set trace off
pause on
cap log close

* Project: GRC
* Created: Aug 2021
* Last modified: 08/19/2021 by OBC
* Stata v.16.1

* does
	* estimates  test on phi for the OLS, FE, CRE, CRC, and GMM models

* dependencies
	*

* **********************************************************************
* 0 - Define root folder globals
* **********************************************************************
	local cwd                       "`${root_path}"
	global  scripts                 "`cwd'/scripts"
	global  scripts_simulations      "`cwd'/script_simulations"
	global  logs                    "$scripts/logs"
	global save_data                "${root_path}/output"
	global save_data_simulations    "${root_path}/output/simulations"        	

* **********************************************************************
* 1 (a) - Data
* **********************************************************************

/*
Simulation

Run simulation first and append results. Put lines to sleep and then get results from the collapse 
*/

/*
Gets the multiple files from $save_data/temp
	+ Appends them 
	+ Gets stats

Append all the different files from the temp folder

- First GMM and CRC
- Then Weak Id
- Then we merge to have a file that is wide: Simulation-method 
*/


*****************************************
***** Compile and save files
*****************************************

***** GMM AND CRC
drop _all
global filelist : dir "$save_data_simulations/temp" files "crc_GMM_t2_sim_*.dta"

tempfile crc_GMM_t2_sim_appended
save `crc_GMM_t2_sim_appended', emptyok

use `crc_GMM_t2_sim_appended', clear

gen file_id = ""

foreach file of global filelist {
	di "$save_data_simulations/temp/`file'"

	append using "$save_data_simulations/temp/`file'"

	di in red substr("`file'", -28, .) 
	replace file_id =  "`file'" if file_id == ""
	su phi_coeff
	
	}

replace file_id = subinstr(file_id, ".dta", "", .)

split file_id , parse("_")
drop file_id  file_id1 file_id2 file_id3 file_id4
gen file_id = file_id5+"_"+file_id6
drop file_id5 file_id6

save "$save_data_simulations/crc_GMM_t2_sim_appended.dta", replace

**** weakid_t2_sim_
drop _all
global filelist : dir "$save_data_simulations/temp" files "weakid_t2_sim_*.dta"

tempfile weakid_t2_sim_appended
save `weakid_t2_sim_appended', emptyok

use `weakid_t2_sim_appended', clear

cap drop  file_id
gen file_id = ""


foreach file of global filelist {
	
	di "$save_data_simulations/temp/`file'"
	
	append using "$save_data_simulations/temp/`file'", force
	di in red "`file'"
	// di in red substr("`file'", -28, .) 
	
	// replace file_id = substr("`file'", -28, .) if file_id == ""
	replace file_id = "`file'" if file_id == ""
	
	su phi
	}

replace file_id = subinstr(file_id, ".dta", "", .)

split file_id , parse("_")
drop file_id  file_id1 file_id2 file_id3
gen file_id = file_id4+"_"+file_id5
drop file_id4 file_id5


save "$save_data_simulations/weakid_t2_sim_appended.dta", replace


***************************************************
*****Coverage: weakid_t2_sim_appended
***************************************************

use "${save_data_simulations}/weakid_t2_sim_appended.dta", clear

drop if comp_advantage ==.
* Keep one line per loop (when )
* Gen share of N01 and N10 indicators
* Gen share of N01 and N10 indicators

cap drop phi_in_range 
gen phi_in_range = (phi_real>=min_phi) & (phi_real<=max_phi)
/*CI length*/
gen length = max_phi-min_phi


* Keep just a line per simulation with the results and not all the iterations 
duplicates drop phi_real beta std_u file_id sample comp_advantage std add share_N01 share_N10 , force

sort sample comp_advantage std add phi
replace comp_advantage = round(comp_advantage,0.03)
replace phi_real = round(phi_real,.003)
replace beta = round(beta,.003)

* Fix format so they match to string so the keys match 
tostring sample  phi_real beta comp_advantage std add std_u share_N01 share_N10  , replace usedisplayformat force

replace comp_advantage = substr(comp_advantage ,1,4)

* Real phi is in the CI of each loop 
// cap drop phi_in_range 
// gen phi_in_range = (phi_real>=min_phi32) & (phi_real<=max_phi32)
// /*CI length*/
// gen length = max_phi32-min_phi32



tempfile aux_save
save `aux_save', replace

***************************************************
***** Coverage: Fix GMM and CRC
***************************************************

use "${save_data_simulations}/crc_GMM_t2_sim_appended.dta", clear

tostring share*, replace

*** if not coverge we drop, but count first
replace converged = 0 if converged == 99999

/*Coverage*/
* Real phi is in the CI of each loop 
gen phi_in_range = (phi_real>phi_CI_min) & (phi_real<phi_CI_max)

replace phi_in_range = . if converged  == 0
/*CI length*/
gen length = phi_CI_max-phi_CI_min
replace length = . if length == 0

ren compar_advtg comp_advantage 
ren loop add
sort method sample comp_advantage  std add 
drop if comp_advantage ==.

* Merge to make wide

replace comp_advantage = round(comp_advantage,0.03)
replace phi_real = round(phi_real,.003)
replace beta = round(beta, .003)

gen prob_phi_reject = 1 - inrange(0, phi_CI_min, phi_CI_max)

duplicates drop phi_real beta std_u file_id sample comp_advantage std add method share_N01 share_N10 , force


* Fix formats for the merge
tostring sample phi_real beta comp_advantage std add std_u, replace usedisplayformat force

replace comp_advantage = substr(comp_advantage ,1,4)

* Keep CRC
preserve 
	keep if method == "CRC"
	
	foreach var of varlist phi_coeff phi_se phi_in_range phi_CI_min phi_CI_max phi_real converged  length prob_phi_reject {
	    ren `var' `var'_CRC 
		
	}

	gen phi_real = phi_real_CRC

	tempfile aux_CRC
	save `aux_CRC', replace
	
restore  

* Keep GMM_restricted
keep if method == "GMM_restricted"

foreach var of varlist  phi_coeff phi_se phi_in_range phi_CI_min phi_CI_max phi_real converged length prob_phi_reject {
	ren `var' `var'_GMM_restricted
	
}

	gen phi_real = phi_real_GMM_restricted

merge 1:1 file_id phi_real beta sample add comp_advantage std std_u share_N01 share_N10  using `aux_CRC'

ta _merge
drop _merge


merge 1:1  file_id phi_real beta  sample add comp_advantage std std_u share_N01 share_N10  using `aux_save'
ta _merge

drop _merge


drop method
compress 

save "${save_data_simulations}/all_appended.dta", replace 

***************************************************
***** Produce Tables
***************************************************

use "${save_data_simulations}/all_appended.dta", replace 
cap drop method
cap drop compar_advtg  phi_CI_min phi_CI_max loop converged

*** All simulations 
** Phi in range when other methods converged
gen phi_in_range_converged_GMM = phi_in_range 
replace phi_in_range_converged_GMM  = . if converged_GMM_restricted == 0

gen phi_in_range_converged_CRC= phi_in_range 
replace phi_in_range_converged_CRC= . if converged_CRC == 0

** Length wak id when other methods converged
gen length_converged_GMM = length  
replace length_converged_GMM  = . if converged_GMM_restricted == 0

gen length_converged_CRC = length 
replace length_converged_CRC= . if converged_CRC == 0

*** Proportion on weak-id where CI is infinite
gen CI_inifinite = (length > 99)

gen prob_phi_reject_weakid = (p_val_joint < 0.05)

*** In range
preserve  
	collapse (mean) phi_in_range phi_in_range_converged_GMM  phi_in_range_converged_CRC ///
	 phi_in_range_CRC phi_in_range_GMM_restricted prob_phi_reject_weakid prob_phi_reject_CRC prob_phi_reject_GMM_restricted, by(phi_real beta std_u sample comp_advantage std share_N01 share_N10  )
	sort share_N01 share_N10  sample std comp_advantage  

	foreach var of varlist 	phi_in_range phi_in_range_converged_GMM ///
							 phi_in_range_converged_CRC phi_in_range_GMM_restricted ///
							 phi_in_range_CRC {
						
		format %10.3g `var'
	}

	* Keep the relevant for the table
	// keep if inlist(comp_advantage, ".09",".24",".51",".99")


	order sample std comp_advantage share_N01 share_N10  phi_in_range phi_in_range_converged_CRC phi_in_range_converged_GMM ///
										 phi_in_range_CRC phi_in_range_GMM_restricted 
	save "${save_data_simulations}/all_appended_table_converged.dta", replace 

restore

// preserve
keep phi_real beta phi_se_CRC phi_se_GMM_restricted phi_coeff_GMM_restricted ///
 phi_coeff_CRC sample comp_advantage std std_u share_N01 share_N10  converged_GMM_restricted converged_CRC p_val_joint ///
 prob_phi_reject_CRC prob_phi_reject_GMM_restricted


gen prob_phi_reject_weakid = (p_val_joint < 0.05)

replace phi_coeff_GMM_restricted = . if converged_GMM_restricted == 0
replace phi_coeff_CRC = . if converged_CRC == 0

replace phi_se_GMM_restricted = . if converged_GMM_restricted == 0
replace phi_se_CRC = . if converged_CRC == 0

destring phi_real, replace 
gen phi_coeff_CRC_mae = abs(phi_coeff_CRC-phi_real)  
gen phi_coeff_GMM_restricted_mae = abs(phi_coeff_GMM_restricted-phi_real)  

gen phi_coeff_CRC_rmse_aux = (phi_coeff_CRC-phi_real)^2
gen phi_coeff_GMM_rmse_aux = (phi_coeff_GMM_restricted-phi_real)^2
// phi_coeff_CRC_mae
collapse (mean) mean_phi_CRC=phi_coeff_CRC   mean_phi_se_CRC = phi_se_CRC (p50) p50_phi_CRC=phi_coeff_CRC (sd) sd_phi_CRC=phi_coeff_CRC ///
(mean) mae_phi_CRC=phi_coeff_CRC_mae (mean) rse_phi_CRC=phi_coeff_CRC_rmse_aux ///
(mean) mean_phi_GMM=phi_coeff_GMM_restricted  mean_phi_se_GMM = phi_se_GMM_restricted (p50) p50_phi_GMM=phi_coeff_GMM_restricted ///
(sd) sd_phi_GMM=phi_coeff_GMM_restricted  ///
(mean) mae_phi_GMM=phi_coeff_GMM_restricted_mae (mean) rse_phi_GMM=phi_coeff_GMM_rmse_aux /// 
(sd)  sd_phi_se_CRC = phi_se_CRC (sd) sd_phi_se_GMM = phi_se_GMM_restricted ///
(mean) prob_phi_reject_weakid = prob_phi_reject_weakid prob_phi_reject_CRC = prob_phi_reject_CRC prob_phi_reject_GMM = prob_phi_reject_GMM_restricted ///
, by(phi_real beta std_u sample comp_advantage std share_N01 share_N10  )

gen phi_coeff_CRC_rmse = rse_phi_CRC^(.5)
drop rse_phi_CRC

gen phi_coeff_GMM_restricted_rmse = rse_phi_GMM^(.5)
drop rse_phi_GMM

gen phi_coeff_CRC_se_std= mean_phi_se_CRC/sd_phi_CRC
gen phi_coeff_GRC_se_std= mean_phi_se_GMM/sd_phi_GMM




foreach var of varlist mean_phi_CRC p50_phi_CRC sd_phi_CRC mae_phi_CRC phi_coeff_CRC_rmse phi_coeff_CRC_se_std ///
				mean_phi_GMM p50_phi_GMM sd_phi_GMM mae_phi_GMM phi_coeff_GMM_restricted_rmse phi_coeff_GRC_se_std {
					format %10.3g `var'
}

// drop mean_phi_se_CRC mean_phi_se_GMM

order sample comp_advantage std share_N01 share_N10  mean_phi_CRC p50_phi_CRC sd_phi_CRC mae_phi_CRC phi_coeff_CRC_rmse phi_coeff_CRC_se_std ///
mean_phi_GMM p50_phi_GMM sd_phi_GMM mae_phi_GMM phi_coeff_GMM_restricted_rmse phi_coeff_GRC_se_std


// keep if inlist(comp_advantage, ".09",".24",".51",".99")

save "${save_data_simulations}/all_appended_table_stats.dta", replace 


**** Modify tables for final paper version

use "${save_data_simulations}/all_appended_table_converged.dta", replace 

keep sample comp_advantage phi_in_range phi_in_range_CRC phi_in_range_GMM_restricted std std_u phi_real beta

tempfile df_aux
save `df_aux'

use "${save_data_simulations}/all_appended_table_stats.dta", replace 

tostring phi_real beta, replace
merge 1:1 phi_real beta std_u sample comp_advantage std using `df_aux'

// 					CRC													|					Restricted GRC			   									| Weak-Id Robust
// Mean Median SD MAE RMSE SE/SD  CRC conv.  phi_SE_mean phi_SE_STD 		Mean Median SD MAE RMSE SE/SD  All R-GRC    phi_SE_mean phi_SE_STD 				conv  simulations

/* order sample comp_advantage std std_u mean_phi_CRC p50_phi_CRC sd_phi_CRC mae_phi_CRC phi_coeff_CRC_rmse phi_coeff_CRC_se_std phi_in_range_CRC             mean_phi_se_CRC sd_phi_se_CRC      ///
mean_phi_GMM p50_phi_GMM sd_phi_GMM mae_phi_GMM phi_coeff_GMM_restricted_rmse phi_coeff_GRC_se_std phi_in_range_GMM_restricted       mean_phi_se_GMM sd_phi_se_GMM  prob_phi_reject_weakid      phi_in_range */


sort sample comp_advantage std*


* Table to be exported

// // Create matrix from dataset
mkmat mean_phi_CRC p50_phi_CRC sd_phi_CRC mae_phi_CRC phi_coeff_CRC_rmse ///
phi_coeff_CRC_se_std  mean_phi_se_CRC sd_phi_se_CRC phi_in_range_CRC mean_phi_GMM p50_phi_GMM sd_phi_GMM ///
mae_phi_GMM phi_coeff_GMM_restricted_rmse phi_coeff_GRC_se_std ///
 mean_phi_se_GMM sd_phi_se_GMM phi_in_range_GMM_restricted  phi_in_range, matrix(sim_table)

// //generate table

esttab matrix(sim_table, fmt(%9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc %9.2fc)) using "$output/tables/sim_coverage_bias.tex", nostar ///
prehead( ///
	`"\renewcommand{\arraystretch}{1.1}"' ///
	`"\begin{table}[ht]"' ///
	`"{"' ///
	`"\begin{threeparttable}"' ///
	`"\small"' ///
	`"\caption{CRC and Restricted GrRC Point Estimation and Weak-identification Robust Inference on $\phi$}\label{tab:sim_crc_grc_cov_bias}"' ///
	`"\setlength{\tabcolsep}{3pt}"' ///
	`"\begin{tabular}{@{}cccccccccccccccccccc@{}}"' ///
	`"\toprule"' ///
	`"$\mu_{(0,1)}-\mu_{(1,0)}$ & \multicolumn{9}{c}{CRC} & \multicolumn{9}{c}{Restricted GrRC} & \multicolumn{1}{c}{WIR-CI}\\"' ///
	`"\cmidrule(lr){2-10}\cmidrule(lr){11-19} \cmidrule(lr){20-20}"' ///
	`"& Mean & Med. & SD & MAE & RMSE & $\frac{SE}{SD}$ & $\overline{SE}$ & $\sigma_{SE}$ & Cov. & Mean & Med. & SD & MAE & RMSE & $\frac{SE}{SD}$ & $\overline{SE}$ & $\sigma_{SE}$ & Cov. & Cov.\\"' ///
	`"\multicolumn{13}{l}{$ n=1,000$}\\"' ) ///
postfoot( ///
	`"\bottomrule"' ///
    `"\end{tabular}"' ///
	`"{\footnotesize\begin{tablenotes}[flushleft]"' ///
	`"\item "' ///
	`"\item{"' ///
	`"\emph{Notes}: This table presents simulation statistics for the point estimators of $\phi$ as well as the coverage for the weak-identification robust confidence interval ($ WIR$-$ CI$). The parameter $\phi$ is set to the CRC estimate from \cite{S2011} presented in Panel A of Table \ref{tab:grc_crct2}, which equals $-0.794$.  SD, MAE, RMSE and SE/SD abbreviate the simulation standard deviation, median absolute error, root-mean squared error, and the ratio of the average standard error to the simulation standard deviation, respectively. In addition, we report the simulation mean of the standard error and its simulation standard deviation, which we denote by $\overline{SE}$ and $\sigma_{SE}$. Cov. abbreviates coverage probability for a 95\% confidence interval. The summary statistics are computed using 1,000 simulation replications. For the CRC and Restricted GrRC, the simulation results are based on the replications where the estimator in question converges. Since $ WIR$-$ CI$ is based on closed-form estimators, we report its simulation coverage probability across all simulations. The outcome in our design is given by $ y_{it} =\mu_{i}+(\beta+\phi\theta_{i})h_{it}+u_{it}$ for $ i=1,\dots,n$, $ t=1,2$, where $\theta_{i}=\mu_{i}-E[\mu_{i}]$, $\mu_{i}|(h_{i1},h_{i2})\overset{i.i.d.}{\sim} N(\mu_{(h_{i1},h_{i2})},\sigma_{\mu}^2)$, $ u_{it}|(h_{i1},h_{i2})\overset{i.i.d.}{\sim} N(0,\sigma_u^2)$. Similar to $\phi$, we set $\beta$ to its CRC estimate from \cite{S2011} presented in Panel A of Table \ref{tab:grc_crct2}. We set $\mu_{(0,0)}$ and $\mu_{(0,1)}$ to their respective values in Panel C of Table \ref{tab:grc_crct2}; $\mu_{(1,0)}=\mu_{(0,1)}+\eta$ and $\mu_{(1,1)}=\frac{\kappa_{(1,1)}-\beta+\phi\sum_{\underline{h}\in\mathcal{H}^2\setminus (1,1)}\mu_{\underline{h}}\pi_{\underline{h}}}{1+\phi(1-\pi_{(1,1)})}$, where $\Delta_{(0,1)}$ and $\kappa_{(1,1)}$ are also set to their respective values in Panel C of Table \ref{tab:grc_crct2}. We set  $\sigma_{\mu}=0.84$, $\sigma_u=0.38$, which we obtain from a random effects regression of yield on trajectory fixed effects and interactions of $ h_{it}$ with trajectory fixed effects using our dataset. We set $\pi_{(0,0)}=0.26$, $\pi_{(0,1)}=0.08$,  $\pi_{(1,0)}=0.13$, $\pi_{(1,1)}=0.53$, which are set to their sample proportions in our dataset. }"' ///
	`"\end{tablenotes}}"' ///
	`"\end{threeparttable}"' ///
	`"	}"' ///
	`"\end{table}"') nodepvars nomtitles nonumbers tex substitute(\_ _) replace ///
	mgroups(none) mlabels(none) collabels(none) eqlabels(none) ///
	varlabels(r1 "$0.1$" r2 "$0.25$" r3 "$0.5$" r4 "$1$" ///
	r5 "\multicolumn{13}{l}{$ n=2,000$}\\ $0.1$" r6 "$0.25$" r7 "$0.5$" r8 "$1$" r9 "\multicolumn{13}{l}{$ n=5,000$}\\ $0.1$" ///
	r10 "$0.25$" r11 "$0.5$" r12 "$1$") ///
	 nolines






