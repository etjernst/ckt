# Second-pass review: econometrics-critic and alignment-critic

**Date:** 2026-03-12
**Inputs:** [2026-03-12_theory-section-review.md](2026-03-12_theory-section-review.md), [2026-03-12_proposed-fixes.md](2026-03-12_proposed-fixes.md), `paper/main.tex`, `scripts/0_programs.do`, `scripts/5_GrRC.do`
**Purpose:** Fresh-eyes pass on both the review and the proposed fixes

---

## Severity reclassifications

| Issue | Old severity | New severity | Rationale |
|-------|-------------|-------------|-----------|
| C2 (extrapolation outside support) | Critical | Major | Extrapolation is inherent to the research question; the fix is framing, not a fundamental flaw |
| C3 ($J$-test power) | Critical | Major | Standard limitation of GMM overid tests; one sentence suffices |
| m6 (GE overclaim at line 821) | Minor | Major | A PE model claiming GE welfare gains is a substantive overreach, not a typo |

---

## Corrections to proposed fixes

### Fix 4 (M3): Precision on "switcher trajectories"

The AFTER text says "any two switcher trajectories $\underline{d} \neq \underline{d}'$ with distinct average rural consumption." This is correct and more precise than the original review's "any two trajectories," since the $\phi$ identification formula uses only switcher trajectories (non-switchers have no within-person variation in $D_{it}$).

No change needed; the proposed fix is already correct.

### Fix 6 (M4): Minor completeness issue

The proposed text explains why $\tau_i$ drops out by citing orthogonality to $\theta_i$ and absence from the decision rule. It should also note that $\nu_{it}^l$ independence (A2) ensures the residual $\varepsilon_{it}$ does not reintroduce $\tau_i$ dependence conditional on trajectory. However, this is implicit in the i.i.d. assumption and adding it would overload a single sentence. **No change recommended.**

### Fix 8 (M6/M7): Incomplete---missing "no state dependence" condition

The proposed text states the equivalence between myopic and forward-looking optimization follows from i.i.d. shocks alone. This is incomplete. The equivalence requires two conditions:

1. Future utility shocks are independent of current choice (from i.i.d.)---**stated in Fix 8**
2. Payoffs do not depend on past location (no state dependence in $\theta_i^l$ or $\beta_t^l$)---**missing from Fix 8**

If there are moving costs, location-specific human capital accumulation, or network effects that make $\theta_i^U$ depend on whether the worker was urban last period, then the current location affects future payoffs even with i.i.d. shocks. The worker would then have an incentive to consider future consequences, breaking the myopic equivalence.

**Revised Fix 8:**

```latex
An important consequence of this assumption is that the period-by-period
location choice rule derived below is equivalent to the solution of a fully
forward-looking dynamic optimization problem. Two conditions deliver this
equivalence: the i.i.d.\ assumption ensures that future utility shocks are
independent of the current location choice, so there is no informational
option value; and the time-invariant productivity assumption
(equation~\ref{eq:consumption}) ensures that payoffs do not depend on past
locations, so there is no state dependence in returns. Together, these
eliminate any channel through which today's choice affects future welfare,
reducing the dynamic problem to a sequence of static comparisons. If
non-pecuniary factors were instead persistent---or if migration experience
altered productivity---the equivalence would break down, and the set of
marginal workers who generate identifying variation would differ from what
our model implies.
```

### Fix 10: Missing assumption A6 (no moving costs / state dependence)

The assumptions inventory lists A1--A5 but omits a maintained assumption that does real work: the absence of moving costs, switching costs, or any form of state dependence in payoffs. This assumption is used in Fix 8 (myopic equivalence) and is distinct from the i.i.d. assumption on $\nu_{it}^l$.

**Add between A2 and A3:**

```latex
(A3)~Location-specific payoffs do not depend on migration history: there are
no moving costs, no location-specific human capital accumulation, and no
network effects that create state dependence in returns.
```

This shifts the old A3--A5 to A4--A6. Update the testability sentence accordingly:

```latex
Assumptions A4--A6 are testable; we discuss their empirical support in
Sections \ref{sec:grc-returns} and \ref{sec:robustness}.
```

---

## New issues identified

### N1 (Major). Decision rule drops covariates without justification

The decision rule at eq (8) (line 291) compares $E[V_{it}^U \mid \theta_i]$ vs $E[V_{it}^R \mid \theta_i]$, but the consumption equation at eq (10) (line 310) includes covariates $x_{it}'\gamma^l$. If covariates affect consumption, they should also affect the location choice through the expected utility comparison. The paper does not explain why $x_{it}$ is absent from the decision rule.

Possible justifications: (a) covariates are realized after the location choice, (b) covariates are the same in both locations so they cancel in the comparison, or (c) the decision rule is stated in terms of the productivity component only. Any of these would work, but one should be stated.

**Suggested fix:** Add a sentence after eq (8) noting that covariates cancel in the urban-rural comparison under the symmetric covariate assumption ($\gamma^U = \gamma^R$), or that the decision rule conditions on $x_{it}$ (which are predetermined).

### N2 (Major). Line 812 mischaracterizes the model

Line 812 (conclusion) says the model captures "the relationship between comparative and absolute advantage." The model separates $\theta_i$ (comparative) and $\tau_i$ (absolute) but does not model any *relationship* between them---they are orthogonal by construction. The correct characterization is "the relationship between returns to migration and comparative advantage," which is the $\Delta_i = \beta + \phi\theta_i$ restriction.

**Suggested fix:**

```latex
% BEFORE (line 812):
the relationship between comparative and absolute advantage

% AFTER:
the relationship between returns to migration and comparative advantage
```

### N3 (Major). GE overclaim at line 821

The conclusion states that "promoting migration would reduce misallocation and increase overall growth." This is a general equilibrium claim that the partial equilibrium model cannot support. If migration increases, urban wages fall and rural wages rise (GE adjustment), potentially eliminating the gains. The paper's PE estimates of $\Delta_i$ are informative about *who* gains from migration, not about the aggregate welfare effects of a migration-promoting policy.

**Suggested fix:** Qualify the claim:

```latex
% BEFORE:
promoting migration would reduce misallocation and increase overall growth

% AFTER:
the partial-equilibrium estimates suggest that reducing barriers to migration
could improve allocative efficiency, though the aggregate welfare effects
depend on general-equilibrium adjustments that our framework does not model
```

### N4 (Minor). Always-urban term needs bridging text

The always-urban group's coefficient is bundled as $\kappa + \phi(\kappa - \mu_{\underline{d}_0})$ in the restricted GRC (line 394). The notation $\kappa$ appears without introduction in the equation. While $\kappa$ is defined earlier (line 365), the transition from the unrestricted to restricted GRC does not explain why always-urban workers get a special term rather than being handled like other trajectories. A brief note would help: always-urban workers have $\sum_t D_{it} = T$, so they are not in $\mathcal{D}_S$ and their trajectory-specific return is parameterized separately.

### N5 (Minor). Split-sample $J$-test non-rejection may reflect power loss

The paper splits CHN into hukou and non-hukou subsamples and reports that the $J$-test passes in both subsamples (while failing in the pooled sample). Splitting the sample reduces both the number of observations and potentially the number of trajectories, reducing the $J$-test's power. The non-rejection in subsamples could reflect inadequate power rather than genuine model fit. A sentence acknowledging this would be appropriate.

---

## Alignment-critic findings: code-theory consistency

### Confirmed correct

1. **GMM residual matches paper.** The `run_grc` program in `0_programs.do` (lines 1552--1584) implements the restricted GRC residual equation correctly. The substitution pattern $\mu_{\underline{d}_0} + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ matches the paper's parameterization.

2. **Instrument list is correct.** Trajectory indicators, $D_{it}$, $D_{it} \times \text{trajectory indicators}$, and covariates. The always-rural dummy is omitted (absorbed into the constant), avoiding collinearity.

3. **Always-urban $\kappa$ bundling is correct.** The code estimates $\kappa + \phi(\kappa - \mu_{\underline{d}_0})$ as a single composite parameter, consistent with the paper's restricted GRC.

4. **Clustering at individual level confirmed.** `vce(cluster pid)` in `0_programs.do:1581`.

5. **Two-step efficient GMM confirmed.** `winitial(identity)` with `onestep` not specified implies two-step by default in Stata's `gmm` command.

### Critical: `define_switcherpars` base(2) bug

The `define_switcherpars` program is called with hardcoded `base(2)` at **9 call sites** in `5_GrRC.do` (lines 88, 164, 240, 514, 590, 666, 933, 1004, 1075). The `initial_values` program selects the baseline data-adaptively (highest $|t|$ among trajectories with $N_s/T > 5$), but the GMM estimation always uses trajectory 2 as the baseline.

When the data-driven base $\neq 2$, this creates an internal inconsistency: the initial values are computed relative to one baseline while the moment conditions are parameterized relative to another. Under exact LCA, the choice of baseline is a reparameterization and the inconsistency affects only convergence speed. Under approximate LCA, different baselines can yield different $\hat\phi$ estimates.

**Impact:**
- **CHN consumption:** base = 2 is likely the data-driven choice (largest switcher group). Probably unaffected.
- **IDN consumption:** data-driven base may differ (base = 16 per earlier analysis). Potentially affected.
- **TZA consumption:** data-driven base may differ (base = 5 per earlier analysis). Potentially affected.
- **All income specs:** unknown alignment between hardcoded and data-driven base.

**One-line fix:** Change `base(2)` to `` base(`base') `` at all 9 sites in `5_GrRC.do`, where `` `base' `` is the local macro set by `initial_values`.

**This is a code bug, not a paper fix.** Flagged for separate attention; does not belong in the proposed-fixes.md for main.tex.

### Not tested in code: $\gamma^U = \gamma^R$

The symmetric covariate restriction is imposed but never tested. No interaction $D_{it} \times x_{it}$ appears in any specification. Fix 9 proposes acknowledging testability in the text; the actual test would require a code change (adding `c.x_k#1.choice` interactions).

---

## Updated fix summary

| Fix | Issue | Type | Status after second pass |
|-----|-------|------|--------------------------|
| 1 | C1: Duplicate equation block | Delete | Unchanged |
| 2 | M1: Missing time subscript | Notation | Unchanged |
| 3 | M2: Inconsistent underline | Notation | Unchanged |
| 4 | M3: Broken sentence | Grammar | Unchanged (already precise) |
| 5 | m7: "full" $\to$ "balanced" | Typo | Unchanged |
| 6 | M4: Why $\tau_i$ drops out | New sentence | Unchanged (minor gap acceptable) |
| 7 | M5: GMM details | New paragraph | Unchanged |
| 8 | M6/M7: i.i.d. $\Rightarrow$ myopic | New paragraph | **Revised** (add state-dependence condition) |
| 9 | M8: Symmetric covariates | Replace sentence | Unchanged |
| 10 | Assumptions inventory | New paragraph | **Revised** (add A3: no state dependence; renumber A3--A5 $\to$ A4--A6) |
| 11 | N1: Decision rule drops covariates | New sentence | **New** |
| 12 | N2: Line 812 mischaracterization | Word change | **New** |
| 13 | N3: GE overclaim at line 821 | Rewrite clause | **New** |
| 14 | N4: Always-urban bridging text | New sentence | **New** (minor) |
| 15 | N5: Split-sample $J$-test power | New sentence | **New** (minor) |
