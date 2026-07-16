* *******************************************************************
* Title:   Gate-panel slice of 9_GRC_extras.do (Stage 0 baseline)
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Runs the single gate-panel extras stem (experience family,
*          IDN, consumption urban unbalanced) exactly as
*          9_GRC_extras.do does. Verbatim call; re-slice from the
*          source script if it changes.
* Input:   processed cells via run_grc_with_extra_regressor
* Output:  gate-panel extras sters in $dir/output
* *******************************************************************

capture log close
log using "$logs/gate_panel_extras.log", replace

run_grc_with_extra_regressor, country(IDN) spec3(cuu) regressor(exp)

capture log close
