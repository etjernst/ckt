# 2026-05-11---inversion table reformat, canonical sters, and a draft paragraph on dropping column~(1)

Mode: implementation + maintenance.
Picked up from [2026-05-07's post-merge smoke hand-off](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-07_post-merge-smoke-fixed.md), which had closed the inversion thread end-to-end at the plumbing level on stale smoke sters.

## Goals

The user wanted to copy a couple of the new inversion-annotated tables into Overleaf's `temp-tables/` folder, wired into a temporary appendix in `main-sections.tex`, so they could eyeball how the new LCA inversion CI rows and the $\Delta_{\text{always}}$ block render in the actual paper.
Hard rule: never touch `main.tex` (legacy, never edit), `main-sections.tex` is the canonical paper source.

Mid-session course corrections shaped the work:

- Round 1: SE columns not aligned the way the user wanted, the `\addlinespace` between SE row and CI row reads as a block break rather than as the CI row "belonging to" its parameter, parameter labels in CI rows are redundant once they're visually adjacent, drop the 90\% CI row and keep only 95\%, drop the `+` prefix on positive numbers, render the preview tables in landscape because they're getting cut off.
- Round 2 (the bigger one): the user flagged that "what you are calling 'new' is actually old."
The smoke sters at [RP7/output/smoke/](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/smoke/) had a May 7 mtime but inherited a GMM fit from the pre-merge inversion branch's staging directory.
The fresh GMM run lived in a sibling worktree at [grc-pipeline-refactor/RP7/output/](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/), dated May 8.
The session re-rendered against those.
- Round 3: the user asked for help articulating why dropping column~(1) (the no-controls, no-time-FE specification) is defensible on substantive grounds, then asked for a careful econometric draft paragraph to put in the paper.
The draft is in this chat transcript only; explicit reminder block at the bottom of this log.

## What got built or changed

### Code edits

[explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)
Lines 830--831: passed `fmt=".3f"` explicitly to both `format_islands_tex` calls so positive numbers no longer get a `+` prefix.
Negatives still render with a leading `-`.
The `format_islands_tex` helper's own default of `"+.3f"` is untouched; only the call sites in `compute_all_inversion_cis` overrode it.

[RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) `grc_tex_table_trend`
Four CI-row stats blocks reduced from `(inv_*_ci90_str inv_*_ci95_str, fmt(s s) labels("90\% LCA inv. CI (...)" "95\% LCA inv. CI (...)"))` to `(inv_*_ci95_str, fmt(s) labels("95\% inv. CI"))`---drops the 90\% row entirely and uses a single uniform label across all four blocks ($\Delta_{\text{never}}$, $\bar{\Delta}$, $\Delta_{\text{always}}$, $\phi$).
Added a post-render `filefilter` pass that strips the `\addlinespace` esttab inserts between the SE row and the CI row of each block, so the CI row visually attaches to its parameter.
The pattern uses `\BS\BS\r\n\BSaddlinespace\r\n95\BS% inv. CI` --- note CRLF, not just LF, because esttab writes Windows line endings here.
Earlier attempt with `\\\\\n\\addlinespace\n` failed silently (no match) for that reason.
Also added `\\` between the M\"obius singularity tablenote and `\bottomrule` (the line-too-long `! Misplaced \noalign` LaTeX compile bug from the previous session never showed in the Stata-side smoke because that smoke only verified .tex emission, not LaTeX compile).

[RP7/scripts/_smoke_table_overleaf.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_table_overleaf.do)
New file (untracked).
Stages canonical IDN+TZA cuu sters from `grc-pipeline-refactor/RP7/output/`, runs `attach_inversion_ci` for 10 cells, renders IDN and TZA tables via `grc_tex_table_trend`.
Two skip-globals: `$skip_stage` (bypass the canonical-ster copy) and `$skip_attach` (bypass the python inversion compute).
Both globals were essential during this session's debugging to avoid 5-minute re-runs of the python compute on each iteration.

### Overleaf edits

[temp-tables/GRC_IDN_consumption_urban_unb.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/temp-tables/GRC_IDN_consumption_urban_unb.tex) and [temp-tables/GRC_TZA_consumption_urban_unb.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/temp-tables/GRC_TZA_consumption_urban_unb.tex)
Refreshed with the canonical (May 8) sters' point estimates plus inversion CIs in the new format.

[sections/app_inversion_preview.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/sections/app_inversion_preview.tex)
Both tables wrapped in `\begin{landscape}...\end{landscape}`.
Tablenotes updated to drop the "90\% and" reference now that only 95\% CIs are rendered.

[main-sections.tex](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/main-sections.tex)
Single `\input{sections/app_inversion_preview}` line added in the appendix block, marked `% TEMPORARY---delete once preview is reviewed`.

## Decisions, with the why

Decision: use sters from the `grc-pipeline-refactor` sister worktree rather than this worktree's `RP7/output/smoke/`.
Why: user flagged that "what you are calling 'new' is actually old".
The smoke sters' mtime was May 7 but their GMM fit was a byte-copy of pre-merge staging output; the post-merge code shape produced different (and apparently worse) convergence on column~(1) of TZA in particular ($J = 63$, Converged = N).
The May 8 grc-pipeline-refactor sters had fresh fits with the production code path, matching the canonical Overleaf table's column~(1) numbers.

Decision: drop the 90\% inversion CI row entirely.
Why: user-requested.
Two CI rows under each parameter (90\% and 95\%) felt redundant and crowded the table; the 95\% row alone carries the inversion message.

Decision: drop the parameter name from CI row labels (`"95\% LCA inv. CI ($\Delta_{\text{never}}$)"` becomes `"95\% inv. CI"`).
Why: user-requested.
With only one CI row directly below the SE row, the visual proximity unambiguously identifies which parameter the CI belongs to.
The shorter uniform label also fixed the SE-alignment artifact---the longer label was widening the `l` column and shifting all centered `c` columns right.

Decision: post-process the .tex with a `filefilter` pass instead of finding a `nogap` or similar esttab option.
Why: tried several esttab options; none cleanly suppressed the `\addlinespace` that esttab inserts between body and stats.
The post-process is one extra pass over a 30-line file per call; runtime cost is negligible and the pattern is local to the inversion CI rows.

Decision: use `\BS` (filefilter's literal-backslash escape) and `\r\n` (CRLF), not `\\` and `\n`.
Why: first attempt errored with "Unresolved backslash escape sequence. Use '\BS' to represent a backslash character.": Stata's `filefilter` has its own escape syntax and does not interpret `\\` as a literal backslash.
Second attempt used `\BS` correctly but `\n` only and failed silently because esttab emits CRLF on Windows, not LF.
The pattern that worked: `\BS\BS\r\n\BSaddlinespace\r\n95\BS% inv. CI`.

Decision: stage canonical sters into `RP7/output/` rather than render directly from `grc-pipeline-refactor/RP7/output/`.
Why: `grc_tex_table_trend` reads sters from `$dir/output/`, hardcoded.
The user-facing alternative would be to add a `sterdir()` option to the program signature, which is more invasive than necessary for a one-off preview.
Cost: `RP7/output/` now has 40 sters from the sister worktree, plus inversion macros attached on top.
This is fine for the preview but should be cleaned up before any production master run (see "Open items").

Decision: add `\skip_stage` and `\skip_attach` globals to the smoke driver.
Why: during the debugging cycle, the staging step kept silently overwriting the inversion macros attached on the previous run.
The first time this manifested was the run with `\skip_attach 1` where the macros were cleared because the canonical sters had been re-copied at the top of the script.
The globals make the script idempotent and allow render-only / attach-only iteration without paying the 5-minute python compute each round.

Decision: use a paragraph in the paper body to justify dropping column~(1), not just a footnote saying "all columns include time FE."
Why: the inversion CIs are a new contribution; readers will notice the empty CIs and the J-rejection in column~(1) and will want to know why we don't show that specification.
A paragraph anchors the choice in the LCA's structure (single line in $\mu$-space, period contamination has trajectory-specific weights) and lets the J-test and inversion-CI behavior land as evidence.
A footnote alone shifts that burden onto the reader.

Decision: phrase the paragraph as "LCA's overidentifying restrictions are rejected" rather than "identification breaks."
Why: the Hansen $J$-test is a specification test, not an identification test.
The model is overidentified either way; what fails when time FE are excluded is the empirical fit of the maintained restrictions, not whether the parameters are theoretically identifiable.
The user's framing was "breaks identification" but I softened it to be econometrically defensible.

## Approaches rejected and the reason

Approach: filefilter with `\\\\` (double-double-backslash) for literal `\\`.
Why dropped: Stata's `filefilter` does not use `\\` as the literal-backslash escape; it uses `\BS`.
The first run errored loudly with the unresolved-escape message.

Approach: filefilter with `\BS\BS\n\BSaddlinespace\n95\BS% inv. CI` (LF-only).
Why dropped: esttab writes CRLF on Windows; LF-only pattern failed to match silently.
The .tex looked unchanged after the pass and the user only caught it on visual inspection of the rendered file.

Approach: re-render using the May 7 smoke sters at `RP7/output/smoke/`.
Why dropped: those sters are byte-copies from the pre-merge inversion branch's staging directory with stale GMM convergence behavior, not the post-merge canonical fit.
Symptom: TZA column~(1) showed $J = 63$, Converged = N, $\Delta_{\text{always}} = -138.579$ with $SE = 5950$, none of which matched the canonical Overleaf table.

Approach: edit `grc_tex_table_trend`'s signature to accept a `sterdir()` option pointing at `grc-pipeline-refactor/RP7/output/` directly.
Why dropped: invasive program-signature change for a one-off preview.
Staging sters into `$dir/output/` keeps the program untouched and uses its existing `$dir/output/` lookup convention.

Approach: keep the longer CI labels and rely on `varwidth(20)` truncation.
Why dropped: `varwidth(20)` truncates at 20 chars but the underlying `l`-column width is still determined by the full label.
Truncation does not undo the column-width side effect that shifts the centered `c` columns.

Approach: write the paragraph to defend column~(1) on pedagogical grounds (showing how much period effects matter for identification).
Why dropped: the user's clear preference was to drop column~(1) from the main table because it "looks terrible" with empty CIs and an obviously misspecified $J$-test.
The pedagogical argument is still valid but lives in the paragraph, not in retaining the column.

## Open items

- The draft paragraph on why dropping column~(1) is defensible.
The user said "remind me to take a look at your added paragraph when we pick back up in a fresh session."
The paragraph lives in this session's chat transcript only.
**See the "Reminder: review the period-FE paragraph" block at the very end of this log for the full draft and the econometric choices made.**
- CHN's column~(1) $J$-statistic in the paragraph is currently "comparable" rather than a specific number.
Pull it from [grc-pipeline-refactor/RP7/output/grc_CHN_cuu_c0.ster](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/grc_CHN_cuu_c0.ster) on a fresh session and substitute the actual value.
- `RP7/output/` of this worktree now holds 40 sters copied from `grc-pipeline-refactor/RP7/output/` plus inversion macros attached on top.
Before running master end-to-end on this branch, decide whether to delete those and let master regenerate them, or keep them as cached starting points.
The mtimes will be misleading.
- The four open items from the 2026-05-07 hand-off carry over:
  - Run `0_master.do` end-to-end on this branch (hours; cleanest as a dedicated session).
  - Refine grid spacing for paper-final CIs.
  - Inversion CIs on robustness specs.
  - Port `grc_tex_table_trend_robust` and fix the `17_verdier_robust.do` `_never`/`_avg` vs `_n`/`_g` disk-naming bug.
- Uncommitted changes to commit before /clear:
  - `M explorations/python-grc/lca_inversion.py` (fmt=".3f" for inversion CI strings).
  - `M RP7/scripts/0_programs.do` (CI row collapse, label change, addlinespace strip).
  - `?? RP7/scripts/_smoke_table_overleaf.do` (new file, untracked).
  - `M RP7/output/tables/GRC_{IDN,TZA}_consumption_urban_unb.tex` (re-rendered; tables/ is tracked).
- The Overleaf edits are not under git but are persisted via Dropbox sync.

## Picking back up

**If you resume:**
Read [quality_reports/session_logs/2026-05-11_inversion-table-format-and-period-fe-paragraph.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-11_inversion-table-format-and-period-fe-paragraph.md).
Open thread: the draft period-FE-justification paragraph is in this log under "Reminder" below; the user wants to review it before deciding whether to put it in the paper body or settle for a one-line table note.
Next concrete action: paste the draft paragraph back into the conversation, give the user a chance to react, then pull the CHN column~(1) $J$-stat to fill in the placeholder.
State to know: voice.md was Read this session so the prose-rules-enforcer flag is set on the next session; will reset on /clear.
The lca-inversion branch has the four code/config edits above uncommitted.
The Overleaf-side temp appendix renders cleanly via `xelatex main-sections.tex` (verified twice this session, 59 pages including both landscape preview tables).

---

## Reminder: review the period-FE paragraph

The user explicitly asked future-self to look at this paragraph in a fresh session.
Paragraph reproduced verbatim below.

> We include time (survey wave) fixed effects in all reported specifications.
> The LCA restriction $\Delta_{\underline{d}} = \beta + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ posits that dispersion in trajectory-specific returns reflects a single source: worker-level comparative advantage.
> Aggregate period shocks that are not absorbed by time fixed effects enter the $\Delta_{\underline{d}}$ estimates with weights that depend on each trajectory's period coverage: always-rural workers contribute only rural-period observations, always-urban workers contribute only urban-period observations, and switchers contribute mixtures whose composition depends on when they move.
> Period-driven dispersion across $\Delta_{\underline{d}}$ then fails the LCA's overidentifying restrictions because a single line in $\mu$-space cannot reconcile $\Delta_{\underline{d}}$ values that differ both because of comparative advantage and because of how each trajectory averages aggregate period shocks.
> Empirically, omitting time fixed effects rejects Hansen's $J$-test in all three countries (IDN: $J = 86.5$, $p < 0.001$; TZA: $J = 9.7$, $p = 0.021$; CHN comparable) and produces empty LCA-inversion confidence sets across all four reported parameters because no $\phi_0$ on the grid satisfies the test at the 5\% level.
> Including period dummies restores failure to reject in IDN ($p = 0.214$) and TZA ($p = 0.084$) and yields non-empty inversion intervals.

Three choices the user might push back on:

1. "Posits that dispersion ... reflects a single source" is a soft framing of the LCA.
A stronger version would be "imposes that the only systematic variation in $\Delta_{\underline{d}}$ across trajectories comes from $\mu_{\underline{d}}$."
The soft framing matches the paper's existing hedging around the LCA being an approximation.
2. "Fails the LCA's overidentifying restrictions" is phrased as a property of the moment fit, not as "biases $\phi$."
The bias direction depends on the joint distribution of period shocks and trajectory composition, which the data do not pin down; the $J$-rejection is the cleanest claim.
3. CHN's column~(1) $J$-stat is "comparable" rather than a specific value.
Pull it from [grc-pipeline-refactor/RP7/output/grc_CHN_cuu_c0.ster](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/grc_CHN_cuu_c0.ster) and substitute.

The user's stated alternative was a one-line table note: "All columns include survey-wave fixed effects."
That works but shifts the burden onto a reader who notices the omission to figure out why.
Given that the inversion CIs are a new contribution and the empty column~(1) CIs would be visible to anyone reading the appendix tables, the paragraph belongs in the body if column~(1) gets dropped from any of the tables.
