* ============================================================
* Title:   TZA simple specs: phi initial-value sensitivity
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Follow-up to x_tza_phi_sensitivity.do (which found the
*          Verdier robust spec has two local minima across 5 phi
*          starts). This script tests whether the SIMPLE specs
*          run_grc (two-step, as published) and run_grc_onestep
*          suffer the same problem. If simple phi is stable across
*          starts, the issue is specific to the cluster-fixed-effects
*          parameterization. If unstable, the published CKT simple
*          numbers may themselves be initial-value artifacts.
* Input:   data/processed/TZA_unb.dta
*          scripts/0_programs.do (must have phistart option on both
*                                 run_grc and run_grc_onestep)
* Output:  x_tza_simple_phi_sensitivity.smcl / .txt
*          x_tza_simple_phi_sensitivity_results.dta
*          Two tables of (phistart, phi_hat, se_phi, Q, converged),
*          one per program.
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
log using "x_tza_simple_phi_sensitivity.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

* ============================================================
* TZA setup
* ============================================================
local country TZA
local balance unb

global covs_gmm_all "female age2 education_max education_max2"
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

local iterations 500

* Initial values (once; reused across all starts and both programs)
initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(`balance')       ///
    estname(initial_sens_simple)
local base_simple    `r(base)'
local initial_simple "`r(initial)'"

tempname results
postfile `results' str16 program double(phistart phi_hat se_phi Q converged) ///
    using "x_tza_simple_phi_sensitivity_results.dta", replace

* ============================================================
* Sensitivity: run_grc (two-step)
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# run_grc (two-step, as published)"
di as result "################################################################"

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== run_grc phistart = `pstart' (run `k') ==="

    preserve
        run_grc,                                                 ///
            estname(grc_sens_`k')                                ///
            switchers($switchers) base(`base_simple')            ///
            initial(`initial_simple')                            ///
            balance(`balance')                                   ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        * Reload main .ster (run_grc's final nlcom post replaces e(b))
        estimates use "$output/grc_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("run_grc") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

* ============================================================
* Sensitivity: run_grc_onestep
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# run_grc_onestep (one-step, VV-matching)"
di as result "################################################################"

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== run_grc_onestep phistart = `pstart' (run `k') ==="

    preserve
        run_grc_onestep,                                         ///
            estname(grc1_sens_`k')                               ///
            switchers($switchers) base(`base_simple')            ///
            initial(`initial_simple')                            ///
            balance(`balance')                                   ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        estimates use "$output/grc1_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("run_grc_onestep") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

postclose `results'

* ============================================================
* Report
* ============================================================
di as result _newline(2) "=== SIMPLE-SPEC SENSITIVITY RESULTS ==="
preserve
    use "x_tza_simple_phi_sensitivity_results.dta", clear

    di as result _newline "All results:"
    list program phistart phi_hat se_phi Q converged, abbrev(16) noobs sep(5)

    di as result _newline "Range of phi_hat within each program:"
    by program, sort: egen phi_min = min(phi_hat)
    by program: egen phi_max = max(phi_hat)
    gen phi_range = phi_max - phi_min
    duplicates drop program, force
    list program phi_min phi_max phi_range, abbrev(16) noobs sep(0)

    foreach pp in "run_grc" "run_grc_onestep" {
        qui sum phi_range if program == "`pp'"
        local rng = r(mean)
        di as result _newline
        if `rng' < 1e-4 {
            di as result "`pp': phi is ROBUST to initial value (range = " %9.2e `rng' ")."
        }
        else if `rng' < 1e-2 {
            di as result "`pp': phi is approximately robust (range = " %9.4f `rng' ")."
        }
        else {
            di as error "`pp': phi DEPENDS on initial value (range = " %9.4f `rng' ")."
        }
    }
restore

log close
capture translate "x_tza_simple_phi_sensitivity.smcl" "x_tza_simple_phi_sensitivity.txt", replace
exit, STATA clear
