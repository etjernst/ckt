# 2026-07-13 --- P7 split-fit leg, simulation-methodology review, P5b launch-pause-fix cycle

## If you resume

One-line state: P7 is done and committed; a fresh-context simulation-methodology review (adapted from Sant'Anna's sim-reviewer) returned FIX-BEFORE-FREEZE and all its fixes are committed; P5b is NOT running --- it is blocked on Emilia's pending ruling on one last truth-definition change (the `Delta_avg_kept5` row-share question below), after which: apply that fix (~20 min), delete the stale `sims/results/p5b/` batches, relaunch `sims/src/run_p5b.sh`, ~7.5 h to completion, then metrics check and hash freeze.

The pending decision (asked of Emilia at ~00:05): production `compute_all_inversion_cis` ([lca_inversion.py:806](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/lca_inversion.py), parity-certified, cannot change) weights the kept-set average return by ROW shares, but the registry truth `estimands.delta_avg` uses PEOPLE shares; on IDN these differ by up to 2.6e-4 because some kept trajectories mix 4- and 5-period individuals (TZA exact).
Recommendation delivered: redefine the `Delta_avg_kept5` truth to design row shares over the kept set (deterministic under the fixed design, aligns truth with what production targets, enables an exact runtime weight assert); numeric effect ~1e-4 on one IDN truth, far below MCSE.
If approved, also update the registry line in [p3_dgp_truths.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p3_dgp_truths.md) section 3.2 and the appendix scoring sentence ("row shares within the kept set", not "people shares"), and complete the deferred half of review Fix 9 (exact pi_within assert; the kept-set equality assert is already in).

Worktree: [C:/git/ckt/.claude/worktrees/extension-sims](file:///C:/git/ckt/.claude/worktrees/extension-sims), branch `worktree-extension-sims`, tip `d793f01`, clean.
Commits this session: `44ae12a` (P7 split-fit leg), `4225bf0` (appendix disclosures), `d793f01` (review fix batch).

## Mode

Implementation (P7 per the approved extension-simulation plan), then Review (fresh-context sim-methodology review), then Implementation again (approved fix batch).

## Goals

Emilia's asks, in order: "pick back up where we left off" (P7 split-fit leg per the 2026-07-12 handoff); launch P5b with a fresh out-dir and track duration ("these are not large files, right?" --- answered: ~40 KB per 10-rep batch, ~3-4 MB total); assess https://github.com/pedrohcgs/claude-code-my-workflow/blob/main/.claude/agents/sim-reviewer.md for reviewing our work and/or adoption as an agent; "yes please proceed with the fixes. what will we do about the TZA singleton?"

## What got built or changed

P7 split-fit leg (commit `44ae12a`; sonnet subagent from a main-thread brief, main-thread review).
[run_one.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/run_one.py) stage 2b: for each regime of a two-regime replication, refit the certified GMM on the true-regime-label subsample; score `phi`, per-trajectory `Delta_traj_d`, `Delta_never`, `Delta_always` as `gmm_split_r1`/`gmm_split_r2` against `truths["phi_1"/"phi_2"]`/`truths["Delta_split"]`; per-regime typed failure capture; `trajectory_absent_in_regime` guard; `wall_split_s` column; no within-regime average (registry defines no such truth).
Review catch: the DGP-failure early return emitted no split rows, silently shrinking the split estimators' `n_attempted` denominator relative to pooled; fixed + test.
Registry doc gained the split-fit scoring rule (section 4.4).

P5b first launch (22:33) and diagnosis-rich abort.
TZA baseline completed 100/100 in 1316 s (~2x the 6-worker pilot per-rep pace at 12 workers).
TZA two-regime dial 0 completed 100/100 in 1401 s but the driver ABORTED on exit code 1: TZA trajectory 3 has exactly ONE person (`traj_n_pids`), so every replication records one deterministic `trajectory_absent_in_regime` row (72 in regime 1 / 28 in regime 2, matching that person's membership odds), and the orchestrator treated a nonzero failure tally as process failure.
The P7 guard behaved exactly as designed; the exit-code convention was the bug (independently flagged as MINOR 11 by the review an hour earlier).

Simulation-methodology review (fresh-context Fable subagent, rubric adapted from pedrohcgs sim-reviewer; report at [2026-07-12_sim-methodology-review.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-07-12_sim-methodology-review.md)).
Verdict FIX-BEFORE-FREEZE: 0 CRITICAL, 3 MAJOR, 8 MINOR; coverage-against-truth, seeding/CRN, MCSE formulas, dial-zero nesting all PASS.
MAJOR 1 run identity (resume keyed only on cell/arm/dial; rows lacked noise_scale/rho_override; stale pre-split pilot batches would mix silently); MAJOR 2 arm-two pooled `phi` scored against the people-share WLS projection while the docstring wrongly called that the GMM pseudo-true value; MAJOR 3 inversion rows carried an undocumented grid-argmin point estimate into the paper table's bias/SE/RMSE columns.
All three MAJORs verified in main thread before acting (stale batch = 30 cols/no split rows; make_tables prints inversion accuracy cells; docstring/test contradiction).

Fix batch (commit `d793f01`; sonnet subagent, 13 specified fixes, main-thread review of orchestrate/dgp/run_one diffs; 36/36 tests).
Run identity: `noise_scale`/`rho_override` columns + integrity checks (NaN/value rho mixing is a hard error); filename family `{cell}_{arm}_dial{D}_ms{S}_ns{N}_rho{R}`; resume refuses on source-md5 drift or missing manifest (`--force-resume` to override); rep-set consistency assert in `summarize()`.
Truths fill on every failure path via new `dgp.compute_truths` (single construction; `_truth_lookup` shared by success and failure paths).
`profile_cap_hit` flag + share; orchestrator exits 0 on typed failures and pins BLAS threads; inversion accuracy cells blanked in `main_table` (test proves blanking on finite inputs); completion table counts replications; `converged_share` per estimator; kept-set assert; two docstrings corrected.

Appendix disclosures (commit `4225bf0`, main thread): arm-two `phi` is drift vs a best-linear-fit reference; the TZA singleton sentence; unconditional convergence convention with reported shares; size-adjusted J critical-value note (in the results TODO block).

## Decisions, with the why

TZA singleton: keep the typed-failure treatment, no code special-case.
Conditional on presence the split fit is unbiased for the regime-conditional truth (the person's theta is drawn regime-conditionally, which is what `delta_d_split` describes); n_eff 28/72 by regime on that one parameter; headline split parameters unaffected.

MAJOR 2 resolved by relabeling (docstring + appendix), not by computing the GMM's own pseudo-true value numerically: the per-trajectory pooled truths are exact mixture expectations and carry the finding; J power is the headline violation detector; the numeric pseudo-true chase buys little.

MAJOR 3 resolved by blanking: the inversion is an interval procedure; its grid-argmin is quantized at the grid step and the appendix names no point estimator.

P5b paused at 23:13 (before the abort landed): the MAJOR 1 schema fix would stale every batch written; pausing was reversible via idempotent resume.
Moot in hindsight: the driver died at 23:19 on the exit-code bug regardless.

Old-naming pilot batches in `sims/results/raw/` are quarantined by construction (new filename families never match them); left in place.

## Approaches rejected, with the reason

Excluding n=1 trajectories from split scoring: trades honest accounting for a data-quirk-shaped branch in certified code.
Waiting for P5b to finish before reviewing: the review existed precisely to run before the hash freeze; it found schema changes that would have invalidated the whole 7-h run at 6 am.
Computing the pooled GMM's exact pseudo-true `phi*(g)` from the population moment system: no closed form, high effort, low payoff given the relabel option.

## Open items

Emilia's ruling on the `Delta_avg_kept5` row-share truth redefinition (the only blocker).
Then: apply it + docs + exact weight assert, wipe `sims/results/p5b/`, relaunch `run_p5b.sh` (~7.5 h at the observed 12-worker pace), metrics check, watch-items recheck (erratic GMM `Delta_always`, J power at TZA full dial, IDN Wald SE bias), hash freeze.
Decide on saving an adapted `sim-reviewer` agent after the P5b cycle (recommended: yes --- the lens found 3 MAJORs after a general-Python pass found none; wire its claims-vs-tables category into P8).
Carried over for Emilia: hukou stub footnote, `11b_extrapolation_support_figure.do` wiring, server-access request (feeds the full-matrix venue).
Monitor `b520s5plh` (persistent, tails `sims/results/p5b/launch_log.txt`) is still armed and will fire on the relaunch's tranche boundaries.
