# 2026-07-14 --- Fix-batch implementation (C1/C3/C4/C5/C6/C10/C2 + Change A) and non-destructive verification

## If you resume

One-line state: seven fix-batch edits are implemented, committed to `main`, and the two substantive ones (per-capita outcome, Change A sample restriction) are run-verified against real data non-destructively; Change B, the parallel launcher, and the definitive re-run are NOT done and are deliberately held.

Read first: this log end to end, then the CRITICAL verdicts [2026-07-13-critical-findings-verdicts.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-critical-findings-verdicts.md), the switcher spec [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) and its plan [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md), and the prior session log [2026-07-13_p7-split-fit-sim-review-p5b.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-13_p7-split-fit-sim-review-p5b.md).

Open thread: the user has redirected. Before Change B, the parallel launcher, or the re-run, the user wants a fresh-context spec+plan for a CRITICAL review/refactor of the whole data-cleaning and assembly pipeline plus the shared programs, hunting for exactly the class of issue this batch surfaced (in-place `replace` mutation of a generically-named outcome slot). The per-capita cleanup (remove the 25 redundant `replace`s, rename `lndepvar` to something self-documenting like `logpccons`, de-mutate) folds into that refactor, not into more piecemeal patching here.

Next concrete action: none in the code. The user opens a fresh context to spec the pipeline critical-review refactor. Do not launch the re-run until Change B AND that refactor land, so the 7-hour pipeline runs once on final code.

Sequencing decision (load-bearing): the definitive full-pipeline re-run must be the LAST step, after both Change B and the pipeline refactor. Running it before the refactor would force a second re-run afterward.

---

## Mode

Implementation (the approved fix batch from the 2026-07-13 CRITICAL verdicts), then targeted non-destructive verification.

## Goals

The user's asks, in order: "move ahead with the fix batch and then launch the pipeline re-run as we planned"; a pointed correctness question about whether the upstream per-capita move double-applies with the downstream transforms; discomfort with the `replace` pattern and the overall safety of the approach, and a request to explain "every cell self-contained"; "let's quickly run the data build first and see," then a decision to spec a critical pipeline review in fresh context and to rename `lndepvar` (e.g. `logpccons`); "did you update logs to reflect the above."

## What got built or changed (all on `main`)

Seven commits, each atomic, verified as noted:

- `47b60e3` per-capita outcome at source in `handle_depvar` ([0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do)). Changed `gen lndepvar = ln(depvar)` to `gen lndepvar = log(depvar/hhsize_cube)` so every processed dataset stores the per-capita outcome on disk. Fixes C1/C4/C6 (3_OLS_uGRC, 6_OLS_uGRC_hukou, 11_make_figures never applied the per-capita replace, so their consumption outcomes were raw household totals while the notes claimed per capita). GRC drivers keep their now-redundant replaces (identical value). Income datasets and the `iuu` extras path, which trusted a stale "already per-capita on disk" comment, now genuinely carry `log(income/hhsize_cube)`.
- `a11e013` Change A: reflag strict-spec-incomplete individuals as unbalanced in `handle_balance`. An individual missing any of {`hhsize_cube`, `female`, `age`, `education_max`} in any wave is reflagged `unbalanced==1`, leaving the balanced cells for the unbalanced cell with valid waves retained (lump, not delete).
- `1e10113` C10: `non_switcher` classified by observed movement (all-rural or all-urban across observed waves), not the balanced-only trajectory. `switcher` deliberately left trajectory-based (it feeds the GRC average-return weight `pi_within` via `sum ... if switcher==1` and the OLS migrants-only column, so a global redefinition would silently change `Delta_avg`).
- `bf50957` C3: `create_panel_tex_table` builds panel labels from the resolved country (map IDN/CHN/TZA + CHN_rf/CHN_uf) instead of hardcoded position (`Panel A: Indonesia`). Fixes the CHN hukou tables that read "Panel A: Indonesia."
- `72cccec` C5: `17b_cluster_summary.do` is the sole producer of `cluster_comparison_consumption_unb.tex`; removed the clobbering `cluster_comparison_table` call from `17_verdier_robust.do`, added 17b to `0_master.do`, set `skip_if_exists` in 17b. (sonnet subagent; diff reviewed in main thread.)
- `da0ea4e` fixed `run_grc_robust_vv`'s resume guard: it checked a stale `_avg.ster` that is never written (the suffix was renamed to `_g`), so `skip_if_exists` was a no-op on the VV path. Now checks `_g${vsfx}.ster`, matching the actual final save and `run_grc`'s own guard. (Bug surfaced by the C5 subagent; fixed in main thread.)
- `71e9e02` C2: added a full-sample trajectory bar chart (`trajectories_fullsample.{pdf,png}`) alongside the untouched balanced-only one, built on `trajectory_2waves` (pid_obs>=2, the most inclusive pre-built encoding; `_3waves` collapses to balanced for TZA's 3-wave max). (sonnet subagent; diff reviewed in main thread.)

Two mechanical fixes were delegated to `model: sonnet` subagents (C5, C2) running in parallel while the judgment-heavy edits stayed in the main thread; both diffs were reviewed before commit.

## Verification (non-destructive, run against real data)

Ran `data_setup` in memory for IDN/CHN/TZA (no save; reads the hub read-only) via scratch do-files [verify_changeA_build.do] and [verify_percapita.do] (in the session scratchpad). Results:

- Edited programs build end to end, exit 0, no error (exercised per-capita, Change A, and C10's `handle_trajectory_groups`).
- Per-capita applied exactly once: `max|lndepvar - log(cons/hhsize_cube)| = 4.77e-07` (float precision, i.e. identical), vs `0.999` for a divide-twice and `0.999` for raw log-consumption. NOT double-applied. (An initial check reported a spurious 90013-row mismatch; that was a self-inflicted `1e-9` tolerance comparing a float-stored variable to a double recompute, not a real discrepancy.)
- Change A individuals moved from balanced to unbalanced cells: IDN 29, CHN 1, TZA 0 (balanced-individual counts 3284->3255, 14214->14213, 7842->7842). Exactly the tiny magnitude the plan predicted; the A-3 gate passes. The larger raw reflag person-wave counts (145 IDN, 1024 CHN) are individuals `set_covariates` drops anyway (missing `education_max`/`age` entirely), so they do not change the estimation sample.

## Decisions, with the why

C10 scoped to `non_switcher` only, not `switcher`: `non_switcher` has no estimation consumer (only summary-stats programs at [0_programs.do:838/1048] and keepvars), so redefining it is safe; `switcher` feeds `pi_within` and the OLS migrants-only column, so a global redefinition per the verdict's wording would silently move `Delta_avg`. Observed-movement equals the trajectory-based rule for balanced workers, so the balanced summary stats are unchanged.

Per-capita left the 25 downstream `replace`s in place rather than removing them: they recompute from the raw `consumption`/`hhsize_cube` columns (untouched by the source fix), so they are idempotent no-ops, not a second division; verified by the divide-twice probe. Kept for minimal blast radius and per-cell interactive re-runnability. The real downside (the source is not yet the sole source of truth) is deferred to the pipeline refactor, where the `replace`s are removed and `lndepvar` renamed.

C3 minimal label fix, not a structural rewrite: resolve the country per panel and build `\textbf{Panel <letter>: <name>}`; the 3-panel main tables are byte-identical, only single-panel hukou tables change.

Verification done in memory with no writes to the canonical processed hub, because the current committed `.ster` correspond to it and the old data is needed for the eventual old-vs-new comparison; overwriting it to get a count was unnecessary.

Re-run is the LAST step, after Change B and the pipeline refactor: running it before the refactor forces a second run.

## Approaches rejected, with the reason

Removing the 25 `replace`s now: correct eventually, but it belongs in the specced pipeline refactor (paired with the `lndepvar`->`logpccons` rename and de-mutation), not as another piecemeal patch in this batch.

Global `switcher` redefinition for C10 (the verdict's literal wording): would corrupt the GRC `Delta_avg` weights via `sum ... if switcher==1`.

Overwriting the canonical processed hub to verify Change A: unnecessary and destructive; used in-memory `data_setup` instead.

Cramming Change B into the tail of a long session: it is a multi-file, estimand-altering build (new keep-list program, GMM lumping, Python across 3+ files, exporter, VV path, prose, appendix) feeding a 7-hour re-run; rushing it into dwindling context risks a subtle error in Econometrica production code. Held for a focused pass.

## Open items

- Change B (switcher-inclusion consistency) NOT implemented. Held pending the user's go-ahead and, per the new direction, likely folded into or sequenced with the pipeline refactor.
- Pipeline critical-review refactor: to be specced/planned in fresh context (user's next move). Scope: kill the `replace`-mutation pattern, rename `lndepvar` to a self-documenting per-capita name (e.g. `logpccons`), remove the 25 redundant `replace`s, and sweep the data-cleaning + assembly + shared programs for siblings of these bugs. Parameterizing the estimators by outcome-variable name is the fuller fix but a bigger refactor; flagged, not assumed.
- C12 (constant-sample table note): deferred. The GRC table notes appear to come from the Overleaf `preamble.tex` `\GRCtable` macro, which must not be edited locally; goes into the disclosure-prose handoff with Change B.
- Parallel launcher (task 9): not built. Pre-reqs are a read of `9_GRC_extras.do` block structure and the per-instance log globals. The VV skip-guard fix (`da0ea4e`) unblocks its idempotence on the VV path.
- Definitive re-run (task 10): gated; must be last, after Change B + the refactor.
- The 30 MAJOR and 23 MINOR pipeline-review findings remain unverified/untriaged (only the 14 CRITICALs were).
- Scratch verify do-files ([verify_changeA_build.do], [verify_percapita.do]) live in the session scratchpad; reusable, non-destructive.

## How to pick back up

Open a fresh context and write the spec+plan for the pipeline critical-review refactor (the user asked for this explicitly). Treat the per-capita cleanup and the `lndepvar` rename as part of it. Keep the 7 committed fix-batch edits as-is; they are verified where it matters. Do not build the launcher or launch the re-run until Change B and the refactor are both in, then run the full pipeline once on final code.
