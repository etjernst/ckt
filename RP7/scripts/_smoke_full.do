* **********************************************************************
* Overnight smoke driver (Phase 1b Tier 3): runs every GMM script that
* the ster-rename touched, producing fresh sters under the M11 naming
* scheme. SKIPS table generation (make_tables.do) so paper compilation
* on Overleaf is unaffected during the run.
*
* GMM scripts run, in order:
*   5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do, GRC_extras.do
* GRC_extras.do (Phase 1b.6) replaces the deleted files
*   10_GrRC_experience.do, 11_GrRC_max_experience.do,
*   12_GrRC_experience_share.do, 13_GrRC_max_experience_share.do,
*   14_GrRC_NonAg_experience.do, 15_GrRC_birth.do
*
* NOT included this run:
*   make_tables.do, make_figures.do --- run separately AFTER this
*     completes so .tex tables get refreshed in one atomic step
*     (then re-do paper macro swap in Overleaf to use \GRCtable).
*   1_processData.do, 0_CHN_hukou_restrictions.do --- would `save`
*     back to the Dropbox junction; processed .dta files already exist.
*
* skip_if_exists toggle (set below): 0 = fresh verification (overwrite
* every cell); 1 = resume-on-interrupt (preserve completed cells from a
* prior killed run). Default is 0 so that running this driver on changed
* code always recomputes; flip to 1 only when explicitly recovering.
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

* skip_if_exists controls whether run_grc reuses on-disk sters:
*   0 = OVERWRITE every cell (fresh end-to-end verification of changed
*       scripts; reproduces results from scratch).
*   1 = RESUME-ON-INTERRUPT (recovery from a killed run; preserves
*       any cell whose <estname>_g.ster is already on disk).
* Set this BEFORE every launch to match the run's purpose.
global skip_if_exists 0

* GMM scripts (write 5 sters per fit; M10 guard active).
include "$dir/scripts/5_GrRC.do"
include "$dir/scripts/6_GrRC_NonAg.do"
include "$dir/scripts/8_GrRC_hukou.do"
include "$dir/scripts/GRC_extras.do"

* Table builders skipped --- run make_tables.do separately AFTER this
* completes (then redo the paper macro swap in Overleaf).

* Show all per-fit elapsed times collected via M9 timer.
display as text "============ per-fit timer summary ============"
timer list

display as text "============ overnight smoke complete ============"
exit, STATA clear
