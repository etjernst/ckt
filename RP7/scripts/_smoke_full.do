* **********************************************************************
* Overnight smoke driver: runs every GMM script that the ster-rename
* touched, plus the table-builder. Skips the data-prep scripts that
* would write back to the Dropbox junction.
*
* Scripts run, in order:
*   5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do,
*   10/11/12/13_GrRC_*experience*.do,
*   14_GrRC_NonAg_experience.do, 15_GrRC_birth.do,
*   16_heterogeneity_tables.do.
*
* Skipped (would `save` to `$dirdata/...` = Dropbox junction):
*   1_processData.do, 0_CHN_hukou_restrictions.do.
*   The processed and hukou-restricted .dta files already exist in
*   the Dropbox junction from the coauthor's runs, so reads work.
*
* M10 resume-on-interrupt guard is enabled (global skip_if_exists 1),
* so if the run is killed and re-launched, run_grc skips any spec
* whose `_avg.ster` file is already present. To force a fresh run,
* delete `$output/*.ster` before launching.
*
* M9 timer is on by default --- each call to run_grc / run_grc_onestep
* uses a sequential `timer` slot and stashes elapsed seconds into the
* main ster as a custom scalar `runtime` (via estadd). After the run,
* `timer list` shows all per-fit elapsed times in slot order.
*
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

* M10: enable resume-on-interrupt. Re-launching this driver after a kill
* will skip any spec whose <estname>_avg.ster already exists.
global skip_if_exists 1

* GMM scripts (write 5 sters per fit; M10 guard active).
include "$dir/scripts/5_GrRC.do"
include "$dir/scripts/6_GrRC_NonAg.do"
include "$dir/scripts/8_GrRC_hukou.do"
include "$dir/scripts/10_GrRC_experience.do"
include "$dir/scripts/11_GrRC_max_experience.do"
include "$dir/scripts/12_GrRC_experience_share.do"
include "$dir/scripts/13_GrRC_max_experience_share.do"
include "$dir/scripts/14_GrRC_NonAg_experience.do"
include "$dir/scripts/15_GrRC_birth.do"

* Table builder (no GMM; reads sters that 5/6/etc wrote).
include "$dir/scripts/16_heterogeneity_tables.do"

* Show all per-fit elapsed times collected via M9 timer.
display as text "============ per-fit timer summary ============"
timer list

display as text "============ overnight smoke complete ============"
exit, STATA clear
