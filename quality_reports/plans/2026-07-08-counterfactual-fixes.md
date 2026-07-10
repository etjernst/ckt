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
6. [CHANGED, review R-Y5] Housekeeping: drop `pi_helper`; define the sample filter EXPLICITLY and identically on both sides as `consumption > 0 & hhsize_cube > 0 & !missing(choice, period, female, age2, education_max, education_max2, unbalanced, unbalanced_choice)` (Stata `ln()` of a nonpositive value is missing while Python's `np.log(0)` is $-\infty$ and survives `dropna`, so a positivity filter, not a missingness filter, is what aligns the two); export the post-filter row and pid counts to the scalars CSV so Python can assert an exact match at load.
7. [NEW] Export `delta_never_point` (`_b[Delta_never]` from the `_n` ster) in BOTH exporters, not only the hukou one --- it sharpens the Phase 2 self-check (exact ster point, not the grid-snapped `inv_dN`).

Checkpoint: rerun both exporters, eyeball the CSVs (`mu_d_ster` reproduces the values dumped from the sters on 2026-07-08; CHN_uf base = 4; IDN/TZA/CHN_rf base = 2).

## Phase 2: Python module

File: [counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py).

1. `run_cell` reads `base` from the scalars CSV (assert it is in `switchers_kept`; drop the hardcoded `BASE_TRAJECTORY` fallback) and uses it for the grid moments, $\mu_{base}$, and the point plug-in.
2. Single-source LCA objects: all $\mu$ differences and $\alpha_{d_T}$ come from the auxiliary-OLS fit (`alpha[d]` coefficients); `compute_alpha_dT_obs` and the raw-mu consumption of the CSV are deleted.
3. [CHANGED, review R1/Y3/Y4] `delta_at(phi, beta, delta_unb)` implements D1: kept-switcher returns $\beta + \phi(\alpha_s - \alpha_{base})$ recomputed at each lattice point; never via $\alpha_{never} - \alpha_{base}$; $d_T$ via the Mobius formula on $\alpha_{d_T}$; sparse NON-kept switchers (whose OLS $\alpha$ pools rural and urban observations) recomputed on the line via the ster's `mu:switcher_k` differences so they too vary with $(\phi, \beta)$ (one disclosure sentence in the paper); the lumped cell takes the `delta_unb` ARGUMENT --- the tested lattice value under coverage variant 1, the auxiliary-OLS `unbalanced_choice` coefficient at the point and under variant 2. The lumped-cell source is the auxiliary-OLS coefficient everywhere (it is what variant 1's moment tests, with covariance from the same fit); the OLS-vs-GMM (`xb:unbalanced_choice`) gap is persisted to the diagnostics CSV and the Phase 3 disclosure names the OLS estimator.
4. Baseline (ii): `evaluate_aggregate` gains `dbar0_d`; the value term becomes $\pi_d \Delta_d (\bar D_d - \bar D^0_d)$; the gap term is unchanged; the P3 zeroing of $d_T$ in the value column is removed (it now exits via $\bar D - \bar D^0 = 0$).
5. [CHANGED, review Y1] Coverage variant 1: extend `build_joint_ci_grid` with a third coordinate $\delta_{unb}$ --- one extra moment `unbalanced_choice`$_{OLS} - \delta_{unb}$, Jacobian row appended, dof $K+1$ --- on a grid of $\pm(\sqrt{\chi^2_{K+1, 0.95}} + 1)$ cluster-robust SEs (step $\approx$ SE/5), sized per cell; the widen-and-rerun policy applies to ALL THREE lattice coordinates, not only $\phi$. The aggregate at each accepted 3D point is `delta_at(phi, beta, delta_unb)` (item 3), so the third dimension genuinely moves the interval.
   Coverage variant 2: the existing 2D region with the $\Delta_{unb}$ 95% CI folded in by interval arithmetic.
   Both variants persisted per cell so the user can choose on widths.
6. Cross-check exhibit (D1): fit `beta[s]` for ALL switcher trajectories (moments still over `switchers_kept` only); compute the point aggregate under unrestricted switcher returns; persist the (B)-vs-(A) gap difference per cell to the diagnostics CSV.
7. [CHANGED, review Y5/G2] Guards and diagnostics: schema assertion in `load_cell_inputs` (required columns and scalar keys named; error on any missing or unexpected rename); assert Python's post-filter row and pid counts equal the exporter's exported counts exactly; assert the accepted region touches no lattice edge (error, with the offending margin named); self-check $\Delta_{d_N}$ at the point vs the exported `delta_never_point` (tolerance 0.001) and vs `inv_dN` (0.01) --- on failure the run STOPS and the divergence is investigated, the tolerance is never loosened; write a diagnostics CSV with the per-trajectory decomposition, `marginal_phi`, `marginal_beta`, `n_accept`, `crosses_boundary`, the (B)-vs-(A) deltas, and the OLS-vs-GMM lumped-coefficient gap.
8. E2: `run_hukou_bound` uses the exported `delta_never_point` for the table point (inversion CI unchanged).
9. Tables: value column reflects the new baseline; national row unchanged mechanically (footnote text lives in the paper).
10. OPTIONAL (D5 go): `envelope_curve` per the envelope spec (closed-form censored normal; $s$ grid to the heuristic ceiling; references L and U), CSV + figure in house style.
11. [NEW, review G1] One-cell synthetic check of the 3D inversion (reuse the 2D synthetic harness pattern in the folder): confirm the 3D projected interval strictly contains the same cell's 2D-region-only interval and that simulated coverage is $\ge 95\%$ on a small replication count.
12. [CHANGED, review Y2] Baseline regeneration happens ONLY AFTER the user approves the old-vs-new table at the checkpoint below, as its own commit whose message records what was verified; until then the drift check is expected to fail loudly and that failure is quoted, not suppressed.

Checkpoint: full `12_counterfactuals.do` run; verify the acceptance criteria in the spec (base-4 CHN_uf end to end, $\Delta_{d_N}$ vs `delta_never_point` and `inv_dN`, CHN_rf with-$d_T$ = P3 on the gap); present the user an old-vs-new table of every headline number plus the two coverage variants side by side. USER DECISIONS HERE: coverage variant, then baseline regeneration (item 12).

## Phase 3: paper edits (Overleaf `main-updated.tex`, mirrored in `paper/results_counterfactuals.tex`)

All numbers from the accepted Phase 2 run; one commit per logical edit; one sentence per line.

1. [CHANGED, review G3] Equation (1): value term gains $\bar D^0$, described as the share urban in the FIRST OBSERVED wave (not "initial location" --- histories are left-censored); the "deterministic functions" sentence changes ($\bar D$, $\bar D^0$ estimated for the lumped cell).
2. Identification paragraph (line 820 region): rewrite for D1 --- switcher returns evaluated on the estimated LCA line at each point of the confidence region; unrestricted returns as the cross-check sentence with the computed difference; delete "identified non-parametrically" as a description of what enters the aggregate; one sentence on the sparse-switcher rows (ster-$\mu$ line values).
3. [CHANGED, review Y4] Lumped-cell disclosure: two sentences in the decomposition paragraph (return = the auxiliary-regression unbalanced-mover coefficient applied to the whole cell; its sampling uncertainty is inside the interval per the chosen variant).
4. [CHANGED, review G4] Interval description: update the "convex hulls of the joint $(\phi,\beta)$ region" sentence to the chosen variant; national-row coverage footnote states joint coverage of AT LEAST 90% (a floor under arbitrary dependence, not an approximation).
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