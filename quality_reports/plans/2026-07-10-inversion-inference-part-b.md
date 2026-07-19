# Plan: inversion-inference validation and rerun

Date: 2026-07-10

Status: draft for author approval.

Governing specifications:

- `quality_reports/specs/2026-07-10-citation-and-inversion-paper-update.md`, Phase B only.
- `quality_reports/specs/2026-07-10-extension-simulation-study.md`.

## Objective

Determine whether the paper's inversion confidence sets have reliable coverage in the empirical IDN and TZA designs; correct the inference implementation if they do not; and regenerate the empirical inversion and counterfactual outputs. This work does not edit the manuscript and does not rerun GMM point estimation unless a separate integrity gate requires it.

## Non-negotiable outputs

1. A frozen baseline that reproduces the current synthetic and empirical inversion results.
2. Candidate-level rank, conditioning, generalized-inverse, and grid-bound diagnostics.
3. A production-path IDN/TZA Monte Carlo with raw replication results, failures, seeds, and Monte Carlo standard errors.
4. If required, a validated finite-sample adjustment and a direct adjusted-versus-current comparison.
5. Regenerated empirical inversion/counterfactual outputs plus an endpoint-change report.
6. A written decision on whether the full GMM sweep is necessary.

## Step 0: freeze the baseline

1. Create an execution manifest containing:
   - git revision and hashes of `lca_inversion.py`, `counterfactuals.py`, the Python GMM port, and the production Stata inversion scripts;
   - Python/Stata and package versions;
   - input `.ster`, CSV, and data-snapshot hashes;
   - random seeds, tolerances, pseudoinverse cutoff, grid bounds, and grid spacing.
2. Reproduce without code changes:
   - the current generic `T=2`, `T=3`, and `T=4` coverage summaries;
   - current empirical scalar/profile inversion outputs;
   - current joint counterfactual regions.
3. Save baseline outputs under a versioned directory. Never overwrite them during later stages.

**Gate 0:** Stop if the existing results cannot be reproduced. Diagnose environment or input drift before changing inference code.

## Step 1: harden diagnostics without changing reported inference

1. At every candidate point, record:
   - number of restrictions;
   - numerical rank of the restriction covariance;
   - smallest and largest retained singular values and condition number;
   - whether the generalized inverse discarded any direction;
   - nominal degrees of freedom and reference-law degrees of freedom;
   - Wald statistic, p-value, convergence/failure status, grid-bound hit, and component identifier.
2. For each candidate `c`, form `Omega(c) = A(c) V A(c)'`, symmetrize it, and normalize it by its diagonal scale before computing rank.
3. Use `rcond=1e-10` as the primary rank tolerance after normalization and require the accepted-set topology and endpoints to be stable at `1e-8` and `1e-12`.
4. Check that the restriction residual lies in the column space of `Omega(c)` to the documented numerical tolerance.
5. Handle exact algebraic redundancy in two independently coded ways:
   - reduce the restrictions to a verified full-row-rank basis and use its dimension as the chi-squared degrees of freedom;
   - use the Moore--Penrose quadratic form with degrees of freedom equal to `rank(Omega(c))`.
   The two statistics and p-values must agree within tolerance.
6. Treat numerical ill-conditioning as a rescaling/recomputation problem or a failure, not as permission to lower degrees of freedom silently.
7. Candidate-dependent structural rank changes require a written derivation of the limiting law and targeted tests at the rank-change points. Without that derivation, the affected cell fails.
8. Add unit tests that construct the fixed-candidate restriction vector and candidate-specific covariance directly from the auxiliary OLS coefficient vector and covariance matrix.
9. Add an invariance test showing that coefficient ordering and the choice of an equivalent full-rank restriction basis do not change the statistic.
10. Add a guard against ratio-based implementations of `phi`; all tests must remain in fixed-candidate restriction form.

**Gate 1:** Every rank loss must be classified as exact algebraic redundancy, numerical ill-conditioning, candidate-dependent structural rank change, or a coding/data defect. The basis-reduced and generalized-inverse tests must agree for exact redundancy; all other unresolved cases stop the cell.

## Step 2: remove grid artifacts

1. Write down the scientifically admissible parameter domain implied by the model before coding the search. If the domain is finite, a component that reaches it is `domain-truncated`, not unbounded.
2. Replace fixed-bound endpoint reporting with a two-stage search:
   - a coarse, cell-specific bracketing grid wide enough to locate every accepted component;
   - local refinement of each rejection/acceptance boundary to `1e-4` in the reported parameter's units, with a tighter-tolerance sensitivity check at `1e-5`.
3. Use adaptive subdivision around sign changes, discontinuities, and rank-change points so a narrow accepted component is not missed merely because both ends of a coarse interval reject.
4. Preserve disconnected components; never replace them with their convex hull.
5. On an infinite parameter domain, label a scalar component unbounded only after an analytic or numerically verified tail certificate establishes that the acceptance decision persists in that direction. Reaching an expansion cap is an unresolved search failure.
6. For joint regions, require adaptive contour and domain-boundary checks in each open direction; do not infer unboundedness from a plotting box.
7. Record empty sets, component counts, expansions, refined endpoints, domain truncation, tail certificates, and unresolved boundary hits.
8. Test the refined routine against the current 0.01 grid and report endpoint differences.

**Gate 2:** No empirical or simulated set proceeds with an unresolved boundary search. Every open component must be certified as unbounded or labeled domain-truncated under the documented parameter domain.

## Step 3: validate the real-data harness

1. Feed the empirical IDN and TZA data through the Python production path.
2. Reconcile Python and Stata for the estimation sample, observation/cluster weights, design columns, omitted categories, coefficient ordering, auxiliary-regression coefficients, and the full cluster-robust covariance including finite-sample corrections.
3. At pre-specified sentinel candidates in the accepted interior, near each endpoint, and in the tails, reconcile restriction matrices, transformed covariances, ranks, Wald statistics, and p-values.
4. Reproduce the Stata point estimates and all quantities above within pre-specified absolute and relative tolerances.
5. Reconcile Python/Stata collinear-column handling and Hansen-`J` degrees of freedom.
6. If Hansen `J` cannot be reconciled within a two-day time box, quarantine it as an internally consistent Python simulation diagnostic, exclude it from every inversion decision, and label it non-comparable to the production Stata specification test.
7. Confirm that the inversion covariance comes from the individual-clustered saturated auxiliary OLS and never from the GMM variance matrix.

**Gate 3:** Synthetic work cannot begin until the real-data harness reproduces the relevant production quantities or every remaining discrepancy is explicitly quarantined.

## Step 4: run the R=20 IDN/TZA pilot

1. Use the approved fixed-design, country-calibrated DGP and the actual production estimation path.
2. Run 20 replications for IDN and 20 for TZA.
3. Treat this pilot only as a correctness, failure-mode, and runtime exercise. Do not interpret its coverage rate.
4. For every replication, save estimates, confidence-set components, truth, coverage indicator, rank/grid diagnostics, convergence status, failure reason, seed, and runtime.
5. Any failed replication triggers diagnosis before scaling.
6. Produce projected wall-clock, memory, and storage costs for the R=500 discovery run and the power-sized confirmatory run, including the two-regime misspecification arm.

**Gate 4:** Present the pilot diagnostics and compute budget before launching the full Monte Carlo.

## Step 5: pre-register the coverage decision

1. The headline family contains, for both IDN and TZA:
   - `phi`, `Delta_dN`, `Delta_avg`, `Delta_dT`, and `Delta_unb`;
   - coverage of the true `(phi, Delta_d0, Delta_unb)` point by the joint region;
   - every projected aggregate interval currently reported in the counterfactual table, enumerated by name in the execution manifest before simulation.
2. Set the substantively acceptable coverage floor at 94% for a nominal 95% procedure (`delta = 0.01`).
3. Control the familywise one-sided error rate at 5% across the complete headline family using Bonferroni-adjusted exact binomial bounds.
4. After the pilot fixes runtime, choose the confirmatory replication count by exact-binomial power so there is at least 80% probability of approving a procedure whose true coverage is 95%. The confirmatory run may not have fewer than 1,000 replications per cell/arm.
5. Pre-generate two disjoint seed banks:
   - discovery seeds for diagnosing and selecting the procedure;
   - confirmatory seeds that cannot influence backend, tolerance, grid, or adjustment choices.
6. For computational failures, use all attempted replications as the primary denominator. Report lower and upper coverage bounds by scoring each unresolved failure as uncovered and covered. Empty sets are ordinary noncoverage when they exclude the truth, not computational failures.
7. A procedure can pass only if the familywise-adjusted lower binomial bound is at least 94% for every headline item under both failure assignments. It fails if the adjusted upper bound is below 94% for any item. Otherwise the result is inconclusive and requires a larger pre-specified confirmatory run or a stop; it is not a pass.

**Gate 5:** Freeze the headline family, 94% floor, multiplicity rule, failure scoring, confirmatory sample size, and both seed banks before any discovery results are examined.

## Step 6: discovery study and method selection

1. Run R=500 on the discovery seeds for the current procedure in the approved LCA-true IDN/TZA designs and two-regime misspecification arm.
2. Save every replication, including estimates, truth, accepted components, rank/grid diagnostics, convergence status, failure reason, seed, and runtime.
3. Report bias, empirical standard deviation, RMSE, coverage and MCSE, exact binomial intervals, bounded-set length, topology frequencies, and failure bounds.
4. Activate the finite-sample-adjustment work if the discovery results show headline coverage below 94%, if existing rank/reference-law gates fail, or if the adjusted procedure is otherwise required by the approved specification.
5. Use the existing backend-selection specification rather than an ad hoc critical-value change. Require each candidate adjustment to pass a small-design anchor, IDN-scale resource limits, stable rank/df diagnostics, and discovery-seed comparisons against the current procedure.
6. Freeze the selected procedure, tolerances, grids, and code hash before opening the confirmatory seed bank.
7. Keep the current chi-squared procedure as a labeled comparison. If no candidate survives discovery, stop before empirical reruns and scope bootstrap-calibrated inversion separately.

**Gate 6:** Econometrics and fresh code reviews must approve the frozen procedure before confirmation.

## Step 7: independent confirmatory coverage study

1. Run the frozen current and selected procedures on the same confirmatory replications for precision, while keeping all confirmatory seeds independent of method selection.
2. Use the fixed, power-sized replication count from Step 5; do not stop early based on favorable coverage.
3. Apply the pre-registered familywise binomial rule and failure bounds exactly as written.
4. Report conditional-on-success coverage only as a secondary diagnostic.
5. Release the procedure to empirical inference only if every headline item passes and no rank, boundary, or reproducibility gate remains unresolved.

## Step 8: rerun empirical inference

1. Using the validated final procedure, rerun for every production cell:
   - the saturated auxiliary OLS;
   - scalar inversion for `phi`;
   - profile inversions for `Delta_dN`, `Delta_avg`, and `Delta_dT`;
   - the joint counterfactual region and projected aggregate intervals.
2. Regenerate machine-readable outputs without overwriting the baseline.
3. Produce a before/after comparison of:
   - every endpoint;
   - bounded, unbounded, empty, and disconnected status;
   - accepted-component count;
   - rank/reference-law diagnostics;
   - counterfactual interval endpoints and coverage-floor calculations.
4. Investigate any change larger than the pre-specified numerical tolerance before accepting the output.

## Step 9: decide whether to rerun GMM

Do not rerun the multi-day GMM sweep unless at least one condition holds:

1. Required `.ster` inputs cannot be recovered and hash-validated together with their generating scripts, data/sample identity, convergence state, objective diagnostics, parameter ordering, and downstream parameter mappings.
2. Production point estimates fail the reproduction tolerance.
3. The accepted inference change alters GMM estimation rather than only auxiliary-OLS inversion.
4. China/hukou outputs cannot be regenerated coherently from validated existing estimates.

If none holds, document that point estimates were preserved and only the inference layer was rerun. If a condition holds, prepare a separate costed GMM-rerun plan before launching it.

## Required reviews

1. Targeted unit and integration tests after Steps 1--3.
2. `critic-python` after any Python edit; `critic-stata` after any Stata edit.
3. `critic-econometrics` at Gates 1, 5, and 6.
4. `critic-alignment` after the final empirical rerun.
5. `verifier-build` before any commit or handoff.

## Stop rules

- Baseline reproduction fails.
- Unexplained candidate-dependent rank changes remain.
- Any final set has an unresolved boundary or unboundedness classification.
- Pilot failures are not diagnosed.
- The coverage decision changes between the all-failures-uncovered and all-failures-covered bounds.
- Confirmatory coverage is below or inconclusive under the pre-registered familywise rule.
- Empirical outputs change without a traceable code, input, or reference-law explanation.
