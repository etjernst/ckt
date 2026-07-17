* *******************************************************************
* Title:   Stage 0 hub characterization: old hub vs rebuilt hub
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Compare every processed cell in the stale hub (RP7/data)
*          against the rebuilt hub (RP7/data_rebuild) and attribute
*          each difference to one of the three post-build commits:
*          47b60e3 (lndepvar per-capita: new = old - ln(hhsize_cube)),
*          a11e013 (Change A: strict-spec reflag, bal cells drop
*          individuals, unb cells flip unbalanced 0->1),
*          1e10113 (C10: non_switcher moves only for unbalanced workers).
* Input:   processed cells in RP7/data and RP7/data_rebuild
* Output:  quality_reports/staging/stage0/hub_characterization.csv
*          quality_reports/staging/stage0/hub_var_diffs.csv
* Historical artifact: the lndepvar-signature diagnostic below targets
*          the pre-rename variable name and must run against the
*          pre-rename hub. After the Stage 2 rename (lndepvar ->
*          logpc_consumption / logpc_income), it silently no-ops
*          against the live hub. Do not re-run this file for live signal.
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"
local oldp  "$dir/data/processed"
local newp  "$dir/data_rebuild/processed"
local outp  "C:/git/ckt/quality_reports/staging/stage0"

* Enumerate cells from the rebuilt hub
local cells : dir "`newp'" files "*.dta"

tempname S V
postfile `S' str40 cell long(n_old n_new rows_old_only rows_new_only) ///
    long(reflag_0to1 reflag_1to0 chgA_pred_drops chgA_mismatch) ///
    double lndep_sig_maxabs long(nonsw_diff_bal nonsw_diff_unb) ///
    str244 vars_only_old str244 vars_only_new ///
    using "`outp'/hub_characterization.dta", replace
postfile `V' str40 cell str32 varname long n_diff ///
    using "`outp'/hub_var_diffs.dta", replace

foreach f of local cells {
    local cell = subinstr("`f'", ".dta", "", 1)
    di as text "===== `cell' ====="

    * ---- load old, stash varlist, rename non-key vars with _o suffix
    use "`oldp'/`f'", clear
    local n_old = _N
    unab oldvars : *
    ds pid period, not
    foreach v of varlist `r(varlist)' {
        rename `v' `v'_o
    }
    tempfile oldT
    save "`oldT'"

    * ---- load new, stash varlist
    use "`newp'/`f'", clear
    local n_new = _N
    unab newvars : *

    * ---- varlist deltas
    local only_old ""
    foreach v of local oldvars {
        if !`: list v in newvars' local only_old "`only_old' `v'"
    }
    local only_new ""
    foreach v of local newvars {
        if !`: list v in oldvars' local only_new "`only_new' `v'"
    }

    * ---- merge on the panel key
    merge 1:1 pid period using "`oldT'"
    quietly count if _merge == 2
    local rows_old_only = r(N)
    quietly count if _merge == 1
    local rows_new_only = r(N)

    * ---- Change A signature on the flag (matched rows)
    local reflag01 = 0
    local reflag10 = 0
    capture confirm variable unbalanced unbalanced_o
    if _rc == 0 {
        quietly count if _merge == 3 & unbalanced_o == 0 & unbalanced == 1
        local reflag01 = r(N)
        quietly count if _merge == 3 & unbalanced_o == 1 & unbalanced == 0
        local reflag10 = r(N)
    }

    * ---- Change A signature on dropped rows (bal cells): dropped pids
    *      must be exactly the pids the strict-spec rule flags in the
    *      old data (rule recomputed on old variables)
    local chgA_pred = 0
    local chgA_mism = 0
    capture confirm variable hhsize_cube_o female_o age_o education_max_o
    if _rc == 0 & `rows_old_only' > 0 {
        tempvar mrow pmiss dropped
        gen byte `mrow' = missing(hhsize_cube_o) | hhsize_cube_o <= 0 | ///
            missing(female_o) | missing(age_o) | missing(education_max_o) ///
            if _merge != 1
        bysort pid: egen byte `pmiss' = max(`mrow')
        gen byte `dropped' = _merge == 2
        quietly count if `pmiss' == 1 & _merge != 1
        local chgA_pred = r(N)
        quietly count if `dropped' != `pmiss' & _merge != 1
        local chgA_mism = r(N)
    }

    * ---- lndepvar signature: new = old - ln(hhsize_cube)
    local sigmax = .
    capture confirm variable lndepvar lndepvar_o hhsize_cube
    if _rc == 0 {
        tempvar sig
        gen double `sig' = abs(lndepvar - (lndepvar_o - ln(hhsize_cube))) ///
            if _merge == 3
        quietly summarize `sig'
        local sigmax = r(max)
    }

    * ---- C10 signature: non_switcher diffs only where unbalanced == 1
    local nsw_bal = 0
    local nsw_unb = 0
    capture confirm variable non_switcher non_switcher_o unbalanced
    if _rc == 0 {
        quietly count if _merge == 3 & non_switcher != non_switcher_o ///
            & unbalanced == 0
        local nsw_bal = r(N)
        quietly count if _merge == 3 & non_switcher != non_switcher_o ///
            & unbalanced == 1
        local nsw_unb = r(N)
    }

    * ---- generic per-variable mismatch count on matched rows
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
            post `V' ("`cell'") ("`v'") (r(N))
        }
    }

    post `S' ("`cell'") (`n_old') (`n_new') (`rows_old_only') ///
        (`rows_new_only') (`reflag01') (`reflag10') (`chgA_pred') ///
        (`chgA_mism') (`sigmax') (`nsw_bal') (`nsw_unb') ///
        ("`only_old'") ("`only_new'")
}

postclose `S'
postclose `V'

use "`outp'/hub_characterization.dta", clear
export delimited using "`outp'/hub_characterization.csv", replace
use "`outp'/hub_var_diffs.dta", clear
export delimited using "`outp'/hub_var_diffs.csv", replace
di as text ">>> CHARACTERIZATION COMPLETE"
