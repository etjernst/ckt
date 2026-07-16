* *******************************************************************
* Title:   Stage 0 determinism proof: compare double-fit to baseline
* Author:  Emilia Tjernstrom
* Date:    2026-07-16
* Purpose: gate_compare every ster of the hukou double-fit
*          (baseline_root2/output) against the frozen baseline
*          (baseline_root/output). Identical code and data, so all
*          30 pairs (2 cells x 3 specs x 5 ster files) must be
*          PASS_BITWISE; anything else means the pipeline is not
*          run-to-run deterministic and Stage 1 must not start.
* Input:   both shadow-root output directories, gate_harness.do
* Output:  quality_reports/staging/stage0/determinism_results.csv
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* defines gate_compare and $stage0dir; manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/gate_determinism_compare_run.log", replace text

local base    "C:/git/ckt/RP7/tests/stage0/baseline_root/output"
local refit   "C:/git/ckt/RP7/tests/stage0/baseline_root2/output"
local results "$stage0dir/determinism_results.csv"
capture erase "`results'"

foreach cell in CHN_rf_cuu CHN_uf_cuu {
    foreach spec in c1 c2 ca {
        foreach suf in "" _n _a _d _g {
            local nm grc_`cell'_`spec'`suf'
            gate_compare, estname(`nm') refit_ster("`refit'/`nm'.ster") ///
                basedir("`base'") resultsfile("`results'")
        }
    }
}

import delimited using "`results'", clear varnames(1) stringcols(_all)
quietly count if tier_verdict != "PASS_BITWISE"
if r(N) > 0 {
    di as error ">>> DETERMINISM: `r(N)' of `=_N' pairs NOT bitwise identical"
    list estname tier_verdict max_crit_ratio if tier_verdict != "PASS_BITWISE", clean
}
else {
    di as result ">>> DETERMINISM PROOF: all `=_N' ster pairs PASS_BITWISE"
}

log close
