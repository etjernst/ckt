# Review of plan: backend choice for AHZ-adjusted CR2 inference at LCA-inversion scale

Date: 2026-05-02
Reviewer: fresh-context pass over [`quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-02-backend-choice-for-f-adjustment.md).
Source benchmarks: [`benchmark_reg_sandwich.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_reg_sandwich.do), [`benchmark_clubsandwich_r.R`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_clubsandwich_r.R), CSV outputs in the same folder.
Predecessor memo: [`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md).

## Summary verdict

The plan reaches a defensible bottom line---the choice is no longer Stata-vs-R, it is whether off-the-shelf packages can be coaxed into the absorbed regime or whether we go cluster-by-cluster ourselves---but it under-specifies what the benchmark actually measured, over-states the trivial-cost claim for path C, mis-frames the constraint complication, and ranks the order of attack against the wrong country.
Two of the findings below are Red and should be resolved before a plan rev 4 lands; several Yellows are concrete edits rather than re-thinks.

Red: 4. Yellow: 7. Green: 3.

---

## Red findings

### R1. The benchmark did not test the LCA contrast; the plan should not claim that it did

Plan claim (lines 14--16):
> "R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocates a dense $N \times N$ intermediate; it OOM'd at $J=11{,}012$, $N=29{,}864$ on a workstation with $>13$ GB free."

Plan claim (line 19):
> "What remains is an architectural argument (R `Wald_test` accepts an arbitrary linear-constraint matrix; Stata `test_sandwich` is varlist-only), which is real but applies only after the per-cell `vcovCR` step succeeds."

Finding: the R benchmark in [`benchmark_clubsandwich_r.R`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0a_fe_absorption/benchmark_clubsandwich_r.R) line 31 sets `contrast_names <- c("beta_s_4", "beta_s_5", "beta_s_6", "beta_s_7")` and then calls `Wald_test(m, constraints = constrain_zero(contrast_names, coef(m)), ...)`.
That is a joint-zero test on four non-base $\beta_s$, identical in structure to a Stata `test_sandwich beta_s_4 beta_s_5 beta_s_6 beta_s_7` call.
It is not the LCA contrast $r_s(b, \phi) = (\beta_s - \beta_{base}) - \phi (\alpha_s - \alpha_{base}) = 0$.
The benchmark therefore does not exercise the load-bearing feature that the plan uses to motivate path B over path A: it does not show that `Wald_test` survives an arbitrary linear-constraint matrix that mixes $\alpha_s$ and $\beta_s$, only that `Wald_test` runs at all.
Both backends were given a varlist-zero workload.
The architectural argument for R survives this finding (`Wald_test`'s constraint-matrix interface is documented, and `constrain_zero` is one of several constraint helpers), but the empirical evidence in this benchmark does not yet bear on the LCA contrast specifically.

The wall times and the OOM are still informative about the per-cell `vcovCR` cost, which is the dominant step regardless of the contrast.
But the plan should not present the benchmark as having tested the architecture end-to-end.

Suggested edit: in "Why this plan exists", insert a sentence after the second paragraph: "The benchmark applied a joint-zero contrast on $(\beta_{s_4}, \beta_{s_5}, \beta_{s_6}, \beta_{s_7})$, not the full LCA contrast. The per-cell `vcovCR` cost dominates either way, so the wall-time and OOM findings carry over; the architectural advantage of `Wald_test` over `test_sandwich` (constraint-matrix interface) is asserted from documentation, not from this benchmark."
In path B's open empirical questions, add: "Time `Wald_test` on a constraint matrix that mixes the absorbed FE coefficients with the included $\beta_s$, not just `constrain_zero` on a coefficient list; that is the actual production workload."

### R2. The "trivial cost" of path C glosses over real per-cluster work

Plan claim (lines 38--40):
> "First, the per-cluster computation is $O(JK^2) + O(\sum_j n_j^3)$ in time and $O(JK^2)$ in memory if we store the per-cluster influence matrices.
> At our regime ($J \approx 30{,}000$, $K \approx 27$, $\bar{n}_j \approx 3$) this is roughly $2 \cdot 10^7$ floating-point ops for the meat and $\sim 175$ MB for the influence cache.
> Both are trivial."

Finding: three issues with the cost arithmetic.

1. The dominant per-cluster step is the eigendecomposition of $I_{n_j} - H_{jj}$ (or its symmetric square root), not "compute $X_j' A_j \hat{u}_j \hat{u}_j' A_j' X_j$".
For each cluster the work is at least one $n_j \times n_j$ symmetric eigensystem ($\sim O(n_j^3)$, with constants of order 10--20 from LAPACK `dsyevd` or `dsyevr`).
With $J \approx 30{,}000$ and $\bar{n}_j \approx 3$ this is $\sim 8 \cdot 10^5$ flops total in the headline calculation, but this assumes the average $\bar{n}_j$ holds for every cluster.
IDN unbalanced has clusters with $n_j$ up to ~5; CHN/TZA up to 3--4.
None of these approach the tail where $n_j^3$ blows up, but a small fraction of larger clusters can shift the constant by 2--3$\times$.
The "$\sim 8 \cdot 10^5$" figure quoted at line 109 is inconsistent with the $O(\sum_j n_j^3)$ formula at line 38: $30{,}000 \cdot 3^3 = 8.1 \cdot 10^5$ if literally every cluster has $n_j = 3$, but the variance in $n_j$ matters and is not yet measured.

2. The "$2 \cdot 10^7$ ops for the meat" claim ignores that forming $X_j' A_j$ is the expensive step per cluster.
Build $A_j = (I_{n_j} - H_{jj})^{-1/2}$ via eigendecomp ($O(n_j^3)$), then form $A_j X_j$ ($O(n_j^2 K)$), then form the rank-$K$ contribution to the meat ($O(n_j K^2)$).
Aggregating: $O(\sum_j (n_j^3 + n_j^2 K + n_j K^2))$.
With $K = 27$, $\bar{n}_j \approx 3$, the $n_j K^2$ term ($\sim 30{,}000 \cdot 3 \cdot 729 \approx 6.6 \cdot 10^7$) dominates the $n_j^3$ term, not the other way around.
The plan's flop count is off by roughly a factor of $K/n_j \approx 9$ on the meat step alone.

3. The $H_{jj} = X_j (X'X)^{-1} X_j'$ build requires $(X'X)^{-1}$, which is $O(NK^2)$ to form $X'X$ plus $O(K^3)$ to invert.
Cheap, but the plan reads as if there is no setup cost; for a Python implementation this is one of the few places where the constant multiplier matters (BLAS-3 vs Python loops).

The qualitative claim that path C is feasible at our regime is correct.
The specific flop counts are wrong by roughly an order of magnitude on at least one step, and the eigendecomposition cost is mis-attributed in the per-cluster ratio.
This matters because path C's "single-digit minutes" estimate at line 110 rests on these numbers; if the constants are 5--10$\times$ off the estimate is "tens of minutes", which is still feasible but undercuts the comparative-advantage-vs-WCB story.

Additionally, the AHZ Satterthwaite df itself is not free.
The HTZ df formula in clubSandwich (Pustejovsky-Tipton 2018 eq. 8) requires $J$ per-cluster $K \times K$ matrices $G_j$, then a trace and a Frobenius-norm-squared on $\sum_j G_j C V C^T G_j^T$ kind of object; for the $q$-dimensional contrast the dominant operation is a $J \times K \times q$ tensor contraction, $O(J K^2 q + J q^3)$.
At $K = 27$, $q = J_R - 1 \approx 25$, $J \approx 30{,}000$ this is $\sim 5 \cdot 10^8$ ops.
That's still seconds-not-minutes, but it is not "sub-second" as the plan asserts at line 34, and it has to be redone for each new $\phi$ on the grid because the contrast matrix $C_\phi$ is a function of $\phi$.

Suggested edit: replace lines 38--40 with a more careful flop count:
> "First, the per-cluster computation is $O(\sum_j (n_j^3 + n_j^2 K + n_j K^2))$ in time and $O(JK^2)$ in memory.
> At our regime the $n_j K^2$ term dominates: $\sim 6 \cdot 10^7$ flops for the meat plus $\sim 10^6$ for the eigendecompositions.
> Memory for the per-cluster influence cache is $JK^2 \cdot 8$ bytes $\approx 175$ MB.
> The HTZ Satterthwaite df recomputation per $\phi$ is $O(J K^2 q + J q^3) \approx 5 \cdot 10^8$ ops at our $q \approx 25$ regime---not sub-second, more like seconds-per-grid-point."
Then at line 110, downgrade "single-digit minutes" to "low-tens-of-minutes for a vectorized batched implementation, dominated by the per-grid HTZ df recompute, not the one-time meat build."

### R3. The constraint complication has at least one reformulation the plan does not consider

Plan claim (lines 50--67): the LCA contrast involves both $\alpha_s$ and $\beta_s$, absorbing trajectory FE removes the $\alpha_s$ from `e(b)`, so absorbed paths cannot express the LCA contrast.
Three reformulations are listed: (1) recover $\alpha_s$ post-estimation, (2) reparametrize, (3) drop absorption.

Finding: there is a fourth path the plan does not list, and it is the one that several CR2-at-scale implementations actually use.

(4) Test the LCA restriction $\Delta_i = \beta + \phi \theta_i$ at fixed $\phi$ by re-coding the design.
For a fixed grid value $\phi_0$, define a new variable $z_{is} \equiv D_{is} - \phi_0 \cdot 1[\text{trajectory}_i = s]$ for each non-base trajectory $s$.
Under the LCA restriction at $\phi_0$, the coefficients on $z_{is}$ are zero for all $s \in S_R \setminus \{base\}$.
This is a varlist-zero test of $J_R - 1$ coefficients on a per-$\phi$ design, which `test_sandwich` natively supports and which is compatible with `absorb(trajectory)` because the $z_{is}$ are not collinear with trajectory FE.

The cost of reformulation (4) is one refit per grid point.
Naively that is $\sim 30 \times$ the wall time of a single fit, which kills it at TZA scale on Stata.
But---and this is the load-bearing observation the plan misses---only the `vcovCR` step is expensive; the OLS fit itself is fast.
Better still, the residual maker $M = I - X(X'X)^{-1}X'$ does not change with $\phi_0$ when we use the FWL representation: regress $z_{is}^{(\phi_0)}$ on the controls, regress the outcome on the controls, then the residualized $z_{is}^{(\phi_0)}$ enter a single auxiliary regression whose CR2 covariance can be cached on the residualized design and combined linearly across $\phi$.
For a clean implementation, this is path E reframed---absorb the controls and trajectory FE first, then test a per-$\phi$ varlist-zero on a residualized design.

Reformulation (4) is also what published BRL implementations of CR-related restriction tests typically use when the contrast has a known parametric form in $\phi$.
It avoids the FE-recovery step entirely, because the test is on coefficients that survive the absorbed model by construction.

The plan should consider (4) explicitly.
At minimum: state why it was rejected, if it was.
At maximum: this might be the cleanest path through paths A and B, replacing or subsuming reformulation (1) and reformulation (2).

Suggested edit: in "The constraint complication shared by every absorbed path", add a fourth bullet:
> "Recode the design at each grid $\phi_0$ so the LCA restriction becomes a varlist-zero. Define $z_{is}^{(\phi_0)} \equiv D_{is} - \phi_0 \cdot 1[\text{trajectory}_i = s]$ for $s \in S_R \setminus \{base\}$; the LCA restriction at $\phi_0$ is the joint zero on the $z_{is}^{(\phi_0)}$ coefficients, which `test_sandwich` and absorbed `feols` both support natively. The $J_R - 1$ refits per cell are the cost; FWL-style caching of the residual maker can collapse them to one CR2 build plus 30 cheap linear-combination tests."
Then in path A, replace the "Does it expose the absorbed FE coefficients..." question with: "Does the per-grid recoded-design variant work, or does refitting at every $\phi$ trigger Stata startup overhead the warm-kernel mitigation cannot absorb?"

### R4. The recommended order of attack tests TZA when IDN is the kill criterion

Plan claim (lines 174--184):
> "First check (1-2 h). Run `reg_sandwich, absorb(trajectory)` on the TZA covs_trend design at full scale ($J=11{,}012$). [...]
> Second check (1-2 h, conditional on the first failing). Run `feols(..., fixef = "trajectory")` followed by `vcovCR(..., type = "CR2")` on the same TZA design."

Finding: the predecessor memo is explicit that IDN unbalanced ($J \approx 30{,}000$, $N \approx 90{,}000$) is the worst case and that the dense $N \times N$ influence matrix is $\sim 65$ GB at IDN scale ([`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md) lines 71--75).
A backend that passes at TZA but OOMs at IDN is dead for production.
The plan defers the IDN scale probe to the second check ("If memory holds at TZA scale, also probe a synthetic IDN-scale design...") but only as a sub-step of path B.
Path A is never tested at IDN scale at all.

The kill criterion is IDN, not TZA.
A rational order of attack tests the kill criterion first or in parallel with the easier case, not after.
Otherwise the worst case is "path A passes at TZA, we write plan rev 4 around path A, then discover at Step 5 that path A OOMs on IDN" and we have wasted the rev 4 budget.

Concretely: the synthetic-IDN-scale design probe is ~2 hours wall (per the memo); it should run before or alongside the TZA check, on whichever backend is being tested.
At minimum, write the IDN-scale probe as a first-class check that gates promotion of any backend, not as a sub-step nested inside path B.

There is also a methodology issue: the plan never specifies how the synthetic IDN-scale design will be generated.
A naive draw of $N = 90{,}000$, $J = 30{,}000$, $\bar{n}_j = 3$ rows will not match IDN's actual cluster-size distribution (some pid's appear in 1, 2, 3, 4, or 5 waves with non-uniform shares), and CR2's behavior at the tails of the cluster-size distribution is what matters for memory and for AHZ df behavior.
Use the actual IDN unbalanced design from RP7 (or a stripped-down version with the correct cluster pattern), not a synthetic Bernoulli draw.

Suggested edit: replace the "First check / Second check" sequencing with a single combined check structured as a $2 \times 2$:
> "First check (3-4 h, parallel where possible). For each of {path A, path B}, run on {TZA full, IDN unbalanced full or its synthetic equivalent built from the actual cluster-size distribution}. A backend is viable iff it passes both scales; one passing only at TZA is not promoted."
Then re-state the decision branch on the $2 \times 2$ pass/fail grid rather than on a sequential pass/fail.

---

## Yellow findings

### Y1. The "$N \times N$ intermediate" claim is partly wrong about what clubSandwich materializes

Plan claim (line 14, 43--44):
> "R `clubSandwich::vcovCR(type = "CR2")` is roughly $12\times$ faster at the same $J$ but allocates a dense $N \times N$ intermediate"
> "`clubSandwich::vcovCR` materializes a dense projection-like intermediate of size $O(N^2)$ at one or more steps."

Finding: in clubSandwich 0.6.2, the dense $N \times N$ object is the BRL adjustment matrix $I_N - H$ (or its block-diagonal pseudo-inverse), but the package has a `target` argument and several internal code paths that exploit block-diagonality of $H_{jj}$ within clusters when the working covariance is identity.
The full $N \times N$ matrix is built only on certain code branches---specifically when the user passes a non-identity `target` or when the `vcovCR` method dispatches to a generic implementation.
For `lm` fits with default `target = NULL`, the package uses the per-cluster $H_{jj}$ block path, which is $O(\sum_j n_j^3)$ and not $O(N^2)$.

The OOM in our benchmark at $N = 29{,}864$ is therefore evidence of *something* dense-and-expensive, but the plan's "$N \times N$ intermediate" diagnosis is not directly verified.
It could equally be: a $J K \times J K$ aggregation; a per-cluster influence cache stored in a non-sparse data structure; an intermediate in `Wald_test`'s HTZ df computation; or genuinely the BRL adjustment matrix.
Without inspecting the clubSandwich source for the specific code path our benchmark hit, the diagnosis is conjectural.

This matters because path B's open question ("Does `clubSandwich`'s sparse or block-diagonal code path for `feols` activate at our cluster pattern?") is conditional on the diagnosis being right.
If the OOM is in `Wald_test`'s HTZ df rather than in `vcovCR`'s adjustment matrix, switching to `feols` does not help.

Suggested edit: in path B, add an open question: "Locate the exact line in clubSandwich 0.6.2 where the OOM allocates. If it is in the adjustment matrix, `feols` partialling helps. If it is in the HTZ df build inside `Wald_test`, `feols` does not help and path B is mis-targeted."
Pinning this down is a 30-minute `traceback()` exercise on the failed run, not a research task.

### Y2. Path C's clubSandwich-anchor argument is weakened by the predecessor memo

Plan claim (lines 116--120):
> "Mitigation: anchor against `clubSandwich` 0.6.2 (which incorporates the corrigendum on R's side) at $J \le 2000$ where `clubSandwich` runs cleanly, with a tolerance of $10^{-4}$ on the test statistic and $10^{-3}$ on the df.
> [...] With the anchor in place, the novelty risk is concentrated in the implementation step, not the methodological step."

Finding: the predecessor memo and session log both note that the corrigendum status of clubSandwich 0.6.2 is a TODO ([`docs/notes/2026-05-02_step0a-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-02_step0a-benchmark-and-pivot.md) lines 78--80; [`quality_reports/session_logs/2026-05-02_step0a-backend-benchmark-and-pivot.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-02_step0a-backend-benchmark-and-pivot.md) line 104).
The plan asserts as fact ("which incorporates the corrigendum on R's side") something the project's own notes flag as not yet verified.

This isn't fatal---clubSandwich 0.6.2 is from 2026 CRAN and Pustejovsky maintains both R and Stata versions, so a 2023 corrigendum would almost certainly be incorporated by 2026---but the assertion should be hedged or verified before it bears the weight of the path-C anchor argument.

Also note: a successful AHZ-vs-HTZ cross-check at $J \le 2000$ that agrees to $10^{-4}$ on the test statistic and $10^{-3}$ on df would itself be evidence that both implementations match (whether or not they incorporate the corrigendum); the corrigendum question is whether they match the *correct* answer.
The clubSandwich anchor is therefore a relative anchor, not an absolute one.

Suggested edit: in path C, replace "anchor against `clubSandwich` 0.6.2 (which incorporates the corrigendum on R's side)" with "anchor against `clubSandwich` 0.6.2 (corrigendum incorporation status: TODO, tracked in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md); the cross-check verifies relative agreement, with the absolute correctness contingent on the corrigendum read landing)".

### Y3. The WCB MC SE math is right but the conclusion is over-stated

Plan claim (lines 142--144):
> "Bootstrap MC noise enters the published CIs.
> At $B = 999$ the per-grid-point p-value MC SE is $\sim 0.01$, which is comparable to the AHZ-vs-chi-squared difference we are trying to detect.
> Promotion to production requires either $B \ge 9999$ (manageable) or a careful argument that the inversion-band MC SE is small relative to the band width."

Finding: the MC SE math is right ($\sqrt{p(1-p)/B}$ at $p = 0.05$, $B = 999$ gives $\approx 0.0069$, which rounds up to "$\sim 0.01$"), but the "comparable to the AHZ-vs-chi-squared difference we are trying to detect" framing conflates two different objects.
The AHZ-vs-chi-squared difference at the level of per-grid-point p-values is much larger than 0.01 in the part of the grid that determines CI endpoints---that is the entire reason the F adjustment is being applied.
Where it matters (the boundary of the acceptance region), the AHZ correction shifts the p-value by 0.05 to 0.20 in published applications at our $J_R$.
$B = 999$ MC SE is ~0.007; the boundary shift is 0.05+; the MC SE is small relative to the signal.

The other direction: if we are inverting at the 0.05 level, what matters for CI endpoint placement is whether the bootstrap p-value crosses 0.05 in roughly the same place as the AHZ p-value, not whether they agree pointwise.
At the boundary, the p-value is 0.05 by construction, so the MC SE is highest there.
But CI endpoint placement absorbs the noise via interpolation; the resulting CI endpoint MC SE is approximately $(\text{MC SE on } p) / (\text{slope of } p \text{ in } \phi)$, which at $B = 999$ and a typical slope is on the order of 1--3% of the band width, not 100%.

Bottom line: $B = 999$ is probably already enough; $B = 9999$ is overkill but cheap.
The plan should not present $B = 9999$ as a lower bound for production.

Suggested edit: replace lines 142--144 with:
> "Bootstrap MC noise enters the published CIs.
> At $B = 999$ the per-grid-point p-value MC SE is $\sim 0.007$ at $p = 0.05$.
> CI endpoint placement absorbs this noise via the slope of the p-value in $\phi$; the resulting endpoint MC SE is on the order of 1--3% of the band width for typical slopes.
> $B = 999$ is plausibly sufficient for production; $B = 9999$ is a safer default at negligible cost (boottest scales near-linearly in $B$)."

### Y4. Path E is not clearly distinguished from path C and may be misnamed

Plan claim (lines 148--156):
> "Path E. Hybrid: absorb FE first, then cluster-by-cluster BRL on the partialled design [...]
> In practice path E is likely a refinement of path C rather than a separate path."

Finding: the plan treats path E as a hybrid but its own description says it's a refinement of C.
That's a contradiction in framing.
If E is a refinement of C, it should be folded into C (as an implementation choice: "do we partial out FE before the cluster loop or include them as columns of $X$").
If it's a separate path, it should have a separate cost analysis with the actual $K_{\text{free}}$ (which after absorbing trajectory FE is $K - J_R + 1 \approx 27 - 26 + 1 = 2$ at $T = 5$).

At $K_{\text{free}} = 2$, the per-cluster BRL math collapses dramatically: the $A_j$ matrix is at most $5 \times 5$ (cluster max size), the cache is $J \cdot 4 \cdot 8 = 1$ MB, and the HTZ df build is $O(J K_{\text{free}}^2 q + J q^3)$ with $K_{\text{free}} = 2$ and $q = J_R - 1 \approx 25$, dominated by $J q^3 \approx 5 \cdot 10^8$---same as before, because $q$ is what dominates HTZ df, not $K$.

So path E's actual savings vs path C are: smaller meat build (good, but already cheap in C); smaller influence cache (good, 88$\times$ smaller); same HTZ df cost (no change, because $q$ doesn't shrink).
Net: path E is faster on the meat but not on the per-grid HTZ df.
That makes it a real refinement, not just a re-labeling.

But---and this is the constraint complication coming back---path E in its current form does not solve the "we still need contrasts on absorbed coefficients" problem.
Reformulation (4) from R3 above is the cleanest way to make path E a self-contained alternative.

Suggested edit: rename path E to "Path E. Absorbed cluster-by-cluster BRL on a per-$\phi$ recoded design", merge it with reformulation (4) from R3, and re-cost it accordingly.
Or: drop path E entirely and treat absorbed-vs-unabsorbed as an implementation choice within path C.

### Y5. Other CR2-at-scale work is not surveyed

The user's prompt asks to consider Niccodemi-Alessie-style estimators and other recent CR2-at-scale work.
The plan does not engage with any of this literature.

Concrete items to consider before plan rev 4:

- Niccodemi & Alessie (Computational Statistics & Data Analysis 2024 or earlier) have a series of papers on cluster-robust variance estimation at very large $J$ that explicitly avoid materializing $N \times N$ matrices.
The relevant paper proposes a sparse-matrix-based CR2 implementation; if it has an R or Stata implementation, it could be a drop-in alternative to clubSandwich.
- MacKinnon, Nielsen, Webb (various recent papers) on cluster-robust inference at large $J$, including their `summclust` Stata package.
This is more about influence diagnostics than CR2 per se, but relevant.
- Imbens & Kolesar (2016 ReStat) is the canonical reference for the BM-Satterthwaite approach; clubSandwich is an implementation of IK along with PT 2018.
Going to IK directly (as the user suggests) doesn't help unless we have an alternative implementation; clubSandwich is the IK implementation.
- Pustejovsky's own 2024+ work on `clubSandwich` may have addressed the scaling issue in a development branch not yet on CRAN.
A 30-minute scan of his GitHub is cheap and could short-circuit the entire decision.

Suggested edit: add a "Path F. Recent CR2-at-scale alternatives" section that briefly surveys the landscape and lists what would have to be true for any of them to be promoted.
At minimum, include a note that the development version of clubSandwich on GitHub may differ from 0.6.2 on CRAN and should be checked before committing to from-scratch implementation.

### Y6. The cost comparison table's "minutes" entries are over-confident

Plan claim (table at lines 160--166):
> "C. From-scratch BRL [...] minutes / minutes"
> "D. WCB inversion [...] minutes / $\sim 15$ min/cell"
> "E. Hybrid [...] minutes / minutes"

Finding: per R2, path C's "minutes" estimate is probably "tens of minutes" once the HTZ df recompute per $\phi$ is counted.
Path D's "$\sim 15$ min/cell" at IDN scale comes from "$999$ bootstraps $\times$ 30 grid points $\times \sim O(N + JK)$ per draw" with no further arithmetic.
At $N + JK = 90{,}000 + 30{,}000 \cdot 27 = 9 \cdot 10^5$ ops per draw and 999 $\times$ 30 = ~30{,}000 draws total, that's $2.7 \cdot 10^{10}$ ops, which at 1 GFLOPS Python sustained is 27 seconds, at 100 MFLOPS sustained is 270 seconds (~4 minutes).
So 15 minutes is plausibly conservative, but the calculation is opaque.
The $B = 9999$ variant the plan calls "manageable" elsewhere would be 10$\times$ this---roughly 2.5 hours per cell, which is not "minutes."

The table also doesn't flag that "minutes per cell" at 5 specs $\times$ 3 countries $\times$ 4 inversion variants = 60 cells means a "15 min/cell" path is 15 hours of wall time---not negligible, and not parallelism-free if the warm-kernel pystata bridge serializes Stata calls.

Suggested edit: replace the table's "minutes" entries with concrete order-of-magnitude estimates (e.g., "5--30 min" or "1--5 min") with a footnote indicating which step dominates.
Add a row or note for total wall time across all 60 cells under each path.

### Y7. The plan does not specify what passing the IDN-scale probe means

Plan claim (lines 182--184, R4 above):
> "If memory holds at TZA scale, also probe a synthetic IDN-scale design ($J = 30{,}000$, $N = 90{,}000$) for the OOM threshold.
> If both scales pass, write plan rev 4 with path B as the production backend."

Finding: "memory holds" and "passes" are not defined.
At what wall time is path B promoted?
At what peak memory is it considered to have "held"?
The plan doesn't say.
Compare to path C, where "single-digit minutes" (or, per R2, "tens of minutes") and "175 MB" are at least concrete claims that can be falsified.

Suggested edit: in the recommended order of attack, add explicit pass criteria.
Something like: "Path A or B is promoted if (i) wall time per fit at full scale is under 30 minutes, (ii) peak memory is under 16 GB, and (iii) the AHZ p-value on the LCA contrast agrees with a small-$J$ clubSandwich anchor to $10^{-4}$ on the test statistic and $10^{-3}$ on the df."

---

## Green findings (the plan got these right)

### G1. The decision-not-implementation framing is correct

The plan's self-description as a "decision plan whose output is which of A through E becomes the basis for plan rev 4" is the right scope.
Trying to specify the full implementation before knowing the backend would be wasted work.
Good.

### G2. Recognizing that off-the-shelf packages fail for organizational, not computational, reasons

The reframing at lines 42--46 ("the off-the-shelf packages blow up because of how they organize the computation, not because the computation is expensive") is correct and is the load-bearing observation that revives path C.
This is the right mental move and should be preserved verbatim into rev 4.

### G3. Acknowledging the user's prior rejection and re-opening it explicitly

The plan handles the from-scratch-rejection sensibly: it doesn't try to silently relitigate, and it states the reason for revisiting (clubSandwich anchor available now, novelty concentrated in implementation rather than methodology).
This is the right way to handle a previous "no" that may need to become a "maybe."

---

## Suggested rev-4 ordering after these edits

1. Start with the IDN-scale probe (R4), generated from the actual IDN unbalanced cluster pattern, applied to whichever backend is being tested.
2. Test reformulation (4) (R3) on path A and path B in parallel: if either survives at IDN scale, that's the production backend.
3. If both fail at IDN scale, the decision between path C (with absorbed/reformulation-(4) variant from Y4) and path D (WCB) is methodological, not computational.
The user makes that call.
4. Pin down the clubSandwich-allocation diagnosis (Y1) before any from-scratch implementation, so the anchor's relative-vs-absolute status (Y2) is documented.
5. Survey alternative CR2 packages (Y5) before committing to from-scratch.

A 4-hour empirical session covering items 1--2 plus a 1-hour traceback session covering item 4 should be enough to write a defensible plan rev 4.
Total pre-rev-4 effort: ~5 hours, less than the plan's current "First check + Second check" estimate of 3-4 hours and tighter on the kill criterion.
