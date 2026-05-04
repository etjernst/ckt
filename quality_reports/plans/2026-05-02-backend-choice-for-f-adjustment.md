# Plan: backend choice for AHZ-adjusted CR2 inference at LCA-inversion scale

Date: 2026-05-02
Branch: `lca-inversion`
Status: decision plan; supersedes the implicit Stata-`reg_sandwich`-as-engine assumption baked into [`2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md) (rev 3).
Predecessor memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## Why this plan exists

Step 0a of plan rev 3 produced two empirical findings.

First, Stata `reg_sandwich` on the TZA covs_trend design without FE absorption scales as roughly $O(J^2)$: 90 s at $J=1000$, 366 s at $J=2000$, extrapolated $\sim 3$ h at the full $J=11{,}012$.

Second, R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocates a dense $N \times N$ intermediate; it OOM'd at $J=11{,}012$, $N=29{,}864$ on a workstation with $>13$ GB free.

The 2026-05-02 evening memo proposed pivoting the production backend from Stata `reg_sandwich` to R `clubSandwich`.
The user pushed back: if R OOM'd at TZA, it cannot scale to IDN ($J \approx 30{,}000$, $N \approx 90{,}000$).
That objection is correct and kills the speed half of the original pivot argument.
What remains is an architectural argument (R `Wald_test` accepts an arbitrary linear-constraint matrix; Stata `test_sandwich` is varlist-only), which is real but applies only after the per-cell `vcovCR` step succeeds.

The choice of backend is therefore not Stata-vs-R.
It is: how do we compute the BRL CR2 covariance and its AHZ Satterthwaite df at LCA scale at all, and only then, which of the surviving paths is cleanest.
This plan enumerates the surviving paths, costs them, and proposes the order in which to test them before any more code lands.

## What the BRL+AHZ computation actually requires

Bell-McCaffrey CR2 (the BRL adjustment in Pustejovsky-Tipton 2018) is

$$\widehat{V}_{CR2} = (X'X)^{-1} \left[\sum_{j=1}^{J} X_j' A_j \hat{u}_j \hat{u}_j' A_j' X_j \right] (X'X)^{-1}, \qquad A_j = (I_{n_j} - H_{jj})^{-1/2},$$

with $H_{jj} = X_j (X'X)^{-1} X_j'$ the $n_j \times n_j$ hat block for cluster $j$.

The AHZ (HTZ in `clubSandwich` notation) Satterthwaite degrees of freedom for a $q$-dimensional linear contrast $C\beta = 0$ is a closed-form function of the per-cluster influence matrices.
The Satterthwaite df is computed once per contrast $C$ from these matrices; evaluating the test at any new $\phi$ given a cached $V$ and cached $G_j$ is sub-second.

Two implementation facts matter for what follows.

First, the per-cluster computation is $O(JK^2) + O(\sum_j n_j^3)$ in time and $O(JK^2)$ in memory if we store the per-cluster influence matrices.
At our regime ($J \approx 30{,}000$, $K \approx 27$, $\bar{n}_j \approx 3$) this is roughly $2 \cdot 10^7$ floating-point ops for the meat and $\sim 175$ MB for the influence cache.
Both are trivial.

Second, the off-the-shelf packages blow up because of how they organize the computation, not because the computation is expensive.
`clubSandwich::vcovCR` materializes a dense projection-like intermediate of size $O(N^2)$ at one or more steps.
`reg_sandwich` (unabsorbed) materializes a similar object inside its Mata routine.
Cluster-by-cluster, the BRL+AHZ machinery is fundamentally cheap in our regime.
This reframing is what makes the from-scratch path viable; it was speculative when the user originally rejected it.

## The constraint complication shared by every absorbed path

The LCA contrast is

$$r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0, \qquad s \in S_R \setminus \{base\}.$$

It involves both the trajectory main effects $\alpha_s$ and the trajectory-by-treatment interactions $\beta_s$.
The auxiliary OLS at $T = 5$, $K = 27$ has $J_R = 26$, so trajectory dummies $\alpha_s$ are responsible for almost all of $K$.

Absorbing trajectory FE (`absorb(trajectory)` in Stata, `feols(..., fixef = "trajectory")` in R) removes the $\alpha_s$ from `e(b)`.
The LCA contrast cannot be expressed directly on the absorbed model.
Three reformulations are possible, but each requires verification against a known answer before going into production:

- Recover the $\alpha_s$ from the absorbed-FE estimates and form the contrast post-estimation.
The CR2 covariance between the recovered $\alpha_s$ and the included $\beta_s$ is what we actually need; FWL guarantees the point estimates align but the covariance recovery is non-trivial.
- Reparametrize the auxiliary OLS so the LCA constraint becomes a constraint on coefficients that survive absorption.
This is a mechanical change of basis but the resulting design loses some of the interpretability of $(\alpha_s, \beta_s)$.
- Drop absorption entirely.
Possible only if the per-cluster path keeps $K \approx 27$ tractable.

This complication applies to paths A, B, and E below.
Paths C and D sidestep it.

## Candidate paths

### Path A. Stata `reg_sandwich` with `absorb(trajectory)` at full scale

The test that should have preceded the pivot.
At Step 0a, Spec A (unabsorbed, `i.trajectory` dummies) was killed at 17 minutes; Spec B (`absorb(trajectory)`) was never run because the broader pivot question intervened first.

Open empirical questions:

- Does `reg_sandwich, absorb(trajectory)` complete on the TZA covs_trend design at $J=11{,}012$ within an order of magnitude of the small-$J$ extrapolation, and does memory stay sub-`xmax`?
- Does it expose the absorbed FE coefficients (`e(absvars)` or via post-estimation `predict`) and a CR2 covariance between absorbed and included coefficients sufficient to evaluate the LCA contrast?
- Does it silently produce a degenerate AHZ df at this $K$/$J$ ratio (the rev-3 reviewer's near-singularity concern, which Step 0a was supposed to A/B-test)?

Cost to answer all three: one TZA Spec B run plus a side-by-side AHZ-vs-HTZ check at the same scale through a pre-built smaller-$J$ subset.
Estimated wall: 1-2 hours including the LCA-contrast bookkeeping.

### Path B. R `fixest::feols` partialling + `clubSandwich::vcovCR`

`clubSandwich` 0.6.2 has `vcovCR.fixest` and `Wald_test.fixest` methods.
`feols` partials trajectory FE inside the OLS step (Mundlak-style demeaning rather than a dummy expansion), which collapses the dense intermediate that OOM'd at full TZA scale.

Open empirical questions:

- Does `vcovCR(feols_fit, cluster = "pid", type = "CR2")` fit in memory at TZA scale, and at IDN scale?
- Does `Wald_test` accept a constraint matrix that references the absorbed FE, or does it treat absorbed FE as nuisance and refuse contrasts on them?
- Does `clubSandwich`'s sparse or block-diagonal code path for `feols` activate at our cluster pattern, or does it route through the same dense path that OOM'd?

Cost to answer: a single $J=11{,}012$ `feols` + `vcovCR` benchmark, plus one $J \approx 30{,}000$ synthetic-design probe for IDN scale.
Estimated wall: 2 hours including the synthetic IDN-scale design build.

### Path C. From-scratch BRL with cluster-by-cluster computation

Implement the CR2 meat and the AHZ Satterthwaite df directly, never materializing $H$ as a dense $N \times N$ object.
Loop over clusters, compute $A_j$ via eigendecomposition of the $n_j \times n_j$ block $H_{jj}$, accumulate the meat and the per-cluster influence matrices into a $J \times K \times K$ tensor.
The Wald test at any $\phi$ becomes $O(K^2 q + J q^2)$ in the cached influence matrices.

Cost analysis at the LCA regime ($J \approx 30{,}000$, $K = 27$, $\bar{n}_j \approx 3$):

- Time for one `vcov + AHZ-df` build: $\sim 2 \cdot 10^7$ ops for the meat, $\sim 8 \cdot 10^5$ for per-cluster eigendecompositions, dominated by Python/numpy loop overhead.
A vectorized batched implementation should land at single-digit minutes.
- Memory: $JK^2 \cdot 8$ bytes $\approx 175$ MB for the influence cache; trivially fits.
- Per-grid Wald test: closed form, sub-second.

Risk: AHZ Satterthwaite df implementation correctness.
The PT 2018 Theorem 2 derivation has the 2023 corrigendum; any from-scratch implementation has to match the corrigendum, not the original.
Mitigation: anchor against `clubSandwich` 0.6.2 (which incorporates the corrigendum on R's side) at $J \le 2000$ where `clubSandwich` runs cleanly, with a tolerance of $10^{-4}$ on the test statistic and $10^{-3}$ on the df.

This is the path the user previously rejected on novelty grounds.
The rejection was made before `clubSandwich` was viable as a small-$J$ verification anchor.
With the anchor in place, the novelty risk is concentrated in the implementation step, not the methodological step.

Implementation effort: 1-2 days for the meat, the Satterthwaite df, and the cross-check harness.

### Path D. Wild cluster bootstrap inversion

WCB inversion is already specified as Step 3.5 in plan rev 3 as a conditional comparison run.
Path D promotes WCB to the production backend.

Stata `boottest` (Roodman et al. 2019) and R `fwildclusterboot` are both implemented to avoid materializing dense $N \times N$ objects.
They re-multiply per-cluster scores by Rademacher draws, compute the test statistic per draw, and accumulate the empirical distribution.
Per-cell cost: $\sim 999$ bootstraps $\times$ 30 grid points $\times \sim O(N + JK)$ per draw.
At TZA scale this is $\sim 5$ minutes per cell; at IDN scale, $\sim 15$ minutes per cell.

Pros:

- Off-the-shelf packages handle the scaling problem in a way `vcovCR` does not.
- The WCB-Wald inversion is a published method with no novelty risk.
- The constraint matrix can be passed directly via `boottest`'s multi-restriction syntax.

Cons:

- Bootstrap MC noise enters the published CIs.
At $B = 999$ the per-grid-point p-value MC SE is $\sim 0.01$, which is comparable to the AHZ-vs-chi-squared difference we are trying to detect.
Promotion to production requires either $B \ge 9999$ (manageable) or a careful argument that the inversion-band MC SE is small relative to the band width.
- The published table would change from "F-adjusted" to "WCB-inverted" and the corresponding referee narrative would shift accordingly.
- AHZ remains the load-bearing comparison method; demoting AHZ to a small-$J$ comparison and elevating WCB to primary changes which method bears the burden of the validation gate.

### Path E. Hybrid: absorb FE first, then cluster-by-cluster BRL on the partialled design

A combination of the K-reduction in paths A and B with the dense-matrix avoidance in path C.
After `feols` (or `areg`) partialling, the residualized design has $K_{\text{free}} \ll K$ free parameters; the cluster-by-cluster BRL on this reduced design is cheaper than path C's full-K version, and the FE-recovery problem becomes "do we need contrasts on the absorbed coefficients" rather than "do we have access to them".

Whether path E is meaningfully cheaper than path C depends on whether the LCA contrast can be reformulated to live entirely on the included $\beta_s$, which it cannot in its current form (it explicitly involves $\alpha_s$).
Path E only helps if we accept reformulation 1 from the constraint complication section (recover $\alpha_s$ post-estimation) and treat the reduced-design BRL as a numerical accelerator.
In practice path E is likely a refinement of path C rather than a separate path.
Listed for completeness.

## Cost comparison

| Path | Prototype effort | TZA-scale wall | IDN-scale wall | FE-recovery effort | Novelty risk | Anchor available |
|---|---:|---:|---:|---:|---:|---:|
| A. Stata absorbed `reg_sandwich` | 1-2 h | unknown | unknown | yes (high) | none | clubSandwich at small $J$ |
| B. R `feols`+`vcovCR` | 2 h | unknown | unknown | yes (high) | none | clubSandwich at small $J$ |
| C. From-scratch BRL | 1-2 days | minutes | minutes | none (uses original design) | medium (impl) | clubSandwich at $J \le 2000$ |
| D. WCB inversion | 0.5-1 day | minutes | $\sim 15$ min/cell | none | none | published method |
| E. Hybrid (absorb + cluster BRL) | 2-3 days | minutes | minutes | yes (high) | medium (impl) | clubSandwich at small $J$ |

The "unknown" entries for paths A and B are exactly what the next benchmarks resolve.

## Recommended order of attack

The work breaks into two short empirical checks followed by one of two longer code paths.

First check (1-2 h).
Run `reg_sandwich, absorb(trajectory)` on the TZA covs_trend design at full scale ($J=11{,}012$).
Capture wall time, peak memory, and whether the AHZ test on the LCA contrast is computable post-estimation (either directly on absorbed FE coefficients or via a contrast-recovery step).
Cross-check the AHZ p-value against a $J \le 2000$ subsample from the same design via clubSandwich for numerical agreement.
If this check passes, write plan rev 4 with path A as the production backend.

Second check (1-2 h, conditional on the first failing).
Run `feols(..., fixef = "trajectory")` followed by `vcovCR(..., type = "CR2")` on the same TZA design.
Capture wall time, peak memory, and whether `Wald_test` can express the LCA contrast.
If memory holds at TZA scale, also probe a synthetic IDN-scale design ($J = 30{,}000$, $N = 90{,}000$) for the OOM threshold.
If both scales pass, write plan rev 4 with path B as the production backend.

Decision branch.
If both checks fail, two paths remain.

- Path C. Implement BRL+AHZ from scratch.
1-2 days code, anchored against clubSandwich at $J \le 2000$.
This is the highest-control path and the one that does not depend on package internals at the scale where they fail.
The user previously rejected this path; it should not be pursued without explicit re-approval, with the clubSandwich-anchor argument as the reason for revisiting.
- Path D. Promote WCB inversion from Step 3.5 to primary.
0.5-1 day code, no novelty risk, but the published CIs become bootstrap-based and the referee story changes accordingly.
Less methodological freight, more storytelling work.

The choice between C and D after both checks fail is a methodological decision the user should make, not a coding decision.

## Open decision points

These are the questions whose answers determine which plan rev 4 to write.

1. Does `reg_sandwich, absorb(trajectory)` complete on TZA full-scale, and if so, can the LCA contrast be expressed against its output?
2. Does `vcovCR.fixest` avoid the $N \times N$ intermediate that killed the unabsorbed run?
3. If both fail, is the user willing to revisit the from-scratch path now that clubSandwich is available as a small-$J$ anchor, or does the original novelty objection still stand?
4. Is WCB inversion an acceptable backend for the published F-adjusted CIs, or only as a comparison run?
5. Does the FE-recovery step needed for paths A, B, and E introduce its own novelty risk that the user wants to avoid?

## What this plan is not

This is not a step-by-step implementation plan.
It is a decision plan whose output is which of A through E becomes the basis for plan rev 4.
The implementation details (Stata wrapper structure, Python bridge, subprocess verification, synth coverage MC, empirical re-run) are unchanged from plan rev 3 and ride on top of whichever backend the next checks ratify.

If none of A through E is acceptable, the work parks; the chi-squared-based CIs in the existing pipeline remain the published inference, with the F-adjustment narrative downgraded from "implemented" to "scoped and infeasible at our scale" in the derivation note.
