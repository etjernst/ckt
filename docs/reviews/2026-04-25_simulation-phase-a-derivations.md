# Phase A derivations: regression direction, bias formula, and tilt calibration

**Date:** 2026-04-25
**Context:** Paper-only analytical work prerequisite to coding the MC simulation. Per [plan](file:///C:/Users/maand/.claude/plans/valiant-sleeping-trinket.md) Phase A.

## A.1 Regression direction under VV's GMM

### Setup

LCA at worker level (CKT convention, reiterating [proof memo](file:///C:/git/ckt/docs/reviews/2026-04-25_robust-vv-equivalence-proof.md) eq. 2):
$$\Delta_i \;=\; \beta(v_i) + \phi\,\theta_i + \xi_i, \quad E[\xi_i \mid v_i, \text{instruments}] = 0 \quad (1)$$

Adopt the simplification $\alpha_i = \theta_i$ (pre-treatment productivity equals comparative advantage up to rescaling). Then at the worker level:
$$b_i \;=\; \beta + \phi a_i + \xi_i \quad (2)$$
where $a_i$ is rural productivity and $b_i$ is the treatment effect.

### VV's GMM moment

Per line 7 of VV's [`robust.do`](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do):
```
local epsilon (a-{alpha1}*return)
```
i.e.,
$$\varepsilon_i^{\text{VV}} = a_i - \alpha_0 - \alpha_1 \cdot \text{return}_i = a_i - \alpha_0 - \alpha_1 b_i$$

The GMM moment condition is $E[z_i \cdot \varepsilon_i^{\text{VV}}] = 0$ where $z_i$ is VV's cluster-demeaned period-treatment instrument.

### Solve for $\alpha_1$

$$E[z \cdot (a - \alpha_0 - \alpha_1 b)] = 0$$
$$\Longleftrightarrow E[z \cdot a] \;=\; \alpha_0 E[z] + \alpha_1 E[z \cdot b]$$

Under cluster-demeaning, $E[z] = 0$ asymptotically, so:
$$\alpha_1 \;=\; \frac{E[z \cdot a]}{E[z \cdot b]} \quad (3)$$

### Substitute the LCA to reduce

From (2), $b = \beta + \phi a + \xi$, so:
$$E[z \cdot b] \;=\; \beta E[z] + \phi E[z \cdot a] + E[z \cdot \xi] \;=\; \phi \cdot E[z \cdot a]$$
using $E[z] = 0$ and $E[z \cdot \xi] = 0$ (the instrument exogeneity in A2$'$).

Plug into (3):
$$\boxed{\alpha_1 \;=\; \frac{E[z \cdot a]}{\phi \cdot E[z \cdot a]} \;=\; \frac{1}{\phi}} \quad (4)$$

**So VV's GMM estimator for $\alpha_1$ targets $1/\phi$, NOT $\phi$**, under CKT's LCA convention where $b = \beta + \phi a + \xi$.

### Reverse moment

Suppose instead we used the moment $E[z \cdot (b - \gamma_0 - \gamma_1 a)] = 0$:
$$\gamma_1 \;=\; \frac{E[z \cdot b]}{E[z \cdot a]} \;=\; \frac{\phi \cdot E[z \cdot a]}{E[z \cdot a]} \;=\; \phi \quad (5)$$

So regressing $b$ on $a$ via IV targets $\phi$ directly.

### Overidentified case

When multiple instruments $z_1, \ldots, z_K$ are used (as in VV's full spec with Block 2 containing period-specific residuals), the GMM estimator with any positive-definite weighting matrix solves:
$$\hat\alpha_1 \;=\; \arg\min_{\alpha_1} \; g_n(\alpha_1)' W g_n(\alpha_1)$$
where $g_n(\alpha_1)$ stacks the $K$ moment means. At the population, every component of $g_n$ vanishes at $\alpha_1 = 1/\phi$ (same analysis as the scalar case applied per instrument). So the population target is unchanged. Weighting affects efficiency, not consistency.

### Correction to the proof memo

The proof memo [`2026-04-25_robust-vv-equivalence-proof.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_robust-vv-equivalence-proof.md) §3.1 states "$\hat\alpha_1^{\text{vv}} \xrightarrow{p} \phi$". **This is wrong** under VV's published moment. The correct statement is $\hat\alpha_1^{\text{vv}} \xrightarrow{p} 1/\phi$. To compare to CKT's $\phi$, one must report $1/\hat\alpha_1^{\text{vv}}$, OR run VV with the reverse moment $(b - \gamma_0 - \gamma_1 a)$ which directly targets $\phi$.

The consistency claim of the proof memo still holds: both estimators are consistent for a population parameter that maps one-to-one to $\phi$. But the scalars they directly report differ by reciprocal.

### Re-interpretation of the real-data diagnostic

The [main comparison](file:///C:/git/ckt/docs/reviews/2026-04-24_simple-vs-verdier-comparison.md) and the [VV worker-level diagnostic](file:///C:/git/ckt/docs/reviews/2026-04-24_vv-worker-level-diagnostic-results.md) reported VV's $\hat\alpha_1$ at face value alongside CKT's $\hat\phi^{\text{robust\_vv}}$. Correct interpretation:

| Country | CKT $\hat\phi^{\text{robust\_vv}}$ | VV $\hat\alpha_1$ (raw) | **Implied $\phi^{\text{VV}} = 1/\hat\alpha_1^{\text{VV}}$** |
|---|---:|---:|---:|
| TZA | $-0.690$ | $-0.634$ | $-1.577$ |
| CHN | $-0.155$ | $-0.598$ | $-1.672$ |
| IDN | $-0.334$ | $-1.691$ | $-0.591$ |

**The "TZA agreement" we celebrated was spurious.** VV's raw $\alpha_1 = -0.634$ is close to CKT's $\hat\phi = -0.69$ only because, at $|\alpha_1| \approx |\phi| \approx 0.7$, $\alpha_1$ and $1/\alpha_1$ happen to be numerically similar in magnitude (both around $\pm 0.7$ to $\pm 1.5$). This is a numerical coincidence at the boundary of the $|\phi| \approx 1$ regime.

Under the corrected reading:
- **TZA**: $\phi^{\text{CKT}} = -0.69$ vs $\phi^{\text{VV}} = -1.58$. Meaningful divergence.
- **CHN**: $\phi^{\text{CKT}} = -0.16$ vs $\phi^{\text{VV}} = -1.67$. Dramatic divergence.
- **IDN**: $\phi^{\text{CKT}} = -0.33$ vs $\phi^{\text{VV}} = -0.59$. Moderate divergence.

The TV-diagnostic ranking (IDN highest tilt) maps onto which estimate is MOST trusted: IDN is where the two are closest (VV inversion ~$-0.59$, CKT $-0.33$). For TZA and CHN, VV says $\phi$ is around $-1.6$ while CKT says $-0.7$ or $-0.16$ --- much larger alpha-pooling bias than we first thought.

**This is a significant finding** that changes the interpretation of the earlier diagnostic. The rest of Phase A should proceed with the understanding that the simulation will report both $\hat\alpha_1$ and its reciprocal $1/\hat\alpha_1$ to avoid confusion.

## A.2 Alpha-pooling bias formula for two R2 regimes

Per user's 2026-04-25 call, the simulation runs TWO R2 variants isolating the two failure modes:

- **R2a (Mode B, differential cluster assignment):** $P(v_i = v \mid d_i = s) = \frac{1}{V}(1 + \lambda g(s) h(v))$. A3 holds; worker types are the same across clusters within a trajectory, but trajectories concentrate in different clusters. Isolates the alpha-pooling bias.
- **R2b (Mode A, $\theta$-tilt):** $\theta_i \mid (d_i = s, v_i = v) \sim N(m_s + \lambda g(s) h(v), \sigma_\theta^2)$. A3 fails. Biases both estimators.

For both, $g(s) = (s - 8.5)/7.5$ for $s \in \{1, \ldots, 16\}$, $h(v) = (v - 13)/12$ for $v \in \{1, \ldots, 25\}$. Both centered on zero, range $\pm 1$.

Deterministically tie $\beta(v)$ to the same $h(v)$ shape that drives the tilt: $\beta(v) = \sigma_\beta \cdot h(v)$. Without this coupling the bias vanishes in expectation.

### R2a bias (Mode B, analytical)

From the [alpha-pooling derivation](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md) §3, the CKT trajectory-pooled estimator's bias is:
$$\hat\phi^{\text{robust\_vv}} - \phi \;=\; -\frac{\mathrm{Cov}_s(\bar\beta(s),\, m_s - m_{d_0})}{\mathrm{Var}_s(m_s - m_{d_0})} + o_p(1)$$

where $\bar\beta(s) = \sum_v \tilde w(s, v)\, \beta(v)$ and $\tilde w(s, v) = w(s, v) / \sum_{v'} w(s, v')$ with $w(s, v) = n_{s,v} \cdot \mathrm{Var}(D \mid s, v)$.

**Under R2a:**
- $n_{s,v} = N_s \cdot P(v \mid s) = N_s \cdot \frac{1}{V}(1 + \lambda g(s) h(v))$.
- $\mathrm{Var}(D \mid s, v) = V_s$ (depends only on trajectory, since $D$ is deterministic given $d$ and $t$).
- $w(s, v) = N_s V_s / V \cdot (1 + \lambda g(s) h(v))$.
- $\sum_v w(s, v) = N_s V_s$ (since $\sum_v h(v) = 0$).
- $\tilde w(s, v) = \frac{1}{V}(1 + \lambda g(s) h(v))$.

Plug in $\beta(v) = \sigma_\beta h(v)$:
$$\bar\beta(s) \;=\; \frac{\sigma_\beta}{V}\sum_v h(v)(1 + \lambda g(s) h(v)) \;=\; \sigma_\beta \lambda g(s) \cdot \tfrac{1}{V}\sum_v h(v)^2 \;=\; \sigma_\beta \lambda \sigma_h^2\, g(s)$$

since $\sum_v h(v) = 0$ by centering. So $\bar\beta(s)$ is linear in $g(s)$ with slope $\sigma_\beta \lambda \sigma_h^2$.

Now the bias:
$$\hat\phi^{\text{robust\_vv}} - \phi \;=\; -\sigma_\beta \lambda \sigma_h^2 \cdot \frac{\mathrm{Cov}_s(g(s),\, m_s)}{\mathrm{Var}_s(m_s)}$$

With the DGP's $m_s = m_1 (s - 8.5)$ and $g(s) = (s - 8.5)/7.5$, we have $\mathrm{Cov}_s(g, m) / \mathrm{Var}_s(m) = 1/(7.5 m_1)$, so:
$$\boxed{\hat\phi^{\text{robust\_vv}} - \phi \;\approx\; -\frac{\sigma_\beta \lambda \sigma_h^2}{7.5\, m_1}}$$

For the DGP parameters below ($\sigma_\beta = 0.4$, $\sigma_h^2 \approx 1/3$, $m_1 = 0.1$), this gives bias $\approx -\lambda \cdot 0.18$. So $\lambda = 1.78$ produces bias $\approx -0.32$, matching IDN's empirical $|VV^{-1} - \text{CKT}| \approx 0.26$ order of magnitude.

### R2b bias (Mode A, qualitative)

Under R2b, the tilt enters the worker's type distribution directly. $E[\alpha \mid s, v] = c_0 + c_1(m_s + \lambda g(s) h(v))$ varies with $v$ even at the population. Both estimators get biased; the bias depends on the full covariance structure of $(\alpha, \Delta, D)$ at the worker level and does not reduce to a clean Cov-over-Var ratio.

**Qualitative prediction:** in R2b the worker-level estimator also picks up bias (because the LCA is not uniform across clusters), and the two estimators' biases should be correlated in sign. The simulation will measure this numerically. No closed-form formula; we rely on the MC.

### Summary

| Regime | A3 | Which estimator biased | Closed-form bias |
|---|---|---|---|
| R1 | holds | neither | 0 |
| R2a (Mode B) | holds | trajectory-pooled only | $-\sigma_\beta \lambda \sigma_h^2 / (7.5 m_1)$ |
| R2b (Mode A) | fails | both | no clean form |

## A.3 Calibration of $\lambda_{\text{tilt}}$

### R2a calibration

Mean TV distance between switcher weight profiles:
$$\overline{\mathrm{TV}} \;=\; E_{s_1, s_2}\left[\tfrac{1}{2} \sum_v \left|\tilde w(s_1, v) - \tilde w(s_2, v)\right|\right] \;=\; \frac{\lambda}{2V} E_{s_1, s_2}\left[|g(s_1) - g(s_2)|\right] \sum_v |h(v)|$$

With $h(v) = (v - 13)/12$ uniform on $[-1, 1]$: $\frac{1}{V}\sum_v |h(v)| \approx \frac{1}{2}$. With $g(s) = (s - 8.5)/7.5$ restricted to switchers $s \in \{2, \ldots, 15\}$: $E[|g(s_1) - g(s_2)|] \approx 0.58$. So:
$$\overline{\mathrm{TV}}^{\text{R2a}} \;\approx\; 0.5 \cdot 0.58 \cdot \lambda / 2 \;=\; 0.145 \lambda$$

To match IDN's empirical $\overline{\mathrm{TV}} = 0.258$:
$$\lambda^{\text{R2a}} \;=\; 0.258 / 0.145 \;\approx\; 1.78$$

Double-check: $\lambda^{\text{R2a}} = 1.78$ must keep $P(v \mid s) > 0$ for all $(s, v)$. Minimum $P(v \mid s) = \frac{1}{V}(1 - \lambda |g(s)| \cdot |h(v)|_{\max}) = \frac{1}{25}(1 - 1.78 \cdot 0.867 \cdot 1) = \frac{1}{25}(1 - 1.54) < 0$. NEGATIVE, not a valid probability.

**Constraint:** $\lambda \cdot \max_s |g(s)| \cdot \max_v |h(v)| < 1$, i.e., $\lambda < 1 / 0.867 \approx 1.15$.

**Fix:** reduce the calibration target. Set $\lambda^{\text{R2a}} = 1.0$ (safely under the constraint) and note that the implied mean TV is $0.145 \cdot 1.0 = 0.145$, below IDN's 0.258 but of the same order. Alternatively, rescale $g$ or $h$ to smaller range.

Let me use $\lambda^{\text{R2a}} = 1.0$. Implied bias: $-0.18$ at $m_1 = 0.1$.

### R2b calibration

Under R2b, the TV distance between switcher weight profiles stays at zero because $\tilde w(s, v) = 1/V$ is uniform (cluster assignment is uniform; the tilt affects $\theta$ values, not sample shares). So R2b doesn't connect to the TV diagnostic meaningfully.

**For R2b, pick $\lambda^{\text{R2b}} = 1.0$** as a comparable magnitude and observe the resulting bias numerically. No analytical calibration target.

### Combined recommendation

- $\lambda^{\text{R2a}} = 1.0$, implies mean TV $\approx 0.145$, CKT bias $\approx -0.18$, VV unbiased.
- $\lambda^{\text{R2b}} = 1.0$, implies mean TV $= 0$ (tilt doesn't affect weights), both estimators biased.
- Sanity check: if R2a and R2b both show expected bias patterns, we have evidence for both failure modes.
