# 2026-07-01 --- OLS/GRC table restructure and Overleaf table plumbing

## If you resume

One-line state: the OLS table restructure is fully shipped (code + regenerated tables + copied to Overleaf), but the parallel GRC table restructure is code-complete yet blocked at regeneration because the RP7-named GRC sters for CHN and the hukou cells are not on disk.

Read first, in this order:
1. This whole log, end to end.
2. The plan: [2026-07-01-ols-grc-table-restructure.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-07-01-ols-grc-table-restructure.md).
3. The paper-side change-list (what the user still edits in Overleaf): [2026-07-01_paper-edits-table-restructure.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-01_paper-edits-table-restructure.md).

The open thread: the CHN and hukou GRC tables cannot regenerate into the new 4-column-plus-CI format because their RP7-named, inversion-attached `ct`/`c1`/`c2` sters do not exist anywhere.
Only IDN-cuu and TZA-cuu have the full sweep in this worktree; every other GRC cell has only the `ca` ster.
The raw CHN/hukou GMM fits DO exist, but only in the coauthor's RP6 output (`C:/git/ckt/output` junction) under the pre-refactor naming (`grc_CHN_rural_first_ct`, no spec token), and probably without the inversion CI attached.

Next concrete action: the user was deciding among three paths for the missing GRC sters.
Option 3 (investigate first) was the recommendation: check the `grc-pipeline-refactor` worktree and git history to learn whether the M11-named CHN sters ever existed here and where they went (the 2026-06-23 data-loss event is a candidate).
Option 1: copy the RP6 old-named fits into `RP7/output` under M11 names, then run only `5b_inversion` to attach the weak-ID CIs (avoids the multi-day GMM re-fit; needs a correctness check that the RP6 fits match the post-refactor pipeline, and must copy OUT of the read-only RP6 junction).
Option 2: re-run the CHN/hukou GRC from scratch (multi-day GMM).
Do NOT re-run the GRC GMM without explicit approval; the user was firm that it takes days.

Cached state:
- Branch lca-inversion, worktree `C:/git/ckt/.claude/worktrees/lca-inversion`.
- Four commits this session: `2467e48` (E2 V2 prototype), `e67e9cd` (CLAUDE.md Overleaf structure), `c1a55ba` (table restructure code), `068f8d7` (regenerated OLS tables + change-list).
- The regenerated IDN and TZA GRC tables (4-col + CI) sit in `RP7/output/tables/` but are NOT committed and NOT copied to Overleaf, because a mixed GRC set (IDN/TZA new, CHN/hukou stale) would break the paper.
- The 16 OLS tables ARE copied to Overleaf `tables/` and committed.
- `$dir` for maand points at the lca-inversion worktree; the table-only regeneration driver is [\_regen_tables.do](file:///C:/Users/maand/AppData/Local/Temp/claude/C--git-ckt--claude-worktrees-lca-inversion/f5c3db97-6ba0-4c01-8298-2d0b73ac6c81/scratchpad/_regen_tables.do) in scratchpad (runs 0-section setup, then 3_OLS/6_OLS/10_make_tables with copyOverleaf 0).
- Unresolved annoyance: Dropbox is pushing Overleaf edits DOWN to local fine, but Overleaf is slow to pull the local table changes UP; the reliable fix is a direct drag-drop upload of the OLS files in the Overleaf UI.

---

## Mode

Implementation (spec/plan, then code edits across seven do-files, then partial regeneration and verification).

## Goals

The session opened with "where did we leave off" (answered: the E2 V2 Step 1.5 prototype gate had run overnight; committed it).
The user then asked to fix an Overleaf table-path problem, which turned out to be missing table files rather than a path bug.
The main request was a four-part restructure of the OLS and restricted GRC result tables:
1. Drop column (1) from the restricted GRC tables (the `c0` spec: no time FE, no covariates).
2. Drop column (1) from the OLS tables (the `reg1` spec: no absorb, no covariates), and comment out the c0 estimation too since it is slow and often non-convergent.
3. Put the Time FE indicator row above the Covariates row in the OLS tables.
4. Add the weak-identification-robust confidence intervals to the main-text GRC tables, for $\Delta_{\text{never}}$ and $\bar\Delta$ only, not $\Delta_{\text{always}}$.
Constraint stated repeatedly: regenerate tables only, do NOT re-run the GRC GMM (it takes days).

## What got built or changed

E2 V2 prototype (committed `2467e48`, from the prior overnight run):
- [proto_e2v2_step1p5.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/proto_e2v2_step1p5.py), its results CSV, and the gate memo [2026-06-30_e2-v2-step1.5-prototype.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-06-30_e2-v2-step1.5-prototype.md).

Overleaf table plumbing:
- Copied [hukou_bound.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/tables/hukou_bound.tex) and `counterfactual_misallocation.tex` from `RP7/output/tables/` into the Overleaf `tables/` folder; they were simply missing there, which is why `sec_results.tex` failed to compile (the `\input{tables/...}` path was already correct).
- Documented the Overleaf folder structure and the "`\input` resolves from the compile root" rule in [CLAUDE.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/CLAUDE.md) (commit `e67e9cd`).

Table restructure code (commit `c1a55ba`):
- [0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): `reghdfe_regressions` drops `reg1` and renumbers to six columns; `grc_tex_table_trend` default `covs2set` drops `c0`, gates the $\Delta_{\text{always}}$ block plus its `_a` ster load plus the Mobius note behind a new `showalways` option (default off), and the blank-row stripper pattern was cut from five columns to four.
- [3_OLS_uGRC.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/3_OLS_uGRC.do) and [6_OLS_uGRC_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/6_OLS_uGRC_hukou.do): `columns(6)`, reordered footers (Time FE above Covariates), renumbered enumerated notes.
- [10_make_tables.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/10_make_tables.do): GRC `columns(4)`, 4-col GRC footers.
- [4_GrRC.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/4_GrRC.do), [5_GrRC_NonAg.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5_GrRC_NonAg.do), [7_GrRC_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/7_GrRC_hukou.do): all 22 `c0` `run_grc` blocks wrapped in `/* */` comments (not deleted).

Regeneration (commit `068f8d7`):
- All 16 OLS tables regenerated (6 columns, Time FE above Covariates, notes renumbered) and copied to Overleaf `tables/`.
- Paper change-list written: [2026-07-01_paper-edits-table-restructure.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-01_paper-edits-table-restructure.md), including the exact `preamble.tex` edits for the GRC captions and notes.

## Decisions, with the why

Decision: gate $\Delta_{\text{always}}$ behind a `showalways` option (default off) rather than hard-removing it.
Why: the user wants only never and average in the main tables, but a flag keeps the always row available for a possible appendix robustness table without a second code path.

Decision: keep the row label `95\% inv. CI` and describe the intervals as weak-identification-robust in prose, rather than relabeling the row.
Why: user preference ("weak-ID robust CI is a bit long"), and notation discipline favors not renaming an existing label.

Decision: the weak-ID CIs are the LCA inversion CIs already produced by `grc_tex_table_trend`, not a new object.
Why: verified against the `temp-tables/` preview and the `5b_inversion` skip-guard, which reads `e(inv_phi_ci95_lo)` off the parent ster, so the CI values persist on the sters and surface at table time.

Decision: also gate the `_a` (always) ster LOAD behind `showalways`, not just the display block.
Why: the load loop used `estimates use ..._a` unconditionally, so a missing `_a` ster would abort a table that does not even report always.

Decision: comment out the `c0` estimation with `/* */` matching only the four-line `run_grc` statement ending at `iterate(...)`.
Why: ending the match before the trailing whitespace avoids per-block whitespace fragility, and a Stata block comment safely swallows the `///` continuations.

Decision: regenerate locally with `copyOverleaf 0` first, inspect, then copy only the finished OLS tables to Overleaf.
Why: writing straight to Overleaf risked pushing broken or half-updated tables; local-first let the GRC blocker surface before anything reached the paper.

Decision: ship the OLS tables but hold all GRC tables back from Overleaf.
Why: IDN and TZA GRC regenerated correctly but CHN and the hukou cells skipped, and a mixed GRC set (some 4-col-with-CI, some stale 5-col) would be incoherent in the paper.

## Approaches rejected and the reason

Tried the initial "path fix" framing for the Overleaf table failure.
Rejected: the `\input{tables/...}` path was already correct (line 39's OLS table uses the same form and compiles); the real cause was two missing generated files.

Assumed table regeneration alone would surface the CIs for all GRC cells.
Rejected after the run: only IDN-cuu and TZA-cuu have the full covariate-sweep sters in this worktree; the generalization from the IDN preview was too optimistic, and I flagged that as my error.

Considered copying the RP6 old-named sters and renaming them on the spot to unblock CHN.
Rejected for now: it touches the read-only RP6 junction and is a data-processing decision that needs user approval and a correctness check that the RP6 fits match the post-refactor pipeline.

## Open items and blockers

1. The CHN and all 12 hukou GRC tables cannot regenerate until the RP7-named, inversion-attached `ct`/`c1`/`c2` sters exist.
See the three options in the resume block; the user was leaning toward investigating first.
2. The regenerated IDN and TZA GRC tables sit uncommitted in `RP7/output/tables/` and are not in Overleaf, pending a coherent full GRC set.
3. The user still needs to apply the paper-side edits in Overleaf per the change-list: retire the `app_inversion_preview` appendix, update the `preamble.tex` GRC captions and notes (Edits 1 to 5 in the change-list), and do the deferred column-reference prose sweep in `sec_results.tex`.
4. Dropbox is not pushing the local OLS table changes UP to Overleaf promptly; the reliable workaround is a direct drag-drop upload of the 16 OLS files in the Overleaf UI, which the user was deciding whether to do.

## State to know

- Only IDN-cuu and TZA-cuu have full-sweep GRC sters here; every other GRC cell has only `ca`.
- `C:/git/ckt/RP7/output` holds 15 sters, all Verdier-robustness ones, no GRC main or CHN sters.
- The coauthor RP6 output (`C:/git/ckt/output` junction) has the CHN and hukou full sweep under old names (`grc_CHN_rural_first_ct`, `grc_CHN_urban_first_ct`, `grc_CHN_rural_only_ct`, `grc_CHN_urban_only_ct`, plus `_c1`).
- The GRC captions and notes live in `preamble.tex` lines 177 to 310 (`\GRCtable`, `\GRCexptable`, `\GRChukoutable`, and the note macros), not in the section files.
- The OLS tables carry their own captions and notes in the generated `.tex`, so OLS note edits happen in the do-files, not the paper.
- `showalways` is the new option on `grc_tex_table_trend`; pass it to restore the $\Delta_{\text{always}}$ block for an appendix.
