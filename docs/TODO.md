# Project to-do list (CKT migration paper)

Persistent to-do list for items that are decided but not yet in progress.
Append dated entries. Move completed items to the bottom with a strike-through or a completion date.

---

## Active

### Add panel bootstrap CIs to main empirical tables
**Added:** 2026-04-22
**Context:** Default GMM CIs may under-cover for the headline objects --- $\hat\phi$, $\hat\Delta_{d_N}$, $\hat\Delta_{d_T}$ --- because they combine the LCA slope with extrapolation distance to the never-mover mean. The simulation (Exercise 1 in `explorations/SIMULATION_PLAN.md`) will tell us whether the under-coverage risk materializes.
**Action:** Add panel bootstrap CIs ($B=500$, resample individuals with replacement, preserve all within-person waves) alongside the existing GMM SEs in the tables that report $\hat\phi$ and the trajectory-specific $\hat\Delta_{\underline d}$. Use bias-corrected percentile intervals.
**Target tables:** The main GRC results tables for CHN / IDN / TZA consumption (balanced and unbalanced), and the hukou-split tables for CHN.
**Scope caveat:** Hold until simulation results land in case the coverage check is clean, in which case bootstrap is still good practice to report but lower-priority.
**Estimated cost:** $B=500$ means 500 GMM fits per country-spec. With the Python GMM implementation from `explorations/simulations/`, this is parallelizable across cores and should take a few hours per country.

---

### Port rcond fix into Python `_robust_inv`
**Added:** 2026-04-23
**Context:** The 2.8x SE($\phi$) divergence between Python's iterated GMM and Stata's twostep was traced to Python's `np.linalg.pinv(S, rcond=1e-10)` keeping a near-zero singular value associated with rank-deficient moments at sparse switcher trajectories (e.g., `switcher_11` in IDN has 1 cluster contributing). Stata uses a generalized inverse with a stricter tolerance that drops the rank-deficient direction --- this is its documented behavior for singular S. Python should match.
**Action:** In `explorations/python-grc/grc_gmm.py`, change `_robust_inv` to use `rcond` ≈ `1e-5` (or detect singular values below a relative threshold and zero them out). After the fix, re-run the IDN/cons/urban/unb verification; SE($\phi$) should drop from 0.20 to ~0.07, matching Stata. Then re-validate against CHN and TZA.
**Decided approach:** Option 1 (tighten rcond) over Option 2 (pre-drop sparse moments by cluster count) per user 2026-04-23, on the grounds that it more closely mirrors Stata's documented behavior.
**Estimated cost:** 1 line change + ~30 min revalidation per country.
**Status:** Decided, not yet implemented.

---

## Completed

- **Island detection in LCA inversion CI.** Done 2026-04-29. Added `find_islands` and `summary_curve_stats` to `explorations/python-grc/lca_inversion.py`; post-processing pass `explorations/python-grc/postprocess_islands.py` reads the saved `(phi, p_value)` parquets and writes `results/lca_inversion_islands.md` + `results/lca_inversion_islands_summary.csv`. Two findings: (1) no multimodality at 95% or 90% in any country/spec, so the convex-hull CIs in `lca_inversion_three_countries.md` are honest; (2) CHN's max p across the entire `[-3, 1]` grid is 0.017 at covs_all, so the empty CIs are not borderline---pooled CHN LCA is rejected at 5% for every grid phi, strengthening the case that hukou splits are necessary.

- **Confirm trajectory-labeling convention for unbalanced observers.** Verified 2026-04-22, with correction. First reading looked at `_2waves` / `_3waves` variants and was wrong about their role. The main estimation uses `handle_trajectory_groups`, which executes `keep if !unbalanced` (`scripts/0_programs.do:199`): only balanced observers get a trajectory. Unbalanced observers are pooled to `trajectory = 999` (line 1217) --- one cell, not a set of partial-trajectory cells --- with the $U_i$ dummy and $U_i \times \text{choice}$ interaction carrying their contribution. The FWL orthogonality premise in `explorations/unbalanced_proposition.tex` holds; the proof's cell structure is simpler than the first draft suggested.
