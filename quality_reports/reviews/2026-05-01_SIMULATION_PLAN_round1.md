# Round 1 review: SIMULATION_PLAN.md

**Target:** `C:/git/ckt/explorations/SIMULATION_PLAN.md`
**Date:** 2026-05-01
**Reviewer:** writing-critic (Opus 4.7)
**Document type:** Exploratory planning memo (markdown). Self-described as "Exploratory planning, not an approved implementation plan."

## Context-setting

This file is an internal thinking-through memo, not a manuscript section, slide deck, or referee report.
The voice profile patterns (opening moves, parenthetical asides, "First/Second/Third" enumeration) are clearly being used by the author.
Standards for a memo are slightly more relaxed than for a submission, but the hard rules (American English, em-dash spacing, sentence case, one-sentence-per-line, no bold pseudo-labels) still apply.
Most "claim without evidence" findings would be inappropriate to flag aggressively here because the document is explicitly forward-looking ("the simulation will show..."); I limit those findings to places where a current empirical claim is asserted without a pointer.

## Findings

### CRITICAL

None.
The document compiles as plain markdown, has no broken cross-references that would block use, and makes no identification claims that exceed what the planning frame supports.

### MAJOR

**M1. Bold pseudo-labels used as in-prose subheadings throughout.**
Hard rule. Severity: MAJOR. Confidence: HIGH.
Lines: 19 (`**What this does for CKT is limited.**`), 21, 23, 24, 25, 85, 89, 91, 92, 93, 94, 95, 101, 126, 127, 128, 129, 130, 131, 132, 136, 137, 138, 139, 140, 141, 142, 247, 253, 260, 265, 268, 273, plus numbered list items in §10.
Problem: The manuscript-writing rule is explicit: "No bold subheadings or bold labels in prose. Structure through headings, paragraphs, and transitions."
This file uses bold-as-label aggressively across nearly every section.
~30+ instances; the single largest violation in the document.
Fix: Convert each into either (a) a proper Markdown heading (`####` if appropriate for the nesting), or (b) a topic sentence that opens the paragraph with the claim.

**M2. One-sentence-per-line rule violated throughout.**
Hard rule. Severity: MAJOR. Confidence: HIGH.
Representative lines with multiple sentences on one source line: 19, 23, 25, 35, 68, 72, 85, 95, 101, 121, 122, 137, 141, 146--151, 153, 196, 202, 211, 232, 236.
Problem: Per `manuscript-writing.md`, ".tex and .md files break the source line at every sentence end."
The file consistently packs 2--4 sentences per source line, which makes per-sentence diffs impossible.
Fix: Reflow the entire memo so each sentence ends with a hard line break.
Mechanical but tedious; easiest place to start is each numbered item in §5 (Pitfalls), §6 (Decisions), and §10 (Open questions resolved).

**M3. Notation drift between `\Delta_{\underline d}` and `\Delta_{d_N}` / `\Delta_{d_T}`.**
Hard rule (notation discipline). Severity: MAJOR. Confidence: MEDIUM.
Lines 23, 78, 82, 85, 105, 108, 116, 139.
Problem: The document switches between $\Delta_{\underline d}$ (generic, indexed by trajectory $\underline d$), $\Delta_{d_N}$ (never-movers), and $\Delta_{d_T}$ (always-movers) without defining $d_N$ or $d_T$.
A reader who has not internalized CKT's trajectory indexing will not know whether $d_N = \underline d = (0,\ldots,0)$ and $d_T = (1,\ldots,1)$.
Fix: At first mention (line 23), add a parenthetical: "$\Delta_{d_N}$ (returns for the all-rural trajectory $d_N \equiv (0,\ldots,0)$) and $\Delta_{d_T}$ (returns for the all-urban trajectory $d_T \equiv (1,\ldots,1)$)."

**M4. Claim asserted without forward pointer.**
Hard rule (every claim traces to evidence). Severity: MAJOR. Confidence: LOW.
Line 19 quotes the GRC paper having majority adopters ($p_{11}=0.53$), the opposite of the CKT samples.
The numbers 95.7 / 92.9 / 88.6 (non-switcher shares) appear later in the table at line 62.
The line-19 claim that this is "the opposite" relies on the reader knowing those numbers two pages later.
Fix: Add a forward reference: "the opposite of the CKT samples (89--96% non-switcher mass; see §2.3)."

**M5. Calibration table has placeholder cells.**
Hard rule (every empirical claim traces to a table; here the table itself is the claim and it's empty). Severity: MAJOR. Confidence: HIGH.
Lines 58--67: rows for $\hat\phi$, $\hat\beta$, $\mu_{d_N}$, "Variance of switcher returns" all show "from Table X" / "from descriptive" rather than actual numbers.
Problem: The whole §2.3 calibration is an unresolved bookmark.
For an exploratory memo this is okay if explicitly flagged, but the memo does not flag it.
A reader (including the author in three months) will not know whether the placeholders are deliberate or oversights.
Fix: Either fill the table now, or add an explicit `<!-- TODO: fill from Table 4 of CKT_2026.tex once Python GMM is validated -->` annotation right above the table.

### MINOR

**m1. Em dashes with surrounding spaces.**
Hard rule by manuscript-writing.md, but listed as MINOR per quality-gates.md rubric for .md.
Severity: MINOR. Confidence: HIGH.
Lines: 19, 25, 85, 99, 101, 116, 121, 122, 138, 146, 149, 150, 151, 153, 196, 202.
The triple-dash `---` is rendered correctly in Markdown, but the surrounding spaces (`) --- the`) violate the flush em-dash rule.
Fix: Search-and-replace ` --- ` with `---` across the file.
Spot-check the result for places where the spaces were doing real work; pipe-table cells should keep them.
Note: lines 60--62 use `---` as table separators; those are fine and should not be changed.

**m2. "loads on $\theta_i$" usage hits a voice-profile rule.**
Voice rule. Severity: MINOR. Confidence: HIGH.
Line 72: "MNAR: attrition loads on $\theta_i$ (correlated with comparative advantage)."
The voice profile prohibits factor-analysis verbs like "loads on" outside of factor-model contexts.
There is no factor model here; "$\theta_i$" is unobserved heterogeneity in a Roy-style selection model, not a latent factor with a loading.
Fix: Replace with "MNAR: attrition is correlated with $\theta_i$" or "MNAR: attrition selection depends on $\theta_i$" on line 72.

**m3. Hedging without quantification.**
Preferred default. Severity: MINOR. Confidence: MEDIUM.
Line 76: "probably sufficient for a referee-convincing appendix" — "probably" is unquantified.
Per voice profile, the author normally quantifies ("80% returns", "89 percent") rather than hedging.
Acceptable in a memo but worth flagging.
Fix: Either drop "probably" or replace with a specific basis: "Exercises 1--3 directly answer the three things §1 lists as central; we expect referees to ask for 4 only if Exercise 2 finds power problems against regime heterogeneity."

**m4. AI-tell phrasing risk on line 101.**
Preferred default / voice consistency. Severity: MINOR. Confidence: LOW.
"A Monte Carlo that reproduces the gap *from first principles* turns that interpretation into a decisive argument."
"decisive argument" is on the edge of empty-superlative territory; the voice profile avoids "novel," "groundbreaking," and similar.
"From first principles" is also fluff-adjacent.
Fix: "A Monte Carlo that reproduces the empirical OLS/FE/GRC gap from the calibrated selection mechanism turns the interpretive claim into a quantitative one."

**m5. Italics used for emphasis (`*directly*`, `*from first principles*`, `*under*`, `*near but not at*`, `*estimator*`).**
Preferred default for `.md`. Severity: MINOR. Confidence: MEDIUM.
Lines: 25, 53, 99, 101, 149, 151.
Six instances; on the high side but not abusive.
The italics on `*near but not at*` (line 151) and `*estimator*` (line 149) are doing real semantic work (contrast); the others are decorative.
Fix: Sweep and remove the decorative instances.

**m6. §3 exercise headers use em-dash separator that should be flush.**
Hard rule. Severity: MINOR. Confidence: HIGH.
Line 78: `### Exercise 1 --- Finite-sample properties of $\hat\phi$ and $\hat\Delta_{\underline d}$ at CKT calibration`
Lines 87, 97, 103, 110, 114.
Problem: the literal `' --- '` token has a space on each side.
Should be `Exercise 1---Finite-sample` per the rule.
Fix: Tighten the spaces.

**m7. Voice deviation: §1 opens descriptively rather than gap-first.**
Voice consistency. Severity: MINOR. Confidence: LOW.
Line 10: "## 1. What the GRC simulations already prove, and why CKT needs its own"
Lines 11--12: "The GRC paper's simulations (...) are tightly focused: ..."
The author's voice profile prefers a functional-purpose opening: scoped claim, then narrow to the gap.
The current opening describes the GRC simulations descriptively before pivoting to the CKT gap on line 19.
Fix (optional): A more voice-consistent opening would lead with the gap: "CKT's simulation needs are different from GRC's in three respects: (i) ..., (ii) ..., (iii) ..., and the GRC simulations therefore cannot substitute."

**m8. LaTeX-style cross-reference embedded in markdown.**
Severity: MINOR. Confidence: MEDIUM.
Line 94 has "validates the §\ref{sec:hukou} diagnostic", where `\ref{sec:hukou}` is a LaTeX command embedded in markdown that will not render.
The file already uses `$...$` math environments freely, so LaTeX-flavored markdown is the convention.
Fix: Either leave as-is (consistent with the file's hybrid style) or replace with descriptive text: "validates the hukou-split diagnostic in CKT_2026.tex §sec:hukou."

## Summary of severity counts

- CRITICAL: 0
- MAJOR: 5 (M1 bold labels, M2 one-sentence-per-line, M3 notation drift, M4 forward-pointer, M5 placeholder calibration table)
- MINOR: 8

## Score

Weights: hard rules 60%, preferred defaults 20%, voice consistency 20%.

- **Hard rules (60 pts available).**
The two systemic violations (bold-pseudo-labels at ~30 instances, plus one-sentence-per-line, pervasive) are both hard rules.
Spaced em dashes (~15 instances) are also a hard rule.
Notation drift and the placeholder calibration table are hard-rule MAJORs.
Net hard-rule score: ~30/60.
The document is internally coherent and the math is consistent, but the formatting hygiene is far from manuscript standard.

- **Preferred defaults (20 pts available).**
Active voice is mostly used.
Hedging is mostly quantified.
Filler phrases are rare.
Italic emphasis is moderate.
Net: ~15/20.

- **Voice consistency (20 pts available).**
The author's voice patterns (numbered enumeration, parenthetical asides, quantified claims, scope-then-narrow openings) are mostly present.
The "loads on $\theta_i$" usage on line 72 is a direct hit on a voice rule.
Net: ~15/20.

**Overall: ~60/100.**

Below the 80/100 commit threshold.
No CRITICAL issues, so the document is not blocked on substance, but the formatting violations (bold pseudo-labels, sentence-per-line) are pervasive enough that this should not be circulated as-is.
A focused 30-minute pass on M1 + M2 + m1 would lift the score over 80.

## Recommended order of operations

1. Global search-and-replace for ` --- ` → `---` (fixes m1 and m6 mostly).
2. Reflow paragraphs to one sentence per line (fixes M2). Tedious but mechanical.
3. Convert each `**Label.**` pseudo-heading to either a `####` Markdown heading or a topic-sentence opening (fixes M1). Highest-leverage rewrite.
4. Fill the calibration table at lines 58--67, or annotate as TODO (fixes M5).
5. Define $d_N, d_T$ on first use (fixes M3).
6. Fix "loads on" on line 72 (fixes m2).
7. Sweep italics for unnecessary emphasis (m5).
