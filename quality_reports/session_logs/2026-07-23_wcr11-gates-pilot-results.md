# Session log 2026-07-23 (overnight and morning): WCR11 gates passed, pilot results, J-dial proposal

## If you resume

- Branch `wcr11-inversion-port` in the worktree `C:/git/ckt/.claude/worktrees/wcr11-inversion-port`, now at commit `3f80d25` (pilot results); nine commits total on the branch.
- Open thread: Emilia asked whether to set up runs dropping sparser trajectories.
  I proposed the cheaper variant: a one-cell J-dial experiment on IDN cuu ca (invert at J in {8, 14, 20, 25} under the count-descending ordering, fixed seed, B = 999) using the sims branch's `restriction_projection` machinery, leaving GMM untouched, to measure whether fewer, denser restrictions narrow the corrected CI.
  Awaiting her yes/no; if yes, wiring the projection into `grid_lca_inversion` is a self-contained addition, and adopting it for reported CIs would need a short spec addendum.
- Also awaiting her: the review-fix batch ([2026-07-22-wcr11-port-code-review.md](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/reviews/2026-07-22-wcr11-port-code-review.md)), production B (399 vs 999), the CHN_rf counterfactual-bound consequence of the delta scrub, and the Stage 6 grid widening (extend the phi grid's lower bound past -3 for at least IDN).
- Definitive master run: still alive at 08:00, about 33.5 hours in (launched Tuesday 2026-07-21 22:33), PID 28684, error count still exactly 1 (the known 5b fossil abort).
  At 07:49 it was inside `9_GRC_extras` on the birth family with `grc_IDN_cuu_birth_c1_*` freshly written; remaining are two birth cells (cub, cnu), then `10_make_tables`, `11_make_figures`, `17_verdier_robust` (30 GMM fits, the last long block), `17b_cluster_summary`, `11b`.
  920 sters on disk; expect roughly 1,020-1,050 at completion.
  Check [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt) before touching anything under `C:/git/ckt/RP7`.

---

## Context

Continuation of [2026-07-22_wcr11-port-stages0-5.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-22_wcr11-port-stages0-5.md) in the same conversation: overnight the detached jobs finished and Emilia engaged this morning.

## Overnight results

Gate B passed after one instructive false alarm.
The first attempt subset the sims invocation to J = 26 / count_desc only; the uncorrected size reproduced exactly (0.264) but the WCR size came out 0.040, because `run_wcr_eval.py` consumes one rng stream per rep across sorted (ordering, J) combos, so subsetting shifts the sign draws' stream position.
The full-invocation rerun (both orderings, all five J values, factor 1.0, master seed 20260710) reproduced every count_desc factor-1.0 reference row exactly, including the anchor (uncorrected 0.264, WCR 0.048), zero failures, zero insufficient draws.
Verdict and raw parquet committed (`914452d`); the subset diagnostic is archived under `gateB_subset_diagnostic/` with a README recording the stream-position lesson for any future partial rerun of the sims harness.

The Stage 5 pilot completed all three arms cleanly (rc = 0), committed at `3f80d25`; report at [pilot_idn_cuu_ca.md](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/pilot_idn_cuu_ca.md).
Headline numbers for IDN cuu ca (the full-covariate column of the main IDN table): production arm (B = 399) phi 95% CI (-2.95, 0.92), 90% CI (-1.59, 0.56); second seed 95% (-3.00, 0.98) with the region split into two islands; B = 999 95% (-3.00, 0.84).
All arms: full draw validity, zero ties, Wald-min at phi = -0.58.
Uncontended timing 102.8 min at B = 399 and 213.0 min at B = 999 for this, the most expensive cell.

## Morning discussion with the author

I misattributed the GMM comparison point: I quoted phi = -2.46 as "the GMM estimate," but that is the decommissioned no-covariate column 1 value; the correct column 5 (covs_all) GMM phi is -0.525 (SE 0.102), which sits essentially on the inversion's Wald-min of -0.58.
Emilia caught it from the frozen Table 4; corrected in conversation, and the pilot report on disk never carried the bad comparison.

Her concern that the bootstrap CIs look "really problematic" (wobble, islands): my assessment, delivered, is that the width is the honest consequence of correcting a size-0.264 test and reads as a weak-identification signature beside the tight GMM CI (-0.73, -0.32); the seed wobble is 0.05-0.08 on an interval about 3.9 wide and shrinks with root-B; the arm-2 island split is marginal-grid-point noise (p curve grazing 0.05), single island again at B = 999.
Lesson recorded: Stage 6 should persist the p-value curves, not just endpoints, so island depth is inspectable without re-runs.

Her question on dropping sparse trajectories: the keep-list already drops switcher trajectories with fewer than 5 both-state individuals (26 kept for IDN, J_R = 25).
I distinguished raising that estimation threshold (heavy: changes GMM sample and all results) from dropping restrictions only inside the inversion via the sims `restriction_projection` count-descending machinery (light: GMM untouched, CI stays valid under the null, question is purely precision), and noted the sims evidence says sparsity drove the chi-squared size failure while WCR held size everywhere, so the open question for the J-dial is width, not validity.
Proposed the one-cell J-dial experiment; awaiting her decision.

## Files changed this session (all in the port worktree)

- `quality_reports/staging/wcr11/gateB/` (verdict, run log, manifest, raw parquet), `gateB_subset_diagnostic/`, `gateB_verdict.txt` --- commit `914452d`.
- `quality_reports/staging/wcr11/pilot_idn_cuu_ca.{csv,md}`, `pilot_run.txt` --- commit `3f80d25`.
- `quality_reports/reviews/2026-07-22-wcr11-port-code-review.md` --- commit `56df30b` (last night, after the previous log).

## Open items

Carried from the prior log: review-fix approvals, production-B choice, CHN_rf counterfactual-bound adjudication, Stage 6 after the rc sentinel plus gates (both now green), Stage 7 author items, merge.
New this session: the J-dial experiment decision, the Stage 6 grid widening for bound-touching cells, and persisting inversion p-value curves in Stage 6.
