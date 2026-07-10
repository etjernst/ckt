# Dispositions on the external review of the extension-simulation spec and plan

2026-07-10.
Target of the external review: [the spec](file:///C:/git/ckt/quality_reports/specs/2026-07-10-extension-simulation-study.md) and [the plan](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md).
Prior internal review: [2026-07-10_simulation-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-10_simulation-plan-review.md).
External verdict: REVISE before approval, keeping the architecture (fixed design, IDN and TZA cells, three arms, pilot gates).
My assessment: the external review is right on the substance of its two sharpest findings (R1 and R4), which the internal review missed entirely, and its code-level factual claims check out against the source.
I recommend adopting most of it, with modifications recorded per finding below.
Nothing in it overturns decisions A through D; it tightens how they are executed.

## Claims I verified independently against the code

The reviewer asserted that the current `grc_gmm.py` applies collinearity dropping, making the plan's description of the Hansen J discrepancy ("the port keeps two collinear instrument columns Stata drops") stale.
Verified: `explorations/python-grc/grc_gmm.py` on the lca-inversion worktree has `_drop_collinear` (line 116) mirroring Stata's `_rmcoll`, composed with the sparse-cluster drop inside `fit` (line 530).
The recorded discrepancy ($J = 97.74$ at 29 df vs Stata's $86.52$ at 27 df) therefore predates the current source, and P2 must re-measure rather than cite it.

The reviewer asserted the port runs iterated GMM while the recorded Stata comparator is a single two-step pass.
Verified on the Python side: `fit` iterates the weighting matrix to a fixed point, `max_outer = 8` (lines 620 to 651).
The Stata side of the claim (production `gmm` runs plain two-step) is plausible but unverified here; it belongs in the P2 parity checklist.

I re-derived the R1 mixture algebra; it is correct (details under R1).

## Load-bearing findings

R1, the two-regime arm may not violate pooled LCA.
ADOPT in full; this is the review's best catch.
If regime membership is independent of trajectory and of $\theta_i$ given trajectory, then $\Delta_{\underline{d}} = \sum_r \lambda_r (\beta_r + \phi_r E[\theta \mid \underline{d}]) = \bar\beta + \bar\phi \mu_{\underline{d}}$, an exact line, so the pooled restrictions hold at every dial value and the J-test has nothing to detect.
The plan's current wording (global $\lambda$, regime-specific $(\beta_r, \phi_r)$, no statement about $\lambda_{r \mid \underline{d}}$ or $E[\theta \mid \underline{d}, r]$) permits exactly that degenerate implementation.
The fix is what the reviewer prescribes: trajectory-specific regime shares $\lambda_{r \mid \underline{d}}$ and regime-specific conditional means calibrated so the violation is real; an analytic population LCA residual vector computed at every dial value, required to be exactly zero at dial zero and monotonically increasing in the dial; dial zero exactly nesting the arm-one baseline (which the plan already gets via reusing arm-one replications, but the nesting must also hold in the truth definitions); and size-adjusted power alongside nominal rejection rates.
This goes into the P3 truth module as a hard unit check.

R2, the Python J cannot be an internal fallback.
ADOPT the tightening, with the failure branch left as an explicit Emilia decision rather than an automatic hard stop.
The reviewer is right that spec M3 (production estimation path) and the plan's fallback (internal-to-Python J with a disclosed df difference) contradict each other: size and power of a J-test with a different reference distribution do not validate the paper's test.
Concretely: P2 gains a J-parity requirement (instrument construction, collinearity and rank handling, GMM iteration scheme, J statistic, df, p-value) with predefined tolerances for every headline point estimate, plus source hashes in the parity report.
If parity fails inside the time box, the choice is between descoping the production-J claims by explicit spec amendment or extending the reconciliation effort, and that choice is presented at the gate, never defaulted.
The stale-source point above makes this less scary than it reads: the current port may already be much closer to Stata than the recorded discrepancy suggests.

R3, the baseline DGP is underspecified and iid errors favor the procedure.
ADOPT both parts.
Writing the complete DGP (potential-outcome equations, the $\tau_i$ component, all distributions, all covariance and independence restrictions) before coding is M1 hygiene and costs a day.
On the error process, the reviewer has the polarity right for a coverage study: production inference clusters by person precisely because empirical errors are serially dependent, and finite-sample coverage (the study's central question) depends on the effective information per cluster, which iid transitory shocks overstate.
Baseline becomes an empirically calibrated within-person dependent error process (autocovariance estimated from production residuals in `calibrate.py`), with iid as the favorable sensitivity, inverting the plan's current polarity.
Estimated extra cost: one to two build days in P1/P3.

R4, grid membership is not a reliable coverage definition.
ADOPT; this simplifies and sharpens at the same time.
Coverage of an inverted set is the probability that the test evaluated at the truth fails to reject, so $\phi$ coverage needs one test evaluation at $\phi_0$ per replication and no grid at all, and each $\Delta$ coverage needs the profiled statistic at $\Delta_0$ with continuous or adaptive nuisance minimization rather than a fixed nuisance grid.
The grid machinery is then only needed to reconstruct the reported set's topology and length, where the reviewer's classification (empty, bounded, disconnected, one-sided unbounded, two-sided unbounded, whole line, unresolved) and adaptive boundary refinement replace the current hit-grid-bound flag.
A grid-truncated set is scored unresolved, never as a completed set.
This supersedes the internal review's island-membership fix (finding 12), which treated the symptom.

R5, failure-aware performance measurement.
ADOPT wholesale; this is standard Morris, White, and Crowther practice and costs almost nothing.
Completion rates over all attempted replications; unconditional coverage with failures as misses, conditional coverage among valid fits, and the $[H/R, (H+F)/R]$ bounds; empty confidence sets scored as valid noncoverage outcomes, not failures (the plan currently never says how an empty set scores in arm-one coverage, which is a real gap); bias, empirical SE, and RMSE over finite estimates with $n_{\mathrm{eff}}$ reported; a predefined full-run failure threshold; every MCSE tied to its declared denominator.
All of this lands in `metrics.py` and the P8 table notes.

R6, truth definitions rest on unproven weighting claims.
ADOPT the machinery, with one pushback on the diagnosis.
The base-selection point is fully right: the auto-selected base can differ across replications, so the DGP truth line becomes base-invariant ($\Delta_{\underline{d}} = a + \phi \mu_{\underline{d}}$), the selected base is recorded per replication, and estimates are translated onto the invariant line before scoring.
The estimand registry (population functional, sample, exact weights per estimator) and the large-sample projection validation of every analytic truth both go into P3.
The pushback: under the plan's homogeneity choice, $\theta_i$ in the lumped cell is drawn with a common conditional mean independent of the observation pattern, and the auxiliary-OLS weights are functions of $(X, D)$ only, so the FWL-weighted average of $E[\theta_i]$ equals the common mean under any such weighting and the claimed invariance does hold in expectation.
That argument now gets written down and unit-tested (the reviewer's derivation requirement) instead of asserted, which is the correct resolution either way.

## Secondary findings

Y1, model-based SE diagnostics: ADOPT; add mean model SE and relative SE bias for Wald-type intervals, and report topology plus finite-set length for the inversions instead of a forced SE analogue.
Y2, Monte Carlo precision statement: ADOPT; the spec's $\pm 0.7$pp at $R = 1{,}000$ is one MCSE, and the protocol will say so and state precision targets for J rejection and failure rates too.
Y3, validation tranche: ADOPT; keep the R=20 pilot for timing only and add an $R \approx 100$ validation tranche covering every distinct execution path before freezing code and config hashes; this formalizes the plan's existing "re-check at the first R=100 tranche" into a named gate.
Y4, compute-gate completeness: ADOPT; memory per worker, BLAS thread nesting, atomic checkpoints, idempotent resume; the data-governance item is the one Emilia-facing piece, since the design snapshot contains consumption microdata and moving it to a server needs an explicit check against the data-use terms (connects to D4).
Y5, F-adjustment mathematics: ADOPT AT HALF STRENGTH; resolve the adjusted statistic, degrees of freedom, and nuisance-profiling interaction on paper during P3/P4 so P9 is implementation-only, but do not implement before the trigger; full early implementation buys nothing if coverage is fine.
The reviewer's `reg_sandwich` reconciliation point stands: the prior F-adjustment plan assumed Stata tooling and the current path is headless Python, so the paper-stage derivation must specify the Python route.
Y6, fixed-design scope statement: ADOPT; one appendix sentence saying the study validates estimator and inference behavior conditional on the empirical trajectory and covariate design, not the migration-choice mechanism.

G1, M1 vs config-driven architecture: ADOPT; amend M1 to one parameterized entry point taking a per-cell configuration.
G2, common random numbers across dial values: ADOPT; same rep-level seed across dial points within a cell sharpens the power curve at zero cost and composes with the dial-zero reuse already planned.
G3, model-routing portability: DECLINE as written; the routing language targets this workshop's Claude Code setup, and it converts to bounded briefs only if Emilia decides to implement elsewhere.

## What this does to the plan

The architecture survives untouched: fixed-design DGP, IDN and TZA, three arms, P0 through P10 with the P2 and P5 gates.
The changes concentrate in four places.
P2 gains the full parity gate (estimates, SEs where fixable, J, df, p-value, iteration scheme, hashes) with an explicit decision branch on failure.
P3 gains the written-out DGP with a dependent-error baseline, the exactly nested two-regime family with the analytic violation-residual check, the estimand registry with base-invariant truths, and the F-adjustment derivation on paper.
P4/P8 gain test-at-truth coverage, adaptive set reconstruction with topology classes, and the failure-aware metric suite with declared denominators.
P5 splits into a timing pilot (R=20) and a validation tranche (R about 100) with a hash freeze, and the compute memo adds checkpointing and the microdata-transfer governance check.
Build-time impact: roughly two to four extra days on the plan's 8-to-11-day estimate, plus the validation tranche's compute (about a tenth of a full run).
The R=1,000 full-run cost is unchanged; test-at-truth coverage is cheaper than full grid inversion per replication, partially offsetting the dependent-error and adaptive-topology additions.

## Open decisions for Emilia

1. Adopt the disposition set above and fold it into the plan (and the M1/M3/M8 spec amendments), or trim specific items.
2. The R2 failure branch: if J parity cannot be reached inside the time box, descope the production-J claims by spec amendment or extend the reconciliation; my recommendation is to decide only at the gate, with the stale-source finding suggesting parity is likelier than the recorded numbers imply.
3. The Y4 governance item: whether server execution of the consumption-microdata snapshot is permissible under the data-use terms, which only Emilia can check.
