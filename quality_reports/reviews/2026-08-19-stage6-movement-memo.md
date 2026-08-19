# Movement memo: WCR11 phi regions, counterfactual transition, and the two E1 variants

Date: 2026-08-19.
For author adjudication; nothing here is decided.
Inputs: the 80 re-attached sters in `RP7/output/` (WCR11, B = 999, phi grid [-5, 1] for IDN, TZA, CHN_uf and [-5, 5] for CHN and CHN_rf), the tables rebuilt from them at 11:15 today, the counterfactual transition run at 11:35 today (`12_counterfactuals.do` with `$cf_allow_drift = 1`, log at [12_counterfactuals.log](file:///C:/git/ckt/RP7/scripts/logs/12_counterfactuals.log)), and for the "before" side the 2026-07-21 ster vintage in `RP7/output_prestage9_2026-07-21/` (the last vintage carrying chi-squared inversion CIs; extracted to [chi2_era_cis.csv](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/chi2_era_cis.csv)) and the committed `counterfactual_results_baseline.csv`.

## 1. Phi confidence regions: chi-squared era against WCR11

The chi-squared vintage carried an inversion CI on the IDN and TZA cells, on CHN ca, CHN_rf ca, and CHN_uf ca only; the pooled-CHN ct/c1/c2 and the hukou ct/c1/c2 cells had none, so those rows show only the WCR11 result.

| Cell | Point ($\phi$ at Wald min) | Chi-squared 95% (2026-07-21) | WCR11 95% (today) |
|---|---|---|---|
| IDN ct | -0.36 | [-0.64, -0.07] | [-0.86, 0.39] |
| IDN c1 | -0.36 | [-0.64, -0.07] | [-0.86, 0.41] |
| IDN c2 | -0.37 | [-0.63, -0.11] | [-0.92, 0.35] |
| IDN ca | -0.58 | [-1.23, -0.01] | five islands, hull [-4.15, 0.84]; 90%: [-1.54, 0.41] |
| TZA ct | -0.55 | [-0.70, -0.41] | [-0.75, -0.38] |
| TZA c1 | -0.56 | [-0.71, -0.41] | [-0.76, -0.35] |
| TZA c2 | -0.57 | [-0.72, -0.43] | [-0.78, -0.38] |
| TZA ca | -0.73 | [-1.22, -0.45] | [-1.30, -0.42] |
| CHN ct | -0.24 | none attached | [0.36, $+\infty$] |
| CHN c1 | -0.24 | none attached | [-0.35, -0.14] $\cup$ [0.41, $+\infty$] |
| CHN c2 | -0.28 | none attached | [-0.30, -0.28] $\cup$ [-0.25, -0.25] $\cup$ [0.48, 4.00] |
| CHN ca | -0.33 | empty set | [-0.53, -0.18] $\cup$ [0.28, 3.85] |
| CHN_rf ct | -0.04 | none attached | [-0.88, $+\infty$]; 90%: [-0.48, 4.04] |
| CHN_rf c1 | -0.04 | none attached | [-0.77, $+\infty$]; 90%: [-0.47, 2.89] |
| CHN_rf c2 | -0.14 | none attached | [-0.53, $+\infty$]; 90%: [-0.39, 0.71] |
| CHN_rf ca | -0.16 | [-0.30, 0.01] | [-0.59, $+\infty$]; 90%: [-0.48, 0.55] |
| CHN_uf ct | -5.00 | none attached | [$-\infty$, -0.52] $\cup$ [0.26, $+\infty$] |
| CHN_uf c1 | -5.00 | none attached | [$-\infty$, -0.50] $\cup$ [0.34, $+\infty$] |
| CHN_uf c2 | -5.00 | none attached | [$-\infty$, -0.54] $\cup$ [0.30, $+\infty$] |
| CHN_uf ca | -3.23 | [$-\infty$, -0.77] (grid [-3, 1]) | [$-\infty$, -0.65] $\cup$ [0.37, $+\infty$] |

What moved and why it was expected.
Tanzania barely moves: four restrictions and at least 17 switchers per kept trajectory put it where the size study said the chi-squared test is close to correctly sized, and the WCR11 regions widen by 0.03 to 0.10 on each side and stay bounded and negative.
Indonesia widens a lot: with 26 restrictions and thin trajectories the chi-squared test rejected the true $\phi$ 26 percent of the time in the Indonesia-calibrated simulations, so its intervals were too short by construction; the corrected regions no longer exclude zero in the three main specifications, and the all-covariates specification fragments into five islands whose four lower islands lie below -3 (the 90 percent region is a single interval, [-1.54, 0.41]).
Pooled China turns from an empty set (every $\phi$ rejected, the joint-misfit symptom of the known Hansen J rejection) into regions that reach the upper grid edge; the 90 percent regions are empty in all four pooled cells and the Wald-minimizing point lies outside the 95 percent region in ct and c1, so the pooled sample still displays joint misfit rather than a $\phi$ that the data pin down.
Rural-hukou China is bounded below near -0.5 to -0.9 in every specification and open above at 95 percent even on the grid widened to +5, while its 90 percent regions close (at 4.04, 2.89, 0.71, and 0.55); this is a weak-identification upper tail, not a grid margin, and the lean recorded in the endpoint memo is to report it as open above and stop widening.
Urban-hukou China is open at both edges at 95 and 90 percent in all four specifications, as the port plan predicted.

Two presentation choices for the author.
First, for IDN ca: union of five islands as the tables now print it, or hull with a footnote; the table string is 120 characters wide.
Second, for the six CHN and CHN_rf cells open above +5, whether the table should say "$+\infty$" (current rendering, meaning the region reaches the grid edge) or state the edge value.

## 2. Counterfactual transition: fresh against the committed baseline

The transition run rebuilt the per-cell inputs from the GMM sters (`_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`), recomputed every cell, wrote both variant tables and the hukou-bound table, and reported drift.
Because the E1/E2 rework changed the result schema (variant A and B points, both value baselines, hull intervals demoted to diagnostics), the drift report is 65 rows present on one side only rather than a numeric comparison; the numeric comparison is below.

Misallocation gap, percent, point estimates:

| Cell | Baseline (p3, chi-squared era) | Fresh variant B (always-urban zeroed) | Fresh variant A (always-urban at GMM point) |
|---|---|---|---|
| Indonesia | 9.32 | 9.31 | 9.63 |
| Tanzania | 23.50 | 23.49 | 40.79 |
| China national | 11.75 | 11.75 | 56.66 |
| China rural-hukou first | 15.21 | 15.22 | 15.22 |
| China urban-hukou first | 2.51 | 2.50 | 273.16 |

Value of migration versus first location, percent: 0.81, 0.21, 0.67, 0.78, 0.34 in the same order, identical to the baseline to two decimals.
Value of migration versus all rural (new column): variant B 8.20, 5.78, 8.67, 6.16, 16.07; variant A 7.89, -7.21, -21.89, 7.26, -68.12.

Reading.
Variant B reproduces the baseline points to within 0.02 percentage points everywhere, so the GMM sourcing of the inputs and the WCR11 attach changed nothing in the quantities the paper reported before; the drift is entirely the schema.
Variant A differs only through the always-urban row, and it moves the headline in three cells: Tanzania (23.5 to 40.8), China national (11.7 to 56.7), and urban-hukou China (2.5 to 273.2), the last driven by a GMM $\Delta_{d_T}$ point in a cell whose $\phi$ region is open at both edges.
Two facts bear on the A/B pick: the derived-quantity coverage study found that GMM 95 percent intervals for $\Delta_{d_T}$ under-cover (0.85 to 0.90 across designs), which was the reason the boundary drop was adopted, and the CHN_uf $\phi$ region is unbounded, so any quantity that leans on that cell's always-urban return inherits weak identification.
The lean is variant B as the canonical table, with variant A shown in the appendix or a footnote as the sensitivity to the always-urban row.

E1 intervals: the fresh CSV carries points only for the E1 quantities; the E1 interval is pending per the plan (its construction under WCR11 is what the extension simulations' set-metric pathway is for), so the variant tables print points without brackets.
E2 hukou bound: the point is unchanged (11.13 percent per never-migrant, 2.14 percent economy-wide); the interval now comes from the GMM `_n` ster of `grc_CHN_rf_cuu_ca` rather than the chi-squared inversion, [6.1, 16.4] against [9.4, 13.9] before, and [1.2, 3.1] against [1.8, 2.7] economy-wide.

## 3. Rebuilt tables

All 28 GRC tables regenerated at 11:15 from the main-tree sters with the port branch's `grc_tex_table_trend`; the phi block carries one "95\% inv. CI" row (WCR11) and the delta blocks print GMM inference only, as the port plan specifies.
Rendered examples: [GRC_IDN_consumption_urban_unb.tex](file:///C:/git/ckt/RP7/output/tables/GRC_IDN_consumption_urban_unb.tex), [GRC_CHN_consumption_urban_unb.tex](file:///C:/git/ckt/RP7/output/tables/GRC_CHN_consumption_urban_unb.tex), [GRC_CHN_hukou_rural_first_consumption_urban_unb.tex](file:///C:/git/ckt/RP7/output/tables/GRC_CHN_hukou_rural_first_consumption_urban_unb.tex); the pre-rebuild tables are kept in `RP7/output_tables_backup_2026-08-19/`.

## 4. Author gates that follow

1. Drift adjudication: approve the fresh counterfactual numbers (variant B equals the baseline; the schema is new).
2. E1 variant pick: A or B; then one run with `$cf_regen_baseline = 1` and `$cf_e1_variant` set writes the canonical `counterfactual_misallocation.tex` and freezes the new baseline, followed by a strict run with all knobs unset.
3. Presentation of the open-above CHN and CHN_rf regions and of the IDN ca islands.
4. Preamble table-macro diffs for Overleaf (proposed as a diff for the author to place), and the additive copy of the rebuilt tables into the Overleaf `tables/` folder.
