# Within-$v$ demeaning: VV Section F adapted to the CKT GRC estimator

**Date:** 2026-04-23
**Source:** Verdier (2020) Online Appendix Section F (pp. 35--44; `tmp/VV-appendix.txt:1706-2400`).
**Companion implementation:** `tmp/vv-replication/replication_archive/Table1/Code/robust.do`.
**Purpose:** P0 prerequisite per [revised plan §2.1](file:///C:/git/ckt/.claude/worktrees/verdier/docs/plans/2026-04-22-verdier-robust-grc.md). Translates VV's robust-extrapolation derivation into CKT's GRC notation, then specifies what `run_grc_robust` actually estimates. Audience: anyone who needs to read or modify the code.

This is *not* a new derivation. VV does the work in Section F. This memo maps symbols and reconciles the difference between VV's worker-level estimator structure and CKT's trajectory-pooled structure.

## 1. Notation translation

| VV (Section F) | CKT | Comments |
|---|---|---|
| $a_i$ | trajectory mean $\mu_{\underline d_i}$ | VV is worker-level; CKT pools to trajectories. |
| $b_i$ | $\theta_i \equiv b_R(\theta_i^U - \theta_i^R)$ | Worker-specific comparative advantage. In the LCA-restricted form, $\theta_i$ enters only through $\mu_{\underline d_i}$ for switchers and through residual variation for stayers. |
| $\alpha_1$ | $\phi$ | Slope of returns on comparative advantage; common across $v$. |
| $\alpha_0$ (simple) | $\beta$ | LCA intercept. Becomes $\beta(v)$ in robust spec. |
| $e_v$ | $\beta(v)$ | Cluster-specific intercept introduced by VV (F.2): $a_i = e_{v_i} + \alpha_1 b_i + \epsilon_i$. |
| $M_n$ | switchers ($\underline d \in \mathcal{D}_S$) | Workers whose treatment status varies over time. |
| $v_i$ | first-wave province | Time-invariant cluster index per spec §3.1 (CHN/IDN: prov, TZA: region). |
| $n_v$ | switcher count in cluster $v$ | $\geq 5$ in $\geq 50\%$ of clusters per the support requirement. |
| $\hat{ATE}_{S,0}$ | $\Delta_{d_N}$ | Always-rural ATE. |
| $\hat{ATE}_{S,1}$ | $\Delta_{d_T}$ | Always-urban ATE. |
| $W_i$ ($T \times 2$) | $[1, D_{it}]$ stacked across $t$ | Within-worker treatment-status design matrix. |
| $Z_i$ | covariate matrix (period FE, female, age, education) | Same role both papers. |
| $X_i$ | treatment vector $D_i = [D_{i1}, \ldots, D_{iT}]'$ | Same role. |
| $\gamma$ | covariate coefficients | Estimated jointly in `run_grc`. |

## 2. The CKT simple spec, restated for comparison

The current `run_grc` (l.~1538 of `0_programs.do`) estimates by GMM:

$$y_{it} \;=\; \sum_{\underline d \in \mathcal{D}} \mu_{\underline d}\, \mathbb{1}\{\underline d_i = \underline d\} \;+\; \Delta_{\underline d_0} D_{it} \;+\; \phi \sum_{\underline d \in \mathcal{D}_S \setminus \underline d_0} (\mu_{\underline d} - \mu_{\underline d_0})\, D_{it}\,\mathbb{1}\{\underline d_i = \underline d\}$$

$$+\; \big(\kappa + \phi(\kappa - \mu_{\underline d_0})\big)\, \mathbb{1}\{\underline d_i = d_T\}\,D_{it} \;+\; x_{it}'\gamma \;+\; \varepsilon_{it}.$$

The free parameters are $\{\mu_{\underline d}\}_{\underline d \in \mathcal{D}}$ (one per trajectory), $\Delta_{\underline d_0}$ (return for the base switcher trajectory), $\phi$ (LCA slope), $\kappa$ (always-urban level), and $\gamma$ (covariates). Standard errors `vce(cluster pid)`.

The LCA intercept is *implicit*: $\beta = \Delta_{\underline d_0} - \phi(\mu_{\underline d_0} - 0)$, never instantiated as a free parameter.

## 3. What VV Section F changes

**Identifying assumption.** Replace VV's (E.2) (CKT's A2):
$$a_i = \alpha_0 + \alpha_1 b_i + \epsilon_i, \qquad E(\epsilon_i \mid X_i) = 0$$
with VV's (F.2):
$$a_i = e_{v_i} + \alpha_1 b_i + \epsilon_i, \qquad E(\epsilon_i \mid \{X_j\}_{j: v_j = v_i}) = 0.$$

The slope $\alpha_1$ stays scalar; the intercept becomes cluster-specific. Independence is required only *within* clusters (VV Assumption 10), not across the whole sample.

In CKT terms, the LCA restriction
$$\Delta_i = \beta + \phi\, \theta_i \quad\text{(simple)}$$
becomes
$$\Delta_i = \beta(v_i) + \phi\, \theta_i \quad\text{(robust)}.$$

**What identification needs.** Under the simple spec, $\phi$ is identified from variation in $(\mu_{\underline d}, \Delta_{\underline d})$ across all switcher trajectories pooled. Under the robust spec, $\phi$ is identified from *within-cluster* variation in $(\mu_{\underline d}, \Delta_{\underline d})$ across switcher trajectories. Across-cluster variation is absorbed by $\beta(v)$.

Equivalently (this is the within-demeaning route): the estimator that emerges if we project out cluster fixed effects from both $\mu_{\underline d_i}$ and $\Delta_{\underline d_i}$ for switchers, then runs the same LCA regression on the within-cluster-demeaned objects. This is the operational form VV uses on pp. 36--37.

## 4. Implementation route for `run_grc_robust`

CKT's `run_grc` doesn't expose worker-level $\hat a_i, \hat b_i$ as separate variables (the trajectory pooling absorbs them into $\mu_{\underline d}$). So we cannot literally apply VV's "demean $\hat a_i$ within $v_i$" step at the worker level. Instead, the equivalent operation in CKT structure is: **add cluster fixed effects to the GMM equation and let the existing trajectory-pooling do its work**.

Specifically, the robust GMM equation is:

$$y_{it} \;=\; \sum_{\underline d \in \mathcal{D}} \mu_{\underline d}\, \mathbb{1}\{\underline d_i = \underline d\} \;+\; \sum_{v} \beta(v)\, \mathbb{1}\{v_i = v\}\, D_{it} \;+\; \phi \sum_{\underline d \in \mathcal{D}_S \setminus \underline d_0} (\mu_{\underline d} - \mu_{\underline d_0})\, D_{it}\,\mathbb{1}\{\underline d_i = \underline d\}$$

$$+\; \text{(always-urban term, see §6)} \;+\; x_{it}'\gamma \;+\; \varepsilon_{it}.$$

Free parameters added vs simple: $\{\beta(v)\}_{v \in V}$, replacing the single $\Delta_{\underline d_0}$ scalar (or equivalently, $\Delta_{\underline d_0}$ becomes cluster-specific). Net additional parameter count: $|V| - 1$.

For CHN ($|V| = 29$): adds 28 parameters --- not 406 as the saturated route would have done.
For IDN ($|V| = 22$): adds 21.
For TZA ($|V| = 26$): adds 25.

Standard errors switch from `vce(cluster pid)` to `vce(cluster vfirst)`.

## 5. Why this is equivalent to VV's within-demeaning (asymptotically)

**Asymptotic claim.** Conditional on the (saturated) GMM equation in §4, the FOC for $\phi$ partials out the cluster fixed effects on $D_{it}$, leaving identification of $\phi$ to come from within-cluster covariation between $(\mu_{\underline d_i} - \mu_{\underline d_0})$ and $\Delta_{i} - \beta(v_i)$ among switchers. In large samples this matches VV's two-step within-demeaned estimator.

**Finite-sample failure (discovered 2026-04-24).** The asymptotic equivalence does NOT hold in finite sample with few clusters. The single-step parameterization adds $|V|-1$ cluster-FE parameters; under onestep GMM with $\text{vce(cluster\ vfirst)}$, the cluster-robust weighting matrix $W_2$ has maximum rank equal to the number of clusters. With $|V| \in \{22, 26, 29\}$ and $\#\text{moments} = 47$ on typical specs, $W_2$ is rank-deficient, making the GMM objective nearly flat in $\phi$ along a ridge of cluster-FE combinations.

This was confirmed by a 5-start sensitivity sweep on TZA (`explorations/verdier/x_tza_phi_sensitivity.do`):

| phistart | $\hat\phi$ | $Q$ |
|---:|---:|---:|
| $-1$ | $-1.003$ | 0.000227 |
| $-0.5, 0, +0.5, +1$ | $\approx +1.25$ | 0.000192 (lowest) |

Two local minima. The global minimum has $\text{se}(\hat\phi) \approx 3.5$ — statistically zero. CHN showed the same pathology (first fit hung $>70$ min). The "headline" TZA result from P1 ($\hat\phi = -1.00$) was an artifact of the Stata default initial value `{phi=-1}`.

**Diagnosis of the finite-sample gap.** Asymptotically the extra cluster-FE parameters are identified by within-cluster variation. In finite sample they compete with $\phi$ for explaining the same within-cluster variation, and with a rank-deficient $W_2$ the optimizer can drift along a near-flat ridge. VV's original design avoids this by using the cluster structure only in the instruments, keeping the parameter set small.

**Implementation decision (2026-04-24).** Retire the single-step cluster-FE parameterization (`run_grc_robust` in `0_programs.do`) as the robust spec. Replace with `run_grc_robust_vv`, which ports VV's `Table1/Code/robust.do` idea directly:

1. Regress `switcher_s_choice` on `i.vfirst` among workers with `switcher_s == 1`; residual is `swd_switcher_s_choice`; zero-fill non-switchers.
2. Same regression for `always_choice` among always-urban workers → `swd_always_choice`.
3. GMM with the same parameter set as `run_grc` (phi, $\mu_{\underline d}$, $\Delta_{\text{base}}$, $\kappa$, $\gamma$) -- no cluster FEs -- and the demeaned instruments in place of raw $\text{switcher\_s\_choice}$ / $\text{always\_choice}$. `vce(cluster vfirst)`, `winitial(unadjusted, independent)`, `onestep` as in VV.

5-start sensitivity on the VV-adapted spec is stable on all three countries: phi ranges are $0.002$ (TZA), $0.007$ (CHN), $0.017$ (IDN). All converge to values within $5\%$ of each other. Point estimates match `run_grc_onestep` (simple) closely, with SE changes that depend on the within-cluster vs between-cluster variance ratio.

**The cluster-FE parameterization is retained in `run_grc_robust` for reference** but should not be the primary estimator. See the §9 table below for the structural comparison.

## 6. Always-urban extrapolation under the robust spec

The simple spec computes $\Delta_{d_T}$ from the always-urban kappa-coefficient adjusted by $\phi(\kappa - \mu_{\underline d_0})$. Under the robust spec, this becomes:

$$\Delta_{d_T, v} = \beta(v) + \phi\,(\kappa(v) - \mu_{\underline d_0})$$

if $\kappa$ is also cluster-specific, OR

$$\Delta_{d_T, v} = \beta(v) + \phi\,(\kappa - \mu_{\underline d_0})$$

if we keep a scalar $\kappa$. The latter is a "cross-origin" extrapolation: we use the rural-origin $\hat\phi$ to extrapolate to always-urban workers. VV's Section F treats this as the default (his $\hat e_v$ is computed from movers in cluster $v$; stayers in $v$ inherit it).

**Decision (default):** keep $\kappa$ scalar (cross-origin extrapolation), report it in the results memo as a known caveat. Per spec §3.3 and Q5 in the open-questions register, a separate $\phi^U$ from urban-origin switchers (if support permits) is a P2 follow-up.

## 7. Estimator for $\Delta_{d_N}$ (always-rural ATE)

Per cluster $v$ with both switcher and never support:
$$\widehat\Delta_{d_N, v} = \widehat\beta(v) + \widehat\phi\,(\widehat\mu_{d_N} - \widehat\mu_{\underline d_0}).$$

Aggregate:
$$\widehat\Delta_{d_N} = \sum_{v \in V_{\text{supp}}} w_v\, \widehat\Delta_{d_N, v}, \qquad w_v = \frac{n^N_v}{\sum_{v' \in V_{\text{supp}}} n^N_{v'}},$$

where $n^N_v$ is the always-rural count in cluster $v$ and $V_{\text{supp}}$ is the set of clusters with both switcher and never support.

The simple-spec analogue, for sample-matched comparison:
$$\widehat\Delta_{d_N}^{\text{simple, supp}} = \widehat\Delta_{\underline d_0}^{\text{simple}} + \widehat\phi^{\text{simple}}\,(\widehat\mu_{d_N, V_{\text{supp}}} - \widehat\mu_{\underline d_0}),$$

i.e., evaluate the simple-spec extrapolation only over the same support set used by the robust aggregator. This is the apples-to-apples comparison number for tables.

## 8. Validation: the degenerate-$v$ test

If $|V| = 1$ (everyone in one cluster), then $\beta(v)$ collapses to a single scalar identical to the simple-spec $\Delta_{\underline d_0}$ (up to the SE clustering choice). The robust GMM then produces:
- $\hat\phi^{\text{robust}} = \hat\phi^{\text{simple}}$ to numerical precision.
- $\hat\Delta_{\underline d}^{\text{robust}}$ matching $\hat\Delta_{\underline d}^{\text{simple}}$ for every switcher trajectory.

This is the cheapest correctness test for `run_grc_robust`. To implement: `gen v_one = 1`, then `run_grc_robust, vindex(v_one) ...`. The estimates must match `run_grc` to 6 decimals. Reproduce on TZA in P1 verification gate.

## 9. Comparison to VV's `robust.do` choices (revised 2026-04-24)

| Element | VV's robust.do | CKT `run_grc_robust` (retired) | CKT `run_grc_robust_vv` (primary) |
|---|---|---|---|
| First-stage projection | Chamberlain (1992) `areg lyield w1-wN, absorb(hhid_hybrid)` | Skipped --- subsumed by `run_grc`'s joint GMM. | Skipped --- trajectory pooling already aggregates worker-level info. |
| Role of cluster structure | Instruments: `hybrid_per` regressed on `i.vil` among switchers; residuals are optimal instruments for $\phi$. | **Parameters:** $\|V\|-1$ cluster dummies times $D_{it}$ as free GMM parameters. | **Instruments:** `switcher_s_choice` regressed on `i.vfirst` among `switcher_s = 1`; residuals replace raw `switcher_s_choice` in the instrument list. |
| Parameter count | phi + gammas + ATE parameters | phi + mu_d + Delta_base + kappa + gammas + $\|V\|-1$ beta_dev | phi + mu_d + Delta_base + kappa + gammas (same as simple spec) |
| Finite-sample identification | Stable (VV shows in Section F) | **Fails** for $\|V\| \in \{22, 26, 29\}$: two local minima, ridge-flat objective | Stable on TZA/CHN/IDN (5-start sensitivity ranges $\leq 0.017$) |
| Slope estimation | Joint GMM with two instrument blocks | Single GMM call extending `run_grc` | Single GMM call; demeaned instruments replace raw ones |
| GMM settings | `winitial(unadjusted, independent), onestep, vce(cluster vil)` | Same settings (updated 2026-04-24) | Same settings |
| LCA-overid test | Wald on $\eta_t$ from augmented GMM (`Table1/Code/nrobust.do`) | Same approach (would be `run_grc_overid`, P3) | Same approach, same augmented moments --- just different baseline instrument set |

**Why `run_grc_robust` fails in finite sample.** Asymptotically, the extra cluster-FE parameters are identified by within-cluster treatment variation --- exactly the variation VV uses for $\phi$. In finite sample with few clusters, the cluster-FE parameters and $\phi$ compete for the same variation, and onestep GMM with rank-deficient cluster-robust $W_2$ lets the optimizer drift along a near-flat ridge. The first local minimum reached depends on the initial value.

**Why `run_grc_robust_vv` works.** Only $\phi$ and the existing `run_grc` parameters need to be identified. The cluster structure enters exclusively in the instrument construction, which does not add parameters to the GMM. $W_2$ is still rank-deficient but the objective is strictly convex in $\phi$ (within the usual identification conditions), so the optimizer converges regardless of starting value.

## 10. Sign-off

- [x] **Derivation approved.** Reviewer: Emilia Date: 2026-04-23
- [x] **`run_grc_robust` skeleton (§4) translates correctly into Stata.**
- [x] **Degenerate-$v$ test (§8) is part of P1 verification gate.**
- [x] **Q5 (always-urban $\phi^U$) deferred to P2 per §6.**

---

**Reminder for the user:**
- Q7 and Q8 from the implementation-findings memo (single-vs-multi instrument blocks; GMM weighting choice) still need a decision before P3 code is written.
- Plan §P0 §2.3 (bootstrap default), §P3 §5.1 (`run_grc_overid` skeleton), and §P3 robust-spec text need editing per the implementation-findings memo §7.
