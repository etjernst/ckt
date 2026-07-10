# Six-dimension critique of plan rev 2

Date: 2026-05-02
Target: [`quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md)
Mode: fresh-eyes critique across six dimensions.

## Summary verdict

Red: 6.
Yellow: 11.
Green: 4.

The plan tightens rev 1 substantially on the methodological side (reformulation 4, the IDN-first reordering, the corrected flop counts) but leaves several load-bearing pieces unresolved: the recoded design's CR2 cost is undercounted, the empirical block depends on a traceback against a process that may no longer be reproducible, the path-F survey is scheduled in parallel with the IDN probe rather than gating it, and CR3 (a published, computationally cheaper alternative) is missing entirely.
Two pre-mortem failure modes are concrete enough to warrant Red findings even before any code runs.

## Dimension 1: pre-mortem

If this plan fails by August 2026, the most plausible root causes are: (i) reformulation (4) does not actually collapse the per-grid CR2 cost the way the plan implicitly assumes, because $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s and so the entire BRL adjustment must be rebuilt at every grid point---turning "30 cheap refits per cell" into "30 expensive vcovCR builds per cell"; (ii) the IDN-scale probe burns days because it is built from the actual unbalanced cluster pattern but the plan does not specify which RP7 design file, which controls, or whether to drop singletons, leading to repeated false-start configurations; (iii) the path-F survey never identifies a viable candidate, the user re-rejects path C on novelty grounds (the same rejection that produced rev 1), and the team falls back to path D under time pressure without the WCB validation work in place.
None of these are speculative; each is implied by the plan's own text.

[Red] [Per-grid CR2 cost in reformulation (4)] -- The plan acknowledges at line 107 that "the CR2 step still has to be redone per $\phi$ because $H_{jj}(\phi)$ depends on $\phi$ through the recoded $z$'s; this is the dominant cost," but the path A cost analysis at lines 117--122 reads as if 30 refits is mostly OLS work, and the cost-comparison table at line 220 lists "30 fits/cell $\times$ per-fit wall" without specifying that "per-fit wall" includes a full vcovCR rebuild.
If vcovCR at IDN scale is 30 minutes, 30 grid points $\times$ 30 minutes is 15 hours per cell, $\times$ 60 cells is 900 hours. -> Add an explicit per-cell wall-time row in the cost table that multiplies the per-$\phi$ vcovCR cost by 30, and gate the IDN probe on a single-fit timing first.

[Red] [Path-F survey concurrency with IDN probe] -- At lines 235--244, the empirical block runs path-F survey (1-2 h) and the IDN A/B probe (2-3 h) without a stated dependency.
If path F finds a viable candidate (say, a sparse-CR2 R package), the IDN probe on paths A and B is wasted work; conversely if path F is run after, the team has spent the rev-4 budget on paths that path F could have made obsolete. -> Sequence the path-F survey before the IDN probe (it is shorter), and only run the probe on paths A, B, plus any path-F candidate that survives the literature scan.

[Red] [Plan does not engage with CR3] -- MacKinnon, Nielsen, Webb (2023) and Hansen (2025) propose CR3 as performing as well or better than CR2 in many scenarios while being computationally cheaper.
The plan never mentions CR3.
If the team commits 1-2 days to a from-scratch CR2 implementation under path C and a referee asks "why not CR3," the answer "we did not consider it" is bad. -> Add CR3 as either a sub-variant of path C (cheaper meat build, no $A_j = (I - H_{jj})^{-1/2}$ step) or as a separate path G with its own cost analysis and anchor.

## Dimension 2: completeness

The plan covers backend selection, cost arithmetic, the constraint reformulation, and pass criteria, but several things a domain expert would expect are missing.
There is no small-cluster-count or leverage-diagnostics step before promotion of any backend, despite the AHZ df being a function of leverage---a concentrated leverage profile in the IDN unbalanced design could collapse the effective df below 4 and the plan has no contingency.
The pass criteria at line 247--253 specify wall time, memory, and anchor agreement, but not what the team does if the empirical AHZ df at IDN scale lands below 4 (the F distribution becomes unreliable at very low df) or above $J/2$ (a sign of df breakdown).
The plan also does not discuss anti-conservative-bias checks: a backend that runs but produces CIs that under-cover at the empirical $J/q$ ratio is worse than no backend.
Sample size vs cluster count is conflated in the cost arithmetic (the $N$ in the OOM diagnosis is implicit).

[Red] [Empirical AHZ df contingency missing] -- The PT 2018 + 2023 corrigendum AHZ df can collapse to small values when leverage is concentrated; the rev-1 reviewer flagged this (line 127 of plan rev 1: "near-singularity concern"), and rev 2 dropped it.
The plan does not say what happens if the IDN-unbalanced AHZ df is below 4. -> Add to the pass criteria: "(v) the empirical AHZ df at the LCA contrast is between 4 and $J/2$; df below 4 triggers a fallback to path D (WCB) regardless of wall-time/memory."

[Yellow] [Leverage diagnostics not in pre-promotion checks] -- Compute and report the per-cluster leverage distribution before promoting any backend, since AHZ df is a function of it.
A 5-line check on the actual IDN design takes 15 minutes and de-risks the df contingency above. -> Add a "leverage profile" sub-step to the IDN-scale probe.

[Yellow] [Coverage simulation absent] -- The plan never specifies a synthetic coverage MC at the empirical $J/q$ ratio, which is the standard validation for any new BRL+AHZ implementation at large $J$.
PT 2018 themselves run such simulations. -> Either add a step 5 (small synthetic coverage MC at empirical $J/q$) or reference where in the broader pipeline this lives.

[Yellow] [Sample size vs cluster count] -- The plan's "kill criterion" is $J = 30{,}000$, but at IDN unbalanced the relevant constraint for OOM is $\sum_j n_j^2$ or $N$, not $J$ alone.
A cluster pattern with the same $J$ but heavier tail would OOM where the average pattern doesn't. -> When building the IDN probe, report $J$, $N$, $\max n_j$, $\sum_j n_j^2$, and the Gini coefficient of cluster sizes.

[Yellow] [Singletons not addressed] -- IDN unbalanced will have a tail of singleton clusters ($n_j = 1$); these contribute zero to the BRL adjustment ($I_1 - H_{11}$ has a single eigenvalue that may be near zero or zero) and can trigger numerical issues in the $A_j = (I - H_{jj})^{-1/2}$ step.
The plan does not say whether to drop them, regularize, or carry them through. -> Specify singleton handling explicitly before any IDN-scale run.

[Yellow] [No published-paper precedent cited] -- The plan invokes "published `boottest` benchmarks" at line 180 and "published BRL implementations" at rev 1's R3 reformulation (4) discussion but does not cite a specific paper that ran into this exact problem (CR2 + AHZ inversion at $J \approx 30{,}000$). -> Cite at least one prior empirical paper that ran inference at comparable $J$, ideally one from labor or development.

[Yellow] [Numerical conditioning of recoded design unstated] -- For each $\phi_0$ on the grid, the recoded $z_{is}^{(\phi_0)}$ may be near-collinear with the trajectory FE for $\phi_0$ values where the LCA restriction is nearly satisfied.
The plan does not check the condition number of the per-$\phi$ design. -> Add a per-$\phi$ condition number diagnostic to the IDN probe.

## Dimension 3: feasibility

Several steps depend on resources or accesses the plan asserts but does not confirm.
The biggest is the 30-minute traceback at line 237: this requires either a reproducible OOM or the original Python/R session still being alive with the traceback object accessible, and the predecessor memo at line 21 says the run was "still running" rather than confirming it was captured.
The path-F survey depends on packages that may not exist (Niccodemi-Alessie has a series of papers; whether any has a public R/Stata package is unverified) or on a clubSandwich GitHub dev branch whose existence is conjectural.
The clubSandwich-as-anchor argument depends on the corrigendum incorporation TODO landing, which the plan acknowledges but does not schedule.

[Red] [Traceback on already-failed run] -- Line 237: "Pin down where `clubSandwich`'s OOM allocates, via `traceback()` on the failed J=11k run."
The Step 0a memo at line 21 has the run "still running at 12 GB after 40+ min wall"; whether it OOM'd cleanly with a traceback object preserved, or was killed by the OOM killer (no traceback), or is still alive in a session, is not stated.
A 30-minute step that depends on a traceback that may not exist is a feasibility risk. -> Reframe the step as "reproduce the OOM under controlled conditions with `tracemem()` or the Python `tracemalloc` profiler instrumented from the start"; budget 1-2 h, not 30 min.

[Yellow] [Path-F candidate package existence unverified] -- Line 203--214 lists Niccodemi-Alessie, MNW summclust, and Pustejovsky GitHub dev branch as path-F candidates, but the plan does not assert that any of them has a working implementation suitable as a drop-in for clubSandwich at our scale.
"Cost to scan: 1-2 hours" is a literature-search budget, not a candidate-promotion budget. -> Split path F into F.0 (literature scan, 1-2 h) and F.1 (candidate prototype on TZA full, conditional on F.0 finding something, 2-3 h).

[Yellow] [Corrigendum TODO not scheduled] -- The corrigendum incorporation status is "TODO" per line 160, but the plan does not schedule when this TODO closes.
Path C's anchor argument is contingent on it. -> Schedule the corrigendum read as a prerequisite of any path-C implementation kickoff.

[Yellow] [60-cell wall budget assumes parallelism] -- Pass criterion at line 253: "60 cells fit in $\le 10$ days of wall time, or under 2.5 days with 4-way parallelism."
4-way parallelism on the pystata bridge serializes Stata calls; the plan does not say what infrastructure provides the parallelism. -> Specify the parallelism mechanism (separate Stata sessions, R processes, cluster scheduler) before relying on the 4-way speedup.

## Dimension 4: best-practice alignment

The plan engages well with best practice 2 (the PT 2018 corrigendum's OLS-vs-GLS restriction on the absorbed-FE shortcut): the auxiliary OLS in the LCA inversion satisfies the OLS-with-identity-working-model condition, so the absorbed-FE shortcut is legitimate.
The plan does not cite the corrigendum's Theorem 2 update by name when invoking absorption at lines 88--110, though, and an explicit footnote would protect the path A and path B architecture against a referee challenge.
The plan engages with best practice 5 (WCB) under path D and gets the inversion-noise math approximately right (Y3 of the rev-1 review).
The plan engages with best practice 4 (MNW summclust) as part of path F, though only in passing.
The plan does not engage with best practice 1 (CR3) at all, despite CR3 being computationally cheaper and arguably the current frontier as of 2025.
The plan engages with best practice 3 (BRL adjustment matrix after absorbing within-cluster FE for OLS-identity) only implicitly, via the path-A/B framing under reformulation (4); it should be cited.

[Red] [CR3 absent] -- See pre-mortem Red 3.
Best practice 1 in the user's literature scan flags CR3 (MacKinnon-Nielsen-Webb 2023, Hansen 2025) as the emerging frontier alternative to CR2 + Satterthwaite, and the plan does not engage. -> Add a path G (CR3 + Satterthwaite or CR3 + bootstrap) with a parallel cost analysis to path C; the implementation effort should be shorter than path C since CR3 does not require the $A_j = (I - H_{jj})^{-1/2}$ eigendecomposition.

[Yellow] [Corrigendum not cited at the absorbed-FE step] -- Path A at lines 117--122 and path B at 134--140 invoke `absorb(trajectory)` without citing the PT 2018 corrigendum's Theorem 2 update that legitimizes the absorbed-FE shortcut for OLS-with-identity-working-model.
A referee will ask. -> Add an inline citation to Pustejovsky's 2024 corrigendum post (https://jepusto.com/posts/pusto-tipton-2018-theorem-2/) at the absorbed-FE introduction.

[Yellow] [No citation for varlist-zero recoded-design pattern] -- Reformulation (4) at lines 100--108 is presented as novel-to-this-plan, but the recoded-design varlist-zero is a published pattern in CR-restriction testing (e.g., Davidson-MacKinnon WCB papers use a structurally identical reformulation for restriction tests). -> Cite the published precedent so reformulation (4) is not load-bearing on novel work.

[Green] [PT 2018 corrigendum applicability] -- The plan's auxiliary OLS satisfies the OLS-with-identity-working-model condition, so the absorbed-FE shortcut is legitimate; this is consistent with best practice 2 and should be preserved.

[Green] [Reformulation (4) collapses constraint-matrix advantage] -- The plan correctly identifies at lines 49--51 that with reformulation (4) the architectural argument for R over Stata is moot; this is the right read of best practice 5.

## Dimension 5: sequencing

The empirical block at lines 235--245 orders: (1) traceback, (2) path-F survey, (3) IDN-scale A/B probe in parallel.
Two reorderings would reduce risk.
First, the path-F survey should precede the A/B probe rather than running in parallel with it; if path F finds a sparse-CR2 R package, paths A and B may be obsolete.
Second, the traceback should run before the path-F survey, not in parallel, because the traceback diagnosis determines whether path B's premise (FE-absorption helps) holds, and a path-F candidate that solves a different problem than what actually OOM'd is a wasted promotion.
There is also a hidden blocker the plan does not address: the IDN-scale probe requires the actual IDN unbalanced design from RP7, which means the IDN data-prep pipeline must be runnable end-to-end---and the team has not confirmed this on the lca-inversion branch.

[Yellow] [Path-F survey should gate the A/B probe] -- See pre-mortem Red 2.
If F finds a viable candidate, run the candidate on the IDN probe instead of paths A and B; if F finds nothing, run paths A and B. -> Sequence: F.0 (1-2 h) before A/B probe (2-3 h).

[Yellow] [Traceback should gate path B specifically] -- The traceback at line 237 resolves Y1, which determines whether path B's FE-absorption premise holds.
Running paths A and B in parallel before knowing whether path B is mis-targeted (per rev-1 review's Y1) wastes path B effort if the OOM is in `Wald_test`'s HTZ df build. -> Sequence: traceback before path B probe; path A probe can run in parallel with traceback since path A's premise (Stata absorbed-mode behaves differently) is independent of the clubSandwich diagnosis.

[Yellow] [IDN data-prep pipeline reproducibility on this branch] -- The IDN-scale probe at line 241 says "build the IDN-scale probe from the actual IDN unbalanced cluster pattern (RP7 design, not a synthetic Bernoulli draw)."
Whether `4_processOLS.do` and the upstream IDN cleaning run end-to-end on lca-inversion's RP7 has not been confirmed in any artifact in this plan.
A morning lost to data-prep debugging would push the empirical block to 6-8 h. -> Verify the IDN data-prep runs cleanly on lca-inversion before scheduling the probe; this is a 30-minute check.

[Green] [IDN-first ordering] -- The rev-1 review's R4 (test the kill criterion first) is correctly addressed; this was the most important sequencing fix in rev 2.

## Dimension 6: specificity

For someone unfamiliar with the project to execute, three specific steps are under-specified.
The recoded-design construction at lines 100--108 specifies the formula $z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot \mathbb{1}\{\text{trajectory}_i = s\}$ but does not specify which trajectory is the base, how to handle the IDN income spec where the base is 16 not 2 (per the CLAUDE.md known issue), or whether $D_{is}$ is the per-trajectory urban indicator or the trajectory-by-treatment interaction $\beta_s$ from the existing GRC code.
The IDN-scale probe at line 241 says "from the actual unbalanced cluster pattern" without specifying a design file path, controls list, or whether to use covs_all or covs_trend.
The traceback step at line 237 says "30-min traceback on the failed J=11k run" without specifying whether the run is reproducible, what tooling to use (`traceback()`, `tracemem()`, Python `tracemalloc`), or what the success criterion of the traceback is.

[Red] [Recoded-design construction under-specified] -- Reformulation (4) is the methodological linchpin of paths A and B but the plan does not specify (a) the base trajectory choice, (b) the relationship between $D_{is}$ and the existing `beta_s_*` / `alpha_d_*` variables in the auxiliary OLS, (c) how to handle the IDN income-base-16 issue from CLAUDE.md known issues, or (d) whether the recoding includes controls.
A first-time implementer would need to ask 3-5 questions before writing any code. -> Add a worked example: "for IDN consumption, base trajectory $\underline{d}_0 = 2$, $D_{is}$ is the per-cell urban indicator at trajectory $s$, the recoded variable is $z_{is}^{(\phi_0)} = \mathtt{beta\_s\_}s - \phi_0 \cdot \mathtt{alpha\_d\_}s$, and the LCA test at $\phi_0$ is the joint zero on $z_{is}^{(\phi_0)}$ for $s \in \{3, 4, ..., 26\} \setminus \{\underline{d}_0\}$."

[Yellow] [IDN-scale probe inputs under-specified] -- See sequencing Y3.
The plan should pin (a) the design file path under RP7, (b) the spec (covs_all or covs_trend), (c) singleton handling, and (d) the controls list. -> Add a probe-spec sub-section with these four items pinned to a specific RP7 do-file.

[Yellow] [Traceback step under-specified] -- The 30-min traceback at line 237 does not say what success looks like.
Is it "identify the line in clubSandwich source that allocates the OOM-blowing intermediate," or "produce a peak-memory trace showing where allocation crosses 12 GB"?
These are different exercises. -> Specify success criterion: "produce a `tracemalloc` snapshot at peak with at least the top 10 allocation sites identified, and a one-line summary of which clubSandwich function the largest allocation occurred in."

[Yellow] [Pass criterion for the small-J anchor agreement] -- Line 252: "agrees with a small-$J$ clubSandwich anchor to $10^{-4}$ on the test statistic and $10^{-3}$ on the df."
The plan does not specify which $J$ ("small-J" is informal), which design (TZA, IDN, synthetic), or whether the agreement is on the same recoded $\phi_0$ or on the joint-zero contrast.
Different choices give different tolerances. -> Pin: "anchor at $J = 1500$ on the TZA covs_trend design, agreement on the recoded varlist-zero at $\phi_0 = \hat\phi_{\text{point}}$ (the unrestricted point estimate)."

[Green] [Pass criteria are concrete on wall time and memory] -- Lines 250--253 are specific where they need to be (30 min, 16 GB, 4 h/cell, 10 days total); this is the right level of specificity for promotion gates.

[Green] [Cost-comparison table is concrete] -- The path-by-path table at lines 218--225 is more explicit than rev 1's and gives reviewers something to falsify.

## Top recommendations for rev 3

1. Add CR3 (MacKinnon-Nielsen-Webb 2023, Hansen 2025) as a separate path G, with parallel cost analysis to path C; CR3 is computationally cheaper and is the current frontier alternative to CR2 + Satterthwaite that the plan does not engage with.
2. Make the per-$\phi$ vcovCR cost explicit in the cost-comparison table and in the path A/B descriptions.
The current text at line 107 acknowledges "the CR2 step still has to be redone per $\phi$" but the cost table does not multiply by 30; if vcovCR at IDN scale is 30 minutes, paths A and B are dead at IDN regardless of memory because per-cell wall is 15 hours.
3. Specify the recoded-design construction to first-implementer level: pin the base trajectory per country/spec, name the existing variables ($\mathtt{beta\_s\_}*$, $\mathtt{alpha\_d\_}*$) the recoding maps onto, and address the IDN income-base-16 issue from CLAUDE.md.
4. Reorder the empirical block: (i) traceback first (1-2 h, with reproduction-from-scratch budget), (ii) path-F literature scan (1-2 h), (iii) only then run paths A, B, and any path-F candidate on the IDN probe in parallel.
This avoids wasting probe effort on paths that the diagnosis or the literature scan would have ruled out.
5. Add an explicit empirical-AHZ-df contingency to the pass criteria: if the IDN-scale AHZ df at the LCA contrast lands below 4, fall back to path D (WCB) regardless of wall-time/memory.
Concentrated leverage in the IDN unbalanced pattern can collapse the df, and the plan currently has no contingency.
