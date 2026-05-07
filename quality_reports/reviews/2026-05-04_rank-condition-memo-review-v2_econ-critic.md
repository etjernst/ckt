---
title: Second-round review of the rank-condition diagnostic memo
date: 2026-05-04
target: quality_reports/2026-05-02_rank-condition-diagnostic.md (revised)
prior review: quality_reports/reviews/2026-05-02_rank-condition-memo-review_econ-critic.md
reviewer: econ-critic
---

# Second-round review of the rank-condition diagnostic memo

## Summary

The revision lands the partialling correction cleanly.
The boxed condition is now stated correctly; the Schur-complement framing is the right way to present it; the new "three sub-populations" section organizes the identifying-variation discussion well.
A handful of small issues remain --- one slight imprecision in the iff statement, one numbered-list typo, one place where the "stronger orthogonality demand" framing of the Verdier comparison is sharper than the appendix actually argues, and one operational gap in the proposed numeric check.
None of these is a CRITICAL identification issue.
The math is right; the prose has a few rough edges.

I take the user's six lettered questions in order, then close with anything else.

## A. Did the revision incorporate the partialling correction correctly?

Agree.

The boxed condition now reads
$$\mathrm{Var}(D_{it} - x_{it}'\beta^* \mid U_i=1) > 0,$$
where $\beta^*$ is the linear projection of $D_{it}$ on $x_{it}$ within the unbalanced stratum.
This is the correct full-system rank condition for $\Delta_{\mathrm{unb}}$ once $\gamma$ is jointly estimated.
The derivation walks through the right Schur-complement argument: the unbalanced-block Jacobian is presented with the bottom-right $x x'$ block flagged as receiving contributions from both strata, and the rank condition is described as full rank of the Schur complement of the $\gamma$ block, equivalently rank-2 retention of $(U_i, U_iD_{it})$ after linear projection on $x_{it}$.
The textbook example (region dummy that perfectly distinguishes always-rural from always-urban unbalanced individuals) is the right counterexample, and the framing of the sub-block condition as the "special case in which $x_{it}$ is the constant" is precise and helpful.

One minor sharpening would help the reader.
The boxed condition, as stated, is the rank condition for $\Delta_{\mathrm{unb}}$ alone --- it ensures the residualized $U_i D_{it}$ regressor has positive variance after partialling on both $U_i$ and $x_{it}$.
For $\mu_{\mathrm{unb}}$ to also be identified one needs the full Schur complement to be rank 2, which additionally requires that $U_i$ is not collinear with $x_{it}$ on the full sample (i.e., the unbalanced indicator is not a linear function of the covariates).
That is automatic in any reasonable setup but worth one sentence, because the prose around the box says "the rank condition" and a careful reader will ask which one.

Severity: MINOR. Confidence: HIGH.

## B. Is the iff statement in "Three sub-populations" exactly right?

Mostly agree, but the iff is slightly off as written.

The memo says (line 94):

> The sub-block rank condition holds iff at least one of $\mathcal U_S$ is non-empty, or both $\mathcal U_R$ and $\mathcal U_U$ are non-empty.

The intended claim is correct: the sub-block rank condition is equivalent to the unbalanced stratum containing at least one $D=0$ person-period and at least one $D=1$ person-period.
But the natural-language iff as written is not quite that.
It says non-emptiness of $\mathcal U_S$ alone is sufficient, which is true if any single member of $\mathcal U_S$ contributes both a $D=0$ and a $D=1$ person-period.
That is by construction true under the memo's own definition of $\mathcal U_S$ (switchers, both values observed across own waves), so this branch is fine.
The other branch ("both $\mathcal U_R$ and $\mathcal U_U$ are non-empty") is also fine.
What is missing is the third logical possibility: $\mathcal U_S$ empty, $\mathcal U_R$ non-empty, $\mathcal U_U$ empty (or symmetrically the reverse) --- i.e., the unbalanced stratum has only one value of $D$ across all observed person-periods.
The current iff handles that case correctly (the rank condition fails because neither branch fires), so the logic is right; what is awkward is the prose "at least one of $\mathcal U_S$ is non-empty," which reads as if there is more than one subset of $\mathcal U_S$ being quantified over.

A cleaner statement: "the sub-block rank condition holds iff $\mathcal U_S$ is non-empty, or both $\mathcal U_R$ and $\mathcal U_U$ are non-empty."
Drop "at least one of."

This is a phrasing issue, not a logical error.
Severity: MINOR. Confidence: HIGH.

## C. Is the Verdier comparison accurate, and is the tradeoff framing fair?

Partially agree. The factual claim about Verdier is right; the framing of the tradeoff overstates what the appendix actually does.

The factual claim --- that Verdier's individual-FE parameterization needs within-individual variation in $D_{it}$ for individuals contributing to the LCA slope, and that the pooled-cell parameterization with no person-FE on the unbalanced cell does not need within-individual variation --- is correct.
This matches my earlier review (Q5 / Additional observations) and is exactly the right contrast.

The tradeoff framing is where the memo gets slightly ahead of itself.
The memo writes (line 154):

> The flip side is that the pooled-cell estimator has to lean more heavily on the orthogonality assumption to keep between-individual variation interpretable as $\Delta_{\mathrm{unb}}$.

This is true in spirit: replacing person-FE with a single cell intercept means the orthogonality assumption (Assumption~\ref{ass:orthogonality} in the appendix, $E[\varepsilon_{it} \mid U_i=1, D_{it}, x_{it}] = 0$) is doing more work, because between-individual variation in $D_{it}$ is now included in the identifying signal and is not partialled out by a person-FE.
But the appendix itself does not make this argument as a *tradeoff*.
The appendix argues for the pooled-cell over Verdier's specification on different grounds: continuity with the trajectory-cell notation, $\{\Delta_{\underline d}\}_{\underline d \in \mathcal D_S}$ as direct estimation outputs rather than post-estimation averages over individual fixed effects.
The "easier rank condition, stronger orthogonality demand" framing is the reviewer-style critique the memo is offering, not a recap of the paper.
The memo's last sentence ("This tradeoff ... is exactly the one the appendix already discusses when it argues for the pooled-cell over Verdier's individual-FE setup") is overclaiming --- the appendix does not discuss the tradeoff in those terms.

Two ways to fix: either soften the closing sentence to "this tradeoff is implicit in the choice the appendix already makes," or drop the closing sentence and let the analytical comparison stand on its own.

Severity: MINOR. Confidence: MEDIUM (depends on how strict one is about "the appendix discusses" vs "the appendix's choice implies").

## D. Is the proposed operational form of the partialling check the right one?

Agree it is workable; a methods referee would prefer a sharper statement.

The recommendation says: "we verify separately that the residual variance of $D_{it}$ regressed on $x_{it}$ within $\{U_i=1\}$ is bounded away from zero in all three samples, confirming the rank condition."

This is the right object up to scale, but a referee will ask three questions the current phrasing does not pre-empt:

1. *Bounded away from zero by what threshold?*
   "Bounded away from zero" is a population statement; in the sample, residual variance is whatever it is.
   What the referee wants is a sample-level diagnostic that does not depend on the units of $D_{it}$.
   The natural object is the partial $R^2$ of $D_{it}$ on $x_{it}$ within the unbalanced stratum, or equivalently $1 - R^2$ from a regression of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$.
   That is unit-free, lives in $[0,1]$, and a value like $0.85$ is self-evidently far from collinearity in a way that "residual variance is 0.18" is not.

2. *Why not the condition number / minimum eigenvalue of the design matrix on the unbalanced stratum?*
   The actual rank condition is full rank of the Schur-complement-of-$\gamma$ Jacobian sub-block.
   The minimum eigenvalue of that sub-block (or the reciprocal condition number) is the most direct numeric analogue.
   Reporting it is more work, and probably overkill for an empirical paper, but a methods referee may push for it.
   The partial-$R^2$ check is the standard practitioner shortcut and is defensible if presented as such.

3. *What if $x_{it}$ has many components?*
   With $\dim(x)$ moderate (which it is here --- demographics, year FE), running the unbalanced-stratum regression and reporting the residual variance is a single line of Stata.
   With $\dim(x)$ large (region $\times$ year FE, etc.), the residual variance can shrink for innocuous reasons (overfit) and the diagnostic loses its sharpness.
   A note that $x_{it}$ here is the same vector used in the main estimation would close that off.

Bottom line: the proposed check is operationally fine for an applied paper; reporting it as a partial $R^2$ rather than as a residual variance is a small upgrade that costs nothing and reads more naturally.
The memo's phrasing leaves the threshold question unanswered, which is the only real issue.

Severity: MINOR. Confidence: MEDIUM.

## E. Are the action-item diagnostics the right set?

Mostly agree.

The action items list:
(a) conditional treatment rate $\Pr(D_{it}=1 \mid U_i=1)$;
(b) the decomposition $(|\mathcal U_R|, |\mathcal U_U|, |\mathcal U_S|)$;
(c) within-stratum residual variance of $D_{it}$ on $x_{it}$.

All three are warranted. (a) is the headline diagnostic for the sub-block condition; (b) lets the reader see whether between-individual variation comes from a meaningful number of always-urban unbalanced individuals or a handful of outliers (especially relevant for TZA); (c) is the actual full-system rank condition.
None is redundant.

Two things worth adding to the action item rather than the diagnostic itself:

- A note that $x_{it}$ in (c) should be the same covariate vector used in the main estimation, not a stripped-down version. If the main spec includes year FE and region indicators, those should be in the partial-$R^2$ check; otherwise the check is too easy.
- The within-switch share is already computed and reported. The action item should be explicit that the new diagnostics complement, rather than replace, the existing within-switch share macros.

One thing that is *not* missing but could be sharpened: the action items mention the partial-$R^2$ / residual-variance check as a numeric check, but the recommendation paragraph (the prose draft on lines 162--165) describes it as "we verify separately that the residual variance ... is bounded away from zero" without stating the value.
Whatever is computed in (c) should appear in the appendix as a number, not as an assertion.
Otherwise the prose says "we verified" but the reader cannot replicate or check.

Severity: MINOR. Confidence: HIGH.

## F. Did the rewrite introduce new errors, weakening, or imprecision? Did it remove anything correct that was worth keeping?

Three small issues, none material.

1. **Numbered-list typo (lines 114--124).** The "Two numbers we do not yet have" paragraph introduces the list as "Two numbers" but then lists *three* items: conditional treatment rate, the $(|\mathcal U_R|, |\mathcal U_U|, |\mathcal U_S|)$ decomposition, and the residual variance. Fix by changing "Two numbers we do not yet have" to "Three numbers" (or by reorganizing items 2 and 3 into a single bullet, since they are conceptually different objects).

2. **A potentially misleading sentence at line 117.** The text says "By construction it lies strictly in $(0,1)$ in any country where $\mathcal U_S \cup (\mathcal U_R \cap \mathcal U_U)$ is non-empty in the sense of the previous section..." The set-theoretic notation here is wrong: $\mathcal U_R \cap \mathcal U_U$ is the empty set by construction (an unbalanced individual is either always-rural-among-observed, always-urban-among-observed, or a switcher --- the three sets partition). What the memo means is something like "$\mathcal U_S$ is non-empty, or both $\mathcal U_R$ and $\mathcal U_U$ are non-empty" --- the same condition stated cleanly in the boxed iff. Replace the symbolic expression with the prose version.

3. **The "automatically residualized" sentence at line 123.** The memo says "The within-switch share is, for what it is worth, automatically residualized against any time-invariant function of $x_{it}$ for the switcher individual: a within-individual transition from $D=0$ to $D=1$ partials out individual-level time-invariant covariates by construction." This is true if the diagnostic were the within-individual variance of $D_{it}$ residualized in a fixed-effects sense. The within-switch *share* (proportion of unbalanced individuals who switch) is not itself a residualized quantity; what is residualized is the variation in $D_{it}$ contributed by switchers in a within-transformation of the regression. The sentence is reaching for a real point (within-switcher variation is more robust to time-invariant confounders than between-individual variation), but the phrasing conflates a count diagnostic (the share) with a regression-based one (within-individual variation in $D_{it}$). I would either tighten the wording to refer to "within-switcher variation" rather than "the within-switch share," or drop the parenthetical.

Things that were *not* removed but should not be: the v1 boxed claim ($\Pr(D_{it}=1 \mid U_i=1) \in (0,1)$) is now correctly demoted to "the sub-block condition," which is the right place for it. The Jacobian derivation, the determinant factorization, the "sufficient but not necessary" framing of within-switch variation --- all preserved. The memo did not throw out anything from v1 that was correct.

Severity: items 1 and 2 are MINOR (typos / notation slips); item 3 is MINOR (imprecise framing).
Confidence: HIGH on items 1 and 2; MEDIUM on item 3.

## Additional observations

**The appendix file itself still needs updating.** The memo is self-consistent now, but [paper/unbalanced_proposition.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition.tex) lines 73--75 and the parallel passage in [paper/unbalanced_proposition_short.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition_short.tex) line 69 still state the rank condition as "$D_{it}$ takes both values within the unbalanced stratum" with the within-switch share as the headline diagnostic. The proposition's stated rank condition does not yet incorporate the partialling caveat the memo's revision is built around. The action items mention this but it is the substantive change that has to land in the actual paper, not just the memo. Worth flagging as the binding open task.

**The proof in `unbalanced_proposition.tex` already does the right thing.** Step 3 of the proof (lines 132--137) correctly states that strict efficiency improvement for $\gamma$ requires "the residual $x$-variation on the unbalanced stratum after partialling out $(U_i, U_iD_{it})$" --- which is the same partialling object the rank-condition discussion needs. So the proof internally already reasons about the partialled-out quantity; the rank-condition statement just needs to match. This is encouraging --- it means the appendix is more nearly correct than the surface-level rank-condition sentence suggests, and the fix is local to the rank-condition prose.

**The "Two readings" framing reads slightly redundant after the revision.** Once the formal condition is correctly stated as positive residual variance (Reading 1, sharpened), the role of the within-switch share is the credibility supplement (Reading 2), and the recommendation is to report both. That's the right resolution and the memo lands it. The stand-alone "Two readings" section is now somewhat redundant with the recommendation paragraph that follows. Not a problem, but if the memo is shortened for any reason, the "Two readings" section is the natural cut.

## Verdict on each question

| Question | Verdict |
|----------|---------|
| A. Partialling correction incorporated correctly | Yes; one minor sharpening (clarify which parameter the boxed condition pins down). |
| B. Three-sub-populations iff exactly right | Logic is right; phrasing "at least one of $\mathcal U_S$ is non-empty" is awkward; rewrite as "$\mathcal U_S$ is non-empty, or both $\mathcal U_R$ and $\mathcal U_U$ are non-empty." |
| C. Verdier comparison and tradeoff framing | Factual claim about Verdier is correct; "the appendix already discusses [the tradeoff]" overstates what the appendix does. Soften or drop. |
| D. Operational form of the partialling check | Workable; partial $R^2$ would be sharper than residual variance and unit-free. State the sample threshold or value, not just "bounded away from zero." |
| E. Action-item diagnostics | All three warranted, none redundant. Note that $x_{it}$ in the residual-variance check should match the main-spec covariate vector, and the computed value should appear as a number in the appendix. |
| F. New errors / removed correct content | Three small issues: "Two numbers" should be "Three numbers"; $\mathcal U_R \cap \mathcal U_U$ is empty by construction; "within-switch share is automatically residualized" conflates a count with a residualized quantity. Nothing correct was removed from v1. |

## Bottom line

The revision is substantially clean.
The central correction --- partialling out $x_{it}$ in the rank condition --- is correctly incorporated, and the Schur-complement framing is the right way to present it.
What remains is small: a phrasing tightening on the iff, a typo on "two/three numbers," a notation slip on $\mathcal U_R \cap \mathcal U_U$, a softening of the Verdier-tradeoff claim, and a sharper operational form for the partialling check (partial $R^2$ rather than raw residual variance).
None of these blocks readiness; collectively they would take an hour to fix.
The binding open task is not the memo but the appendix: [paper/unbalanced_proposition.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition.tex) line 73 and [paper/unbalanced_proposition_short.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition_short.tex) line 69 still state the rank condition without the partialling caveat the memo correctly identifies.

## Files referenced

- [quality_reports/2026-05-02_rank-condition-diagnostic.md](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/quality_reports/2026-05-02_rank-condition-diagnostic.md)
- [quality_reports/reviews/2026-05-02_rank-condition-memo-review_econ-critic.md](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/quality_reports/reviews/2026-05-02_rank-condition-memo-review_econ-critic.md)
- [paper/unbalanced_proposition.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition.tex)
- [paper/unbalanced_proposition_short.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition_short.tex)

## Overall assessment

Does the memo's identification analysis survive scrutiny on the second pass? Yes.
The correction the prior review asked for has landed correctly; the Jacobian math is right; the boxed rank condition is now the right object; the Verdier comparison is factually accurate even if the closing tradeoff framing slightly outruns what the appendix says.
The remaining issues are MINOR and editorial, not substantive.
The work that still has to happen is not in the memo --- it is in the appendix files, which still state the rank condition in the un-corrected form.
This assessment is a prompt for the researcher's own judgment, not a substitute for it.
