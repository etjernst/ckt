* *******************************************************************
* Title:   Stage 3+4 hub equivalence: enumerated-delta check
* Author:  Emilia Tjernstrom
* Date:    2026-07-18
* Purpose: Compare every processed cell in the canonical hub
*          (RP7/data/processed) against the Stage 3+4 rebuild
*          (RP7/data_rebuild/processed). Allowed deltas, and nothing
*          else:
*            rows: the rebuild drops exactly the recomputed-singleton
*              rows (per-pid surviving-wave count of 1) and the
*              missing-per-capita-outcome rows of the old cell;
*            variables: the rebuild adds only the GRC scaffolding
*              dummies (always, always_choice, never, switcher_*);
*            values: the per-individual descriptors must equal the
*              recomputed truth on the surviving rows; every other
*              common variable must be bitwise identical.
* Input:   processed cells in RP7/data and RP7/data_rebuild
* Output:  quality_reports/staging/stage34/hub_stage34_check.csv
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"
local oldp "$dir/data/processed"
local newp "$dir/data_rebuild/processed"
local outp "C:/git/ckt/quality_reports/staging/stage34"
capture mkdir "`outp'"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/compare_hub_stage34_run.log", replace text

local descvars "nr_periods_obs obs_per_individual pid_first_obs obs_per_individual_2waves pid_first_obs_2waves obs_per_individual_3waves pid_first_obs_3waves"

local cells : dir "`newp'" files "*.dta"
local n_cells : word count `cells'
di as text "cells in rebuild: `n_cells'"

tempname S
postfile `S' str40 cell long(n_old n_removed_singleton n_removed_mi n_new) ///
    long(n_unmatched n_vars_diffing n_desc_wrong) ///
    str244 vars_only_old str244 unexpected_new str12 verdict ///
    using "`outp'/hub_stage34_check.dta", replace

local n_fail = 0
foreach f of local cells {
    local cell = subinstr("`f'", ".dta", "", 1)

    local outc "logpc_consumption"
    if strpos("`cell'", "_income") local outc "logpc_income"

    di as text "===== `cell' (`outc') ====="

    * ---- load old, mark the rows the rebuild is expected to remove
    use "`oldp'/`f'", clear
    local n_old = _N
    bysort pid: gen __tn = _N
    quietly count if __tn == 1
    local n_removed_singleton = r(N)
    quietly count if mi(`outc') & __tn > 1
    local n_removed_mi = r(N)
    drop if __tn == 1 | mi(`outc')
    drop __tn
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

    * ---- varlist deltas: nothing may vanish; only scaffolding may appear
    local only_old ""
    foreach v of local oldvars {
        if !`: list v in newvars' local only_old "`only_old' `v'"
    }
    local unexpected_new ""
    foreach v of local newvars {
        if `: list v in oldvars' continue
        if !regexm("`v'", "^(always|always_choice|never|switcher_[0-9]+(_choice)?)$") {
            local unexpected_new "`unexpected_new' `v'"
        }
    }
    local only_old = strtrim("`only_old'")
    local unexpected_new = strtrim("`unexpected_new'")

    * ---- merge on the panel key against the trimmed old cell
    merge 1:1 pid period using "`oldT'"
    quietly count if _merge != 3
    local n_unmatched = r(N)

    * ---- descriptors must equal the recomputed truth on the new rows
    local n_desc_wrong = 0
    bysort pid: gen __tn2 = _N
    bysort pid (year): gen __first = (_n == 1)
    foreach v of local descvars {
        capture confirm variable `v'
        if _rc continue
        if regexm("`v'", "first") {
            quietly count if `v' != __first
        }
        else {
            quietly count if `v' != __tn2
        }
        if r(N) > 0 {
            local ++n_desc_wrong
            di as error "  DESC WRONG `v': " r(N) " rows"
        }
    }
    drop __tn2 __first

    * ---- every other common variable bitwise equal on matched rows
    local n_vars_diffing = 0
    foreach v of local newvars {
        if inlist("`v'", "pid", "period") continue
        if `: list v in descvars' continue
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

    * ---- verdict
    local verdict "PASS"
    if `n_new' != `n_old' - `n_removed_singleton' - `n_removed_mi' local verdict "FAIL"
    if `n_unmatched' > 0        local verdict "FAIL"
    if `n_vars_diffing' > 0     local verdict "FAIL"
    if `n_desc_wrong' > 0       local verdict "FAIL"
    if "`only_old'" != ""       local verdict "FAIL"
    if "`unexpected_new'" != "" local verdict "FAIL"
    if "`verdict'" == "FAIL" local ++n_fail

    post `S' ("`cell'") (`n_old') (`n_removed_singleton') (`n_removed_mi') ///
        (`n_new') (`n_unmatched') (`n_vars_diffing') (`n_desc_wrong') ///
        ("`only_old'") ("`unexpected_new'") ("`verdict'")
}

postclose `S'

use "`outp'/hub_stage34_check.dta", clear
export delimited using "`outp'/hub_stage34_check.csv", replace

if `n_fail' > 0 {
    di as error ">>> STAGE 3+4 HUB CHECK: `n_fail' of `n_cells' cells FAIL"
}
else {
    di as result ">>> STAGE 3+4 HUB CHECK: all `n_cells' cells PASS (enumerated deltas only)"
}

log close
