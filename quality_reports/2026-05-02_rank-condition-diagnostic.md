---
title: Rank condition for $\Delta_{\mathrm{unb}}$ — what is the right diagnostic?
date: 2026-05-02 (revised 2026-05-04 after independent review)
files:
  - paper/unbalanced_proposition.tex
  - paper/unbalanced_proposition_short.tex
  - RP7/scripts/1b_unbalanced_rank_diagnostic.do
status: open question — substantive call required
---

# Rank condition for $\Delta_{\mathrm{unb}}$ in the pooled-cell model

## What this memo is about

The unbalanced-pooling appendix states a rank condition — "$D_{it}$ takes both values within the unbalanced stratum" — and promises a country-by-country diagnostic.
The current diagnostic computes the share of unbalanced individuals observed with both $D=0$ and $D=1$ across their own observed waves.
That number measures within-individual switching, but the formal rank condition for the pooled-cell model is at the person-period level (not the individual level) and, once the common covariate vector $\gamma$ is brought into the system, is on $D_{it}$ residualized against $x_{it}$ rather than on raw $D_{it}$.
The memo derives both versions of the rank condition, shows when within-individual switching does and does not coincide with the formal requirement, and lays out two diagnostics together with a partialling caveat.

A first draft of the memo treated the 2x2 sub-block on $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ in isolation and stated the boxed condition $\Pr(D_{it}=1 \mid U_i=1) \in (0,1)$ as the formal answer.
That is correct for the sub-block but understates the actual condition once $\gamma$ is jointly estimated; an independent review (saved at [quality_reports/reviews/2026-05-02_rank-condition-memo-review_econ-critic.md](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/quality_reports/reviews/2026-05-02_rank-condition-memo-review_econ-critic.md)) flagged the gap and this revision incorporates the partialling correction.

## Setup

The augmented restricted-GRC equation is
$$y_{it} = \sum_{\underline d \in \mathcal D \setminus \{d_T\}} \mu_{\underline d}\,\mathbbm{1}\{\underline d_i=\underline d\} + \mu_{\mathrm{unb}}\,U_i + \Delta_{\underline d_0}\,D_{it} + \sum_{\underline d \in \mathcal D_S \setminus \{\underline d_0\}} \phi(\mu_{\underline d}-\mu_{\underline d_0})\,D_{it}\,\mathbbm{1}\{\underline d_i=\underline d\} + \kappa_T\,D_{it}\,\mathbbm{1}\{\underline d_i=d_T\} + (\Delta_{\mathrm{unb}}-\Delta_{\underline d_0})\,U_i D_{it} + x_{it}'\gamma + \varepsilon_{it}.$$

Trajectory indicators $\mathbbm{1}\{\underline d_i=\underline d\}$ are defined only for individuals observed in all $T_c$ waves, so $U_i=1$ implies all trajectory indicators are zero.
On the unbalanced stratum the equation collapses to a plain pooled regression:
$$y_{it} = \mu_{\mathrm{unb}} + \Delta_{\mathrm{unb}}\,D_{it} + x_{it}'\gamma + \varepsilon_{it} \qquad (U_i=1).$$

The pooled-cell parameterization adds two free parameters, $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$, indexing the unbalanced stratum.
There are no individual fixed effects in this cell.
Throughout the memo, expectations $E[\cdot]$ are taken over person-periods (so an unbalanced individual observed in $T_i^*$ waves contributes $T_i^*$ rows) — the right object for a stacked individual-period GMM whose Jacobian is the per-period mean.
Cluster-robust inference at the individual level affects the asymptotic variance of $\hat\theta$, not the local rank condition that determines whether $\hat\theta$ exists; it is therefore orthogonal to everything in this memo.
The unbalanced stratum is non-empty in all three samples, so $\Pr(U_i=1) > 0$ is implicit throughout.

## The 2x2 sub-block: $\gamma$ treated as known

The two moment functions that carry information about $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ are
$$g^{(\mu)}_{it}(\theta) = U_i \cdot \varepsilon_{it}(\theta), \qquad g^{(\Delta)}_{it}(\theta) = U_i D_{it} \cdot \varepsilon_{it}(\theta),$$
where $\varepsilon_{it}(\theta) = y_{it} - \mu_{\mathrm{unb}} - \Delta_{\mathrm{unb}} D_{it} - x_{it}'\gamma$ on the unbalanced stratum (with the more general form on the balanced stratum, which the trajectory-block moments handle separately).

The orthogonality condition gives $E[g^{(\mu)}_{it}(\theta_0)] = 0$ and $E[g^{(\Delta)}_{it}(\theta_0)] = 0$.
Local identification of $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ — *taking $\gamma$ as known* — requires that the $2 \times 2$ Jacobian of these two moments with respect to those parameters is full rank at $\theta_0$.

Differentiating,
$$\frac{\partial g^{(\mu)}_{it}}{\partial \mu_{\mathrm{unb}}} = -U_i, \quad \frac{\partial g^{(\mu)}_{it}}{\partial \Delta_{\mathrm{unb}}} = -U_i D_{it}, \quad \frac{\partial g^{(\Delta)}_{it}}{\partial \mu_{\mathrm{unb}}} = -U_i D_{it}, \quad \frac{\partial g^{(\Delta)}_{it}}{\partial \Delta_{\mathrm{unb}}} = -U_i D_{it}^2.$$

Taking expectations and using $D_{it}^2 = D_{it}$ (binary treatment), the relevant block is
$$G = -\begin{pmatrix} E[U_i] & E[U_i D_{it}] \\ E[U_i D_{it}] & E[U_i D_{it}] \end{pmatrix}.$$

Its determinant is
$$\det G = E[U_i] \cdot E[U_i D_{it}] - (E[U_i D_{it}])^2 = E[U_i D_{it}] \cdot \big(E[U_i] - E[U_i D_{it}]\big) = \Pr(U_i=1, D_{it}=1) \cdot \Pr(U_i=1, D_{it}=0).$$

Full rank therefore requires both probabilities to be strictly positive.
Conditional on the unbalanced stratum being non-empty, this is
$$\Pr(D_{it}=1 \mid U_i=1) \in (0,1). \qquad \text{(sub-block rank condition)}$$

This is the condition the appendix is naturally read as stating, and it is correct *as a condition on the sub-block treating $\gamma$ as known*.
It is at the person-period level, not the individual level: it can hold without any unbalanced individual switching, as long as the unbalanced stratum contains both observed-rural and observed-urban person-periods (whether from switchers or from a mix of always-rural and always-urban unbalanced individuals).

## The full system: $\gamma$ is jointly identified

The trajectory-block parameters $(\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}, \kappa_T)$ enter only the balanced-stratum moments and the unbalanced-stratum moments do not depend on them; conversely $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ enter only the unbalanced moments.
The Jacobian is block-diagonal in those two parameter blocks.

The complication is $\gamma$.
The covariate vector $x_{it}$ enters both strata, and the common-$\gamma$ assumption ties them together.
Including $\gamma$, the unbalanced-block Jacobian is
$$G_{\mathrm{unb}} = -E\!\begin{pmatrix} U_i & U_i D_{it} & U_i x_{it}' \\ U_i D_{it} & U_i D_{it} & U_i D_{it} x_{it}' \\ U_i x_{it} & U_i D_{it} x_{it} & x_{it} x_{it}' \end{pmatrix},$$
where the bottom-right block uses the full $x$-moment (which receives contributions from both strata, not just unbalanced).
The local rank condition for $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ in the full system is full rank of the *Schur complement* of the $\gamma$ block.
Equivalently: the residualized regressors $(U_i, U_iD_{it})$ retain rank 2 after linear projection onto $x_{it}$.

This is strictly stronger than the sub-block rank condition.
Concretely, identification of $\Delta_{\mathrm{unb}}$ fails if $D_{it}$ is a deterministic function of $x_{it}$ on the unbalanced stratum even when $D_{it}$ varies on that stratum.
A textbook example: $x_{it}$ contains a region dummy that perfectly distinguishes always-urban from always-rural unbalanced individuals; within $\{U_i=1\}$, every $D=1$ observation has region dummy 1 and every $D=0$ observation has region dummy 0.
The sub-block condition reads as full rank in this case but the full-system condition fails.

The corrected formal rank condition is therefore
$$\boxed{\mathrm{Var}(D_{it} - x_{it}'\beta^* \mid U_i=1) > 0,}$$
where $\beta^*$ is the linear projection of $D_{it}$ on $x_{it}$ within the unbalanced stratum.
In words: $D_{it}$ has positive residual variance after partialling out $x_{it}$ on the unbalanced stratum.
The sub-block condition is the special case in which $x_{it}$ is the constant.
Strictly, the boxed condition pins down $\Delta_{\mathrm{unb}}$; for $\mu_{\mathrm{unb}}$ to also be identified one needs $U_i$ to not be a linear function of $x_{it}$ on the full sample (automatic in any sensible setup, but worth one sentence to flag the asymmetry).

## Three sub-populations among the unbalanced

The unbalanced stratum partitions into three sub-populations defined by what is *observed*:
$\mathcal U_R$ = unbalanced individuals always observed rural ($D_{it}=0$ for all observed $t$);
$\mathcal U_U$ = unbalanced individuals always observed urban ($D_{it}=1$ for all observed $t$);
$\mathcal U_S$ = unbalanced switchers (both values observed across own waves).

The sub-block rank condition holds iff $\mathcal U_S$ is non-empty, or both $\mathcal U_R$ and $\mathcal U_U$ are non-empty.
$\Delta_{\mathrm{unb}}$ then sources its identifying variation from:
- within-individual variation among $\mathcal U_S$ (each switcher contributes both their own $D=0$ and $D=1$ observations);
- between-individual variation across $\mathcal U_R$ and $\mathcal U_U$ (an always-rural individual and an always-urban individual contribute jointly the $D=0$ and $D=1$ observations needed to pin down the slope).

The full-system rank condition adds the requirement that whichever combination of these sources is doing the work, the resulting variation in $D_{it}$ is not collinear with $x_{it}$.

## What the data show

Computed from the unbalanced strata in the three estimation samples (one row per person-period, $U_i=1$ subset):

| Country | Unbalanced individuals | Switchers ($\mathcal U_S$) | Within-switch share |
|---------|-----------------------:|---------------------------:|--------------------:|
| CHN     |                 20,532 |                      1,884 |               9.2\% |
| IDN     |                 26,432 |                      6,917 |              26.2\% |
| TZA     |                  3,170 |                        182 |               5.7\% |

All three within-switch shares are strictly positive, so $\mathcal U_S$ is non-empty and the sub-block rank condition holds in every sample regardless of how $\mathcal U_R$ and $\mathcal U_U$ are distributed.
The TZA share of 5.7\% is small but well away from zero; the formal sub-block condition is binary, not continuous, so $\Delta_{\mathrm{unb}}$ in TZA is precision-limited rather than non-identified *under that condition*.

Three numbers we do not yet have:

1. The urban rate $\Pr(D_{it}=1 \mid U_i=1)$ — the quantity the sub-block condition pins down at the person-period level.
By construction it lies strictly in $(0,1)$ whenever $\mathcal U_S$ is non-empty, or $\mathcal U_R$ and $\mathcal U_U$ are both non-empty (the iff condition above), so the sub-block conclusion (rank condition holds) does not change.
The number is still worth knowing: it tells the reader where the unbalanced sample sits in urban-share terms (e.g., 30\%--40\% of unbalanced person-periods being urban describes a more balanced design than 5\% being urban).
2. The full breakdown $(|\mathcal U_R|, |\mathcal U_U|, |\mathcal U_S|)$ — important for TZA in particular.
With only 3,170 unbalanced TZA individuals and only 182 switchers, the reader cannot tell from the table whether between-individual variation in TZA comes from a meaningful number of always-urban unbalanced individuals or from one or two outliers.
3. The partial $R^2$ of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$ — equivalently, the share of within-stratum variation in $D_{it}$ left after partialling out $x_{it}$.
This is the operational form of the full-system rank condition: a partial $R^2$ near 1 (most variation in $D_{it}$ explained by $x_{it}$ on the unbalanced stratum) means $\Delta_{\mathrm{unb}}$ is being identified off a very thin residualized signal; a partial $R^2$ around 0.1--0.3 with $x_{it}$ matched to the main-estimation covariate vector is the kind of value that comfortably confirms the rank condition.
Reporting the partial $R^2$ rather than the raw residual variance has two advantages: it is unit-free (lives in $[0,1]$), and the threshold question ("how far from collinear is far enough?") is more naturally answered.

Within-switcher variation has an additional robustness property worth flagging.
A within-individual transition from $D=0$ to $D=1$ partials out individual-level time-invariant covariates by construction, so the contribution of $\mathcal U_S$ to identification is automatically residualized against any time-invariant component of $x_{it}$.
Between-individual variation across $\mathcal U_R$ and $\mathcal U_U$ does not partial out anything and is the channel most exposed to collinearity with location dummies, sample-frame variables, or other time-invariant components of $x_{it}$.

## Two readings of the diagnostic

The two diagnostics answer different questions.

**Reading 1: report what the rank condition formally requires (after partialling).**
The actual full-system rank condition is positive residual variance of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$.
Two diagnostics together give a defensible read on this:
the urban rate $\Pr(D_{it}=1 \mid U_i=1)$ for the marginal variation;
and the partial $R^2$ of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$, with $x_{it}$ matched to the main-estimation covariate vector.
The urban rate alone is naturally read as the sub-block condition, which is *necessary but not sufficient* for the full-system condition; the partial-$R^2$ value closes the gap.

**Reading 2: report what makes the parameter credible, not just identified.**
The orthogonality assumption is doing a lot of work; if a substantial fraction of $\Delta_{\mathrm{unb}}$'s identifying variation is between-individual, then unbalanced individuals who happen to live in always-urban locations contribute differently than unbalanced individuals who happen to live in always-rural ones.
Selection into always-rural vs always-urban among unbalanced individuals could be driven by exactly the same unobserved comparative-advantage channels the paper otherwise tries to address through trajectory cells.
Within-individual switching among unbalanced individuals is the kind of variation that, if abundant, partially insulates $\Delta_{\mathrm{unb}}$ from this selection concern even if the orthogonality condition is mildly misspecified.
As a side benefit, within-individual variation automatically partials out any time-invariant component of $x_{it}$.

The two readings answer different questions.
Reading 1 answers "is $\Delta_{\mathrm{unb}}$ identified under the appendix's assumptions?"
Reading 2 answers "how would $\Delta_{\mathrm{unb}}$ behave if the orthogonality assumption were partially wrong?"

Both questions matter; the cleanest package reports both.

## Connection to Verdier (2020)

Verdier's individual-fixed-effects parameterization on observed periods has a rank condition at the individual level: each individual contributing to the LCA slope must be observed in 2+ periods with $D_{it}$ taking both values across those periods.
Within-individual switching is necessary in his setup because the individual fixed effect partials out everything between individuals.
Our pooled-cell parameterization has no person FE on the unbalanced cell, so the formal rank condition is correspondingly weaker — variation in $D_{it}$ on the unbalanced stratum, residualized against $x_{it}$, is enough.
The flip side is that the pooled-cell estimator has to lean more heavily on the orthogonality assumption to keep between-individual variation interpretable as $\Delta_{\mathrm{unb}}$.

## Recommendation

The cleanest path is to report the urban rate as the headline diagnostic (matches the sub-block condition exactly), the within-switch share as a credibility supplement, and add one sentence stating the partialling caveat plus a numeric check that $D_{it}$ is not collinear with $x_{it}$ on $\{U_i=1\}$.
A draft replacement for the closing paragraph of the short appendix:

> Identification of $\Delta_{\mathrm{unb}}$ requires variation in $D_{it}$ among unbalanced person-periods *after partialling out* $x_{it}$: if $D_{it}$ is collinear with $(U_i, x_{it})$ on the unbalanced stratum, the $U_iD_{it}$ moment carries no residual signal and $\Delta_{\mathrm{unb}}$ drops out.
> The marginal share of unbalanced person-periods with $D=1$ is `\unbUrbanRateCHN`\% in China, `\unbUrbanRateIDN`\% in Indonesia, and `\unbUrbanRateTZA`\% in Tanzania, well inside $(0,1)$ in every sample.
> With $x_{it}$ matched to the main-estimation covariate vector, $D_{it}$ retains `\unbResidShareCHN`\% of its within-stratum variation in China, `\unbResidShareIDN`\% in Indonesia, and `\unbResidShareTZA`\% in Tanzania after partialling out $x_{it}$---ample residualized variation to identify $\Delta_{\mathrm{unb}}$.
> A stronger diagnostic, useful for assessing the credibility (not the identification) of $\Delta_{\mathrm{unb}}$ under partial misspecification of the orthogonality assumption, is the share of unbalanced individuals observed with both $D=0$ and $D=1$ across their own waves: `\unbShareCHN`\% in China, `\unbShareIDN`\% in Indonesia, and `\unbShareTZA`\% in Tanzania.
> The smaller within-switch shares for China and Tanzania mean $\Delta_{\mathrm{unb}}$ is identified primarily off between-individual variation in those samples; in Indonesia about a quarter of unbalanced individuals contribute within-individual variation directly.

If only one number is preferred, the urban rate is the right headline — but it should not be sold as "the rank condition" in isolation, because the formal condition involves residualized variation.
The right framing is "the sub-block condition holds, and the partial-$R^2$ check confirms the full-system condition holds."

If the within-switch share alone is preferred (the current setup), then the appendix's rank condition should be tightened to read "$D_{it}$ varies *within* unbalanced individuals" and the proof should note that this is sufficient but not necessary for the formal rank condition.
That tightening is honest but slightly weaker than what the model actually requires, and within-individual variation does not on its own guarantee rank in the presence of $x_{it}$ collinearity (a within-switcher whose own $x_{it}$ moves perfectly with $D_{it}$ across waves contributes nothing to residual variance).

## Action items

- Decision: which diagnostic to feature (urban rate, within-switch share, or both).
- Code: extend [RP7/scripts/1b_unbalanced_rank_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/RP7/scripts/1b_unbalanced_rank_diagnostic.do) to compute (a) the urban rate $\Pr(D_{it}=1\mid U_i=1)$, (b) the always-rural / always-urban / switcher decomposition $(|\mathcal U_R|, |\mathcal U_U|, |\mathcal U_S|)$, and (c) the residual share $1 - R^2$ of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$ with $x_{it}$ matched to the main-estimation covariate vector (year FE, demographics, and any other regressors the main spec includes — not a stripped-down version, otherwise the check is too easy). Output corresponding macros (`\unbUrbanRateCHN`, `\unbAlwaysUrbanCHN`, `\unbAlwaysRuralCHN`, `\unbResidShareCHN`, etc.). The new diagnostics complement the existing within-switch share macros (`\unbShareCHN`, `\unbCountCHN`, `\unbBothCHN`) — they do not replace them.
- Prose: replace the current closing paragraph in [paper/unbalanced_proposition_short.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition_short.tex) according to the chosen reading; tighten the rank-condition statement in [paper/unbalanced_proposition.tex](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/paper/unbalanced_proposition.tex) so it does not equate the formal condition with the within-switch share without acknowledging the gap.
- Numerical check: confirm that the partial $R^2$ of $D_{it}$ on $x_{it}$ within $\{U_i=1\}$ is bounded away from 1 in all three samples; report the actual values in the appendix (not just an assertion that "we verified") so the reader can replicate.
