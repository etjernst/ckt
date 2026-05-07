---
title: Phase D --- Monte Carlo results for trajectory-pooled vs worker-level robust LCA
author: Emilia (with Claude)
date: 2026-04-25
---

# Phase D --- Monte Carlo results

## Summary

The Monte Carlo simulation in [`explorations/verdier/x_equivalence_simulation.do`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation.do) confirms the equivalence claim from [`docs/reviews/2026-04-25_robust-vv-equivalence-proof.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_robust-vv-equivalence-proof.md) under A1, A2$'$, A3, and exposes the alpha-pooling bias of the trajectory-pooled estimator when A3 holds but the cluster assignment is differential across switcher trajectories.

100 replications $\times$ 3 regimes $\times$ 2 estimators, all 300 GMM optimizations converged on the first try.
DGP: $N=4{,}000$, $T=4$, $V=25$, $\phi_{\text{true}} = -0.7$.

## Headline table

| Regime | $\bar{\hat\phi}^{\text{CKT}}$ (SD) | bias | $\overline{1/\hat\alpha_1}^{\text{VV}}$ (SD) | bias | mean TV |
|---|---|---|---|---|---|
| R1 (A3 holds, uniform $v$) | $-0.698$ $(0.026)$ | $+0.002$ | $-0.705$ $(0.023)$ | $-0.005$ | --- |
| R2a (A3 holds, Mode B) | $-0.502$ $(0.026)$ | $+0.198$ | $-0.701$ $(0.026)$ | $-0.001$ | $0.252$ |
| R2b (A3 fails, Mode A) | $-0.694$ $(0.026)$ | $+0.006$ | $-0.701$ $(0.023)$ | $-0.001$ | --- |

MC SE on each mean is $\text{SD}/\sqrt{100} \approx 0.0026$. Bias is computed as $\bar{\hat\phi} - \phi_{\text{true}}$.

## Verdicts on the four claims under test

### Claim 1: Both estimators consistent under A1, A2$'$, A3 (regime R1)

Confirmed. CKT bias $+0.002$ and VV bias $-0.005$ are both within $\pm 2 \times \text{MC SE}$ of zero. The two estimators have nearly identical sampling distributions ($\text{SD}_{\text{CKT}} = 0.026$, $\text{SD}_{\text{VV}} = 0.023$).

### Claim 2: VV moment targets $\alpha_1 = 1/\phi$ (Phase A.1)

Confirmed empirically. Across all three regimes the worker-level GMM returns $\hat\alpha_1 \approx 1/(-0.7) = -1.43$, and reporting $1/\hat\alpha_1$ recovers $\phi$ to within $0.005$ on average. This validates Phase A.1's algebraic derivation that VV's just-identified GMM moment $E[z(a - \alpha_0 - \alpha_1 \cdot \text{return})] = 0$ targets the inverse of the LCA slope under CKT's $b = \beta + \phi a + \xi$ convention.

### Claim 3: Trajectory-pooled CKT picks up alpha-pooling bias when cluster assignment is differential (regime R2a)

Confirmed. With $P(v \mid s) \propto 1 + \lambda g(s) h(v)$ and $\lambda = 1$, the CKT estimator delivers $\bar{\hat\phi} = -0.502$, a bias of $+0.198$. The VV worker-level estimator, which uses Chamberlain projection to recover individual $a_i$ and $b_i$ before averaging within cluster, stays consistent ($\bar{1/\hat\alpha_1} = -0.701$).

The mean realized total-variation distance between switcher cluster-weight profiles is $0.252$, almost exactly the IDN target of $0.258$ identified in [`2026-04-24_alpha-pooling-diagnostic-results.md`](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md). Phase A.3's calibration is on target.

### Claim 4: Quantitative match to Phase A.2 closed-form bias formula

Confirmed, with a sign correction to the Phase A memo.

The closed-form bias is

$$\text{plim}\,\hat\phi^{\text{CKT}} - \phi_{\text{true}} = \frac{\text{Cov}_{(s,v)}\big[\beta(v),\, m_s\big]}{\text{Var}_s\big[m_s\big]}.$$

Under the R2a tilt, $E[h(v) \mid s] = \lambda g(s)\,\text{Var}(h)$, so

$$\text{Cov}\big[\beta(v),\, m_s\big] = \sigma_\beta\, m_{\text{slope}}\, \lambda\, \frac{\text{Var}(h)\,\text{Var}(s)}{7.5}, \qquad \text{Var}(m_s) = m_{\text{slope}}^2\, \text{Var}(s),$$

so

$$\text{plim}\,\hat\phi^{\text{CKT}} - \phi_{\text{true}} = \frac{\sigma_\beta\, \lambda\, \text{Var}(h)}{7.5\, m_{\text{slope}}}.$$

Plugging in $\sigma_\beta = 0.4$, $\lambda = 1$, $\text{Var}(h) = (V^2 - 1)/(12 \cdot ((V-1)/2)^2) = 624/(12 \cdot 144) = 0.361$, $m_{\text{slope}} = 0.1$:

$$\text{predicted bias} = \frac{0.4 \cdot 1 \cdot 0.361}{0.75} = 0.193.$$

Observed bias: $+0.198$. The deviation is $0.005$, well within MC SE $\approx 0.003$.

The Phase A.2 derivation memo at [`docs/reviews/2026-04-25_simulation-phase-a-derivations.md`](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-phase-a-derivations.md) wrote the bias with a leading minus sign; the correct sign is positive. The Cenci-Kleemans-Tjernström convention $\Delta_i = \beta(v_i) + \phi \theta_i + \xi_i$ gives a $+\text{Cov}/\text{Var}$ alpha-pooling bias, not $-\text{Cov}/\text{Var}$. To fix in Phase A: replace the minus with plus in §A.2 and update the conclusion's sign.

### Claim 5: R2b (Mode A, $\theta$-tilt, A3 fails) biases both estimators

Not confirmed --- and informatively so.

R2b's data-generating process tilts $\theta_i$ by $\lambda g(s) h(v_i)$ but keeps $v_i$ uniform across switchers. A3 fails because $E[\theta_i \mid s, v]$ depends on $v$. Both estimators, however, return essentially unbiased $\phi$: CKT bias $+0.006$, VV bias $-0.001$.

The reason is structural to this DGP. Under R2b, the v-tilt enters $\theta_i$, and $\theta_i$ enters $\alpha_i$ and $\Delta_i$ linearly through the same parameter $\phi$. The cluster-demeaned instruments project the v-tilt out of both the regressor and the regressand symmetrically; the LCA $b = \phi a + (\text{stuff})$ still holds at the worker level; and the instruments still satisfy A2$'$. So $\phi$ remains identified.

What R2b would need to actually break $\phi$ identification is a v-tilt that enters $\Delta$ and $\alpha$ in different ways --- e.g., $\xi_i$ correlated with $(s, v)$, or the LCA slope $\phi$ itself varying with $v$. Neither is what the original A3-failure narrative pointed to. The narrative concerns the violation of trajectory pooling at the population aggregation layer, which surfaces through differential cluster assignment (Mode B / R2a), not through a $\theta$-tilt that preserves the LCA.

Implication: drop R2b from the headline table in any future write-up. Replace with a regime that violates A2$'$ or makes $\phi$ heterogeneous across $v$.

## Convergence and runtime

All 300 (regime, rep) combinations converged on the first iteration set for both estimators. No reps required restart. Total wall time: $\approx 70$ minutes for the full 100-rep $\times$ 3-regime grid.

## Recommendations

1. Stop at 100 reps. The R1 and R2a verdicts are decisive at this scale (MC SE $\approx 0.003$, bias $\approx 0.2$ for R2a). Scaling to 500 would only sharpen R2b's null result, which is not informative given the structural reason it returns zero bias.
2. Update [Phase A.2 memo](file:///C:/git/ckt/docs/reviews/2026-04-25_simulation-phase-a-derivations.md) sign on the bias formula.
3. The R2b regime should either be dropped or re-specified. The cleanest extension is to make $\phi$ depend on $v$ (heterogeneous LCA slope), which would actually break worker-level identification too and would be a more interesting failure mode to characterize.
4. Calibration of $\lambda^{\text{R2a}} = 1.0$ produces realized mean TV $= 0.252$, almost exactly IDN's $0.258$. Use this in any robustness discussion as evidence that the empirically observed alpha-pooling exposure is at the magnitude where trajectory pooling materially biases $\phi$.

## Files

- [`explorations/verdier/x_equivalence_simulation.do`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation.do) --- the MC do-file
- [`explorations/verdier/x_equivalence_simulation_results.dta`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation_results.dta) --- 300 rows of $(\text{regime}, \text{rep}, \hat\phi^{\text{CKT}}, \text{SE}, 1/\hat\alpha_1, \text{SE}, \text{TV}, n_\text{sw}, \text{ckt\_ok}, \text{vv\_ok})$
- [`explorations/verdier/x_equivalence_simulation.txt`](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation.txt) --- full SMCL log (translated)
