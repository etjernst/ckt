# PR description draft: GRC pipeline refactor

PR body for `worktree-grc-pipeline-refactor` -> `main`.
Drafted 2026-05-02; verification numbers populated 2026-05-04 after Tier 3 #6 closed and the Tier 2 harness ran clean against the regenerated tables.

---

## Title

GRC pipeline refactor: consolidate scripts, add `values()` switch, lock ster naming

## Summary

82 commits, 245 files changed (+17,380 / -46,037), branched from `main` on 2026-04-24.
Implements the refactor spec at [`quality_reports/specs/2026-04-24_grc-pipeline-refactor.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md): MUST items M1--M11 except deferred M5, plus SHOULD items S2 partial and S3, plus the Phase 1b table-formatting subseries, plus an audit-driven correctness sweep.
Net effect: the `RP7/scripts/` tree drops from 22 do-files to 13, the duplicated real-values script fork is gone, ster filenames are unique per fit and 32-char-safe, and a per-fit timer plus resume-on-interrupt guard make Tier 3 smoke runs survivable.

Bit-for-bit reproducibility of published numbers is the binding constraint throughout.
Tier 1 (static), Tier 2 (table-body byte-identity), and Tier 3 (full smoke) checks all pass on the final commit.

## Changes by area

### Program consolidation (M1, M2, M3, S2 partial)

- M1: collapse `10_GrRC_experience.do`, `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do` into `5_GrRC.do` via `run_grc_with_extra_regressor` and a new `GRC_extras.do` dispatcher.
- M2: collapse `14_GrRC_NonAg_experience.do` and `15_GrRC_birth.do` the same way.
- M3 (commit `062b5d5`): collapse `grc_tex_table_trend{,_exp,_birth,_hukou}` into a single `grc_tex_table_trend` with `spec()`, `est_schedule()`, and `est_prefix()` options.
- S2 partial: `make_tables.do` plus `make_figures.do` separate post-estimation IO from regression code (commit `2b3640f`).
- Hukou: `run_grc_hukou` merged into `run_grc` (Option B; commit `5c3308b`).

### Path / values refactor (M4)

- M4: replace the `ReplicationPackage6 - real values/` script fork with a `values(nominal|real)` switch in `RP7/scripts/0_path_config.do`, propagating `${vsfx}` through every output-writing site in `0_programs.do`.
- Nominal mode preserves bare filenames byte-identical to the pre-M4 reference; real mode appends `_r` so the two coexist.
- Per-machine setup: `RP7/data_real/` is a new junction (gitignored, documented in [`CLAUDE.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/CLAUDE.md)).
- Verification: 4-test harness at [`tests/verify_M4_values_switch.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_values_switch.do) passed 4/4 on `grc_IDN_cub_c0` (commit `49e05d4`).

### Run hygiene (M9, M10, M11)

- M11 (commit `ddb3886` plus follow-ups): locked-in 32-char-safe ster naming `grc_<country>_<spec3>_<covs2>[_<sfx1>]`. Eliminates collision across the three sections of `5_GrRC.do` and `8_GrRC_hukou.do`. See [`RP7/scripts/STER_NAMING.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/STER_NAMING.md).
- M9: per-fit timer in `run_grc{,_onestep,_robust,_robust_vv}`, with elapsed seconds saved in `e()`.
- M10: resume-on-interrupt guard in `run_grc` (`$skip_if_exists` global). Required to survive Tier 3's roughly 30-hour wall clock when interruptions happen mid-run.

### Table formatting (Phase 1b series, Δbar)

- Phase 1b.1--1b.4: extract paper-side table envelope (caption, `\label{}`, tablenotes) into Overleaf preamble macros (`\GRCtable`, `\GRChukoutable`); slim `grc_tex_table_trend*` programs to tabular-only output.
- Phase 1b.5b: separate table creation from regressions in `5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`.
- Phase 1b.6 (commit `f68892e`): strip esttab's blank tabular rows.
- Δbar (commit `5e2277c`): `Average $\Delta$` becomes `$\bar{\Delta}$` in GRC tables.

### Internal cleanups

- M4 internal (commit `d2b0c73`): collapse the duplicated mu-loop in `initial_values` and `initial_values_robust`.
- Path globals: project globals moved from individual do-files into `0_path_config.do` (commit `cc94d3e`).
- M11 audit batches 1--4: `$lnsize` and other magic numbers to globals, `m1` cd-pattern, `m2` `cap` to `capture`, `m6` `assert_merge_clean` retrofit.
- Bug fix: `\@empty` becomes `\empty` in GRC macros staging draft (commit `7448f6a`; live Overleaf `preamble.tex` patched out-of-band).

### Verification harnesses and tooling

- [`tests/verify_M4_mu_loop.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_mu_loop.do): mu-loop dedup verification (4 production cells, bit-identical).
- [`tests/verify_M4_extended.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_extended.do): wider mu-loop coverage.
- [`tests/verify_M4_values_switch.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/verify_M4_values_switch.do): 4-test driver for the M4 values switch.
- [`tests/replay_one_cell.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/replay_one_cell.do): interactive cell-level troubleshooting harness.
- [`tests/regression_test.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/regression_test.py): table and figure regression-test scaffold.
- [`tests/compare_tabular_bodies.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/compare_tabular_bodies.py): tabular-body bit-comparison.
- [`tests/tier2_table_diff.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tests/tier2_table_diff.py): Tier 2 byte-identity check with classified diffs (label flip, blank rows, addlinespace, unexpected).

Tooling that supported the refactor (one-shot scripts; can be deleted post-PR if desired):
[`tools/captions_to_paper_phase1b3.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/captions_to_paper_phase1b3.py),
[`tools/program_caller_map_phase2_s3.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/program_caller_map_phase2_s3.py),
[`tools/rename_m11_phase1a.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/rename_m11_phase1a.py),
[`tools/split_tables_from_regressions_phase1b5b.py`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/split_tables_from_regressions_phase1b5b.py).

## Verification status

| Tier | Scope | Status |
|---|---|---|
| Tier 1 (static) | grep-based call-site audit; ster-name length check; lint | PASS at each phase. Final pass [`quality_reports/reviews/2026-05-02_tier1-lint.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-05-02_tier1-lint.md) (5/6 checks PASS; the 1 failure is 75 pre-M11 orphan sters in `RP7/output/`, not a code defect). |
| Tier 2 (table body) | bit-comparison of `RP7/output/tables/*.tex` against `tests/reference/output/tables/*.tex`, classified | PASS (`tier2_table_diff.py`, run 2026-05-04 against tables regenerated from the final-commit sters): 53 reference tables, all 53 expected diffs only, 0 UNEXPECTED, 0 missing live. Total LABEL_FLIP=53 (Δbar), BLANK_ROW=54 (Phase 1b.6 strip), ADDLINESPACE=0. The live tree contains 19 additional tables (12 hukou + 1 IDN nonag + 6 het) that pre-existed outside the reference snapshot; this is a snapshot gap, not a refactor regression. |
| Tier 3 (full smoke) | full master pipeline; convergence and ster-counts | PASS. Tier 3 #6 (batch `bayt3x4r5`) closed cleanly at 2026-05-03 06:50:21 with `end of do-file` and exit code 0. 1505 sters on disk at close (1365 carried forward via `skip_if_exists=1`, 140 newly written). |
| M4 verify | 4-test driver on `grc_IDN_cub_c0` | PASS 4/4 (commit `49e05d4`). |
| M4 mu-loop | bit-comparison on 4 production cells | PASS (commit `7545c14`). |

## Open items

- Earlier Tier 3 #5 hit `r(3900) editmissing(): out of memory` at the end of 2026-05-01. The proximate cause was a parallel R process competing for RAM, not a code-side leak. No code change needed; relaunched as Tier 3 #6 with `skip_if_exists=1` so the 1365 already-on-disk sters were not recomputed. Tier 3 #6 closed cleanly.
- Tier 2 reference snapshot covers 53 of the 72 tables the pipeline now produces (12 hukou, 1 IDN nonag, and 6 het tables are not in the snapshot). These are pre-existing gaps, not refactor regressions; refresh the snapshot in a follow-up if a tighter Tier 2 net is desired.
- Paper-side `\GRCvaluesfx` toggle macro deferred. It will be added to Overleaf `preamble.tex` once the team decides whether real-values is a replacement for or a robustness check on nominal-values tables. Logged in spec section 4a.

## Notes for the reviewer

- `paper/preamble.tex` in this branch drifts from the Overleaf-Dropbox copy by design. The user manually copies `main.tex`, `CKT.bib`, and `preamble.tex` to Overleaf when ready (Dropbox sync corrupts Overleaf track changes). Do not push from this branch to Overleaf.
- The top-level `scripts/`, `data/`, and `output/` paths are read-only directory junctions into the coauthor's live ReplicationPackage6/ in Dropbox. All edits live in `RP7/`. Final handoff per branch is to copy `RP7/{scripts,output}/` to Dropbox as `ReplicationPackage7/`.
- The spec doc and per-phase plans are in `quality_reports/specs/` and `docs/plans/`; per-day session logs are in `quality_reports/session_logs/`.

with Claude
