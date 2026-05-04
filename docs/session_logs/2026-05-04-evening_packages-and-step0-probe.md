# 2026-05-04 evening---packages installed, IDN Step 0/0.5 probe, popup mystery

Mode: Implementation (resuming the rev 5 backend-choice plan from the morning session at [`2026-05-04_backend-plan-rev5-and-bias-fix.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-04_backend-plan-rev5-and-bias-fix.md)).

## Goals

Pick up where the morning session ended.
The next concrete actions per that wrap-up were: (1) commit rev 5 patches, (2) `ssc install summclust`, (3) verify `boottest`, (4) summclust scaling pre-flight on IDN at $J \in \{5{,}000, 10{,}000, 20{,}000\}$.

## What got built or changed

Stata package installs added to the canonical install location ([`RP7/scripts/0_setup.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_setup.do)): appended `boottest` and `summclust` to the `ssc_install` local.
Running `0_setup.do` (or `0_master.do` in full) now ensures both are present.
Confirmed installed via [`RP7/scripts/_smoke_packages.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_packages.do): `boottest 4.5.2` (27 July 2025), `summclust`, `reghdfe 6.12.3`, and `moremata` are all `which`-able.

Step 0/0.5 probe at [`explorations/python-grc/stata/step0_5_summclust_preflight/probe_idn_setup.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/probe_idn_setup.do).
Loaded IDN unbalanced consumption sample, ran `setup_grc_estimation`, extracted $\hat\phi_{\text{point}}$ from the saved `grc_IDN_urban_covs_trend.ster`, built the recoded $z$'s at $\phi_0 = \hat\phi_{\text{point}}$, dropped singletons, subsampled to $J = 500$ unique pids, attempted `summclust` syntax in two variants.
Run log at [`RP7/scripts/logs/probe_idn_setup_run.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/logs/probe_idn_setup_run.log).
No probe artifacts written to `RP7/output/staging/` (`initial_values` does not persist to disk; only the in-memory `e()` results were used).

Commits:

- `b5d0106` Add boottest and summclust to 0_setup.do; smoke test for both.

The probe do-file is uncommitted at the time of this log.

## Key probe findings

IDN unbalanced consumption sample.
$N = 89{,}648$ before any transforms; after `setup_grc_estimation` and dropping the lone singleton observation, the data have $J = 29{,}715$ unique pids.
Trajectory range: switchers are $2$ through $31$, always-urban is $32$, never-urban is $1$.
So $|S_R| = 30$ switcher trajectories, base $\underline{d}_0 = 2$ confirms the rev 5 plan claim, and the joint null has $|S_R \setminus \{\underline{d}_0\}| = 29$ recoded $z$'s.

Point estimate.
`grc_IDN_urban_covs_trend.ster` exposes $\phi$ as `_b[/phi]` (the slash-prefix form; `_b[phi:_cons]` failed first).
Value: $\hat\phi_{\text{point}} = -0.30948$.
Sign matches the paper's pro-poor migration finding.

Variable name correction to the rev 5 plan.
Rev 5 calls the trajectory $\times$ choice variable `beta_s_{s}` and the trajectory dummy `alpha_d_{s}`.
The actual code in [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) at lines 1248--1251 generates them as `switcher_{s}_choice` and `switcher_{s}` respectively.
Probe used the actual names; rev 5's "Recoded-design construction, pinned" section needs a one-line correction.

Two `summclust` syntax issues caught in the probe.
The probe tried `summclust lndepvar z_3...z_31 period_2-period_T, cluster(pid) absorb(trajectory) jackknife` and got `Cluster variable not constant within absorb variable. Use fevar instead.` (rc=198).
Diagnosis: `pid` varies within `trajectory` in the unbalanced sample (multiple individuals share a trajectory pattern), so `summclust`'s `absorb()` is for cluster-constant fixed effects only; the option for arbitrary FE is `fevar()`.
The fallback `i.trajectory` factor expansion failed with `factor-variable and time-series operators not allowed` (rc=101).
Diagnosis: `summclust` does not parse `i.varname`; trajectory dummies need to be expanded manually.
Both issues are simple fixes for the next iteration: switch `absorb(trajectory)` to `fevar(trajectory)`, OR pre-build manual trajectory dummies and pass them as columns of $X$.
Pick the one that survives the IDN scaling sweep cleanly.

## Decisions, with the why

Decision: install via `0_setup.do`, not via a new `_install/` subdir.
Why: user pushed back (mid-session) on creating a new install location when one already exists.
The canonical pattern uses `window stopbox rusure` which is interactive, but the conditional only triggers when a package is missing; once installed, `0_setup.do` is a silent no-op and safe in batch.
Cleaned up the ad-hoc `RP7/scripts/_install/` directory.

Decision: probe at $J = 500$ before launching the full $\{5{,}000, 10{,}000, 20{,}000\}$ scaling sweep.
Why: I don't trust rev 5's pinned `summclust` syntax until I've seen it parse on the actual data.
The 500-pid probe surfaced both syntax issues in 30 seconds; running the full sweep with the wrong syntax would have wasted 20--30 minutes per failed try and stacked more popups.

Decision: stop running batch jobs after the user reported popup accumulation.
Why: each batch-mode `r(608)` (or any error firing before `exit, STATA clear` is reached) pops a "Stata finished" or "command failed" dialog on Windows; the dialogs accumulate on the desktop until manually dismissed.
Three of my early runs failed with `r(608)` (log-name collision) before I added the wrapper, so $\ge 3$ popups are likely stacked.
Continuing to launch batches risks stacking more.

## Approaches rejected and the reason

Approach: run the full IDN scaling sweep right after the probe found the syntax issues.
Why dropped: `summclust` syntax not yet pinned correctly; another full-sweep failure costs 20--30 min and another popup; user's "still getting popups" message arrived as I was about to launch.

Approach: dismiss the popup mystery as benign batch-mode chrome.
Why dropped: the batch-mode "Stata finished" popup is exactly what `exit, STATA clear` is supposed to suppress (per [stata-conventions.md](file:///C:/Users/maand/.claude/rules/stata-conventions.md)).
That guard fails on errors that abort before the `exit` line; my early failed runs had no `capture noisily` wrapper, so they were fully exposed.
The mystery is just bookkeeping for the residual popups, not a bug in current code.

## Open items and blockers

Popup hygiene.
Old popups from the early failed `r(608)` runs are likely stacked on the user's desktop; the user has to dismiss them manually.
All my current scripts (`install_packages.do`, `_smoke_packages.do`, `probe_idn_setup.do`) wrap the body in `capture noisily { ... }` and end with `exit, STATA clear`, so future runs will not pop.

Rev 5 plan needs three small patches before the next batch run.

1. Correct the variable mapping: `beta_s_{s}` $\rightarrow$ `switcher_{s}_choice`; `alpha_d_{s}` $\rightarrow$ `switcher_{s}`.
2. Pin the `summclust` syntax: `summclust lndepvar z_3 ... z_31 trajdum_2 ... trajdum_K period_2 ... period_T, cluster(pid) jackknife`, where `trajdum_*` are pre-expanded trajectory dummies (or `fevar(trajectory)`---decide after a 5-minute test of which one survives the IDN scale).
3. Fix the small-cluster claim consistency: probe found IDN unb has $J = 29{,}715$ post-singleton-drop, not $\approx 30{,}000$ as rev 5 estimates.
The pre-flight grid $\{5{,}000, 10{,}000, 20{,}000\}$ stays the same since extrapolation to $29{,}715$ is the goal.

The summclust scaling pre-flight itself is still TODO.
After the syntax patch, the script structure is straightforward: subsample $J$ unique pids at $\{5{,}000, 10{,}000, 20{,}000\}$, time the fit and `tracemalloc`-equivalent peak memory at each point, plot the curve, extrapolate to $J = 29{,}715$.

Boottest install verified but Step 0.6 smoke test not yet run.
The smoke is on TZA $J = 1500$ recoded varlist-zero null at $\phi_0 = \hat\phi_{\text{point}}$ for TZA consumption; it's a separate prerequisite for path D-onepass selection.
TZA $\hat\phi_{\text{point}}$ extraction uses the same pattern as IDN (load `grc_TZA_urban_covs_trend.ster`, `_b[/phi]`).

The corrigendum incorporation read on `clubSandwich` 0.6.2 (rev 5 deadline 2026-05-09) remains TODO.

## Process feedback noted from this session

The user noted two practices to apply going forward.

Log naming for trial / probe scripts.
Either close the existing log and reopen with `replace`, or use a `_<timestamp>` suffix on the log name for trial runs, so successive runs don't either collide on the auto-batch log of the same name OR silently overwrite the previous run's evidence.
Add to the probe scripts in this directory before the next iteration.

Trial output isolation.
Outputs from probes / scaling sweeps must land somewhere distinct from the main `RP7/output/{staging,tables,figures}` directories so a re-run of the production pipeline never clobbers a probe artifact and a probe never leaks into a published table.
The probe complied incidentally (no ster persisted), but a new convention is needed: dedicate `explorations/python-grc/stata/step0_5_summclust_preflight/output/` (or similar) for sweep artifacts.

## If you resume

Read this log and the morning's wrap-up at [`2026-05-04_backend-plan-rev5-and-bias-fix.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-04_backend-plan-rev5-and-bias-fix.md).
Both probe artifacts (`probe_idn_setup.do` and the run log) are on disk and uncommitted.

Next concrete actions, in order.

1. Dismiss any leftover Stata popups on the desktop (manual; cannot be done from CLI).
2. (5 min) Patch rev 5 with the three corrections above (variable names, summclust syntax, $J$ count).
3. (10 min) Update `probe_idn_setup.do` to use `fevar(trajectory)` (or manual dummies---test which one parses), confirm the syntax probe at $J = 500$ now succeeds.
Add timestamped log naming.
4. (15--20 min) Build the scaling sweep do-file at $J \in \{5{,}000, 10{,}000, 20{,}000\}$.
Output artifacts (timing CSV, peak-memory log, summclust ster files) go to `explorations/python-grc/stata/step0_5_summclust_preflight/output/`, not `RP7/output/staging/`.
Use `_<timestamp>` log naming.
5. (60--90 min) Run the sweep, plot the timing and memory curves, extrapolate to $J = 29{,}715$.
If the extrapolation predicts $> 30$ minutes wall or $> 8$ GB peak, kick off the from-scratch CR3 prototype in parallel per rev 5 Step 0.5 decision rule.
6. (15--30 min) Step 0.6: `boottest, gridpoints(0)` smoke on TZA $J = 1500$.

State to know.
$\hat\phi_{\text{point}} = -0.30948$ for IDN consumption covs_trend; same extraction pattern works for TZA via `grc_TZA_urban_covs_trend.ster`.
Trajectory range for IDN unb: $1, 2, \ldots, 31, 32$, with $1$ never, $32$ always, and $S_R = \{2, \ldots, 31\}$.
The recoded design has 29 $z$ regressors after omitting the base $\underline{d}_0 = 2$.
Singletons: only one observation in IDN unb has $n_{\text{pid}} = 1$, so the singleton drop costs nothing material at IDN scale.
