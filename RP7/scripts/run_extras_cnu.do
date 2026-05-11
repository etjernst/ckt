* **********************************************************************
* run_extras_cnu.do
*
* Family slice driver for the IDN cnu (nonag) x experience-families
* block of 9_GRC_extras.do. Reads the non-ag dataset
* (IDN_unb_nonag.dta) and runs the four experience-family regressors.
*
* Cells (4 stems x 4 cols = 16 fits = 80 sters):
*   IDN cnu x {exp, exp_max, exp_share, exp_max_share}
*
* NOTE: this driver does NOT include the IDN cnu x urbanbirth cell
* --- that one belongs in run_extras_birth.do because it reads the
* URBAN dataset (IDN_unb.dta), not the nonag dataset, per the
* 9_GRC_extras.do comment block reproducing file-15 historical
* behavior.
*
* USAGE
* -----
*   stata-mp -e do run_extras_cnu.do
*
* For real-values mode (deflated CPI, $dir/data_real), edit the
* `global values` line below to "real" and re-launch.
* **********************************************************************

clear all
version 17

* ----------------------------------------------------------------------
* values switch (M4): "nominal" reads $dir/data; "real" reads
* $dir/data_real and appends "_r" ($vsfx) to ster/CSV/table filenames
* so nominal and real outputs coexist without clobbering. Default is
* nominal; edit here before launching to switch modes. 0_path_config.do
* picks this up via the $values global.
* ----------------------------------------------------------------------
global values "nominal"

* ----------------------------------------------------------------------
* $dir resolution per user. Mirrors 0_master.do; keep these blocks in
* sync if 0_master.do gains new users.
* ----------------------------------------------------------------------
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

if "${dir}" == "" {
    di as error "run_extras_cnu: \$dir not set for user `c(username)'."
    di as error "Add a user block above (mirror the layout in 0_master.do)."
    exit 198
}

* Set sub-directory globals ($scripts, $logs, $output, $dirdata) and
* project-wide constants ($grc_max_iter, $grc_min_switchers_per_wave).
* Reads $values to pick nominal vs. real data paths and $vsfx suffix.
include "$dir/scripts/0_path_config.do"

* Load all shared programs (run_grc_with_extra_regressor + dependencies).
* Quietly because the 155 KB file would otherwise saturate batch output.
quietly include "$scripts/0_programs.do"

* skip_if_exists=1: run_grc skips any cell whose _g$vsfx.ster is already
* on disk. Lets this slice coexist safely with a parallel 0_master.do
* run --- both processes agree on which cells still need fitting.
global skip_if_exists 1

* copyOverleaf=0: slice drivers don't run the table builders, but set
* this defensively in case any called helper attempts a copy.
global copyOverleaf   0

capture log close
log using "$logs/run_extras_cnu$vsfx.log", replace

capture noisily {
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp)
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_max)
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_share)
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(exp_max_share)
}
local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> run_extras_cnu FAILED with rc=`saved_rc'"

exit, STATA clear
