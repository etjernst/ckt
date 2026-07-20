* ============================================================
* Title:   One-shot smoke that boottest and summclust load.
* Author:  Emilia (with Claude)
* Date:    2026-05-04
* Purpose: Confirm post-0_setup.do that the packages we added
*          (boottest, summclust) are installed and which-able.
*          Disposable; safe to delete after the verification.
* ============================================================
clear all
set more off
capture log close
log using _smoke_packages_run.log, replace text

capture noisily {
    di as txt _n "=== boottest ==="
    which boottest

    di as txt _n "=== summclust ==="
    which summclust

    di as txt _n "=== reghdfe ==="
    which reghdfe

    di as txt _n "=== moremata ==="
    which mata mm_quantile()
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> _smoke_packages.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
