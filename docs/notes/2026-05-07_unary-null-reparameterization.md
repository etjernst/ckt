# Unary-null reparameterization for `boottest` one-pass $\phi$ CI

Date: 2026-05-07.
Context: Step 0.6 of the rev 5 backend-choice plan.

## What and why

Path D-onepass requires a parameterization where $\phi$ is a single regression coefficient.
The recoded design has $\phi$ implicit in the design matrix---one column per non-base switcher, all parameterized by a common $\phi_0$---so the LCA test is a $(J_R-1)$-dimensional joint null.
`boottest` does not invert multi-coefficient joint nulls in a single bootstrap pass; per the help, the one-pass CI machinery (Chandrupatla bisection, [Roodman et al. 2019](https://doi.org/10.1177/1536867X19874225)) is for unary nulls only.
This memo describes a reparameterization that makes $\phi$ a unary coefficient, what we trade for it, and how to validate it against D-grid.

## The recoded-design parameterization (status quo, D-grid path)

The auxiliary OLS in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) at line 83 is

$$y_i = \sum_{d \in \mathcal{D}} \alpha_d \mathbb{1}\{d_i = d\} + \sum_{s \in \mathcal{S}_R} \beta_s \mathbb{1}\{d_i = s\} D_i + X_i \gamma + \varepsilon_i,$$

with cluster-robust VCV at `pid`.
The LCA restriction $\Delta_i = \beta + \phi \theta_i$ implies the linear contrast

$$r_s(\phi_0) = (\beta_s - \beta_{\underline{d}_0}) - \phi_0 (\alpha_s - \alpha_{\underline{d}_0}) = 0, \qquad s \in \mathcal{S}_R \setminus \{\underline{d}_0\}.$$

Inverting the joint Wald over a $\phi_0$ grid gives the chi-squared CI; the WCU-bootstrap CI replaces chi-squared crit values with WCU crit values at each grid point.
At 30 grid points and $B=9999$, this is the D-grid cost.

## The unary-null reparameterization

First, fit a saturated first-stage OLS of $y$ on the trajectory FE $\{\mathbb{1}\{d_i=d\}\}_{d \in \mathcal{D}}$ and the trajectory-by-treatment indicators $\{\mathbb{1}\{d_i=d\} D_i\}_{d \in \mathcal{S}_R}$, with the same controls and cluster-robust VCV.
Define a per-trajectory comparative-advantage proxy

$$\hat\theta_d = \hat\alpha_d - \hat\alpha_{\underline{d}_0},$$

so $\hat\theta_{\underline{d}_0} = 0$ by construction and $\hat\theta_d$ is the rural-side outcome differential between trajectory $d$ and the base.

Second, refit

$$y_i = \alpha_{d_i} + \beta_{\underline{d}_0} D_i + \phi \cdot \hat\theta_{d_i} D_i + X_i \gamma + u_i, \qquad \phi \in \mathbb{R}.$$

The single regressor $z_i^{\text{LCA}} = \hat\theta_{d_i} D_i$ has $\phi$ as its scalar coefficient.
`boottest` inverts the unary null $\phi = \phi_0$ in one bootstrap pass.
Trajectory FE $\alpha_{d_i}$ stays free; the LCA restriction is imposed only on the treatment-by-trajectory interaction.

### Stata sketch

```stata
* First stage: free alpha_d, free beta_s; recover theta_hat_d
areg lndepvar i.trajectory#1.choice $controls,        ///
    absorb(trajectory) vce(cluster pid)
* Read alpha_hat_d from e(b)["i.trajectory"], compute alpha_hat_d - alpha_hat_base
* and merge back as theta_hat_d on trajectory.

* Second stage: phi as a unary coefficient
gen z_lca = theta_hat_d * choice
areg lndepvar choice z_lca $controls,                 ///
    absorb(trajectory) vce(cluster pid)

* boottest one-pass CI for phi
boottest {z_lca}, weighttype(rademacher) reps(9999) nograph
```

## Tradeoffs vs D-grid

What the unary reparameterization gains.
A single `boottest` call per cell rather than 30, so roughly a 30x compute reduction at fixed $B$.
No per-$\phi_0$ design rebuild; the second-stage regressors are fixed once $\hat\theta_d$ is computed.

What it costs.
First, the LCA restriction is imposed in the second-stage regression rather than tested.
The CI is for $\phi$ given the LCA, not for the over-identifying restrictions test.
Asymptotically the two CIs coincide if the LCA holds; at finite $J^*$ they differ, and the recoded-design CI is more robust to LCA misspecification because it rejects $\phi_0$ where over-identification fails.
Second, $\hat\theta_d$ is a generated regressor, not data, and a naive cluster-robust SE on the second stage understates uncertainty by ignoring estimation of $\hat\theta_d$.

I worry about three handling paths for the generated-regressor problem.

First, cluster-bootstrap both stages jointly: resample pids, refit the first stage, refit the second, run `boottest`.
This restores valid coverage at the cost of nesting `boottest` inside an outer cluster bootstrap, and the compute saving over D-grid mostly evaporates.

Second, treat $\hat\theta_d$ as fixed and document the bias; flag the resulting CI as a lower bound on the true CI width.
This is acceptable as an internal benchmark but insufficient for the published table.

Third, use the unary CI as a sanity check against D-grid at small $J$ and commit to D-grid for production.
This is what the rev 5 plan implicitly assumes when it allows D-onepass to fail to D-grid.

## Validation against D-grid

At TZA $J=1500$ recoded covs_trend, with $\phi_0 = \hat\phi$ as the reference point.

First, run the unary `boottest` and record the point estimate, the cluster-robust SE, and the 95% CI.

Second, run D-grid with 30 grid points and the same $B = 9999$ and record the CI.

Third, pass criterion: unary CI endpoints lie within the D-grid CI to $\pm 0.01$ on $\phi$.
On pass, D-onepass becomes the headline path and D-grid stays as the validation reference and the LCA-misspecification fallback.
On fail, D-grid stays as production; document the discrepancy and the most plausible source (LCA misfit, generated-regressor bias, or different test statistic).

## What this memo is not

It is not a derivation of the joint sampling distribution under generated regressors.
It is not a proposal to replace the existing $\chi^2$ inversion in `lca_inversion.py`.
It is a feasibility note for path D-onepass, conditional on the validation pass criterion above.

## Decision (2026-05-07): D-grid as production, do not pursue D-onepass

After review by both an econometrics critic ([`quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md)) and a Stata critic ([`quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md)), the unary-null path does not survive scrutiny in the form proposed.
Three reasons.
First, the Stata sketch as written does not recover $\hat\alpha_d$ from `areg`'s `e(b)` (the absorbed FE are partialled out, not stored), and both stages of the sketch carry collinearity issues with `absorb(trajectory)` that silently change the estimand.
Second, the unary $\hat\phi$ is a different estimator from the D-grid $\hat\phi$, even at $B = \infty$: D-grid is minimum-distance-weighted joint Wald inversion; the unary stage is OLS-projection-onto-LCA with OLS-implicit weighting.
The two coincide only if all $J_R$ over-identifying contrasts hold exactly in sample, which will not happen at $J_R \geq 2$.
Third, the generated-regressor handling menu in this memo missed standard alternatives (Murphy-Topel analytical correction, score bootstrap, sample splitting), and the framing of the D-grid path as "less compute-efficient" understates how cheap D-grid actually is at production scale.

The Step 0.6 smoke at TZA $J = 1500$ with $B = 999$ ran in three seconds wall and confirmed that single-fit `boottest` joint-null cost is sub-second.
At production $B = 9999$ across 30 grid points, D-grid IDN-scale lands in the few-hours-per-cell range---an order of magnitude faster than `summclust` and well within budget.
D-grid is also the validation reference; making it the production path avoids divergence between headline and check.

The memo stays in the docs as a record of the consideration.
The unary path could be revisited if a referee specifically asks for `boottest` one-pass inversion and the methodological corrections (Murphy-Topel, fixed Stata sketch, validation against the right object) are then in scope.
