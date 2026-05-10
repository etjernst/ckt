# 2026-05-11: headlines cache shipped, gitignore flipped

Short session, mostly verification and one course correction on top of yesterday's implementation.
The bulk of the cache work happened on 2026-05-10 (Steps 0--3 of the round-3 plan) and is logged at [quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md).

## Goals

User picked up the cache plan in a fresh session asking to start Step 0.
By end of yesterday's session we shipped Steps 0--3 in commit `dc83443`.
Today the open thread was: confirm full-cache idempotency at scale; address user's pushback on two decisions I'd made (the resume-script wire-in, and the headlines gitignore); and wrap up.

## What got built or changed

[.gitignore](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/.gitignore).
Removed the `RP7/output/headlines/` ignore line and replaced it with a comment explaining why the CSVs are tracked.

[RP7/output/headlines/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/headlines).
219 cache CSVs added to git in commit `ee1b8a6` (~140 KB total, 632 bytes each).
Future re-fits will produce per-cell diffs showing which headline values moved.

No code changes today.

## Decisions, with the why

### Track `RP7/output/headlines/` in git (reversed yesterday's gitignore)

Why: user pointed out that the whole point of writing these as text CSVs is that they ARE version-controllable, unlike binary `.ster` files which git can only treat as opaque blobs.
A re-fit batch will now produce a per-cell git diff showing which estimates moved by how much --- exactly the signal that's invisible when staring at a 2.6 MB rendered HTML.
The plan's "tracking creates per-fit churn that pollutes diffs without adding signal" argument was wrong on the second clause: the churn IS the signal.

### Did NOT add the scrape line to `run_master_resume.do`

Why: `run_master_resume.do` is just `do "0_master.do"`, so it inherits the new tail automatically.
Adding the line a second time inside the resume script would scrape the cache twice per resume run --- the second pass is a fast `--incremental` no-op, but it's pointless work and clutter.
User confirmed they were fine leaving it as-is.

### Full-cache idempotency verified empirically rather than declared from the single-file proof

Why: even though the single-stem byte-identical proof established the writer is per-file deterministic, the user-facing claim "the cache rebuilds bit-for-bit" benefits from a 219-file hash check at scale.
Took ~30 min in the background; pre- and post-rerun cache hashes matched (`f066b43576784bba658be1ae7747904d`).
Now I can say it with no caveats.

## Approaches rejected and the reason

### Not adopted: parallel `--jobs 4` bootstrap default

Reason dropped: the plan already rejected this on premature-optimization grounds and the 30-minute one-time bootstrap turned out to be only ~12 min in practice.
Flag stays available for anyone who finds it annoying.

### Not added: post-cache cProfile to confirm no other bottleneck emerged

Reason dropped (deferred): the 37-second render is fast enough that the question "what dominates now?" has no urgency.
Listed as an open item for the next session if the user wants to push further or audit the new shape.

## Open items and blockers

- **Post-cache profile not run yet.**
  The pre-cache memo at [quality_reports/baselines/2026-05-09_pre-cache_profile.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/baselines/2026-05-09_pre-cache_profile.md) lists `_synthetic_fit_from_bank`, `_load_rescaled`, and pandas `comparison_table` ops as the most likely new dominators if the cache is working but render time is still off.
  Profile is cheap; do this before declaring the cache fully audited.

- **The two fixes from 2026-05-08** (`assert_merge_clean` `asis` + Delta_avg scaling in `0_programs.do`, `copyOverleaf` filename in `8_learning.do`) are committed on this branch but not on `lca-inversion`.
  Cherry-pick or merge still owed.
  Carried forward from yesterday's log.

- **Pipeline is still OFF.**
  No live Stata process to coordinate around.
  Carried forward from yesterday's log.

- **`--jobs N` default of 1.**
  Defensible today.
  Revisit only if someone is actually annoyed by the 12--30 min one-time bootstrap.

## Picking back up

If you resume:

Read [quality_reports/session_logs/2026-05-11_headlines-cache-shipped.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-11_headlines-cache-shipped.md), then [quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-10_headlines-cache-plan-converged.md) for the implementation context.

Open thread: the cache is shipped, verified, and tracked.
The next move is either an audit pass (post-cache profile) or moving on to a different work item.

Next concrete actions, in priority order:

1. **Run a post-cache profile.**
   `cd tools/results_overview && python -m cProfile -o profile_render_postcache.prof profile_render.py`, then `python -c "import pstats; pstats.Stats('profile_render_postcache.prof').strip_dirs().sort_stats('cumulative').print_stats(25)"`.
   Confirm the new bottleneck (if any) and decide whether to act on it.
   Compare against the pre-cache profile at [tools/results_overview/profile_render.prof](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/profile_render.prof).

2. **End-to-end test the master-script tail.**
   The `shell python ... --incremental` line in [RP7/scripts/0_master.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_master.do) was sanity-checked from the shell directly, but not yet through a real Stata batch run.
   Run a `_smoke_master.do` (or trigger any cell that re-fits a ster) and confirm the tail fires and the CSV updates.

3. **Cherry-pick / merge the 2026-05-08 fixes into `lca-inversion`.**
   `assert_merge_clean` `asis` + Delta_avg scaling fix in `0_programs.do`, and the `copyOverleaf` filename fix in `8_learning.do`.
   Both are on `worktree-grc-pipeline-refactor` and have been owed for a few days now.

4. **Consider raising `--jobs` default** if the one-time bootstrap cost becomes friction for any coauthor who clones fresh.
   Not urgent.

State to know:

- Commits `dc83443` (cache implementation) and `ee1b8a6` (track CSVs) are on `worktree-grc-pipeline-refactor`; not pushed.
- Cache is fully populated (219 stems) and tracked in git.
- Hash of the cache as of session end: `f066b43576784bba658be1ae7747904d`.
- The `_load_rescaled` overlay for the 110 buggy `_g.ster` cells sits one layer above the cache and runs identically on both cache-hit and cache-miss paths.
  No interaction work owed there.
- Dashboard renders in ~37 s vs. the ~12 min pre-cache baseline.

with Claude
