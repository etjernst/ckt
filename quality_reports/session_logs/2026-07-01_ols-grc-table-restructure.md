# 2026-07-01 --- OLS/GRC table restructure and Overleaf table plumbing

## If you resume

One-line state: the afternoon follow-on work (OLS whitespace fix, combined landscape summary-stats table, robustness coefplots for IDN/TZA) is built and verified; the summary-stats + OLS piece is committed (`d05e772`), but the robustness-coefplot code and its four figure files are NOT committed yet.
The user has already copied the relevant tables and figures into Overleaf, so no Overleaf copy is outstanding.

Read first, in this order:
1. This whole log, end to end (the afternoon continuation block below `---` carries the current work).
2. The robustness-coefplot plan: [2026-07-01-robustness-coefplot.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-07-01-robustness-coefplot.md).
3. The figure notes (paste-ready LaTeX): [2026-07-01_robustness-coefplot-notes.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/reviews/2026-07-01_robustness-coefplot-notes.md).

The open thread: the robustness-coefplot change is complete and delivered but sits uncommitted in the working tree.
Next concrete action: commit `0_programs.do`, `11_make_figures.do`, `quality_reports/plans/2026-07-01-robustness-coefplot.md`, the notes doc, and `RP7/output/figures/robustness_coefplot_{IDN,TZA}.{pdf,png}` as one commit (leave the pre-existing morning GRC/hetDelta/hetmu table changes untouched).
The user had not yet said "commit" at wrap-up time.

Still-live earlier thread (from the morning, unchanged): the CHN and hukou GRC main tables cannot regenerate into the 4-col-plus-CI format because their RP7-named, inversion-attached `ct`/`c1`/`c2` sters do not exist on disk (only IDN-cuu and TZA-cuu have the full sweep; every other GRC cell has only `ca`).
The raw CHN/hukou fits exist only in the coauthor RP6 output (`C:/git/ckt/output` junction) under pre-refactor names.
Do NOT re-run the GRC GMM without explicit approval (multi-day).
This did not block the afternoon work, which reads the `ca`/`ca_n`/`ca_g` sters that DO exist.

Cached state:
- Branch lca-inversion, worktree `C:/git/ckt/.claude/worktrees/lca-inversion`.
- Morning commits: `c1a55ba`, `068f8d7`, `c547828` (OLS/GRC restructure). Afternoon commit: `d05e772` (OLS blank-row `collabels(none)` fix + combined `sumstats_combined_table` + 16 regenerated OLS tables + 2 new combined sumstats tables).
- UNCOMMITTED: the robustness-coefplot change (see next action above).
- `$dir` for maand points at the lca-inversion worktree. Scratchpad drivers for this session: `_regen_ols.do`, `_regen_sumstats_combined.do`, `_regen_robplot.do` under `C:/Users/maand/AppData/Local/Temp/claude/C--git-ckt--claude-worktrees-lca-inversion/ddaf51b0-.../scratchpad/`.
- Adult-equivalence robustness was requested but deferred: no GRC ever fit with the alternate `hhsize_*` scales; needs a multi-day GMM re-fit.
- CHN has no extra-regressor sters on disk, so the robustness coefplot is IDN + TZA only.

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

---

## Continuation (2026-07-01 afternoon): OLS whitespace, combined sumstats, robustness coefplot

Three follow-on tasks after the OLS/GRC restructure, all Implementation/Maintenance on the table+figure generators.

### 1. OLS header blank rows (committed `d05e772`)
Removed the empty ` & & & \\` filler rows between OLS panels at the generator, not ex post (user was explicit about this).
Cause: `collabels("")` in `create_panel_tex_table` emits an empty column-labels row.
Fix: `collabels("")` -> `collabels(none)` (0_programs.do).
Regenerated all 16 OLS tables; model-number row and stats intact.

### 2. Combined landscape summary-stats table (committed `d05e772`)
New program `sumstats_combined_table` in 0_programs.do; called twice (unb, bal) from 2_summaryStats.do.
Side-by-side layout: countries as column blocks (All/Rural/Urban/Diff. per country), 13 columns.
Merges the three per-country `country_summary_stats` outputs by row.
Uses `sidewaystable` (rotating), NOT `\begin{landscape}`+`table` --- the latter loses the float ("Float(s) lost") and cascades a threeparttable brace error.
Also dropped the `\midrule` under the sub-header (user: the cmidrules under the country names already separate; the midrule was copied from the single-country tables and unwanted).
Outputs: `summary_stats_combined_{unb,bal}.tex`. Per-country tables still generated (non-destructive); paper swaps six `\input`s down to two + repoints `\ref`s (user's Overleaf edit, not yet done).
Compile-tested clean (0 overfull).

### 3. Robustness coefplot (NOT yet committed)
New native Stata `coefplot` program `grc_robustness_coefplot <country>` in 0_programs.do; called for IDN and TZA from 11_make_figures.do.
Shows phi, $\Delta_{\text{never}}$, $\bar\Delta$ (three combined panels, specs on the y-axis) for the main `ca` spec plus each extra-regressor robustness spec.
Reads existing sters ONLY (no GMM re-fit): phi from `grc_<C>_cuu[_<fam>]_ca.ster` (`_b[phi:_cons]`), never from `..._ca_n` (`_b[Delta_never]`), avg from `..._ca_g` (`_b[Delta_avg]`).
Plain GMM SEs (95% CI), per user.
Coverage: IDN = main + exp + maxexp + expsh + maxexpsh + birth (6 rows); TZA = same minus birth (5; birth cell not on disk). CHN has NO extra-regressor sters on disk, so excluded.
Adult-equivalence robustness requested but NOT built: `hhsize_{oxford,oecd,root,comp,pse}` scales exist in the data build but no GRC was ever fit with them (main always divides by `hhsize_cube`); would need a multi-day GMM re-fit. Deferred with user approval.
Aesthetics after two rounds of user feedback: wide 19:6 (`xsize(19) ysize(6)` on graph combine); color by group (Main navy `16 62 106`, experience lavender `128 116 168`, birth orange `216 128 60`); `xscale(range(0))` + `xlabel(#6)` to force even ticks to 0 (this also killed a stray vertical bar --- it was the y-axis sitting next to the data when the range did not reach 0); removed the embedded country title (goes in LaTeX `\caption`); kept the three Greek panel labels.
Figure titles are Greek via the non-embedded base-14 `Symbol` font --- renders in Overleaf/Adobe, but flag for strict-submission font-embedding checks (offered a gs embed pass; user did not request).
Files: `output/figures/robustness_coefplot_{IDN,TZA}.{pdf,png}`, plan at `quality_reports/plans/2026-07-01-robustness-coefplot.md`.

Figure notes written to `quality_reports/reviews/2026-07-01_robustness-coefplot-notes.md` (full `\begin{figure}` blocks, both countries).
Notation matched to the GRC table notes in `preamble.tex`: $\phi$, $\Delta_{\text{never}}$, $\bar\Delta = \sum_{\underline{d}} \pi_{\underline{d}} \Delta_{\underline{d}}$; `\caption` + `\floatfoot{\small ...}` style; Title-Case caption to match `fig:heterogeneity`.
Corrected a wording bug the user caught: the robustness rows are NOT cumulative --- each is Main + exactly one added covariate (verified: `covsall = "\`regressor' female age2 education_max education_max2"` = main ca set + the single regressor).

### Open items
- Not committed: task 3 (robustness coefplot) --- `0_programs.do`, `11_make_figures.do`, the plan, the notes doc, and the four figure files. Offered to commit; awaiting user go.
- Overleaf copies: DONE by the user (combined sumstats `.tex` and robustness figure `.pdf` are over). No copy outstanding.
- Paper-side edits still the user's to do inside Overleaf: swap summary-stats `\input`s (six -> two) + repoint `\ref`s; add the two `\begin{figure}` blocks from the notes doc; the GRC/OLS caption edits from the earlier change-list.
- Pre-existing uncommitted GRC/hetDelta/hetmu table changes from the morning session remain unstaged (left untouched).
