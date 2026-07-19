# Plan: citation and inversion-inference paper update

Date: 2026-07-10

Status: revised after `review-plan`. Phase A completed and verified on 2026-07-10. Phases B--C are sequenced below; any results-changing inference fix requires the approved simulation gate and a recorded implementation decision.

Specification: `quality_reports/specs/2026-07-10-citation-and-inversion-paper-update.md`.

## Priority order

1. Complete the independent literature/BibTeX edit safely.
2. Harden and validate inversion inference; rerun the inversion and counterfactual layers.
3. Revise the methods/results prose against the validated outputs.
4. Decide separately whether missing China/hukou table inputs force a full GMM rerun.

## Phase A: literature edit now

1. Create an execution manifest with paths, timestamps, and SHA-256 hashes for live `main-updated.tex`, `CKT.bib`, protected `main.tex`, `preamble.tex`, and relevant generated artifacts.
2. Search all TeX sources for `herrendorfWagesHumanCapital2018` and `herrendorfWagesHumanCapital2018a`.
3. Copy only `main-updated.tex` and `CKT.bib` to a workspace staging directory.
4. Remove the duplicate `herrendorfWagesHumanCapital2018a` block.
5. Insert the audited Herrendorf--Schoellman description and move Donovan--Schoellman into the main selection-versus-frictions sentence.
6. Run the citation-faithfulness check on the exact staged sentence.
7. Overlay the staged files on a clean full-project copy and compile with:

```powershell
xelatex -interaction=nonstopmode -halt-on-error main-updated.tex
bibtex main-updated
xelatex -interaction=nonstopmode -halt-on-error main-updated.tex
xelatex -interaction=nonstopmode -halt-on-error main-updated.tex
```

8. Search the final log for undefined citations/references, multiply defined labels, and new warnings attributable to the edit.
9. Run the manuscript writing, humanization, and residue checks. Apply only non-substantive corrections within the authorized literature scope.
10. Recheck live hashes. If unchanged, copy only the staged `main-updated.tex` and `CKT.bib` back; then verify all protected-file hashes.

## Phase B: inference hardening and rerun first

This phase follows the approved extension-simulation specification and the separately reviewed implementation plan in `quality_reports/plans/2026-07-10-extension-simulation-study.md`.

### B1. Freeze and reproduce the baseline

1. Record code revisions, environments, package versions, random seeds, numerical tolerances, grid definitions, and hashes of all input `.ster`/CSV files.
2. Reproduce current synthetic coverage summaries and current empirical inversion outputs without changing code.
3. Add or expose diagnostics for restriction count, covariance rank, condition number, pseudoinverse rank loss, grid-bound hits, empty sets, island counts, and failures.
4. Verify candidate-specific covariance and fixed-candidate restriction construction using targeted numerical tests; prohibit ratio-based reformulations.

### B2. Pilot at the risky empirical designs

1. Run the approved R=20 timing/correctness pilot for IDN and TZA.
2. Confirm that the real-data harness reproduces production point estimates within the approved tolerance.
3. Reconcile Python/Stata collinear-column handling and Hansen-`J` degrees of freedom, or explicitly quarantine the Python `J` as an internally consistent simulation diagnostic.
4. Test cell-specific grid expansion and local boundary refinement. Any boundary hit or unexplained rank loss is a failed pilot, not a usable confidence interval.
5. Present projected wall time, memory, and storage before launching the full Monte Carlo.

### B3. Coverage gate

1. Run the pre-specified Monte Carlo in tranches, preserving raw replication-level outputs and failures.
2. Report bias, empirical SE, RMSE, coverage, coverage MCSE, empty-set frequency, island counts, and boundary-hit frequency for each estimand and cell.
3. Score coverage by island membership.
4. Do not ship with fewer than the approved minimum replications; target R=1,000 for the final Econometrica exhibit.

### B4. Finite-sample adjustment branch

1. If any headline interval misses the approved coverage threshold, activate the pre-specified adjustment work rather than rationalizing the chi-squared result.
2. Choose the adjustment backend only after its small-design anchor, IDN-scale runtime, rank behavior, and degrees-of-freedom diagnostics pass.
3. Retain unadjusted chi-squared intervals as an explicit comparison.
4. Re-run the coverage study for the adjusted procedure and require improvement under the pre-specified decision rule.
5. Send the implementation through fresh econometrics and code review before empirical use.

### B5. Empirical rerun scope

1. Rerun the saturated auxiliary OLS, scalar/profile inversions, and joint counterfactual projections for all production cells affected by the final procedure.
2. Regenerate inversion-output CSVs and any tables that report confidence sets; produce a before/after endpoint comparison with flags for changed emptiness, disconnectedness, or boundedness.
3. Do not rerun restricted GMM point estimation unless an input-integrity or table-regeneration gate below requires it.

### B6. Full-GMM decision gate

Run the multi-day GMM sweep only if at least one condition holds:

- required `.ster` inputs cannot be recovered and validated;
- the accepted inference change alters GMM estimation rather than only auxiliary-OLS inversion;
- China/hukou tables cannot be made internally coherent from validated existing estimates;
- a production-point-estimate reproduction check fails.

If none holds, preserve GMM estimates and document that only the inference layer was rerun.

## Phase C: update the paper after results stabilize

1. Draft the inference subsection from the final code/output manifest, including the auxiliary regression, sparse-switcher rule, fixed-candidate restrictions, candidate-specific covariance, reference law, grid/refinement scheme, profile inversion, and nonstandard set shapes.
2. Correct the counterfactual notation to `(phi, Delta_{d0}, Delta_unb)`, the trajectory formula, and the direct interpretation of `Delta_unb`.
3. Replace the unconditional “at least 95%” language with the precise theoretical and simulated coverage statement supported by the final method. Revalidate the separate China 90% projection claim.
4. Map each reported interval and prose claim to a named output and code path.
5. Compile in a clean project clone with `-halt-on-error`, run citation/code alignment checks and manuscript critics, and iterate.
6. Recheck live hashes and copy only author-approved files after confirming no concurrent edits.

## Failure handling

- Concurrent Dropbox edit: stop and restage from the new live files.
- Rank loss with nominal degrees of freedom: fail the affected candidate/cell and investigate; never silently report it.
- Grid-bound hit: expand/refine and rerun; do not label the finite boundary as an endpoint.
- Pilot nonconvergence or any pilot failure: report it before scaling.
- Undercoverage after the first adjustment: stop before empirical/paper updates and escalate to the pre-specified bootstrap-calibration branch.
- Missing China/hukou inputs: keep the literature edit separate and present the exact GMM rerun cost before launching it.

## Deliverables

1. Safe literature/BibTeX patch and clean build log.
2. Reproducible simulation outputs with raw replications and MCSEs.
3. Rank/grid/failure diagnostic report.
4. Before/after empirical inversion comparison.
5. Final code-aligned inference prose and output map.
6. Explicit decision memo on whether the full GMM sweep is necessary.
