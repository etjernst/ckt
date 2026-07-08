# 2026-07-08 --- Counterfactual E1/E2 implementation review and fix spec

## If you resume (UPDATED 14:15, supersedes the block further down)

One-line state: Phases 1--2 of the fix plan are implemented, verified, approved, and committed (`7ae1ae1` exporters, `555eb6b` Python, `f8d51d7` checkpoint memo, `a908644` regenerated baseline); NEXT ACTION is Phase 3, the paper edits in the Overleaf `main-updated.tex` (user-approved) mirrored in `paper/results_counterfactuals.tex`.

Decisions all settled except the envelope: coverage variant v1 (joint 3D region; must be SPELLED OUT in the paper prose); UF/national unboundedness reported as open intervals (footnote reason: the UF subsample's six small switcher cells cannot bound the LCA slope --- NOT "phi near zero"; $\hat\phi^{uf} = -0.97$ is steep and the user was corrected on this in chat); baseline regenerated and strict; envelope (D5) awaiting the user's go/cut after a re-explanation (my updated recommendation: CUT the paragraph now that the gaps are already wide; build only for appendix depth).

Phase 3 checklist (all numbers from [the checkpoint memo](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-checkpoint.md) and `RP7/output/counterfactual_results.csv`):
1. Read `~/.claude/references/voice.md` first (prose hook).
2. Equation (1): value term becomes $\pi_d \Delta_d (\bar D_d - \bar D^0_d)$, $\bar D^0$ = share urban in the FIRST OBSERVED wave (not "initial location").
3. Identification paragraph (~line 820 of main-updated.tex): switcher returns evaluated on the estimated LCA line at each region point; unrestricted cross-check sentence (moves the gap by less than 0.05pp); sparse-switcher ster-$\mu$ sentence; delete "identified non-parametrically" as the description of what enters the aggregate.
4. Lumped-cell disclosure: return = $\Delta_{base}$ plus the unbalanced-choice shift (the GMM's unbalanced urban premium; the old code dropped the $\Delta_{base}$ part); its uncertainty is inside the interval via the third region coordinate.
5. Interval prose: joint 3D $(\phi, \beta, \Delta_{unb})$ test-inversion region, aggregate recomputed at every accepted point, hull reported, honest $\ge 95\%$; national row footnote "at least 90%" (Bonferroni floor under arbitrary dependence).
6. UF $[+2.0\%, \infty)$ and national $[+10.4\%, \infty)$ open intervals with the weak-ID footnote; rewrite "an order of magnitude smaller" (survives via points and lower bounds only).
7. Refresh every quoted number per the checkpoint table; value-of-migration column is now 0.2--0.8% (pre-panel migration no longer counted --- sharpens the pro-poor story; the prose must explain the drop).
8. Hukou bound: $+11.6\% \to +11.1\%$ point; "$\pi_{d_N}^{rh}$" glossed as the balanced-panel never-migrant share.
9. Cut or refresh the with-$d_T$ caveat numbers (+58%/+145%; with_dT_v1 rows in the results CSV are the corrected ones); delete the law-of-total-variance sentence; envelope paragraph per the pending D5 decision.
10. Process: one commit per logical edit in the worktree mirror; critic-alignment pass after (Phase 4); review-memo status footer; NEVER touch `main.tex` (only `main-updated.tex`).
11. `12_counterfactuals.do` calls the entry point without `table_variant`, which defaults to v1 --- consistent; no driver edit needed.

## Original resume block (2026-07-08 morning, superseded)

One-line state: the E1/E2 counterfactual review is done and committed (`9bdab00`); the fix spec is written; the session is PAUSED awaiting the user's answers to six decision points (D1--D6 in the spec) before any code is edited.

Read first, in this order:
1. The review memo: [2026-07-08_counterfactual-implementation-review.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-implementation-review.md).
2. The spec: [2026-07-08-counterfactual-fixes.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-counterfactual-fixes.md).

The open thread: the user said "we should fix all of them" (all review findings); I recommended options 1a/2a/3a/4a/5-implement and asked where the paper edits should land (D6).
Next concrete action once the user answers: write the plan to `quality_reports/plans/2026-07-08-counterfactual-fixes.md`, get plan approval, then implement.
Do NOT edit the exporters, `counterfactuals.py`, or any Overleaf file before that approval chain completes.

## Mode

Review (this morning), then Implementation entry (spec written, awaiting spec-decision approval).

## Goals

The user asked for a careful correctness review of the two counterfactual experiments the paper will keep --- the aggregate consumption gap (E1, `tab:counterfactual_misallocation`) and removing-hukou (E2, `tab:hukou_bound`) --- because some results looked counterintuitive.
Reference paper text: the Overleaf `main-updated.tex` lines 781--920 (mirrors the worktree's `paper/results_counterfactuals.tex`).

## What the review found (full detail in the memo)

Critical:
- C1: the exporters feed E1's LCA extrapolation raw household-level `ln(consumption)` trajectory means instead of the model's per-capita covariate-consistent $\mu_d$; root cause is a dead `mu:switcher_` extraction (`: colnames` strips equation prefixes, so the loop never matched and the raw-data fallback became the source). Verified against the sters: model-consistent $\Delta_{d_N}$ reproduces each ster's `inv_dN`; the raw version does not. TZA's headline gap point moves $17.9\% \to \approx 20.4\%$ when fixed.
- C2: `compute_alpha_dT_obs` (per-capita) is differenced against the household-level `mu_base` inside `lca_delta_dT`, so the quoted with-$d_T$ numbers (+58% IDN, +145% TZA) are unit artifacts.

Major: M1 the "unrestricted" switcher deltas are `nlcom` LCA-fitted values from the restricted fit, held fixed while $(\phi,\beta)$ vary; M2 the lumped unbalanced cell (89% of IDN pids) carries the unbalanced-mover coefficient with no selection correction and no uncertainty (this is why IDN's CI is so tight --- 96% of the IDN gap is that constant term); M3 the prose's initial-location zero-migration baseline vs equation (1)'s all-rural baseline, plus the value column silently zeroing $d_T$ everywhere; M4 the CHN_uf ster's base is trajectory 4 while Python hardcodes 2 (point plug-in mixes coordinates; hull unaffected); M5 the CHN national "95%" interval sums two 95% hulls (honest coverage $\ge 90\%$).

Minors: unimplemented Gaussian envelope the paper promises; four-way decomposition promised but not persisted; hukou point $+11.6\%$ is grid-snapped `inv_dN` (0.11) vs the `_n` ster's 0.106 the RF GRC table shows; no lattice-truncation guard; sample-filter mismatches; `pi_helper` dead code.

Verified correct (so nobody re-litigates): the joint $(\phi,\beta)$ S-statistic region, hull projection, P3's lower-bound logic for the gap, the entire E2 arithmetic and its paper numbers, the baseline self-check harness, and paper-numbers-vs-CSV agreement.

## Decisions made, with the why

- Wrote findings to a memo rather than chat (project output preference) and committed it alone (`9bdab00`), leaving the pre-existing uncommitted hetDelta/hetmu table changes untouched.
- Treated the fixes as Implementation mode: they alter published numbers and estimation-adjacent code, so spec-then-plan applies even though the user pre-approved "fix all".
- Recommended (not decided): D1a unrestricted OLS `beta[s]`; D2a keep $\hat\Delta_{unb}$ + propagate its variance + disclose; D3a initial-location baseline via exported $\bar D^0_d$; D4a Bonferroni budgets (97.5% per-cell components, 98.75% national); D5 implement the envelope. D6 (where paper edits land: Overleaf `main-updated.tex` vs change-list + worktree copy) is purely the user's.

## Approaches rejected and the reason

- Considered that the model's $\mu_d$ might itself be household-level (which would make the exporter correct): rejected --- the ster $\mu$'s sit on the per-capita scale (IDN `mu:never` 10.51 vs raw 11.83) and reproduce `inv_dN` exactly, and the Python fit divides by `hhsize_cube`.
- Considered that the `_d` ster deltas might be genuinely unrestricted: rejected --- IDN `Delta_3` equals $\beta + \phi(\mu_3 - \mu_2)$ from the parent ster to machine precision, and `Delta_base` equals the base's `Delta_k` in every cell (which is also how the CHN_uf base-4 mismatch surfaced).

## Files changed

- New: [quality_reports/reviews/2026-07-08_counterfactual-implementation-review.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-implementation-review.md) (committed `9bdab00`).
- New: [quality_reports/specs/2026-07-08-counterfactual-fixes.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-counterfactual-fixes.md) (uncommitted).
- Scratchpad only: `_dump_ster_mus.do` + log (read-only ster diagnostic; not repo material).

## State to know

- All quantitative checks used the on-disk sters (`grc_{IDN,TZA,CHN_rf,CHN_uf}_cuu_ca{,_d}.ster`) and the CSVs in `RP7/output/counterfactual_inputs/`; no GMM was re-run and none of the fixes require one.
- Ster bases: IDN/TZA/CHN_rf = trajectory 2, CHN_uf = trajectory 4.
- Key reference values for the fix verification: model $\mu_{d_N}-\mu_{base}$ = IDN $-0.0081$, TZA $-0.1885$, CHN_rf $-0.0243$, CHN_uf (base 4) $+0.1880$; ster `inv_dN` = 0.07 / 0.27 / 0.11 / (UF: $-0.23$ waldmin, CI $[-0.56, 0.11]$).
- The frozen drift baseline (`counterfactual_results_baseline.csv`) will fail after any fix by design; regenerate with `regenerate_baseline=True` once numbers are verified.
- Pre-existing uncommitted working-tree changes (hetDelta/hetmu tables from the CHN sweep-refit thread) are unrelated; leave them alone.
