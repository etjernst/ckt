# Plan: implement the E1/E2 counterfactual fixes

Date: 2026-07-08.
Spec: [2026-07-08-counterfactual-fixes.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-counterfactual-fixes.md) (all decisions resolved except D5).
D1 resolved 2026-07-08 by critic-econometrics adjudication: headline = LCA-fitted switcher returns recomputed at each $(\phi,\beta)$ lattice point; unrestricted returns computed as a cross-check exhibit; the frozen hybrid retired.
D5 (dispersion envelope) still awaits the user's go/no-go on [2026-07-08-dispersion-envelope.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-dispersion-envelope.md); Phase 2 carves it as an optional block so nothing else waits on it.

No GRC GMM re-fit anywhere; every step reuses the on-disk sters and the processed panels.

## Phase 1: Stata exporters

Files: [_export_e1_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs.do), [_export_e1_inputs_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs_hukou.do).

1. Fix the dead ster-$\mu$ extraction: iterate `coleq`+`colnames` pairs, collect `mu:never` and every `mu:switcher_k`, and write them as a `mu_d_ster` column in the `_e1_mu_d.csv` (kept alongside the raw column, renamed `mu_d_raw_hh`, for the cross-check; Python stops consuming the raw column).
2. Export the ster's base trajectory into the scalars CSV: find the unique $k$ with $|$`Delta_base:_cons`$ - $`Delta_k`$| < 10^{-10}$ in the `_d` ster; error out if zero or multiple matches.
3. Export the first-observed-wave urban share $\bar D^0_{\underline{d}}$ per `traj_for_agg` (by pid: `choice` at the first observed wave; mean within trajectory) as a `dbar0_d` column in the traj CSV.
4. Rename the `_d`-ster export column `delta_d_unrestricted` to `delta_d_lcafit_point` (it is the restricted-fit nlcom value; the misnomer flagged by both reviews).
5. Hukou exporter only: export `delta_never_point` from the `_n` ster (`grc_CHN_rf_cuu_ca_n.ster`, `_b[Delta_never]`) for the E2 table point.
6. Housekeeping: drop `pi_helper`; align the $\pi_d$/$\bar D_d$/$\bar D^0_d$ sample filter with the Python fit (drop missing lndepvar/choice plus the controls and unbalanced dummies).

Checkpoint: rerun both exporters, eyeball the CSVs (`mu_d_ster` reproduces the values dumped from the sters on 2026-07-08; CHN_uf base = 4; IDN/TZA/CHN_rf base = 2).

## Phase 2: Python module

File: [counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py).

1. `run_cell` reads `base` from the scalars CSV (assert it is in `switchers_kept`; drop the hardcoded `BASE_TRAJECTORY` fallback) and uses it for the grid moments, $\mu_{base}$, and the point plug-in.
2. Single-source LCA objects: all $\mu$ differences and $\alpha_{d_T}$ come from the auxiliary-OLS fit (`alpha[d]` coefficients); `compute_alpha_dT_obs` and the raw-mu consumption of the CSV are deleted.
3. `delta_at(phi, beta)` implements D1: switcher returns $\beta + \phi(\alpha_s - \alpha_{base})$ recomputed at each lattice point; never via $\alpha_{never} - \alpha_{base}$; $d_T$ via the Mobius formula on $\alpha_{d_T}$; lumped cell = $\Delta_{unb}$ (from the fit's `unbalanced_choice` coefficient, see 5).
4. Baseline (ii): `evaluate_aggregate` gains `dbar0_d`; the value term becomes $\pi_d \Delta_d (\bar D_d - \bar D^0_d)$; the gap term is unchanged; the P3 zeroing of $d_T$ in the value column is removed (it now exits via $\bar D - \bar D^0 = 0$).
5. Coverage variant 1: extend `build_joint_ci_grid` with a third coordinate $\delta_{unb}$ --- one extra moment `unbalanced_choice`$_{OLS} - \delta_{unb}$, Jacobian row appended, dof $K+1$ --- on a grid of $\pm 4$ cluster-robust SEs (41 points); project the aggregate through the accepted 3D set.
   Coverage variant 2: the existing 2D region with the $\Delta_{unb}$ 95% CI folded in by interval arithmetic.
   Both variants persisted per cell so the user can choose on widths.
6. Cross-check exhibit (D1): fit `beta[s]` for ALL switcher trajectories (moments still over `switchers_kept` only); compute the point aggregate under unrestricted switcher returns; persist the (B)-vs-(A) gap difference per cell to the diagnostics CSV.
7. Guards and diagnostics: assert the accepted region touches no lattice edge (error, with the offending margin named); self-check $\Delta_{d_N}$ at the point vs ster `inv_dN` within 0.01; write a diagnostics CSV with the per-trajectory decomposition, `marginal_phi`, `marginal_beta`, `n_accept`, `crosses_boundary`, and the (B)-vs-(A) deltas.
8. E2: `run_hukou_bound` uses the exported `delta_never_point` for the table point (inversion CI unchanged).
9. Tables: value column reflects the new baseline; national row unchanged mechanically (footnote text lives in the paper).
10. OPTIONAL (D5 go): `envelope_curve` per the envelope spec (closed-form censored normal; $s$ grid to the heuristic ceiling; references L and U), CSV + figure in house style.
11. `regenerate_baseline=True` on the accepted run; then restore the drift check.

Checkpoint: full `12_counterfactuals.do` run; verify the acceptance criteria in the spec (base-4 CHN_uf end to end, $\Delta_{d_N}$ vs `inv_dN`, CHN_rf with-$d_T$ = P3 on the gap); present the user an old-vs-new table of every headline number plus the two coverage variants side by side. USER DECISION HERE: coverage variant.

## Phase 3: paper edits (Overleaf `main-updated.tex`, mirrored in `paper/results_counterfactuals.tex`)

All numbers from the accepted Phase 2 run; one commit per logical edit; one sentence per line.

1. Equation (1): value term gains $\bar D^0$; surrounding prose already argues the initial-location baseline, so only the equation and the "deterministic functions" sentence change ($\bar D$, $\bar D^0$ estimated for the lumped cell).
2. Identification paragraph (line 820 region): rewrite for D1 --- switcher returns evaluated on the estimated LCA line at each point of the confidence region; unrestricted returns as the cross-check sentence with the computed difference; delete "identified non-parametrically" as a description of what enters the aggregate.
3. Lumped-cell disclosure: two sentences in the decomposition paragraph (return = GMM unbalanced-mover coefficient applied to the whole cell; its sampling uncertainty is inside the interval per the chosen variant).
4. Interval description: update the "convex hulls of the joint $(\phi,\beta)$ region" sentence to the chosen variant; add the national-row coverage footnote.
5. Refresh every quoted number: IDN/TZA/CHN gaps and CIs, value-of-migration column (will fall under the new baseline), the with-$d_T$ caveat numbers (refresh from the corrected $\alpha_{d_T}$ or cut the sentence), hukou-bound point ($+11.6\%$ becomes the `_n`-ster value), the TZA-dominance and IDN-lumped sentences if the corrected decomposition changes them.
6. Small repairs: "balanced-panel never-migrant share" for $\pi_{d_N}^{rh}$; delete the law-of-total-variance sentence; envelope paragraph rewritten (D5 go) or cut (D5 no-go).

## Phase 4: verify and close out

1. critic-alignment on the refreshed tables vs the rewritten prose.
2. Review-memo status footer: old vs new headline numbers, findings marked fixed.
3. Session log update; commits throughout (exporters, Python, regenerated outputs, paper, docs as separate commits).

## Execution notes

- All estimator-touching edits stay in the main thread (workflow rule); no subagent delegation for Phases 1--2.
- The Overleaf edits (Phase 3) are approved by the user (D6) but each substantive edit gets its own commit in the worktree mirror for the diff trail.
- Risks: the 3D lattice multiplies runtime by ~41 (from seconds to minutes per cell --- acceptable); sparse-switcher `beta[s]` columns in the cross-check fit may be near-collinear (pinv already guards the moment variance; the cross-check uses coefficients only); the lattice-edge assertion may legitimately fire for CHN_uf's $\phi$ (region known to extend far below $-1$) --- if so, widen the phi grid and rerun rather than suppress.