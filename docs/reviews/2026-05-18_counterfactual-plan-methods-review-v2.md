# Counterfactual experiments plan: methods review (v2)

**Target:** [quality_reports/plans/2026-05-18-counterfactual-experiments.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).
**Companion documents reviewed:** [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md), [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).
**Reviewer:** methods-paper rubric, four lenses dispatched in parallel (Assumptions & setup, Identification, Estimation & inference, Literature positioning) plus parent passes on Exposition / notation and Internal consistency.
**Scope:** methods review of the plan as a working document, before any implementation begins.

This review is harsh on purpose.
The plan will drive several days of code, and any identification or inference defect that survives into implementation will propagate into the paper.

## Summary tally

| Severity | Count |
|----------|-------|
| CRITICAL | 4     |
| MAJOR    | 17    |
| MINOR    | 10    |

## Priority action list

CRITICAL items block the plan from proceeding without revision.
MAJOR items materially weaken the plan and should be addressed before code is written.

1. **F2**---Option 2 of E1 uses a decision rule the data have rejected to identify the within-$d_N$ distribution.
   Plan does not state what Option 2's number measures when the constructive rule generates the wrong sign of $\Delta_{d_N}$.
2. **F8**---LCA out-of-support extrapolation diagnostic ($\mu_{d_N}$ inside the convex hull of $\{\mu_{\underline{d}} : \underline{d} \in \mathcal{D}_S\}$) is missing from the implementation.
   R6's "low impact at implementation" tag is backwards; the diagnostic is one line of code on objects already in hand.
3. **F12**---Inference protocol leaves constrained-Wald vs constrained-$J$ unresolved.
   Wald is not weak-ID-robust; the plan's motivation for grid inversion was precisely weak ID.
4. **F17**---R1's empty-joint-CI fallback ("report the point estimate with a footnote") reports a counterfactual number under a model the data reject.
   Category error.
5. **F4**---Convex hull of the joint CI as inference for the aggregate lacks a stated smoothness / connectedness condition; near the Möbius pole both fail.
6. **F5**---E2 mapping $\beta^{rh} \to \beta^{uh}$ as "removing the hukou wedge" conflates institutional, price-level, and selection-on-$\tau_i$ sources.
   The plan acknowledges Frisch-style price-level conflation but not the selection or $F_\eta$-distribution-across-regimes channels.
7. **F1**---$\theta_i \sim N(0, \sigma_\theta^2)$ is imported as a headline parametric assumption without flagging it as auxiliary or supplying a non-normal sensitivity.
   Inconsistent with the paper's explicit positioning against Borjas-style joint log-normality.
8. **F3**---$\sigma_\theta$ "pinned" from the cross-trajectory variance of $\mu_{\underline{d}}$ is structurally a between-group variance.
   In the headline unbalanced spec, it is computed across 3 cells $\{d_N, \text{(lumped)}, d_T\}$ and is a structural lower bound on $\text{Var}(\theta_i)$.
   The Option 3 envelope mislabels the directionality.
9. **F11**---E1 estimand 1 silently assumes the GRC-identified $\Delta_{\underline{d}}$ equals the trajectory-conditional mean realized return.
   Defensible under the model's time-invariance assumptions, but the plan does not state the chain.
10. **F13**---Adaptive $\beta$ grid centered at $\hat\beta$ with width set by marginal SE × 6 is self-defeating near the Möbius pole, where the marginal SE itself is uninformative.
11. **F14**---P4's "marginal CI projection check" conflates code-verification with coverage-verification.
   Projection CI is in general weakly wider than profile CI; a $\geq 10\%$ half-width discrepancy is not a bug threshold.
12. **F15**---P5's $\exp(\Delta W) - 1$ "percent" transformation reports change in geometric-mean consumption, not arithmetic-mean consumption.
    The two differ by Jensen; the plan acknowledges this in a footnote but the headline number requires labeling.
13. **F18**---Adaptive Gauss-Hermite is the wrong quadrature backup for the non-smooth $\max(0, \cdot)$ integrand at $\theta^* = -\beta/\phi$.
14. **F19**---E2 resort CI propagation (Py-mod 4) is unspecified.
    Bootstrap-of-bootstraps, Cartesian product of joint grids, or naive Bonferroni? Each has different coverage; Cartesian product is computationally infeasible.
15. **F10**---Cross-piece $J$-test status is not propagated to the headline table.
    CHN pooled rejects; the plan addresses this case but not the implication for TZA/IDN where $p$-values are modest.
16. **F22**---Misallocation strand (Hsieh-Klenow, Adamopoulos-Restuccia, Tombe-Zhu) uncited despite "aggregate misallocation accounting" label.
17. **F24**---Hukou-wedge literature (Tombe-Zhu 2019, Fan 2019) essentially uncited despite E2 sitting directly in that conversation.
18. **F27**---Plan-paper inconsistency: paper draft commits to logistic AND normal as parallel reports (line 95-96), plan §O2 commits to logistic as headline with normal as sensitivity.
19. **F28**---Plan-paper inconsistency: paper draft commits to Suri-Route-A "extension" in present tense (line 105-108), plan defers Experiment 3 entirely.
20. **F6**---No testability discussion of the four new auxiliary assumptions ($\theta_i \sim N$, eq.(6) sorting generates $d_N$, $\sigma_\theta$ identification, full institutional reading of $\beta^{rh} - \beta^{uh}$).
21. **F9**---Suri (2011) cited as Welfare Route A precedent but the closer connection is to Suri's Section 5.2 selection-driven counterfactual returns, which is the immediate LCA-tradition precedent for E1.

## Cross-lens synthesis

Three findings the individual lenses each touched but did not state in their joint form:

**X1. Option 2 is triply unmoored.**
The decision rule that builds the conditional density $f_{\theta \mid d_N}$ has been rejected by the data (F2).
The $\sigma_\theta$ that scales the density is structurally a between-group variance — a lower bound on the population variance, biased toward zero exactly in the direction that suppresses the heterogeneity correction (F3).
The Jensen monotonicity check (D3) catches integration bugs but not either of these issues, so a passing diagnostic gives false reassurance (F6).
The three together mean Option 2's headline number is determined by parametric and procedural choices the plan makes silently, with no implemented test that pushes back.
Recommendation: demote Option 2 from headline to clearly-labeled thought-experiment.
Option 1 and Option 3 envelope (with the directionality re-examined per F3) are the defensible deliverables.

**X2. Inference validity hinges on cross-piece consistency, which is the LCA restriction the $J$-test scrutinizes.**
The joint $(\phi, \beta)$ CI from constrained $J$ has the right coverage *when the LCA restriction holds*.
When it does not, the joint CI is empty, the procedure produces no number, and the plan's fallback (R1) reports a point estimate under the rejected model.
This is one continuous logical chain that Lens 2 (F10 cross-piece consistency, F17 empty-CI handling) and Lens 3 (F12 weak-ID-robust statistic, F17 model-rejection) saw separately.
The unified statement: the inference procedure does not separately handle the case where the model fails; it simply produces an empty CI, and the plan's response there must be silence (or a relaxed-$\alpha$ sensitivity), not a point estimate.

**X3. The headline magnitude is driven more by silent parametric choices than by identified parameters.**
Counting: $\theta_i \sim N$ (F1), logistic vs normal $\nu$ (F1, F27), Jensen vs no-Jensen percent (F15), within-trajectory dispersion $\sigma_\theta$ scaling (F3), full institutional reading of $\beta^{rh} - \beta^{uh}$ (F5), Option 2 decision-rule construction (F2).
Each of these is a parametric or functional-form choice; cumulatively, they determine the headline number more than $(\hat\phi, \hat\beta)$ do.
A reader of the eventual paper section needs this stated.
Recommendation: add a "scope of parametric choices" paragraph to the paper-side draft that lists each auxiliary assumption with the magnitude sensitivity attached.
The Option 3 envelope figure plus a logistic-vs-normal sensitivity figure plus a within-trajectory-variance sensitivity figure are the natural three deliverables.

## Detailed findings

Findings are numbered globally; the lens that surfaced each is named.

### Identification

#### F1: Imported $\theta_i \sim N$ as headline assumption, not flagged as auxiliary

- Severity: MAJOR
- Confidence: HIGH
- Lens: Assumptions & setup
- Problem: Plan §"Estimands" (line 71) and Py-mod 3 specify $\theta_i \sim N(0, \sigma_\theta^2)$.
  The model section imposes no $\theta_i$ distribution.
  The memo (§"Borjas-style benchmark (later TODO)") explicitly says "Our LCA approach deliberately avoids" joint log-normality of $(\theta^U, \theta^R)$, which is equivalent to $\theta_i$ joint normality.
  Importing $\theta_i \sim N$ at headline contradicts the paper's positioning.
- Suggested fix: (i) Flag $\theta_i \sim N$ as auxiliary in plan §"Estimands" and in paper text; (ii) add at least one heavier-tailed and one skewed alternative ($t_5$, log-normal centered) as a sensitivity in Option 2/3; (iii) make explicit that Option 1 floor does not require this assumption.

---

#### F2: Option 2 uses a decision rule the data have rejected to construct $f_{\theta \mid d_N}$

- Severity: CRITICAL
- Confidence: HIGH
- Lens: Identification (and Assumptions & setup)
- Problem: Plan §"Estimands" lines 69-71 derive $f_{\theta \mid d_N}(\theta) \propto f_\theta(\theta) F_\eta(-\beta - \phi\theta)^T$ from eq.(6).
  Under $\hat\phi < 0$ and rational sorting via eq.(6), $d_N$ membership tilts the conditional distribution toward low $\theta$ and implies $E[\Delta_i \mid d_N] < \beta$ (and typically negative when $\beta$ is small).
  The empirical LCA-extrapolated $\hat\Delta_{d_N} > 0$ in all three countries, which is a direct rejection of the rule used to construct the density.
  The memo flags the tension (§"Tension with the decision rule"); the plan inherits the construction without inheriting the resolution.
  Option 2 then does not identify $E[\max(0, \Delta_i) \mid d_N]$ in the world the data live in; it identifies that object in a counterfactual world where eq.(6) holds at the estimated $(\phi, \beta)$ — a world the data rule out.
- Suggested fix: Two clean options.
  (a) Introduce an explicit friction parameter $\kappa$ into the decision rule, identify $\kappa$ from the trajectory-share moment $\pi_{d_N} = E_\theta[F_\eta(-\beta - \phi\theta - \kappa)^T]$, and rebuild the density consistently.
  (b) Demote Option 2 to a transparent thought experiment ("if sorting were governed by eq.(6) at the estimated $(\phi, \beta)$, ...") and acknowledge in plan and paper that this is inconsistent with $\hat\Delta_{d_N} > 0$.
  Add a diagnostic that reports $E[\theta \mid d_N]$ from the constructed density vs the value of $\theta$ at which the LCA line crosses $\hat\Delta_{d_N}$ — a large gap is the smoking gun for misuse.
  Move §R6's classification of this issue from "low impact at implementation" to "high impact at definition."

---

#### F3: $\sigma_\theta$ pinned from cross-trajectory variance is structurally a between-group lower bound

- Severity: MAJOR
- Confidence: HIGH
- Lens: Assumptions & setup
- Problem: Plan §"Estimands" line 71 pins $\sigma_\theta$ via the weighted cross-trajectory variance of $\mu_{\underline{d}}$.
  In the unbalanced headline spec, $\mathcal{D}_S$ is lumped to a single cell, so the variance is over $\{d_N, \text{(lumped)}, d_T\}$ — three points.
  A 3-point between-group variance is a structural lower bound on $\text{Var}(\theta_i)$ by the law of total variance, biased downward by the within-group variance that the unbalanced lumping discards.
  This bias propagates into Option 2 / Option 3 as understated within-trajectory dispersion, biasing the heterogeneity correction toward zero.
  R3 mitigates only by also computing the balanced-sample version; it does not acknowledge the structural bias.
  More awkwardly, the Option 3 envelope parameterizes $\sigma_{\theta \mid d_N} = c \cdot \sigma_\theta$ for $c \in [0, 1]$ and calls $c = 1$ the upper edge — but if $\sigma_\theta$ is itself a lower bound, $c = 1$ is also a lower edge of the actual envelope.
- Suggested fix: (i) State explicitly that the unbalanced 3-cell variance is a between-group variance and a lower bound on $\text{Var}(\theta_i)$; (ii) re-parameterize Option 3 so $c$ scales between the between-group lower bound and an upper bound that uses the balanced-sample within-group variance whenever available; (iii) report the balanced-sample variance as headline pinning whenever it exists, falling back to the unbalanced version only with an explicit warning.

---

#### F4: Convex-hull-of-image as CI lacks a stated smoothness / connectedness condition

- Severity: MAJOR
- Confidence: HIGH
- Lens: Assumptions & setup (also Estimation & inference F16)
- Problem: Step P3 (plan lines 107-110) asserts the convex hull of the aggregate over the accepted joint grid is the inversion CI for the aggregate.
  This is exact only when (a) the aggregate is continuous as a function of $(\phi, \beta)$ on the joint CI region and (b) the joint CI region is connected (or, if disconnected, the disconnected pieces produce an image whose convex hull does not over-cover).
  Near the Möbius pole at $\phi = -1$, (a) fails on any path crossing the pole.
  The plan's edge-case handling (lines 124-127) restricts the aggregate to $d_N + \mathcal{D}_S$ when the CI brushes $-1$, which is sensible but does not address disconnection.
  Additionally, the plan does not state the regularity conditions needed for the joint Wald or constrained $J$ to be valid uniformly over the joint region (full-rank moment Jacobian, bounded efficient weighting).
- Suggested fix: (i) State in P3 the smoothness condition: "convex hull is a valid CI under continuity of the aggregate on the joint CI region and connectedness of that region; if either fails, switch to the union of image intervals on connected components"; (ii) extend D2 to report the number of connected components of the joint grid acceptance set (flood-fill on the boolean lattice); (iii) state the GMM regularity assumptions explicitly.

---

#### F5: E2 mapping $\beta^{rh} \to \beta^{uh}$ conflates institutional, price-level, and selection sources

- Severity: MAJOR
- Confidence: HIGH
- Lens: Assumptions & setup (also Identification F20)
- Problem: Plan §"Estimands" estimand (6) parameterizes "removing the hukou wedge" as the intercept gap $\beta^{rh} - \beta^{uh}$.
  R4 acknowledges Frisch-style price-level conflation but the conflation is wider than R4 admits.
  $\beta^l$ in the consumption equation absorbs (i) period dummies, (ii) average urban-rural consumption gap at the regime level, (iii) selection on absolute advantage $\tau_i$ across regimes, (iv) skill-price differences across regimes that the GRC does not separate from the institutional barrier.
  Mapping $\beta^{rh}$ to $\beta^{uh}$ assumes none of (iii) or (iv).
  The plan does not state this as an assumption.
  Additionally, the plan's headline (O4) commits to Reading A (full wedge); Reading B (continuum) is only a figure, demoted from the table.
- Suggested fix: List in §"Estimands" estimand (6) the identifying assumption: "we assume the rural-hukou-urban-hukou intercept gap is entirely institutional, attributing none of it to selection on $\tau_i$, skill-price differences, or amenity-distribution differences across regimes."
  Promote Reading B (continuum) to a headline column in T3 alongside Reading A, not just a figure.

---

#### F6: No testability discussion of the new auxiliary assumptions

- Severity: MAJOR
- Confidence: MEDIUM
- Lens: Assumptions & setup
- Problem: The plan adds four substantive auxiliary assumptions: $\theta_i \sim N$ (F1), eq.(6) sorting generates $d_N$ membership (F2), $\sigma_\theta$ identified from cross-trajectory variance (F3), full institutional reading of $\beta^{rh} - \beta^{uh}$ (F5).
  The plan's only assumption diagnostic is the Jensen monotonicity check D3, which is necessary but far from sufficient — it catches integration bugs, not assumption failures.
- Suggested fix: Add a "testability of auxiliary assumptions" subsection that lists each assumption, its testable implication if any, and either the implemented test or a written acknowledgement that it is untestable in this design.
  At minimum: (i) skewness of $\theta_i$ via the moments of $\mu_{\underline{d}}$ ranks; (ii) consistency between eq.(6)-implied $E[\theta \mid d_N]$ and the LCA-extrapolated $\hat\Delta_{d_N}$; (iii) overlap of regime-specific switcher distributions.

---

#### F7: "Standard conditions" / unstated regularity in inference protocol

- Severity: MINOR
- Confidence: MEDIUM
- Lens: Assumptions & setup
- Problem: Step P1 refers to "the GMM Wald statistic (or the constrained $J$ at that $(\phi, \beta)$ implied by the LCA restriction)" without committing to which is headline.
  See F12 for the deeper version.

---

#### F8: Out-of-support extrapolation diagnostic missing; R6 misclassification

- Severity: CRITICAL
- Confidence: HIGH
- Lens: Identification
- Problem: §R6 (plan lines 353-358) acknowledges LCA out-of-support extrapolation to $d_N$ as "the deeper identification concern" with the headline E1 magnitude "dominated by the $d_N$ piece."
  R6 then classifies this as "low impact at implementation (does not block code); high at interpretation."
  Backwards.
  The diagnostic is one line of code on objects already in hand: compute the convex hull of switcher $\mu_{\underline{d}}$'s per (country, spec), report whether $\mu_{d_N}$ sits inside or outside, and if outside, report the extrapolation distance.
  Without this, the reader cannot tell whether $\hat\Delta_{d_N}$ is interpolation or extrapolation; the headline magnitude lacks the right caveat.
- Suggested fix: Add to P-prog 1 a per-(country, spec) report of (i) $\mu_{d_N}$ vs $[\min_{\underline{d} \in \mathcal{D}_S} \mu_{\underline{d}}, \max_{\underline{d} \in \mathcal{D}_S} \mu_{\underline{d}}]$ with in-hull / out-of-hull flag and (ii) extrapolation distance $|\mu_{d_N} - \mu_{\underline{d}_0}|$ scaled by switcher-$\mu_{\underline{d}}$ range.
  Surface in T1 footnote.
  Reclassify R6 as high-impact at implementation.

---

#### F9: Suri-Section-5.2 connection to E1 not stated

- Severity: MINOR
- Confidence: MEDIUM
- Lens: Identification (also Literature)
- Problem: Suri (2011) Section 5.2 reports selection-and-comparative-advantage counterfactual returns (ATE, TT, MTE) — the closest precedent for E1's optimal-sort counterfactual within the LCA tradition.
  Memo line 282 acknowledges; paper draft does not.
- Suggested fix: In the paper draft, add a sentence in §sec:misallocation's opening or in line 25's list of related work acknowledging Suri's selection-driven counterfactual returns as the immediate LCA-tradition precedent, with CKT's contribution being the extension to multi-country panels and trajectory-level decomposition.

---

#### F10: Cross-piece $J$-test status not propagated to the headline table

- Severity: MAJOR
- Confidence: MEDIUM
- Lens: Identification (also Estimation & inference)
- Problem: The misallocation aggregate uses $\Delta_{d_N}$ (LCA extrapolation), $\Delta_{d_T}$ (LCA inversion), and $\Delta_{\underline{d}}$ for switchers (non-parametric).
  The cross-piece restriction is exactly what the restricted-GRC $J$-test tests.
  CHN pooled rejects; the plan handles via hukou split (R5).
  But: the plan does not state per-(country, spec) $J$-stat in the audit table, nor propagate it to the headline table T1.
  TZA and IDN pass at conventional levels but with modest $p$-values; readers reading T1 need this context.
- Suggested fix: Add per-(country, spec) $J$-stat and $p$-value rows to the "Identified objects" audit table.
  In T1, footnote countries where the $p$-value is below (say) 0.20 with the caveat "LCA restriction is borderline at this spec; magnitude propagates the borderline."
  Verify D2 reports the minimum $J$ over the joint $(\phi, \beta)$ CI region — already on the lattice.

---

#### F11: E1 estimand 1 silently assumes trajectory ATE equals trajectory-conditional realized return

- Severity: MAJOR
- Confidence: HIGH
- Lens: Identification
- Problem: Plan line 61 writes $W_{\text{obs}} - W_{\text{zero}} = \sum_{\underline{d}} \pi_{\underline{d}} \Delta_{\underline{d}} \bar{D}_{\underline{d}}$ and asserts identification "by the GRC."
  Under $\theta_i$ time-invariant and trajectory pinning the full $D_{it}$ sequence, the trajectory-conditional ATE equals the trajectory-conditional realized-return mean — so the equation is identified.
  But the plan does not state this chain.
  A reader cannot tell whether the aggregate is identified.
- Suggested fix: Add one paragraph in §"Estimands" stating: under A1-A5 and time-invariant $\theta_i$, the GRC identifies $E[\Delta_i \mid \underline{d}]$ for $\underline{d} \in \mathcal{D}_S$; because trajectory pins the full $D_{it}$ sequence, the trajectory-conditional ATE equals the trajectory-conditional realized-return mean, so equation (1) is identified.
  Mirror in `paper/results_counterfactuals.tex` §sec:misallocation.

---

### Estimation & inference

#### F12: Constrained-Wald vs constrained-$J$ unresolved; Wald is not weak-ID-robust

- Severity: CRITICAL
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: Plan lines 95-100 leave the choice between constrained Wald and constrained $J$ unresolved.
  The motivation for grid inversion (Möbius memo) was that Wald-type asymptotics fail near the pole.
  Under weak identification (Stock-Wright 2000; Andrews-Mikusheva 2016, 2024), Wald-based CIs do not attain nominal coverage; $S$-type or $J$-type statistics do.
  The existing `grid_lca_inversion` and `_md_constrained_wald` invert a chi-squared MD statistic that is the constrained-$J$ analog; calling it "Wald" in the plan is sloppy and substantively wrong if the intent is to use a delta-method-implied Wald on $(\phi, \beta)$.
- Suggested fix: Commit explicitly to the constrained-$J$ (continuously-updated GMM objective minimized over nuisance parameters at fixed $(\phi, \beta)$, or the MD analog already implemented).
  State the chi-squared dof: under the LCA restriction at fixed $(\phi, \beta)$, $\text{dof} = |\mathcal{D}_S| - 1$, matching `grid_lca_inversion`.
  Add a sentence citing Stock-Wright (2000), Andrews-Moreira-Stock (2006), or Andrews-Mikusheva (2016) on weak-ID-robust inversion.

---

#### F13: $\beta$ grid centered at point estimate with width set by marginal SE is self-defeating near the pole

- Severity: MAJOR
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: Plan line 100 specifies a 51-point $\beta$ grid "centered at $\hat\beta$ with width set by point-estimate marginal SE times 6, clamped."
  The marginal SE on $\hat\beta$ diverges or becomes meaningless near the pole — the object the inversion was meant to avoid.
  Setting grid width from it can (a) collapse the grid when the SE is small at the point estimate but the joint region is elongated, or (b) inherit the same delta-method failure.
  "Clamped" is undefined.
- Suggested fix: Use a fixed wide $\beta$ grid spanning $[\hat\beta - K, \hat\beta + K]$ where $K$ is chosen to span the relevant economic range (e.g., $\pm 1$ log point), or derive grid bounds by sweeping outward at fixed $\phi = \hat\phi$ until the test rejects, then padding.
  Report grid-saturation diagnostics in D2; flag CIs that touch a grid endpoint as "extends beyond grid" matching the convention used for $\phi$.

---

#### F14: P4 conflates code verification with coverage verification

- Severity: MAJOR
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: Plan lines 112-116 say "the marginal CI obtained by projecting the joint CI should weakly cover the existing marginal CI" and treat $\geq 10\%$ half-width discrepancy as a "propagation bug."
  The cached marginal CI from `grid_delta_never_md_inversion` profiles out the nuisance parameter via a $\min$ over `phi_search_grid`.
  The projection of the joint 2D acceptance region onto $\Delta_{d_N}$ is in general weakly wider than the profile CI on $\Delta_{d_N}$ — these coincide only when the test statistic has no nuisance, which is not the case.
  A failure can be a bug or a legitimate difference between profile and projection inversion.
- Suggested fix: Reframe P4 as a code-consistency check.
  The correct invariant: at every $(\phi, \beta)$ accepted in the joint grid, $\Delta_{d_N}(\phi, \beta) = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$ must lie inside the cached profile CI.
  Halt if any joint-accepted $(\phi, \beta)$ maps outside the cached profile CI.
  Drop the $10\%$ half-width tolerance — there is no a priori reason joint-projection and profile CIs agree within that.

---

#### F15: P5 $\exp(\Delta W) - 1$ is geometric-mean change, mislabeled as percent of aggregate consumption

- Severity: MAJOR
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: The aggregate $W$ is mean log consumption, so $W_{\text{opt}} - W_{\text{obs}}$ is the change in mean log consumption.
  $\exp(W_{\text{opt}} - W_{\text{obs}}) - 1$ is the geometric-mean ratio minus 1, not the arithmetic-mean change.
  The two differ by approximately $\frac{1}{2}(\sigma^2_{\text{opt}} - \sigma^2_{\text{obs}})$.
  The plan briefly acknowledges this at lines 398-400 as a deferred decision; P5 commits to the formula as the headline with no disclaimer.
- Suggested fix: Commit to "change in geometric-mean consumption" as the headline (cleanest given linear-in-logs model) and footnote that aggregate level consumption gains differ by Jensen; or compute both and report the gap.
  Do not silently call the formula "percent of aggregate consumption."

---

#### F16: Convex hull is valid projection inference but the plan over-states its tightness

- Severity: MINOR
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: Plan line 110 says the convex hull "is conservative when the joint CI is non-convex (rare but possible near the Möbius pole)."
  The conservativeness statement is broader: the convex hull weakly enlarges $g(\mathcal{C})$ whenever the image is non-convex in $\mathbb{R}$, i.e., a disjoint union of intervals — exactly what `find_islands` detects.
  Near the pole, $g$ is unbounded and the image can split into a union of intervals; the convex hull can then be materially conservative (worst case $(-\infty, +\infty)$).
- Suggested fix: Apply `find_islands` to $g(\mathcal{C})$ on a fine grid; report a union of intervals when the image is disconnected, matching the convention for $\Delta_{d_T}$.
  State explicitly that this is projection inference in the Kaido-Molinari-Stoye (2019) sense; cite the convex-hull / Bonferroni / direct-test-inversion ranking.

---

#### F17: R1's empty-CI fallback reports a point estimate under a rejected model

- Severity: CRITICAL
- Confidence: HIGH
- Lens: Estimation & inference (also Identification)
- Problem: Plan lines 320-323: if the joint CI is empty, "report the gap at the point estimate with a footnote that the joint CI is empty (meaning the LCA restriction is rejected at the chosen alpha for that (country, spec))."
  An empty grid-inversion CI at level $\alpha$ means the LCA-restricted model is rejected at $\alpha$.
  Reporting "the point estimate" under a rejected model projects an unidentified object onto a model the data say is wrong.
  Readers will read the headline and ignore the footnote.
- Suggested fix: When the joint CI is empty, do not report a counterfactual number for that (country, spec).
  Report "—" or "model rejected at $\alpha = 0.05$" in the table cell.
  If a relaxed-$\alpha$ CI is desired, move to a sensitivity column or appendix with clear disclaimer.
  For CHN pooled (the live example), the rule should be "report regime-by-regime only."

---

#### F18: Adaptive Gauss-Hermite is the wrong quadrature backup for the non-smooth integrand

- Severity: MAJOR
- Confidence: MEDIUM
- Lens: Estimation & inference
- Problem: Plan line 328 proposes adaptive Gauss-Hermite as the fallback for the heterogeneity integral.
  Gauss-Hermite is optimal for smooth $g(\theta) e^{-\theta^2}$ integrands.
  The integrand here has (i) a non-differentiable kink at $\theta^* = -\beta/\phi$ from the $\max(0, \cdot)$, (ii) a CDF-power factor $F_\eta(\cdot)^T$ that becomes peaked as $T$ grows and as $\phi \to -1$, and (iii) a Gaussian density.
  Gauss-Hermite will misbehave at the kink.
- Suggested fix: Replace with domain-split adaptive quadrature: compute $\theta^* = -\beta/\phi$, call `scipy.integrate.quad` on $(-\infty, \theta^*)$ and $(\theta^*, +\infty)$ separately, or pass `points=[theta_star]` to a single call.
  For the CDF-power sharpness as $\phi \to -1$, transform $u = F_\eta(-\beta - \phi\theta)$ so $u^T$ becomes a polynomial in $u \in [0, 1]$.
  If quadrature still fails, importance-sampled Monte Carlo is the right backup, not Gauss-Hermite.

---

#### F19: E2 resort CI propagation (Py-mod 4) is unspecified and likely intractable as written

- Severity: MAJOR
- Confidence: HIGH
- Lens: Estimation & inference
- Problem: Memo line 215 says "Inference propagates the inversion confidence intervals on $\phi^{rh}$ and $\phi^{uh}$ through the simulation."
  Py-mod 4 takes scalar $(\phi^{rh}, \phi^{uh}, \beta^{rh}, \beta^{uh})$ inputs.
  Propagation procedure not specified.
  Bootstrap-of-bootstraps, joint 4D grid, Cartesian product of two joint 2D grids, naive Bonferroni — each has different coverage.
  Cartesian product of two 2D grids is $20{,}451 \times 20{,}451 \approx 4.2 \times 10^8$ before simulation; infeasible.
- Suggested fix: Specify before implementation.
  Defensible options: (a) joint 4D grid at coarser resolution with combined constrained $J$ across regimes; (b) per-regime joint 2D CI, then convex hull of simulated aggregate over the Cartesian product of $\beta^{rh} - \beta^{uh}$ wedges holding other parameters at joint-CI-implied locus (more tractable); (c) bootstrap GMM moments and re-run inversion-plus-simulation per draw (cleanest but most expensive).
  Pick one and document.

---

#### F20: E2 resort assumes $F_\eta^{rh} = F_\eta^{uh}$ implicitly

- Severity: MAJOR
- Confidence: HIGH
- Lens: Identification
- Problem: Plan estimand (6) parameterizes "removing hukou" as $\beta^{rh} \to \beta^{uh}$.
  The identifying assumption is that removing the institutional barrier maps the rural-hukou decision environment to the urban-hukou one — i.e., that the $\nu^U - \nu^R$ distribution is the same across regimes.
  Not stated.
  Equivalent to assuming urban-hukou holders have the same amenity-valuation distribution as rural-hukou holders conditional on $\theta_i$, which is plausibly false.
- Suggested fix: State explicitly: "the E2 resorting counterfactual is identified under the auxiliary assumption that $F_\eta^{rh} = F_\eta^{uh}$ and that $\theta_i$ distributions are comparable across regimes conditional on covariates."
  Note that this is in principle testable via per-regime trajectory share moments; either implement the test or flag it as untestable in current data.

---

#### F21: 10,000 shock draws may undersize the marginal-migrant piece

- Severity: MINOR
- Confidence: MEDIUM
- Lens: Estimation & inference
- Problem: Py-mod 4 specifies 10,000 draws per worker.
  Adequate for mean choice probability; potentially undersized for the marginal-migrant decomposition piece, which by definition concentrates on workers with $\Delta_i$ near zero where Monte Carlo error can dominate.
  Plan does not state whether shock draws are common across grid points (CRN) or fresh per grid point — CRN reduces propagation variance by 1-2 orders of magnitude.
- Suggested fix: Use common random numbers across joint-CI grid points (seed once, reuse the $N \times S$ shock matrix at every $(\phi, \beta)$).
  Re-run with $S = 50{,}000$ at the point estimate to verify the marginal-migrant piece is stable; bump $S$ if it moves by more than 10% of the CI half-width.

---

#### F22: Misallocation strand uncited despite "aggregate misallocation accounting" label

- Severity: MAJOR
- Confidence: HIGH
- Lens: Literature
- Problem: The plan calls E1 "aggregate misallocation accounting" (plan line 15) and the paper draft frames the consumption gap as a misallocation magnitude.
  Hsieh-Klenow (2009, QJE), Restuccia-Rogerson (2008, RED), Adamopoulos-Restuccia (2014, AER), Adamopoulos-Brandt-Leight-Restuccia (2022, ECMA), Tombe-Zhu (2019, AER) are the natural literature touch-points; none is cited.
- Suggested fix: Either (a) add a paragraph positioning E1 against the agricultural-misallocation strand, or (b) soften the label from "misallocation accounting" to "aggregate consumption gap from optimal sort" and drop the misallocation construct.

---

#### F23: Kennan-Walker / dynamic Roy missing from structural positioning

- Severity: MAJOR
- Confidence: HIGH
- Lens: Literature
- Problem: Memo (lines 290-307) identifies Kennan-Walker (2011, ECMA) and Carneiro-Hansen-Heckman / Cunha-Heckman as the natural structural templates; none appears in the paper draft.
  The E2 resorting counterfactual simulates a model decision rule; referees will ask where it sits relative to the dynamic-Roy / structural-migration literature.
- Suggested fix: At minimum, cite Kennan-Walker when introducing the resorting counterfactual.
  Position the simulation as a static, GRC-disciplined cousin of the dynamic-Roy literature.

---

#### F24: Hukou-wedge literature essentially uncited

- Severity: MAJOR
- Confidence: HIGH
- Lens: Literature
- Problem: Tombe-Zhu (2019, AER), Fan (2019, AEJ:Macro), Ngai-Pissarides-Wang (2019), Hao-Sun-Tombe-Zhu (2020) are the natural literature for E2.
  Paper draft (lines 66-96) presents the hukou exercise as if it stands alone.
- Suggested fix: Add a paragraph at the top of §sec:hukou-counterfactual positioning the exercise against the Tombe-Zhu / Fan tradition.
  CKT's contribution: partial-equilibrium consumption-side number disciplined by GRC-identified objects, with trajectory-level decomposition as the distinctive piece.

---

#### F25: Reporting units label needs care to avoid welfare-equivalent-variation confusion

- Severity: MINOR
- Confidence: MEDIUM
- Lens: Literature
- Problem: Bryan-Morten report percent of aggregate output / consumption; Lagakos-Mobarak-Waugh report welfare-equivalent units.
  Paper draft (line 100-104) positions CKT as "consumption-side" complement; unit label should be unambiguous to readers steeped in either convention.
- Suggested fix: Label reported magnitudes "percent of observed aggregate consumption" rather than ambiguous "percent" or "percent gain."
  Footnote distinguishing this from welfare-equivalent variation in Lagakos-Mobarak-Waugh sense.

---

#### F26: Trajectory decomposition is the distinctive piece; underclaimed

- Severity: MINOR
- Confidence: HIGH
- Lens: Literature
- Problem: The $d_N$ / switcher / $d_T$ decomposition is the natural distinctive piece of CKT.
  Bryan-Morten don't have trajectory structure; Lagakos-Mobarak-Waugh report aggregate gains without this slice.
  Paper draft mentions it as a passing design choice; doesn't claim as contribution.
- Suggested fix: Lift the decomposition into the section's opening "features worth flagging up front" as the natural piece the misallocation strand does not deliver.

---

### Internal consistency

#### F27: Plan-paper inconsistency on logistic vs normal shocks

- Severity: MAJOR
- Confidence: HIGH
- Lens: Internal consistency
- Problem: Paper draft lines 95-96 commits to logistic AND normal as parallel reports ("we report results under both...").
  Plan §"Estimands" estimand (6) line 86 commits to "logistic as headline, normal as sensitivity"; §"Open issues" O2 line 378 reaffirms.
  Plan and paper draft disagree on which is the headline.
- Suggested fix: Pick one.
  If the paper convention (both as parallel) is right, update plan §O2 and table T3 columns accordingly.
  If the plan (logistic headline, normal sensitivity) is right, update paper draft to match.

---

#### F28: Plan-paper inconsistency on Experiment 3 status

- Severity: MAJOR
- Confidence: HIGH
- Lens: Internal consistency
- Problem: Paper draft lines 105-108 commits to the Suri-Route-A extension in present tense ("the exercise generalizes the hukou comparison cross-country and pins down what fraction...").
  Plan §"Scope and non-goals" line 22-25 defers Experiment 3 (both Route A and Route B) to a follow-up plan.
- Suggested fix: Update paper draft to match plan: soften line 107 to "A natural extension would..." or "We pursue this welfare extension in ongoing work" (which line 108 already says but is preceded by a present-tense commitment to the extension in line 107).
  Or, if Route A is to be in scope, expand the plan accordingly.

---

#### F29: Plan §R4 vs §O4 reaffirm Reading A headline; paper draft silent

- Severity: MINOR
- Confidence: HIGH
- Lens: Internal consistency
- Problem: Plan §R4 (line 337-344) and §O4 (line 380-382) both say E2 headline is Reading A (full intercept gap is the wedge), with Reading B (continuum) as sensitivity figure.
  Paper draft is silent on which is headline.
- Suggested fix: Add to paper draft §sec:hukou-counterfactual one sentence committing to Reading A as headline, with the continuum figure as sensitivity.
  Or — better, given F5 — promote Reading B to a headline column.

---

#### F30: Plan §"Estimands" labeling (E1.1-E1.4 vs E2.5-E2.7) is awkward

- Severity: MINOR
- Confidence: HIGH
- Lens: Exposition & notation
- Problem: The estimands are numbered globally (1-7) but referred to as "E1 estimand 5" and "E2.5-E2.7" in different places.
  Reader has to translate.
- Suggested fix: Renumber within experiment.
  Use E1.1, E1.2, E1.3 (Options 1, 2, 3) and E1.0 ($W_{\text{obs}} - W_{\text{zero}}$); E2.1 (bound), E2.2 (resort), E2.3 (continuum sensitivity).
  Cosmetic.

---

#### F31: Notation: $\sigma_\eta$ used without explicit equation

- Severity: MINOR
- Confidence: MEDIUM
- Lens: Exposition & notation
- Problem: Plan §"Estimands" line 71 says "$\sigma_\eta$ pinned per E2 Step 4 below" and elsewhere refers to $\sigma_\eta$ as the shock-distribution width.
  Under logistic $F_\eta$, $\sigma_\eta^2 = \pi^2 \sigma^2 / 6$ for scale $\sigma$ — the parameterization is not stated.
  Under normal $F_\eta$, $\sigma_\eta^2$ is the variance directly.
- Suggested fix: Define $\sigma_\eta^2 \equiv \text{Var}(\nu^U - \nu^R)$ in the §"Notation" of the memo or in the plan's §"Estimands."
  Specify the scale parameter for each distribution family.

---

## Positive observations

P1.
The audit script `_smoke_counterfactual_inputs.do` and Milestone V1 enforce that every aggregate-input object trace back to a `.ster` file or panel descriptive before any production run.
Catches silent missing-data bugs (Assumptions & setup lens).

P2.
The Jensen monotonicity check D3 is a sharp diagnostic that catches Option 2 integration bugs at the point estimate — exactly the place they hide (Estimation & inference lens).
(It does not, however, catch the deeper Option 2 problems flagged in F2; see X1.)

P3.
The empty-CI detection plan D2 (fraction of lattice accepted, boundary contour, minimum chi-squared) is the right diagnostic to surface model rejection before propagation (Estimation & inference lens).
Pair with F17's fix.

P4.
Reusing `_md_constrained_wald` rather than building a parallel inversion is the right call; the existing machinery is well-tested and the joint extension is a thin wrapper (Estimation & inference lens).

P5.
The Step P4 marginal-CI-projection sanity-check (reframed per F14) is a genuinely useful internal consistency test that catches a real class of propagation bugs (Assumptions & setup lens).

P6.
R6 correctly identifies LCA out-of-support extrapolation as the deeper concern (even if it misclassifies impact at implementation; see F8).

P7.
The plan's framing of E2 as a bound-and-magnitude pair matches how Bryan-Morten, Lagakos-Mobarak-Waugh, and the Suri-style structural papers report bracketing magnitudes (Literature lens).

P8.
Reporting both logistic and normal shocks for E2 resorting is the right convention; type-I EV is the migration-literature default, normal is the Heckman default (Literature lens; pair with F27 on plan-paper consistency).

P9.
The inversion-CI-based inference protocol is methodologically more honest than the delta-method conventions of most of the cited literature; the paper draft correctly flags this as a distinguishing feature (Literature lens).

P10.
The plan's explicit Jensen monotonicity diagnostic D3 is the right discipline for an optimal-sort counterfactual; cited literature typically omits this (Literature lens).

P11.
Reporting the hukou bound under both regime-specific and common-base conventions correctly acknowledges that the LCA intercept is base-dependent and the bound magnitude moves with base choice — many counterfactual exercises silently fix the base (Identification lens).

P12.
The plan's open-issues list (O1-O6) correctly identifies the major undecided choices and surfaces them for user decision before implementation, which is the right move at this stage.

## Lenses with no significant issues

None.
All six lenses produced findings.

## Lenses not assessed

**Monte Carlo design (Lens 4):**
the plan does not include a Monte Carlo simulation study and does not need one; the counterfactuals are derived from already-estimated parameters and propagate via the inversion CI rather than via a separate simulation study.
A simulation would be valuable for coverage diagnostics on the joint-CI propagation (X2), but is out of scope for this plan.

**Empirical application (Lens 5):**
not applicable; the entire plan is an empirical exercise built on top of the paper's existing estimation.
The "application" is the paper itself.

## Closing note

The plan is at the right stage for this review.
The infrastructure decisions (P-prog 1-4, Py-mod 1-4, S-do 1-3) are clean and the inversion-CI propagation strategy is the right approach in principle.
The substantive concerns concentrate at (i) Option 2's coherence as an identified estimand, (ii) the absence of an out-of-support diagnostic, (iii) the inference-protocol details around weak-ID-robustness and empty-CI handling, and (iv) plan-paper drift on logistic/normal and Experiment 3 status.
All four are addressable before code is written.
