# Phase 4 plan: `values(nominal|real)` switch (M4)

Status: draft, awaiting user approval.
Branch: `worktree-grc-pipeline-refactor`.
Umbrella spec: [quality_reports/specs/2026-04-24_grc-pipeline-refactor.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md), section M4.

## What we just learned

The entire diff between `Dropbox/.../ReplicationPackage6/scripts/` and `Dropbox/.../ReplicationPackage6 - real values/scripts/` is three lines in `0_master.do`---all `global dir = "...ReplicationPackage6"` vs `"...ReplicationPackage6 - real values"`.
The script body is otherwise byte-identical between the two folders.
Both data folders (`Dropbox/.../ReplicationPackage6/data/` and `Dropbox/.../ReplicationPackage6 - real values/data/`) have the same `countries/` + `processed/` subdirectory structure; the difference lives in the `.dta` files themselves (deflated values vs nominal).

So the M4 implementation is purely about routing `$dirdata` to one folder or the other and tagging output artifacts so they don't clobber.
No script logic changes; no estimation changes.

## Design choice: filename suffix vs separate output dir

Spec says append `_${values}` to ster, CSV, and LaTeX filenames so both can coexist in the same `output/`.
Considered the alternative (separate `output_nominal/` + `output_real/` dirs) but rejected because:

1. The S1 ster scraper (Phase 5) is simpler if all sters live in one dir---one glob pattern, parser keys off the suffix.
2. The paper-side `\input{tables/<file>}` macros would need dir-aware logic if outputs split across dirs.
3. Visual diff of nominal vs real is easier when files are in the same folder.

Going with the spec.

## Backward-compatibility constraint

Pre-Phase-4 sters and tables have NO `_${values}` suffix (e.g. `grc_IDN_cuu_c0.ster`, `GRC_IDN_consumption_urban_unb.tex`).
The Phase 0 reference set in `tests/reference/` has the bare names.
905+ sters on disk right now have the bare names.
A naive "always append `_${values}`" would invalidate the entire reference and all existing sters.

So: append `_r` only when `values == "real"`.
Nominal mode produces bare names (byte-identical to current).
This preserves Tier 0 reference, existing sters, and existing paper-side `\input{tables/GRC_<...>}` references.

## Implementation: stage 1, `0_path_config.do`

Add the switch logic at the top of `0_path_config.do`:

```stata
* values switch (M4 / Phase 4): nominal (default) reads $dir/data; real
* reads $dir/data_real (which junctions to the deflated-values data folder
* in Dropbox). $vsfx is appended to ster, CSV, and LaTeX filenames so
* nominal and real outputs coexist without clobbering. Nominal mode keeps
* bare filenames for backward compat with the pre-M4 reference set.
if "$values" == "" {
    global values "nominal"
}

if "$values" == "nominal" {
    global vsfx ""
    global dirdata "$dir/data"
}
else if "$values" == "real" {
    global vsfx "_r"
    global dirdata "$dir/data_real"
}
else {
    di as error "0_path_config: unknown values=$values; must be nominal or real"
    exit 198
}
```

Caller knob: set `global values "real"` BEFORE `include "0_path_config.do"` to switch.
`_smoke_full.do` and `0_master.do` keep their default (no `global values` line; resolves to nominal).
Add a one-line override at the top of any future `_smoke_real_only.do` or interactive session.

## Implementation: stage 2, junction `RP7/data_real`

Create a Windows directory junction:

```cmd
cmd /c mklink /J "RP7/data_real" "C:\Users\maand\Dropbox (Personal)\Returns to migration\ReplicationPackage6 - real values\data"
```

Mirrors the existing `RP7/data` junction pattern.
Add `RP7/data_real` to `.gitignore` (or confirm `RP7/data*` already covers it).

Per machine: each dev needs to recreate the junction locally.
Document in `CLAUDE.md`'s "Workspace" section.

## Implementation: stage 3, append `${vsfx}` to disk artifacts

Two surface areas: ster paths (`run_grc*` programs) and LaTeX paths (`grc_tex_table_trend`, `het_table_*`, etc.).

### Ster paths (in `0_programs.do`)

Five programs, five `estimates save` blocks each (main, _n, _a, _d, _g):

| Program | Lines |
|---|---|
| `run_grc` | 1950, 1957, 1964, 1993, 2018 |
| `run_grc_with_extra_regressor` | 2279, 2284, 2289, 2308, 2326 |
| `run_grc_onestep` | (in the 23xx range) |
| `run_grc_robust` | 2548, 2587, 2595, 2618, 2640 |
| `run_grc_robust_vv` | 2821, 2831, 2836, 2856, 2874 |

Pattern: `estimates save "$dir/output/`estname'<sfx>", replace` becomes `estimates save "$dir/output/`estname'<sfx>${vsfx}", replace`.

The skip-on-exists guard at the top of `run_grc` (M10) checks `_g.ster`; that needs the suffix too.

### LaTeX paths

Inside `grc_tex_table_trend` (the unified M3 program):
- 3 `estimates use "$dir/output/<...>"` lookups: append `${vsfx}` so it reads the right ster set.
- 3 `esttab using "$output/tables/`filename'.tex"` calls: append `${vsfx}` to the filename.
- 1 `capture confirm file "$dir/output/<...>.ster"` skip-check: append `${vsfx}`.

`het_table_delta`, `het_table_mu`: same `esttab using` pattern; append `${vsfx}` to the filename.

`sumstats_table`, `create_panel_tex_table`, `reghdfe_regressions`: these write to `$output/tables/<filename>.tex` too; append `${vsfx}` for consistency, or skip them if they're not values-dependent.
Decision: append everywhere `$output/tables/` appears, even for tables that don't depend on the deflation, so the user can run a real-values pipeline end-to-end without any nominal-vs-real artifact ambiguity.
Cost is one global expansion per table emit; no risk.

`extras_tex_table` builds `filename(GRC_<...>_<file_suffix>)` and passes to the unified `grc_tex_table_trend`; the suffix gets appended inside the unified program, so no change to `extras_tex_table` itself.

## Implementation: stage 4, paper-side macro update

The paper's `\GRCtable`, `\GRCexptable`, `\GRChukoutable` macros do `\input{tables/GRC_#1_#2_#3_#4}` (no values suffix).
For real-values papers, they would need to read `\input{tables/GRC_#1_#2_#3_#4_real}`.

Two options:

(a) Add a `\GRCvaluesfx` macro in `preamble.tex`, default empty, set to `_r` for real-values builds. `\input{tables/GRC_#1_#2_#3_#4\GRCvaluesfx}`.

(b) Don't touch the paper. Real-values runs produce parallel `_r`-suffixed `.tex` files; the user manually edits the paper's `\input` references for any real-values builds.

**Recommend (a).** One-line preamble addition; flexible per-build switch.
Out-of-scope for this in-repo commit set since `preamble.tex` lives in Overleaf-Dropbox.
Document in the M4 commit message; user applies the preamble change manually.

## Validation

### Tier 1 (grep)

After edits, every `estimates save / estimates use / capture confirm file / esttab using` that references `$dir/output/` or `$output/tables/` should have `${vsfx}` appended.
A grep for `\$dir/output/` or `\$output/tables/` should find ZERO matches that lack `${vsfx}` (ignoring comments and skip-on-exists check messages).

### Tier 2 (replay, nominal mode)

In nominal mode, `$vsfx` is empty so all paths reduce to the pre-M4 form.
Re-run `_smoke_tables_only.do` against existing sters and diff every `output/tables/*.tex` against the pre-M4 reference.
Expected: byte-identical (except for the M3 Δ_avg label change already verified in commit `5e2277c`).

This validates that nominal mode is unaffected.

### Tier 2 (single-cell, real mode)

Pick one cell---say `grc_IDN_cub_c0`---and:

1. Set up the `RP7/data_real` junction.
2. In a fresh Stata session: `global values "real"`, then run the cuu/cub/iuu cells of `5_GrRC.do` for IDN.
3. Diff the resulting `grc_IDN_cub_c0_real.ster` against the existing real-values `.ster` from `Dropbox/.../ReplicationPackage6 - real values/output/`.
4. Bit-identical confirms the values switch is functionally equivalent to the script-fork it replaces.

This is the "spec deferred archival decision" check: only if real mode produces existing real-values results exactly should we archive `ReplicationPackage6 - real values\scripts\`.

### Tier 3 (deferred)

A full real-values smoke run would take ~30 hours and isn't part of this phase.
Defer until the spec's "archival decision" question is answered (post-Phase-4 single-cell verification).

## Phase 4 commit plan

1. **`docs/plans/2026-04-30-phase4-values-switch.md`** (this file).
2. **`0_path_config.do` switch logic** (stage 1).
3. **Junction `RP7/data_real`** (stage 2).
   Out-of-band; document in commit message.
   Add to `.gitignore` if not already covered.
4. **`0_programs.do` ster path suffix** (stage 3, 5 programs × 5 saves = 25 sites).
   One commit covers all 5 programs' ster paths.
5. **`0_programs.do` LaTeX path suffix** (stage 3 cont., grc_tex_table_trend + het_table_* + sumstats_table + create_panel_tex_table + reghdfe_regressions).
   One commit covers all table-emitting programs.
6. **`CLAUDE.md` workspace doc update** for the `RP7/data_real` junction.
7. **Tier 2 nominal-mode validation** post-Tier-3 #4 finish.
   Confirms backward compat.

## Decisions from user (2026-05-01)

1. **Output stays in `RP7/output/`** (not the Dropbox folder).
The real-values Dropbox path is INPUT only; output is always local under `$dir/output`.
No risk of clobbering the coauthor's working set.
2. **Suffix is `_r`, not `_r`.**
The 32-char `_est_` ceiling is already tight on the longest M11 estnames (`grc_IDN_cuu_maxexpsh_ca_d` = 25 chars + `_est_` = 30); `_r` (5 chars) would bust the limit at 35, `_r` (2 chars) lands at exactly 32.
Two-char suffix keeps every existing estname legal even if we later decide to disambiguate stored names too.
3. **Two verification cells:** `grc_IDN_cub_c0` (no covs) and `grc_IDN_cub_ca` (full covs), both on the IDN balanced sample.
Bit-compare both against the existing real-values sters from `Dropbox/.../ReplicationPackage6 - real values/output/`.
4. **Preamble change is optional, deferred.**
Spec implication: pipeline-side M4 produces `_r`-suffixed `.tex` files; the paper's `\input{tables/GRC_<...>}` macros stay hardcoded for nominal.
A real-values paper build would later need a one-line `\GRCvaluesfx` switch in `preamble.tex` (default empty, set to `_r` for real builds).
Out of scope for this in-repo commit set; flag for a follow-up Overleaf edit when the user actually wants a real-values paper.

## Risks

- **MAJOR.** Any missed `$dir/output/` or `$output/tables/` write that fails to append `${vsfx}` will cause real-mode runs to clobber nominal-mode files.
  Mitigated by the Tier 1 grep validation as a hard gate.
- **MAJOR.** If `data_real` junction points at a deflated data folder with a different schema (e.g. extra columns, renamed variables), `data_setup` could fail or silently produce different results.
  Mitigated by the single-cell bit-comparison against the existing real-values output.
- **MINOR.** Existing pre-M4 sters have bare filenames; under M4 nominal mode the program saves to bare filenames too, so pre-existing sters keep working.
  No risk for nominal.
