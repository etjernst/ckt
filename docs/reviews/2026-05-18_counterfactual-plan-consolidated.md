# Counterfactual plan: consolidated punch list

**Date:** 2026-05-18.
**Sources:** [critic-econometrics review](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-18_counterfactual-plan-methods-review.md) (v1), [review-econometrics-methods six-lens review](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/reviews/2026-05-18_counterfactual-plan-methods-review-v2.md) (v2).
**Target:** [plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md), [paper draft](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).
**Purpose:** single actionable list separating decisions Emilia must make from mechanical updates that follow once decisions are in.
**Convergence note:** the two reviews agree on every CRITICAL finding and most MAJOR ones, which is a strong signal those findings are real.

The list is in two buckets.
Bucket A holds the seven decisions that determine what the deliverable is.
Bucket B holds the mechanical updates to plan and paper draft that follow once Bucket A is decided.

---

## Bucket A: needs user decision

### A1. Option 2 of E1 (heterogeneity-corrected gap)

**Status:** CRITICAL.
**Sources:** v1 C1, v2 F2, v2 X1.

The within-$d_N$ conditional density $f_{\theta \mid d_N}(\theta) \propto f_\theta(\theta) F_\eta(-\beta - \phi\theta)^T$ is built from eq.(6) of the model.
Under $\hat\phi < 0$ and rational sorting via eq.(6), $d_N$ workers should have $\Delta_i < 0$ on average; the empirical $\hat\Delta_{d_N} > 0$ in all three countries is a direct rejection of the rule used to build the density.
Memo flags the tension, plan does not resolve it.

Triple unmooring (v2 X1): rejected decision rule (F2) plus structurally biased $\sigma_\theta$ pinning (A6 below) plus a Jensen monotonicity check that catches integration bugs but not either of these.

**Options for the decision:**

1. Drop Option 2 entirely.
   Ship Option 1 (conservative floor) and Option 3 (envelope over within-trajectory dispersion fraction $c$).
2. Demote Option 2 to a clearly-labeled thought experiment.
   Paper text: "if sorting were governed by eq.(6) at the estimated $(\phi, \beta)$, the gap would be $X\%$---a number incompatible with the empirical $\hat\Delta_{d_N} > 0$."
3. Fix with an explicit friction parameter $\kappa$.
   Identify $\kappa$ from the trajectory share moment $\pi_{d_N} = E_\theta[F_\eta(-\beta - \phi\theta - \kappa)^T]$, rebuild $f_{\theta \mid d_N}$ consistently.
4. Collapse Option 2 into the $c = 1$ point of Option 3 (v1 M2 reframe).
   Recognize that cross-trajectory variance is an upper bound on $\sigma_\theta$ by the law of total variance, so "Option 2 with $\sigma_\theta$ at the cross-trajectory pinning" equals "Option 3 at $c = 1$."
   Report only Options 1 and 3; no standalone Option 2.

Recommendation: option 4 (cleanest reframe; preserves the substance of the within-trajectory correction without claiming an independent Option 2 magnitude).

### A2. $\sigma_\eta$ identification

**Status:** MAJOR.
**Source:** v1 M8.

Option 2 and the E2 resorting simulation both require $\sigma_\eta$, the scale of $\nu^U - \nu^R$.
Plan defers to "E2 Step 4 or sensitivity grid"; there is no E2 Step 4 specified.
Without $\sigma_\eta$ identified, Option 2 is a function of a free parameter; the resort simulation's choice probabilities depend on scale, not just shape.

**Options for the decision:**

1. Bring memo Route B into scope.
   Identify $\sigma_\eta$ by matching the trajectory share moment $\pi_{d_T} = E_\theta[(1 - F_\eta(-\Delta(\theta)))^T]$.
   This sits "in the same machinery as E2 resorting" per the plan's own out-of-scope note.
2. Commit to a sensitivity grid with stated range.
   E.g., $\sigma_\eta \in \{0.1, 0.5, 1.0, 2.0, 5.0\}$ in log-consumption units, justified by the cross-country range of $\Delta_{d_T}$.
   Report the aggregate at each grid point and let the envelope speak.
3. Defer entirely.
   Then drop Option 2 (per A1 option 1) and report E2-resort as "for a stated $\sigma_\eta = X$" placeholder with explicit caveat.

Recommendation: option 1.
Route B's machinery is largely in place from the inversion side; the identification step is one moment condition.
If that's too much scope creep, option 2 is the next-best.

### A3. Logistic vs normal $\nu$ distribution

**Status:** MAJOR.
**Sources:** v2 F27 (plan-paper drift), v1 m3 (shape vs scale confounding).

Paper draft lines 95-96 commits to logistic AND normal as parallel reports.
Plan O2 commits to logistic as headline with normal as sensitivity.
The two documents disagree.

Additionally, if $\sigma_\eta$ is re-identified per family (per A2 option 1), then the logistic-vs-normal comparison confounds shape with scale: under type-I EV, $\sigma_\eta^2 = \pi^2 \sigma^2 / 6$; under normal, $\sigma_\eta^2$ is the variance directly.

**Options for the decision:**

1. Parallel headline reports (paper draft current).
   Two columns in T1 and T3.
   If A2 picks option 1, fix $\sigma_\eta$ across families (shape-only sensitivity) and footnote.
2. Logistic headline plus normal sensitivity (plan current).
   One column in T1 and T3; normal as a robustness row.
   Update paper draft to match.
3. Logistic only.
   Simpler; defensible if the migration literature default is type-I EV (Kennan-Walker, McFadden).

Recommendation: option 2, with the explicit shape-vs-scale framing depending on what A2 decides.
Logistic is the migration literature default; normal as sensitivity is plenty.

### A4. Hukou wedge reading

**Status:** MAJOR.
**Sources:** v2 F5, v1 M7.

Plan parameterizes "removing the hukou wedge" as $\beta^{rh} \to \beta^{uh}$.
Plan O4 commits to Reading A (full intercept gap) as headline, with Reading B (continuum $c$) only in a figure.
$\beta$ in the GRC absorbs four sources: (i) pecuniary urban premium net of cost-of-living, (ii) cost-of-living difference, (iii) compensating differentials for non-pecuniary amenities, (iv) selection bias not absorbed by $\phi\theta_i$ under LCA misspecification (v1 M7 enumeration).
Reading A assumes (ii)-(iv) are equal across regimes.
Not stated.

**Options for the decision:**

1. Keep Reading A as headline.
   Add the four-source decomposition and the maintained-assumption statement to the paper draft.
   Continuum as a figure.
2. Promote Reading B (continuum $c$) to a headline column in T3, with Reading A as one point.
   Force the reader to take a position on what fraction of $\beta^{rh} - \beta^{uh}$ is institutional.
3. Report the intercept difference as a maintained-assumption upper bound on the institutional wedge.
   Drop the resort version entirely as not interpretable without external evidence on (ii)-(iv).

Recommendation: option 2.
Promoting Reading B forces the assumption to be visible; option 1's footnote will be ignored.

### A5. Empty joint CI cells

**Status:** CRITICAL.
**Sources:** v2 F17, v1 M4.

Plan R1 says: if the joint CI is empty, "report the gap at the point estimate with a footnote that the joint CI is empty (meaning the LCA restriction is rejected at the chosen alpha)."
An empty joint CI means the LCA-restricted model is rejected.
Reporting a point estimate under a rejected model with a footnote is a category error; readers read the headline, ignore the footnote.

**Options for the decision:**

1. Drop empty-CI cells from the headline table.
   Use "---" or "model rejected at $\alpha = 0.05$" in the cell.
2. Report only the parts of the aggregate that do not depend on the rejected LCA piece.
   $W_{\text{obs}} - W_{\text{zero}}$ uses non-parametric switcher $\Delta_{\underline{d}}$ and $\Delta_{d_T}$ from inversion; no LCA cross-piece restriction needed.
   $W_{\text{opt}} - W_{\text{obs}}$ uses LCA-extrapolated $\Delta_{d_N}$; report only when the joint CI is non-empty.
3. Report at relaxed $\alpha$ in a sensitivity column with disclaimer.
   E.g., $\alpha = 0.20$ where the CI is non-empty.

Recommendation: option 2.
Distinguishes the identified piece (always reportable) from the LCA-dependent piece (only when LCA holds); the existing CHN-pooled vs hukou-split treatment is consistent with this convention.

### A6. Out-of-support diagnostic

**Status:** CRITICAL.
**Sources:** v2 F8, v1 M6 / C2.

R6 classifies LCA out-of-support extrapolation to $d_N$ as "low impact at implementation, high at interpretation."
Backwards.
The diagnostic is one line of code on objects already in hand: compute the convex hull of switcher $\mu_{\underline{d}}$'s per (country, spec), check whether $\mu_{d_N}$ sits inside, report the extrapolation distance if outside.

**Decision needed:**

Confirm adding D4 (out-of-support diagnostic) as a required output, with two pieces:

1. Hull check: is $\mu_{d_N}$ in $[\min_{\underline{d} \in \mathcal{D}_S} \mu_{\underline{d}}, \max_{\underline{d} \in \mathcal{D}_S} \mu_{\underline{d}}]$ in the unbalanced lumped case, or in the convex hull of $\{\mu_{\underline{d}} : \underline{d} \in \mathcal{D}_S\}$ in the balanced case?
2. Distance metric: $\min_{\underline{d} \in \mathcal{D}_S} |\mu_{d_N} - \mu_{\underline{d}}|$ in units of switcher-$\mu_{\underline{d}}$ range.

Surface in T1 footnote when out-of-hull.
Same for $\mu_{d_T}$.

No alternative options; this is a yes/no.
Recommendation: yes.

### A7. Experiment 3 (welfare bridge) status

**Status:** MAJOR.
**Source:** v2 F28.

Paper draft lines 105-108 commits to Suri-Route-A extension in present tense ("the exercise generalizes the hukou comparison cross-country and pins down what fraction...").
Plan defers Experiment 3 entirely.

**Options for the decision:**

1. Defer entirely (current plan).
   Update paper draft to match: line 107 softens to "A natural extension would project the residual non-pecuniary component on observable correlates of location choice, following the spirit of Suri (2011); we leave this to future work."
2. Commit to Route A (Suri-style observables) as in-scope for this plan.
   Requires expanding the plan: catalog of observables across CFPS, IFLS, TZNPS; per-country probit/logit; integration into the counterfactual aggregates.
   Adds 3-4 days per the memo.
3. Bring Route B (parametric $\sigma_\eta$ via $\pi_{d_T}$ matching) into scope.
   Tied to A2 option 1.
   Adds 2-3 days.

Recommendation: option 1 plus A2 option 1.
Route B is the smaller scope creep and gives Option 2 / E2-resort a defensible $\sigma_\eta$.
Route A is the larger exercise; defer to a follow-up plan.

---

## Bucket B: mechanical updates given Bucket A decisions

These I would apply without further input once A1-A7 are decided.

### B1. Plan revisions

`quality_reports/plans/2026-05-18-counterfactual-experiments.md`.

**Scope and non-goals:**

- Rewrite per A7 (which routes of Experiment 3 are in or out).

**Estimands:**

- Insert paragraph stating the GRC identifies $E[\Delta_i \mid \underline{d}]$ for switchers under A1-A5 plus time-invariance, and trajectory-conditional ATE equals trajectory-conditional realized-return mean because trajectory pins the full $D_{it}$ sequence (v2 F11).
- Flag $\theta_i \sim N(0, \sigma_\theta^2)$ as auxiliary; propose $t_5$ and shifted log-normal sensitivities (v2 F1).
- Restate Option 2 per A1.
- Restate $\sigma_\theta$ pinning as between-group lower bound, not point estimate (v2 F3, v1 M2).
- Reparameterize Option 3 envelope so $c$ scales between the between-group lower bound and the balanced-sample upper bound where available (v2 F3).
- Reframe E2 institutional reading per A4; promote Reading B if A4 picks option 2.
- Renumber estimands within experiment: E1.0, E1.1, E1.3 (skip E1.2 per A1 option 4) and E2.1, E2.2, E2.3 (v2 F30).
- Define $\sigma_\eta \equiv \text{Var}(\nu^U - \nu^R)$; specify scale parameter per family (v2 F31).

**Inference protocol:**

- P1: commit to constrained-$J$, drop "or Wald" (v2 F12, v1 M1).
  Cite Stock-Wright (2000) and Andrews-Mikusheva (2016) for weak-ID-robust inversion.
- P1: replace adaptive $\beta$ grid with fixed wide grid; bounds set by sweeping outward at $\phi = \hat\phi$ until test rejects, then padding (v2 F13).
- P2: state the aggregate functional explicitly; note continuity holds away from the Möbius pole.
- P3: state the smoothness plus connectedness conditions for convex-hull validity (v2 F4, v2 F16).
  Apply `find_islands` to the image $g(\mathcal{C})$; report union of intervals when image is disconnected, matching $\Delta_{d_T}$ convention.
  Identify as projection inference in the Kaido-Molinari-Stoye (2019) sense (v1 M1).
- P4: reframe as code-consistency check (v2 F14, v1 M5).
  Invariant: every joint-accepted $(\phi, \beta)$ must map to a $\Delta_{d_N}$ inside the cached profile CI.
  Drop the 10% half-width tolerance.
- P5: label percent as change in geometric-mean consumption (v2 F15).
  Footnote that arithmetic-mean change differs by Jensen.
- P6 (new): document $\sigma_\eta$ propagation per A2.
- P7 (new): specify E2 resort CI propagation per F19 (joint 4D grid / per-regime joint then Cartesian wedge / bootstrap of simulation).
  Use common random numbers across grid points (v2 F21).

**Risk register:**

- R1: rewrite empty-CI handling per A5.
- R2: replace adaptive Gauss-Hermite with domain-split adaptive quadrature at $\theta^* = -\beta/\phi$; importance-sampled MC as ultimate fallback (v2 F18).
- R4: rewrite per A4; state the maintained assumption that $F_\eta^{rh} = F_\eta^{uh}$ and $\theta_i$ distributions are comparable across regimes (v2 F20).
- R6: reclassify as high-impact at implementation; cross-reference new D4 (per A6).
- Add R7: cross-piece consistency assumption silently maintained for IDN/TZA; the $J$-test does not test extrapolation to $d_N$ (v1 C2).
  Mitigation: D4 plus headline-table footnote when out-of-hull.

**Cross-cutting infrastructure:**

- Py-mod 1 (`build_joint_ci_grid`): commit to constrained-$J$ per P1.
- Py-mod 3 (`integrate_heterogeneity`): swap quadrature per R2.
- Py-mod 4 (`simulate_hukou_resort`): specify CI propagation per A2 and the chosen P7 option; use CRN.
- Add Py-mod 5 (`check_extrapolation_support`): convex hull check plus distance metric per A6.

**Validation milestones:**

- V2: relabel as "code-consistency check, not magnitude validation" (v1 M3).
- Add V2b: external triangulation against urban-rural gap in country descriptives, or Lagakos-Mobarak-Waugh 2023 magnitudes with explicit reconciliation of differences (v1 M3).
- Add V7: out-of-support diagnostic D4 runs cleanly per A6.
- V6 expanded: verify all CRITICAL and MAJOR caveats from this consolidated punch list appear in the paper text or are resolved in code (v1 sequencing).

**Diagnostics:**

- Add D4: out-of-support hull check plus distance metric (A6).
- Add D5: $\sigma_\eta$ grid sensitivity per A2 (v1 D5).
- Add D6: cross-trajectory variance vs balanced-sample variance for $\sigma_\theta$ side by side (v1 D6, v2 F3).
- Add D7: decomposition of inversion-CI width into $\phi$-alone, $\beta$-alone, joint (v1 D7).
- Add D8: leave-one-trajectory-out sensitivity (balanced specs only) (v1 D8).
- Add D9: sign-flip placebo on $\hat\phi$ (v1 D9).
- Add visibility tag in CSV when Option 2 is dropped per R2 (v1 m5); irrelevant if A1 picks option 1 or 4.

**Open issues:**

- Close O1-O6 per the A-decisions.
- Add O7: threshold for out-of-hull reporting (e.g., flag in T1 only when distance exceeds X% of switcher range).

**Sequencing:**

- S2 gate: expand from "back-of-envelope arithmetic match" to "user has approved C1/C2 framing for paper text" (v1 sequencing).
- Add a "what was decided" section at the top of the plan summarizing A1-A7 decisions for future-Claude reference.

**New subsection:**

- "Auxiliary assumptions and their testability" (v2 F6).
  Lists each new assumption beyond CKT's A1-A5: $\theta_i \sim N$, eq.(6) sorting generates $d_N$ membership (or whatever survives A1), $\sigma_\theta$ pinning, full institutional reading of $\beta^{rh} - \beta^{uh}$ (or A4 choice), $F_\eta^{rh} = F_\eta^{uh}$.
  Per assumption: testable implication if any, implemented test or written acknowledgement that it is untestable.

**Master switch documentation:**

- Document `run_counterfactuals` switch in `0_master.do` and surface in ReplicationPackage7/ README (v1 m6).

### B2. Paper draft revisions

`paper/results_counterfactuals.tex`.

**Opening (lines 16-26):**

- Add explicit mention of trajectory decomposition as a contribution (v2 F26, v1 m2).
- Soften line 22 "policy conclusion" to "consumption-side reading" (v2 F8).
- Add Suri 5.2 selection-driven counterfactual returns as the immediate LCA-tradition precedent in line 25's related work list (v2 F9).
- Add cites for the misallocation strand: Hsieh-Klenow (2009), Adamopoulos-Restuccia (2014), Tombe-Zhu (2019) (v2 F22, v1 m2).
- Add cite for Kennan-Walker (2011) as the dynamic-Roy template when introducing the resort counterfactual (v2 F23).

**Misallocation subsection (lines 28-65):**

- Line 31 zero-migration label: clarify that this is "no further migration after initial sort" (intensive margin), not "zero migration ever" (extensive margin); update line 40 "value of observed migration" wording accordingly (v1 m1).
- Line 49 trajectory ATE: state the identification chain (v2 F11).
- Line 50 $\Delta_{d_N}$ identification: cite the LCA extrapolation explicitly.
- Lines 54-60 within-trajectory heterogeneity: flag $\theta_i \sim N$ as auxiliary; restate Option 2 per A1; restate the three-option framing per A1.
- Line 63 percent: label as change in geometric-mean consumption; footnote arithmetic-mean difference (v2 F15).
- Line 64 decomposition framing: promote to "feature worth flagging up front" (v2 F5/F26).

**Hukou subsection (lines 66-96):**

- Add positioning paragraph at the top: Tombe-Zhu (2019), Fan (2019), Hao-Sun-Tombe-Zhu (2020) as the hukou-counterfactual literature; CKT's contribution is the GRC-disciplined consumption-side number with trajectory decomposition (v2 F24).
- Line 79-89: four-source decomposition of $\beta^{rh} - \beta^{uh}$ (pecuniary premium net of cost-of-living, cost-of-living difference, compensating differentials, residual selection); state the maintained assumption (v1 M7, v2 F5).
- Line 87-89: rewrite resort version per A4 (Reading A or B as headline).
- Lines 95-96: reconcile logistic-vs-normal per A3.

**Welfare bridge (lines 98-108):**

- Reconcile Experiment 3 status per A7.
- If A7 picks option 1: soften line 107 to "A natural extension would..." in subjunctive.
- Add caveat that the consumption-side reporting is the marginal contribution beyond what Bryan-Morten and Lagakos-Mobarak-Waugh deliver (v2 F7).

**Reporting unit:**

- Label "percent of observed aggregate consumption" rather than ambiguous "percent" (v2 F25).
- Footnote distinguishing from welfare-equivalent variation in Lagakos-Mobarak-Waugh sense (v2 F25).

### B3. Re-verification

After B1 plus B2 are applied:

1. Re-spawn `review-econometrics-methods` skill on the revised plan plus paper draft, fresh context.
2. Verify each CRITICAL finding (F2/C1, F8/M6, F12/M1, F17/M4) is resolved in plan text or explicitly accepted as a known limitation in paper text.
3. Verify each MAJOR finding is either resolved or documented under "auxiliary assumptions and their testability" subsection.
4. If new MAJOR findings appear, iterate.

---

## What survives this list

These are the pieces of the plan that the two reviews agreed are sound, with no action needed:

- E1 Option 1 (conservative floor) under the maintained assumptions, transparent about what it does and does not assume.
- $W_{\text{obs}} - W_{\text{zero}}$ piece, modulo the intensive-margin labeling fix.
- E2 lower bound (E2.1), defensible under regime-specific base.
- Audit script and Milestone V1: clean discipline.
- Jensen monotonicity diagnostic D3 (catches integration bugs at the point estimate).
- Empty-CI detection D2 (the right place to surface model rejection).
- Reusing `_md_constrained_wald` (well-tested existing machinery).
- The plan's open-issues list correctly identified the major undecided choices and surfaced them.

Most of the building should proceed.
What needs to happen before paper-ready numbers is the seven A-decisions, then the mechanical B-pass.

---

End of consolidated punch list.
