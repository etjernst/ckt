* ============================================================
* Title:   Re-run IDN GMM for 5 specs using the LOCAL RP7
*          0_programs.do, which carries the within-switcher
*          Delta_avg fix (commit on lca-inversion 2026-04-29).
* Author:  delta-inversion validation gate
* Date:    2026-04-29
* Purpose: Regenerate _avg.ster (and the entire spec series)
*          for IDN with the corrected Delta_avg formula. The
*          Dropbox 0_programs.do still has the bug; this script
*          forces the fixed local copy.
* Output:  rerun_workdir/output/grc_IDN_*.ster (overwritten)
*          rerun_workdir/idn_fresh_phi.csv (overwritten)
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "rerun_workdir/rerun_idn_5gr_fixed.smcl", replace

global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
* FIXED 0_programs.do is in the local RP7, not Dropbox.
global scripts "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts"

global dir     "rerun_workdir"
global output  "$dir/output"
global logs    "$dir/logs"
capture mkdir "$logs"

do "$scripts/0_programs.do"

capture noisily {
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

    * Refresh the phi summary CSV from the new estimates.
    tempname fh
    file open `fh' using "$dir/idn_fresh_phi.csv", write replace
    file write `fh' "spec,phi,phi_se,Delta_base,Delta_base_se,kappa,kappa_se,J,J_p,N,converged" _n
    foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
        estimates use "$output/grc_`country'_`spec'"
        local phi    = _b[phi:_cons]
        local phi_se = _se[phi:_cons]
        local Db     = _b[Delta_base:_cons]
        local Db_se  = _se[Delta_base:_cons]
        local ka     = _b[kappa:_cons]
        local ka_se  = _se[kappa:_cons]
        local J      = e(J)
        local Jp     = e(J_p)
        local N      = e(N)
        local cv     = cond(e(converged) == 1, "Y", "N")
        file write `fh' "`spec',`phi',`phi_se',`Db',`Db_se',`ka',`ka_se',`J',`Jp',`N',`cv'" _n
    }
    file close `fh'
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> rerun_idn_5gr_fixed FAILED rc=`saved_rc'"
}
exit, STATA clear
