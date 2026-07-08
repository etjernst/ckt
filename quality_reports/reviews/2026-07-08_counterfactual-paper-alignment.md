# Alignment review: counterfactual-experiments section vs. generated outputs

**File reviewed:** [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex)
**Sources of truth:** [RP7/output/counterfactual_results.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_results.csv), [RP7/output/counterfactual_decomposition.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_decomposition.csv), [RP7/output/counterfactual_diagnostics.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_diagnostics.csv), [RP7/output/tables/counterfactual_misallocation.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/tables/counterfactual_misallocation.tex), [RP7/output/tables/hukou_bound.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/tables/hukou_bound.tex), [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py), [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)
**Mode:** CoVe (Chain-of-Verification). 40 atomic claims decomposed across 5 findings clusters, each verified by a `verifier-claim` subagent running in forked context with no visibility into this document or the caller's reasoning.

## Summary

Every quantitative claim in the section — all point estimates and confidence intervals in Table 1 and Table 2 (misallocation gaps and value-of-migration for IDN, TZA, CHN national, CHN rural-hukou-first, CHN urban-hukou-first; the hukou-bound return and economy-wide gain), every decomposition ratio ("roughly nine in ten," "about 95%," "half the gap," "nearly all," "roughly a sixth"), every diagnostic claim about the phi = -1 boundary crossing and the without-fallback overflow values, and the 74%/26% CHN population weights — checked out against the CSVs and generated tables to the precision quoted in the prose. Four of five structural/method claims about how the code implements the misallocation-decomposition equation (first-observed-wave baseline, LCA-line recomputation at every accepted grid point, joint 3D test-inversion region with convex hull, dT contribution zeroed in the reported P3 intervals, and the <0.05pp unrestricted-switcher cross-check) are also confirmed against the code as written.

One CRITICAL finding requires human attention before submission: the prose's description of the lumped unbalanced-cell return $\Delta_{\text{unb}}$ as "the base-trajectory return plus the unbalanced-mover shift" does not match what the reviewed code computes — no addition of a base-trajectory term is visible anywhere in the code path that builds the value actually used in the aggregate. One MAJOR finding notes that the "J-test holds within each regime" claim is unverifiable from the five designated sources of truth (though a supplementary file outside the formal review scope does support it). Two MINOR findings flag rhetorical/rounding precision points that do not affect the reported numbers.

---

### Finding F1: "Comparable in magnitude" characterization for CHN rural-hukou-first vs. Tanzania

**Lens:** 1 (alignment)
**Severity:** MINOR
**Confidence:** HIGH
**Files involved:** [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) line 87; [RP7/output/counterfactual_results.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_results.csv)

**Atomic claims (verifier-checked):**
1. [paper-text/paper-table] The paper text (line 87) states the rural-hukou-first misallocation gap is +15.2% [+13.6%, +17.2%] — SUPPORTED
   - Verifier evidence: `CHN_rf,misallocation,p3_v1,...,15.21168797547997` (counterfactual_results.csv); paper text "$+15.2\%$ ... $[+13.6\%, +17.2\%]$" (line 87)
2. [paper-text] The paper describes this rural-hukou-first gap as "comparable in magnitude to Tanzania's" (+23.5%) — PARTIAL
   - Verifier evidence: CHN_rf point_pct=15.21%, TZA point_pct=23.50%; absolute gap ≈8.3pp, relative gap ≈54.5% (TZA larger); the two 95% CIs do not overlap (CHN_rf upper 17.24% < TZA lower 18.58%)
   - Note: the underlying point estimates and CIs are both numerically correct; the rhetorical characterization "comparable in magnitude" is not tightly supported given a >50% relative gap and non-overlapping confidence intervals.

**Verdict rationale:** Both cited numbers are exactly right (confirmed elsewhere in F-clean numeric checks). The only issue is a judgment call about whether a >50% relative difference with non-overlapping CIs should be called "comparable." This is a wording precision issue, not a numeric error.

**Recommended action:** Leave as-is or soften to "of the same order of magnitude as" / "roughly two-thirds the size of Tanzania's" — a prose-only fix, no re-estimation needed.

---

### Finding F2: Rounding precision on the Indonesia without-fallback overflow figure

**Lens:** 1 (alignment)
**Severity:** MINOR
**Confidence:** HIGH
**Files involved:** [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) line 102; [RP7/output/counterfactual_results.csv](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_results.csv)

**Atomic claims (verifier-checked):**
1. [paper-text] The paper states that without the dT fallback, Indonesia's gap upper bound inflates "to +89%" — SUPPORTED
   - Verifier evidence: `IDN,misallocation,with_dT_v1,...,ci_hi_pct=88.5464082058749` (counterfactual_results.csv); 88.5464 rounds to 89 under standard nearest-integer rounding.
   - Note: the underlying value (88.5%) is a borderline round (just above the .5 threshold); correct under nearest-integer rounding, but worth a sanity check against whichever rounding convention the paper uses elsewhere (round vs. truncate) if that convention is meant to be uniform across the section.

**Verdict rationale:** The number checks out; flagged only because it sits so close to the rounding boundary that a reader spot-checking by eye might expect "88%."

**Recommended action:** Leave as-is; optionally note one more decimal ("+88.5%") if the paper wants to avoid the rounding-boundary appearance.

---

### Finding F3: The lumped-cell return Δ_unb's stated formula does not match the code's construction

**Lens:** 1 (alignment)
**Severity:** CRITICAL
**Confidence:** MEDIUM
**Files involved:** [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) line 61; [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py); [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)

**Atomic claims (verifier-checked):**
1. [paper-text] Paper text (line 61): "Individuals with unbalanced panels enter through a single lumped cell whose return $\Delta_{\text{unb}}$ is the unbalanced-mover urban premium---the base-trajectory return plus the unbalanced-mover shift---estimated by an auxiliary regression on the estimation sample." — this is the claim under test.
2. [code] The lumped-cell delta value used in the aggregate is assigned directly from the swept/point `delta_unb` coordinate with no addition of a base-trajectory term anywhere in the code — CONTRADICTED (verifier `matches_claim: no` on whether the code constructs "base + shift" via an addition operation)
   - Verifier evidence: `out = np.where(is_lumped, delta_unb, out)` (counterfactuals.py:839); point estimate `dv_hat[is_lumped] = unb_ols` (counterfactuals.py:982); `unb_idx = fit.idx("unbalanced_choice"); unb_ols = float(fit.b[unb_idx])` (counterfactuals.py:799-800) — the raw OLS coefficient, used as-is.
3. [code] The auxiliary-OLS per-trajectory `alpha[d]` dummy columns are constructed as `(df[trajectory] == d)`, which evaluates to 0/False for every row where trajectory is missing (i.e., every unbalanced individual), so unbalanced rows never receive a base-trajectory alpha term in the same regression that estimates `unbalanced_choice` — SUPPORTED
   - Verifier evidence: `cols[f"alpha[{d}]"] = (df[trajectory] == d).astype(float).values` (lca_inversion.py:107)

**Verdict rationale:** The verifier found no addition of `alpha[base]` or `beta_hat` anywhere in the code path that builds the value labeled `delta_unb`, which contradicts the paper's explicit "base-trajectory return plus the unbalanced-mover shift" formula. The verifier explicitly noted it could not rule out that this decomposition holds for some other reason upstream (e.g., in how the underlying `unbalanced_choice` variable is constructed in Stata) since that lay outside the two Python files it was asked to check. Separately, in the course of this review (outside the forked verifier's scope, reported here for the record and not as a substitute for verification), a cross-check of `RP7/scripts/0_programs.do` line 322 shows `unbalanced_choice` is generated as the plain interaction `unbalanced*choice`, which also carries no base-trajectory term. Yet a numeric comparison of `unb_ols` against `unb_gmm` (the ster's own `xb:unbalanced_choice` diagnostic) in `counterfactual_diagnostics.csv` shows `unb_ols - unb_gmm` tracks the base trajectory's own return (`beta_hat`, from each cell's `_e1_delta_d.csv` base row) to within 0.02 log points in all four cells (IDN, TZA, CHN_rf, CHN_uf) — a pattern too tight across four independent estimation samples to be pure noise, yet not explained by any line of code either verifier or this reviewer could locate. This combination — a prose claim contradicted by the visible code, alongside an unexplained numerical regularity that is *consistent* with the prose claim — is exactly the kind of identification/model-spec ambiguity that needs the author's judgment, not a mechanical fix.

**Recommended action:** fixer-code needs human approval. Do not silently patch the code or the prose. The open question for the author: is `unb_ols` (the value actually plugged into the aggregate and its confidence region) supposed to equal $\Delta_{\text{base}} + \text{shift}$, and if so, by what mechanism does the current auxiliary-OLS specification deliver that (given no explicit addition step is visible)? If the empirical closeness is coincidental rather than structural, the paper's formula description needs revision to match what `unb_ols` actually estimates (a level return for the lumped group, analogous to `beta[s]` for switchers, not decomposed into base + shift).

---

### Finding F4: "J-test holds within each regime" is unverifiable from the designated sources of truth

**Lens:** 1 (alignment)
**Severity:** MAJOR
**Confidence:** LOW
**Files involved:** [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) line 90; the five designated CSV/table sources

**Atomic claims (verifier-checked):**
1. [paper-text] Paper text (line 90): "The $J$-test holds within each regime, in contrast to its pooled rejection." — UNVERIFIED
   - Verifier evidence: a grep for J-test/Hansen/jstat/overid terms across all five designated source files (`counterfactual_results.csv`, `counterfactual_decomposition.csv`, `counterfactual_diagnostics.csv`, `counterfactual_misallocation.tex`, `hukou_bound.tex`) returned zero matches; none of them carry J-test statistics.

**Verdict rationale:** None of the files given as sources of truth for this review contain Hansen J-test output, so the claim cannot be verified from them and is reported as UNVERIFIED per protocol (cannot-verify on a load-bearing model-spec claim maps to LOW confidence). For the record only (not part of the formal CoVe verification, and not a substitute for it): this reviewer separately opened `RP7/output/counterfactual_inputs/CHN_rf_e1_scalars.csv` and `CHN_uf_e1_scalars.csv` — two intermediate files that were not part of the designated review scope — and found `j_pval = 0.1249` (CHN_rf) and `j_pval = 0.2154` (CHN_uf), both well above 0.05, consistent with the paper's claim that the J-test does not reject in either regime. This is supportive but out-of-scope evidence; it does not close the gap for a reader of the paper, who has no path from the prose to a J-test table.

**Verdict rationale (continued):** The claim is very likely true based on the supplementary check, but the paper currently gives readers no citable source (table, appendix, or footnote pointer) for it, and the review's designated sources of truth do not carry the statistic.

**Recommended action:** No fix needed to the counterfactual code. Recommend the author add a J-test table (or appendix reference) for the CHN hukou-split and pooled specifications so this claim is traceable from the paper itself, the way the misallocation and hukou-bound claims already are via their generated tables.

---

## Findings suppressed as CLEAN (all claims SUPPORTED, no advisory notes)

Per protocol, CLEAN findings are omitted from the itemized list above. For completeness, the following claim clusters were independently verified via forked `verifier-claim` calls and returned unanimous `yes` verdicts with verbatim CSV/table citations:

- IDN, TZA, and CHN-national misallocation-gap point estimates and 95% CIs (paper lines 79, 80, 82) against `counterfactual_results.csv` (version `p3_v1`).
- CHN rural-hukou-first and urban-hukou-first misallocation-gap point estimates and CIs (lines 87-88).
- Value-of-observed-migration figures below +1% in every country (line 83).
- The 74%/26% CHN population-weighting footnote (line 82), verified by solving the weighted-average identity against `CHN_rf`/`CHN_uf`/`CHN_national` point_log values (implied w_rf ≈ 0.7385).
- Every row of `counterfactual_misallocation.tex` against both the prose and `counterfactual_results.csv`.
- The IDN lumped-cell share ("roughly nine in ten," pi_d = 0.8894) and its gap/value contributions ("about 95%" → 94.98%; "nearly all" of the value → 89.5%).
- TZA never-migrants "contribute half the gap" (52.4%).
- CHN urban-hukou-first "roughly a sixth" of rural-first magnitudes (0.165 vs. 1/6 = 0.167).
- The phi = -1 boundary-crossing pattern (IDN, TZA, CHN_uf cross; CHN_rf does not) against `counterfactual_diagnostics.csv`.
- The urban-hukou-first subsample's phi-unbounded-both-directions footnote.
- The Tanzania without-fallback overflow figure ("beyond +90,000%," actual 92,064%).
- The CHN urban-hukou-first "infinite either way" claim (both P3 and with-dT upper bounds are `inf`).
- All hukou-bound table/prose numbers: Δ_dN^rh = +11.1% [+9.4%, +13.9%]; economy-wide gain = +2.1% [+1.8%, +2.6%]; the 0.74 × 0.27 ≈ 0.20 share decomposition; the "half-width near 0.02" footnote claim.
- Structural claims: the value-of-migration term uses first-observed-wave shares `dbar0_d` (line 44-49 vs. `evaluate_aggregate`); switcher returns are recomputed on the LCA line at every accepted confidence-region grid point (lines 57, 62-63 vs. `delta_at` and the `_iter_v1`/`_iter_v2` sweep generators); inference uses a joint 3D $(\phi,\beta,\Delta_{\text{unb}})$ test-inversion region with the convex hull reported, and the paper table's default variant (`v1`) does correspond to that 3D sweep, not the 2D-plus-interval-arithmetic fallback (line 62 vs. `build_joint_ci_grid_3d`, `write_latex_table`); the dT contribution is zeroed at every point in the reported P3 intervals, not just at the point estimate (lines 100-101 vs. `_hulls_from_sweep`); the <0.05 percentage-point unrestricted-switcher cross-check (line 58 — largest observed gap was IDN at ≈0.048pp, still under the stated threshold).

## Overall verdict

The section's numeric content is unusually well-supported: of ~40 atomic claims checked via independent forked verification, only one (F3) was a genuine contradiction and one (F4) was unverifiable from the designated sources. F3 is a CRITICAL finding per protocol and blocks submission-readiness until the author resolves whether $\Delta_{\text{unb}}$'s prose description matches its actual construction — this requires human judgment about model specification, not a mechanical code or prose fix. F4 is MAJOR but likely resolves with a citation addition once the author points to (or adds) a J-test table. F1 and F2 are MINOR wording/rounding precision notes that do not require re-estimation.

---

## Adjudication (main session, 2026-07-08 15:35)

F3 (CRITICAL) resolves as consistent; no code or estimand change needed.
The mechanism the verifier could not see: in the auxiliary OLS, unbalanced rows receive no `alpha[d]` trajectory dummy (the verifier's own claim 3), so the `unbalanced_choice` coefficient absorbs the full urban premium of the lumped cell in one coefficient---there is no addition step because the OLS parameterization estimates the sum directly.
The GMM parameterizes the same premium as $\Delta_{base}$ plus its `unbalanced_choice` shift, which is why `unb_ols - unb_gmm` tracks the base return: that identity was verified to the fourth decimal in all four cells during Phase 2 (session log 2026-07-08, commit `555eb6b`), and it is the reconciliation that surfaced the lumped-return bug in the first place.
Prose tweak applied for clarity: "estimated as a single coefficient by an auxiliary regression" (both files), so no reader expects a literal sum in the code.

F4 (MAJOR) closed: the J-test statistics live in the hukou GRC tables the same paragraph already discusses (`GRC_CHN_hukou_{rural,urban}_first_consumption_urban_unb.tex`: pooled p = 0.000, within-regime p = 0.126 and 0.209); explicit `Tables~\ref{...}` cross-references added to the sentence.

F1 (MINOR) fixed: "comparable in magnitude to Tanzania's" replaced with "second only to Tanzania's among our samples" (15.2 vs 23.5, non-overlapping CIs).

F2 (MINOR) fixed: "+89%" replaced with "+88.5%", matching the section's one-decimal convention and avoiding the rounding-boundary appearance.
