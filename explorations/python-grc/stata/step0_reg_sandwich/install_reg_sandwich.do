* ============================================================
* Title:   Install and verify reg_sandwich (Pustejovsky)
* Author:  Emilia Tjernstrom (with Claude)
* Date:    2026-05-01
* Purpose: Install reg_sandwich from SSC and capture metadata
*          (.pkg path, install date, version) for Step 0a
*          corrigendum check.
* Input:   none
* Output:  install_reg_sandwich.smcl
* ============================================================

clear all
set more off
set varabbrev off
capture log close
log using "install_reg_sandwich.smcl", replace

capture noisily {
    * Try a fresh install (replace overwrites any prior version).
    capture ssc install reg_sandwich, replace
    if _rc {
        di as error ">>> ssc install failed with rc=" _rc
        di as error ">>> Network access? SSC reachable?"
    }

    * Show where Stata put it and what files came along.
    which reg_sandwich
    capture findfile reg_sandwich.ado
    if !_rc {
        di as text "ado path: " r(fn)
    }
    capture findfile reg_sandwich.pkg
    if !_rc {
        di as text "pkg path: " r(fn)
        di as text "----- reg_sandwich.pkg -----"
        type "`r(fn)'"
        di as text "----- end pkg -----"
    }

    * Show the help-file header so we can confirm the AHZ syntax.
    capture findfile reg_sandwich.sthlp
    if !_rc {
        di as text "sthlp path: " r(fn)
    }

    * What did stata.trk record?
    capture findfile stata.trk
    if !_rc {
        di as text "stata.trk: " r(fn)
        di as text "----- last 40 lines of stata.trk -----"
        * Cheap tail via mata.
        mata: f = fopen(st_local("r(fn)"), "r")
        mata: lines = J(0, 1, "")
        mata: while ((line = fget(f)) != J(0,0,"")) lines = lines \ line
        mata: fclose(f)
        mata: n = rows(lines)
        mata: start = max((1, n - 39))
        mata: for (i = start; i <= n; i++) printf("%s\n", lines[i,1])
    }
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> install_reg_sandwich.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
