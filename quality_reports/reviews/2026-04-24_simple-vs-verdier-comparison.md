# Simple GRC vs Verdier robust: main-results comparison

**Date:** 2026-04-24
**Specification:** consumption | urban | unbalanced panel
**Approaches compared:**
- **Simple** --- `run_grc` (Stata default two-step GMM, `vce(cluster pid)`), as published in CKT.
- **Verdier** --- `run_grc_robust_vv` (VV-adapted: cluster-demeaned treatment instruments, `winitial(unadjusted, independent), onestep, vce(cluster vfirst)`). See [derivation memo](2026-04-23_robust-grc-derivation.md).

**Data / estimator files:**
- `explorations/verdier/x_main_comparison.do` --- fit 30 models (3 countries × 5 cov variants × 2 approaches).
- `explorations/verdier/x_main_comparison_tables.do` --- renders the tables below from the saved results dta.
- `explorations/verdier/x_main_comparison_results.dta` --- one row per (country, cov_spec, approach).

**Cluster variable (`vindex` for Verdier):** `prov` (IDN), `provcd` (CHN), `region` (TZA).

---

## 1. Full covariate breakdown

Each cell is `coef (se)`.
The `covs_0` column is included for completeness but fails sanity checks everywhere (no period FE, so time trends leak into $\phi$; Hansen J strongly rejects for all three countries; TZA covs_0 fails to converge).
Read `covs_trend` through `covs_all` as the meaningful columns.

### 1.1 IDN --- consumption | urban | unbalanced

| Statistic | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |
|-----------|-------:|-----------:|-------:|-------:|---------:|
| $\phi$ (simple) | $-2.445 (0.070)$ | $-0.309 (0.087)$ | $-0.310 (0.087)$ | $-0.321 (0.086)$ | **$-0.526 (0.102)$** |
| $\phi$ (Verdier) | $-2.678 (0.300)$ | $-0.228 (0.121)$ | $-0.229 (0.121)$ | $-0.240 (0.124)$ | **$-0.334 (0.147)$** |
| $\Delta_{d_N}$ (simple) | $0.304 (0.054)$ | $0.086 (0.021)$ | $0.086 (0.021)$ | $0.091 (0.021)$ | **$0.071 (0.018)$** |
| $\Delta_{d_N}$ (Verdier) | $0.311 (0.115)$ | $0.075 (0.028)$ | $0.075 (0.028)$ | $0.080 (0.028)$ | **$0.057 (0.025)$** |
| $\Delta_{d_T}$ (simple) | $0.460 (0.041)$ | $-0.053 (0.042)$ | $-0.053 (0.042)$ | $-0.053 (0.043)$ | $-0.096 (0.061)$ |
| $\Delta_{d_T}$ (Verdier) | $0.448 (0.043)$ | $-0.021 (0.041)$ | $-0.021 (0.041)$ | $-0.020 (0.041)$ | $-0.026 (0.032)$ |
| $\Delta_{\text{avg}}$ (simple) | $0.027 (0.002)$ | $0.003 (0.001)$ | $0.003 (0.001)$ | $0.003 (0.001)$ | $0.003 (0.001)$ |
| $\Delta_{\text{avg}}$ (Verdier) | $0.028 (0.002)$ | $0.003 (0.001)$ | $0.003 (0.001)$ | $0.003 (0.001)$ | $0.003 (0.001)$ |
| Hansen $J$ (simple) | $86.5$ ($p=0.00$) | $32.5$ ($p=0.21$) | $32.4$ ($p=0.22$) | $33.3$ ($p=0.19$) | $28.2$ ($p=0.40$) |
| $Q$ (simple) | $9.4 \times 10^{-4}$ | $3.5 \times 10^{-4}$ | $3.5 \times 10^{-4}$ | $3.6 \times 10^{-4}$ | $3.0 \times 10^{-4}$ |
| $Q$ (Verdier) | $1.9 \times 10^{-3}$ | $2.2 \times 10^{-4}$ | $2.2 \times 10^{-4}$ | $2.3 \times 10^{-4}$ | $2.3 \times 10^{-4}$ |
| Converged (simple / Verdier) | Y / Y | Y / Y | Y / Y | Y / Y | Y / Y |
| $N$ (simple / Verdier) | 92,450 / 92,153 | 92,450 / 92,153 | 92,439 / 92,142 | 92,439 / 92,142 | 92,439 / 92,142 |

Verdier drops ~300 observations relative to simple because some workers have missing first-wave province.

### 1.2 CHN --- consumption | urban | unbalanced

| Statistic | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |
|-----------|-------:|-----------:|-------:|-------:|---------:|
| $\phi$ (simple) | $-0.898 (0.056)$ | $-0.073 (0.134)$ | $-0.073 (0.134)$ | $-0.161 (0.117)$ | **$-0.205 (0.134)$** |
| $\phi$ (Verdier) | $-0.742 (0.126)$ | $-0.076 (0.202)$ | $-0.076 (0.201)$ | $-0.130 (0.197)$ | **$-0.155 (0.231)$** |
| $\Delta_{d_N}$ (simple) | $0.424 (0.021)$ | $0.090 (0.028)$ | $0.090 (0.028)$ | $0.104 (0.023)$ | **$0.098 (0.021)$** |
| $\Delta_{d_N}$ (Verdier) | $0.398 (0.044)$ | $0.091 (0.042)$ | $0.091 (0.042)$ | $0.101 (0.038)$ | **$0.095 (0.035)$** |
| $\Delta_{d_T}$ (simple) | $-0.109 (0.398)$ | $0.059 (0.046)$ | $0.059 (0.046)$ | $0.032 (0.054)$ | $0.033 (0.050)$ |
| $\Delta_{d_T}$ (Verdier) | $0.150 (0.247)$ | $0.058 (0.079)$ | $0.058 (0.079)$ | $0.044 (0.094)$ | $0.049 (0.085)$ |
| $\Delta_{\text{avg}}$ (simple) | $0.020 (0.001)$ | $0.003 (0.001)$ | $0.003 (0.001)$ | $0.004 (0.001)$ | $0.004 (0.001)$ |
| $\Delta_{\text{avg}}$ (Verdier) | $0.019 (0.002)$ | $0.003 (0.002)$ | $0.003 (0.002)$ | $0.004 (0.002)$ | $0.004 (0.002)$ |
| Hansen $J$ (simple) | $98.9$ ($p=0.00$) | $17.1$ ($p=0.03$) | $17.1$ ($p=0.03$) | $18.3$ ($p=0.02$) | $17.5$ ($p=0.02$) |
| $Q$ (simple) | $9.0 \times 10^{-4}$ | $1.6 \times 10^{-4}$ | $1.6 \times 10^{-4}$ | $1.7 \times 10^{-4}$ | $1.6 \times 10^{-4}$ |
| $Q$ (Verdier) | $1.2 \times 10^{-3}$ | $1.0 \times 10^{-4}$ | $1.0 \times 10^{-4}$ | $1.1 \times 10^{-4}$ | $1.1 \times 10^{-4}$ |
| Converged (simple / Verdier) | Y / Y | Y / Y | Y / Y | Y / Y | Y / Y |
| $N$ (simple / Verdier) | 109,535 / 109,535 | 109,535 / 109,535 | 109,535 / 109,535 | 109,535 / 109,535 | 109,535 / 109,535 |

Hansen $J$ rejects at 5% for CHN on every spec with period FE --- consistent with the known CHN multi-regime issue (pooling hukou types rejects the single-$\phi$ restriction).

### 1.3 TZA --- consumption | urban | unbalanced

| Statistic | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |
|-----------|-------:|-----------:|-------:|-------:|---------:|
| $\phi$ (simple) | $-0.998 (0.064)$ | $-0.515 (0.091)$ | $-0.523 (0.092)$ | $-0.534 (0.093)$ | **$-0.719 (0.124)$** |
| $\phi$ (Verdier) | $-0.998 (0.145)$ | $-0.406 (0.144)$ | $-0.414 (0.146)$ | $-0.425 (0.147)$ | **$-0.690 (0.087)$** |
| $\Delta_{d_N}$ (simple) | $0.539 (0.036)$ | $0.301 (0.039)$ | $0.304 (0.039)$ | $0.301 (0.039)$ | **$0.270 (0.033)$** |
| $\Delta_{d_N}$ (Verdier) | $0.539 (0.085)$ | $0.261 (0.053)$ | $0.264 (0.054)$ | $0.263 (0.052)$ | **$0.259 (0.033)$** |
| $\Delta_{d_T}$ (simple) | $-138.6$ ($5951$) | $-0.262 (0.133)$ | $-0.273 (0.138)$ | $-0.289 (0.146)$ | $-0.662 (0.469)$ |
| $\Delta_{d_T}$ (Verdier) | $-138.6$ ($1.3 \times 10^4$) | $-0.129 (0.205)$ | $-0.136 (0.212)$ | $-0.146 (0.223)$ | $-0.578 (0.388)$ |
| $\Delta_{\text{avg}}$ (simple) | $0.010 (0.002)$ | $0.012 (0.002)$ | $0.012 (0.002)$ | $0.012 (0.002)$ | $0.012 (0.002)$ |
| $\Delta_{\text{avg}}$ (Verdier) | $0.010 (0.005)$ | $0.012 (0.003)$ | $0.012 (0.003)$ | $0.012 (0.003)$ | $0.012 (0.003)$ |
| Hansen $J$ (simple) | $63.0$ ($p=0.00$) | $6.7$ ($p=0.08$) | $6.5$ ($p=0.09$) | $6.7$ ($p=0.08$) | $3.8$ ($p=0.28$) |
| $Q$ (simple) | $2.1 \times 10^{-3}$ | $2.2 \times 10^{-4}$ | $2.2 \times 10^{-4}$ | $2.2 \times 10^{-4}$ | $1.3 \times 10^{-4}$ |
| $Q$ (Verdier) | $5.0 \times 10^{-3}$ | $7.1 \times 10^{-5}$ | $7.0 \times 10^{-5}$ | $7.3 \times 10^{-5}$ | $8.1 \times 10^{-5}$ |
| Converged (simple / Verdier) | **N / N** | Y / Y | Y / Y | Y / Y | Y / Y |
| $N$ (simple / Verdier) | 29,864 / 29,864 | 29,864 / 29,864 | 29,864 / 29,864 | 29,864 / 29,864 | 29,864 / 29,864 |

TZA covs_0 fails to converge under either approach; the $\Delta_{d_T} = -138.6$ value is garbage from the non-convergent fit and should be ignored.

---

## 2. Statistical significance

Thresholds: *** $= 1\%$ ($\|z\| > 2.576$), ** $= 5\%$ ($\|z\| > 1.960$), * $= 10\%$ ($\|z\| > 1.645$), ns otherwise.

### 2.1 $\phi$

| Country | Approach | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |
|---------|----------|:------:|:----------:|:------:|:------:|:--------:|
| IDN | simple | *** | *** | *** | *** | *** |
| IDN | Verdier | *** | * | * | * | ** |
| CHN | simple | *** | ns | ns | ns | ns |
| CHN | Verdier | *** | ns | ns | ns | ns |
| TZA | simple | *** | *** | *** | *** | *** |
| TZA | Verdier | *** | *** | *** | *** | *** |

### 2.2 $\Delta_{d_N}$

| Country | Approach | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |
|---------|----------|:------:|:----------:|:------:|:------:|:--------:|
| IDN | simple | *** | *** | *** | *** | *** |
| IDN | Verdier | *** | *** | *** | *** | ** |
| CHN | simple | *** | *** | *** | *** | *** |
| CHN | Verdier | *** | ** | ** | *** | *** |
| TZA | simple | *** | *** | *** | *** | *** |
| TZA | Verdier | *** | *** | *** | *** | *** |

### 2.3 Where significance changes

| Where | What happens |
|---|---|
| IDN $\phi$, covs_trend through covs_2 | *** $\to$ * |
| IDN $\phi$, covs_all | *** $\to$ ** |
| IDN $\Delta_{d_N}$, covs_all | *** $\to$ ** |
| CHN $\Delta_{d_N}$, covs_trend / covs_1 | *** $\to$ ** |
| CHN $\phi$ (all covs_trend+) | ns $\to$ ns (unchanged --- never significant under either) |
| TZA (everything) | *** $\to$ *** (unchanged) |

Nothing flips from significant to not-significant at the $10\%$ level.
Verdier widens SEs for IDN and CHN, so some estimates drop a significance tier (1% $\to$ 5% or 10%), but $\phi$ and $\Delta_{d_N}$ remain statistically distinguishable from zero in every spec where they were under the simple GRC.
The already-not-significant CHN $\phi$ stays not significant.

The most fragile case is IDN under covs_trend through covs_2: simple GRC shows $\phi$ strongly significant ($***$, $\|z\| \approx 3.5$), Verdier drops it to borderline ($*$, $\|z\| \approx 1.9$).
Substantively still negative and pointing the same way, just with much less statistical precision --- which is honest given the Verdier spec uses less of the cross-cluster variation.

---

## 3. Big-picture observations

1. **$\phi < 0$ at covs_all under both approaches in all three countries.**
    - IDN: $-0.526$ (simple) vs $-0.334$ (Verdier).
    - CHN: $-0.205$ vs $-0.155$.
    - TZA: $-0.719$ vs $-0.690$.

    Pro-poor pattern holds whether you use the original two-step GRC or the Verdier robust spec.

2. **Verdier pulls $\phi$ toward zero by 20--40% at covs_all.** Some of the estimated pro-poor-ness in the simple spec was coming from cross-cluster variation in baseline returns, which Verdier absorbs.

3. **$\Delta_{d_N}$ is remarkably stable across approaches:** 0.07 $\to$ 0.06 (IDN), 0.10 $\to$ 0.09 (CHN), 0.27 $\to$ 0.26 (TZA). Under both approaches, never-migrants gain $\approx 7\%$ (IDN), $\approx 10\%$ (CHN), $\approx 26\%$ (TZA) log consumption from hypothetical migration.

4. **SE behavior is country-specific:**
    - TZA: Verdier SE on $\phi$ is tighter ($0.087$ vs $0.124$). Cluster-demeaning helps.
    - IDN, CHN: Verdier SE wider (e.g., IDN $0.147$ vs $0.102$). Less within-cluster variation relative to between.

5. **Hansen $J$ (simple) rejects at 5% for CHN on every spec;** IDN and TZA don't reject. Consistent with the known CHN hukou multi-regime issue.

6. **No-covariates spec (covs_0) is broken everywhere.** Use covs_trend as the minimum.

7. **TZA covs_0 fails to converge under either approach.** The $\Delta_{d_T} = -138.6$ is a non-convergent artifact.

---

## 4. Next-step open questions

- **IDN $\phi$ is the biggest mover** (-0.53 $\to$ -0.33). Worth a closer look at which provinces drive the shift. The drop from *** to ** significance at covs_all --- and to * at covs_trend through covs_2 --- is the strongest caveat in the Verdier rollout.
- **CHN $\Delta_{d_T}$ under covs_0** (simple $= -0.109$, Verdier $= +0.150$) flips sign across approaches; another artifact of the badly specified no-covariates case, but flag for sanity.
- **Income and balanced-panel tables** have not been re-fit yet. If they show similar stability the story holds; if $\phi$ sign flips somewhere, we'd want to report both.

**Data dependencies:** all .ster estimate files saved in `$output/cmp_{country}_{cov}*.ster` and `$output/cmpvv_{country}_{cov}*.ster`. Re-run `x_main_comparison_tables.do` to regenerate this document's numerical content from those files.
