# Spec: wire the WCR11-corrected inversion into the real-data pipeline

Received from the author 2026-07-22, authored on branch `worktree-extension-sims`; saved verbatim below (formatting only: fenced as delivered).
Plan: [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/plans/2026-07-22-wcr11-inversion-port.md).

---

This file is written to be pasted into a fresh session on the main branch of the CKT repo.
It is a MUST/SHOULD/MAY spec, but it also carries the full context a cold session needs, because the validation work lives on a different branch (worktree-extension-sims) that the implementing session will not have loaded.
Follow the Mode 2 workflow: read this, write a plan to quality_reports/plans/, get approval, then implement.

## What this changes and why

The paper's weak-identification-robust confidence interval for the linear comparative advantage slope phi comes from inverting a joint Wald test of the LCA restrictions across kept switcher trajectories.
The production inversion refers that Wald statistic to a chi squared J R distribution.
A Monte Carlo study calibrated to the Indonesian design showed this over-rejects badly: at the paper's J R = 26 the uncorrected test rejects the true phi 26 percent of the time at a nominal 5 percent level, so the chi squared confidence set covers at roughly 70 percent instead of 95, and the reported interval is too narrow.
The distortion is a few-cluster problem compounding restriction by restriction: sparse switcher trajectories (5 to 20 switching individuals) give clustered variance estimates that are too small in the tails, and summing 26 such noisy quadratic-form contributions inflates the statistic far past its chi squared reference.
The validated fix is WCR11, the restricted wild cluster bootstrap with untransformed restricted residuals and the CV1 clustered covariance in every statistic, in the taxonomy of MacKinnon, Nielsen, and Webb (2023).
In simulation it restores nominal size everywhere on the sparsity-by-restriction-count surface: the Indonesian anchor at J R = 26 goes from 0.264 uncorrected to 0.048 corrected, and the sparsest design from 0.528 to 0.042, with Monte Carlo standard error about 0.010 at R = 500.
This port replaces the chi squared critical values for the phi inversion with the WCR11 bootstrap p-value.

## Where the pieces live

The validated reference implementation and its brute-force oracle are on branch worktree-extension-sims:
sims/src/wcr_bootstrap.py: the WCR11 kernel (ClusterDesign, constrained_ls, projected_wald, wcr11_test, and build_aux_design, which reconstructs the design matrix, outcome, and cluster ids exactly as the production auxiliary OLS does).
sims/src/wcr_oracle.py: the oracle that checks the vectorized kernel against per-draw statsmodels refits.
sims/docs/wcr11_inversion_bootstrap_note.md: the pre-registered algorithm note. This is the specification the kernel implements; read it before porting.
sims/results/inversion_size_remediation/summary/wcr_size.csv: the validated size numbers.
Retrieve those files from that branch (git show worktree-extension-sims:sims/src/wcr_bootstrap.py, or a worktree checkout) rather than reimplementing from the note.

The production code to change:
explorations/python-grc/lca_inversion.py, function grid_lca_inversion. The chi squared line is p_value = 1.0 - chi2.cdf(wald, df=J_R); the accept rule is p_value >= type_one. This is the only statistical object the port replaces for phi.
RP7/scripts/5b_inversion.do: the driver that loops countries and specs and calls attach_inversion_ci.
RP7/scripts/0_programs.do, program attach_inversion_ci (around line 4045): the Stata wrapper that calls the Python bridge attach_inversion_for_stata and writes the results back to the .ster files.
Confirm which lca_inversion.py the pipeline actually imports before editing: the do-file does a bare python: import lca_inversion, so the file on sys.path is the one that runs.
On the simulation branch the worktree copy of attach_inversion_for_stata lags the 0_programs.do call signature (the do-file passes esample= and switchers_kept= kwargs the worktree function does not accept), so verify the main copy is the current one and reconcile if not.

## The port, precisely

At each grid value phi 0, grid_lca_inversion already builds the restriction matrix G(phi 0) (J R times p) whose rows implement (beta s minus beta base) minus phi 0(alpha s minus alpha base).
That G(phi 0) is exactly the constraint matrix C the WCR11 kernel tests, at the identity projection A J = I, J = J R.
So the geometry the simulation validated is the production geometry; nothing about the restriction changes.
What changes is the reference distribution: instead of 1 minus chi squared J R (Wald), the p-value at phi 0 is the WCR11 bootstrap p-value for the null G(phi 0) b = 0.
The bootstrap needs the design matrix X, the outcome y, and the cluster ids, which the current AuxiliaryFit does not carry.
Reuse build_aux_design from wcr_bootstrap.py to reconstruct them with byte-identical columns to fit_auxiliary_ols, build one ClusterDesign per (country, spec) fit, and reuse it across every grid point and every bootstrap draw.
Per grid point the cost is one constrained least squares plus B vectorized draws with no statsmodels refit, so the whole grid sweep stays cheap.

## MUST

Replace the chi squared critical values in the phi inversion with the WCR11 bootstrap.
At each phi 0, compute the WCR11 p-value for G(phi 0) b = 0 using the validated kernel, keep the CV1 covariance and the exact finite-B rule p* = (1 + #{W*_b >= W_obs})/(B_valid + 1), and accept phi 0 into the confidence set when p* > 0.05 (and > 0.10 for the 90 percent set).
Default B = 399, exposed as a parameter.
The restricted-residual bootstrap DGP is refit once per phi 0 (the null moves with phi 0), not once per fit.

Preserve reproducibility.
Draw the G times B Rademacher sign matrix from a documented SeedSequence keyed on (country, spec) and record the key in the run log, so the confidence interval is reproducible from the seed alone.
Record B_valid, tie counts, and per-type invalid-draw counts per grid point, and treat a grid point with B_valid < 0.95 B as a typed failure, never a silent accept.

Parity gate before any reported number.
Port wcr_oracle.py and show the production kernel reproduces the brute-force statsmodels refit to the note's tolerance on at least the anchor case, and reproduces a wcr_size.csv row (for example the IDN anchor at J = 26) to within Monte Carlo error on a shared design.
Vectorized code does not generate a reported CI until the oracle passes.

Regenerate the phi inversion CIs for every country and split.
Indonesia, Tanzania, China national, China rural-first hukou, and China urban-first hukou.

Fix the missing China attachment.
The regenerated tables currently lack the inversion row for China national and both hukou splits because the attachment did not land in those .ster files.
Diagnose why (the attach_inversion_ci e(sample) or base-selection path is the likely culprit), fix it, and confirm the row is present for all three China cells.

Run the corrected inversion for every reported specification, not just the mainline.
5b_inversion.do already loops covs_0, covs_trend, covs_1, covs_2, covs_all; the corrected inversion runs for all of them because the CI prints under every table, main and robustness alike.

Price the compute before running.
Report the cost of the WCR11 inversion across all cells (countries times splits times specs times grid points times B) from a timed pilot on one cell, and get approval before the full regeneration.

## The decision this port must not make silently

The three derived-quantity inversions in the same pipeline, grid_delta_never_md_inversion, grid_delta_avg_md_inversion, and grid_delta_always_md_inversion, still refer a profiled minimum-distance Wald to chi squared.
The simulation validated WCR11 only for the phi joint Wald, not for the profiled-MD statistic, so those three intervals are not yet corrected and correcting them would require a separate validation study.
Under the adopted decision, phi moves to the corrected inversion and derived quantities (the misallocation gap, the never-migrant return) are sourced from the GMM, which covers those correctly in simulation.
So this port corrects phi and must not ship a WCR-corrected phi CI in the same table as an uncorrected chi squared delta inversion CI.
A derived-quantity coverage study is being run on the simulation branch to confirm the GMM covers the never-migrant, within-switcher average, and always-urban returns and the misallocation gap at nominal rates.
Its result settles whether the paper reports GMM intervals for those (the expected outcome, in which case the delta inversion rows are dropped) or needs a validated bootstrap for the profiled-MD inversion.
Do not touch the derived-quantity tables until that study reports; confirm the phi tables with Emilia before touching them.

## SHOULD

Report both inferences in every affected table: the GMM cluster-robust standard error with significance stars, and the WCR11 inversion confidence interval underneath.
Add a table note stating that the inversion confidence interval is the preferred inference for phi, so printing the GMM standard error on top does not silently endorse a number known to under-cover.
Make the table-macro changes this requires in the Overleaf preamble.tex: \GRCtable, \GRCexptable, and \GRChukoutable each need a row for the inversion CI.
Copying regenerated tables into the Overleaf tables/ folder is additive and safe; never edit main.tex or main-updated.tex there without Emilia's approval.
Decide how to report the China urban-first hukou subsample, which is weakly identified and returns an unbounded phi confidence region.
The honest reading is that the data cannot bound phi there; report the region as one-sided or unbounded rather than forcing an interval.

## MAY

Add a Bartlett-type analytic correction as a cheap reference column, if a referee wants a non-bootstrap comparator.
Evaluate the WCR-jackknife variant (WCR31 in the same taxonomy), which MacKinnon, Nielsen, and Webb recommend when leverage is uneven; WCR11 already passed validation here, so this is a robustness extra, not a fix.

## Out of scope

Re-running the GMM. The inversion is decoupled from 4_GrRC.do by design; this port touches only the inversion's reference distribution.
The derived-quantity (delta) inversions, pending the decision above and, if corrected, a separate validation study.
Any change to trajectory construction, sample definitions, or the auxiliary OLS column set.

## Provenance to carry into the plan

The uncorrected size numbers, the mechanism diagnosis, and the validated WCR11 numbers are in sims/docs/p5b_gate_report.md, sims/docs/stage1_sparse_dial_report.md, and sims/results/inversion_size_remediation/summary/wcr_size.csv on branch worktree-extension-sims.
The adoption decision and its rationale are in quality_reports/session_logs/2026-07-22_wcr11-adoption-decision.md on that branch.
