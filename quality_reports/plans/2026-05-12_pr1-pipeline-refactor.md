# PR-1 draft: GRC pipeline refactor + rescaler cleanup

Date: 2026-05-12
Branch: `worktree-grc-pipeline-refactor` → `main`
Status: draft (pending refit completion + rescaler-deletion commit)

This file holds the PR description so it survives across sessions.
Edit before opening the PR; copy the rendered version into the GitHub PR
body via `gh pr create --body-file ...`.

---

## Title (suggested)

GRC pipeline refactor: 22→13 do-files, resume entry point, slice drivers, Delta_avg fix

## Summary

Refactor of the GRC estimation pipeline to (i) reduce duplication, (ii) make
the pipeline cheap to resume on interrupt, (iii) enable OS-level parallel
execution of independent slices, and (iv) make the pipeline coauthor-friendly
by gating Python dependencies behind a default-off switch.
Also includes the `Delta_avg` formula fix and the deletion of the sidecar
rescaler that the fix obviates.

No new estimands, no removed estimands. Sample construction, identification,
and model specification are unchanged. The only numeric movement vs. pre-PR
state is the `Delta_avg` correction (`b_correct = b_buggy / switcher_frac`),
which applies to the 110 cells from `4_GrRC.do` / `5_GrRC_NonAg.do` /
`7_GrRC_hukou.do`. The correction was previously surfaced via a sidecar
overlay in the dashboard; now it lives directly in `0_programs.do` and
the overlay is removed.

## What changes

### Pipeline structure

- Consolidate 22 do-files into 13 by extracting per-stem logic into
  `0_programs.do` programs.
  Key new program: `run_grc_with_extra_regressor` (one call per
  country × spec3 × extra-regressor stem, replaces the deleted files
  `10_*.do` -- `15_*.do`).
- New entry point: `run_master_resume.do`.
  One-line wrapper that sets `${skip_if_exists}=1` then calls
  `0_master.do`.
  Enables cheap restart after interrupt.
- New parallel-execution shape: three family slice drivers
  (`run_extras_maxexpsh.do`, `run_extras_birth.do`, `run_extras_cnu.do`)
  that walk a single family of `9_GRC_extras.do` cells.
  Safe to launch concurrently with `0_master.do` and with each other:
  the filesystem (`_g$vsfx.ster` existence) coordinates which cells
  still need fitting.
- New shared include: `0_slice_bootstrap.do`.
  Carries path_config include, programs include (quietly), skip flag,
  copyOverleaf=0.
  Slice drivers call it after their inline `$dir` block.

### Coauthor friction reductions

- New global: `$runDashboard` (default 0).
  Gates the two `shell python` calls in the pipeline
  (`scrape_headlines.py` cache refresh at the tail of `0_master.do`;
  `gen_verdier_comparison.py` review-memo generator at the tail of
  `17_verdier_robust.do`).
  Coauthors without Python installed no longer hit shell errors.
  Neither Python call produces paper artifacts ---
  `.tex` tables and figures are produced before the Python calls fire.

### Estimation correctness

- `Delta_avg` formula fix in `0_programs.do` (commit `82766d2`).
  The buggy formula computed
  `Delta_avg_buggy = switcher_frac × E[Delta | switcher]`;
  the corrected formula computes
  `Delta_avg_correct = E[Delta | switcher]`.
  Affects the 110 cells from `4_GrRC.do`, `5_GrRC_NonAg.do`,
  `7_GrRC_hukou.do`.
  The same fix was previously cherry-picked to `main` (commit
  `a2f8312`) and `lca-inversion` (commit `3de8a76`) to propagate the
  correction; this PR makes those cherry-picks redundant on `main`.
- Re-fit the 110 affected cells with the corrected formula.
  Verified post-refit: on-disk `Delta_avg` for sample cell
  `grc_IDN_cuu_c0` matches the analytical rescaling
  (`b_disk = 0.3810670249710334` vs sidecar `b_rescaled =
  0.3810670249710419`; difference at machine epsilon).

### Removals (rescaler infra)

- Remove `RP7/scripts/fix_delta_avg_scaling.do`
  (113-line analytical rescaler that wrote the sidecar CSV).
- Remove `RP7/output/delta_avg_rescaled.csv`
  (sidecar CSV with 110 (b_buggy, b_rescaled) pairs).
- Remove `_load_rescaled` / `_cached_rescaled` / `DELTA_RESCALED_CSV` and
  the substitution block in `tools/results_overview/compare.py`.
  After refit, on-disk values no longer match `b_buggy`, so the overlay
  is dead code anyway.

## Test plan

- [x] Smoke test on `run_extras_birth.do`: 16/16 cells skipped under
  `skip_if_exists=1`, clean rc=0.
- [x] Spot-check on `grc_IDN_cuu_c0` post-refit: on-disk Delta_avg matches
  the previously-rescaled value to machine epsilon.
- [x] Full refit of 110 affected cells completes cleanly
  (2026-05-12 13:10 -- 2026-05-13 01:38, 12h28m wall, 108 fits, rc=0).
- [x] Post-refit: scraped headlines cache (110 rows refreshed),
  re-rendered dashboard, verified on-disk Delta_avg matches
  `b_rescaled` across CHN/IDN/TZA samples to machine epsilon:
  - `grc_IDN_cuu_c0`: 0.3810670249710334 vs 0.3810670249710419 (Δ = 8.5e-15)
  - `grc_CHN_cuu_c0`: 0.4717084505520197 vs 0.4717084505520192 (Δ = 5e-16)
  - `grc_TZA_cuu_c0`: 0.0556964918815639 vs 0.0556964918815645 (Δ = 6e-16)

## Risks

- Numeric: paper tables and figures that report `Delta_avg` will move
  by a factor of approximately `1 / switcher_frac` (typically 9× to
  14×) vs. any draft fitted before 2026-05-08.
  This is the correction, not a regression.
- Coverage: no cells added or removed.
- Reproducibility: the formula change is documented in the commit log
  (`82766d2`).
  Anyone running `do 0_master.do` on a clean checkout post-merge gets
  correct values directly; no sidecar required.

## Pre-merge checklist

- [x] All 110 cells refit and verified.
- [x] Rescaler deletion committed (e37bc13).
- [x] Verdier early-exit removed (rolled into e37bc13).
- [x] Headlines cache refreshed (110 rows; commit 13b2905).
- [x] Dashboard re-rendered against corrected values (report.html, 2.6 MB).
- [x] `RP7/output/_pre_fix_backup_82766d2/` deleted (550 ster files, 17 MB).
- [ ] Push branch and open PR with this body.

## Out of scope (left for follow-on PRs)

- Headlines cache infrastructure and dashboard tooling (PR-2).
- Verdier-related work (separate branches: `worktree-vanilla-vv`,
  `worktree-verdier-modification`).
- `find-do-file-directory` as a public Stata utility (worth flagging
  on SSC eventually but not part of this work).
