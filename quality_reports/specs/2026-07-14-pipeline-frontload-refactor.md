# Spec: front-load the pipeline to a single construction site

Date: 2026-07-14.
Mode: Implementation.
Grounding review: [2026-07-14_pipeline-consistency-audit.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md).
Sequencing: this refactor precedes the parallel launcher and the definitive re-run, so the 7-hour run executes once on final code.

## Problem statement

Construction is duplicated between the front end (`data_setup` in `0_programs.do`, saved by `1_processData.do`) and the analysis scripts, which re-mutate the saved data.
That duplication is the seam behind last session's per-capita GRC-vs-OLS inconsistency and behind every latent divergence in the review.
The fix is to make the front end the sole construction site and reduce each analysis script to load-and-estimate.

## The load-bearing invariant: byte-identical unless a fix is named

Split the work into two classes.
Consistency refactoring (kill duplication, front-load construction) MUST leave every `.ster` byte-identical to the current committed set, because each removed `replace` is a verified no-op.
Correctness fixes (C1, M3, M4, C2, and Change B) MAY change specific numbers, but only where the change is named, isolated to its own stage, and approved.
Any byte difference in a consistency stage is a defect in that stage, and the verification gate must catch it before the stage is committed.

## MUST

M-1. The front end is the sole construction site.
Every variable any analysis or figure script consumes MUST be built once, in the `data_setup` family, and persisted to the processed `.dta`.
No analysis script may `gen`, `replace`, `egen`, or `recode` a variable that the front end already builds, nor re-impose a sample filter the front end already applies.

M-2. No overwriting of existing variables anywhere in the pipeline.
A transform produces a new, self-documenting named variable via `gen` (or `clonevar` for a pure copy); it never overwrites an existing slot in place.
Any residual `replace` that cannot be cleanly eliminated MUST be flagged in the plan with the reason, not silently kept.

M-3. Rename `lndepvar` to a self-documenting per-capita name (`logpccons` for consumption cells, `logpcinc` for income cells, or a single `logpc_outcome` parameterized by depvar), built once at source, parameterized by `` `depvar' `` (never the literal `consumption`).

M-4. Single source of truth for the covariate ladder.
The `$covs_gmm*` sets are defined in exactly one place; all hand-redeclarations in `4_GrRC.do`/`5_GrRC_NonAg.do`/`7_GrRC_hukou.do` and the parallel locals in `run_grc_with_extra_regressor` are removed and replaced by a reference to that one definition (a program call and/or a dataset characteristic stored at build time).

M-5. The inversion CIs key off `e(sample)`.
`attach_inversion_ci` (5b/5c) computes on the fitted ster's estimation sample, not a reconstructed one, so the CI $N$ always equals the GMM fit's $N$.

M-6. `run_grc_robust_vv` no longer mutates the in-memory sample in a way that persists across the covariate-spec loop.
Each spec in the Verdier loop starts from the same baseline sample (preserve/restore or a scoped working copy), and the resulting VV sters are byte-identical to the current ones.

M-7. C1 fix: `11b_extrapolation_support_figure.do` builds its $\mu_{\underline{d}}$ quantities on the per-capita outcome (or reads them from the ster, matching `_export_e1_inputs.do`), and the corrected figure is checked for whether it changes the in-support conclusion.

M-8. Verification after every stage.
Each stage runs its affected cells non-destructively into a fresh output directory and compares the resulting sters against the frozen baseline at full precision.
Consistency stages MUST show zero difference; correctness stages MUST show differences only in the cells named by that stage.
No stage is committed until its gate passes.

M-9. No writes to the data junctions or the raw folder during construction beyond the existing processed-file saves.
Derived hukou datasets move out of `data/countries/` (raw) into `data/processed/` (F4); raw inputs stay immutable.

M-10. Change B (switcher-inclusion consistency) is folded in: the front-end build authors the switcher keep-list once, persists it, and every estimator reads the identical list rather than recomputing it.

## SHOULD

S-1. The estimation scaffolding currently in `setup_grc_estimation` (the `always`/`never`/`switcher_*` construction and the `trajectory` sentinel) is built at the front end and saved to disk, so analysis scripts are truly load-only; the sentinel carries a documented value label (M5 of the review).
If moving it to disk risks a byte difference (e.g. the data-driven `$switchers` list), keep the program but make it the single call site and persist its metadata as a dataset characteristic.

S-2. Split `set_covariates` into a pure covariate-definition step and an explicit sample-restriction step, so construction and sample definition are no longer tangled (F2); the drops stay in the front end.

S-3. Replace the two hand-enumerated ~60-way `non_switcher` string lists with a computed rule (F3).

S-4. Collapse the three hand-coded never/switcher/always partitions (m4) to one shared indicator.

S-5. `1b_unbalanced_rank_diagnostic.do` cross-checks the shipped `switcher`/`non_switcher` rather than recomputing them, with an assertion tying the two (m2).

S-6. Fold `ln_income`/`ln_consumption` into the same per-capita naming discipline or drop them if unused, so no raw-scale outcome sits beside the per-capita one (F1).

## MAY

A-1. One named master log per the AEA pattern (F5).
A-2. Fix the `6_OLS_uGRC_hukou.do` literal-`CHN` eststo-naming so subgroup estimates are uniquely named (m6).
A-3. Flag or fix the `8_learning.do` `first_period_urban` missingness edge case (m5).

## Out of scope

The Python-codegen generation layer (rejected this cycle: forks the pipeline off Stata right before freeze; DRY is achievable in Stata via one construction site plus `0_programs.do`).
The parallel launcher and the definitive re-run (separate, sequenced after this).
Any change to identification, the estimator, or the set of reported specifications, except the named correctness fixes C1/C2/M3/M4/Change B.

## Decisions needed from the author before implementation

D-1. C2 (the IDN cnu $\times$ urbanbirth cell): keep the documented urban-dataset override, or align it to the nonag `cnu` definition? This changes a robustness-table number if aligned.
D-2. `logpccons` vs a single parameterized `logpc_outcome`: preference on the rename target.
D-3. Whether the estimation scaffolding moves fully to disk (S-1 strong form) or stays a single-call program with persisted metadata (S-1 fallback), decided by whichever keeps the byte-identical gate green.
