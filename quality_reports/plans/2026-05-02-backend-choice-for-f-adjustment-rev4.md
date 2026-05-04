# Plan rev 4: backend choice for AHZ-adjusted CR3 inference at LCA-inversion scale

Date: 2026-05-02 (rev 4)
Branch: `lca-inversion`
Predecessors: [rev 3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev3.md), [rev 2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md), [rev 1](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md).
Critique driving this rev: [`2026-05-02_rev3-six-dimension-critique.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev3-six-dimension-critique.md) (4 Red, 9 Yellow, 5 Green).
Predecessor empirical memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## What changed since rev 3

Rev 3 closed most of the rev 2 Reds but missed the conventional 2026 sequencing in which leverage diagnostics drive backend selection.
Rev 4 incorporates four Reds, the actionable Yellows, and preserves the five Greens from the rev 3 critique.

First (R1), leverage and effective-cluster-count diagnostics now run before any backend selection.
A new Step 0.5 calls `summclust` on TZA full and IDN unbalanced, reports $G^*$, partial leverage, influence, and cluster-size moments, and applies the kill rule: if $G^* < 30$ at IDN unbalanced, the entire backend-selection block (Steps 1--4) collapses and path D becomes production.

Second (R2), path G no longer treats `summclust` as an anchor for from-scratch CR3.
`summclust, vce(jackknife, mse)` is the production CR3 implementation.
From-scratch CR3 enters as a fallback only if `summclust` does not scale to IDN.
The cost arithmetic loses an eigendecomposition step that does not exist in CR3 anyway: $A_j = (I - H_{jj})^{-1}$ acts on residuals once.

Third (R3), path D is pinned to wild cluster unrestricted (WCU) inversion via `boottest, gridpoints(0)` with native root-finding, not WCR with grid-point re-bootstrapping.
The single-pass WCU inversion is roughly $30\times$ cheaper per cell than the WCR-style cost arithmetic in rev 3.
WCR drops to a fallback that only activates if WCU's root-finder fails to bracket.

Fourth (R4), paths G and D are reframed as the conventional MNW (2023) production-plus-validation pair, not as alternatives.
The published table reports CR3 + AHZ-Satterthwaite as the headline and WCU bootstrap as a robustness check.
Running both is conventional, answers symmetric referee questions ("why not CR3," "why not WCB") in one move, and does not require a binary methodological commitment.

The Greens from rev 3 carry through: the AHZ df contingency in pass criteria, the recoded-design construction pinned to first-implementer level, the F.0/F.1 split of path F, the PT 2018 corrigendum applicability for OLS-with-identity, the Davidson-MacKinnon precedent for the recoded-design pattern, the IDN-first ordering of the empirical block (now subordinate to Step 0.5's `summclust` first), and the falsifiable cost-comparison table.

## Why this plan exists

Step 0a produced two empirical findings.
Stata `reg_sandwich` on the TZA covs_trend design without FE absorption scales as roughly $O(J^2)$: 90 s at $J=1000$, 366 s at $J=2000$, extrapolated $\sim 3$ h at full $J=11{,}012$.
R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocated a dense intermediate that OOM'd at $J=11{,}012$, $N=29{,}864$.
The exact allocation site has not been pinned down; "dense $N \times N$ intermediate" remains a working hypothesis.

The user's pushback on a Stata-to-R production pivot is correct: if R OOM'd at TZA, it cannot scale to IDN unbalanced.
What survives is the question of how to compute BRL CR2 + AHZ Satterthwaite df, or CR3 + Satterthwaite, or WCU bootstrap inversion, at LCA scale at all.
Once reformulation (4) (recoded-design varlist-zero) is in scope, R's constraint-matrix advantage over Stata becomes moot: both backends accept varlist-zero contrasts natively.

The decision in rev 4 reduces to a single ordering question.
Run `summclust` first to get $G^*$; that diagnostic alone determines whether AHZ-style inference is meaningful at IDN scale.
If $G^*$ clears the bar, the joint pair (CR3 via `summclust`, WCU via `boottest`) becomes production-plus-validation.
If $G^*$ does not clear the bar, only path D survives.

## What the BRL+AHZ computation actually requires

Bell-McCaffrey CR2 (the BRL adjustment in Pustejovsky-Tipton 2018) is

$$\widehat{V}_{CR2} = (X'X)^{-1} \left[\sum_{j=1}^{J} X_j' A_j \hat{u}_j \hat{u}_j' A_j' X_j \right] (X'X)^{-1}, \qquad A_j = (I_{n_j} - H_{jj})^{-1/2}.$$

CR3 (MacKinnon, Nielsen, Webb 2023; Hansen 2025) replaces $A_j = (I - H_{jj})^{-1/2}$ with $A_j = (I - H_{jj})^{-1}$ acting on the residuals once.
No eigendecomposition, no per-cluster matrix square root.
Empirically CR3 performs as well or better than CR2 in many large-$J$ scenarios.

The HTZ Satterthwaite degrees of freedom for a $q$-dimensional linear contrast $C\beta = 0$ is a closed-form function of per-cluster influence matrices $G_j$ (PT 2018 Theorem 2 plus the 2023 corrigendum at https://jepusto.com/posts/pusto-tipton-2018-theorem-2/).
The corrigendum updates Theorem 2: the absorbed-FE shortcut holds only for OLS with identity working model.
The auxiliary OLS in our setting satisfies that condition exactly.

Three implementation facts shape the rest of the plan.
First, the per-cluster computation is $O(\sum_j (n_j^2 K + n_j K^2))$ in time and $O(JK^2)$ in memory if we cache per-cluster influence matrices; at our regime ($J \approx 30{,}000$, $K \approx 27$, $\bar{n}_j \approx 3$) the dominant term is $n_j K^2$.
Second, the HTZ Satterthwaite df recompute per grid $\phi$ scales as $O(JK^2 q + Jq^3)$, roughly $5 \cdot 10^8$ ops per grid point at $K = 27$, $q \approx 25$.
Third, off-the-shelf packages blow up because of how they organize the computation, not because the computation itself is expensive.

## The LCA constraint and reformulation (4)

The LCA contrast is

$$r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0, \qquad s \in S_R \setminus \{\underline{d}_0\}.$$

It mixes trajectory main effects $\alpha_s$ and trajectory-by-treatment interactions $\beta_s$.
The auxiliary OLS at $T = 5$, $K = 27$ has $J_R = 26$, so trajectory dummies $\alpha_s$ account for almost all of $K$.

Reformulation (4) defines, for each grid $\phi_0$ and each non-base trajectory $s$,

$$z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot \mathbb{1}\{\text{trajectory}_i = s\}.$$

Under the LCA restriction at $\phi_0$, the coefficients on $z_{is}^{(\phi_0)}$ are zero for all $s \in S_R \setminus \{\underline{d}_0\}$.
This is a varlist-zero test of $J_R - 1$ coefficients on a per-$\phi$ design, native to `test_sandwich` (Stata) and `Wald_test` with `constrain_zero` (R).
The pattern is structurally identical to the recoding Davidson-MacKinnon use in their wild bootstrap papers; it is not novel.

Reformulation (4) sidesteps FE recovery entirely.
Its cost is one refit per grid point.
The CR3 step has to be redone per $\phi$ because $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s; the per-grid CR3 rebuild is the dominant cost.

## Recoded-design construction, pinned

For first-implementer level specificity, four rules govern the recoded design.

First, base trajectory per country/spec.
Consumption (all three countries): $\underline{d}_0 = 2$.
IDN income: $\underline{d}_0 = 16$ (per the CLAUDE.md known issue on `define_switcherpars`).
TZA income: $\underline{d}_0 = 5$ (same source).
CHN income: TBD, default to $\underline{d}_0 = 2$ pending verification.

Second, variable mapping.
$D_{is}$ corresponds to `beta_s_{s}` in the existing GRC code; $\mathbb{1}\{\text{trajectory}_i = s\}$ corresponds to `alpha_d_{s}`.
The recoded variable is

$$z_{is}^{(\phi_0)} = \mathtt{beta\_s\_}s - \phi_0 \cdot \mathtt{alpha\_d\_}s,$$

constructed for $s \in S_R \setminus \{\underline{d}_0\}$ and tested via joint zero.

Third, singleton handling.
IDN unbalanced has a tail of singleton clusters ($n_j = 1$).
For these, $I_1 - H_{11}$ has a single eigenvalue near zero that triggers numerical issues.
Drop singletons before constructing the design and report the count and share dropped; expect $\sim 5$--10% of clusters but a much smaller share of $N$.

Fourth, controls and FE.
Include the same controls as the matched GRC spec (covs_trend or covs_all).
Absorb trajectory FE in paths A, B, and G; in path C, include trajectory dummies as columns of $X$.
The recoded $z$'s are not collinear with trajectory FE because $\phi_0 \ne 0$ on the grid.

## Candidate paths

### Path A. Stata `reg_sandwich, absorb(trajectory)` + reformulation (4)

The cleanest absorbed-mode Stata path.
At each grid $\phi_0$, build the recoded $z$ variables, fit `reg_sandwich y z_2 ... z_{J_R} controls, absorb(trajectory) cluster(pid)`, run `test_sandwich z_2 z_3 ... z_{J_R}`.
The PT 2018 corrigendum legitimizes the absorbed-FE shortcut for OLS-with-identity.
Per-cell wall = 30 grid points $\times$ per-fit wall, where per-fit wall includes the full vcovCR rebuild because $H_{jj}(\phi)$ varies with $\phi$.

### Path B. R `fixest::feols(..., fixef = "trajectory")` + `clubSandwich::vcovCR` + reformulation (4)

Same recoded-design test through R.
Path B's advantage over A is contingent on whether `vcovCR.fixest` avoids the dense intermediate that `reg_sandwich` (unabsorbed) hit.
The controlled-OOM reproduction in Step 1 resolves this.

### Path C. From-scratch BRL CR2 with cluster-by-cluster computation

Implement the CR2 meat and the AHZ Satterthwaite df directly, never materializing $H$ as a dense $N \times N$ object.
Anchor against `clubSandwich` 0.6.2 at $J = 1500$ on the TZA covs_trend recoded design with $\phi_0 = \hat\phi_{\text{point}}$; tolerance $10^{-4}$ on the test statistic and $10^{-3}$ on the df.
Corrigendum incorporation status in clubSandwich 0.6.2 is TODO; the corrigendum read is scheduled to $\le$ 2026-05-09 or before path-C kickoff, whichever is sooner.
Implementation effort: 1--2 days.

Path C is held in reserve.
The MNW (2023) recommendation pairs CR3 with WCB; CR2 is the older convention and only re-enters if path G fails for an implementation-specific reason.

### Path D. WCU bootstrap inversion via `boottest`

Path D inverts the wild cluster bootstrap directly using `boottest`'s native root-finding rather than re-bootstrapping at every grid point.
Specification, pinned: WCU inversion via `boottest, gridpoints(0)` with native root-finding, Rademacher weights, $B = 9999$ as the production default ($B = 999$ for development), root-finder tolerance $10^{-4}$ on $\phi$.
WCR with grid-point re-bootstrapping is a fallback that activates only if WCU's root-finder fails to bracket the CI endpoints.

Per-cell cost at IDN scale under WCU: one bootstrap pass of $B = 9999$ draws times $\sim 9 \cdot 10^5$ ops per draw $\approx 9 \cdot 10^9$ ops, on the order of seconds to minutes per cell wall on `boottest`'s native code path.
The 30-grid multiplier that drove rev 3's 5--15 min/cell estimate disappears: WCU does not re-bootstrap per grid point.

The published table can report CR3 + AHZ as the headline and WCU bootstrap as a validation row; the referee narrative does not have to shift away from F-adjusted CIs.

### Path F. Recent CR2/CR3-at-scale alternatives

Three concrete items to scan, split into F.0 (literature scan, 1--2 h) and F.1 (candidate prototype, 2--3 h, conditional).

F.1 candidates: Niccodemi-Alessie sparse-CR2; clubSandwich GitHub dev branch ahead of CRAN.
`summclust` is no longer in this list because it lives in path G.

Promotion criterion: any path-F candidate that runs at IDN scale within wall-time and memory budgets is preferred over path C (less novelty risk).
Path F does not displace path G + D as the joint headline.

### Path G. CR3 via `summclust, vce(jackknife, mse)`

Path G is `summclust`'s native CR3 implementation, not a from-scratch reimplementation.
`summclust, vce(jackknife, mse)` returns CV3 standard errors directly; `vce(jackknife)` returns CV3J.
The MNW (2023) recommendation is CV3J for the joint CR3+WCB pair; we use `vce(jackknife)` as the headline and `vce(jackknife, mse)` as the cross-check.

Anchor specification, pinned: `summclust, vce(jackknife, mse)` at $J = 1500$ on the TZA covs_trend recoded design as the small-$J$ self-consistency reference; tolerance $10^{-6}$ relative on the CR3 covariance, $10^{-4}$ on the test statistic, $10^{-3}$ on the df.
The from-scratch CR3 implementation activates as a fallback only if `summclust` does not scale to IDN unbalanced (verified in Step 0.5).
If from-scratch is needed, implementation effort is 1 day, dominated by the AHZ df recompute and not by the meat (no eigendecomposition).

### Referee Q&A: CR2 vs CR3, CR3 vs WCB

Why CR3 not CR2?
At our IDN-scale $J/q$ ratio with non-trivial leverage on switcher trajectories, $A_j = (I - H_{jj})^{-1/2}$ becomes numerically poorly conditioned at low effective cluster counts; CR3's $A_j = (I - H_{jj})^{-1}$ is closed-form on the residuals and avoids the eigensystem entirely.
MNW (2023) report CR3 performs as well or better than CR2 in the regimes most like ours.

Why CR2 not CR3?
CR2 is the older convention and is preferred when leverage is moderate and $G^*$ is large; we run path C as a small-$J$ cross-check against path G to confirm the two agree at $J = 1500$, but CR2 does not earn the headline at LCA scale.

Why CR3 not WCB?
CR3 keeps the F-adjusted-AHZ narrative the paper builds toward; WCB-inverted CIs require a section-name change and a different referee story.
We report both: CR3 + AHZ-Satterthwaite as the headline, WCU bootstrap as a robustness row.

Why WCB not CR3?
WCB is asymptotically valid under fewer assumptions on the leverage structure; it is the conventional fallback when CR-type leverage diagnostics flag concern.
If $G^* < 30$ at IDN unbalanced, WCU bootstrap becomes the headline and CR3 drops out.

## Cost comparison

The cost-comparison table is the falsifiable core of the plan.
The "per-fit wall" column is the IDN-scale wall for one $(X, \phi_0)$ vcovCR/jackknife build (paths A, B, G) or one BRL meat build (path C); path D is scoped per cell, not per fit, because WCU inversion does not refit per grid point.

| Path | Prototype | TZA full ($J=11{,}012$) per fit | IDN unb. ($J\approx 30{,}000$) per fit | Per-cell wall (30 grid) | 60-cell wall, 4-way parallel | Anchor |
|---|---:|---:|---:|---:|---:|---:|
| A. `reg_sandwich, absorb` + reform (4) | 2--3 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends | clubSandwich at $J=1500$ |
| B. `feols` + `vcovCR` + reform (4) | 2 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends | clubSandwich at $J=1500$ |
| C. From-scratch CR2 (held in reserve) | 1--2 days | $\sim 30$ s | $\sim 1$ min | $\sim 10$--30 min | 2.5--7.5 h | clubSandwich at $J=1500$ |
| D. WCU inversion via `boottest` ($B=9999$) | 0.5 day | $<$ 1 min | seconds--minutes | seconds--minutes | $<$ 30 min | published method |
| F. Path-F candidate | 1--2 h F.0 + 2--3 h F.1 | unknown | unknown | TBD | TBD | candidate-dependent |
| G. `summclust, vce(jackknife, mse)` | hours (use as-is) | $\sim 10$ s | $\sim 30$ s | $\sim 10$--30 min | 2.5--7.5 h | self at $J=1500$, $10^{-6}$ relative |

Three reads.
First, paths A and B are dead at the 60-cell budget if their per-fit IDN wall exceeds 6 minutes.
Second, path G dominates path C on prototype effort by an order of magnitude because `summclust` is the implementation, not just the anchor.
Third, path D is roughly $30\times$ cheaper per cell than rev 3's WCR-style estimate, which makes the joint G+D pair feasible inside a single working day's wall budget.

## Recommended order of attack

The work breaks into a strictly sequential head followed by a parallel empirical block.

Step 0 (30 min). Verify the IDN data-prep pipeline runs end-to-end on `lca-inversion`'s RP7.

Step 0.5 (30--60 min). Run `summclust` on TZA full and on IDN unbalanced.
Use `summclust y z_* controls, cluster(pid)` (or the equivalent `summclust` invocation) on the recoded-design covs_trend spec.
Report $G^*$, partial leverage, influence, and cluster-size moments.
This step also verifies that `summclust` itself scales to IDN unbalanced; if `summclust` OOMs or times out, the from-scratch CR3 fallback in path G activates and Step 0.5 records the wall and memory profile for that contingency.

Step 0.5 decision rule: if $G^* < 30$ at IDN unbalanced, skip Steps 1--4 entirely and route to path D as production.
Write rev 5 with WCU bootstrap as the headline.
If $G^* \ge 30$, proceed to the rest of the empirical block with the joint G+D pair as the headline target.

Step 1 (1--2 h, conditional on $G^* \ge 30$). Reproduce the clubSandwich OOM under controlled conditions.
Re-run the failed $J = 11{,}012$ TZA design with `tracemalloc` (Python) or `tracemem()` (R) instrumented from process start.
Verify the profiler is available before committing the budget; flag if the R or Python environment requires a reinstall.
Success criterion: a `tracemalloc` snapshot at peak with the top 10 allocation sites identified.

Step 2 (1--2 h). Path-F literature scan (F.0).
Niccodemi-Alessie, clubSandwich GitHub dev branch.
Promotion: if a candidate has a working implementation suitable for our scale, schedule F.1 (2--3 h prototype on TZA full) before the IDN probe.

Step 3 (2--3 h, parallelizable). IDN-scale probe of paths A and B at one $\phi$.
Build the IDN unbalanced cluster pattern from the actual RP7 design, drop singletons, run paths A and B in parallel under reformulation (4).
Single-fit timing first; only if the single fit comes in under 6 minutes do we extrapolate to the 30-fit cell budget.

Step 4 (conditional, 2--3 h). Path G is already scoped via `summclust` in Step 0.5; the from-scratch CR3 prototype only activates if `summclust` did not scale.
If both A and B fail at IDN AND F.0 finds nothing actionable AND `summclust` scaled in Step 0.5, the joint G+D pair is the production answer; no further prototype is needed.
If `summclust` did not scale in Step 0.5, run the from-scratch CR3 prototype on the TZA covs_trend recoded design at $J = 1500$ and validate against `summclust`'s small-$J$ output.
If F.0 finds a candidate AND A, B both fail AND `summclust` did not scale, run F.1 alongside the from-scratch CR3 prototype and pick on cost.

The decision rule for "F.0 null AND A, B fail" is explicit: route to G + D paired (no path C).

## Pass criteria

A backend is promoted if all six hold.

(i) Per-fit wall time at full IDN scale is under 30 minutes.
(ii) Peak memory is under 16 GB.
(iii) The AHZ p-value on the recoded-design varlist-zero agrees with the small-$J$ anchor (clubSandwich for paths A, B, C; `summclust` for path G) to $10^{-4}$ on the test statistic and $10^{-3}$ on the df at $J = 1500$ on the TZA covs_trend recoded design with $\phi_0 = \hat\phi_{\text{point}}$.
(iv) The implied CI endpoints across the 30-grid are computable in under 4 hours per cell wall (60 cells fit in $\le 2.5$ days with 4-way parallelism via separate Stata sessions or R processes).
(v) The empirical AHZ df at the LCA contrast at IDN scale is between 4 and $J/2$.
df below 4 triggers fallback to path D regardless of (i)--(iv); df above $J/2$ is df breakdown and triggers the same fallback.
(vi) $G^*$ from `summclust` $\ge 30$ at IDN unbalanced.
A pass on (i)--(v) at $G^* < 30$ is meaningless; below the bar, only path D survives.

Anti-conservative-bias check: a synthetic coverage MC at the empirical $J/q$ ratio runs as a separate validation step.
Rev 5 carries this with a 4-hour wall budget for a $1000$-replication MC at the post-Step-0.5 backend (CR3 if $G^* \ge 30$, WCU otherwise); if it does not fit in rev 5's scope, it lands in the broader pipeline plan rev 4 with the same budget.

## Decision branch

Step 0.5 outcome dictates the rev 5 structure.

If $G^* \ge 30$ at IDN unbalanced and `summclust` scales: production = path G, validation = path D.
The published table reports CR3 + AHZ-Satterthwaite as the headline and WCU bootstrap as a robustness check.
This is the MNW (2023) joint pair and matches the conventional referee expectation.

If $G^* \ge 30$ but `summclust` does not scale: production = from-scratch CR3 (path G fallback), validation = path D.
Path C is held in reserve and only re-enters if a referee specifically requests CR2.

If $G^* < 30$: production = path D (WCU bootstrap inversion), no CR3 headline.
Rev 5 reframes the published section from "F-adjusted CIs" to "Bootstrap-inverted CIs" and drops the AHZ-Satterthwaite narrative.
This is a substantive change to the paper's framing and the user makes the final call before rev 5 is written.

If exactly one of A, B, F passes at IDN AND $G^* \ge 30$ AND `summclust` scales: ratify the cheapest path-A/B/F option as a CR2 cross-check row, with G+D as the joint headline.
If multiple of A, B, F pass: prefer F (least novelty + least dependency), then B (most flexible R-side ecosystem), then A (closest to existing CKT Stata pipeline).

## Open decision points

These determine which plan rev 5 to write.

(i) What is $G^*$ at IDN unbalanced from `summclust`?
(ii) Does `summclust` itself scale to IDN unbalanced?
(iii) Where does `clubSandwich` allocate the OOM-blowing intermediate at TZA?
(iv) Does the user accept WCU bootstrap as the headline if $G^* < 30$?
(v) Does reformulation (4)'s 30-fits-per-cell cost dominate any per-fit savings from absorbed mode?

Step 0.5 answers (i) and (ii) directly; Step 1 answers (iii); the user answers (iv) before rev 5 lands; Step 3 answers (v).

## What this plan is not

This is a decision plan whose output is which of paths A, B, C, D, F, G becomes the basis for plan rev 5.
The implementation details (Stata wrapper structure, Python bridge, subprocess verification, synthetic coverage MC harness, empirical re-run) are unchanged from the broader F-adjustment work and ride on top of whichever backend the next checks ratify.

This plan does not specify the synthetic coverage MC design, the WCU validation harness, or the published-table layout under either AHZ or WCB.
Those land in plan rev 5 once Step 0.5's $G^*$ comes back.

This plan does not relitigate AHZ vs WCB as a primary methodological choice.
The MNW (2023) joint-pair convention treats them as production-plus-validation; only a sub-30 $G^*$ at IDN unbalanced collapses that into a single-headline WCB-only structure.

If `summclust` does not scale AND from-scratch CR3 fails AND WCU does not converge, the work parks: the chi-squared-based CIs in the existing pipeline remain the published inference, with the F-adjustment narrative downgraded from "implemented" to "scoped and infeasible at our scale" in the derivation note.
