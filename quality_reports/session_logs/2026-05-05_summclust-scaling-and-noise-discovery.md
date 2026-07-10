# 2026-05-05---summclust IDN scaling sweep and run-to-run noise discovery

Mode: Implementation, transitioning to investigation as the sweep results revealed system-noise issues.

## Goal

Continue the rev 5 backend-choice work picked up from [the 2026-05-04 evening session](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-04_evening_packages-and-step0-probe.md).
The morning's plan was: rev 5 patches, probe re-run with `fevar(trajectory)`, scaling sweep at $J \in \{5{,}000, 10{,}000, 20{,}000\}$, and a Step 0.6 boottest smoke on TZA $J = 1500$.

## What got built or changed

Rev 5 patches applied in commit `956b629`: variable mapping (`switcher_{s}_choice` / `switcher_{s}` not `beta_s_` / `alpha_d_`), pinned `summclust` syntax with `fevar(trajectory)` (fallback to manual `trajdum_*` documented), and the $J = 29{,}715$ count replacing the $\approx 30{,}000$ estimate.

Probe iterated to popup-free, rc=0 behavior at $J = 500$ in commit `158d258`.
Three issues fixed: switch from `absorb(trajectory)` (errored rc=198 because `pid` varies within `trajectory`) to `fevar(trajectory)`; active-z filter that drops zero-variance $z_s$ columns (only 13 of 32 trajectory levels appear in $J = 500$ subsamples, so most $z_s$ columns are uniformly zero and tripped a `<istmt>: 3301 subscript invalid` deep inside `summclust`'s Mata); `nograph` option to suppress summclust's leverage figure (`set graphics off` does not survive summclust's internals).

Scaling sweep do-file built at [`sweep_idn_summclust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust.do).
Output goes to `output/` with timestamped filenames per the trial-output discipline rule.

No-jackknife sweep do-file built at [`sweep_idn_summclust_nojack.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust_nojack.do) to test whether dropping the `jackknife` option saves wall time.

Stability test do-file built at [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do): five identical replicates of the production spec at $J = 5{,}000$ to quantify run-to-run wall-time noise.

R `summclust` head-to-head plan written at [`quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md).
Three sequential probes (R.1 smoke at $J = 500$, R.2 scaling at $J \in \{1000, 2000, 5000\}$, R.3 stress at $J = 10{,}000$), each with hard memory and wall ceilings, none to run on the main workstation given the prior `clubSandwich` 13 GB OOM crash.

Convention rule fixed at [`~/.claude/rules/stata-conventions.md`](file:///C:/Users/maand/.claude/rules/stata-conventions.md): the popup is suppressed by the `-e` invocation flag (`stata-mp -e do file.do`), not by the `exit, STATA clear` directive that the prior convention claimed.
Verified empirically across multiple runs.

## Sweep results (Stata `summclust`, IDN unb, with `fevar(trajectory)` and `nograph`)

With-jackknife at $J = 5{,}000$: 480 s.
With-jackknife at $J = 10{,}000$: 8,066 s.
No-jackknife at $J = 5{,}000$: 613 s (counter-intuitive direction; suspected noise).
No-jackknife at $J = 10{,}000$: killed before completion to free the machine for the stability test.
With-jackknife at $J = 20{,}000$: killed mid-run; would have taken ~36 hours at the empirical $J^4$ scaling.

Stability test at $J = 5{,}000$ first replicate: 1,167 s.
That is 2.4x the original 480 s baseline and 1.9x the no-jack 613 s for an IDENTICAL spec.
Run-to-run variance dwarfs the with-vs-no-jack difference; the comparison is currently noise-dominated.

## Decisions, with the why

Decision: kill the $J = 20{,}000$ cell at the start of the day rather than let it finish.
Why: the empirical $J^{4}$ scaling implied 36 hours wall at the desktop, and waiting that long would not change what we already knew from $J = 10{,}000$ alone (summclust does not scale to IDN on this hardware on this timescale).
The user's framing that 36 hours / 8 days is acceptable on a server reframes the decision: the $J = 20{,}000$ datum is a nice-to-have for a smoother extrapolation curve, not load-bearing for the production decision.

Decision: do not roll our own CR3 yet (path C / from-scratch CR3 in rev 5).
Why: server compute or work-laptop compute is plausibly enough to run Stata `summclust` to convergence at IDN scale; the implementation cost of from-scratch CR3 (1-day budget) is not justified until we know the production-execution-environment wall is also too long.

Decision: pause and run a stability test at $J = 5{,}000$ before drawing any conclusion from the no-jackknife result.
Why: the 480 vs 613 wall-time direction (no-jackknife slower than with-jackknife) is mechanically implausible since `jackknife` adds CV3J ON TOP of CV3, so removing it should only ever shrink wall time.
Either the algorithm differs more than the help suggests, or the comparison is noise-dominated.
The first replicate (1,167 s) makes "noise-dominated" overwhelmingly likely.

Decision: write the R `summclust` comparison as a plan, not run it.
Why: the prior R `clubSandwich` attempt at TZA scale crashed the workstation with a 13 GB peak-RSS OOM; running R again on the main machine without an external memory monitor is unwise.
The plan documents what the comparison would look like and where it should run (work laptop or MQ HPC), with hard memory ceilings enforced from outside R via PowerShell.

## Approaches rejected and the reason

Approach: trust the 480 vs 613 second difference and conclude that `jackknife` is essentially free.
Why dropped: the 1,167 s first-replicate result blew this conclusion out of the water.
Need a clean-conditions re-run before any wall-time claim is publishable.

Approach: pivot immediately to the from-scratch CR3 prototype.
Why dropped: the user explicitly asked to defer it, and the prior justification (Stata too slow at IDN scale) becomes weaker once server-class compute is on the table.

Approach: launch the R comparison opportunistically while the Stata sweep was running.
Why dropped: per the prior R crash, R needs an external memory monitor and a non-main-workstation host.
Both are setup work that has to land before R can be safely run again.

## Open items and blockers

Stability test in flight at the time of this log; replicate 1 done at 1,167 s, replicates 2--5 still to come.
User decision pending: kill the stability test now (we have the answer that the system is noisy) or let all 5 replicates finish for a real distribution.

Server / clean-laptop compute environment is not yet scoped.
Action items: user to check (a) MQ HPC access protocol, R version, package install policy, RAM ceiling per job; (b) work laptop's RAM, OS, and whether `stata-mp` is licensed there.
Once one of those is in hand, re-run the with-jackknife sweep at $J \in \{5{,}000, 10{,}000\}$ in clean conditions to anchor the production scaling estimate.

R comparison is not yet greenlit; the plan is on disk awaiting execution.
Step 0.6 boottest smoke on TZA $J = 1500$ is still TODO from the rev 5 plan.

## Files touched

Probe: [`probe_idn_setup.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/probe_idn_setup.do).
Sweep (with jackknife): [`sweep_idn_summclust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust.do).
Sweep (no jackknife): [`sweep_idn_summclust_nojack.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust_nojack.do).
Stability test: [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do).
R comparison plan: [`quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md).
Rev 5 patches: [`quality_reports/plans/2026-05-04-backend-choice-for-f-adjustment-rev5.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-04-backend-choice-for-f-adjustment-rev5.md).
Convention rule fix: [`~/.claude/rules/stata-conventions.md`](file:///C:/Users/maand/.claude/rules/stata-conventions.md).

## Commits this session

- `956b629` Rev 5 patches from evening session probe findings.
- `158d258` Probe: fevar(trajectory), nograph, active-z filter, timestamped log.

The sweep, no-jack sweep, stability test, and R comparison plan are uncommitted at the time of this log.
A bundled commit before the next /clear would group "Step 0.5 sweep tooling and stability investigation" cleanly.

## Picking up

Read this log and the sweep CSVs in [`output/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/).
Wait for the user's call on the stability test (kill now vs. finish 5 replicates), then act accordingly.
The R comparison plan does not run without explicit user greenlight and a memory-monitored host.
Step 0.6 (boottest smoke on TZA $J = 1500$) remains TODO and is the next item once the noise question is resolved.

## Wrap-up addendum (pre-/clear)

User called `/wrap-up` at the end of the session.
This addendum captures the final state of every loose thread.

### Final actions

User decided to kill the in-flight stability test rather than wait for all 5 replicates.
Why: replicate 1 already came back at 1,167 s vs the 480 s baseline, a 2.4x ratio that establishes "the system is currently noise-dominated" without needing the full distribution.
Replicate 1 result preserved at [`output/stability_J5000_2026May5_110559.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_110559.csv).
The stability test do-file is ready to re-run cold once the laptop is otherwise idle; same invocation, ~40 min wall budget at the clean baseline.

Bundled commit at `2ef9cce` covers the sweep tooling, no-jack sweep, stability test, R comparison plan, today's session log, and the partial sweep results.
Twelve files, 897 insertions; `.log` files excluded by `.gitignore` but reproducible from the do-files.

### Decisions, with the why (final tally for this session)

Decision: `stata-mp -e do file.do` is the canonical batch-mode invocation on Windows; `-b` is wrong.
Why: the `-e` flag suppresses the Windows completion popup that no in-script directive (`exit, STATA clear`, `clear all`, etc.) can suppress on Stata 18/19; verified empirically across multiple runs after the `-b` invocation popped a dialog every time.
Convention rule at [`~/.claude/rules/stata-conventions.md`](file:///C:/Users/maand/.claude/rules/stata-conventions.md) updated.

Decision: `summclust ..., nograph` is mandatory in batch invocations.
Why: `set graphics off` is reset internally by `summclust` and the leverage figure pops a graph window on Windows.
Documented in the same convention rule update.

Decision: kill the $J = 20{,}000$ Stata cell mid-run.
Why: the $J^4$ scaling implied 36 hours wall on this desktop and the user's reframing (server compute is acceptable) made the smoother extrapolation curve a nice-to-have rather than load-bearing for the production decision.

Decision: pause the no-jackknife wall comparison; do not draw conclusions until the noise problem is resolved.
Why: 480 vs 613 s (with-jack vs no-jack) is in the wrong mechanical direction (no-jack should be faster, not slower), and the stability test's 1,167 s replicate showed run-to-run variance dwarfs the difference.

Decision: write the R `summclust` comparison as a plan, do NOT run it.
Why: the prior R `clubSandwich` attempt at TZA scale crashed the workstation with a 13 GB peak-RSS OOM; running R again on the main machine without an external memory monitor and on a dedicated host is unwise.

Decision: defer the from-scratch CR3 prototype.
Why: the user explicitly asked to defer; the original "Stata too slow" justification weakens once server-class compute is on the table.

### Approaches rejected

Approach: bake `nograph` and `set graphics off` together for double belt-and-suspenders.
Why dropped: `set graphics off` does nothing useful and adds noise; `nograph` alone is sufficient.

Approach: drop `jackknife` for a 2x speedup.
Why dropped: empirical no-jack run came in 28% LONGER, not faster, and the J=5000 stability test showed the comparison was noise-dominated.
Algorithmically `jackknife` adds CV3J on top of CV3 with shared per-cluster machinery; the marginal cost is small.

Approach: run R `summclust::vcov_CR3J.fixest` opportunistically while Stata sweeps run.
Why dropped: prior R crash on the same machine; need external memory monitor and ideally a different host.

Approach: trust the with-vs-no-jack 480/613 difference and conclude `jackknife` is essentially free.
Why dropped: the 1,167 s stability replicate at the same $J = 5{,}000$ blew the comparison out of the water.

### Open items and blockers

Stability re-run.
[`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do) needs a clean-conditions run; ~40 min wall, 5 reps, CV across reps is the headline number.
Below 10% means we trust the wall-time comparisons; above means we need a different host (work laptop or MQ HPC).

Sweep re-run after stability is resolved.
Both [`sweep_idn_summclust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust.do) and [`sweep_idn_summclust_nojack.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust_nojack.do) need a clean re-run for trustworthy numbers; the existing `2ef9cce` results are anchor data only.

R comparison execution.
Plan at [`quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md) is ready; greenlight requires a host decision and the PowerShell memory monitor to be in place.

Server / work-laptop compute scoping.
User to check (a) MQ HPC access protocol, R version, package install policy, RAM ceiling per job; (b) work laptop's RAM, OS, whether `stata-mp` is licensed there.
Whichever comes first becomes the host for the clean re-runs and the R comparison.

Step 0.6 (boottest gridpoints(0) smoke on TZA $J = 1500$) is still TODO from the rev 5 plan; same `_b[/phi]` extraction pattern from `grc_TZA_urban_covs_trend.ster`.

### Stale state to be aware of

Two old monitor processes (`boyih0lig` no-jack sweep, `bxzixv18l` stability test) timed out at the end of the session and are no-ops; their underlying Stata processes were killed by `kill 13272` and `kill 20363` respectively.
No stranded `StataMP-64.exe` processes verified via `ps -ef | grep stata`.

The two sweep CSVs in `output/` (`summclust_scaling_sweep_2026May4_224022.csv` and `summclust_scaling_sweep_nojack_2026May5_104928.csv`) are committed and represent the noise-contaminated baseline.
The clean re-runs will produce new timestamped CSVs alongside; do not delete or overwrite the existing ones.

### If you resume

Read this log first.
Next concrete actions in order.

1. (5 min, manual) User confirms when laptop is otherwise idle.
2. (40 min wall) Re-run [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do) via `cd explorations/python-grc/stata/step0_5_summclust_preflight && stata-mp -e do stability_test_J5000.do`; check the resulting `stability_J5000_<stamp>.csv` for CV across the 5 replicates.
3. (decision branch) If CV < 10%: re-run both sweep variants ([`sweep_idn_summclust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust.do) and [`sweep_idn_summclust_nojack.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/sweep_idn_summclust_nojack.do)) for the trustworthy with-vs-no-jack comparison.
If CV >= 10%: defer to a different host before any further benchmarking.
4. (15--30 min) Step 0.6 boottest smoke on TZA $J = 1500$ once noise is resolved; extracts $\hat\phi_{\text{point}}$ for TZA via `_b[/phi]` from `grc_TZA_urban_covs_trend.ster`.
5. (deferred) R comparison if step 3 leaves Stata as the production choice and the host scoping work is done.

Cached state.
$\hat\phi_{\text{point}} = -0.30948$ for IDN consumption covs_trend (extract via `_b[/phi]`).
Base trajectory $\underline{d}_0 = 2$ for IDN.
$J = 29{,}715$ unique pids in IDN unb post-singleton.
29 recoded $z$'s in the joint null; 28 active in the $J = 5{,}000$ subsample.
`boottest 4.5.2` and `summclust` are installed and `which`-able.
TZA $\hat\phi$ extraction is the same `_b[/phi]` pattern from `grc_TZA_urban_covs_trend.ster`.

Commits this session bundle.

- `956b629` Rev 5 patches from evening session probe findings.
- `158d258` Probe: fevar(trajectory), nograph, active-z filter, timestamped log.
- `2ef9cce` Step 0.5 summclust sweep tooling and noise investigation.

## Evening addendum: stability re-run reveals thermal throttling

Picked up after a ~3.5 hour idle gap.
User confirmed laptop was reasonably idle; launched [`stability_test_J5000.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_J5000.do) cold.

### Run 1 (background `bay4mwdbv`, results at [`stability_J5000_2026May5_161425.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_161425.csv))

| Rep | Wall (s) |
|-----|---------:|
| 1   |   447.6  |
| 2   | 1,462.3  |
| 3   | 1,553.3  |
| 4   | 1,458.8  |
| 5   | 1,502.4  |

Pooled CV across all 5 reps: ~36.5%, well above the 10% trust threshold.
But the structure is not random scatter: rep 1 lands at the clean baseline (~448 s), reps 2--5 cluster tightly at ~1,494 s (CV ~3% across reps 2--5 alone).
A step change after rep 1, not white noise.

### Run 2 (background `b75v6ds97`, in flight at log time, results at [`stability_J5000_2026May5_194819.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_J5000_2026May5_194819.csv))

Re-run with no other changes to test whether something background was running during run 1.

| Rep | Wall (s) |
|-----|---------:|
| 1   |   406.5  |
| 2   | 1,489.0  |
| 3   | 1,515.5  |
| 4   | (in flight) |
| 5   | (in flight) |

Same step change. Rep 1 even faster than run 1's rep 1 (laptop had ~3.5 hours to cool fully).
Reps 2--3 land in the same ~1,500 s regime as run 1 reps 2--5.

### Hypothesis update

Thermal throttling is now the leading explanation by a wide margin.
The pattern reproduces across two independent runs separated by hours of idle: cold rep 1 fast, then a sustained-load regime change at ~1,500 s.
Yesterday's anomalous 1,167 s replicate is no longer anomalous; it sits between the cold regime (~430 s) and the throttled regime (~1,500 s) and was probably caught mid-transition.
The original 480 s "baseline" was the unusually fast rep, not the typical one.

### Implications for the production decision

The relevant production wall on this laptop is the throttled regime (~1,500 s at $J = 5{,}000$), not the cold-rep baseline.
At empirical $J^4$ scaling, that implies $\approx 24{,}000$ s ($\approx 6.7$ hours) at $J = 10{,}000$ and $\approx 384{,}000$ s ($\approx 4.4$ days) at $J = 20{,}000$ on this hardware.
The IDN production scale is $J = 29{,}715$.
That makes the case for moving the production benchmark off this desktop materially stronger than it looked yesterday.

### Open items

Wait for run 2 reps 4--5 to complete (notification will fire).
Decide between (a) accepting ~1,500 s as the operative wall and re-running sweeps in that regime, (b) moving to a quieter host (work laptop or MQ HPC) before further benchmarking, or (c) investigating whether throttling can be mitigated (CPU power profile, cooling pad, etc.).
The from-scratch CR3 prototype and the R `summclust` head-to-head plan remain deferred pending host scoping.
