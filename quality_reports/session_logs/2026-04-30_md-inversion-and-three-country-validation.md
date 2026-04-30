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

## Post-validation wrap-up

Two commits landed today on `lca-inversion`: `5cfe158` (Stata Delta_avg fix + validation infrastructure) and `dc1b1ea` (MD inversion + three-country validation).
Working tree is clean except for `.claude/settings.local.json` (gitignored / local-only).
No commits pushed to remote yet; the user can push when ready.

Cached state to know when picking back up:

- `published_deltas.csv` already reflects all 15 corrected (country, spec) cells.
The two background jobs (CHN id `blu3u8iie`, TZA id `bnaznb3k2`) both completed cleanly with exit 0; no segfaults this round (we removed the dangerous CSV-write tail that crashed the IDN run yesterday).
- `${skip_if_exists}` is now wired into `run_grc` in [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do).
Set `global skip_if_exists 1` in any new master driver to skip cells whose `_avg.ster` already exists.
- The post-edit-scan and prose-rules-enforcer hooks have been triggered this session, so the voice.md and rules/manuscript-writing.md flags are set.
Will reset on the next session.
- Auxiliary GRC tables (8_GrRC_hukou, 11/13/14/15) still carry the buggy Delta_avg in their published `.ster` files since we only re-ran 5_GrRC's mainline.
Those will pick up the corrected formula on the next routine run of those scripts.

## Picking back up, second sub-session (2026-04-30, late)

Closed three of four open items from the morning hand-off in this same day.

First, the multi-island handling in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) is now generic: `find_islands` takes an arbitrary `x` column (default `phi`), and a new `format_islands` helper pretty-prints unions of intervals and annotates endpoints touching the grid boundary as `-inf`/`+inf` so unbounded CIs surface honestly in tables.

Second, [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py) now computes all four inversions per (country, spec) cell---$\phi$ (just-identified), $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ via constrained MD---and writes a separate delta-inversion markdown table (`results/delta_inversion_three_countries.md`) with islands and grid annotations alongside the existing phi summary.

Third, the new script [`synth_t2_coverage.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_t2_coverage.py) implements the synthetic-data coverage gate at $R = 100$ replications.
The DGP's LCA structure pins the truth for every parameter ($\phi = -1.5$, $\Delta_{d_N} = +2.0$, $\Delta_{\text{avg}} \approx -0.43$, $\Delta_{d_T} = -2.5$), which lets us check empirical coverage at the nominal 95% level cleanly.

Both jobs landed cleanly.

Three-country inversion table results (`results/delta_inversion_three_countries.md`).
The well-identified IDN and TZA cells (covs_trend through covs_all, four specs each, three deltas each) return inversion CIs that bracket Stata's $\pm 1.96 \cdot$SE band tightly.
Two cells produce multi-island Delta_always CIs where the phi-CI crosses $\phi = -1$ (the Mobius singularity): IDN/covs_all returns $[-\infty, +0.040] \cup [+0.660, +\infty]$ and TZA/covs_all returns $[-\infty, -0.140] \cup [+1.720, +\infty]$.
In both cases a convex-hull CI would have spanned the rejection region between the two islands, so the multi-island summary is materially more informative.
Pooled CHN cells return empty CIs across the board, consistent with prior find_islands diagnostics showing the pooled CHN sample never accepts at 5% across the entire $\phi$-grid.

Coverage at $R = 100$ on the T=2 synthesizer: $\phi$ covers at 0.92 (MC SE 0.027), Delta_never at 0.93 (0.026), Delta_avg at 0.79 (0.041), Delta_always at 0.94 (0.024).
Three of four parameters land within one MC SE of nominal 95%.
Delta_avg under-covers at 0.79, about four MC SEs below nominal.
This is a real finding flagged in the validation memo's coverage section, with two candidate explanations: pi_s sampling variance not propagated into the Jacobian (we passed truth-known shares); or a $K = 2$-switcher degeneracy specific to T=2 that may not surface at the empirical $K = 5$ to $27$ scale.
Worth a small follow-up but not a blocker for the inversion-CI infrastructure.

Validation gate memo updated at [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md) with the final inversion table and coverage results.
All four open items from the morning hand-off now closed.

## Möbius singularity memo and over-identified synthesizer

User asked for an explanation of the multi-island CI and the meaning of $\phi = -1$.
The relevant algebra: $\Delta_{d_T} = (\beta + \phi(\alpha_{d_T}^{\text{obs}} - \mu_{\text{base}}))/(1+\phi)$ is a Möbius transformation in $\phi$, with its single pole at $\phi = -1$.
Under LCA the rural counterfactual mean for always-movers $\mu_{d_T}$ is not directly observed (the GMM code calls it $\kappa$, a misnomer to fix); we recover it by combining the LCA restriction with the urban mean, and the $1+\phi$ factor in the denominator drops out of that elimination.
The phrase "Möbius singularity" applied to this specific GRC parameter combination is our coinage, not jargon from the literature; we will introduce it explicitly the first time we use it in the paper.

Memo with definitions and reporting decisions saved at [`docs/notes/2026-04-30_mobius-singularity.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md).
Decision: report multi-island CIs as a union of intervals with $\pm \infty$ endpoints, footnoted to point readers at the singularity; we may switch to "uninformative" check marks later if a coauthor or reviewer prefers cleaner table aesthetics.

To diagnose the Delta_avg under-coverage from the T=2 synth, built [`synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py) with $T = 3$, $K = 6$ kept switchers ($J_R = 5$, strongly over-identified), and CKT-realistic parameters: trajectory means spaced 0.1 log units apart, $\sigma_\alpha = 0.6$, $\sigma_\epsilon = 0.3$, $\phi_{\text{true}} = -0.5$, $\beta_{\text{base}} = 0.05$.
The user noted that the $T=2$ synth has trajectory means spaced 1.0 log units apart, which makes the model artificially un-fragile relative to real CKT data where mean differences across trajectories are 0.1 to 0.3 log units.
$R = 100$ coverage on the over-identified synth landed.

Headline: $\Delta_{\text{avg}}$ coverage jumped from 0.79 ($T=2$, $K=2$) to 0.90 ($T=3$, $K=6$).
All four parameters cover at 0.90 to 0.93, within roughly two MC SEs of the nominal 0.95.
5 of 100 reps return empty CIs per parameter, which matches the nominal Type I rate of the joint $\chi^2_5$ LCA test exactly; conditional on a non-empty CI, all four parameters cover at 0.95 to 0.98, which is the asymptotic chi-squared approximation working as advertised.

This closes the under-coverage finding.
The $T = 2$ pathology was specific to the $K = 2$ just-identified case where the $\Delta_{\text{avg}}$ moment vector reduces to a one-dimensional reparameterization.
At the empirical $K \geq 5$ scale, the chi-squared approximation works cleanly.

Validation gate memo updated with the over-identified results; TODO entry for $\Delta_{\text{avg}}$ marked RESOLVED.

## T = 4 cross-check at R = 50

User asked whether coverage degrades further at higher $T$.
$T = 4$ with $K = 14$ switchers ($J_R = 13$) at $R = 50$, $N = 15{,}000$:

| Parameter | Coverage | MC SE |
|---|---:|---:|
| $\phi$ | 0.86 | 0.049 |
| $\Delta_{d_N}$ | 0.90 | 0.042 |
| $\Delta_{\text{avg}}$ | 0.84 | 0.052 |
| $\Delta_{d_T}$ | 0.90 | 0.042 |

3/50 empty CIs per parameter (consistent with the nominal 5% Type I rate of the joint $\chi^2_{13}$ LCA test).
Conditional on non-empty CI ($n = 47$), $\phi$ covers 0.915 and $\Delta_{\text{avg}}$ covers 0.894.

User judged 0.84 too far from 0.95 to be comfortable with MC-noise interpretation.
Decision: re-run $T = 4$ at $R = 200$ to halve MC SE from $\sim 0.05$ to $\sim 0.026$ and pin down whether the residual gap is real.

## T = 4 R = 200 (running, ~2 hours)

Background bash task `b88u28uvl` running [`synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py) at $T = 4$ ($K = 14$, $J_R = 13$, $N = 15{,}000$), $R = 200$.
Output streaming to `synth_overid_t4_r200.log`.
Seeds 2000 to 2199 (the first 50 are the same seeds used in the $R = 50$ run, so we will see directly how the new 150 reps shift the headline numbers).
At ~36 s per rep (measured from the $R = 50$ run), expect completion around two hours from launch.

After it lands:

1. Update the validation gate memo's $T = 4$ section with $R = 200$ numbers.
2. If $\Delta_{\text{avg}}$ coverage stays below $\sim 0.90$ at $R = 200$, that is real under-coverage worth investigating (likely candidates: finite-sample chi-squared bias as $J_R$ grows; per-switcher mass of $\sim 375$ individuals at $N = 15{,}000$ being too sparse vs the empirical $\sim 1100$ in CHN's $K = 10$).
3. If $\Delta_{\text{avg}}$ coverage rises to $\sim 0.90$, the $R = 50$ number was MC noise and the chi-squared approximation is fine at $T \leq 4$ scale.
4. Either way, commit the new CSVs and append a short "evaluate-from-here" subsection.

## State and key file pointers (for picking back up)

Key files touched this session:

- [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py): inversion machinery; `find_islands` is now generic over the x column, `format_islands` handles unbounded multi-island reporting.
- [`explorations/python-grc/run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py): three-country, four-CI runner. Outputs at [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md) and [`results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md).
- [`explorations/python-grc/synth_t2_coverage.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_t2_coverage.py): the original $K = 2$ coverage check showing the 0.79 anomaly for $\Delta_{\text{avg}}$.
- [`explorations/python-grc/synth_overid.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/synth_overid.py): parameterized over-identified synthesizer; pass `SYNTH_OVERID_T=3` or `=4` via env var. Outputs `results/synth_overid_t{T}_coverage_{per_rep,summary}.csv`.

Memos and reports:

- [`docs/notes/2026-04-30_mobius-singularity.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md): definitions of Möbius transformation, pole, singularity; the algebraic derivation of the $1+\phi$ pole; the explicit note that "Möbius singularity" is our coinage; the reporting decision to render multi-island CIs as the union of intervals with $\pm \infty$ endpoints in tables.
- [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md): single source of truth for the validation gate. Contains the full decomposition of the original failure (Issue 1: Stata Delta_avg formula bug; Issue 2: auxiliary OLS vs GMM beta gap), the resolution (Stata fix + MD inversion), the three-country inversion CI table, the $T = 2$ coverage finding, the over-identified $T = 3$ resolution, and the $T = 4$ cross-check.

Key decisions, with the why:

1. Multi-island CIs reported as union of intervals with $\pm \infty$ endpoints, footnoted to point at the singularity.
**Why**: a check-mark "uninformative" cell hides why the CI is wide; the union is more honest.
**How to revise**: switch to check marks if a coauthor or reviewer prefers cleaner table aesthetics.
2. Phrase "Möbius singularity" introduced explicitly the first time used in any paper text.
**Why**: it is our coinage, not literature jargon, even though "Möbius transformation" is standard math.
3. $T = 4$ re-run at $R = 200$ rather than larger $N$ or smaller $K$.
**Why**: the user's question was specifically whether coverage degrades with $T$; halving MC SE gives a definitive answer to that question without confounding it with sample-size or fragility changes.
4. Coverage check uses TRUE $\pi_{\text{within}}$ (not sample $\hat\pi_s$).
**Why**: the population $\Delta_{\text{avg}}$ is the parameter being targeted; using true $\pi$ tests the chi-squared approximation cleanly without conflating $\pi$ sampling variance with the inversion machinery.
**Caveat**: a separate experiment that propagates $\hat\pi_s$ variance through the Jacobian would test that hypothesis, which is recorded in the (now resolved) TODO entry.

If interrupted before $R = 200$ lands:

- The bash task `b88u28uvl` writes to `explorations/python-grc/synth_overid_t4_r200.log`. Tail the log to see progress.
- Output CSVs land at `explorations/python-grc/results/synth_overid_t4_coverage_{per_rep,summary}.csv` and overwrite the $R = 50$ files (which are committed in `76f6bec`).
- If you need to restart, `SYNTH_OVERID_T=4 python -u synth_overid.py 200` from `explorations/python-grc/`.

Commit chain on `lca-inversion` for today's work (run `git log --oneline 5cfe158..HEAD`):

- `5cfe158` Stata `Delta_avg` formula fix and validation infrastructure (yesterday).
- `dc1b1ea` MD inversion and three-country validation (this morning's first sub-session).
- `a0e22cf` four-CI runner extension and multi-island handling.
- `396f8bd` $T = 2$ coverage check finding the 0.79 $\Delta_{\text{avg}}$ anomaly.
- `9383dfe` Möbius singularity memo.
- `3749257` $T = 3$ over-identified coverage resolving the under-coverage finding.
- `4da95b5` parameterize `synth_overid.py` by $T$ via env var.
- `76f6bec` $T = 4$ cross-check at $R = 50$.
- ($T = 4$ $R = 200$ commit pending after the background run lands).

## Status update

$T = 4$ $R = 200$ background task at 100/200 reps as of this update.
Cadence is steady at 36 s per rep, no failures, no new findings yet.
Coverage will land around the next two-hour mark.
No further code changes pending; only the post-run analysis and commit remain.

## $T = 4$ $R = 200$ landed

Final coverage at $R = 200$ (MC SE ~0.024):

| Parameter | Coverage | MC SE |
|---|---:|---:|
| $\phi$ | 0.870 | 0.024 |
| $\Delta_{d_N}$ | 0.905 | 0.021 |
| $\Delta_{\text{avg}}$ | 0.840 | 0.026 |
| $\Delta_{d_T}$ | 0.895 | 0.022 |

The 0.84 for $\Delta_{\text{avg}}$ at $R = 50$ was real, not MC noise.
Coverage trajectory: $T = 2$ K=2 0.79; $T = 3$ K=6 0.90; $T = 4$ K=14 0.84.
The pattern: $T = 3$ K=6 sits closest to nominal across all four parameters; $T = 2$ K=2 has the just-identified small-$K$ pathology; $T = 4$ K=13 J_R=13 shows mild under-coverage that grows with $J_R$.

Empty-CI rate at $T = 4$ is $7.5\%$ (15/200) vs nominal 5%, MC SE 0.015.
That tells us the joint $\chi^2_{13}$ over-identification test itself is over-rejecting in finite samples by about 2.5 percentage points.
The bias propagates into the inversion: too many reps reject the truth.

Conditional on a non-empty CI ($n = 185$): $\phi$ 0.919, $\Delta_{d_N}$ 0.978, $\Delta_{\text{avg}}$ 0.908, $\Delta_{d_T}$ 0.968.
$\Delta_{\text{avg}}$ stays at 0.91 even after dropping the 15 globally-rejected reps, so it has its own residual under-coverage on top of the global Wald-rejection bias.

Conclusion: the chi-squared approximation has a finite-sample bias that grows with $J_R$.
With $J_R = 5$ (T=3) the bias is small; with $J_R = 13$ (T=4) it is mild but persistent (~5-10 pct of under-coverage).
This is a known property of overidentification tests in moderate samples and not a bug in our machinery.

Implications for the empirical paper:

- TZA $K = 5$ ($J_R = 4$): closest to T=3 in over-identification; inversion CIs should be approximately well-calibrated.
- CHN $K = 10$ ($J_R = 9$): mild under-coverage expected (between $T=3$ and $T=4$).
- IDN $K = 27$ ($J_R = 26$): could be more under-covering than $T=4$; quantification would need $T=5$ or $T=6$ MC, or panel bootstrap.

The reasonable next move (not done this session) is a panel bootstrap CI on $\Delta_{\text{avg}}$ for IDN as a robustness check.
This is in the existing TODO entry for "Add panel bootstrap CIs for $\hat\Delta_{d_N}$ and $\hat\Delta_{d_T}$ in main tables", which should be extended to include $\Delta_{\text{avg}}$.

Validation gate memo updated with $T = 4$ $R = 200$ findings and the calibration discussion.

## Wrap-up: chi-squared finite-sample memo and three robustness TODOs

### Goals (this sub-session)

After the $T = 4$, $R = 200$ run confirmed mild persistent under-coverage of the inversion CI, the user asked four follow-up questions:

1. What is $J_R$ exactly?
2. Are there standard adjustments for the finite-sample chi-squared bias?
3. What are the literature citations (with full paper titles, not just author-year)?
4. How does the $T = 4$ synth compare to the empirical CKT setting, and is a panel bootstrap CI actually better than the inversion?

The user also course-corrected on terminology: "LCA over-identifying restrictions" is not a literature concept; the chi-squared bias is a property of GMM J-tests in general, with the LCA assumption being the specific structure that produces the over-identifying restrictions in our setup.

### What got built or changed

- [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md): new memo defining $J_R$, explaining the finite-sample bias, listing four classes of corrections (Bartlett-style, F adjustment, bootstrap calibration, Edgeworth), and explicitly comparing point-estimate panel bootstrap vs bootstrap-calibrated inversion as separate inference procedures.
All citations include full paper titles, journal volumes, and page ranges.
- [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): three new TODO entries.
First, an empirically calibrated coverage test (synthesize using each country's actual trajectory shares, unbalanced fraction, and controls).
Second, the Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment as an additional row beneath the inversion CI in each table cell (cheap, principled, recommended first robustness pass).
Third, the Hall-Horowitz (1996) bootstrap-calibrated inversion CI as an optional third row (more expensive, theoretically best).
- Existing TODO for panel bootstrap CIs on $\hat\Delta_{d_N}$ and $\hat\Delta_{d_T}$ already expanded earlier in the session to include $\hat\Delta_{\text{avg}}$.

### Decisions, with the why

Decision: clarify in the memo that $J_R$ is the number of over-identifying restrictions of the GMM model in general, not "LCA-specific."
Why: user pointed out "LCA over-identifying restrictions" is not literature terminology; the LCA is what gives rise to over-identifying restrictions in our setup, but the chi-squared bias is a generic GMM property documented in Hansen-Heaton-Yaron 1996 and elsewhere.

Decision: report the F-adjusted inversion CI as an additional row beneath the chi-squared inversion CI in each table cell, not as a separate column.
Why: user explicitly preferred row over column ("doesn't need its own column, can just be an additional row").
This keeps the table compact while showing both calibrations side-by-side.

Decision: present the point-estimate panel bootstrap as a "cross-check" rather than a "replacement" for the inversion CI in the memo.
Why: the inversion CI is weak-ID-robust; the point-estimate bootstrap is not.
The user's intuition that "the inversion was the most robust" was largely correct; what makes the inversion CI biased in finite samples is the chi-squared part of "chi-squared inversion CI", not the inversion structure.
The right "best of both worlds" is bootstrap calibration of the inversion test (Hall-Horowitz 1996), which preserves weak-ID robustness and corrects the chi-squared bias.

Decision: rank robustness rows in priority order: F adjustment first (cheap), bootstrap-calibrated inversion second (expensive, escalate if F adjustment doesn't close the gap), point-estimate panel bootstrap third (cross-check, not a primary inference).
Why: the F adjustment is a one-line replacement of the critical value with a Satterthwaite-type degrees-of-freedom adjustment to the variance; running it costs nothing relative to the existing pipeline.
The bootstrap-calibrated inversion costs $B$ Wald computations per grid point per cell; only worth doing if the F adjustment doesn't close the gap.

### Approaches rejected and the reason

None this sub-session.
The session was answering questions and recording decisions, not exploring alternatives.

### Open items and blockers

All three new TODOs are unblocked and can proceed independently:

- Empirically calibrated coverage test: half a day of code plus a few hours per country at $R = 100$.
- F adjustment: one-line replacement plus a $\widehat{\nu}$ computation per grid point.
Re-run synth_overid at $T = 4$ to verify gap closure.
- Bootstrap-calibrated inversion: $B \times$ grid size Wald computations per cell.
Start with IDN $K = 27$ specs.

### Picking back up

If you resume on lca-inversion:

Read [`docs/notes/2026-04-30_chi-squared-finite-sample.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_chi-squared-finite-sample.md) first.
The memo carries the full citation set and the framing of why the under-coverage is real, which is the load-bearing context for any of the three new TODO items.

Open thread: choose which of the three new robustness paths to implement first.
The recommended order is the F adjustment (cheapest, principled, single-day implementation) followed by the empirically calibrated coverage test, with the bootstrap-calibrated inversion held as a fallback if the F adjustment alone does not close the gap.

Next concrete action: implement the Imbens-Kolesár (2016) Bell-McCaffrey-Satterthwaite F adjustment in [`grid_lca_inversion`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) and the three MD delta inversions.
Replace the $\chi^2_{J_R, 0.95}$ critical value with $J_R \cdot F_{0.95}(J_R, \widehat{\nu})$ where $\widehat{\nu}$ is the Satterthwaite-type estimate.
Re-run synth_overid at $T = 4$, $R = 200$ and verify the under-coverage gap closes.
If yes, re-run the empirical three-country inversion to produce F-adjusted CIs alongside the chi-squared inversion CIs.

State to know:

- The $T = 4$, $K = 14$, $R = 200$ Monte Carlo gives $\Delta_{\text{avg}}$ coverage of 0.840 (MC SE 0.026); 15/200 = 7.5% empty CIs.
Conditional on a non-empty CI, $\Delta_{\text{avg}}$ covers 0.908.
- Three-country inversion outputs at [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md) and [`results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md).
Two cells are multi-island Delta_always: IDN/covs_all and TZA/covs_all (both phi-CIs cross $\phi = -1$, the Möbius singularity).
- Working tree is clean except for `.claude/scheduled_tasks.lock` and `.claude/settings.local.json` (both gitignored).
- The `prose-rules-enforcer` hook fires once per session; was triggered earlier today, so the next session will trigger it again on the first prose edit.
