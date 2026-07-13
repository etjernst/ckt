* adjustment: set covarlist in the run_grc command as always as:
* 	covarlist "unbalanced unbalanced_choice" "unbalanced unbalanced_choice"
* (otherwise the xb vector is empty in specs wo/ log HH size)
* (not a problem for balanced specifications since unbalanced varis empty?)

* **********************************************************************
* Locked-in shorthand for GRC ster filenames and stored estimate names
* ----------------------------------------------------------------------
* Format:  grc_<country>_<spec3>_<covs2>_<sfx1>
*
* country: 3 chars  CHN | IDN | TZA
*
* spec3:   3-char positional triplet <depvar><choice><balance>
*   cuu = consumption / urban / unbalanced  (4_GrRC.do section 1)
*   cub = consumption / urban / balanced    (4_GrRC.do section 2)
*   iuu = income      / urban / unbalanced  (4_GrRC.do section 3)
*   cnu = consumption / nonag / unbalanced  (5_GrRC_NonAg.do; IDN-only)
*
* covs2:   2-char covariate-set abbreviation
*   c0 = no covariates                            (was covs_0)
*   ct = trend (time FE only)                     (was covs_trend)
*   c1 = trend + female                           (was covs_1)
*   c2 = trend + female + age^2                   (was covs_2)
*   ca = trend + female + age^2 + edu + edu^2     (was covs_all)
*   The experience-family suffixes c1/c2/c3/ca keep their meaning
*   inside 10/11/12/13/14_*.do (different from c1/c2 in 4_GrRC.do).
*
* sfx1:    0--1 char post-estimation marker
*   <empty> = main GMM result
*   n       = Delta_never  extrapolation       (was _never)
*   a       = Delta_always extrapolation       (was _always)
*   d       = per-trajectory Deltas + joint    (was _delta)
*   g       = population-weighted average      (was _avg)
*
* Hukou variant (7_GrRC_hukou.do):
*   grc_<country>_<hukou>_<spec3>_<covs2>
*   hukou:  rf | uf | ro | uo (rural_first, urban_first, rural_only,
*                              urban_only). Compresses the prior
*                              CHN_rural_first / CHN_urban_first form.
*
* Experience / birth families (now consolidated in 9_GRC_extras.do)
* include their family token:
*   grc_<country>_<spec3>_<family>_<covs2>
*   family: exp | maxexp | expsh | maxexpsh | birth | nonag_exp -> exp
*           (the IDN nonag-experience cells use cnu_exp; cross-section
*            collisions present in the legacy 10--15 files were resolved
*            by the M11 ster-rename pass when those files were merged
*            into 9_GRC_extras.do.)
*
* Examples:
*   grc_IDN_cuu_ca       = main fit, IDN cons/urban/unb, all covariates
*   grc_IDN_cuu_ct_n     = Delta_never, IDN cons/urban/unb, trend-only
*   grc_CHN_rf_cuu_c0_g  = Delta_avg, CHN rural-first hukou, cons/urban/unb, no covs
*   grc_IDN_cuu_exp_ca_d = per-trajectory Deltas, IDN exp regressor
*
* Why this scheme:
*   - Disk filenames and in-memory `estimates store` names use the
*     same string. Drops the prior Option-B "long disk / short memory"
*     bridge (`urban_` -> `u_`, `nonag_` -> `n_`).
*   - Worst case: `_est_grc_CHN_uf_iuu_ca_n` = 24 chars + Stata's
*     5-char `_est_` prefix = 29. Fits Stata's 32-char internal limit
*     for stored-estimate matrix names.
*   - Each section in 4_GrRC.do and 7_GrRC_hukou.do gets a unique
*     spec3 token, so sections no longer overwrite each other on disk.
*
* Note: this scheme is for STER FILENAMES and STORED ESTIMATE NAMES
* only. The .tex output filenames (e.g. GRC_IDN_consumption_urban_unb.tex)
* keep their existing verbose form -- they are what the paper reads.
* **********************************************************************

* **********************************************************************
* List of programs
    * copyOverleaf						copies files to Overleaf
	* data_setup						combines below programs
	* use_data							opens data
	* handle_choice						sets 'treatment' variable
	* handle_depvar						sets choice dimension 
	* handle_balance					sets balanced/unbalanced panel
	* handle_trajectory_groups			creates trajectories and switcher variable 
	* gen_time_trend					creates time trend variable	
	* set_covariates					sets covariates
	* fix_varlabels						fixes variable labels
	* sumstats_table 					creates summary stats LaTeX table
	* country_summary_stats				prep for summary stats table
	* country_summary_stats_nonag		prep for summary stats table (non-ag)
	* removeStringFromTex				removes string from .tex using filefilter
	* create_panel_tex_table			creates three-part LaTeX table
	* reghdfe_regressions				OLS regressions (using reghdfe)
	* heterogeneity_plots				makes heterogeneity plots
	* setup_grc_estimation				get data ready for GRC regs
	* ugrc_regressions					uGRC regressions
	* initial_values					creates initial values for GRC
	* define_switcherpars				defines switcher parameters
	* grc_tex_table						creates country-specific LaTeX table for GRC

* **********************************************************************
* assert_merge_clean
* Audit-2026-04-28 M3: a small helper to validate a Stata merge against
* an expected set of _merge values, print a one-line diagnostic showing
* the actual breakdown, and drop _merge so it doesn't conflict downstream.
*
* Usage:
*     merge 1:1 pid year using "$dirdata/foo.dta"
*     assert_merge_clean, allow(1 3) label("hhsize merge")
*
*   allow()  --- list of _merge values that are OK (1=master only,
*                2=using only, 3=matched). Defaults to "3" (must-match-all).
*   label()  --- string for the diagnostic line. Defaults to "merge".
*   drop_unmatched(string) --- which side(s) to drop after the check.
*                Pass "1" to drop master-only, "2" to drop using-only,
*                "1 2" to drop both, or "" to keep all rows. Defaults to "".
*
* Always drops _merge at the end so callers don't have to remember.
* **********************************************************************
capture program drop assert_merge_clean
program define assert_merge_clean
    syntax , [allow(numlist integer min=1 max=3) label(string) ///
              drop_unmatched(string)]

    if "`allow'" == "" {
        local allow "3"
    }
    if `"`label'"' == "" {
        local label "merge"
    }

    qui count
    local n_total = r(N)
    qui count if _merge == 1
    local n_master = r(N)
    qui count if _merge == 2
    local n_using = r(N)
    qui count if _merge == 3
    local n_matched = r(N)

    di as text "[`label'] _merge breakdown: master-only=`n_master', using-only=`n_using', matched=`n_matched' (total `n_total')"

    foreach v of numlist 1 2 3 {
        local in_allow = strpos(" `allow' ", " `v' ")
        if !`in_allow' {
            local n = cond(`v'==1, `n_master', cond(`v'==2, `n_using', `n_matched'))
            if `n' > 0 {
                di as error "[`label'] FAIL: _merge==`v' has `n' rows but is not in allow(`allow')"
                exit 459
            }
        }
    }

    if "`drop_unmatched'" != "" {
        foreach v of numlist `drop_unmatched' {
            qui count if _merge == `v'
            if r(N) > 0 {
                di as text "[`label'] dropping `r(N)' rows with _merge==`v'"
                qui drop if _merge == `v'
            }
        }
    }

    drop _merge
end

* **********************************************************************
* copyOverleaf
* **********************************************************************
capture program drop copyOverleaf
program define copyOverleaf
	syntax anything(name=fileName1), SUBdir(string asis)

	* Skip silently if no Overleaf path was set for this user.
	if ("$overleaf" == "") {
		exit
	}

	* Make all slashes forward slashes
	local 	betterFileName1 = subinstr(`fileName1', "\", "/", .)

	local 	destDir = "$overleaf/`subdir'"

* Make destination filepath
	local fileName2 = "`destDir'/" + substr("`betterFileName1'", strrpos("`betterFileName1'", "/") + 1, .)
	copy 		`fileName1' "`fileName2'", replace
end

capture program drop data_setup
program define data_setup
  args country choice depvar balance
* Open data
  use_data 					`country'

* Define choice dimension ('urban' or 'nonag')
  handle_choice			`choice'

* Define outcome variable and drop if missing or negative
  handle_depvar			`depvar'
  
* Impose balanced or unbalanced panel
  handle_balance		`balance'

* Create trajectories and switcher variable  
  handle_trajectory_groups

* *******
* Covariate management
* *******  
* Drop observations with missing values 
  set_covariates `depvar' `country'	// if depvar == consumption --> include hh size
  gen_time_trend
  fix_varlabels
end

capture program drop data_setup_2waves
program define data_setup_2waves
  args country choice depvar balance
* Open data
  use_data 					`country'

* Define choice dimension ('urban' or 'nonag')
  handle_choice			`choice'

* Define outcome variable and drop if missing or negative
  handle_depvar			`depvar'
  
* Impose balanced or unbalanced panel
  handle_balance		`balance'

* Create trajectories and switcher variable  
  handle_trajectory_groups

* Create trajectories and switcher variable for individuals in at least 2 waves
  handle_trajectory_groups_2waves

* *******
* Covariate management
* *******  
* Drop observations with missing values 
  set_covariates `depvar' `country'	// if depvar == consumption --> include hh size
  gen_time_trend
  fix_varlabels
end

capture program drop data_setup_3waves
program define data_setup_3waves
  args country choice depvar balance
* Open data
  use_data 					`country'

* Define choice dimension ('urban' or 'nonag')
  handle_choice			`choice'

* Define outcome variable and drop if missing or negative
  handle_depvar			`depvar'
  
* Impose balanced or unbalanced panel
  handle_balance		`balance'

* Create trajectories and switcher variable  
  handle_trajectory_groups

* Create trajectories and switcher variable for individuals in at least 3 waves
  handle_trajectory_groups_3waves

* *******
* Covariate management
* *******  
* Drop observations with missing values 
  set_covariates `depvar' `country'	// if depvar == consumption --> include hh size
  gen_time_trend
  fix_varlabels
end

* **********************************************************************
* Open data
* **********************************************************************
capture program drop use_data
program define use_data
    args country
    use "$dirdata/countries/`country'", clear
end

* **********************************************************************
* Set choice variable
* **********************************************************************
capture program drop handle_choice
program define handle_choice
    args choice
    clonevar choice = `choice'
    drop if mi(choice)
    display as text "Note: Dropped `r(N_drop)' observations due to missing values in `choice'"
    if "`choice'" == "nonag" label var choice "Non-Agricultural"
    if "`choice'" == "urban" label var choice "Urban"
end

* **********************************************************************
* Set dependent variable
* **********************************************************************
capture program drop handle_depvar
program define handle_depvar
    args depvar
    clonevar depvar = `depvar'
    drop if mi(depvar) | depvar <= 0
	display as text "Note: Dropped `r(N_drop)' observations due to missing/negative values in `depvar' "
    * per-capita (adult-equivalent cube) outcome, built once at source so every
    * downstream estimator inherits it; hhsize_cube arrives with the raw panel
    gen lndepvar = log(depvar/hhsize_cube)
	label var lndepvar "Log (`depvar')"
	
	gen ln_income		= ln(income)
	lab var				ln_income "Log Income"
	gen ln_consumption 	= ln(consumption)
	lab var 			ln_consumption "Log Consumption"
end

* **********************************************************************
* Declare panel, impose balance if balance = bal
* **********************************************************************
capture program drop handle_balance
program define handle_balance
    args balance
    xtset pid period
	local max_period = r(tmaxs)
    by pid: gen nr_periods_obs	= _N		// number of obs for pid
		label var nr_periods_obs "Number of observations per individual"
	gen unbalanced = (nr_periods_obs != `max_period')
	gen unbalanced_choice = unbalanced*choice
	lab var unbalanced "Unbalanced panel = 1"
	lab var unbalanced_choice "Unbalanced panel * choice"

	* Change A: strict-spec sample restriction. An individual missing any
	* strictest-column regressor in any wave is reflagged unbalanced, so they
	* leave the balanced trajectory cells and land in the unbalanced cell with
	* their valid waves kept (lumped, not deleted). Raw names hardcoded because
	* set_covariates (which defines the covariate globals) runs later.
	tempvar miss_row
	gen byte `miss_row' = missing(hhsize_cube) | hhsize_cube <= 0 | ///
		missing(female) | missing(age) | missing(education_max)
	bysort pid: egen byte pid_miss_strict = max(`miss_row')
	quietly count if pid_miss_strict & !unbalanced
	di as text "handle_balance: Change A reflagging `r(N)' person-waves (strict-spec-incomplete individuals) as unbalanced"
	replace unbalanced = 1 if pid_miss_strict
	replace unbalanced_choice = unbalanced*choice
	drop pid_miss_strict

    if "`balance'" == "bal" {
		keep if unbalanced == 0
	}
end

* **********************************************************************
* Handle trajectory groups
* **********************************************************************
capture program drop handle_trajectory_groups
program define handle_trajectory_groups
  preserve
	* Keep relevant observations and variables
	keep if !unbalanced
	keep pid period choice
	
	* Reshape the data
	reshape wide choice, i(pid) j(period)
	
	* Initialize an empty string variable for trajectories
    gen string_traj = ""
	
    * Unabbreviate the list of 'choice' variables
	unab choice_vars: choice*
	
	* Concatenate choice variables into a single string
	foreach var of varlist `choice_vars' {
		tostring `var', gen(`var'S)
		replace string_traj = string_traj + `var'S
		drop `var'S  // Drop temporary string variables
	}

	* Encode string trajectories to numerical form, maintaining natural order
	* it automatically orders them in a "natural" way (000, 001, ..., 110, 111)
	* ordering matters for defining globals for 1st switcher, last switcher, etc
    encode string_traj, gen(traj)
    lab var traj "Trajectory indicators"
    drop string_traj

	* Save this as a tempfile for merging with original data
	drop choice*
	tempfile traj
	save `traj'
	
	* Restore original data and merge with trajectories
	restore
	merge m:1 pid using `traj'
	assert_merge_clean, allow(1 3) label("handle_trajectory_groups")

	* Verify the trajectories (missing indicates unbalanced observations)
	rename traj trajectory
	tab trajectory
	* Grab biggest number (always-adopters)
	local max_trajectory = r(r)
	gen switcher_temp = ((trajectory > 1 & trajectory < `max_trajectory'))
	bys pid: egen switcher = min(switcher_temp)
	label variable switcher "Switcher"
	* C10: non_switcher counts observed non-movers (all rural or all urban
	* across a worker's OBSERVED waves), so unbalanced workers---who have a
	* missing balanced-only trajectory and were previously counted as neither
	* switcher nor non-switcher---are classified correctly in the unbalanced
	* summary statistics. switcher stays trajectory-based because it feeds the
	* GRC average-return weights and the OLS migrants-only column.
	bys pid: egen byte pid_any_urban = max(choice == 1)
	bys pid: egen byte pid_any_rural = max(choice == 0)
	gen byte non_switcher = !(pid_any_urban & pid_any_rural)
	label variable non_switcher "Non-switcher"
	drop switcher_temp pid_any_urban pid_any_rural
	
	bysort pid: egen obs_per_individual = count(pid)
	label variable obs_per_individual "Number of obs per pid"
	
	bysort pid (year): g pid_first_obs = _n == 1
	label variable pid_first_obs "Indicator for pid's first obs"
end	

* **********************************************************************
* Handle trajectory groups with at least 2 waves
* **********************************************************************
capture program drop handle_trajectory_groups_2waves
program define handle_trajectory_groups_2waves
  preserve
	* Keep relevant observations and variables
	bys pid: g pid_obs = _N
	lab var pid_obs "# of periods individual is present in survey"
	keep if pid_obs >= 2
	keep pid period choice pid_obs
	
	* Reshape the data
	reshape wide choice, i(pid) j(period)
	
	* Initialize an empty string variable for trajectories
    gen traj_2waves = ""
	
    * Unabbreviate the list of 'choice' variables
	unab choice_vars: choice*
	
	* Concatenate choice variables into a single string
	foreach var of varlist `choice_vars' {
		tostring `var', gen(`var'S)
		replace `var'S = "" if `var'S == "."
		replace traj_2waves = traj_2waves + `var'S
		drop `var'S  // Drop temporary string variables
	}
	lab var traj_2waves "Trajectory indicators"

	* Save this as a tempfile for merging with original data
	keep pid traj_2waves pid_obs
	tempfile traj
	save `traj'
	
	* Restore original data and merge with trajectories
	restore
	merge m:1 pid using `traj'
	assert_merge_clean, allow(1 3) label("handle_trajectory_groups_2waves")

	* Verify the trajectories (missing indicates unbalanced observations)
	rename traj_2waves trajectory_2waves
	tab trajectory_2waves
	
	* Grab biggest number (always-adopters)
	gen non_switcher_2waves = .
	replace non_switcher_2waves = 1 if trajectory_2waves == "00" | trajectory_2waves == "000" | trajectory_2waves == "0000" | trajectory_2waves == "00000" | trajectory_2waves == "11" | trajectory_2waves == "111" | trajectory_2waves == "1111" | trajectory_2waves == "11111"
	replace non_switcher_2waves = 0 if trajectory_2waves == "00001" | trajectory_2waves == "0001" | trajectory_2waves == "00011" | trajectory_2waves == "001" | trajectory_2waves == "0011" | trajectory_2waves == "00111" | trajectory_2waves == "01" | trajectory_2waves == "011" | trajectory_2waves == "0111" | trajectory_2waves == "01111" | trajectory_2waves == "00010" | trajectory_2waves == "0010" | trajectory_2waves == "00100" | trajectory_2waves == "00101" | trajectory_2waves == "00110" | trajectory_2waves == "010" | trajectory_2waves == "0100" | trajectory_2waves == "01000" | trajectory_2waves == "01001" | trajectory_2waves == "0101" | trajectory_2waves == "01010" | trajectory_2waves == "01011" | trajectory_2waves == "0110" | trajectory_2waves == "01100" | trajectory_2waves == "01101" | trajectory_2waves == "01110" | trajectory_2waves == "10001" | trajectory_2waves == "1001" | trajectory_2waves == "10010" | trajectory_2waves == "10011" | trajectory_2waves == "101" | trajectory_2waves == "1010" | trajectory_2waves == "10100" | trajectory_2waves == "10101" | trajectory_2waves == "1011" | trajectory_2waves == "10110" | trajectory_2waves == "10111" | trajectory_2waves == "11001" | trajectory_2waves == "1101" | trajectory_2waves == "11010" | trajectory_2waves == "11011" | trajectory_2waves == "11101" | trajectory_2waves == "10" | trajectory_2waves == "100" | trajectory_2waves == "1000" | trajectory_2waves == "10000" | trajectory_2waves == "110" | trajectory_2waves == "1100" | trajectory_2waves == "11000" | trajectory_2waves == "1110" | trajectory_2waves == "11100" | trajectory_2waves == "11110"
	label variable non_switcher_2waves "Non-switcher"
	gen switcher_2waves = non_switcher_2waves == 0
	label variable switcher_2waves "Switcher"
	
	bysort pid: egen obs_per_individual_2waves = count(pid)
	label variable obs_per_individual_2waves "Number of obs per pid"
	
	bysort pid (year): g pid_first_obs_2waves = _n == 1
	label variable pid_first_obs_2waves "Indicator for pid's first obs"
end	

* **********************************************************************
* Handle trajectory groups with at least 3 waves
* **********************************************************************
capture program drop handle_trajectory_groups_3waves
program define handle_trajectory_groups_3waves
  preserve
	* Keep relevant observations and variables
	bys pid: g pid_obs = _N
	lab var pid_obs "# of periods individual is present in survey"
	keep if pid_obs >= 3
	keep pid period choice pid_obs
	
	* Reshape the data
	reshape wide choice, i(pid) j(period)
	
	* Initialize an empty string variable for trajectories
    gen traj_3waves = ""
	
    * Unabbreviate the list of 'choice' variables
	unab choice_vars: choice*
	
	* Concatenate choice variables into a single string
	foreach var of varlist `choice_vars' {
		tostring `var', gen(`var'S)
		replace `var'S = "" if `var'S == "."
		replace traj_3waves = traj_3waves + `var'S
		drop `var'S  // Drop temporary string variables
	}
	lab var traj_3waves "Trajectory indicators"

	* Save this as a tempfile for merging with original data
	keep pid traj_3waves pid_obs
	tempfile traj
	save `traj'
	
	* Restore original data and merge with trajectories
	restore
	merge m:1 pid using `traj'
	assert_merge_clean, allow(1 3) label("handle_trajectory_groups_3waves")

	* Verify the trajectories (missing indicates unbalanced observations)
	rename traj_3waves trajectory_3waves
	tab trajectory_3waves
	
	gen non_switcher_3waves = .
	replace non_switcher_3waves = 1 if trajectory_3waves == "000" | trajectory_3waves == "0000" | trajectory_3waves == "00000" | trajectory_3waves == "111" | trajectory_3waves == "1111" | trajectory_3waves == "11111"
	replace non_switcher_3waves = 0 if trajectory_3waves == "00001" | trajectory_3waves == "0001" | trajectory_3waves == "00011" | trajectory_3waves == "001" | trajectory_3waves == "0011" | trajectory_3waves == "00111" | trajectory_3waves == "011" | trajectory_3waves == "0111" | trajectory_3waves == "01111" | trajectory_3waves == "00010" | trajectory_3waves == "0010" | trajectory_3waves == "00100" | trajectory_3waves == "00101" | trajectory_3waves == "00110" | trajectory_3waves == "010" | trajectory_3waves == "0100" | trajectory_3waves == "01000" | trajectory_3waves == "01001" | trajectory_3waves == "0101" | trajectory_3waves == "01010" | trajectory_3waves == "01011" | trajectory_3waves == "0110" | trajectory_3waves == "01100" | trajectory_3waves == "01101" | trajectory_3waves == "01110" | trajectory_3waves == "10001" | trajectory_3waves == "1001" | trajectory_3waves == "10010" | trajectory_3waves == "10011" | trajectory_3waves == "101" | trajectory_3waves == "1010" | trajectory_3waves == "10100" | trajectory_3waves == "10101" | trajectory_3waves == "1011" | trajectory_3waves == "10110" | trajectory_3waves == "10111" | trajectory_3waves == "11001" | trajectory_3waves == "1101" | trajectory_3waves == "11010" | trajectory_3waves == "11011" | trajectory_3waves == "11101" | trajectory_3waves == "100" | trajectory_3waves == "1000" | trajectory_3waves == "10000" | trajectory_3waves == "110" | trajectory_3waves == "1100" | trajectory_3waves == "11000" | trajectory_3waves == "1110" | trajectory_3waves == "11100" | trajectory_3waves == "11110"
	label variable non_switcher_3waves "Non-switcher"
	gen switcher_3waves = non_switcher_3waves == 0
	label variable switcher_3waves "Switcher"
	
	bysort pid: egen obs_per_individual_3waves = count(pid)
	label variable obs_per_individual_3waves "Number of obs per pid"
	
	bysort pid (year): g pid_first_obs_3waves = _n == 1
	label variable pid_first_obs_3waves "Indicator for pid's first obs"
end	

* **********************************************************************
* Time trend
* **********************************************************************
capture program drop gen_time_trend
program define gen_time_trend
    sum year if period == 1
    gen trend = year - r(min)
	lab var trend "Time trend"
end

* **********************************************************************
* gen_vfirst: earliest non-missing value of `vname' per pid
* **********************************************************************
* Used by initial_values_robust / run_grc_robust to build the
* time-invariant cluster index v_i (first-wave province/region) that
* VV (2020) Section F requires for the robust extrapolation.
* Unit-tested at explorations/verdier/3_test_gen_vfirst.do.
* The buggy bysort pid: egen min(cond(!missing(v), v, .)) returns the
* smallest numeric value of v per pid, NOT the first-wave value; the
* correct form below marks the FIRST non-missing row per pid sorted by
* year, then propagates its value within pid.
capture program drop gen_vfirst
program define gen_vfirst
    syntax , vname(varname) genname(name)
    capture drop `genname'
    tempvar seq mark tmp
    bysort pid (year): gen `seq' = sum(!missing(`vname'))
    by pid: gen `mark' = (!missing(`vname')) & (`seq' == 1)
    gen `tmp' = `vname' if `mark'
    by pid: egen `genname' = max(`tmp')
    lab var `genname' "First-wave non-missing `vname'"
end

* **********************************************************************
* Covariate management
* **********************************************************************

capture program drop set_covariates
program define set_covariates
  args 			depvar country
	gen 			loghhsize = log(hhsize)	
	label var 	loghhsize "Log Household Size"

	gen 			rural = 1-urban
	lab var 	rural	"Rural"

	if "`country'" ==	"IDN" {
		clonevar baseline_age = age1993
    gen 			ag = 1-nonag
    lab var 	ag	"Agricultural"
	}
	if "`country'" == "CHN" | "`country'" == "CHN_hukou_rural_only" | "`country'" == "CHN_hukou_urban_only" | "`country'" == "CHN_hukou_rural_first" | "`country'" == "CHN_hukou_urban_first" {
		clonevar baseline_age = age2010
	}
	if "`country'" ==	"TZA" {
		clonevar baseline_age = age2008
	}
	
	global 	covs_1 					"female"
	global 	covs_2					"$covs_1 c.age#c.age"
	global 	covs_all				"$covs_2 c.education_max##c.education_max"
	
	global  covs_1_hukou			"hukou"
	global 	covs_2_hukou 			"$covs_1_hukou female"
	global 	covs_3_hukou			"$covs_2_hukou c.age#c.age"
	global 	covs_all_hukou			"$covs_3_hukou c.education_max##c.education_max"
	
	* gmm doesn't play nice with some factor variables
	* so reluctantly generating the interaction terms
	* factor variables also drastically increase the computation time for gmm
	gen baseline_age2  = baseline_age*baseline_age
    gen age2           = age*age
	gen education_max2 = education_max*education_max
	global covs_gmm   "female"
// 	global covs_gmm2  "$covs_gmm baseline_age baseline_age2"
    global covs_gmm2  "$covs_gmm age2"

	global covs_gmm_all "$covs_gmm2 education_max education_max2"
	
	global covs_gmm_hukou   	"hukou"
	global covs_gmm2_hukou   	"$covs_gmm_hukou female"
    global covs_gmm3_hukou		"$covs_gmm2_hukou age2"
	global covs_gmm_all_hukou 	"$covs_gmm3_hukou education_max education_max2"

  drop if mi(education_max)
	drop if mi(age)
	drop if obs_per_individual == 1

end
* **********************************************************************
* Variable labels
* **********************************************************************
capture program drop 	fix_varlabels
program define 		fix_varlabels
	lab variable          baseline_age 		"Age at baseline (years)"
	lab variable          baseline_age2 	"Age at baseline (years) squared"
  lab variable          age             "Age (years)"
  lab variable          age2            "Age (years) squared"
	lab variable          education_max 	"Education (years)"
	lab variable          education_max2 	"Education (years) squared"
	lab variable          hhsize          "Household Size"
	lab variable          female          "Female"
	capture: lab variable nonag           "Non-Agricultural"
end

* **********************************************************************
* Custom LaTeX table (for summary stats by country)
* **********************************************************************
* Create a custom LaTeX table
capture program 		drop sumstats_table
program 				define sumstats_table
	syntax, TABle_notes(string asis) COUNTRY(string asis) OUTputdir(string asis) FILEname(string asis) BALance(string asis)
	
	if "`country'" 	== "IDN" {
		local 		country_name "Indonesia"
	}
	if "`country'" 	== "CHN" {
		local 		country_name "China"
	}
	if "`country'" 	== "TZA" {
		local 		country_name "Tanzania"
	}	 
  local       balance_caption ""
  if "`balance'"  == "bal" {
      local   balance_caption ", Balanced Panel"
  }
  
	* Clear any existing file handle
	file close _all

  * Construct the full file path using the output directory.
  * M4: append ${vsfx} (empty for nominal, "_r" for real) so nominal/real
  * artifacts coexist without clobbering.
  local filepath "`outputdir'/`filename'${vsfx}.tex"
	local table_label "tab:`filename'"

  file open myfile using "`filepath'", write replace
	if "`choice'"  == "urban" & "`balance'"  == "unb" {
		file write myfile "\begin{table}[h!] \centering \caption{Summary Statistics `country_name'`balance_caption'}\label{`table_label'} \begin{threeparttable} \begin{tabular}{l cccc} \toprule" _n
	}
	else {
		file write myfile "\begin{table}[htbp] \centering \caption{Summary Statistics `country_name'`balance_caption'}\label{`table_label'} \begin{threeparttable} \begin{tabular}{l cccc} \toprule" _n
	}
	if "`choice'"  == "urban" {
      file write myfile "& All & Rural & Urban & Difference \\" _n
	}
	if "`choice'"  == "nonag" {
      file write myfile "& All & Agricultural & Non-Agricultural & Difference \\" _n
	}
	file write myfile " &  &  &  & \$t\$-test \\" _n
	/* file write myfile "\addlinespace" _n */
	file write myfile "\midrule" _n

	* Loop through each observation and write to the LaTeX file
	quietly {
		forvalues i = 1/`=_N' {
			local varname 		  = v1[`i']
			local all 				  = v3[`i']
			local rural 			  = v5[`i']
			local urban 			  = v7[`i']
			local difference 		= v9[`i']
			* Add one linespace after Location
			if `i' == 1 {
				file write myfile "`varname' & `all' & `rural' & `urban' & `difference' \\  \addlinespace \addlinespace" _n
			}
			else {
				* Only add \addlinespace to odd lines, except for "Observations" row
				if mod(`i', 2) == 1 & `i' != 15 {
					file write myfile "`varname' & `all' & `rural' & `urban' & `difference' \\  \addlinespace" _n
				}
				else {
						file write myfile "`varname' & `all' & `rural' & `urban' & `difference' \\" _n
				}
			}
		}
	}

	file write myfile "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}"
	file close myfile

end

* **********************************************************************
* Combined summary stats table (three countries side by side, landscape)
* **********************************************************************
capture program 	drop sumstats_combined_table
program 			define sumstats_combined_table
	syntax, BALance(string asis) OUTputdir(string asis) FILEname(string asis)

	* Balance-dependent caption suffix and note wording
	local balance_caption ""
	local balance_word    "unbalanced"
	if "`balance'" == "bal" {
		local balance_caption ", Balanced Panel"
		local balance_word    "balanced"
	}

	* Build each country's summary block; stash its four data columns keyed by row
	foreach c in IDN CHN TZA {
		use "$dirdata/processed/`c'_`balance'.dta", clear
		quietly count if !mi(ln_income)
		local inc_`c' = string(r(N), "%9.0fc")
		country_summary_stats `c' urban consumption `balance'
		gen long _row = _n
		if "`c'" == "IDN" {
			keep _row v1 v3 v5 v7 v9
		}
		else {
			keep _row v3 v5 v7 v9
		}
		rename (v3 v5 v7 v9) (`c'_all `c'_rural `c'_urban `c'_diff)
		tempfile t`c'
		save `t`c''
	}
	use `tIDN', clear
	merge 1:1 _row using `tCHN', nogen
	merge 1:1 _row using `tTZA', nogen
	sort _row

	* Open the output file
	file close _all
	local filepath    "`outputdir'/`filename'${vsfx}.tex"
	local table_label "tab:`filename'"
	file open myfile using "`filepath'", write replace

	file write myfile "\begin{sidewaystable} \centering" _n
	file write myfile "\caption{Summary Statistics`balance_caption'}\label{`table_label'}" _n
	file write myfile "\begin{threeparttable}" _n
	file write myfile "\begin{tabular}{l cccc cccc cccc} \toprule" _n
	file write myfile "& \multicolumn{4}{c}{Indonesia} & \multicolumn{4}{c}{China} & \multicolumn{4}{c}{Tanzania} \\" _n
	file write myfile "\cmidrule(lr){2-5} \cmidrule(lr){6-9} \cmidrule(lr){10-13}" _n
	file write myfile "& All & Rural & Urban & Diff. & All & Rural & Urban & Diff. & All & Rural & Urban & Diff. \\" _n

	quietly {
		local nrows = _N
		forvalues i = 1/`nrows' {
			local lab = v1[`i']
			* cmidrule marker row: emit a rule spanning all data columns
			if "`lab'" == "\cmidrule{2-5}" {
				file write myfile "\cmidrule(lr){2-13}" _n
				continue
			}
			local i_all = IDN_all[`i']
			local i_rur = IDN_rural[`i']
			local i_urb = IDN_urban[`i']
			local i_dif = IDN_diff[`i']
			local c_all = CHN_all[`i']
			local c_rur = CHN_rural[`i']
			local c_urb = CHN_urban[`i']
			local c_dif = CHN_diff[`i']
			local t_all = TZA_all[`i']
			local t_rur = TZA_rural[`i']
			local t_urb = TZA_urban[`i']
			local t_dif = TZA_diff[`i']
			* skip fully-blank leftover rows from iebaltab
			if "`lab'" == "" & "`i_all'" == "" & "`c_all'" == "" & "`t_all'" == "" {
				continue
			}
			local cells "`lab' & `i_all' & `i_rur' & `i_urb' & `i_dif' & `c_all' & `c_rur' & `c_urb' & `c_dif' & `t_all' & `t_rur' & `t_urb' & `t_dif'"
			if `i' == 1 {
				file write myfile "`cells' \\  \addlinespace \addlinespace" _n
			}
			else if mod(`i', 2) == 1 {
				file write myfile "`cells' \\  \addlinespace" _n
			}
			else {
				file write myfile "`cells' \\" _n
			}
		}
	}

	file write myfile "\bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{Summary statistics for the `balance_word' panel. Sources: IFLS (Indonesia), China survey (China), and Tanzania survey (Tanzania). The table reports means and standard deviations (in parentheses) based on individual-year pairs. The All column reports the country-wide mean; Rural and Urban report location-specific means, and Diff. reports their difference, with stars from a \$t\$-test of equality. See Section \ref{sec:data} for further details. All variables have the same number of observations within a country, except income, which is missing for some observations: it has `inc_IDN', `inc_CHN', and `inc_TZA' observations in Indonesia, China, and Tanzania, respectively.} \end{tablenotes}" _n
	file write myfile "\end{threeparttable}" _n
	file write myfile "\end{sidewaystable}" _n
	file close myfile

end

* **********************************************************************
* Summary stats table prep
* **********************************************************************
capture program drop		country_summary_stats
program define			country_summary_stats
args								country choice depvar balance
	
* Grab number of observations	
	summarize 					pid
	local observations 			= r(N)
* Format the observations to have a comma
	local observations_formatted = string(`observations', "%9.0fc")	
* Grab number of individuals
	egen tag 					= tag(pid)
	summarize 					tag
	local num_individuals 		= r(sum)
	local num_individuals_formatted = string(`num_individuals', "%9.0fc")		
* Grab number of obs for urban/rural
	count if rural
	local num_rural			= r(N)	
	local num_rural_formatted = string(`num_rural', "%9.0fc")		
	count if urban
	local num_urban			= r(N)	
	local num_urban_formatted = string(`num_urban', "%9.0fc")		
* Grab percentages of urban and rural
	summarize 					rural
	local percent_rural			= r(mean)*100
	local percent_rural_formatted : display %6.1f `percent_rural' "\%"
	summarize 					urban
	local percent_urban			= r(mean)*100
	local percent_urban_formatted : display %6.1f `percent_urban' "\%"	
* Grab percent non-switchers	
	summarize 					non_switcher if pid_first_obs == 1
	local non_switchers			= r(mean)*100
	local non_switchers_formatted : display %6.1f `non_switchers' "\%"	
			
* Create summary stats table, export as .csv file (transient; erased after import)
	iebaltab 		rural ln_consumption ln_income female age 	          ///
					education_max hhsize, ///
					savecsv("$logs/summary_stats_`country'_`balance'.csv") replace  ///
					groupvar(urban) total ///
					totallabel(All) format(%9.2fc) ///
					rowvarlabels stats(desc(sd)) nonote

* Import the saved CSV file, then erase the on-disk intermediate.
	import delimited using "$logs/summary_stats_`country'_`balance'.csv", clear
	erase "$logs/summary_stats_`country'_`balance'.csv"

* Drop unnecessary columns & rows
	drop v2 v4 v6 v8
	drop in 1/3
	drop in 2/2
	set obs 19
	replace v1		= "Location"			in 1
	replace v3 		= "" 					in 1
	replace v5		= "`percent_rural_formatted'" in 1
	replace v7		= "`percent_urban_formatted'" in 1
	replace v9 		= "" 					in 1
	replace v1		= "\cmidrule{2-5}"		in 16
	replace v1 		= "Observations" 		in 17
	replace v1 		= "Individuals" 		in 18
	replace v1 		= "Non-switchers" 		in 19
	replace v3 		= "`observations_formatted'" 		in 17	
	replace v3 		= "`num_individuals_formatted'" 	in 18
	replace v3 		= "`non_switchers_formatted'" 	in 19
	replace v5		= "`num_rural_formatted'"			in 17
	replace v7		= "`num_urban_formatted'"			in 17
end

* **********************************************************************
* Summary stats table prep - at least 2 waves
* **********************************************************************
capture program drop		country_summary_stats_2waves
program define			country_summary_stats_2waves
args								country choice depvar balance
	
* Grab number of observations	
	summarize 					pid
	local observations 			= r(N)
* Format the observations to have a comma
	local observations_formatted = string(`observations', "%9.0fc")	
* Grab number of individuals
	egen tag 					= tag(pid)
	summarize 					tag
	local num_individuals 		= r(sum)
	local num_individuals_formatted = string(`num_individuals', "%9.0fc")		
* Grab number of obs for urban/rural
	count if rural
	local num_rural			= r(N)	
	local num_rural_formatted = string(`num_rural', "%9.0fc")		
	count if urban
	local num_urban			= r(N)	
	local num_urban_formatted = string(`num_urban', "%9.0fc")		
* Grab percentages of urban and rural
	summarize 					rural
	local percent_rural			= r(mean)*100
	local percent_rural_formatted : display %6.1f `percent_rural' "\%"
	summarize 					urban
	local percent_urban			= r(mean)*100
	local percent_urban_formatted : display %6.1f `percent_urban' "\%"	
* Grab percent non-switchers	
	keep if pid_first_obs_2waves == 1 & pid_obs >= 2 & non_switcher_2waves != .
	summarize 					non_switcher_2waves
	local non_switchers			= r(mean)*100
	local non_switchers_formatted : display %6.1f `non_switchers' "\%"	
			
* Create summary stats table, export as .csv file (transient; erased after import)
	iebaltab 		rural ln_consumption ln_income female age 	          ///
					education_max hhsize, ///
					savecsv("$logs/summary_stats_`country'_`balance'_2waves.csv") replace  ///
					groupvar(urban) total ///
					totallabel(All) format(%9.2fc) ///
					rowvarlabels stats(desc(sd)) nonote

* Import the saved CSV file, then erase the on-disk intermediate.
	import delimited using "$logs/summary_stats_`country'_`balance'_2waves.csv", clear
	erase "$logs/summary_stats_`country'_`balance'_2waves.csv"
	
* Drop unnecessary columns & rows
	drop v2 v4 v6 v8
	drop in 1/3
	drop in 2/2
	set obs 19
	replace v1		= "Location"			in 1
	replace v3 		= "" 					in 1
	replace v5		= "`percent_rural_formatted'" in 1
	replace v7		= "`percent_urban_formatted'" in 1
	replace v9 		= "" 					in 1
	replace v1		= "\cmidrule{2-5}"		in 16
	replace v1 		= "Observations" 		in 17
	replace v1 		= "Individuals" 		in 18
	replace v1 		= "Non-switchers" 		in 19
	replace v3 		= "`observations_formatted'" 		in 17	
	replace v3 		= "`num_individuals_formatted'" 	in 18
	replace v3 		= "`non_switchers_formatted'" 	in 19
	replace v5		= "`num_rural_formatted'"			in 17
	replace v7		= "`num_urban_formatted'"			in 17
end

* **********************************************************************
* Summary stats table prep - at least 3 waves
* **********************************************************************
capture program drop		country_summary_stats_3waves
program define			country_summary_stats_3waves
args								country choice depvar balance
	
* Grab number of observations	
	summarize 					pid
	local observations 			= r(N)
* Format the observations to have a comma
	local observations_formatted = string(`observations', "%9.0fc")	
* Grab number of individuals
	egen tag 					= tag(pid)
	summarize 					tag
	local num_individuals 		= r(sum)
	local num_individuals_formatted = string(`num_individuals', "%9.0fc")		
* Grab number of obs for urban/rural
	count if rural
	local num_rural			= r(N)	
	local num_rural_formatted = string(`num_rural', "%9.0fc")		
	count if urban
	local num_urban			= r(N)	
	local num_urban_formatted = string(`num_urban', "%9.0fc")		
* Grab percentages of urban and rural
	summarize 					rural
	local percent_rural			= r(mean)*100
	local percent_rural_formatted : display %6.1f `percent_rural' "\%"
	summarize 					urban
	local percent_urban			= r(mean)*100
	local percent_urban_formatted : display %6.1f `percent_urban' "\%"	
* Grab percent non-switchers	
	keep if pid_first_obs_3waves == 1 & pid_obs >= 3 & non_switcher_3waves != .
	summarize 					non_switcher_3waves
	local non_switchers			= r(mean)*100
	local non_switchers_formatted : display %6.1f `non_switchers' "\%"	
			
* Create summary stats table, export as .csv file (transient; erased after import)
	iebaltab 		rural ln_consumption ln_income female age 	          ///
					education_max hhsize, ///
					savecsv("$logs/summary_stats_`country'_`balance'_3waves.csv") replace  ///
					groupvar(urban) total ///
					totallabel(All) format(%9.2fc) ///
					rowvarlabels stats(desc(sd)) nonote

* Import the saved CSV file, then erase the on-disk intermediate.
	import delimited using "$logs/summary_stats_`country'_`balance'_3waves.csv", clear
	erase "$logs/summary_stats_`country'_`balance'_3waves.csv"
	
* Drop unnecessary columns & rows
	drop v2 v4 v6 v8
	drop in 1/3
	drop in 2/2
	set obs 19
	replace v1		= "Location"			in 1
	replace v3 		= "" 					in 1
	replace v5		= "`percent_rural_formatted'" in 1
	replace v7		= "`percent_urban_formatted'" in 1
	replace v9 		= "" 					in 1
	replace v1		= "\cmidrule{2-5}"		in 16
	replace v1 		= "Observations" 		in 17
	replace v1 		= "Individuals" 		in 18
	replace v1 		= "Non-switchers" 		in 19
	replace v3 		= "`observations_formatted'" 		in 17	
	replace v3 		= "`num_individuals_formatted'" 	in 18
	replace v3 		= "`non_switchers_formatted'" 	in 19
	replace v5		= "`num_rural_formatted'"			in 17
	replace v7		= "`num_urban_formatted'"			in 17
end

* **********************************************************************
* Summary stats table prep for ag/nonag 
*   - should instead make the main one more robust but no time
* **********************************************************************
capture program drop		country_summary_stats_nonag
program define			country_summary_stats_nonag
args								country choice depvar balance
	
* Grab number of observations	
	summarize 					pid
	local observations 			= r(N)
* Format the observations to have a comma
	local observations_formatted = string(`observations', "%9.0fc")	
* Grab number of individuals
	egen tag 					= tag(pid)
	summarize 					tag
	local num_individuals 		= r(sum)
	local num_individuals_formatted = string(`num_individuals', "%9.0fc")		
* Grab number of obs for urban/rural
	count if ag
	local num_ag			= r(N)	
	local num_ag_formatted = string(`num_ag', "%9.0fc")		
	count if nonag
	local num_nonag			= r(N)	
	local num_nonag_formatted = string(`num_nonag', "%9.0fc")		
* Grab percentages of ag and nonag
	summarize 					ag
	local percent_ag			= r(mean)*100
	local percent_ag_formatted : display %6.1f `percent_ag' "\%"
	summarize 					nonag
	local percent_nonag			= r(mean)*100
	local percent_nonag_formatted : display %6.1f `percent_nonag' "\%"	
* Grab percent non-switchers	
	summarize 					non_switcher if pid_first_obs == 1
	local non_switchers			= r(mean)*100
	local non_switchers_formatted : display %6.1f `non_switchers' "\%"	
			
* Create summary stats table, export as .csv file (transient; erased after import)
	iebaltab 		ag ln_consumption ln_income female age 	          ///
					education_max hhsize, ///
					savecsv("$logs/summary_stats_`country'_`balance'_nonag.csv") replace  ///
					groupvar(nonag) total ///
					totallabel(All) format(%9.2fc) ///
					rowvarlabels stats(desc(sd)) nonote

* Import the saved CSV file, then erase the on-disk intermediate.
	import delimited using "$logs/summary_stats_`country'_`balance'_nonag.csv", clear
	erase "$logs/summary_stats_`country'_`balance'_nonag.csv"
	
* Drop unnecessary columns & rows
	drop v2 v4 v6 v8
	drop in 1/3
	drop in 2/2
	set obs 19
	replace v1		= "Non-Agricultural"			in 1
	replace v3 		= "" 					in 1
	replace v5		= "`percent_ag_formatted'" in 1
	replace v7		= "`percent_nonag_formatted'" in 1
	replace v9 		= "" 					in 1
	replace v1		= "\cmidrule{2-5}"		in 16
	replace v1 		= "Observations" 		in 17
	replace v1 		= "Individuals" 		in 18
	replace v1 		= "Non-switchers" 		in 19
	replace v3 		= "`observations_formatted'" 		in 17	
	replace v3 		= "`num_individuals_formatted'" 	in 18
	replace v3 		= "`non_switchers_formatted'" 	in 19
	replace v5		= "`num_ag_formatted'"			in 17
	replace v7		= "`num_nonag_formatted'"			in 17
end

* **********************************************************************
* Clean up .tex files
* **********************************************************************
capture program drop removeStringFromTex
program define removeStringFromTex
    syntax anything(name=texFileName) , REMove(string asis)

    * Create a temporary file to store the modified content
    tempfile tempFile

    * Use filefilter to remove the specified string
    filefilter `texFileName' `tempFile', from(`remove') to("")

    * Replace the original file with the modified file
    copy `tempFile' `texFileName', replace
end

* **********************************************************************
* Create three-part LaTeX table
* **********************************************************************
capture program drop create_panel_tex_table
program define create_panel_tex_table
    syntax , 	Panels(integer) COLumns(integer) FILEname(string asis) 	///
				COUNTRIES(string asis) Keep(varlist) 	///
				PREhead(string asis) POSTfoot(string asis) ///
				COEFLABels(string asis) TEXTdepvar(string asis)
	
    // Split the panel names, prehead, and postfoot strings into tokens

    local num_panels `panels'
    local ccc ""
    * Loop to concatenate "c" the number of times specified in `columns'
    forval i = 1/`columns' {
        local ccc "`ccc'c"
    }
    local cmid = `columns' + 1
    
	forvalues i = 1/`num_panels' {
		local replace append
		local colnumbers ""
		local table_prehead 	""
		local table_postfoot 	""
		local posthead 			""

		* C3: resolve the panel's country from the countries() argument and
		* build the label from it, so single-country tables (e.g. the CHN
		* hukou tables) are not mislabeled by panel position.
		local country : word `i' of `countries'
		local panel_letter : word `i' of A B C D E F G
		local cname "`country'"
		if      "`country'" == "IDN"    local cname "Indonesia"
		else if "`country'" == "CHN"    local cname "China"
		else if "`country'" == "TZA"    local cname "Tanzania"
		else if "`country'" == "CHN_rf" local cname "China (rural-first)"
		else if "`country'" == "CHN_uf" local cname "China (urban-first)"

		if `i' == 1 & `i' == `num_panels' {
			local replace replace
			local table_prehead1 "`"\begin{table}[htbp] \centering \begin{threeparttable}"'"
			local table_prehead2 "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
			local table_prehead "`table_prehead1' `prehead' `table_prehead2'"
			local table_posthead "\textbf{Panel `panel_letter': `cname'} \\"
			local table_postfoot "\cmidrule{2 -`cmid'} `postfoot'"
		}
		if `i' == 1 & `i' != `num_panels' {
			local replace replace
			local table_prehead1 "`"\begin{table}[htbp] \centering \begin{threeparttable}"'"
			local table_prehead2 "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
			local table_prehead "`table_prehead1' `prehead' `table_prehead2'"
			local table_posthead "\textbf{Panel `panel_letter': `cname'} \\"
			local table_postfoot "\cmidrule{2 -`cmid'}"
		}
		if `i' == 2 {
			local colnumbers nonum
			local table_posthead "\textbf{Panel `panel_letter': `cname'} \\"
			local table_postfoot "\cmidrule{2-`cmid'}"
		}
		if `i' == 3 {
			local colnumbers nonum
			local table_posthead "\textbf{Panel `panel_letter': `cname'} \\"
			local table_postfoot "\cmidrule{2-`cmid'} `postfoot'"
		}

		local panelname `i'
    local ests = ""        
		
		// Extract word i of panelnames
		local country : word `i' of `countries'
		di as error "Panel `i' `country'"
		
        // Generate the list of stored estimates for the current panel
        forvalues j = 1/`columns' {
            local ests = "`ests' reg`j'_`country'"
        }
        
        esttab `ests'                          ///
        using "$output/tables/`filename'${vsfx}.tex", ///
		se b(%8.3f)                            ///           
        keep(`keep') fragment booktabs         ///
        collabels(none)                        ///
        starlevels(* 0.10 ** 0.05 *** 0.01)    ///
		s(N N_clust r2_a, label("Observations" "Individuals" "Adj. R\$^{2}\$") ///
        fmt(%9.0fc %9.0fc a2))                 ///
        varwidth(20)                           ///
        nolines nomtitles `colnumbers'         ///
        coeflabels(`coeflabels')               ///
        prehead(`table_prehead')               ///
        posthead(`table_posthead')             ///
        postfoot("`table_postfoot'")           ///
        `replace' substitute(\_ _)
    }

end

* **********************************************************************
* Create three-part LaTeX table - learning IDN
* **********************************************************************
capture program drop create_panel_tex_table_learn_IDN
program define create_panel_tex_table_learn_IDN
    syntax , 	COLumns(integer) FILEname(string asis) 	///
				Keep(varlist) 	///
				PREhead(string asis) POSTfoot(string asis) ///
				COEFLABels(string asis) TEXTdepvar(string asis)
	
    // Split the panel names, prehead, and postfoot strings into tokens

    local ccc ""
    * Loop to concatenate "c" the number of times specified in `columns'
    forval i = 1/`columns' {
        local ccc "`ccc'c"
    }
    local cmid = `columns' + 1
    
	local replace append
	local colnumbers ""
	local table_prehead 	""
	local table_postfoot 	""
	local posthead 			""
	local replace replace
	local table_prehead1 "`"\begin{table}[htbp] \centering \begin{threeparttable}"'"
	local table_prehead2 "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
	local table_prehead "`table_prehead1' `prehead' `table_prehead2'"
	local table_postfoot "\cmidrule{2 -`cmid'} `postfoot'"

	local ests = ""        
		
	// Generate the list of stored estimates for the current panel
    forvalues j = 1/`columns' {
		local ests = "`ests' reg`j'_IDN"
    }
        
    esttab `ests'                          ///
    using "$output/tables/`filename'${vsfx}.tex", ///
	se b(%8.3f)                            ///           
    keep(`keep') fragment booktabs         ///
    collabels("")                          ///
    starlevels(* 0.10 ** 0.05 *** 0.01)    ///
	s(urban_p urban_2 urban_3 urban_4 rural_p rural_2 rural_3 rural_4 N N_clust r2_a, label("Joint p-value urban learning" "p-value: 1 year urban = 2 years urban" "p-value: 1 year urban = 3 years urban" "p-value: 1 year urban = 4 years urban" "Joint p-value rural learning" "p-value: 1 year rural = 2 years rural" "p-value: 1 year rural = 3 years rural" "p-value: 1 year rural = 4 years rural" "Observations" "Individuals" "Adj. R\$^{2}\$") ///
    fmt(%9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.0fc %9.0fc a2))	///
    varwidth(20)                           ///
    nolines nomtitles `colnumbers'         ///
    coeflabels(`coeflabels')               ///
    prehead(`table_prehead')               ///
    postfoot("`table_postfoot'")           ///
    `replace' substitute(\_ _)

end

* **********************************************************************
* Create three-part LaTeX table - learning CHN
* **********************************************************************
capture program drop create_panel_tex_table_learn_CHN
program define create_panel_tex_table_learn_CHN
    syntax , 	COLumns(integer) FILEname(string asis) 	///
				Keep(varlist) 	///
				PREhead(string asis) POSTfoot(string asis) ///
				COEFLABels(string asis) TEXTdepvar(string asis)
	
    // Split the panel names, prehead, and postfoot strings into tokens

    local ccc ""
    * Loop to concatenate "c" the number of times specified in `columns'
    forval i = 1/`columns' {
        local ccc "`ccc'c"
    }
    local cmid = `columns' + 1
    
	local replace append
	local colnumbers ""
	local table_prehead 	""
	local table_postfoot 	""
	local posthead 			""
	local replace replace
	local table_prehead1 "`"\begin{table}[htbp] \centering \begin{threeparttable}"'"
	local table_prehead2 "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
	local table_prehead "`table_prehead1' `prehead' `table_prehead2'"
	local table_postfoot "\cmidrule{2 -`cmid'} `postfoot'"

	local ests = ""        
		
	// Generate the list of stored estimates for the current panel
    forvalues j = 1/`columns' {
		local ests = "`ests' reg`j'_CHN"
    }
        
    esttab `ests'                          ///
    using "$output/tables/`filename'${vsfx}.tex", ///
	se b(%8.3f)                            ///           
    keep(`keep') fragment booktabs         ///
    collabels("")                          ///
    starlevels(* 0.10 ** 0.05 *** 0.01)    ///
	s(urban_p urban_2 urban_3 rural_p rural_2 rural_3 N N_clust r2_a, label("Joint p-value urban learning" "p-value: 1 year urban = 2 years urban" "p-value: 1 year urban = 3 years urban" "Joint p-value rural learning" "p-value: 1 year rural = 2 years rural" "p-value: 1 year rural = 3 years rural" "Observations" "Individuals" "Adj. R\$^{2}\$") ///
    fmt(%9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.3fc %9.0fc %9.0fc a2))	///
    varwidth(20)                           ///
    nolines nomtitles `colnumbers'         ///
    coeflabels(`coeflabels')               ///
    prehead(`table_prehead')               ///
    postfoot("`table_postfoot'")           ///
    `replace' substitute(\_ _)

end

* **********************************************************************
* OLS regressions
* **********************************************************************
capture program drop reghdfe_regressions
program define reghdfe_regressions
    args country choice depvar balance
    * OLS / FE regressions using reghdfe
	* Run col 6 first as it has the smallest sample, then use e(sample)
    eststo reg6_`country': reghdfe lndepvar choice			 					///
				$covs_all				 										///
				, vce(cluster pid) absorb(pid period)
		gen regression_sample = e(sample)

	  eststo reg1_`country': reghdfe lndepvar choice			 				///
		if regression_sample, vce(cluster pid) absorb(period)
    eststo reg2_`country': reghdfe lndepvar choice $covs_1 						///
		if regression_sample, vce(cluster pid) absorb(period)
	  eststo reg3_`country': reghdfe lndepvar choice $covs_2 					///
		if regression_sample, vce(cluster pid) absorb(period)
    eststo reg4_`country': reghdfe lndepvar choice $covs_all 					///
		if regression_sample, vce(cluster pid) absorb(period)
    eststo reg5_`country': reghdfe lndepvar choice $covs_all 			 		///
		if regression_sample & switcher, vce(cluster pid) absorb(period)
end

* **********************************************************************
* OLS regressions (learning)
* **********************************************************************
capture program drop reghdfe_regressions_learn_IDN
program define reghdfe_regressions_learn_IDN
    args country depvar balance
    * OLS / FE regressions using reghdfe
	* Run col 4 first as it has the smallest sample, then use e(sample)
    eststo reg4_IDN: reghdfe lndepvar urban_1period urban_2period urban_3period urban_4period rural_1period rural_2period rural_3period rural_4period $covs_all , vce(cluster pid) absorb(pid period)
	gen regression_sample = e(sample)
	test urban_1period=urban_2period=urban_3period=urban_4period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	local urban_1_4 = r(mtest)[3,3]
	test rural_1period=rural_2period=rural_3period=rural_4period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	local rural_1_4 = r(mtest)[3,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar urban_4 = `urban_1_4'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
	estadd scalar rural_4 = `rural_1_4'

    eststo reg1_IDN: reghdfe lndepvar urban_1period urban_2period urban_3period urban_4period rural_1period rural_2period rural_3period rural_4period	if regression_sample, noabsorb vce(cluster pid)
	test urban_1period=urban_2period=urban_3period=urban_4period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	local urban_1_4 = r(mtest)[3,3]
	test rural_1period=rural_2period=rural_3period=rural_4period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	local rural_1_4 = r(mtest)[3,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar urban_4 = `urban_1_4'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
	estadd scalar rural_4 = `rural_1_4'
	
	eststo reg2_IDN: reghdfe lndepvar urban_1period urban_2period urban_3period urban_4period rural_1period rural_2period rural_3period rural_4period if regression_sample, vce(cluster pid) absorb(period)
	test urban_1period=urban_2period=urban_3period=urban_4period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	local urban_1_4 = r(mtest)[3,3]
	test rural_1period=rural_2period=rural_3period=rural_4period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	local rural_1_4 = r(mtest)[3,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar urban_4 = `urban_1_4'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
	estadd scalar rural_4 = `rural_1_4'
    
	eststo reg3_IDN: reghdfe lndepvar urban_1period urban_2period urban_3period urban_4period rural_1period rural_2period rural_3period rural_4period $covs_all if regression_sample, vce(cluster pid) absorb(period)
	test urban_1period=urban_2period=urban_3period=urban_4period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	local urban_1_4 = r(mtest)[3,3]
	test rural_1period=rural_2period=rural_3period=rural_4period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	local rural_1_4 = r(mtest)[3,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar urban_4 = `urban_1_4'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
	estadd scalar rural_4 = `rural_1_4'
		
end

capture program drop reghdfe_regressions_learn_CHN
program define reghdfe_regressions_learn_CHN
    args country depvar balance
    * OLS / FE regressions using reghdfe
	* Run col 4 first as it has the smallest sample, then use e(sample)
    eststo reg4_CHN: reghdfe lndepvar urban_1period urban_2period urban_3period rural_1period rural_2period rural_3period $covs_all , vce(cluster pid) absorb(pid period)
	gen regression_sample = e(sample)
	test urban_1period=urban_2period=urban_3period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	test rural_1period=rural_2period=rural_3period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'

    eststo reg1_CHN: reghdfe lndepvar urban_1period urban_2period urban_3period rural_1period rural_2period rural_3period if regression_sample, noabsorb vce(cluster pid)
	test urban_1period=urban_2period=urban_3period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	test rural_1period=rural_2period=rural_3period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
	
	eststo reg2_CHN: reghdfe lndepvar urban_1period urban_2period urban_3period rural_1period rural_2period rural_3period if regression_sample, vce(cluster pid) absorb(period)
	test urban_1period=urban_2period=urban_3period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	test rural_1period=rural_2period=rural_3period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
    
	eststo reg3_CHN: reghdfe lndepvar urban_1period urban_2period urban_3period rural_1period rural_2period rural_3period $covs_all if regression_sample, vce(cluster pid) absorb(period)
	test urban_1period=urban_2period=urban_3period, mtest
	local urban_p = r(p)
	local urban_1_2 = r(mtest)[1,3]
	local urban_1_3 = r(mtest)[2,3]
	test rural_1period=rural_2period=rural_3period, mtest
	local rural_p = r(p)
	local rural_1_2 = r(mtest)[1,3]
	local rural_1_3 = r(mtest)[2,3]
	estadd scalar urban_p = `urban_p'
	estadd scalar urban_2 = `urban_1_2'
	estadd scalar urban_3 = `urban_1_3'
	estadd scalar rural_p = `rural_p'
	estadd scalar rural_2 = `rural_1_2'
	estadd scalar rural_3 = `rural_1_3'
		
end

* **********************************************************************
* Get ready for GRC
* **********************************************************************

capture program drop setup_grc_estimation
program define setup_grc_estimation
    global 		never 1
    qui: tab 			trajectory
    global 		always `r(r)'	// Last trajectory
    local 		lastswitcher = $always-1
    numlist 	"2(1)`lastswitcher'"	// Grab list of switchers
    global 		switchers `r(numlist)'
    numlist 	"1(1)`lastswitcher'"	// Grab list of all-but-always
    global 		noalways `r(numlist)'
    global 		last = $always-1
    global 		first = $never+1

    replace trajectory = 999 if trajectory == .	// Unbalanced

    * Generating dummies for gmm
    gen always = (trajectory == $always)
    gen always_choice = always*choice

    gen never = (trajectory == 1)

    foreach s of numlist $switchers {
      gen switcher_`s' = (trajectory == `s')
      gen switcher_`s'_choice = switcher_`s'*choice
    }
    
end

* **********************************************************************
* Make heterogeneity figures
* **********************************************************************
capture program drop heterogeneity_plots
program define heterogeneity_plots
	args country choice depvar balance
	if "`country'" == "IDN" {
		local textcountry "Indonesia"
	}
	if "`country'" == "CHN" {
		local textcountry "China"
	}
	if "`country'" == "TZA" {
		local textcountry "Tanzania"
	}

* Compute \Delta estimates for switchers centered around \Delta_never estimate
* Without covariates
  eststo nocovars_`country': 	reg lndepvar i.trajectory							    ///
															i($switchers).trajectory#i.choice    			///
															i.unbalanced#i.choice  						///
															, vce(cluster pid)

* F-test of equality for \mu
	testparm i($switchers).trajectory, equal
  estadd sca F_mus_`country'_nocovars = r(F), replace
	estadd sca p_mus_`country'_nocovars = r(p), replace
	local F_mus_`country'_nocovars: di %-6.2f r(F)
	local p_mus_`country'_nocovars: di %-3.2f r(p)

* F-test of equality for \Delta
	testparm i($switchers).trajectory#1.choice, equal
	estadd sca F_dts_`country'_nocovars = r(F), replace
	estadd sca p_dts_`country'_nocovars = r(p), replace
	local F_dts_`country'_nocovars: di %-6.2f r(F)
	local p_dts_`country'_nocovars: di %-3.2f r(p)

* With covariates for \Delta
  eststo covars_`country': 	  reghdfe lndepvar i.trajectory   							///
														  i($switchers).trajectory#i.choice    			///
              							  i.unbalanced#i.choice $covs_all	  ///
														  , vce(cluster pid) absorb(period)

* F-test of equality for \mu
	testparm i($switchers).trajectory, equal
  estadd sca F_mus_`country'_covars = r(F), replace
	estadd sca p_mus_`country'_covars = r(p), replace
	local F_mus_`country'_covars: di %-6.2f r(F)
	local p_mus_`country'_covars: di %-3.2f r(p)

* F-test of equality for \Delta
	testparm i($switchers).trajectory#1.choice, equal
	estadd sca F_dts_`country'_covars = r(F), replace
	estadd sca p_dts_`country'_covars = r(p), replace
	local F_dts_`country'_covars: di %-6.2f r(F)
	local p_dts_`country'_covars: di %-3.2f r(p)
			  
* Grab interaction coefficients to plot for \Delta
  local interaction_coefs ""
  local coefnames: colnames e(b)
  foreach coef of local coefnames {
  	* if the coefname contains #1.choice
    if strpos("`coef'", "#1.choice") {
      local interaction_coefs "`interaction_coefs' `coef'"
		}
}

* Grab coefficients to plot for \mu
  local mu_coefs ""
  foreach coef of local coefnames {
  	* if the coefname is a trajectory without choice
    if regexm("`coef'", "trajectory$") {
      local mu_coefs "`mu_coefs' `coef'"
		}
}

* Set truncation length for coeflabels
	if "`country'" == "IDN" {
		local coefnr    5
	}
	if "`country'" == "CHN" {
		local coefnr		4
 	}
	if "`country'" == "TZA" {
		local coefnr    3
	}
	
* Plot them for \Delta, sorting by size
	coefplot ///
		(covars_`country', keep(`interaction_coefs') msymb(S) mcolor(lavender%100) ciopts(lwidth(thick) lcolor(lavender%100)))  	///
		(nocovars_`country', keep(`interaction_coefs') msymb(O) mcolor(lavender%50) ciopts(lwidth(thick) lcolor(lavender%50)))	///
		, sort coeflabels(, truncate(`coefnr')) grid(none) ///	
		legend(order(2 "All covariates & time FE" 4 "No covariates") pos(6) rows(1) size(small) span) 		///
		ysize(10) xsize(8) 						///
		ylabel(, labsize(small)) xlabel(, labsize(small))						///
		xline(0, lwidth(thin) lcolor(%40)) title("`textcountry'") ///
		note("F-stat (all equal): `F_dts_`country'_covars' (p-value: `p_dts_`country'_covars')", size(small) pos(6) span) ///
		saving(hetplotDelta_`depvar'_`choice'_`balance'_`country'_Fcovars, replace)
	
		graph save "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_`country'_Fcovars${vsfx}.pdf", replace
	
	coefplot ///
		(covars_`country', keep(`interaction_coefs') msymb(S) mcolor(lavender%100) ciopts(lwidth(thick) lcolor(lavender%100)))  	///
		(nocovars_`country', keep(`interaction_coefs') msymb(O) mcolor(lavender%50) ciopts(lwidth(thick) lcolor(lavender%50)))	///
		, sort coeflabels(, truncate(`coefnr')) grid(none) ///	
		legend(order(2 "All covariates & time FE" 4 "No covariates") pos(6) rows(1) size(small) span) 		///
		ysize(10) xsize(8) 						///
		ylabel(, labsize(small)) xlabel(, labsize(small))						///
		xline(0, lwidth(thin) lcolor(%40)) title("`textcountry'") ///
		note("F-stat (all equal): `F_dts_`country'_nocovars' (p-value: `p_dts_`country'_nocovars')", size(small) pos(6) span) ///
		saving(hetplotDelta_`depvar'_`choice'_`balance'_`country'_Fnocovars, replace)
	
		graph save "$output/figures/hetplotDelta_`depvar'_`choice'_`balance'_`country'_Fnocovars${vsfx}.pdf", replace
	
* Plot them for \mu, sorting by size
	coefplot ///
		(covars_`country', keep(`mu_coefs') msymb(S) mcolor(lavender%100) ciopts(lwidth(thick) lcolor(lavender%100)))  	///
		(nocovars_`country', keep(`mu_coefs') msymb(O) mcolor(lavender%50) ciopts(lwidth(thick) lcolor(lavender%50)))	///
		, sort coeflabels(, truncate(`coefnr')) grid(none) ///	
		legend(order(2 "All covariates & time FE" 4 "No covariates") pos(6) rows(1) size(small) span) 		///
		ysize(10) xsize(8) 						///
		ylabel(, labsize(small)) xlabel(, labsize(small))						///
		xline(0, lwidth(thin) lcolor(%40)) title("`textcountry'") ///
		note("F-stat (all equal): `F_mus_`country'_covars' (p-value: `p_mus_`country'_covars')", size(small) pos(6) span) ///
		saving(hetplotmu_`depvar'_`choice'_`balance'_`country'_Fcovars, replace)
	
		graph save "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_`country'_Fcovars${vsfx}.pdf", replace
	
	coefplot ///
		(covars_`country', keep(`mu_coefs') msymb(S) mcolor(lavender%100) ciopts(lwidth(thick) lcolor(lavender%100)))  	///
		(nocovars_`country', keep(`mu_coefs') msymb(O) mcolor(lavender%50) ciopts(lwidth(thick) lcolor(lavender%50)))	///
		, sort coeflabels(, truncate(`coefnr')) grid(none) ///	
		legend(order(2 "All covariates & time FE" 4 "No covariates") pos(6) rows(1) size(small) span) 		///
		ysize(10) xsize(8) 						///
		ylabel(, labsize(small)) xlabel(, labsize(small))						///
		xline(0, lwidth(thin) lcolor(%40)) title("`textcountry'") ///
		note("F-stat (all equal): `F_mus_`country'_nocovars' (p-value: `p_mus_`country'_nocovars')", size(small) pos(6) span) ///
		saving(hetplotmu_`depvar'_`choice'_`balance'_`country'_Fnocovars, replace)
	
		graph save "$output/figures/hetplotmu_`depvar'_`choice'_`balance'_`country'_Fnocovars${vsfx}.pdf", replace

end

* **********************************************************************
* Robustness coefplot: phi, Delta_never, Delta_avg across the main ca
* spec plus each extra-regressor robustness spec (experience family +
* urban birth). Specs on the y-axis, one panel per estimand. Reads
* existing sters only --- no GMM re-fit. Plain GMM SEs (95% CI).
* **********************************************************************
capture program drop grc_robustness_coefplot
program define grc_robustness_coefplot
	args country
	if "`country'" == "IDN" local textcountry "Indonesia"
	if "`country'" == "TZA" local textcountry "Tanzania"

	* Spec stems (ster family token; "main" carries no family token).
	* IDN has the urban-birth cell on disk; TZA does not.
	if "`country'" == "IDN" {
		local stems main exp maxexp expsh maxexpsh birth
	}
	else {
		local stems main exp maxexp expsh maxexpsh
	}
	local nspec : word count `stems'

	* One row vector (+ se vector) per estimand; columns index the specs.
	tempname bphi sephi bdn sedn bdg sedg
	matrix `bphi'  = J(1, `nspec', .)
	matrix `sephi' = J(1, `nspec', .)
	matrix `bdn'   = J(1, `nspec', .)
	matrix `sedn'  = J(1, `nspec', .)
	matrix `bdg'   = J(1, `nspec', .)
	matrix `sedg'  = J(1, `nspec', .)

	local j = 0
	foreach s of local stems {
		local ++j
		if "`s'" == "main" local base "grc_`country'_cuu_ca"
		else               local base "grc_`country'_cuu_`s'_ca"

		* phi from the main ster
		estimates use "$output/`base'${vsfx}.ster"
		matrix `bphi'[1,`j']  = _b[phi:_cons]
		matrix `sephi'[1,`j'] = _se[phi:_cons]

		* Delta_never from the _n ster
		estimates use "$output/`base'_n${vsfx}.ster"
		matrix `bdn'[1,`j']  = _b[Delta_never]
		matrix `sedn'[1,`j'] = _se[Delta_never]

		* Delta_avg from the _g ster
		estimates use "$output/`base'_g${vsfx}.ster"
		matrix `bdg'[1,`j']  = _b[Delta_avg]
		matrix `sedg'[1,`j'] = _se[Delta_avg]
	}
	matrix colnames `bphi'  = `stems'
	matrix colnames `sephi' = `stems'
	matrix colnames `bdn'   = `stems'
	matrix colnames `sedn'  = `stems'
	matrix colnames `bdg'   = `stems'
	matrix colnames `sedg'  = `stems'

	* Pretty row labels (labels for absent specs, e.g. birth on TZA, are ignored)
	local cl coeflabels(main = "Main" exp = "+ Experience" maxexp = "+ Max experience" expsh = "+ Experience share" maxexpsh = "+ Max exp. share" birth = "+ Urban birth")

	* One color per group: Main (anchor), the four experience variants, birth.
	local cmain  "16 62 106"
	local cexp   "128 116 168"
	local cbirth "216 128 60"

	* Shared twoway options: force 0 into every panel (also pins the y-axis
	* line to 0 instead of floating next to the data), zero reference line.
	local gopts `cl' grid(none) xscale(range(0)) ///
		xline(0, lwidth(thin) lcolor(%40)) ylabel(, labsize(small)) ///
		xlabel(#6, labsize(small)) legend(off)

	* birth plot-spec: IDN only (no urban-birth cell on disk for TZA)
	local birth_phi ""
	local birth_dn  ""
	local birth_dg  ""
	if "`country'" == "IDN" {
		local birth_phi (matrix(`bphi'), se(`sephi') keep(birth) msymb(S) mcolor("`cbirth'") ciopts(lwidth(thick) lcolor("`cbirth'")))
		local birth_dn  (matrix(`bdn'),  se(`sedn')  keep(birth) msymb(S) mcolor("`cbirth'") ciopts(lwidth(thick) lcolor("`cbirth'")))
		local birth_dg  (matrix(`bdg'),  se(`sedg')  keep(birth) msymb(S) mcolor("`cbirth'") ciopts(lwidth(thick) lcolor("`cbirth'")))
	}

	coefplot ///
		(matrix(`bphi'), se(`sephi') keep(main) msymb(S) mcolor("`cmain'") ciopts(lwidth(thick) lcolor("`cmain'"))) ///
		(matrix(`bphi'), se(`sephi') keep(exp maxexp expsh maxexpsh) msymb(S) mcolor("`cexp'") ciopts(lwidth(thick) lcolor("`cexp'"))) ///
		`birth_phi' ///
		, `gopts' title("{&phi}") saving(robplot_phi_`country', replace)

	coefplot ///
		(matrix(`bdn'), se(`sedn') keep(main) msymb(S) mcolor("`cmain'") ciopts(lwidth(thick) lcolor("`cmain'"))) ///
		(matrix(`bdn'), se(`sedn') keep(exp maxexp expsh maxexpsh) msymb(S) mcolor("`cexp'") ciopts(lwidth(thick) lcolor("`cexp'"))) ///
		`birth_dn' ///
		, `gopts' title("{&Delta}{subscript:never}") saving(robplot_dn_`country', replace)

	coefplot ///
		(matrix(`bdg'), se(`sedg') keep(main) msymb(S) mcolor("`cmain'") ciopts(lwidth(thick) lcolor("`cmain'"))) ///
		(matrix(`bdg'), se(`sedg') keep(exp maxexp expsh maxexpsh) msymb(S) mcolor("`cexp'") ciopts(lwidth(thick) lcolor("`cexp'"))) ///
		`birth_dg' ///
		, `gopts' title("Average {&Delta}") saving(robplot_dg_`country', replace)

	graph combine robplot_phi_`country'.gph robplot_dn_`country'.gph ///
		robplot_dg_`country'.gph, row(1) xsize(19) ysize(6)
	graph export "$output/figures/robustness_coefplot_`country'${vsfx}.pdf", replace
	graph export "$output/figures/robustness_coefplot_`country'${vsfx}.png", replace as(png) width(3600)
	if $copyOverleaf == 1 {
		copyOverleaf "$output/figures/robustness_coefplot_`country'${vsfx}.pdf", subdir(figures)
	}
end

* **********************************************************************
* uGRC regressions
* **********************************************************************
capture program drop ugrc_regressions
program define ugrc_regressions
    args country choice depvar balance
    * OLS / FE regressions using reghdfe
    * Audit-2026-04-28 M7: the first reghdfe runs ONLY to define the
    * common sample (smallest-sample col-7-equivalent fixed-effects
    * specification). It is not the result that goes into the table ---
    * it used to be stored under reg7_`country' and was silently
    * overwritten by the trajectory-decomposed regression below, losing
    * the sample-defining regression. Now we run it 'quietly' without
    * eststo, capture e(sample), and apply 'if regression_sample' to
    * EVERY estimated column including col 7, so the uGRC table reports
    * cols 1-7 on a common sample (matching reghdfe_regressions's pattern).
    quietly reghdfe lndepvar choice                                  ///
                $covs_all trend                                      ///
                , vce(cluster pid) absorb(pid)
    gen regression_sample = e(sample)

    eststo reg7_`country': reghdfe lndepvar i.trajectory             ///
                i($switchers).trajectory#i.choice                    ///
                i.unbalanced#i.choice $covs_all trend                ///
                if regression_sample                                 ///
                , vce(cluster pid)
	
	
    eststo reg1_`country': reghdfe lndepvar choice 						///
		if regression_sample,  noabsorb vce(cluster pid)
	eststo reg2_`country': reghdfe lndepvar choice $covs_1 				///
		if regression_sample,  noabsorb vce(cluster pid)
    eststo reg3_`country': reghdfe lndepvar choice $covs_2				///
		if regression_sample,  noabsorb vce(cluster pid)
	eststo reg4_`country': reghdfe lndepvar choice $covs_all	///
		if regression_sample,  noabsorb vce(cluster pid)
    eststo reg5_`country': reghdfe lndepvar choice $covs_all trend		///
		if regression_sample,  noabsorb vce(cluster pid)
    eststo reg6_`country': reghdfe lndepvar choice $covs_all trend 		///
		if regression_sample & switcher, noabsorb vce(cluster pid)
end

* **********************************************************************
* regs to grab initial values for GMM
* **********************************************************************

capture program drop initial_values
program define initial_values, rclass

    * Define local variables for the country and switchers
    syntax varlist(min=1) [if], switchers(numlist) estname(string) balance(string) [print]

		local balance_covars ""
		if "`balance'" == "unb" {
			local balance_covars "`balance_covars' unbalanced unbalanced_choice"
		}
		
    * Run OLS regression
    eststo `estname': reg `varlist' always* switcher_*				///
											, vce(cluster pid) nocons
											
    * Store first trajectory coefficient as a scalar
    scalar mu_1 = 0

    * Loop through the list of switchers and define the scalars for mu and Delta
    foreach s of numlist `switchers' {
        scalar mu_`s'    = _b[switcher_`s']
        scalar Delta_`s' = _b[switcher_`s'_choice]
        scalar kappa     = _b[always]
    }
    
    * Return scalars so they can be accessed outside the program
    return scalar mu_1 = mu_1
    foreach s of numlist `switchers' {
        return scalar mu_`s' = mu_`s'
        return scalar Delta_`s' = Delta_`s'
    }
		
    * Accumulate mu-coeffs for initial values
		foreach s of numlist $switchers {
			local initial "`initial' mu:switcher_`s' mu_`s'"
		}	
    
    * Accumulate Delta-coeffs for initial values
// 		foreach s of numlist $switchers {
// 			local initial "`initial' Delta:Delta_`s' switcher_`s'_choice"
// 		} 
//    Tricky to do with the potentially-changing Delta_base
    
    * Add kappa-coeff for initial values
		local initial "`initial' kappa: kappa"

		return local initial "`initial'"
		
		* If print option is specified, display the scalars in formatted output
    if "`print'" != "" {
        di "mu_1 : " %9.2f scalar(mu_1)
        foreach s of numlist `switchers' {
            di "mu_`s' : " %9.2f scalar(mu_`s')
            di "Delta_`s' : " %9.2f scalar(Delta_`s')
        }
        
        di "Initial local: `initial'"
    }

		* Define base trajectory (default is switcher 2)
		* criterion: trajectory with highest t-stat for Delta estimate 
		* (out of those trajectories with more than 5 individual observations)
		
		* Retrieve panel data structure
    quietly xtdescribe
    scalar T = r(max)
		
		* Initialize macros with default
    local base = 2
    local max_t = -1
		
		* Loop through the switchers and compute t-values
    foreach s of numlist `switchers' {
      scalar t_`s' = _b[switcher_`s'_choice] / _se[switcher_`s'_choice]
        
			* Summarize trajectory for the current switcher
			quietly sum trajectory if trajectory == `s'
			scalar N_`s' = r(N)
			
			* Check if condition N_s / T > 5 is met
			if N_`s' / T > $grc_min_switchers_per_wave {
				* Check if the current t-value is the largest
				if abs(`=scalar(t_`s')') > `max_t' {
					local max_t = abs(`=scalar(t_`s')')
					local base = `s'
				}
			}
    }
		
		* Return the base value in r()
    return local base `base'
end

* **********************************************************************
* initial_values_robust: OLS initial values for run_grc_robust
* **********************************************************************
* Extends initial_values to the Verdier (2020) Section F robust spec.
* Generates vfirst (first-wave cluster index) and vchoice_v dummies
* (vchoice_v = 1{vfirst==v} * choice for v != v_base), then runs the
* same OLS as initial_values but augmented with the v-choice
* interactions so the OLS coefficients on vchoice_v serve as starting
* values for {beta_dev:vchoice_v} in run_grc_robust's GMM.
* NOTE: drops observations with missing vfirst. Re-entering run_grc
* after this program will see a trimmed sample.
capture program drop initial_values_robust
program define initial_values_robust, rclass

    syntax varlist(min=1) [if], switchers(numlist) estname(string) ///
        balance(string) vindex(varname) [print]

    * ----------------------------------------------------------------
    * Build first-wave cluster variable + drop missing
    * ----------------------------------------------------------------
    gen_vfirst, vname(`vindex') genname(vfirst)

    qui count if missing(vfirst)
    if r(N) > 0 {
        di as text "initial_values_robust: dropping " r(N) ///
            " obs with missing vfirst"
    }
    qui drop if missing(vfirst)

    * Enumerate distinct clusters (sorted ascending by levelsof)
    qui levelsof vfirst, local(vvals)
    local V : word count `vvals'
    local v_base : word 1 of `vvals'
    di as text "initial_values_robust: |V| = `V' clusters, baseline v = `v_base'"

    * ----------------------------------------------------------------
    * Generate vchoice_v = I(vfirst==v) * choice for v != v_base
    * ----------------------------------------------------------------
    local vchoice_list ""
    foreach v of local vvals {
        if `v' != `v_base' {
            capture drop vchoice_`v'
            qui gen vchoice_`v' = (vfirst == `v') * choice
            local vchoice_list "`vchoice_list' vchoice_`v'"
        }
    }

    * ----------------------------------------------------------------
    * OLS (same as initial_values, augmented with vchoice_*)
    * ----------------------------------------------------------------
    eststo `estname': reg `varlist' always* switcher_* `vchoice_list' ///
        , vce(cluster pid) nocons

    * Extract mu, Delta, kappa exactly as in initial_values
    scalar mu_1 = 0
    foreach s of numlist `switchers' {
        scalar mu_`s'    = _b[switcher_`s']
        scalar Delta_`s' = _b[switcher_`s'_choice]
        scalar kappa     = _b[always]
    }
    return scalar mu_1 = mu_1
    foreach s of numlist `switchers' {
        return scalar mu_`s' = mu_`s'
        return scalar Delta_`s' = Delta_`s'
    }

    * ----------------------------------------------------------------
    * Build `initial' local: mu, kappa (mirrors initial_values exactly)
    * ----------------------------------------------------------------
    local initial ""
    foreach s of numlist $switchers {
        local initial "`initial' mu:switcher_`s' mu_`s'"
    }
    local initial "`initial' kappa: kappa"

    * Append beta_dev initial values, one per non-baseline cluster.
    * Guard against unidentified coefficients (e.g., collinear vchoice_v
    * with zero within-cluster variation in choice): default to 0.
    foreach v of local vvals {
        if `v' != `v_base' {
            capture scalar beta_dev_`v' = _b[vchoice_`v']
            if _rc != 0 {
                di as text "  beta_dev_`v' unidentified in OLS; using 0"
                scalar beta_dev_`v' = 0
            }
            if missing(scalar(beta_dev_`v')) {
                di as text "  beta_dev_`v' missing in OLS; using 0"
                scalar beta_dev_`v' = 0
            }
            local initial "`initial' beta_dev:vchoice_`v' beta_dev_`v'"
        }
    }

    return local initial "`initial'"
    return local vchoice_list "`vchoice_list'"
    return local vvals "`vvals'"
    return local v_base `v_base'
    return scalar V = `V'

    if "`print'" != "" {
        di "Initial local: `initial'"
    }

    * ----------------------------------------------------------------
    * Base trajectory selection (identical to initial_values)
    * ----------------------------------------------------------------
    quietly xtdescribe
    scalar T = r(max)
    local base = 2
    local max_t = -1
    foreach s of numlist `switchers' {
        scalar t_`s' = _b[switcher_`s'_choice] / _se[switcher_`s'_choice]
        quietly sum trajectory if trajectory == `s'
        scalar N_`s' = r(N)
        if N_`s' / T > $grc_min_switchers_per_wave {
            if abs(`=scalar(t_`s')') > `max_t' {
                local max_t = abs(`=scalar(t_`s')')
                local base = `s'
            }
        }
    }
    return local base `base'
end

* **********************************************************************
* Define switcher parameters
* **********************************************************************

capture program drop define_switcherpars
program define define_switcherpars, rclass

    * Syntax for accepting the list of switchers and the base trajectory
    syntax , switchers(numlist) base(numlist)

    * Initialize the local macro for the switcher parameters
    local switcherpars "0"

		* Loop over the switchers and build the local switcherpars
		foreach s of numlist `switchers' {
			if `s' != `base' {
				local switcherpars 																	///
        "`switcherpars' + ({mu:switcher_`s'} - {mu:switcher_`base'})*(switcher_`s'#1.choice)"
			}
    }
		* Store the switcherpars in r() for external access
		return local switcherpars "`switcherpars'"
	
end

* **********************************************************************
* GMM regression
* **********************************************************************
capture program drop run_grc
program define run_grc

    * Syntax to accept user-specified covariates and estname
    syntax , estname(string) switchers(numlist) base(numlist)  balance(string) [covars(varlist) iterate(numlist) initial(string) phistart(real -0.1)]

    * Resume-on-interrupt. If ${skip_if_exists} == "1" and the last-written
    * ster for this estname exists (the _g subgroup, saved at the end of
    * run_grc), skip the whole block. Lets an interrupted master pipeline
    * pick up from the next missing cell on relaunch. To force a fresh run,
    * either delete `$output/`estname'*.ster` or unset ${skip_if_exists}.
    if "${skip_if_exists}" == "1" {
        capture confirm file "$output/`estname'_g${vsfx}.ster"
        if _rc == 0 {
            di as text "run_grc: SKIP `estname' (`estname'_g${vsfx}.ster present)"
            exit
        }
    }

    * Construct the covariates string for the regression and instruments
		if "`balance'" == "unb" {
			local covarlist "`covars' unbalanced unbalanced_choice"
		}
		else {
			capture drop covar_cons
			gen covar_cons = 0
			local covarlist "`covars' covar_cons"
		}

		* Initialize a local to hold switcher variables
		local switcher_traj

		* Loop through switchers and add them to local
		foreach s of numlist `switchers' {
			local switcher_traj "`switcher_traj' switcher_`s'"
		}

		* Build switcherpars internally — guarantees same base everywhere
		define_switcherpars, switchers(`switchers') base(`base')
		local switcherpars `r(switcherpars)'
		di as text "run_grc: base trajectory = `base'"
		di as text "run_grc: phi initial value = `phistart'"

    * M9: time the GMM fit + post-estimation. Each call uses a fresh
    * sequential timer slot (1, 2, 3, ...) so all per-fit times survive
    * for `timer list` at the end of the session, in addition to being
    * stashed into the ster as a custom scalar `runtime` via `estadd`.
    *
    * Stata's `timer` only accepts slot numbers 1-100. Pipelines with
    * more than 100 fits in one Stata session (e.g. full Tier 3 has
    * ~200 fits) hit `r(198) invalid syntax` at slot 101. Wrap the
    * counter back to 1 after 100. Each fit's runtime is read via
    * r(t<n>) and saved to the ster via estadd BEFORE the next fit
    * touches the slot, so reuse is safe. The session-end `timer list`
    * loses pre-wrap timings but the per-fit ster scalars retain them.
    if "${grc_timer_slot}" == "" global grc_timer_slot 0
    global grc_timer_slot = ${grc_timer_slot} + 1
    if ${grc_timer_slot} > 100 global grc_timer_slot 1
    local _tslot = ${grc_timer_slot}
    timer clear `_tslot'
    timer on `_tslot'

    * Run the GMM estimation
    eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}  			///
									- {Delta_base}*choice  																///
									- {phi=`phistart'}*(`switcherpars')		 										///
									- ({kappa}+{phi}*({kappa} 										        ///
									- {mu: switcher_`base'}))*(always#1.choice)           ///
									- {xb: `covarlist'})  																///
									, instruments(  																			///
									`covarlist'  																					///
									never `switcher_traj' choice 													///
									always_choice switcher_*_choice, nocons								///
									) 																										///
                      vce(cluster pid) 																	///
											from(`initial') 																	///
											iterate(`iterate')
      
      * Joint test for mus.
      * Wrapped in capture-noisily so small subsamples (e.g. CHN hukou
      * splits) where the mu equality test is rank-deficient don't
      * crash run_grc; the joint_chi2/joint_p scalars are simply not
      * stored when the test fails. Audit-2026-04-30 (run_grc_hukou
      * merge: hukou cells previously skipped this block entirely).
	  capture noisily {
	      local mu_test ""
	      local s0 : word 1 of $switchers
	      local mu_test "[mu]switcher_`s0'"
	      foreach s of numlist $switchers {
		      if `s' != `s0'{
			      local mu_test "`mu_test' = [mu]switcher_`s'"
		      }
	      }
	      test `mu_test'
	      estadd scalar joint_chi2 = r(chi2), replace   : `estname'
	      estadd scalar joint_p    = r(p),    replace   : `estname'
	  }
	  if _rc != 0 {
	      di as text "run_grc: joint mu test failed for `estname' (rc=" _rc ")"
	      di as text "         joint_chi2 / joint_p NOT stored on main ster"
	  }
	  
	  * Add J-stat estimates from Hansen's J-test  
      estat overid 
      estadd sca Jstat    = r(J)      , replace   : `estname' 
      estadd sca Jdf      = r(J_df)   , replace   : `estname'  
      estadd sca Jpval    = r(J_p)    , replace   : `estname'  
	  local converged_str = cond(e(converged)==1, "Y", "N")
	  estadd local converged_str "`converged_str'", replace : `estname'

	  * M9: stop timer; record GMM-fit wall-clock seconds in e(runtime).
	  timer off `_tslot'
	  qui timer list `_tslot'
	  estadd scalar runtime = r(t`_tslot'), replace : `estname'
	  estadd scalar timer_slot = `_tslot', replace : `estname'
	  di as text "run_grc: `estname' fit in " %7.2f r(t`_tslot') " sec  (timer slot `_tslot')"

	  * Save results
      estimates save "$dir/output/`estname'${vsfx}", replace
      
      * Compute Delta_never
	  estimates restore `estname'   // make sure the results are in memory
	  nlcom (Delta_never: _b[Delta_base:_cons] + (_b[phi:_cons] * ///
            (_b[mu:never] - _b[mu:switcher_`base']))), post
      * Save results
      estimates save "$dir/output/`estname'_n${vsfx}", replace
           
      * Compute Delta_always (average Delta for always-urban)
      estimates restore `estname'   // make sure the results are in memory
      nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] *  ///
            (_b[kappa:_cons] - _b[mu:switcher_`base']))), post           
      * Save results
      estimates save "$dir/output/`estname'_a${vsfx}", replace
      
      * Compute all switcher Deltas.
      * Wrapped in capture-noisily so small subsamples (hukou splits,
      * sparse switcher trajectories) that can't compute every per-
      * trajectory Delta don't crash run_grc; the main / _n / _a / _g
      * sters are saved regardless. If this block fails the _d.ster is
      * simply not written. Audit-2026-04-30 (run_grc_hukou merge:
      * hukou cells previously skipped this entire block).
	  capture noisily {
	      estimates restore `estname'
	      local nlcom_expr ""
	      foreach s of numlist $switchers {
	  	      local nlcom_expr "`nlcom_expr' (Delta_`s': _b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))"
          }
	      nlcom `nlcom_expr', post
	      * Joint test for Deltas
	      local d_test ""
	      local s0 : word 1 of $switchers
	      local d_test "Delta_`s0'"
	      foreach s of numlist $switchers {
		      if `s' != `s0'{
			      local d_test "`d_test' = Delta_`s'"
		      }
	      }
	      test `d_test'
	      estadd scalar joint_chi2 = r(chi2), replace
	      estadd scalar joint_p    = r(p),    replace
          * Save results
          estimates save "$dir/output/`estname'_d${vsfx}", replace
	  }
	  if _rc != 0 {
	      di as text "run_grc: per-trajectory Delta_d block failed for `estname' (rc=" _rc ")"
	      di as text "         _d.ster NOT saved (typical cause: small subsample with empty switchers)"
	  }
	  
	  * Compute Delta_avg (average Delta for all switchers)
	  local first_loop = 1
	  local Delta_avg_nlcom ""
	  foreach s of numlist $switchers {
	  	estimates restore `estname'   // make sure the results are in memory
        * Within-switcher trajectory share: condition on switcher == 1 so
        * num_s sums to 1 across $switchers. The previous form
        *     sum 1.switcher_`s' if e(sample); local num_`s' = r(mean)
        * gave N_s / N_total (an over-all-sample share summing to the
        * switcher fraction), which made Delta_avg = sw_frac * E[Delta | switcher]
        * instead of E[Delta | switcher]. See
        * quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md.
        sum 1.switcher_`s' if e(sample) & switcher == 1
        local num_`s' = r(mean)   // proportion of sample in this trajectory
		if `first_loop' == 0 {
			local Delta_avg_nlcom "`Delta_avg_nlcom' + (`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
		}
		else if `first_loop' == 1 {
			local Delta_avg_nlcom "(`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
			local first_loop = 0
		}
      }
	  estimates restore `estname'   // make sure the results are in memory
	  nlcom (Delta_avg: `Delta_avg_nlcom'), post
      * Save results
      estimates save "$dir/output/`estname'_g${vsfx}", replace

end

* **********************************************************************
* run_grc_with_extra_regressor
* Phase 1b.6: extracts the per-stem GMM logic of files 10/11/12/13/14/15
* (now deleted) into a single program. One call estimates ONE STEM
* (country x spec3 x extra-regressor family) and writes 5 sters per
* stem under fully disambiguated names:
*     grc_<country>_<spec3>_<fam>_{c1,c2,c3,ca}     (main)
*     grc_<country>_<spec3>_<fam>_<col>_n           (never subgroup; via run_grc)
*     grc_<country>_<spec3>_<fam>_<col>_g           (group-avg; via run_grc)
*
* This finally fixes the "preserve prior cross-section ster collisions"
* deferred from M11 (Phase 1a). All 44 stems now coexist on disk.
*
* Args:
*   country(IDN|CHN|TZA)
*   spec3(cuu|cub|iuu|cnu)
*   regressor(varname)        e.g. exp, exp_max, exp_share, exp_max_share, urbanbirth
*   [iterate(integer 100)]
*   [data_path_override(string)]   override resolved dataset path
*
* Internal lookup regressor -> family-name token used in ster filenames:
*   exp           -> exp
*   exp_max       -> maxexp
*   exp_share     -> expsh
*   exp_max_share -> maxexpsh
*   urbanbirth    -> birth
*
* spec3 dispatch (sets choice/depvar/balance for the table label and
* picks the dataset+lndepvar handling that matches the original 10-15
* per-section code):
*   cuu -> choice=urban, depvar=consumption, balance=unb,
*          dataset=<country>_unb.dta,  lndepvar=log(consumption/hhsize_cube)
*   cub -> choice=urban, depvar=consumption, balance=bal,
*          dataset=<country>_bal.dta,  lndepvar=log(consumption/hhsize_cube)
*   iuu -> choice=urban, depvar=income,      balance=unb,
*          dataset=<country>_unb_income.dta, lndepvar already log(income/hhsize_cube)
*          on disk (no replace)
*   cnu -> choice=nonag, depvar=consumption, balance=unb,
*          dataset=<country>_unb_nonag.dta,  lndepvar=log(consumption/hhsize_cube)
*
* data_path_override is for the one cell from file 15 sec 4 where the
* original code opened the urban dataset (IDN_unb.dta) but labeled the
* output as cnu in the filename. Faithful replication preserves that
* historical behavior; pass data_path_override("...IDN_unb.dta") when
* needed.
* **********************************************************************
capture program drop run_grc_with_extra_regressor
program define run_grc_with_extra_regressor
    syntax , country(string) spec3(string) regressor(name)            ///
        [ iterate(integer 100) data_path_override(string) ]

    * --- 1. Family token lookup ---
    local fam ""
    if "`regressor'" == "exp"           local fam "exp"
    if "`regressor'" == "exp_max"       local fam "maxexp"
    if "`regressor'" == "exp_share"     local fam "expsh"
    if "`regressor'" == "exp_max_share" local fam "maxexpsh"
    if "`regressor'" == "urbanbirth"    local fam "birth"
    if "`fam'" == "" {
        di as error "run_grc_with_extra_regressor: unknown regressor `regressor'"
        exit 198
    }

    * --- 2. Spec3 dispatch ---
    local choice  ""
    local depvar  ""
    local balance ""
    if "`spec3'" == "cuu" {
        local choice  urban
        local depvar  consumption
        local balance unb
    }
    else if "`spec3'" == "cub" {
        local choice  urban
        local depvar  consumption
        local balance bal
    }
    else if "`spec3'" == "iuu" {
        local choice  urban
        local depvar  income
        local balance unb
    }
    else if "`spec3'" == "cnu" {
        local choice  nonag
        local depvar  consumption
        local balance unb
    }
    else {
        di as error "run_grc_with_extra_regressor: unknown spec3 `spec3'"
        exit 198
    }

    * --- 3. Resolve dataset path ---
    if "`data_path_override'" != "" {
        local dpath "`data_path_override'"
    }
    else if "`spec3'" == "iuu" {
        local dpath "$dirdata/processed/`country'_`balance'_income.dta"
    }
    else if "`spec3'" == "cnu" {
        local dpath "$dirdata/processed/`country'_`balance'_`choice'.dta"
    }
    else {
        local dpath "$dirdata/processed/`country'_`balance'.dta"
    }

    * --- 4. Open data; build lndepvar (skip for iuu --- already on disk) ---
    use "`dpath'", clear
    if "`spec3'" != "iuu" {
        replace lndepvar = log(`depvar'/hhsize_cube)
    }
    sum ln*

    * --- 5. GMM-side variable construction (uses dataset's `choice' column) ---
    setup_grc_estimation

    * Keep only relevant variables (speeds up estimation). Mirrors the
    * original keepvars from 10-15. The $lnsize global referenced in
    * 10-15 was vestigial scaffolding from David's old OLS code that
    * was never assigned in the current pipeline; removed 2026-04-29.
    keep lndepvar trajectory choice pid `regressor'         ///
         period unbalanced* switcher non_switcher           ///
         female age age2 education_max education_max2 trend ///
         always always_choice never switcher_*

    * --- 6. Period fixed effects ---
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * --- 7. Initial values ---
    initial_values lndepvar,         ///
        switchers($switchers)        ///
        balance(`balance')           ///
        estname(initial_`country')
    local base    "`r(base)'"
    local initial "`r(initial)'"

    * --- 8. Per-fit covariate strings (locals; no global pollution) ---
    local covs1   "`regressor'"
    local covs2   "`regressor' female"
    local covs3   "`regressor' female age2"
    local covsall "`regressor' female age2 education_max education_max2"

    * --- 9. Four fits with progressive covariates ---
    run_grc, estname(grc_`country'_`spec3'_`fam'_c1)               ///
        switchers($switchers) base(`base') initial(`initial')      ///
        balance(`balance')                                          ///
        covars(`periodFE' `covs1')                                  ///
        iterate(`iterate')

    run_grc, estname(grc_`country'_`spec3'_`fam'_c2)               ///
        switchers($switchers) base(`base') initial(`initial')      ///
        balance(`balance')                                          ///
        covars(`periodFE' `covs2')                                  ///
        iterate(`iterate')

    run_grc, estname(grc_`country'_`spec3'_`fam'_c3)               ///
        switchers($switchers) base(`base') initial(`initial')      ///
        balance(`balance')                                          ///
        covars(`periodFE' `covs3')                                  ///
        iterate(`iterate')

    run_grc, estname(grc_`country'_`spec3'_`fam'_ca)               ///
        switchers($switchers) base(`base') initial(`initial')      ///
        balance(`balance')                                          ///
        covars(`periodFE' `covsall')                                ///
        iterate(`iterate')
end

* **********************************************************************
* run_grc_onestep: simple spec with VV's onestep GMM settings
* **********************************************************************
* Identical to run_grc except for winitial(unadjusted, independent) +
* onestep options. Exists so the paper can report a simple-spec
* comparator that is apples-to-apples with run_grc_robust (which uses
* onestep because the cluster-robust two-step weighting matrix is
* rank-deficient when #moments > #vfirst clusters). Also serves as the
* reference for run_grc_robust's degenerate-v (|V|=1) test.
* Hansen's J is not available under onestep, so estat overid is
* wrapped in capture.
capture program drop run_grc_onestep
program define run_grc_onestep

    syntax , estname(string) switchers(numlist) base(numlist) balance(string) [covars(varlist) iterate(numlist) initial(string) phistart(real -0.1)]

    if "`balance'" == "unb" {
        local covarlist "`covars' unbalanced unbalanced_choice"
    }
    else {
        capture drop covar_cons
        gen covar_cons = 0
        local covarlist "`covars' covar_cons"
    }

    local switcher_traj
    foreach s of numlist `switchers' {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }

    define_switcherpars, switchers(`switchers') base(`base')
    local switcherpars `r(switcherpars)'
    di as text "run_grc_onestep: base trajectory = `base'"
    di as text "run_grc_onestep: phi initial value = `phistart'"

    * M9: same sequential-slot timer scheme as run_grc; all slots survive
    * for `timer list` at the end of the session. Wrap at 100 because
    * Stata's timer only accepts slots 1-100; runtime is saved to the
    * ster before the slot is reused, so wrapping is safe. (See run_grc
    * for the full rationale.)
    if "${grc_timer_slot}" == "" global grc_timer_slot 0
    global grc_timer_slot = ${grc_timer_slot} + 1
    if ${grc_timer_slot} > 100 global grc_timer_slot 1
    local _tslot = ${grc_timer_slot}
    timer clear `_tslot'
    timer on `_tslot'

    eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}                    ///
                            - {Delta_base}*choice                                    ///
                            - {phi=`phistart'}*(`switcherpars')                      ///
                            - ({kappa}+{phi}*({kappa}                                ///
                            - {mu: switcher_`base'}))*(always#1.choice)              ///
                            - {xb: `covarlist'})                                     ///
                           , instruments(                                            ///
                            `covarlist'                                              ///
                            never `switcher_traj' choice                             ///
                            always_choice switcher_*_choice, nocons                  ///
                           )                                                         ///
                             vce(cluster pid)                                        ///
                             winitial(unadjusted, independent)                       ///
                             onestep                                                 ///
                             from(`initial')                                         ///
                             iterate(`iterate')

    local mu_test ""
    local s0 : word 1 of $switchers
    local mu_test "[mu]switcher_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local mu_test "`mu_test' = [mu]switcher_`s'"
        }
    }
    test `mu_test'
    estadd scalar joint_chi2 = r(chi2), replace : `estname'
    estadd scalar joint_p    = r(p),    replace : `estname'

    capture estat overid
    if _rc == 0 {
        estadd sca Jstat = r(J),    replace : `estname'
        estadd sca Jdf   = r(J_df), replace : `estname'
        estadd sca Jpval = r(J_p),  replace : `estname'
    }
    else {
        di as text "run_grc_onestep: estat overid unavailable (onestep GMM) -- Jstat not computed"
    }
    local converged_str = cond(e(converged)==1, "Y", "N")
    estadd local converged_str "`converged_str'", replace : `estname'

    estimates save "$dir/output/`estname'${vsfx}", replace

    estimates restore `estname'
    nlcom (Delta_never: _b[Delta_base:_cons] + (_b[phi:_cons] * ///
            (_b[mu:never] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_n${vsfx}", replace

    estimates restore `estname'
    nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] *  ///
            (_b[kappa:_cons] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_a${vsfx}", replace

    estimates restore `estname'
    local nlcom_expr ""
    foreach s of numlist $switchers {
        local nlcom_expr "`nlcom_expr' (Delta_`s': _b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))"
    }
    nlcom `nlcom_expr', post
    local d_test ""
    local s0 : word 1 of $switchers
    local d_test "Delta_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local d_test "`d_test' = Delta_`s'"
        }
    }
    test `d_test'
    estadd scalar joint_chi2 = r(chi2), replace
    estadd scalar joint_p    = r(p),    replace
    estimates save "$dir/output/`estname'_d${vsfx}", replace

    local first_loop = 1
    local Delta_avg_nlcom ""
    foreach s of numlist $switchers {
        estimates restore `estname'
        * Within-switcher trajectory share: condition on switcher == 1 so
        * num_s sums to 1 across $switchers. The previous form
        *     sum 1.switcher_`s' if e(sample); local num_`s' = r(mean)
        * gave N_s / N_total (an over-all-sample share summing to the
        * switcher fraction), which made Delta_avg = sw_frac * E[Delta | switcher]
        * instead of E[Delta | switcher]. See
        * quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md.
        sum 1.switcher_`s' if e(sample) & switcher == 1
        local num_`s' = r(mean)
        if `first_loop' == 0 {
            local Delta_avg_nlcom "`Delta_avg_nlcom' + (`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
        }
        else if `first_loop' == 1 {
            local Delta_avg_nlcom "(`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
            local first_loop = 0
        }
    }
    estimates restore `estname'
    nlcom (Delta_avg: `Delta_avg_nlcom'), post
    estimates save "$dir/output/`estname'_g${vsfx}", replace

end

* **********************************************************************
* run_grc_hukou (DELETED 2026-04-30)
* **********************************************************************
* run_grc_hukou was a near-duplicate of run_grc, missing only:
*   1. The skip_if_exists guard.
*   2. The joint test for mu coefficients.
*   3. The per-trajectory Delta_d block (and the _d.ster).
* The gmm equation, post-estimation Delta_never/Delta_always/Delta_avg
* logic, and timer scheme were byte-identical to run_grc.
*
* Folded into run_grc on 2026-04-30 by wrapping the per-trajectory
* Delta_d block and the joint mu test in capture-noisily so small
* hukou subsamples (the original reason for the separate program)
* dont crash run_grc; the _d.ster simply isnt written when the block
* fails. 7_GrRC_hukou.do callers now invoke run_grc directly.
* **********************************************************************

* **********************************************************************
* run_grc_robust: Verdier (2020) Section F robust extrapolation
* **********************************************************************
* Implements the within-v demeaning estimator as a single-step
* extension of run_grc: adds |V|-1 cluster dummies x choice to the
* GMM equation so Delta_{d_0} becomes cluster-specific (beta(v)).
* See quality_reports/reviews/2026-04-23_robust-grc-derivation.md for the full
* derivation. Standard errors switch from vce(cluster pid) to
* vce(cluster vfirst). The always-urban term uses scalar kappa
* (cross-origin extrapolation) per memo section 6.
* P1 aggregations: _never uses the cluster-share-weighted aggregate
* from memo section 7 (weights = never-urban counts per support
* cluster); _delta, _avg, _always use baseline-cluster beta
* (= Delta_base) as a placeholder -- proper cross-cluster aggregation
* deferred to P2.
capture program drop run_grc_robust
program define run_grc_robust

    syntax , estname(string) switchers(numlist) base(numlist) balance(string) ///
        vindex(varname) ///
        [covars(varlist) iterate(numlist) initial(string) phistart(real -0.1)]

    * ----------------------------------------------------------------
    * Build vfirst + vchoice_* (idempotent; initial_values_robust may
    * have already built them and dropped missing-vfirst obs)
    * ----------------------------------------------------------------
    gen_vfirst, vname(`vindex') genname(vfirst)
    qui count if missing(vfirst)
    if r(N) > 0 {
        di as text "run_grc_robust: dropping " r(N) " obs with missing vfirst"
    }
    qui drop if missing(vfirst)

    qui levelsof vfirst, local(vvals)
    local V : word count `vvals'
    local v_base : word 1 of `vvals'

    local vchoice_list ""
    foreach v of local vvals {
        if `v' != `v_base' {
            capture drop vchoice_`v'
            qui gen vchoice_`v' = (vfirst == `v') * choice
            local vchoice_list "`vchoice_list' vchoice_`v'"
        }
    }

    * ----------------------------------------------------------------
    * Cluster-support diagnostics (per plan section 3.1 step 2)
    * ----------------------------------------------------------------
    tempvar first_obs n_sw_v n_nev_v n_tot_v
    qui bysort pid (year): gen byte `first_obs' = (_n == 1)
    qui bysort vfirst: egen `n_sw_v'  = sum(switcher * `first_obs')
    qui bysort vfirst: egen `n_nev_v' = sum(never    * `first_obs')
    qui bysort vfirst: egen `n_tot_v' = sum(`first_obs')

    di as txt _newline(1) "run_grc_robust: cluster-support diagnostics"
    di as txt "  |V| = `V' clusters (baseline v = `v_base')"

    preserve
        qui duplicates drop vfirst, force
        qui sum `n_sw_v', detail
        di as txt "  Switchers per cluster: mean=" %6.2f r(mean) ///
            ", p50=" %6.0f r(p50) ", max=" %6.0f r(max)
        qui count if `n_sw_v' >= 10
        local nclust_ge10 = r(N)
        qui count if `n_sw_v' > 0 & `n_nev_v' > 0
        local V_supp = r(N)
        qui sum `n_nev_v' if `n_sw_v' > 0 & `n_nev_v' > 0
        local nev_supp = r(sum)
        qui sum `n_nev_v'
        local nev_tot = r(sum)
    restore

    di as txt "  Clusters with >=10 switchers: `nclust_ge10' / `V'"
    di as txt "  Clusters with both sw & never: `V_supp' / `V'"
    if `nev_tot' > 0 {
        di as txt "  Always-rural support share: " ///
            %5.1f (100 * `nev_supp' / `nev_tot') "%"
    }

    * ----------------------------------------------------------------
    * Build covarlist and switcher_traj (same as run_grc)
    * ----------------------------------------------------------------
    if "`balance'" == "unb" {
        local covarlist "`covars' unbalanced unbalanced_choice"
    }
    else {
        capture drop covar_cons
        gen covar_cons = 0
        local covarlist "`covars' covar_cons"
    }

    local switcher_traj
    foreach s of numlist `switchers' {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }

    define_switcherpars, switchers(`switchers') base(`base')
    local switcherpars `r(switcherpars)'
    di as text "run_grc_robust: base trajectory = `base'"
    di as text "run_grc_robust: |V|-1 cluster deviations = " ///
        `: word count `vchoice_list''

    * ----------------------------------------------------------------
    * GMM estimation
    * ----------------------------------------------------------------
    * Degenerate V=1 branch: vchoice_list empty, equation reduces
    * exactly to run_grc_onestep. Used by the P1 degenerate-v test
    * (derivation memo section 8). vce switches to cluster pid
    * because vce(cluster vfirst) with 1 cluster yields undefined
    * cluster-robust variance (division by G-1=0). Uses the same
    * onestep + winitial settings as the non-degenerate branch so the
    * comparison to run_grc_onestep is apples-to-apples.
    di as text "run_grc_robust: phi initial value = `phistart'"
    if "`vchoice_list'" == "" {
        di as text "run_grc_robust: degenerate |V|=1 branch (no beta_dev parameters)"
        di as text "run_grc_robust: switching to vce(cluster pid) for |V|=1"
        eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}                ///
                                - {Delta_base}*choice                                ///
                                - {phi=`phistart'}*(`switcherpars')                  ///
                                - ({kappa}+{phi}*({kappa}                            ///
                                - {mu: switcher_`base'}))*(always#1.choice)          ///
                                - {xb: `covarlist'})                                 ///
                               , instruments(                                        ///
                                `covarlist'                                          ///
                                never `switcher_traj' choice                         ///
                                always_choice switcher_*_choice, nocons              ///
                               )                                                     ///
                                 vce(cluster pid)                                    ///
                                 winitial(unadjusted, independent)                   ///
                                 onestep                                             ///
                                 from(`initial')                                     ///
                                 iterate(`iterate')
    }
    else {
        * Q8 (2026-04-23): adopt VV robust.do's GMM settings --
        * winitial(unadjusted, independent) onestep. VV does one-step
        * GMM with independence-weighted initial matrix; we match so
        * the second-step cluster-robust weighting matrix (which is
        * rank-deficient when #moments > #clusters, typical here --
        * 47 moments vs 26 TZA clusters) is never computed. This
        * resolves the non-convergence + singular-SE issues observed
        * under Stata default two-step GMM. Inference via
        * vce(cluster vfirst) still uses the cluster-robust formula.
        eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}                ///
                                - {Delta_base}*choice                                ///
                                - {beta_dev: `vchoice_list'}                         ///
                                - {phi=`phistart'}*(`switcherpars')                  ///
                                - ({kappa}+{phi}*({kappa}                            ///
                                - {mu: switcher_`base'}))*(always#1.choice)          ///
                                - {xb: `covarlist'})                                 ///
                               , instruments(                                        ///
                                `covarlist'                                          ///
                                never `switcher_traj' choice `vchoice_list'          ///
                                always_choice switcher_*_choice, nocons              ///
                               )                                                     ///
                                 vce(cluster vfirst)                                 ///
                                 winitial(unadjusted, independent)                   ///
                                 onestep                                             ///
                                 from(`initial')                                     ///
                                 iterate(`iterate')
    }

    * ----------------------------------------------------------------
    * Joint mu test + Hansen J (same as run_grc)
    * ----------------------------------------------------------------
    local mu_test ""
    local s0 : word 1 of $switchers
    local mu_test "[mu]switcher_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local mu_test "`mu_test' = [mu]switcher_`s'"
        }
    }
    test `mu_test'
    estadd scalar joint_chi2 = r(chi2), replace : `estname'
    estadd scalar joint_p    = r(p),    replace : `estname'

    * Hansen's J: only available under twostep GMM. The non-degenerate
    * branch uses onestep (Q8 decision, matches VV), so estat overid
    * would error; capture and skip gracefully. Do-file must not abort
    * before log close / exit, STATA clear (avoids the Windows batch
    * "Stata finished" popup).
    capture estat overid
    if _rc == 0 {
        estadd sca Jstat = r(J),    replace : `estname'
        estadd sca Jdf   = r(J_df), replace : `estname'
        estadd sca Jpval = r(J_p),  replace : `estname'
    }
    else {
        di as text "run_grc_robust: estat overid unavailable (onestep GMM) -- Jstat not computed"
    }
    local converged_str = cond(e(converged)==1, "Y", "N")
    estadd local converged_str "`converged_str'", replace : `estname'

    * Cluster diagnostics stored on the estimate for table builders
    estadd scalar V_clusters = `V',           replace : `estname'
    estadd scalar V_ge10sw   = `nclust_ge10', replace : `estname'
    estadd scalar V_supp     = `V_supp',      replace : `estname'

    * Save main .ster
    estimates save "$dir/output/`estname'${vsfx}", replace

    * ----------------------------------------------------------------
    * Delta_never: cluster-share-weighted aggregate over V_supp
    *   Delta_never = Delta_base + sum_{v != v_base, v in V_supp} w_v * beta_dev_v
    *                            + phi * (mu:never - mu:switcher_base)
    *   w_v = n^N_v / sum_{v' in V_supp} n^N_{v'}
    * (Delta_base absorbs the baseline-cluster weight since weights sum to 1
    *  and beta_dev_{v_base} is 0 by the drop-a-dummy convention.)
    * ----------------------------------------------------------------
    estimates restore `estname'

    * Recompute support + per-cluster never counts (vchoice_list-indexed only)
    preserve
        qui duplicates drop vfirst, force
        qui keep if `n_sw_v' > 0 & `n_nev_v' > 0
        qui sum `n_nev_v'
        local nev_supp_sum = r(sum)

        * Build weighted sum of beta_dev terms
        local beta_agg_expr "_b[Delta_base:_cons]"
        if `nev_supp_sum' > 0 & "`vchoice_list'" != "" {
            forvalues i = 1/`=_N' {
                local v_i = vfirst[`i']
                local n_nev_i = `n_nev_v'[`i']
                if `v_i' != `v_base' {
                    local w_i = `n_nev_i' / `nev_supp_sum'
                    local beta_agg_expr "`beta_agg_expr' + `w_i' * _b[beta_dev:vchoice_`v_i']"
                }
            }
        }
    restore

    di as text "run_grc_robust: Delta_never aggregate expression:"
    di as text "  `beta_agg_expr' + phi * (mu_never - mu_base)"

    nlcom (Delta_never: `beta_agg_expr' + _b[phi:_cons] * ///
            (_b[mu:never] - _b[mu:switcher_`base'])), post
    estadd scalar V_never_supp = `V_supp', replace
    estimates save "$dir/output/`estname'_n${vsfx}", replace

    * ----------------------------------------------------------------
    * Delta_always (baseline-cluster beta; proper aggregation in P2)
    * ----------------------------------------------------------------
    estimates restore `estname'
    nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] * ///
            (_b[kappa:_cons] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_a${vsfx}", replace

    * ----------------------------------------------------------------
    * Per-switcher Deltas (baseline-cluster beta) + joint test
    * ----------------------------------------------------------------
    estimates restore `estname'
    local nlcom_expr ""
    foreach s of numlist $switchers {
        local nlcom_expr "`nlcom_expr' (Delta_`s': _b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))"
    }
    nlcom `nlcom_expr', post

    local d_test ""
    local s0 : word 1 of $switchers
    local d_test "Delta_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local d_test "`d_test' = Delta_`s'"
        }
    }
    test `d_test'
    estadd scalar joint_chi2 = r(chi2), replace
    estadd scalar joint_p    = r(p),    replace
    estimates save "$dir/output/`estname'_d${vsfx}", replace

    * ----------------------------------------------------------------
    * Delta_avg: trajectory-share-weighted average across switchers
    * (baseline-cluster beta; mirror run_grc structure)
    * ----------------------------------------------------------------
    local first_loop = 1
    local Delta_avg_nlcom ""
    foreach s of numlist $switchers {
        estimates restore `estname'
        * Within-switcher trajectory share: condition on switcher == 1 so
        * num_s sums to 1 across $switchers. The previous form
        *     sum 1.switcher_`s' if e(sample); local num_`s' = r(mean)
        * gave N_s / N_total (an over-all-sample share summing to the
        * switcher fraction), which made Delta_avg = sw_frac * E[Delta | switcher]
        * instead of E[Delta | switcher]. See
        * quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md.
        sum 1.switcher_`s' if e(sample) & switcher == 1
        local num_`s' = r(mean)
        if `first_loop' == 0 {
            local Delta_avg_nlcom "`Delta_avg_nlcom' + (`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
        }
        else if `first_loop' == 1 {
            local Delta_avg_nlcom "(`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
            local first_loop = 0
        }
    }
    estimates restore `estname'
    nlcom (Delta_avg: `Delta_avg_nlcom'), post
    estimates save "$dir/output/`estname'_g${vsfx}", replace

end

* **********************************************************************
* run_grc_robust_vv: VV-style robust extrapolation via cluster-demeaned
*                    instruments (no cluster-FE parameters)
* **********************************************************************
* Ports the core identification idea of Verdier (2020) Online Appendix
* Section F / Table1/Code/robust.do to CKT's trajectory-pooled GRC.
*
* Key difference vs run_grc_robust (single-step cluster-dummy version):
*   - run_grc_robust adds |V|-1 cluster*choice interactions as free
*     parameters (beta_dev_v). Asymptotically equivalent to VV's
*     approach, but in finite sample with few clusters the extra |V|-1
*     parameters make the GMM objective nearly flat in phi, giving
*     multiple local minima (confirmed on TZA; hung on CHN).
*   - run_grc_robust_vv keeps CKT's original parameters (phi, mu_d,
*     Delta_base, kappa, xb gammas) -- no cluster FEs -- and instead
*     replaces the switcher_s_choice instruments with their within-
*     cluster-demeaned residuals (regressed on i.vfirst among workers
*     in trajectory s). The within-cluster variation in treatment
*     identifies phi robustly to cluster-level confounders in the
*     outcome, matching VV's Prop. F identification assumption.
*
* This mirrors VV's Table1/Code/robust.do: he demeans hybrid_per on
* i.vil among switchers (line 12), uses the residual as the optimal
* instrument (line 14), and fits GMM with vce(cluster vil), winitial
* unadjusted independent, onestep (line 206). We follow the same
* pattern but adapted to CKT's trajectory structure.
*
* Aggregations for _never etc. follow VV Eq. F.3 conceptually -- for
* P1 we defer the full cluster-share-weighted aggregator to P2 and use
* the simple-spec extrapolation with VV-style phi.
capture program drop run_grc_robust_vv
program define run_grc_robust_vv

    * ============================================================
    * Purpose:  GRC GMM with Verdier (2020 JAE) cluster-residualized
    *           switcher instruments and SEs clustered at vfirst.
    *           Used by 17_verdier_robust.do for the paper's
    *           "Allowing location-specific trajectory intercepts"
    *           subsection.
    *
    * Key differences from run_grc (audit memo A1-A10, C1-C8):
    *   - Switcher instruments swd_switcher_*_choice are residuals
    *     from regressing switcher_s_choice on i.vfirst within
    *     trajectory s (first stage below).
    *   - No always-urban instrument: always_choice is a constant
    *     among always==1 workers, so the demeaned version would
    *     be identically zero (audit C1, smoke-test verified).
    *   - vce(cluster vfirst), winitial(unadjusted, independent).
    *   - Default: onestep GMM (matching VV's setting).
    *
    * SIDE EFFECT: drops observations with missing vfirst from the
    * loaded data. The drop persists across calls within the same
    * `use'. Driver `17_verdier_robust.do' reloads per country, so
    * cross-country contamination is avoided. Reload before unrelated
    * estimation if reusing the program elsewhere (audit C2).
    *
    * Output (.ster files in $dir/output):
    *   <estname>          -- main GMM fit
    *   <estname>_never    -- nlcom Delta_never
    *   <estname>_always   -- nlcom Delta_always
    *   <estname>_delta    -- nlcom per-switcher Delta + joint test
    *   <estname>_avg      -- nlcom Delta_avg
    *
    * Full audit at:
    *   quality_reports/reviews/2026-04-29_run-grc-robust-vv-audit.md
    * ============================================================

    syntax , estname(string) switchers(numlist) base(numlist) balance(string) ///
        vindex(varname) ///
        [covars(varlist) iterate(numlist) initial(string) phistart(real -0.1) ///
         ONEstep TWOstep]

    * ----------------------------------------------------------------
    * Resume-on-interrupt. If ${skip_if_exists} == "1" and the
    * last-written .ster for this estname exists (the _g subgroup,
    * saved at the very end of run_grc_robust_vv), skip the whole block.
    * Lets an interrupted master pipeline pick up from the next missing
    * cell on relaunch. To force a fresh run, either delete
    * $output/`estname'*.ster or unset ${skip_if_exists}.
    * Pattern ported from grc-pipeline-refactor branch's run_grc.
    * ----------------------------------------------------------------
    if "${skip_if_exists}" == "1" {
        capture confirm file "$dir/output/`estname'_g${vsfx}.ster"
        if _rc == 0 {
            di as text "run_grc_robust_vv: SKIP `estname' (`estname'_g${vsfx}.ster present)"
            exit
        }
    }

    * ----------------------------------------------------------------
    * Resolve onestep vs twostep (default: onestep, matching VV's setting)
    * ----------------------------------------------------------------
    if "`onestep'" != "" & "`twostep'" != "" {
        di as error "run_grc_robust_vv: cannot specify both onestep and twostep"
        exit 198
    }
    if "`twostep'" != "" {
        local stepopt "twostep"
    }
    else {
        local stepopt "onestep"
    }
    di as text "run_grc_robust_vv: GMM step option = `stepopt'"

    * ----------------------------------------------------------------
    * Build vfirst + drop missing-vfirst obs
    * ----------------------------------------------------------------
    gen_vfirst, vname(`vindex') genname(vfirst)
    qui count
    local n_pre_drop = r(N)
    qui count if missing(vfirst)
    local n_dropped_vfirst = r(N)
    local pct_dropped = cond(`n_pre_drop' > 0, ///
        100*`n_dropped_vfirst'/`n_pre_drop', 0)
    di as text "run_grc_robust_vv: vfirst missing -> dropping " ///
        `n_dropped_vfirst' " of " `n_pre_drop' " obs (" ///
        %5.2f `pct_dropped' "%)"
    qui drop if missing(vfirst)

    qui levelsof vfirst, local(vvals)
    local V : word count `vvals'
    di as text "run_grc_robust_vv: |V| = `V' clusters"

    * ----------------------------------------------------------------
    * VV's first-stage optimal instrument construction:
    * for each switcher trajectory s, demean switcher_s_choice on
    * i.vfirst AMONG workers in trajectory s; residual is the within-
    * cluster treatment variation that identifies phi robustly.
    * Zero-fill for non-trajectory-s workers so the moment is defined
    * over the whole sample (contributes zero from non-switchers).
    * ----------------------------------------------------------------
    local swd_list ""
    foreach s of numlist `switchers' {
        capture drop swd_switcher_`s'_choice

        tempvar tmpy tmpresid
        qui gen `tmpy' = switcher_`s'_choice if switcher_`s' == 1
        qui reg `tmpy' i.vfirst if switcher_`s' == 1
        qui predict `tmpresid' if switcher_`s' == 1, resid

        qui gen swd_switcher_`s'_choice = `tmpresid'
        qui replace swd_switcher_`s'_choice = 0 if missing(swd_switcher_`s'_choice)
        local swd_list "`swd_list' swd_switcher_`s'_choice"
    }

    * Per-trajectory rank diagnostic (audit C7): a (cluster, trajectory)
    * cell with very few workers absorbs almost everything into i.vfirst
    * and produces residuals near zero, leaving residual variance from a
    * smaller effective sample than counts suggest. Print nonzero-residual
    * counts per trajectory so weak first stages are visible in the log.
    foreach s of numlist `switchers' {
        qui count if switcher_`s' == 1
        local n_traj_`s' = r(N)
        qui count if switcher_`s' == 1 & swd_switcher_`s'_choice != 0
        local nz_traj_`s' = r(N)
        di as text "  trajectory `s': nonzero residuals = " ///
            `nz_traj_`s'' " / " `n_traj_`s''
    }

    * No always-urban instrument is constructed.
    * Earlier code residualized always_choice on i.vfirst among workers
    * with always==1 to mirror VV's switcher residualization. But always-
    * urban have choice==1 in every period by construction, so always_choice
    * is identically 1 within that subsample; demeaning a constant on
    * cluster dummies gives residuals identically zero. The resulting
    * instrument added a zero column to the moment system. The smoke test
    * at tests/verify_C1_swd_always.do verified this empirically across
    * all three countries (IDN, TZA, CHN: 0 nonzero values out of 92,738 /
    * 29,864 / 109,535 observations) and showed that dropping the
    * instrument from CHN covs_all onestep changed point estimates and
    * standard errors by zero to machine precision. kappa is identified
    * through the cross-equation restrictions in the moment formula
    * (always # 1.choice term) plus the existing instrument set.
    * See quality_reports/reviews/2026-04-29_run-grc-robust-vv-audit.md
    * (finding C1) for the full audit.

    * ----------------------------------------------------------------
    * Cluster-support diagnostics (brief)
    * ----------------------------------------------------------------
    tempvar first_obs n_sw_v
    qui bysort pid (year): gen byte `first_obs' = (_n == 1)
    qui bysort vfirst: egen `n_sw_v' = sum(switcher * `first_obs')

    preserve
        qui duplicates drop vfirst, force
        qui sum `n_sw_v', detail
        di as txt "run_grc_robust_vv: switchers/cluster mean=" ///
            %6.2f r(mean) " p50=" %6.0f r(p50) " max=" %6.0f r(max)
        qui count if `n_sw_v' >= 10
        local nclust_ge10 = r(N)
    restore
    di as txt "run_grc_robust_vv: clusters >=10 sw = `nclust_ge10' / `V'"

    * ----------------------------------------------------------------
    * Build covarlist + switcher_traj (same as run_grc)
    * ----------------------------------------------------------------
    if "`balance'" == "unb" {
        local covarlist "`covars' unbalanced unbalanced_choice"
    }
    else {
        capture drop covar_cons
        gen covar_cons = 0
        local covarlist "`covars' covar_cons"
    }

    local switcher_traj
    foreach s of numlist `switchers' {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }

    define_switcherpars, switchers(`switchers') base(`base')
    local switcherpars `r(switcherpars)'
    di as text "run_grc_robust_vv: base trajectory = `base'"
    di as text "run_grc_robust_vv: phi initial value = `phistart'"

    * Initial-values option is declared optional; only attach from(...)
    * to the gmm call when the caller actually supplied starting values.
    * Empty from() would otherwise leave the option present but blank.
    local fromopt
    if "`initial'" != "" local fromopt "from(`initial')"

    * ----------------------------------------------------------------
    * GMM: same moment equation as run_grc, BUT instruments
    * swd_switcher_*_choice replace switcher_*_choice. vce(cluster vfirst),
    * winitial unadjusted independent, onestep (VV's settings).
    * Parameter count identical to run_grc -- no beta_dev.
    * No always-urban instrument (the demeaned version would be identically
    * zero; see comment block above and audit memo C1). kappa is identified
    * through the moment equation's always#1.choice term combined with the
    * standard instruments (never, switcher_traj, choice).
    * ----------------------------------------------------------------
    eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}                   ///
                            - {Delta_base}*choice                                   ///
                            - {phi=`phistart'}*(`switcherpars')                     ///
                            - ({kappa}+{phi}*({kappa}                               ///
                            - {mu: switcher_`base'}))*(always#1.choice)             ///
                            - {xb: `covarlist'})                                    ///
                           , instruments(                                           ///
                            `covarlist'                                             ///
                            never `switcher_traj' choice                            ///
                            `swd_list', nocons                                      ///
                           )                                                        ///
                             vce(cluster vfirst)                                    ///
                             winitial(unadjusted, independent)                      ///
                             `stepopt'                                              ///
                             `fromopt'                                              ///
                             quickderivatives nolog                                 ///
                             iterate(`iterate')

    * ----------------------------------------------------------------
    * Post-estimation (joint mu test, Hansen J, convergence flag)
    * ----------------------------------------------------------------
    local mu_test ""
    local s0 : word 1 of $switchers
    local mu_test "[mu]switcher_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local mu_test "`mu_test' = [mu]switcher_`s'"
        }
    }
    test `mu_test'
    estadd scalar joint_chi2 = r(chi2), replace : `estname'
    estadd scalar joint_p    = r(p),    replace : `estname'

    * Note (audit C6): under one-step GMM, Stata's behavior is version-
    * dependent -- some versions return rc != 0, others return rc == 0
    * with r(J) missing. Either path leaves Jstat unset / missing on the
    * ster, which renders as a blank cell in the table -- the desired
    * behavior under onestep. Worth knowing if a future Stata version
    * starts populating these cells with a non-missing value.
    capture estat overid
    if _rc == 0 {
        estadd sca Jstat = r(J),    replace : `estname'
        estadd sca Jdf   = r(J_df), replace : `estname'
        estadd sca Jpval = r(J_p),  replace : `estname'
    }
    else {
        di as text "run_grc_robust_vv: estat overid unavailable (`stepopt' GMM) -- Jstat not computed"
    }
    local converged_str = cond(e(converged)==1, "Y", "N")
    estadd local converged_str "`converged_str'", replace : `estname'
    estadd scalar V_clusters = `V',           replace : `estname'
    estadd scalar V_ge10sw   = `nclust_ge10', replace : `estname'
    estadd scalar n_dropped_vfirst = `n_dropped_vfirst', replace : `estname'

    * ----------------------------------------------------------------
    * Individual-count scalar: e(N_clust) under vce(cluster vfirst) is
    * the location count, NOT the individual count. Compute the true
    * count of unique pids in the GMM's e(sample) and store it as a
    * separate scalar so the table program can show Individuals AND
    * Locations as distinct rows. Audit memo C8.
    * ----------------------------------------------------------------
    tempvar pid_tag
    qui egen `pid_tag' = tag(pid) if e(sample)
    qui count if `pid_tag' == 1
    estadd scalar n_indiv = r(N), replace : `estname'

    estimates save "$dir/output/`estname'${vsfx}", replace

    * ----------------------------------------------------------------
    * Standard nlcoms (Delta_never, Delta_always, per-switcher Delta,
    * Delta_avg). Identical structure to run_grc (phi is now
    * VV-robust; the LCA extrapolation formulas are unchanged).
    * ----------------------------------------------------------------
    estimates restore `estname'
    nlcom (Delta_never: _b[Delta_base:_cons] + (_b[phi:_cons] * ///
            (_b[mu:never] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_n${vsfx}", replace

    estimates restore `estname'
    nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] *  ///
            (_b[kappa:_cons] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_a${vsfx}", replace

    estimates restore `estname'
    local nlcom_expr ""
    foreach s of numlist $switchers {
        local nlcom_expr "`nlcom_expr' (Delta_`s': _b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))"
    }
    nlcom `nlcom_expr', post

    local d_test ""
    local s0 : word 1 of $switchers
    local d_test "Delta_`s0'"
    foreach s of numlist $switchers {
        if `s' != `s0' {
            local d_test "`d_test' = Delta_`s'"
        }
    }
    test `d_test'
    estadd scalar joint_chi2 = r(chi2), replace
    estadd scalar joint_p    = r(p),    replace
    estimates save "$dir/output/`estname'_d${vsfx}", replace

    local first_loop = 1
    local Delta_avg_nlcom ""
    foreach s of numlist $switchers {
        estimates restore `estname'
        * Within-switcher trajectory share: condition on switcher == 1 so
        * num_s sums to 1 across $switchers. The previous form
        *     sum 1.switcher_`s' if e(sample); local num_`s' = r(mean)
        * gave N_s / N_total (an over-all-sample share summing to the
        * switcher fraction), which made Delta_avg = sw_frac * E[Delta | switcher]
        * instead of E[Delta | switcher]. See
        * quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md.
        sum 1.switcher_`s' if e(sample) & switcher == 1
        local num_`s' = r(mean)
        if `first_loop' == 0 {
            local Delta_avg_nlcom "`Delta_avg_nlcom' + (`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
        }
        else if `first_loop' == 1 {
            local Delta_avg_nlcom "(`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
            local first_loop = 0
        }
    }
    estimates restore `estname'
    nlcom (Delta_avg: `Delta_avg_nlcom'), post
    estimates save "$dir/output/`estname'_g${vsfx}", replace

end

* **********************************************************************
* (Deprecated grc_tex_table program removed 2026-04-29. Pre-trend
* variant; not called by any numbered .do file. Use grc_tex_table_trend
* instead. Old definition preserved in git history.)
* **********************************************************************
capture program drop grc_tex_table

* **********************************************************************
* grc_tex_table_trend (Phase 2 / M3-unified)
*
* Builds the standard country-level GRC LaTeX table (3 coefficient rows:
* Delta_never, Delta_avg, phi/extra-regressor) by reading 5 sters per
* covs2 column (main, _n, _g) from $dir/output/.
*
* Phase 1b: produces a SLIM tabular-only output (no \begin{table},
* \caption, \label, or tablenotes). The paper-side macros (\GRCtable /
* \GRCexptable / \GRChukoutable in preamble.tex) wrap the \input with
* the table envelope, caption, label, and notes. Caller's POSTfoot now
* holds ONLY the indicator rows; the program adds \cmidrule prefix and
* \bottomrule\end{tabular} suffix.
*
* Phase 2 / M3 collapse: replaces three former program variants
* (grc_tex_table_trend_hukou, grc_tex_table_trend_exp,
* grc_tex_table_trend_birth) by parameterizing the two axes that
* differed across them:
*   spec      --- when supplied, ster lookup is grc_<country>_<spec>_<c>;
*                 when empty, lookup is grc_<country>_<c> (the former
*                 hukou path, where country_short already encodes the
*                 disambiguator, e.g. CHN_rf).
*   covs2_set --- space-separated list of covs2 column suffixes
*                 (default: "c0 ct c1 c2 ca", the 4_GrRC.do family).
*                 Pass "c1 c2 c3 ca" for the experience/birth family
*                 (was: grc_tex_table_trend_exp, _birth).
* **********************************************************************
capture program drop grc_tex_table_trend
program define grc_tex_table_trend
    syntax , COLumns(integer) FILEname(string asis)            ///
             COUNTRY(string asis) KEEP(string) varlabel(string) ///
             POSTfoot(string asis)                              ///
             COEFLABels(string asis) TEXTdepvar(string asis)    ///
             [SPEC(string) COVS2set(string) SHOWalways INVci]

    if "`covs2set'" == "" {
        local covs2set "ct c1 c2 ca"
    }

    * invci gate: only the main-results tables (main GRC IDN/CHN/TZA plus
    * the two main hukou cells) carry the LCA weak-identification-robust
    * inversion-CI rows. Robustness / extras tables call without invci, so
    * their sters (which have no inversion CI attached) do not emit an empty
    * "95\% inv. CI" label row. When off, the three CI stats() options are
    * empty and the phi bottom block omits the inv_phi_ci95_str row.
    if "`invci'" != "" {
        local ci_never  `"stats(inv_dN_ci95_str, fmt(s) labels("95\% inv. CI"))"'
        local ci_avg    `"stats(inv_davg_ci95_str, fmt(s) labels("95\% inv. CI"))"'
        local ci_always `"stats(inv_dT_ci95_str, fmt(s) labels("95\% inv. CI"))"'
        local ci_bottom `"s(inv_phi_ci95_str N_clust N Jstat Jpval converged_str, label("95\% inv. CI" "Individuals" "Observations" "J-stat" "J-stat (p-value)" "Converged") fmt(s %9.0fc %9.0fc %8.1fc %8.3fc %8.0fc))"'
    }
    else {
        local ci_never  ""
        local ci_avg    ""
        local ci_always ""
        local ci_bottom `"s(N_clust N Jstat Jpval converged_str, label("Individuals" "Observations" "J-stat" "J-stat (p-value)" "Converged") fmt(%9.0fc %9.0fc %8.1fc %8.3fc %8.0fc))"'
    }

    * Build ster path stem and stored-name stem. Diverges based on whether
    * the spec disambiguator is supplied (hukou path leaves it empty).
    if "`spec'" != "" {
        local _stem "grc_`country'_`spec'"
        local _label "`country'/`spec'"
    }
    else {
        local _stem "grc_`country'"
        local _label "`country'"
    }

    // Split the panel names, prehead, and postfoot strings into tokens

    local num_panels `panels'
    local ccc ""
    * Loop to concatenate "c" the number of times specified in `columns'
    forval i = 1/`columns' {
        local ccc "`ccc'c"
    }
    local cmid = `columns' + 1
		local colnumbers ""
		local table_postfoot 	""
		local posthead 			""
    local table_prehead "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
    * Tablenote explaining multi-island CIs. The Delta_always inversion
    * CI splits into two intervals at the singularity phi = -1 in the
    * LCA mapping; the inversion CI strings emit the union form
    * `[$-\infty$, x] $\cup$ [y, $+\infty$]` for those cells, and this
    * note tells readers what that union notation means.
    * The Mobius/multi-island note only applies when the Delta_always row is
    * shown (its inversion CI is the one that renders as a union interval).
    if "`showalways'" != "" {
        local mobius_note "\multicolumn{`cmid'}{p{\linewidth}}{\footnotesize \emph{Note:} Multi-island confidence intervals (one endpoint at $\pm\infty$) reflect the singularity at $\phi=-1$ in the LCA mapping for $\Delta_{\text{always}}$.}"
        local table_postfoot "\cmidrule{2-`cmid'} `postfoot' `mobius_note' \\ \bottomrule \end{tabular}"
    }
    else {
        local table_postfoot "\cmidrule{2-`cmid'} `postfoot' \bottomrule \end{tabular}"
    }

    * Phase 1b.5b: load estimates from disk inside the program, so callers
    * don't need to do `estimates use/store` boilerplate. This means a
    * tables-only driver can re-emit the .tex from existing sters without
    * any other setup.
    * Skip-and-warn if a required ster is missing (e.g. running tables-only
    * on a cell whose regression hasn't completed yet).
    local first_covs : word 1 of `covs2set'
    capture confirm file "$dir/output/`_stem'_`first_covs'${vsfx}.ster"
    if _rc != 0 {
        di as error "grc_tex_table_trend: SKIP `_label' (sters missing on disk)"
        exit
    }
      foreach estname in `covs2set' {
        estimates use "$dir/output/`_stem'_`estname'${vsfx}"
        estimates store `_stem'_`estname'
        estimates use "$dir/output/`_stem'_`estname'_n${vsfx}"
        estimates store `_stem'_`estname'_n
        estimates use "$dir/output/`_stem'_`estname'_g${vsfx}"
        estimates store `_stem'_`estname'_g
        * Only load the always (_a) ster when it will be shown; otherwise a
        * missing _a ster would abort a table that does not report it.
        if "`showalways'" != "" {
            estimates use "$dir/output/`_stem'_`estname'_a${vsfx}"
            estimates store `_stem'_`estname'_a
        }
      }

    * Empty locals to store estimate-name lists for esttab
    local ests_never  = ""
	local ests_avg    = ""
    local ests_always = ""
    local ests        = ""

    * Generate the list of stored estimates for the current panel.
    * After M11, ster filenames and stored-estimate names use the same
    * `grc_<country>_<spec3>_<covs2>{,_n,_a,_d,_g}` shorthand, so no
    * Option-B "long disk / short memory" bridge is needed.
      foreach estname in `covs2set' {
        local ests_never  = "`ests_never' `_stem'_`estname'_n"
        local ests_avg    = "`ests_avg' `_stem'_`estname'_g"
        local ests_always = "`ests_always' `_stem'_`estname'_a"
        local ests        = "`ests' `_stem'_`estname'"
      }

      * Output Delta-never row plus its LCA inversion CI rows (90% and
      * 95%). The CI rows consume pre-formatted bracketed string macros
      * set on each _n ster by attach_inversion_ci.
      esttab `ests_never'                    ///
      using "$output/tables/`filename'${vsfx}.tex", ///
	  se b(%8.3f)                            ///
      fragment booktabs noobs                ///
      collabels("")                          ///
      starlevels(* 0.10 ** 0.05 *** 0.01)    ///
      `ci_never'                             ///
      varwidth(20) 	                         ///
      nolines nomtitles `colnumbers'         ///
      prehead(`table_prehead')               ///
      posthead(`table_posthead')             ///
      coeflabels(Delta_never "$\Delta_{\text{never}}$") ///
      replace substitute(\_ _)

      * Output Delta-average row plus its LCA inversion CI rows.
      esttab `ests_avg'   		             ///
      using "$output/tables/`filename'${vsfx}.tex", ///
	  se b(%8.3f)                            ///
      fragment booktabs noobs                ///
      collabels("")                          ///
      starlevels(* 0.10 ** 0.05 *** 0.01)    ///
      `ci_avg'                               ///
      varwidth(20) 	                         ///
      nolines nomtitles nonum 		         ///
      coeflabels(Delta_avg "$\bar{\Delta}$") ///
      append substitute(\_ _)

      * Output Delta-always row plus its LCA inversion CI rows. The
      * Delta_always inversion CI is the one most likely to render as
      * a multi-island union --- see the M\"obius tablenote in postfoot.
      * Gated off by default: the main-text tables report only never and
      * average. Pass showalways to include it (appendix robustness).
      if "`showalways'" != "" {
      esttab `ests_always'   		         ///
      using "$output/tables/`filename'${vsfx}.tex", ///
	  se b(%8.3f)                            ///
      fragment booktabs noobs                ///
      collabels("")                          ///
      starlevels(* 0.10 ** 0.05 *** 0.01)    ///
      `ci_always'                            ///
      varwidth(20) 	                         ///
      nolines nomtitles nonum 		         ///
      coeflabels(Delta_always "$\Delta_{\text{always}}$") ///
      append substitute(\_ _)
      }

    * Output other estimates plus phi inversion CI rows and existing
    * diagnostics. The phi CI rows ride on the parent (unsuffixed) ster.
      esttab `ests'	                         ///
      using "$output/tables/`filename'${vsfx}.tex", ///
	  se b(%8.3f)                            ///
      keep(`keep')                           ///
      varlabels(`keep' "`varlabel'")         ///
      eqlabels(none)				         ///
      fragment booktabs                      ///
      collabels("")                          ///
      starlevels(* 0.10 ** 0.05 *** 0.01)    ///
      `ci_bottom'                            ///
      varwidth(20)                           ///
      nolines nomtitles nonum                ///
      postfoot("`table_postfoot'")           ///
      append substitute(\_ _)

    * Phase 1b.6: strip esttab's spurious blank tabular rows.
    * Same workaround as 2_summaryStats.do, specialized for 5-column GRC
    * tables (label + 4 covariate columns after dropping c0). Removes the
    * literal pattern emitted between fragments by varwidth(20) +
    * nomtitles + noobs. Leaves \addlinespace intact.
    removeStringFromTex "$output/tables/`filename'${vsfx}.tex" ///
        , remove("                    &               &               &               &               \BS\BS")

    * Strip the \addlinespace that esttab inserts between the SE row and
    * the inversion CI row of the same block, so the CI row visually
    * attaches to its parameter rather than reading as a separate block.
    * Pattern: "\\\n\addlinespace\n95\% inv. CI" -> "\\\n95\% inv. CI".
    * The \addlinespace BETWEEN blocks is left intact because the line
    * before it is a CI row (or coef row in covs2 columns where the CI
    * row is "empty"), not an SE row immediately followed by a CI row.
    * Only runs when invci is on; without CI rows there is no "95\% inv. CI"
    * string to attach, so the filter would be a no-op rewrite.
    if "`invci'" != "" {
        tempfile _addlspc_tmp
        filefilter "$output/tables/`filename'${vsfx}.tex" "`_addlspc_tmp'", ///
            from("\BS\BS\r\n\BSaddlinespace\r\n95\BS% inv. CI")            ///
            to("\BS\BS\r\n95\BS% inv. CI")
        copy "`_addlspc_tmp'" "$output/tables/`filename'${vsfx}.tex", replace
    }

    * Drop the ~15 estimates this call stored. Without cleanup the
    * stored-estimates namespace fills up after ~20 cells (Stata limit ~300)
    * and subsequent grc_tex_table_trend calls fail with
    * "system limit exceeded; you need to drop one or more models".
    est drop _all

end

* **********************************************************************
* Create LaTeX table for the Verdier-style robust GRC results.
* Differs from grc_tex_table_trend in the bottom stats block: shows
* Individuals (n_indiv = unique pid count in e(sample)) AND Locations
* (N_clust = vfirst cluster count under vce(cluster vfirst)) as
* separate rows. The main GRC tables only need one count row because
* their vce(cluster pid) makes N_clust == individual count; the
* Verdier tables need both because clusters are locations, not pids.
* **********************************************************************
cap program drop grc_tex_table_trend_robust
program define grc_tex_table_trend_robust
    syntax , COLumns(integer) FILEname(string asis) 	///
					COUNTRY(string asis) KEEP(string) varlabel(string) 	///
					htb(string) PREhead(string asis) POSTfoot(string asis) ///
					COEFLABels(string asis) TEXTdepvar(string asis) ///
					[ESTPrefix(string)]

    if "`estprefix'" == "" local estprefix "vv_"

    local num_panels `panels'
    local ccc ""
    forval i = 1/`columns' {
        local ccc "`ccc'c"
    }
    local cmid = `columns' + 1
		local colnumbers ""
		local table_prehead 	""
		local table_postfoot 	""
		local posthead 			""
    local table_prehead1 "`"\begin{table}[`htb'] \centering \begin{threeparttable}"'"
    local table_prehead2 "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
    local table_prehead "`table_prehead1' `prehead' `table_prehead2'"
		local table_postfoot "\cmidrule{2-`cmid'} `postfoot'"

    local ests_never = ""
    local ests_avg = ""
    local ests = ""

    foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all {
        local ests_never = "`ests_never' `estprefix'`country'_`estname'_never"
        local ests_avg   = "`ests_avg' `estprefix'`country'_`estname'_avg"
        local ests       = "`ests' `estprefix'`country'_`estname'"
    }

    * Delta_never row
    esttab `ests_never'                    ///
    using "$output/tables/`filename'.tex", ///
    se b(%8.3f)                            ///
    fragment booktabs noobs                ///
    collabels("")                          ///
    starlevels(* 0.10 ** 0.05 *** 0.01)    ///
    varwidth(20)                           ///
    nolines nomtitles `colnumbers'         ///
    prehead(`table_prehead')               ///
    posthead(`table_posthead')             ///
    coeflabels(Delta_never "$\Delta_{\text{never}}$" Delta_always "$\Delta_{\text{always}}$") ///
    replace substitute(\_ _)

    * Average Delta row
    esttab `ests_avg'                      ///
    using "$output/tables/`filename'.tex", ///
    se b(%8.3f)                            ///
    fragment booktabs noobs                ///
    collabels("")                          ///
    starlevels(* 0.10 ** 0.05 *** 0.01)    ///
    varwidth(20)                           ///
    nolines nomtitles nonum                ///
    coeflabels(Delta_avg "Average $\Delta$") ///
    append substitute(\_ _)

    * Phi row + bottom stats: Individuals, Locations, Observations,
    * J-stat, J-stat p-value, Converged.
    esttab `ests'                          ///
    using "$output/tables/`filename'.tex", ///
    se b(%8.3f)                            ///
    keep(`keep')                           ///
    varlabels(`keep' "`varlabel'")         ///
    eqlabels(none)                         ///
    fragment booktabs                      ///
    collabels("")                          ///
    starlevels(* 0.10 ** 0.05 *** 0.01)    ///
    s(n_indiv N N_clust Jstat Jpval converged_str, label( "Individuals" "Observations" "Locations" "J-stat" "J-stat (p-value)" "Converged") ///
    fmt(%9.0fc %9.0fc %9.0fc %8.1fc %8.3fc %8.0fc))      ///
    varwidth(20)                           ///
    nolines nomtitles nonum                ///
    postfoot("`table_postfoot'")           ///
    append substitute(\_ _)

end

* **********************************************************************
* _ctab_cell (helper for cluster_comparison_table)
* Loads one .ster, reads a coefficient, and returns the point estimate
* with significance stars (r(b)) and its parenthesized SE (r(se)).
* Stars use the normal approximation z = b/se at * .10, ** .05, *** .01,
* matching the star levels the esttab-based table writers use.
* **********************************************************************
capture program drop _ctab_cell
program define _ctab_cell, rclass
    syntax , STER(string) COEF(string)
    capture quietly estimates use "`ster'"
    if _rc {
        di as error "cluster_comparison_table: missing ster `ster'"
        exit 198
    }
    local b  = _b[`coef']
    local se = _se[`coef']
    local star = ""
    local p = 2*normal(-abs(`b'/`se'))
    if `p' < 0.10 local star "*"
    if `p' < 0.05 local star "**"
    if `p' < 0.01 local star "***"
    return local b  = trim(string(`b',  "%9.3f")) + "`star'"
    return local se = "(" + trim(string(`se', "%9.3f")) + ")"
end

* **********************************************************************
* cluster_comparison_table
* Baseline-vs-cluster-residualized GRC summary table, reporting both the
* LCA slope phi and the extrapolated never-migrant return Delta_never.
* Reads four .ster per row (phi + Delta_never, baseline + cluster):
*   baseline phi     -> $output/<baseprefix><c><basesuffix>            (grc_<c>_cuu_ca)
*   cluster  phi     -> $output/<vvprefix><c><vvsuffix>               (vv_<c>_os_covs_all)
*   baseline Dnever  -> $output/<baseprefix><c><basesuffix><never>    (..._n)
*   cluster  Dnever  -> $output/<vvprefix><c><vvsuffix><never>        (..._n)
* Countries may include hukou codes (CHN_rf, CHN_uf), whose stems follow
* the same pattern (grc_CHN_rf_cuu_ca, vv_CHN_rf_os_covs_all, ...).
* **********************************************************************
capture program drop cluster_comparison_table
program define cluster_comparison_table
    syntax , FILEname(string) [                              ///
        Countries(string)                                   ///
        baseprefix(string) basesuffix(string)               ///
        vvprefix(string)   vvsuffix(string)                 ///
        neversuffix(string) phicoef(string) nevercoef(string) ]

    if "`countries'"   == "" local countries  "IDN CHN TZA"
    if "`baseprefix'"  == "" local baseprefix  "grc_"
    if "`basesuffix'"  == "" local basesuffix  "_cuu_ca"
    if "`vvprefix'"    == "" local vvprefix    "vv_"
    if "`vvsuffix'"    == "" local vvsuffix    "_os_covs_all"
    if "`neversuffix'" == "" local neversuffix "_n"
    if "`phicoef'"     == "" local phicoef     "phi:_cons"
    if "`nevercoef'"   == "" local nevercoef   "Delta_never"

    tempname fh
    file open `fh' using "$output/tables/`filename'.tex", write replace text

    file write `fh' "% Generated by cluster_comparison_table (0_programs.do) --- do not hand-edit." _n
    file write `fh' "\begin{table}[htb!] \centering \begin{threeparttable}" _n
    file write `fh' "\caption{Baseline versus cluster-residualized GRC, consumption (unbalanced panel)}" _n
    file write `fh' "\label{tab:verdier-robust}" _n
    file write `fh' "\begin{tabular}{l cc cc} \toprule" _n
    file write `fh' "                       & \multicolumn{2}{c}{\$\phi\$}" _n
    file write `fh' "                       & \multicolumn{2}{c}{\$\Delta_{\text{never}}\$} \\" _n
    file write `fh' "\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n
    file write `fh' "                       & Baseline & Cluster & Baseline & Cluster \\" _n
    file write `fh' "\midrule" _n

    local nc : word count `countries'
    local i = 0
    foreach c of local countries {
        local ++i
        if      "`c'" == "IDN"    local cname "Indonesia"
        else if "`c'" == "CHN"    local cname "China"
        else if "`c'" == "CHN_rf" local cname "China (rural-first)"
        else if "`c'" == "CHN_uf" local cname "China (urban-first)"
        else if "`c'" == "TZA"    local cname "Tanzania"
        else                      local cname "`c'"

        * phi: baseline then cluster-residualized
        _ctab_cell, ster("$output/`baseprefix'`c'`basesuffix'")              coef(`phicoef')
        local pbb = r(b)
        local pbs = r(se)
        _ctab_cell, ster("$output/`vvprefix'`c'`vvsuffix'")                  coef(`phicoef')
        local pcb = r(b)
        local pcs = r(se)

        * Delta_never: baseline then cluster-residualized (from the _n ster)
        _ctab_cell, ster("$output/`baseprefix'`c'`basesuffix'`neversuffix'") coef(`nevercoef')
        local nbb = r(b)
        local nbs = r(se)
        _ctab_cell, ster("$output/`vvprefix'`c'`vvsuffix'`neversuffix'")     coef(`nevercoef')
        local ncb = r(b)
        local ncs = r(se)

        file write `fh' "`cname' & `pbb' & `pcb' & `nbb' & `ncb' \\" _n
        file write `fh' " & `pbs' & `pcs' & `nbs' & `ncs' \\" _n
        if `i' < `nc' file write `fh' "\addlinespace" _n
    }

    file write `fh' "\bottomrule" _n
    file write `fh' "\end{tabular}" _n
    file write `fh' "\begin{tablenotes}[flushleft] \footnotesize" _n
    file write `fh' "\item{Each row reports two quantities from the restricted GRC on the unbalanced consumption sample with full controls and period fixed effects (column~(5) of the per-country GRC tables): the LCA slope \$\phi\$ and the extrapolated never-migrant return \$\Delta_{\text{never}}\$. The baseline columns reproduce the pooled estimates; the cluster columns re-estimate after replacing the switcher-treatment instruments with their within-cluster residuals, using onestep GMM, with standard errors clustered at the level of the cluster of first observation (first-wave province in Indonesia and China, region in Tanzania). Stars: \$^{*}p<0.10\$; \$^{**}p<0.05\$; \$^{***}p<0.01\$.}" _n
    file write `fh' "\end{tablenotes} \end{threeparttable} \end{table}" _n

    file close `fh'
    di as txt "cluster_comparison_table: wrote \$output/tables/`filename'.tex"
end

* **********************************************************************
* extras_tex_table
* Phase 1b.6: per-cell wrapper that builds ONE family-table for the
* extras specs (matches run_grc_with_extra_regressor's GMM cells 1:1).
* Looks up everything --- file suffix, fam_token, postfoot label, and
* depvar/choice/balance for the filename --- from the same (country,
* spec3, regressor) arg triple as the GMM call. Reads disambiguated
* sters from disk (grc_<country>_<spec3>_<fam>_<col>.ster).
*
* Args identical to run_grc_with_extra_regressor:
*   country(IDN|CHN|TZA)
*   spec3(cuu|cub|iuu|cnu)
*   regressor(varname)

* **********************************************************************
capture program drop extras_tex_table
program define extras_tex_table
    syntax , country(string) spec3(string) regressor(name)

    * Family token (ster name) and file suffix (filename)
    local fam ""
    local file_suffix ""
    local fam_label   ""
    if "`regressor'" == "exp" {
        local fam         exp
        local file_suffix exp
        local fam_label   "Experience"
    }
    if "`regressor'" == "exp_max" {
        local fam         maxexp
        local file_suffix exp_max
        local fam_label   "Max Experience"
    }
    if "`regressor'" == "exp_share" {
        local fam         expsh
        local file_suffix exp_sh
        local fam_label   "Experience Share"
    }
    if "`regressor'" == "exp_max_share" {
        local fam         maxexpsh
        local file_suffix exp_m_sh
        local fam_label   "Max Experience Share"
    }
    if "`regressor'" == "urbanbirth" {
        local fam         birth
        local file_suffix birth
        local fam_label   "Urban Birth"
    }
    if "`fam'" == "" {
        di as error "extras_tex_table: unknown regressor `regressor'"
        exit 198
    }

    * Spec3 -> filename label tokens (matches 9_GRC_extras.do dispatch)
    local choice  ""
    local depvar  ""
    local balance ""
    if "`spec3'" == "cuu" {
        local choice  urban
        local depvar  consumption
        local balance unb
    }
    else if "`spec3'" == "cub" {
        local choice  urban
        local depvar  consumption
        local balance bal
    }
    else if "`spec3'" == "iuu" {
        local choice  urban
        local depvar  income
        local balance unb
    }
    else if "`spec3'" == "cnu" {
        local choice  nonag
        local depvar  consumption
        local balance unb
    }
    else {
        di as error "extras_tex_table: unknown spec3 `spec3'"
        exit 198
    }

    local reportvars "phi:_cons"
    local varlab "$\phi$"

    * "Time FE Y Y Y Y" indicator + family covariate labels (per 10-15 convention)
    local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & `fam_label' & \& Female & \& Age$^2$ & All \\

    * M3 (Phase 2) collapse: birth and experience families now share the
    * unified grc_tex_table_trend, parameterized by covs2_set. The birth
    * variant was byte-identical to _exp; both used the c1/c2/c3/ca
    * covs2 set distinct from the main 4_GrRC.do family.
    grc_tex_table_trend, columns(4)                                             ///
        spec(`spec3'_`fam')                                                      ///
        covs2set(c1 c2 c3 ca)                                                    ///
        country(`country')                                                       ///
        filename(GRC_`country'_`depvar'_`choice'_`balance'_`file_suffix')       ///
        keep(`reportvars')                                                       ///
        varlabel(`varlab')                                                       ///
        postfoot(`postfoot_str')                                                 ///
        coeflabels(choice "Urban")                                               ///
        textdepvar( log(`depvar') )

    if $copyOverleaf == 1 {
        capture confirm file "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_`file_suffix'.tex"
        if _rc == 0 {
            copyOverleaf                                                                              ///
                "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_`file_suffix'.tex"          ///
                , subdir(tables)
        }
    }
end

* **********************************************************************
* Make heterogeneity tables for Delta estimates
* **********************************************************************
capture program drop het_table_delta
program define het_table_delta
    syntax , FILEname(string asis) COUNTRY(string asis) KEEP(string)	///
				POSTfoot(string asis) ///
				COEFLABels(string asis) TEXTdepvar(string asis)
	* Phase 1b: SLIM tabular-only output. See grc_tex_table_trend header
	* comment for details. Paper-side wrapper: \GRChetDeltatable (TBD).

    // Split the panel names, prehead, and postfoot strings into tokens

    local ccc "c"		// one column
    local cmid = 2
		local colnumbers ""
		local table_postfoot 	""
		local posthead 			""
		local table_prefoot		"\addlinespace"
    local table_prehead "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
		local table_postfoot "\cmidrule{2-`cmid'} `postfoot' \bottomrule \end{tabular}"

    * Phase 1b.5b: load estimate from disk inside the program.
    * Heterogeneity tables are always urban-spec (M11 spec3 = cuu),
    * max-cov set = ca, Delta-per-trajectory suffix = d.
    capture confirm file "$dir/output/grc_`country'_cuu_ca_d${vsfx}.ster"
    if _rc != 0 {
        di as error "het_table_delta: SKIP `country' (sters missing on disk)"
        exit
    }
    estimates use "$dir/output/grc_`country'_cuu_ca_d${vsfx}"
    estimates store grc_`country'_cuu_ca_d
    local ests_delta = "grc_`country'_cuu_ca_d"

	* Output Deltas and mus
	esttab `ests_delta'						 ///
    using "$output/tables/`filename'${vsfx}.tex",   ///
	se b(%8.3f)                              ///  
    keep(`keep') 							 ///
    coeflabels(`coeflabels') 				 ///
    eqlabels(none)					         ///
	fragment booktabs nogaps noobs           ///
    collabels("$\Delta$")		 			 ///
    star(* 0.10 ** 0.05 *** 0.01) 			 ///
	s(joint_chi2 joint_p, label("$\chi^2$ (all equal)" "p-value") ///
    fmt(%8.3fc %8.3fc))  				     ///
    varwidth(20) 	                         ///
    nolines nomtitles `colnumbers'           ///
    prehead(`table_prehead')                 ///
    posthead(`table_posthead')               ///
    prefoot(`table_prefoot')   	             ///
    postfoot("`table_postfoot'")             ///
    replace substitute(\_ _)
   
end

* **********************************************************************
* Make heterogeneity tables for mu estimates
* **********************************************************************
capture program drop het_table_mu
program define het_table_mu
    syntax , FILEname(string asis) COUNTRY(string asis) KEEP(string)	///
				POSTfoot(string asis) ///
				COEFLABels(string asis) TEXTdepvar(string asis)
	* Phase 1b: SLIM tabular-only output. See grc_tex_table_trend header
	* comment for details. Paper-side wrapper: \GRChetMutable (TBD).

    // Split the panel names, prehead, and postfoot strings into tokens

    local ccc "c"		// one column
    local cmid = 2
		local colnumbers ""
		local table_postfoot 	""
		local posthead 			""
		local table_prefoot		"\addlinespace"
    local table_prehead "`"\begin{tabular}{l `ccc'} \toprule  \textbf{Dep. var:} `textdepvar'"'"
		local table_postfoot "\cmidrule{2-`cmid'} `postfoot' \bottomrule \end{tabular}"

    * Phase 1b.5b: load estimate from disk inside the program.
    * Heterogeneity tables are always urban-spec (M11 spec3 = cuu),
    * max-cov set = ca; main fit has empty sfx1.
    capture confirm file "$dir/output/grc_`country'_cuu_ca${vsfx}.ster"
    if _rc != 0 {
        di as error "het_table_mu: SKIP `country' (sters missing on disk)"
        exit
    }
    estimates use "$dir/output/grc_`country'_cuu_ca${vsfx}"
    estimates store grc_`country'_cuu_ca
    local ests = "grc_`country'_cuu_ca"

	* Output Deltas and mus
	esttab `ests'							 ///
    using "$output/tables/`filename'${vsfx}.tex",   ///
	se b(%8.3f)                              ///  
    keep(`keep') 							 ///
    coeflabels(`coeflabels') 				 ///
    eqlabels(none)					         ///
	fragment booktabs nogaps noobs           ///
    collabels("$\mu$")			 			 ///
    star(* 0.10 ** 0.05 *** 0.01) 			 ///
	s(joint_chi2 joint_p, label("$\chi^2$ (all equal)" "p-value") ///
    fmt(%8.3fc %8.3fc))  				     ///
    varwidth(20) 	                         ///
    nolines nomtitles `colnumbers'           ///
    prehead(`table_prehead')                 ///
    posthead(`table_posthead')               ///
    prefoot(`table_prefoot')   	             ///
    postfoot("`table_postfoot'")             ///
    replace substitute(\_ _)

end

* **********************************************************************
* attach_inversion_ci: weak-ID-robust LCA inversion CIs for phi and the
* three trajectory-specific deltas (never, avg, always), attached to a
* saved GRC estimate.
*
* Calls into Python via lca_inversion.compute_all_inversion_cis. Stores
* point estimates, 90% and 95% convex-hull CIs as e()-scalars, plus
* pre-formatted bracketed LaTeX strings as e()-macros so that
* grc_tex_table_trend can consume them via esttab's stats() clause.
* Re-saves the .ster so the scalars persist.
*
* Decoupled from run_grc: callers run the GMM pipeline first (writes
* _g/_n/_a sters per STER_NAMING.md), then call attach_inversion_ci on
* each saved ster. This keeps the (slow) GMM step independent of the
* inversion pass, so the latter can be re-run on its own when the
* inference machinery changes (F adjustment, bootstrap calibration,
* etc.) without redoing the GMM.
* **********************************************************************

* file-level python: set sys.path so subsequent imports find lca_inversion.
* Runs once per do-of-this-file; idempotent against repeats.
python:
import sys, os
from sfi import Macro
_DIR = Macro.getGlobal("dir")
if _DIR:
    _EXPLOR = os.path.normpath(
        os.path.join(_DIR, "..", "explorations", "python-grc")
    )
    if _EXPLOR not in sys.path:
        sys.path.insert(0, _EXPLOR)
del _DIR
end

capture program drop attach_inversion_ci
program define attach_inversion_ci, eclass
    syntax , ESTbase(string)                                     ///
             OUTcome(string) TRAJ(string) CHOICE(string)         ///
             HHID(string) BASE(integer)                          ///
             [CONTrols(varlist fv)]                              ///
             [STERdir(string asis)]                              ///
             [THReshold(integer 5)]

    * `string asis' preserves outer double quotes from callers like
    * `sterdir("${inversion_sterdir}")', which would otherwise produce a
    * malformed path when concatenated. Strip them so subsequent
    * `confirm file' / `estimates use' / `estimates save' calls see a
    * plain path. File paths on Windows and POSIX cannot contain `"', so
    * a blanket subinstr is safe here.
    local sterdir = subinstr(`"`sterdir'"', `"""', "", .)

    * estbase is the (country, spec) cell base name without suffix under
    * the STER_NAMING.md convention, e.g. "grc_IDN_cuu_ca". The program
    * looks for and updates the four sters {estbase}.ster, {estbase}_n.ster,
    * {estbase}_g.ster, {estbase}_a.ster (parent / never / avg / always)
    * --- attaching the same inversion macros to each via a single python
    * compute, since the inversion math is identical across suffixes (the
    * four sters all rest on the same underlying GMM fit).

    * 1. fv-expand controls so the python helper sees plain variable names
    local ctrl_list `controls'
    if "`controls'" != "" {
        fvexpand `controls'
        local ctrl_list = r(varlist)
    }

    * 2. ONE python call computes all four inversions for this cell.
    python: import lca_inversion as _li; _li.attach_inversion_for_stata(outcome="`outcome'", trajectory="`traj'", choice="`choice'", hhid="`hhid'", base=int("`base'"), controls="`ctrl_list'".split(), threshold=int("`threshold'"))

    * 3. iterate over the four suffixes, ereturn-ing the macros and
    * re-saving each ster. Skips suffixes whose .ster does not exist.
    * Suffix tokens follow the post-refactor naming in STER_NAMING.md:
    *   ""  parent (main GMM result)
    *   _n  Delta_never extrapolation (was _never)
    *   _g  Delta_avg average across switchers (was _avg)
    *   _a  Delta_always extrapolation (was _always)
    local n_attached = 0
    foreach suffix in "" "_n" "_g" "_a" {
        local target "`sterdir'/`estbase'`suffix'.ster"
        capture confirm file "`target'"
        if _rc != 0 {
            di as text "  attach_inversion_ci: SKIP `estbase'`suffix' (no ster)"
            continue
        }
        estimates use "`target'"

        foreach prefix in inv_phi inv_dN inv_davg inv_dT {
            ereturn scalar `prefix'_at_waldmin     = ``prefix'_at_waldmin'
            ereturn scalar `prefix'_wald_min       = ``prefix'_wald_min'
            ereturn scalar `prefix'_J_R            = ``prefix'_J_R'
            ereturn scalar `prefix'_n_kept         = ``prefix'_n_kept'
            ereturn scalar `prefix'_ci90_lo        = ``prefix'_ci90_lo'
            ereturn scalar `prefix'_ci90_hi        = ``prefix'_ci90_hi'
            ereturn scalar `prefix'_ci95_lo        = ``prefix'_ci95_lo'
            ereturn scalar `prefix'_ci95_hi        = ``prefix'_ci95_hi'
            ereturn scalar `prefix'_island_count95 = ``prefix'_island_count95'
            ereturn scalar `prefix'_island_count90 = ``prefix'_island_count90'
            ereturn local  `prefix'_ci90_str       `"``prefix'_ci90_str'"'
            ereturn local  `prefix'_ci95_str       `"``prefix'_ci95_str'"'
        }

        estimates save "`target'", replace
        local ++n_attached
    }

    * 4. pretty print summary (once per cell, not once per suffix)
    di as text "{hline 72}"
    di as text "Inversion CIs attached to " as result "`estbase'"   ///
        as text "  (`n_attached' of 4 sters updated)"
    di as text "{hline 72}"
    di as text "  J_R = " as result `inv_phi_J_R'                ///
        as text ",  switchers kept = " as result `inv_phi_n_kept'
    foreach prefix in inv_phi inv_dN inv_davg inv_dT {
        di as text "  `prefix' point = " as result %9.4f ``prefix'_at_waldmin'
        di as text "    95% CI: " as result `"``prefix'_ci95_str'"'
        di as text "    90% CI: " as result `"``prefix'_ci90_str'"'
    }
end
