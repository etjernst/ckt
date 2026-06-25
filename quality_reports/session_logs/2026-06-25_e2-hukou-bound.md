# 2026-06-25: E2 hukou-wedge lower bound (Version 1)

## If you resume

E2 Version 1 (the hukou-wedge consumption-gain lower bound) is built, run, reviewed, and committed (`84ef93c`, `2a872b6`, `5054e4a`).
The headline: removing the rural-hukou barrier delivers a per-never-migrant return of +11.6% (95% CI [+9.4%, +13.9%]) and an economy-wide consumption floor of +2.2% ([+1.8%, +2.6%]).
Nothing is mid-flight.

The next substantive piece is E2 Version 2 (the resorting magnitude): the decision-rule simulation with a sigma_eta grid under type-I EV and normal shapes, the common-vs-regime base sweep, and the c in [0,1] appendix figure.
It needs distributional/base modeling decisions settled with the user first; the section already describes it in subjunctive (lines ~128-146 of results_counterfactuals.tex), which stays as-is until V2 is run.

Punch lists unchanged from last session: the Overleaf/CKT.bib items (inline cites, undefined tab:GRC_CHN_hukou_* refs) and MAY1 (move counterfactuals.py + lca_inversion.py under RP7/scripts/ before the ReplicationPackage7 handoff).

## Modes active

Implementation (spec + twice-reviewed plan + build) then Review (three critics + two fixers).

## What got built

The deliverable graduates eq:hukou-bound from subjunctive prose into a harness output.

- [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py): new `HukouBoundResult`, `hukou_bound_point`, `run_hukou_bound`, `_result_row`/`_hukou_bound_rows`, `write_hukou_bound_table`; wired into `run_all_cells`, `results_dataframe`, and `run_counterfactuals_for_stata` (new `table_path_hukou` param + E2 echo). No `run_cell` refactor; E1 untouched.
- [RP7/scripts/_export_e1_inputs_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_export_e1_inputs_hukou.do): exports `inv_dN_ci95_lo/hi` (2 scalar reads + 2 file writes).
- [RP7/scripts/12_counterfactuals.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/12_counterfactuals.do): passes `table_path_hukou`, confirms the new table.
- [RP7/output/tables/hukou_bound.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/tables/hukou_bound.tex): generated table (Delta_dN_rh row + economy-wide gain row).
- Two new rows in the results CSV + golden baseline (`CHN_hukou_bound`: `hukou_consumption_gain/bound` and `delta_dN_rural_hukou/inversion`).
- [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex): V1 paragraph rewritten with both magnitudes, the population identity, a fixed-share footnote, and `\input{tables/hukou_bound.tex}`.

Spec/plan/memos: [spec](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-06-25-e2-hukou-bound.md), [plan](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-06-25-e2-hukou-bound.md), [base-robustness memo](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-06-25_e2-base-robustness.md).

## Decisions, with the why

- Inference object: scale the CHN_rf ster's PROFILED Delta_dN inversion CI ([0.09, 0.13]) by the fixed constant pi_rh * pi_dN_rh, rather than imaging the joint (phi,beta) region (the E1 approach). The bound is a monotone transform of a SINGLE functional, so the profiled CI is the canonical object AND it matches the Delta_dN^rh CI the paper already reports. The joint-region image would have been wider (chi^2_2 vs chi^2_1) and would have disagreed with the paper's own reported Delta_dN CI. This was the decisive change from the first plan draft, surfaced by review round 1.
- pi_rh = w_rf_cond (conditional, 74%), per user. The bound is then per-defined-hukou-capita, consistent with the E1 national combination (same base). Review round 2 forced writing this population identity out explicitly: const x Delta_dN = (RF-never share of defined-hukou pop) x per-never-migrant return.
- Report BOTH the economy-wide floor (+2.2%) and the per-never-migrant return (+11.6%). The economy-wide number reads low because it averages a double-digit per-worker gain over a population in which ~80% are not RF never-migrants; the per-worker figure makes the magnitude legible. (User reaction "sounds low" prompted this.)
- Shares treated as fixed: their sampling SE (~0.003 on pi_dN, large-N on pi_rh) is ~10x smaller than the Delta_dN CI half-width (~0.02), so endpoint-scaling is the exact inversion CI by equivariance. Stated in a quantified footnote, not hidden.
- Object labeled a partial-equilibrium FLOOR (not the hukou-removal magnitude); Gai 2025 a loose reference, not corroboration.
- No `run_cell` refactor (the revised plan dropped it once the profiled-CI design removed the need for a shared joint CI), so the E1 drift surface is zero. Self-check green throughout.

## Verification

- `12_counterfactuals.do` runs clean via `stata-mp -e`; self-check passes; both tables + results CSV on disk.
- Baseline regenerated via a one-off `regenerate_baseline=True` (temporary driver edit, reverted); the git diff on the baseline is exactly +2 rows with every E1 row byte-identical.
- Hand-check: Delta_dN row = ster CI [0.09, 0.11, 0.13]; bound = const(0.2010) x those.
- Base-robustness: Delta_dN_rh inversion CI is [0.09, 0.13] for ALL 10 candidate bases, so the bound is base-invariant in practice.

## Review

- critic-python 87/100 (no CRITICAL): accepted M1 (NaN/range guards on the two shares), M2 (clarifying comment), M3 (KeyError-with-file-context); routed through fixer-code. Skipped cosmetic minors.
- critic-stata 88/100: the one MAJOR (silent `.` for CHN_uf) was moot --- CHN_uf carries finite inv_dN CI scalars ([-0.56, 0.11]); verified. Nothing to fix.
- critic-writing 92/100 (above PR): accepted the line-130 sentence split and a reword of the closing sentence to kill a near-verbatim echo of the welfare-bridge paragraph; routed through fixer-writing. Skipped the pre-existing line-126 item.
- Self-check re-run after fixer edits: still green (numbers unchanged).

## Gotchas this session

- The first (regenerate) `stata-mp -e` run hung at exit (StataMP-64.exe lingering, holding the `$logs` log), which made the confirmation re-run fail with r(608). Cleared the hung PID, then the clean re-run went green. The work was already persisted before the hang. Confirmation of "self-check passes" is best done in pure Python (reads the CSVs, no Stata lock) to avoid this entirely.

## Open items

1. E2 Version 2 (resorting magnitude): the remaining substantive deliverable; needs modeling decisions first.
2. Overleaf/CKT.bib punch list (unchanged).
3. MAY1 graduation move before the ReplicationPackage7 handoff (unchanged); the E2 code now has the defensive guards that the critic flagged as graduation blockers.

## State to know

- Branch lca-inversion, 0 behind main. Three commits this session: `84ef93c` (code), `2a872b6` (paper), `5054e4a` (docs).
- $dir for maand points at the lca-inversion worktree; the harness runs via `stata-mp -e do 12_counterfactuals.do` from RP7/scripts.
- Both hukou sters carry the inv_dN CI scalars (CHN_rf [0.09, 0.13]; CHN_uf [-0.56, 0.11]).
