# Six-dimension critique of plan rev 4

Date: 2026-05-02
Target: [`quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev4.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev4.md)
Mode: fresh-eyes critique against the rev 3 critique's four Reds plus a 2026 literature scan that surfaces issues not visible in rev 3.

## Summary verdict

Red: 2.
Yellow: 5.
Green: 6.

Rev 4 closes three of the four rev 3 Reds cleanly: path G is re-scoped to `summclust` as the implementation (not the anchor), `summclust` is promoted to Step 0.5 ahead of backend selection, and paths G and D are reframed as the MNW joint production-plus-validation pair.
Two new Reds emerge from rev 4's own choices: the $G^* \ge 30$ kill threshold is fabricated (MNW give no such cutoff; published empirical examples flag concern at $G^* \approx 6$--$8$), and path D's "WCU inverts in one pass via `boottest, gridpoints(0)`" claim conflates scalar-null inversion (what `boottest` natively supports) with the multi-parameter joint-restriction inversion over scalar $\phi$ that the LCA contrast actually requires.
The kill rule plus the path-D over-claim creates a routing failure mode: a typical empirical $G^*$ of 6--8 fires the kill rule, the plan collapses to path D, and path D may not implement what rev 4 advertises.
These are load-bearing and need fixing in rev 5; the other findings are tunable.

## Dimension 1: pre-mortem

If rev 4 fails by August 2026, three new failure modes (introduced by rev 4 itself) dominate.
First, Step 0.5 returns $G^* = 7$ at IDN unbalanced---a typical empirical value, well below MNW's 6--8 concern thresholds---the kill rule fires, the team commits to path D, and then discovers `boottest`'s native one-pass inversion (`gridpoints(0)`) is documented for scalar nulls $R\beta = r$ with $1 \times k$ row-vector $R$, not for the $q \approx 25$-dimensional joint LCA restriction over scalar nuisance $\phi$.
The 30$\times$ cost reduction reverses; the team is back to WCR-style grid-point bootstrapping at 5--15 min/cell or has to switch to `WildBootTests.jl` mid-stream.
Second, the team ratifies $G^* = 32$ at IDN as "above the bar" on the strength of rev 4's invented $\ge 30$ rule, ships CR3 as headline, and a referee citing MacKinnon (2025) flags that $G^* = 32$ on $G = 30{,}000$ clusters is far below the implied effective fraction MNW treat as comfortable.
Third, rev 4 designates `vce(jackknife)` (CV3J) as headline and `vce(jackknife, mse)` (CV3) as cross-check (line 166); MNW (2023) recommend computing both and reporting agreement, not picking one as headline---so the team discovers at submission that the conventional report is dual-CV3-and-CV3J, not CV3J-with-CV3-as-cross-check.

[Red] [Path D's WCU one-pass inversion is over-claimed for multi-parameter joint restrictions] -- Lines 22--24, 142--148, and the cost-comparison table row D treat `boottest, gridpoints(0)` as inverting the LCA test in a single bootstrap pass, but the LCA contrast is $q = J_R - 1 \approx 25$-dimensional joint over scalar nuisance $\phi$, and `boottest`'s native inversion (per Roodman et al. 2019 and the `boottest` manual) supports scalar nulls.
Multi-parameter joint inversion over a scalar nuisance is a different operation; it is supported in `WildBootTests.jl` but not obviously in Stata `boottest`'s `gridpoints(0)` path.
If the plan is wrong here, path D's per-cell cost is back to WCR territory and the joint G+D-pair budget breaks.
-> Verify via a 30-minute test on `boottest` with the recoded varlist-zero null at small $J$ before relying on the one-pass cost; if `boottest` does not support multi-parameter native inversion, path D becomes "WCU via `WildBootTests.jl`" or "WCR with grid-point re-bootstrapping at $\sim 30\times$ cost." Update the cost-comparison table accordingly.

[Red] [The $G^* \ge 30$ kill threshold is invented] -- Lines 15, 219, 253, 270, and 287 treat $G^* < 30$ as the threshold below which AHZ inference is meaningless and only path D survives, but MNW (2023) give no such numerical cutoff; MacKinnon's published empirical examples report $G^* = 5.98$ and $G^* = 8.49$ as concerning levels, and the MacKinnon (2025) SOTA review at https://arxiv.org/html/2604.02000v1 frames $G^*$ relative to nominal $G$ (the cluster count) and as a soft trigger for CV3J + WCB rather than a hard kill rule.
Rev 4's kill rule will fire on most empirical applications and is not defensible against a referee citing the literature.
-> Replace the $G^* \ge 30$ rule with a soft trigger: "if $G^*$ is small relative to $G$ or absolutely below the MNW empirical-concern range ($\sim 6$--$10$), report both CR3 and WCU with extra emphasis on WCU; otherwise report CR3 + WCU as the standard joint pair." Tie any specific number to a citation.

[Yellow] [Headline-vs-cross-check framing of CV3 vs CV3J does not match MNW recommendation] -- Line 166: rev 4 names `vce(jackknife)` as headline and `vce(jackknife, mse)` as cross-check, but MNW (2023) recommend computing both CV3 and CV3J and reporting both.
The "headline + cross-check" framing implicitly demotes one to a robustness row.
-> Reframe as "report both CV3 and CV3J per MNW recommendation; flag any disagreement."

## Dimension 2: completeness

Rev 4 covers the leverage-diagnostic-first ordering, the joint G+D pair, recoded-design construction, the AHZ df contingency, and the falsifiable cost table.
What a 2026 domain expert with the literature scan in hand would still expect: a citation to MacKinnon (2025) as the SOTA reference replacing or supplementing MNW (2023); a defensible $G^*$ trigger keyed to MNW's published empirical thresholds rather than an invented round number; explicit specification of which WCU variant (WCU13, WCU31, WCU33) is being run via `boottest` since they differ in test-statistic construction; an explicit verification step for `boottest` multi-parameter inversion before the joint G+D budget is committed; and the dual CV3/CV3J reporting convention in place of headline + cross-check.

[Red] [MacKinnon (2025) "When Can We Trust Cluster-Robust Inference?" not cited] -- Rev 4 cites MNW (2023) and PT (2018 + 2023 corrigendum) but not the 2025 review at https://arxiv.org/html/2604.02000v1, which is the current SOTA and directly addresses the diagnostic-then-backend ordering rev 4 codifies.
A referee will ask why this isn't cited.
-> Read the paper, cite it in the plan and in the eventual paper, and use its $G^*$ guidance to replace the invented $\ge 30$ rule. (Promoted to Yellow on reflection: the absence is fixable in rev 5 without re-architecting the plan, so it does not block APPROVE on its own; it does, however, compound the kill-threshold Red.) Reclassified below as Yellow.

[Yellow] [MacKinnon (2025) SOTA reference not cited] -- See above.
-> Cite in rev 5 and use its guidance to replace the $\ge 30$ threshold.

[Yellow] [WCU variant unspecified] -- Lines 22, 142, 144 say "WCU" without distinguishing WCU13, WCU31, WCU33.
The variants differ in how the test statistic is built and have different small-$G$ properties.
-> Pin the variant (likely WCU31 or WCU33 per recent recommendations) and note the choice in the plan.

[Yellow] [No verification step for `boottest` multi-parameter inversion] -- The plan does not budget a small-scale test of whether `boottest, gridpoints(0)` actually inverts the multi-parameter LCA varlist-zero contrast over $\phi$ in one pass.
This verification is the difference between a 30-min/cell wall and a 5--15 min/cell wall (a $30\times$ swing in either direction).
-> Add to Step 0.5 (or as a Step 0.6): a 15-minute `boottest` smoke test on the TZA $J = 1500$ recoded design at $\phi_0 = \hat\phi$ that confirms `gridpoints(0)` returns a CI for $\phi$ from a single bootstrap pass on the joint $q$-dim null.

[Green] [Step 0.5 promoted ahead of backend selection] -- Lines 14--16 and 214--221 implement the rev 3 critique's R3 cleanly: `summclust` runs first, the kill rule short-circuits the rest of the empirical block.
The architecture is right; only the threshold value is wrong.

[Green] [Path G re-scoped to `summclust` implementation, not anchor] -- Lines 17--21, 162--170 close rev 3's R1: `summclust, vce(jackknife)` / `vce(jackknife, mse)` is the production CR3 implementation, with from-scratch CR3 demoted to a fallback contingent on `summclust` not scaling.

[Green] [Joint G+D pair reframing] -- Lines 26--29 close rev 3's R4: the published table reports CR3 + AHZ as headline and WCU as validation, the conventional MNW joint pair.

[Green] [Empirical AHZ df contingency preserved] -- Pass criterion (v) at lines 251--253 carries forward from rev 3.

## Dimension 3: feasibility

The feasibility hinge is whether `boottest` natively supports multi-parameter joint inversion over a scalar nuisance.
If yes, rev 4's per-cell cost arithmetic for path D is right and the joint G+D pair fits in a working day's wall budget.
If no, path D's cost is roughly $30\times$ what rev 4 estimates, and the kill-rule pathway (Step 0.5 returns sub-30 $G^*$, plan collapses to path D) routes us into a corner.
The feasibility risk is asymmetric: under the kill rule, rev 4 is committed to a path that may not implement in one pass.
The other feasibility carryovers from rev 3 (`tracemalloc` availability, path-F null handling, `summclust` scaling at IDN) are addressed.

[Red] [Path D's one-pass inversion may not be feasible for multi-parameter joint nulls] -- See dimension 1, Red 1.
If `boottest, gridpoints(0)` only natively inverts scalar nulls, the entire rev 4 cost arithmetic for path D is wrong.
-> Add a `boottest` smoke test in Step 0.5 (or 0.6) before relying on the one-pass cost; if it fails, the fallback is `WildBootTests.jl` (Julia) or WCR-style 30-grid re-bootstrapping in Stata, and the cost-comparison table needs revision.
Promoted to Red because under the rev 4 kill rule this is the load-bearing failure mode.

[Yellow] [`summclust` IDN scaling still unverified] -- Step 0.5 scopes the `summclust` IDN profile but the plan does not commit a small-scale time/memory budget for what happens if `summclust` itself OOMs at $J \approx 30{,}000$.
The plan says the from-scratch CR3 fallback activates, but the wall and memory budgets for that fallback are not pinned.
-> Add a Step 0.5b contingency: if `summclust` exceeds 8 GB or 30 minutes at IDN, log peak memory and the dominant `summclust` operation, then activate from-scratch CR3 with a 1-day budget.

[Green] [Path-F null handling now defined] -- Step 4 at lines 236--241 specifies the routing under all combinations of (A or B passes, F.0 finds candidate, `summclust` scales). This closes rev 3's Yellow.

## Dimension 4: best-practice alignment

Rev 4 aligns with three of the four 2026 best-practice items the rev 3 critique flagged: `summclust`-first ordering (Step 0.5), CR3-via-`summclust` rather than from-scratch as the default, and CR3 + WCU as the joint pair.
What rev 4 misses against the 2026 literature scan: a defensible $G^*$ threshold tied to MNW's published empirical concern levels rather than an invented round number; the dual-CV3-and-CV3J reporting convention in place of headline + cross-check; the WCU variant pin (WCU13/WCU31/WCU33); and the verification that `boottest`'s native inversion supports the multi-parameter LCA joint over scalar $\phi$.
The PT 2018 corrigendum applicability and the Davidson-MacKinnon recoded-design precedent are still correctly invoked (lines 58--60, 82).

[Yellow] [$G^* \ge 30$ threshold misaligned with MNW empirical concern levels] -- See dimension 1 Red 2.
The literature concern range is $\sim 6$--$10$ in published examples; rev 4's $\ge 30$ rule is off by a factor of 3--5.
-> Replace with a soft trigger keyed to citations.
(Counted under dimension 1 Red; this dimension's finding is the alignment-side framing of the same issue.)

[Yellow] [Dual CV3/CV3J reporting convention not matched] -- See dimension 1 Yellow on headline-vs-cross-check.

[Green] [`summclust`-first ordering matches 2026 convention] -- Step 0.5 is right.

[Green] [CR3-via-`summclust` matches 2026 convention] -- Path G is right.

[Green] [CR3 + WCU joint pair matches MNW (2023)] -- Lines 26--29.

## Dimension 5: sequencing

Step 0.5 first is right and closes the rev 3 sequencing Red.
What rev 4's sequencing introduces as a new risk: a typical empirical $G^*$ of 6--8 fires the kill rule, the plan collapses to path D, and path D's one-pass inversion may not be feasible for multi-parameter joint nulls---creating a corner where Steps 1--4 are skipped on the strength of an invented threshold and the surviving path is also misspecified.
The fix is sequencing-level: insert a `boottest` smoke test (Step 0.6, ~15 min) before the kill rule routes to path D, so the routing decision is informed by whether path D actually implements what rev 4 claims.

[Red] [Kill rule plus path-D over-claim creates a routing corner] -- See dimensions 1 and 3.
At a typical empirical $G^* \approx 7$, rev 4 routes to path D as the sole survivor and budgets it as a one-pass cost; if `boottest`'s native inversion doesn't cover the multi-parameter case, the plan has no fallback within the kill-rule branch.
-> Sequence fix: Step 0.5 reports $G^*$ but does NOT immediately collapse Steps 1--4; Step 0.6 (15 min) verifies `boottest` inversion behavior on the recoded design; only after both diagnostics does the plan branch.
Counted under dimension 1 and 3 Reds; this is the sequencing-level statement.

[Green] [Step 0.5-first ordering closes rev 3's R3] -- Lines 14--16, 214--221.

[Green] [IDN-first ordering preserved within the empirical block] -- Step 3 leads with IDN.

[Green] [Step 4 conditional logic now reflects Step 0.5 outcomes] -- Lines 236--241.

## Dimension 6: specificity

Rev 4 is specific where it can afford to be: path G's `summclust` invocation with `vce(jackknife)` / `vce(jackknife, mse)`, path D's $B = 9999$ and Rademacher weights and root-finder tolerance, recoded-design construction with base trajectories per country, singleton handling, controls/FE choice.
The two specificity gaps that drive the Reds: the $G^* \ge 30$ rule is concrete but unsupported (worse than under-specified---confidently wrong), and path D's "WCU inverts in one pass via `boottest, gridpoints(0)`" is concrete but may not implement what rev 4 needs.
The WCU variant (WCU13/WCU31/WCU33) is left unspecified.
The CHN income base trajectory is "TBD, default to $\underline{d}_0 = 2$ pending verification" (line 96)---a known under-specification but minor.

[Yellow] [WCU variant unspecified] -- See dimension 2.

[Yellow] [CHN income base trajectory still TBD] -- Line 96.
Minor; flagged for completeness.
-> Verify before path D runs on CHN income spec.

[Green] [Path G specification is first-implementer ready] -- Lines 162--170.

[Green] [Recoded-design construction is first-implementer ready] -- Lines 90--114.

[Green] [Cost-comparison table is falsifiable] -- Lines 194--201.
The numbers may be wrong (see Reds) but the structure is right and reviewers can falsify.

## Top recommendations for rev 5 (or APPROVE)

Rev 4 is not yet APPROVE-ready; two Reds are load-bearing.
Both are tightly scoped; rev 5 can be a focused patch rather than a full re-architecture.

1. Replace the $G^* \ge 30$ kill threshold with a soft trigger keyed to MNW (2023) and MacKinnon (2025) empirical concern levels (around $G^* \in [6, 10]$).
Below the soft trigger, emphasize WCU and report CR3 with caveat; do not drop CR3 entirely.
The $\ge 30$ rule should not survive review.

2. Add Step 0.6 (15--30 min): a `boottest, gridpoints(0)` smoke test on the TZA $J = 1500$ recoded varlist-zero null at $\phi_0 = \hat\phi$ to verify that one-pass inversion over scalar $\phi$ is feasible for the $q$-dimensional joint restriction.
If it is not, rev 5 specifies path D as either `WildBootTests.jl` or WCR-with-grid-point re-bootstrapping and updates the cost-comparison table; the joint G+D pair's wall budget needs revision.

3. Cite MacKinnon (2025) SOTA review at https://arxiv.org/html/2604.02000v1 and use its guidance for the $G^*$ trigger.

4. Reframe `vce(jackknife)` and `vce(jackknife, mse)` as both reported (CV3 and CV3J) per MNW (2023), not as headline + cross-check.

5. Pin the WCU variant (WCU13, WCU31, or WCU33) in path D's specification.

6. Resolve the CHN income base trajectory before path D runs on the CHN income spec.

If items 1 and 2 land cleanly with the smoke-test result, rev 5 is APPROVE-ready and the empirical block can run.
