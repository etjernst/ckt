# 2026-05-19: counterfactual implementation, V1 / V2 / V3 smoke

## If you resume

**Open thread.**
V3 IDN col 5 joint CI returns 0 of 6171 accepted lattice points at $\alpha = 0.05$, but the cached marginal inv_phi CI from 5b is non-empty at $[-1.23, -0.01]$.
The discrepancy is almost certainly the joint $K$ dof vs profile $K - 1$ dof choice, not a substantive J-rejection.

**Next concrete action.**
Evaluate the constrained-$J$ Wald in `build_joint_ci_grid` at the GMM point estimate ($\phi = -0.524$, $\beta = 0.067$ from `IDN_e1_scalars.csv`) and compare to $\chi^2_{27, 0.95} = 40.11$.
If the Wald is small (say below 10), the construction is right and the empty-CI is honest at the high $K$ dof.
If the Wald is large (above 40) at the GMM point, the moment formula or Jacobian has a bug.

**Files to read first.**

- [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py): `build_joint_ci_grid` is the function to test.
- [explorations/2026-05-18_e1_v3_joint_ci_smoke.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_e1_v3_joint_ci_smoke.py): the existing smoke driver, easy to fork for the point-estimate Wald check.
- [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py): `grid_lca_inversion` and `grid_md_inversion` are the existing $K - 1$ dof inversions to cross-check against.
- [RP7/output/counterfactual_inputs/IDN_e1_scalars.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_inputs/IDN_e1_scalars.csv): GMM point estimate for IDN.

**Cached state to know.**

- Junction `RP7/data` now points at the canonical `C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/data` (was a symlink to ReplicationPackage5, an older snapshot).
  Data hashes verified to match the canonical copy.
- Sters in `RP7/output/` for `cuu_ca`: IDN (parent + `_n, _a, _d, _g`), TZA (same), CHN pooled (same; J rejects, CIs are empty), CHN hukou-split for rf, uf, ro, uo (same five suffixes each).
  Inversion CIs are attached to the pooled cuu cells (IDN, TZA, CHN_cuu_ca via `5b_inversion.do`).
  Inversion CIs are **not** yet attached to the CHN hukou-split sters; 5b is pooled-only.
- Commits on this branch since the 2026-05-18 plan landed: `c69dde0` (V1 audit), `619d16e` (V2), `f978d3a` (V3 smoke + paper sentence).
- Uncommitted: `RP7/output/counterfactual_inputs_rp5/` (V2 CSV snapshot from the pre-swap data, kept as a comparison artifact).
  Not worth committing unless we end up doing a pre-vs-post-swap diff in the V3 memo.
- 5b second run (post-swap) results captured at end of session: IDN cuu_ca inv_phi $= -0.60$, CI95 $= [-1.23, -0.01]$; TZA cuu_ca similar; CHN cuu_ca pooled CI empty.
  These are the canonical-data inversion outputs.

**After the V3 dof diagnosis.**

1. Implement the plan's P3 fallback for TZA: when the joint CI crosses $\phi = -1$, restrict the aggregate to $d_N + $ switchers (drop the $d_T$ piece because $\Delta_{d_T}$ is unbounded across the Möbius pole).
   TZA's V3 smoke showed the issue: 19 accepted points all in $\phi \in [-1.225, -1.050]$, $W_{\text{obs}} - W_{\text{zero}}$ inflating to $+285\%$ from the pole.
2. Fix `project_image_intervals` binning at low $N$ (one-bin-per-point artifact at the 19-finite-values level).
3. Build the CHN hukou-split inversion-attach driver (5b is pooled-only; hukou cells need an adapted pipeline).
4. Bib entries for Kennan and Walker (2011), Tombe and Zhu (2019), Fan (2019) — the paper draft has inline cites with TODO comments.

---

## Goals

The user asked to commit the prior session's plan / methods-review / Bucket-B / A6 work, then start implementation of the counterfactual experiments per the agreed plan sequencing.
Implementation goals were the audit script (V1 gate), the point-estimate aggregate (V2 milestone), and the joint inversion CI machinery (V3).
Mid-session, the user added: cherry-pick CHN sters from main if needed, add a paper-side sentence about the lumped-unbalanced cell, and give a verbal summary of V2 before continuing.

## What got built or changed

**V1 audit.**

- [RP7/scripts/_smoke_counterfactual_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_counterfactual_inputs.do): walks the three countries under the headline col 5 spec (`cuu_ca`); inventories the five sters per cell, dumps $\hat\beta$, $\hat\phi$, $J$-stat, $J$-pval, the four inversion-CI prefixes (`inv_phi`, `inv_dN`, `inv_dT`, `inv_davg`), and trajectory descriptives from the data ($\pi_d$, $\bar D_d$, $\hat\mu_d$, $\sigma_\theta$ as the between-group lower bound).
  Halts on missing inputs.
- One-shot diagnostic: [RP7/scripts/_probe_d_ster.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_probe_d_ster.do) for inspecting the `_d` ster's `e(b)` to confirm the `Delta_2 .. Delta_K` naming.

**V2 pipeline.**

- [RP7/scripts/_export_e1_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs.do): per-country exporter that reads the parent + `_d` sters plus the unbalanced data, writes four CSVs per country (trajectory shares plus `dbar_d`; `mu_d`; switcher `Delta_d` from the `_d` ster; country-level scalars).
- [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py): helper module with `evaluate_aggregate(delta_d, pi_d, dbar_d)`, `log_to_pct`, and (added later for V3) `build_joint_ci_grid`, `_flood_fill_2d`, `project_image_intervals`, `lca_delta_dN`, `lca_delta_dT`.
- [explorations/2026-05-18_e1_v2_check.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_e1_v2_check.py): V2 driver that reads the CSVs, builds the trajectory-level `Delta_d` vector (with $d_N$ from inversion, $d_T$ from inversion, balanced switchers from `_d` ster, lumped switcher from `xb:unbalanced_choice` on the parent ster), evaluates the aggregate, and compares to the 2026-05-13 memo BoE.
- V2 memo: [docs/notes/2026-05-18_e1_v2_check.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-18_e1_v2_check.md).
  Headline numbers: TZA $W_{\text{obs}} - W_{\text{zero}} = -0.096$ log pts ($-9.2\%$), TZA misallocation gap $+38.4\%$.
  IDN $W_{\text{obs}} - W_{\text{zero}} = +0.046$ log pts ($+4.7\%$), IDN gap $+6.4\%$.
  IDN flips sign vs the BoE because the lumped-switcher cell holds 89% of the sample with $\bar D \approx 0.48$ and $\Delta \approx +0.12$.

**Data junction swap (uncommitted; setup change).**

- Removed `RP7/data` symlink to ReplicationPackage5 (older).
- Re-created `RP7/data` as a Windows junction to `C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/data` via PowerShell `cmd /c mklink /J`.
- Copied IDN, TZA, CHN pooled, and CHN hukou-split cuu sters from `grc-pipeline-refactor/RP7/output/` into `lca-inversion/RP7/output/`.
  30 sters total for the headline col 5 cells, plus the rest of the cuu covariate set for IDN and TZA.
- [RP7/scripts/_run_5b_for_attach.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_run_5b_for_attach.do): thin wrapper that sets `$dir` and invokes `5b_inversion.do` against the new sters.
  Ran it twice; second run included the pooled CHN cuu_ca sters after I noticed I had only copied hukou-split CHN the first time.

**V3 joint-CI machinery.**

- `counterfactuals.py` additions: `build_joint_ci_grid(fit, switchers_kept, base, phi_grid, beta_grid, type_one)`, the 2D constrained-$J$ inversion that fixes both $\phi$ and $\beta$ at each lattice point.
  `_flood_fill_2d` for connected-component decomposition on the accept mask.
  `project_image_intervals` for 1D image projection of the aggregate's value at accepted lattice points.
  `lca_delta_dN(phi, beta, mu_dN, mu_base) = beta + phi * (mu_dN - mu_base)`.
  `lca_delta_dT(phi, beta, alpha_dT_obs, mu_base) = (beta + phi * (alpha_dT_obs - mu_base)) / (1 + phi)`, the Möbius transformation with `+/- inf` handling near `phi = -1`.
- [explorations/2026-05-18_e1_v3_joint_ci_smoke.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_e1_v3_joint_ci_smoke.py): the V3 smoke driver that fits the auxiliary OLS in Python, builds the joint CI grid, evaluates the aggregate at each accepted point, and reports the projection-CI image.

**Paper draft.**

- [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex): added one sentence flagging the four-way decomposition ($d_N$, balanced switchers, lumped switcher, $d_T$) since V2 showed the lumped cell holds 89% of IDN and contributes non-trivially to both the observed-migration value and the misallocation gap.

## Decisions, with the why

**Decision: re-junction `RP7/data` from ReplicationPackage5 to the canonical `grc-pipeline-refactor/RP7/data`.**
Why: the project memory specifies `grc-pipeline-refactor/RP7/data` as the canonical local copy of processed `.dta` files (dated 2026-04-25).
The lca-inversion worktree's symlink pointed at older data, the sters had drifted (May 8 lca-inversion sters vs May 12 grc-pipeline-refactor sters, different MD5s), and V2 numbers were internally consistent with the OLD data only.
For V3 to be defensible against canonical numbers we needed the data and sters in sync.

**Decision: include the lumped-unbalanced-switcher cell as its own row in the aggregate.**
Why: V2 surfaced that 89% of IDN's sample sits there with $\bar D \approx 0.48$ and $\Delta \approx +0.12$.
Skipping it (as the 2026-05-13 memo BoE did) gave the wrong sign for $W_{\text{obs}} - W_{\text{zero}}$ in IDN.
The plan's T1 decomposition currently shows $d_N$ / switchers / $d_T$ only; this needs a fourth row.
Already flagged in the paper draft.

**Decision: use trajectory-conditional $\Delta_d$ from the `_d` ster (unrestricted GRC) for switchers; LCA-derived $\Delta_{d_N}$ and $\Delta_{d_T}$ from the parent ster's inversion scalars.**
Why: matches the plan's "non-parametric switcher $\Delta_d$ + LCA-extrapolated $d_N$ + inversion-derived $d_T$" structure.
The `_d` ster's `e(b)` carries `Delta_2 .. Delta_K` as free unrestricted parameters; the parent ster's `e(inv_dN_at_waldmin)` and `e(inv_dT_at_waldmin)` carry the inversion point estimates.

**Decision: use $K$ dof (joint) for `build_joint_ci_grid`, including the base moment.**
Why: the plan calls for "constrained-$J$ at fixed $(\phi, \beta)$" with the moment vector evaluated for every switcher in `switchers_kept` (including the base, where $\alpha_s - \alpha_{\text{base}} = 0$).
The joint hypothesis tests both the cross-switcher restrictions and the level of $\beta$.
Using $K - 1$ dof would only test the cross-switcher piece (matching `grid_lca_inversion`, which pins $\beta$ to the base equation), which is the marginal $\phi$ CI not the joint $(\phi, \beta)$ region.
NOTE: this produced an empty CI for IDN; the next session needs to verify the construction at the GMM point estimate.

**Decision: do not rename `alpha_dT_obs` despite the Verdier-Vella naming clash.**
Why: the user explicitly chose option 2 (leave the name, add a comment).
The `alpha` here is shorthand for the observed urban-period mean log consumption for always-urban workers, following the Möbius singularity memo's notation ($\alpha_{d_T}^{\text{obs}}$).
Renaming would diverge from the memo and introduce its own confusion.

**Decision: keep the V2 CSVs under `counterfactual_inputs_rp5/` as a snapshot.**
Why: V2 results were computed against the older RP5 data.
The numbers in the V2 memo are useful for narrative purposes but should be replaced once a re-export against the canonical data is run.
The snapshot lets us diff later if needed.

**Decision: hold off on the P3 Möbius-pole fallback in V3.**
Why: the smoke surfaced the issue cleanly (TZA's CI crosses $\phi = -1$ from below; the aggregate inflates to nonsense values from the singularity).
Implementing the fallback was deferred so we could land the V3 plumbing cleanly first and inspect the IDN empty-CI issue, which is the load-bearing question.

## Approaches rejected, with the reason

**Tried: reading sters directly from Python via pystata.**
Rejected because: the `pystata` namespace bridge has known gotchas (per `rules/stata-conventions.md`, two gotchas about `python:` inside `program define` and the `__name__ == "builtins"` scope issue).
Switched to a Stata CSV exporter that writes to `RP7/output/counterfactual_inputs/`, then a Python driver that reads the CSVs.
Simpler handoff, no bridge fragility.

**Tried: `cmd //c mklink /J <path>` via Git Bash.**
Rejected because: the double-slash escaping confused either Git Bash's MSYS path-mangling or Windows' command parser, returning "Invalid switch."
Used PowerShell tool with bare `cmd /c mklink /J` instead.
That worked first try.

**Tried: running V2 against the original (pre-swap) data.**
Rejected because: V2 numbers were against the May 8 lca-inversion sters which were fit against RP5 data (older).
Internally consistent but not the canonical state.
Re-junctioned first, then re-fit (still pending re-export to update V2 numbers against canonical data).

**Tried: `capture matrix list e(b)` in the V1 audit's main-ster inspection.**
Rejected because: `cap` swallowed the matrix-list output silently.
Switched to `noisily matrix list e(b)`, which surfaces the parameter vector.

**Tried: standalone `else { ... }` block on its own line in the Stata extrapolation diagnostic.**
Rejected because: Stata's parser requires `} else {` on a single line; `}` on one line and `else {` on the next produced "matching close brace not found."
Switched to a flat numeric reporting style (`di "d_N inside switcher range (1=yes 0=no): " in_hull`) that avoids the if/else block entirely.

**Tried: `cap matrix list e(b)` with the `cap` prefix in the audit.**
Same issue as above.
Dropped `cap` for `noisily`.

## Open items and blockers

1. **V3 IDN empty-CI** is the headline open thread.
   Need to diagnose whether it is a dof / moment-construction issue (likely, given that the marginal $\phi$ CI from 5b is non-empty at $[-1.23, -0.01]$) or a substantive J-rejection.
   Concrete next step in the "If you resume" section.

2. **TZA P3 fallback** for the Möbius pole crossing.
   The smoke's TZA result (19 lattice points, all in $\phi \in [-1.225, -1.050]$, aggregate inflated to $+285\%$) needs the plan's "restrict to $d_N$ + switchers" reporting.

3. **`project_image_intervals` binning at small $N$.**
   With 19 finite values and 401 bins it reports 18 islands (one bin per value), which is an artifact not a real disconnection.
   Needs adaptive binning that uses the count-of-finite-values to size the bin lattice.

4. **CHN hukou-split inversion CIs not yet attached.**
   `5b_inversion.do` is pooled-only.
   The four hukou cells (rf, uf, ro, uo) need an adapted attach pipeline.

5. **Bib entries for Kennan-Walker (2011), Tombe-Zhu (2019), Fan (2019).**
   Paper draft has inline cites with TODO comments; the entries need to be added to `CKT.bib` and the cites converted to `\cite{}`.

6. **V2 re-export against canonical data.**
   The V2 numbers in the memo are against pre-swap data.
   Re-running `_export_e1_inputs.do` against the new sters + canonical data should give updated numbers; the memo should be updated when V3 is also re-run for the same reason.

## Picking back up

Read the `## If you resume` block at the top of this file.
The first concrete action is the Wald-at-GMM-point check for the V3 IDN empty-CI.
After that, P3 fallback, then `project_image_intervals` fix, then CHN hukou inversion, then re-export V2 numbers against canonical data, then bib entries.
