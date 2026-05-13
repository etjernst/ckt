# 2026-05-08: dashboard rescale + convergence row (post-/clear continuation)

## Goal

Continuation of [2026-05-08_full-pipeline-run.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-08_full-pipeline-run.md), picked up after /clear.
Two asks from the user, in order:

1. Refresh the dashboard so the rescaled Delta_avg values (per the sidecar CSV produced yesterday) actually show up in [report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html).
2. Add a row to the comparison tables indicating whether the GMM converged.

## State at session start

Resume run still alive as PID 4864 (launched 2026-05-07 12:28 via `run_master_resume.do`).
Logged into [run_master_resume.log](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.log).
At pickup, the run was inside `9_GRC_extras.do`, partway through the very first cell (`run_grc_with_extra_regressor IDN cuu exp`).
GMM Steps 1--2 had completed by 12:33 (per log mtime); the process was buffer-locked on the `nlcom` block, which is the same 30-trajectory IDN-cuu pattern that takes ~50 min/cell.

Confirmed Stata process alive (~26 CPU-min at pickup, growing) and not hung.

## What changed

### Dashboard override (commit `19cd009`)

[tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py).
Added `_load_rescaled()` --- a cached loader (mtime-keyed) for [delta_avg_rescaled.csv](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/delta_avg_rescaled.csv).
Modified `Fit.headline()` so that, after reading `Delta_avg` from `g_rec`, it looks up the stem in the rescaled dict and substitutes `(b_rescaled, se_rescaled)` whenever the on-disk ster's buggy values still match `(b_buggy, se_buggy)` within 1e-9.
Smoke test confirmed the override: `grc_IDN_cuu_c0` now reads `(0.381, 0.023)`, exactly matching the CSV row, vs the prior buggy `(0.027, 0.002)`.
The 14x ratio matches `1/sw_frac = 1/0.0716` for that cell.

[tools/results_overview/report.qmd](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.qmd).
Added `error: true` under the `execute:` YAML key so quarto continues past chunks that raise.
Five family-extras comparison chunks (`exp`, `maxexp`, `expsh`, `maxexpsh`, `birth`) reference sters that `9_GRC_extras.do` is currently producing for the first time --- without `error: true`, the first such chunk aborted the entire render and `report.html` was never rewritten.

### Convergence row (commit `1f1f5c7`)

[tools/results_overview/scrape.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape.py).
`SterRecord` gains a `converged` field; `load_ster` reads `e(converged)` (set by Stata's `gmm` command at the end of the second-step optimizer).

[tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py).
`comparison_table` appends a `converged` row between `J p` and `N`.
Cells render `Y` for `e(converged) == 1`, `<b>N</b>` for `0`, empty when the field is missing (synthetic-bank fits from `scraped_real.json` carry no convergence info).

[tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html).
Re-rendered after each commit.
Final size 2.58 MB, last write 13:41.
Every fit across the rendered dashboard shows `Y`; no GMM failures in the 110 cells from this run.

## Decisions, with the why

### Match-on-buggy guard for the headline override

Why: a sidecar CSV that always overrides would corrupt the dashboard the moment any cell gets re-fit under the corrected `0_programs.do` --- the new ster's correct values would be replaced by stale rescaled values from the CSV, and the user would have to remember to re-run `fix_delta_avg_scaling.do` to refresh.
Comparing the on-disk `(b, se)` to `(b_buggy, se_buggy)` within 1e-9 makes the override self-cleaning: the moment a re-fit lands, the equality fails and the override silently bypasses.
Zero plumbing, zero stale-CSV risk.

### `error: true` at the document level instead of per-chunk try/except

Why: cleaner, one-line change vs touching all five extras-comparison chunks.
Quarto renders the failing chunks with inline tracebacks, which is informative ("these aren't ready yet"), and the document still gets written.
When the in-flight `9_GRC_extras.do` produces the missing sters, those chunks will start producing tables on the very next render with no further qmd change.

### Convergence row uses only the main ster's `e(converged)`

Why: the main fit's GMM is where `phi` is identified, and that's the headline.
The four subgroup sters (`_n`, `_a`, `_d`, `_g`) carry their own `e(converged)`, but stacking four extra rows would clutter the table.
If a non-converged subgroup ever shows up in practice, it's easy to extend.

### Bold for non-converged, plain for converged

Why: the dashboard should be a clean Y wall in steady state, with `<b>N</b>` standing out.
Color coding would compete with the existing version-stripe background colors.

## Approaches rejected

### Per-chunk try/except wrappers in report.qmd

Reason dropped: would touch 5+ chunks with boilerplate, harder to maintain than a single YAML toggle.

### In-place mutation of `_g.ster` files to bake in the rescaled values

Reason dropped (already documented in yesterday's wrap-up): `ereturn post` after `estimates use` of an `nlcom`-posted ster errors with `r(301)` on save and `r(152)` on `ereturn repost`.
The CSV sidecar route avoids touching the binary ster.

### Exposing convergence per-subgroup in the dashboard

Reason deferred: not worth the row count today.
Revisit if a non-converged subgroup actually appears.

## Open items

- Pipeline still detached as PID 4864.
  Per [run_master_resume.log](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.log), still inside `9_GRC_extras.do`, working through the first IDN-cuu cell.
  Estimated remaining time: 24--30 hours through `9_GRC_extras` (44 stems), then `10_make_tables`, `11_make_figures`, `17_verdier_robust`.
- Family-extras chunks in the dashboard render as tracebacks until those sters land.
  Re-rendering after the run finishes will populate them automatically.
- Two fixes from yesterday (assert_merge_clean asis + Delta_avg scaling in `0_programs.do`, copyOverleaf filename in `8_learning.do`) plus today's dashboard work all need eventual reconciliation with `lca-inversion`.

## Picking back up

The pipeline is on track; no immediate action needed.
Once it finishes (likely overnight or tomorrow), re-render the dashboard --- the family-extras chunks should populate, and the rescaled-CSV override will continue to apply only to the 110 pre-fix cells.

with Claude
