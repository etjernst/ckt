# Plan: the definitive end-of-stages run

Date: 2026-07-21.
Parent plan: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), whose Stages 0-9 are all CLOSED and merged to main; this run is the entire remaining job.
Stage 9 context: [2026-07-21-stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md).

## What this run is

One serial batch run of `0_master.do` from the raw replication-package data all the way through the final tables and figures, on final post-refactor code (author decision 2026-07-21: no parallel launcher, one master file, agent launches it).
The run does three jobs at once: it rebuilds the processed hub with the Stage 9 switcher keep-list characteristics stamped in (which is what makes Change B take effect), it refits the entire `.ster` population under per-capita outcomes plus Change A plus Change B, and it regenerates every paper table and figure from those fits.
Expected wall-clock is roughly two days; the extras block (`9_GRC_extras.do`) is the long pole.

## Scope decisions (author, 2026-07-21)

- No old-versus-new comparison table with Hansen's $J$: dropped.
  A possible future appendix is a robustness check sweeping the trajectory-drop thresholds, but not now.
- No B-8 thin-cells-retained inversion exhibit: same status, not now.
- The simulation rebuild and P2 parity re-certification are outside this run's scope (the `sims/` machinery lives on `worktree-extension-sims`, not `main`); they become a dependent follow-on once the new sters are frozen.
- `copyOverleaf 0`: nothing ships to Overleaf as a side effect of the run.
  The Overleaf copy is a separate step the author approves after seeing the movement.
- Serial, not parallel: the author does not want a fleet of drivers and processes; `0_master.do` is the spine and the only entry point.

## Pre-flight edits to 0_master.do

1. `global copyOverleaf 0` (currently 1).
2. Add `include "$dir/scripts/5c_inversion_hukou.do"` after the `7_GrRC_hukou.do` include: the hukou inversion CIs are a paper input (the E1 hukou exporter reads them) and the script is currently a standalone driver the master never runs.
3. Add `include "$dir/scripts/11b_extrapolation_support_figure.do"` after the `11_make_figures.do` include: since Stage 7 this produces the paper's extrapolation-support figure and the support test CSV, and it too is currently orphaned from the master.
4. `$run_counterfactuals` stays 0 during the master run.
   `12_counterfactuals.do` self-checks against a committed baseline snapshot that is pre-Change-A/B, so its drift check will fire by design on the new numbers; running it inside the master risks a hard stop tens of hours in.
   It runs as a post-run step instead (below), with the drift adjudicated by the author and the baseline updated on approval.
5. `$runDashboard` stays 0.

These edits are committed before launch, so the run executes committed code.

## Backups before anything overwrites

- Copy `RP7/output/` (about 18 MB: 310 sters, tables, figures) to `RP7/output_prestage9_2026-07-21/`.
- Copy `RP7/data/processed/` (about 571 MB, the Stage 3+4 build) to `RP7/data/processed_prestage9_2026-07-21/`.
- The run then writes in place, which keeps every canonical path intact; the backups are the rollback, joining `processed_prestage34_2026-07-19` and the two earlier hub backups until the run is verified.
- Raw data under `RP7/data/countries/` are read-only inputs to the run and are not touched.

## Launch mechanics

- Launch detached via PowerShell `Start-Process` (per [reference_detached_stata_batches.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_detached_stata_batches.md)): a plain background Bash task would be reaped about 30 minutes after session idle, killing Stata mid-fit.
- Invocation: `stata-mp -e do 0_master.do` from `RP7/scripts/`, so the auto-log lands there and no completion popup fires.
- A small wrapper writes an rc sentinel file when Stata exits, since no completion notification fires for detached processes.
- Progress monitoring: poll the named master log (`$logs/0_master_<stamp>_maand.log`) and the ster mtimes in `RP7/output/`; the agent reports progress and completion in chat, and the author launches nothing.

## Post-run steps, in order

1. Sanity of the run itself: master log free of error codes, rc sentinel clean, every expected output family present (sters, tables, figures, `output/keeplists/*.csv`).
2. Keep-list agreement smoke: run `explorations/python-grc/run_all_countries_inversion.py` once; it must load the persisted keep-list CSVs and agree with its own recomputation (hard-error on mismatch).
   This closes the fixture-smoke item from the Stage 9 plan.
3. Run `12_counterfactuals.do`; collect the drift against the baseline snapshot and bring it to the author for adjudication; update the baseline snapshot only on approval.
4. Movement summary for the author: how the headline numbers moved (expected drivers: per-capita scale in OLS cells, Change A everywhere, Change B in cells with lumped thin trajectories), plus the TZA single-person-trajectory verification flagged with a `% TODO verify` in `main-updated.tex`.
5. Nothing ships until the author reviews: the Overleaf table and figure copy, the `RP7/{scripts,output}/` to Dropbox `ReplicationPackage7/` handoff, and the retirement of the hub and output backups are each separate author-approved steps after the movement review.

## Open items that stay open

- D-4 (the nonag manuscript promise) at the parent plan: unresolved, unaffected by this run.
- The `main-updated.tex` "lack complete trajectories" footnote imprecision: flagged to the author, not acted on.
- The threshold-robustness appendix idea (sweep `$grc_switcher_keep_min` and friends): parked, author may pick it up later.
- Simulation rebuild and P2 parity: follow-on after this run's sters are frozen.

## Rollback

A failed or wrong run rolls back by restoring the two backups (`output_prestage9_2026-07-21`, `processed_prestage9_2026-07-21`) over the in-place directories; committed code is untouched by the run itself, so no git surgery is involved.
