# 2026-05-06---summclust cache-vs-thermal investigation, dual-J and reversed-J runs

Mode: Implementation, continuing the noise/throttling investigation from [the 2026-05-05 session](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-05_summclust-scaling-and-noise-discovery.md).

## Goal

Yesterday's stability runs showed a sharp step-change pattern: rep 1 cold at ~430 s and reps 2--5 warm at ~1,500 s, with the cold-fast/warm-slow pattern reproducing across two independent runs separated by 3.5 hours of laptop idle.
The working hypothesis was thermal throttling.
The user pushed for a system monitor to test it directly, then for a fresh-context review of the evidence.

Today's work: rule out alternative explanations (memory pressure, pagefile, GUI-related hang, summclust internal state) and decide whether the cause lives in the OS (thermal/scheduler), in summclust, or somewhere else.

## What got built or changed

A PowerShell system monitor (v1) at [`monitor_system.ps1`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/monitor_system.ps1).
Polls every 5 s and records system-wide CPU%, CPU performance counter (% of nominal frequency), memory usage, commit, pagefile, and StataMP-64 process working set / cumulative CPU seconds / thread count.

A v2 monitor at [`monitor_system_v2.ps1`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/monitor_system_v2.ps1).
Adds per-core `% Processor Performance` and `% Processor Time` (pipe-separated columns), and aggregates ALL StataMP-64 processes if multiple are alive (v1 mis-handled this case).

Three new do-files:

- [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do) extended to write `start_clock` and `end_clock` columns into the CSV so monitor traces can be joined per replicate.
- [`stability_test_dual.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual.do) loops 5 reps at J=2000 then 5 reps at J=5000 in one Stata session.
- [`stability_test_dual_reverse.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual_reverse.do) reverses the order: 5 reps at J=5000 first, then 5 reps at J=2000.

A monitor-summary script at [`summarize_monitor_per_rep.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/summarize_monitor_per_rep.py) joins each rep's start_clock/end_clock window with the monitor CSV and emits per-rep stats.

An evidence dossier at [`quality_reports/reviews/2026-05-06_summclust-noise-evidence.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-06_summclust-noise-evidence.md) captures all observations across six sessions (yesterday morning's single rep, yesterday afternoon's noisy run, this evening's runs C and D, the hung run E, tonight's dual-J run F).
The dossier is observation-only; no hypotheses authored by me.

## Run results

Run 3 (with v1 monitor): hung. summclust never produced output. Stata window title read "94% complete" with cumulative CPU frozen at 298.7 s for ~28 min. Killed manually.

Run 4 (dual-J with v1 monitor, completed):

| J | Rep | Wall (s) |
|--:|----:|---------:|
| 2,000 | 1 | 30.2 |
| 2,000 | 2 | 95.3 |
| 2,000 | 3 | 99.1 |
| 2,000 | 4 | 95.0 |
| 2,000 | 5 | 97.7 |
| 5,000 | 1 | 1,310.7 |
| 5,000 | 2 | 2,469.6 |
| 5,000 | 3 | 2,344.0 |
| 5,000 | 4 | 2,325.0 |
| 5,000 | 5 | 2,399.2 |

The within-J step is preserved at J=2000 (3.2x, very tight CV across reps 2--5).
Notably, J=5000 reps 2--5 averaged 2,385 s --- about 1.6x slower than the corresponding ~1,500 s regime in earlier J=5000-only sessions.
J=5000 rep 1 came in at 1,310 s, neither the cold ~430 s baseline nor the warm ~1,500 s seen previously.

All replicates produced bit-identical regression output within their J level (CV3J coefficient $-0.298736$, SE 0.761360 at J=5000; coefficient 0.889897, SE 0.019514 at J=2000). The only thing that varied was wall time.

## Fresh-context review

A general-purpose subagent in fresh context (no prior conversation, only the dossier) returned a memo with several observations I had missed.
Key points:

- Split the puzzle into four phenomena: P1 (J=2000 rep-1-vs-rep-2 step), P2 (J=5000 rep-1-vs-rep-2 step in earlier sessions), P3 (session F's slower J=5000 regime), P4 (the hang). These probably do not share a single cause.
- Leading hypothesis H1: summclust caches state across calls within one Stata session. Predicts P1 and P2 cleanly with matching ratios.
- Killer prediction from H1: session F's "anomalous" J=5000 rep 1 (1,310 s) is consistent with a "warm" call (97 s J=2000 rep 5 multiplied by $J^4$ scaling = 1,516 s), not a cold one. So the J=5000 rep 1 in session F may be confirmation of H1, not a new phenomenon.
- Hypothesis H2 (thermal/freq throttling) is partially supported: cpu_perf_pct drops from ~155% (rep 1) to ~119% (reps 2--5) for J=5000 in session F, with sample mins of 58--63% (below base frequency). But ~25% perf reduction explains only ~33% of the 88% slowdown, so frequency throttling is a contributor not the cause.
- Best next experiment to distinguish H1 from H2: reverse the J order. If H1, J=2000 rep 1 in the reversed run should be ~95 s (warm), not ~30 s (cold). If H2, J=2000 should run at full speed once the long J=5000 phase ends.
- Measurement gaps: per-core CPU performance counters (the v1 `_Total` aggregate hides P/E core scheduling), CPU temperature, Stata thread-to-core affinity. Closed the per-core gap with v2 monitor.

The dossier reviewer also flagged that v1 monitor recorded `stata_pid = System.Object[]` on a few rows when multiple StataMP-64 processes were alive, which v1 mis-handled. v2 fixes this.

## Decisions, with the why

Decision: write the dossier as observation-only, no hypotheses authored by Claude.
Why: the user explicitly asked for the subagent's eyes to be fresh. Pre-loading my thermal-throttling hypothesis would have anchored the review.
Outcome: the reviewer split the puzzle differently than I had and surfaced the H1 cache-state hypothesis I had not considered.

Decision: run the reversed-J experiment with v2 monitor as the next step.
Why: the reordered experiment cleanly separates H1 from H2 with one variable changed (J order); the user's pause-experiment idea would distinguish them too but requires more new code.

Decision: add per-core counters to monitor v2 rather than try to retrofit per-core onto v1.
Why: v1 used `\Processor Information(_Total)\% Processor Performance` which averages over all 22 logical cores. If Stata's one busy thread is bouncing between P-cores and E-cores, v1's aggregate hides it.
The reviewer flagged this as the largest measurement gap.

Decision: kill the v1 monitor by force-stopping all recent powershell processes rather than trying to identify the right PID.
Why: v1's launching mechanism (PowerShell wrapping a script) creates multiple PowerShell PIDs and identifying them precisely was error-prone; the recent-startup time filter was sufficient and the side effect was acceptable.

## Approaches rejected and the reason

Approach: assume thermal throttling and pivot to a different host.
Why dropped: the v2 monitor data showed cpu_perf_pct above 100% throughout most of run 4, and the within-J 3.2x step at J=2000 (rep 1 30s, rep 2 95s) is too sharp to be a thermal effect. Thermal degrades gradually with sustained load.

Approach: pause-between-reps experiment as the next step.
Why dropped (for now): the reordered-J experiment is cleaner because it changes one variable. Pause experiment is a useful follow-up if the reordered run still doesn't separate H1 from H2.

Approach: run R `summclust::vcov_CR3J.fixest` opportunistically to compare to the Stata implementation.
Why dropped: still requires a memory-monitored host given the prior R clubSandwich OOM, and the cause of the wall-time pattern is not yet diagnosed; comparing to R doesn't help isolate the cause.

## Open items and blockers

The reversed-J run is in flight (monitor `bouyyj8a0`, Stata `bor1aplxw`).
Expected wall ~1h45m for J=5000 phase + ~5--8 min for J=2000 phase, total ~2h.
Will fire a notification when Stata exits.

After the run, key analyses to perform:

1. Compare J=2000 rep 1 wall: ~95s supports H1 (cache), ~30s falsifies H1.
2. Pull per-core perf and util from the monitor for each rep window. If the slow J=5000 reps run on E-cores while the cold ones run on P-cores, that supports H2/H4. If cores look the same, that argues against P/E scheduling.
3. Check whether session F's J=5000 slowness reproduces; if J=5000 reps 2-5 land at ~1,500 s (sessions C/D regime) rather than ~2,400 s (session F regime), session F was an outlier.

If H1 is confirmed: next steps shift to working around or working with summclust's internal state. Options include opening a fresh Stata process per call (slow, defeats the point), reporting the issue upstream, or investigating whether summclust has a flag to skip the cached path.

If H1 is falsified: revisit thermal/scheduler hypotheses with the per-core data and likely move benchmarking to a quieter host before further work.

## Files touched

Monitors: [`monitor_system.ps1`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/monitor_system.ps1), [`monitor_system_v2.ps1`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/monitor_system_v2.ps1).
Do-files: [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do) (edited to add start/end clock columns), [`stability_test_dual.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual.do), [`stability_test_dual_reverse.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual_reverse.do).
Analysis: [`summarize_monitor_per_rep.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/summarize_monitor_per_rep.py).
Dossier: [`quality_reports/reviews/2026-05-06_summclust-noise-evidence.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-06_summclust-noise-evidence.md).

## Picking up

Wait for the reversed-J run to finish.
Read [`output/stability_dual_reverse_<stamp>.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/) and the [`output/monitor_v2_<stamp>.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/) trace.
Run the per-rep summary script (adapted to v2's wider format) and check the J=2000 rep 1 wall first.
Decide H1 vs H2 and route to the next experiment accordingly.

## Wrap-up addendum (pre-/clear)

The reverse-J run completed; the v2 monitor caught what looks like a contamination event mid-run, which means the H1 vs H2 question is still open.
The user called `/wrap-up` after seeing the contaminated results.

### Reverse-J run results

| J | Rep | Wall (s) | Notes |
|--:|----:|---------:|-------|
| 5,000 | 1 |   512.2  | rep 1 regime, fresh session |
| 5,000 | 2 | 1,973.0  | rep 2+ regime |
| 5,000 | 3 | 1,763.6  | drifting down |
| 5,000 | 4 | 1,525.5  | converged toward sessions C/D's ~1,500 s |
| 5,000 | 5 | 3,451.7  | huge spike, more than 2x rep 4 |
| 2,000 | 1 | 1,697.9  | neither H1 (~95 s) nor H2 (~30 s) prediction |
| 2,000 | 2 |   828.9  | recovering |
| 2,000 | 3 |   722.9  | trending down |
| 2,000 | 4 |   675.6  | low |
| 2,000 | 5 |   750.7  | small bump |

Both H1 (cache-state) and H2 (thermal/freq) predicted distinct values for J=2,000 rep 1.
We got 1,698 s --- not what either hypothesis said.
J^4 scaling broke (J=2,000 rep 4 wall 676 s × $(5/2)^4$ = 10,562 s, far above the J=5,000 walls).
Per-call overhead was the dominant cost during the slow phase, not per-cluster computation.

### Smoking gun in the v2 monitor

Saved at [`per_rep_monitor_summary_v2.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/per_rep_monitor_summary_v2.csv).
Three correlated jumps right at the J=5,000 rep 4-to-rep 5 boundary, near 09:36:

- Memory commit jumped from 45 GB to 54 GB (10 GB external allocation; Stata's own working set stayed under 0.9 GB).
- Pagefile usage jumped from 3.3% to 13.4%.
- System-wide CPU% jumped from ~12% to 30%+ for the duration of J=5,000 rep 5 and J=2,000 rep 1, then dropped back to 12% by J=2,000 rep 2.

Stata itself was steady throughout: pinned to a single core (mostly core 18), CPU rate ~0.97 logical-core per wall-second, working set under 0.9 GB.
The active core's frequency varied only ±15% across all reps (78--110% of nominal).
Frequency variation alone cannot account for a 6.7x wall-time spread.

Pattern: external memory + system CPU spike + slowdown all rose together at one moment, then receded together over the next 4 reps.
Most likely cause is some external process (Windows Update, OneDrive, antivirus full scan, or another user application) loading the system from ~09:36 until ~10:18.

### Decisions, with the why

Decision: drop "warm" / "cold" terminology in this investigation.
Why: user pushed back that "warm" implies a thermal frame which the data don't support.
Use "fast regime" / "slow regime" or just "rep 1" / "reps 2+" instead.
This is a substantive correction worth keeping for future sessions.

Decision: write the evidence dossier as observation-only with no hypotheses authored by Claude.
Why: user explicitly asked for the subagent's eyes to be fresh.
Pre-loading my thermal-throttling hypothesis would have anchored the review.
Outcome: the reviewer split the puzzle into four distinct phenomena and surfaced H1 (cache-state) which I had not considered.

Decision: add per-core CPU performance counters to monitor v2.
Why: the reviewer flagged this as the largest measurement gap.
v1's `\Processor Information(_Total)` averaged across 22 logical cores and would hide P-core vs E-core scheduling.
v2 closed this gap and showed Stata is single-core throughout.

Decision: aggregate ALL StataMP-64 processes in v2 monitor rather than per-process.
Why: v1 broke when multiple Stata processes were alive (recorded `System.Object[]`); the reviewer flagged this as a real possibility (and the user confirmed running other Stata work).
v2 reports stata_count, stata_pids, and totals across all alive processes.

Decision: declare the reverse-J run contaminated and stop trying to interpret it as a clean H1-vs-H2 test.
Why: the v2 monitor's external memory + CPU spike at the rep 4-to-rep 5 boundary correlates exactly with the wall-time anomaly.
Trying to read H1 or H2 signal through that contamination would over-interpret.

### Approaches rejected

Approach: re-run immediately to try to repeat the experiment with the user's other Stata work paused.
Why dropped: user called `/wrap-up`; this is the next session's job.

Approach: identify the specific external process that caused the spike (Process Explorer history, Event Viewer).
Why dropped: not high-leverage relative to running the experiment cleanly the next time; a process-snapshot would also need to have been captured at the time, and we did not.

Approach: assume the original dual-J run (session F) was contaminated too.
Why dropped: possible but not confirmed; that run was less variable and might still hold useful signal.
Need clean re-runs before we can decide.

### Open items and blockers

H1 vs H2 still not cleanly distinguished.
The reverse-J run was supposed to settle it but is contaminated.
Need a clean-room re-run with all other Stata work paused, anti-virus / OneDrive / Windows Update temporarily quieted, and ideally on AC power.

The pause-between-reps experiment is still queued as a follow-up if the clean reverse-J run leaves H1/H2 ambiguous.

Session E's "94% complete" hang in summclust remains unexplained.
The hang reproduced once at J=5,000 with v1 monitor, then did not reproduce in three subsequent runs (sessions F, the v2 reverse-J).
Worth keeping in mind: summclust at large J has a non-zero hang probability per call.

A new pattern from this run that I had not seen before: J=5,000 reps 2--4 walls drift downward (1,973 → 1,764 → 1,526) rather than holding flat as in sessions C/D.
Could be the system "settling in" or could be the contamination starting earlier than the rep-5 boundary suggests.

The user's mental model is that the rep-1-vs-rep-2+ step is too sharp and reproducible to be background noise.
This run does not falsify that view but does not confirm H1 either; the data point that would have decided it (J=2,000 rep 1) was contaminated.

Many uncommitted files: see "Files touched" above plus today's session log and the new CSVs / monitor traces.

### If you resume

Read [`quality_reports/session_logs/2026-05-06_summclust-cache-vs-thermal-investigation.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-06_summclust-cache-vs-thermal-investigation.md) (this file).

Open thread: H1 (summclust caches state across calls) vs H2 (thermal/freq) is still open.
Today's reverse-J run was contaminated by external load and could not decide it.

Next concrete action: re-run [`stability_test_dual_reverse.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual_reverse.do) under controlled conditions.
Before launching: confirm no other Stata processes (`tasklist //FI "IMAGENAME eq StataMP-64.exe"`), pause OneDrive sync, defer any pending Windows Update, plug into AC.
The decisive observation is the wall of J=2,000 rep 1: ~95 s supports H1, ~30 s supports H2, neither would suggest yet a third explanation.

Cached state to know:

- $\hat\phi_{\text{point}} = -0.30948$ for IDN consumption covs_trend.
- Base trajectory $\underline{d}_0 = 2$ for IDN.
- $J = 29{,}715$ unique pids in IDN unb post-singleton.
- 28 active z's at J=5,000, 21 active z's at J=2,000.
- Stata is pinned to a single logical core (mostly core 18 in this run) and uses ~0.97 core throughout.
- All completed summclust calls produced bit-identical regression output within their J level.
- The v2 monitor format has per-core perf and util as pipe-separated strings; use [`summarize_monitor_v2_per_rep.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/summarize_monitor_v2_per_rep.py) to aggregate by rep window.

Background tasks at end of session: all completed cleanly.
No stranded StataMP-64 or PowerShell processes (verified).

The pause-between-reps experiment idea is still queued; it would distinguish H1 (no help) from system-state recovery (recovery during pause).
Run it AFTER the clean re-run of the reverse-J experiment if H1/H2 still ambiguous.

Files awaiting commit: see "Files touched" above, plus this session log and the dossier and the contaminated-run CSVs.
The user has not requested a commit yet.
