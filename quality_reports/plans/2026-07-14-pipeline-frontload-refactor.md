# Plan: front-load the pipeline, staged with a tiered equivalence gate

Date: 2026-07-14 (revised after fresh-context plan critique).
Spec: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md).
Review: [2026-07-14_pipeline-consistency-audit.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md).

## Principle

Every stage is one logical change, implemented, then verified non-destructively against a frozen baseline before it is committed.
The pipeline stays runnable per-country and per-cell throughout (no collapsing into loops, per the standing convention).
Consistency stages must leave the estimates equivalent to the baseline; correctness and estimand stages change only their named cells.
Citations below are by program name and anchor string, not line numbers, because Stages 1-2 edit `0_programs.do` and shift every downstream line.

## The equivalence gate (tiered, byte-first)

The April 2026 M4 verification already showed that refits reproduce the committed sters bit-for-bit on this machine, so byte-identity is attainable, not aspirational.
The gate is therefore tiered rather than a single pass/fail line.

Tier 1, provenance (exact, always required).
Per cell: `e(N)` and `count if e(sample)` match baseline exactly; the trajectory partition (count of always / never / each switcher trajectory) matches exactly; the `e(sample)` membership is identical.
A provenance mismatch is a real change and stops the stage regardless of coefficients.

Tier 2, byte-identity (the target for stages that do not reorder rows).
Full-precision `%24.16e` dump of `e(b)`/`e(V)` is identical to baseline.
Stages 1 and 2 remove value-identical no-ops without touching row order, so they must be byte-identical; anything else is a bug.

Tier 3, tolerance adjudication (only when a stage legitimately reorders rows).
Stages 3 and 4 move construction and reorder drops, so `vce(cluster pid)` summation order can flip low-order bits under float non-associativity.
When Tier 2 goes red but Tier 1 passes and coefficients/SEs match to relative `1e-10`, the red is a benign reorder: accept and record it in the stage's gate artifact.
If Tier 1 fails or the tolerance is exceeded, stop and surface it.

Every stage commits its gate artifact (the provenance table and the diff result) alongside the code, so "why did cell X move" is answerable from history.

## Coverage: the gate panel

Per-stage verification runs a fixed gate panel, not ad hoc cells, chosen to exercise every distinct code path: each estimator type (OLS/FE, main GRC, non-ag GRC, hukou GRC, one extras stem, inversion, Verdier) crossed with all three countries, both balanced and unbalanced, and at least one switcher-sparse cell (a CHN hukou split).
The panel prioritizes fast cells so a stage gate is minutes, not hours.
The full `.ster` population is swept once at the end, when the definitive re-run happens, and compared cell-by-cell against baseline; that end sweep is the exhaustive characterization check, so no stage needs a full refit.

## Stage 0: freeze the baseline and prove the gate is meaningful (no pipeline change)

Preconditions, confirmed before any refactor:
pin `version`, the Stata flavor and MP core count (mata reduction order depends on it), and the installed package set, and record them in the gate artifact;
confirm the local data hub `C:/git/ckt/RP7/data` is populated and that `1_processData.do` regenerates the processed files it holds.

Deliverables committed at Stage 0:
a golden-master harness that refits a cell into a fresh output dir and runs the three-tier comparison against the baseline ster;
a reproducibility proof that the gate panel refits byte-identically on unchanged code (if any panel cell does not, the pipeline is not run-to-run deterministic and that must be resolved before trusting the gate);
the no-op inventory, an enumerated before/after variable diff for every `replace`/global the consistency stages will remove, run across all three countries, proving each is a no-op on the current data (this is the evidence base for Stages 1-2, not a plan assertion);
a per-cell N-reconciliation baseline table (`e(N)`, `e(sample)` count, trajectory partition) for the whole `.ster` population, cheap because it needs `data_setup` + counts, not refits;
an early 11b materiality probe: recompute the figure's mu quantities on the per-capita outcome (a mean recomputation, no GMM refit) and report whether the corrected scale changes the in-support conclusion, since a flip would change what the frozen results claim.

## Stage 1: single source of truth for the covariate ladder (consistency, Tier 2)

Define `$covs_gmm*` in one place (a `set_covariate_globals` program, country-arg for hukou), and additionally stash the resolved list as a dataset characteristic at build time.
Delete the hand-redeclarations in `4_GrRC.do`/`5_GrRC_NonAg.do`/`7_GrRC_hukou.do` and the parallel locals in `run_grc_with_extra_regressor`, replacing each with the one reference.
No row-order change, so the gate panel must be byte-identical.
Commit with gate artifact.

## Stage 2: de-mutate and rename the outcome, remove income (consistency, Tier 2)

Build the per-capita outcome once in `handle_depvar`, parameterized by `` `depvar' ``, and rename `lndepvar` to `logpc_consumption`.
Remove every redundant `replace ... = log(consumption/hhsize_cube)` site (enumerated by the Stage 0 inventory) and the central one in `run_grc_with_extra_regressor`, updating every consumer to the new name.
Remove the income pathway (the `_income.dta` builds in `1_processData.do` and the income blocks in `3_OLS_uGRC`/`4_GrRC`/`7_GrRC_hukou` and the `iuu` extras), pending the author's confirmation that income is cut from the paper, not merely dormant.
No row-order change, so the gate panel (consumption cells) must be byte-identical; income cells leave the panel with the pathway.
Commit with gate artifact.

## Stage 3: front-load the estimation scaffolding, document the trajectory contract (consistency, Tier 3 allowed)

Move the `always`/`never`/`switcher_*` construction and the `trajectory` sentinel into the front-end build so the processed `.dta` carries them, with a documented value label on the sentinel, and persist the data-driven `$switchers` list as a dataset characteristic the estimator reads back.
Reduce the analysis scripts to `use` + estimate; remove the now-redundant `drop if mi(logpc_consumption)|mi(choice)` re-filters in 5b/5c.
Build-time construction may reorder rows, so Tier 3 applies: Tier 1 provenance must be exact; a Tier 2 red is accepted only under the `1e-10` tolerance and recorded.
Commit with gate artifact.

## Stage 4: split set_covariates, tidy non_switcher and the partition (consistency, Tier 3 allowed)

Separate covariate definition from the sample drops; replace the two hand-enumerated `non_switcher` string lists with a computed rule; collapse the three partition re-implementations to one shared indicator.
Rebuild all processed files and diff variable-by-variable against the Stage 0 processed snapshot; the reordered drops make Tier 3 applicable to the sters.
Provenance (N, partition, `e(sample)`) must be exact; coefficients within tolerance.
Commit with gate artifact.

## Stage 5: inversion CIs key off e(sample) (correctness, contract not exercised today)

Change `attach_inversion_ci` (5b/5c) to compute on the fitted ster's `e(sample)` rather than a reconstruction.
This establishes a contract that is not currently exercised (zero missingness in the present covariates), so the CIs should match baseline today; a future data refresh with missingness would move them, which is the point.
Document the invariant.
Verify: refit the inversion panel cells; Tier 1 exact, Tier 2 expected; if any CI moves the reconstruction was already diverging, so stop and surface.
Author sign-off, then commit.

## Stage 6: clean up run_grc_robust_vv (correctness, contract not exercised today)

Make the Verdier loop start each spec from the same baseline sample (preserve/restore or a scoped working copy), so the internal `drop if missing(vfirst)` no longer persists across specs.
Same contract framing as Stage 5: expected byte-identical today, corrected for the general case.
Verify: refit the Verdier panel cells for all three countries; if any move, the persistence was affecting results and that is a finding, not something to absorb.
Author sign-off, then commit.

## Stage 7: fix the 11b figure scale (correctness, figure changes)

Rebuild `11b_extrapolation_support_figure.do`'s mu quantities on the per-capita outcome, or read them from the ster (matching `_export_e1_inputs.do`).
The materiality was already probed at Stage 0; this stage ships the fix and the corrected figure.
Author sign-off (a numeric change is expected), then commit.

## Stage 8: config hygiene (no estimate change)

Move the derived `CHN_hukou_*.dta` out of `data/countries/` (raw) into `data/processed/` and repoint the readers.
Script-folder taxonomy (user preference, 2026-07-14, to settle by discussion first): the leading underscore is currently overloaded, marking both throwaway dev scratch (`_smoke_*`, `_probe_*`, `_refit_*`, `test_*`) and load-bearing include-only helpers (`_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`, included by `12_counterfactuals.do`).
Proposed convention: a `scripts/helpers/` subdirectory for include-only helpers and a `tests/` or `dev/` subdirectory for the scratch, so the pipeline folder shows only numbered pipeline scripts plus clearly-marked entry points.
Optionally add the named master log, the hukou eststo-naming fix, the learning edge-case flag, and the 1b cross-check assertion.
Verify: full clean run of the cleaning path; confirm every processed file regenerates and the hukou readers resolve.
Commit.

## Stage 9: Change B, switcher-inclusion consistency (estimand change, human-approved)

Author the switcher keep-list once at the front end, persist it, and have every estimator read it.
This intentionally changes the estimand, per the switcher-inclusion spec [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) and its plan [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md).
Verify against that spec's acceptance criteria, not the equivalence gate.
Author approval, then commit.

## After all stages

Run the full pipeline once (serial or via the parallel launcher, the next project) on final code, and compare the full `.ster` population cell-by-cell against baseline as the exhaustive end characterization sweep.
Promote the fresh output to canonical and copy `RP7/{scripts,output}/` to Dropbox as the replication handoff.

## Decisions to resolve before Stage 1 (batched to avoid serial waits)

D-1. C2, the IDN cnu x urbanbirth cell: keep the documented urban-dataset override (and footnote it) or align it to the nonag definition (changes one extras number); may need a coauthor's memory of why urban was used.
D-2. Income: cut from the paper (remove the code paths in Stage 2) or dormant (leave the paths, do not rebuild)? Project card currently lists log income as the secondary outcome.
D-3. 11b materiality: after the Stage 0 probe reports whether the in-support conclusion flips, decide whether the fix is cosmetic or claim-affecting.

## Review and human gates

Each consistency stage: fixer applies, the harness confirms the tier result, `critic-stata` on the touched programs, then commit with the gate artifact.
Correctness and estimand stages (5, 6, 7, 9) and decisions D-1/D-2/D-3 require author sign-off before commit, since they can change reported numbers or a treatment definition.
Maximum five review-fix rounds per stage; unresolved issues stop the stage and surface.
