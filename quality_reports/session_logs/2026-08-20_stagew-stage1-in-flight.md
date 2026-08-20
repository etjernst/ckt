# Stage W Stage one in flight on Gadi; Stage 6 closed except author gates

## If you resume

Read [2026-08-19_stage-w-round1-review-and-fixes.md](file:///C:/git/ckt/quality_reports/session_logs/2026-08-19_stage-w-round1-review-and-fixes.md) end to end first (it carries the two external review rounds, the fixes, and all of yesterday's author decisions), then this file.

The open thread is the Stage W Stage one production run: eight PBS jobs on Gadi (176677711 to 176677719, names `sm_f{factor}_r{0|250}`), set metrics for $q \in \{20, 26\}$, coarse lattice, $B = 999$, the frozen 33-offset grid, replications 0 to 499, output `/scratch/dr48/et5292/ckt-sims-r1/sims/results/stagew_prod_setmetric`.
Stage one FAILED on 2026-08-20 evening: the seven running jobs were killed by PBS at the 30 h walltime (Exit Status -29, 22:02 to 22:04 AEST) with no output written, because the driver writes its single per-factor parquet only after all 250 replications finish; the eighth (`sm_f4.0_r250`, 176677719) never started and is on a PBS system hold for insufficient allocation.
The seven kills consumed 6,724 SU; Q3 has 636.60 SU left and the 10 KSU Q4 grant opens 2026-10-01.
Full incident detail, verified facts, and the four options (delete the held job, chunk the driver's write unit, run a small timing probe at production spec, reprice Stage one for Q4) are in [2026-08-20_stagew_stage1_walltime_incident.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-08-20_stagew_stage1_walltime_incident.md).

Emilia approved the timing probe ("ok go", 23:50); it is Gadi job 176849518 (`sm_probe`), submitted 23:52 at the exact production configuration recovered from the held job's `qstat -f` environment: factors 0.5 and 1.0, `JLIST="20 26"`, coarse grid, $B = 999$, the frozen 33 offsets, master seed 20260710, 2 replications per factor on 2 cores and 8 GB, 15 h walltime cap, output to `sims/results/stagew_timing_probe`.
Expected wall time is the sum of the two factors' per-replication times (each factor's 2 replications run in parallel), so roughly 4 to 6 h and 16 to 25 SU; the PBS epilogue gives total SU and the two parquet mtimes give the per-factor split.

Next concrete action: poll `qstat -u et5292` for `sm_probe`; when it finishes, read its `.o` file for walltime and SU, compute per-replication cost per factor, reprice Stage one for the 10 KSU Q4 window, and put the rescoping options to Emilia.
Still open from the incident memo: qdel of held job 176677719 (recommended, cannot start before Q4 opens) and approval of the driver write-unit chunking change before any relaunch.
The summarize-and-memo step from the original plan applies unchanged once a successful run exists.
The pilot batches live in separate directories (`power_setmetric/`, `power_outer/`) and must not be mixed into the production summarize call except as the descriptive `--power-dir` source.

Cached state.
Sims worktree (`C:/git/ckt/.claude/worktrees/extension-sims`, branch `worktree-extension-sims`, HEAD 0c73466): drivers with shared sign matrix and config-hashed manifests, summarizer with lattice-only topology and the $B = 999$ adoption power source, 75 tests passing; the governing plan is [2026-07-22-unified-run-and-derived-quantity-coverage.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/plans/2026-07-22-unified-run-and-derived-quantity-coverage.md) with two dated revision sections at the end and the frozen offset grid.
Stage two (Q4, October allocation): if $q = 20$ passes, paired full-grid confirmation of 20 against 26 (about 6,500 SU); if it fails, stay at 26 or run $q = 14$ (about 3,300 SU), the choice recorded before results are opened; descriptive $B = 399$ power curves for all five $q$ when the balance allows.
Q3 balance after the failed Stage one: 636.60 SU (verified via nci_account 2026-08-20).

Stage 6 is closed except author items: the movement memo is [2026-08-19-stage6-movement-memo.md](file:///C:/git/ckt/quality_reports/reviews/2026-08-19-stage6-movement-memo.md); decided already are the 90 percent CI row (memory `project_phi_ci_90pct`), variant B (memory `project_e1_variant_b`), and the Overleaf note edits (applied directly to `preamble.tex` and `main-updated.tex`, compiled clean, five tables plus `counterfactual_misallocation.tex` and `hukou_bound.tex` copied over).
Still open for Emilia: presentation of the six CHN and CHN_rf cells open above the widened grid (lean: report as open, stop widening) and of the IDN ca five-island 95 percent set (moot in the tables now that only the 90 percent row prints, but live for any appendix that shows 95 percent); the always-urban caveat paragraph rewrite is Todoist task 6hHwvX2w5JM2C58J (due 2026-09-05).
The uncommitted working-tree noise in the main repo is mostly regenerated `RP7/output` figures and stage-test scaffolding predating this session; the counterfactual CSVs and the GRC/counterfactual tables are committed.

---

## 2026-08-20

Morning status check only: seven of the eight Stage one jobs running at 18 h elapsed, one queued, no output batches yet (each job writes its parquet only at factor completion).
No decisions, no file changes beyond this log.
Explained to Emilia that completion is discovered by polling `qstat` at next session start, that a local restart cannot touch the Gadi jobs, and that `/scratch` purges untouched files after 100 days, so results should be fetched within days.

### Evening (23:05 to 23:30)

Emilia relayed PBS abort notifications; investigated directly on Gadi.
All seven running Stage one jobs hit the 30 h walltime and were killed with nothing written (`raw_setmetric/` empty, no `*.tmp.parquet` in either Gadi tree); each job wrapped one factor times 250 replications in a single `Parallel()` call, so no partial batch ever flushed.
The eighth job is held by PBS because dr48 lacks the 960 SU it would reserve (636.60 SU remain in Q3 after the 6,724 SU burn).
The pricing shortfall: the 6,800 SU estimate implied about 3.4 SU per replication against the coarse pilot's measured 8.3 on the five-$J$ spec; the observed lower bound is 3.84 with zero batches complete, and the discount for dropping to $q \in \{20, 26\}$ was evidently too generous since those are the two most expensive $J$ values.
Incident memo with options written to the sims worktree: [2026-08-20_stagew_stage1_walltime_incident.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-08-20_stagew_stage1_walltime_incident.md).
No script changes made (driver chunking needs approval); no jobs deleted.
Emilia asked whether compute is exhausted; answer: Q3 supports only the probe, Q4's 10 KSU likely cannot cover the original Stage one plus Stage two, so October means a rescoped Stage one (for example $R = 250$, a trimmed offset grid, or one fewer factor) or a supplementary-allocation request.
She approved the probe at 23:50; submitted as job 176849518 at 23:52 (details in the resume block above).
