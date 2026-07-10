# Spec --- E2 Version 2: hukou-removal resorting scenario (revision 2)

Date: 2026-06-29.
Mode: Implementation.
Branch: lca-inversion.
Status: revised draft, awaiting approval. CC1 resolved by the empirics; CC2 resolved (report both calibrations). Two non-blocking paper edits drafted for the coauthors. Incorporates the /review-plan pass (three Reds, six Yellows, two Greens): $c$-range primary under Reading A, explicit $G_d$ family with tail sensitivity, local sensitivity panel, probability-weighted realized-effect integral.

Revision 2 responds to the external review ([2026-06-29_e2-v2-external-review-response.md](../reviews/2026-06-29_e2-v2-external-review-response.md)).
It reframes V2 from an "identified magnitude" to a calibrated partial-equilibrium resorting scenario, separates the consumption payoff from the utility cost, normalizes both hukou regimes to a common base, adds a within-trajectory comparative-advantage distribution, and recasts the $\phi^{rh}$ vs $\phi^{uh}$ choice as two named scenarios.
Supersedes revision 1; the decision-history memos remain in `quality_reports/reviews/`.

Builds on: E2 Version 1 (the hukou-wedge lower bound, committed `84ef93c`/`2a872b6`/`5054e4a`).

## Objective

Graduate the resorting paragraph (`paper/results_counterfactuals.tex` lines 139--157) from subjunctive prose into a harness output, framed honestly as a calibrated scenario.
Deliver a partial-equilibrium consumption effect of removing the rural-hukou barrier, computed by running the model's realized-shock decision rule with a calibrated non-pecuniary shock scale and a calibrated within-trajectory comparative-advantage distribution, with sensitivity reported over every calibrated knob.

## Model framing (fixed before requirements)

### Realized-shock decision rule (A1, resolved by the empirics)

The location choice that generates observed switching is the realized-shock rule
$$\text{choose urban in period } t \iff \beta + \phi\theta_i + \eta_{it} > 0, \qquad \eta_{it} = \nu_{it}^U - \nu_{it}^R \sim F(0, \sigma_\eta).$$
This is not a modeling choice; the empirics force it.
Under the alternative reading, where the worker chooses on expected utility and the mean-zero shock integrates out, the index $\beta + \phi\theta_i$ is time-invariant (since $\theta_i$ is time-invariant and covariates cancel under $\gamma^U = \gamma^R$), so every worker is always-urban or always-rural and no one switches.
The data contain switchers, and the GRC is identified only from switchers (main.tex:337), so the expected-utility-with-mean-zero reading contradicts the feature the estimator depends on.
The realized-shock rule is the only formulation consistent with the estimation.
It is also what the paper's own static-equivalence argument (main.tex:282--285) delivers: with i.i.d. shocks and time-invariant productivity there is no option value, so the forward-looking comparison in eq:decision-rule collapses to a sequence of static, realized-shock choices; the $E[\cdot]$ is the dynamic expectation over future shocks, not an integration over the current one.

$\sigma_\eta$ is the scale of the difference shock $\eta$, a model primitive that the GRC estimation never parameterized because it conditions on observed trajectories.
V2 therefore does not change the identifying model; it overlays a parametric form $F$ and a calibrated scale $\sigma_\eta$ on a primitive the estimation left unspecified, used only to compute counterfactual choice probabilities.
Two coauthor-facing items follow, neither blocking: a one-sentence clarification of the realized-shock rule in the model section, and a stated limitation on the $\sigma_\eta$ calibration; both are drafted in [2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md](../reviews/2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md).

### Payoff versus utility cost (A3)

The consumption payoff and the choice index are distinct objects.
The consumption return to urban location for a rural-hukou worker of type $\theta$ is
$$\Delta_{\text{payoff}}^{rh}(\theta) = \beta^{rh} + \phi^{rh}\theta.$$
The hukou barrier is a utility cost $\kappa \geq 0$ that enters the choice index, not the payoff:
$$\text{choose urban} \iff \Delta_{\text{payoff}}^{rh}(\theta) - \kappa + \eta > 0.$$
Removing the barrier sets $\kappa \to 0$; the worker's consumption payoff is unchanged, only the choice changes.

### Common-base normalization (A2)

$\beta^{rh}$ and $\beta^{uh}$ are returns at different regime-specific base types, so the raw gap mixes a normalization artifact with the institutional wedge.
Re-normalize each regime's return schedule to a common reference type by the algebraic transform
$$\tilde\beta^{g} = \beta^{g} + \phi^{g}\,(\mu_{\text{common}} - \mu_{\text{base}^{g}}), \qquad g \in \{rh, uh\},$$
which evaluates regime $g$'s schedule at the common type.
This is an algebraic re-expression of the existing point estimates, not a GRC re-estimation, so it does not touch the within-regime $J$-test.
The institutional cost is then $\kappa = c\,(\tilde\beta^{uh} - \tilde\beta^{rh})$, with $c \in [0,1]$ the fraction of the common-base wedge treated as institutional.

### Within-trajectory comparative-advantage distribution (A4)

The GRC identifies trajectory means $\mu_d$, not individual $\theta_i$.
A single $\theta_d$ per trajectory cannot deliver the high-return tail that motivates V2 (the suppressed-sorting story), because the shock would move a return-independent random fraction.
Instead, model $\theta_i$ within trajectory $d$ as drawn from a calibrated distribution $G_d$ with mean fixed at the trajectory's identified $\bar\theta_d$ (from $\mu_d$) and a within-trajectory dispersion $\sigma_{\theta,d}$ that is calibrated, not identified.
The resorting then selects on $\theta$: when the barrier is removed, the workers who flip are those with the highest choice index, recovering the tail.
Two calibrations of $\sigma_{\theta,d}$ are reported side by side (CC2):
- Calibration 1 (headline first pass): $\sigma_{\theta,d}$ set to the within-trajectory dispersion of individual rural log consumption from the auxiliary OLS.
  This is an upper proxy because that dispersion also contains absolute advantage $\tau_i$ and transitory $\varepsilon_{it}$, so it over-states $\theta$ dispersion and hence tail selection; the resulting magnitude is reported as an upper estimate.
- Calibration 2 (contender): $\sigma_{\theta,d}$ set to the comparative-advantage component alone, stripping out $\tau$ and $\varepsilon$ via the model's variance decomposition.
  Cleaner in principle but leans on the $\theta$/$\tau$ separation being credible.
Both are reported, and $\sigma_{\theta,d}$ is also swept as a sensitivity axis.
The pure agnostic-range option (no anchor) is not used.

### Two named scenarios (A5)

The $\phi^{rh}$ vs $\phi^{uh}$ choice is two different counterfactuals, not a statistical bracket:
- Barrier-only scenario: rural-hukou workers keep their own schedule $(\tilde\beta^{rh}, \phi^{rh})$; only $\kappa$ changes.
  Both the choice index and the payoff use $\phi^{rh}$.
- Regime-convergence scenario: rural-hukou workers are assigned the urban-hukou schedule $(\tilde\beta^{uh}, \phi^{uh})$ after common-base normalization, in both the choice index and the payoff.
These are reported as named modeling alternatives, never as endpoints of one interval.

## Requirements

### MUST

- M1 [CLEAR]. Implement the realized-shock decision rule above, with the difference-shock scale $\sigma_\eta$ entering the choice index.
  Document the realized-shock formulation as a stated extension and flag the coauthor-confirmation item in the prose.
- M2 [CLEAR]. Build the type-I extreme value (logit) shape first, behind an injectable CDF so the normal (probit) shape is a one-line swap.
  Define $\sigma_\eta$ as the standard deviation of the difference shock $\eta$, and match logit and probit at equal variance of $\eta$, not equal scale (A-tier B5/B for issue 16).
- M3 [CLEAR]. Separate the consumption payoff $\Delta_{\text{payoff}}^{g}(\theta)$ from the choice index, with the barrier as a utility cost $\kappa$ in the index only (A3).
- M4 [CLEAR]. Normalize both regimes to a common base via the $\tilde\beta$ transform before forming any cross-regime wedge; set $\kappa = c(\tilde\beta^{uh} - \tilde\beta^{rh})$ (A2).
  No GRC re-estimation.
- M5 [CLEAR]. Model within-trajectory $\theta$ via a calibrated $G_d$ with identified mean $\bar\theta_d$ and calibrated dispersion $\sigma_{\theta,d}$; the resorting integrates the consumption payoff over the $\theta$ that flip (A4).
  Report both calibrations of $\sigma_{\theta,d}$ side by side (consumption-dispersion upper proxy as the headline; the $\tau$/$\varepsilon$-stripped comparative-advantage component as the contender), state each as calibrated, and sweep $\sigma_{\theta,d}$ as a sensitivity axis (CC2).
- M5b [CLEAR]. The $G_d$ distributional family is an explicit maintained assumption, because the magnitude is driven by the tail of $G_d$, not by $\sigma_{\theta,d}$ alone (plan review Red 2).
  Name the family (default Gaussian), justify it, and report headline sensitivity to at least one fatter-tailed alternative at matched variance.
  A quadrature choice (e.g. Gauss-Hermite) presupposes a family and must not be defaulted silently.
- M6 [CLEAR]. Anchor $\sigma_\eta$ by backing it out of an observed moment in the rural-hukou subsample, computed at the person level (not the row level).
  The primary target is the never-migrant share; the switcher share is a pass/fail over-identification check with a pre-specified tolerance, not merely a reported diagnostic.
- M7 [CLEAR]. Verify the $\sigma_\eta$ back-out is well-posed: define the i.i.d. ceiling as the attainable never-share limits at $\sigma_\eta \to 0$ and $\to \infty$ under the exact panel-length mixture; require the target strictly interior; check root uniqueness over the full attainable range and fail on multiple roots unless a pre-specified selection rule is justified (A-tier C4, issues 2/15).
- M8 [CLEAR]. Report the realized partial-equilibrium consumption effect and the remaining unrealized potential as two separate objects; never sum them (issue 7).
  The realized effect is the probability-weighted integral over $G_d$, not an average over a deterministic tail set (plan review Y3):
  $$\text{realized effect} = \sum_d \pi_d \int \Delta(\theta)\,[P_d^{cf}(\theta) - P_d^{base}(\theta)]\,dG_d(\theta), \qquad \text{unrealized potential} = \sum_d \pi_d \int [1 - P_d^{cf}(\theta)]\,\max(\Delta(\theta), 0)\,dG_d(\theta).$$
- M9 [CLEAR]. The realized-effect integral in M8 uses the signed payoff $\Delta(\theta)$, not $\max(0, \Delta(\theta))$: a choice simulation moves some negative-return workers, and the integral nets them automatically (issue 13).
- M10 [CLEAR]. Run both named scenarios (barrier-only and regime-convergence) and report them as distinct labeled objects, not a range (A5).
- M11 [CLEAR]. The primary reported object is the resorting gain across the full $c \in [0,1]$ range, not a $c=1$ point (plan review Red 1).
  $c$ has no data discipline: under Reading A the baseline never-share is fit jointly by $\sigma_\eta$ and $\kappa = c(\tilde\beta^{uh} - \tilde\beta^{rh})$, so a single moment cannot separate barrier from shock, and the gain scales near-monotonically with $c$.
  Lead with the range, state plainly that $c$ indexes an assumption not an estimate, and never headline $c=1$ as a bound.
  Add the monotonicity diagnostic: increasing $c$ weakly raises urban choice for the affected group.
- M12 [CLEAR]. Inference object is a conditional inversion envelope, not a "95% CI": propagate the accepted $(\phi, \beta)$ inversion lattice through the simulation, re-anchoring $\sigma_\eta$ jointly at each accepted point and each $c$ (Reading A, plan review Red 1), and label the result a conditional inversion envelope (issue 8).
  Report separate sensitivity bands over $c$, shape, $\sigma_{\theta,d}$, the $G_d$ family, base normalization, and scenario, plus a local sensitivity panel (normalized elasticity of the headline to $\sigma_\eta$, $\sigma_{\theta,d}$, $c$, $\mu_{\text{common}}$ at the anchor; plan review Red 3) and a $\pm 1$ to $2$ SE perturbation of the calibrated moments (never-share target and $\sigma_{\theta,d}$; plan review Y2).
- M13 [CLEAR]. Emit grid and root diagnostics: count of accepted points, points with valid/no/multiple $\sigma_\eta$ roots, boundary touches in $\phi$ and $\beta$, number of disconnected image islands, and sensitivity to grid refinement (issue 14).
- M14 [CLEAR]. Emit a baseline-fit diagnostic: observed vs modeled urban-choice rate by trajectory, not only the aggregate never-share match; a poor by-trajectory fit blocks headlining V2 (issue 9).
- M15 [CLEAR]. Define the V2 sample explicitly at the person level, with a documented treatment of unbalanced and missing-trajectory workers ($\theta$, $\Delta$, $\pi$, $T_i$), or an explicit balanced-only restriction (issue 10).
  Reuse the existing `prepare_data` path; missing data stays NaN; never regress missing to zero.
- M16 [CLEAR]. Reproducibility: a single Python entry point callable from `12_counterfactuals.do`, a long-format results CSV, a generated LaTeX table, and a golden-baseline self-check, mirroring E1/E2-V1.
  Before regenerating the baseline, run a legacy-subset equality check: filter fresh and baseline to the pre-existing E1/E2-V1 keys, assert near-exact equality on those rows, and assert only new V2 rows are added (issue 12).
  Self-check confirmation runs in pure Python (no Stata lock).
- M17 [CLEAR]. Every number in the table and prose traces to a computed value; nothing hardcoded.
  The table notes disclose every calibrated knob: $\sigma_\eta$, target-share reproduction error, switcher over-ID gap, $c$, CDF shape, $\sigma_{\theta,d}$, base normalization, scenario, and the count of invalid or non-unique roots (issue 17).
- M18 [CLEAR]. The code path is additive: no refactor of `run_cell`, `build_joint_ci_grid`, or any E1 path; E1 and E2-V1 outputs stay byte-identical.

### SHOULD

- S1 [CLEAR]. Generate the probit shape before promoting V2 to the main text, not in a deferred pass, since the logit/probit gap may exceed the inversion width in the targeted tail (issue 18).
- S2 [CLEAR]. Validate the logit back-out against a fine-grid check at the point estimate and assert the anchored $\sigma_\eta$ reproduces the targeted never-share to a stated tolerance.
- S3 [CLEAR]. Surface every calibration caveat ($\sigma_\eta$ and $\sigma_{\theta,d}$ calibrated not identified; $c$ a sensitivity parameter; the two scenarios distinct; the envelope conditional) in the paper prose, not only in code comments.
- S4 [CLEAR]. Keep the V2 code additive with zero E1 drift surface (the V1 design principle).

### MAY

- MAY1 [CLEAR]. Produce the $\sigma_\eta \times c$ and $\sigma_{\theta,d} \times c$ heatmaps for the appendix.
- MAY2 [DEFERRED]. Graduate `counterfactuals.py` + `lca_inversion.py` under `RP7/scripts/` before the ReplicationPackage7 handoff (standing item; out of scope here).

## Out of scope

- The general-equilibrium welfare magnitude; V2 is an explicitly partial-equilibrium consumption-side object.
- IDN/TZA; V2 is CHN-hukou only.
- Any edit to the Overleaf `main.tex`; paper prose edits land in the local `paper/results_counterfactuals.tex`.
- A GRC re-estimation; the common base is reached by the $\tilde\beta$ transform, not re-estimation.

## Coauthor-facing items (neither blocking)

- CC1 (resolved by the empirics). The realized-shock decision rule is forced by the existence of switchers, not a choice; see Model framing A1.
  Two paper edits follow and are drafted in [2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md](../reviews/2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md): a one-sentence clarification of the realized-shock rule in the model section, and the $\sigma_\eta$-calibration limitation in the counterfactual section.
  Flag both to coauthors; neither blocks the build.
- CC2 (resolved: report both). The within-trajectory $\theta$ dispersion is reported under two calibrations (consumption-dispersion upper proxy and the $\tau$/$\varepsilon$-stripped component), per Model framing A4.
  Flag the choice of headline to coauthors.

## Verification plan

- Logit back-out reproduces the targeted person-level never-share at the point estimate (S2); root uniqueness confirmed over the attainable range (M7).
- Baseline-fit diagnostic shows acceptable observed-vs-modeled urban-choice rates by trajectory (M14).
- Legacy-subset equality check green; E1 + E2-V1 rows byte-identical; baseline diff purely additive (M16).
- `12_counterfactuals.do` runs clean via `stata-mp -e`; pure-Python self-check green.
- Hand-check one grid point against a by-hand logit-probability and payoff-integral calculation.
- Both scenarios and both shapes produced; sensitivity bands populated (M10, S1, M12).
- critic-python on the harness diff; critic-writing on the paper prose; verifier on the table compile.
