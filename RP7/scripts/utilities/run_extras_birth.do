* **********************************************************************
* run_extras_birth.do
*
* Family slice driver for 9_GRC_extras.do's birth (urbanbirth) block.
* IDN-only family.
*
* Cells (3 stems x 4 cols = 12 fits = 60 sters):
*   IDN x {cuu, cub} x urbanbirth        -- use spec3 default datasets
*   IDN x cnu       x urbanbirth          -- overrides default cnu data
*                                            path to IDN_unb.dta (urban),
*                                            faithful to file-15
*                                            historical behavior.
*
* USAGE
* -----
*   stata-mp -e do run_extras_birth.do
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
log using "$logs/run_extras_birth$vsfx.log", replace

capture noisily {
    run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(urbanbirth)
    run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(urbanbirth)

    * IDN cnu x birth overrides the default cnu dataset; see 9_GRC_extras.do.
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(urbanbirth) ///
        data_path_override("$dirdata/processed/IDN_unb.dta")
}
local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> run_extras_birth FAILED with rc=`saved_rc'"

exit, STATA clear
