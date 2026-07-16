/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
    - runs restricted GRC regressions for the four CHN hukou subgroups
        - rural-only / urban-only / rural-first / urban-first
        - urban as choice; unbalanced and balanced panels
    - outcomes: consumption per capita (adult equivalent: cube) and income
    - covariates (columns): (1) nothing, (2) add time FE, (3) add female,
                            (4) add age^2, (5) add education (max) & education^2
    - hukou subgroups are built upstream by 0_CHN_hukou_restrictions.do
*******************************************************************************/

* set log file
capture log close
log using "$logs/7_GrRC_hukou.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis
*     Countries:          CHN (4 hukou subgroups)
*     Choice variable:    urban
*     Dependent variable: consumption / income
*     Panel structure:    bal / unb
* ********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC | rural hukou first
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
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC | rural hukou first
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_rural_first
local country_short CHN_rf_cub

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 3. Income | Urban | Unbalanced | GRC | rural hukou first
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_rural_first
local country_short CHN_rf_iuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'_income.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

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
* **********************************************************************

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
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC | urban hukou first
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_urban_first
local country_short CHN_uf_cub

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 3. Income | Urban | Unbalanced | GRC | urban hukou first
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_urban_first
local country_short CHN_uf_iuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'_income.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC | only rural hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_rural_only
local country_short CHN_ro_cuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC | only rural hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_rural_only
local country_short CHN_ro_cub

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 3. Income | Urban | Unbalanced | GRC | only rural hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_rural_only
local country_short CHN_ro_iuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'_income.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC | only urban hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_urban_only
local country_short CHN_uo_cuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC | only urban hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_urban_only
local country_short CHN_uo_cub

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid 
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

* ==> replace log consumption with log consumption per capita
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars // Dropping some vars can help speed up gmm

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
* **********************************************************************

* **********************************************************************
* 3. Income | Urban | Unbalanced | GRC | only urban hukou
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_urban_only
local country_short CHN_uo_iuu

* define GMM covariates (so they enter the first estimations)
set_covariate_globals

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear

* Open dataset
use "$dirdata/processed/`country'_`balance'_income.dta", clear

setup_grc_estimation
keep $keepvars // Dropping some can help speed up gmm

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
* **********************************************************************

log close
