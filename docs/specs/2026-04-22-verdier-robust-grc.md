# Spec: implementing Verdier's robust extrapolation in the CKT GRC estimator

**Date:** 2026-04-22
**Task:** verdier-robust-grc
**Worktree:** `verdier`
**Workflow mode:** Implementation (per `rules/workflow.md`)
**Prerequisites:**
- [Design memo](file:///C:/git/ckt/.claude/worktrees/verdier/quality_reports/reviews/2026-04-22_verdier-modification-design.md)
- [Addendum](file:///C:/git/ckt/.claude/worktrees/verdier/quality_reports/reviews/2026-04-22_verdier-modification-design-addendum.md)
- [Feasibility note](file:///C:/git/ckt/.claude/worktrees/verdier/quality_reports/reviews/2026-04-22_verdier-feasibility-note.md)

This spec uses the MUST / SHOULD / MAY framework with clarity status flags (C = clear, A = ambiguous but has a default, R = requires reviewer input).

---

## 1. Purpose and scope

Implement the robust extrapolation of Verdier (2020) inside the CKT GRC pipeline. This is variant A of the design memo. The goal is to weaken the CKT identifying assumption A2 ($\nu_{it}^l$ i.i.d. across individuals, time, locations) to allow a region-specific component: $\nu_{it}^l = m_l(v_i) + \tilde\nu_{it}^l$, where $v_i$ is first-wave province (or country-specific equivalent per §3.1) and only the residual $\tilde\nu_{it}^l$ need be i.i.d.

Under the relaxed assumption, the LCA restriction becomes $\Delta_i = \beta(v_i) + \phi\theta_i$. The slope $\phi$ remains common across clusters; the intercept is cluster-specific. Estimation partials $v_i$ out of the trajectory means in the restricted GRC regression.

Out of scope for this spec (may be future specs):
- Variant B (stand-alone LCA overid test with $|S|-1$ df).
- Variant C (cost-shifter diagnostic via an observed exogenous covariate).
- Variant D (individual-level Chamberlain-style rewrite).
- Any change to the `define_switcherpars` hardcoding bug --- orthogonal.

## 2. Functional requirements

### 2.1 MUST

- **M1 [C].** Introduce a new program `run_grc_robust` in `scripts/0_programs.do` alongside the existing `run_grc`. The existing `run_grc` remains unchanged and usable; the two programs run side-by-side in every country's pipeline. Users call either one depending on the specification.
- **M2 [C].** `run_grc_robust` accepts an additional argument `vindex(varname)` that names the cluster indexing variable $v_i$. Defaults per country per §3.1 are set in country-level driver do-files, not hardcoded in the program.
- **M3 [C].** The restricted GRC equation that `run_grc_robust` estimates is:
  $$y_{it} = \sum_{\underline d, v} \mu_{\underline d, v}\,\mathbbm{1}\{\underline d_i = \underline d, v_i = v\} + \Delta_{\underline d_0} D_{it} + \phi \sum_{\underline d \in \mathcal D_S \setminus \underline d_0} (\mu_{\underline d, v_i} - \mu_{\underline d_0, v_i}) D_{it}\mathbbm{1}\{\underline d_i=\underline d\} + \text{(always-urban term, adapted)} + x_{it}'\gamma + \varepsilon_{it}.$$
  The slope $\phi$ is a single scalar; the trajectory-cluster intercepts $\mu_{\underline d, v}$ are $|\mathcal D| \times |V|$ free parameters (subject to support).
- **M4 [C].** The instrument vector in `run_grc_robust` is the interaction of the current CKT instruments (trajectory indicators, $D_{it}$, trajectory $\times D_{it}$, covariates) with cluster indicators. Standard errors are clustered at the $v_i$ level.
- **M5 [C].** The always-rural return $\Delta_{d_N}$ plug-in is computed per $v$ via `nlcom`:
  $$\widehat\Delta_{d_N, v} = \hat\Delta_{\underline d_0, v} + \hat\phi\,(\hat\mu_{d_N, v} - \hat\mu_{\underline d_0, v}),$$
  then averaged over $v$-clusters with both (i) a non-empty always-rural mass and (ii) at least one switcher. The averaging weights are proportional to the share of always-rural individuals in each cluster. An overall $\widehat\Delta_{d_N}$ is reported as the cluster-support-weighted average.
- **M6 [C].** Observations with missing $v_i$ are dropped from estimation with a count reported. Per the feasibility note, this is $\leq 0.5\%$ per country.
- **M7 [C].** The spec runs on the unbalanced panels (`{CHN,IDN,TZA}_unb.dta`) for the primary consumption specifications. The balanced-panel specifications (`_bal.dta`) are run as a robustness. Both inherit from the existing pipeline structure.
- **M8 [C].** Main results tables (`GRC_{country}_consumption_urban_unb.tex` and equivalents) report the robust spec alongside the simple spec, either as additional columns or as a separate panel. Format decision is in the plan document, not here.
- **M9 [C].** The country-level drivers (`5_GrRC.do`) gain a parallel call to `run_grc_robust` for each main specification that currently calls `run_grc`. The existing calls are preserved.
- **M10 [C].** The baseline switcher trajectory $\underline d_0$ is held fixed across $v$-clusters. This is a normalization, not a substantive choice: fixing $\underline d_0$ globally means all $\mu_{\underline d, v}$ are interpreted relative to the same reference trajectory.

### 2.2 SHOULD

- **S1 [C].** Report Verdier's LCA-specific overid test ($|S|-1$ df) for **both** the simple and the robust spec, so the two tests can be directly compared. Implementation: augment each GMM system with $|S|-1$ nuisance $\eta_s$ parameters as per VV's equation F in the appendix, and `test` their joint zero-ness after estimation. The simple-spec version is the "variant B" diagnostic from the design memo: it tests whether the current CKT identifying assumption holds. The robust-spec version tests whether the $v_i$-relaxed version holds. The contrast between the two p-values is the key diagnostic.
  - Deliverable: a `run_grc_overid` program that takes an existing `.ster` file and computes the LCA overid test on it; callable on both `run_grc` and `run_grc_robust` estimates. Alternatively, add the $\eta_s$ moments inline to `run_grc` and `run_grc_robust` so the overid test is produced as part of the primary estimation.
- **S2 [A, default: run both].** Report CHN hukou-indexed robust spec (`vindex(hukou)`) as a secondary specification. Only two clusters, so wild cluster bootstrap standard errors are required (use `boottest`'s wild cluster bootstrap at the cluster level, 999 repetitions). Reconcile with the current hukou-split pipeline: confirm whether the robust spec with hukou clustering recovers a pooled $\phi$ consistent with the two separate hukou-split $\phi$s estimated in the current code.
- **S2$'$ [C, added 2026-04-23].** Report CHN `vindex(birth_province)` as a third secondary spec. Per the [corrected feasibility comparison](file:///C:/git/ckt/.claude/worktrees/verdier/quality_reports/reviews/2026-04-23_feasibility-comparison.md), birth_province has 32 clusters with 19 having $\geq 10$ switchers and 99.5% always-rural support --- comparable to first-wave `prov` and institutionally cleaner (literally the worker's origin, not where they were observed at panel start). Kept as robustness rather than primary because birth_province is missing for some workers (smaller sample), so it should not displace `prov` as the default. The original feasibility note dismissed this option due to the `gen_vfirst` bug; the corrected helper reveals it as a viable indexing variable.
- **S3 [A, default: run].** For IDN, report the finer-grain robust spec with `vindex(kabu)` (244 kabupaten, 92.4% always-rural support) as an additional secondary.
- **S4 [A, default: run].** For TZA, report the finer-grain robust spec with `vindex(regdist)` (region-district, 130 clusters, 84.9% support) as an additional secondary.
- **S5 [A, default: run].** For IDN, report the `migr == 0` subsample restriction as a robustness (sample where first-wave location equals birth location, so $v_i$ is a clean origin index).
- **S6 [C].** Log the cluster-support diagnostics (mean switchers per cluster, fraction with $\geq 10$ switchers, always-rural support fraction) at the top of every `run_grc_robust` call so the log captures what subsample the estimate is based on.
- **S7 [C].** Convergence: reuse `initial_values` with the cluster-specific $\mu$'s initialised to cluster-specific trajectory means from the data. The current `initial_values` program will need a small extension to compute these.

### 2.3 MAY

- **MA1 [R].** Implement variant A$'$ (VV's joint two-step GMM inference without changing identification). Low-risk code cleanup; unclear whether the inference improvements warrant the effort. Defer.
- **MA2 [R].** Implement variant C (cost-shifter diagnostic). Requires identifying a defensible $w_i$ per country (distance-to-capital, travel-time-to-urban, migration-policy indicator). Defer to a separate spec.
- **MA3 [C].** Variance-estimation alternative: cluster bootstrap applying both steps of the estimator (first-stage and second-stage) with 999 repetitions, clustered at $v_i$. Use if analytical cluster-robust SEs from `gmm` turn out to underperform simulation-based SEs in Monte Carlo.

Note: variant B (LCA overid test on the simple spec) was moved from MAY to SHOULD in S1. Both simple and robust specs now receive the overid test and their p-values are compared directly.

## 3. Design decisions

### 3.1 $v_i$ per country

Defaults (primary specification):

- **CHN:** `vindex(prov)` (29 first-wave provinces; 22 with $\geq 10$ switchers; 99.99% always-rural support).
- **IDN:** `vindex(prov)` (22 first-wave propinsi; 13 with $\geq 10$ switchers; 99.65% support).
- **TZA:** `vindex(region)` (26 first-wave regions; 19 with $\geq 10$ switchers; 100% support).

Secondary specifications per §2.2 S2--S5.

### 3.2 First-wave vs time-varying

$v_i$ is defined as the first observed non-missing value of the location variable per individual. Operationally: `bysort pid (year): egen v_first = first(`varname')` or equivalent. Individuals always-rural at wave 1 get their wave-1 rural province; switchers who start rural get their rural origin; always-urban individuals get their wave-1 urban province. $v_i$ is time-invariant by construction.

Implication: the within-$v$ variation that identifies $\phi$ is within-first-wave-province switcher variation. This is acceptable for the primary spec because migration decisions from period 2 onward are what the LCA describes; the wave-1 province is "pre-treatment" in that sense for our panel.

### 3.3 Always-urban extrapolation

Under the simple spec the always-urban average return is recovered from:
$$\widehat\Delta_{d_T} = \widehat{\kappa_{d_T}} - \widehat\mu_{d_T},\qquad \widehat\mu_{d_T} = \widehat\mu_{\underline d_0} + \frac{\widehat\kappa_{d_T} - \widehat\Delta_{\underline d_0} - \widehat\beta}{\widehat\phi} \cdot \widehat\phi = \ldots$$
(see current `run_grc`). Under the robust spec the analogue is cluster-specific: for each urban $v$-cluster containing always-urban individuals and at least one switcher (rural-starter who became urban, or urban-starter who switched), extrapolate $\Delta_{d_T, v}$ using within-$v$ switcher slope. Average over urban $v$-clusters.

Decision [A, default]: always-urban extrapolation uses urban-origin first-wave clusters separately from rural-origin first-wave clusters. If the urban-origin $v$-clusters lack switcher support, the always-urban extrapolation is reported only where identified; the remainder is flagged.

### 3.4 Missing $v_i$ treatment

Drop. Per the feasibility note the dropped fraction is small ($\leq 0.5\%$ for all primary specs). Report the count in the log.

### 3.5 What happens to the `define_switcherpars` hardcoded base bug

Orthogonal. `run_grc_robust` inherits the same bug for income specifications. Fix in a separate spec.

## 4. Deliverables

1. New program `run_grc_robust` in `scripts/0_programs.do`. Existing `run_grc` unchanged.
2. Updates to `scripts/5_GrRC.do` (and analogous scripts) adding parallel `run_grc_robust` calls.
3. Updated `grc_tex_table` (or new `grc_tex_table_robust`) to produce LaTeX tables that include the robust column(s) alongside the simple.
4. Updates to `3_heterogeneity_plots.do` to overlay robust slope on the existing pooled $\phi$ figures, or produce a side-by-side plot.
5. Log diagnostics per §2.2 S6 captured in the existing log stream.
6. Robustness specifications per §2.2 S2--S5 producing separate `.ster` files (naming convention: `grc_robust_{country}_{spec}_{vindex}.ster`).

## 5. Non-goals

- The manuscript prose does not change in this spec. Prose updates go in a separate spec once results are in.
- The simple-extrapolation estimator is preserved and reported. The paper keeps both for comparison, at least through an R&R.
- No changes to the data-processing pipeline (`1_processData.do` and upstream).

## 6. Risks and open questions

### 6.1 Requires reviewer input (all deferred until we have results)

- **R1.** Should the manuscript headline feature the robust spec as primary, or keep the simple spec as primary with robust as robustness? Deferred. Default for now: report both.
- **R2.** For CHN, does the hukou-indexed robust spec replace the current hukou-split pipeline, or run alongside it? These are different estimators (pooled $\phi$ vs separate $\phi$ per hukou). Deferred. Default for now: run alongside.
- **R3.** Variant B included (moved to S1). No longer a pending decision.

### 6.2 Implementation risks

- **I1.** Convergence of `gmm` with many cluster-specific $\mu$'s (CHN: 29 clusters $\times$ 14 trajectories = up to 406 free $\mu$ parameters). Mitigation: S7 initial values; if convergence fails, reduce clusters via a coarser $v_i$ specification.
- **I2.** Identification of $\phi$ relies on within-cluster switcher variation. Clusters with $<5$ switchers contribute nothing to $\phi$ identification. If many clusters fall below this threshold (see feasibility note: all three countries have at least 13 clusters with $\geq 10$ switchers), the estimator should still work, but cluster-robust standard errors may be understated.
- **I3.** `run_grc_robust` has to be internally consistent with how `run_grc` handles always-urban, switcher base trajectory, and covariates. Any divergence would make the side-by-side comparison non-comparable. Mitigation: the two programs share internal sub-programs for switcher base, initial values, and covariate setup.

## 7. Acceptance criteria

- **A1.** `run_grc_robust` runs without error on all three country primary specs using the unbalanced consumption panels. `.ster` files saved. Hansen $J$ and LCA-specific overid test statistics recorded.
- **A2.** Cluster-support diagnostics logged match the feasibility note (29 CHN provinces with 22 having $\geq 10$ switchers, etc.). Sanity check that confirms the data has been read correctly.
- **A3.** Side-by-side table produced comparing simple and robust specs for primary consumption specifications.
- **A4.** Secondary specs per S2--S5 run without error; their results recorded in robustness tables.
- **A5.** A short results memo drafted (separate from this spec) summarizing: magnitude of $\hat\phi$ change under robust vs simple; magnitude of $\widehat\Delta_{d_N}$ change; direction of pro-poor finding across both specs; overid test results.

---

## Sign-off

- [x] **Spec approved.** Reviewer: Emilia Date: 2026-04-22
- [x] **Ready for plan.** Move to `docs/plans/2026-04-22-verdier-robust-grc.md`.
