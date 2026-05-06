# VV's worker-level approach vs CKT's trajectory-pooled approach

**Date:** 2026-04-24
**Context:** Follow-up to [alpha-pooling derivation](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md). The user noted that Verdier's original paper estimates the robust LCA slope "within person," not via trajectory pooling. This memo compares the two approaches and clarifies why the alpha-pooling concern arises for CKT but not for VV.

## 1. VV's approach (Table 1 / robust.do)

VV's setup has households that switch in and out of hybrid-seed use across panel periods. He estimates the LCA slope $\alpha_1$ (= our $\phi$) in three steps:

### Step 1: Chamberlain (1992) within-household projection

At the worker/household level, partial out household $\times$ treatment-status fixed effects:
```stata
areg lyield w1-wN, absorb(hhid_hybrid)
predict yresid, dresiduals
```
where `hhid_hybrid = hhid * 10 + hybrid`. This creates $|$hhid$| \cdot 2$ fixed effects (one per household per treatment status).

After this projection:
- `a_i` = within-household mean of `lyield` when `hybrid = 0` (pre-treatment).
- `apb_i` = within-household mean when `hybrid = 1` (post-treatment).
- `return_i = apb_i - a_i` = worker-level treatment effect $\Delta_i$ (for switchers only; stayers have missing `return_i`).

Key point: `a_i` and `return_i` are WORKER-LEVEL quantities. One per household. Aggregation happens within household, not across households.

### Step 2: Optimal instruments via village demeaning

For each period `per`, regress `hybrid_per` on village dummies `i.vil` among switchers:
```stata
reg hybrid`per' i.vil if switcher
predict hybrid`per'd if switcher, resid
```

These village-demeaned period-treatment indicators `hybrid_per_d` are the cluster-demeaned optimal instruments.

### Step 3: Joint GMM estimating $\alpha_1$

The LCA moment condition at the worker level:
$$E\Big[\text{hybrid\_per\_d}_i \cdot (a_i - \alpha_1 \cdot \text{return}_i)\Big] = 0$$

Note that `a_i` and `return_i` are already WORKER-LEVEL. No trajectory aggregation. Each worker contributes their own `a_i`, `return_i` pair to the moment.

The joint GMM estimates $\alpha_1$ + first-stage gammas + various ATE parameters (for stayers extrapolation) simultaneously, with `vce(cluster vil), winitial(unadjusted, independent), onestep`.

## 2. CKT's approach (run_grc / run_grc_robust_vv)

CKT's setup has workers moving between rural and urban, with multiple switching patterns (trajectories).

Instead of working at the worker level, CKT POOLS to the trajectory level. Each worker's type is summarized by their trajectory $d_i$, and the model has one $\mu_d$ parameter per trajectory.

### The CKT moment equation (simple)
$$y_{it} = \mu_{d_i} + \Delta_{d_0} D_{it} + \phi \sum_{s \in S \setminus \{d_0\}} (\mu_s - \mu_{d_0}) \mathbb{1}\{d_i = s\} D_{it} + (\text{always-urban term}) + x' \gamma + \varepsilon_{it}$$

### Trajectory pooling assumption
$$E[y^R_i \mid d_i = d, v_i = v] = \mu_d \quad \text{(does not depend on } v\text{)}$$
$$E[\theta_i \mid d_i = s, v_i = v] = \mu_s - \mu_{d_0}$$

Under this assumption, all the worker-level variation within a trajectory is collapsed to a scalar $\mu_d$. There is no per-worker `a_i`, `return_i` in CKT's parameterization --- instead, the trajectory mean $\mu_d$ plays both roles (proxy for $a_i$ and anchor for the LCA extrapolation).

### Verdier robust variant

`run_grc_robust_vv` replaces the raw instruments with cluster-demeaned ones:
```stata
reg switcher_s_choice i.vfirst if switcher_s == 1
predict swd_switcher_s_choice, resid
```
Then the GMM uses `swd_switcher_s_choice` instead of `switcher_s_choice`. Same trajectory-pooled parameter set; only instruments change.

## 3. Where the alpha-pooling concern comes from

The critical difference: **VV's moment is defined at the worker level; CKT's moment is defined at the trajectory level.**

In VV's moment:
$$E[\text{hybrid\_per\_d}_i \cdot (a_i - \alpha_1 \cdot \text{return}_i)] = 0$$
The LCA is imposed worker-by-worker: $\Delta_i = \alpha_0 + \alpha_1 \cdot \theta_i + \varepsilon_i$ with $E[\varepsilon_i \mid v_i] = 0$. Under this, the moment holds because the cluster-demeaning of the instrument purges $\alpha_0 + \text{constant}$ per cluster, leaving only within-cluster variation in $\theta_i$ to identify $\alpha_1$.

In CKT's moment:
$$E[\text{swd}_{s, it} \cdot \varepsilon_{\text{CKT}, it}] = 0$$
The LCA is imposed TRAJECTORY-BY-TRAJECTORY: $\Delta_s = \beta + \phi \cdot (\mu_s - \mu_{d_0})$ (and robustly, $\Delta_{s,v} = \beta(v) + \phi \cdot (\mu_s - \mu_{d_0})$). The moment has to hold at the trajectory-aggregated level, and the aggregation weighting happens INSIDE the moment expectation.

**This is where the alpha-pooling concern enters.** The derivation in [2026-04-24_alpha-pooling-derivation.md](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md) §3 showed that the moment takes the form:
$$\sum_v P(d=s, v) \cdot \text{Var}(D \mid s, v) \cdot [\beta(v) - \Delta_{d_0, \text{fit}} + (\phi_{\text{true}} - \phi_{\text{fit}})(\mu_s - \mu_{d_0})] = 0$$

When the weights $P(d=s, v) \cdot \text{Var}(D \mid s, v)$ vary systematically across $s$, the moment embeds a weighted average of $\beta(v)$ that's $s$-specific, and that creates the bias.

**VV's approach avoids this by never aggregating across workers within a trajectory.** Each worker $i$ contributes one moment-contribution, and the weighting across clusters happens AFTER the worker-level projection --- so cluster weights are uniform across the trajectory-axis. In VV there IS no trajectory axis.

## 4. Could we adapt CKT to VV's structure?

**Yes in principle, no in practice (for now).** Porting VV's worker-level Chamberlain projection to CKT would require:

1. Define hybrid_per-analog for CKT: worker-specific treatment indicator per trajectory phase. But CKT's trajectories encode MULTI-SWITCH patterns (e.g., RURU) that don't map to a single pre/post split. VV's setup has at most one switch per household; CKT allows multiple.
2. Worker-level LCA regression: $a_i = \alpha_0 + \alpha_1 \cdot \text{return}_i + \varepsilon_i$. Requires $\text{return}_i$ estimable per worker, which requires at least one treated and one untreated observation per worker. In CKT's unbalanced panels many switchers have only one period of each status, so $\text{return}_i$ is a single noisy difference.
3. Reformulate the extrapolation aggregators ($\Delta_{d_N}$, $\Delta_{d_T}$) in terms of worker-level quantities rather than trajectory means.

This is a significant rewrite of the CKT estimator. Worth scoping but not something to undertake without a clear empirical signal that trajectory pooling is a problem.

## 5. Empirical diagnostic

The current comparison's empirical diagnostic (x_alpha_pooling_diagnostic.do) computes the per-$(s,v)$ weight $w(s, v) = n_{s,v} \cdot \text{Var}(D \mid s, v)$ on the three datasets and reports TV distances between switcher weight profiles. If TV distances are small across all countries and cov specs, the trajectory-pooled approach is empirically safe and no rewrite is needed.

If TV distances are large, we need to either:
(a) Accept that Verdier robust point estimates absorb some between-cluster selection and report with a caveat.
(b) Port VV's worker-level approach (§4 above).
(c) Use an alternative CI procedure (Stock-Wright S or Kleibergen K with onestep $W = I$) that doesn't lean on the trajectory-pooling assumption the same way.

## 6. What VV assumes that CKT should check

VV's original paper (Assumption 10) requires i.i.d. errors within a village. This implies the cluster distribution of worker types doesn't matter --- within-village variation alone identifies $\alpha_1$.

CKT's trajectory-pooling assumption is STRONGER in one direction (requires $E[\theta_i \mid d_i = s]$ to not depend on $v$) and WEAKER in another (allows multi-period treatment patterns VV's single-switch setup doesn't).

In the Verdier robust adaptation for CKT, both assumptions need to hold:
- Trajectory pooling: $E[\theta_i \mid d_i = s, v_i = v] = E[\theta_i \mid d_i = s]$ for all $v$.
- Cluster-distribution invariance across switchers: the distribution of `vfirst` given trajectory $s$ has similar support and shape for different $s$.

If either fails, the Verdier estimator of $\phi$ in CKT can be biased in a way that VV's original estimator would not be.
