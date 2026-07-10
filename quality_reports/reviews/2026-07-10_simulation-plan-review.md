# Fresh-context review of the extension-simulation-study plan

2026-07-10.
Reviewer: fresh-context critic subagent (plan + spec only, no priors), session-model tier.
Target: [quality_reports/plans/2026-07-10-extension-simulation-study.md](file:///C:/git/ckt/quality_reports/plans/2026-07-10-extension-simulation-study.md) at commit `e665460`, against the approved spec.
Verdict: REVISE; all findings folded into the plan at commit `b2bc645`, except as noted.

## Findings and dispositions

1. CRITICAL. Under the SE-fix fallback, $\Delta_{\text{unb}}$ had no CI at all (`compute_all_inversion_cis` inverts only $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$), so M4 coverage was unanswerable for a headline estimand.
ADOPTED: the plan now assigns $\Delta_{\text{unb}}$ a cluster-robust Wald CI from the auxiliary OLS ($U_i \times D_{it}$ coefficient) in every branch.
2. MAJOR. The truth of $\Delta_{\text{unb}}$ was undefined and weighting-sensitive in general.
ADOPTED: the DGP draws unbalanced $\theta_i$ from one conditional distribution matching the lumped cell's empirical mean, making the truth weighting-invariant; disclosed as a calibration choice with a heterogeneous-means sensitivity pocketed.
3. MAJOR. Two-regime pooled truths unstated.
ADOPTED: regime-share-weighted definitions written into the plan's new truth-definitions section.
4. MAJOR. The port's Hansen J differs from production Stata on the same IDN cell ($J = 97.74$ at 29 df vs $86.52$ at 27 df; collinear-column handling), threatening M3 for arm three.
ADOPTED: J reconciliation added to the P2 time box (shared root cause with the SE fix); disclosed internal-to-Python fallback with the df difference reported, flagged at the P5 gate.
5. MAJOR. Covariate handling ambiguous (simulate with $x_{it}'\hat\gamma$ vs residualize).
ADOPTED: simulate including $x_{it}'\hat\gamma$ at production values; every replication re-estimates the covariate block.
6. MAJOR. Arm-three cost understated (pooled plus two split fits per replication, roughly 2x GMM time; full IDN matrix plausibly 4-5 days of continuous local 14-core compute).
ADOPTED: P5 memo must price the full matrix; calendar updated.
7. MINOR. "Single `chi2.cdf` plug-in point" was wrong (five call sites); BMS df adjustment not mechanical for the minimized-Wald delta inversions.
ADOPTED: corrected.
8. MINOR. Coverage convention (island membership vs convex hull) unpinned.
ADOPTED: island membership, matching the paper's bracketed regions; island counts recorded.
9. MINOR. Parquet schema could not carry J stats, wald_min, island counts, or seeds (M6/M8).
ADOPTED: schema extended.
10. MINOR. A 2 percent failure threshold is unmeasurable at pilot R=20.
ADOPTED: any pilot failure escalates; rate re-checked at the first R=100 tranche.
11. MINOR. Arm-three split uses the true latent regime label (best case vs observed hukou).
ADOPTED: disclosure requirement added to the appendix-prose stage.
12. MINOR. Bounded inversion grids can truncate accept regions and contaminate coverage and empty-set frequency.
ADOPTED as per-cell grid bounds plus a per-rep hit-grid-bound flag.
NOT CARRIED: the reviewer's supporting claim that the calibrated IDN truth is $\hat\phi = -2.44$; the exporter CSV on disk (`IDN_e1_scalars.csv`) records $\hat\phi = -0.5247$, so the specific proximity claim is unverified, though the fix stands on general grounds.
13. MINOR. iid transitory shocks may flatter coverage relative to serially dependent empirical errors.
ADOPTED: disclosure in the calibration report; strengthens the case for keeping M9 armed.

The reviewer verified independently: byte-identical `grc_gmm.py` copies (md5), the existence of all cited calibration inputs, the 16-minute IDN wall-time figure against `BLOCKER.md`, and that the inversion CIs never touch the GMM variance.
