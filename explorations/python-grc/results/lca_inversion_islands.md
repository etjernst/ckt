# LCA inversion: island detection and curve diagnostics
Post-processing of the (phi, p_value) grid curves saved by `run_all_countries_inversion.py`. Companion to `lca_inversion_three_countries.md` (CI comparison).

Single-island results are the same convex hull as the comparison md. Multimodal results would mean disconnected non-rejected regions of the phi grid; reporting only the min/max would overstate CI coverage. Empty CIs are reported with the max p-value attained on the grid, which says how close the model comes to acceptance for the best-fitting phi.

**Grid:** `phi in [-3, 1]` step 0.01 (401 points). **Levels:** 95% (alpha=0.05), 90% (alpha=0.10).

## Curve diagnostics and island counts

| Country | Spec | max p (phi) | min Wald (phi) | Islands @ 95% | Islands @ 90% |
|---|---|---|---|---|---|
| IDN | covs_0 | 0.0000 (phi=-2.330) | 123.62 (phi=-2.310) | 0: empty | 0: empty |
| IDN | covs_trend | 0.1651 (phi=-0.370) | 32.90 (phi=-0.370) | 1: [-0.640, -0.070] | 1: [-0.540, -0.190] |
| IDN | covs_1 | 0.1672 (phi=-0.370) | 32.83 (phi=-0.370) | 1: [-0.640, -0.070] | 1: [-0.540, -0.180] |
| IDN | covs_2 | 0.1395 (phi=-0.380) | 33.83 (phi=-0.380) | 1: [-0.630, -0.110] | 1: [-0.520, -0.240] |
| IDN | covs_all | 0.4360 (phi=-0.600) | 26.50 (phi=-0.600) | 1: [-1.230, -0.010] | 1: [-1.090, -0.140] |
| CHN | covs_0 | 0.0000 (phi=-3.000) | 120.09 (phi=-1.040) | 0: empty | 0: empty |
| CHN | covs_trend | 0.0089 (phi=-0.240) | 22.01 (phi=-0.240) | 0: empty | 0: empty |
| CHN | covs_1 | 0.0089 (phi=-0.240) | 22.01 (phi=-0.240) | 0: empty | 0: empty |
| CHN | covs_2 | 0.0088 (phi=-0.280) | 22.02 (phi=-0.280) | 0: empty | 0: empty |
| CHN | covs_all | 0.0170 (phi=-0.330) | 20.16 (phi=-0.330) | 0: empty | 0: empty |
| TZA | covs_0 | 0.0148 (phi=-1.300) | 12.37 (phi=-1.300) | 0: empty | 0: empty |
| TZA | covs_trend | 0.1213 (phi=-0.550) | 7.29 (phi=-0.550) | 1: [-0.700, -0.410] | 1: [-0.610, -0.490] |
| TZA | covs_1 | 0.1299 (phi=-0.560) | 7.11 (phi=-0.560) | 1: [-0.710, -0.410] | 1: [-0.630, -0.480] |
| TZA | covs_2 | 0.1206 (phi=-0.570) | 7.31 (phi=-0.570) | 1: [-0.720, -0.430] | 1: [-0.640, -0.510] |
| TZA | covs_all | 0.4034 (phi=-0.730) | 4.02 (phi=-0.730) | 1: [-1.220, -0.450] | 1: [-1.100, -0.500] |

## Findings

**No multimodality.** Every non-empty CI in the grid is a single connected region of non-rejection, so the convex-hull CIs in `lca_inversion_three_countries.md` are not hiding disconnected islands. The reported `[min, max]` endpoints fully describe each country/spec's accepted phi region.

**CHN's empty CIs are not borderline.** Across all five specs, the highest p-value attained on the `[-3, 1]` grid is 0.0170 (at covs_all). Even at the best-fitting phi, the joint Wald statistic for the LCA restriction is rejected at the 5% level. Pooled-sample LCA is incompatible with the CHN data for *every* phi value in the grid, not just the GMM point estimate. Hukou splits are necessary, not optional.

