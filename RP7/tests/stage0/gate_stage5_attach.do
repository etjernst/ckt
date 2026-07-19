* *******************************************************************
* Title:   Stage 5 gate attach: fallback leg (A) then marker leg (B)
* Author:  Emilia Tjernstrom
* Date:    2026-07-19
* Purpose: Copies the Stage 5 refit sters into two leg directories and
*          runs the production inversion scripts against each. Leg A
*          holds sters only (markers removed), so every cell takes the
*          loud-warning fallback path, which is the old computation.
*          Leg B holds sters plus markers, the new mainline. The legs
*          run sequentially in this one batch because both write
*          $logs/5b_inversion.log; leg A's logs are copied aside
*          before leg B starts. gate_stage5_compare.do then requires
*          identical inv_* results across the legs.
*          Run only after both refit batches report rc=0.
* Input:   stage5_root/output (refit sters + markers), canonical hub
* Output:  stage5_legA_output/ and stage5_legB_output/ (attached sters)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7/tests/stage0/stage5_root"

include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"
global copyOverleaf 0
global skip_if_exists ""

* 0_programs.do resolves the lca_inversion module path relative to $dir,
* which points at the shadow root here; pin the real location (test
* drivers hardcode the per-user path per project convention)
python:
import sys
_P = "C:/git/ckt/explorations/python-grc"
if _P not in sys.path:
    sys.path.insert(0, _P)
end

capture log close

capture noisily {

    local src  "C:/git/ckt/RP7/tests/stage0/stage5_root/output"
    local legA "C:/git/ckt/RP7/tests/stage0/stage5_legA_output"
    local legB "C:/git/ckt/RP7/tests/stage0/stage5_legB_output"
    capture mkdir "`legA'"
    capture mkdir "`legB'"

    local sters : dir "`src'" files "*.ster"
    local n_sters : word count `sters'
    if `n_sters' == 0 {
        di as error "gate_stage5_attach: no sters in `src'; run the refit batches first"
        exit 601
    }
    foreach f of local sters {
        copy "`src'/`f'" "`legA'/`f'", replace
        copy "`src'/`f'" "`legB'/`f'", replace
    }
    local mks : dir "`src'" files "*_esample.dta"
    local n_mks : word count `mks'
    di as text "gate_stage5_attach: `n_sters' sters copied to each leg; `n_mks' markers to leg B only"
    foreach f of local mks {
        copy "`src'/`f'" "`legB'/`f'", replace
    }

    * ---- leg A: no markers, every cell takes the fallback path
    global inversion_sterdir "`legA'"
    include "$dir/scripts/5b_inversion.do"
    include "$dir/scripts/5c_inversion_hukou.do"
    copy "$logs/5b_inversion.log" "$logs/5b_inversion_legA.log", replace
    copy "$logs/5c_inversion_hukou.log" "$logs/5c_inversion_hukou_legA.log", replace

    * ---- leg B: markers present, every cell takes the marker path
    global inversion_sterdir "`legB'"
    include "$dir/scripts/5b_inversion.do"
    include "$dir/scripts/5c_inversion_hukou.do"
    copy "$logs/5b_inversion.log" "$logs/5b_inversion_legB.log", replace
    copy "$logs/5c_inversion_hukou.log" "$logs/5c_inversion_hukou_legB.log", replace
}
local saved_rc = _rc
capture log close

tempname fh
file open `fh' using "C:/git/ckt/RP7/tests/stage0/gate_stage5_attach_rc.txt", write replace
file write `fh' "rc=`saved_rc'" _n
file close `fh'
