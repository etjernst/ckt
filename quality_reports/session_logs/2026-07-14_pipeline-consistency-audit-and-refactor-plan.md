# 2026-07-14 --- Pipeline consistency audit, front-load refactor spec + plan, plan review

## If you resume

One-line state: Stage 0 ran and found that the processed data hub is stale, still holding raw log consumption from before last session's per-capita fix, so the OLS and hukou-OLS consumption outputs are currently on the wrong scale and the true first step is rebuilding the hub with current source before any refactor edit proceeds.

Read first: this log in full, then the findings report [2026-07-14_pipeline-consistency-audit.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md), the spec [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md), and the plan [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).

Open thread: the processed data hub at [C:/git/ckt/RP7/data/processed/](file:///C:/git/ckt/RP7/data/processed/) is stale, because it holds raw log consumption from before last session's per-capita fix, so the OLS and hukou-OLS consumption outputs are currently on the wrong scale.

Next concrete action: once the user finishes inspecting [C:/git/ckt/RP7/scripts/](file:///C:/git/ckt/RP7/scripts/) to confirm the stale-data finding, rebuild the processed hub with current source into a fresh location rather than overwriting the current hub, confirm that the depvar is per-capita everywhere, and quantify how far the OLS and hukou-OLS consumption numbers move from raw to per-capita.
Then re-establish a clean per-capita baseline and resume the staged refactor.

Cached state: `$dir` for user maand is `C:/git/ckt/RP7`, and the working code lives in [C:/git/ckt/RP7/scripts/](file:///C:/git/ckt/RP7/scripts/).
The stale hub is [C:/git/ckt/RP7/data/processed/](file:///C:/git/ckt/RP7/data/processed/), and the sters are in [C:/git/ckt/RP7/output/](file:///C:/git/ckt/RP7/output/) (310 total, 54 are `grc_*_g` files).
The environment is StataNow 19.5 MP, 4 processors.
Stage 0 do-files live in [C:/git/ckt/RP7/tests/stage0/](file:///C:/git/ckt/RP7/tests/stage0/) and reports in [C:/git/ckt/quality_reports/staging/stage0/](file:///C:/git/ckt/quality_reports/staging/stage0/).
Uncommitted work includes all Stage 0 files, the three planning artifacts, and this log.

Two author decisions from the morning session are still open and block Stage 1 (not Stage 0): income status (cut vs dormant) and C2 (the cnu x urbanbirth cell).
`gate_harness.do` is drafted but not yet run; the gate-panel byte-reproducibility proof is held pending go-ahead on the rebuild above.

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
