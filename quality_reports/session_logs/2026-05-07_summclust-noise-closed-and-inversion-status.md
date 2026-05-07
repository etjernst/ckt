# 2026-05-07---summclust noise investigation closed; inversion CI production-status review

Mode: mixed.
Started in maintenance/audit mode for the inversion CI status check; transitioned to implementation mode for the clean reverse-J summclust run.

## Goal

Two threads in this session.

First, audit whether the lca-inversion branch has a production-ready weak-ID-robust CI implementation wired into the pipeline (setting aside the coverage/noise issue).

Second, run a clean reverse-J summclust stability test under controlled conditions to settle the H1 (cache state) vs H2 (thermal/freq) question that yesterday's contaminated reverse-J run left ambiguous.

## Inversion CI status review

Found via grep + reading [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) lines 1839--1942, [`RP7/scripts/5b_inversion.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do), [`RP7/scripts/test_5b_and_table.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/test_5b_and_table.log):

- `attach_inversion_ci` Stata program exists in `0_programs.do` and is decoupled from `run_grc`.
- `5b_inversion.do` driver loops country x spec for the urban/cons/unb mainline.
- `grc_tex_table_trend` reads `inv_*_ci90_str` / `inv_*_ci95_str` macros and emits bracketed-CI rows.
- BUT: `5b_inversion.do` is not in `0_master.do`, and the integration-test smoke at `test_5b_and_table.do` failed with `_est_grc_IDN_urban_covs_trend_never invalid name` (r(7) --- 32-char `_est_<name>` overflow).

Memory pointed to the pipeline-refactor branch having solved the naming via a unified `grc_<country>_<spec3>_<covs2>[_<sfx1>]` scheme.
Explore subagent confirmed the new convention:
`grc_IDN_cuu_ct` for the parent (14 chars / `_est_` = 19), `grc_IDN_cuu_ct_n` / `_a` / `_g` for never/always/avg subgroups (16 chars / 21).
Worst case `grc_CHN_uf_iuu_ca_n` = 19 chars / 24 internal, 9-char margin under the 32-char limit.
Refactor lives at [`worktree-grc-pipeline-refactor`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do); `4_GrRC.do` replaced `5_GrRC.do` as the GRC entry point.

PR #3 status check: open against main, head `worktree-grc-pipeline-refactor`, 89 commits ahead, mergeable status `CONFLICTING / DIRTY`.
Conflicts limited to two files (`RP7/scripts/0_master.do`, `RP7/scripts/0_programs.do`).
User confirmed in this session that the PR has since been merged.

## Decisions, with the why

Decision: pause inversion-side work until pipeline-refactor lands on main and lca-inversion can be rebased.
Why: doing a local rename only on lca-inversion would create divergent naming between branches and compound the merge problem.
Path of least surprise is rebase-then-update.
The user picked option 2 (wait for refactor merge, then rebase) over option 1 (do the merge now myself) and option 3 (local rename on inversion files only).

Decision: do not chase the noise investigation further once H2 was demonstrated.
Why: the user explicitly said "we have enough information now."
Pinning the conclusion is more useful than another 30 minutes of confirmatory data.

Decision: send the fresh-eyes review with very minimal context per the user's explicit instruction.
Why: prior fresh-eyes runs were anchored by my framing.
Doing this strictly without H1/H2 framing surfaced findings I had missed in my own write-up, including the cpu_perf_pct trajectory (188% to ~75%) and the cross-run pattern matching across May-5, May-6, and May-7.

## Reverse-J clean run

Launched at 08:19:38 (monitor v2 PID 37712) and 08:20:03 (Stata reverse-J PID 27588).
Killed at 10:37 after the J=2,000 rep 1 result was in.

| J | Rep | Wall (s) |
|--:|----:|---------:|
| 5,000 | 1 | 480 |
| 5,000 | 2 | 1,716 |
| 5,000 | 3 | 1,667 |
| 5,000 | 4 | 1,729 |
| 5,000 | 5 | 1,709 |
| 2,000 | 1 | 751 |
| 2,000 | 2--5 | not run |

Within-J=5,000 step pattern reproduced cleanly: rep 1 fast, reps 2--5 in tight band (CV ~2%).
J=2,000 rep 1 came in at 751 s --- neither H1's ~95 s nor H2's bare ~30 s prediction.
Monitor v2 was clean throughout: memory commit steady at 29 GB (vs 45->54 GB jump in the contaminated 2026-05-06 run), pagefile <0.3% (vs 13.4%), system CPU 4--9% (vs 30%+).
No external-load contamination event.

## Fresh-eyes review verdict

Fresh-context subagent received only the four artifacts (do-file, ps1, Stata log, monitor CSV) with the bare prompt "what do you think is going on?".
It autonomously also pulled in the prior May-5 and May-6 CSVs from the same directory.
Verdict: thermal throttling (H2) is the most likely story, not summclust cache state (H1).

Key evidence the subagent surfaced:

- `cpu_perf_pct` dropped from 188% at 08:19:59 to ~75% by 10:34. Per-core perf values that started at 150--200 ended at 50--90. Monotonic decay.
- The "fast rep 1, slow rep 2+" step appears in every phase across all three dual runs, regardless of J order. Pattern-consistent with thermal, not with cache state.
- J=2,000 rep 1 *after* a long J=5,000 phase came in at 751 s today vs 30 s in the cold-machine forward run. 25x slowdown tracks the ~60% perf-counter drop.
- May-6 reverse run's J=2,000 reps 2--5 (829, 723, 676, 751 s) sit in the same band. The J=2,000 phase never recovers cold-machine speed once the J=5,000 phase has heated the chip.
- Memory flat (~17.7 GB), one Stata process throughout, no commit pressure. Rules out memory bloat or runaway second Stata.
- Correctly inferred the run was killed mid-J=2,000 rep 2 (Stata log stops cleanly, monitor kept ticking 9 min after).

Conclusion: noise investigation closed.
The "third regime" I was framing isn't a third regime --- it's the same thermal effect at a longer integration.

## Approaches rejected and the reason

Approach: run J=2,000 reps 2--5 to confirm the slow band reproduces.
Why dropped: user said "we have enough information."
Confirmatory at this point, not decisive.

Approach: identify the specific thermal mechanism with `powercfg` to disable turbo, or with a cooling pad.
Why dropped: not asked; the diagnosis is good enough for the immediate decision (which backend to use for CV3J).

Approach: keep iterating on the lca-inversion CI implementation locally without waiting for the refactor merge.
Why dropped: user picked the wait-and-rebase path.
Compounding divergence would cost more time later than waiting now.

## Files touched

No source files edited this session.
Artifacts produced:

- [`output/stability_dual_reverse_2026May7_082003.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_dual_reverse_2026May7_082003.csv)
- [`output/stability_dual_reverse_2026May7_082003.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/stability_dual_reverse_2026May7_082003.log)
- [`output/monitor_v2_20260507_081937.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output/monitor_v2_20260507_081937.csv)

## Open items

Inversion CI work is blocked on the lca-inversion rebase onto post-refactor main.
The user confirmed PR #3 merged; rebase has not been done.
After rebase, the four-step plan from earlier in the session still stands:

1. Resolve rebase conflicts in `RP7/scripts/0_master.do` and `RP7/scripts/0_programs.do`.
2. Update inversion-side files to consume new names: `attach_inversion_ci`, `5b_inversion.do`, `demo_lca_inversion_ci.do`, `test_5b_and_table.do`. Rename `estbase` strings from `grc_IDN_urban_covs_*` to `grc_IDN_cuu_<covs2>`; change suffix loops from `_never`/`_avg`/`_always` to `_n`/`_g`/`_a`. Re-route `5_GrRC.do`-mainline references to `4_GrRC.do`.
3. Re-run `5b_inversion` against the renamed sters and smoke the table-build.
4. Add `5b_inversion.do` to `0_master.do`.

Noise investigation: closed.
Backend choice for CV3J should treat thermal-limited wall time as the binding constraint on this laptop.

The pause-between-reps experiment that was queued is dropped (would only confirm thermal recovery, not change the diagnosis).

Reverse-J reps 2--5 of J=2,000 not run.
Could be re-run later if the user wants in-band confirmation.

## If you resume

Two natural paths.

Path A: do the lca-inversion rebase against post-refactor main.
Resolve conflicts in the two do-files, update the inversion-side files to the new naming, smoke 5b on a single (country, spec) cell, then add 5b to master and run the table-build smoke.

Path B: continue the broader backend-choice work for CV3J inference now that the noise-investigation diagnosis is in.
Active plan at [`quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-05-r-summclust-comparison-plan.md) is still in scope.

Cached state to know:

- Reverse-J clean-run J=2,000 rep 1 = 751 s. cpu_perf_pct dropped from 188% to ~75% over 2h17m of sustained Stata load.
- All J=5,000 reps in this run produced bit-identical regression output (CV3J coefficient -0.298736, SE 0.761360 at J=5,000; coefficient 0.889897, SE 0.019514 at J=2,000).
- $\hat\phi_{\text{point}} = -0.30948$ for IDN consumption covs_trend, base $\underline{d}_0 = 2$, $J = 29{,}715$ unique pids in IDN unb post-singleton, 28 active z's at J=5,000, 21 at J=2,000.
- PR #3 (pipeline refactor) merged. lca-inversion not yet rebased.

## Step 0.6 boottest smoke and unary-null memo (afternoon)

Pivoted from the summclust noise diagnosis to the rev 5 plan's Step 0.6: a 15--30 minute `boottest` smoke at TZA $J = 1500$ recoded covs_trend to settle whether path D resolves to D-onepass or D-grid.

### What the smoke ran

[`explorations/python-grc/stata/step0_6_boottest_smoke/step06_boottest_smoke.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_6_boottest_smoke/step06_boottest_smoke.do) loads TZA, recovers $\hat\phi = -0.5150$ from the staging GRC ster, builds the recoded design at $\phi_0 = \hat\phi$, drops singletons, subsamples to 1500 unique pids ($N = 4091$), fits the auxiliary OLS via `areg`, runs the analytic joint Wald, runs `boottest` for the joint p-value, and tries `gridpoints(0)` for the one-pass CI.

Wall time: three seconds total.

### What the smoke found

Active z's at TZA $J = 1500$: 5 (not the q $\approx$ 25 the rev 5 plan named, which was an IDN-scale guess).

The asymptotic and bootstrap inference disagree dramatically.
$F(5,1499) = 1224.81$ with asymptotic $p < 10^{-300}$.
WCU rademacher $B = 999$ at the same null gives $p = 0.6867$.
This is the canonical weak-identification finding---asymptotic chi-squared rejects overwhelmingly while the WCU bootstrap, which is correctly sized at moderate $J^*$, accepts the LCA at the point estimate.

`gridpoints(0)` is invalid syntax.
`boottest` errors with "gridpoints() entry not a positive integer."
Per the help, multi-coefficient joint nulls do not have a one-pass CI inversion mode; the Chandrupatla bisection only handles unary nulls.
This forces the D-onepass-vs-D-grid question into a different framing: D-onepass is only available if $\phi$ can be made a unary regression coefficient.

### The unary-null memo

Wrote [`docs/notes/2026-05-07_unary-null-reparameterization.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md) describing a two-stage parameterization: a saturated first-stage OLS recovers $\hat\alpha_d$, define $\hat\theta_d = \hat\alpha_d - \hat\alpha_{\underline{d}_0}$, then refit with $\hat\theta_{d_i} D_i$ as a single regressor whose coefficient is $\phi$.
`boottest` then inverts the unary null $\phi = \phi_0$ in one bootstrap pass.

### What the critics found

Both an econometrics critic and a Stata critic returned substantive critiques.
Reports at [`quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md) and [`quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md).

Convergent verdict: the unary path is not worth pursuing.
First, the Stata sketch wouldn't run.
`areg` does not expose absorbed FE coefficients in `e(b)`, so the $\hat\theta_d$ recovery step is impossible as written.
Plus `i.trajectory#1.choice` collinear with `absorb(trajectory)` for always-takers and never-takers means silent column drop and a different effective estimand.
Second, the unary $\hat\phi$ is a different estimator from the D-grid $\hat\phi$, not just a more efficient computation of the same thing.
D-grid is minimum-distance-weighted joint Wald inversion; the unary stage is OLS projection onto the LCA with OLS-implicit weighting.
The two coincide only if all $J_R$ over-identifying contrasts hold exactly in sample, which will not happen at $J_R \geq 2$.
Third, the generated-regressor handling menu in the memo missed Murphy-Topel analytical correction, sample splitting, and score bootstrap; the framing of D-grid as "less compute-efficient" understated how cheap D-grid actually is.

### Decision (2026-05-07)

D-grid is production.
The unary path is documented as a feasibility memo with a decision paragraph appended; both critic reports are persisted under `quality_reports/reviews/`.
The decision rests on three things: (a) D-grid is fast enough at production scale (sub-second per fit at TZA $J = 1500$, extrapolating to a few hours per cell at IDN scale), (b) it's an order of magnitude faster than `summclust`, and (c) it's the validation reference, so making it production avoids divergence between headline and check.

The unary path stays available if a referee specifically asks for `boottest` one-pass inversion and the methodological corrections come back in scope.

### Files added or touched in this sub-session

- [`explorations/python-grc/stata/step0_6_boottest_smoke/step06_boottest_smoke.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_6_boottest_smoke/step06_boottest_smoke.do)
- [`explorations/python-grc/stata/step0_6_boottest_smoke/output/step06_boottest_smoke_2026May7_112343.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_6_boottest_smoke/output/step06_boottest_smoke_2026May7_112343.log)
- [`docs/notes/2026-05-07_unary-null-reparameterization.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-07_unary-null-reparameterization.md) (created and amended)
- [`quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_econ-critic.md)
- [`quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-07_unary-null-reparameterization_stata-critic.md)

### What's next (handoff for the next session)

The user clears context after this wrap-up.
Next session starts on (c): wiring D-grid as the production path for path D weak-ID-robust inference.

Concrete starting points the next session needs.

The boottest invocation pattern that worked in the smoke is `boottest (z_3 z_4 ... z_J), weighttype(rademacher) reps(`Bdev') nograph`.
At each $\phi_0$ on the grid, the recoded design is rebuilt, the auxiliary OLS is refit, and `boottest` returns the joint p-value at that $\phi_0$.
The CI is the convex hull of $\phi_0$ values where bootstrap $p \geq 0.05$.

Current parameters from the smoke: TZA $\hat\phi = -0.5150$, IDN $\hat\phi = -0.30948$, base trajectory 2 for both consumption specs.
The recoded design construction lives in [`explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual_reverse.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/stability_test_dual_reverse.do) lines 60--90 (use `setup_grc_estimation` plus `initial_values`, drop singletons, build $z_s$).

Open questions for D-grid wiring.

First, where the D-grid driver lives: a new `5c_dgrid_inversion.do` in `RP7/scripts/`, or a free-standing exploration script that gets called from `5b_inversion.do`?
The latter is consistent with how the inversion CI was done; the former matches the rev 5 plan's framing.

Second, scaling: at TZA $J = 1500$ a single fit was sub-second, but the design rebuild plus `boottest` at production $B = 9999$ at IDN $J = 29{,}715$ is the relevant cost.
Run a single-cell wall benchmark first before committing to full 60-cell production.

Third, naming: the lca-inversion branch still has the old pre-refactor naming (`grc_IDN_urban_covs_trend`).
Pipeline-refactor PR #3 has merged to main but lca-inversion has not been rebased.
Decide whether to rebase first or wire D-grid against the old names and update at the rebase.
