# CHN-hukou V3 joint CI: RF and UF

**Date:** 2026-05-20.
**Branch:** lca-inversion.
**Files:**

- Stata exporter: [RP7/scripts/_export_e1_inputs_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs_hukou.do)
- Python driver: [explorations/2026-05-20_e1_v3_joint_ci_hukou.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-20_e1_v3_joint_ci_hukou.py)
- CSV inputs: `RP7/output/counterfactual_inputs/CHN_{rf,uf}_e1_*.csv`
- Parent ster scalars (5c attach): `RP7/output/grc_CHN_{rf,uf}_cuu_ca.ster`

## What this run does

Closes the CHN piece of E1 by routing through the hukou-split sters rather than the pooled CHN sample (whose $J$-test rejects).
The exporter mirrors `_export_e1_inputs.do` but reads the RF and UF parent + `_d` sters and the corresponding `_unb.dta` files.
The Python driver mirrors `2026-05-20_e1_v3_joint_ci.py` (IDN/TZA) with two adjustments: the lattice extends to $\phi = -3.5$ to cover the UF region, and the country loop reads hukou-specific CSVs.
Outcome, controls, and sample selection match the GMM cuu_ca specification.

## Headline numbers

### CHN-RF (rural-hukou-first) cuu_ca

| object | value |
|---|---:|
| Joint CI: accepted lattice points | $75$ of $45{,}551$ ($0.16\%$) |
| Joint connected components | $1$ |
| Marginal $\phi$ projection | $[-0.300, -0.070]$ |
| Marginal $\beta$ projection | $[+0.100, +0.140]$ |
| Wald at GMM point $(-0.0389, +0.1046)$ | $18.87$ (threshold $18.31$; $p = 0.042$) |
| Aggregate $W_{\text{obs}} - W_{\text{zero}}$ | $[+5.36\%, +6.77\%]$ |
| Aggregate misallocation gap | $[+10.49\%, +11.69\%]$ |

The joint CI is tight and well-behaved; the marginal $\phi$ projection sits comfortably above the identification boundary at $\phi = -1$.
The misallocation gap convex hull is $[+10.5\%, +11.7\%]$ in geometric-mean consumption, narrower than IDN or TZA.

A wrinkle worth flagging: the GMM point $(\hat\phi, \hat\beta) = (-0.0389, +0.1046)$ sits **just outside** the joint CI ($p = 0.042$).
The auxiliary-OLS-based joint test and the GMM Hansen $J$ test different hypotheses, so a discrepancy at the $5\%$ level is not by itself a refutation of the model.
Two readings: (i) finite-sample noise putting the GMM point at the boundary of acceptance; (ii) a real tension between the auxiliary OLS and the GMM that warrants investigation before relying on RF numbers in the paper.
Worth a follow-up diagnostic.

### CHN-UF (urban-hukou-first) cuu_ca

| object | value |
|---|---:|
| Joint CI: accepted lattice points | $13{,}072$ of $45{,}551$ ($28.7\%$) |
| Joint connected components | $1$ |
| Marginal $\phi$ projection | $[-3.500, -0.710]$ |
| Marginal $\beta$ projection | $[-0.350, +0.240]$ |
| Wald at GMM point $(-0.9731, +0.1888)$ | $9.99$ (threshold $12.59$; $p = 0.125$) |
| Aggregate $W_{\text{obs}} - W_{\text{zero}}$ | $[-99.92\%, +138{,}727.02\%]$ |
| Aggregate misallocation gap | $[+0.91\%, +130{,}660.80\%]$ |

The aggregate is not interpretable in this form.
The marginal $\phi$ projection $[-3.500, -0.710]$ contains the identification boundary at $\phi = -1$, and the lattice runs straight through it.
At lattice points with $\phi$ in (roughly) $(-1.01, -0.99)$, the $\Delta_{d_T}$ formula divides by a number close to zero and the always-urban return is reported as several thousand percent.
That blowup propagates into the convex hull as $+130{,}660\%$, which is the pole, not a confidence-interval endpoint.

P3 fallback (drop the $\Delta_{d_T}$ piece, report the aggregate as $d_N$ plus switchers only) is the remedy.
With P3 in place, the UF aggregate will report a defensible upper bound and the contribution of always-urban workers will be excluded from the UF counterfactual entirely.
This is consistent with the model's logic: when $\phi$ is at or beyond the identification boundary, we have no information about the always-urban counterfactual rural return.

## Open items

1. **P3 fallback** is the immediate next module.
   Should be straightforward: extend `evaluate_aggregate` (or wrap it) to accept a `drop_dT=True` flag that zeroes out the $d_T$ piece.
   Report both the with-$d_T$ and without-$d_T$ aggregates in the driver output.
2. **RF GMM-point near-rejection** ($p = 0.042$) is worth a closer look before the RF aggregate enters the paper.
   The GMM Hansen $J$ test on the same RF parent ster gave $J = 12.64$ on 8 dof, $p = 0.124$---comfortably non-rejected.
   The discrepancy localizes to a difference between the auxiliary-OLS spec and the GMM moment structure, similar to (but smaller than) what we found for IDN.
3. **National CHN E1.**
   Once the RF and UF aggregates are clean (i.e., once P3 lands and the RF discrepancy is understood), we can compute the population-weighted CHN E1 number using the rural-first and urban-first hukou shares in the full CHN sample.
   Reporting convention agreed on 2026-05-20: report both regimes separately and the weighted aggregate.
4. **Residual upper-bound disagreement with 5b** still applies (open from the IDN/TZA V3 memo); not specific to the hukou cells.
5. **RO and UO inversion attach** (Task #3) can follow the hukou pipeline once the headline RF/UF E1 is settled.

## Identification boundary---naming convention

The Möbius singularity at $\phi = -1$ is the identification boundary for $\Delta_{d_T}$: it corresponds to $b_U = 0$, where urban earnings carry no return to workers' (rural-priced) skill, so observing always-urban workers' urban outcomes carries no information about their underlying comparative advantage.
The always-urban formula $\Delta_{d_T} = (\beta + \phi(\alpha_{d_T}^{\text{obs}} - \mu_{\text{base}})) / (1 + \phi)$ divides by $(1+\phi)$, so the implied $\Delta_{d_T}$ inflates without bound as $\phi$ approaches $-1$.
For paper text, we will avoid "Möbius pole" and use phrasing like "the identification boundary at $\phi = -1$" or "the $\phi = -1$ knife-edge where urban earnings are flat in skill".
