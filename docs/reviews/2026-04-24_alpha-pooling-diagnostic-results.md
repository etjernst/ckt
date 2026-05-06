# Alpha-pooling diagnostic: empirical results

**Date:** 2026-04-24
**Context:** The [alpha-pooling derivation](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md) showed that the Verdier robust estimator of $\phi$ in CKT is biased whenever the cluster-share-and-variance weight $w(s, v) = n_{s,v} \cdot \text{Var}(D \mid s, v)$ differs substantially across switcher trajectories $s$ AND the cluster-specific LCA intercept $\beta(v)$ correlates with the $s$-tilted aggregation. This memo reports the empirical weight tilt on the three datasets.

**Driver:** [x_alpha_pooling_diagnostic.do](file:///C:/git/ckt/explorations/verdier/x_alpha_pooling_diagnostic.do)
**Output files:**
- [x_alpha_pooling_diagnostic_weights.dta](file:///C:/git/ckt/explorations/verdier/x_alpha_pooling_diagnostic_weights.dta) --- one row per (country, switcher, vfirst) with $n_{s,v}$, $\text{Var}(D \mid s, v)$, raw weight, normalized weight.
- [x_alpha_pooling_diagnostic_tv.dta](file:///C:/git/ckt/explorations/verdier/x_alpha_pooling_diagnostic_tv.dta) --- pairwise TV distances.

## 1. Headline numbers

### Total variation distance between switcher weight profiles

Computed as $\text{TV}(w_s, w_{s'}) = \tfrac{1}{2} \sum_v \|\tilde w_{s,v} - \tilde w_{s',v}\|$ where $\tilde w_{s,v} = w(s,v) / \sum_{v'} w(s, v')$.

TV = 0: switchers $s$ and $s'$ have identical cluster weight distributions. TV = 1: disjoint support.

| Country | mean TV (over all switcher pairs) | max TV | min TV |
|---------|------:|------:|------:|
| **IDN** | **0.258** | 0.539 | 0.000 |
| CHN | 0.038 | 0.504 | 0.000 |
| TZA | 0.014 | 0.601 | 0.000 |

### Per-cluster weight disagreement across switchers

For each cluster $v$, compute $\max_s \tilde w_{s,v} - \min_s \tilde w_{s,v}$ (the range of switchers' weights in that cluster). Then summarize across clusters.

| Country | mean(range) across $v$ | max(range) |
|---------|------:|------:|
| IDN | 0.331 | 0.978 |
| CHN | 0.211 | 0.993 |
| TZA | 0.141 | 0.981 |

The max(range) near 1.0 for all three is driven by sparse switcher trajectories that happen to concentrate in one cluster; this is the tail of the distribution and less informative. The mean(range) is a better summary: IDN shows the largest weight disagreement at the typical cluster.

## 2. Interpretation

**IDN has the most severe weight tilt**, by both mean TV (0.26) and mean per-cluster weight range (0.33). CHN and TZA are much cleaner on the mean TV metric (0.04, 0.01) though all three show extreme values in specific switcher pairs.

**Why this matters:** under the derivation, the bias in $\hat\phi$ is

$$\hat\phi - \phi = -\frac{\text{Cov}_s(\bar\beta(s),\, \mu_s - \mu_{d_0})}{\text{Var}_s(\mu_s - \mu_{d_0})}$$

where $\bar\beta(s) = \sum_v \tilde w_{s,v}\,\beta(v)$ is the $s$-tilted average of cluster-specific LCA intercepts. Large TV distances imply potential for large $\bar\beta(s)$ variation across $s$; whether that variation covaries with $(\mu_s - \mu_{d_0})$ is the remaining unknown that we can't check without observing $\beta(v)$ directly.

## 3. Strong circumstantial evidence

The mean TV ranking (**IDN > CHN > TZA**) matches EXACTLY the ranking of estimator shifts from simple to Verdier at covs_all in the [main comparison](file:///C:/git/ckt/docs/reviews/2026-04-24_simple-vs-verdier-comparison.md):

| Country | simple $\hat\phi$ | Verdier $\hat\phi$ | shift (absolute) | relative shift | mean TV |
|---------|-----:|-----:|-----:|-----:|-----:|
| IDN | $-0.526$ | $-0.334$ | $0.192$ | $37\%$ | $0.258$ |
| CHN | $-0.205$ | $-0.155$ | $0.050$ | $24\%$ | $0.038$ |
| TZA | $-0.719$ | $-0.690$ | $0.029$ | $4\%$ | $0.014$ |

The two series move together. This is consistent with two interpretations:

**(A) The Verdier estimator is correctly absorbing between-cluster variation that biased the simple estimator.** Under this reading, the shift size equals the between-cluster contamination that Verdier successfully purges. In that case the simple estimator is biased and Verdier is right; the alpha-pooling bias discussed in the derivation is zero because both $\bar\beta(s) - \bar\beta$ and $(\mu_s - \mu_{d_0})$ move together consistently with within-cluster LCA holding.

**(B) The Verdier estimator is absorbing the between-cluster variation AND re-importing a second-order alpha-pooling tilt.** Under this reading, the simple $\hat\phi$ was biased in one direction (too negative because between-cluster sorting made $\phi$ look bigger than within-cluster truth), Verdier corrects most of that, and a residual bias of opposite sign remains from the $s$-dependent moment weighting.

The empirical pattern alone cannot distinguish (A) from (B). IDN's large shift + large TV could be EITHER (a large genuine correction with no alpha-pooling bias) OR (a genuine correction plus a partial pooling bias that dragged $\hat\phi$ back toward zero).

## 4. What would settle the question

Three directions:

### 4.1 Decomposition check

Construct a "saturated" estimator that allows $\beta_{s, v}$ per trajectory-$\times$-cluster cell (Option A from the [design memo](file:///C:/git/ckt/docs/reviews/2026-04-24_lca-inversion-ci-verdier-design.md)) with aggressive sparsity filtering. Compare the $\phi$ estimate from this saturated-beta version to `run_grc_robust_vv`. If they agree, alpha-pooling bias is small. If they differ, the pooled version has a tilt.

Costly: $O(\|S\| \cdot \|V\|)$ parameters, needs cell-level sparsity filtering. Feasible on TZA (small). Maybe not feasible on IDN and CHN without serious trajectory pre-selection.

### 4.2 VV-style worker-level projection

Port VV's [Table 1 robust.do](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do) approach verbatim: Chamberlain within-household projection for $a_i$ and $\text{return}_i$, village-demeaned instruments, GMM on the LCA moment at the worker level. Compare $\phi$ from the ported VV estimator to `run_grc_robust_vv`. See [vv-vs-ckt-approach memo](file:///C:/git/ckt/docs/reviews/2026-04-24_vv-vs-ckt-approach.md) for the mechanics.

More invasive but more faithful. CKT's multi-switch trajectories complicate the worker-level projection somewhat (VV has at most one switch per household; CKT allows RURU patterns). Could be restricted to single-switch trajectories as a first cut.

### 4.3 Sensitivity bound

Assume $\beta(v)$ has a maximum spread of $B = \max_v \beta(v) - \min_v \beta(v)$. Then the maximum bias in $\hat\phi$ is bounded by something like
$$\|\hat\phi - \phi\| \leq \frac{B \cdot \sqrt{\text{Var}_s(\text{TV}_s)}}{\sqrt{\text{Var}_s(\mu_s - \mu_{d_0})}}$$
(this needs tightening but the idea is a Cauchy-Schwarz bound). If we can argue $B$ is small from external evidence (e.g. province-level migration cost estimates from Bryan-Morten-style papers), the bias is bounded even without observing $\beta(v)$ directly.

Cheapest route but conclusions are only as good as the $B$ assumption.

## 5. Recommendation

**Primary:** run option 4.2 (VV-style worker-level projection). It's the most defensible way to get a biasless estimate for comparison. If the worker-level estimate agrees with `run_grc_robust_vv` across all three countries, the alpha-pooling concern is empirically resolved and `run_grc_robust_vv` stays as the primary estimator. If it disagrees notably, we adopt the worker-level estimator as primary and relegate `run_grc_robust_vv` to a sensitivity column.

**Secondary:** run option 4.3 with defensible $B$ bounds for a quick sanity check that doesn't require new estimation infrastructure.

**Defer:** option 4.1. The saturated-beta estimator is heavy machinery and would mostly restate the VV worker-level approach in a less natural parameterization.

## 6. Implication for the Option B CI design

Since the alpha-pooling concern is primarily about the estimator, not an extra issue introduced by Option B, the CI design memo's recommendation stands modulo the resolution of §4 above. If we adopt a VV worker-level primary estimator, the CI for $\phi$ should invert THAT estimator's moment conditions, not the trajectory-pooled ones. That's a different project from the simple-spec prototype extension.

## 7. Scope caveat

The diagnostic measures weight TILT across switchers, not bias magnitude directly. Large TV indicates the POSSIBILITY of bias; small TV indicates bias is small regardless of $\beta(v)$ pattern. The derivation multiplies the tilt by $\beta(v)$ variation --- so even IDN's 0.26 mean TV could produce negligible bias if $\beta(v)$ happens to be nearly constant across Indonesian provinces.

Empirically we have strong reason to think $\beta(v)$ is NOT constant (migration costs, local amenities, labor market differences vary across provinces), so the TV metric is informative as an upper-bound diagnostic.
