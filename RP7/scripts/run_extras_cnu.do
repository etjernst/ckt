* **********************************************************************
* run_extras_cnu.do
*
* Family slice driver for the IDN cnu (nonag) x experience-families block
* of 9_GRC_extras.do. Reads the non-ag dataset (IDN_unb_nonag.dta) and
* runs the four experience-family regressors.
*
* Cells (4 stems x 4 cols = 16 fits = 80 sters):
*   IDN cnu x {exp, exp_max, exp_share, exp_max_share}
*
* NOTE: this driver does NOT include the IDN cnu x urbanbirth cell ---
* that one belongs in run_extras_birth.do because it reads the URBAN
* dataset (IDN_unb.dta), not the nonag dataset, per the 9_GRC_extras.do
* comment block reproducing file-15 historical behavior.
*
* Invoke with:
*   stata-mp -e do run_extras_cnu.do
* **********************************************************************

clear all
version 17

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}
if "${dir}" == "" {
    di as error "run_extras_cnu: \$dir not set for user `c(username)'"
    exit 198
}

include "$dir/scripts/0_path_config.do"
quietly include "$scripts/0_programs.do"

global skip_if_exists 1
global copyOverleaf   0

capture log close
log using "$logs/run_extras_cnu.log", replace

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
