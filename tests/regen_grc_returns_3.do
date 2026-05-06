* ============================================================
* Title:   Regenerate the 3 GRC §grc-returns tables (cuu)
* Author:  Emilia (with Claude)
* Date:    2026-05-01
* Purpose: One-shot rebuild of GRC_{IDN,CHN,TZA}_consumption_urban_unb.tex
*          to verify the Phase 1b.6 blank-row strip in grc_tex_table_trend
*          (added to 0_programs.do this session).
* Input:   RP7/output/grc_{IDN,CHN,TZA}_cuu_<covs2>{,_n,_g}.ster (existing)
* Output:  RP7/output/tables/GRC_{IDN,CHN,TZA}_consumption_urban_unb.tex
*          (overwrites)
* ============================================================

clear all
set more off
set varabbrev off

global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
global values "nominal"
quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

capture log close
log using "$logs/regen_grc_returns_3.smcl", replace

capture noisily {

local reportvars "phi:_cons"
local varlab "$\phi$"
local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

local choice  urban
local depvar  consumption
local balance unb

foreach country in IDN CHN TZA {
    di as text _newline "===> Building GRC_`country'_`depvar'_`choice'_`balance'.tex"
    grc_tex_table_trend, columns(5)                         ///
        spec(cuu)                                           ///
        country(`country')                                  ///
        filename(GRC_`country'_`depvar'_`choice'_`balance') ///
        keep(`reportvars')                                  ///
        varlabel(`varlab')                                  ///
        postfoot(`postfoot_str')                            ///
        coeflabels(choice "Urban")                          ///
        textdepvar( log(`depvar') )
}

di as text _newline "===> Done. Files at $output/tables/GRC_*_consumption_urban_unb.tex"

}
local saved_rc = _rc
capture log close
exit, STATA clear
