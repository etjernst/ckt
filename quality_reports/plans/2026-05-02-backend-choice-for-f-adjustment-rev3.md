# Plan rev 3: backend choice for AHZ-adjusted CR2 inference at LCA-inversion scale

Date: 2026-05-02 (rev 3)
Branch: `lca-inversion`
Predecessors: [rev 2 of this plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md), [rev 1 of this plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md).
Critique driving this rev: [`2026-05-02_rev2-six-dimension-critique.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev2-six-dimension-critique.md) (6 Red, 11 Yellow, 4 Green).
Predecessor empirical memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## What changed since rev 2

The critique surfaced six Red items.
Rev 3 incorporates all six and the actionable Yellows.

First, rev 2 quietly assumed reformulation (4) collapses the per-grid CR2 cost to "30 cheap refits."
That is wrong: $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s, so the BRL adjustment is rebuilt at every grid point.
Rev 3 makes the per-$\phi$ vcovCR cost explicit in the cost table (multiplied by 30) and gates the IDN probe on a single-fit timing.
Second, the path-F survey now precedes the IDN probe rather than running in parallel; a path-F candidate that solves the OOM should not be discovered after we have already burned probe budget on paths A and B.
Third, CR3 (MacKinnon, Nielsen, Webb 2023; Hansen 2025) enters as a separate path G with parallel cost analysis to path C; the previous absence would have looked like inattention to a published, computationally cheaper alternative.
Fourth, an empirical AHZ df contingency lands in the pass criteria: df below 4 at IDN forces a fall-back to path D regardless of wall time or memory, because the Satterthwaite F distribution is unreliable in that regime.
Fifth, the recoded-design construction now specifies the base trajectory per country/spec (consumption: $\underline{d}_0 = 2$; IDN income: 16; TZA income: 5; CHN income: TBD or 2), the mapping to the existing `beta_s_*` and `alpha_d_*` variables, and singleton handling.
Sixth, the traceback step is reframed as a controlled OOM reproduction with `tracemalloc`/`tracemem`, budgeted at 1-2 hours rather than 30 minutes.

The Greens from the critique survive intact: IDN-first sequencing as the kill criterion, reformulation (4) collapsing the constraint-matrix advantage of R over Stata, the PT 2018 corrigendum applicability argument, concrete pass criteria on wall and memory, and a falsifiable cost-comparison table.

## Why this plan exists

Step 0a of the broader F-adjustment work produced two empirical findings.
Stata `reg_sandwich` on the TZA covs_trend design without FE absorption scales as roughly $O(J^2)$: 90 s at $J=1000$, 366 s at $J=2000$, extrapolated $\sim 3$ h at full $J=11{,}012$.
R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocated a dense intermediate that OOM'd at $J=11{,}012$, $N=29{,}864$ on a workstation with $>13$ GB free.
Both backends were given a varlist-zero workload (joint zero on four $\beta_s$), so the wall-time and OOM findings reflect the per-cell `vcovCR` cost, not the LCA contrast specifically.
The exact allocation site that OOM'd has not been pinned down; "dense $N \times N$ intermediate" remains a working hypothesis.

The user pushed back on a Stata-to-R production pivot: if R OOM'd at TZA, it cannot scale to IDN.
That objection is correct and kills the speed half of the original pivot argument.
What remains is whether off-the-shelf packages can be coaxed into the absorbed regime, whether a published from-scratch alternative (CR2 or CR3) is now cheap enough to risk, or whether wild cluster bootstrap inversion replaces the AHZ-adjusted F as the production inference object.

Once reformulation (4) is in scope, the constraint-matrix advantage of R over Stata becomes moot: both backends accept varlist-zero contrasts natively.
The decision is therefore: how do we compute BRL CR2 + AHZ Satterthwaite df (or CR3 + Satterthwaite, or WCB inversion) at LCA scale at all, and only then, which surviving path is cleanest.

## What the BRL+AHZ computation actually requires

Bell-McCaffrey CR2 (the BRL adjustment in Pustejovsky-Tipton 2018) is

$$\widehat{V}_{CR2} = (X'X)^{-1} \left[\sum_{j=1}^{J} X_j' A_j \hat{u}_j \hat{u}_j' A_j' X_j \right] (X'X)^{-1}, \qquad A_j = (I_{n_j} - H_{jj})^{-1/2},$$

with $H_{jj} = X_j (X'X)^{-1} X_j'$ the $n_j \times n_j$ hat block for cluster $j$.
The HTZ Satterthwaite degrees of freedom for a $q$-dimensional linear contrast $C\beta = 0$ is a closed-form function of per-cluster influence matrices $G_j$ (PT 2018 Theorem 2 plus the 2023 corrigendum at https://jepusto.com/posts/pusto-tipton-2018-theorem-2/).
The corrigendum updates Theorem 2: the absorbed-FE shortcut holds only for OLS with identity working model.
The auxiliary OLS in our setting satisfies that condition exactly, so the absorbed-FE shortcut is legitimate for our application.

Three implementation facts shape what follows.

First, the per-cluster computation is $O(\sum_j (n_j^3 + n_j^2 K + n_j K^2))$ in time and $O(JK^2)$ in memory if we cache the per-cluster influence matrices.
At our regime ($J \approx 30{,}000$, $K \approx 27$, $\bar{n}_j \approx 3$) the dominant term is $n_j K^2$, giving $\sim 6 \cdot 10^7$ flops for the meat plus $\sim 10^6$ for per-cluster eigendecompositions.
Memory: $JK^2 \cdot 8$ bytes $\approx 175$ MB for the influence cache.
Second, the HTZ Satterthwaite df recompute per grid $\phi$ is not free: at $K = 27$, $q = J_R - 1 \approx 25$, $J \approx 30{,}000$, the dominant tensor contraction is $O(JK^2 q + Jq^3) \approx 5 \cdot 10^8$ ops per grid point.
Third, off-the-shelf packages blow up because of how they organize the computation, not because the computation itself is expensive.

CR3 (MacKinnon-Nielsen-Webb 2023; Hansen 2025) replaces $A_j = (I - H_{jj})^{-1/2}$ with $A_j = (I - H_{jj})^{-1}$ applied differently, and skips the eigendecomposition step entirely.
Empirically CR3 performs as well or better than CR2 in many scenarios at large $J$.
The cost saving is on the per-cluster meat step: no eigensystem at each cluster.

## The LCA constraint and its four reformulations

The LCA contrast is

$$r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0, \qquad s \in S_R \setminus \{\underline{d}_0\}.$$

It mixes trajectory main effects $\alpha_s$ and trajectory-by-treatment interactions $\beta_s$.
The auxiliary OLS at $T = 5$, $K = 27$ has $J_R = 26$, so trajectory dummies $\alpha_s$ are responsible for almost all of $K$.

Absorbing trajectory FE removes $\alpha_s$ from `e(b)`.
Four reformulations exist.
First, recover $\alpha_s$ post-estimation; FWL guarantees point estimates align between absorbed and dummied designs, but recovering the CR2 covariance between absorbed FE and included $\beta_s$ is non-trivial.
Second, reparametrize so the LCA constraint becomes a constraint on coefficients that survive absorption; mechanical but loses interpretability of $(\alpha_s, \beta_s)$.
Third, drop absorption entirely; viable only if the per-cluster path keeps $K \approx 27$ tractable.
Fourth, recoded-design varlist-zero.

Reformulation (4) defines, for each grid $\phi_0$ and each non-base trajectory $s$,

$$z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot \mathbb{1}\{\text{trajectory}_i = s\}.$$

Under the LCA restriction at $\phi_0$, the coefficients on $z_{is}^{(\phi_0)}$ are zero for all $s \in S_R \setminus \{\underline{d}_0\}$.
This is a varlist-zero test of $J_R - 1$ coefficients on a per-$\phi$ design, native to `test_sandwich` (Stata) and `Wald_test` with `constrain_zero` (R).
The pattern is structurally identical to the recoding Davidson-MacKinnon use in their wild bootstrap papers for restriction tests; it is not novel.

Reformulation (4) sidesteps FE recovery entirely.
Its cost is one refit per grid point.
The OLS step is fast (FWL pre-residualization on controls and trajectory FE collapses the fit to a regression on a small residualized design), but the CR2 step has to be redone per $\phi$ because $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s.
This is the dominant cost and the one rev 2 understated.

## Recoded-design construction, pinned

For first-implementer level specificity, the recoded design follows three rules.

First, base trajectory per country/spec.
Consumption (all three countries): $\underline{d}_0 = 2$.
IDN income: $\underline{d}_0 = 16$ (per the CLAUDE.md known issue on `define_switcherpars`).
TZA income: $\underline{d}_0 = 5$ (same source).
CHN income: TBD, default to $\underline{d}_0 = 2$ pending verification.

Second, variable mapping.
$D_{is}$ in the formula is the per-trajectory urban indicator at trajectory $s$, which corresponds to `beta_s_{s}` in the existing GRC code.
$\mathbb{1}\{\text{trajectory}_i = s\}$ is the trajectory main effect, which corresponds to `alpha_d_{s}`.
The recoded variable is therefore

$$z_{is}^{(\phi_0)} = \mathtt{beta\_s\_}s - \phi_0 \cdot \mathtt{alpha\_d\_}s,$$

constructed for $s \in S_R \setminus \{\underline{d}_0\}$ and tested via joint zero.

Third, singleton handling.
IDN unbalanced will have a tail of singleton clusters ($n_j = 1$).
For these, $I_1 - H_{11}$ has a single eigenvalue that may be near zero and triggers numerical issues in the $A_j = (I - H_{jj})^{-1/2}$ step.
Drop singletons before constructing the design; report the count and share dropped.
At IDN this is expected to remove $\sim 5$-10% of clusters but a much smaller share of $N$.

Fourth, controls and FE.
Include the same controls as the matched GRC spec (covs_trend or covs_all).
Absorb trajectory FE in paths A, B, and G; in path C, include trajectory dummies as columns of $X$.
The recoded $z$'s are not collinear with trajectory FE because $\phi_0 \ne 0$ on the grid.

## Candidate paths

### Path A. Stata `reg_sandwich, absorb(trajectory)` + reformulation (4)

The cleanest absorbed-mode Stata path.
At each grid $\phi_0$, build the recoded $z$ variables, fit `reg_sandwich y z_2 ... z_{J_R} controls, absorb(trajectory) cluster(pid)`, run `test_sandwich z_2 z_3 ... z_{J_R}` to get the AHZ p-value.
The PT 2018 corrigendum (https://jepusto.com/posts/pusto-tipton-2018-theorem-2/) legitimizes the absorbed-FE shortcut for OLS-with-identity, which is the regime we are in.
Per-cell wall = 30 grid points $\times$ per-fit wall, where per-fit wall includes the full vcovCR rebuild because $H_{jj}(\phi)$ varies with $\phi$.

Open empirical questions for path A.
Does `reg_sandwich, absorb(trajectory)` complete within an order of magnitude of the small-$J$ extrapolation at TZA ($J=11{,}012$) and at IDN ($J \approx 30{,}000$, $N \approx 90{,}000$) at all?
Is the per-fit wall low enough that 30 refits per cell, $\times$ 60 cells (5 specs $\times$ 3 countries $\times$ 4 inversion variants), is feasible?
Does the absorbed-mode AHZ df at our $K_{\text{free}}/J$ ratio behave well, or collapse?

### Path B. R `fixest::feols(..., fixef = "trajectory")` + `clubSandwich::vcovCR` + reformulation (4)

Same recoded-design test, run through R.
`feols` partials trajectory FE inside the OLS step; `vcovCR.fixest` then computes CR2 on the partialled design; `Wald_test` runs the varlist-zero on the $z$-coefficients.
PT 2018 corrigendum applies identically to path A.
Path B's advantage over path A is contingent on whether `vcovCR.fixest` avoids the dense intermediate that `reg_sandwich` (unabsorbed) hit.
That depends on the controlled-OOM-reproduction finding (open question Y1 below).

### Path C. From-scratch BRL CR2 with cluster-by-cluster computation

Implement the CR2 meat and the AHZ Satterthwaite df directly, never materializing $H$ as a dense $N \times N$ object.
Loop over clusters, compute $A_j$ via eigendecomposition of $I_{n_j} - H_{jj}$, accumulate the meat and the per-cluster influence matrices into a $J \times K \times K$ tensor.
The Wald test at any $\phi$ is closed-form against the cached influence matrices and the LCA contrast matrix $C_\phi$.

Cost analysis at IDN scale ($J \approx 30{,}000$, $K = 27$, $\bar{n}_j \approx 3$, $q \approx 25$).
One-time meat build: $\sim 6 \cdot 10^7$ flops, seconds at numpy speeds.
Per-cluster eigendecompositions: $\sim 10^6$ flops, sub-second.
Per-cluster influence cache: $\approx 175$ MB.
Per-grid HTZ df: $\sim 5 \cdot 10^8$ flops, a few seconds at numpy speeds.
Total per cell at 30 grid points: low tens of minutes, dominated by the per-grid HTZ df recompute and Python loop overhead.

Risk: AHZ Satterthwaite df implementation correctness against the 2023 PT corrigendum.
Mitigation: anchor against `clubSandwich` 0.6.2 at $J = 1500$ on the TZA covs_trend design, joint-zero on the recoded $z$'s at $\phi_0 = \hat\phi_{\text{point}}$, tolerance $10^{-4}$ on the test statistic and $10^{-3}$ on the df.
Corrigendum incorporation status in clubSandwich 0.6.2: TODO, tracked in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md); the cross-check verifies relative agreement, with absolute correctness contingent on the corrigendum read landing.
The corrigendum read is a prerequisite of any path-C implementation kickoff; it is scheduled before the 1-2 day path-C build, not after.

Path E from rev 1 (absorb FE before the cluster loop) is folded into path C as an implementation choice.
Implementation effort: 1-2 days.

### Path D. Wild cluster bootstrap inversion

Promotes the WCB comparison from Step 3.5 of the broader plan to the production backend.
Stata `boottest` (Roodman et al. 2019) and R `fwildclusterboot` are both implemented to avoid materializing dense $N \times N$ objects.

Per-cell cost at IDN scale: $999$ bootstraps $\times$ 30 grid points $\times \sim 9 \cdot 10^5$ ops per draw $\approx 2.7 \cdot 10^{10}$ ops total.
Published `boottest` benchmarks suggest 5-15 minutes per cell at $B = 999$; $B = 9999$ would be 50 minutes to 2.5 hours per cell.
At $B = 999$ the per-grid-point p-value MC SE is $\sim 0.007$ at $p = 0.05$.
CI endpoint placement absorbs this noise via the slope of the p-value in $\phi$; the resulting endpoint MC SE is on the order of 1-3% of the band width for typical slopes.
$B = 999$ is plausibly sufficient for production; $B = 9999$ is a safer default at modest cost.

The published table changes from "F-adjusted" to "WCB-inverted" and the corresponding referee narrative shifts.
AHZ remains a small-$J$ comparison rather than the production CI method.

### Path F. Recent CR2-at-scale alternatives

Three concrete items to scan, split into F.0 (literature scan) and F.1 (candidate prototype, conditional).

(F.1 candidates) Niccodemi-Alessie sparse-CR2; MacKinnon-Nielsen-Webb `summclust` (Stata) and related R packages; Pustejovsky's clubSandwich GitHub dev branch ahead of CRAN.
F.0 cost: 1-2 hours of literature search and CRAN/PyPI/SSC checks.
F.1 cost: 2-3 hours, conditional on F.0 finding a candidate with a working implementation suitable for our scale.

Promotion criterion: any path-F candidate that runs at IDN scale within wall-time and memory budgets is preferred over path C (less novelty risk) and over path D (avoids the bootstrap-noise narrative shift).

### Path G. From-scratch CR3 with cluster-by-cluster computation

CR3 replaces $A_j = (I - H_{jj})^{-1/2}$ with $A_j = (I - H_{jj})^{-1}$ in the meat, and skips the eigendecomposition.
Per-cluster cost drops by the eigensystem constant (factor of 5-10 in practice).
HTZ df recompute per grid $\phi$ is unchanged in cost ($q$ dominates, not $K$).
Total per cell at 30 grid points: low tens of minutes, dominated by the same per-grid HTZ df recompute as path C, with a faster meat build.

Risk: CR3 + Satterthwaite is newer; the small-$J$ anchor is `summclust` in Stata at $J = 1500$, since clubSandwich does not implement CR3 as of 0.6.2.
Cross-check tolerance: same $10^{-4}$ on test statistic, $10^{-3}$ on df, against the recoded varlist-zero at $\phi_0 = \hat\phi_{\text{point}}$.
Implementation effort: 1 day, shorter than path C because no eigendecomposition.

A referee asking "why not CR3" is answered by path G being on the table.

## Cost comparison

The cost-comparison table is the falsifiable core of this plan.
The "per-fit wall" column is the IDN-scale wall for one $(X, \phi_0)$ vcovCR build (paths A, B) or one BRL meat build (paths C, G).
The "per-cell wall" column multiplies by 30 grid points.

| Path | Prototype | TZA full ($J=11{,}012$) per fit | IDN unb. ($J\approx 30{,}000$) per fit | Per-cell wall (30 fits) | 60-cell wall, 4-way parallel | Anchor |
|---|---:|---:|---:|---:|---:|---:|
| A. `reg_sandwich, absorb` + reform (4) | 2-3 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends on per-fit | clubSandwich at $J=1500$ |
| B. `feols` + `vcovCR` + reform (4) | 2 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends on per-fit | clubSandwich at $J=1500$ |
| C. From-scratch CR2 | 1-2 days | $\sim 30$ s | $\sim 1$ min | $\sim 10$-30 min | 2.5-7.5 h | clubSandwich at $J=1500$ (corrigendum: TODO) |
| D. WCB inversion ($B=999$) | 0.5-1 day | $\sim 5$ min | $\sim 5$-15 min | bundled (cell = 30 grid) | 1.25-3.75 h | published method |
| F. Path-F candidate | 1-2 h F.0 + 2-3 h F.1 | unknown | unknown | TBD | TBD | candidate-dependent |
| G. From-scratch CR3 | 1 day | $\sim 10$ s | $\sim 30$ s | $\sim 10$-30 min | 2.5-7.5 h | `summclust` at $J=1500$ |

Three reads of this table.
First, paths A and B are dead at the 60-cell budget if their per-fit IDN wall exceeds 6 minutes: 6 min $\times$ 30 grid $\times$ 60 cells $/$ 4-way parallelism $= 45$ hours, which is the upper edge of the 10-day budget but only if the per-fit wall stays below that line.
Second, path C and path G come out comparable on per-cell wall because the HTZ df recompute dominates, but path G is faster on prototype effort.
Third, path D is the cheapest if the bootstrap-noise narrative shift is acceptable.

The "60 cells" budget is 5 specs $\times$ 3 countries $\times$ 4 inversion variants.
Parallelism for paths A and B requires separate Stata sessions or R processes (the pystata bridge serializes within a session); 4-way is feasible on a single workstation if memory allows.

## Recommended order of attack

The work breaks into a strictly sequential head followed by a parallel empirical block.

Step 0 (30 min). Verify the IDN data-prep pipeline runs end-to-end on `lca-inversion`'s RP7.
A morning lost to data-prep debugging would push the empirical block to 6-8 hours.
This is a 30-minute check, not a research task.

Step 1 (1-2 h). Reproduce the clubSandwich OOM under controlled conditions.
Re-run the failed $J = 11{,}012$ TZA design with `tracemalloc` (Python) or `tracemem()` (R) instrumented from process start.
Success criterion: a `tracemalloc` snapshot at peak with the top 10 allocation sites identified and a one-line summary of which clubSandwich function the largest allocation occurred in.
This resolves whether path B's premise (FE-absorption reduces the dense intermediate) holds.
If the OOM is in `Wald_test`'s HTZ df build rather than `vcovCR`'s adjustment matrix, path B is mis-targeted and drops out.

Step 2 (1-2 h). Path-F literature scan (F.0).
Niccodemi-Alessie, MacKinnon-Nielsen-Webb summclust, clubSandwich GitHub dev branch.
Promotion: if a candidate has a working implementation suitable for our scale, schedule F.1 (2-3 h prototype on TZA full) before the IDN probe.
If F.0 finds nothing, skip F.1 and go to Step 3.

Step 3 (2-3 h, parallelizable). IDN-scale probe.
Build the IDN unbalanced cluster pattern from the actual RP7 design (covs_trend or covs_all per spec; specify in the probe spec sub-section), drop singletons, report leverage diagnostics ($\max n_j$, $\sum_j n_j^2$, Gini of cluster sizes), report per-$\phi$ condition number of the recoded design.
Apply paths A and B in parallel under reformulation (4) at one $\phi$ value: `reg_sandwich, absorb(trajectory)` on the recoded design and `feols + vcovCR` likewise.
Single-fit timing first; only if the single fit comes in under 6 minutes do we extrapolate to the 30-fit cell budget.

Step 4 (conditional, 2-3 h). If both A and B fail at IDN, run path C and path G prototypes on the same recoded TZA design at $J = 1500$ to validate the from-scratch cost analyses against the clubSandwich (path C) and `summclust` (path G) anchors before committing to the 1-2 day implementation.

## Pass criteria

A backend (path A, B, F, C, or G) is promoted if all five hold.

(i) Per-fit wall time at full IDN scale is under 30 minutes.
(ii) Peak memory is under 16 GB.
(iii) The AHZ p-value on the recoded-design varlist-zero agrees with the small-$J$ anchor (clubSandwich for paths A, B, C; `summclust` for path G) to $10^{-4}$ on the test statistic and $10^{-3}$ on the df, at $J = 1500$ on the TZA covs_trend design with $\phi_0 = \hat\phi_{\text{point}}$.
(iv) The implied CI endpoints across the 30-grid are computable in under 4 hours per cell wall (60 cells fit in $\le 10$ days serial, $\le 2.5$ days with 4-way parallelism via separate Stata sessions or R processes).
(v) The empirical AHZ df at the LCA contrast at IDN scale is between 4 and $J/2$.
df below 4 triggers a fall-back to path D regardless of wall-time and memory, because the Satterthwaite F distribution is unreliable in that regime.
df above $J/2$ is a sign of df breakdown and triggers the same fall-back.

Anti-conservative-bias check.
A backend that runs but produces CIs that under-cover at the empirical $J/q$ ratio is worse than no backend.
A small synthetic coverage MC at the empirical $J/q$ ratio runs as a separate validation step in the broader pipeline plan rev 4; it is not a gating criterion of this backend choice but is referenced here so it is not lost.

## Decision branch

If exactly one of A, B, F, G passes at IDN, ratify it and write plan rev 4.
If multiple pass, prefer in order: F (least novelty + least dependency), G (CR3 + smaller eigensystem cost), B (most flexible R-side ecosystem), A (closest to existing CKT Stata pipeline).
If none pass, the choice between path C (CR2 from-scratch) and path D (WCB) is methodological, not computational, and the user makes the call.

The relevant trade-off: path C keeps the F-adjusted-AHZ narrative and concentrates novelty in implementation, anchored by clubSandwich at small $J$ subject to the corrigendum hedge; path D drops AHZ from the production CIs in favor of WCB-inverted CIs and rewrites the referee narrative accordingly, with no novelty risk and a $\sim 1$-day implementation.

## Open decision points

These determine which plan rev 4 to write.

(i) Where does `clubSandwich` allocate the OOM-blowing intermediate?
(ii) Does at least one of A, B, F, G pass the criteria at IDN scale on the recoded design?
(iii) If (ii) fails, is the user willing to revisit the from-scratch path (C or G) given the small-$J$ anchor and the corrigendum hedge?
(iv) Is WCB inversion an acceptable backend for the published F-adjusted CIs (with a section-name change to "Bootstrap-inverted CIs"), or only as a comparison?
(v) Does reformulation (4)'s 30-fits-per-cell cost dominate any per-fit savings from absorbed mode?
The IDN-scale single-fit timing answers (v) directly.

## What this plan is not

This is a decision plan whose output is which of A, B, C, D, F, G becomes the basis for plan rev 4.
The implementation details (Stata wrapper structure, Python bridge, subprocess verification, synthetic coverage MC, empirical re-run) are unchanged from the broader F-adjustment work and ride on top of whichever backend the next checks ratify.

If none of A, B, C, D, F, G is acceptable, the work parks; the chi-squared-based CIs in the existing pipeline remain the published inference, with the F-adjustment narrative downgraded from "implemented" to "scoped and infeasible at our scale" in the derivation note.

This plan does not specify the synthetic coverage MC design, the WCB validation harness, or the published-table layout under either AHZ or WCB.
Those land in plan rev 4 once the backend is ratified.
This plan does not relitigate the AHZ-vs-CR3 methodological choice as a primary inference object; CR3 enters as path G to address the cost-comparison gap and the referee defensibility question, not as a recommendation that we drop AHZ.
