* ============================================================
* Title:   CHN + IDN VV-adapted robust smoke + sensitivity
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Confirm run_grc_robust_vv works on CHN and IDN.
*          TZA already passed (phi range 0.0020, converged,
*          matches simple with 25% tighter SE). CHN has 29
*          clusters (vs TZA 26) and IDN has 22 -- all should
*          handle fine given no cluster-FE parameters.
* Input:   data/processed/{CHN,IDN}_unb.dta
*          scripts/0_programs.do (run_grc_robust_vv)
* Output:  x_chn_idn_robust_vv_smoke.smcl / .txt
*          x_chn_idn_robust_vv_smoke_results.dta
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
log using "x_chn_idn_robust_vv_smoke.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

local iterations 500

global covs_gmm_all "female age2 education_max education_max2"
global keepvars_base lndepvar trajectory choice pid period unbalanced*
global keepvars_base $keepvars_base switcher non_switcher female age age2
global keepvars_base $keepvars_base education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_* year

tempname results
postfile `results' str4 country double(phistart phi_hat se_phi Q converged) ///
    str8 simple_phi double simple_se ///
    using "x_chn_idn_robust_vv_smoke_results.dta", replace

* ============================================================
* CHN (vindex = provcd)
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# CHN: run_grc_robust_vv sensitivity (vindex = provcd)"
di as result "################################################################"

use "$dirdata/processed/CHN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
keep $keepvars_base provcd

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(unb)             ///
    estname(init_CHN_vv)
local base_chn    `r(base)'
local initial_chn "`r(initial)'"

* Simple onestep baseline for reference
run_grc_onestep, estname(grc1_CHN_vv_base)                  ///
    switchers($switchers) base(`base_chn')                   ///
    initial(`initial_chn')                                   ///
    balance(unb)                                             ///
    covars(`periodFE' $covs_gmm_all)                         ///
    iterate(`iterations')                                    ///
    phistart(-1)
estimates use "$output/grc1_CHN_vv_base"
local chn_simple_phi = _b[phi:_cons]
local chn_simple_se  = _se[phi:_cons]
di as result "CHN simple onestep: phi = " %9.4f `chn_simple_phi' ///
    ", se = " %9.4f `chn_simple_se'

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== CHN run_grc_robust_vv phistart = `pstart' (run `k') ==="

    preserve
        run_grc_robust_vv,                                   ///
            estname(grcvv_chn_sens_`k')                      ///
            switchers($switchers) base(`base_chn')           ///
            initial(`initial_chn')                           ///
            balance(unb) vindex(provcd)                      ///
            covars(`periodFE' $covs_gmm_all)                 ///
            iterate(`iterations')                            ///
            phistart(`pstart')

        estimates use "$output/grcvv_chn_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("CHN") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged') ///
        ("simple") (`chn_simple_phi')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

* ============================================================
* IDN (vindex = prov)
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# IDN: run_grc_robust_vv sensitivity (vindex = prov)"
di as result "################################################################"

use "$dirdata/processed/IDN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
keep $keepvars_base prov

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(unb)             ///
    estname(init_IDN_vv)
local base_idn    `r(base)'
local initial_idn "`r(initial)'"

* Simple onestep baseline for reference
run_grc_onestep, estname(grc1_IDN_vv_base)                  ///
    switchers($switchers) base(`base_idn')                   ///
    initial(`initial_idn')                                   ///
    balance(unb)                                             ///
    covars(`periodFE' $covs_gmm_all)                         ///
    iterate(`iterations')                                    ///
    phistart(-1)
estimates use "$output/grc1_IDN_vv_base"
local idn_simple_phi = _b[phi:_cons]
local idn_simple_se  = _se[phi:_cons]
di as result "IDN simple onestep: phi = " %9.4f `idn_simple_phi' ///
    ", se = " %9.4f `idn_simple_se'

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== IDN run_grc_robust_vv phistart = `pstart' (run `k') ==="

    preserve
        run_grc_robust_vv,                                   ///
            estname(grcvv_idn_sens_`k')                      ///
            switchers($switchers) base(`base_idn')           ///
            initial(`initial_idn')                           ///
            balance(unb) vindex(prov)                        ///
            covars(`periodFE' $covs_gmm_all)                 ///
            iterate(`iterations')                            ///
            phistart(`pstart')

        estimates use "$output/grcvv_idn_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("IDN") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged') ///
        ("simple") (`idn_simple_phi')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

postclose `results'

* ============================================================
* Report
* ============================================================
di as result _newline(2) "=== CHN + IDN VV-ROBUST SENSITIVITY RESULTS ==="
preserve
    use "x_chn_idn_robust_vv_smoke_results.dta", clear

    di as result _newline "All results:"
    list country phistart phi_hat se_phi Q converged, abbrev(10) noobs sep(5)

    di as result _newline "Range of phi_hat by country:"
    by country, sort: egen phi_min = min(phi_hat)
    by country: egen phi_max = max(phi_hat)
    gen phi_range = phi_max - phi_min
    duplicates drop country, force
    list country phi_min phi_max phi_range simple_phi, abbrev(10) noobs sep(0)

    foreach cc in "CHN" "IDN" {
        qui sum phi_range if country == "`cc'"
        local rng = r(mean)
        di as result _newline
        if `rng' < 1e-4 {
            di as result "`cc': VV-robust phi is ROBUST to initial value (range = " %9.2e `rng' ")."
        }
        else if `rng' < 1e-2 {
            di as result "`cc': VV-robust phi is approximately robust (range = " %9.4f `rng' ")."
        }
        else {
            di as error "`cc': VV-robust phi DEPENDS on initial value (range = " %9.4f `rng' ")."
        }
    }
restore

log close
capture translate "x_chn_idn_robust_vv_smoke.smcl" "x_chn_idn_robust_vv_smoke.txt", replace
exit, STATA clear
