# Session log 2026-07-18 to 2026-07-19: Stages 3 and 4 implemented, gated, and closed

## If you resume

Stages 1 through 4 of the pipeline-frontload plan are COMPLETE: closed, merged to `main`, and pushed to origin (`main` == `origin/main` at `f73ab40`).
The next work is Stage 5 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md): change `attach_inversion_ci` (5b/5c) to compute on the fitted ster's `e(sample)` rather than a reconstruction.
Byte-identity is expected today, since covariate missingness is zero.
The stage also commits a synthetic contract test with injected missingness where reconstruction and `e(sample)` disagree by construction, then goes to author sign-off before commit.
Stage 5 has not been specced beyond its plan section; treat it as Mode 2 (spec, then plan, then implement).
Cached state a resumer should know: the canonical hub at `RP7/data/processed` carries the Stage 3+4 build (`logpc`, labeled scaffolding dummies, `_dta[grc_switchers]/grc_always/grc_never` contract, estimable-sample drops, corrected descriptors) with the three backups listed in the close-out section below; `setup_grc_estimation` is a reader that exits 459 on contract-less data, so any scratch driver pointed at an old backup will fail loudly; `stage34_root/output` holds the 250 gated refit sters with `skip_if_exists=1` drivers, and `stage34_root/data` now points at the canonical hub; the frozen baseline at `baseline_root/output` remains the reference for Stages 5 through 8; accepted movement at the definitive run covers the IDN Verdier robustness columns (`vfirst` reassignment, 45 pids) and the IDN OLS/summary-stat denominators; the 110 Tier 3 acceptances get re-adjudicated at the end sweep; D-4 (the nonag manuscript promise) is still open; `ugrc_regressions` is dead code slated for Stage 8; Stage 6 carries the mandatory Verdier table-suffix fix.

## Goals

Pick up after the Stage 1+2 close: merge, kick off Stage 3 per the plan (deliver the MAJOR-4 reminder, settle gate bundling), implement Stages 3 and 4, and run the bundled gate.

## Decisions, with the why

MAJOR-4 flipped to per-cell drop-at-source (author, 2026-07-18): rows no estimator can use (missing per-capita outcome) are dropped at build, so summary-stat denominators describe the estimable sample; the author's cross-approach smallest-common-sample variant was rejected because it would collapse the designed balanced/unbalanced and hukou distinctions and restrict headline estimates to a robustness check's sample.
The drop runs LAST in the build, after all classification construction, so trajectory strings and switcher classifications keep the full observed choice history and every surviving value is bitwise unchanged.
The 999 trajectory sentinel stays OUT of the saved data: the only live `i.trajectory` consumer (`heterogeneity_plots`) runs after the reader, and `ugrc_regressions`---the sole `i.trajectory` path without the reader---has no call site (dead code, Stage 8 deletion candidate); an earlier rationale wrongly attributed `i.trajectory` regressions to `3_OLS_uGRC`/`6_OLS_uGRC_hukou` and was corrected in plan and comments (70f7c02).
`vfirst` stays computed at estimation time on the estimable sample (author, 2026-07-19 sign-off covers the movement): 45 IDN pids change Verdier cluster assignment; the freeze-at-build alternative was declined because a wave without an estimable outcome should not seed the cluster index.
Individuals with exactly one estimable wave but a longer observed history are KEPT (author, 2026-07-18): 205 in IDN_unb, 89 in nonag; dropping them is deferred as a deliberate Stage 9-class decision because it would shrink gated estimation samples.
Stages 3 and 4 bundled their gate per D-5 (author, 2026-07-18), accepting that a red bisects between the stages.
Variable labels on the scaffolding dummies and the `_dta[grc_never]` characteristic were author-approved after checking that all table calls pass explicit coeflabels.

## What got built

Stage 3 (af67f7e): `handle_grc_scaffolding` builds the always/never/switcher_* dummies at source and stashes the trajectory contract as dataset characteristics; `handle_estimable_sample` drops missing-outcome person-waves as the last build step; `setup_grc_estimation` became a contract reader (exit 459 without it) keeping only the load-time 999 recode; redundant re-filters removed from 5b/5c.
Stage 4 (4d42d27): `set_covariates` split into definitions (`set_covariates`, dead depvar arg deleted) and counted drops (`handle_sample_drops`), with the CRITICAL-1 descriptor recompute before the singleton test; `refresh_descriptors` (factored after the critic found the `_2waves`/`_3waves` twins stale, which would silently drop individuals from figure panels) reruns after the estimable-sample drop; `isid pid period` in `use_data`; counted attrition messages replace the broken `r(N_drop)` strings; the two hand-enumerated non_switcher string lists became a computed all-same-string rule.
Gate scaffolding (9c971e4): `compare_hub_stage34.do` (enumerated-delta hub check), `stage34_root` shadow root, `gate_stage34.do`/`gate_stage34_ct.do` batch drivers, `gate_stage34_compare.do` adjudicator.

## Verification

Smokes: `smoke_stage3.do` and `smoke_stage4.do`, both all-PASS, with row-by-row equality against the old constructions emulated from the canonical hub and exact N transitions.
critic-stata reviewed each stage's diff (83/100 and 84/100, no CRITICAL); its Stage 3 MAJOR (degenerate-trajectory guard) and Stage 4 MAJOR (suffixed-descriptor staleness) were both fixed and re-smoked.
Hub rebuild compared 34/34 PASS on the enumerated-delta check ([hub_stage34_check.csv](file:///C:/git/ckt/quality_reports/staging/stage34/hub_stage34_check.csv)).
Bundled gate: 250/250 pairs as enumerated---140 PASS_BITWISE, 110 EXPECTED_N_CHANGE at exactly e(N)-1 (IDN cuu family) and e(N)-2 (TZA cuu and Verdier), coefficient movement max 2.3e-2 relative ([gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage34/gate_results.csv), [moved_movement.csv](file:///C:/git/ckt/quality_reports/staging/stage34/moved_movement.csv)); author signed off 2026-07-19 (abad0a6).

## Gotchas recorded

Stata's `dir` extended macro lowercases filenames on Windows, so estname regexes in compare drivers must match lowercased names (first adjudication pass mislabeled all 110 expected rows).
The gate harness skips the b/V comparison when provenance differs, so N-changing cells need their coefficient movement computed directly from the ster pairs.
`bysort pid:` alone on tie-ordered data risks nondeterministic reorder; every new bysort uses the unique `pid year` key on pre-sorted data.

## Open items

The IDN Verdier robustness columns and the OLS/summary-stat IDN numbers move at the definitive run (accepted, enumerated); the 110 Tier 3 acceptances are re-adjudicated at the end sweep.
D-4 (nonag promise in the manuscript) remains open.
`ugrc_regressions` is dead code slated for the Stage 8 taxonomy sweep.
Stage 5 next; Stage 6 carries the mandatory Verdier suffix-bug fix.

## 2026-07-19 close-out: gate adjudicated, signed off, hub promoted, merged and pushed

Both detached batches finished overnight with rc=0, about 8.5 hours, 250 sters covering the full panel.
`gate_stage34_compare.do` adjudicated all 250 pairs exactly as enumerated: 140 PASS_BITWISE (every CHN cell including both hukou splits, IDN nonag, all balanced cells) and 110 EXPECTED_N_CHANGE (`grc_IDN_cuu*` at `e(N)-1`; `grc_TZA_cuu*` and `vv_TZA_*` at `e(N)-2`), with nothing outside those two buckets.
The first adjudication pass mislabeled all 110 expected rows: Stata's `dir` extended macro lowercases filenames on Windows, so the case-sensitive estname regexes matched nothing.
Matching on `lower(estname)` fixed it.
The gate harness skips the b/V comparison when provenance differs, so coefficient movement for the 110 moved pairs was computed directly from the ster pairs: max relative `e(b)` change ranged 1.9e-13 to 2.3e-2, mean 1.0e-3, with the largest movers a Verdier TZA two-step trend subgroup coefficient (2.3%) and IDN extras c3 per-trajectory deltas (2.0%).
Artifacts: [gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage34/gate_results.csv) and [moved_movement.csv](file:///C:/git/ckt/quality_reports/staging/stage34/moved_movement.csv).
Commit `abad0a6`.

The author signed off on the 110 N-changing cells at midday ("I think this is fine, I approve those changes").
The hub was promoted: `RP7/data/processed` renamed to `processed_prestage34_2026-07-19` as a backup, and `RP7/data_rebuild/processed` moved in as the new canonical `RP7/data/processed`.
Verification: the IDN cell loads with N=92,449, the trajectory contract holds (switchers 2 through 31, always 32, never 1), variable labels are present, and logpc has zero missing values.
`RP7/data_rebuild` was then removed: the `countries` junction was deleted with `cmd rmdir` only, the raw countries folder was verified intact (7 dta files) afterward, and the emptied directory was removed.
`stage34_root/data` was repointed from `data_rebuild` to `C:/git/ckt/RP7/data`, matching the `stage1_root` convention.
Three backups stay until the definitive run: `processed_prestage34_2026-07-19`, `processed_prelogpc_2026-07-17`, and `processed_stale_2026-07-14`.
The plan was updated to close Stages 3 and 4, with the 110 accepted N-changes recorded as Tier 3 acceptances to be re-adjudicated against the full population at the end sweep.
Branch `stage3-frontload-scaffolding` merged to `main` (merge commit `f73ab40`) and was pushed to origin with the author's explicit approval (`f92e351..f73ab40`).
Project memory was updated to record the hub state, and MEMORY.md was compacted under its size limit by moving workspace and hub history detail out to a separate reference file.
