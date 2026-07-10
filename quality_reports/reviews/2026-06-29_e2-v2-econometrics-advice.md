# E2 V2 resorting simulation: econometrics advice on three modeling decisions

Date: 2026-06-29.
Scope: the China hukou resorting-magnitude counterfactual (E2 V2) described in subjunctive at `paper/results_counterfactuals.tex` lines 139--157.
This memo is advice on identification, calibration, and inference, not a code review.

## Setup and notation

Write the regime-specific decision-rule index for worker $i$ as $v_i \equiv \beta + \phi\theta_i$, the systematic part of equation~\eqref{eq:decision-rule}.
The rule chooses urban in period $t$ when $v_i + \eta_{it} > 0$, where $\eta_{it} \equiv \nu_{it}^U - \nu_{it}^R$ is the realized contemporaneous utility-shock difference.
The model's i.i.d.\ assumption makes the realized $\eta_{it}$ the only source of within-worker variation in choices, and the static-equivalence result in `main.tex` (lines 282--284) is what licenses reading the period-$t$ choice off this single static comparison.
V2 must commit to this reading explicitly: the per-period urban probability for a type-$\theta_i$ worker is
$$ p_i(\sigma_\eta) = G\!\left(v_i/\sigma_\eta\right), $$
with $G$ the standardized CDF of $\eta$ (logistic or normal) and $\sigma_\eta$ its scale.
Everything below turns on the fact that the consumption GMM identifies $\beta$ and $\phi$ in consumption units but says nothing about $\sigma_\eta$.

One cross-cutting caution before the three decisions.
The wedge removal is a change in the utility index that drives the choice, but the consumption gain a flipper realizes is the consumption return $\Delta_i = \beta + \phi\theta_i$, which can be negative even when the utility-driven flip is rational.
Keep the choice index and the consumption return as two separate objects in the code; do not let the simulation credit a flip with a positive gain by construction.

## Decision 1: anchoring $\sigma_\eta$ from observed switching

### (a) Well-posedness

The moment is well-posed and generically has a unique interior solution.
Let $s_i(\sigma_\eta) = 1 - p_i^{T_i} - (1-p_i)^{T_i}$ be worker $i$'s probability of being a switcher over the $T_i$ periods you observe them, and $S(\sigma_\eta) = E[s_i]$ the population switcher share.
As $\sigma_\eta \to 0$, choices become deterministic ($p_i \to \mathbf{1}\{v_i>0\}$), every worker is a stayer, and $S \to 0$.
As $\sigma_\eta \to \infty$, $p_i \to G(0) = 1/2$ for all $i$, and $S \to E[1 - 2^{1-T_i}]$.
Because $1 - p^T - (1-p)^T$ is strictly increasing in $p$ on $[0,1/2)$ and strictly decreasing on $(1/2,1]$, and because raising $\sigma_\eta$ moves every $p_i$ monotonically toward $1/2$, each $s_i$ is strictly increasing in $\sigma_\eta$; the aggregate $S(\sigma_\eta)$ is therefore strictly monotone.
A unique root exists iff the observed rural-hukou switcher share lies in $\left(0,\; E[1 - 2^{1-T_i}]\right)$.
The corner case is an observed share above that ceiling, with no finite solution; for CHN ($T \le 4$) the ceiling is near $0.875$, so the corner is unlikely for a switcher-share target but becomes a live risk for any target whose attainable range is narrower.

### (b) Which target moment

Anchor on the never-migrant share within the rural-hukou subsample, $\pi_{d_N}^{rh} = E[(1-p_i)^{T_i}]$, not the switcher share.
The reason is relevance: the counterfactual perturbs the left tail of the choice distribution (currently-always-rural workers near the migration threshold), and $\pi_{d_N}^{rh}$ is exactly the moment that disciplines mass in that tail, so the calibrated $\sigma_\eta$ is pinned where the magnitude is sensitive.
Report the switcher share as an over-identifying cross-check; if the $\sigma_\eta$ that matches the never-migrant share badly misses the switcher share, that is diagnostic of the i.i.d.\ misspecification and should be disclosed, not averaged away.
Do not target the period-by-period transition rate: under i.i.d.\ the model has no genuine state dependence, so its transition rate is mechanically $2\,E[p_i(1-p_i)]$ and will misfit real (persistent) transitions, contaminating $\sigma_\eta$ with the persistence the model omits.
Do not target the full trajectory distribution for the same reason: the i.i.d.\ model can match marginal location shares but not the autocorrelation structure, so fitting the whole distribution forces $\sigma_\eta$ to compromise across moments the model is misspecified for.
Note that $S(\cdot)$ and $\pi_{d_N}^{rh}(\cdot)$ are computed against an assumed distribution of $v_i$ across the subsample; feed in the empirical individual-level rural-consumption-based proxy for $\theta_i$ rather than a parametric $\theta$ distribution, so the tail mass the moment matches is the actual never-migrant mass.

### (c) Sweep grid

Make the multiplicative band the primary sensitivity axis and the CI-implied range a secondary, illustrative line.
$\sigma_\eta$ is a scale parameter, so a log-spaced multiplicative grid is the natural construction: report at $\{0.5, 0.75, 1, 1.5, 2\}\times\hat\sigma_\eta$.
Justify the band width by something defensible rather than round numbers: set it at least as wide as the factor separating the logit-anchored and probit-anchored $\hat\sigma_\eta$, so the grid encodes the shape disagreement (Decision 2) instead of an arbitrary choice.
Also report the CI-implied range obtained by mapping the binomial sampling interval on the target share through the monotone $S^{-1}$; this range will be very narrow (binomial SE near $0.003$), and that is the point: it documents that sampling uncertainty in the anchor is negligible relative to the scale and shape uncertainty, so the headline interval's width must come from the $\phi$ inversion plus the explicit $\sigma_\eta$ and shape sweeps, not from the calibration target.

### (d) Re-anchor each draw, or anchor once

Re-anchor $\sigma_\eta$ at each $(\phi,\beta)$ draw; this is the headline, with anchor-once reported as a robustness line.
Re-anchoring (Option B) solves $\sigma_\eta(\phi,\beta)$ to hold the observed share fixed at every point in the inversion region, so the only thing varying across the CI is the returns geometry; the resulting interval is the clean image of the $(\phi,\beta)$ inversion region through the resorting functional with $\sigma_\eta$ profiled out by a data constraint.
This is the direct analogue of how the existing harness profiles $\beta$ in `grid_md_inversion` and scales E2 V1 by a fixed share, and it keeps the model data-consistent at the CI endpoints.
Anchoring once at $(\hat\phi,\hat\beta)$ and holding $\sigma_\eta$ fixed (Option A) is internally inconsistent: at the CI endpoints the frozen $\sigma_\eta$ no longer reproduces the observed share, so the model is being evaluated off its own calibration target.
The interpretive payoff of choosing B is that the reader can read the CI as returns-parameter uncertainty alone, with choice noise always re-disciplined; reporting A alongside isolates how much of the width is the scale channel (it will be small, which is itself reassuring).

### Biggest risk in Decision 1

$\sigma_\eta$ is not identified by the consumption GMM; it is calibrated off a single choice moment under the i.i.d.\ assumption, which is the model's strongest and least-tested restriction.
If real switching is persistent (moving costs, state dependence), the i.i.d.\ model attributes that persistence to a small $\sigma_\eta$, making choices look more deterministic than they are; that pushes more never-migrants confidently onto the wrong side of a sharp threshold and inflates the resorting magnitude.
The propagated $\phi,\beta$ CI cannot capture this because it conditions on the i.i.d.\ shape, so the headline must be framed as conditional on the i.i.d.\ scale assumption, with the $\sigma_\eta$ sweep carrying the honest sensitivity.

## Decision 2: logit (type-I EV) vs probit (normal), which to build first

Build logit first; add probit as the second shape behind an injectable $G$.

The per-period choice probability is closed-form under both shapes ($\Lambda$ and $\Phi$ are both univariate CDFs), so the user's "closed-form vs simulation" framing is not the deciding factor; the static binary choice needs no Monte Carlo either way.
Logit wins on three operational grounds.
First, its inverse CDF is analytic, $\Lambda^{-1}(p) = \log\!\big(p/(1-p)\big)$, which makes the $\sigma_\eta$ back-out, the $S^{-1}$ map for the CI-implied range, and every sanity check trivial to compute and to audit.
Second, the logistic has heavier tails than the normal, so when the back-out matches a small never-migrant flip mass it does not underflow; $\Phi(v_i/\sigma_\eta)$ goes to zero fast for deeply rural types and can destabilize both the share root-find and the marginal-flip count.
Third, logit is the empirical-migration default the paper already names (line 156), so it is the natural headline, with probit as the Heckman-convention robustness, matching the paper's own framing.
Architecturally, make $G$, $G^{-1}$, and the tail evaluator a single injected object so probit is a one-line swap, and extend the existing golden-snapshot self-check to both shapes.

### Biggest risk in Decision 2

The shape is not innocuous precisely for the extrapolation to never-migrants, because they sit in the tail where logit and probit diverge most.
The magnitude's shape-dependence is therefore largest for the exact subpopulation the counterfactual targets, so reporting both shapes is a core component of the uncertainty, not decoration.
Validate by reporting the implied never-migrant flip count under each shape at the calibrated $\sigma_\eta$; if logit and probit magnitudes differ materially, that gap, not the $\phi$ CI, may be the binding uncertainty and must be presented as such.

## Decision 3: base trajectory, and where the $c$ sweep lives

### Base

Treat the regime-specific bases $\underline{d}_0^{rh}$ and $\underline{d}_0^{uh}$ as the headline; treat a common re-estimated base as a robustness bound, not a co-equal number.
A common base is not a relabeling: $\phi^{rh}$, $\phi^{uh}$, and their inversion CIs ($[0.09,0.13]$ and $[-0.56,0.11]$) were each estimated within-subsample against their own data-driven base, so forcing a common base requires re-running the GRC for at least one regime, which changes the point estimates, the $J$-tests, and the very inversion CIs that V2 is supposed to propagate.
The regime-specific base is the only choice for which the CIs being propagated are the right CIs, so it is the internally consistent headline.
A common base also partially re-pools the two regimes whose separation was the entire point of the hukou split (pooled CHN fails $J$), so it risks breaking $J$ in at least one regime; report it as a sensitivity with that caveat, and refine the current paper text (lines 152--154) so the two are not presented as equal footing.

### The $c \in [0,1]$ wedge sweep

Keep $c$ and $\sigma_\eta$ as separate axes; do not fold them into a single $c/\sigma_\eta$ ratio.
They answer different questions: $c$ is an economic identifying assumption (what fraction of the intercept gap $\beta^{uh}-\beta^{rh}$ is a removable institution versus a real amenity or cost-of-living difference), while $\sigma_\eta$ is a statistical nuisance (choice-noise scale).
They do interact, because the flip mass depends on $c\cdot(\beta^{uh}-\beta^{rh})/\sigma_\eta$, so present the sensitivity as a 2-D heatmap over $(c,\sigma_\eta)$ rather than two independent 1-D sweeps, which would hide the interaction.
The headline sits at $c=1$ (full gap institutional, the paper's maintained assumption, line 147) and the calibrated $\hat\sigma_\eta$; $c=1$ is an upper bound on the institutional reading and should be labeled as such.

### Biggest risk in Decision 3

The magnitude's level is set jointly by the base choice and $c$, and neither is pinned by the data the way $\phi$ is.
The danger is false precision: a tight $\phi$ CI quoted next to a level that the base choice and the $c$ assumption move by more than the CI half-width.
Mitigate by reporting the base-choice range and the $c$ sweep as first-class uncertainty next to the $\phi$ CI, never buried, so the reader sees that the conditioned-on choices, not the propagated CI, dominate the total uncertainty in the level.

## Recommendations at a glance

| Decision | Recommendation | Headline vs robustness |
|---|---|---|
| 1. Anchor $\sigma_\eta$ | Calibrate to the rural-hukou never-migrant share $\pi_{d_N}^{rh}$ (switcher share as over-ID check); re-anchor at each $(\phi,\beta)$ draw | Headline: re-anchored, never-migrant target. Robustness: anchor-once, switcher-share target |
| 1c. Grid | Log-spaced multiplicative band $\{0.5,\dots,2\}\times\hat\sigma_\eta$, width $\ge$ logit-probit anchor gap; CI-implied range as a negligibility check | Multiplicative band is primary |
| 2. Shape | Logit first behind an injectable $G$; probit as the swap | Headline: logit. Robustness: probit |
| 3. Base | Regime-specific bases | Headline: regime-specific. Robustness: common re-estimated base (flag $J$ risk) |
| 3. $c$ | Separate axis from $\sigma_\eta$; 2-D $(c,\sigma_\eta)$ heatmap; headline at $c=1$ | $c=1$ headline, full sweep in appendix |
