* *******************************************************************
* Title:   Stage 6 contract test: run_grc_robust_vv leaves the
*          caller's data untouched across calls
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Build the scenario byte-identity cannot probe: a cluster
*          index (vindexA) with injected all-wave missingness for a
*          subset of pids, so the fitter's internal missing-vfirst
*          drop removes those pids in call 1. Call 2 then fits on the
*          intact index (region) and must recover the FULL baseline
*          sample, including the injected pids, proving the drop did
*          not persist. After each call the caller's data must be
*          row-for-row identical to a pre-call snapshot and carry no
*          leaked vfirst/swd_* columns.
* Input:   canonical hub via the stage6_ctroot data junction
* Output:  ct6_TZA_* sters and markers in stage6_ctroot/output (test
*          artifacts; safe to delete); log is the test artifact
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage6_ctroot"

include "C:/git/ckt/RP7/scripts/0_path_config.do"
quietly include "C:/git/ckt/RP7/scripts/0_programs.do"

capture log close
log using "$logs/contract_stage6_vv_sample.log", replace text

capture noisily {

* ----------------------------------------------------------------
* 1. Load TZA (smallest country), mirroring 17_verdier_robust.do's
*    prep: setup, keepvars incl. year (gen_vfirst sorts pid year)
* ----------------------------------------------------------------
local country TZA
local balance unb
local vidx    region

set_covariate_globals

global keepvars logpc_consumption trajectory choice pid year
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

use "$dirdata/processed/`country'_`balance'.dta", clear
setup_grc_estimation
keep $keepvars `vidx'

local n_total = _N

* ----------------------------------------------------------------
* 2. Build vindexA: a copy of region set to missing in ALL waves for
*    every 50th individual (group() numbers pids densely, so the rule
*    is deterministic). vfirst is missing exactly for pids with no
*    non-missing index value in any wave, so call 1 must drop the
*    injected pids' rows internally.
* ----------------------------------------------------------------
egen long pidgrp = group(pid)
gen vindexA = `vidx'
replace vindexA = . if mod(pidgrp, 50) == 0

* Expected fit samples, computed independently of the fitter:
* rows whose pid has at least one non-missing index value.
tempvar hasA hasR
bysort pid: egen byte `hasA' = max(!missing(vindexA))
bysort pid: egen byte `hasR' = max(!missing(`vidx'))
quietly count if `hasA' == 1
local nA = r(N)
quietly count if `hasR' == 1
local nR = r(N)
di as text "n_total = `n_total'; expected e(N): call 1 (vindexA) = `nA', call 2 (region) = `nR'"
assert `nA' < `nR'
assert `nR' <= `n_total'
drop `hasA' `hasR'

* ----------------------------------------------------------------
* 3. Initial values (as the driver computes them, once, up front),
*    then snapshot the caller's data
* ----------------------------------------------------------------
initial_values logpc_consumption,   ///
    switchers($switchers)           ///
    balance(`balance')              ///
    estname(initial_`country')
local base    `r(base)'
local initial "`r(initial)'"

quietly describe, short
local k_pre = r(k)
tempfile presnap
quietly save "`presnap'"

* ----------------------------------------------------------------
* 4. Call 1 on the injected index: fits on the reduced sample, must
*    hand back the untouched caller data
* ----------------------------------------------------------------
run_grc_robust_vv,                                        ///
    estname(ct6_TZA_A)                                    ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance') vindex(vindexA)                    ///
    iterate(100) onestep

assert _N == `n_total'
capture confirm variable vfirst
assert _rc != 0
capture confirm variable swd_switcher_`base'_choice
assert _rc != 0
quietly describe, short
assert r(k) == `k_pre'
cf _all using "`presnap'"
di as text ">>> call 1 caller-data check: PASS (rows, columns, and values all unchanged)"

estimates use "$dir/output/ct6_TZA_A.ster"
di as text "call 1 e(N) = " e(N) " (expected `nA')"
assert e(N) == `nA'
preserve
    use "$dir/output/ct6_TZA_A_esample.dta", clear
    assert _N == `nA'
restore
di as text ">>> call 1 fit-sample check: PASS (reduced sample = `nA')"

* ----------------------------------------------------------------
* 5. Call 2 on the intact index: must fit on the FULL baseline
*    sample, including the pids call 1 dropped internally. Under the
*    pre-fix code this is exactly where the persisted drop would
*    shrink the sample to `nA' or fewer.
* ----------------------------------------------------------------
run_grc_robust_vv,                                        ///
    estname(ct6_TZA_B)                                    ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance') vindex(`vidx')                     ///
    iterate(100) onestep

assert _N == `n_total'
cf _all using "`presnap'"
di as text ">>> call 2 caller-data check: PASS"

estimates use "$dir/output/ct6_TZA_B.ster"
di as text "call 2 e(N) = " e(N) " (expected `nR', pre-fix code would give <= `nA')"
assert e(N) == `nR'
preserve
    use "$dir/output/ct6_TZA_B_esample.dta", clear
    assert _N == `nR'
restore
di as text ">>> call 2 fit-sample check: PASS (full baseline recovered)"

di as text ">>> CONTRACT_STAGE6_VV_SAMPLE: ALL PASS"
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> CONTRACT_STAGE6_VV_SAMPLE FAILED with rc=`saved_rc'"
}

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/contract_stage6_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
