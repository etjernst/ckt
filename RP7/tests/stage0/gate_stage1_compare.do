* *******************************************************************
* Title:   Bundled Stage 1+2 gate: compare refit to frozen baseline
* Author:  Emilia Tjernstrom
* Date:    2026-07-16
* Purpose: gate_compare every ster the bundled Stage 1+2 refit
*          produced (stage1_root/output) against the frozen baseline
*          (baseline_root/output). Stage 1 removes value-identical
*          covariate redeclarations and Stage 2 renames the per-capita
*          outcome to logpc_consumption and removes value-identical
*          replace sites; neither touches row order, so every pair
*          must be PASS_BITWISE (Tier 2); anything else stops the
*          stage.
* Input:   both shadow-root output directories, gate_harness.do
* Output:  quality_reports/staging/stage1/gate_results.csv
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* defines gate_compare and $stage0dir; manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/gate_stage1_compare_run.log", replace text

local base    "C:/git/ckt/RP7/tests/stage0/baseline_root/output"
local refit   "C:/git/ckt/RP7/tests/stage0/stage1_root/output"
local stagedir "C:/git/ckt/quality_reports/staging/stage1"
capture mkdir "`stagedir'"

* gate_cmp_mata writes its full-precision b/V dumps into $stage0dir;
* repoint it so stage 1 evidence lands in the stage 1 staging folder
* instead of clobbering the stage 0 dumps
global stage0dir "`stagedir'"

local results "`stagedir'/gate_results.csv"
capture erase "`results'"

* every ster the refit produced is compared; with the Verdier leg in
* the bundled refit, the refit set matches the baseline set
local sters : dir "`refit'" files "*.ster"
local n_sters : word count `sters'
if `n_sters' == 0 {
    di as error ">>> STAGE 1 GATE: no sters found in `refit'"
    exit 601
}
foreach f of local sters {
    local nm = subinstr("`f'", ".ster", "", .)
    gate_compare, estname(`nm') refit_ster("`refit'/`f'") ///
        basedir("`base'") resultsfile("`results'")
}

import delimited using "`results'", clear varnames(1) stringcols(_all)
quietly count if tier_verdict != "PASS_BITWISE"
if r(N) > 0 {
    di as error ">>> STAGE 1 GATE: `r(N)' of `=_N' pairs NOT bitwise identical"
    list estname tier_verdict max_crit_ratio if tier_verdict != "PASS_BITWISE", clean
}
else {
    di as result ">>> STAGE 1 GATE: all `=_N' ster pairs PASS_BITWISE"
}

log close
