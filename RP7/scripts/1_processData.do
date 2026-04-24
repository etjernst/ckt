/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May, 2024
This code:
    - Saves processed datasets
*******************************************************************************/

*******************************************************************************
* INDONESIA - unbalanced
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* INDONESIA - unbalanced, non-ag
*******************************************************************************
* Choices
	local country				IDN
	local choice 				nonag
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_`choice'.dta", replace
  
*******************************************************************************
* INDONESIA - unbalanced, income
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace  
  
*******************************************************************************
* INDONESIA - balanced
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* INDONESIA - unbalanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace

*******************************************************************************
* INDONESIA - unbalanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace
  
*******************************************************************************
* INDONESIA - balanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace
  
*******************************************************************************
* INDONESIA - balanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				IDN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace
    
*******************************************************************************
* CHINA - unbalanced
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  
*******************************************************************************
* CHINA - unbalanced, income
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* CHINA - balanced
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* CHINA - unbalanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace

*******************************************************************************
* CHINA - unbalanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace
  
*******************************************************************************
* CHINA - balanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace
  
*******************************************************************************
* CHINA - balanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				CHN
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace
    
*******************************************************************************
* TANZANIA - unbalanced
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
 
*******************************************************************************
* TANZANIA - unbalanced, income
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* TANZANIA - balanced
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* TANZANIA - unbalanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace

*******************************************************************************
* TANZANIA - unbalanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace
  
*******************************************************************************
* TANZANIA - balanced, trajectory from at least 2 waves
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_2waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_2waves.dta", replace
  
*******************************************************************************
* TANZANIA - balanced, trajectory from at least 3 waves
*******************************************************************************
* Choices
	local country				TZA
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup_3waves `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_3waves.dta", replace

*******************************************************************************
* CHINA - unbalanced, rural hukou only
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_only
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  
*******************************************************************************
* CHINA - unbalanced, income, rural hukou only
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_only
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* CHINA - balanced, rural hukou only
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_only
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* CHINA - unbalanced, only urban hukou
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_only
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  
*******************************************************************************
* CHINA - unbalanced, income, only urban hukou
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_only
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* CHINA - balanced, only urban hukou
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_only
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace

*******************************************************************************
* CHINA - unbalanced, rural hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_first
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  
*******************************************************************************
* CHINA - unbalanced, income, rural hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_first
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* CHINA - balanced, rural hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_rural_first
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
    
*******************************************************************************
* CHINA - unbalanced, urban hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_first
	local choice 				urban
	local depvar				consumption
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  
*******************************************************************************
* CHINA - unbalanced, income, urban hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_first
	local choice 				urban
	local depvar				income
	local balance				unb

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'_income.dta", replace 
  
*******************************************************************************
* CHINA - balanced, urban hukou first
*******************************************************************************
* Choices
	local country				CHN_hukou_urban_first
	local choice 				urban
	local depvar				consumption
	local balance				bal

* Prepare for summary stats
	data_setup `country' `choice' `depvar' `balance'					

* Save dataset for later use
	save 				"$dirdata/processed/`country'_`balance'.dta", replace
  