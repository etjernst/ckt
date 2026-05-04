* ============================================================
* Title:   TZA VV-adapted robust spec smoke test + sensitivity
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Test run_grc_robust_vv (VV-style cluster-demeaned
*          instruments, no cluster-FE parameters) on TZA.
*          Runs at 5 phistart values to verify phi is stable
*          (unlike run_grc_robust which had 2 local minima).
*          Also reports run_grc_onestep phi as the simple-spec
*          comparator.
* Input:   data/processed/TZA_unb.dta
*          scripts/0_programs.do (run_grc_robust_vv)
* Output:  x_tza_robust_vv_smoke.smcl / .txt
*          x_tza_robust_vv_smoke_results.dta
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
log using "x_tza_robust_vv_smoke.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

local country TZA
local balance unb

global covs_gmm_all "female age2 education_max education_max2"
global keepvars lndepvar trajectory choice pid period unbalanced*
global keepvars $keepvars switcher non_switcher female age age2
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

* Initial values (reused across all starts)
initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(`balance')       ///
    estname(initial_vv_smoke)
local base_tza    `r(base)'
local initial_tza "`r(initial)'"

* ============================================================
* Baseline: run_grc_onestep (simple onestep) for comparison
* ============================================================
di as result _newline(2) "=== run_grc_onestep (simple baseline, phistart=-1) ==="

run_grc_onestep, estname(grc1_vv_smoke)                         ///
    switchers($switchers) base(`base_tza')                      ///
    initial(`initial_tza')                                      ///
    balance(`balance')                                          ///
    covars(`periodFE' $covs_gmm_all)                            ///
    iterate(`iterations')                                       ///
    phistart(-1)

estimates use "$output/grc1_vv_smoke"
di as result "run_grc_onestep: phi = " %8.4f _b[phi:_cons] ///
    ", se = " %8.4f _se[phi:_cons]

* ============================================================
* run_grc_robust_vv sensitivity sweep (5 phi starts)
* ============================================================
tempname results
postfile `results' double(phistart phi_hat se_phi Q converged) ///
    using "x_tza_robust_vv_smoke_results.dta", replace

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== run_grc_robust_vv phistart = `pstart' (run `k') ==="

    preserve
        run_grc_robust_vv,                                       ///
            estname(grcvv_tza_sens_`k')                          ///
            switchers($switchers) base(`base_tza')               ///
            initial(`initial_tza')                               ///
            balance(`balance') vindex(region)                    ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        estimates use "$output/grcvv_tza_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
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
* Report
* ============================================================
di as result _newline(2) "=== VV-ROBUST SENSITIVITY RESULTS (TZA) ==="
preserve
    use "x_tza_robust_vv_smoke_results.dta", clear
    list phistart phi_hat se_phi Q converged, abbrev(12) noobs sep(0)

    qui sum phi_hat
    local range = r(max) - r(min)
    di as result _newline "phi_hat range across starts: " %9.4f `range'
    if `range' < 1e-4 {
        di as result "VERDICT: VV-robust phi is ROBUST to initial value."
    }
    else if `range' < 1e-2 {
        di as result "VERDICT: VV-robust phi is approximately robust."
    }
    else {
        di as error "VERDICT: VV-robust phi DEPENDS on initial value (range = " ///
            %9.4f `range' "). Still not identified!"
    }
restore

log close
capture translate "x_tza_robust_vv_smoke.smcl" "x_tza_robust_vv_smoke.txt", replace
exit, STATA clear
