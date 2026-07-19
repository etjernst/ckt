* *******************************************************************
* Title:   Stage 5 smoke test: e(sample) marker write and marker-path
*          inversion attach, with fallback equivalence
* Author:  Emilia Tjernstrom
* Date:    2026-07-19
* Purpose: Verify that run_grc writes a labeled pid-period e(sample)
*          marker with exactly e(N) rows; that attach_inversion_ci
*          attaches CIs through the marker path with the e(N) guard
*          passing; and that the legacy fallback path (marker removed)
*          warns loudly and reproduces identical CI scalars on
*          zero-missingness data.
* Input:   RP7/data/processed/TZA_unb.dta (canonical hub)
* Output:  smk5_TZA_ct*.ster and smk5_TZA_ct_esample.dta in RP7/output
*          (smoke artifacts; safe to delete); log is the test artifact
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
* 1. Fit one fast cell (TZA cuu ct) under a smoke estname
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

initial_values logpc_consumption,   ///
    switchers($switchers)           ///
    balance(`balance')              ///
    estname(initial_`country')
local base    `r(base)'
local initial "`r(initial)'"

run_grc, estname(smk5_TZA_ct)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                    ///
    covars(`periodFE')                                    ///
    iterate(100)

* ----------------------------------------------------------------
* 2. Marker exists, is labeled, and has exactly e(N) rows
* ----------------------------------------------------------------
local marker "$dir/output/smk5_TZA_ct_esample.dta"
confirm file "`marker'"
estimates use "$dir/output/smk5_TZA_ct.ster"
local n_fit = e(N)
preserve
    use "`marker'", clear
    di as text "marker rows = " _N " (parent e(N) = `n_fit')"
    assert _N == `n_fit'
    isid pid period
    local dlab : data label
    assert strpos("`dlab'", "smk5_TZA_ct") > 0
restore
di as text ">>> marker write: PASS (labeled, keyed, `n_fit' rows)"

* ----------------------------------------------------------------
* 3. Attach through the marker path; guard must pass
* ----------------------------------------------------------------
attach_inversion_ci,            ///
    estbase(smk5_TZA_ct)        ///
    sterdir("$dir/output")      ///
    outcome(logpc_consumption)  ///
    traj(trajectory)            ///
    choice(choice)              ///
    hhid(pid)                   ///
    base(`base')                ///
    controls(`periodFE')

* the marker path returns with the parent estimates active and their
* true sample declared (session-only), so e(sample) is usable here
quietly count if e(sample)
assert r(N) == `n_fit'

estimates use "$dir/output/smk5_TZA_ct.ster"
assert e(inv_phi_ci95_lo) < .
scalar ci_lo_marker    = e(inv_phi_ci95_lo)
scalar ci_hi_marker    = e(inv_phi_ci95_hi)
scalar point_marker    = e(inv_phi_at_waldmin)
scalar dN_lo_marker    = e(inv_dN_ci95_lo)
di as text ">>> marker-path attach: PASS (phi 95% CI [" ci_lo_marker ", " ci_hi_marker "])"

* ----------------------------------------------------------------
* 4. Fallback path: remove the marker, re-attach, expect identical
*    scalars on zero-missingness data (reconstruction = fit sample)
* ----------------------------------------------------------------
copy "`marker'" "`marker'.bak", replace
erase "`marker'"

attach_inversion_ci,            ///
    estbase(smk5_TZA_ct)        ///
    sterdir("$dir/output")      ///
    outcome(logpc_consumption)  ///
    traj(trajectory)            ///
    choice(choice)              ///
    hhid(pid)                   ///
    base(`base')                ///
    controls(`periodFE')

estimates use "$dir/output/smk5_TZA_ct.ster"
assert e(inv_phi_ci95_lo)    == ci_lo_marker
assert e(inv_phi_ci95_hi)    == ci_hi_marker
assert e(inv_phi_at_waldmin) == point_marker
assert e(inv_dN_ci95_lo)     == dN_lo_marker
di as text ">>> fallback attach: PASS (identical CI scalars, loud warning above)"

* restore the marker so the smoke artifacts stay consistent
copy "`marker'.bak" "`marker'", replace
erase "`marker'.bak"

di as text ">>> SMOKE_STAGE5: ALL PASS"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> SMOKE_STAGE5 FAILED with rc=`saved_rc'"
}
