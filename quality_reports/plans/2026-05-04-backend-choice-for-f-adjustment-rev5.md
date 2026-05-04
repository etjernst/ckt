# Plan rev 5: backend choice for AHZ-adjusted CR3 inference at LCA-inversion scale

Date: 2026-05-04 (rev 5)
Branch: `lca-inversion`
Predecessors: [rev 4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev4.md), [rev 3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev3.md), [rev 2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md), [rev 1](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md).
Critique driving this rev: [`2026-05-02_rev4-six-dimension-critique.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev4-six-dimension-critique.md) (2 Red, 5 Yellow, 6 Green).
Predecessor empirical memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## What changed since rev 4

Rev 4 was structurally close---Step 0.5 first, `summclust` as the path-G implementation, joint G+D pair as the production+validation pattern.
Two specific claims were wrong, and rev 5 patches them without re-architecting.

First (R1), the $G^* \ge 30$ kill threshold was an invented round number.
MacKinnon, Nielsen, Webb (2023) give no such cutoff, and MacKinnon's 2025 review at https://arxiv.org/html/2604.02000v1 frames $G^*$ as a soft trigger keyed to published empirical concern levels around $G^* \in [6, 10]$, not a hard kill rule.
Rev 5 replaces the kill rule with a soft trigger and keeps CR3 in scope below the trigger with a caveat rather than dropping it.

Second (R2), path D's "WCU inverts in one pass via `boottest, gridpoints(0)`" claim conflated scalar-null inversion (what `boottest` natively supports per Roodman et al. 2019) with the $q \approx 25$-dimensional joint LCA restriction over scalar nuisance $\phi$ that this paper actually tests.
Rev 5 adds Step 0.6, a 15--30 minute `boottest` smoke test that verifies one-pass joint-null inversion is feasible at $J = 1500$ before the joint G+D wall budget gets committed.
Failure routes path D to one of two named fallbacks: `WildBootTests.jl` as a Julia subprocess, or WCR with grid-point re-bootstrapping at roughly $30\times$ the rev 4 cost.

The five actionable Yellows are folded in.
First, MacKinnon (2025) is cited at Step 0.5 (for the $G^*$ trigger range) and at path D (for the WCU variant choice).
Second, `vce(jackknife)` (CV3J) and `vce(jackknife, mse)` (CV3) are both reported per MNW (2023), not framed as headline plus cross-check.
Third, the WCU variant is pinned to WCU31 per MacKinnon (2025) recommendations for moderate-to-large $G$, instantiated via `boottest`'s `weighttype(rademacher)`.
Fourth, the `summclust` IDN-scaling fallback now has a budget: 8 GB peak memory or 30 minutes wall, whichever fires first, then from-scratch CR3 with a 1-day budget and $10^{-6}$ relative agreement against `summclust` at $J = 1500$.
Fifth, CHN income base trajectory verification is sequenced ahead of any path-D run on the CHN income spec.

The six Greens carry through verbatim where possible: Step 0.5 ordering ahead of backend selection, path G as `summclust`, joint G+D pair framing, AHZ df contingency in pass criteria, recoded-design construction at first-implementer level, and path-F null handling.

## Why this plan exists

Step 0a produced two empirical findings.
Stata `reg_sandwich` on the TZA covs_trend design without FE absorption scales as roughly $O(J^2)$: 90 s at $J=1000$, 366 s at $J=2000$, extrapolated $\sim 3$ h at full $J=11{,}012$.
R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocated a dense intermediate that OOM'd at $J=11{,}012$, $N=29{,}864$.
The exact allocation site has not been pinned down; "dense $N \times N$ intermediate" remains a working hypothesis.

The user's pushback on a Stata-to-R production pivot is correct: if R OOM'd at TZA, it cannot scale to IDN unbalanced.
What survives is the question of how to compute BRL CR2 + AHZ Satterthwaite df, or CR3 + Satterthwaite, or WCU bootstrap inversion, at LCA scale at all.
Once reformulation (4) (recoded-design varlist-zero) is in scope, R's constraint-matrix advantage over Stata becomes moot: both backends accept varlist-zero contrasts natively.

The decision in rev 5 reduces to two ordering questions, answered in sequence.
Run `summclust` first to get $G^*$; that diagnostic locates us on the MacKinnon (2025) trigger spectrum.
Run `boottest, gridpoints(0)` second on the recoded varlist-zero null to verify that path D's one-pass inversion implements what we need at the dimensionality our LCA contrast requires.
Together, these two diagnostics pick the production+validation pair before any wall-time budget gets committed.

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

Two diagnostic guards on the per-grid recoding.
First, log the condition number of the $z$-block of the design at each grid $\phi_0$; for $\phi_0$ values where the LCA restriction is approximately satisfied in-sample, $z_{is}^{(\phi_0)}$ may be near-collinear with trajectory FE and the per-$\phi$ CR3 build can become numerically unstable.
A condition number above $10^{12}$ at any grid point flags that point in the output and triggers the contiguous-acceptance fallback rule from the broader F-adjustment plan rev 3 (locked decision 4) when handling disjoint CIs in the inverted test.
Second, follow that same locked decision when the per-grid p-value series has more than one sign change in $(p - \alpha)$ for a given (country, spec, parameter) cell: fall back to a single-$\widehat\nu$ AHZ critical value evaluated at the OLS point estimate of $\phi$ for that cell.

## Recoded-design construction, pinned

For first-implementer level specificity, four rules govern the recoded design.

First, base trajectory per country/spec.
Consumption (all three countries): $\underline{d}_0 = 2$.
IDN income: $\underline{d}_0 = 16$ (per the CLAUDE.md known issue on `define_switcherpars`).
TZA income: $\underline{d}_0 = 5$ (same source).
CHN income: verify before path D runs on CHN income spec by reading what `define_switcherpars` (or the data-driven base selector at L1511--1524 of `0_programs.do`) returns; if the selector picks a non-default base, document the value in the rev 5 implementation log; otherwise default to $\underline{d}_0 = 2$.

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

### Path D. WCU bootstrap inversion via `boottest`, conditional on Step 0.6

Path D inverts the wild cluster bootstrap using `boottest`'s native root-finding rather than re-bootstrapping at every grid point, conditional on Step 0.6 confirming that the one-pass inversion handles the $q \approx 25$-dimensional joint LCA null over scalar $\phi$.
Specification, pinned: WCU31 inversion via `boottest, gridpoints(0)` with `weighttype(rademacher)`, $B = 9999$ as the production default ($B = 999$ for development), root-finder tolerance $10^{-4}$ on $\phi$.
The WCU31 choice follows MacKinnon (2025) Section 4 recommendations for moderate-to-large $G$ where the unrestricted estimator's residuals dominate the small-sample noise pattern.

If Step 0.6 fails---that is, `boottest, gridpoints(0)` does not pass both parts of the success criterion---path D resolves to D-grid: WCR with grid-point re-bootstrapping in Stata `boottest`, at roughly $30\times$ the per-cell cost of the one-pass variant.
This is the rev 3 cost arithmetic and lands per-cell wall back at 5--15 minutes; 60 cells in 5--15 hours total at single-thread, or 1--4 hours with 4-way parallelism via separate Stata sessions.

A `WildBootTests.jl` Julia subprocess path exists in the literature and supports multi-parameter joint inversion natively, but the Stata-to-Julia marshaling on Windows is out of scope for this work; the implementation cost is not justified by the marginal speedup over D-grid.
If a referee specifically requests one-pass WCU and Step 0.6 has failed, that becomes a separate scoped task.

The published table reports CR3 + AHZ-Satterthwaite as the headline above the soft trigger and WCU bootstrap as a robustness check; below the soft trigger the WCU row gains emphasis but CR3 stays in the table with a caveat.

### Path F. Recent CR2/CR3-at-scale alternatives

Three concrete items to scan, split into F.0 (literature scan, 1--2 h) and F.1 (candidate prototype, 2--3 h, conditional).

F.1 candidates: Niccodemi-Alessie sparse-CR2; clubSandwich GitHub dev branch ahead of CRAN.
`summclust` is no longer in this list because it lives in path G.

Promotion criterion: any path-F candidate that runs at IDN scale within wall-time and memory budgets is preferred over path C (less novelty risk).
Path F does not displace path G + D as the joint headline.

### Path G. CR3 via `summclust`, both `vce(jackknife)` and `vce(jackknife, mse)` reported

Path G is `summclust`'s native CR3 implementation, not a from-scratch reimplementation.
`summclust, vce(jackknife)` returns CV3J standard errors; `summclust, vce(jackknife, mse)` returns CV3.
Per MNW (2023), the convention is to report both CV3 and CV3J side by side and flag any disagreement, not to pick one as headline and demote the other.
Rev 5 reports both in the published table and in any pre-publication diagnostics; agreement to $10^{-3}$ relative is the expected pattern, and any larger gap gets called out in the derivation note.

Anchor specification, pinned: `summclust, vce(jackknife)` and `summclust, vce(jackknife, mse)` at $J = 1500$ on the TZA covs_trend recoded design as the small-$J$ self-consistency reference; tolerance $10^{-6}$ relative on the CR3 covariance, $10^{-4}$ on the test statistic, $10^{-3}$ on the df.
The from-scratch CR3 implementation activates as a fallback only if `summclust` does not scale to IDN unbalanced (the budget is pinned in Step 0.5: 8 GB peak memory or 30 minutes wall).
Acceptance for the from-scratch fallback: covariance agreement with `summclust` at $J = 1500$ to $10^{-6}$ relative.
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
Below the soft trigger ($G^* \in [6, 10]$ per MacKinnon 2025) the WCU row in the published table gains emphasis and CR3 carries an explicit small-$G^*$ caveat.

Why not Hansen (2025) calculated df?
Hansen (2025) proposes a calculated df for the cluster-robust Wald statistic that does not rely on the Satterthwaite approximation, deriving the df from the empirical distribution of the test statistic under the null.
For a referee reading the recent literature this is the natural alternative to AHZ-Satterthwaite at small $G^*$.
We do not adopt it as the production path because `summclust` and `boottest` together already cover the production+validation pair the paper builds toward, and adding a third inference framework expands the referee surface without obvious gain.
We commit to running Hansen (2025) calculated df as a robustness row in the derivation note's appendix if a referee specifically asks; the implementation is a closed-form post-estimation calculation against the cached `summclust` output and adds no new package dependency.

## Cost comparison

The cost-comparison table is the falsifiable core of the plan.
The "per-fit wall" column is the IDN-scale wall for one $(X, \phi_0)$ vcovCR/jackknife build (paths A, B, G) or one BRL meat build (path C); path D is scoped per cell and conditional on Step 0.6.

| Path | Prototype | TZA full ($J=11{,}012$) per fit | IDN unb. ($J\approx 30{,}000$) per fit | Per-cell wall (30 grid) | 60-cell wall, 4-way parallel | Anchor |
|---|---:|---:|---:|---:|---:|---:|
| A. `reg_sandwich, absorb` + reform (4) | 2--3 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends | clubSandwich at $J=1500$ |
| B. `feols` + `vcovCR` + reform (4) | 2 h | unknown | unknown (kill criterion) | 30 $\times$ per-fit | depends | clubSandwich at $J=1500$ |
| C. From-scratch CR2 (held in reserve) | 1--2 days | $\sim 30$ s | $\sim 1$ min | $\sim 10$--30 min | 2.5--7.5 h | clubSandwich at $J=1500$ |
| D-onepass. WCU31 inversion via `boottest, gridpoints(0)` ($B=9999$) | 0.5 day | $<$ 1 min | seconds--minutes | seconds--minutes | $<$ 30 min | published method (conditional on Step 0.6 pass; recent `boottest` documentation suggests one-pass CI inversion is for scalar nulls, so this branch may not survive Step 0.6) |
| D-grid. WCR with grid-point re-bootstrapping ($B=9999$) | 0.5 day | $<$ 1 min | seconds--minutes | 5--15 min | 5--15 h | published method (Step 0.6 fail fallback, $\sim 30\times$ D-onepass; the realistic D variant absent a Step 0.6 surprise) |
| F. Path-F candidate | 1--2 h F.0 + 2--3 h F.1 | unknown | unknown | TBD | TBD | candidate-dependent |
| G. `summclust, vce(jackknife)` and `vce(jackknife, mse)` | hours (use as-is) | $\sim 10$ s | $\sim 30$ s | $\sim 10$--30 min | 2.5--7.5 h | self at $J=1500$, $10^{-6}$ relative |

Three reads.
First, paths A and B are dead at the 60-cell budget if their per-fit IDN wall exceeds 6 minutes.
Second, path G dominates path C on prototype effort by an order of magnitude because `summclust` is the implementation, not just the anchor.
Third, path D's cost is now conditional: D-onepass is roughly $30\times$ cheaper per cell than D-grid, so Step 0.6's outcome shifts the joint G+D pair's wall budget from "fits in a working day" (D-onepass) to "fits in two to three days at 4-way parallelism" (D-grid).

## Recommended order of attack

The work breaks into a strictly sequential head followed by a parallel empirical block.

Step 0 (30 min). Verify the IDN data-prep pipeline runs end-to-end on `lca-inversion`'s RP7.

Step 0.5 (60--90 min). Run `summclust` on TZA full and on IDN unbalanced, with a scaling pre-flight first.

Pre-flight scaling sweep (15--20 min): run `summclust` on the IDN unbalanced cluster pattern at $J \in \{5{,}000, 10{,}000, 20{,}000\}$ subsamples and time + memory-profile each.
MNW (2023) advertise `summclust`'s computational efficiency for the "large clusters" regime (large $\bar{n}_j$); IDN unbalanced is the opposite case ($J \approx 30{,}000$, $\bar{n}_j \approx 3$), so MNW's scalability claim does not transfer automatically.
The sweep gives a scaling curve we can extrapolate to $J = 30{,}000$ before committing to the full run.
If the extrapolation predicts $> 30$ minutes wall or $> 8$ GB peak at $J = 30{,}000$, kick off the from-scratch CR3 prototype in parallel with the full IDN run rather than as a downstream fallback.

Full run (30--60 min): use `summclust y z_* controls, cluster(pid)` on the recoded-design covs_trend spec at TZA full and IDN unbalanced full.
Report $G^*$, partial leverage, influence, and cluster-size moments.
If `summclust` exceeds the 8 GB peak memory or 30 minutes wall budget at IDN, log peak memory and the dominant operation, then activate the from-scratch CR3 fallback (1-day budget; acceptance: $10^{-6}$ relative agreement against `summclust` at $J = 1500$).

Step 0.5 decision rule (soft trigger, MacKinnon 2025): if $G^*$ at IDN unbalanced lands in the published empirical concern range $\sim 6$--$10$ or below, the rev 5 published table emphasizes the WCU row and reports CR3 with a small-$G^*$ caveat; CR3 stays in the table.
Above $\sim 10$, report CR3 + WCU as the standard joint pair without caveat.
The trigger is a soft routing signal, not a kill rule, and Steps 1--4 still run.

Step 0.6 (15--30 min). Run a `boottest, gridpoints(0)` smoke test on the TZA $J = 1500$ recoded varlist-zero null at $\phi_0 = \hat\phi_{\text{point}}$.
The test confirms whether one-pass inversion over scalar $\phi$ is feasible for the joint $q \approx 25$-dimensional LCA restriction.
Success criterion (two parts, both required): (a) `boottest` returns a CI for $\phi$ from a single bootstrap pass on the joint $q$-dim null, with finite endpoints and no convergence warnings; (b) the returned CI corresponds to inversion of the joint Wald statistic, verified by checking that the one-step `boottest` p-value at $\phi_0 = $ each CI endpoint equals $\alpha = 0.05$ to within $10^{-3}$, AND that the test statistic at $\phi_0 = \hat\phi_{\text{point}}$ matches a separately-computed $q$-dim joint Wald.
The two-part criterion guards against the silent failure mode where `boottest` runs to completion but treats the test as a per-coefficient scalar inversion and returns a non-joint CI that looks plausible but is wrong.
Failure modes: `boottest` rejects the multi-parameter null specification with a syntax error; `boottest` accepts but the root-finder fails to bracket; `boottest` runs but the joint-Wald cross-check at the CI endpoints disagrees with $\alpha = 0.05$ (the silent per-coefficient case).
On failure, path D resolves to D-grid (WCR with grid-point re-bootstrapping at roughly $30\times$ cost); D-Julia via `WildBootTests.jl` exists in the literature but is out of scope for this work.

Step 1 (1--2 h, parallelizable with Step 0.5). Reproduce the clubSandwich OOM under controlled conditions.
Re-run the failed $J = 11{,}012$ TZA design with `tracemalloc` (Python) or `tracemem()` (R) instrumented from process start.
Verify the profiler is available before committing the budget; flag if the R or Python environment requires a reinstall.
Success criterion: a `tracemalloc` snapshot at peak with the top 10 allocation sites identified.
Step 1 has no input-output dependency on Step 0.5 or Step 0.6, so the two can run on separate sessions and finish faster end-to-end.

Step 2 (1--2 h). Path-F literature scan (F.0).
Niccodemi-Alessie, clubSandwich GitHub dev branch.
Promotion: if a candidate has a working implementation suitable for our scale, schedule F.1 (2--3 h prototype on TZA full) before the IDN probe.

Step 3 (2--3 h, parallelizable). IDN-scale probe of paths A and B at one $\phi$.
Build the IDN unbalanced cluster pattern from the actual RP7 design, drop singletons, run paths A and B in parallel under reformulation (4).
Single-fit timing first; only if the single fit comes in under 6 minutes do we extrapolate to the 30-fit cell budget.

Step 4 (conditional, 2--3 h). Path G is already scoped via `summclust` in Step 0.5; the from-scratch CR3 prototype only activates if `summclust` did not scale.
If both A and B fail at IDN AND F.0 finds nothing actionable AND `summclust` scaled in Step 0.5, the joint G+D pair (with the D variant chosen by Step 0.6) is the production answer; no further prototype is needed.
If `summclust` did not scale in Step 0.5, run the from-scratch CR3 prototype on the TZA covs_trend recoded design at $J = 1500$ and validate against `summclust`'s small-$J$ output to $10^{-6}$ relative.
If F.0 finds a candidate AND A, B both fail AND `summclust` did not scale, run F.1 alongside the from-scratch CR3 prototype and pick on cost.

The decision rule for "F.0 null AND A, B fail" is explicit: route to G + D paired (no path C), with the D variant selected by Step 0.6.

## Pass criteria

A backend is promoted if all six hold.

(i) Per-fit wall time at full IDN scale is under 30 minutes.
(ii) Peak memory is under 16 GB.
(iii) The AHZ p-value on the recoded-design varlist-zero agrees with the small-$J$ anchor (clubSandwich for paths A, B, C; `summclust` for path G) to $10^{-4}$ on the test statistic and $10^{-3}$ on the df at $J = 1500$ on the TZA covs_trend recoded design with $\phi_0 = \hat\phi_{\text{point}}$.
(iv) The implied CI endpoints across the 30-grid are computable in under 4 hours per cell wall (60 cells fit in $\le 2.5$ days with 4-way parallelism via separate Stata sessions or R processes).
(v) The empirical AHZ df at the LCA contrast at IDN scale is between 4 and $J/2$.
df below 4 triggers fallback to path D regardless of (i)--(iv); df above $J/2$ is df breakdown and triggers the same fallback.
(vi) $G^*$ from `summclust`: if $G^*$ at IDN unbalanced sits in the MacKinnon (2025) concern range $\sim 6$--$10$ or below, the WCU row gains emphasis in the published table and the CR3 row carries a small-$G^*$ caveat; pass (i)--(v) at $G^*$ in this range still ratifies CR3 in the table, just with the caveat.
The trigger is a soft routing signal, not a kill rule.

Anti-conservative-bias check: a synthetic coverage MC at the empirical $J/q$ ratio runs as a separate validation step.
Rev 5 carries this with a 4-hour wall budget for a $1000$-replication MC at the post-Step-0.5 backend (CR3 if $G^*$ above the soft trigger, WCU emphasized if at or below); if it does not fit in rev 5's scope, it lands in the broader pipeline plan rev 4 with the same budget.

## Decision branch

Step 0.5 and Step 0.6 outcomes jointly dictate the rev 6 structure.

If $G^*$ above the soft trigger AND `summclust` scales AND Step 0.6 passes: production = path G (both CV3 and CV3J), validation = path D-onepass.
The published table reports CR3 + AHZ-Satterthwaite as the headline and WCU31 bootstrap as a robustness check; this is the MNW (2023) joint pair and matches the conventional referee expectation.

If $G^*$ above the soft trigger AND `summclust` scales AND Step 0.6 fails: production = path G, validation = path D-Julia (preferred) or path D-grid (fallback).
The wall budget shifts from "fits in a working day" to "fits in two to three days at 4-way parallelism" if D-grid is the only available variant.

If $G^*$ above the soft trigger AND `summclust` does not scale: production = from-scratch CR3 (path G fallback, validated against `summclust` at $J = 1500$ to $10^{-6}$ relative), validation = path D under the variant Step 0.6 ratifies.
Path C is held in reserve and only re-enters if a referee specifically requests CR2.

If $G^*$ in or below the soft trigger range ($\sim 6$--$10$): production = path G with small-$G^*$ caveat, validation = path D with emphasis.
The published section narrative shifts to lead with the WCU row; CR3 stays in the table for completeness with the caveat documented in the note.
This is a tone shift, not a section-name change; the user makes the final call on phrasing before rev 6 is written.

If exactly one of A, B, F passes at IDN AND $G^*$ above the soft trigger AND `summclust` scales: ratify the cheapest path-A/B/F option as a CR2 cross-check row, with G+D as the joint headline.
If multiple of A, B, F pass: prefer F (least novelty + least dependency), then B (most flexible R-side ecosystem), then A (closest to existing CKT Stata pipeline).

## Open decision points

These determine which plan rev 6 to write.

(i) What is $G^*$ at IDN unbalanced from `summclust`, and does it sit above, in, or below the MacKinnon (2025) soft-trigger range?
(ii) Does `summclust` itself scale to IDN unbalanced inside the 8 GB / 30 min budget?
(iii) Does `boottest, gridpoints(0)` invert the joint $q$-dim LCA null in one pass at $J = 1500$, or does path D resolve to D-Julia or D-grid?
(iv) Where does `clubSandwich` allocate the OOM-blowing intermediate at TZA?
(v) For the CHN income spec, what base trajectory does `define_switcherpars` (or the data-driven selector at L1511--1524 of `0_programs.do`) return?
(vi) Does reformulation (4)'s 30-fits-per-cell cost dominate any per-fit savings from absorbed mode?

Step 0.5 answers (i) and (ii); Step 0.6 answers (iii); Step 1 answers (iv); the CHN income verification step in path D's preflight answers (v); Step 3 answers (vi).

## What this plan is not

This is a decision plan whose output is which of paths A, B, C, D (in variant onepass, Julia, or grid), F, G becomes the basis for plan rev 6.
The implementation details (Stata wrapper structure, Python bridge, subprocess verification for `WildBootTests.jl`, synthetic coverage MC harness, empirical re-run) are unchanged from the broader F-adjustment work and ride on top of whichever backend the next checks ratify.

This plan does not specify the synthetic coverage MC design, the WCU validation harness, or the published-table layout under the headline-vs-emphasized-WCU branch.
Those land in plan rev 6 once Step 0.5's $G^*$ and Step 0.6's `boottest` outcome come back.

This plan does not relitigate AHZ vs WCB as a primary methodological choice.
The MNW (2023) joint-pair convention treats them as production-plus-validation, and the MacKinnon (2025) soft trigger only shifts emphasis within the same table; it does not collapse the table to a single row.

If `summclust` does not scale AND from-scratch CR3 fails AND all three D variants do not converge, the work parks: the chi-squared-based CIs in the existing pipeline remain the published inference, with the F-adjustment narrative downgraded from "implemented" to "scoped and infeasible at our scale" in the derivation note.
