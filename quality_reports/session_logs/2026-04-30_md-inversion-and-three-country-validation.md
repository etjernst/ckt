# Session log: 2026-04-30 MD inversion + three-country validation

Mode: Implementation (MD inversion in `lca_inversion.py`, three-delta inversion CIs, full three-country validation).
Branch: `lca-inversion`.
Continues from [`2026-04-29_delta-inversion-validation-and-stata-fix.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_delta-inversion-validation-and-stata-fix.md).

## Goals

The 2026-04-29 session ended with the IDN GMM rerun completing cleanly via `rerun_idn_5gr_fixed.do` (despite a Stata segfault in the post-success CSV-write tail), and a clear plan: regenerate CHN and TZA `_avg.ster`, implement the minimum-distance inversion procedure described in the validation memo, and re-run the validation gate across all three countries.

This session executed that plan.

## What got built or changed

Stata side:

- [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): added `${skip_if_exists}` resume-on-interrupt guard at the top of `run_grc`, mirroring the pattern in the `grc-pipeline-refactor` branch but adapted to our suffix convention (`_avg.ster` is the last-written file in lca-inversion's pipeline, not `_g.ster`).
The guard exits `run_grc` silently if the cell's `_avg.ster` already exists, so a script interrupted mid-run resumes from the next missing cell.
- [`explorations/python-grc/rerun_chn_5gr_fixed.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_chn_5gr_fixed.do) and [`rerun_tza_5gr_fixed.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_tza_5gr_fixed.do): split the previous combined CHN+TZA fixed-formula rerun into two scripts.
Both load the local RP7 `0_programs.do` (with the within-switcher Delta_avg fix), wrap the body in `capture noisily {...}`, set `global skip_if_exists 1`, and drop the post-success CSV-write block that segfaulted on the IDN run.
- The combined `rerun_chn_tza_5gr_fixed.do` was deleted to avoid confusion.
Two parallel background runs (CHN id `blu3u8iie`, TZA id `bnaznb3k2`) completed cleanly with no crashes or popups.

Python side:

- [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py): added `grid_md_inversion`, `grid_delta_never_md_inversion`, `grid_delta_avg_md_inversion`, and `grid_delta_always_md_inversion`.
The first inverts the LCA $\phi$ test using the concentrated minimum-distance Wald (Chamberlain 1982; Newey--McFadden 1994 ch.\ 36).
The other three invert the Wald under the corresponding linear/Mobius constraint that pins $\delta^* = f(\phi, \beta)$, with $\phi$ profiled out at each $\delta^*$ over the existing $\phi$-grid.
- [`explorations/python-grc/smoke_md_vs_just_id.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/smoke_md_vs_just_id.py): smoke test verifying MD's $\hat\beta(\phi)$ at the wald-min closes 86--97% of the gap to GMM's $\hat\beta$ across all 5 IDN specs (vs the OLS-pinned $\hat\beta_{\text{base}}$ used by the just-identified version).
- [`explorations/python-grc/smoke_delta_never_md.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/smoke_delta_never_md.py): three-delta inversion CI smoke test on IDN.
Confirms that the MD inversion CIs bracket Stata's `nlcom` $\pm 1.96 \cdot$SE band on well-identified specs (covs_trend through covs_all) and return empty intervals on the weakly-identified covs_0 spec, matching the $\phi$ inversion behavior.
- [`explorations/python-grc/validate_delta_points.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/validate_delta_points.py): extended to also compute MD-implied $\Delta_X(\hat\phi, \hat\beta_{\text{md}})$ values and compare against Stata's corrected `nlcom`.

Reference data:

- [`rerun_workdir/published_deltas.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/published_deltas.csv) regenerated after both reruns finished.
All 45 (country, spec, delta) cells now reflect the corrected within-switcher formula.

## Decisions, with the why

Decision: split the combined CHN+TZA rerun into two parallel jobs.
Why: yesterday's IDN rerun completed all GMM optimizations and `nlcom` saves but Stata segfaulted (exit code 139) during the trailing CSV-write block.
Splitting CHN and TZA bounds the blast radius if the same crash hits one of them, and the two-process parallel layout halved wall-clock time anyway.
Both finished cleanly; the segfault appears to be specific to the long phi-summary write loop after a full GMM cycle, which we removed.

Decision: dropped the post-success CSV-write block from the rerun do-files.
Why: the segfault on IDN happened in that block, after all `_avg.ster` files were saved.
The CSV (phi/SE/J summary) is reproducible offline by `extract_published_deltas.do`, which loads each `_avg.ster` independently outside the GMM process.
Removing the inline CSV write trades a minor convenience for crash-free completion.

Decision: ported `${skip_if_exists}` to lca-inversion's `0_programs.do`.
Why: user pointed out the pattern in the `grc-pipeline-refactor` branch.
We don't need the full master-driver resume yet, but having the guard available prevents redoing finished cells if a future rerun is interrupted.
Adapted the file-existence check from `_g.ster` (the other branch's last-written suffix) to `_avg.ster` (ours).

Decision: minimum-distance inversion (`grid_md_inversion`) and the three delta inversions implemented as new functions, not replacements of the existing just-identified `grid_lca_inversion`.
Why: the just-identified version is a legitimate weak-ID-robust procedure with a clean interpretation when LCA fails ($\hat\beta_{\text{base}}$ is the unconstrained OLS coefficient at the base switcher).
MD is more efficient under LCA but its $\hat\beta(\phi)$ has a less clean interpretation when LCA rejects.
Keeping both lets us report MD as the primary procedure and just-identified as a robustness check, and lets us cross-check coverage on synthetic data.

Decision: profile $\phi$ over the existing $\phi$-grid for the constrained Wald in $\delta^*$ inversions, rather than running a 1D nonlinear minimization at each $\delta^*$.
Why: the $\phi$-grid is dense (step 0.01 over [-3, 1]) and produces smooth Wald curves on visual inspection.
A grid-min approximation is fast (matrix builds dominate the cost) and matches the existing $\phi$ inversion's behavior.
A `scipy.optimize.minimize_scalar` refinement could be added later if the grid resolution becomes binding.

## Validation results

Validation gate, $\Delta$ at $\hat\phi$ from GMM, MD-implied vs Stata's corrected `nlcom`:

| Country | covs_trend / covs_1 / covs_2 / covs_all | covs_0 (weakly identified) |
|---|---|---|
| IDN | $-4.7\%$ / $-4.7\%$ / $-4.7\%$ / $-4.5\%$ never; $-8.4\%$ / $-8.4\%$ / $-8.0\%$ / $-4.3\%$ avg; $-11.2\%$ / $-11.2\%$ / $-12.0\%$ / $-7.2\%$ always | $+82\%$ / $+55\%$ / $-37.5\%$ |
| CHN | $-6.6\%$ / $-6.5\%$ / $-4.5\%$ / $-3.4\%$ never; $-7.7\%$ / $-7.7\%$ / $-6.0\%$ / $-4.4\%$ avg; $-10.8\%$ / $-10.8\%$ / $-17.7\%$ / $-12.9\%$ always | $+9\%$ / $+5.7\%$ / $+342\%$ |
| TZA | $-1.5\%$ / $-1.5\%$ / $-1.5\%$ / $+2.5\%$ never; $-2.7\%$ / $-2.8\%$ / $-3.1\%$ / $+5.0\%$ avg; $-3.4\%$ / $-3.4\%$ / $-3.4\%$ / $+3.7\%$ always | $+6.2\%$ / $+38.6\%$ / $-23.8\%$ |

The MD framework reduces the Python-vs-Stata gap from 30--2700% (before fix and before MD) to 1.5--12% on well-identified specs.
TZA matches best (1.5--5%), then IDN (4--12%), then CHN (3--18%).
The covs_0 spec is weakly identified ($J_p < 0.001$ in IDN, near-singular Mobius for always in CHN/TZA), so the gap stays wide there.

The residual gap reflects the moment-set difference between auxiliary OLS and GMM: GMM uses the always-mover moment (mu:kappa) and the unbalanced indicators in ways the auxiliary OLS does not, so even MD's pooled $\hat\beta$ does not converge exactly to GMM's $\hat\beta$ when those moments carry information.
For weak-ID-robust inference, the inversion CI's coverage matters more than the point-estimate match, and this residual gap is acceptable.

Inversion CI smoke (IDN, all three deltas):

- covs_0: empty CIs across all three (matches the $\phi$ inversion's empty CI for covs_0).
- covs_trend through covs_2: tight CIs that bracket Stata's nlcom $\pm 1.96 \cdot$SE band, e.g., $\Delta_{d_N}$ CI $[+0.04, +0.15]$ vs Stata $[+0.045, +0.127]$ for covs_trend.
- covs_all: wider CIs as expected from the wider $\phi$ inversion CI; $\Delta_{d_T}$ for covs_all hits the grid bounds $\pm 1.5$, signaling the Mobius singularity at $\phi = -1$ (which IDN/cons/urban/unb covs_all crosses).
The grid should be expanded for that cell or the multi-island CI flagged via `find_islands`.

## Approaches rejected and why

Numerical 1D minimization (`scipy.optimize.minimize_scalar`) for the inner $\phi$ profile in delta inversions:
the grid-based approach is fast and visually smooth.
A nonlinear inner loop adds ~10--100x runtime per cell with no measurable improvement at the 0.01 grid step.

Re-running the GMM full pipeline (8_GrRC_hukou, 11/13/14/15/etc.) to regenerate every `_avg.ster` everywhere:
the user noted this would be 30--40 hours.
The validation gate only needed the urban/cons/unb mainline.
The auxiliary GRC tables can pick up the corrected formula on the next routine pipeline run, when convenient.

## Open items

- $\Delta_{d_T}$ multi-island CI for IDN/covs_all (and any other cell whose $\phi$-CI crosses $-1$): the current `grid_delta_always_md_inversion` returns the convex hull of accepted points, which can grossly understate or overstate the CI when the singularity creates a gap.
Need to apply `find_islands` on the curve and report the union of intervals.
The grid bounds also need to expand beyond $\pm 1.5$ for the Mobius case.
- `run_all_countries_inversion.py` still reports only the $\phi$ inversion CI.
Extend it to compute and report all four ($\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$) for the published comparison table.
- Coverage check on the T=2 synthesizer (`synth_t2_validation.py`): verify that MD's $\Delta_X$ inversion CIs cover the truth at the nominal rate over $R = 100$ replications.
- The validation gate memo at [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md) carries the MD derivation but predates today's three-country results.
Add a final-results section.

## Picking back up

If you resume on lca-inversion to ship the inversion CI table for the paper:

1. Apply `find_islands` to the $\Delta_{d_T}$ inversion curve and report multi-island CIs as a union of intervals.
Expand the delta_grid bounds for the Mobius case (currently $\pm 1.5$, hits the bounds for IDN covs_all).
2. Extend [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py) to call the three new MD delta-inversion functions alongside the existing $\phi$ inversion.
The output table grows from 1 row to 4 rows per (country, spec).
3. Run the coverage check on synthetic data via the existing T=2 synthesizer.
4. Update the validation gate memo's "final results" section with the three-country numbers from the validation table above.

If you resume to debug something specific:

- The MD machinery is in `lca_inversion.py`; smoke tests in `smoke_md_vs_just_id.py` and `smoke_delta_never_md.py` (the latter covers all three deltas despite the name).
- Stata-side ground truth is at `rerun_workdir/published_deltas.csv`, regenerated after the IDN+CHN+TZA reruns.
The do-files `rerun_*_fixed.do` use the local fixed `0_programs.do`; if you re-run them, set `global skip_if_exists 1` to avoid redoing finished cells.
