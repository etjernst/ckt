# Theory section review: Model and identification (lines 178--440)

**Date:** 2026-03-12
**Reviewers:** domain-reviewer, econometrics-critic
**File:** paper/main.tex, Section 2

---

## Critical issues (3)

### C1. Duplicate restricted GRC equation block (lines 397--404)

The restricted GRC model equation appears twice. The second version (lines 400--404) contains errors:
- Missing indicator functions in the first sum (line 401): writes $\sum \mu_{\underline{d}} +$ without $\mathbbm{1}\{\underline{d}_i = \underline{d}\}$
- Wrong summation range (line 402): sums over $\mathcal{D} \setminus \underline{d}_0$ instead of $\mathcal{D}_S \setminus \{\underline{d}_0\}$
- Notation inconsistency: uses lowercase $d_{it}$ instead of uppercase $D_{it}$
- Triple-duplicate `\label{eq:restricted-GRC}` (lines 394, 402, 403) causes LaTeX warnings and unpredictable cross-refs
- Duplicated prose: "We do not restrict the sign of $\phi$" appears at both line 385 and line 398

**Fix:** Delete lines 397--405 entirely. The first version (lines 388--395) is correct.

### C2. Extrapolation to non-switchers operates outside support of identifying variation

The paper's headline contribution is extrapolated returns for never-migrants. The LCA restriction identifies these through linear extrapolation of the $\Delta$-$\mu$ relationship estimated from switchers. But always-rural workers likely have lower $\mu$ than any switcher group, and always-urban workers higher $\mu$. The extrapolation therefore operates in regions with no identifying variation. The $J$-test provides some comfort but has limited power with few overidentifying restrictions (especially Tanzania with only 3 waves).

**Not a "fix" issue---requires authorial judgment on framing.** Suggestions:
- Show where non-switcher $\mu$ values fall relative to the range of switcher $\mu$ values
- Report a quadratic LCA sensitivity check (one additional parameter)
- Acknowledge explicitly that non-switcher returns are partially identified by functional form

### C3. $J$-test power not discussed

Non-rejection of the $J$-test in IDN and TZA is presented as support for the LCA restriction (lines 717--721), but the test's power is not discussed. With few switcher trajectories (few overidentifying restrictions), the test cannot detect many plausible alternatives (e.g., moderate nonlinearity in comparative advantage).

**Fix:** Add a sentence acknowledging that non-rejection is necessary but not sufficient evidence for LCA, especially with few degrees of freedom.

---

## Major issues (9)

### M1. Missing time subscript on $\beta^R$ in eq (310)

Line 310 writes $\beta^R$ without time subscript, but the derivation from eqs (259--260) yields $\beta_t^R$. Time effects are not stated as suppressed until line 339 (GRC section). Either add the subscript or note the simplification.

### M2. Inconsistent underline notation in eq (413)

Line 413: denominator has $\mu_{d}$ (no underline) vs $\mu_{\underline{d}'}$ (with underline). Should be $\mu_{\underline{d}}$ throughout.

### M3. Broken sentence at line 410

"...implies that average returns satisfy the following equality for any two trajectories $\underline{d} \neq \underline{d}'$ the following equality holds:" --- "the following equality" appears twice. Grammatically broken.

### M4. Unstated assumption: why $\tau_i$ drops out when conditioning on trajectories

The formula $\phi = (\Delta_{\underline{d}} - \Delta_{\underline{d}'}) / (\mu_{\underline{d}} - \mu_{\underline{d}'})$ at line 413 requires $E[\tau_i \mid \underline{d}_i = \underline{d}] = E[\tau_i]$ for all $\underline{d}$. This holds because $\tau_i$ is orthogonal to $\theta_i$ by construction and does not enter the decision rule (eq 8), so trajectories carry no information about absolute advantage. The logical chain should be stated explicitly.

### M5. GMM moment conditions never written explicitly

Line 436 says the model is estimated via GMM following Tjernström (2023) but never states the moment conditions, number of moments vs parameters, or weighting matrix choice.

**From the do-files** ([0_programs.do:1552--1584](scripts/0_programs.do#L1552-L1584)), the actual GMM implementation is:

The Stata `gmm` command estimates a single residual equation:
$$\varepsilon_{it} = y_{it} - \sum_{\underline{d} \in \mathcal{D} \setminus \{d_T\}} \mu_{\underline{d}} \cdot \mathbbm{1}\{\underline{d}_i = \underline{d}\} - \Delta_{\underline{d}_0} D_{it} - \phi \sum_{\underline{d} \in \mathcal{D}_S \setminus \{\underline{d}_0\}} (\mu_{\underline{d}} - \mu_{\underline{d}_0}) D_{it} \mathbbm{1}\{\underline{d}_i = \underline{d}\} - \big(\kappa + \phi(\kappa - \mu_{\underline{d}_0})\big) D_{it} \mathbbm{1}\{\underline{d}_i = d_T\} - x_{it}'\gamma$$

The moment conditions are $E[\varepsilon_{it} \cdot z_{it}] = 0$ where the instrument vector $z_{it}$ includes:
- Covariate vector $x_{it}$ (period FEs, female, age$^2$, education, education$^2$, unbalanced indicators)
- Trajectory indicators: $\mathbbm{1}\{\underline{d}_i = d_N\}$, $\mathbbm{1}\{\underline{d}_i = \underline{d}\}$ for each switcher $\underline{d}$
- Choice interactions: $D_{it}$, $D_{it} \cdot \mathbbm{1}\{\underline{d}_i = d_T\}$, $D_{it} \cdot \mathbbm{1}\{\underline{d}_i = \underline{d}\}$ for each switcher $\underline{d}$

**Weighting:** Two-step efficient GMM with standard errors **clustered at the individual level** (`vce(cluster pid)`).

**Parameter count:** $k + 2 + p$ where $k$ = number of switcher trajectories, $p$ = number of covariates. The $J$-test degrees of freedom equal the number of instruments minus the number of parameters.

**The $J$-test statistic, degrees of freedom, and $p$-value are stored and reported in tables** (lines 1599--1603 of `0_programs.do`).

The paper should state these moment conditions explicitly, or at minimum state the instrument list and clustering.

### M6. i.i.d. utility shocks are implausible for migration

The i.i.d. assumption on $\nu_{it}^l$ (line 277) does real work in the model but is hard to defend for migration decisions. Here is why it matters:

The model groups workers by their observed migration trajectory $\underline{d}_i = (D_{i1}, \ldots, D_{iT})$. It then interprets differences in average consumption across trajectories ($\mu_{\underline{d}}$) as reflecting differences in comparative advantage ($\theta_i$). The i.i.d. assumption is what makes this interpretation valid: if the $\nu$ shocks are independent over time, then the only reason two workers follow different trajectories is that they have different $\theta_i$ values (different comparative advantage).

If instead the $\nu$ shocks are persistent---say a worker gets a "good urban draw" in period 1 that makes her likely to stay urban in period 2---then two workers with *identical* $\theta_i$ could follow different trajectories simply because of their shock histories. In that case, trajectory differences in $\mu_{\underline{d}}$ would partly reflect the persistent shocks, not just comparative advantage. The $\phi$ estimate would then be contaminated: what looks like "workers with low rural consumption gain the most from migration" could partly be "workers who happened to get persistent negative rural shocks look like they gained from migration."

Concretely, this is plausible because:
- Migration involves large fixed costs (moving, housing, networks). Once you move, you are more likely to stay---not because of a new i.i.d. draw, but because you already paid the cost.
- Family events (marriage, death of a parent) create correlated location shocks across periods.
- China's hukou system creates persistent institutional constraints (which the paper partially addresses by splitting the CHN sample).

This doesn't mean the results are wrong, but the paper should acknowledge that persistent non-pecuniary factors would blur the distinction between trajectories driven by comparative advantage and trajectories driven by shock persistence.

### M7. Myopic decision rule is a consequence of i.i.d., not an independent assumption

The decision rule at eq (8) (lines 291--295) compares $E[V_{it}^U]$ vs $E[V_{it}^R]$ period by period. This looks like a separate modeling choice, but it isn't---it is a *consequence* of the i.i.d. assumption on $\nu_{it}^l$.

Here's why: if a worker is deciding where to work in period $t$, and she knows that future $\nu$ shocks are i.i.d. and independent of her current choice, then her current choice cannot affect her future payoffs. The option value of being in one location vs the other is the same regardless of where she is now. So the dynamic optimization problem collapses to a sequence of static (myopic) comparisons.

If $\nu$ shocks were instead persistent (say, AR(1)), a forward-looking worker would consider the option value of her current location: being in the city today might give her a better chance of a good urban draw tomorrow. The myopic rule would then be wrong, and the set of workers at the margin of switching would change. This in turn changes which workers generate the identifying variation for $\phi$.

The practical implication is the same as M6: the i.i.d. assumption is doing heavy lifting. The paper presents the myopic rule (lines 282--284) as if it were a lightweight convenience, when in fact it and the i.i.d. assumption are two sides of the same coin. A sentence acknowledging this linkage would strengthen the exposition.

### M8. $\gamma^U = \gamma^R$ is testable but untested

Line 321 imposes symmetric covariate effects "to simplify the empirical specification." The unrestricted model at eq (10) (line 310) includes the interaction $D_{it} x_{it}'(\gamma^U - \gamma^R)$, which the restriction drops.

**How to test this:**

Run the unrestricted version of eq (10) by interacting all covariates with the urban indicator $D_{it}$:
$$y_{it} = \beta_t^R + \theta_i + \tau_i + (\beta + \phi\theta_i)D_{it} + x_{it}'\gamma^R + D_{it} x_{it}'(\gamma^U - \gamma^R) + \varepsilon_{it}$$

In Stata, this could be done within the existing GRC framework by adding interaction terms to the covariate list. Concretely, for each covariate $x_k$ currently in `covarlist`, add `c.x_k#1.choice` to the instrument and covariate lists. Then:

1. **Point estimate test:** Run the unrestricted model and test $H_0: \gamma^U - \gamma^R = 0$ jointly (Wald test on the interaction coefficients). If the interactions are jointly insignificant, the restriction is empirically supported.

2. **Sensitivity check:** Compare the restricted and unrestricted estimates of $\phi$ and $\Delta_{d_N}$. If they are similar, the restriction is innocuous for the key results even if statistically rejected.

3. **Economic prior:** The most likely violation is differential returns to education. Urban labor markets typically reward education more than rural ones ($\gamma^U_{\text{educ}} > \gamma^R_{\text{educ}}$). If this holds, imposing $\gamma^U = \gamma^R$ forces the education premium difference into the unobservable $\theta_i$, potentially biasing the estimate of $\phi$.

The test is straightforward to implement with the existing code and would substantially strengthen the paper.

### M9. Sensitivity to baseline trajectory $\underline{d}_0$ not reported

The restricted GRC (lines 387--403) is written relative to a baseline $\underline{d}_0 \in \mathcal{D}_S$. If LCA holds exactly, the choice is irrelevant (it is a reparameterization). If only approximately, different baselines could yield different $\hat\phi$.

**From the code:** The `initial_values` program ([0_programs.do:1426--1521](scripts/0_programs.do#L1426-L1521)) selects the baseline trajectory data-adaptively as the switcher trajectory with the highest absolute $t$-statistic among those with sufficient observations ($N_s / T > 5$). However, `define_switcherpars` is called with a hardcoded `base(2)` in [5_GrRC.do](scripts/5_GrRC.do) (lines 88, 164, etc.), overriding the data-driven selection for the LCA parameterization. This means the initial values use one baseline while the moment conditions use another---a discrepancy that may or may not affect convergence or final estimates depending on the optimization landscape.

The paper should report results for at least two baseline choices to demonstrate insensitivity (or flag sensitivity if it exists).

---

## Minor issues (7)

### m1. Zero-mean assumption implicit (line 218)
Stated "assuming zero means" but could note this is a normalization absorbed into $\beta_t^l$.

### m2. Time-invariant $\beta$ assumption not stress-tested (lines 285--289)
$\beta \equiv \beta_t^U - \beta_t^R = \text{const}$ is attributed to Lemieux (1998) but its plausibility is not discussed. Testable in principle.

### m3. $\varepsilon_{it}$ independence assumptions not stated (lines 302--305)
No assumptions on the error term's relationship to $\theta_i$, $\tau_i$, $\nu_{it}$, or $D_{it}$.

### m4. Equation (10$'$) numbering is non-standard (line 324)
`\tag{10$'$}` is unusual in journal articles.

### m5. Clustering of standard errors not discussed in text
Panel data on individuals requires at minimum individual-level clustering. The code does cluster at the individual level (`vce(cluster pid)` in [0_programs.do:1581](scripts/0_programs.do#L1581)), but the paper does not state this.

### m6. SUTVA for GE policy claims (line 821)
Conclusion claims "promoting migration would reduce misallocation and increase overall growth"---a GE claim the PE model cannot support.

### m7. Possible typo at line 790
"In contrast, this difference is reversed in the full sample" should probably read "in the balanced sample."

---

## Positive findings

1. The projection coefficient derivation ($b_U$, $b_R$) is mathematically correct; $b_U - b_R = 1$ holds as required.
2. The economic interpretation of $\phi$ (lines 253--255) correctly maps to the variance-covariance structure.
3. The first version of the restricted GRC equation (lines 388--395) correctly derives from the LCA restriction.
4. The progression OLS $\to$ FE $\to$ unrestricted GRC $\to$ restricted GRC is pedagogically effective.
5. Cross-country consistency of negative $\phi$ is a significant robustness feature that is undersold in the current draft.

---

## Identifying assumptions: collection and integration proposal

### The five maintained assumptions

The model requires all five of the following to hold jointly. Currently they are scattered across subsections 2.1.1--2.2.2.

1. **Time-invariant location-specific productivity** (line 212): $\theta_i^U$ and $\theta_i^R$ do not change over time. This rules out learning, human capital accumulation from migration experience, or skill depreciation. Combined with the time-varying $\beta_t^l$, this means individual productivity is fixed but aggregate conditions can shift.

2. **i.i.d. non-pecuniary shocks** (line 277): $\nu_{it}^l \overset{iid}{\sim}$ across $i$, $t$, and $l$. This ensures (a) migration trajectories reflect comparative advantage, not shock persistence, (b) the period-by-period decision rule is equivalent to forward-looking optimization, and (c) $\varepsilon_{it}$ is orthogonal to trajectory membership conditional on $\theta_i$.

3. **Constant average rural-urban gap** (line 288): $\beta \equiv \beta_t^U - \beta_t^R$ does not vary over time. Levels $\beta_t^R$ can vary (absorbed into period FEs) but the gap is stable. This is needed to define the worker-specific return $\Delta_i = \beta + \phi\theta_i$ as time-invariant.

4. **Symmetric covariate effects** (line 321): $\gamma^U = \gamma^R \equiv \gamma$. Observable characteristics affect consumption the same way in both locations. This is a simplification that drops the $D_{it} x_{it}'(\gamma^U - \gamma^R)$ interaction from the estimating equation.

5. **Linear comparative advantage (LCA)** (line 378): $\Delta_i = \beta + \phi\theta_i$. Returns to urban location are linear in (rescaled) comparative advantage. This is the restriction that enables extrapolation to non-switchers and is partially testable via the $J$-test.

### Where to integrate

**Option A (preferred): Add a short subsection** at the end of Section 2.2, after eq (10$'$) and before Section 2.2.1. Title it "Maintained assumptions" or "Assumptions for identification." Collect all five in a numbered list (similar to the list above), with one sentence each on economic content and testability. This creates a single reference point for the reader before the GRC machinery begins.

**Option B: End of Section 2.2.2** (after eq \eqref{eq:restricted-GRC}, before the estimation paragraph at line 436). This places the assumption inventory right before estimation, which is when the reader most needs to know what is being assumed. Slightly less natural for the flow since the assumptions are introduced earlier.

**In either case**, each assumption should note:
- Whether it is testable (assumptions 3, 4, and 5 are; assumptions 1 and 2 are not directly testable but have observable implications)
- What breaks if it fails (briefly)
- Where in the paper it is invoked

This consolidation would address the econometrics-critic's observation that a referee cannot currently assess the joint plausibility of the identification strategy because the assumptions are distributed across 6 pages.
