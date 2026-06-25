# E2 hukou bound: base-robustness check

Date: 2026-06-25
Purpose: confirm the rural-hukou never-migrant return $\Delta_{d_N}^{rh}$, and
hence the E2 consumption-gain lower bound, does not move with the base
trajectory chosen for the inversion. This addresses the base-dependence concern
raised in the round-2 plan review (the paper defers a full base-range report to
the Version 2 resorting magnitude; for Version 1 we verify stability here).

## Method

Recompute the $\Delta_{d_N}^{rh}$ 95% test-inversion CI
(`lca_inversion.grid_delta_never_md_inversion`, the same routine that produces
the ster-attached `inv_dN` CI) for the CHN rural-hukou-first cell under every
kept switcher trajectory as the base, holding the auxiliary OLS fit, grids
(phi in [-3, 1] step 0.01; delta in [-1.5, 1.5] step 0.01), and the
never-migrant trajectory fixed. Scale each CI by the constant
$\pi^{rh}\cdot\pi_{d_N}^{rh} = 0.2010$ to get the bound.

## Result

Kept switchers (candidate bases): 2, 3, 4, 5, 8, 9, 10, 11, 12, 13.

| base | $\Delta_{d_N}^{rh}$ CI (log) | bound (geom.\ mean %) |
|------|------------------------------|-----------------------|
| all 10 | [0.090, 0.130] | [+1.83%, +2.65%] |

The $\Delta_{d_N}^{rh}$ inversion CI is identical to the grid resolution
([0.090, 0.130]) for every base, so the bound is [+1.83%, +2.65%] regardless of
base. The minimum-distance inversion for $\Delta_{d_N}$ profiles $\phi$ out and
the base enters only through the moment construction, which does not move the
accepted $\Delta_{d_N}$ set in this cell.

## Conclusion

Base-dependence is non-binding for the Version 1 bound. The paper's
"conditional on the estimated rural-hukou base trajectory" caveat is honest but
practically slack here. No change to the reported numbers.
