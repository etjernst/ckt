* *******************************************************************
* Title:   Bundled Stage 3+4 gate: compare refit to frozen baseline
* Author:  Emilia Tjernstrom
* Date:    2026-07-18
* Purpose: gate_compare every ster the bundled Stage 3+4 refit
*          produced (stage34_root/output) against the frozen baseline
*          (baseline_root/output). Expected outcome, and nothing else:
*          every pair PASS_BITWISE except the cells fit on IDN_unb
*          (grc_IDN_cuu*, one estimable singleton row removed, so
*          e(N) falls by exactly 1) and on TZA_unb (grc_TZA_cuu* and
*          vv_TZA_*, two rows removed, e(N) falls by exactly 2).
*          Those pairs are reclassified EXPECTED_N_CHANGE when the
*          provenance delta matches exactly; their coefficient
*          movement (max_crit_ratio, plus the full-precision b/V
*          dumps) is reported for author sign-off. Any other verdict
*          fails the gate.
* Input:   both shadow-root output directories, gate_harness.do
* Output:  quality_reports/staging/stage34/gate_results.csv
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* defines gate_compare and $stage0dir; manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/gate_stage34_compare_run.log", replace text

local base    "C:/git/ckt/RP7/tests/stage0/baseline_root/output"
local refit   "C:/git/ckt/RP7/tests/stage0/stage34_root/output"
local stagedir "C:/git/ckt/quality_reports/staging/stage34"
capture mkdir "`stagedir'"

* gate_cmp_mata writes its full-precision b/V dumps into $stage0dir;
* repoint it so the Stage 3+4 evidence lands in its own staging folder
global stage0dir "`stagedir'"

local results "`stagedir'/gate_results_raw.csv"
capture erase "`results'"

local sters : dir "`refit'" files "*.ster"
local n_sters : word count `sters'
if `n_sters' == 0 {
    di as error ">>> STAGE 3+4 GATE: no sters found in `refit'"
    exit 601
}
foreach f of local sters {
    local nm = subinstr("`f'", ".ster", "", .)
    gate_compare, estname(`nm') refit_ster("`refit'/`f'") ///
        basedir("`base'") resultsfile("`results'")
}

* ---- adjudicate against the enumerated expectation
import delimited using "`results'", clear varnames(1) stringcols(_all)
destring n_base n_new, replace
gen byte moved = regexm(estname, "grc_IDN_cuu") | ///
    regexm(estname, "grc_TZA_cuu") | regexm(estname, "vv_TZA")
gen expected_delta = cond(regexm(estname, "grc_IDN_cuu"), 1, ///
    cond(moved, 2, 0))
gen final_verdict = tier_verdict
replace final_verdict = "EXPECTED_N_CHANGE" if moved & ///
    tier_verdict == "FAIL_PROVENANCE" & n_base - n_new == expected_delta
gen byte gate_fail = (!moved & tier_verdict != "PASS_BITWISE") | ///
    (moved & final_verdict != "EXPECTED_N_CHANGE")
export delimited using "`stagedir'/gate_results.csv", replace

quietly count if gate_fail
local n_fail = r(N)
di as text _newline "Moved cells for author sign-off (enumerated N change; coefficient movement below):"
list estname n_base n_new max_crit_ratio if moved, clean noobs

if `n_fail' > 0 {
    di as error ">>> STAGE 3+4 GATE: `n_fail' of `=_N' pairs FAIL"
    list estname tier_verdict n_base n_new max_crit_ratio if gate_fail, clean noobs
}
else {
    quietly count if moved
    di as result ">>> STAGE 3+4 GATE: all `=_N' pairs as enumerated (" ///
        r(N) " EXPECTED_N_CHANGE, rest PASS_BITWISE)"
}

log close
