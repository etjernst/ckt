# Followup: methods findings for `unbalanced_proposition.tex`

**Context:** response to user's questions on F1, F2, F3, F4, F5, F6, F7, F8, F10 from [methods review](file:///C:/git/ckt/docs/reviews/2026-04-22-unbalanced_proposition-methods.md).
**Date:** 2026-04-22

---

## Honest accounting: what I underplayed

Before fixes: a concession on F5 and F8. The restricted GRC is written (`main.tex:396-403`) as

$$y_{it} = \sum_{\underline d \in \mathcal D \setminus\{d_T\}} \mu_{\underline d}\mathbbm 1\{\underline d_i=\underline d\} + \Delta_{\underline d_0} D_{it} + \sum_{\underline d \in \mathcal D_S\setminus\{\underline d_0\}} \phi\,(\mu_{\underline d}-\mu_{\underline d_0})\,D_{it}\mathbbm 1\{\underline d_i=\underline d\} + \big(\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})\big)D_{it}\mathbbm 1\{\underline d_i=d_T\} + \varepsilon_{it}.$$

The products $\phi\cdot\mu_{\underline d}$ make this **nonlinear in parameters**. FWL is an OLS identity, and its extension to two-step linear GMM (Newey-McFadden 1994, Sec. 6) requires linearity. For nonlinear GMM, FWL does not hold even asymptotically --- there is no partialling-out identity. My review flagged F5 as "apply with care / asymptotic only", but that was understated: the entire FWL framing of Step 1 in the current proof should be dropped, not tightened.

This also affects F8: the proposition's claim to deliver $\{(\mu_{\underline d},\Delta_{\underline d})\}_{\underline d\in\mathcal D}$ is sloppy because $(\mu_{\underline d},\Delta_{\underline d})$ are not all free parameters. The actual parameter vector is $(\Delta_{\underline d_0}, \phi, \gamma, \alpha, \pi)$ plus $\{\mu_{\underline d}:\underline d\in\mathcal D\setminus\{d_T\}\}$ plus the composite $\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$. Implied returns $\Delta_{\underline d}$ for every $\underline d$ are delivered by plug-in under LCA, not estimated directly.

With that said, here are the proposed fixes.

---

## Proposed fix: F1 (MAR omits $\varepsilon_{it}$)

Agreed that splitting adds clutter for little gain. The cleanest fix is to put $\varepsilon_{it}$ inside the single MAR statement:

**Proposed replacement at `paper/unbalanced_proposition.tex:46-49`:**

```latex
\begin{assumption}[Missing at random]
\label{ass:mar}
$U_i \perp (\theta_i,\tau_i,\{\nu_{it}^l\}_{t,l},\{\varepsilon_{it}\}_t)\mid w_i$,
where $w_i$ denotes a vector of covariates observed for every individual
(baseline demographics and wave-of-first-observation indicators).
\end{assumption}
```

This also handles F3 (see below): the conditioning set is no longer the problematic "full history $x_{i1},\dots,x_{iT_c}$" that isn't observed for unbalanced individuals, but a set $w_i$ that is observed for everyone.

**Awaiting your approval before editing.**

---

## Proposed fix: F2 (match the restricted GRC exactly, add unbalanced extension additively)

**Proposed replacement at `paper/unbalanced_proposition.tex:21-35`:**

```latex
\begin{equation}
\label{eq:restricted-grc-unbalanced}
\begin{aligned}
y_{it} =\; &
\sum_{\underline d\in\mathcal D\setminus\{d_T\}} \mu_{\underline d}\,\mathbbm 1\{\underline d_i=\underline d\}
+ \Delta_{\underline d_0} D_{it} \\
& + \sum_{\underline d\in\mathcal D_S\setminus\{\underline d_0\}} \phi\,(\mu_{\underline d}-\mu_{\underline d_0})\,D_{it}\,\mathbbm 1\{\underline d_i=\underline d\} \\
& + \Big(\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})\Big)D_{it}\,\mathbbm 1\{\underline d_i=d_T\} \\
& + \alpha\,U_i + \pi\,U_i D_{it} + x_{it}'\gamma + \varepsilon_{it}.
\end{aligned}
\end{equation}
```

The pooled extension is the original restricted GRC of `main.tex:397-403` with $\alpha U_i + \pi U_i D_{it}$ added. This also removes the LCA re-derivation (lines 36-38 of the current proposition), which was redundant with the restricted GRC.

**Awaiting your approval before editing.**

---

## F3: How to fix the conditioning set

The current assumption conditions on $x_{i1},\dots,x_{iT_c}$ --- but unbalanced observers don't have $x$ at every wave, so the conditioning set is undefined for the exact group the assumption targets.

Three realistic options, ranked by economic cleanness:

1. **Condition on a baseline $w_i$ observed for everyone.** This is what the proposed F1 fix does. $w_i$ could be birth year, sex, first-wave region, and an indicator for wave of first observation. MAR then says attrition depends on these observable pre-determined variables but not on structural unobservables or transitory shocks. This is the Rubin (1976) / Wooldridge (2002) convention for unbalanced panels.

2. **Condition on the observed covariate history $\{x_{it}:t\in\mathcal T_i\}$ plus $\mathcal T_i$ itself.** Econometrically correct but notationally awkward (random conditioning set). Wooldridge-style.

3. **Condition on wave-1 covariates $x_{i,1}$.** Works only if everyone is observed in wave 1 (no aging-in). Mentioned in the main.tex:489-492 text; attrition in all three panels is described as post-wave-1, and wave 1 is the baseline. If that is accurate for CFPS/IFLS/TZNPS, this is the simplest fix.

**Recommendation:** option 1 (baseline $w_i$). It is economically defensible, notationally clean, and avoids committing to "everyone observed in wave 1" which has exceptions for aging-in panels.

---

## F4 vs F7: different assumptions, both need reconciliation

These are genuinely different:

- **F4** says: the MAR-style assumption in the proposition and the one in the `main.tex:455` footnote ("attrition is independent of $\varepsilon_{it}$ conditional on $D_{it}$ and $x_{it}$") are not the same assumption. They condition on different variables (full-history $x$ vs. $(D_{it}, x_{it})$), and they list different things as independent (structural $(\theta,\tau,\nu)$ vs. transitory $\varepsilon$). The two need to agree.

- **F7** says: the `main.tex:455` footnote has a **second** condition --- "(ii) covariate effects on consumption are common across balanced and unbalanced individuals" --- that the proposition silently imposes through the single $\gamma$ parameter in its equation but never states as an assumption.

Together, both conditions need to be formal assumptions in the proposition. Proposed additional assumption (alongside the revised MAR):

```latex
\begin{assumption}[Common covariate effects]
\label{ass:common-gamma}
The partial effect of $x_{it}$ on $y_{it}$ is the same in the balanced and
unbalanced strata; equivalently, the covariate block in
\eqref{eq:restricted-grc-unbalanced} has a single coefficient vector $\gamma$.
\end{assumption}
```

Then the footnote at `main.tex:455` should be rewritten to reference the proposition:

> We include individuals with missing waves under Assumptions \ref{ass:mar} and \ref{ass:common-gamma}. Proposition \ref{prop:pooling} shows that the resulting pooled estimator is consistent and weakly more efficient than the estimator restricted to balanced observers.

---

## F5: how to fix the proof (this is the big one)

Drop the FWL/numerical-equivalence framing entirely. Replace with a direct NLGMM argument. The proof outline becomes:

**Step 1 (validity of the pooled moments).** Under Assumption \ref{ass:mar} and Assumption \ref{ass:common-gamma}, the full moment vector
$$g(z_i,\theta) = \begin{pmatrix} \varepsilon_{it} \cdot \mathbbm 1\{\underline d_i=\underline d\} \\ \varepsilon_{it} \cdot D_{it}\mathbbm 1\{\underline d_i=\underline d\} \\ \varepsilon_{it} \cdot U_i \\ \varepsilon_{it} \cdot U_i D_{it} \\ \varepsilon_{it} \cdot x_{it} \end{pmatrix}$$
has expectation zero at the true parameter $\theta_0$, on both strata.

- On the balanced subsample: Assumption (A1)-(A5) of Section \ref{subsec:empirical-model} deliver $E[\varepsilon_{it}|\underline d_i, D_{it}, x_{it}] = 0$.
- On the unbalanced subsample: the switcher moments are **identically zero** because $\mathbbm 1\{\underline d_i=\underline d\}$ is zero by construction. The remaining moments ($U_i$, $U_i D_{it}$, $x_{it}$) have expectation zero under MAR, which gives $E[\varepsilon_{it}|U_i=1, D_{it}, x_{it}]=0$.

**Step 2 (identification and consistency).** The pooled moment system identifies $\theta_0$ (the balanced block identifies $(\mu, \phi, \Delta_{\underline d_0})$ and the always-urban composite, exactly as in the restricted GRC; the additional unbalanced moments identify $(\alpha, \pi)$; the $x$-block identifies $\gamma$). Standard NLGMM consistency and asymptotic normality follow from Hansen (1982) and Newey-McFadden (1994, Thm 2.6 and Thm 3.4), given the usual regularity conditions.

**Step 3 (relation to the balanced-only estimator).** This replaces the old FWL argument. Because the switcher moments are identically zero on the unbalanced subsample, the first-order conditions for $(\mu, \phi, \Delta_{\underline d_0})$ under the pooled estimator are **algebraically identical** to the first-order conditions under the balanced-only estimator, except that they are evaluated at $\hat\gamma^{\text{pool}}$ rather than $\hat\gamma^{\text{bal}}$. So $(\hat\mu^{\text{pool}}, \hat\phi^{\text{pool}})$ differs from $(\hat\mu^{\text{bal}}, \hat\phi^{\text{bal}})$ only through the choice of $\hat\gamma$. This is the honest replacement for the old "block-separates via FWL" claim, and it holds exactly for the nonlinear model.

**Step 4 (efficiency --- this is F6).** By the partitioned-information argument below.

---

## F6: efficiency via the partitioned information matrix

Let the asymptotic information matrix of the pooled NLGMM estimator have block form
$$I = \begin{pmatrix} I_{\vartheta\vartheta} & I_{\vartheta\gamma} \\ I_{\gamma\vartheta} & I_{\gamma\gamma} \end{pmatrix},$$
where $\vartheta=(\mu,\phi,\Delta_{\underline d_0},\alpha,\pi)$ collects everything except $\gamma$. By partitioned inversion, the asymptotic variance of $\hat\vartheta$ is
$$\text{AVar}(\hat\vartheta) = \Big(I_{\vartheta\vartheta} - I_{\vartheta\gamma}\,I_{\gamma\gamma}^{-1}\,I_{\gamma\vartheta}\Big)^{-1}.$$

Two observations:

- Because the switcher moments are identically zero on $\{U_i=1\}$, the score for $\mu, \phi, \Delta_{\underline d_0}$ is also zero on $\{U_i=1\}$. So $I_{\mu\mu}, I_{\phi\phi}, I_{\mu\phi}$ are **unchanged** between the pooled and balanced-only estimators. Only the $(\alpha, \pi)$ entries of $I_{\vartheta\vartheta}$ are new in the pooled version.
- $I_{\gamma\gamma}^{\text{pool}} \geq I_{\gamma\gamma}^{\text{bal}}$ because the $x$-block contribution is additively larger on the pooled sample. Under the common-$\gamma$ assumption and iid-across-strata errors, the inequality is typically strict.

So the efficiency gain comes entirely through **smaller $I_{\gamma\gamma}^{-1}$ in the partitioned-inverse correction**, which makes the matrix $I_{\vartheta\vartheta} - I_{\vartheta\gamma}I_{\gamma\gamma}^{-1}I_{\gamma\vartheta}$ larger, hence $\text{AVar}(\hat\vartheta)$ smaller.

**Important caveat:** the gain is strict only when $I_{\vartheta\gamma} \neq 0$ --- i.e., when the covariates $x_{it}$ are informative about $\vartheta$. If $x_{it}$ is asymptotically orthogonal to the trajectory indicators (unlikely in practice), there is no efficiency spillover. The efficiency claim should therefore be stated as a weak inequality, with strictness contingent on $I_{\vartheta\gamma}\neq 0$.

This replaces the current proof's hand-wavy "it uses strictly more observations, therefore smaller variance" argument.

---

## F8: what the estimator actually delivers

The clean statement: the pooled NLGMM estimator is consistent and asymptotically normal for
$$\theta_0 = \big(\underbrace{\Delta_{\underline d_0}, \phi}_{\text{CAT}}, \underbrace{\{\mu_{\underline d}\}_{\underline d\in\mathcal D\setminus\{d_T\}}}_{\text{trajectory means}}, \underbrace{\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})}_{\text{always-urban composite}}, \underbrace{\alpha,\pi,\gamma}_{\text{nuisance}}\big).$$

Under the LCA restriction, the trajectory-specific returns
$$\Delta_{\underline d} = \Delta_{\underline d_0} + \phi\,(\mu_{\underline d}-\mu_{\underline d_0}), \qquad \underline d \in \mathcal D,$$
are continuous functions of $\theta_0$, so $\hat\Delta_{\underline d}$ is consistent and asymptotically normal by the delta method. **This is how the proposition should state the claim** --- not as "consistent for $\{(\mu_{\underline d},\Delta_{\underline d})\}$".

Note the always-urban composite cannot be decomposed into separate $\mu_{d_T}$ and $\Delta_{d_T}$ without further restrictions; LCA alone does not identify them separately.

---

## F10: "instruments" in GMM

The paper itself uses "instrument vector $z_{it}$" at `main.tex:448-450`, and that is defensible terminology in the Hansen (1982) tradition for moment vectors of the form $E[z_{it}\cdot\varepsilon_{it}]=0$. So at the paper-internal level, the terminology is consistent and fine.

Strictly speaking, though, the $z_{it}$ here are not "instruments" in the exclusion-restriction sense --- the trajectory indicators, $D_{it}$, and their interactions are **regressors in the equation**, not external variables excluded from it. In GMM textbook language, these are "included instruments" or, more neutrally, components of the "moment vector." The more precise terminology would be "moment function" $g(z_i,\theta) = z_i \cdot \varepsilon_{it}(\theta)$, with $z_i$ a "basis vector" or "weighting vector."

For internal consistency with the paper, "instrument vector" is fine. If you want to be strictly correct, "moment vector" or "score instruments" would be more precise.

---

## Plan

If you approve the F1 and F2 edits above, I'll:

1. Make the two equation/assumption edits to `paper/unbalanced_proposition.tex`.
2. Add Assumption 2 (common covariate effects) (F7).
3. Rewrite the conditioning set to use $w_i$ (F3).
4. Replace the proof with the four-step NLGMM version (F5, F6).
5. Fix the proposition statement to reference $\theta_0$ correctly and invoke the delta method for $\Delta_{\underline d}$ (F8).
6. Revise the footnote at `main.tex:455` to reference the proposition (F4).
7. Add a brief attrition-literature reference (F9 from the original review, not discussed above).
8. Run the writing-fixes as a separate commit after the math is settled (residualised, misspecification, two-vs-three, emph, etc.).

This is a substantial rewrite --- probably 75% of the file is touched. Before I start, I want your explicit sign-off on the F1, F2, and F3 proposals above.
