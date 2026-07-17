* *******************************************************************
* Title:   Gate-panel slice of 7_GrRC_hukou.do (Stage 0 baseline)
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Runs the two gate-panel hukou cells (CHN_rf_cuu and
*          CHN_uf_cuu) exactly as 7_GrRC_hukou.do does; the blocks
*          below are verbatim copies of that script's sections 1
*          (rural first, consumption, unbalanced) and 1 (urban first,
*          consumption, unbalanced). Do not edit the blocks here;
*          re-slice from the source script if it changes.
* Input:   processed cells via $dirdata; programs from 0_programs.do
* Output:  gate-panel hukou sters in $dir/output
* *******************************************************************

capture log close
log using "$logs/gate_panel_hukou.log", replace

* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_rural_first
local country_short CHN_rf_cuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars logpc_consumption trajectory choice pid 
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values logpc_consumption,       ///
    switchers($switchers)      ///
    balance(`balance')         ///
    estname(initial_`country_short')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

* ************
* Specify general command for GMM
* ************
local iterations $grc_max_iter

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
/* c0 (no covariates) no longer estimated (2026-07-01): dropped from the
   tables and often non-convergent. Uncomment to restore.
run_grc, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 


* Add female
run_grc, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC | urban hukou first
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_urban_first
local country_short CHN_uf_cuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars logpc_consumption trajectory choice pid 
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values logpc_consumption,       ///
    switchers($switchers)      ///
    balance(`balance')         ///
    estname(initial_`country_short')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

* ************
* Specify general command for GMM
* ************
local iterations $grc_max_iter

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
/* c0 (no covariates) no longer estimated (2026-07-01): dropped from the
   tables and often non-convergent. Uncomment to restore.
run_grc, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 


* Add female
run_grc, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Tables for this section are produced by the sibling _tables.do file
* (reads existing .ster files via grc_tex_table_trend's internal load).
* Run that separately to refresh tables without re-running GMM.

capture log close
