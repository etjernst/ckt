# Specification: citation and inversion-inference paper update

Date: 2026-07-10

Status: revised after fresh-context plan review. The literature phase is author-approved. Inference-prose edits are gated on the code and simulation work below.

## Objective

Update the author-confirmed target `main-updated.tex` so that its literature discussion accurately describes Herrendorf and Schoellman (2018), moves Donovan and Schoellman (2023) into the main text, and ultimately documents the inversion-based inference used for the paper. Remove the duplicate Herrendorf and Schoellman (2018) BibTeX entry.

The paper must not make stronger coverage claims than the implementation and the CKT-calibrated simulations support. Because existing synthetic evidence shows material undercoverage and the current pseudoinverse can silently reduce rank while retaining nominal degrees of freedom, the inference prose is downstream of an inference-hardening and rerun gate.

## Phase A: authorized literature and bibliography edits

### Must

1. Never edit the protected Overleaf-Dropbox `main.tex`.
2. Limit Overleaf-Dropbox edits to the author-approved `main-updated.tex` and `CKT.bib`; stage and compile them outside Dropbox first.
3. Search every TeX source in the complete Overleaf project for both Herrendorf--Schoellman cite keys before deleting the duplicate.
4. Remove only `herrendorfWagesHumanCapital2018a`; retain the cited, metadata-complete `herrendorfWagesHumanCapital2018` entry.
5. Describe Herrendorf and Schoellman (2018) as combining cross-country census evidence on sectoral wages and human capital with panel evidence on wage gains for workers leaving agriculture in the United States, Brazil, and Indonesia.
6. Preserve the fact that the paper's own panel estimate is for the United States, while the Brazil and Indonesia estimates come from Alvarez and Hicks et al.; neutral wording such as “panel evidence” may keep the sentence compact.
7. State that switchers' wage gains are positive but small relative to sectoral wage gaps and align more closely with the paper's selection view than its technology view.
8. Do not describe the study as estimating rural--urban consumption returns.
9. Move Donovan and Schoellman (2023) from the nearby footnote into the main selection-versus-frictions sentence.
10. Do not add Lee and Liao (2018) in this round.
11. Pass the Herrendorf--Schoellman citation-faithfulness audit before copying the staged edit back.

## Phase B: inference validation and implementation gate

### Must

1. Treat the current code audit as a static alignment check, not as numerical validation.
2. Before drafting coverage language, run the approved CKT extension-simulation study for the IDN high-restriction design and the TZA small-sample/boundary design, following `quality_reports/specs/2026-07-10-extension-simulation-study.md`.
3. In every inversion, verify and record:
   - the candidate-specific restriction covariance;
   - its numerical rank and condition diagnostics;
   - the nominal restriction count and the degrees of freedom actually used;
   - whether the generalized inverse dropped directions;
   - grid-bound hits, disconnected components, empty sets, and failures.
4. Fail loudly on an unexplained rank loss. Do not silently combine a lower-rank pseudoinverse with nominal degrees of freedom.
5. Verify the fixed-candidate formulation directly from restriction vectors and covariance matrices; do not rewrite the estimator as a ratio whose denominator may be weak.
6. Use island membership, not the convex hull, for coverage scoring, and use cell-specific bounds plus boundary flags so grid truncation cannot masquerade as a confidence-set endpoint.
7. Run a small timing and correctness pilot before committing to the full Monte Carlo budget. Present projected compute cost before the full run.
8. If any headline 95% interval undercovers by more than the approved simulation threshold, do not revise prose around the failure. Implement and validate the pre-specified finite-sample adjustment, retain the chi-squared result as a disclosed comparison, and rerun the affected inversion outputs.
9. Do not claim unconditional or finite-sample coverage of at least 95%. State the coverage result actually established by the final procedure and its assumptions. Preserve the separate China national combined-subgroup 90% floor only where its projection argument remains valid after rerun.
10. Keep the inversion statistic distinct from the restricted-GMM Hansen `J` statistic.
11. Do not rerun the multi-day GMM point-estimation sweep merely to validate the inversion. The first rerun is the auxiliary-OLS/inversion/counterfactual layer plus simulations.
12. Escalate to a GMM rerun only if production `.ster` inputs cannot be reproduced or validated, the inference fix changes the GMM estimator itself, or coherent China/hukou tables cannot otherwise be regenerated.

### Should

1. Validate first at the designs where current evidence is most concerning: IDN (`K=27`, 26 restrictions) and TZA (small sample and extrapolation boundary).
2. Reconcile the Python and Stata handling of collinear columns and Hansen-`J` degrees of freedom before using the Python port for the misspecification arm.
3. Use adaptive boundary refinement or a demonstrably fine local grid around each acceptance boundary; retain the production 0.01 grid only if refinement shows it is immaterial for reported endpoints.
4. Preserve a machine-readable execution manifest with code revision, package versions, seeds, cell definitions, grid bounds, tolerances, and output hashes.

## Phase C: paper update after the gate passes

### Must

1. Describe the final, validated implementation rather than the pre-validation code.
2. Include the saturated auxiliary OLS, individual-clustered covariance, sparse-switcher rule, fixed-candidate restriction vector, candidate-specific covariance, set inversion, profile inversions, and empty/disconnected/unbounded-set interpretation.
3. Attribute the exact construction to Tjernström et al. (2026) and use Stock--Wright/Dufour/Kleibergen only for the broader weak-identification rationale as appropriate.
4. Correct the counterfactual parameter labels from `(phi, beta, Delta_unb)` to `(phi, Delta_{d0}, Delta_unb)`.
5. Use `Delta_d = Delta_{d0} + phi(mu_d - mu_{d0})`.
6. Describe `Delta_unb` as the direct coefficient on the lumped unbalanced cell's urban indicator in the auxiliary regression, not as the baseline return plus a shift.
7. State the joint-region restriction count and reference distribution exactly as implemented after validation; do not hard-code `K+1` degrees of freedom if the validated procedure uses a finite-sample or rank-aware reference law.
8. State that restricted-GMM point estimates and inversion confidence sets come from distinct but aligned estimators.
9. Map every manuscript inference claim and every reported interval to a named output file and code path.

### May

1. Keep sparse-cell and computational details in a footnote if the main-text treatment remains complete.
2. Add a short sentence explaining how to interpret empty, disconnected, or unbounded sets.
3. Correct nearby references to table-row ordering once the final regenerated tables are selected.

## File-safety and build requirements

1. Record hashes and modification times for `main-updated.tex`, `CKT.bib`, protected `main.tex`, `preamble.tex`, and relevant tables before staging.
2. Compile a clean full-project clone with `-halt-on-error` and BibTeX; inspect the log for undefined citations/references and multiply defined labels.
3. Re-run citation-faithfulness, code--paper alignment, manuscript critics, humanization, and editorial-residue checks after edits; iterate until the required critics pass or the author accepts a documented exception.
4. Immediately before copying staged files back, confirm that the live source hashes and modification times have not changed. Stop on any concurrent edit.
5. Verify afterward that protected `main.tex`, `preamble.tex`, tables, and figures retain their original hashes.

## Out of scope

1. Adding Lee and Liao (2018).
2. Editing `preamble.tex`, protected `main.tex`, or generated artifacts during the literature-only phase.
3. Silently changing critical values, estimands, samples, covariates, or headline results without an approved implementation plan and recorded before/after comparison.
4. Presenting the base T=2 simulation from Tjernström et al. as validation of CKT's high-`K`, unbalanced, extrapolation setting.

## Acceptance criteria

1. Phase A passes the existing citation-faithfulness audit and the full-project build.
2. Phase B produces CKT-calibrated coverage evidence with Monte Carlo standard errors, explicit failure accounting, rank diagnostics, and no unexplained grid truncation.
3. If a finite-sample adjustment is activated, its implementation passes a fresh methods/code review and improves coverage according to the pre-specified rule before it enters production results.
4. Phase C's prose maps one-to-one to the final implementation and output manifest.
5. `CKT.bib` contains exactly one Herrendorf and Schoellman (2018) entry.
6. Protected files remain byte-for-byte unchanged.
