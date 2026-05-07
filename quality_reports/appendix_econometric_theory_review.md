# Combined Review: Appendix on Pooling Unbalanced Individuals

Paper: Appendix on pooling unbalanced individuals (GRC with trajectory cells)
Date: 2026-04-24
Review type: self-review (synthesis of two independent reviews)

## Organizing diagnosis

The appendix mixes three interpretations of the pooled cell: (i) a MAR-based attrition correction where the unbalanced stratum shares the balanced-stratum latent distribution; (ii) a projection-based device where $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ are nuisance parameters that absorb stratum-level residual variation; and (iii) a structural interpretation where these parameters represent the unbalanced stratum's average rural level and urban return. These three readings are in mild tension — under strict MAR plus (A1–A5), (i) implies $\mu_{\mathrm{unb}} \to \mu_{\underline d_0}$ (up to covariate-distribution differences) and the separate parameters become superfluous, so the structural reading (iii) cannot coexist cleanly with (i). The projection reading (ii) resolves the tension: $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ are defensive nuisance parameters that absorb any remaining stratum-level leakage without contaminating the trajectory estimates.

The recommended revision anchors the appendix on (ii) as the formal primitive while keeping (i) as motivation — a middle path that preserves the MAR narrative without overclaiming. The new assumption is a direct orthogonality condition; MAR (plus A1–A5) is noted as sufficient but not necessary for it. The pooled-cell parameters then provide robustness against mild MAR violations by absorbing stratum-level residual variation. This change simplifies the proof, removes the interpretive clash, and keeps MAR as a recognizable anchor for readers in the panel-data tradition.

## Implementation checklist

Before making edits, run a global search for `\ref{ass:mar}` in the appendix. Every occurrence needs to become `\ref{ass:orthogonality}`. The ones I know about:

- The proposition statement.
- Proof Step 1: "Under Assumption~\ref{ass:mar}, the conditional distribution of $(D_{it},\theta_i,\tau_i,\{\nu_{it}^l\})$ given $x_{it}$ is the same on both strata." This sentence needs more than a label swap — the MAR-implication framing is no longer the formal primitive. Replace with: "Under Assumption~\ref{ass:orthogonality}, the pooled-cell residual on the unbalanced stratum is mean-zero conditional on $(D_{it},x_{it})$; the pair $(\mu_{\mathrm{unb},0},\Delta_{\mathrm{unb},0})$ is the unique pair of scalars that delivers this."
- The A4/common-$\gamma$ sentence: "Assumption~\ref{ass:common-gamma} is a consequence of Assumption~(A4) ($\gamma^U=\gamma^R$) from Section~\ref{subsec:empirical-model} combined with Assumption~\ref{ass:mar}..." — drop the "consequence of" framing entirely (see Assumptions & Setup finding below).

The main text drops this review provides:

1. Replacement assumption block (Assumption~\ref{ass:mar} and its paragraph → Assumption~\ref{ass:orthogonality} with middle-path discussion). See "Replace MAR with direct orthogonality" finding.
2. Replacement sentence for the $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ interpretation. See "Projection-parameter interpretation" finding.
3. Revised proposition statement. See "Suggested revised proposition" at the end.
4. Revised efficiency paragraph. See "Suggested revised efficiency paragraph" at the end.
5. Revised Step 1 sentence (above).

Edits requiring author judgment rather than mechanical text drops:

- Drop the bare $D_{it}$ moment from $z_{it}$ in Step 1's moment list, and rephrase the unbalanced-stratum identification prose accordingly.
- State the rank condition on $D_{it}$ variation within the unbalanced stratum (one sentence, in the proposition or just before the proof).
- Decide whether to keep the wave-of-first-observation robustness claim; if kept, verify it and state it plainly, if dropped, delete the TODO footnote.
- Check the $d_T$ vs $\underline d_T$ notation against the main text.
- Move or delete the Stata implementation sentence.

## Summary Tally

| Severity | Count |
|----------|-------|
| CRITICAL | 0     |
| MAJOR    | 5     |
| MINOR    | 9     |

## Priority Action List

1. Replace Assumption~\ref{ass:mar} with a direct observed-period orthogonality condition $E[\varepsilon_{it}(\theta_0)\mid U_i=1,D_{it},x_{it}]=0$ as the formal primitive. Keep MAR in the surrounding discussion as a sufficient (but not necessary) condition that motivates the orthogonality. Reframe $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ as projection parameters that absorb stratum-level residual variation and provide robustness against mild MAR violations, rather than as structural objects.
2. Fix the efficiency argument. Partition the nuisance block as $\eta=(\gamma,\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ (not just $\gamma$), then invoke the nested-GMM subset result: balanced-only moments form a strict subset of pooled moments, so efficient GMM on the superset is weakly more efficient for any common sub-vector. The partitioned-inverse sketch can remain as intuition for *why* the improvement flows through $\gamma$.
3. Handle $(\mu_{d_T},\Delta_{d_T})$ via the reduced-form coefficient $\kappa_T \equiv \mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$ and the LCA inversion. State the inversion explicitly, flag the $\phi\neq -1$ non-degeneracy condition, and commit to AR-style weak-identification-robust intervals for $\phi$, with projection to $\mu_{d_T}$.
4. Drop the bare $D_{it}$ moment from $z_{it}$ — it is linearly dependent on the trajectory×$D_{it}$ interactions plus $U_iD_{it}$ — and rephrase the prose so the unbalanced slope $\Delta_{\mathrm{unb}}$ is described as identified from the combination of treatment columns, not as a separate moment.
5. State the rank condition for $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$: identification of $\Delta_{\mathrm{unb}}$ requires within-unbalanced-stratum variation in $D_{it}$. Flag the diagnostic (share of unbalanced individuals realizing both $D=0$ and $D=1$).

## Detailed Findings

### Assumptions & Setup

#### Replace MAR with direct orthogonality as primitive; keep MAR as motivation

- Lens: Assumptions & Setup
- Severity: MAJOR
- Confidence: HIGH
- Problem: Assumption~\ref{ass:mar} states the latent-distribution version of MAR: $U_i \perp (\theta_i,\tau_i,\{\nu_{it}^l\}) \mid \{x_{it}\}_{t\in\mathcal T_i}$. The prose gloss — "the joint distribution of latent productivities and shocks on the unbalanced stratum is, conditional on $x$, the same as on the balanced stratum" — creates tension with the separate $\mu_{\mathrm{unb}}$ and $\Delta_{\mathrm{unb}}$ parameters. Under strict MAR plus (A1–A5), these parameters collapse to $\mu_{\underline d_0}$ and $\Delta_{\underline d_0}$ (up to covariate-distribution differences the $\gamma$-block already absorbs), so their presence in the equation makes them look like an over-parameterization.

  The fix is a middle path: make observed-period orthogonality the formal primitive, keep MAR as motivation, and reframe $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ as projection parameters that absorb stratum-level residual variation. This removes the interpretive clash, maps directly to what the proof uses, and preserves the MAR narrative as a recognizable anchor.

  Concrete replacement text for the old Assumption~\ref{ass:mar} block plus the paragraph that follows it (delete both, paste this in):

  ```latex
  \begin{assumption}[Observed-period orthogonality]
  \label{ass:orthogonality}
  For unbalanced person-periods,
  \[
  E[\varepsilon_{it}(\theta_0)\mid U_i=1,\,D_{it},\,x_{it}]=0.
  \]
  \end{assumption}

  Assumption~\ref{ass:orthogonality} is the exact condition the proof of Proposition~\ref{prop:pooling} uses on the unbalanced stratum. It is implied by the combination of (A1)--(A5) with a standard missing-at-random condition on attrition in the tradition of \citet{rubin1976inference} and \citet[ch.~17--19]{wooldridge2010econometric}: if $U_i$ is independent of $(\theta_i,\tau_i,\{\nu_{it}^l\})$ conditional on observed-period covariates, then Assumption~\ref{ass:orthogonality} follows. MAR is sufficient but not necessary — the pooled-cell parameters $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ absorb stratum-level residual variation in levels and returns, providing robustness against mild MAR violations. Attrition in CFPS, IFLS, and TZNPS reflects migration, household breakup, mortality, and tracking quality; the demographic controls in $x_{it}$ reduce, but do not eliminate, concerns about selective attrition. Section~\ref{sec:robustness} compares balanced-only and pooled estimates as a joint sensitivity check on Assumption~\ref{ass:orthogonality} and Assumption~\ref{ass:common-gamma}.
  ```

  Downstream edits this requires: find-and-replace `\ref{ass:mar}` throughout the appendix with `\ref{ass:orthogonality}`. The proposition statement, Step 1 of the proof, and the A4/common-$\gamma$ discussion all reference the old label. The Step 1 sentence about "the conditional distribution of latents given $x$ is the same on both strata" needs rewriting because that framing is MAR-specific; replace with: "Under Assumption~\ref{ass:orthogonality}, the pooled-cell residual on the unbalanced stratum is mean-zero conditional on $(D_{it},x_{it})$; the pair $(\mu_{\mathrm{unb},0},\Delta_{\mathrm{unb},0})$ is the unique pair of scalars that delivers this."
- Files: main paper

---

#### Conditioning set issue: $\{x_{it}\}_{t\in\mathcal T_i}$ is post-selection

- Lens: Assumptions & Setup
- Severity: MINOR
- Confidence: HIGH
- Problem: The conditioning set $\{x_{it}\}_{t\in\mathcal T_i}$ depends on who attrits, which makes the assumption awkward because the conditioning variables are themselves post-selection. Standard practice (Wooldridge Ch 17–19, cited) reads this as "observed-period covariates," but a reader unfamiliar with that convention could object. The replacement assumption block (see the MAR finding above) states "observed person-periods" directly, sidestepping the issue. No separate edit needed if the MAR replacement is adopted — note for implementation.
- Files: main paper

---

#### "Rich demographic controls... make this plausible" overstates the case

- Lens: Assumptions & Setup
- Severity: MINOR
- Confidence: HIGH
- Problem: Attrition in CFPS, IFLS, and TZNPS depends on migration, income shocks, household breakup, mortality, and tracking quality — forces that demographic controls partially capture at best. The replacement assumption block (see the MAR finding above) folds this into the same paragraph with "reduce, but do not eliminate, concerns about selective attrition." No separate edit needed if the MAR replacement is adopted.
- Files: main paper

---

#### Assumption A4 relationship to common-$\gamma$-across-strata

- Lens: Assumptions & Setup
- Severity: MINOR
- Confidence: MEDIUM
- Problem: The text claims Assumption~\ref{ass:common-gamma} "is a consequence of Assumption~(A4) ($\gamma^U=\gamma^R$) from Section~\ref{subsec:empirical-model} combined with Assumption~\ref{ass:mar}." Two problems. First, (A4) is a within-person equality of covariate effects across urban/rural sectors, while Assumption~\ref{ass:common-gamma} is a between-stratum equality across balanced/unbalanced — the implication requires (A4) to hold separately on the unbalanced stratum, which is a substantive assumption not a consequence. Second, once MAR drops from a formal primitive to a motivating condition (per the finding above), the "consequence of MAR" framing no longer applies. Drop the "consequence of" framing entirely and present Assumption~\ref{ass:common-gamma} as a separate, testable primitive. The testability note already in the appendix — replace $x_{it}'\gamma$ with $x_{it}'\gamma + U_i\,x_{it}'\delta$ and test $\delta=0$ — stands.
- Files: main paper

### Identification

#### Bare $D_{it}$ moment is linearly redundant

- Lens: Identification
- Severity: MAJOR
- Confidence: HIGH
- Problem: On the full sample, $1 = \sum_{\underline d \in \mathcal D} \mathbbm{1}\{\underline d_i=\underline d\} + U_i$, so
  \[
    D_{it} = \sum_{\underline d} D_{it}\cdot\mathbbm{1}\{\underline d_i=\underline d\} + U_iD_{it}.
  \]
  The bare $D_{it}$ moment in $z_{it}$ is a linear combination of moments already in the system. Step 1 treats it as a distinct non-degenerate moment on the unbalanced stratum, which is true stratum by stratum but misleading for the pooled GMM system.

  Fix both the moment list (drop $D_{it}$) and the exposition. On the prose side: rather than describing the bare $D_{it}$ moment as identifying something on the unbalanced stratum, say that the two treatment columns ($D_{it}$ and $U_iD_{it}$) combine on unbalanced observations to imply the fitted slope $\Delta_{\mathrm{unb}}$.
- Files: main paper

---

#### Rank condition for $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ not stated

- Lens: Identification
- Severity: MAJOR
- Confidence: HIGH
- Problem: Identification of $\Delta_{\mathrm{unb}}$ requires within-unbalanced-stratum variation in $D_{it}$. If unbalanced individuals enter the panel only once with a single $D$ value — plausible near panel edges in CFPS and IFLS — the $U_iD_{it}$ moment identifies nothing and $\Delta_{\mathrm{unb}}$ is not identified even when the stratum share is large. State this as a rank condition and report the diagnostic: share of unbalanced individuals realizing both $D=0$ and $D=1$ across their observed waves, by country panel.
- Files: main paper

---

#### Projection-parameter interpretation clarifies $\mu_{\mathrm{unb}}$

- Lens: Identification
- Severity: MINOR
- Confidence: HIGH
- Problem: The text describes $\mu_{\mathrm{unb}}$ as "directly the rural-consumption level" on the unbalanced stratum. Because $x_{it}'\gamma$ remains in the equation, $\mu_{\mathrm{unb}}$ is really an adjusted intercept: the unbalanced-stratum rural level at $x=0$, or equivalently the unbalanced-stratum rural level after partialling out $x$. If $x$ is not centered in a meaningful baseline, the literal interpretation misleads.

  Concrete replacement text for the sentence "For an unbalanced individual, the equation collapses to $y_{it} = \mu_{\mathrm{unb}} + \Delta_{\mathrm{unb}} D_{it} + x_{it}'\gamma + \varepsilon_{it}$, so $\mu_{\mathrm{unb}}$ and $\Delta_{\mathrm{unb}}$ are directly the rural-consumption level and the average urban return on the unbalanced stratum":

  ```latex
  For an unbalanced individual, the equation collapses to $y_{it} = \mu_{\mathrm{unb}} + \Delta_{\mathrm{unb}} D_{it} + x_{it}'\gamma + \varepsilon_{it}$. The parameters $\mu_{\mathrm{unb}}$ and $\Delta_{\mathrm{unb}}$ index the unbalanced stratum's adjusted rural intercept and adjusted urban-return parameter --- the pooled-cell analogues of $\mu_{\underline d}$ and $\Delta_{\underline d}$ for a stratum whose trajectory label is undefined.
  ```

  This phrasing keeps the parallel-structure motivation (pooled-cell analogues of trajectory-cell parameters) without overclaiming the structural interpretation, and aligns with the projection framing adopted in Assumption~\ref{ass:orthogonality}.
- Files: main paper

### Estimation & Asymptotics

#### Efficiency argument: partial out the full nuisance block and invoke nested-GMM

- Lens: Estimation & Asymptotics
- Severity: MAJOR
- Confidence: HIGH
- Problem: Step 3 has two related issues.

  First, the nuisance block in the partitioned inverse is not $\gamma$ alone — it is $\eta=(\gamma,\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$. Information about $\gamma$ from the unbalanced stratum enters only after partialling out $(U_i,U_iD_{it})$. The current argument elides this step.

  Second, the claim that "$I_{\vartheta_T\vartheta_T}$ is unchanged between pooled and balanced-only estimators" is fragile. Under efficient GMM, the relevant information object is $G'S^{-1}G$, not a sum of per-moment contributions. Adding unbalanced observations leaves the $G$-block targeting $\vartheta_T$ unchanged (trajectory-indicator scores vanish on $U_i=1$) but changes the full moment covariance $S$, and through $S^{-1}$ it can change the $\vartheta_T\vartheta_T$ block of $G'S^{-1}G$.

  The clean fix combines both corrections: state the nuisance block as $\eta$, write the Schur complement as $I_{\vartheta_T\vartheta_T} - I_{\vartheta_T\eta}I_{\eta\eta}^{-1}I_{\eta\vartheta_T}$, and then invoke the nested-GMM subset result (Hansen 1982, Theorem 3.2) rather than arguing the efficiency improvement from scratch: the balanced-only estimator uses a strict subset of the moments in the pooled system, so under efficient weighting the pooled variance for any common sub-vector is weakly smaller, with strict improvement when the added moments are informative.

  The partitioned-inverse sketch can remain as intuition for *why* the improvement flows through $\eta$ — just don't let it carry the formal weight. Normalization (pooled uses $n$, balanced-only uses $n_b$) is a presentational detail: the natural comparison is at the same total sample, both variances scaled by $1/n$, with the balanced-only estimator discarding $n-n_b$ observations.
- Files: main paper

---

#### Delta method for the non-switcher cell via $\kappa_T$ inversion

- Lens: Estimation & Asymptotics
- Severity: MAJOR
- Confidence: HIGH
- Problem: Introduce the reduced-form coefficient
  \[
    \kappa_T \equiv \mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})
  \]
  explicitly, and let $\vartheta_T$ include $\kappa_T$ rather than the combined expression (this also cleans up the proposition statement). The structural parameters are recovered by inverting LCA:
  \[
    \mu_{d_T} = \frac{\kappa_T + \phi\,\mu_{\underline d_0}}{1+\phi}, \qquad \Delta_{d_T} = \Delta_{\underline d_0} + \phi(\mu_{d_T}-\mu_{\underline d_0}).
  \]
  The inversion is smooth in $(\kappa_T,\phi,\mu_{\underline d_0})$ provided $\phi\neq -1$ — a non-degeneracy condition worth stating once, since the proof's closing delta-method line currently covers only the forward LCA transformation ($\Delta_{\underline d}$ for switcher cells).
- Files: main paper

---

#### Weak identification of $\phi$ propagates into $\mu_{d_T}$

- Lens: Estimation & Asymptotics
- Severity: MAJOR
- Confidence: HIGH
- Problem: Identification of $\phi$ comes from cross-trajectory variation in switcher means. When those means are similar, $\phi$ is weakly identified, and the inversion above transmits weak identification into $\mu_{d_T}$ and $\Delta_{d_T}$ through the $1/(1+\phi)$ term. Standard delta-method standard errors will understate this — the usual weak-IV pathologies (non-normal sampling distribution, coverage distortions) apply.

  Commit to weak-identification-robust inference for $\phi$: AR-style test inversion, which targets $\phi$ directly via the switcher-interaction moments under the LCA restriction. For $\mu_{d_T}$ and $\Delta_{d_T}$, report projection intervals from the AR confidence set for $\phi$ combined with delta-method intervals for the other inputs. State both diagnostics up front: an empty AR set signals LCA rejection at the chosen level; an unbounded set signals severe weak identification.

  A diagnostic on the observed spread of $\hat\mu_{\underline d}$ across switcher cells in each country panel would let readers judge proximity to the weakly-identified regime.
- Files: main paper

---

#### Overidentification and the Hansen $J$-test as a free specification check

- Lens: Estimation & Asymptotics
- Severity: MINOR
- Confidence: MEDIUM
- Problem: The proposition says "two-step GMM" without specifying whether the system is exactly identified or overidentified. Count: trajectory indicators ($|\mathcal D|-1$), switcher interactions ($|\mathcal D_S|-1$), $(U_i,U_iD_{it})$ (2), $x_{it}$ ($\dim x$). Parameters: $\{\mu_{\underline d}\}$, $\Delta_{\underline d_0}$, $\phi$, $\kappa_T$, $\mu_{\mathrm{unb}}$, $\Delta_{\mathrm{unb}}$, $\gamma$. With $\geq 3$ switcher trajectories, the system is overidentified in $\phi$ (and the LCA restriction more generally). The Hansen $J$-statistic is then a free specification check on LCA, complementary to the AR intervals: where AR inverts a $\phi$-specific statistic, $J$ evaluates the joint overidentifying restrictions at the point estimate. Worth reporting both.
- Files: main paper

---

#### Cluster-level i.i.d. framing belongs in the setup, not inside Step 1

- Lens: Estimation & Asymptotics
- Severity: MINOR
- Confidence: HIGH
- Problem: "For inference under individual-level clustering we stack within individual..." is the probabilistic setup for the whole asymptotic argument, not a side-note on inference. Within-cluster dependence of $\varepsilon_{it}$ and $\nu_{it}^l$ across $t$ is what forces the i.i.d.-across-$i$ framing. Promote this sentence to a setup paragraph before the proof begins.
- Files: main paper

### Monte Carlo Design

No Monte Carlo design is presented in this appendix. Not applicable; supporting simulations presumably live elsewhere in the paper.

### Empirical Application

Not assessable from the appendix alone.

### Literature Positioning

#### Verdier comparison reads as a methodological critique

- Lens: Literature Positioning
- Severity: MINOR
- Confidence: MEDIUM
- Problem: "we adopt the pooled-cell specification instead because it preserves the trajectory-cell structure" reads as if Verdier's stacked-vector approach wouldn't work here. The real point is that yours is more convenient given the trajectory-cell parameterization you already use. Revise to "Verdier's stacked-vector formulation applies here; we use the pooled-cell specification for continuity with Section~\ref{subsec:restricted-grc-model}'s trajectory-cell notation." If space matters, demote to a footnote.
- Files: main paper

### Exposition & Notation

#### $d_T$ notation breaks the underline convention

- Lens: Exposition & Notation
- Severity: MINOR
- Confidence: HIGH
- Problem: Trajectory labels use $\underline d_i, \underline d, \underline d_0$ throughout, but the non-switcher trajectory appears as $d_T$ (no underline). If $d_T \in \mathcal D$ and $\mathcal D$ is the set of $\underline d$-labeled trajectories, consistency suggests $\underline d_T$. Check the main-text convention and align.
- Files: main paper

---

#### $\vartheta_T$ definition is cumbersome without $\kappa_T$

- Lens: Exposition & Notation
- Severity: MINOR
- Confidence: HIGH
- Problem: The proposition currently writes $\vartheta_T$ with the combined expression $\mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$ inline. Introducing $\kappa_T$ (per the finding above) lets you write
  \[
    \vartheta_T=(\Delta_{\underline d_0},\phi,\{\mu_{\underline d}\}_{\underline d\in\mathcal D\setminus\{d_T\}},\kappa_T).
  \]
  This also shortens the proof.
- Files: main paper

---

#### Remove the red TODO footnote before circulation

- Lens: Exposition & Notation
- Severity: MINOR
- Confidence: HIGH
- Problem: The red TODO note breaks the professional tone. Either verify the wave-of-first-observation robustness claim and state it plainly, or drop the claim. Placeholder phrasing: "As a robustness check, wave-of-first-observation indicators can be added to $x_{it}$ to absorb differences across panel-entry cohorts without changing the argument below."
- Files: main paper

---

#### Stata implementation detail interrupts the theory

- Lens: Exposition & Notation
- Severity: MINOR
- Confidence: HIGH
- Problem: "In the Stata implementation, $\mu_{\mathrm{unb}}$ is the coefficient on the unbalanced dummy..." interrupts the theoretical argument. Move to a footnote or delete.
- Files: main paper

### Internal Consistency

No issues identified within the scope of this appendix. Main-text consistency (A1–A5, $\mathcal D_S$ vs $\mathcal D$, the non-switcher trajectory $d_T$, and the claimed shares of unbalanced individuals) cannot be verified without the main-text material.

## Shortening plan

The current appendix runs long because it (i) verifies moment validity stratum by stratum, (ii) walks through identification with prose that restates the equation, (iii) proves efficiency through a partitioned-inverse argument that can be replaced by a citation, (iv) carries implementation and setup material inside the proof. A tightened version following the organizing diagnosis above can cut 30–40% without losing content.

Target structure:

- One paragraph motivating the pooled cell, defining $U_i$, and introducing $(\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$ as projection parameters.
- Equation~\eqref{eq:restricted-grc-unbalanced}, with a two-to-three-sentence explanation of what it collapses to on each stratum (tighter than the current prose).
- Assumptions — replace Assumption~\ref{ass:mar} with Assumption~\ref{ass:orthogonality} (observed-period orthogonality) as the formal primitive, with MAR retained in the surrounding paragraph as a sufficient motivating condition; keep Assumption~\ref{ass:common-gamma} with the testability note.
- Proposition statement using $\kappa_T$ and referencing \eqref{eq:restricted-grc-unbalanced} for $\vartheta_T$.
- Proof in two steps:
  - Validity + identification: "For balanced individuals, (A1)–(A5) imply the moment restrictions from Section~\ref{subsec:restricted-grc-model}. For unbalanced individuals, the trajectory indicators equal zero by construction; the orthogonality assumption and common-$\gamma$ deliver the remaining moments. Standard non-linear GMM (Hansen 1982; Newey–McFadden 1994) gives $\sqrt n$-consistency and asymptotic normality under the usual regularity conditions." Two to three sentences, not three paragraphs.
  - Efficiency: "The balanced-only GMM system is a strict subset of the pooled system. Under efficient weighting, the pooled variance for any common sub-vector is weakly smaller, with strict improvement when the unbalanced stratum contains residual variation in $x_{it}$ after partialling out $(U_i,U_iD_{it})$ and the trajectory scores covary with the covariate scores." One Schur-complement sentence for intuition if desired.

Bring back at least the first and third of the commented-out remarks: the block-structure robustness against non-ignorable attrition and the balanced-vs-pooled gap as an empirical check on the joint null. These are referee-bait in the good sense and the current draft is weaker without them. The second remark (imposing LCA on $\Delta_{\mathrm{unb}}$) is worth keeping in a conservative-choice framing.

## Suggested revised proposition

```latex
\begin{proposition}[Pooling balanced and unbalanced individuals]
\label{prop:pooling}
Let $\kappa_T \equiv \mu_{d_T}+\phi(\mu_{d_T}-\mu_{\underline d_0})$ and
\[
\vartheta_T \equiv (\Delta_{\underline d_0},\,\phi,\,\{\mu_{\underline d}\}_{\underline d\in\mathcal D\setminus\{d_T\}},\,\kappa_T).
\]
Let $\theta_0\equiv(\vartheta_T,\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}},\gamma)$ denote the parameter vector in \eqref{eq:restricted-grc-unbalanced}. Under (A1)--(A5), Assumption~\ref{ass:orthogonality}, Assumption~\ref{ass:common-gamma}, the rank condition that $D_{it}$ varies within the unbalanced stratum, and the standard regularity conditions for non-linear GMM, the two-step GMM estimator of \eqref{eq:restricted-grc-unbalanced} is $\sqrt n$-consistent and asymptotically normal for $\theta_0$. The trajectory-specific returns $\Delta_{\underline d}=\Delta_{\underline d_0}+\phi(\mu_{\underline d}-\mu_{\underline d_0})$ for $\underline d\in\mathcal D_S$, and the structural parameters $(\mu_{d_T},\Delta_{d_T})$ recovered by inverting $\kappa_T$ (for $\phi\neq -1$), inherit consistency and asymptotic normality by the delta method. Because the balanced-only GMM system is a strict subset of the pooled system, the pooled asymptotic variance of any common sub-vector is weakly smaller, with strict improvement when the unbalanced stratum contributes residual variation in $x_{it}$ after partialling out $(U_i,U_iD_{it})$ and the trajectory scores covary with the covariate scores.
\end{proposition}
```

## Suggested revised efficiency paragraph

```latex
Partition the information matrix into the trajectory block $\vartheta_T$ and the nuisance block $\eta=(\gamma,\mu_{\mathrm{unb}},\Delta_{\mathrm{unb}})$. The asymptotic information for $\vartheta_T$ equals the Schur complement $I_{\vartheta_T\vartheta_T}-I_{\vartheta_T\eta}I_{\eta\eta}^{-1}I_{\eta\vartheta_T}$. Unbalanced observations do not contribute to $I_{\vartheta_T\vartheta_T}$ because their trajectory indicators equal zero; they contribute to $I_{\eta\eta}$ through $x_{it}$ after partialling out $(U_i,U_iD_{it})$. The formal efficiency statement follows from the nested-GMM subset result (Hansen 1982): because the balanced-only moment system is a strict subset of the pooled system, efficient GMM on the superset yields weakly smaller asymptotic variance for any common sub-vector. The gain is strict when the residual $x$-variation on the unbalanced stratum is informative about $\gamma$ and the trajectory scores covary with the covariate scores.
```

## Positive Observations

- The pooled-cell specification preserves the trajectory-cell structure cleanly; the unbalanced stratum contributes to identification only through $\eta$, which is the right target. (Identification.)
- Cluster-level i.i.d. framing is in place and consistent with the main paper's inference procedure. (Estimation & Asymptotics.)
- Assumption~\ref{ass:common-gamma} is stated as directly testable, and the corresponding test is specified. (Assumptions & Setup.)
- The TODO footnote and placeholder shares are flagged visibly, signalling pre-submission discipline even if they need to be resolved before circulation.

## Lenses With No Issues Found

- Internal Consistency (within-appendix; main-text consistency not assessed).

## Lenses Not Assessable

- Monte Carlo Design: no simulations in this appendix.
- Empirical Application: not in scope of the appendix.
- Main-text internal consistency: would require Section~\ref{subsec:empirical-model}, Section~\ref{subsec:restricted-grc-model}, and the summary-statistics tables to verify that (A1–A5), the definition of $d_T$ vs $\underline d$, and the claimed share of unbalanced individuals all line up.
