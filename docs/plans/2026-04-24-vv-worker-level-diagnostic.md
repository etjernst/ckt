# Plan: VV worker-level diagnostic port

**Date:** 2026-04-24
**Context:** The [alpha-pooling derivation](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md) and [empirical diagnostic](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md) show the TV ranking of switcher weight profiles matches the Verdier-shift ranking across IDN/CHN/TZA. That's circumstantial evidence. To settle whether `run_grc_robust_vv`'s estimator is biased by the trajectory-pooling aggregation, we want to compare its $\hat\phi$ to a worker-level estimator that doesn't aggregate across workers within a trajectory --- i.e., VV's original Chamberlain (1992) + village-demeaned-instruments approach from his [Table 1 robust.do](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do).

## 1. Purpose (what this is NOT)

**This is a diagnostic check, NOT a proposed replacement for the paper's primary estimator.**

The paper uses CKT's trajectory-pooled framework throughout: $\mu_d$ parameters, LCA restriction at the trajectory level, GMM moments on trajectory-times-choice instruments. Porting VV's worker-level Chamberlain projection as a REPLACEMENT would require reworking the entire estimation + extrapolation machinery, plus the paper's theoretical derivation. That's out of scope.

What we DO want: a worker-level $\hat\phi^{\text{VV}}$ computed on the same data, using VV's own identification strategy, side-by-side with $\hat\phi^{\text{robust\_vv}}$ from the trajectory-pooled Verdier spec. If they agree, the trajectory pooling isn't introducing meaningful bias and the paper's primary estimator stands with confidence. If they disagree, we learn:

- the direction of the alpha-pooling bias in each country,
- which country's Verdier estimate to flag with a caveat,
- and how much to weight the disagreement in the paper's narrative (sensitivity column vs footnote vs main table).

## 2. Decision matrix

Let $\hat\phi^{\text{simple}}$ (published two-step), $\hat\phi^{\text{robust\_vv}}$ (main comparison), $\hat\phi^{\text{VV}}$ (new worker-level) at covs_all per country.

Tolerance: call them "agreeing" if $|\hat\phi^{\text{VV}} - \hat\phi^{\text{robust\_vv}}| < \max(0.05, \hat{\text{se}}(\hat\phi^{\text{robust\_vv}}))$. Looser than 1/2 SE because the worker-level estimator has its own noise from the Chamberlain projection.

| Pattern | Interpretation | Paper treatment |
|---|---|---|
| simple $\neq$ robust_vv $\approx$ VV | Verdier correctly absorbs between-cluster selection. Trajectory pooling adds no further bias. | `run_grc_robust_vv` as primary with confidence. VV check relegated to appendix or footnote. |
| simple $\neq$ robust_vv $\neq$ VV | Trajectory pooling fails; Verdier is biased by $\bar\beta(s)$ tilt. | Report Verdier with explicit caveat. Add VV as a sensitivity column. Narrative: "Two checks against the simple estimator; they differ, we report both, the true effect is likely bracketed." |
| simple $\approx$ robust_vv $\approx$ VV | Neither between-cluster selection nor alpha-pooling matters empirically. Simple spec was fine all along. | Robustness: all three agree. Still keep Verdier as primary for interpretability, but the caveats in the comparison memo soften. |
| Mixed across countries (e.g. IDN diverges, CHN/TZA agree) | Country-specific issue. | Flag per-country caveats. |

Expected, given the mean-TV diagnostic: IDN most likely to diverge; CHN mild divergence; TZA essentially identical.

## 3. Scope

**Included:**
- covs_all only (matches main comparison headline spec).
- Consumption, urban, unbalanced panel.
- Three countries: IDN, CHN, TZA.
- Single statistic of interest: $\phi$.

**Excluded:**
- $\Delta_{d_N}$, $\Delta_{d_T}$, $\Delta_{\text{avg}}$ extrapolations. Worker-level versions would require VV's ATE parameter machinery; out of scope for a phi check.
- Other cov variants (covs_0 through covs_2).
- Balanced panel or income outcome.
- Weak-ID-robust CIs. Point estimate + Wald SE is enough for the check.

**Deliverable:** a three-way comparison table and a short interpretation memo.

## 4. Implementation

### Stage 1: Within-worker Chamberlain projection

Mirror VV's [firststage_projection.do](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/firststage_projection.do). Per country:

1. Construct `pid_choice = pid * 10 + choice` (analog of VV's `hhid_hybrid`).
2. Residualize `lndepvar` and the covs_all controls on `pid_choice` fixed effects:
    ```stata
    areg lndepvar period_2 period_3 female age2 education_max education_max2 ///
         unbalanced unbalanced_choice, absorb(pid_choice)
    predict yresid, resid
    ```
3. For each worker, compute:
    - $a_i$ = within-pid mean of `yresid` when `choice == 0` (rural residual level).
    - $apb_i$ = within-pid mean of `yresid` when `choice == 1` (urban residual level).
    - $\text{return}_i = apb_i - a_i$ for switchers only (stayers have exactly one of the two states).

**Multi-switch trajectories:** VV's setup has at most one switch per household; CKT has RURU-style multi-switch trajectories. The Chamberlain projection absorbs `pid * choice` fixed effects, so multi-switchers contribute within-state means pooled across their multiple state visits. $\text{return}_i$ for an RURU worker is still well-defined: the difference between their mean residual when urban and when rural. That's a valid worker-level quantity; it just pools their two urban visits and two rural visits. Acceptable for the diagnostic.

### Stage 2: Village-demeaned instruments

For each switcher trajectory $s$ (we'll restrict to the same `$switchers` as the main analysis uses):

1. Regress `switcher_s * choice` on `i.vfirst` among workers with `switcher_s == 1`:
    ```stata
    reg swc_s i.vfirst if switcher_s == 1
    predict swd_s, resid
    replace swd_s = 0 if missing(swd_s)
    ```

These are the same swd_s used by `run_grc_robust_vv`. We can reuse or regenerate; either works.

### Stage 3: Worker-level LCA regression (diagnostic)

Collapse to one row per pid (worker-level). For each worker we have $a_i$, $\text{return}_i$ (missing for non-switchers), and the demeaned instruments $\{swd_{s, i}\}_{s \in S}$ (zero for non-switcher-s).

Run the LCA 2SLS at the worker level:
$$a_i = \alpha_0 + \alpha_1 \cdot \text{return}_i + \varepsilon_i, \qquad E[\text{swd}_{s, i} \cdot \varepsilon_i] = 0 \ \forall s$$

In Stata:
```stata
ivregress 2sls a (return = swd_s_*), vce(cluster vfirst_pid)
```

$\hat\alpha_1$ is the worker-level VV estimate of $\phi$.

**Why 2SLS not GMM:** VV's original code does joint GMM with both first-stage moments (the Chamberlain projection's gamma coefficients) and LCA moments. For a diagnostic we can estimate the Chamberlain projection in stage 1 and feed residuals to a stage-3 2SLS. That's a just-identified version; asymptotically equivalent to GMM if we get gamma right in stage 1. Simpler, faster, easier to debug.

**One subtlety:** we need SEs that account for stage-1 estimation uncertainty. Standard 2SLS SEs don't. Two options:
1. Ignore (the diagnostic is point-estimate focused; 1-SE tolerance is wide enough that this shouldn't matter).
2. Cluster bootstrap the entire pipeline (stages 1+2+3) at the `vfirst` level to get a bootstrap SE.

Start with option 1 for speed; add bootstrap if the comparison is close to the tolerance threshold.

### Stage 4: Comparison

Produce table:

| Country | $\hat\phi^{\text{simple}}$ (two-step) | $\hat\phi^{\text{robust\_vv}}$ | $\hat\phi^{\text{VV}}$ (worker) | $\|\text{VV} - \text{robust\_vv}\|$ | Within tolerance? |
|---------|---:|---:|---:|---:|:-:|
| IDN | -0.526 | -0.334 | ? | ? | ? |
| CHN | -0.205 | -0.155 | ? | ? | ? |
| TZA | -0.719 | -0.690 | ? | ? | ? |

Tolerance = $\max(0.05, \hat{\text{se}}(\hat\phi^{\text{robust\_vv}}))$.

### Stage 5: Report

Write [2026-04-24_vv-worker-level-diagnostic-results.md] with the table, interpretation per §2, and per-country caveats (if any) that should propagate to the paper.

## 5. Files to produce

- `explorations/verdier/x_vv_worker_level_diag.do` --- driver
- `explorations/verdier/x_vv_worker_level_diag.txt` --- log
- `explorations/verdier/x_vv_worker_level_diag_results.dta` --- comparison table data
- `docs/reviews/2026-04-24_vv-worker-level-diagnostic-results.md` --- interpretation memo

## 6. What we explicitly do NOT change

- `run_grc`, `run_grc_onestep`, `run_grc_robust_vv` --- unchanged.
- `5_GrRC.do` --- no driver changes.
- Paper main text, tables, or extrapolation formulas --- no edits until the diagnostic reports.
- RP7/scripts/0_programs.do --- the worker-level port lives in `explorations/`, not as a production program, because it is a diagnostic not a replacement.

## 7. Success criteria

Plan is successful if:
1. Worker-level VV $\hat\phi$ estimates complete without error on all three countries.
2. The comparison table has quantitative entries for all three.
3. Per-country decision (within vs outside tolerance) is clearly marked.
4. Memo documents the resulting paper-side implication per the decision matrix.

## 8. Risks and mitigations

- **Multi-switch trajectories may break the Chamberlain projection for some workers.** Mitigation: check that `pid_choice` has both states per pid in our switcher sample; drop pids with only one state observed. Log the drop count.
- **Stage-1 absorbed residuals might have tiny variance, making stage-3 2SLS noisy.** Mitigation: if SE on $\hat\alpha_1$ is huge (say $> 2 \times$ `run_grc_robust_vv`'s SE), bootstrap to get a more accurate SE before declaring divergence.
- **VV's estimator ignores the always / never extrapolation; ours gives back phi for switchers only.** That's fine for the diagnostic since we're only comparing phi, not extrapolated ATEs.

## 9. Timeline

- 30 min: write do-file
- 10 min per country (3 countries = 30 min): run
- 30 min: produce memo + commit

Total: 1.5 hours best case. If 2SLS has numerical issues, add another hour for debugging.
