/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Apr 2026 (Phase 1b.5b)

5_GrRC_tables.do --- regenerate the LaTeX tables for the 9 main GRC cells
(IDN/CHN/TZA × cuu/cub/iuu) without re-running GMM. Reads existing
.ster files from $dir/output/ and emits .tex via grc_tex_table_trend.

Sibling to 5_GrRC.do: 5_GrRC.do estimates and writes the .ster files;
this file consumes them and produces tables. Run this whenever you
need to refresh the .tex tables (e.g. after a paper-side caption tweak)
without paying the GMM cost.

Per-country grc_tex_table_trend calls are written explicitly (not in a
loop) so any single cell can be commented out and re-run individually.
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 5_GrRC_tables.log, replace

* Common args reused across all cells
local reportvars "phi:_cons"
local varlab "$\phi$"

* P1 indicator-rows (5-col main GRC tables)
local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* **********************************************************************
* 1. Consumption | Urban | Unbalanced  (spec3=cuu) --- 3 cells
* **********************************************************************
local choice  urban
local depvar  consumption
local balance unb

* INDONESIA
local country IDN
grc_tex_table_trend, columns(5)                         ///
    spec(cuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* CHINA
local country CHN
grc_tex_table_trend, columns(5)                         ///
    spec(cuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* TANZANIA
local country TZA
grc_tex_table_trend, columns(5)                         ///
    spec(cuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* **********************************************************************
* 2. Consumption | Urban | Balanced  (spec3=cub) --- 3 cells
* **********************************************************************
local choice  urban
local depvar  consumption
local balance bal

* INDONESIA
local country IDN
grc_tex_table_trend, columns(5)                         ///
    spec(cub)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* CHINA
local country CHN
grc_tex_table_trend, columns(5)                         ///
    spec(cub)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* TANZANIA
local country TZA
grc_tex_table_trend, columns(5)                         ///
    spec(cub)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* **********************************************************************
* 3. Income | Urban | Unbalanced  (spec3=iuu) --- 3 cells
* **********************************************************************
local choice  urban
local depvar  income
local balance unb

* INDONESIA
local country IDN
grc_tex_table_trend, columns(5)                         ///
    spec(iuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* CHINA
local country CHN
grc_tex_table_trend, columns(5)                         ///
    spec(iuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

* TANZANIA
local country TZA
grc_tex_table_trend, columns(5)                         ///
    spec(iuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"
if _rc == 0 & $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

log close
