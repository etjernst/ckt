* *******************************************************************
* Title:   Bundled Stage 3+4 gate-panel refit, ct supplement
* Author:  Emilia Tjernstrom
* Date:    2026-07-18
* Purpose: Refits the _ct (time-FE-only) gate-panel cells on the
*          bundled Stage 3+4 code into the stage34_root shadow root.
*          Runs in parallel with the main bundled batch; ster names
*          are disjoint. gate_stage34_compare.do adjudicates both
*          batches against the frozen baseline.
* Input:   RP7/data_rebuild/processed via the stage34_root data
*          junction (must carry the Stage 3+4 scaffolding)
* Output:  RP7/tests/stage0/stage34_root/output/ (ct refit sters)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage34_root"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0

* Resume-on-interrupt: run_grc skips any fit whose _g ster already
* exists in $output, so relaunching this driver refits only
* incomplete work. Delete the target sters to force a refit.
global skip_if_exists 1

* Free the unnamed log slot (-e batch holds it); each slice opens its
* own named log.
capture log close

capture noisily {
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_ct_main.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_ct_nonag.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_ct_hukou.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage34_ct_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
