# Fresh-eyes review: unbalanced-panel pooling proof

**Date:** 2026-04-23
**Files under review:**
- `paper/unbalanced_proposition.tex` (integrated, v2 revisions, commit 50866a6)
- `paper/main.tex` lines 454--456 (footnote in identification section) and 789--795 (robustness section)
- Reference: `explorations/unbalanced_proposition.tex` (earlier exploratory draft)
- Reference: `scripts/0_programs.do` `run_grc` (lines 1538--1664), `handle_trajectory_groups` (195), `i.trajectory=999` (1217)

This memo re-reads the proof with no prior commitment and checks it against what the manuscript text claims. Findings below are grouped by severity.

---

## 1. What the proof actually establishes

Proposition~\ref{prop:pooling} in the current integrated version delivers three claims:

(i) under (A1)--(A5) + MAR ($U_i \perp (\theta_i, \tau_i, \{\nu_{it}^l\}, \{(x_{it},\varepsilon_{it})\}_{t\in\mathcal{T}_i}) \mid w_i$) + common-$\gamma$, the two-step GMM estimator of the augmented system \eqref{eq:restricted-grc-unbalanced} is $\sqrt{n}$-consistent and asymptotically normal for the full parameter vector $\theta_0$;

(ii) the trajectory-specific returns $\Delta_{\underline d} = \Delta_{\underline d_0} + \phi(\mu_{\underline d}-\mu_{\underline d_0})$ inherit consistency and asymptotic normality by the delta method;

(iii) the pooled asymptotic variance of the sub-vector $\vartheta^{\text{bal}}$ shared with the balanced-only estimator is weakly smaller, with strict inequality when $I_{\vartheta\gamma}\neq 0$.

These are the right targets for this proposition. The proof is well-structured (four steps, each short) and the theorem environment aliases in the preamble appear to work.

---

## 2. CRITICAL --- one text claim overshoots the proof

**Location:** `paper/main.tex:791`.

> "Proposition~\ref{prop:pooling} in Appendix~\ref{app:pooling} shows that this pooling is consistent under our identifying assumptions and a standard missing-at-random condition on attrition, **and that the balanced-panel trajectory estimates remain consistent even when attrition in the unbalanced stratum is non-ignorable**."

The proof does not establish the bolded clause. Step 3 proves an asymptotic partialling-out equivalence that holds **at the truth** --- i.e., conditional on $\hat\gamma^{\text{pool}} \overset{p}{\to} \gamma$. The Remark after the proof makes the caveat explicit: the bias-robustness conclusion holds "whenever $\hat\gamma^{\mathrm{pool}}\overset{p}{\to}\gamma$." That precondition is exactly what fails if MAR fails in the unbalanced stratum --- if $U_i$ depends on $(\theta_i, \nu_{it}^l)$ conditional on $w_i$ and covariates do not absorb the dependence, $\hat\gamma^{\text{pool}}$ is generally inconsistent.

So the implication chain is: MNAR $\Rightarrow$ generically $\hat\gamma^{\text{pool}} \not\to \gamma$ $\Rightarrow$ the remark's "whenever" precondition fails $\Rightarrow$ the bias in $\hat\Delta_{\underline d}$ is no longer of smaller order. The text's "even when attrition is non-ignorable" claim is therefore unsupported by what the proposition proves.

There is a weaker property the proof does support: the block structure of the information matrix means the unbalanced stratum's contribution to $\hat\Delta_{\underline d}$ enters only through $\hat\gamma$ (and period shifters absorbed in $\gamma$). If one is willing to assume that $\gamma$ is identifiable from the balanced stratum alone at the true value --- a strong assumption that essentially says covariate effects are over-identified --- then one can argue the balanced-stratum moments pin down $\gamma$ and the unbalanced stratum's non-ignorability doesn't contaminate the balanced-trajectory estimates. This is **not** what the proof shows, and it is not obviously what one would want to claim.

**Recommendation:** replace lines 790--791 with something like:

> "Proposition~\ref{prop:pooling} in Appendix~\ref{app:pooling} shows that this pooling is consistent under our identifying assumptions and a standard missing-at-random condition on attrition, and is weakly more efficient than the balanced-only alternative. The unbalanced stratum affects the trajectory estimates only through the covariate coefficients $\gamma$, so the empirical gap between pooled and balanced-only trajectory estimates (Tables...) is a joint test of MAR and common-$\gamma$."

This matches what the proposition + second remark actually deliver and drops the non-ignorability claim.

---

## 3. MAJOR --- the bare $D_{it}$ moment is not addressed in Step 1

**Location:** `paper/unbalanced_proposition.tex:108--132` (Step 1, moment validity).

The instrument vector in the Stata implementation includes `choice` (= $D_{it}$) on **every** observation --- balanced and unbalanced (see `run_grc`, `instruments(... never switcher_* choice always_choice switcher_*_choice ...)`). Step 1 enumerates $z_{it}$ as including "the urban indicator $D_{it}$", which is correct, but then treats the unbalanced-subsample moment contribution as coming only from "$(U_i, U_i D_{it}, x_{it})$" whose expectations vanish by MAR + common-$\gamma$.

The $D_{it}$ moment is not zero stratum-by-stratum. On the unbalanced stratum at $\theta_0$:
$$E[\varepsilon_{it} D_{it} \mid U_i=1] = E\big[(y_{it} - \Delta_{\underline d_0} D_{it} - \alpha - \pi D_{it} - x_{it}'\gamma) D_{it} \mid U_i=1\big].$$
This equals zero only because $\pi$ is parameterized to absorb the unbalanced-stratum deviation of the average return from $\Delta_{\underline d_0}$. In other words, the $D_{it}$ moment identifies $\Delta_{\underline d_0} + \pi$ on the unbalanced stratum (averaged with covariate controls), not $\Delta_{\underline d_0}$ directly. The pooled system is identified because the balanced stratum pins down $\Delta_{\underline d_0}$ through the trajectory-switcher moments, and $\pi$ absorbs the residual on the unbalanced stratum.

The proof should state this explicitly. Right now a careful referee will flag Step 1 as incomplete: the $D_{it}$ moment is non-degenerate on both strata, and the proof relies on its validity without justifying why the parameterization makes it hold at $\theta_0$.

**Recommendation:** add one paragraph to Step 1 stating that on the unbalanced stratum, the $D_{it}$ moment is satisfied at $\theta_0$ precisely because the parameter $\pi_0$ is defined so that $E[\varepsilon_{it} D_{it} \mid U_i=1, w_i] = 0$. Under MAR + common-$\gamma$, this $\pi_0$ is well-defined and does not vary with $w_i$ once $\gamma$ is correctly specified. The bare $D_{it}$ moment across the pooled sample equals a convex combination of the stratum-specific moments and is zero at $\theta_0$.

---

## 4. MAJOR --- MAR conditioning set and covariate support

**Location:** `paper/unbalanced_proposition.tex:49--54`.

> "$U_i \perp (\theta_i, \tau_i, \{\nu_{it}^l\}, \{(x_{it},\varepsilon_{it})\}_{t\in\mathcal{T}_i}) \mid w_i$, where $w_i$ is a vector of covariates observed for every individual (baseline demographics and wave-of-first-observation indicators)."

The proof uses MAR to deliver $E[\varepsilon_{it} \mid x_{it}, U_i, w_i] = 0$ and $(U_i, x_{it}) \perp \varepsilon_{it} \mid w_i$. For the $(U_i, U_i D_{it}, x_{it})$ moments to be population-zero at $\theta_0$, the conditioning set actually used in the GMM must contain $w_i$, **or** $w_i$ must be redundant given $x_{it}$.

Two concerns:

(a) The paper's $x_{it}$ (age, education, household size, period, time trend) arguably spans "baseline demographics" but does **not** include "wave-of-first-observation indicators" --- a non-trivial subset of $w_i$ given that panel entry is associated with being young (CKT notes this explicitly in `main.tex:489--491`). If wave-of-first-observation is not in the estimation covariate vector, MAR as stated does not deliver the population moment condition used in Step 1.

(b) The assumption states conditioning on the joint $w_i$, but the moment conditions $E[\varepsilon_{it} x_{it}]=0$ in the GMM are **marginal** in $w_i$. These coincide only if $w_i \subset x_{it}$ or if $(x_{it}, \varepsilon_{it}) \perp w_i$, neither of which is asserted.

**Recommendation:** Either (i) weaken MAR to condition on a subset of $w_i$ that is actually included in $x_{it}$, or (ii) state explicitly that $w_i \subseteq \text{span}(x_{it})$ --- i.e., that the wave-of-first-observation indicators enter the regression. The current Stata code does not include wave-of-first-observation dummies, so option (i) is the honest move; option (ii) would require a code change.

Worth asking: should we add wave-of-first-observation fixed effects to the regression? This is the natural empirical analogue of MAR on attrition in a rotating panel.

---

## 5. MAJOR --- Step 3's "partialling-out" invocation is opaque

**Location:** `paper/unbalanced_proposition.tex:156--170`.

The step claims "by the GMM partialling-out result of \citet[Thm.~6.1]{neweyMcFadden1994}, the pooled estimator of the trajectory sub-vector is asymptotically equivalent, up to $o_p(n^{-1/2})$, to the balanced-only estimator with $\hat\gamma^{\mathrm{pool}}$ plugged in for $\gamma$." The earlier exploratory version used a cleaner Frisch--Waugh--Lovell argument that worked because the design matrix block-separated on the balanced vs. unbalanced strata.

The current version has abandoned FWL (probably because the efficient weighting matrix couples moment blocks and FWL does not carry over exactly), but the Newey--McFadden Thm 6.1 invocation is under-specified. The reader needs to see:

- What is the "partialled-out" moment system? Presumably the trajectory-indicator moments after projecting off the $(\alpha, \pi, \gamma)$-score.
- Why does the "equivalence" hold up to $o_p(n^{-1/2})$ rather than exactly? The step says "the efficient weighting matrix $\hat S^{-1}$ couples moment blocks, so the pooled and balanced-only finite-sample first-order conditions differ, but the higher-order discrepancy is $o_p(n^{-1/2})$." This is plausible but not argued.
- What regularity conditions does Thm 6.1 actually require, and are they satisfied here?

**Recommendation:** replace Step 3 with the cleaner framing in the earlier exploratory version --- identify the equivalence as holding at the level of *efficient-weight* asymptotic variances, not finite-sample scores, and point to standard two-step GMM plug-in theory rather than partialling-out. Or: drop Step 3 entirely and subsume it into Step 4, which already does the efficiency comparison via partitioned inversion.

Step 3 in its current form does real work only in motivating the remark's bias-robustness claim, which (per Finding 2) should be softened anyway.

---

## 6. MAJOR --- Step 4's efficiency argument needs to be tightened

**Location:** `paper/unbalanced_proposition.tex:172--194`.

The partitioned-inverse argument is the right approach, but two things need to be said more carefully:

(a) "the pooled $I_{\gamma\gamma}$ is weakly larger than the balanced-only analogue" --- this holds because the unbalanced stratum contributes an extra positive-semidefinite $E[x_{it} x_{it}' \mid U_i=1]$ block under common-$\gamma$ + MAR. The proof should just say this: the variance of the $\gamma$-score is additive in sample contributions because $\{g_i\}$ are iid across $i$, and the unbalanced stratum's $g_i$ vector for the $x_{it}$-block is non-trivial. The current "contribute additively (through the efficient weighting matrix)" phrasing is vague.

(b) "The pooled and balanced-only versions of $I_{\vartheta\vartheta}$ coincide on the trajectory-parameter block, because the corresponding score is zero on the unbalanced subsample." This is correct for the trajectory-indicator and switcher-interaction scores, but $\vartheta$ also includes $(\alpha, \pi)$, whose scores are non-zero on the unbalanced stratum. The proof has $\alpha$ and $\pi$ in $\theta_0$ but the efficiency statement only addresses $\vartheta^{\text{bal}}$ (which excludes $\alpha, \pi$). The step's language ("$\vartheta$ collects all components of $\theta_0$ other than $\gamma$") is inconsistent with the proposition's statement about $\vartheta^{\text{bal}}$. Fix the notation.

**Recommendation:** Let $\vartheta_T = (\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}, \mu_{d_T} + \phi(\mu_{d_T}-\mu_{\underline d_0}))$ denote the trajectory block. Partition $\theta_0 = (\vartheta_T, \alpha, \pi, \gamma)$ and apply partitioned inversion for $\vartheta_T$ only. The information-matrix block $I_{\vartheta_T \vartheta_T}$ is then unchanged between pooled and balanced-only. Blocks involving $(\alpha, \pi)$ don't enter the comparison because those parameters are not targets of the efficiency claim.

---

## 7. MINOR --- placeholder percentages still unfilled

**Location:** `paper/unbalanced_proposition.tex:12--18`.

> "between \textbf{[X\%]} and \textbf{[Y\%]} of individuals are observed in strictly fewer than $T_c$ waves."

The exploratory version had "between $88.6\%$ and $95.7\%$" --- but those are the *non-switcher* shares, not the unbalanced shares. The integrated version correctly flags the potential confusion in the footnote. The percentages need to be pulled from the `summary_stats_*_unb` tables before the paper can go out. Actionable next step: compute `|\mathcal{T}_i| < T_c` shares per country from the estimation sample.

Secondary: the footnote references `tab:summary_stats_CHN_unb` and `tab:summary_stats_TZA_unb` but not `tab:summary_stats_IDN_unb`. Either intentional (IDN trajectory share is computed elsewhere) or an oversight. Include IDN for symmetry.

---

## 8. MINOR --- proposition statement conflates two sub-vectors

**Location:** `paper/unbalanced_proposition.tex:77--99`.

The proposition statement opens by defining $\theta_0$ as the **full** parameter vector, then introduces $\vartheta^{\text{bal}}$ as the common sub-vector for the efficiency claim. The movement from $\theta_0$ to $\vartheta^{\text{bal}}$ between the consistency and efficiency claims is under-motivated. A reader wonders: why not state efficiency for $\theta_0$ directly?

The reason is that balanced-only estimation doesn't produce $\alpha$ or $\pi$ (they aren't identified without unbalanced observers). So the efficiency comparison can only be made for the parameters common to both estimators. State this explicitly in one sentence before defining $\vartheta^{\text{bal}}$.

---

## 9. MINOR --- identification of $\phi$ argument is loose

**Location:** `paper/unbalanced_proposition.tex:138--148`.

The proof says "$\phi$ is identified from the cross-trajectory ratio of switcher returns to rural-consumption differences in Equation~\eqref{eq:phi-proposition1}." But Equation \eqref{eq:phi-proposition1} is a population-moment characterization; in the GMM estimator, $\phi$ is identified by imposing the LCA restriction across all switcher-trajectory moments simultaneously. The ratio form is a useful intuition but is not how the GMM estimates it.

The rank condition is "at least two switcher trajectories have distinct trajectory means." Restate as: the $\phi$ coefficient is identified from the over-identifying LCA restriction, which requires $\text{rank}(\{\mu_{\underline d} - \mu_{\underline d_0}\}_{\underline d \in \mathcal D_S}) \geq 1$ in population.

---

## 10. MINOR --- proof style: `\textit{Step 1.}` vs `\emph{Step 1.}`

**Location:** Throughout the proof.

The current version uses `\textit{Step 1.}` (lines 108, 134, 156, 172). The earlier exploratory version used `\emph{Step 1.}`. Minor inconsistency; `\emph{}` is the convention. No substantive issue, but also: per my global preferences `\emph{}` should be used sparingly. For proof step labels, `\textbf{Step 1.}` or a genuine theorem-style `\textsc{step 1}` might read cleaner and leave `\emph{}` for true emphasis.

---

## 11. MINOR --- footnote in main.tex overclaims "weakly more efficient"

**Location:** `paper/main.tex:455`.

> "...and weakly more efficient than the analogous estimator restricted to balanced observers, under a missing-at-random condition and a common-covariate-effects condition (Assumptions~\ref{ass:mar} and \ref{ass:common-gamma})."

Technically correct, but the clause "weakly more efficient" is ambiguous as written: more efficient for which parameters? The proposition establishes weakly smaller variance for $\vartheta^{\text{bal}}$ (the sub-vector common to both estimators). The footnote should say "weakly more efficient for the trajectory sub-vector $\vartheta^{\text{bal}}$."

---

## 12. Suggested revisions --- prioritized

**Must fix before submission:**
1. Rewrite `main.tex:790--791` to drop the unsupported "even when attrition is non-ignorable" claim (Finding 2).
2. Add the bare-$D_{it}$-moment discussion to Step 1 (Finding 3).
3. State MAR conditioning set cleanly: either restrict to covariates in $x_{it}$ or add wave-of-first-observation dummies (Finding 4).
4. Fix notation consistency in Step 4: distinguish $\vartheta_T$ (trajectory block) from the full non-$\gamma$ sub-vector (Finding 6).
5. Fill in `[X\%]` / `[Y\%]` placeholders (Finding 7).

**Should fix:**
6. Simplify or consolidate Step 3 (Finding 5).
7. State the efficiency claim carefully for the right sub-vector (Finding 8).
8. Tighten $\phi$ identification argument (Finding 9).

**Nice to have:**
9. Style consistency in step labels (Finding 10).
10. Tighten footnote at `main.tex:455` (Finding 11).

---

## 13. Overall assessment

The proposition is in the right place and answers a question referees will ask. The structure (four steps: moment validity, identification + asymptotics, pooled/balanced relationship, efficiency) is the right structure. The MAR + common-$\gamma$ assumption pair is standard and defensible.

The v2 revisions (commit 50866a6) successfully moved from the FWL-based exploratory argument to a block-partitioning argument that accommodates the efficient weighting matrix. That was the right call.

The main remaining problems are:
- **One substantive overstatement in the main-text narrative** (Finding 2) that should be an easy fix.
- **Two gaps in the proof machinery** (Findings 3 and 4) that would be flagged by a careful referee and need addressing.
- **Stylistic tightening** across Steps 3, 4, and the proposition statement.

None of this is fatal. The proof is essentially right; it just needs a careful pass to close the gaps and align the main-text claim with what is actually proven.

The empirical check --- comparing balanced and pooled estimates in Tables~\ref{tab:GRC_IDN_consumption_urban_bal} et al. --- remains the critical joint test of MAR + common-$\gamma$. The second remark correctly frames this. The "close correspondence" observed across CFPS, IFLS, and TZNPS is good news for the joint null; the proposition alone cannot deliver it.
