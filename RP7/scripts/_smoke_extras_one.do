* **********************************************************************
* Phase 1b.6 smoke: run ONE stem (TZA cuu x exp) via the new pipeline
* and verify sters land at disambiguated names + table cell builds.
* TZA cuu picked because it's the smallest sample.
*
* Expected outputs after success:
*   RP7/output/grc_TZA_cuu_exp_{c1,c2,c3,ca}.ster        (4 main)
*   RP7/output/grc_TZA_cuu_exp_{c1,c2,c3,ca}_n.ster      (4 never)
*   RP7/output/grc_TZA_cuu_exp_{c1,c2,c3,ca}_g.ster      (4 group-avg)
*   RP7/output/tables/GRC_TZA_consumption_urban_unb_exp.tex
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

* GMM
run_grc_with_extra_regressor, country(TZA) spec3(cuu) regressor(exp)

* Table
extras_tex_table, country(TZA) spec3(cuu) regressor(exp)

display as text "============ smoke complete ============"
exit, STATA clear
