* *******************************************************************
* Title:   Stage 0 determinism double-fit (hukou leg)
* Author:  Emilia Tjernstrom
* Date:    2026-07-16
* Purpose: Refits the two hukou gate-panel cells (6 fits) into a
*          second shadow root on identical code and data; the pairs
*          must be bit-identical to the frozen baseline, proving the
*          pipeline is run-to-run deterministic on this machine.
* Input:   RP7/data/processed via the data junction
* Output:  RP7/tests/stage0/baseline_root2/output/
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/baseline_root2"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0

capture log close

capture noisily {
    include "C:/git/ckt/RP7/tests/stage0/gate_panel_hukou.do"
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_determinism_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
