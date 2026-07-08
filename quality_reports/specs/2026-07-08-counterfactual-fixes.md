# Spec: fix the E1/E2 counterfactual findings (review 2026-07-08)

Date: 2026-07-08.
Source: [2026-07-08_counterfactual-implementation-review.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-implementation-review.md).
Scope: `RP7/scripts/{12_counterfactuals,_export_e1_inputs,_export_e1_inputs_hukou}.do`, `explorations/python-grc/counterfactuals.py`, the two generated tables, the counterfactual subsection prose, and the frozen baseline CSV.
Out of scope: any GRC GMM re-fit (all fixes reuse existing sters), the E2 resorting version (separate work stream), sections of the paper outside `sec:counterfactuals`.

## MUST

1. (C1) Compute every LCA object inside E1 from one consistent per-capita, covariate-adjusted source: the auxiliary-OLS fit already estimated in `run_cell`.
   Concretely, `delta_at` uses $\mu_{d_N} - \mu_{base} = \alpha[\text{never}] - \alpha[\text{base}]$ from `fit.b`, replacing the raw-data `mu_d` CSV in the LCA extrapolation.
   Acceptance: at the point estimate, the E1 $\Delta_{d_N}$ reproduces the ster's `inv_dN` within grid resolution (0.01) for all four cells.
2. (C2) The with-$d_T$ variant uses $\alpha[d_T]$ from the same fit in the Mobius formula, replacing `compute_alpha_dT_obs`; no formula may difference quantities from two different consumption scales.
3. (M4) The exporters write the ster's base trajectory into the scalars CSV (recovered by matching `Delta_base:_cons` to the `_d` ster's `Delta_k` within 1e-10; error out if no unique match).
   Python asserts the exported base is in `switchers_kept` and uses it (not a hardcoded 2) for the grid coordinates, `mu_base`, and the point plug-in.
   Acceptance: CHN_uf runs with base 4 end to end; IDN/TZA/CHN_rf results identical to a base-2 run.
4. (M1) Switcher returns feeding equation (1) are genuinely unrestricted per the chosen convention (decision D1); the `_d`-ster LCA-fitted values leave the E1 path.
5. (M2) The lumped-cell return keeps its estimand but its sampling uncertainty enters the reported intervals (decision D2/D4), and the paper discloses the assumption (one or two sentences in the decomposition paragraph).
6. (M3) One zero-migration baseline convention, applied consistently in the equation, the code, and the prose (decision D3), with the $d_T$ handling of the value column following from the convention rather than from a silent P3 zeroing.
7. (M5) The CHN national interval's stated coverage is honest under the chosen inference scheme (decision D4).
8. Regenerate `counterfactual_results.csv`, both tables, and the baseline snapshot (`regenerate_baseline=True`) in one verified run of `12_counterfactuals.do`; update every counterfactual number quoted in the paper prose to the refreshed values; the review memo gains a status footer recording old vs new headline numbers.
9. (Minor 3) The hukou-bound per-never-migrant point is the `_n` ster's `Delta_never` (exported by the hukou exporter), not the grid-snapped `inv_dN`; the CI stays the inversion CI.

## SHOULD

10. (Minor 2) Persist the per-trajectory decomposition (already computed in `AggregateResult`) plus `marginal_phi`, `marginal_beta`, `n_accept`, and `crosses_boundary` per cell to a diagnostics CSV next to the results CSV.
11. (Minor 5) `run_cell` raises (or loudly warns) if the accepted joint-CI region touches any edge of the $(\phi, \beta)$ lattice.
12. (C1 root cause) Fix the exporters' dead `mu:switcher_` extraction (`coleq` + `colnames` pairs) and export the ster $\mu$'s as a cross-check column; add a Python self-check that the OLS-based $\Delta_{d_N}$ and the ster `inv_dN` agree within 0.01.
13. (Minor 1) Implement the Gaussian dispersion envelope the paper promises (decision D5): at each accepted $(\phi, \beta)$, integrate $\max(0, \beta + \phi\theta)$ against $\theta \mid d_N \sim N(\mu_{d_N} - \mu_{base}, (c\,\sigma_\theta)^2)$ with $\sigma_\theta$ = cross-trajectory dispersion of the $\alpha_d$'s, sweep $c \in \{0, 0.25, 0.5, 0.75, 1\}$, and persist the envelope curve (figure or CSV; prose points to it).
14. (Minor 4, 6) Prose repairs in the counterfactual subsection: "balanced-panel never-migrant share" for $\pi_{d_N}^{rh}$; drop or qualify "deterministic functions of trajectory definitions"; align the caveat-paragraph quoted numbers with the refreshed with-$d_T$ variant or cut them.
15. Remove the unused `pi_helper`; compute $\pi_d$/$\bar D_d$ on the same row filter the Python fit uses.

## MAY

16. Report the four-way decomposition in a small table panel or appendix rather than prose only.
17. Align `hukou_population_weights` to the filtered sample used for $\pi_d$.

## Decisions (status as of 2026-07-08 afternoon)

D1 (M1) switcher-return convention: OPEN, out for independent adjudication by critic-econometrics (report to land at `quality_reports/reviews/2026-07-08_switcher-delta-convention-adjudication.md`).
Candidates: (a) unrestricted auxiliary-OLS `beta[s]`, held fixed across the region; (b) LCA-line returns $\beta + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ recomputed at each grid point.
Whichever wins, BOTH are computed and compared as a validation exhibit (they should sit close since the $J$-test passes); the current frozen hybrid (LCA-fitted at the point estimate while $(\phi,\beta)$ vary) is retired either way.

D2 (M2) lumped-cell treatment: DECIDED (a) --- keep $\hat\Delta_{unb}$ as the cell's return, propagate its sampling uncertainty into the interval (see D4), disclose the assumption in prose.

D3 (M3) zero-migration baseline: DECIDED --- initial-location baseline.
Export the trajectory-mean first-observed-wave urban share $\bar D^0_{\underline{d}}$; the value term becomes $\pi_{\underline{d}} \Delta_{\underline{d}} (\bar D_{\underline{d}} - \bar D^0_{\underline{d}})$; $d_T$ drops out of the value column by construction; the equation display changes accordingly; value-of-migration numbers will fall.

D4 (M2+M5) interval coverage: DECIDED --- compute BOTH variants, then choose on the numbers.
Variant 1: extend the test inversion to a joint 3D region for $(\phi, \beta, \Delta_{unb})$ (one extra moment from the same auxiliary fit, dof $K+1$), project the aggregate through it; honest $\ge 95\%$ per cell with no widening tricks.
Variant 2: the 2D region with the $\Delta_{unb}$ 95% CI combined by interval arithmetic, labeled transparently (joint coverage $\approx 90\%$).
Bonferroni budgets are REJECTED (user, 2026-07-08).
National CHN row: interval-arithmetic combination of the per-cell intervals with a transparent coverage footnote; no widening.

D5 (Minor 1) dispersion envelope: OPEN, pending user go/no-go on the standalone spec [2026-07-08-dispersion-envelope.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-dispersion-envelope.md), which SUPERSEDES item 13 above.
Regardless of go/no-go, the incorrect law-of-total-variance sentence leaves the paper.

D6 paper-side edits: DECIDED --- apply prose changes directly in the Overleaf `main-updated.tex` (user approval given 2026-07-08), mirrored in the worktree's `paper/results_counterfactuals.tex`.

## Verification

- `12_counterfactuals.do` runs clean end to end; self-checks pass against the regenerated baseline.
- Cross-consistency: E1 $\Delta_{d_N}$ at the point vs ster `inv_dN` (all cells, within 0.01); hukou-bound point vs the RF GRC table's $\Delta_{\text{never}}$ (exact); paper prose numbers vs the refreshed CSV (exact).
- CHN_rf with-$d_T$ gap hull still equals its P3 hull (theory check).
- critic-alignment pass on the refreshed tables vs the rewritten prose.
