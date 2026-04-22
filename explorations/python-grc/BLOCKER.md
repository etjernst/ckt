# Blocker: M4 verification partial

## Status as of commit

- Python estimator (`grc_gmm.py`) runs end-to-end on IDN consumption/urban/unbalanced.
- Point estimates are in the right neighborhood: `phi` approx -0.95,
  `Delta_base` approx 0.38, `Delta_never` approx 0.37. Signs and
  magnitudes match the paper's claim that migration is pro-poor
  (`phi < 0`).
- Stata reference run has not yet completed within the 90-minute time
  budget for this task. GMM with 588 initial missing values and 30
  switcher parameters on 92,450 observations takes longer than
  anticipated (likely 5-10 minutes of wall time). The previous attempt
  killed the Stata subprocess prematurely at a 290s timeout.

## Known issues in the Python estimator

1. `Converged: False` from L-BFGS-B: the optimizer exhausts line-search
   steps near the optimum but still reports sensible point estimates.
   Likely cause is the tight `gtol` with a flat objective surface near
   the optimum. Try a two-stage polish with Nelder-Mead after L-BFGS-B,
   or switch to `scipy.optimize.root` on the first-order conditions
   directly.

2. `se == 0` for `mu:switcher_28`, `switcher_30`, `switcher_31`, `phi`:
   the analytic variance `(G' W G)^{-1}` is near-singular because
   switcher_31 is collinear with the intercept block in the instrument
   matrix (Stata drops `switcher_31_choice` with a collinearity note).
   Python does not currently detect this and project away the
   redundant column. Fix: (a) drop collinear columns of `Z` before
   computing `S` and `W`, or (b) use `np.linalg.pinv(GtWG)` with a
   truncation rule.

3. `xb:unbalanced` coefficient around 11.37 is expected (it's absorbing
   the pooled level for unbalanced observers under the pooled
   proposition), but needs a Stata cross-check.

## Recommended next steps (post-budget)

1. Let Stata complete the reference run (allow 15+ minutes wall time).
2. Drop collinear instrument columns in `_build_instruments` before
   computing the weighting matrix.
3. Add a convergence-polish step (Nelder-Mead with `xatol=1e-10`).
4. Re-run the verification and tune L-BFGS-B parameters until
   coefficients match Stata to 1e-4 and SEs to 1e-3.

## How to resume

```bash
cd explorations/python-grc
# Give Stata a longer budget:
python verify_idn_consumption.py   # subprocess.run timeout is 900s
```

Or run Stata by itself and then `SKIP_STATA=1 python verify_idn_consumption.py`
to iterate on the Python side without re-running Stata.
