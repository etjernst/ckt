# Audit-residue: results_counterfactuals.tex

Date: 2026-06-24.
This skill flags only; it never rewrites. Route accepted flags to fixer-writing.

## Tally

```
Candidates found: 30
RESIDUE: 2  (both via adjudicator overrule)
KEEP (held): 23
KEEP overruled by adjudicator -> RESIDUE: 2  (lines 27, 110)
BORDERLINE (residue-leaning): 4
```

The section is unusually clean for this skill. Nearly every lexical hit on "not"/"rather than"/"never" is a factual negation, a mathematical condition, terminology ("never-migrant", "always-urban"), or a real scope/limitation statement the reader needs. The five BORDERLINE items are the ones worth the author's eye: two contribution-against-the-literature framings, one thrice-repeated inference-method disclaimer, and two future-work closers.

## Findings (document order)

### RESIDUE (confirmed by independent adjudicator)

- Location: line 27 (footnote). Verbatim: "our object differs from a Hsieh-Klenow TFPR-dispersion index in that it is identified from panel switchers under the LCA restriction rather than from cross-sectional marginal-revenue-product dispersion."
  Flavor: false-contrast / path-not-taken.
  Verdict: RESIDUE (KEEP overruled by adjudicator).
  Diagnosis: defines the object by rebutting an HK TFPR framing the paper never adopts; in a returns-to-migration GRC paper the reader does not import the expectation that the object is an HK index. The positive conclusion (identified from panel switchers under LCA) survives without the contrast.
  Suggested fix: state what the object is --- "our misallocation gap is identified from panel switchers under the LCA restriction" --- and drop the "differs from ... rather than ..." contrast, or keep only if the HK index is genuinely the reader's default object here (author's call).

- Location: line 110. Verbatim: "Relative to these exercises, our contribution is a partial-equilibrium consumption-side magnitude disciplined by GRC-identified objects, with a trajectory-level decomposition that the existing literature does not deliver."
  Flavor: anticipated-objection.
  Verdict: RESIDUE (KEEP overruled by adjudicator).
  Diagnosis: self-positioning against the GE structural literature; the "does not deliver" tail is conceded residue and the GE-expectation core is thin. The contribution can be stated directly.
  Suggested fix: "We report a partial-equilibrium consumption-side magnitude disciplined by GRC-identified objects, with a trajectory-level decomposition of where the misallocation lives." Drop "Relative to these exercises" and "that the existing literature does not deliver."

### BORDERLINE (residue-leaning) --- worth the author's eye

- Location: line 76. Verbatim: "This decomposition by panel trajectory is what the existing aggregate-gain literature does not deliver: ..."
  Flavor: anticipated-objection / contribution-against-frame.
  Diagnosis: frames the trajectory decomposition by what other papers do not do. A reader of an aggregate-gain counterfactual does expect a single aggregate number (Bryan et al.), so naming the decomposition as novel is partly legitimate, but the "does not deliver" construction states the contribution as an absence in others' work rather than a positive claim.
  Suggested fix: recast positively --- "Our trajectory-level decomposition shows where the misallocation lives: the never-migrant piece dominates the gap in TZA, the lumped-switcher cell dominates the value of observed migration in IDN."

- Location: line 83. Verbatim: "All three intervals are convex hulls of the joint $(\phi, \beta)$ confidence region propagated through equation~\eqref{eq:misallocation-decomposition}, not asymptotic delta-method intervals."
  Flavor: false-contrast (by repetition).
  Diagnosis: the not-delta-method point is already made at lines 29 and 60. A third assertion after the numbers reads as insistence to a skeptic rather than new information for the reader.
  Suggested fix: drop the "not asymptotic delta-method intervals" clause here; the point is established. Keep the convex-hull description.

- Location: line 158. Verbatim: "We leave this welfare-side extension to future work."
  Flavor: path-not-taken.
  Diagnosis: the canonical future-work closer. Mitigated here because the subsection ("From consumption to welfare") genuinely raises the extension, so the reader is led to expect it; the sentence closes a thread the text itself opened.
  Suggested fix: defensible to keep as a genuine scope close, but the whole paragraph 155--157 describes the extension speculatively; consider compressing 155--158 so the close is shorter.

- Location: line 145. Verbatim: "Identifying the scale $\sigma_\eta$ ... is feasible but is left to ongoing work; for now we report the resorting magnitude as a function of $\sigma_\eta$ on a justified grid ..."
  Flavor: path-not-taken (mitigated).
  Diagnosis: "is left to ongoing work" plus "for now" is future-work residue, but it is doing real work: it explains why the resorting result is reported as a curve in $\sigma_\eta$ rather than a single number. The reader needs that.
  Suggested fix: keep the methodological explanation (curve in $\sigma_\eta$); the "left to ongoing work" framing can stay or compress, author's call.

### KEEP --- factual / legitimate scope (held, re-checked where non-trivial)

These cleared the burden of proof: each corrects a concrete reader expectation or is a factual/mathematical statement, not an argument with a non-reader.

- line 29 ("Inference propagates through the inversion confidence region rather than asymptotic standard errors"): corrects the reader's default expectation of standard errors and says why ($\phi=-1$).
- line 41 ("does not undo extensive-margin migration ... isolates the value of subsequent location switching rather than the value of migration over a lifetime"): corrects a real misreading of "zero migration" as lifetime.
- line 60 ("without requiring delta-method approximations that the boundary at $\phi=-1$ would not support"): same real inference expectation as line 29.
- line 62 ("identifies trajectory-conditional means ... but not the within-trajectory dispersion of $\Delta_i$"): real identification limitation that motivates the envelope.
- line 68 ("We do not report a structural intermediate value ... would integrate the wrong density"): a reader steeped in the model expects the decision rule to discipline the correction; this gives the real reason it cannot ($\hat\phi<0$ implies $\hat\Delta_{d_N}<0$, contradicting the data).
- line 69 ("auxiliary parametric assumption not implied by the GRC ... our floor reading does not require it"): corrects the expectation that the Gaussian $\theta$ is model-implied.
- line 82 ("we do not report a pooled CHN gap because the pooled $J$-test rejects"): a reader expects one CHN number like IDN/TZA; this says why CHN is split.
- line 101 ("driven by the singularity rather than honest uncertainty"): a reader seeing +145% might take it as real uncertainty; this flags it as a pole artifact.
- line 114 ("the LCA restriction is not refuted in either regime"): factual ($J$-test passes within regime).
- line 126 ("a bound rather than a magnitude ... suppressed sorting rather than uniformity"): real distinctions the reader must not conflate.
- line 128 ("delivers a magnitude rather than a bound"): distinguishes the two E2 versions.
- line 151 ("the LCA framework deliberately does not identify on its own"): real limitation for the welfare bridge.
- line 153 ("the consumption-side complement to welfare statements"): tells the reader how to read the number (consumption units, welfare weakly smaller); not a "complement, not competitor" strawman.
- line 155 ("relating residual choice probabilities to amenity proxies ... rather than imputing them from a distributional assumption"): names the extension's method against the parametric alternative; informative.
- Remaining hits (lines 51, 58, 63, 74, 88, 115, 120-121, 125, 135, 138): mathematical conditions, "never-migrant"/"always-urban" terminology, or factual definitions ("the marginal migrant who did not move under hukou"). Grep caught the word, not residue. Held as factual-descriptive.

## Adjudicator note

A fresh-context adjudicator re-checked the five non-trivial KEEPs (lines 27, 68, 101, 110, 151). It UPHELD lines 68, 101, 151 (genuine scope corrections of real reader moves) and OVERRULED lines 27 and 110 to RESIDUE (both rebut framings the reader does not import). The four BORDERLINE items are surfaced for the author rather than auto-resolved.
