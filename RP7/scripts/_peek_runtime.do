* Peek at the M9 timer values stored as `e(runtime)` in a few sters.
* Read-only --- doesn't interfere with the live smoke.

clear all

local out "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output"

di as text "{hline 60}"
di as text "M9 e(runtime) inspection"
di as text "{hline 60}"

foreach ster in grc_CHN_urban_covs_0 grc_CHN_urban_covs_trend ///
                grc_CHN_urban_covs_1 grc_CHN_urban_covs_2 grc_CHN_urban_covs_all ///
                grc_IDN_urban_covs_0 grc_IDN_urban_covs_all ///
                grc_TZA_urban_covs_0 grc_TZA_urban_covs_all {
    capture estimates use "`out'/`ster'"
    if _rc == 0 {
        di as text "{result:`ster'}: " ///
            "runtime=" %8.2f e(runtime) " sec   " ///
            "timer_slot=" %3.0f e(timer_slot) "   " ///
            "Jpval=" %5.3f e(Jpval) "   " ///
            "converged=" e(converged_str)
    }
    else {
        di as text "`ster': not present (rc=`=_rc')"
    }
}

di as text "{hline 60}"
exit, STATA clear
