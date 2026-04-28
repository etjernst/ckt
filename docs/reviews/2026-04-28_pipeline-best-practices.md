# Pipeline best-practice audit (2026-04-28)

## Summary

27 findings: 2 critical / 8 major / 17 minor.
The three things to do first: (1) **fix the `run_grc_hukou` timer crash bug** --- it reads `_tslot` without ever setting it, which will abort the hukou GMM section with a "syntax" error when Tier 3 reaches `8_GrRC_hukou.do`; (2) **fix the doubled `mu` accumulation in `initial_values`** --- the `from()` string has every `mu:switcher_s` entry twice, which wastes GMM time parsing redundant starting values and could interfere with non-default `gmm` parsers; (3) **add `version 17` and `set more off`** at the top of `0_master.do` since every other project-wide convention is set there and these are the only missing ones.

---

## Critical

### C1 --- `run_grc_hukou` uses `_tslot` without initializing it

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 2276--2281

`run_grc_hukou` calls `timer off \`_tslot'`, `timer list \`_tslot'`, and `estadd scalar runtime = r(t\`_tslot')`, but `_tslot` is a local that is **never assigned** inside `run_grc_hukou`.
Compare to `run_grc` lines 1798--1801 which initialize `${grc_timer_slot}` and set `local _tslot`.
When `run_grc_hukou` runs, `\`_tslot'` expands to the empty string, causing Stata to evaluate `timer off ` (syntax error) which will abort `8_GrRC_hukou.do` in batch mode.

**Fix:** add at the start of `run_grc_hukou` (after the `di as text "run_grc: base trajectory..."` line) the same timer-slot block that `run_grc` uses:

```stata
if "${grc_timer_slot}" == "" global grc_timer_slot 0
global grc_timer_slot = ${grc_timer_slot} + 1
local _tslot = ${grc_timer_slot}
timer on `_tslot'
```

Lens: reproducibility / CRITICAL / HIGH

---

### C2 --- `$lnsize` global is used but never defined

[5_GrRC.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/5_GrRC.do) line 545; [8_GrRC_hukou.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/8_GrRC_hukou.do) lines 253, 555, 857, 1159; [0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) line 2030

`global keepvars lndepvar $lnsize trajectory ...` appears in the income section of `5_GrRC.do` and four places in `8_GrRC_hukou.do`.
No `global lnsize` assignment exists anywhere in `RP7/scripts`.
Stata silently expands undefined globals to the empty string, so the income-section `keep` list omits whatever `lnsize` was intended to retain.
The same global is referenced in `run_grc_with_extra_regressor` (line 2030) for `spec3==iuu`.
If `lnsize` is meant to hold `loghhsize` or `hhsize_cube`, the variable is being silently dropped from the working dataset before GMM runs on income specifications, which may or may not matter depending on whether those variables enter the model, but it is an undocumented behavior that creates a silent replication gap.

**Fix:** either define `global lnsize ""` (empty, deliberate) or `global lnsize loghhsize` in `0_master.do` immediately after the path setup, and document the intent.

Lens: reproducibility, data quality / CRITICAL / HIGH

---

## Major

### M1 --- No `version` declaration in any `.do` file

Affects all files in `RP7/scripts`.
No file begins with `version 17` (or any version).
Without a version pin, Stata's behavior for deprecated or changed syntax may differ across co-author installations.

**Fix:** add `version 17` as the first executable line in `0_master.do` (it propagates to `include`-d files).
Optionally add it to the top of each standalone file too for files that may be run independently.

Lens: reproducibility / MAJOR / HIGH

### M2 --- `set more off` missing from `0_master.do` (master log idea retracted)

[0_master.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_master.do) lines 1--97

`set more off` is absent from `0_master.do` (it is set in `0_setup.do` as `set varabbrev off` only, and never reaches the "pager freeze" concern that `more` controls).
Add it to prevent interactive runs from freezing on full screens.

The original audit also recommended a master-level log file.
**Retracted (2026-04-29):** Stata only supports one open log at a time, and sub-scripts (`5_GrRC.do`, `make_tables.do`, etc.) each `log using` their own files.
A master log would have to be closed before each sub-script's `log using`, defeating its purpose.
Skip the master log; rely on sub-script logs and the `_smoke_full.log` master driver log when running via that path.

**Fix:** add `set more off` near the top of `0_master.do`.

Lens: output / MINOR / HIGH

### M3 --- Merge diagnostics suppressed with `nogen` but not verified

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 295, 354, 412

All three trajectory merges inside `handle_trajectory_groups`, `handle_trajectory_groups_2waves`, and `handle_trajectory_groups_3waves` use `merge m:1 pid using \`traj', nogen`.
The `nogen` suppresses `_merge` creation, which makes it impossible to detect unmatched observations programmatically.
The merge is between the full panel and a tempfile of pids who survived the `keep if pid_obs >= N` filter, so unmatched observations (master-only) are expected and represent unbalanced individuals --- but this is not asserted.
If the tempfile build has a bug, the merge would silently produce master-unmatched rows with missing trajectory values.

**Fix:** drop `nogen`, then immediately `assert _merge != 2` (no using-only rows expected) and `drop _merge`.
Or at minimum keep `nogen` but add a `count if mi(trajectory)` diagnostic to document the expected unmatched count.

Lens: data quality / MAJOR / HIGH

### M4 --- Doubled `mu` accumulation in `initial_values` (and `initial_values_robust`)

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 1530--1547, parallel block in `initial_values_robust` lines 1666--1671

`initial_values` runs two separate `foreach s of numlist $switchers` loops that both append `mu:switcher_\`s' mu_\`s'` to `local initial`.
The intent (from the comment at line 1544) appears to be a copy-paste error --- the first loop accumulates mu starting values, then later a second identical loop re-appends them all again.
The `from()` string Stata's `gmm` sees therefore contains every `mu:switcher_s` entry twice.
While Stata processes `from()` by last-wins, this doubles the string length (which matters for Stata's 65,536-char macro limit with many switchers) and is confusing to read.

The same doubled-loop pattern appears verbatim in `initial_values_robust` lines 1666--1671.

**Fix:** delete the second mu-loop (lines 1544--1547 in `initial_values`, lines 1668--1671 in `initial_values_robust`).

Lens: reproducibility / MAJOR / MEDIUM (Confidence MEDIUM because `gmm from()` last-wins semantics means results are numerically identical; it's waste, not wrong inference.)

### M5 --- `run_grc_hukou` does not expose `phistart` option

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 2227, 2255

`run_grc_hukou`'s syntax does not include a `phistart(real -0.1)` option, so the phi initial value is hardcoded to `{phi=-0.1}` in the GMM equation (line 2255).
`run_grc` and `run_grc_onestep` both expose `phistart` so callers can override it.
If the hukou specs ever need a different starting value (e.g., for a country where the sign is ambiguous), the caller has no way to pass it without editing `0_programs.do`.

**Fix:** add `[phistart(real -0.1)]` to `run_grc_hukou`'s syntax line and replace `{phi=-0.1}` with `{phi=\`phistart'}` in the GMM equation.
One-line change, exactly mirrors `run_grc`.

Lens: inference / MAJOR / HIGH

### M6 --- `summary_stats_*.csv` written to Stata's working directory (not to a known path)

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 651, 657, 720, 726, 789, 795, 858, 864

`iebaltab ... savecsv("summary_stats_\`country'_\`balance'.csv")` writes to the current working directory (wherever `cd "$logs"` left it), and the subsequent `import delimited using summary_stats_...csv` reads from the same implicit cwd.
If a sub-script runs `cd` for a different purpose between the `savecsv` and `import delimited`, the CSV will not be found.
More importantly, the CSV files are left behind in `$logs` (a tracked output directory) as a side-effect.

**Fix:** use `"$logs/summary_stats_\`country'_\`balance'.csv"` as a full path in both the `savecsv()` call and the `import delimited` call, then `erase "$logs/..."` after import.
Or write to a `tempfile`.

Lens: reproducibility / MAJOR / MEDIUM

### M7 --- `ugrc_regressions` contains a shadow `eststo reg7_<country>`

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 1469--1478

`ugrc_regressions` runs `eststo reg7_\`country': reghdfe lndepvar choice ... absorb(pid)` and captures `e(sample)` as `regression_sample`.
Then on lines 1474--1477 it immediately overwrites `reg7_\`country'` with a completely different regression (uGRC trajectory version) that does not use `if regression_sample`.
The first `reg7` estimate is silently discarded.
The second `reg7` therefore runs on the full sample, not the common sample established by the first run.
This is inconsistent with how `reghdfe_regressions` handles the same problem (col 7 sets the sample, then col 1--6 use `if regression_sample`).

Lens: inference / MAJOR / MEDIUM (Confidence MEDIUM: the uGRC regression may be intentionally running on a different sample, but this is not documented and the duplicate `eststo` name is almost certainly unintended.)

### M8 --- `make_tables.do` runs `initial_values` (a non-trivial OLS) just to discover `$switchers`

[make_tables.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/make_tables.do) lines 601--630, 680--707, 755--783

The heterogeneity-table section of `make_tables.do` opens each country's dataset, calls `setup_grc_estimation` (which creates switcher dummies), then calls `initial_values` (which runs an OLS regression) just to populate `$switchers` so the keep-list and coeflabel-list can be built.
This OLS is discarded immediately.
The OLS runs on all three countries and takes measurable time in a tables-only pass, defeating the purpose of `make_tables.do` as a fast table-only runner.

**Fix:** the `$switchers` global is set by `setup_grc_estimation` alone (via `numlist "2(1)\`lastswitcher'"`).
The subsequent `initial_values` call is unnecessary.
Replace the three `initial_values` calls with a comment explaining that `$switchers` is available immediately after `setup_grc_estimation`.

Lens: code quality / MAJOR / HIGH

---

## Minor

### m1 --- `cd "$logs"` used pervasively where `log using` with full path would suffice

All sub-scripts (`5_GrRC.do`, `GRC_extras.do`, `make_tables.do`, etc.) open with `cd "$logs"` then `log using MyScript.log, replace`.
The `cd` pattern is explicitly discouraged by the stata-conventions rule (use globals, not `cd`).
The pattern works only because the log filename is short and no subsequent code relies on the cwd being `$logs`.
Full-path form:

```stata
capture log close
log using "$logs/5_GrRC.log", replace
```

Lens: reproducibility / MINOR / HIGH

### m2 --- `cap program drop` vs `capture program drop`: inconsistent abbreviation

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) throughout

Most programs use `cap program drop` (abbreviated); a handful (`initial_values`, `define_switcherpars`, `run_grc`, `run_grc_onestep`, `run_grc_hukou`, `run_grc_robust`, `run_grc_robust_vv`, `extras_tex_table`) use `capture program drop` (full form).
Both work identically.
Pick one and apply consistently --- the full form is recommended in `stata-conventions.md` for clarity.

Lens: code quality / MINOR / LOW

### m3 --- Magic number `5` in base-trajectory selection threshold

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 1583, 1713

`if N_\`s' / T > 5 {` hard-codes the minimum-individuals-per-wave threshold for base-trajectory eligibility.
Same literal `5` appears in both `initial_values` and `initial_values_robust`.
Promote to a local:

```stata
local min_switchers_per_wave 5
...
if N_`s' / T > `min_switchers_per_wave' {
```

Lens: code quality / MINOR / HIGH

### m4 --- Magic number `100` for GMM iterations

[5_GrRC.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/5_GrRC.do) line 88; similarly in `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `make_tables.do`

`local iterations 100` is set locally in each driver file.
It is already a local (good), but the value `100` appears many times with no `run_grc` default documented in `0_programs.do`'s `syntax` line.
The `run_grc` syntax already defaults `iterate` to integer but does not enforce a convention; the value `100` is load-bearing (GMM may not converge in fewer iterations).
One approach: set `global grc_max_iter 100` in `0_master.do` and reference it in each driver.
Low priority but useful for a run that needs to increase iterations globally.

Lens: code quality / MINOR / LOW

### m5 --- `grc_tex_table` (deprecated) still defined and occupies ~80 lines

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 2859--2938

The header comment at line 2854 marks `grc_tex_table` as "DEPRECATED: pre-trend variant ... Not called by any numbered .do file."
It is still defined, adding 80 lines of live Stata code that will be parsed and compiled at every pipeline run.
No caller references it.
Remove the program definition (or comment out the entire block) and note in the header that it is archived.

Lens: code quality / MINOR / HIGH

### m6 --- `non_switcher_2waves` / `non_switcher_3waves` classification uses hardcoded string enumeration

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 362--363, 419--420

`replace non_switcher_2waves = 0 if trajectory_2waves == "00001" | ...` lists dozens of specific binary strings.
This is brittle: if a new country is added with a different number of waves, or if the string encoding changes, these lists silently produce missing values for the new trajectories.
The main `handle_trajectory_groups` uses the elegant max-trajectory numeric encoding instead.
The `_2waves` and `_3waves` variants should use the same approach: `encode` the string trajectory to a numeric, then classify `non_switcher` as those whose encoded trajectory is the all-zeros or all-ones value.

Lens: data quality / MINOR / MEDIUM

### m7 --- `set obs 19` hard-coded in four summary-stats helpers

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 663, 733, 800, 872

All four `country_summary_stats*` programs assume the `iebaltab` CSV produces exactly 15 data rows plus a 4-row header (which gets dropped), leaving 11 rows, then `set obs 19` adds 8 to allow 4 footer rows.
If `iebaltab`'s output format changes, `set obs 19` and the subsequent `replace ... in 17/19` will silently misplace the footer rows.
Use `local nrows = _N` after dropping the header, then `set obs \`=\`nrows'+4'`.

Lens: data quality / MINOR / LOW

### m8 --- `handle_depvar` unconditionally generates `ln_income` and `ln_consumption`

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 230--233

Every call to `handle_depvar` generates both `ln_income` and `ln_consumption`, even for datasets where only one outcome is present.
For the income dataset, `ln_consumption` will be generated and then contain missing values (since `consumption` may be missing), introducing unnecessary columns and potential confusion if a downstream `keep` list accidentally retains them.

Lens: data quality / MINOR / LOW

### m9 --- `graph save` uses temporary names that land in Stata's cwd, not `$output/figures`

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 1415--1430; [make_figures.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/make_figures.do) lines 82--128, 191, 232, 273, etc.

`graph save hetplotDelta_..._Fcovars, replace` saves `.gph` files to the cwd (`$logs` because of the leading `cd "$logs"`).
These files persist after `graph combine` and accumulate over runs.
The combined figure is correctly saved to `$output/figures`, but the component `.gph` files are not cleaned up.
Use `tempfile` for intermediate graphs:

```stata
tempfile g1
graph save `g1', replace
```

Or save to `$output/figures` with a `.gph` suffix and clean up after combine.

Lens: output / MINOR / MEDIUM

### m10 --- `make_figures.do`: `label define mega_trajectories` called 9 times without `replace`

[make_figures.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/make_figures.do) lines 169, 208, 248, 304, 343, 385, 439, 478, 518

Each country block calls `label define mega_trajectories ...` (without `replace` or `add`).
The second call for CHN will fail with "label already defined" unless the previous dataset's labels are cleared when `use ... , clear` clears the data in memory.
In practice, `use ..., clear` does NOT clear value labels from memory --- they persist.
This means the CHN and TZA calls will silently fail (Stata returns an error but execution continues because there is no `assert` or `cap`), using the IDN label for all three countries.
Use `label define mega_trajectories ... , replace` on every call, or define the label once at the top of `make_figures.do`.

Lens: output / MINOR / HIGH (Confidence HIGH --- this is a real Stata behavior.)

### m11 --- `make_tables.do` section headers use stale copy-paste boilerplate

[make_tables.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/make_tables.do) lines 557--568

The heterogeneity-table section still contains a multi-line `/**** Project: Returns to Migration ... This code: Creates table of rGRC estimates ****/` comment block that is copy-pasted from a deleted sub-file and references `8_GrRC_hukou.do` in the context block above it.
The block is misleading because this section actually builds heterogeneity Delta/mu tables.
Replace with a concise header matching the other section headers.

Lens: code quality / MINOR / LOW

### m12 --- `0_path_config.do` contains a hardcoded absolute fallback path for `$overleaf`

[0_path_config.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_path_config.do) lines 23--24

```stata
global overleaf "C:/Users/maand/Dropbox (Personal)/Apps/Overleaf/..."
```

This path will silently be set (and `copyOverleaf` will attempt to copy to it) on any machine where the user has not set `$overleaf` before `include 0_path_config.do`.
On co-author machines this path does not exist, so every `copyOverleaf` call will fail silently (it uses `copy` without error trapping).
The `di as text "Output will be copied..."` display is misleading in that case.

**Fix:** change the fallback to `global overleaf ""` and add a check: if `$overleaf == ""` and `$copyOverleaf == 1`, display a warning rather than silently attempting the copy.

Lens: reproducibility / MINOR / HIGH

### m13 --- `data_path_override` in `GRC_extras.do` expands `$dirdata` at call time

[GRC_extras.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/GRC_extras.do) line 122; [0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 2002--2003

```stata
run_grc_with_extra_regressor, ... data_path_override("$dirdata/processed/IDN_unb.dta")
```

The global `$dirdata` is expanded by Stata before the argument is passed to the program (because it's inside double quotes at the call site, not inside a local).
This is correct behavior on any machine where `$dirdata` is set.
However, the comment in `run_grc_with_extra_regressor` says "data_path_override is a leak of the file-15-sec-4 historical bug."
Leaving it as a special-case string argument is fragile: if `$dirdata` ever contains spaces (unlikely on this project but possible), the quoted path would need adjustment.
Low risk as-is, worth documenting the expansion assumption explicitly.

Lens: code quality / MINOR / LOW

### m14 --- `0_setup.do` has a bug in the `schemepack` installation check

[0_setup.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_setup.do) lines 43--63

The `findfile` call checks for `\`styles'.sthlp` (the name of the local, which equals "schemepack"), but inside the `if _rc == 0` block it displays "found helpfile" --- that branch fires when `_rc == 0`, which `findfile` sets when it *succeeds*.
The logic is inverted relative to the SSC loop above (which uses `if (_rc)` to check for missing).
So the `else` branch (install the package) fires when the file IS found.
Additionally, the install command uses `\`package'` (which is empty since `package` was a loop variable in the previous loop) instead of `\`style'`.

Lens: reproducibility / MINOR / HIGH (Confidence HIGH --- the logic inversion and wrong variable name are real bugs, though the impact is limited to re-installing schemepack on machines that already have it.)

### m15 --- Figure export does not produce a PNG for all figures

[make_figures.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/make_figures.do) lines 279--283, 414--418, 549--553

The trajectory bar-graph combines (`trajectories.pdf`, `trajectories_2waves.pdf`, `trajectories_3waves.pdf`) export only `.pdf`, not `.png`.
The heterogeneity coefplots export both.
Convention in `stata-conventions.md` requires both formats.
Add a matching `graph export ... .png, replace` line after each PDF export for the trajectory graphs.

Lens: output / MINOR / HIGH

### m16 --- `create_panel_tex_table` and `create_panel_tex_table_learn_IDN/CHN` hardcode "Panel A: Indonesia", "Panel B: China", "Panel C: Tanzania"

[0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) lines 935, 942, 952

The panel headers are hardcoded strings rather than being derived from the `countries()` argument.
If the `countries()` order ever changes (e.g., CHN IDN TZA), the panel labels will be wrong.
The `countries()` list is already parsed with `local country : word \`i' of \`countries'` (line 961) for the estimate names but not for the panel headers.

Lens: code quality / MINOR / LOW

### m17 --- `0_master.do`: two Kleemans `global dir` assignments overwrite each other silently

[0_master.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_master.do) lines 31--32

```stata
global dir = "C:\Users\kleemans\Dropbox\..."
global dir = "D:\Dropbox\..."
```

Both lines are inside the same `if "\`c(username)'"=="kleemans"` block with no surrounding `if` or conditional.
The second line always overwrites the first.
This was presumably intended as a machine-specific toggle (office vs. laptop D:\ drive) but both are unconditional.
If Kleemans' machine ever changes back to C:\, this fails silently.

Lens: reproducibility / MINOR / LOW

---

## Out of scope (deliberately not flagged)

- Per-cell explicit `run_grc` calls in `5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`. The `feedback_no_loops_for_regressions.md` rule explicitly prohibits suggesting loops here.
- The `data_setup` / `data_setup_2waves` / `data_setup_3waves` near-duplication. Refactoring into a single parametric program would require a substantive spec/plan; out of scope for a best-practices audit.
- The `non_switcher_2waves`/`non_switcher_3waves` string enumeration correctness for existing countries (they appear correct for CHN/IDN/TZA as currently structured; only flagged as a future-extension risk in m6).
- The `skip_if_exists` resume logic in `run_grc`. This is correct and intentional.

---

## Aggregate score

| Lens | Weight | Raw Score | Weighted |
|------|--------|-----------|---------|
| Reproducibility | 25% | 62 | 15.5 |
| Inference | 30% | 82 | 24.6 |
| Data Quality | 20% | 74 | 14.8 |
| Output | 10% | 70 | 7.0 |
| Code Quality | 15% | 72 | 10.8 |
| **Total** | | | **73** |

Two CRITICAL issues block readiness regardless of this score.
The score is a rough ordinal indicator only.

---

## Small wins (under 30 minutes, low risk)

**SW1 --- Fix `run_grc_hukou` timer crash (C1).**
Copy the four-line timer-slot block from `run_grc` lines 1798--1801 into `run_grc_hukou` right before the `gmm` call.
This is a four-line edit with zero risk of changing any results.
Without it, `8_GrRC_hukou.do` will abort in the current Tier 3 run if it reaches `run_grc_hukou`.

**SW2 --- Delete the duplicate mu-loop in `initial_values` and `initial_values_robust` (M4).**
Remove lines 1544--1547 in `initial_values` and the parallel lines 1668--1671 in `initial_values_robust`.
No change to any result (last-wins semantics), but the `from()` string will be half as long, slightly faster to parse, and unambiguous.

**SW3 --- Remove deprecated `grc_tex_table` definition (m5).**
Delete lines 2859--2938 from `0_programs.do`.
This is dead code confirmed by grep.
Removes 80 lines, makes the file easier to navigate.
Zero risk.

**SW4 --- Fix `label define mega_trajectories` in `make_figures.do` (m10).**
Add `, replace` to every `label define mega_trajectories` call (9 occurrences).
Without this, the CHN and TZA trajectory bar graphs may display the IDN labels.
This is a one-word addition per call, testable immediately by running `make_figures.do`.

**SW5 --- Add `version 17` and `set more off` to `0_master.do` (M1, M2).**
Two lines at the top of `0_master.do`.
Zero risk; adds version pinning for reproducibility and prevents pager-freeze in interactive mode.
(Master log idea retracted --- Stata supports only one open log at a time and sub-scripts each `log using` their own files.)

---

# Data-creation scripts (Dropbox) audit (2026-04-28)

## Scope

Files audited:

- [200829 IFLS prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/200829%20A%20Preparation%20of%20IFLS%20dataset%20(internal%20use%20only)_MK_CV.do) (160 lines, IDN internal IFLS prep)
- [250314 data prep (nominal)](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) (693 lines)
- [260302 data prep (real)](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) (726 lines)
- [230328 variable selection (nominal)](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/230328%20Variable%20selection_DB_MK.do) (720 lines, CHN/IDN/TZA panel construction)
- [260424 TZA real variable selection](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/260424%20Variable%20selection%20TZA%20real%20values_DB.do) (169 lines)
- [RP7/scripts/1_processData.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/1_processData.do) (517 lines)

**Status of the 200829 IFLS script.** This script saves `IFLS.dta` to the KLPS panel directory (`$dpa/IFLS.dta`). Files 250314 and 260302 both open `Intergen_Analysis_IFLS.dta` directly from the HKLM replication package (line 58 of each) --- they do not use the 200829 output. The 200829 script is upstream of a separate KLPS study pipeline and is not in the CKT data-creation chain. Findings from it are noted below only for completeness; they do not block the CKT pipeline.

---

## Critical (data-creation)

No CRITICAL issues found. No result-changing bug on the critical path was identified with HIGH confidence.

---

## Major (data-creation)

### DC-M1 --- TZA education merge uses `keep if _merge==3`, silently dropping unmatched individuals

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) line 589; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) line 637

The TZA education merge uses an inner join (`keep if _merge == 3`), silently dropping any individual in `Panel_LMMVW_TZA(.dta` or `_real.dta)` who has no match in the education tempfile, and vice versa.
No count of dropped observations is printed before or after.
The merge key is `pid_str` (a string created by `decode pid, gen(pid_str)` --- line 587/635); if label encoding differs between the two TZA source files, observations can disappear silently.
Both the nominal and real-values prep scripts have identical behavior here.

**Fix:** add `count` immediately before `keep if _merge == 3` and print the implied drop count after, so each run documents sample attrition.
Also `assert _merge != 2` before the inner join to confirm no education-file orphans.

Lens: data quality / MAJOR / MEDIUM

### DC-M2 --- IDN `hhsize` unconditional replace may silently set it to missing for unmatched rows

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) lines 164--166; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) lines 164--166

```stata
merge 1:1 pidlink year using Total_panel_HKLM_hhsize
drop if _merge == 2
replace hhsize = hhsize_hklm          // unconditional
```

After `drop if _merge==2`, master-only rows (`_merge==1`) are retained but have `hhsize_hklm == .`.
The unconditional `replace hhsize = hhsize_hklm` overwrites any valid original `hhsize` value with missing for those rows.
No count is printed to document how many rows were unmatched.
The same pattern appears in both the nominal and real-values prep scripts.

**Fix:**
```stata
count if _merge == 1
di as text "Note: `r(N)' pidlink-year obs unmatched in hhsize merge; hhsize unchanged for these."
replace hhsize = hhsize_hklm if _merge == 3
drop _merge hhsize_hklm
```

Lens: data quality / MAJOR / HIGH

### DC-M3 --- Deflation base year is undocumented in code for IDN and CHN

[260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) lines 247--265 (IDN), lines 577--595 (CHN)

The scripts import `Processed Indonesia CPI data.xlsx` and `Processed China CPI data.xls` and divide `consumption` and `income` by a `deflator` variable.
No comment in the script states the base year or what the deflator represents.
The TZA real-values script is explicit: line 139 (`sum CPI_tanzania if year == 2013`) makes 2013 the base year via code that readers can verify.
For IDN and CHN the base year lives in the Excel files and is invisible to code reviewers.

**Fix:** add a one-line comment before each deflation block, e.g.:
```stata
* IDN spatial deflator: base year [YYYY]. Source: Processed Indonesia CPI data.xlsx, sheet "Final deflators".
replace consumption = consumption / deflator
```

Lens: data quality / MAJOR / MEDIUM (Confidence MEDIUM: the base year may be readable from column headers in the Excel file; this is a documentation gap, not necessarily a computation error.)

### DC-M4 --- No `version` declaration or log file in any Dropbox data-prep script

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) line 1; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) line 1; [230328 variable selection](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/230328%20Variable%20selection_DB_MK.do) line 1; [260424 TZA real values](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/260424%20Variable%20selection%20TZA%20real%20values_DB.do) line 1

None of the four Dropbox data-prep scripts declares a `version` or opens a log file.
Any behavior change across Stata versions (e.g., `rowtotal` missing-value handling, `decode` label encoding) will go undetected.
A failed run leaves no trace of where it stopped.

**Fix:** add `version 17` and `log using "[path]/data_prep_[date].smcl", replace` at the top of each script.

Lens: reproducibility / MAJOR / HIGH

### DC-M5 --- `1_processData.do` has no `version`, no log, no `clear all`, and no post-save sanity check

[1_processData.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/1_processData.do) lines 1--18

The bridge script that produces all GMM-ready `.dta` files is missing `version 17`, `clear all`, and `log using`.
It also has no `count` or `assert _N > 0` after any of its 26 `save` calls.
A silent failure in `data_setup` (e.g., a missing raw file causing `use` to fail with `r(601)`) would produce a zero-observation file that downstream GMM scripts would load without complaint, producing nonsensical estimates with no diagnostic output.

**Fix:** add `clear all`, `version 17`, and a log open/close.
Optionally add `count` after each `save` and `assert _N > 0`.

Lens: reproducibility / MAJOR / HIGH

---

## Minor (data-creation)

### DC-m1 --- `cd` used pervasively in place of full-path globals

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) lines 57, 208, 245, 441, 551, 560, 582, 672; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) same pattern

Every `use`, `save`, and `merge ... using` that operates on a short filename relies on `cd` having set the cwd to the correct directory.
This is the pattern explicitly discouraged by `stata-conventions.md`.
If `cd` is invoked for a different purpose between two file operations, subsequent saves land in the wrong directory silently.

**Fix:** replace `cd "..."` + bare filename with `use "$global/filename"` and `save "$global/filename"` throughout.

Lens: reproducibility / MINOR / HIGH

### DC-m2 --- CHN experience merges have no diagnostic for master-unmatched rows

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) lines 458--468; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) lines 482--492

Four sequential merges bring wave-specific experience variables from raw CFPS data.
Each uses `drop if _merge==2; drop _merge` with no count of `_merge==1` (master-unmatched) rows.
Individuals in `Panel_LMMVW_CHN` absent from a wave's raw file will silently have missing experience for that wave; the `rowmax` accumulation still runs.
This is probably the intended behavior, but the silent nature makes it unverifiable.

**Fix:** after each merge, add `count if _merge == 1` with a comment documenting the expected behavior.

Lens: data quality / MINOR / MEDIUM

### DC-m3 --- `set mem 250m` is obsolete and silently ignored

[230328 variable selection](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/230328%20Variable%20selection_DB_MK.do) line 14; [260424 TZA real values](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/260424%20Variable%20selection%20TZA%20real%20values_DB.do) line 14

`set mem 250m` has had no effect since Stata 12 (memory is allocated dynamically).
Stata 18 silently ignores it.
Remove to avoid confusion.

Lens: code quality / MINOR / HIGH

### DC-m4 --- Variable label typos propagate into all output datasets

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) lines 481, 604; [260302 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/260302%20Data%20preparation%20real%20values_DB.do) lines 505, 652

`lab var empl "empoyment indicator for year of observation"` (missing "l" in "employment") appears four times across the two scripts and propagates into IDN, CHN, and TZA output datasets.
This label appears in summary-statistics output.

**Fix:** `lab var empl "employment indicator for year of observation"` in each occurrence.

Lens: output / MINOR / HIGH

### DC-m5 --- IDN `lncons_tot` is real in the nominal output file; level `consumption` is nominal

[250314 data prep](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/250314%20Data%20preparation_DB.do) lines 141--144, 234

The nominal IDN.dta has an unusual mix: `lncons_tot` is real log consumption (the HKLM `lncons_tot_real` renamed), but `consumption` (the level variable, renamed from `cons_tot`) is nominal.
The downstream GMM uses `ln(consumption)` computed by `handle_depvar` --- which produces nominal log for the nominal pipeline.
The pre-computed `lncons_tot` appears to be used only for summary statistics and is not what the GMM consumes as its dependent variable.
This is probably intentional but is undocumented and could mislead a reviewer examining `IDN.dta` metadata.

**Fix:** add a comment at line 141: `* Note: lncons_tot is renamed from lncons_tot_real (real values from HKLM). The level variable "consumption" remains nominal; the GMM uses ln(consumption) computed by handle_depvar, not lncons_tot.`

Lens: data quality / MINOR / LOW

### DC-m6 --- `consfood` label says "nominal" in the TZA real-values output

[260424 TZA real variable selection](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/260424%20Variable%20selection%20TZA%20real%20values_DB.do) line 152

`lab var consfood "nominal annual consumption of food items"` --- the food sub-component is intentionally not deflated in this script (only total consumption and income are converted to real).
The label is technically accurate but confusing in a file named "real values".
Clarify: `"Annual food consumption (nominal; deflated total = consumption)"`.

Lens: output / MINOR / LOW

### DC-m7 --- TZA `nonag` is derived from a household-level agriculture indicator, not individual employment

[230328 variable selection](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/230328%20Variable%20selection_DB_MK.do) lines 335--338; [260424 TZA real values](file:///C:/Users/maand/Dropbox%20(Personal)/Returns%20to%20migration/Data/Replication%20LMMVW/260424%20Variable%20selection%20TZA%20real%20values_DB.do) lines 80--83

`nonag = 1 if any_ag == 0` where `any_ag` is flagged in an RA comment (line 346 of 230328) as "Does anyone in the hh cultivate any plot" --- a household-level indicator.
A TZA individual who personally works off-farm but lives in an agricultural household is coded `nonag == 0`.
The RA flagged this concern but it was unresolved.
The impact on the current pipeline is limited because `1_processData.do` does not produce a `TZA_unb_nonag.dta` file; the issue would matter if TZA non-ag results were added later.

Lens: inference / MINOR / LOW (Confidence LOW: the pipeline does not currently produce TZA non-ag output.)

---

## Out of scope (data-creation, deliberately not flagged)

- CHN experience `rowmax` accumulation logic: correct by design (uses best-available wave information).
- South Africa, Malawi, Ghana, Bangladesh sections in 230328: not used in the paper (marked as "not used anymore, moved to Archive" in 250314).
- The 200829 IFLS script: not upstream of the CKT pipeline (see Scope note above).
- `unique pid` calls in 230328: these are good diagnostic practice and were not flagged as issues.
- The `nonagonly` and `switcheran` variable definitions: flagged as uncertain in RA comments; resolving them requires a substantive methodological decision, not a best-practices fix.

---

## Real vs nominal divergence appendix

### Pair 1: 250314 (nominal) vs 260302 (real)

The two files have identical IDN and CHN sections up to a deflation block that appears only in 260302.
TZA differs in the source panel loaded.

| Section | Nominal (250314) | Real (260302) | Character |
|---------|-----------------|---------------|-----------|
| IDN: pre-deflation code | Lines 56--244 construct IDN_temp | Lines 56--243 identical | Identical |
| IDN: deflation | Not present; saves `IDN.dta` directly (line 246) | Imports `Processed Indonesia CPI data.xlsx`; divides `consumption` and `income` by `deflator`; saves `IDN_real.dta` (lines 247--270) | **Intentional switch point** |
| IDN: lncons level | `lncons_tot` is real (renamed from `lncons_tot_real`, line 141); level `consumption` is nominal | Same pre-deflation treatment; then level `consumption` is divided by spatial deflator | Mix present in nominal; resolved in real (see DC-m5) |
| CHN: experience construction | Lines 252--438 (4 waves, raw CFPS) | Lines 276--462 identical | Identical |
| CHN: deflation | Not present; saves `CHN.dta` (line 552) | Imports `Processed China CPI data.xls`; deflates; saves `CHN_real.dta` (lines 577--600) | **Intentional switch point** |
| TZA: source panel | `Panel_LMMVW_TZA.dta` (nominal, line 583) | `Panel_LMMVW_TZA_real.dta` (real, line 631) | **Intentional switch point** |
| TZA: post-merge processing | Identical (experience, hhsize equivalents, drop/compress) | Identical | Identical |
| CHN `hhsize_root` label | `"Square root of hhsize"` (capital S, line 178) | `"square root of hhsize"` (lower s, line 179) | **Accidental drift** |
| CHN `hhsize_comp` label | `"Companion adult equivalent scale..."` (capital C, line 182) | `"companion adult equivalent scale..."` (lower c, line 562) | **Accidental drift** |
| TZA education merge | `keep if _merge==3` (inner join, line 589) | `keep if _merge==3` (inner join, line 637) | Identical behavior; both have the same undiagnosed attrition risk (DC-M1) |

**Verdict:** The two scripts are structurally identical except for three intentional switch points (IDN deflation, CHN deflation, TZA source file).
Collapsing them into a single script with a `real_values` flag requires adding: (a) the Excel import + deflation block for IDN and CHN under `if \`real_values'`; (b) a conditional on which TZA panel to load.
The two label-case drifts (`hhsize_root`, `hhsize_comp`) should be harmonized before merging to avoid confusion about which is canonical.

### Pair 2: 230328 (nominal variable selection) vs 260424 (TZA real variable selection)

File 260424 covers only TZA (169 lines) vs the full multi-country 230328 (720 lines).
The TZA section of 230328 is lines 297--413.

| Dimension | 230328 TZA section | 260424 (full file) | Character |
|-----------|-------------------|--------------------|-----------|
| Raw source | `tza_panel` from LMMVW (line 298) | `tza_panel` from LMMVW (line 43) | Identical |
| Variables kept | Nominal `consumption`, `earnings`; no `consumption_real`, `logearnings_real`, `CPI_tanzania` | Keeps `consumption_real`, `logearnings_real`, `CPI_tanzania`; drops `consumption` and `earnings` (line 66) | **Intentional: core difference** |
| Consumption construction | `consumption` passes through as nominal | Lines 136--142: derives spatial deflator; constructs CPI-deflated real consumption with 2013 base | **Intentional switch point** |
| Income construction | `rename earnings income` (line 394) | `g income = exp(logearnings_real)` then multiply by spatial deflator (lines 145--146) | **Intentional switch point** |
| `nonag` construction | `nonag = 1 if any_ag == 0` (lines 335--338) | Identical (lines 80--83) | Identical (household-level issue, DC-m7) |
| `switcheran` | Lines 344--347 | Lines 89--93 | Identical |
| `hhadults` warning | RA comment: values in thousands (line 387) | Identical RA comment (line 132) | Copy-pasted; known data quality issue in both |
| Output file | `Panel_LMMVW_TZA.dta` (line 413) | `Panel_LMMVW_TZA_real.dta` (line 167) | Naming convention consistent |
| `urbanbirth` | Not available for TZA in either file | Not available | Consistent gap |

**Verdict:** File 260424 is a minimal extension of the TZA section of 230328 --- the only substantive additions are the real-values construction (lines 136--148 of 260424) and the different `keep` list.
Collapsing into one script requires: (a) a `real_values` flag; (b) conditional `keep` list; (c) conditional consumption and income construction.
The rest of the TZA processing is identical and can be shared.

---

## Aggregate score for data-creation scripts

| Lens | Weight | Raw Score | Weighted |
|------|--------|-----------|---------|
| Reproducibility | 25% | 50 | 12.5 |
| Inference | 30% | 72 | 21.6 |
| Data Quality | 20% | 58 | 11.6 |
| Output | 10% | 72 | 7.2 |
| Code Quality | 15% | 65 | 9.8 |
| **Total** | | | **63** |

No CRITICAL issues block readiness.
The score reflects primarily the absence of version declarations, logs, and merge diagnostics across all Dropbox scripts --- reproducibility hygiene that is standard for any shared pipeline.
The TZA inner join (DC-M1) and IDN hhsize replace (DC-M2) are the most pressing correctness concerns.

---

## Small wins for data-creation scripts (under 30 minutes, low risk)

**DSW1 --- Fix IDN `hhsize` unconditional replace (DC-M2).**
Add `if _merge == 3` to the `replace hhsize = hhsize_hklm` line in both 250314 (line 166) and 260302 (line 166).
Add a `count if _merge==1` before it to document unmatched rows.
Two-line change per file.
No risk of changing results if the merge is nearly complete; only prevents silent missing-value creation for the (likely small) set of truly unmatched pidlink-year pairs.

**DSW2 --- Add a `count` before the TZA inner join (DC-M1).**
Insert `count if _merge != 3` before `keep if _merge == 3` in 250314 (line 589) and 260302 (line 637).
One line per file.
Documents the attrition without changing any outcome.

**DSW3 --- Remove `set mem 250m` from 230328 and 260424 (DC-m3).**
Delete line 14 from each.
Zero functional impact on Stata 12+; removes a misleading obsolete command.

**DSW4 --- Fix the "empoyment" label typo (DC-m4).**
Change `"empoyment indicator"` to `"employment indicator"` in 250314 (lines 481, 604) and 260302 (lines 505, 652).
Four one-word fixes.
No impact on results; corrects public-facing variable metadata.

**DSW5 --- Add base-year comments before IDN and CHN deflation blocks (DC-M3).**
Two comment lines in 260302 (before line 259 for IDN, before line 589 for CHN).
Zero code change.
Requires checking the Excel file to confirm the base year before writing the comment.
Under 10 minutes per country.

---

# Post-Tier-3 cleanup queue (added 2026-04-29)

After the current Tier 3 run finishes:

1. **Kill all `$lnsize` references.** Five references in 5_GrRC.do and 8_GrRC_hukou.do, two in `run_grc_with_extra_regressor` (`KEEPLNsize` option + the conditional keep), plus one comment in `0_programs.do`. Pure vestige from David's OLS code where `$lnsize "loghhsize"` was a covariate. The current GMM bakes hh-size adjustment into `lndepvar = log(consumption/hhsize_cube)` and the `$lnsize` slot does nothing. Removal is low risk: if anything breaks, we will notice in the regression test.

2. **Fix the smoke-test overwrite policy.** `_smoke_full.do` currently sets `global skip_if_exists 1` for resume-on-interrupt. For verification semantics we want overwrite-by-default so that re-running a smoke regenerates every cell. Two paths:
   - Default to `global skip_if_exists 0`; set it to `1` only inside an explicit `_smoke_resume.do` driver that knows it is resuming.
   - Keep the dual-mode but document that any "verification" smoke should manually delete `RP7/output/*.ster` before launch.
   The first option is cleaner --- explicit-is-better-than-implicit semantics --- and prevents another situation where a stale ster from a prior debug run silently survives a fresh smoke.
