* ============================================================
* Title:   Alpha-pooling diagnostic for Verdier robust estimator
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: The Verdier robust estimator (run_grc_robust_vv) pools
*          moment conditions across switchers s and clusters v.
*          Each moment's implicit weight on cluster v depends on s:
*            w(s, v) = n_obs(s, v) * Var(D | s, v).
*          If these weights differ substantially across switchers
*          AND beta(v) varies across clusters, the GMM estimator of
*          phi is biased (see
*          quality_reports/reviews/2026-04-24_alpha-pooling-derivation.md).
*          This script computes the per-(s, v) weights for each
*          (country, cov_all spec), then the total-variation distance
*          between pairs of switchers' weight profiles to diagnose
*          the tilt magnitude empirically.
* Input:   data/processed/{IDN,CHN,TZA}_unb.dta
*          RP7/scripts/0_programs.do (for gen_vfirst, setup_grc_estimation)
* Output:  x_alpha_pooling_diagnostic.smcl / .txt
*          x_alpha_pooling_diagnostic_weights.dta (one row per
*          country x switcher x cluster, columns pi_sv, var_D_sv,
*          w_sv, tilde_w_sv)
*          x_alpha_pooling_diagnostic_tv.dta (pairwise TV
*          distances between switcher weight profiles)
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
include "$dir/scripts/0_path_config.do"

cd "$dir/explorations/verdier"
log using "x_alpha_pooling_diagnostic.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/RP7/scripts/0_programs.do"

* ============================================================
* Postfiles
* ============================================================
tempname weights tv
postfile `weights' str4 country double(switcher) double(vfirst) ///
    double(n_sv) double(var_D_sv) double(w_sv) double(tilde_w_sv) ///
    using "x_alpha_pooling_diagnostic_weights.dta", replace

postfile `tv' str4 country double(s1) double(s2) double(tv_dist) ///
    using "x_alpha_pooling_diagnostic_tv.dta", replace

* ============================================================
* Main loop
* ============================================================
foreach country in IDN CHN TZA {
    di as result _newline(2) "################################"
    di as result "# Country: `country'"
    di as result "################################"

    if "`country'" == "CHN" {
        local vidx provcd
    }
    else if "`country'" == "TZA" {
        local vidx region
    }
    else {
        local vidx prov
    }

    use "$dirdata/processed/`country'_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)

    setup_grc_estimation
    * Keep what we need
    keep pid year trajectory switcher choice always never `vidx'

    * Build vfirst the same way run_grc_robust_vv does
    gen_vfirst, vname(`vidx') genname(vfirst)
    qui drop if missing(vfirst)

    qui levelsof vfirst, local(vvals)
    local V : word count `vvals'
    di as text "  |V| = `V' clusters"
    di as text "  switchers = $switchers"

    * ----------------------------------------------------------
    * For each switcher s, compute per-cluster n_sv, var_D_sv,
    * w_sv = n_sv * var_D_sv, tilde_w_sv (normalized per s).
    * ----------------------------------------------------------
    foreach s of numlist $switchers {
        * Restrict to obs with trajectory == s
        preserve
            qui keep if trajectory == `s'
            qui count
            local n_s_total = r(N)
            if `n_s_total' == 0 {
                restore
                continue
            }

            * Per-cluster n and var(D)
            qui levelsof vfirst, local(vvals_s)
            foreach v of local vvals_s {
                qui sum choice if vfirst == `v', detail
                local n_sv     = r(N)
                local var_D_sv = r(Var)
                if missing(`var_D_sv') local var_D_sv 0
                local w_sv = `n_sv' * `var_D_sv'

                * Temporarily store for normalization
                tempvar dummy
                post `weights' ("`country'") (`s') (`v') ///
                    (`n_sv') (`var_D_sv') (`w_sv') (.)
            }
        restore
    }
}

postclose `weights'
postclose `tv'

* ============================================================
* Compute normalized weights and TV distances in memory
* ============================================================
use "x_alpha_pooling_diagnostic_weights.dta", clear

* Normalize w_sv per (country, switcher)
bysort country switcher (vfirst): egen W_s = sum(w_sv)
replace tilde_w_sv = w_sv / W_s if W_s > 0

* Write back
save "x_alpha_pooling_diagnostic_weights.dta", replace

* ----------------------------------------------------------
* Compute pairwise TV distance between switchers within each country
* ----------------------------------------------------------
* TV(s1, s2) = 0.5 * sum_v |tilde_w_sv(s1) - tilde_w_sv(s2)|
* A full-support union is used; missing cells treated as 0 weight.
* ----------------------------------------------------------

* Save current long data to tempfile so we can iterate without
* nested preserve/restore (Stata only allows one level).
tempfile long_weights
save `long_weights', replace

* Reshape wide once, save to tempfile, then iterate over countries
keep country switcher vfirst tilde_w_sv
replace tilde_w_sv = 0 if missing(tilde_w_sv)
reshape wide tilde_w_sv, i(country vfirst) j(switcher)
tempfile wide_weights
save `wide_weights', replace

* Compute TV between each pair of switchers per country
tempname tv2
postfile `tv2' str4 country double(s1) double(s2) double(tv_dist) ///
    using "x_alpha_pooling_diagnostic_tv.dta", replace

foreach country in IDN CHN TZA {
    use `wide_weights', clear
    qui keep if country == "`country'"
    if _N == 0 continue

    * Get columns (switcher values) for this country
    ds tilde_w_sv*
    local cols `r(varlist)'

    * Extract numeric switcher indices from var names
    local switchers_c ""
    foreach c of local cols {
        local s_val = substr("`c'", length("tilde_w_sv") + 1, .)
        qui sum `c'
        if r(mean) > 0 | r(sum) > 0 {
            local switchers_c "`switchers_c' `s_val'"
        }
    }

    di as text "  `country' switchers with data: `switchers_c'"

    * Pairwise TV
    foreach s1 of local switchers_c {
        foreach s2 of local switchers_c {
            if `s1' < `s2' {
                qui gen _abs_diff = abs(tilde_w_sv`s1' - tilde_w_sv`s2')
                qui sum _abs_diff
                local tv_val = 0.5 * r(sum)
                drop _abs_diff
                post `tv2' ("`country'") (`s1') (`s2') (`tv_val')
            }
        }
    }
}

postclose `tv2'

* ============================================================
* Report
* ============================================================
di as result _newline(2) "================================"
di as result "# ALPHA POOLING DIAGNOSTIC RESULTS"
di as result "================================"

use "x_alpha_pooling_diagnostic_tv.dta", clear
di as result _newline "Total-variation distance between switcher weight profiles"
di as result "(TV = 0: identical; TV = 1: disjoint support)"
di as result ""

foreach country in IDN CHN TZA {
    di as result _newline "## `country'"
    qui count if country == "`country'"
    if r(N) == 0 continue
    list s1 s2 tv_dist if country == "`country'", abbrev(8) noobs sep(0)

    qui sum tv_dist if country == "`country'"
    di as result "  mean TV = " %6.4f r(mean)
    di as result "  max TV  = " %6.4f r(max)
    di as result "  min TV  = " %6.4f r(min)
}

* ============================================================
* Also report: per-country, max |tilde_w(s,v) - tilde_w(s',v)|
* across any v and any pair (s, s')
* ============================================================
use "x_alpha_pooling_diagnostic_weights.dta", clear
replace tilde_w_sv = 0 if missing(tilde_w_sv)
keep country switcher vfirst tilde_w_sv
reshape wide tilde_w_sv, i(country vfirst) j(switcher)

di as result _newline(2) "## Per-(country, v) max weight disagreement across switchers"
foreach country in IDN CHN TZA {
    preserve
        qui keep if country == "`country'"
        if _N == 0 {
            restore
            continue
        }

        ds tilde_w_sv*
        local cols `r(varlist)'

        gen w_max = .
        gen w_min = .
        foreach c of local cols {
            replace w_max = max(w_max, `c') if !missing(`c')
            replace w_min = min(w_min, `c') if !missing(`c')
        }
        gen w_range = w_max - w_min

        qui sum w_range
        di as result "`country': mean(w_max - w_min) across v = " %7.4f r(mean) ///
            ", max = " %7.4f r(max)
    restore
}

log close
capture translate "x_alpha_pooling_diagnostic.smcl" "x_alpha_pooling_diagnostic.txt", replace
exit, STATA clear
