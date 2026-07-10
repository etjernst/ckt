# Six-dimension critique of plan rev 3

Date: 2026-05-02
Target: [`quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev3.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev3.md)
Mode: fresh-eyes critique across six dimensions, with the rev 2 critique as anchor for what was supposed to change.

## Summary verdict

Red: 4.
Yellow: 9.
Green: 5.

Rev 3 closes most of the rev 2 Reds---per-grid CR2 cost is now explicit, path G adds CR3, recoded-design construction is pinned to first-implementer level, and the empirical AHZ df contingency lands in the pass criteria.
The plan still misses the conventional 2026 sequencing in which `summclust` runs first as a leverage and $G^*$ diagnostic before any backend selection, conflates "from-scratch CR3" with what `summclust`'s `vce(jackknife)` already delivers, leaves path D under-specified on the WCR-versus-WCU decision that drives whether path D is one bootstrap or thirty, and treats CR3 + WCB as a choice rather than the conventional joint pair that MNW (2023) recommends.

## Dimension 1: pre-mortem

If rev 3 fails by August 2026, three failure modes dominate.
First, the team commits 1 day to path G's "from-scratch CR3" implementation only to discover that `summclust`'s `vce(jackknife)` and `vce(jackknife, mse)` already implement CV3J and CV3 respectively---the very thing path G is described as building from scratch with `summclust` only as an anchor.
Second, path D is selected as the fallback, the team builds a WCR (wild cluster restricted) inversion that re-bootstraps at every grid point, and discovers two weeks in that WCU (wild cluster unrestricted) inversion via `boottest`'s native root-finding would have collapsed the same workload to a single bootstrap pass---a 30-fold cost differential the plan never names.
Third, leverage diagnostics are deferred to inside the IDN probe (Step 3), $G^*$ at IDN unbalanced turns out to be far below 30, and the entire backend-selection block (paths A, B, C, F, G) was moot because only path D survives at this leverage profile---the 30-min `summclust` run that would have revealed this was scheduled too late.

[Red] [Path G conflates CR3 implementation with the diagnostic tool] -- Plan line 196 names `summclust` as "the small-$J$ anchor" for path G, but `summclust` itself implements CR3 / CV3J directly via `vce(jackknife)` (and CV3 via `vce(jackknife, mse)`), so "from-scratch CR3" at lines 189--200 is building what summclust ships.
The 1-day implementation effort is potentially the wrong unit of work. -> Re-scope path G to "use `summclust`'s `vce(jackknife, mse)` as the production CR3 backend; from-scratch only if `summclust` does not scale to IDN," and rerun the cost analysis with `summclust` as the candidate, not the anchor.

[Red] [Path D's WCR-vs-WCU choice is not stated] -- Plan lines 166--178 cost path D as "999 bootstraps $\times$ 30 grid points" (line 170), which is the WCR (restricted) cost; under WCU (unrestricted) `boottest` inverts in a single bootstrap pass via root-finding for all parameters.
The differential is roughly 30$\times$.
The plan never names this distinction. -> Specify path D as WCU inversion via `boottest`'s native root-finding (single bootstrap, not 30); WCR is a fallback only if WCU's root-finder fails to bracket.
This collapses path D's per-cell cost from 5--15 min to roughly $1/30$th of that.

[Red] [Leverage diagnostics scheduled inside the probe instead of before backend selection] -- Plan Step 3 (lines 244--248) lists "leverage diagnostics ($\max n_j$, $\sum_j n_j^2$, Gini)" as part of the IDN probe, after Steps 0--2 have already scoped paths A, B, C, F, G.
But $G^*$ from `summclust` is the diagnostic that decides whether AHZ inference is even meaningful---if $G^* < 30$ at IDN unbalanced, only path D survives regardless of any other consideration. -> Promote `summclust` leverage and $G^*$ diagnostics to a new Step 0.5, before the literature scan and IDN probe; if $G^* < 30$ or leverage is severely concentrated, skip Steps 1--3 and go directly to path D.

[Red] [CR3 and WCB framed as alternatives rather than the conventional joint recommendation] -- MNW (2023) recommend CV3J and/or wild cluster bootstrap as the standard paired fallback when CR1/CR2 leverage diagnostics flag concern; running both is conventional, not "either path G or path D."
Plan line 269--273 frames path G versus path D as a binary choice, with G "keeping the F-adjusted-AHZ narrative" and D "rewriting the referee narrative." -> Reframe the decision branch as "production = CR3 via `summclust` (path G) with WCU bootstrap (path D) as the validation cross-check," not as G-or-D; this is the published recommendation and matches what referees will expect.

## Dimension 2: completeness

The plan covers backend selection arithmetic, the constraint reformulation, recoded-design construction, the AHZ df contingency, and pass criteria.
What a domain expert circa 2026 would still expect: an explicit pre-backend leverage and $G^*$ pass via `summclust` before any path commits, an explicit WCR-vs-WCU decision under path D, an explicit Q&A for the referee on "why CR2 not CR3" (currently hand-waved as "path G is on the table"), and a small-$J$ anchor strategy for path G that does not collapse into the very tool the plan names as the anchor.
The pass criteria handle df-too-small (line 260) and df-too-large (line 261) but not the related diagnostic of $G^*$ at promotion time---the plan reports leverage moments but not $G^*$ itself.
The corrigendum incorporation status remains TODO with no scheduled close (line 159, hedged "TODO" reference).

[Red] [No pre-backend $G^*$ check] -- See pre-mortem Red 3.
The standard 2026 ordering is: run `summclust` first to get $G^*$ and the leverage profile; only then decide which backend.
The plan never computes $G^*$. -> Add Step 0.5: "Run `summclust` on TZA covs_trend at full $J$ and on the IDN unbalanced design at full $J$; report $G^*$, partial leverage, and influence diagnostics; if $G^* < 30$ at IDN, skip to path D."

[Yellow] [Referee Q&A on CR2 vs CR3 missing] -- The plan invokes "a referee asking 'why not CR3' is answered by path G being on the table" (line 200), but the symmetric question---"why CR3 not CR2"---is not addressed.
Path C remains in the plan as the CR2 from-scratch route; with path G also in the plan, the team needs to articulate which one wins on what grounds. -> Add a one-paragraph Q&A: "CR2 is preferred when leverage is moderate and $G^*$ is large; CR3 is preferred when the eigendecomposition cost dominates or when $A_j = (I - H_{jj})^{-1/2}$ is numerically poorly conditioned at low $G^*$; we run both and report agreement at small $J$ as a robustness check."

[Yellow] [Path D specification missing] -- Path D at lines 166--178 specifies $B = 999$ vs $B = 9999$ but not (a) WCR vs WCU (see Red above), (b) which `boottest` weight type (Rademacher, Mammen, Webb), (c) what root-finder tolerance for the inversion, or (d) whether to use `boottest`'s native CI-via-inversion option or build the inversion externally. -> Pin: WCU inversion via `boottest, gridpoints(0)` with native root-finding, Rademacher weights, $B = 9999$, root-finder tolerance $10^{-4}$ on $\phi$.

[Yellow] [$G^*$ not in the pass criteria] -- Pass criteria at lines 254--261 cover wall, memory, anchor agreement, total wall, and df bounds.
$G^*$ from `summclust` is the prior diagnostic: a pass on (i)--(v) at $G^* = 5$ is meaningless. -> Add (vi): "$G^*$ from `summclust` $\ge 30$ at IDN; if $G^* < 30$, fallback to path D regardless of (i)--(v)."

[Yellow] [Anti-conservative-bias check still deferred] -- Line 263--265 acknowledges the synthetic coverage MC but defers it to plan rev 4.
The plan rev 2 critique (Y2) flagged the same gap; rev 3 did not close it. -> Either land a 30-min synthetic coverage MC at the empirical $J/q$ ratio inside this plan as Step 5, or commit to a specific section in rev 4 with a budget.

[Yellow] [Corrigendum read still not scheduled to a date] -- Line 159 says "scheduled before the 1--2 day path-C build" but does not name a calendar date or a person. -> Pin to "$\le$ 2026-05-09" or to "before Step 4."

[Green] [Empirical AHZ df contingency landed] -- Pass criterion (v) at lines 259--261 closes rev 2's Red on df-too-small; df below 4 triggers fallback to path D. This is the right contingency.

[Green] [Recoded-design construction pinned to first-implementer level] -- Lines 92--121 pin base trajectory per country/spec, the variable mapping to `beta_s_*` and `alpha_d_*`, singleton handling, and controls/FE choice. This closes rev 2's Red on under-specification.

## Dimension 3: feasibility

Three feasibility risks survive into rev 3.
The traceback is now reframed as a controlled OOM reproduction with `tracemalloc` budgeted at 1--2 hours (closing rev 2 R-feasibility-1), but it still depends on `tracemalloc` being installable in the R/Python environment used in Step 0a---untested.
Path F's literature scan retains the rev 2 risk that all three candidates fail; rev 3 does not say what happens if F.0 finds nothing actionable beyond "skip F.1 and go to Step 3."
Path G is described as "from-scratch" with `summclust` as the anchor, but as flagged in dimension 1, `summclust` itself is the production-ready CR3 implementation, so the feasibility of "1-day from-scratch CR3" is uncertain---it may be a one-line `summclust, jackknife mse` call, or it may be a real reimplementation, depending on whether `summclust` scales to IDN.

[Yellow] [`summclust` scaling to IDN unverified] -- The plan names `summclust` as the path G anchor (line 196) without checking whether `summclust` itself runs at $J \approx 30{,}000$ under IDN unbalanced.
If `summclust` OOMs or times out at IDN (it computes leverage diagnostics on every cluster), path G's anchor is broken. -> Add to Step 0.5: timing and memory profile of `summclust` at IDN scale.

[Yellow] [Path-F null result has no defined action] -- Step 2 at line 242 says "If F.0 finds nothing, skip F.1 and go to Step 3," which sends the team to paths A and B at IDN scale.
But if F.0 finds nothing AND paths A and B fail (the most likely outcome given the rev 2 cost arithmetic), the plan has not specified whether to default to G, C, or D. -> Add an explicit decision rule: "If F.0 null and A, B fail, skip path C in favor of G + D paired (per dimension 1 reframing)."

[Yellow] [`tracemalloc` / R `tracemem()` availability assumed] -- The Step 1 OOM reproduction at lines 233--237 assumes `tracemalloc` (Python) or `tracemem()` (R) are usable in the same environment that hit the OOM.
The Step 0a memo at line 31 ran R `clubSandwich` from `explorations/python-grc/stata/step0a_fe_absorption/`; whether instrumenting that script with `tracemem()` is a 5-min change or requires reinstalling R packages is unstated. -> Verify the profiler is available before the 1--2 h budget; flag if reinstall needed.

[Green] [Path-F split into F.0 and F.1] -- Line 181--187 implements rev 2's R-feasibility-1 (split into literature scan and conditional prototype) cleanly. This is closed.

## Dimension 4: best-practice alignment

Best practice 1 (`summclust` as canonical Stata tool for CR3 and leverage diagnostics): the plan engages with `summclust` only as an anchor for path G and only mentions it inside the path G description (line 196) and the path F survey (line 183).
It does not use `summclust` as the diagnostic tool that decides whether AHZ inference is even meaningful (the conventional ordering).
Best practice 2 (WCR re-bootstraps per null, WCU inverts in one pass via root-finding): the plan does not engage at all---path D's cost arithmetic at line 170 implicitly assumes WCR.
Best practice 3 (`boottest` natively supports test inversion via root-finding): the plan names `boottest` (line 168) but does not invoke its root-finding inversion explicitly; the per-cell cost arithmetic again assumes WCR-style grid-point bootstrapping.
Best practice 4 (CV3J + WCB as the conventional joint pair, not alternatives): the plan frames path G versus path D as a binary methodological choice (line 271).
Best practice 5 (run `summclust` BEFORE picking a backend): the plan defers leverage diagnostics to inside Step 3, after backend selection has been scoped.

[Red] [WCR-vs-WCU not specified under path D] -- See pre-mortem Red 2 and dimension 2 Yellow on path D specification.
Path D's per-cell cost is 30$\times$ too high if WCU inversion is the intended implementation. -> Specify WCU inversion via `boottest`'s native root-finding; recompute the cost-comparison table.

[Yellow] [`summclust` not used as the diagnostic before backend selection] -- See pre-mortem Red 3 and dimension 2 Red.
The conventional ordering (per MNW 2023) is `summclust` first, then backend. -> Promote `summclust` to Step 0.5.

[Yellow] [CR3 + WCB joint not on the table] -- See pre-mortem Red 4. -> Reframe paths G and D as a paired production-plus-validation pair, not alternatives.

[Green] [PT 2018 corrigendum applicability still correctly invoked] -- Line 48--49 cites the corrigendum and confirms the OLS-with-identity-working-model condition for the auxiliary OLS. This is consistent with best practice 2 and is preserved from rev 2.

[Green] [Reformulation (4)'s structural identity to Davidson-MacKinnon WCB recoding noted] -- Line 86 acknowledges "the pattern is structurally identical to the recoding Davidson-MacKinnon use in their wild bootstrap papers; it is not novel." This closes rev 2's Yellow on missing precedent.

## Dimension 5: sequencing

The empirical block at lines 229--249 orders Step 0 (data-prep verification, 30 min), Step 1 (controlled OOM repro, 1--2 h), Step 2 (path-F scan, 1--2 h), Step 3 (IDN probe, 2--3 h), Step 4 (conditional path C/G prototypes).
This closes rev 2's sequencing Yellows on traceback-before-path-B and path-F-before-A/B-probe.
What rev 3 still misses: `summclust` leverage and $G^*$ diagnostics should run before Step 1, not inside Step 3.
The 30-min `summclust` step potentially short-circuits the entire rest of the empirical block if $G^*$ is small.
The corrigendum read is named as a path-C prerequisite (line 160) but is not given a calendar slot.

[Red] [`summclust` should be Step 0.5, before OOM repro] -- See dimensions 1 and 4.
Running `summclust` first as a 30-min step potentially cuts the empirical block in half. -> Insert Step 0.5: "`summclust` on TZA full and IDN unbalanced; report $G^*$, partial leverage, influence; if $G^* < 30$ at IDN, skip Steps 1--4 and write rev 4 with path D as production."

[Yellow] [Step 4 conditional logic incomplete] -- Step 4 at line 249 says "If both A and B fail at IDN, run path C and path G prototypes on the same recoded TZA design at $J = 1500$."
But if $G^* < 30$ (per Step 0.5), Step 4 is moot.
And if `summclust` itself is the path G prototype (per dimension 1 Red), Step 4's path G prototype reduces to a one-line `summclust` call already done in Step 0.5. -> Rewrite Step 4 to reflect the Step 0.5 outcomes.

[Green] [IDN-first ordering preserved] -- Step 3 still leads with the IDN unbalanced pattern. The kill criterion is correctly placed.

[Green] [Path-F scan now precedes IDN probe] -- Step 2 is now before Step 3, closing rev 2's sequencing Yellow.

## Dimension 6: specificity

Three specificity gaps survive.
Path G's "anchor via `summclust` at small $J$" (line 196) is hand-wavy: which `summclust` option (`vce(jackknife)` for CV3J or `vce(jackknife, mse)` for CV3), what $J$, what tolerance, and whether the anchor is on the test statistic, df, or the CR3 covariance itself.
Path D is under-specified on WCR vs WCU, weight type, $B$, and root-finder tolerance (see dimension 4).
The Step 0.5 leverage diagnostics step (which I am proposing be added) needs first-implementer specificity if it is to be a 30-min step rather than a half-day.

[Yellow] [Path G anchor under-specified] -- Line 196--197: "small-$J$ anchor is `summclust` in Stata at $J = 1500$" without naming the `summclust` option or what is being compared.
If path G is reimplementing CR3 from scratch and `summclust` is the reference, the anchor is "our CR3 covariance matches `summclust, vce(jackknife, mse)`'s to $10^{-6}$ relative." -> Pin: "anchor against `summclust, vce(jackknife, mse)` at $J = 1500$ on the TZA covs_trend recoded design; tolerance $10^{-6}$ relative on the CR3 covariance, $10^{-4}$ on the test statistic, $10^{-3}$ on the df."

[Yellow] [Path D specification still under-pinned] -- See dimension 4 Yellow on path D specification.
A first-time implementer cannot write the path D code from the plan as written. -> Pin all four: WCU inversion, Rademacher weights, $B = 9999$, root-finder tolerance $10^{-4}$ on $\phi$.

[Green] [Recoded-design construction is now first-implementer specific] -- Lines 92--121 are a worked example with base trajectory, variable names, and singleton handling pinned. This closes rev 2's Red.

[Green] [Cost-comparison table is concrete] -- The path-by-path table at lines 208--215 gives reviewers something to falsify; this is preserved from rev 2.

[Green] [Pass criteria are concrete] -- Lines 254--261 are specific on wall, memory, anchor tolerance, total wall budget, and df bounds. This is the right level of specificity.

## Top recommendations for rev 4

1. Add Step 0.5: run `summclust` on TZA full and IDN unbalanced before any backend selection.
Report $G^*$, partial leverage, influence.
If $G^* < 30$ at IDN, skip to path D and write rev 4 with WCU bootstrap as the production backend.
This is the conventional 2026 ordering and potentially short-circuits the rest of the empirical block.

2. Re-scope path G: `summclust`'s `vce(jackknife, mse)` is the production CR3 implementation, not just the anchor.
The "1-day from-scratch CR3" framing is wrong; the right unit is "verify `summclust` scales to IDN, then call it."
If `summclust` does not scale, the from-scratch path is well-defined, but it should not be the default scoping.

3. Specify path D as WCU inversion via `boottest`'s native root-finding, not WCR with grid-point re-bootstrapping.
The cost differential is roughly 30$\times$ in the per-cell wall.
Pin Rademacher weights, $B = 9999$, root-finder tolerance $10^{-4}$ on $\phi$.

4. Reframe paths G and D as the conventional joint production-plus-validation pair (per MNW 2023), not as alternative backends.
"Production = CR3 via `summclust`; validation = WCU bootstrap via `boottest`" is the standard 2026 recommendation; running both is conventional and answers the symmetric referee questions ("why not CR3," "why not WCB") in one move.

5. Add $G^*$ to the pass criteria as criterion (vi); without it, criteria (i)--(v) can pass at meaninglessly low effective cluster counts.

6. Schedule the corrigendum read to a calendar date ($\le$ 2026-05-09 or before Step 4), and either land the synthetic coverage MC inside this plan or commit it to a specific rev 4 section with a wall-time budget.
