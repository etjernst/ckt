# Econometrics-critic review: delta-inversion-extension spec

**Memo under review:** [`quality_reports/specs/2026-04-29-delta-inversion-extension.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-04-29-delta-inversion-extension.md)
**Reviewer:** econometrics-critic agent (fresh context).
**Date:** 2026-04-29.
**Verdict:** revise.

This file records the critic's report verbatim plus the responding analysis where I disagreed.

---

## Critic's verdict and findings (verbatim)

**[CRITICAL, HIGH] Lens 1 (identification): paper line 401 vs Stata vs memo (2).**
The third line of the restricted-GRC equation in `paper/main.tex:401` writes the always-mover composite as $\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$, with no $\beta D_{it}$ term.
This omits $\Delta_{\underline d_0}$ from the always-mover return.
Stata at `0_programs.do:1722-1723` matches the paper line 401 (no $\beta$ inside the always block).
But Stata's `nlcom` for $\Delta_{d_T}$ at line 1768 puts $\beta$ back in.
The memo's eq (2) follows the `nlcom`. Either (a) the paper line 401 is missing a term, (b) the Stata GMM is mis-specified relative to the paper's model, or (c) Stata's `_b[kappa]` is a re-parameterization of $\mu_{d_T}$ that absorbs $\beta$, in which case $\hat\alpha_{d_T}$ from the auxiliary OLS does **not** map to the same object that Stata's `_b[kappa]` maps to, and equation $(2')$ is wrong as stated.
This must be resolved before implementation.

**[MAJOR, MEDIUM] Lens 1: auxiliary OLS does not partial controls the GMM way (Q1).**
In `lca_inversion.py:114-116` controls enter as level shifters added to the design matrix, no interaction with $D$ or with trajectory dummies.
The Stata GMM at `0_programs.do:1724` puts $xb$ as a separate additive term, also level-shifters.
So at first pass the partialling is the same: both subtract a common $X\gamma$ from $y$.
But the auxiliary OLS includes $X$ on the same $\hat\alpha_{d_T}$ design where $d_T$ is observed only at $D=1$.
That means $\hat\alpha_{d_T}$ is the within-$D=1$ residual mean for $d_T$ after partialling controls evaluated **at the always-trajectory's covariate distribution**, while Stata's $\mu_{d_T}$ is the same residual mean.
Mechanically the projection is identical when the saturated trajectory dummies span the same column space as the GMM's $\mu$ free parameters and controls are exogenous.
Verdict: **probably equal in expectation** but only after one verifies that (i) `unbalanced` and `unbalanced_choice` are also in the GMM (they are not visible in the memo's Stata snippet---needs check), and (ii) controls are truly additive in both.
A small finite-sample wedge from cluster-robust vs GMM-cluster vcov will appear regardless.
The validation step (point estimate match at $\hat\phi$) catches this; flag it as a precondition gate, not as a downstream "verify after" step.

**[MAJOR, HIGH] Lens 3: Wald test asymptotics under profile substitution.**
For $\Delta_{d_N}$ and $\Delta_{\text{avg}}$ the proposal is **algebraically identical** to a constrained-Wald on the linear restriction $c_0(b)+\phi c_1(b)=\delta^*$ added to $g(b,\phi)=0$, profiled over $\phi$.
Asymptotic equivalence to constrained-LR / score holds under standard regularity.
For $\Delta_{d_T}$, the Mobius profile is smooth except at $\delta_T^* = \hat\alpha_{d_T}-\hat\alpha_{\text{base}}$ and at $1+\phi=0$.
Near these points the delta-method variance explodes; this is the **right** behavior for a weak-ID-robust test (it correctly fails to reject at unidentified points), but the dof of $J_R$ understates conservativeness near the singularity because the effective number of restrictions changes.
Standard practice would still use $\chi^2_{J_R}$; flag as MINOR.

**[MAJOR, HIGH] Lens 4: Mobius-image-of-phi-CI shortcut (Q2).**
Mapping the existing $\phi$ CI through $(2')$ does **not** in general yield a valid $(1-\alpha)$ CI for $\Delta_{d_T}$.
It does iff (i) $\Delta_{d_T}(\phi,b)$ at the *fixed* OLS point estimate $b=\hat b$ is a monotone (or at least 1-1 within each branch) function of $\phi$, **and** (ii) the OLS coefficients $\hat\alpha_{d_T}$ and $\hat\beta_{\text{base}}$ are treated as known.
Condition (i) holds piecewise.
Condition (ii) is **violated**: $\hat\alpha_{d_T}$ has its own sampling variance, and ignoring it understates the CI width.
The shortcut is therefore an **anti-conservative approximation** of the formal Wald CI.
**Recommendation: implement the formal Wald.**

**[MAJOR, MEDIUM] Lens 1: $\hat\alpha_{d_T}$ as $\kappa_{d_T}$ in the presence of unbalanced indicators.**
`fit_auxiliary_ols` adds `unbalanced` and `unbalanced_choice` columns alongside the trajectory dummies.
For the always-trajectory, the projection of $y$ onto $\alpha[d_T]$ is the residualized urban mean **after** removing the unbalanced shift, not the raw $\kappa_{d_T}$.
This is fine **if** the GMM does the same residualization, but the GMM at `0_programs.do:1719-1733` uses `never `switcher_traj'` in the $\mu$ block---no `always`---and the always block carries no `unbalanced` interaction.
This is a real wedge between OLS and GMM identification of $\kappa_{d_T}$ that the memo does not address.

**[MAJOR, MEDIUM] Lens 4: singularity at $\phi=-1$ for IDN.**
The deeper issue is that $\phi=-1$ corresponds to $b_U=0$ in the structural model, which is a model breakdown.
A bounded-parameter-space Wald (e.g., truncated at $\phi > -1$) is one alternative; flagging the singularity in the paper writeup is another.
The memo's "honestly produce unbounded CI" is defensible but should be paired with a sentence explaining the structural meaning of $\phi=-1$.

**[MINOR, HIGH] Edge cases (Section 7 of the memo).**
$J_R=1$ is **not** the same as the memo's $J_R=0$.
With one non-base switcher, the Wald has $J_R=1$ (well-defined chi-squared with 1 df).
The memo handles $J_R=0$ correctly but should explicitly state $J_R=1$ is fine.
$c_1(b)=0$ handling: the memo says "singleton CI if LCA holds, empty otherwise"---correct in population; in sample needs a numerical tolerance, not just exact zero.

**[MINOR, MEDIUM] Lens 3: $\Delta_{\text{avg}}$ weighting (Q3).**
The shares $\pi_s$ depend on which sample defines them.
Use the **same** sample for both shares and the OLS to avoid a moving estimand.

## Direct answers to memo Section 8

- **Q1 (auxiliary-OLS-vs-GMM identification of $\kappa_{d_T}$):** Likely consistent in expectation, but verify (a) `unbalanced` and `unbalanced_choice` are in both, and (b) controls are truly additive in both.
Validation step 1 (point-estimate match at $\hat\phi$) is the gate.
- **Q2 (Mobius-image vs formal Wald):** Not acceptable.
Anti-conservative because it ignores the sampling variance of $\hat\alpha_{d_T}$ and $\hat\beta_{\text{base}}$.
**Implement the formal Wald.**
- **Q3 ($\Delta_{\text{avg}}$ weighting):** Same sample for both.
Pick the auxiliary-OLS sample if validation step 1 reproduces Stata's point estimate; otherwise the GMM sample.
- **Q4 (singularity handling):** Option (c) "report a multi-island CI honestly" is the journal-grade choice.
Report as a union of intervals separated by the $\phi=-1$ singularity, with a textual flag.

---

## Author response

The CRITICAL flagged by the critic is a **misreading of the paper equation**.
The critic claimed paper line 401 omits $\beta D_{it}$ from the always-mover composite.
But the equation has *three* terms that touch always-movers, not one.
The first line at `paper/main.tex:398` includes `+ Delta_{d_0} D_{it}` which contributes $\beta$ universally across all $D=1$ observations, including always-movers.
The third line at `paper/main.tex:401` gives the always-movers' *marginal* contribution beyond that universal $\beta$.
Total always-mover fit at $D_{it}=1$:

$$\beta + \mu_{d_T} + \phi(\mu_{d_T} - \mu_{d_0}) = \mu_{d_T} + \Delta_{d_T} = \kappa_{d_T} \text{ (paper notation, observed urban mean)}$$

This matches the Stata GMM at `0_programs.do:1719--1733`, where the universal `Delta_base*choice` adds $\beta$ for all $D=1$ observations and the always-block adds the rest.
And the Stata `nlcom` at line 1768 correctly extracts $\Delta_{d_T} = \beta + \phi(\mu_{d_T} - \mu_{d_0})$.
**Paper, Stata, and memo eq (2) are all internally consistent.**

The other MAJOR / MINOR findings stand and should be incorporated into a revision:

1. **Formal Wald, not Mobius shortcut.** Drop Section 5's "alternative framing to consider" paragraph.
Implement the Wald-with-delta-method for all three parameters.
2. **Multi-island CI handling for $\Delta_{d_T}$.** Make explicit in Section 5: when the $\phi$ inversion CI crosses $-1$, the $\Delta_{d_T}$ CI is reported as a union of intervals separated by the singularity, with a textual flag.
3. **$J_R = 1$ wording.** Clarify Section 4: $J_R = 1$ (one non-base switcher) is fine; the existing $\phi$ inversion handles it.
4. **$c_1(b) = 0$ tolerance.** Add a numerical tolerance for the degenerate case.
5. **$\Delta_{\text{avg}}$ sample consistency.** Use the same sample for the OLS and the share weights.
6. **Validation step as a gate, not just verify-after.** The auxiliary-OLS-vs-GMM controls partialling concern is resolved by reproducing Stata's `nlcom` point estimate at $\hat\phi$ before any inversion CI is reported.
Promote validation step 1 to a precondition.
7. **Structural meaning of $\phi = -1$.** Worth a sentence in the paper writeup that explains why the model breaks down at $\phi = -1$ (corresponds to $b_U = 0$, urban returns vanishing in the comparative-advantage decomposition).

After these incorporations, the spec is ready for implementation. Estimated revision cost: ~30 minutes.
