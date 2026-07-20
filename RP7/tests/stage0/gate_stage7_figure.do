* *******************************************************************
* Title:   Stage 7 gate: extrapolation-support figure on per-capita
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Runs 11b_extrapolation_support_figure.do from the
*          stage7_root scripts snapshot so the corrected figure and
*          its log land in the shadow root, not RP7/output. The log
*          carries mu_dN and the switcher support per country for
*          the D-3 comparison.
* Input:   canonical hub via the stage7_root data junction
* Output:  stage7_root/output/figures/extrapolation_support_*.{pdf,png},
*          gate_stage7_rc.txt
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage7_root"

* Free the unnamed log slot (-e batch holds it); the script opens its
* own log in the shadow root's logs directory.
capture log close

capture noisily {
    do "$dir/scripts/11b_extrapolation_support_figure.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage7_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
