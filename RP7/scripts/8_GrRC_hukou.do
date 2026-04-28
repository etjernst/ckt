/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Nov 2025
This code:
    - runs restricted GRC regressions for
        - all countries: unbalanced sample, urban as choice
        - all countries: balanced sample, urban as choice
    - outcomes: consumption per capita (adult equivalent: cube) and income
    - covariates (columns): (1) nothing, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 8_GrRC_hukou.log, replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis
*     Countries:          `country'
*     Choice variable:    urban / nonag
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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_rural_first
local country_short CHN_rf_cuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2    
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_rural_first
local country_short CHN_rf_cub

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"  ///
    , subdir(tables)
}

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
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar $lnsize trajectory choice pid 
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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_rural_first
local country_short CHN_rf_iuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}


local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************


* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_urban_first
local country_short CHN_uf_cuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2    
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_urban_first
local country_short CHN_uf_cub

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex"  ///
    , subdir(tables)
}

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
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar $lnsize trajectory choice pid 
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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_urban_first

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}


local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************


* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_rural_only
local country_short CHN_ro_cuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2    
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_rural_only
local country_short CHN_ro_cub

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex"  ///
    , subdir(tables)
}

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
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar $lnsize trajectory choice pid 
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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_rural_only
local country_short CHN_ro_iuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}


local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************


* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb
local country CHN_hukou_urban_only
local country_short CHN_uo_cuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex" ///
    , subdir(tables)
}

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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2    
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal
local country CHN_hukou_urban_only
local country_short CHN_uo_cub

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
    estimates use "$dir/output/grc_`country_short'_`estname'"
    estimates store grc_`country_short'_`estname'
    estimates use "$dir/output/grc_`country_short'_`estname'_n"
    estimates store grc_`country_short'_`estname'_n
    estimates use "$dir/output/grc_`country_short'_`estname'_g"
    estimates store grc_`country_short'_`estname'_g
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************



local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex"  ///
    , subdir(tables)
}

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
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar $lnsize trajectory choice pid 
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
local iterations 100

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* No covariates
run_grc_hukou, estname(grc_`country_short'_c0)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations') 

* Add time FE
run_grc_hukou, estname(grc_`country_short'_ct)                         ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations') 

* Add female
run_grc_hukou, estname(grc_`country_short'_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations') 

* Add age2
run_grc_hukou, estname(grc_`country_short'_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2)                                  ///
    iterate(`iterations') 

* Add education & education2
run_grc_hukou, estname(grc_`country_short'_ca)                           ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all)                               ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}

* Display a simple table of results
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country_short'_c0 grc_`country_short'_ct     ///
    grc_`country_short'_c1 grc_`country_short'_c2         ///
    grc_`country_short'_ca                            ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb
local country CHN_hukou_urban_only
local country_short CHN_uo_iuu

* Make sure estimates are in memory
foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country_short'_`estname'"
        estimates store grc_`country_short'_`estname'
        estimates use "$dir/output/grc_`country_short'_`estname'_n"
        estimates store grc_`country_short'_`estname'_n
        estimates use "$dir/output/grc_`country_short'_`estname'_g"
        estimates store grc_`country_short'_`estname'_g
}


local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* CHINA
* **********************************************************************


* Run program to create output table
grc_tex_table_trend_hukou, columns(5)                         ///
    country(`country_short')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_r.tex" ///
    , subdir(tables)
}

* **********************************************************************
log close
