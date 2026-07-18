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
* estnames arrive lowercased (Stata's dir macro lowercases filenames on
* Windows), so match on the lowercased form
gen byte moved = regexm(lower(estname), "grc_idn_cuu") | ///
    regexm(lower(estname), "grc_tza_cuu") | regexm(lower(estname), "vv_tza")
gen expected_delta = cond(regexm(lower(estname), "grc_idn_cuu"), 1, ///
    cond(moved, 2, 0))
gen final_verdict = tier_verdict
replace final_verdict = "EXPECTED_N_CHANGE" if moved & ///
    tier_verdict == "FAIL_PROVENANCE" & n_base - n_new == expected_delta
gen byte gate_fail = (!moved & tier_verdict != "PASS_BITWISE") | ///
    (moved & final_verdict != "EXPECTED_N_CHANGE")
export delimited using "`stagedir'/gate_results.csv", replace

quietly count if gate_fail
local n_fail = r(N)

* ---- coefficient movement for the moved pairs (the harness skips the
* b/V comparison when provenance differs, so compute it from the ster
* pairs directly: max over e(b) of |new-old| / (|old| + 1e-12))
quietly levelsof estname if moved, local(mvnames) clean
tempname M
postfile `M' str40 estname double max_b_reldiff ///
    using "`stagedir'/moved_movement.dta", replace
foreach nm of local mvnames {
    quietly estimates use "`base'/`nm'.ster"
    matrix __b0 = e(b)
    quietly estimates use "`refit'/`nm'.ster"
    matrix __b1 = e(b)
    mata: st_numscalar("__mrd", max(abs(st_matrix("__b1") - st_matrix("__b0")) :/ (abs(st_matrix("__b0")) :+ 1e-12)))
    post `M' ("`nm'") (scalar(__mrd))
}
postclose `M'
preserve
    use "`stagedir'/moved_movement.dta", clear
    export delimited using "`stagedir'/moved_movement.csv", replace
    quietly sum max_b_reldiff
    di as text _newline "Moved cells for author sign-off: coefficient movement" ///
        " (max relative e(b) change) min=" %12.4e r(min) " mean=" %12.4e r(mean) " max=" %12.4e r(max)
    gsort -max_b_reldiff
    list estname max_b_reldiff in 1/10, clean noobs
restore

di as text _newline "Moved cells (enumerated N change):"
list estname n_base n_new if moved, clean noobs

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
