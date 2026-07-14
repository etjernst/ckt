* *******************************************************************
* Title:   Gate-harness self-test (known-good and known-bad pairs)
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Proves gate_compare returns the right verdict on three
*          pairs with known answers before it gates any refactor
*          stage: a ster against itself (PASS_BITWISE), a fit with a
*          1e-2 input nudge (FAIL_TOLERANCE), and a fit with a 1e-9
*          input nudge (PASS_TOLERANCE: not bitwise, inside the mixed
*          criterion). Asserts all three; any wrong verdict aborts.
* Input:   none (deterministic scratch data, no RNG)
* Output:  quality_reports/staging/stage0/selftest_gate_results.csv
*          RP7/tests/stage0/selftest/ (three scratch sters)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* load gate_compare; gate_harness.do sets $stage0dir and manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/selftest_gate_run.log", replace text

local sdir "C:/git/ckt/RP7/tests/stage0/selftest"
capture mkdir "`sdir'"
local results "$stage0dir/selftest_gate_results.csv"
capture erase "`results'"

* deterministic scratch data
clear
set obs 200
gen double x = _n/100
gen double y = 1 + 2*x + sin(_n)/10

* base fit
reg y x
estimates save "`sdir'/selftest_base.ster", replace

* large perturbation: one observation nudged by 1e-2
gen double y_big = y
replace y_big = y_big + 1e-2 in 1
reg y_big x
estimates save "`sdir'/selftest_big.ster", replace

* tiny perturbation: one observation nudged by 1e-9
gen double y_tiny = y
replace y_tiny = y_tiny + 1e-9 in 1
reg y_tiny x
estimates save "`sdir'/selftest_tiny.ster", replace

gate_compare, estname(selftest_base) refit_ster("`sdir'/selftest_base.ster") ///
    basedir("`sdir'") resultsfile("`results'")
gate_compare, estname(selftest_base) refit_ster("`sdir'/selftest_big.ster") ///
    basedir("`sdir'") resultsfile("`results'")
gate_compare, estname(selftest_base) refit_ster("`sdir'/selftest_tiny.ster") ///
    basedir("`sdir'") resultsfile("`results'")

* assert the three known verdicts
import delimited using "`results'", clear varnames(1) stringcols(_all)
assert _N == 3
assert tier_verdict[1] == "PASS_BITWISE"
assert tier_verdict[2] == "FAIL_TOLERANCE"
assert tier_verdict[3] == "PASS_TOLERANCE"
di as result ">>> HARNESS SELF-TEST: ALL THREE VERDICTS CORRECT"

log close
