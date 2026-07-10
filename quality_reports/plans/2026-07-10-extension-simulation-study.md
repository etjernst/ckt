# Plan: extension simulation study for the ECMA draft

2026-07-10.
Status: REVISED per the external-review dispositions ([2026-07-10_external-simulation-review-dispositions.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md)), adopted items folded in on Emilia's 2026-07-10 instruction; awaiting her final go-ahead to start P0.
Spec (approved, governs scope): [quality_reports/specs/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/specs/2026-07-10-extension-simulation-study.md).
Context memo: [docs/notes/2026-07-10_simulation-cost-benefit.md](file:///C:/git/ckt/docs/notes/2026-07-10_simulation-cost-benefit.md).
Prior exploratory design (mined, not inherited): `explorations/SIMULATION_PLAN.md` on the simulations worktree.

## What the study delivers

A referee-grade Monte Carlo validating the CKT extension of the comment paper's $T=2$ GrRC machinery: bias, empirical SE, RMSE, and coverage for the extrapolated $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$, and the lumped unbalanced-cell return, plus inversion-CI coverage at the empirical $(N, T, K)$, plus a two-regime misspecification arm, in IDN and TZA calibrations (D1).
Deliverable prose is one appendix section plus one main table with a one-paragraph main-text pointer (S4, D5).

## Design decisions for approval

These four choices shape everything downstream; each carries a recommendation.

### A. Fixed-design DGP (recommended) vs endogenous migration choice

The 2026-04-22 exploratory plan argued for simulating the migration decision rule so that trajectories form endogenously on comparative advantage.
I recommend the fixed-design alternative: hold each empirical individual's trajectory label, observation pattern, and covariate rows exactly as in the production data, and regenerate only the unobservables (heterogeneity and shocks) each replication.
Four reasons.
First, the spec's three questions are all about estimator and CI behavior at the empirical design, and the GRC moment system conditions on trajectories, so the empirical design is reproduced exactly rather than approximately (M2's shares, counts, unbalanced share, $T$, $N$ all match by construction).
Second, M1 requires the truth of every target parameter to be a closed-form function of DGP parameters; under endogenous selection, trajectory-conditional truths become implied moments that must themselves be simulated.
Third, endogenous selection requires calibrating a cost process to hit non-switcher shares, an ill-posed extra layer that tests the calibration rather than the procedure.
Fourth, the selection-on-$\theta$ content that matters observationally, namely that $E[\theta_i \mid \underline{d}]$ varies across trajectories, is preserved by drawing $\theta_i$ conditional on trajectory with means matched to the empirical $\mu_{\underline{d}}$ pattern.
The endogenous-selection DGP remains the right tool for the pocketed OLS/FE-vs-GRC gap exercise and can be added during R&R without redesign (M-b).

### B. Coverage metric for arm one, given the known SE($\phi$) gap in the Python port

The validated port matches Stata point estimates ($\hat\phi$ to 0.003) but its cluster-robust SE for $\phi$ is a documented open issue (about 2.75 times Stata's, traced to `pinv` retaining a rank-deficient direction; `BLOCKER.md` item A on the simulations worktree).
I recommend: report bias, empirical SE, and RMSE from the GMM point estimates (unaffected); define headline coverage via the inversion CI, which never touches the GMM variance (it runs off the auxiliary saturated OLS with cluster-robust VCV); and time-box a two-day fix attempt for the GMM SE so conventional-Wald coverage can be reported alongside.
If the fix fails inside the time box, the appendix reports inversion-CI coverage only, which matches the paper's actual inference claims, and the GMM-Wald coverage row is dropped rather than reported with a known-wrong variance.
The lumped unbalanced-cell return $\Delta_{\text{unb}}$ is not among the four parameters `compute_all_inversion_cis` inverts, so its coverage vehicle in every branch is the cluster-robust Wald interval on the $U_i \times D_{it}$ coefficient from the same auxiliary OLS; like the inversions, this never touches the GMM variance.
Coverage for the inverted parameters is scored by evaluating the test at the truth, not by grid membership: for $\phi$ the p-value is computed directly at $\phi_0$, and for each $\Delta$ the profiled statistic is evaluated at $\Delta_0$ with continuous (or adaptively refined) nuisance minimization over $\phi$, so coverage is exact and free of grid-resolution artifacts.
The grid machinery is retained only to reconstruct the reported set, with adaptive expansion and boundary refinement, and each set is classified as empty, bounded, disconnected, one-sided unbounded, two-sided unbounded, whole-line, or unresolved; a grid-truncated result is scored unresolved, never as a completed confidence set.
An empty set is a valid inferential outcome and scores as noncoverage, not as a numerical failure.
Set topology and finite-set length are reported alongside coverage.
A related P2 task: J-test parity with production Stata is part of the P2 gate, covering instrument construction, collinearity and rank handling, the GMM iteration scheme, the J statistic, its degrees of freedom, and the p-value, with predefined tolerances for every headline point estimate and source hashes recorded in the parity report.
The recorded discrepancy ($J = 97.74$ at 29 df versus $86.52$ at 27 df) predates the port's current `_drop_collinear` step, which mirrors the suspected cause (Stata's `_rmcoll` handling), so P2 re-measures the gap rather than citing it.
If parity fails inside the time box, the choice between descoping the production-J claims by explicit spec amendment and extending the reconciliation is Emilia's, made at the gate with the measured gap in hand, never defaulted (ruled 2026-07-10: no pre-commitment).

### C. Arm-three dial and budget

Two-regime primary violation (D2): each individual belongs to latent regime 1 or 2, each regime LCA-true with its own $(\beta_r, \phi_r)$; regime shares are trajectory-specific ($\lambda_{r \mid \underline{d}}$) with regime-specific conditional means $E[\theta_i \mid \underline{d}, r]$, because a mixture with regime membership independent of trajectory and $\theta$ collapses to the exact pooled line $\bar\beta + \bar\phi\,\mu_{\underline{d}}$ and violates nothing.
The dial is the slope gap $|\phi_1 - \phi_2|$, scaled so the largest value reproduces the empirical hukou-split gap; P3 computes the analytic population LCA residual vector at every dial value and requires it to be exactly zero at dial zero (the dial-zero DGP nests the arm-one baseline completely: intercepts, distributions, and composition) and monotonically increasing in the dial.
J rejection rates are reported both nominal and size-adjusted.
I recommend three dial points (zero, half-gap, full empirical gap) at R=1,000 each, with the zero point doubling as the J-test size check under LCA-truth (it reuses the arm-one replications, so only two dial points cost new compute).
Within each cell, dial points share common random numbers at the replication level (same rep seed across dials), which sharpens the power curve at no cost while replications stay independent of each other.
Curvature family ($\Delta_i = \beta + \phi_1\theta_i + \phi_2\theta_i^2$) stays time-permitting per D2, same dial logic.
Regime membership is recorded in the simulated data so split estimation can be run exactly as the paper splits on hukou, demonstrating detect-then-split recovers truth (S2); the appendix prose discloses that the simulation splits on the true recorded regime label, the best case relative to splitting on observed hukou.
Cost note: each arm-three replication runs one pooled fit plus two split fits, roughly doubling per-replication GMM time relative to arm one; the P5 memo prices this explicitly.

### Truth definitions (M1, written into `dgp.py` and its unit tests)

Baseline arm: $\Delta_{\underline{d}} = \beta + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ for every trajectory, with $\mu_{\underline{d}}$ set to the calibrated values; $\Delta_{\text{avg}}$ is the $\pi_{\underline{d}}$-weighted average over switcher trajectories (people-shares of the kept switcher set), and because the fixed design holds the kept switcher set stable across replications, the target is a single fixed number (no per-replication recomputation of the kind `synth_overid.py` needed).
Because the estimator's auto-selected base can differ across replications, the DGP truth line is defined base-invariantly as $\Delta_{\underline{d}} = a + \phi\,\mu_{\underline{d}}$, the selected base is recorded in every replication, and estimates are mapped onto the invariant line before scoring.
P3 maintains an estimand registry giving each reported estimator's population functional, sample, and exact weights, and validates every analytic truth against a large-sample population-projection calculation before any coverage number is trusted.
$\Delta_{\text{unb}}$: unbalanced individuals draw $\theta_i$ from one conditional distribution with mean calibrated to the lumped cell's empirical mean (`traj_for_agg = -1`), which makes the lumped truth $\beta + \phi(\mu_{\text{unb}} - \mu_{\underline{d}_0})$ invariant to the estimator's within-person weighting; the invariance argument (the auxiliary-OLS weights are functions of $(X, D)$ only while $\theta_i$ has a common conditional mean, so any FWL-weighted average of $E[\theta_i]$ equals that mean) is written into the estimand registry and unit-tested at P3, not asserted; this within-cell homogeneity is a disclosed calibration choice, and a heterogeneous-means sensitivity stays in the pocket.
Two-regime arm: pooled truths are regime-share-weighted with trajectory-specific shares, e.g. $\Delta_{d_N} = \sum_r \lambda_{r \mid d_N} \left(\beta_r + \phi_r\, E[\theta_i \mid d_N, r]\right)$, and analogously for $\Delta_{\text{avg}}$ and $\Delta_{d_T}$; split-estimation truths are the within-regime lines.
P3's unit checks verify that large-sample simulated moments converge to these definitions before any coverage number is trusted.
Estimand alignment (the simulation-conventions contract): every reported estimator names the estimand it targets, and each is scored only against its own truth---the GMM $\hat\Delta_{d_N}$ and the inversion region both target the $\Delta_{d_N}$ defined above; the auxiliary-OLS lumped coefficient targets $\Delta_{\text{unb}}$ as defined above (weighting-invariant by the homogeneity choice); a mismatch discovered at P3 is a bug, never a finding.

### D. Worktree and data safety

New worktree `extension-sims` (branch `worktree-extension-sims`) under `.claude/worktrees/`, per D3.
NO junctions into it: the calibration stage reads the hub `C:/git/ckt/RP7/data/processed/` and `C:/git/ckt/RP7/output/counterfactual_inputs/` read-only ONCE and snapshots what it needs into the worktree as parquet.
Snapshots contain consumption microdata, so they are gitignored, with a regeneration script tracked in their place (data-governance rule: cleaned data reproducible by script, never committed).
This sidesteps the junction-deletion failure mode entirely (see [project_data_loss_2026-06-23.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/project_data_loss_2026-06-23.md)); the worktree can be removed safely once merged because nothing lives behind a junction.

## Machinery: reused vs new

Reused as-is (copied into the worktree, provenance noted in README):
- `grc_gmm.py` (`RestrictedGRC`): byte-identical on the simulations and lca-inversion worktrees, checked 2026-07-10; supports the lumped unbalanced cell via `unbalanced_col`, auto base selection mirroring Stata `initial_values`, sparse-moment dropping, iterated GMM; approximately 16 minutes per fit at IDN's full $N$, no Stata dependency, no I/O.
- `lca_inversion.py`: `compute_all_inversion_cis` runs all four inversions ($\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$) off one auxiliary OLS fit; every grid function computes its p-value at one line (`1 - chi2.cdf(wald, df=J_R)`), which is exactly where the M9 F-adjustment plugs in; the only Stata-dependent function (`attach_inversion_for_stata`) is excluded from headless imports.

New code, structured after `synth_overid.py` but parameterized (its DGP constants are module globals set at import, unusable for a config-driven loop):
- `config.py`: per-cell calibration dataclass (loaded from a generated per-cell JSON/YAML) holding $N$, $T$, patterns, trajectory labels, $\hat\phi$, $\hat\beta$, $\mu_{\underline{d}}$, variance components, and the arm dial.
- `dgp.py`: fixed-design synthesizer (M1): one function per arm family returning the simulated long panel plus every true target parameter computed from DGP parameters.
- `run_one.py`: one replication end to end, returning tidy rows (cell, arm, dial, rep, master_seed, rep_seed, selected_base, parameter, estimate, se, ci_lo, ci_hi, covered_at_truth, set_topology, n_islands, set_length, wald_min, J_stat, J_df, J_pval, converged, fail_reason); failures captured and typed, never silently skipped (`synth_overid.py`'s bare `try/except: continue` is explicitly not carried over, per M4).
The J columns per replication are what M8's rejection rates aggregate from, and the seed columns satisfy M6's seed-in-every-output requirement.
- `orchestrate.py`: `joblib.Parallel` over replications (S3), master seed 20260710 with `SeedSequence.spawn` per replication (M6), incremental parquet writes (M7).
- `metrics.py` + `make_tables.py`: bias, empirical SE, and RMSE over finite estimates with $n_{\mathrm{eff}}$ reported; completion rates over all attempted replications; unconditional coverage with numerical failures counted as misses, conditional coverage among valid fits, and the $[H/R, (H+F)/R]$ bounds when failure coverage is unknowable; empty sets scored as valid noncoverage outcomes; mean model SE and relative SE bias for every Wald-type interval; set topology frequencies and finite-set length for the inversions; every MCSE computed over its declared denominator; the M5 precision target stated as one MCSE (0.69pp at 0.95 and $R = 1{,}000$, a 95 percent Monte Carlo half-width of about 1.35pp), with analogous targets for J rejection rates and failure frequencies; the paper table generated from the summary by script only (M7).
- `calibrate.py`: the one-time snapshot + calibration-extraction script (stage P1 below).

## Calibration inputs (all verified on disk 2026-07-10)

- $(\hat\phi, \hat\beta)$, per-trajectory counts, urban shares, trajectory shares, and $\mu_{\underline{d}}$ (including the lumped cell as `traj_for_agg = -1`): exporter CSVs at `C:/git/ckt/RP7/output/counterfactual_inputs/{IDN,TZA}_e1_*.csv`.
- Observation patterns, covariate matrices, unbalanced flags: `C:/git/ckt/RP7/data/processed/{IDN,TZA}_unb.dta` (read-only snapshot).
- Variance components and error dependence: `calibrate.py` computes $\sigma_\theta$ within-trajectory and the within-person residual autocovariance structure after the production covariates, documented in the calibration report.
The baseline DGP draws serially dependent transitory shocks calibrated to that autocovariance, because production inference clusters by person precisely against this dependence, and iid shocks would overstate the effective information per cluster---flattering coverage on exactly the question the study asks.
iid shocks are retained as a favorable sensitivity, and simulated covariance moments must match their calibration targets before the pilot.
- Covariate coefficients $\hat\gamma$ and time effects from the production estimates: simulated outcomes include $x_{it}'\hat\gamma$ at those values, and every replication re-estimates the full covariate block, so the production path's $\gamma$-estimation noise is part of what the study measures (M2/M3).
- 310 production `.ster` files in `C:/git/ckt/RP7/output/` remain the cross-check of record for the P2 sanity gate.

## Stages and gates

P0. Worktree and scaffold (0.5 day).
Branch, directory layout (`sims/{src,configs,data,output,results}`), pinned environment (extend `explorations/python-grc/requirements.txt` with joblib and pyarrow), module copies, README skeleton mapping scripts to outputs (D3).
Gate: headless smoke import of the full per-rep call chain.

P1. Calibration and design snapshot (1 day).
Run `calibrate.py`: snapshot design matrices to parquet, extract per-cell parameters, emit configs and a calibration report.
Gate: a zero-noise simulated panel reproduces the calibration targets (shares, counts, $\mu_{\underline{d}}$ pattern) exactly.

P2. Harness sanity (1-2 days).
Feed the real IDN and TZA data through the worktree's copies of the production path; point estimates must match the production Stata values within the tolerances already used in the port validation (spec Verification bullet one).
Time-boxed SE($\phi$) fix attempt (decision B) runs inside this stage.
Hard gate: no synthetic run is trusted before the sanity check passes.

P3. DGP and truth module (2-3 days).
The complete DGP is written out mathematically before coding: outcome equations, the absolute-advantage component $\tau_i$, every distribution, and every covariance and conditional-independence restriction the GRC moments need.
Arm families: LCA-true baseline with dependent errors, two-regime mixture (exactly nested at dial zero, analytic violation-residual check per decision C), curvature (stub).
Unit checks: truth functions against hand-computed cases; simulated moments against targets at large $R \cdot N$; the estimand registry's analytic truths against large-sample population projections; the $\Delta_{\text{unb}}$ weighting-invariance derivation.
The F-adjustment mathematics (adjusted statistic, numerator and denominator degrees of freedom, interaction with nuisance profiling, and the headless-Python route replacing the earlier Stata `reg_sandwich` assumption) is resolved on paper here so P9 is implementation-only.

P4. Per-replication pipeline and orchestrator (1-2 days).
Wire GMM fit, `delta_never`/`delta_always`, and `compute_all_inversion_cis` into `run_one.py`; typed failure capture; parquet schema per M7.

P4b. Harness code review (0.5 day).
critic-python pass over `dgp.py`, `run_one.py`, `orchestrate.py`, and `metrics.py` before the pilot, hunting specifically for the simulation-killers named in the conventions: coverage checked against an estimate instead of the truth, estimand-truth mismatch, seeding inside the loop, silent failure drops, and missing MCSEs.
Convention hygiene enforced at this gate: no per-replication console printing (a single progress counter at the orchestrator level only), and NaN/Inf guards on estimates with a documented count-as-failure rule.
Sources: [simulation-conventions.md](https://github.com/pedrohcgs/claude-code-my-workflow/blob/be53c12f235996dff41fb7f21580506fd2dd8d50/.claude/rules/simulation-conventions.md) and [simulation-study SKILL.md](https://github.com/pedrohcgs/claude-code-my-workflow/blob/be53c12f235996dff41fb7f21580506fd2dd8d50/.claude/skills/simulation-study/SKILL.md) (R-oriented; the contract, metric definitions, and pitfall list transfer directly).

P5a. Timing pilot and compute gate (0.5 day plus compute).
R=20 per cell (M5), wall time measured per stage (GMM fit vs inversion vs overhead), reusing the instrumentation knowledge in `explorations/python-grc/profile_hot_paths.py` (S3); the pilot informs timing only, never validation.
Deliverable: a compute-gate memo pricing the FULL matrix explicitly---cells $\times$ arms $\times$ dial points $\times$ (pooled plus split fits for arm three)---locally (roughly 14 usable cores) and on the server option (D4), with the R=1,000 target and R=500 floor, plus memory per worker, BLAS thread nesting under joblib, I/O, a retry allowance, and (for any multi-day run) atomic checkpoints, idempotent resume, and duplicate-key protection.
Server transfer is not a data-governance blocker: the replication data are fully public (Emilia, 2026-07-10), so the design snapshot may move to the server, and a moments-only config (calibrated parameters travel, microdata do not) remains the fallback if a specific host requires it.
EMILIA DECISION POINT: approve the full-run budget and venue before any full run (command-safety rule and M5).
Rough prior for the memo to check: IDN at about 16-20 minutes per replication implies roughly 24-30 hours for arm one at R=1,000 on 14 local cores; TZA should be an order of magnitude cheaper; arm three's two new dial points run pooled plus two split fits per replication (roughly double the per-rep GMM time), so the full IDN matrix is plausibly 4-5 days of continuous local compute---which is the concrete case for the server option, decided at this gate.

P5b. Validation tranche (0.5 day plus compute).
$R \approx 100$ per cell covering every distinct execution path (pooled fit, split fits, inversion, IDN, TZA): convergence rates, set-topology frequencies, metric plumbing, and J size at dial zero are sanity-checked here, since R=20 cannot validate any of them.
Code and configuration hashes are frozen when this tranche passes; with the same master seed the tranche replications are the first 100 of the full run, so its compute (about a tenth of a full run) is not wasted.

P6. Full run, arms one and two (compute-bound).
Arm two costs one extra metric on the same replications (inversion coverage), not a separate run.

P7. Arm three (1 day design plus compute).
Two-regime dial per decision C; split-estimation recovery; empty-CI frequency; J rejection rates (power); curvature only if the calendar allows (D2).

P8. Metrics, tables, and appendix draft (1-2 days).
M4 metrics with MCSEs; failed and non-converged replications reported in the table notes; appendix section framed as validating the extension from the comment paper's $T=2$ design (S4), never re-proving it.
The appendix states the fixed-design scope explicitly: the study validates estimator and inference behavior conditional on the empirical trajectory and covariate design, not the migration-choice mechanism or unconditional selection behavior.

P9. Contingency (M9, only if triggered).
If arm two shows coverage more than 2 MCSEs below nominal for any headline parameter at R=1,000: implement the Imbens-Kolesár Bell-McCaffrey-Satterthwaite F adjustment at the `chi2.cdf` plug-in points in `lca_inversion.py` (five call sites, one per grid function), re-run coverage, and report adjusted intervals alongside (not instead of) the chi-squared row.
The mathematics is already resolved on paper at P3 (including the minimized-Wald delta inversions, where the degrees-of-freedom adjustment is not a mechanical swap), so this stage is implementation and re-run only.
Prior spec work at `quality_reports/plans/2026-05-01-f-adjustment-inversion.md` (lca-inversion worktree) is the starting point.

P10. Review and integration (1 day).
critic-alignment pass of the appendix prose against the summary CSV (spec Verification); paper insertion with per-edit approval; drift check that no production outputs changed (M10).

## Model routing (S5)

Mechanical legs are delegated to `model: "sonnet"` subagents with per-task briefs: the synth-refactor into `config.py`/`dgp.py` scaffolding, `calibrate.py` extraction code, `metrics.py`/`make_tables.py`, and README/environment housekeeping.
The main thread keeps: DGP design and calibration choices (P1/P3 judgment calls), the compute-gate memo, arm-three design, results interpretation, and all paper prose.

## Risks

- Runtime concentration in the IDN GMM fit (16 min/rep dominates; inversion is cheap by comparison since it runs off the auxiliary OLS, not the GMM).
Mitigations: joblib parallelism, the P5 gate before any large spend, the server option, and M-a's reduced-$N$ scaling check as a documented fallback if full-$N$ IDN proves infeasible (any such fallback is presented at the gate, never silently substituted).
- SE($\phi$) fix may fail inside its time box; decision B pre-commits the fallback so this cannot stall the pipeline.
- Convergence failures at synthetic draws the optimizer dislikes; typed failure capture plus the M4 reporting rule keeps this visible, and ANY failure in the R=20 timing pilot escalates to Emilia before the full run (a percentage threshold is meaningless at pilot granularity; the rate is re-measured at the P5b validation tranche, where a predefined full-run failure threshold enters the frozen protocol and blocks the appendix or triggers solver remediation if breached).
- TZA calibration nearness to the boundary ($\hat\mu_{d_N}$ at 8 percent of the switcher hull) may make its extrapolated-estimand coverage genuinely fragile; that is a finding, not a bug, and gets reported as such.

## Calendar

Roughly 10-15 working days of build after folding in the external-review dispositions (the added days sit in P2 parity, P3's dependent-error DGP and analytic violation checks, and the P5b validation tranche), plus compute on the order of 4-5 days of continuous local 14-core time for the full IDN matrix if run locally (the P5a memo firms this up and the server option shortens it); P5a's decision point is the natural mid-course check-in.
