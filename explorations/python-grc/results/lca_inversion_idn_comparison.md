# IDN/cons/urban/unb: GMM vs LCA inversion

GMM source: `rerun_workdir/idn_fresh_phi.csv (fresh)`

## 95% confidence intervals

| Spec | GMM $\hat\phi$ (SE) | GMM 95% CI (sandwich) | Inversion 95% CI (LCA) | Width ratio (inv/sand) |
|---|---:|---|---|---:|
| covs_0 | -2.445 (0.070) | [-2.584, -2.307] | empty | --- |
| covs_trend | -0.309 (0.087) | [-0.480, -0.139] | [-0.640, -0.070] | 1.67 |
| covs_1 | -0.310 (0.087) | [-0.480, -0.140] | [-0.640, -0.070] | 1.68 |
| covs_2 | -0.321 (0.086) | [-0.490, -0.152] | [-0.630, -0.110] | 1.54 |
| covs_all | -0.526 (0.102) | [-0.725, -0.326] | [-1.230, -0.010] | 3.06 |

## 90% confidence intervals

| Spec | GMM $\hat\phi$ (SE) | GMM 90% CI (sandwich) | Inversion 90% CI (LCA) | Width ratio (inv/sand) |
|---|---:|---|---|---:|
| covs_0 | -2.445 (0.070) | [-2.561, -2.330] | empty | --- |
| covs_trend | -0.309 (0.087) | [-0.453, -0.166] | [-0.540, -0.190] | 1.22 |
| covs_1 | -0.310 (0.087) | [-0.453, -0.167] | [-0.540, -0.180] | 1.26 |
| covs_2 | -0.321 (0.086) | [-0.463, -0.179] | [-0.520, -0.240] | 0.99 |
| covs_all | -0.526 (0.102) | [-0.693, -0.358] | [-1.090, -0.140] | 2.84 |
