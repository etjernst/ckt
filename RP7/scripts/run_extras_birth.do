* **********************************************************************
* run_extras_birth.do
*
* Family slice driver for 9_GRC_extras.do's birth (urbanbirth) block.
* IDN-only family.
*
* Cells (4 stems x 4 cols = 16 fits = 80 sters):
*   IDN x {cuu, cub, iuu} x urbanbirth   -- use spec3 default datasets
*   IDN x cnu       x urbanbirth          -- overrides default cnu data
*                                            path to IDN_unb.dta (urban),
*                                            faithful to historical
*                                            file-15 behavior.
*
* Invoke with:
*   stata-mp -e do run_extras_birth.do
* **********************************************************************

clear all
version 17

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}
if "${dir}" == "" {
    di as error "run_extras_birth: \$dir not set for user `c(username)'"
    exit 198
}

include "$dir/scripts/0_path_config.do"
quietly include "$scripts/0_programs.do"

global skip_if_exists 1
global copyOverleaf   0

capture log close
log using "$logs/run_extras_birth.log", replace

capture noisily {
    run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(urbanbirth)
    run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(urbanbirth)
    run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(urbanbirth)

    * IDN cnu x birth overrides the default cnu dataset; see 9_GRC_extras.do.
    run_grc_with_extra_regressor, country(IDN) spec3(cnu) regressor(urbanbirth) ///
        data_path_override("$dirdata/processed/IDN_unb.dta")
}
local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> run_extras_birth FAILED with rc=`saved_rc'"

exit, STATA clear
