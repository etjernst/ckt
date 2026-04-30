* test_attach_inversion_ci.do --- exercise the new attach_inversion_ci
* program from 0_programs.do against a real IDN cell. Confirms that
* (1) the file-level python: sys.path setup works,
* (2) the in-program python: import + helper call works,
* (3) e()-scalars and e()-macros are written and persist after the
*     ster is re-saved.
*
* Targets the rerun_workdir sters (post-Delta_avg-fix) since RP7/output
* hasn't yet been populated by a 5_GrRC.do run.
version 19
clear all
set more off
set varabbrev off
capture log close
log using "test_attach_inversion_ci.smcl", replace

* dir set so 0_programs.do's file-level python: block resolves the
* explorations/python-grc directory off it.
global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global localout "rerun_workdir/output"

quietly include "$dir/scripts/0_programs.do"

capture noisily {

    local country IDN
    local choice  urban
    local depvar  consumption
    local balance unb

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    global keepvars lndepvar trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*
    keep $keepvars
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"
    drop if mi(lndepvar) | mi(choice)

    initial_values lndepvar, switchers(2 3 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27) ///
        balance(`balance') estname(initial_`country')
    local base `r(base)'
    di as text ""
    di as text ">>> base trajectory = `base'"

    * controls for covs_all
    local controls `periodFE' female age2 education_max education_max2

    di as text ""
    di as text "{hline 72}"
    di as text "Test 1: phi inversion on grc_IDN_covs_all_avg"
    di as text "{hline 72}"
    attach_inversion_ci,                 ///
        estname(grc_`country'_covs_all_avg) ///
        sterdir("$localout")                 ///
        outcome(lndepvar) traj(trajectory)   ///
        choice(choice) hhid(pid)             ///
        base(`base')                         ///
        controls(`controls')

    * verify the scalars persist after estimates use
    estimates use "$localout/grc_`country'_covs_all_avg"
    di as text ""
    di as text ">>> After estimates use, scalars should be present:"
    di as text "    e(inv_phi_ci95_lo)  = " as result %9.4f e(inv_phi_ci95_lo)
    di as text "    e(inv_phi_ci95_hi)  = " as result %9.4f e(inv_phi_ci95_hi)
    di as text "    e(inv_dT_island_count95) = " as result e(inv_dT_island_count95)
    di as text "    e(inv_dT_ci95_str)  = " as result `"`e(inv_dT_ci95_str)'"'
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> SCRIPT FAILED rc=`rc'"
exit, STATA clear
