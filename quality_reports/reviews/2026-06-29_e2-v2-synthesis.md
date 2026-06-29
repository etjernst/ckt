# E2 Version 2 design --- synthesis of theory and econometrics advice

Date: 2026-06-29.
Inputs: [theory memo](2026-06-29_e2-v2-theory-advice.md), [econometrics memo](2026-06-29_e2-v2-econometrics-advice.md).
Purpose: consolidate the two advisors into a single set of decisions to settle before writing the V2 spec.

## Where they agree (settled, no user input needed)

- Build the type-I extreme value (logit) shape first.
  Native McFadden micro-foundation under the i.i.d.-across-locations assumption, migration-literature default, closed-form choice probabilities, analytic inverse CDF makes the $\sigma_\eta$ back-out and its checks trivial, heavier tails avoid underflow at the never-migrant margin.
  Probit is a one-line swap added second.
  Compare the two shapes at equal variance, not equal scale parameter.
- The $\sigma_\eta$ back-out is well-posed.
  The population switching share is strictly monotone in $\sigma_\eta$, so a unique interior root exists as long as the observed share sits below the i.i.d. ceiling $E[1 - 2^{1-T_i}]$.
- $\sigma_\eta$ is calibrated, not identified.
  Both advisors stress this is the dominant caveat: the i.i.d. assumption forces all panel mobility (return migration, miscoding, real persistence) into the scale, which can inflate the magnitude.
  Present $\sigma_\eta$ as the focal point of a reported grid, not as a structural primitive.
- Grid construction: a log-spaced multiplicative band around the anchor is the primary object; the CI-implied range is shown only to document that sampling noise in the anchor is negligible.
- The institutional-fraction sweep $c \in [0,1]$ is a separate axis from $\sigma_\eta$ (a heatmap, not folded into the scale grid).

## Where they diverge (need a call)

### D1. Target moment for the $\sigma_\eta$ back-out

- Theory: target the rural-hukou switcher share; the i.i.d.-over-time assumption makes switching the realized dispersion of $\eta$.
- Econometrics: target the rural-hukou never-migrant share; the counterfactual perturbs the left tail (the never-migrant pool that resorts), so the never-migrant share is the moment the counterfactual actually moves.
- Both independently propose using the other share as an over-identification check.
- Recommendation: never-migrant share as the primary anchor, switcher share as the over-ID check.
  The counterfactual mechanism operates on the never-migrant pool, so disciplining that moment directly is the tighter choice; report sensitivity to the targeting choice.

### D2. Inference: re-anchor $\sigma_\eta$ per draw?

- Econometrics: re-anchor $\sigma_\eta$ at every $(\phi, \beta)$ draw so the model stays data-consistent across the CI; anchor-once is internally inconsistent and belongs in robustness.
- Theory: silent; no objection.
- Recommendation: re-anchor per draw. Adopt the econometrics call.

### D3. Base trajectory headline

- Theory: headline the common re-estimated base; the wedge $\beta^{rh} - \beta^{uh}$ is only economically interpretable on a common normalization, otherwise the wedge mixes a base-normalization difference with the institutional gap.
- Econometrics: headline the regime-specific bases; they are the only choice consistent with the inversion CIs we already have, and re-estimating a common base risks breaking the $J$-test that justified the hukou split in the first place.
- This is the sharpest conflict, and it is a real tension: regime-specific bases give clean CIs but a wedge contaminated by the base difference; a common base gives a clean wedge but requires re-running GRC and risks $J$.
- Recommendation: regime-specific bases as the headline for the first build (clean CIs, no $J$ risk), common base as the robustness range, and check whether the common-base re-estimation breaks $J$ before promoting it.
  Flag the wedge-contamination caveat in the prose.

### D4. The $c$ headline

- Theory: do not headline $c=1$; discipline with cost-of-living and headline a $c<1$ value, with $c=1$ as a labeled upper bound.
- Econometrics: headline $c=1$, keep $c$ as a separate sensitivity axis.
- Recommendation: keep the paper's existing framing --- $c=1$ as the maintained assumption and headline, with the full $c \in [0,1]$ sweep as the sensitivity figure --- but make the prose state plainly that $c=1$ is an upper bound because the gap also absorbs cost-of-living, amenities, and residual selection.
  Minor; defers to existing paper text.

## New fork neither the paper nor the plan had pinned down

### D5. Which slope do resorted workers carry?

The theory advisor's single biggest flag: a $\beta$-only shift raises the migration level but does not restore slope-based sorting.
After the barrier is removed, do the rural-hukou never-migrants who now sort urban carry the flat $\phi^{rh}$ (their estimated regime slope) or the steep $\phi^{uh}$ (the no-barrier regime, if the flat slope was itself a symptom of suppressed sorting)?

- Recommendation: headline $\phi^{rh}$ (the estimated object for that population, the transparent baseline), and bracket with $\phi^{uh}$ as the "barrier removal also restores sorting" alternative.
  Report the pair as a modeling range, not a point.

## Net: what goes into the spec, pending user sign-off

1. Shape: logit first, probit second. (settled)
2. Anchor $\sigma_\eta$ to the never-migrant share, over-ID check on the switcher share. (D1, rec)
3. Re-anchor $\sigma_\eta$ per inference draw. (D2, rec)
4. Regime-specific bases headline, common base as robustness pending a $J$ check. (D3, rec)
5. $c=1$ maintained headline, full sweep as sensitivity, prose flags it as an upper bound. (D4, rec)
6. Report a $\phi^{rh}$-to-$\phi^{uh}$ slope-sorting range. (D5, rec)
