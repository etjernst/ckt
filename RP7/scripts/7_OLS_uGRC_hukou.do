/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Nov 2025
This code:
	- runs OLS & FE regressions for
        - all countries: unbalanced sample, urban as choice
        - all countries: balanced sample, urban as choice
        - Indonesia: unbalanced sample, non-ag as choice
	- outcomes: consumption per capita (adult equivalent: cube) and income
    - covariates (columns): (1) nothing, (2) add time FE, (3) add female, 
                            (4) add age^2, (5) add education (max) & education^2
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 7_OLS_uGRC_hukou.log, replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* Choices for the analysis				  
* 		Countries: 			CHN
* 		Choice variable: 	urban / nonag
* 		Dependent variable:	consumption / income
* 		Panel structure: 	bal / unb 
* **********************************************************************

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | OLS & FE | rural hukou first
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		unb
	local country 		CHN_hukou_rural_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Rural Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (7) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and columns (5) to (7) add education (years of schooling, maximum across periods) and its square. Column (6) restricts the sample to migrants, i.e. those who we observe switching between rural and urban at least once in our data, and column (7) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}
	
* **********************************************************************
* 2. Consumption | Urban | Balanced | OLS & FE | rural hukou first
* **********************************************************************	
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		bal
	local country 		CHN_hukou_rural_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Balanced Sample, Rural Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  using the balanced panel. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."


* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }
    
* **********************************************************************
* 3. Income | Urban | Unbalanced | OLS & FE | rural hukou first
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		income
	local balance		unb
	local country 		CHN_hukou_rural_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'_income.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Income, Rural Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb} with log income per capita as the dependent variable. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | OLS & FE | urban hukou first
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		unb
	local country 		CHN_hukou_urban_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Urban Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (7) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and columns (5) to (7) add education (years of schooling, maximum across periods) and its square. Column (6) restricts the sample to migrants, i.e. those who we observe switching between rural and urban at least once in our data, and column (7) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}
	
* **********************************************************************
* 2. Consumption | Urban | Balanced | OLS & FE | urban hukou first
* **********************************************************************	
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		bal
	local country 		CHN_hukou_urban_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Balanced Sample, Urban Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  using the balanced panel. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."


* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }
    
* **********************************************************************
* 3. Income | Urban | Unbalanced | OLS & FE | urban hukou first
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		income
	local balance		unb
	local country 		CHN_hukou_urban_first

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'_income.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Income, Urban Hukou First} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb} with log income per capita as the dependent variable. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | OLS & FE | only rural hukou
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		unb
	local country 		CHN_hukou_rural_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Only Rural Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (7) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and columns (5) to (7) add education (years of schooling, maximum across periods) and its square. Column (6) restricts the sample to migrants, i.e. those who we observe switching between rural and urban at least once in our data, and column (7) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}
	
* **********************************************************************
* 2. Consumption | Urban | Balanced | OLS & FE | only rural hukou
* **********************************************************************	
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		bal
	local country 		CHN_hukou_rural_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Balanced Sample, Only Rural Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  using the balanced panel. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."


* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }
    
* **********************************************************************
* 3. Income | Urban | Unbalanced | OLS & FE | only rural hukou
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		income
	local balance		unb
	local country 		CHN_hukou_rural_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'_income.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Income, Only Rural Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb} with log income per capita as the dependent variable. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}

* **********************************************************************
* 1. Consumption | Urban | Unbalanced | OLS & FE | only urban hukou
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		unb
	local country 		CHN_hukou_urban_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Only Urban Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "The dependent variable is the log of total consumption per capita. Columns (2) to (7) include time (survey wave) fixed effects, column (3) adds a female indicator, column (4) adds age squared, and columns (5) to (7) add education (years of schooling, maximum across periods) and its square. Column (6) restricts the sample to migrants, i.e. those who we observe switching between rural and urban at least once in our data, and column (7) adds individual fixed effects. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}
	
* **********************************************************************
* 2. Consumption | Urban | Balanced | OLS & FE | only urban hukou
* **********************************************************************	
eststo clear			
* Choices
	local choice 		urban
	local depvar		consumption
	local balance		bal
	local country 		CHN_hukou_urban_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Consumption, Balanced Sample, Only Urban Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb}  using the balanced panel. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. The dependent variable is the log of total consumption per capita. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."


* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)		
  }
    
* **********************************************************************
* 3. Income | Urban | Unbalanced | OLS & FE | only urban hukou
* **********************************************************************
eststo clear			
* Choices
	local choice 		urban
	local depvar		income
	local balance		unb
	local country 		CHN_hukou_urban_only

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'_income.dta", clear

* Run OLS & FE regressions and eststo them
	quietly: 				reghdfe_regressions CHN `choice' `depvar' `balance'
	
* ************	
* Make bootiful latex table
* ************
*  Define prehead and postfoot strings for each panel

* Table caption	
	local table_caption "`" \caption{OLS Estimates of the Returns to Urban Location on log Income, Only Urban Hukou} "'"
* Table label
	local table_label "`" \label{tab:OLS_`country'_`depvar'_`choice'_`balance'} "'" 	
* Table notes
	local table_notes "This table repeats the analyses of Table \ref{tab:OLS_cons_urb_unb} with log income per capita as the dependent variable. Please refer to Section \ref{sec:data} for further details on the data and to the notes of Table \ref{tab:OLS_cons_urb_unb} for additional information on the variables. We report robust standard errors, clustered at the individual level, in parentheses. Stars denote: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."

* Table footer	
	local postfoot_str Covariates & & & Female & \& Age$^2$ & All & All & All \\ Time FE & & Y & Y & Y & Y & Y & Y \\ Individual FE & & & & & & & Y \\ Migrants only & & & & & & Y & \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}
	
* Run program to create multi-panel table
	create_panel_tex_table, panels(1) columns(7) 						///
					countries(CHN) 										///
					filename(OLS_`country'_`depvar'_`choice'_`balance')			///
					keep(choice) 										///
					prehead(`table_caption' `table_label') 				///
					postfoot(`postfoot_str')							///
					coeflabels(choice "Urban")							///
					textdepvar( log(`depvar') )		
					
* Copy table over to Overleaf folder
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/OLS_`country'_`depvar'_`choice'_`balance'.tex", subdir(tables)	
	}

* **********************************************************************
log close
