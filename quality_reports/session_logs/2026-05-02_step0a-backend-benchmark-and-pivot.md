# 2026-05-02---Step 0a backend benchmark and proposed pivot

Mode: Implementation (Step 0a of [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md)).
Continuation of the 2026-05-01 evening sub-session logged in [`2026-05-01_f-adjustment-plan-rev3-via-reg-sandwich.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-01_f-adjustment-plan-rev3-via-reg-sandwich.md).

## Goals

Resolve last night's open question: does Stata `reg_sandwich` Spec A complete in reasonable wall time on TZA covs_trend ($J = 11{,}012$, $N = 29{,}864$), or is the BRL adjustment loop too slow at our cluster counts to use as the production engine?
If too slow, characterize the scaling curve and decide between (a) porting BRL to a faster Mata implementation, (b) calling R `clubSandwich` as the engine, or (c) re-deriving the AHZ p-value directly from `e(b)` / `e(V)` plus per-cluster influence matrices.
Lock locked decision 8 (FE-absorption choice) at the end of Step 0a.

## What got built or changed

New artifacts under [`explorations/python-grc/stata/step0a_fe_absorption/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/):

- [`benchmark_reg_sandwich.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_reg_sandwich.do) and its log/SMCL/CSV outputs: subsamples the TZA covs_trend design at $J \in \{100, 500, 1000, 2000\}$, fits unabsorbed `reg_sandwich`, runs the same $q = 4$ joint test, times each fit.
- [`benchmark_clubsandwich_r.R`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_clubsandwich_r.R) and its CSV output: same protocol against R `clubSandwich::Wald_test(test = "HTZ")` over `vcovCR(type = "CR2")`, including a $J = 5000$ and an attempted $J = 11012$ point.
- [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md): the benchmark numbers, the resulting pivot proposal, and two next-action checks for the user to pre-approve.

Edits to existing files (still uncommitted):

- [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): added the corrigendum follow-up entry locking in the user-approved decision to use the SSC build now and read the 2023 PT corrigendum later.
- [`docs/notes/2026-05-01_step0-ahz-vs-htz.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-01_step0-ahz-vs-htz.md): rewrote the "what this does not prove" and hand-off sections to reflect that the GitHub head matches SSC and that the corrigendum is now a TODO rather than a Step 0a blocker.
- [`quality_reports/session_logs/2026-05-01_f-adjustment-plan-rev3-via-reg-sandwich.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-01_f-adjustment-plan-rev3-via-reg-sandwich.md): appended a sub-session covering the Step 0 verdict, the corrigendum decision, and the FE-absorption A/B in flight.

The benchmark numbers are recorded in the memo and reproduced here for hand-off:

| $J$ (target) | $N$ | Stata `reg_sandwich` wall | R `clubSandwich` wall |
|---:|---:|---:|---:|
| 100 | 272 / 275 | 0.96 s (joint test errored on collinear betas) | error: V not positive definite |
| 500 | 1358 / 1356 | 3.79 s (joint test errored) | error: V not positive definite |
| 1000 | 2747 / 2711 | 90.06 s | 7.58 s |
| 2000 | 5432 / 5429 | 366.06 s | 30.20 s |
| 5000 | -- / 13560 | not run | 217.14 s |
| 11012 | -- / 29864 | extrapolated $\sim$ 3 h | active at 12 GB after 40+ min |

Both backends scale roughly $O(J^2)$ between $J = 1000$ and $J = 5000$.
R is consistently $\sim 12 \times$ faster than Stata at the same $J$.
The small-$J$ errors come from pid resampling that drops some kept switchers, so the joint contrast contains coefficient names no longer in the model; that is a benchmark-script artifact, not a real backend bug.

## Decisions, with the why

Decision: kill Spec A on the full TZA panel rather than wait it out.
Why: the BRL adjustment loop sat at "note: unbalanced omitted because of collinearity" for 17 minutes with no further progress and steady $\sim 140$ MB memory.
Extrapolating the $J = 1000$ and $J = 2000$ Stata times forward predicts $\sim 3$ hours per fit at $J = 11{,}012$, which makes the plan's "$\sim 30$ grid points per inversion $\times 4$ inversions $\times 5$ specs $\times 3$ countries $= 1{,}800$ fits" budget infeasible regardless of how Spec A turns out.
Cleaner to characterize the curve at small $J$ and design around the curve.

Decision: benchmark R `clubSandwich` on the same design rather than only Stata.
Why: R is the natural fallback if Stata is too slow, and the plan rev 3 review explicitly listed "switch to clubSandwich-via-R subprocess" as one of the three escape hatches.
Running the same design through both backends gives a head-to-head curve plus a sanity check that R agrees with Stata where Stata completes ($J \in \{1000, 2000\}$).
The constant 12$\times$ ratio is the strongest evidence that R should be the production engine.

Decision: stop Step 0a as written and write a memo proposing a backend pivot rather than improvising a fix.
Why: switching the production backend is a substantive change to Steps 1, 2, 3, and 5 of the plan, not a tactical tweak.
Per the workflow rules, that requires user review before more code lands.
The "fit once per cell, `Wald_test` per grid $\phi$" pattern is the right architecture if it works, but two open questions (`Wald_test` cost given a cached `vcov`, and IDN-scale memory) need to be answered before rev 4 of the plan is worth writing.

Decision: use TZA covs_trend rather than IDN covs_all for the benchmark.
Why: TZA is the smallest country (29,864 rows vs $\sim 90{,}000$ for IDN), so a single fit completes faster, and the FE-absorption question is about absorbed-vs-unabsorbed numerics on the same alpha + beta structure rather than about controls.
If R completes at TZA scale, IDN is the harder problem and gets its own scoping check.

## Approaches rejected and the reason

Continued waiting on Spec A.
Why dropped: the BRL loop's lack of progress markers makes "still running" indistinguishable from "stuck"; the user's earlier wakeup-at-23:11 decision point passed without completion, and the small-$J$ benchmark gave a cleaner answer than waiting.

Trying `xi: reg_sandwich` instead of pre-built `alpha_d_*` dummies.
Why dropped: numerically identical to the dummy expansion already in the design `.dta`, so it would not change the wall-time problem; only worth revisiting if we go back to Stata as the engine.

Calling `test_sandwich` directly with the LCA contrast at grid $\phi$.
Why dropped (carry-over from the 2026-05-01 sub-session): `test_sandwich` is varlist-only.
The LCA contrast at grid $\phi$ is $r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0$, which is not a varlist-zero on the original design.
The plan would have required either reparametrizing per grid (refit per grid point, $\sim 30 \times$ cost on top of an already $O(J^2)$ engine) or a constraint-matrix interface that `test_sandwich` does not have.
This is the second reason the pivot to R is attractive: R's `Wald_test` accepts an arbitrary constraint matrix natively.

Porting BRL to a faster Mata implementation as the first response.
Why dropped: speculative; before re-implementing the package internals we should know whether R `clubSandwich` (a more recent and actively maintained implementation) gets us where we need to be with less work.
The from-scratch Mata path stays on the backup list but is not the next thing to try.

## Open items and blockers

Backend pivot to R is not yet ratified.
The user needs to review [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md) and decide whether the proposed "fit once per cell, `Wald_test` per grid $\phi$, R as engine" architecture is the path to take into a plan rev 4, or whether to fall back to one of the alternatives (WCB-as-primary; from-scratch BRL).

Two empirical checks should run before plan rev 4 is worth writing:

1. `Wald_test` per-call cost.
   Fit one TZA covs_trend cell in R, time 30 successive `Wald_test` calls at different LCA-style constraint matrices.
   If each call is much smaller than the `vcovCR` cost, the "fit once, test many" pattern is the right architecture.
   $\sim 1$ hour wall.
2. IDN-scale memory.
   Synthesize a $J \approx 30{,}000$, $N \approx 90{,}000$ design.
   Try `vcovCR(..., type = "CR2")` on a 16/32 GB workstation.
   The internal $N \times N$ influence matrix is $\sim 65$ GB at IDN scale, so a naive call almost certainly OOMs; the question is whether `clubSandwich` exposes a sparse or cluster-by-cluster path that avoids it, or whether we need to absorb FE first via `fixest::feols` or compute BRL ourselves.
   $\sim 2$ hours wall.

The R $J = 11{,}012$ benchmark was still running at $\sim 12$ GB memory at the time the memo was written.
If it completes, append the wall-time number to the memo's table; it does not change the recommendation, only sharpens the cost.

Locked decision 8 (FE-absorption: `i.trajectory` vs `absorb(trajectory)`) is not closed.
Spec A on the full TZA panel never completed, so the absorbed-vs-unabsorbed comparison was never made.
This decision is now bundled into the broader backend-pivot question rather than being its own subtask.

The corrigendum TODO is open and tracked in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md); it does not block plan rev 4 because the strong AHZ-vs-HTZ agreement at $J \in \{1000, 2000\}$ in this benchmark is consistent with the 2017 SSC build matching current R `clubSandwich` 0.6.2 on our test geometry.

Uncommitted at session end: the three modified files plus the new memo plus the `step0a_fe_absorption/` artifacts.
The user should decide whether to commit these as a "Step 0a benchmark + proposed pivot" snapshot or wait until plan rev 4 lands and bundle them.

## If you resume

Read [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md) first; it is the canonical statement of where Step 0a stopped and what the proposed pivot is.
Open thread: user has not yet ratified the backend pivot from Stata `reg_sandwich` to R `clubSandwich`.
Next concrete action: run the two empirical checks above (`Wald_test` per-call timing, then IDN-scale memory probe).
If both pass, write plan rev 4 that flips the engine to R and updates Steps 1, 2, 3, and 5; if the memory check fails, plan rev 4 should promote WCB inversion (Step 3.5 in plan rev 3) to the primary path, with from-scratch BRL as the fallback.

State to know: the TZA covs_trend design `.dta` is reproducible from [`build_tza_design.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/build_tza_design.py) and is checked into the explorations folder, so the benchmarks rerun cold; the R `clubSandwich` package was installed on this machine during the session; the SSC `reg_sandwich` package is also installed (version 0.0, dated 02-March-2017).
The corrigendum TODO is logged in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md); the SSC build is the locked production version pending the corrigendum read.

## Post-memo finding: R also fails at TZA full scale

The R $J = 11{,}012$ benchmark finished with NA: `vcovCR` errored or OOM'd at $N = 29{,}864$ on this machine.
The CSV at [`benchmark_clubsandwich_r_out.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_clubsandwich_r_out.csv) records `J=11012, wall=NA, F_stat=NA, ...` for that row.
Memory growth of the Rscript process peaked above 13 GB before failing.

This sharpens the pivot question.
"R as engine, fit once per cell" is not viable at TZA scale on a stock workstation, let alone IDN scale ($N \approx 90{,}000$).
The two paths that survive this finding are:

1. Absorb the trajectory FE first (via `fixest::feols` or `lfe::felm` in R, or `areg` in Stata), then pass the partialled-out model to `vcovCR` / `reg_sandwich`.
This collapses the dense $N \times N$ influence matrix to one of size $N \times K_{\text{free}}$ where $K_{\text{free}} \ll K$ once trajectory FE are absorbed.
The plan's locked decision 8 (FE-absorption choice) becomes "absorbed is required, not optional" under this finding.
2. Implement the BRL adjustment ourselves cluster by cluster, never forming the full influence matrix.
This is the rev 1 path the user originally rejected on novelty grounds; with R `clubSandwich` 0.6.2 as a tractable anchor at smaller $J$ and the Step 0 cross-check confirming the math, the novelty risk is much lower now.

The two next-action benchmarks in the memo should be retargeted accordingly: instead of "fit once per cell with vanilla `vcovCR`", time `vcovCR` after `fixest::feols` partialling, and only after that probe IDN-scale memory.

Two background tasks failed silently after the memo was written (`bvssgzut6`, `blq6e2ph0`); both were wakeup-system housekeeping artifacts unrelated to the benchmarks and can be ignored.

## Picking back up (revised after the post-memo finding)

Read [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md) and this session log; the memo predates the J=11012 OOM finding, so this log carries the more current state.
Open thread: backend pivot is not yet ratified, and the OOM at TZA full scale narrows the viable paths to "absorbed FE first" or "from-scratch BRL".
Next concrete action: try `feols(..., cluster = "pid")` on the TZA covs_trend design and time `vcovCR` after partialling out trajectory; if that brings the wall time and memory into a workable range, plan rev 4 leads with absorbed FE.
State to know: the R 11k benchmark process exited; no background work is in flight.

## Sub-session: backend-choice decision plan, four revision cycles

After the empirical pivot above, the work moved entirely into planning: drafting a decision plan for which CR2/CR3/WCB backend takes the LCA F-adjustment to production, then iterating it through four critic-fixer cycles.
No code ran in this sub-session.

What got produced.

Decision plans, each in [`quality_reports/plans/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/):

- [Rev 1](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md): initial decision plan enumerating paths A--E (Stata absorbed, R absorbed, from-scratch BRL CR2, WCB inversion, hybrid).
- [Rev 2](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev2.md): adds reformulation (4) (recoded-design varlist-zero), corrects path C cost arithmetic, reorders to IDN-first, adds path F (literature scan).
- [Rev 3](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev3.md): adds path G (CR3) parallel to path C; pins recoded-design construction to first-implementer level with `beta_s_*`/`alpha_d_*` variable mapping; adds AHZ df contingency to pass criteria.
- [Rev 4](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment-rev4.md): promotes `summclust` leverage diagnostics to Step 0.5 ahead of backend selection; re-scopes path G to `summclust, vce(jackknife, mse)` as production (not anchor); pins path D to WCU inversion via `boottest, gridpoints(0)`; reframes G+D as the MNW joint pair.

Reviews, each in [`quality_reports/reviews/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/):

- [Rev 1 review](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_backend-choice-plan-review.md): 4 Red, 7 Yellow, 3 Green. Headline finding: the Step 0a benchmark tested a varlist-zero on $\beta_{s_4}\ldots\beta_{s_7}$, NOT the actual LCA contrast that mixes $\alpha_s$ and $\beta_s$. Surfaced reformulation (4) (recoded design $z_{is}^{(\phi_0)} = D_{is} - \phi_0 \cdot \mathbb{1}\{\text{traj}=s\}$) as the missing fourth option for the FE-absorption complication.
- [Rev 2 critique](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev2-six-dimension-critique.md): 6 Red, 11 Yellow, 4 Green. Surfaced per-$\phi$ vcovCR cost undercount (rev 2 listed "30 fits/cell" without multiplying out), missing CR3 path, and recoded-design under-specification.
- [Rev 3 critique](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev3-six-dimension-critique.md): 4 Red, 9 Yellow, 5 Green. Surfaced that `summclust` IS the production CR3 implementation (`vce(jackknife, mse)`), not just an anchor for from-scratch CR3; that `boottest` natively inverts WCU via root-finding without grid-point re-bootstrapping; that leverage diagnostics belong before backend selection per MNW (2023) convention.
- [Rev 4 critique](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-02_rev4-six-dimension-critique.md): 2 Red, 5 Yellow, 6 Green. Surfaced two new Reds rev 4 introduced: the $G^* \ge 30$ kill threshold is fabricated (MNW empirical concern levels are $\sim 6$--$10$, not 30), and `boottest`'s native inversion via `gridpoints(0)` documented for scalar nulls only ($R\beta = r$ with $1 \times k$ row vector $R$), not the multi-parameter joint LCA restriction over scalar $\phi$ that path D actually needs.

Decisions, with the why.

Decision: pivot the rev 1 framing from "Stata vs R" to "how do we compute BRL+AHZ at LCA scale at all".
Why: the user's pushback on the original Stata-to-R pivot was correct---if R OOM'd at TZA, it cannot scale to IDN ($J \approx 30{,}000$). The "12$\times$ faster" speed argument collapses; what survives is only the architectural argument about constraint-matrix flexibility, which is then itself made moot by reformulation (4).

Decision: adopt reformulation (4) as the methodological linchpin of paths A, B, and G.
Why: re-coding the design at each grid $\phi_0$ as $z_{is}^{(\phi_0)} = D_{is} - \phi_0 \cdot \mathbb{1}\{\text{traj}_i = s\}$ turns the LCA test into a varlist-zero on the $z$-coefficients. This is native to `test_sandwich`, compatible with `absorb(trajectory)`, and sidesteps the FE-recovery step that makes absorbed-mode paths painful. The pattern is structurally identical to the Davidson-MacKinnon WCB recoding---it is not novel.

Decision: promote `summclust` leverage and $G^*$ diagnostics to Step 0.5 ahead of backend selection.
Why: the conventional 2026 ordering per MNW (2023) is "diagnose first, choose backend second". If $G^*$ is small at IDN unbalanced, only WCB survives regardless of any backend choice; running the diagnostic first potentially short-circuits Steps 1--4.

Decision: reframe paths G and D as the MNW (2023) joint production-plus-validation pair, not as alternatives.
Why: MNW recommend computing CV3(J) AND wild cluster bootstrap when leverage flags concern; running both is conventional, not "either/or". This answers the symmetric referee questions ("why not CR3", "why not WCB") in one move.

Approaches rejected and the reason.

Stata-to-R production pivot.
Why dropped: R OOM'd at $J = 11{,}012$ on TZA; cannot scale to IDN.

R `Wald_test`'s constraint-matrix interface as the architectural advantage over Stata `test_sandwich`.
Why dropped: once reformulation (4) is in scope, both backends accept varlist-zero contrasts natively; the constraint-matrix argument is moot.

From-scratch CR3 implementation as the default path G.
Why dropped: `summclust, vce(jackknife)` and `vce(jackknife, mse)` IS the production CR3 implementation. From-scratch CR3 enters only as a fallback if `summclust` does not scale to IDN.

The $G^* \ge 30$ kill rule (rev 4).
Why dropped (in proposed rev 5): MNW give no such cutoff; published empirical concern levels are $\sim 6$--$10$. Rev 4's threshold was a number the plan invented and would not survive referee review.

Open items and blockers.

Rev 5 not yet written. The two rev 4 Reds (fabricated $G^* \ge 30$ threshold; over-claimed `boottest` one-pass inversion for multi-parameter joint nulls) need to land in rev 5 before the empirical block runs.
Proposed rev 5 patches sketched in the rev-4 review's "Top recommendations" section: replace $\ge 30$ rule with soft trigger keyed to MNW empirical-concern range; add Step 0.6 (15--30 min `boottest` smoke test for multi-parameter inversion) before relying on path D's one-pass cost; cite MacKinnon (2025) SOTA review at https://arxiv.org/html/2604.02000v1; reframe CV3+CV3J as both reported per MNW; pin WCU variant (WCU13/WCU31/WCU33).

Backend-choice work is not yet committed. Files unstaged at session end:

- 4 plan revisions in [`quality_reports/plans/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/) (rev 1, rev 2, rev 3, rev 4).
- 4 review reports in [`quality_reports/reviews/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/) (rev-1 review, rev-2/3/4 six-dimension critiques).

User declined to commit yet pending a read of rev 4.

## If you resume

Read this session log and the rev-4 critique first.
Open thread: rev 4 has 2 Reds; rev 5 is the focused patch (described in the rev-4 critique's top recommendations section).
Next concrete action depends on whether rev 5 is written first or whether the empirical block proceeds with rev-4-with-known-Reds.
The first concrete experiment is unchanged across rev 3, rev 4, and (proposed) rev 5: run `summclust` on TZA full-scale and on IDN unbalanced, report $G^*$, partial leverage, influence, cluster-size moments. That single 30--60 minute `summclust` invocation is the first action regardless of rev 5's specifics.

If $G^*$ comes back small ($\sim 6$--$10$) at IDN, the work routes to path D (WCU bootstrap) and the rev-4 Red on `boottest`'s multi-parameter inversion becomes load-bearing immediately---run the Step 0.6 `boottest` smoke test before committing path D's per-cell cost arithmetic.
If $G^*$ comes back large ($\gg 10$), the joint G+D pair is the production answer and the path-D Red is less urgent (CR3 is the headline; WCB is a robustness row at relaxed wall budget).

State to know.

The benchmark artifacts at [`explorations/python-grc/stata/step0a_fe_absorption/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/) are reproducible cold from the design `.dta` plus the two benchmark scripts.
The R `clubSandwich` 0.6.2 install on this machine has not been tested for corrigendum incorporation; that read is still TODO.
`summclust` has NOT been installed on this machine yet; `ssc install summclust` is the first command of the next session.
The recoded-design construction is pinned to first-implementer level in rev 3 onward (lines 90--114 of rev 4); the variable mapping is `z_{is}^{(\phi_0)} = beta_s_{s} - \phi_0 \cdot alpha_d_{s}` for $s \in S_R \setminus \{\underline{d}_0\}$, with base trajectories pinned per country/spec (consumption: $\underline{d}_0 = 2$; IDN income: 16; TZA income: 5; CHN income: TBD).
