# Plan: OLS + restricted GRC table restructure (2026-07-01)

Branch: lca-inversion. Mode: Implementation.

## Goal

Four coordinated table changes, plus regeneration (tables only, no GRC re-run):

1. Drop column (1) from the restricted GRC tables (the `c0` spec: no time FE, no covariates).
2. Drop column (1) from the OLS tables (the `reg1` spec: no absorb, no covariates).
3. In the OLS tables, put the Time FE row above the Covariates row.
4. Add the weak-identification-robust (LCA inversion) CI rows to the main-text GRC tables, for
   $\Delta_{\text{never}}$ and $\bar\Delta$ only (not $\Delta_{\text{always}}$).

## Key facts established

- OLS tables are complete `\begin{table}` fragments; their caption/notes come from the `.do` files.
  So OLS note edits happen in the `.do`.
- GRC tables are bare `tabular` fragments; captions/notes live in the paper sections.
  So GRC note/column-reference edits happen in the paper (deferred to the user in Overleaf).
- The inversion (weak-ID-robust) CI values are already attached to the sters by `5b_inversion.do`
  (`attach_inversion_ci`) and persisted (`5b` skip-guard reads `e(inv_phi_ci95_lo)` off the parent
  ster). `grc_tex_table_trend` already emits `95\% inv. CI` rows for never/avg/always/phi from those
  sters (see `temp-tables/GRC_IDN_consumption_urban_unb.tex`). So table regeneration surfaces the CIs
  with no GMM re-run.
- Current canonical `tables/GRC_*.tex` are stale (old format: no CI rows, no always). Regeneration
  promotes the new format.

## Edits

### 0_programs.do
- `reghdfe_regressions` (L1184-1205): remove `reg1` (noabsorb, no covariates); renumber
  `reg2->reg1 ... reg7->reg6`. The full-FE spec (old `reg7`) still runs first to set
  `regression_sample`; only its stored name changes to `reg6`. Result: OLS becomes 6 columns.
- `grc_tex_table_trend`:
  - default `covs2set` `"c0 ct c1 c2 ca"` -> `"ct c1 c2 ca"` (drops `c0`; GRC becomes 4 columns).
  - gate the `$\Delta_{\text{always}}$` esttab block (L3182-3197) behind an option (default off) so the
    main tables show never + avg only. Temporary appendix preview keeps always via its static
    temp-tables (not regenerated).

### 3_OLS_uGRC.do  (4 tables)
- `columns(7)` -> `columns(6)` (4 sites).
- postfoot: reorder Time FE above Covariates, drop the col-1 empty cell:
  `Time FE & Y & Y & Y & Y & Y & Y \\ Covariates & & Female & \& Age$^2$ & All & All & All \\`
  `Individual FE & & & & & & Y \\ Migrants only & & & & & Y & \\`
- master enumerated note (L84): renumber to 6 columns.

### 6_OLS_uGRC_hukou.do  (12 tables)
- Same `columns(6)`, postfoot reorder, and enumerated-note renumbering as 3_OLS_uGRC.do.

### 10_make_tables.do
- `columns(5)` -> `columns(4)` at all GRC `grc_tex_table_trend` sites (~22).
- 3 GRC postfoot strings (L39, L236, L286): 5-col -> 4-col (drop the c0 empty cell). Already Time-FE-first.
- het tables at the bottom untouched.

### Estimation code (comment out, do not delete; do NOT run now)
- Comment out the `c0` `run_grc` blocks in `4_GrRC.do`, `5_GrRC_NonAg.do`, `7_GrRC_hukou.do`.
  Reason: c0 often fails to converge and estimating it wastes GRC time. Existing c0 sters stay on
  disk (harmless, unused).

## Regeneration (tables only)
- GRC: run `10_make_tables.do` — reads existing sters, no GMM. Fast.
- OLS: run `3_OLS_uGRC.do` + `6_OLS_uGRC_hukou.do` — re-runs the fast OLS/FE `reghdfe` regressions
  (not GRC; seconds-to-minutes). Required because dropping `reg1` changes what is estimated.
- Both write to `RP7/output/tables/` and copy to Overleaf `tables/` via `copyOverleaf`.
- Driver: minimal harness that runs section 0 of `0_master.do` (globals + program includes) then the
  three do-files. Ask before running (Stata run + Overleaf write).

## Verification
- Inspect regenerated tables: 6 OLS columns / 4 GRC columns, Time FE above Covariates (OLS),
  never+avg CI rows present, no always block, footers correct.
- Report inversion-CI coverage (cells where CI attached vs empty).

## Deferred (paper-side, user does in Overleaf)
- GRC table captions/notes in `sections/sec_results.tex`: column-number references, and a note that
  the tables now carry weak-ID-robust CIs.
- `app_inversion_preview.tex` references "column (1)"; appendix is temporary.
- Section prose column references throughout (user: "leave for later").

## Open decisions (confirm before implementing)
1. Gate $\Delta_{\text{always}}$ via a program option (recommended) vs hard-remove.
2. Keep the existing row label `95\% inv. CI` (recommended; matches paper) vs relabel to
   "weak-identification-robust".
3. OK to re-run the fast OLS/FE regressions as part of regeneration (GRC is not re-run).
4. Apply CI rows to ALL GRC text tables incl. the 12 hukou cells (user said "all").
5. Flag paper-side notes for you to edit in Overleaf (defer) rather than editing sections now.
