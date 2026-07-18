* *******************************************************************
* Title:   Bundled Stage 3+4 gate-panel refit (D-5)
* Author:  Emilia Tjernstrom
* Date:    2026-07-18
* Purpose: Refits every gate-panel leg on the Stage 3 (front-loaded
*          GRC scaffolding, estimable-sample drop) plus Stage 4
*          (sample-drop split, descriptor recompute, computed
*          non-switcher rule) code, reading the rebuilt hub through
*          the stage34_root shadow root. Expected outcome: bitwise
*          identity to the frozen baseline everywhere except the
*          cells fit on IDN_unb (one estimable singleton row removed)
*          and TZA_unb (two removed); gate_stage34_compare.do
*          adjudicates. The ct supplement runs in parallel via
*          gate_stage34_ct.do (ster names are disjoint).
* Input:   RP7/data_rebuild/processed via the stage34_root data
*          junction (must carry the Stage 3+4 scaffolding)
* Output:  RP7/tests/stage0/stage34_root/output/ (refit sters)
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

* Free the unnamed log slot (-e batch holds it); each included script
* opens its own named log.
capture log close

capture noisily {
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_main.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_nonag.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_hukou.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_extras.do"
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_verdier.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage34_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
