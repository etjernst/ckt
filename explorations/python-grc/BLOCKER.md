# Blocker status (post-fix pass)

## Previously blocked (now resolved)

### 1. `Converged: False` from L-BFGS-B

**Root cause:** `gtol=1e-10` was too tight for the objective `n * g'Wg`, which
is O(J) ~ 10-100 at the optimum. The projected gradient was bounded below by
O(sqrt(n)) times numerical noise, so the gradient tolerance could not be met
and `res.success` stayed False even at valid optima.

**Fix:** `gtol=1e-8` for L-BFGS-B + Nelder-Mead polish + alternation. `converged_`
is now judged by the relative gradient norm at the final point, not by the
optimizer's success flag. Verification run (2026-04-22) returned
`Converged: True` with `||grad||/|obj| < 1e-4`.

### 2. `se == 0` for `phi`, `switcher_28`, `switcher_30`, `switcher_31`

**Root cause:** `np.linalg.inv` was used to invert both `S` (for the weighting
matrix) and `GtWG` (for the variance). Stata's `gmm` explicitly drops
`switcher_31_choice` with a collinearity note (confirmed in
`verify_idn_consumption_stata.log`). Python was keeping all columns, and
`np.linalg.inv` silently produced a variance matrix with negative diagonals.

**Fix:** `_robust_inv(M, rcond=1e-10)` wrapper calls `np.linalg.pinv` with an
explicit singular-value threshold, used consistently for `W2`, `W_final`, and
`V`. Verification run returned all finite SEs.

### 3. First-step sensitivity of two-step GMM (resolved via iterated GMM)

**Observed symptom:** three separate runs with slightly different inner-loop
tolerances produced $\hat\phi\in\{-0.95,-1.45,-2.20\}$. The two-step efficient
GMM is asymptotically efficient for any consistent first step, but in finite
sample $\hat W = \hat S^{-1}(\hat\theta^{(1)})$ depends on the first-step
estimate, and different $\hat W$ yield different second-step $\hat\theta^{(2)}$.

**Fix:** iterated GMM. Repeat the weighting-matrix update and re-optimization
until $\|\hat\theta^{(k+1)} - \hat\theta^{(k)}\|/\|\hat\theta^{(k)}\| < 10^{-4}$.
Implemented in `RestrictedGRC.fit()` via an outer loop over at most 8
iterations with a "light" inner optimizer after the first iteration.
`self._iter_history_` exposes the per-outer-iteration objective and step size.

Verification run (2026-04-22): the fixed point is reached in 5 outer
iterations, total fit time ~12 minutes.

## Outstanding: Stata-vs-Python verification not yet completed

**Status:** Stata's GMM on the 92k-observation IDN sample runs for tens of
minutes (slow enough that the subprocess timeout in the Python wrapper is
not the right cadence for iteration). The standalone `verify_stata.do` can
now be invoked manually in parallel; once the Stata CSVs exist, the Python
side compares against them via `SKIP_STATA=1 python verify_idn_consumption.py`.

**Current Python estimates (iterated GMM, IDN consumption / urban / unb,
no covariates):**

| Quantity                  |   Estimate | Std err |
|---------------------------|-----------:|--------:|
| $\hat\phi$                |     -2.454 |   0.196 |
| $\hat\Delta_\text{base}$  |      0.853 |   0.048 |
| $\hat\Delta_\text{never}$ |      0.315 |   0.054 |
| Hansen J (df = 29)        |     97.829 |         |

Signs and magnitudes are consistent with the paper's pro-poor finding
($\phi<0$). Stata picked the same base trajectory (2) that Python chose.

## Recommended next steps

1. Run `verify_stata.do` to completion (may need ~30 min). Then run
   `SKIP_STATA=1 python verify_idn_consumption.py` for the diff.
2. If Python vs Stata match within target precision, lift the port out of
   `explorations/` into `scripts/python/` following the graduate checklist.
3. If they do not match, do a numerical-vs-analytic gradient check on
   `_gradient_of_g` first (it is the largest single source of unchecked
   math in the port).
4. Stretch: extend the port to the income specification (mindful of the
   `define_switcherpars` base-hardcode bug flagged in `CLAUDE.md`).
