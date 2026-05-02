# Project to-do list (CKT migration paper)

Persistent to-do list for items that are decided but not yet in progress.
Append dated entries.
Move completed items to the bottom with the resolution date.

---

## Active

### Resolve `_est_<name>` 32-char overflow in 5_GrRC.do's table-build block
**Added:** 2026-05-01.
**Branch:** lca-inversion.
**Context:** Commit `2b24344` wired LCA inversion CIs into the GRC pipeline (`attach_inversion_ci` + `5b_inversion.do` + extended `grc_tex_table_trend`).
The 5b_inversion driver runs cleanly and writes inversion CI scalars and macros to all 15 mainline `.ster` files in ~1 hour.
The end-to-end verification then needs to render the table via `grc_tex_table_trend, spec(urban)`, which requires the four sters per cell to be in memory under their disk-side names (`grc_<country>_urban_<spec>{,_never,_avg,_always}`).
The longest of those is `grc_IDN_urban_covs_trend_never` at 30 chars; with the `_est_` prefix Stata stores it under, the effective name is 35 chars and overflows the 32-char `_est_<NAME>` limit.
The error `r(7) invalid name` fires inside the `estimates store` call.

Two interlocking issues:
1. **5_GrRC.do internal naming inconsistency.** `run_grc, estname(grc_<country>_urban_<spec>)` saves sters with the long name, but the `* Make sure estimates are in memory` block (lines ~280, ~325) does `estimates store grc_<country>_<spec>` (without `urban`).
The disk-side names and the in-memory store names diverge.
The existing table-build flow apparently still works in production---likely because `grc_tex_table_trend` is called with `spec(urban)` and so esttab actually looks for `grc_<country>_urban_<spec>{,_never,_avg}` in memory, but those store names are 30+ chars and would also overflow.
Either (a) production has been silently running on stale cached state, (b) the `_urban_` segment is omitted somewhere I haven't found, or (c) the table-build block has a separate workaround.
**Action:** trace exactly how production resolves this when running 5_GrRC.do end-to-end on a fresh tree. Likely fix: rename to a shorter identifier (e.g., drop `_urban_` from the in-memory store names or compress `urban`/`nonag` to `u`/`n`).
2. **`grc_tex_table_trend` should not assume short names.** Its current `local ests_never = "...grc_<country>_<spec>_<estname>_never"` is what generates the long names that trip the limit.
**Action:** consider changing the program to take a separate `estname_pattern()` argument so callers can supply a shorter naming scheme without touching the table builder.

**Estimated cost:** half a day of tracing + minor renaming.
**Why it matters:** the LCA-inversion CI rows in the new `grc_tex_table_trend` extension cannot be exercised end-to-end until the lookup names match.
The CI scalars and macros are correctly attached to the sters by `attach_inversion_ci`; only the rendering step is blocked.

### Regenerate auxiliary GRC tables to pick up the Delta_avg fix
**Added:** 2026-04-30.
**Branch:** lca-inversion.
**Context:** Commit `5cfe158` (2026-04-29) fixed a bug in `RP7/scripts/0_programs.do` where `Delta_avg` was computed using over-all-sample shares (`sum 1.switcher_s if e(sample); local num_s = r(mean)`).
Those weights summed to the switcher fraction (~4% in IDN/CHN, ~11% in TZA) instead of 1, so the published `Delta_avg` equaled `switcher_frac * E[Delta | switcher]` rather than the actual average return for switchers, depending on country.
The fix conditions on `& switcher == 1` so the weights sum to 1 across the switcher subsample.
We re-ran 5_GrRC.do's mainline (urban / consumption / unbalanced, 5 specs each for IDN, CHN, TZA), so those `_avg.ster` files are now correct.
But the `_avg.ster` files for the auxiliary tables (6_GrRC_NonAg, 8_GrRC_hukou, 11_GrRC_max_experience, 13_GrRC_max_experience_share, 14_GrRC_NonAg_experience, 15_GrRC_birth) still carry the buggy values.
Any paper table that displays `Average Delta` from those scripts is currently showing `switcher_frac * correct_value`.
**Action:** when next running each of those scripts, the corrected formula in `0_programs.do` will pick up automatically.
For the paper, identify which tables actually display `Delta_avg` and prioritize regenerating those.
For the hukou-split table specifically (8_GrRC_hukou), this might combine with the kappa-rename TODO since both touch the same code path.
**Estimated cost:** modest. Each auxiliary script takes 30-60 minutes to rerun, and not all of them surface `Delta_avg` in the published table cells (some only use it as a scalar diagnostic).

### Delta_avg inversion under-coverage on the T=2 synthesizer (RESOLVED)
**Added:** 2026-04-30.
**Resolved:** 2026-04-30.
**Branch:** lca-inversion.
**Resolution:** the under-coverage was a $K = 2$ small-sample pathology specific to the just-identified $T = 2$ synth.
[`synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py) reruns coverage with $T = 3$, $K = 6$ kept switchers ($J_R = 5$, over-identified), trajectory means spaced 0.1 log units apart (CKT-realistic, vs 1.0 in T=2), $\sigma_\alpha = 0.6$, $\sigma_\epsilon = 0.3$, $\phi = -0.5$, $\beta = 0.05$.
$\Delta_{\text{avg}}$ coverage at $R = 100$ jumps to 0.90 (MC SE 0.030), within roughly two MC SEs of nominal 0.95.
The 5/100 empty CIs per parameter match the nominal Type I rate of the joint $\chi^2_5$ LCA test (5%), so conditional on a non-empty CI all four parameters cover at 0.95 to 0.98.
The chi-squared approximation works cleanly at empirical $K \geq 5$ scale.

### Per-replication LCA inversion CI in the simulation (Stream C deliverable)
**Added:** 2026-04-29.
**Branch:** Stream C (simulation work, lives on the `simulations` worktree).
**Context:** The empirical paper reports the LCA inversion CI as the primary inference for $\phi$.
The simulation must measure its empirical coverage at CKT's $(N, T)$ so the paper can defend the inversion CI as well-calibrated.
This is the headline simulation deliverable.
**Action:** for each Monte Carlo replication $r = 1, \ldots, R$ of the synthetic data, call `grid_lca_inversion` from [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) on replication $r$'s data, extract the CI endpoints, record whether the true $\phi$ falls inside.
Report empirical coverage = $\frac{1}{R} \sum_r \mathbf{1}\{\text{covered}_r\}$ alongside the nominal level.
**Cost:** wiring is small (lca_inversion is already a callable module); the cost is Monte Carlo runtime.

### Profile $Q(\phi)$ on real data
**Added:** 2026-04-29 (Stream B diagnostic).
**Branch:** simulations.
**Context:** The basin-switching diagnosis from 2026-04-24 was based on one data point (IDN covs_all element-wise diff).
A direct visualization of the GMM criterion as a function of $\phi$ would either corroborate or refute the "flat ridge" framing.
This is the cleanest possible test of weak identification at CKT's specifications.
**Action:** for IDN/cons/urban/unb across covs_0, covs_trend, covs_2, covs_all: hold all parameters except $\phi$ at their profiled optima; sweep $\phi$ on a grid; plot $Q(\phi)$.
A flat region over a wide range of $\phi$ confirms weak ID and validates the LCA inversion CI as the right inference; a sharp single minimum says weak ID is overstated and we revisit.
**Estimated cost:** ~50 min per spec (each grid point is one constrained optimization); 4 specs $\sim 3{-}4$ hours total.

### Multistart on Python step 1
**Added:** 2026-04-29 (Stream B diagnostic).
**Branch:** simulations.
**Context:** Sanity check on whether what looks like basin-switching is actually a multimodal landscape (multiple valid optima of the GMM criterion) versus a tolerance gap (Python and Stata stop at slightly different points within the same basin).
Also feeds the secondary multistart simulation from the 2026-04-24 log.
**Action:** run Python step-1 GMM on IDN/cons/urban/unb covs_all from 50-100 random initial values (perturbations around the OLS initial).
Tabulate distinct local minima and the spread of $\hat\phi$ across starts.
If only one basin, the divergence between Python and Stata is something other than basin-switching (probably a tolerance / W-convention gap).
If multiple basins, the basin-switching framing is supported.
**Estimated cost:** $50 \times 12$ min $\approx 10$ hours of Python compute (parallelizable).

### Empirically calibrated coverage test for the inversion CI
**Added:** 2026-04-30.
**Branch:** lca-inversion (or simulations).
**Context:** The current synth_overid Monte Carlos at $T = 3$ ($K = 6$, $J_R = 5$) and $T = 4$ ($K = 14$, $J_R = 13$) approximate the empirical CKT setting but differ in several dimensions: trajectory shares are uniform across switchers (vs uneven empirically), there are no unbalanced observations (vs $\sim 75\%$ in CKT), there are no controls (vs period FE / age² / education in covs_trend through covs_all), and the trajectory mean spread is set to a uniform 0.1 log units (vs uneven empirical spreads).
The $T = 4$ run shows mild persistent under-coverage ($\Delta_{\text{avg}}$ at 0.84 vs nominal 0.95) that is consistent with the chi-squared finite-sample bias documented in [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md), but we cannot say from the synth alone how much under-coverage to expect at the IDN $K = 27$ scale specifically.
**Action:** synthesize panels using empirical trajectory shares (drawn from each country's data), the empirical share of unbalanced observations, and realistic controls.
For each country (TZA, CHN, IDN), generate $R \geq 100$ panels under an LCA-true DGP calibrated to the empirical $\hat\phi$ and $\hat\beta$, run the full inversion pipeline (including the same `drop_sparse_switchers`, the same controls per spec, and the same cluster-robust SE), and report empirical coverage of all four parameters per (country, spec).
This gives a country-spec-specific calibration of the inversion CI that the current generic synth cannot.
**Estimated cost:** moderate. The synthesizer extension is ~half a day of code; running $R = 100$ per country is a few hours.
**Why it matters:** the paper claims weak-ID-robust inference via the inversion CI; an empirically calibrated coverage check is the cleanest defense against a referee asking "is your CI actually 95%?"

### Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment as a robustness row
**Added:** 2026-04-30.
**Branch:** lca-inversion.
**Context:** The chi-squared finite-sample bias documented in [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md) over-rejects $H_0$ at $T = 4$, $K = 14$ ($J_R = 13$) by about 2.5 pct.
Imbens, G. W., and Kolesár, M. (2016), "Robust Standard Errors in Small Samples: Some Practical Advice," *Review of Economics and Statistics* 98(4), 701--712, propose a Bell-McCaffrey adjustment to the cluster-robust variance plus an $F(J_R, \hat\nu)$ critical value with $\hat\nu$ set by a Satterthwaite-type formula.
**Action:** apply the Bell-McCaffrey-Satterthwaite F adjustment to the chi-squared cutoff in [`grid_lca_inversion`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) and the three MD delta inversions.
Re-run the synth_overid coverage at $T = 4$, $R = 200$ to verify that the under-coverage gap closes.
Re-run the empirical three-country inversion to produce the F-adjusted CI for each cell.
**Reporting:** present the F-adjusted CI as an additional row beneath the inversion CI in each table cell (same column, two rows: chi-squared inversion above, F-adjusted inversion below).
No new column needed.
**Estimated cost:** modest. The adjustment is a one-line replacement of the critical value plus a $\hat\nu$ computation per grid point; coverage rerun is automated.

### Look into the 2023 PT corrigendum vs the 2017 `reg_sandwich` we are using
**Added:** 2026-05-01.
**Branch:** lca-inversion.
**Context:** Step 0 of [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md) installed `reg_sandwich` from SSC (version `0.0`, dated 02-March-2017).
GitHub history at https://github.com/jepusto/clubSandwich-Stata stops at commit `e9741c0` on 2017-05-31, so SSC and GitHub are the same code generation; both predate the 2023 PT corrigendum to Theorem 2.
On the $q = 3$ toy panel, Stata AHZ and R `clubSandwich::Wald_test(test = "HTZ")` (current CRAN, 0.6.2) agree to $1.8 \cdot 10^{-8}$ on the F statistic and $1.6 \cdot 10^{-7}$ on the Satterthwaite df.
That agreement is consistent with two stories: either the corrigendum does not touch the HTZ code path we use, or the corrigendum touches an edge case our toy does not exercise.
**Action:** read the 2023 corrigendum, identify which test variants and code paths it changes, decide whether our LCA inversion case is in scope.
If in scope, port the corrigendum fix into the 2017 ado or compute the test in R via subprocess.
If out of scope, document and proceed with the SSC build.
**Why this is a TODO and not a blocker:** the user authorized using the 2017 Stata package now; the cross-check with current R already gives strong evidence that AHZ on our test geometry is unchanged.
**Memo:** [`docs/notes/2026-05-01_step0-ahz-vs-htz.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-01_step0-ahz-vs-htz.md).
**Estimated cost:** half a day to read the corrigendum and trace.

### Bootstrap-calibrated inversion CI as a third robustness row (optional)
**Added:** 2026-04-30.
**Branch:** lca-inversion (or simulations).
**Context:** Hall, P., and Horowitz, J. L. (1996), "Bootstrap Critical Values for Tests Based on Generalized-Method-of-Moments Estimators," *Econometrica* 64(4), 891--916, show that bootstrap critical values for GMM tests have asymptotic refinements over the chi-squared.
For our setting this means: at each grid $\phi$, recompute the LCA Wald statistic on $B$ bootstrap resamples of individuals (preserving within-individual waves), tabulate the bootstrap distribution of the Wald *under $H_0$ at that grid point*, and use its empirical 95th percentile in place of $\chi^2_{J_R, 0.95}$.
This is the "best of both worlds": preserves weak-ID robustness of the inversion CI while correcting the chi-squared finite-sample bias.
**Action:** implement bootstrap calibration in `grid_lca_inversion` and the MD delta inversions, with $B \approx 500$ resamples.
Run on the IDN $K = 27$ specs first (where the chi-squared bias is largest).
**Reporting:** present alongside the chi-squared inversion CI and the F-adjusted CI as a third row in each table cell.
**Status:** lower priority than the F adjustment and the empirical coverage calibration above.
Escalate to this if the F adjustment alone does not close the gap.
**Estimated cost:** $B \times$ (grid size) Wald computations per cell, parallelizable.
At IDN scale, expect a few CPU-hours per spec.

### Add panel bootstrap CIs for $\hat\Delta_{d_N}$, $\hat\Delta_{\text{avg}}$, and $\hat\Delta_{d_T}$ in main tables
**Added:** 2026-04-22 (scope narrowed 2026-04-29; expanded 2026-04-30 to include $\Delta_{\text{avg}}$).
**Branch:** TBD (depends on whether bootstrap is computed on Stream B or Stream A).
**Context:** Default GMM and inversion CIs may under-cover for the trajectory-specific returns because they combine the LCA slope with extrapolation distance to the trajectory mean.
**Scope expanded 2026-04-30:** $\Delta_{\text{avg}}$ added after the $T = 4$, $K = 14$, $J_R = 13$ over-identified Monte Carlo at $R = 200$ showed mild persistent under-coverage of the inversion CI: 0.840 vs nominal 0.95 (4 MC SEs below).
The pattern is consistent with finite-sample bias in chi-squared asymptotics that grows with $J_R$, plus a small upward bias in the joint LCA over-id test itself (7.5% empty CIs vs nominal 5%).
The empirical IDN spec has $K = 27$, so the IDN inversion CI for $\Delta_{\text{avg}}$ is most likely the cell with the largest under-coverage gap.
**Scope narrowed 2026-04-29:** original entry covered $\hat\phi$ too, but with the LCA inversion CI as the headline weak-ID-robust inference for $\phi$, a cluster bootstrap on $\phi$ would be a redundant third inference.
**Action:** add panel bootstrap CIs ($B = 500$, resample individuals with replacement, preserve all within-person waves) alongside the existing GMM SEs and inversion CIs in the tables that report the trajectory-specific $\hat\Delta_{\underline d}$ and $\hat\Delta_{\text{avg}}$.
Use bias-corrected percentile intervals.
**Target tables:** the main GRC results tables for CHN / IDN / TZA consumption (balanced and unbalanced), and the hukou-split tables for CHN.
The IDN unbalanced $K = 27$ specs are the highest priority because that's where the chi-squared bias is most likely to bite.
**Estimated cost:** $B = 500$ means 500 GMM fits per country-spec; parallelizable across cores; ~few hours per country.

---

## Active (low priority)

### Critic findings 4, 5, 2 in `lca_inversion.py`
**Added:** 2026-04-23 (re-flagged 2026-04-29).
**Status:** Postponed per user 2026-04-29.
**Action:** (a) detect rank loss in `pinv(V_R)` and use effective-rank chi-squared dof; (b) symmetric sparse-switcher drop (currently only treated person-years; should also drop too few untreated); (c) Stata-style cluster correction (covered above).
**Why low priority:** at $N$ in the thousands these are unlikely to move CIs at the third decimal; current published CIs in `lca_inversion_three_countries.md` are likely robust to all three fixes.

### Per-spec switcher keep-list (P-M2)
**Added:** 2026-04-29.
**Status:** Postponed.
**Context:** `run_all_countries_inversion.py:135` calls `drop_sparse_switchers` once on the full `df`; covs_2 / covs_all subset further when `education_max` etc.
are required, and a switcher with 5 treated pids on `df` may have $<5$ on `sub`.
**Action:** recompute `kept` inside the spec loop on `sub`; rerun and diff against `lca_inversion_three_countries.md`.
**Why low priority:** $N \approx 90{,}000$ for IDN unbalanced, similar for the other countries; the few switchers near the threshold are unlikely to flip.

### Smoke-test the .ster rename end-to-end
**Added:** 2026-04-24 (carryover).
**Status:** **Deferred indefinitely.** Full pipeline run is 30+ hours, so this only makes sense bundled with the next pipeline run we'd do anyway (e.g., real values branch merge, or the next coauthor handoff).
**Action:** `cd RP7/scripts && stata-mp -b do 0_master.do`.
Verify the renamed `.ster` files (commit `ff9a665`) don't collide and produce the same headline tables.

### Send the coauthor email about ster filename collision
**Added:** 2026-04-23.
**Status:** Pending small update.
**Action:** Edit `docs/communications/2026-04-23_ster-filename-collision-email.md` to note that the local fix is already in RP7 and will land for the team via ReplicationPackage7.
Send.
**Estimated cost:** ~10 min once decided.

### Rename `kappa` to `mu_dT` everywhere in the Stata GMM code
**Added:** 2026-04-29.
**Status:** **Low priority. Gated on the pipeline refactor branch (`worktree-grc-pipeline-refactor`) landing first**---do not attempt mid-refactor.
**Context:** Stata's `_b[kappa]` in `0_programs.do` (and matching parameter names in `e(b)` outputs and the `nlcom` formulas for `Delta_always`) actually represents $\mu_{d_T}$, the unobserved rural counterfactual mean for always-movers.
The paper's eq.\ at `paper/main.tex:376` reserves $\kappa_{d_T}$ for the observed urban mean $\mu_{d_T} + \Delta_{d_T}$, which is a different object.
The math in the code is correct (the `Delta_always` `nlcom` formula correctly computes the return $\Delta_{d_T} = \Delta_{\text{base}} + \phi(\mu_{d_T} - \mu_{d_0})$); the variable name is what's misleading.
**Action:** rename the GMM parameter from `kappa` to `mu_dT` (or `mu_always`) in `run_grc`, `run_grc_onestep`, `run_grc_robust_vv`, `run_grc_robust_vv_onestep`, `initial_values`, and any `nlcom` / table builder that references `_b[kappa]`.
Update `e(b)` consumers (`grc_tex_table*`, `heterogeneity_plots`, etc.) and the Python port's [`grc_gmm.py`](file:///C:/git/ckt/explorations/python-grc/grc_gmm.py) to match.
Decide whether `kappa_dT` (paper notation, observed urban mean) needs an explicit symbol anywhere in the code; probably not, since the GMM never reports it directly.
**Why low priority:** the misnaming has not caused any computational error---the LCA arithmetic that produces `Delta_always` is right.
The cost is a wide refactor of variable names across the .do files and several scripts.
Do this only after the pipeline refactor lands, so we don't compound merge churn.
**Estimated cost:** half a day, mostly mechanical, plus a smoke test to verify estimates are unchanged.

### Archive `grc_weak_id_inference.ado`
**Added:** 2026-04-29.
**Context:** Comparison on 2026-04-29 confirmed `grc_weak_id_inference.ado` (250 lines) is the legacy CI .ado from a prior paper.
Nothing in the current pipeline calls it.
The active production wrapper is `lca_inversion_ci.ado` (103 lines), which delegates to Python via `lca_inversion_ci_helper.py`.
**Action:** move `grc_weak_id_inference.ado` to `explorations/archive/` (or similar) with a one-line README pointing to the active .ado.
The two MAJOR bugs the 2026-04-29 stata-critic flagged (string-`if` evaluating numeric, and the `post` scalar-reference bug) are real but moot under archive.
**Estimated cost:** ~5 min.

---

## Completed

- **Verified `statsmodels` cluster correction matches Stata exactly.** Closed 2026-04-29.
Read `statsmodels.stats.sandwich_covariance.cov_cluster` source (statsmodels 0.14.2): `use_correction=True` multiplies the sandwich by `n_groups / (n_groups - 1) * (nobs - 1) / (nobs - k_params)`, which is Stata's $(N-1)/(N-K) \cdot G/(G-1)$ correction factor.
[`lca_inversion.py:125`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) already passes `use_correction=True`, so the formula matches.
At IDN/CHN/TZA sample sizes ($G \approx 30{,}000$, $N \approx 90{,}000$) the correction is sub-permille anyway; this was never going to move CIs at the third decimal.
The 2026-04-23 carryover finding #2 and the 2026-04-29 P-M3 are both formally closed.
Soft caveat: if statsmodels is bumped to a future version, re-verify the formula; statsmodels has changed cluster-correction semantics across releases.

- **rcond fix attempt for `_robust_inv` -> replaced with `_drop_sparse_moments`.** Closed 2026-04-24.
The original divergence was the **standard error** on covs_0: Stata SE 0.0705 vs Python SE 0.1943 (2.8x); $\hat\phi$ matched within 0.003.
[`FINDINGS_SE_phi.md`](file:///C:/git/ckt/explorations/python-grc/FINDINGS_SE_phi.md) traced this to a weighting-matrix convention difference and confirmed Python's variance formula correct (the matrix-level test in [`compare_stata_matrices.py`](file:///C:/git/ckt/explorations/python-grc/compare_stata_matrices.py) reproduces every Stata SE exactly when fed Stata's W).
The bump from `rcond=1e-10` to `1e-5` was tried on IDN covs_0 and failed: it broke `mu:switcher_27` identification (3 contributing pids) and drifted $\hat\phi$ from $-2.45$ to $-1.50$.
Reverted rcond to `1e-10`; replaced with explicit `_drop_sparse_moments(threshold=2)` in `grc_gmm.py` (drops only mechanically rank-1 moments).
A separate, later finding on covs_all (33% point-estimate gap; always-treated invariant matched between Python and Stata to 0.08% on that one spec) was tentatively interpreted as basin-switching on a flat $(\phi, \kappa)$ ridge, but **that interpretation has not been independently tested**.
Items in the active "Build the weak-ID-robust GMM toolkit" entry test it cleanly via $Q(\phi)$ profile, the always-treated invariant generalized across all 15 (country, spec) cells, and multistart.
Full context: [`HANDOFF_streamB.md`](file:///C:/git/ckt/.claude/worktrees/simulations/explorations/python-grc/HANDOFF_streamB.md) on the simulations worktree, [`2026-04-24_rcond-and-sparse-moment.md`](file:///C:/git/ckt/quality_reports/session_logs/2026-04-24_rcond-and-sparse-moment.md), [`FRESH_EYES_SE_phi.md`](file:///C:/git/ckt/explorations/python-grc/FRESH_EYES_SE_phi.md).

- **Island detection in LCA inversion CI.** Done 2026-04-29.
Added `find_islands` and `summary_curve_stats` to `explorations/python-grc/lca_inversion.py`; post-processing pass `explorations/python-grc/postprocess_islands.py` reads the saved `(phi, p_value)` parquets and writes `results/lca_inversion_islands.md` + `results/lca_inversion_islands_summary.csv`.
Two findings: (1) no multimodality at 95% or 90% in any country/spec, so the convex-hull CIs in `lca_inversion_three_countries.md` are honest; (2) CHN's max p across the entire `[-3, 1]` grid is 0.017 at covs_all, so the empty CIs are not borderline---pooled CHN LCA is rejected at 5% for every grid phi, strengthening the case that hukou splits are necessary.

- **Confirm trajectory-labeling convention for unbalanced observers.** Verified 2026-04-22, with correction.
First reading looked at `_2waves` / `_3waves` variants and was wrong about their role.
The main estimation uses `handle_trajectory_groups`, which executes `keep if !unbalanced` (`scripts/0_programs.do:199`): only balanced observers get a trajectory.
Unbalanced observers are pooled to `trajectory = 999` (line 1217)---one cell, not a set of partial-trajectory cells---with the $U_i$ dummy and $U_i \times \text{choice}$ interaction carrying their contribution.
The FWL orthogonality premise in `explorations/unbalanced_proposition.tex` holds; the proof's cell structure is simpler than the first draft suggested.
