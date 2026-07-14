* *******************************************************************
* Title:   Stage 0 hub rebuild driver
* Author:  Emilia Tjernstrom
* Date:    2026-07-14
* Purpose: Rebuild the processed data hub from current source into a
*          fresh location (RP7/data_rebuild), leaving the canonical
*          hub at RP7/data untouched. Runs 1_processData.do unmodified
*          with $dirdata repointed after 0_path_config.do.
* Input:   RP7/data_rebuild/countries (junction to RP7/data/countries)
* Output:  RP7/data_rebuild/processed/ (34 .dta files)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"

include "$dir/scripts/0_path_config.do"
include "$dir/scripts/0_programs.do"

* Repoint the data root at the rebuild location. 1_processData.do reads
* raw files from $dirdata/countries and saves to $dirdata/processed.
global dirdata "$dir/data_rebuild"
capture mkdir "$dirdata/processed"

capture noisily {
    include "$dir/scripts/1_processData.do"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> REBUILD FAILED with rc=`saved_rc'"
}
else {
    di as text ">>> REBUILD COMPLETE: processed files written to $dirdata/processed"
}
