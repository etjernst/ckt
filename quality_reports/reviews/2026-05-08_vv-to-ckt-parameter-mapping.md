# How Verdier (2020)'s procedure maps to CKT's, and where the slide deck got it wrong

**Date:** 2026-05-08
**Author:** Claude (Opus 4.7)
**Audience:** Emilia (CKT)
**Status:** Draft for review.
Slide deck edits are paused until this memo is approved.
This memo is about *what each procedure does* and how the two map onto each other.
Empirical results (point estimates, condition numbers, convergence flags from the current smoke runs) are deliberately omitted, because we do not yet trust those numbers.

## Why this memo exists

I added a "diagnostics" section to [paper/slides/verdier-modification.tex](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.tex) without first verifying the parameter mapping it relied on.
You pushed back on five separate items, all of which I now believe correct.
Rather than patch the slides, I went back to (1) the published Verdier (2020) paper, (2) our own equivalence-proof memo, and (3) the live CKT/VV port (`_vv_firststage_projection`, `run_vv_vanilla` in [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/RP7/scripts/0_programs.do)).
This memo documents what those sources say, where the existing deck (slide 9 and slide 12) is wrong, and where my new section made it worse.

Section references below to "VV" are to the published paper, [Verdier (2020), J. Applied Econometrics; PDF in repo](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/papers/extracted/verdierAverageTreatmentEffects2020/verdierAverageTreatmentEffects2020.pdf).

## 1. What Verdier (2020) does

### 1.1 The model

VV §2 (eq. 2.4, p.4) writes the CRC model as

$$y_{it} = a_i + f_t + b_i x_{it} + u_{it},$$

where $a_i$ is the worker's untreated mean (rural baseline level), $b_i$ is the worker-specific treatment effect (urban return), $f_t$ a time effect, and $u_{it}$ idiosyncratic.

VV §2.3 (p.7) introduces the simple-extrapolation identifying assumption: $E(b_i \mid a_i, x_{i1}, \ldots, x_{iT}) = E(b_i \mid a_i)$, with the linearity sufficient condition (footnote 19, p.10):

$$a_i = \alpha_0 + \alpha_1 b_i + e_i, \qquad E(e_i \mid b_i, c_{i1}, \ldots, c_{iT}) = 0.$$

So VV's LCA writes baseline $a$ as a linear function of return $b$.
$\alpha_1^{VV}$ is therefore the slope of $a$ on $b$.

### 1.2 Step 1: First-step CRC regression

VV §3.1 (p.13--14) defines Step 1 as an OLS regression of $y_{it}$ on:

- indicator variables for each cross-sectional observation, $d_{it}^{j} = \mathbb{1}\{i = j\}$ for $j = 1, \ldots, n$;
- the interaction of these indicators with treatment status, $x_{it} d_{it}^{j}$;
- and either time-period indicators $\mathbb{1}\{t = s\}$ (no covariates) or control covariates $z_{it}$ (with covariates).

The estimated coefficients on $d_{it}^{j}$ and $x_{it} d_{it}^{j}$ recover, for each *mover* $j$, noisy estimates $\hat a_j$ (the within-$j$ untreated-period mean residual) and $\hat a_j + \hat b_j$ (the within-$j$ treated-period mean residual).
For untreated stayers only $\hat a_j$ is well-defined; for treated stayers only $\hat a_j + \hat b_j$.

Mechanically:

$$\hat a_i = \tfrac{1}{|\{t: x_{it} = 0\}|}\sum_{t: x_{it} = 0} (y_{it} - z_{it}'\hat\gamma), \quad \hat a_i + \hat b_i = \tfrac{1}{|\{t: x_{it} = 1\}|}\sum_{t: x_{it} = 1} (y_{it} - z_{it}'\hat\gamma).$$

Then $\hat b_i = (\hat a_i + \hat b_i) - \hat a_i$ for movers.

### 1.3 Step 2 (simple extrapolation): IV regression

VV §3.2 (p.16) is unambiguous about the regression direction:

> "$\alpha_0$ and $\alpha_1$ are therefore parameters in an instrumental variable regression model where the observed variable $\hat a_i$ is the **dependent** variable, the observed variable $\hat b_i$ is the **endogenous covariate**, and instrumental variables are given by treatment status history $\{x_{i1}, x_{i2}\}$."

That is: regress $\hat a_i$ on $\hat b_i$, instrument $\hat b_i$ with the binary trajectory pattern $(x_{i1}, \ldots, x_{iT})$, run on movers only.
$\alpha_1$ is identified by the moment

$$E[(x_{i\bullet})\, (\hat a_i - \alpha_0 - \alpha_1 \hat b_i)] = 0,$$

stacked across periods.

The instrument is the *trajectory pattern itself*.
Why this works as an instrument: $\hat b_i$ is a noisy estimate of $b_i$, and (under the simple extrapolation assumption) $b_i$ is the only thing that connects $a_i$ to treatment status.
So $x_{i\bullet}$ is correlated with $b_i$ (relevance) but uncorrelated with the LCA error $e_i$ (exogeneity).

### 1.4 Step 2 (robust extrapolation): IV regression with cluster fixed effects

VV §3.3 (p.18) generalizes Step 2 to allow correlated cost shifters that originate from cluster-level (e.g., village-level) sources.
The robust version is:

> "fixed-effects instrumental variable regression of $\hat a_i$ on $\hat b_i$ using $\{x_{i1}, \ldots, x_{iT}\}$ as instrumental variables, with fixed effects indexed by the variable $v_i$."

Same IV regression, but with cluster ($v_i$) fixed effects in the *regression* (not in the instrument).
By Frisch-Waugh, this is algebraically identical to:

- partial $v_i$ FE out of $\hat a_i$, $\hat b_i$, and the instruments;
- run no-FE IV on the residuals.

These are equivalent.
The published paper writes the FE-in-regression form; an equivalent FWL formulation cluster-demeans the LHS, RHS, and instruments and runs no-FE IV.
Our port uses the FWL form (see §2 below).

### 1.5 What the parameters $\alpha_1$, $\alpha_0$ mean

By footnote 34 (p.26), $\alpha_1 = \mathrm{Corr}(a_i, b_i) \cdot \sigma(b_i)/\sigma(a_i)$.
This is the population OLS slope of $a$ on $b$.
Its magnitude is bounded above by $\sigma(b)/\sigma(a)$ when $|\mathrm{Corr}(a,b)| \le 1$.
$\alpha_0$ is the corresponding intercept.

ATE for stayers comes from a plug-in: untreated-stayer ATE $= (E(a \mid \text{never}) - \alpha_0)/\alpha_1$ in the simple version, with cluster-FE corrections in the robust version.

## 2. What our port does

The port lives in two programs in [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/RP7/scripts/0_programs.do): `_vv_firststage_projection` (lines 3506--3702) and `run_vv_vanilla` (lines 3735--4163).
We port VV's published `firststage_projection.do` and `robust.do` (from his replication archive) with a straightforward CKT renaming: `lyield`$\to$`lndepvar`, `hybrid`$\to$`urban`, `hhid`$\to$`pid`, `per`$\to$`period`, `provd`$\to$`vfirst`.

### 2.1 Step 1 in the port: `_vv_firststage_projection`

Three substantive operations.

**a. Construct `pid_urban = pid * 10 + urban`.**
This is a unit-by-treatment-state index --- one identifier per (worker, regime) pair, exactly VV's `hhid_hybrid`.

**b. Partial out covariates by `pid_urban`.** For each covariate `w_i`:

```stata
areg w`v', absorb(pid_urban)
predict wd`v', resid
```

And similarly for the outcome `yd`.
This is the Frisch-Waugh half-step that takes out individual-by-regime fixed effects, leaving the within-(worker, regime) covariate residuals.

**c. Recover $\hat a_i$ and $\hat a_i + \hat b_i$ via the within-(pid, regime) means of $y - \hat\gamma_{\rm fs} w$.**
After fitting $\hat\gamma_{\rm fs}$ from `reg yd wd1-wd_nw, nocons` on the residuals:

```stata
predict _vv_xb, xb       // gamma_fs * w (full sample, not residualized)
gen _vv_t1 = depvar - _vv_xb
egen _vv_resid_pu_mean = mean(_vv_t1), by(pid_urban)   // mean of (y - gamma'w) within (pid, regime)
gen _vv_t2 = _vv_resid_pu_mean if  urban   ; egen apb = mean(_vv_t2), by(pid)
gen _vv_t2 = _vv_resid_pu_mean if !urban   ; egen a   = mean(_vv_t2), by(pid)
gen return = apb - a if switcher
```

So the port produces, for every worker:

- `a` = within-(pid, regime=rural) mean of $y - \hat\gamma_{\rm fs}'w$ = $\hat a_i$ in VV's notation.
- `apb` = within-(pid, regime=urban) mean of the same = $\hat a_i + \hat b_i$.
- `return` = `apb - a` = $\hat b_i$, defined only for switchers.

This matches VV §3.1.

### 2.2 Step 2 in the port: `run_vv_vanilla`

Three phases.

**Phase B (lines 3793--3805): a first-stage iterated GMM to get a weight matrix.**
The moments are

$$E[\widetilde x_{it,p} \cdot (a_i - \alpha_1 \cdot \mathrm{return}_i)] = 0 \quad \text{for } p = 1, \ldots, T,$$

where $\widetilde x_{it,p}$ is the cluster-residualized period-$p$ treatment indicator, built as

```stata
reg urban`per' i.vfirst if switcher           // urban`per' = 1 if treated in period p
predict urban`per'd if switcher & urban`per' != ., resid
```

This is the FWL-equivalent of VV's "FE-in-regression" formulation: the residual `urban`per`d` is the within-cluster deviation of the period-$p$ treatment indicator.
The first-stage iterated GMM is run only to recover an optimal weight matrix `W`; it is not the headline estimator.

**Phase C (lines 3810--3832): build optimal IVs in mata.**
Stack the cluster-residualized indicators into a matrix `z`, then form `z_opt = z * (W * (z' * x))`, where `x = return`.
This is the optimal-IV combination of the period-specific moments under heteroscedastic clustering.

**Phase D--G (lines 3837--4081): the joint GMM.**
The joint GMM stacks three blocks of moments:

1. First-stage projection moments (Phase D): `mf1 = yd - sum(gamma_i * wd_i)`, instrumented by `wd1...wd_nw, nocons`. These re-estimate $\gamma$ jointly.
2. The LCA moment (Phase E): $\varepsilon = a - \alpha_1 \cdot \mathrm{return}$, instrumented by `z_opt1`. This identifies $\alpha_1$.
3. ATE moments and overid moments: per-period ATE-style moments to recover $\Delta_{\rm never}$, $\Delta_{\rm switcher}$, etc., plus per-period $\eta_p$ "auxiliary" moments tested for being zero (overid test on $T-1$ degrees of freedom).

The headline parameter is `_b[alpha1:_cons]`, returned to the caller as `e(phi)` (line 4128--4130).
The label "phi" in the return is misleading: the *value* in `e(phi)` is VV's $\alpha_1$ in VV's convention, not CKT's $\phi$ from the trajectory-pooled GRC.
See §4 below.

### 2.3 Where our procedure differs from VV's published one

- **VV does sequential 2SLS** (Step 1, then Step 2 IV).
  Our port does a **joint GMM** that stacks the first-stage and second-stage moments, plus ATE-recovery moments, in a single optimization.
  The motivation is to propagate Step 1 noise into the Step 2 standard errors correctly; the cost is a much larger parameter vector ($n_w + 7T + 3$ parameters) and stiffer numerical optimization.
- **VV's published instruments are raw treatment-history indicators** $\{x_{i1}, \ldots, x_{iT}\}$ with cluster FE in the IV regression.
  Our port uses **cluster-residualized period-treatment indicators** with no FE in the IV regression.
  By Frisch-Waugh these are equivalent, but the codebase looks different from a literal reading of VV.
- **VV uses the empirical first-step OLS for $\hat\gamma$ once.**
  Our joint GMM **re-estimates $\gamma$** as part of the joint moment system, which is in principle more efficient under correctly-specified moments.

## 3. Side-by-side mapping

| Object | VV (paper) | Our port (code) | Same thing? |
|---|---|---|---|
| Worker baseline | $a_i$ | `a` | yes |
| Worker treated mean | $a_i + b_i$ | `apb` | yes |
| Worker return | $b_i$ | `return` (= `apb - a`, switchers only) | yes |
| Cluster index | $v_i$ (village) | `vfirst` (first-wave province) | yes, by analogy |
| Treatment status | $x_{it} \in \{0,1\}$ | `urban` (binary) | yes |
| Trajectory pattern | $\{x_{i1}, \ldots, x_{iT}\}$ | `urban1, urban2, ..., urbanT` (period-specific dummies) | yes |
| Step 1 estimator | OLS with worker + worker$\times$treatment FE | `areg ..., absorb(pid_urban)` then within-mean recovery | yes (Frisch-Waugh equivalent) |
| Step 2 estimator (simple) | IV: $\hat a$ on $\hat b$, instrument with $\{x_{i\bullet}\}$ | not implemented separately; `run_vv_vanilla` is the robust version | --- |
| Step 2 estimator (robust) | IV with cluster FE, instrument with $\{x_{i\bullet}\}$ | joint GMM with cluster-residualized period-treatment instruments | yes (Frisch-Waugh equivalent) but stacked with other moments |
| Inference | clustered cluster bootstrap or analytical SE | `vce(cluster vfirst)` from joint GMM | both cluster-robust at $v_i$ |
| Headline parameter (slope) | $\alpha_1$ (slope of $a$ on $b$) | `_b[alpha1:_cons]`, returned as `e(phi)` | yes --- both are the slope of $a$ on $b$ |

The note in the last row is the critical one: we *implement* VV's $\alpha_1$, but we *return* it under the name `phi`.
That is a labeling choice (or labeling mistake) inside `run_vv_vanilla`, not a computational difference.

## 4. The conceptual issue: VV's $\alpha_1$ vs CKT's $\phi$

These are different population parameters.
The distinction is what the deck currently elides.

### 4.1 The two regression directions

**VV** writes the LCA as

$$a_i = \alpha_0 + \alpha_1 b_i + e_i,$$

so $\alpha_1$ is the slope of *baseline* on *return*.
By footnote 34, $\alpha_1 = \mathrm{Corr}(a, b)\, \sigma(b)/\sigma(a)$.

**CKT** writes the LCA as

$$\Delta_i = \beta + \phi \theta_i + \xi_i,$$

so $\phi$ is the slope of *return* on *comparative advantage*, where $\theta_i = b_R(\theta_i^U - \theta_i^R)$ is rescaled comparative advantage.
$\phi$'s population formula is $\mathrm{Corr}(\Delta, \theta) \cdot \sigma(\theta)/\sigma(\Delta)$, but evaluated against $\theta_i$, not against $a_i$.

Two distinctions between $\alpha_1$ and $\phi$:

- the *direction* of the regression (slope of $a$ on $b$ vs slope of $\Delta$ on $\theta$);
- the *regressor* on the right-hand side (rural baseline level $a$ vs comparative advantage $\theta$).

CKT's $\theta_i = b_R(\theta_i^U - \theta_i^R)$ is a function of *both* skills.
VV's $a_i$ is a function of $\theta_i^R$ alone (the rural intercept).
So $\theta_i \ne a_i$ structurally except in the special case where there is only one underlying skill.

### 4.2 The deterministic-LCA limit

If we (i) shut off the LCA error term ($\xi_i = 0$, $e_i = 0$) and (ii) collapse to one skill so that $\theta_i = a_i$, then

$$\Delta_i = \beta + \phi a_i \iff a_i = -\beta/\phi + (1/\phi)\Delta_i,$$

so $\alpha_1 = 1/\phi$.
This is the identity claimed in our equivalence-proof memo §7.5: [2026-04-25_robust-vv-equivalence-proof.md, line 109](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-25_robust-vv-equivalence-proof.md).

It is a **special case**, not a general result.
Two ways the identity breaks:

- *Noise:* with $\xi_i \ne 0$ the OLS slope of $a$ on $b$ is $\mathrm{Corr}\cdot\sigma(b)/\sigma(a)$ and the OLS slope of $b$ on $a$ is $\mathrm{Corr}\cdot\sigma(a)/\sigma(b)$.
  Their product is $\mathrm{Corr}^2 \le 1$, so they are reciprocal only when $|\mathrm{Corr}| = 1$.
- *Two-skill structure:* $\theta_i \ne a_i$, so $\phi$ (slope of $\Delta$ on $\theta$) and the slope of $\Delta$ on $a$ are different population parameters in the first place.

So *neither* $\alpha_1 = \phi$ *nor* $\alpha_1 = 1/\phi$ holds in CKT's setup in general.
The two estimators target genuinely different scalars.

### 4.3 What the codebase's "phi^VV" actually returns

`run_vv_vanilla` (line 4128) returns `e(phi) = _b[alpha1:_cons]`.
The moment expression at line 3793 is `epsilon = a - alpha1 * return`, where `return = apb - a`, the residual from regressing $a$ on $b$ in VV's convention.
So the value in `e(phi)` is exactly VV's $\alpha_1$.
The variable name `phi` is the misleading bit --- it suggests CKT's $\phi$.
A coauthor reading `e(phi)` from `run_vv_vanilla` would naturally compare it to `e(phi)` from `run_grc` or `run_grc_robust_vv`, and conclude (wrongly) that they target the same scalar.

### 4.4 Practical implication

The "vanilla VV" V1 sweep produces an $\hat\alpha_1$ for each (country, covariate column).
To compare with CKT's $\hat\phi^{\text{robust\_vv}}$ from the trajectory-pooled GRC, we need to either:

- *Report both* and remember they target different scalars (with the deterministic-LCA reciprocal as a heuristic check).
- *Re-derive* a population-level mapping from $\alpha_1$ to $\phi$ that handles both the regression direction and the two-skill structure.
  This needs a moment-by-moment derivation that I have not done; the equivalence-proof memo §10 simulation was supposed to test the reciprocal identity numerically under DGPs that satisfy A1--A3, but the empirical comparison on real CKT data does not satisfy A1--A3 by construction.

This is a pre-V1 question that needs answering.
The slide deck's current claim "$\alpha_1 = \phi$" makes the question disappear without resolving it.

## 5. Slide-deck issues

### 5.1 Existing slide 9: "Verdier identifies $\alpha_1$ at the worker level"

Three problems.

1. **Step 1's equation does not show the FE recovery.**
   The equation $y_{it} = \mu_{\mathrm{hhid}_i, D_{it}} + x_{it}'\gamma + e_{it}$ shows an OLS regression but not the within-(individual, regime) means that come out the other side.
   The reader cannot deduce $\hat a_i = \hat\mu_{i, 0}$ and $\hat b_i = \hat\mu_{i,1} - \hat\mu_{i,0}$ from the equation as written.
   For movers both $\hat\mu_{i,0}$ and $\hat\mu_{i,1}$ exist; for untreated stayers only $\hat\mu_{i,0}$; for treated stayers only $\hat\mu_{i,1}$.
   This mechanic is the load-bearing part of Step 1 and should be explicit on the slide.

2. **Step 2 is shown as an OLS regression but is actually IV.**
   The slide writes $a_i = \alpha_0 + \alpha_1 b_i + \varepsilon_i$ as if it were an OLS equation.
   $\hat b_i$ recovered from Step 1 is noisy, so OLS would be biased by measurement error in the regressor.
   VV's procedure instruments $\hat b_i$ with the trajectory pattern $\{x_{i1}, \ldots, x_{iT}\}$.
   The IV moment is what makes the procedure work; the slide should write it out.

3. **The alert block says "village-demeaned period-treatment indicators" but Step 2's equation has no cluster.**
   Cluster $v_i$ enters Step 2 only through fixed effects in the IV regression (or, FWL-equivalently, by demeaning the instruments).
   The current alert block asserts cluster demeaning without the rest of the slide showing where $v_i$ lives.
   Either Step 2 is the simple version (no cluster) and the cluster comes in a separate "robust extension" slide, or Step 2 is the robust version and the slide writes the moment with the cluster FE explicit.

The clean fix is to split slide 9 into two slides:

- **Slide 9a (Step 1).** Show the FE recovery: $\hat a_i = \hat\mu_{i,0}$, $\hat b_i = \hat\mu_{i,1} - \hat\mu_{i,0}$, with the within-(pid, regime) mean construction written out and a note that it works only for movers (both regimes observed).
- **Slide 9b (Step 2).** Show the IV moment $E[(x_{it} - \bar x_{v_i, t})\, (\hat a_i - \alpha_0 - \alpha_1 \hat b_i)] = 0$, introduce the cluster index $v_i$, and note the FWL equivalence to VV's published "FE-in-regression" formulation.

### 5.2 Existing slide 12: "Asymptotically the two estimators target the same $\phi$"

The slide writes:

> $\mu_d = \alpha_0 + \alpha_1 \Delta_d$
>
> which is exactly CKT's trajectory-level LCA $\Delta_d = \beta + \phi(\mu_d - \mu_{d_0})$ with $\alpha_1 = \phi$.

The two equations regress in *opposite directions* (line 1: $\mu_d$ on $\Delta_d$, slope $\alpha_1$; line 2: $\Delta_d$ on $\mu_d$, slope $\phi$).
These give the same slope only under perfect linearity (no LCA error).
With noise, $\alpha_1 = 1/\phi$ in the special case where $\theta_i = a_i$, and neither $\alpha_1 = \phi$ nor $\alpha_1 = 1/\phi$ in general.

The economic content (LCA captures heterogeneity) is right; the algebra "$\alpha_1 = \phi$" is wrong as a general claim.

The fix: replace "$\alpha_1 = \phi$" with the correct reciprocal-under-deterministic-LCA identity, and explicitly mark it as a special-case heuristic, not an asymptotic equivalence.
Better: drop slide 12 and let a new "parameter mapping" appendix carry the convention note.

### 5.3 The diagnostics section I added (current slides 16--19)

Eight problems.

1. **The conflation $\alpha_1 = \phi$ propagated into my new content.**
   I wrote $\hat\alpha_1^{VV}$ alongside $\hat\phi^{\text{robust\_vv}}$ as if they targeted the same parameter.
   They do not.
2. **"Cluster index: $v_i = $ first-wave province" appears without an equation showing $v_i$.**
   Same issue as slide 9: $v_i$ should appear in the moment condition before being named in a bullet.
3. **"Instruments: cluster-demeaned period-treatment indicators" appears without an equation showing the instruments.**
   Same issue.
4. **The "slide 9" cross-reference is brittle.**
   After insertion, slide numbers shifted, and I did not verify the reference.
5. **"VV (Kenya): $V = 6$" is wrong.**
   VV §3.3 footnote 29 (p.18) says "twelve farmers per village on average, 1,130 farmers total", so $V \approx 94$.
   Where the "$V = 6$" claim in our project memory comes from is unclear; possibly a sub-experiment in an appendix table.
   I have not verified.
6. **"Many CKT clusters hold only a handful of workers" was an unverified empirical claim** that I should not have made on a slide without checking the data.
   You said the current numbers are not yet trustworthy, so this point is left as a flag rather than re-litigated here.
7. **"Covariate column" is referenced without being introduced.**
   The four covariate sets ($\mathrm{covs\_trend}$, $\mathrm{covs\_1}$, $\mathrm{covs\_2}$, $\mathrm{covs\_all}$) that the V1 sweep cycles through need to be defined before the diagnostics slide uses the term.
8. **"Location residualization" is referenced without being introduced.**
   Refers to the optional `vfirst` $\times$ period interactions added to the first-stage projection.
   Same issue as covariate column.

The diagnostics section needs to be reverted and rewritten from scratch, after slide 9 is fixed.

## 6. Where the procedure breaks down conceptually

VV's identification strategy needs:

a. Within-cluster movers (workers who switch treatment status within the same $v_i$).
b. Within-cluster variation in the trajectory pattern across movers.
c. Enough movers per cluster that the FE-IV regression is well-conditioned.

Conceptually, the procedure is fragile when:

- A cluster has *zero* movers. Then the cluster-FE-residualized period-treatment indicators are zero throughout that cluster, contributing nothing to identification.
- A cluster has *one or two* movers. Then within-cluster demeaning eats almost all the variation.
- The trajectory pattern is collinear *within* a cluster. With $T$ periods and $k$ workers in a cluster, the rank of the within-cluster trajectory design is at most $\min(T, k-1)$ after partialling worker FEs, so clusters with $k \le T$ contribute fewer free moments than the procedure assumes.

This is a *general* property of cluster-FE IV procedures with worker-level fixed effects.
It bites whether $V$ is 6 or 100; what matters is the within-cluster mover count and trajectory variation.

## 7. What I want from you before I touch the deck again

a. Sign-off on §1--4 (the procedure description and the parameter-mapping diagnosis), or pushback where the diagnosis is wrong.
b. Decide whether to revert the diagnostics section now (recommend yes) and rewrite from scratch using §1--4 as the source of truth.
c. Decide whether to add a "parameter mapping VV $\leftrightarrow$ CKT" appendix to the deck.
   Without it, a coauthor or referee reading the existing deck has to re-derive the convention issue from the literature; with it, the deck is internally auditable.

I have not edited the slide deck since you pushed back.
The 24-page version with the (broken) diagnostics section is the current state of [verdier-modification.tex](file:///C:/git/ckt/.claude/worktrees/worktree-vanilla-vv/paper/slides/verdier-modification.tex).
