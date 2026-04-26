# Audit of `0_programs.do`

Date: 2026-04-24
File audited: `C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do` (3096 lines)
Callers cross-referenced: `RP7/scripts/*.do` (22 do-files).

## Scope and method

This audit reads `0_programs.do` statically.
For each `program define`, it records the line range, `syntax` (or `args`) line, required and optional arguments, one-sentence purpose, a caller count from grepping top-level invocations across `RP7/scripts/*.do`, and any hardcoded literals that leak through the abstraction (magic base trajectories, hardcoded country names, hardcoded `estname` prefixes, hardcoded cov lists, hardcoded `phistart`).
I did not run Stata; behavioral claims are based on reading, not execution.

45 programs are defined.
Three are confirmed dead (never called outside `0_programs.do` itself): `sumstats_table`, `ugrc_regressions`, `run_grc_onestep`.
Three more are staged but not yet wired into the numbered pipeline: `run_grc_robust`, `run_grc_robust_vv`, `initial_values_robust` (used by the exploration in `explorations/verdier/`, not by `5_GrRC.do` et al.).

## Dependency graph

Call edges shown for within-`0_programs.do` invocations only; the "(caller do-files)" annotation summarizes which numbered scripts invoke the top-level program.

```
data_setup                                  (<- 2, 3, 6, 10..15)
  |-- use_data
  |-- handle_choice
  |-- handle_depvar
  |-- handle_balance
  |-- handle_trajectory_groups
  |-- set_covariates
  |-- gen_time_trend
  \-- fix_varlabels

data_setup_2waves                           (<- 1_processData.do)
  |-- [same as data_setup, plus:]
  \-- handle_trajectory_groups_2waves

data_setup_3waves                           (<- 1_processData.do)
  |-- [same as data_setup, plus:]
  \-- handle_trajectory_groups_3waves

setup_grc_estimation                        (<- 5, 6, 8, 10..15)

initial_values                              (<- 5, 6, 8, 10..15)

initial_values_robust                       (<- explorations only; NO numbered caller)
  \-- gen_vfirst

run_grc                                     (<- 5, 6, 10..15)
  \-- define_switcherpars

run_grc_onestep                             (<- NONE; dead / experimental)
  \-- define_switcherpars

run_grc_hukou                               (<- 8_GrRC_hukou.do)
  \-- define_switcherpars

run_grc_robust                              (<- explorations only; NO numbered caller)
  |-- gen_vfirst
  \-- define_switcherpars

run_grc_robust_vv                           (<- explorations only; NO numbered caller)
  |-- gen_vfirst
  \-- define_switcherpars

heterogeneity_plots                         (<- 3_heterogeneity_plots.do)

reghdfe_regressions                         (<- 2_OLS_uGRC.do, 7_OLS_uGRC_hukou.do)
reghdfe_regressions_learn_IDN               (<- 9_learning.do)
reghdfe_regressions_learn_CHN               (<- 9_learning.do)

ugrc_regressions                            (<- NONE; dead)

country_summary_stats                       (<- 1_summaryStats.do)
country_summary_stats_2waves                (<- 1_summaryStats.do)
country_summary_stats_3waves                (<- 1_summaryStats.do)
country_summary_stats_nonag                 (<- 1_summaryStats.do)

sumstats_table                              (<- NONE; dead -- superseded by country_summary_stats+removeStringFromTex workflow)

create_panel_tex_table                      (<- 2, 6, 7)
create_panel_tex_table_learn_IDN            (<- 9)
create_panel_tex_table_learn_CHN            (<- 9)

grc_tex_table                               (<- NONE among numbered callers; likely dead, overlaps grc_tex_table_trend)
grc_tex_table_trend                         (<- 5, 6)
grc_tex_table_trend_hukou                   (<- 8)
grc_tex_table_trend_exp                     (<- 10, 11, 12, 13, 14)
grc_tex_table_trend_birth                   (<- 15)

het_table_delta                             (<- 16)
het_table_mu                                (<- 16)

copyOverleaf                                (<- 2, 5, 6, 7, 8, 9, 10..15, 16)
removeStringFromTex                         (<- 1_summaryStats.do)
```

Dead or unwired:

- `sumstats_table` — defined at L478--L547, never called from any numbered do-file.
- `ugrc_regressions` — defined at L1401--L1429, never called.
- `run_grc_onestep` — defined at L1828--L1943, never called from numbered pipeline (used only as the degenerate-V fallback inside `run_grc_robust`, which itself is unwired).
- `grc_tex_table` — defined at L2577--L2656; no numbered caller uses it (all GRC tables go through `grc_tex_table_trend*`). Keep until confirmed.
- `run_grc_robust`, `run_grc_robust_vv`, `initial_values_robust` — defined but only exercised by files under `explorations/verdier/`.

## Program-by-program audit

### copyOverleaf
- Line range: L32--L44.
- Signature: `syntax anything(name=fileName1), SUBdir(string asis)`.
  Required: positional filename; SUBdir().
- Purpose: copies a generated file into `$overleaf/<subdir>/`, replacing backslashes with forward slashes first.
- Callers: 2, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 (14+ files; ~50 invocations). Guarded by `if $copyOverleaf == 1` in callers.
- Hardcoded values: relies on `$overleaf` global (set in `0_setup.do`). No severity concerns.
- Extension points: `[force]` flag to ignore a missing global; `mode(table|figure|bib)` to pick subdir automatically.
- Known bugs: none.

### data_setup
- Line range: L46--L71.
- Signature: `args country choice depvar balance` (positional).
- Purpose: one-shot wrapper that opens the country dataset, sets choice/depvar/balance, builds trajectories, generates covariates, and fixes labels.
- Callers: `1_processData.do` (12), `2_OLS_uGRC.do` (6), `3_heterogeneity_plots.do` (3), `6_GrRC_NonAg.do` (3), `7_OLS_uGRC_hukou.do` (8+), and the experience/birth branches (10..15 each call once per country per spec).
- Hardcoded values: none at this level (delegates everything). MINOR: `depvar` accepts a varname (`consumption`/`income`) and the sub-programs generate both `ln_income` and `ln_consumption` unconditionally. MAJOR: the covariate globals inside `set_covariates` are fixed and cannot be overridden from here.
- Extension points: `[covspec(string)]` to pick which covariate globals to build; `[hhsize_norm(cube|raw|log)]` to let the outer script stop doing `replace lndepvar = log(consumption/hhsize_cube)` by hand; `[waves_min(integer)]` to collapse `data_setup` / `_2waves` / `_3waves` into one.
- Known bugs: none.

### data_setup_2waves
- Line range: L73--L101.
- Signature: `args country choice depvar balance`.
- Purpose: as `data_setup` but also builds `traj_2waves` / `switcher_2waves` for the >=2-wave subsample.
- Callers: `1_processData.do` (6 invocations).
- Hardcoded values: MINOR — the sub-program `handle_trajectory_groups_2waves` carries an enormous hardcoded string list of trajectory codes (see below).
- Extension points: merge with `data_setup` via `waves_min(integer)` option.
- Known bugs: none at this level.

### data_setup_3waves
- Line range: L103--L131.
- Signature: `args country choice depvar balance`.
- Purpose: same as `data_setup_2waves` but with a 3-wave minimum.
- Callers: `1_processData.do` (6).
- Hardcoded values: inherits `handle_trajectory_groups_3waves` string list.
- Extension points: collapse into `data_setup ..., waves_min()`.
- Known bugs: none at this level.

### use_data
- Line range: L136--L140.
- Signature: `args country`.
- Purpose: `use "$dirdata/countries/`country'", clear`.
- Callers: only via `data_setup*` (internal).
- Hardcoded values: relies on `$dirdata` global. Filename convention `<country>.dta`.
- Extension points: optional `[subdir(string)]` to support `data/processed/` variants; `[suffix(string)]` for `_income` datasets that callers currently open inline (`5_GrRC.do` L906 etc. hand-opens `${country}_${balance}_income.dta`).
- Known bugs: none.

### handle_choice
- Line range: L145--L153.
- Signature: `args choice`.
- Purpose: clones the chosen treatment variable (`urban` or `nonag`) into a variable literally named `choice`, drops missing, assigns a hardcoded label per choice string.
- Callers: internal via `data_setup*`.
- Hardcoded values: MINOR — `"urban"` and `"nonag"` are the only two recognized choice names; adding a new treatment (e.g., `offfarm`) requires editing the program.
- Extension points: `[label(string)]` to let caller pass label; make the literal list a local so additions are one-line.
- Known bugs: none.

### handle_depvar
- Line range: L158--L171.
- Signature: `args depvar`.
- Purpose: clones `depvar` to variable `depvar`, drops missing or non-positive, generates `lndepvar`, and unconditionally also generates `ln_income` and `ln_consumption`.
- Callers: internal via `data_setup*`.
- Hardcoded values: MAJOR — the program always tries to `gen ln_income = ln(income)` and `gen ln_consumption = ln(consumption)`. If a country dataset does not contain both, this errors; if either is zero/negative for some rows, those rows silently get missing $\ln$ without being dropped (unlike the primary `lndepvar` path). CRITICAL-adjacent if a new country dataset lacks one of these.
- Extension points: `[auxlns(namelist)]` to control which auxiliary log variables to build; move the unconditional `ln_income`/`ln_consumption` out of here and into a dedicated helper.
- Known bugs: the `drop if mi(depvar) | depvar <= 0` rule silently discards zero-income observations from the $\ln$(income) spec; for log-consumption this is usually harmless but for income it quietly shrinks the sample.

### handle_balance
- Line range: L176--L190.
- Signature: `args balance`.
- Purpose: xtsets the panel, constructs `unbalanced` and `unbalanced_choice` indicators, and keeps only balanced observations if `balance == "bal"`.
- Callers: internal via `data_setup*`.
- Hardcoded values: MINOR — string literal `"bal"` is the only value that triggers balancing; any other string (including `"balanced"`) silently leaves the panel unbalanced.
- Extension points: accept `unb|bal` via an explicit enum check and error on unknown values.
- Known bugs: `gen unbalanced_choice = unbalanced*choice` assumes `choice` already exists (which it does in the wrapper's call order, but is fragile).

### handle_trajectory_groups
- Line range: L195--L252.
- Signature: no `args` / `syntax` (expects caller to have set things up).
- Purpose: builds `trajectory`, `switcher`, `non_switcher`, and `obs_per_individual` by reshaping balanced-only rows into wide choice strings and encoding them.
- Callers: internal via `data_setup*`.
- Hardcoded values: uses `pid`, `period`, `year`, `choice` (all conventional), and requires `unbalanced` to exist. MINOR.
- Extension points: none obvious.
- Known bugs: relies on `encode` sort order — comment at L218 notes the "natural" ordering is load-bearing for switcher indexing.

### handle_trajectory_groups_2waves
- Line range: L257--L310.
- Signature: no syntax.
- Purpose: same as above but restricted to individuals with >=2 waves, producing `trajectory_2waves`, `switcher_2waves`, `non_switcher_2waves`.
- Callers: internal via `data_setup_2waves`.
- Hardcoded values: CRITICAL — L299--L300 contain an enormous hardcoded enumeration of every possible trajectory string (`"00" | "000" | "0000" | ... | "11110"`) up to length 5. Any country with 6+ waves will silently mark those trajectories as `non_switcher_2waves = .`, which downstream becomes NaN rather than 0 or 1. Easy to overlook.
- Extension points: replace the string enumeration with a regex or a parsed check (`non_switcher = regexm(trajectory_2waves, "^0+$|^1+$")`). Accept `maxwaves(integer)` if enumeration must stay.
- Known bugs: hardcoded to 5-wave maximum.

### handle_trajectory_groups_3waves
- Line range: L315--L367.
- Signature: no syntax.
- Purpose: analogue for 3-wave minimum.
- Callers: internal via `data_setup_3waves`.
- Hardcoded values: CRITICAL — same issue as 2waves, L357 enumerates trajectory strings of lengths 3 through 5.
- Extension points: same refactor.
- Known bugs: hardcoded to 5-wave maximum.

### gen_time_trend
- Line range: L372--L377.
- Signature: no args.
- Purpose: generates `trend = year - min(year at period==1)`.
- Callers: internal via `data_setup*`.
- Hardcoded values: assumes variable names `year`, `period`. MINOR.
- Extension points: none needed.
- Known bugs: none.

### gen_vfirst
- Line range: L390--L400.
- Signature: `syntax , vname(varname) genname(name)`.
- Purpose: first-wave non-missing value of `vname` per `pid`; used to build the time-invariant cluster index $v_i$ for Verdier (2020) robust specs.
- Callers: internal to `initial_values_robust`, `run_grc_robust`, `run_grc_robust_vv`.
- Hardcoded values: assumes sort key `(pid, year)`. MINOR — could be configurable.
- Extension points: `[sortvar(varname) default(year)]`.
- Known bugs: header comment documents the previous buggy `egen min(cond(...))` attempt; current implementation is correct per the unit test at `explorations/verdier/3_test_gen_vfirst.do`.

### set_covariates
- Line range: L406--L457.
- Signature: `args depvar country`.
- Purpose: generates `loghhsize`, `rural`, `baseline_age`, `ag` (IDN only), plus squared terms, and defines a suite of `$covs_*` globals.
- Callers: internal via `data_setup*`.
- Hardcoded values:
  - MAJOR: `clonevar baseline_age = age1993` (IDN), `age2010` (CHN and all hukou variants), `age2008` (TZA). New country or new data vintage requires editing this program.
  - MAJOR: `"CHN" | "CHN_hukou_rural_only" | "CHN_hukou_urban_only" | "CHN_hukou_rural_first" | "CHN_hukou_urban_first"` — the full list of hukou slices is hardcoded; adding a new slice means editing the string.
  - MAJOR: the `$covs_*` and `$covs_gmm_*` global names are the entire covariate vocabulary of the pipeline. They are also re-defined in many caller do-files (see `5_GrRC.do` L42--L44), duplicating the definitions.
  - MINOR: `drop if obs_per_individual == 1` hardcodes a singleton drop (silently changes samples).
- Extension points: `[baseline_year(integer)]` to pick the baseline-age variable; `[country_family(string)]` so `CHN_hukou_*` derives from one declaration; move covariate globals into a dedicated `set_cov_globals` program that accepts an `override` option.
- Known bugs: IDN baseline uses `age1993` even though IDN has 5 waves from 1993--2015; this is intentional (Hamory et al. convention) but silent.

### fix_varlabels
- Line range: L461--L472.
- Signature: no args.
- Purpose: adds variable labels used by downstream table programs.
- Callers: internal via `data_setup*`.
- Hardcoded values: MINOR — a fixed list of variables it labels; silently no-ops if a var is absent (via `capture: lab variable nonag`).
- Extension points: none needed.
- Known bugs: none.

### sumstats_table
- Line range: L478--L547.
- Signature: `syntax, TABle_notes(string asis) COUNTRY(string asis) OUTputdir(string asis) FILEname(string asis) BALance(string asis)`.
- Purpose: writes a hand-rolled LaTeX summary-stats table (threeparttable + tabular) from a pre-loaded v1..v9 dataset.
- Callers: NONE in `RP7/scripts/*.do`. DEAD CODE.
- Hardcoded values: literal country names ("Indonesia"/"China"/"Tanzania") at L482--L490; row-15 hardcoded as "Observations" (`if mod(i,2) == 1 & i != 15`); hardcoded column header "Location" and "Non-Agricultural" labels. CRITICAL if resurrected.
- Extension points: replace with the now-standard `country_summary_stats` + `removeStringFromTex` workflow, or delete.
- Known bugs: relies on `choice` local being in scope from the caller (uses `"`choice'"` without having it as an option).

### country_summary_stats
- Line range: L552--L615.
- Signature: `args country choice depvar balance`.
- Purpose: runs `iebaltab` on the loaded dataset (rural + ln_consumption + ln_income + ...), writes a CSV, re-imports it, and rewrites rows to emit a custom v1..v9 layout that the (dead) `sumstats_table` or the inline caller expects.
- Callers: `1_summaryStats.do` (6 invocations for urban-choice panels).
- Hardcoded values:
  - CRITICAL: the varlist passed to `iebaltab` is hardcoded (`rural ln_consumption ln_income female age education_max hhsize`). Missing either `ln_income` or `ln_consumption` (e.g., a dataset that never built one) will silently cause fewer rows; the `set obs 19` and `replace v1 = "..." in 17` rely on a fixed number of rows.
  - MAJOR: row indexes 16, 17, 18, 19 are hardcoded to "\cmidrule", "Observations", "Individuals", "Non-switchers" (L606--L609). Any change to the variable list breaks the row numbering.
- Extension points: `[varlist(varlist)]` and compute the final row indexes from `_N`.
- Known bugs: emits `summary_stats_${country}_${balance}.csv` to the current working directory (implicit `cd` dependency).

### country_summary_stats_2waves
- Line range: L620--L684.
- Signature: `args country choice depvar balance`.
- Purpose: 2-waves-subsample variant.
- Callers: `1_summaryStats.do` (3).
- Hardcoded values: same CRITICAL and MAJOR issues as `country_summary_stats`.
- Extension points: collapse with the base version via `waves_min()`.
- Known bugs: same.

### country_summary_stats_3waves
- Line range: L689--L753.
- Signature: `args country choice depvar balance`.
- Purpose: 3-waves-subsample variant.
- Callers: `1_summaryStats.do` (3).
- Hardcoded values: same issues.
- Extension points: same.
- Known bugs: same.

### country_summary_stats_nonag
- Line range: L759--L822.
- Signature: `args country choice depvar balance`.
- Purpose: ag/non-ag variant of `country_summary_stats`.
- Callers: `1_summaryStats.do` (1).
- Hardcoded values: same pattern; headers switch to "Non-Agricultural"/"Agricultural".
- Extension points: merge with `country_summary_stats` via `choice_kind(urban|nonag)` option.
- Known bugs: same.

### removeStringFromTex
- Line range: L827--L839.
- Signature: `syntax anything(name=texFileName), REMove(string asis)`.
- Purpose: uses `filefilter` to strip a string from a .tex file.
- Callers: `1_summaryStats.do` (22).
- Hardcoded values: none.
- Extension points: accept `[To(string) default("")]` for substitution instead of deletion.
- Known bugs: none.

### create_panel_tex_table
- Line range: L844--L923.
- Signature: `syntax, Panels(integer) COLumns(integer) FILEname(string asis) COUNTRIES(string asis) Keep(varlist) PREhead(string asis) POSTfoot(string asis) COEFLABels(string asis) TEXTdepvar(string asis)`.
- Purpose: emits the three-country panel-stacked OLS table via repeated `esttab` passes.
- Callers: `2_OLS_uGRC.do` (4), `6_GrRC_NonAg.do` (2), `7_OLS_uGRC_hukou.do` (4).
- Hardcoded values: MAJOR — the panel labels are hardcoded: `Panel A: Indonesia`, `Panel B: China`, `Panel C: Tanzania` (L872, L880, L885, L890). Panel order is fixed; callers that pass `countries(CHN IDN TZA)` would still get Indonesia labeling on the first panel. Also estname prefix hardcoded to `reg<j>_<country>` (L903).
- Extension points: `panel_labels(string)` option; `est_prefix(string)` default `reg`.
- Known bugs: `local num_panels `panels'` is computed but `panels` is already the integer option, so the local is redundant.

### create_panel_tex_table_learn_IDN
- Line range: L928--L977.
- Signature: `syntax, COLumns(integer) FILEname(string asis) Keep(varlist) PREhead(string asis) POSTfoot(string asis) COEFLABels(string asis) TEXTdepvar(string asis)`.
- Purpose: learning-model table, IDN-specific, with 4 urban/rural learning periods.
- Callers: `9_learning.do` (2).
- Hardcoded values: MAJOR — the `s()` statistics list names `urban_2 urban_3 urban_4 rural_2 rural_3 rural_4` (L968), assuming exactly 4 learning periods. Estname pattern `reg<j>_IDN` is hardcoded. Country label "IDN" appears in the code.
- Extension points: `country(string)` and `nperiods(integer)` to merge with the CHN variant.
- Known bugs: none.

### create_panel_tex_table_learn_CHN
- Line range: L982--L1031.
- Signature: same as IDN variant.
- Purpose: learning-model table, CHN-specific (3 periods instead of 4).
- Callers: `9_learning.do` (2).
- Hardcoded values: MAJOR — estname pattern `reg<j>_CHN` and 3-period `s()` list (L1022) hardcoded.
- Extension points: merge with IDN variant.
- Known bugs: none.

### reghdfe_regressions
- Line range: L1036--L1058.
- Signature: `args country choice depvar balance`.
- Purpose: seven-column OLS/FE regression block (`reg1_<country>` .. `reg7_<country>`) using `$covs_*` globals.
- Callers: `2_OLS_uGRC.do` (10), `7_OLS_uGRC_hukou.do` (12).
- Hardcoded values:
  - MAJOR: column count is fixed at 7 (L1040 comment says "Run col 7 first"); the covariate progression `$covs_1`, `$covs_2`, `$covs_all` is hardcoded to those global names.
  - MAJOR: `absorb(pid period)` in col 7 is hardcoded; col 1 uses `noabsorb`; other cols use `absorb(period)`.
  - MINOR: `vce(cluster pid)` hardcoded.
- Extension points: `cov_schedule(string)` to let the caller pass a list of cov globals; `fixedeffects(string)` for absorb choices; `ncols(integer)`.
- Known bugs: the `choice` and `balance` args are received but not used inside the program (they come through the preloaded `choice` variable).

### reghdfe_regressions_learn_IDN
- Line range: L1063--L1149.
- Signature: `args country depvar balance`.
- Purpose: four-column learning-model OLS for IDN, with joint/pairwise tests on the urban_<k>period and rural_<k>period coefficients.
- Callers: `9_learning.do` (L83, called as `reghdfe_regressions_learn_${country}` via macro substitution).
- Hardcoded values: MAJOR — four-period structure hardcoded; covariate set `$covs_all` hardcoded; the test block is copy-pasted four times (L1068--L1149) for reg4/reg1/reg2/reg3.
- Extension points: `nperiods(integer)`; internal loop over columns.
- Known bugs: none.

### reghdfe_regressions_learn_CHN
- Line range: L1151--L1221.
- Signature: `args country depvar balance`.
- Purpose: three-period CHN variant of the learning OLS.
- Callers: `9_learning.do` (via same macro substitution as IDN).
- Hardcoded values: MAJOR — three-period structure hardcoded; same copy-paste pattern.
- Extension points: merge with IDN variant via `nperiods()`.
- Known bugs: none.

### setup_grc_estimation
- Line range: L1227--L1253.
- Signature: no args.
- Purpose: builds the $switchers globals ($never=1, $always=last, $switchers=2..last-1, $noalways, $last, $first) and generates `always`, `always_choice`, `never`, `switcher_s`, `switcher_s_choice` dummies per trajectory.
- Callers: `5_GrRC.do` (6), `6_GrRC_NonAg.do` (3), `8_GrRC_hukou.do` (12), `10_GrRC_experience.do` (6), ... — every GRC do-file.
- Hardcoded values: MINOR — `$never = 1` hardcodes the never-urban trajectory as index 1 (relies on `encode` producing 000...0 as the smallest). `replace trajectory = 999 if trajectory == .` hardcodes 999 as the unbalanced marker.
- Extension points: `[unbalanced_marker(integer) default(999)]`.
- Known bugs: none, but the reliance on `encode` sort order is a silent contract.

### heterogeneity_plots
- Line range: L1258--L1396.
- Signature: `args country choice depvar balance`.
- Purpose: runs two `reghdfe` specs (with/without covariates), tests joint equality of mu and Delta, and emits four coefplot PDFs per country.
- Callers: `3_heterogeneity_plots.do` (3).
- Hardcoded values:
  - MAJOR: truncation length per country (L1332--L1340): IDN=5, CHN=4, TZA=3. Adding a fourth country requires editing.
  - MAJOR: country text labels ("Indonesia"/"China"/"Tanzania") hardcoded L1261--L1269.
  - MAJOR: `$covs_all` is baked in.
  - MINOR: color `lavender` hardcoded; filename suffix `_Fcovars`/`_Fnocovars` hardcoded.
- Extension points: `[country_label(string)]`, `[truncate(integer)]`, `[covarglobal(string)]`, `[palette(string)]`.
- Known bugs: none.

### ugrc_regressions
- Line range: L1401--L1429.
- Signature: `args country choice depvar balance`.
- Purpose: seven-column unrestricted-GRC OLS (the first two `eststo reg7_` assignments overwrite each other — L1406 and L1411 both use estname `reg7_<country>`).
- Callers: NONE. DEAD CODE.
- Hardcoded values: same patterns as `reghdfe_regressions`.
- Extension points: delete or merge with `reghdfe_regressions` via a `spec(ols|ugrc)` option.
- Known bugs: CRITICAL — the first `eststo reg7_` is overwritten in the same program by the second `eststo reg7_` before it is ever used (L1406 vs L1411). Either a bug or dead scaffolding. Since nothing calls it, no downstream harm.

### initial_values
- Line range: L1435--L1531.
- Signature: `syntax varlist(min=1) [if], switchers(numlist) estname(string) balance(string) [print]`.
- Purpose: runs an OLS that returns r(mu_s), r(Delta_s), and picks a base trajectory (the one with the largest |t-stat| on Delta among switchers with N/T > 5), returning r(base) and a `from()`-compatible `initial` local.
- Callers: 5, 6, 8, 10..15 (6 invocations per GRC script).
- Hardcoded values:
  - MAJOR: criterion `N_s / T > 5` is a hardcoded minimum-obs threshold (L1520).
  - MAJOR: the default base `local base = 2` (L1508) leaks as a fallback when no switcher meets the criterion.
  - MINOR: covariate side is skipped; the OLS regresses on `always*` and `switcher_*` only, with `vce(cluster pid) nocons` hardcoded.
- Extension points: `[base_min_obs(real) default(5)]`, `[default_base(integer) default(2)]`, `[covars(varlist)]` to include covariates in the OLS.
- Known bugs: the `foreach s of numlist $switchers` block at L1468--L1470 and L1482--L1484 duplicates mu lines in the `initial` local (each mu appears twice). Appears intentional to seed GMM with both the free mu and a pinned copy, but the code structure is opaque.

### initial_values_robust
- Line range: L1544--L1658.
- Signature: `syntax varlist(min=1) [if], switchers(numlist) estname(string) balance(string) vindex(varname) [print]`.
- Purpose: Verdier (2020) Section F variant that additionally generates `vfirst` via `gen_vfirst`, builds `vchoice_v = I(vfirst==v)*choice` for v != v_base, and adds these to the OLS so the coefficients can seed GMM beta_dev parameters.
- Callers: NONE in numbered scripts (used in `explorations/verdier/`).
- Hardcoded values: same `base = 2` fallback and `N_s / T > 5` rule as `initial_values`. Baseline cluster `v_base = first value of levelsof vfirst` (L1565) is hardcoded as "first distinct value ascending".
- Extension points: `[base_min_obs]`, `[default_base]`, `[vbase(numlist) default(first)]`.
- Known bugs: drops observations with missing `vfirst` (L1560) before the OLS; subsequent callers should be aware the sample is trimmed. This is documented in the header comment (L1542).

### define_switcherpars
- Line range: L1664--L1683.
- Signature: `syntax, switchers(numlist) base(numlist)`.
- Purpose: builds the `switcherpars` local (the expression that enters the GMM moment as `phi*(switcherpars)`), namely `sum over s != base of ({mu:switcher_s} - {mu:switcher_base}) * (switcher_s#1.choice)`.
- Callers: all `run_grc*` variants via internal call; 1 call site each inside `run_grc`, `run_grc_onestep`, `run_grc_hukou`, `run_grc_robust`, `run_grc_robust_vv`.
- Hardcoded values:
  - CRITICAL (per the known-bugs list in CLAUDE.md): the docstring comment at the top of the file and the old behavior flag the `base(2)` default. The CURRENT code (L1668) declares `syntax, switchers(numlist) base(numlist)` with NO default, so `base()` is required. Memory-described "hardcoded base(2)" appears to refer to the historical callers that pass `base(2)` or to the fallback in `initial_values` (L1508), NOT to `define_switcherpars` itself as shipped in `RP7/scripts/0_programs.do`.
  - VERIFICATION: `run_grc` at L1713 passes `base(`base')` where `base` is the local returned by `initial_values`, which defaults to 2 when no switcher meets N/T>5. So the CRITICAL bug actually lives in `initial_values` (L1508) and propagates through — for IDN income (should be 16) and TZA income (should be 5) the default would silently be 2 unless a switcher happens to win the t-stat criterion. This matches the CLAUDE.md description and must be tested on the actual sample before asserting what base the code picks in practice.
- Extension points: `[base(numlist) default(2)]` with a warning if the default is used; validate base is in switchers list.
- Known bugs: see CRITICAL note above — the `base(2)` issue is upstream in `initial_values`, not here. Confirm by running: load IDN income sample, call `initial_values`, inspect `r(base)`.

### run_grc
- Line range: L1688--L1815.
- Signature: `syntax, estname(string) switchers(numlist) base(numlist) balance(string) [covars(varlist) iterate(numlist) initial(string) phistart(real -1)]`.
- Purpose: the workhorse GMM — fits the pooled-trajectory GRC moment, saves `${estname}`, `${estname}_never`, `${estname}_always`, `${estname}_delta`, `${estname}_avg` .ster files, adds J-stat and convergence scalars.
- Callers: 5 (15), 6 (5), 10 (4), 11 (4), 12 (4), 13 (4), 14 (4), 15 (4), ~44 invocations.
- Hardcoded values:
  - MAJOR: `vce(cluster pid)` hardcoded (L1730).
  - MAJOR: default `phistart(real -1)` (L1692) bakes in the pro-poor prior; fine for consumption but should be surfaced in doc.
  - MAJOR: `quickderivatives nolog` hardcoded.
  - MAJOR: weighting matrix default left to Stata (two-step GMM) — contrast with `run_grc_onestep` which uses `winitial(unadjusted, independent) onestep`.
  - MINOR: output path `$dir/output/${estname}*.ster` hardcoded.
  - MINOR: `"unb"` vs "else" balance handling (L1695--L1702) hardcodes the one-unbalanced-covariate pattern.
- Extension points: `[vcetype(string) default(cluster pid)]`, `[gmmopts(string)]` passthrough for `winitial()` / `onestep`, `[outdir(string)]` for the .ster directory. The ster-rename session already moved callers to a uniform `estname` spec, so that part is done.
- Known bugs: the `base` propagated from `initial_values` may be wrong for IDN/TZA income (see `define_switcherpars` and `initial_values`). CLAUDE.md flags this as the CRITICAL `base(2)` bug.

### run_grc_onestep
- Line range: L1828--L1943.
- Signature: identical to `run_grc`.
- Purpose: same GMM equation but with `winitial(unadjusted, independent) onestep`; exists as the apples-to-apples comparator for `run_grc_robust`.
- Callers: NONE in numbered scripts. Exercised only by exploration/verdier.
- Hardcoded values: same set as `run_grc` plus the hardcoded `winitial(unadjusted, independent) onestep` (L1864--L1865).
- Extension points: fold into `run_grc` as `[gmmspec(twostep|onestep) default(twostep)]`.
- Known bugs: none; `estat overid` wrapped in capture because onestep has no Hansen J.

### run_grc_hukou
- Line range: L1948--L2038.
- Signature: `syntax, estname(string) switchers(numlist) base(numlist) balance(string) [covars(varlist) iterate(numlist) initial(string)]`.
- Purpose: same GMM as `run_grc` but pins `phi = -1` (not a free parameter) and saves `_n`, `_a`, `_avg` rather than `_never`, `_always`, `_delta`, `_avg`.
- Callers: `8_GrRC_hukou.do` (60 invocations across 12 hukou-slice x 5-spec combos).
- Hardcoded values:
  - CRITICAL: `phi = -1` is hardcoded at L1980 (not exposed as a `phistart` option), so the user cannot change the pinned value without editing the program. If the true $\phi$ for the rural-first-only slice is not -1, all hukou point estimates will be off.
  - MAJOR: ster suffixes `_n` / `_a` differ from `run_grc`'s `_never` / `_always`, forcing `grc_tex_table_trend_hukou` to use a different `local ests_never` pattern (see L2780). A pure renaming duplication.
  - MINOR: omits the `_delta`/`per-switcher Delta joint test` block that `run_grc` has.
- Extension points: collapse into `run_grc` via `[phi_fixed(real)]` option and `[ster_suffix(never|n) default(never)]`.
- Known bugs: the hardcoded `phi = -1` is effectively a restriction that differs from the main spec and should be documented as such at call sites (it is not).

### run_grc_robust
- Line range: L2055--L2337.
- Signature: `syntax, estname(string) switchers(numlist) base(numlist) balance(string) vindex(varname) [covars(varlist) iterate(numlist) initial(string) phistart(real -1)]`.
- Purpose: Verdier robust extension — adds |V|-1 cluster*choice interactions as free GMM parameters (`beta_dev`), switches vce to cluster vfirst, uses onestep weighting, and emits cluster-support diagnostics.
- Callers: NONE in numbered scripts.
- Hardcoded values: `winitial(unadjusted, independent) onestep` hardcoded (L2198--L2199); `cluster vfirst` for the non-degenerate branch and `cluster pid` for the |V|=1 branch hardcoded; `nclust_ge10` threshold of 10 hardcoded at L2103.
- Extension points: `[vcecluster(varname) default(vfirst)]`, `[min_sw_per_cluster(integer) default(10)]`.
- Known bugs: `Delta_never` uses cluster-share-weighted aggregator (L2247); `Delta_always`/`Delta_delta`/`Delta_avg` use baseline-cluster beta as placeholder — documented deliberately as deferred to P2 (L2051--L2054).

### run_grc_robust_vv
- Line range: L2369--L2572.
- Signature: same as `run_grc_robust`.
- Purpose: alternative robust port that keeps CKT parameters unchanged and replaces the `switcher_s_choice` instruments with within-cluster-demeaned residuals (VV Table1 style).
- Callers: NONE in numbered scripts.
- Hardcoded values: same GMM settings (onestep, vce cluster vfirst) hardcoded.
- Extension points: same as `run_grc_robust`.
- Known bugs: for non-switcher pid rows, zero-fills the demeaned residual (L2408) — documented in header. This is intentional but fragile.

### grc_tex_table
- Line range: L2577--L2656.
- Signature: `syntax, COLumns(integer) FILEname(string asis) COUNTRY(string asis) KEEP(string) varlabel(string asis) PREhead(string asis) POSTfoot(string asis) COEFLABels(string asis) TEXTdepvar(string asis)`.
- Purpose: one-country GRC table loop over `covs_0 covs_1 covs_2 covs_all covs_trend`.
- Callers: NONE in numbered scripts (superseded by `grc_tex_table_trend`). Likely dead.
- Hardcoded values:
  - MAJOR: est list `covs_0 covs_1 covs_2 covs_all covs_trend` hardcoded (L2608). The order differs from `grc_tex_table_trend` (which puts `covs_trend` in position 2, not position 5).
  - MAJOR: estname pattern `grc_${country}_${est}(_never|_avg)?` hardcoded (L2609--L2611).
- Extension points: merge with `grc_tex_table_trend` and take the column order as an option.
- Known bugs: `local num_panels `panels'` (L2586) references a non-existent local `panels` (the syntax is `COLumns`, not `Panels`). Likely a leftover from copy-paste; harmless since `num_panels` is never used.

### grc_tex_table_trend
- Line range: L2662--L2742.
- Signature: same as `grc_tex_table` plus `htb(string)`.
- Purpose: same as `grc_tex_table` but with `covs_0 covs_trend covs_1 covs_2 covs_all` ordering and a user-supplied `htb` placement.
- Callers: `5_GrRC.do` (6), `6_GrRC_NonAg.do` (3).
- Hardcoded values: same as `grc_tex_table` with the different hardcoded covariate list.
- Extension points: `[est_schedule(string) default("covs_0 covs_trend covs_1 covs_2 covs_all")]` to absorb `grc_tex_table`.
- Known bugs: same stray `local num_panels panels` (L2671).

### grc_tex_table_trend_hukou
- Line range: L2748--L2828.
- Signature: same as `grc_tex_table_trend` minus the `htb` option.
- Purpose: variant that uses ster suffix `_n` (not `_never`) and `c0 ct c1 c2 ca` codes (not `covs_*`).
- Callers: `8_GrRC_hukou.do` (12).
- Hardcoded values: MAJOR — both the est-name schedule `c0 ct c1 c2 ca` and the `_n` suffix are hardcoded (L2779--L2780). Tracking artifact of `run_grc_hukou` using different ster conventions.
- Extension points: `[est_schedule(string)]`, `[never_suffix(string) default(_never)]`.
- Known bugs: same stray `num_panels` local.

### grc_tex_table_trend_exp
- Line range: L2834--L2914.
- Signature: same as `grc_tex_table_trend_hukou`.
- Purpose: experience/exp-share variant using `c1 c2 c3 ca` codes and the `_never`/`_avg` suffixes.
- Callers: `10`, `11`, `12`, `13` (9 each), `14` (4).
- Hardcoded values: MAJOR — est schedule `c1 c2 c3 ca` hardcoded (L2865); no column for no-covariate or trend-only baseline.
- Extension points: same `est_schedule` option.
- Known bugs: same stray `num_panels` local.

### grc_tex_table_trend_birth
- Line range: L2920--L3000.
- Signature: same as `_exp`.
- Purpose: byte-identical to `grc_tex_table_trend_exp` in this file's snapshot; the only difference would be the caller's `textdepvar`/`coeflabels` strings.
- Callers: `15_GrRC_birth.do` (4).
- Hardcoded values: same as `_exp`.
- Extension points: DELETE and let `15_GrRC_birth.do` call `grc_tex_table_trend_exp`.
- Known bugs: duplication with `_exp`.

### het_table_delta
- Line range: L3005--L3048.
- Signature: `syntax, FILEname(string asis) COUNTRY(string asis) KEEP(string) htb(string) PREhead(string asis) POSTfoot(string asis) COEFLABels(string asis) TEXTdepvar(string asis)`.
- Purpose: single-column heterogeneity table for the `_delta` ster (joint chi2 and p).
- Callers: `16_heterogeneity_tables.do` (3).
- Hardcoded values: MAJOR — ster name hardcoded to `grc_${country}_covs_all_delta` (L3026). Cannot report a different covariate spec without editing.
- Extension points: `[estname(string) default(grc_${country}_covs_all_delta)]` or `[covspec(string) default(covs_all)]`.
- Known bugs: none.

### het_table_mu
- Line range: L3053--L3096.
- Signature: same as `het_table_delta`.
- Purpose: single-column heterogeneity table for the mu estimates (from the main ster, not `_delta`).
- Callers: `16_heterogeneity_tables.do` (3).
- Hardcoded values: MAJOR — ster name hardcoded to `grc_${country}_covs_all` (L3074). Same issue.
- Extension points: same as `het_table_delta`; could merge the two with a `stat(delta|mu)` option.
- Known bugs: none.

## Refactor-target options summary

#### data_setup (merged with data_setup_2waves / data_setup_3waves)
Proposed new options:
- `waves_min(integer) default(1)` — absorbs the `_2waves` / `_3waves` variants.
- `covspec(string) default(default)` — selects which set of `$covs_*` globals to build (default, hukou, exp, exp_share, maxexp, maxexp_share, birth).
- `hhsize_norm(none|cube|raw|log) default(none)` — lets the wrapper normalize consumption by household size so callers stop doing `replace lndepvar = log(consumption/hhsize_cube)` by hand.
- `ln_aux(namelist) default(ln_income ln_consumption)` — replaces the unconditional generation inside `handle_depvar`.

#### set_covariates
Proposed new options:
- `baseline_year(integer)` — absorbs the `age1993`/`age2010`/`age2008` country branches.
- `country_family(string)` — absorbs the hardcoded hukou-slice list.
- `override_globals(string)` — allows callers to supply their own covariate globals instead of the baked-in set.

#### handle_trajectory_groups_2waves / _3waves
Proposed refactor:
- Replace the enumerated string-comparison lists with `non_switcher_Nwaves = regexm(trajectory_Nwaves, "^0+\$|^1+\$")`.
- Parametrize `waves_min(integer)`.

#### initial_values
Proposed new options:
- `base_min_obs(real) default(5)` — surfaces the `N/T > 5` criterion.
- `default_base(integer) default(2)` — surfaces the fallback base trajectory (critical for IDN/TZA income where 2 is wrong).
- `covars(varlist)` — lets the OLS include covariates so the Delta t-stat ranking is covariate-adjusted.
- `assert_base_in_switchers` — error if the winning base is not in `switchers()`.

#### run_grc (the unified GMM interface)
Proposed new options (merging `run_grc`, `run_grc_onestep`, `run_grc_hukou`, `run_grc_robust`, `run_grc_robust_vv`):
- `spec(main|onestep|hukou|robust_dummy|robust_vv) default(main)` — picks the moment equation and weighting.
- `phistart(real) default(-1)` — already present in `run_grc`, add to `run_grc_hukou`.
- `phi_fixed(real)` — if set, pins $\phi$ (absorbs `run_grc_hukou`'s hardcoded `phi = -1`).
- `vcetype(string) default(cluster pid)` — absorbs the vce switch to `cluster vfirst` in the robust variants.
- `vindex(varname)` — cluster index for the robust specs (optional when spec=main).
- `gmm_weighting(twostep|onestep) default(twostep)` — absorbs `run_grc_onestep`.
- `ster_never_suffix(string) default(_never)` / `ster_always_suffix(string) default(_always)` — absorbs `run_grc_hukou`'s `_n` / `_a` peculiarity during the transition; long-term deprecate.
- `outdir(string) default("$dir/output")` — absorbs hardcoded `$dir/output/` paths.
- `cluster_diag_threshold(integer) default(10)` — absorbs the `n_sw_v >= 10` threshold.

#### reghdfe_regressions (+ reghdfe_regressions_learn_IDN/CHN)
Proposed new options:
- `cov_schedule(string) default("none female female_age2 female_age2_edu")` — replaces hardcoded `$covs_1`, `$covs_2`, `$covs_all`.
- `ncols(integer) default(7)` — replaces the fixed 7-column block.
- `fe_schedule(string)` — list of `absorb()` choices per column.
- `learning_periods(integer) default(0)` — if > 0, switches to the learning-variant behavior and auto-generates the `urban_<k>period rural_<k>period` test block (merges `_learn_IDN` and `_learn_CHN`).
- `store_tests(string)` — controls which `estadd scalar` lines get emitted.

#### create_panel_tex_table (+ _learn_IDN / _learn_CHN)
Proposed new options:
- `panel_labels(string)` — replaces hardcoded "Panel A: Indonesia" / "Panel B: China" / "Panel C: Tanzania".
- `est_prefix(string) default(reg)` — replaces hardcoded estname pattern.
- `stats(string)` — replaces the hardcoded `s(urban_p urban_2 ...)` list in the learn variants.
- `nperiods(integer)` — merges `_learn_IDN` (4) and `_learn_CHN` (3).

#### heterogeneity_plots
Proposed new options:
- `country_label(string)` — replaces hardcoded country text labels.
- `truncate(integer)` — replaces the hardcoded IDN=5 / CHN=4 / TZA=3 truncation.
- `covarglobal(string) default($covs_all)` — exposes the covariate choice.
- `palette(string) default(lavender)` — exposes color.
- `file_suffix(string) default(Fcovars)` — already encoded but hardcoded.

#### country_summary_stats (+ _2waves / _3waves / _nonag)
Proposed new options:
- `waves_min(integer) default(1)` — absorbs the 2waves/3waves variants.
- `choice_kind(urban|nonag) default(urban)` — absorbs the nonag variant.
- `varlist(varlist) default(rural ln_consumption ln_income female age education_max hhsize)` — replaces hardcoded iebaltab varlist; also fixes the fragile row-number dependency by computing the count.

#### grc_tex_table family (grc_tex_table, _trend, _trend_hukou, _trend_exp, _trend_birth)
Proposed new options (to collapse all five into one):
- `est_schedule(string) default("covs_0 covs_trend covs_1 covs_2 covs_all")` — replaces the hardcoded column list.
- `est_prefix(string) default(grc)` — replaces hardcoded `grc_${country}_`.
- `never_suffix(string) default(_never)` — absorbs the hukou variant's `_n`.
- `avg_suffix(string) default(_avg)`.
- `htb(string) default(htbp)`.
- `extra_stats(string)` — exposes the `s(N_clust N Jstat Jpval converged_str, ...)` block.

With all of the above, delete `grc_tex_table` (never called), `grc_tex_table_trend_hukou` (use `est_schedule(c0 ct c1 c2 ca)` and `never_suffix(_n)`), `grc_tex_table_trend_exp` (use `est_schedule(c1 c2 c3 ca)`), and `grc_tex_table_trend_birth` (byte-identical to `_exp`).

#### het_table_delta / het_table_mu
Proposed new options (to merge):
- `stat(delta|mu) default(delta)` — picks which ster and which `collabels()`.
- `estname_pattern(string) default(grc_${country}_covs_all)` — exposes ster dependence so non-`covs_all` specs can be reported.

## Cross-cutting observations

- Every `run_grc*` variant writes estimates to hardcoded `$dir/output/${estname}*.ster`. A shared `outdir()` option would simplify the refactor.
- Every `grc_tex_table*` variant contains the stray `local num_panels `panels'` line even though none of them take a `Panels` option — copy-paste leftover. Harmless but worth cleaning during the refactor.
- Five of the 45 programs (`sumstats_table`, `ugrc_regressions`, `run_grc_onestep`, `grc_tex_table`, plus `run_grc_robust` / `run_grc_robust_vv` / `initial_values_robust` as staged-but-unwired) are confirmed or likely unreferenced by the numbered pipeline.
- Four programs have the `base(2)`-fallback issue in some form: `initial_values` (L1508, the root), `initial_values_robust` (L1644, same default), and via propagation `run_grc` / `run_grc_hukou` / `run_grc_robust` / `run_grc_robust_vv` when the t-stat criterion picks no switcher. The CLAUDE.md memory attributes this to `define_switcherpars`; static reading shows `define_switcherpars` actually requires `base()` as a mandatory option. The real defaulting is upstream in `initial_values`.
- `run_grc_hukou` pins `phi = -1` as a hardcoded literal (L1980) rather than as a restricted parameter — this is a substantive econometric choice masquerading as a coding detail.

## Unknowns flagged for runtime verification

1. Confirm that `initial_values` actually returns `r(base) = 2` for IDN income and TZA income (expected CRITICAL) — static reading cannot predict which switcher wins the t-stat criterion without running the regression.
2. Confirm which of the staged robust programs are reachable from `0_master.do` vs purely from `explorations/verdier/`. Only `0_master.do` inclusion counts as "wired."
3. Confirm that `grc_tex_table` is truly unused; a caller may exist in a not-yet-renamed file I missed.
4. Confirm that `handle_trajectory_groups_{2,3}waves` is never called on a dataset with 6+ waves — if it is, the hardcoded trajectory-string enumeration silently leaves those rows as missing.
