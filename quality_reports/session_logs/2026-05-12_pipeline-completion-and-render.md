# 2026-05-12: pipeline completion + dashboard re-render

Short session covering the wrap-up of yesterday's three concurrent Stata runs and the dashboard re-render.
Yesterday's full context lives at [quality_reports/session_logs/2026-05-11_headlines-cache-shipped.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-11_headlines-cache-shipped.md), which is the right starting read for context.

## Goals

User checked in on the overnight runs, found all three completed, asked to re-render the dashboard, then wrap up to start a fresh session on the merge-readiness work.

## What got built or changed

[tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html) re-rendered with all 24 chunks populated.
2.6 MB, 33.2 second render time (matches the post-cache baseline).
Not committed.

Headlines cache extended from 219 to 273 stems via `scrape_headlines.py --incremental`.
The 54 new stems are the fits produced by the overnight runs (180 maxexpsh + 80 birth + 80 cnu sters across ~54 unique stems after de-duplication of shared cells).
Cache lives at [RP7/output/headlines/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/headlines).
Not committed.

## Decisions, with the why

### Did not refresh the cache before checking whether it needed refreshing

Initial reflex was to run `scrape_headlines.py --incremental` first.
User pushed back: the whole point of yesterday's cache work was that the dashboard renders fast without manual setup.
The actual situation was that the serial pipeline (PID 17480) finished 41 min before the user checked, and `0_master.do`'s tail had already called `scrape_headlines.py --incremental` at that point.
The slices (birth, cnu) finished hours earlier, so their sters were already on disk when the serial pipeline ran its scrape tail.
The cache WAS already fresh; the manual incremental call I started was redundant.
The redundant call was harmless (incremental, no-op on cached stems) but unnecessary.

### Did not commit the new report.html

Why: the rendered HTML is regenerable from the .ster files + cache + qmd source, and adding a 2.6 MB binary diff would be churn.
The .ster files and cache are what matter for reproducibility, and those are tracked.
If we want a "shipped" snapshot for a coauthor, we can commit on demand.

## Final pipeline state

All three runs completed successfully.
Ster counts on disk (with double-counting from family-token overlap collapsed):

| Family               | Sters | Target |
|----------------------|------:|-------:|
| maxexpsh             |   180 |    180 |
| birth                |    80 |     80 |
| IDN cnu x experience |    80 |     80 |
| **owed at session start** |  **340** | **340** |

Plus the 220 sters already on disk before the relaunch (exp + maxexp + expsh families): pipeline is now complete for `9_GRC_extras.do`.

## Open items

- **branch is ready for merge consideration.**
  All estimation results that gated the merge are now on disk.
  Three buckets identified yesterday:
  1. GRC pipeline refactor (22→13 do-files, run_master_resume entry point, Delta_avg sidecar rescaler).
     The branch's original scope; mergeable now that the rerun completed cleanly.
  2. Headlines cache infrastructure (commits `dc83443`, `ee1b8a6`).
     Purely additive, can merge anytime.
  3. Results-overview dashboard (~25 commits in `tools/results_overview/`, ~12k lines).
     Separate productivity infra, could be its own PR or land with the refactor.
- **Verify the `_load_rescaled` overlay only fires for the 110 pre-fix `_g.ster` cells.**
  The new fits from yesterday's run should carry corrected Delta_avg from birth (because they were fit AFTER cherry-pick `5cfe158`).
  Sanity check: open the dashboard, find a recently-fit cell, confirm no rescale indicator.
- **Two 2026-05-08 fixes cherry-picked to main and lca-inversion are not pushed.**
  Carried forward from yesterday.

## Picking back up

If you resume:

Read [quality_reports/session_logs/2026-05-12_pipeline-completion-and-render.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-12_pipeline-completion-and-render.md) then yesterday's log for context.

Open thread: branch is estimation-complete; user wants to work on (a) verifying the `_load_rescaled` overlay scope and (b) deciding what to merge into main next, in a fresh session.

Next concrete actions, in priority order:

1. **Verify the _load_rescaled overlay only fires for the 110 pre-fix `_g.ster` cells.**
   Method TBD next session.
   Could be: load dashboard, locate one of the new fits (e.g. `grc_IDN_cuu_maxexpsh_c2`), confirm rescale flag is not set.
   Or: inspect `tools/results_overview/compare.py` for the overlay logic and assert it only triggers on pre-fix mtimes.

2. **Plan the merge sequence.**
   GRC pipeline refactor is the branch's purpose and is now ready.
   Headlines cache infra and dashboard tooling could merge alongside, or land as separate PRs.
   The lca-inversion branch also carries the assert_merge_clean fix as of yesterday's cherry-pick.

State to know:

- Commits on `worktree-grc-pipeline-refactor`: 41 ahead of main.
  Most recent: `a6950a1` (session log), `b5c7e5a` (driver generalization), `b24b847` (initial slice drivers).
  None pushed.
- Commits on `main`: 2 ahead of origin (`a2f8312`, `b848115` --- yesterday's cherry-picks).
  Not pushed.
- Commits on `lca-inversion`: 2 ahead of origin (`3de8a76`, `c048a6d`).
  Not pushed.
- Headlines cache holds 273 stems at hash <not measured this session>.
- Rendered dashboard sits at [tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html), 2.6 MB, 24 chunks all populated.
- No live Stata processes (verified by `tasklist`).
- The three slice drivers exist on disk in generalized form (multi-user $dir + values toggle); they have not been re-run since generalization.

## Afternoon addendum: slice-bootstrap extract + rescaler audit

Resumed in afternoon to address open items from the morning wrap-up.

### Slice-driver parallelization write-up

Built [docs/parallelization-overview.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/parallelization-overview.html) describing how the master pipeline and three family slice drivers coordinate via `skip_if_exists` on the filesystem.
Flagged ~70 lines of duplicated post-`$dir` boilerplate across `run_extras_{maxexpsh,birth,cnu}.do`.

### "Can Stata find its own do-file's directory?" rabbit hole

Tested empirically (see `/c/temp/stata_include_test/`):

- Batch mode (`stata-mp -e do file.do`): `psutil.Process(os.getpid()).cmdline()` and Windows `GetCommandLineW()` both return the full launch command with the do-file path. So Python introspection works.
- Interactive mode (GUI, then `do "..."`): `c(filename)`, `$S_FN`, all candidate macros are empty during `do` execution. Stata exposes nothing. Confirmed via the MCP, which runs as a pystata kernel (interactive-like).

Decided NOT to use Python introspection for `$dir` resolution: it works for batch (Emilia), fails silently for coauthors in interactive mode (they don't run Stata in batch).
`cd`-to-scripts rejected as anti-pattern (DIME conventions).
Env var (`CKT_DIR`) considered but rejected as too much friction for coauthors who run from multiple machines.

Resulting decision: keep the `$dir` username block inline (status quo) and extract only the post-`$dir` envelope.
Flagged in the doc that "find do-file's directory" is a genuine Stata public-good gap; could be packaged as an .ado on SSC.
Not now.

### Implemented Change 2: 0_slice_bootstrap.do extract

Plan: [quality_reports/plans/2026-05-12_slice-bootstrap-extract.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-12_slice-bootstrap-extract.md).

Created [RP7/scripts/0_slice_bootstrap.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_slice_bootstrap.do) carrying: path_config include, programs include (quietly), `skip_if_exists=1`, `copyOverleaf=0`.
Refactored all three slice drivers to call it after their inline `$dir` block.

Verified by running `run_extras_birth.do` via `stata-mp -e`: 16/16 cells skipped (all already on disk), no fresh GMM fits, `rc=0`, log closed clean.

Commits: `12ae1cc` (docs + plan), `d80bfa0` (bootstrap + driver refactor).

### Spot-check on `_load_rescaled` overlay (the morning open item)

The new families fit yesterday (`maxexpsh`, `birth`, `cnu × experience`) do not appear in `delta_avg_rescaled.csv` at all (grep returned 0).
So `_load_rescaled().get(stem)` returns None for any of them; the substitution branch is bypassed; overlay cannot fire.
Spot-check resolves trivially without loading a single ster.

### Discovery: the rescaler is NOT yet a one-time patch

While walking through cleanup ("if it was a one-time patch, can we delete it?"), reconstructed the timeline:

- 2026-04-30: `5cfe158` fixed `Delta_avg` formula on `lca-inversion` branch.
- 2026-05-07 22:31 -- 2026-05-08 11:25: 110 main-GRC + hukou cells re-fit on this branch using OLD buggy `0_programs.do` (the fix wasn't merged into this branch yet).
- 2026-05-08 12:27: sidecar CSV generated as a workaround.
- 2026-05-08 12:44: `82766d2` -- the formula fix actually landed in `0_programs.do` on THIS branch.

So the 110 `_g.ster` files have buggy `Delta_avg` on disk; the rescaler is currently load-bearing.
Yanking the sidecar today would silently show wrong numbers for the entire main GRC table set across CHN/IDN/TZA + hukou variants.

Cleanup is two-step:

1. Re-fit the 110 cells with the now-correct `0_programs.do`.
2. Then delete `fix_delta_avg_scaling.do`, `delta_avg_rescaled.csv`, and the `_load_rescaled`/`DELTA_RESCALED_CSV` block in `tools/results_overview/compare.py`.

Pending user decision on whether to kick off the re-fit now (~1-3 hours wall), overnight, or defer until after merge.

## Late-afternoon addendum: refit launched, more cleanup, key Stata finding

### Refit kicked off

User chose option A (kick off now, parallel work meanwhile).
Moved all 550 sters for the 110 rescale CSV estnames to [RP7/output/\_pre\_fix\_backup\_82766d2/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/_pre_fix_backup_82766d2) (reversible).
Launched `stata-mp -e do run_master_resume.do` in background (PID 33472, 09:45).
Spot-checked first completed cell `grc_IDN_cuu_c0`: on-disk Delta_avg matches CSV's `b_rescaled` to machine epsilon (`0.3810670249710334` vs `0.3810670249710419`).
Confirms the formula fix in `0_programs.do` (commit `82766d2`) produces the same value as the analytical rescaling.

### Push cherry-picks; analyze merge plan

Pushed `origin/main` and `origin/lca-inversion` so the two formula-fix cherry-picks (`a2f8312`, `3de8a76`, plus the `8_learning.do` filename fix) are no longer dangling.
The PR for this branch will land on top of cherry-pick-aware main; reviewers won't see duplicate "Delta_avg formula fix" surface.

User chose PR shape:
- **PR-1** (pipeline refactor + rescaler cleanup): this branch's original purpose.
  Rescaler infra (CSV, `fix_delta_avg_scaling.do`, `compare.py` overlay) is born-and-dies on this branch --- never reaches main, no separate PR.
- **PR-2** (headlines cache + dashboard tooling): purely additive, ships with the default-off `$runDashboard` switch so coauthors don't need Quarto/Python.

PR-1 description drafted at [quality\_reports/plans/2026-05-12\_pr1-pipeline-refactor.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-12_pr1-pipeline-refactor.md).

### Python dependency audit

Only two `shell python` calls in the entire pipeline:
- `scrape_headlines.py` at the tail of `0_master.do` (dashboard cache).
- `gen_verdier_comparison.py` at the tail of `17_verdier_robust.do` (review-memo).

Both produce non-paper artifacts.
Coauthors do not need Python to get paper tables/figures/sters.
Added `$runDashboard 0` switch to `0_master.do` (mirrors `$copyOverleaf` pattern); gates both Python calls.
Commit `43ab63d`.

### Dev-artifact purge (e)

Audited remaining 13+ `.do` files in `RP7/scripts/` for duplication.
The bigger find: 10 smoke/peek dev-artifact drivers from Phase 1a/1b/M11 refactor checkpoints, all stale, all referencing past phases.
`_smoke_4_GrRC.do`'s header literally says "Do NOT save this file to the production master pipeline."
`smoke_17_TZA.do` pointed to the wrong worktree.
Deleted all 10 (commit `abbaa14`); updated `0_master.do` and `0_path_config.do` comments that referenced `_smoke_full.do` to point to the live `run_extras_*.do` slice drivers instead.

### 17\_verdier\_robust.do alignment

Several small fixes:
- Wrong-worktree path in the inline `$dir` block (commit `a8ed9b7`): pointed to `verdier-wrap-up/RP7` instead of this worktree.
  Latent footgun for standalone launches.
- User pushed for "remove the inline `$dir` block since that's how everything else gets run (from within master)" --- removed entire `if "$dir" == ""` setup block, replaced with single guard that errors if `$dir` unset (commit `a86a246`).
- Trimmed redundant "meant to be run as include" comment per user (part of commit `896d482`).

### Slice driver boilerplate trim

Each slice driver carried a 5-line `$dir`-not-set guard that duplicated the one inside `0_slice_bootstrap.do`.
Removed the slice-local guards; hardened the bootstrap's message to name the user and point to `0_master.do`.
Also trimmed the verbose "values switch (M4)" and "$dir resolution per user" intro comments.
Net: -54 lines across 5 files, behavior unchanged.
Commit `896d482`.
Smoke-tested `run_extras_birth.do`: 16/16 cells skipped, clean rc=0.

### KEY FINDING: Stata pre-loads `include`d files

User pushed back on my assumption that mid-refit edits to included files would take effect when the running refit reached the include statement.
I tested empirically (in `/c/temp/stata_include_timing/`):

- `test_main.do` sleeps 8 seconds, then `include "test_inc.do"`.
- Launch Stata; at t=3, edit `test_inc.do` on disk from "ORIGINAL CONTENT" to "MODIFIED CONTENT".
- At t=8, include statement executes.
- Stata log shows **"ORIGINAL CONTENT"**.

Conclusion: Stata reads included files at parse time (or via aggressive filesystem caching --- observable behavior is identical), not at execution time.
**Mid-execution edits to `include`d files do NOT propagate to the running do-file.**
This is a load-bearing fact for any future hot-edit scenario.

Implications for the current refit:
- My recent edits to `0_master.do`, `17_verdier_robust.do`, `0_path_config.do` since the 09:45 launch are invisible to PID 33472.
- The `$runDashboard 0` gate does NOT prevent this refit from running `scrape_headlines.py` at the tail.
- The verdier early-exit (commit `28a74f2`) does NOT skip verdier in this refit.
- This is also reassuring: my mid-refit edits couldn't have broken the running refit because they don't reach it.

### Refit slowness + orphan Stata

User noticed the refit is much slower than expected.
Investigation:
- One cell (`grc_IDN_cuu_ct`) took **52 minutes** (`fit in 3113.96 sec`).
- Currently on `grc_IDN_cuu_c1`, mid-step-2 GMM, ~35 min in.
- 2 of 110 cells refit after ~2.5 hours.
- Original fit rate was ~7 min/cell; current rate is 5-10x slower.
- Stata CPU is active (~3 hours of CPU time over 2.5 hours of wall) --- not hung.

Likely culprit: an orphan `StataMP-64.exe` (PID 37364, 1.8 GB resident) from my earlier slice driver smoke test that didn't release memory after exiting cleanly.
Possible memory pressure on the refit.

Pending user decision: kill PID 33472 (refit) + PID 37364 (orphan) and relaunch, which would:
- Lose ~2.5 hours of progress (mostly data prep + OLS + 2 GRC cells)
- Free 1.8 GB RAM
- Apply all current commits (verdier skip, runDashboard gate)
- Honor the "leave verdier for later" instruction

Versus letting it run, which means verdier runs as part of the pipeline (against user's request) and the slow pace continues.

### Where things stand

- Branch is 49 ahead of main (was 41 at start of session).
- 8 new commits this session.
- 1 dev-doc commit, 6 refactor/cleanup commits, 1 temporary skip commit (`28a74f2`, which doesn't take effect this refit; remove before merge regardless).
- `RP7/scripts/` now has 24 `.do` files (down from 34).
- Slice drivers shrunk to 65/65/73 lines.
- Refit still running; outcome pending.

## Final wrap-up: refit killed for clean relaunch

User chose to kill the slow refit and relaunch in a fresh session context so the verdier early-exit (commit `28a74f2`) and `runDashboard=0` gate (commit `43ab63d`) take effect.
Per the empirical pre-load finding above, these only apply when Stata reads the do-files at launch time.
The killed refit had launched at 09:45 with the pre-commit versions, so neither switch was active for it.

### State at kill

- Killed `StataMP-64.exe` PID 33472 at approximately 12:34 via `Stop-Process -Id 33472 -Force`.
- 3 of 110 cells refit cleanly: `grc_IDN_cuu_c0`, `grc_IDN_cuu_ct`, `grc_IDN_cuu_c1`.
- Refit was mid-fit on `grc_IDN_cuu_c2` (twostep GMM, step 2, iteration 6 with Q(b) creeping near 0.00036) when killed.
- 107 cells still need refitting.
- Buggy sters preserved in [RP7/output/\_pre\_fix\_backup\_82766d2/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/_pre_fix_backup_82766d2) (550 files).
  Delete only after refit completes and `_g.ster` values are verified to match `delta_avg_rescaled.csv`'s `b_rescaled` column.

### Why kill rather than let it finish

Three reasons stacked up:

1. Per-cell pace was 50+ minutes for IDN cuu cells, projecting many hours of compute that may have continued unevenly across cells.
2. The original "leave verdier for later" decision could not be honored without a relaunch, because Stata pre-loads do-files.
3. The killed cells (`c0`, `ct`, `c1`) are already on disk and verified correct, so a relaunched refit picks up at cell `c2` via `skip_if_exists=1`.
   Lost work is bounded.

### Picking back up

**If you resume:**

Read [quality\_reports/session\_logs/2026-05-12\_pipeline-completion-and-render.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-12_pipeline-completion-and-render.md) (this file) first.
Skim from "Late-afternoon addendum" onward; earlier sections are about pre-refit setup.

**Open thread:** the Delta\_avg formula refit is partly done (3 of 110 cells), needs to be relaunched and run to completion before the rescaler-cleanup PR can land.

**Next concrete action:**

1. Run `cd RP7/scripts && stata-mp -e do run_master_resume.do` in the background.
   This time, all current commits are loaded at launch:
   the verdier early-exit fires so `17_verdier_robust.do` is skipped, and the `$runDashboard 0` global gates the shell python at the tail.
2. Monitor the log at `RP7/scripts/run_master_resume.log` for progress.
   Time estimate is uncertain because per-cell times varied widely in this session.
3. When refit completes, manually run `python tools/results_overview/scrape_headlines.py --incremental` to refresh the dashboard cache.

**Then, the rescaler cleanup (drafted, ready to apply once refit verifies):**

Files to remove via `git rm`:

- [RP7/scripts/fix\_delta\_avg\_scaling.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/fix_delta_avg_scaling.do)
- [RP7/output/delta\_avg\_rescaled.csv](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/delta_avg_rescaled.csv)

Plus edit [tools/results\_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py):

- Delete lines 78-106 (the `DELTA_RESCALED_CSV` constant, `_cached_rescaled`, `_load_rescaled`, and the comment block).
- Delete lines 265-271 in `Fit.headline()` (the rescaled substitution block).
- `lru_cache` and `pandas` imports stay --- used elsewhere.

Also: remove the temporary verdier early-exit (commit `28a74f2`) before opening PR-1.
This is the six lines under `* TEMPORARY: skip verdier in the 2026-05-12 refit` in `17_verdier_robust.do`.

### State to know

- Branch: `worktree-grc-pipeline-refactor`, 49 commits ahead of `main`.
- Today's commits (in order): `12ae1cc`, `d80bfa0`, `43ab63d`, `abbaa14`, `a8ed9b7`, `a86a246`, `896d482`, `28a74f2`.
- `main` and `lca-inversion` have been pushed to origin; the 2026-05-11 cherry-picks are on the remote.
- No `StataMP-64.exe` processes are owned by this project after the kill.
  PID 37364 visible in process listings is from an unrelated project, per the user; ignore.
- 3 cells in `RP7/output/` are post-fix correct.
  107 cells are missing (deleted to backup); `run_master_resume.do` will refit them on relaunch.
- PR-1 description ready at [quality\_reports/plans/2026-05-12\_pr1-pipeline-refactor.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/plans/2026-05-12_pr1-pipeline-refactor.md); edit before opening.
- Parallelization write-up at [docs/parallelization-overview.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/parallelization-overview.html); useful background read but the slice-bootstrap section is now stale (drivers were further trimmed after that doc).
- PR-2 (headlines cache + dashboard tooling) still needs its own description draft.
  Scope catalog is in the body of this log above ("Dashboard PR scope catalog").

### Decisions to remember across the session boundary

- The rescaler infrastructure (CSV + `fix_delta_avg_scaling.do` + overlay) is born-and-dies on this branch.
  No separate PR.
  Deletion is one of the final commits before opening PR-1.
- `$runDashboard 0` is the coauthor-safe default.
  Emilia can either set it to 1 in her local copy or run `scrape_headlines.py` manually.
  Same for `gen_verdier_comparison.py` (the verdier comparison memo).
- The 9 deleted smoke drivers + `_peek_runtime.do` were Phase 1a/1b/M11 dev artifacts.
  Git history preserves them.
  If a fresh smoke is needed in the future, the slice-driver template plus `0_slice_bootstrap.do` produces one in 25 lines.
- Stata pre-loads included files at parse time (empirically confirmed this session).
  Future "edit while running" plans should account for this.

with Claude
