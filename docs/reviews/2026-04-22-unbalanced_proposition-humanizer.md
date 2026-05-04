# Humanizer review: `paper/unbalanced_proposition.tex`

**File:** `paper/unbalanced_proposition.tex`
**Date:** 2026-04-22
**Context:** LaTeX proof-of-proposition block (setup prose, Assumption, Proposition, 3-step proof, two Remarks). Theorem/proof register is expected; math notation is not flagged.

---

## Summary

The file is substantially cleaner than typical AI-assisted drafts. Theorem-proof prose constrains voice, and most prose-level AI patterns (promotional language, negative parallelism, em-dash overuse, copula avoidance, -ing phrases, rule-of-three cascades) are absent or borderline. What remains are a handful of throat-clearing transitions and two mildly inflated closing sentences.

No CRITICAL humanizer issues. Four MINOR items below.

---

## Findings

### H1. Throat-clearing transition --- `paper/unbalanced_proposition.tex:122-123`

> The orthogonality of Step~1 is the substantive content of the proposition.

This is the "meta-sentence" opener --- it tells the reader the *next* sentence will matter, which is an AI-pacing tell. The actual substantive claim follows immediately after ("Because the trajectory indicators are identically zero for unbalanced observers...").

Fix: drop the meta-sentence and promote the substantive one to the topic position.

Before:
> The orthogonality of Step~1 is the substantive content of the proposition. Because the trajectory indicators are identically zero for unbalanced observers, the unbalanced subsample does not contribute directly...

After:
> Because the trajectory indicators are identically zero for unbalanced observers, the unbalanced subsample does not contribute directly to the identification of any $\Delta_{\underline d}$ of economic interest; it enters \eqref{eq:restricted-grc-unbalanced} only through the estimation of $\gamma$, period shifters, and the pooled pair $(\alpha,\pi)$.

### H2. "An immediate corollary is that..." opener --- `paper/unbalanced_proposition.tex:142-143`

> An immediate corollary is that the empirical gap between the balanced-only and pooled estimates of $\Delta_{\underline d}$...

"An immediate corollary is that" is a copula-avoidance flourish. Human math writing tends to say "A corollary: ..." or just lead with the claim.

Fix:
> The balanced/pooled gap in estimates of $\Delta_{\underline d}$, reported in Tables~\ref{tab:GRC_IDN_consumption_urban_bal}, \ref{tab:GRC_CHN_consumption_urban_bal}, and \ref{tab:GRC_TZA_consumption_urban_bal}, is a direct empirical check on Assumption~\ref{ass:mar}.

### H3. Inflated "conservative" closer --- `paper/unbalanced_proposition.tex:137-139`

> The pooled specification is therefore conservative: it never loses information relative to the balanced-only estimator and is weakly more efficient whenever $\gamma$ is correctly specified in both strata.

Two flags: (a) "conservative" is used as a vague positive ("never loses, weakly more efficient") --- the generic-positive-conclusion pattern; (b) "therefore" continues a chain of soft connectors ("As a result," --- "The pooled specification is therefore...") that together read as mechanical.

Fix: state the claim plainly.
> Under Assumption~\ref{ass:mar}, the pooled specification weakly dominates the balanced-only estimator in asymptotic variance and reduces to it when $\alpha=\pi=0$.

### H4. Soft hedged endorsement --- `paper/unbalanced_proposition.tex:51-55` and `paper/unbalanced_proposition.tex:151-153`

Two places use a similar "we view this as defensible / is consistent with" pattern:

> We view this as defensible in the CFPS, IFLS, and TZNPS samples given the rich demographic controls, and probe it directly through the balanced-panel comparison in Section~\ref{sec:robustness}.

> The close correspondence we observe is consistent with both conditions holding in the CFPS, IFLS, and TZNPS panels.

Both use listing of the three country acronyms as a mild rule-of-three, and "is consistent with both conditions holding" is a hedged generic-positive conclusion.

Fix for line 51-55 (active, specific):
> The rich demographic controls in these three panels make this plausible; Section~\ref{sec:robustness} tests it directly by comparing balanced-only and pooled estimates.

Fix for line 151-153 (sharper):
> The balanced and pooled estimates match closely in all three panels, which is what the joint null of MAR and common-$\gamma$ predicts. Separating the two conditions would require additional structure.

---

## What would make this obviously AI-generated?

Remaining tells, in order:

- The triple repetition "CFPS, IFLS, and TZNPS" appearing twice in close proximity (lines 52-53 and 153).
- Soft connectors: "As a result," / "therefore" / "An immediate corollary is that".
- "We view this as defensible" --- the hedged-endorsement voice.
- "never loses information / weakly more efficient" --- paired-claim conclusion.

Nothing severe. This is a case where one careful pass over the two Remarks and the assumption gloss fully de-AI-ifies the prose.

---

## Not flagged (appropriate for the register)

- The proof's enumerated structure ("Step 1 (orthogonality)", "Step 2 (consistency)", "Step 3 (efficiency)") is conventional in math writing.
- Heavy use of mathematical notation is required.
- The formal voice of the Assumption, Proposition, and Proof environments is appropriate.
- No em-dash overuse, no emojis, no boldface emphasis, no title-case headings, no promotional language, no superficial -ing phrases, no negative parallelisms, no chatbot artifacts, no knowledge-cutoff disclaimers.

---

## Recommendation

Apply H1-H4 as small surgical edits; no rewrite needed. The file is structurally sound and the math prose is in good shape. Humanizer score (informal): 88/100 --- above the "commit" threshold, below "submission".
