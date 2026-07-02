# Plan: targeted CHN + hukou covariate-sweep re-fit (approved 2026-07-02)

## Goal

Populate the three CHN main-results GRC tables (pooled CHN, hukou rural-first, hukou urban-first; all consumption/urban/unbalanced) in the new 4-column + inversion-CI format.
User approved the re-fit after the RP6 equivalence check rejected reuse of the coauthor fits (see [2026-07-01_rp6-vs-rp7-chn-ster-check.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-01_rp6-vs-rp7-chn-ster-check.md)).

## What is missing on disk

- `grc_CHN_cuu_{ct,c1,c2}` and subgroup sters (only `ca` exists, unattached).
- `grc_CHN_rf_cuu_{ct,c1,c2}` and `grc_CHN_uf_cuu_{ct,c1,c2}` (only `ca` exists, attached).
- Inversion CIs on CHN main `ca` and on all nine new cells.

## Runtime basis (from e(runtime) on existing ca sters)

CHN main 560s/fit, rural-first 426s/fit, urban-first 123s/fit; nine fits total, roughly one hour of GMM, plus the inversion attach.
The earlier "multi-day" estimate was for the full pipeline (IDN fits run ~1h each); it does not apply to this targeted job.

## Driver: `RP7/scripts/_refit_chn_sweep.do`

Phase A (GMM, 9 cells): mirror the `run_grc` call shape of `4_GrRC.do` (CHN section) and `7_GrRC_hukou.do` (rf_cuu, uf_cuu sections) for covs2 in {ct, c1, c2}.
`$skip_if_exists = 1` so an interrupted run resumes at the next missing cell.

Phase B (inversion attach): driver-local loop mirroring `5b_inversion.do` / `5c_inversion_hukou.do` data prep and `attach_inversion_ci` calls, restricted to CHN main + rf + uf over {ct, c1, c2, ca}, skipping cells already attached.
Not routed through 5b/5c themselves because those also attach the unattached IDN/TZA `c0` parents, a column dropped from the tables (wasted compute, especially IDN).

Phase C (tables): regenerate the three tables via `grc_tex_table_trend, invci` with the exact `10_make_tables.do` call shapes; `copyOverleaf 0` (local first, copy after inspection).

## Verify

- Nine new base sters + subgroup sters exist; `e(converged)` = 1 on each.
- `e(inv_phi_ci95_lo)` non-missing on all twelve parents (3 specs x ct/c1/c2/ca).
- Three tables render 4 columns with populated CI rows; sanity-check phi against the ca cells (CHN main ca phi = -0.205).

## Out of scope

Other hukou cells (ro/uo), balanced/income spec3s, IDN/TZA anything, c0 anywhere.
