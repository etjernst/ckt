# 2026-07-11 --- P1 calibration shipped; P2 parity diagnosed, certified, and at Emilia's decision branch

## If you resume

One-line state: P0-P3 are effectively done, with P2 CLOSED and P3's spec, implementation, and calibration all committed.
The single open implementation item before P4 is the approved urban shock-scale multiplier, spec'd as an addendum in [sims/docs/p3_dgp_truths.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p3_dgp_truths.md) section 2.4.
The stage after that is P4, the per-replication pipeline (`run_one.py`) plus orchestrator, which also carries P3's deferred check 7.

Read first, in order:
1. [sims/docs/p3_dgp_truths.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p3_dgp_truths.md) --- the P3 DGP and truths spec; both DECISION items were resolved 2026-07-11 evening, and the not-yet-implemented shock-scale addendum sits in section 2.4.
2. [sims/output/p2_parity_notes.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/output/p2_parity_notes.md) --- the full P2 record, including the SE re-measure and the inversion-parity close-out sections.
3. [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md), stage P4.

Worktree: [C:/git/ckt/.claude/worktrees/extension-sims](file:///C:/git/ckt/.claude/worktrees/extension-sims), branch `worktree-extension-sims`, tip `f65c9b6`, working tree clean.
Commits this session: `d167538`, `77be113`, `7f1ef5e`, `fd56b39`, `b719c1a`, `cea5586`, `f65c9b6`.

Next concrete action: implement the urban shock-scale multiplier.
In `calibrate.py`, compute $m_U^2 = 1 + (V_U - V_R)/\sigma_\epsilon^2$, clamped below at 1, and emit it into the configs.
In `dgp.py`, scale each person's AR(1) $\epsilon$ path by $m_U$ on urban rows, preserving the correlation structure.
Extend check 3's urban/rural variance targets to match, then move on to P4: `run_one.py`, `orchestrate.py`, typed failure capture, and the parquet schema from plan M7.
Run the P4b critic-python review before the P5a pilot.

## Mode

Implementation (plan-governed, stages P1-P2 of the approved extension-simulation plan).

## Goals

Emilia's asks, in order: pick back up from the 2026-07-10 handoff (stage P1); a scope question ("we're not really running code anytime soon?"), answered no-heavy-compute-today; "how many fits do we need to run" (answered: 2 for P2, ~7,000/cell for the full study); "just kick them off" (the P2 sanity fits, post-midnight); and "let's add Stata protocol" (the morning reconciliation).

## Approaches rejected, with the reason

- Sparse-moment threshold 0 as the parity fix: rerun still failed; the drop was not the binding difference (the iteration scheme was).
- Naive two-step with L-BFGS-B + Nelder-Mead: stalls far above Stata's criterion (J 121 vs 28); the generic optimizer does not track Gauss-Newton on this surface.
- Pure full-step Gauss-Newton: slides past Stata's stopping point into a degenerate near-exact root (Q to 1e-17) because undamped steps jump basins on the ill-conditioned normal matrix.
- Levenberg-Marquardt from Stata's crude initials: early damped path diverges from Stata's giant clean first step, and the root still attracts once damping shrinks.
- Exact solver-trajectory replication (matching quickderivatives noise and Mata optimize stopping): judged brittle and wrong-headed as an estimand; kept only as the "extend" branch of Emilia's pending decision.
- pinv for W2 and the GN direction solve: retains near-null S directions with enormous weight instead of sweeping them; replaced by `_invsym_ginv`.

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

- RESOLVED 11:01: the P2 branch decision went to descope (spec amendment D7); see the resume block.
- SE(phi) time box: re-measure the aux-direct variant's SEs against production (e(V) dump exists for c0 only; cuu_ca would need a small ster dump like the W one).
- The inversion-CI leg of P2 (arm-two machinery parity) has not run yet; it is independent of the GMM parity question since it runs off the auxiliary OLS.
- Carried over: hukou stub footnote (Emilia), `11b_extrapolation_support_figure.do` wiring into 0_master.do (Emilia), server-compute investigation feeding P5a (Emilia).

## Evening session (11:30-22:00): P2 closed, P3 spec + implementation, calibration rulings

### Goals

Emilia's asks, in order: "pick back up where we left off," meaning finish P2 (the SE($\phi$) re-measure and the inversion-CI parity leg); "Let's go," meaning start P3; evening rulings on the two open P3 decisions; "Ok sure let's try the shock-scale multiplier though I worry that it's going to start seeming like a lot of ad hoc stuff"; and a wrap-up.

### What got built or changed

SE($\phi$) re-measure, closing BLOCKER item A (commit `d167538`).
[sims/src/_dump_ster_V.do](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/_dump_ster_V.do) dumps production $e(V)$ from the `cuu_ca` sters into `configs/{IDN,TZA}_ster_V.csv` plus name files.
[sims/src/p2_se_compare.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/p2_se_compare.py) merges production SEs, computed as $\sqrt{\mathrm{diag}(e(V))}$ plus a delta-method SE for $\Delta_{never}$ built from Stata's own $\theta$ and $V$, into the aux-direct parity tables, writing `sims/output/p2_se_{IDN,TZA}_comparison.csv`.
The first pass reconciled IDN (SE($\phi$) ratio 0.945) but collapsed TZA (SE($\phi$) ratio 0.128, $\kappa$ ratio 0.020).
The root cause was that the `stata_twostep` sandwich bread used `_robust_inv`, a pinv with rcond $10^{-10}$; TZA's $G'W_2G$ has condition number $1.3\times10^{11}$, so pinv truncated exactly the weakly identified directions the sandwich needed to report.
The fix, in [sims/src/grc_gmm.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/grc_gmm.py), swaps the bread to a symmetrized `_invsym_ginv`, matching Stata's own `invsym`, and touches only the VCE, not the point estimates.
Final port-to-production ratios: SE($\phi$) 1.005 TZA / 0.973 IDN; $\Delta_{never}$ 1.004 / 1.008; $\Delta_{base}$ 1.002 / 1.042; $\kappa$ 1.042 / 1.158, with a single residual outlier at IDN's one-person switcher cell `mu:switcher_11` (ratio 0.19, a swept one-cluster direction, not a reported parameter).
The historical 2.75x SE($\phi$) gap recorded in BLOCKER.md item A turns out to have been pinv-versus-invsym in two places, $W_2$ and the bread, never a formula error, so the GMM-Wald coverage rows are now reportable in the study per plan decision B.
A companion fix removed a spurious requirement that `converged_` see step-1 iterations under `initials="aux-direct"`, since step 1 is skipped by design there; left alone it would have polluted per-replication failure typing.
`grc_gmm.py`'s md5 was re-recorded in [sims/README.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/README.md) as `85298a3b9e90813fb0823962e9071013`.

Inversion-CI parity leg, closing P2 (commit `77be113`).
[sims/src/p2_inversion_parity.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/p2_inversion_parity.py) runs the worktree's `compute_all_inversion_cis` on the P1 design snapshots with the production `covs_all` controls, checked against the production summaries in `C:/git/ckt/explorations/python-grc/results/` (`lca_inversion_three_countries_summary.csv` and `delta_inversion_three_countries_summary.csv`, `covs_all` rows).
All 42 compared quantities matched in both cells: the $\phi$ point at the Wald minimum, the Wald minima to 1e-6 relative, the 90/95 hulls for $\phi$, and the point, Wald minimum, 95-hull, and island count for $\Delta_{never}$, $\Delta_{avg}$, and $\Delta_{always}$, including the two-island unbounded $\Delta_{always}$ sets in both cells.
The output table is `sims/output/p2_inversion_parity.csv`, and `p2_parity_notes.md` gained a close-out section: with D7, the exact-J certification, the parity table, the SE re-measure, and this leg, every P2 item is now closed.

P3 spec (commits `7f1ef5e`, `fd56b39`): [sims/docs/p3_dgp_truths.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p3_dgp_truths.md) writes out the complete DGP mathematically before any coding.
The baseline arm gives person effect $a_i = \tau_i + \theta_i$ (comparative plus absolute advantage) and individual-level returns $\Delta_i = \beta + \phi\theta_i^*$ on the LCA line, with AR(1) transitory shocks; section 2.3 works through why the GRC moments hold, via cell-mean centering, the LCA restriction inducing that centering at the cell level, and independence from the fixed design.
The truths and estimand registry pins a base-invariant line $\Delta_d = a^* + \phi\mu_d$ (the estimator auto-selects its base per replication, so estimates get mapped before scoring); records that the GMM $\Delta_{avg}$ and the inversion $\Delta_{avg}$ are different estimands, since the GMM side averages the full switcher set and the inversion side drops sub-5 switchers and renormalizes; and derives $\Delta_{unb}$ weighting-invariance from design-measurable weights plus a common conditional mean.
The two-regime arm sets logistic regime shares in $\mu_c$, mean-preserving regime means $m_{c,r}$, and variance-preserving $\sigma_c^2$, so the dial moves only the LCA violation and never the noise level; $\phi_r = \phi \pm g/2$ pivots at the base mean; the arm nests the baseline exactly at dial zero; and the violation residual, the deviation of pooled truths from the people-share WLS fit in $\mu_d$, is linear in $g$.
The dial scale $g^* = 0.93$ comes from the CHN hukou tables' full-covariates column ($\phi$ $-0.039$ rural-first versus $-0.973$ urban-first).
The spec also carries a curvature stub, eight unit checks, and the F-adjustment math for P9: CR2 plus HTZ (Pustejovsky-Tipton 2018 and the 2023 corrigendum) implemented headless in Python, superseding the 2026-05-01 `reg_sandwich` Stata route, with the profiling rule pre-committed (evaluate $\nu$ at the minimizing $\phi$ per grid point, non-contiguity fallback carried over) and the exact $\nu$ formula deliberately left uncoded from memory, to be transcribed from the corrigendum and cross-checked against R's clubSandwich HTZ at $q \ge 2$.

P3 implementation (commit `b719c1a`; a sonnet subagent implemented it, the main thread reviewed the full diff).
[sims/src/estimands.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/estimands.py) is new: every registry truth is a deterministic function of `CellConfig`, including the two-regime functions ($\lambda_1$, $m_{c1}$/$m_{c2}$, $\sigma_c^2$ with a positivity guard added in review) and the pooled/split truths, violation residual, and pooled WLS fit.
[sims/src/dgp.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/dgp.py) was refactored around a single `simulate()` entry point over arms `baseline`/`two_regime`/`curvature` (stub); the regime label is recorded, and truths always come from `estimands.py`.
[sims/src/config.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/config.py) gained optional `s_ca`/`eta`/`h` fields, defaulting to `None`, with each arm raising rather than silently defaulting.
[sims/tests/test_dgp.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/tests/test_dgp.py) is new: it covers spec checks 1, 3, 4, 5, 6, and 8 with hand-derived literals and MCSE-derived tolerances, plus a violation-sensitivity leg where check 4 must fail on a deliberately pattern-heterogeneous draw; the subagent's mutation check showed the variance-gap assertion failing by about 20 MCSE against a wrong `s_ca`.
The subagent's ambiguity calls were all verified in review: $\bar\mu_S$ is taken over the full switcher set; no $\phi$ truth is invented for the two-regime arm, which instead exposes $\phi_1$/$\phi_2$/$\phi_{pooled}$; `s_ca` is required only lazily, when `noise_scale != 0`, so the P1 gate still passes on old configs; and the threshold-5 kept set built from `cfg.traj_n_pids` was checked exact against `drop_sparse_switchers`' treated-pid semantics, matching production $J_R$ of 26/4 with 27 IDN / 5 TZA kept.
The main thread verified 8/8 tests passing and the P1 zero-noise gate PASS in both cells; check 2 is the P1 gate script itself, and check 7, the registry truths against a large-sample projection through the actual estimation pipeline, is deferred to P4 by design.

Calibration rulings wired (commit `cea5586`).
Emilia ruled at 21:46: DECISION 1 approved ("the residual idea sounds good"), DECISION 2 deferred to Claude's proposed constants ("I'm really not sure I'll go with your judgement here").
[sims/src/calibrate.py](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/src/calibrate.py) was extended to compute $V_R$/$V_U$ from aux-OLS residuals split by choice; $\sigma_\xi^2 = (V_R - V_U)/(-\phi(2+\phi))$, clamped to $[0, \sigma_\theta^2]$; `s_ca` as a share; $\eta = 2\ln(3)/\mathrm{range}(\mu_c)$ (1.685 IDN, 1.144 TZA); and $h = \sigma_\theta$ (0.355 IDN, 0.421 TZA).
Configs were re-emitted, and the calibration report gained a "Within-cell split and two-regime constants" section.
The finding: urban residual variance exceeds rural in both cells ($V_U - V_R = +0.036$ IDN, $+0.048$ TZA), so $\sigma_\xi^2$ comes back negative and the clamp lands `s_ca = 0` in both cells.
The model logic is that with $\phi < 0$, the comparative-advantage channel can only shrink urban variance (since $(1+\phi)^2 < 1$), so the data put zero weight on within-cell return heterogeneity through this channel, and the excess urban variance instead points at a location-specific shock scale the DGP had not modeled.
The baseline therefore runs with homogeneous within-cell returns, the favorable case, disclosed as such, with the `s_ca = 1` pocket now serving as the stress-direction sensitivity.
Tests and the P1 gate were re-verified after wiring.

Shock-scale multiplier approved and recorded, not yet implemented (commit `f65c9b6`).
Emilia approved trying the urban shock-scale multiplier at 21:57, with a recorded concern: the DGP is starting to accumulate ad hoc calibration choices, so each addition must earn its place, and the appendix's calibration paragraph must surface the full ledger of fitted constants in one place.
The spec addendum (section 2.4) scales $\epsilon_{it}$ by $m_U^{D_{it}}$, so a person's AR(1) path is scaled on urban rows only, preserving the correlation structure; at the $s=0$ corner, $m_U^2 = 1 + (V_U - V_R)/\sigma_\epsilon^2$, clamped below at 1; if $s > 0$, the split is solved first and the multiplier absorbs the remainder.
Implementation is deferred to next session, alongside a check-3 test extension.

### Decisions, with the why

The sandwich bread now goes through `_invsym_ginv`, not pinv, because pinv's rcond truncation zeroed exactly the weakly identified directions whose sampling variance the sandwich must report, which had collapsed TZA's SE($\phi$) by a factor of 8; invsym matches Stata's own computation, and the diagnosis came from comparing pinv-based and exact-inverse breads at the fitted $\theta$.

The inversion-parity gate runs at 1e-9 absolute on grid values rather than bitwise, because the port and production agree to the last ULP of `arange` accumulation; bitwise equality tripped on 1-ULP differences invisible at 17 significant digits, and 1e-9 sits far below the 0.01 grid step.

The baseline DGP puts return heterogeneity at the individual level, not the trajectory level, because that is the Roy/CRC structure the estimator is built for; the cell-mean moments still hold under it, so the exercise stays informative rather than rigged.

GMM $\Delta_{avg}$ and inversion $\Delta_{avg}$ are registered as different estimands, because the simulation estimator (sparse threshold 0) averages all switcher trajectories while the inversion machinery drops sub-5 switchers and renormalizes; per the plan, each gets scored only against its own truth, and a mismatch between them is a bug, never a finding.

The two-regime arm preserves means and variances exactly at every dial value, so the dial moves only the LCA violation and never the noise level; the dial-zero point nests the baseline bit-exactly, since the correction term is coded as `dial/2 * (...)` and so is exactly 0.0 at dial zero, letting the third arm reuse the first arm's replications at that point.

The F-adjustment $\nu$ formula was not coded from memory, on no-fabrication discipline; the 2023 corrigendum changed exactly the multi-parameter case this project hits, so it gets transcribed and cross-checked against clubSandwich at implementation time.

Claude accepted the `s_ca = 0` clamp rather than second-guessing the just-approved rule, because the rule was Emilia's call and the corner is what the data say; the location-specific shock-scale interpretation was flagged instead, and Emilia approved the multiplier refinement that same evening.

### Approaches rejected, with the reason

Bitwise equality as the inversion-parity gate: it tripped on ULP-level `arange` differences, so it was loosened to 1e-9.

Keeping pinv in the sandwich bread: it collapsed SEs in weakly identified directions, so it was replaced by invsym.

### Open items

Implement the urban shock-scale multiplier in `calibrate.py` and `dgp.py`, plus the check-3 test extension; the spec addendum in [sims/docs/p3_dgp_truths.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/p3_dgp_truths.md) section 2.4 has the formulas.
This is the next concrete action.

P4: build `run_one.py` and `orchestrate.py` (typed failure capture, parquet schema per plan M7, seeds per plan M6), then run the P4b critic-python review, then run the P5a timing pilot once Emilia sets the compute budget.

Check 7, the estimand-registry projection through the full pipeline, lands with P4.

An ad-hockery ledger is owed: the appendix's calibration paragraph must enumerate every fitted constant, per Emilia's requirement recorded in the spec addendum.

Carried over from the morning session: the hukou stub footnote (Emilia), wiring `11b_extrapolation_support_figure.do` into `0_master.do` (Emilia), and the server-compute investigation feeding P5a (Emilia).

Paper-relevant flag, carried over from the morning session and still standing: production $\hat\phi$ is solver-selected in weakly identified directions, so one disclosure sentence belongs in the simulation appendix.
