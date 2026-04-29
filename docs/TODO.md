# Project to-do list (CKT migration paper)

Persistent to-do list for items that are decided but not yet in progress.
Append dated entries.
Move completed items to the bottom with the resolution date.

---

## Active

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

### Add panel bootstrap CIs for $\hat\Delta_{d_N}$ and $\hat\Delta_{d_T}$ in main tables
**Added:** 2026-04-22 (scope narrowed 2026-04-29).
**Branch:** TBD (depends on whether bootstrap is computed on Stream B or Stream A).
**Context:** Default GMM CIs may under-cover for the trajectory-specific extrapolated returns $\hat\Delta_{d_N}$ and $\hat\Delta_{d_T}$ because they combine the LCA slope with extrapolation distance to the never-mover mean.
**Scope narrowed 2026-04-29:** original entry covered $\hat\phi$ too, but with the LCA inversion CI as the headline weak-ID-robust inference for $\phi$, a cluster bootstrap on $\phi$ would be a redundant third inference.
Bootstrap is more useful for $\Delta_{d_N}$ and $\Delta_{d_T}$ (no inversion analog).
**Action:** add panel bootstrap CIs ($B = 500$, resample individuals with replacement, preserve all within-person waves) alongside the existing GMM SEs in the tables that report the trajectory-specific $\hat\Delta_{\underline d}$.
Use bias-corrected percentile intervals.
**Target tables:** the main GRC results tables for CHN / IDN / TZA consumption (balanced and unbalanced), and the hukou-split tables for CHN.
**Scope caveat:** hold until simulation coverage results land in case the under-coverage risk turns out to be small.
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
