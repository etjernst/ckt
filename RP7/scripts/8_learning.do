/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Jan 2026
This code:
    - runs regressions for returns to learning in rural and urban areas
*******************************************************************************/

* set log file
capture log close
log using "$logs/8_learning.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis
*     Countries:          IDN / TZA / CHN
*     Dependent variable: consumption
*     Panel structure:    bal 
* ********************************************************************

* **********************************************************************
* 1. Consumption | Balanced
* **********************************************************************

* Choices
local depvar  consumption
local balance bal

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

g first_period_urban_temp = .
replace first_period_urban_temp = urban if period == 1

bys pid: egen first_period_urban = min(first_period_urban_temp)
drop first_period_urban_temp

bys pid (period): g urban_periods = sum(urban)
bys pid (period): g rural_periods = sum(rural)

g urban_1period = first_period_urban == 0 & urban_periods == 1 & urban == 1
lab var urban_1period "1 period of urban since migrating"

g urban_2period = first_period_urban == 0 & urban_periods == 2 & urban == 1
lab var urban_2period "2 periods of urban since migrating"

g urban_3period = first_period_urban == 0 & urban_periods == 3 & urban == 1
lab var urban_3period "3 periods of urban since migrating"

g urban_4period = first_period_urban == 0 & urban_periods == 4 & urban == 1
lab var urban_4period "4 periods of urban since migrating"

g rural_1period = first_period_urban == 1 & rural_periods == 1 & rural == 1
lab var rural_1period "1 period of rural since migrating"

g rural_2period = first_period_urban == 1 & rural_periods == 2 & rural == 1
lab var rural_2period "2 periods of rural since migrating"

g rural_3period = first_period_urban == 1 & rural_periods == 3 & rural == 1
lab var rural_3period "3 periods of rural since migrating"

g rural_4period = first_period_urban == 1 & rural_periods == 4 & rural == 1
lab var rural_4period "4 periods of rural since migrating"

drop first_period_urban urban_periods rural_periods

* Run OLS & FE regressions and eststo them
quietly: reghdfe_regressions_learn_`country' `country' `depvar' `balance'

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* **********************************************************************
* INDONESIA
* **********************************************************************

*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Learning in Urban and Rural Locations on log Consumption in Indonesia, Balanced Sample} "'"
* Table label
	local table_label "`" \label{tab:OLS_IDN_cons_learning_bal} "'" 	
	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (4) include time (survey wave) fixed effects. Columns (3) and (4) add a female indicator, age squared, and education (years of schooling, maximum across periods) and its square. Column (4) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & All & All \\ Time FE & & Y & Y & Y \\ Individual FE & & & & Y \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
/* Settings for multi-panel table
Panels(integer): 			Number of panels
COLumns(integer): 			Number of columns
FILEname(string asis): 		Filename for the output LaTeX table
COUNTRIES(string asis): 	Names for each panel (space-separated list)
Keep(varlist): 				List of variables to display in each panel
PREhead(string asis): 		Prehead (space-separated strings)
POSTfoot(string asis): 		Postfoot (space-separated strings)
COEFlabels(string asis):	How to label vars (if different from var label)
*/
	
* Run program to create multi-panel table
	create_panel_tex_table_learn_IDN, columns(4) 						///
					filename(OLS_IDN_`depvar'_learning_`balance')			///
					keep(urban_1period urban_2period urban_3period urban_4period rural_1period rural_2period rural_3period rural_4period)	///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(urban_1period "1st urban period" urban_2period "2nd urban period" urban_3period "3rd urban period" urban_4period "4th urban period" rural_1period "1st rural period" rural_2period "2nd rural period" rural_3period "3rd rural period" rural_4period "4th rural period")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_IDN_`depvar'_`choice'_`balance'.tex", subdir(tables)		
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

g first_period_urban_temp = .
replace first_period_urban_temp = urban if period == 1

bys pid: egen first_period_urban = min(first_period_urban_temp)
drop first_period_urban_temp

bys pid (period): g urban_periods = sum(urban)
bys pid (period): g rural_periods = sum(rural)

g urban_1period = first_period_urban == 0 & urban_periods == 1 & urban == 1
lab var urban_1period "1 period of urban since migrating"

g urban_2period = first_period_urban == 0 & urban_periods == 2 & urban == 1
lab var urban_2period "2 periods of urban since migrating"

g urban_3period = first_period_urban == 0 & urban_periods == 3 & urban == 1
lab var urban_3period "3 periods of urban since migrating"

g rural_1period = first_period_urban == 1 & rural_periods == 1 & rural == 1
lab var rural_1period "1 period of rural since migrating"

g rural_2period = first_period_urban == 1 & rural_periods == 2 & rural == 1
lab var rural_2period "2 periods of rural since migrating"

g rural_3period = first_period_urban == 1 & rural_periods == 3 & rural == 1
lab var rural_3period "3 periods of rural since migrating"

drop first_period_urban urban_periods rural_periods

* Run OLS & FE regressions and eststo them
quietly: reghdfe_regressions_learn_`country' `country' `depvar' `balance'

* **********************************************************************
* Make bootiful latex table
* **********************************************************************

* **********************************************************************
* CHINA
* **********************************************************************

*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Learning in Urban and Rural Locations on log Consumption in China, Balanced Sample} "'"
* Table label
	local table_label "`" \label{tab:OLS_CHN_cons_learning_bal} "'" 	
	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (4) include time (survey wave) fixed effects. Columns (3) and (4) add a female indicator, age squared, and education (years of schooling, maximum across periods) and its square. Column (4) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & All & All \\ Time FE & & Y & Y & Y \\ Individual FE & & & & Y \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
/* Settings for multi-panel table
Panels(integer): 			Number of panels
COLumns(integer): 			Number of columns
FILEname(string asis): 		Filename for the output LaTeX table
COUNTRIES(string asis): 	Names for each panel (space-separated list)
Keep(varlist): 				List of variables to display in each panel
PREhead(string asis): 		Prehead (space-separated strings)
POSTfoot(string asis): 		Postfoot (space-separated strings)
COEFlabels(string asis):	How to label vars (if different from var label)
*/
	
* Run program to create multi-panel table
	create_panel_tex_table_learn_CHN, columns(4) 						///
					filename(OLS_CHN_`depvar'_learning_`balance')			///
					keep(urban_1period urban_2period urban_3period rural_1period rural_2period rural_3period)	///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(urban_1period "1st urban period" urban_2period "2nd urban period" urban_3period "3rd urban period" rural_1period "1st rural period" rural_2period "2nd rural period" rural_3period "3rd rural period")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_CHN_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }

* **********************************************************************
log close
