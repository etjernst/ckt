* **********************************************************************
* Phase 1b.6 dispatch smoke: exercise the cub (balanced) and iuu
* (income dataset) code paths in run_grc_with_extra_regressor +
* extras_tex_table on TZA (smallest sample). Tier 3 will be the
* comprehensive run --- this is just a 10-minute sanity check that
* dispatch + table-naming work for cub / iuu.
*
* Expected:
*   grc_TZA_cub_maxexp_{c1,c2,c3,ca}{,_n,_g}.ster  (10 sters)
*   grc_TZA_iuu_expsh_{c1,c2,c3,ca}{,_n,_g}.ster   (10 sters)
*   GRC_TZA_consumption_urban_bal_exp_max.tex
*   GRC_TZA_income_urban_unb_exp_sh.tex
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_setup.do"
include "$scripts/0_programs.do"

global copyOverleaf 0
global skip_if_exists 0

* TZA cub x exp_max: covers cub (balanced) + exp_max -> maxexp/_exp_max naming
run_grc_with_extra_regressor, country(TZA) spec3(cub) regressor(exp_max)
extras_tex_table, country(TZA) spec3(cub) regressor(exp_max)

* TZA iuu x exp_share: covers iuu (income dataset, no lndepvar replace) + expsh/_exp_sh naming
run_grc_with_extra_regressor, country(TZA) spec3(iuu) regressor(exp_share)
extras_tex_table, country(TZA) spec3(iuu) regressor(exp_share)

display as text "============ dispatch smoke complete ============"
exit, STATA clear
