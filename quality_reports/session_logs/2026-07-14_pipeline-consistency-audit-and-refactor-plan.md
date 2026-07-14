# 2026-07-14 --- Pipeline consistency audit, front-load refactor spec + plan, plan review

## If you resume

One-line state: the rebuilt data hub is promoted to canonical, the critic pass is adjudicated with findings frozen into Stages 3/4/8, the gate harness passed its self-test after two bug fixes, and the Stage 0 gate-panel baseline refit (roughly 70 GMM fits) is running as an independent stata-mp batch that survives the session ending.

Read first: this log in full, then the plan [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), the critic report [2026-07-14_pipeline-frontend-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-frontend-critic-stata.md), and its adjudication [2026-07-14_frontend-critic-adjudication.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_frontend-critic-adjudication.md).

Next concrete action: check whether the baseline refit finished.
The rc file is [gate_baseline_rc.txt](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline_rc.txt), where rc=0 means clean.
The ster count lives in [baseline_root/output/](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/output/), and the logs to check are `4_GrRC.log` and `5_GrRC_NonAg.log` in `RP7/scripts/logs/`, `gate_panel_hukou.log` and `gate_panel_extras.log` in the same place, and `17_verdier_robust.log` in `RP7/tests/stage0/`.
If everything is clean, run the determinism double-fit: re-run the `5_GrRC_NonAg` leg into a second output directory and `gate_compare` every ster pair against the baseline, expecting PASS_BITWISE.
Then open Stage 1 (single source for the covariate ladder, Tier 2 byte-identity gate).

Cached state, hub: the canonical processed data is now the rebuilt hub at [C:/git/ckt/RP7/data/processed](file:///C:/git/ckt/RP7/data/processed/) (per-capita outcome, Change A, C10).
The old hub is retained at [C:/git/ckt/RP7/data/processed_stale_2026-07-14](file:///C:/git/ckt/RP7/data/processed_stale_2026-07-14/) until the definitive run, and rollback is just swapping the rename back.

Cached state, baseline run: the first launch (23:30, whole-script legs) was KILLED at 00:20 after the user flagged that the first fit grinding for 45 minutes was the `_ct` no-covariate spec, a column dropped from the tables as a bad, slow spec; zero sters had been written, so nothing was lost.
The driver [gate_baseline.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline.do) was RELAUNCHED around 00:25 on 2026-07-15 via `stata-mp -e` from `RP7/tests/stage0`, now with every leg a slice: [gate_panel_main.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_main.do) (4_GrRC consumption blocks, cuu+cub x 3 countries, c1/c2/ca specs, 18 fits), [gate_panel_nonag.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_nonag.do) (IDN cnu, 3 fits), [gate_panel_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_hukou.do) (CHN_rf_cuu and CHN_uf_cuu, 6 fits), [gate_panel_extras.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_extras.do) (experience IDN cuu stem), and [gate_panel_verdier.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_verdier.do) (TZA only, full onestep/twostep x 5-spec VV grid, 10 fits).
CORRECTION (00:41): the `_ct` cut was wrong and is reversed; `grc_tex_table_trend`'s default `covs2set` is `ct c1 c2 ca`, so the shipped four-column GRC tables still read the `_ct` sters, and the column dropped by commit `c1a55ba` was `_c0` (no covariates, no time FE), which is already commented out in the scripts.
The author confirmed `_ct` stays in the tables, so a supplementary batch [gate_baseline_ct.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline_ct.do) (9 `_ct` fits: 6 main via [gate_panel_ct_main.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_main.do), 1 nonag via [gate_panel_ct_nonag.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_nonag.do), 2 hukou via [gate_panel_ct_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_hukou.do)) launched around 00:45 in PARALLEL with the main batch; disjoint ster names into the same shadow output, rc lands in [gate_baseline_ct_rc.txt](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline_ct_rc.txt).
Excluded from the baseline by author decision: every income (`iuu`) block, per D-2; Verdier IDN/CHN, per the plan appendix; the commented `_c0` calls (the column `c1a55ba` actually dropped).
The follow-up for Stage 2 changes accordingly: only the dead `_c0` comments and income blocks are removal candidates; `_ct` is live table code.
The slices were built programmatically with content assertions ([build_slices.py](file:///C:/Users/maand/AppData/Local/Temp/claude/C--git-ckt/6f4531b7-aa10-4c73-a728-e6fd75436c40/scratchpad/build_slices.py) in the session scratchpad); slice logs are `gate_panel_main/nonag/hukou/extras.log` in `RP7/scripts/logs/` and `gate_panel_verdier.log` in `RP7/tests/stage0/`.
The shadow root [baseline_root](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/) has `scripts/` and `data/` junctions into the live tree---remove only with `cmd /c rmdir`, never a recursive delete, and the directory is git-excluded via `.git/info/exclude`---plus a real `output/` that receives the baseline sters.

Cached state, deviations to remember: `5b_inversion` is excluded from the baseline because its Python module resolves paths relative to `$dir`, which the shadow root breaks, so the inversion baseline gets refit from the frozen GRC sters when Stage 5 arrives.
FOLLOW-UP FOR STAGE 2: the commented `_c0` calls still sit in `4_GrRC.do`, `5_GrRC_NonAg.do`, and `7_GrRC_hukou.do` and can be deleted with Stage 2's income-block removal; `_ct` is LIVE table code (see the correction above) and stays.

Cached state, gate harness: [gate_harness.do](file:///C:/git/ckt/RP7/tests/stage0/gate_harness.do)'s `gate_compare` now enforces a pass iff |new - old| <= max(1e-12, 1e-10 x |old|) per element (CSV column `max_crit_ratio`, <= 1 passes), takes a `basedir()` option pointing at the frozen baseline directory, and passed the three-way self-test in [selftest_gate.do](file:///C:/git/ckt/RP7/tests/stage0/selftest_gate.do).

Standing reminders: nothing ships to coauthors or Overleaf until the definitive run regenerates all sters and tables, since the current sters and paper tables were fit on the old hub.
At Stage 3 kickoff, remind the user about the MAJOR-4 keep-vs-drop choice (the plan's Stage 3 section carries the reminder text).
At Stage 4, the CRITICAL-1 fix has its predicted diff enumerated in the plan.

Uncommitted: `gate_baseline.do` and all five `gate_panel_*.do` slices (commit after the baseline run verifies).
Everything else from today is committed: `71c6d93` (Stage 0 evidence), `d8fecfe` (plan and reviews), `90a802e` (session log), and `76b6ea1` (harness and self-test).

---

## Mode

Implementation, planning phase only (Mode 2): review + spec + plan written and approved-pending; no file edits to the pipeline.

## Goal

The user wants a critical review of the whole data-cleaning and variable-construction pipeline plus `0_programs.do` before the final definitive run, to prevent a repeat of last session's GRC-vs-OLS per-capita inconsistency.
Stated wishes: front-load all cleaning/variable-creation/globals and never re-touch them in analysis scripts; eliminate in-place `replace` of existing variables (use `gen` for transforms); more than one agent per script plus an orchestrator; work backwards from the analysis scripts; review `0_programs.do` for best-practice tightening; implement modularly and verify after each stage; and a floated idea of generating the Stata scripts from Python.

## What was produced

Three artifacts, no pipeline edits:
findings report at [quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md);
spec at [quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md);
plan (revised after critique) at [quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).

## Review method

Five independent Explore readers (sonnet), two-look coverage of every analysis script: four cluster readers (OLS/FE; GRC family; inversion/learning/robust; summary/assembly) plus one global cross-check with fresh eyes.
Orchestrator read the front end directly (`data_setup` family, `handle_depvar`, `handle_balance`, `set_covariates`, `run_grc`, `1_processData.do`, `0_path_config.do`, `0_CHN_hukou_restrictions.do`).
The plan was then stress-tested by a fresh-context general-purpose critic (inherited model, judgment work) grounded in golden-master and floating-point-determinism best practices from two web searches.

## Key findings (from the report)

The load-bearing fact: the front end (`data_setup`, saved per-cell by `1_processData.do`) already persists 34 fully-built processed `.dta`, but analysis scripts do not trust them --- they re-mutate on top (redundant per-capita `replace`s, triplicated covariate globals) and the OLS scripts mix cached-`use` and live-`data_setup` provenance.
That one seam is the whole story.

No realized numerical bug in the mainline GRC/OLS estimates: every redundant `replace` is a verified no-op today.
The one realized correctness problem is C1: `11b_extrapolation_support_figure.do` builds the never-migrant reference line on raw `ln(consumption)`, not the per-capita scale the GRC estimates, and never reconciles against the ster.
C2 is a labeling decision: the IDN cnu x urbanbirth extras cell deliberately loads the urban dataset for a nonag-labeled cell (documented historical faithfulness).
Elevated to must-fix on user feedback: the inversion CIs reconstruct their sample instead of keying off `e(sample)` (M3), and `run_grc_robust_vv`'s internal `drop if missing(vfirst)` persists across the covariate loop (M4).

## Decisions, with the why

Python codegen rejected this cycle: it forks the pipeline off Stata-only coauthors right before freeze and adds a new failure surface; the same DRY guarantee is achievable in Stata via one construction site plus `0_programs.do`.
The user accepted this ("ok let's try your way") while noting coauthors would still only ever see Stata.

`clonevar` interpreted correctly per user: the rule is no overwriting of existing variables; use `gen` for transforms, reserve `replace` only where unavoidable and flag those. Not a literal ban on the `replace` keyword.

Rename target is `logpc_consumption` (user, Q2), and income is being dropped ("too many missing values") --- folded into Stage 2 as income-pathway removal, pending the user's confirmation that income is cut from the paper (project card lists it as the secondary outcome) rather than merely dormant.

The equivalence gate was redefined after critique from blanket byte-identity to a tiered gate: Tier 1 exact provenance (N, `e(sample)`, trajectory partition) always; Tier 2 byte-identity as the target for non-reordering stages (1, 2); Tier 3 a `1e-10` tolerance to adjudicate benign float-reorder reds only where a stage reorders rows (3, 4).
Reason: byte-identity as a single pass/fail line fires false reds on harmless reorders (float non-associativity in `vce(cluster pid)` summation) and would burn 3.5h refit cycles; but the April M4 verification shows byte-identity IS attainable on this machine, so byte-first-with-tolerance-fallback is stronger for the user's anti-inconsistency goal than a blanket tolerance.

Scaffolding (Q3): move `always`/`never`/`switcher_*` + the trajectory sentinel to disk (Option A), persisting the data-driven `$switchers` list as a dataset characteristic; fall back to a single-call program only if the gate goes red purely from reordering.

## Approaches rejected, with the reason

Blanket tolerance band (the critic's proposal): rejected in favor of tiered byte-first, because most stages are value-identical no-op removals where anything but bit-identity is a real bug worth flagging, and M4 proves bit-identity is reachable.
"One cell per country" verification: rejected as thin sampling that misses non-equivalent refactors; replaced by a fixed gate panel spanning every code path plus a full end sweep.
Trusting the "25 replaces / 15+ globals" counts: the aggregate was synthesized (only sub-counts like 4_GrRC=6, 7_GrRC_hukou=8 are verified), so the exact enumeration is now a mandatory Stage 0 artifact.

## Open items

Author decisions batched in the plan: D-1 (C2 cnu x urbanbirth, may need a coauthor's memory), D-2 (income cut vs dormant), D-3 (11b materiality, after the Stage 0 probe).
Stage 0 not started: harness, reproducibility proof on the gate panel, committed no-op inventory, N-reconciliation baseline, 11b materiality probe.
Change B (switcher-inclusion) folded in as Stage 9, judged against its own 2026-07-13 spec, not the equivalence gate.
The parallel launcher and the definitive re-run remain gated behind this refactor.

## How to pick back up

Get the two open decisions (income status, C2) from the user, then start Stage 0: build the golden-master harness reusing the 2026-04-30 M4 pattern, prove the gate panel refits byte-identically on unchanged code, produce the committed no-op inventory and N-reconciliation baseline, and run the 11b materiality probe.
Do not touch pipeline code before Stage 0's reproducibility proof passes; if the current pipeline is not run-to-run deterministic on the gate panel, resolve that before trusting any gate.

---

## Continuation (afternoon): plan review, Stage 0, and the stale-data discovery

This block supersedes the morning block's bottom line that there is "no realized numerical bug in the mainline GRC/OLS estimates."
Stage 0 found that the OLS and hukou-OLS consumption outputs are, right now, on the wrong scale, so that line no longer holds; see the critical finding below.

### Mode

Still Implementation, planning phase (Mode 2): the user first invoked `/review-plan` to stress-test the plan from the morning block, then ran Stage 0 of that plan, then invoked `/wrap-up`.
No pipeline code has been edited; Stage 0 is diagnostic only.

### What ran

Two Stage 0 do-files executed from [C:/git/ckt/RP7/tests/stage0/](file:///C:/git/ckt/RP7/tests/stage0/): `stage0_11b_probe.do` and `stage0_checks.do`.
A third, `gate_harness.do`, is drafted in the same directory but has not been run.
Outputs landed in [C:/git/ckt/quality_reports/staging/stage0/](file:///C:/git/ckt/quality_reports/staging/stage0/): [probe_11b.csv](file:///C:/git/ckt/quality_reports/staging/stage0/probe_11b.csv), [noop_lndepvar.csv](file:///C:/git/ckt/quality_reports/staging/stage0/noop_lndepvar.csv), [baseline_N.csv](file:///C:/git/ckt/quality_reports/staging/stage0/baseline_N.csv), and [environment.txt](file:///C:/git/ckt/quality_reports/staging/stage0/environment.txt).
A throwaway confirmation script, `confirm_scale.do`, was run from the scratchpad to pin down the CHN_unb scale discrepancy directly; it was not committed.

### Critical finding: the processed data hub is stale

The processed `.dta` hub at [C:/git/ckt/RP7/data/processed/](file:///C:/git/ckt/RP7/data/processed/) still holds raw log consumption, not the per-capita log(consumption/hhsize_cube) that last session's fix was supposed to produce.
On CHN_unb, `confirm_scale.do` found max|lndepvar - ln(consumption)| = 4.77e-07, effectively zero to float precision, against a mean of 0.45 and a max of 1.09 against log(consumption/hhsize_cube); `hhsize_cube` on that cell ranges from 1 to 2.96.
[noop_lndepvar.csv](file:///C:/git/ckt/quality_reports/staging/stage0/noop_lndepvar.csv) shows the same signature across all 34 processed cells: the divide-twice column is exactly double the single-divide column in every row (for example chn_unb: 1.08603 versus 2.17206), which is the algebraic fingerprint of an outcome that was never divided by household size at all.
The cause: last session's per-capita fix changed `handle_depvar` in source (commit `47b60e3`), but `1_processData.do` was never re-run afterward, so the fix never reached the saved data.
Last session's in-memory verification passed only because it exercised the new code path in memory without rebuilding the hub on disk.

Consequence for the estimation family: the GRC scripts (`4_GrRC`, `5_GrRC_NonAg`, `7_GrRC_hukou`, `5b`, `5c`, `8_learning`, `17`, `17b`, and the extras) each carry a load-time `replace lndepvar = log(consumption/hhsize_cube)`, so those `.ster` files are per-capita and correct.
The OLS and hukou-OLS scripts (`3_OLS_uGRC`, `6_OLS_uGRC_hukou`) and the figures built on `lndepvar` have no such `replace`, so their consumption outputs are on the raw scale right now, and the paper's OLS consumption tables are raw values currently mislabeled as per-capita.
This means the "redundant no-op replaces" the morning audit flagged are not no-ops against the on-disk data as it currently stands; they are the only thing making GRC per-capita, and they become true no-ops only after the hub is rebuilt.
The equivalence gate cannot treat all current `.ster` files as one baseline: the GRC-family sters are the byte-identical target to preserve, while the OLS, hukou-OLS, figure, and income outputs need a raw-to-per-capita correction that should be surfaced and approved, not silently gated away as a refactor artifact.

### 11b materiality, now with numbers

The 11b probe read directly from [probe_11b.csv](file:///C:/git/ckt/quality_reports/staging/stage0/probe_11b.csv).
For TZA, the never-migrant target moves from inside the switcher support on the raw scale (mu_dN 14.57, support [14.51, 15.35]) to below it on the per-capita scale (mu_dN 14.00, support starting at 14.05), a gap of about 0.055 log points and a close call.
For IDN and CHN the never-migrant target stays inside the support on both scales (IDN: 11.83 raw / 11.35 per-capita, both inside [11.50, 12.83] and [10.97, 12.39] respectively; CHN: 10.21 raw / 9.75 per-capita, both inside [9.82, 11.31] and [9.31, 10.96]).
So the earlier "cosmetic for IDN/CHN, claim-affecting for TZA" read from the morning block holds, and the mechanism is that rural never-migrant and switcher households differ in size, so the per-capita adjustment moves them differently.

### Other findings, carried and sharpened from the five-reader audit

The front end (`data_setup`, saved by `1_processData.do`) already persists all 34 cells, but the OLS scripts still mix cached-`use` and live-`data_setup` provenance on top of that saved data.
C1 stands: `11b_extrapolation_support_figure.do` builds `mu` on raw ln(consumption), not per-capita, and never reconciles against the ster.
C2 stands: the IDN cnu x urbanbirth extras cell loads the urban dataset for a nonag-labeled cell.
The covariate ladder is triplicated: `covs_gmm` globals from `set_covariates`, 48 hand-redeclaration lines across `4/5/7_GrRC`, and parallel locals in `run_grc_with_extra_regressor`.
There are 25 redundant `replace`-lndepvar sites in total, 24 hardcoded to consumption plus one parameterized central site.
The inversion CIs (`5b`/`5c`) reconstruct the sample instead of keying off `e(sample)`; `run_grc_robust_vv`'s drop-if-missing-vfirst persists across the covariate loop; the trajectory=999 sentinel is an undocumented on-disk contract; `set_covariates` tangles global definition with sample drops; the 2- and 3-wave `non_switcher` lists are hand-enumerated 60-way string lists; and `0_CHN_hukou_restrictions.do` writes derived datasets into the raw `countries/` folder.

### Decisions, with the why

C2 is now a fix, not a footnote: align the cnu x urbanbirth cell to the nonag definition, because the user called it definitely an error; this changes one extras number.
Income handling: keep building the income processed data, but do not run income results and cut income from the paper text, because income carries too many missing values; this is easy to restore if a referee asks, though it does remove income from the project card's listed secondary outcome.
The `lndepvar` rename is now parameterized rather than fixed to `logpc_consumption`: the new name is `logpc_` followed by the outcome, giving `logpc_consumption` for consumption cells and `logpc_income` for income cells, because the income data is still being built and a flat `logpc_consumption` name would mislabel it.
Scaffolding (Q3) stays Option A: move `always`/`never`/`switcher_*` and the trajectory sentinel to disk and persist the data-driven switchers list as a dataset characteristic, falling back to a single-call program only if the gate reddens purely from reordering.
The equivalence gate is confirmed as the tiered version from the morning block (exact provenance always, byte-identity as the target for non-reordering stages, a `1e-10` tolerance only where a stage reorders rows), now read together with the caveat above that OLS/hukou-OLS/figure/income outputs are expected to move, not stay byte-identical.
Coverage stays a fixed gate panel spanning every code path per stage, plus one full ster sweep at the definitive run, because thin one-cell-per-country sampling misses non-equivalent refactors.

### Approaches rejected, with the reason

Overwriting the canonical hub to verify the stale-data finding: rejected; any rebuild writes to a fresh location and compares against the current hub rather than overwriting it.
Trusting the "25 replaces / 15+ globals" counts as originally synthesized: rejected in favor of the Stage 0 count, which came out at 24 hardcoded plus 1 parameterized replace, and 48 covariate-global redeclaration lines.

### Stage 0 execution gotchas worth keeping

Stata's `-e` batch mode occupies the unnamed log slot, so a do-file's own `log using` then errors `r(604)`; the fix is to drop the explicit log, rely on the `-e` auto-log, and run from the target directory so the auto-log lands there.
Stata parses `/*` inside a `*` line comment as a block-comment opener, so a header path like `processed/*.dta` or `output/*.ster` silently comments out the rest of the file with no error and no execution; this bit `stage0_checks.do` twice before it ran clean.
The `grc_*_g.ster` files (the `nlcom`/post-results files) do preserve `e(N)`/`e(N_clust)`: all 54 read cleanly for the N-reconciliation baseline.

### Open items and blockers

The user is going to inspect the working code directly at [C:/git/ckt/RP7/scripts/](file:///C:/git/ckt/RP7/scripts/) to verify the stale-data finding before anything is rebuilt.
Pending decision: rebuild the processed hub now, to a fresh location, and quantify the OLS raw-to-per-capita movement, versus hold; both were offered, and the user chose to wrap up and inspect the code first.
Once confirmed, rebuilding the hub with current source is the true first step, ahead of resuming the staged refactor, followed by re-establishing a clean fully-per-capita baseline.
`gate_harness.do` is drafted but not run, and the gate-panel byte-reproducibility proof is not yet run, since it needs GMM refits held for go-ahead.
Change B (switcher-inclusion consistency) stays folded in as Stage 9.
The paper's OLS consumption tables are currently raw-scale and need correcting via the rebuild and re-run.
None of the Stage 0 do-files, the Stage 0 reports, or the three planning artifacts are committed to git yet; this wrap-up commits only the session log.

---

## Continuation (evening): stale-hub confirmation, three-commit characterization, plan revision, review adjudication

### Mode

Implementation, planning phase (Mode 2) continued: no pipeline code edited; the plan and review artifacts were updated.

### What was verified together with the user

The stale-hub diagnosis was walked through step by step at the user's request and every link confirmed against code and git.
Commit `47b60e3` changed `handle_depvar` from `gen lndepvar = ln(depvar)` to `gen lndepvar = log(depvar/hhsize_cube)`; the source at [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) carries the fix; the hub on disk predates it.
The GRC family (`4_GrRC`, `5_GrRC_NonAg`, `5b`, `5c`, `7_GrRC_hukou`, `8_learning`, `17`, `17b`, plus `10_make_tables` at three sites) each carry the load-time per-capita `replace`; `3_OLS_uGRC` and `6_OLS_uGRC_hukou` carry none, which is exactly the safe-vs-wrong divergence.
`3_OLS_uGRC` additionally mixes cached-`use` (stale raw today) and live-`data_setup` (per-capita today) provenance, so its current consumption cells are a mix of scales, not uniformly raw.
The user ran lines 14-23 of `1_processData.do` mid-session, which rebuilt `IDN_unb.dta` through current code; the file is deliberately kept, not reverted, as a byte-identity determinism probe for the coming rebuild.

### The user's pushback that reshaped the plan

The user pushed back on the expectation that the fresh hub would match the old hub except for `lndepvar`: if the earlier code had errors, the new data should not match.
Git confirmed this: three commits since the 2026-06-24 hub build change the saved data, `47b60e3` (per-capita scale), `a11e013` (Change A, strict-spec reflagging: `_bal` cells lose individuals, `_unb` cells change `unbalanced`/`unbalanced_choice` values), and `1e10113` (C10, `non_switcher` reclassified by observed movement, moves only for unbalanced workers).
Consequence: the current GRC sters are correct on scale but fit on pre-Change-A samples, so the entire current ster population is stale relative to committed source and cannot serve as the refactor gate baseline.
This supersedes the earlier "GRC sters are correct" line: correct on scale only.

### Decisions, with the why

The old-vs-fresh hub comparison is characterization, not equivalence: every diff must be attributable to exactly one of the three commit signatures, and any unattributable diff stops the stage.
The full GRC re-run happens exactly once, as late as possible (the definitive end run), because GRC fits are expensive; only the small gate panel is refit at Stage 0 to freeze the baseline (user decision).
The OLS movement is reported as a combined delta (scale plus Change A), not decomposed (user accepted the recommendation).
Until the definitive run, the paper's GRC tables stay pre-Change-A, so nothing ships to coauthors or Overleaf in between.

### Files changed

The plan [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) was revised before any run, per the user's instruction: Stage 0 rewritten around rebuild-first sequencing, gate baseline repointed to the Stage 0 panel refit on the rebuilt hub, D-1/D-2/D-3 marked resolved, Stage 2 aligned to the parameterized `logpc_` rename and the keep-building-income decision, end run documented as triple duty.
A fresh-context plan review arrived at [2026-07-14-pipeline-frontload-refactor-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14-pipeline-frontload-refactor-review.md) (verdict REVISE, two Reds).
My adjudication is at [2026-07-14_frontload-plan-review-adjudication.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_frontload-plan-review-adjudication.md): nine fixes accepted (full environment pinning restored, sortseed mechanism and Tier 2 failure path, fail-fast determinism preflight on the current hub, sign-off as characterization review, synthetic contract tests for Stages 5/6, end-sweep re-adjudication of Tier 3 acceptances, harness self-test, mixed tolerance criterion max(1e-12, 1e-10 x |old|), executability appendix, rollback sentence), two rejected (interim delivery checkpoint, would ship mixed-generation tables; pre-Stage 0 CHN_hukou relocation, an unguarded edit before a baseline exists).

### Open items

Awaiting user approval to fold the nine accepted review fixes into the plan.
After that, the rebuild go-ahead: create `RP7/data_rebuild/` (empty `processed/`, `countries` junction), run `1_processData.do` unmodified via a `$dirdata`-repointing driver, confirming first that it does not include `0_CHN_hukou_restrictions.do`.
The Stage 0 artifacts and planning documents remain uncommitted.

---

## Continuation (late evening): Stage 0 executed through the sign-off package

### What ran

The nine accepted review fixes were folded into the plan (tiered-gate section, fail-fast preflight, characterization-review sign-off, synthetic contract tests for Stages 5/6, end-sweep Tier 3 re-adjudication, harness self-test, mixed tolerance criterion, rollback section, gate-panel appendix).
The hub rebuild then ran: [rebuild_hub.do](file:///C:/git/ckt/RP7/tests/stage0/rebuild_hub.do) rebuilt all 34 cells into `RP7/data_rebuild/processed/` (fresh dir, `countries` junction to existing raw, `1_processData.do` unmodified, canonical hub untouched), clean log, minutes not hours.
The characterization ran via [compare_hubs.do](file:///C:/git/ckt/RP7/tests/stage0/compare_hubs.do) after one abort: a header comment containing `processed/*.dta` tripped the `/*` block-comment gotcha (same trap as stage0_checks last session) and silently commented out the whole script.
The OLS re-run ran via [ols_rerun_new.do](file:///C:/git/ckt/RP7/tests/stage0/ols_rerun_new.do) into `RP7/tests/stage0/ols_new/` (copyOverleaf pinned 0, own $logs, auto-log slot freed before the scripts' `log using`).

### Results

Characterization: every hub difference attributed to the three commits; memo at [hub_characterization_memo.md](file:///C:/git/ckt/quality_reports/staging/stage0/hub_characterization_memo.md).
The 3 unpredicted CHN bal drops are one pid (620123103) whose 2014 wave has missing age: old code kept the pid balanced then silently dropped that wave post-balance; Change A now reflags them, which is the exact inconsistency it was written to fix.
Determinism probe: batch rebuild of IDN_unb is `cf _all`-identical to the user's 19:45 interactive build; byte diffs are header timestamp plus uninitialized label-block padding only, so raw byte-compare of .dta across invocation modes is the wrong instrument (sters/e(b) dumps remain the gate instrument).
OLS movement: memo at [ols_movement_memo.md](file:///C:/git/ckt/quality_reports/staging/stage0/ols_movement_memo.md), full CSV at [ols_movement.csv](file:///C:/git/ckt/quality_reports/staging/stage0/ols_movement.csv).
Headline: pooled urban coefficient IDN 0.338 to 0.323, CHN 0.422 to 0.474, TZA 0.669 to 0.710; FE column IDN 0.072 to 0.084, CHN 0.105 to 0.142, TZA 0.094 to 0.110; no significance flips.
Verified mechanism: the column-1 shift equals minus the urban-rural gap in mean ln(hhsize_cube) (-0.0515 CHN, +0.0087 IDN, -0.0405 TZA); IDN also loses 793 person-waves whose hhsize_cube is missing, rows GRC already excluded.
Old hukou tables carry pre-C3 panel labels (all said Indonesia), so the table parser matches hukou rows by coefficient label.

### Open items

The user requested one fresh critic-stata pass over the data-construction pipeline before promotion; it is running, output due at [2026-07-14_pipeline-frontend-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-frontend-critic-stata.md).
Promotion (swap rebuilt hub to canonical, retain old as backup) is on hold pending that report plus the user's review of the two memos.
After promotion: gate-panel baseline refit (step five), then Stages 1-8.
Stage 0 artifacts, plan revisions, and this log remain uncommitted.

### Promotion (user-approved, 22:37)

The user approved promotion after reviewing the package (characterization memo, OLS movement memo, critic report, adjudication).
Executed: `RP7/data/processed` renamed to `RP7/data/processed_stale_2026-07-14` (backup, 34 files, retained until the definitive run); `RP7/data_rebuild/processed` moved in as canonical `RP7/data/processed` (34 files); the `data_rebuild/countries` junction removed with `rmdir` (junction-safe) and the empty `data_rebuild` deleted.
The critic pass artifacts: report at [2026-07-14_pipeline-frontend-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-frontend-critic-stata.md) (3 CRITICAL / 7 MAJOR / 5 MINOR, verdict do-not-promote), adjudication at [2026-07-14_frontend-critic-adjudication.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_frontend-critic-adjudication.md) (both CRITICALs verified empirically: C1 real at 9/4/2 person-waves, shared identically by both hubs; C2 closed by regenerating all four hukou intermediates cf-identical; recommendation promote, findings frozen into Stages 3/4/8).
The adjudication caught a hazard in the critic's C2 fix: including the hukou-restriction script in the rebuild driver would write through the countries junction into the raw folder.
Verification drivers persisted: [verify_c1.do](file:///C:/git/ckt/RP7/tests/stage0/verify_c1.do), [regen_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/regen_hukou.do).
Still pending user decision: the two driver-hygiene fixes (username guard, junction precondition) and formal sign-off on freezing the critic findings into Stages 3/4/8.
Next step: Stage 0 step five, refit the gate panel on the new canonical hub with unchanged code to freeze the baseline, plus the double-fit determinism proof.

---

## Continuation (night): critic adjudication, promotion executed, gate baseline launched, harness self-test

### Goals

Adjudicate the user-requested critic-stata pass before promotion, execute promotion, write the approved decisions into the plan, run Stage 0 step five (the gate-panel baseline) and the harness self-test while it runs, and wrap up for a fresh-context session.

### Critic pass

The fresh-context critic (sonnet) returned 3 CRITICAL, 7 MAJOR, and 5 MINOR findings, with a do-not-promote verdict.
The critic session had no Write tool, so the parent session persisted the report verbatim to [2026-07-14_pipeline-frontend-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-frontend-critic-stata.md).
Both data-relevant CRITICALs were verified empirically before adjudicating, via [verify_c1.do](file:///C:/git/ckt/RP7/tests/stage0/verify_c1.do) and [regen_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/regen_hukou.do).
CRITICAL-1 (the descriptors `nr_periods_obs`, `obs_per_individual`, and `pid_first_obs` go stale after `set_covariates` row drops) is real: 9/4/2 stale person-waves in CHN/IDN/TZA unb, 2/0/2 rows of pids lacking a first-obs flag, and 0/1/2 surviving singleton rows, identical in both hubs, so the defect cannot distinguish between them.
CRITICAL-2 (the rebuild driver skipped the hukou-intermediates prerequisite) closed empirically: all four `CHN_hukou_*.dta` files regenerate `cf`-identical from current source.
The adjudication at [2026-07-14_frontend-critic-adjudication.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_frontend-critic-adjudication.md) also caught a hazard in the critic's proposed C2 fix: including the hukou-restriction script in the rebuild driver would write through the countries junction into the raw folder.

### Decisions, with the why

The user approved promotion at 22:37 despite the critic's do-not-promote verdict, because the verdict reviewed the pipeline in absolute terms while the actual decision was old hub versus new hub, and every verified defect is shared identically by both hubs while the new hub corrects the outcome scale and carries Change A and C10.
Promotion was executed as renames: the old `processed` directory became `processed_stale_2026-07-14` (34 files, kept as rollback), the rebuilt hub moved in as the canonical `processed` (34 files), and the `data_rebuild` junction was removed with `rmdir`.

The user declined the `rebuild_hub.do` hygiene fixes (a username guard and a junction precondition), because no future hub rebuilds are planned and any future parallelization should be built more cleanly than this driver; the findings stay on record in the adjudication.

The user approved the findings-to-stages mapping and it is now written into the plan: MAJOR-4 goes to Stage 3, with the ruling that rows with missing or non-positive `hhsize_cube` keep a missing per-capita outcome (no drop, no imputation) plus a diagnostic; CRITICAL-1 and MAJOR-1/2/3/7 go to Stage 4, with the predicted diff enumerated; MAJOR-5 (a named master log) is now required in Stage 8; and MAJOR-6 (hukou files written out of the raw folder) is confirmed for Stage 8.

### Discussion: MAJOR-4 equivalence

The user pushed back on the MAJOR-4 ruling: since tables restrict to a common `e(sample)` across columns, keep-with-missing is effectively a drop.
The answer: the two approaches are equivalent for every estimate, since all estimators condition on the outcome, but not equivalent for summary-statistic denominators and wave-counting bookkeeping.
The user asked to be reminded at Stage 3 kickoff, and that reminder now sits in the plan's Stage 3 section.

### Baseline launch

Sters save to hardcoded `$dir/output` paths, so repointing `$output` alone does not redirect them.
The solution is a shadow root ([baseline_root](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/)) whose `scripts/` and `data/` are junctions to the live tree and whose `output/` is real, with the global `dir` pointed at it.
The shadow root is excluded from git via `.git/info/exclude`, because git would otherwise index the whole scripts tree twice through the junction.
The plan uses whole-script legs for `4_GrRC`, `5_GrRC_NonAg`, and `17_verdier` (bounded cost, no slicing-drift risk) and verbatim slices only for the two most expensive scripts (`7_GrRC_hukou`, cut from 60 to 10 calls, and `9_GRC_extras`, cut from 44 to 1 call).
The user noted this adds up to more fits than expected and accepted it, with the option to kill the run and slice `4_GrRC` too if it drags.

### Harness self-test

The user approved updating `gate_compare` to the plan's mixed criterion plus a `basedir()` option, then self-testing it on three known-answer pairs.
The self-test caught two real bugs on the first run.
A mata block's bare `end` inside `program define` terminated the program definition early, so every `gate_compare` call died with `r(198)` (the same parser collision the Stata conventions document for `python:` blocks), fixed by moving the logic to a file-level mata function `gate_cmp_mata` with a single-line invocation.
Mata's `fopen("w")` errors when the dump file already exists, so repeat gate runs would have crashed, fixed with `_unlink` before `fopen`.
A third snag: the self-test's explicit log name collided with the `-e` auto-log of the same name (`r(608)`), fixed by renaming to `selftest_gate_run.log`.
Final verdicts: PASS_BITWISE on a ster compared against itself, FAIL_TOLERANCE at a criterion ratio of 2e6 on a 1e-2 nudge, and PASS_TOLERANCE at a ratio of 0.2 on a 1e-9 nudge, with comfortable margins in both directions.

### Approaches rejected, with the reason

Running all five estimation scripts whole for the baseline was rejected: about 163 fits is definitive-run cost and contradicts the run-GRC-once-late decision.
Slicing every script was rejected: each hand-copied block is a drift risk against production code, so slices are used only where the savings are large.
Including `5b_inversion` in the baseline was rejected, for the Python path-resolution reason above.

### Open items

The baseline run is in progress; check the rc file and ster count on resume.
The determinism double-fit is pending.
Commit the three uncommitted Stage 0 drivers after the run verifies.
Stage 1 opens after that.
Decision 2 (driver hygiene) remains declined, with the findings on record.
