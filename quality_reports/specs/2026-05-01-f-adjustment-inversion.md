# Spec: F-adjustment for finite-sample bias of LCA inversion CIs

Date: 2026-05-01
Branch: `lca-inversion`
Author: Emilia (with Claude)
Mode: Implementation, methodology component

## Context

The Monte Carlo evidence in [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md) and the diagnosis in [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md) document that the LCA inversion CI under-covers in finite samples, with the gap growing in $J_R = K - 1$.
At $T=4$, $K=14$, $J_R=13$, $R=200$ the $\Delta_{\text{avg}}$ CI covers at $0.840$ (MC SE $0.026$); the empty-CI rate is $7.5\%$ vs nominal $5\%$.

The chi-squared memo identifies the Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment as the cheapest principled correction.
The proposal is to replace $\chi^2_{J_R, 1-\alpha}$ in each inversion's accept rule with $J_R \cdot F_{1-\alpha}(J_R, \widehat{\nu})$, where $\widehat{\nu}$ is a Satterthwaite degrees-of-freedom estimate computed from the cluster-leverage structure of the moment-vector variance.

This spec defines the goal, scope, success criteria, and open methodological questions for that implementation.

## Goal

Add an F-adjusted variant of every chi-squared inversion in [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py), verify it against a known-correct OLS anchor (`clubSandwich`), and demonstrate via Monte Carlo that the under-coverage gap at $T=4$, $K=14$ closes toward nominal.
Report results in the existing markdown tables under `explorations/python-grc/results/` alongside chi-squared CIs.
Defer Stata-pipeline integration until after `worktree-grc-pipeline-refactor` merges.

## Requirements

### MUST

1. Closed-form Satterthwaite $\widehat{\nu}$ at each grid point in each inversion.
The formula has to come from a primary source (Imbens-Kolesár 2016 §3, Pustejovsky-Tipton 2018 for unbalanced clusters) and be documented in a memo with the explicit equation, the clustering unit (individual `pid`), and the cluster-leverage matrix definition.
No black-box copy from a package.

2. OLS anchor verification before any GMM application.
Port the formula to a plain OLS-cluster-robust toy problem and verify that $\widehat{\nu}$ matches `clubSandwich::vcovCR(..., type="CR2")` plus `coef_test(..., test="Satterthwaite")` to within numerical tolerance ($10^{-4}$ relative) on at least three test cases (varying $N$, cluster size, $J_R$).
This is the load-bearing correctness check; if we cannot match `clubSandwich` on OLS, we cannot trust the formula on GMM.

3. Coverage evidence at $T=4$, $K=14$, $R=200$.
Re-run [`synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py) with the F adjustment switched on (same seeds 2000--2199 as the chi-squared baseline) and report the four-parameter coverage table.
The F-adjusted $\Delta_{\text{avg}}$ coverage must move toward 0.95.
If it lands inside $[0.92, 0.95]$, the adjustment "closes the gap"; if it lands below 0.92 (still under-covers materially), the spec records this as a finding and escalates to bootstrap calibration in a follow-up.

4. No regressions at smaller $J_R$.
Re-run the existing $T=2$, $K=2$ and $T=3$, $K=6$ synth coverage runs with F adjustment.
Coverage must not drop more than 1 MC SE below the chi-squared baseline at smaller $J_R$.
The F adjustment widens CIs; we want to confirm it doesn't over-correct where chi-squared was already fine.

5. Both 90% and 95% CIs.
The pipeline-integration spec requires both; keep parity here so the markdown tables can be reused downstream.

6. Apply to all four inversions.
$\phi$ via the just-identified `grid_lca_inversion`, $\phi$ via the over-identified `grid_md_inversion`, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$.
The chi-squared bias applies to each one (memo lines 9--10).

7. Preserve chi-squared inversion as a side-by-side option.
The F-adjusted CI is an additional column or row in the markdown tables, not a replacement.
Reasoning: we want the reader to see both, and the F adjustment is itself an asymptotic approximation; reporting both shows the magnitude of the correction.

8. Non-empty result on the empirical three-country cells.
After the synthetic gate passes, re-run [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py) with F adjustment and verify it produces non-empty CIs on the well-identified IDN, CHN, TZA cells.
F adjustment widens CIs, so a previously non-empty CI cannot collapse to empty.
A previously empty CI may become non-empty (the F adjustment is more permissive); flag any such cell.

### SHOULD

1. Memo with derivation and verification table.
Save a numbered memo at `docs/notes/2026-05-01_f-adjustment-derivation.md` with: the explicit Satterthwaite formula adapted to GMM-MD; the cluster-leverage matrix construction in our setting; the OLS-anchor verification numbers; and the synthetic coverage table.
This is the primary deliverable for methodological transparency.

2. Update the validation-gate memo.
Append an "F-adjusted coverage" subsection to [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md) with the synth coverage results, both at $T=4, R=200$ and at the two smaller-$J_R$ regression checks.

3. Compute $\widehat{\nu}$ once per cell (not per grid point) when feasible.
Cache the auxiliary-OLS cluster scores at the start of `compute_all_inversion_cis` and reuse them inside the inversion loops.
Each inversion already loops over the same $\phi$-grid with the same Jacobian structure; if $\widehat{\nu}$ is constant in $\phi$ along the grid, compute it once.
If it varies (see open question 1 below), document it and pay the per-grid-point cost.

### MAY

1. Per-grid-point $\widehat{\nu}$ versus single $\widehat{\nu}$.
The Satterthwaite df depends on the constraint matrix; for the constrained MD inversions in $\Delta$, the constraint changes with $\phi$, so $\widehat{\nu}$ technically varies along the grid.
A single conservative $\widehat{\nu}$ at the chi-squared-Wald minimum (point-estimate $\phi$) may be acceptable; if so, document it as an approximation.

2. Skip the $T=2$, $K=2$ regression check.
That case is already documented as the just-identified $K=2$ pathology and the under-coverage there is structural, not chi-squared bias.
If the F-adjusted version produces equally bad coverage there, that is not a blocker for the rest.

3. Bootstrap calibration as a follow-up.
If the F adjustment fails MUST.3 (coverage stays below 0.92), the next robustness path is Hall-Horowitz (1996) bootstrap calibration of the Wald.
That is out of scope for this spec; it gets its own spec.

## Open methodological questions

1. Does the OLS Bell-McCaffrey formula port directly to our GMM-MD Wald?
The auxiliary OLS in our setup uses individual fixed effects via `alpha[d]` dummies, so `clubSandwich`'s `vcovCR` should apply directly to that auxiliary regression.
The MD Wald combines those OLS coefficients with a Jacobian to project onto the LCA constraint space.
The Satterthwaite formula then needs the constraint Jacobian, exactly as in the OLS case where you test $R\hat\beta = r$ for a $q \times p$ matrix $R$.
The mapping looks clean, but it has to be written down before coding.
This is the load-bearing methodological step.

2. What is the right cluster unit?
We have a panel with individual `pid` and time `period`; observations within `pid` are correlated.
The default is to cluster at `pid`; an alternative would be to cluster at a higher unit (region, country-region) if the user has a strong prior.
The spec assumes `pid` unless the user objects.

3. Pustejovsky-Tipton (2018) versus Imbens-Kolesár (2016).
Pustejovsky-Tipton generalizes Bell-McCaffrey to unbalanced clusters and is what `clubSandwich` actually implements; Imbens-Kolesár is the canonical Stata-world citation but their formula is for balanced or near-balanced clusters.
Our panel is unbalanced (CHN, IDN, TZA all have unbalanced fractions $> 0$).
The spec uses Pustejovsky-Tipton for the implementation (cleaner, matches `clubSandwich` so the OLS anchor is meaningful) and cites both.

4. What constitutes "the gap closes" quantitatively?
The threshold $0.92$ in MUST.3 is one MC SE below the lower bound of the nominal $0.95$ CI.
A stricter threshold ($0.94$) might be desirable; a looser one ($0.90$) might be defensible.
The spec uses $0.92$ at $R=200$ (MC SE $\approx 0.026$); revisit if the data argue for a different threshold.

## Out of scope

- Stata-pipeline integration of F-adjusted CIs into `0_programs.do` or `5b_inversion.do`.
Blocked by the M11 rename and M3 table-builder collapse on `worktree-grc-pipeline-refactor`.
Resume after that merges into our branch.
- Bootstrap-calibrated inversion CI (Hall-Horowitz 1996).
Separate spec, conditional on F adjustment failing.
- Empirically calibrated coverage test (synthesize using each country's actual switcher distribution and unbalanced fractions).
Already a TODO entry; can run in parallel but is not a dependency.
- Point-estimate panel bootstrap on $\widehat{\Delta}_{d_N}$, $\widehat{\Delta}_{\text{avg}}$, $\widehat{\Delta}_{d_T}$.
Already a TODO entry; cross-check rather than primary inference.

## Success criteria

- All MUST items satisfied.
- Memo exists, has the formula, has the OLS anchor numbers.
- $\Delta_{\text{avg}}$ coverage at $T=4, K=14, R=200$ rises from $0.840$ to within $[0.92, 0.95]$ with F adjustment on (or, if it does not, the failure is documented and a Hall-Horowitz spec is queued).
- Three-country empirical inversion table runs to completion with F-adjusted CIs alongside chi-squared CIs.

## Failure modes worth naming

- The OLS anchor doesn't match `clubSandwich`. That implies our Satterthwaite formula is wrong; do not proceed to GMM application until anchored.
- The F adjustment closes the gap on synthetic data but not on the empirical IDN cells. Possible diagnosis: the empirical cluster-leverage structure is more skewed than the synth DGP; the right escalation is bootstrap calibration on the affected specs.
- The F adjustment over-corrects at small $J_R$ ($T=2, T=3$) by widening CIs further than chi-squared. That would be unusual but not impossible; document and consider a $J_R$-conditional rule (use chi-squared at $J_R \le 5$, F-adjusted at $J_R > 5$).
