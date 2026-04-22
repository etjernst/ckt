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

## Outstanding: Stata-vs-Python verification not yet completed

**Status:** the Stata reference run in `verify_idn_consumption.py` exceeds
available wall time on this machine (the previous agent saw it still running
at 10+ minutes; the blocker-fix pass could not afford the time to let it
complete). Python runs end-to-end in ~23 minutes on the full IDN unbalanced
sample (91,862 observations, 31 trajectories).

**Current Python estimates (post-fix, M4 spec: IDN consumption / urban / unb,
no covariates):**

| Quantity          |   Estimate | Std err |
|-------------------|-----------:|--------:|
| $\hat\phi$        |     -2.201 |   0.159 |
| $\hat\Delta_\text{base}$ |     0.853 |   0.047 |
| $\hat\Delta_\text{never}$ |     0.309 |   0.055 |
| Hansen J (df=29)  |    272.094 |         |

These numbers converged with the relative-gradient criterion and all SEs are
finite. Signs are consistent with the paper's pro-poor finding ($\phi<0$).

**Point estimates are sensitive to the first-step optimum.** The two-step
efficient GMM is asymptotically efficient regardless of the first-step
estimator, but in finite sample the optimal weighting matrix $\hat W = S^{-1}$
is estimated from the first-step $\hat\theta^{(1)}$ and different first steps
produce different $\hat W$ and therefore different second-step estimates. An
iterated-GMM step (repeat until $\hat\theta$ stabilizes) would remove this
dependence and is a natural follow-on.

**How to resume verification:**

```bash
# Give Stata a longer budget; the subprocess.run timeout in
# verify_idn_consumption.py is already 900s but Stata may need more.
cd explorations/python-grc
python verify_idn_consumption.py   # full run
SKIP_STATA=1 python verify_idn_consumption.py   # Python-only, after Stata CSV exists
```

## Recommended next steps

1. Complete Stata reference run (may need 15-30 min wall time).
2. Implement iterated GMM (two-step → three-step → ... until $\hat\theta$
   stabilizes to $1e-6$). This removes the first-step sensitivity.
3. Compare Python vs Stata on coefficients, SEs, J-stat. Target: match to
   $1e-4$ on coefs, $1e-3$ on SEs, $1e-2$ on J-stat.
4. If iterated GMM doesn't resolve discrepancy, do a numerical-vs-analytic
   gradient check to rule out bugs in `_gradient_of_g`.
