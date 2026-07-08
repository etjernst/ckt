# 2026-07-08 --- Counterfactual E1/E2 implementation review and fix spec

## If you resume (UPDATED 21:25, supersedes all blocks further down)

Evening cleanup pass, all in `main-updated.tex` (user-approved) with the counterfactual-section edits mirrored in `paper/results_counterfactuals.tex`:
1. Welfare bridge KILLED (user decision): the `From consumption to welfare` subsubsection deleted from the mirror, both `sec:welfare-bridge` cross-references rewritten to end on "which the consumption data alone cannot price" (mirror commit `0275668`).
2. Kennan-Walker (2011), Tombe-Zhu (2019), and Fan (2019) appended to `CKT.bib` (user-approved additive edit; metadata verified against Zotero, keys `kennanEffectExpectedIncome2011`, `tombeTradeMigrationProductivity2019`, `fanInternalGeographyLabor2019`); inline cites converted to `\citealt`/`\citep`/`\citet`; both TODO footnotes deleted (mirror commit `cf09fad`).
3. Line 494's three dead per-country balanced summary-stats refs repointed to `tab:summary_stats_combined_bal`; the dangling `(Appendix~\ref{app:inversion-preview})` parenthetical dropped from the inference sentence in both files.
4. Full xelatex+bibtex cycle: zero errors, zero undefined citations; the ONLY remaining undefined reference in the document is the stub footnote `\footnote{Tables \ref{hukou}}` at line 754 --- the user is deciding what it should point to (delete vs point at the appendix hukou tables); do NOT touch it without her word.
5. Fan (2019) stays in both spots for now (user decision 21:23: "the first mention clearly belongs"; she will reassess the Hukou Index sentence on a full read-through). Kennan-Walker is duplicated in Zotero (items L8VL7CQB / 8PT5AIBU); suggest merging at some point.
NEXT ACTION: nothing pending except the `hukou` footnote decision.
Remaining open items: the Bryan-Morten restyle Todoist task (6h4694ChV544Wg4J).

## Superseded resume block (15:45)

One-line state: Phases 3 AND 4 are COMPLETE --- all paper edits are in BOTH `paper/results_counterfactuals.tex` (commits `f4772da`..`bd8384e`) and the Overleaf `main-updated.tex` (user re-authorized after a mid-run permission block; shared region verified byte-identical), the regenerated tables are in the Overleaf `tables/` folder, the critic-alignment pass ran (report + adjudication at `quality_reports/reviews/2026-07-08_counterfactual-paper-alignment.md`; its one CRITICAL resolved as a parameterization misread, all findings addressed), and `main-updated.tex` compiles clean (xelatex+bibtex, zero errors, zero undefined citations, aux swept).
NEXT ACTION: nothing pending in this thread.
Open items for a future session: pre-existing undefined refs in `main-updated.tex` (`sec:welfare-bridge` --- subsubsection exists only in the mirror and could be ported with user approval; `app:inversion-preview`, `hukou`, three `tab:summary_stats_*_bal` labels); the two TODO inline cites (Kennan-Walker, Tombe-Zhu, Fan); the Bryan-Morten restyle Todoist task (6h4694ChV544Wg4J).

Decisions ALL settled: coverage variant v1 (joint 3D region; must be SPELLED OUT in the paper prose); UF/national unboundedness reported as open intervals (footnote reason: the UF subsample's six small switcher cells cannot bound the LCA slope --- NOT "phi near zero"; $\hat\phi^{uf} = -0.97$ is steep and the user was corrected on this in chat); baseline regenerated and strict; envelope CUT (user 14:16) --- delete the envelope paragraph at lines 825--832 of `main-updated.tex`, keep the one-sentence Jensen floor remark, delete the law-of-total-variance sentence.
Phase 3 starts in a FRESH session per the user; this file plus the checkpoint memo carry everything it needs.

Phase 3 checklist (all numbers from [the checkpoint memo](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-checkpoint.md) and `RP7/output/counterfactual_results.csv`):
1. Read `~/.claude/references/voice.md` first (prose hook).
2. Equation (1): value term becomes $\pi_d \Delta_d (\bar D_d - \bar D^0_d)$, $\bar D^0$ = share urban in the FIRST OBSERVED wave (not "initial location").
3. Identification paragraph (~line 820 of main-updated.tex): switcher returns evaluated on the estimated LCA line at each region point; unrestricted cross-check sentence (moves the gap by less than 0.05pp); sparse-switcher ster-$\mu$ sentence; delete "identified non-parametrically" as the description of what enters the aggregate.
4. Lumped-cell disclosure: return = $\Delta_{base}$ plus the unbalanced-choice shift (the GMM's unbalanced urban premium; the old code dropped the $\Delta_{base}$ part); its uncertainty is inside the interval via the third region coordinate.
5. Interval prose: joint 3D $(\phi, \beta, \Delta_{unb})$ test-inversion region, aggregate recomputed at every accepted point, hull reported, honest $\ge 95\%$; national row footnote "at least 90%" (Bonferroni floor under arbitrary dependence).
6. UF $[+2.0\%, \infty)$ and national $[+10.4\%, \infty)$ open intervals with the weak-ID footnote; rewrite "an order of magnitude smaller" (survives via points and lower bounds only).
7. Refresh every quoted number per the checkpoint table; value-of-migration column is now 0.2--0.8% (pre-panel migration no longer counted --- sharpens the pro-poor story; the prose must explain the drop).
8. Hukou bound: $+11.6\% \to +11.1\%$ point; "$\pi_{d_N}^{rh}$" glossed as the balanced-panel never-migrant share.
9. Cut or refresh the with-$d_T$ caveat numbers (+58%/+145%; with_dT_v1 rows in the results CSV are the corrected ones); delete the law-of-total-variance sentence; DELETE the envelope paragraph (D5 = cut), keeping only the Jensen floor sentence.
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

---

## Continuation (2026-07-08 afternoon): decisions, plan review, Phases 1--2 implemented

Implementation mode throughout; commits `2ca96ab` through `1ea00ab` plus the log/spec updates at wrap-up.

### Decision resolution

The user approved fixing all findings; four items needed design choices.
D1 (switcher returns) went to critic-econometrics for independent adjudication (clean brief, no steering); verdict B > A > C: LCA-fitted returns recomputed at every lattice point, unrestricted returns as a cross-check, the frozen hybrid retired ([adjudication report](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_switcher-delta-convention-adjudication.md)).
D3 baseline (ii): stay at first observed wave.
D4: both coverage variants computed, Bonferroni vetoed by the user; after seeing widths (they differ by under 0.5pp) the user locked v1.
D5 envelope: cut (see resume block).
D6: paper edits go directly into `main-updated.tex`.

### Plan review catch

/review-plan (fresh-context critique) found one Red in my own plan text: as written, `delta_at(phi, beta)` froze the lumped return while the 3D sweep varied it, which would have made coverage variant 1 silently vacuous --- the same frozen-object bug class the plan exists to remove.
Fixed by making `delta_unb` an argument of `delta_at`; five Yellows (grid width, baseline timing, sparse switchers, lumped-source naming, interface hardening) also folded into the plan before implementation.

### Two substantive discoveries during implementation

1. The old E1 fed `xb:unbalanced_choice` alone as the lumped-cell return, but in the GMM unbalanced individuals carry no trajectory dummy, so their urban premium is $\Delta_{base}+$ `unbalanced_choice`; the sum matches the auxiliary-OLS coefficient to the fourth decimal in all four cells.
A fourth bug the morning review missed; it understated every gap by 2--4 points.
Found because the OLS and GMM coefficients "disagreed" by 3--9 SEs and the plan's investigate-never-loosen rule forced the reconciliation.
2. The CHN_uf confidence region is genuinely unbounded in $\phi$ (both sides): the min-over-$\beta$ S-statistic plateaus at 7.4 against a 12.6 critical value as $|\phi| \to \infty$ (Dufour-type unbounded weak-ID set; six small switcher cells cannot pin the LCA slope).
The old UF interval was a grid-truncation artifact; the code now probes for open edges, marks diverging hull endpoints infinite, and formats open intervals in the table.

### Approaches rejected

- Hard 0.01 OLS-vs-ster $\Delta_{d_N}$ assertion for all cells: CHN_uf legitimately diverges (restricted-GMM $\mu$ vs unrestricted OLS $\alpha$ near the boundary); resolved by taking point estimates from the ster objects (the GRC tables' own pairing) and exempting UF with a 0.15 sanity cap rather than loosening globally.
- Chasing wider $\phi$ grids for CHN_uf ($-3.5 \to -6$): the limit probe showed no finite grid closes the region; unbounded handling replaced grid-chasing.
- OLS-vs-GMM lumped "source choice" as a user decision: dissolved once the parameterization difference was found; there is only one estimand.

### Verification state

Exporter filters reproduce GMM $e(N)$ exactly in all four cells; CHN_uf runs on base 4 end to end; the unrestricted-vs-LCA-line cross-check moves the gap by under 0.05pp per cell; the baseline was regenerated only after user approval (`a908644`) and the pipeline is strict again.
Full old-vs-new table in the [checkpoint memo](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-08_counterfactual-checkpoint.md).

### Also this session

Todoist parent task 6h4694ChV544Wg4J (restyle sec:counterfactuals to Bryan-Morten 2019, three subtasks) filed for after implementation.
New project memory [reference_stata_coleq_colnames.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_stata_coleq_colnames.md) (the `: colnames` equation-prefix gotcha behind the mu bug).

---

## Continuation (2026-07-08 ~15:00): Phase 3 paper edits

Implementation mode; commits `f4772da`, `7e599b8`, `a38c092`, `40f0d2b`, `8eebb96`, `137b60b`, `b538959` (one per logical edit), `f2e4617` (memo footer).

### What shipped (all in `paper/results_counterfactuals.tex`; numbers from `RP7/output/counterfactual_results.csv` and the two regenerated tables)

1. Equation (1): value term is now $\pi_d \Delta_d (\bar D_d - \bar D^0_d)$; $\bar D^0$ defined as the first-observed-wave urban share; left-censoring sentence rewritten; "$W_{\text{zero}}$" kept as a symbol but described as the no-further-migration scenario.
2. Identification paragraph: switcher returns are LCA-line fitted values recomputed at each accepted point; unrestricted cross-check sentence (moves the gap by under 0.05pp); sparse-switcher line-evaluation sentence; "identified non-parametrically" deleted; lumped-cell return defined as the base-trajectory return plus the unbalanced-mover shift ($\Delta_{\text{unb}}$, auxiliary regression); inference spelled out as the joint 3D $(\phi, \beta, \Delta_{\text{unb}})$ test-inversion region, hull reported, coverage at least 95%.
3. Envelope paragraph cut (D5); Jensen floor kept as two sentences plus a closing floor sentence; law-of-total-variance sentence gone.
4. Decomposition paragraph: IDN lumped cell carries ~95% of the gap; no-within-cell-heterogeneity disclosure; dominance claims recomputed from `counterfactual_decomposition.csv` (TZA never-migrants contribute half the gap, 0.111 of 0.211).
5. Results numbers: IDN $[+7.9, +10.8]$ point $+9.3$; TZA $[+18.6, +33.2]$ point $+23.5$; CHN national $[+10.4, \infty)$ point $+11.7$ with a footnote carrying BOTH the $\ge 90\%$ Bonferroni floor and the inherited unbounded endpoint; value-of-migration under 1% everywhere with the first-wave-baseline explanation.
6. Hukou asymmetry: RF $+15.2$ $[+13.6, +17.2]$; UF point $+2.5$, lower bound $+2.0$, "roughly a sixth of the rural-first magnitudes" replacing "an order of magnitude smaller"; weak-ID footnote (six small switcher cells cannot bound the LCA slope; contrast reads off points and lower bounds).
7. $d_T$ caveat: boundary-crossing cells corrected per `counterfactual_diagnostics.csv` (IDN, TZA, CHN_uf cross; CHN_rf clear); no-fallback bounds refreshed ($+89\%$ IDN, beyond $+90{,}000\%$ TZA at lattice resolution, CHN_uf infinite either way).
8. Hukou bound: $+11.1\%$ per worker (the `_n`-ster value), $+2.1\%$ economy-wide, CI $[+1.8\%, +2.6\%]$; $\pi_{d_N}^{rh}$ glossed as the balanced-panel never-migrant share.

### The Overleaf block (the one open thread)

The first prose edit of the session tripped the one-time prose-rules hook; the retry of that same replacement was then denied by the permission classifier as an edit to a protected Dropbox file, and the denial note warned against working around it.
Before the denial, four of edit 1's five replacements had already landed in `main-updated.tex`; edits 2--7 have not.
`main-updated.tex` is therefore internally inconsistent (equation uses $\bar D^0$; the identification paragraph does not yet define it) until the remaining edits are applied.
The mirror is the complete reference text; syncing the shared region wholesale is safe because the two files are meant to be identical from the scenarios paragraph onward.

### Also flagged (pre-existing, not touched)

- `main-updated.tex` line 784 ends a declarative sentence with "?" ("...would implement?").
- `main-updated.tex` references `sec:welfare-bridge` (line 815) but never defines it; the welfare-bridge subsubsection exists only in the mirror. Whoever finishes the Overleaf sync should either port that subsubsection or expect an undefined-reference warning.
- The pre-existing uncommitted hetDelta/hetmu table changes (CHN sweep-refit thread) remain untouched.

### Verification state

Phase 4 critic-alignment run launched against the mirror, the two regenerated tables, and the three CSVs; report lands at `quality_reports/reviews/2026-07-08_counterfactual-paper-alignment.md`.
No compile run: the mirror is a standalone fragment, and `main-updated.tex` should only be compiled after its remaining edits land.


---
**Context compaction (manual) at 19:37**
Check git log and quality_reports/plans/ for current state.
