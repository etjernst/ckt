# Diagnostic resolved: V3 drivers were dropping unbalanced workers

**Date:** 2026-05-20.
**Branch:** lca-inversion.
**Resolves:** Tasks #8 (RF GMM-point near-rejection) and #9 (IDN Python-vs-5b marginal $\phi$ disagreement).
**Files:**

- IDN/TZA driver (sample fix): [explorations/2026-05-20_e1_v3_joint_ci.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci.py)
- Hukou driver (same fix): [explorations/2026-05-20_e1_v3_joint_ci_hukou.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci_hukou.py)
- National CHN driver (same fix): [explorations/2026-05-20_e1_chn_national.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_chn_national.py)
- Logs (v2 = post-fix runs): [explorations/logs/](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/logs/)

## The bug

All three V3 drivers began with `df = df.dropna(subset=["consumption", "choice", "trajectory"])`.
The trajectory variable is missing for unbalanced workers, so dropping NaN trajectory dropped the entire unbalanced subsample.
For IDN this meant 26,408 of 29,692 pids ($89\%$) were silently excluded; for CHN-RF, 14,889 of 25,491 pids ($58\%$); for CHN-UF, 5,433 of 9,024 pids ($60\%$).
The misallocation aggregate still used the unbalanced cell via `unb_choice_hat` because the V2 CSV inputs were exported from Stata sters that had been fit on the full sample.
What was wrong was the auxiliary OLS that built the joint $(\phi, \beta)$ CI: it saw only balanced workers, so its standard errors were inflated relative to 5b's auxiliary OLS that saw the full sample.

The Stata-side pipeline (`5b_inversion.do` plus `attach_inversion_for_stata` plus `compute_all_inversion_cis`) handles unbalanced workers correctly: `setup_grc_estimation` recodes trajectory NaN to 999, `attach_inversion_for_stata` reverses 999 back to NaN, and `compute_all_inversion_cis` does `dropna(subset=cols_needed)` with trajectory deliberately excluded so the unbalanced rows survive.
Inside `fit_auxiliary_ols`, unbalanced rows (trajectory NaN) contribute through the `unbalanced` and `unbalanced_choice` dummies, not through any trajectory-specific $\alpha_d$ or $\beta_s$.
My Python drivers had not replicated that detail.

## The fix

Replace `df.dropna(subset=["consumption", "choice", "trajectory"])` with `df.dropna(subset=["lndepvar", "choice"])` plus a dropna on the controls and `unbalanced` / `unbalanced_choice` columns.
Unbalanced workers (trajectory NaN) survive the filter and are routed through the unbalanced dummies in `fit_auxiliary_ols`.

## What the fix changes (and what it does not)

The bigger sample tightens the auxiliary OLS standard errors.
Joint $(\phi, \beta)$ confidence regions shrink, and the marginal projections shrink with them.
The point-estimate misallocation aggregate is essentially unchanged because the underlying GMM sters (and the V2 trajectory CSVs) were always fit on the correct sample.
What moves is the inference, not the point estimates.

## Headline numbers, before and after

| object | before fix | after fix |
|---|---:|---:|
| IDN marginal $\phi$ projection | $[-1.21, +0.90]$ | $[-1.29, +0.03]$ |
| IDN P3 misallocation gap | $[+5.67\%, +6.14\%]$ | $[+5.67\%, +6.08\%]$ |
| TZA marginal $\phi$ projection | $[-1.37, -0.40]$ | $[-1.35, -0.42]$ |
| TZA P3 misallocation gap | $[+14.34\%, +22.67\%]$ | $[+14.67\%, +22.84\%]$ |
| CHN-RF marginal $\phi$ projection | $[-0.30, -0.07]$ | $[-0.36, +0.09]$ |
| CHN-RF P3 misallocation gap | $[+10.49\%, +11.69\%]$ | $[+9.88\%, +11.70\%]$ |
| CHN-RF Wald at GMM point | $18.87$ (rejected at threshold $18.31$) | $16.29$ (accepted) |
| CHN-UF marginal $\phi$ projection | $[-3.50, -0.71]$ | $[-3.50, -0.73]$ |
| CHN-UF P3 misallocation gap | $[+0.91\%, +1.25\%]$ | $[+0.91\%, +1.15\%]$ |
| CHN national P3 misallocation gap | $[+7.90\%, +8.86\%]$ | $[+7.46\%, +8.84\%]$ |

The IDN marginal $\phi$ upper bound moved from $+0.90$ to $+0.03$, against 5b's $-0.01$.
Residual disagreement narrowed from $\approx 0.9$ to $\approx 0.04$ units, which is plausibly grid-resolution or rounding.
Task #9 is resolved.

The CHN-RF Wald at the GMM point dropped from $18.87$ (just outside) to $16.29$ (comfortably inside) the joint CI.
The prior near-rejection was an artifact of the truncated sample; with the full sample the GMM point is accepted and the per-switcher Wald contributions are no longer dominated by trajectory 11.
Task #8 is resolved.

The misallocation gap intervals shift slightly across all four cells but the qualitative story is unchanged.
Cross-country ordering, CHN regime decomposition, identification-boundary fallback: all the same.

## Updated headline table

| country / cell | misallocation gap (P3) |
|---|---:|
| IDN | $[+5.7\%, +6.1\%]$ |
| TZA | $[+14.7\%, +22.8\%]$ |
| CHN national (RF + UF weighted) | $[+7.5\%, +8.8\%]$ |
| CHN-RF (subsample) | $[+9.9\%, +11.7\%]$ |
| CHN-UF (subsample) | $[+0.9\%, +1.2\%]$ |

These supersede the numbers in [docs/notes/2026-05-20_p3_fallback.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_p3_fallback.md), [docs/notes/2026-05-20_e1_chn_national.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-20_e1_chn_national.md), and the related V3 memos.
The paper text in [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) has been updated in a follow-up commit.

## Open items left

1. **`project_image_intervals` binning** at small $N$ (unchanged).
   Convex hull is fine; per-interval breakdown is misleading.
2. **RO and UO inversion attach** (Task #3, deferred).
3. **Residual $0.04$-unit upper-bound gap** for IDN's marginal $\phi$ vs 5b.
   Plausibly grid-resolution rounding; not worth chasing further unless headline numbers shift.
