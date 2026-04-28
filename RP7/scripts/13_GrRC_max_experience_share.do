/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Nov 2025
This code:
    - runs restricted GRC regressions for
        - all countries: unbalanced sample, urban as choice
        - all countries: balanced sample, urban as choice
    - outcomes: consumption per capita (adult equivalent: cube) and income
    - covariates (columns): (1) max experience share, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 13_GrRC_max_experience_share.log, replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis
*     Countries:          IDN / TZA / CHN
*     Choice variable:    urban / nonag
*     Dependent variable: consumption / income
*     Panel structure:    bal / unb 
* ********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | GRC | Max Experience Share
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp_m_sh		   	"exp_max_share"
global covs_gmm2_exp_m_sh	   		"$covs_gmm_exp_m_sh female"
global covs_gmm3_exp_m_sh			"$covs_gmm2_exp_m_sh age2"
global covs_gmm_all_exp_m_sh 		"$covs_gmm3_exp_m_sh education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid exp_max_share
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
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

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
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

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
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN CHN TZA {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
        estimates store grc_`country'_cuu_maxexpsh_`estname'
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_n
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
    }

* Display a simple table of results
foreach country in IDN CHN TZA {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_cuu_maxexpsh_c1 grc_`country'_cuu_maxexpsh_c2     			  ///
    grc_`country'_cuu_maxexpsh_c3 grc_`country'_cuu_maxexpsh_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
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
PREhead(string asis):    Prehead (space-separated strings)
POSTfoot(string asis):   Postfoot (space-separated strings)
COEFlabels(string asis): How to label vars (if different from var label)
TEXTdepvar(string asis): Dependent variable as string
*/

* Make sure estimates are in memory
foreach country in IDN CHN TZA {
foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
    estimates store grc_`country'_cuu_maxexpsh_`estname'
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
    estimates store grc_`country'_cuu_maxexpsh_`estname'_n
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
    estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )        

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* CHINA
* **********************************************************************
local country CHN




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* TANZANIA
* **********************************************************************
local country TZA




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )    
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* 2. Consumption | Urban | Balanced | GRC | Max Experience Share
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp_m_sh		   	"exp_max_share"
global covs_gmm2_exp_m_sh	   	"$covs_gmm_exp_m_sh female"
global covs_gmm3_exp_m_sh		"$covs_gmm2_exp_m_sh age2"
global covs_gmm_all_exp_m_sh 	"$covs_gmm3_exp_m_sh education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid exp_max_share
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
    estname(initial_`country')
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
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

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
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

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
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN CHN TZA {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
        estimates store grc_`country'_cuu_maxexpsh_`estname'
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_n
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
    }

* Display a simple table of results
foreach country in IDN CHN TZA {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_cuu_maxexpsh_c1 grc_`country'_cuu_maxexpsh_c2     			  ///
    grc_`country'_cuu_maxexpsh_c3 grc_`country'_cuu_maxexpsh_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  consumption
local balance bal

/* Settings for GRC table
COLumns(integer):        Number of columns
FILEname(string asis):   Filename for the output LaTeX table
COUNTRY(string asis):    Names for each panel (space-separated list)
Keep(varlist):           List of variables to display in each panel
PREhead(string asis):    Prehead (space-separated strings)
POSTfoot(string asis):   Postfoot (space-separated strings)
COEFlabels(string asis): How to label vars (if different from var label)
TEXTdepvar(string asis): Dependent variable as string
*/

* Make sure estimates are in memory
foreach country in IDN CHN TZA {
    foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
    estimates store grc_`country'_cuu_maxexpsh_`estname'
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
    estimates store grc_`country'_cuu_maxexpsh_`estname'_n
    estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
    estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )       

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex"  ///
    , subdir(tables)
}

* **********************************************************************
* CHINA
* **********************************************************************
local country CHN




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                    ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex"  ///
    , subdir(tables)
}

* **********************************************************************
* TANZANIA
* **********************************************************************
local country TZA




local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* 3. Income | Urban | Unbalanced | GRC | Max Experience Share
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp_m_sh		   	"exp_max_share"
global covs_gmm2_exp_m_sh	   	"$covs_gmm_exp_m_sh female"
global covs_gmm3_exp_m_sh		"$covs_gmm2_exp_m_sh age2"
global covs_gmm_all_exp_m_sh 	"$covs_gmm3_exp_m_sh education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar $lnsize trajectory choice pid exp_max_share
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
    estname(initial_`country')
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
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* TANZANIA
* **********************************************************************
eststo clear
local country TZA

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
    estname(initial_`country')
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
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* CHINA
* **********************************************************************
eststo clear
local country CHN

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
    estname(initial_`country')
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
* Experience control
run_grc, estname(grc_`country'_cuu_maxexpsh_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_cuu_maxexpsh_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_cuu_maxexpsh_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_cuu_maxexpsh_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN CHN TZA {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
        estimates store grc_`country'_cuu_maxexpsh_`estname'
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_n
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
    }

* Display a simple table of results
foreach country in IDN CHN TZA {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_cuu_maxexpsh_c1 grc_`country'_cuu_maxexpsh_c2     			  ///
    grc_`country'_cuu_maxexpsh_c3 grc_`country'_cuu_maxexpsh_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}
* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  urban
local depvar  income
local balance unb

/* Settings for GRC table
COLumns(integer):        Number of columns
FILEname(string asis):   Filename for the output LaTeX table
COUNTRY(string asis):    Names for each panel (space-separated list)
Keep(varlist):           List of variables to display in each panel
PREhead(string asis):    Prehead (space-separated strings)
POSTfoot(string asis):   Postfoot (space-separated strings)
COEFlabels(string asis): How to label vars (if different from var label)
TEXTdepvar(string asis): Dependent variable as string
*/

* Make sure estimates are in memory
foreach country in IDN CHN TZA {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'"
        estimates store grc_`country'_cuu_maxexpsh_`estname'
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_n"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_n
        estimates use "$dir/output/grc_`country'_cuu_maxexpsh_`estname'_g"
        estimates store grc_`country'_cuu_maxexpsh_`estname'_g
    }
}


local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN



* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* CHINA
* **********************************************************************
local country CHN



* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
* TANZANIA
* **********************************************************************
local country TZA



* Run program to create output table
grc_tex_table_trend_exp, columns(4)                         ///
    spec(cuu_maxexpsh)                                      ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)
}

* **********************************************************************
log close
