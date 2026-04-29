* ============================================================
* Title:   Re-run CHN GMM for 5 specs using the LOCAL RP7
*          0_programs.do (with the within-switcher Delta_avg fix
*          from 2026-04-29).
* Author:  delta-inversion validation gate
* Date:    2026-04-30
* Purpose: Regenerate _avg.ster (and full spec series) for CHN
*          via the corrected formula. Split out from the
*          combined CHN+TZA script so a Stata segfault on TZA
*          (previously seen on IDN's post-success CSV-write)
*          does not void CHN's progress.
*          The phi-summary CSV-write loop has been removed
*          entirely; use rerun_workdir/extract_published_deltas.do
*          afterward to extract phi/SE/J safely outside the GMM
*          process.
*          skip_if_exists is enabled so an interrupted run
*          resumes from the next missing _avg.ster on relaunch.
* Output:  rerun_workdir/output/grc_CHN_*.ster (overwritten when
*          _avg.ster is missing).
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "rerun_workdir/rerun_chn_5gr_fixed.smcl", replace

global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global scripts "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts"

global dir     "rerun_workdir"
global output  "$dir/output"
global logs    "$dir/logs"
capture mkdir "$logs"

* Resume-on-interrupt guard inside run_grc; skip a spec whose
* _avg.ster already exists. We deleted any corrupted CHN _avg
* files before launch, so this only kicks in if a prior partial
* run left some specs done.
global skip_if_exists 1

do "$scripts/0_programs.do"

capture noisily {
    local choice  urban
    local depvar  consumption
    local balance unb
    local country CHN

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
    di as error ">>> rerun_chn_5gr_fixed FAILED rc=`saved_rc'"
}
exit, STATA clear
