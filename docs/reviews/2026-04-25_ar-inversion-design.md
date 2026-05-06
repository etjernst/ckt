---
title: AR-style test-inversion confidence intervals for the worker-level LCA estimator
author: Emilia (with Claude)
date: 2026-04-25
audience: LCA_inversion agent
---

# Goal

Build cluster-robust Anderson--Rubin (AR) test-inversion confidence intervals for the LCA slope $\phi$ in the GRC model of [`docs/reviews/2026-04-25_robust-vv-equivalence-proof.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_robust-vv-equivalence-proof.md). AR-inversion gives correct coverage even under weak identification, which matters here because (i) the pooled GMM has shown convergence sensitivities to starting values across countries, and (ii) cluster-S has been near-rank-deficient on at least IDN's unbalanced sample (see [`docs/reviews/2026-04-23_se-phi-diagnostic.md`](file:///C:/git/ckt/docs/reviews/2026-04-23_se-phi-diagnostic.md)).

# Recommended path: AR on the worker-level Verdier moment, not the pooled CKT moment

The trajectory-pooled estimator [`run_grc_robust_vv`](file:///C:/git/ckt/RP7/scripts/0_programs.do) and Verdier's worker-level GMM target the same $\phi$ under A1, A2$'$, A3 (equivalence proof and Phase C MC at [`docs/reviews/2026-04-25_simulation-results.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-results.md)). Build AR on the worker-level moment; use the equivalence as the bridge.

Three reasons.

1. **Mechanical simplicity.** VV's moment is a single equation with one slope and one constant: $E[z_i (a_i - \alpha_0 - \alpha_1 \cdot \text{return}_i)] = 0$, $z_i$ a vector of cluster-demeaned period-treatment instruments. AR inversion at fixed $\alpha_1 = 1/\phi_0$ requires profiling out only $\alpha_0$, which has a closed-form solution (the moment is linear in $\alpha_0$). Compare to the pooled GMM, where each grid point requires re-optimizing the full $(\mu_s, \Delta_s, \beta(v), \text{period FE})$ nuisance vector --- expensive and prone to local minima.

2. **Robustness to alpha-pooling bias.** Phase D shows the worker-level estimator stays consistent under the empirically relevant Mode B failure (differential cluster assignment, A3 still holds), while the pooled estimator picks up a $+0.20$ bias at the IDN-calibrated TV $= 0.252$. AR inversion does not correct bias; it only fixes coverage. So AR on the pooled moment would give a correctly-sized interval centered on the wrong target whenever Mode B holds. AR on the worker-level moment is unbiased in both R1 and R2a regimes.

3. **VV's published implementation is the natural inversion target.** VV's [`Table1/Code/robust.do`](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do) line 7 already writes the moment we'd invert. Per Phase A.1 ([`docs/reviews/2026-04-25_simulation-phase-a-derivations.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-phase-a-derivations.md) §A.1), $\alpha_1 = 1/\phi$ under CKT's convention, so converting between $\phi$-grid and $\alpha_1$-grid is a one-line transformation.

# What AR inversion buys us, what it doesn't

| Concern | AR fixes? | Notes |
|---|---|---|
| Weak instruments / small effective IV variation | Yes | The whole point. |
| Rank-deficient cluster-S | Partially | Use the just-identified version (one summary instrument) or Moore--Penrose pseudoinverse on the cluster-S in the AR quadratic form. |
| Alpha-pooling bias (Mode B) | No | Use worker-level moment; AR on pooled moment centers on biased plim. |
| A3 failure (Mode A) plus differential cluster assignment | No | Both estimators biased; report the gap as a diagnostic. |
| Few clusters ($V \approx 50$ in CHN/TZA) | Partially | Combine AR with cluster-jackknife or wild-cluster bootstrap; the asymptotic $\chi^2$ may under-cover. |

# Mechanics of the AR statistic

Let $g_i(\alpha_0, \alpha_1) = z_i (a_i - \alpha_0 - \alpha_1 \cdot \text{return}_i)$ with $z_i$ the $q$-vector of village-demeaned period-treatment instruments (VV's `hybrid*d`). At a fixed $\phi_0$, set $\alpha_1 = 1/\phi_0$. Profile out $\alpha_0$ by closed-form (the moment is linear in $\alpha_0$):

$$\hat\alpha_0(\phi_0) = \overline{a - \tfrac{1}{\phi_0} \text{return}}.$$

Form the cluster-robust covariance of the residual moment:

$$\hat S(\phi_0) = \frac{1}{N} \sum_{c=1}^{C} \Big(\sum_{i \in c} \hat g_i(\hat\alpha_0(\phi_0), 1/\phi_0)\Big)\Big(\sum_{i \in c} \hat g_i(\hat\alpha_0(\phi_0), 1/\phi_0)\Big)^\top$$

clustered on $\text{vfirst}$. The AR statistic is

$$\text{AR}(\phi_0) = N \cdot \bar g(\phi_0)^\top \hat S(\phi_0)^{-1} \bar g(\phi_0).$$

Reference distribution: asymptotically $\chi^2_{q-1}$ (one degree of freedom absorbed by profiling $\alpha_0$). For finite-sample correction with few clusters, use $F_{q-1, C - q}$ scaled appropriately.

The CI for $\phi$ is

$$\big\{ \phi_0 : \text{AR}(\phi_0) \leq \chi^2_{q-1, 1-\alpha} \big\}.$$

# Implementation in Stata

Loop over a $\phi$-grid. At each grid point, impose $\alpha_1 = 1/\phi_0$ in `gmm` (use the `from()` option with a tight constraint, or compute the moment by hand and form $\bar g, \hat S$ directly --- the latter is cleaner). Save AR. Determine grid bounds adaptively from the unconstrained $\hat\phi$ point estimate $\pm 5 \cdot \text{SE}$, then refine.

```stata
* Pseudo-code
local phi_lo = -2.0
local phi_hi =  0.5
local n_grid = 401
local phi_step = (`phi_hi' - `phi_lo') / (`n_grid' - 1)

forvalues k = 1/`n_grid' {
    local phi0 = `phi_lo' + (`k' - 1) * `phi_step'
    local a1   = 1 / `phi0'

    * Profile out alpha_0
    qui sum a if e(sample), meanonly
    local mean_a = r(mean)
    qui sum return_pid if e(sample), meanonly
    local mean_r = r(mean)
    local a0_hat = `mean_a' - `a1' * `mean_r'

    * Form moment vector: z_i * (a_i - a0_hat - a1*return_pid)
    * (use putmata or matrix accum to build g_bar, S_hat clustered on vfirst)
    * AR = N * g_bar' * inv(S_hat) * g_bar
    ...
    matrix AR_grid[`k', 1] = `phi0'
    matrix AR_grid[`k', 2] = `AR'
}
```

Then post-process the grid: report all $\phi_0$ with $\text{AR} \leq \chi^2_{q-1, 0.95}$, and the two endpoints (or the multiple connected segments if the curve is non-monotone).

# Reporting

For each (country, depvar, choice, balance) cell, output:

1. Point estimate $\hat\phi_{\text{VV}}$ from the unconstrained worker-level GMM (already in `x_main_comparison_results.dta`).
2. AR-VV CI as either an interval $[\phi_L, \phi_U]$ or the full set if non-convex.
3. For comparison: the standard delta-method CI implied by $\hat\alpha_1 \pm 1.96 \cdot \text{SE}$, transformed to $\phi$.
4. As a diagnostic: the gap $\hat\phi_{\text{CKT}} - \hat\phi_{\text{VV}}$, which under the equivalence proof is approximately the alpha-pooling bias. Large gaps (e.g., IDN) flag Mode B exposure.

# Open questions

- Whether to also implement AR-inversion on the pooled CKT moment for direct reporting in the paper. Argument for: matches the headline estimator. Argument against: under Mode B the pooled CI is a confidence interval for the wrong quantity. Recommendation: report AR-VV in the main text and a footnote noting the gap.
- Grid resolution and bound choice: 401 points over $[-2.0, 0.5]$ is a starting default; tighten adaptively after a coarse pass.
- Whether to combine AR with wild-cluster bootstrap for the few-cluster cases (TZA, CHN). VV's published SEs use plain cluster-robust with $V \approx 50$; coverage at this $V$ is borderline. The MC at $V = 25$ produced clean coverage in the point-estimate distribution, but coverage of nominal-95% CIs was not directly tested.

# Files referenced

- [`docs/reviews/2026-04-25_robust-vv-equivalence-proof.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_robust-vv-equivalence-proof.md) --- equivalence proof.
- [`docs/reviews/2026-04-25_simulation-phase-a-derivations.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-phase-a-derivations.md) --- $\alpha_1 = 1/\phi$ identity, alpha-pooling bias formula.
- [`docs/reviews/2026-04-25_simulation-results.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-results.md) --- MC verdict.
- [`explorations/verdier/x_equivalence_simulation_sanity.do`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation_sanity.do) --- $N = 50{,}000$ sanity check (PASS).
- [`explorations/verdier/x_equivalence_simulation.do`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation.do) --- 100-rep MC do-file.
- [`tmp/vv-replication/replication_archive/Table1/Code/robust.do`](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do) --- VV's reference moment.
- [`docs/reviews/2026-04-23_se-phi-diagnostic.md`](file:///C:/git/ckt/docs/reviews/2026-04-23_se-phi-diagnostic.md) --- prior SE$(\phi)$ rank-deficient cluster-S diagnostic.
- [`explorations/verdier/x_main_comparison_results.dta`](file:///C:/git/ckt/explorations/verdier/x_main_comparison_results.dta) --- main 3 countries $\times$ 5 covariates point estimates.
