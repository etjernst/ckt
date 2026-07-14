# Critic-stata review: data-construction pipeline (pre-promotion pass)

Reviewer: critic-stata (fresh context, sonnet), 2026-07-14 late evening.
Requested by the author before promoting the rebuilt hub to canonical.
Scope: `1_processData.do`; the data-construction programs in `0_programs.do` (`data_setup`/`_2waves`/`_3waves`, `use_data`, `handle_choice`, `handle_depvar`, `handle_balance`, `handle_trajectory_groups` and wave variants, `gen_time_trend`, `set_covariates`, `fix_varlabels`, `assert_merge_clean`); `0_path_config.do`; `rebuild_hub.do`.
Estimation programs excluded by design.
The report below is the critic's, verbatim; the parent session persisted it because the critic session had no Write tool.
Adjudication lives separately in [2026-07-14_frontend-critic-adjudication.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_frontend-critic-adjudication.md).

---

## Findings

### CRITICAL-1 — Sample-descriptor variables go stale after set_covariates' row-level drops (Data Quality / silent failure)

File/program: `0_programs.do`, `set_covariates` interacting with `handle_trajectory_groups` and `handle_balance`.
Anchors: `set_covariates`'s `drop if mi(education_max)` / `drop if mi(age)` / `drop if obs_per_individual == 1`; `handle_trajectory_groups`'s `bysort pid: egen obs_per_individual = count(pid)` and `bysort pid (year): g pid_first_obs = _n == 1`; `handle_balance`'s `by pid: gen nr_periods_obs = _N`.
Confidence: HIGH.
`data_setup` runs `handle_balance` then `handle_trajectory_groups` (computes `nr_periods_obs`, `trajectory`, `switcher`, `non_switcher`, `obs_per_individual`, `pid_first_obs`) then `set_covariates` (drops individual person-wave rows for `mi(education_max)`, `mi(age)`, `obs_per_individual==1`).
For unbalanced ("unb") datasets, the strict-spec reflag in `handle_balance` only flags a person as `unbalanced=1`; it does not remove their rows, so rows with missing age/education_max survive into `set_covariates`, which then drops them row-by-row.
None of `nr_periods_obs`, `obs_per_individual`, `trajectory`, `switcher`, `non_switcher`, or `pid_first_obs` is recomputed after these drops, so they describe a panel shape that no longer matches the actual saved rows.
Two concrete failure modes: (a) if the dropped row was a pid's first-year observation, `pid_first_obs` is now 1 for zero of that pid's remaining rows, silently breaking any downstream "one row per person" logic keyed on it; (b) `drop if obs_per_individual == 1` uses the pre-drop count, so a person reduced to a true single remaining row by the two lines directly above it is not caught, defeating the singleton-removal it is meant to perform.
This affects the "unb" specification, the main specification per the project's own documentation (">90% are non-switchers," unbalanced sample).
Fix: recompute `nr_periods_obs`/`obs_per_individual`/`pid_first_obs` (and re-derive `trajectory`/`switcher` if affected) after the `set_covariates` drops, or move the missing-education/age drops earlier (into `handle_balance`'s reflag pass, dropping the rows there before trajectory variables are built) so downstream descriptors are computed on the final row set.

### CRITICAL-2 — rebuild_hub.do skips the CHN hukou-construction prerequisite (Reproducibility)

File: `RP7/tests/stage0/rebuild_hub.do`.
Anchor: `include "$dir/scripts/0_path_config.do"` / `include "$dir/scripts/0_programs.do"` / `include "$dir/scripts/1_processData.do"` with no call to `0_CHN_hukou_restrictions.do` anywhere in the file.
Confidence: HIGH.
`0_master.do` runs `0_CHN_hukou_restrictions.do` (which writes `CHN_hukou_rural_only.dta`, `CHN_hukou_urban_only.dta`, `CHN_hukou_rural_first.dta`, `CHN_hukou_urban_first.dta` into `$dirdata/countries/`) immediately before `1_processData.do`, because 12 of the 34 `1_processData.do` cells (`local country CHN_hukou_*`) read those derived files via `use_data`.
`rebuild_hub.do` never invokes that prerequisite.
Since its `countries` folder is a junction into the canonical `data/countries`, the run either (a) silently reuses whatever hukou-split files happen to already exist there from a prior, uncontrolled run, meaning the "fresh rebuild" is not actually rebuilt from source for 12 of 34 cells, or (b) errors with "file not found" mid-run if those files are absent, since the `capture noisily` wrapper swallows the error without isolating which of the 34 cells failed.
Either way the driver cannot be trusted as a genuine from-source reproducibility check for the hukou-variant outputs, which is exactly the promotion-gating purpose it exists for.
Fix: add `include "$dir/scripts/0_CHN_hukou_restrictions.do"` before `1_processData.do` in `rebuild_hub.do`, repointing its output the same way `$dirdata` is repointed, so the hukou country files are regenerated fresh inside `data_rebuild` rather than reused from the canonical hub.

### CRITICAL-3 — Hardcoded absolute path in rebuild_hub.do (Reproducibility)

File: `RP7/tests/stage0/rebuild_hub.do`, line 18.
Anchor: `global dir "C:/git/ckt/RP7"`.
Confidence: HIGH.
Single machine-specific path with no per-user branching (unlike `0_master.do`'s `c(username)` blocks) and no root-discovery marker-file pattern per the project's own documented convention.
Breaks on any other machine/worktree.
Per the project's own Stata severity rubric this class of issue is Critical.
Fix: either add a `c(username)` branch matching `0_master.do`'s pattern, or derive `$dir` via the marker-file root-discovery pattern instead of a literal path.

### MAJOR-1 — No duplicate check on (pid, period) before any merge or reshape (Data Quality)

File: `0_programs.do`, `handle_trajectory_groups` (and `_2waves`/`_3waves` variants).
Anchor: `reshape wide choice, i(pid) j(period)`.
Confidence: MEDIUM-HIGH.
There is no `duplicates report`/`isid pid period` anywhere in the data-construction path (confirmed: the only `duplicates` calls in `0_programs.do` are inside out-of-scope estimation programs past line 2600).
The only implicit protection is that `reshape wide ... i(pid) j(period)` errors on non-unique (pid, period) pairs, but only for the subsample kept via `keep if !unbalanced`.
A duplicate pid-period pair among individuals who end up flagged `unbalanced` would never trip that check, and would instead silently inflate `nr_periods_obs` in `handle_balance`, corrupting the balance classification itself.
Fix: add an explicit `isid pid period` (or `duplicates report pid period` with an assert) in `use_data` or immediately after, before any other transformation.

### MAJOR-2 — Drop diagnostics reference a return value `drop` does not set (Data Quality / silent failure)

File: `0_programs.do`, `handle_choice` and `handle_depvar`.
Anchors: `display as text "Note: Dropped `r(N_drop)' observations due to missing values in `choice'"`; `display as text "Note: Dropped `r(N_drop)' observations due to missing/negative values in `depvar' "`.
Confidence: MEDIUM.
Stata's `drop if` does not populate an `r(N_drop)` result (no such return is documented for `drop`).
The displayed attrition count is therefore either blank or a stale value carried over from an unrelated earlier r-class command, not the actual number of rows dropped for missing `choice`/`depvar`.
The correct pattern already exists elsewhere in the same file (`handle_balance`'s Change A uses `quietly count if pid_miss_strict & !unbalanced` immediately before printing), which is direct internal evidence of what the fix should look like.
Fix:

```stata
qui count if mi(choice)
local n_drop = r(N)
drop if mi(choice)
display as text "Note: Dropped `n_drop' observations due to missing values in `choice'"
```

### MAJOR-3 — set_covariates' three drops produce zero diagnostic output (Data Quality)

File: `0_programs.do`, `set_covariates`.
Anchor: `drop if mi(education_max)` / `drop if mi(age)` / `drop if obs_per_individual == 1`.
Confidence: HIGH.
Unlike `handle_choice`/`handle_depvar` (which at least attempt a message, see MAJOR-2) and `handle_balance`'s Change A (which prints a real count), these three drops, run on every one of the 34 processed builds, print nothing at all.
There is no visibility into how much sample attrition each of the three conditions causes.
Fix: wrap each drop with a `qui count` before/after and a `display` line, mirroring the Change A pattern in `handle_balance`.

### MAJOR-4 — Primary outcome `lndepvar` can be missing in retained/saved rows with no explicit handling (Data Quality)

File: `0_programs.do`, `handle_depvar`.
Anchor: `gen lndepvar = log(depvar/hhsize_cube)`.
Confidence: MEDIUM-HIGH.
`depvar` is validated (`drop if mi(depvar) | depvar <= 0`) but `hhsize_cube` is not: if `hhsize_cube` is missing or non-positive for a retained row, `lndepvar` becomes missing with no drop and no diagnostic count anywhere in the data-construction path.
`hhsize_cube` missingness is checked only inside `handle_balance`'s strict-spec reflag (which changes the `unbalanced` flag, not the row set), so a `.` value for the outcome the whole GRC/OLS pipeline is built on can ride into the saved canonical `.dta` unaudited.
Fix: add an explicit `qui count if mi(lndepvar)` diagnostic (and a documented decision on whether to drop or retain) in `handle_depvar`, right after `lndepvar` is generated.

### MAJOR-5 — No log file opened anywhere in the data-construction path (Output)

Files: `1_processData.do`, `0_master.do` (context).
Anchor: absence of any `log using` in `1_processData.do`'s header, and absence of any `log using`/`log close` in `0_master.do` (confirmed via repo-wide grep: every other numbered script, e.g. `3_OLS_uGRC.do`, `4_GrRC.do`, `7_GrRC_hukou.do`, opens its own named log; `1_processData.do` and `0_master.do` do not).
Confidence: HIGH.
The project's own `stata-conventions.md` prescribes a named, timestamped master log opened after root discovery.
Here, all of `1_processData.do`'s diagnostics (the counts discussed in MAJOR-2/3/4, `tab trajectory`, `tab trajectory_2waves`, `tab trajectory_3waves` for all 34 cells) rely entirely on the incidental Stata `-e` auto-log for whichever top-level file was invoked.
That auto-log is unnamed by content, not timestamped, and gets silently overwritten on every rerun; there is no durable, per-run audit trail of what the data-construction stage actually did before the pipeline results freeze as canonical.
Fix: open a named log (e.g. `$logs/1_processData_<timestamp>_<user>.log`) at the top of `1_processData.do`, close it at the bottom, independent of whatever auto-log the invoking `-e` session produces.

### MAJOR-6 — Derived CHN hukou-split files are written into the immutable "raw" countries/ folder (Reproducibility / Data governance)

File: `0_CHN_hukou_restrictions.do` (upstream of the reviewed `1_processData.do`, read for context).
Anchor: `save "$dirdata/countries/CHN_hukou_rural_only.dta", replace` (and the three sibling saves).
Confidence: MEDIUM.
`$dirdata/countries/` is documented project-wide (`source-of-truth.md`) as holding "the raw .dta files ... immutable."
`0_CHN_hukou_restrictions.do` writes four derived subsets into that same folder, and `1_processData.do`'s `use_data` treats them exactly like raw country files.
This blurs the raw/processed boundary and creates an undocumented ordering dependency (`1_processData.do` silently assumes `0_CHN_hukou_restrictions.do` has already run), the direct cause of CRITICAL-2.
Fix: write the hukou-derived files to `$dirdata/processed/` (or a new `$dirdata/derived/`) instead of `$dirdata/countries/`, and have `use_data` read hukou variants from there.

### MAJOR-7 — Dead `depvar` parameter and stale comment in set_covariates (Code Quality)

File: `0_programs.do`, call site in `data_setup` and the `set_covariates` definition.
Anchors: `set_covariates `depvar' `country'	// if depvar == consumption --> include hh size`; `args depvar country` (the local `depvar` is never referenced again in the program body; `loghhsize` is generated unconditionally for every country/depvar combination).
Confidence: HIGH on the mismatch; MEDIUM on whether it constitutes an actual bug versus vestigial comment.
The comment describes conditional logic ("if depvar == consumption --> include hh size") that does not exist in the code; `loghhsize` is generated the same way regardless of `depvar`.
This is either a stale comment from an earlier version or a sign that intended depvar-conditional behavior was dropped during a refactor without updating the comment or removing the unused parameter.
Fix: either implement the conditional the comment describes, or delete the dead `depvar` argument and the misleading comment.

## Minor findings

- `1_processData.do` has no `version`/`clear all`/`set varabbrev off`/log declarations of its own (MINOR, confidence MEDIUM): relies on being `include`d after `0_master.do` or `rebuild_hub.do` has already set these, which is a documented project pattern for sub-scripts but still deviates from the file-level convention.
- No explicit final `sort pid period` before each `save` in `1_processData.do` (MINOR, confidence LOW): row order after `merge m:1 pid using traj` is deterministic but implicit rather than defensively asserted.
- `baseline_age` (`age1993`/`age2010`/`age2008`) can be missing for individuals absent in the baseline wave with no diagnostic surfaced in `set_covariates` (MINOR, confidence LOW-MEDIUM).
- `ln_income`/`ln_consumption` in `handle_depvar` are generated unconditionally regardless of which `depvar` was chosen, with no missingness diagnostic (MINOR, confidence LOW): harmless (log of non-positive silently returns missing, not zero, so it does not violate the no-zero-fill rule) but unaudited.
- `rebuild_hub.do` never checks that the `data_rebuild/countries` junction exists before running; failure surfaces as an opaque "file not found" deep inside `use_data` rather than a clear precondition message (MINOR, confidence MEDIUM).

## Strengths worth noting

`assert_merge_clean` is a well-built, reusable merge-diagnostic helper and is called consistently after every merge in the reviewed scope.
`handle_balance`'s "Change A" strict-spec reflag is clearly commented, uses a correctly-computed diagnostic count, and documents its own rationale.
`0_path_config.do`'s nominal/real `$values` switch fails loudly (`exit 198`) on an unrecognized value rather than defaulting silently.

## Severity counts

CRITICAL: 3.
MAJOR: 7.
MINOR: 5.

## Verdict

Do not promote.
Three CRITICAL findings gate this: (1) sample-descriptor variables (`obs_per_individual`, `nr_periods_obs`, `trajectory`, `switcher`, `pid_first_obs`) go stale relative to actual saved rows in the unbalanced datasets, the project's main specification, because `set_covariates` drops rows after those descriptors are computed and never recomputes them; (2) `rebuild_hub.do`, the tool meant to verify the processed data is reproducible from source, silently skips the CHN hukou-construction prerequisite, so it cannot actually validate 12 of the 34 processed cells; (3) `rebuild_hub.do` hardcodes a single-machine absolute path.
Fix CRITICAL-1 first, it is the one that can alter the content of the canonical datasets themselves, not just the process used to verify them, then re-run the full pipeline and re-check summary counts before any promotion decision.
