# 2026-07-13 --- P7 split-fit leg, simulation-methodology review, P5b launch-pause-fix cycle

## If you resume

One-line state: the two production changes (Change A sample restriction, Change B switcher-inclusion consistency) are specced, econ-reviewed, and revised; a full-pipeline adversarial code review ran and its 14 CRITICALs are verified and triaged into a fix batch; nothing is running; no new docs are committed.

Read first: this log end to end, then the verdicts doc [2026-07-13-critical-findings-verdicts.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-critical-findings-verdicts.md), the switcher spec [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) and its plan [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md), and the parallel-launcher plan [2026-07-13-parallel-master-orchestrator.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-parallel-master-orchestrator.md).

Open thread: implement one combined fix batch in the Stata code (Change A + Change B + the verified code bugs), then build the six-lane parallel launcher, then do one definitive full-pipeline re-run into a fresh output dir, then rebuild the extension simulation and re-certify P2 parity, then freeze and switch to writing only.

Next concrete action: implement the fix batch.
Start with the per-capita outcome fix at the source (make handle_depvar build lndepvar = log(depvar/hhsize_cube) once, in 0_programs.do, so every script inherits per-capita and the scattered replaces become redundant).
The batch also includes: Change A (recompute unbalanced in handle_balance so strict-spec-incomplete individuals leave the balanced cells, keeping their valid waves), Change B (one switcher keep-set authored in Stata, consumed by GMM/exporter/Python; VV path counts clusters at threshold two), and the code bugs C3 (hukou Panel-A-Indonesia mislabel, 0_programs.do:1115/1123), C5 (two scripts overwrite cluster_comparison_consumption_unb.tex; make 17b the sole producer and add to 0_master.do), C10 (redefine switcher in the unbalanced sample by observed movement, not full trajectory), and C12 (add the constant-sample statement to the generated table notes).
Also build both a balanced-only and a full-sample version of the trajectories figure (C2) to compare.

Cached state worth knowing: nothing is running.
The full-pipeline review ran as workflow wf_5bca9072-a88 (67 findings: 14 CRITICAL, 30 MAJOR, 23 MINOR), consolidated at [2026-07-13-full-pipeline-review-findings.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-full-pipeline-review-findings.md).
Only the 14 CRITICALs were verified (workflow wf_e97548dc-42b) and triaged; the 30 MAJOR and 23 MINOR are NOT yet verified or triaged, which is an open item.
The main analysis is nominal-values Stata; the canonical paper file is now main-updated.tex (user, 2026-07-13), superseding main-sections.tex; memory was updated.
Six new docs from this session are uncommitted: the switcher spec and plan, the three review docs (adversarial-review plan, consolidated findings, critical verdicts), the parallel-launcher plan, and the git-versionable-estimates memo.
The user is fixing the hidden /review-plan skill config herself (disable-model-invocation plus an archive duplicate).
P5b and the simulation hash freeze remain held behind the definitive re-run.

---

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

## Continuation (2026-07-13 midday): switcher spec+plan, econ review, parallelization plan, pipeline review launch

This block covers the fresh-context session that wrote the switcher-inclusion spec and plan, put them through an econometrics critic, then branched into pipeline-speed and code-review planning.

### Goals

Emilia's asks, in order: pick back up and write the spec then plan for the switcher-inclusion consistency change; fold in three decisions (merge the sample fix into one spec, Stata single source of truth, looser VV threshold); "/review-plan" (skill is hidden from me by `disable-model-invocation`, so I ran critic-econometrics instead); apply the four review decisions; answer whether anything forces an early re-run and whether to port the pipeline to Python; explain the shorthand (P5b, Change A/B, JIT); find the old parallelization spec and scope the work; version the `.ster` before a clean re-run and think about a git-friendly results format; launch an adversarial full-pipeline code review farmed out one script per agent; cap the parallel run at 6 instances.

### What got written

Combined spec [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md): Change A (individual-level strict-spec sample restriction, lumping the 29 incomplete IDN individuals into the unbalanced cell) plus Change B (one switcher-inclusion rule across GMM, aux OLS, inversion), sequenced A-then-B at the final re-run.
Plan [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md): Design 2 (a Stata-authored keep-list artifact consumed by GMM, exporter, and Python), plus a "Review resolutions" section.
Critic report [2026-07-13-switcher-inclusion-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-switcher-inclusion-plan-review.md): 1 CRITICAL (downgraded), 7 MAJOR, 4 MINOR.
Adversarial-review farm-out plan [2026-07-13-full-pipeline-adversarial-review.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-full-pipeline-adversarial-review.md).
Parallel-master plan [2026-07-13-parallel-master-orchestrator.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-parallel-master-orchestrator.md).
Tool-concept memo [2026-07-13_git-versionable-stata-estimates.md](file:///C:/git/ckt/docs/notes/2026-07-13_git-versionable-stata-estimates.md).

### Decisions, with the why

Merge the sample fix and the switcher rule into one spec (DA1): they share the final re-run and interact (the sample fix must precede the keep-set, because the incomplete individuals are the only ones for whom the symmetric both-states count differs from cell size).
Stata authors the keep-set once, Python consumes it (D6): removes any two-language drift; the VV-path conflict rules out baking the lump into the `.dta`.
VV threshold set to two clusters in both states, looser than the main path's five individuals (D7): five clusters would empty most thin trajectories; swept in the robustness check anyway.
Lump the 29 incomplete individuals rather than delete them (DA3, after review finding M4): a full `drop` discards ~116 valid person-waves and contradicts the never-discard principle; recompute `unbalanced` in `handle_balance` instead.
Accept the VV switcher-set confound rather than re-run VV on the main-path set (D8, after M6): VV is already a robustness check; disclose that its set differs.
No Python port of the estimation: verified it is not faster (IDN cell, Stata 616.9 s vs Python 975.9 s, ~1.6x slower, [BLOCKER.md:73](file:///C:/git/ckt/.claude/worktrees/verdier-fresh/explorations/python-grc/BLOCKER.md)); the bigger blocker is that the replication package and the coauthors are Stata-only.
Parallelize Stata instead, capped at six concurrent instances (user): keep `0_master.do`, add a launcher that cleans once, fans estimations across six lanes with `${skip_if_exists}`, writes to a fresh output dir, assembles once.
Do not git-track the 310 binary `.ster` (gitignored because binary/undiffable); version results by exporting their contents to text.

### Verifications that moved review findings

C1 (estimand equivalence) downgraded to wording: [lca_inversion.py:419](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) `grid_delta_avg_md_inversion` targets the same LCA-line share-weighted form as the GMM, not an unrestricted-beta average; residual point is that under LCA rejection the inversion can return an empty CI while the GMM forces a number.
M5 (clustering mismatch) dissolved: [5b_inversion.do:145](file:///C:/git/ckt/RP7/scripts/5b_inversion.do) passes `hhid(pid)`, so the aux OLS and inversion cluster and count on `pid`, matching the GMM's `vce(cluster pid)`.
Verified counterpoint from the critic carried into the plan: because `unbalanced_choice` is a free just-identified absorber, the lumping cannot bias phi or the extrapolated returns; exposure is in claims and validation apparatus (report Hansen J before/after; pin the base trajectory across runs).

### Approaches rejected, with the reason

Using the hidden `/review-plan` skill directly: it carries `disable-model-invocation: true`, so it does not appear in my skill list and I cannot invoke it; ran critic-econometrics (what it would have dispatched anyway). Emilia is fixing the config herself; there is also a duplicate `review-plan` in `~/.claude/skills/archive/` with the same `name:`, a latent collision.
Iteration-capping the Python GMM to speed the sim: it changes the estimate and would break P2 parity; JIT (numba/JAX) is the parity-safe speed lever if the sim needs one.
Running all twelve parallel slices at once: caps the machine; six-lane rolling pool instead, longest slices first.

### Open items

Adversarial full-pipeline review is RUNNING in the background: Workflow run `wf_5bca9072-a88` (task `wpiq2sqik`), 15 agents (sonnet, high effort), one script each, checking code against the paper and against Change A+B.
On completion, consolidate and triage the findings into a review report under `quality_reports/reviews/`, adversarially escalating any uncertain CRITICAL/MAJOR to a fresh verifier before anything reaches a fix list.
Change A+B is specced and planned but NOT implemented; implementation lands at the definitive re-run.
The parallel launcher is planned but NOT built; pre-reqs are a read of `9_GRC_extras.do` block structure and the per-instance log globals.
Pending Emilia decisions: whether to add TODO entries for the near-term full-CSV results export and the longer-term JSON estimate-serialization tool; she already OK'd the fresh-output-dir versioning approach.
None of these six new docs are committed yet.

### How to pick back up

The immediate next event is the pipeline-review Workflow finishing; consolidate its findings first.
Then the standing sequence: implement Change A+B, let the adversarial review clear, build the six-lane parallel launcher, run the definitive pipeline once into a fresh output dir, rebuild the sim and re-certify P2 parity, then freeze and move to writing only.

## Continuation (2026-07-13 afternoon): full-pipeline adversarial review, CRITICAL verification, fix-batch decisions

### Goals

The user's afternoon asks, in order: whether anything in the switcher plan forces an early re-run (answer: no, the old baseline is the committed sters); whether to port the estimation pipeline to Python for speed; explain the shorthand (P5b, Change A/B, JIT) in plain terms; find the earlier parallelization spec and scope the work; version the .ster files before a clean re-run and think about a git-friendly results format; launch an annoyingly-detailed adversarial code review of the whole pipeline, farmed out one do-file per agent, to make sure the code is correct; search the Stata universe for whether the git-versionable-estimates tool already exists and review the .ster documentation for uses a JSON round-trip could not replicate; verify the per-capita discrepancy directly; run a verification pass on all the CRITICAL findings; decide the fixes; wrap up.

### What got built or changed

- [2026-07-13-parallel-master-orchestrator.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-parallel-master-orchestrator.md): parallel-launcher plan, six-lane concurrency cap, fresh output dir.
- [2026-07-13-full-pipeline-adversarial-review.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-full-pipeline-adversarial-review.md): the one-script-per-agent review farm-out.
- [2026-07-13-full-pipeline-review-findings.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-full-pipeline-review-findings.md): 67 consolidated findings.
- [2026-07-13-critical-findings-verdicts.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-critical-findings-verdicts.md): the 14 CRITICAL verdicts plus the decided fix approaches.
- [2026-07-13_git-versionable-stata-estimates.md](file:///C:/git/ckt/docs/notes/2026-07-13_git-versionable-stata-estimates.md): the tool concept, with prior-art and .ster-parity findings.
- [docs/TODO.md](file:///C:/git/ckt/docs/TODO.md): added a per-capita-description paper-update entry.
- Memory files [reference_overleaf_paths.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_overleaf_paths.md) and [MEMORY.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/MEMORY.md): main-updated.tex recorded as canonical.

### Decisions, with the why

- Do not port the estimation pipeline to Python.
  Why: verified not faster (IDN cell, Stata 616.9 s vs Python 975.9 s, ~1.6x slower, BLOCKER.md:73), and the replication package plus the coauthors are Stata-only.
- The Python speedups are relevant only to the simulation, and JIT is the parity-safe lever.
  Why: capping iterated-GMM iterations changes the estimate and would break P2 parity, while JIT (numba/JAX) is the same math compiled.
- Parallelize the Stata run with a separate launcher, capped at six concurrent instances.
  Why: keep 0_master.do canonical, run clean-once then fan-out then assemble, and six lanes leave the laptop headroom; the skip_if_exists idempotence lever already exists in run_grc.
- Version results by a fresh output dir plus a snapshot, not by git-tracking the sters.
  Why: the 310 sters are binary and undiffable (gitignored on purpose); the git-friendly path is exporting their contents to text, which is a real unfilled niche (estwrite owns rich binary storage including e(sample); jsonio serializes data not estimates; per the manual a .ster restores all of e() except e(sample), so a full-namespace JSON round-trip reaches parity).
- main-updated.tex is the canonical paper file.
  Why: user stated it 2026-07-13; it is a single consolidated manuscript superseding the sectioned main-sections.tex build.
- Fix the per-capita outcome at the source in handle_depvar, not in three scattered scripts.
  Why: building lndepvar = log(depvar/hhsize_cube) once kills the whole drift class and stops a future script forgetting the transform.
- C2 trajectories figure: build both a balanced-only and a full-sample version and compare.
  Why: it is unclear which sample the figure should show, so produce both before deciding.
- C10 non-switcher count: in the unbalanced sample define a switcher by observed movement (both a choice-0 and a choice-1 round across observed waves), not by the balanced-only trajectory; in the balanced sample keep trajectory-based classification and exclude unbalanced individuals.
  Why: this gives the overall-sample "never move" count using the less-strict observed-switching sense, and correctly handles individuals seen in fewer than the full waves.
- C12 education drop is by-design (constant sample across columns), so add the constant-sample statement to the generated table notes.
  Why: the drop holds the sample at the most restrictive column, which is intended and defensible, but the verifier could not find the disclosure in the paper, so make it explicit.
- Queue the fix batch (C1, C3, C4, C5, C6, plus C10 redefinition, C2 two-figure, C12 table-note) alongside Change A and Change B for the single definitive re-run.
  Why: fix the code once, re-run once, then the stale-paper prose edits follow with final numbers.

### Verification outcome

The 14 CRITICALs verified as 7 code bugs, 6 stale-paper, 1 by-design, 0 refuted, all high confidence.
Code bugs: per-capita on OLS (C6), hukou-OLS (C4), and the heterogeneity figure (C1); hukou Panel-A-Indonesia mislabel (C3); the non-switcher miscount (C10); the two-scripts-overwrite-one-table clash (C5); the balanced-only trajectories figure (C2).
Stale-paper: the OLS 6-vs-7 column narrative (C7), the GRC nonexistent time-trend column (C8, C14), the Delta-never numbers matching archived pre-refactor tables (C9), the rural-first hukou stale J-column (C11), and the CHN GRC table never regenerated after the 2026-07-01 four-column refactor (C13).
By-design: the education drop (C12).
Independent confirmation from a direct grep: every GRC-family script overwrites lndepvar with log(consumption/hhsize_cube) while 3_OLS_uGRC.do, 6_OLS_uGRC_hukou.do, and 11_make_figures.do do not, so the OLS, hukou-OLS, and figure outcomes are raw household consumption.

### Approaches rejected, with the reason

- Porting the estimation to Python: the speed premise is false and it forks the pipeline from the Stata-only coauthors.
- Git-tracking the sters: binary and undiffable, which is why they are gitignored.
- Fixing per-capita in three scattered scripts: the source fix in handle_depvar is cleaner and drift-proof.
- Launching P5b or the parallel run now: both wait until the fix batch and the definitive re-run.

### Open items

- Implement the combined fix batch; none of it is coded yet.
- Verify and triage the 30 MAJOR and 23 MINOR review findings; only the 14 CRITICALs were verified.
- Build the parallel launcher; pre-reqs are a read of the 9_GRC_extras block structure and the per-instance log globals.
- After the re-run: rebuild the sim, re-certify P2 parity, freeze, then do the stale-paper prose edits (C7, C8, C9, C14) on main-updated.tex with final numbers.
- Confirm the C12 constant-sample disclosure is added to the table notes.
- Commit the six new session docs (currently uncommitted); decide whether to add TODOs for the full-CSV results export and the JSON estimate-serialization tool.
- The user is fixing the /review-plan skill config herself.
