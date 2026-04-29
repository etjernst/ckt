# Session log: 2026-04-29---island detection on LCA inversion CI

Mode: Implementation (exploration fast-track---code lives in `explorations/`).
Branch: `lca-inversion`.

## Goal

Address the "island detection" item from `docs/TODO.md` (added 2026-04-23): walk the saved $(\phi, p)$ curves and check whether any country/spec has multiple disconnected non-rejected regions that the existing convex-hull CI would mask.
The motivating worry was CHN, where pooled-sample LCA fails the J-test and the curve might have local non-rejection pockets.

## What changed

- `explorations/python-grc/lca_inversion.py`: added two pure-post-processing helpers---`find_islands(curve, type_one)` walks the $(\phi, p)$ grid and returns each connected non-rejected interval as `(phi_lo, phi_hi)`; `summary_curve_stats(curve)` returns `max_p` (with `phi_at_max_p`) and `min_wald` (with `phi_at_min_wald`).
- `explorations/python-grc/postprocess_islands.py`: new script. Reads existing `results/lca_inversion_{country}_{spec}.parquet` curves saved by `run_all_countries_inversion.py` (commit `7b9ae93`) and writes `results/lca_inversion_islands.md` (companion to the published comparison md) plus `results/lca_inversion_islands_summary.csv`.
- `docs/TODO.md`: removed the island-detection entry from Active and added a Completed entry pointing to the new artifacts.

The approach is post-hoc on existing parquets, so no re-run of the OLS or the grid sweep was needed and the published comparison md stays canonical.

## Findings

1. **No multimodality.** Every non-empty CI in the 15 country/spec cells (3 countries x 5 covariate specs) is a single connected island at both 95% and 90%. The convex-hull CIs reported in `explorations/python-grc/results/lca_inversion_three_countries.md` are honest---there is no hidden gap to flag in the paper.

2. **CHN's empty CIs are not borderline.** Across all five specs, the highest $p$-value attained on the $[-3, 1]$ grid is $0.017$ at covs_all. At every other CHN spec, max $p$ is $\le 0.009$. The pooled CHN sample rejects the joint LCA restriction at the 5% level for every $\phi$ in the grid, not just at the GMM point estimate. This is stronger evidence than the J-test alone: the J-test rejects pooled-LCA at the GMM $\hat\phi$, while the inversion shows there is no value of $\phi$ at which pooled-LCA is acceptable. Hukou splits are necessary, not optional.

3. **Best-fit $\phi$ is consistent across CHN specs.** The phi-at-max-p values are $-0.24$ (covs_trend, covs_1), $-0.28$ (covs_2), $-0.33$ (covs_all), and $-3.00$ (covs_0; this is the grid endpoint, so the unconstrained max is presumably outside the grid). With covariates the best-fit $\phi$ stabilizes around $-0.3$, which is in the same neighborhood as IDN's and TZA's accepted regions. Pooled CHN data say "if there were a single $\phi$, it would be near $-0.3$, but no $\phi$ fits well enough."

## State at end of session

- Last commit: `7b9ae93` (the previous "Stream A: LCA inversion CI on all 3 countries" commit). This session's changes not yet committed.
- Working tree: 2 modified, 2 untracked files relevant to the change. Pending commit covers `docs/TODO.md`, `explorations/python-grc/lca_inversion.py`, `explorations/python-grc/postprocess_islands.py`, `explorations/python-grc/results/lca_inversion_islands.md`, and `explorations/python-grc/results/lca_inversion_islands_summary.csv`.

## Open next steps (carried)

1. **Apply critic fixes 4, 5, 2** from `quality_reports/reviews/2026-04-23_lca-inversion-code-review.md` (effective-rank dof in `pinv`, symmetric sparse-switcher drop, Stata-style cluster correction). Re-run IDN inversion and compare to sandwich SE.
2. **Port rcond fix into Python `_robust_inv`** for the GMM port (Stream B; tracked in `docs/TODO.md`).
3. **Send the coauthor email** about the ster-collision fix; draft at `docs/communications/2026-04-23_ster-filename-collision-email.md` needs a small update to reflect that the local fix is already in place in RP7.
4. **Smoke-test the rename** end-to-end via `cd RP7/scripts && stata-mp -b do 0_master.do` to confirm the ster-prefix rename runs without collisions across all 5/6/10--16 scripts.
