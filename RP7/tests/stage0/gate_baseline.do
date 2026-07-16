* *******************************************************************
* Title:   Stage 0 gate-panel baseline refit
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Refits the gate panel on the promoted data hub with
*          unchanged estimation code, into the shadow root's output
*          directory, freezing the baseline sters the refactor
*          stages (1-8) gate against. The shadow root's scripts/ and
*          data/ are junctions to the live tree; only output/ is real,
*          so every "$dir/output" ster save lands in the baseline dir.
* Input:   RP7/data/processed (canonical hub, via the data junction)
* Output:  RP7/tests/stage0/baseline_root/output/ (baseline sters)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/baseline_root"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0

* Resume-on-interrupt: run_grc skips any fit whose _g ster already
* exists in $output, so relaunching this driver refits only
* incomplete work (and a full rerun on a complete output is a no-op).
* Delete the target sters to force a refit.
global skip_if_exists 1

* Free the unnamed log slot (-e batch holds it); each included script
* opens its own named log.
capture log close

* All estimation legs are gate-panel slices: the _ct no-covariate
* column is dropped from the tables (author, 2026-07-15) and income
* results are not run (D-2), so neither is refit for the baseline;
* Verdier runs TZA only per the plan appendix.
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
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_baseline_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
