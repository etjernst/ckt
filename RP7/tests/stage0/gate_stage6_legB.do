* *******************************************************************
* Title:   Stage 6 gate, leg B: Verdier grid on fixed code
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Runs 17_verdier_robust.do verbatim from the post-fix
*          scripts snapshot in stage6_rootB/scripts (all three
*          countries, both GMM steps, five covariate specs). Every
*          ster and marker must match its stage6_rootA counterpart
*          bitwise, and the fixed table tail must complete: six
*          verdier_robust_*.tex tables plus three GRC_*_cluster.tex
*          copies in the shadow output/tables. gate_stage6_compare
*          adjudicates.
* Input:   canonical hub via the stage6_rootB data junction
* Output:  RP7/tests/stage0/stage6_rootB/output/ (sters, markers,
*          tables)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage6_rootB"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0

* Free the unnamed log slot (-e batch holds it); the script opens its
* own named log in the shadow root's logs directory.
capture log close

capture noisily {
    do "$dir/scripts/17_verdier_robust.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage6_legB_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
