# Plan review: extension simulation study for the ECMA draft

2026-07-10.
Reviewing as: applied econometrics methodology specialist.
Review depth: standard, including a fresh-context stress test and simulation-study best-practice check.
Plan source: [2026-07-10-extension-simulation-study.md](../plans/2026-07-10-extension-simulation-study.md).
Governing spec: [2026-07-10-extension-simulation-study.md](../specs/2026-07-10-extension-simulation-study.md).

## Verdict

REVISE before approval.
The study is well motivated and unusually disciplined about scope, reproducibility, and compute costs.
The fixed-design approach, IDN and TZA cells, and three-arm structure should remain.
Implementation should not begin yet because six methodological gaps could materially change the conclusions.

The plan already follows much of the ADEMP framework: explicit aims, DGPs, estimands, methods, and performance measures.
Best practice also calls for Monte Carlo uncertainty, model-based standard-error diagnostics, and explicit treatment of numerical failures.
The relevant benchmarks are Morris, White, and Crowther, ["Using simulation studies to evaluate statistical methods"](https://pmc.ncbi.nlm.nih.gov/articles/PMC6492164/), and ["On the assessment of Monte Carlo error in simulation-based statistical analyses"](https://pmc.ncbi.nlm.nih.gov/articles/PMC3337209/).

## Pre-mortem

The three most likely failure modes are:

1. The two-regime design does not actually violate pooled LCA, so the advertised J-test power and empty-region results never materialize.
2. Coverage looks artificially favorable because failures, grid-bound inversions, and the iid error calibration are handled conditionally or ambiguously.
3. The simulation reaches full scale before the Python Hansen J, variance estimator, and inversion numerics are demonstrably equivalent to the paper's production procedures.

## Strengths

1. The simulation targets the actual extension rather than repeating the existing $T=2$ validation.
2. The IDN and TZA rationale is persuasive.
3. Fixed trajectories and covariates are defensible for a conditional Monte Carlo.
4. Seeds, raw replication results, generated tables, and the compute gate are specified well.
5. The plan recognizes disconnected confidence regions and the possibility of empty sets.
6. Real-data parity and code review appear before the expensive run.

## Load-bearing findings

### R1. The two-regime arm may not violate pooled LCA

Severity: Red.
Confidence: High.
Location: spec M8 and S2; plan decision C and the two-regime truth definitions.

The design varies $\phi_1-\phi_2$, but a mixture of two linear relationships can remain linear.
With constant regime shares and common trajectory structure,

$$
\sum_r \lambda_r(\beta_r+\phi_r\theta)=\bar\beta+\bar\phi\theta.
$$

In that case, the J-test has no violation to detect.
The current use of global $\lambda_r$ in the truth definitions leaves this unresolved.
Setting only $\phi_1=\phi_2$ also does not reproduce arm one if intercepts, conditional means, variances, or regime composition differ.

Required revision:

- Specify trajectory-specific regime shares $\lambda_{r\mid d}$ and regime-specific $E[\theta\mid d,r]$.
- Make dial zero nest the entire baseline DGP, including intercepts, distributions, and composition, rather than merely equalizing slopes.
- Before simulation, calculate the population LCA residual vector.
It must be exactly zero at dial zero and nonzero at positive dials.
- Parameterize the dial by distance from the restricted moment manifold, or at least verify that the intended violation increases monotonically.
- Report size-adjusted power as well as nominal 5 percent rejection rates.

### R2. The Python J-test cannot be an internal fallback

Severity: Red.
Confidence: High.
Location: spec M3 and M8; plan decision B and P2.

M3 requires the production estimation path.
Yet the plan would proceed with a Python J of 97.74 at 29 degrees of freedom when production Stata gives 86.52 at 27 degrees of freedom.
That does not validate the J-test used in the paper.
Computing size and power with the same Python implementation does not repair the incorrect reference distribution or make it production-equivalent.

There is also a broader parity issue.
The port uses iterated GMM while the recorded Stata comparator uses a single two-step pass.
The current source applies collinearity dropping, so parts of the plan's port description may now be stale.

Required revision:

- Make instrument and rank handling, estimator iteration, J statistic, degrees of freedom, and p-value parity a hard gate.
- Predefine tolerances for every headline point estimate, not only $\phi$.
- Record source hashes in the parity report.
- If parity fails, either remove the production-J claims or return to the spec for an explicit scope change.
Dropping Wald coverage does not resolve the J problem.

### R3. The baseline DGP is not fully defined and favors the inference procedure

Severity: Red.
Confidence: High.
Location: spec M1 and M2; plan truth definitions and calibration inputs.

The plan names $\sigma_\theta$ and $\sigma_\nu$, but does not state the complete potential-outcome equations, the absolute-advantage component, covariance restrictions, treatment-slope heterogeneity, or the relationships between unobservables, trajectories, and fixed covariates.
It then assumes iid transitory shocks despite known within-person serial dependence.
That is too favorable for a study whose central question is honest uncertainty.

Required revision:

- Write the complete DGP mathematically before coding.
- State every distribution and conditional independence restriction needed for the GRC moments.
- Use an empirically calibrated clustered-error process as the baseline, including serial correlation and trajectory-relevant heteroskedasticity.
- Keep iid shocks as a favorable sensitivity.
- Require simulated covariance moments and all population GRC moments to match their targets before the pilot.

### R4. Grid-based island membership is not a reliable coverage definition

Severity: Red.
Confidence: High.
Location: spec objectives 2 and 3 and M8; plan decision B and inversion machinery.

Having the truth inside the chosen grid does not ensure that the confidence-set boundary or nuisance minimizer lies inside it.
A grid hit is an unresolved numerical result, not merely a diagnostic flag.

Coverage can be assessed more directly.
The truth belongs to an inverted set exactly when the test evaluated at the truth does not reject.

Required revision:

- For $\phi$, calculate coverage from the p-value evaluated directly at $\phi_0$.
- For each $\Delta$, evaluate the profiled test at $\Delta_0$, with adaptive or continuous nuisance minimization.
- Use adaptive grid expansion and boundary refinement to reconstruct the reported set.
- Classify sets as empty, bounded, disconnected, one-sided unbounded, two-sided unbounded, whole-line, or unresolved.
- Report topology and finite-set length in addition to coverage.
- Never score a grid-truncated result as a completed confidence set.

### R5. Failure recording is not the same as failure-aware performance measurement

Severity: Red.
Confidence: High.
Location: spec M4 and M7; plan `run_one.py`, `metrics.py`, P4b, P8, and the risks section.

The spec says failures are reported, but does not define their role in coverage, bias, empirical SE, or RMSE.
Successful-fit metrics plus a failure count can still make a fragile estimator appear reliable.

Required revision:

- Report completion rates over all attempted replications.
- Report unconditional coverage with numerical failures counted as misses, conditional coverage among valid results, and bounds $[H/R,(H+F)/R]$ when failure coverage is unknowable.
- Treat an empty confidence set as a valid inferential outcome and a noncoverage, not as numerical failure.
- Report bias, empirical SE, and RMSE over finite estimates with $n_{\mathrm{eff}}$.
- Predefine a full-run failure threshold that blocks publication or triggers solver remediation.
- Calculate every MCSE using its declared denominator.

### R6. Some truth definitions depend on unproven weighting claims

Severity: Red.
Confidence: High.
Location: plan truth definitions.

The plan does not say whether $\pi_d$ is based on people, observations, or effective estimation weights.
More importantly, the unbalanced-cell auxiliary-OLS coefficient is an FWL-weighted projection.
A common unconditional mean for $\theta_i$ may not be sufficient to establish the claimed target.

The auto-selected base creates another ambiguity.
The DGP truths are defined relative to $d_0$, but the selected base can change across replications.

Required revision:

- Create an estimand registry giving each estimator's population functional, sample, and exact weights.
- Derive the auxiliary-OLS target conditional on the fixed $X,D$ matrix.
- Define the DGP using a base-invariant line, such as $\Delta_d=a+\phi\mu_d$, then translate to whichever base the estimator selects.
- Record the selected base in every replication.
- Validate all analytic truths against a large-sample population-projection calculation.

## Important secondary revisions

### Y1. Add model-based uncertainty diagnostics

Severity: Yellow.
Confidence: High.

Add mean model SE and relative SE bias alongside empirical SE.
The raw schema stores `se`, but the summary does not commit to using it.
For set-valued inversion, report coverage, topology, and finite-set length rather than forcing an SE analogue.

### Y2. State the Monte Carlo precision criterion correctly

Severity: Yellow.
Confidence: High.

At $R=1{,}000$ and coverage 0.95, the MCSE is 0.69 percentage points, while the approximate 95 percent Monte Carlo half-width is 1.35 percentage points.
State whether each threshold refers to one MCSE or a 95 percent Monte Carlo interval.
Choose $R$ using explicit precision targets for every headline metric, including J rejection and failure frequencies.

### Y3. Separate timing from validation pilots

Severity: Yellow.
Confidence: High.

$R=20$ is adequate for timing, not for topology, convergence, metric, or J-size validation.
Add an $R\approx100$ validation tranche covering every distinct path: pooled, split, inversion, IDN, and TZA.
Freeze code and configuration hashes after this tranche passes.

### Y4. Make the compute gate configuration-complete

Severity: Yellow.
Confidence: High.

Measure memory per worker, parallel efficiency, nested BLAS threads, I/O, retries, and split-fit costs.
Four-day runs also require atomic checkpoints, idempotent resume, and duplicate-key protection.
If a server is used, add an explicit data-governance approval for transferring the fixed-design microdata snapshot.

### Y5. Resolve the F-adjustment mathematics before the full run

Severity: Yellow.
Confidence: High.

Implementation may remain contingent on observed undercoverage.
The adjusted statistic, numerator and denominator degrees of freedom, nuisance profiling, and validation fixtures cannot remain unresolved until P9.
The earlier Stata-based `reg_sandwich` plan also needs reconciliation with the current headless Python requirement.

### Y6. State the fixed-design scope narrowly

Severity: Yellow.
Confidence: High.

The fixed design can validate estimator and inference behavior conditional on the empirical trajectory and covariate design.
It cannot validate the migration-choice mechanism or unconditional selection behavior.
The appendix should state that scope explicitly.

### G1. Align M1 with the config-driven architecture

Severity: Green.
Confidence: High.

The plan's config-driven family functions are cleaner than one separate implementation per country cell, but they conflict formally with spec M1.
Amend M1 to require one parameterized entry point accepting a per-cell configuration, or add trivial cell wrappers.

### G2. Use common random numbers across dial values

Severity: Green.
Confidence: Medium.

Use common random numbers across violation-dial values within each cell and replication.
This will sharpen paired comparisons while preserving independent streams across replications.

### G3. Make model routing portable

Severity: Green.
Confidence: High.

Replace the nonportable `model: "sonnet"` routing language with bounded subagent briefs if the plan will be implemented in Codex.

## Recommended revised sequence

1. Freeze an ADEMP protocol: estimand registry, metric formulas, denominators, failure taxonomy, set topology, and precision targets.
2. Make complete Stata and Python estimator and J-test parity the first hard gate.
3. Specify and calibrate the full clustered-error DGP.
4. Build the baseline and an exactly nested two-regime violation, then verify population restrictions analytically and numerically.
5. Validate inversion membership, adaptive topology reconstruction, and the F-adjustment mathematics.
6. Build the per-replication pipeline, failure handling, metrics, and restartable storage.
7. Run independent code review, failure-injection tests, and large-sample truth checks.
8. Run $R=20$ timing pilots for every distinct execution path.
9. Run an $R\approx100$ validation tranche and freeze hashes after it passes.
10. Price the complete matrix and obtain compute and data-governance approval.
11. Run the frozen full study.
12. Generate the appendix and run alignment review against the raw summary.

## Recommendation

Approve design decision A and retain the study's overall scope.
Require a targeted spec addendum and a revised plan before code begins.
