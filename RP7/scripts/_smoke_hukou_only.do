* **********************************************************************
* Smoke driver: 7_GrRC_hukou.do only.
*
* Verification driver for the run_grc_hukou -> run_grc merge (commit
* 5c3308b). With skip_if_exists 1 and ro/uo subgroup sters deleted
* (2026-04-30), this run will:
*   - SKIP all rf and uf hukou cells (their _g.ster files exist)
*   - REFIT all 30 ro and uo cells (15 each) under the merged run_grc,
*     producing 5 sters per cell (main, _n, _a, _g, plus the new _d).
*
* Wall time estimate: 1-2 hours for ~30 fits on the smaller hukou
* subsamples.
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_setup.do"
include "$scripts/0_programs.do"

* Don't write to Overleaf during the verification run.
global copyOverleaf 0

* Resume-on-interrupt: skip cells with an existing _g.ster.
global skip_if_exists 1

* Run only the hukou regressions.
include "$dir/scripts/7_GrRC_hukou.do"

display as text "============ per-fit timer summary ============"
timer list

display as text "============ hukou-only smoke complete ============"
exit, STATA clear
