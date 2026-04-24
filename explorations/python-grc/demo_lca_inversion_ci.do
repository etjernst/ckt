* demo_lca_inversion_ci.do --- proof-of-concept for the LCA inversion
* CI wrapper. Replays the IDN/cons/urban/unb covs_all spec from
* 5_GrRC.do, then attaches inversion CIs via lca_inversion_ci.
*
* Reads the existing fresh ster files from rerun_workdir/output/ to
* avoid re-running the GMM. Re-saves them in place with new e() scalars.
version 19
clear all
set more off
set varabbrev off
capture log close
log using "demo_lca_inversion_ci.smcl", replace

global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global scripts "$dropbox/scripts"
global localout "rerun_workdir/output"

* This do file lives in explorations/python-grc/ alongside lca_inversion_ci.ado
adopath ++ "."

do "$scripts/0_programs.do"

local choice  urban
local depvar  consumption
local balance unb
local country IDN

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
keep $keepvars
tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* Mirror the GMM's silent drop of missing outcome/choice rows
* (dump_stata_step1.do does this; 5_GrRC.do's run_grc handles internally)
drop if mi(lndepvar) | mi(choice)

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'

di as text "{hline 72}"
di as text "Test 1: covs_all (period FE + female + age2 + education + education2)"
di as text "{hline 72}"

lca_inversion_ci, ///
    estname(grc_`country'_covs_all) ///
    sterdir("$localout") ///
    outcome(lndepvar) ///
    traj(trajectory) ///
    choice(choice) ///
    hhid(pid) ///
    base(`base') ///
    controls(`periodFE' $covs_gmm_all)

di as text "{hline 72}"
di as text "Test 2: covs_trend (period FE only)"
di as text "{hline 72}"

lca_inversion_ci, ///
    estname(grc_`country'_covs_trend) ///
    sterdir("$localout") ///
    outcome(lndepvar) ///
    traj(trajectory) ///
    choice(choice) ///
    hhid(pid) ///
    base(`base') ///
    controls(`periodFE')

* Verify that re-loading the ster brings back the new e() scalars
estimates use "$localout/grc_`country'_covs_all"
di as text ""
di as text "After estimates use grc_IDN_covs_all (testing scalar persistence):"
di as text "  e(inv_ci95_lo) = " as result %7.4f e(inv_ci95_lo)
di as text "  e(inv_ci95_hi) = " as result %7.4f e(inv_ci95_hi)

log close
exit, STATA clear
