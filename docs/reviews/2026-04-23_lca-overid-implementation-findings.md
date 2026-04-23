# LCA-overid: implementation findings from VV's published Stata code

**Date:** 2026-04-23
**Source:** `tmp/vv-replication/replication_archive/Table1/Code/{nrobust,robust,firststage_projection,extrapolation}.do` (Verdier's own implementation; identified via `README.txt` line 25, "Table 1 can be replicated... by running the code Table1/Code/extrapolation.do").
**Companion:** [5-agent E.3.2 transcription](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-23_lca-overid-derivation.md). This memo resolves Q1--Q3 from §7 of that file.

## 0. Important correction

The `Footnote31/` folder is **not** the LCA-overid test. It is the over-ID test of the underlying CRC model (constant $a_i, b_i$ over time). The LCA-overid test --- testing the linear extrapolation $a_i = \alpha_0 + \alpha_1 b_i + \epsilon_i$ that lets us go from movers to stayers --- lives in `Table1/Code/`, with `nrobust.do` for the simple spec and `robust.do` for the robust spec.

`test_distance/` implements the cost-shifter alternative test (variant C in our design memo), not the LCA-overid.

## 1. VV's implementation pattern

A single `gmm` call with the entire system stacked:

1. **First-stage projection moments** ($\hat\gamma$). $|w|$ moment conditions, one per nuisance covariate.
2. **Identifying moment for $\alpha_1$** via the optimal-IV weighting matrix.
3. **Averaging moments for stayer ATEs**, switcher ATEs, and per-period subgroup ATEs (used for nlcom-style aggregation).
4. **Overid moments** with $\eta_0, \eta_t$ parameters that are exactly identified --- they record the value of the moment at the estimated $(\hat\alpha_0, \hat\alpha_1)$.

The `gmm` call uses **two instrument blocks** (`instruments(1: ..., nocons) instruments(2: ..., nocons)`) so the first-stage moments use the partialled-out covariates and the second-stage moments use the optimal IVs.

After estimation: `test [eta0]_cons [eta1]_cons ... [etaT]_cons` produces a Wald $\chi^2_{T-1}$ statistic, with p-value `chi2tail(T-1, chi2)`.

## 2. Resolved open questions

### Q1: Does `run_grc` already produce $\hat a_i, \hat b_i$?

**Answer:** VV does NOT extract $\hat a_i, \hat b_i$ as separate generated variables. Instead, the entire moment system is written in terms of partialled-out variables `yp1, yp2` (the within-individual means by treatment status of the dependent variable, then differenced) and parameters $\gamma$. The expression `(a - alpha0 - alpha1*return)` in VV's code is shorthand for an algebraic expression in `yp1, yp2, wp1*, wp2*, gamma*`, evaluated row by row.

**Implication for CKT:** We do NOT need a separate `predict` step or worker-level regression. The CKT analogue is:

- The trajectory means $\mu_{\underline d}$ in `run_grc` play the role of VV's per-trajectory $\hat a_i$ values.
- The implied switcher slope from $\phi$ plays the role of VV's $\hat b_i$.
- The "epsilon" expression in CKT terms is `(mu_d - alpha0 - phi*Delta_d)` summed over trajectories, where `Delta_d` is the trajectory-specific return implied by the LCA line.

The LCA-overid moments can therefore be appended to `run_grc`'s GMM equation as additional `( ... -{eta_t})` terms, without restructuring the existing first-stage.

### Q2: Does the augmented `gmm` system over-determine $\phi$?

**Answer:** No. Each $\eta_t$ is exactly identified by its own moment. The system adds $|S|+1$ moments AND $|S|+1$ free parameters ($\eta_0, \eta_1, \ldots, \eta_{|S|}$). The $\eta$'s absorb the moment values; the original $\phi$ identification is unchanged. The Wald test then asks whether the $\hat\eta$'s are jointly zero.

The original plan's worry that this would over-determine $\phi$ was wrong. The augmentation is exact-identifying for the new parameters, leaving the existing identification intact.

**One subtle point:** VV uses `winitial(unadjusted, independent)` and `onestep` to keep the GMM weighting matrix block-diagonal between the first-stage and second-stage moment groups. This prevents the optimal-IV reweighting from contaminating the first-stage `gamma` estimates. CKT's existing `run_grc` uses `gmm`'s default 2-step weighting; for the augmented version we should switch to VV's pattern (or at minimum pin the weighting to `independent`).

### Q3: Does $\alpha_0$ become $\alpha_0(v)$ in the robust spec?

**Answer:** No, and this is the cleanest finding. VV's `robust.do` handles cluster intercepts as follows:

1. **Drop $\alpha_0$ from the epsilon expression entirely.** `local epsilon (a-{alpha1}*return)` --- no scalar intercept.
2. **Village-residualize the treatment instruments.** `reg hybrid`per' i.vil if switcher; predict hybrid`per'd ..., resid` — this is the within-$v$ demeaning at the instrument level.
3. **Build cluster-specific intercept predictions.** `reg yp1 i.vil if switcher; predict yp1_intercept ..., xb` --- and analogously for `yp2` and each `wp1*, wp2*` covariate. These are the village-specific intercepts $e_v$ (= CKT's $\beta(v)$).
4. **Use the cluster-specific intercept in the stayer extrapolation:** `(a - intercept) / alpha1` instead of `(a - alpha0) / alpha1`.
5. **Drop the $\eta_0$ overid moment.** Only $\eta_1, \ldots, \eta_{|S|}$ are tested ($|S|$ moments instead of $|S|+1$).
6. **Df is unchanged: $|S|-1$.**

This means the cluster intercepts are not new free parameters in the GMM; they are **first-stage residualization artifacts**, computed once outside the `gmm` call.

**Implication for CKT:** the robust spec's "trajectory $\times v$ means" we worried about (up to 406 free $\mu$'s for CHN) reduce to:
- One residualization regression per (covariate, period) pair against `i.vfirst if switcher`.
- Predicted intercepts saved as variables for use in the GMM equation.
- The GMM call itself has the same parameter count as the simple spec (one $\alpha_1$, $|w|$ gammas, $|S|$ etas, plus the ATE-averaging targets).

This is far cleaner than what we'd planned, and aligns with VV's Section F derivation in the appendix.

## 3. Bootstrap not needed (per VV)

VV's published code uses **analytical cluster-robust SEs** (`vce(cluster vil)`) and reports the $\chi^2$ p-value via `chi2tail`. He does NOT run a wild-cluster bootstrap for the LCA-overid test in `nrobust.do` or `robust.do`.

Footnote 31's bootstrap (which we read first) is a different test --- the CRC-model overid --- and there VV uses a cluster bootstrap because the test statistic is non-standard (an F from a residual projection) and the asymptotic distribution is harder to characterize.

**Implication for CKT:** The default for the LCA-overid test should be analytical SEs (`vce(cluster vfirst)` for the robust spec, `vce(cluster pid)` for the simple spec). Bootstrap inference (planned in the previous revision as `boottest`) becomes a robustness check rather than the primary route. With $G \in \{19, 22, 13\}$ for our primary specs, we should still run `boottest` as a cross-check, but the headline number is the analytical p-value matching VV's own implementation.

## 4. Translation matrix: VV → CKT

| VV symbol | VV variable | CKT analogue | Built from |
|---|---|---|---|
| $a_i$ | `(yp1 - sum gamma*wp1)` | $\mu_{\underline d_i}$ | trajectory mean from `run_grc` |
| $b_i$ | `(yp2 - sum gamma*wp2)` | $\Delta_i$ implied by LCA line | derived from $\hat\phi$, $\hat\Delta_{d_0}$, trajectory mean |
| $\alpha_0$ | `{alpha0}` (simple) | $\beta$ (the LCA intercept) | new parameter to add |
| $\alpha_0(v)$ | `intercept` (robust, derived) | $\beta(v)$ | residualization regression |
| $\alpha_1$ | `{alpha1}` | $\phi$ | already in `run_grc` |
| $\eta_0, \eta_t$ | `{eta0}, {eta`per'}` | same | new parameters in augmented GMM |
| $S$ | `start` to `end` (period range with treatment variation) | switcher-defining periods $\{1,\ldots,T\}$ for $T\geq 3$ | already implicit in CKT trajectory definition |
| `vil` | first-wave village | `vfirst` (province) | corrected `gen_vfirst` |
| `hybrid` | treatment indicator | `choice` (urban/non-ag) | already in CKT data |
| `switcher`, `never`, `always` | three groups | same names in CKT | already defined |

## 5. CKT implementation skeleton (revised)

For `run_grc_overid` in CKT (simple spec, mirrors `nrobust.do`):

```stata
program define run_grc_overid
    syntax , estname(string) switchers(numlist) base(numlist) ///
        balance(string) [covars(varlist) iterate(numlist) initial(string)]

    * 1. Build epsilon-equivalent expression in CKT trajectory variables.
    *    For each switcher s, epsilon_s = (mu_s - alpha0 - phi*Delta_s)
    *    where Delta_s is the LCA-implied switcher return.
    * 2. Build per-period instrument indicators (analogue of hybrid`per'IV).
    * 3. Stack: original run_grc moments + overid moments.
    * 4. Use multiple instrument blocks per VV pattern (block 1: original
    *    CKT instruments; block 2: per-period overid instruments).
    * 5. winitial(unadjusted, independent), onestep, vce(cluster pid).
    * 6. Post-estimation: test [eta0]_cons [eta1]_cons ...
    *    estadd lca_chi2, lca_df, lca_p.
end
```

For the robust spec (mirrors `robust.do`):
- Add a pre-step that residualizes each switcher-side trajectory dummy against `i.vfirst if switcher` and predicts cluster-specific intercepts.
- Drop the `{alpha0}` parameter from epsilon (cluster intercepts absorb it).
- Drop the `{eta0}` moment (only $|S|$ moments left, $|S|-1$ df unchanged).
- `vce(cluster vfirst)`.

## 6. Updated open questions

| # | Status | Note |
|---|---|---|
| Q1 | RESOLVED | No separate $\hat a_i, \hat b_i$ extraction needed; expressions written in trajectory variables. |
| Q2 | RESOLVED | $\eta$'s are exact-ID for new parameters; $\phi$ identification unchanged. |
| Q3 | RESOLVED | Cluster intercepts come from residualization regressions, not as free GMM parameters. |
| Q4 | OBSOLETE | Original Q4 was "read VV's implementation" --- done; this memo is the result. |
| Q5 | OPEN (P2) | Always-urban: rural-origin $\phi$ vs separate $\phi^U$. VV's Kenya app has no analogue. |
| Q6 | OPEN (P4) | IDN `migr==0` semantics. |
| Q7 (new) | OPEN (P0) | The CKT `run_grc` first-stage is structurally different from VV's Chamberlain projection. We need to decide whether to (a) write the LCA-overid as an extension of `run_grc`'s existing GMM equation, or (b) add a parallel Chamberlain-style first-stage just for the overid test. Option (a) is more efficient and faithful to CKT; option (b) is more faithful to VV's implementation. Recommend (a). |
| Q8 (new) | OPEN (P0) | VV uses `winitial(unadjusted, independent)` and `onestep`. Current `run_grc` uses `gmm` defaults (2-step). Either we change `run_grc_overid` to match VV's pattern (recommended), or we accept the default and document the deviation. |

## 7. Plan changes triggered by this memo

The revised plan (`docs/plans/2026-04-22-verdier-robust-grc.md`) needs three updates:

1. **P0 §2.3 bootstrap-implementation choice:** demote bootstrap from "default" to "robustness check". Default is now analytical $\chi^2$ via `vce(cluster vfirst)` per VV's own implementation. Bootstrap (`boottest`) runs alongside as a cross-check, especially given $G \in \{13, 19, 22\}$.

2. **P3 §5.1 `run_grc_overid` skeleton:** rewrite per §5 of this memo. Joint GMM with multiple instrument blocks; analytical SEs; test on $\eta_t$'s.

3. **P3 robust-spec implementation:** the "robust" spec doesn't add cluster $\mu$'s as free parameters. Instead it adds a residualization pre-step + drops $\alpha_0, \eta_0$. The plan's discussion of "within-demeaning at the GMM level" was directionally right but mis-specified at the parameter level.

## 8. Sign-off

- [ ] **Implementation findings approved.**
- [ ] **Original LCA-overid memo Q1--Q3 marked resolved with reference to this file.**
- [ ] **Plan §P0 §2.3, §P3 §5.1, §P3 robust-spec: revise per §7 above.**
- [ ] **Q7 and Q8 resolved before P3 code is written.**
