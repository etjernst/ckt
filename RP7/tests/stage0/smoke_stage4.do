* *******************************************************************
* Title:   Stage 4 smoke test: sample-drop split, CRITICAL-1, computed
*          non-switcher rule, scaffolding labels and never-code
* Author:  Emilia Tjernstrom
* Date:    2026-07-18
* Purpose: Verify the Stage 4 front-end changes on cells built in
*          memory against an emulation from the canonical hub: the
*          rebuilt row set equals hub rows minus recomputed-singleton
*          rows minus missing-logpc rows; descriptors are true on
*          every surviving row; the computed non_switcher_2waves rule
*          reproduces the old hand-enumerated lists; the trajectory
*          contract carries grc_never and the dummies carry labels.
* Input:   RP7/data/countries (raw), RP7/data/processed (canonical hub)
* Output:  none (assertions only; log is the artifact)
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
* Cell 1: IDN unb consumption
* ----------------------------------------------------------------
* Old-side emulation: canonical hub rows minus rows whose recomputed
* per-pid count is 1 (CRITICAL-1), minus missing-logpc rows (Stage 3)
use "$dirdata/processed/IDN_unb.dta", clear
assert _N == 93038
bysort pid: gen tn = _N
quietly count if tn == 1
di as text "IDN emulation: recomputed-singleton rows = " r(N)
drop if tn == 1
drop if mi(logpc_consumption)
local n_expected = _N
rename logpc_consumption logpc_o
rename non_switcher non_switcher_o
keep pid period logpc_o non_switcher_o
tempfile oldside
save `oldside'

* New-side: full front-end build in memory
data_setup IDN urban consumption unb
di as text "IDN new build N = " _N " (expected `n_expected')"
assert _N == `n_expected'

* Descriptors true on every surviving row
bysort pid: gen tn2 = _N
assert obs_per_individual == tn2
assert nr_periods_obs == tn2
by pid: egen byte hasfirst = max(pid_first_obs)
assert hasfirst == 1
bysort pid (year): assert pid_first_obs == (_n == 1)
quietly count if obs_per_individual == 1
di as text "IDN new build: kept individuals with one estimable wave (rows) = " r(N)
drop tn2 hasfirst

* Row set and values match the emulation
merge 1:1 pid period using `oldside', assert(3) nogen
assert logpc_consumption == logpc_o
assert non_switcher == non_switcher_o

* Contract carries the never-code; dummies carry labels
assert "`: char _dta[grc_never]'" == "1"
assert "`: var label always'" != ""
assert "`: var label never'" != ""
setup_grc_estimation
assert "$never" == "1"
di as text ">>> IDN unb consumption: PASS (N=`n_expected', descriptors true, contract + labels present)"

* ----------------------------------------------------------------
* Cell 2: TZA unb consumption, 2waves variant (computed rule check)
* ----------------------------------------------------------------
* Old-side emulation from the canonical 2waves cell (list-based
* non_switcher_2waves); TZA has no missing-logpc rows, so the only
* removals are the recomputed-singleton rows
use "$dirdata/processed/TZA_unb_2waves.dta", clear
assert _N == 29864
bysort pid: gen tn = _N
quietly count if tn == 1
di as text "TZA emulation: recomputed-singleton rows = " r(N)
drop if tn == 1
local n_expected = _N
rename non_switcher_2waves nsw2_o
rename switcher_2waves sw2_o
rename trajectory_2waves traj2_o
keep pid period nsw2_o sw2_o traj2_o
tempfile oldside2
save `oldside2'

data_setup_2waves TZA urban consumption unb
di as text "TZA 2waves new build N = " _N " (expected `n_expected')"
assert _N == `n_expected'
merge 1:1 pid period using `oldside2', assert(3) nogen
assert trajectory_2waves == traj2_o
assert non_switcher_2waves == nsw2_o | (mi(non_switcher_2waves) & mi(nsw2_o))
assert switcher_2waves == sw2_o
di as text ">>> TZA unb 2waves: PASS (computed non-switcher rule = old hand lists)"

* ----------------------------------------------------------------
* Cell 3: IDN unb consumption, 2waves variant (descriptor refresh
* under real drops: 588 missing-logpc waves leave after the _2waves
* descriptors were first computed)
* ----------------------------------------------------------------
data_setup_2waves IDN urban consumption unb
bysort pid: gen tn3 = _N
assert obs_per_individual == tn3
assert obs_per_individual_2waves == tn3
by pid: egen byte hasfirst2 = max(pid_first_obs_2waves)
assert hasfirst2 == 1
bysort pid (year): assert pid_first_obs_2waves == (_n == 1)
drop tn3 hasfirst2
di as text ">>> IDN unb 2waves: PASS (suffixed descriptors true after drops)"

* ----------------------------------------------------------------
* CHN raw-file key uniqueness (isid coverage)
* ----------------------------------------------------------------
use_data CHN
di as text ">>> CHN raw: PASS (isid pid period holds)"

di as text ">>> SMOKE_STAGE4: ALL PASS"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> SMOKE_STAGE4 FAILED with rc=`saved_rc'"
}
