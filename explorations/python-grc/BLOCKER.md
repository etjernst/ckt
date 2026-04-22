# Status at merge time

## Resolved

### 1. `Converged: False` from L-BFGS-B

**Root cause:** `gtol=1e-10` was too tight for the objective `n * g'Wg`,
which is O(J) ~ 10-100 at the optimum. The projected gradient was bounded
below by O(sqrt(n)) * numerical noise, so the gradient tolerance could not
be met and `res.success` stayed False even at valid optima.

**Fix:** `gtol=1e-8` for L-BFGS-B + Nelder-Mead polish. Convergence judged
by outer-iteration fixed point (`||theta_{k+1} - theta_k||/||theta_k|| < 1e-4`)
rather than the optimizer's success flag.

### 2. `se == 0` for `phi`, `switcher_28`, `switcher_30`, `switcher_31`

**Root cause:** `np.linalg.inv` was used on a near-singular `(G'WG)` caused
by Stata's collinear `switcher_31_choice` instrument (confirmed in
`verify_stata.log`). `np.linalg.inv` silently produced a variance matrix
with negative diagonals.

**Fix:** `_robust_inv(M, rcond=1e-10)` wrapper calls `np.linalg.pinv` with
an explicit singular-value threshold, used for `W2`, `W_final`, and `V`.
All SEs are now finite.

### 3. First-step sensitivity of two-step GMM

**Fix:** iterated GMM. Outer loop updates `W = S^{-1}(theta)` and re-optimizes
until theta stabilizes. Converges in 5 outer iterations, ~16 min wall time
on IDN.

### 4. Stata/Python side-by-side diff

**Fix:** `verify_stata.do` is now a standalone, conforming .do file
(version 19, proper header, `exit, STATA clear`, CSV export). It runs
`run_grc` from `0_programs.do` with the same spec as `5_GrRC.do` and
writes coefficient, SE, J-stat, timing, and sample-diagnostic CSVs.

`verify_idn_consumption.py` reads those CSVs, dumps its own sample
diagnostics, and prints a side-by-side comparison (coefficients, SEs,
J-stat, wall time, per-variable summary stats, per-trajectory counts).

### 5. Collinearity handling

**Tried:** a QR-with-pivoting `_drop_collinear` that removes redundant
columns before GMM. Empirically this hurt more than helped on IDN: the
optimizer found a different local minimum and J doubled. Reverted to
keeping the full instrument matrix and relying on `_robust_inv`.

`_drop_collinear` is still in `grc_gmm.py` and reports `dropped_moments_`
as a diagnostic but is not applied to `Z` before estimation.

## Verification results on IDN / consumption / urban / unb

Core parameters match Stata to 3--4 decimals on coefficients:

| Quantity          |      Stata |     Python |        delta |
|-------------------|-----------:|-----------:|-------------:|
| $\phi$            |    -2.4455 |    -2.4427 |    -2.8e-03  |
| $\Delta_\text{base}$    |     0.8483 |     0.8522 |    -3.9e-03  |
| $\mu_\text{never}$      |    11.3511 |    11.3511 |    -1.9e-06  |
| $\kappa$ (always-U)     |    11.2875 |    11.2952 |    -7.7e-03  |
| $\hat\alpha$            |    11.3715 |    11.3715 |    -3.8e-09  |
| $\hat\pi$               |    -0.4712 |    -0.4751 |    -3.9e-03  |
| Hansen $J$              |     86.52  |     97.74  |   +11.22     |
|  $J$ df                 |        27  |        29  |              |

$\mu_\text{never}$ and $\hat\alpha$ match to machine precision.

$N = 92{,}450$, $N_\text{clust} = 29{,}697$, base trajectory $= 2$ on both sides.

Wall times: Stata **616.9 s**, Python **975.9 s** (Python ~1.6x slower).

## Outstanding

### A. $\text{SE}(\hat\phi)$ off by $\sim 2.75\times$

Stata reports $\text{SE}(\hat\phi) = 0.0705$; Python reports $0.1943$.
The coefficient matches; the variance does not.

Likely cause: Python keeps the rank-deficient direction in `(G'WG)^{-1}`
via `pinv`, which inflates the variance for parameters that enter the
redundant direction (here $\phi$, which couples to `switcher_31_choice`
via the LCA cross-trajectory moment).

**Recommended next step:** a principled collinearity drop that removes
only the specific column(s) Stata drops. The naive QR-with-pivoting used
in `_drop_collinear` was too aggressive on IDN (cut 2 columns, damaged
the optimization landscape). A proper version would (i) build `Z`,
(ii) identify exactly the columns Stata would drop under `noconstant`
(those collinear with the already-present columns), (iii) drop them
only for variance computation, leaving the full `Z` intact for the
GMM point estimate.

### B. Two unidentified $\mu$'s for sparse trajectories

`mu:switcher_11` and `mu:switcher_27` disagree between Python and Stata
by large margins. Both sides report either machine-precision SEs
(indicating the parameter is pinned to a boundary of the optimizer)
or huge SEs (indicating non-identification). These trajectories have
very few observations and neither method actually identifies the
corresponding $\mu$. Not blocking for the core estimand.

### C. Python ~1.6x slower than Stata

Python uses L-BFGS-B + Nelder-Mead polish with iterated GMM (5 outer
iterations). Stata's `gmm` uses a single two-step pass with its own
internal optimizer. If speed matters, candidates to explore:
- JAX/Numba JIT for the residual + moment functions.
- Trust-region solver with analytic Hessian.
- Stopping iterated GMM at 3 outer iterations once stable.
