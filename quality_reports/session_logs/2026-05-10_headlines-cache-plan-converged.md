# 2026-05-10: headlines cache plan converged (pre-/clear)

## Goals

The session crossed midnight; this is the third leg of a thread that started 2026-05-08 with a long-running pipeline and rolled through 2026-05-09 with critic rounds on a derived-cache plan.
Today's leg: apply the third round of critic simplifications and prepare to start implementation in a fresh session.

The user's framing for the third critic round was the load-bearing one: review fresh, no prior context about revisions, bias hard toward simplicity.
Result: the plan dropped about half its scope and the in-Stata writer disappeared.

## What got built or changed

[quality_reports/plans/2026-05-09_headlines-cache.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-09_headlines-cache.md).
Rewritten in commit `0dc8737` with the round-3 simplifications.
Net `+133 / -214` --- the plan is now shorter than the round-2 version, which is the right shape for a simplification round.
Final design: one writer (Python `scrape_headlines.py` with `--incremental` and `--jobs N`), one reader, no Stata-side schema, no manifest, no provenance column.
Cache freshness wired into the pipeline via a single `shell python ... --incremental` line at the tail of `0_master.do` and `run_master_resume.do`.

[quality_reports/session_logs/2026-05-09_pipeline-watch-and-parallelization-plan.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-09_pipeline-watch-and-parallelization-plan.md).
Earlier today (before midnight) appended the "afternoon" continuation section capturing the kill-pipeline + critic-round-1-and-2 arc.
Today's leg appends nothing further to that file --- it goes here instead.

No code changes today.
The plan is decision-stage; implementation starts in the next session.

## Decisions, with the why

### Drop the in-Stata writer (Step 3)

Why: the round-3 critic correctly flagged it as the biggest YAGNI in the plan.
Step 3 would have touched five Stata estimator programs at multiple capture windows each, required a Stata-side schema mirror (`$HEADLINES_COLS` global), and required `capture noisily` defenses --- all to avoid running a Python script after each fit batch.
Replaced with a single `shell python "$dir/../tools/results_overview/scrape_headlines.py" --incremental` line at the tail of the master scripts.
Recovers the autosync benefit at a fraction of the complexity.

### Replace mtime tolerance with exact comparison via per-row source mtimes

Why: the round-2 plan added a 5-second tolerance constant to handle bootstrap-written rows being born stale-by-one-second relative to the source sters.
The round-3 critic pointed out that recording the source mtimes (`main_mtime`, `n_mtime`, `a_mtime`, `g_mtime`) into each cache row makes exact comparison work cleanly --- no fudge factor, no `_cache_row_is_fresh` as a separate function.

### Drop the manifest sidecar

Why: only `schema_version` was functionally used.
The other manifest fields (`columns`, `written_at`, `writer`) were decorative.
Putting `schema_version` as the first column of every row achieves the same invalidation behavior with one fewer file and one fewer source of sync drift.

### Drop the `source = "ster" | "bank"` provenance column and bank-row writing

Why: nothing in the read path used it for behavior.
The `_r` real-values synthetic-bank case can stay entirely in the existing `_load_fit_live` fallback path (which already handles it correctly).
Eliminates the precedence-rule paragraph, the bank-overwrite-by-real-fit logic, and one whole class of "where did this row come from" debugging.

### `--jobs N` default 1 (was 4)

Why: premature-optimization pushback from the round-3 critic.
30 minutes once is fine.
The flag stays available; raise the default only if the one-time cost actually annoys someone.

### Three critic rounds on the same plan rather than ship the round-1 version

Why: each round caught a different failure layer.
Round 1 caught structural bugs (cache schema too narrow to short-circuit `load_fit`, vague writer call sites, false atomicity claim).
Round 2 caught implementation precision gaps (line targets, `_load_fit_live` rename, parallelization).
Round 3 (with explicit anti-overcomplication framing) caught the over-engineering --- two writers when one suffices, manifest when a row column suffices, source provenance when no caller uses it.
The round-3 verdict was the cleanest version: scope drops by half, dashboard still gets fast.

## Approaches rejected and the reason

### Wire cache writes into `run_grc` directly (round 1 and 2 design)

Reason dropped: required edits at five Stata programs at multiple capture windows each plus a Stata-side schema mirror.
The round-3 critic showed the same outcome reachable with `scrape_headlines.py --incremental` shell-out at the master script tail.
One line of Stata vs. hundreds of lines of fragile capture-window edits.

### Manifest sidecar for schema versioning

Reason dropped: only one of its four fields was functionally used.
A row-level `schema_version` column carries the same invalidation behavior without the second file.

### Bank-row synthesis in the cache for `_r` stems

Reason dropped: the existing `_load_fit_live` synthetic-bank path already handles `_r` stems correctly.
Adding bank rows to the cache duplicated functionality and forced a precedence rule.

### `lru_cache` on `_load_headlines()`

Reason dropped: in long-lived Jupyter kernels, the cache would stick on the first read and miss new sters until the kernel restarts.
Re-reading ~600 small CSVs per render is cheap enough that the optimization isn't worth the staleness risk.

### `--jobs 4` default for the bootstrap

Reason dropped: premature optimization.
The 30-minute one-time cost is acceptable.
Add `--jobs 4` only if it actually annoys someone.

### Feed only `Fit.headline()` (round 1 design)

Reason dropped: `comparison_table` reads `J_p`, `N`, `runtime_s`, `converged` directly off `fit.main.*`.
A cache that only short-circuits `headline()` would still trigger a full `load_fit()` per cell.
Cache must short-circuit `load_fit()` itself, which means carrying the diagnostic columns too.

## Open items and blockers

- Pipeline (PID 4864) is OFF.
  Killed at 24 h elapsed yesterday with ~50 min of work lost on `grc_IDN_cuu_maxexpsh_c1` (slot 9).
  When the user wants to relaunch, run `RP7/scripts/run_master_resume.do` from a fresh PowerShell `Start-Process -WindowStyle Hidden`.
  The 110 pre-fix cells plus the 545 cells from yesterday's resume work all stay on disk and will skip cleanly.
- Headlines cache plan is committed but no implementation work started.
  All implementation deferred to a fresh session per the user's request.
- The two fixes from 2026-05-08 (`assert_merge_clean` `asis` + Delta_avg scaling in `0_programs.do`, copyOverleaf filename in `8_learning.do`) are committed on this branch but not on `lca-inversion`.
  Eventual cherry-pick or merge is still owed.

## Picking back up

If you resume:

Read [quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md), then [the headlines-cache plan](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-09_headlines-cache.md).

Open thread: implementing the cache, starting from Step 0.

Next concrete actions, in priority order:

1. **Step 0: baseline + bottleneck profile.**
   Render the current dashboard once, save the output to `quality_reports/baselines/2026-05-09_pre-cache.html`.
   Profile the same render with `cProfile` (e.g., `python -m cProfile -o baseline.prof -m quarto render report.qmd --to html`, or wrap the qmd setup in a Python harness).
   Confirm `load_ster` (or `_cached_load_ster`) accounts for ≥80% of wall time.
   If a different function dominates (e.g. `_synthetic_fit_from_bank` rebuilding repeatedly, or `_load_rescaled` reconstructing the dict), pause and re-plan.
2. **Step 1: bootstrap.**
   Write [tools/results_overview/scrape_headlines.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape_headlines.py) with `--incremental` and `--jobs N` flags.
   Walk `RP7/output/*.ster`, call `load_ster()` per main + `_n` + `_a` + `_g` subgroup, write per-stem CSVs via `os.replace` atomic rename.
   Default `--jobs 1` (~30 min once).
   Verify idempotency by re-running and checking `git diff` is empty modulo `mtime` columns.
3. **Step 2: reader.**
   Rename existing `load_fit` to `_load_fit_live` in [tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py).
   Add `_load_headlines`, `_fit_from_cache_row`, `_same_mtime`, `EXPECTED_SCHEMA_VERSION`.
   Add the new cache-aware `load_fit()` wrapper.
   Re-render and compare against the step-0 baseline (bytes-identical modulo timestamps).
   Run [tools/results_overview/test_cache_equivalence.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/test_cache_equivalence.py) (N=20 random stems, headline values match within `rtol=1e-12`) as the gate.
4. **Step 3 (one-line wire-in): add `shell python ... --incremental` to the tail of `RP7/scripts/0_master.do` and `RP7/scripts/run_master_resume.do`.**
   No Stata code edits beyond that single line.

State to know:

- `MEMORY.md` flags `pip install pystata` as a known foot-gun.
  The bootstrap script's parallel workers (if `--jobs > 1`) must use the bundled `utilities/pystata/` from the Stata install, not a pip-installed copy.
- The `_load_rescaled` overlay for the 110 buggy `_g.ster` cells stays in place; the cache stores raw values and the rescale layer sits on top of both cache-hit and cache-miss paths.
- `Fit.diagnostics` does not exist; the plan exposes `J_p`/`N`/`runtime_s`/`converged` via `fit.main.*` attributes that `_fit_from_cache_row` populates directly.
- Today's commits (`0dc8737` plan revision, `54479f6` session log continuation) are on this branch and not pushed anywhere.
- Pipeline is OFF.
  No live Stata process to coordinate around during cache implementation.

with Claude
