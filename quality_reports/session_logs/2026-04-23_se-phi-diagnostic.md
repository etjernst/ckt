# Session log: 2026-04-23 afternoon --- SE(phi) diagnostic on Python GRC port

**Mode:** Review (diagnostic) in `explorations/python-grc/`. Light workflow
per `exploration-fast-track.md`.

**Context:** Coefficients match Stata to 3--4 decimals for IDN/cons/urban/unb
(documented in `BLOCKER.md`), but Python reports SE(phi) = 0.199 vs Stata's
0.0705 --- 2.8x inflation. Task was to work through the four diagnostics
queued in `quality_reports/session_logs/2026-04-22_gmm-convergence-audit.md:637`
and also profile Python's ~16 min runtime.

## What we found

### Variance formula is correct

Plugging Stata's saved e(W) (extracted via `dump_stata_vcov.do`) into Python's
sandwich formula at Stata's theta **reproduces every Stata SE to 4+ decimals,
ratio = 1.0000** across all 36 parameters. So the variance formula, the
Jacobian, and the cluster-S computation are all right.

This is a "where does the gap live" test, not a usable fix. To match Stata
standalone, Python must arrive at Stata's W matrix on its own.

### The gap lives entirely in the weighting matrix

All four diagnostics converged on the same answer:

1. **Analytic Jacobian** vs finite-difference at theta_py: max diff 2e-11,
   machine precision. Jacobian is correct.
2. **Efficient vs sandwich** at theta_py with W = S^{-1}(theta_py):
   identical to 6 decimals (expected; W = S^{-1} makes them collapse).
3. **Evaluated at Stata's theta** with Python's W: SE(phi) still 0.200. Not
   a "different optimum" issue.
4. **At Stata's theta with Stata's W** (the formula test): SE(phi) = 0.0705,
   exact match. **Proves Python's formula is correct and all the gap is in W.**

### Why phi specifically

Eigendecomposition of G'WG at theta_py:

| Rank | Eigenvalue | u_phi^2 | Contribution to Var(phi) |
|---:|---:|---:|---:|
| 0 | 3.03e-06 | 3.30e-05 | 1.18e-04 |
| 1 | 2.22e-04 | **0.792** | **3.86e-02** |
| 2 | 1.06e-03 | 0.061 | 6.27e-04 |

97% of Var(phi) comes from one weak eigendirection; phi has 79% loading on
it. No other parameter loads on weak directions, which is why **only phi's
SE is W-sensitive**. This is a genuine feature of the model, not a bug.

### Where the W difference comes from

W_2 = S^{-1}(theta_1). If step-1 theta_1 differs between Stata and Python,
W_2 differs, and phi's hypersensitivity blows the SE up.

Followed a 3-step narrowing:

1. **Python iterated GMM W vs Stata's e(W):** 28.3% Frobenius difference.
2. **Python 2-step with Stata's initial values (mu_never = 0 hardcoded)
   vs Stata's e(W):** 3.2% Frobenius difference. Much closer --- but phi's
   sensitivity still produces SE = 0.197 (vs 0.0705).
3. **Stata theta_1 directly, via `dump_stata_step1.do`**:

   | | Stata theta_1 | Python theta_1 |
   |---|---:|---:|
   | phi | **-2.6875** | **-2.7253** |
   | Q(b) = g'W_1 g | 0.00195 | 0.00133 |

   **Python's L-BFGS-B finds a LOWER step-1 minimum than Stata's `gmm`
   optimizer does.** Same problem, same data, same initial values ---
   different stopping points. The step-1 problem may have multiple local
   minima, or Stata's `gmm` convergence tolerance is looser than L-BFGS-B's
   `gtol=1e-8`.

### Speed profile

Per-call timings (n=92,450, m=64):

| function | time |
|---|---:|
| `_residuals` | 15.1 ms |
| `_moments_individual` | 37.6 ms |
| `_objective` | 48.0 ms |
| `_gradient_of_g` | 102.9 ms |
| `_cluster_S` | 107.2 ms |

Per outer iteration of `fit`:
- **Nelder-Mead polish: 2000 calls x 48 ms = 96 s** (biggest single cost)
- L-BFGS-B: 1000 obj + 100 grad = 58 s
- One W update via `_cluster_S`: 0.1 s

Five to eight outer iterations --> 13-21 minutes. Matches observed ~16 min.
Stata takes ~10 min doing a single 2-step pass. The iterated-GMM recipe in
Python is what adds the extra time --- not a Python-vs-Stata speed gap per se.

Three candidate speed wins (none tested yet):
1. Skip Nelder-Mead polish after outer iteration 1 (~8-12 min savings).
   Risk: if L-BFGS-B stalls on a later iteration, we converge to a slightly
   worse theta_k and feed a slightly-off S into the next W. Near the
   optimum, stalls are rare.
2. Replace `np.add.at` with per-column `np.bincount` in `_cluster_S`: 107
   ms --> 40 ms. Small absolute savings but called many times.
3. JIT `_residuals` + `_moments_individual` with numba: probably 3--5x
   speedup on the hot path; 2x overall. Only worth it if we ever scale
   to Monte Carlo.

## What I did NOT finish

`test_stata_theta1.py` is written but not run. It's the next experiment:
use Stata's exact theta_1 -> compute W_2 = S^{-1}(Stata theta_1) in Python ->
do Python's step 2 -> compute sandwich SE. If that gives SE(phi) = 0.0705,
confirms that the ONLY remaining step to make Python Stata-equivalent is
matching step-1's stopping point.

Estimated runtime: ~5 min (just step 2, not step 1).

## Open question: can Python be standalone Stata-equivalent?

If `test_stata_theta1.py` returns SE(phi) = 0.0705, the standalone recipe
is:

1. Match Stata's initial values (mu_never = 0 hardcoded).
2. Stop step-1 optimization at whatever tolerance Stata's `gmm` uses, NOT
   at L-BFGS-B's tighter default.
3. Compute W_2 = S^{-1}(theta_1_stopped_early) and do step 2.

The fragility here is unsettling: the correct SE depends on when we stop
step 1, and different reasonable tolerances produce 2.8x SE differences.
This is a known weakness of 2-step GMM when one parameter is weakly
identified. The iterated GMM that Python currently runs is MORE defensible
asymptotically because it doesn't depend on a path-dependent first step.

So the choice is:
- **Option A**: match Stata bit-for-bit. Requires reverse-engineering
  Stata's `gmm` convergence criteria. Value: direct replication of
  published numbers.
- **Option B**: use iterated GMM as default, document that SEs differ from
  Stata's twostep in weakly-identified directions. Value: cleaner
  asymptotics, more defensible inference.

A principled middle ground: use iterated GMM for the point estimate, but
report SEs from (i) iterated, (ii) 2-step Stata-style, (iii) bootstrap ---
side by side. Let the reader decide.

## Files created (all in `explorations/python-grc/`)

Diagnostic scripts (Python):
- `check_variance.py` --- analytic vs finite-diff Jacobian, sandwich vs
  efficient, eigendecomposition.
- `check_collinearity.py` --- Z rank at various tolerances, alternative
  column-drop strategies.
- `check_variance_formulas.py` --- grid of alternative W matrices.
- `compare_stata_matrices.py` --- loads Stata's e(V)/e(W)/e(b) and does
  apples-to-apples comparison. **The definitive test.**
- `reproduce_stata_twostep.py` --- implements Stata's twostep protocol
  (but used Python's OLS initial values --> different theta_1).
- `match_stata_initial.py` --- 2-step with mu_never = 0 initial (Stata
  convention). Closes the W gap from 28% to 3.2%, but SE still wrong.
- `test_stata_theta1.py` --- uses Stata's exact theta_1. **Written, not
  yet run.**
- `profile_hot_paths.py` --- per-call timings + `_cluster_S` alternatives.

Stata helpers:
- `dump_stata_vcov.do` --- dumps e(V), e(W), e(b) from `grc_verify.ster`.
- `dump_stata_step1.do` --- runs gmm onestep to capture theta_1.

Output CSVs (cached Stata results for Python comparison):
- `stata_vcov.csv`, `stata_W.csv`, `stata_theta_full.csv` --- dump_stata_vcov.do
- `stata_theta1.csv`, `stata_step1_meta.csv` --- dump_stata_step1.do
- `python_out_idn_cons_urb_unb_2step.csv` --- reproduce_stata_twostep.py

Findings writeup:
- `FINDINGS_SE_phi.md` --- full narrative with all diagnostic results.

## Decisions made

- Stata's `gmm` convergence is measurably LOOSER than Python's L-BFGS-B +
  NM for step 1. Not a bug in either; a convention difference. Documented
  in `FINDINGS_SE_phi.md`.
- Nelder-Mead polish is the single biggest cost in Python's `fit()`
  (~96 s per outer iteration vs ~58 s for L-BFGS-B). Documented but not
  yet changed.
- Exploration-fast-track rules apply (60/100 gate, no spec/plan needed
  for explorations/).

## Next steps (in order)

1. **Run `test_stata_theta1.py`** (~5 min). Confirms or refutes whether
   matching Stata's step-1 theta_1 is sufficient to match SE(phi).
2. **If confirmed:** add a `match_stata=True` option to
   `RestrictedGRC.fit()` that (a) uses Stata-style initial values, (b)
   does 2-step with a looser step-1 tolerance chosen to match Stata's
   stopping behavior, (c) reports sandwich SE. Default stays iterated GMM.
3. **Test speed win #1**: skip NM after outer iteration 1; compare final
   theta and J vs current default.
4. **Commit current exploration state** (many new scripts + CSVs).
5. **Decide the Option A / B / middle-ground question** with the user.

## Workspace state

Branch: `main`. Many new untracked files in `explorations/python-grc/`;
no existing files modified since the last commit. No paper-side or
scripts-side changes. The Verdier robust extrapolation track (P0 done,
P1 pending) is untouched and still awaiting P0 sign-off.
