# Methods review: counterfactual experiments plan

**Date:** 2026-05-18.
**Target:** [plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md), [design memo](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md), [paper-side draft](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).
**Mode:** pre-implementation methods review.
**Scope:** identification, inference, estimand definitions, parametric choices, sequencing.
**Reviewer stance:** harsh, severity-tiered, no fixes proposed for CRITICAL identification issues.

---

## Headline

Two CRITICAL identification problems block readiness: (i) Option 2 of E1 is internally inconsistent and the plan acknowledges the inconsistency but proceeds anyway, and (ii) the cross-piece consistency assumption that E1 depends on is already known to fail for CHN and is not stress-tested for IDN/TZA.
Three MAJOR problems concern inference (the "convex hull of joint CI image" lacks an articulated coverage claim), $\sigma_\theta$ pinning (degenerate under unbalanced specs), and validation milestone V2 (anchors on the same arithmetic it is supposed to validate).
The rest is MINOR or fixable in implementation.

The plan is buildable as code.
It is not yet defensible as econometrics.

---

## CRITICAL findings

### C1. Option 2 of E1 contradicts the empirical $\Delta_{d_N} > 0$ and the plan does not resolve the contradiction

[Plan §Estimands item 3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md); [memo §1 "Tension with the decision rule"](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

The Option 2 conditional density is

$$f_{\theta \mid d_N}(\theta) \;\propto\; f_\theta(\theta) \cdot F_\eta(-\beta - \phi\theta)^T.$$

This expression presupposes that eq.~(6) of the model generates $d_N$ membership.
Under eq.~(6) and $\phi < 0$, the workers in $d_N$ are those for whom $\beta + \phi\theta_i + \eta_{it} < 0$ in every period; conditional on that event, $E[\Delta_i \mid d_N] < 0$ in expectation (standard selection inequality under rational sorting; never-stayers stay because their pecuniary return is bad).

The empirical $\Delta_{d_N} > 0$ from the LCA extrapolation directly contradicts the maintained generating assumption underlying Option 2.

The memo flags this and offers a verbal resolution: "either institutional barrier ... or LCA misspecification off-support."
The plan does not engage with the implication.
Both verbal resolutions invalidate Option 2's interpretation.
First, if institutional barriers are blocking eq.~(6), then the conditional density $F_\eta(-\beta - \phi\theta)^T$ is not the right kernel; it should be the barrier-distorted choice rule, not the frictionless one.
Using the frictionless kernel and integrating $\max(0, \Delta_i)$ against it is computing the wrong object.
Second, if LCA misspecifies off-support, then $\Delta_i = \beta + \phi\theta_i$ is not the worker-level return for $d_N$ members, and Option 2 integrates the wrong integrand.

Either way, the plan as written delivers a number, prints a CI, and the number does not have a clean interpretation tying back to the model.

I do not propose a fix.
The author needs to decide whether Option 2 is (a) reported as a sensitivity with an explicit caveat that the kernel is misspecified, (b) replaced with a Bayes-rule kernel that conditions on $d_N$ via the empirical mean $\mu_{d_N}$ rather than the model's choice probability, or (c) dropped.
What is not defensible is the current plan, which produces the integral and reports a CI without taking a position on what the number means.

Severity: CRITICAL. Confidence: HIGH.

### C2. Cross-piece consistency: E1 requires LCA to hold simultaneously on $d_N$, $d_T$, and every switcher trajectory; CHN's $J$-rejection is direct evidence it fails

[Plan §Risk register R5/R6](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md); [memo §1 "Deeper concern: LCA out of the switcher support"](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

E1 is a sum across $\{d_N\} \cup \mathcal{D}_S \cup \{d_T\}$ using a single $(\phi, \beta)$ pair to pin down $\Delta_{d_N}$ (LCA extrapolation) and $\Delta_{d_T}$ (LCA inversion), with switcher $\Delta_{\underline{d}}$ left non-parametric.
The cross-piece use of $(\phi, \beta)$ is exactly what the overid test checks.

CHN pooled rejects.
The plan's response (R5) is to report regime-by-regime for CHN, summed in proportion to subsample share.
This is reasonable for CHN, but the plan does not pose the analogous question for IDN and TZA.
The $J$-test does not reject in their pooled specs, but failure-to-reject is not evidence that LCA carries to $d_N$.
The $J$-test is computed against switcher moments; it is silent about extrapolation to $d_N$, which is where the bulk of the E1 magnitude sits (the memo notes $\pi_{d_N} \approx 0.75$ TZA, $\approx 0.50$ IDN).

The plan acknowledges this under R6 and tags it "low impact at implementation, high at interpretation."
I disagree with the tagging.
This is the single most consequential assumption in the entire exercise.
The headline number---"$X\%$ of consumption is misallocated"---is essentially a restatement of the LCA extrapolation, weighted by population shares.
If the slope $\phi$ from switchers does not carry to $d_N$, the headline is misstated by whatever the slope error is times the population weight, which is the bulk of the aggregate.

I do not propose a fix.
The author needs to decide whether E1 ships with an explicit identification caveat that says "this number is what LCA implies; we have no test that LCA carries off-support to $d_N$," or whether it requires an out-of-support diagnostic (see M6).
The current plan does neither.

Severity: CRITICAL. Confidence: HIGH.

---

## MAJOR findings

### M1. "Convex hull of the joint CI image" is not articulated as a coverage object

[Plan §Inference protocol P3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

The protocol takes a $1-\alpha$ joint CI region $\mathcal{R}_{1-\alpha} \subset (\phi, \beta)$, evaluates the counterfactual aggregate $g(\phi, \beta)$ over $\mathcal{R}_{1-\alpha}$, and reports $[\min_{\mathcal{R}_{1-\alpha}} g, \max_{\mathcal{R}_{1-\alpha}} g]$.

This is a projection CI: the image of a $1-\alpha$ region under a deterministic map $g$ covers the true $g(\phi_0, \beta_0)$ with probability at least $1-\alpha$ if $(\phi_0, \beta_0) \in \mathcal{R}_{1-\alpha}$ with probability $1-\alpha$.
Coverage is conservative; how conservative depends on the curvature of $g$ over $\mathcal{R}_{1-\alpha}$ and on whether $\mathcal{R}_{1-\alpha}$ is itself conservative.

Things the plan should state and does not.
First, the coverage claim ("$[\min, \max]$ has at least $1-\alpha$ coverage as a CI for $g(\phi_0, \beta_0)$") and the reference (Chen, Christensen, and Tamer 2018 is the natural citation; Andrews-Mikusheva 2016 for the weak-ID-robust version).
Second, that the image of a convex region under a non-monotone $g$ can be non-convex; the "convex hull" wording is then itself an enlargement that further conservatives coverage.
Third, whether the joint $\mathcal{R}_{1-\alpha}$ is a Wald region, a constrained-$J$ region, or something else.
The plan says "GMM Wald statistic (or the constrained $J$ at that $(\phi, \beta)$ implied by the LCA restriction)."
The "or" is doing too much work: these are different objects with different coverage properties, and the inversion machinery already commits to constrained $J$ for the marginal $\phi$ CI.
Consistency requires constrained $J$ for the joint.
Fourth, the conservativeness is not uniform.
Near the Möbius pole, $g$ has unbounded derivative in $\phi$, so projection CIs are arbitrarily wide; away from the pole, projection coverage tightens to the underlying $\mathcal{R}_{1-\alpha}$ coverage.
Cross-country comparison of CI widths therefore confounds coverage and curvature.

Alternatives the plan should consider, even if it rejects them.
First, bootstrap-after-grid for the aggregate directly: at each accepted $(\phi, \beta)$, the aggregate has a delta-method SE for the parts that are smooth in $(\phi, \beta)$; combining with the grid coverage gives a tighter CI.
Second, score-test inversion in the aggregate, treating $g(\phi, \beta) = g_0$ as a nuisance-profiled hypothesis.
This is the Chen-Christensen-Tamer recipe and would be tighter than projection.

The current "convex hull" approach is defensible as a conservative report, but the plan should say "this is conservative projection inference, coverage at least $1-\alpha$, tighter alternatives deferred" rather than leaving the inference object unnamed.

Severity: MAJOR. Confidence: HIGH.

### M2. $\sigma_\theta$ from cross-trajectory variance is degenerate in unbalanced specs

[Plan §Estimands item 3, §Risk register R3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

The plan pins $\sigma_\theta$ as the population-weighted cross-trajectory variance of $\mu_{\underline{d}}$.
Under the unbalanced headline specs, $\mathcal{D}_S$ is lumped into a single trajectory, so cross-trajectory variance is computed over $\{d_N, \mathcal{D}_S, d_T\}$---a three-point distribution with three weights summing to one.

A three-point variance is not zero, but it is not pinning $\sigma_\theta$ in any meaningful sense.
It is a coarse summary of three group means, and its magnitude depends mechanically on the population shares of the three trajectory bins.
Two countries with identical underlying $\theta$ dispersion but different population splits across $d_N$, switchers, $d_T$ will produce different "estimates" of $\sigma_\theta$.

R3 acknowledges this and proposes a side-by-side report of three-trajectory variance vs balanced-sample trajectory variance.
This is not enough.
The balanced-sample variance is also not $\sigma_\theta$ in the population: it is the cross-trajectory variance over whatever trajectory partition the balanced sample admits.
Neither object identifies the within-trajectory dispersion that Option 2 needs.

What the plan should say.
$\sigma_\theta$ is not identified by the existing GRC machinery.
The cross-trajectory variance is an upper bound on $\sigma_\theta$ (by the law of total variance), not a point estimate.
Option 2 with $\sigma_\theta$ set to the cross-trajectory variance is then an upper-bound calculation, not the "magnitude rather than a bound" the memo claims.
Option 3 already understands this---it parameterizes $\sigma_{\theta \mid d_N} = c \cdot \sigma_\theta$.
Option 2 should be reframed as the $c = 1$ point of Option 3 rather than as a separate "heterogeneity-corrected estimate."

Severity: MAJOR. Confidence: HIGH.

### M3. V2 anchors on numbers derived from the same arithmetic V2 is supposed to validate

[Plan §Validation milestones V2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md); [memo §1 back-of-envelope](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

V2 checks that Option 1 misallocation for TZA col 5 matches $\approx 22\%$ within $\pm 0.5$pp; similarly for IDN $\approx 3.7\%$.

These benchmarks come from the memo's back-of-envelope.
The back-of-envelope is computed from the same identified objects ($\Delta_{\underline{d}}$, $\pi_{\underline{d}}$, $\bar{D}_{\underline{d}}$) the production code consumes, via the same arithmetic the production code performs.
V2 therefore checks that the production code reproduces hand-arithmetic on its own inputs.
This catches transcription errors, indexing bugs, and unit confusions.
It does not validate the magnitude against any external benchmark.

The plan should call V2 what it is: a code-consistency check, not a magnitude validation.
The validation milestones should additionally include something that triangulates against an external object, e.g., the urban-rural consumption gap reported in CFPS/IFLS/TZNPS descriptives, or the misallocation magnitudes in Lagakos-Mobarak-Waugh 2023 (with explicit reconciliation of why magnitudes differ).
Without an external triangulation, V2 passing means "the code computes what I told it to compute," not "the magnitude is right."

Severity: MAJOR. Confidence: HIGH.

### M4. Empty joint CI handling (R1) elides what an empty joint CI means

[Plan §Risk register R1](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

R1: "if empty, fall back to reporting the gap at the point estimate with a footnote that the joint CI is empty (meaning the LCA restriction is rejected at the chosen alpha)."

An empty joint $1-\alpha$ CI means the model is rejected at level $\alpha$.
The point estimate under a rejected model is not a defensible report.
Reporting it with a footnote is reporting a number derived from a model the data rejects.
The footnote does not make the number interpretable.

CHN pooled is the leading candidate.
The plan already handles CHN by splitting into hukou regimes (R5), which is the right move.
For any other (country, spec) where the joint CI is empty, the defensible options are: (i) drop that cell from the table, or (ii) report only the parts of the aggregate that do not depend on the rejected restriction (the switcher piece, computed from the non-parametric $\Delta_{\underline{d}}$, plus the zero-migration piece).
The current fallback is neither.

Severity: MAJOR. Confidence: HIGH.

### M5. P4 marginal-CI projection check is correctly characterized as a propagation check, but the 10% tolerance is unjustified

[Plan §Inference protocol P4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

You called this right: it checks arithmetic, not coverage.
The projected marginal CI for $\Delta_{d_N}$ from the joint $(\phi, \beta)$ region should weakly cover the cached marginal CI for $\Delta_{d_N}$ stored in `*_n.ster`, because the joint Wald (or constrained $J$) region projects to a marginal region at least as wide as the marginal Wald region used for the cached CI.
That is the propagation arithmetic.

The 10% half-width tolerance is unjustified.
Discrepancies of under 10% can hide real bugs (e.g., a wrong-units conversion that compounds across the aggregate); discrepancies of over 10% can be legitimate (the projection of a 2D Wald region to its $\phi$ axis can be substantially wider than the 1D marginal $\phi$ Wald region when the region is elongated; the same applies to $\Delta_{d_N}$).
The check should either be exact (zero tolerance, expect the projected CI to contain the cached CI as a set inclusion) or replaced with a Bonferroni-style sanity bound.

Severity: MAJOR. Confidence: MEDIUM.

### M6. Out-of-support extrapolation tagged "low impact at implementation" is mis-tagged

[Plan §Risk register R6](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

See C2.
At minimum, the implementation should include an out-of-support diagnostic that reports where $\mu_{d_N}$ sits relative to $\{\mu_{\underline{d}} : \underline{d} \in \mathcal{D}_S\}$.
Two natural diagnostics.
First, a distance metric: $\min_{\underline{d} \in \mathcal{D}_S} |\mu_{d_N} - \mu_{\underline{d}}|$ in units of the within-trajectory standard error of $\mu_{\underline{d}}$.
Second, a hull check: is $\mu_{d_N}$ in the convex hull of $\{\mu_{\underline{d}} : \underline{d} \in \mathcal{D}_S\}$?
In the unbalanced lumped case this is trivially a one-dimensional hull check (is $\mu_{d_N}$ between the min and max switcher $\mu$?).

Add this to the diagnostics CSVs (D2 or a new D4).
It does not block implementation; it does inform whether the headline number should be reported as "extrapolation within support" or "extrapolation off support."

Severity: MAJOR. Confidence: HIGH.

### M7. E2 resorting: mapping $\beta^{rh} \to \beta^{uh}$ conflates institutional and price-level heterogeneity

[Plan §Estimands item 6, §Risk register R4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

The plan parameterizes the hukou wedge as the intercept gap $\beta^{rh} - \beta^{uh}$.
R4 acknowledges that this conflates institutional barriers with price-level heterogeneity and proposes Reading A (full gap is institutional) vs Reading B (continuum $c$).

This is partial.
The intercept $\beta$ in the GRC is identified from the urban-rural consumption gap among switchers, holding $\theta_i$ fixed.
It absorbs four things at once: (i) pecuniary urban premium net of cost-of-living (the institutional reading wants this), (ii) cost-of-living difference between urban and rural areas (mechanical price-level), (iii) compensating differentials for non-pecuniary location attributes that average across the switcher population (Suri-style amenity, the welfare bridge in §3 of the memo), and (iv) any selection bias not absorbed by $\phi\theta_i$ under LCA misspecification.

Setting $\beta^{rh} = \beta^{uh}$ removes the difference between two intercepts that each contain all four components.
It is the right thing to do only under the additional assumption that components (ii)-(iv) are equal across the two hukou regimes.
That assumption is strong and is not stated.

Reading B's continuum $c$ does not fix this.
It sweeps the magnitude of the wedge, not its identification.
Without an argument that components (ii)-(iv) are equal across regimes, $c = 1$ is not "fully removed institutional barrier"; it is "fully removed intercept difference, of which an unknown fraction is institutional."

A more defensible framing: report the intercept difference $\beta^{rh} - \beta^{uh}$ as the maintained-assumption upper bound on the institutional wedge, with the explicit assumption stated.
Reading B then becomes "fraction $c$ of the intercept gap is institutional"; the policy interpretation requires a position on what $c$ is, not just a plot.

Severity: MAJOR. Confidence: MEDIUM.

### M8. $\sigma_\eta$ identification is deferred to "E2 Step 4 or sensitivity grid" and never specified

[Plan §Estimands item 3, §Risk register R4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md); [memo §3 Route B](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

Option 2 and the E2 resorting simulation both require $\sigma_\eta$, the scale of $\nu^U - \nu^R$.
The plan says: "$\sigma_\eta$ pinned per E2 Step 4 below or set to a sensitivity grid here in E1."
There is no E2 Step 4 in the plan.
The memo's Route B describes the identification step (match $\pi_{d_T} = E_\theta[(1 - F_\eta(-\Delta(\theta)))^T]$) but this is explicitly out of scope (memo §Out of scope, listed as Experiment 3 deferred).

Two problems.
First, without $\sigma_\eta$ identified, Option 2 is a function of a free parameter, not a number.
The "sensitivity grid" approach is fine, but the grid range needs justification.
Logistic with $\sigma_\eta \in [0.1, 5]$ produces wildly different conditional densities for $\theta \mid d_N$; the headline number from Option 2 inherits the range.
Second, the resorting simulation under logistic shocks needs $\sigma_\eta$ to compute choice probabilities.
"Logistic vs normal" sensitivity is a shape sensitivity; the scale matters more numerically and is not addressed.

The plan should either commit to a $\sigma_\eta$ identification step within scope (the memo's Route B is the natural choice; it sits "in the same machinery as E2 resorting" per the plan's own out-of-scope note), or reframe Option 2 and E2-resort explicitly as "for a stated $\sigma_\eta$" with a defensible grid.

The current "deferred" status is not a position.

Severity: MAJOR. Confidence: HIGH.

### M9. Joint normality of $\theta_i$ contradicts the paper's stated avoidance of Borjas-style log-normality

[Plan §Estimands item 3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md); [memo §3 "Why both routes"](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

The memo contrasts our LCA approach with Borjas because Borjas assumes joint log-normality and "our LCA approach deliberately avoids this distributional assumption."
Option 2 then assumes $\theta_i \sim N(0, \sigma_\theta^2)$.

Mechanically these are different objects.
Borjas assumes log-normality of $(\theta^U, \theta^R)$; we assume normality of the rescaled comparative advantage $\theta_i = b_R(\theta^U - \theta^R)$.
But the spirit is the same: we are adding a Gaussian-tails assumption on the latent comparative-advantage distribution in order to integrate $\max(0, \Delta_i)$.
Saying "we avoid Borjas distributional assumptions" in the main text and then adopting a normal $\theta_i$ for the counterfactual is at minimum a presentation inconsistency.

This is salvageable.
Option 2 can be framed as a sensitivity exercise, not as a maintained assumption.
The paper text in [paper/results_counterfactuals.tex:58](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) already softens this ("under a stated parametric form for $\nu_{it}^l$") for $\nu$, but not for $\theta_i$.
The paper text should match: state that Option 2 imposes a parametric form on $\theta_i$, that this is more than LCA asks for in the main analysis, and that Option 1 plus Option 3 are the assumption-light reports.

Severity: MAJOR. Confidence: HIGH.

---

## MINOR findings

### m1. "Value of observed migration" framing

[Paper draft lines 39-44](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex); [memo §1.1 "Both extremes"](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

$W_{\text{obs}} - W_{\text{zero}}$ as the "value of observed migration" is a useful policy object on its own, but the framing needs care.
The zero-migration counterfactual fixes each worker at the location of their initial trajectory observation, which is itself a sorted assignment (workers in $d_T$ are "fixed" at urban, which is their observed initial location).
A genuine zero-migration counterfactual would fix everyone at rural (or at random initial assignment).
The plan's $W_{\text{zero}}$ is closer to "no further migration after initial assignment" than to "zero migration ever."

This is fine if labeled honestly.
The paper draft labels it "no migration" / "value of observed migration"; the memo labels it "zero migration" / "current welfare gains from migration."
These labels suggest a stronger counterfactual than the math delivers.
The labeling should clarify that this is migration on the intensive margin (time spent in destination after initial sort), not the extensive margin (ever migrating).

Severity: MINOR. Confidence: HIGH.

### m2. Standard reporting conventions in the migration literature

[Memo §3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).

The plan reports $W_{\text{obs}} - W_{\text{zero}}$ and $W_{\text{opt}} - W_{\text{obs}}$ as the headline objects.
The literature has a partly different convention.
Bryan-Morten 2019 reports aggregate productivity gain from optimal reallocation as a percentage of baseline productivity, decomposed into reallocation across regions; their object is closer to $W_{\text{opt}} - W_{\text{obs}}$ but expressed as a multiplicative factor on aggregate output.
Lagakos-Mobarak-Waugh 2023 reports a "TFP gap" between urban and rural, then a counterfactual share of the gap attributable to selection vs barriers; their object is decompositional rather than levels-based.
Hicks-Kleemans-Li-Miguel 2024 reports return-to-migration estimates at the individual level; aggregate counterfactuals are not their primary object.

None of these is exactly $W_{\text{opt}} - W_{\text{obs}}$.
Hsieh-Klenow-style misallocation indices (variance of $\log(\text{MRPL})$ across units) are the closest formal benchmark, but they require marginal-product data and are not directly portable.

The plan would benefit from one sentence in the paper text saying "we use the [Bryan-Morten / Lagakos-Mobarak-Waugh] convention of reporting [object] in [units]" with an explicit citation, and reporting one cross-walk number (e.g., the Bryan-Morten-style aggregate productivity gain) alongside our preferred object, so cross-paper comparison is possible.

Severity: MINOR. Confidence: MEDIUM.

### m3. Logistic vs normal shock: implied $\sigma_\eta$ identification differs by family

[Plan §Estimands item 3, item 6, Open issue O2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

Under type-I EV difference, $\sigma_\eta^2 = \pi^2 \sigma^2 / 6$ where $\sigma$ is the scale parameter.
Under normal, $\sigma_\eta^2$ is the variance directly.
The two reports under "same nominal $\sigma_\eta$" therefore use different scale parameters in the underlying CDFs.
If $\sigma_\eta$ is itself identified differently (e.g., matched to $\pi_{d_T}$, as memo Route B suggests), then logistic and normal will produce different $\sigma_\eta$ point estimates.

The plan should specify whether the "logistic vs normal" sensitivity holds $\sigma_\eta$ fixed across the two (in which case it is a shape sensitivity) or re-identifies $\sigma_\eta$ separately under each family (in which case it is a joint shape-and-scale sensitivity).
The first is interpretable; the second confounds shape with scale.

Severity: MINOR. Confidence: HIGH.

### m4. Random seed for Py-mod 4 stated but seed-stability not validated

[Plan §Cross-cutting infrastructure Py-mod 4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

Seed 42 fixed, 10,000 draws per worker.
With around 50,000 rural-hukou workers and 10,000 draws each, simulation variance is small but not zero.
The plan should specify a Monte Carlo standard error target (e.g., "MC SE on the aggregate is under 0.1pp at 10,000 draws; if not, increase draws") and a seed-stability check (run under seeds 42 and 43, compare aggregates; flag if difference exceeds MC SE target).

Severity: MINOR. Confidence: HIGH.

### m5. R2 numerical instability fallback drops Option 2 silently

[Plan §Risk register R2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

R2: "if the integral still does not converge, drop Option 2 for that (country, spec) and report Option 1 plus Option 3 envelope only."

Dropping Option 2 conditional on convergence failure is reasonable, but the plan should ensure the dropped status is visible in the output (table footnote, diagnostic CSV row), not silent.
Currently the diagnostics D1-D3 do not include a "Option 2 dropped at this cell" indicator.

Severity: MINOR. Confidence: HIGH.

### m6. Master switch default of $0$ is fine but should be documented

[Plan §Cross-cutting infrastructure §Master integration](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).

Counterfactuals run only when `run_counterfactuals = 1`.
Document this in [RP7/scripts/0_master.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_master.do) with a comment line explaining the gate (compute cost, optionality), and surface the switch in any README that will travel to ReplicationPackage7/.

Severity: MINOR. Confidence: HIGH.

---

## Diagnostics or robustness checks missing from the plan

The plan has D1-D3.
The following should be added.

D4. Out-of-support diagnostic.
Per (country, spec): position of $\mu_{d_N}$ relative to the convex hull of $\{\mu_{\underline{d}} : \underline{d} \in \mathcal{D}_S\}$, and same for $\mu_{d_T}$.
This is the M6 fix; addresses C2 partially.

D5. Sensitivity to $\sigma_\eta$ grid.
For Option 2 and E2-resort, report the aggregate at $\sigma_\eta \in \{0.5, 1.0, 2.0, 5.0\} \cdot \hat\sigma_\eta$ where $\hat\sigma_\eta$ is either pinned per memo Route B (preferred) or set to 1 (fallback).
Without this, the reader cannot tell which fraction of Option 2's CI comes from $(\phi, \beta)$ uncertainty and which from arbitrary $\sigma_\eta$ choice.

D6. Cross-trajectory variance vs balanced-sample variance.
Report both candidates for $\sigma_\theta$ (per R3) and the resulting Option 2 magnitudes side by side.
Already implicit in the plan; promote to a diagnostic.

D7. Decomposition of CI width.
For each (country, spec), decompose the inversion CI on the aggregate into the contribution from $\phi$ uncertainty alone (holding $\beta$ at $\hat\beta$), $\beta$ uncertainty alone (holding $\phi$ at $\hat\phi$), and the joint.
The Möbius pole near $\phi = -1$ should dominate when $\phi$ uncertainty alone is the input; if it does not, that is informative about which parameter is doing the work.

D8. Leave-one-trajectory-out sensitivity.
Recompute the aggregate with each switcher trajectory dropped in turn.
Cheap and surfaces whether any single trajectory is driving the magnitude.
Only meaningful in balanced specs where $|\mathcal{D}_S| > 1$.

D9. Placebo / sign-flip check.
At $\hat\phi$ flipped to $-\hat\phi$ (so the LCA slope is the wrong sign), recompute the aggregate.
The point estimate should change substantially; if it does not, the result is not being driven by the slope.
This is a sanity check on whether the headline depends on $\phi < 0$ vs the mechanical population weights.

---

## Sequencing comments

The seven-sequence timeline is reasonable.
The main risk to sequencing is C1 and C2: if either fires after V2 passes, all downstream code (S3-S7) needs reinterpretation, not just rerun.
Sequence S2's gate should be expanded beyond "back-of-envelope arithmetic match" to include "author has approved the C1/C2 framing for the paper text."
Otherwise S3-S6 build production infrastructure for an exercise whose interpretation is unresolved.

V6 is fine as a final gate but should additionally verify that all CRITICAL and MAJOR caveats in this review appear in the paper text or are resolved in code.
Otherwise the paper text drifts from what the code actually computes.

---

## What survives scrutiny

The plan's strongest pieces, and what does survive.
E1 Option 1 (conservative floor) is defensible under the maintained assumptions, transparent about what it does and does not assume; the Jensen-monotonicity framing in [memo §1.2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md) is clean.
The $W_{\text{obs}} - W_{\text{zero}}$ piece is mechanically sound (no LCA extrapolation enters; only identified switcher and $d_T$ pieces), modulo the labeling issue in m1.
Option 3 envelope ($c \in [0, 1]$) is the right way to display the within-trajectory dispersion sensitivity; properly framed, Option 2 collapses into the $c = 1$ point of Option 3 (per M2).
The inversion-CI propagation infrastructure (P1, P2) is the right machinery, and P4 is a sensible propagation check (per M5).
E2 lower bound is defensible.
The risk register exists and most major risks are identified, even if some are mis-tagged (R3, R6).

## What does not yet survive scrutiny

Option 2 of E1 as currently specified (C1).
The cross-piece consistency assumption silently maintained for IDN and TZA (C2).
The inference claim attached to "convex hull of joint CI image" (M1).
The $\sigma_\theta$ pinning (M2).
V2 as a magnitude check rather than a code-consistency check (M3).
Empty-CI fallback (M4).
$\sigma_\eta$ identification (M8).
Joint normality of $\theta_i$ contradicting paper-level framing (M9).

## Bottom line for the author

The plan is buildable, and most of the building should proceed.
What needs to happen before the headline numbers are paper-ready is a position---in writing, by the author, in the paper text or a companion methods note---on each of the two CRITICAL items: what does Option 2 of E1 mean given the internal inconsistency (C1), and how should the reader read the headline number given that LCA cross-piece consistency is not testable for the $d_N$ piece (C2)?
The MAJOR items are technical specifications the plan can absorb during implementation (M1, M2, M4-M8) or framing fixes in the paper draft (M9).
The MINOR items are housekeeping.

This is a pre-implementation review.
The identification strategy survives scrutiny for the floor and the bound; it does not yet survive scrutiny for the heterogeneity-corrected magnitudes or the cross-country aggregates.
The author should decide what is in and what is out before code is written, not after.

---

End of review.
