# GMM convergence audit — GrRC specifications

_Date: 2026-04-22 · Source: `scripts/logs/*GrRC*.log` (last run 2026-04-01/02)_

## Diagnosis (read first)

- **21 / 286 GrRC runs did not converge.**
- **IDN never fails** (0 / 100). All failures are CHN, CHN-hukou, or TZA.
- Failures cluster in the **least-saturated specifications** (no covariates, no covariates + time FE, + female) and disappear once age² or education are added.
- **Hukou splits amplify the problem** — rural-first and rural-only (the smaller CHN subsamples) fail most; urban-first/urban-only almost never fail.
- Failing runs share a distinctive signature:
  - `phi` pinned near **−1.00 ± 0.001** (i.e., it never moves from its initial value `{phi=-1}`)
  - `kappa` standard error in the **thousands to millions** (e.g. 4.48e+06 for CHN rural-only income c_t)
  - `kappa` point estimate absurdly large (75--315 on the log-consumption scale where `mu` is ≈9--14)
  - Final GMM criterion Q(b) very small (0.0002--0.003)
- **This is a weak-identification / flat-criterion pattern, not non-concavity.** GMM's criterion is quadratic, so non-concavity per se doesn't apply — the objective is locally flat in the `kappa` direction because the always-urban group is small (and smaller still after hukou splits) and the moments that identify `kappa` --- which rely on always-urban observations --- have little power. The optimizer reduces Q(b) into the 1e-3 range and then stalls because the gradient with respect to `kappa` is nearly zero; `phi` never leaves its starting value because its derivative is also nearly zero at that slice of the parameter space.
- The iteration log is **suppressed** (`run_grc` calls `gmm … nolog`), so we can't see Stata's own `(not concave)` / `(backed up)` / `(flat region)` annotations. Re-running a handful of failed specs without `nolog` would confirm the mechanism; the SE pattern is already strongly consistent with a flat likelihood in `kappa`, not non-concavity.

### Things worth trying

1. **Rerun a few failing specs without `nolog`** to see Stata's iteration-level diagnostics.
2. **Profile `kappa` directly**: fix `kappa` at a grid of values and re-estimate the rest. If `Q(b)` is nearly constant across the grid, `kappa` is unidentified at this sample.
3. **Start `kappa` from the always-urban `mu`** (or a data-driven value) instead of letting it float from the default. Current failures show `kappa ≈ 150+` which is far outside the plausible range.
4. **Bound `kappa` and/or `phi`** via `{kappa:...}` initial-value syntax, or impose a prior/penalty.
5. **Drop the `always`-urban block from the moment system** for cells where the always group is very small (<1% of sample). Without always-urban observations, `kappa` drops out of the model.
6. **Loosen `ltolerance`/`nrtolerance`** or increase `iterate()` above 500 — unlikely to help given the SE pattern, but cheap to test.
7. **Switch optimizer**: try `technique(nr)` or `technique(bhhh)` — may help if the issue is a bad step in the current algorithm rather than true flatness.

## Summary

| Log | Total runs | Converged | Failed |
|---|---:|---:|---:|
| `10_GrRC_experience.log` | 36 | 34 | **2** |
| `11_GrRC_max_experience.log` | 36 | 34 | **2** |
| `12_GrRC_experience_share.log` | 36 | 34 | **2** |
| `13_GrRC_max_experience_share.log` | 36 | 34 | **2** |
| `14_GrRC_NonAg_experience.log` | 16 | 16 | **0** |
| `15_GrRC_birth.log` | 16 | 16 | **0** |
| `5_GrRC.log` | 45 | 41 | **4** |
| `6_GrRC_NonAg.log` | 5 | 5 | **0** |
| `8_GrRC_hukou.log` | 60 | 51 | **9** |
| **Total** | **286** | **265** | **21** |

### Failures by country (across all GrRC logs)

| Country | Total runs | Failed | Failure rate |
|---|---:|---:|---:|
| CHN | 63 | 10 | 15.9% |
| CHN_hukou_rural_first | 15 | 3 | 20.0% |
| CHN_hukou_rural_only | 15 | 5 | 33.3% |
| CHN_hukou_urban_first | 15 | 1 | 6.7% |
| CHN_hukou_urban_only | 15 | 0 | 0.0% |
| IDN | 100 | 0 | 0.0% |
| TZA | 63 | 2 | 3.2% |

## Convergence grid — one row per (log, section, country)

Each cell is the sequence of `run_grc` calls in that cell, in order. `✓` = converged, `✗` = convergence not achieved.

| Log | Section | Country | Runs (in order) |
|---|---|---|---|
| `10_GrRC_experience.log` | 1. Consumption \| Urban \| Unbalanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 1. Consumption \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 2. Consumption \| Urban \| Balanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 2. Consumption \| Urban \| Balanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 3. Income \| Urban \| Unbalanced | CHN | ✗ ? · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `10_GrRC_experience.log` | 3. Income \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 1. Consumption \| Urban \| Unbalanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 1. Consumption \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 2. Consumption \| Urban \| Balanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 2. Consumption \| Urban \| Balanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 3. Income \| Urban \| Unbalanced | CHN | ✗ ? · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `11_GrRC_max_experience.log` | 3. Income \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 2. Consumption \| Urban \| Balanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 2. Consumption \| Urban \| Balanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 3. Income \| Urban \| Unbalanced | CHN | ✗ ? · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `12_GrRC_experience_share.log` | 3. Income \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 1. Consumption \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 2. Consumption \| Urban \| Balanced | CHN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 2. Consumption \| Urban \| Balanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 3. Income \| Urban \| Unbalanced | CHN | ✗ ? · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `13_GrRC_max_experience_share.log` | 3. Income \| Urban \| Unbalanced | TZA | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `14_GrRC_NonAg_experience.log` | 1. Consumption \| Nonag \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `14_GrRC_NonAg_experience.log` | 2. Consumption \| Nonag \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `14_GrRC_NonAg_experience.log` | 3. Consumption \| Nonag \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `14_GrRC_NonAg_experience.log` | 4. Consumption \| Nonag \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `15_GrRC_birth.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `15_GrRC_birth.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `15_GrRC_birth.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `15_GrRC_birth.log` | 4. Consumption \| Nonag \| Unbalanced | IDN | ✓ ? · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 1. Consumption \| Urban \| Unbalanced | CHN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 1. Consumption \| Urban \| Unbalanced | IDN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 1. Consumption \| Urban \| Unbalanced | TZA | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 2. Consumption \| Urban \| Balanced | CHN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2     |
| `5_GrRC.log` | 2. Consumption \| Urban \| Balanced | IDN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 2. Consumption \| Urban \| Balanced | TZA | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 3. Income \| Urban \| Unbalanced | CHN | ✓ No covariates · ✗ Add time FE · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 3. Income \| Urban \| Unbalanced | IDN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `5_GrRC.log` | 3. Income \| Urban \| Unbalanced | TZA | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `6_GrRC_NonAg.log` | 1. Consumption \| Nonag \| Unbalanced | IDN | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 1. Consumption \| Urban \| Unbalanced | CHN_hukou_rural_first | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 1. Consumption \| Urban \| Unbalanced | CHN_hukou_rural_only | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 1. Consumption \| Urban \| Unbalanced | CHN_hukou_urban_first | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 1. Consumption \| Urban \| Unbalanced | CHN_hukou_urban_only | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 2. Consumption \| Urban \| Balanced | CHN_hukou_rural_first | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2     |
| `8_GrRC_hukou.log` | 2. Consumption \| Urban \| Balanced | CHN_hukou_rural_only | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2     |
| `8_GrRC_hukou.log` | 2. Consumption \| Urban \| Balanced | CHN_hukou_urban_first | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2     |
| `8_GrRC_hukou.log` | 2. Consumption \| Urban \| Balanced | CHN_hukou_urban_only | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2     |
| `8_GrRC_hukou.log` | 3. Income \| Urban \| Unbalanced | CHN_hukou_rural_first | ✗ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 3. Income \| Urban \| Unbalanced | CHN_hukou_rural_only | ✗ No covariates · ✗ Add time FE · ✗ Add female · ✓ Add age2 · ✓ Add education & education2 |
| `8_GrRC_hukou.log` | 3. Income \| Urban \| Unbalanced | CHN_hukou_urban_first | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✗ Add education & education2 |
| `8_GrRC_hukou.log` | 3. Income \| Urban \| Unbalanced | CHN_hukou_urban_only | ✓ No covariates · ✓ Add time FE · ✓ Add female · ✓ Add age2 · ✓ Add education & education2 |

## Failed runs — detail

21 failed runs across 6 logs.

| Log | Line | Country | Section | estname | Comment | base | Q(b) | φ | SE(φ) | κ | SE(κ) |
|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|
| `10_GrRC_experience.log` | 10867 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c1` | ? | 2 | 0.0002 | -0.9997 | 0.2239 | 88.16 | 5.15e+04 |
| `10_GrRC_experience.log` | 11054 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c2` | Add female | 2 | 0.0003 | -0.9995 | 0.2380 | 76.36 | 3.25e+04 |
| `11_GrRC_max_experience.log` | 10807 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c1` | ? | 2 | 0.0002 | -0.9995 | 0.2260 | 85.99 | 3.54e+04 |
| `11_GrRC_max_experience.log` | 10994 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c2` | Add female | 2 | 0.0003 | -0.9995 | 0.2379 | 81.21 | 3.24e+04 |
| `12_GrRC_experience_share.log` | 10807 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c1` | ? | 2 | 0.0003 | -0.9988 | 0.2267 | 79.51 | 1.37e+04 |
| `12_GrRC_experience_share.log` | 10994 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c2` | Add female | 2 | 0.0003 | -0.9982 | 0.2365 | 74.28 | 8418.85 |
| `13_GrRC_max_experience_share.log` | 10808 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c1` | ? | 2 | 0.0003 | -0.9988 | 0.2222 | 79.91 | 1.36e+04 |
| `13_GrRC_max_experience_share.log` | 10995 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_c2` | Add female | 2 | 0.0003 | -0.9982 | 0.2353 | 78.98 | 9174.67 |
| `5_GrRC.log` | 2414 | TZA | 1. Consumption \| Urban \| Unbalanced | `grc_TZA_covs_0` | No covariates | 2 | 0.0021 | -0.9985 | 0.0644 | 153.33 | 5950.89 |
| `5_GrRC.log` | 7266 | TZA | 2. Consumption \| Urban \| Balanced | `grc_TZA_covs_0` | No covariates | 2 | 0.0027 | -0.9985 | 0.0644 | 153.33 | 5950.89 |
| `5_GrRC.log` | 13118 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_covs_trend` | Add time FE | 2 | 0.0002 | -0.9993 | 0.2246 | 84.60 | 2.28e+04 |
| `5_GrRC.log` | 13304 | CHN | 3. Income \| Urban \| Unbalanced | `grc_CHN_covs_1` | Add female | 2 | 0.0003 | -0.9989 | 0.2344 | 75.92 | 1.39e+04 |
| `8_GrRC_hukou.log` | 177 | CHN_hukou_rural_first | 1. Consumption \| Urban \| Unbalanced | `grc_CHN_hukou_rural_first_c0` | No covariates | 2 | 0.0012 | -1.0002 | 0.0770 | 149.72 | 4.60e+04 |
| `8_GrRC_hukou.log` | 1298 | CHN_hukou_rural_first | 2. Consumption \| Urban \| Balanced | `grc_CHN_hukou_rural_first_c0` | No covariates | 2 | 0.0023 | -1.0002 | 0.0770 | 149.72 | 4.60e+04 |
| `8_GrRC_hukou.log` | 2372 | CHN_hukou_rural_first | 3. Income \| Urban \| Unbalanced | `grc_CHN_hukou_rural_first_c0` | No covariates | 2 | 0.0004 | -1.0008 | 0.3471 | 136.74 | 5.28e+04 |
| `8_GrRC_hukou.log` | 5613 | CHN_hukou_urban_first | 3. Income \| Urban \| Unbalanced | `grc_CHN_hukou_urban_first_ca` | Add education & education2 | 2 | 0.0002 | -1.0000 | 0.0004 | — | — |
| `8_GrRC_hukou.log` | 6029 | CHN_hukou_rural_only | 1. Consumption \| Urban \| Unbalanced | `grc_CHN_hukou_rural_only_c0` | No covariates | 2 | 0.0015 | -1.0003 | 0.0820 | 150.60 | 4.50e+04 |
| `8_GrRC_hukou.log` | 7150 | CHN_hukou_rural_only | 2. Consumption \| Urban \| Balanced | `grc_CHN_hukou_rural_only_c0` | No covariates | 2 | 0.0028 | -1.0003 | 0.0820 | 150.60 | 4.50e+04 |
| `8_GrRC_hukou.log` | 8224 | CHN_hukou_rural_only | 3. Income \| Urban \| Unbalanced | `grc_CHN_hukou_rural_only_c0` | No covariates | 2 | 0.0004 | -1.0001 | 0.3482 | 162.74 | 8.36e+05 |
| `8_GrRC_hukou.log` | 8341 | CHN_hukou_rural_only | 3. Income \| Urban \| Unbalanced | `grc_CHN_hukou_rural_only_ct` | Add time FE | 2 | 0.0005 | -1.0000 | 0.2890 | 315.06 | 4.48e+06 |
| `8_GrRC_hukou.log` | 8461 | CHN_hukou_rural_only | 3. Income \| Urban \| Unbalanced | `grc_CHN_hukou_rural_only_c1` | Add female | 2 | 0.0007 | -1.0000 | 0.4187 | 216.87 | 4.22e+06 |

## Full cross-tab (converged = ✓, failed = ✗)

### `10_GrRC_experience.log`

**1. Consumption \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✓ | -0.0947 | 0.1407 | 9.81 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0002 | ✓ | -0.0948 | 0.1409 | 9.81 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0002 | ✓ | -0.1733 | 0.1193 | 10.02 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0002 | ✓ | -0.2150 | 0.1354 | 9.52 | 0.05 |

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0003 | ✓ | -0.3045 | 0.0872 | 11.34 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0003 | ✓ | -0.3061 | 0.0869 | 11.34 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3137 | 0.0863 | 11.35 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.4725 | 0.1022 | 10.78 | 0.06 |

**1. Consumption \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0002 | ✓ | -0.5439 | 0.0923 | 15.00 | 0.15 |
| `grc_TZA_c2` | 2 | 0.0002 | ✓ | -0.5524 | 0.0930 | 15.04 | 0.16 |
| `grc_TZA_c3` | 2 | 0.0002 | ✓ | -0.5660 | 0.0947 | 15.12 | 0.17 |
| `grc_TZA_ca` | 2 | 0.0002 | ✓ | -0.7272 | 0.1266 | 15.00 | 0.51 |

**2. Consumption \| Urban \| Balanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✓ | -0.1077 | 0.1384 | 9.81 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0003 | ✓ | -0.1076 | 0.1387 | 9.81 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0003 | ✓ | -0.1648 | 0.1222 | 10.06 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0003 | ✓ | -0.2343 | 0.1365 | 9.55 | 0.06 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0014 | ✓ | -0.1931 | 0.0935 | 11.21 | 0.04 |
| `grc_IDN_c2` | 2 | 0.0014 | ✓ | -0.1816 | 0.0952 | 11.16 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0014 | ✓ | -0.1822 | 0.0951 | 11.18 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0014 | ✓ | -0.2796 | 0.1200 | 10.64 | 0.06 |

**2. Consumption \| Urban \| Balanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0004 | ✓ | -0.5022 | 0.0962 | 14.93 | 0.14 |
| `grc_TZA_c2` | 2 | 0.0004 | ✓ | -0.5101 | 0.0969 | 14.98 | 0.14 |
| `grc_TZA_c3` | 2 | 0.0004 | ✓ | -0.4971 | 0.1018 | 15.02 | 0.14 |
| `grc_TZA_ca` | 2 | 0.0001 | ✓ | -0.7067 | 0.1226 | 14.91 | 0.43 |

**3. Income \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✗ | -0.9997 | 0.2239 | 88.16 | 5.15e+04 |
| `grc_CHN_c2` | 2 | 0.0003 | ✗ | -0.9995 | 0.2380 | 76.36 | 3.25e+04 |
| `grc_CHN_c3` | 2 | 6.55e-05 | ✓ | -1.5905 | 0.3123 | 9.95 | 0.22 |
| `grc_CHN_ca` | 2 | 2.94e-05 | ✓ | -1.5307 | 0.2127 | 9.11 | 0.23 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 16 | 0.0005 | ✓ | 0.4893 | 0.1722 | 15.22 | 0.04 |
| `grc_IDN_c2` | 16 | 0.0005 | ✓ | 0.5093 | 0.1693 | 15.41 | 0.04 |
| `grc_IDN_c3` | 16 | 0.0005 | ✓ | 0.4290 | 0.1672 | 15.53 | 0.04 |
| `grc_IDN_ca` | 16 | 0.0005 | ✓ | 0.7397 | 0.2591 | 14.63 | 0.04 |

**3. Income \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 5 | 0.0007 | ✓ | -0.3037 | 0.1873 | 15.79 | 0.27 |
| `grc_TZA_c2` | 5 | 0.0007 | ✓ | -0.2809 | 0.1933 | 15.91 | 0.26 |
| `grc_TZA_c3` | 5 | 0.0007 | ✓ | -0.2877 | 0.2033 | 15.67 | 0.28 |
| `grc_TZA_ca` | 5 | 0.0005 | ✓ | -0.7745 | 0.2011 | 16.08 | 1.99 |

### `11_GrRC_max_experience.log`

**1. Consumption \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✓ | -0.0932 | 0.1389 | 9.81 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0002 | ✓ | -0.0933 | 0.1391 | 9.82 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0002 | ✓ | -0.1718 | 0.1187 | 10.03 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0002 | ✓ | -0.2134 | 0.1349 | 9.52 | 0.05 |

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | -0.3070 | 0.0884 | 11.37 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0003 | ✓ | -0.3071 | 0.0882 | 11.39 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3164 | 0.0876 | 11.40 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.5284 | 0.1005 | 10.81 | 0.07 |

**1. Consumption \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0002 | ✓ | -0.5492 | 0.0920 | 15.07 | 0.16 |
| `grc_TZA_c2` | 2 | 0.0002 | ✓ | -0.5597 | 0.0929 | 15.13 | 0.17 |
| `grc_TZA_c3` | 2 | 0.0002 | ✓ | -0.5769 | 0.0946 | 15.22 | 0.18 |
| `grc_TZA_ca` | 2 | 0.0001 | ✓ | -0.7189 | 0.1257 | 14.99 | 0.48 |

**2. Consumption \| Urban \| Balanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✓ | -0.1084 | 0.1361 | 9.81 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0003 | ✓ | -0.1085 | 0.1364 | 9.82 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0003 | ✓ | -0.1643 | 0.1214 | 10.06 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0003 | ✓ | -0.2332 | 0.1359 | 9.55 | 0.06 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0014 | ✓ | -0.2126 | 0.0920 | 11.15 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0014 | ✓ | -0.2082 | 0.0926 | 11.06 | 0.06 |
| `grc_IDN_c3` | 2 | 0.0014 | ✓ | -0.2090 | 0.0926 | 11.07 | 0.06 |
| `grc_IDN_ca` | 2 | 0.0014 | ✓ | -0.3146 | 0.1155 | 10.54 | 0.07 |

**2. Consumption \| Urban \| Balanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0003 | ✓ | -0.5383 | 0.0931 | 15.05 | 0.15 |
| `grc_TZA_c2` | 2 | 0.0003 | ✓ | -0.5488 | 0.0941 | 15.11 | 0.16 |
| `grc_TZA_c3` | 2 | 0.0003 | ✓ | -0.5522 | 0.0974 | 15.18 | 0.17 |
| `grc_TZA_ca` | 2 | 0.0001 | ✓ | -0.7084 | 0.1235 | 14.94 | 0.44 |

**3. Income \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✗ | -0.9995 | 0.2260 | 85.99 | 3.54e+04 |
| `grc_CHN_c2` | 2 | 0.0003 | ✗ | -0.9995 | 0.2379 | 81.21 | 3.24e+04 |
| `grc_CHN_c3` | 2 | 5.60e-05 | ✓ | -1.5898 | 0.4058 | 9.91 | 0.24 |
| `grc_CHN_ca` | 2 | 3.00e-05 | ✓ | -1.5315 | 0.2116 | 9.11 | 0.23 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 16 | 0.0005 | ✓ | 0.4615 | 0.1662 | 15.05 | 0.05 |
| `grc_IDN_c2` | 16 | 0.0005 | ✓ | 0.5463 | 0.1760 | 15.33 | 0.05 |
| `grc_IDN_c3` | 16 | 0.0007 | ✓ | 0.2241 | 0.1214 | 15.41 | 0.05 |
| `grc_IDN_ca` | 16 | 0.0007 | ✓ | 0.4815 | 0.2081 | 14.43 | 0.05 |

**3. Income \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 5 | 0.0007 | ✓ | -0.2050 | 0.2142 | 16.60 | 0.25 |
| `grc_TZA_c2` | 5 | 0.0007 | ✓ | -0.1801 | 0.2218 | 16.75 | 0.25 |
| `grc_TZA_c3` | 5 | 0.0007 | ✓ | -0.1840 | 0.2353 | 16.51 | 0.26 |
| `grc_TZA_ca` | 5 | 0.0003 | ✓ | -0.8094 | 0.2053 | 17.54 | 2.82 |

### `12_GrRC_experience_share.log`

**1. Consumption \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✓ | -0.0724 | 0.1334 | 9.76 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0002 | ✓ | -0.0725 | 0.1332 | 9.76 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0002 | ✓ | -0.1622 | 0.1181 | 10.02 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0002 | ✓ | -0.2017 | 0.1328 | 9.50 | 0.05 |

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | -0.3083 | 0.0870 | 11.34 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0004 | ✓ | -0.3098 | 0.0868 | 11.35 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3195 | 0.0862 | 11.35 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.4961 | 0.1013 | 10.73 | 0.07 |

**1. Consumption \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0002 | ✓ | -0.5505 | 0.0913 | 15.06 | 0.16 |
| `grc_TZA_c2` | 2 | 0.0002 | ✓ | -0.5577 | 0.0920 | 15.10 | 0.16 |
| `grc_TZA_c3` | 2 | 0.0002 | ✓ | -0.5718 | 0.0937 | 15.19 | 0.18 |
| `grc_TZA_ca` | 2 | 0.0002 | ✓ | -0.7341 | 0.1275 | 15.05 | 0.54 |

**2. Consumption \| Urban \| Balanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✓ | -0.0992 | 0.1290 | 9.77 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0003 | ✓ | -0.0993 | 0.1288 | 9.76 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0003 | ✓ | -0.1569 | 0.1206 | 10.05 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0003 | ✓ | -0.2300 | 0.1339 | 9.54 | 0.06 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0014 | ✓ | -0.1944 | 0.0934 | 11.16 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0014 | ✓ | -0.1831 | 0.0949 | 11.10 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0014 | ✓ | -0.1838 | 0.0948 | 11.11 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0014 | ✓ | -0.2796 | 0.1201 | 10.57 | 0.06 |

**2. Consumption \| Urban \| Balanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0003 | ✓ | -0.5315 | 0.0928 | 15.03 | 0.15 |
| `grc_TZA_c2` | 2 | 0.0003 | ✓ | -0.5384 | 0.0936 | 15.07 | 0.15 |
| `grc_TZA_c3` | 2 | 0.0003 | ✓ | -0.5334 | 0.0973 | 15.12 | 0.16 |
| `grc_TZA_ca` | 2 | 0.0002 | ✓ | -0.7182 | 0.1246 | 14.98 | 0.47 |

**3. Income \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✗ | -0.9988 | 0.2267 | 79.51 | 1.37e+04 |
| `grc_CHN_c2` | 2 | 0.0003 | ✗ | -0.9982 | 0.2365 | 74.28 | 8418.85 |
| `grc_CHN_c3` | 2 | 5.01e-05 | ✓ | -1.6303 | 0.3309 | 9.81 | 0.21 |
| `grc_CHN_ca` | 2 | 7.62e-05 | ✓ | -0.9822 | 0.1977 | 10.78 | 17.88 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 16 | 0.0005 | ✓ | 0.4559 | 0.1647 | 15.20 | 0.05 |
| `grc_IDN_c2` | 16 | 0.0005 | ✓ | 0.5273 | 0.1748 | 15.50 | 0.05 |
| `grc_IDN_c3` | 16 | 0.0007 | ✓ | 0.2313 | 0.1201 | 15.55 | 0.05 |
| `grc_IDN_ca` | 16 | 0.0006 | ✓ | 0.4727 | 0.2015 | 14.52 | 0.05 |

**3. Income \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 5 | 0.0007 | ✓ | -0.2452 | 0.1992 | 16.39 | 0.26 |
| `grc_TZA_c2` | 5 | 0.0007 | ✓ | -0.2274 | 0.2043 | 16.49 | 0.25 |
| `grc_TZA_c3` | 5 | 0.0007 | ✓ | -0.2340 | 0.2158 | 16.26 | 0.27 |
| `grc_TZA_ca` | 5 | 0.0004 | ✓ | -0.8562 | 0.2219 | 18.01 | 5.32 |

### `13_GrRC_max_experience_share.log`

**1. Consumption \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0002 | ✓ | -0.0709 | 0.1322 | 9.75 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0002 | ✓ | -0.0708 | 0.1320 | 9.75 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0002 | ✓ | -0.1615 | 0.1173 | 10.01 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0002 | ✓ | -0.2003 | 0.1331 | 9.50 | 0.05 |

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | -0.3094 | 0.0874 | 11.35 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0004 | ✓ | -0.3099 | 0.0873 | 11.37 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3206 | 0.0867 | 11.38 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.5235 | 0.0996 | 10.77 | 0.07 |

**1. Consumption \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0002 | ✓ | -0.5552 | 0.0913 | 15.08 | 0.16 |
| `grc_TZA_c2` | 2 | 0.0002 | ✓ | -0.5655 | 0.0922 | 15.14 | 0.17 |
| `grc_TZA_c3` | 2 | 0.0002 | ✓ | -0.5854 | 0.0940 | 15.23 | 0.19 |
| `grc_TZA_ca` | 2 | 0.0001 | ✓ | -0.7220 | 0.1262 | 15.00 | 0.49 |

**2. Consumption \| Urban \| Balanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✓ | -0.0968 | 0.1281 | 9.76 | 0.05 |
| `grc_CHN_c2` | 2 | 0.0003 | ✓ | -0.0969 | 0.1279 | 9.75 | 0.05 |
| `grc_CHN_c3` | 2 | 0.0003 | ✓ | -0.1576 | 0.1195 | 10.05 | 0.06 |
| `grc_CHN_ca` | 2 | 0.0003 | ✓ | -0.2310 | 0.1338 | 9.54 | 0.06 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0014 | ✓ | -0.2120 | 0.0921 | 11.15 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0014 | ✓ | -0.2074 | 0.0927 | 11.07 | 0.06 |
| `grc_IDN_c3` | 2 | 0.0014 | ✓ | -0.2081 | 0.0927 | 11.07 | 0.06 |
| `grc_IDN_ca` | 2 | 0.0014 | ✓ | -0.3127 | 0.1157 | 10.54 | 0.07 |

**2. Consumption \| Urban \| Balanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 2 | 0.0003 | ✓ | -0.5383 | 0.0931 | 15.05 | 0.15 |
| `grc_TZA_c2` | 2 | 0.0003 | ✓ | -0.5488 | 0.0941 | 15.11 | 0.16 |
| `grc_TZA_c3` | 2 | 0.0003 | ✓ | -0.5522 | 0.0974 | 15.18 | 0.17 |
| `grc_TZA_ca` | 2 | 0.0001 | ✓ | -0.7084 | 0.1235 | 14.94 | 0.44 |

**3. Income \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_c1` | 2 | 0.0003 | ✗ | -0.9988 | 0.2222 | 79.91 | 1.36e+04 |
| `grc_CHN_c2` | 2 | 0.0003 | ✗ | -0.9982 | 0.2353 | 78.98 | 9174.67 |
| `grc_CHN_c3` | 2 | 6.48e-05 | ✓ | -1.6020 | 0.2555 | 9.87 | 0.21 |
| `grc_CHN_ca` | 2 | 8.32e-05 | ✓ | -0.9846 | 0.2089 | 10.31 | 15.31 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 16 | 0.0005 | ✓ | 0.4983 | 0.1731 | 14.94 | 0.05 |
| `grc_IDN_c2` | 16 | 0.0005 | ✓ | 0.5430 | 0.1754 | 15.39 | 0.05 |
| `grc_IDN_c3` | 16 | 0.0007 | ✓ | 0.2438 | 0.1250 | 15.46 | 0.05 |
| `grc_IDN_ca` | 16 | 0.0006 | ✓ | 0.5179 | 0.2141 | 14.39 | 0.05 |

**3. Income \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_c1` | 5 | 0.0007 | ✓ | -0.2631 | 0.1986 | 16.67 | 0.27 |
| `grc_TZA_c2` | 5 | 0.0007 | ✓ | -0.2407 | 0.2048 | 16.81 | 0.26 |
| `grc_TZA_c3` | 5 | 0.0007 | ✓ | -0.2490 | 0.2157 | 16.58 | 0.28 |
| `grc_TZA_ca` | 5 | 0.0004 | ✓ | -0.8173 | 0.2048 | 17.65 | 3.05 |

### `14_GrRC_NonAg_experience.log`

**1. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | 0.7856 | 0.3480 | 10.85 | 0.03 |
| `grc_IDN_c2` | 2 | 0.0004 | ✓ | 0.7825 | 0.3465 | 10.85 | 0.03 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | 0.7792 | 0.3453 | 10.85 | 0.03 |
| `grc_IDN_ca` | 2 | 0.0004 | ✓ | 1.4182 | 0.7979 | 10.42 | 0.03 |

**2. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0005 | ✓ | 0.8027 | 0.3585 | 10.82 | 0.04 |
| `grc_IDN_c2` | 2 | 0.0005 | ✓ | 0.8055 | 0.3598 | 10.82 | 0.04 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | 0.7944 | 0.3544 | 10.81 | 0.04 |
| `grc_IDN_ca` | 2 | 0.0005 | ✓ | 2.2039 | 1.4829 | 10.37 | 0.03 |

**3. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0005 | ✓ | 0.7534 | 0.3359 | 10.81 | 0.04 |
| `grc_IDN_c2` | 2 | 0.0005 | ✓ | 0.7467 | 0.3330 | 10.81 | 0.04 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | 0.7649 | 0.3397 | 10.80 | 0.04 |
| `grc_IDN_ca` | 2 | 0.0005 | ✓ | 16.2847 | 50.1672 | 10.27 | 0.03 |

**4. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0005 | ✓ | 0.8073 | 0.3596 | 10.79 | 0.04 |
| `grc_IDN_c2` | 2 | 0.0005 | ✓ | 0.7712 | 0.3450 | 10.79 | 0.04 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | 0.7962 | 0.3536 | 10.78 | 0.04 |
| `grc_IDN_ca` | 2 | 0.0004 | ✓ | 2.5016 | 1.7761 | 10.26 | 0.03 |

### `15_GrRC_birth.log`

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | -0.3019 | 0.0921 | 11.26 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0004 | ✓ | -0.3025 | 0.0918 | 11.27 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3075 | 0.0915 | 11.28 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.5199 | 0.1041 | 10.81 | 0.07 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0014 | ✓ | -0.2124 | 0.0974 | 11.22 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0014 | ✓ | -0.2103 | 0.0982 | 11.21 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0014 | ✓ | -0.2106 | 0.0982 | 11.21 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0014 | ✓ | -0.3188 | 0.1228 | 10.71 | 0.06 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 16 | 0.0006 | ✓ | 0.4847 | 0.1889 | 15.13 | 0.04 |
| `grc_IDN_c2` | 16 | 0.0005 | ✓ | 0.6595 | 0.2222 | 15.28 | 0.04 |
| `grc_IDN_c3` | 16 | 0.0007 | ✓ | 0.1867 | 0.1174 | 15.54 | 0.04 |
| `grc_IDN_ca` | 16 | 0.0006 | ✓ | 0.4319 | 0.1949 | 14.74 | 0.04 |

**4. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_c1` | 2 | 0.0004 | ✓ | -0.3019 | 0.0921 | 11.26 | 0.05 |
| `grc_IDN_c2` | 2 | 0.0004 | ✓ | -0.3025 | 0.0918 | 11.27 | 0.05 |
| `grc_IDN_c3` | 2 | 0.0004 | ✓ | -0.3075 | 0.0915 | 11.28 | 0.05 |
| `grc_IDN_ca` | 2 | 0.0003 | ✓ | -0.5199 | 0.1041 | 10.81 | 0.07 |

### `5_GrRC.log`

**1. Consumption \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_covs_0` | 2 | 0.0009 | ✓ | -0.8975 | 0.0562 | 10.34 | 0.40 |
| `grc_CHN_covs_trend` | 2 | 0.0002 | ✓ | -0.0727 | 0.1344 | 9.77 | 0.05 |
| `grc_CHN_covs_1` | 2 | 0.0002 | ✓ | -0.0728 | 0.1344 | 9.77 | 0.05 |
| `grc_CHN_covs_2` | 2 | 0.0002 | ✓ | -0.1606 | 0.1172 | 10.01 | 0.06 |
| `grc_CHN_covs_all` | 2 | 0.0002 | ✓ | -0.2047 | 0.1336 | 9.51 | 0.05 |

**1. Consumption \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_covs_0` | 2 | 0.0009 | ✓ | -2.4455 | 0.0705 | 11.29 | 0.03 |
| `grc_IDN_covs_trend` | 2 | 0.0004 | ✓ | -0.3095 | 0.0870 | 11.34 | 0.05 |
| `grc_IDN_covs_1` | 2 | 0.0004 | ✓ | -0.3098 | 0.0868 | 11.35 | 0.05 |
| `grc_IDN_covs_2` | 2 | 0.0004 | ✓ | -0.3208 | 0.0862 | 11.36 | 0.05 |
| `grc_IDN_covs_all` | 2 | 0.0003 | ✓ | -0.5256 | 0.1018 | 10.83 | 0.07 |

**1. Consumption \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_covs_0` | 2 | 0.0021 | ✗ | -0.9985 | 0.0644 | 153.33 | 5950.89 |
| `grc_TZA_covs_trend` | 2 | 0.0002 | ✓ | -0.5150 | 0.0911 | 14.91 | 0.14 |
| `grc_TZA_covs_1` | 2 | 0.0002 | ✓ | -0.5227 | 0.0916 | 14.96 | 0.14 |
| `grc_TZA_covs_2` | 2 | 0.0002 | ✓ | -0.5337 | 0.0930 | 15.03 | 0.15 |
| `grc_TZA_covs_all` | 2 | 0.0001 | ✓ | -0.7190 | 0.1243 | 14.94 | 0.47 |

**2. Consumption \| Urban \| Balanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_covs_0` | 2 | 0.0017 | ✓ | -0.8964 | 0.0562 | 10.33 | 0.39 |
| `grc_CHN_covs_trend` | 2 | 0.0003 | ✓ | -0.0992 | 0.1301 | 9.77 | 0.05 |
| `grc_CHN_covs_1` | 2 | 0.0003 | ✓ | -0.0993 | 0.1300 | 9.77 | 0.05 |
| `grc_CHN_covs_2` | 2 | 0.0003 | ✓ | -0.1548 | 0.1190 | 10.04 | 0.06 |
| `grc_CHN_covs_all` | 2 | 0.0003 | ✓ | -0.2293 | 0.1335 | 9.54 | 0.06 |

**2. Consumption \| Urban \| Balanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_covs_0` | 2 | 0.0053 | ✓ | -2.4452 | 0.0705 | 11.29 | 0.03 |
| `grc_IDN_covs_trend` | 2 | 0.0014 | ✓ | -0.2137 | 0.0952 | 11.25 | 0.05 |
| `grc_IDN_covs_1` | 2 | 0.0014 | ✓ | -0.2118 | 0.0959 | 11.24 | 0.05 |
| `grc_IDN_covs_2` | 2 | 0.0014 | ✓ | -0.2122 | 0.0959 | 11.24 | 0.05 |
| `grc_IDN_covs_all` | 2 | 0.0014 | ✓ | -0.3223 | 0.1215 | 10.72 | 0.06 |

**2. Consumption \| Urban \| Balanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_covs_0` | 2 | 0.0027 | ✗ | -0.9985 | 0.0644 | 153.33 | 5950.89 |
| `grc_TZA_covs_trend` | 2 | 0.0003 | ✓ | -0.5008 | 0.0926 | 14.89 | 0.13 |
| `grc_TZA_covs_1` | 2 | 0.0003 | ✓ | -0.5082 | 0.0932 | 14.94 | 0.14 |
| `grc_TZA_covs_2` | 2 | 0.0003 | ✓ | -0.5008 | 0.0965 | 14.98 | 0.14 |
| `grc_TZA_covs_all` | 2 | 0.0001 | ✓ | -0.7097 | 0.1223 | 14.89 | 0.43 |

**3. Income \| Urban \| Unbalanced · CHN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_covs_0` | 2 | 0.0002 | ✓ | -0.7002 | 0.1829 | 9.05 | 0.31 |
| `grc_CHN_covs_trend` | 2 | 0.0002 | ✗ | -0.9993 | 0.2246 | 84.60 | 2.28e+04 |
| `grc_CHN_covs_1` | 2 | 0.0003 | ✗ | -0.9989 | 0.2344 | 75.92 | 1.39e+04 |
| `grc_CHN_covs_2` | 2 | 6.49e-05 | ✓ | -1.6012 | 0.2584 | 9.88 | 0.21 |
| `grc_CHN_covs_all` | 2 | 8.05e-05 | ✓ | -0.9833 | 0.2046 | 9.94 | 9.88 |

**3. Income \| Urban \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_covs_0` | 16 | 0.0006 | ✓ | -0.0455 | 0.0744 | 15.30 | 0.04 |
| `grc_IDN_covs_trend` | 16 | 0.0005 | ✓ | 0.4506 | 0.1644 | 15.24 | 0.04 |
| `grc_IDN_covs_1` | 16 | 0.0005 | ✓ | 0.5431 | 0.1754 | 15.39 | 0.04 |
| `grc_IDN_covs_2` | 16 | 0.0007 | ✓ | 0.2224 | 0.1194 | 15.64 | 0.04 |
| `grc_IDN_covs_all` | 16 | 0.0006 | ✓ | 0.4470 | 0.1967 | 14.76 | 0.04 |

**3. Income \| Urban \| Unbalanced · TZA**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_TZA_covs_0` | 5 | 0.0009 | ✓ | 1.4804 | 1.0126 | 14.49 | 0.14 |
| `grc_TZA_covs_trend` | 5 | 0.0006 | ✓ | -0.2576 | 0.1726 | 15.18 | 0.24 |
| `grc_TZA_covs_1` | 5 | 0.0006 | ✓ | -0.2392 | 0.1770 | 15.32 | 0.24 |
| `grc_TZA_covs_2` | 5 | 0.0006 | ✓ | -0.2503 | 0.1820 | 15.09 | 0.25 |
| `grc_TZA_covs_all` | 5 | 0.0004 | ✓ | -0.5576 | 0.1630 | 14.43 | 0.50 |

### `6_GrRC_NonAg.log`

**1. Consumption \| Nonag \| Unbalanced · IDN**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_IDN_covs_0` | 2 | 0.0009 | ✓ | -2.2254 | 0.1011 | 11.09 | 0.04 |
| `grc_IDN_covs_trend` | 2 | 0.0005 | ✓ | 0.7954 | 0.3574 | 10.93 | 0.03 |
| `grc_IDN_covs_1` | 2 | 0.0005 | ✓ | 0.8095 | 0.3637 | 10.93 | 0.03 |
| `grc_IDN_covs_2` | 2 | 0.0004 | ✓ | 0.8046 | 0.3599 | 10.90 | 0.04 |
| `grc_IDN_covs_all` | 2 | 0.0004 | ✓ | 8.6897 | 15.4021 | 10.44 | 0.03 |

### `8_GrRC_hukou.log`

**1. Consumption \| Urban \| Unbalanced · CHN_hukou_rural_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_first_c0` | 2 | 0.0012 | ✗ | -1.0002 | 0.0770 | 149.72 | 4.60e+04 |
| `grc_CHN_hukou_rural_first_ct` | 2 | 0.0001 | ✓ | 0.1301 | 0.1929 | 9.50 | 0.02 |
| `grc_CHN_hukou_rural_first_c1` | 2 | 0.0001 | ✓ | 0.1285 | 0.1929 | 9.49 | 0.02 |
| `grc_CHN_hukou_rural_first_c2` | 2 | 0.0002 | ✓ | -0.0386 | 0.1513 | 9.76 | 0.03 |
| `grc_CHN_hukou_rural_first_ca` | 2 | 0.0002 | ✓ | -0.0392 | 0.1531 | 9.48 | 0.03 |

**1. Consumption \| Urban \| Unbalanced · CHN_hukou_rural_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_only_c0` | 2 | 0.0015 | ✗ | -1.0003 | 0.0820 | 150.60 | 4.50e+04 |
| `grc_CHN_hukou_rural_only_ct` | 2 | 0.0001 | ✓ | 0.0893 | 0.1759 | 9.46 | 0.02 |
| `grc_CHN_hukou_rural_only_c1` | 2 | 0.0001 | ✓ | 0.0875 | 0.1755 | 9.45 | 0.02 |
| `grc_CHN_hukou_rural_only_c2` | 2 | 0.0001 | ✓ | -0.0211 | 0.1512 | 9.72 | 0.03 |
| `grc_CHN_hukou_rural_only_ca` | 2 | 0.0001 | ✓ | -0.0327 | 0.1520 | 9.46 | 0.03 |

**1. Consumption \| Urban \| Unbalanced · CHN_hukou_urban_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_first_c0` | 4 | 0.0001 | ✓ | -1.3240 | 0.1653 | 10.26 | 0.20 |
| `grc_CHN_hukou_urban_first_ct` | 4 | 0.0003 | ✓ | -0.8060 | 0.1620 | 10.50 | 0.62 |
| `grc_CHN_hukou_urban_first_c1` | 4 | 0.0003 | ✓ | -0.8064 | 0.1624 | 10.49 | 0.62 |
| `grc_CHN_hukou_urban_first_c2` | 4 | 0.0003 | ✓ | -0.8318 | 0.1599 | 10.83 | 0.95 |
| `grc_CHN_hukou_urban_first_ca` | 4 | 0.0002 | ✓ | -0.9592 | 0.1653 | 13.55 | 17.48 |

**1. Consumption \| Urban \| Unbalanced · CHN_hukou_urban_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_only_c0` | 4 | 9.99e-05 | ✓ | -1.2760 | 0.1375 | 10.30 | 0.22 |
| `grc_CHN_hukou_urban_only_ct` | 4 | 0.0003 | ✓ | -0.7984 | 0.1576 | 10.48 | 0.55 |
| `grc_CHN_hukou_urban_only_c1` | 4 | 0.0003 | ✓ | -0.7982 | 0.1577 | 10.46 | 0.55 |
| `grc_CHN_hukou_urban_only_c2` | 4 | 0.0003 | ✓ | -0.8194 | 0.1546 | 10.76 | 0.79 |
| `grc_CHN_hukou_urban_only_ca` | 4 | 0.0002 | ✓ | -0.9876 | 0.1764 | 23.51 | 203.61 |

**2. Consumption \| Urban \| Balanced · CHN_hukou_rural_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_first_c0` | 2 | 0.0023 | ✗ | -1.0002 | 0.0770 | 149.72 | 4.60e+04 |
| `grc_CHN_hukou_rural_first_ct` | 2 | 0.0003 | ✓ | 0.0247 | 0.1686 | 9.51 | 0.02 |
| `grc_CHN_hukou_rural_first_c1` | 2 | 0.0003 | ✓ | 0.0227 | 0.1685 | 9.50 | 0.03 |
| `grc_CHN_hukou_rural_first_c2` | 2 | 0.0003 | ✓ | -0.0677 | 0.1431 | 9.81 | 0.03 |
| `grc_CHN_hukou_rural_first_ca` | 2 | 0.0003 | ✓ | -0.0753 | 0.1442 | 9.51 | 0.03 |

**2. Consumption \| Urban \| Balanced · CHN_hukou_rural_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_only_c0` | 2 | 0.0028 | ✗ | -1.0003 | 0.0820 | 150.60 | 4.50e+04 |
| `grc_CHN_hukou_rural_only_ct` | 2 | 0.0003 | ✓ | 0.0436 | 0.1649 | 9.47 | 0.03 |
| `grc_CHN_hukou_rural_only_c1` | 2 | 0.0003 | ✓ | 0.0414 | 0.1645 | 9.45 | 0.03 |
| `grc_CHN_hukou_rural_only_c2` | 2 | 0.0003 | ✓ | -0.0357 | 0.1490 | 9.77 | 0.03 |
| `grc_CHN_hukou_rural_only_ca` | 2 | 0.0003 | ✓ | -0.0407 | 0.1506 | 9.49 | 0.03 |

**2. Consumption \| Urban \| Balanced · CHN_hukou_urban_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_first_c0` | 4 | 0.0003 | ✓ | -1.3240 | 0.1653 | 10.26 | 0.20 |
| `grc_CHN_hukou_urban_first_ct` | 4 | 0.0006 | ✓ | -0.7997 | 0.1650 | 10.46 | 0.59 |
| `grc_CHN_hukou_urban_first_c1` | 4 | 0.0006 | ✓ | -0.7980 | 0.1646 | 10.44 | 0.57 |
| `grc_CHN_hukou_urban_first_c2` | 4 | 0.0006 | ✓ | -0.8076 | 0.1594 | 10.70 | 0.74 |
| `grc_CHN_hukou_urban_first_ca` | 4 | 0.0004 | ✓ | -0.9822 | 0.1661 | 19.41 | 95.08 |

**2. Consumption \| Urban \| Balanced · CHN_hukou_urban_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_only_c0` | 4 | 0.0002 | ✓ | -1.2760 | 0.1375 | 10.30 | 0.22 |
| `grc_CHN_hukou_urban_only_ct` | 4 | 0.0006 | ✓ | -0.7886 | 0.1584 | 10.43 | 0.51 |
| `grc_CHN_hukou_urban_only_c1` | 4 | 0.0006 | ✓ | -0.7900 | 0.1591 | 10.41 | 0.51 |
| `grc_CHN_hukou_urban_only_c2` | 4 | 0.0005 | ✓ | -0.7999 | 0.1552 | 10.65 | 0.65 |
| `grc_CHN_hukou_urban_only_ca` | 4 | 0.0004 | ✓ | -0.9634 | 0.1720 | 14.14 | 23.09 |

**3. Income \| Urban \| Unbalanced · CHN_hukou_rural_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_first_c0` | 2 | 0.0004 | ✗ | -1.0008 | 0.3471 | 136.74 | 5.28e+04 |
| `grc_CHN_hukou_rural_first_ct` | 2 | 4.61e-05 | ✓ | -1.9636 | 0.2408 | 9.00 | 0.16 |
| `grc_CHN_hukou_rural_first_c1` | 2 | 5.58e-05 | ✓ | -2.6112 | 0.2245 | 9.28 | 0.11 |
| `grc_CHN_hukou_rural_first_c2` | 2 | 0.0001 | ✓ | -1.6720 | 0.4298 | 10.18 | 0.25 |
| `grc_CHN_hukou_rural_first_ca` | 2 | 7.45e-05 | ✓ | -1.6868 | 0.3381 | 9.63 | 0.23 |

**3. Income \| Urban \| Unbalanced · CHN_hukou_rural_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_rural_only_c0` | 2 | 0.0004 | ✗ | -1.0001 | 0.3482 | 162.74 | 8.36e+05 |
| `grc_CHN_hukou_rural_only_ct` | 2 | 0.0005 | ✗ | -1.0000 | 0.2890 | 315.06 | 4.48e+06 |
| `grc_CHN_hukou_rural_only_c1` | 2 | 0.0007 | ✗ | -1.0000 | 0.4187 | 216.87 | 4.22e+06 |
| `grc_CHN_hukou_rural_only_c2` | 2 | 9.19e-05 | ✓ | -2.5156 | 0.8296 | 10.32 | 0.14 |
| `grc_CHN_hukou_rural_only_ca` | 2 | 9.22e-05 | ✓ | -1.6839 | 0.3625 | 9.79 | 0.25 |

**3. Income \| Urban \| Unbalanced · CHN_hukou_urban_first**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_first_c0` | 2 | 6.58e-05 | ✓ | -0.9010 | 0.6225 | 10.23 | 3.05 |
| `grc_CHN_hukou_urban_first_ct` | 2 | 2.93e-05 | ✓ | 1.1630 | 1.1496 | 9.87 | 0.12 |
| `grc_CHN_hukou_urban_first_c1` | 2 | 4.16e-05 | ✓ | 1.3848 | 1.4588 | 10.08 | 0.12 |
| `grc_CHN_hukou_urban_first_c2` | 2 | 4.57e-06 | ✓ | 0.8993 | 0.9329 | 10.44 | 0.12 |
| `grc_CHN_hukou_urban_first_ca` | 2 | 0.0002 | ✗ | -1.0000 | 0.0004 | — | — |

**3. Income \| Urban \| Unbalanced · CHN_hukou_urban_only**

| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |
|---|---:|---:|:---:|---:|---:|---:|---:|
| `grc_CHN_hukou_urban_only_c0` | 2 | 2.62e-31 | ✓ | -0.2001 | 0.6687 | 10.02 | 0.25 |
| `grc_CHN_hukou_urban_only_ct` | 2 | 3.48e-14 | ✓ | 1.3396 | 1.1974 | 10.02 | 0.12 |
| `grc_CHN_hukou_urban_only_c1` | 2 | 1.37e-28 | ✓ | 2.9365 | 3.2244 | 10.18 | 0.11 |
| `grc_CHN_hukou_urban_only_c2` | 2 | 2.45e-20 | ✓ | 1.0216 | 1.1147 | 10.54 | 0.11 |
| `grc_CHN_hukou_urban_only_ca` | 2 | 6.33e-14 | ✓ | 2.4739 | 2.3159 | 9.61 | 0.10 |
