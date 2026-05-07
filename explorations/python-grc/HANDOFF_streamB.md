# Stream B handoff: Python GMM port (rcond / sparse-moment / basin-switching)

**Written:** 2026-04-29 from the `lca-inversion` worktree.
**Audience:** future-Claude (or future-Emilia) picking up Stream B work.
**Branch on which Stream B currently lives:** `main`.
**Companion stream:** Stream A (LCA inversion CI) lives on the `lca-inversion` branch in `explorations/python-grc/lca_inversion*.py`; do not duplicate Stream A work here.

---

## What Stream B is

A Python port of Stata's GMM estimator (`run_grc` in `RP7/scripts/0_programs.do`).
The port targets the restricted-GRC specification from the paper.
Goal is twofold:

1. **Cross-language replication.** Confirm Stata's published $\hat\phi$, $\hat\Delta_{\underline d}$, etc.
are reproducible from a different optimizer.
2. **Engine for the simulation (Stream C).** Run $R \approx 100$ Monte-Carlo replications of the GMM with synthetic DGPs to measure the empirical coverage of the standard sandwich CI and the LCA inversion CI.

The Python implementation lives in [`grc_gmm.py`](file:///C:/git/ckt/explorations/python-grc/grc_gmm.py).
The verification harness is [`verify_idn_consumption.py`](file:///C:/git/ckt/explorations/python-grc/verify_idn_consumption.py) + [`verify_stata.do`](file:///C:/git/ckt/explorations/python-grc/verify_stata.do).
Working notes are in this folder ([README.md](file:///C:/git/ckt/explorations/python-grc/README.md), [BLOCKER.md](file:///C:/git/ckt/explorations/python-grc/BLOCKER.md), [FINDINGS_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FINDINGS_SE_phi.md), [FRESH_EYES_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FRESH_EYES_SE_phi.md)).

---

## The rcond / sparse-moment story (resolved, do not re-litigate)

Read these in order before touching `_robust_inv` or `_drop_sparse_moments`:

1. [BLOCKER.md](file:///C:/git/ckt/explorations/python-grc/BLOCKER.md): the original SE($\phi$) gap (Python 0.199 vs Stata 0.0705 = 2.8x), with the initial recommendation to add a "principled collinearity drop."
2. [FINDINGS_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FINDINGS_SE_phi.md): the diagnosis that **Python's variance formula is correct**---feeding Stata's `e(W)` into Python's sandwich computation reproduces every Stata SE to 4 decimals, including SE($\phi$) = 0.0705 exactly.
The gap is a weighting-matrix convention difference (iterated GMM vs Stata's two-step), not a formula bug.
97% of Var($\phi$) loads on a single weak eigendirection of the moment Jacobian.
3. [FRESH_EYES_SE_phi.md](file:///C:/git/ckt/explorations/python-grc/FRESH_EYES_SE_phi.md): the second-pass review.
Argues that "match Stata's W" is a hack that hides a real weak-identification problem.
Recommends 4f (cluster-S formula audit), 4g (Anderson-Rubin / weak-ID-robust CI), 4h (cluster bootstrap) as the right inferences.
This memo is the philosophical backbone of the current approach.
4. [`2026-04-24_rcond-and-sparse-moment.md`](file:///C:/git/ckt/quality_reports/session_logs/2026-04-24_rcond-and-sparse-moment.md): the implementation log.
Tells you what was tried, what failed, and the final decision.

### What was tried for the rcond fix (don't repeat)

Bumping `_robust_inv`'s `rcond` from `1e-10` to `1e-5` was tried and **failed**:

- IDN/cons/urban/unb covs_0 with rcond=1e-5: $\hat\phi$ drifted from $-2.45$ (Stata) to $-1.50$ (Python). 50% drift, not a small-SE issue---the optimizer landed in a different basin because the looser tolerance dropped not just `switcher_11_choice` (sv $\approx 3 \times 10^{-6}$, the rank-deficient direction) but enough of the singular structure around `switcher_27` (3 contributing pids, sv $\approx 9 \times 10^{-6}$) to break identification of `mu:switcher_27`.
- SE($\hat\phi$) became $0.018$, four times *too small*.

Reverted `_robust_inv` to `rcond=1e-10` with an explanatory comment.
**Don't bump rcond again.**

### What replaced it

Added `_drop_sparse_moments(Z, ids, threshold) -> (Z_kept, kept_idx, dropped_counts)` to [`grc_gmm.py`](file:///C:/git/ckt/explorations/python-grc/grc_gmm.py).
For each instrument column, count unique cluster IDs with non-zero entry.
Drop columns below threshold.

Threshold tuning:

- threshold = 5: too aggressive on IDN covs_all---drops switcher_19 / switcher_27 borderline cases that Stata keeps.
$\hat\phi$ diverges 33% (Python $-0.71$ vs Stata $-0.53$).
- **threshold = 2: kept.** Drops only mechanically rank-1 moments (switchers with 0 or 1 contributing clusters).
On IDN covs_all this is `switcher_11` and `switcher_11_choice`.
Defense: rank-1 moments have rank-1 covariance contribution by construction; pseudoinverse is unstable; asymptotic theory unaffected by dropping them.

### The residual gap is real, not a bug

After threshold = 2, IDN covs_all still has Python $\hat\phi = -0.7066$ vs Stata $-0.5256$.
**This is GMM basin-switching, not an implementation bug.**
Element-wise comparison from the 2026-04-24 log (extracted from the local fresh ster):

| Quantity | Stata | Python | Diff |
|---|---:|---:|---|
| $\hat\phi$ | $-0.526$ | $-0.707$ | $-34$% |
| $\kappa$ | $10.832$ | $11.013$ | $+1.7$% |
| $\Delta_{\text{base}}$ | $0.067$ | $0.077$ | $+14$% |
| $\kappa + \phi(\kappa - \mu_{\text{base}})$ (always-treated fit) | $10.669$ | $10.660$ | **$-0.08$%** |

The always-treated fit agrees to $0.01$.
The data does not pin a unique decomposition into $(\phi, \kappa, \Delta_{\text{base}})$; the GMM has a flat ridge in this subspace.
Both Python (iterated GMM) and Stata (two-step GMM) find valid local minima of the same criterion.

Both point estimates ($-0.526$ Stata, $-0.707$ Python) sit comfortably inside the LCA inversion 95% CI of $[-1.23, -0.01]$ (from [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md) on the lca-inversion branch).

---

## Current state of the code

[`grc_gmm.py`](file:///C:/git/ckt/explorations/python-grc/grc_gmm.py):

- `_robust_inv(M, rcond=1e-10)`: kept at `rcond=1e-10`. Comment explains why the bump didn't work.
- `_drop_sparse_moments(Z, ids, threshold=2)`: wired into `RestrictedGRC.fit()` after `_drop_collinear`.
Default threshold = 2 (set instance attribute `sparse_moment_threshold = 0` to disable for diagnostics).
- Iterated GMM converges in 5 outer iterations on IDN; ~16 min wall time.

Diagnostic harness:

- [`test_sparse_moment_drop.py`](file:///C:/git/ckt/explorations/python-grc/test_sparse_moment_drop.py): runs IDN with the drop, prints dropped columns, compares to Stata's cached output.
Outputs in `test_sparse_moment_drop.out` and `test_sparse_moment_drop_covs_all.out`.
- [`compare_S.py`](file:///C:/git/ckt/explorations/python-grc/compare_S.py), [`compare_stata_matrices.py`](file:///C:/git/ckt/explorations/python-grc/compare_stata_matrices.py): the matrix-level comparisons that established Python's variance formula matches Stata's once the W is held fixed.
- [`reproduce_stata_twostep.py`](file:///C:/git/ckt/explorations/python-grc/reproduce_stata_twostep.py): a Python implementation of Stata's two-step protocol (winitial=unadjusted -> theta_1; W_2 = S^{-1}(theta_1); theta_2 = report).
Used during the basin-switching diagnosis.

Stata-side:

- [`dump_stata_S_mata.do`](file:///C:/git/ckt/explorations/python-grc/dump_stata_S_mata.do), [`dump_stata_step1.do`](file:///C:/git/ckt/explorations/python-grc/dump_stata_step1.do), [`dump_stata_vcov.do`](file:///C:/git/ckt/explorations/python-grc/dump_stata_vcov.do): pull Stata's intermediate matrices to CSV for matrix-level Python diff.
- [`verify_stata.do`](file:///C:/git/ckt/explorations/python-grc/verify_stata.do): the canonical Stata driver for the verification harness.
- `grc_weak_id_inference.ado` is in the [lca-inversion branch only](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/grc_weak_id_inference.ado) and is the legacy CI .ado from a prior paper.
**Not used by Stream B.** Don't port it.

---

## Open Stream B items

### High priority

1. **Validate `_drop_sparse_moments(threshold=2)` on CHN and TZA covs_all.** The IDN diagnostic from 2026-04-24 covered IDN only.
We need element-wise diff tables for CHN/cons/urban/unb/covs_all and TZA/cons/urban/unb/covs_all to confirm the always-treated fit agrees to 0.01 there too.
Stata reruns are already done; CSVs in `rerun_workdir/` on the `lca-inversion` branch. Or rerun locally.

2. **Document basin-switching as a feature.** Memo in `quality_reports/reviews/` summarizing the 2026-04-24 finding, framed as direct empirical evidence of weak identification of $\phi$ (consistent with the eigenstructure decomposition in [`FINDINGS_SE_phi.md`](file:///C:/git/ckt/explorations/python-grc/FINDINGS_SE_phi.md)).
Feeds the paper's inference-section writeup.

### Medium priority

3. **Cluster-S formula audit (FRESH_EYES_SE_phi.md, suggestion 4f).** Confirm `_cluster_S` applies Stata's $(N-1)/(N-K) \cdot G/(G-1)$ correction in both the W update and the sandwich meat.
The matrix-level test in [`compare_stata_matrices.py`](file:///C:/git/ckt/explorations/python-grc/compare_stata_matrices.py) already showed exact matches when Python plugs in Stata's W, so the dof factor is correct *at the W level*; the question is whether it's applied consistently across iterated GMM passes.

4. **Cluster bootstrap for $\hat\phi$ (suggestion 4h).** $B = 500$, resample individuals with replacement, re-fit on each, report bootstrap SE.
This is also on the empirical-tables to-do list (panel bootstrap CIs); the work amortizes.
Cost: a few hours per country.

### Lower priority / exploratory

5. **Multistart on step 1 (suggestion 4c).** Run Python step-1 from 50 random initial values; tabulate distinct local minima.
Confirms whether the basin-switching is a single multimodal landscape (multiple valid optima) or a tolerance gap.
Also feeds the secondary multistart simulation from the 2026-04-24 log (Section "Secondary simulation exercise"; pilot $R = 30, K = 3$).

6. **CUE estimator (suggestion 4e).** Implement continuous-updating GMM as a sensitivity.
CUE's SE is path-free.
If CUE's SE($\phi$) lands closer to Python's iterated SE or Stata's twostep SE, that pins which W choice the data supports.

---

## What this hands off to Stream C (simulation)

The 2026-04-24 log decided four points for Stream C:

1. **Per-replication LCA inversion CI is the headline.** Sandwich CI is a sensitivity.
2. **Python's GMM is the per-replication estimator** regardless of which basin it lands in.
The simulation premise is that $\phi$ is weakly identified, not that Python and Stata must agree element-wise.
3. **Use `_drop_sparse_moments(threshold=2)` per replication**, not a fixed global drop.
The set of mechanically-rank-1 moments depends on the synthetic data realization; recompute per-replication for honesty.
4. **Run a secondary multistart simulation** to characterize how common basin-switching is. Pilot $R=30$, $K=3$ ($\sim 18$ hours of Python fits).

`explorations/SIMULATION_PLAN.md` (in the main worktree) needs an update to incorporate these.
[Stage A0 scaffolding hasn't started.](file:///C:/git/ckt/explorations/SIMULATION_PLAN.md)

---

## Cross-references to Stream A

The LCA inversion CI lives on the `lca-inversion` branch and **does not** belong here.
Files there (do not copy):

- [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py): core OLS + grid Wald + island detection.
- [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py): three-country comparison runner.
- [`postprocess_islands.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/postprocess_islands.py): post-processing for island counts and curve diagnostics.
- [`lca_inversion_ci_helper.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion_ci_helper.py): Python helper called from the Stata wrapper.
- [`lca_inversion_ci.ado`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion_ci.ado): the production .ado that delegates to Python.
- [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md), [`results/lca_inversion_islands.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_islands.md): published outputs.

The lca-inversion branch's `docs/TODO.md` carries an entry pointing to this handoff.

---

## Worktree promotion (recommendation)

Stream B currently lives directly on `main`, which means main's working tree carries WIP simulation files.
Cleaner: branch `main` to a dedicated worktree branch (e.g., `simulations` or `stream-b-gmm-port`), `git worktree add` for it, and continue Stream B there.
That keeps `main` clean and gives Stream B a stable home to run multi-day experiments without blocking other branches.

The user has not authorized creating a worktree yet.
This handoff doc is parked here so the user can decide and either (a) point a fresh Claude session at this folder on a new worktree or (b) keep working on main.
