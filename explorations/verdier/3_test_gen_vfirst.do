* ============================================================
* Title:   Unit test for gen_vfirst helper
* Author:  Emilia (with Claude)
* Date:    2026-04-23
* Purpose: Validate that gen_vfirst returns the value of a variable
*          at the EARLIEST observed year per pid, NOT the smallest
*          numeric value across years (which is what the buggy
*          min(cond(...)) version did).
* Input:   None (synthetic data built in-memory).
* Output:  3_test_gen_vfirst.smcl + .txt log; assertion failures
*          surface as Stata errors that abort the do-file.
* ============================================================

clear all
set more off
set varabbrev off
capture log close
log using "3_test_gen_vfirst.smcl", replace text

version 17

* ----------------------------------------------------------------
* Helper under test
* ----------------------------------------------------------------
capture program drop gen_vfirst
program define gen_vfirst
    syntax , vname(varname) genname(name)
    capture drop `genname'
    tempvar seq mark tmp
    bysort pid (year): gen `seq' = sum(!missing(`vname'))
    by pid: gen `mark' = (!missing(`vname')) & (`seq' == 1)
    gen `tmp' = `vname' if `mark'
    by pid: egen `genname' = max(`tmp')
end

* ----------------------------------------------------------------
* Fabricated panel: 5 pids x 3 waves = 15 rows
* Each pid is a test case. vname holds province codes.
* ----------------------------------------------------------------
input long pid int year long vname int expected_vfirst str20 case_label
1 1   11  11  "A_stayer_all_11"
1 2   11  11  "A_stayer_all_11"
1 3   11  11  "A_stayer_all_11"
2 1    .  11  "B_missing_wave1"
2 2   11  11  "B_missing_wave1"
2 3   22  11  "B_missing_wave1"
3 1   22  22  "C_mover_low_to_high"
3 2   11  22  "C_mover_low_to_high"
3 3   11  22  "C_mover_low_to_high"
4 1    .  11  "D_late_entrant"
4 2    .  11  "D_late_entrant"
4 3   11  11  "D_late_entrant"
5 1   11  11  "E_mid_panel_missing"
5 2    .  11  "E_mid_panel_missing"
5 3   22  11  "E_mid_panel_missing"
end

list pid year vname expected_vfirst case_label, sepby(pid) abbrev(20)

* ----------------------------------------------------------------
* Run the helper
* ----------------------------------------------------------------
gen_vfirst, vname(vname) genname(vfirst)

list pid year vname vfirst expected_vfirst case_label, sepby(pid) abbrev(20)

* ----------------------------------------------------------------
* Assertions
* ----------------------------------------------------------------
* Every row's vfirst must equal expected_vfirst.
count if vfirst != expected_vfirst
local n_mismatches = r(N)
display _newline as text "Number of mismatches: " as result `n_mismatches'

if `n_mismatches' > 0 {
    display as error "TEST FAILED: vfirst != expected_vfirst on " `n_mismatches' " rows"
    list pid year vname vfirst expected_vfirst case_label if vfirst != expected_vfirst, abbrev(20)
    error 9
}

display _newline as result "TEST PASSED: gen_vfirst returns first-wave value for all 5 cases."

* ----------------------------------------------------------------
* Cross-check against the BUGGY min(cond(...)) version on case C
* (mover, low->high) where the bug is most visible.
* ----------------------------------------------------------------
display _newline as text "--- Cross-check: buggy min(cond(...)) version ---"
bysort pid (year): egen vfirst_BUGGY = min(cond(!missing(vname), vname, .))

list pid year vname vfirst vfirst_BUGGY expected_vfirst case_label, sepby(pid) abbrev(20)

count if vfirst_BUGGY != expected_vfirst
local n_buggy_mismatches = r(N)
display _newline as text "Buggy version mismatches (expected to be > 0): " ///
    as result `n_buggy_mismatches'

if `n_buggy_mismatches' == 0 {
    display as error "WARNING: buggy version also passes; test cases not discriminating enough"
}
else {
    display as result "Confirmed: buggy version mismatches on " `n_buggy_mismatches' " rows; corrected version is necessary."
}

log close

* Translate SMCL to plain text for easier reading
capture translate "3_test_gen_vfirst.smcl" "3_test_gen_vfirst.txt", replace

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
