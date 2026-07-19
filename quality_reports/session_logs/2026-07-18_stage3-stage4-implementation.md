# Session log 2026-07-18 to 2026-07-19: Stages 3 and 4 implemented, gated, and closed

## If you resume

Stages 3 and 4 are COMPLETE: implemented, smoke-tested, critic-reviewed, gated (250/250 pairs as enumerated), author-signed-off, and the rebuilt hub is promoted to canonical.
Branch `stage3-frontload-scaffolding` carries the full arc and is merged to `main`.
The next work is Stage 5 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) (inversion CIs key off e(sample); correctness stage with a synthetic contract test and author sign-off), which has not been specced beyond its plan section.
Cached state a resumer should know: the canonical hub at `RP7/data/processed` now carries the Stage 3+4 build (GRC scaffolding dummies with labels, `_dta[grc_switchers]/grc_always/grc_never` contract, estimable-sample drops, corrected descriptors); `setup_grc_estimation` is a reader that exits 459 on contract-less data, so any scratch driver pointed at an old backup folder will fail loudly; backups `processed_prestage34_2026-07-19`, `processed_prelogpc_2026-07-17`, and `processed_stale_2026-07-14` stay until the definitive run; `stage34_root/output` holds the 250 gated refit sters with `skip_if_exists=1` drivers, and `stage34_root/data` points at the canonical hub.

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
