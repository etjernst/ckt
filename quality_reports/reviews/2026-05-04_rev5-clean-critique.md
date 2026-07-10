# Clean fresh-context critique of plan rev 5

## Best practices context (from STEP A web searches)

Search 1 ("boottest Stata gridpoints multi-parameter joint null inversion confidence interval limitations") surfaced the Roodman et al. (2019) Stata Journal paper and the `boottest.sthlp` source.
The documentation is explicit that `boottest` inverts CIs for restrictions of the form $R\beta = r$ where $R$ is a $1 \times k$ row vector and $r$ is a scalar---i.e., scalar-restriction inversion---while $q > 1$ Wald tests are supported only for p-value computation, not natively for one-pass CI inversion.
This directly contradicts the plan's framing of Step 0.6 as a feasibility check whose default expectation is success; the documented feature set says one-pass joint inversion is not what `boottest` does, so D-onepass should be treated as the unlikely branch, not the headline.
Search 2 ("summclust CR3 jackknife scalability...") confirmed MNW's strong scalability claim ("CV3 in roughly the same time as OLS alone") but did not surface any independent benchmark at $J \approx 30{,}000$ unbalanced with $\bar{n}_j \approx 3$ and $K \approx 27$, leaving the IDN-scale claim untested in published form.

## Summary verdict

Red: 2.
Yellow: 5.
Green: 3.
The plan is structurally sound and the sequencing of Step 0.5 then Step 0.6 before any wall-time commitment is the right move; however, the plan's framing of path D-onepass as the default success branch conflicts with `boottest`'s documented feature set, and the auxiliary OLS at $J \approx 30{,}000$, $\bar{n}_j \approx 3$ with a $q \approx 25$-dim joint null is operating at a regime where neither published `summclust` benchmarks nor `boottest` joint-CI inversion are clearly validated.
REVISE before execution---the two Reds are cheap to address and meaningfully change the cost-comparison table and the decision branch.

## Dimension 1: pre-mortem

It is 2026-08-04 and the plan failed.
Three most likely root causes.
First, Step 0.6 fails because `boottest` does not natively invert a $q$-dim joint null in one pass over scalar $\phi$ (consistent with the documented $1 \times k$ restriction limit), and both fallbacks underperform: D-Julia hits Stata-to-Julia subprocess marshaling friction on Windows that exceeds the 1--2 day budget, and D-grid's $30\times$ cost lands per-cell wall above the 4-hour pass-criterion ceiling.
Second, `summclust` scales to TZA but allocates a per-cluster influence-matrix structure that goes quadratic in $J$ at IDN unbalanced (the MNW scalability claim is for fixed cluster size growth, not for $J$ growth at fixed small $\bar{n}_j$), pushing peak memory above 8 GB and triggering a from-scratch CR3 fallback whose 1-day budget then expands as the AHZ df recompute per grid point becomes the bottleneck.
Third, reformulation (4)'s 30-fits-per-cell cost (each requiring a fresh $H_{jj}(\phi)$ rebuild) dominates any per-fit savings; the cost-comparison table's "30 $\times$ per-fit" reads as additive but the per-fit wall is itself $\phi$-dependent through the leverage matrices, and cumulative wall under-estimates by a factor of 1.5--3.

[Red] [boottest one-pass joint inversion is not the documented feature] -- Plan lines 18--20, 142--144, 207, 233--239 frame D-onepass as a feasible default. `boottest` documentation specifies CI inversion for $R\beta = r$ with $R$ a $1 \times k$ row vector; multi-parameter ($q > 1$) tests use the Wald statistic but the native inversion machinery is for scalar restrictions. The "varlist-zero on a per-$\phi$ recoded design" framing in Step 0.6 (line 234) does not collapse to a scalar restriction---it collapses to a $q$-dim joint zero, exactly the case `boottest` treats as Wald rather than as invertible. -> Reframe Step 0.6's expected outcome: D-onepass is the optimistic branch (verify, do not assume); D-Julia (`WildBootTests.jl`) is the modal expected outcome; D-grid is the conservative fallback. Update the cost-comparison table's "Anchor" column for D-onepass from "published method (conditional on Step 0.6 pass)" to "published method (Step 0.6 verification, low prior)." Re-budget the 60-cell wall accordingly: assume D-Julia cost in the joint G+D pair until Step 0.6 returns.

[Red] [summclust scalability claim is unvalidated at IDN regime] -- Plan lines 162--172, 211, 224--227 treat `summclust` as the production headline at IDN unbalanced with no published benchmark at $J \approx 30{,}000$, $\bar{n}_j \approx 3$, $K \approx 27$. MNW's scalability framing is for "datasets with large clusters" (i.e., large $\bar{n}_j$); IDN unbalanced is the opposite regime---many small clusters---where the per-cluster jackknife refit overhead can dominate. The 8 GB / 30 min budget at line 170 is a stop rule, not a scaling argument; if `summclust` blows it, the from-scratch CR3 prototype's 1-day budget at line 172 collapses into the critical path. -> Before Step 0.5 runs at IDN, run `summclust` on a $J = 5000$, $J = 10000$, $J = 20000$ subsample sequence of IDN unbalanced with the recoded covs_trend design and fit a scaling curve. If the curve extrapolates above 30 min at $J = 30000$, activate the from-scratch CR3 prototype in parallel with Step 0.5 rather than after, so the 1-day from-scratch budget runs concurrent with the path-G probe rather than serial.

## Dimension 2: completeness

A domain expert would expect three things the plan does not provide.
First, no synthetic Monte Carlo coverage simulation is committed within rev 5 scope (line 273 carries this with a 4-hour budget but explicitly punts to plan rev 4 if scope tightens); for a paper reporting a confidence interval for $\phi$ inverted from a multi-parameter Wald test, coverage validation at the empirical $J/q$ ratio and cluster-size distribution is not optional.
Second, no plan for handling weak-identification of $\phi$ at the inversion stage; the search-1 source flags that under weak ID, `boottest`'s inverted CI can be disjoint, and the plan does not say what happens if the inverted set has multiple components.
Third, no specification of how the AHZ Satterthwaite df handles the recoded design's near-collinearity with trajectory FE at small $\phi_0$; line 113 asserts non-collinearity at $\phi_0 \ne 0$ but the grid includes points near zero where the design becomes ill-conditioned.

[Yellow] [No coverage MC inside rev 5 scope] -- Lines 273--274 carry the synthetic coverage MC with a contingent 4-hour budget that may slip to plan rev 4. -> Pin the MC inside rev 5: 1000 reps at $J/q$ ratio matched to TZA covs_trend; 4 h budget is realistic for `summclust` but not for `boottest` at $B = 9999$, so cap at $B = 999$ for the MC and document the variance-of-variance penalty.

[Yellow] [Disjoint CI handling for inverted $\phi$ set] -- Plan does not address what happens if the inverted CI for $\phi$ has multiple disjoint segments, a documented `boottest` failure mode under weak ID. -> Add a one-line decision rule: if the inverted set has $> 1$ segment at the published $\alpha = 0.05$ level, report the convex hull plus a footnote, and run a sensitivity at $\alpha = 0.10$.

[Yellow] [Recoded-design conditioning at small $\phi_0$] -- Line 113 is a one-line assertion; needs a numerical conditioning check (condition number of $X'X$ across the grid). -> Add a 5-min conditioning sweep to Step 0.6.

## Dimension 3: feasibility

`WildBootTests.jl` from Stata on Windows is the main external dependency.
The plan's 1--2 day budget for D-Julia (line 147) acknowledges Windows-side marshaling friction but does not specify what passes the design matrix, weight type, and seed across the boundary, nor whether the user has Julia + `WildBootTests.jl` already installed and version-pinned.
This is a foreseeable blocker.

[Yellow] [`WildBootTests.jl` install and version not confirmed] -- Plan assumes the Julia subprocess works as a fallback (lines 146--147, 208) but does not include an install-and-smoke step. -> Add a 30-min preflight: install `WildBootTests.jl`, run the package's own minimal example end-to-end, log version. Promote D-Julia to "verified available" only after preflight.

## Dimension 4: best-practice alignment

Alignment with MNW (2023) and MacKinnon (2025) is genuinely strong: reporting both CV3 and CV3J side-by-side (line 166), the soft trigger keyed to $G^* \in [6, 10]$ rather than a hard kill rule (lines 14--16, 229--231), and the WCU31 weighttype pin (line 25) are all current-literature defensible choices.
The Pustejovsky-Tipton 2023 corrigendum acknowledgment (lines 56--58) is exactly right.
Two best-practice gaps remain.
First, the plan does not cite Hansen (2025) calculated-df as production candidate, only as appendix-on-request (lines 191--195); given the plan's own framing of $G^*$ concern at IDN, the calculated-df row earns more than appendix status.
Second, no mention of the more recent (2024--2025) literature on score bootstrap or empirical-likelihood CIs for $\phi$ in CRC settings, which is the natural Hausman-style validation row.

[Yellow] [Hansen (2025) calculated df relegated to appendix] -- Lines 191--195 commit to running it only on referee request. -> Move Hansen (2025) calculated df to a third row in the published table when $G^*$ is at or below the soft trigger; cost is negligible (closed-form post-`summclust`).

[Green] [Score bootstrap / EL alternatives not scanned] -- Path F's literature scan (lines 245--247) lists two specific candidates but does not include the score-bootstrap or EL families. -> Add one bullet to F.0 covering Davidson-MacKinnon score bootstrap and Bertanha-Moreira-style EL CIs.

## Dimension 5: sequencing

The Step 0.5 then Step 0.6 ordering is correct.
One hidden blocker: Step 1 (clubSandwich OOM reproduction, lines 240--243) is sequenced after Step 0.5 but answers question (iv) (line 303) which conditionally affects whether path B is even worth probing in Step 3.
Reordering Step 1 to run in parallel with Step 0.5 (both are I/O- and memory-bound, not CPU-bound, so they fit alongside each other on one workstation) costs nothing and lets the Step-3 paths-A-and-B probe drop straight if Step 1 confirms a deep allocation defect.

[Yellow] [Step 1 should run in parallel with Step 0.5] -- Lines 222--243 sequence Step 1 strictly after Step 0.5; nothing in Step 1's profiling depends on Step 0.5's `summclust` output. -> Parallelize: launch Step 1 instrumented run alongside Step 0.5; time savings 1--2 h, opportunity cost zero.

[Green] [Step 0.6 cross-check at $\hat\phi_{\text{point}}$] -- Lines 234--236 pin a sensible cross-check. Already correctly sequenced.

## Dimension 6: specificity

A first-implementer could execute most of the plan, but three steps need pinning.
The Step 0.5 invocation (line 225) hand-waves "the equivalent `summclust` invocation"---`summclust` does not accept varlist-zero contrasts directly the same way `test` does, so the exact syntax for testing the recoded $z$'s jointly is not obvious from the do-files alone.
The Step 0.6 success criterion (lines 235--237) part (b) requires "a separately-computed $q$-dim joint Wald" but does not say which estimator's variance matrix to use---if it is `summclust`'s CV3J, that ties Step 0.6 to Step 0.5 success; if it is the unadjusted Stata `, cluster(pid)`, that conflates two adjustments.
The "AHZ df recompute" (line 85, 172) is asserted as the dominant cost but the plan does not give an algorithmic statement; a referee or coauthor reading the rev 6 derivation note will need pseudocode.

[Yellow] [`summclust` joint-zero invocation syntax] -- Line 225 is too vague for first-implementer execution. -> Pin the exact syntax: most likely `summclust ..., cluster(pid) sample(z_2 z_3 ... z_J_R)` or post-`reg_sandwich` testing via `test_sandwich`; verify against `summclust.sthlp` and pin in the plan before Step 0.5.

[Yellow] [Step 0.6 cross-check variance matrix unspecified] -- Line 235 says "separately-computed $q$-dim joint Wald" without naming the variance matrix. -> Specify: cross-check uses `summclust, vce(jackknife)` covariance, since that is the variance the published joint pair will use; this also forces Step 0.5 to complete (or fail visibly) before Step 0.6 runs the cross-check, which is the right ordering anyway.

[Green] [Recoded-design construction is well-specified] -- Lines 89--113 give first-implementer-level rules with explicit fallbacks per country/spec.

[Green] [Pass criteria are quantitative and falsifiable] -- Lines 262--272 give six pass conditions with numeric thresholds.

## Top recommendations

1. Reframe path D-onepass as the optimistic branch with low prior, not the cost-table headline. Update lines 142--150, 207, and 280--291 of the decision branch so D-Julia is the modal expected D variant. The `boottest` documentation does not support one-pass inversion of a $q$-dim joint null over scalar nuisance; this is the single most consequential change to the plan.
2. Run a small-$J$ scaling sweep of `summclust` on IDN unbalanced ($J = 5000, 10000, 20000$) before committing to it as production headline. If the curve extrapolates above the 30-min stop at $J = 30000$, launch the from-scratch CR3 prototype in parallel rather than serial.
3. Pin the synthetic coverage MC inside rev 5 scope at $B = 999$ (not $B = 9999$) and 1000 reps, with the variance-of-variance penalty documented; do not let it slip to rev 4.
4. Add a 30-min `WildBootTests.jl` install-and-smoke preflight before declaring D-Julia an available fallback.
5. Run Step 1 (clubSandwich OOM reproduction) in parallel with Step 0.5 to free Step 3.
6. Pin the exact `summclust` invocation for joint-zero testing on the recoded design and the variance matrix used in Step 0.6's cross-check before kickoff.
7. Promote Hansen (2025) calculated df from appendix-on-request to a third published-table row when $G^*$ is at or below the soft trigger; the cost is closed-form post-`summclust`.

Sources:
- [Fast and wild: Bootstrap inference in Stata using boottest (Roodman et al. 2019)](https://journals.sagepub.com/doi/10.1177/1536867X19830877)
- [boottest.sthlp on droodman/boottest](https://github.com/droodman/boottest/blob/master/boottest.sthlp)
- [Leverage, influence, and the jackknife in clustered regression models: summclust (MacKinnon, Nielsen, Webb 2023)](https://journals.sagepub.com/doi/10.1177/1536867X231212433)
- [arXiv:2205.03288 (summclust paper preprint)](https://arxiv.org/html/2205.03288)
