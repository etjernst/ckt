# SE(phi) diagnostic: findings

**Date:** 2026-04-23
**Status:** Resolved. The SE(phi) discrepancy is a weighting-matrix convention
difference, not a bug in Python's variance formula.

## TL;DR

Python's sandwich formula exactly reproduces **every** Stata SE --- including
phi --- when we plug Stata's saved `e(W)` into Python's computation at
Stata's theta. Ratio = 1.0000 across all 36 parameters.

| Parameter | Stata SE | Python SE (W = Stata's e(W)) | Ratio |
|---|---:|---:|---:|
| mu:never | 0.0158 | 0.0158 | 1.0000 |
| mu:switcher_2 | 0.0233 | 0.0233 | 1.0000 |
| ... | ... | ... | 1.0000 |
| Delta_base | 0.0473 | 0.0473 | 1.0000 |
| **phi** | **0.0705** | **0.0705** | **1.0000** |
| kappa | 0.0291 | 0.0291 | 1.0000 |

So **Python's variance formula is correct**. The 2.8x SE(phi) inflation we
saw earlier comes from Python and Stata landing on different weighting
matrices W at convergence, and phi is the one parameter whose variance is
extremely sensitive to which W is used (see "Why phi specifically" below).

## What Stata actually does (confirmed via `dump_stata_vcov.do`)

Stata's `gmm ..., vce(cluster pid)` with no explicit weighting options:

1. Step 1: `winitial(unadjusted)` = `W_1 = (Z'Z/n)^{-1}`. Minimize
   `n * g'W_1 g` --> theta_1.
2. Step 2: `wmatrix(cluster pid)` = `W_2 = S_cluster^{-1}(theta_1)`, held
   fixed during step 2. Minimize `n * g'W_2 g` --> theta_2 (reported).
3. VCE (sandwich, `vce(cluster pid)`):
   `V = (G_2' W_2 G_2)^{-1} G_2' W_2 S(theta_2) W_2 G_2 (G_2' W_2 G_2)^{-1} / n`.

Stata's initial-value convention (in `initial_values`):
- `mu_never` = **hardcoded 0**. Not from OLS.
- `mu_switcher_s` = OLS coefficient on `switcher_s` indicator.
- `kappa` = OLS coefficient on `always` indicator.
- `Delta_base` = not in initial; Stata's `gmm` defaults it to 0.
- `phi` = `-1` (embedded in the equation via `{phi=-1}`).

## What Python does (current `RestrictedGRC.fit`)

1. W_0 = I. Optimize --> theta_1.
2. Iterated GMM: update `W = S^{-1}(theta_k)`, re-optimize, until
   `||theta_{k+1} - theta_k|| < 1e-4`. Converges in ~5-8 outer iterations.
3. Final W = S^{-1}(theta_hat). VCE = `(G'WG)^{-1}/n`.

Python's initial:
- `mu_never` = OLS coefficient on `never` indicator (~11.35).
- everything else matches Stata.

## Why this matters

Stata's W_2 is computed at theta_1, which depends on Step 1's optimization
path. In this dataset, Stata's theta_1 leads to an S matrix whose inverse
loads heavily on the switcher-choice instruments (unbalanced_choice,
switcher_*_choice). Python's iterated W does not.

Frobenius comparison (at theta_stata):

    ||W_stata - S^{-1}(theta_stata)|| / ||S^{-1}(theta_stata)|| = 0.283

So the two W matrices differ by ~28% in Frobenius norm. Most diagonal
entries match within 2x, but the switcher_*_choice block differs up to
3.7x. Those are the moments that strongly identify phi.

## Why phi specifically (not other params)

Eigendecomposition of Python's G'WG at theta_py (W = S^{-1}(theta_py)):

| Rank | Eigenvalue | u_phi^2 | Contribution to Var(phi) |
|---:|---:|---:|---:|
| 0 | 3.03e-06 | 3.30e-05 | 1.18e-04 |
| 1 | 2.22e-04 | **0.792** | **3.86e-02** |
| 2 | 1.06e-03 | 0.061 | 6.27e-04 |

**97% of Var(phi) comes from ONE eigendirection** (rank 1, eigenvalue
2.22e-04). phi has 79% loading on that direction; no other parameter
does. So phi's variance is extremely sensitive to how well that direction
is pinned by the moments --- and that pinning is weight-matrix-dependent.

All other parameters load on stronger directions; their SEs are
insensitive to W choice. That's why phi is the only SE that differs.

## Diagnostics run

1. **Analytic vs. finite-difference Jacobian** at theta_py: agree to 2e-11
   across all 36 parameters (machine precision). Python's G is correct.

2. **Efficient vs. sandwich** at theta_py with W = S^{-1}(theta_py):
   identical to 6 decimals (expected; W = S^{-1} makes them collapse).

3. **Evaluated at Stata's theta** instead of Python's: SE(phi) still 0.200.
   Not a "we found a different optimum" issue.

4. **Full 2-step in Python** (W_1 = (Z'Z/n)^{-1}, theta_1, W_2 =
   S^{-1}(theta_1), theta_2): SE(phi) = 0.197. Still doesn't match Stata.
   So it's not iterated-vs-2-step --- it's that the specific theta_1 path
   differs. Likely due to different initial value for `mu_never`.

5. **Stata's exact e(W) plugged into Python's sandwich at theta_stata:**
   SE(phi) = 0.0705. EXACT MATCH. This nails down that Python's formula
   is right and only the W differs.

## Path to exactly matching Stata

Option A (simplest): add a `match_stata=True` mode to `RestrictedGRC.fit`:
- Set `mu_never` initial to 0 instead of OLS.
- Do exactly 2 optimization steps (no iterated GMM).
- Use W_1 = (Z'Z/n)^{-1}, W_2 = S^{-1}(theta_1).
- Report sandwich variance with W = W_2.

Option B: Keep iterated GMM as the default (cleaner asymptotics, less
finite-sample sensitivity), document that SEs will differ from Stata by
O(sqrt(ess)) in directions where weight-matrix choice matters.

Recommendation: Option A for verification; keep iterated GMM as a
reproducibility check. Users who need Stata-identical output get it;
users who want the (arguably more defensible) efficient two-step get
that too.

## Speed profile

Per-call timings (n=92,450, m=64):

| function | time |
|---|---:|
| `_residuals` | 15.1 ms |
| `_moments_individual` | 37.6 ms |
| `_objective` | 48.0 ms |
| `_gradient_of_g` | 102.9 ms |
| `_cluster_S` | 107.2 ms |

Per outer iteration of `fit`:
- **Nelder-Mead polish: 2000 calls x 48ms = 96 s** <-- biggest cost
- L-BFGS-B: 1000 obj + 100 grad = 58 s
- One W update (`_cluster_S`): 0.1 s

Five to eight outer iterations --> 13-21 minutes total. Matches observed
~16 min.

Stata's `gmm` runs a single two-step pass (not iterated) so it runs faster
(616 s ~= 10 min). Python's iterated GMM does more work by design.

### Why Python is slow (not a bug)

GMM is inherently iteration-heavy. With 36 parameters and 64 moments:
- Each objective evaluation requires building `g_it = z_it * eps_it`
  (92k x 64 matrix multiply) and reducing to g_bar. ~40 ms.
- Analytic gradient doubles that (dfit has 36 columns).
- Nelder-Mead with 2000 iterations is gratuitous once L-BFGS-B has found
  the region of the optimum.

### Quick speed wins (no correctness risk)

1. **Skip Nelder-Mead polish after outer iteration 1.** L-BFGS-B alone
   converges well once W stabilizes. Estimated savings: 8-12 minutes.
2. **Replace `np.add.at` with per-column `np.bincount` in `_cluster_S`**:
   107 ms --> 40 ms. Small absolute savings but the function is called
   8+ times per fit.
3. **Use `jax.jit` or `numba`** on the hot path (`_residuals` +
   `_moments_individual`). Probably 3-5x speedup on the hot path, 2x
   overall. Higher implementation cost; only worth it if we scale
   to Monte Carlo.

### Why we NOT just replace Python with Stata for speed

Python's speed ceiling with the iterated + analytic-grad recipe is in
the same ballpark as Stata. Real gains need JIT. Stata's 10 min is not
a speed win --- it's just what this GMM costs.

## Artifacts

- `check_variance.py` --- diagnostic 1 (analytic Jacobian) + diagnostic 2
  (efficient vs. sandwich) + eigenstructure decomposition.
- `check_collinearity.py` --- diagnostic: rank / collinearity tests on Z.
- `check_variance_formulas.py` --- diagnostic: alternate W matrices.
- `reproduce_stata_twostep.py` --- implements Stata's 2-step protocol.
  Runtime ~7 min (vs. ~16 min for iterated GMM). phi matches Stata to
  3 decimals; SE still off because theta_1 differs.
- `dump_stata_vcov.do` --- extracts Stata's e(V), e(W), e(b) to CSV.
- `compare_stata_matrices.py` --- feeds Stata's e(W) to Python's sandwich
  formula. Confirms exact match. **Definitive answer.**
- `profile_hot_paths.py` --- timings for speed investigation.
- `python_out_idn_cons_urb_unb_2step.csv` --- Python 2-step results.
- `stata_vcov.csv`, `stata_W.csv`, `stata_theta_full.csv` --- raw Stata
  matrices.
