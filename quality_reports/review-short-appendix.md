# Econometrics Methods Paper Review --- Short Appendix

Paper: `paper/unbalanced_proposition_short.tex` (half-page deferral-to-Verdier version of the unbalanced-panel appendix for CKT)
Date: 2026-04-24
Review type: self-review; reviewer was asked specifically to check whether the short version defers to Verdier without overclaiming, whether the two conditions are stated precisely, whether the proposition is complete, and what a methods referee would flag.

## Summary Tally

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| MAJOR    | 5     |
| MINOR    | 6     |

## Priority Action List

1. **F3** --- Weak identification of $\phi$ is not addressed; the short version drops the AR-intervals discussion the long version contained. This is a visible hole for a methods referee.
2. **F6** --- No cluster structure is stated for inference. The long version had a cluster-i.i.d. paragraph; the short version omits it, but the empirical application clusters at the individual level and the "efficient two-step GMM asymptotic variance" phrasing is ambiguous without it.
3. **F2** --- The two stated conditions are not quite pure exogeneity statements. Both implicitly embed a linearity-in-$(D_{it}, x_{it})$ restriction on the unbalanced-stratum conditional mean. The prose "treatment assignment is exogenous given covariates" understates what the condition buys.
4. **F4** --- The always-urban inversion $(\mu_{d_T}, \Delta_{d_T})$ is gestured at ("inverting $\kappa_T$") without displaying the two-equation, two-unknown system that LCA adds. A referee will ask for at least one formula.
5. **F7** --- The choice of pooled-cell parameterization over Verdier's individual-FE approach is not motivated. The old Verdier sentence in the long version (now commented out) carried the continuity-with-trajectory-cell-notation justification; the short version drops it.

## Detailed Findings

### Assumptions & Setup

#### F1: "Standard regularity conditions for non-linear GMM" is vague in a short version

- Severity: MAJOR
- Confidence: HIGH
- Problem: The long version of the appendix had a three-sentence enumeration in Step 2 that named the four regularity conditions (compact parameter space, continuous differentiability of $g_{it}$ in $\theta$, global identification, finite fourth moments). The short version gives up that enumeration entirely and writes "standard regularity conditions for non-linear GMM" in the proposition. This is acceptable in a main-text statement but problematic in an appendix that is already a deferral --- the short version has nowhere to hide the omission. A methods referee will read the sentence and ask which conditions the proposition depends on. At minimum, add a footnote listing the four conditions, or cite \citet[Sec.~2.2, Assumptions 2.1--2.6]{neweyMcFadden1994} by section.
- Files: `paper/unbalanced_proposition_short.tex`, proposition on line 46.

---

#### F2: Orthogonality and common-$\gamma$ conditions are stated as exogeneity, but they embed linearity

- Severity: MAJOR
- Confidence: HIGH
- Problem: The orthogonality condition $E[\varepsilon_{it}(\theta_0) \mid U_i=1, D_{it}, x_{it}]=0$ is stated at the true parameter. Read carefully, it requires more than "treatment assignment is exogenous given covariates." It requires that the conditional mean of $y_{it}$ on the unbalanced stratum is *linear in $D_{it}$ and $x_{it}$* with coefficients $(\Delta_{\mathrm{unb}}, \gamma)$ and intercept $\mu_{\mathrm{unb}}$. Any nonlinearity in $D_{it}$ or $x_{it}$ within the unbalanced cell --- for instance, a non-constant return for unbalanced individuals observed at different waves --- violates the condition even when selection into treatment is exogenous. The prose gloss on line 37 ("within the unbalanced cell, treatment assignment is exogenous given covariates") understates what the condition delivers. Similarly, the common-$\gamma$ condition is stated on line 38 as a specification choice ("Equation uses a single coefficient vector $\gamma$"), not as a DGP-level restriction. The DGP-level restriction is that the same $\gamma$ governs covariate effects on both strata; the specification-level phrasing conflates the restriction with the equation that encodes it.
- Suggested fix: add one sentence each. For orthogonality: "Equivalently, the pooled-cell specification is correctly specified on the unbalanced stratum: the conditional mean of $y_{it}$ given $(U_i=1, D_{it}, x_{it})$ is linear in $(D_{it}, x_{it})$." For common-$\gamma$: "As a DGP restriction, this requires that the conditional mean of $y_{it}$ depends on $x_{it}$ through the same coefficient vector in both strata."
- Files: `paper/unbalanced_proposition_short.tex`, lines 36--39.

### Identification

#### F3: Weak identification of $\phi$ is silently dropped relative to the long version

- Severity: MAJOR
- Confidence: HIGH
- Problem: The long version had a "Two inferential caveats" paragraph (now commented out per the user's instructions) that flagged weak identification of $\phi$ when switcher-cell means are close, the $1/(1+\phi)$ pathology in the always-urban inversion, and Anderson-Rubin-style intervals as a weak-identification-robust alternative. None of this appears in the short version. The proposition claims $\sqrt n$-consistency and asymptotic normality of $\hat\theta$ --- including $\hat\phi$ --- without flagging when the asymptotic normality is a poor finite-sample approximation. A methods referee will raise this directly. It is particularly visible because the always-urban inversion on line 53 explicitly requires $\phi \neq -1$ but says nothing about what happens when $\phi$ is close to $-1$ or when the switcher means are close together.
- Suggested fix: decide whether this is a main-text topic (as the user judged when commenting out the paragraph) or an appendix topic. If the former, delete the $\phi \neq -1$ remark from the short appendix and let the main text handle the non-degeneracy and weak-identification discussion together. If the latter, restore a one-sentence caveat in the appendix. Leaving the $\phi \neq -1$ remark in the appendix while removing the weak-identification discussion is the worst of the three options because it flags the pathology without addressing it.
- Files: `paper/unbalanced_proposition_short.tex`, line 53.

---

#### F4: Always-urban inversion is gestured without displaying the two-equation system

- Severity: MAJOR
- Confidence: HIGH
- Problem: Line 53 says "the always-urban structural parameters $(\mu_{d_T}, \Delta_{d_T})$ recovered by inverting $\kappa_T$ for $\phi \neq -1$, inherit consistency and asymptotic normality by the delta method." But $\kappa_T$ is one equation in two unknowns $(\mu_{d_T}, \Delta_{d_T})$; the inversion requires a second equation (LCA: $\Delta_{d_T} = \Delta_{\underline d_0} + \phi(\mu_{d_T} - \mu_{\underline d_0})$). The long version displayed both equations; the short version drops them. A careful reader cannot reproduce the claim without reconstructing the missing LCA equation. Worth at least one sentence: "Combined with the LCA restriction $\Delta_{d_T} = \Delta_{\underline d_0} + \phi(\mu_{d_T} - \mu_{\underline d_0})$, the definition of $\kappa_T$ inverts to $\mu_{d_T} = (\kappa_T + \phi\mu_{\underline d_0})/(1+\phi)$ and $\Delta_{d_T} = \Delta_{\underline d_0} + \phi(\mu_{d_T} - \mu_{\underline d_0})$, requiring $\phi \neq -1$."
- Files: `paper/unbalanced_proposition_short.tex`, line 53.

---

#### F5: Identification of $\gamma$ and of $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ is asserted, not shown

- Severity: MINOR
- Confidence: MEDIUM
- Problem: Line 42 says "the moment system is additive across observed person-periods, the orthogonality and common-covariate-effects conditions above deliver moment validity on both strata." That is true, but a methods referee reading the appendix in isolation may want to see the identification argument for $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ spelled out in one sentence: on the unbalanced stratum the $(U_i, U_iD_{it})$ moments deliver the pair under the rank condition, and $\gamma$ is identified from $x_{it}$ under common-$\gamma$. Identification of the trajectory block is correctly deferred to Section~\ref{subsec:restricted-grc-model}. The gap is small and a sympathetic reader will fill it in; the short version could close it with a dozen words.
- Suggested fix: between line 42 and the proposition, add: "The trajectory-block moments identify $(\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}_{\underline d \neq d_T}, \kappa_T)$ as in Section~\ref{subsec:restricted-grc-model}. The $(U_i, U_iD_{it})$ moments identify $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ under the rank condition above, and the $x_{it}$ moments identify $\gamma$ under the common-$\gamma$ condition."
- Files: `paper/unbalanced_proposition_short.tex`, between lines 42 and 44.

### Estimation & Asymptotics

#### F6: No cluster structure stated for inference

- Severity: MAJOR
- Confidence: HIGH
- Problem: The short version states $\sqrt n\,(\hat\theta - \theta_0) \xrightarrow{d} \mathcal N(0, V)$ with $V$ = "the efficient two-step GMM asymptotic variance." The long version had a paragraph (lines 49--50 in the long file) stating that moment functions are stacked within person and treated as i.i.d. across individuals, so all asymptotic variances are cluster-robust at the individual level. The short version silently drops this. Two issues: (a) without a cluster statement, $V$ is ambiguous --- the per-period moment functions are not i.i.d. across $(i,t)$; and (b) the main paper's inference procedure clusters at the individual level, so the appendix's silence creates an unnecessary gap between the consistency proof and the reported standard errors.
- Suggested fix: add one sentence before the proposition: "We stack individual-period moment functions within person and treat them as i.i.d.\ across individuals, so $V$ is the cluster-robust efficient two-step GMM asymptotic variance, consistent with the main paper's inference procedure."
- Files: `paper/unbalanced_proposition_short.tex`, between lines 42 and 44.

---

#### F8: The efficiency claim's strict-improvement condition is a paraphrase of the long version's, and it's not obviously equivalent

- Severity: MINOR
- Confidence: MEDIUM
- Problem: Long version's Step 3 closer: "The improvement is strict when the residual $x$-variation on the unbalanced stratum after partialling out $(U_i, U_iD_{it})$ is informative about $\gamma$ and the trajectory scores covary with the covariate scores." Short version's closer (line 54): "with strict improvement when the unbalanced stratum contributes residual variation in $x_{it}$ after partialling out $(U_i, U_iD_{it})$." The short version drops the second clause ("trajectory scores covary with covariate scores"). The strict improvement for the trajectory-block sub-vector $\vartheta_T$ *does* need both clauses, because information about $\vartheta_T$ flows from the unbalanced stratum only via $\gamma$, and it requires the trajectory-covariate cross-block to be nonzero. Without the second clause, the short version asserts strict improvement for $\vartheta_T$ under a condition that is necessary but not sufficient. For $\gamma$ itself, the first clause is sufficient.
- Suggested fix: either restore the second clause (more precise but more words), or soften the claim: "with strict improvement for $\gamma$ whenever the unbalanced stratum contributes residual variation in $x_{it}$ after partialling out $(U_i, U_iD_{it})$; strict improvement for $\vartheta_T$ additionally requires the trajectory scores to covary with the covariate scores."
- Files: `paper/unbalanced_proposition_short.tex`, line 54.

### Literature Positioning

#### F7: Motivation for pooled-cell parameterization over Verdier's individual-FE approach is missing

- Severity: MAJOR
- Confidence: HIGH
- Problem: Line 41 correctly flags that Verdier's Appendix G uses an individual-FE parameterization that differs from the paper's trajectory-cell structure. But it does not say why the paper prefers its own specification. A methods referee will ask: if Verdier's approach handles unbalanced panels under MAR with weaker machinery, why introduce the pooled cell at all? The honest answer is that the paper's main-text estimator uses trajectory cells (per Section~\ref{subsec:restricted-grc-model}), and the pooled cell preserves that structure. The long version of the appendix (previous commit) contained an explicit sentence --- since commented out by the user --- that said exactly this. Recommend restoring it in the short version as continuity-with-the-main-text justification, which is also a defensible answer to the referee's natural question.
- Suggested fix: after the Verdier sentence, insert: "We adopt the pooled-cell specification because it preserves the trajectory-cell structure of Section~\ref{subsec:restricted-grc-model}, which yields trajectory-specific returns $\{\Delta_{\underline d}\}_{\underline d \in \mathcal D_S}$ as direct estimation outputs rather than as post-estimation averages over heterogeneous individual effects."
- Files: `paper/unbalanced_proposition_short.tex`, after line 41.

---

#### F9: No engagement with Lagakos et al. (2023) or other trajectory-cell/pooling arguments in the direct literature

- Severity: MINOR
- Confidence: LOW
- Problem: The main CKT paper uses CHN and TZA data from Lagakos et al. (2023), which also handles the balanced/unbalanced question in that data. If Lagakos et al. have a pooling or weighting argument of their own, the appendix should at least acknowledge it. If they simply drop unbalanced individuals, that is a useful contrast to cite. The short version engages only with Verdier; that may be enough for a methods audience, but a referee familiar with the development-economics panel literature may expect broader engagement.
- Files: `paper/unbalanced_proposition_short.tex`.

### Exposition & Notation

#### F10: Two-condition labelling is inconsistent with being unlabelled

- Severity: MINOR
- Confidence: HIGH
- Problem: The short version calls them "the orthogonality condition" and "the common-covariate-effects condition" in running prose, which is fine. But the proposition references "the orthogonality and common-covariate-effects conditions stated above," which makes the reader scroll back to identify them. A compromise that keeps the half-page feel: label them "Condition O" and "Condition C" inline --- e.g., "The first, \textbf{Condition O}, is an observed-period orthogonality condition..." --- and then reference "Conditions O and C" in the proposition. This is lighter than `\begin{assumption}` environments but gives the reader a handle.
- Severity: MINOR because the current prose is still parseable.
- Files: `paper/unbalanced_proposition_short.tex`, lines 35--39 and 46.

Note: the user's writing rules disallow bold labels in prose; if Condition O / Condition C are labelled, use plain parenthetical form: "(Condition O)" rather than "\textbf{Condition O}".

---

#### F11: "Absorbs" is informal

- Severity: MINOR
- Confidence: MEDIUM
- Problem: Line 37 says the pooled pair "absorbs any stratum-level difference." This is intuitive language but is doing technical work --- the precise statement is that the free intercept and slope make the pooled-cell mean function flexible enough to accommodate any level and any slope shift between strata. A referee may ask what "absorbs" means formally. Either leave as is (it is a standard idiom in the panel-data literature) or tighten: "the free pair $(\mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}})$ nests any stratum-level difference in the unbalanced-stratum conditional mean as a level-and-slope shift relative to the balanced stratum."
- Files: `paper/unbalanced_proposition_short.tex`, line 37.

### Internal Consistency

#### F12: Moment system is "additive across observed person-periods" --- imprecise

- Severity: MINOR
- Confidence: MEDIUM
- Problem: Line 42 says "the moment system is additive across observed person-periods." The trajectory-indicator moments are individual-level (the trajectory label is defined once per individual), but the residual-indicator products summed across observed $t$ within individual and then summed across individuals. Saying "additive across observed person-periods" elides the within-person aggregation that is essential for the cluster-i.i.d. treatment (see F6). Consider: "the moment system aggregates within person across observed periods and then across individuals."
- Files: `paper/unbalanced_proposition_short.tex`, line 42.

## Positive Observations

- **P1** (Literature Positioning): Line 41 explicitly flags the architectural difference between Verdier's individual-FE parameterization and the paper's trajectory-cell approach. This is an honest deferral that a referee can verify without being misled. It reads as "we're citing Verdier for the principle, not claiming his proof translates line-by-line."

- **P2** (Assumptions & Setup): The rank condition on $D_{it}$ within the unbalanced stratum is stated precisely and a diagnostic is promised. This was flagged in the prior review of the long version; the short version retains the fix.

- **P3** (Exposition & Notation): The MAR-is-stronger framing on line 37 is clean and gives the reader exactly the right intuition for what the pooled-cell construction buys: a weakening of ignorability to a conditional-mean-zero restriction, facilitated by two extra free parameters.

- **P4** (Estimation & Asymptotics): The proposition is genuinely compact --- one sentence, one displayed formula --- matching the Verdier-style template the user extracted to `docs/Econometric Proof Style.md`. This is the kind of proposition readers can cite by number without hunting for the ingredients.

- **P5** (Literature Positioning): Citing Hansen (1982) for both the two-step GMM machinery and the subset efficiency result is the correct double-duty citation; no need to invoke Chamberlain or Wooldridge for the subset theorem when Hansen's Theorem 3.2 already covers it.

## Lenses With No Issues Found

None. Every lens produced at least one minor finding.

## Lenses Not Assessable

- **Monte Carlo Design**: The short appendix is analytical; no simulation material is provided. If the main paper has a Monte Carlo section, it was not included in this review scope.
- **Empirical Application**: Not directly reviewable from the appendix alone. The appendix refers to Section~\ref{sec:robustness} for the balanced-vs-pooled sensitivity check and to the rank-condition diagnostic (share of unbalanced individuals with both $D$-values). Neither output was included for review; the promises are appropriate but unverified.
