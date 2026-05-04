# Spec: Verdier V2 robust estimator -- finalization for paper table

**Date:** 2026-04-29
**Branch:** `worktree-verdier-wrap-up`
**Mode:** Implementation (produces a paper-bound table and adds production code)
**Owner:** Emilia + Claude

## Goal

Promote the Verdier-style robust GRC estimator (`run_grc_robust_vv` in `RP7/scripts/0_programs.do`) from exploration to production, so it produces the table referenced in the paper's "Robustness to cluster pooling" subsection (`sections/sec_robustness.tex` in the Overleaf-Dropbox folder; placeholder Table~\ref{tab:verdier-robust}).

## Context

The program `run_grc_robust_vv` already exists in `0_programs.do` (lines 2370--2572) and was developed in `explorations/verdier/`.
Earlier exploration scripts (`x_main_comparison.do`, `x_main_comparison_tables.do`) produced one-off results in `x_main_comparison_results.dta`.
The paper section is drafted but the table remains a placeholder.
Outstanding items 3 and 4 from the 2026-04-26 session log are the scope here.

## MUST

- M1.
The new code lives in `RP7/scripts/`, never the top-level `scripts/` junction.
- M2.
A new numbered do-file `17_verdier_robust.do` calls `run_grc_robust_vv` for the three baseline cells: CHN, IDN, TZA on log per-capita consumption with urban as treatment and unbalanced panel.
The full covariate set used in the main table goes in (period FE + the same demographic covariates as `5_GrRC.do`).
- M3.
The driver writes one paper table per country in the main-results format: `output/tables/verdier_robust_CHN_consumption_urban_unb.tex`, `verdier_robust_IDN_consumption_urban_unb.tex`, `verdier_robust_TZA_consumption_urban_unb.tex`.
Each mirrors the structure of the corresponding `GRC_{country}_consumption_urban_unb.tex` (5 columns of progressively-added covariates; rows for $\Delta_{\text{never}}$, average $\Delta$, $\phi$, Individuals, Observations, $J$, $J$ p-value, Converged; with the Time FE / Covariates indicator row at the bottom).
Reports the robust results only.
No side-by-side with the main GMM.
Inputs come from `.ster` files saved by `run_grc_robust_vv`, not re-estimation inside the table block.
The reference for the main-results format is `main-sections.tex` in the Overleaf-Dropbox folder, specifically `sections/sec_results.tex`.
- M4.
For now, the driver runs both onestep and twostep versions of `run_grc_robust_vv` for each country and produces a comparison summary showing $\hat\phi^{\mathrm{rob}}$, $\Delta_{\text{never}}^{\mathrm{rob}}$, $\Delta_{\text{always}}^{\mathrm{rob}}$, average $\Delta^{\mathrm{rob}}$, and `e(converged)` for both versions side by side.
Output goes to a markdown file at `quality_reports/reviews/2026-04-29_verdier-v2-onestep-vs-twostep.md` so I can review and decide which to use in the paper table.
No automatic decision rule; the user picks after seeing the numbers.
- M5.
The robust spec changes only the estimator relative to the main spec.
Cluster-robust SEs at the `vfirst` (village-first-period) level stay.
No AR-inversion CIs, no different cluster level.
- M6.
`0_master.do` includes `17_verdier_robust.do` after `5_GrRC.do`, so the baseline $\hat\phi$ ster files exist when the robust comparison runs.
- M7.
The Converged row in each paper table reports `e(converged)` (Y/N) for each column, mirroring how the main GRC tables already do.
No hard stop on convergence failure; iterate later if any country fails.

## SHOULD

- S1.
A new program `run_grc_robust_vv_overid_bootstrap` in `0_programs.do` implements VV's Footnote-31 bootstrap overID test (project residuals on trajectory$\times$period$\times$switcher cells, F-statistic against GMM-implied $\mu$'s, cluster bootstrap on `vfirst` for the null distribution).
This program is conditional: only used if M4 lands on the onestep branch and the user wants a $J$-analog statistic in the table.
- S2.
The audit (Task #3) writes a short markdown findings note to `quality_reports/reviews/2026-04-29_run-grc-robust-vv-audit.md` listing any rough edges observed in `run_grc_robust_vv` (e.g. default values, missing checks, output-naming mismatch with `run_grc`).
The user decides which to fix.
- S3.
Output `.ster` files follow the existing CKT naming pattern: `grc_robust_vv_{country}_{depvar}_{choice}_{balance}.ster` plus `_always`, `_delta`, `_never`, `_avg` suffixes.
This mirrors what `run_grc` does for the baseline.
- S4.
A session log goes in `quality_reports/session_logs/2026-04-29_verdier-v2-finalize.md` documenting decisions made, the onestep-vs-twostep call, and any audit fixes applied.

## MAY

- A1.
Refactor adjacent unrelated code in `0_programs.do` if encountered during the audit (e.g. trailing whitespace, comment cleanup).
Out of scope unless trivial.
- A2.
Promote selected paper-bound exploration scripts (`x_main_comparison.do`, `x_equivalence_simulation.do`, `x_alpha_pooling_diagnostic.do`) from `explorations/verdier/` to `RP7/scripts/` as numbered do-files.
The user said "we can come back to this," so it stays out of scope for this branch.
- A3.
Add a TV-distance diagnostic line to the table footnote, documenting how close the cluster pooling assumption is to satisfied in each country.
Available from the explorations folder; not in the paper body per the 2026-04-26 D5 decision.

## Out of scope

- AR-inversion CIs for $\phi$ (would change inference simultaneously with estimator).
- Income or balanced-panel specs (the paper's robustness table is for the unbalanced consumption baseline only).
- Hukou or experience splits (already have their own scripts).
- Modifying the existing `run_grc` program.
- Touching anything in the top-level `scripts/` junction or `output/` junction.
- Editing the paper's `.tex` files (a separate session fills the results paragraph once the table numbers exist).

## Risks and mitigations

- **R1: $\hat\phi^{\mathrm{rob}}$ doesn't converge in some country.** Mitigation: report which country failed, leave the table cell blank with a footnote, and document in the session log. Do not paper over with manual restarts unless the user authorizes.
- **R2: Onestep and twostep results differ enough that we're stuck reporting onestep.** Mitigation: implement S1 so the table can still carry an overID statistic. Otherwise footnote per M4.
- **R3: `vfirst` clusters are too sparse for the bootstrap.** Mitigation: the program already prints `nclust_ge10` (clusters with $\geq 10$ switchers); if this is small in any country, document and either use a lower threshold or skip the bootstrap for that country.
- **R4: Naming collision with existing `.ster` files in `output/`.** Mitigation: use the explicit `grc_robust_vv_*` prefix and `replace` flag on save, never overwrite a file from `run_grc`.

## Success criteria

1. `cd RP7/scripts && stata-mp -b do 17_verdier_robust.do` runs cleanly on a machine that has already executed `5_GrRC.do` for all three countries.
2. `output/tables/verdier_robust_consumption_unb.tex` compiles inside `paper/sections/sec_robustness.tex` without warnings, fills the placeholder table, and shows `\hat\phi$ vs $\hat\phi^{\mathrm{rob}}$ for CHN, IDN, TZA with cluster-robust SEs.
3. The session log records the onestep-vs-twostep decision with numerical evidence.
4. All three countries show `e(converged)==1` in the `eststo` results.
