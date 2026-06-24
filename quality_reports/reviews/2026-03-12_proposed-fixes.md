# Proposed fixes to main.tex: Theory section

**Date:** 2026-03-12
**Source:** [2026-03-12_theory-section-review.md](2026-03-12_theory-section-review.md)
**Status:** Awaiting approval

---

## Mechanical fixes

### Fix 1 (C1): Delete duplicate equation block

**Lines 397--405.** Delete entirely. The first version of the restricted GRC (lines 388--395) is correct; the second has missing indicator functions, wrong summation range, lowercase $d_{it}$, triple-duplicate labels, and repeated prose.

**Delete:**
```latex
We do not restrict the sign of the relationship between returns to migration and comparative advantage; rather, we allow this to be determined by the data.
This yields the following restricted GRC model:
\begin{align}
        y_{i t} = & \sum_{\underline{d} \in \mathcal{D} \setminus d_{T}} \mu_{\underline{d}}+
        \Delta_{\underline{d}_0} d_{i t}+\sum_{\underline{d} \in \mathcal{D} \backslash \underline{d}_0} \phi\left(\mu_{\underline{d}}-\mu_{\underline{d}_0}\right) d_{i t} \mathbbm{1}\left\{d_i=\underline{d}\right\} \label{eq:restricted-GRC} \\ \notag
    & + \left(\mu_{\underline{d}_T}+\phi\left(\mu_{\underline{d}_T}-\mu_{\underline{d}_0}\right)\right) d_{i t} \mathbbm{1}\left\{\sum_{t=1}^T d_{i t}=T\right\}+\varepsilon_{i t}\label{eq:restricted-GRC}
\end{align}
\noindent for some baseline trajectory $d_{0} \in \mathcal{D}_{S}$.
```

---

### Fix 2 (M1): Add time subscript to $\beta^R$

**Line 310.** Change `\beta^R` to `\beta_t^R`:

```latex
% BEFORE (line 310):
y_{it}&=\beta^R+\theta_i + \tau_i +(\beta+\phi \theta_i)D_{it}+  x_{it}'\gamma^R + D_{it}x_{it}'(\gamma^U-\gamma^R) + \varepsilon_{it}.

% AFTER:
y_{it}&=\beta_t^R+\theta_i + \tau_i +(\beta+\phi \theta_i)D_{it}+  x_{it}'\gamma^R + D_{it}x_{it}'(\gamma^U-\gamma^R) + \varepsilon_{it}.
```

**Line 324.** Same change in eq (10$'$):

```latex
% BEFORE (line 324):
y_{it}&=\beta^R+\theta_i + \tau_i +(\beta+\phi \theta_i)D_{it}+  x_{it}'\gamma + \varepsilon_{it}.

% AFTER:
y_{it}&=\beta_t^R+\theta_i + \tau_i +(\beta+\phi \theta_i)D_{it}+  x_{it}'\gamma + \varepsilon_{it}.
```

---

### Fix 3 (M2): Fix underline notation in eq (413)

**Line 413.** Change `\mu_{d}` to `\mu_{\underline{d}}` in the denominator:

```latex
% BEFORE:
\phi = \frac{\Delta_{\underline{d}} - \Delta_{\underline{d}^{'}}}{\mu_{d} - \mu_{\underline{d}^{'}}},\ \ \mu_{\underline{d}} \neq \mu_{\underline{d}^{'}}.

% AFTER:
\phi = \frac{\Delta_{\underline{d}} - \Delta_{\underline{d}'}}{\mu_{\underline{d}} - \mu_{\underline{d}'}},\ \ \mu_{\underline{d}} \neq \mu_{\underline{d}'}.
```

(Also cleaned up the prime notation: `\underline{d}^{'}` $\to$ `\underline{d}'` throughout.)

---

### Fix 4 (M3): Fix broken sentence at line 410

```latex
% BEFORE:
Taking expectations of equation \eqref{eq:LCA-restriction} within migration
trajectories implies that average returns satisfy the following equality for
any two trajectories \(d \neq d^{'}\) the following equality holds:

% AFTER:
Taking expectations of equation \eqref{eq:LCA-restriction} within migration
trajectories implies that for any two switcher trajectories
$\underline{d} \neq \underline{d}'$ with distinct average rural consumption,
average returns satisfy:
```

---

### Fix 5 (m7): Fix typo at line 790

```latex
% BEFORE:
In contrast, this difference is reversed in the full sample, with urban
respondents being nearly two years older.

% AFTER:
In contrast, this difference is reversed in the balanced sample, with urban
respondents being nearly two years older.
```

---

## Substantive additions

### Fix 6 (M4): Explain why $\tau_i$ drops out

**After line 383** (after "...which in turn allows us to extrapolate returns for non-migrants."), insert:

```latex
This extrapolation is valid because absolute advantage, $\tau_i$, does not
enter the location choice rule in equation \eqref{eq:decision-rule} and is
orthogonal to comparative advantage by construction; consequently,
$E[\tau_i \mid \underline{d}_i = \underline{d}]$ is constant across
trajectories and differences in $\mu_{\underline{d}}$ reflect only
differences in average comparative advantage.
```

---

### Fix 7 (M5): Add GMM estimation details

**After line 436** (after "...as in \cite{tjernstromCommentSuri2011}."), insert:

```latex
Specifically, the moment conditions require the residual from equation
\eqref{eq:restricted-GRC} to be orthogonal to a set of instruments that
includes trajectory indicators, the urban location indicator and its
interactions with trajectory indicators, and the vector of covariates.
Standard errors are clustered at the individual level to account for
within-person serial correlation. The number of moment conditions exceeds
the number of parameters, yielding overidentifying restrictions that we
test using Hansen's $J$-statistic.
```

---

### Fix 8 (M6/M7): Acknowledge i.i.d. implications for the decision rule

**After line 280** (after "Under this assumption, migration decisions respond to temporary, idiosyncratic factors that do not reflect systematic differences in productivity across sectors."), insert:

```latex
An important consequence of this assumption is that the period-by-period
location choice rule derived below is equivalent to the solution of a fully
forward-looking dynamic optimization problem: because future utility shocks
are independent of the current location choice, there is no option value
associated with being in a particular location today. This simplifies the
dynamic problem to a sequence of static comparisons. If non-pecuniary
factors were instead persistent---for example, due to moving costs or
institutional constraints that create state dependence---the equivalence
would break down, and the set of marginal workers who generate identifying
variation would differ from what our model implies.
```

---

### Fix 9 (M8): Acknowledge symmetric covariates restriction

**Replace line 321:**

```latex
% BEFORE:
To simplify the empirical specification, we assume that observable
characteristics affect consumption symmetrically across locations, so
that $\gamma^U=\gamma^R$.

% AFTER:
We assume that observable characteristics affect consumption symmetrically
across locations, so that $\gamma^U=\gamma^R$. This restriction is testable
by including the interaction $D_{it} x_{it}'(\gamma^U - \gamma^R)$ in
equation \eqref{eq:generalized-consumption-eq} and testing whether the
interaction coefficients are jointly zero. If the restriction fails---for
example, because education earns higher returns in urban labor
markets---part of the heterogeneity attributed to $\theta_i$ may instead
reflect differential covariate effects across locations.
```

---

### Fix 10: Collect identifying assumptions

**After line 333** (after "...imposing economically motivated restrictions that link returns across subpopulations."), insert a new paragraph:

```latex
Before proceeding, we collect the maintained assumptions underlying
identification.
(A1)~Location-specific productivities $\theta_i^U$ and $\theta_i^R$ are
time-invariant.
(A2)~Non-pecuniary utility shocks $\nu_{it}^l$ are i.i.d.\ across
individuals, time, and locations, implying that migration trajectories
reflect comparative advantage rather than shock persistence.
(A3)~The average rural-urban consumption gap $\beta$ is constant over time.
(A4)~Observable characteristics affect consumption symmetrically across
locations ($\gamma^U = \gamma^R$).
In addition, the restricted model below imposes
(A5)~the linear comparative advantage restriction.
Assumptions A3--A5 are testable; we discuss their empirical support in
Sections \ref{sec:grc-returns} and \ref{sec:robustness}.
```

---

## Summary

| Fix | Issue | Type | Lines affected |
|-----|-------|------|----------------|
| 1 | C1: Duplicate equation block | Delete | 397--405 |
| 2 | M1: Missing time subscript | Notation | 310, 324 |
| 3 | M2: Inconsistent underline | Notation | 413 |
| 4 | M3: Broken sentence | Grammar | 410 |
| 5 | m7: "full" $\to$ "balanced" | Typo | 790 |
| 6 | M4: Why $\tau_i$ drops out | New sentence | after 383 |
| 7 | M5: GMM details | New paragraph | after 436 |
| 8 | M6/M7: i.i.d. $\Rightarrow$ myopic | New paragraph | after 280 |
| 9 | M8: Symmetric covariates | Replace sentence | 321 |
| 10 | Assumptions inventory | New paragraph | after 333 |
