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
