# Plan rev 2: backend choice for AHZ-adjusted CR2 inference at LCA-inversion scale

Date: 2026-05-02 (rev 2)
Branch: `lca-inversion`
Predecessor: [rev 1 of this plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md)
Review that drove this rev: [`2026-05-02_backend-choice-plan-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_backend-choice-plan-review.md) (4 Red, 7 Yellow, 3 Green)
Predecessor empirical memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## What changed since rev 1

The fresh-context review surfaced four Red items.
Rev 2 incorporates all four and the Yellows that produce concrete edits.
The single biggest consequence is methodological, not numerical: a constraint reformulation the reviewer flagged collapses much of the original Stata-vs-R framing.

First, the rev-1 benchmark did not actually test the LCA contrast.
Both R `clubSandwich::Wald_test` and Stata `test_sandwich` were given a joint-zero on $(\beta_{s_4}, \beta_{s_5}, \beta_{s_6}, \beta_{s_7})$, which is a varlist-zero in both languages, not the full LCA contrast that mixes $\alpha_s$ and $\beta_s$.
The wall-time and OOM findings carry over (those depend on the per-cell `vcovCR` step, which dominates either way), but the "R `Wald_test` accepts arbitrary linear constraints; Stata `test_sandwich` is varlist-only" architectural argument is asserted from documentation, not validated by what we ran.

Second, rev 1's flop count for path C was off by roughly a factor of $K/\bar{n}_j \approx 9$ on the meat step.
The corrected arithmetic puts path C at low tens of minutes per cell, not single-digit minutes, dominated by the per-grid HTZ Satterthwaite df recompute rather than the one-time meat build.

Third, the constraint complication has a fourth reformulation rev 1 missed.
Re-coding the design at each grid $\phi_0$ as $z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot \mathbb{1}\{\text{trajectory}_i = s\}$ turns the LCA restriction into a varlist-zero on the $z$-coefficients.
This is compatible with `absorb(trajectory)`, native to `test_sandwich`, and sidesteps the FE-recovery step that makes paths A, B, and E painful in rev 1.
It costs one refit per grid point, so it trades methodological cleanness for compute.
Whether that trade is good depends on per-fit wall time, which the rev-1 benchmark already speaks to.

Fourth, rev 1 ordered TZA before IDN.
IDN unbalanced is the kill criterion ($J \approx 30{,}000$, $N \approx 90{,}000$), and a backend that passes TZA but fails IDN burns the rev-4 budget.
Rev 2 leads with IDN scale on the actual unbalanced cluster pattern, not on a synthetic Bernoulli design.

Yellows folded in as concrete edits below: clubSandwich's "$N \times N$ intermediate" diagnosis is unverified and gets a 30-minute traceback step before any from-scratch work; the corrigendum status of clubSandwich-as-anchor is hedged from "incorporates" to "incorporation status: TODO"; the WCB $B \ge 9999$ requirement is downgraded to $B = 999$ likely sufficient; path E is merged with path C as an implementation choice; and a new path F surveys recent CR2-at-scale alternatives the rev-1 plan did not engage with.

## Why this plan exists

Step 0a of plan rev 3 of the broader F-adjustment work produced two empirical findings.

First, Stata `reg_sandwich` on the TZA covs_trend design without FE absorption scales as roughly $O(J^2)$: 90 s at $J=1000$, 366 s at $J=2000$, extrapolated $\sim 3$ h at the full $J=11{,}012$.

Second, R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocates a dense intermediate that OOM'd at $J=11{,}012$, $N=29{,}864$ on a workstation with $>13$ GB free.
Both backends were given a varlist-zero workload (joint zero on four $\beta_s$), so the wall-time and OOM findings reflect the per-cell `vcovCR` cost, not the LCA contrast specifically.
The exact allocation site that OOM'd has not been pinned down; "dense $N \times N$ intermediate" is a working hypothesis, not a verified diagnosis.

The 2026-05-02 evening memo proposed pivoting the production backend from Stata `reg_sandwich` to R `clubSandwich`.
The user pushed back: if R OOM'd at TZA, it cannot scale to IDN.
That objection is correct and kills the speed half of the original pivot argument.
What remains is an architectural argument about constraint-matrix flexibility, which (per R1 above) is documentation-based and applies only after the per-cell `vcovCR` step succeeds.

Once reformulation (4) (recoded design) is in scope, the constraint-matrix advantage of R over Stata becomes moot: both backends accept varlist-zero contrasts natively.
The choice is therefore not Stata-vs-R.
It is: how do we compute BRL CR2 + AHZ Satterthwaite df at LCA scale at all, and only then, which of the surviving paths is cleanest.

## What the BRL+AHZ computation actually requires

Bell-McCaffrey CR2 (the BRL adjustment in Pustejovsky-Tipton 2018) is

$$\widehat{V}_{CR2} = (X'X)^{-1} \left[\sum_{j=1}^{J} X_j' A_j \hat{u}_j \hat{u}_j' A_j' X_j \right] (X'X)^{-1}, \qquad A_j = (I_{n_j} - H_{jj})^{-1/2},$$

with $H_{jj} = X_j (X'X)^{-1} X_j'$ the $n_j \times n_j$ hat block for cluster $j$.
The AHZ (HTZ in `clubSandwich` notation) Satterthwaite degrees of freedom for a $q$-dimensional linear contrast $C\beta = 0$ is a closed-form function of per-cluster influence matrices $G_j$ (PT 2018 Theorem 2 plus the 2023 corrigendum).

Three implementation facts shape what follows.

The per-cluster computation is $O(\sum_j (n_j^3 + n_j^2 K + n_j K^2))$ in time and $O(JK^2)$ in memory if we cache the per-cluster influence matrices.
At our regime ($J \approx 30{,}000$, $K \approx 27$, $\bar{n}_j \approx 3$) the dominant term is $n_j K^2$, giving $\sim 6 \cdot 10^7$ flops for the meat plus $\sim 10^6$ for per-cluster eigendecompositions.
Memory: $JK^2 \cdot 8$ bytes $\approx 175$ MB for the influence cache.

The HTZ Satterthwaite df recompute per grid $\phi$ is not free.
At $K = 27$, $q = J_R - 1 \approx 25$, $J \approx 30{,}000$, the dominant tensor contraction is $O(JK^2 q + Jq^3) \approx 5 \cdot 10^8$ ops per grid point.
Vectorized numpy at modern speeds: seconds per grid point; 30 grid points per cell: low tens of seconds for the df recomputation, plus the meat build amortized once.
Net path-C cost per cell: low tens of minutes for a careful Python implementation, dominated by the per-grid HTZ df recompute and Python loop overhead.

The off-the-shelf packages blow up because of how they organize the computation, not because the computation is expensive.
The exact failure mode is the open question Y1 below; "dense $N \times N$ intermediate" is a working hypothesis that needs traceback verification.

This reframing is what makes the from-scratch path viable.
It was speculative when the user originally rejected it on novelty-risk grounds.

## The constraint complication and its four reformulations

The LCA contrast is

$$r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0, \qquad s \in S_R \setminus \{base\}.$$

It involves both the trajectory main effects $\alpha_s$ and the trajectory-by-treatment interactions $\beta_s$.
The auxiliary OLS at $T = 5$, $K = 27$ has $J_R = 26$, so trajectory dummies $\alpha_s$ are responsible for almost all of $K$.

Absorbing trajectory FE removes the $\alpha_s$ from `e(b)`.
Four reformulations exist; rev 1 missed the fourth.

(1) Recover $\alpha_s$ post-estimation.
FWL guarantees the point estimates align between absorbed and dummied designs, but recovering the CR2 covariance between absorbed FE and included $\beta_s$ is non-trivial and requires methodological work.

(2) Reparametrize the auxiliary OLS so the LCA constraint becomes a constraint on coefficients that survive absorption.
A mechanical change of basis but loses some interpretability of $(\alpha_s, \beta_s)$.

(3) Drop absorption entirely.
Possible only if the per-cluster path keeps $K \approx 27$ tractable; this is path C.

(4) Recoded-design varlist-zero.
For each grid $\phi_0$, define $z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot \mathbb{1}\{\text{trajectory}_i = s\}$ for each non-base trajectory $s$.
Under the LCA restriction at $\phi_0$, the coefficients on the $z_{is}^{(\phi_0)}$ are zero for all $s \in S_R \setminus \{base\}$.
This is a varlist-zero test of $J_R - 1$ coefficients on a per-$\phi$ design.
It is compatible with `absorb(trajectory)` (the recoded $z$'s are not collinear with trajectory FE).
It is native to `test_sandwich`; no constraint matrix needed.
It costs one refit per grid point, but the OLS step is fast and FWL pre-residualization on the controls and trajectory FE collapses the fit step to a regression on a small residualized design.
The CR2 step still has to be redone per $\phi$ because $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s; this is the dominant cost.

Reformulation (4) is the cleanest path through the absorbed-mode candidates because it sidesteps FE recovery entirely.
It also collapses the architectural argument for R over Stata: with a varlist-zero contrast, `test_sandwich` and `Wald_test` are interchangeable.

## Candidate paths

### Path A. Stata `reg_sandwich, absorb(trajectory)` + reformulation (4)

The cleanest absorbed-mode path.
At each grid $\phi_0$, build the recoded $z$ variables, fit `reg_sandwich y z_2 ... z_{J_R} controls, absorb(trajectory) cluster(pid)`, run `test_sandwich z_2 z_3 ... z_{J_R}` to get the AHZ p-value.
Cost is dominated by the per-$\phi$ `vcovCR` build, which is the same step that scaled badly without absorption.
With absorbed FE, the design has $K_{\text{free}} \approx 1 + (J_R - 1) + (\text{controls}) \approx 30$ free parameters at $T=5$, comparable to the unabsorbed $K = 27$.
The savings are not in $K$; they are in whatever the dense-intermediate-allocator inside `reg_sandwich` did differently for absorbed vs unabsorbed mode.
This is exactly what Step 0a was supposed to A/B-test before getting derailed.

Open empirical questions for path A:

- Does `reg_sandwich, absorb(trajectory)` complete on the TZA covs_trend design at full scale ($J=11{,}012$) within an order of magnitude of the small-$J$ extrapolation, and at IDN scale ($J \approx 30{,}000$, $N \approx 90{,}000$) at all?
- Is the per-fit wall-time low enough that 30 refits per cell (one per grid $\phi$) is feasible across all 60 cells (5 specs $\times$ 3 countries $\times$ 4 inversion variants)?
- Does the absorbed-mode AHZ df behave well at our $K_{\text{free}}/J$ ratio, or does it silently collapse (the rev-3 reviewer's near-singularity concern)?

Cost to answer all three: 2-3 hours including the recoded-design plumbing and the IDN-scale probe.

### Path B. R `fixest::feols(..., fixef = "trajectory")` + `clubSandwich::vcovCR` + reformulation (4)

Same recoded-design test, run through R.
`feols` partials trajectory FE inside the OLS step (Mundlak-style demeaning); `vcovCR.fixest` then computes CR2 on the partialled design; `Wald_test` runs the varlist-zero on the $z$-coefficients.

Path B's advantage over path A is solely whether `vcovCR.fixest` avoids the dense intermediate that `reg_sandwich` (unabsorbed) hit.
That is contingent on Y1's traceback finding.
If the OOM was in `Wald_test`'s HTZ df build, path B is mis-targeted.
If the OOM was in `vcovCR`'s adjustment-matrix build, path B might help.

Open empirical questions: same as path A, plus the Y1 traceback question.

Cost: 2 hours including the IDN-scale synthetic-design probe (built from the actual IDN unbalanced cluster pattern, per R4).

### Path C. From-scratch BRL with cluster-by-cluster computation

Implement the CR2 meat and the AHZ Satterthwaite df directly, never materializing $H$ as a dense $N \times N$ object.
Loop over clusters, compute $A_j$ via eigendecomposition of $I_{n_j} - H_{jj}$, accumulate the meat and the per-cluster influence matrices into a $J \times K \times K$ tensor.
The Wald test at any $\phi$ is closed-form against the cached influence matrices and the LCA contrast matrix $C_\phi$.

Cost analysis at IDN scale ($J \approx 30{,}000$, $K = 27$, $\bar{n}_j \approx 3$, $q \approx 25$):

- One-time meat build: $\sim 6 \cdot 10^7$ flops; seconds at numpy speeds.
- Per-cluster eigendecompositions: $\sim 10^6$ flops; sub-second.
- Per-cluster influence cache: $JK^2 \cdot 8$ bytes $\approx 175$ MB.
- Per-grid HTZ df: $\sim 5 \cdot 10^8$ flops; a few seconds at numpy speeds.
- Total per cell at 30 grid points: low tens of minutes, dominated by the per-grid HTZ df recompute and Python loop overhead.

Risk: AHZ Satterthwaite df implementation correctness against the 2023 PT corrigendum.
Mitigation: anchor against `clubSandwich` 0.6.2 (corrigendum incorporation status: TODO, tracked in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md)) at $J \le 2000$ where `clubSandwich` runs cleanly.
The cross-check verifies relative agreement between our implementation and clubSandwich's; absolute correctness against the corrigendum is contingent on the corrigendum read landing.
Tolerance: $10^{-4}$ on the test statistic, $10^{-3}$ on the df.

This is the path the user previously rejected on novelty grounds.
The rejection was made before clubSandwich was available as a small-$J$ verification anchor.
With the anchor in place (modulo the corrigendum hedge), the novelty risk is concentrated in the implementation step rather than the methodological step.

Path E from rev 1 (absorb FE first, then cluster-by-cluster BRL) is folded into path C as an implementation choice.
At $T=5$, absorbing trajectory FE drops $K_{\text{free}}$ to $\approx 2$ and the influence cache to $\sim 1$ MB, but the HTZ df cost is dominated by $q$ (which doesn't shrink), so the savings are on the meat step only.
"Absorbed vs unabsorbed" is therefore a constant-factor speedup within path C, not a separate path.

Implementation effort: 1-2 days for the meat, the Satterthwaite df, and the cross-check harness.

### Path D. Wild cluster bootstrap inversion

Promotes the WCB comparison from Step 3.5 of plan rev 3 to the production backend.
Stata `boottest` (Roodman et al. 2019) and R `fwildclusterboot` are both implemented to avoid materializing dense $N \times N$ objects.

Per-cell cost at IDN scale: $999$ bootstraps $\times$ 30 grid points $\times \sim 9 \cdot 10^5$ ops per draw $\approx 2.7 \cdot 10^{10}$ ops total.
At sustained 1 GFLOPS this is ~30 seconds, at sustained 100 MFLOPS this is ~5 minutes; published `boottest` benchmarks suggest 5-15 minutes per cell is realistic at $B = 999$.
At $B = 9999$: 50 minutes to 2.5 hours per cell.

Pros:

- Off-the-shelf packages handle the scaling problem in a way `vcovCR` does not.
- The WCB-Wald inversion is a published method with no novelty risk.
- The constraint matrix can be passed via `boottest`'s multi-restriction syntax; reformulation (4) is also compatible.

Cons:

- Bootstrap MC noise enters the published CIs.
At $B = 999$ the per-grid-point p-value MC SE is $\sim 0.007$ at $p = 0.05$.
CI endpoint placement absorbs this noise via the slope of the p-value in $\phi$; the resulting endpoint MC SE is on the order of 1-3% of the band width for typical slopes.
$B = 999$ is plausibly sufficient for production; $B = 9999$ is a safer default at modest cost (boottest scales near-linearly in $B$).
- The published table changes from "F-adjusted" to "WCB-inverted" and the corresponding referee narrative shifts accordingly.
- AHZ remains the load-bearing comparison method; demoting AHZ to a small-$J$ comparison and elevating WCB to primary changes which method bears the burden of the validation gate.

### Path F. Recent CR2-at-scale alternatives

Rev 1 did not engage with this literature.
Three concrete items to scan before any from-scratch work.

(F.1) Niccodemi & Alessie's recent papers on cluster-robust variance estimation at large $J$ propose sparse-matrix-based CR2 implementations that explicitly avoid materializing $N \times N$ objects.
If the paper has an R or Stata implementation, it could be a drop-in alternative to `clubSandwich`.
Cost to check: 30 minutes of literature search plus a CRAN/PyPI/SSC search for the package name.

(F.2) MacKinnon, Nielsen, and Webb's recent papers on cluster-robust inference at large $J$ include the `summclust` Stata package (and `MNW.cluster.boot` in R).
This is more about influence diagnostics than CR2 per se, but the influence-function machinery may overlap with what BRL needs.

(F.3) Pustejovsky's GitHub for clubSandwich (R) and clubSandwich-Stata may have a development branch ahead of CRAN/SSC.
A scan of recent commits for "memory", "sparse", or "vcovCR" performance work is cheap and could short-circuit this whole decision.

Cost to scan all three: 1-2 hours.
Promotion criterion: any path-F candidate that runs at IDN scale within wall-time and memory budgets is preferred over path C (less novelty risk) and over path D (avoids the bootstrap-noise narrative).

## Cost comparison

| Path | Prototype effort | TZA full ($J=11{,}012$) | IDN unb. ($J\approx 30{,}000$) | Per-cell wall (60 cells) | FE-recovery effort | Novelty risk | Anchor available |
|---|---:|---:|---:|---:|---:|---:|---:|
| A. `reg_sandwich, absorb` + reform (4) | 2-3 h | unknown | unknown (kill criterion) | 30 fits/cell $\times$ per-fit wall | none (reform 4) | none | clubSandwich at $J\le2000$ |
| B. `feols` + `vcovCR` + reform (4) | 2 h | unknown | unknown (kill criterion) | 30 fits/cell $\times$ per-fit wall | none (reform 4) | none | clubSandwich at $J\le2000$ |
| C. From-scratch BRL | 1-2 days | $\sim 5$-15 min | $\sim 10$-30 min | $\sim 10$-30 hours total | none | medium (impl) | clubSandwich at $J\le2000$ (corrigendum: TODO) |
| D. WCB inversion | 0.5-1 day | $\sim 5$ min ($B=999$) | $\sim 5$-15 min ($B=999$) | $\sim 5$-15 hours total ($B=999$) | none | none | published method |
| F. Path-F survey package | 1-2 h scan | unknown | unknown | unknown | TBD | low (if any candidate exists) | candidate-dependent |

The "unknown" entries for paths A, B, and F are exactly what the next checks resolve.
The "60 cells" budget is 5 specs $\times$ 3 countries $\times$ 4 inversion variants.

Path E is dropped as a separate row; absorbed vs unabsorbed BRL is an implementation choice within path C.

## Recommended order of attack

The work breaks into one parallel empirical block followed by either implementation or a methodological decision.

Empirical block (4-6 h, parallelizable).

1. (30 min) Pin down where `clubSandwich`'s OOM allocates, via `traceback()` on the failed J=11k run plus a peak-memory profile of `vcovCR` vs `Wald_test`.
This resolves Y1 and gates whether path B's premise (FE-absorption helps) holds.
2. (1-2 h) Path-F scan: Niccodemi-Alessie, MacKinnon-Nielsen-Webb, clubSandwich GitHub dev branch.
Promote any candidate that runs at IDN scale.
3. (2-3 h) Build the IDN-scale probe from the actual IDN unbalanced cluster pattern (RP7 design, not a synthetic Bernoulli draw).
Apply path A and path B in parallel under reformulation (4): `reg_sandwich, absorb(trajectory)` on the recoded design at one $\phi$, and `feols + vcovCR` likewise.
A backend is viable iff it passes both TZA and IDN at the pass criteria below.
4. (Conditional) If both A and B pass at TZA but fail at IDN, run the corresponding TZA timing on path C's prototype on the same recoded design to validate the from-scratch cost analysis before committing to a 1-2 day implementation.

Pass criteria (Y7).

A backend (path A, B, or F) is promoted if:

- Per-fit wall time at full scale is under 30 minutes.
- Peak memory is under 16 GB.
- The AHZ p-value on the recoded-design varlist-zero agrees with a small-$J$ clubSandwich anchor to $10^{-4}$ on the test statistic and $10^{-3}$ on the df.
- The implied CI endpoints across the grid are computable in under 4 hours per cell wall (so 60 cells fit in $\le 10$ days of wall time, or under 2.5 days with 4-way parallelism).

Decision branch.

If exactly one of A, B, F passes the criteria at IDN, ratify it as the production backend and write plan rev 4.

If multiple pass, prefer in order: F (least novelty + least dependency), B (most flexible constraint interface), A (closest to existing CKT Stata pipeline).

If none pass, the choice between path C (from-scratch) and path D (WCB) is methodological, not computational, and the user makes the call.
The relevant trade-off:

- Path C keeps the F-adjusted-AHZ narrative and concentrates novelty risk in the implementation, anchored by clubSandwich at small $J$ subject to the corrigendum hedge.
- Path D drops AHZ from the production CIs in favor of WCB-inverted CIs and rewrites the referee narrative accordingly, with no novelty risk and a $\sim 1$-day implementation.

## Open decision points

These are the questions whose answers determine which plan rev 4 to write.

1. (Empirical) Where does `clubSandwich` allocate the OOM-blowing intermediate?
2. (Empirical) Does at least one of A, B, F pass the pass criteria at IDN scale on the recoded design?
3. (Methodological, if 2 fails) Is the user willing to revisit the from-scratch path now that clubSandwich is available as a small-$J$ anchor, conditional on the corrigendum hedge?
4. (Narrative) Is WCB inversion an acceptable backend for the published F-adjusted CIs (with a section-name change to "Bootstrap-inverted CIs"), or only as a comparison?
5. (Methodological) Does reformulation (4)'s 30-fits-per-cell cost dominate any per-fit savings from absorbed mode?
The IDN-scale probe answers this directly.

## What this plan is not

It is still a decision plan whose output is which of A, B, C, D, F becomes the basis for plan rev 4.
The implementation details (Stata wrapper structure, Python bridge, subprocess verification, synth coverage MC, empirical re-run) are mostly unchanged from plan rev 3 of the broader F-adjustment work and ride on top of whichever backend the next checks ratify.

If none of A, B, C, D, F is acceptable, the work parks; the chi-squared-based CIs in the existing pipeline remain the published inference, with the F-adjustment narrative downgraded from "implemented" to "scoped and infeasible at our scale" in the derivation note.

## What is fixed relative to rev 1

To make the diff legible:

- Reformulation (4) added to the constraint complication section, then propagated into paths A and B as the production architecture.
- Path C's flop count corrected: meat dominated by $n_j K^2$ ($\sim 6 \cdot 10^7$ ops), not the previous "$\sim 2 \cdot 10^7$" estimate.
HTZ df recompute per grid $\phi$ added explicitly ($\sim 5 \cdot 10^8$ ops, seconds-per-grid-point).
"Single-digit minutes" downgraded to "low tens of minutes".
- Path E folded into path C as an implementation choice.
- Path F (recent CR2-at-scale alternatives) added as a separate path.
- Order of attack reordered: IDN-scale probe first/parallel, not after a TZA pass.
IDN probe specified to use the actual unbalanced cluster pattern, not a synthetic design.
- Pass criteria added (wall time, memory, anchor agreement, total wall budget).
- WCB MC SE conclusion corrected: $B = 999$ likely sufficient, $B = 9999$ a cheap safety margin.
- The "$N \times N$ intermediate" diagnosis hedged to "working hypothesis"; a 30-minute traceback step gates path B's premise.
- clubSandwich-as-anchor's corrigendum status hedged from "incorporates" to "incorporation status: TODO".
- The architectural argument for R over Stata (constraint-matrix interface) explicitly noted as moot once reformulation (4) is in scope.
