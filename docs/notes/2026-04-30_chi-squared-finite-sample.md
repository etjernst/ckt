# Finite-sample bias of chi-squared asymptotics in GMM tests

## What $J_R$ refers to

$J_R$ is the number of over-identifying restrictions of the GMM model we test, equivalently the degrees of freedom of the chi-squared distribution we are inverting.
The general GMM setup with $m$ moments and $p$ parameters has $J_R = m - p$ over-identifying restrictions; under $H_0$ the J-statistic has an asymptotic $\chi^2_{J_R}$ distribution.

In our paper, the LCA assumption $\Delta_d = \beta + \phi (\mu_d - \mu_{\text{base}})$ delivers the over-identifying restrictions: the auxiliary OLS gives $K$ switcher-specific $\widehat{\beta}_s$ as moments, the LCA fits two parameters ($\beta$, $\phi$), leaving $K - 2$ restrictions for the joint test $\phi$ alone (since $\beta$ is concentrated out as a nuisance).
With $K - 1$ non-base switchers entering the just-identified inversion's restriction vector $r_s(\beta, \phi)$ and $\beta$ pinned to $\beta_{\text{base}}$ by the base equation, the just-identified inversion has $J_R = K - 1$.
For the constrained MD inversions (`grid_delta_*_md_inversion`), the same $K - 1$ effective restrictions remain after profiling $\phi$ out.

So $J_R = K - 1$ for the inversions we run, where $K$ is the number of kept switchers.
The chi-squared finite-sample bias documented in the literature applies to GMM J-tests with any over-identifying structure; our LCA setup is one specific instance.

By country, with the threshold-5 sparse-switcher drop:

| Country | $K$ kept | $J_R$ |
|---|---:|---:|
| TZA | 5 | 4 |
| CHN | 10 | 9 |
| IDN | 27 | 26 |

Our $T = 4$ Monte Carlo runs at $K = 14$ ($J_R = 13$) sit between CHN and IDN.
TZA is the cleanest empirical case from a chi-squared-asymptotics standpoint; IDN is the riskiest.

## What "finite-sample bias in chi-squared asymptotics" means

The Wald, J, and LR statistics in GMM are derived under asymptotic theory: as the number of observations or clusters grows, the test statistic converges in distribution to $\chi^2_{J_R}$ under $H_0$.
In finite samples the empirical distribution of the statistic systematically differs from $\chi^2_{J_R}$.
The bias has two well-known features.

First, the empirical mean of the statistic exceeds $J_R$ (the chi-squared mean) under $H_0$, especially with cluster-robust covariance and small-to-moderate cluster counts.
Equivalently, the asymptotic critical value is too small: a $\chi^2_{J_R}$ at the 5% upper tail puts less mass in the rejection region than the true sampling distribution at the 5% upper tail.
The test rejects $H_0$ too often.

Second, the bias grows with $J_R$.
Intuitively, the chi-squared approximation to a quadratic-form Wald statistic comes from a CLT applied to a $J_R$-dimensional moment vector.
Each additional dimension demands more sample to converge.
For fixed $N$ (or fixed cluster count), larger $J_R$ produces more bias.

This is why we observed:

- $T = 3$, $K = 6$, $J_R = 5$: empty-CI rate 5/100 $= 5\%$ (matches nominal exactly), $\Delta_{\text{avg}}$ coverage 0.90 (close to nominal).
- $T = 4$, $K = 14$, $J_R = 13$: empty-CI rate 15/200 $= 7.5\%$ (over-rejects by 2.5 pct), $\Delta_{\text{avg}}$ coverage 0.84 (under-covers by 11 pct).

The under-coverage of the inversion CI is a *direct consequence* of the over-rejection of the test we are inverting.
When the asymptotic critical value puts too little mass beyond the cutoff, the inversion's accept region is too small, and the resulting CI is too narrow.

## Citations and adjustments

The classical reference is Hansen, L., Heaton, J., and Yaron, A. (1996), "Finite-Sample Properties of Some Alternative GMM Estimators," *Journal of Business and Economic Statistics* 14(3), 262--280.
They document via Monte Carlo that the GMM J-test over-rejects in moderate samples, especially with many moments, and that the bias scales with the number of over-identifying restrictions.
This is the canonical citation.

Newey, W. K., and McFadden, D. (1994), "Large Sample Estimation and Hypothesis Testing," in R. F. Engle and D. L. McFadden (eds.), *Handbook of Econometrics*, Vol. 4, Ch. 36, North-Holland, pp. 2111--2245, derive the asymptotic distribution of the minimum-distance test (the basis of our `grid_md_inversion`) and discuss finite-sample issues in §7.

For corrections, the literature offers four broad strategies:

1. Bartlett-style multiplicative corrections to the test statistic.
For likelihood ratio tests in regular models this is well-developed: Lawley, D. N. (1956), "A General Method for Approximating to the Distribution of Likelihood Ratio Criteria," *Biometrika* 43(3), 295--303; Cribari-Neto, F., and Cordeiro, G. M. (1996), "On Bartlett and Bartlett-Type Corrections," *Econometric Reviews* 15(4), 339--367.
For GMM, see Imbens, G. W., Spady, R. H., and Johnson, P. (1998), "Information Theoretic Approaches to Inference in Moment Condition Models," *Econometrica* 66(2), 333--357; and Newey, W. K., and Smith, R. J. (2004), "Higher Order Properties of GMM and Generalized Empirical Likelihood Estimators," *Econometrica* 72(1), 219--255.
These develop empirical-likelihood-based corrections that share the Bartlett spirit but require a different estimating equation; implementing them on our MD setup is non-trivial.

2. F-distribution corrections (cheap, principled, recommended as the first robustness pass).
In linear models the exact distribution of the Wald is $F(J_R, N - K)$ rather than $\chi^2_{J_R} / J_R$; using the F critical value introduces a small-sample correction.
For GMM with cluster-robust covariance the canonical reference is Imbens, G. W., and Kolesár, M. (2016), "Robust Standard Errors in Small Samples: Some Practical Advice," *Review of Economics and Statistics* 98(4), 701--712.
They propose a Bell-McCaffrey adjustment to the variance estimator (named after Bell, R. M., and McCaffrey, D. F. (2002), "Bias Reduction in Standard Errors for Linear Regression with Multi-Stage Samples," *Survey Methodology* 28(2), 169--181), combined with an F-distribution whose denominator degrees of freedom $\widehat{\nu}$ is estimated by a Satterthwaite-type formula.
The adjustment replaces $\chi^2_{J_R, 0.95}$ in `grid_lca_inversion` and the MD inversions with $J_R \cdot F_{0.95}(J_R, \widehat{\nu})$.
For typical cluster counts in our data this shifts the critical value upward by a few percent and widens the inversion CI accordingly.

3. Bootstrap calibration of the test (more expensive, more powerful).
Hall, P., and Horowitz, J. L. (1996), "Bootstrap Critical Values for Tests Based on Generalized-Method-of-Moments Estimators," *Econometrica* 64(4), 891--916, show that bootstrap critical values for GMM tests have asymptotic refinements over the chi-squared.
For our LCA inversion, this would mean: at each grid $\phi$, recompute the Wald on $B$ bootstrap resamples of individuals, and use the empirical 95th percentile of the bootstrap Walds in place of $\chi^2_{J_R, 0.95}$.
This corrects both the chi-squared bias and the cluster-robust covariance approximation in one move.
The cost is $B \times$ (grid size) Wald computations per cell, parallelizable across grid points.

4. Higher-order asymptotic expansions.
Edgeworth expansions of the J-statistic characterize the bias analytically and could be inverted to a corrected critical value.
See Andrews, D. W. K. (2002), "Higher-Order Improvements of a Computationally Attractive k-Step Bootstrap for Extremum Estimators," *Econometrica* 70(1), 119--162.
This is the most principled but the least off-the-shelf.

We have not applied any of these.
The current paper reports inversion CIs that are mildly anti-conservative (under-cover at the empirical CKT scale by an amount that grows with $K$).

## Is bootstrap better than inversion?

Short answer: not in the way you were thinking.
Long answer: it depends on which bootstrap, and what we are robust to.

There are two distinct objects you might compute with a bootstrap.

First, a bootstrap of the GMM point estimate $\widehat{\Delta}_{\text{avg}}$.
Resample individuals with replacement, refit the GMM, take percentile or bias-corrected percentile of the bootstrap distribution.
This gives a CI on the *sampling distribution* of the GMM point estimate.
It is robust to finite-sample bias in cluster-robust standard errors.
It is *not* robust to weak identification: if the GMM point estimate's distribution is non-normal because $\phi$ is weakly identified, the bootstrap of the GMM point estimate will inherit that non-normality and the percentile CI may be misleading.
This is what the TODO entry calls "panel bootstrap CIs" and what most practitioners mean when they say "bootstrap CI".

Second, a bootstrap calibration of the inversion test.
Resample individuals with replacement, recompute the LCA Wald statistic (or the constrained MD Wald) at each grid $\phi$ (or $\Delta$), tabulate the bootstrap distribution of the Wald *under* $H_0$ at each grid point, take the empirical 95th percentile, use that as the critical value in place of $\chi^2_{J_R, 0.95}$.
This corrects the chi-squared finite-sample bias while preserving everything else about the inversion CI, including its weak-ID robustness.

The two are not interchangeable.
Specifically:

- The point-estimate bootstrap is *not strictly better* than the inversion CI.
It trades weak-ID robustness for finite-sample-bias correction.
For the trajectory-specific returns at the empirical CKT scale, $\phi$ identification is genuinely weak in some specifications (the LCA inversion CI for $\phi$ on IDN/covs_all spans almost the full $[-1.23, -0.01]$ range).
A point-estimate bootstrap could under-cover or over-cover unpredictably depending on how non-normal the point estimator's distribution is.
- The bootstrap-calibrated inversion CI *is* strictly better than the chi-squared inversion CI in the finite-sample-bias dimension, because it replaces the chi-squared approximation with a finite-sample-correct distribution while preserving the inversion structure.
It is more expensive ($B$ Walds per grid point) but theoretically dominates the chi-squared inversion.

So your intuition that the inversion is the most robust object was mostly right.
What it misses is that "the inversion CI" is shorthand for "the inversion of a chi-squared test."
The chi-squared part is asymptotic and biased in finite samples; replacing it with a bootstrap-calibrated test gives you the same weak-ID robustness with better finite-sample calibration.

For the paper, I would suggest the following pragmatic ranking:

1. Headline inversion CI as currently reported, with a footnote describing the finite-sample bias and pointing the reader to a robustness check.
2. Robustness check: Imbens-Kolesar Bell-McCaffrey-Satterthwaite F adjustment, applied to all the chi-squared critical values.
This is cheap, principled, and known to help in samples like ours.
3. If the F adjustment doesn't fully close the under-coverage gap, run a bootstrap-calibrated inversion at each grid point for the IDN $K = 27$ specs (where the bias is largest) as a final robustness column.
4. The point-estimate panel bootstrap (the original TODO entry) is still useful as a cross-check, but should be presented as "we also report a panel bootstrap CI on the GMM point estimate; it is not weak-ID-robust but it is robust to cluster-SE finite-sample issues, so the agreement (or disagreement) with the inversion CI is informative."

The cheapest first step is option (2): re-run `grid_lca_inversion` and the three delta inversions with the F adjustment in place of the chi-squared cutoff, and check whether the synthetic coverage at $T = 4$, $K = 14$, $J_R = 13$ moves toward 0.95.
If yes, we have a quick fix.
If not, escalate to (3).

## Recap

$J_R = K - 1$ where $K$ is the number of kept switchers, and is the chi-squared dof of the LCA test we invert.
For our empirical specs $J_R$ runs from 4 (TZA) to 26 (IDN); the bias scales with this number.
The classical citation for the over-rejection of GMM tests is Hansen, Heaton, and Yaron (1996); the most pragmatic correction is the Imbens-Kolesar (2016) F adjustment.
A panel bootstrap of the point estimate is useful but is not strictly better than the inversion CI; the inversion CI inherits the chi-squared finite-sample bias but gives weak-ID robustness that the point-estimate bootstrap loses.
The right "best of both" is bootstrap calibration of the inversion test itself (Hall and Horowitz 1996).
