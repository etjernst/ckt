# Plan: weak-ID-robust CI for phi via LCA test inversion (Python implementation)

**Date:** 2026-04-23
**Status:** Approved 2026-04-23, ready to implement.
**Implementation language:** Python (decision below).

## 1. Problem

`phi` in CKT's restricted GRC is weakly identified: 97% of `Var(phi)` loads on a single weak eigendirection of the moment Jacobian. Sandwich SEs are W-sensitive --- Stata twostep gives 0.07, Python iterated GMM gives 0.20, Path-A two-step gives 0.04 (`explorations/python-grc/FRESH_EYES_SE_phi.md`). None is wrong; they reflect different choices of W under weak identification.

A weak-ID-robust CI would invert a test statistic over a phi-grid, sidestepping W entirely. The GRC paper (Tjernström 2023 / forthcoming Econometrica) implements this in `grc_weak_id_inference.ado` for its T=2 design. This plan adapts the procedure for CKT (T=3, 4, 5; up to 32 trajectories; μ-difference encoding of comparative advantage) and implements it in Python.

## 2. The procedure (language-agnostic)

The auxiliary-OLS test inversion. Three steps:

1. **Auxiliary OLS.** Saturated regression of `y` on trajectory dummies and (switcher trajectory) × treatment interactions, with cluster-robust SEs at the individual level:

   ```
   y_it = sum_d alpha_d * 1{traj_i = d} + sum_{s in switchers} beta_s * 1{traj_i = s} * D_it
          + gamma' x_it + eps_it
   ```

   This produces one `alpha_d` per trajectory --- estimating mu_d, the mean of `y` in the rural state for that trajectory --- and one `beta_s` per switcher trajectory --- the unrestricted within-group treatment effect.

2. **LCA restriction at fixed phi.** For each candidate phi value on a grid, the LCA hypothesis `Delta_s = beta_base + phi * (mu_s - mu_base)` translates to:

   ```
   r_s(b, phi) = (beta_s - beta_base) - phi * (alpha_s - alpha_base) = 0,    s != base
   ```

   This is **nonlinear in coefficients** (phi multiplies estimated alphas). Wald statistic via the delta method:

   ```
   J_R = (number of switchers tested) - 1
   r = vector of r_s values across kept switchers s != base
   G = Jacobian of r with respect to b   (dimension J_R x dim(b))
   V_R = G * V * G'                       (V = cluster-robust VCV of b)
   Wald(phi) = r' * inv(V_R) * r
   p_value(phi) = 1 - chi2.cdf(Wald(phi), df=J_R)
   ```

   For fixed phi, `r` is **linear** in `b` --- so the Jacobian `G` is a constant selector matrix that depends on phi but not on b.

3. **Invert.** Sweep phi across a grid `[min, max]` step `increment`; collect `(phi, p_value)` pairs; the (1 - alpha) CI is `{phi : p_value >= alpha}`. Take min and max for endpoints.

The validity argument: the auxiliary OLS is just-identified in `(alpha_d, beta_s)` and its cluster-robust VCV is well-conditioned regardless of how weakly identified `phi` is in the GMM problem. The Wald test on the restriction at fixed phi has the standard chi² distribution under the null. Inversion gives a CI honest under weak identification.

## 3. Adaptations vs the GRC paper's `.ado`

Three structural differences. Diagnosis was earlier in this session; documented in `docs/plans/2026-04-23-lca-inversion-ci-ckt.md` v1 (this file's previous draft, now superseded).

| | GRC paper `.ado` (T=2) | CKT (T=3-5) |
|---|---|---|
| θ-encoding | integer trajectory code (sequential, adjacent diff = 1) | μ-difference (`mu_s - mu_base`); adjacent diff varies, estimated from data |
| Restriction type | linear in coefficients | nonlinear in coefficients (phi multiplies estimated mu's) |
| Pairing | adjacent switchers (k - 1 restrictions) | (s, base) anchor (S - 1 restrictions, matching `define_switcherpars`) |

## 4. Why Python (not Stata)

Decided 2026-04-23.

- **Trivial implementation.** Auxiliary OLS via `statsmodels.regression.linear_model.OLS` with cluster-robust SE; Wald via numpy. ~80 lines.
- **Fast.** For fixed phi, the Wald is a linear-algebra one-liner (microseconds per grid point). Stata's `testnl` with 30+ joint nonlinear restrictions is slow (potentially minutes per grid point).
- **Trivially parallelizable.** `joblib.Parallel` over the phi grid. 200 grid points x 3 countries x N specs in seconds.
- **Reuses simulation infrastructure.** The cluster-robust OLS + Wald machinery powers the cluster bootstrap planned for the empirical paper (`docs/TODO.md`) and the inferential layer of the simulations (`explorations/SIMULATION_PLAN.md`).
- **Easier iteration.** No batch-mode reruns; interactive inspection of the (phi, p) curve.

The cost: validation against the original `.ado` requires hand-translating its logic. We mitigate by synthesizing a small T=2 dataset, running the original `.ado` once via Stata batch, then running our Python implementation on the same data and comparing CI endpoints.

## 5. Algorithm in Python

### 5.1 Module: `explorations/python-grc/lca_inversion.py`

Three components.

**`_drop_sparse_switchers(df, switcher_var, choice_var, hhid, threshold=5)`**

Counts unique pids with `switcher_s == 1 & choice == 1` per switcher s. Returns the list of switchers retained (count >= threshold). Mirrors the rank-deficient-moment drop rule planned for `_robust_inv` (`docs/TODO.md`). Same threshold for both procedures by default.

**`fit_auxiliary_ols(df, outcome, trajectory, choice, hhid, switchers_kept, controls=None, base=2)`**

Returns:
- `b` --- coefficient vector
- `V` --- cluster-robust VCV at `hhid`
- `name_to_idx` --- dict mapping coefficient names to indices in `b` (e.g., `"alpha[2]"`, `"beta[3]"`, `"gamma[unbalanced]"`)
- `J_R` --- number of LCA restrictions = `len(switchers_kept) - 1`

Implementation: build the design matrix with one column per trajectory (alpha_d) and one column per switcher × choice (beta_s); fit via `statsmodels.OLS`; cluster VCV via `OLSResults.get_robustcov_results(cov_type="cluster", groups=df[hhid])`.

**`grid_lca_inversion(b, V, name_to_idx, switchers_kept, base, phi_grid, type_one=0.05)`**

For each phi in the grid:
- Build selector matrix `G(phi)` of shape `(J_R, len(b))`. For each restricted switcher s, the row picks +1 on `beta_s`, -1 on `beta_base`, -phi on `alpha_s`, +phi on `alpha_base`. Other entries 0.
- Compute `r = G @ b` and `V_R = G @ V @ G.T`.
- `Wald = r @ pinv(V_R) @ r`; `p = 1 - chi2.cdf(Wald, df=J_R)`.

Returns a DataFrame `[phi, p_value]`. CI endpoints = `(min, max)` over phi where `p_value >= type_one`.

### 5.2 Driver: `explorations/python-grc/run_lca_inversion.py`

For each (country, spec):
- Load processed `.dta` via `data_loader.py`.
- Determine `base` from CKT's `initial_values` rule (or pass explicitly --- decided per spec).
- Run `_drop_sparse_switchers`.
- Run `fit_auxiliary_ols`.
- First-pass: coarse grid `[-6, 2]` step 0.05 (160 points); identify approximate CI.
- Second pass: fine grid step 0.01 around the rough endpoints.
- Save full grid to `output/lca_inversion_{country}_{spec}.parquet`.
- Append summary (CI endpoints) to `output/lca_inversion_summary.csv`.

### 5.3 Output

```
explorations/python-grc/
├── lca_inversion.py                                         # estimator
├── run_lca_inversion.py                                     # driver
└── output/
    ├── lca_inversion_idn_cons_urb_unb.parquet               # full (phi, p) curve
    ├── lca_inversion_chn_cons_urb_unb.parquet
    ├── lca_inversion_tza_cons_urb_unb.parquet
    └── lca_inversion_summary.csv                            # CI endpoints across countries / specs
```

### 5.4 No island detection in v1

The simple `(min, max)` over non-rejected grid is what we ship in v1. Island detection (multiple disconnected non-rejected regions, possible under regime heterogeneity in CHN) is on `docs/TODO.md` for a future iteration.

## 6. Validation plan

Three layers, in order.

### 6.1 T=2 backward compatibility (synthesized data)

Goal: confirm the Python implementation reproduces the original `.ado`'s CI on data the original was designed for.

- Synthesize a T=2 panel: N = 5,000 individuals, two periods, four trajectories with shares calibrated to Suri (2011) (matching the GRC paper's MC). Set `phi = -1.5`, `beta = 0.5`, draw alpha and outcomes per the GRC DGP. Save as `.dta`.
- Stata side: run `grc_weak_id_inference.ado` on the synthesized data with grid `[-3, 1]` step 0.02. Save the postfile as `.dta`.
- Python side: run our `lca_inversion.py` on the same data with the same grid. Save as `.parquet`.
- Compare: CI endpoints should agree to 2 decimal places. The (phi, p) curves should agree pointwise to ~1e-3.

If they disagree by more, debug. Likely culprits: (a) different VCV formula (`vce(cluster)` in Stata vs `cov_type="cluster"` in statsmodels --- check the small-sample correction); (b) incorrect restriction encoding; (c) different reference category in the OLS.

### 6.2 IDN/cons/urban/unb baseline

Run on the IDN data (the spec we have been debugging all session). Expectations:

- `phi_hat ≈ -2.45` from CKT's GMM should fall well inside the inversion CI.
- The (phi, p) curve should be roughly unimodal with peak near `phi_hat`.
- CI width: between Stata's `1.96 * 0.07 = 0.14` and Python's `1.96 * 0.20 = 0.39` is plausible. Anything narrower than 0.14 suggests an error; anything wider than 0.5 suggests genuinely weak data.

### 6.3 CHN, TZA rollout

- CHN: J-stat rejects in pooled sample (hukou splits resolve). The CI may be very wide or multimodal (the latter we ignore in v1; flagged in `docs/TODO.md`).
- TZA: small sample, T=3. CI may be wider; that's expected and reported honestly.

## 7. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `statsmodels` cluster small-sample correction doesn't match Stata's `(n-1)/(n-k) * G/(G-1)` | medium | Apply the Stata correction explicitly; compare a known regression to Stata's `reg ..., vce(cluster pid)` output and match SEs. |
| Sparse switcher pre-drop interacts with auxiliary OLS rank | low | After `_drop_sparse_switchers`, the design matrix may still have a column with very few nonzero entries. Statsmodels handles this gracefully (drops collinear columns); we log and report any auto-drops. |
| CI hits the grid boundary | medium | Detect at run time; widen grid and rerun. Initial grid `[-6, 2]` is conservatively wide for IDN; CHN may need wider. |
| Auxiliary OLS `mu_s` differs systematically from GMM's `mu_s` | low | OLS coefficient on `i.trajectory` partials out controls and gives the conditional mean of `y` in the omitted (rural) state. This matches the GMM moment definition. Sanity-check on IDN: report `OLS mu_s` and `GMM mu_s` side by side, expect agreement to ~0.01 in log-consumption units. |
| The synthesized T=2 dataset doesn't match the GRC paper's MC closely enough to cleanly compare | low | Use the GRC paper's exact published DGP (`explorations/GRC.tex` simulations section). If a saved synthetic dataset already exists in the GRC repo, use that. |
| Validation against the original `.ado` fails for opaque reasons | medium | Fall back: re-implement the original `.ado` logic in Python (treating the trajectory codes as the θ-encoding) and compare to the same `.ado`. If THAT matches, the CKT adaptation is the source of the difference --- inspect the restriction encoding. |

## 8. Stage decomposition and effort

| Stage | Description | Estimated effort |
|---|---|---|
| 8a | Implement `lca_inversion.py` (the three functions in §5.1). Smoke-test on a simple regression. | 2 h |
| 8b | Synthesize T=2 dataset; run original `.ado`; run new Python; compare. | 2 h |
| 8c | Implement `run_lca_inversion.py`. First-pass IDN run. | 1 h |
| 8d | Diagnose any IDN issues. Fine-grid second pass. | 1 h |
| 8e | CHN and TZA runs. | 1 h (mostly compute) |
| 8f | Writeup `docs/reviews/2026-04-XX-lca-inversion-ci-results.md`. Plot (phi, p) curves; tabulate CIs alongside sandwich SEs. | 1 h |
| **Total** | | **~1 day** |

## 9. Approved decisions (2026-04-23)

1. **Implementation language:** Python.
2. **Files:** `explorations/python-grc/lca_inversion.py` and `run_lca_inversion.py`. Output to `explorations/python-grc/output/`. If the procedure graduates to production, move to `scripts/python/`.
3. **Base trajectory:** Use the data-driven base from CKT's `initial_values` for each (country, spec).
4. **Grid:** First pass `[-6, 2]` step 0.05; refine around CI endpoints with step 0.01.
5. **Output format:** `parquet` for grid curves, `csv` for the cross-spec summary.
6. **Auxiliary OLS controls:** Match the GMM column being inverted (e.g., `unbalanced`, `unbalanced_choice`, plus any covariates --- none for `covs_0`).
7. **Sparse-switcher threshold:** 5 unique pids with `switcher_s == 1 & choice == 1`. Same number used for the rcond-related sparse-moment pre-drop in the Python GMM port.
8. **Islands:** Defer. Tracked in `docs/TODO.md`.
9. **Validation:** Synthesize a T=2 dataset rather than searching for one. Run original `.ado` once via Stata batch for the comparison.

## 10. Two streams of work, made explicit

This work belongs to **stream A: weak-ID inference**. The other active stream is **stream B: Python port → simulation** (`explorations/SIMULATION_PLAN.md`). They overlap on infrastructure:

- Stream A's auxiliary-OLS-with-cluster-VCV becomes the cluster bootstrap engine in stream B (planned in `docs/TODO.md`).
- Stream B's `_robust_inv` rcond fix (`docs/TODO.md`) closes the SE divergence that motivated stream A in the first place. Both should be done; they answer different questions.

## 11. Out of scope

- Stata implementation. The original `.ado` stays as-is for cross-checking.
- Bootstrap CIs. Separate effort.
- Specs other than `cons / urban / unb`. Will extend after the consumption baseline works.
- Hukou-split and balanced-subsample versions. Will follow the country rollout if results are interesting.
- Island detection. `docs/TODO.md`.
