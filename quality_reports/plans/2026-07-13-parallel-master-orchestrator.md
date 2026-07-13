# Plan: parallel master orchestrator for the definitive re-run

Date: 2026-07-13.
Prior art: [2026-05-09_parallelization-options.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-09_parallelization-options.html) (the extras-family Gantt analysis) and the session log [2026-05-09_pipeline-watch-and-parallelization-plan.md](file:///C:/git/ckt/quality_reports/session_logs/2026-05-09_pipeline-watch-and-parallelization-plan.md).
Goal: cut the wall-clock of the one final full-pipeline re-run without rewriting `0_master.do` and without changing a single estimate.

## Design

Leave `0_master.do` as the canonical serial orchestrator; it stays the reference and the coauthor-facing entry point.
Add a separate launcher beside it that runs the pipeline in three phases: clean once, fan the estimations out across concurrent Stata instances, assemble once.
The lever already exists: `run_grc` (and the other estimators) honor `${skip_if_exists}`, so any instance that finds a target ster on disk skips that cell in seconds, which makes disjoint slices safe and the whole thing idempotent and resumable.
Stata cannot parallelize a single `gmm` fit across cores, so multiple instances on disjoint slices is the only real speedup.

## Phase structure

Phase 1, serial (one instance): `0_CHN_hukou_restrictions.do` then `1_processData.do`.
Everything downstream reads the processed `.dta`, so this must finish first.
Author the Change B switcher keep-list here, once, on the cleaned data, and persist it to disk, so every estimation instance reads the identical keep-list rather than recomputing it (this is the single-source-of-truth from the switcher-inclusion plan, and running it once in Phase 1 removes any cross-instance divergence).

Phase 2, parallel (concurrent instances, each with `global skip_if_exists 1` and its own log path):
- Instance A: `3_OLS_uGRC.do` + `6_OLS_uGRC_hukou.do` (OLS/FE, cheap).
- Instance B: `4_GrRC.do` then `5b_inversion.do` (main GRC, then its inversion which reads `4`'s sters and the keep-list; ordered within one instance).
- Instance C: `5_GrRC_NonAg.do`.
- Instance D: `7_GrRC_hukou.do`.
- Instance E: `8_learning.do`.
- Instance F: `17_verdier_robust.do`.
- Instance L: `2_summaryStats.do` + `1b_unbalanced_rank_diagnostic.do` (cheap diagnostics).
- Instances G..K: `9_GRC_extras.do` sliced by family (experience / max-experience / experience-share / max-experience-share / birth), per the 2026-05-09 slicing, since the extras block is the long pole (~32 h serial on its own).

Phase 3, serial (one instance, after Phase 2 fully drains): `10_make_tables.do` then `11_make_figures.do`, then the optional `12_counterfactuals.do` and dashboard refresh.
These read every ster, so they run last.

## Mechanism and safety

- Each Phase 2 instance is a thin slice driver that sources `0_path_config.do` + `0_programs.do`, sets its own log path, sets `global skip_if_exists 1`, and `include`s only its target script(s).
- Cap concurrency at 6 instances at once (user, 2026-07-13; leaves the machine headroom, six single-core `gmm` fits on a typical 8-16 core laptop).
  The launcher keeps a rolling pool of six: it starts the six longest slices first (the `9_GRC_extras` family slices and Instance B), and launches the next queued slice whenever one finishes.
  `skip_if_exists` makes this scheduler trivial and safe: a slice that is re-entered simply skips the cells already on disk, so the pool can be managed by a simple "keep six running until the queue drains" loop.
- Launch each detached via PowerShell `Start-Process -WindowStyle Hidden`, capturing PIDs.
- Write the whole run to a fresh output directory, leaving the current `RP7/output/` as the canonical set until the new run is verified and promoted; this is also how we avoid deleting the canonical sters (`skip_if_exists` would otherwise refuse to overwrite them).
- No serial master runs alongside the slices, so the 2026-05-09 timing race (a master wandering into a slice another instance is fitting) cannot occur.
- Concurrent writes to the same ster are impossible by construction (disjoint slices), and `estimates save` is atomic (temp + rename) anyway.
- A monitor counts sters landing in the fresh output dir, broken down by script/family, to track progress.

## Expected speedup and floor

The irreducible floor is the single slowest cell (IDN main consumption spec, ~3.5 h on one core); no slicing beats that.
With the layout above the critical path is set by whichever is larger: the slowest `9_GRC_extras` family slice or Instance B (`4_GrRC` + `5b_inversion` on IDN).
The 2026-05-09 analysis put the extras alone at 32 h serial to 8-13 h parallel; the main-path scripts are a smaller add-on that overlap under their own instances, so the full definitive run should land in the high-single-digit hours rather than 30-plus.
At a six-instance cap rather than running all twelve at once, the critical path lengthens somewhat (the twelve slices flow through six lanes instead of twelve), but with the long slices scheduled first it should still land in roughly the low-to-mid teens of hours at worst, floored at ~3.5 h, and the machine stays usable throughout.

## Effort

Small: a handful of ~15-line slice drivers, one PowerShell launcher, one monitor.
The scripting is a couple of hours; the care is in getting the slices disjoint and complete so the definitive run misses nothing.
Two quick pre-reqs from the 2026-05-09 open questions, both settled by a short read: the internal block structure of `9_GRC_extras.do` (so each family slice is a clean `include` target) and each estimation script's per-instance log global.

## Confirmed and out of scope

- Stata-MP license allows concurrent instances (user, 2026-07-13): the hard gate is cleared.
- Thermal throttling: never actually confirmed as a problem; ignore per user.
- A Python port of the estimation is rejected: not faster as-is, and it would fork the pipeline away from Stata-only coauthors and the replication package.
- This is orthogonal to Change A + Change B: it speeds up the run, it does not change any estimate. It must produce results byte-equivalent to a serial run (verify by spot-checking a few cells against a serial fit).

## Sequencing

This lands after the Change A + Change B code is implemented (that is what the definitive run executes), and after the full-pipeline adversarial review clears, so the run we parallelize is the one we actually intend to freeze.
