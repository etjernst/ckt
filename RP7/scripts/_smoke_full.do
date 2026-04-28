* **********************************************************************
* Overnight smoke driver (Phase 1b Tier 3): runs every GMM script that
* the ster-rename touched, producing fresh sters under the M11 naming
* scheme. SKIPS table generation (make_tables.do) so paper compilation
* on Overleaf is unaffected during the run.
*
* GMM scripts run, in order:
*   5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do,
*   10/11/12/13_GrRC_*experience*.do,
*   14_GrRC_NonAg_experience.do, 15_GrRC_birth.do
*
* NOT included this run:
*   make_tables.do, make_figures.do --- run separately AFTER this
*     completes so .tex tables get refreshed in one atomic step
*     (then re-do paper macro swap in Overleaf to use \GRCtable).
*   1_processData.do, 0_CHN_hukou_restrictions.do --- would `save`
*     back to the Dropbox junction; processed .dta files already exist.
*
* M10 resume-on-interrupt guard enabled (global skip_if_exists 1):
* if killed and re-launched, run_grc skips any spec whose _g.ster
* file is already present (Phase 1a renamed the sentinel from _avg
* to _g). Force a fresh run by deleting all .ster files in $output.
*
* M9 timer is on --- each call to run_grc stashes elapsed seconds
* into its main ster as a custom scalar runtime (via estadd).
* timer list at end shows per-fit elapsed times.
*
* global copyOverleaf 0 --- this driver doesn't write tables, so no copies.
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

* Table builders skipped --- run make_tables.do separately AFTER this
* completes (then redo the paper macro swap in Overleaf).

* Show all per-fit elapsed times collected via M9 timer.
display as text "============ per-fit timer summary ============"
timer list

display as text "============ overnight smoke complete ============"
exit, STATA clear
