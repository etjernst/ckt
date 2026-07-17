/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
	- runs OLS & FE regressions for
        - all countries: unbalanced sample, urban as choice
        - all countries: balanced sample, urban as choice
        - Indonesia: unbalanced sample, non-ag as choice
	- outcome: consumption per capita (adult equivalent: cube)
    - covariates (columns): (1) nothing, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
capture log close
log using "$logs/3_OLS_uGRC.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis				  
* 		Countries: 			IDN / TZA / CHN
* 		Choice variable: 	urban / nonag
* 		Dependent variable:	consumption
* 		Panel structure: 	bal / unb 
* **********************************************************************
				  
* **********************************************************************
* 1. Consumption | Urban | Unbalanced | OLS & FE
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		unb
	
* ************
* INDONESIA
* ************
  local country 	IDN

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions IDN `choice' `depvar' `balance'
	
* ************
* CHINA
* ************
  local country 	CHN

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************
* TANZANIA
* ************
  local country 	TZA

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear
	
* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions TZA `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption} "'"
* Table label
	local table_label "`" \label{tab:OLS_cons_urb_unb} "'" 	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. All columns include time (survey wave) fixed effects. Column (2) adds a female indicator, column (3) adds age squared, and columns (4) to (6) add education (years of schooling, maximum across periods) and its square. Column (5) restricts the sample to migrants, i.e. those who we observe switching between rural and urban at least once in our data, and column (6) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Time FE & Y & Y & Y & Y & Y & Y \\ Covariates & & Female & \& Age$^2$ & All & All & All \\ Individual FE & & & & & & Y \\ Migrants only & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
/* Settings for multi-panel table
Panels(integer): 			Number of panels
COLumns(integer): 			Number of columns
FILEname(string asis): 		Filename for the output LaTeX table
COUNTRIES(string asis): 	Names for each panel (space-separated list)
Keep(varlist): 				List of variables to display in each panel
PREhead(string asis): 		Prehead (space-separated strings)
POSTfoot(string asis): 		Postfoot (space-separated strings)
COEFlabels(string asis):	How to label vars (if different from var label)
TEXTdepvar(string asis): 	Dependent variable as string
*/
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(3) columns(6) 						///
					countries(IDN CHN TZA) 								///
					filename(OLS_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}
* **********************************************************************
* 2. Consumption | Urban | Balanced | OLS & FE
* **********************************************************************	
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		bal

* ************
* INDONESIA
* ************
  local country   IDN
* Prepare data for regressions
	data_setup      `country' `choice' `depvar' `balance'
* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions `country' `choice' `depvar' `balance'
	
* ************
* CHINA
* ************
  local country   CHN
* Prepare data for regressions
	data_setup      `country' `choice' `depvar' `balance'
* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions `country' `choice' `depvar' `balance'
	
* ************
* TANZANIA
* ************
  local country   TZA
* Prepare data for regressions
	data_setup      `country' `choice' `depvar' `balance'
* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions `country' `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Balanced Sample} "'"
* Table label
	local table_label "`" \label{tab:OLS_cons_urb_bal} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  using the balanced panel. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."


* Table footer	
	local postfoot_str Time FE & Y & Y & Y & Y & Y & Y \\ Covariates & & Female & \& Age$^2$ & All & All & All \\ Individual FE & & & & & & Y \\ Migrants only & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
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
	create_panel_tex_table, panels(3) columns(6) 						///
					countries(IDN CHN TZA) 								///
					filename(OLS_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }

  
* **********************************************************************
* 3. Consumption | Non-ag | Unbalanced | OLS & FE | Indonesia only
* **********************************************************************
eststo clear			
* Choices
	local choice 		nonag
	local depvar		consumption
	local balance		unb
	
* ************
* INDONESIA
* ************
  local country 	IDN
  
* Prepare data for regressions
	data_setup      `country' `choice' `depvar' `balance'
/*
* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear
*/
* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions `country' `choice' `depvar' `balance'

* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Non-Agricultural Sector on log Consumption} "'"
* Table label
	local table_label "`" \label{tab:OLS_cons_nonag_unb} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  for non-agricultural employment, which is an indicator equal to one for individuals who report working in the non-agricultural sector. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."
	
* Table footer	
	local postfoot_str Time FE & Y & Y & Y & Y & Y & Y \\ Covariates & & Female & \& Age$^2$ & All & All & All \\ Individual FE & & & & & & Y \\ Migrants only & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(6) 						///
					countries(IDN) 								        ///
					filename(OLS_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Non-agricultural employment")	///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }
    
* **********************************************************************
log close
