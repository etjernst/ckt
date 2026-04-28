/*******************************************************************************
6_GrRC_NonAg_tables.do --- LaTeX table for IDN cons/nonag/unb (cnu)
without re-running GMM. Reads existing .ster files; emits via
grc_tex_table_trend.

Sibling to 6_GrRC_NonAg.do.
*******************************************************************************/

cd "$logs"
capture log close
log using 6_GrRC_NonAg_tables.log, replace

local reportvars "phi:_cons"
local varlab "$\phi$"

* P1 indicator-rows (5-col main GRC tables)
local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* **********************************************************************
* 1. Consumption | Nonag | Unbalanced  (spec3=cnu) --- IDN only
* **********************************************************************
local choice  nonag
local depvar  consumption
local balance unb

* INDONESIA
local country IDN
grc_tex_table_trend, columns(5)                         ///
    spec(cnu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Non-Ag")                         ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

log close
