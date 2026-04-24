# Plan: implementing Verdier's robust extrapolation in the CKT GRC estimator

**Date:** 2026-04-22
**Revised:** 2026-04-23 (incorporating [plan-review findings](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-22_verdier-robust-grc-plan-review.md))
**Spec:** [`docs/specs/2026-04-22-verdier-robust-grc.md`](file:///C:/git/ckt/.claude/worktrees/verdier/docs/specs/2026-04-22-verdier-robust-grc.md) (approved)
**Worktree:** `verdier`
**Mode:** Implementation

## 0. Reading list

| File | Purpose |
|---|---|
| `tmp/VV-appendix.txt` Section F (pp. 35--44) | Verdier's *derivation* of the robust extrapolation as within-$v$ demeaning. The paper itself supplies the math; we do not re-derive. |
| `tmp/VV-appendix.txt` Section E.3.2 (pp. 33--35) | The LCA-overid test: $|S|+1$ augmented exactly-identifying moments, Wald test on $H_0: \eta_0 = 0,\ \eta_t = 0\ \forall t\in S$, $\chi^2_{|S|-1}$. |
| `scripts/0_programs.do` ll. 1412--1664 | `initial_values`, `define_switcherpars`, `run_grc` (existing) |
| `scripts/0_programs.do` ll. 1764--1843 | `grc_tex_table` (existing table builder) |
| `scripts/5_GrRC.do` | Country drivers; pattern of `run_grc` calls per spec |
| `explorations/verdier/2_cluster_support_v2.do` | Helper logic (note: `min(cond(...))` semantic bug; see §2.1) |

## 1. Phasing

Six phases. Each ends in a verification gate before the next begins.

| Phase | Scope | Gate |
|---|---|---|
| P0 | Design-cleanup memos: VV-Section-F adaptation + E.3.2 transcription + bootstrap-implementation choice + `gen_vfirst` unit test | Two memos signed off; bootstrap path chosen; helper passes test on a fabricated 5-row dataset |
| P1 | `gen_vfirst`, `initial_values_robust`, `run_grc_robust` via VV's within-$v$-demeaning route; smoke-test on TZA only | TZA primary spec converges; degenerate-$v$ test reproduces simple spec to 6 dec.; cluster diagnostics in log match feasibility note |
| P2 | Roll out to CHN + IDN; per-cluster always-urban extrapolation; sample-matched simple-spec column | Three primary triples (`.ster`, `_never`, `_always`) saved; un-extrapolated population shares logged |
| P3 | LCA-overid (E.3.2) for both simple and robust specs; Wald test that $\beta(v)$ collapses to a scalar | Six new `.ster` files; both p-values reported alongside Hansen $J$ for each country |
| P4 | Secondary specs: CHN hukou (`boottest`, $G=2$), IDN kabu, TZA regdist, IDN `migr==0`. WCB inference applied to $\phi$ and $\Delta_{d_N}$ in **all three** primary specs (not just hukou). | All robustness `.ster` files saved; WCB p-values in log |
| P5 | Side-by-side tables, heterogeneity plot overlay, sign-of-$\phi$ stress matrix, results memo | `paper/main.tex` builds; results memo saved; all support shares disclosed |

## 2. Phase 0 --- Design cleanup (must complete before P1)

### 2.1 VV Section F adaptation memo

**File:** `docs/reviews/2026-04-XX_robust-grc-derivation.md`. Audience: anyone who needs to read the code. Translates VV's notation into CKT notation:

| VV | CKT |
|---|---|
| $a_i$, $b_i$ | trajectory mean ($\mu_{\underline d}$ for the worker's $\underline d_i$), slope coefficient on $\theta_i$ |
| $\alpha_1$ | $\phi$ |
| $e_v$ | $\beta(v)$ |
| $M_n$ | switchers |
| $v_i$ | first-wave province |
| $\hat{ATE}_{S,0}$ | $\Delta_{d_N}$ |
| $\hat{ATE}_{S,1}$ | $\Delta_{d_T}$ |

VV's Section F estimator is: (i) first-stage OLS recovers noisy $\hat a_i, \hat b_i$ for switchers and $\hat a_i$ for stayers; (ii) within-$v$ demean $\hat a_i, \hat b_i$ across switchers in the same cluster; (iii) GMM on the demeaned variables yields $\hat\phi$; (iv) cluster-specific $\hat e_v = \frac{1}{n_v}\sum_{i\in M_n: v_i=v}(\hat a_i - \hat\phi \hat b_i)$ enters the stayer-ATE estimators per VV Eq. F.3. The "saturated joint GMM" route the original plan envisioned is *equivalent in expectation* but VV explicitly recommends the demeaned form for tractability when $|V|$ is large. We follow VV.

Critically: this is not novel methodology --- the memo's job is to map symbols, identify which existing CKT objects play each VV role, and confirm that CKT's `run_grc` first-stage is the analogue of VV's first-stage (which the memo will confirm; if not, document the gap).

Sign-off: human review before P1 begins.

### 2.2 LCA-overid (E.3.2) transcription

**File:** `docs/reviews/2026-04-XX_lca-overid-derivation.md`. Five independent subagents transcribe the E.3.2 augmented moments in parallel; majority-of-five consensus is the canonical version. Key facts (from initial transcription):

- VV adds $|S|+1$ exactly-identifying moments, indexed by $\eta_0$ and $\eta_t$ for $t \in S$.
- $S$ = largest subset of time periods with linearly independent treatment vectors among switchers. For $T\geq 3$, $S = \{1, \ldots, T\}$.
- Test: Wald, $H_0: \eta_0 = 0, \eta_t = 0\ \forall t \in S$, $\chi^2_{|S|-1}$.
- Variance: cluster bootstrap or Proposition 6 analytical.
- Inapplicable when $T = 2$ (and CHN with 2 waves would be excluded; CKT data: CHN 4 waves, IDN 5, TZA 3 --- all qualify).

The Stata implementation: `run_grc_overid` adds two extra moment terms to the existing `run_grc` GMM equation (one for $\eta_0$, $T-1$ more for the $\eta_t$'s after one is dropped for the base period), uses `test {eta_0=0} {eta_1=0} ...`, and reports the resulting $\chi^2$, df, and p-value.

Sign-off: human review of the consensus transcription and the worked Stata expression before any `run_grc_overid` code is written.

### 2.3 Inference: analytical default, bootstrap as cross-check

**Updated 2026-04-23** after reading [VV's published implementation](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-23_lca-overid-implementation-findings.md): VV uses analytical cluster-robust standard errors (`vce(cluster vil)`) and reports the LCA-overid p-value via `chi2tail`. He does NOT bootstrap the LCA-overid test. We follow VV.

**Default for both LCA-overid and $\hat\phi$ inference:** analytical SEs from `vce(cluster vfirst)` (robust spec) or `vce(cluster pid)` (simple spec). Wald p-values via `chi2tail`.

**Cross-check (run alongside, do not replace):** `boottest` after `gmm` with Webb weights and 9999 reps, given $G \in \{13, 19, 22\}$ for our primary specs. `boottest` v3+ supports `gmm` with one caveat (the moment-weighting matrix is held fixed across replications, not re-weighted). If `boottest` rejects the augmented `gmm` syntax, fall back to Kline--Santos (2010) score bootstrap (hand-rolled on GMM influence functions).

**Validation route (small reps, TZA only):** full cluster bootstrap with `bsample, cluster(vfirst)` re-running `run_grc_robust` per replication. Confirms `boottest` p-values agree to 2 decimals. Only run once per spec for validation.

### 2.4 `gen_vfirst` unit test

The plan's helper `bysort pid (year): egen vfirst = min(cond(!missing(vname), vname, .))` is wrong: `min` returns the smallest *value*, not the value at the earliest year. The same bug appears in `2_cluster_support_v2.do`, so the feasibility-note cluster counts may be off and need a re-run with the corrected helper.

Correct implementation:

```stata
capture program drop gen_vfirst
program define gen_vfirst
    syntax , vname(varname) genname(name)
    capture drop `genname'
    tempvar tmp
    bysort pid (year): gen `tmp' = `vname' if !missing(`vname') & ///
        (_n == 1 | missing(`vname'[_n-1]))
    bysort pid: egen `genname' = max(`tmp')
end
```

Unit test on a 5-row fabricated panel with known first-wave values; document in the §2.2 derivation memo. Re-run `2_cluster_support_v2.do` with corrected helper; if cluster counts differ materially from the feasibility note, update the note.

### 2.5 China $v$-coarseness question

The user asked: for CHN should we use a coarser-than-province $v$ to ease convergence? Three considerations:

- Under VV's within-$v$ demeaning (the route we adopt), the parameter explosion of the saturated formulation disappears. For CHN, free GMM parameters become $\hat\phi$ + a handful of trajectory means + $|V|-1$ cluster fixed-effect dummies $\sim 30$ parameters total --- not 406. Convergence concern is much milder.
- CFPS data does not contain a built-in macro-region variable (East/Central/West/Northeast or 6-region). Constructing one requires hand-mapping 29 provinces. Doable, but not data-driven.
- A coarser $v$ trades better convergence and tighter asymptotic SEs (fewer clusters but each is bigger) against a stronger identifying assumption (now we require i.i.d. within macro-region rather than within province). Verdier explicitly argues finer $v$ is preferable when feasible.

**Decision:** Stick with `vindex(prov)` (29 clusters) for CHN under the within-demeaning route; flag macro-region as an explicit fallback in P4 only if P2 convergence fails. Add a CHN-specific macro-region helper (4-region mapping: East, Central, West, Northeast) to be ready as a fallback.

## 3. Phase 1 --- TZA smoke test (within-demeaning route)

### 3.1 New programs in `scripts/0_programs.do`

All additive --- existing programs unchanged.

- `gen_vfirst` per §2.4 (after `gen_time_trend` at l. 372).
- `initial_values_robust` (after `initial_values` at l. 1412). Cluster-OLS with $v$-demeaned variables; for any $(s,v)$ cell that is empty or singleton, substitute the global trajectory mean for $s$ and log substitution count. Validates `initial` local has no `.` literals before passing to `gmm`.
- `run_grc_robust` (after `run_grc_hukou` at l. 1759). Per the [within-demeaning derivation memo §4](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-23_robust-grc-derivation.md), the implementation route is to add $|V|-1$ cluster dummies $\times D_{it}$ as cluster-specific $\Delta_{\underline d_0}$ parameters. This is the single-step CKT-equivalent of VV's two-step within-demeaning; it avoids the saturated trajectory-by-cluster $\mu$ explosion (which would have been $\sim 400$ free parameters for CHN; with this approach we add 21--28 net parameters across the three countries).

    Body:
    1. Confirm `vindex` exists; build `vfirst` via `gen_vfirst`. Drop missing-$v$ obs; log count.
    2. Cluster-support diagnostics inline (mean / median / max switchers per cluster; clusters $\geq 10$ sw; always-rural support). Bail if support below threshold.
    3. Replace the simple-spec scalar $\Delta_{\underline d_0}$ with a cluster-specific $\Delta_{\underline d_0, v} = \beta(v)$ via $|V|-1$ cluster dummies interacted with $D_{it}$ in the GMM equation. The trajectory-pooled $\mu_{\underline d}$ scalars stay as in `run_grc`.
    4. Build switcherpars via existing `define_switcherpars` (no cluster interaction needed; the cluster fixed effects on $D_{it}$ absorb the cluster-level intercept variation).
    5. GMM call structurally identical to `run_grc` plus the cluster-FE-on-$D_{it}$ block. Standard errors `vce(cluster vfirst)`. Logged check: instrument-count : free-parameter ratio < 3 or bail.
    6. Save raw `.ster` as `grc_robust_{country}_{spec}_{vindex}.ster`.
    7. Hansen $J$ + convergence flag.
    8. Per-cluster $\hat\Delta_{d_N, v}$ via `nlcom`; cluster-share-weighted aggregate $\hat\Delta_{d_N}$ over clusters with both switcher and never support per derivation memo §7. Report population share covered.
    9. Always-urban: P2 work; default cross-origin extrapolation per derivation memo §6.
    10. Switcher $\Delta$'s and $\Delta_{\text{avg}}$ as in `run_grc`.

### 3.2 TZA driver

In `scripts/5_GrRC.do` TZA section, add **one** parallel `run_grc_robust` call after `grc_TZA_covs_all`:

```stata
run_grc_robust, estname(grc_robust_TZA_covs_all_region) ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance') vindex(region) ///
    covars(`periodFE' $covs_gmm_all) iterate(`iterations')
```

Comment out IDN and CHN sections temporarily; revert in P2.

### 3.3 P1 verification gate

- Cluster-support log matches feasibility note (26 regions, 19 with $\geq 10$ switchers, 100% support) **after** re-running `2_cluster_support_v2.do` with corrected `gen_vfirst`.
- `grc_robust_TZA_covs_all_region.ster` plus `_never`, `_avg`, `_delta` siblings exist; convergence flag = "Y".
- **Degenerate-$v$ test:** with `vindex(_one)` (single cluster, all obs), $\hat\phi$ and all $\hat\Delta$'s match simple `run_grc` to 6 decimals.
- Commit at this point with message `verdier robust: P1 -- run_grc_robust + TZA smoke test`.

## 4. Phase 2 --- CHN + IDN primary, always-urban

Insert parallel `run_grc_robust` calls in IDN (`vindex(prov)`) and CHN (`vindex(prov)`) sections of `5_GrRC.do`. Run full `5_GrRC.do`. Verify cluster diagnostics in log against the corrected feasibility note (CHN: 29 prov, 22 $\geq 10$ sw; IDN: 22 prov, 13 $\geq 10$ sw).

Implement always-urban per-cluster extrapolation (per spec §3.3). Two sub-options to choose between in P2:

- **(2a) Same $\phi$.** Use the rural-origin-switcher $\hat\phi$ and apply it to the always-urban subgroup, acknowledging cross-origin extrapolation in text.
- **(2b) Separate $\phi^U$.** Estimate a second slope from urban-origin switchers if support permits (check switcher count by first-wave-urban subset before promising).

Default (2a) for P2 deliverable; (2b) noted as future work if support is sufficient.

In addition: for tables, save a sample-matched simple-spec estimate that restricts the simple-spec sum to the same support set as the robust-spec aggregator (per R6). This is the apples-to-apples comparison number.

**P2 verification gate.** Three primary triples produced; un-extrapolated population shares logged; sample-matched simple-spec saved. Commit `verdier robust: P2 -- CHN/IDN primary + cluster-aware always-urban`.

## 5. Phase 3 --- LCA overid + constant-$\beta(v)$ test

### 5.1 `run_grc_overid`

New program in `0_programs.do`. Implements the augmented exactly-identifying moment system from VV E.3.2 per the [§2.2 transcription memo](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-23_lca-overid-derivation.md) and the [implementation-findings memo §5](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-23_lca-overid-implementation-findings.md). Naming: `grc_{simple|robust}_{country}_{spec}{_vindex}_lca.ster`.

**Implementation pattern (mirrors VV's `Table1/Code/nrobust.do` and `robust.do`):** single `gmm` call with the system stacked as: original `run_grc` moments + LCA-overid $\eta$ moments. Uses two instrument blocks: block 1 = original CKT instruments (the `wd*` analogues for first-stage covariates), block 2 = per-period treatment indicators (`hybrid`per'IV` analogues) for the overid moments. After estimation, `test [eta0]_cons [eta1]_cons ... [eta_T]_cons` produces a Wald $\chi^2_{|S|-1}$ statistic; p-value via `chi2tail(|S|-1, chi2)`.

**Decided 2026-04-23 (Q7):** single-step extension of `run_grc`'s GMM equation, NOT a parallel Chamberlain projection. The trajectory-pooled trajectory means $\mu_{\underline d}$ in `run_grc` play the role of VV's worker-level $\hat a_i$; the LCA epsilon expression $(a - \alpha_0 - \alpha_1\,\text{return})$ is rewritten in CKT terms as $(\mu_{\underline d_i} - \alpha_0 - \phi(\mu_{\underline d_i} - \mu_{\underline d_0}))$ and added as one moment per worker-period. The augmentation does NOT over-determine $\phi$ (each $\eta_t$ is exactly identified by its own moment; see implementation-findings memo §2 Q2).

**GMM weighting (Q8 still open):** VV uses `winitial(unadjusted, independent), onestep` to keep the first-stage and overid moment groups block-diagonal. Current `run_grc` uses `gmm` defaults (2-step). Default for `run_grc_overid`: match VV's pattern. To resolve before P3 code is written.

**Robust-spec specifics:** drop the $\alpha_0$ scalar from the epsilon expression (the cluster fixed effects on $D_{it}$ in `run_grc_robust` already absorb the cluster-level intercept). Drop the $\eta_0$ moment. Test only $[eta_t]_cons$ for $t \in S$. df remains $|S|-1$ (we lose one parameter and one moment). See implementation-findings memo §2 Q3.

### 5.2 Constant-$\beta(v)$ Wald test

For each robust spec, add a Wald test of $\beta(v_1) = \beta(v_2) = \ldots = \beta(v_{|V|})$ after `run_grc_robust`. The cluster fixed-effect dummies in the GMM equation give us all $|V|-1$ $\beta(v) - \beta(v_{\text{base}})$ contrasts; `test` produces a joint $\chi^2_{|V|-1}$. Save as `e(beta_v_chi2)`, `e(beta_v_p)`. Failing to reject is itself a result --- it would mean CKT's simple spec is OK after all.

### 5.3 Driver calls

Add to each country's section of `5_GrRC.do` (with `initial(...)` mirroring the originating call):

```stata
run_grc_overid, estname(grc_TZA_covs_all_lca) ///
    base_estname(grc_TZA_covs_all) ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance') ///
    covars(`periodFE' $covs_gmm_all) iterate(`iterations')

run_grc_overid, estname(grc_robust_TZA_covs_all_region_lca) ///
    base_estname(grc_robust_TZA_covs_all_region) ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance') vindex(region) ///
    covars(`periodFE' $covs_gmm_all) iterate(`iterations')
```

**P3 verification gate.** Six new `.ster` files plus six $\beta(v)$ Wald p-values logged. Commit `verdier robust: P3 -- LCA overid + constant-beta(v) test`.

## 6. Phase 4 --- Secondary specs and WCB

### 6.1 Wild-cluster bootstrap for primary specs

Per R4, $G \in \{19, 22, 13\}$ for the primary robust specs is too few for analytical CR1 SEs to be reliable. Apply `boottest` after each primary `run_grc_robust` call (Webb weights, 9999 reps, seed `20260423`):

```stata
boottest {phi=0}, cluster(vfirst) reps(9999) seed(20260423) weighttype(webb)
estadd matrix wcb = (r(stat), r(p), r(p_l), r(p_u)), replace : grc_robust_TZA_covs_all_region
```

Same for $\Delta_{d_N}$ and the constant-$\beta(v)$ test. Caveat: `boottest` after `gmm` does not re-weight the moment-weighting matrix per replication; document in the results memo. If `boottest` rejects the syntax of the augmented `gmm` system, fall back to Kline--Santos score bootstrap (route 2 in §2.3).

### 6.2 CHN hukou ($G=2$)

Use `boottest` with `cluster(hukou)` and `reps(9999)`. With $G=2$, even WCB has known size distortions; report alongside MacKinnon--Webb (2018) subcluster bootstrap as a robustness. Cross-check against the existing `run_grc_hukou` split-$\phi$ estimates (the pooled-$\phi$ from `vindex(hukou)` should bracket them).

### 6.3 IDN kabu, TZA regdist, IDN `migr==0`

Driver-call additions per the original plan §5.2--5.3, with two corrections:
- Drop the `egen regdist_idn = group(prov kabu)` line from IDN; use `vindex(kabu)` directly.
- Document that `run_grc_robust` calls `initial_values_robust` internally; the `preserve/restore` block for `migr==0` only needs the `run_grc_robust` call.

**P4 verification gate.** All robustness `.ster` files saved; WCB p-values stored as matrices on each estimate. Commit `verdier robust: P4 -- secondary specs and wild-cluster bootstrap`.

## 7. Phase 5 --- Tables, plots, results memo

### 7.1 `grc_tex_table_robust`

Side-by-side columns within the existing table layout. Three new rows per robust column: (a) un-extrapolated population share, (b) cluster count contributing to $\phi$ identification, (c) WCB p-value alongside CR1 p-value for $\phi$. Simple-spec column appears in two flavors: unrestricted (current behavior) and sample-matched (restricted to robust-spec support set), as separate rows.

Output filenames lowercase: `grc_robust_{country}_consumption_urban_unb.tex`.

### 7.2 Heterogeneity plot overlay

Modify `heterogeneity_plots` to overlay robust slope $\hat\phi$ on existing pooled-$\phi$ figures. Detailed figure design TBD when tables settle.

### 7.3 Sign-of-$\phi$ stress matrix

Per country, a $|V_{\text{choices}}| \times |\text{routes}|$ matrix of $\hat\phi$:
- CHN: rows = `prov`, `hukou`, `macroregion`; columns = within-demeaning, saturated (TZA-only validation route, listed for symmetry --- entries blank for CHN).
- IDN: rows = `prov`, `kabu`, `migr==0` subset; columns same.
- TZA: rows = `region`, `regdist`; columns same.

Sign-and-magnitude stability of $\phi$ across this matrix is the actual robustness deliverable for the pro-poor claim.

### 7.4 Results memo

`docs/reviews/2026-04-XX_verdier-results.md`. Headings as in the original plan, plus:
- Sign-of-$\phi$ stress matrix as the headline robustness table.
- WCB p-values discussion (caveat about `boottest` not re-weighting the moment matrix).
- Constant-$\beta(v)$ test result: did the data reject the simple spec, or not?

**P5 verification gate.** `paper/main.tex` builds with new tables; heterogeneity plots regenerate; results memo saved. Commit `verdier robust: P5 -- tables, plots, results memo`.

## 8. File-touch list

New files:
- `docs/plans/2026-04-22-verdier-robust-grc.md` (this file)
- `docs/reviews/2026-04-XX_robust-grc-derivation.md` (P0)
- `docs/reviews/2026-04-XX_lca-overid-derivation.md` (P0)
- `docs/reviews/2026-04-XX_verdier-results.md` (P5)

Modified (single file, additive only):
- `scripts/0_programs.do`: append `gen_vfirst`, `initial_values_robust`, `run_grc_robust`, `run_grc_overid`, `grc_tex_table_robust`. Modify `heterogeneity_plots` (P5).
- `scripts/5_GrRC.do`: parallel `run_grc_robust`, `run_grc_overid`, `boottest` calls per country.

Modified (small fix):
- `explorations/verdier/2_cluster_support_v2.do`: replace `min(cond(...))` with corrected `gen_vfirst` logic. Re-run; update feasibility note.

Generated:
- `output/grc_robust_{country}_{spec}_{vindex}[_subsample].ster` plus `_never`, `_always`, `_delta`, `_avg`, `_lca` siblings.
- `output/tables/grc_robust_{country}_consumption_urban_unb.tex`.

Not touched:
- `data/processed/*.dta`.
- `1_processData.do`, `0_programs.do` for `data_setup*`, `setup_grc_estimation`, `run_grc`, `run_grc_hukou`.
- `paper/main.tex` (manuscript prose updates are a separate spec).

## 9. Risks revisited

| Risk | Mitigation |
|---|---|
| GMM convergence under within-demeaning with 29 CHN clusters | Far milder than the saturated-route concern. If it still fails, the macro-region fallback (4 clusters; analytical SEs unreliable but interpretation cleaner) is ready. |
| `boottest` rejects the `gmm` syntax of the augmented overid system | Fall back to Kline--Santos score bootstrap (route 2 in §2.3). Document the route in the results memo. |
| LCA overid moment specification garbled in transcription | Five-agent independent transcription with majority consensus; human sign-off on the consensus before any code is written. |
| `boottest` does not re-weight the moment matrix per replication | Document this approximation in the results memo; in P4 §6.1 run a small-rep validation against route 3 (full bsample) to confirm p-values agree to 2 decimals. |
| CHN hukou WCB with $G=2$ has known distortion | Report both Roodman `boottest` and MacKinnon--Webb subcluster as robustness; flag clearly. |
| Always-urban support thinness in some clusters | (2a) default uses rural-origin $\phi$ for the urban subgroup with cross-origin caveat; (2b) separate $\phi^U$ is future work if support is sufficient. |

## 10. Sign-off

- [x] **Plan approved (revised).** Reviewer: Emilia Date: 2026-04-23
- [x] **Begin Phase 0.**
