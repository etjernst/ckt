# Regression test scaffold (M6 + M7 of the refactor spec)

`reference/` holds a frozen snapshot of pipeline outputs that any future
change to the GMM code must continue to reproduce.

## What's in the reference

As of 2026-04-28, **only the 9 LaTeX tables produced by `5_GrRC.do`**:

```
reference/output/tables/GRC_<CHN|IDN|TZA>_<consumption|income>_urban_<unb|bal>.tex
```

These were captured from a clean smoke run on `worktree-grc-pipeline-refactor`
that completed 2026-04-27 17:56 (commit `b1ddf25`).
At that commit they are byte-for-byte identical to the coauthor's
ReplicationPackage6 outputs from 2026-04-22 (Dropbox).

Not yet captured (later phases will extend the reference):

- `.ster` files from `5_GrRC.do` --- 5_GrRC.do's three sections currently overwrite each other's sters; M11 fixes this and once M11 lands the next reference run can include all 45 unique sters.
- Figures from `3_heterogeneity_plots.do` and `4_trajectory_bar_graph.do` --- not run by `_smoke_5_GrRC.do`. Add when running the full master.
- Tables from `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `10`--`16_*.do` --- same.

## How to run the test

```bash
python tests/regression_test.py
```

Exits `0` if every reference file is reproduced exactly under
`RP7/output/`. Exits `1` if anything differs or is missing.

The test does NOT itself run Stata --- it just diffs files. Run the
relevant smoke first (`stata-mp -b do _smoke_5_GrRC.do` from
`RP7/scripts/`), then run the test.

## How to refresh the reference

When a phase intentionally changes outputs (e.g. M11 changes filenames),
the reference must be regenerated:

1. Run the relevant smoke or full master pipeline.
2. Verify the new outputs are correct (manual or against a prior reference plus the expected diff).
3. `cp -r RP7/output/<thing> tests/reference/output/<thing>`.
4. Commit the new reference with a message that explains why it changed.

Do NOT modify reference files directly --- always regenerate from a
verified Stata run.
