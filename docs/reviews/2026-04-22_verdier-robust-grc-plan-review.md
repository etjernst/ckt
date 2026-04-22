# Plan review: Verdier robust GRC implementation

**Date:** 2026-04-22
**Plan reviewed:** [`docs/plans/2026-04-22-verdier-robust-grc.md`](file:///C:/git/ckt/.claude/worktrees/verdier/docs/plans/2026-04-22-verdier-robust-grc.md)
**Reviewer role:** Applied econometrics methodology specialist (fresh-context subagent)
**Method:** `review-plan` skill, standard depth (2 web searches on Verdier 2020 + cluster-robust inference best practices)

## Best-practice context

- Verdier (2020) robust extrapolation requires (i) a region intercept $\beta(v_i)$ in the LCA, (ii) clustering of inference at the same $v_i$ used for the intercept, and (iii) an LCA-overid test that distinguishes failure-of-LCA from failure-of-i.i.d. The plan engages all three but conflates "intercept saturation" with "instrument interaction."
- With ~25 clusters, naive cluster-robust SEs are downward-biased ~10--30%. With 2 clusters (CHN hukou) analytical CR SEs are not defined; wild-cluster bootstrap (Webb weights, 6-point, kurtosis correction) with `boottest` is required, and even then $T(G-1)$ critical values must be used.
- Stata `gmm` parameter naming with factor-variable interactions (`{mu:i.vfirst#switcher_s}`) is brittle; for nontrivial $|V|\times|S|$ counts, manual dummy expansion plus one parameter per $(v,s)$ cell is the only reliable route. Each empty $(v,s)$ cell will silently break parameter identification unless explicitly skipped.
- Identification of $\phi$ comes from within-$v$ switcher variation. A cluster contributing zero switchers contributes only to fixed-effect absorption, not to $\phi$. The cluster-weighted aggregator for $\hat\Delta_{d_N}$ should be defined on the support set, with the un-extrapolated mass disclosed in every table.
- "Pro-poor" interpretation rests on the sign and stability of $\phi$ across $v_i$ partitions. The robust spec subsumes the simple spec only if $\beta(v)$ is uncorrelated with $\bar\theta_v$; this is testable via a Wald test that all $\beta(v)$ collapse to a constant.

## Strengths

1. Phasing puts the smallest country (TZA, 26 clusters, 100% support) first, where convergence problems are least likely; this is the right order.
2. Spec/plan separate "what" from "how"; existing `run_grc` is preserved, allowing direct simple-vs-robust comparison without retracing data flow.
3. Cluster-support diagnostics required at the top of every call (S6) --- the right anti-footgun.
4. Naming convention `grc_robust_{country}_{spec}_{vindex}.ster` is unambiguous and survives multi-spec rollout.
5. Plan flags the 2-cluster CHN-hukou problem and routes to `boottest`.
6. Plan correctly keeps $\underline d_0$ globally fixed (M10) --- necessary for cross-cluster comparability.

## Weaknesses and gaps

### Red (will likely cause failure if unaddressed)

**R1. LCA-overid moment specification is not specified** --- §4.1 / S1
Plan defers $\eta_s$ moment construction to "VV's appendix Eq. F" with "transcribe carefully and review by eye." This is the single most important diagnostic in the entire deliverable: it tells the referee whether the LCA holds in either spec. Leaving it as an unverified transcription invites a wrong test that nobody catches.
**Fix:** Before P1 begins, write the $\eta_s$ moments out longhand in a methodology note (`docs/reviews/2026-04-XX_lca-overid-derivation.md`): for each non-base switcher $s$, give (a) the conditional moment, (b) the instrument set that identifies it under the null, (c) the dimension count ($|S|-1$ in the simple, $(|S|-1)\times|V|$ or $|S|-1$ in the robust depending on whether $\eta_s$ varies with $v$), (d) a worked Stata expression. Human approval before coding.

**R2. Saturated joint GMM with $|D|\times|V|$ free $\mu$'s is computationally infeasible for CHN and statistically wasteful everywhere** --- §2.4 step 4, §8 risks
For CHN this is up to 406 free $\mu$'s, plus $|S|\times|V|$ instrument interactions, plus covariates. Stata `gmm` with `quickderivatives` and a parameter vector this size, initialized from cluster-OLS, will not converge reliably. Verdier's robust extrapolation does NOT require joint estimation of all $\mu_{\underline d, v}$ as free GMM parameters --- it can be implemented by partialling out $v_i$ fixed effects from $y_{it}$ and from each switcher dummy and re-running the existing GMM on the within-transformed data with $v$-clustered SEs. Mathematically equivalent under linearity of $\beta(v)$, with a tiny fraction of the parameter count.
**Fix:** Before P1, add a §2.4.0 step deriving the within-cluster-demeaned representation. Implement that as primary. Keep the saturated version as a fallback for TZA only, as a numerical check.

**R3. Instrument vector explodes and is mis-specified** --- §2.4 step 5
`i.vfirst#(never switcher_* choice always_choice switcher_*_choice)` produces $|V| \times (|S|+3)$ instruments. For CHN that is $29 \times 17 \approx 493$ instruments against ~10 free GMM parameters (after the within transformation, or ~420 in the saturated version). Hansen $J$ becomes mechanically near-zero from instrument proliferation --- useless as a diagnostic; 2-step GMM weighting matrices become near-singular. CKT identification needs only the original CKT instrument set plus $v$ dummies (or the within transformation), not full $v$-interactions.
**Fix:** Restrict instruments to (a) original instruments plus (b) $v$ dummies as exogenous regressors absorbed into $x_{it}'\gamma$, OR (c) the within-$v$ demeaned analogues. Document instrument count in P1's verification gate; bail if instrument:parameter ratio exceeds 3.

**R4. `vce(cluster vfirst)` with 13--19 clusters needs WCB, not just for CHN-hukou** --- §2.4 step 5, S2
Plan only invokes `boottest` for CHN hukou ($G=2$); IDN and TZA primary specs (13 and 19 clusters) are also at risk of substantial CR-SE bias and need wild-cluster-bootstrap inference at minimum for $\phi$. With $G=13$, Bell-McCaffrey or Imbens-Kolesar small-sample CR2 SEs differ materially from CR1.
**Fix:** Apply `boottest` (Webb weights, 9999 reps; or score bootstrap if `boottest` cannot wrap `gmm` --- see R5) for $\phi$, $\Delta_{d_N}$, and the $\beta(v)$ joint test in **all three countries' primary robust specs**. Report both analytical CR1 and WCB p-values side by side.

**R5. `boottest` does not natively support `gmm` post-estimation** --- §5.1
`boottest` works with `regress`, `xtreg`, `areg`, `reghdfe`, `ivreg2`, `ivregress` and a few others; `gmm` support is extremely limited (it cannot reconstruct the moment Jacobian for a custom `gmm` equation). The line `boottest {phi}, cluster(hukou)` after `run_grc_robust` will fail.
**Fix:** Either (a) hand-roll a wild-score bootstrap using GMM influence functions (extract via `predict, score`), (b) for CHN hukou with $G=2$ use the MacKinnon-Webb (2018) "subcluster" wild bootstrap manually, or (c) reformulate the robust GRC at the cluster level so it is `ivregress`-compatible (within-demeaned route from R2 enables this). Decide before P4. Until resolved, the CHN hukou inference deliverable is fictional.

**R6. Aggregator for $\hat\Delta_{d_N}$ is not the same estimand as in the simple spec** --- §2.4 step 9, M5
The cluster-share-weighted average of cluster-specific $\hat\Delta_{d_N, v}$ is consistent for $E[\Delta_{d_N} \mid v \in \text{support}]$, NOT for $E[\Delta_{d_N}]$. The simple spec targets the unconditional mean. If clusters with no always-rural mass (or no switcher mass) have systematically different $\beta(v)$, the simple-vs-robust comparison conflates spec change with sample change.
**Fix:** (a) In every table, also report the simple-spec $\hat\Delta_{d_N}$ restricted to the same support set used by the robust aggregator; (b) report $\sum_v w_v$ and disclose the un-extrapolated population share; (c) discuss whether the sign-of-$\phi$ comparison is valid given the support gap (yes for $\phi$, no for the level comparison).

### Yellow (creates risk but plan can proceed)

**Y1. `gen_vfirst` semantic bug** --- §2.1, §3.2
`bysort pid (year): egen v = min(cond(!missing(vname), vname, .))` returns the *minimum value* of `vname`, not the value at the earliest observed year. For a province code this returns the province with the smallest numeric ID, not the first-wave province. (Same pattern was used in `2_cluster_support_v2.do` --- the feasibility note's numbers may be slightly off too.)
**Fix:** `bysort pid (year): gen tmp = vname if !missing(vname) & (_n == 1 | missing(vname[_n-1]))` then `bysort pid: egen v_first = max(tmp)`. Or use `egenmore`'s `first()`. Unit-test on a fabricated 5-row dataset.

**Y2. Always-urban per-cluster extrapolation under-spec'd** --- §3.3, §2.4 step 10
$v_i$ for an always-urban person is their first-wave urban province, which differs from the first-wave-rural support that identifies $\phi$. If $\phi$ identifies off rural-origin switchers but the always-urban extrapolation needs $\phi$ at urban-origin clusters, the LCA assumption is being applied across populations the test cannot detect.
**Fix:** Spec the always-urban estimand explicitly. Two options: (i) use the same $\phi$ but acknowledge cross-origin extrapolation in text, or (ii) estimate a separate $\phi^U$ from urban-origin switchers (requires sufficient urban-origin switcher count --- check before promising).

**Y3. Initial-values cluster-OLS will fail to invert in CHN** --- §2.2 step 1
`reg lndepvar i.vfirst#always* i.vfirst#switcher_*, vce(cluster pid) nocons` for CHN has ~406 regressors against ~30k obs with very thin $(v,s)$ cells. Many cells empty; some singletons. `eststo` returns missing coefficients; the `initial` local then contains `.` literals that break the `from()` GMM call.
**Fix:** After OLS, iterate over $(s,v)$ cells; for missing/singleton cells, substitute the global trajectory mean for $s$ and log substitution count. Validate `initial` contains no missing before `gmm`.

**Y4. Behavior when $v$-cell has switcher mass but no always-rural (or vice versa) is undocumented** --- §2.4 steps 8--9
**Fix:** Three counts in every log: (a) $|V|$ contributing to $\phi$ ($\geq 1$ switcher), (b) $|V|$ contributing to $\hat\Delta_{d_N}$ aggregator ($\geq 1$ switcher AND $\geq 1$ never), (c) population share covered by (b). Same for always-urban.

**Y5. No Wald test that $\beta(v)$ collapses to a scalar** --- spec §2.1, plan §6.3
Single most informative diagnostic for "does the robust spec actually buy you anything" is a joint test of $\beta(v_1) = \beta(v_2) = \ldots = \beta(v_{|V|})$. Failing to reject would itself be a result.
**Fix:** Add to P3 alongside LCA-overid; report in same diagnostic block as Hansen $J$ and LCA-overid $p$.

**Y6. CHN convergence fallback "use cluster-level fixed effects with a partialled-out $\phi$" is hand-waved** --- §8 risks
This IS the within-demeaned implementation that should be primary (R2). Calling it a "last resort" inverts the priority.
**Fix:** Promote within-demeaned to primary; saturated joint GMM becomes TZA-only validation check.

**Y7. `estadd ... : <estname>` post-`boottest` syntax requires `estimates restore`** --- §5.1
**Fix:** After bootstrap, store WCB p-values into a matrix; `estadd matrix wcb = ..., replace : <estname>`.

**Y8. §5.2 conflates IDN kabu (S3) with TZA regdist (S4)** --- §5.2
The line `egen regdist_idn = group(prov kabu)  // or appropriate` in the IDN section accidentally produces a third IDN spec.
**Fix:** Drop the regdist line from IDN; use `vindex(kabu)` directly. For TZA, `egen regdist = group(region district)` is correct.

**Y9. §5.3 IDN `migr == 0` snippet doesn't show `initial_values_robust` call** --- §5.3
Either the call is missing, or `run_grc_robust` calls `initial_values_robust` internally (preferred) but this is not documented in §2.4.
**Fix:** Decide; document `run_grc_robust`'s internal call to `initial_values_robust` in §2.4 signature.

**Y10. No baseline numerical regression test** --- spec §A2
Setting `vindex(constant)` (single $v$-cluster for everyone) should reproduce the simple spec exactly (up to SE clustering). Cheapest possible test of correctness.
**Fix:** Add to P1 verification gate: TZA with `vindex(_one)` ($_{one}=1$ for all obs) must match simple spec $\hat\phi$ and $\hat\Delta$'s to 6 decimals.

**Y11. No mention of GMM weighting (2-step vs CUE)** --- §2.4
With many more instruments under the robust spec, optimal weighting becomes ill-conditioned. CUE or iterated GMM more reliable.
**Fix:** Specify `twostep` (default), `igmm`, or `cue`. With instrument proliferation under the saturated route, CUE preferred; with within-demeaned, 2-step fine.

**Y12. Case mismatch in table filename** --- §6.1, §7
`GRC_robust_*.tex` (table) vs `grc_robust_*.ster` (estimates). Harmless on Windows, breaks under Linux/CI.
**Fix:** Use lowercase `grc_robust_` everywhere.

### Green (minor)

**G1.** §4.2 driver call shows `run_grc_overid` without `initial(...)`; should mirror originating call's initial values. Add `initial()` to all `run_grc_overid` driver calls.
**G2.** §6.2 "Defer detailed figure design until tables are settled" --- fine, but the heterogeneity plot is the visual headline; deserves its own §7-style spec when the time comes.
**G3.** Commit messages with `verdier-robust:` prefix violate repo convention (plain informative messages, no prefixes per `git-conventions.md`). Drop the prefix.
**G4.** Spec §3.3 has a malformed equation: $\hat\phi/\hat\phi$ cancels and $\hat\beta$ is undefined. Fix the algebra before P2.

## Verdict: REVISE

The plan correctly identifies the deliverable, files to touch, and phasing. But three structural issues will cause the implementation to fail or produce indefensible output:

1. **The saturated joint GMM is computationally infeasible for CHN and statistically wasteful everywhere; the within-demeaned formulation should be primary** (R2).
2. **`boottest` does not wrap `gmm`, so the CHN-hukou inference plan is non-executable as written** (R5).
3. **The LCA-overid moment specification is the single most important diagnostic and is left as "transcribe and review by eye" --- a gap that needs a written derivation gate before any code is written** (R1).

Fix Reds 1--6 and Yellows 1--3 in a P0 design-cleanup phase before P1 begins. Without those changes, P1 will hit a wall in CHN and P3--P4 will produce numbers that cannot be defended in a referee report.

## Revised plan (sections that need to change)

### [NEW] P0 --- Design cleanup (before P1)

1. Derive within-$v$-demeaned formulation of the robust GRC. Show algebraic equivalence to saturated joint GMM (up to choice of cluster-OLS first-step vs single-step). Save to `docs/reviews/2026-04-XX_robust-grc-derivation.md`. Human sign-off.
2. Derive LCA-overid $\eta_s$ moment conditions for both simple and robust specs. State (a) the moment, (b) the instrument set under the null, (c) dimension/df, (d) Stata expression. Same memo. Human sign-off.
3. Decide bootstrap implementation for `gmm`-based inference. Three candidates: hand-rolled wild-score bootstrap on GMM influence functions; reformulation as `ivregress` to enable `boottest`; cluster bootstrap with `bsample, cluster(vfirst)`. Pick one; document.
4. Verify `gen_vfirst` semantics. Unit-test on a fabricated 5-row dataset.

### [CHANGED] P1 §2.4 step 4 --- GMM equation

Replace saturated `i.vfirst#switcher_*` parameter expansion with within-$v$-demeaned implementation derived in P0 step 1. The GMM call is structurally identical to existing `run_grc` after replacing $y_{it}$, switcher dummies, and `mu:` parameters with their within-$v$ analogues, plus $|V|-1$ $v$-fixed-effect dummies absorbed into `xb:`. Saturated specification implemented only as TZA-only validation check (§2.5 addition).

### [CHANGED] P1 §2.4 step 5 --- instruments and SEs

Instrument set = original CKT instruments PLUS $|V|-1$ $v$-dummies as exogenous regressors. Do NOT $v$-interact every instrument. SEs `vce(cluster vfirst)`. Logged check: instrument:parameter ratio < 3 or bail.

### [NEW] P1 §2.5 verification gate additions

- Degenerate-$v$ regression test: with `vindex(_one)`, $\hat\phi$ and all $\hat\Delta$'s must match the simple `run_grc` to 6 decimals.
- Saturated-vs-demeaned test (TZA only): both implementations must produce the same $\hat\phi$ to 4 decimals.

### [CHANGED] P1 §2.2 step 4 --- initial values robustness

After cluster-OLS, iterate $(s,v)$ cells; substitute global trajectory mean for missing/singleton cells; log substitution count; validate `initial` has no missing before `gmm`.

### [CHANGED] P3 --- LCA overid

Implement $\eta_s$ moments per P0 derivation. Add Wald test of $\beta(v_1) = \ldots = \beta(v_{|V|})$ (constant intercept across clusters) and report in same diagnostic block. Both p-values are deliverables.

### [CHANGED] P4 §5.1 --- CHN hukou

Replace `boottest {phi}, cluster(hukou)` with bootstrap implementation chosen in P0 step 3. Apply same WCB to $\phi$, $\Delta_{d_N}$, and constant-$\beta(v)$ tests in **all three countries' primary specs**, not just CHN-hukou.

### [CHANGED] P5 §6.1 --- table contents

Add three rows to every robust-spec table block: (a) un-extrapolated population share, (b) cluster count contributing to $\phi$ identification, (c) WCB p-value alongside CR1 p-value for $\phi$. Restrict simple-spec column comparison to same support set as robust column (or report both unrestricted and support-matched simple rows).

### [NEW] P5 §6.4 --- sign-of-$\phi$ stress matrix

Per country, produce a small matrix of $\hat\phi$ across $v_i$ choices (CHN: prov vs hukou; IDN: prov vs kabu; TZA: region vs regdist) and across estimation routes (saturated vs within-demeaned). The sign-and-magnitude stability of $\phi$ across this matrix is the actual robustness deliverable for the pro-poor claim.
