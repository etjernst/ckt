# Econometrics methods paper review: `unbalanced_proposition.tex` (v2)

**Paper:** Cenci-Kleemans-Tjernström, "Selection and Heterogeneity in the Returns to Migration"
**Target:** `paper/unbalanced_proposition.tex` --- Proposition on pooling balanced and unbalanced observers in the restricted GRC model (revised)
**Date:** 2026-04-22
**Review type:** fresh-eyes second pass; v1 review at [2026-04-22-unbalanced_proposition-methods.md](file:///C:/git/ckt/docs/reviews/2026-04-22-unbalanced_proposition-methods.md)

## What changed since v1

v1 flagged 2 CRITICAL and 7 MAJOR issues. The revision addresses most of them:

- F1 (MAR omits $\varepsilon_{it}$) --- fixed.
- F2 (equation mismatch) --- fixed.
- F3 (conditioning set) --- fixed via baseline $w_i$.
- F4 (footnote/proposition mismatch) --- fixed.
- F5 (FWL in GMM) --- partially fixed: the proof drops FWL, but Step 3's "algebraically identical" language still overclaims. See F_v2_1 below.
- F6 (efficiency argument) --- fixed via partitioned-information.
- F7 (common-$\gamma$ not stated) --- fixed as Assumption 2.
- F8 (parameter set) --- fixed via explicit $\theta_0$ and $\vartheta^{\mathrm{bal}}$.
- F9 (attrition literature) --- still unaddressed (carried forward).
- F10 (instruments terminology) --- author noted; out of scope here.

The remaining findings below are issues not previously flagged (or not fully resolved) and that a referee would still raise.

## Summary tally

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| MAJOR    | 6     |
| MINOR    | 6     |

## Priority action list

1. **F_v2_1** --- Step 3's "algebraically identical" is too strong for two-step efficient GMM with overidentification; should be "asymptotically equivalent".
2. **F_v2_2** --- MAR conditions on $w_i$ but the proof invokes moments involving $x_{it}$; the $w_i \leftrightarrow x_{it}$ mapping is not specified.
3. **F_v2_3** --- Standard errors / clustering: the main paper clusters SEs at individual level but the proposition's variance argument is silent on clustering.
4. **F_v2_4** --- Identification of $\phi$ requires a rank condition ($\mu_{\underline d} \neq \mu_{\underline d'}$ for at least two switchers); should be stated explicitly.
5. **F_v2_5** --- `{\varepsilon_{it}}_t` in the MAR statement is ambiguous when $t$ includes unobserved waves.
6. **F_v2_6** --- Attrition / unbalanced-panel literature still uncited (carried from v1 F9).

---

## Detailed findings

### Assumptions & setup

#### F_v2_2: $w_i \leftrightarrow x_{it}$ mapping unspecified

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Assumption~\ref{ass:mar} conditions on $w_i$, described informally as "baseline demographics and wave-of-first-observation indicators." But Step 1 of the proof invokes the moment $E[\varepsilon_{it} \cdot x_{it}] = 0$ on the unbalanced subsample, which requires $U_i \perp \varepsilon_{it} \mid x_{it}$ (or an equivalent variation-based condition). The MAR conditions on $w_i$, not on $x_{it}$. Unless $w_i \supseteq x_{it}$ (which contradicts "$w_i$ is observed for every individual") or unless an additional ignorability-of-$x$ assumption is imposed, the mean-zero claim for the $x_{it}$ moment on the unbalanced subsample does not follow from what is assumed.
- Two fixes: (i) state that the baseline $w_i$ is a sufficient statistic for the selection process conditional on which $(\varepsilon_{it}, x_{it})$ on the unbalanced subsample has the same distribution as on the balanced subsample; (ii) alternatively, restate MAR conditional on $x_{it}$ and document how $x_{it}$ is defined on the unbalanced subsample (e.g., using last-observed $x$, or a baseline-only covariate).
- Files: `paper/unbalanced_proposition.tex:49-55`, `paper/unbalanced_proposition.tex:104-122`

---

#### F_v2_4: Rank / generic-identification condition for $\phi$ unstated

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Step 2 says $\phi$ is identified from the cross-trajectory ratio in Equation~\eqref{eq:phi-proposition1}. That equation requires $\mu_{\underline d} \neq \mu_{\underline d'}$ for at least two switcher trajectories. With only one switcher trajectory, $\phi$ is unidentified. With two but with $\mu_{\underline d} \approx \mu_{\underline d'}$, $\phi$ is weakly identified. The proposition should state this rank condition, or an equivalent completeness-type assumption, alongside the regularity conditions. A brief sentence in Step 2 suffices.
- Files: `paper/unbalanced_proposition.tex:124-139`

---

#### F_v2_5: "$\{\varepsilon_{it}\}_t$" in MAR is ambiguous for unbalanced observers

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Assumption~\ref{ass:mar} states $U_i \perp (\ldots, \{\varepsilon_{it}\}_t) \mid w_i$. For an unbalanced observer, some $\varepsilon_{it}$ correspond to unobserved waves. Does the independence apply to the full panel of shocks (including unobserved) or only to observed ones? If the former, the assumption is a meta-claim that is strictly stronger than needed. If the latter, the notation $\{\varepsilon_{it}\}_t$ should be $\{\varepsilon_{it}: t \in \mathcal T_i\}$ or the full-panel semantics should be explicit. The distinction matters: the moment conditions only involve observed $\varepsilon$'s.
- Fix: either restrict to observed shocks in the notation, or justify the full-panel independence via a latent-variable framing.
- Files: `paper/unbalanced_proposition.tex:51`

---

### Identification

No new issues beyond those flagged in Assumptions & Setup above (F_v2_4).

---

### Estimation & Asymptotics

#### F_v2_1: "Algebraically identical" overclaims for two-step efficient GMM

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Step 3 says: "The first-order conditions for these parameters in the pooled GMM problem are **algebraically identical** to the first-order conditions in the balanced-only problem, except that they are evaluated at $\hat\gamma^{\mathrm{pool}}$." For two-step efficient GMM with overidentification, this is not an algebraic identity. The FOC for $\vartheta_{\text{bal}}$ in the pooled estimator is
  $$G_{\text{switch},\vartheta}^\prime\,[\hat S^{-1}]_{\text{switch},\cdot}\,g_n(\theta) = 0,$$
  where $[\hat S^{-1}]_{\text{switch},\cdot}$ is the full row-block of the pooled weighting matrix, which couples the switcher moments to the $x$ and $(U,UD)$ moments. The balanced-only FOC uses a different weighting matrix (the balanced-only $\hat S^{\text{bal}}$) with different off-diagonal blocks. So the pooled FOC is not literally the balanced-only FOC at a different $\hat\gamma$.
- What IS true (and what the proposition should say): asymptotically, the pooled estimator of $\vartheta_{\text{bal}}$ is equivalent to the balanced-only estimator with $\hat\gamma^{\text{pool}}$ plugged in, up to $o_p(n^{-1/2})$ terms, by the Newey-McFadden (1994, Theorem 6.1) partialling-out result for GMM. This is enough for the efficiency argument in Step 4.
- Fix: Replace "algebraically identical" with "asymptotically equivalent, up to $o_p(n^{-1/2})$," and add a single cite (Newey-McFadden 1994 Sec. 6). If `CKT.bib` lacks this entry, add it.
- Files: `paper/unbalanced_proposition.tex:141-151`

---

#### F_v2_3: Cluster-robust inference not addressed

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: `main.tex:452` states "Standard errors are clustered at the individual level." Individual-level clustering means observations within an individual are not independent across $t$. The proposition's Step 1-4 are framed assuming i.i.d. individual-period moments; $\sqrt n$-consistency and asymptotic normality under clustered dependence require a stacked-individual moment formulation $g_i(\theta) = \sum_t z_{it}\varepsilon_{it}(\theta)$ with $g_i$ i.i.d. across $i$. The weighting matrix $\hat S$ must then be the clustered long-run variance. The information matrix $I = G^\prime S^{-1} G$ inherits the clustered structure. The proposition's current formulation $g_{it}(\theta) = z_{it}\varepsilon_{it}(\theta)$ with population moment $E[g_{it}(\theta_0)]=0$ is fine pointwise but the variance argument needs adaptation.
- Fix: Either (i) reformulate the moment function as individual-stacked, $g_i(\theta) = T_i^{-1} \sum_t z_{it}\varepsilon_{it}(\theta)$ with $E[g_i(\theta_0)] = 0$ and $\hat S$ the sample variance of $g_i$ across $i$; or (ii) add one sentence noting that all asymptotic statements use the cluster-robust long-run variance, with the information matrix adjusted accordingly.
- This is a real issue for a referee: clustering appears in the paper but not in the proposition.
- Files: `paper/unbalanced_proposition.tex:104-176`; `paper/main.tex:452`

---

#### F_v2_7: Regularity condition for global identification stated only implicitly

- Severity: **MINOR** (edging into MAJOR)
- Confidence: **MEDIUM**
- Problem: Step 2 says "the standard non-linear GMM arguments ... deliver $\sqrt n$-consistency." Hansen (1982) requires global identification: $E[g_{it}(\theta)] = 0 \iff \theta = \theta_0$. The proof argues identification element-by-element (trajectory indicators identify $\mu$, ratio identifies $\phi$, etc.), but does not verify that the overall system is globally identified (i.e., that no other $\theta$ also solves $E[g(\theta)] = 0$). Under LCA this is usually fine, but worth one sentence stating or citing.
- Files: `paper/unbalanced_proposition.tex:134-139`

---

### Monte Carlo Design

Not applicable to this proposition. A Monte Carlo that tests Proposition~\ref{prop:pooling} under violations of MAR and common-$\gamma$ would strengthen the paper, but that is a future task.

### Empirical Application

No new findings. The balanced/pooled comparison in Remark 2 is appropriate.

### Literature Positioning

#### F_v2_6: Attrition / unbalanced-panel literature uncited

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Carried from v1 F9. No reference to the unbalanced-panel / missing-at-random literature: Rubin (1976), Wooldridge (2002 panel-data textbook ch. 17-19), Semykina-Wooldridge (2010), Hirano-Imbens-Ridder-Rubin (2001), Fitzgerald-Gottschalk-Moffitt (1998). A reviewer at any methods journal will ask for this. One paragraph in the section preceding the proposition (or a footnote in Remark 1) is sufficient.
- Files: `paper/unbalanced_proposition.tex` (surrounding section prose)

---

### Exposition & Notation

#### F_v2_8: Step 2 combines identification and asymptotics

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: Step 2 argues both identification (via Equations 12 and LCA) and $\sqrt n$-consistency/asymptotic normality (via Hansen 1982) in one paragraph. Splitting into two substeps would aid readability: "Step 2a (identification)" and "Step 2b (asymptotics)." Not required but cleaner.
- Files: `paper/unbalanced_proposition.tex:124-139`

---

#### F_v2_9: "Trajectory averages of rural consumption identify $\{\mu_{\underline d}\}$ directly" is imprecise

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: $\mu_{\underline d}$ is the trajectory-specific fixed effect in the regression equation; it is not literally a trajectory average of $y_{it}$. Under the equation, $\mu_{\underline d} = E[y_{it} - x_{it}'\gamma \mid \underline d_i = \underline d, D_{it}=0]$ for switcher trajectories, which is only "trajectory-average rural consumption" after partialling out $x$ effects. The imprecision is minor but a sharp reader will notice.
- Fix: "trajectory-indicator moments identify $\{\mu_{\underline d}\}$ as fixed effects in the regression."
- Files: `paper/unbalanced_proposition.tex:127-129`

---

#### F_v2_10: "CFPS, IFLS, and TZNPS" repetition

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: The triple of country-survey acronyms appears at lines 58-59 and 203. In a 200-line file this is a modest rule-of-three echo. Harmless but tightenable.
- Files: `paper/unbalanced_proposition.tex:58-59`, `paper/unbalanced_proposition.tex:203`

---

#### F_v2_11: Placeholder percentages

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: Lines 13-18 hold `\textbf{[X\%]}` and `\textbf{[Y\%]}` placeholders flagged by a footnote. These must be filled with the actual unbalanced-observer shares (approx. 89% IDN, 59% CHN, 29% TZA based on `summary_stats_{IDN,CHN,TZA}_{bal,unb}.tex`) before submission. Note: the spread is wider than the original 88.6%-95.7% non-switcher range, which changes the rhetorical opening.
- Files: `paper/unbalanced_proposition.tex:12-18`

---

#### F_v2_12: $\vartheta^{\mathrm{bal}}$ phrasing

- Severity: **MINOR**
- Confidence: **MEDIUM**
- Problem: The phrase "the pooled-estimator asymptotic variance of $\hat\vartheta^{\mathrm{bal}}$" is technically correct but slightly awkward --- readers have to parse "pooled-estimator ... balanced sub-vector" simultaneously. Consider: "Let $\hat\vartheta^{\mathrm{pool}}$ and $\hat\vartheta^{\mathrm{bal}}$ denote the pooled and balanced-only estimators of $\vartheta^{\mathrm{bal}}$. Then $\mathrm{AVar}(\hat\vartheta^{\mathrm{pool}}) \leq \mathrm{AVar}(\hat\vartheta^{\mathrm{bal}})$ with strict inequality when..."
- Files: `paper/unbalanced_proposition.tex:88-94`

---

### Internal Consistency

No new issues. Assumption numbering, equation references, and notation are all consistent with the main manuscript.

---

## Positive observations

- **P1 (Assumptions):** The revised MAR statement and the common-$\gamma$ assumption are stated separately and cleanly, with an explicit testability note on Assumption~\ref{ass:common-gamma}.
- **P2 (Proof structure):** The four-step restructuring avoids the FWL overreach of v1. The block-orthogonality observation (switcher moments identically zero on unbalanced) is now a property of the moment conditions rather than a partialling-out identity, which is the right framing for nonlinear GMM.
- **P3 (Efficiency argument):** The partitioned-information matrix argument is the correct tool and is stated with the right caveat ($I_{\vartheta\gamma} \neq 0$).
- **P4 (Parameter set):** $\theta_0$ is specified explicitly, and the always-urban composite is carried through rather than buried.
- **P5 (Scoped efficiency claim):** Introducing $\vartheta^{\mathrm{bal}}$ to scope the efficiency comparison avoids the apples-to-apples problem with $(\alpha,\pi)$.
- **P6 (Diagnostic tie-in):** Remark 2 frames the balanced/pooled table comparison as a joint-null test, which is the right statistical framing and is explicit that separating the two conditions requires more structure.
- **P7 (Equation match):** The equation in the proposition now matches the paper's restricted GRC (`main.tex:396-403`) with the unbalanced extension added additively, resolving v1 F2.

## Lenses with no issues found

- Monte Carlo Design --- not applicable.
- Internal Consistency (equation references, assumption numbering) --- clean.

## Lenses not assessable

None. The proposition is self-contained and all referenced material (main paper sections, tables, equations) is available for cross-checking.

---

## Bottom line

The revision is a substantial upgrade over v1. The 2 CRITICAL items are gone, and the proof's core argument --- block-orthogonality of the switcher moments plus partitioned-information efficiency --- is now correctly framed for nonlinear GMM.

Four remaining items are worth a second pass before the proposition goes out for external review:
- **F_v2_1** (Step 3's "algebraically identical" overclaim) is the highest-priority because the same kind of OLS-leaning slippage was the main weakness in v1.
- **F_v2_2** (MAR on $w_i$ vs. proof on $x_{it}$) is a logical gap that a careful referee will catch.
- **F_v2_3** (clustering silence) is a cosmetic gap that any referee reading the main paper alongside the appendix will notice.
- **F_v2_4** (rank condition for $\phi$) is a standard completeness-type assumption that needs one sentence.

The other findings (F_v2_5 through F_v2_12) are polish items.

Drawing on both passes: the proposition is currently defensible for internal circulation and a coauthor read, but not yet ready for external submission. One more targeted revision addressing F_v2_1 through F_v2_4 would likely clear the bar.
