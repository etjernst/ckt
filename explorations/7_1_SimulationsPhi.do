* Project: GRC
* Created: Aug 2021
* Last modified: 04/07/2023 by OBC
* Stata v.16.1

* The code estimates test on phi for the OLS, FE, CRE, CRC, and GMM models

/*
Simulation

We strongly advice to batch the code into multiple parallel processes.
	The code exports to a temporary folder, using the sample and seed to identify to which simulation and batch the process refers to:
		-  ${save_data}/temp/weakid_t2_sim_`sample'`seed'.dta
		- ${save_data}/temp/crc_GMM_t2_sim_`sample'`seed'.dta
	
	For parallel execution ---> nohup stata -b do "/home/grc/grc-weak-id-robust-inference/modules/stata/1_SimulationsPhi.do"  [seed value] &
		
	After enough iterations have been produced, the user can aggregate them using the code using 9_2_SimulationCompile
*/
* **********************************************************************
* 0 - Define root folder globals
* **********************************************************************
args param1 param2 param3 param4 param5
display "Seed: `param1'"
display "Sample: `param2'"
display "eta: `param3'"
display "Repetitions: `param4'"
display "Path: `param5'"

	// global root_path "../grc-replication-package"
	global root_path 				"`param5'"
	global  scripts                 "${root_path}/scripts"
	global  scripts_simulations      "${root_path}/script_simulations"
	global  logs                    "$scripts/logs"
	global save_data                "${root_path}/output"
	global save_data_simulations    "${root_path}/output/simulations"        

	
*       2. Set sub-directory paths for convenience
           include "$root_path/scripts/0_path_config.do"    
*       3. Set local ado directory
           include "$root_path/scripts/0_ado_config.do"   
*       4. Set up directory structure
*          The below global can be set to zero if the data folder already has 
*          the necessary subdirectories 
           global dirCreate 1
           include "$root_path/scripts/0_directory_structure.do"
*       5. Install dependencies
		       include "$scripts/0_setup.do"
*       6. Set preferences
           include "$root_path/scripts/0_preferences.do" 
*       7. Specify python path to use
*          Leave empty (or comment out) to use default python installation
           local python_path  ""
*       8. Set parameters for simulations, Weak-ID confidence intervals and coefficient stability
           include "$root_path/scripts/0_set_parameters.do"


* **********************************************************************
* 1 (a) - Data
* **********************************************************************
clear all
pause on 
********************************* 
*** Simulation parameters
*********************************
* Guarantees all enviromental set ups are loaded, even if multiple independent sessions are batched

* Note which flavor of Stata
    local variant = cond(c(MP),"MP",cond(c(SE),"SE",c(flavor)) )

* Include in log file info on how and when program was run
    di "=== SYSTEM DIAGNOSTICS ==="
    di "Stata version: `c(stata_version)'"
    di "Updated as of: `c(born_date)'"
    di "Variant:       `variant'"
    di "Processors:    `c(processors)'"
    di "OS:            `c(os)' `c(osdtl)'"
    di "Machine type:  `c(machine_type)'"
    di "=========================="
   
/*
Includes the simulation parameters. 
The total simulations will equal the number of repetitions times the number of parallel processes launched. 
- Repetitions
- Sample size
- Beta
- Phi

*/
/* Number of repetition: Total repetitions will be equal to N_repetitions TIMES the number of parallel processes */
local N_repetitions = `param4'

/*Sample sizes to be tested*/
local sample_size = "`param2'"

/*Difference in comparative advantage*/
local eta_val = "`param3'"

/*Share of trajectories*/
local p00 = 0.26
local p11 = 0.53
local p01 = 0.08
local p10 = 0.13

/*Setting mu values*/
local mu00 = 5.246
local mu01 = 5.942
local mu11  = 8.101

/*STD*/
loc std_val = ".84"

/*STD of U*/
loc std_U = ".38"

* Setting up values for the simulation
loc beta_0	 = "-0.543"

* I start by playing with how the trajectories are assigned
loc phi_to_test		 = "-0.794"



/*
Identify the file where it is saved: When running the commad on parallel the following locals help to identify and track which files where save from which session
*/

***** Guarantees differnt seeds when running in parallel: `param1' is passed at the end of the line running the do file
set seed `param1'

*********************************************
* Loop
*********************************************
foreach sample of loc sample_size {
	
	di in red "-------sample: `sample'---------"
	* Save results on the CRC and GMM this file (saved at the end)
	tempfile results_phi
	tempname memhold
	postfile `memhold' str20(std_u beta sample method phi_coeff phi_se phi_CI_min phi_CI_max loop std compar_advtg phi_real converged share_N01 share_N10) using "`results_phi'"

	tempfile weakid_t2_sim
	save `weakid_t2_sim', emptyok replace
	
	foreach real_phi of loc phi_to_test {
		di in red "-------real_phi : `real_phi'---------"
		
		set obs `sample'

		* groups
		foreach var of newlist N00 N11 N01 N10 {
			gen `var' = 0
		}
		
		* Assigning to groups
		loc seed_time = `param1'*100
		set seed `seed_time'
		

		cap drop aux
		gen aux=runiform(0,1)
		* Assigning to groups
		replace N00 = 1 if (aux < `p00') 
		replace N01 = 1 if (aux > `p00') & (aux<`p00'+`p01')
		replace N10 = 1 if (aux > `p00'+`p01') & (aux < `p00'+`p01'+`p10')
		replace N11 = 1 if (aux > `p00'+`p01'+`p10')

		gen H1 = .
		gen H2 = .
		
		replace H1 = 1 if N11 == 1
		replace H2 = 1 if N11 == 1

		replace H1 = 0 if N00 == 1
		replace H2 = 0 if N00 == 1
		
		replace H1 = 0 if N01 == 1
		replace H2 = 1 if N01 == 1

		replace H1 = 1 if N10 == 1
		replace H2 = 0 if N10 == 1
		
		gen group = .
		replace group = 1 if N11 == 1
		replace group = 2 if N10 == 1
		replace group = 3 if N01 == 1
		replace group = 4 if N00 == 1

		label define group 1 "always" 2 "dissadopt" 3 "adopter" 4 "Never" , modify
		label values group group
		
		tempfile pre_draws
		save `pre_draws'
		

		******************************************
		*** At this point, we define the size of the alpha, and the s.d 
		******************************************	
			
		foreach beta_val of loc beta_0 {
			foreach std_U_val of loc std_U {
				foreach std of loc std_val {
					foreach eta of loc eta_val {
								
						di in red "-------STD: `std' AND comparative_advantage: `eta'--------- sample: `sample'"
						
						/* random error*/
						foreach loop of numlist 1(1)`N_repetitions' {
							di "Loop in `loop'"
							
							use `pre_draws', clear

							loc seed_time = `param1'*`loop'*110
							set seed `seed_time'

							cap drop alpha
							gen	alpha = rnormal(`mu00'*(1-H1)*(1-H2) + `mu01'*(1-H1)*H2 +(`mu01'+`eta')*H1*(1-H2)+ `mu11'*H1*H2 , `std')

							// Mean alpha  
							loc mean_alpha = (`p00'*`mu00')+(`mu01'*`p01')+((`mu10'+`eta')*`p10')+(`mu11'*`p11')
							
							local count 0

							*** Need to make a new local with the order of trajectories that worked for the above definition of the groups
							local traj_N = "00 01 11 10"
							
							* Table of alphas
							foreach traj of local traj_N {

								local ++count

								qui: su alpha if group==`count'
								local alpha_`traj' = r(mean)
								
								di "alpha_`traj'"
								di "`alpha_`traj''"
							}

									
							* Create IDs
							cap drop hhid
							gen hhid = _n			
							
							* Create outcome variables
							*** errors
							cap drop e1
							cap drop e2

							loc seed_time = `param1'*`loop'*120
							set seed `seed_time'
							
							gen	e1 	=	rnormal(0,`std_U_val')
							gen	e2 	=	rnormal(0,`std_U_val')
												
							cap drop y1 y2 
							gen y1 = alpha+`beta_val'*H1+(alpha-`mean_alpha')*`real_phi'*H1+e1
							gen y2 = alpha+`beta_val'*H2+(alpha-`mean_alpha')*`real_phi'*H2+e2		
					
							***********************
							*** get data as long
							***********************
							* This format is used in the group effect estimation we are developing
							tempfile data_wide
							save `data_wide', replace

							tempfile year_1

							keep H1 N00 N11 N01 N10 group e1 alpha y1 hhid
							ren y1 y
							ren H1 hybrid
							ren e1 error
							save `year_1' , replace

							use `data_wide' , clear
							keep H2 N00 N11 N01 N10 group e2 alpha y2 hhid
							ren y2 y
							ren H2 hybrid
							ren e2 error
							append using `year_1'

							tempfile data_long
							save `data_long' , replace
						
							***********************
							* Results Group effect model
							***********************

							*************************************
							* Set up GCR
							*************************************				
							use `data_wide', clear
							
							noi di "----- Rand Coef ---- "

							cap randcoef ( y1 y2 )  , choice( H1 H2 )  method(CRC) showreg max(250)
							
							* Extract info
							loc cap_rc = _rc
							
							mat A = r(table)
							loc phi_CI_low_crc =  A[5,5]
							if (`cap_rc' == 0) & (`phi_CI_low_crc' != .) {
								local converged_crc = 1
								
								local phi_crc = _b[phi]
								local phi_crc_se = _se[phi]
								
								loc rank =  e(rank_matrix)
								loc phi_CI_low_crc =  A[5,5]
								loc phi_CI_high_crc =  A[6,5]
												
								loc phi_crc_in_CI = 0

								loc phi_t_crc = A[4,5]
							}
							else {
								local converged_crc = 99999
								local phi_crc 		= 99999
								local phi_crc_se 	= 99999
								
								loc rank 			= 99999
								loc phi_CI_low_crc 	= 99999
								loc phi_CI_high_crc = 99999
													
								loc phi_crc_in_CI 	= 99999
								loc phi_t_crc 		= 99999	
							}
							
							qui {
								
								su N01
								loc share_n01 = r(mean)
								su N10
								loc share_n10 = r(mean)
								
							}

							post `memhold' ("`std_U_val'") ("`beta_val'") ("`sample'") ("CRC") ("`phi_crc'") ("`phi_crc_se'") ("`phi_CI_low_crc'") ("`phi_CI_high_crc'") ///
							("`loop'") ("`std'") ("`eta'") ("`real_phi'") ("`converged_crc'") ///
							("`p01'") ("`p10'") 


							*************************************
							* Set up GMM
							*************************************									
							use `data_long' , clear

							** get variables needed
							foreach var of varlist  N00 N01 N10 N11  {

								local traj = substr("`var'",-3,.)

								gen h_interact_`traj' = hybrid*`var'
								gen h_neg_interact_`traj' = (1-hybrid)*`var'
							}
							*** GMM ESTIMATION (assuming hbar_0 is trajectory 001)
							* First, let's make locals for all the dummy histories
							local alphas
							local int
							local alphas_new

							foreach var of varlist N* {

								local aux = substr("`var'",-2,.)
								di "`aux'"
								** Get alpha names
								local alphas `alphas'  - {a_`aux'=2}*`var'
							}

							foreach var of varlist N00 N01 N10 {

								local aux = substr("`var'",-2,.)
								** Get alpha names
								local alphas_new `alphas_new'  - {a_`aux'=`alpha_`aux''}*`var'
							}

							*** run regression to get b0 initial value
							reg y N* h_interact_*  , noconst
							local b01 : di _b[h_interact_N01]
							
							di "`alphas_new'"
							di "`b01'"
							di "`alpha_01'"
							di "`alpha_10'"

						
							*************************************
							* Set up GMM: Trajectories
							*************************************				
							
							global          never 1
													
							gen trajectory 		= 4 if group == 1
							replace trajectory 	= 3 if group == 2
							replace trajectory 	= 2 if group == 3
							replace trajectory 	= 1 if group == 4
							
							label define trajectory 1 "000" 2 "001" 3 "010" 4 "011"
							label values trajectory trajectory 
							
							lab var         trajectory "Trajectory group indicators"
							
							tab             trajectory

							global          always `r(r)'
							global          lastswitcher = $always-1

							numlist         "2(1)$lastswitcher"
							global          switchers `r(numlist)'

							numlist         "1(1)$lastswitcher"
							global          noalways `r(numlist)'
							
							/*
							One file per repetition. In each *_`loop' file we have the search ride for the paramiter combination
							
							- To save time, we only test on the real phi
							*/
							noi di "----- Weak Id ---- "
						
							loc increments = 0.1
						
							/*IF ONLY RUNNING GMM*/
							di "${save_data_simulations}/temp/weakid_t2_sim_`loop'_`param1'.dta"
							
							loc range_min = `real_phi'-.2
							loc range_max = `real_phi'+.2							
							
							di in red "Real phi range: `range_min' --- `range_max'"
							// set trace on
							di in red "min(`range_min') max(`range_max') inc(`increments') hhid(hhid) path() add()"
							di in red "${save_data_simulations}/temp/weakid_t2_sim_`loop'`param1'.dta" 
							di in red "`loop'"
							
							weakidri y, h(hybrid) min(`range_min') max(`range_max') inc(`increments') hhid(hhid) ///
							path("${save_data_simulations}/temp/weakid_t2_sim_`loop'_`param1'.dta") test_type("joint") add("`loop'")
							
							* Send to main file with results
							preserve 
								use "${save_data_simulations}/temp/weakid_t2_sim_`loop'_`param1'.dta", clear
								* add relevant variables
								gen comp_advantage = `eta'
								gen std_u = `std_U_val' 
								gen beta = `beta_val' 
								gen std = `std' 
								gen phi_real = `real_phi' 
								gen sample = `sample'
						
								gen share_N01 = "`p01'"
								gen share_N10 = "`p10'"
								
								append using `weakid_t2_sim' , force

								ta share_N01, m 
								ta share_N10, m 
								save `weakid_t2_sim' , replace 
		
								
								cap erase "${save_data_simulations}/temp/weakid_t2_sim_`loop'_`param1'.dta"
							restore

							* **********************************************************************
							* Restricted GMM without controls
							* **********************************************************************

							/* We have to define a local with all the mu parameters
								needed to identify \phi. */
							local           switcherpars ({mu:3.trajectory} - ///
												{mu:2.trajectory})*(3.trajectory#1.hybrid)

							di in red "`switcherpars'"
					
							foreach num of numlist $switchers {
								if `num'>3 {
									local   switcherpars `switcherpars' + ({mu:`num'.trajectory} ///
									- {mu:2.trajectory})*(`num'.trajectory#1.hybrid)
								* di "`switcherpars'"
								}
							}
						
							/* From the unrestricted gmm, keep the \mu parameters
							and the first \Delta*/
							/* First run OLS with  dummies for all trajectories.
							Save parameters to use to initialize the gmm; may speed up estimation */

							reg             y i($noalways).trajectory             			///
											i($switchers).trajectory#1.hybrid 	            ///
											, nocons vce(cluster hhid) coeflegend

							* Grab matrix of parameter estimates
							matrix          ols_init = e(b)

							* Run gmm
							cap gmm     	(y - {mu: i($noalways).trajectory}       		///
										- {Delta: i($switchers).trajectory#1.hybrid})   ///
										, instruments(i($noalways).trajectory 			///
										i($switchers).trajectory#1.hybrid, nocons) 		///
										vce(cluster hhid) coeflegend from(ols_init)

			
							* Adjust the "controls" indicator according to specification
							estadd          local controls "No" , replace

							* Store estimates
							estimates       store gmm_nc_ur_t$periods

							estimates restore gmm_nc_ur_t$periods

							/* 	Now store these estimates in a matrix
								to use as initial values in the restricted model */
							matrix          gmm_init = e(b)

							
							matrix          r_pars = gmm_init[1,1..$always]
						
							* Add the phi specified in preferences
							/* (2) want to make an initial guess for phi? (can help gmm converge)
							* currently grab parameter from unrestricted model
							without controls & phi */

							global      	phi -1
							matrix          r_pars = r_pars,$phi
							
							* Also make a guess for \kappa
							* we use mu_{last switcher}
							local           kappa_guess = _b[mu:i(${lastswitcher}).trajectory]
							
							di in red "kappa_guess: `kappa_guess'"

							matrix          r_pars = r_pars,`kappa_guess'							
							
							noi di "----- Restricted GMM ---- "
						
							cap gmm		(y - {mu: i(${noalways}).trajectory}              				///
										- {Delta}*(1.hybrid) - {phi}*(`switcherpars')           	///
										- ({mu_always} + {phi}*({mu_always}                     	///
										- {mu:2.trajectory}))*($always.trajectory#1.hybrid))    	///
										, instruments(i(${noalways}).trajectory 1.hybrid          	///
										i(${switchers} ${always}).trajectory#1.hybrid , nocons)     ///
										vce(cluster hhid) from(r_pars) coeflegend conv_maxiter(90)  

							if _rc == 0 {
								* If not converge the model results show so
								loc converged_gmm =  e(converged) 
							}
							else {
								loc converged_gmm =  99999
							}

							if (`converged_gmm' == 1) {
								mat results_gmm = r(table)
								
								local phi_gmm = results_gmm[1,5]
								local phi_gmm_se = results_gmm[2,5]
								
								loc phi_CI_low_gmm = results_gmm[5,5]
								loc phi_CI_high_gmm = results_gmm[6,5]
							}
							else {
								local phi_gmm 		= 99999
								local phi_gmm_se 	= 99999
			
								loc phi_CI_low_gmm 	= 99999
								loc phi_CI_high_gmm = 99999
							}

						
							post `memhold' ("`std_U_val'")  ("`beta_val'") ("`sample'") ("GMM_restricted") ("`phi_gmm'") ("`phi_gmm_se'") ("`phi_CI_low_gmm'") ("`phi_CI_high_gmm'") ///
							("`loop'") ("`std'") ("`eta'") ("`real_phi'") ("`converged_gmm'") ///
							("`p01'") ("`p10'") 
						
						} /*Repetitions*/
					} /*End comparative advantage*/
				} /*End of STD*/
			} /*End of STD U*/
		}  /*End of beta */
	}/*End of phi repetitions*/
	
	/*Save weak id*/
	use `weakid_t2_sim', clear
	save "${save_data_simulations}/temp/weakid_t2_sim_`sample'_`param1'.dta", replace

	/*Save CRC and GMM*/
	postclose `memhold' 

	drop _all
	use `results_phi' ,clear
	destring * , replace
	save "${save_data_simulations}/temp/crc_GMM_t2_sim_`sample'_`param1'.dta", replace
} /*End of Sample size*/
di in r "DONE"


