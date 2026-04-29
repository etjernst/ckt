# Spec: extend the LCA inversion CI to $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$

**Date:** 2026-04-29
**Author drafting:** the lca-inversion session.
**Status:** revised 2026-04-29 after econometrics-critic review (full report at [`quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md)).
Ready for implementation.
**Goal:** extend [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) so that the same grid-test-inversion machinery that produces a CI for $\phi$ also produces CIs for the trajectory-aggregate returns $\Delta_{d_N}$ (never-movers), $\Delta_{\text{avg}}$ (switcher-share-weighted average), and $\Delta_{d_T}$ (always-movers).

This spec documents the math, the mapping from canonical Stata `nlcom` formulas to the auxiliary OLS coefficients used by the inversion, and the inversion procedure for each parameter.
The reviewer should check the algebra against (a) the paper's restricted-GRC equation (`paper/main.tex`, eq.\ `eq:restricted-GRC`, around line 367) and (b) the Stata `nlcom` formulas in `RP7/scripts/0_programs.do` (lines 1759--1813 within `run_grc`).

---

## 1. Notation

From the paper's restricted-GRC equation and Stata's `gmm` block:

- $\mu_{\underline d}$: average rural consumption for trajectory $\underline d$.
For switchers, identified from the panel's $D_{it} = 0$ observations.
For never-movers $d_N$, identified directly (they are observed only at $D_{it} = 0$).
For always-movers $d_T$, **not** identified from the data alone (they are observed only at $D_{it} = 1$).
- $\Delta_{\underline d}$: average return to urban location for trajectory $\underline d$.
Identified for switchers from within-person variation; identified by extrapolation under LCA for $d_N$ and $d_T$.
- $\beta \equiv \Delta_{d_0}$ where $d_0$ is the baseline switcher (`base` in Stata).
- $\phi$: LCA slope, the parameter the existing inversion CIs target.
- $\kappa_{d_T} \equiv \mu_{d_T} + \Delta_{d_T}$: observed urban mean for always-movers (paper line 376).
This is what is identified directly from the data on always-movers.

**Important notation mismatch:** Stata's `_b[kappa]` in `0_programs.do` is **not** the paper's $\kappa_{d_T}$.
Stata's `_b[kappa]` is the GMM's free parameter representing $\mu_{d_T}$, the unobserved rural counterfactual for always-movers.
The GMM identifies it via the always-mover moment that fits the observed mean $\kappa_{d_T} = \mu_{d_T} + \Delta_{d_T}$ under the LCA structure $\Delta_{d_T} = \beta + \phi(\mu_{d_T} - \mu_{d_0})$.
The Stata `nlcom` formulas use Stata's `_b[kappa]` (i.e., $\mu_{d_T}$) in the LCA extrapolation, which is why they are linear in $\phi$ given the GMM estimates.

The auxiliary OLS in [`lca_inversion.py:fit_auxiliary_ols`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) does not estimate Stata's `_b[kappa]`.
It estimates only trajectory means and switcher returns:

| OLS coefficient | Object identified |
|---|---|
| $\hat\alpha_{d_N}$ | $\mu_{d_N}$ (rural mean of never-movers, observed) |
| $\hat\alpha_s$ for switcher $s$ | $\mu_s$ (rural mean of switcher trajectory $s$, observed) |
| $\hat\alpha_{d_T}$ | $\kappa_{d_T} = \mu_{d_T} + \Delta_{d_T}$ (observed urban mean of always-movers) |
| $\hat\beta_s$ for switcher $s$ | $\Delta_s$ (return for switcher trajectory $s$) |

Note again: $\hat\alpha_{d_T}$ in the auxiliary OLS is $\kappa_{d_T}$ (observed urban mean), **not** Stata's `_b[kappa] = ` $\mu_{d_T}$.
The inversion procedures below carry this distinction carefully.

## 2. Canonical Stata formulas (from `0_programs.do`)

From `run_grc`, lines 1761--1811 (and mirrored in `run_grc_onestep`, `run_grc_robust_vv`, etc.):

**Delta_never:**

```
nlcom (Delta_never: _b[Delta_base:_cons] + (_b[phi:_cons] *
        (_b[mu:never] - _b[mu:switcher_`base'])))
```

That is,

$$\Delta_{d_N} = \beta + \phi \cdot (\mu_{d_N} - \mu_{d_0}). \qquad (1)$$

**Delta_always:**

```
nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] *
        (_b[kappa:_cons] - _b[mu:switcher_`base'])))
```

Using Stata's `_b[kappa] = ` $\mu_{d_T}$:

$$\Delta_{d_T} = \beta + \phi \cdot (\mu_{d_T} - \mu_{d_0}). \qquad (2)$$

This is linear in $\phi$ because $\mu_{d_T}$ is a free GMM parameter.
Auxiliary-OLS-only inversion does not have this luxury (see Section 5 below).

**Delta_avg:**

```
local Delta_avg_nlcom ""
foreach s of numlist $switchers {
    sum 1.switcher_`s' if e(sample)
    local num_`s' = r(mean)
    Delta_avg_nlcom += num_`s' * (_b[Delta_base:_cons] +
        (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))
}
nlcom (Delta_avg: `Delta_avg_nlcom')
```

Where `num_s` is the sample share of trajectory $s$ over the GMM estimation sample.
Equivalently,

$$\Delta_{\text{avg}} = \sum_{s \in \mathcal S} \pi_s \, [\beta + \phi \cdot (\mu_s - \mu_{d_0})] = \beta + \phi \cdot \sum_{s \in \mathcal S} \pi_s (\mu_s - \mu_{d_0}). \qquad (3)$$

The sum is over **switchers only** (`$switchers` excludes never and always); $\pi_s = N_s / \sum_{s' \in \mathcal S} N_{s'}$ is the within-switcher trajectory share.
This is linear in $\phi$.

## 3. Mapping to auxiliary OLS coefficients

Using the table in Section 1, the GMM-side formulas map as:

| GMM expression | Auxiliary-OLS expression |
|---|---|
| $\mu_{d_N}$ | $\hat\alpha_{d_N}$ |
| $\mu_s$ (switcher) | $\hat\alpha_s$ |
| $\mu_{d_0}$ | $\hat\alpha_{d_0}$ (a.k.a.\ $\hat\alpha_{\text{base}}$) |
| $\beta = \Delta_{d_0}$ | $\hat\beta_{d_0}$ (a.k.a.\ $\hat\beta_{\text{base}}$) |
| $\mu_{d_T}$ (Stata `_b[kappa]`) | not directly estimated; recoverable via $\hat\alpha_{d_T} = \kappa_{d_T}$ and $\Delta_{d_T}$ |

Substituting:

$$\Delta_{d_N}(\phi, b) = \hat\beta_{\text{base}} + \phi \cdot (\hat\alpha_{d_N} - \hat\alpha_{\text{base}}) \tag{1$'$}$$

$$\Delta_{\text{avg}}(\phi, b) = \hat\beta_{\text{base}} + \phi \cdot \sum_{s \in \mathcal S} \pi_s (\hat\alpha_s - \hat\alpha_{\text{base}}) \tag{3$'$}$$

Both linear in $\phi$.

For $\Delta_{d_T}$, Stata's $\mu_{d_T}$ is unavailable.
We have $\hat\alpha_{d_T} \approx \kappa_{d_T} = \mu_{d_T} + \Delta_{d_T}$ and the LCA identity (2):
$\Delta_{d_T} = \beta + \phi(\mu_{d_T} - \mu_{d_0})$.
Eliminate $\mu_{d_T}$:

$$\hat\alpha_{d_T} = \mu_{d_T} + \Delta_{d_T} = \mu_{d_T} + \beta + \phi(\mu_{d_T} - \mu_{d_0}) = (1+\phi)\mu_{d_T} + \beta - \phi \mu_{d_0}.$$

Solve for $\mu_{d_T}$ in terms of OLS coefficients and $\phi$:

$$\mu_{d_T}(\phi, b) = \frac{\hat\alpha_{d_T} - \hat\beta_{\text{base}} + \phi \hat\alpha_{\text{base}}}{1 + \phi} \quad (\phi \ne -1).$$

Substitute back into the LCA formula:

$$\Delta_{d_T}(\phi, b) = \hat\alpha_{d_T} - \mu_{d_T}(\phi, b) = \frac{\hat\beta_{\text{base}} + \phi (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})}{1 + \phi} \quad (\phi \ne -1). \tag{2$'$}$$

Nonlinear in $\phi$.
Singular at $\phi = -1$.

## 4. Inversion procedure: linear cases ($\Delta_{d_N}$, $\Delta_{\text{avg}}$)

Given $(1')$ and $(3')$, both have the form

$$\Delta_X(\phi, b) = c_0(b) + \phi \cdot c_1(b),$$

where $c_0(b) = \hat\beta_{\text{base}}$ and $c_1$ is either $\hat\alpha_{d_N} - \hat\alpha_{\text{base}}$ (for $\Delta_{d_N}$) or $\sum_s \pi_s (\hat\alpha_s - \hat\alpha_{\text{base}})$ (for $\Delta_{\text{avg}}$).

For each candidate value $\delta^*$:

$$\phi^*(\delta^*, b) = \frac{\delta^* - c_0(b)}{c_1(b)} \quad (c_1 \ne 0).$$

The model is consistent with $\delta^*$ if and only if (a) the LCA restrictions hold at $\phi^*$, and (b) the implicit identity $\delta^* = c_0 + \phi^* c_1$ holds.
Since $\phi^*$ is defined to satisfy (b) exactly, only the LCA restrictions remain to test.

**Test statistic.** Let $g(b, \phi) \in \mathbb R^{J_R}$ be the existing LCA restriction vector,

$$g_s(b, \phi) = (\hat\beta_s - \hat\beta_{\text{base}}) - \phi (\hat\alpha_s - \hat\alpha_{\text{base}}), \quad s \in \mathcal S \setminus \{d_0\}.$$

Define $\tilde g(b; \delta^*) \equiv g(b, \phi^*(\delta^*, b))$.
Under the null $\Delta_X = \delta^*$, $\sqrt n \tilde g \sim N(0, V_{\tilde g})$ where $V_{\tilde g} = \nabla \tilde g \cdot V_b \cdot (\nabla \tilde g)^\top$ and $\nabla \tilde g = \partial g/\partial b + (\partial g/\partial \phi)(\partial \phi^*/\partial b)$.

Wald: $W(\delta^*) = n \tilde g^\top V_{\tilde g}^{-1} \tilde g$.
p-value from $\chi^2_{J_R}$.
CI = $\{\delta^* : W(\delta^*) \le \chi^2_{J_R, 1-\alpha}\}$ on a grid.

**Implementation:** parallels the existing `grid_lca_inversion`.
At each $\delta^*$ in a grid, compute $\phi^*$, build $\tilde g$, compute $\nabla \tilde g$ analytically (the chain rule is straightforward for these linear cases), form $V_{\tilde g}$, compute the Wald.
Same dof as the $\phi$ inversion ($J_R$).

**Edge cases:**

- $|c_1(b)| < \epsilon$ (numerical tolerance, not exact zero): $\Delta_X$ is approximately invariant in $\phi$ at the OLS estimates.
The CI is the singleton $\{\hat\beta_{\text{base}}\}$ if the LCA restrictions hold, empty otherwise.
Implementation should detect this case and return a degenerate CI with a warning.
For $\Delta_{d_N}$ this means never-movers have the same rural mean as the baseline switcher; possible but unlikely.
For $\Delta_{\text{avg}}$ this means the share-weighted average switcher mean equals the baseline switcher mean; even more unlikely by construction.
- $J_R = 1$ (one non-base switcher in addition to the base, so two switchers total): the joint Wald has $\chi^2_1$ distribution.
The existing $\phi$ inversion handles this; the same applies to the new inversions.
- $J_R = 0$ (only the base switcher kept after `drop_sparse_switchers`): the LCA restriction set is empty.
The auxiliary OLS is exactly identified; any $\phi^*$ satisfies the (empty) restrictions; the CI is $(-\infty, \infty)$.
The current $\phi$ inversion already raises in this case; mirror that behavior.

## 5. Inversion procedure: nonlinear case ($\Delta_{d_T}$)

From $(2')$, $\Delta_{d_T}(\phi, b) = (\hat\beta_{\text{base}} + \phi(\hat\alpha_{d_T} - \hat\alpha_{\text{base}}))/(1+\phi)$.

Solving for $\phi^*$ given a candidate $\delta_T^*$:

$$\delta_T^* (1+\phi^*) = \hat\beta_{\text{base}} + \phi^* (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})$$
$$\delta_T^* + \delta_T^* \phi^* = \hat\beta_{\text{base}} + \phi^* (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})$$
$$\phi^* (\delta_T^* - (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})) = \hat\beta_{\text{base}} - \delta_T^*$$

$$\phi^*(\delta_T^*, b) = \frac{\hat\beta_{\text{base}} - \delta_T^*}{\delta_T^* - (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})} = -\frac{\delta_T^* - \hat\beta_{\text{base}}}{\delta_T^* - (\hat\alpha_{d_T} - \hat\alpha_{\text{base}})}.$$

The mapping $\delta_T^* \mapsto \phi^*$ is a Mobius transform; one-to-one away from the singularity $\delta_T^* = \hat\alpha_{d_T} - \hat\alpha_{\text{base}}$ (where $\phi^* = \pm \infty$, corresponding to the model's $1+\phi=0$ singularity in the other direction).

**Test statistic.** Same shape as the linear case: $\tilde g(b; \delta_T^*) = g(b, \phi^*(\delta_T^*, b))$, Wald with $\chi^2_{J_R}$.
The Jacobian $\partial \phi^*/\partial b$ now involves $\hat\alpha_{d_T}$ as well, computed by direct differentiation of the Mobius formula.

**Edge cases:**

- $\delta_T^* = \hat\alpha_{d_T} - \hat\alpha_{\text{base}}$: $\phi^* \to \pm \infty$; the LCA restrictions cannot be satisfied unless they happen to hold in the limit (they do if $\hat\beta_s - \hat\beta_{\text{base}} = $ const $\cdot (\hat\alpha_s - \hat\alpha_{\text{base}})$ asymptotically, which is degenerate).
Implementation should detect proximity to this singularity (numerical tolerance, not exact zero) and skip the grid point with a flag.
- Grid coverage of $\delta_T^*$: since the mapping is Mobius, a uniform grid in $\delta_T^*$ does not correspond to a uniform grid in $\phi^*$.
The grid should either (a) cover a wide range of $\delta_T^*$ uniformly and accept the nonuniform $\phi^*$ coverage, or (b) start from a uniform $\phi^*$ grid and map forward to $\delta_T^*$ values.
Option (b) is cleaner and reuses the existing $\phi^*$ grid.
- **Inversion CI for $\phi$ contains $-1$: report a multi-island CI honestly.**
This is the case for IDN/cons/urban/unb covs_all, where the 95% inversion CI for $\phi$ is $[-1.23, -0.01]$.
The Mobius transform $\Delta_{d_T}(\phi, b) = (\hat\beta_{\text{base}} + \phi(\hat\alpha_{d_T} - \hat\alpha_{\text{base}}))/(1+\phi)$ has a vertical asymptote at $\phi = -1$, so the $\Delta_{d_T}$ inversion CI splits into two intervals separated by the singularity.
The implementation should report both branches as a union of intervals, not paper over the gap.
The structural meaning of $\phi = -1$ is $b_U = 0$ (the urban-skill returns vanish in the LCA decomposition $\phi \equiv (b_U - b_R)/b_R$); near this point the always-treated counterfactual is genuinely unidentified.
The paper writeup should mention this when reporting any $\Delta_{d_T}$ CI whose $\phi$-image crosses $-1$.

**Test statistic choice: formal Wald, not Mobius image of the $\phi$ CI.**
A tempting shortcut is to map the existing $\phi$ inversion CI directly through $(2')$, treating $\hat\alpha_{d_T}$ and $\hat\beta_{\text{base}}$ as known.
This is anti-conservative: it ignores the sampling variance of those OLS coefficients in the conversion and understates CI width.
Implement the formal Wald-with-delta-method described in Section 4 (extended for the Mobius nonlinearity), which propagates the joint variance of all relevant OLS coefficients through the transform.
The two methods give the same qualitative answer when the $\phi$ CI crosses $-1$ (both produce unbounded sets), so the formal Wald loses nothing in writeup honesty while gaining finite-sample validity.

## 6. Implementation sketch

New module `delta_inversion.py` next to `lca_inversion.py`.
Three new functions, paralleling `grid_lca_inversion`:

```python
def grid_delta_never_inversion(fit, switchers_kept, base, never_traj,
                                delta_grid, type_one=0.05) -> tuple[pd.DataFrame, float, float]:
    ...

def grid_delta_avg_inversion(fit, switchers_kept, base, switcher_shares,
                              delta_grid, type_one=0.05) -> tuple[pd.DataFrame, float, float]:
    ...

def grid_delta_always_inversion(fit, switchers_kept, base, always_traj,
                                 delta_grid, type_one=0.05) -> tuple[pd.DataFrame, float, float]:
    ...
```

Each returns `(curve_df, ci_lo, ci_hi)` mirroring the existing `grid_lca_inversion` interface.
Curve DataFrame columns: `delta`, `phi_at_delta` (the implied $\phi^*$), `wald`, `p_value`.

The `find_islands` and `summary_curve_stats` helpers already in `lca_inversion.py` apply unchanged (operate on any `(parameter, p_value)` curve).
The `postprocess_islands.py` runner extends with three new parquets per (country, spec): one each for $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$.

The runner `run_all_countries_inversion.py` extends to compute and report the new CIs alongside the existing $\phi$ CI.
The `lca_inversion_three_countries.md` table grows from one to four CI rows per country/spec.

**Switcher shares for $\Delta_{\text{avg}}$:** use the **same sample** for both the share weights $\pi_s$ and the auxiliary OLS that supplies $\hat\alpha_s$ and $\hat\beta_{\text{base}}$.
Concretely: compute $\pi_s$ from the auxiliary-OLS sample restricted to switcher trajectories: `pi_s = (df[traj] == s).sum() / (df[traj].isin(switchers)).sum()`.
The Stata code computes shares from `e(sample)` (the GMM sample), which may differ slightly from the auxiliary-OLS sample if covariate-missingness rules diverge.
Validation step 1 below catches any wedge by reproducing Stata's `nlcom` point estimate at $\hat\phi$; if the auxiliary-OLS shares fail to reproduce it, fall back to GMM-sample shares and document the deviation.

## 7. Validation plan

1. **Point-estimate match (precondition gate, not verify-after).** Before any inversion CI is computed for a paper table, verify that $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ at $\hat\phi$ from the GMM (computed via $(1')$, $(3')$, $(2')$ with the auxiliary OLS coefficients) reproduce Stata's published `nlcom` point estimates.
For $\Delta_{d_N}$ and $\Delta_{\text{avg}}$, expect near-exact match (small differences only from auxiliary-OLS-vs-GMM coefficient differences, likely sub-percent at IDN's $N$).
For $\Delta_{d_T}$, expect a similar match because the GMM's $\mu_{d_T}$ is derivable from the same identity used in $(2')$ at the GMM's $\hat\phi$.
**This is the gate that resolves the auxiliary-OLS-vs-GMM identification question.**
If it fails, the controls partialling differs between the two implementations (e.g., the `unbalanced` and `unbalanced_choice` indicators interact with always-trajectory selection differently in OLS vs GMM), and the spec needs to be revisited before proceeding.
Do not report any inversion CI for a parameter whose point-estimate match fails this gate.
2. **CI coverage on synthetic data.** Same T=2 synthesizer as `synth_t2_validation.py`; check that the new inversion CIs cover the true $\Delta$ at the nominal rate over $R = 100$ replications.
3. **Cross-check against the GMM `nlcom` SE-based CI.** The two should agree only when $\phi$ is well-identified; under weak ID (the IDN covs_all case), the inversion CI should be wider for $\Delta_{d_N}$ and $\Delta_{\text{avg}}$, and may be a union of two intervals for $\Delta_{d_T}$ if the $\phi$ CI crosses $-1$.
4. **CHN check.** With CHN's empty $\phi$ inversion CI for every spec, the $\Delta_X$ inversion CIs should also be empty (image of an empty set under any map).
Implementation must propagate this correctly.

## 8. Decisions adopted after reviewer feedback

The 2026-04-29 econometrics-critic review (full report at [`quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md)) raised several questions that this spec now resolves:

- **Auxiliary OLS vs GMM identification of $\kappa_{d_T}$.** Resolved empirically by validation step 1 (now a precondition gate).
If the OLS-derived $\Delta_X(\hat\phi, b)$ reproduces Stata's `nlcom` point estimate, the controls partialling is aligned and the inversion proceeds.
If not, the spec is revisited.
- **Mobius image vs formal Wald for $\Delta_{d_T}$.** Formal Wald, per Section 5.
The Mobius image is anti-conservative (ignores variance of $\hat\alpha_{d_T}$ and $\hat\beta_{\text{base}}$).
- **$\Delta_{\text{avg}}$ sample / share weights.** Same sample for both; default to the auxiliary-OLS sample, fall back to GMM sample only if validation step 1 demands it.
See Section 6.
- **Singularity at $\phi = -1$ for $\Delta_{d_T}$.** Multi-island CI reported as a union of intervals separated by the singularity, with a textual flag in the paper writeup explaining the structural meaning ($b_U = 0$).
See Section 5.

One remaining open question for implementation:

- **Numerical tolerance for $|c_1(b)| < \epsilon$.** What value of $\epsilon$ separates "genuinely degenerate $\Delta_X$ in $\phi$" from numerical noise?
At IDN's sample sizes the OLS coefficient SEs are $O(0.01)$, so $\epsilon \approx 10^{-3}$ would catch any real degeneracy without flagging healthy cases.
Decide during implementation; the choice is unlikely to bite in practice given how distinct trajectory means are.

## 9. Cross-references

- Paper restricted-GRC equation: `paper/main.tex` line 367 (eq.\ `eq:restricted-GRC`); always-mover identification subsection at line 376.
- Stata `nlcom` formulas: `RP7/scripts/0_programs.do` lines 1759--1813 (within `run_grc`); same formulas mirrored at lines 1897--1940 (`run_grc_onestep`), 2006--2036 (`run_grc_balanced`), 2279--2334 (`run_grc_robust_vv`), 2525--2570 (`run_grc_robust_vv_onestep`).
- Auxiliary OLS: [`lca_inversion.py:fit_auxiliary_ols`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) lines 83--135.
- Existing $\phi$ inversion: [`lca_inversion.py:grid_lca_inversion`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) lines 138--193.
- Published $\phi$ inversion CIs: [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md).

## 10. Estimated implementation cost

After reviewer sign-off on the math:

- $\Delta_{d_N}$: 0.5 days (simplest; near-clone of `grid_lca_inversion`).
- $\Delta_{\text{avg}}$: 0.5 days (slightly more bookkeeping for the share-weighted sum).
- $\Delta_{d_T}$: 1 day (Mobius, singularity handling, decision on the approximation framing).
- Validation harness (synthetic + cross-check against Stata `nlcom`): 0.5 days.
- Runner extension and table updates: 0.5 days.
- **Total:** ~3 days.

Lower bound assumes no surprises during validation; if point-estimate match against Stata fails for any of the three, expect another 0.5--1 days to debug.
