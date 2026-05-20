# National CHN E1: population-weighted RF + UF aggregate

**Date:** 2026-05-20.
**Branch:** lca-inversion.
**Files:**

- Driver: [explorations/2026-05-20_e1_chn_national.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_chn_national.py)
- Run log: [explorations/logs/2026-05-20_e1_chn_national.log](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/logs/2026-05-20_e1_chn_national.log)

## Setup

Pooled CHN cuu_ca rejects the $J$-test, so CHN enters E1 through the hukou-split cells.
The driver loads the RF and UF data files, fits the auxiliary OLS, builds the joint CI grid, and projects the P3 (no-$d_T$) aggregate image for each cell.
It then combines the two cell-level P3 aggregates via a population-weighted linear combination, using interval arithmetic on the per-cell convex hulls.

## Population partition

| count | value | share of CHN |
|---|---:|---:|
| n CHN pids | $34{,}746$ | $100.00\%$ |
| n RF pids | $25{,}491$ | $73.36\%$ |
| n UF pids | $9{,}024$ | $25.97\%$ |
| n in neither (undefined hukou) | $231$ | $0.66\%$ |
| n in both (RF $\cap$ UF) | $0$ | $0.00\%$ |

RF and UF are disjoint at the pid level and together cover $99.3\%$ of CHN.
The remaining $231$ pids have undefined hukou status and are not included in either subsample.

## Per-cell P3 results

| cell | misallocation gap | value of observed migration |
|---|---:|---:|
| RF | $[+10.49\%, +11.69\%]$ | $+3.95\%$ (point) |
| UF | $[+0.91\%, +1.25\%]$ | $+5.25\%$ (point) |

Identical to the prior P3 memo; copied here for reference.

## National CHN aggregate

Three weighting schemes, all giving essentially the same result.

| weighting | $w_{\text{RF}}$ | $w_{\text{UF}}$ | misallocation gap | value of migration |
|---|---:|---:|---:|---:|
| Population (conditional on RF or UF) | $0.7385$ | $0.2615$ | $+8.02\%$, CI $[+7.90\%, +8.86\%]$ | $+4.29\%$ |
| Population (divided by full CHN N) | $0.7336$ | $0.2597$ | $+7.96\%$, CI $[+7.84\%, +8.80\%]$ | $+4.26\%$ |
| Analysis sample (post-selection) | $0.7470$ | $0.2530$ | $+8.10\%$, CI $[+7.98\%, +8.95\%]$ | $+4.28\%$ |

The three schemes agree on the headline: a national CHN misallocation gap of about $+8\%$ in geometric-mean consumption.
The CI from interval arithmetic is tight (width about $1$ percentage point) because both per-cell convex hulls are narrow.

The interval arithmetic combination is a conservative outer bound: it treats RF and UF as independent draws within their own joint CIs, which weakly inflates the CI relative to a proper joint analysis.
A tighter bound would propagate the joint $(\phi_{\text{RF}}, \beta_{\text{RF}}, \phi_{\text{UF}}, \beta_{\text{UF}})$ uncertainty assuming the four parameters are jointly identified.
For the present purpose (a headline CHN national number with a bounded CI), interval arithmetic is sufficient.

## Cross-country comparison

| country / cell | misallocation gap (P3) |
|---|---:|
| IDN | $[+5.7\%, +6.1\%]$ |
| TZA | $[+14.3\%, +22.7\%]$ |
| **CHN national (RF + UF weighted)** | $\mathbf{[+7.8\%, +8.8\%]}$ |
| CHN-RF (subsample) | $[+10.5\%, +11.7\%]$ |
| CHN-UF (subsample) | $[+0.9\%, +1.3\%]$ |

CHN sits between IDN and TZA on the misallocation gap.
The decomposition into RF and UF shows that the national $8\%$ is roughly $75\%$ rural-hukou-first contributing $10.5\%$ to $11.7\%$, plus $25\%$ urban-hukou-first contributing under $1.3\%$.
The contrast lands the headline E2 message: when the institutional barrier binds (rural-hukou-first), substantial consumption is left on the table; when it does not bind (urban-hukou-first), workers are sorted close to optimum.

## Reporting choice for the paper

Three numbers to put in front of readers, in order of how they should be read:

1. **The CHN national figure** ($+8.0\%$) as the headline magnitude for the country.
2. **The RF and UF decomposition** as the substantive content: where the misallocation lives.
3. **The hukou-removal counterfactual** (E2) as the policy-relevant magnitude: how much of the RF gap would be eliminated by giving rural-hukou-first workers the same mobility as urban-hukou-first workers.

The weighted national number on its own would obscure the institutional story; the RF/UF decomposition without the national would obscure the population-level magnitude.
Reporting both is the right discipline.

## Open items

1. **RF GMM-point near-rejection** is the most important diagnostic still open before the RF number enters the paper as a headline.
   The Wald-at-GMM check on RF returned $p = 0.042$ against $p = 0.124$ from the GMM Hansen $J$, suggesting a small aux-OLS-vs-GMM tension at the joint test level.
2. **Residual upper-bound disagreement with 5b** on the IDN marginal $\phi$ (unchanged).
3. **`project_image_intervals` binning** at small $N$ (unchanged).
4. **RO and UO inversion attach** (Task #3, deferred).
