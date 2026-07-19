* *******************************************************************
* Title:   Stage 6 gate, leg A: Verdier grid on pre-fix code
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Runs 17_verdier_robust.do verbatim from the pre-fix scripts
*          snapshot in stage6_rootA/scripts (all three countries, both
*          GMM steps, five covariate specs). Produces the old-code
*          sters and markers that leg B must match bitwise. The stale
*          table tail is expected to error (r(601) on the _never load)
*          inside the script's own capture wrapper AFTER all sters are
*          saved; that error is gate evidence of the defect, so a
*          FAILED rc in 17_verdier_robust.log does not fail this leg.
* Input:   canonical hub via the stage6_rootA data junction
* Output:  RP7/tests/stage0/stage6_rootA/output/ (sters + markers)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage6_rootA"

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
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage6_legA_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
