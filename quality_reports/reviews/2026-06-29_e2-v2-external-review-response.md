# Response to the external review of E2 Version 2

Date: 2026-06-29.
Reviewed: the fresh-eyes review at `~/Downloads/e2-v2-resorting-magnitude-review.md` (verdict: "rethink first; do not build as written").
Purpose: triage the 18 issues, separate what forces a redesign from what is a spec edit, flag where the reviewer improved on the plan, and recommend a next step.

## Bottom line

The review is strong and largely correct.
It does not kill V2, but it does mean the current spec should not be built as written.
The gap to a buildable spec is a substantive revision of the *estimand framing*, not a from-scratch redesign: the computation (logit choice probabilities, the $\sigma_\eta$ back-out, the resorting mass, the inversion-image interval) survives almost intact.
What changes is how the object is framed, normalized, and labeled, plus one genuinely reopened modeling question that threatens V2's rationale.

Verified independently against `main.tex`: the i.i.d. shocks $\nu_{it}^l$ are realized objects that generate switching (main.tex:274), so $\sigma_\eta$ is a model primitive, but the GRC estimation conditions on observed trajectories and never parameterizes the choice model, so $\sigma_\eta$ is nowhere in the estimated model.
The reviewer's framing is right: V2 is a calibrated random-utility extension consistent with the model's utility layer, not an implication of the estimation.

## Tier A --- blocking, needs a decision (and some need coauthors)

### A1. Decision rule: realized shock vs expected utility (review issue 1)

The paper writes the rule as $E[\nu^U - \nu^R]$ (expected-utility form), yet the realized switching that V2 simulates is driven by the realized period shock $\eta_{it} = \nu_{it}^U - \nu_{it}^R$.
The model permits this (the shocks are realized and generate switching), so V2 is not "a different model" --- but the notation must be made explicit and the choice process stated as $\text{urban iff } \beta + \phi\theta_i + \eta_{it} > 0$, $\eta_{it} \sim F(0, \sigma_\eta)$.
This is partly a coauthor question: confirm the intended choice process and whether the paper text should state the realized-shock rule.
My read: the realized-shock interpretation is consistent with the model; the fix is explicit notation plus a calibrated-extension label, not a redesign.

### A2. Common-base normalization (review issues 3, 5-fix)

The reviewer rejects my "regime-specific bases headline" recommendation: $\beta^{rh}$ and $\beta^{uh}$ are returns at *different* base types, so the wedge $\beta^{rh} - \beta^{uh}$ mixes a normalization artifact with the institutional gap.
Crucially, the reviewer offers a fix neither advisor proposed: an *algebraic* re-normalization to a common reference type,
$$\tilde\beta^g = \beta^g + \phi^g(\mu_{\text{common}} - \mu_{\text{base}^g}),$$
which evaluates each regime's return schedule at a common type.
This is NOT a re-estimation, so it sidesteps the econometrics advisor's objection (re-running GRC risks the $J$-test) entirely.
Recommendation: flip to common-base normalization via the $\tilde\beta$ transform.
It resolves the D3 tension better than either advisor, requires no GRC re-run, and makes the wedge interpretable.

### A3. Payoff vs utility-cost separation (review issue 4)

$\beta$ currently does double duty: the consumption payoff and the choice-utility index.
A hukou barrier should enter the choice index as a cost $\kappa$, not as a shift in the consumption-return intercept.
The clean estimand: consumption payoff $\Delta_{\text{payoff}}^{rh}(\theta) = \beta^{rh} + \phi^{rh}\theta$ and choice index $I^{rh}(\theta) = \Delta_{\text{payoff}}^{rh}(\theta) - \kappa + \eta$, with $\kappa$ a stated function of the common-base wedge and $c$.
If that mapping cannot be defended, $c=1$ is "an interpolation between estimated intercept schedules", not "full hukou removal".
Recommendation: rewrite the estimand with separate payoff and cost objects before coding.
This is the heart of the "rethink" and is doable in the spec, not the code.

### A4. Trajectory-level type may not deliver V2's reason for existing (review issue 6, reopens OQ1)

This is the most consequential reopened question.
With one $\theta_d$ per trajectory and an i.i.d. shock independent of the return, V2 moves a *random fraction* of a representative never-migrant type; there is no within-never-migrant high-return tail to select.
But V2's whole rationale (vs the V1 bound) was that optimal sorting selects the high-return tail, so the magnitude can exceed the bound.
The trajectory-level representation I recommended for OQ1 does not recover that tail, so V2-as-designed would not deliver the object the prose motivates.
Options: (a) narrow the claim and label it a "representative-trajectory calibrated resorting scenario" (honest but weaker), or (b) introduce an explicit within-trajectory $\theta$ distribution (recovers the tail, but is an extra calibration needing its own sensitivity, not GRC-identified).
Recommendation: this needs the user's call, and likely a coauthor view, because it determines whether V2 is worth building at all in trajectory-level form.

### A5. Two named scenarios, not a slope "range" (review issue 5)

$\phi^{rh}$ and $\phi^{uh}$ are two different counterfactuals (barrier-only vs regime-convergence), not endpoints of one identified object; presenting them as a "range" or CI is misleading.
Recommendation: adopt the reviewer's split into a "barrier-only scenario" $(\beta^{rh}, \phi^{rh})$ with only $\kappa$ changing, and a "regime-convergence scenario" assigning $(\tilde\beta^{uh}, \phi^{uh})$ after common-base normalization.
Report as named modeling alternatives.
This aligns with the theory advisor's "report as a modeling range, not a point" but sharpens it.

## Tier B --- accept and incorporate (spec edits, not redesigns)

- B1 (issue 7): report the realized partial-equilibrium effect and the remaining unrealized potential as two separate objects; never sum them.
- B2 (issue 8): do not label the propagated interval a "95% CI"; call it a conditional inversion envelope and add explicit sensitivity bands over $c$, shape, base, and scenario.
- B3 (issue 11): report $c$ as a sensitivity parameter, not a proven upper bound; add the sign/monotonicity diagnostic that increasing $c$ weakly raises urban choice for the affected group.
- B4 (issue 13): for marginal movers use $\Delta_d$, not $\max(0, \Delta_d)$ --- V2 is a choice simulation, so shock-induced movers with negative returns must count against the realized gain. (The E1 $\max(0,\cdot)$ is correct for E1's optimum exercise but wrong here.)
- B5 (issue 16): define $\sigma_\eta$ as the scale of the *difference* shock $\eta = \nu^U - \nu^R$, and match logit/probit at equal variance of $\eta$.
- B6 (issue 15): formalize the i.i.d. ceiling as the attainable never-share limits at $\sigma_\eta \to 0$ and $\to \infty$ under the exact panel-length mixture; require the target strictly inside.
- B7 (issue 17): the table notes disclose every calibrated knob ($\sigma_\eta$, target-share reproduction error, switcher gap, $c$, shape, base, scenario, count of invalid/non-unique roots).
- B8 (issue 18): generate the probit comparison before promotion if V2 is headlined, not deferred (drop MAY2's "later pass").

## Tier C --- implementation hardening (the reviewer improved the plan)

- C1 (issue 12): add a legacy-subset equality check BEFORE regenerating the golden baseline --- filter fresh and baseline to the pre-existing E1/E2-V1 keys and assert near-exact equality on those rows, then assert only new V2 rows are added.
  My plan's Step 5 relied on eyeballing the additive diff; this is a real gap the reviewer caught.
- C2 (issue 10): compute never-migrant and switcher shares at the person level, not the row level, and define the unbalanced/missing-trajectory treatment explicitly (a named unbalanced type with documented $\theta$, $\Delta$, $\pi$, $T_i$, or an explicit balanced-only restriction).
- C3 (issue 9): add a baseline-fit diagnostic table (observed vs modeled urban-choice rate by trajectory), not just the aggregate never-share match; if the by-trajectory fit is poor, do not headline V2.
- C4 (issues 2, 14): treat $\sigma_\eta$ as a calibration with full root diagnostics --- attainable-range check, uniqueness check, fail (or a pre-specified selection rule) on multiple roots, and grid diagnostics (accepted points, points with valid/no/multiple roots, boundary touches, image islands, refinement sensitivity).

## Where I would push back on the review

- The "rethink first" verdict reads as more dire than the actual remedy.
  Most of Tier B and all of Tier C are spec/code edits; the genuine redesign is confined to A1--A5, and even those are estimand-framing changes, not a new method.
  The reviewer bundles labeling fixes under the same dramatic banner as the conceptual issues.
- Issue 1 slightly overstates the gap: the model *does* contain realized shocks generating switching, so V2 is a calibrated extension of the existing utility layer, not "a different model". The fix is explicit notation, not abandoning the approach.
- The non-monotonicity worry (issue 2) is real but bounded: with $\phi^{rh}$ flat and a single targeted never-migrant trajectory, mixed-sign indices across many types are less of a threat than in the general case; still worth the uniqueness check, but unlikely to be the binding problem.

## Recommended next step

1. Decide A4 first (within-trajectory $\theta$): it determines whether V2 is worth building in trajectory-level form, and it likely needs a coauthor view.
2. Confirm A1 (realized-shock rule) with coauthors, since it touches the paper's stated model.
3. If A4 and A1 land in favor of proceeding, revise the spec to a "calibrated partial-equilibrium resorting scenario" framing that folds in A2, A3, A5 and all of Tier B/C, then re-review the revised spec before coding.
4. Do not write code against the current spec.
