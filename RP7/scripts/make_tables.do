/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Apr 2026

make_tables.do --- regenerate ALL LaTeX tables produced by the GRC
pipeline (main 5_GrRC + 6_NonAg + 8_hukou + 16_heterogeneity) without
re-running any GMM. Reads existing .ster files from $dir/output/ and
emits .tex via grc_tex_table_trend / _hukou / het_table_*.

Replaces:
  5_GrRC_tables.do          (9 cells, cuu/cub/iuu × IDN/CHN/TZA)
  6_GrRC_NonAg_tables.do    (1 cell, IDN cnu)
  8_GrRC_hukou_tables.do    (12 cells, 4 hukou subgroups × 3 spec3)
  16_heterogeneity_tables.do (6 cells, Delta + Mu × IDN/CHN/TZA)
                             --- 28 GRC tables total.

Run whenever you need to refresh the .tex tables (e.g. after a
paper-side caption tweak) without paying the GMM cost. Per-cell
calls are explicit (no loops over country/spec) so any single cell
can be commented out and re-run individually.

Heterogeneity tables (Section 16) need per-country data loading and
setup_grc_estimation to discover $switchers (the trajectory numlist),
which then drives the keep/coeflabel lists. Other sections only need
sters on disk.
*******************************************************************************/

* set log file
capture log close
log using "$logs/make_tables.log", replace

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

/*******************************************************************************
6_GrRC_NonAg_tables.do --- LaTeX table for IDN cons/nonag/unb (cnu)
without re-running GMM. Reads existing .ster files; emits via
grc_tex_table_trend.

Sibling to 6_GrRC_NonAg.do.
*******************************************************************************/

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

* **********************************************************************
* Heterogeneity Delta and mu tables (per-country)
* Reads sters from $output, writes hetdelta_<country>.tex and
* hetmu_table_<country>.tex.
* **********************************************************************

* **********************************************************************
* Consumption | Urban | Unbalanced | GRC | Heterogeneity Tables
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* INDONESIA
* **********************************************************************
eststo clear
local country IDN

* Open dataset
use "$dirdata/processed/`country'_`balance'.dta", clear

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

decode trajectory, gen(traj_str)

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values lndepvar,        ///
    switchers($switchers)       ///
    balance(`balance')          ///
    estname(initial_`country')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

* ************
* Specify general command for GMM 
* ************
local iterations 100

* ************
* GMM estimate is read from 5_GrRC.do's output rather than re-run here,
* both to avoid the ster-filename collision with 5_GrRC.do and because
* the spec is identical (urban, all covariates, time FE). The estimates
* are loaded below via `estimates use`.
* ************

* Build the ordered coefficient list we want in the Delta table
local `country'_keep_list_delta ""
foreach s of numlist $switchers {
	local `country'_keep_list_delta "``country'_keep_list_delta' Delta_`s'"
}

* Build coeflabels for Delta using the trajectories associated with each switcher_s
local `country'_coeflabs_delta ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_delta `"``country'_coeflabs_delta' Delta_`s' "`rowlab'""'
}

* Build the ordered coefficient list we want in the mu table
local `country'_keep_list_mu ""
foreach s of numlist $switchers {
	local `country'_keep_list_mu "``country'_keep_list_mu' mu:switcher_`s'"
}

* Build coeflabels for mu using the trajectories associated with each switcher_s
local `country'_coeflabs_mu ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_mu `"``country'_coeflabs_mu' mu:switcher_`s' "`rowlab'""'
}

* **********************************************************************
* TANZANIA
* **********************************************************************
eststo clear
local country TZA

* Open dataset
use "$dirdata/processed/`country'_`balance'.dta", clear

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

decode trajectory, gen(traj_str)

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values lndepvar,       ///
    switchers($switchers)      ///
    balance(`balance')         ///
    estname(initial_`country')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

* ************
* Specify general command for GMM 
* ************
local iterations 100

* ************
* GMM estimate is read from 5_GrRC.do's output rather than re-run here,
* both to avoid the ster-filename collision with 5_GrRC.do and because
* the spec is identical (urban, all covariates, time FE). The estimates
* are loaded below via `estimates use`.
* ************

* Build the ordered coefficient list we want in the Delta table
local `country'_keep_list_delta ""
foreach s of numlist $switchers {
	local `country'_keep_list_delta "``country'_keep_list_delta' Delta_`s'"
}

* Build coeflabels for Delta using the trajectories associated with each switcher_s
local `country'_coeflabs_delta ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_delta `"``country'_coeflabs_delta' Delta_`s' "`rowlab'""'
}

* Build the ordered coefficient list we want in the mu table
local `country'_keep_list_mu ""
foreach s of numlist $switchers {
	local `country'_keep_list_mu "``country'_keep_list_mu' mu:switcher_`s'"
}

* Build coeflabels for mu using the trajectories associated with each switcher_s
local `country'_coeflabs_mu ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_mu `"``country'_coeflabs_mu' mu:switcher_`s' "`rowlab'""'
}

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear
local country CHN

* Open dataset
use "$dirdata/processed/`country'_`balance'.dta", clear

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

decode trajectory, gen(traj_str)

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values lndepvar,       ///
    switchers($switchers)      ///
    balance(`balance')         ///
    estname(initial_`country')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

* ************
* Specify general command for GMM
* ************
local iterations 100

* ************
* GMM estimate is read from 5_GrRC.do's output rather than re-run here,
* both to avoid the ster-filename collision with 5_GrRC.do and because
* the spec is identical (urban, all covariates, time FE). The estimates
* are loaded below via `estimates use`.
* ************

* Build the ordered coefficient list we want in the Delta table
local `country'_keep_list_delta ""
foreach s of numlist $switchers {
	local `country'_keep_list_delta "``country'_keep_list_delta' Delta_`s'"
}

* Build coeflabels for Delta using the trajectories associated with each switcher_s
local `country'_coeflabs_delta ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_delta `"``country'_coeflabs_delta' Delta_`s' "`rowlab'""'
}

* Build the ordered coefficient list we want in the mu table
local `country'_keep_list_mu ""
foreach s of numlist $switchers {
	local `country'_keep_list_mu "``country'_keep_list_mu' mu:switcher_`s'"
}

* Build coeflabels for mu using the trajectories associated with each switcher_s
local `country'_coeflabs_mu ""
foreach s of numlist $switchers {
	* find the trajectory code for this switcher
    quietly levelsof traj_str if switcher_`s'==1, local(lbls) clean
    local rowlab : word 1 of `lbls'
    local `country'_coeflabs_mu `"``country'_coeflabs_mu' mu:switcher_`s' "`rowlab'""'
}

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN CHN TZA {
		estimates use "$dir/output/grc_`country'_cuu_ca"
        estimates store grc_`country'_cuu_ca
		estimates use "$dir/output/grc_`country'_cuu_ca_d"
        estimates store grc_`country'_cuu_ca_d
    }

* Display a simple table of results
foreach country in IDN CHN TZA {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_cuu_ca	                  ///
    , star(.1 .05 .01) b(%7.3f) varlabel varwidth(35) ///
    stats(joint_chi2 joint_p)
estimates table                                       ///
    grc_`country'_cuu_ca_d                ///
    , star(.1 .05 .01) b(%7.3f) varlabel varwidth(35) ///
    stats(joint_chi2 joint_p)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb

/* Settings for GRC table
COLumns(integer):        Number of columns
FILEname(string asis):   Filename for the output LaTeX table
COUNTRY(string asis):    Names for each panel (space-separated list)
Keep(varlist):           List of variables to display in each panel
varlabel(string):		 Label for phi in table
htb(string):			 Chooses whether prehead of .tex table contains "htb!" or "htbp"
PREhead(string asis):    Prehead (space-separated strings)
POSTfoot(string asis):   Postfoot (space-separated strings)
COEFlabels(string asis): How to label vars (if different from var label)
TEXTdepvar(string asis): Dependent variable as string
*/

* Make sure estimates are in memory
foreach country in IDN CHN TZA {
		estimates use "$dir/output/grc_`country'_cuu_ca"
        estimates store grc_`country'_cuu_ca
		estimates use "$dir/output/grc_`country'_cuu_ca_d"
        estimates store grc_`country'_cuu_ca_d
    }

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN
* Delta table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetmu_table_`country'.tex" ///
    , subdir(tables)
}

* **********************************************************************
* CHINA
* **********************************************************************
local country CHN
* Delta table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetmu_table_`country'.tex" ///
    , subdir(tables)
}

* **********************************************************************
* TANZANIA
* **********************************************************************
local country TZA
* Delta table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )   
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table




local postfoot_str Time FE & Y \\ Covariates & All \\

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetmu_table_`country'.tex" ///
    , subdir(tables)
}

* **********************************************************************
* Phase 1b.6: extras family tables (44 cells, GRC_extras.do output)
* Wrapper extras_tex_table reads disambiguated sters
*   grc_<country>_<spec3>_<fam>_<col>.ster
* and writes one .tex per cell:
*   GRC_<country>_<depvar>_<choice>_<balance>_<file_suffix>.tex
* Each line is a 1-call per stem; explicit per-cell, no loops.
* **********************************************************************

* --- Family: experience  (regressor = exp) ---
extras_tex_table, country(IDN) spec3(cuu) regressor(exp)
extras_tex_table, country(CHN) spec3(cuu) regressor(exp)
extras_tex_table, country(TZA) spec3(cuu) regressor(exp)

extras_tex_table, country(IDN) spec3(cub) regressor(exp)
extras_tex_table, country(CHN) spec3(cub) regressor(exp)
extras_tex_table, country(TZA) spec3(cub) regressor(exp)

extras_tex_table, country(IDN) spec3(iuu) regressor(exp)
extras_tex_table, country(CHN) spec3(iuu) regressor(exp)
extras_tex_table, country(TZA) spec3(iuu) regressor(exp)

* --- Family: max_experience  (regressor = exp_max) ---
extras_tex_table, country(IDN) spec3(cuu) regressor(exp_max)
extras_tex_table, country(CHN) spec3(cuu) regressor(exp_max)
extras_tex_table, country(TZA) spec3(cuu) regressor(exp_max)

extras_tex_table, country(IDN) spec3(cub) regressor(exp_max)
extras_tex_table, country(CHN) spec3(cub) regressor(exp_max)
extras_tex_table, country(TZA) spec3(cub) regressor(exp_max)

extras_tex_table, country(IDN) spec3(iuu) regressor(exp_max)
extras_tex_table, country(CHN) spec3(iuu) regressor(exp_max)
extras_tex_table, country(TZA) spec3(iuu) regressor(exp_max)

* --- Family: experience_share  (regressor = exp_share) ---
extras_tex_table, country(IDN) spec3(cuu) regressor(exp_share)
extras_tex_table, country(CHN) spec3(cuu) regressor(exp_share)
extras_tex_table, country(TZA) spec3(cuu) regressor(exp_share)

extras_tex_table, country(IDN) spec3(cub) regressor(exp_share)
extras_tex_table, country(CHN) spec3(cub) regressor(exp_share)
extras_tex_table, country(TZA) spec3(cub) regressor(exp_share)

extras_tex_table, country(IDN) spec3(iuu) regressor(exp_share)
extras_tex_table, country(CHN) spec3(iuu) regressor(exp_share)
extras_tex_table, country(TZA) spec3(iuu) regressor(exp_share)

* --- Family: max_experience_share  (regressor = exp_max_share) ---
extras_tex_table, country(IDN) spec3(cuu) regressor(exp_max_share)
extras_tex_table, country(CHN) spec3(cuu) regressor(exp_max_share)
extras_tex_table, country(TZA) spec3(cuu) regressor(exp_max_share)

extras_tex_table, country(IDN) spec3(cub) regressor(exp_max_share)
extras_tex_table, country(CHN) spec3(cub) regressor(exp_max_share)
extras_tex_table, country(TZA) spec3(cub) regressor(exp_max_share)

extras_tex_table, country(IDN) spec3(iuu) regressor(exp_max_share)
extras_tex_table, country(CHN) spec3(iuu) regressor(exp_max_share)
extras_tex_table, country(TZA) spec3(iuu) regressor(exp_max_share)

* --- IDN cnu (nonag) x experience families (file 14) ---
extras_tex_table, country(IDN) spec3(cnu) regressor(exp)
extras_tex_table, country(IDN) spec3(cnu) regressor(exp_max)
extras_tex_table, country(IDN) spec3(cnu) regressor(exp_share)
extras_tex_table, country(IDN) spec3(cnu) regressor(exp_max_share)

* --- Family: birth  (regressor = urbanbirth; IDN-only) ---
extras_tex_table, country(IDN) spec3(cuu) regressor(urbanbirth)
extras_tex_table, country(IDN) spec3(cub) regressor(urbanbirth)
extras_tex_table, country(IDN) spec3(iuu) regressor(urbanbirth)
extras_tex_table, country(IDN) spec3(cnu) regressor(urbanbirth)

log close
