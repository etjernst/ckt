# LCA inversion CI for Verdier robust spec --- design options

**Date:** 2026-04-24
**Context:** The parent session's [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) implements weak-ID-robust CIs for the LCA slope $\phi$ in the simple GRC via grid test inversion. This memo thinks through how to extend that machinery to [run_grc_robust_vv](file:///C:/git/ckt/RP7/scripts/0_programs.do) (the VV-style cluster-demeaned-instrument spec).

## 1. What the simple-spec prototype actually does

Reading [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) carefully:

1. **Saturated auxiliary OLS** on a just-identified model (no LCA restriction imposed):
   $$y_{it} = \sum_{d} \alpha_d \mathbb{1}\{d_i = d\} + \sum_{s \in S} \beta_s \mathbb{1}\{d_i = s\} D_{it} + x_{it}' \gamma + \varepsilon_{it}$$
   Cluster-robust SE at $\text{pid}$. One $\alpha_d$ per trajectory, one $\beta_s$ per switcher. Sparse switcher trajectories (too few treated clusters) get dropped before the fit.

2. **LCA restriction at fixed $\phi_0$:**
   $$r_s(\phi_0) = (\beta_s - \beta_{s_0}) - \phi_0 (\alpha_s - \alpha_{s_0}) = 0 \quad \forall s \in S \setminus \{s_0\}$$
   This is linear in the OLS coefficients for fixed $\phi_0$.

3. **Wald statistic at $\phi_0$:** $W(\phi_0) = r(\phi_0)' \hat V_r^{-1}(\phi_0) r(\phi_0)$. Under $H_0: \phi = \phi_0$, $W \sim \chi^2_{\|S\|-1}$. Jacobian is a constant selector matrix, so $\hat V_r$ is one matrix sandwich.

4. **Grid inversion:** $\text{CI}_\alpha = \{\phi_0 : W(\phi_0) < \chi^2_{\|S\|-1, 1-\alpha}\}$.

Key property: the expensive step (the OLS) happens once. Only the Wald sandwich is computed per grid point. CI can be unbounded, disjoint, or empty when $\phi$ is weakly identified --- honest in that regime.

Not mechanically a refit-constrained-GMM-at-each-grid-point procedure --- it's purely algebraic on the OLS coefficient vector.

## 2. What changes under Verdier

The Verdier-robust LCA restriction is stronger than the simple one:
$$\Delta_i = \beta(v_i) + \phi \mu_{d_i}$$
Cluster-specific intercept, common slope. In OLS coefficient terms:
$$(\beta_{s,v} - \beta_{s_0, v}) - \phi (\mu_s - \mu_{s_0}) = 0 \quad \forall s \in S \setminus \{s_0\},\ \forall v \in V$$
(Intercept $\beta(v)$ cancels within cluster --- that's the point.)

Two design directions follow.

## 3. Option A --- saturated OLS with $(s, v)$-indexed betas

Fit:
$$y_{it} = \sum_{d,v} \alpha_{d,v} \mathbb{1}\{d_i = d, v_i = v\} + \sum_{s, v} \beta_{s,v} \mathbb{1}\{d_i = s, v_i = v\} D_{it} + x'\gamma + \varepsilon$$

- Parameters: $\|D\| \cdot \|V\|$ alphas + $\|S\| \cdot \|V\|$ betas + covariates. For TZA ($\|V\|=26$, $\|S\|=5$, $\|D\|=7$): 7 $\times$ 26 + 5 $\times$ 26 = 312 coefficients. Many cells will be empty (rank-deficient).
- Wald restriction: $(\|S\|-1) \cdot \|V\|$ constraints at fixed $\phi_0$. TZA: $4 \cdot 26 = 104$ df.

Issues:
- High df kills power. Chi-square critical at 5% with 104 df is ~129, so we need a Wald statistic > 129 to reject --- hard.
- Sparse cells give unidentified $\beta_{s,v}$. Would need sparsity-aware drop analogous to [drop_sparse_switchers](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py), extended to $(s, v)$ cells.
- Structurally analogous to the failed single-step `run_grc_robust` cluster-FE-parameter route (§5 of [2026-04-23_robust-grc-derivation.md](file:///C:/git/ckt/docs/reviews/2026-04-23_robust-grc-derivation.md)).

Not recommended.

## 4. Option B --- cluster-demeaned OLS (recommended)

Keep the trajectory-pooled beta structure from the simple prototype, but make the OLS regressors within-cluster-demeaned. Specifically:

1. For each switcher trajectory $s$, construct the within-cluster-demeaned treatment instrument:
   $$z_{s, it} = \mathbb{1}\{d_i = s\} (D_{it} - \bar D_{s, v_i})$$
   where $\bar D_{s, v}$ is the mean of $D$ among trajectory-$s$ workers in cluster $v$. This is exactly the [swd_switcher_s_choice](file:///C:/git/ckt/RP7/scripts/0_programs.do) construction from `run_grc_robust_vv`.

2. Saturated auxiliary OLS:
   $$y_{it} = \sum_{d, v} \alpha_{d, v} \mathbb{1}\{d_i = d, v_i = v\} + \sum_s \beta_s^{\text{w}} z_{s, it} + x' \gamma + \varepsilon_{it}$$
   - $\alpha_{d, v}$ (trajectory $\times$ cluster FE) absorbs between-cluster intercepts. Can be done via `areg`/`reghdfe` or explicit dummies.
   - $\beta_s^{\text{w}}$ is the pooled within-cluster effect of treatment for trajectory-$s$ workers. One per switcher, same as simple spec.
   - Cluster-robust SE at $v_{\text{first}}$.

3. LCA restriction (same structure as simple):
   $$r_s(\phi_0) = (\beta_s^{\text{w}} - \beta_{s_0}^{\text{w}}) - \phi_0 (\bar\alpha_s - \bar\alpha_{s_0}) = 0$$
   where $\bar\alpha_s = \sum_v w_v \alpha_{s, v}$ for some cluster weights $w_v$ (sample-share natural).

4. Wald at $\phi_0$ with $\|S\| - 1$ df, same machinery as simple.

5. Invert over a grid.

**Why this works:**
- Parameter count is manageable --- trajectory$\times$cluster FE are absorbed, not estimated as free Wald targets. The Wald targets are just the $\|S\|$ pooled $\beta_s^{\text{w}}$ coefficients (and trajectory means for the restriction).
- Test df same as simple ($\|S\|-1$), so power is comparable.
- Structurally mirrors the `run_grc_robust_vv` identification (within-cluster variation in treatment).
- Asymptotically the test has correct size regardless of whether $\phi$ is strongly or weakly identified. Strong: CI is a bounded interval around $\hat\phi$. Weak: CI is wide / unbounded / disjoint. That's the AR-style honesty property.

**Implementation sketch:**
```python
# Drop-in analog of fit_auxiliary_ols, with cluster FE + demeaned D
def fit_auxiliary_ols_robust(df, outcome, trajectory, choice, hhid, vfirst,
                              switchers_kept, controls):
    # 1. Within-cluster-demean the switcher x choice interactions
    df = df.copy()
    for s in switchers_kept:
        col = f"z[{s}]"
        df[col] = (df[trajectory] == s).astype(float) * df[choice].astype(float)
        # Demean within (trajectory==s, vfirst) cell
        means = df.loc[df[trajectory] == s].groupby(vfirst)[col].transform("mean")
        df.loc[df[trajectory] == s, col] -= means.values
        df[col] = df[col].fillna(0.0)

    # 2. Absorb trajectory x vfirst fixed effects via statsmodels or pyfixest
    # (large number of dummies: use FixedEffectsModel or residualize y, z)
    ...

    # 3. Return coefficients + cluster-robust VCV
```

Critical detail: the variance matrix $\hat V$ must be clustered at $v_{\text{first}}$, not pid. Otherwise the "robust" SE story falls apart.

## 5. Option C --- GMM-criterion inversion

Constrain $\phi = \phi_0$ in [run_grc_robust_vv](file:///C:/git/ckt/RP7/scripts/0_programs.do)'s GMM equation (substitute literal $\phi_0$, no free phi parameter), refit, record the GMM criterion $Q(\phi_0)$. Test statistic: either $n Q(\phi_0)$ (Stock-Wright $S$) or $n [Q(\phi_0) - Q(\hat\phi)]$ (LR-style). Invert.

**Why this is problematic:**
- Under one-step GMM with `winitial(unadjusted, independent)`, $n Q(\phi_0)$ is NOT asymptotically $\chi^2_{k-p+1}$ because the weighting matrix is not the inverse of the moment variance.
- Switching to two-step to get proper asymptotics brings back the rank-deficient cluster-robust $\hat \Sigma$ problem (the whole reason we abandoned the cluster-FE route).
- Could use a Moore-Penrose pseudoinverse for $\hat\Sigma^{-1}$ and accept some power loss, but adds complexity.

Not recommended unless we find a way to sidestep the rank-deficient weighting.

## 6. Option D --- wild cluster bootstrap CI

Fit `run_grc_robust_vv` once. Use `boottest` with `ci` option to get a wild cluster bootstrap CI for $\phi$:
```stata
boottest {phi=0}, reps(9999) weighttype(webb) cluster(vfirst) ci
```

**Why this is the easiest valid route:**
- `boottest` handles few-cluster distortions via wild bootstrap (Cameron, Gelbach, Miller 2008; Roodman 2019).
- Works with `gmm` (we verified this earlier for the retired `run_grc_robust` plan).
- Automatically inverts the test to get the CI.
- Weak-ID behavior is less crisp than test inversion (bootstrap distribution concentrates around $\hat\phi$ even when that estimate is uninformative) --- so not AR-honest in the same sense as Option B.

## 7. Recommendation

Primary recommendation: **Option B (cluster-demeaned saturated OLS + Wald inversion)**. Clean analog of the simple-spec prototype; keeps the same df for the Wald; mirrors the `run_grc_robust_vv` identification; can be implemented by extending [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) with a `fit_auxiliary_ols_robust` variant + a small change to the restriction construction.

Secondary: **Option D (boottest CI)** as a cheap robustness check. Should give qualitatively similar CIs when $\phi$ is strongly identified; divergence is informative.

Avoid: **A** (df explosion) and **C** (rank-deficient weighting).

## 8. Implementation steps if we pursue Option B

1. Extend [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) with `fit_auxiliary_ols_robust` that:
    - Takes `vfirst` as an additional column.
    - Builds the within-(trajectory, $v$) demeaned $z_{s, it}$ columns.
    - Absorbs trajectory$\times$vfirst fixed effects (pyfixest or dummies + partialing out).
    - Returns $(\hat\beta^{\text{w}}, \hat V)$ clustered at $v_{\text{first}}$.

2. Extend `grid_lca_inversion` to accept the robust fit + a `phi_grid` as before. The Wald formula is identical in structure, just using $\hat V$ from the new OLS.

3. Write a Stata wrapper [lca_inversion_ci_robust.ado](file:///C:/git/ckt/RP7/explorations/python-grc/lca_inversion_ci_robust.ado) (analog of the existing `lca_inversion_ci.ado`) that attaches the inverted CI to the saved `run_grc_robust_vv` estimate as `e(inv_ci95_lo)` / `e(inv_ci95_hi)`.

4. Smoke test on TZA (few clusters, cleanest case from the [main comparison](file:///C:/git/ckt/docs/reviews/2026-04-24_simple-vs-verdier-comparison.md)). Compare inverted CI to boottest CI and to analytical Wald CI from `run_grc_robust_vv`.

5. Roll out to CHN / IDN. Expected: Verdier robust CIs wider than simple where $\phi$ is less sharply identified (IDN covs_trend--covs_2 was the fragile case).

## 9. Open questions

- **How to aggregate $\alpha_{s, v}$ to $\bar\alpha_s$** for the LCA restriction? Simple sample-share weighting is natural; alternatives (inverse-variance weights) might have better power.
- **Does the existing `lca_inversion_ci.ado` Stata wrapper's API let us plug in a different auxiliary OLS?** If yes, minimal new code. If no, clone + modify.
- **Should the drop_sparse_switchers threshold change** under the demeaned instruments? Within-cluster variation requires at least 2 treated observations per $(s, v)$ cell for that cell to contribute --- sparser than the simple spec's threshold.

All three are implementable tasks; the design is solid enough to start without first resolving them.
