# Trajectory-specific Delta inversion CIs

**Spec:** consumption / urban / unbalanced.
**Inversion source:** `lca_inversion.py` MD inversions (`grid_delta_never_md_inversion`, `grid_delta_avg_md_inversion`, `grid_delta_always_md_inversion`) profiling phi over `[-3, 1]` step 0.01.

**Stata source:** `rerun_workdir/published_deltas.csv`, regenerated 2026-04-30 with the corrected within-switcher Delta_avg formula.

**Grid:** Delta_never / Delta_avg use a `[-1.5, +1.5]` step 0.01 grid; Delta_always uses `[-5, +5]` step 0.02 to absorb the Mobius singularity at phi = -1. CI endpoints annotated as `-inf` / `+inf` indicate the inversion CI extends beyond the grid (CI is unbounded; widen the grid or treat as not-rejected over the half-line).

**Islands:** number of disjoint intervals in the inversion CI, from `find_islands`. >= 2 indicates the curve crosses rejection on both sides of a non-monotone region (typically the Mobius singularity for Delta_always).

## Delta_never (return for never-movers)

| Country | Spec | Stata point (SE) | Stata 95% CI | MD inversion 95% CI | Islands | Grid |
|---|---|---:|---|---|---:|---|
| IDN | covs_0 | +0.304 (0.054) | [+0.199, +0.410] | empty | 0 | [-1.5, +1.5] |
| IDN | covs_trend | +0.086 (0.021) | [+0.045, +0.127] | [+0.040, +0.150] | 1 | [-1.5, +1.5] |
| IDN | covs_1 | +0.086 (0.021) | [+0.046, +0.127] | [+0.040, +0.150] | 1 | [-1.5, +1.5] |
| IDN | covs_2 | +0.091 (0.021) | [+0.051, +0.132] | [+0.050, +0.150] | 1 | [-1.5, +1.5] |
| IDN | covs_all | +0.071 (0.018) | [+0.037, +0.106] | [+0.010, +0.150] | 1 | [-1.5, +1.5] |
| CHN | covs_0 | +0.424 (0.021) | [+0.383, +0.465] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_trend | +0.090 (0.028) | [+0.035, +0.145] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_1 | +0.090 (0.028) | [+0.035, +0.145] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_2 | +0.104 (0.023) | [+0.059, +0.149] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_all | +0.098 (0.021) | [+0.057, +0.138] | empty | 0 | [-1.5, +1.5] |
| TZA | covs_0 | +0.539 (0.036) | [+0.469, +0.609] | empty | 0 | [-1.5, +1.5] |
| TZA | covs_trend | +0.301 (0.039) | [+0.224, +0.378] | [+0.260, +0.380] | 1 | [-1.5, +1.5] |
| TZA | covs_1 | +0.304 (0.039) | [+0.227, +0.381] | [+0.260, +0.380] | 1 | [-1.5, +1.5] |
| TZA | covs_2 | +0.301 (0.039) | [+0.225, +0.377] | [+0.260, +0.370] | 1 | [-1.5, +1.5] |
| TZA | covs_all | +0.270 (0.033) | [+0.204, +0.335] | [+0.200, +0.390] | 1 | [-1.5, +1.5] |

## Delta_avg (within-switcher average return)

| Country | Spec | Stata point (SE) | Stata 95% CI | MD inversion 95% CI | Islands | Grid |
|---|---|---:|---|---|---:|---|
| IDN | covs_0 | +0.381 (0.023) | [+0.335, +0.427] | empty | 0 | [-1.5, +1.5] |
| IDN | covs_trend | +0.041 (0.016) | [+0.009, +0.072] | [+0.000, +0.070] | 1 | [-1.5, +1.5] |
| IDN | covs_1 | +0.041 (0.016) | [+0.009, +0.073] | [+0.000, +0.070] | 1 | [-1.5, +1.5] |
| IDN | covs_2 | +0.045 (0.016) | [+0.013, +0.077] | [+0.010, +0.070] | 1 | [-1.5, +1.5] |
| IDN | covs_all | +0.038 (0.016) | [+0.006, +0.069] | [-0.020, +0.090] | 1 | [-1.5, +1.5] |
| CHN | covs_0 | +0.472 (0.021) | [+0.430, +0.513] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_trend | +0.081 (0.021) | [+0.040, +0.122] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_1 | +0.081 (0.021) | [+0.040, +0.122] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_2 | +0.091 (0.021) | [+0.050, +0.132] | empty | 0 | [-1.5, +1.5] |
| CHN | covs_all | +0.090 (0.021) | [+0.049, +0.131] | empty | 0 | [-1.5, +1.5] |
| TZA | covs_0 | +0.085 (0.015) | [+0.056, +0.114] | empty | 0 | [-1.5, +1.5] |
| TZA | covs_trend | +0.102 (0.014) | [+0.074, +0.131] | [+0.090, +0.120] | 1 | [-1.5, +1.5] |
| TZA | covs_1 | +0.102 (0.014) | [+0.074, +0.131] | [+0.080, +0.120] | 1 | [-1.5, +1.5] |
| TZA | covs_2 | +0.103 (0.014) | [+0.074, +0.131] | [+0.090, +0.120] | 1 | [-1.5, +1.5] |
| TZA | covs_all | +0.106 (0.014) | [+0.077, +0.134] | [+0.080, +0.130] | 1 | [-1.5, +1.5] |

## Delta_always (return for always-movers)

| Country | Spec | Stata point (SE) | Stata 95% CI | MD inversion 95% CI | Islands | Grid |
|---|---|---:|---|---|---:|---|
| IDN | covs_0 | +0.460 (0.041) | [+0.379, +0.541] | empty | 0 | [-5.0, +5.0] |
| IDN | covs_trend | -0.053 (0.042) | [-0.136, +0.030] | [-0.320, +0.020] | 1 | [-5.0, +5.0] |
| IDN | covs_1 | -0.053 (0.042) | [-0.136, +0.030] | [-0.320, +0.020] | 1 | [-5.0, +5.0] |
| IDN | covs_2 | -0.053 (0.043) | [-0.137, +0.032] | [-0.300, +0.020] | 1 | [-5.0, +5.0] |
| IDN | covs_all | -0.096 (0.061) | [-0.217, +0.024] | [-inf, +0.040] U [+0.660, +inf] | 2 | [-5.0, +5.0] |
| CHN | covs_0 | -0.109 (0.398) | [-0.889, +0.672] | empty | 0 | [-5.0, +5.0] |
| CHN | covs_trend | +0.059 (0.046) | [-0.031, +0.149] | empty | 0 | [-5.0, +5.0] |
| CHN | covs_1 | +0.059 (0.046) | [-0.031, +0.149] | empty | 0 | [-5.0, +5.0] |
| CHN | covs_2 | +0.032 (0.054) | [-0.073, +0.137] | empty | 0 | [-5.0, +5.0] |
| CHN | covs_all | +0.033 (0.050) | [-0.065, +0.131] | empty | 0 | [-5.0, +5.0] |
| TZA | covs_0 | -138.579 (5950.886) | [-11802.315, +11525.158] | empty | 0 | [-5.0, +5.0] |
| TZA | covs_trend | -0.262 (0.133) | [-0.522, -0.002] | [-0.680, -0.140] | 1 | [-5.0, +5.0] |
| TZA | covs_1 | -0.273 (0.138) | [-0.543, -0.003] | [-0.740, -0.140] | 1 | [-5.0, +5.0] |
| TZA | covs_2 | -0.289 (0.146) | [-0.575, -0.002] | [-0.780, -0.160] | 1 | [-5.0, +5.0] |
| TZA | covs_all | -0.662 (0.469) | [-1.582, +0.257] | [-inf, -0.140] U [+1.720, +inf] | 2 | [-5.0, +5.0] |
