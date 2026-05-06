---
title: Independent review of the rank-condition diagnostic memo
date: 2026-05-02
target: quality_reports/2026-05-02_rank-condition-diagnostic.md
reviewer: econ-critic
---

# Independent review of the rank-condition diagnostic memo

## Summary

The memo's central claim --- that the within-individual switching share is sufficient but not necessary for the formal rank condition on $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ --- is correct.
The Jacobian algebra is right.
The boxed condition $\Pr(D_{it}=1 \mid U_i=1) \in (0,1)$ is the right condition for the 2x2 sub-block in isolation, but as written it understates one ingredient that actually matters in the full system: the rank condition for $\Delta_{\mathrm{unb}}$ in the pooled GMM is not whether $D_{it}$ varies on the unbalanced stratum, but whether $D_{it}$ varies on the unbalanced stratum *after partialling out* $x_{it}$.
With $\gamma$ shared across strata, this distinction matters and the memo misses it.
The recommendation to feature both diagnostics is sensible; the conditional treatment rate is the cleaner of the two but should be presented with the caveat that perfect collinearity with $x$ on the unbalanced cell would still kill identification of $\Delta_{\mathrm{unb}}$.

Below I take the five questions in order, then flag the partialling issue separately as the headline finding.

## Q1. Is the moment-system / Jacobian derivation correct?

Yes.

Setting $\varepsilon_{it}(\theta) = y_{it} - \mu_{\mathrm{unb}} - \Delta_{\mathrm{unb}} D_{it} - x_{it}'\gamma$ on $\{U_i=1\}$, the partials $\partial \varepsilon_{it}/\partial \mu_{\mathrm{unb}} = -1$ and $\partial \varepsilon_{it}/\partial \Delta_{\mathrm{unb}} = -D_{it}$ are correct.
Multiplying by the moment instruments $U_i$ and $U_i D_{it}$ gives the four entries reported in the memo.
With $D_{it} \in \{0,1\}$ so $D_{it}^2 = D_{it}$, the $2 \times 2$ matrix
$$G = -\begin{pmatrix} E[U_i] & E[U_i D_{it}] \\ E[U_i D_{it}] & E[U_i D_{it}] \end{pmatrix}$$
is right.
Its determinant factors as
$$\det G = E[U_i D_{it}] \cdot \big(E[U_i] - E[U_i D_{it}]\big) = \Pr(U_i=1, D_{it}=1) \cdot \Pr(U_i=1, D_{it}=0),$$
which the memo states correctly.
No errors here.

One small notational point.
The memo's $E[U_i]$ and $E[U_i D_{it}]$ are taken over person-periods, not individuals; this is the right object for a stacked individual-period GMM where the asymptotic Jacobian is the per-period mean.
Stating that explicitly somewhere would protect the reader from the (innocuous here) ambiguity.

## Q2. Is the boxed claim correct under cluster-robust GMM at the individual level?

Yes, modulo two qualifications.

First, the boxed condition $\Pr(D_{it}=1 \mid U_i=1) \in (0,1)$ implicitly assumes $\Pr(U_i=1) > 0$, i.e., the unbalanced stratum is non-empty.
This is harmless --- the parameters $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ are not even defined otherwise --- but worth stating once.

Second, cluster-robust inference at the individual level affects the asymptotic variance, not the Jacobian or the local rank condition.
The Jacobian is still $G = E[\partial g_{it}/\partial \theta]$; clustering changes how you estimate the long-run variance of the sample moments, not what makes $G$ singular.
So clustering is orthogonal to the boxed claim.
The memo's framing is consistent with this; I read it as correct.

Third (and this is the substantive caveat I expand on under Q4): the boxed condition is the right local rank condition for the *isolated* 2x2 sub-block on $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$, treating $\gamma$ as known.
Once $\gamma$ has to be jointly identified from a moment system that includes both strata, the relevant condition for $\Delta_{\mathrm{unb}}$ is positive variation in $D_{it}$ on the unbalanced cell *after partialling out* $x_{it}$.
The memo's boxed claim is therefore right under the maintained assumption that $D_{it}$ is not collinear with $x_{it}$ on $\{U_i=1\}$, but the maintained assumption is not stated and is not implied by $\Pr(D_{it}=1\mid U_i=1) \in (0,1)$.

## Q3. Is "within-individual switching is sufficient but not necessary" correct?

Yes.

Within-individual switching among the unbalanced means there exist $i$ with $U_i=1$ and $D_{it}, D_{it'}$ taking both values for some $t,t' \in \mathcal T_i$.
This guarantees both $\Pr(U_i=1, D_{it}=1) > 0$ and $\Pr(U_i=1, D_{it}=0) > 0$, so the determinant is non-zero --- sufficiency.
Necessity fails by the explicit counterexample the memo gives: an unbalanced sample composed entirely of always-rural individuals plus always-urban individuals (no within switchers) still has $\Pr(D_{it}=1\mid U_i=1) \in (0,1)$ as long as both groups are non-empty.

The memo could sharpen this by saying: among the three sub-populations of unbalanced individuals (always-rural-among-observed, always-urban-among-observed, switchers-among-observed), the rank condition holds iff at least two of the three sub-populations are non-empty, with at least one of those two having $D=0$ somewhere and at least one having $D=1$ somewhere.
The current wording "Within-individual switching is sufficient (and conservative)" is correct but slightly understates how loose the formal condition is.

## Q4. Subtleties: does the interaction with trajectory-block moments through the common $\gamma$ change the rank condition?

This is where the memo overstates how clean the boxed condition is.
The trajectory parameters $(\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}, \kappa_T)$ enter only the balanced-stratum moments and the unbalanced moments do not depend on them; conversely, $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ enter only the unbalanced moments and balanced-stratum moments do not depend on them.
So far the Jacobian is block-diagonal in those two parameter blocks.

The complication is $\gamma$.
The covariate vector $x_{it}$ enters both strata, and the common-$\gamma$ assumption (Assumption 2 in the appendix) ties them together.
The full Jacobian for the unbalanced sub-block, including $\gamma$, is
$$G_{\mathrm{unb}} = -E\!\begin{pmatrix} U_i & U_i D_{it} & U_i x_{it}' \\ U_i D_{it} & U_i D_{it} & U_i D_{it} x_{it}' \\ U_i x_{it} & U_i D_{it} x_{it} & x_{it} x_{it}' \end{pmatrix},$$
where the bottom-right block uses the full $x$-moment (which gets contributions from both strata, not just unbalanced).

The local rank condition for $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ in the full system is full rank of the *Schur complement* of the $\gamma$ block --- equivalently, that the residualized regressors $(U_i, U_i D_{it})$ retain rank 2 after projecting out $x_{it}$.
This is strictly stronger than $\Pr(D_{it}=1 \mid U_i=1) \in (0,1)$.
Concretely, identification of $\Delta_{\mathrm{unb}}$ fails if $D_{it}$ is a deterministic function of $x_{it}$ on the unbalanced stratum even when $D_{it}$ varies on that stratum.
The textbook example: if $x_{it}$ contains a region dummy that perfectly distinguishes the always-urban-among-observed from the always-rural-among-observed unbalanced individuals, then within $\{U_i=1\}$ all variation in $D_{it}$ is collinear with the region dummy and the $U_i D_{it}$ moment is collinear with the corresponding $x_{it}$ moment after partialling.
The memo's boxed condition reads as full rank in this case but identification fails.

This matters in practice because:

1. The two diagnostics the memo discusses (within-switch share; conditional treatment rate) both look at marginal variation in $D_{it}$ on the unbalanced cell, neither looks at *residual* variation of $D_{it}$ on $x_{it}$.
2. In a sample like TZA with within-switch share 5.7\%, almost all of the identifying variation in $\Delta_{\mathrm{unb}}$ is between-individual.
That variation is exactly the kind that can be soaked up by $x_{it}$ if covariates correlate strongly with location.
A region or province fixed effect, demographic controls, or a time trend that loads differently on always-urban vs. always-rural unbalanced individuals would erode the residualized signal.
The "precision-limited rather than non-identified" reassurance the memo offers for TZA is true under the boxed condition but optimistic under the actual rank condition.
3. The within-switch share is a slightly tighter diagnostic for this reason than the memo acknowledges --- within-individual variation in $D_{it}$ partials out anything time-invariant for that individual, including any regional-fixed-effect-like component of $x_{it}$.
It does not partial out time-varying components, but the time-varying components in $x_{it}$ are what they are (demographics, year FE), and within-switch variation is more robustly residual than between-individual variation.

What I would write into the appendix or memo is the corrected condition: $D_{it}$ has positive variance on the unbalanced stratum after linear projection on $x_{it}$.
A diagnostic that maps to this directly is the partial $R^2$ of $D_{it}$ on $(U_i, x_{it})$ regressed against the unbalanced indicator interactions, or equivalently the residual variance of $D_{it}$ from a regression on $x_{it}$ within $\{U_i=1\}$.
That residual variance being bounded away from zero is what actually pins down $\Delta_{\mathrm{unb}}$.

This does not break the memo's punchline.
In all three samples the within-switch share is positive and the conditional treatment rate will be in $(0,1)$, so unless $x_{it}$ is doing something pathological the rank condition (correctly stated) will hold.
But the memo's description of *what* the rank condition is should mention $x_{it}$.

## Q5. Is the recommendation reasonable, or is one reading clearly preferable?

The recommendation to report both is reasonable and I would endorse it with one modification.

Reading 1 (formal: conditional treatment rate) is the right strict-mathematical answer for the *2x2 sub-block in isolation* but, as Q4 argues, it understates the actual condition once $\gamma$ is in the system.
The honest formal-mathematical condition involves residualized $D_{it}$, which is a less appealing diagnostic to feature because it has no clean prose interpretation.

Reading 2 (within-switch share) is what the appendix currently uses.
As a diagnostic it is sufficient but conservative; as a *credibility* signal under partial misspecification of orthogonality it does extra work that Reading 1 does not (it tells the reader how much of $\Delta_{\mathrm{unb}}$ comes from within-individual variation, which is the variation most insulated from time-invariant unobserved heterogeneity even if Assumption 1 is mildly wrong).

The memo's draft replacement closing paragraph is good and I would adopt it with two tweaks:

a. State the partialling caveat once.
Something like: "Identification additionally requires that $D_{it}$ is not collinear with $x_{it}$ on the unbalanced stratum; this is satisfied in all three samples by inspection of the design matrix."
The reader can take that on faith if it is true and you have checked, but the rank-condition statement in the proposition should not pretend $x_{it}$ is absent.

b. The current text in `unbalanced_proposition.tex` line 73 says "$D_{it}$ takes both values within the unbalanced stratum" and on line 75 explicitly equates this to "the share of unbalanced individuals observed with both $D=0$ and $D=1$ across their observed waves."
This identifies the formal rank condition with the within-switch share, which is the conflation the memo is trying to fix.
If you keep the within-switch share as the headline diagnostic, the proposition's stated rank condition needs to be tightened to "$D_{it}$ varies *within* unbalanced individuals" --- the memo says this on line 127 and I agree.
If you switch to Reading 1, the proposition's text is actually fine as written ("takes both values within the unbalanced stratum" is naturally read at the person-period level), but the diagnostic computation in the .do file and the prose paragraph that reports it need to change.

If forced to pick one: Reading 1 (conditional treatment rate as headline, with the partialling caveat, plus within-switch share as a credibility supplement) is the cleaner package.
The within-switch share is the right *credibility* check; the conditional treatment rate is the right *identification* check; reporting only one of them obscures whichever question the omitted one answers.

## Additional observations

**Stratum-period weighting.**
The memo writes $E[U_i]$ and $E[U_i D_{it}]$ as expectations over person-periods.
For an unbalanced panel where individuals are observed for different numbers of periods, this gives more weight to unbalanced individuals observed in more waves.
That is correct for the GMM Jacobian (which sums over $t$ within $i$ before averaging over $i$) but a reader might expect a person-level expectation.
A one-line clarification ("expectations are over person-periods, weighted by observed-wave count per individual") would help.

**Empty cells in TZA.**
The 5.7% within-switch share for TZA reflects that TZA has only 3 waves and so most unbalanced TZA individuals are observed in 1 or 2 waves, of which a small fraction can switch.
The memo's diagnostic table does not break out always-urban / always-rural / switcher among the unbalanced.
That decomposition would let the reader see whether TZA's between-individual variation comes from a meaningful number of always-urban observed unbalanced individuals or from one or two outlier respondents.
The action item already lists this; I think it is more important than the memo treats it, especially given how thin TZA is.

**Connection to Verdier (2020).**
The short version cites Verdier and notes that he uses an individual-FE parameterization on observed periods.
Verdier's rank condition in that parameterization is within-individual variation in $D_{it}$ for individuals observed in 2+ periods, which is closer in spirit to the within-switch share than to the conditional treatment rate.
The current pooled-cell parameterization has no individual fixed effects, so it formally requires less within-individual variation to identify $\Delta_{\mathrm{unb}}$ --- this is the gap the memo is correctly diagnosing.
A sentence connecting "Verdier's rank condition needs within-individual variation; ours does not, because we have no person-FE on the unbalanced cell" would clarify why the pooled-cell choice has different identification footprint than the natural alternative.

## Verdict on each question

| Question | Verdict |
|----------|---------|
| Q1 Jacobian derivation | Correct. |
| Q2 Boxed condition under cluster-robust GMM | Correct for the 2x2 sub-block in isolation; needs the partialling caveat for the full system. |
| Q3 Sufficient-not-necessary | Correct. |
| Q4 Interaction with trajectory-block moments | Trajectory-block parameters do not interact with the rank condition; $\gamma$ does, through $x_{it}$. The memo misses this interaction. Real but small: in practice it almost certainly does not change the conclusion. |
| Q5 Recommendation | Reasonable. Recommend Reading 1 as headline plus Reading 2 as credibility supplement, with a one-line partialling caveat. |

## Bottom line for the action items

The memo is substantially correct.
The recommendation is sound.
Adding one sentence that acknowledges the partialling-out-of-$x_{it}$ subtlety to the appendix (and ideally a quick numeric check that $D_{it}$ is not collinear with $x_{it}$ on the unbalanced stratum) would close the only gap I see.
The within-switch share is conservative but defensible; the conditional treatment rate is sharper but slightly optimistic without the partialling caveat.
Both is best.

Files referenced:

- [quality_reports/2026-05-02_rank-condition-diagnostic.md](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/quality_reports/2026-05-02_rank-condition-diagnostic.md)
- [paper/unbalanced_proposition.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition.tex)
- [paper/unbalanced_proposition_short.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition_short.tex)

## Overall assessment

The memo's identification analysis survives scrutiny on its central claim.
The Jacobian math is right, the sufficient-not-necessary argument is right, the recommendation is reasonable.
The one gap is that the boxed rank condition treats $\gamma$ as if it were not in the system; once $\gamma$ is jointly estimated from a common-$\gamma$ specification across strata, the condition that actually pins down $\Delta_{\mathrm{unb}}$ is residualized variation in $D_{it}$ after partialling on $x_{it}$, not raw variation.
Whether this matters empirically is a question about the design matrix on $\{U_i=1\}$, not about the math; almost certainly it does not change the conclusion.
The researcher should still verify it once and then choose one of the two readings (or both) for the appendix.
