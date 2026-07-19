# Spec: Stage 5, inversion CIs key off e(sample)

Date: 2026-07-19.
Mode: Implementation (correctness stage; author sign-off required before commit).
Parent spec: M-5 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md).
Plan section: Stage 5 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).

## Problem statement

`attach_inversion_ci` (called by `5b_inversion.do` and `5c_inversion_hukou.do`) does not see the GMM fit's estimation sample; it reconstructs it.
The Python helper (`compute_all_inversion_cis` in [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py)) drops rows with missing values in the outcome, choice, controls, and unbalanced columns and treats the survivors as the fit sample.
Today the reconstruction and the true `e(sample)` coincide, because the Stage 3 build drops missing-outcome rows at source and the present covariates have zero missingness.
A future data refresh with covariate missingness would silently break the coincidence: the CIs would compute on a different sample than the GMM fit they are attached to, with no diagnostic.

The fix cannot read `e(sample)` from the saved ster, because Stata does not persist the sample marker: after `estimates use`, `count if e(sample)` returns 0 while `e(N)` reports the fit's count (verified 2026-07-19 on this machine's StataNow 19.5 MP with a saved regression: `e(N)=22`, marker count 0 after reload).
The estimation sample must therefore be persisted at fit time, alongside the ster, and read back at attach time.

## MUST

M5-1. `run_grc` persists the parent fit's estimation sample.
Immediately after the parent `estimates save`, the rows flagged by `e(sample)` are saved as a keyed marker file next to the ster (proposed name: `<estname>${vsfx}_esample.dta`, holding `pid` and `period` of in-sample rows only).
The marker describes the parent GMM fit; the `_n`/`_a`/`_d`/`_g` suffixes rest on the same fit and need no separate marker.
The fit itself is untouched: no change to the `gmm` call, its inputs, or their order, so refit sters remain byte-identical.

M5-2. `attach_inversion_ci` reads the marker; a legacy ster without one triggers a loud warning, never a silent path.
With a marker present, the program merges it on `pid period` against the data in memory, hard-errors if any marker row fails to match a data row, and passes the resulting in-sample flag to Python.
Without a marker (a ster predating the contract), the program prints a prominent warning naming the missing file and falls back to the reconstruction, and in BOTH paths it asserts that the row count the inversion computed on equals the parent ster's `e(N)`, so a diverging reconstruction fails loudly instead of attaching wrong-sample CIs.
(Decision 3, author 2026-07-19: warning-plus-fallback chosen over a hard refit error; the `e(N)` assert is the guardrail that keeps the fallback honest.)

M5-3. The Python side computes on exactly the flagged rows.
`compute_all_inversion_cis` gains a sample-flag column argument; the `dropna` reconstruction is replaced by a subset on that flag.
An assert confirms the flagged rows carry no missing values in the columns the inversion needs (the fit sample guarantees this for the GMM columns); an assert failure is a hard error, never a silent drop.
Rows the flag excludes never enter `drop_sparse_switchers`, `fit_auxiliary_ols`, or the trajectory shares.

M5-4. The invariant is documented at both ends.
The `attach_inversion_ci` header and the `compute_all_inversion_cis` docstring state the contract: the inversion sample is the parent fit's `e(sample)`, so the CI $N$ always equals the GMM fit's $N$, including under future data refreshes with missingness.

M5-5. A synthetic contract test proves the contract where byte-identity cannot.
On scratch data with missingness injected into one control, fit a small GRC cell (so `e(sample)` excludes the injected rows), then fill the missingness in the loaded data to simulate a data refresh and run the attach path.
The test asserts the inversion computed on the persisted `e(sample)` count, not the reconstruction's larger count, and fails loudly under the old code path.
The test is committed as a runnable script under `RP7/tests/`.

M5-6. Gate: refit the inversion panel cells and compare against the Stage 3+4 gate baseline.
The panel GMM cells refit under the new code must be byte-identical to their gated Stage 3+4 counterparts (the marker write cannot touch the fit), and the attached sters must match baseline at Tier 2; Tier 1 provenance exact.
Any CI movement means the reconstruction was already diverging from `e(sample)`: stop and surface, do not absorb.

M5-7. Author sign-off on the gate artifact before commit, per the correctness-stage rule.

## SHOULD

S5-1. The marker is written for every `run_grc` fit, not only the cuu inversion cells.
Uniform behavior is one code path, costs one small `.dta` per cell, and future-proofs any later consumer of a fit sample (the same contract question will recur wherever a saved ster meets reloaded data).

S5-2. Marker files follow the ster lifecycle.
They land in the same output directory, are gitignored the same way `.ster` files are, and are copied or regenerated together with their sters; the replication-package handoff treats them as generated output.

S5-3. `5c_inversion_hukou.do` is covered by the same mechanism with no hukou-specific code: its sters come from `run_grc` via `7_GrRC_hukou.do`, so M5-1 and M5-2 apply as-is.

## MAY

MAY-1. A guarded backfill helper for legacy sters (reconstruct, tag the marker as RECONSTRUCTED, refuse to run in production paths) if a use case appears before the definitive run; not built by default.

## Out of scope

The Verdier loop's persisted sample mutation (Stage 6), the 11b figure scale (Stage 7), any change to the GMM moment conditions or fit sample, and any change to which cells get inversions.

## Decisions resolved 2026-07-19 (author)

1. Marker scope: every fit writes a marker, labeled appropriately (dataset label naming the source ster and fit date), so future inversion consumers on other estimates inherit the contract; S5-1 is promoted to MUST-level behavior.
2. Marker location and name: the author proposed one index per run; Claude recommended per-cell files (`<estname>${vsfx}_esample.dta` next to the ster) because cells are re-runnable individually, parallel detached batches would race on a shared index, and per-cell files follow their ster through copies and handoffs.
Per-cell files are the working choice pending the author's confirmation at plan approval.
3. Failure mode on legacy sters: loud warning with fallback to the reconstruction, guarded by the `e(N)` assert in M5-2.
