# Out-of-support diagnostic for the never-migrant extrapolation

**Date:** 2026-05-18.
**Branch:** lca-inversion.
**Context:** decision A6 in the 2026-05-18 methods review.
The headline E1 misallocation magnitude is dominated by the $d_N$ piece, which is identified by LCA extrapolation: evaluating the LCA line $\Delta_i = \beta + \phi\theta_i$ at $\mu_{d_N}$.
If $\mu_{d_N}$ sits outside the range of switcher trajectory means $\mu_{\underline{d}}$, the magnitude depends on the LCA line holding off the support where it was estimated.
This memo reports a first-pass visual diagnostic for that question.

## Method

For each country (CHN, IDN, TZA) on the balanced sample, compute each individual's mean of log per-capita consumption over their rural periods.
For never-migrants, all periods contribute; for switchers, only rural periods.
Plot the density of this individual-level rural mean by trajectory category, with never-migrants highlighted, and overlay a dashed line at $\hat\mu_{d_N}$ (the empirical $d_N$ trajectory mean) and dotted lines at the min and max of switcher trajectory means.
Driver: [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do).
Log: [RP7/output/logs/extrapolation_support_diagnostic.smcl](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/logs/extrapolation_support_diagnostic.smcl).

## Numbers

| Country | $\hat\mu_{d_N}$ | Switcher $\mu_{\underline{d}}$ range | Position in hull | Verdict |
|---------|-----------------|---------------------------------------|------------------|---------|
| CHN     | 10.21           | $[9.82, 11.31]$                       | 0.26 from low    | Interior, well-supported |
| IDN     | 11.83           | $[11.50, 12.83]$                      | 0.24 from low    | Interior, very well-supported |
| TZA     | 14.57           | $[14.51, 15.35]$                      | 0.08 from low    | Interior but at the boundary |

All in log per-capita consumption units (local currency).

## Headline reading

All three countries have $\hat\mu_{d_N}$ *inside* the convex hull of switcher trajectory means.
The E1 magnitude is interpolation, not extrapolation, in every country.
This is good news for the headline interpretation.

**TZA is borderline.**
$\hat\mu_{d_N}$ sits at the very low edge of the switcher range, only 8% of the way across.
The TZA never-migrant density is visibly shifted to the left of the switcher density.
The headline TZA magnitude is technically interpolation but sensitive to LCA holding near the lower edge of the switcher support.
A footnote in T1 noting this is warranted.

CHN and IDN are clean.
$\hat\mu_{d_N}$ sits about a quarter of the way into the switcher hull in both; densities overlap heavily.

## Files

Figures:

- [extrapolation_support_CHN.pdf](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_CHN.pdf), [.png](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_CHN.png)
- [extrapolation_support_IDN.pdf](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_IDN.pdf), [.png](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_IDN.png)
- [extrapolation_support_TZA.pdf](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_TZA.pdf), [.png](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/figures/extrapolation_support_TZA.png)

Driver and log:

- [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do)
- [RP7/output/logs/extrapolation_support_diagnostic.smcl](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/logs/extrapolation_support_diagnostic.smcl)

## What to do with this

This is a first-pass visual check.
The natural next steps are:

1. Decide whether to include this as a paper-side appendix figure with a one-sentence reference in the main text where $\hat\Delta_{d_N}$ is reported.
2. Extend to hukou-split CHN: the rural-hukou and urban-hukou regimes have different $\hat\mu_{d_N}$ and different switcher sets; the diagnostic should be repeated per regime.
3. The TZA boundary case may warrant a sensitivity exercise that trims switcher trajectories with $\mu_{\underline{d}}$ above some quantile of the $d_N$ distribution and refits, to test whether the headline magnitude depends on the upper-end switcher pull.
4. The dotted lines at the switcher min/max are visible but thin in the current figures; if this becomes a paper figure, increase line width or add small caps at the endpoints.
