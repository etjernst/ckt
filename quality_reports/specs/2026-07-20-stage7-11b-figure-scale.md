# Spec: Stage 7, rebuild the extrapolation-support figure on the per-capita outcome

Date: 2026-07-20.
Parent plan: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), Stage 7.
Mode 2 (correctness stage); author sign-off required before commit because the corrected figure changes a reported claim (D-3: claim-affecting for TZA).

## Problem

`11b_extrapolation_support_figure.do` builds every quantity in the paper's support figure (fig:extrapolation_support) from raw household `ln(consumption)`: the never-migrant and switcher densities, the vertical line at $\mu_{d_N}$, and the rug of per-trajectory switcher means.
The GRC estimates the figure is meant to support run on log per-capita consumption (`logpc_consumption`, adult-equivalent cube), and the figure note in the manuscript already describes the plotted variable as per-capita, so the figure currently mislabels its own scale.
The Stage 0 probe ([probe_11b.csv](file:///C:/git/ckt/quality_reports/staging/stage0/probe_11b.csv), D-3) quantified the consequence: on the per-capita scale TZA's $\mu_{d_N}$ (14.00) falls about 0.055 log points below the switcher support (which starts at 14.05), while IDN (11.35 inside [10.97, 12.39]) and CHN (9.75 inside [9.31, 10.96]) stay inside.
The manuscript currently claims in-support in all three countries with in-range percentages of 24 (IDN), 26 (CHN), and 8 (TZA), and calls Tanzania "just inside the lower edge" (main-updated.tex, subsec:extrapolation-support); the corrected figure flips the TZA claim.

## Design choice

Rebuild the mu quantities from the per-capita variable in the data rather than reading them from a ster.
The figure overlays densities of individual rural-period means with the trajectory means of the same variable, so every plotted element must live on one scale; the processed `<country>_bal.dta` files now carry `logpc_consumption` built once at source (Stage 3+4 hub), which is exactly the estimation outcome.
Reading $\mu_{d_N}$ and the switcher means from a ster instead would mix covariate-adjusted model quantities into a raw-data density plot, and the current ster population is stale (pre-Change-A) until the definitive run, so a ster-based reconciliation is deferred (Y1).

## MUST

- M1. All mu quantities in `11b_extrapolation_support_figure.do` (density variable, $\mu_{d_N}$, per-trajectory switcher means, support range) compute from `logpc_consumption` as carried by `<country>_bal.dta`; the script no longer generates `ln(consumption)` or any local per-capita transform.
- M2. Sample handling keeps its current intent with missingness keyed to the new variable: drop rows missing `logpc_consumption`, `trajectory`, or `choice` (the hub already drops non-positive and missing outcomes at build; the defensive drop stays as a guard, not a second definition).
- M3. Figure text tells the truth about the scale: the x-axis title says per-capita (for example "Rural mean log consumption per capita"); no other visual redesign (palette, layout, labels, panel order unchanged).
- M4. The run lands in a shadow root (`stage7_root` beside the Stage 5/6 roots, data junction to `RP7/data`, real script copy), so no figure, log, or output under `RP7/output/` is overwritten before sign-off, per the standing nothing-gets-overwritten constraint.
- M5. Verification against the D-3 probe: the log prints $\mu_{d_N}$ and the switcher support per country; expected TZA $\mu_{d_N}$ below the support lower edge by about 0.055 log points, IDN and CHN inside; any departure from the probe's numbers is a finding to surface, not to absorb.
- M6. The stage reports the manuscript-facing numbers the author needs for the text revision: per country, $\mu_{d_N}$, the switcher support endpoints, and the position of $\mu_{d_N}$ relative to the range (percent into the range, or the gap below it for TZA); the manuscript itself is not edited in this stage.
- M7. Nothing ships to coauthors or Overleaf; the corrected figure is gate evidence until the definitive run.

## Author additions, 2026-07-20 afternoon

- M8. The figure script runs a support test per country: a pid-level comparison of individual rural-period mean log per-capita consumption between never-migrants and the switcher trajectory with the smallest mean (the support's lower edge), with robust standard errors; the gap, its standard error, and the two-sided p-value are logged and written to `extrapolation_support_test.csv` beside the figures, so the paper can state whether $\mu_{d_N}$ sits within sampling uncertainty of the switcher support.
- M9. The per-capita figure is the paper figure (author decision: the honest figure ships even though TZA looks worse); the script header documents that the scale is deliberate, and the raw household-scale variant stays a shadow-root comparison artifact only.
- M10. Update subsec:extrapolation-support in main-updated.tex to the per-capita numbers and the test result, and copy the per-capita `extrapolation_support_combined.pdf` into the Overleaf `figures/` folder; this supersedes M7's no-ship rule for this figure alone, at the author's direction.

## SHOULD

- S1. Correct the stale comments the fix orphans: the header and the in-body comment stating that consumption arrives in levels and must be transformed.
- S2. The shadow-root driver and rc receipt follow the `RP7/tests/stage0/` conventions from Stages 5 and 6.

## MAY

- Y1. A log-printed cross-check of the data-based $\mu_{d_N}$ against a balanced-spec ster's `mu:never`, once post-Change-A sters exist; deferred to the definitive run by default.
- Y2. Drop the defensive missingness guard entirely if the hub contract makes it provably redundant; default is to keep it.

## Out of scope

Any change to the densities' construction (kdensity grid, bandwidth), the figure's visual design beyond the axis-title wording, manuscript edits to subsec:extrapolation-support (author's call after seeing the numbers), the income outcome, and all estimation code.
