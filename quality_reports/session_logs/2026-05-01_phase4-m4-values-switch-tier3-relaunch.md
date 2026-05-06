# Session log 2026-05-01

Branch: `worktree-grc-pipeline-refactor`.
Continuation of yesterday's Phase 2 work (M3 + S3 + Δ̄ all landed late on 2026-04-30).
Today's focus: Tier 3 #4 crash diagnosis, Tier 3 #5 relaunch, Phase 4 (M4) `values(nominal|real)` switch end-to-end, verification harness design.

## Goals at the start of the session

1. Triage the Tier 3 #4 background-task failure notification.
2. Continue Phase 4 (M4 values switch) per yesterday's plan reminder.
3. Build a verification harness for M4.

Mid-session course corrections from the user:
- Output goes to `RP7/output/`, not Dropbox (the real-values Dropbox folder is INPUT only).
- Use `_r` suffix instead of `_real` because some M11 estnames are tight against the 32-char `_est_` ceiling.
- Two cells for verification, not one: `grc_IDN_cub_c0` (no covs) and `grc_IDN_cub_ca` (full covs).
- Drop bit-compare validation against RP6 real-values sters; build functional tests instead.
The RP6 sters predate M3/M11/hukou-merge/mu-loop-dedup, so a bit-compare would conflate four refactors and prove nothing about M4 specifically.
- Real-values papers in the future will either replace or augment the nominal tables, not coexist with them, so a paper-side `\GRCvaluesfx` toggle macro is unnecessary.
Defer that question.

## What got built or changed

### `RP7/scripts/0_path_config.do`

M4 stage 1: added the `$values` switch at the top of the file.
Defaults to `nominal` if unset.
`nominal` → `$dirdata=$dir/data`, `$vsfx=""`.
`real` → `$dirdata=$dir/data_real`, `$vsfx="_r"`.
Anything else aborts with `exit 198`.
Commit `b3b021d`.

### `RP7/scripts/0_programs.do`

M4 stage 3: appended `${vsfx}` to every output path emitted by the programs.
- 25 `estimates save "$dir/output/<estname>{,_n,_a,_d,_g}", replace` sites across `run_grc`, `run_grc_with_extra_regressor`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv` (5 programs × 5 sters per fit).
- 1 M10 skip-on-exists guard at the top of `run_grc` (checks for `_g${vsfx}.ster` instead of `_g.ster`).
- 8 `esttab using "$output/tables/`filename'.tex"` sites in `grc_tex_table_trend`, `het_table_delta`, `het_table_mu`, `create_panel_tex_table`, the `_learn_IDN/CHN` variants.
- 3 `estimates use "$dir/output/`_stem'_<...>"` and 1 `capture confirm file` skip-check inside `grc_tex_table_trend`.
- 2 `estimates use "$dir/output/grc_`country'_cuu_ca[_d]"` reads inside `het_table_delta` / `het_table_mu`.
- 1 `local filepath "<dir>/<filename>${vsfx}.tex"` site in `sumstats_table`.
- 4 `graph save "$output/figures/hetplot*_<...>.pdf"` sites in `heterogeneity_plots`.
Commit `b3b021d`.

### `.gitignore`

Added `RP7/data_real/` so the new junction doesn't get tracked.
Commit `5fbe30b`.

### `CLAUDE.md`

Documented the `RP7/data_real/` junction in the Directory layout section, alongside the existing `RP7/data/` line.
Also dropped a spaced em dash (` --- ` → `;`) on the parent line because the post-edit prose hook flagged it during the edit.
Commit `5fbe30b`.

### `RP7/data_real` (out-of-band)

Junction created via PowerShell:
```
New-Item -ItemType Junction -Path RP7\data_real ^
  -Target "C:\Users\maand\Dropbox (Personal)\Returns to migration\ReplicationPackage6 - real values\data"
```
Per-machine; recreate on each dev workstation.
Verified working: `RP7/data_real/countries/CHN.dta` resolves correctly.

### `tests/verify_M4_values_switch.do`

Four-test verification harness modeled on `tests/verify_M4_extended.do` (the mu-loop verifier from 2026-04-30).
Tests:
- T1 (config): toggle `$values=real` then `nominal`; assert `$dirdata` and `$vsfx` wire up correctly in both directions.
- T2 (real fit): fit `grc_IDN_cub_c0` with `$values=real`; verify `_r`-suffixed sters land on disk; stash `e(b)`, `e(V)`, `e(N)`.
- T3 (nominal regression): refit `grc_IDN_cub_c0` with `$values=nominal` under estname `verify_M4_values_nominal_IDN_cub_c0` (so the original pre-M4 ster is preserved on disk); bit-compare `e(b)/e(V)` against the pre-M4 stash via `mreldif`.
- T4 (real ≠ nominal): max abs diff between T2 and T3 estimates > 1e-6 expected.
Commit `b8530a7`.

Two follow-up edits NOT yet committed:
- `_b[Delta_avg:_cons]` → `_b[Delta_avg]` (3 sites): `nlcom` stores the result as a named row, not a `name:_cons` equation, so the suffix throws `r(111) equation Delta_avg not found`.
- `quietly` on the two `initial_values` and two `run_grc` calls inside T2 and T3: without `quietly`, the GMM iteration trace blows past the MCP's 100K-char response cap.
Both fixes work in isolation; needed together for a clean MCP run.

### `docs/plans/2026-04-30-phase4-values-switch.md`

Phase 4 plan, written before any code edits.
Updated mid-session to reflect the user's `_r` and "decisions captured" framing.
Commit `b3b021d`.

### Tier 3 background tasks

`bnf7hjfb8` (Tier 3 #4) — launched yesterday at 15:46, failed with exit code 1 today.
Crash was silent: log just stops mid-iteration on Step 2 of the cell after `grc_IDN_cuu_expsh_c3` (which had completed and saved 5 sters cleanly).
No `r(N);` error, no popup mentioned, no Stata processes lingering at the time of diagnosis.
1010 sters on disk at crash time (up from 905 at launch); 105 cells completed in this run.
Most likely cause: external process kill (Windows shutdown / sleep / system event) since the log shows active mid-iteration write when cut off.

`b8jjayskx` (Tier 3 #5) — relaunched immediately, `skip_if_exists=1` so it picks up where Tier 3 #4 stopped.
Currently still running; ~25 cells remain after Tier 3 #4's contribution.

## Decisions, with the why

**Decision: launch Tier 3 #4 in background and work Phase 4 in parallel rather than serializing.**
Why: Tier 3 doesn't compete with the MCP `default` session, and Phase 4 is pure code/doc work needing no Stata.
Saves a multi-hour wait.

**Decision: hold off on a partial PR; ship the whole audit + Phase 1 closure stack as one coherent PR after Tier 3 finishes.**
Why: bug fixes (M4-mu-loop, timer wrap, hukou merge) and refactor commits are interleaved and touch the same files; cherry-picking into separate PRs is more reconciliation work than value.
Tier 3 IS the integration test for the whole stack; merging early means debugging across a merge boundary if something surfaces post-merge.
No external pressure since coauthors don't use git.

**Decision: `_r` not `_real` for the values suffix.**
Why: longest current M11 estname is `grc_IDN_cuu_maxexpsh_ca_d` at 25 chars.
Stata's stored-name budget is `_est_` + name = 32 chars, so 25 + 5 = 30 leaves 2 chars of headroom.
`_real` (5 chars) would bust the limit at 35; `_r` (2 chars) lands at exactly 32.
Two-char suffix keeps every existing estname legal even if we later disambiguate stored names too.

**Decision: conditional suffix (empty for nominal, `_r` for real) rather than always-suffix.**
Why: pre-M4 sters and tables have NO values suffix.
Tier 0 reference set + 1010 existing sters + paper-side `\input{tables/<...>}` references all assume bare names.
A naive "always append `_${values}`" would invalidate every one of those.
Conditional preserves backward compat exactly, at the cost of a 4-line if/else in `0_path_config.do`.

**Decision: filename suffix in shared `output/` dir, not separate `output_nominal/` and `output_real/` dirs.**
Why: per spec.
Considered the alternative but rejected because (a) the S1 ster scraper is simpler with one glob pattern keyed off the suffix, (b) the paper-side `\input` macros would need dir-aware logic if outputs split, (c) visual diff of nominal vs real is easier in one folder.

**Decision: drop bit-compare against RP6 real-values sters; use functional tests instead.**
Why: user pointed out that the RP6 real-values sters were generated under pre-M3, pre-M11, pre-hukou-merge, pre-mu-loop-dedup code.
A bit-compare would test "M4 + 4 other refactors == RP6 real-values" rather than "M4 alone == correct".
Functional tests (T1 config, T2 real fit, T3 nominal regression, T4 real ≠ nominal) target M4 specifically.

**Decision: T3 nominal regression check uses a sandbox estname (`verify_M4_values_nominal_*`) rather than overwriting the original `grc_IDN_cub_c0` ster.**
Why: keeps the pre-M4 reference ster intact on disk for later side-by-side comparison.
The bit-compare loads the reference into memory matrices first, then refits in nominal mode under the sandbox estname; the matrices are compared without anything on disk being clobbered.

**Decision: relaunch Tier 3 with `skip_if_exists=1` rather than rerun from scratch.**
Why: 1010 sters already on disk; rerunning would burn ~50 hours of compute to regenerate identical numbers.
Resume mode picks up only the missing ~25 cells and the failed cell.

**Decision: defer the paper-side `\GRCvaluesfx` macro work.**
Why: user clarified that real-values output would either REPLACE the nominal tables in a future paper revision or appear as a robustness-check appendix.
Either way, a per-build switch in `preamble.tex` isn't needed because the paper would commit to one or the other, not maintain parallel macro paths.

**Decision: in T2/T3 of the verification driver, use `_b[Delta_avg]` not `_b[Delta_avg:_cons]`.**
Why: `nlcom (Delta_avg: ...)` stores the result under name `Delta_avg`; the matrix has a single column labeled `Delta_avg` and a single row labeled `y1`.
There is no `:_cons` equation prefix because nlcom doesn't have an underlying linear model.
Discovered via `matrix list e(b)` on the existing `grc_IDN_cub_c0_g.ster`.

**Decision: wrap the fits in `quietly` inside the driver.**
Why: MCP responds with the captured stdout; un-quieted `gmm` produces 50K+ chars of iteration trace per fit.
Two fits + setup output exceeded the 100K-char response cap on the second run attempt.
`log using` opens a log on disk but does NOT suppress screen output in pystata mode (unlike batch mode where it does).
The fix is `quietly` on the noisy commands; the matrices we need are recovered via `estimates use` on the saved sters.

## Approaches rejected and the reason

**Splitting M4 into two commits (path_config switch alone, then `${vsfx}` propagation).**
Tempting for clean history, but `0_path_config.do` setting `$vsfx=""` (in nominal default) requires `0_programs.do` to actually USE `$vsfx` for the no-op behavior to be visible.
Either alone is a half-implementation.
Combined commit `b3b021d` is the right unit.

**Always appending `_${values}` (so nominal mode produces `*_nominal.ster`).**
Spec wording suggests this.
Rejected because it invalidates the pre-M4 reference set, the 1010 existing sters, and the paper-side `\input` references all in one go.
Conditional suffix gets the same coexistence property without breaking anything.

**Bit-compare M4 real mode against `Dropbox/.../ReplicationPackage6 - real values/output/grc_*.ster`.**
Spec listed this as a verification gate.
Rejected after the user pointed out the RP6 real-values sters predate too many other refactors to be a clean M4 test.
Replaced by functional tests in the verification driver.

**Doing the M4 verification via Stata MCP `default` session (interactive).**
Tried twice, both attempts failed before any test results.
First failure: `_b[Delta_avg:_cons]` syntax error (driver bug, fixed).
Second failure: 100K-char response cap exceeded (driver design, fixed by adding `quietly`).
The fixes are in the working tree but un-committed; the third attempt was intercepted by the user with /pause.
Open question: re-attempt via MCP after fixes commit, or run via batch (`stata-mp -b do tests/verify_M4_values_switch.do`) once Tier 3 #5 finishes and Stata is free.

**Force-killing the failed Tier 3 #4 process to inspect state.**
No process to kill; `tasklist | grep stata` showed only mcp-stata.exe at diagnosis time.
The Stata MP batch had already exited.
Reading the log tail and `tasklist` was sufficient to characterize the crash; no recovery action was taken beyond the relaunch.

**Creating the `RP7/data_real` junction via Git Bash `ln -s`.**
Per memory: Git Bash on Windows silently creates a copy, not a symlink.
Used PowerShell `New-Item -ItemType Junction` instead.
Initial cmd.exe attempt failed with quoting issues; PowerShell handled the path-with-spaces cleanly.

## Open items and blockers

**Two un-committed edits in `tests/verify_M4_values_switch.do`.**
- `_b[Delta_avg:_cons]` → `_b[Delta_avg]` (3 sites).
- `quietly` on `initial_values` and `run_grc` (4 calls total, 2 in T2 and 2 in T3).
Need to commit before the next driver attempt.

**M4 verification has not actually executed end-to-end yet.**
Two MCP attempts failed at preamble (T2 hadn't started either time).
Driver hasn't produced T1/T2/T3/T4 results.
Three options for next session, in priority order:
1. Commit the un-committed fixes; rerun via MCP — fastest if the `quietly` fix is sufficient.
2. Wait for Tier 3 #5 to finish; run via batch `stata-mp -b do tests/verify_M4_values_switch.do` — most robust, no response-cap concerns.
3. Run only T1 (config check, no fits) via MCP now to confirm the path-config wiring at least; defer T2/T3/T4 to batch.

**Tier 3 #5 still running.**
Background ID `b8jjayskx`.
Log last updated 09:19; growing slowly.
Expected finish: several more hours.
Doesn't block Phase 5 prep work.

**Paper-side `\GRCvaluesfx` macro deferred.**
Will need to be added to `preamble.tex` (Overleaf-Dropbox) when the team decides whether real-values is a replacement or robustness check.
Logged in the spec's section 4a parking lot.

**Tier 2 nominal byte-identity check on M3 + M4.**
Mechanical: post-Tier-3 #5, run `_smoke_tables_only.do` against existing sters and diff every `output/tables/*.tex` against the pre-M3 reference.
Expected diff: exactly one row per file (the `Delta_avg` label flipping from "Average $\Delta$" to "$\bar{\Delta}$").
Anything else changing is a regression.

## Picking back up

**If you resume:** Read this file end-to-end first, then [2026-04-30_tier3-wrap-timer-bug-hukou-merge.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-04-30_tier3-wrap-timer-bug-hukou-merge.md) for the M3 + S3 + Δ̄ context that's already done.

**Open thread:** how to actually run the M4 verification harness.
Three options listed above; user paused after the second failed MCP attempt and didn't pick.

**Next concrete action:**
1. Commit the un-committed edits in `tests/verify_M4_values_switch.do` (the `_b[Delta_avg]` fix and the `quietly` wrappers).
2. Pick run-mode: MCP or batch.
3. Execute and inspect [RP7/output/verify_M4_values_summary.txt](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/verify_M4_values_summary.txt) (will be created on first successful run).

**State to know:**
- Branch `worktree-grc-pipeline-refactor` last commit `b8530a7` (verification driver landed but un-tested).
- Two un-committed edits in `tests/verify_M4_values_switch.do`.
- Tier 3 #5 background task `b8jjayskx` running; ~25 cells remaining.
- 1010+ sters on disk (will grow as Tier 3 #5 progresses).
- `RP7/data_real` junction is live on this machine; gitignored, documented in CLAUDE.md.
- prose-rules-enforcer flag is set this session; resets next session.
- voice.md and manuscript-writing.md were Read.
- MCP `default` session has stale state from the two failed verification attempts (`b_pre_main`, `V_pre_main`, etc. matrices in memory plus a partially-written log).
First MCP command in next session should `clear all` before doing anything else.

## Commits landed this session

- `b3b021d` M4 (Phase 4) stage 1+3: values switch in 0_path_config + ${vsfx} on all output paths.
- `5fbe30b` M4 (Phase 4) stage 2: gitignore RP7/data_real + document junction in CLAUDE.md.
- `b8530a7` M4 (Phase 4) verification harness: 4-test driver for values switch.
- `d896edd` M4 verification harness fixes (`_b[Delta_avg]`, `quietly` wrappers) + 2026-05-01 session log.

Plus disk-only changes: `RP7/data_real` junction created locally.

---

## Continuation later 2026-05-01: batch verification, two failure modes, retry

Resumed after /clear.
Open thread was picking a run mode (MCP vs batch) for the M4 verification harness and executing it.
User chose batch ("we've basically agreed batch is better for something with so much output, and concurrent batches are fine").

### Driver hygiene (uncommitted; will go in next commit)

Added `capture noisily { ... }` wrapper plus `exit, STATA clear` at the tail of `tests/verify_M4_values_switch.do` per `~/.claude/rules/stata-conventions.md`.
That convention is the canonical fix for the Windows batch-mode "Stata finished" modal popup, on both success AND error paths.

### Failure 1: `r(608)` log-file lock

First batch (`bptx7yxio`) errored at `log using "$logs/verify_M4_values.smcl", replace` with `r(608); cannot be modified or erased; likely cause is read-only directory or file`.
Diagnosis steps:
- `tasklist | grep -i stata` showed live processes (Tier 3 #5 batch + MCP servers).
- `mcp-stata list_sessions` reported `default` as `status: "stopped"` with `pid: 17924`.
- `rm -f` on the smcl returned `Device or resource busy`, indicating a ghost file handle from yesterday's failed MCP attempts that Windows hadn't released.

Fix: renamed the log path in the driver from `verify_M4_values.smcl` to `verify_M4_values_batch.smcl`.
Cleaner than killing processes (Tier 3 #5 was running) or restarting Stata (would interrupt it).
Updated header comment to match.

### Failure 2: `r(7)` invalid name (32-char `_est_` ceiling)

Second batch (`b47htghk8`) cleared the smcl issue but errored ~10 minutes later inside `run_grc` with `_est_verify_M4_values_real_IDN_cub_c0 invalid name`.
Diagnosis: estname `verify_M4_values_real_IDN_cub_c0` is 32 characters; with the `_est_` prefix Stata uses internally that becomes 37, busting the 32-char internal-name ceiling documented in `~/.claude/rules/stata-conventions.md`.

Confirmed via grep on `0_programs.do` that `${vsfx}` is appended only to disk paths inside run_grc, not to the eststo internal name.
Shortening the estname (rather than the disk filename) is the right lever.

Fix: shortened the verify-harness estnames using a `vM4_` prefix.
- `verify_M4_values_real_IDN_cub_c0` (32 chars) became `vM4_real_IDN_cub_c0` (19); plus `_g` suffix = 21; `_est_` + 21 = 26, fits.
- `verify_M4_values_nominal_IDN_cub_c0` (35) became `vM4_nom_IDN_cub_c0` (18); plus `_g` = 20; `_est_` + 20 = 25, fits.

Sites changed: 2 `run_grc, estname(...)` lines (T2 and T3, both with backtick `country`), 4 `estimates use ".../<estname>...ster"` lines, 2 `capture confirm file` lines, plus the header `Output:` comment.
First `replace_all` on the hardcoded `IDN` form missed the macro form (`` `country' ``); caught it in a follow-up grep before relaunch.

The `vM4_*` prefix is far enough from `verify_M4_*` that it doesn't collide with the prior mu-loop verification harness's persisted sters in `RP7/output/verify_M4_*.ster`.

### Decisions, with the why

Decision: rename the log file rather than chase the ghost handle.
Why: the holding process was unidentifiable (MCP `default` reported stopped, but Windows clearly still had a handle attached).
Killing the only candidate live PID would have corrupted 2+ hours of Tier 3 #5 progress.
Rename is non-invasive and the smcl filename is internal scaffolding, not load-bearing.

Decision: shorten via `vM4_` prefix rather than re-architect the estname budget.
Why: the 32-char ceiling is a hard Stata constraint, not negotiable.
The `verify_M4_values_*` prefix was always going to be tight: `verify_M4_values_` alone is 17 chars, leaving only 8 for everything else after the `_g` suffix and `_est_` overhead.
Other M11 estname conventions already use compact tags (`cuu`, `ca`, `os`, `ts`), so a 3-letter `vM4` prefix is consistent with house style.

Decision: keep the `vM4_` prefix far from `verify_M4_*` (the mu-loop harness sters).
Why: the two harnesses' artifacts then stay cleanly separated on disk; `ls RP7/output/v*.ster` shows them in obvious groups.
A `verify_*` shortening (e.g., `vfy_`) would have visually conflated them.

### Status as of last check

- Third batch (`bwxhxfua7`) launched at ~10:18; expected ~5--10 min for two GMM fits on `grc_IDN_cub_c0`.
- Tier 3 #5 (`b8jjayskx`) still running, no contention with the verify batch (separate Stata MP processes; license allows concurrent batches).
- No commits yet from today's continuation; uncommitted changes in `tests/verify_M4_values_switch.do` (popup safety + log rename + estname shortening).

### Open items

- Wait on `bwxhxfua7`, read T1/T2/T3/T4 results from `RP7/output/verify_M4_values_summary.txt`.
- Commit driver fixes once a clean run produces the summary file.
- Tier 3 #5 still running; no action needed.

### Continuation: failure modes 3 and 4 plus paper-side diagnosis

`bwxhxfua7` finished after ~10 min (T2 + T3 fits successful) but errored at the mata summary writer with r(3253) `nonreal found where real required`.
The smcl showed all four tests had passed before the mata error fired:
- T1 PASS (config switch wires up).
- T2 PASS (`vM4_real_IDN_cub_c0_*_r.ster` on disk, N=16,391, Delta_avg_real = -0.1375).
- T3 PASS bit-identical (`mreldif(b_nom, b_pre) = 0`, V matrices too; Delta_avg_nom = 0.1539 matches pre-M4 exactly).
- T4 PASS (max |b_real - b_nom| = 5.59, mreldif = 0.93; deflation flips Delta_avg sign as expected).

Diagnosis: `strofreal(st_local("t1_pass"))` is wrong because `st_local` already returns a string and mata's `strofreal` expects a real.
Fix: drop `strofreal` on the four `t*_pass` reads (the `st_numscalar` reads stay; those return real).

Relaunched as `bbclpgfno`.
Hit a different mata error: r(602) `file already exists` on `fopen(..., "w")`.
Mata's "w" mode is exclusive-create, not truncate-or-create.
The 10:35:48 partial summary file from `bwxhxfua7` was still on disk.
Fix: prepend `unlink(...)` to the summary path so the writer always starts clean.
Also `rm -f` the stale summary on disk to avoid depending on the unlink during the next run.

Relaunched as `bqt4wzzsq` at 12:31.
Currently running, mid-T3 nominal fit at last check (12:51).
Slower than the prior runs because Tier 3 #5 (`b8jjayskx`, PID 12516) is now also actively iterating, sharing CPU with the M4 batch (PID 24324).
Both Stata MP processes alive; the slowdown is contention, not a hang.

### Decision: chase the cosmetic mata bug rather than hand-write the summary

Why: the verification harness is supposed to be self-contained and re-runnable.
Hand-writing the summary file based on the smcl numbers I already read would have been faster, but it would have left the harness broken for future replays.
The `unlink()` + `st_local` fixes cost two extra ~10 min runs and a third ~10 min run still pending; in exchange, the harness produces a clean summary on demand, every time.

### Tangent: Overleaf bare-tabular issue (user question while waiting)

User asked why `GRC_TZA_consumption_urban_unb` shows up in Overleaf without the `\begin{table}` wrapper.

Diagnosis: the M11 / Phase 1b.2 refactor slimmed the `.do` table output to emit only the inner `\begin{tabular}...\end{tabular}`.
The `\GRCtable{country}{depvar}{choice}{balance}` macro was added to Overleaf's [preamble.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/preamble.tex) (line 254) to supply the missing `\begin{table}`, caption, label, threeparttable, `\input{tables/GRC_<...>}`, and tablenotes.
But the body of [main.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/main.tex) still has bare `\input{tables/GRC_TZA_consumption_urban_unb}` (lines 708--713) instead of `\GRCtable{TZA}{consumption}{urban}{unb}`.
So Overleaf is `\input`-ing the new bare-tabular file with no envelope, and the prose `\ref{tab:GRC_TZA_consumption_urban_unb}` produces an undefined-reference warning (3 hits in the compile log).

Fix: in Overleaf `main.tex`, swap each `\input{tables/GRC_<...>}` for the corresponding `\GRCtable{...}` / `\GRCexptable{...}` / `\GRChukoutable{...}` invocation per the [draft notes file](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-28_preamble-macros-draft.tex) line 263+.
This is paper-side work that hasn't been done yet; defer until M4 verification is closed.

### Status as of last check

- Third batch attempt `bqt4wzzsq` running, mid-T3 nominal fit at 12:51 (started 12:31).
- Tier 3 #5 (`b8jjayskx`) still running (no action).
- Three uncommitted fixes accumulated in `tests/verify_M4_values_switch.do`: popup safety + log path rename + estname shortening + mata writer fixes (strofreal removal + unlink).

### M4 verification CLOSED, committed in `49e05d4`

`bqt4wzzsq` finished cleanly with all four tests PASSING:
- T1 config: PASS.
- T2 real fit: PASS, N=16,391, Delta_avg_real = -0.1375 (deflated; sign flip vs nominal).
- T3 nominal refit: PASS bit-identical to pre-M4 reference (`mreldif(b_nom, b_pre) = 0` exactly, V matrices too).
- T4 real != nominal: PASS, mreldif = 0.93, max |dB| = 5.59.

Headline finding: T3's bit-identity at full precision establishes that M4's `${vsfx}` path edits are perfectly transparent in nominal mode.
Persisted artifact at `RP7/output/verify_M4_values_summary.txt`.

Committed with the driver fixes accumulated this session: popup safety wrapper, log path rename, estname shortening (`vM4_real_*`/`vM4_nom_*`), and the mata writer corrections (`st_local` reads + `unlink()` before `fopen`).
Decision to skip Tier 2: T3's bit-identity is stronger evidence than a per-cell replay, the M11 pipeline is uniform across cells, and Tier 2's expected diff was already fully predicted (just the `Delta_avg` label flip).
User signed off on skipping.

### Tangent continued: paper-side wiring after the file copy

User confirmed: only TZA had been copied to Overleaf-Dropbox (the IDN and CHN files in `tables/` are still pre-refactor full-envelope shape).
And `sec_results.tex` line 85 had a typo: `\GRCtable{TZA}{consumption}{urban}{unb}` mid-sentence instead of `\ref{tab:GRC_TZA_consumption_urban_unb}`.
That spurious macro invocation was floating the entire TZA table at line 85, which is why TZA appeared before IDN despite the source order suggesting otherwise.
With user approval, did three things:
- Copied IDN/CHN/TZA `consumption_urban_unb` tables from `RP7/output/tables/` to `Overleaf-Dropbox/tables/`.
- Fixed the line-85 typo: `\GRCtable{TZA}{...}` -> `\ref{tab:GRC_TZA_consumption_urban_unb}`, dropped the spurious double space.
- Swapped lines 102-107 (commented `\GRCtable{...}` block + active `\input{}` block) to active `\GRCtable{IDN/CHN/TZA}{consumption}{urban}{unb}[\GRCnotesIDNcanonical]` calls.
None of these are committed yet (they're in Dropbox, outside the git tree).

### Detour: addlinespace + blank-row visual issue

User flagged that the new GRC tables show too much vertical space between coefficient blocks---about 1.5 lines, not the half-line `\addlinespace` should give.
Diagnosis: between every coefficient block there's a blank tabular row (`& & & & & \\`) AND `\addlinespace` stacked.
The blank row is the larger contributor.

Read `esttab.ado` from `~/ado/plus/e/`.
The `gaps` option (auto-enabled when `se` is used) does three things at lines 894, 902, and 928:
- defaults `posthead` to `\addlinespace` (booktabs `midgap`),
- defaults `prefoot` to `\addlinespace` when stats are present,
- auto-builds `varlabels(... end("" \addlinespace) nolast)`---inserts blank row + `\addlinespace` at end of each varlabel's rows, except the last.

Why no blank row after phi: the third esttab call in `grc_tex_table_trend` (line 3015 of `0_programs.do`) explicitly passes `varlabels(`keep' "`varlabel'")`.
That bypasses the auto-end injection.
First two esttab calls only set `coeflabels`---so they fall through to the auto-end path.
But the user has not yet greenlit the fix in `0_programs.do`; they asked me to test the proposed fix on a test table first.

Wrote `tests/test_addlinespace_fix.do` to compare:
- baseline: current pattern.
- fix: explicit `varlabels(...)` on first two esttab calls (mirroring how the third does it).

First test attempt failed for two reasons:
- Baseline third esttab errored r(111) "coefficient phi not found" because in this test driver the kept variable is named "phi" but the `ests` matrix uses different naming.
- Fix block had `keep(Delta_never)`, but `Delta_never` may not be the matrix column name---silent skip.
Removed `keep()` from fix block in retry; same r(111) on baseline; fix block STILL produces no file (no error in smcl, just no file).

Open hypothesis: `varlabels(Delta_never "..." Delta_always "...")` may error or silently skip when `Delta_always` isn't in the matrix.
`coeflabels` tolerates unmatched entries; `varlabels` may not.
Wrote `tests/test_addlinespace_minimal.do` to test three variants (coeflabels both, varlabels both, varlabels Delta_never only) plus a `matrix list e(b)` diagnostic to find the actual coefficient name.
Currently running as `bvhhjuea1`.

### Decisions, with the why

Decision: test the addlinespace fix empirically before editing `0_programs.do`.
Why: the esttab.ado source supports the diagnosis but doesn't fully explain why `nolast` doesn't suppress the trailing on the first two calls---those have only one varlabel that actually renders.
The user explicitly asked me to verify; they have intuition that "I'm not 100% sure" is correct.

Decision: use `tests/` for the test driver, not edit `0_programs.do` first.
Why: per `~/.claude/rules/script-safety.md`, never edit data-processing scripts without explicit approval.
The user approved the diagnosis path but the fix itself still needs verification.

### Open items

- Wait on `bvhhjuea1` minimal 3-variant test to identify which `varlabels` form actually works.
- Once the right form is found, update the FIX block in `tests/test_addlinespace_fix.do`, rerun, diff baseline vs fix, and report whether blank row is suppressed and `\addlinespace` survives.
- Then either (a) edit `0_programs.do` lines 2989-3012 with user approval, or (b) defer and note the visual issue is cosmetic.
- Also still pending: the IDN canonical tablenotes ref via `\GRCnotesIDNcanonical`---verify it renders correctly when the user compiles in Overleaf.
- Tier 3 #5 (`b8jjayskx`) still running.

### Detour resolution: filefilter precedent in summary stats

Three rounds of unsuccessful diagnosis through esttab.ado source:
- Variant A (coeflabels with both Delta_never and Delta_always) and B (varlabels with both): byte-identical baseline output.
- Variant C (varlabels with Delta_never only): also identical.
- Variant D (drop Delta_always entirely from coeflabels in baseline): still identical.

So `nolast` and the `gaps`-driven auto-end injection were not what controlled the trailing blank rows.
The blank rows are emitted by esttab's `nomtitles + noobs + varwidth(20)` interaction, which I did not fully trace.

User pointed me back to `0_programs.do` and `make_tables.do` to look for filefilter usage.
Found 30+ instances in `1_summaryStats.do` already calling `removeStringFromTex` (a thin wrapper around Stata's `filefilter`) with patterns like `" &  &  &  &  \BS\BS  \BSaddlinespace"`---exactly the post-hoc strip approach we needed.
The codebase has the precedent baked into the summary stats workflow but `grc_tex_table_trend` never adopted it.

Solution: added one `removeStringFromTex` call at the end of `grc_tex_table_trend` (after the third esttab call) targeting the 6-column GRC table's literal blank-row pattern.
The pattern is stable: 20 leading spaces (from `varwidth(20)`) + 5 inner `&` separated by 15 spaces (from `modelwidth`) + `\BS\BS`.
Only one filefilter pass per cell.
The `\addlinespace` stays intact.

Verification: regenerated the 3 cuu §grc-returns tables via `tests/regen_grc_returns_3.do`.
Diff shows 4 changes per cell:
- 3 blank tabular rows stripped (lines 3, 7, 11)---the Phase 1b.6 spacing fix.
- 1 label change (line 9): `Average $\Delta$` -> `$\bar{\Delta}$`.
The label change is the predicted M3 mu-loop diff from yesterday's session log; not part of this fix but rolled in because the table-builder reads from the post-M3 sters.
All numerics bit-identical.

Files dropped from 1869 to 1563 bytes each (~16% smaller).
Copied to Overleaf-Dropbox `tables/` as the persistent paper-side artifact.

Popup-safety fix on the test drivers: I had introduced popups by changing `capture noisily {` to plain `{` on `tests/test_addlinespace_fix.do` line 33 when restructuring for per-block isolation, and forgot to wrap `tests/test_addlinespace_minimal.do` at all.
Fixed both---they now have proper `capture noisily { ... }` + `exit, STATA clear` flow so future runs won't fire the Windows batch popup even on r(111).

### Decisions, with the why

Decision: post-hoc filefilter strip rather than chase the esttab option that emits the blank row.
Why: I ruled out `gaps`, `nolast`, `coeflabels`/`varlabels` shape with three controlled tests.
The blank row comes from somewhere else in esttab's transition machinery (`nomtitles` + `noobs` + `varwidth` interaction).
Tracing that further would have been a sinkhole for cosmetic gain.
The filefilter approach is the project's established workaround for this exact pattern (1_summaryStats.do has 30+ such calls), and adding one line to `grc_tex_table_trend` matches that style.

Decision: regenerate only the 3 §grc-returns tables, not the full pipeline.
Why: the `removeStringFromTex` call is internal to `grc_tex_table_trend`, so any cell that runs through that function gets the strip.
The 3 cuu cells are what's affected in the active paper section; other cells (cub, iuu, cnu, hukou, experience family) will pick up the strip when their tables are next regenerated.
No need to force a full regen now.

Decision: commit-or-hold question deferred to user.
Why: the visible payoff is in the rendered Overleaf PDF, not in the .tex source.
User wants to confirm the rendering before committing.
Files are already on disk in Dropbox; the commit just captures the source change in `0_programs.do`.

### Status now

- `0_programs.do` has the Phase 1b.6 strip; uncommitted.
- `tests/regen_grc_returns_3.do` is new; uncommitted.
- `tests/test_addlinespace_*.do` (fix + minimal) have popup-safety fixes; uncommitted.
- 3 GRC §grc-returns tables regenerated and copied to Overleaf-Dropbox.
- Tier 3 #5 (`b8jjayskx`) still running.

### Open items

- Confirm Overleaf compile renders the 3 tables correctly with proper envelopes (from `\GRCtable{...}`), tighter inter-block spacing, and the `\bar{\Delta}` label.
- Then commit the `0_programs.do` Phase 1b.6 strip + the regen helper + the test driver popup fixes.
- Tier 3 #5 still pending.

---

## Final wrap before /clear

### What landed after the last log section

User compiled in Overleaf and confirmed the spacing fix renders correctly.
Then flagged a follow-on bug: CHN and TZA tables had no tablenotes.

Diagnosis: `\GRCtable` in `preamble.tex` line 256 used `\ifx\GRCthisnotes\@empty`.
`\@empty` requires `\makeatletter` to parse correctly because `@` has catcode 12 in the document body.
Outside `\makeatletter`, `\@empty` parses as `\@` (the inter-sentence space command) followed by literal `empty`, so the comparison silently never matches.
The fallback to `\GRCnotesxref{#1}{#4}` was never triggered.
With #5 supplied (IDN canonical), notes rendered.
With #5 default empty (CHN, TZA), `\GRCthisnotes` stayed empty, and the tablenotes block emitted nothing.

Fix: replaced `\@empty` with `\empty` (kernel-defined, document-body-safe).
Applied to both:
- Live `Overleaf-Dropbox/preamble.tex` line 256 (operational, outside git tree).
- Tracked staging draft [quality_reports/reviews/2026-04-28_preamble-macros-draft.tex](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-28_preamble-macros-draft.tex) line 151 (committed `7448f6a`).

User confirmed the rendered output looked good after the fix.

### Decisions, with the why

Decision: leave `paper/preamble.tex` (local, 168 lines) stale rather than syncing the Overleaf preamble.tex (305 lines) back into it.
Why: user explicitly said "the fix was entirely in the paper, then honestly it's fine let's not mess with the local paper".
The Overleaf-Dropbox copy is the canonical operational source.
Local `paper/preamble.tex` exists only as a historical artifact and isn't used to compile.
A one-shot sync would be ~140 lines of unrelated Overleaf evolution dragged into git history with no operational benefit.

Decision: capture the `\@empty` fix in the staging draft, not in `paper/preamble.tex`.
Why: the staging draft IS the canonical "source" for the GRC macro block in git; the macros were originally pasted from there into Overleaf.
Updating the draft means future re-pastes will carry the fix.
Updating `paper/preamble.tex` would require first syncing all the missing GRC macros from Overleaf, which the user vetoed.

Decision: commit the Phase 1b.6 fix and the table regen now even though Tier 3 #5 is still running.
Why: the spacing fix only touches `grc_tex_table_trend` and the 3 cuu tables.
It doesn't conflict with Tier 3 #5 (which writes other ster files via `run_grc_with_extra_regressor`).
Holding the commit would just risk losing it if context compresses.

### Approaches rejected

Approach: chase the esttab option that emits the blank tabular row.
Reason: three controlled tests (variants A, B, C, D) ruled out `gaps` / `nolast` / `coeflabels`-vs-`varlabels`.
The blank row comes from some interaction of `nomtitles` + `noobs` + `varwidth(20)` that I did not fully trace.
Time vs payoff was unfavorable; the codebase already has a post-hoc `filefilter` precedent in `1_summaryStats.do`.

Approach: post-process via mata file rewrite.
Reason: the existing `removeStringFromTex` wrapper around Stata's `filefilter` is simpler, faster, and matches the project's established style.

Approach: live with the spacing or fix it via LaTeX-side `\setlength{\defaultaddspace}{0pt}`.
Reason: would zero out `\addlinespace` everywhere in the paper, not just the GRC tables.
The blank tabular row is the visual culprit, not the `\addlinespace`; killing the wrong thing.

### Open items and blockers

- Tier 3 #5 (`b8jjayskx`) still running, last check during this session showed PID 12516 alive at 200+MB.
No estimate of remaining time.
On completion: that closes Phase 1b.5 (M11 + extras dispatch + hukou merge + mu-loop dedup).
- Tier 2 nominal byte-identity check: skipped per user (M4 T3 bit-identity at full precision is stronger evidence; the only expected diff is the `Delta_avg` label flip we already saw).
- Paper-side `\GRCvaluesfx` macro for nominal/real switch: deferred per yesterday's session; user clarified real-values output would either replace or appear as a robustness appendix, not coexist with parallel paths.
- The other 8 main GRC tables (cub, iuu, hukou × 4, experience family, heterogeneity) and 4 hukou variants will pick up the Phase 1b.6 spacing fix on their next regeneration.
No need to force a regen now since they're not in the active paper section.
- `RP7/output/test_min_*.tex` and `RP7/output/test_addlinespace_*.tex` are untracked transient test outputs.
Can be deleted; they're not gitignored but probably should be added to gitignore for `RP7/output/test_*`.
- `paper/preamble.tex` continues to drift from Overleaf-Dropbox; user accepted this.

### Picking back up

**If you resume:** Read [quality_reports/session_logs/2026-05-01_phase4-m4-values-switch-tier3-relaunch.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-01_phase4-m4-values-switch-tier3-relaunch.md) end to end.

**Open thread:** Tier 3 #5 (`b8jjayskx`) just finished AT THE END OF THE SESSION with `r(3900)` out-of-memory inside `editmissing()` in the GMM derivative evaluator (Step 2 iteration 10 of some cell).
1365 sters on disk (was 1010 at Tier 3 #4 launch, +355 cells this run).
28 error markers in `RP7/scripts/_smoke_full.log` (1.8 MB).
The crash is internal to Stata mata (different from Tier 3 #4's silent external kill); it's a fresh issue, not a continuation of the M4 work.

**Next concrete actions, in priority order:**
1. Diagnose the `r(3900) editmissing(): out of memory` crash.
Locate the cell that was running when memory blew up.
Check whether it's a single problematic cell (e.g. one with too many trajectories or an unusually large $N$) or a generic memory leak across the smoke driver.
2. **MUST** relaunch Tier 3 #6 with `skip_if_exists=1` (the M10 skip-on-exists guard inside `run_grc`).
1365 sters are already on disk from Tier 3 #4 + #5; rerunning from scratch would burn ~70 hours of compute regenerating identical numbers.
The skip guard is in `0_programs.do` `run_grc` near line 1846 (`capture confirm file "$output/`estname'_g${vsfx}.ster"`); the smoke driver passes `skip_if_exists` through.
Verify the smoke driver still has it set to 1 before launching---it was set to 1 for #5, but make sure no edit since then changed it.
3. After Tier 3 closes, the worktree branch `worktree-grc-pipeline-refactor` is ready for PR review against `main`.
The audit-and-fixes work, M3 + S3 + Δ̄ + M4 + extras dispatch + hukou merge + mu-loop dedup + Phase 1b.6 spacing all in one stack.
4. (Optional) clean up untracked `RP7/output/test_*` transient files; add `RP7/output/test_*` to `.gitignore` so future test drivers don't pollute the diff.

**State to know:**
- Branch `worktree-grc-pipeline-refactor` last commit `7448f6a`.
- Working tree clean except `.claude/settings.local.json`, `.claude/scheduled_tasks.lock`, and untracked transient test outputs in `RP7/output/`.
- Tier 3 #5 task ID `b8jjayskx` still running in the background.
- prose-rules-enforcer flag is set this session (voice.md and manuscript-writing.md were Read).
Resets next session.
- MCP `default` Stata session reported as `stopped` with dead pid 17924 earlier in session; not relevant unless next session tries to use MCP.
- Live Overleaf preamble.tex has the `\@empty` -> `\empty` fix applied; that file is outside the git tree.

### Commits landed this session

In order:
- `b3b021d` (yesterday) M4 stage 1+3: values switch in 0_path_config + ${vsfx} on all output paths.
- `5fbe30b` (yesterday) M4 stage 2: gitignore RP7/data_real + document junction in CLAUDE.md.
- `b8530a7` (yesterday) M4 verification harness: 4-test driver for values switch.
- `d896edd` (this morning) M4 verification harness fixes (`_b[Delta_avg]`, `quietly` wrappers) + 2026-05-01 session log.
- `49e05d4` (today) M4 verification harness PASSED on grc_IDN_cub_c0 (4/4 tests) + driver hardening.
- `f68892e` (today) Phase 1b.6: strip esttab's blank tabular rows in grc_tex_table_trend.
- `7448f6a` (today) Fix `\@empty` bug in GRC macros staging draft.

---

## Continuation 2026-05-02: Tier 3 #6 launch + PR prep + Tier 1 lint

Resumed after `/clear`.
User confirmed yesterday's OOM diagnosis: the `editmissing()` failure in Tier 3 #5 was likely caused by a parallel R process competing for RAM, not a code-side leak.
That makes per-cell forensic on the OOM unnecessary.
Plan: relaunch Tier 3 #6 with `skip_if_exists=1` and work other tasks in parallel.

### Tier 3 #6 launched

Confirmed `RP7/scripts/_smoke_full.do` L57 still has `global skip_if_exists 1` and `0_programs.do` L1845 still has the M10 guard.
Archived the prior 1.8 MB OOM log to `_smoke_full.tier3-5_OOM_2026-05-01.log` so the new run does not overwrite it.
Launched batch `bayt3x4r5` from `RP7/scripts/`.
Confirmed alive at 12:43:27 (log size 497 KB at 3 min, mid-GMM iteration of an early cell).
Error/completion monitor armed twice: `b166y7uz7` (timed out at 1 hr), re-armed as `bfomr7mm4` (3-hr window).
1365 sters on disk at relaunch; 263 of those are `_g.ster` (the suffix the M10 guard checks).

### Three commits while Tier 3 ran

User chose three separate atomic commits over a bundled one.
Commits in order:

- `1fe0250` `.gitignore`: ignore `RP7/output/test_*` transient test artifacts (the addlinespace investigation outputs).
- `c46de1a` Add [tests/tier2_table_diff.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/tier2_table_diff.py): classified Tier 2 byte-identity check.
  Walks every reference table, computes per-file unified diffs against live, classifies hunks as `LABEL_FLIP` / `BLANK_ROW` / `ADDLINESPACE` / `UNEXPECTED`.
  Exit code is the count of files with at least one `UNEXPECTED` hunk (0 = clean Tier 2 pass).
  review-python subagent gave it 96/100; the only minor finding (no `requirements.txt`) was non-actionable for a stdlib-only script.
- `b1387e0` Draft PR description for the GRC pipeline refactor branch at [quality_reports/reviews/2026-05-02_PR-description-draft.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_PR-description-draft.md).
  Title, summary, change-by-area, verification-status table (PENDING/IN PROGRESS rows for Tier 2 / Tier 3), open items, reviewer notes.

### Tier 1 lint sweep ran clean

Five Tier 1 checks (per spec section 4b):

- Old-suffix references (`_avg.ster` etc.) in do-files: PASS (zero hits).
  The `_avg`/`_never`/`_always`/`_delta` matches that came up in `0_programs.do` are `nlcom` equation names, not file suffixes; the file documents this at L30--33.
- Dead-script `include` references (10/11/12/13/14/15/16/3): PASS (zero hits).
- Estname construction uses M11 shorthand (`cuu`/`cub`/`iuu`/`cnu`): PASS.
- 32-char `_est_` ceiling: PASS with at minimum 2 chars of slack.
  Longest production stem is `grc_TZA_iuu_maxexpsh_ca_g` (25 chars) → 30 internal name.
- Script inventory: 13 files in `RP7/scripts/`, matches the spec target.
  S2 not fully shipped: `2_OLS_uGRC.do` and `7_OLS_uGRC_hukou.do` still separate; `9_learning.do` not renamed; `make_tables.do` replaces `16_*` rather than rename.

Lint review at [quality_reports/reviews/2026-05-02_tier1-lint.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_tier1-lint.md).

### Pre-M11 orphan sters surfaced (Check 6)

Off-spec finding while running the length budget:
**75 leftover sters** in `RP7/output/` from before commit `ddb3886` (M11 / Phase 1a):

- 60 with old suffix words: `*_always.ster`, `*_never.ster`, `*_delta.ster`, `*_avg.ster`.
- 15 main-fit sters with the old `urban_covs_*` and `nonag_covs_*` naming.

No live do-file writes or reads them.
They coexist on disk with the new-naming sters Tier 3 #6 is producing.
A 31-char stem like `grc_TZA_urban_covs_trend_always` busts the `_est_` ceiling if anyone tries to load it interactively, so the dead files are a foot-gun for future-me.
**Cleanup is paused** until the user explicitly approves the `rm` --- the directory is shared replication-package output, not local-only.

### Decisions, with the why

**Decision: skip per-cell forensic on the Tier 3 #5 OOM.**
Why: user confirmed the proximate cause is a parallel R process competing for RAM, not a code-side leak.
A per-cell investigation would have spent hours fingerprinting whichever cell happened to be running when system memory tightened, with no actionable code change at the end.
The right mitigation is operational (don't run heavy R alongside Tier 3), not algorithmic.

**Decision: archive prior OOM log to a timestamped name before the relaunch.**
Why: `stata-mp -b` overwrites `<file>.log` by default.
The 1.8 MB Tier 3 #5 log has 28 error markers that may matter for post-mortem if the OOM recurs.
Cost of preserving: a single `mv`.
Cost of losing it: irrecoverable.

**Decision: separate commits for each artifact (.gitignore, harness, PR draft) instead of one bundled commit.**
User preference, explicit in this session.
Why: each commit captures one logical change so the edit history is meaningful (per CLAUDE.md "atomic commits frequently").
The three artifacts share no semantic dependency; bundling would have made a future bisect harder.

**Decision: keep human-readable .tex table names; do not rename to match M11 ster shorthand.**
Why: tables are paper-facing, sters are code-facing.
`GRC_IDN_consumption_urban_unb.tex` is recognizable to a coauthor; `GRC_IDN_cuu.tex` is not without the legend.
Renaming would also re-freeze the Tier 0 reference snapshot, which would invalidate the Tier 2 byte-identity check we are about to run.
Targeted exception: standardize the experience-family abbreviation so .tex names match ster names (`exp_m_sh` → `maxexpsh` etc.); narrower scope, higher payoff.
Full rename can be revisited as its own phase post-PR.

### Approaches rejected

**Rejected: deleting the 75 orphan sters during this session.**
Why: Tier 3 #6 is mid-flight, writing into the same directory.
A `rm` issued now risks racing with the batch's writes (different filenames in this case, but the discipline is conservative: don't `rm` from a directory with an active writer).
Punted to post-Tier-3 with an explicit user go/no-go.

**Rejected: bundling .gitignore + tier2 harness + PR draft into one commit.**
Why: see "Decisions" above; user preference.
Took roughly the same total time as the bundled commit because the working tree changes were already segmented.

**Rejected: running the Tier 2 harness now against the stale 12 live tables.**
Why: the live `RP7/output/tables/` only has 12 of the 53 reference tables (the smoke driver explicitly skips `make_tables.do`; tables get rebuilt only when `_smoke_tables_only.do` runs separately).
Running the harness against partial output would produce a noisy "missing in live" report that obscures the real Tier 2 result.
Defer to post-Tier-3 + `_smoke_tables_only.do`.

### Files changed

- [.gitignore](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/.gitignore): one new entry, `RP7/output/test_*`.
- [tests/tier2_table_diff.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/tier2_table_diff.py): new file, 271 lines.
- [quality_reports/reviews/2026-05-02_PR-description-draft.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_PR-description-draft.md): new file.
- [quality_reports/reviews/2026-05-02_tier1-lint.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_tier1-lint.md): new file (uncommitted at log time).

Disk-only changes:

- `RP7/scripts/_smoke_full.tier3-5_OOM_2026-05-01.log`: archived OOM log (1.8 MB).
- `RP7/scripts/_smoke_full.log`: live Tier 3 #6 log, growing as the batch runs.

### Open items

User just expanded scope at the end of the session:

1. Tier 1 lint sweep: DONE, review committed below; 75 orphan sters await cleanup approval.
2. Audit `tests/regression_test.py` (older M7 scaffold) vs the new `tier2_table_diff.py`; decide if one supersedes the other or if they cover different ground.
3. Plan for the S1 ster scraper.
   User said this "deserves its own plan" --- write the plan, do not implement until approved.
4. Append a "shipped vs deferred" status footer to the umbrella refactor spec.
5. MEMORY.md hygiene pass: prune entries that are stale (e.g. ster-count snapshots, the agent-archiving question if since resolved).

Tier 2 byte-identity check still parked until Tier 3 #6 closes and `_smoke_tables_only.do` regenerates the 53 production tables.
PR creation also parked: not mergeable until Tier 2 reports zero `UNEXPECTED` diffs.

### Status as of session log time

- Branch `worktree-grc-pipeline-refactor` last commit `b1387e0` (PR draft).
- Tier 3 #6 batch `bayt3x4r5` running in background.
- Error/completion monitor `bfomr7mm4` armed for 3 hours.
- Working tree: `quality_reports/reviews/2026-05-02_tier1-lint.md` uncommitted.

### Picking back up

**If you resume:** read this continuation block top to bottom, then walk down "Open items" 2--5 in whatever order looks productive.
The 75-orphan-ster cleanup is the only item that requires explicit user approval before action.

**Next concrete actions:**

1. Commit the Tier 1 lint review.
2. Open `tests/regression_test.py`, `tests/compare_tabular_bodies.py`, and `tests/tier2_table_diff.py` side by side.
   Decide if any are redundant.
   Document the verdict in a short note or by deleting/merging.
3. Draft the S1 plan as `docs/plans/2026-05-02-s1-ster-scraper.md`.
   No implementation in the same session.
4. Spec status footer: append a "shipped vs deferred" table to [`quality_reports/specs/2026-04-24_grc-pipeline-refactor.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md).
5. MEMORY.md prune: read top to bottom, mark stale entries for removal, ask user to confirm before deleting.

### Commits landed in 2026-05-02 continuation

- `1fe0250` `.gitignore`: ignore `RP7/output/test_*` transient test artifacts.
- `c46de1a` Add `tests/tier2_table_diff.py`: classified Tier 2 byte-identity check.
- `b1387e0` Draft PR description for the GRC pipeline refactor branch.
- `ce0798a` Add Tier 1 lint review.
- `6a8d35d` Session log: 2026-05-02 continuation.
- `7aee16e` Audit: `tier2_table_diff.py` supersedes `regression_test.py` plus `compare_tabular_bodies.py`.
- `6974593` Plan: S1 ster scraper (results-overview CSV).
- `b696d58` Spec: append PR-time status footer (section 10).

---

## Continuation 2026-05-02 evening: harness bugs surfaced, Tier 3 still grinding

User stepped away after approving items 2--5; auto-mode work proceeded through items 4 (spec status footer) and 5 (MEMORY.md hygiene).
Then a single low-risk action while waiting on input: a dry-run of `tier2_table_diff.py` against one of the 12 currently-stale live tables (`GRC_CHN_consumption_urban_unb.tex`) to validate classification logic.
The dry-run surfaced two real bugs in the harness.

### Two bugs in tier2_table_diff.py

**Bug 1: LABEL_FLIP fails on the Δbar rename.**
The classifier substitutes `Average $\Delta$` for `$\bar{\Delta}$` in the removed line and checks for byte-equality against the added line.
That fails because esttab right-pads the label cell to a fixed width.
The pre-rename label `Average $\Delta$    ` (16 chars + 4 trailing spaces) is wider than the post-rename label `$\bar{\Delta}$      ` (13 chars + 6 trailing spaces).
Substitution preserves the original 4 trailing spaces; the live line has 6.
Result: the classifier reports `LABEL_FLIP=0` instead of 1 for any file containing the rename.

**Bug 2: Phase 1b.6 blank-row removal half-classified.**
Phase 1b.6 does not delete the blank tabular rows; it leaves an empty line where each `& & & ... & \\` row used to be.
The diff hunks are (-1, +1) per blank row.
The removed line correctly matches `BLANK_ROW_RE`, but the added empty line does not match anything and falls into `UNEXPECTED`.
Result: every blank row counts as 1 BLANK_ROW + 1 UNEXPECTED.

Dry-run output for `GRC_CHN_consumption_urban_unb.tex`:

```
clean : 0 / expected only : 0 / UNEXPECTED : 1 / missing live : 4
LABEL_FLIP=0 BLANK_ROW=3 ADDLINESPACE=0 UNEXPECTED=5
```

Expected output if the harness were correct:

```
expected only : 1 / UNEXPECTED : 0
LABEL_FLIP=1 BLANK_ROW=6 (3 removed + 3 empty added) UNEXPECTED=0
```

### Fix proposed, awaiting user approval

Per `~/.claude/rules/script-safety.md`, "bug fixes in scripts all require user approval before editing."
Two localized edits in `tests/tier2_table_diff.py` (~10 lines total):

1. `LABEL_FLIP` matching: split the row at the first `&`; compare post-`&` parts byte-equal; pre-`&` parts must match the rename pattern modulo trailing whitespace.
2. `BLANK_ROW` classification: extend `classify_line` to also flag empty / whitespace-only lines as `BLANK_ROW`, so both sides of a (-1, +1) blank-row hunk classify together.

Both fixes are bounded, easy to retest with the same dry-run command.

### Decisions, with the why

**Decision: dry-run the Tier 2 harness before the real Tier 2 run depended on it.**
Why: the harness is the canonical Tier 2 gate per the spec status footer.
Discovering classification bugs after the real Tier 2 run would mean either a manual triage of every "UNEXPECTED" hit or a re-run of `_smoke_tables_only.do`.
Dry-run cost: one Python invocation + one .diff file to delete.
Catching both bugs on the first try paid for itself.

**Decision: do not auto-fix the bugs without approval.**
Why: project rule explicitly requires user sign-off for script bug fixes.
Even though the bugs are in code I wrote in this session, the rule is path-scoped to all scripts.
The cost of waiting (a few hours) is low; the value of preserving the rule is meaningful.

### Tier 3 #6 still healthy

Hourly heartbeat checks throughout the afternoon and evening:

| Time | `_g.ster` count | Log mtime |
|---|---|---|
| 12:43 | 261 | active |
| 16:12 | 263 | mid-fit |
| 17:38 | 265 | mid-fit |
| 18:20 | 266 | mid-fit |
| 19:38 | 268 | mid-fit |
| 20:20 | 269 | mid-fit |
| 21:02 | 270 | mid-fit |
| 22:40 | 272 | mid-fit |

About 1--2 cells per hour, which is slower than yesterday's pace but consistent with the longer GMM convergence times on the larger covariate sets.
No errors trapped by the monitor across 7 successive 1-hour windows (which is why "monitor timed out -- re-arm if needed" notifications kept arriving; that is the no-event healthy outcome).

### Files changed since the previous log block

- [`quality_reports/reviews/2026-05-02_test-harness-audit.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_test-harness-audit.md): three-harness audit, recommends deletion of older two.
- [`docs/plans/2026-05-02-s1-ster-scraper.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/plans/2026-05-02-s1-ster-scraper.md): S1 plan with 4 open questions for user.
- [`quality_reports/specs/2026-04-24_grc-pipeline-refactor.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md): appended section 10 status footer.
- `MEMORY.md` (user-global, outside the repo): three prunes (collapsed duplicate "real values" entry; updated stale 22-.do count to 13; removed stale 2026-03-12 currentDate line).
- [`RP7/output/tier2_diffs/GRC_CHN_consumption_urban_unb.tex.diff`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/tier2_diffs/GRC_CHN_consumption_urban_unb.tex.diff): dry-run artifact; should be deleted before the real Tier 2 run.

### Open items at log time

User input pending on:

1. Approve the two `tier2_table_diff.py` bug fixes (LABEL_FLIP whitespace tolerance; BLANK_ROW empty-line side).
2. Approve deletion of `tests/regression_test.py` and `tests/compare_tabular_bodies.py` per the harness audit.
3. Answer the four open questions in [docs/plans/2026-05-02-s1-ster-scraper.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/plans/2026-05-02-s1-ster-scraper.md) section 8 before S1 implementation starts.
4. Approve cleanup of the dry-run artifact in `RP7/output/tier2_diffs/`.

Tier 3 #6 still running.
Tier 2 still parked until the smoke closes and `_smoke_tables_only.do` regenerates the production tables.
PR creation also parked.

### Picking back up

**If you resume:** read the "Two bugs" subsection above; the proposed fix is small.
The four user-input gates above are the only blockers on PR-readiness besides Tier 3 closing.
Once user approves the harness fixes, retest with the same `--filter` invocation, then run unfiltered to spot any other surprises before the real Tier 2.

### Commits landed in 2026-05-02 evening continuation

None.
This block is a status update; no code or doc edits since `b696d58` except this session log append.
