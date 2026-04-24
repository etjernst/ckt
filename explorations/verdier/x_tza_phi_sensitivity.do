* ============================================================
* Title:   TZA robust spec: phi initial-value sensitivity
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Verify that run_grc_robust's converged phi does not depend
*          on the initial value. The default {phi=-1} in the GMM
*          equation means the optimizer starts at phi=-1. If the
*          converged value (-1.003 in the P1 smoke test) merely
*          reflects that initial value, the answer is not informative.
*          This script re-runs the robust fit with phistart in
*          {-1, -0.5, 0, 0.5, 1} and reports the converged phi for each.
* Input:   data/processed/TZA_unb.dta
*          scripts/0_programs.do
* Output:  x_tza_phi_sensitivity.smcl / .txt
*          A table of (phistart, converged_phi, se, converged_flag,
*          final_Q).
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
if "$dir" == "" {
    di as error "Set \$dir for your username in the header of this script."
    exit 198
}
include "$dir/scripts/0_path_config.do"

cd "$dir/explorations/verdier"
log using "x_tza_phi_sensitivity.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

* ============================================================
* TZA setup (minimal)
* ============================================================
local country TZA
local balance unb

global covs_gmm_all "female age2 education_max education_max2"
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*
global keepvars $keepvars year region

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

local iterations 500

* ============================================================
* Initial values (computed once; reused across all phi starts)
* ============================================================
initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(`balance')              ///
    vindex(region)                  ///
    estname(initial_`country'_sens)
local base_region    `r(base)'
local initial_region "`r(initial)'"

* ============================================================
* Sensitivity loop
* ============================================================
tempname results
postfile `results' double(phistart phi_hat se_phi Q converged) using ///
    "x_tza_phi_sensitivity_results.dta", replace

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== phistart = `pstart' (run `k') ==="

    * Preserve + restore to keep the dataset clean across fits;
    * run_grc_robust drops missing-vfirst obs.
    preserve
        run_grc_robust,                                          ///
            estname(grcr_sens_`k')                               ///
            switchers($switchers) base(`base_region')            ///
            initial(`initial_region')                            ///
            balance(`balance') vindex(region)                    ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        * Reload main .ster (run_grc_robust's final nlcom post
        * replaces e(b) with Delta_avg).
        estimates use "$output/grcr_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(criterion)
        local converged = e(converged)
    restore

    post `results' (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged')

    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

postclose `results'

* ============================================================
* Report table
* ============================================================
di as result _newline(2) "=== SENSITIVITY RESULTS ==="
preserve
    use "x_tza_phi_sensitivity_results.dta", clear
    list phistart phi_hat se_phi Q converged, abbrev(12) noobs sep(0)

    qui sum phi_hat
    local range = r(max) - r(min)
    di as result _newline
    di as result "phi_hat range across starts: " %9.4f `range'
    if `range' < 1e-4 {
        di as result "VERDICT: phi is robust to initial value (range < 1e-4)."
    }
    else if `range' < 1e-2 {
        di as result "VERDICT: phi is approximately robust (range < 1e-2, likely different local minima numerically close)."
    }
    else {
        di as error "VERDICT: phi DEPENDS on initial value (range = " ///
            %9.4f `range' "). Robust fit is not well identified."
    }
restore

log close
capture translate "x_tza_phi_sensitivity.smcl" "x_tza_phi_sensitivity.txt", replace
exit, STATA clear
