# Counterfactual experiments (E1 misallocation, E2 hukou bound)

This note documents how the counterfactual numbers in the paper are produced and reproduced.

## What E1 computes

For each country it reports three point aggregates, in log per-capita consumption (percent figures are the geometric-mean change, exp(x) − 1):

- the misallocation gap, the consumption that optimal sorting would unlock relative to observed sorting,
- the value of observed migration relative to holding each worker at their first-observed-wave location, and
- the value of observed migration relative to an everyone-rural baseline, which additionally values the urban person-time of workers who never appear rural.

China enters through its two hukou regimes (rural-hukou first, urban-hukou first) plus a population-weighted national aggregate, because the pooled-China model is rejected by the J-test while each regime passes.

Every trajectory return entering the points is a GMM estimate: the LCA-fitted switcher returns from the `_d` ster, the never-migrant return from the `_n` ster, and (in variant A) the always-urban return from the `_a` ster.

The always-urban return is estimated less reliably than the others, so the table ships in two variants for comparison: variant A keeps the always-urban row at its GMM point, and variant B sets it to zero in the gap and everyone-rural value columns.
The first-observed-wave value column is identical across variants because always-urban workers do not move relative to their first observed wave.

No confidence interval is reported for the E1 aggregates at present.
The interval construction that projects the joint (phi, beta) confidence region through the aggregate showed simulated coverage of 0.82 at the nominal 95 percent level, and a corrected construction is planned; the computed projections stay in the diagnostics CSV, not in the reported results.

## What E2 computes

The hukou-wedge lower bound: the economy-wide consumption gain from relocating the rural-hukou never-migrants, computed as the rural-hukou population share times the never-migrant share within that group times the never-migrant return.
The return and its 95 percent confidence interval come from the CHN_rf `_n` ster (the GMM estimate and its delta-method interval, exported as `gmm_dN_ci95_lo/hi`); the bound's interval scales those endpoints by the fixed shares.
The results CSV records the source ster of the interval in a `ci_source` column.

## How to run it

Set the switch in 0_master.do and run the master:

```stata
global run_counterfactuals 1
```

The step runs last in the pipeline (its export sub-steps do a clear all) and needs Python plus the GRC sters (4_GrRC.do) and the hukou sters (7_GrRC_hukou.do) already on disk.

Three optional globals, all off by default:

```stata
global cf_allow_drift 1      // print a baseline drift loudly instead of stopping
global cf_regen_baseline 1   // rewrite the baseline snapshot (after the numbers are approved)
global cf_e1_variant A       // A or B: also write the chosen variant as counterfactual_misallocation.tex
```

## The two tiers

The computation is split so the expensive estimation and the cheap aggregation are separable.

Tier 1, Python, seconds.
counterfactuals.run_counterfactuals_for_stata reads the per-cell input CSVs in output/counterfactual_inputs/ plus the processed panel, evaluates the point aggregates and diagnostics, and writes the outputs.
This is where all the counterfactual math lives.

Tier 2, Stata, the upstream estimation.
The input CSVs are written by utilities/_export_e1_inputs.do (IDN, TZA) and utilities/_export_e1_inputs_hukou.do (the China regimes), which pull the trajectory shares, trajectory means, switcher returns, and the GMM points and intervals off the GRC sters; each exported quantity carries a source row naming the ster behind it.
12_counterfactuals.do regenerates these CSVs before the Python step, so the numbers always trace back to the current sters.

12_counterfactuals.do orchestrates both tiers and calls Python over the same SFI bridge that 5b_inversion.do uses for the inversion.

## Outputs

- output/counterfactual_results.csv, every reported number at full precision (E1 points for both variants and both value baselines, E2 point and CI, in log points and percent, with CI provenance).
- output/counterfactual_diagnostics.csv and output/counterfactual_decomposition.csv, working diagnostics including the unreported interval projections and the per-trajectory contributions.
- output/tables/counterfactual_misallocation_varA.tex and _varB.tex, the two comparison tables.
- output/tables/counterfactual_misallocation.tex, the paper table, written once a variant is chosen via `cf_e1_variant`.
- output/tables/hukou_bound.tex, the E2 table.

## The self-check

The run compares its numbers against output/counterfactual_results_baseline.csv, a frozen snapshot of a verified run, and stops with an explicit message if anything drifts beyond 0.001 log points.
A genuine change to the inputs therefore fails loudly rather than silently shipping.
To accept a new set of numbers, rerun with `global cf_regen_baseline 1` and keep the refreshed baseline.
