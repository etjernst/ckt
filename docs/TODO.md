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

### Island detection and reporting in LCA inversion CI
**Added:** 2026-04-23
**Context:** The grid inversion for $\phi$ in the LCA test (`docs/plans/2026-04-23-lca-inversion-ci-ckt.md`) takes the outermost `min` and `max` of the non-rejected grid as the CI endpoints. Under regime heterogeneity (likely in CHN given the hukou-split J-rejection) the (phi, p) curve may be multimodal --- two or more disconnected non-rejected regions. Reporting only the outer min/max hides the gap and overstates CI coverage.
**Action:** After the grid run, walk the (phi, p_value) curve and flag disconnected non-rejected regions. Report each as `[low_k, high_k]`. If multiple islands, the paper should say so explicitly --- it is informative about identification.
**Estimated cost:** ~30 min of code (numpy diff on the indicator vector + group consecutive runs). Add to the inversion runner once the basic implementation works.

### Port rcond fix into Python `_robust_inv`
**Added:** 2026-04-23
**Context:** The 2.8x SE($\phi$) divergence between Python's iterated GMM and Stata's twostep was traced to Python's `np.linalg.pinv(S, rcond=1e-10)` keeping a near-zero singular value associated with rank-deficient moments at sparse switcher trajectories (e.g., `switcher_11` in IDN has 1 cluster contributing). Stata uses a generalized inverse with a stricter tolerance that drops the rank-deficient direction --- this is its documented behavior for singular S. Python should match.
**Action:** In `explorations/python-grc/grc_gmm.py`, change `_robust_inv` to use `rcond` ≈ `1e-5` (or detect singular values below a relative threshold and zero them out). After the fix, re-run the IDN/cons/urban/unb verification; SE($\phi$) should drop from 0.20 to ~0.07, matching Stata. Then re-validate against CHN and TZA.
**Decided approach:** Option 1 (tighten rcond) over Option 2 (pre-drop sparse moments by cluster count) per user 2026-04-23, on the grounds that it more closely mirrors Stata's documented behavior.
**Estimated cost:** 1 line change + ~30 min revalidation per country.
**Status:** Decided, not yet implemented.

---

## Completed

- **Confirm trajectory-labeling convention for unbalanced observers.** Verified 2026-04-22, with correction. First reading looked at `_2waves` / `_3waves` variants and was wrong about their role. The main estimation uses `handle_trajectory_groups`, which executes `keep if !unbalanced` (`scripts/0_programs.do:199`): only balanced observers get a trajectory. Unbalanced observers are pooled to `trajectory = 999` (line 1217) --- one cell, not a set of partial-trajectory cells --- with the $U_i$ dummy and $U_i \times \text{choice}$ interaction carrying their contribution. The FWL orthogonality premise in `explorations/unbalanced_proposition.tex` holds; the proof's cell structure is simpler than the first draft suggested.
