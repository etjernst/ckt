# Spec: Pipeline integration of weak-ID-robust inversion CIs

Date: 2026-04-30.
Branch: `lca-inversion`.
Mode: Implementation.

## Goal

Graduate the LCA inversion CI machinery from `explorations/python-grc/` into the production GRC pipeline, so that paper tables display weak-ID-robust 95% CIs for $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, and $\Delta_{d_T}$ alongside the chi-squared point-estimate inference already in place.

## Status quo

The Python module [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) implements grid-inversion CIs for $\phi$ (just-identified) and the three deltas (constrained MD).
A working Stata wrapper at [`explorations/python-grc/lca_inversion_ci.ado`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion_ci.ado) computes the $\phi$ inversion CI, attaches it as `e()` scalars to a restored estimate, and re-saves the `.ster`.
The wrapper currently shells out to a separate Python helper script via `python script`, and only handles $\phi$.
[`explorations/python-grc/run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py) computes all four CIs but writes them to a markdown table in `explorations/python-grc/results/`, not to the `.ster` files the paper tables consume.

The estimation entry point is `run_grc` in [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do).
Each call to `run_grc` saves four `.ster` files per (country, spec) cell: the parent estimate, plus `_never`, `_avg`, and `_always` subgroup `nlcom` saves.
Tables are built inline at the end of the numbered GRC scripts (5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do, ...) by `grc_tex_table_trend` and its variants in `0_programs.do`.

## Architecture

Three components, in priority order.

1. New program `attach_inversion_ci` in `RP7/scripts/0_programs.do`.
Calls into Python via an inline `python:` block (no separate helper script).
Computes all four CIs at 90% and 95% in a single Python call, returns them via `sfi.Macro.setLocal`, and writes them into `e()` on the restored estimate before re-saving the `.ster`.
2. New standalone driver `RP7/scripts/5b_inversion.do`.
Loops country $\times$ spec for the urban/cons/unb mainline of `5_GrRC.do`.
For each cell it loads the data once, restores each of the four `.ster` files in turn, and calls `attach_inversion_ci`.
Independent of `run_grc` so that re-running the inversion does not re-run the GMM.
3. Light-touch extension to `grc_tex_table_trend` in `0_programs.do`.
Reads the new `e()` scalars and emits an extra row per coefficient (formatted as `[lo, hi]`) beneath the existing point-estimate-and-SE row.

Out of scope (kept as separate TODOs): Imbens-Kolesár F adjustment, Hall-Horowitz bootstrap calibration, refactor of table-building into a single `make_tables.do`, auxiliary GRC scripts (6/8/11/13/14/15), `run_grc_hukou` and `run_grc_robust` paths.

## MUST

- The new `attach_inversion_ci` program lives in `RP7/scripts/0_programs.do`.
Single inline `python:` block.
No external helper script.
- The program signature accepts: `estname`, `outcome`, `traj`, `choice`, `hhid`, `base`, optional `controls`, optional `min_phi`/`max_phi`/`increment`/`threshold`, optional `sterdir`.
The program is `eclass` so re-saved estimates carry the inversion scalars.
- The Python entry point is a single function in `lca_inversion.py` that takes `(phi_grid, beta_hat, residual_moment, weight_matrix, ...)` and returns a dict with the four point estimates (at the Wald minimum) and the four CIs at both 90% and 95%.
The Stata wrapper makes one Python call per (country, spec) cell, not four.
- Inversion CI scalars are stored in `e()` and persisted to the `.ster` file the wrapper restored.
The `.ster` is re-saved with `estimates save ... , replace`.
- Storage routing: $\phi$ inversion goes on the parent `_avg.ster`.
$\Delta_{d_N}$ inversion goes on `_never.ster`.
$\Delta_{\text{avg}}$ inversion goes on `_avg.ster`.
$\Delta_{d_T}$ inversion goes on `_always.ster`.
Each delta `.ster` carries both its own delta CI and the model-level $\phi$ CI for cross-reference.
- Scalar names follow the existing convention: `inv_phi_at_waldmin`, `inv_phi_ci90_lo`, `inv_phi_ci90_hi`, `inv_phi_ci95_lo`, `inv_phi_ci95_hi`, `inv_phi_J_R`, `inv_phi_n_kept`; analogous names with prefix `inv_dN_`, `inv_davg_`, `inv_dT_` for the three deltas.
Names budget under the 32-character `_est_` limit when combined with the longest `estname` produced by `5_GrRC.do` (`grc_IDN_urban_covs_trend_avg`, 28 chars).
- The driver `RP7/scripts/5b_inversion.do` runs as a batch script with the standard CKT header (`version 19`, `clear all`, log open, `capture noisily { ... }` body, `exit, STATA clear` at the end).
The body loops over `country in (CHN, IDN, TZA)` and `spec in (covs_0, covs_trend, covs_1, covs_2, covs_all)` for the urban/consumption/unbalanced mainline, replicating the data-loading pattern from [`5_GrRC.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5_GrRC.do).
For each cell, the driver calls `attach_inversion_ci` four times---once per `.ster` suffix in `(none, _never, _avg, _always)`---using the corresponding restored estimate.
- The driver respects `${skip_if_exists}`.
A cell is skipped if the target `.ster` already has `e(inv_phi_ci95_lo) != .` populated.
- `grc_tex_table_trend` reads `e(inv_phi_ci95_lo)`, `e(inv_phi_ci95_hi)`, `e(inv_dN_ci95_lo)`, `e(inv_dN_ci95_hi)`, `e(inv_davg_ci95_lo)`, `e(inv_davg_ci95_hi)`, `e(inv_dT_ci95_lo)`, `e(inv_dT_ci95_hi)` from the relevant restored estimates and emits an additional bracketed-CI row beneath each existing coefficient row.
The row label reads "95% LCA inv. CI" or similar.
Multi-island CIs (where the lo or hi endpoint hits the grid boundary, $\pm \infty$ in `format_islands` parlance) render as the union format described in [`docs/notes/2026-04-30_mobius-singularity.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md).
- Numerical-equivalence verification: after the new pipeline runs end-to-end on IDN/cons/urban/unb covs_all, the four CIs in the re-saved `.ster` files match (within numerical tolerance) the values in [`explorations/python-grc/results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md).
This is the validation gate that the migration preserves the existing inversion machinery.

## SHOULD

- The `python:` block inside `attach_inversion_ci` adds `explorations/python-grc/` to `sys.path` so it can import `lca_inversion`.
This keeps the Python module in its current location during the transition.
A later refactor can move `lca_inversion.py` to a permanent home in `RP7/scripts/python/` once the API is stable.
- `attach_inversion_ci` re-uses `run_grc`'s existing data-prep conventions (the `setup_grc_estimation` keepvars, `tab period, gen(period_)`, `drop if mi(lndepvar) | mi(choice)`).
This avoids the dataset-mismatch bugs that would surface if the auxiliary OLS used a different sample than the GMM.
- The driver `5b_inversion.do` separates GMM inversion from F adjustment and bootstrap calibration so the latter two can be added as additional rows in `grc_tex_table_trend` without re-running the GMM or the chi-squared inversion.
- Table rows for the inversion CI are formatted to handle multi-island outputs gracefully (footnote pointer to the Möbius memo for cells where one endpoint touches $\pm \infty$).

## MAY

- Phase 2 generalizes `attach_inversion_ci` to the auxiliary GRC pipelines (6/8/11/13/14/15).
This is a one-time extension once the mainline pattern is verified.
- After verification, the existing `lca_inversion_ci.ado` and `lca_inversion_ci_helper.py` in `explorations/python-grc/` can move to `explorations/ARCHIVE/` since the new program in `0_programs.do` supersedes them.
- A future refactor can hoist `attach_inversion_ci` and the table-building logic into a real `make_tables.do`, decoupling table output from the numbered GRC scripts entirely.
This is plausibly part of the `grc-pipeline-refactor` branch's scope.

## Acceptance criteria

The spec is satisfied when:

1. `RP7/scripts/5b_inversion.do` runs to completion in batch mode and writes the four inversion-CI scalars into all 60 `.ster` files for the urban/cons/unb mainline (3 countries $\times$ 5 specs $\times$ 4 suffixes).
2. The four CIs read from any post-run `.ster` match (within numerical tolerance) the values in `explorations/python-grc/results/delta_inversion_three_countries.md`.
3. Re-running `5_GrRC.do` and then `5b_inversion.do` regenerates a `.tex` table that includes the inversion-CI row beneath each coefficient row, with the multi-island Möbius cells rendered as $[-\infty, x] \cup [y, +\infty]$ and a footnote pointer.
4. None of the changes alter the existing GMM point estimates, SEs, or `J`-stat outputs.
The numerical-equivalence check on `e(b)` and `e(V)` from the re-saved `.ster` matches the pre-migration values exactly.

## Resolved design decisions

1. Display both 90% and 95% CIs in the inversion-CI rows.
Two extra rows per coefficient (one per confidence level), labeled "90% LCA inv. CI" and "95% LCA inv. CI".
Either can be dropped from the final tables later without touching the upstream pipeline.
2. Multi-island Möbius cells use a single global footnote pointing at [`docs/notes/2026-04-30_mobius-singularity.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md).
No per-cell footnote markers.
3. CI rows go beneath the SE row in the table layout (preserves the existing coefficient-then-SE block, then appends the CI rows).
