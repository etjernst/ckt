# 2026-07-12 --- shock-scale multiplier, P4 pipeline + review, P5a pilot and compute memo

## If you resume

One-line state: P0-P4 (including P4b) are done and committed; the P5a pilot ran clean (60/60 replications, zero failures) and the compute-gate memo is committed; the session is paused at Emilia's three P5a decisions.
The decisions in front of Emilia, from [sims/docs/p5a_compute_memo.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p5a_compute_memo.md): venue (wait for server vs local at 12 workers), sensitivity-pocket R (1,000 / 500 / defer), and whether to spend a time-boxed day vectorizing the inversion (only relevant if local-only, and it forces a parity re-run because `lca_inversion.py` is parity-certified).
Claude's recommendation, delivered in chat: if the server is likely within a week, skip vectorization, run P5b locally now (~5.5 h at 12 workers, must include IDN two-regime, the untimed cell-arm), hold the full matrix for the server.

Next concrete action once Emilia rules: run P5b (R = 100 per cell over every execution path, including IDN two-regime, sensitivity pockets at reduced R, and the split-fit leg once P7 lands), then freeze code and config hashes.
Note that P7's split-estimation leg (two extra GMM fits per two-regime replication, on the true regime label) is NOT yet implemented in `run_one.py`; it is now trivially cheap (GMM is 6 s) and should land before or with P5b so the tranche covers it.

Worktree: [C:/git/ckt/.claude/worktrees/extension-sims](file:///C:/git/ckt/.claude/worktrees/extension-sims), branch `worktree-extension-sims`, tip `ffd7e78`, clean.
Worktree commits this session: `3085b47` (multiplier), `5dee220` (P4), `a009b74` (P4b fixes), the spec-amendment commit, `71dd586` (appendix draft), `aad6b3a` (metrics), `ffd7e78` (memo).
Main-tree commit: `b6d10b9` (plan decision C amendment).

## Mode

Implementation (plan-governed, stages P3-addendum through P5a of the approved extension-simulation plan), with Review mode for P4b.

## Goals

Emilia's asks, in order: "pick back up where we left off" (the shock-scale multiplier, then P4 per the handoff); "try again" (rerun of a truncated final summary); an explain request on the dial-zero reuse convention; the decision to drop the reuse coupling ("maybe we don't need to set it up so that we can reuse them"); "yes please make those amendments" plus a request to re-explain the China exclusion; "make sure we have this written up clearly... maybe we should start writing some things into the appendix now"; "let's go with 1 & 2 in sequence" (metrics layer, then pilot); "re-launch because I did not kill it, maybe try fewer workers"; "keep an eye on the computer's resources."

## What got built or changed

Urban shock-scale multiplier (commit `3085b47`), closing the last P3 item.
`calibrate.py` computes $m_U^2 = 1 + ((V_U - V_R) - ((1+\hat\phi)^2 - 1)\sigma_\xi^2)/\sigma_\varepsilon^2$, split solved first, multiplier absorbing the remainder, clamped below at 1; calibrated $m_U$ = 1.046 IDN, 1.128 TZA, no clamp binding.
Both DGP arms scale each person's AR(1) path by $m_U$ on urban rows only; check 3's urban variance target gained the $m_U^2\sigma_\varepsilon^2$ term and a mutation check confirmed an unscaled DGP fails by >6 MCSEs.

P4 (commit `5dee220`; sonnet subagent implemented from a main-thread brief, main thread reviewed the full diff).
[sims/src/run_one.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/run_one.py): one replication across four independently-failing stages (DGP, certified stata_twostep/aux-direct GMM at sparse threshold 0, auxiliary-OLS lumped coefficient, grid inversions) with typed fail_reason capture; GMM estimates mapped onto the base-invariant line with delta-method SEs; inversion coverage scored by evaluating the test at the truth via single-point grid calls with a two-stage refined nuisance-$\phi$ search; set reconstruction with adaptive grid expansion and topology classification, truncated sets never reported as completed confidence sets.
[sims/src/orchestrate.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/orchestrate.py): master seed 20260710, SeedSequence spawn keyed (cell, rep) so dial points share common random numbers; joblib fan-out; atomic parquet batches; idempotent resume; run manifest with source md5s.
The main thread caught and fixed one real defect in review: batches could straddle gaps in the rep sequence after a gappy resume, and the filename's [first, last] range would then falsely claim the gap as covered; fixed with contiguity-aware batching plus a unit test.

P4b review (commit `a009b74`; record at [quality_reports/reviews/2026-07-11_p4b-critic-python-harness.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-07-11_p4b-critic-python-harness.md)).
critic-python (sonnet, fresh context) returned APPROVED WITH FIXES, zero CRITICAL; coverage-vs-truth and estimand wiring verified clean.
Applied: shared phi grid between truth-evaluation and set reconstruction (F1); typed `nonfinite_pvalue_at_truth` (F2); never/always labels passed explicitly to RestrictedGRC (F4); row-count guards after DGP, GMM, and aux dropna (F5); explicit-rng requirement (F6); estimands.py and config.py added to manifest hashes (F7); canonicalized dial strings (F8); two-regime end-to-end tests (F9).
F9's test needed a correction to the reviewer's proposal: at dial > 0 the GMM's pseudo-true value is not the people-share WLS fit, so the test asserts estimate proximity only at dial 0 and truth-WIRING at dial 0.4 (bias under violation is a finding per M8, never a bug).

Dial-zero reuse dropped (Emilia's ruling; worktree spec commit + main-tree `b6d10b9`).
Spec 4.2/4.3, plan decision C, the orchestrator docstring, and the P4b review record all amended: arm one runs the Gaussian baseline as its own tranche; arm three runs all three dial points itself; the Gaussian-vs-mixture dial-zero contrast becomes a reported shape-robustness check.
Reason: the reuse was priced at 16 min/rep iterated GMM; at aux-direct speeds the saved tranche is ~50-70 core-hours, and the coupling cost a run-matrix landmine plus a mixture caveat on the headline table.

Appendix design draft (commit `71dd586`): [sims/docs/appendix_simulation.tex](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/appendix_simulation.tex).
Six subsections written final-candidate: questions, fixed-design DGP, calibration with the full fitted-constant ledger table (discharges Emilia's 2026-07-11 ad-hockery requirement), cell selection with the three-part China exclusion, the two-regime arm, estimation/scoring rules; results section is placeholders only, with the rule that no number enters except from `make_tables.py`.
The China rationale as re-derived for Emilia: pooled CHN J-rejects so no LCA-true calibration exists; rural-first duplicates IDN's stress dimensions; urban-first's unbounded $\phi$ region makes any single truth arbitrary (coverage would test the calibration, not the procedure); the hukou split enters the study through the violation arm's dial scale $g^* = 0.93$.

Metrics layer (commit `aad6b3a`; sonnet subagent, main-thread review).
[sims/src/metrics.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/metrics.py): bias/empirical-SE/RMSE with MCSEs over n_eff; coverage at 95/90 in conditional, unconditional (failures as misses), and [H/R, (H+F)/R] bound variants; model-SE calibration; inversion topology shares; J rejection rates nominal and size-adjusted against the dial-0 empirical critical value with no chi-squared fallback; failures and per-stage timing tables; hard integrity errors on duplicate keys, non-unique truths, and mixed master seeds.
[sims/src/make_tables.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/make_tables.py): main paper table and completion/failure audit table from summary CSV only, tabular-environment-only per the table-split convention.
25/25 tests pass.

P5a pilot and memo (commit `ffd7e78`).
Three tranches at R = 20: TZA baseline, IDN baseline, TZA two-regime at $g^*$; 60/60 replications, zero failures.
The first launch (10 workers) was killed externally ~15 min in; Emilia confirmed she did not kill it; relaunch at 6 workers completed; a 15 s resource sampler ran through the relaunch and shows 0.41 GB/worker peak with 4.4+ GB always free, so memory pressure is ruled out and the cause stays unknown; mitigation is chunked tranches plus idempotent resume, which the orchestrator already provides.
Headline pilot fact: the cost model inverted --- aux-direct cut the IDN GMM to 6 s and the inversion set-reconstruction is now 97 percent of per-rep cost (278 s IDN, 78 s TZA, violated DGP 1.30x).
Full core matrix ~470 core-hours; sensitivities +198; local at 12 workers ~1.6 days; 32-64-core server 8-16 h.

## Decisions, with the why

Dial-zero reuse dropped: see above; Emilia ruled after Claude recommended agreeing with her instinct.

The pilot's two-regime timing came from TZA only; IDN two-regime is extrapolated at the measured 1.30 factor and P5b must actually run it.

sims/results/ is gitignored because raw results are deterministic given the master seed; summary CSVs get committed deliberately at P8 when they feed the paper table.

The vectorization of the inversion sweep was flagged as an option, not done: `lca_inversion.py` is parity-certified, so any edit forces a parity re-run, and the optimization only pays if the study stays local-only.

## Approaches rejected, with the reason

Asserting bitwise equality of `phi_pooled` and `phi_hat` at dial 0 in the new two-regime test: the Delta truths nest bit-exactly but `phi_pooled` passes through `np.linalg.solve`, which carries last-ULP roundoff; relaxed to 1e-12.

The critic's proposed dial > 0 estimate-proximity test: the pooled GMM's pseudo-true value differs from the people-share WLS registry truth by construction, so proximity would fail on correct code.

Treating the 10-worker kill as OOM and rearchitecting: the resource trace showed tiny worker footprints, so only the worker count was reduced and chunked launches retained.

## Open items

Emilia's three P5a decisions (venue, sensitivity R, vectorization), then P5b.
P7's split-fit leg in `run_one.py`, ideally before P5b so the tranche covers it.
IDN two-regime has never run; P5b must include it.
Watch-items from the R = 20 preview (5pp MCSE, nothing conclusive): erratic GMM $\Delta_{d_T}$ point estimates against well-behaved inversion sets in both cells; J power at TZA's full dial (1/20 rejections at $J_R = 3$); IDN GMM Wald relative SE bias for $\phi$ at $-0.42$.
Carried over for Emilia: hukou stub footnote, `11b_extrapolation_support_figure.do` wiring, server-access request (in progress, feeds the venue decision).
Carried over for the paper: the solver-dependence disclosure sentence (spec M3) is drafted in the appendix; the appendix results section fills at P8.
