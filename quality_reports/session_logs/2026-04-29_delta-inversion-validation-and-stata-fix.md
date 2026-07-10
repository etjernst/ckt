# Session log: 2026-04-29 delta-inversion validation gate + Stata Delta_avg fix

Mode: Implementation (validation gate + Stata bug fix) and Review (econometric / spec revisions).
Branch: `lca-inversion`.
Fourth log of the day; previous siblings at [`2026-04-29_island-detection.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_island-detection.md), [`2026-04-29_weak-id-review-and-handoff.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_weak-id-review-and-handoff.md), and [`2026-04-29_delta-inversion-spec.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-29_delta-inversion-spec.md).

## Goals

The user picked up from the prior session where the delta-inversion spec was at "ready for implementation."
The next concrete step from that session log was validation step 1, the precondition gate that compares Python's auxiliary-OLS-derived $\Delta_X(\hat\phi, b)$ against Stata's published `nlcom` point estimates.
The session ran the gate, found it failed everywhere, and worked through the diagnosis with the user.

## What got built or changed

Stata-side ground truth and bug fix:

- [`explorations/python-grc/rerun_workdir/extract_published_deltas.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/extract_published_deltas.do): new extractor.
Walks every `grc_{country}_{spec}_{never|avg|always}.ster` in `rerun_workdir/output/` (45 files), pulls $\Delta_X$ point + SE, writes `published_deltas.csv` and a separate `published_gmm_internals.csv` with $\hat\phi$, $\hat\beta$, $\hat\mu_{d_N}$, $\hat\kappa$.
- [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): patched in five sibling code paths (`run_grc`, `run_grc_onestep`, `run_grc_balanced`, `run_grc_robust_vv`, `run_grc_robust_vv_onestep`).
The `Delta_avg` `nlcom` now conditions on `e(sample) & switcher == 1` so the trajectory shares `num_s` are within-switcher (sum to 1), not over-all-sample (which summed to switcher fraction).
- [`explorations/python-grc/rerun_idn_5gr_fixed.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_idn_5gr_fixed.do) and [`rerun_chn_tza_5gr_fixed.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_chn_tza_5gr_fixed.do): new fixed-formula reruns.
Identical to the 2026-04-23/24 reruns except `$scripts` points to the local RP7 0_programs.do (with the fix) instead of the Dropbox copy (still buggy).
Both wrap the body in `capture noisily { ... }` per the popup-safety convention.
- IDN rerun launched in background (id `bqvklp2l1`).
CHN+TZA queued pending IDN verification.

Python-side validation:

- [`explorations/python-grc/validate_delta_points.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/validate_delta_points.py): new validation gate runner.
For each (country, spec) at the GMM's $\hat\phi$, computes Python's auxiliary-OLS $\Delta_{d_N}$, $\Delta_{\text{avg}}$ (within-switcher and over-all variants), $\Delta_{d_T}$, and compares against `published_deltas.csv`.
Also reports OLS-vs-GMM $\hat\beta$ decomposition.
- Outputs at [`results/validate_delta_points.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_points.csv), [`results/validate_delta_decomposition.csv`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_decomposition.csv), and [`results/validate_delta_points.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/validate_delta_points.md).

Reviews and memos:

- [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md): full failure analysis.
Two issues identified: (1) Stata's $\Delta_{\text{avg}}$ uses over-all shares, so its published value equals sw\_frac times the right quantity; (2) auxiliary-OLS $\hat\beta_{\text{base}}$ disagrees with GMM $\hat\beta$ by 1--7 percentage points across cells.
The memo carries the full Chamberlain (1982) / Newey-McFadden (1994) minimum-distance derivation for the new inversion procedure, with explicit Wald and asymptotic statements.

## Decisions, with the why

Decision: Stata's `Delta_avg` `nlcom` is computing a malformed quantity, not a Python implementation error.
Why: Stata's `num_s = (sum 1.switcher_s if e(sample); local num_s = r(mean))` returns $N_s/N_{\text{total}}$, which sums to switcher fraction across switchers, not 1.
The economically meaningful $E[\Delta \mid \text{switcher}]$ requires within-switcher shares (sum to 1).
Three independent reasons: (i) population-level expected return for switchers is the unique number that, multiplied by switcher population size, gives total switcher returns; (ii) sw\_frac varies 4--14% across countries, so the over-all version conflates the return with switching prevalence; (iii) FE-OLS on switchers converges to the within-switcher weighted average.

Decision: fix the Stata bug now and regenerate `_avg.ster` via a full GMM rerun.
Why: the user pushed back on my "GMM is multi-hour, let's leave it" framing as overstating cost.
Re-running just the `nlcom` step would have been cheap, but my attempt failed because `e(sample)` is invalidated by `clear all` + reload, and reconstructing it manually is brittle.
A clean GMM rerun via the standard `run_grc` path (~1 hour for IDN, ~3 total) actually goes through the corrected code on real data and produces verifiable `_avg.ster` files.

Decision: rejected the analytical correction shortcut $\Delta_{\text{avg, correct}} = \Delta_{\text{avg, buggy}} / \text{sw\_frac}$ in Python.
Why: the user flagged it as a hack.
The math is right (within delta-method-equivalent SE scaling), but it doesn't go through the corrected Stata code path on real data, so any other assumption I missed wouldn't surface.
Pivoted to the GMM rerun even though it costs hours of compute.

Decision: minimum-distance is the inversion procedure for $\Delta_X$.
Why: Issue (2) of the validation report, the auxiliary-OLS-vs-GMM $\hat\beta_{\text{base}}$ gap, has a principled fix.
At each candidate $\phi$, concentrate out $\beta$ via GLS over the LCA moment vector $m_s = \hat\beta_s - \beta - \phi(\hat\alpha_s - \hat\alpha_{\text{base}})$ for $s \in \mathcal{S}$.
The concentrated Wald is asymptotically $\chi^2_{|\mathcal{S}|-1}$ under standard regularity (Chamberlain 1982, Newey-McFadden 1994 ch.\ 36).
Pools information across all switchers, closes most of the OLS-vs-GMM gap, and is at least as efficient as the just-identified version under LCA.
User accepted MD as the inversion target after walking through the derivation.

Decision: start with IDN only before committing to CHN+TZA.
Why: user noted the full pipeline (which includes 6_GrRC_NonAg, 7-15) would be 30--40 hours.
Even main-specs-only is ~3 hours.
IDN at ~1 hour gives a fast verification: if the corrected Stata $\Delta_{\text{avg}}$ matches Python's within-switcher $\Delta_{\text{avg}}$ to the OLS-vs-GMM tolerance, the fix is validated and CHN+TZA can run.
If something else is broken, we catch it at 1 hour cost, not 3.

Decision: $\Delta_{d_N}$ and $\Delta_{d_T}$ failures of the gate are real but expected.
Why: GMM imposes the LCA restriction across all switchers jointly, so $\hat\beta_{\text{GMM}}$ pools information.
Auxiliary OLS imposes nothing.
At $N \approx 90{,}000$ the two estimators differ by 1--7 pp, and they target genuinely different objects when LCA fails (IDN covs_0, CHN throughout).
The MD inversion described above closes most of this gap analytically; the residual gap reflects GMM's additional moments (always-mover moment, unbalanced indicators) that the auxiliary OLS does not use.

## Approaches rejected and why

Replay-only-the-`nlcom` rerun script:
attempted at [`rerun_workdir/rerun_delta_avg_only.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/) (deleted after failure).
Failed because `estimates use foo.ster` after `clear all` + `use ..._unb.dta` reload does not restore a working `e(sample)` mask.
`count if e(sample)` returned 0 after the reload.
Reconstructing the GMM sample manually was brittle and would have required mirroring `setup_grc_estimation` + spec-specific dropna logic.
Cost-benefit pointed to a clean GMM rerun.

Stata-conventions popup-safety wrapper omitted from `test_load.do` and `test_one_ster.do`:
those minimal probes errored without `capture noisily`, which fired the "Output has been saved..." popup that the user flagged.
Both files have been deleted.
The production `extract_published_deltas.do` and the new `rerun_*_fixed.do` files all carry the wrapper.

Analytical correction $\Delta_{\text{avg, correct}} = \Delta_{\text{avg, buggy}} / \text{sw\_frac}$:
mathematically equivalent under the bug's structure, but does not exercise the corrected Stata code on real data, so leaves any other assumption I may have missed undetected.
User flagged as a hack.
Reverted before pivoting to the GMM rerun.

## Open items and blockers

- IDN rerun running in background (id `bqvklp2l1`).
ETA ~1 hour from launch.
Watch for completion, then re-run [`extract_published_deltas.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/extract_published_deltas.do) and [`validate_delta_points.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/validate_delta_points.py).
The expected outcome: corrected Stata $\Delta_{\text{avg}}$ matches Python's within-switcher value to the OLS-vs-GMM tolerance (sub-percent for IDN given $N \approx 90{,}000$).
- CHN+TZA rerun (`rerun_chn_tza_5gr_fixed.do`) queued pending IDN verification.
- Minimum-distance inversion implementation has not started.
The MD derivation is in the validation gate memo.
Next concrete step: rewrite `lca_inversion.py:grid_lca_inversion` to use the concentrated MD Wald, and write three new functions `grid_delta_never_inversion`, `grid_delta_avg_inversion`, `grid_delta_always_inversion` per the spec.
- Local working state: previously corrupted `_avg.ster` files in `rerun_workdir/output/` (from the failed `rerun_delta_avg_only.do` attempt) will be overwritten by the IDN rerun.
CHN and TZA `_avg.ster` files are still corrupted until the CHN+TZA rerun runs.

## Picking back up

Read the validation gate memo first: [`quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md).
That memo is self-contained: it carries the bug analysis, the MD derivation, the implementation steps, and the validation strategy.

If IDN finished cleanly:

1. Run [`rerun_workdir/extract_published_deltas.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_workdir/extract_published_deltas.do) again to refresh `published_deltas.csv`.
2. Run [`validate_delta_points.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/validate_delta_points.py) to confirm Python's within-switcher $\Delta_{\text{avg}}$ matches the corrected Stata `nlcom` for the five IDN specs.
3. If yes, kick off [`rerun_chn_tza_5gr_fixed.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/rerun_chn_tza_5gr_fixed.do) (~2 hours).

If IDN failed: triage the log at `rerun_workdir/rerun_idn_5gr_fixed.smcl`, fix root cause, re-run.

After all three countries are clean: pivot to MD inversion implementation.
The MD spec section is the new validation gate (Python's MD-derived $\Delta_X$ at $\hat\phi$ should match Stata's `nlcom` to fractions of a percent).
