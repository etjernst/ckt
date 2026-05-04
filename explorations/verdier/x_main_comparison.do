* ============================================================
* Title:   Main consumption-urban-unbalanced comparison
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Replicate the published GRC tables for IDN/CHN/TZA
*          consumption urban unbalanced, for all five cov variants
*          (covs_0, covs_trend, covs_1, covs_2, covs_all). Run
*          each spec under two approaches:
*            1. Original GRC (run_grc, Stata default two-step)
*            2. Verdier robust (run_grc_robust_vv, cluster-demeaned
*               instruments, onestep GMM)
*          Collect all estimates into a comparison dta and print
*          country-specific markdown tables to the log.
* Input:   data/processed/{IDN,CHN,TZA}_unb.dta
*          RP7/scripts/0_programs.do
* Output:  x_main_comparison.smcl / .txt
*          x_main_comparison_results.dta (one row per
*          country x cov x approach, with phi / Delta_* / etc.)
* Notes:   run_grc_robust_vv is onestep so Hansen J is not available;
*          we report e(Q) as the GMM criterion instead.
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
if "$dir" == "" {
    di as error "Set \$dir for your username."
    exit 198
}
include "$dir/scripts/0_path_config.do"

cd "$dir/explorations/verdier"
log using "x_main_comparison.smcl", replace text
version 17

global copyOverleaf 0

* Load the RP7 programs (tracked in git; junction has the same content
* but is coauthor's read-only RP6).
include "$dir/RP7/scripts/0_programs.do"

local iterations 500

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* keepvars base: country-specific cluster var added later
global keepvars_base lndepvar trajectory choice pid period unbalanced*
global keepvars_base $keepvars_base switcher non_switcher female age age2
global keepvars_base $keepvars_base education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_* year

tempname results
postfile `results'                                               ///
    str4 country str10 spec str10 approach                       ///
    double(phi se_phi Delta_never se_never Delta_always se_always ///
           Delta_avg se_avg Jstat Jpval Q converged N)            ///
    using "x_main_comparison_results.dta", replace

* ----------------------------------------------------------------
* Helper: extract estimates for a single country x cov x approach
* ----------------------------------------------------------------
* After each run_grc / run_grc_robust_vv call, the main .ster is at
* $output/`estname'; the nlcom-posted _never / _always / _avg / _delta
* are saved as separate .ster files. We grab phi from the main, then
* Delta_never from _never, etc.
capture program drop collect_one
program define collect_one, rclass
    syntax , estname(string) approach(string) country(string) spec(string)

    * Main estimate: phi, N, Q, converged
    estimates use "$output/`estname'"
    local phi       = _b[phi:_cons]
    local se_phi    = _se[phi:_cons]
    local N         = e(N)
    local converged = e(converged)
    local Q         = e(Q)
    capture local Jstat = e(Jstat)
    if _rc != 0 local Jstat = .
    capture local Jpval = e(Jpval)
    if _rc != 0 local Jpval = .

    * Delta_never (posted from nlcom)
    capture estimates use "$output/`estname'_never"
    if _rc == 0 {
        local Dnever    = _b[Delta_never]
        local seDnever  = _se[Delta_never]
    }
    else {
        local Dnever = .
        local seDnever = .
    }

    * Delta_always
    capture estimates use "$output/`estname'_always"
    if _rc == 0 {
        local Dalways   = _b[Delta_always]
        local seDalways = _se[Delta_always]
    }
    else {
        local Dalways = .
        local seDalways = .
    }

    * Delta_avg
    capture estimates use "$output/`estname'_avg"
    if _rc == 0 {
        local Davg    = _b[Delta_avg]
        local seDavg  = _se[Delta_avg]
    }
    else {
        local Davg = .
        local seDavg = .
    }

    return scalar phi         = `phi'
    return scalar se_phi      = `se_phi'
    return scalar Dnever      = `Dnever'
    return scalar seDnever    = `seDnever'
    return scalar Dalways     = `Dalways'
    return scalar seDalways   = `seDalways'
    return scalar Davg        = `Davg'
    return scalar seDavg      = `seDavg'
    return scalar Jstat       = `Jstat'
    return scalar Jpval       = `Jpval'
    return scalar Q           = `Q'
    return scalar converged   = `converged'
    return scalar N           = `N'
end

* ----------------------------------------------------------------
* Main loop
* ----------------------------------------------------------------
local balance unb

foreach country in IDN CHN TZA {

    di as result _newline(2) ///
        "################################################################"
    di as result "# `country'"
    di as result "################################################################"

    * Country-specific cluster variable
    if "`country'" == "CHN" {
        local vidx provcd
    }
    else {
        local vidx prov
    }
    if "`country'" == "TZA" {
        local vidx region
    }

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)

    setup_grc_estimation
    keep $keepvars_base `vidx'

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * Initial values (shared across all specs within country)
    initial_values lndepvar,         ///
        switchers($switchers)        ///
        balance(`balance')           ///
        estname(init_cmp_`country')
    local base    `r(base)'
    local initial "`r(initial)'"

    * Loop over cov specs
    foreach cov in 0 trend 1 2 all {

        * Build covars list matching 5_GrRC.do exactly
        if "`cov'" == "0"     local covars_cov ""
        if "`cov'" == "trend" local covars_cov "`periodFE'"
        if "`cov'" == "1"     local covars_cov "`periodFE' $covs_gmm"
        if "`cov'" == "2"     local covars_cov "`periodFE' $covs_gmm2"
        if "`cov'" == "all"   local covars_cov "`periodFE' $covs_gmm_all"

        * ----- Original GRC (run_grc, two-step, as published) -----
        di as result _newline "=== `country' `cov' / SIMPLE (run_grc) ==="
        run_grc, estname(cmp_`country'_`cov')                    ///
            switchers($switchers) base(`base')                    ///
            initial(`initial')                                    ///
            balance(`balance')                                    ///
            covars(`covars_cov')                                  ///
            iterate(`iterations')

        collect_one, estname(cmp_`country'_`cov')                 ///
            approach(simple) country(`country') spec(`cov')
        post `results' ("`country'") ("`cov'") ("simple")         ///
            (r(phi)) (r(se_phi))                                  ///
            (r(Dnever)) (r(seDnever))                             ///
            (r(Dalways)) (r(seDalways))                           ///
            (r(Davg)) (r(seDavg))                                 ///
            (r(Jstat)) (r(Jpval)) (r(Q))                          ///
            (r(converged)) (r(N))

        * ----- Verdier VV-robust (run_grc_robust_vv, onestep) -----
        di as result _newline "=== `country' `cov' / VERDIER (run_grc_robust_vv) ==="
        preserve
            run_grc_robust_vv, estname(cmpvv_`country'_`cov')     ///
                switchers($switchers) base(`base')                 ///
                initial(`initial')                                 ///
                balance(`balance') vindex(`vidx')                  ///
                covars(`covars_cov')                               ///
                iterate(`iterations')

            collect_one, estname(cmpvv_`country'_`cov')           ///
                approach(verdier) country(`country') spec(`cov')
            post `results' ("`country'") ("`cov'") ("verdier")    ///
                (r(phi)) (r(se_phi))                              ///
                (r(Dnever)) (r(seDnever))                         ///
                (r(Dalways)) (r(seDalways))                       ///
                (r(Davg)) (r(seDavg))                             ///
                (r(Jstat)) (r(Jpval)) (r(Q))                      ///
                (r(converged)) (r(N))
        restore
    }
}

postclose `results'

* ----------------------------------------------------------------
* Comparison tables (markdown, one per country)
* ----------------------------------------------------------------
use "x_main_comparison_results.dta", clear

di as result _newline(2) "=============================================================="
di as result "# COMPARISON TABLES (markdown)"
di as result "=============================================================="

foreach country in IDN CHN TZA {
    di as result _newline(2) "## `country' --- consumption | urban | unbalanced"

    * Header
    di as result _newline ///
        "| Statistic | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |"
    di as result ///
        "|-----------|--------|------------|--------|--------|----------|"

    * For each statistic and approach, print a row
    foreach stat in phi Dnever Dalways Davg {

        local statlabel "phi"
        if "`stat'" == "Dnever"  local statlabel "Delta_never"
        if "`stat'" == "Dalways" local statlabel "Delta_always"
        if "`stat'" == "Davg"    local statlabel "Delta_avg"

        foreach appr in simple verdier {
            local row "| `statlabel' (`appr') |"
            foreach cov in 0 trend 1 2 all {
                qui sum phi if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                if r(N) == 0 {
                    local row "`row' -- |"
                    continue
                }
                * Map stat to variable
                if "`stat'" == "phi" {
                    qui sum phi if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local val = r(mean)
                    qui sum se_phi if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local se  = r(mean)
                }
                if "`stat'" == "Dnever" {
                    qui sum Delta_never if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local val = r(mean)
                    qui sum se_never if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local se  = r(mean)
                }
                if "`stat'" == "Dalways" {
                    qui sum Delta_always if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local val = r(mean)
                    qui sum se_always if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local se  = r(mean)
                }
                if "`stat'" == "Davg" {
                    qui sum Delta_avg if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local val = r(mean)
                    qui sum se_avg if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                    local se  = r(mean)
                }
                local row "`row' " + string(`val', "%6.3f") + " (" + string(`se', "%5.3f") + ") |"
            }
            di as result "`row'"
        }
    }

    * Additional rows: Hansen J (simple only), Q (both), converged, N
    local row "| Hansen J (simple) |"
    foreach cov in 0 trend 1 2 all {
        qui sum Jstat if country == "`country'" & spec == "`cov'" & approach == "simple"
        if r(N) == 0 | missing(r(mean)) {
            local row "`row' -- |"
        }
        else {
            local jstat = r(mean)
            qui sum Jpval if country == "`country'" & spec == "`cov'" & approach == "simple"
            local jpval = r(mean)
            local row "`row' " + string(`jstat', "%5.2f") + " (p=" + string(`jpval', "%4.2f") + ") |"
        }
    }
    di as result "`row'"

    * Converged flags
    foreach appr in simple verdier {
        local row "| Converged (`appr') |"
        foreach cov in 0 trend 1 2 all {
            qui sum converged if country == "`country'" & spec == "`cov'" & approach == "`appr'"
            if r(N) == 0 {
                local row "`row' -- |"
            }
            else {
                local cvg = r(mean)
                local cvgstr = cond(`cvg' == 1, "Y", "N")
                local row "`row' `cvgstr' |"
            }
        }
        di as result "`row'"
    }

    * N (should be the same for simple and verdier; verdier may drop some
    * missing-vfirst rows)
    foreach appr in simple verdier {
        local row "| N (`appr') |"
        foreach cov in 0 trend 1 2 all {
            qui sum N if country == "`country'" & spec == "`cov'" & approach == "`appr'"
            if r(N) == 0 {
                local row "`row' -- |"
            }
            else {
                local nn = r(mean)
                local row "`row' " + string(`nn', "%10.0fc") + " |"
            }
        }
        di as result "`row'"
    }
}

log close
capture translate "x_main_comparison.smcl" "x_main_comparison.txt", replace
exit, STATA clear
