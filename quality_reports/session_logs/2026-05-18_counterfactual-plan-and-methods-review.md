# 2026-05-18---counterfactual plan, methods review, and decision walkthrough

Mode: planning + review (workflow Mode 2 transitioning to Mode 3 prep).
Picked up from [2026-05-13's design memo + HTML session](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-13_counterfactual-experiments-memo-and-html.md), which produced the design memo and HTML overview for the counterfactual experiments.

## Goal

Convert the 2026-05-13 design memo into a detailed implementation plan, run a methods-focused review on it, and reach decisions on the open identification/inference choices before any code is written.

## What got produced

### Detailed implementation plan

[quality_reports/plans/2026-05-18-counterfactual-experiments.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md).
Roughly 400 lines.
Specifies estimands (E1.1-E1.4 misallocation options, E2.5-E2.7 hukou wedge), inversion-CI propagation protocol (Steps P1-P5), cross-cutting infrastructure (P-prog 1-4, Py-mod 1-4, S-do 1-3), output artifacts (T1-T3 tables, F1-F2 figures, D1-D3 diagnostics), validation milestones (V1-V6), risk register (R1-R6), and open issues (O1-O6).

### Two methods reviews

First attempt with the `critic-econometrics` agent at [quality_reports/reviews/2026-05-18_counterfactual-plan-methods-review.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-18_counterfactual-plan-methods-review.md).
User flagged as unsuitable mid-session; the skill `review-econometrics-methods` was the right tool but is not exposed as a subagent_type.

Second pass via the `review-econometrics-methods` skill, which dispatched four parallel lens reviewers (Assumptions, Identification, Estimation/Inference, Literature positioning) plus parent passes on Exposition/notation and Internal consistency.
Synthesis at [docs/reviews/2026-05-18_counterfactual-plan-methods-review-v2.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/reviews/2026-05-18_counterfactual-plan-methods-review-v2.md).
Tally: 4 CRITICAL, 17 MAJOR, 10 MINOR findings; three cross-lens synthesis findings (X1 triple-unmooring of Option 2; X2 inference-hinges-on-LCA; X3 silent parametric choices dominate).

### Consolidated punch list

[docs/reviews/2026-05-18_counterfactual-plan-consolidated.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/reviews/2026-05-18_counterfactual-plan-consolidated.md).
Merges both reviews; preserves the six v1-unique items (intensive-margin labeling for $W_{\text{zero}}$, Option-2-as-$c=1$-of-Option-3 collapse, shape-vs-scale shock confounding, diagnostics D7/D8/D9, four-source decomposition of $\beta^{rh} - \beta^{uh}$, S2-gate sharpening) alongside the v2 cross-lens synthesis.
Sorted into Bucket A (7 user decisions) and Bucket B (mechanical plan + paper updates given Bucket A).

### Decision boxes added inline to the HTML overview

[docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html).
Seven `.decision` boxes (steel-blue palette, distinct from the existing rust/amber/olive content boxes) placed at the section relevant to each question.
Nav strip at the top with severity-color pills (red = critical, amber = major) anchored to each box.
The boxes carry the question, context, three or four options, a "Recommended" marker on the option I suggested, and a source line crediting v1/v2.

## Decisions reached so far

Working through A1-A7 in HTML order.

- **A5** (empty joint CI cells): option 2.
  Report only the parts of the aggregate not dependent on the rejected LCA piece.
  $W_{\text{obs}} - W_{\text{zero}}$ stays; $W_{\text{opt}} - W_{\text{obs}}$ drops when the joint CI is empty.
- **A1** (Option 2 disposition): option 4.
  Collapse Option 2 into the $c = 1$ point of Option 3 envelope.
  No standalone Option 2 magnitude; report Options 1 and 3 only.
  This resolves the triple-unmooring (X1) by recognizing that cross-trajectory variance is an upper bound on $\sigma_\theta$ by the law of total variance.
- **A7** (Experiment 3 status): option 1.
  Defer Route A and Route B entirely.
  Soften paper draft language at `paper/results_counterfactuals.tex` line 105-108 to subjunctive ("would project", "we leave to future work").

## Open at session end

Three boxes still need explanation or decision:

- **A6** (out-of-support diagnostic): explained intuitively in chat; awaiting decision.
  Recommendation: option 1 (add D4 with hull check + extrapolation distance).
- **A4** (hukou wedge: Reading A vs B): explained in chat with concrete numerical example; awaiting decision.
  Recommendation: option 2 (promote continuum to headline column in T3).
- **A2** ($\sigma_\eta$ identification): not yet discussed.
  Now load-bearing because A1's option 4 still needs $\sigma_\eta$ for the within-trajectory dispersion integration at $c = 1$ (and for E2 resort).
  Recommendation: option 1 (bring Route B's $\sigma_\eta$ moment into scope for #1 + #2-resort, without committing to the full Route B welfare exercise).
- **A3** (logistic vs normal): not yet discussed.
  Tied to A2: if A2 picks Route B, the comparison may confound shape with scale.
  Recommendation: option 2 (logistic headline + normal sensitivity).

## How to pick back up next session

1. Finish the walkthrough: get user decisions on A6, A4, A2, A3.
2. Once all seven are decided, mark the HTML decision boxes as resolved (gray out + add a "Decided: option N" tag) so future-Claude reads the final state.
3. Apply Bucket B mechanical updates (Section B1 + B2 of the consolidated punch list):
   - Revise [quality_reports/plans/2026-05-18-counterfactual-experiments.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md) per the seven decisions plus the mechanical findings list.
   - Revise [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) per the decisions plus the intensive-margin / geometric-mean / four-source-decomposition / literature-cite edits in B2.
4. Re-spawn the `review-econometrics-methods` skill on the revised plan + paper draft in fresh context as a verification pass.
5. Only then move to implementation (Mode 2 → Mode 3 → code).

## Continuation: 2026-05-18 (later)

All seven decisions resolved, Bucket B core edits applied.

### Final decisions

- **A1**: collapse Option 2 into the $c = 1$ point of Option 3 envelope.
  No standalone Option 2 magnitude.
  Option 3 reformulated as a direct Gaussian sweep on $\theta_i \mid d_N$ dispersion (no decision-rule construction, no $F_\eta$ dependence).
- **A2**: defer $\sigma_\eta$ identification entirely.
  E1 Option 3 reformulated to not need $\sigma_\eta$.
  E2 resort reports the magnitude as a curve in $\sigma_\eta$ over a justified grid.
- **A3**: both logistic and normal as parallel headline reports.
  At each $\sigma_\eta$ on the E2-resort curve, simulate under both shapes.
- **A4**: Reading A (full intercept gap is institutional) as headline; Reading B continuum kept as appendix sensitivity figure.
  Revisit if the four-source decomposition turns out to drive the magnitude.
- **A5**: report only LCA-independent pieces when joint CI empty.
  $W_{\text{obs}} - W_{\text{zero}}$ stays; $W_{\text{opt}} - W_{\text{obs}}$ drops.
- **A6**: yes, add D4 out-of-support diagnostic.
  First-pass visual diagnostic shipped (see below).
- **A7**: defer Experiment 3 entirely; paper draft softened to subjunctive.

### A6 first-pass result

First-pass visual diagnostic at [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do) plus per-trajectory variant at [explorations/2026-05-18_extrapolation_support_per_trajectory.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_per_trajectory.do).
Memo at [docs/notes/2026-05-18_extrapolation_support_diagnostic.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-18_extrapolation_support_diagnostic.md).
Headline numbers: all three countries have $\hat\mu_{d_N}$ interior to the switcher hull.

| Country | $\hat\mu_{d_N}$ | switcher range | position in hull |
|---------|-----------------|-----------------|------------------|
| CHN     | 10.21           | $[9.82, 11.31]$ | 26% from low     |
| IDN     | 11.83           | $[11.50, 12.83]$| 24% from low     |
| TZA     | 14.57           | $[14.51, 15.35]$| **8% from low** (boundary) |

TZA is the case that warrants a paper-side flag.
Figures at [RP7/output/figures/extrapolation_support_{CHN,IDN,TZA}.{pdf,png}](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/) and `_pertraj_*` variants.

### Bucket B edits applied

**Paper draft** ([paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex)).
Nine edits: intensive-margin label on $W_{\text{zero}}$; "policy conclusion" softened to "consumption-side reading"; trajectory ATE identification chain stated; Option 2 reformulated per A1 (Gaussian $\theta\mid d_N$ as auxiliary, three options collapsed to two); percent labeled as geometric-mean change; trajectory decomposition lifted to a contribution; four-source decomposition of $\beta^{rh} - \beta^{uh}$ stated with the maintained-assumption; logistic and normal reconciled per A3 as parallel reports at each $\sigma_\eta$; Experiment 3 softened to subjunctive per A7.

**Plan** ([quality_reports/plans/2026-05-18-counterfactual-experiments.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-18-counterfactual-experiments.md)).
Added §"Decisions resolved" summary at top.
§Estimands: Option 2 collapsed; Option 3 reformulated; E2 resort updated for $\sigma_\eta$ curve under both shocks.
§Inference protocol: committed to constrained-$J$; fixed wide $\beta$ grid; P5 percent labeled as geometric-mean.
§Risk register: R1 rewritten per A5; R6 reclassified to high-impact-at-implementation.
§Diagnostics: added D4 (out-of-support), D5 ($\sigma_\eta$ grid for E2 resort), D6 ($\sigma_\theta$ pinning sensitivity), D7 (CI width decomposition), D8 (leave-one-trajectory-out), D9 (sign-flip placebo).
§Open issues: closed O1-O6, added O7 (out-of-support flagging threshold).

**HTML overview** ([docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html)).
All seven decision boxes marked decided (steel-blue → green color shift) with chosen option highlighted, "Chosen" tag, and a resolution paragraph summarizing the call.
Nav strip pills now show resolved state.

**TODO** ([docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md)).
Added entry for promoting the A6 density figures to a paper-side appendix or main-text figure.

### Bucket B fully applied (second pass)

All Bucket B leftovers from the first pass are now applied:

**Plan:**

- §Inference protocol P3 rewritten as projection inference (Kaido-Molinari-Stoye 2019 framing) with `find_islands` for non-convex image cases.
- §Inference protocol P4 rewritten as a code-consistency check (set-inclusion invariant, no half-width tolerance).
- §Inference protocol P6 added: $\sigma_\eta$ propagation under A2 deferral; E2-resort reported as curve over $\sigma_\eta$ grid $\{0.1, 0.25, 0.5, 1.0, 2.0\}$.
- §Inference protocol P7 added: E2 resort propagation via common random numbers over the joint $(\phi^{rh}, \beta^{rh})$ CI grid at each $\sigma_\eta$.
- §Cross-cutting infrastructure: Py-mod 1-4 rewritten to reflect constrained-$J$ commit, the no-$F_\eta$ reformulation of the envelope, and CRN handling.
  Py-mod 5 added for hull check (A6).
- §Validation milestones: V2 relabeled as code-consistency; new V2b for external triangulation; V3 / V4 / V5 updated to match the resolved estimand structure; new V7 for out-of-support; V6 expanded to cross-reference the methods-review findings.
- §"Auxiliary assumptions and their testability" subsection added with AA1-AA7 entries.
- Master switch documentation expanded with header-comment requirements and README mention.

**Paper draft:**

- Opening-paragraph cites: Adamopoulos-Restuccia (2022) added as `\cite{adamopoulosMisallocationSelectionProductivity2022}` (already in bib); Hsieh-Klenow tradition mentioned by name in a footnote; Kennan-Walker (2011) cited inline with TODO comment for bib entry; Suri 5.2 connection stated.
- Hukou positioning paragraph added at the top of `sec:hukou-counterfactual` citing Tombe-Zhu (2019) and Fan (2019) inline with TODO comments for bib entries.
- Reporting-unit label already "percent change in geometric-mean consumption" from the first pass; verified.

The HTML overview was separately cleaned up via a background subagent: decision boxes and decision-nav strip removed, decision-related CSS dropped, content sections updated to reflect the resolved design (no Option 2 as standalone, intensive-margin labeling, four-source decomposition statement, subjunctive Experiment 3).

### Next-session pickup

1. Commit the work.
2. (Optional) Re-spawn `review-econometrics-methods` on the revised plan + paper draft in fresh context as a verification pass.
3. Move to implementation: build the audit script `_smoke_counterfactual_inputs.do` first, then Py-mod 1 + Py-mod 2, then the rest of the pipeline in the order specified in §"Sequencing and timeline."
4. Open items for implementation: bib entries for Kennan-Walker, Tombe-Zhu, Fan (paper draft currently uses inline cites with TODO comments).

## Mid-session notes

- The `critic-econometrics` agent and the `review-econometrics-methods` skill are different tools.
  The agent is general-purpose identification/inference review; the skill is a methods-paper rubric that dispatches per-lens subagents.
  For this kind of plan-level methods review, the skill is the right pick.
  The agent's review was not wasted (it surfaced six items the skill missed), but the skill produced the better-structured artifact.
- Both reviews converged on the same four CRITICAL findings, which is a strong signal those findings are real.
- The fixer agents (`fixer-code`, `fixer-writing`) are not the right tool for plan revisions: more than half the consolidated findings require user judgment, not mechanical edits, and the plan lives in `quality_reports/plans/`, not in the kind of file fixers operate on.
