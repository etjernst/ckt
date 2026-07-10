# Six-dimension critique of plan rev 5

Date: 2026-05-04
Target: [`quality_reports/plans/2026-05-04-backend-choice-for-f-adjustment-rev5.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-04-backend-choice-for-f-adjustment-rev5.md)
Predecessor critique: [`2026-05-02_rev4-six-dimension-critique.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev4-six-dimension-critique.md) (2 Red, 5 Yellow, 6 Green).
Mode: fresh-eyes critique against rev 4 critique's two Reds plus a 2026 literature scan.

## Best practices context (from STEP A web searches)

WildBootTests.jl documentation explicitly advertises "wild cluster bootstrap tests of multiple joint hypotheses" and "arbitrary and multiple linear hypotheses in the parameters," with CIs formed by inverting the test and iteratively searching for bounds---this validates rev 5's path D-Julia fallback as a real off-the-shelf option for the $q$-dimensional joint LCA null.
The Roodman et al. (2019) Stata Journal article describing `boottest` represents nulls in the form $R\beta = r$ with $R$ a vector, which corroborates rev 4's concern (carried into rev 5 Step 0.6) that Stata `boottest, gridpoints(0)` may not handle the multi-parameter case natively.
MacKinnon's 2025 Canada Stata Meeting slides ("When Can We Trust Cluster-Robust Inference?") and MNW (2023) treat CV3 and CV3J as "often indistinguishable" except when cluster counts are small and sizes vary greatly, and frame small $G^*$ as a soft red flag routing to CV3 + WCB rather than a numerical kill threshold---rev 5's $G^* \in [6, 10]$ soft trigger and dual CV3/CV3J reporting both align.
Hansen (2025) recommends a calculated df parameter in place of $G - 1$, which is consistent with rev 5's HTZ Satterthwaite approach.

## Summary verdict

Red: 0.
Yellow: 3.
Green: 9.

Rev 5 closes both rev 4 Reds cleanly and folds in all five actionable Yellows.
APPROVE: rev 5 is ready to act on; the three remaining Yellows are tuning-grade and can be resolved during execution rather than blocking another revision round.

## Dimension 1: pre-mortem

If rev 5 fails by August 2026, the failure modes have shifted from rev 4's load-bearing routing corner (kill rule plus over-claimed path D) to softer execution risks.
The most plausible failure: Step 0.6 returns ambiguous output---`boottest, gridpoints(0)` accepts the multi-parameter syntax without erroring but silently treats it as a per-coefficient inversion and returns a non-joint CI---and the team does not catch the silent miscoding because the Step 0.6 success criterion (lines 229--230) requires only "finite endpoints and no convergence warnings."
A second plausible failure: `WildBootTests.jl` subprocess wrapping (path D-Julia) consumes more than the 1-day budget at line 147 once Stata-to-Julia data marshaling is properly engineered for $J \approx 30{,}000$ clusters and $K \approx 27$ regressors, since Julia subprocess startup, dependency precompilation, and serialized matrix handoff are non-trivial in a Windows + Stata environment.
A third plausible failure: the synthetic coverage MC at line 267 lands at 4-hour budget but the empirical $J/q$ ratio MC requires more than 1000 replications to distinguish CR3 + AHZ from WCU coverage at the soft-trigger boundary, and rev 5 punts the design specification to "broader pipeline plan rev 4."
None of these are load-bearing in the rev 4 sense; they are tunable.

[Yellow] [Step 0.6 success criterion does not catch silent per-coefficient inversion] -- Lines 229--230 say success is "finite endpoints and no convergence warnings"; the failure mode "boottest accepts but treats the test as a per-coefficient scalar inversion and returns a non-joint CI" is named in line 230 as a failure mode but the success criterion does not include a positive check (e.g., comparing the returned CI against an independently computed scalar-null inversion to confirm they differ in the expected direction).
-> Strengthen Step 0.6 success criterion: in addition to finite endpoints, require either (a) inspection of `boottest`'s returned `e()` matrix for a $q$-dimensional null specification, or (b) a sanity check that the joint CI differs from a per-coefficient scalar CI on one of the recoded $z$'s.
This is a 5-minute add to Step 0.6, not a re-architecture.

[Yellow] [path D-Julia subprocess overhead under-scoped] -- Line 147 budgets "1 day for the subprocess wrapper plus per-cell wall comparable to a single bootstrap pass" and line 202 echoes "$<$ 30 min + subprocess overhead" in the cost table.
On Windows with Stata as the parent process, the subprocess wrapper has to handle Julia install verification, package precompile, data marshaling for $J \approx 30{,}000$ clusters and $N \approx 90{,}000$ rows, and result deserialization.
A 1-day budget is plausible but tight; if it slips, the cost table's per-cell wall for D-Julia is also stale.
-> Either widen the D-Julia wrapper budget to 1--2 days with an explicit "if subprocess marshaling exceeds 2 days, route to D-grid" trigger, or add a Step 0.6b that times a single Julia subprocess round-trip on a toy problem before committing the wrapper budget.

[Green] [Both rev 4 Reds closed] -- Line 18--20 (Step 0.6 inserted, path D fallbacks named) and lines 15, 222--225 (soft trigger replacing kill rule, CR3 stays in scope below trigger) directly address rev 4's two Reds.

## Dimension 2: completeness

Rev 5 covers everything rev 4 was missing per the rev 4 critique: MacKinnon (2025) cited at lines 15 and 144 with the soft trigger keyed to its empirical concern range, dual CV3/CV3J reporting at lines 24 and 162--167, WCU31 variant pinned at lines 25 and 143--144, `summclust` IDN budget at lines 26 and 169--170, CHN income base trajectory verification at lines 27 and 95.
A 2026 reviewer with the literature scan in hand would still want one item rev 5 does not address: the MacKinnon (2025) recommendation that small $G^*$ may also warrant reporting Hansen (2025)-style calculated df, which goes beyond rev 5's "AHZ Satterthwaite df with empirical contingency" but is adjacent enough that a referee could ask.
This is genuinely scope creep; rev 5 is not obligated to add it.

[Yellow] [Hansen (2025) calculated-df alternative not mentioned] -- The MacKinnon (2025) review notes Hansen (2025a, b) recommend a calculated df parameter $d_i$ in place of $G - 1$ for small effective clusters; rev 5 commits to AHZ Satterthwaite throughout (lines 49--64) without flagging Hansen as an alternative referee path.
-> Optional: in the "Referee Q&A" section, add a one-line "Why AHZ Satterthwaite not Hansen calculated df?" entry.
Not blocking; this is a hedge against a specific referee, not a methodological requirement.

[Green] [MacKinnon (2025) cited and used to anchor the soft trigger] -- Lines 15, 144, 222--224.

[Green] [Dual CV3/CV3J reporting per MNW (2023) convention] -- Lines 24, 162--167.

[Green] [WCU31 variant pinned with citation] -- Lines 25, 143--144.

[Green] [CHN income base trajectory verification sequenced] -- Lines 27, 95.

[Green] [`summclust` IDN scaling budget pinned] -- Lines 26, 169--170, 220--221.

## Dimension 3: feasibility

The feasibility risk that drove rev 4's Reds (path D one-pass inversion may not implement the multi-parameter joint case) is now addressed by Step 0.6 as an explicit verification gate before the joint G+D budget is committed.
The web search confirms `WildBootTests.jl` natively supports multi-parameter joint nulls, so the D-Julia fallback is a real off-the-shelf option, not a hopeful gesture.
The remaining feasibility hinges are all named: `summclust` IDN scaling, `boottest` multi-parameter behavior, R or Python `tracemalloc` profiler availability for Step 1.
The Yellow under dimension 1 (D-Julia subprocess overhead) is the only feasibility risk not already pinned to a budget.

[Yellow] [`tracemalloc`/`tracemem()` availability not verified ahead of Step 1] -- Line 235 says "Verify the profiler is available before committing the budget; flag if the R or Python environment requires a reinstall."
This is correctly flagged but not actually scheduled as a separate verification; under a strict reading, Step 1 itself does the verification, and a reinstall mid-step blows the 1--2 hour budget.
-> Minor: add a 5-minute pre-Step-1 environment check, or accept the risk as scoped.
Not blocking.

[Green] [Step 0.6 verifies path D feasibility before joint budget commit] -- Lines 19--21, 227--231.

[Green] [`summclust` IDN scaling has named fallback with budget] -- Lines 169--170, 220--221.

[Green] [Path-F null handling carried forward from rev 4] -- Lines 246--251.

## Dimension 4: best-practice alignment

Rev 5 aligns with the 2026 literature scan on every dimension the rev 4 critique flagged: MacKinnon (2025) cited and used as the soft-trigger anchor, dual CV3/CV3J per MNW (2023), WCU31 pinned with citation, `summclust` as the production CR3 path, recoded-design construction following Davidson-MacKinnon precedent.
The web search corroborates the soft-trigger framing (MacKinnon's Canada 2025 slides and the MNW 2023 paper both treat $G^*$ as a soft red flag for routing to CV3 + WCB) and ratifies path D-Julia (`WildBootTests.jl` documentation explicitly supports multi-parameter joint nulls).
No new misalignments surface.

[Green] [Soft trigger replaces invented kill rule, anchored to MacKinnon (2025)] -- Lines 15, 222--225, 263--264.

[Green] [Dual CV3/CV3J convention matches MNW (2023)] -- Lines 24, 162--167.

[Green] [WCU31 choice cites MacKinnon (2025)] -- Lines 25, 144.

[Green] [`summclust`-first ordering retained] -- Lines 218--225.

## Dimension 5: sequencing

The rev 4 sequencing Red (kill rule routes to a path that may not implement what it claims) is closed: Step 0.5 reports $G^*$ as a soft routing signal, Steps 1--4 still run, and Step 0.6 verifies path D feasibility before the joint G+D wall budget is committed.
The new sequencing question is whether Step 0.6 should run in parallel with or after Step 0.5; rev 5's order has Step 0.5 first (30--60 min), then Step 0.6 (15--30 min), which is correct because Step 0.5's $G^*$ output informs whether path D needs to be the headline (below soft trigger) or the validation row (above), and that framing affects how Step 0.6's failure mode is scored.
The conditional Step 4 logic at lines 246--251 covers all four combinations of Step 0.5 outcomes (`summclust` scales / does not, F.0 finds candidate / does not) and reads as first-implementer-ready.

[Green] [Step 0.5 then 0.6 ordering is correct] -- Lines 218--231.

[Green] [Steps 1--4 not short-circuited by Step 0.5 outcome] -- Lines 222--225 explicitly state "soft routing signal, not a kill rule, and Steps 1--4 still run."

[Green] [Decision branch at lines 269--287 covers all relevant Step 0.5 + Step 0.6 outcome combinations] -- Lines 273--284.

## Dimension 6: specificity

Rev 5 is first-implementer-ready on the dimensions that matter for kicking off Steps 0.5 and 0.6: `summclust` invocation, recoded-design construction, base trajectory per country with the CHN income contingency named, singleton handling, controls/FE choice, WCU31 variant, $B = 9999$ production / $B = 999$ development, root-finder tolerance.
The cost-comparison table is falsifiable.
The remaining specificity gaps are minor: Step 0.6's success criterion could be tightened (see dimension 1 Yellow), and the synthetic coverage MC design is explicitly punted to plan rev 6.
Neither blocks execution of rev 5's empirical block.

[Green] [Recoded-design construction first-implementer-ready] -- Lines 90--114.

[Green] [Path G specification first-implementer-ready] -- Lines 162--170.

[Green] [Path D variants (onepass / Julia / grid) all named with budgets] -- Lines 142--150, 197--205.

[Green] [Cost-comparison table falsifiable] -- Lines 196--205.

## Top recommendations for rev 6 (or APPROVE)

APPROVE: rev 5 is ready to act on.

The three remaining Yellows are tuning-grade and resolvable during execution:

1. (Optional, 5-minute add) Strengthen Step 0.6 success criterion to include a positive check that the returned CI is genuinely from a joint $q$-dim null, not a silent per-coefficient inversion---e.g., compare against a scalar-null `boottest` run on one of the recoded $z$'s and confirm they differ in the expected direction.

2. (Optional, accept risk) Either widen the path D-Julia wrapper budget to 1--2 days or add a 30-minute Step 0.6b that times a single `WildBootTests.jl` subprocess round-trip on a toy problem before committing the full wrapper budget; the Windows + Stata + Julia subprocess path is genuinely tight at 1 day.

3. (Optional, low-priority hedge) Add a one-line "Why AHZ Satterthwaite not Hansen calculated df?" entry to the Referee Q&A section to preempt a referee citing Hansen (2025).

The convergence pattern across revisions---4 Red (rev 1) -> 6 Red (rev 2) -> 4 Red (rev 3) -> 2 Red (rev 4) -> 0 Red (rev 5)---reflects that rev 5 patched rev 4's two load-bearing issues without re-architecting and folded in the actionable Yellows.
The team should run Steps 0, 0.5, and 0.6 and let the empirical results dictate plan rev 6's structure.
