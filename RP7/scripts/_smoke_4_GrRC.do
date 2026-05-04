* **********************************************************************
* Smoke-test driver for 5_GrRC.do (M8 of the refactor spec).
* Runs only the 0_* preliminaries + 5_GrRC.do. Skips 1_processData.
* Reads processed .dta files from the data junction (Dropbox RP6/data,
* read-only for this run). Writes .ster and tables to RP7/output/.
* Do NOT save this file to the production master pipeline.
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_setup.do"
include "$scripts/0_programs.do"

global copyOverleaf 0

include "$dir/scripts/5_GrRC.do"

* Print every per-fit timer slot in one place so log readers don't have
* to scroll through GMM output to find them.
display as text "============ M9 timer list (one row per slot) ============"
timer list

* Suppress the Windows batch-mode "Stata finished" popup (on success).
exit, STATA clear
