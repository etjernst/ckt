# V3 IDN empty-CI diagnostic: Wald at the GMM point estimate

**Date:** 2026-05-20.
**Branch:** lca-inversion.
**Plan reference:** Milestone V3 of [the counterfactual plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).
**Files:**

- Driver: [explorations/2026-05-20_e1_v3_wald_at_gmm.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_wald_at_gmm.py)
- Module under diagnosis: [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py) (`build_joint_ci_grid`)
- Upstream module: [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) (`fit_auxiliary_ols`, `grid_lca_inversion`)
- Reference Stata: [RP7/scripts/5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do)

## Question

The V3 smoke (2026-05-18) returned zero accepted lattice points for IDN col 5 at $\alpha = 0.05$, but 5b's attached scalars give a marginal $\phi$ CI of $[-1.23, -0.01]$.
Is the empty grid CI a lattice/coverage artifact, or is the joint-CI construction in `build_joint_ci_grid` mis-specified?

## Diagnostic

Evaluate the constrained-$J$ inside `build_joint_ci_grid` at the GMM point estimate $(\hat\phi, \hat\beta) = (-0.5247, +0.0672)$ and compare to $\chi^2_{K, 0.95}$, where $K$ is the number of moments (= number of kept switchers).
At the GMM point, the LCA restriction should approximately hold on the auxiliary-OLS estimates, so the Wald should fall well below the threshold.
A Wald in the hundreds points to a moment-formula or spec mismatch.

## Result

**First pass: pythonic defaults (`log(consumption)`, no controls).**

| object | value |
|---|---:|
| Wald at $(\hat\phi, \hat\beta)$ | $846$ |
| $\chi^2_{27, 0.95}$ threshold | $40.1$ |
| Marginal $\phi$ CI from `grid_lca_inversion` | empty |
| Marginal Wald at $\hat\phi$ | $622$ |
| Auxiliary OLS $\hat\beta_2$ (base switcher) | $+0.8285$ |
| GMM $\hat\Delta_2$ from parent ster | $+0.0672$ |

The auxiliary OLS $\hat\beta_2 = +0.83$ is a 12x discrepancy from the GMM's $\hat\Delta_2 = +0.07$.
These should be the same object: the urban-rural shift in log per-capita consumption for trajectory $2$.
The discrepancy localizes the bug: the auxiliary OLS in `fit_auxiliary_ols` is not estimating the same population object as the GMM specification it is supposed to invert.

## Root cause

The smoke driver and `fit_auxiliary_ols` defaults use a misspecified auxiliary regression relative to the GMM spec it must match.
Reading [5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do) lines 75 and 95--147 shows what Stata-side 5b actually does for the `cuu_ca` cell:

- Outcome is `lndepvar = log(consumption / hhsize_cube)` (line 75 of 5b, line 136 of 4_GrRC.do), where `hhsize_cube` is the cube-root equivalence scale used throughout the GMM pipeline.
- Controls are `periodFE \$covs_gmm_all`, i.e., period fixed effects plus `female`, `age2`, `education_max`, `education_max2` (5b lines 114--117).
- Sample selection mirrors `set_covariates` in `0_programs.do`: drop `mi(education_max)`, `mi(age)`, and `obs_per_individual == 1`.

The Python smoke driver passed `log(consumption)` (not per-capita) and no controls.
The auxiliary $\hat\beta_s$ therefore picked up unconditional urban-period mean log consumption levels rather than the urban-rural shift conditional on covariates, leaving the OLS estimates inconsistent with the LCA restriction at any $(\phi, \beta)$ in the relevant region.

## Confirmation

Re-running the diagnostic with the matched outcome (`lndepvar = log(consumption/hhsize_cube)`) and the matched controls (period dummies + female + age² + education + education²), and matched sample selection:

| object | value |
|---|---:|
| Wald at $(\hat\phi, \hat\beta)$ | $24.2$ |
| $\chi^2_{27, 0.95}$ threshold | $40.1$ |
| Marginal $\phi$ CI from `grid_lca_inversion` | $[-1.153, +0.745]$ |
| Marginal Wald at $\hat\phi$ | $23.5$ |
| 5b's attached marginal $\phi$ CI | $[-1.23, -0.01]$ |

The construction is right.
The joint Wald at the GMM point falls below threshold, so the GMM point should be accepted in the joint CI.
The original empty-grid CI was caused by the auxiliary-OLS spec mismatch, not by a moment-formula or Jacobian bug in `build_joint_ci_grid`.

## Residual disagreement with 5b

The Python marginal $\phi$ CI is $[-1.153, +0.745]$ against 5b's attached $[-1.23, -0.01]$.
The lower bound matches closely ($-1.15$ vs $-1.23$); the upper bound is materially wider in Python ($+0.745$ vs $-0.01$).
Possible sources, in order of likelihood:

1. **Sample-selection mismatch.**
   `set_covariates` may drop additional observations beyond what was reproduced here.
   The exact `keepvars`, the `unbalanced` indicator's interaction with the OLS, and the handling of trajectory NaNs could differ.
2. **Inversion procedure.**
   `attach_inversion_ci` in `0_programs.do` might use a different test statistic or grid than `grid_lca_inversion`.
   Worth reading before assuming the OLS is the only culprit.
3. **Cluster correction.**
   The Python OLS uses statsmodels' cluster-robust SE with `use_correction=True`; Stata's `vce(cluster pid)` default has a slightly different small-sample correction.
   Unlikely to drive a CI of width $\approx 1.9$ vs $1.2$, but worth ruling out.

The lower-bound agreement is reassuring.
The upper-bound disagreement is the next question to chase down, but it does not block the V3 plumbing fix below.

## Next steps

1. **Fix `fit_auxiliary_ols` defaults / call sites.**
   The current implementation supports `controls=` and a configurable `outcome=`, so the fix is to update the V3 smoke driver (and any other call site) to pass the matched outcome and controls.
   Alternatively, the V3 smoke can pull the auxiliary OLS estimates directly from a Stata-side exporter mirroring 5b's regression, sidestepping the Python reimplementation.
2. **Refine the V3 lattice** around $(\hat\phi, \hat\beta) = (-0.5247, +0.0672)$ and re-run `build_joint_ci_grid`.
   With the construction now sound, the accepted region should contain the GMM point and the joint CI should be non-empty.
3. **Run down the residual upper-bound disagreement** with 5b.
   Read `attach_inversion_ci` in `0_programs.do`, inspect the exact `set_covariates` drops, and compare a side-by-side Stata vs Python aux-OLS run at one phi grid point.
4. **TZA Möbius-pole fallback** (plan's P3): unchanged from the prior open-items list.
5. **CHN hukou-split inversion CIs** (RF/UF priority, then RO/UO): unchanged from the prior open-items list.
