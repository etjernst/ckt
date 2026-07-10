# Session log: 2026-04-29 delta-inversion spec + Stream B handoff

Mode: Implementation (TODO restructure + handoff doc + spec memo) + Review (econometrics-critic in fresh context).
Branch: `lca-inversion` (Stream A) and `main`/`simulations` (Stream B handoff).
Third log of the day; sibling logs at [`2026-04-29_island-detection.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_island-detection.md) and [`2026-04-29_weak-id-review-and-handoff.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_weak-id-review-and-handoff.md).

## Goals

The user picked up from yesterday's work on the LCA inversion CI for $\phi$ and asked to extend the same machinery to the trajectory-aggregate returns: $\Delta_{d_N}$ (never-movers), $\Delta_{\text{avg}}$ (switcher-share-weighted average), and $\Delta_{d_T}$ (always-movers).
The headline interest is $\Delta_{d_N}$, since that is the most directly reported in the empirical paper's tables; $\Delta_{\text{avg}}$ matches Stata's existing `nlcom` over switchers; $\Delta_{d_T}$ was scoped last because of an anticipated nonlinearity.

Mid-session course corrections, in roughly the order they happened:

- The basin-switching narrative I had carried from earlier sessions was over-stated.
The user pointed out the original Python-vs-Stata divergence was the standard error on covs_0, not the point estimate, and the basin-switching diagnosis rests on a single data point (IDN covs_all element-wise diff).
Drop the proposed basin-switching memo entirely.
- Several TODO items got reprioritized.
Bucket 1 (per-spec keep-list, effective-rank dof, symmetric drop) was postponed because at $N \approx 90{,}000$ these are unlikely to move CIs at the third decimal.
Bucket 2 (cluster correction match) was checked quickly and closed without code change.
Bucket 4 (.ado correctness fixes) was made moot by archiving the legacy `.ado` (it is not used in the active pipeline).
Bucket 5 (smoke test of the `.ster` rename) was deferred indefinitely because it is a 30+ hour pipeline rerun.
- The user noticed Stata's variable naming for `kappa` is misleading versus the paper, and asked for a low-priority TODO entry to rename it across the codebase, gated on the pipeline-refactor branch landing first.
- Stream B (the Python GMM port) got promoted from `main` into a dedicated `simulations` worktree to keep `main` clean and avoid Stream A/B duplication.
- The user wanted me to write a math memo for the delta-inversion extension and have an agent review it in fresh context, rather than coding directly.

## What got built or changed

Code (Stream A inversion machinery on lca-inversion):

- [`explorations/python-grc/lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py): added `find_islands` and `summary_curve_stats` post-processing helpers.
- [`explorations/python-grc/postprocess_islands.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/postprocess_islands.py): new script.
Reads existing `(phi, p_value)` parquets, walks each curve, writes per-cell island counts and curve diagnostics.
- [`explorations/python-grc/results/lca_inversion_islands.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_islands.md) and `_islands_summary.csv`: outputs of the post-processing.

Reviews and specs (lca-inversion):

- [`quality_reports/reviews/2026-04-29_weak-id-code-review.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_weak-id-code-review.md): python-critic + stata-critic findings on the entire weak-ID code surface.
- [`quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-spec-critic.md): econometrics-critic findings on the delta-inversion spec, with my response.
- [`quality_reports/specs/2026-04-29-delta-inversion-extension.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-04-29-delta-inversion-extension.md): the spec memo, revised after critic review.
Status: ready for implementation.

Bookkeeping (lca-inversion):

- [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): heavy restructure.
Active items now include the per-replication LCA inversion CI for the simulation, profile $Q(\phi)$, multistart on Python step 1, and panel bootstrap CIs scoped to $\Delta_{d_N}$ and $\Delta_{d_T}$ (not $\phi$).
Low-priority items: archive `grc_weak_id_inference.ado`, rename `kappa` → `mu_dT` in the GMM code, the bucket-1 critic findings, the smoke test of the rename, the coauthor email.
- Three sibling session logs for today (`island-detection`, `weak-id-review-and-handoff`, this one).

Stream B handoff (main, then mirrored on simulations):

- [`explorations/python-grc/HANDOFF_streamB.md`](file:///C:/git/ckt/explorations/python-grc/HANDOFF_streamB.md) on main (commit `34f6238`) and a revised version on the simulations worktree.
The revision corrected the SE-vs-point-estimate framing and softened the basin-switching claim from "diagnosed" to "tentatively interpreted, not yet independently tested."

Worktree:

- New worktree at `C:/git/ckt/.claude/worktrees/simulations` on branch `simulations`, branched from main's commit `34f6238`.

## Decisions, with the why

Decision: dropped the basin-switching memo from active TODO.
Why: user noted the diagnosis rests on a single data point (IDN covs_all element-wise diff), and the paper does not need it---justification for weak-ID-robust inference rests on the LCA inversion machinery itself, the Tjernstrom Econometrica precedent, and the simulation coverage check.
Python's GMM point estimates are not reported in the paper anyway.

Decision: Stream B promoted to a dedicated `simulations` worktree branched from main.
Why: Stream B was living directly on main and creating duplication with Stream A files on lca-inversion.
A dedicated worktree gives Stream B a stable home for multi-day Monte Carlo experiments and keeps main clean for the empirical paper's pipeline.

Decision: bucket 1 (per-spec keep-list, effective-rank dof, symmetric sparse-switcher drop) postponed.
Why: at $N \approx 90{,}000$ these are unlikely to move CIs at the third decimal; the published inversion CIs in `lca_inversion_three_countries.md` are likely robust to all three.

Decision: bucket 2 closed without code change.
Why: read statsmodels source for `cov_cluster`; `use_correction=True` applies $G/(G-1) \cdot (N-1)/(N-K)$ which exactly matches Stata's `vce(cluster pid)` correction.
The line in `lca_inversion.py:125` already passes that flag.

Decision: archive `grc_weak_id_inference.ado` rather than fix the bugs the stata-critic flagged.
Why: it is the legacy CI .ado from a prior paper, not called by anything in the current pipeline.
The active production wrapper is `lca_inversion_ci.ado`, which delegates to Python via `lca_inversion_ci_helper.py`.
The two MAJOR Stata-critic findings (string-`if` evaluating numeric, post scalar-reference bug) are real but moot under archive.

Decision: rename `kappa` to `mu_dT` across GMM code (added to TODO at low priority, gated on pipeline refactor).
Why: Stata's `_b[kappa]` actually represents $\mu_{d_T}$ (the unobserved rural counterfactual mean for always-movers), while the paper at line 376 reserves $\kappa_{d_T}$ for the observed urban mean $\mu_{d_T} + \Delta_{d_T}$.
Same Greek letter, different objects.
Math in the code is correct; only the variable name is misleading.
Don't do the rename mid-refactor to avoid merge churn.

Decision: cluster bootstrap for $\phi$ removed from the panel-bootstrap TODO entry; scope narrowed to $\Delta_{d_N}$ and $\Delta_{d_T}$ only.
Why: the LCA inversion CI already serves the weak-ID-robust purpose for $\phi$, so a bootstrap on $\phi$ is a third inference (sandwich + inversion + bootstrap) with no marginal information.
The $\Delta$'s have no inversion analog yet (until this spec is implemented), so bootstrap is genuinely useful there.

Decision: profile $Q(\phi)$ and multistart on Python step 1 promoted to standalone TODO entries.
Why: these are the cleanest empirical tests of whether basin-switching is real, instead of inheriting it as a narrative.
User wanted them visible as their own diagnostic items, not buried in a bundled "weak-ID-robust toolkit" entry.

Decision: implement the delta-inversion extension via formal Wald-with-delta-method, not the Mobius-image-of-phi-CI shortcut.
Why: critic flagged the shortcut as anti-conservative because it ignores the sampling variance of $\hat\alpha_{d_T}$ and $\hat\beta_{\text{base}}$ in the conversion.
The formal Wald loses nothing in writeup honesty since both methods produce unbounded sets when the $\phi$ CI crosses $-1$.

Decision: $\Delta_{d_T}$ multi-island CI when the $\phi$-CI crosses $-1$, reported as a union of intervals separated by the singularity.
Why: the singularity is structural ($\phi = -1$ corresponds to $b_U = 0$ in the LCA decomposition $\phi \equiv (b_U - b_R)/b_R$, where urban-skill returns vanish), not a numerical artifact.
Honest reporting beats hiding the gap.

Decision: validation step 1 (Python's OLS-derived $\Delta_X(\hat\phi, b)$ matches Stata's published `nlcom` point estimate) is a precondition gate, not a verify-after step.
Why: it empirically resolves the auxiliary-OLS-vs-GMM controls partialling concern that the critic raised.
If the gate fails, the spec needs revisiting before any inversion CI is reported in a paper table.

Decision: rejected the critic's CRITICAL finding that paper line 401 omits $\beta$ from the always-mover composite.
Why: the paper equation has three terms touching always-movers, and the universal $\Delta_{d_0} D_{it}$ term on line 398 already contributes $\beta$ to all $D=1$ observations including always-movers.
Total fit is $\beta + \mu_{d_T} + \phi(\mu_{d_T} - \mu_{d_0}) = \mu_{d_T} + \Delta_{d_T} = \kappa_{d_T}$, which matches both Stata's GMM and the memo's eq (2).
The critic missed the cross-line term in the paper equation.

## Approaches rejected and why

Mobius-image-of-phi-CI shortcut for $\Delta_{d_T}$: anti-conservative (ignores OLS-coefficient variance), and the formal Wald gives the same qualitative answer when the $\phi$-CI crosses $-1$.

Memo justifying weak-ID-robust inference via basin-switching narrative: rests on one data point, and the paper does not need a bespoke justification (Tjernstrom Econometrica precedent + simulation coverage check do the work).

Cluster bootstrap for $\phi$ specifically: redundant given the LCA inversion CI is already weak-ID-robust.
The empirical-tables bootstrap entry now scopes to $\Delta_{d_N}$ and $\Delta_{d_T}$ only.

Smoke test of the .ster rename: deferred indefinitely.
Full pipeline rerun is 30+ hours of Stata compute; only worth bundling with the next pipeline run we would do anyway.

Bucket 1 fixes from the 2026-04-23 econometrics review: low priority.
Sample sizes make these unlikely to move CIs at the third decimal.

## Open items and blockers

- Implementation of the delta-inversion extension has not started.
Spec is at "ready for implementation" status.
- The simulations worktree exists, but Stream C scaffolding (SIMULATION_PLAN.md update, simulation runner) has not started.
- Profile $Q(\phi)$ and multistart on Python step 1 are standalone TODO entries on the simulations worktree, not started.
- Coauthor email about the .ster collision is pending a small update saying the local fix is already in RP7.
- The kappa rename TODO is gated on the pipeline-refactor branch (`worktree-grc-pipeline-refactor`) landing first.

## Picking back up

**If you resume on lca-inversion to start implementation:**

Read [`quality_reports/specs/2026-04-29-delta-inversion-extension.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-04-29-delta-inversion-extension.md) first.
That memo is self-contained: it carries the math derivations, the Stata-vs-paper notation reconciliation, the seven post-critic decisions, and an implementation sketch with cost estimates.

Open thread: implement the extension, $\Delta_{d_N}$ first.

Next concrete actions, in order:

1. Implement validation step 1 (precondition gate).
Extract Stata's published `nlcom` point estimates for $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ from the IDN/cons/urban/unb `.ster` files in `RP7/output/` (the rename from commit `ff9a665` ensures these are uniquely named: `grc_IDN_urban_covs_*_never`, `_avg`, `_always`).
Compare against Python's $\Delta_X(\hat\phi, b)$ via the auxiliary OLS using equations $(1')$, $(2')$, $(3')$ from the spec.
Expected: sub-percent match.
2. If the gate passes, write `grid_delta_never_inversion` in a new module `delta_inversion.py` next to `lca_inversion.py`.
Mirror the existing `grid_lca_inversion` interface; reuse `find_islands` and `summary_curve_stats` for diagnostics.
3. Add `grid_delta_avg_inversion` (linear, share-weighted), then `grid_delta_always_inversion` (Mobius, multi-island handling).
4. Extend `run_all_countries_inversion.py` to compute and report all three CIs alongside the existing $\phi$ CI.
The `lca_inversion_three_countries.md` table grows from one to four CI rows per (country, spec).

Cached state to know:

- Branch: `lca-inversion` at commit `a6dc93b` (revised spec).
Four commits this session: `c0909d6` (island detection) → `69be5dd` (weak-ID review + TODO restructure) → `92b0c0b` (critic review + kappa-rename TODO) → `a6dc93b` (revised spec).
- Main has commit `34f6238` (Stream B handoff doc) added during this session.
- New worktree: `C:/git/ckt/.claude/worktrees/simulations` on branch `simulations`, branched from main's `34f6238`.
- The published $\phi$ inversion CIs in [`results/lca_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/lca_inversion_three_countries.md) for IDN/cons/urban/unb covs_all is $[-1.23, -0.01]$, which crosses the $\phi = -1$ singularity.
This means $\Delta_{d_T}$'s inversion CI for IDN covs_all will be a union of two intervals separated by the singularity; expect to flag this in the paper writeup.
- The prose-rules-enforcer hook has been triggered this session, so the voice.md and rules/manuscript-writing.md flags are set.
Will reset on the next session.
- TODO has the kappa-rename entry gated on the pipeline-refactor branch landing first.
Verify that branch's status before starting any rename work.

**If you resume on simulations to work on Stream B / Stream C:**

Read [`explorations/python-grc/HANDOFF_streamB.md`](file:///C:/git/ckt/.claude/worktrees/simulations/explorations/python-grc/HANDOFF_streamB.md) first.
That doc is self-contained on the rcond / sparse-moment / basin-switching arc and the Stream C deliverables.
The simulations worktree is at branch `simulations` from main's `34f6238`.
