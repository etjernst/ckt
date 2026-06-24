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

---

## Continuation: pipeline relaunch + parallelization slice drivers (afternoon)

User asked "where did we left off", I summarized the four open threads from the morning log, and user pushed back that we have unfinished estimation results that should be the top priority.
They were right --- the 2026-05-09 resume run was killed at 24 h elapsed with ~50 min of work lost on `grc_IDN_cuu_maxexpsh_c1`, and `maxexpsh`, `IDN cnu x experience`, and `birth` families had never finished.
The morning hand-off had buried this under audit busy-work.

### State on disk before relaunch

| Family               | Sters | Fits done | Owed |
|----------------------|------:|----------:|-----:|
| `exp`                |  180  |  36/36    | 0    |
| `maxexp`             |  180  |  36/36    | 0    |
| `expsh`              |  180  |  36/36    | 0    |
| `maxexpsh`           |    5  |   1/36    | 35   |
| IDN cnu x experience |    0  |   0/16    | 16   |
| birth (urbanbirth)   |    0  |   0/16    | 16   |
| **total owed**       |       |           | **67** |

The 25 `grc_IDN_cnu_*.ster` files on disk are from base GRC (c0/c1/c2/ca/ct cols, no extras token in name), not from the IDN cnu x experience block.

### What got built

Three family-slice drivers in [RP7/scripts/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts):

- [run_extras_maxexpsh.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_maxexpsh.do) --- 9 stems x 4 cols (IDN cuu dominates wall-clock).
- [run_extras_cnu.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_cnu.do) --- IDN cnu x {exp, exp_max, exp_share, exp_max_share}, 4 stems x 4 cols.
- [run_extras_birth.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do) --- IDN x {cuu, cub, iuu, cnu} x urbanbirth, 4 stems x 4 cols.

Each follows the established `_smoke_extras_one.do` pattern: `$dir` block matching `0_master.do`, `include 0_path_config.do`, `quietly include 0_programs.do`, `global skip_if_exists 1`, `global copyOverleaf 0`, per-driver log under `$logs/`, body wrapped in `capture noisily`, `exit, STATA clear` (harmless under `-e`).

### Decisions, with the why

#### Launched the serial resume FIRST, then wrote drivers, then launched the safe two parallel slices

Why: user wanted to get the long-running estimation in flight immediately and only THEN spin up parallel work.
Sequencing the launches lets the serial resume cover all owed families if the slice drivers misbehave; the slices are pure speed-up insurance.

Serial resume launched at ~14:35 via `Start-Process StataMP-64.exe /e do run_master_resume.do`, captured as PID 17480.
Confirmed alive (log populating, 1_processData rebuilding the .dta files, then into 9_GRC_extras).

#### Option 2: launched birth and cnu slices, NOT maxexpsh

Why: `9_GRC_extras.do` runs families in fixed order --- exp -> maxexp -> expsh -> maxexpsh -> IDN cnu -> birth.
PID 17480 will reach `maxexpsh` within minutes (already inside `9_GRC_extras.do` at the time slices launched), so a parallel `maxexpsh` slice would race directly against it.
`birth` and `cnu` are positions 5 and 6 of 6 --- PID 17480 won't reach them for hours, so the slices finish long before the serial pipeline arrives.
Zero race window, strict speed-up.
A parallel maxexpsh slice would need PID 17480 killed first (Plan B) to be safe; deferred.

Birth slice PID 42328, cnu slice PID 4420. Both confirmed mid-fit on first cell (`grc_IDN_cuu_urbanbirth_c1` and `grc_IDN_cnu_exp_c1`) within 30 s of launch.

#### Three drivers instead of one combined "run_all_remaining" driver

Why: fine-grained partition lets the user re-launch one slice without re-running the others if any single slice fails or needs re-running.
Also lets PID 17480 plus N slices coexist with disjoint cell sets, which is the whole point of family-level partitioning.

### Approaches rejected

#### Plan A (Plan A from 2026-05-09 HTML): same as what we shipped

The 2026-05-09 plan called this "Plan A: 2 new instances (cnu + birth), 32 h -> 13 h critical path".
This is what we launched.
Not rejected --- adopted.

#### Plan B: kill PID 17480 and launch all three slices

Reason deferred: kills 30 min of in-flight serial work for ~2 h wall-clock saving.
Not worth the disruption when option 2 already gets us a strict speed-up at zero risk.

#### Plan C: split maxexpsh and birth by stem across 6 instances

Reason deferred: 8 h vs 11 h critical path saves ~3 h but multiplies coordination surface 6x.
Not worth it for a one-time relaunch.

### Open items

- **Three pipelines in flight.**
  Serial (17480) ETA ~11 h on the critical path through maxexpsh.
  Birth (42328) ETA ~2--3 h.
  Cnu (4420) ETA ~2--3 h.
- **`maxexpsh` slice driver exists but is NOT launched.**
  Sitting dormant.
  If PID 17480 dies mid-maxexpsh, can launch the slice to finish the family without rerunning the whole 0_master.
- **`tier2_diffs/` directory** (untracked, dated 2026-05-04) is sitting in `RP7/output/`.
  Not touched by today's work.
  Owed: decide whether to commit or remove on a future pass.
- The 2026-05-08 fixes (assert_merge_clean `asis` + Delta_avg scaling; copyOverleaf filename) still owed to `lca-inversion`.
  Carried forward unchanged.

### Picking back up

Check on the three running processes first:

```powershell
tasklist /FI "IMAGENAME eq StataMP-64.exe"
```

Expected: PIDs 17480, 42328, 4420 still alive (plus 8144 which is unrelated cross-worktree work).

Tail any log to see current cell:

```powershell
Get-Content RP7/scripts/logs/run_extras_birth.log -Tail 20
Get-Content RP7/scripts/logs/run_extras_cnu.log -Tail 20
Get-Content RP7/scripts/run_master_resume.log -Tail 20
```

Count sters by family to gauge progress:

```powershell
Get-ChildItem RP7/output -Filter 'grc_*_maxexpsh_*.ster' | Measure-Object | Select-Object Count
Get-ChildItem RP7/output -Filter 'grc_IDN_cnu_*_*.ster' | Where-Object Name -match '_(exp|maxexp|expsh|maxexpsh)_' | Measure-Object | Select-Object Count
Get-ChildItem RP7/output -Filter 'grc_*_urbanbirth_*.ster' | Measure-Object | Select-Object Count
```

Target totals: maxexpsh = 180, IDN cnu x experience = 80, birth = 80.

When everything finishes, re-render the dashboard --- all 24 chunks should populate cleanly:

```bash
cd tools/results_overview && python render_results.py
```

with Claude

---

## Continuation: cherry-picks, tier2_diffs cleanup, slice-driver generalization (evening)

User came back to the session and asked what else could be worked on while the pipelines run, plus what should be merged into main soon.

### Goals

1. Triage the 39 commits on this branch into what could land on main vs. main-blocked-by-pipeline.
2. Cherry-pick the two 2026-05-08 methodology fixes into both `main` and `lca-inversion`. User explicitly said both, not one or the other.
3. Decide what to do with the `RP7/output/tier2_diffs/` directory (untracked since 2026-05-04, purpose unclear).
4. Run `review-dofile` on the three slice drivers written this afternoon.
5. After review feedback flagged hardcoded paths, user asked to generalize the drivers to mirror `0_master.do`'s multi-user setup, with a particular eye to reusing them for real-values reruns.

User explicitly rejected writing a merge-strategy planning doc as overcomplicating things.

### What got built or changed

[RP7/scripts/run_extras_maxexpsh.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_maxexpsh.do), [RP7/scripts/run_extras_cnu.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_cnu.do), [RP7/scripts/run_extras_birth.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do).
Rewritten from single-user maand-only stubs into proper portable drivers.
Each now has the full multi-user `$dir` block from `0_master.do` (kleemans, David, ecenci, etje0002, maand), an explicit `global values "nominal"` at the top with a comment block explaining the M4 nominal/real toggle, log filenames suffixed with `$vsfx` so the two modes do not clobber, and inline comments on what every global and every include does.
Commit `b5c7e5a`.

`RP7/output/tier2_diffs/` directory deleted (53 dry-run `.tex.diff` files from 2026-05-02--2026-05-04 that were flagged as "needs deletion" in the 2026-05-04 wrap-up but never removed).
Not committed (the dir was untracked).

`main` branch (worktree at `C:/git/ckt`).
Cherry-picked `82766d2` (assert_merge_clean asis + Delta_avg formula fixes) as `a2f8312` and `21b6e22` (8_learning.do copyOverleaf filename) as `b848115`.
Both applied clean.
Not pushed.

`lca-inversion` branch (worktree at `C:/git/ckt/.claude/worktrees/lca-inversion`).
Cherry-picked the same two commits as `3de8a76` and `c048a6d`.
First one hit a comment-only conflict in four blocks because lca-inversion already had the Delta_avg fix from its native commit `5cfe158`; resolved by taking HEAD on all four conflicts.
Net change on lca-inversion was a 1-line diff (only the `assert_merge_clean asis` portion was new).
Not pushed.

Session log appended with this section.

### Decisions, with the why

#### Cherry-pick to both main AND lca-inversion, not one or the other

Why: user pushed back on the framing of "main or lca-inversion".
Both branches need the fixes; the assert_merge_clean bug is latent on any branch that runs `1_processData.do`, and the copyOverleaf filename fix breaks coauthor-facing tables on any branch that publishes them.
No reason to gate one behind the other.

#### Resolve lca-inversion's cherry-pick conflict by taking HEAD on the Delta_avg comment blocks

Why: the four conflicts were entirely in comment text describing the same fix.
Incoming version had a `(cherry-picked from lca-inversion commit 5cfe158)` provenance line --- which would be a lie on the lca-inversion branch itself, since 5cfe158 is the native source there.
HEAD's comments were already the canonical wording on that branch.
Verified by reading the diff that the actual estimation code below all four conflict blocks was bit-identical on both sides.

#### Generalize slice drivers to mirror `0_master.do` instead of leaving them as personal stubs

Why: user wants to rerun the real-values pipeline soon and may want to parallelize that too.
Single-user maand-only drivers would block any coauthor rerun and would not work in real-values mode (because `$values` was never set, defaulting to nominal silently).
The full multi-user `$dir` block plus an explicit `$values` toggle costs ~35 extra lines per file and makes the drivers reusable for both modes and any user.

#### Did not factor out the prelude into a shared `_extras_driver_prelude.do`

Why: `0_master.do` keeps its prelude inline.
Mirroring that pattern keeps each driver self-contained --- a coauthor can read one file top-to-bottom and understand what runs.
Also matches the project's `feedback_no_loops_for_regressions.md` preference for explicit per-call sites over abstracted shared scaffolding.

#### Did not write a `2026-05-11_merge-strategy.md` planning doc

Why: user explicitly said it would be overcomplicating things.
The two-bullet sketch in chat was enough to decide what got cherry-picked now vs. left until the pipeline finishes.

### Approaches rejected and the reason

#### `git checkout --ours RP7/scripts/0_programs.do` to resolve the lca-inversion conflict

Reason dropped: `--ours` replaces the whole file with the HEAD version, which would also undo the auto-merged `assert_merge_clean asis` fix that landed cleanly outside the conflict regions.
The whole point of the cherry-pick was to bring that one fix over; reverting it would defeat the operation.
Switched to a Python script that walks the file, deletes the incoming-side blocks, and keeps HEAD on the four conflict regions.

#### PowerShell `Set-Content -Encoding utf8NoBOM` for the conflict resolution

Reason dropped: PowerShell 5.1 does not accept `utf8NoBOM` as a valid encoding name (only `UTF8` with a BOM, or workarounds).
Switched to Python with `write_text(..., encoding="utf-8")` which writes UTF-8 without BOM by default.

#### Treat the dofile review's "hardcoded path" finding as MINOR and leave the drivers as-is

Reason reconsidered: my initial response to the review was to downgrade the finding since `_smoke_extras_one.do` has the same pattern.
User then said no --- the drivers should be generalized properly for real-values reruns.
Applied the fix, not the downgrade.

### Open items and blockers

- **Three pipelines still running.**
  PID 17480 (serial resume), PID 42328 (birth slice), PID 4420 (cnu slice).
  Output state at session end: 10 maxexpsh sters (out of 180), 0 urbanbirth sters, 5 cnu-extras sters.
  Birth and cnu slices each ~1--2 h into their estimated 2--3 h runtime.
  PID 17480 still grinding maxexpsh.
- **Cherry-picks on `main` and `lca-inversion` are not pushed.**
  Commits `a2f8312` and `b848115` on main; `3de8a76` and `c048a6d` on lca-inversion.
  User decides when to push.
- **`run_extras_maxexpsh.do` was never launched.**
  Driver is dormant on disk; PID 17480 is handling maxexpsh serially.
  Available if PID 17480 dies mid-family.
- **Currently-running birth and cnu slices use the OLD pre-generalization driver.**
  They loaded those into memory at launch and are unaffected by the b5c7e5a rewrite.
  If they need to be killed and relaunched, the new generalized version is what disk now holds.
- **Main worktree has uncommitted changes** unrelated to this session (paper/slides/verdier-modification.pdf modified, papers/extracted/ files churned).
  Left alone.
- **2026-05-09 parallelization HTML still says "atomic writes mitigate it"** about the race risk.
  User flagged this for revision earlier but deferred.
  Carries forward.

### Picking back up

If you resume:

Read this session log first, then the original 2026-05-11 section above it for the morning's headlines-cache + afternoon's slice-driver launch context.

Open thread: three Stata processes are completing the GRC extras work that was killed on 2026-05-09.
No further action needed until they finish; the next decision point is "all sters present" --- at which point the dashboard re-renders cleanly and the branch is ready for merge.

Check progress with:

```powershell
tasklist /FI "IMAGENAME eq StataMP-64.exe"
Get-ChildItem RP7/output -Filter 'grc_*_maxexpsh_*.ster' | Measure-Object | Select-Object Count
Get-ChildItem RP7/output -Filter 'grc_*_urbanbirth_*.ster' | Measure-Object | Select-Object Count
Get-ChildItem RP7/output -Filter 'grc_IDN_cnu_*.ster' | Where-Object Name -match '_(exp|exp_max|exp_share|exp_max_share|maxexp|expsh|maxexpsh)_' | Measure-Object | Select-Object Count
```

Target totals: 180, 80, 80.

State to know:

- Commits on `worktree-grc-pipeline-refactor`: `b24b847` (initial slice drivers), `b5c7e5a` (driver generalization).
  Neither pushed.
- Commits on `main`: `a2f8312`, `b848115`.
  Not pushed.
- Commits on `lca-inversion`: `3de8a76`, `c048a6d`.
  Not pushed.
- `tier2_diffs/` directory is gone from `RP7/output/`.
- Birth and cnu slices were launched BEFORE driver generalization; they hold the pre-b5c7e5a version in memory.
- Three commits sitting upstream on `lca-inversion` and `main` plus 41 commits on this branch.
  No PR opened yet.

with Claude
