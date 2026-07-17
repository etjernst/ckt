* *******************************************************************
* Title:   Stage 2 hub equivalence: rename-only check
* Author:  Emilia Tjernstrom
* Date:    2026-07-17
* Purpose: Compare every processed cell in the canonical hub
*          (RP7/data/processed, built pre-rename) against the Stage 2
*          rebuild (RP7/data_rebuild/processed). The rebuild must be a
*          pure rename: same N, same rows, every common variable
*          bitwise identical, and logpc_<outcome> bitwise identical to
*          the old lndepvar. The only allowed varlist delta is
*          lndepvar -> logpc_consumption / logpc_income. (The rebuilt
*          cells additionally carry the _dta covariate characteristic
*          stashed by set_covariates; characteristics carry no values,
*          so the row-level comparison is unaffected.)
* Input:   processed cells in RP7/data and RP7/data_rebuild
* Output:  quality_reports/staging/stage2/hub_rename_check.csv
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"
local oldp "$dir/data/processed"
local newp "$dir/data_rebuild/processed"
local outp "C:/git/ckt/quality_reports/staging/stage2"
capture mkdir "`outp'"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/compare_hub_stage2_run.log", replace text

local cells : dir "`newp'" files "*.dta"
local n_cells : word count `cells'
di as text "cells in rebuild: `n_cells'"

tempname S
postfile `S' str40 cell long(n_old n_new n_unmatched) ///
    long(n_vars_diffing) long outcome_diff_n ///
    str244 vars_only_old str244 vars_only_new str12 verdict ///
    using "`outp'/hub_rename_check.dta", replace

local n_fail = 0
foreach f of local cells {
    local cell = subinstr("`f'", ".dta", "", 1)

    * outcome the renamed variable holds in this cell
    local outc "logpc_consumption"
    if strpos("`cell'", "_income") local outc "logpc_income"

    di as text "===== `cell' (`outc') ====="

    * ---- load old, suffix non-key vars with _o
    use "`oldp'/`f'", clear
    local n_old = _N
    unab oldvars : *
    ds pid period, not
    foreach v of varlist `r(varlist)' {
        rename `v' `v'_o
    }
    tempfile oldT
    save "`oldT'"

    * ---- load new
    use "`newp'/`f'", clear
    local n_new = _N
    unab newvars : *

    * ---- varlist deltas (expected: lndepvar only-old, `outc' only-new)
    local only_old ""
    foreach v of local oldvars {
        if !`: list v in newvars' local only_old "`only_old' `v'"
    }
    local only_new ""
    foreach v of local newvars {
        if !`: list v in oldvars' local only_new "`only_new' `v'"
    }
    local only_old = strtrim("`only_old'")
    local only_new = strtrim("`only_new'")

    * ---- merge on the panel key
    merge 1:1 pid period using "`oldT'"
    quietly count if _merge != 3
    local n_unmatched = r(N)

    * ---- every common variable bitwise equal on matched rows
    local n_vars_diffing = 0
    foreach v of local newvars {
        if inlist("`v'", "pid", "period") continue
        if !`: list v in oldvars' continue
        capture confirm string variable `v'
        if _rc == 0 {
            quietly count if _merge == 3 & `v' != `v'_o
        }
        else {
            quietly count if _merge == 3 & ///
                !(`v' == `v'_o | (missing(`v') & missing(`v'_o)))
        }
        if r(N) > 0 {
            local ++n_vars_diffing
            di as error "  DIFF `v': " r(N) " rows"
        }
    }

    * ---- the renamed outcome must equal the old lndepvar bitwise
    local outcome_diff_n = .
    capture confirm variable `outc' lndepvar_o
    if _rc == 0 {
        quietly count if _merge == 3 & ///
            !(`outc' == lndepvar_o | (missing(`outc') & missing(lndepvar_o)))
        local outcome_diff_n = r(N)
    }

    * ---- verdict
    local verdict "PASS"
    if `n_old' != `n_new'                       local verdict "FAIL"
    if `n_unmatched' > 0                        local verdict "FAIL"
    if `n_vars_diffing' > 0                     local verdict "FAIL"
    if "`only_old'" != "lndepvar"               local verdict "FAIL"
    if "`only_new'" != "`outc'"                 local verdict "FAIL"
    if `outcome_diff_n' > 0 | `outcome_diff_n' >= . local verdict "FAIL"
    if "`verdict'" == "FAIL" local ++n_fail

    post `S' ("`cell'") (`n_old') (`n_new') (`n_unmatched') ///
        (`n_vars_diffing') (`outcome_diff_n') ///
        ("`only_old'") ("`only_new'") ("`verdict'")
}

postclose `S'

use "`outp'/hub_rename_check.dta", clear
export delimited using "`outp'/hub_rename_check.csv", replace

if `n_fail' > 0 {
    di as error ">>> STAGE 2 HUB CHECK: `n_fail' of `n_cells' cells FAIL"
}
else {
    di as result ">>> STAGE 2 HUB CHECK: all `n_cells' cells PASS (pure rename)"
}

log close
