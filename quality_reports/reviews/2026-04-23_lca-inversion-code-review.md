# LCA inversion code review

**Target:** `explorations/python-grc/lca_inversion.py`
**Date:** 2026-04-23
**Reviewer:** econometrics-critic agent (referee lens)
**Author response and validation update:** added below the critic report.

---

## Critic findings (summary table)

| # | Severity | Confidence | Lens | Issue |
|---|----------|------------|------|-------|
| 1 | MAJOR | HIGH | Identification | Auxiliary OLS does NOT enforce the GMM's `(kappa, mu_base)` cross-restriction on the always group; alpha_s estimates may be biased relative to the GMM's mu_s. **Author note: refuted by T=2 validation, see below.** |
| 2 | MAJOR | HIGH | Inference | `statsmodels` cluster correction differs from Stata's `vce(cluster pid)` --- misses `(N-1)/(N-K)` factor. |
| 3 | MAJOR | MEDIUM | Identification | Wald encoding is correct but uses the auxiliary-OLS coefficients in the role of the GMM's $\mu_s$. |
| 4 | MAJOR | HIGH | Identification | `pinv(V_R, rcond=1e-10)` silently changes the chi-square dof: when V_R loses rank, the test still uses `df = J_R` and is undersized. |
| 5 | MAJOR | MEDIUM | Robustness | Sparse-switcher pre-drop counts unique pids contributing a treated obs; the symmetric criterion (a switcher with too few RURAL person-years) is not enforced. |
| 6 | MINOR | HIGH | Inference | `unbalanced_choice` indicator is built from the column passed in rather than constructed as `unbalanced * choice` --- silent mismatch risk if the upstream column is stale. |
| 7 | MINOR | MEDIUM | Robustness | The "smallest = never, largest = always" rule in `drop_sparse_switchers` is a convention assumption; if upstream encoding ever changes, the function will silently mislabel. |
| 8 | MINOR | LOW | Robustness | Grid-boundary / island detection deliberately deferred. Acknowledged in plan. |
| 9 | INFORMATIONAL | HIGH | Identification | Smoke-test result (Wald min = 123 vs J = 86) plausibly explained by issues #1, #2, #4 jointly. **Author note: validation suggests #1 is not the cause.** |

## Critic's full analysis (verbatim, abridged)

The critic's full prose argument is preserved in the session log
`quality_reports/session_logs/2026-04-23_afternoon-rank-deficient-S.md`
(linked from this file). Key quotes:

On finding 1: "OLS estimates `alpha[d]` as the unconditional pooled mean of $y$ for trajectory $d$, NOT specifically the rural-state mean. For switchers this includes both rural and urban person-years, so `alpha[s]` is a weighted average of $\mu_s$ and $\mu_s + \Delta_s$, with weights equal to the within-switcher rural/urban share. Concretely, $\mathbb{E}[\hat\alpha_s] = \mu_s + \pi_s \Delta_s$."

On finding 4: "`pinv(V_R, rcond=1e-10)` returns the Moore-Penrose pseudoinverse; if V_R has effective rank $r < J_R$, the resulting Wald statistic is distributed $\chi^2_r$, not $\chi^2_{J_R}$."

On finding 9 (smoke-test interpretation): "Without diagnostics it's not clear which" of the three issues is dominant; recommends running the synth T=2 validation as the immediate diagnostic.

---

## Author response

### Finding 1 (alpha_s contamination): empirically refuted

The critic's algebra assumes the OLS estimates alpha_s without a free beta_s coefficient for that switcher. In the implementation, alpha_s and beta_s are jointly fit. Because alpha_s appears at every observation where trajectory == s, while beta_s appears only when trajectory == s AND choice == 1, OLS separates them cleanly:

- $\hat\alpha_s \to \mathbb{E}[y \mid \text{traj}=s, D=0] = \mu_s$
- $\hat\beta_s \to \mathbb{E}[y \mid \text{traj}=s, D=1] - \mathbb{E}[y \mid \text{traj}=s, D=0] = \Delta_s$

The synthesizer (`synth_t2_validation.py`) confirms this: with true $\mu_2 = 2.0$, $\mu_3 = 3.0$, $\Delta_2 = 0.5$, $\Delta_3 = -1.0$, the OLS recovers $\hat\alpha_2 = 2.08$, $\hat\alpha_3 = 3.01$, $\hat\beta_2 = 0.48$, $\hat\beta_3 = -1.00$. None of these is contaminated by $\pi_s \Delta_s$.

Definitive evidence: the original `.ado` and the Python implementation produce **identical CIs** on the same synthetic data:

| Implementation | CI lower | CI upper |
|---|---|---|
| Original `grc_weak_id_inference.ado` | $-1.78$ | $-1.44$ |
| Python `lca_inversion.py` | $-1.78$ | $-1.44$ |

If finding 1 were correct, the Python CI would be biased away from the truth and the two implementations would not agree to 2 decimals. They do.

### Finding 2 (cluster correction): minor but real; fix with explicit DOF correction

The critic is right that statsmodels' default cluster correction differs from Stata's. The empirical effect at $N \approx 10{,}000$ is below 2-decimal precision (CIs match exactly). For the IDN run at $N \approx 92{,}000$, the effect is even smaller. Worth a one-line fix to apply Stata's $(N-1)/(N-K) \cdot G/(G-1)$ factor explicitly so the Python and Stata Walds agree to higher precision. Tracked.

### Finding 3 (encoding): no issue

The critic confirmed the encoding is mathematically correct. Their substantive concern (that we test the "right" hypothesis) reduces to finding 1, which is refuted.

### Finding 4 (pinv silent rank-drop): real, fix needed

For $J_R = 1$ (T=2 case), $V_R$ is a scalar and pinv's rank handling is irrelevant. For $J_R > 1$ (CKT cases with $T \in \{3,4,5\}$), if a sparse switcher slips past `drop_sparse_switchers`, $V_R$ could be near-singular and `pinv` would silently drop a singular value, mismatching the chi-squared dof. Fix: compute effective rank from `pinv` and use `df = rank` when it differs from $J_R$. Tracked.

### Finding 5 (one-sided sparse drop): valid; fix

Currently we drop switchers with too few treated person-years (`switcher_s == 1 & choice == 1`). We should symmetrically drop switchers with too few untreated person-years. In the unbalanced-panel case, a switcher observed mostly in one state would destabilize the alpha estimate. Tracked.

### Findings 6, 7, 8: minor; tracked

- 6: construct `unbalanced_choice = unbalanced * choice` in code rather than reading the column.
- 7: add `assert` that the smallest trajectory has 0 treated observations and the largest has 100% treated.
- 8: island detection deferred per plan; flagged for CHN but not blocking IDN.

### Finding 9 (smoke-test interpretation): updated

With finding 1 refuted, the IDN smoke-test result (Wald min = 123 at phi = -2.3, rejects everywhere on $[-6, 2]$ at 5%) is most plausibly a **real LCA failure**, not implementation noise:

- The GMM J-stat on the same spec rejects at 5% (J ≈ 86, dof ≈ 28, p ≈ 1e-7).
- The inversion test is more aggressive than J because all 26 restrictions must hold at a single fixed $\phi$, while J allows other parameters to absorb misfit.
- Findings 4 and 5 could inflate the Wald slightly (sparse switchers with bad rcond handling) but cannot account for a 3.2x ratio of Wald (123) to the chi-square critical value (38.9).

**Provisional implication for the paper:** in IDN/cons/urban/unb without covariates, LCA is rejected jointly. Worth running with covariates (covs_1, covs_2 specs) and on CHN/TZA to see if the rejection is universal. If so, the LCA assumption is empirically untenable in this dataset and the GMM's reported $\hat\phi$ is best read as a partially-identified summary.

## Action items (tracked in `docs/TODO.md`)

1. Fix critic finding 4: detect rank loss in `pinv(V_R)`, use effective-rank dof.
2. Fix critic finding 5: symmetric sparse-switcher drop (treated AND untreated).
3. Fix critic finding 2: explicit Stata-style cluster correction in OLS.
4. Fix critic findings 6, 7: small robustness improvements.
5. Run on IDN with covs_1 and covs_2 to see if LCA rejection persists with controls.
6. Run on CHN and TZA to check universality of LCA rejection.

## Files involved

- `lca_inversion.py` (the reviewed file)
- `synth_t2_validation.py` and `.do` (the validation that empirically refuted finding 1)
- `synth_t2_python_ci.csv`, `synth_t2_stata_ci.csv` (CI agreement evidence)
- `quality_reports/session_logs/2026-04-23_afternoon-rank-deficient-S.md` (context)
