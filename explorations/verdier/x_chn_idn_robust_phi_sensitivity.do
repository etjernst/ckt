* ============================================================
* Title:   CHN + IDN robust spec: phi initial-value sensitivity
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Follow-up to x_tza_phi_sensitivity.do. TZA's robust fit
*          (26 regions as clusters) had two local minima across 5
*          phistart values, with the global min at phi=+1.25 (se 3.5,
*          statistically zero). Check whether CHN (29 provinces) and
*          IDN (22 provinces) identify phi cleanly under the same
*          single-step cluster-dummy parameterization.
*          If CHN/IDN are stable, the problem is TZA-specific (sparse
*          within-cluster variation). If CHN/IDN are also unstable,
*          we need VV's two-step procedure verbatim.
* Input:   data/processed/{CHN,IDN}_unb.dta
*          scripts/0_programs.do (gen_vfirst, initial_values_robust,
*                                 run_grc_robust with phistart option)
* Output:  x_chn_idn_robust_phi_sensitivity.smcl / .txt
*          x_chn_idn_robust_phi_sensitivity_results.dta
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
log using "x_chn_idn_robust_phi_sensitivity.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

local iterations 500

global covs_gmm_all "female age2 education_max education_max2"
global keepvars_base lndepvar trajectory choice pid period unbalanced* switcher non_switcher
global keepvars_base $keepvars_base female age age2 education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_* year

tempname results
postfile `results' str4 country double(phistart phi_hat se_phi Q converged) ///
    using "x_chn_idn_robust_phi_sensitivity_results.dta", replace

* ============================================================
* CHN
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# CHN robust sensitivity (vindex = prov)"
di as result "################################################################"

* CHN: processed data has provcd (not prov). Use provcd as vindex.
use "$dirdata/processed/CHN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars_base provcd

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(unb)                    ///
    vindex(provcd)                  ///
    estname(initial_CHN_sens)
local base_chn    `r(base)'
local initial_chn "`r(initial)'"

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== CHN robust phistart = `pstart' (run `k') ==="

    preserve
        run_grc_robust,                                          ///
            estname(grcr_chn_sens_`k')                           ///
            switchers($switchers) base(`base_chn')               ///
            initial(`initial_chn')                               ///
            balance(unb) vindex(provcd)                          ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        estimates use "$output/grcr_chn_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("CHN") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

* ============================================================
* IDN
* ============================================================
di as result _newline(2) ///
    "################################################################"
di as result "# IDN robust sensitivity (vindex = prov)"
di as result "################################################################"

use "$dirdata/processed/IDN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars_base prov

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(unb)                    ///
    vindex(prov)                    ///
    estname(initial_IDN_sens)
local base_idn    `r(base)'
local initial_idn "`r(initial)'"

local k = 0
foreach pstart in -1 -0.5 0 0.5 1 {
    local ++k
    di as result _newline(2) "=== IDN robust phistart = `pstart' (run `k') ==="

    preserve
        run_grc_robust,                                          ///
            estname(grcr_idn_sens_`k')                           ///
            switchers($switchers) base(`base_idn')               ///
            initial(`initial_idn')                               ///
            balance(unb) vindex(prov)                            ///
            covars(`periodFE' $covs_gmm_all)                     ///
            iterate(`iterations')                                ///
            phistart(`pstart')

        estimates use "$output/grcr_idn_sens_`k'"
        local phi_hat   = _b[phi:_cons]
        local se_phi    = _se[phi:_cons]
        local Q         = e(Q)
        local converged = e(converged)
    restore

    post `results' ("IDN") (`pstart') (`phi_hat') (`se_phi') (`Q') (`converged')
    di as result "  phi_hat = " %9.4f `phi_hat'     ///
        ", se = "                %9.4f `se_phi'     ///
        ", Q = "                 %11.4e `Q'         ///
        ", converged = "         `converged'
}

postclose `results'

* ============================================================
* Report
* ============================================================
di as result _newline(2) "=== CHN + IDN ROBUST SENSITIVITY RESULTS ==="
preserve
    use "x_chn_idn_robust_phi_sensitivity_results.dta", clear

    di as result _newline "All results:"
    list country phistart phi_hat se_phi Q converged, abbrev(10) noobs sep(5)

    di as result _newline "Range of phi_hat by country:"
    by country, sort: egen phi_min = min(phi_hat)
    by country: egen phi_max = max(phi_hat)
    gen phi_range = phi_max - phi_min
    duplicates drop country, force
    list country phi_min phi_max phi_range, abbrev(10) noobs sep(0)

    foreach cc in "CHN" "IDN" {
        qui sum phi_range if country == "`cc'"
        local rng = r(mean)
        di as result _newline
        if `rng' < 1e-4 {
            di as result "`cc': robust phi is ROBUST to initial value (range = " %9.2e `rng' ")."
        }
        else if `rng' < 1e-2 {
            di as result "`cc': robust phi is approximately robust (range = " %9.4f `rng' ")."
        }
        else {
            di as error "`cc': robust phi DEPENDS on initial value (range = " %9.4f `rng' ")."
        }
    }
restore

log close
capture translate "x_chn_idn_robust_phi_sensitivity.smcl" ///
    "x_chn_idn_robust_phi_sensitivity.txt", replace
exit, STATA clear
