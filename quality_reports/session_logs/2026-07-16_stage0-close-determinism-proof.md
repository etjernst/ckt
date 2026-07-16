# 2026-07-16 --- Stage 0 close: determinism proof and hand-off to Stage 1

## If you resume

- One-line state: STAGE 0 IS CLOSED; the gate-panel baseline is frozen (250 sters, all 50 fit families, both drivers rc=0) and the determinism proof passed (hukou-leg double-fit, all 30 ster pairs PASS_BITWISE against the baseline); the next work is Stage 1 in fresh context.

- Read first: this log, then the plan [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) (Stage 1 section and the gate/appendix sections), then the rolling Stage 0 log [2026-07-14_pipeline-consistency-audit-and-refactor-plan.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-14_pipeline-consistency-audit-and-refactor-plan.md) for the full Stage 0 history.

- Next concrete action, Stage 1 (single source of truth for the covariate ladder, consistency, Tier 2): write a `set_covariate_globals` program (country-arg for hukou) defining `$covs_gmm*` in one place, and delete the hand-redeclaration lines in `4_GrRC.do`, `5_GrRC_NonAg.do`, and `7_GrRC_hukou.do` (the 2026-07-14 audit counted 48 such lines) plus the parallel locals in `run_grc_with_extra_regressor`.
  Per Mode 2 this needs a spec and plan already approved, and the plan's Stage 1 section is that approved plan; implement it, then refit the gate panel and run `gate_compare` against the frozen baseline, expecting PASS_BITWISE everywhere.

- Gate mechanics for Stage 1: the frozen baseline sters live in [baseline_root/output/](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/output/) (250 sters).
  Refit into a fresh shadow root (copy the baseline_root2 pattern) and compare via `gate_compare, estname(...) refit_ster(...) basedir("C:/git/ckt/RP7/tests/stage0/baseline_root/output")` from [gate_harness.do](file:///C:/git/ckt/RP7/tests/stage0/gate_harness.do); the drivers to rerun per leg are [gate_baseline.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline.do) and [gate_baseline_ct.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline_ct.do), both of which carry `global skip_if_exists 1`, so point them at an empty output directory or delete the target sters to force refits.

- Launch discipline: multi-hour Stata batches launch detached via PowerShell Start-Process, never as tracked background Bash tasks, since the harness reaps tracked tasks roughly 30 minutes after session idle (see the memory note `reference_detached_stata_batches.md`).
  Completion is polled via rc files or a Monitor watcher on the rc file, not via a completion notification.

- Cached state: the canonical processed-data hub is [RP7/data/processed](file:///C:/git/ckt/RP7/data/processed/), rebuilt 2026-07-14 with the per-capita outcome, Change A, and C10.
  The stale backup sits at `RP7/data/processed_stale_2026-07-14/`.
  The shadow roots `baseline_root` and `baseline_root2` hold `scripts/` and `data/` junctions into the live tree, removable only with `cmd /c rmdir` (never a recursive delete), and both are git-excluded via `.git/info/exclude`.
  The determinism refits (30 sters) live in `baseline_root2/output`.

- Standing reminders: nothing ships to coauthors or Overleaf until the definitive run regenerates all sters and tables.
  At Stage 3 kickoff, remind the author about the MAJOR-4 keep-vs-drop choice; the reminder text sits in the plan's Stage 3 section.
  Stage 4 carries CRITICAL-1, with its predicted diff already enumerated in the plan.
  Stage 6 carries a required fix: stale `_never`/`_avg` ster suffixes in `17_verdier_robust.do`'s tail block silently block regeneration of the paper's Verdier robustness tables, and the production tables (frozen 2026-05-06) predate the current sters.
  D-4 is open: the manuscript prose around line 574 promises a nonag table that no table input currently supplies, and the choice is between dropping the promise from the paper and restoring an appendix table, with the author leaning toward low priority on nonag.
  The `5b_inversion` baseline stays deferred to Stage 5, because its Python path resolves relative to `$dir` and breaks under shadow roots.

- Everything from this session is committed: `612ba2f` (baseline drivers and slices), `0d559ed` (determinism proof), `bc24ade` (the Stage 6 required fix written into the plan), and `f109255` (D-4 opened).

---

## Goals

The 2026-07-16 session picked up after an overnight laptop restart, with three asks from the user.

Check whether the detached baseline runs survived the restart.

Explain, then justify, the claimed harmlessness of the Verdier tail failure flagged in the prior session.

Close Stage 0 by completing the determinism double-fit, then wrap up for a fresh-context Stage 1.

## What got built or changed

- Post-restart verification: both rc files read rc=0.
  The baseline had finished at 01:27, ten hours before the 11:20 reboot, and produced 250 sters.
  The `_g` roster confirms all 50 expected fit families: 18 main, 3 nonag, 6 hukou, 4 extras, 10 VV-TZA, and 9 ct.

- [gate_baseline.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline.do) and [gate_baseline_ct.do](file:///C:/git/ckt/RP7/tests/stage0/gate_baseline_ct.do) both gained `global skip_if_exists 1`.
  The guard was verified live: a no-op rerun of the ct driver skipped all 9 fits, logging "run_grc: SKIP ... _g.ster present" for each.
  Committed as `612ba2f`, together with all five slice files.

- Determinism proof: [gate_determinism.do](file:///C:/git/ckt/RP7/tests/stage0/gate_determinism.do) refit the hukou leg (6 fits, 19 minutes) into a new shadow root, `baseline_root2`.
  That shadow root uses the same junction pattern as `baseline_root` (junctions into the live tree, git-excluded), and its README warns about junction removal.
  [gate_determinism_compare.do](file:///C:/git/ckt/RP7/tests/stage0/gate_determinism_compare.do) then compared all 30 ster pairs (2 cells x 3 specs x 5 files): every pair came back PASS_BITWISE, N matched exactly, and max_crit_ratio was 0.
  The verdict CSV sits at [determinism_results.csv](file:///C:/git/ckt/quality_reports/staging/stage0/determinism_results.csv); committed as `0d559ed`.

- Plan updates: Stage 6 gained the required Verdier-table fix (`bc24ade`), and D-4 (nonag) opened the night before (`f109255`).

- A Monitor watcher, polling the rc file with a process-death branch, replaced background-Bash waiting for the detached refit, per the idle-reap lesson from the prior incident.

## Decisions, with the why

The Verdier tail finding moved from "harmless" to a required Stage 6 fix after the user challenged the claim.
Verification showed the tail's `eststo` loads feed `grc_tex_table_trend_robust`, which generates the paper's verdier_robust tables, and the production tables (2026-05-06) predate the production sters (2026-07-01) by two months.
That gap proves no run since the `_never`/`_avg` to `_n`/`_a` suffix rename has regenerated the tables.
The failure is silent: a captured load error, followed by a skip-and-warn inside the table program.

The hukou leg was chosen for the determinism double-fit because it is the fastest complete leg and covers two cells across three specs, exceeding the plan's requirement of at least two cells.

The double-fit ran into a second shadow root, `baseline_root2`, rather than the frozen `baseline_root`, because the refits share estnames with the frozen baseline and would have overwritten it.

Nonag stayed in the baseline despite the user's stated indifference toward it.
Its 3 fits are cheap, the manuscript question (D-4) is separable from the baseline, and cutting cells mid-baseline would have reopened the panel definition.

The baseline hukou-leg log was renamed to `gate_panel_hukou_baseline.log` before the double-fit, because the refit writes a log of the same name through the shared junction.

## Approaches rejected and the reason

Waiting on the detached refit with a background Bash until-loop was rejected, because tracked background tasks are reaped roughly 30 minutes after session idle, as the 2026-07-15 01:26 incident showed; a persistent Monitor watcher replaced it.

Committing the 60 full-precision b/V dump files was skipped, since they are bulk evidence that regenerates on demand; the verdict CSV and the drivers already carry the proof.

## Open items

Stage 1 is next, in fresh context per the user's instruction, and runs against the frozen baseline.

D-4 (whether to keep the nonag promise in the manuscript) awaits the author.

The Stage 6 required fix and the Stage 3 MAJOR-4 reminder are both recorded in the plan.

The two shadow roots keep their junctions until the refactor ends; remove them only via `cmd /c rmdir`.
