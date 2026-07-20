# Session log 2026-07-20 (afternoon): Stage 7 spec-to-merge, support figure per-capita with edge test

## If you resume

Stage 7 is CLOSED: signed off 2026-07-20, merged to main with merge commit `096765c` (--no-ff, matching the Stage 3-6 close pattern); NOT pushed to origin (the author did not request a push this session).
Next work is Stage 8 of [quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md): config hygiene (remove the `$values`/`$vsfx`/`data_real` machinery, relocate `CHN_hukou_*.dta` to processed, the named master log, the script-folder taxonomy discussion the author wants settled first); then Stage 9 (Change B) and the definitive run.
Cached state a resumer should know: `stage7_root` in `RP7/tests/stage0` (data junction to `RP7/data`, script copies including the raw-scale comparison variant `11b_extrapolation_support_figure_raw.do`) is retained gate evidence, untracked like the other stage roots; rc receipts stay untracked; D-4 (nonag manuscript promise) remains open; the critic MAJOR on the unguarded no-testable-edge case is a watch-item, declined at sign-off.

## Goals

Resume at Stage 7 of the pipeline-frontload plan (the 11b extrapolation-support figure on raw household scale), run as Mode 2 through spec, implementation, and author-extended scope: a support hypothesis test, shipping the per-capita figure to the paper, and the manuscript text update.

## Decisions, with the why

Data-based per-capita mu rather than ster-read (spec design choice): the figure overlays densities of raw individual rural means with trajectory means of the same variable, so every element must live on one scale; ster mu are covariate-adjusted model quantities, and the entire ster population is stale (pre-Change-A) until the definitive run.
The author decided the per-capita figure is the paper figure even though TZA looks worse: it is the honest figure, matching the GRC estimation outcome and the figure note's existing "per-capita" wording; the raw household-scale figure was rebuilt once as a comparison artifact only.
The support test keys the edge to the lowest-mean switcher trajectory with at least two individuals, because the naive lowest-mean test selected TZA's singleton cell (one individual, no estimable variance, robust SE fiction of 0.007) and IDN's 9-person cell; singletons stay rug ticks but cannot anchor inference.
The author-requested claim survives the redesign: TZA's testable edge (trajectory 4, 17 individuals, mean 14.096) exceeds mu_dN (13.999) by 0.097 with robust se 0.179 (p = 0.59), so the manuscript can say mu_dN is within sampling uncertainty of the switcher support; IDN and CHN edges sit significantly below mu_dN (p = 0.007, p < 0.001), confirming interior placement.
The critic MAJOR (unguarded crash if a country ever has no n>=2 switcher cell) was declined at sign-off: impossible on current data, loud failure mode, consistent with the Stage 6 F4 adjudication on defensive asserts.
The manuscript edit went into main-updated.tex directly (author instruction "we should also update the relevant text"), and the per-capita combined PDF was copied to the Overleaf figures folder as an author-directed exception to the stage's no-ship rule for this figure alone.

## What got built

[RP7/scripts/11b_extrapolation_support_figure.do](file:///C:/git/ckt/RP7/scripts/11b_extrapolation_support_figure.do): all mu quantities from `logpc_consumption`, per-capita x-axis title, header documenting the deliberate scale, and the support-test block (edge selection among n>=2 cells, singleton counting, pid-level robust regression, postfile accumulation to `extrapolation_support_test.csv`).
[RP7/tests/stage0/gate_stage7_figure.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage7_figure.do): shadow-root driver; [stage7_diag_traj_densities.do](file:///C:/git/ckt/RP7/tests/stage0/stage7_diag_traj_densities.do): always-rural vs always-urban density diagnostic (per-country y-axis caps per author preference); [stage7_probe_edge_cells.do](file:///C:/git/ckt/RP7/tests/stage0/stage7_probe_edge_cells.do): per-trajectory cell sizes and pairwise edge tests that exposed the singleton problem.
Manuscript: subsec:extrapolation-support rewritten (Indonesia and China in-support at 26 percent into the range each; Tanzania 0.055 below the raw edge, within sampling uncertainty of the testable edge; figure note updated); compile check passed, aux swept.
Production figures and test CSV regenerated in `RP7/output/figures`; per-capita combined PDF copied to Overleaf figures/.
Memory: [project_support_figure_percapita.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/project_support_figure_percapita.md) pins the scale decision and test design.

## Verification

Shadow-root gate rc=0; production-root rerun matches the shadow CSV value-for-value.
The corrected figure reproduces the Stage 0 D-3 probe: TZA mu_dN 13.999 vs support starting 14.054 (gap 0.055); IDN 11.354 inside [10.972, 12.462]; CHN 9.747 inside [9.312, 10.962]; the raw-scale comparison variant reproduces the pre-fix numbers exactly (TZA 14.571 inside [14.506, 15.347]).
Trajectory-coding check: share of urban waves exactly 0 for always-rural and 1 for always-urban in all three countries.
critic-stata 93 was Stage 6; Stage 7 scored 83/100, no CRITICAL, adjudications in [the review file](file:///C:/git/ckt/quality_reports/reviews/2026-07-20_stage7-support-figure-review.md).

## Gotchas recorded

A two-group robust regression where one group is a singleton produces a fictional standard error (the singleton's residual is zero by construction), so a min-over-cells edge must exclude cells that cannot carry within-group variance.
The support-of-the-distribution vs range-of-trajectory-means distinction matters: TZA's mu_dN is well inside the switcher consumption distribution but below the trajectory-mean grid that identifies the LCA line; the paper text now separates the two.

## Open items

Stage 8 (config hygiene sweep, includes the real-values removal and the script-taxonomy discussion), Stage 9 (Change B), then the definitive run.
D-4 (nonag manuscript promise) remains open at the parent plan.
Watch-item: the unguarded no-testable-edge case in the 11b support test (critic MAJOR, declined).
Main is ahead of origin by the Stage 7 commits; push only at the author's request.
