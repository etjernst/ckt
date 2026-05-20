# CHN hukou-split inversion CIs: RF and UF

**Date:** 2026-05-20.
**Branch:** lca-inversion.
**Files:**

- New Stata driver: [RP7/scripts/5c_inversion_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5c_inversion_hukou.do)
- Wrapper: [RP7/scripts/_run_5c_for_attach.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_run_5c_for_attach.do)
- Updated sters: `RP7/output/grc_CHN_rf_cuu_ca{,_n,_g,_a}.ster`, `RP7/output/grc_CHN_uf_cuu_ca{,_n,_g,_a}.ster`
- Log: [RP7/scripts/logs/5c_inversion_hukou.log](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/logs/5c_inversion_hukou.log)

## Why

`5b_inversion.do` handles only the pooled IDN/TZA/CHN cells.
The pooled CHN parent ster's $J$-test rejects on `cuu_ca`, so its inversion CIs are empty by construction and CHN cannot enter the E1 counterfactual through the pooled route.
The plan is to route CHN through the hukou-split sters, which pass the $J$-test within regime.
This required a parallel inversion-attach driver for the hukou subsamples.

## What 5c does

`5c_inversion_hukou.do` mirrors `5b_inversion.do` but loops over the hukou subsamples instead of pooled countries.
The `country -> country_short` mapping follows `7_GrRC_hukou.do`: `CHN_hukou_rural_first -> CHN_rf`, `CHN_hukou_urban_first -> CHN_uf`, with the corresponding pattern for `_rural_only -> CHN_ro` and `_urban_only -> CHN_uo` left in the script (for the deferred RO/UO pass).
Outcome, controls, and sample selection mirror `5b_inversion.do` to keep the auxiliary OLS aligned with the GMM specification.
The `attach_inversion_ci` program is subsample-agnostic---it reads the data from memory via SFI, so passing in the hukou subsample requires no changes to the underlying inversion machinery.

The c0, ct, c1, and c2 sters skip because only the `_ca` (column 5) parent sters live in this worktree.
That is fine for the counterfactual pipeline, which targets column 5 as the headline.

## Results

### CHN-RF (rural-hukou-first) cuu_ca

| object | point | 95% CI |
|---|---:|---|
| $\phi$ | $-0.16$ | $[-0.300, +0.010]$ |
| $\Delta_{d_N}$ | $+0.11$ | $[+0.090, +0.130]$ |
| $\Delta_{\text{avg}}$ | $+0.11$ | $[+0.090, +0.130]$ |
| $\Delta_{d_T}$ | $+0.08$ | $[+0.060, +0.100]$ |

$J_R = 9$, $K = 10$ kept switchers.
All four CIs are single-island.
Pattern matches what the paper text claims for the rural-hukou regime: a flat LCA slope ($\phi$ close to zero, weak comparative-advantage gradient) with substantial positive returns for never-migrants ($\Delta_{d_N} = +0.11$), consistent with suppressed sorting---workers who would gain are not moving.

### CHN-UF (urban-hukou-first) cuu_ca

| object | point | 95% CI |
|---|---:|---|
| $\phi$ | $-3.00$ | $[-\infty, -0.770]$ |
| $\Delta_{d_N}$ | $-0.23$ | $[-0.560, +0.110]$ |
| $\Delta_{\text{avg}}$ | $+0.07$ | $[-0.040, +0.180]$ |
| $\Delta_{d_T}$ | $+0.38$ | $[-\infty, -0.480] \cup [+0.240, +\infty]$ |

$J_R = 5$, $K = 6$ kept switchers.
$\phi$ is well below the Möbius pole at $-1$; $\Delta_{d_T}$ is two-island and effectively unbounded; $\Delta_{\text{avg}}$ is statistically indistinguishable from zero.
Pattern matches the paper text's reading of the urban-hukou regime: a steep slope ($|\phi|$ large), close-to-zero average return ($\Delta_{\text{avg}} \approx 0$), where workers sort by comparative advantage and the residual never-migrants face roughly zero pecuniary returns.

## What this unblocks

The E1 misallocation aggregate can now be computed separately for the RF and UF regimes (and, once a weighting scheme is chosen, aggregated to a national CHN misallocation gap).
The E2 hukou-wedge counterfactual can also be computed from the contrast between $\phi^{rf}$ and $\phi^{uf}$ and from the implied $\Delta_{d_N}^{rf}$ versus $\Delta_{d_N}^{uf}$.

## Open items

1. **A CHN-hukou variant of the V3 joint-CI driver** is the next step.
   The IDN/TZA pipeline at [explorations/2026-05-20_e1_v3_joint_ci.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci.py) loads `_unb.dta`, fits the auxiliary OLS, and propagates the aggregate.
   The hukou variant reads `CHN_hukou_rural_first_unb.dta` (and `CHN_hukou_urban_first_unb.dta`) instead, with the same GMM-matched spec.
   $K$ values are smaller for the hukou cells (10 for RF, 6 for UF) than for IDN (27) or TZA (5), so the lattice spacing and Möbius-pole behavior may differ.
2. **The UF $\phi$ CI sits below $-1$.**
   The Möbius pole crossing is severe in this cell (the entire CI is below the pole).
   The P3 fallback (drop $d_T$, report aggregate as $d_N$ plus switchers) is essential for the UF counterfactual to be reportable.
3. **An E1 trajectory-share exporter for the hukou subsamples** is needed.
   The existing `_export_e1_inputs.do` loops over IDN and TZA only.
   A parallel `_export_e1_inputs_hukou.do` would read the RF and UF parent and `_d` sters and write trajectory shares, $\mu_d$, and $\Delta_d$ CSVs in the same format.
4. **RO and UO** can be added by extending the foreach loop in `5c_inversion_hukou.do`.
   Lower priority; can be batched with the figures-side robustness work.
