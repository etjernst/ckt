# 2026-05-09: pipeline watch + parallelization planning

## Goal

Two threads, both downstream of the long-running resume run launched 2026-05-08 12:28 (PID 4864):

1. Re-render the dashboard once enough of `9_GRC_extras.do` has produced sters that previously-failing chunks start populating.
2. Think through whether and how to parallelize the remaining ~32 h of serial work in `9_GRC_extras.do` to shorten the wall-clock ETA.

## State at session start

Pipeline (PID 4864) had been running ~9 h.
Family `exp` complete; just entered `maxexp`.
36 of 44 stems still pending across families `maxexp`, `expsh`, `maxexpsh`, plus IDN cnu sub-block and IDN birth dispatcher.

## What changed

### Dashboard re-rendered with experience-family tables

[tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html).
Re-rendered after family `exp` completed.
The five family-extras chunks that previously rendered as inline tracebacks now produce comparison tables for `experience`; the four other extras families (`maxexp`, `expsh`, `maxexpsh`, `birth`) still show tracebacks until their sters land.
Committed as `7c4c5aa`.

### Parallelization planning document

[quality_reports/plans/2026-05-09_parallelization-options.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-09_parallelization-options.html).
Self-contained HTML with embedded SVG, no external dependencies.
Three plans laid out side-by-side as Gantt charts:

- Plan A: 2 new instances (cnu + birth). 32 h --> 13 h critical path.
- Plan B: 3 new instances (adds maxexpsh slice). Same 13 h floor but PID 4864 wraps in 3.5 h instead of 11 h.
- Plan C: 6 new instances (split birth and maxexpsh by stem). 8 h critical path, set by IDN cnu.

Sections: cell timing intuition (IDN cuu eats 47% of family time), current-state Gantt, three plan Gantts, mechanism diagram (`${skip_if_exists}` is the lever), risks table, open questions about `9_GRC_extras.do` structure that gate implementation.

## Decisions, with the why

### Plan only, no implementation

Why: the user explicitly asked to think and plan first.
The HTML is a decision artifact for the human to chew on, not a launch script.
Once the user picks a plan, three reads of `9_GRC_extras.do` (family-block contiguity, log-path global, cross-family dependencies) settle the implementation details.

### Did not over-defend the "concurrent ster write" risk in v1

Why (post-hoc correction): the user pushed back that with disjoint slices and `skip_if_exists` everywhere, two instances writing the same ster is impossible by construction.
Correct.
The actual race is timing-based: PID 4864 walks through every family in order and could enter a parallel-handled family before that instance has finished, hitting cells the parallel instance is currently fitting.
Two clean fixes: kill PID 4864 at the partition boundary, or split the parallel slices fine enough that they finish before PID 4864 catches up.
The HTML still says "atomic writes mitigate it" --- left in for now since user said "leave it for now or revise"; deferred.

## Approaches rejected

### Cell-level parallelization

Reason dropped: data setup and program loading repeat for every cell, eating the gains.
Stem-level is the natural unit.

### Killing and restarting PID 4864 to slice it cleanly

Reason deferred: PID 4864 is already deep into expsh and would lose the ~4 h of work it has done in the current family.
Cheaper to let it keep going on what it is currently doing and partition the not-yet-started work to new instances.

## Open items

- Pipeline still detached as PID 4864 (now 24.0 h elapsed).
  Just entered family `maxexpsh` at slot 9.
  Serial ETA from now: late 2026-05-10 to early 2026-05-11.
- Parallelization plan is sitting on the user's desk; no implementation triggered yet.
- The "atomic writes" framing in the HTML risks table is technically true but secondary to the real race condition (timing).
  Worth revising if the user picks any plan and we do the implementation pass.

## Picking back up

If parallel runs get launched in the next session:

1. Confirm `9_GRC_extras.do` block structure (3 reads should settle it).
2. Write per-family slice drivers under `RP7/scripts/run_extras_<family>.do` that source `0_path_config.do` + `0_programs.do`, set a per-instance log name, set `global skip_if_exists 1`, and `include` only the target family's block.
3. Launch via PowerShell `Start-Process -WindowStyle Hidden`, capture PID for tracking.
4. Combined progress monitor: count `RP7/output/*.ster` written since launch, broken down by family stem.

If the run finishes before parallelization is implemented:

1. Re-render the dashboard --- all 24 chunks should populate.
2. Verify the rescaled Delta_avg override only fires for the 110 pre-fix cells (new cells from this run carry corrected values from birth).
3. Decide what to commit / merge with `lca-inversion`.

with Claude

---

## Continuation: pipeline killed + headlines cache plan (afternoon)

User asked to kill the long-running pipeline (laptop running hot) and re-render the dashboard.
Then noted the dashboard render itself is slow and asked to think about alternative rendering approaches.

### What changed

[PID 4864 killed at 24 h elapsed](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.log).
Lost ~50 min of work on `grc_IDN_cuu_maxexpsh_c1` (slot 9 of the maxexpsh family).
The 110 pre-fix `_g.ster` cells from the original run plus the 545 cells from the resume's `9_GRC_extras` work (families exp + maxexp + most of expsh) all stay on disk.

[quality_reports/plans/2026-05-09_headlines-cache.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-09_headlines-cache.md).
New planning doc: cache the ~10 numbers per stem that the dashboard actually displays into per-stem CSVs under `RP7/output/headlines/`.
Render-time pystata round-trips become a single `pd.read_csv` directory walk.
Three rounds of critic review applied:

- Round 1 (after initial draft): caught 3 Reds --- schema too narrow (didn't cover the J_p / N / runtime / converged that comparison_table reads off `fit.main`), Stata writer call sites under-specified, false atomicity claim from Stata's `copy ..., replace`.
- Round 2 (after R1 fixes): caught Yellows about `_load_fit_live` rename, line-target precision, parallelization, mtime tolerance, manifest-read in Stata.
- Round 3 (instructed to bias toward simplicity, fresh context): the breakthrough --- pushed back against over-engineering. Top simplifications: drop the in-Stata writer entirely (Step 3) in favor of a `--incremental` flag on the Python bootstrap; drop the manifest sidecar in favor of a `schema_version` column; drop the `source` provenance column; replace mtime tolerance with exact comparison via per-row source mtimes.

### Decisions, with the why

Three rounds of critic review on the same plan.
Why: each round caught a different layer.
Round 1 found structural bugs.
Round 2 found implementation precision gaps.
Round 3 (with explicit anti-overcomplication framing) found the over-engineering --- two writers when one suffices, manifest when a row column suffices, source provenance when no caller uses it.
The third round's verdict ("scope drops by half, dashboard still gets fast") is the cleanest version of the plan.

User's bigger-picture catch: agreed it's true that Stata can `, append` results into a single ster, so the 5-ster-per-fit structure is not architecturally forced.
Decided not to redesign the pipeline around it (out of scope for this branch); just noted it.

### Approaches rejected

In-Stata writer for cache rows.
Reason dropped (round 3): touches 5 Stata estimator programs at multiple capture windows each, requires a Stata-side schema mirror, requires `capture noisily` defenses --- all to avoid running a Python script after each fit batch.
Replaced with `! python tools/results_overview/scrape_headlines.py --incremental` wired into `0_master.do`'s tail; one line, recovers most of the autosync benefit at a fraction of the complexity.

Per-stem manifest with version, columns, written_at, writer.
Reason dropped (round 3): only `schema_version` was functionally used; the rest was decorative.
Replaced with `schema_version` as a row column.

`source = "ster" | "bank"` provenance column.
Reason dropped (round 3): nothing in the read path uses it for behavior.
The `_r` synthetic-bank case can stay entirely in the existing `_load_fit_live` fallback.

### Open items

- Plan revisions from round 3 not yet applied to the file (user has the review and asked "what do you think").
  My answer: yes, apply --- the simplifications all earn their keep and the one downside (Step 3 drop means user has to wire the incremental bootstrap into `0_master.do`'s tail) is one line.
- Pipeline is OFF.
  When the user wants to relaunch it, the plan to do that is to re-run `RP7/scripts/run_master_resume.do` after applying the cache plan.
  All cache benefits will start applying on the next render.

### Picking back up

Apply the round-3 simplifications to [the headlines cache plan](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-09_headlines-cache.md), then start implementing.
Step 0 (baseline render + cProfile to confirm `load_ster` is the bottleneck) is the first concrete move.
Then Step 1 (`scrape_headlines.py` + `--incremental`), Step 2 (cache-aware `load_fit` + `_fit_from_cache_row` + the equivalence test), then re-render and verify identical headline values.
No Step 3.

with Claude

