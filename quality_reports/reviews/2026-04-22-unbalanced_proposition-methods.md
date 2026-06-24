# Econometrics methods paper review: `unbalanced_proposition.tex`

**Paper:** Cenci-Kleemans-Tjernstrom, "Selection and Heterogeneity in the Returns to Migration"
**Target:** `paper/unbalanced_proposition.tex` --- Proposition on pooling balanced and unbalanced observers in the restricted GRC model
**Date:** 2026-04-22
**Review type:** self-review / coauthor feedback

## Summary tally

| Severity | Count |
|----------|-------|
| CRITICAL | 2     |
| MAJOR    | 7     |
| MINOR    | 5     |

## Priority action list

1. **F1** --- MAR assumption omits $\varepsilon_{it}$, the very shock the proof needs orthogonal for consistency.
2. **F2** --- Specification equation (`eq:restricted-grc-unbalanced`) is inconsistent with the paper's restricted GRC in `main.tex` (missing $\kappa_{d_T}$, different $\mathcal D$ summation, uses $\Delta_{\underline d}$ where paper uses $\phi(\mu_{\underline d}-\mu_{\underline d_0})$).
3. **F3** --- MAR conditions on $x_{i1},\dots,x_{iT_c}$, but unbalanced observers don't have $x$ at every wave --- the conditioning set is undefined for the group the assumption is about.
4. **F4** --- The footnote in `main.tex:455` states a narrower attrition assumption (conditional on $D_{it}$ and $x_{it}$, orthogonal to $\varepsilon_{it}$); the proposition's MAR is both broader (more variables) and narrower (no $D_{it}$). Reconcile.
5. **F5** --- Frisch-Waugh-Lovell is applied to two-step GMM without justification. FWL is an OLS identity; its extension to over-identified GMM requires an argument.
6. **F6** --- Efficiency step argues "uses strictly more observations, therefore smaller variance." Under MAR this is defensible, but the argument needs the partitioned information matrix, not a counting argument.
7. **F7** --- Assumption (ii) from the `main.tex:455` footnote ("covariate effects common across balanced and unbalanced individuals") is embedded in the equation but never stated as a formal assumption.
8. **F8** --- Proposition statement asserts consistency for $\{(\mu_{\underline d},\Delta_{\underline d})\}_{\underline d \in \mathcal D}$. $\Delta_{\underline d}$ is only defined (nonparametrically) for switchers in the unrestricted model, and only implied for non-switchers via LCA. Specify which.
9. **F9** --- No engagement with attrition literature (Rubin 1976; Wooldridge 2002; Hirano-Imbens-Ridder-Rubin 2001).

---

## Detailed findings

### Assumptions & setup

#### F1: MAR assumption omits $\varepsilon_{it}$

- Severity: **CRITICAL**
- Confidence: **HIGH**
- Problem: The assumption (line 48) states $U_i \perp (\theta_i, \tau_i, \{\nu_{it}^l\}_{t,l}) \mid x_{i1},\dots,x_{iT_c}$. The consumption equation in `main.tex:330` is $y_{it}=\beta^R+\theta_i + \tau_i +(\beta+\phi \theta_i)D_{it}+ x_{it}'\gamma + \varepsilon_{it}$, where $\varepsilon_{it}$ is the transitory shock on observed log consumption. The MAR assumption does not include $\varepsilon_{it}$ among the variables independent of $U_i$. Yet Step 2 of the proof (line 103) claims "$E[\varepsilon_{it}\mid\underline d_i, D_{it}, U_i, x_{it}]=0$ on both strata." This does not follow from the stated MAR. If attrition is correlated with the transitory consumption shock $\varepsilon_{it}$ (e.g., people who experience a bad consumption shock are more likely to drop out next wave), the pooled estimator is inconsistent.
- Fix: Either broaden MAR to $U_i \perp (\theta_i, \tau_i, \{\nu_{it}^l\}, \{\varepsilon_{it}\}) \mid x$, or break it into a structural-unobservables piece (for $\theta,\tau,\nu$) and an exogenous-attrition piece (for $\varepsilon$). The latter is cleaner and matches Wooldridge's selection-on-observables for unbalanced panels.
- Files: `paper/unbalanced_proposition.tex:46-49`, `paper/unbalanced_proposition.tex:95-107`

---

#### F2: Specification equation inconsistent with the paper's restricted GRC

- Severity: **CRITICAL**
- Confidence: **HIGH**
- Problem: `paper/unbalanced_proposition.tex:22-35` writes
  $$y_{it}=\sum_{\underline d\in\mathcal D}\mu_{\underline d}\mathbbm 1\{\underline d_i=\underline d\} + \sum_{\underline d\in\mathcal D_S}\Delta_{\underline d}\mathbbm 1\{\underline d_i=\underline d\}D_{it}+\alpha U_i+\pi U_iD_{it}+x_{it}'\gamma+\varepsilon_{it}.$$
  But `main.tex:396-403` writes the restricted GRC as
  $$y_{it}=\sum_{\underline d\in\mathcal D\setminus\{d_T\}}\mu_{\underline d}\mathbbm 1\{\underline d_i=\underline d\} + \Delta_{\underline d_0}D_{it}+\sum_{\underline d\in\mathcal D_S\setminus\{\underline d_0\}}\phi(\mu_{\underline d}-\mu_{\underline d_0})D_{it}\mathbbm 1\{\underline d_i=\underline d\}+\Big(\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})\Big)D_{it}\mathbbm 1\{\underline d_i=d_T\}+\varepsilon_{it}.$$
  Three differences:
  (i) The proposition sums $\mu_{\underline d}$ over all of $\mathcal D$; the paper sums over $\mathcal D\setminus\{d_T\}$ because $\mu_{d_T}$ and $\Delta_{d_T}$ are not separately identified and the always-urban group enters through a composite coefficient.
  (ii) The proposition uses unrestricted $\Delta_{\underline d}$ coefficients indexed by $\mathcal D_S$; the paper's restricted GRC parameterizes these through $\phi$ and the $\mu$'s (the LCA restriction is imposed on the equation, not on an auxiliary moment).
  (iii) The proposition omits the composite $\big(\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})\big)D_{it}\mathbbm 1\{\underline d_i=d_T\}$ term for the always-urban trajectory.
  The proposition either needs to (a) use the paper's exact restricted-GRC equation and state the unbalanced extension additively, or (b) explicitly note that it uses the unrestricted parameterization with the LCA restriction imposed as a side condition (line 36--38 hints at this but the equation above doesn't reflect it).
- Fix: Replace the proposition's equation with the paper's restricted-GRC equation plus $\alpha U_i + \pi U_i D_{it}$.
- Files: `paper/unbalanced_proposition.tex:22-35`; `paper/main.tex:396-403`

---

#### F3: Conditioning set in MAR is undefined for unbalanced observers

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: MAR conditions on $x_{i1},\dots,x_{iT_c}$, the full covariate history. But the individuals the assumption is about --- those with $U_i=1$ --- do not have $x_{it}$ at every wave by definition. The statement $U_i \perp \ldots \mid x_{i1},\dots,x_{iT_c}$ is therefore ill-defined on the event $\{U_i=1\}$.
- Fix: Condition on the observed covariate history $\{x_{it}:t\in\mathcal T_i\}$ together with a design variable capturing which waves are observed, or on a time-invariant covariate vector (baseline $x_{i,1}$ plus demographics) that all observers have.
- Files: `paper/unbalanced_proposition.tex:48`

---

#### F4: Two assumption statements in the manuscript don't agree

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: `main.tex:455` states: "attrition is independent of $\varepsilon_{it}$ conditional on $D_{it}$ and $x_{it}$, and covariate effects on consumption are common across balanced and unbalanced individuals." The proposition states MAR as $U_i \perp (\theta_i,\tau_i,\nu)\mid x$. These are not the same assumption:
  - The footnote conditions on $D_{it}$; the proposition does not. $U_i$ correlated with $D_{it}$ is plausible (migrants may be harder to track) and matters for what can be identified.
  - The footnote excludes $\varepsilon_{it}$ from the independence; the proposition excludes $\theta,\tau,\nu$. These are logically independent statements.
- Fix: Rewrite the footnote to match the proposition (if the proposition is correct after F1), or rewrite the proposition to match the footnote (if the footnote is the intended assumption). Do not leave two mutually inconsistent formalizations of the same assumption in the paper.
- Files: `paper/unbalanced_proposition.tex:46-49`; `paper/main.tex:455`

---

#### F7: Common-$\gamma$ assumption across strata is implicit, not stated

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: The equation in the proposition uses a single $\gamma$ for both strata. This imposes the footnote's "(ii) covariate effects on consumption are common across balanced and unbalanced individuals" but never names it as an assumption. A reader trying to understand what the proposition requires needs to extract this from the equation.
- Fix: Add Assumption 2: "The partial effect of $x_{it}$ on log consumption is the same in the balanced and unbalanced strata." Optionally note this is directly testable by interacting $U_i$ with $x_{it}$ (i.e., by fitting the equation with a $U_i \otimes x_{it}$ block and testing its coefficient against zero).
- Files: `paper/unbalanced_proposition.tex:22-35`, implicit

---

### Identification

#### F8: Parameter set indexed inconsistently

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: The proposition statement (line 63-64) reads: "the collection of balanced-panel trajectory parameters $\{(\mu_{\underline d},\Delta_{\underline d})\}_{\underline d\in\mathcal{D}}$." But (i) $\Delta_{\underline d}$ is nonparametrically identified only on $\mathcal D_S$ in the unrestricted GRC and (ii) under LCA, $\Delta_{\underline d}$ for non-switchers is not a free parameter but is implied by $\beta + \phi\,E[\theta\mid \underline d]$. The phrasing "the collection of ... parameters" suggests a full-rank set of parameters, but half of the $\Delta_{\underline d}$ are implied, not estimated.
- Fix: Be explicit. "The estimator is consistent for $(\beta,\phi,\gamma)$ and for the trajectory-level mean parameters $\{\mu_{\underline d}\}_{\underline d\in\mathcal D\setminus\{d_T\}}$, which together (via LCA) identify $\{\Delta_{\underline d}\}_{\underline d\in\mathcal D}$."
- Files: `paper/unbalanced_proposition.tex:57-67`

---

### Estimation & asymptotics

#### F5: FWL applied to two-step GMM without an argument

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: Line 90 invokes "the Frisch-Waugh-Lovell theorem" to argue that the GMM estimator of $(\mu,\Delta)$ is numerically equal to a partialled-out version. FWL is a statement about OLS: if $X=[X_1, X_2]$, then $\hat\beta_1$ from OLS of $y$ on $X$ equals OLS of $M_2 y$ on $M_2 X_1$. Two-step efficient GMM with a weighting matrix $\hat W$ does not share this identity in general, because the weighting matrix couples moments and the partialled-out system's weighting matrix is not the same as the subblock of $\hat W$. The statement "numerically equal" is therefore stronger than can be established by FWL alone.
- What is likely true: there is an asymptotic FWL-type result for GMM (Newey-McFadden 1994, Section 6), but it requires the partialled system to use the appropriate subblock of the efficient weighting matrix, and the equivalence is asymptotic, not numerical.
- Fix: Replace "numerically equal" with "asymptotically equivalent", cite Newey-McFadden (1994) or an equivalent reference for partialling in GMM, and note the condition on the weighting matrix.
- Files: `paper/unbalanced_proposition.tex:89-93`

---

#### F6: Efficiency argument is a counting argument, not a variance argument

- Severity: **MAJOR**
- Confidence: **MEDIUM**
- Problem: Step 3 (line 109-119) argues: $\hat\gamma^{\text{pool}}$ uses more observations than $\hat\gamma^{\text{bal}}$, so its asymptotic variance is weakly smaller, and this "carries over to $(\mu_{\underline d},\Delta_{\underline d})$ via the sandwich variance formula." This is plausible under MAR but not immediate:
  (i) More observations gives smaller variance *only under the assumption the new observations provide positive information*, i.e., that the pooled moment conditions are not weaker-identified than the balanced ones. Under MAR with homoskedastic shocks across strata, this holds. With heteroskedastic $\varepsilon_{it}$ or a weak-instrument problem in the unbalanced stratum, it need not.
  (ii) The claim that efficiency gains in $\hat\gamma$ translate to efficiency gains in $(\hat\mu,\hat\Delta)$ needs the partitioned-inverse-information calculation, not just an appeal to the sandwich formula. If $\gamma$ and $(\mu,\Delta)$ are asymptotically orthogonal in the information matrix (which they are not in general), there is no spillover.
- Fix: Either give the partitioned-information calculation (one paragraph), or cite a standard reference (Newey-McFadden 1994, Hansen 2022 Chapter 13), and note the homoskedasticity/regularity conditions under which the inequality is strict.
- Files: `paper/unbalanced_proposition.tex:109-119`

---

#### F10: Nothing said about the instruments

- Severity: **MAJOR**
- Confidence: **MEDIUM**
- Problem: The restricted GRC is estimated via two-step GMM with an overidentified moment system (`main.tex:445-451`). The proposition's equation adds two new parameters $(\alpha,\pi)$. For the estimator to be well-defined, the instrument vector $z_{it}$ must be extended to identify $(\alpha,\pi)$ --- presumably with $U_i$ and $U_i D_{it}$ themselves --- but the proposition does not say what moments are used for the unbalanced block or whether overidentification is preserved. A reader cannot reproduce the estimator from the proposition alone.
- Fix: Add one sentence: "The instrument vector is augmented to $z_{it}\cup\{U_i, U_i D_{it}\}$, which identifies $(\alpha,\pi)$ exactly and preserves the overidentification of the balanced block."
- Files: `paper/unbalanced_proposition.tex:57-67`; `paper/main.tex:445-451`

---

### Monte Carlo design

Not assessable --- this proposition does not include Monte Carlo evidence. Appropriate for a proposition in the theory section.

### Empirical application

The remark (line 142-153) references the balanced/pooled comparison in Tables `tab:GRC_{IDN,CHN,TZA}_consumption_urban_bal`. This is the correct diagnostic. Two minor concerns:

#### F11: Robustness remark over-interprets the balanced-unbalanced comparison

- Severity: **MINOR**
- Confidence: **MEDIUM**
- Problem: Remark 2 frames close balanced/pooled correspondence as "consistent with both conditions holding." But the two conditions (MAR and common $\gamma$) are not separately identified by a balanced-pooled comparison --- a violation of one could be offset by a violation of the other. The comparison is a joint test, not a test of each.
- Fix: Soften to "consistent with the joint null that both conditions hold"; note that separate tests would require additional instruments or restrictions.
- Files: `paper/unbalanced_proposition.tex:142-153`

---

### Literature positioning

#### F9: No engagement with the attrition / missing-panel literature

- Severity: **MAJOR**
- Confidence: **HIGH**
- Problem: A proposition about pooling balanced and unbalanced observers under a MAR-type assumption belongs in a substantial literature: Rubin (1976) on MAR, Hirano-Imbens-Ridder-Rubin (2001) on matching with attrition, Wooldridge (2002, *Econometric Analysis of Cross Section and Panel Data*, ch. 17-19) on selection in unbalanced panels, Fitzgerald-Gottschalk-Moffitt (1998) on PSID attrition, Semykina-Wooldridge (2010) on panel data with sample selection. The proposition cites only Hansen (1982) for GMM asymptotics. A reader will expect some positioning.
- Fix: Add a brief paragraph (2-3 sentences) in the Remark or in the surrounding section text placing the pooling argument in this literature.
- Files: `paper/unbalanced_proposition.tex`, surrounding section text

---

### Exposition & notation

#### F12: Proof opening says "two steps," proof has three

- Severity: **MINOR** (but quick win)
- Confidence: **HIGH**
- Problem: Line 70-73 says "The argument has two steps." Lines 75, 95, 109 label three steps. Inconsistency.
- Fix: "The argument has three steps."
- Files: `paper/unbalanced_proposition.tex:70-73`

---

#### F13: "i.i.d. shock assumptions" ambiguous

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: Line 98: "Under the time-invariant comparative advantage and i.i.d. shock assumptions." Which shocks --- $\varepsilon_{it}$ or $\nu_{it}^l$? In the main text, $\nu$ is i.i.d. (A2) and $\varepsilon$ has no stated i.i.d. assumption. Be specific.
- Fix: "Under Assumptions (A1)-(A2) of Section \ref{subsec:empirical-model}..."
- Files: `paper/unbalanced_proposition.tex:95-100`

---

#### F14: $W_1$ index set is off

- Severity: **MINOR**
- Confidence: **HIGH**
- Problem: Line 86-89: $W_1 \equiv (\mathbbm 1\{\underline d_i = \underline d\}, \mathbbm 1\{\underline d_i = \underline d\} D_{it})_{\underline d\in\mathcal D}$. The second component should run over $\mathcal D_S$ only (because $\Delta$ is parameterized only for switchers) or over $\mathcal D\setminus\{d_T\}$ with the always-rural coefficient zero and always-urban handled via $\kappa_{d_T}$. As written, it double-parametrizes.
- Fix: Index the slope block over $\mathcal D_S$.
- Files: `paper/unbalanced_proposition.tex:86-89`

---

### Internal consistency

#### F15: Never-migrant trajectory ($d_T$ omitted; $d_N$ included) handling is muddled

- Severity: **MINOR**
- Confidence: **MEDIUM**
- Problem: The paper's restricted GRC (`main.tex:397`) excludes $d_T$ from the $\mu$ summation, because $(\mu_{d_T},\Delta_{d_T})$ cannot be separately identified and the equation uses the composite $\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$ for that trajectory. The proposition's equation (`paper/unbalanced_proposition.tex:24-27`) sums over all $\underline d\in\mathcal D$, which would include $d_T$. Combined with F2, this needs to be reconciled.
- Fix: Once F2 is addressed the proposition should inherit the paper's $\mathcal D\setminus\{d_T\}$ convention.
- Files: `paper/unbalanced_proposition.tex:22-35`; `paper/main.tex:397`

---

## Positive observations

- **P1 (Identification, Exposition):** The orthogonality argument --- the trajectory indicators are identically zero on the unbalanced subsample, so the unbalanced block is block-orthogonal to the balanced block --- is a clean and substantively meaningful observation. It justifies the pooling in a way a referee cannot easily dismiss.

- **P2 (Empirical Application):** The Remark tying the balanced-pooled comparison in Tables `GRC_{IDN,CHN,TZA}_consumption_urban_bal` to the assumption is exactly the kind of diagnostic a careful reader wants. Promoting this from a remark to the robustness section text would strengthen.

- **P3 (Assumptions & Setup):** MAR is stated explicitly with a name (`\begin{assumption}[Missing at random, conditional on covariates]`). Many applied papers hand-wave the attrition assumption.

- **P4 (Exposition):** The decision to separate the three roles ($(\mu,\Delta)$, $\gamma$, $(\alpha,\pi)$) in the proof architecture makes the argument easy to follow even under critique.

## Lenses with no issues found

- Monte Carlo design --- N/A (no simulation in this proposition).

## Lenses not assessable

None at the proposition level. The paper's broader Monte Carlo (if any) is out of scope.

---

## Summary

The proposition's core idea is correct and the orthogonality argument is the right one. The two CRITICAL items (F1, F2) are fixable in under an hour:

- **F1:** Add $\varepsilon_{it}$ (or an equivalent shock) to the MAR independence set, or separate MAR into a structural-unobservables piece and an attrition-exogeneity piece matching the footnote in `main.tex:455`.
- **F2:** Restate the equation to match the paper's restricted-GRC parameterization (Eq. `eq:restricted-GRC` in `main.tex:396-403`), then add the $(\alpha,\pi)$ augmentation.

MAJOR items mostly require tightening the proof (F5 on GMM-FWL, F6 on efficiency, F10 on instruments) and reconciling with the main-text footnote (F4, F7). Literature positioning (F9) adds three sentences. Notation cleanup (F8, F14) is fast.

With these changes the proposition would be submission-ready. As currently drafted, the core claim is defensible but the formalization has enough gaps that a referee in a methods journal would push back.
