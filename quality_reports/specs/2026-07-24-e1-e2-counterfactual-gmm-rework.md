# Spec: E1/E2 counterfactual inputs under WCR11 sters

Date: 2026-07-24.
Status: draft, awaiting approval.
Mode: Implementation (changes how reported counterfactual quantities are computed).

## Problem

The WCR11 attach path scrubs the three delta inversion families (`inv_dN*`, `inv_davg*`, `inv_dT*`) on every re-save: scalars to missing, macros emptied, so a corrected phi CI can never sit next to uncorrected chi-squared delta CIs on one ster.
The counterfactual pipeline consumes exactly those fields, so `12_counterfactuals.do` fails loudly on wcr11 sters.

The verified dependency map (2026-07-24, direct reads):

- [_export_e1_inputs.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do) lines 60-63 and [_export_e1_inputs_hukou.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs_hukou.do) lines 61-64 read `e(inv_phi_at_waldmin)`, `e(inv_dN_at_waldmin)`, `e(inv_dT_at_waldmin)`, `e(inv_davg_at_waldmin)` per cell into the scalars CSVs.
- [_export_e1_inputs_hukou.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs_hukou.do) lines 68-69 additionally read `e(inv_dN_ci95_lo)` and `e(inv_dN_ci95_hi)` for the CHN_rf cell.
- `run_hukou_bound` in [counterfactuals.py](file:///C:/git/ckt/explorations/python-grc/counterfactuals.py) (E2, the hukou-wedge lower bound) requires finite `delta_never_point`, `inv_dN_ci95_lo`, `inv_dN_ci95_hi` for CHN_rf and computes the bound as the fixed constant `pi_rh * pi_dN_rh` times the CI endpoints.
- The E1 aggregate uses the inversion point values for the never and always-urban trajectory returns; balanced-switcher returns come from the `_d` ster and the lumped unbalanced return from the parent ster.
- The E1 interval construction is the hull of the aggregate over the chi-squared joint accept region.

## Evidence base

All coverage numbers from [derived_quantity_coverage_synthesis.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/derived_quantity_coverage_synthesis.md) (R = 1000 per sparse-dial factor, Monte Carlo SE 0.007-0.014), verdicts under the pre-registered decision rule:

- GMM $\Delta_{d_N}$: coverage 0.915-0.940, passes (marginally; the anchor rate 0.936 is stated wherever the interval is reported).
- GMM $\Delta_{\text{avg}}$: coverage 0.929-0.944, passes.
- GMM $\Delta_{d_T}$: coverage 0.852-0.902, fails (the $(1+\phi)^{-1}$ singularity); the uncorrected inversion is no rescue.
- Chi-squared joint-region hull for the misallocation gap: 0.820 unconditional at the anchor, fails; the recorded escalation is extending the WCR11 correction to the gap's joint region, and the author leans that way (2026-07-24).

## MUST

1. The E2 bound's CI source switches from the scrubbed `inv_dN_ci95_{lo,hi}` to the GMM 95% CI for $\Delta_{d_N}$ read off the CHN_rf `_n` ster (the same nlcom estimate whose point the exporter already writes as `delta_never_point`).
2. The new scalars are exported under new keys (`gmm_dN_ci95_lo`, `gmm_dN_ci95_hi`), never under the old `inv_dN_*` names, so provenance cannot silently mix; `run_hukou_bound` reads the new keys and records the CI source in its result and in the results CSV.
3. The E1 point aggregate's never-migrant return switches from `inv_dN_at_waldmin` to the GMM `_n`-ster point for every cell (national and hukou), keeping each cell's own ster as the source.
4. The E1 interval over the chi-squared joint region is not reported while its measured coverage stands at 0.820: `12_counterfactuals` reports the point aggregate and marks the interval unavailable pending the WCR11 joint-region extension, which is scoped as its own algorithm note and spec per the gap-coverage note.
5. All finiteness and presence checks stay hard errors; no consumer acquires a silent fallback.
6. After implementation, `counterfactual_results.csv` regenerates on the definitive-run sters and the movement against `counterfactual_results_baseline.csv` goes to the author for drift adjudication, since replacing Wald-min points with GMM points moves reported numbers.

## SHOULD

1. The scalars CSVs carry a source column (or companion provenance rows) naming the ster and estimator behind each exported quantity.
2. [README_counterfactuals.md](file:///C:/git/ckt/RP7/scripts/README_counterfactuals.md) updates to describe the GMM sourcing and the interval's pending status, with no git or branch references (coauthor-facing).
3. The E2 endpoint-scaling logic itself stays unchanged: scaling CI endpoints by a known positive constant is exact for the delta-method interval just as it was for the test-inversion interval, and the shares' sampling variance remains negligible relative to the CI width.
4. Wherever the paper or a note reports the $\Delta_{d_N}$ GMM interval, the simulated anchor coverage 0.936 is stated directly, per the synthesis verdict.

## MAY

1. A simulation-appendix sentence citing the synthesis table as the basis for reporting GMM intervals for $\Delta_{d_N}$ and $\Delta_{\text{avg}}$.
2. A footnote-ready sentence on the E1 interval's pending WCR11 extension.

## Open questions for the author

1. The always-urban return $\Delta_{d_T}$ in E1's value term ($W_{\text{obs}} - W_{\text{zero}}$ includes $\pi_{d_T} \Delta_{d_T}$ since $\bar D_{d_T} = 1$): the reported gap variant zeroes the $d_T$ row, but if the reported value term keeps it, neither GMM (fails the coverage rule; large finite-sample bias in some designs) nor the scrubbed inversion supplies a defensible number.
   Options: source the point from the `_a` ster GMM estimate and report no interval for it, zero the $d_T$ row in the value term symmetrically with the gap, or drop the value term's $d_T$ sensitivity to a footnote.
   The spec implements whichever the author picks; the choice changes a reported number.
2. Whether $\Delta_{\text{avg}}$ appears anywhere in the counterfactual outputs (the exporters write `inv_davg`; if nothing downstream consumes it, the export drops rather than gaining a GMM substitute).

## Out of scope

- The WCR11 joint-region extension for the misallocation gap (own algorithm note and spec; substantial compute design).
- The trajectory-size coverage gradient and its treatment in the heterogeneity figures (separate adjudication).
- Any change to `attach_inversion_ci`, the scrub, or the sims engine.

## Verification

1. Grep confirms no consumer reads `inv_dN`, `inv_dT`, or `inv_davg` fields outside the chi2 comparison path.
2. Exporters re-run on wcr11 sters produce complete scalars CSVs with the new keys.
3. `counterfactuals.py` runs end-to-end on the regenerated inputs; the E2 bound reproduces `const * gmm_dN_ci95_{lo,hi}` exactly; the drift report lands with the author.
