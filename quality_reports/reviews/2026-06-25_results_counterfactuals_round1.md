# Review: Version 1 lower-bound prose, results_counterfactuals.tex

Scope: lines 128-132 (Version 1 lower-bound block), the footnote on line 130, the `\input{tables/hukou_bound.tex}` on line 136, and the immediately preceding paragraph (lines 118-126) for consistency. Out of scope per instructions: E1 misallocation subsection, Version 2 resorting subsection, welfare-bridge subsection, the verified harness numbers, the undefined cross-references, and the subjunctive tense of Version 2.

File: `C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex`

CoVe note: this is a single in-scope prose fragment whose numbers were declared verified harness output and whose table reference (`tab:hukou_bound`) is a known Overleaf-side punch-list item. No claim-evidence finding is raised, so the verifier-claim CoVe pass is not invoked.

## Summary

The block is clean against the hard rules. No spaced em dashes, no British spelling, no dropped "that"-complementizer, no bold labels, no title-case headings, notation consistent with the section ($\pi^{rh}$, $\pi_{d_N}^{rh}$, $\Delta_{d_N}^{rh}$, $\phi^{rh}$), one sentence per source line throughout. The voice match is strong: every claim carries a number, the limitation in line 132 is stated directly, and the footnote quantifies the source of uncertainty rather than hedging. The only findings are two MAJOR compound-complexity sentences and two MINOR items.

## Findings

### MAJOR

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | MEDIUM |
| Hard rule or default | hard |
| Location | line 130 |
| Problem | Single sentence stacks three independent clauses (shares "make up... 0.20", "so averaging... delivers... +2.2%, with a 95% interval...") and then carries a multi-clause footnote, exceeding the two-independent-clause limit. |
| Suggested fix | Split into two source sentences: state the share, then state the resulting economy-wide gain and its interval. E.g. "Rural-hukou never-migrants make up $\pi^{rh}\cdot\pi_{d_N}^{rh} \approx 0.74 \times 0.27 \approx 0.20$ of the defined-hukou population. Averaging their gain over the whole population delivers an economy-wide consumption gain of $+2.2\%$, with a $95\%$ interval of $[+1.8\%, +2.6\%]$." Attach the footnote to the second sentence. |

| Field | Value |
|---|---|
| Severity | MAJOR |
| Confidence | LOW |
| Hard rule or default | hard |
| Location | line 126 (surrounding paragraph, consistency check) |
| Problem | One sentence stacks a colon-joined verdict ("The expression is a bound rather than a magnitude") with a conditional "if... then" clause and a trailing "because" clause, three ideas chained across one source line. |
| Suggested fix | Break after the colon: "The expression is a bound, not a magnitude. If the flat $\phi^{rh}$ reflects suppressed sorting rather than uniformity of returns, the true gain exceeds this floor, because optimal sort would select the high-return tail rather than averaging across it." Confidence LOW because this is in the surrounding paragraph, flagged only for consistency; defensible to leave if the author prefers the single-sentence framing. |

### MINOR

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | MEDIUM |
| Hard rule or default | default |
| Location | line 132 |
| Problem | "We read it as a partial-equilibrium consumption floor conditional on the estimated rural-hukou base trajectory, the consumption-side complement to the general-equilibrium magnitudes the literature reports" pairs an appositive onto an already-loaded sentence; the same closing phrase ("consumption-side complement to... the literature reports") also appears at line 163 in the welfare-bridge subsection, creating a near-verbatim echo. |
| Suggested fix | Keep the appositive (it is a clean voice-consistent close) but consider varying the wording from the line-163 occurrence so the two paragraphs do not read as duplicated. Deviation acceptable if the echo is intentional emphasis. |

| Field | Value |
|---|---|
| Severity | MINOR |
| Confidence | LOW |
| Hard rule or default | default |
| Location | line 131 |
| Problem | "This economy-wide figure reads low precisely because it spreads a double-digit per-worker gain across a population in which four in five workers contribute nothing to the floor" — "four in five" (0.80) is the complement of the 0.20 share on line 130, which is fine, but it restates a number already given as $\approx 0.20$ one sentence earlier; mild redundancy rather than an error. |
| Suggested fix | Optional. The restatement aids readability and matches the voice's quantify-everything habit, so leaving it is defensible. |

## Score

92/100. No CRITICAL or hard-rule format violations; two MAJOR compound-complexity sentences (one in the reviewed block, one in the surrounding paragraph flagged for consistency) and two MINOR style items. Above the 90 PR threshold; the line-130 split is the one fix worth making before the block is considered submission-ready.
