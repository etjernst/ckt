# Alpha-pooling derivation: does it bias the Verdier estimator or only the CI?

**Date:** 2026-04-24
**Context:** The [econometrics-critic review](file:///C:/git/ckt/docs/reviews/2026-04-24_lca-inversion-verdier-critique.md) §4 flagged a potential CRITICAL issue with the [Option B design](file:///C:/git/ckt/docs/reviews/2026-04-24_lca-inversion-ci-verdier-design.md) for Verdier LCA-inversion CIs: pooling cluster-specific trajectory-level intercepts $\alpha_{s,v}$ into a single $\bar\alpha_s$ may re-import between-cluster selection that the Verdier demeaning was supposed to purge.

The user asked whether this is an issue only for the CI procedure, or also for the Verdier point estimator itself. This memo works through the derivation.

## 1. Plain-English summary

The Verdier robust estimator in [run_grc_robust_vv](file:///C:/git/ckt/RP7/scripts/0_programs.do) identifies $\phi$ by pooling moment conditions across switcher trajectories $s$ and clusters $v$. Each moment uses WITHIN-cluster variation in treatment (via the cluster-demeaned instrument `swd_switcher_s_choice`). That demeaning purges cluster-specific baseline returns $\beta(v)$ from the moment.

But the moments for DIFFERENT switcher trajectories $s$ each weight clusters differently --- they weight each cluster $v$ by (i) the sample share of trajectory-$s$ workers in that cluster and (ii) the within-cluster variance of $D$ among those workers. If different trajectories have systematically different distributions across clusters (e.g. rural-to-urban-early switchers concentrate in a few coastal provinces while rural-to-urban-late switchers are more dispersed), those moment weights differ across $s$. And if $\beta(v)$ varies across clusters in a way that correlates with this differential trajectory distribution, the GMM estimator of $\phi$ absorbs some of that variation.

**So the answer to the user's question is: yes, the alpha-pooling concern affects both the estimator and the CI.** The CI procedure in Option B is just a clean venue to expose the same problem that quietly biases the estimator.

However, the problem vanishes under one or both of the following conditions:

- **Trajectory pooling holds and worker types are distributed similarly across clusters.** I.e., conditional on trajectory $s$, the cluster distribution of workers is the same (or very close) for all $s$. Then moment weights are invariant to $s$ and no contamination.
- **$\beta(v)$ is weakly correlated with the trajectory-specific cluster distributions.** Even if weights differ across $s$, if $\beta(v)$ doesn't "tilt" with those differential distributions, the bias is small.

VV's paper implicitly invokes both conditions by treating the within-cluster demeaning as sufficient. CKT's trajectory-pooling assumption (one $\mu_s$ per trajectory, not per $(s, v)$) aligns with the first condition.

The rest of this memo shows the derivation.

## 2. Setup and notation

**Verdier LCA population restriction:**
$$\Delta_i = \beta(v_i) + \phi\,\theta_i$$
where $\theta_i$ is individual comparative advantage, $\beta(v_i)$ is the cluster-specific LCA intercept, $\phi$ is the common LCA slope.

**CKT trajectory pooling:**
$$E[\theta_i \mid d_i = s] = c \cdot (\mu_s - \mu_{d_0}), \qquad E[\theta_i \mid d_i = s, v_i = v] = E[\theta_i \mid d_i = s]$$
with constant of proportionality $c$ (we set $c = 1$ throughout for notational ease; it gets absorbed into $\phi$). The second equality is the key simplifying assumption: given trajectory, the distribution of $\theta_i$ does NOT depend on cluster. This is not innocuous; when it fails, everything downstream needs re-examination.

**Trajectory-pooled conditional means:**
$$\mu_s = E[y^R_{it} \mid d_i = s], \qquad \mu_{s,v} = E[y^R_{it} \mid d_i = s, v_i = v]$$
Under trajectory pooling, $\mu_{s, v} = \mu_s$ for all $v$.

**Implied trajectory-and-cluster-specific treatment effect:**
$$\Delta_{s, v} := E[\Delta_i \mid d_i = s, v_i = v] = \beta(v) + \phi \cdot (\mu_s - \mu_{d_0})$$

**CKT's simple-spec GMM moment equation** (for a switcher-$s$ worker, ignoring covariates and always-urban for clarity):
$$\varepsilon_{\text{CKT}, it} = y_{it} - \mu_{d_i} - \Delta_{d_0}\,D_{it} - \phi\,(\mu_{d_i} - \mu_{d_0})\,\mathbb{1}\{d_i \in S \setminus \{d_0\}\}\,D_{it}$$

The Verdier robust variant replaces the raw switcher-choice instruments with cluster-demeaned ones:
$$\text{swd}_{s, it} = \mathbb{1}\{d_i = s\} \cdot (D_{it} - \bar D_{s, v_i}), \qquad \bar D_{s, v} := E[D_{it} \mid d_i = s, v_i = v]$$
Moment conditions: $E[\text{swd}_{s, it} \cdot \varepsilon_{\text{CKT}, it}] = 0$ for each switcher $s$.

## 3. What does the Verdier moment pin down?

Plug the true DGP into $\varepsilon_{\text{CKT}, it}$ for a worker with $d_i = s$:
$$y_{it} = \mu_s + \Delta_i\,D_{it} + u_{it}$$
where $u_{it}$ is mean-zero idiosyncratic given $(d_i, v_i)$. Under the Verdier LCA with trajectory pooling:
$$\Delta_i = \beta(v_i) + \phi\,(\mu_s - \mu_{d_0}) + \phi\,(\theta_i - (\mu_s - \mu_{d_0}))$$
The last term is mean-zero given $d_i = s$.

Substitute into $\varepsilon_{\text{CKT}, it}$ at some fitted $(\Delta_{d_0, \text{fit}}, \phi_{\text{fit}})$:
$$\varepsilon_{\text{CKT}, it} = \big[\beta(v_i) - \Delta_{d_0, \text{fit}}\big]\,D_{it} + \big[\phi - \phi_{\text{fit}}\big]\,(\mu_s - \mu_{d_0})\,D_{it} + \text{mean-zero}$$
The first bracket collects cluster-specific deviations from the fitted scalar $\Delta_{d_0, \text{fit}}$. The second bracket is the bias from misfitting $\phi$.

**Taking the moment** $E[\text{swd}_{s, it} \cdot \varepsilon_{\text{CKT}, it}]$:
$$E[\text{swd}_{s, it} \cdot \varepsilon_{\text{CKT}, it}] = \sum_v \pi(s, v)\, E[(D - \bar D_{s, v}) D \mid d = s, v]\, \big[\beta(v) - \Delta_{d_0, \text{fit}} + (\phi - \phi_{\text{fit}})(\mu_s - \mu_{d_0})\big]$$
where $\pi(s, v) = P(d_i = s, v_i = v)$.

Note $E[(D - \bar D_{s, v}) D \mid d = s, v] = \text{Var}(D \mid d = s, v)$. Define cluster-and-switcher weights:
$$w(s, v) := \pi(s, v) \cdot \text{Var}(D \mid d = s, v)$$
These weights are NOT normalized. Divide by $W(s) := \sum_v w(s, v)$ to get a probability measure:
$$\tilde w(s, v) := w(s, v) / W(s)$$

**The moment for switcher $s$ becomes:**
$$W(s) \cdot \Big[\bar\beta(s) - \Delta_{d_0, \text{fit}} + (\phi - \phi_{\text{fit}})(\mu_s - \mu_{d_0})\Big] = 0$$
where
$$\bar\beta(s) := \sum_v \tilde w(s, v)\,\beta(v)$$
is the cluster-specific LCA intercept averaged across clusters, with weights tilted by (i) how heavily trajectory-$s$ workers are represented in each cluster, and (ii) the within-cluster variance of treatment among those workers.

## 4. Is the estimator biased?

Setting the moment equal to zero for each switcher $s$:
$$\Delta_{d_0, \text{fit}} = \bar\beta(s) + (\phi - \phi_{\text{fit}})\,(\mu_s - \mu_{d_0}) \qquad \forall s \in S$$

This is a system of $|S|$ equations in 2 unknowns ($\phi_{\text{fit}}$, $\Delta_{d_0, \text{fit}}$). GMM solves it by minimizing the weighted sum of squared residuals.

**Case 1: $\bar\beta(s)$ is the same for all switchers $s$.**
Then the system reduces to one equation (repeated $|S|$ times):
$$\Delta_{d_0, \text{fit}} = \bar\beta + (\phi - \phi_{\text{fit}})\,(\mu_s - \mu_{d_0})$$
This is solved by $\phi_{\text{fit}} = \phi$ and $\Delta_{d_0, \text{fit}} = \bar\beta$. **The estimator is consistent for the true $\phi$.** The fitted $\Delta_{d_0}$ represents a sample-share-and-variance-weighted average of cluster-specific baseline returns.

**Case 2: $\bar\beta(s)$ varies across switchers.**
Let $\delta_s := \bar\beta(s) - \bar\beta$ where $\bar\beta$ is the $s$-average. Then:
$$\Delta_{d_0, \text{fit}} = \bar\beta + \delta_s + (\phi - \phi_{\text{fit}})\,(\mu_s - \mu_{d_0})$$
The FOCs from GMM (under identity weighting) give:
$$\sum_s [\Delta_{d_0, \text{fit}} - \bar\beta - \delta_s - (\phi - \phi_{\text{fit}})(\mu_s - \mu_{d_0})] = 0$$
$$\sum_s [\Delta_{d_0, \text{fit}} - \bar\beta - \delta_s - (\phi - \phi_{\text{fit}})(\mu_s - \mu_{d_0})](\mu_s - \mu_{d_0}) = 0$$

Solving: $\phi_{\text{fit}}$ differs from $\phi$ by an amount proportional to $\text{Cov}_s(\delta_s,\, \mu_s - \mu_{d_0})$.

**The bias in $\hat\phi$ is:**
$$\hat\phi - \phi = -\frac{\text{Cov}_s(\delta_s,\, \mu_s - \mu_{d_0})}{\text{Var}_s(\mu_s - \mu_{d_0})}$$

Where $\delta_s = \bar\beta(s) - \bar\beta$ captures the cluster-reweighted LCA intercept for switcher $s$ (its "$s$-tilted" version).

**Conclusion.** Verdier is consistent for $\phi$ under EITHER of:

1. **Weights do not depend on $s$** --- i.e. $\tilde w(s, v) = \tilde w(v)$ for all $s$. This holds if trajectory-$s$ workers' cluster distribution and their within-cluster treatment variance are the same across switchers.
2. **$\bar\beta(s)$ does not covary with $(\mu_s - \mu_{d_0})$** --- i.e. the cluster-reweighting for each switcher doesn't systematically select clusters with high or low $\beta(v)$ in a way that correlates with that switcher's trajectory mean.

If both fail, the Verdier estimator is biased --- and the bias has nothing to do with within-cluster identification failing; it's a between-cluster selection effect smuggled in through differential moment weights.

## 5. Is the CI (Option B) biased for the same reasons?

Yes, by the same logic. The Option B auxiliary OLS pools across clusters to form $\beta_s^{\text{w}}$ (within-cluster-demeaned treatment-by-trajectory effects). The OLS implicit weights are the same variance-sample-share products as above, so the same $\bar\beta(s)$ tilting happens.

Writing the OLS pooled estimand asymptotically:
$$\beta_s^{\text{w}} \xrightarrow{p} \bar\beta(s) + \phi\,(\mu_s - \mu_{d_0})$$

The LCA restriction in Option B is $(\beta_s^{\text{w}} - \beta_{s_0}^{\text{w}}) - \phi\,(\mu_s - \mu_{s_0}) = 0$. Under the TRUE $\phi$:
$$(\beta_s^{\text{w}} - \beta_{s_0}^{\text{w}}) - \phi\,(\mu_s - \mu_{s_0}) = \bar\beta(s) - \bar\beta(s_0) = \delta_s - \delta_{s_0}$$

If $\delta_s$ varies with $s$, this is NOT zero at the true $\phi$, so the Wald statistic is non-degenerate at $\phi = \phi_{\text{true}}$ and the CI is biased.

**So the CI and the estimator share the same vulnerability.** Neither is more robust than the other. The reviewer was right to flag it, but mis-characterized the scope: it's a property of the identification strategy, not a problem introduced by the Option B design.

## 6. How much does this matter in practice?

Two empirical questions:

(a) **Are the weights $\tilde w(s, v)$ meaningfully different across switchers?** This is easy to check: for each $(s, v)$ cell, compute $\pi(s, v) \cdot \text{Var}(D \mid d = s, v)$ and look at whether the cluster profile differs across switcher trajectories. If TZA, CHN, IDN all show similar cluster profiles across switchers, the estimator is effectively unbiased.

(b) **If weights differ, how strongly does $\beta(v)$ correlate with the $s$-tilted distributions?** Harder to check directly because $\beta(v)$ is unobserved. An indirect check: compute the cluster-specific per-switcher treatment effect $\Delta_{s, v}$ (via saturated OLS Option A), compute $\bar\beta(s) \approx \Delta_{s, v} - \phi \cdot (\mu_s - \mu_{d_0})$ for each $(s, v)$ under an assumed $\phi$, see whether $\bar\beta(s)$ covaries with $(\mu_s - \mu_{d_0})$ across $s$. If the covariance is small, bias is small.

## 7. Does this change Option B's status?

Partially. Option B is no worse than the Verdier estimator itself --- both rely on the same assumption. But Option B is also no better. If the user believes the Verdier estimator is trustworthy on the TZA/CHN/IDN data (because trajectory pooling + similar cluster profiles are plausible), Option B's CI is equally trustworthy.

What Option B LOSES vs the Stock-Wright-S alternative (Option C revisited): robustness to weak identification. When $\phi$ is weakly identified, Option B's Wald statistic becomes degenerate in the usual way (non-pivotal distribution) --- just like Wald-based inference on any weakly identified parameter. Stock-Wright-S with onestep $W = I$ sidesteps this because the S-statistic stays pivotal under weak ID.

What Option B GAINS: sharper CIs near strong ID (Wald is more powerful than S when identification is strong), familiar Wald machinery, simple implementation by extending [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).

## 8. Revised recommendation

Given this derivation:

1. **Check assumption (a) empirically on the three datasets.** If cluster profiles are approximately $s$-invariant, the Verdier estimator is approximately unbiased and Option B is a valid CI machinery (modulo the $G = 22$--$29$ small-cluster asymptotics qualification from the critic review §3).

2. **Add a sensitivity diagnostic to the main comparison.** Report $\max_{s, s_0} |\tilde w(s, \cdot) - \tilde w(s_0, \cdot)|$ as a summary statistic; if small across all country-cov combinations, the assumption is empirically supported.

3. **Implement Option B as the primary CI route**, with the above diagnostic. Promote Stock-Wright-S (Option C reformulated) to a secondary route for weak-ID insurance.

4. **Flag in the paper text that the Verdier robust estimator assumes trajectory-pooling + $s$-invariant cluster weighting** (implicitly, even before any CI concerns). This is already implicit in CKT's trajectory-pooling framework but deserves explicit acknowledgement.

The alpha-pooling concern doesn't block Option B, but it does upgrade the importance of empirically checking the underlying assumption.
