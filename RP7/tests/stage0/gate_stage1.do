* *******************************************************************
* Title:   Bundled Stage 1+2 gate-panel refit (D-5)
* Author:  Emilia Tjernstrom
* Date:    2026-07-16
* Purpose: Refits every gate-panel leg whose script the Stage 1
*          (covariate-ladder single source) or Stage 2 (logpc outcome
*          rename, income removal) refactor touched --- main, nonag,
*          hukou, extras, Verdier, and the ct supplement --- into the
*          stage1_root shadow root, on the refactored code. The
*          Verdier leg is included because Stage 2's outcome rename
*          edits 17_verdier_robust.do. Every refit ster must be
*          bit-identical to the frozen baseline (Tier 2);
*          gate_stage1_compare.do adjudicates. The ct supplement runs
*          in parallel via gate_stage1_ct.do (ster names are
*          disjoint), mirroring the Stage 0 batch split.
* Input:   RP7/data/processed (canonical hub, via the data junction;
*          must be rebuilt with the Stage 2 front end so the cells
*          carry logpc_consumption before this refit launches)
* Output:  RP7/tests/stage0/stage1_root/output/ (refit sters)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage1_root"

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
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage1_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
