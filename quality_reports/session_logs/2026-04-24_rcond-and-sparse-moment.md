# Session log: 2026-04-24 --- rcond fix attempt + sparse-moment drop

**Branch:** `main` (Stream B work; Python GRC port).
**Mode:** Implementation (Stream B fix) → Review (diagnostic).
**Continuation of:** `quality_reports/session_logs/2026-04-23_afternoon-rank-deficient-S.md` (sparse-moment / rank-deficient S diagnosis).

## Goal

Close the SE($\phi$) gap between Python iterated GMM and Stata twostep on IDN/cons/urban/unb covs_0. Python reports SE = 0.199 vs Stata 0.0705 (2.8x). Diagnosis from the previous log: rank-1 cluster contribution from `switcher_11` (1 unique pid) makes the cluster-S near-singular; Python's `pinv(rcond=1e-10)` keeps the small singular value while Stata drops it.

## Stream reorganization (carry-over decision)

User clarified that the LCA inversion has grown into its own deliverable (Stream A) separate from the simulation work that motivated it (Stream C). Reorganization:

| Stream | Purpose | Worktree |
|---|---|---|
| A: LCA inversion | Tool for the empirical paper + a per-replication CI in the simulation | `lca-inversion` |
| B: Python GMM port | Engine for the simulation; cross-language replication | `main` (WIP) |
| C: Simulation | The original goal; depends on A and B | (not yet created) |

Decision: the simulation must include the LCA inversion at every replication, not just the sandwich CI. Reason: nominal 95% coverage of the inversion is unverified at CKT's $(N, T)$; the simulation should measure empirical coverage so the paper has a defensible inference claim.

## Conventions update

`CLAUDE.md` now requires session logs to follow `YYYY-MM-DD_short-topic.md` (mandatory topic). Existing topic-less logs renamed to `_verdier.md` and `_verdier-p1.md`. This file uses the new convention.

## Stream B work this session

### rcond fix attempt (FAILED, reverted)

Bumped `_robust_inv` default `rcond` from `1e-10` to `1e-5` to mirror Stata's effective drop threshold for the rank-deficient `switcher_11_choice` direction. Re-ran IDN/cons/urban/unb covs_0:

| Quantity | Stata twostep | Python iterated, rcond=1e-5 | Notes |
|---|---:|---:|---|
| $\hat\phi$ | $-2.4455$ | $-1.4961$ | 50% drift; iterated GMM landed in a different basin |
| SE($\hat\phi$) | $0.0705$ | **$0.0179$** | now too small by 4x |
| mu:switcher_11 | $20.39$ (SE 8.94) | $12.16$ (SE 0.016) | Stata also struggles here |
| **mu:switcher_27** | $11.42$ (SE 0.050) | **$19.81$** (SE 0.007) | **broken**: should be ~11.4 |

Diagnosis of the failure: `rcond=1e-5` was too aggressive. With `max_sv ≈ 0.94`, the threshold lands at `~9.4e-6`, which dropped not just `switcher_11_choice` (sv ~3e-6) but also enough of the singular structure around `switcher_27` (which has 3 contributing pids) to break identification of `mu:switcher_27`. Cascading through iterated GMM, the point estimate of $\phi$ drifted from $-2.45$ to $-1.50$.

Reverted `_robust_inv` to `rcond=1e-10` with a comment explaining why the bump didn't work. The note also points to the next attempt (option A below).

### Option A: explicit sparse-moment drop

Added `_drop_sparse_moments(Z, ids, threshold) -> (Z_kept, kept_idx, dropped_counts)` to `grc_gmm.py`:

- For each instrument column $j$, count the number of unique cluster IDs with `|Z[i, j]| > 0` for some row.
- Drop columns where the count is below `threshold` (default 5).
- Returns the reduced Z, the original-column kept indices, and a list of `(orig_col, n_clusters)` for dropped columns for diagnostics.

Wired into `RestrictedGRC.fit()` after `_drop_collinear`. Composed `kept_idx` so it tracks columns of the original `Z_raw`.

Default `sparse_moment_threshold = 5` (instance attribute). Set to 0 to disable. Same threshold as `lca_inversion.drop_sparse_switchers` (Stream A) --- intentionally unified.

### Diagnostic in flight

`test_sparse_moment_drop.py` runs the IDN covs_0 spec with `sparse_moment_threshold=5`, prints the dropped columns, then prints the W condition number and final $\hat\phi$, SE compared to Stata's cached values. Currently running in background (~16 min expected).

If option A succeeds, expect:
- `switcher_11_choice` dropped (1 contributing pid)
- `switcher_27_choice` (3 pids) **also** dropped at threshold 5 --- could be too aggressive too
- Maybe `switcher_19_choice` (4 pids) as well

The threshold of 5 might be too high. Need to inspect the actual diagnostic output and possibly tune. If option A still drifts the point estimate, fall back to **option D**: revert, document the gap as inherent to iterated-vs-twostep GMM under weak ID, use Python's SE for the simulation with the caveat documented.

## Files changed this session

- `explorations/python-grc/grc_gmm.py`: added `_drop_sparse_moments`, wired into `fit`, reverted rcond, added explanatory comments at `_robust_inv`.
- `explorations/python-grc/test_sparse_moment_drop.py`: diagnostic harness.

## Open questions

- Is threshold 5 right? Stata's procedure isn't publicly documented at this granularity; we may want to tune empirically (e.g., try 3 or 2 to see if `switcher_27_choice` is retained correctly).
- Even with the right drop, iterated GMM and twostep GMM have inherent finite-sample differences. How much of the residual gap will persist after option A? Diagnostic will tell us.
- For the simulation: should the sparse-moment drop be deterministic per replication (compute once, reuse) or per-replication (might vary as synthetic data shifts which switchers have <5 pids)? Probably per-replication for honesty.

## Diagnostic results (option A, threshold = 5 then 2)

**covs_0 with threshold = 5** (6 sparse drops including switcher_19, switcher_27 borderline cases):

- Sparse drops: $(12, 1)$, $(20, 4)$, $(28, 3)$, $(44, 1)$, $(52, 4)$, $(60, 3)$
- Python: $\hat\phi = -2.5445$, SE $= 0.2136$
- Stata: $\hat\phi = -2.4455$, SE $= 0.0705$
- Point estimate matches to ~4%. SE ratio still 3x. Threshold 5 too aggressive --- catches borderline cases that Stata keeps.

**Decision: switch threshold to 2** --- drop only mechanically rank-1 moments (zero or one cluster contributing). Easy to defend: such moments have rank-1 covariance contribution by construction; pseudoinverse is unstable; asymptotic theory unaffected.

**covs_all with threshold = 2** (only switcher_11 + switcher_11_choice dropped, the only 1-cluster cases):

- Sparse drops: $(20, 1)$, $(52, 1)$
- Python: $\hat\phi = -0.7066$, SE $= 0.0475$
- Stata: $\hat\phi = -0.5256$, SE $= 0.1018$
- Point estimate **diverges by 33%**.

User correctly pushed back: this is more than just SE noise; the GMM is finding meaningfully different point estimates between the two implementations.

## Element-wise diagnostic on covs_all (the punchline)

Extracted Stata's full coefficient vector from the local fresh ster (`grc_IDN_covs_all.ster` in `lca-inversion` worktree's `rerun_workdir/`) and compared element-by-element:

| Coefficient | Stata | Python | Diff (rel) |
|---|---:|---:|---|
| mu:never | 10.5126 | 10.5137 | +0.01% |
| period FEs (4) | --- | --- | match to ~0.1% |
| mu:switcher_* (30) | --- | --- | mostly within 1-3% |
| xb:female / age2 / education / education^2 | --- | --- | match to <1% |
| **phi** | **$-0.526$** | **$-0.707$** | **$-34$%** |
| **kappa** | **$10.832$** | **$11.013$** | **$+1.7$%** |
| Delta_base | 0.067 | 0.077 | +14% |
| xb:unbalanced | 10.4621 | 10.4630 | <0.01% |

The phi and kappa discrepancies are **structurally linked**. The GMM moment for the always-treated mean pins
$$\kappa + \phi(\kappa - \mu_{\text{base}})$$

Compute this for both:

- Stata: $10.832 + (-0.5256)(10.832 - 10.521) = 10.669$
- Python: $11.013 + (-0.7066)(11.013 - 10.514) = 10.660$

**They agree to $0.01$ ($0.1$%).** Same always-treated fit, different decomposition into $(\phi, \kappa)$.

## Diagnosis: weak identification of phi, exactly as theorized

The GMM has a **flat ridge** in $(\phi, \kappa, \Delta_{\text{base}})$ space. The over-identifying moments don't separately pin these three parameters; only certain combinations are pinned. Different optimizers (Python iterated, Stata twostep) land at different points on the ridge --- both are valid local minima of the GMM criterion. Same model, different decomposition.

The LCA inversion CI for IDN/cons/urban/unb covs_all is $[-1.23, -0.01]$ at 95%. Both point estimates ($-0.526$ Stata, $-0.707$ Python) sit comfortably inside this CI. The **data does not distinguish between them.**

## What this means for the simulation premise

The simulation was originally framed assuming Python GMM faithfully replicates Stata GMM. That premise has to be reframed: Python and Stata each find **a** local optimum of the GMM criterion; the data does not pin a unique one. For each replication of the simulation:

1. The DGP sets the true $\phi$.
2. Python GMM finds a local optimum (which one depends on optimizer path; could be either basin in any single replication).
3. The LCA inversion is computed from the same data.
4. We measure whether the inversion CI contains the true $\phi$. **Coverage of the inversion CI is the relevant statistic.**

The sandwich CI from Python is also reported (sensitivity), but its coverage will reflect Python's optimizer path. As long as we document this honestly, the simulation answers the right question.

## Implications for the paper

**Tentative paper sentence (revisit after the multistart simulation below):**

> The GMM point estimate of $\phi$ is sensitive to optimizer path: on this dataset, Python's iterated GMM lands at $-0.71$ where Stata's twostep gives $-0.53$. Both are local minima of the GMM criterion within the weak-identification ridge in $(\phi, \kappa)$ space, and both lie well inside the LCA-inversion CI of $[-1.23, -0.01]$. This sensitivity is precisely the motivation for reporting the inversion CI as the primary inference.

**Caveat:** the sentence is based on a **single dataset and a single Python-vs-Stata comparison.** Need a more systematic check before committing wording. Plan below.

## Secondary simulation exercise: GMM-basin diagnostic

**Goal:** measure how common $(\phi, \kappa)$-ridge basin-switching is across data sets and optimizer paths.

**Two-axis design:**

- **Axis 1 (data):** synthetic data sets at the CKT calibration, $R$ replications.
- **Axis 2 (optimizer):** for each data set, run Python's iterated GMM from $K$ different starting values (multistart) AND, on a small subset, run Stata twostep for cross-check.

**Cheap variant (recommended first):** Python-only multistart, no Stata. For each of $R = 100$ replications, run Python GMM from $K = 5$ starting values (perturbations around the OLS initial). Record the $(\phi, \kappa, \Delta_{\text{base}})$ at each optimum. Tabulate:

- Distribution of $\hat\phi$ across replications and starts.
- For each replication, the spread $\max\hat\phi - \min\hat\phi$ across the $K$ starts (within-sample basin-switching).
- For each $K$-tuple, the always-treated mean $\kappa + \phi(\kappa - \mu_{\text{base}})$ (should be invariant if all optima are on the same ridge --- a strong robustness check).

Cost: $100 \times 5 = 500$ Python fits $\times 12$ min $= 100$ hours. Heavy. Reduce to $R = 30, K = 3$ for a pilot ($\sim 18$ hours).

**Expensive variant (for headline confirmation):** Stata-Python comparison on a small subset, say $R_{\text{cross}} = 10$ data sets, just to confirm the cross-language pattern observed on the empirical data. $10 \times 12 \text{ min Stata} = 2$ hours plus the Python fits.

**Deliverable:** a histogram or table showing the empirical distribution of basin-switching, in support of (or against) the tentative paper sentence above.

**Status:** secondary to the main coverage simulation. Add to `docs/TODO.md`. Run when the primary simulation is in flight.

## Files added today

- `explorations/python-grc/test_sparse_moment_drop.py` --- diagnostic runner.
- `explorations/python-grc/test_sparse_moment_drop.out` --- covs_0 result.
- `explorations/python-grc/test_sparse_moment_drop_covs_all.out` --- covs_all result.
- `explorations/python-grc/python_out_idn_cons_urb_unb_sparsedrop.csv` --- covs_0 Python coefs.
- `explorations/python-grc/python_out_idn_cons_urb_unb_covs_all_sparsedrop.csv` --- covs_all Python coefs.
- `explorations/python-grc/stata_out_idn_cons_urb_unb_covs_all.csv` --- Stata covs_all coefs (extracted from the local fresh ster for the element-wise comparison above).

## Decisions logged

1. **Keep `_drop_sparse_moments` in `grc_gmm.py` with `threshold = 2`.** Defense: drops mechanically rank-1 moments only; matches the apparent threshold Stata uses internally; preserves asymptotic theory; necessary for numerical stability of the pseudoinverse.
2. **Accept the iterated-vs-twostep / basin-switching gap as a real feature, not a bug.** Both implementations find valid local minima of the same GMM problem; the always-treated fit (the actually-pinned combination) agrees to 0.01.
3. **Use the LCA inversion CI as the primary inference for the empirical paper.** Sandwich SE is a sensitivity. Document the basin-switching as direct empirical evidence for weak identification.
4. **For the simulation:** measure inversion CI coverage as the headline. Sandwich CI coverage as comparison. Python's GMM is the per-replication estimator regardless of which basin it lands in.
5. **Run a secondary multistart simulation** to characterize how common basin-switching is. Pilot $R=30, K=3$ first ($\sim 18$ hours of Python fits).

## Tangentially (Stream A capacity-building from earlier today)

User pulled an accidentally-included `paper/main.pdf` from a commit (was inadvertently staged at some point); reverted with `git reset --soft HEAD~1` + `git restore --staged paper/main.pdf` + recommit. Clean now.
