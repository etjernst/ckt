# Session log 2026-07-22: definitive run status and 5b deferral

## If you resume

Read this file fully, then read [2026-07-21_stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-21_stage9-switcher-inclusion.md) for the launch, the income-cell crash, and the README narrative; this file does not repeat that content.
The definitive end-of-stages run (one serial `0_master.do` batch from raw data through final tables, plan at [2026-07-21-definitive-run.md](file:///C:/git/ckt/quality_reports/plans/2026-07-21-definitive-run.md)) was launched 2026-07-21 22:33, PID 28684, and is likely still running or just finished.
Check for [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt) (present means Stata exited) and the tail of [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log).
If finished, start the post-run sequence: log sanity sweep first, noting the EXPECTED `5b_inversion.do` `r(460)` failure and its story below, then the Python keep-list agreement smoke, the `12_counterfactuals` baseline-drift adjudication, and the movement summary for the author.
If still running, leave it alone.
Known-expected state: main-line inversion CIs are absent from all 12 of 12 cells (IDN, CHN, TZA times ct, c1, c2, ca) by deliberate author deferral, since the simulation branch showed the inversion CI computation needs adjustment before `5b` is worth re-running.
The `covs_0` fossil `.ster` files that killed `5b` overnight are deleted from `RP7/output`; they remain in the backup `output_prestage9_2026-07-21`.
Backups `output_prestage9_2026-07-21` and `processed_prestage9_2026-07-21` still stand.
`copyOverleaf=0`, so nothing ships to Overleaf or Dropbox without author review.
The working tree is clean at commit `55f6fca` except pre-existing untracked files (RP7 test fixtures, extraction outputs, paper build artifacts already listed in git status).

---

## Context

Continuation of the definitive run tracked in [2026-07-21_stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-21_stage9-switcher-inclusion.md).
That log covers the 22:11 launch, its crash on an all-thin keep-list income cell, the author's decision to drop income entirely, the keep-list hardening fix (commit `b08d369`), the 22:33 relaunch (PID 28684), the README draft (commit `fbc8e2b`), and the README verification fixes (commit `55f6fca`).
This log covers only what happened today, 2026-07-22, while that run kept going in the background.

## Morning status check

About 11 hours into the run, Stata was alive, scripts 1 through 8 had completed, and the batch was deep into `9_GRC_extras.do`, the long pole of the pipeline.
At that point there were 370 fresh `.ster` files and 84 extras-family `.ster` files, with the birth-cohort family not yet started.
By 13:12 the run was still inside the extras family, on the IDN cub-experience cell.

## The 5b_inversion.do overnight casualty

`5b_inversion.do` aborted on its first cell overnight and attached inversion confidence intervals to zero of the 12 main-line cells (IDN, CHN, TZA times ct, c1, c2, ca).
The mechanism, confirmed by a direct read of [5b_inversion.do](file:///C:/git/ckt/RP7/scripts/5b_inversion.do) lines 115-145 and the master log, is a chain of three individually reasonable design choices interacting badly.
First, the loop's spec list still includes `covs_0`, the no-covariate column decommissioned on 2026-07-01, and its skip logic is keyed on file existence: a `capture confirm file` that skips the cell only when no parent `.ster` is present.
Second, a stale `grc_IDN_cuu_c0.ster` fossil from a months-old run was still sitting in `RP7/output`, because the run writes in place rather than into a fresh directory.
Third, the fossil passed the existence check, carried no `_esample` marker (only fresh fits write one), and the reconstruction fallback found 92,449 rows against the fossil's `e(N)=92,450`.
That one-row gap is the Stage 4 recomputed-singleton drop, so the row-count check worked exactly as designed and correctly flagged a mismatch.
`attach_inversion_ci` hard-stopped with `r(460)`, and because that attach call is deliberately uncaptured, on the loud-failure convention used for real cells, the error escaped the loop and killed the rest of `5b`.
The master script's script-level capture logged the failure and moved on, so every stage after `5b` in the running batch is unaffected and healthy.
The GMM fits themselves are untouched by this: `5b` only attaches confidence intervals to already-fit results, so it is decoupled by design and re-runnable in minutes once its inputs are right.

`5c_inversion_hukou.do` was clean by contrast.
Its `covs_0` fossils do not exist, so the same existence-keyed SKIP branch fired correctly, and all rf/uf cells attached 4 of 4 sters.

## Decisions, with the why

Delete the `covs_0` fossil sters rather than guard `5b`'s loop: the fossils are relics nothing regenerates or reads, since `10_make_tables` uses only `ct`, `c1`, `c2`, `ca`, deletion restores the existing skip logic to correctness, and the backup `output_prestage9_2026-07-21` preserves the deleted files.
Done: ten `grc_*_c0*.ster` files removed from `RP7/output`; the `vv_` `covs_0` family was never present, and `17_verdier_robust` refits that family from scratch anyway, so there was nothing to clean there.
Defer the `5b` re-run rather than patch and re-run now: the simulation branch (`worktree-extension-sims`) has shown the inversion CI computation needs adjustment, so re-attaching current-method CIs now would be double work.
Accepted consequence: the tables `10_make_tables` builds in this run will lack main-line inversion CIs, and will need regenerating once the eventual `5b` re-run is done.
No pipeline-script edits while the run is live: the `0_master.do` "44 stems" comment and the `9_GRC_extras.do` header are known-stale but parked, because editing a file a running batch may still read risks corrupting the definitive run.
The one code edit made mid-run was `run_master_resume.do`'s active `$dir` line, repointed from the stale grc-pipeline-refactor worktree to `C:/git/ckt/RP7`: the running batch never reads that file, and a crash-resume is exactly the moment the stale path would bite.
Root-cause framing recorded for the `5b` failure, for the post-run cleanup pass: three individually sensible choices combined into a bad interaction (existence-keyed skip, a deliberately uncaptured attach call, and an in-place output directory that can carry fossils across runs).
Two hardening candidates are parked for after the run: trim `covs_0` from `5b`'s spec list, and start definitive runs against a clean output directory.

## Rejected approaches

Re-running `5b` concurrently with the still-live master, on the grounds that the two touch disjoint files: proposed as safe, but mooted once the author decided to defer the `5b` re-run entirely until the sims-branch CI adjustment lands.

## Open items

The definitive run is in flight; after `9_GRC_extras` finishes, the remaining stages are `10_make_tables`, `11_make_figures`, `17_verdier_robust`, `17b_cluster_summary`, and the `11b` support figure.
Monitor [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log) and the sentinel [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt), written by `RP7/tests/run_definitive.cmd` when Stata exits; no completion notification fires on its own.
The `5b` re-run stays deferred until the simulation-branch inversion-CI adjustment is built; because the fossils are gone, `covs_0` will SKIP cleanly next time, and once the re-run happens, `10_make_tables` (and `11_make_figures` if it depends on CI values) need to regenerate so the tables carry confidence intervals.
The post-run sequence is otherwise unchanged from the prior plan: a master-log sanity sweep, the Python keep-list agreement smoke ([run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py)), `12_counterfactuals` with baseline-drift adjudication, a movement summary for the author, and a purge of remaining stale artifacts in `RP7/output` (income-era sters and tables nothing regenerates), before the author-gated Overleaf and Dropbox shipping steps.
Post-run code cleanups parked in the README verify report ([2026-07-21_2310_readme.md](file:///C:/git/ckt/quality_reports/verify-snippet/2026-07-21_2310_readme.md)): the `0_master.do` line 131 comment (44 to 31 stems), the `9_GRC_extras.do` header (44 stems, 220 sters), per-script version-17 declarations pending an author decision, the per-user `$dir` block collapse before the ReplicationPackage7 handoff, `$runDashboard`'s external-path dependency, `lca_inversion_ci.ado` as a deletion candidate, and the `5b` `covs_0` spec-list trim.
README FILL-IN placeholders still await the author: data rights, storage and hardware, the table-to-manuscript mapping, and the shipped Python module location, plus an optional CFPS codebook confirmation that `hukou==1` means rural.
D-4 (the nonag manuscript promise) and the `main-updated.tex` "lack complete trajectories" footnote remain open, unchanged from the prior log.
The simulation rebuild and P2 parity certification remain a follow-on after this run completes.
