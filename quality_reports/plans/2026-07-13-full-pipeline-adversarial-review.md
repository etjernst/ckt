# Plan: adversarial full-pipeline code review before the definitive re-run

Date: 2026-07-13.
Motive: we found an internal inconsistency (the switcher set differed across three co-reported estimators) and are about to commit to one definitive full-pipeline re-run that we do not want to repeat.
Before spending that run, audit every script for consistency with the paper and with the planned Change A + Change B, adversarially, one script per agent.

Primary question each agent answers: does this script do what the paper says it does, and is it consistent with the two planned changes?
Secondary: any internal bug, silent inconsistency, or dead/misleading path.

## What each agent gets

- The CKT project context (estimator, notation, key parameters).
- Its own script (the one-do-file-per-agent rule).
- The named `0_programs.do` programs that script calls (the connective tissue it depends on).
- The relevant paper section(s) from the Overleaf source (canonical), located by listing `sections/` and reading the matching file.
- The Change A + Change B spec and plan, so it flags anything the changes would break or anything already inconsistent with them.
- A clean rubric and a structured findings schema. No prior critiques or expected findings are seeded (fresh-context discipline).

Paper source (read-only): `C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/sections/`.
Change docs: the switcher-inclusion spec and plan dated 2026-07-13 in `quality_reports/{specs,plans}/`.

## Farm-out (one script per agent, 15 agents)

| Agent | Script | Key programs from 0_programs.do | Paper focus |
|---|---|---|---|
| data-construction | 1_processData.do | data_setup(+2/3waves), use_data, handle_choice/depvar/balance, handle_trajectory_groups(+variants), set_covariates, gen_time_trend, gen_vfirst | data section, sample and trajectory definitions (Change A lives here) |
| chn-hukou-setup | 0_CHN_hukou_restrictions.do | -- | hukou sample construction |
| summary-stats | 2_summaryStats.do | (summary table builders) | descriptive tables |
| rank-diagnostic | 1b_unbalanced_rank_diagnostic.do | -- | unbalanced-pooling appendix (prop:pooling) |
| ols-fe | 3_OLS_uGRC.do | reghdfe_regressions, ugrc_regressions, create_panel_tex_table | OLS/FE baseline results |
| grc-main | 4_GrRC.do | setup_grc_estimation, initial_values, define_switcherpars, run_grc | model + main GRC results (Change B lives here) |
| inversion | 5b_inversion.do (+ explorations/python-grc/lca_inversion.py) | attach_inversion_ci | weak-ID inversion inference (Change B) |
| nonag | 5_GrRC_NonAg.do | run_grc (nonag choice) | non-agricultural robustness |
| ols-hukou | 6_OLS_uGRC_hukou.do | reghdfe_regressions | hukou OLS |
| grc-hukou | 7_GrRC_hukou.do | run_grc, initial_values | hukou GRC split |
| learning | 8_learning.do | reghdfe_regressions_learn_IDN/CHN, create_panel_tex_table_learn_* | learning results |
| extras | 9_GRC_extras.do | run_grc_with_extra_regressor, extras_tex_table | experience-family robustness |
| tables | 10_make_tables.do | grc_tex_table_trend(+_robust), het_table_delta/mu, cluster_comparison_table, _ctab_cell | every result table's rows/labels vs the paper's reported tables |
| figures | 11_make_figures.do | heterogeneity_plots, grc_robustness_coefplot | paper figures |
| verdier | 17_verdier_robust.do | run_grc_robust, run_grc_robust_vv, grc_tex_table_trend_robust, gen_vfirst | Verdier robustness section |

## Output

Each agent returns structured findings (severity, category, file:line, description, paper reference, confidence).
The workflow returns the pooled set; I triage in-thread, adversarially escalating any uncertain CRITICAL/MAJOR to a fresh verifier before it reaches the fix list.
Findings land in a consolidated review report under `quality_reports/reviews/`.
No fixes are applied without approval (workflow Mode 3).
