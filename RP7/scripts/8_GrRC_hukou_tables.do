/*******************************************************************************
8_GrRC_hukou_tables.do --- LaTeX tables for the 12 hukou-subgroup cells
(4 hukou subgroups × 3 spec3) without re-running GMM. Reads existing
.ster files; emits via grc_tex_table_trend_hukou.

Sibling to 8_GrRC_hukou.do.

Hukou call shape:
  country()  receives the M11-compressed `country_short` (e.g. CHN_rf_cuu)
             which the program uses to build the ster lookup name
             grc_<country>_<covs2>{,_n,_g}.
  filename() receives the verbose `country` (e.g. CHN_hukou_rural_first)
             so the .tex output file matches the historical naming.

Per-cell explicit calls (no loop) so any single cell can be commented
out and re-run individually.
*******************************************************************************/

cd "$logs"
capture log close
log using 8_GrRC_hukou_tables.log, replace

local reportvars "phi:_cons"
local varlab "$\phi$"

* P1 indicator-rows (5-col)
local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* **********************************************************************
* Rural Hukou First  (CHN_rf_*)  --- 3 cells
* **********************************************************************

* Rural First | Consumption | Urban | Unbalanced
local country       CHN_hukou_rural_first
local country_short CHN_rf_cuu
local choice  urban
local depvar  consumption
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Rural First | Consumption | Urban | Balanced
local country       CHN_hukou_rural_first
local country_short CHN_rf_cub
local choice  urban
local depvar  consumption
local balance bal
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Rural First | Income | Urban | Unbalanced
local country       CHN_hukou_rural_first
local country_short CHN_rf_iuu
local choice  urban
local depvar  income
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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
* Urban Hukou First  (CHN_uf_*)  --- 3 cells
* **********************************************************************

* Urban First | Consumption | Urban | Unbalanced
local country       CHN_hukou_urban_first
local country_short CHN_uf_cuu
local choice  urban
local depvar  consumption
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Urban First | Consumption | Urban | Balanced
local country       CHN_hukou_urban_first
local country_short CHN_uf_cub
local choice  urban
local depvar  consumption
local balance bal
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Urban First | Income | Urban | Unbalanced
local country       CHN_hukou_urban_first
local country_short CHN_uf_iuu
local choice  urban
local depvar  income
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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
* Only Rural Hukou  (CHN_ro_*)  --- 3 cells
* **********************************************************************

* Only Rural | Consumption | Urban | Unbalanced
local country       CHN_hukou_rural_only
local country_short CHN_ro_cuu
local choice  urban
local depvar  consumption
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Only Rural | Consumption | Urban | Balanced
local country       CHN_hukou_rural_only
local country_short CHN_ro_cub
local choice  urban
local depvar  consumption
local balance bal
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Only Rural | Income | Urban | Unbalanced
local country       CHN_hukou_rural_only
local country_short CHN_ro_iuu
local choice  urban
local depvar  income
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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
* Only Urban Hukou  (CHN_uo_*)  --- 3 cells
* **********************************************************************

* Only Urban | Consumption | Urban | Unbalanced
local country       CHN_hukou_urban_only
local country_short CHN_uo_cuu
local choice  urban
local depvar  consumption
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Only Urban | Consumption | Urban | Balanced
local country       CHN_hukou_urban_only
local country_short CHN_uo_cub
local choice  urban
local depvar  consumption
local balance bal
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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

* Only Urban | Income | Urban | Unbalanced
local country       CHN_hukou_urban_only
local country_short CHN_uo_iuu
local choice  urban
local depvar  income
local balance unb
grc_tex_table_trend_hukou, columns(5)                   ///
    country(`country_short')                            ///
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
