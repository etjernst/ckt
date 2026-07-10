* ============================================================
* Title:   Validate grc_weak_id_inference.ado on synthesized T=2 data
* Purpose: Run the original ado on the synthetic dataset produced by
*          synth_t2_validation.py and dump the CI endpoints. Compare
*          against the Python implementation's CI to verify our port
*          matches the original on data it was designed for.
* Input:   synth_t2.dta (created by synth_t2_validation.py)
* Output:  synth_t2_stata_curve.csv (full grid postfile)
*          synth_t2_stata_ci.csv    (CI endpoints)
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "synth_t2_validation.smcl", replace

* Make the original ado discoverable.
adopath ++ "."

use "synth_t2.dta", clear
tab trajectory

tempfile postfile_path
grc_weak_id_inference y, ///
    hhid(pid) ///
    hybrid(choice) ///
    min(-3) max(1) increment(0.02) ///
    test_type(joint) ///
    progress(0) ///
    path("synth_t2_stata_curve.dta") ///
    type_one(0.05)

* The ado returns r(min_phi32), r(max_phi32) for the (3, 2) adjacent pair.
return list

local min_phi = "`r(min_phi32)'"
local max_phi = "`r(max_phi32)'"

di as result "Stata CI: [`min_phi', `max_phi']"

file open fh using "synth_t2_stata_ci.csv", write replace
file write fh "min_phi,max_phi" _n
file write fh "`min_phi',`max_phi'" _n
file close fh

* Convert the postfile .dta to .csv for cross-language comparison.
use "synth_t2_stata_curve.dta", clear
export delimited "synth_t2_stata_curve.csv", replace nolabel

log close
exit, STATA clear
