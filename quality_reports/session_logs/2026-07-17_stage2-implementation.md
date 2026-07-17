# Session log 2026-07-17 (second session): Stage 2 implemented and gated; Stages 1+2 closed

## If you resume

Stages 1 and 2 are COMPLETE and gated: the bundled Stage 1+2 refit ran on the promoted logpc hub and all 250 ster pairs are bitwise identical to the frozen baseline (gate artifact committed as 83bd3af; verdict CSV at [gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage1/gate_results.csv)).
Branch stage1-covariate-ladder carries the full arc: 577f0d2 (implementation), ffcaa27 (hub-rename verification), 83bd3af (gate PASS).
The next work is Stage 3 of the plan (front-load the estimation scaffolding, document the trajectory contract; Tier 3 allowed), which is Mode 2: it needs the Stage 3 plan section re-read, the MAJOR-4 keep-with-missing reminder DELIVERED TO THE AUTHOR AT KICKOFF (plan requires this), and a decision on whether Stage 3 bundles its gate with Stage 4 per D-5.
Consider merging or PR-ing stage1-covariate-ladder first; the author decides.

## Goals

Implement Stage 2 of the pipeline-frontload refactor per the approved plan section in [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), rebuild the processed hub with the new front end, and launch the bundled Stage 1+2 gate per D-5.
Everything shipped except the launch, which is blocked on the hub promotion.

## What got built or changed

`handle_depvar` in [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) now generates `logpc_`depvar'` (logpc_consumption or logpc_income) with the label text unchanged; the raw-log gens (ln_income, ln_consumption) stay.
The four GMM estimators (run_grc, run_grc_onestep, run_grc_robust, run_grc_robust_vv) reference logpc_consumption directly, which is deliberate: they take no depvar argument and post-D-2 never see an income cell, and an outcome option with a single possible value would be dead surface (the same reasoning that dropped the Stage 1 country-arg).
The OLS-side programs (reghdfe_regressions, the two learn variants, ugrc_regressions, heterogeneity_plots) use `logpc_`depvar'` because their depvar argument already exists.
All 32 redundant `replace lndepvar = log(consumption/hhsize_cube)` sites are deleted, with their `* ==>` comment and `sum ln*` eyeball lines.
Income estimation is removed per D-2: section 4 of [3_OLS_uGRC.do](file:///C:/git/ckt/RP7/scripts/3_OLS_uGRC.do), section 3 of [4_GrRC.do](file:///C:/git/ckt/RP7/scripts/4_GrRC.do), four income sections of [7_GrRC_hukou.do](file:///C:/git/ckt/RP7/scripts/7_GrRC_hukou.do), all spec3(iuu) stems in [9_GRC_extras.do](file:///C:/git/ckt/RP7/scripts/9_GRC_extras.do) and the run_extras_birth/run_extras_maxexpsh slice drivers, five income table blocks plus thirteen iuu extras_tex_table calls in [10_make_tables.do](file:///C:/git/ckt/RP7/scripts/10_make_tables.do), and the iuu branches in run_grc_with_extra_regressor and extras_tex_table (a surviving iuu call now errors loudly with rc 198).
The `_income.dta` builds in 1_processData.do are untouched.
Five files still hand-declared the covariate ladder that Stage 1 was supposed to single-source (5b_inversion, 5c_inversion_hukou, 10_make_tables, 17_verdier_robust, 17b_cluster_summary; the Stage 1 audit had only enumerated 4/5/7): all five, plus the scratch scripts, now call set_covariate_globals.
All seven gate-panel slices were re-sliced to match the edited sources; [gate_stage1.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1.do) gained the Verdier leg because the rename edits 17_verdier_robust.do; the compare driver and ct driver headers now describe the bundled Stage 1+2 gate.
[compare_hub_stage2.do](file:///C:/git/ckt/RP7/tests/stage0/compare_hub_stage2.do) is the new hub-equivalence checker.

## Verification

A smoke test built TZA consumption and income cells through data_setup and asserted logpc_* equals the per-capita formula bitwise, no lndepvar survives, and the covariate ladder resolves; N matched the no-op inventory exactly (29,864 and 9,339).
The hub was rebuilt with the new front end into RP7/data_rebuild via the Stage 0 rebuild driver and compared cell by cell: all 34 cells PASS as a pure rename (same rows, every common variable bitwise identical, logpc_* bitwise equal to old lndepvar); artifact at [hub_rename_check.csv](file:///C:/git/ckt/quality_reports/staging/stage2/hub_rename_check.csv).
A one-cell pre-gate probe fit TZA cuu ct on the rebuilt hub with the new code and gate_compared all five sters against the frozen baseline: PASS_BITWISE on all five, proving the chain end to end before the full gate.
critic-stata reviewed the full diff: no CRITICAL or MAJOR findings, 94/100; three MINOR doc-staleness items (stale iuu row in STER_NAMING.md, historical-artifact markers for stage0_checks.do and compare_hubs.do, drifted gate-panel banners) were applied through fixer-code and are in the implementation commit.

## Decisions, with the why

Hardcoding logpc_consumption inside the four GMM estimator programs, rather than adding an outcome option, follows the dead-surface principle: every remaining call path is consumption, and git history restores income if a referee asks.
The Verdier leg joined the bundled gate because Stage 2's rename necessarily edits 17_verdier_robust.do; the plan's "untouched until Stage 6" note was written from Stage 1's perspective and no longer holds (the Stage 6 suffix-bug fix itself remains deferred).
Income blocks were deleted outright, not commented, per the author's standing do-nothing-code preference and D-2's easy-to-restore-from-history rationale.
The hub promotion was left to the author after the permission classifier blocked the renames twice; given the 2026-06-23 data-loss history, surfacing beats working around.

## Approaches rejected and the reason

Repointing stage1_root's data junction at a composite rebuilt-hub location, to dodge the blocked promotion, was rejected: junction rewiring without author approval is exactly the action class behind the June data loss.
Waiting to commit until the gate passes was rejected again, per the standing commit-frequently lesson; Stage 1 set the precedent of committing implementation ahead of its gate artifact.

## Gotchas recorded

The gate-panel files under RP7/tests/stage0 are CRLF; perl patterns anchored on `\n` silently no-op there (the initial panel sweep renamed but failed to delete the replace blocks until rerun with `\r?\n`).
PowerShell cannot see `stata-mp`; detached launches need the full path `C:\Program Files\StataNow19\StataMP-64.exe` with `/e`.
A probe driver that bypasses 0_path_config.do leaves $grc_min_switchers_per_wave empty, which breaks initial_values' base-selection comparison with a confusing "invalid name" r(198); include the config and override $dirdata after.

## Afternoon update: hub promoted, gate launched and running

The author approved the hub promotion by running the first rename herself at 12:14; the second rename and the data_rebuild cleanup (junction removed via `cmd /c rmdir`, empty dir deleted) followed, so `RP7/data/processed` is now the 34-cell logpc hub with `processed_prelogpc_2026-07-17` and `processed_stale_2026-07-14` as backups.
The bundled Stage 1+2 gate launched at 12:15 as two detached Stata batches (full exe path `C:\Program Files\StataNow19\StataMP-64.exe` with `/e`; `stata-mp` is not on PowerShell's PATH).
The ct supplement batch finished at 14:24 with rc=0.
The main batch was at 195 of 250 sters by 20:41: every main GRC family complete (cuu and cub for all three countries, IDN cnu, both CHN hukou splits), the IDN experience extras stem in progress (about 35 minutes per column), the Verdier TZA leg still to come.
A persistent monitor watches gate_stage1_rc.txt and flags a dead Stata process without an rc file.
The main batch finished at 21:16 with rc=0 and 250 sters; gate_stage1_compare.do then verified ALL 250 pairs PASS_BITWISE (provenance exact, e(b)/e(V) byte-identical, max_crit_ratio 0 throughout), and the gate artifact was committed (83bd3af).
Total gate wall-clock: about nine hours across the two parallel batches.

Unrelated interlude: recovered the NCI Gadi allocation-form decisions from the 2026-07-11 home-workspace session log (Tier 1, NCI Gadi, 20 KSU over Q3-Q4 2026) and drafted the form answers at [2026-07-17_gadi-allocation-answers.md](file:///C:/Users/maand/.claude/quality_reports/session_logs/2026-07-17_gadi-allocation-answers.md).

## Open items

Hub promotion (author), then the gate launch, compare, and gate-artifact commit; see "If you resume."
RP7/data_rebuild currently holds the verified rebuilt processed files and a countries junction into RP7/data/countries; after promotion the leftover junction should be removed with `cmd /c rmdir` only, and the empty dir deleted (it is in .git/info/exclude).
D-4, whether the manuscript keeps its nonag promise, remains open with the author.
The run_extras_birth/run_extras_maxexpsh slice drivers still point $dir at the old grc-pipeline-refactor worktree; stale-scratch taxonomy is Stage 8 business.
Pre-existing untracked working-tree items (selftest/, older staging folders, stage0 gate dump txts) were left alone.
