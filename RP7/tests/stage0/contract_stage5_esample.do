* *******************************************************************
* Title:   Stage 5 contract test: inversion computes on e(sample),
*          not on a reconstruction, when the two disagree
* Author:  Emilia Tjernstrom
* Date:    2026-07-19
* Purpose: Build the one scenario byte-identity cannot probe: inject
*          missingness into a GMM covariate (rows leave e(sample)),
*          fit, then refill the missingness to simulate a data
*          refresh. The marker path must attach CIs computed on the
*          persisted e(sample) count; the fallback reconstruction
*          (marker removed) now disagrees by construction and must
*          trip the e(N) guard (exit 460) instead of attaching
*          wrong-sample CIs.
* Input:   RP7/data/processed/TZA_unb.dta (canonical hub)
* Output:  smk5c_TZA_c1*.ster and smk5c_TZA_c1_esample.dta in
*          RP7/output (test artifacts; safe to delete); log is the
*          test artifact
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"

include "$dir/scripts/0_path_config.do"
include "$dir/scripts/0_programs.do"

capture noisily {

* ----------------------------------------------------------------
* 1. Load one cell and inject deterministic missingness into a
*    c1-spec covariate (female) so those person-waves leave e(sample)
* ----------------------------------------------------------------
local country TZA
local balance unb

set_covariate_globals

global keepvars logpc_consumption trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

use "$dirdata/processed/`country'_`balance'.dta", clear
setup_grc_estimation
keep $keepvars
tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

gen byte female_orig = female

* Injection rule: number individuals densely (group() is assigned in pid
* sort order, so the rule is deterministic and independent of how raw
* pid values are coded) and blank the covariate for every
* `inject_every'-th individual at their period-2 wave. Any rule giving
* a nonzero strict subset of person-waves works; 50 puts about 2% of
* individuals in the injected set.
local inject_every 50
egen long pidgrp = group(pid)
replace female = . if mod(pidgrp, `inject_every') == 0 & period == 2
quietly count if mi(female)
local n_injected = r(N)
assert `n_injected' > 0
local n_total = _N
assert `n_injected' < `n_total'
di as text "injected missingness: `n_injected' of `n_total' person-waves"

* ----------------------------------------------------------------
* 2. Fit on the injected data; marker must carry e(N) = _N - injected
* ----------------------------------------------------------------
initial_values logpc_consumption,   ///
    switchers($switchers)           ///
    balance(`balance')              ///
    estname(initial_`country')
local base    `r(base)'
local initial "`r(initial)'"

run_grc, estname(smk5c_TZA_c1)                            ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                    ///
    covars(`periodFE' $covs_gmm)                          ///
    iterate(100)

estimates use "$dir/output/smk5c_TZA_c1.ster"
local n_fit = e(N)
di as text "fit e(N) = `n_fit' (expected `=`n_total' - `n_injected'')"
assert `n_fit' == `n_total' - `n_injected'

local marker "$dir/output/smk5c_TZA_c1_esample.dta"
confirm file "`marker'"
preserve
    use "`marker'", clear
    assert _N == `n_fit'
restore

* ----------------------------------------------------------------
* 3. Simulate a data refresh: the injected values come back, so the
*    reconstruction (dropna) now keeps `n_total' rows while the fit
*    used `n_fit'. The two disagree by construction.
* ----------------------------------------------------------------
replace female = female_orig if mi(female)
quietly count if mi(female)
assert r(N) == 0

* ----------------------------------------------------------------
* 4. Marker path: attach must compute on the persisted e(sample)
*    (the internal guard passes at n = `n_fit')
* ----------------------------------------------------------------
attach_inversion_ci,            ///
    estbase(smk5c_TZA_c1)       ///
    sterdir("$dir/output")      ///
    outcome(logpc_consumption)  ///
    traj(trajectory)            ///
    choice(choice)              ///
    hhid(pid)                   ///
    base(`base')                ///
    controls(`periodFE' $covs_gmm)

estimates use "$dir/output/smk5c_TZA_c1.ster"
assert e(inv_phi_ci95_lo) < .
di as text ">>> marker path on refreshed data: PASS (computed on e(sample) = `n_fit', not `n_total')"

* ----------------------------------------------------------------
* 5. Fallback path: remove the marker; the reconstruction keeps all
*    `n_total' rows, so the e(N) guard must trip with exit 460
* ----------------------------------------------------------------
erase "`marker'"

capture noisily attach_inversion_ci,  ///
    estbase(smk5c_TZA_c1)             ///
    sterdir("$dir/output")            ///
    outcome(logpc_consumption)        ///
    traj(trajectory)                  ///
    choice(choice)                    ///
    hhid(pid)                         ///
    base(`base')                      ///
    controls(`periodFE' $covs_gmm)
local fb_rc = _rc
di as text "fallback rc = `fb_rc' (expected 460)"
assert `fb_rc' == 460
di as text ">>> fallback on refreshed data: PASS (diverging reconstruction refused, exit 460)"

di as text ">>> CONTRACT_STAGE5_ESAMPLE: ALL PASS"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> CONTRACT_STAGE5_ESAMPLE FAILED with rc=`saved_rc'"
}
