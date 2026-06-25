# Spec: E2 hukou-wedge counterfactual, lower bound (Version 1)

Date: 2026-06-25
Mode: Implementation
Branch: lca-inversion

## Objective

Compute the lower-bound consumption gain from removing the rural-hukou
mobility barrier in China, as defined in `eq:hukou-bound` of
[paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex):

$$\text{gain (lower bound)} = \pi^{rh} \cdot \pi_{d_N}^{rh} \cdot \Delta_{d_N}^{rh}.$$

This is "Version 1" only. The resorting-magnitude version (Version 2) is
explicitly out of scope for this cycle (it requires distributional and
base-choice decisions to be settled separately).

## Why this is the right next step

The section currently states the bound only in subjunctive with no number.
Every ingredient already exists in the committed E1 harness:

- $\pi^{rh}$: rural-hukou share of the CHN sample, from `hukou_population_weights`.
- $\pi_{d_N}^{rh}$: never-migrant share within the rural-hukou subsample.
  Confirmed `= 0.27214` (the `pi_d` for `traj_for_agg == 1` in
  `CHN_rf_e1_traj.csv`).
- $\Delta_{d_N}^{rh}$: rural-hukou never-migrant return, the LCA extrapolation
  $\beta + \phi(\mu_{d_N} - \mu_{\text{base}})$ the CHN_rf cell already computes
  via `lca_delta_dN`. Point $\approx 0.1045$ log pts (consistent with the
  `inv_dN = 0.11` scalar).

Provisional point estimate of the bound: $\approx +2.1\%$ in geometric-mean
consumption (same order as Gai 2025's 2.04 log-pt GE figure the paper cites).
Final numbers come from the harness run, not this spec.

## Requirements

### MUST

- M1. Compute the bound `gain = pi_rh * pi_dN_rh * Delta_dN_rh` at the GMM
  point $(\hat\phi, \hat\beta)$ for the CHN_rf cell.
- M2. Propagate inference through the CHN_rf joint $(\phi,\beta)$ confidence
  region the harness already builds (`build_joint_ci_grid`). At each accepted
  lattice point evaluate $\Delta_{d_N}^{rh}(\phi,\beta)$, multiply by the fixed
  shares, and report the convex hull. $\Delta_{d_N}$ is linear in $(\phi,\beta)$
  with no Möbius pole, so NO P3 / drop-$d_T$ fallback is needed; report the
  honest hull (and run island detection for completeness).
- M3. Code lives in
  [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py).
  No new module; no `e1_`/`e2_` function-name prefix (per prior user directive).
  Reuse the CHN_rf CI construction so the bound and the E1 CHN_rf gap rest on
  the identical fitted object.
- M4. No E1 number changes. Any refactor to share the CI construction must be
  behavior-preserving and is guarded by the existing golden-snapshot self-check
  (`_self_check`, atol 1e-3 log pts).
- M5. Extend the persisted results CSV and its golden baseline with the E2 row(s)
  so the existing drift self-check covers E2. Proposed key:
  `cell = "CHN_hukou_bound"`, `quantity = "hukou_consumption_gain"`,
  `version = "bound"`.
- M6. Emit a paper-facing LaTeX table for the bound, written by the same
  `run_counterfactuals_for_stata` entry point and confirmed to exist by
  `12_counterfactuals.do`.

### SHOULD

- S1. Update the Version 1 lower-bound paragraph in
  `results_counterfactuals.tex` to state the computed bound and its CI, and
  `\input` the new table. Leave the Version 2 subjunctive text untouched (V2
  has not been run; rewriting it would falsely imply results exist). This is a
  prose edit and triggers the prose-rules hook (read voice.md +
  manuscript-writing.md first).
- S2. The table note records the three ingredient values
  ($\pi^{rh}$, $\pi_{d_N}^{rh}$, $\Delta_{d_N}^{rh}$) for transparency.
- S3. Echo the E2 headline to the Stata log, mirroring the E1 echo loop.

### MAY

- MAY1. Report the bound under both $\pi^{rh}$ conventions (conditional vs
  full-sample) as a sensitivity, if the user wants the range.
- MAY2. Surface the 90% interval alongside the 95%.

## Decisions needing confirmation (clarity)

- C1 (NEEDS CONFIRM). Definition of $\pi^{rh}$. `hukou_population_weights`
  exposes both `w_rf_cond = n_rf/(n_rf+n_uf)` (the 74% the paper already
  reports, conditional on defined hukou) and `w_rf_full = n_rf/n_chn`
  (full-sample, counting the ~0.7% undefined-hukou pids in the denominator).
  The E1 national combination uses the conditional weights.
  RECOMMENDATION: use `w_rf_cond` (= 74%) for consistency with the E1 national
  weighting and the share the paper already states. The two differ by <1pp, so
  the headline is essentially unaffected either way.
- C2 (NEEDS CONFIRM). Table placement. RECOMMENDATION: a small SEPARATE table
  (one row, the CHN rural-hukou bound with its CI), not folded into
  `counterfactual_misallocation.tex`, because the unit differs (a single CHN
  aggregate consumption gain, not a per-country misallocation gap). This was
  Q2 from chat; defaulting to separate unless you say otherwise.
- C3 (resolved, noted). Base trajectory for $\Delta_{d_N}^{rh}$: use the
  harness default `base = 2` (the same base the CHN_rf E1 cell uses). V2's
  base-sensitivity discussion does not apply to the V1 bound.

## Out of scope

- Version 2 (resorting magnitude): decision-rule simulation, $\sigma_\eta$ grid,
  type-I EV vs normal shapes, common-vs-regime base sweep, $c\in[0,1]$ appendix
  figure. Separate Implementation cycle.
- Any change to E1 outputs, the GRC/inversion sters, or the export do-files.

## Verification

- Self-check passes for all E1 rows (numbers unchanged) plus the new E2 row.
- `12_counterfactuals.do` runs clean via `stata-mp -e`; both result CSV and both
  tables confirmed on disk.
- Bound point and CI hand-checked against the ingredient values above.
