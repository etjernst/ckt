* set log file
cd "$logs"
capture log close
log using make_figures.log, replace

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
/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Aug, 2024
This code:
	- Creates bar graph of different trajectories
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

* Create value label
  label define mega_trajectories 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories = 1 if trajectory == 1
  replace mega_trajectories = 2 if inlist(trajectory, 2, 4, 8, 16)
  replace mega_trajectories = 3 if inlist(trajectory, 9, 3, 12, 11, 13, 5, 6, 7, 14, 10, 15)
  replace mega_trajectories = 4 if inlist(trajectory, 24, 28, 17, 20, 30, 18, 26, 22, 21, 23, 19, 27)
  replace mega_trajectories = 5 if inlist(trajectory, 25, 29, 31)
  replace mega_trajectories = 6 if trajectory == 32

* Label values
  label values mega_trajectories mega_trajectories

keep if pid_first_obs == 1 & mega_trajectories != .

* Generate bar graph for Indonesia
  graph bar, over(mega_trajectories) asyvars stack           ///
        subtitle(Indonesia) ytitle("Percent", margin(zero) size(10pt)) legend(off) 		///
				fxsize(65) plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3) ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_IDN.gph, replace	

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

* Create value label
  label define mega_trajectories 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories = 1 if trajectory == 1
  replace mega_trajectories = 2 if inlist(trajectory, 2, 4, 8)
  replace mega_trajectories = 3 if inlist(trajectory, 3, 5, 6, 7)
  replace mega_trajectories = 4 if inlist(trajectory, 10, 12)
  replace mega_trajectories = 5 if inlist(trajectory, 9, 11, 13)
  replace mega_trajectories = 6 if trajectory == 14

* Label values
  label values mega_trajectories mega_trajectories

keep if pid_first_obs == 1 & mega_trajectories != .

* Generate bar graph for China
  graph bar, over(mega_trajectories) asyvars stack           ///
        subtitle(China) yscale(off) legend(off)  fxsize(50)                 ///
        plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3)    ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))

				
  graph save mega_CHN.gph, replace

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

* Create value label
  label define mega_trajectories 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories = 1 if trajectory == 1
  replace mega_trajectories = 2 if inlist(trajectory, 2, 4)
  replace mega_trajectories = 3 if inlist(trajectory, 3)
  replace mega_trajectories = 4 if inlist(trajectory, 6)
  replace mega_trajectories = 5 if inlist(trajectory, 5, 7)
  replace mega_trajectories = 6 if trajectory == 8

* Label values
  label values mega_trajectories mega_trajectories

keep if pid_first_obs == 1 & mega_trajectories != .

* Generate bar graph for Tanzania
  graph bar, over(mega_trajectories) asyvars stack           ///
        subtitle(Tanzania)                                                  ///
        yscale(off) legend(order(6 5 4 3 2 1) pos(4) cols(1) size(10pt)      ///
        region(margin(zero))) fxsize(100) plotregion(margin(zero))          ///
        graphregion(margin(zero))  scheme(tab3)        ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_TZA.gph, replace

* **********************************************************************
* Combine graphs	  
* **********************************************************************

  graph combine mega_IDN.gph mega_CHN.gph mega_TZA.gph, col(3)
	graph export "$output/figures/trajectories.pdf", replace
	graph export "$output/figures/trajectories.png", replace as(png) width(3600)
    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/trajectories.pdf", subdir(figures)
	}

* **********************************************************************
* Consumption | Urban | Unbalanced | Figures | At least 2 waves
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
  use 						"$dirdata/processed/`country'_`balance'_2waves.dta", clear

* Create value label
  label define mega_trajectories_2waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_2waves = 1 if trajectory_2waves == "00" | trajectory_2waves == "000" | trajectory_2waves == "0000" | trajectory_2waves == "00000"
  replace mega_trajectories_2waves = 2 if trajectory_2waves == "00001" | trajectory_2waves == "0001" | trajectory_2waves == "00011" | trajectory_2waves == "001" | trajectory_2waves == "0011" | trajectory_2waves == "00111" | trajectory_2waves == "01" | trajectory_2waves == "011" | trajectory_2waves == "0111" | trajectory_2waves == "01111"
  replace mega_trajectories_2waves = 3 if trajectory_2waves == "00010" | trajectory_2waves == "0010" | trajectory_2waves == "00100" | trajectory_2waves == "00101" | trajectory_2waves == "00110" | trajectory_2waves == "010" | trajectory_2waves == "0100" | trajectory_2waves == "01000" | trajectory_2waves == "01001" | trajectory_2waves == "0101" | trajectory_2waves == "01010" | trajectory_2waves == "01011" | trajectory_2waves == "0110" | trajectory_2waves == "01100" | trajectory_2waves == "01101" | trajectory_2waves == "01110"
  replace mega_trajectories_2waves = 4 if trajectory_2waves == "10001" | trajectory_2waves == "1001" | trajectory_2waves == "10010" | trajectory_2waves == "10011" | trajectory_2waves == "101" | trajectory_2waves == "1010" | trajectory_2waves == "10100" | trajectory_2waves == "10101" | trajectory_2waves == "1011" | trajectory_2waves == "10110" | trajectory_2waves == "10111" | trajectory_2waves == "11001" | trajectory_2waves == "1101" | trajectory_2waves == "11010" | trajectory_2waves == "11011" | trajectory_2waves == "11101"
  replace mega_trajectories_2waves = 5 if trajectory_2waves == "10" | trajectory_2waves == "100" | trajectory_2waves == "1000" | trajectory_2waves == "10000" | trajectory_2waves == "110" | trajectory_2waves == "1100" | trajectory_2waves == "11000" | trajectory_2waves == "1110" | trajectory_2waves == "11100" | trajectory_2waves == "11110"
  replace mega_trajectories_2waves = 6 if trajectory_2waves == "11" | trajectory_2waves == "111" | trajectory_2waves == "1111" | trajectory_2waves == "11111"

* Label values
  label values mega_trajectories_2waves mega_trajectories_2waves

keep if pid_first_obs_2waves == 1 & pid_obs >= 2 & mega_trajectories_2waves != .

* Generate bar graph for Indonesia
  graph bar, over(mega_trajectories_2waves) asyvars stack           ///
        subtitle(Indonesia) ytitle("Percent", margin(zero) size(10pt)) legend(off) 		///
				fxsize(65) plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3) ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_IDN_2waves.gph, replace	

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
  use 						"$dirdata/processed/`country'_`balance'_2waves.dta", clear

* Create value label
  label define mega_trajectories_2waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_2waves = 1 if trajectory_2waves == "00" | trajectory_2waves == "000" | trajectory_2waves == "0000"
  replace mega_trajectories_2waves = 2 if trajectory_2waves == "0001" | trajectory_2waves == "001" | trajectory_2waves == "0011" | trajectory_2waves == "01" | trajectory_2waves == "011" | trajectory_2waves == "0111"
  replace mega_trajectories_2waves = 3 if trajectory_2waves == "0010" | trajectory_2waves == "010" | trajectory_2waves == "0100" | trajectory_2waves == "0101" | trajectory_2waves == "0110"
  replace mega_trajectories_2waves = 4 if trajectory_2waves == "101" | trajectory_2waves == "1011" | trajectory_2waves == "1101"
  replace mega_trajectories_2waves = 5 if trajectory_2waves == "10" | trajectory_2waves == "100" | trajectory_2waves == "1000" | trajectory_2waves == "110" | trajectory_2waves == "1100" | trajectory_2waves == "1110"
  replace mega_trajectories_2waves = 6 if trajectory_2waves == "11" | trajectory_2waves == "111" | trajectory_2waves == "1111"

* Label values
  label values mega_trajectories_2waves mega_trajectories_2waves

keep if pid_first_obs_2waves == 1 & pid_obs >= 2 & mega_trajectories_2waves != .

* Generate bar graph for China
  graph bar, over(mega_trajectories_2waves) asyvars stack           ///
        subtitle(China) yscale(off) legend(off)  fxsize(50)                 ///
        plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3)    ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))

				
  graph save mega_CHN_2waves.gph, replace

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
  use 						"$dirdata/processed/`country'_`balance'_2waves.dta", clear

* Create value label
  label define mega_trajectories_2waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_2waves = 1 if trajectory_2waves == "00" | trajectory_2waves == "000"
  replace mega_trajectories_2waves = 2 if trajectory_2waves == "001" | trajectory_2waves == "01" | trajectory_2waves == "011"
  replace mega_trajectories_2waves = 3 if trajectory_2waves == "010"
  replace mega_trajectories_2waves = 4 if trajectory_2waves == "101"
  replace mega_trajectories_2waves = 5 if trajectory_2waves == "10" | trajectory_2waves == "100" | trajectory_2waves == "110"
  replace mega_trajectories_2waves = 6 if trajectory_2waves == "11" | trajectory_2waves == "111"

* Label values
  label values mega_trajectories_2waves mega_trajectories_2waves

keep if pid_first_obs_2waves == 1 & pid_obs >= 2 & mega_trajectories_2waves != .

* Generate bar graph for Tanzania
  graph bar, over(mega_trajectories_2waves) asyvars stack           ///
        subtitle(Tanzania)                                                  ///
        yscale(off) legend(order(6 5 4 3 2 1) pos(4) cols(1) size(10pt)      ///
        region(margin(zero))) fxsize(100) plotregion(margin(zero))          ///
        graphregion(margin(zero))  scheme(tab3)        ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_TZA_2waves.gph, replace

* **********************************************************************
* Combine graphs	  
* **********************************************************************

  graph combine mega_IDN_2waves.gph mega_CHN_2waves.gph mega_TZA_2waves.gph, col(3)
	graph export "$output/figures/trajectories_2waves.pdf", replace
	graph export "$output/figures/trajectories_2waves.png", replace as(png) width(3600)
    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/trajectories_2waves.pdf", subdir(figures)
	}	
	
* **********************************************************************
* Consumption | Urban | Unbalanced | Figures | At least 3 waves
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
  use 						"$dirdata/processed/`country'_`balance'_3waves.dta", clear

* Create value label
  label define mega_trajectories_3waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_3waves = 1 if trajectory_3waves == "000" | trajectory_3waves == "0000" | trajectory_3waves == "00000"
  replace mega_trajectories_3waves = 2 if trajectory_3waves == "00001" | trajectory_3waves == "0001" | trajectory_3waves == "00011" | trajectory_3waves == "001" | trajectory_3waves == "0011" | trajectory_3waves == "00111" | trajectory_3waves == "011" | trajectory_3waves == "0111" | trajectory_3waves == "01111"
  replace mega_trajectories_3waves = 3 if trajectory_3waves == "00010" | trajectory_3waves == "0010" | trajectory_3waves == "00100" | trajectory_3waves == "00101" | trajectory_3waves == "00110" | trajectory_3waves == "010" | trajectory_3waves == "0100" | trajectory_3waves == "01000" | trajectory_3waves == "01001" | trajectory_3waves == "0101" | trajectory_3waves == "01010" | trajectory_3waves == "01011" | trajectory_3waves == "0110" | trajectory_3waves == "01100" | trajectory_3waves == "01101" | trajectory_3waves == "01110"
  replace mega_trajectories_3waves = 4 if trajectory_3waves == "10001" | trajectory_3waves == "1001" | trajectory_3waves == "10010" | trajectory_3waves == "10011" | trajectory_3waves == "101" | trajectory_3waves == "1010" | trajectory_3waves == "10100" | trajectory_3waves == "10101" | trajectory_3waves == "1011" | trajectory_3waves == "10110" | trajectory_3waves == "10111" | trajectory_3waves == "11001" | trajectory_3waves == "1101" | trajectory_3waves == "11010" | trajectory_3waves == "11011" | trajectory_3waves == "11101"
  replace mega_trajectories_3waves = 5 if trajectory_3waves == "100" | trajectory_3waves == "1000" | trajectory_3waves == "10000" | trajectory_3waves == "110" | trajectory_3waves == "1100" | trajectory_3waves == "11000" | trajectory_3waves == "1110" | trajectory_3waves == "11100" | trajectory_3waves == "11110"
  replace mega_trajectories_3waves = 6 if trajectory_3waves == "111" | trajectory_3waves == "1111" | trajectory_3waves == "11111"

* Label values
  label values mega_trajectories_3waves mega_trajectories_3waves

keep if pid_first_obs_3waves == 1 & pid_obs >= 3 & mega_trajectories_3waves != .

* Generate bar graph for Indonesia
  graph bar, over(mega_trajectories_3waves) asyvars stack           ///
        subtitle(Indonesia) ytitle("Percent", margin(zero) size(10pt)) legend(off) 		///
				fxsize(65) plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3) ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_IDN_3waves.gph, replace	

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
  use 						"$dirdata/processed/`country'_`balance'_3waves.dta", clear

* Create value label
  label define mega_trajectories_3waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_3waves = 1 if trajectory_3waves == "000" | trajectory_3waves == "0000"
  replace mega_trajectories_3waves = 2 if trajectory_3waves == "0001" | trajectory_3waves == "001" | trajectory_3waves == "0011" | trajectory_3waves == "011" | trajectory_3waves == "0111"
  replace mega_trajectories_3waves = 3 if trajectory_3waves == "0010" | trajectory_3waves == "010" | trajectory_3waves == "0100" | trajectory_3waves == "0101" | trajectory_3waves == "0110"
  replace mega_trajectories_3waves = 4 if trajectory_3waves == "101" | trajectory_3waves == "1011" | trajectory_3waves == "1101"
  replace mega_trajectories_3waves = 5 if trajectory_3waves == "100" | trajectory_3waves == "1000" | trajectory_3waves == "110" | trajectory_3waves == "1100" | trajectory_3waves == "1110"
  replace mega_trajectories_3waves = 6 if trajectory_3waves == "111" | trajectory_3waves == "1111"

* Label values
  label values mega_trajectories_3waves mega_trajectories_3waves

keep if pid_first_obs_3waves == 1 & pid_obs >= 3 & mega_trajectories_3waves != .

* Generate bar graph for China
  graph bar, over(mega_trajectories_3waves) asyvars stack           ///
        subtitle(China) yscale(off) legend(off)  fxsize(50)                 ///
        plotregion(margin(zero)) graphregion(margin(zero))  scheme(tab3)    ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))

				
  graph save mega_CHN_3waves.gph, replace

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
  use 						"$dirdata/processed/`country'_`balance'_3waves.dta", clear

* Create value label
  label define mega_trajectories_3waves 1 "Always rural"  2 "Rural to urban" 3 "Multiple moves, start rural" 4 "Multiple moves, start urban" 5 "Urban to rural" 6 "Always urban", replace

* Generate trajectory grouping variable
  gen     mega_trajectories_3waves = 1 if trajectory_3waves == "000"
  replace mega_trajectories_3waves = 2 if trajectory_3waves == "001" | trajectory_3waves == "011"
  replace mega_trajectories_3waves = 3 if trajectory_3waves == "010"
  replace mega_trajectories_3waves = 4 if trajectory_3waves == "101"
  replace mega_trajectories_3waves = 5 if trajectory_3waves == "100" | trajectory_3waves == "110"
  replace mega_trajectories_3waves = 6 if trajectory_3waves == "111"

* Label values
  label values mega_trajectories_3waves mega_trajectories_3waves

keep if pid_first_obs_3waves == 1 & pid_obs >= 3 & mega_trajectories_3waves != .

* Generate bar graph for Tanzania
  graph bar, over(mega_trajectories_3waves) asyvars stack           ///
        subtitle(Tanzania)                                                  ///
        yscale(off) legend(order(6 5 4 3 2 1) pos(4) cols(1) size(10pt)      ///
        region(margin(zero))) fxsize(100) plotregion(margin(zero))          ///
        graphregion(margin(zero))  scheme(tab3)        ///
        bar(1, color("128 116 168")) bar(2, color("155 147 201"))           ///
        bar(3, color("198 193 240")) bar(4, color("255 190 209"))           ///
        bar(5, color("244 152 182")) bar(6, color("196 100 135"))
  graph save mega_TZA_3waves.gph, replace

* **********************************************************************
* Combine graphs	  
* **********************************************************************

  graph combine mega_IDN_3waves.gph mega_CHN_3waves.gph mega_TZA_3waves.gph, col(3)
	graph export "$output/figures/trajectories_3waves.pdf", replace
	graph export "$output/figures/trajectories_3waves.png", replace as(png) width(3600)
    if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/trajectories_3waves.pdf", subdir(figures)
	}

log close
