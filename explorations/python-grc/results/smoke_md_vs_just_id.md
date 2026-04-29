# MD vs just-identified phi inversion: IDN smoke

Both procedures test the same LCA null at chi^2_{|S|-1} dof.
MD differs by concentrating out a free LCA intercept beta
across all switchers via GLS, instead of pinning beta to the
base switcher's OLS coefficient.

## Per-spec comparison

| Spec | JI phi_min | JI 95% CI | width | MD phi_min | MD 95% CI | width | beta_OLS | beta_MD | beta_GMM | beta_OLS-GMM | beta_MD-GMM |
|---|---:|---|---:|---:|---|---:|---:|---:|---:|---:|---:|
| covs_0 | -2.310 | empty | nan | -2.310 | empty | nan | +0.9070 | +0.8436 | +0.8483 | +0.0587 | -0.0048 |
| covs_trend | -0.370 | [-0.640, -0.070] | 0.570 | -0.370 | [-0.640, -0.070] | 0.570 | +0.1062 | +0.0787 | +0.0742 | +0.0320 | +0.0044 |
| covs_1 | -0.370 | [-0.640, -0.070] | 0.570 | -0.370 | [-0.640, -0.070] | 0.570 | +0.1065 | +0.0790 | +0.0746 | +0.0319 | +0.0044 |
| covs_2 | -0.380 | [-0.630, -0.110] | 0.520 | -0.380 | [-0.630, -0.110] | 0.520 | +0.1149 | +0.0840 | +0.0798 | +0.0351 | +0.0042 |
| covs_all | -0.600 | [-1.230, -0.010] | 1.220 | -0.600 | [-1.230, -0.010] | 1.220 | +0.0948 | +0.0694 | +0.0672 | +0.0276 | +0.0021 |
