/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Nov 2025
This code:
    - runs restricted GRC regressions for
        - Indonesia: unbalanced sample, non-ag as choice
    - outcomes: consumption per capita (adult equivalent: cube) and income
    - covariates (columns): (1) experience, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 14_GrRC_NonAg_experience.log, replace

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
* 1. Consumption | Nonag | Unbalanced | GRC | Experience
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp		   	"exp"
global covs_gmm2_exp	   	"$covs_gmm_exp female"
global covs_gmm3_exp		"$covs_gmm2_exp age2"
global covs_gmm_all_exp 	"$covs_gmm3_exp education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid exp
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
use "$dirdata/processed/`country'_`balance'_`choice'.dta", clear

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
local iterations 500

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_nonag_exp_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_nonag_exp_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_nonag_exp_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_nonag_exp_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_`estname'"
        estimates store grc_`country'_`estname'
        estimates use "$dir/output/grc_`country'_`estname'_never"
        estimates store grc_`country'_`estname'_never
        estimates use "$dir/output/grc_`country'_`estname'_avg"
        estimates store grc_`country'_`estname'_avg
    }
    }

* Display a simple table of results
foreach country in IDN {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_nonag_exp_c1 grc_`country'_nonag_exp_c2     			  ///
    grc_`country'_nonag_exp_c3 grc_`country'_nonag_exp_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
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
foreach country in IDN {
foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_`estname'"
    estimates store grc_`country'_`estname'
    estimates use "$dir/output/grc_`country'_`estname'_never"
    estimates store grc_`country'_`estname'_never
    estimates use "$dir/output/grc_`country'_`estname'_avg"
    estimates store grc_`country'_`estname'_avg
    }
}

* Define prehead and postfoot strings

* Table notes
local table_notes "This table repeats the analyses of Table \ref{tab:GRC_IDN_consumption_urban_unb}  for non-agricultural employment, which is an indicator equal to one for individuals who report working in the non-agricultural sector. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:GRC_IDN_consumption_urban_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Experience & \& Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN

* Table caption
local table_caption "`" \caption{Restricted GRC Estimates of the Returns to Non-Agricultural Sector on log Consumption in Indonesia, Experience Controls} "'"

* Table label
local table_label "`" \label{tab:GRC_`country'_`depvar'_`choice'_`balance'_exp} "'"

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                     ///
    spec(nonag_exp)                                     ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Non-Ag")                         ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
	copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp.tex" ///
    , subdir(tables)	    
}

* **********************************************************************
* 2. Consumption | Nonag | Unbalanced | GRC | Max Experience
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp_max		   	"exp_max"
global covs_gmm2_exp_max	   	"$covs_gmm_exp_max female"
global covs_gmm3_exp_max		"$covs_gmm2_exp_max age2"
global covs_gmm_all_exp_max 	"$covs_gmm3_exp_max education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid exp_max
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
use "$dirdata/processed/`country'_`balance'_`choice'.dta", clear

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
local iterations 500

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_nonag_exp_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_max)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_nonag_exp_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_max)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_nonag_exp_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_max)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_nonag_exp_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_max)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_`estname'"
        estimates store grc_`country'_`estname'
        estimates use "$dir/output/grc_`country'_`estname'_never"
        estimates store grc_`country'_`estname'_never
        estimates use "$dir/output/grc_`country'_`estname'_avg"
        estimates store grc_`country'_`estname'_avg
    }
    }

* Display a simple table of results
foreach country in IDN {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_nonag_exp_c1 grc_`country'_nonag_exp_c2     			  ///
    grc_`country'_nonag_exp_c3 grc_`country'_nonag_exp_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
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
foreach country in IDN {
foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_`estname'"
    estimates store grc_`country'_`estname'
    estimates use "$dir/output/grc_`country'_`estname'_never"
    estimates store grc_`country'_`estname'_never
    estimates use "$dir/output/grc_`country'_`estname'_avg"
    estimates store grc_`country'_`estname'_avg
    }
}

* Define prehead and postfoot strings

* Table notes
local table_notes "This table repeats the analyses of Table \ref{tab:GRC_IDN_consumption_urban_unb}  for non-agricultural employment, which is an indicator equal to one for individuals who report working in the non-agricultural sector. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:GRC_IDN_consumption_urban_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience & \& Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN

* Table caption
local table_caption "`" \caption{Restricted GRC Estimates of the Returns to Non-Agricultural Sector on log Consumption in Indonesia, Max Experience Controls} "'"

* Table label
local table_label "`" \label{tab:GRC_`country'_`depvar'_`choice'_`balance'_exp_max} "'"

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                     ///
    spec(nonag_exp)                                     ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_max) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Non-Ag")                         ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
	copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_max.tex" ///
    , subdir(tables)	    
}

* **********************************************************************
* 3. Consumption | Nonag | Unbalanced | GRC | Experience Share
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
local balance unb

* define GMM covariates (so they enter the first estimations)
global covs_gmm_exp_sh		   	"exp_share"
global covs_gmm2_exp_sh	   		"$covs_gmm_exp_sh female"
global covs_gmm3_exp_sh			"$covs_gmm2_exp_sh age2"
global covs_gmm_all_exp_sh 		"$covs_gmm3_exp_sh education_max education_max2"

* Keep only relevant variables (speeds up estimation)
global keepvars lndepvar trajectory choice pid exp_share
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
use "$dirdata/processed/`country'_`balance'_`choice'.dta", clear

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
local iterations 500

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_nonag_exp_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_nonag_exp_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_nonag_exp_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_nonag_exp_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_`estname'"
        estimates store grc_`country'_`estname'
        estimates use "$dir/output/grc_`country'_`estname'_never"
        estimates store grc_`country'_`estname'_never
        estimates use "$dir/output/grc_`country'_`estname'_avg"
        estimates store grc_`country'_`estname'_avg
    }
    }

* Display a simple table of results
foreach country in IDN {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_nonag_exp_c1 grc_`country'_nonag_exp_c2     			  ///
    grc_`country'_nonag_exp_c3 grc_`country'_nonag_exp_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
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
foreach country in IDN {
foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_`estname'"
    estimates store grc_`country'_`estname'
    estimates use "$dir/output/grc_`country'_`estname'_never"
    estimates store grc_`country'_`estname'_never
    estimates use "$dir/output/grc_`country'_`estname'_avg"
    estimates store grc_`country'_`estname'_avg
    }
}

* Define prehead and postfoot strings

* Table notes
local table_notes "This table repeats the analyses of Table \ref{tab:GRC_IDN_consumption_urban_unb}  for non-agricultural employment, which is an indicator equal to one for individuals who report working in the non-agricultural sector. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:GRC_IDN_consumption_urban_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Experience Share & \& Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN

* Table caption
local table_caption "`" \caption{Restricted GRC Estimates of the Returns to Non-Agricultural Sector on log Consumption in Indonesia, Experience Share Controls} "'"

* Table label
local table_label "`" \label{tab:GRC_`country'_`depvar'_`choice'_`balance'_exp_sh} "'"

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                     ///
    spec(nonag_exp)                                     ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Non-Ag")                         ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
	copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_sh.tex" ///
    , subdir(tables)	    
}

* **********************************************************************
* 4. Consumption | Nonag | Unbalanced | GRC | Max Experience Share
* **********************************************************************

* Choices
local choice  nonag
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
use "$dirdata/processed/`country'_`balance'_`choice'.dta", clear

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
local iterations 500

* ************
* Estimate restricted GMM model, uses `switcherpars' & `initial' from above
* ************
* Experience control
run_grc, estname(grc_`country'_nonag_exp_c1)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_exp_m_sh)                               ///
    iterate(`iterations') 

* Add female
run_grc, estname(grc_`country'_nonag_exp_c2)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm2_exp_m_sh)                              ///
    iterate(`iterations') 

* Add age2
run_grc, estname(grc_`country'_nonag_exp_c3)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm3_exp_m_sh)                              ///
    iterate(`iterations') 

* Add education & education2
run_grc, estname(grc_`country'_nonag_exp_ca)                             ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm_all_exp_m_sh)	                       ///
    iterate(`iterations') 

* **********************************************************************
* Add statistics and table markers
* **********************************************************************
foreach country in IDN {
    foreach estname in c1 c2 c3 ca {
        estimates use "$dir/output/grc_`country'_`estname'"
        estimates store grc_`country'_`estname'
        estimates use "$dir/output/grc_`country'_`estname'_never"
        estimates store grc_`country'_`estname'_never
        estimates use "$dir/output/grc_`country'_`estname'_avg"
        estimates store grc_`country'_`estname'_avg
    }
    }

* Display a simple table of results
foreach country in IDN {
di "`country', `depvar', `choice', `balance'"
estimates table                                       ///
    grc_`country'_nonag_exp_c1 grc_`country'_nonag_exp_c2     			  ///
    grc_`country'_nonag_exp_c3 grc_`country'_nonag_exp_ca         		  ///
    , star(.1 .05 .01) b(%7.2f) varlabel varwidth(35) ///
    stats(Delta_avg Jstat Jdf Jpval N N_clust converged)
}

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* Choices
local choice  nonag
local depvar  consumption
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
foreach country in IDN {
foreach estname in c1 c2 c3 ca {
    estimates use "$dir/output/grc_`country'_`estname'"
    estimates store grc_`country'_`estname'
    estimates use "$dir/output/grc_`country'_`estname'_never"
    estimates store grc_`country'_`estname'_never
    estimates use "$dir/output/grc_`country'_`estname'_avg"
    estimates store grc_`country'_`estname'_avg
    }
}

* Define prehead and postfoot strings

* Table notes
local table_notes "This table repeats the analyses of Table \ref{tab:GRC_IDN_consumption_urban_unb}  for non-agricultural employment, which is an indicator equal to one for individuals who report working in the non-agricultural sector. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:GRC_IDN_consumption_urban_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & Max Experience Share & \& Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Define variables to keep
// local reportvars "phi:_cons Delta_base:_cons kappa:_cons"
local reportvars "phi:_cons"
local varlab "$\phi$"

* **********************************************************************
* INDONESIA
* **********************************************************************
local country IDN

* Table caption
local table_caption "`" \caption{Restricted GRC Estimates of the Returns to Non-Agricultural Sector on log Consumption in Indonesia, Max Experience Share Controls} "'"

* Table label
local table_label "`" \label{tab:GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh} "'"

* Run program to create output table
grc_tex_table_trend_exp, columns(4)                     ///
    spec(nonag_exp)                                     ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh) ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Non-Ag")                         ///
    textdepvar( log(`depvar') )  

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
	copyOverleaf                                                   ///
    "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_exp_m_sh.tex" ///
    , subdir(tables)	    
}

* **********************************************************************
log close
