# Writing review: `paper/unbalanced_proposition.tex`

**File:** `paper/unbalanced_proposition.tex` (154 lines)
**Parent:** `paper/main.tex:925` (section "Consistency of the pooled estimator")
**Reviewer:** writing-critic agent
**Date:** 2026-04-22
**Score:** 82/100 --- commit-ready but not PR-ready.

---

## CRITICAL

None. The proposition, assumption, and proof structure are coherent; nothing blocks readiness on logical or identification grounds.

---

## MAJOR

### 1. `paper/unbalanced_proposition.tex:92` --- British spelling (hard rule) --- HIGH

"residualised" is British. Replace with "residualized". American spelling is a hard rule.

Fix: `then fitting the residuals to the residualized $W_1$`.

### 2. `paper/unbalanced_proposition.tex:131,133,149` --- Terminology inconsistency with main.tex (hard rule) --- HIGH

This file writes "mis-specification" and "mis-specified" (hyphenated). `main.tex:741,754` uses "misspecification" (unhyphenated). Pick one; the main manuscript's unhyphenated form is the established convention.

Fix: `mis-specification` $\to$ `misspecification`; `mis-specified` $\to$ `misspecified`.

### 3. `paper/unbalanced_proposition.tex:70-73` --- Proof opening contradicts the proof structure --- HIGH

The opening sentence says "The argument has two steps," but the proof then has three labeled steps (Step 1 orthogonality, Step 2 consistency, Step 3 efficiency). A referee will catch this immediately.

Fix: "The argument has three steps: an orthogonality step that isolates the contribution of balanced observers to $\{(\mu_{\underline d},\Delta_{\underline d})\}$, a consistency step for the covariate and nuisance parameters, and an efficiency step."

### 4. `paper/unbalanced_proposition.tex:75,95,109` --- Scattered `\emph{}` as pseudo-headings for proof steps --- HIGH

`\emph{Step 1 (orthogonality).}`, `\emph{Step 2 ...}`, `\emph{Step 3 ...}` act as bold/italic labels embedded in prose. The global rule forbids `\emph{}` scattered through academic writing and forbids bold labels/pseudo-headings. If step labels are retained for navigability, use `\textit{Step 1.}` consistently; alternatively, introduce each step with a topic sentence ("The orthogonality step establishes...").

### 5. `paper/unbalanced_proposition.tex:85-89` --- Overstated orthogonality claim --- MEDIUM

"The design matrix therefore block-separates: the balanced regressors $W_1$ ... are orthogonal in the sample to the unbalanced controls $W_2$." The zero-interaction step shows $W_1 \perp W_2$ in sample, but FWL applied cleanly also requires partialling out $x_{it}$, which is not orthogonal to $W_1$. The proof acknowledges this ("partialling out $W_2$ and $x_{it}$") but "block-separates" overstates the structural claim.

Suggested: "The design matrix partitions: the balanced regressors $W_1$ are orthogonal in the sample to the unbalanced controls $W_2$, though not to $x_{it}$."

### 6. `paper/unbalanced_proposition.tex:131-136` --- Robustness claim asserted without derivation --- MEDIUM

"the balanced-panel estimates are robust to substantially stronger forms of mis-specification for the unbalanced stratum than Assumption~\ref{ass:mar} requires: even if attrition were non-ignorable on the unbalanced subsample, the bias would operate only through $\hat\gamma$..." This is a substantive claim about bias propagation that the proof does not establish (the proof assumes MAR throughout). Either sketch the argument or weaken to "suggests" and defer to a footnote.

---

## MINOR

### 7. `paper/unbalanced_proposition.tex:12-14` --- Claim without anchor --- MEDIUM

"between $88.6\%$ and $95.7\%$ of individuals are observed in strictly fewer than $T_c$ waves." No table reference. Add `(Table~\ref{...})`.

### 8. `paper/unbalanced_proposition.tex:16-17` --- Passive voice --- LOW

"a trajectory label $\underline d_i$ is defined only for individuals..." Active alternative: "We define a trajectory label $\underline d_i$ only for individuals observed in all $T_c$ waves; unbalanced observers receive no trajectory label."

### 9. `paper/unbalanced_proposition.tex:51-55` --- Hedging without anchor --- LOW

"We view this as defensible in the CFPS, IFLS, and TZNPS samples given the rich demographic controls" is exactly the kind of hedging the voice profile flags. Tighten: "The rich demographic controls in CFPS, IFLS, and TZNPS make this plausible, and Section~\ref{sec:robustness} probes it directly by comparing balanced-only and pooled estimates."

### 10. `paper/unbalanced_proposition.tex:42-44` --- Redundancy --- LOW

"The pair $(\alpha, \pi)$ absorbs the level and the average urban return of the unbalanced stratum through a single pooled cell." The phrase "through a single pooled cell" is redundant with "absorbs". Consider: "The pair $(\alpha,\pi)$ absorbs the level and average urban return on the unbalanced stratum."

### 11. `paper/unbalanced_proposition.tex:96` --- "Step 1 requires" is backwards --- MEDIUM

"Step~1 requires consistent estimation of $(\gamma,\alpha,\pi)$ from the pooled sample." Step 1 is the FWL equivalence; Step 2 *supplies* the consistent estimator.

Suggested: "For the partialling-out in Step 1 to yield a consistent estimator of $(\mu,\Delta)$, we need consistency of $(\hat\gamma,\hat\alpha,\hat\pi)$ from the pooled sample."

### 12. `paper/unbalanced_proposition.tex:104` --- Citation key --- LOW

`\citep{hansen1982gmm}` --- verify the bibkey matches CKT.bib. Standard CKT bib convention is `hansen1982`.

### 13. `paper/unbalanced_proposition.tex:122-140` --- Remark 1 is a long single paragraph with two distinct claims --- LOW

Splits naturally: (a) only balanced observers identify $\Delta_{\underline d}$; (b) robustness to stronger violations.

### 14. `paper/unbalanced_proposition.tex:123-124` --- Meta/throat-clearing --- LOW

"The orthogonality of Step~1 is the substantive content of the proposition." Lead with the substantive claim instead: "Because the trajectory indicators are identically zero for unbalanced observers, those observers contribute to the pooled fit only through $\gamma$, period shifters, and $(\alpha,\pi)$."

### 15. `paper/unbalanced_proposition.tex:137-139` --- "Conservative" ambiguous --- LOW

"The pooled specification is therefore conservative: it never loses information relative to the balanced-only estimator and is weakly more efficient whenever $\gamma$ is correctly specified in both strata." "Conservative" is ambiguous (relative to what? bias? variance?). Suggested: "Under Assumption~\ref{ass:mar}, the pooled specification weakly dominates the balanced-only estimator in asymptotic variance and reduces to it as a special case when $\alpha=\pi=0$ is imposed."

### 16. `paper/unbalanced_proposition.tex:131` --- "As a result" filler --- LOW

Could be dropped: "The balanced-panel estimates are therefore robust to..."

---

## Voice-consistency notes

- Functional opening ("The estimation sample is unbalanced..."). Good.
- Quantification at the opening (88.6%--95.7%) matches the voice profile. Good, but add a table anchor (#7 above).
- "We view this as defensible" at line 52 is a voice deviation (#9).
- No use of banned phrases ("novel," "it is worth noting," "arguably," "interestingly"). Good.

---

## Summary

The proposition is well-structured and the mathematical content is sound. Four items move the needle most:

1. British "residualised" $\to$ "residualized" (hard rule).
2. "mis-specification" / "mis-specified" inconsistent with main.tex's "misspecification" (hard rule, terminology).
3. Proof says "two steps" but has three --- internal inconsistency.
4. `\emph{Step 1}` etc. violate the no-pseudo-heading / sparing-`\emph{}` conventions.

Secondary: the robustness claim in Remark 1 and the "conservative" claim at the end of Remark 1 overstate what the proof establishes; one passage in Step 1 ("block-separates") overstates orthogonality; the opening statistic (88.6%--95.7%) needs a table anchor.

**Score: 82/100** --- commit-ready but not PR-ready. Fix the four hard-rule / consistency items before circulating.
