* ============================================================
* Title:   Re-run TZA GMM for 5 specs using the LOCAL RP7
*          0_programs.do (with the within-switcher Delta_avg fix
*          from 2026-04-29).
* Author:  delta-inversion validation gate
* Date:    2026-04-30
* Purpose: TZA half of the CHN/TZA split. See
*          rerun_chn_5gr_fixed.do for context.
* Output:  rerun_workdir/output/grc_TZA_*.ster.
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "rerun_workdir/rerun_tza_5gr_fixed.smcl", replace

global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global scripts "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts"

global dir     "rerun_workdir"
global output  "$dir/output"
global logs    "$dir/logs"
capture mkdir "$logs"

global skip_if_exists 1

do "$scripts/0_programs.do"

capture noisily {
    local choice  urban
    local depvar  consumption
    local balance unb
    local country TZA

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

    initial_values lndepvar, switchers($switchers) balance(`balance') ///
        estname(initial_`country')
    local base `r(base)'
    local initial "`r(initial)'"
    local iterations 500

    run_grc, estname(grc_`country'_covs_0) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') iterate(`iterations')
    run_grc, estname(grc_`country'_covs_trend) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE') iterate(`iterations')
    run_grc, estname(grc_`country'_covs_1) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm) iterate(`iterations')
    run_grc, estname(grc_`country'_covs_2) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm2) iterate(`iterations')
    run_grc, estname(grc_`country'_covs_all) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm_all) iterate(`iterations')
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> rerun_tza_5gr_fixed FAILED rc=`saved_rc'"
}
exit, STATA clear
