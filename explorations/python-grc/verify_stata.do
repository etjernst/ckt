* ============================================================
* Title:   Stata reference run for Python GRC GMM verification
* Author:  Generated for CKT Python port verification
* Date:    2026-04-22
* Purpose: Run two-step efficient GMM (run_grc from 0_programs.do)
*          on the IDN consumption/urban/unbalanced spec without
*          covariates; export coefficients, SEs, and J-stat to CSV
*          for side-by-side comparison against grc_gmm.py.
* Input:   $dirdata/processed/IDN_unb.dta (via setup_grc_estimation)
* Output:  stata_out_idn_cons_urb_unb.csv        -- coef + SE per param
*          stata_out_idn_cons_urb_unb_jstat.csv  -- J-stat + metadata
*          verify_stata.smcl                     -- run log
*
* Usage (from the python-grc directory):
*    stata-mp -b do verify_stata.do
* or, setting an alternative replication-package root:
*    stata-mp -b do verify_stata.do, global(dir "<root>")
* ============================================================

version 17
clear all
set more off
set varabbrev off
capture log close
log using "verify_stata.smcl", replace

* -------- Paths --------
* The script expects the replication-package globals to be set. If run
* standalone, fall back to the canonical user-level path.
if "$dir" == "" {
    global dir     "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
    global dirdata "$dir/data"
    global scripts "$dir/scripts"
    global output  "$dir/output"
}

* -------- Load shared programs --------
do "$scripts/0_programs.do"

* -------- Data --------
local country IDN
local balance unb
use "$dirdata/processed/`country'_`balance'.dta", clear

* Recompute log consumption per capita per 5_GrRC.do line 64.
replace lndepvar = log(consumption/hhsize_cube)

* -------- Trajectory / period setup --------
setup_grc_estimation
tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

* -------- Initial values (also selects the base switcher) --------
initial_values lndepvar, switchers($switchers) balance(`balance') ///
    estname(initial_`country')
local base `r(base)'
local initial "`r(initial)'"

* -------- Two-step efficient GMM --------
local iterations 500
run_grc, estname(grc_verify) switchers($switchers) base(`base') ///
    initial(`initial') balance(`balance') iterate(`iterations')

* -------- Export coefficients and SEs --------
estimates restore grc_verify
matrix b = e(b)
matrix V = e(V)
local names : colfullnames b
local p = colsof(b)

tempname fh
file open `fh' using "stata_out_idn_cons_urb_unb.csv", write replace
file write `fh' "name,coef,se" _n
forvalues i = 1/`p' {
    local nm : word `i' of `names'
    local c  = b[1,`i']
    local v  = V[`i',`i']
    local s  = sqrt(`v')
    file write `fh' "`nm'," ("`c'") "," ("`s'") _n
}
file close `fh'

* -------- Export J-stat + metadata --------
file open `fh' using "stata_out_idn_cons_urb_unb_jstat.csv", write replace
file write `fh' "stat,value" _n
file write `fh' "J,`=e(J)'" _n
file write `fh' "J_df,`=e(J_df)'" _n
file write `fh' "J_p,`=e(J_p)'" _n
file write `fh' "N,`=e(N)'" _n
file write `fh' "N_clust,`=e(N_clust)'" _n
file write `fh' "base,`base'" _n
file write `fh' "converged,`=e(converged)'" _n
file close `fh'

log close

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
