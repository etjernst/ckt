# E2 V2 resorting counterfactual: theory advice on three modeling choices

Date: 2026-06-29.
Scope: structural/welfare judgment on three decisions for the hukou-removal resorting magnitude (E2 V2), grounded in the model at `paper/main.tex` lines 268--321 and the counterfactual text at `paper/results_counterfactuals.tex` lines 139--157.
Not a code review.

Notation for this memo: let $\eta_{it} \equiv \nu_{it}^U - \nu_{it}^R$ denote the location-choice taste shock entering the decision rule, with scale (standard deviation) $\sigma_\eta$.
The decision rule chooses urban iff $\beta + \phi\theta_i + \eta_{it} > 0$, so the per-period urban probability for a worker of type $\theta_i$ is $p_i = F_\eta(\beta + \phi\theta_i)$, where $F_\eta$ is the CDF of $\eta$ at scale $\sigma_\eta$.

## Decision 1: anchoring $\sigma_\eta$ to a choice-share moment

Recommendation: yes, back $\sigma_\eta$ out of an observed switching moment, and make the switcher share (not the never-migrant share, the cross-sectional urban share, or a one-step transition rate) the primary target.
Anchor to the rural-hukou switcher share for the factual baseline, and use the urban-hukou switcher share as an overidentification check on the intercept-shift parameterization.

The structural logic is tight, and it is specific to this model rather than a generic calibration convenience.
The paper assumes $\nu_{it}^l$ is i.i.d. across individuals, time, and locations (lines 277--280), which means the model attributes all within-person mobility across waves to transitory taste draws.
Under that assumption a worker's trajectory probabilities are products of per-period choice probabilities: always-urban is $p_i^T$, always-rural is $(1-p_i)^T$, and switcher is $1 - p_i^T - (1-p_i)^T$.
The switcher share is therefore the moment the i.i.d.-over-time structure speaks to most directly, because switching in this model just is the realized dispersion of $\eta$ around each worker's threshold.
Targeting it is internally consistent: you are calibrating the scale of the transitory taste shock to the observed amount of transitory movement.

This anchor is unique given $\beta$, $\phi$, and the type distribution $G(\theta)$.
The aggregate switcher share $\int [1 - p_i^T - (1-p_i)^T]\, dG(\theta)$ is monotone increasing in $\sigma_\eta$: as $\sigma_\eta \to 0$ every $p_i \to \{0,1\}$ and the share $\to 0$; as $\sigma_\eta \to \infty$ every $p_i \to 0.5$ and the share $\to 1 - 2^{1-T}$.
So any observed share interior to $(0,\, 1 - 2^{1-T})$ pins a unique $\sigma_\eta$.
For China with $T=4$ the ceiling is $0.875$, comfortably above any plausible target, but flag the ceiling as a feasibility check: a switcher share above it would refute the i.i.d. model outright.

Why not the alternatives.
The cross-sectional urban share is governed mostly by $\beta$ and the location of $G(\theta)$, not by $\sigma_\eta$, so it is a weak instrument for the scale and nearly flat in $\sigma_\eta$ near the data.
The never-migrant share is just one minus the complement of the switcher and always-urban shares, so it carries the same information as the switcher share but mixes in the always-urban mass, which is contaminated by the $\Delta_{d_T}$ singularity discussed at lines 95--101.
A one-step transition rate would be the right target only if you modeled persistence, which the i.i.d. assumption explicitly rules out, so it adds nothing here.

Use the urban-hukou switcher share as a validation moment, not a second target.
If the $\sigma_\eta$ that matches the rural-hukou share, when fed through the urban-hukou intercept $\beta^{uh}$, also reproduces the observed urban-hukou switcher share, that is direct evidence that the barrier acts as the intercept shift the counterfactual assumes.
If it does not, the discrepancy measures how much of the regime difference is something other than a level shift (a different taste scale, or the slope difference discussed below), which is exactly the diagnostic the counterfactual needs before claiming a clean wedge.
Turning the second share into an overidentification test is a low-cost addition that strengthens the parameterization.

Biggest risk: $\sigma_\eta$ absorbs every source of measured mobility in the panel, including return migration, coding error in location, and life-cycle moves the model does not represent, so the calibrated scale overstates genuine taste heterogeneity.
A large absorbed $\sigma_\eta$ makes even the no-barrier rule noisy and mechanically damps the resorting response, biasing the magnitude toward zero.
It is also partially confounded with $\mathrm{Var}(\theta)$: within-trajectory dispersion of $\theta_i$, which the GRC does not identify beyond the trajectory means $\mu_{\underline d}$, also widens the switcher share, so the single share moment cannot separate taste scale from type dispersion.
Present the anchored value as the focal point of the $\sigma_\eta$ grid the paper already commits to (line 156), not as a point-identified primitive, and state the maintained $G(\theta)$ assumption explicitly.

## Decision 2: shape of $\eta$, build type-I extreme value first

Recommendation: build the type-I extreme value (logistic $\eta$, logit choice probabilities) version first, then add the normal.

On the i.i.d. assumption the paper already makes, the Gumbel primitive is the native micro-foundation, not merely a convenient default.
The model's primitive is the location-specific shock $\nu_{it}^l$, assumed i.i.d. across locations; if each $\nu^l$ is type-I extreme value, then $\eta = \nu^U - \nu^R$ is logistic and the binary choice probability is exactly $\Lambda(\beta + \phi\theta_i)$.
That is the McFadden random-utility result, and it makes the distributional assumption and the choice shape the same modeling object rather than two separate commitments.
The logit is also the empirical-migration default the paper cites, so it is the least surprising shape to that audience and reads directly off the decision rule at equation~\eqref{eq:decision-rule}.

The usual reason to prefer normal here is absent.
Normality is the Heckman convention because joint normality of the selection shock and the outcome error delivers the inverse-Mills correction.
But the model assumes $\nu_{it}^l$ is orthogonal to the consumption error $\varepsilon_{it}$ (line 279), which shuts down selection on unobserved consumption, so normality buys none of the Heckman machinery in this setup.
The closed-form-versus-simulation tradeoff also does not discriminate: because choice is binary and shocks are i.i.d. over time, both logistic and normal give closed-form choice probabilities (logit and probit), so neither requires simulation.
That leaves the micro-foundation and convention arguments, and both point to logit.

Biggest risk: the logistic has heavier tails than the normal at matched variance, so it places more probability on counter-index choices (low-$\theta$ workers who migrate, high-$\theta$ workers who stay), and the resorting magnitude in the tails is sensitive to this.
This is the substantive reason the paper is right to report both shapes, but it means the headline must not over-read the logit point.
A concrete safeguard: define $\sigma_\eta$ as the standard deviation of $\eta$ and compare the two shapes at equal $\sigma_\eta$, backing out the logistic scale $s = \sigma_\eta \sqrt{3}/\pi$ rather than equating scale parameters, so the logit-versus-normal contrast reflects shape alone and not an accidental variance difference.

## Decision 3: common re-estimated base for the headline, and $c<1$ as the central wedge

Recommendation on the base: use the common re-estimated base for the headline counterfactual, and report the regime-specific bases as the robustness range.

The wedge $\beta^{rh} - \beta^{uh}$ is only an economic quantity if the two intercepts sit on a common normalization.
Each regime's intercept is defined relative to its own base trajectory $\underline d_0$, and the base sets where on the $\theta$ axis the LCA line $\Delta = \beta + \phi\theta$ is anchored.
If $\underline d_0^{rh} \neq \underline d_0^{uh}$, part of the raw gap $\beta^{rh} - \beta^{uh}$ is an arbitrary difference in which switcher trajectory was selected as base (the data-driven t-stat rule in `initial_values` can pick different bases in the two subsamples), not a barrier.
Removing a wedge that is partly a normalization artifact is not interpretable, so the cross-regime comparison needs a common base.
The within-regime tables are a different object: there each regime is best described by its own data-driven base, which is why the paper should keep both and report the range (line 154).

What the base choice changes economically runs through the steep regime.
Because $\phi^{rh}$ is flat, the rural-hukou extrapolated return $\Delta_{d_N}^{rh}$ is nearly invariant to the base: sliding the anchor along a flat line barely moves the level.
Because $\phi^{uh}$ is steep, the urban-hukou intercept and any uh-based extrapolation move materially with the base.
So the range of the resorting magnitude across base choices is driven almost entirely by the uh side, and the common base is what disciplines that sensitivity into a single reported headline with the regime-specific range around it.

Recommendation on $c$: do not headline $c=1$ as the central magnitude; headline a disciplined $c<1$ value and present $c=1$ as the labeled upper bound.

The four-source decomposition at lines 142--147 is the reason.
At least the cost-of-living term has a definite sign and is first-order in China: urban-hukou workers reside disproportionately in higher-price cities, so a real share of $\beta^{rh} - \beta^{uh}$ is spatial price level, not removable barrier.
Residual selection also plausibly inflates the apparent uh intercept, because the urban-hukou population self-selected into urban work.
Reading the entire gap as institutional ($c=1$) therefore sits at the optimistic end and invites the referee objection that the headline is mostly cost-of-living and selection.
If a spatial price index for the rh and uh residence locations is available, net out a defensible cost-of-living share and headline that $c$, with $c=1$ as the upper bound and the premium-only value as the lower bound; if no index is available, you may headline $c=1$ but only if it is labeled unambiguously as a full-liberalization upper bound, mirroring the general-equilibrium literature's full-liberalization convention (the cited Gai et al. 2.04 log points is such a number), never as a point estimate.

Biggest risk: presenting $c=1$ as the magnitude lets a single contestable assumption carry the headline, and the resorting gain is monotone and steep in $c$, so the number a reader remembers is the most aggressive one in the admissible range.
The sweep figure should also show the marginal-migrant versus residual-never-migrant decomposition shifting with $c$, since at low $c$ the gain is dominated by the residual pool and at $c=1$ the marginal-migrant piece grows, and that composition is part of the economic story.

## Cross-cutting flag: which $\phi$ governs post-removal sorting

This is arguably the single biggest modeling risk in the whole exercise and it cuts across all three decisions, so I raise it separately.
The counterfactual removes the barrier as a pure intercept shift $\beta^{rh} \to \beta^{uh}$, but an intercept shift alone moves the migration level without restoring comparative-advantage-based sorting, because sorting on $\theta$ is governed by the slope $\phi$, not the intercept.
If the flat $\phi^{rh}$ reflects suppressed sorting under the barrier, then post-removal workers should sort on something closer to the steep $\phi^{uh}$, yet a $\beta$-only shift keeps them sorting on the flat $\phi^{rh}$ and the simulated resorting is mostly a uniform level rise, not selection of the high-return tail.
Make the choice of post-removal slope explicit and report the range: $\phi^{rh}$ retained (conservative, level-only response) versus $\phi^{uh}$ adopted (full resorting on the undistorted technology).
This also reconciles with the lower-bound logic at line 126, where the floor is conservative precisely because it averages over the rural-hukou never-migrant distribution instead of selecting its high-return tail; the upper end of the resorting range, using $\phi^{uh}$, is what selects that tail.
The plan to propagate both $\phi^{rh}$ and $\phi^{uh}$ inversion intervals (line 150) is the right vehicle for this range as long as the paper states that the two slopes bracket a modeling choice about the post-removal sorting technology, not merely sampling uncertainty.
