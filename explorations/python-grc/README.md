# Python port of the restricted-GRC GMM estimator

Python re-implementation of the two-step efficient GMM estimator that
Stata's `gmm` runs inside `scripts/0_programs.do::run_grc`. Targets the
pooled unbalanced-panel specification from Proposition 1 of
`paper/unbalanced_proposition.tex` and the restricted GRC model of
Equation `eq:restricted-GRC` in `paper/main.tex`.

Scope: IDN / consumption / urban / unbalanced panel only.

## Files

| File | Purpose |
|------|---------|
| `grc_gmm.py` | `RestrictedGRC` estimator class. |
| `data_loader.py` | Loads `data/processed/*_unb.dta` and builds period dummies. |
| `verify_idn_consumption.py` | Runs Stata + Python on the same IDN sample and compares outputs. |
| `verify_stata.do` | Standalone Stata driver. Runs `run_grc` and writes two CSVs. Can be invoked via the Python wrapper or directly with `stata-mp -b do verify_stata.do`. |
| `requirements.txt`, `environment.yml` | Python 3.10+, pandas, numpy, scipy, statsmodels. |
| `BLOCKER.md` | Outstanding work (see "Verification status" below). |

## Stata to Python mapping

| Stata program (`0_programs.do`)   | Python counterpart (`grc_gmm.py`) |
|-----------------------------------|-----------------------------------|
| `setup_grc_estimation`            | `RestrictedGRC._build_design` (trajectory, always, never, switcher dummies) |
| `initial_values`                  | `RestrictedGRC._ols_initial_values` and `_choose_base` |
| `define_switcherpars`             | Inline in `RestrictedGRC._residuals` (baseline trajectory excluded from the `phi*(mu_s - mu_base)` sum) |
| `run_grc` (the `gmm` call)        | `RestrictedGRC.fit` (two-step L-BFGS-B with analytic gradient) |
| `run_grc` post-estimation `nlcom` | `RestrictedGRC.delta_never`, `delta_always` (delta method via analytic gradient and final variance) |

Parameter vector (in optimizer order):

```
theta = [mu_never,
         mu_{s1}, ..., mu_{sS},
         kappa,
         Delta_base,
         phi,
         gamma_1, ..., gamma_K]     # covariates + (pooled) U_i, U_i*D_it
```

Moment vector (instruments, no constant, matching `run_grc`):

```
z_it = [ x_it',                     # covariates (period dummies, female, ...)
         U_i, U_i * D_it,           # if pooled unbalanced
         1{never},
         1{trajectory = s} for each s,
         D_it,
         1{always} * D_it,
         1{trajectory = s} * D_it for each s ]
```

Sample moment: `g_i(theta) = sum_{t in T_i} z_it * eps_it(theta)` with
`eps_it = y_it - fit_it(theta)` given by Equation
`eq:restricted-grc-unbalanced`.

## Reproducing the verification

From this directory:

```bash
python data_loader.py --country IDN                # sanity-check loader
python verify_idn_consumption.py                   # Stata + Python + diff
```

The verify script writes four artifacts:

- `stata_out_idn_cons_urb_unb.csv` - Stata coefficients and SEs.
- `stata_out_idn_cons_urb_unb_jstat.csv` - Stata J-stat and sample info.
- `python_out_idn_cons_urb_unb.csv` - Python coefficients and SEs.
- `verification_idn_consumption.csv` - joined comparison table with diffs.

Target precision: coefficients to 4 decimals, SEs to 3 decimals, J-stat
to 2 decimals.

Because Stata's GMM on the 92k-observation IDN sample can take 20-60
minutes, a split workflow is usually preferable:

```bash
# 1. Launch Stata in the background (or in a separate shell) and let
#    it write the CSV artifacts at its own pace.
stata-mp -b do verify_stata.do

# 2. Once stata_out_idn_cons_urb_unb.csv exists, run the Python side
#    against the cached CSV without waiting for Stata.
SKIP_STATA=1 python verify_idn_consumption.py
```

Environment variables:

- `STATA_TIMEOUT=<sec>` (default 1800) bounds the subprocess timeout
  when the wrapper runs Stata itself.
- `STATA_EXE=/path/to/StataMP-64.exe` if the executable is not at one
  of the default locations.
- `SKIP_STATA=1` skips the Stata step and re-parses the last CSV.

## Verification status

Python estimator: iterated GMM converges to a stable fixed point in 4-5
outer iterations on the IDN consumption / urban / unbalanced sample.
Post-fix point estimates: `phi = -2.45`, `Delta_base = 0.85`,
`Delta_never = 0.31`, Hansen `J = 97.8` (df = 29). All SEs are finite.

Stata reference: `verify_stata.do` calls the paper's `run_grc` on the
same sample. The Stata-vs-Python coefficient/SE/J diff has not yet been
confirmed --- Stata's GMM is slow enough on this sample that the
comparison has not completed in one sitting. See `BLOCKER.md`.

## Design notes

1. **Two-step efficient GMM** matches Stata's default under
   `vce(cluster pid)`. Identity in step 1, `S^{-1}` at the step-1 theta
   in step 2. Cluster-robust S aggregates moments at the individual id.
2. **Analytic gradient.** The Jacobian `G = d g_bar / d theta` is built
   from `d fit / d theta` (closed-form given the restricted-GRC
   equation). L-BFGS-B with this gradient was more robust on the IDN
   design than plain BFGS with finite differences (which drifted to a
   pathological local minimum).
3. **Base trajectory rule** mirrors `initial_values`: switcher with the
   largest |t| on its `switcher_s * choice` coefficient in the OLS
   initial-values regression, restricted to switchers with N_s / T > 5.
4. **Covariate block.** In unbalanced mode `(U_i, U_i * D_it)` is
   appended to `gamma`. In balanced mode Stata appends a dummy
   `covar_cons = 0` to keep the covariate block well defined; Python
   drops this (an all-zero regressor contributes nothing).
5. **Missing values.** Rows with a missing outcome, choice, or
   covariate are dropped (matching Stata's silent drop). Trajectory may
   stay missing for unbalanced observers; their trajectory indicators
   are zero, as in Proposition 1. No imputation.
6. **`define_switcherpars` base hardcode.** Stata hardcodes
   `define_switcherpars` to `base(2)`, but `run_grc` overrides it via
   `base(\`base')`. On the IDN consumption sample the selected base is
   2, so the hardcode does not bite this verification. Income specs
   for IDN and TZA do bite it and are out of scope.

## Out of scope

- Monte Carlo experiments.
- Heterogeneity plots (`heterogeneity_plots` in `0_programs.do`).
- Hukou-split and experience-split GRC.
- Income specifications (affected by the `define_switcherpars` bug).
- Balanced-panel runs (estimator supports them via `unbalanced_col=None`
  but the verification target is the pooled case).
