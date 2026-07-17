* *******************************************************************
* Title:   ct-only slice of 7_GrRC_hukou.do (CHN_rf_cuu, CHN_uf_cuu)
* Author:  Emilia Tjernstrom
* Date:    2026-07-15
* Purpose: Supplementary Stage 0 baseline slice: the _ct (time-FE-
*          only) fits, which stay in the GRC tables per the author's
*          2026-07-15 decision. Blocks are verbatim copies of the
*          source script; re-slice from source if it changes.
* *******************************************************************

capture log close
log using "$logs/gate_panel_ct_hukou.log", replace

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

* Add time FE
run_grc, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
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

* Add time FE
run_grc, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 




* **********************************************************************
* Tables for this section are produced by the sibling _tables.do file
* (reads existing .ster files via grc_tex_table_trend's internal load).
* Run that separately to refresh tables without re-running GMM.

capture log close
