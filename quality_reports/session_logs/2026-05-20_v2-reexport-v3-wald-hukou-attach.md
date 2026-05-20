# 2026-05-20: V2 re-export, V3 Wald diagnostic + fix, CHN hukou RF/UF inversion attach

## If you resume

**Open thread.**
V3 plumbing is now sound for IDN and TZA at column 5, and the CHN hukou-split RF and UF cuu_ca cells have inversion CIs attached.
The natural next step is a CHN-hukou variant of the V3 joint-CI driver that loads `CHN_hukou_rural_first_unb.dta` and `CHN_hukou_urban_first_unb.dta`, fits the auxiliary OLS with matched spec, and propagates the E1 aggregate through the joint CI for each regime separately.

**Next concrete action.**
Fork [explorations/2026-05-20_e1_v3_joint_ci.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci.py) into a hukou variant that loops over `CHN_hukou_rural_first` and `CHN_hukou_urban_first`.
The data files have the same column structure (`consumption`, `hhsize_cube`, `trajectory`, `choice`, `pid`, plus the covariates), and `attach_inversion_ci` already verified the OLS sample selection works.
Two cells to compute, then propagate the misallocation aggregate through each.
For UF, expect that the entire accepted region sits below the Möbius pole at $\phi = -1$, so the $d_T$ piece will blow up; the P3 fallback (drop $d_T$, report aggregate as $d_N$ plus switchers) is essential for UF.

**Files to read first.**

- [docs/notes/2026-05-20_chn_hukou_inversion_attach.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_chn_hukou_inversion_attach.md): RF and UF inversion scalars, with the open items at the bottom.
- [docs/notes/2026-05-20_e1_v3_joint_ci.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_e1_v3_joint_ci.md): IDN and TZA joint CI results, plus CHN E1 reporting convention captured at the bottom.
- [docs/notes/2026-05-20_e1_v3_wald_at_gmm.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_e1_v3_wald_at_gmm.md): the auxiliary-OLS spec-match fix that unblocked V3.
- [explorations/2026-05-20_e1_v3_joint_ci.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci.py): the working driver to fork.

**Cached state to know.**

- IDN col 5 misallocation gap (point estimate, unchanged from V2): $+0.0617$ log pts ($+6.36\%$).
  Joint CI convex hull: $[+5.7\%, +45.6\%]$.
  GMM point accepted in joint CI (Wald 24.2 vs threshold 40.1).
- TZA col 5 misallocation gap (point estimate, unchanged from V2): $+0.3251$ log pts ($+38.42\%$).
  Joint CI convex hull goes to $+171\%$ at the top because the accepted region crosses the Möbius pole.
  GMM point accepted (Wald 3.1 vs threshold 11.1).
- CHN-RF cuu_ca: $\hat\phi = -0.16$, ci95 $[-0.30, +0.01]$; $\hat\Delta_{d_N} = +0.11$, ci95 $[+0.09, +0.13]$.
- CHN-UF cuu_ca: $\hat\phi = -3.00$, ci95 $[-\infty, -0.77]$; $\hat\Delta_{d_N} = -0.23$, ci95 $[-0.56, +0.11]$.
  UF's $\phi$ CI sits entirely below $\phi = -1$, so $d_T$ is unbounded; P3 essential.
- Commits on this branch today: `907492a` (V2 memo re-verify), `aa1acde` (Wald-at-GMM diagnostic), `09d5da3` (V3 joint CI matched spec), `f533b5d` (5c hukou attach).
  All clean; no uncommitted state.

**After the CHN-hukou V3 driver.**

1. **P3 Möbius-pole fallback** in `counterfactuals.py`: when the accepted region crosses $\phi = -1$, evaluate the aggregate as $\pi_{d_N} \Delta_{d_N} \bar D_{d_N} + \sum_{s \in \mathcal{D}_S} \pi_s \Delta_s \bar D_s$ (drop the $d_T$ piece).
   Report both versions in the driver's output so readers can see how much of the upper bound is pole-driven.
2. **`project_image_intervals` binning artifact**: at small $N$ of finite values, the function reports phantom islands (one bin per value).
   Fix by sizing the bin lattice from the count of finite values.
   Convex hull is unaffected; only the per-interval breakdown is wrong.
3. **Residual upper-bound disagreement with 5b**: Python's marginal $\phi$ CI for IDN goes to $+0.90$; 5b's attached CI stops at $-0.01$.
   Lower bounds agree.
   Likely a sample-selection or `attach_inversion_ci` procedure difference; the cleanest probe is a Stata-vs-Python side-by-side aux-OLS at one $\phi$ grid point.
4. **E1 trajectory-share exporter for hukou subsamples**: `_export_e1_inputs.do` loops over IDN and TZA only; a parallel `_export_e1_inputs_hukou.do` is needed to feed the CHN-hukou V3 driver with $\pi_{\underline{d}}$, $\bar D_{\underline{d}}$, $\mu_{\underline{d}}$, and the switcher $\Delta_d$ from the `_d` ster.
   Probably should land before the V3 hukou driver so the inputs are persisted to CSV.
5. **RO and UO inversion attach** (Task #3): extend the foreach loop in `5c_inversion_hukou.do`.
   Lower priority; can be batched with the figures-side robustness work.
6. **Bib entries** for Kennan and Walker (2011), Tombe and Zhu (2019), Fan (2019).
   Inline `TODO` cites still in [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).

---

## Goals

The user asked first for the status of E1 in the paper draft and the V2/V3 numerics, then for a re-export of V2 against the canonical RP7 sters.
After that, the Wald-at-GMM diagnostic for the V3 IDN empty-CI puzzle.
Then, with the diagnostic done, V3 plumbing was fixed and re-run.
The session closed on Task #2 (CHN hukou RF and UF inversion attach), with RO and UO deferred to Task #3.
Throughout, the user wanted a single-headline view of E1 with the option to bracket CHN with both an RF-vs-UF split and a population-weighted aggregate.

## What got built or changed

**V2 re-export and memo update.**

- Re-ran [RP7/scripts/_export_e1_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs.do) against the canonical RP7 sters.
  The refreshed CSVs in `RP7/output/counterfactual_inputs/` are bit-identical to the pre-existing `counterfactual_inputs_rp5/` snapshot, so the V2 point-estimate aggregate is unchanged after the data and ster swap.
- Updated [docs/notes/2026-05-18_e1_v2_check.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-18_e1_v2_check.md) with a 2026-05-20 re-verify stamp and refreshed the Next steps section to point at the V3 IDN diagnostic.
  Commit `907492a`.

**V3 Wald-at-GMM diagnostic.**

- New driver: [explorations/2026-05-20_e1_v3_wald_at_gmm.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_wald_at_gmm.py).
  Evaluates the constrained-$J$ inside `build_joint_ci_grid` at the IDN col 5 GMM point.
- First pass (using the smoke driver's defaults: `log(consumption)`, no controls) gave Wald = $846$ vs threshold $40$.
  The auxiliary OLS $\hat\beta_2 = +0.83$ differed from the GMM $\hat\Delta_2 = +0.07$ by a factor of 12; the auxiliary regression was estimating a different population object than the GMM specification it was supposed to invert.
- Memo: [docs/notes/2026-05-20_e1_v3_wald_at_gmm.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_e1_v3_wald_at_gmm.md).
  Diagnosed the spec mismatch against [5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do): 5b uses `outcome = log(consumption/hhsize_cube)` and `controls = periodFE + female + age2 + education_max + education_max2`.
  Re-running with the matched spec dropped the Wald to $24$ and the marginal CI from `grid_lca_inversion` became non-empty.
  Commit `aa1acde`.

**V3 joint CI with matched spec.**

- New driver: [explorations/2026-05-20_e1_v3_joint_ci.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci.py) (supersedes the 2026-05-18 smoke).
  Uses the GMM-matched outcome, controls, and sample selection; refined lattice to $301 \times 101$ (0.01 spacing on both axes).
- IDN: 2,543 of 30,401 lattice points accepted in one connected component; marginal $\phi$ $[-1.21, +0.90]$, $\beta$ $[-0.04, +0.15]$; aggregate misallocation gap convex hull $[+5.7\%, +45.6\%]$.
- TZA: 768 of 30,401 accepted; marginal $\phi$ $[-1.37, -0.40]$, $\beta$ $[+0.08, +0.18]$; aggregate gap convex hull $[+14.3\%, +171.0\%]$, but the $+171\%$ upper bound is the Möbius pole, not a credible CI endpoint.
- Memo: [docs/notes/2026-05-20_e1_v3_joint_ci.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_e1_v3_joint_ci.md).
  Captures the agreed CHN E1 reporting convention at the bottom.
  Commit `09d5da3`.

**CHN hukou RF and UF inversion attach (Task #2).**

- New Stata driver: [RP7/scripts/5c_inversion_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5c_inversion_hukou.do) (parallel to 5b).
  Loops `country in CHN_hukou_rural_first CHN_hukou_urban_first` with the country-to-country_short mapping from `7_GrRC_hukou.do` (`_rural_first -> CHN_rf`, `_urban_first -> CHN_uf`).
  The if/else mapping inside the foreach loop already includes the lines for `_rural_only -> CHN_ro` and `_urban_only -> CHN_uo`, so adding RO and UO is a one-line edit to the foreach iterator.
- Wrapper: [RP7/scripts/_run_5c_for_attach.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_run_5c_for_attach.do).
- Inversion scalars attached to `grc_CHN_rf_cuu_ca{,_n,_g,_a}.ster` and `grc_CHN_uf_cuu_ca{,_n,_g,_a}.ster`.
  The c0/ct/c1/c2 sters skipped because the worktree only has the `_ca` parent sters.
- Memo: [docs/notes/2026-05-20_chn_hukou_inversion_attach.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_chn_hukou_inversion_attach.md).
  Commit `f533b5d`.

## Decisions, with the why

**Decision: spec-mismatch in `fit_auxiliary_ols` is the root cause of the V3 IDN empty-CI, not a bug in `build_joint_ci_grid`.**
Why: the auxiliary OLS $\hat\beta_2 = +0.83$ at the base switcher differs from the GMM $\hat\Delta_2 = +0.07$ by a factor of 12.
Both should be the urban-rural shift for trajectory 2 in log per-capita consumption.
The discrepancy localizes to the auxiliary regression itself: 5b uses `lndepvar = log(consumption/hhsize_cube)` with period FE plus `covs_gmm_all` controls, while the smoke driver used `log(consumption)` with no controls.
Matching the spec dropped the Wald from $846$ to $24$, confirming the diagnosis.

**Decision: fix the V3 driver in `explorations/` rather than modifying `fit_auxiliary_ols`'s defaults.**
Why: `fit_auxiliary_ols` already supports `controls=` and a configurable `outcome=`.
The bug was at the call site, not in the function.
A defaults change in `fit_auxiliary_ols` would silently affect downstream code that may have relied on the old defaults.
Fixing at the call site is targeted and easy to audit.

**Decision: lattice spacing $0.01$ on both axes for the joint CI.**
Why: prior smoke used 121 phi $\times$ 51 beta = 6,171 points (0.025 spacing on phi, 0.02 on beta), which is too coarse for clean marginal projections near the GMM point.
The new $301 \times 101$ lattice runs in seconds (one V_m inversion per phi, constant in beta), and the marginal projection rounding error drops to $\pm 0.005$.

**Decision: 5c_inversion_hukou.do as a parallel script rather than extending 5b.**
Why: 5b handles three pooled countries with the same data prep code path.
The hukou subsamples are stored in separate `.dta` files (`CHN_hukou_rural_first_unb.dta`, etc.) and use the `country_short` naming convention from `7_GrRC_hukou.do`.
Mixing the two code paths in a single script would either require an inner branch on whether the country is pooled or hukou-split, or hidden state setting `country_short` for some branches and not others.
A parallel script keeps 5b's pooled logic untouched, which protects the (already verified) inversion CIs on the pooled IDN/TZA/CHN sters.

**Decision: route CHN through hukou splits in E1, with both regime-separate and weighted-aggregate reporting.**
Why: pooled CHN's $J$-test rejects, so the pooled inversion CIs are empty by construction.
The hukou split passes the $J$-test within regime.
Reporting both separately (RF and UF as two counterfactuals) and as a population-weighted aggregate (the "national" CHN E1) lets us see what each regime contributes and then choose the headline once the magnitudes are visible.
The user explicitly chose this both-then-reconcile approach over picking one upfront.

**Decision: defer RO and UO inversion attach to Task #3.**
Why: the user explicitly flagged RF and UF as the priority because they carry the headline E2 contrast (rural-first vs urban-first hukou).
RO and UO are "only-ever-rural" and "only-ever-urban" subsets, lower priority for the headline, and easy to add later via a one-line edit to the foreach loop in 5c_inversion_hukou.do.

## Approaches rejected, with the reason

**Tried: editing the existing 2026-05-18 V3 smoke driver in place.**
Rejected because: dated exploration files in this project are versioned by date in the filename.
Editing the 2026-05-18 file to reflect a 2026-05-20 fix would lose that history.
Created a new dated driver 2026-05-20_e1_v3_joint_ci.py that supersedes the smoke; both files now coexist in git.

**Tried: querying ster scalars by reading the raw .ster file in Python.**
Rejected because: the .ster format is Stata-internal and not exposed through pystata's standard API for full inspection.
Used the mcp-stata `default` session instead, which can `estimates use` and `di e(...)` directly.
Took two attempts: first call hit the path-safety guard (sters live outside the project root because RP7/output is technically a real dir but its parent is gitignored), second call passed with `allow_unsafe_paths: true`.

**Tried: running `stata-mp -e do _run_5c_for_attach.do` from the worktree root with a relative path.**
Rejected because: the wrapper sets `\$dir` via `c(username)` and then includes `\$dir/scripts/0_path_config.do`, so it does not care which directory it is launched from.
But running from the worktree root left the Stata log in the worktree root rather than in the `\$logs` directory.
Switched to running from `RP7/scripts/` so the log lands in the canonical location alongside other Stata logs.

**Tried: spawning a TaskCreate before each substantive step.**
Partially rejected: created task entries for the three milestone items (Wald diagnostic, hukou RF/UF attach, hukou RO/UO attach) at the start of that work, but did not create granular tasks for intermediate diagnostics inside each milestone.
The task list works at the milestone level, not the per-action level.
Granular tasks would just rot.

## Open items and blockers

1. **CHN-hukou V3 joint-CI driver** is the immediate next step.
   No blocker; the RF/UF inversion scalars are in place and the data files exist.
2. **TZA P3 Möbius-pole fallback** in `counterfactuals.py`.
   The TZA upper bound on the misallocation gap is currently inflated to $+171\%$ by the pole; honest reporting requires the fallback.
3. **`project_image_intervals` binning artifact** at low $N$.
   The IDN and TZA convex hulls are fine; the per-interval breakdown reports 29-42 phantom islands inside a single connected accepted region.
   Convex hull is the right summary until the binning is fixed.
4. **Residual upper-bound disagreement with 5b** on IDN's marginal $\phi$ CI.
   Python with matched spec gives $[-1.21, +0.90]$; 5b's attached scalar is $[-1.23, -0.01]$.
   Lower bounds agree.
   Worth a Stata-vs-Python side-by-side aux-OLS at one phi grid point to localize.
5. **E1 trajectory-share exporter for the hukou subsamples.**
   `_export_e1_inputs.do` is IDN/TZA only; a parallel `_export_e1_inputs_hukou.do` is needed before the CHN-hukou V3 driver can read trajectory CSVs.
6. **RO and UO inversion attach** (Task #3).
   One-line edit to the foreach loop in `5c_inversion_hukou.do`.
   Lower priority; can be batched with figure-side robustness.
7. **Bib entries** for Kennan and Walker (2011), Tombe and Zhu (2019), Fan (2019).
   Inline `TODO` cites still in [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex).

## Picking back up

Read the "If you resume" block at the top of this file.
The first concrete action is the CHN-hukou V3 joint-CI driver; the data files exist, the inversion scalars are attached, and the existing IDN/TZA driver is the template to fork.
After that, P3 Möbius-pole fallback (TZA and UF both need it), then the trajectory-share exporter, then RO/UO inversion attach.
