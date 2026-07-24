# Plan: E1/E2 counterfactual inputs under WCR11 sters

Date: 2026-07-24.
Status: draft, awaiting approval.
Mode: Implementation.
Spec: [2026-07-24-e1-e2-counterfactual-gmm-rework.md](file:///C:/git/ckt/quality_reports/specs/2026-07-24-e1-e2-counterfactual-gmm-rework.md) (approved, both open questions resolved at 4bdac46).

## Verified current state (direct reads, 2026-07-24)

The E1 point aggregate already sources the never-migrant return from the GMM `_n` ster: [counterfactuals.py](file:///C:/git/ckt/explorations/python-grc/counterfactuals.py) line 982 sets `dv_hat[is_dN] = delta_never_point`, so MUST 3 is a confirmation plus cleanup, not a numeric change for $\Delta_{d_N}$.
The scalars key `inv_dN` is consumed only by the `_SCALAR_KEYS` presence check (line 490) and a diagnostic print (line 866); `inv_phi`, `inv_dT`, and `inv_davg` are exported but never read by Python.
`run_hukou_bound` (lines 1088-1158) is the sole consumer of `inv_dN_ci95_{lo,hi}`.
The always-urban point in `dv_hat` currently comes from the Mobius echo `lca_delta_dT(phi_hat, beta_hat, ...)` (line 985), not from any ster.
`_a` sters exist for all needed cells (`grc_{IDN,TZA,CHN_rf,CHN_uf}_cuu_ca_a.ster`) and carry the nlcom coefficient `Delta_always` ([0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) lines 2489, 2811, 3277).
The paper inputs `tables/counterfactual_misallocation.tex` (main-updated.tex line 870) and `tables/hukou_bound.tex` (line 913); no other consumer of `counterfactual_results.csv` exists outside the driver and docs.

## Step 1: exporters (Stata)

[_export_e1_inputs.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do):

1. Delete the four `e(inv_*_at_waldmin)` reads (lines 60-63) and the four `inv_*` CSV write lines (lines 278-281), including `inv_davg` per resolved question 2.
2. After the existing `_n` ster block, read the `_a` ster (`grc_<c>_cuu_ca_a.ster`): `delta_always_point` from `Delta_always` in `e(b)`; hard error (exit 498) if the file or coefficient is missing.
3. Write `delta_always_point` to the scalars CSV, plus provenance rows `delta_never_source` and `delta_always_source` naming the ster file behind each value (SHOULD 1).
4. Update the two `di` diagnostic lines that echo `inv_dN` / `inv_dT`.

[_export_e1_inputs_hukou.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs_hukou.do): the same four changes, and additionally:

5. Replace the `inv_dN_ci95_{lo,hi}` reads (lines 68-69) and writes (lines 281-282) with a GMM 95% CI computed on the `_n` ster: `se = sqrt(el(e(V), j, j))` at the `Delta_never` column, `gmm_dN_ci95_lo/hi = delta_never_point -/+ invnormal(0.975)*se`; hard error if `e(V)` is missing or the SE is not strictly positive (MUST 1, MUST 5).
6. Write `gmm_dN_ci95_lo`, `gmm_dN_ci95_hi`, and a `gmm_dN_ci95_source` provenance row for both hukou cells (RF and UF each from its own `_n` ster); only RF is consumed today, but symmetric export keeps the CSVs uniform (MUST 2: new key names only, never the old `inv_dN_*` names).

## Step 2: counterfactuals.py

1. `_SCALAR_KEYS`: drop `inv_dN`, add `delta_always_point`.
2. `run_cell`: drop the `inv_dN` term from the diagnostic print; read `delta_always_point` and hard-error if non-finite.
3. Point estimates become two variants per resolved question 1.
   Variant A: `dv_hat` sets the always-urban row to `delta_always_point` (the `_a`-ster GMM point) and the gap term keeps that row.
   Variant B: the always-urban row is zero in both the gap and the value term.
   Per the 2026-07-24 amendment, the value of observed migration is reported under both zero-migration baselines: the first-observed-wave value $\sum \pi_d \Delta_d (\bar D_d - \bar D^0_d)$, which is variant-invariant (always-urban workers contribute zero by construction), and the everyone-rural value $\sum \pi_d \Delta_d \bar D_d$, which includes the always-urban row and so takes the variant A/B treatment.
   `CellResult` carries `point_gap_varA`, `point_gap_varB`, a single `point_value_d0`, and `point_value_allrural_varA` / `point_value_allrural_varB`.
   The Mobius echo `lca_delta_dT` leaves the point path entirely; it survives only inside the region-sweep machinery.
4. The joint-region machinery (2D/3D grids, hulls, open-edge probes) keeps running unchanged, but its hulls leave the reported surface: hull tuples move from `counterfactual_results.csv` into `counterfactual_diagnostics.csv` columns (MUST 4; the region also still feeds the `marginal_*` diagnostics and its interior/finiteness assertions stay hard errors per MUST 5).
5. `combine_national`: weight the variant A and variant B gap points and the value point; national hulls drop with the rest of the reported intervals.
6. `run_hukou_bound`: require `gmm_dN_ci95_{lo,hi}` (KeyError if absent), keep the finiteness and ordering hard errors, and add `ci_source` to `HukouBoundResult`, filled from the `gmm_dN_ci95_source` provenance row (MUST 2).
7. `results_dataframe`: per E1 cell five rows --- (`misallocation`, `point_varA`), (`misallocation`, `point_varB`), (`value_migration_d0`, `point`), (`value_migration_allrural`, `point_varA`), (`value_migration_allrural`, `point_varB`) --- and the two E2 rows with version `gmm_ci` (previously `inversion`) plus a new `ci_source` column, empty on E1 rows.
8. Tables: `write_latex_table` becomes a two-variant writer producing `counterfactual_misallocation_varA.tex` and `counterfactual_misallocation_varB.tex`, each with three point columns (misallocation gap, value vs. first-observed location, value vs. everyone rural) and a one-sentence tablenote stating the always-urban treatment and naming the two baselines; the canonical `counterfactual_misallocation.tex` is written only once the author has picked a variant (knob in step 3).
   `write_hukou_bound_table` keeps its layout; the CI column now carries the GMM interval.
9. `_self_check` logic is untouched; the schema change means the first post-change run must go through the drift protocol below.

## Step 3: 12_counterfactuals.do

1. Pass both variant table paths into `run_counterfactuals_for_stata`; update the `confirm file` block and the header comments.
2. Add three optional globals read by the python call, all defaulting to strict/off: `$cf_allow_drift` (passes `allow_drift=True`, which still prints the full drift report loudly), `$cf_regen_baseline` (one-shot baseline regeneration after author approval), and `$cf_e1_variant` (`A` or `B`; when set, also writes the chosen variant under the canonical `counterfactual_misallocation.tex` name the paper inputs).
3. No silent fallback anywhere: unset knobs mean the strict self-check runs and only the two variant files are written.

## Step 4: README_counterfactuals.md

Update [README_counterfactuals.md](file:///C:/git/ckt/RP7/scripts/README_counterfactuals.md) to describe the GMM sourcing ($\Delta_{d_N}$ point and CI from the `_n` ster, $\Delta_{d_T}$ variant A point from the `_a` ster), the two-variant comparison state, and the E1 interval's pending status; coauthor-facing language with no git, branch, or commit references (SHOULD 2).

## Transition and drift protocol (MUST 6)

1. Run the exporters and driver end-to-end on the definitive-run sters via `stata-mp -e` with `$cf_allow_drift = 1`.
2. The run writes the regenerated `counterfactual_results.csv`, both variant tables, and the drift report against `counterfactual_results_baseline.csv` in the log.
3. I summarize the movement (old vs new per reported quantity, plus the variant A vs variant B comparison) in a memo under `quality_reports/reviews/` for author adjudication.
4. After the author approves the numbers and picks the variant: one run with `$cf_regen_baseline = 1` and `$cf_e1_variant` set, then a final strict run with all knobs unset as the closing verification.

## Verification (spec section, mapped)

1. Grep sweep confirming no consumer reads `inv_dN`, `inv_dT`, `inv_davg`, or `inv_phi` fields outside the exporters' history and the chi2-comparison/attach machinery.
2. Exporter re-run produces complete scalars CSVs with the new keys and provenance rows for all four cells.
3. End-to-end driver run passes; recompute `const * gmm_dN_ci95_{lo,hi}` from the CHN_rf scalars CSV and confirm the E2 `hull_bound` matches exactly.
4. Sanity cross-check: the exported `gmm_dN_ci95` half-width for CHN_rf against the $\Delta_{\text{never}}$ SE in the reported CHN RF GRC table ($\pm 1.96 \times$ SE).
5. Drift memo delivered; no baseline regeneration before author approval.

## Execution and model routing

The counterfactuals.py restructure (reporting semantics, variant construction) stays in the main thread as judgment-bearing work.
The two exporter edits, the driver knob wiring, and the README update go to `model: "sonnet"` subagents with precise briefs, diffs reviewed here.
Batch runs go through `stata-mp -e` per the batch conventions; runtime is dominated by the CHN 3D grids and matches the current driver runtime.

## Expected visible effects (not failures)

The E2 bound CI moves because the delta-method GMM interval replaces the test-inversion interval; `floor_positive` is re-evaluated on the new endpoints.
The variant A gap for CHN_uf may look extreme since the `_a` point sits near the $(1+\phi)^{-1}$ singularity in that regime; surfacing that contrast is the purpose of the author comparison.
The self-check fails by construction on the first run (schema plus sourcing changes); that is the drift protocol working, not a defect.

## Out of scope (per spec)

The WCR11 joint-region extension for the misallocation gap, the trajectory-size coverage gradient, and any change to `attach_inversion_ci`, the scrub, or the sims engine.
Paper prose edits around the two tables (the pending-interval sentence, the variant B explanation if chosen) are author-gated Overleaf work and follow the variant decision.
