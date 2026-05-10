# Step 0 baseline: pre-cache dashboard render profile

Captured 2026-05-10 against branch `worktree-grc-pipeline-refactor` at commit `5a6bdda`.

## Artifacts

- [quality_reports/baselines/2026-05-09_pre-cache.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/baselines/2026-05-09_pre-cache.html) --- the rendered dashboard, 2.6 MB, 49 cells.
  Rendered with `quarto render report.qmd --to html` from `tools/results_overview/`.
  Wall: roughly 12 minutes.
  This is the bytes-comparison baseline for Step 2 (cache-aware reader); the new render must reproduce this output modulo the rendered footer's timestamp.

- [tools/results_overview/profile_render.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/profile_render.py) --- the cProfile harness.
  Mirrors the 24 `comparison_table` + `coefplot` chunks in `report.qmd` without Quarto/Jupyter overhead so the profile reflects the pure Python+pystata work.

- [tools/results_overview/profile_render.prof](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/profile_render.prof) --- the cProfile output, 1.4 MB, captured 2026-05-10 14:12.
  10.5 minutes wall, 627.9 seconds tracked under cProfile, 24 chunks (22 succeeded, 2 raised `FileNotFoundError` for the `urban birth` family which has no on-disk sters --- caught and logged, matching the qmd's `error: true` behavior).

## Top of profile by cumulative time

| function                                  | ncalls | cumtime (s) | share of total |
|-------------------------------------------|--------|-------------|----------------|
| `comparison_table` (compare.py:374)       | 24     | 619.97      | 98.7%          |
| `load_fit` (compare.py:311)               | 427    | 619.69      | 98.7%          |
| `_cached_load_ster` (compare.py:28)       | 365    | 619.37      | 98.6%          |
| `load_ster` (scrape.py:119)               | 365    | 619.36      | 98.6%          |
| `sfi.py:get` (pystata)                    | 730    | 592.55      | 94.4%          |
| `stata_plugin._st_getmatrix` (built-in)   | 730    | 589.86      | 93.9%          |
| `compare.py:_maybe`                       | 1356   | 167.95      | 26.7%          |
| `compare.py:coefplot`                     | 22     |   4.96      |  0.8%          |

Total run time: 627.94 s.

## Read

`_cached_load_ster` accounts for **98.6% of wall time** --- well past the 80% threshold the plan required to proceed with the cache.
93.9% is in `_st_getmatrix` itself: the pystata IPC round-trip pulling matrices from Stata's `e()`.
365 unique disk hits across 24 chunks, averaging 1.70s per `load_ster`, with each call making two `_st_getmatrix` round-trips (one for `e(b)`, one for `e(V)`).

The 427 `load_fit` calls (vs. 365 `_cached_load_ster` calls) confirm the in-process LRU cache is already absorbing roughly 15% of repeated lookups (the `comparison_table` --> `coefplot` double-load mentioned in the docstring).
The remaining 365 unique loads are exactly what the on-disk headlines cache will short-circuit.

`coefplot` itself contributes only ~5 seconds total --- matplotlib is not on the critical path.
`comparison_table`'s 26.7s in `_maybe` is the same `_st_getmatrix` cost rolled up under the optional-load helper.

## Decision

Proceed to Step 1 (Python writer: `tools/results_overview/scrape_headlines.py`).

Expected post-cache render time: dominated by `_load_headlines()` (one pass over ~600 small CSVs with `pd.read_csv`, hundreds of milliseconds) plus the ~5s of matplotlib work for coefplots.
Order of magnitude: well under 30 seconds, vs. 12 minutes baseline.

## Caveats and re-plan triggers

If, after Step 2, the post-cache render time stays above ~30 seconds, the bottleneck has shifted somewhere outside `load_fit`.
Likely suspects in priority order:

1. `_load_rescaled` reconstructing the dict per-render (didn't show up in this profile because the existing `_cached_rescaled` already absorbs it).
2. `_synthetic_fit_from_bank` for `_r` stems (also under 1% in this profile, but with `load_fit` removed from the critical path, anything else could become dominant).
3. `comparison_table`'s pandas operations (table assembly, filtering, sorting --- a few percent today, would become more visible).

Re-profile under cProfile in step 2 to confirm the new shape; do not assume.
