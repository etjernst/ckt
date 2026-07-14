* *******************************************************************
* Title:   Stage 0 OLS re-run on the rebuilt hub
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Run 3_OLS_uGRC.do and 6_OLS_uGRC_hukou.do unmodified
*          against the rebuilt hub (RP7/data_rebuild) into a fresh
*          output directory, for the combined raw-to-per-capita plus
*          Change A movement table. Canonical output untouched.
* Input:   processed cells in RP7/data_rebuild
* Output:  RP7/tests/stage0/ols_new/tables/ and logs/
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"

include "$dir/scripts/0_path_config.do"
include "$dir/scripts/0_programs.do"

* Fresh, isolated data/output/log roots for this run
global dirdata      "$dir/data_rebuild"
global output       "$dir/tests/stage0/ols_new"
global logs         "$dir/tests/stage0/ols_new/logs"
global copyOverleaf 0
capture mkdir "$dir/tests/stage0/ols_new"
capture mkdir "$output/tables"
capture mkdir "$logs"

* Free the unnamed log slot (-e batch holds it) so the scripts' own
* log using calls do not error with r(604)
capture log close

capture noisily {
    include "$dir/scripts/3_OLS_uGRC.do"
    include "$dir/scripts/6_OLS_uGRC_hukou.do"
}
local saved_rc = _rc

* The auto-log is closed, so record the return code to a file
tempname fh
file open `fh' using "$dir/tests/stage0/ols_new/rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
