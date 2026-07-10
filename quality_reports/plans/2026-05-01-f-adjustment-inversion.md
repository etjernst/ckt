# Plan: F-adjustment for finite-sample bias of LCA inversion CIs (rev 3)

Date: 2026-05-01 (rev 3)
Branch: `lca-inversion`
Spec: [`quality_reports/specs/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-05-01-f-adjustment-inversion.md)
Methods review: [`quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-05-01_f-adjustment-spec-methods-review.md)
Plan reviews: rev 1 review surfaced three Red findings on the from-scratch reimplementation; rev 2 review surfaced three new Red findings on the `reg_sandwich` sourcing path.

## Why this is rev 2

Rev 1 proposed implementing CR2 + Satterthwaite df from scratch in Python, anchored against `clubSandwich` via R subprocess.
The methods review and the subsequent plan review flagged three Red items, all of which dissolve under a different sourcing decision.

- (Red) Cite PT 2018 Theorem 2 vs the 2023 corrigendum.
- (Red) BRL-FE vs plain CR2 distinction under absorbed fixed effects.
- (Red) GMM-Wald-inversion bridge undocumented (later resolved as a framing issue: the inversion is OLS Wald on a linear restriction at each $\phi$, not GMM novelty).

The user explicitly objected to the from-scratch path on novelty-risk grounds.

The cleanest resolution is to call Pustejovsky's own implementation rather than re-derive his methodology.
The Stata package `reg_sandwich` (`ssc install reg_sandwich`) is by the same author as R `clubSandwich`, implements the same BRL-FE + AHZ machinery, and adds no new project dependency since Stata is already required.

## Why this is rev 3

A fresh-context review of rev 2 surfaced three new Red findings that target the sourcing path itself, plus several Yellow and Green items.
Rev 3 folds them in.

The Red items are:

1. Corrigendum compliance is not verified.
The 2023 PT corrigendum to Theorem 2 touches multi-parameter Wald-Satterthwaite, which is exactly the case the LCA test hits.
The SSC release of `reg_sandwich` may lag the corrigendum.
Rev 3 inserts Step 0a to verify the package version against the GitHub history at https://github.com/jepusto/clubSandwich-Stata, install from GitHub if SSC lags, pin a commit SHA in the derivation note, and require a multi-parameter ($q \ge 2$) toy cross-check rather than the silent $q = 1$ case.

2. The auxiliary OLS enters `i.trajectory` dummies unabsorbed, but `reg_sandwich` has separate code paths for absorbed FE.
With $J_R + K$ parameters and small per-cluster $N$, the unabsorbed CR2 adjustment matrix can become near-singular and the AHZ df can collapse silently.
Rev 3's Step 0a runs `reg_sandwich` both ways on the same regression, compares AHZ df, CR2 SE, and p-value, and switches to the absorbed form for production if they diverge.
Step 3 logs AHZ df at every grid point and trips a warning whenever df $< 4$.

3. Stata returns exit code 0 even on batch-mode script errors.
Silent failures would corrupt the 14-hour Step 3 simulation.
Rev 3 expands Step 2 with an explicit subprocess verification scaffold: the Python wrapper checks that the expected CSV exists, has rows equal to the $\phi$-grid length, has no missing `ahz_pvalue` entries, and that the `.log` contains no `r(...)` error codes via regex.
Any failure raises before downstream code consumes the file.

The Yellow and Green items appear as concrete edits in the relevant steps below: pystata for warm-kernel reuse, a pre-committed contiguous-acceptance fallback rule, a conditional WCB comparison run when coverage lands in the 0.92--0.935 gray band, a sharper toy-example specification, and an expanded CSV schema.

## Locked decisions

1. Cluster unit is `pid`. Confirmed in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) lines 120, 718, 764.
2. Source of truth for the F adjustment is `reg_sandwich` by Pustejovsky; the production install must include the 2023 PT corrigendum to Theorem 2 (verified in Step 0a; pinned commit SHA recorded in the derivation note).
Cite PT 2018 and the 2023 corrigendum.
3. Compute the AHZ p-value per grid point.
The Stata loop is fast enough that the single-$\widehat{\nu}$ path is reserved for the non-contiguous fallback below.
4. Contiguous-acceptance-region fallback rule.
Compute the AHZ p-value at every grid point.
If the series of $(p - \alpha)$ over the $\phi$-grid has more than one sign change in a given (country, spec, parameter) cell, that cell is non-contiguous; fall back to a single-$\widehat{\nu}$ AHZ critical value evaluated at the OLS point estimate of $\phi$, used uniformly across the grid for that cell.
The empirical-table footnote reports the per-country/spec fallback rate.
5. Coverage success cutoffs (PT 2018 §4 / Pustejovsky-Tipton 2018 simulation tolerances): $\ge 0.935$ closes the gap, $0.92$--$0.935$ is "substantially narrowed and documented", $< 0.92$ escalates to wild cluster bootstrap inversion.
6. Headline coverage runs at $R = 1000$ (MC SE $\approx 0.007$ at $p = 0.95$).
Smaller-$J_R$ regression checks at $R = 200$.
7. Side-by-side reporting: chi-squared, F-adjusted (AHZ), and published Stata `nlcom` $1.96 \cdot \widehat{SE}$ in adjacent columns of the markdown tables.
8. FE-absorption choice is decided in Step 0a by comparing `i.trajectory` against `absorb(trajectory)` on the same auxiliary regression.
The choice is logged in the derivation note and used uniformly downstream.

## Step 0: install and smoke-test `reg_sandwich`

Verify the Stata API exposes the AHZ p-value programmatically (in `r()` or `e()`).

- `ssc install reg_sandwich` (requires user approval; Pustejovsky's package, well-cited).
- Smoke test: run a tiny OLS with a known multi-parameter linear restriction, compute the AHZ test, confirm the p-value is retrievable as a scalar (not just printed).
- Toy DGP for the cross-check: a simulated balanced panel with $J = 20$ clusters, $T = 4$, two regressors of interest, and a multi-parameter contrast of dimension $q = 3$ (or, if a published example is preferred, the `MortalityRates` example shipped with R `clubSandwich` with a $q = 2$ contrast).
A $q = 1$ contrast is forbidden because the 2023 corrigendum is silent at $q = 1$ and a $q = 1$ match would not exercise the load-bearing code path.
- Cross-check the AHZ p-value, the AHZ statistic, and the AHZ df against R `clubSandwich::Wald_test(test = "HTZ")` on the same toy data.
Tolerance: $10^{-4}$ on the test statistic, $10^{-3}$ on the df.
- If the cross-check passes, proceed to Step 0a.
If it fails, stop and escalate before any production wiring.

Estimated ~2 hours (toy DGP construction, two-way cross-check at $q \ge 2$, log capture).

## Step 0a: corrigendum verification and FE-absorption choice

This step is load-bearing for rev 3.
It locks both the package version and the regression specification before any synth-coverage runtime is committed.

Corrigendum verification:

- Pull the GitHub history at https://github.com/jepusto/clubSandwich-Stata.
- Identify the commit (or release notes) that addresses the 2023 PT corrigendum to Theorem 2.
- Read the SSC version metadata via `which reg_sandwich` and the package `.pkg` header; compare against the GitHub commit dates.
- If the SSC release lags the corrigendum commit, install from GitHub via `net install reg_sandwich, from(...)` pointing at the raw GitHub URL of a commit at or after the corrigendum.
- Pin the commit SHA in the derivation note (Step 6).

FE-absorption A/B test:

- Run the auxiliary OLS that the LCA inversion uses, twice, on a representative country dataset.
Specification A enters trajectory dummies as `i.trajectory`.
Specification B uses `absorb(trajectory)`.
- Apply `reg_sandwich` to both and capture, for the same multi-parameter LCA-style contrast: AHZ statistic, AHZ df, CR2 SE on the contrast, AHZ p-value, and wall time per call.
Wall time matters: with $K = 27$ and $J_R = 26$, the unabsorbed adjustment-matrix computation is $O(J^2 K^2)$ in memory and could be materially slower than absorbed even if the numerics agree.
- Compare.
If the two specifications agree to within $10^{-3}$ on df and $10^{-4}$ relative on the SE, document and proceed with the unabsorbed form for transparency.
If they diverge meaningfully, switch to `absorb(trajectory)` for production and document the divergence in the derivation note as evidence that the unabsorbed CR2 adjustment matrix is near-singular at this scale.
- Record the final choice in locked decision 8.

Estimated ~1.5 hours (GitHub history scan, optional GitHub install, A/B test).

## Step 1: write the Stata-side wrapper

In a new file [`RP7/scripts/f_adjust_inversion.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/f_adjust_inversion.do):

- Load a country dataset, prep variables identically to the auxiliary OLS in [`fit_auxiliary_ols`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).
- Run the auxiliary OLS via `regress` with `cluster(pid)`, using the FE-absorption choice locked in Step 0a.
- Loop over a $\phi$-grid (passed in via globals or a CSV).
At each grid $\phi$, build the LCA constraint matrix, call `reg_sandwich`'s AHZ test on that constraint, capture the p-value, the test statistic, the AHZ df, and the CR2 SE.
- Write rows with the expanded schema `(country, spec, phi, ahz_pvalue, ahz_stat, ahz_df, cr2_se, status)` to a CSV.
The `status` column takes values `"ok"`, `"df_low"` (when $2 \le$ AHZ df $< 4$), `"df_floor"` (when AHZ df $< 2$), or `"singular_adj"` (when the CR2 adjustment matrix fails to invert and the call falls back), so the Python side can flag suspect rows without re-running Stata.
The `df_low` rows are retained in the CI union but flagged in the derivation note; `df_floor` rows are dropped from the union with the resulting non-coverage at those grid points documented as structural.

Pattern follows [`attach_inversion_ci`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) from end of last session: same Stata-Python bridge structure, same `capture noisily` wrapper, same `exit, STATA clear` tail.

Estimated ~2 hours.

## Step 2: Python wrapper in `lca_inversion.py`

Add a new function `f_adjusted_inversion_via_stata(...)` that:

- Pickles or CSVs out the auxiliary OLS data + grid specification.
- Calls the Stata wrapper via `subprocess.run("stata-mp", "-b", "do", "f_adjust_inversion.do", ...)`.
- Performs subprocess verification before reading any output.
The check covers four conditions, each of which raises a descriptive exception on failure: (a) the expected CSV exists at the agreed path; (b) the CSV has exactly `len(phi_grid)` rows; (c) no row has a missing `ahz_pvalue`; (d) the companion `.log` file contains no `r(\d+)` error codes when scanned by regex.
Stata's batch-mode exit code is ignored because it returns 0 even on script errors.
- Reads back the AHZ p-value CSV and inspects the `status` column; rows flagged `df_low` or `singular_adj` propagate a warning into the returned object so downstream tables can footnote them.
- Returns the F-adjusted CI as the union of intervals where `ahz_pvalue > alpha` (uses the existing `find_islands` + `format_islands` machinery; method-agnostic).

Add `cv_method: Literal["chi2", "f_adj"] = "chi2"` to:

- `grid_lca_inversion`
- `grid_md_inversion`
- `grid_delta_never_md_inversion`
- `grid_delta_avg_md_inversion`
- `grid_delta_always_md_inversion`
- `compute_all_inversion_cis`

Default stays `"chi2"` so all existing callers behave unchanged.
When `cv_method="f_adj"`, route through `f_adjusted_inversion_via_stata`.

Estimated ~4.5 hours (~3 hours for the wrapper plus ~1.5 hours for the verification scaffold and its tests).

## Step 3: synth coverage at $T=4, R=1000$ and $T=5, R=1000$

- $T=4, K=14, J_R=13, R=1000$, seeds 2000--2999.
Headline test of whether F adjustment closes the 0.840 chi-squared coverage gap at moderate $J_R$.
- $T=5, K=27, J_R=26, R=1000$, seeds 5000--5999.
F1-folded test of whether F adjustment closes the gap at IDN scale.

Stata-startup mitigation.
At $R = 1000$, naive per-replication subprocess launches dominate runtime.
Two mitigations apply, in priority order: (i) keep one Stata kernel warm across replications via `pystata` (the bundled module from the Stata install at `utilities/pystata/`, never installed via `pip`), so a single Stata session services all $R$ datasets; (ii) if the warm-kernel path is unstable in batch mode, batch all $R$ datasets to disk first and call Stata once with a do-file that loops over them.
Either approach drops runtime 5--10x relative to per-rep subprocess launches.

Pystata pilot trigger.
Run a 50-rep pilot at $T=4$ via the warm-kernel path before committing to the 14-hour headline.
If the pilot exhibits a kernel crash, RAM growth above 4 GB, or any seed-determinism break before rep 50 lands, switch to the disk-staged batch fallback for the headline run.
Both paths use identical seeds (2000--2049 for the pilot); seed determinism is verified by comparing the chi-squared coverage point estimate at $R=50$ between the two paths to within MC noise.

Per-rep: pass the entire $\phi$-grid plus all four inversion variants in one Stata call so the per-replication cost is dominated by the regress + reg_sandwich loop rather than overhead.
Expected runtime: ~50 s/rep at $T=4$, ~75 s/rep at $T=5$.
$R = 1000$ at both: ~14 hours of MC runtime, parallelizable across reps.

Per-grid logging.
Every replication emits AHZ df at every grid point.
A summary tally per cell records the minimum AHZ df observed across the grid and the share of grid points with df $< 4$.
A nonzero share trips a warning that propagates into the synth coverage table footnote and the derivation note.

Decision tree on the $T=5, K=27$ $\Delta_{\text{avg}}$ coverage (the IDN-scale headline):

- $\ge 0.935$: gap closed at IDN scale.
Skip Step 3.5 and proceed to Step 4.
- $[0.92, 0.935)$: substantially narrowed at IDN scale.
Run Step 3.5 (WCB comparison) before proceeding to Step 4 with the documented caveat.
- $< 0.92$: gap not closed at IDN scale.
Stop, document, queue a wild cluster bootstrap inversion spec as the next robustness path.

Estimated ~3 hours of code (synth wrapper + warm-kernel Stata bridge) + ~14 hours of MC runtime.

## Step 3.5: WCB comparison conditional on the gray band

Trigger condition.
This step runs only if the $T=5, K=27$ $\Delta_{\text{avg}}$ coverage from Step 3 lands in $[0.92, 0.935)$.
A referee reading PT 2018 will note that HTZ achieves 0.94--0.95 at comparable cluster counts and ask why F-adjustment delivers less; rev 3 pre-empts the "why not WCB?" question with a small comparison run.

Framing.
Step 3.5 is a qualitative WCB-vs-AHZ comparison ("does WCB recover the gap?"), not a formal coverage estimate.
With $R = 200$ the MC SE on coverage is $\sim 0.015$, which is wide relative to the $[0.92, 0.935]$ window that triggered the comparison; treating the WCB number as point-decisive would over-claim.

Design.

- Same DGP and seeds as the $T=5, K=27$ headline cell but truncated to $R = 200$ replications (seeds 5000--5199).
- Implement WCB inversion against the auxiliary OLS using `boottest` (Roodman et al. 2019) called via the multi-parameter joint-restriction syntax `boottest (R1) (R2) ...` mirroring the AHZ Wald constraint, NOT a sequence of single-restriction tests (the two have different size properties under weak ID).
- Bootstrap draws $B = 9999$ (Roodman et al.'s default; large enough that bootstrap noise is negligible relative to MC noise at $R = 200$).
- Wrapped through the same warm-kernel pystata bridge as Step 3.
- Report side by side: chi-squared coverage, F-adjusted coverage (from Step 3 at the same seeds, subset to the first 200), WCB coverage, plus median CI half-width for each.
- The output feeds a one-paragraph subsection in the derivation note quantifying the residual gap qualitatively and stating whether WCB would be a worthwhile follow-up path.

Estimated ~2 hours of code (boottest wrapper) + ~4 hours of conditional runtime; both line items are zero unless the trigger fires.

## Step 4: regression check at smaller $J_R$

Re-run two existing synth coverage runs with F adjustment.

- $T=3, K=6, J_R=5, R=200$, seeds 1000--1199 (existing chi-squared baseline 0.90).
- $T=2, K=2, J_R=1, R=200$, seeds 0--199 (existing chi-squared baseline 0.79; just-id $K=2$ pathology).

Pass criterion: F-adjusted coverage at smaller $J_R$ does not drop more than 1 MC SE ($\sim 0.025$ at $R = 200$) below the chi-squared baseline.
The $T=2$ pathology is structural and a degradation there does not block.

Estimated ~1 hour code, ~3 hours runtime.

## Step 5: empirical three-country re-run

Re-run [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py) with `cv_method="f_adj"` and write a side-by-side comparison table at [`results/delta_inversion_three_countries_compare.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries_compare.md) with three columns per parameter: chi-squared CI, F-adjusted CI, published Stata `nlcom` $\pm 1.96 \cdot \widehat{SE}$.

Apply the contiguous-acceptance fallback rule from locked decision 4.
For each (country, spec, parameter) cell, compute the AHZ p-value series over the $\phi$-grid and count sign changes of $(p - \alpha)$.
Cells with more than one sign change use single-$\widehat{\nu}$ AHZ critical values at the OLS point estimate of $\phi$.
The footnote of the empirical table reports per-country/spec fallback rates.

Verify:

- No previously non-empty CI collapses to empty under F adjustment (F adjustment monotonically widens or preserves CIs on contiguous-acceptance cells).
- Multi-island handling still works on IDN/covs_all and TZA/covs_all (the Möbius-singularity cells).
- F-adjusted vs chi-squared widening on well-identified cells (covs_trend, covs_1, covs_2): expected 5--30%.
- F-adjusted vs `nlcom` widening on the same cells: also 5--30% (the F-adjusted CI is weak-ID-robust whereas `nlcom` is not, but on well-identified cells the two should be close).
A widening of 50%+ on a clean cell flags an implementation issue; investigate before declaring Step 5 complete.
Any narrowing of the F-adjusted CI relative to chi-squared is also a flag (the F adjustment should monotonically widen or preserve CIs on contiguous-acceptance cells); narrowings indicate either a contiguity-fallback artifact or a scaling bug.
- Per-grid AHZ p-value diagnostics: log min/median/max p-values per cell, plus the sign-change count and the resulting fallback decision per cell.

Estimated ~2 hours code + ~1 hour runtime.

## Step 6: derivation note and validation-gate update

Save a memo at [`docs/notes/2026-05-01_f-adjustment-via-reg-sandwich.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-01_f-adjustment-via-reg-sandwich.md) covering:

- The decision to route through `reg_sandwich` rather than reimplement.
- Citation chain: PT 2018 + 2023 corrigendum, AHZ $\to$ HTZ correspondence in R, Stata version pin (commit SHA from Step 0a).
- The OLS framing (auxiliary OLS Wald, not GMM Wald) and why `reg_sandwich` applies directly.
- The FE-absorption A/B-test result and the locked production specification.
- The contiguous-acceptance fallback rule and the per-country fallback rate.
- Synth coverage table from Step 3, including AHZ-df diagnostics per cell.
- WCB comparison subsection from Step 3.5 if the gray-band trigger fired; otherwise a one-line note that coverage cleared $\ge 0.935$ and WCB was unnecessary.
- Smaller-$J_R$ regression check from Step 4.
- Three-country empirical comparison from Step 5.

This is shorter than rev 1's planned derivation memo because we no longer derive a Satterthwaite formula, but rev 3 reinstates a corrigendum-and-FE-absorption section that rev 2 did not anticipate.
The net is a slightly longer note than rev 2 budgeted.

Append an "F-adjusted coverage via reg_sandwich" subsection to [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md) summarizing gate-pass status and pointing the reader at the new note.

Estimated ~3 hours.

## Step 7: commit chain and TODO updates

Atomic commits, each verified:

1. `Step 0: reg_sandwich smoke test + AHZ-vs-HTZ q>=2 cross-check`.
2. `Step 0a: corrigendum-version pin + FE-absorption A/B test`.
3. `Step 1-2: Stata wrapper f_adjust_inversion.do + Python bridge with verification scaffold`.
4. `Step 3: synth coverage at T=4 R=1000 and T=5 R=1000 (warm pystata kernel)`.
5. `Step 3.5: conditional WCB comparison at R=200 (only if triggered)`.
6. `Step 4: smaller-JR regression check`.
7. `Step 5: empirical three-country side-by-side table with fallback footnote`.
8. `Step 6: reg_sandwich note + validation-gate update`.

Mark RESOLVED in [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md):

- "Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment" entry.

Leave open:

- "Hall-Horowitz (1996) bootstrap-calibrated inversion" (conditional on Step 3 outcome at $T=5, K=27$).
- "Wild cluster bootstrap inversion" (conditional on Step 3 outcome; partial evidence from Step 3.5 if the gray-band trigger fired).
- "Empirically calibrated coverage test" (independent path).
- "Stata-pipeline integration of inversion CIs" (blocked on `worktree-grc-pipeline-refactor` merge; the F-adjusted CI plumbing here is parallel to that work).

## Total estimate

| Step | Code time | Runtime | Total |
|---|---:|---:|---:|
| 0 | 2 h | 0 | 2 h |
| 0a | 1.5 h | 0 | 1.5 h |
| 1 | 2 h | 0 | 2 h |
| 2 | 4.5 h | 0 | 4.5 h |
| 3 | 3 h | 14 h | 17 h |
| 3.5 (conditional) | 2 h | 4 h | 6 h |
| 4 | 1 h | 3 h | 4 h |
| 5 | 2 h | 1 h | 3 h |
| 6 | 3 h | 0 | 3 h |
| 7 | 1 h | 0 | 1 h |
| Total (no Step 3.5) | 20 h | 18 h | 38 h |
| Total (with Step 3.5) | 22 h | 22 h | 44 h |

Code time (~20 hours) is up from rev 2's ~15 hours.
The five-hour delta breaks down as ~2 hours on Step 0a (corrigendum verification + FE-absorption A/B), ~1.5 hours on Step 2 (subprocess verification scaffold), and ~1.5 hours on Step 6 (memo extension covering the new diagnostics).
Step 3.5 adds 2 hours of code and 4 hours of conditional runtime, both zero unless the gray-band trigger fires.
Runtime is still dominated by the $R = 1000$ synth coverage MC at $T=5$ and is parallelizable.
Wall time on a 4-core machine with parallelization: ~26 hours total without Step 3.5, ~30 hours with it; either fits in 3 sessions.

The load-bearing checkpoints are now Step 0 (toy AHZ-vs-HTZ cross-check at $q \ge 2$) and Step 0a (corrigendum compliance + FE-absorption choice).
If both pass, the rest is plumbing.
If either fails, stop and escalate to wild cluster bootstrap or Hall-Horowitz before any further coding.

## Risks and mitigations

The risks below are now scaffolded by Step 0a and the Step 2 verification routine rather than left as open hazards.

- `reg_sandwich`'s AHZ test does not expose a programmatic p-value (only prints to log).
Mitigation: parse the log via `file read`, or open a GitHub issue with Pustejovsky asking for an `r()` storage.
Step 0 catches this before any other code lands.
- The SSC release of `reg_sandwich` lags the 2023 PT corrigendum.
Mitigation: Step 0a verifies the SSC version against the GitHub commit history, falls back to a `net install` from a pinned commit SHA when needed, and records the pin in the derivation note.
- Unabsorbed `i.trajectory` dummies make the CR2 adjustment matrix near-singular at our scale and silently collapse AHZ df.
Mitigation: Step 0a runs an A/B test against `absorb(trajectory)` and switches specifications if they diverge.
Step 3 logs AHZ df at every grid point and warns whenever df $< 4$.
- Stata returns exit code 0 on batch-mode script errors and a silent failure would corrupt the 14-hour Step 3 MC.
Mitigation: Step 2's subprocess verification routine raises if the expected CSV is missing, is the wrong length, has missing `ahz_pvalue` rows, or if the `.log` contains any `r(\d+)` error code.
The verification runs before any downstream consumer reads the CSV.
- Stata startup cost per replication kills the $R = 1000$ MC runtime budget.
Mitigation: warm `pystata` kernel reused across reps, with a fallback to a single-process do-file loop over disk-batched datasets.
Either path drops runtime 5--10x relative to per-rep subprocess launches.
- Per-grid AHZ p-values produce a non-contiguous acceptance region.
This is a real possibility because $\widehat{\nu}$ varies along the grid.
Mitigation: locked decision 4 pre-commits the fallback rule (single $\widehat{\nu}$ at the OLS point estimate when more than one sign change of $(p - \alpha)$ appears in a cell).
The empirical table footnote reports the fallback rate per country/spec.

## What success looks like

- `reg_sandwich` is installed at a version that incorporates the 2023 PT corrigendum, with the commit SHA pinned in the derivation note.
- AHZ matches HTZ on a $q \ge 2$ toy example to $10^{-4}$ on the statistic and $10^{-3}$ on the df.
- The FE-absorption A/B test produces a documented production choice.
- `lca_inversion.py` supports `cv_method="f_adj"` on all four inversions via a thin Stata-Python bridge.
- The subprocess verification scaffolding catches silent Stata errors before they corrupt the synth runs.
- AHZ df $> 4$ at every grid point in every cell of every synth and empirical run, or any violation is flagged in the table footnote and the derivation note.
- Synth $\Delta_{\text{avg}}$ coverage at $T=4, K=14, R=1000$ and $T=5, K=27, R=1000$ both land at $\ge 0.92$, ideally $\ge 0.935$.
- Three-country empirical comparison table shows F-adjusted CIs widening 5--30% relative to chi-squared on well-identified cells.
- The contiguous-acceptance fallback rate per country/spec is documented in the empirical-table footnote.
- One-page note at `docs/notes/2026-05-01_f-adjustment-via-reg-sandwich.md` documents the decision chain.

The work is decoupled from the Stata-pipeline refactor; F-adjusted CIs are first-class in the Python markdown tables and ride alongside the existing `attach_inversion_ci` pattern when `worktree-grc-pipeline-refactor` merges.
