/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
    - Creates summary statistics tables (means and trajectory differences
      by country x choice x depvar x balance)
*******************************************************************************/

*******************************************************************************
* Preliminaries
*******************************************************************************
* Make sure to run section 0 of 0_master.do before running this script
			
*******************************************************************************
* 1 - Consumption | Urban | Unbalanced | Means & differences
*******************************************************************************
* ************
* INDONESIA
* ************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset
	use 							  "$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Indonesia for the unbalanced panel across all five waves. Source: IFLS. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance')			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex", subdir(tables)
  }

* ************
* CHINA
* ************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for China for the unbalanced panel across all waves. Source: China survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance')			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex", subdir(tables)
    }
* ************
* TANZANIA
* ************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Tanzania for the unbalanced panel across all waves. Source: Tanzania survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance')	
	
	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex", subdir(tables)	
    }

*******************************************************************************
* 2 - Consumption | Urban | Balanced | Means & differences
*******************************************************************************
* ************
* INDONESIA
* ************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				bal			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Indonesia for the balanced panel across all five waves. Source: IFLS. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance')	

* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
      if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex"    ///
      , subdir(tables)
    }
* ************
* CHINA
* ************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				bal			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for China for the balanced panel across all waves. Source: China survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables) filename(summary_stats_`country'_`balance')			

* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
      if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex"    ///
      , subdir(tables)
    }
* ************
* TANZANIA
* ************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				bal
  

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Tanzania for the balanced panel across all waves. Source: Tanzania survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables) filename(summary_stats_`country'_`balance')		
	
* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'.tex" ///
  , remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
      if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'.tex"    ///
      , subdir(tables)
    }
	

*******************************************************************************
* 3 - Consumption | Non-ag | Unbalanced | Means & differences
*******************************************************************************
* ************
* INDONESIA
* ************
* Choices
	local country				IDN
	local choice 				nonag
	local depvar				consumption
	local balance				unb			

* Open processed dataset
	use 							  "$dirdata/processed/`country'_`balance'.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_nonag `country' `choice' `depvar' `balance'	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Indonesia for the unbalanced panel across all five waves. Source: IFLS. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_nonag)			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_nonag.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_nonag.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/summary_stats_`country'_`balance'_nonag.tex", subdir(tables)
  }
			
*******************************************************************************
* 4 - Consumption | Urban | Unbalanced | Means & differences | Non-switcher at least 2 waves present
*******************************************************************************
* ************
* INDONESIA
* ************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset
	use 							  "$dirdata/processed/`country'_`balance'_2waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_2waves `country' `choice' `depvar' `balance'	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Indonesia for the unbalanced panel across all five waves. Source: IFLS. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_2waves)			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/summary_stats_`country'_`balance'_2waves.tex", subdir(tables)
  }

* ************
* CHINA
* ************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'_2waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_2waves `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for China for the unbalanced panel across all waves. Source: China survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_2waves)			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'_2waves.tex", subdir(tables)
    }
* ************
* TANZANIA
* ************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'_2waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_2waves `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Tanzania for the unbalanced panel across all waves. Source: Tanzania survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_2waves)	
	
	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_2waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'_2waves.tex", subdir(tables)	
    }
			
*******************************************************************************
* 5 - Consumption | Urban | Unbalanced | Means & differences | Non-switcher at least 3 waves present
*******************************************************************************
* ************
* INDONESIA
* ************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset
	use 							  "$dirdata/processed/`country'_`balance'_3waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_3waves `country' `choice' `depvar' `balance'	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Indonesia for the unbalanced panel across all five waves. Source: IFLS. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_3waves)			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
  if $copyOverleaf == 1 {
    copyOverleaf "$output/tables/summary_stats_`country'_`balance'_3waves.tex", subdir(tables)
  }

* ************
* CHINA
* ************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'_3waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_3waves `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for China for the unbalanced panel across all waves. Source: China survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_3waves)			

	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'_3waves.tex", subdir(tables)
    }
* ************
* TANZANIA
* ************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb			

* Open processed dataset for later use
	use 							"$dirdata/processed/`country'_`balance'_3waves.dta", replace

* Grab number of obs for income	
	count if !mi(ln_income)
	local num_income			= r(N)
* Format the income observations to have a comma
	local formatted_num_income = string(`num_income', "%9.0fc")	
	
	country_summary_stats_3waves `country' `choice' `depvar' `balance'	
	
* Create LaTeX table with table notes	
	sumstats_table, table_notes(Summary statistics for Tanzania for the unbalanced panel across all waves. Source: Tanzania survey. The table reports means and standard deviations (in parentheses) based on individual-year pairs. See section 3 for further details. All variables have the same number of observations, except for income, which is missing for some observations. Income has `formatted_num_income' observations.) country(`country') balance(`balance') outputdir($output/tables)	filename(summary_stats_`country'_`balance'_3waves)	
	
	* Remove some empty lines
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS  \BSaddlinespace")
	removeStringFromTex	"$output/tables/summary_stats_`country'_`balance'_3waves.tex", remove(" &  &  &  &  \BS\BS")
	* Copy table to Overleaf
    if $copyOverleaf == 1 {
      copyOverleaf "$output/tables/summary_stats_`country'_`balance'_3waves.tex", subdir(tables)	
    }
  