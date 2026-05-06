# Phase 1b.6 spec --- `run_grc_with_extra_regressor` + GRC_extras.do

Date: 2026-04-28
Author: Emilia (with Claude)
Branch: `worktree-grc-pipeline-refactor`
Status: draft, awaiting approval

## Goal

Replace 6 near-duplicate do-files (`10/11/12/13_GrRC_*experience*.do`, `14_GrRC_NonAg_experience.do`, `15_GrRC_birth.do`) with one program in `0_programs.do` plus one driver `GRC_extras.do` containing 44 explicit per-cell calls. Net file count: 27 do-files → 22 (six deleted, one added).

The 6 files differ only in the "extra regressor" injected ahead of the c1/c2/c3/ca progressive-covariate chain (`exp`, `exp_max`, `exp_share`, `exp_max_share`, `urbanbirth`).

## Constraints (workflow / context)

- Tier 3 was launched twice (`bosgo168d`, `bbrryiled`) on 2026-04-28 and killed in both cases once we discovered the M11 collision issue. **Tier 3 is paused until disambiguation completes.** This avoids producing 30h of sters under collided names.
- During implementation 0_programs.do, GRC_extras.do, make_tables.do, 0_master.do, _smoke_full.do all change. No Stata is running, so no edit-collision concern.
- After implementation: re-launch Tier 3. Skip-if-exists in run_grc means existing M11-correct sters are preserved; mis-named sters from prior smokes will simply be ignored (run_grc will produce new properly-named ones).

## M11 collision discovery (this changed scope)

When we initially specced this work, the design said the new code should be byte-identical against Tier 3 sters from 10–15. That's wrong: M11's commit message explicitly states 10–13/14/15 retained pre-existing cross-section ster collisions ("Disambiguation lands in Phase 1b").

Concretely:
- File 10/11/12/13: 3 sections (cuu, cub, iuu) all hardcode `cuu` in the ster name. Sections 2/3 silently overwrite section 1's sters; only section 3 (iuu) survives on disk. Tables are correct because they're built immediately after each section's GMM, before the next overwrite.
- File 14: 4 sections (exp, maxexp, expsh, maxexpsh for IDN cnu) all hardcode `cnu_exp`. 4-way collision; only maxexpsh survives.
- File 15: 4 sections (cuu, cub, iuu, cnu for IDN with birth) all hardcode `cuu_birth`. 4-way collision; only cnu survives.

Phase 1b.6 IS the disambiguation step. Each of the 44 stems gets its own correctly-named ster set.

Verification cannot be byte-diff against Tier 3 sters (names won't match). Verification path is `.tex` table comparison: run new GRC_extras.do + new make_tables.do additions, diff resulting tables against `tests/reference/output/tables/`. Tables built right after each section's GMM in the OLD pipeline are bit-identical to tables built from per-stem disambiguated sters in the NEW pipeline.

## Scope --- MUST

User direction (2026-04-28): all tables separated from regressions (Option II from earlier discussion); disambiguation completed BEFORE re-launching Tier 3.

1. **Add `run_grc_with_extra_regressor` to `0_programs.do`.** One stem per call (open data → setup → init → 4 fits c1/c2/c3/ca). Signature:
   ```stata
   program define run_grc_with_extra_regressor
       syntax , country(string) spec3(string) regressor(varname) ///
                [ iterate(integer 100) ]
   end
   ```
   - `country` ∈ `{IDN, CHN, TZA}`
   - `spec3` ∈ `{cuu, cub, iuu, cnu}`. Determines `choice`, `depvar`, `balance`, dataset path internally.
   - `regressor` is the variable name to inject (e.g. `exp`, `exp_max`, `exp_share`, `exp_max_share`, `urbanbirth`).
   - `fam_token` is **derived internally** from `regressor` via lookup (`exp`→`exp`, `exp_max`→`maxexp`, `exp_share`→`expsh`, `exp_max_share`→`maxexpsh`, `urbanbirth`→`birth`). Caller passes only `regressor`.
   - Produced ster names: `grc_<country>_<spec3>_<fam_token>_{c1,c2,c3,ca}` plus `_n` and `_g` subgroup files (run_grc handles these). 44 stems × 5 sters per stem = 220 sters, all distinct on disk (no collisions).

2. **Build `GRC_extras.do`** as a new file in `RP7/scripts/`. Slim — GMM only, no inline tables.
   - Header, log open, 44 explicit per-cell calls, log close, exit.
   - NO loops over country/spec/family. Each call is one line.
   - Cell coverage (44 stems = 36 + 4 + 4):
     - **From 10/11/12/13:** 9 stems × 4 families = 36. The 9 stems are 3 specs (cuu, cub, iuu) × 3 countries (IDN, CHN, TZA), each crossed with 4 families (exp, maxexp, expsh, maxexpsh).
     - **From 14:** 4 stems = IDN cnu × 4 families.
     - **From 15:** 4 stems = IDN × 4 specs (cuu, cub, iuu, cnu) × 1 family (birth).
   - `log close; exit, STATA clear` at the end (per stata-conventions).

3. **Extend `make_tables.do` with 44 new table cells.** Each one is the same per-cell shape already used for 5/6/8 family tables:
   ```
   local country IDN
   local postfoot_str ...
   grc_tex_table_trend_exp, columns(4) spec(cuu_exp) country(`country') ///
       filename(GRC_`country'_consumption_urban_unb_exp) ...
   if $copyOverleaf == 1 { copyOverleaf ... }
   ```
   - Use existing `grc_tex_table_trend_exp` and `grc_tex_table_trend_birth` programs from 0_programs.do (already updated in 1b.5b/c to read sters from disk and fragment-only output).
   - Filename pattern unchanged from 10–15: `GRC_<country>_<depvar>_<choice>_<balance>_<fam>.tex`.
   - Per-cell explicit calls (no loops).

4. **Verification before deletion of 10–15.**
   - Run `GRC_extras.do` standalone (or via a tiny driver) on one canonical stem per family — e.g. TZA cuu × exp/maxexp/expsh/maxexpsh and IDN cuu × birth — with `${skip_if_exists}` off so sters are produced fresh.
   - Run `make_tables.do` to build the corresponding 5 .tex tables.
   - Compare resulting .tex content against `tests/reference/output/tables/GRC_TZA_consumption_urban_unb_exp.tex` etc. (these are present from Phase 1b.1's import; OLD-format envelope-wrapped). Note the format mismatch: post-1b.3 tables are SLIM (no envelope), references are OLD. The TABULAR BODY (the part inside `\begin{tabular}{l cccc}...\end{tabular}`) should match byte-for-byte after stripping the envelope.
   - If tabular bodies match for the 5 audit stems, accept the new code path.

5. **Atomic commits.**
   - Commit A (6a): `run_grc_with_extra_regressor` in `0_programs.do`.
   - Commit B (6b): `GRC_extras.do` (slim GMM driver).
   - Commit C (6b+): table cells appended to `make_tables.do`.
   - Commit D (6d): smoke verification + tabular-body diff results.
   - Commit E (6e): swap `0_master.do` (6 includes → 1), update `_smoke_full.do` similarly, delete 10/11/12/13/14/15.

6. **Re-launch Tier 3** (after 6e) and let it complete unattended.

## Scope --- SHOULD

- Mirror `run_grc`'s `${skip_if_exists}` cascading behavior — i.e., the new program's 4 inner `run_grc` calls each independently honor the skip guard. No new skip logic at the wrapper layer.
- Keep `_smoke_full.do` consistent: when 6c lands, replace the 6 individual includes with one `GRC_extras.do` include.
- Keep the per-cell call sites readable: 4-line comment header per stem (`* IDN cuu × experience`), with the call vertically aligned for visual scanning.

## Scope --- MAY

- Add a mini-driver `_smoke_extras_only.do` that runs just `GRC_extras.do` (analogous to `_smoke_tables_only.do`). Useful for fast iteration.
- Document in `0_programs.do`'s table-of-contents header comment that `run_grc_with_extra_regressor` exists.

## Out of scope

- Migrating 5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do --- these have a different structure (c0/c1/c2/c3/ca with no extra regressor at c1) and are not duplicates.
- Migrating 2_OLS_uGRC.do, 7_OLS_uGRC_hukou.do, 9_learning.do --- different estimation path (direct esttab, not run_grc).
- Refreshing tables. Tier 3 + `make_tables.do` handle that downstream.
- Changing `run_grc` itself.

## Verification gate (before deletion of 10–15)

| Check | Pass criterion |
|---|---|
| Tier 3 completion | `_smoke_full.do` finished cleanly; expected ster count present under M11 naming |
| Byte-identical ster output (6 stems × 4 fits = 24 sters per audit) | `tools/sterdiff.py` reports zero diffs vs. Tier 3 sters |
| Compile sanity | Re-run `make_tables.do` after audit; reference-test passes (or only the expected slim/old format diffs we already know about) |

If any audit stem differs, **do not** delete 10–15. Investigate. The new program is wrong somewhere.

## Risks

- Subtle data-prep differences between 10/11/12/13 and 14/15: 10–13 build `keepvars` once at the top of the file; 14 redefines `keepvars` per section to include the right extra regressor. The new program must compute its own `keepvars` based on the `regressor` arg.
- `setup_grc_estimation` reads `$choice`, set in the calling script. The program must set `$choice` correctly before calling.
- `replace lndepvar = log(consumption/hhsize_cube)` vs `log(income/hhsize_cube)` — must dispatch on `spec3` (cuu/cub/cnu use consumption; iuu uses income).
- `iterate(100)` is the existing convention. Keep it as the default; no caller currently overrides.

## Acceptance

Spec is approved when:
- The cell list (44 calls) is enumerated in this spec or the plan, with each row showing (country, spec3, fam_token, regressor, expected ster prefix).
- The plan specifies the order of commits and the audit command.
- Tier 3's running state is acknowledged (no edits to 10–15 / 5 / 6 / 8 mid-run).
