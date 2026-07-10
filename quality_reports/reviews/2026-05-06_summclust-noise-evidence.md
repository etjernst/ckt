# Evidence dossier: summclust wall-time variation across replicates

This document collects raw observations from a series of stability tests of the Stata user-written command `summclust` running CV3/CV3J cluster-jackknife standard errors on the IDN unbalanced sample of a project dataset.
The numerical answer (regression coefficient, standard errors) is bit-identical across replicates within each J level.
What varies is wall-time.
The author is not requesting an opinion on the substantive estimation; the question is solely about the wall-time pattern and the system state observed during it.

## What the experiment does

A single Stata do-file ([`stability_test_dual.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual.do)) executes the following:

1. Loads a panel dataset (~152K rows pre-singleton-drop, IDN unb).
2. Sets up a regression on a transformed dependent variable.
3. Runs five replicates at $J = 2{,}000$ unique clusters (random subsample, **same seed each replicate**), then five replicates at $J = 5{,}000$ unique clusters (also same seed each replicate).
4. Each replicate calls `summclust ..., cluster(pid) fevar(trajectory) jackknife nograph` on identical data and records wall time.

The same seed within each J level guarantees the subsample, the active-z column set, and therefore the inputs to summclust are exactly identical replicate to replicate.
summclust's printed regression output is bit-identical across replicates at the same J (verified; see "Bit-identicality" below).

## System

- Windows 11.
- 22 logical cores reported by `Get-CimInstance Win32_Processor`.
- 72 GB pagefile commit limit; ~40 GB committed at idle.
- Plenty of RAM (>40 GB free at idle); stata working set <1 GB throughout.
- Stata 19 MP, invoked as `stata-mp -e do stability_test_dual.do`.

## Wall-time observations across multiple sessions

All numbers below are wall-clock seconds for a single `summclust` call at the J indicated, $\hat\phi$ fixed, same data each call.
$J = 5{,}000$ has 28 active z-columns, $J = 2{,}000$ has 21 active z-columns.

### Session A: yesterday morning, single fresh-Stata run, $J = 5{,}000$

One replicate: 480 s.

### Session B: yesterday afternoon, fresh-Stata run, 5 replicates at $J = 5{,}000$

Only replicate 1 completed (1,167 s) before the test was killed for unrelated reasons.
[`stability_J5000_2026May5_110559.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_110559.csv).

### Session C: this evening, fresh-Stata run #1, 5 replicates at $J = 5{,}000$

[`stability_J5000_2026May5_161425.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_161425.csv):

| Rep | Wall (s) |
|----:|---------:|
|   1 |    447.6 |
|   2 |  1,462.3 |
|   3 |  1,553.3 |
|   4 |  1,458.8 |
|   5 |  1,502.4 |

### Session D: this evening, fresh-Stata run #2, 5 replicates at $J = 5{,}000$ (killed after rep 3)

[`stability_J5000_2026May5_194819.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_194819.csv):

| Rep | Wall (s) |
|----:|---------:|
|   1 |    406.5 |
|   2 |  1,489.0 |
|   3 |  1,515.5 |
|   4 |   killed |
|   5 |   killed |

The session was killed by the user to relaunch with a system monitor running in parallel.

### Session E: this evening, fresh-Stata run #3, 5 replicates at $J = 5{,}000$, with monitor (HUNG)

[`stability_J5000_2026May5_210122.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_210122.csv) is empty (header only).

The do-file launched, set up data, and entered the rep 1 `summclust` call.
**summclust never produced any output** (its banner "SUMMCLUST - MacKinnon, Nielsen, and Webb" never appeared in the log).
Stata sat with no CPU consumption for 28+ minutes.
StataMP-64.exe's main window title (visible via `Get-Process | Where MainWindowTitle`) read "**94% complete**" — a string that does not appear in any normal summclust output.
The monitor showed system-wide CPU at 1–15%, CPU performance counter at 100–190% (boost engaged), memory and pagefile stable.
Stata was killed manually.

The monitor partial-CSV is at [`monitor_20260505_210044.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/monitor_20260505_210044.csv).
The Stata log (showing the call entered but never returned) is at [`stability_J5000_2026May5_210122.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_210122.log) — last logged line is the rep 1 setup print; no summclust output follows.

### Session F: tonight, fresh-Stata run #4, dual-J with monitor (this is the main run)

[`stability_dual_2026May5_215257.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_dual_2026May5_215257.csv):

| J     | Rep | Wall (s)  | Wall ratio to J=2000 rep 1 (30.2 s) |
|------:|----:|----------:|------------------------------------:|
| 2,000 |   1 |     30.2  |                              1.00x  |
| 2,000 |   2 |     95.3  |                              3.16x  |
| 2,000 |   3 |     99.1  |                              3.28x  |
| 2,000 |   4 |     95.0  |                              3.15x  |
| 2,000 |   5 |     97.7  |                              3.23x  |
| 5,000 |   1 |  1,310.7  |                                     |
| 5,000 |   2 |  2,469.6  |                                     |
| 5,000 |   3 |  2,344.0  |                                     |
| 5,000 |   4 |  2,325.0  |                                     |
| 5,000 |   5 |  2,399.2  |                                     |

The empirical scaling between $J = 2{,}000$ and $J = 5{,}000$ from earlier sweep work is approximately $J^4$.
$30.2 \times (5000/2000)^4 = 472$, which matches earlier sessions' "cold rep 1" wall at $J = 5{,}000$ (~430--480 s).
$97 \times (5000/2000)^4 = 1{,}516$, which matches earlier sessions' "rep 2--5" wall at $J = 5{,}000$ (~1,460--1,553 s).

But session F's $J = 5{,}000$ rep 1 came in at 1,310.7 s — neither the "cold" regime nor the "rep 2--5" regime seen in sessions A--D, and session F's $J = 5{,}000$ reps 2--5 averaged 2,385 s — about 1.6x slower than sessions C and D's reps 2--5.

## Bit-identicality of summclust output

Within session F:

- All five $J = 2{,}000$ replicates produced regression coefficient 0.889897, CV3 SE 0.019514 (singularity-dropped), CV3J SE 0.019514, and identical cluster variability tables.
- All five $J = 5{,}000$ replicates produced coefficient $-0.298736$, CV3 SE 0.761360, CV3J SE 0.761360, and identical cluster variability tables.

Across sessions C, D, F at $J = 5{,}000$, the same regression numbers appear.
Wall time is the only thing that varies across replicates with identical inputs.

## Monitor data per replicate (session F)

Per-rep summary computed by joining each replicate's start_clock/end_clock window with the monitor CSV.
Source: [`per_rep_monitor_summary.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/per_rep_monitor_summary.csv) (the script that builds it is at [`summarize_monitor_per_rep.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/summarize_monitor_per_rep.py)).

| J     | Rep | Wall (s)  | cpu_perf_pct mean | cpu_perf_pct min | cpu_perf_pct max | stata_cpu_sec / wall_sec | stata_ws GB mean | stata_threads med |
|------:|----:|----------:|------------------:|-----------------:|-----------------:|-------------------------:|-----------------:|------------------:|
| 2,000 |   1 |     30.2  |             151.0 |            142.9 |            172.3 |                    1.004 |            0.306 |                 9 |
| 2,000 |   2 |     95.3  |             152.4 |            117.9 |            183.8 |                    0.991 |            0.349 |                 5 |
| 2,000 |   3 |     99.1  |             145.3 |            123.8 |            189.0 |                    0.988 |            0.365 |                 3 |
| 2,000 |   4 |     95.0  |             149.2 |            133.9 |            167.2 |                    0.978 |            0.360 |                 3 |
| 2,000 |   5 |     97.7  |             159.8 |            129.3 |            187.4 |                    0.973 |            0.360 |                 6 |
| 5,000 |   1 |  1,310.7  |             155.0 |             78.9 |            197.7 |                    0.984 |            0.645 |                 3 |
| 5,000 |   2 |  2,469.6  |             111.4 |             58.1 |            169.2 |                    0.979 |            0.757 |                 3 |
| 5,000 |   3 |  2,344.0  |             122.8 |             61.6 |            170.5 |                    0.979 |            0.760 |                 3 |
| 5,000 |   4 |  2,325.0  |             125.2 |             59.5 |            178.8 |                    0.980 |            0.763 |                 3 |
| 5,000 |   5 |  2,399.2  |             116.9 |             62.4 |            169.7 |                    0.979 |            0.765 |                 3 |

Notes on the columns:

- `cpu_perf_pct` is the value of the Windows performance counter `\Processor Information(_Total)\% Processor Performance`.
This counter is the current CPU frequency normalized to the CPU's nominal/base frequency.
At idle on this system it reads about 130–150% (boost is engaged).
Values below 100% indicate the CPU is running below its base frequency.
- `stata_cpu_sec / wall_sec` is the rate at which the Stata process accumulates CPU time per wall-clock second of the replicate.
A value near 1.0 means Stata is using on average one logical core's worth of wall time throughout the replicate.
- `stata_ws GB` is the StataMP-64 process working set (RSS).
- `stata_threads` is the thread count of the Stata process.
- All replicates ran with `stata-mp -e`, so Stata MP has access to 2 logical cores per its license.

System-wide values during the replicates:

- Total CPU usage: 8–13% (mean across replicates).
- Memory used: 22.99–25.40 GB out of >40 GB available.
- Memory commit: 39.57–40.14 GB out of 71.99 GB commit limit.
- Pagefile usage: 3.65–3.67% (effectively flat throughout).

The full minute-by-minute monitor trace is at [`monitor_20260505_215248.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/monitor_20260505_215248.csv) (1372 polling rows over ~3 hours, 5-second polling interval).

## The PowerShell monitor

The monitor script is [`monitor_system.ps1`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/monitor_system.ps1).
It polls every 5 seconds and records:

- `\Processor(_Total)\% Processor Time` (system-wide CPU%)
- `\Processor Information(_Total)\% Processor Performance` (current freq as % of nominal)
- `\Paging File(_Total)\% Usage`
- `Win32_OperatingSystem` memory counters (TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory)
- `Get-Process -Name StataMP-64` working set, cumulative CPU seconds, thread count

The monitor does not measure CPU temperature or per-core frequency, only the system-wide performance counter.
There is no measurement of which physical cores Stata is running on.

## Stata invocation and prior-run behavior

All sessions used the same Stata invocation: `stata-mp -e do <file>.do`.
The `-e` flag is "execute and exit" (no GUI dialogs at end of run).
Sessions C, D, and F all completed with rc=0 for every replicate that ran to completion.
Session E did not — the rep 1 summclust call produced no output and the Stata process consumed no CPU for 28 min while displaying the window title "94% complete".

## Question for review

Given the observations above:

1. What hypotheses are consistent with these observations?
2. What additional measurements would distinguish among them?
3. Are there facts here that look inconsistent with each other in a way that warrants going back to the data?

Please form your own view from the evidence rather than ranking a list provided.
