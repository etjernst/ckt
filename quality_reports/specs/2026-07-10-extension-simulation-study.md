# Spec: extension simulation study for the ECMA draft

2026-07-10.
Status: APPROVED; Emilia resolved D1-D5 the same day (resolutions recorded at the bottom); amended the same evening per the external-review dispositions ([2026-07-10_external-simulation-review-dispositions.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_external-simulation-review-dispositions.md)), with D6 recording her rulings.
Next step: implementation plan (fresh session; see the handoff in the 2026-07-10 simulation session log).
Context: [the cost-benefit memo](file:///C:/git/ckt/docs/notes/2026-07-10_simulation-cost-benefit.md).
The comment paper (`tjernstromCommentSuri2011`, forthcoming Econometrica) validates the GrRC machinery at $T=2$ with a single Wald restriction.
This study validates the extension CKT actually runs and claims as its methodological contribution: longer unbalanced panels with many trajectories, extrapolated estimands, and weak-identification robust inference at high restriction counts.
It never re-proves the $T=2$ case.

## Objective

Produce a referee-grade simulation exhibit for the submitted draft answering three questions:
1. Do the CKT-specific estimands (extrapolated $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$, the lumped unbalanced-cell return $\Delta_{\text{unb}}$) come back unbiased with honest uncertainty at CKT-calibrated designs?
2. Does the inversion CI cover at nominal rates at the empirical $(N, T, K)$, where $J_R$ reaches 26 (IDN) and the chi-squared finite-sample bias is a documented risk (generic-synth coverage 0.84 at $J_R = 13$)?
3. What do the estimates, the Hansen J-test, and the inversion region do when the LCA restriction fails (misspecification arm), including the empty-CI behavior that the paper's pooled-China split relies on?

## MUST

- M1. One parameterized DGP entry point accepting a per-cell configuration, returning data plus the true value of every target parameter computed from the DGP parameters, never from an estimate; the complete DGP (outcome equations, every distribution, every covariance and conditional-independence restriction) is written out mathematically before coding.
- M2. LCA-true baseline DGP calibrated per cell to the empirical design: trajectory shares and counts, unbalanced share, $T$, $N$, $(\hat\phi, \hat\beta)$ from the production sters, and residual variance components; covariates enter by holding the empirical covariate matrix fixed (snapshot from the production data) and simulating only the unobservables, per the 2026-04-22 SIMULATION_PLAN design.
Transitory shocks are serially dependent within person, calibrated to the empirical residual autocovariance; iid shocks are a favorable sensitivity only.
- M3 (amended 2026-07-11 per D7). Per replication, run the certified two-step estimator, not a simplified stand-in: `grc_gmm.py` in `stata_twostep` mode with `initials="aux-direct"` (Stata's two-step protocol with invsym-swept weighting, warm-started from the saturated auxiliary OLS), plus the inversion CI machinery (`lca_inversion.py`) for arm two.
The original bit-parity requirement is descoped: the P2 reconciliation established that the port's residuals, instruments, moments, and J formula reproduce production exactly at Stata's own $(\hat\theta, W)$, that the production point estimates are solver-selected in weakly identified directions (the criterion admits degenerate near-exact roots that Stata's solver happens not to visit), and that exact trajectory replication would make Stata's numerical-derivative noise part of the estimand.
Production-path fidelity is instead certified by (i) the exact-J certification at production $(\hat\theta, W)$, (ii) matching J degrees of freedom via the same rank-sweep rule, with the same swept columns, and (iii) a real-data parity table (port vs production, both cells, all parameters) published with the appendix, with headline-parameter agreement documented at the achieved tolerances (TZA within 0.02 on all parameters; IDN returns within 0.007, $\phi$ within 0.06).
The appendix discloses the solver dependence in one sentence.
- M4. Metrics per parameter and cell, each with its Monte Carlo standard error: bias, empirical SE, RMSE, and coverage defined as the share of replications whose CI contains the DGP truth.
Coverage of inverted sets is scored by evaluating the test at the truth, not by grid membership; empty sets are valid noncoverage outcomes, not failures; unconditional coverage (failures counted as misses) and conditional coverage (among valid fits) are both reported.
Failed or non-converged replications are counted and reported, never silently dropped.
- M5. Replication budget: timing pilot at R=20 per cell, an $R \approx 100$ validation tranche covering every distinct execution path (code and configuration hashes frozen when it passes), then a compute gate (present the projected cost before launching the full run); full run targets R=1,000 per cell-arm, where the coverage MCSE near 0.95 is 0.69pp (one MCSE; the corresponding 95 percent Monte Carlo half-width is about 1.35pp), with analogous precision targets stated for J rejection rates and failure frequencies. R below 500 does not ship (cannot distinguish 0.93 from 0.95).
- M6. Seeding: one master seed (YYYYMMDD), independent streams per replication via `numpy` `SeedSequence.spawn`; seed and R recorded in every saved output.
- M7. Storage: per-replication raw results (parquet or csv: cell, arm, rep, parameter, estimate, se, ci_lo, ci_hi, converged) saved alongside the summary table; the paper table is generated from the summary by script, never hand-edited.
- M8. Arm three (misspecification): at least one LCA-violation DGP family with a violation-size dial, reporting J-test rejection rates (size under the arm-one LCA-true DGP, power under violation, both nominal and size-adjusted), inversion-region empty-set frequency, and bias of the extrapolated $\Delta_{d_N}$ under violation.
The violation family must nest the arm-one baseline exactly at dial zero, and the population LCA residual vector must be verified analytically to be zero at dial zero and monotonically increasing in the dial; a two-regime mixture with regime membership independent of trajectory and $\theta$ is exactly LCA-true when pooled and violates nothing, so regime shares and conditional means must vary by trajectory.
- M9. Pre-registered contingency: if arm two shows coverage more than 2 MCSEs below nominal for any headline parameter at R=1,000, implement the Imbens-Kolesár Bell-McCaffrey-Satterthwaite F adjustment (already spec'd in docs/TODO.md) and report the adjusted intervals in the paper; the chi-squared row is then disclosed alongside, not replaced silently.
- M10. No edits to the production Stata pipeline or any data-processing script; the study is additive and lives in its own directory.

## SHOULD

- S1. Cell coverage (resolved by D1): two cells, IDN and TZA.
IDN is the high-$K$ stress case (27 switcher trajectories, 26 restrictions, the largest chi-squared-bias exposure) and TZA is the small-sample case that doubles as the extrapolation boundary case ($\hat\mu_{d_N}$ sits 8% from the lower edge of the switcher hull per the 2026-05-18 support diagnostic, and its $\hat\mu_{d_N}-\hat\mu_{base}$ gap of $-0.19$ log points is by far the largest of the three countries).
The CHN cells are excluded deliberately: rural-first replicates IDN's stress dimensions at added compute, and urban-first is a weakly identified cell where an LCA-true calibration is ill-posed---the empirical $\phi^{uf}$ region is unbounded, so any single "true" $\phi$ is arbitrary and coverage numbers there would test the calibration choice, not the procedure.
The paper's weak-identification defense for that cell is the Dufour-type unbounded-set argument, which is theoretical, plus the two-regime arm below.
- S2. The violation family for M8 mirrors the paper's own story: a two-regime DGP ($\phi$ differing across latent regimes, the hukou situation) as the primary violation, so the arm shows that pooled estimation is detected (J rejects, region empties) and split estimation recovers truth---turning the China wrinkle into evidence the procedure works.
A smooth-curvature violation (quadratic term in $\theta$) is the secondary family if time permits.
If a referee asks whether curvature can be accommodated rather than merely detected, the principled answer exists and should be kept in the pocket: with three or more switcher trajectories, a quadratic comparative-advantage restriction $\Delta_i = \beta + \phi_1\theta_i + \phi_2\theta_i^2$ is estimable from the same $(\mu_{\underline{d}}, \Delta_{\underline{d}})$ variation (three distinct points pin a parabola), which is impossible in the comment paper's $T=2$ design---another consequence of the extension, not a patch.
- S3. Runtime engineering: parallelize replications across cores with `joblib`; reuse the profiling knowledge in `explorations/python-grc/profile_hot_paths.py`.
- S4. Deliverable prose: one appendix section plus one main table (bias / empirical SE / RMSE / coverage with MCSEs, by cell and parameter), framed explicitly as validating the extension from the comment paper's $T=2$ design.
- S5. Mechanical implementation legs delegated to `model: "sonnet"` subagents per rules/model-routing.md; design, calibration choices, and results interpretation stay in the main thread.

## MAY

- M-a. A reduced-$N$ scaling check (does coverage degrade as synthetic $N$ shrinks) if the pilot shows fits are cheap.
- M-b. Persist a reusable synthesizer API so the pocket exercises (J-test power, OLS/FE-vs-GRC gap) can be run during R&R without redesign.
- M-c. A design-robustness sensitivity that redraws the design per replication by resampling individuals (with their trajectory labels, observation patterns, and covariate rows intact) from the empirical pool, perturbing trajectory composition and $J_R$ realistically without specifying a design-formation model; truths remain computable from the same calibrated line per resampled design (decided 2026-07-10: kept as a maybe, not committed).

## Out of scope

- Re-running or replicating the comment paper's $T=2$ simulation.
- The pocket exercises (Hansen J size/power beyond M8's byproduct, OLS/FE/GRC selection-gap quantification): deliberately reserved as referee asks.
- Bootstrap-calibrated critical values: escalation path only if the F adjustment fails to close a coverage gap.
- Any change to empirical results, tables, or the estimation pipeline.

## Decisions (Emilia, 2026-07-10)

- D1. Cells: IDN and TZA only, with the exclusion rationale spelled out per S1; Emilia specifically judged the flat-$\phi$ urban-first cell a poor simulation case.
- D2. Two-regime (hukou-style mixing) is the primary violation family; curvature stays time-permitting, with the quadratic-restriction fix noted in S2 kept as a pocket answer.
- D3. The work happens in a dedicated git worktree, in Python, and does NOT go into RP7 for now---but the directory must be built replication-package-ready from day one: pinned environment (requirements or conda env file), seed discipline per M6, a README mapping scripts to outputs, deterministic regeneration of every table from raw per-rep results.
Parallelism is a design requirement (replication-level, embarrassingly parallel), but runs start small per the M5 pilot gate.
- D4. Emilia is investigating server compute access, which reinforces Python-only execution: the per-replication path must run headless with no Stata dependency (the validated `grc_gmm.py` port plus `lca_inversion.py` satisfy this).
The M5 compute gate stands: pilot first, project the wall-clock, then decide local vs server.
- D5. Appendix section with a one-paragraph pointer from the main text.
- D6 (evening). The external-review dispositions are folded into this spec and the plan; the M3 parity failure branch is decided at the P2 gate, not pre-committed; and server execution is not a data-governance blocker because the replication data are fully public, with a moments-only config (calibrated parameters travel, microdata do not) as the fallback if a host requires it.
- D7 (2026-07-11). The M3 parity branch is resolved: descope exact point parity ("option 1 for sure"); the simulation estimator is the `stata_twostep` + `aux-direct` variant; the amended M3 above states the replacement fidelity requirements; full reconciliation record at `sims/output/p2_parity_notes.md` on the extension-sims worktree.

## Verification

- Harness sanity (amended per D7): fed the real data, the simulation estimator must reproduce the certified real-data parity table exactly (same code path, same numbers), and the exact-J certification at production $(\hat\theta, W)$ must hold; both were established at P2 on 2026-07-11 and are re-run before any synthetic run is trusted.
- The self-check against the drift baseline stays green throughout (no production outputs change).
- critic-alignment pass on the final appendix prose against the simulation summary CSV before the table enters the draft.
