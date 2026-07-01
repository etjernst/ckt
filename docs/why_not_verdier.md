# Why we do not implement Verdier (2020) as a robustness check

Date: 2026-05-13.
Author: Emilia, with Claude.

## TL;DR

Verdier identifies $\alpha_1 = \mathrm{Cov}(\alpha, \Delta)/\mathrm{Var}(\Delta)$, where $\alpha$ is the rural-baseline random coefficient and $\Delta$ the worker-specific return.
We identify $\phi = (b_U - b_R)/b_R$, the slope in $\Delta_i = \beta + \phi \theta_i$ where $\theta_i$ is comparative advantage.
Under the projection that defines $\tau_i \perp \theta_i$, $\alpha_i = \theta_i + \tau_i$ and $\alpha_1 = 1/\phi$ in population.
Reciprocals, but of different objects, projected through different IVs.
"Verdier agrees" is a statement about reciprocal projections, not about the same parameter.

The exercise is also outside Verdier's design regime for our data on three other counts: clusters, T, and the hukou split.
Combined, the case against running this as a headline robustness check is strong.

## Five substantive reasons

### 1. The estimand is reciprocal-but-different

$\alpha_1 = 1/\phi$ holds under the orthogonality $\tau_i \perp \theta_i$ that the projection in our model imposes by construction.
That orthogonality is part of how we define $\tau_i$ in the first place, not a testable restriction.
So "Verdier's $\hat\alpha_1$ matches $1/\hat\phi$" rules in something tautological if you accept the projection, and uninterpretable if you don't.

There's a deeper issue.
Even granting the reciprocity, what each estimator projects onto differs.
$\phi$ is the slope of returns on comparative advantage.
$\alpha_1$ is the slope of rural baseline on returns.
Different IVs, different conditioning, different finite-sample distributions.
Reading numerical "agreement" between the two as confirming the model is misleading.

### 2. Cluster regime mismatch

Verdier's robust LCA is asymptotic in the number of clusters, with bounded cluster size.
His application: 95 villages with about 12 farmers each.
Our cluster sizes are an order of magnitude larger.

- CHN with `countyid`: 357 clusters, median ~155 obs each.
- IDN with `kabu`: 233 clusters, median ~390 obs each.
- TZA with `ward`: 124 clusters, median ~240 obs each.

The cluster-FE residualization absorbs less of the within-cluster variation than the asymptotics presume.
The implied identifying signal is noisier.
This is not fatal, but it pushes us toward the "fewer clusters of larger size" regime that Verdier did not test.

### 3. Verdier cannot accommodate the hukou split

Our pooled CHN GRC rejects Hansen's $J$.
The documented resolution is splitting the sample by hukou status, because pooled CHN combines two institutional regimes with different selection structures.

Verdier's joint GMM has no analog.
You can't run "hukou-split Verdier" in any sense that mirrors what the main paper does, because the cluster-FE residualization is a single-sample estimator with the cluster definition baked in upstream.
So pooled-CHN-Verdier is being asked to do exactly what pooled-CHN-CKT also fails at.
Any disagreement between the two on pooled CHN is comparing apples to oranges.

### 4. The joint problem is ill-conditioned at $T = 5$

Verdier's setup has $7T + 2$ nuisance parameters.
We extended to $7T + 3$ with the always-stayer ATE moment.
At $T = 4$ (his application): 30 nuisance parameters.
At $T = 5$ (IDN): 38 nuisance, on top of the 91 thick covariate gammas.
130 parameters total.

IDN's joint Hessian is non-concave at the start, and the optimizer crawls through the asymptotic-tail regime for many iterations.
We diagnosed it: 30 of the 38 nuisance parameters (the per-period heterogeneous-ATE block) are weakly identified at default starting values.
Warm-starting that block with sample means at $\alpha_1 = -0.5$ helps a lot (Q at iter 0 dropped from 6.33 to 0.0017).
But the underlying conditioning issue is intrinsic to taking the estimator past its tested $T$.

### 5. We don't need this

The main paper already has internal robustness:
Hansen's $J$ for over-identification, hukou splits for CHN, balanced-vs-unbalanced for the panel structure, alternative consumption denominators, and the pooling proposition that we prove identifies the same $\phi$.
Adding Verdier on top asks the reader to absorb a second framework with different assumptions, different variance components, and a different cluster regime, before they can interpret the comparison.
For the headline claim ($\hat\phi < 0$ across countries) the marginal value is small relative to that cognitive cost.

## What we tried

Two-day implementation effort, 2026-05-10 through 2026-05-13:

First, ported Verdier's `firststage_projection.do` and `robust.do` to our data structure ([`RP7/scripts/vv_fresh.do`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/RP7/scripts/vv_fresh.do)).
Added a thick covariate block (province $\times$ period interactions) and the always-stayer ATE moment via LCA inversion.

Second, ran all three countries.
TZA converged cleanly: $\hat\alpha_1 = -1.92$, matching $1/\hat\phi$ via the reciprocity identity.
CHN converged but to $\hat\alpha_1 = +2.96$ (reciprocally $\hat\phi \approx +0.34$, opposite sign from CKT pooled), consistent with the hukou-LCA-rejection regime.
IDN did not converge under the thick spec.

Third, tried interventions for IDN.
Steeper $\alpha_1$ starting value: no effect (the function is flat in $\alpha_1$ near the start, falsified by a separate gradient diagnostic).
BFGS optimizer: too expensive at 130 parameters, never reached iter 0 in 47 wall minutes.
Relaxed `tolerance(1e-4)` with iter cap: crawled to iter 49 with Q $\approx 1.6 \times 10^{-4}$ in 19 hours wall time.
Warm-starting the per-period ATE block from sample means: dropped iter-0 Q from 6.33 to 0.0017 and looks promising (run in flight at the time of writing).

The implementation works.
The interpretation is the problem.

## Counterarguments

A referee could push back on each of the five reasons.
The honest version of each:

- **On (1):** "But $\alpha_1 \leftrightarrow \phi$ is testable in your data via the variance ratio."
True.
We could fit the GRC, read off $\sigma_R$, $\sigma_U$, $\rho$ from the moment system, then construct the implied $1/\phi$ as $\mathrm{Var}(\theta + \tau) / [\mathrm{Var}(\theta) \cdot \phi]$.
Doable, but adds a second derivation appendix.
Worth doing if a referee specifically asks.
- **On (2):** "Run with `prov` (23 large clusters) instead."
Doesn't work in combination with the thick spec.
Clustering at province AND adding province $\times$ period as controls means the residualization absorbs the variation the controls are supposed to identify.
And 23 clusters is too few for the cluster-FE asymptotics in the other direction.
- **On (3):** "Then run hukou-split Verdier."
Possible.
Doubles the implementation, doubles the tables, and the conclusion is "Verdier agrees with CKT-hukou-split that splitting is necessary," which adds nothing the main paper doesn't already show.
- **On (4):** "$T = 5$ isn't past Verdier's test point if you trust the asymptotics."
Theoretically yes.
Empirically we measure the cost in convergence behavior and burn many days of wall time per IDN fit.
- **On (5):** "Reviewers may want it anyway."
The strongest version.
Path B below addresses this without endorsing the deeper interpretation.

## Writeup options if forced to engage

A. **Skip entirely.**
One paragraph in the appendix noting that we considered Verdier (2020), explaining the estimand-mismatch issue, and pointing to this memo for detail.
Defensible if estimand-mismatch is the framing.

B. **Report what worked.**
TZA and CHN tables in the appendix.
IDN noted as "did not converge in the joint GMM at our specification within reasonable iteration count; estimates available on request."
Section text emphasizes that the comparison maps reciprocal-but-different objects, so direct numerical agreement is not the test.
Defensible and minimally reactive.

C. **Run all three.**
Path B plus warm-started IDN until it converges (in flight, may land tonight).
Adds little to the headline claim and asks the reader to engage with the estimand mapping.
Worth doing only if the referee is specifically Verdier-adjacent.

Recommended at writing: **B**, with this memo as the long-form answer if pressed.

## Files and pointers

- Implementation: [`RP7/scripts/vv_fresh.do`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/RP7/scripts/vv_fresh.do).
- Master driver: [`RP7/scripts/vv_fresh_master.do`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/RP7/scripts/vv_fresh_master.do).
- Existing appendix: [`paper/app_verdier_robustness.tex`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/paper/app_verdier_robustness.tex).
- HTML overview: [`docs/vv_fresh_port_overview.html`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/docs/vv_fresh_port_overview.html).
- Phase 1/2 session logs: [`quality_reports/session_logs/2026-05-12_vv-fresh-phase2.md`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/quality_reports/session_logs/2026-05-12_vv-fresh-phase2.md), [`quality_reports/session_logs/2026-05-13_idn-convergence-and-tza-rerun.md`](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/quality_reports/session_logs/2026-05-13_idn-convergence-and-tza-rerun.md).
- Verdier original: `tmp/vv-replication/replication_archive/Table1/Code/{firststage_projection,robust}.do`.
