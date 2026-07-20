* **********************************************************************
* run_extras_maxexpsh.do
*
* Family slice driver for 9_GRC_extras.do's max_experience_share block.
* Runs the 9 stems below; $skip_if_exists short-circuits any cell whose
* _g$vsfx.ster is already on disk, so it is safe to launch alongside
* 0_master.do / run_master_resume.do. (The remaining concern is a
* timing-based race: if both processes start the same un-fit cell at
* the same instant, both fit it and the second save wins; the resulting
* sters are byte-identical when initial values converge.)
*
* Cells (6 stems x 4 cols = 24 fits = 120 sters):
*   {IDN, CHN, TZA} x {cuu, cub} x exp_max_share
*
* USAGE
* -----
*   stata-mp -e do run_extras_maxexpsh.do
*
* For real-values mode (deflated CPI, $dir/data_real), edit the
* `global values` line below to "real" and re-launch.
* **********************************************************************

clear all
version 17

* values: "nominal" or "real" (deflated CPI, appends _r to output filenames).
global values "nominal"

* $dir per user. Mirrors 0_master.do.
if "`c(username)'"=="kleemans" {
    global dir = "C:\Users\kleemans\Dropbox\Returns to migration\ReplicationPackage6"
    global dir = "D:\Dropbox\Returns to migration\ReplicationPackage6"
}
if "`c(username)'"=="David" {
    global dir = "C:\Users\David\OneDrive - University of Illinois - Urbana\UIUC\Research\ReplicationPackage6"
}
if inlist("`c(username)'", "ecenci", "educenci", "eduardocenci") {
    global dir = "~/Dropbox/__Research/Returns to migration/ReplicationPackage6"
}
if "`c(username)'"=="etje0002" {
    global dir = "C:/Users/etje0002/Desktop/git/ReturnsToMigration"
}
if "`c(username)'"=="maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
    global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

include "$dir/scripts/0_slice_bootstrap.do"

capture log close
log using "$logs/run_extras_maxexpsh$vsfx.log", replace

capture noisily {
    * cuu (consumption, urban, unbalanced) x 3 countries
    run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp_max_share)

    * cub (consumption, urban, balanced) x 3 countries
    run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_max_share)
}
local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> run_extras_maxexpsh FAILED with rc=`saved_rc'"

exit, STATA clear
