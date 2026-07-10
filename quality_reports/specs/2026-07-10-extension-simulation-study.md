# Spec: extension simulation study for the ECMA draft

2026-07-10.
Status: DRAFT, awaiting Emilia's approval on the spec and the open decisions D1-D5.
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

- M1. One parameterized DGP function per country cell, returning data plus the true value of every target parameter computed from the DGP parameters, never from an estimate.
- M2. LCA-true baseline DGP calibrated per cell to the empirical design: trajectory shares and counts, unbalanced share, $T$, $N$, $(\hat\phi, \hat\beta)$ from the production sters, and residual variance components; covariates enter by holding the empirical covariate matrix fixed (snapshot from the production data) and simulating only the unobservables, per the 2026-04-22 SIMULATION_PLAN design.
- M3. Per replication, run the production estimation path, not a simplified stand-in: the validated Python GMM port (`grc_gmm.py`) with the same sparse-switcher rule, base-selection logic, and settings as the Stata production pipeline, plus the inversion CI machinery (`lca_inversion.py`) for arm two.
- M4. Metrics per parameter and cell, each with its Monte Carlo standard error: bias, empirical SE, RMSE, and coverage defined as the share of replications whose CI contains the DGP truth.
Failed or non-converged replications are counted and reported, never silently dropped.
- M5. Replication budget: pilot at R=20 per cell to measure wall time, then a compute gate (present the projected cost before launching the full run); full run targets R=1,000 per cell-arm (coverage MCSE $\pm 0.7$pp near 0.95). R below 500 does not ship (cannot distinguish 0.93 from 0.95).
- M6. Seeding: one master seed (YYYYMMDD), independent streams per replication via `numpy` `SeedSequence.spawn`; seed and R recorded in every saved output.
- M7. Storage: per-replication raw results (parquet or csv: cell, arm, rep, parameter, estimate, se, ci_lo, ci_hi, converged) saved alongside the summary table; the paper table is generated from the summary by script, never hand-edited.
- M8. Arm three (misspecification): at least one LCA-violation DGP family with a violation-size dial, reporting J-test rejection rates (size under the arm-one LCA-true DGP, power under violation), inversion-region empty-set frequency, and bias of the extrapolated $\Delta_{d_N}$ under violation.
- M9. Pre-registered contingency: if arm two shows coverage more than 2 MCSEs below nominal for any headline parameter at R=1,000, implement the Imbens-Kolesár Bell-McCaffrey-Satterthwaite F adjustment (already spec'd in docs/TODO.md) and report the adjusted intervals in the paper; the chi-squared row is then disclosed alongside, not replaced silently.
- M10. No edits to the production Stata pipeline or any data-processing script; the study is additive and lives in its own directory.

## SHOULD

- S1. Cell coverage: the four production cells (IDN, TZA, CHN rural-first, CHN urban-first), matching the paper's tables; CHN urban-first doubles as the weak-cell stress test, where the unbounded-interval frequency should be reported (the Dufour-type behavior the paper already documents empirically).
- S2. The violation family for M8 mirrors the paper's own story: a two-regime DGP ($\phi$ differing across latent regimes, the hukou situation) as the primary violation, so the arm shows that pooled estimation is detected (J rejects, region empties) and split estimation recovers truth---turning the China wrinkle into evidence the procedure works.
A smooth-curvature violation (quadratic term in $\theta$) is the secondary family if time permits.
- S3. Runtime engineering: parallelize replications across cores with `joblib`; reuse the profiling knowledge in `explorations/python-grc/profile_hot_paths.py`.
- S4. Deliverable prose: one appendix section plus one main table (bias / empirical SE / RMSE / coverage with MCSEs, by cell and parameter), framed explicitly as validating the extension from the comment paper's $T=2$ design.
- S5. Mechanical implementation legs delegated to `model: "sonnet"` subagents per rules/model-routing.md; design, calibration choices, and results interpretation stay in the main thread.

## MAY

- M-a. A reduced-$N$ scaling check (does coverage degrade as synthetic $N$ shrinks) if the pilot shows fits are cheap.
- M-b. Persist a reusable synthesizer API so the pocket exercises (J-test power, OLS/FE-vs-GRC gap) can be run during R&R without redesign.

## Out of scope

- Re-running or replicating the comment paper's $T=2$ simulation.
- The pocket exercises (Hansen J size/power beyond M8's byproduct, OLS/FE/GRC selection-gap quantification): deliberately reserved as referee asks.
- Bootstrap-calibrated critical values: escalation path only if the F adjustment fails to close a coverage gap.
- Any change to empirical results, tables, or the estimation pipeline.

## Open decisions for Emilia

- D1. Cells: the four production cells per S1, or fewer (e.g., IDN as the high-$K$ worst case plus TZA)?
- D2. Violation family priority per S2: two-regime first (recommended; matches the hukou narrative), curvature second?
- D3. Where code and outputs live: proposal is a new `explorations/simulations/` in the main tree (Python, not part of the coauthor Stata handoff), with only the final generated table copied into `RP7/output/tables/`.
- D4. Compute ceiling: the pilot will produce a projected wall-clock; is there a budget above which we scale R down (with the MCSE consequence made explicit) rather than up?
- D5. Placement in the paper: appendix section with a one-paragraph main-text pointer (recommended), or a main-text subsection?

## Verification

- The pilot must reproduce each cell's production point estimates within tolerance when fed the real data (harness sanity check) before any synthetic run is trusted.
- The self-check against the drift baseline stays green throughout (no production outputs change).
- critic-alignment pass on the final appendix prose against the simulation summary CSV before the table enters the draft.
