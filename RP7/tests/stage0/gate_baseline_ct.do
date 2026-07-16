* *******************************************************************
* Title:   Stage 0 gate-panel baseline refit, ct supplement
* Author:  Emilia Tjernstrom
* Date:    2026-07-15
* Purpose: Refits the _ct (time-FE-only) gate-panel cells into the
*          same shadow-root output as gate_baseline.do. The _ct
*          column stays in the GRC tables (author, 2026-07-15), so
*          the baseline must cover it. Runs in parallel with the
*          main baseline batch; ster names are disjoint.
* Input:   RP7/data/processed (canonical hub, via the data junction)
* Output:  RP7/tests/stage0/baseline_root/output/ (ct baseline sters)
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
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_baseline_ct_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
