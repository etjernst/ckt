# Session log 2026-07-23 (overnight and morning): WCR11 gates passed, pilot results, J-dial proposal

## If you resume

- Branch `wcr11-inversion-port` in the worktree `C:/git/ckt/.claude/worktrees/wcr11-inversion-port`, now at commit `826e924` (review fixes closed), working tree clean.
- Open thread: launch the J-dial experiment in this fresh session.
  Emilia approved it as purely exploratory ("for now we are just curious").
  Design: the IDN cuu ca cell, inverting phi using only the J most-populated switcher restrictions under a count-descending, pre-specified ordering, J in {8, 14, 20}, B = 999, the same seed token `grc_IDN_cuu_ca` and the same esample-marker sample as the pilot.
  The pilot's B = 999 arm already is the J = 25 (full) point, so it should not be re-run.
  Persist the full p-value curves per J, not just the endpoints.
  Runs locally, about 3 hours if the three J values run in parallel with threads capped; no gadi run is needed.
- Implementation route: a pure `explorations/` driver, with zero production-code changes.
  Retrieve `restriction_projection.py` from `worktree-extension-sims` via `git show` into `explorations/python-grc/`, the same pattern used for the Stage 0 retrievals.
  Build the restriction matrix C = A_J @ G per grid point and call `wcr_bootstrap.wcr11_test` directly, reusing the one sign matrix across grid points and J values.
  Counts per kept trajectory come from `drop_sparse_switchers`.
  The exploration fast-track applies, so no spec is needed; if the dial looks promising and a reported CI would change, a short spec addendum comes first.
- Validity argument recorded, both asked and accepted by Emilia: coverage only requires the used restrictions to be true at the true phi, and every subset satisfies that under the maintained LCA model.
  Dropping restrictions affects power and width only, and the subset rule is pre-specified (count-descending) to avoid CI-shopping.
- Author decisions this morning: leaning toward B = 999 for production, with the final call deferred until after the J-dial since the two interact.
  Persisting inversion p-value curves in Stage 6 is approved.
  All seven code-review fixes are approved and now closed at commit `826e924`, with Gate A re-passed on the fixed kernel.
- Sims backlog item, agreed: a J-dial power-and-width companion study tracking coverage at truth, mean and median 95% CI length plus the SD of length, the share of bound-touching or unbounded intervals, the island-count distribution, and rejection rates at two or three fixed false phi values, plus for the Wald-min point estimate the standard set (mean, median, SD, MAE, RMSE).
  The SE-calibration ratios do not translate to the inversion, since no SE exists there, and stay only for any GMM comparison arm.
- Definitive master run: still alive at 08:30, about 34 hours in, PID 28684, error count still exactly 1 (the known 5b fossil abort), inside `9_GRC_extras` on the birth family.
  920 sters on disk; expect roughly 1,020-1,050 at completion.
  Check [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt) before touching anything under `C:/git/ckt/RP7`.
  Stage 6 regeneration remains blocked on the sentinel plus Emilia's production-B call.
- Other open author items carried: the CHN_rf counterfactual-bound breakage from the delta scrub, the Stage 6 grid widening (extend the phi grid's lower bound past -3, at least for IDN), the Stage 7 table-macro diffs and CHN urban-first wording, and the merge at the end.
- The critic-fixer hook flag is cleared, since fixer-code ran, so new Python file writes are unblocked.

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

## 2026-07-23 morning continuation: metrics guidance, review fixes closed, J-dial approved

Goals: Emilia engaged with the overnight results, and this block covered four things: simulation-metrics guidance, the restriction-subset validity question, the code-review fix batch, and the J-dial go-ahead, with wrap-up before a fresh-context launch.

### Decisions

- Emilia leans toward B = 999 for production, driven by the pilot's seed-sensitivity finding that CI endpoints move 5-8 grid steps between seeds at B = 399; she deferred the final call until after the J-dial result, since the two interact.
- Emilia approved persisting inversion p-value curves in Stage 6, since the pilot saved only endpoints and left island depth impossible to inspect without a re-run.
- Emilia approved the J-dial as exploratory.
  The restriction-subset CI stays valid because coverage needs only the used restrictions to be true at the truth, and any subset qualifies under the LCA model.
  Width is the open question, and the count-descending pre-specification prevents CI-shopping.
- I delivered the metrics guidance: the standard point-estimator set (mean, median, SD, MAE, RMSE) applies to the Wald-min point, while the CI study tracks coverage, the CI-length distribution, the bound-touching share, island counts, and rejection at fixed alternatives.
  The two SE-calibration diagnostics do not translate, because the inversion produces no SE, and stay only for GMM comparison arms.
- Emilia approved all seven review fixes, applied through fixer-code per the Mode 3 loop, at commit `826e924`.
- I verified the kernel fix (the W_obs singularity guard plus the B >= 1 guard) with a full Gate A oracle re-run rather than trusting the arithmetically-identical claim; the re-run passed in full, covering the toy enumeration plus 12 real anchor cases at 1e-8.
- The Gate A re-run required temporarily copying the fixed kernel over the sims worktree's copy and restoring it afterward, because the oracle imports sims-only modules and its `sys.path.insert(0)` defeats a PYTHONPATH override.
- Fix verification used coordinator diff review plus the oracle, the unit suite (now seven tests), and a Stage 9 keep-list re-run, instead of re-spawning both critics; this was proportionate to an 86-line diff of pre-approved changes.

### Files changed

All in the worktree, commit `826e924`.

- [0_programs.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/RP7/scripts/0_programs.do): a symmetric provenance scrub on chi2 re-saves in `attach_inversion_ci`.
- [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/lca_inversion.py): `grid_lca_inversion` now requires and verifies `design_names` under wcr11.
- [wcr_bootstrap.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/wcr_bootstrap.py): a B >= 1 entry guard, and a singular observed projected covariance now returns a typed-failure result instead of crashing.
- [wcr11_pilot_idn.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/wcr11_pilot_idn.py): unused imports removed, and arm-3 wording corrected to an independent higher-B run.
- [5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/RP7/scripts/5b_inversion.do) and [5c_inversion_hukou.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/RP7/scripts/5c_inversion_hukou.do): a comment documenting the load-bearing `_rc == 0` conjunct.
- [test_wcr11_inversion.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/test_wcr11_inversion.py): the typed-failure test rewritten guard-agnostic, plus a new B = 0 guard test; the suite is now at seven tests.
- [2026-07-22-wcr11-port-code-review.md](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/reviews/2026-07-22-wcr11-port-code-review.md): disposition updated, all seven findings closed.

### Rejected approaches

None substantive this block, beyond the fix-verification choice noted above.

### Open items

Launching the J-dial is the resume thread, the production-B decision follows it, the sims power-and-width companion study is queued, and the carried items are the CHN_rf bound, the grid widening, Stage 7, and the merge.

## 2026-07-23 evening addendum: J-dial results, production B settled

The three J-dial runs completed cleanly (all rc 0, full draw validity, zero insufficient grid points) in the port worktree; driver and retrieved projection module committed at `8bcb17e`, results under [quality_reports/staging/wcr11/jdial/](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/quality_reports/staging/wcr11/jdial/).
Emilia confirmed the production bootstrap draw count is DECIDED at B = 999, superseding this log's earlier "leaning" language; no future session should re-open it.
The remaining production question from the dial is J alone: keep all 25 restrictions or adopt a reduced construction, which requires a spec addendum and the companion power-and-width study before any reported CI changes.

J-dial headline for IDN cuu ca, 95% CIs for phi: J = 25 (pilot) (-3.00, 0.84) hitting the grid edge; J = 20 (-1.30, 0.53) single island, width 1.83; J = 14 (-1.80, 0.32) single island; J = 8 unbounded below with three islands.
The dial is non-monotone with J = 20 the width sweet spot; the Wald-min point stays between -0.73 and -0.53 at every J, near the GMM -0.525.
None of the corrected intervals excludes zero at 95% for this cell, and Emilia acknowledged that; choosing J to rescue significance would be CI-shopping, so the J choice rests on the sims evidence only.

E1 detail verified from the 2026-05-18 note this evening: the E1 aggregate consumes inversion values for BOTH the never-migrant and the always-urban trajectories, so the GMM-substitution rework must handle the always-urban piece (where sims show GMM is NOT well calibrated: rel_se_bias up to 6), not just Delta_never; the reported variant zeroes the always-urban row in the gap term, and which pieces survive in the reported numbers is the first thing a rework spec must pin down.
Sims evidence read directly from [p5b_gadi_summary/summary.csv](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/results/p5b_gadi_summary/summary.csv): GMM 95% coverage for Delta_never 0.86-0.94 and Delta_avg 0.90-0.98 across cells and dials (about nominal at MC precision of roughly 2pp), against inversion 0.74-0.78 in IDN; no CHN-calibrated cell exists, so applying this to CHN_rf is an extrapolation the author must own.
