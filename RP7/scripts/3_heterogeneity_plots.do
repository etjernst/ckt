/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Aug, 2024
This code:
	- Creates coefplot graphs of uGRC estimates
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
* Consumption | Urban | Unbalanced | Figures
* **********************************************************************

* ************
* INDONESIA
* ************
	eststo clear			

  local country 	IDN
* Choices
	local choice 		urban
	local depvar    consumption
	local balance		unb
	
* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear
  setup_grc_estimation
  heterogeneity_plots `country' `choice' `depvar' `balance'
	
* ************
* CHINA
* ************
	eststo clear			

  local country 	CHN
* Choices
	local choice 		urban
	local depvar    consumption
	local balance		unb
	
* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear
  setup_grc_estimation
  heterogeneity_plots `country' `choice' `depvar' `balance'
	
* ************
* TANZANIA
* ************
	eststo clear			

  local country 	TZA
* Choices
	local choice 		urban
	local depvar    consumption
	local balance		unb

* Open dataset
  use 						"$dirdata/processed/`country'_`balance'.dta", clear
  setup_grc_estimation
  heterogeneity_plots `country' `choice' `depvar' `balance'
				  
* **********************************************************************
* Combine graphs	  
* **********************************************************************
  graph combine hetplotDelta_`depvar'_`choice'_`balance'_IDN_Fcovars.gph ///
								hetplotDelta_`depvar'_`choice'_`balance'_CHN_Fcovars.gph ///
								hetplotDelta_`depvar'_`choice'_`balance'_TZA_Fcovars.gph ///
								, col(3)	
	
	graph export "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fcovars.pdf", replace	
	graph export "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fcovars.png", replace		

    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fcovars.pdf", subdir(figures)	
    }

  graph combine hetplotDelta_`depvar'_`choice'_`balance'_IDN_Fnocovars.gph ///
								hetplotDelta_`depvar'_`choice'_`balance'_CHN_Fnocovars.gph ///
								hetplotDelta_`depvar'_`choice'_`balance'_TZA_Fnocovars.gph ///
								, col(3)	
	
	graph export "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fnocovars.pdf", replace	
	graph export "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fnocovars.png", replace		

    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_Fnocovars.pdf", subdir(figures)	
    }
	
  graph combine hetplotmu_`depvar'_`choice'_`balance'_IDN_Fcovars.gph ///
								hetplotmu_`depvar'_`choice'_`balance'_CHN_Fcovars.gph ///
								hetplotmu_`depvar'_`choice'_`balance'_TZA_Fcovars.gph ///
								, col(3)	
	
	graph export "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fcovars.pdf", replace	
	graph export "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fcovars.png", replace		

    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fcovars.pdf", subdir(figures)	
    }

  graph combine hetplotmu_`depvar'_`choice'_`balance'_IDN_Fnocovars.gph ///
								hetplotmu_`depvar'_`choice'_`balance'_CHN_Fnocovars.gph ///
								hetplotmu_`depvar'_`choice'_`balance'_TZA_Fnocovars.gph ///
								, col(3)	
	
	graph export "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fnocovars.pdf", replace	
	graph export "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fnocovars.png", replace		

    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_Fnocovars.pdf", subdir(figures)	
    }
