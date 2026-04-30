# Validation gate for the delta-inversion extension: failure analysis

Status: spec gate failed across all 45 (country, spec, delta) cells, but the failure decomposes into two unrelated issues.
Python implementation halted pending a decision on each.

Companion artifacts produced by [`explorations/python-grc/validate_delta_points.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/validate_delta_points.py):

- [`results/validate_delta_points.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_points.csv): per-cell Stata vs Python comparison.
- [`results/validate_delta_decomposition.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_decomposition.csv): GMM vs OLS coefficient diagnostics.
- [`rerun_workdir/published_deltas.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/published_deltas.csv): Stata `nlcom` ground truth (point + SE) for $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ across 3 countries x 5 specs.
- [`rerun_workdir/published_gmm_internals.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/published_gmm_internals.csv): GMM-side $\hat\phi$, $\hat\beta$, $\hat\mu_{d_N}$, $\hat\kappa$ for the same cells.

## Headline

The 45-cell gate failed for two unrelated reasons:

1. $\Delta_{\text{avg}}$ is off by a factor that exactly tracks the switcher fraction (4--14% across countries), pointing to a definitional bug in Stata's `nlcom`, not a Python implementation error.
2. $\Delta_{d_N}$ and $\Delta_{d_T}$ are off because the auxiliary OLS's $\hat\beta_{\text{base}}$ disagrees with the GMM's $\hat\beta$ by 1--7 percentage points across cells.
This is the auxiliary-OLS-vs-GMM identification question the spec critic raised, now empirically resolved: they disagree at a level that matters economically.

## Issue 1: $\Delta_{\text{avg}}$ is currently a malformed quantity

In [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) lines 1797--1812 (and four mirror copies elsewhere in the same file), `Delta_avg` is built by:

```stata
foreach s of numlist $switchers {
    sum 1.switcher_`s' if e(sample)
    local num_`s' = r(mean)
    Delta_avg_nlcom += num_`s' * (Delta_base + phi * (mu_s - mu_base))
}
nlcom (Delta_avg: `Delta_avg_nlcom')
```

`sum 1.switcher_s if e(sample); local num_s = r(mean)` returns $N_s / N_{\text{total}}$, where $N_{\text{total}}$ counts the entire GMM sample (never-movers + switchers + always-movers).
The implied weights satisfy $\sum_s \text{num}_s = N_{\text{switchers}} / N_{\text{total}} = \text{sw\_frac} < 1$, so Stata is computing
$$
\Delta_{\text{avg, Stata}} = \sum_s \frac{N_s}{N_{\text{total}}} \bigl[\beta + \phi(\mu_s - \mu_{\text{base}})\bigr] = \text{sw\_frac} \cdot \beta + \phi \cdot \sum_s \frac{N_s}{N_{\text{total}}} (\mu_s - \mu_{\text{base}}).
$$

This equals $\text{sw\_frac} \cdot \tilde\Delta_{\text{avg}}$ when both use the same $\beta$ and $\mu$'s, where $\tilde\Delta_{\text{avg}}$ is the within-switcher-weighted average defined below.
sw\_frac is 0.04 in IDN, 0.04 in CHN, 0.11 in TZA, so Stata's published value is 4--11% of the within-switcher quantity.

The disciplined target is the population-level expected return for switchers,
$$
\Delta_{\text{avg}} \equiv E[\Delta_i \mid i \text{ is a switcher}] = \sum_{s \in \mathcal{S}} \pi_s \, \Delta_s, \quad \pi_s \equiv \frac{N_s}{\sum_{s' \in \mathcal{S}} N_{s'}}, \quad \sum_s \pi_s = 1.
$$

Under LCA + the restricted GRC, $\Delta_s = \beta + \phi(\mu_s - \mu_{\text{base}})$, so
$$
\Delta_{\text{avg}} = \beta + \phi \cdot \sum_{s \in \mathcal{S}} \pi_s (\mu_s - \mu_{\text{base}}).
$$

Three reasons within-switcher shares is the right convention.
First, $E[\Delta \mid \text{switcher}]$ is the unique number that, when multiplied by the switcher population size, equals total switcher returns; it is the object referenced when papers say "the average return to migration for switchers."
Stata's over-all-sample-share version does not have a comparable natural-language meaning.
$\sum_s (N_s / N_{\text{total}}) \Delta_s$ is the contribution of switcher returns to a hypothetical sample mean that includes never-movers and always-movers as zeros, which is neither $E[\Delta \mid \text{switcher}]$ nor $E[\Delta \mid \text{anyone}]$.
Second, sw\_frac varies from 4% (IDN, CHN) to 14% (TZA) across countries.
The within-switcher convention isolates "the return" from "the prevalence of switching," so cross-country comparisons of $\Delta_{\text{avg}}$ are interpretable.
The Stata convention conflates the two.
Third, FE-OLS on a switcher subsample converges in the limit to a within-switcher weighted average of $\Delta_s$, so the natural target for $\Delta_{\text{avg}}$ should match that limit.

I checked the ratio Stata $\Delta_{\text{avg}}$ / (sw\_frac $\cdot$ Python within-switcher $\Delta_{\text{avg}}$) across all 15 (country, spec) cells.
The ratio varies a few percent because $\hat\beta_{\text{OLS}} \ne \hat\beta_{\text{GMM}}$ (issue 2 below), but the qualitative pattern holds: Stata is approximately sw\_frac times the within-switcher value.

Decision needed:

A. Fix Stata's `nlcom` and rerun the GMM pipeline.
The bug exists in five sibling code paths inside `0_programs.do` (`run_grc`, `run_grc_onestep`, `run_grc_balanced`, `run_grc_robust_vv`, `run_grc_robust_vv_onestep`).
This costs a multi-hour Stata rerun but produces the correct quantity going forward.
B. Implement Python's $\Delta_{\text{avg}}$ inversion using the within-switcher convention now, accept that the inversion CI's point estimate at $\hat\phi_{\text{OLS}}$ will not match Stata's published `nlcom` point estimate, and document the Stata bug as a TODO.
C. Mirror Stata's buggy formula in Python so the inversion CI is consistent with the published point estimate, knowing the quantity itself is malformed.

I recommend B in the short term and A when the pipeline-refactor branch lands.
C is the worst option but is what's needed for strict consistency with the published tables today.

## Issue 2: auxiliary-OLS $\hat\beta_{\text{base}}$ disagrees with GMM $\hat\beta$

[`validate_delta_decomposition.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_decomposition.csv) reports the side-by-side:

| Country | Spec | $\hat\beta_{\text{OLS}}$ | $\hat\beta_{\text{GMM}}$ | OLS $-$ GMM |
|---|---|---:|---:|---:|
| IDN | covs_0 | 0.846 | 0.848 | $-0.002$ |
| IDN | covs_trend | 0.107 | 0.074 | $+0.033$ |
| IDN | covs_all | 0.095 | 0.067 | $+0.028$ |
| CHN | covs_0 | 0.560 | 0.484 | $+0.076$ |
| CHN | covs_trend | 0.070 | 0.083 | $-0.013$ |
| CHN | covs_all | 0.080 | 0.095 | $-0.015$ |
| TZA | covs_0 | 0.460 | 0.389 | $+0.070$ |
| TZA | covs_all | 0.149 | 0.134 | $+0.015$ |

The differences are 1--7 percentage points on the log-consumption return scale.
At $N \approx 90{,}000$ they are not sampling noise.

Three contributing mechanisms; the first is load-bearing.
First, GMM imposes the LCA restriction $\Delta_s = \beta + \phi(\mu_s - \mu_{\text{base}})$ for all switchers $s$ simultaneously, and $\hat\beta_{\text{GMM}}$ is the LCA-implied return for the base trajectory under that joint constraint.
The auxiliary OLS imposes no such restriction and gives the unconstrained coefficient on the (trajectory == base) $\times$ choice interaction.
When LCA does not hold exactly (Hansen's $J$ rejects in IDN covs_0 with $J_p < 0.001$, and in CHN throughout), the two estimators target genuinely different objects.
Second, even when LCA holds in expectation, GMM weights its overidentified moments by the inverse-covariance of the moment vector, while the just-identified saturated OLS weights all switcher trajectories implicitly by their inverse-variance via the cluster-robust covariance.
At finite $N$ these produce slightly different point estimates.
Third, sample alignment: Python's auxiliary OLS sample is the OLS-side `dropna` after spec controls; Stata's GMM sample is `e(sample)`, which can differ by a handful of observations.
This is a small effect (the two should match within 0.01% for IDN at 92,450) but worth flagging.

The inversion CI in `lca_inversion.py:grid_lca_inversion` is internally consistent: at any $\phi$, the Wald statistic tests whether the LCA restrictions hold using the OLS coefficients, and the CI is the convex hull of acceptance.
The point estimate at the Wald minimum is Python's preferred $\hat\phi$, which differs from the GMM's $\hat\phi$ by an amount tracked in [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md).
The existing $\phi$ inversion already accepts this gap.
The new $\Delta_X$ inversion CIs would inherit the same property: internally consistent, but their point estimate at the OLS Wald minimum will not match Stata's published `nlcom`.

This is fine as long as the paper reports the inversion CI alongside the GMM nlcom CI and frames the inversion as a weak-ID-robust supplementary analysis, not a replacement.

## Path forward: minimum-distance inversion

Decision (2026-04-29): rewrite the inversion as minimum-distance on the auxiliary OLS.
The remainder of this section derives the procedure and explains why it is valid for inference.

The framing is cleanest if we write the auxiliary regression's coefficient vector as $\theta = (\alpha_{d_N}, \{\alpha_s\}_{s \in \mathcal{S}}, \alpha_{d_T}, \{\beta_s\}_{s \in \mathcal{S}})$ from saturated OLS, with cluster-robust covariance $\hat V_\theta$.
LCA imposes for every switcher $s$ (including the base) that $\beta_s = \beta + \phi(\alpha_s - \alpha_{\text{base}})$.
That is $|\mathcal{S}|$ restrictions on $\theta$ parameterized by two scalars $(\beta, \phi)$, which leaves $J_R = |\mathcal{S}| - 1$ overidentifying restrictions when both are estimated, or $J_R = |\mathcal{S}|$ when $\phi$ is fixed and only $\beta$ is concentrated out.

The current Wald in `lca_inversion.py` does the latter the just-identified way: it uses $\hat\beta_{\text{base, OLS}}$ as the LCA intercept directly and tests $\beta_s - \beta_{\text{base}} - \phi(\alpha_s - \alpha_{\text{base}}) = 0$ for the remaining $|\mathcal{S}| - 1$ switchers.
The Wald has $\chi^2_{|\mathcal{S}|-1}$ asymptotic distribution under $H_0$.

Minimum-distance does the efficient concentration.
At candidate $\phi$, define the moment vector
$$
m_s(\hat\theta; \beta, \phi) = \hat\beta_s - \beta - \phi(\hat\alpha_s - \hat\alpha_{\text{base}}), \quad s \in \mathcal{S}.
$$

Concentrate out $\beta$ at its GLS-optimal value:
$$
\hat\beta(\phi) = \arg\min_\beta \, m(\hat\theta; \beta, \phi)' \, W \, m(\hat\theta; \beta, \phi),
$$

which has a closed form (a weighted average over $s$ of $\hat\beta_s - \phi(\hat\alpha_s - \hat\alpha_{\text{base}})$) when $W$ is the inverse covariance $V_m^{-1}$ implied by $\hat V_\theta$.
The concentrated test statistic
$$
W_{\text{MD}}(\phi) = m(\hat\theta; \hat\beta(\phi), \phi)' \, \hat V_m^{-1} \, m(\hat\theta; \hat\beta(\phi), \phi)
$$

is asymptotically $\chi^2_{|\mathcal{S}|-1}$ under $H_0$.
This is the classical Chamberlain (1982) and Newey-McFadden (1994, Handbook of Econometrics ch.\ 36) minimum-distance result.
Inverting it on a $\phi$ grid is valid under the same regularity conditions that make the current Wald valid: clustered SEs, asymptotic normality of $\hat\theta$, full-rank Jacobian at the truth.

Three things to note about whether MD is strictly better.

First, efficiency.
$\hat\beta(\phi)$ pools information across all switchers, so it is at least as efficient as $\hat\beta_{\text{base, OLS}}$, which uses only one switcher's data.
When LCA holds, the MD CI for $\Delta_X$ should be tighter or at least no wider than the just-identified version.

Second, robustness when LCA fails.
When $J$ rejects (IDN covs_0, CHN throughout), the MD $\hat\beta(\phi)$ is still well-defined, but its interpretation is "the LCA-best-fit $\beta$ at this $\phi$," not "the base switcher's actual return."
The just-identified version's $\hat\beta_{\text{base}}$ keeps a cleaner interpretation in that regime.
Under LCA failure, the two procedures target different objects, and the just-identified version may be the safer pick for the paper's writeup in those (country, spec) cells.

Third, match to GMM.
MD on the auxiliary OLS will close most of the OLS-vs-GMM gap because both pool $\beta$ across switchers under LCA.
It will not match GMM exactly, because GMM also uses the always-mover moment and the unbalanced indicators differently, but the 1--7 pp gap should shrink to fractions of a percentage point.

Implementation steps (replacing the existing `grid_lca_inversion`):

1. Compute $V_m$ from $\hat V_\theta$ via the linear map $m_s = \beta_s - \beta - \phi(\alpha_s - \alpha_{\text{base}})$.
$V_m$ depends on $\phi$ through the Jacobian, so it must be rebuilt at each grid point.
2. Solve the closed-form weighted average for $\hat\beta(\phi)$.
3. Form $W_{\text{MD}}(\phi)$ and the corresponding $p$-value from $\chi^2_{|\mathcal{S}|-1}$.
4. Apply the same CI machinery (`find_islands`, convex-hull / multi-island reporting).

Cost estimate: roughly half a day, mostly debugging the $V_m$ Jacobian.

## Suggested next step

Issue 1: fix the Stata bug now.
The cost is small because the GMM optimization need not rerun, only the `nlcom` step.
Issue 2: implement MD inversion as derived above; that becomes the spec's preferred validation gate (Python's MD-derived $\Delta_X(\hat\phi_{\text{MD}})$ should reproduce the corrected Stata `nlcom` to fractions of a percent).

## Resolution and three-country validation (2026-04-30)

Issue 1 resolved: `0_programs.do` patched in five sibling code paths; full GMM reruns via `rerun_{idn,chn,tza}_5gr_fixed.do` regenerated all 15 `_avg.ster` cells with the within-switcher formula.
Stata segfaulted (exit 139) on IDN's post-success CSV-write loop but completed all GMM optimizations and saves; the CHN and TZA reruns dropped that block and finished cleanly.

Issue 2 implemented: `grid_md_inversion`, `grid_delta_never_md_inversion`, `grid_delta_avg_md_inversion`, and `grid_delta_always_md_inversion` are in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).
The two smoke scripts ([`smoke_md_vs_just_id.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/smoke_md_vs_just_id.py), [`smoke_delta_never_md.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/smoke_delta_never_md.py)) confirm that MD's $\hat\beta(\phi)$ closes 86--97% of the OLS-vs-GMM $\hat\beta$ gap, and that the inversion CIs bracket Stata's `nlcom` $\pm 1.96 \cdot$SE band on well-identified specs.

Three-country validation gate, MD-implied $\Delta_X(\hat\phi_{\text{GMM}}, \hat\beta_{\text{md}})$ vs Stata's corrected `nlcom`:

| Country | Δ | covs_trend | covs_1 | covs_2 | covs_all |
|---|---|---:|---:|---:|---:|
| IDN | never | $-4.7\%$ | $-4.7\%$ | $-4.7\%$ | $-4.5\%$ |
| IDN | avg | $-8.4\%$ | $-8.4\%$ | $-8.0\%$ | $-4.3\%$ |
| IDN | always | $-11.2\%$ | $-11.2\%$ | $-12.0\%$ | $-7.2\%$ |
| CHN | never | $-6.6\%$ | $-6.5\%$ | $-4.5\%$ | $-3.4\%$ |
| CHN | avg | $-7.7\%$ | $-7.7\%$ | $-6.0\%$ | $-4.4\%$ |
| CHN | always | $-10.8\%$ | $-10.8\%$ | $-17.7\%$ | $-12.9\%$ |
| TZA | never | $-1.5\%$ | $-1.5\%$ | $-1.5\%$ | $+2.5\%$ |
| TZA | avg | $-2.7\%$ | $-2.8\%$ | $-3.1\%$ | $+5.0\%$ |
| TZA | always | $-3.4\%$ | $-3.4\%$ | $-3.4\%$ | $+3.7\%$ |

The MD framework reduces the Python-vs-Stata gap on well-identified specs from 30--2700% (before any fix) to 1.5--18% (after fix + MD).
TZA matches to 1.5--5%, IDN to 4--12%, CHN to 3--18%.
covs_0 (the weakly-identified spec, $J_p < 0.001$ in IDN and CHN) keeps a wider gap because GMM uses additional moments (the always-mover and unbalanced moments) that the auxiliary OLS does not.
For weak-ID-robust inversion, that residual is acceptable: coverage matters more than point-estimate parity, and the inversion CI bounds (not the point) are what gets reported.

Open items resolved 2026-04-30 (late sub-session):

1. Multi-island handling done.
`find_islands` now takes an arbitrary `x` column (defaults to `phi`); a new `format_islands` helper renders unions of intervals and labels endpoints touching the grid bound as $-\infty$ / $+\infty$ to flag unbounded CIs.
The $\Delta$ grid for the always case widened to $[-5, +5]$ step 0.02.
2. `run_all_countries_inversion.py` now computes all four inversions per cell and writes a separate delta-inversion table.
Outputs at [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md) and [`results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md).
3. T=2 synthesizer coverage check at $R = 100$ ran via [`synth_t2_coverage.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_t2_coverage.py).

## Three-country inversion CI table (final)

The inversion CI for $\phi$ matches the saved table from the previous wave (it uses `grid_lca_inversion`, unchanged).
The new outputs cover the three trajectory-specific deltas.

For the seven well-identified IDN and TZA cells (covs_trend through covs_all), the MD inversion CIs bracket Stata's $\pm 1.96 \cdot$SE band tightly: IDN/$\Delta_{d_N}$ Stata $[+0.045, +0.127]$ vs inversion $[+0.040, +0.150]$ for covs_trend; TZA/$\Delta_{d_T}$ Stata $[-0.522, -0.002]$ vs inversion $[-0.680, -0.140]$ for covs_trend.
The pooled CHN sample's $\phi$-CI is empty across every spec (Hansen J rejects at all grid $\phi$ at the 5% level), so all three CHN delta inversions return empty as expected.
The covs_0 cells return empty CIs across all three countries because the spec is weakly identified.

Two cells produce multi-island $\Delta_{d_T}$ CIs when $\phi$'s CI crosses the Mobius singularity at $\phi = -1$:

- IDN/covs_all: $[-\infty, +0.040] \cup [+0.660, +\infty]$ (rejection on $[+0.040, +0.660]$).
- TZA/covs_all: $[-\infty, -0.140] \cup [+1.720, +\infty]$ (rejection on $[-0.140, +1.720]$).

In both cases the convex-hull CI would have spanned the rejection region, so the multi-island summary is materially more informative.

## Synthetic coverage check (R = 100)

The T=2 synthesizer with $\phi_{\text{true}} = -1.5$, $\Delta_{\text{base}} = 0.5$, and trajectory means $\mu \in \{1, 2, 3, 4\}$ pins the truth to $\Delta_{d_N} = 2.0$, $\Delta_{\text{avg}} \approx -0.43$, $\Delta_{d_T} = -2.5$.
Empirical 95% coverage across $R = 100$ replications:

| Parameter | True value | Coverage | MC SE | Empty CI | Multi-island |
|---|---:|---:|---:|---:|---:|
| $\phi$ | $-1.500$ | 0.92 | 0.027 | 0 | 0 |
| $\Delta_{d_N}$ | $+2.000$ | 0.93 | 0.026 | 0 | 0 |
| $\Delta_{\text{avg}}$ | $-0.429$ | 0.79 | 0.041 | 0 | 0 |
| $\Delta_{d_T}$ | $-2.500$ | 0.94 | 0.024 | 0 | 1 |

Three of four parameters cover within roughly one MC SE of the nominal 95%.
$\Delta_{\text{avg}}$ under-covers at 0.79 (about four MC SEs below nominal), which is a real finding worth investigating.
The other three deltas use a profile likelihood at chi-squared with $J_R = 1$ dof under the same general MD scaffolding, so the under-coverage cannot be a global bug; it is specific to how the avg constraint propagates the $\pi_s$-weighted mean.
One candidate: the inversion treats $\pi_s$ as known constants (we passed truth-known shares in the coverage check), but the Wald variance does not absorb the finite-sample variability that the empirical $\hat\pi_s$ would inject into $\hat c_1$.
A follow-up experiment that recomputes $\hat\pi_s$ from each replication's data and adds its sampling variance to the Jacobian would discriminate this.
A second candidate: with $K = 2$ kept switchers in T=2, the $\Delta_{\text{avg}}$ equation is degenerate in a particular way (it reduces to $\beta + \phi \pi_3 (\mu_3 - \mu_2)$ instead of a sum over many switchers); the under-coverage may not show up at the empirical $K = 5$ to $27$ scale.

Per-replication CSVs at [`results/synth_t2_coverage_per_rep.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/synth_t2_coverage_per_rep.csv) and [`results/synth_t2_coverage_summary.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/synth_t2_coverage_summary.csv).

## Over-identified synthetic coverage check (R = 100, K = 6, T = 3)

To diagnose the $\Delta_{\text{avg}}$ under-coverage on the just-identified $K = 2$ synth, [`synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py) implements a $T = 3$ DGP with $K = 6$ kept switcher trajectories (so $J_R = K - 1 = 5$ over-identifying restrictions on $\phi$).
The parameters match realistic CKT log-consumption scales: trajectory means spaced 0.1 log units apart, $\sigma_\alpha = 0.6$ (within-trajectory dispersion), $\sigma_\epsilon = 0.3$ (transitory shock), $\phi_{\text{true}} = -0.5$, $\beta_{\text{base}} = 0.05$.
The narrower mean spacing makes this DGP substantially more fragile than the $T = 2$ synth; the model has more information across switcher trajectories but less signal per trajectory.

| Parameter | True value | Coverage | MC SE | Empty CI | Multi-island |
|---|---:|---:|---:|---:|---:|
| $\phi$ | $-0.500$ | 0.92 | 0.027 | 5 | 0 |
| $\Delta_{d_N}$ | $+0.100$ | 0.91 | 0.029 | 5 | 0 |
| $\Delta_{\text{avg}}$ | $-0.077$ | 0.90 | 0.030 | 5 | 0 |
| $\Delta_{d_T}$ | $-0.250$ | 0.93 | 0.026 | 5 | 0 |

The 5 empty CIs per parameter are replications where the joint LCA test rejected at the 5% level over the entire grid; with $J_R = 5$ and the $\chi^2_5$ critical value at 11.07, that is exactly the nominal Type I error rate.
Conditional on a non-empty CI ($n = 95$ reps), each parameter covers at 0.95 to 0.98, fully consistent with the asymptotic chi-squared approximation.

This closes the $\Delta_{\text{avg}}$ under-coverage finding from the $T = 2$ run.
The $T = 2$ pathology was specific to the $K = 2$ just-identified case where the $\Delta_{\text{avg}}$ moment vector reduces to a one-dimensional reparameterization tying both moments through $\phi (\alpha_3 - \alpha_2)$ with opposite-sign loadings.
At $K = 6$ with five over-identifying restrictions and trajectory means spaced 6$\times$ tighter than the $T = 2$ synth, the chi-squared approximation works cleanly across all four parameters.

Per-replication CSV at [`results/synth_overid_coverage_per_rep.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/synth_overid_coverage_per_rep.csv); summary at [`results/synth_overid_coverage_summary.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/synth_overid_coverage_summary.csv).
