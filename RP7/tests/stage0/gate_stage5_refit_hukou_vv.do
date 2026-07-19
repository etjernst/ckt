* *******************************************************************
* Title:   Stage 5 gate refit, batch 2: hukou GRC and Verdier cells
* Author:  Emilia Tjernstrom
* Date:    2026-07-19
* Purpose: Refits the CHN hukou cells (rf/uf, ct/c1/c2/ca) and the
*          TZA Verdier leg on the Stage 5 code, exercising the
*          save_esample_marker call sites in run_grc, run_grc_onestep,
*          run_grc_robust, and run_grc_robust_vv. Expected outcome:
*          every ster bitwise-identical to its stage34_root/output
*          counterpart, plus one _esample.dta marker per parent fit;
*          gate_stage5_compare.do adjudicates. Runs in parallel with
*          gate_stage5_refit_main.do (ster names are disjoint).
* Input:   canonical hub via the stage5_root data junction
* Output:  RP7/tests/stage0/stage5_root/output/ (sters + markers)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage5_root"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0

* Resume-on-interrupt: run_grc skips any fit whose _g ster already
* exists in $output, so relaunching this driver refits only
* incomplete work. Delete the target sters to force a refit.
global skip_if_exists 1

* Free the unnamed log slot (-e batch holds it); each included script
* opens its own named log.
capture log close

capture noisily {
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_hukou.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_ct_hukou.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_verdier.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage5_hukou_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
