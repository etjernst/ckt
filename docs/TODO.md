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

### Extend LCA inversion CI to the Verdier-robust (run_grc_robust_vv) spec
**Added:** 2026-04-24
**Context:** Verdier-style robust GRC (`run_grc_robust_vv`, committed today on the lca-inversion worktree's RP7 setup) uses village-demeaned optimal instruments per VV, with cluster-robust SEs at `vfirst` (first-wave province; $G \in \{13, 19, 22\}$). Early TZA result is $\hat\phi = -1.00$ (vs $-0.72$ for plain `run_grc` covs_all on TZA), tightening the pro-poor pattern. The LCA inversion CI is the natural inference companion --- but small $G$ makes the asymptotic $\chi^2$ for the cluster-robust Wald under-cover.
**Standard approach for this exact case:** wild cluster bootstrap (WCB) of the Wald statistic at each $\phi$ on the inversion grid, with critical values from the bootstrap distribution. CI = $\{\phi : p_{\text{boot}}(\phi) \geq \alpha\}$. Citations:
- Stock & Wright (2000) "GMM with Weak Identification", *Econometrica* --- the AR-style S-statistic.
- Kleibergen (2005) "Testing Parameters in GMM without Assuming that They are Identified", *Econometrica* --- the K-statistic.
- Cameron, Gelbach & Miller (2008) "Bootstrap-Based Improvements for Inference with Clustered Errors", *ReStat* 90(3) --- WCB for clustered errors.
- Davidson & MacKinnon (2010) "Wild Bootstrap Tests for IV Regression", *J Bus Econ Stat* 28(1).
- Finlay & Magnusson (2009) "Implementing Weak-Instrument Robust Tests for a General Class of Instrumental-Variables Models", *Stata J* 9(3) --- the basis for `weakiv`; combines AR-style inversion with bootstrap critical values.
- Roodman, Nielsen, MacKinnon & Webb (2019) "Fast and Wild: Bootstrap Inference in Stata Using boottest", *Stata J* 19(1) --- explicitly endorses WCB combined with AR-type tests in IV and GMM.
**Action:** extend `lca_inversion.py`:
1. Add `cluster_var` argument (default `"pid"`; for Verdier-robust, pass `"vfirst"`).
2. Auto-include `vfirst` fixed-effects as controls in the auxiliary OLS (mirrors VV's within-village demeaning).
3. Revise `drop_sparse_switchers` to count by `cluster_var` not `pid` (asks: is the switcher observed in enough vfirsts?).
4. Wrap the per-grid-point Wald computation in a wild cluster bootstrap (B=999, Rademacher at the cluster level, residuals from the LCA-restricted fit). Cost: $\sim 30$ min per spec.
5. Validate against `boottest` after `gmm` on a synthetic dataset where the answer is known.
**Dependency:** Verdier P3 sign-off (the conceptual LCA-restriction derivation in the village-demeaned framework is still in flux; current derivation memo §5 explicitly flags the asymptotic-vs-finite-sample equivalence as needing revision).
**Estimated cost:** $\sim 1$--2 days once dependency clears.

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

### Switch vanilla VV implementation from `vfirst` to fine-grained sub-province cluster
**Added:** 2026-05-08
**Context:** The vanilla VV port currently clusters at `vfirst` (first-wave province). Mistaken reading of Verdier (2020): we saw "province" in his Step 1 covariates and missed that $v_i$ in his Step 2 robust IV is *village* (~94 villages, ~12 farmers each in Suri-Kenya), one administrative level *below* province. Audit of our processed `.dta` files (2026-05-08) finds we have direct village-equivalents:
- **CHN**: `cid` (community), ~4,066 distinct, ~16 workers each.
- **IDN**: `keca` (kecamatan / subdistrict), ~1,669 distinct, ~22 workers each.
- **TZA**: `ward`, ~135 distinct, ~152 workers each.
**Action:** rewire `_vv_firststage_projection` and `run_vv_vanilla` (in `RP7/scripts/0_programs.do`) to take a cluster-variable argument; set the analog of Verdier's village ($v_i$) per country; rerun the V1 sweep at the corrected granularity. Province ($\texttt{vfirst}$) can stay as a covariate (province$\times$year FE in Step 1) per VV §4.1.
**Cost:** ~1 day of plumbing + reruns.
**Why it matters:** the current `vfirst` clustering is one administrative level coarser than VV's. If the V1 results disagreed with CKT-vv at the wrong granularity, the disagreement may be a clustering-level artifact, not an identification issue.

### Counterfactual experiments leveraging CKT's two-skill structure
**Added:** 2026-05-08
**Context:** CKT's structural model decomposes outcomes into rural / urban skills $\theta_i^R$ and $\theta_i^U$ separately, with location-specific prices $b_R, b_U$. Verdier's framework is agnostic about the structural origin of $a_i$ and $b_i$ and cannot decompose returns into skill prices vs skill quantities. **This is a substantive advantage of our model that is not currently emphasized in the paper.**
**Action:** brainstorm and document concrete counterfactual policy experiments that require the two-skill decomposition:
- *Urban skill premium policy*: e.g., what if $b_U$ rose by $X\%$ (urban wage compression policies)? CKT's model predicts how $\Delta_i$ changes; VV's reduced form cannot.
- *Rural skill upgrading*: e.g., what if $\theta_i^R$ rose for low-skill workers (rural training programs)? Predicts effect on $\Delta_i$.
- *Differential migration costs*: a policy that lowers the migration cost for low-$\theta^R$ workers vs high-$\theta^R$ workers.
- *Asymmetric education effects*: schooling that raises urban skill more than rural skill.
**Why it matters:** referees may ask "why not just adopt VV's estimator?" The clean answer is that CKT's structural model lets us run counterfactual policy experiments that VV's reduced-form framework cannot. This is potentially a major paper-level argument.
**Status:** decided as a high-priority follow-up after the methodology section is locked.

### Empirical hint of A3 (trajectory-pooling) validity
**Added:** 2026-05-08
**Context:** A3 ("trajectory pooling") says $E[\theta_i \mid \underline d_i = s, v_i = v]$ is the same across clusters $v$ within trajectory $s$. $\theta_i$ is unobservable, so no exact test exists. But in CKT's single-skill reduction, $\theta_i$ tracks rural baseline $a_i$, and we have an existing alpha-pooling diagnostic (`docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md`) that probes this.
**Action:** surface and consolidate three forms of A3 diagnostic into a single section of the paper / appendix:
1. **Hansen J / overid test** from `run_vv_vanilla` and `run_grc_robust_vv` (already produced; under-publicized).
2. **Trajectory-by-cluster mean comparison.** For each switcher trajectory $d$, regress $\hat a_i$ on cluster dummies; F-test the joint significance of the dummies. Repeat for $\hat\Delta_i$. Report by country and trajectory.
3. **Visual scatter** of $(\hat\mu_{d,v}, \hat\Delta_{d,v})$ trajectory-cluster cell means, faceted by trajectory. Drift across clusters within a trajectory hints A3 fails.
**Why it matters:** A3 is the load-bearing assumption for CKT-vv (and CKT-main). When A3 fails, CKT estimators pick up bias; VV's worker-level stays consistent. Some empirical hint that A3 is approximately true would substantially strengthen the case for CKT-vv vs adopting VV directly.

---

## Completed

- **Resolve SE($\phi$) divergence between Python and Stata GMM.** Tried `rcond` bump first (option 1 from 2026-04-23 plan); cascaded through iterated GMM and broke other-switcher identification. Switched to explicit pre-drop of moments with $<$ 2 contributing clusters (option 2, threshold = 2). Implemented as `_drop_sparse_moments` in `grc_gmm.py`; only the rank-1 `switcher_11` moments get dropped. SE gap remains: this is **not** an implementation bug but **finite-sample basin-switching on the weakly-identified $(\phi, \kappa)$ ridge.** Both implementations agree on the always-treated fit $\kappa + \phi(\kappa - \mu_{\text{base}})$ to $0.01$. Decided to accept the gap and rely on the LCA inversion CI as the primary inference. Documented in `quality_reports/session_logs/2026-04-24_rcond-and-sparse-moment.md`. Followup multistart simulation tracked above.

- **Confirm trajectory-labeling convention for unbalanced observers.** Verified 2026-04-22, with correction. First reading looked at `_2waves` / `_3waves` variants and was wrong about their role. The main estimation uses `handle_trajectory_groups`, which executes `keep if !unbalanced` (`scripts/0_programs.do:199`): only balanced observers get a trajectory. Unbalanced observers are pooled to `trajectory = 999` (line 1217) --- one cell, not a set of partial-trajectory cells --- with the $U_i$ dummy and $U_i \times \text{choice}$ interaction carrying their contribution. The FWL orthogonality premise in `explorations/unbalanced_proposition.tex` holds; the proof's cell structure is simpler than the first draft suggested.
