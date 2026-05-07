# Econ critic review: unary-null reparameterization memo

Target: [`docs/notes/2026-05-07_unary-null-reparameterization.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md)
Reference code: [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)
Date: 2026-05-07
Mode: Review (exploration fast-track applies; this is a docs note about an exploratory backend choice).

## Summary

The memo proposes refitting the auxiliary regression with $\hat\theta_d = \hat\alpha_d - \hat\alpha_{\underline{d}_0}$ as a per-trajectory regressor interacted with $D_i$, so that $\phi$ becomes a unary coefficient amenable to `boottest`'s one-pass CI inversion.
The arithmetic of the reparameterization is correct under one strong condition (LCA holds *and* the trajectory FE in the second stage are not the same alphas used to build $\hat\theta_d$, or---if they are---the second-stage normalization is handled).
The generated-regressor discussion is roughly right but mislabels which direction the bias goes and misses at least two standard alternatives.
The validation criterion is sensible as a sanity check but is the wrong object if the goal is to defend D-onepass as a substitute for D-grid: the test statistic, not the CI endpoints, is what should agree.

Severity-tagged issues follow.

---

## CRITICAL

### C1. Collinearity between $\hat\theta_{d_i} D_i$ and the trajectory FE in the second stage

Lens: identification design.
Confidence: HIGH.

The second-stage regression as written at [`docs/notes/2026-05-07_unary-null-reparameterization.md:38`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md) is

$$y_i = \alpha_{d_i} + \beta_{\underline{d}_0} D_i + \phi \cdot \hat\theta_{d_i} D_i + X_i \gamma + u_i.$$

The trajectory FE $\alpha_{d_i}$ are free in the second stage (line 42).
But $\hat\theta_d = \hat\alpha_d - \hat\alpha_{\underline{d}_0}$ was constructed from the *first-stage* FE that are exactly the same fixed effects (saturated trajectory dummies on the same data, same controls).
After demeaning by the second-stage FE, the regressor $\hat\theta_{d_i}$ (the level shifter) is collinear with the trajectory FE and absorbs.
Only the *interaction* $\hat\theta_{d_i} D_i$ survives, so the parameterization is fine for the level---but only because of within-trajectory variation in $D_i$.

The substantive issue: among observations with the same $d$, $\hat\theta_{d_i} D_i$ varies only through $D_i$.
So $\hat\theta_{d_i} D_i$ is a deterministic affine function of $D_i$ within each trajectory: $\hat\theta_d \cdot D_i = c_d \cdot D_i$ with $c_d$ a per-trajectory scalar.
That means the regressor matrix in the second stage spans the same column space as the *interactions* $\{\mathbb{1}\{d_i = s\} D_i\}_{s \in \mathcal{S}_R}$ (after partialling out the level $D_i$): the unary regression is a one-degree-of-freedom restriction of the saturated $J_R$-coefficient regression with restriction $\beta_s - \beta_{\underline{d}_0} = \phi (\hat\alpha_s - \hat\alpha_{\underline{d}_0})$, where the alphas are the *first-stage* OLS estimates.

This is *not* the LCA restriction $\beta_s - \beta_{\underline{d}_0} = \phi (\alpha_s - \alpha_{\underline{d}_0})$ (population alphas).
It is a sample-analog version with $\hat\alpha$ in place of $\alpha$.
Whether they coincide asymptotically depends on whether the first-stage $\hat\alpha_d$ is consistent for the population $\alpha_d$ that enters the LCA restriction.
For a saturated trajectory FE with the same controls, $\hat\alpha_d \to_p \alpha_d$ if the $\alpha_d$ in the LCA restriction is defined as the rural-side trajectory mean (i.e., the same population object the first-stage FE estimates).

This *is* what the LCA model intends, so the parameterization identifies $\phi$ asymptotically.
But the memo never states this---it implicitly assumes it---and never confirms that the $\alpha_d$ in the LCA restriction $\Delta_i = \beta + \phi \theta_i$ with $\theta_i = b_R(\theta_i^U - \theta_i^R)$ is the same population object as the rural-side trajectory mean.
If $\theta_d$ in the LCA restriction is (for example) the *expectation of $b_R(\theta_i^U - \theta_i^R)$ given trajectory $d$*, that is *not* in general $E[y^R \mid d] = \alpha_d$ unless $\alpha_d$ is normalized in a specific way.

Action item for the human: confirm that the population analog of $\hat\alpha_d$ in the first-stage regression equals (up to a known scalar) the $\theta_d$ that enters the LCA restriction.
If not, $\phi$ in the memo's second stage is a rescaled and possibly biased version of the LCA $\phi$.
The D-grid path uses the same $\hat\alpha_d$ in its restriction $r_s(\phi_0) = (\beta_s - \beta_{\underline{d}_0}) - \phi_0(\alpha_s - \alpha_{\underline{d}_0})$ ([`lca_inversion.py:13`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)), so the two should be consistent with each other---but if there is a population-vs-sample-alpha conflation in the memo's interpretation of $\phi$, it inherits from the existing code rather than being introduced by the reparameterization.

### C2. The second-stage $\phi$ is not numerically equal to D-grid $\phi$ at any finite $J_R$

Lens: identification design.
Confidence: HIGH.

Under the recoded design, the D-grid CI inverts a *joint* $J_R$-dimensional Wald: the LCA restriction must hold simultaneously across all non-base switchers.
The unary second stage imposes the LCA restriction *as a regression model* and then inverts a unary Wald on $\phi$.
These deliver the same point estimate only if the over-identifying restrictions hold exactly in sample, i.e., if all $J_R$ contrasts $\{(\hat\beta_s - \hat\beta_{\underline{d}_0}) - \phi(\hat\alpha_s - \hat\alpha_{\underline{d}_0})\}$ are zero at the same $\phi$.
With $J_R \geq 2$ and any finite-sample noise, they will not.

The unary-stage $\hat\phi$ is the *minimum-distance* (or, equivalently, the GLS-projection-onto-LCA) estimate, weighted by the second-stage regression's implicit weighting matrix---which is *not* the efficient minimum-distance weighting matrix.
The implicit weighting is

$$W_{\text{unary}} \propto \sum_i (\hat\theta_{d_i} D_i)(\hat\theta_{d_i} D_i)' = \sum_d \hat\theta_d^2 \cdot N_d^{(1)},$$

where $N_d^{(1)}$ is the count of treated obs in trajectory $d$.
This is OLS-on-the-restriction weighting.
The D-grid joint Wald inverts using $\hat V$ from the saturated OLS, which is closer to the minimum-distance weighting matrix in spirit but not identical to it (the existing `grid_md_inversion` at [`lca_inversion.py:196`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) is the actual MD object).

Consequence: the unary $\hat\phi$ can differ from the D-grid acceptance-region centroid by an amount that grows with the over-identification residual, even at $B = \infty$.
The memo says (line 71) "asymptotically the two CIs coincide if the LCA holds; at finite $J^*$ they differ."
This is not quite right.
Asymptotically, *both* estimators are consistent for $\phi$ if the LCA holds.
But they are different estimators with different finite-sample distributions and different efficiency---they do not coincide even at $B = \infty$ unless the LCA holds *exactly in sample* or $J_R = 1$.
The memo's wording lets the reader think the gap is just simulation noise.

Action item: state explicitly that the unary CI is for $\phi$ under a different (less efficient, OLS-weighted) estimator, and that comparing CIs is comparing two different things, not Monte-Carlo replicates of the same object.

---

## MAJOR

### M1. The pass criterion compares CIs, not test statistics

Lens: inference.
Confidence: HIGH.

[`docs/notes/2026-05-07_unary-null-reparameterization.md:93`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md): "unary CI endpoints lie within the D-grid CI to $\pm 0.01$ on $\phi$."

This is the wrong target if the question is "does D-onepass produce the same inference as D-grid."
The two CIs are inversions of two different test statistics, so endpoint agreement reflects a confounded comparison of (i) point estimate gap from the OLS-vs-MD weighting issue in C2, (ii) bootstrap simulation noise, (iii) generated-regressor variance the unary path omits.
Even if endpoints agree to $\pm 0.01$, you have not shown that D-onepass and D-grid *test* the same null at the same level.

The right check is one of the following.

First, at $\phi_0 = \hat\phi_{\text{unary}}$ and at $\phi_0 = \text{grid endpoint}$, does the unary-stage Wald (or `boottest` $t$) agree with the D-grid Wald in absolute value at the corresponding grid point?
This isolates the test-statistic agreement.

Second, on the same data, simulate the joint sampling distribution of $(\hat\phi_{\text{unary}}, \text{D-grid CI})$ via cluster bootstrap and check whether the unary CI's coverage of the D-grid CI is roughly nominal.
This is more expensive but is the correct frequentist comparison.

The $\pm 0.01$ tolerance on $\phi$ is also unmotivated.
For TZA $J = 1500$, what is the typical CI half-width?
If the D-grid CI half-width is, e.g., $0.05$, then $\pm 0.01$ on each endpoint is $\pm 20\%$ of the half-width---not a tight check.

### M2. Generated-regressor handling: missing alternatives

Lens: inference.
Confidence: HIGH.

The memo lists three handling paths at lines 74--83.
Standard alternatives not in the list:

First, Murphy-Topel-style analytical correction.
For two-step estimators where the first stage produces a finite-dimensional generated regressor, there is a closed-form variance correction (Murphy and Topel 1985, JBES; Newey and McFadden 1994 sec. 6).
Here $\hat\theta_d$ is a finite vector (one entry per trajectory) and the second-stage influence function is standard, so Murphy-Topel applies.
This gives an analytical SE that accounts for first-stage estimation without nesting bootstraps.
It does not solve the weak-ID problem, but it solves the generated-regressor problem cleanly.

Second, sample-splitting / cross-fitting.
Estimate $\hat\theta_d$ on half the clusters and run the second stage on the other half.
This eliminates the generated-regressor bias asymptotically without correcting the variance, at the cost of efficiency.
Useful as a robustness check, not a primary path.

Third, the score-bootstrap / multiplier-bootstrap that bootstraps the joint score of the two-step system.
This is what `boottest` essentially does for one-step, and there is literature extending it to multi-step (Kline and Santos 2012; MacKinnon 2023 review).
This is more or less option 1 in the memo (joint cluster bootstrap), but the memo conflates "resample pids and refit both stages" (slow) with "bootstrap the joint score" (fast).
The latter does not require refitting the first stage on each bootstrap replication.

Also, the memo's first option (line 76) says "the compute saving over D-grid mostly evaporates."
That is true for naive nonparametric cluster bootstrap but is not true for the score-bootstrap variant, which costs roughly $2 \times$ a single `boottest` call.

Action item: expand the menu to at least four options and distinguish naive resample-and-refit from analytical / score-based corrections.

### M3. Direction of the generated-regressor bias understated

Lens: inference.
Confidence: MEDIUM.

[`docs/notes/2026-05-07_unary-null-reparameterization.md:72`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md): "a naive cluster-robust SE on the second stage understates uncertainty by ignoring estimation of $\hat\theta_d$."

Direction is right in the typical case but not universal.
Pagan (1984, IER) and the standard generated-regressor result give:

$$\text{Var}(\hat\phi_{\text{2nd}}) = \text{Var}(\hat\phi \mid \hat\theta) + \text{(contribution from } \hat\theta\text{ uncertainty)},$$

and the second term is positive only if the first-stage estimation contributes net additional variance after accounting for the fact that the first and second stages share data.
With shared data and overlapping moment conditions (which is the case here---both stages are OLS on the same observations), the second term can be negative because the cross-covariance between first-stage and second-stage estimating equations can offset.
This is a standard subtlety, e.g., when the same residuals enter both stages.

Action item: hedge the directional claim, or derive the sign for this specific design.

Also, line 79: "flag the resulting CI as a lower bound on the true CI width."
That phrasing assumes upward-only correction.
If the cross-covariance term is negative, the naive CI overstates uncertainty and the corrected CI is *narrower*.
Either case is possible without a derivation.

### M4. LCA imposed vs tested distinction is correct but the implication for "robustness to LCA misspecification" is overstated

Lens: identification design.
Confidence: HIGH.

The memo correctly notes (lines 69--71) that the unary stage imposes the LCA whereas the D-grid path tests the LCA jointly.
But the claim that "the recoded-design CI is more robust to LCA misspecification because it rejects $\phi_0$ where over-identification fails" needs care.

The D-grid CI is the inversion of a joint Wald for $(\beta_s - \beta_{\underline{d}_0}) - \phi_0 (\alpha_s - \alpha_{\underline{d}_0}) = 0$ for all $s$.
If the LCA is misspecified, the Wald can reject every $\phi_0$ in the grid, producing an *empty* CI.
That is not "robustness"---it is detection.
The unary CI under misspecification is a CI for the OLS-projection-onto-LCA pseudo-true value, which is a defined object and will not be empty.

Both behaviors have merit (D-grid: hypothesis test of LCA + CI conditional on LCA, possibly empty; unary: pseudo-true-value CI, never empty).
The memo frames this as D-grid being strictly more robust.
That is wrong---they answer different questions under misspecification.

### M5. `boottest` / `lca_inversion.py` mismatch in dof

Lens: inference.
Confidence: MEDIUM.

The D-grid path in [`lca_inversion.py:186`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) uses $\chi^2_{J_R}$ where $J_R = \text{len(switchers\_kept)} - 1$ (line 160).
The memo at line 24 calls this a $\chi^2$-based CI and at line 9 calls the LCA test "a $(J_R - 1)$-dimensional joint null."
The dimensionalities don't match: the code uses $J_R$ degrees of freedom (one per non-base switcher), the memo says $J_R - 1$.

Either the memo is using a different definition of $J_R$ (counting non-base switchers, in which case dof should be $J_R$, not $J_R - 1$) or there's a typo.
Worth resolving before the validation pass criterion is operationalized---wrong dof means wrong critical values means wrong CI for the validation reference.

Note: [`lca_inversion.py:160`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) defines `J_R = len(other)` where `other = [s for s in switchers_kept if s != base]`.
So the *code* sets $J_R$ = number of non-base switchers and uses dof = $J_R$, which is correct for $J_R$ contrasts.
The memo's wording on line 9 ("$(J_R - 1)$-dimensional joint null") is then off by one in some convention.

---

## MINOR

### m1. "Saturated first stage" is overspecified

Lens: identification design.
Confidence: LOW.

[`docs/notes/2026-05-07_unary-null-reparameterization.md:29`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md): "fit a saturated first-stage OLS of $y$ on the trajectory FE ... and the trajectory-by-treatment indicators."

If the first stage includes the trajectory-by-treatment interactions $\{\mathbb{1}\{d_i = d\} D_i\}$ then $\hat\alpha_d$ is the rural-side mean for trajectory $d$ (fitted at $D = 0$).
If those interactions are omitted, $\hat\alpha_d$ is a within-trajectory weighted average of $D = 0$ and $D = 1$ outcomes, which is *not* the rural-side mean and contaminates $\hat\theta_d$.
The memo does include them (line 29) but should explicitly note that this is what makes $\hat\theta_d$ an estimate of the rural-side trajectory differential.

### m2. "Unbalanced" controls dropped from the sketch

Lens: identification design.
Confidence: LOW.

[`lca_inversion.py:112`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) shows the auxiliary OLS includes `unbalanced` and `unbalanced_choice` indicators.
The Stata sketch in the memo (lines 46--60) does not.
If the validation pass is run on a balanced subsample, that's fine; if on the unbalanced sample, the sketch is missing two indicators that materially change $\hat\theta_d$.

### m3. "Linear contrast" framing in line 20 is correct but the phrasing "linear in the OLS coefficients for fixed phi" is what makes D-grid trivially fast

Lens: inference.
Confidence: LOW.

The memo could note that this is *exactly* why the D-grid path is cheap: the Jacobian is constant, so the per-grid-point cost is one matrix-vector product.
The main expense is the bootstrap critical value at each grid point, not the Wald computation.
The "30x compute reduction" claim (line 65) is therefore really "30x bootstrap-replication reduction"---which is still real but is a different framing.
Worth saying so the cost calculus is explicit.

### m4. Validation case selection: TZA $J = 1500$ is one cell

Lens: external validity.
Confidence: LOW.

[`docs/notes/2026-05-07_unary-null-reparameterization.md:87`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md): the validation runs at TZA $J = 1500$ recoded covs_trend.
A single cell is a thin reed.
At minimum, validate at one CHN cell and one IDN cell as well, since (a) sample sizes differ, (b) cluster counts differ, (c) the over-identification structure differs (CHN has hukou-driven heterogeneity that the J-test rejects in the pooled sample, per CLAUDE.md's "Known issues").
If D-onepass and D-grid agree on TZA but disagree on CHN, you want to know that before committing.

### m5. "Compute saving evaporates" needs a number

Lens: not directly econ; methodology presentation.
Confidence: LOW.

Lines 76--77 say nesting `boottest` inside an outer cluster bootstrap mostly evaporates the 30x saving.
With $B_{\text{outer}} = 999$ and $B_{\text{inner}} = 9999$, the nested cost is $\sim 10^7$ inner replications vs $30 \times 9999 \approx 3 \times 10^5$ for D-grid.
That's a $30\times$ *increase* over D-grid, not "evaporation of saving."
If you mean a low-replication outer bootstrap, say so.

---

## Overall assessment

The reparameterization is mathematically coherent, but the memo presents it as a near-equivalent reformulation of D-grid when in fact it is a different estimator (OLS projection onto LCA, not minimum-distance) with a different test (unary Wald on a generated regressor, not joint Wald on free parameters) and a different interpretation under misspecification (pseudo-true-value CI, not LCA test).
Issues C1 and C2 are the load-bearing ones for the human's judgment.
M1 (validation criterion) is the most actionable.
M2--M4 are framing problems that affect how the memo will be read by coauthors.

Does the identification strategy survive scrutiny?
The unary path identifies *something*---specifically, the OLS-projection $\phi$ under an imposed LCA, with a generated-regressor variance correction needed for honest inference.
Whether that "something" is what the paper claims to be reporting under D-grid is a separate question that requires the human to confirm: does the LCA $\phi$ in the manuscript denote the population MD parameter (D-grid), the population OLS-projection parameter (unary), or are these the same object under LCA truth?
If the latter, both paths target it.
If not, the unary path tests a different hypothesis and the validation pass criterion in the memo is comparing apples and oranges.

This memo is appropriate as a feasibility note for an exploration backend.
It is not yet ready to support a publication-table claim that D-onepass replaces D-grid.
For that, items C1, C2, M1, and M2 require explicit treatment.
