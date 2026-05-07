# Stata critic review: unary-null reparameterization memo

Target: [`docs/notes/2026-05-07_unary-null-reparameterization.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md)
Date: 2026-05-07
Mode: Review (exploration fast-track applies; this is a feasibility note, not production code).

The sketch occupies lines 46--59 of the memo.
Issues are grouped by severity.

## CRITICAL

### C1. `areg` does not report absorbed FE coefficients in `e(b)`; the sketch's recovery step is impossible as written

Anchor: sketch line 50 (comment `* Read alpha_hat_d from e(b)["i.trajectory"]...`).
Lens: 3 (data quality, generated-variable construction).
Confidence: HIGH.

`areg` absorbs the group variable by within-group demeaning and never stores the absorbed cell means in `e(b)`.
After `areg lndepvar i.trajectory#1.choice $controls, absorb(trajectory) vce(cluster pid)`, `e(b)` contains only the explicitly included regressors: the interaction dummies `i.trajectory#1.choice` and the controls.
The trajectory-level intercepts $\hat\alpha_d$ are gone.
There is no `e(b)["i.trajectory"]` stripe.

The sketch comment describes computing $\hat\theta_d = \hat\alpha_d - \hat\alpha_{\underline{d}_0}$ from this `e(b)`, but that recovery cannot happen after `areg`.
The implementer would need either (a) `reghdfe` with `predict, d` (which stores the absorbed FE projection) and then a `collapse` to get trajectory-level means, or (b) fit the first stage as a plain `regress` with an explicit `i.trajectory` factor variable (no `absorb()`), in which case `e(b)` does contain all $\hat\alpha_d$ coefficients.
Option (b) is infeasible when the number of trajectories is large enough to hit Stata's matsize or maxvar limits.
The sketch leaves the implementer with no viable path.

### C2. The first-stage specification produces perfect collinearity between `absorb(trajectory)` and `i.trajectory#1.choice`; absorbed FE subsume the treatment variation for always-takers and never-takers, and Stata's column-drop behavior silently alters what $\hat\beta_s$ identifies

Anchor: sketch line 48, `areg lndepvar i.trajectory#1.choice $controls, absorb(trajectory) vce(cluster pid)`.
Lens: 2 (inference).
Confidence: HIGH.

`i.trajectory#1.choice` expands to one dummy per trajectory--treatment cell where choice=1.
For always-takers ($d_T$, where choice=1 in every period), the interaction dummy `trajectory==d_T # choice==1` is identical to the trajectory dummy absorbed by `absorb(trajectory)` (within their group, choice is constant so the within-group demeaned interaction is identically zero).
Stata will drop that column silently.
For never-takers ($d_N$, where choice is always 0), the interaction dummy is zero everywhere and is also dropped.
This means the absorbed FE are not cleanly partial-ed out of the interactions for the groups where it matters; instead the FE absorbs part of the treatment variation for always-takers, and the remaining `i.trajectory#1.choice` columns are not the $\hat\beta_s$ of the intended saturated specification.
The Python first-stage in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) (lines 105--117) avoids this correctly by constructing interaction columns only for switcher trajectories and trajectory dummies separately, with no joint absorption.
The sketch's Stata analog replicates neither that logic nor the paper's GMM first-stage moment structure.

## MAJOR

### M1. The second-stage `areg` uses `absorb(trajectory)`, which would absorb the trajectory-level variation in `z_lca` and bias the $\hat\phi$ estimate

Anchor: sketch line 55--56, `areg lndepvar choice z_lca $controls, absorb(trajectory) vce(cluster pid)`.
Lens: 2 (inference).
Confidence: HIGH.

`z_lca = theta_hat_d * choice` varies at the trajectory level (because $\hat\theta_d$ is constant within trajectory) interacted with choice.
The trajectory FE absorbed by `absorb(trajectory)` subsumes the between-trajectory variation in $\hat\theta_d$.
What remains in `z_lca` after within-trajectory demeaning is only the within-trajectory time-series variation in `choice` scaled by a constant $\hat\theta_d$; for switchers that is useful, but for non-switchers (who never change choice status) `z_lca` demeans to zero.
In practice `absorb(trajectory)` will soak up all the cross-trajectory signal in `z_lca` that the sketch intends $\hat\phi$ to use.
The second stage should either absorb only time FE (as in the paper's GMM) or use `reghdfe` with absorbed FE and the `partial(z_lca)` option, or not absorb trajectory at all and include trajectory dummies explicitly.
Absorbing trajectory here is not equivalent to the memo's econometric model at lines 37--40.

### M2. `boottest` with `areg` works but will compute a finite-sample correction using `1 + e(df_a)` absorbed categories; the implementer must verify `e(df_a)` is correct for the second-stage specification

Anchor: sketch line 59, `boottest {z_lca}, weighttype(rademacher) reps(9999) nograph`.
Lens: 2 (inference).
Confidence: MEDIUM.

`boottest` detects `e(cmd)=="areg"` and sets `NFE = 1 + e(df_a)` (boottest.ado line 263).
If the second-stage `absorb(trajectory)` has many levels but some are collinear with `choice` or `z_lca` (as described in M1), Stata may report a smaller `e(df_a)` than expected, and `boottest`'s degrees-of-freedom adjustment would be wrong.
This is a downstream consequence of M1 rather than an independent bug, but it would produce incorrect CI width and is worth calling out separately.

### M3. `boottest {z_lca}` tests $H_0: \beta_{\text{z_lca}} = 0$ and by default inverts to a CI; the default behavior is correct for the stated purpose, but `level(95)` is absent and the default `reps(999)` note is misleading

Anchor: sketch line 59.
Lens: 2 (inference).
Confidence: MEDIUM.

The unary-null CI inversion is the default for `df=1` constraints as long as `noci` is not specified (boottest.ado line 532--534: `if "`noci'"=="" & ... & df<=1 tempname cimat`).
So the invocation will produce a CI without needing an explicit `level()`.
However: (a) the sketch omits `level(95)` even as documentation, leaving an implementer uncertain whether to rely on `c(level)`; (b) `boottest`'s own note (line 827--828) warns that coverage is best when `level/100 * (reps+1)` is an integer---at 95% and reps=9999, that product is 0.95 * 10000 = 9500, an integer, so this is fine; (c) the CI is inverted via Chandrupatla bisection, not by evaluating all 9999-rep bootstrap distributions on a grid, so the 9999 reps apply to a single null imposed at the bisection midpoints, and the compute cost is dominated by the number of bisection steps times reps, not by a 30-point grid---the "30x saving" claim in the memo is therefore not quite right about where the saving comes from, but the invocation itself is correct.

### M4. `gen z_lca = theta_hat_d * choice` will produce missing values for any observation where `theta_hat_d` is missing, and those observations are silently dropped from the second-stage regression

Anchor: sketch line 54, `gen z_lca = theta_hat_d * choice`.
Lens: 3 (data quality).
Confidence: HIGH.

`theta_hat_d` must be merged back onto the individual-level panel dataset from a trajectory-level result.
If the merge is not exact (e.g., unmatched trajectories, always-takers or never-takers with no corresponding $\hat\alpha_d$ entry, or missing trajectory codes), `theta_hat_d` will be missing for some observations, and `z_lca` will be missing for those rows.
`areg` drops missing observations silently.
The sketch mentions "merge back as theta_hat_d on trajectory" but does not specify the merge command, the merge key, the `_merge` assertion, or any handling of unmatched rows.
This gap is exploitable---a wrong merge could produce a different effective sample than the first stage, invalidating any comparison between the two stages.

## MINOR

### m1. No `set seed` before `boottest`

Anchor: sketch line 59.
Lens: 1 (reproducibility).
Confidence: HIGH.

`boottest` draws Rademacher weights randomly.
Without `set seed` immediately before the call, results are not reproducible across sessions.
The seed is not deferred by `sameseed`; a bare `set seed 12345` (or the value used in the existing bootstrap infrastructure) is required.

### m2. No `version` declaration in the sketch

Anchor: sketch header (no version statement).
Lens: 1 (reproducibility).
Confidence: LOW (sketch is a blueprint, not a runnable do-file).

Production implementation would need `version 17` (or matching the project convention) at the top.

### m3. The `reps(9999)` default produces a note from `boottest` about integer coverage alignment

Anchor: sketch line 59.
Lens: 2 (inference).
Confidence: LOW.

As computed above (0.95 * 10000 = 9500 exactly), reps=9999 is fine at the 95% level.
But if the level were changed to, say, 90%, the product would be 0.90 * 10000 = 9000, also fine.
The sketch is acceptable here; flagged only so an implementer checks alignment if they change `level()`.

## Summary table

| # | Severity | Lens | Confidence | Anchor |
|---|----------|------|------------|--------|
| C1 | CRITICAL | 3 | HIGH | sketch line 50: `e(b)` FE recovery from `areg` impossible |
| C2 | CRITICAL | 2 | HIGH | sketch line 48: absorbed FE collinear with interaction; silent column drop changes estimand |
| M1 | MAJOR | 2 | HIGH | sketch line 55--56: second-stage `absorb(trajectory)` soaks up `z_lca` variation, biases $\hat\phi$ |
| M2 | MAJOR | 2 | MEDIUM | sketch line 59: `boottest` NFE adjustment depends on potentially wrong `e(df_a)` |
| M3 | MAJOR | 2 | MEDIUM | sketch line 59: `level(95)` absent; CI inversion behavior correct but undocumented |
| M4 | MAJOR | 3 | HIGH | sketch line 54: `gen z_lca` silently propagates missing if merge of `theta_hat_d` is incomplete |
| m1 | MINOR | 1 | HIGH | sketch line 59: no `set seed` before `boottest` |
| m2 | MINOR | 1 | LOW | no `version` declaration |
| m3 | MINOR | 2 | LOW | `reps(9999)` integer-alignment note |

## Aggregate

C1 and C2 are CRITICAL and block the sketch from serving as a valid blueprint for production implementation.
The two-stage `areg` pattern as written does not recover $\hat\alpha_d$ (so $\hat\theta_d$ cannot be constructed), and the absorption structure in both stages produces a different estimand than the memo's model.
Numeric score around **28/100** (Reproducibility 15/25, Inference 5/30, Data Quality 5/20, Output 8/10, Code Quality 8/15), but the score is secondary; the two CRITICALs block use of this sketch as-is regardless.
