# Counterfactual misallocation accounting (E1)

This note documents how the E1 misallocation numbers in the paper are produced and reproduced.

## What it computes

For each country it reports two aggregates, in log per-capita consumption (percent figures are the geometric-mean change, exp(x) − 1):

- the misallocation gap, the consumption that optimal sorting would unlock relative to observed sorting, and
- the value of observed migration, the consumption observed migration already delivers relative to no migration.

China enters through its two hukou regimes (rural-hukou first, urban-hukou first) plus a population-weighted national aggregate, because the pooled-China model is rejected by the J-test while each regime passes.

Each aggregate carries a 95 percent confidence interval obtained by projecting the joint weak-identification-robust confidence region for (phi, beta) through the aggregate, not by the delta method.
The reported headline is the P3 variant, which drops the always-urban contribution where the confidence region crosses the phi = −1 identification boundary (the always-urban return diverges there).

## How to run it

Set the switch in 0_master.do and run the master:

```stata
global run_counterfactuals 1
```

The step runs last in the pipeline (its export sub-steps do a clear all) and needs Python plus the inversion sters (5b_inversion.do) and the hukou sters (7_GrRC_hukou.do) already on disk.

## The two tiers

The computation is split so the expensive estimation and the cheap aggregation are separable.

Tier 1, Python, seconds.
counterfactuals.run_counterfactuals_for_stata reads the per-cell input CSVs in output/counterfactual_inputs/ plus the processed panel, builds the joint (phi, beta) confidence region, propagates the aggregate, and writes the outputs.
This is where all the counterfactual math lives.

Tier 2, Stata, the upstream estimation.
The input CSVs are written by _export_e1_inputs.do (IDN, TZA) and _export_e1_inputs_hukou.do (the China regimes), which pull the trajectory shares, trajectory means, switcher returns, and the (phi, beta) point estimates off the GRC and inversion sters.
12_counterfactuals.do regenerates these CSVs before the Python step, so the numbers always trace back to the current sters.

12_counterfactuals.do orchestrates both tiers and calls Python over the same SFI bridge that 5b_inversion.do uses for the inversion.

## Outputs

- output/counterfactual_results.csv, every number at full precision (point and CI, both the P3 and the with-always-urban variants, in log points and percent).
- output/tables/counterfactual_misallocation.tex, the paper table.

## The self-check

The run compares its numbers against output/counterfactual_results_baseline.csv, a frozen snapshot of a verified run, and stops with an explicit message if anything drifts beyond 0.001 log points.
A genuine change to the inputs therefore fails loudly rather than silently shipping.
To accept a new set of numbers, rerun the Python entry with regenerate_baseline=True and keep the refreshed baseline.
