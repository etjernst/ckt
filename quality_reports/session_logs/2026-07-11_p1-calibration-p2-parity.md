# 2026-07-11 --- P1 calibration shipped; P2 parity diagnosed, certified, and at Emilia's decision branch

## If you resume

One-line state: stages P0-P1 of the extension simulation study are DONE and gate-passed; stage P2's point-estimate parity gate is FAILED-with-full-diagnosis, a well-posed estimator variant (`aux-direct`) is built and lands within 0.005-0.05 of production on headline parameters, and the open thread is EMILIA'S DECISION between descoping exact parity by spec amendment and extending the reconciliation (plan decision B / D6 branch).

Read first, in order:
1. [sims/output/p2_parity_notes.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/output/p2_parity_notes.md) on the worktree --- the complete parity record: what is certified, what is solved, the irreducible finding, and the two branches.
2. The plan: [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md) (P2 stage and decision B).
3. The parity tables: `sims/output/p2_sanity_*_comparison*.csv` on the worktree (suffix `_thr0_stata_aux_direct` is the current best variant).

Worktree: `C:/git/ckt/.claude/worktrees/extension-sims`, branch `worktree-extension-sims`, tip `8a59016`.
Commits today: `2febbfb` (P1), `fb10153` (first parity measurement), `8ef519f` (threshold-0 rerun + diagnosis notes), `8a59016` (reconciliation: certified formulas, invsym sweep, LM-GN, aux-direct variant).

If Emilia chooses descope (my recommendation, stated in chat): amend the spec's Verification bullet by explicit spec edit (document the real-data parity table as the check, adopt `stata_twosep + initials="aux-direct"` as the simulation estimator), then proceed to P3 (DGP and truth module).
If she chooses extend: next lever is replicating Stata's `quickderivatives` numerical-derivative noise and Mata optimize's exact stopping, which the notes argue is brittle; budget accordingly.
Either way the SE(phi) time box (BLOCKER item A) remains open in P2; the certification result (Stata's e(W) plugged into the port's sandwich reproduced SE(phi) exactly, per FINDINGS_SE_phi.md point 5) means the aux-direct variant's SEs should be re-measured against production before ruling.

## Mode

Implementation (plan-governed, stages P1-P2 of the approved extension-simulation plan).

## What happened, in order

### P1 (late evening 2026-07-10, committed 2febbfb)

- `export_ster_b.do` dumps the full production cuu_ca coefficient vectors read-only into worktree configs (gotcha re-learned: Git Bash mangles Stata's `/e` flag into a path; use `-e`).
- Key semantics pinned: headline spec is `cuu_ca` (period FE + female age2 education_max education_max2 + U + U*D); `mu_d_ster` is the covariate-consistent model mean; the lumped cell's level is directly `xb:unbalanced`; kappa is E[theta|always]; Delta_always = beta + phi*(kappa - mu_base).
- `calibrate.py` (sonnet subagent, reviewed): snapshots both designs to gitignored parquet, hard-asserts counts/mu/scalars against the exporter CSVs (all passed exactly), fits AR(1)+permanent variance components from auxiliary-OLS residual autocovariances.
- Calibrated components: IDN sigma_theta 0.355, sigma_eps 0.619, rho 0.223 (overidentified, 5 lags); TZA 0.421, 0.420, 0.088 (exactly identified at T=3, no fit diagnostic).
- P1 gate PASSED both cells: zero-noise panel reproduces every cell count, share, rural mean, urban-mean-net-of-Delta (lumped cell included, check added in review), and the always-cell level to 1e-9.

### P2 sanity fits (post-midnight, approved by Emilia "just kick them off")

- First run (port defaults): gate FAIL both cells; covariate block matches production to 1e-3/1e-4 but the GMM structural block diverges (IDN phi -0.707 vs -0.525; TZA on the phi=-1 ridge, kappa 42); port J collapses to ~0 vs production 28.17/3.83.
- Discovery: tonight's output is digit-identical to the April 24 archived "sparsedrop" run, and the recorded "matches Stata to 0.003" validation was the NO-COVARIATE spec only; cuu_ca parity had never been measured.
- Threshold-0 rerun: still FAIL; the sparse-moment drop is not the binding difference.
- Root cause one: production `run_grc` is Stata-default TWO-STEP gmm (winitial unadjusted, W2 fixed, from() initials, phistart -0.1); the port iterates W to a fixed point, which drives J toward zero and lets (phi, kappa) wander the ridge.

### P2 reconciliation (morning, Emilia: "let's add Stata protocol")

- `stata_twostep` mode built in the worktree `grc_gmm.py` (hash re-recorded in the README; iterated default path untouched).
- Certification (the decisive experiment): dumped e(W) and evaluated the port at Stata's exact theta-hat under Stata's exact W; J reproduces to 6 significant figures both cells; GN from theta_stata moves at most 0.002.
- Solved: J df rule (invsym sweeps the one-cluster switcher LEVEL moment out of the singular S; df = kept - params; explains e(J_df) = m - p - 1 exactly); the pinv-vs-invsym mechanism; initials and W1 verified via matching iteration-0 criterion (118.056 vs 118.059).
- Irreducible: the criterion admits degenerate near-exact roots (step-1 Q to 1e-17); Stata's estimates are where its GN + quickderivatives stalls; pure GN, LM, and Stata-tolerance stopping each fail to track the trajectory (first steps already diverge on the ill-conditioned normal matrix).
- The variant that works: `initials="aux-direct"` (saturated-auxiliary-OLS warm start, no step-1 minimization, W2 evaluated at the consistent initials, LM-damped step 2).
Results: TZA all params within 0.0193 (phi 0.005, J 3.87 vs 3.83); IDN Delta_base/Delta_never within 0.007, kappa 0.023, phi 0.052, J 28.96 vs 28.17 at df 27 both, worst thin-cell mu 0.44.
Runtime ~1 min per IDN fit (vs 16 iterated), which would cut the P5a full-run compute estimate substantially.

## Decisions, with the why

- Adopted Stata's e(W)-dump certification as the parity anchor rather than chasing point equality first, because it separates "formulas differ" from "optimizer path differs" in one experiment; it came back formulas-exact.
- Chose aux-direct warm start over replicating Stata's solver because one local step from root-n-consistent initials is the classic asymptotically-efficient construction, it is well-posed and per-replication computable, and exact trajectory replication would enshrine quickderivatives' numerical noise as the estimand.
- The literal 1e-3 gate failure is NOT being papered over: the branch (descope by spec amendment vs extend) is pre-assigned to Emilia by plan D6 and is presented in chat with a recommendation (descope).

## Paper-relevant flag

The production phi-hat sits at a solver-selected point in weakly identified directions; well-posed variants land at -0.53 to -0.59 (IDN) against the production -0.525, and the criterion admits degenerate near-zero-J roots at extreme theta.
The paper's inversion-CI-first inference already covers this conceptually, but a referee re-implementing the GMM would get slightly different point estimates; worth a disclosure sentence in the simulation appendix, and worth Emilia knowing before ECMA submission.

## Files changed (all on the extension-sims worktree unless noted)

- [sims/src/export_ster_b.do](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/export_ster_b.do), [sims/src/_probe_ster_scalars.do](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/_probe_ster_scalars.do), [sims/src/_dump_ster_W.do](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/_dump_ster_W.do) --- one-time read-only Stata dumps.
- [sims/src/config.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/config.py), [sims/src/calibrate.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/calibrate.py), [sims/src/dgp.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/dgp.py), [sims/src/check_p1_gate.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/check_p1_gate.py) --- P1.
- [sims/src/grc_gmm.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/grc_gmm.py) --- stata_twostep mode, _invsym_ginv, LM-GN, initials options; md5 re-recorded in [sims/README.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/README.md).
- [sims/src/p2_sanity.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/p2_sanity.py), [sims/src/p2_certify_W.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/p2_certify_W.py) --- parity drivers.
- [sims/output/p2_parity_notes.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/output/p2_parity_notes.md) --- the parity record; plus comparison CSVs and the calibration report under sims/output/.

## Open items

- EMILIA: the P2 branch decision (descope vs extend), presented in chat 2026-07-11 morning.
- SE(phi) time box: re-measure the aux-direct variant's SEs against production (e(V) dump exists for c0 only; cuu_ca would need a small ster dump like the W one).
- The inversion-CI leg of P2 (arm-two machinery parity) has not run yet; it is independent of the GMM parity question since it runs off the auxiliary OLS.
- Carried over: hukou stub footnote (Emilia), `11b_extrapolation_support_figure.do` wiring into 0_master.do (Emilia), server-compute investigation feeding P5a (Emilia).
