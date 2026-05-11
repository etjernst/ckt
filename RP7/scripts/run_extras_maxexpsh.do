* **********************************************************************
* run_extras_maxexpsh.do
*
* Family slice driver for 9_GRC_extras.do's max_experience_share block.
* Runs just the 9 stems below; $skip_if_exists short-circuits any cell
* whose _g.ster is already on disk, so it is safe to launch alongside
* 0_master.do / run_master_resume.do as long as the user is willing to
* tolerate the race window (last writer wins; both writers produce
* byte-identical sters when initial values converge).
*
* Cells (9 stems x 4 cols = 36 fits = 180 sters):
*   {IDN, CHN, TZA} x {cuu, cub, iuu} x exp_max_share
*
* Invoke with:
*   stata-mp -e do run_extras_maxexpsh.do
* **********************************************************************

clear all
version 17

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}
if "${dir}" == "" {
    di as error "run_extras_maxexpsh: \$dir not set for user `c(username)'"
    exit 198
}

include "$dir/scripts/0_path_config.do"
quietly include "$scripts/0_programs.do"

global skip_if_exists 1
global copyOverleaf   0

capture log close
log using "$logs/run_extras_maxexpsh.log", replace

capture noisily {
    * cuu (consumption, urban, unbalanced) x 3 countries
    run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(CHN) spec3(cuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp_max_share)

    * cub (consumption, urban, balanced) x 3 countries
    run_grc_with_extra_regressor, country(IDN) spec3(cub) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(CHN) spec3(cub) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_max_share)

    * iuu (income, urban, unbalanced) x 3 countries
    run_grc_with_extra_regressor, country(IDN) spec3(iuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(CHN) spec3(iuu) regressor(exp_max_share)
    run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp_max_share)
}
local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> run_extras_maxexpsh FAILED with rc=`saved_rc'"

exit, STATA clear
