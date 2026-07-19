# Plan review: citation and inversion-inference paper update

Date: 2026-07-10

Reviewing as: applied econometrics methodology and academic-publishing specialist.

Plan source: `quality_reports/plans/2026-07-10-citation-and-inversion-paper-update.md` and its linked specification.

Depth: standard, with fresh-context independent critique.

## Best-practices context

1. Weak-identification-robust sets should invert tests evaluated at fixed candidate parameter values rather than rely on estimator-centered intervals.
2. A manuscript should separately identify the estimand, nuisance parameters, restriction vector, covariance estimator, statistic, degrees of freedom, critical value, and asymptotic nature of coverage.
3. Code, claims, and outputs need an explicit mapping, and computational exhibits should be generated without manual alteration.
4. A clean build should follow the final unchanged edit, and unavailable numerical verification should be disclosed.
5. Replacing a live coauthor manuscript requires an immediately pre-write hash comparison after write permission is available.

These principles follow [Stock and Wright (2000)](https://onlinelibrary.wiley.com/doi/abs/10.1111/1468-0262.00151) on GMM with weak identification and the [AEA Data Editor's preparation guidance](https://aeadataeditor.github.io/aea-de-guidance/preparing-for-data-deposit) on explicit code-to-output mapping and clean reproduction.

## Strengths

1. The protected-file boundary is clear and appropriately strict.
2. Staging, hashing, clean compilation, and concurrent-edit detection are strong foundations.
3. The specification separates inversion inference from the Hansen $J$-test and distinguishes scalar, profile, and joint inversions.
4. The plan avoids mixed-generation GRC tables and an unauthorized multi-day GMM rerun.
5. The literature and notation corrections are traceable to existing audits.

## Pre-mortem

Three plausible failure paths dominate.

1. The edited file is not the active Overleaf compile root, or a newer coauthor version is overwritten, so the text either never reaches the paper or destroys concurrent work.
2. The manuscript calls the procedure weak-identification robust and claims coverage without validating candidate-specific covariance, matrix rank, grid approximation, and the distinct $95\%$ and $90\%$ coverage statements.
3. Critics change the manuscript after compilation, while static code inspection is presented as computational verification despite no inversion or GMM execution.

## Weaknesses and gaps

### Red findings

1. Production-target ambiguity.
   Project instructions name `main-sections.tex` as the live compile root, while the inspected Dropbox folder contains `main-updated.tex` but no `main-sections.tex`.
   Compiling only `main-updated.tex` does not establish how the live Overleaf project uses it.
   Fix: make the compile root and delivery semantics an author-approved preflight gate, without inferring permission to edit another root.

2. The methodological validation is weaker than the proposed claims.
   “A $K-1$ Wald statistic at fixed $\phi_0$” does not establish that the restriction covariance is recomputed at each candidate, that the procedure avoids division by a weak denominator, or that nuisance parameters are handled as required.
   Fix: require an exact mapping from the restriction vector, candidate-specific covariance, statistic, acceptance rule, nuisance treatment, and critical value to the code before drafting the manuscript claim.

3. Rank and grid issues may undermine the coverage language.
   The code uses a pseudoinverse while applying the nominal $K-1$ or $K+1$ chi-squared degrees of freedom.
   The current plan does not verify full rank in the reported samples.
   A $0.01$ grid can also miss a narrow accepted component, so “coverage of at least $95\%$” is not automatically a property of the computed lattice.
   Fix: inspect saved rank diagnostics and the implementation's grid convention before asserting coverage; otherwise qualify the numerical set and record the blocker.

4. Verification overclaim.
   With no GMM or inversion run, the plan cannot verify numerical identity, realized rank, accepted-set topology, or table values.
   Fix: describe the review as static code--paper alignment and create a claim-to-code-to-output matrix with hashes of the inspected implementation.

5. Validation occurs before possible final edits.
   The critic step may trigger a fix after compilation and alignment checks, but the plan does not require all checks to rerun afterward.
   Fix: place audit, approved fixes, alignment, and compilation in a loop; deploy only the final unchanged staged hash.

6. Time-of-check/time-of-use race.
   The plan rechecks hashes before requesting filesystem approval, leaving a window for concurrent Dropbox edits while approval is pending.
   Fix: obtain permission first, then hash-check immediately before writing.

### Yellow findings

1. Add an explicit Step 0 stating that no implementation begins until the author approves the specification, plan, target files, and compile-root interpretation.
2. State exactly which object receives the general $95\%$ coverage claim and which China national construction has only a $90\%$ floor.
3. Search every TeX source for both Herrendorf--Schoellman citation keys before deleting the duplicate entry.
4. Define a clean compile as a fresh clone with stale auxiliaries removed, recorded tool versions, `-halt-on-error`, and log checks for unresolved citations and references.
5. Map every affected table-row statement and in-text number to a current output artifact or record explicitly that the present Overleaf table does not display the interval.
6. Keep the roles of Tjernström et al. and Stock--Wright distinct; any additional general-method citation requires separate approval and bibliography validation.

### Green findings

1. Name the staging directory, source paths, artifacts, and log locations in an execution manifest.
2. Specify failure handling after a compile failure or partial deployment: preserve staged and baseline copies, stop, and report without automatically overwriting live files.

## Verdict

REVISE.

The file-protection and editing scope are strong, but the compile-root ambiguity, inference-validity checks, verification limitation, and final hash race are release blockers.

## Revised plan

### Phase 0: authorization and target resolution

1. [NEW] Obtain explicit author approval before editing any manuscript or bibliography file.
2. [NEW] Confirm which TeX file Overleaf currently compiles and what role `main-updated.tex` plays.
   If `main-updated.tex` is not the intended deliverable, stop rather than edit another root by inference.
3. [NEW] Confirm that the approved files, supporting code, audits, XeLaTeX, and BibTeX are available.

### Phase 1: immutable baseline

4. [CHANGED] Create a uniquely named workspace staging directory.
   Record SHA-256, byte size, modification time, and encoding for the editable and protected files.
5. [NEW] Hash the code files and audit reports supporting each manuscript claim.
6. [CHANGED] Copy only `main-updated.tex` and `CKT.bib` to staging, retain untouched baseline copies, and use patch-based edits.

### Phase 2: evidence and methodology gate

7. [NEW] Build a claim-to-evidence matrix covering literature claims, inference claims, code locations, and current output artifacts.
8. [NEW] Record and verify the scalar restriction
   \[
   r_{\underline d}(\phi_0)
   = (\widehat\Delta_{\underline d}-\widehat\Delta_{\underline d_0})
   - \phi_0(\widehat\mu_{\underline d}-\widehat\mu_{\underline d_0}),
   \]
   its candidate-specific covariance, the $K-1$ statistic, asymptotic critical value, and nonrejection rule.
   Confirm that the code evaluates the test at fixed $\phi_0$ and does not divide by the estimated $\mu$ difference.
9. [NEW] Separately document nuisance profiling for $\Delta_{d_N}$, $\bar\Delta$, and $\Delta_{d_T}$ and the joint region for $(\phi,\Delta_{\underline d_0},\Delta_{\mathrm{unb}})$.
10. [NEW] Inspect existing rank diagnostics.
    If nominal degrees of freedom cannot be justified without a new run, stop for author and methods review rather than strengthening the claim.
11. [NEW] Reconcile exact-set theory with the $0.01$ grid, finite support, disconnected components, and the boundary-as-unbounded convention.
12. [NEW] State the general $95\%$ projected-region coverage and the China national $90\%$ floor as distinct objects.

### Phase 3: staged edits

13. [CHANGED] Search all TeX sources for both Herrendorf--Schoellman keys before removing only the trailing-`a` duplicate.
14. [CHANGED] Apply the audited literature wording and move Donovan--Schoellman into the main text.
15. [CHANGED] Add a compact inference block that defines the auxiliary estimates, sample rule, clustering, restriction, statistic, covariance, critical value, grid acceptance, profiling, and possible empty, disconnected, or unbounded sets.
16. [CHANGED] Explicitly distinguish restricted-GMM point estimates and the Hansen $J$-test from auxiliary-regression inversion sets.
17. [CHANGED] Attribute the exact construction to Tjernström et al. (2026); do not add Lee--Liao.
    Add Stock--Wright only after separate author approval.
18. [CHANGED] Correct the counterfactual formulas and parameter labels, including $\Delta_{\underline d_0}$ versus structural $\beta$ and the direct auxiliary interpretation of $\Delta_{\mathrm{unb}}$.
19. [CHANGED] Search for inversion terminology, both BibTeX keys, $(\phi,\beta)$, $\Delta_{\mathrm{unb}}$, Hansen $J$, coverage percentages, and table-row statements.

### Phase 4: iterative review and clean build

20. [CHANGED] Run citation-faithfulness, code--paper alignment, econometric-methods, manuscript-writing, humanization, and residue checks on the staged files.
21. [NEW] Present substantive findings for author approval and apply only approved changes.
22. [NEW] Repeat the searches and reviews after every edit until the staged hashes stop changing.
23. [CHANGED] Create a uniquely named empty project clone under `C:\tmp`, overlay the final staged files, and remove stale LaTeX auxiliaries.
24. [CHANGED] Record tool versions and compile the author-confirmed root with `-halt-on-error` through XeLaTeX, BibTeX, and two final XeLaTeX passes.
25. [NEW] Fail verification on nonzero exits, missing inputs, BibTeX errors, or unresolved citations or references.
26. [NEW] Rerun the claim-to-evidence comparison after the final compile without changing text.

### Phase 5: deployment

27. [CHANGED] Obtain filesystem write approval before the final concurrency check.
28. [CHANGED] Immediately before writing, recompute hashes and modification times for editable and protected targets; stop on any mismatch.
29. [CHANGED] Copy only the final staged `main-updated.tex` and `CKT.bib`, then verify destination hashes.
    If either write fails, stop and report the partial state without automatic rollback.
30. [CHANGED] Rehash `main.tex`, `preamble.tex`, tables, and figures and confirm byte-for-byte identity.
31. [CHANGED] Write a session log with approvals, compile-root decision, manifests, code hashes, evidence mapping, commands, logs, deployed hashes, unresolved table synchronization, and the limitation that no GMM or inversion computation was run.

## Revised acceptance criteria

1. [CHANGED] Author approval and compile-root interpretation are recorded.
2. [CHANGED] Citation-faithfulness and static code--paper alignment pass against hash-identified sources.
3. [NEW] The fixed-candidate test, nuisance treatment, covariance, rank assumption, grid approximation, degrees of freedom, and coverage scopes are supported or explicitly qualified.
4. [CHANGED] The final unchanged staged files compile without unresolved citations or references.
5. [CHANGED] Exactly one approved Herrendorf--Schoellman entry remains.
6. [NEW] Every affected table or in-text statement maps to a current artifact or explicitly states that current tables do not display inversion intervals.
7. [CHANGED] Deployed hashes equal staged hashes while protected files remain unchanged.
8. [NEW] The handoff states that numerical identity and realized inversion diagnostics were not verified because no estimation run occurred.
