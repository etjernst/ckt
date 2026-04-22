# LCA-overid moment conditions: 5-agent transcription consensus

**Date:** 2026-04-23
**Source:** Verdier (2020) Online Appendix, Section E.3.2 (pp. 33--35)
**Method:** Five independent subagents transcribed the augmented moment conditions verbatim from `tmp/VV-appendix.txt` (4 of 5 also cross-checked against the PDF in `papers/inbox/VV-appendix.pdf`). No disagreement among the five on any equation, parameter count, or degrees of freedom.

This memo is the canonical reference for the `run_grc_overid` Stata program. Sign-off required before code is written.

---

## 1. The implication being tested

VV's extrapolation identifying assumption (E.2):
$$a_i = \alpha_0 + \alpha_1 b_i + \epsilon_i, \qquad E(\epsilon_i \mid X_i) = 0.$$

This implies (E.10):
$$E(a_i - \alpha_0 - \alpha_1 b_i \mid X_i) = 0.$$

Because $E(a_i - \alpha_0 - \alpha_1 b_i \mid X_i)$ is generally hard to test directly (small-cell problem), VV tests the parsimonious implications (E.11) and (E.12):

$$E(a_i - \alpha_0 - \alpha_1 b_i \mid i \in M_n) = 0 \tag{E.11}$$

$$E(x_{it}(a_i - \alpha_0 - \alpha_1 b_i) \mid i \in M_n) = 0 \quad \forall\, t \in S \tag{E.12}$$

where $M_n$ is the set of movers (CKT: switchers) and $S$ is the largest subset of time periods such that $\{x_{it}\}_{t\in S}$ are linearly independent among movers. For $T \geq 3$, $S = \{1, \ldots, T\}$.

## 2. Augmented exactly-identifying moment conditions

VV adds $|S|+1$ exactly-identifying moment conditions (one for $\eta_0$, one for each $t \in S$):

$$E\!\left(\mathbf{1}[i\in M_n]\,\Big([1,-\alpha_1](W'_i W_i)^{-1} W'_i (Y_i - Z_i\gamma) - \alpha_0\Big) - \eta_0\right) = 0$$

$$E\!\left(\mathbf{1}[i\in M_n]\, x_{it}\,\Big([1,-\alpha_1](W'_i W_i)^{-1} W'_i (Y_i - Z_i\gamma) - \alpha_0\Big) - \eta_t\right) = 0 \quad \forall\, t \in S$$

The bracket $[1, -\alpha_1]$ is a $1 \times 2$ row vector. The product $(W'_i W_i)^{-1} W'_i (Y_i - Z_i\gamma)$ is the $2 \times 1$ OLS coefficient vector $(\hat a_i, \hat b_i)'$ from regressing $Y_i - Z_i\gamma$ on $W_i = [1, x_{it}]$ (worker-by-worker first-stage). So:

$$[1, -\alpha_1](W'_i W_i)^{-1} W'_i (Y_i - Z_i\gamma) - \alpha_0 = \hat a_i - \alpha_1 \hat b_i - \alpha_0.$$

This is the residual whose population mean and treatment-history-weighted means are tested against zero.

## 3. Test statistic

$$H_0: \eta_0 = 0, \qquad \eta_t = 0 \quad \forall\, t \in S$$

Wald statistic, distributed $\chi^2_{|S|-1}$ under $H_0$.

The discrepancy between $|S|+1$ moments and $|S|-1$ df is intentional: $\alpha_0$ and $\alpha_1$ are jointly identified by 2 of the moments, leaving $|S|-1$ over-identifying restrictions. VV does not spell this out explicitly but all 5 transcription agents arrived at the same explanation.

## 4. Variance estimation

Three options stated by VV:
- Cluster bootstrap.
- Analytical formulae as in Proposition 6.
- Numerical differentiation of the exactly-identifying moment conditions (Stata `gmm` does this automatically via `vce(cluster ...)` after estimation).

We adopt the third option as default. Cluster the variance at `pid` for the simple spec, at `vfirst` for the robust spec.

## 5. Applicability to CKT data

| Country | Waves $T$ | $|S|$ | Test applicable? |
|---|---:|---:|---|
| CHN | 4 (2010, 2012, 2014, 2016) | 4 | Yes |
| IDN | 5 (1993, 1997, 2000, 2007, 2014) | 5 | Yes |
| TZA | 3 (2008, 2010, 2012) | 3 | Yes |

All three countries have $T \geq 3$ so $|S| \geq 2$ and the test produces a non-trivial $\chi^2$ statistic.

## 6. Worked Stata expression (skeleton)

The augmented `gmm` system extends `run_grc`'s existing equation. In CKT notation, $\alpha_1 = \phi$ and $\alpha_0 = $ a new intercept parameter (separate from the existing trajectory means). For the simple spec (no $v$-clustering):

```stata
* Worker-level OLS coefficients â_i, b̂_i computed in a first step.
* Generated variables: a_hat (= â_i), b_hat (= b̂_i), is_mover (= 1[i ∈ M_n]).
* For each time period t in S: an additional dummy x_t = (period == t) * choice.

eststo `estname': gmm                                                 ///
    (lndepvar - {mu: never `switcher_traj'}                           ///
     - {Delta_base}*choice                                            ///
     - {phi=-1}*(`switcherpars')                                      ///
     - ({kappa}+{phi}*({kappa} - {mu: switcher_`base'}))              ///
       *(always#1.choice)                                             ///
     - {xb: `covarlist'})                                             ///
    /* augmented moments for LCA overid */                            ///
    (is_mover * (a_hat - {phi}*b_hat - {alpha_0}) - {eta_0})          ///
    (is_mover * x_t1 * (a_hat - {phi}*b_hat - {alpha_0}) - {eta_t1})  ///
    (is_mover * x_t2 * (a_hat - {phi}*b_hat - {alpha_0}) - {eta_t2})  ///
    /* ... one per t in S, dropping one for normalization ... */      ///
    , instruments(...)                                                ///
      vce(cluster pid)                                                ///
      from(`initial')                                                 ///
      quickderivatives nolog iterate(`iterations')

* Wald test
test ([eta_0]_cons = 0) ([eta_t1]_cons = 0) ([eta_t2]_cons = 0) /* ... */
estadd scalar lca_chi2 = r(chi2)
estadd scalar lca_df   = r(df)
estadd scalar lca_p    = r(p)
estimates save "$dir/output/`estname'.ster", replace
```

For the robust spec (`vindex(v)`): replace `vce(cluster pid)` with `vce(cluster vfirst)`. The first-stage worker-level regression of $Y_i - Z_i\gamma$ on $W_i$ already lives inside `run_grc`'s estimation of trajectory means (so $\hat a_i, \hat b_i$ are derivable from the existing GMM estimates rather than recomputed); confirm during P3 implementation.

## 7. Open implementation questions

- **Q1.** Does `run_grc` already produce $\hat a_i$ and $\hat b_i$ as identifiable post-estimation objects, or do we need a separate worker-level regression to compute them? If the latter, the `gen a_hat b_hat is_mover` step needs to be added before the augmented `gmm` call.
- **Q2.** The $|S| + 1$ moment conditions are listed as exactly-identifying — meaning the $\alpha_0$ and $\eta_0, \eta_t$ parameters are exactly identified by them. Stata `gmm` requires the system to be at least exactly identified; verify that adding $|S|+2$ parameters ($\alpha_0, \eta_0, \eta_t$ for $t\in S$) and $|S|+1$ moment conditions does not over-determine the existing $\phi$ parameter. The fix may require either (a) imposing a normalization that drops one $\eta_t$, or (b) treating $\alpha_0$ as a derived quantity via `nlcom` rather than a free parameter.
- **Q3.** For the robust spec, does $\alpha_0$ become $\alpha_0(v)$ (one intercept per cluster) or stay as a single scalar? VV's Section F treats $e_v$ (CKT's $\beta(v)$) as the cluster-specific intercept; the LCA overid would test whether the cluster-demeaned residual $\hat a_i - \alpha_1 \hat b_i - e_{v_i}$ is uncorrelated with $X_i$ within $M_n$. Verify whether VV addresses this in Section F (the transcribed text is from E.3.2, which is about the simple spec).

These three questions need answers before P3 code is written. Q3 in particular may require its own short transcription pass on Section F's testing discussion (currently no equivalent of E.3.2 has been transcribed for the robust spec).

## 8. Sign-off

- [ ] **Derivation approved.** Reviewer: _________ Date: _________
- [ ] **Open questions Q1--Q3 resolved.**
- [ ] **Ready for P3 code.**
