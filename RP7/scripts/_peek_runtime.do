* Peek at the M9 timer values stored as `e(runtime)` in a few sters.
* Read-only --- doesn't interfere with the live smoke.

clear all

local out "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output"

di as text "{hline 60}"
di as text "M9 e(runtime) inspection"
di as text "{hline 60}"

* M11 shorthand: grc_<country>_<spec3>_<covs2>. Section 3 of smoke #9 was
* income/urban/unb (spec3=iuu); the section-1 (cuu) and section-2 (cub)
* sters were overwritten on disk before M11 landed. Adjust the spec3
* token here when peeking at a different section.
foreach ster in grc_CHN_iuu_c0 grc_CHN_iuu_ct ///
                grc_CHN_iuu_c1 grc_CHN_iuu_c2 grc_CHN_iuu_ca ///
                grc_IDN_iuu_c0 grc_IDN_iuu_ca ///
                grc_TZA_iuu_c0 grc_TZA_iuu_ca {
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
