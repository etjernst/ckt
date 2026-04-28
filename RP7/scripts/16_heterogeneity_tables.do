/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Aug, 2024
This code:
	- Creates table of rGRC estimates
*******************************************************************************/

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis				  
* 		Countries: 			IDN / TZA / CHN
* 		Choice variable: 	urban / nonag
* 		Dependent variable:	consumption / income
* 		Panel structure: 	bal / unb 
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
local htb_str "htb!"

* Delta table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Delta Estimates of the Returns to Urban Location on log Consumption in Indonesia} "'"

* Table label
local table_label "`" \label{tab:hetDelta_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the Indonesia Family Life Survey. Please refer to Section \ref{sec:data} for further details on the data. The dependent variable is the log of total consumption per capita. Urban is an indicator equal to one for individuals who report living in a city or town, as opposed to a village. Individuals are assigned to trajectories based on their location history across the survey waves. This table reports the estimates of $\Delta$ for each switcher trajectory. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Mu Estimates of the Returns to Urban Location on log Consumption in Indonesia} "'"

* Table label
local table_label "`" \label{tab:hetmu_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the Indonesia Family Life Survey. Please refer to Section \ref{sec:data} for further details on the data. The dependent variable is the log of total consumption per capita. Urban is an indicator equal to one for individuals who report living in a city or town, as opposed to a village. Individuals are assigned to trajectories based on their location history across the survey waves. This table reports the estimates of $\mu$ for each switcher trajectory. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
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
local htb_str "htbp"

* Delta table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Delta Estimates of the Returns to Urban Location on log Consumption in China} "'"

* Table label
local table_label "`" \label{tab:hetDelta_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the China Family Panel Survey. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:hetDelta_table_IDN} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Mu Estimates of the Returns to Urban Location on log Consumption in China} "'"

* Table label
local table_label "`" \label{tab:hetmu_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the China Family Panel Survey. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:hetmu_table_IDN} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
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
local htb_str "htbp"

* Delta table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Delta Estimates of the Returns to Urban Location on log Consumption in Tanzania} "'"

* Table label
local table_label "`" \label{tab:hetDelta_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the National Panel Survey from Tanzania. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:hetDelta_table_IDN} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_delta, country(`country')                     ///
    filename(hetDelta_table_`country') 					///
    keep(``country'_keep_list_delta')                   ///
    coeflabels(``country'_coeflabs_delta')              ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )   
                     
* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetDelta_table_`country'.tex" ///
    , subdir(tables)
}

* Mu table

* Table caption
local table_caption "`" \caption{Heterogeneity in Restricted GRC Mu Estimates of the Returns to Urban Location on log Consumption in Tanzania} "'"

* Table label
local table_label "`" \label{tab:hetmu_table_`country'} "'"

* Define prehead and postfoot strings

* Table notes
local table_notes "This table uses data from the National Panel Survey from Tanzania. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:hetmu_table_IDN} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer
local postfoot_str Time FE & Y \\ Covariates & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create output table
het_table_mu, country(`country')                        ///
    filename(hetmu_table_`country') 					///
    keep(``country'_keep_list_mu')	                    ///
    coeflabels(``country'_coeflabs_mu')                 ///
    htb(`htb_str')		                                ///
    prehead(`table_caption' `table_label')              ///
    postfoot(`postfoot_str')                            ///
    textdepvar( log(`depvar') )

* Copy table over to Overleaf folder
if $copyOverleaf == 1 {
    copyOverleaf              ///
    "$output/tables/hetmu_table_`country'.tex" ///
    , subdir(tables)
}
