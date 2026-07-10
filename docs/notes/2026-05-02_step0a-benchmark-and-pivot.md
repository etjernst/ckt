# Step 0a: backend benchmark and proposed pivot

Date: 2026-05-02 (continuation of 2026-05-01 Step 0).
Plan: [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md), Step 0a.
Working dir: [`explorations/python-grc/stata/step0a_fe_absorption/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/).

## What happened

The original Step 0a plan called for an FE-absorption A/B test on TZA covs_trend ($J = 11{,}012$ clusters, $N = 29{,}864$).
The first `reg_sandwich` Spec A call (unabsorbed `alpha_d_*` dummies) sat in the BRL adjustment loop for 17 minutes with no progress past the collinearity note before I killed it.

Backend benchmark on the same TZA covs_trend design at increasing $J$:

| $J$ (target) | $N$ | Stata `reg_sandwich` wall | R `clubSandwich` wall |
|---:|---:|---:|---:|
| 100 | 272 / 275 | 0.96 s (test errored on collinear betas) | error: V not positive definite |
| 500 | 1358 / 1356 | 3.79 s (test errored) | error: V not positive definite |
| 1000 | 2747 / 2711 | 90.06 s | 7.58 s |
| 2000 | 5432 / 5429 | 366.06 s (6.1 min) | 30.20 s |
| 5000 | -- / 13560 | not run | 217.14 s (3.6 min) |
| 11012 | -- / 29864 | not run (extrapolated 3 h) | still running at 12 GB after 40+ min wall |

Both backends scale roughly $O(J^2)$ between $J = 1000$ and $J = 5000$, and the small-$J$ errors come from pid resampling that drops some kept switchers (so the joint contrast contains coefficients no longer in the model).
R is consistently ~12 times faster than Stata at the same $J$; both grow steeply.
R's vcovCR also allocates an internal $N \times N$ influence matrix ($\sim 7$ GB at $N = 29{,}864$), which explains the memory profile.

The Stata Spec A run at $J = 11{,}012$ was extrapolated to $\sim 3$ hours per fit from the $O(J^2)$ Stata curve; the R run at $J = 11{,}012$ is still active at 40+ minutes and 12 GB of memory.
Either backend, fit naively at every grid $\phi$ ($\sim 30$ grid points per inversion $\times 4$ inversions $\times 5$ specs $\times 3$ countries $= 1{,}800$ fits), is unworkable.

Stata raw output: [`benchmark_reg_sandwich_out.txt`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_reg_sandwich_out.txt).
R output (in progress): [`benchmark_clubsandwich_r_out.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_clubsandwich_r_out.csv).

## What this changes about the plan

The plan assumed two things that the benchmark falsifies.

First, that `reg_sandwich` would be fast enough to fit at LCA scale.
At TZA covs_trend ($J = 11{,}012$), one fit looks like 3 hours via Stata or ~30 minutes via R.
At IDN covs_all the cluster count is similar but $K$ is larger; expect comparable or worse.

Second, that `test_sandwich` could be called at every grid $\phi$ on the same fit.
`test_sandwich` is varlist-only (joint zero on a list of coefficient names).
The LCA contrast at grid $\phi$ is $r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0$, which is not a varlist-zero on the original design.
The plan implicitly required either reparametrizing per grid (refit $\Rightarrow$ 30 fits per cell) or a constraint-matrix interface that `test_sandwich` does not have.

Both problems argue for the same pivot: switch the production backend to R `clubSandwich` and exploit `Wald_test`'s native support for arbitrary linear constraints, plus the fact that vcovCR is computed once per fit and cached.

## Proposed path forward

The intended computational pattern is "fit once, test many" with R as the engine.

For each (country, spec) cell:

1. Fit `lm(...)` on the auxiliary OLS design (Python builds the design matrix; R reads it; `lm` itself is fast, on the order of a second).
2. Compute `vcovCR(m, cluster=pid, type="CR2")` once.
This is the load-bearing step at $\sim 30$ minutes wall and ~12 GB memory at TZA scale.
Cache the resulting `V_CR2` plus the per-cluster influence matrices.
3. Loop over the $\phi$-grid.
At each $\phi$, build the constraint matrix
$$C_\phi = \big[ e_{\beta_s} - e_{\beta_{base}} - \phi (e_{\alpha_s} - e_{\alpha_{base}}) : s \in S_R \setminus \{base\} \big]$$
of shape $(J_R, K)$, then call `Wald_test(m, constraints = C_\phi, vcov = V_CR2, test = "HTZ")`.
`Wald_test` runs the AHZ Wald with Satterthwaite df from the cached influence matrices; per-call cost should be small relative to vcovCR.
4. Collect per-grid AHZ p-values, build the F-adjusted CI as the union of $\{\phi : p \ge \alpha\}$, apply the contiguous-acceptance fallback rule (locked decision 4) when the sign-change count exceeds one.

Open questions before this pivots into a new plan rev:

- Is `Wald_test` actually fast given a cached `vcov` (or does it recompute the influence matrices each call)?
A quick benchmark: fit one TZA covs_trend cell, time 30 successive `Wald_test` calls at different constraint matrices.
If each call is much smaller than the vcovCR cost, the "fit once, test many" pattern is the right one.
Estimated time to verify: 1 hour.
- Memory at IDN unbalanced scale.
IDN unbalanced has $J \approx 30{,}000$ clusters and $N \approx 90{,}000$ rows.
The internal $N \times N$ influence matrix at IDN scale is $\sim 65$ GB.
That is unworkable on a 16 GB or 32 GB workstation.
Mitigations: (a) some clubSandwich code paths use sparse representations of the influence matrix; verify whether vcovCR triggers them at our cluster pattern; (b) absorb FE first via `lfe::felm` or `fixest::feols` and reduce $K$ before passing to `vcovCR`; (c) compute the BRL adjustment ourselves, cluster by cluster, without forming the full $N \times N$ matrix.
- The Step 0 cross-check used Stata SSC `reg_sandwich` 0.0 (2017) against R `clubSandwich` 0.6.2 (2026 CRAN) and they agreed to $1.8 \cdot 10^{-8}$.
Switching the production backend from Stata to R does not require redoing the Step 0 verification on the toy panel.
- The corrigendum status is unchanged: the TODO entry stays open ([`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md)).
R `clubSandwich` 0.6.2 is the more likely place for the 2023 fix to live.

## What I am stopping on

Step 0a as written cannot complete at TZA scale within the plan's runtime budget.
The pivot to "R as backend, fit once per cell, Wald_test per grid $\phi$" is a substantive change that affects Steps 1, 2, 3, and 5 of the plan.
This is the kind of change that the user reviews before I write more code.
The R J=11012 benchmark is still running in the background; if it finishes I will append the number to this memo, but it does not change the recommendation.

## Hand-off

Open thread.
Read this memo first if you resume.
The benchmark artifacts at [`explorations/python-grc/stata/step0a_fe_absorption/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/) are reproducible from the design `.dta` plus the two benchmark scripts.
Locked decision 8 (FE-absorption choice) is not yet locked because Spec A could not complete; that decision is now bundled into the broader backend-pivot question.

Two concrete next actions, in priority order:

1. Quick benchmark: fit one TZA covs_trend cell in R, time 30 `Wald_test` calls at different LCA-style constraints; confirm the "fit once, test many" pattern is fast.
~1 hour wall.
2. Memory check at IDN unbalanced scale: dummy a $J = 30{,}000$ design, see whether `vcovCR(..., type = "CR2")` runs without OOM; if not, plan an absorbed-FE path through `fixest::feols_internal` or a from-scratch BRL implementation.
~2 hours wall.

If both check out, write a plan rev 4 that flips the backend to R and folds in the rest of the existing structure.
If the memory check fails, the path forward is either WCB inversion (Step 3.5 promoted to primary) or a from-scratch BRL implementation (the rev 1 path the user originally rejected, possibly less risky now that R `clubSandwich` 0.6.2 exists as an anchor).
