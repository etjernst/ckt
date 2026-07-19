# Plan: Stage 5, inversion CIs key off e(sample)

Date: 2026-07-19.
Spec: [2026-07-19-stage5-inversion-esample.md](file:///C:/git/ckt/quality_reports/specs/2026-07-19-stage5-inversion-esample.md) (approved 2026-07-19 with decisions: markers for every fit, loud-warning fallback; per-cell marker files are the working choice pending confirmation at this plan's approval).
Parent plan: Stage 5 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).
Branch: `stage5-inversion-esample`, cut from `main` at `78360cf` or later.
Execution follows the coordinator pattern in rules/model-routing.md: mechanical edit and batch legs go to `model: "sonnet"` subagents with precise briefs; the contract design, gate adjudication, and anything touching estimation semantics stay in the main thread.

## Step 1: marker writer in the fitter programs

Add a small helper program (`save_esample_marker`, taking the estname, suffix global, and output dir) to `0_programs.do` that snapshots `pid` and `period` for rows with `e(sample) == 1` and saves `<estname>${vsfx}_esample.dta` next to the ster, under `preserve`/`restore` so the data and the in-memory estimates are untouched.
The marker file carries a dataset label naming the source ster and the fit date, and variable labels on `pid` and `period`.
Call the helper immediately after the parent `estimates save` in every fitter that saves a parent ster: `run_grc`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`, and the extras path if it fits its own `gmm` rather than dispatching to `run_grc` (enumerated by grep at implementation; the exact call-site list goes in the gate artifact).
The `_n`/`_a`/`_d`/`_g` suffix saves get no marker; they rest on the parent fit.
The addition to `run_grc_robust_vv` is purely additive (one call after the parent save) so it does not entangle Stage 6's sample-persistence fix.
No change to any `gmm` call, its inputs, or their order: refit sters must stay byte-identical.

## Step 2: attach_inversion_ci reads the marker

`attach_inversion_ci` looks for `<estbase>_esample.dta` in the ster directory.
Marker present: merge on `pid period` against the data in memory, hard-error (named exit code) if any marker row fails to match a data row, build a byte flag, and pass the flag's column name to Python.
After the merge, formally re-declare the sample on the loaded estimates via `estimates esample:` using the merged flag, so the in-memory results carry a true `e(sample)` and any Stata-side consumer can condition on `if e(sample)` rather than on our flag variable (`estimates esample:` declares a sample, it cannot recover one, which is why the marker file remains the durable record).
Marker absent: print a prominent multi-line warning naming the missing file and stating that the sample is being reconstructed, then proceed with the flag unset (Python falls back to its reconstruction).
Both paths: after the Python call, assert that the row count the inversion computed on (returned by Python, step 3) equals the parent ster's `e(N)`; a mismatch is a hard error naming both counts.

## Step 3: Python computes on the flag

`compute_all_inversion_cis` gains an optional `esample` column argument: when set, the estimation subset is `df[df[esample] == 1]` and the old `dropna` becomes an assert that this subset carries no missing values in the needed columns (excluding `trajectory`); when unset (legacy callers, the standalone runners), behavior is unchanged.
`attach_inversion_for_stata` gains the same argument, includes the flag column in the `Data.getAsDict` pull, and writes the realized estimation-row count back as a Stata local so step 2's assert can compare it to `e(N)`.
The count is returned in both the flag and fallback paths.
Docstrings and the `attach_inversion_ci` header state the contract per spec M5-4.

## Step 4: smoke test

`RP7/tests/stage0/smoke_stage5.do`: on the canonical hub's IDN cell, fit one fast cuu spec into a scratch dir, confirm the marker file exists with exactly `e(N)` rows and the right label, run the attach through the marker path, and confirm the `e(N)` assert passes and the attached scalars are present.
Also exercise the fallback: delete the marker copy, re-run the attach, confirm the warning fires and results are identical (zero missingness today makes reconstruction equal the marker sample).

## Step 5: synthetic contract test

`RP7/tests/stage0/contract_stage5_esample.do`, per spec M5-5: build a scratch copy of a small cell with missingness injected into one GMM covariate for a known set of person-waves, fit (those rows leave `e(sample)`), write the marker, then fill the injected missingness in the loaded data to simulate a data refresh.
Assert the attach computes on the marker count, not the reconstruction's larger count; assert the fallback path on the same data trips the `e(N)` assert instead of silently attaching wrong-sample CIs.
This is the test that distinguishes the new code from the old where byte-identity cannot.

## Step 6: gate, two legs, detached

Baseline: the Stage 3+4 gated sters (with attached inversions) in `RP7/tests/stage0/stage34_root/output`; comparison is Tier 2 full-precision dumps of `e(b)`/`e(V)` plus the `inv_*` scalars and CI strings.
Leg A, fallback equivalence: run the new 5b/5c attach against fresh copies of the baseline sters (no markers exist for them), with `skip_if_exists` unset; expect the warning on every cell and attached results identical to baseline.
Leg B, marker mainline: refit the inversion-consuming parent cells (3 countries x 5 specs for 5b, 2 hukou subsamples x 5 specs for 5c) with the new code into a scratch output; the parent sters must be byte-identical to their Stage 3+4 gate counterparts (the marker write cannot touch the fit); then run 5b/5c through the marker path and compare attached results to baseline.
Tier 1 provenance exact throughout; any CI movement means the reconstruction was already diverging, which stops the stage per spec M5-6.
Launch as detached batches per the detached-Stata-batches convention (leg B's GMM refits are the cost; expect low single-digit hours based on the Stage 3+4 gate rate).

## Step 7: review and close

`critic-stata` on the touched programs and test drivers; fix or record findings per the review loop.
Assemble the gate artifact (marker call-site list, leg A and leg B comparison tables) under `quality_reports/staging/stage5/`.
Author sign-off on the gate artifact, then commit code, tests, and artifact; merge `stage5-inversion-esample` to `main` after sign-off, matching the Stage 3+4 close pattern.

## Rollback

The branch reverts cleanly: markers are additive files, `attach_inversion_ci`'s fallback path preserves today's behavior, and no data or hub state changes in this stage.

## Out of scope

The Verdier loop persistence fix and table-suffix fix (Stage 6), the 11b figure scale (Stage 7), any change to fit samples or moment conditions, and any backfill of markers for legacy ster populations (spec MAY-1, not built).
