# 2026-07-13 --- P7 split-fit leg, simulation-methodology review, P5b launch-pause-fix cycle

## If you resume

One-line state: the extension-simulation code is stable and committed; P5b is held (not running) by deliberate choice; the next action is to write a spec and a plan, in fresh context, for making the switcher-inclusion rule internally consistent across the estimators.

Read first: this log end to end, then the three new pre-submission entries in [docs/TODO.md](file:///C:/git/ckt/docs/TODO.md).

Open thread: two production methods changes are queued for the final pre-submission full pipeline re-run, and both change the estimand and break P2 parity, so each needs a spec and a plan, then the re-run, then a sim rebuild and a parity re-certification.
First, exclude individuals missing household size on the strictest specification: an individual missing `hhsize_cube` in any wave should not be in the sample at all, not merely have that one wave dropped.
Second, make the switcher-inclusion rule identical across the GMM, the auxiliary OLS, and the inversion.

Decided baseline for that second change, locked 2026-07-13: keep a switcher trajectory if and only if it has at least five unique individuals observed in both an urban period and a rural period; apply it identically in all three estimators; the GMM moves from `sparse_moment_threshold=0` to this rule.
Individuals in a dropped sparse trajectory get lumped into the unbalanced cell (trajectory -1), not deleted.
Count by individual on the main specification and by cluster (village) on the Verdier-robust path.

Next concrete action: write the spec, then the plan, for the internal-consistency change (the switcher-inclusion rule), per the workflow, in fresh context.
Emilia asked for this to happen after wrap-up, in a new session.

Cached state worth knowing:
P5b is held, not running.
Relaunching now would validate the current inconsistent procedure that we have already agreed to revise, so relaunch only after the consistency change ships, so that P5b validates the version that actually gets submitted.
The sim code is stable at the extension-sims worktree tip.
Worktree commits this session: `44ae12a` (P7 split-fit leg), `4225bf0` (appendix disclosures), `d793f01` (review fix batch, 13 fixes, 36/36 tests).
Main-tree commits this session: `9aaaa62` (first session log), `ce24063`, `339a188`, and `0eaa72d` (the three TODO entries).
The stale pre-fix P5b batches still sit in [sims/results/p5b/](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/results/p5b/); a move to shelve them failed on a transient permission error, not on anything in our own process.
On relaunch, write to a fresh output directory rather than reuse that one.
The 24 Python processes on the machine are MCP servers plus Emilia's own `bednets_application.py` run, active since July 9 with four workers; none of them are ours.
Emilia is investigating the rogue bednets run herself, so leave it alone.
Once both production changes land, P2 parity needs re-certification before any simulation hash freeze.

Worktree: [C:/git/ckt/.claude/worktrees/extension-sims](file:///C:/git/ckt/.claude/worktrees/extension-sims), branch `worktree-extension-sims`, tip `d793f01`, clean.

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

## Continuation (2026-07-13 morning): sample-fidelity investigation and the internal-consistency decision

This continuation covers the morning of 2026-07-13, after the first log entry above closed.
It resolved the open `Delta_avg_kept5` question from that entry's hand-off, and the resolution turned into a sample-fidelity finding plus a methods decision about the switcher-inclusion rule.

### Goals

Emilia's asks, in order: assess the pedrohcgs `sim-reviewer` agent for reviewing this work and for possible adoption; "yes proceed with the fixes, what will we do about the TZA singleton?"; a sharp challenge to a subagent's explanation, "how is this possible? a trajectory is defined by e.g. 01011"; fix the sample issue in production, but not now, at the final re-run; "add the robustness checks to the to-do list; is our drop-if-less-than-five reasonable; how come TZA still has a singleton?"; "make everything internally consistent first; symmetry probably makes sense; the GMM should be consistent, no coauthor decision needed, re-run is fine"; a request to recommend a baseline rule plus a robustness sweep; "lump dropped-trajectory people with unbalanced; do the spec and plan after wrap-up in fresh context."

### The Delta_avg_kept5 question resolved, and it was not a weighting choice

Direct investigation of the sim design and the production source data found the real mechanism, and it was not a weighting choice.
Emilia challenged a subagent's claim that IDN switcher trajectories mix individuals observed for 4 and 5 periods.
In the production source `RP7/data/processed/IDN_unb.dta`, every balanced individual has a full five waves, exactly as Emilia expected.
The sim's design-build at [calibrate.py:100-104](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/calibrate.py) drops person-period rows where log per-capita consumption is non-finite, then never recomputes the balance flag, so 29 IDN individuals lose one wave each and end up flagged balanced with only four waves.
The trigger is a missing `hhsize_cube` (the per-capita denominator) in one wave for those 29 people; consumption itself is present.
The production `unbalanced` flag is computed at [0_programs.do:321](file:///C:/git/ckt/RP7/scripts/0_programs.do) before the outcome restriction, and the production estimation uses a row-level `regression_sample = e(sample)` from the strictest column at [0_programs.do:1287](file:///C:/git/ckt/RP7/scripts/0_programs.do), so production keeps the same 29 individuals with four waves too.
This was verified decisively: the production exporter's per-trajectory `n_pids` in `RP7/output/counterfactual_inputs/IDN_e1_traj.csv` matches the design's person counts exactly, trajectory by trajectory, with the 29 included.
So the sim faithfully reproduces the production sample, and the earlier framing of a 2.6e-4 row-versus-people weighting gap was a symptom, not the root issue.

### What changed

A simulation-methodology review report at [2026-07-12_sim-methodology-review.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-07-12_sim-methodology-review.md): verdict FIX-BEFORE-FREEZE, zero critical findings, three major, eight minor, adapted from the pedrohcgs sim-reviewer rubric.
The review fix batch across the sim source and tests, worktree commit `d793f01`.
Appendix disclosures in [appendix_simulation.tex](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/appendix_simulation.tex), commit `4225bf0`.
Three new entries in [docs/TODO.md](file:///C:/git/ckt/docs/TODO.md), main-tree commits `ce24063`, `339a188`, and `0eaa72d`, covering the production sample fix, the internal-consistency methods change, and the robustness checks.

### Decisions, with the why

Fix the sample issue in production, not the sim, and defer it to the final pre-submission re-run.
The sim already matches production (the exporter `n_pids` includes the 29), so changing only the sim would break the calibrate `n_pids` assert at [calibrate.py:236](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/calibrate.py) and P2 parity; Emilia deferred the production change to the one final full re-run.

Keep the TZA singleton as a typed failure with no code special-case.
Conditional on the one individual being present, the split fit is unbiased for the regime-conditional truth, and special-casing a single-person trajectory would put a data-quirk branch into parity-certified code.

Make the switcher-inclusion rule internally consistent across the GMM, the auxiliary OLS, and the inversion.
Right now the GMM keeps every switcher at `sparse_moment_threshold=0` while the auxiliary and inversion estimators drop switchers with fewer than five treated individuals, so the GMM average return and the inversion average return are different estimands over different switcher sets; that is a referee poke point and a genuine inconsistency in the paper, not just in the sim.

Set the baseline rule at five, symmetric, applied consistently, with the GMM adopting it.
Five is the current production value, which keeps continuity, and it is a standard minimum-cell heuristic; the honest defense is the robustness sweep, not the specific number.

Lump dropped-trajectory individuals into the unbalanced cell rather than deleting them.
Never discard data, and the lumped cell already exists to absorb people who do not get their own trajectory parameter; Emilia confirmed this, and it needs disclosure because it shifts what `Delta_unb` estimates.

Hold P5b rather than relaunch it.
Relaunching now would validate the current inconsistent procedure that has already been agreed for revision, so it is better to validate the version that will actually ship.

### Approaches rejected, with the reason

Redefining the `Delta_avg_kept5` truth to row-share weights, the recommendation at the end of the first log entry above: retracted, because it treated the 2.6e-4 weighting gap as a clean choice when the root cause is the 29 incomplete individuals, and it would have masked the real sample question.
Changing only the sim to exclude the 29 individuals: it breaks the calibrate `n_pids` assert and P2 parity, and the sim must match the current production sample.
Treating the treated-only count in `drop_sparse_switchers` as an independent bug: verified empirically that every complete switcher-trajectory individual appears in both states, so the treated count equals the cell size, and the only asymmetry comes from the same 29 incomplete individuals and is cured by the sample fix; the symmetric wording stays anyway, as self-documenting insurance.
Random trajectory dropping for the robustness check: leave-one-trajectory-out is deterministic, interpretable, and enumerable, so it is preferred over random subsampling.
Force-deleting the stale P5b directory or force-killing the Python processes: the delete was correctly blocked by a safety guard, and the processes turned out to be MCP servers plus Emilia's own bednets run, so neither was ours to remove.

### Open items

Write a spec, then a plan, for the internal-consistency change to the switcher-inclusion rule, in fresh context, next session; Emilia asked for this to happen after wrap-up.
Land both production changes, the sample restriction and the consistency rule, together at the final pre-submission full pipeline re-run, followed by a sim rebuild and a P2 parity re-certification.
Keep P5b held; relaunch it after the consistency change ships so it validates the shipping procedure, and write to a fresh output directory because the stale batches in [sims/results/p5b/](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/results/p5b/) are transiently locked.
Emilia is investigating her own rogue bednets run; hands off.
The hash freeze stays deferred until P5b passes on the final procedure.
