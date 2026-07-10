# Plan: counterfactual reproduction harness

Date: 2026-06-24.
Branch: lca-inversion.
Spec: [2026-06-24-counterfactual-reproduction-harness.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-06-24-counterfactual-reproduction-harness.md).

This plan turns the two verified dated drivers into one re-runnable pipeline step, persists the numbers, and wires the step into the master.
The math is already written and verified, so the work is consolidation, I/O, and orchestration, not new estimation.

## Architecture

Stata orchestrates, Python computes, matching the inversion step.

```
0_master.do  (switch: local run_counterfactuals = 0)
   └─ 12_counterfactuals.do
        ├─ Step A: regenerate input CSVs from current sters
        │          (include _export_e1_inputs.do + _export_e1_inputs_hukou.do)
        └─ Step B: python: import counterfactuals as _cf;
                   _cf.run_counterfactuals_for_stata(...)
                     ├─ reads input CSVs + processed .dta
                     ├─ runs all five cells (IDN, TZA, CHN_rf, CHN_uf, national)
                     ├─ self-check vs canonical numbers
                     ├─ writes RP7/output/counterfactual_results.csv
                     └─ writes RP7/output/tables/counterfactual_misallocation.tex
```

## Step 1: consolidate the glue into counterfactuals.py

Move the duplicated driver glue out of the two dated files and into the module, as module-level functions plus one orchestration entry.

- `prepare_data(country_file_stem, data_dir)` -- the sample prep that mirrors 5b (do not drop trajectory NaN rows).
- `load_cell_inputs(country_short, inputs_dir)` -- read the four input CSVs and merge.
- `compute_alpha_dT_obs(df, ...)` -- unchanged.
- `run_cell(country_file_stem, country_short, phi_grid, beta_grid)` -- one cell: fit aux OLS, build joint CI, propagate, return a structured result (point + CI, P3 and with-$d_T$, for both aggregates).
- `combine_national(rf_result, uf_result, weights)` -- the interval-arithmetic combination for CHN.
- `run_counterfactuals_for_stata(inputs_dir, data_dir, out_dir, table_path)` -- the Stata-facing entry: loops the cells, builds the national aggregate, runs the self-check, writes the results CSV and the LaTeX table.

The two dated drivers (`2026-05-20_e1_v3_joint_ci.py`, `2026-05-20_e1_chn_national.py`) become thin callers of `run_cell` / `run_counterfactuals_for_stata`, or are archived once the entry reproduces their output.

Validation gate 1: calling `run_cell` for IDN, TZA, CHN_rf, CHN_uf and `combine_national` reproduces the exact stdout numbers from the 2026-06-24 verification run before any file is archived.

## Step 2: self-check against a committed baseline snapshot

The regression baseline is a committed golden file, not in-code constants.
After Step 1 reproduces the verified stdout, freeze that run's results CSV as `RP7/output/counterfactual_results_baseline.csv` and commit it.

`run_counterfactuals_for_stata` then reads the baseline, joins it to the fresh run on (cell, aggregate, version), and asserts every value is within a stated tolerance (0.1 pp) of the baseline; it raises with a clear per-row message on drift.
Full-precision values live in the CSV; the code holds only the tolerance and the comparison.
Drift therefore surfaces twice: a loud failure and a git diff on the baseline.
Updating the baseline is a deliberate `--regenerate-baseline` run plus a reviewable commit, never an edit to magic numbers.

The headline P3 convex-hull intervals are the anchor (the paper's reported numbers):

| cell | misallocation gap (P3) | value of migration (P3) |
|---|---|---|
| IDN | [+5.67%, +6.08%] | +5.14% |
| TZA | [+14.67%, +22.84%] | +4.36% |
| CHN national | [+7.46%, +8.84%] | +4.29% |

(shown here for reference only; the live baseline is the committed CSV, at full precision).

Optional integrity cross-check (MAY): assert the export step's input CSVs still match the `.ster` scalars they were pulled from.
This guards the export, not the aggregation, so it is a secondary check.

Validation gate 2: the self-check passes on a clean run and fails (tested by perturbing one baseline row) with an informative message.

## Step 3: persist outputs

- `RP7/output/counterfactual_results.csv`: one row per (cell, aggregate, version), columns for point, CI low, CI high, in both log points and percent.
- `RP7/output/tables/counterfactual_misallocation.tex`: the paper-facing table, styled to match the existing GRC tables, with a `\label` and the P3 convex-hull intervals as the headline.

Validation gate 3: the CSV round-trips the numbers the paper currently states; the .tex compiles inside a minimal standalone harness.

## Step 4: the Stata driver 12_counterfactuals.do

Follow `5b_inversion.do` structure: header, log open, `capture noisily` body, log close, rc report.

- Set `inputs_dir`, `data_dir`, `out_dir`, `table_path` globals from the existing path config.
- Step A: `include` the two export do-files so the CSVs are regenerated from the current sters.
- Step B: one single-line `python:` call to `run_counterfactuals_for_stata`, passing the paths as arguments (per the SFI single-line-in-program convention; no multi-line python blocks).
- Echo the persisted file locations on success.

Validation gate 4: `stata-mp -e do 12_counterfactuals.do` from `RP7/scripts/` runs clean, regenerates the CSVs, and writes both outputs.

## Step 5: wire into 0_master.do

Add `local run_counterfactuals = 0` near the existing switches, with a header comment block: what it gates, why it defaults off, what it produces, prerequisites (inversion sters on disk).
Include `12_counterfactuals.do` after the inversion step and before table/figure assembly.

Validation gate 5: a master run with the switch on reaches and completes the new step; with the switch off, the step is skipped.

## Step 6: README and paper wiring

- Short README (`RP7/scripts/README_counterfactuals.md` or a section in the existing scripts README) documenting the two-tier chain and the switch.
- Replace the hand-typed E1 numbers in `paper/results_counterfactuals.tex` with an `\input` of the generated table where the paper currently shows a table-shaped result, leaving the prose intervals as prose but now traceable to the persisted CSV.

Validation gate 6: the paper section compiles with the new `\input`; numbers match the persisted results.

## Verification

End-to-end: from a state where the inversion sters exist, run `12_counterfactuals.do`, confirm the five cells reproduce, the self-check passes, the CSV and .tex are written, and the paper section compiles.
Run `critic-python` on the consolidated `counterfactuals.py` and `critic-stata` on `12_counterfactuals.do` before commit.

## Out of scope, tracked separately

- E2 hukou-wedge counterfactual.
- Moving the Python helpers under `RP7/scripts/` (MAY1).
- The full T1--T3 / F1--F2 / D1--D9 production pipeline.

## Estimated effort

Roughly one focused day: Step 1 is the bulk (consolidation without changing numbers), Steps 2--6 are mechanical once the entry point reproduces.
