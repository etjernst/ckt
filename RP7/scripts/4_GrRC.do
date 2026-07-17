/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
    - runs restricted GRC regressions for
        - all countries: unbalanced sample, urban as choice
        - all countries: balanced sample, urban as choice
    - outcome: consumption per capita (adult equivalent: cube)
    - covariates (columns): (1) nothing, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
capture log close
log using "$logs/4_GrRC.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis
*     Countries:          IDN / TZA / CHN
*     Choice variable:    urban / nonag
*     Dependent variable: consumption
*     Panel structure:    bal / unb 
* ********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars logpc_consumption trajectory choice pid
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

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* ************
* Store initial values for GMM, program returns "base" trajectory in r(base) 
* & stores estimates in the string defined in estname() option
* add option print to see the initial values
* ************
initial_values logpc_consumption,        ///
    switchers($switchers)       ///
    balance(`balance')          ///
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cuu_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */

* Add time FE
run_grc, estname(grc_`country'_cuu_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* TANZANIA
* **********************************************************************
eststo clear
local country TZA

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
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cuu_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 

* Add time FE
run_grc, estname(grc_`country'_cuu_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear
local country CHN

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
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cuu_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 

* Add time FE
run_grc, estname(grc_`country'_cuu_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Tables for this section are produced by the sibling _tables.do file
* (reads existing .ster files via grc_tex_table_trend's internal load).
* Run that separately to refresh tables without re-running GMM.
* **********************************************************************

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars logpc_consumption trajectory choice pid
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
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cub_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 

* Add time FE
run_grc, estname(grc_`country'_cub_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cub_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cub_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cub_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* TANZANIA
* **********************************************************************
eststo clear
local country TZA

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
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cub_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 

* Add time FE
run_grc, estname(grc_`country'_cub_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cub_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cub_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cub_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear
local country CHN

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
    estname(initial_`country')
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
run_grc, estname(grc_`country'_cub_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') */ 

* Add time FE
run_grc, estname(grc_`country'_cub_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cub_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cub_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2    
run_grc, estname(grc_`country'_cub_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Tables for this section are produced by the sibling _tables.do file
* (reads existing .ster files via grc_tex_table_trend's internal load).
* Run that separately to refresh tables without re-running GMM.
* **********************************************************************

log close
