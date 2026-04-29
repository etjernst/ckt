# Session log 2026-04-29

Branch: `worktree-grc-pipeline-refactor`.
Continuation of the 2026-04-28 Phase 1b.6 work.
Tier 3 (`bdop8w15m`) launched 2026-04-28 ~22:38; running this entire session.

## Tier 3 progress at end of session

| Time | Sters (`_g`) | Where in pipeline |
|------|--------------|-------------------|
| 2026-04-28 ~22:38 | ~17 | Just launched, 5_GrRC.do start |
| 2026-04-29 06:58 | 54 | Mid-5_GrRC.do |
| 2026-04-29 08:21 | 59 | 5 done; in 6_GrRC_NonAg.do at IDN cnu_ct |
| 2026-04-29 09:04 | 60 | In 6_GrRC_NonAg.do at IDN cnu_c1 |

The IDN cnu_c1 cell took ~43 minutes (08:21 to 09:04), which is slow for a single GMM fit.
At this pace, 6_GrRC_NonAg.do finishes the remaining c2/c3/ca cells in maybe 1.5 hours, after which Tier 3 enters `8_GrRC_hukou.do`.
The C1 timer bug fires there (see "Open" section below).

## What we did this session

### 1. Pipeline best-practice audit

Spawned the `stata-critic` subagent over `RP7/scripts/0_programs.do` and the rest of the live pipeline.
Result: 27 findings (2 critical, 8 major, 17 minor) saved to [docs/reviews/2026-04-28_pipeline-best-practices.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/reviews/2026-04-28_pipeline-best-practices.md).

### 2. Data-creation scripts audit (Dropbox)

Spawned a second `stata-critic` over five Dropbox data-prep scripts plus `RP7/scripts/1_processData.do`.
Result: 12 findings (0 critical, 5 major, 7 minor) appended to the same review document.
Includes a real-vs-nominal divergence appendix that compares `250314 Data preparation_DB.do` to `260302 Data preparation real values_DB.do`, and `230328 Variable selection_DB_MK.do` to `260424 Variable selection TZA real values_DB.do`.
This is the practical input for the future "collapse two parallel scripts into one" refactor.
User deferred all data-creation findings to a later session.

### 3. M2 retraction

User pointed out that Stata supports only one open log at a time, so the master-log recommendation in M2 is impossible.
M2 downgraded to MINOR (only the `set more off` part survived).

### 4. Audit batch 1 (commit 73588da)

Applied the user-authorized safe fixes:

- M1: `version 17` at top of `0_master.do`.
- M2: `set more off` at top of `0_master.do`.
- m3: `global grc_min_switchers_per_wave 5` in `0_master.do` (replaces magic 5 in `initial_values`).
- m4: `global grc_max_iter 100` in `0_master.do` (replaces magic 100 in driver files).
- m10: added `, replace` to all 9 `label define mega_trajectories[_2waves|_3waves]` calls in `make_figures.do` so CHN and TZA bar graphs re-define the label cleanly instead of silently inheriting IDN's.
- m11: replaced stale "Creates table of rGRC estimates" boilerplate in `make_tables.do` heterogeneity section with a concise description.
- m12: moved `$overleaf` from a hardcoded maand-specific fallback in `0_path_config.do` into per-user blocks in `0_master.do`. `copyOverleaf` now exits silently if `$overleaf` is unset.
- m15: added `graph export ... .png, replace` lines next to the trajectories PDF exports.

Pipeline files (5/6/8/GRC_extras) still hold the magic 5 and 100 locals; future PRs will swap to globals.
Tier 3 was unaffected because it loaded `0_programs.do` once at start.

### 5. Audit batch 2 (commit f2f392c)

- M3: added `assert_merge_clean` helper to `0_programs.do`.
Takes `allow()` list of acceptable `_merge` values, prints a one-line diagnostic, errors out on disallowed values, optionally drops master-only or using-only rows via `drop_unmatched()`, always drops `_merge` at the end.
Future PRs will retrofit this helper into the data-prep merges that currently use `nogen`.
- M7 (urgent per user): fixed the shadow `eststo` in `ugrc_regressions`.
First `reghdfe ... absorb(pid)` now runs `quietly` without `eststo` (just to capture `e(sample)`); the second `eststo reg7_<country>` adds `if regression_sample` so all seven columns share a common sample.
This matches the `reghdfe_regressions` pattern and the original comment "Run col 7 first as it has the smallest sample, then use e(sample)".
- M4 test: `tests/test_gmm_from_duplicate.do` written (not run yet; deferred to avoid Stata popups during Tier 3).
Compares macro-string lengths and `gmm` convergence with and without duplicate `from()` entries, to verify whether the doubled mu-loop in `initial_values` actually doubles the local string.

Also tidied: moved `capture program drop copyOverleaf` next to its `program define copyOverleaf` (was orphaned far above when `assert_merge_clean` got inserted between them).

### 6. M6 + m6 investigations

User asked me to investigate both questions myself.
Findings:

- M6: the `summary_stats_<country>_<balance>.csv` files are one-trip intermediates produced by `iebaltab` (which only writes CSV).
The program immediately `import delimited`s the file back, tweaks the in-memory data, and the caller (`1_summaryStats.do`) converts the in-memory data to LaTeX via `sumstats_table` to `$output/tables/summary_stats_<country>_<balance>.tex`.
The CSV file is never cleaned up; it persists in `$logs` after each run.
Fix: use `tempfile` or write to a known path then `erase` after import.
No table impact.

- m6: the `_2waves` / `_3waves` variants are not vestigial.
They produce distinct trajectory variables (`trajectory_2waves`, `trajectory_3waves`) that drive specific descriptive outputs---the 2-wave and 3-wave trajectory bar graphs in `make_figures.do`.
The hardcoded string enumeration is brittle in theory but the user said the trajectory string encoding will never change, so the audit concern is moot.
Possible future refactor: unify all three under a parameterized `handle_trajectory_groups_window(n_waves)`.

## Outstanding decisions

1. **C1 timing.**
Tier 3 will hit `8_GrRC_hukou.do` in roughly 1.5 hours.
The `run_grc_hukou` timer bug will fire on the first `timer off` call there (empty `_tslot` macro).
Two options:
   - Let it crash, fix `run_grc_hukou` afterwards, restart Tier 3; skip-if-exists preserves all 5 + 6 sters and any hukou cells that completed before the crash.
   The crash will fire at the FIRST `timer off` call, so probably zero hukou cells survive.
   - Kill Tier 3 now, fix `run_grc_hukou`, restart.
   Loses no work because we've checkpointed everything via skip-if-exists.

2. **m13 status.** The `data_path_override` expansion is documented and works. Marked TRIVIA; can be skipped or noted in a comment.

## Post-Tier 3 cleanup queue

In rough priority order:

1. **Kill `$lnsize`.** Five `keepvars` references in `5_GrRC.do` (line 545) and `8_GrRC_hukou.do` (lines 253, 555, 857, 1159), one in `run_grc_with_extra_regressor` (the `KEEPLNsize` option), one comment in `0_programs.do`.
Pure vestige from David's OLS code where `$lnsize "loghhsize"` was a covariate.
Current GMM bakes hh-size adjustment into `lndepvar = log(consumption/hhsize_cube)` and the `$lnsize` slot does nothing.
If anything breaks after removal, the regression test will catch it.

2. **Fix the smoke-test overwrite policy.**
`_smoke_full.do` currently sets `global skip_if_exists 1` for resume-on-interrupt.
For verification semantics we want overwrite-by-default.
Plan: default to `global skip_if_exists 0`; create a separate `_smoke_resume.do` driver that explicitly sets it to 1 for resume mode.

3. **m1: `cd "$logs"` -> `log using "$logs/..."`.**
Pattern appears in every numbered `.do` file.
Fix the ones Tier 3 doesn't touch first (1, 2, 7, 9, `0_CHN_hukou_restrictions`, `make_tables`, `make_figures`); fix 5/6/8/GRC_extras after Tier 3 finishes.

4. **m5: delete deprecated `grc_tex_table`.**
80 lines around line 2864 of `0_programs.do`.
Whitespace mismatches blocked the Edit this session; retry with a fresh Read.

5. **C1 + M5 (`run_grc_hukou`).**
Add the timer-slot init block (4 lines, copied verbatim from `run_grc` lines 1798--1801).
Add the optional `phistart(real -0.1)` argument and substitute `\`phistart'` for the hardcoded `-0.1` in the `gmm` equation.

6. **M4 test run.**
`tests/test_gmm_from_duplicate.do` produces a definitive answer about whether the doubled mu-loop wastes string space (likely yes) and whether it affects gmm convergence (likely no).

7. **Pipeline files: swap magic numbers to globals.**
Replace `local iterations 100` in 5/6/8/GRC_extras/make_tables with `local iterations $grc_max_iter`.
Replace `if N_\`s' / T > 5` in `initial_values` and `initial_values_robust` with `if N_\`s' / T > $grc_min_switchers_per_wave`.

8. **m6 retrofit `assert_merge_clean`.**
Update the data-prep merges that currently use `nogen` to use the new helper.
Files affected: data-prep code in `0_programs.do` (lines 295, 354, 412 in `handle_trajectory_groups` and the 2/3-waves variants).

9. **m2: `cap` -> `capture` consistency pass** in `0_programs.do`.

10. **m14: schemepack install bug** in `0_setup.do`.
Logic inversion + wrong variable name.

11. **m16: hardcoded panel headers** in `create_panel_tex_table*` programs.
Derive from `countries()` argument instead.

## Deferred (data-creation scripts; will need a later session)

User: come back to the pipeline review for the sections on data construction since I don't have time now.

12 findings on the Dropbox scripts queued; reminders:

- DC-M1 (TZA inner join silent attrition).
- DC-M2 (IDN hhsize unconditional replace).
- DC-M3 (undocumented deflation base year for IDN/CHN).
- DC-M4 (no `version` declaration / no log).
- DC-M5 (1_processData.do has no `version`, log, or post-save sanity check).
- 7 minors: `cd` pattern, CHN experience merges without diagnostics, `set mem 250m` obsolete, "empoyment" typo, `lncons_tot` real-in-nominal label confusion, TZA `consfood` "nominal" label in real file, TZA `nonag` household-level definition.
- The real-vs-nominal divergence appendix is the practical input for the planned "collapse two parallel scripts into one" refactor.

## Tracking files

- [docs/reviews/2026-04-28_pipeline-best-practices.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/reviews/2026-04-28_pipeline-best-practices.md): the audit, all 39 findings.
- [docs/plans/2026-04-29-audit-action-plan.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/plans/2026-04-29-audit-action-plan.md): user's response to each finding (NOW / POST-T3 / TODO / WAIT / SKIP).
- [tests/test_gmm_from_duplicate.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/test_gmm_from_duplicate.do): M4 test, not yet run.

## Commits this session

| Hash | Description |
|------|-------------|
| `1cb8cf3` | Pipeline best-practice audit + data-creation scripts audit + post-Tier-3 cleanup queue |
| `b664422` | Audit: retract master-log recommendation in M2 |
| `73588da` | Audit batch 1: M1 / M2 / m3 / m4 / m10 / m11 / m12 / m15 |
| `f2f392c` | Audit batch 2: M3 helper / M7 ugrc_regressions sample fix / M4 test |
| `7c6d99f` | Session log 2026-04-29 (this file) |
| `7e80f6c` | C1 + M5 + M6 fixes: run_grc_hukou timer + phistart + summary CSV path |
| (commit) | Verification harness: 12/12 tabular bodies match RP6 |
| `8259fd8` | Audit batch 3: kill `$lnsize` / magic numbers to globals / m1 cd-pattern / m5 tombstone |

## Tier 3 status when killed (2026-04-29 ~09:33)

Killed by user at 09:33 mid-`6_GrRC_NonAg.do` (in IDN cnu_c2's GMM Step 2).
60 `_g.ster` files preserved on disk.
Skip-if-exists guard in `_smoke_full.do` will pick up at IDN cnu_c2 on relaunch.

## Verification of partial Tier 3 output

Ran `_smoke_tables_only.do` on the 60 surviving sters; got 12 `.tex` tables (9 main 5_GrRC + 3 leftovers from earlier debug smokes).
Wrote `tests/compare_tabular_bodies.py` to extract `\begin{tabular}...\end{tabular}` from RP6 references and compare with the SLIM live tables.
Result: **12 matched bit-identical, 0 differed, 41 missing in live (expected---no GRC_extras or hukou run yet)**.
Confirms the disambiguated Phase 1b.6 code reproduces RP6 numbers exactly for every cell with sters.

## Audit batch 3 (commit `8259fd8`) summary

- C2: `$lnsize` removed from 5 keepvars references in 5_GrRC.do (1) and 8_GrRC_hukou.do (4), and from the dispatch in `run_grc_with_extra_regressor` in 0_programs.do.
Also dropped the unused `KEEPLNsize` option from the program.
- m3 / m4: pipeline files now reference `$grc_max_iter` and `$grc_min_switchers_per_wave` (set in `0_master.do`) instead of the hardcoded 100 and 5.
- m1: removed `cd "$logs"` from all 11 sub-scripts; switched to `log using "$logs/<file>.log"`.
- m5: deprecated `grc_tex_table` program removed (Python line-delete; the Edit tool failed twice on whitespace mismatches in the 80-line block). 4-line tombstone comment in its place.

## State at end of session

**Done this session (3 audit batches + verification + critical fixes):** M1, M2, M3, M5, M6 (path + erase), M7, m1, m3, m4, m5, m10, m11, m12, m15, C1, C2 (= `$lnsize` kill), 12-table verification.

**Files in clean state ready for relaunch:**
- `0_programs.do`: new `run_grc_with_extra_regressor`, new `extras_tex_table`, new `assert_merge_clean`, fixed `run_grc_hukou` (C1 + M5), fixed `ugrc_regressions` (M7), removed `grc_tex_table` deprecated, summary-stats CSV writes to `$logs/` and erases.
- `0_master.do`: version 17, set more off, project globals (`$grc_max_iter`, `$grc_min_switchers_per_wave`), `$overleaf` per-user.
- `0_path_config.do`: empty-string fallback for `$overleaf` (warns instead of silently using maand path).
- `5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `GRC_extras.do`: log-using full-path; `$grc_max_iter`; no `$lnsize`.
- `make_tables.do`: log-using full-path; cleaner header; 44 extras family cells; orphan `cd` lines removed.
- `make_figures.do`: log-using full-path; `label define ..., replace` on all 9 occurrences; PNG export for trajectory bar graphs.

**Sters on disk (60 `_g`):**
- 54 from 5_GrRC.do (cuu/cub/iuu × IDN/CHN/TZA × 6 fits)
- 6 from 6_GrRC_NonAg.do (IDN cnu_{c0,ct,c1} × main+_n+_g sters; cnu_{c2,c3,ca} pending)

## How to pick this up next session

### Quick health check
```bash
cd C:/git/ckt/.claude/worktrees/grc-pipeline-refactor
git log --oneline -10
ls RP7/output/grc_*_*_g.ster | wc -l    # expect 60
python tests/compare_tabular_bodies.py  # expect 12 matched / 0 differed
```

### Remaining cleanup before relaunch (optional, in priority order)

1. **Smoke-test overwrite policy.**
Flip `_smoke_full.do`'s `global skip_if_exists 1` to 0 by default; create a separate `_smoke_resume.do` driver that explicitly sets `skip_if_exists 1` for resume mode.
Today's relaunch can stay with `skip_if_exists 1` since the 60 surviving sters are valid; the policy change is for future runs.

2. **M4 test run.**
`tests/test_gmm_from_duplicate.do` is written but not yet executed.
One Stata invocation; ~1 minute wall time; settles whether the doubled mu-loop in `initial_values` actually doubles the macro string.

3. **m6 retrofit `assert_merge_clean`.**
Update merges in `handle_trajectory_groups` and the 2/3-waves variants to use the new helper instead of `nogen`.
Adds diagnostics; no behavioral change.

4. **m2: cap -> capture consistency pass** in 0_programs.do.
Bulk one-line replacement.

5. **m14: schemepack install bug** in 0_setup.do.
Logic inversion + wrong variable name.

6. **m16: hardcoded panel headers** in `create_panel_tex_table*` programs.
Derive from `countries()` argument.

### Relaunch Tier 3

When ready:
```bash
cd RP7/scripts && stata-mp -b do _smoke_full.do
```

Will resume at IDN cnu_c2 (skip-if-exists preserves the 60 existing sters).
Wall clock: ~20-30 hours.
8_GrRC_hukou.do is now safe (C1 timer fix in place).

### Deferred (data-creation scripts)

User: come back to data-construction findings (DC-M1 through DC-M5, DC-m1 through DC-m7) when ready.
12 findings on Dropbox scripts; reminders in this log and in [docs/plans/2026-04-29-audit-action-plan.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/plans/2026-04-29-audit-action-plan.md).

### Open questions

- m13 (`data_path_override` expansion explained): probably TRIVIA / SKIP. Confirm with user.
- m6 (2waves/3waves variants): confirmed not vestigial; possible future TODO to unify under `handle_trajectory_groups_window(n_waves)`.

## Continuation: afternoon work (2026-04-29)

User picked up the cleanup queue: M4 + m6 retrofit + m2 in parallel, then Tier 3 relaunch.

### M4 test (RESOLVED)

Ran [tests/test_gmm_from_duplicate.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/test_gmm_from_duplicate.do) (~1 sec wall).
Macro string: 108 chars (one mu-loop) vs 203 chars (two mu-loops); ratio 1.88x.
Stata's local accumulator does not deduplicate.
gmm with same-value duplicates returns the baseline fit bit-identically; with different-value duplicates also matches (caveat: the test model is exactly identified, so OLS regardless of `from()`).
Verdict: doubled mu-loop wastes about 2x macro space but is harmless because the duplicated `mu_<s>` scalars carry the same value.
Cleanup of the second `foreach` is deferred to a separate Implementation-mode commit since it touches estimation code.

### m6 retrofit `assert_merge_clean`

Replaced `nogen` with `assert_merge_clean, allow(1 3)` at all three trajectory-group merge sites:
`handle_trajectory_groups` (L368), `handle_trajectory_groups_2waves` (L427), `handle_trajectory_groups_3waves` (L485).
All three accept `allow(1 3)` because `using` is built as a strict subset of master pids (balanced subset / `pid_obs >= 2` / `pid_obs >= 3`), so `_merge==2` should never appear.
Adds a per-merge diagnostic line; no rows dropped; no behavioral change.

### m2 cap to capture pass

Bulk replaced `\bcap\b` with `capture` in `0_programs.do` (Python regex; 34 occurrences, all `cap program drop ...`).
Pure stylistic; no behavioral change.

### Two crash bugs surfaced on Tier 3 relaunch

The first relaunch hit the new m12 path-config code and crashed at `r(198)` on a `di` statement.
The line `di as error "Add 'global overleaf \"<path>\"' ..."` used `\"` to embed a literal `"`, but Stata's plain double-quoted strings do not recognize backslash escapes.
The parser saw `"Add 'global overleaf \"`, closed the string, and then tried to read `<path>\"...` as a name.
Fix: drop the literal-quote requirement and use SMCL italic markup `{it:global overleaf <path>}` instead.

The second relaunch cleared the path-config block but crashed inside `initial_values` on `if N_\`s' / T > $grc_min_switchers_per_wave {`.
Root cause: the project globals (`$grc_max_iter`, `$grc_min_switchers_per_wave`) were set in `0_master.do` (audit batch 1, commit 73588da), but `_smoke_full.do` bypasses `0_master.do` (it sets only `$dir` for the current user, then includes `0_path_config.do`, `0_setup.do`, `0_programs.do` directly).
Both globals expanded to empty strings under the smoke driver; `if N_2 / T >  {` raised `r(198) "invalid name"`.
Yesterday's overnight Tier 3 launch (2026-04-28 ~22:38) did not crash because audit batch 1 was committed AFTER that launch; the run used the older code with hardcoded local literals 100 and 5.

Fix: move both globals from `0_master.do` to `0_path_config.do`, which all entry points include unconditionally.
They are project-wide constants, not per-user, so `0_path_config.do` is the right home anyway.
Verified by grep: seven smoke and tier drivers (`_smoke_5_GrRC.do`, `_smoke_extras_dispatch.do`, `_smoke_extras_one.do`, `_smoke_full.do`, `_smoke_idn_only.do`, `_smoke_tables_only.do`, `_tier2_tza.do`) plus `0_master.do` all include `0_path_config.do`.

Lesson worth carrying forward: any future project-wide global belongs in `0_path_config.do`, not `0_master.do`.
The latter is a per-user driver with `$dir`/`$overleaf` blocks, and several debug entry points deliberately skip it.

### Tier 3 third launch (in progress as of writing)

Background task `box05upsf`; skip-if-exists=1 preserves the 60 sters from yesterday.
Resumes at IDN cnu_c2 in `6_GrRC_NonAg.do`.
Monitor armed for `r(...);`, `invalid name`, `matrix not positive`, `conformability error`, and the `overnight smoke complete` end marker.

### Commits this continuation

| Hash | Description |
|------|-------------|
| `ac8f3f6` | Audit batch 4: m2 cap to capture + m6 assert_merge_clean retrofit + M4 verdict |
| `3959874` | Fix `\"<path>\"` escape in 0_path_config.do overleaf hint message |
| `cc94d3e` | Move project globals to 0_path_config.do (fixes Tier 3 smoke crash) |

### How to pick this up next session if Tier 3 finishes overnight

```bash
cd C:/git/ckt/.claude/worktrees/grc-pipeline-refactor
git log --oneline -10
ls RP7/output/grc_*_*_g.ster | wc -l
python tests/compare_tabular_bodies.py
```

Expect the ster count to grow well past 60 if Tier 3 cleared `6_GrRC_NonAg.do` and entered `8_GrRC_hukou.do` and `GRC_extras.do`.
After Tier 3 completes, run `make_tables.do` and `make_figures.do` for the final tables + figures.
Then re-run `tests/compare_tabular_bodies.py` and expect 53 matched / 0 differed.

## Continuation: M4 cleanup decision and commit

While Tier 3 ran in the background, the user pushed back on the M4 framing.
Three issues clarified.

### Untangling "duplicate" claims

The user thought the duplication was BETWEEN `initial_values` and `initial_values_robust`; I had been describing duplication WITHIN each program.
Both are real but distinct.

`initial_values_robust` is a separate program that extends `initial_values` for the Verdier (2020) Section F robust spec; it also has its own internal doubled mu-loop.
The audit doc had conflated these.

### Where each program is actually used

`initial_values` is the workhorse: ~30 call sites across `5_GrRC.do` (9), `6_GrRC_NonAg.do` (1), `8_GrRC_hukou.do` (12), `make_tables.do` (3+), smoke and tier drivers, plus indirect calls through `run_grc_with_extra_regressor` (which serves `GRC_extras.do`).

`initial_values_robust` is dormant: defined in `0_programs.do` but never called from any production .do file.
Verbatim grep confirms zero non-comment, non-self-references outside `0_programs.do`.
It is only referenced by `run_grc_robust` and `run_grc_robust_vv`, which are also defined but unwired.
The robust suite is for the Verdier exploration on the `lca-inversion` and `verdier-p1` branches, not Tier 3.

### Hypotheses considered for the doubled mu-loop

I worked through six hypotheses for why the duplication might be intentional rather than a bug.
Hypothesis 4 (placeholder for an unfinished Delta refactor) is the most plausible because:
- The pre-existing structure between the two mu-loops is `mu-loop, [commented-out Delta loop with note "Tricky to do with the potentially-changing Delta_base"], kappa append, mu-loop again`.
- Both mu-loops carry the IDENTICAL leading comment `* Accumulate mu-coeffs for initial values`.
- The "Tricky to do" comment reads as the author wrestling with the Delta block, giving up, and leaving copy-paste debris.

What M4 does NOT settle:
- First-wins vs last-wins gmm `from()` semantics under truly different starting values.
The exactly-identified test model (Test 4) converges to OLS regardless, so cannot discriminate.
- Whether the optimizer for the real overidentified pipeline GMM (~30 switchers + kappa, igmm two-step) makes any subtle numerical difference under the doubled `from()` string.
No specific reason to believe it does, but the M4 test is too small to rule it out empirically.

### Decision: delete the second mu-loop in both programs

Decision: delete the second `foreach s of numlist $switchers { local initial ... mu_<s> }` block in both `initial_values` (lines 1633-1636) and `initial_values_robust` (lines 1759-1761).
Why: user authorized the cleanup after agreeing hypothesis 4 is most likely; M4 test confirmed gmm produces identical fits with the duplicate; removing dead code is cheap, easily revertable, and improves readability.

Decision: leave the commented-out Delta loop and the "Tricky to do with the potentially-changing Delta_base" note in place.
Why: those comments are useful historical context that explains the intended design and where the doubled mu-loop came from; deleting them would erase the only on-file evidence of the unfinished refactor.

Decision: do NOT update the audit doc to mark M4 fully closed yet.
Why: the user pointed out (correctly) that "RESOLVED with verdict + cleanup committed" is not the same as "verified bit-identical."
Until a real pipeline cell is re-run on the cleaned code and its ster compared against a current ster from the doubled-loop code, we cannot promise zero numerical change.
Audit doc stays at "RESOLVED" with the M4 verdict; promotion to "CLOSED" waits on the post-Tier-3 verification.

### Tier 3 in flight is unaffected by the cleanup

`_smoke_full.do` includes `0_programs.do` once at startup; Stata caches program definitions in memory after that.
On-disk edits to `0_programs.do` do not propagate to the running batch process.
The cleanup commit takes effect on the next launch only.
Confirmed by checking the `_smoke_full.do` structure.

### Commits in this continuation

| Hash | Description |
|------|-------------|
| `d2b0c73` | Delete duplicate mu-loop in initial_values + initial_values_robust (M4) |

### Tier 3 status as of wrap-up (2026-04-29 14:55)

Background task `box05upsf` still running.
Ster count: 66 (was 60 at the third launch start at 12:50).
Log size 321+ KB, currently mid-GMM iteration on some cell in `6_GrRC_NonAg.do`.
No errors since the third launch.
Stata process responding (CPU ~84 minutes over 2 hours wall, multi-threaded).

A second StataMP-64 process (PID 42164) appeared at 13:35 with no clear origin (not from any background task I started).
Could be a stray from one of the failed earlier launches that did not fully clean up, or a manually-opened interactive session.
Not interfering with the smoke driver as far as I can tell from the log; flagging here in case it matters next session.

Three monitor instances on the smoke log timed out over the morning and afternoon (1-hour limits each).
Re-arming on each timeout caught no errors.
Tier 3 is grinding through the post-resume cells slowly; some are taking 60+ minutes per fit, consistent with yesterday's IDN cnu_c1 timing of 43 minutes.

### How to pick up next session

If Tier 3 has finished by the next session:
1. `git log --oneline -15`---expect 4 new commits since `974ec5d` (audit batch 4, escape fix, globals relocation, doc updates, mu-loop cleanup).
2. `ls RP7/output/grc_*_*_g.ster | wc -l`---expect a substantial increase from 60 (full GRC_extras + 8_GrRC_hukou would push past 200; just 6_GrRC_NonAg completion would be in the 80--90 range).
3. Run the final tables+figures: `cd RP7/scripts && stata-mp -b do _smoke_tables_only.do` (or run `make_tables.do` directly through 0_master.do).
4. Re-run `python tests/compare_tabular_bodies.py`---expect 53 matched / 0 differed if everything cleared.

If Tier 3 is still running, leave it alone, re-arm a monitor, and work on something else.

If Tier 3 crashed, the smoke log tail will show the error.
Common likely causes given history: another `\"` escape somewhere I missed, another global expected from `0_master.do` that the smoke driver does not load, or a genuine numerical issue in 8_GrRC_hukou (the first time the new C1 timer fix gets exercised end-to-end).

The M4 verification step (post-Tier 3): pick one cell from `5_GrRC.do`---e.g., the IDN cuu_c2 cell---and re-run with `skip_if_exists 0` against the cleaned `0_programs.do`.
Compare the new ster bit-for-bit against the existing ster (which was created with the duplicate mu-loop in place).
If they match, mark M4 fully CLOSED in `docs/plans/2026-04-29-audit-action-plan.md` and `docs/reviews/2026-04-28_pipeline-best-practices.md`.
If they diverge, the doubled `from()` string was numerically meaningful after all and we revert `d2b0c73` and reopen the audit finding.

### Lessons worth carrying forward

Two crash bugs today both came from `_smoke_full.do` bypassing `0_master.do`:
- The `\"` escape sequence does not work in plain Stata double-quoted strings.
- Project globals set in `0_master.do` are invisible to alternate entry points.

Lesson: any future project-wide global or always-needed setup belongs in `0_path_config.do`, which all entry points include.
`0_master.do` is per-user (sets `$dir`, `$overleaf` per `c(username)`); several debug drivers deliberately skip it.

When introducing a `display` statement that quotes user-facing syntax, prefer SMCL markup (`{it:...}`) over backslash escapes, since plain `"..."` strings in Stata do not honor `\"` and the failure mode is `r(198) "invalid name"` at runtime.

### Why does make_tables.do call initial_values? (resolved, no follow-up needed)

User flagged this question while reviewing the M4 cleanup risk surface.
Inspected all three `initial_values` call sites in `make_tables.do` (lines 607, 683, 759, one per country block).
Same pattern at each: call `initial_values`, capture `r(base)` into `local base` and `scalar base_<country>`, capture `r(initial)` into `local initial`.

The `local initial` capture is dead code: assigned but never referenced downstream within `make_tables.do` (verified by grep over the post-assignment lines).
Pure copy-paste leftover from when these blocks were lifted from `5_GrRC.do`, where `initial` is the `from()` argument fed to `gmm`.
The comment block at lines 621-624 of `make_tables.do` explicitly states: "GMM estimate is read from 5_GrRC.do's output rather than re-run here ... The estimates are loaded below via `estimates use`."
So no re-fitting; no use of `from()`; nothing in the table machinery depends on the structure of `r(initial)`.

What `make_tables.do` actually needs from `initial_values`:
- `r(base)` for the data-driven base-trajectory selection (highest-t-stat switcher with N/T > 5), used to label the baseline trajectory in the Delta tables.
- The `mu_<s>` and `Delta_<s>` scalars set in loop A of `initial_values` (the OLS coefficient extraction at L1606-1610), used in `scalar()` references during table assembly.
- Side effect: `eststo initial_<country>` saves the OLS regression set in case downstream `esttab` calls reference it.

Net implication for the M4 cleanup (commit `d2b0c73`):
the doubled mu-loop only affected `r(initial)`, which `make_tables` captures into a dead local.
The base selection and the OLS-derived scalars are identical before and after.
Post-Tier-3 `make_tables` should produce bit-identical `.tex` tables on the cleaned code.
No additional verification needed at table-build time; the M4 verification gate (compare a fresh ster against an existing one) is sufficient.

Future micro-cleanup (not urgent): drop the three dead `local initial "\`r(initial)'"` assignments at L613/689/765 of `make_tables.do`.
Pure m-tier hygiene; no functional change.

### Bigger picture: Workstream A (the original 2026-04-24 refactor spec)

User flagged at the end of the 2026-04-29 session that the audit-driven cleanups (Workstream B) are NOT the same as the original refactor spec, and we need to make sure the refactor work is not forgotten while the audit closes out.
Authoritative source: [quality_reports/specs/2026-04-24_grc-pipeline-refactor.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md), now updated with per-phase status notes (commit `5b2cabe` or whichever commit lands these doc updates).

Current Workstream A status:

| Phase | Items | Status |
|-------|-------|--------|
| Phase 0 | M6, M7, M8, M9, M10---reference build, regression test, smoke, runtime, resume guard | DONE per 2026-04-28 status note |
| Phase 1 | M1, M2, M11---collapse experience family, collapse 14/15, unique ster names | PARTIAL: M11 landed; Phase 1b.6 spec implemented (`run_grc_with_extra_regressor` + `GRC_extras.do`); commit 6e (delete 10/11/12/13/14/15 + collapse master includes) NOT YET LANDED, gated on Tier 3 |
| Phase 2 | M3 (unify `grc_tex_table_trend*`) + S3 step 1 (program-caller map) | NOT STARTED |
| Phase 4 | M4 (`values(nominal\|real)` switch at `0_path_config.do`) | NOT STARTED |
| Phase 5 | S1 (overview scraper) + S1b (coefplot figure) + S2 (file rename) | NOT STARTED |
| Phase 6 | Decisions on remaining deletions | gated on Phase 2 caller map |
| S1c | Add $\Delta_{\text{always}}$ row to main GRC tables | NOT STARTED |

Workstream B (the 2026-04-28 audit + 2026-04-29 action plan) is nearly closed; remaining items are low-priority `m`-tier (`m8`, `m13`, `m14`, `m16`) plus the deferred data-creation findings (`DC-M1` through `DC-m7`).

### Concrete next steps in Workstream A, ordered

1. **Wait for Tier 3 to finish.**
Background task `box05upsf` is running; ster count was 132 at 20:28.
The smoke driver writes `_smoke_full.log`; check with `tail -3 RP7/scripts/_smoke_full.log` and `ls RP7/output/grc_*_*_g.ster | wc -l`.

2. **Run the M4 verification gate** (closes Workstream B's last open MAJOR finding).
Pick one cell, e.g. IDN cuu c2.
Re-run with the cleaned `initial_values` (commit `d2b0c73`) under `skip_if_exists 0` so the fit produces a fresh ster.
Compare bit-for-bit against the existing IDN cuu c2 ster on disk (which was created by the doubled-loop version).
If identical, mark M4 CLOSED in the audit doc and action plan.
If different, revert `d2b0c73` and reopen M4.

3. **Run `make_tables.do` against the full Tier 3 ster set.**
Use `_smoke_tables_only.do` (already wired, sets `$dir` for maand and includes path-config + programs + 0_setup).
Confirm `tests/regression_test.py` (or `tests/compare_tabular_bodies.py`) passes against the frozen reference.
This proves Workstream B's cleanups (m6, m2, the two crash bug fixes, the mu-loop cleanup) did not shift any published numbers.

4. **Phase 1 close-out: commit 6e.**
Delete `10/11/12/13/14/15_*.do` from `RP7/scripts/`.
Update `0_master.do` to drop the six numbered includes and add one `include "$dir/scripts/GRC_extras.do"` line.
Update `_smoke_full.do` similarly if not already done (it currently calls `GRC_extras.do` directly per the inspection, so probably no change needed).
Re-run regression test to confirm bit-identity.
This closes Phase 1.

5. **Phase 2: unify `grc_tex_table_trend*` family.**
Currently four near-identical programs (`grc_tex_table_trend`, `grc_tex_table_trend_exp`, `grc_tex_table_trend_birth`, `grc_tex_table_trend_hukou`).
The ster-rename commit cherry-picked from `lca-inversion` already added a `spec()` option to three of them.
Collapse into one program with options `spec(string)`, `est_schedule(string)`, `est_prefix(string)` plus hukou-specific controls.
`grc_tex_table_trend_birth` is byte-identical to `grc_tex_table_trend_exp` per the programs audit---delete it outright and redirect callers.
Plus S3 step 1: produce a definitive map of which programs in `0_programs.do` are actually called and from where (no deletions yet).

6. **Phase 4: `values(nominal|real)` switch at `0_path_config.do`.**
Implement `global values "nominal"` as default; `global dirdata` resolves to the appropriate folder.
Append `_${values}` to `.ster` prefix, CSV output, and LaTeX table filenames so nominal and real results coexist.
No in-pipeline deflation code added; deflation lives upstream.
Note: `0_path_config.do` is already the canonical home for project-wide globals after the 2026-04-29 fix, so the values switch slots in cleanly there.

7. **Phase 5: overview layer.**
S1 (Python `.ster` scraper writing `RP7/output/overview/grc_runs.csv`), S1b (coefplot/specification-curve figure), S2 (rename numbered files for legibility: target file count 13).

8. **S1c.** Add $\Delta_{\text{always}}$ row to the main GRC LaTeX tables. One-line edit in `grc_tex_table_trend`; gated by regression test.

9. **Phase 6.** Decide on any further deletions in `0_programs.do` informed by Phase 2's caller map.

If you resume: read [quality_reports/session_logs/2026-04-29_audit-and-fixes.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-04-29_audit-and-fixes.md) end-to-end (this file).
Open thread: M4 verification (run one cell on cleaned code, compare ster bit-identically against existing).
Next concrete action: check whether Tier 3 task `box05upsf` has completed; if yes, run `python tests/compare_tabular_bodies.py` and inspect new sters.
State to know: voice.md and manuscript-writing.md were Read this session, so the prose-rules-enforcer flag is set; will reset on next session.
The duplicate-mu-loop cleanup commit (`d2b0c73`) is on disk but its effect is NOT in the running Tier 3.