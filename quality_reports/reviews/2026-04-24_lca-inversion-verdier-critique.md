# Econometrics-critic review of LCA-inversion Verdier design memo

**Date:** 2026-04-24
**Target memo:** [2026-04-24_lca-inversion-ci-verdier-design.md](file:///C:/git/ckt/docs/reviews/2026-04-24_lca-inversion-ci-verdier-design.md)
**Reviewer:** `econometrics-critic` subagent
**Mode:** Independent critique; no author input before the review was written.

---

## 1. Simple-spec prototype description (memo §1)

Description is essentially faithful to [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py). Two small inaccuracies worth flagging:

- The OLS includes `unbalanced` and `unbalanced_choice` indicators (lines 99-113). The memo's display equation omits them. Harmless but incomplete.
- The memo writes "Sparse switcher trajectories (too few treated clusters) get dropped before the fit." The code's threshold is "at least `threshold` unique `hhid` contributing a treated obs" (lines 74-79), i.e. treated pids, not treated clusters. This matters for the Verdier extension because the analogous filter there needs to be at the $(s, v_{\text{first}})$ cell level with at least 2 treated pids per cell; the memo's Open Question 3 acknowledges this but the §1 phrasing is already non-literal.

Everything else --- Jacobian constant, $V_R$ one-sandwich computation, grid inversion as convex hull of acceptance set --- matches the code.

## 2. Stating the Verdier LCA restriction (memo §2)

This is the memo's weakest exposition. The Verdier estimator in [run_grc_robust_vv](file:///C:/git/ckt/RP7/scripts/0_programs.do) does NOT estimate cluster-specific $\beta(v)$ in the main GMM. It (i) projects each switcher-treatment interaction on `i.vfirst` among that trajectory's workers, (ii) replaces the raw `switcher_s_choice` instrument with its residual `swd_switcher_s_choice`, (iii) runs the SAME GMM moment equation as `run_grc`, with a single pooled $\{\phi\}$ and unrestricted $\{\text{mu:switcher}_s\}$ terms. There is no $\beta(v_i)$ parameter in the equation. The "cluster-specific LCA intercept" interpretation lives only in the asymptotic argument for why the robust instrument identifies $\phi$ without contamination from between-cluster sorting --- it is a statement about what is differenced OUT, not what is estimated.

So the display $(\beta_{s,v} - \beta_{s_0,v}) - \phi (\mu_s - \mu_{s_0}) = 0$ for all $(s,v)$ is the population restriction being exploited, but it is not what the Stata estimator parameterizes. Option A's saturated-beta formulation tries to honor that display literally; Option B does not. This ambiguity is the root of concerns raised in (3)--(4). The memo should say something like: "the Verdier estimator does not parameterize $\beta(v)$; within-cluster demeaning of the instrument is the device that purges it." Minor but substantive.

## 3. Option B asymptotics (memo §4)

Option B as literally described is a pure OLS --- trajectory $\times$ vfirst FE plus pooled $\beta_s^{\text{w}}$ on within-cluster-demeaned $z_s$. Mechanically that is the FWL representation of an OLS analog of the Verdier IV: demean $y$ and each $z_s$ within $(s, v_{\text{first}})$, run pooled OLS on the demeaned vars, recover $\beta_s^{\text{w}}$. That is fine as an auxiliary just-identified vehicle; there are $|S|$ pooled $\beta_s^{\text{w}}$ coefficients and $|V|$ per-$(s,v)$ alphas absorbed. The $|S|-1$ df claim for the Wald is correct IF the auxiliary is just-identified in the parameters entering the restriction --- which it is, as long as $\bar\alpha_s - \bar\alpha_{s_0}$ is expressed as a linear combination of absorbed $\alpha_{s,v}$ coefficients in the same OLS vector that $\beta_s^{\text{w}}$ lives in, with a valid joint VCV.

However --- **MAJOR issue, MEDIUM confidence** --- the memo elides a critical point. The asymptotic argument for weak-ID honesty of AR-style Wald inversion requires the auxiliary OLS coefficients to be CAN normal at root-$N$ (or root-$G$ where $G$ = # clusters) REGARDLESS of $\phi$'s identification strength. That holds for $\beta_s^{\text{w}}$ (OLS on demeaned regressors, $G = 22$--$29$ clusters, cluster-robust SEs at `vfirst`). But the target of the restriction on the trajectory-mean side is $\bar\alpha_s$, which in Option B is a weighted average of cluster FE coefficients. With only 22--29 clusters and sparse $(s, v_{\text{first}})$ cells, many $\alpha_{s,v}$ are estimated on a handful of observations; some cells are empty (dropped from the fit). The mapping $\bar\alpha_s = \sum_v w_v \alpha_{s,v}$ is only well-defined if the weights $w_v$ are fixed functions of sample shares on the support where $\alpha_{s,v}$ is identified. That is feasible but the asymptotics are not automatic at $G = 22$--$29$ --- this is a small-$|V|$, ragged-cell regime where the Wald statistic's denominator depends on many thinly-estimated FE.

The honest statement is: under standard cluster-asymptotic regularity ($G \to \infty$), the test is size-correct whether $\phi$ is strong or weak, with $|S|-1$ df. At $G = 22$--$29$ with sparse cells, size is approximate --- the memo should not claim weak-ID honesty without qualifying the cluster count.

## 4. Pooling $\alpha_{s,v}$ to $\bar\alpha_s$ (specific concern)

This is the sharpest design question in the memo, and the §4/§9 treatment is too breezy.

$\phi$ in the Verdier spec IS identified by within-cluster variation --- that's the whole point of the demeaned instrument. But the LCA restriction being tested, $\Delta_i = \beta(v_i) + \phi \mu_{d_i}$, needs a trajectory-mean anchor $\mu_{d_i}$. That anchor is a POPULATION object, not a within-cluster object. In the simple spec this is unambiguous because there's one alpha per trajectory; in the Verdier spec, $\bar\alpha_s = E[\alpha_{s, V}]$ is an average over the cluster distribution.

Two things matter:

(a) Sample-share vs equal weighting is NOT asymptotically innocuous for the Wald. The two choices define different estimands $\bar\alpha_s$ (expectation vs unweighted mean), hence different constraint functions $r_s(\phi)$. Sample-share weighting targets the population-mean $\mu_s$ that $\phi$ should extrapolate with; equal weighting targets an artificial uniform-over-clusters object. The point estimate of $\bar\alpha_s$ and its variance differ; Wald values at the same $\phi_0$ differ; CIs differ. Sample-share is the right default. Equal weighting would need justification.

(b) There is a subtler identification point. Using between-cluster variation in $\bar\alpha_s$ (which is what aggregating $\alpha_{s,v}$ across $v$ does) to test a restriction on $\phi$ that is separately identified within-cluster risks re-importing exactly the between-cluster selection that the Verdier demeaning was designed to purge. If cluster-level selection into migration differs across $v$, $\bar\alpha_s - \bar\alpha_{s_0}$ absorbs that cross-cluster sorting, while the numerator $\beta_s^{\text{w}} - \beta_{s_0}^{\text{w}}$ does not. The ratio driving the LCA test is then a mismatched object --- a within-based slope benchmarked against a between-contaminated intercept gap. The simple-spec prototype does not face this because there is no cluster dimension to aggregate over.

This is a potential **CRITICAL issue under weak identification, MEDIUM confidence**. The memo should work out whether $\bar\alpha_s - \bar\alpha_{s_0}$ can be reformulated using only within-cluster variation (e.g. as a cluster-average of WITHIN-cluster trajectory-differences, which is a different object), or argue formally that the population LCA restriction is the same whether you anchor on $\mu_s$ (population) vs $\bar\mu_{s,v}$ averaged. This deserves explicit derivation, not a throwaway mention in Open Questions.

## 5. Option D (boottest) AR-honesty claim

The memo's characterization is directionally correct but imprecise. `boottest` with $\{\phi=0\}$ imposes the null in the score-equivalent sense and inverts via wild cluster bootstrap. That is NOT the same as "bootstrap concentrates around $\hat\phi$." With Roodman's (2019) implementation, `boottest ..., ci` does grid-search inversion of the restricted bootstrap distribution, producing confidence sets that can be unbounded or disjoint when the test is non-informative. In that sense it is closer to AR-honest than the memo suggests.

However, Roodman/MNW wild-cluster bootstrap inherits its size properties from the Wald / t-statistic it is inverting, which is a STRONG-ID object. Under weak identification, the finite-sample distribution of $t(\phi_0)$ is not well-approximated by a mean-zero wild-bootstrap sampling distribution built around the unrestricted fit --- the unrestricted fit is itself non-standard. Andrews-Guggenberger-type results show that non-pivotal-statistic bootstraps can severely under-cover under weak ID. So Option D is NOT AR-honest, but for a more nuanced reason than "concentrates around $\hat\phi$." With $G = 22$--$29$ clusters and Webb weights (Rademacher is too coarse at $G < 12$), `boottest` improves finite-sample size of the Wald test but does not fix weak-ID non-pivotness. The memo's one-liner dismissal is correct in direction, incomplete in reasoning.

## 6. Alternatives not considered

- **Kleibergen (2005) K-statistic** adaptation is the natural counterpart to AR when there are multiple moments and a scalar coefficient of interest with nuisance structural parameters. In this setup $\phi$ is scalar and the nuisance parameters ($\mu$, $\Delta_{\text{base}}$, $\kappa$, $xb$) are numerous --- K (or the LM version) projects out the nuisance gradient and can deliver sharper CIs than AR when $\phi$ is close to strongly identified, while retaining size under weak ID. Worth a sentence.

- **CLR (Moreira 2003)** was developed for linear IV with a single endogenous regressor and homoskedastic errors. The GRC moment equation is nonlinear in $\{\phi\}$ (through the always-urban term $(\kappa + \phi \cdot (\kappa - \mu_{\text{switcher}_{\text{base}}})) \cdot \text{always} \cdot \text{choice}$), so CLR does not directly apply. An Andrews-Moreira-style CLR generalization to GMM exists (Andrews, Moreira, Stock 2006, 2007) but is heavy machinery for this context. Not worth pursuing for a robustness check.

- A **nonparametric projection approach** (invert each moment separately, intersect the univariate CIs with Bonferroni adjustment) would be strictly conservative but immune to cell-sparsity concerns in (4). Worth having as a sanity check.

- **Stock-Wright S** directly on the Verdier moments with onestep $W = I$ is actually well-defined --- the worry in Option C is about two-step rank deficiency, but Stock-Wright S uses a first-step weight that does not require inversion of a cluster-robust moment covariance. This is closer to AR than the memo acknowledges. **C deserves a second look specifically as S-statistic inversion, not LR-style.**

## 7. Errors and missing caveats

- §2 statement conflates the population restriction with the estimator's parameterization, as noted in (2).
- §4 Wald df claim is technically correct only if $\bar\alpha_s$ is expressed as a linear combination within the full OLS coefficient vector; the variance propagation is subtle when some $(s, v_{\text{first}})$ cells are dropped for rank deficiency. Needs explicit treatment.
- §4 Implementation sketch clusters at `vfirst`. That is correct for matching the Verdier estimator but deviates from the simple-spec prototype's `pid` clustering. The shift to coarser clustering increases SEs and reduces power; this is a feature (AR honesty under cluster-level selection) but should be stated as a deliberate design choice, not a "critical detail" footnote.
- §4 does not discuss what happens to `drop_sparse_switchers` under the demeaned instruments. Open Question 3 raises it but does not resolve. The threshold MUST be at the $(s, v_{\text{first}})$ cell level with $\geq 2$ treated pids per cell, otherwise the within-demeaning produces identically-zero regressors for that cell. This should be lifted out of Open Questions into §4 because it changes how many switchers survive.
- No mention of how the always-urban cluster-demeaned instrument (`swd_always_choice`) enters the auxiliary OLS. The Verdier GMM uses it; an OLS analog needs to decide whether to include `always_choice` demeaned within `vfirst` as an additional regressor. Missing.

## Summary

Option B is a reasonable direction but it is not as clean an extension of the simple-spec prototype as the memo argues. The two non-trivial issues are:

(a) **Potential CRITICAL, MEDIUM confidence:** Pooling $\alpha_{s,v}$ to $\bar\alpha_s$ may re-import between-cluster selection that Verdier demeaning purges --- needs explicit derivation.

(b) **Qualification needed:** $G = 22$--$29$ clusters with ragged cells is not a regime where weak-ID-honesty claims follow automatically from standard AR asymptotics.

Option D is roughly correctly placed as a secondary check but the "loses AR-honesty" reasoning needs tightening. Kleibergen K / LM or Stock-Wright S (onestep) are worth adding as third options before committing to B alone.
