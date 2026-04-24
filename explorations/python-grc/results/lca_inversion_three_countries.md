# LCA inversion CI vs GMM sandwich CI

**Spec:** consumption / urban / unbalanced

**GMM source:** fresh local Stata reruns of 5_GrRC.do (`rerun_workdir/idn_fresh_phi.csv` for IDN, `rerun_workdir/chn_tza_fresh_phi.csv` for CHN/TZA). Cross-checked against the published `output/tables/GRC_{country}_consumption_urban_unb.tex` --- match to 3-4 decimals.

**Inversion source:** `lca_inversion.py` on the same data, Python statsmodels OLS with cluster-robust SE at pid, grid `[-3, 1]` step 0.01, `drop_sparse_switchers` threshold 5.

**(J rejects)** flag indicates Stata GMM Hansen J p-value < 0.05 (model rejected by overid; e.g., CHN pooled sample needs hukou splits).

## 95% confidence intervals

| Country | Spec | GMM $\hat\phi$ (SE) | GMM 95% CI (sandwich) | Inversion 95% CI (LCA) | Width ratio (inv/sand) |
|---|---|---:|---|---|---:|
| IDN | covs_0 | -2.445 (0.070) (J rejects) | [-2.584, -2.307] | empty | --- |
| IDN | covs_trend | -0.309 (0.087) | [-0.480, -0.139] | [-0.640, -0.070] | 1.67 |
| IDN | covs_1 | -0.310 (0.087) | [-0.480, -0.140] | [-0.640, -0.070] | 1.68 |
| IDN | covs_2 | -0.321 (0.086) | [-0.490, -0.152] | [-0.630, -0.110] | 1.54 |
| IDN | covs_all | -0.526 (0.102) | [-0.725, -0.326] | [-1.230, -0.010] | 3.06 |
| CHN | covs_0 | -0.898 (0.056) (J rejects) | [-1.008, -0.787] | empty | --- |
| CHN | covs_trend | -0.073 (0.134) (J rejects) | [-0.336, 0.191] | empty | --- |
| CHN | covs_1 | -0.073 (0.134) (J rejects) | [-0.336, 0.191] | empty | --- |
| CHN | covs_2 | -0.161 (0.117) (J rejects) | [-0.390, 0.069] | empty | --- |
| CHN | covs_all | -0.205 (0.134) (J rejects) | [-0.467, 0.057] | empty | --- |
| TZA | covs_0 | -0.998 (0.064) (J rejects) | [-1.125, -0.872] | empty | --- |
| TZA | covs_trend | -0.515 (0.091) | [-0.694, -0.336] | [-0.700, -0.410] | 0.81 |
| TZA | covs_1 | -0.523 (0.092) | [-0.702, -0.343] | [-0.710, -0.410] | 0.84 |
| TZA | covs_2 | -0.534 (0.093) | [-0.716, -0.352] | [-0.720, -0.430] | 0.80 |
| TZA | covs_all | -0.719 (0.124) | [-0.963, -0.475] | [-1.220, -0.450] | 1.58 |

## 90% confidence intervals

| Country | Spec | GMM $\hat\phi$ (SE) | GMM 90% CI (sandwich) | Inversion 90% CI (LCA) | Width ratio (inv/sand) |
|---|---|---:|---|---|---:|
| IDN | covs_0 | -2.445 (0.070) (J rejects) | [-2.561, -2.330] | empty | --- |
| IDN | covs_trend | -0.309 (0.087) | [-0.453, -0.166] | [-0.540, -0.190] | 1.22 |
| IDN | covs_1 | -0.310 (0.087) | [-0.453, -0.167] | [-0.540, -0.180] | 1.26 |
| IDN | covs_2 | -0.321 (0.086) | [-0.463, -0.179] | [-0.520, -0.240] | 0.99 |
| IDN | covs_all | -0.526 (0.102) | [-0.693, -0.358] | [-1.090, -0.140] | 2.84 |
| CHN | covs_0 | -0.898 (0.056) (J rejects) | [-0.990, -0.805] | empty | --- |
| CHN | covs_trend | -0.073 (0.134) (J rejects) | [-0.294, 0.148] | empty | --- |
| CHN | covs_1 | -0.073 (0.134) (J rejects) | [-0.294, 0.148] | empty | --- |
| CHN | covs_2 | -0.161 (0.117) (J rejects) | [-0.353, 0.032] | empty | --- |
| CHN | covs_all | -0.205 (0.134) (J rejects) | [-0.424, 0.015] | empty | --- |
| TZA | covs_0 | -0.998 (0.064) (J rejects) | [-1.104, -0.893] | empty | --- |
| TZA | covs_trend | -0.515 (0.091) | [-0.665, -0.365] | [-0.610, -0.490] | 0.40 |
| TZA | covs_1 | -0.523 (0.092) | [-0.673, -0.372] | [-0.630, -0.480] | 0.50 |
| TZA | covs_2 | -0.534 (0.093) | [-0.687, -0.381] | [-0.640, -0.510] | 0.43 |
| TZA | covs_all | -0.719 (0.124) | [-0.923, -0.515] | [-1.100, -0.500] | 1.47 |
