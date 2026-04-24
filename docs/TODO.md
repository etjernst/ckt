# Project to-do list (CKT migration paper)

Persistent to-do list for items that are decided but not yet in progress.
Append dated entries. Move completed items to the bottom with a strike-through or a completion date.

---

## Active

### Wire LCA inversion CI into all GrRC scripts (5/6/8/10--15)
**Added:** 2026-04-23
**Context:** A prototype Stata-Python wrapper `lca_inversion_ci.ado` (in `explorations/python-grc/`) attaches the weak-ID-robust CI for $\phi$ to a saved GMM estimate as plain $e()$ scalars. Demonstrated for IDN/cons/urban/unb. Currently called explicitly after `run_grc`; not yet wired into the production pipeline.
**Action:** After the prototype is validated on all three countries and the headline IDN spec, integrate the call site into:
- `5_GrRC.do` (urban) and `6_GrRC_NonAg.do` (nonag) --- right after each `run_grc` block.
- Hukou splits in `8_GrRC_hukou.do` (which uses `run_grc_hukou`; may need a parallel `lca_inversion_ci_hukou` or argument tweak).
- The experience family `10_GrRC_experience.do`, `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do`, `14_GrRC_NonAg_experience.do`, and `15_GrRC_birth.do`.
- Update `grc_tex_table_trend` and any other table-generating programs in `0_programs.do` to read $e(\text{inv\_ci95\_lo})$, $e(\text{inv\_ci95\_hi})$ (and 90%) and add them as a row in the LaTeX tables.
**Cost:** ~1 day once the prototype is locked. Best done after the rcond fix and the ster-filename rename PR land.
**Dependency:** ster-filename collision fix (separate TODO via the coauthor email) should land first to avoid mixing inversion CIs across choice / experience specs.

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

### Multistart GMM-basin diagnostic simulation
**Added:** 2026-04-24
**Context:** On IDN/cons/urban/unb covs_all, Python iterated GMM and Stata twostep land at meaningfully different points on the $(\phi, \kappa)$ ridge --- Stata $\hat\phi = -0.526$, Python $\hat\phi = -0.707$ --- but agree to 0.01 on the always-treated fit $\kappa + \phi(\kappa - \mu_{\text{base}})$. Same model, same data, different decomposition into the unidentified $(\phi, \kappa)$ components. Both lie inside the LCA-inversion 95% CI of $[-1.23, -0.01]$.
**Concern:** the proposed paper sentence about basin-switching is based on a single dataset. A systematic check is needed to know how common this is.
**Action:** secondary simulation exercise (after the main coverage simulation):
1. **Pilot:** $R = 30$ synthetic data sets at CKT calibration, $K = 3$ Python multistarts per data set. Tabulate: distribution of $\hat\phi$, within-sample basin spread $\max\hat\phi - \min\hat\phi$, and the always-treated fit (should be invariant on the ridge). $\sim 18$ hours.
2. **If pilot shows basin-switching is common:** scale to $R = 100, K = 5$ ($\sim 100$ hours).
3. **Optional Stata-Python cross-check:** run Stata GMM on $R_{\text{cross}} = 10$ data sets to confirm the cross-language pattern matches the within-Python multistart pattern. $\sim 4$ hours.
**Deliverable:** histogram or table of basin-switching frequency, supporting (or refining) the paper's weak-identification claim.
**Status:** decided, deferred until Stream C primary simulation is in flight.

---

## Completed

- **Resolve SE($\phi$) divergence between Python and Stata GMM.** Tried `rcond` bump first (option 1 from 2026-04-23 plan); cascaded through iterated GMM and broke other-switcher identification. Switched to explicit pre-drop of moments with $<$ 2 contributing clusters (option 2, threshold = 2). Implemented as `_drop_sparse_moments` in `grc_gmm.py`; only the rank-1 `switcher_11` moments get dropped. SE gap remains: this is **not** an implementation bug but **finite-sample basin-switching on the weakly-identified $(\phi, \kappa)$ ridge.** Both implementations agree on the always-treated fit $\kappa + \phi(\kappa - \mu_{\text{base}})$ to $0.01$. Decided to accept the gap and rely on the LCA inversion CI as the primary inference. Documented in `quality_reports/session_logs/2026-04-24_rcond-and-sparse-moment.md`. Followup multistart simulation tracked above.

- **Confirm trajectory-labeling convention for unbalanced observers.** Verified 2026-04-22, with correction. First reading looked at `_2waves` / `_3waves` variants and was wrong about their role. The main estimation uses `handle_trajectory_groups`, which executes `keep if !unbalanced` (`scripts/0_programs.do:199`): only balanced observers get a trajectory. Unbalanced observers are pooled to `trajectory = 999` (line 1217) --- one cell, not a set of partial-trajectory cells --- with the $U_i$ dummy and $U_i \times \text{choice}$ interaction carrying their contribution. The FWL orthogonality premise in `explorations/unbalanced_proposition.tex` holds; the proof's cell structure is simpler than the first draft suggested.
