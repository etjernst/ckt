# Verification verdicts: the 14 CRITICAL pipeline-review findings

Date: 2026-07-13.
Method: one fresh-context verifier per CRITICAL finding, reading the actual code, classifying each as a genuine code bug, stale paper text, by-design, or refuted, per the researcher's instruction to check code correctness rather than results-versus-paper agreement.
Outcome: 7 code bugs, 6 stale-paper, 1 by-design, 0 refuted.
All verdicts HIGH confidence.

## Code bugs (fold into the definitive re-run, then regenerate)

C6, OLS/FE baseline uses raw consumption, not per-capita.
`3_OLS_uGRC.do` never applies `replace lndepvar = log(consumption/hhsize_cube)`, so its consumption columns regress raw household-total log consumption while the table notes claim per capita and the printed header reads `log(consumption)`; internally inconsistent, not just paper-mismatched.
Fix: add the per-capita replace after each consumption-block load in `3_OLS_uGRC.do` (income blocks untouched).

C4, hukou OLS/FE same raw-vs-per-capita bug.
`6_OLS_uGRC_hukou.do` regresses raw `lndepvar` while its notes say per capita.
Fix: same per-capita replace at the 12 hukou call sites, and correct the `textdepvar()` header.

C1, heterogeneity figure uses raw consumption.
`11_make_figures.do` is the one GRC-family driver that omits the per-capita replace before `heterogeneity_plots`.
Fix: add the replace after each of the three per-country loads.

C3, hukou tables mislabeled "Panel A: Indonesia" for every country.
`create_panel_tex_table` hardcodes the literal `Panel A: Indonesia` at `0_programs.do:1115` and `:1123` regardless of the country passed, and the generated CHN tables carry that wrong label over actual CHN estimates.
Fix: build the panel label from the resolved country name already available at `0_programs.do:1141`.

C10, non-switcher percentage miscounts unbalanced individuals.
In `handle_trajectory_groups` (`0_programs.do:378-384`), individuals with a missing trajectory (the unbalanced ones) evaluate to `non_switcher=0` under Stata's missing-value comparison rules, so the unbalanced summary-stats tables divide balanced non-switchers by the total unbalanced population (IDN 6.6%, CHN 37.6%, TZA 60.9%).
Fix: guard both temp variables on `!missing(trajectory)` so the count excludes individuals who have no trajectory.
Open question for the researcher: the intended denominator, since unbalanced individuals have no trajectory and are therefore neither switcher nor non-switcher; excluding them is the proposed fix, confirm that is what the table should report.

C5, two scripts overwrite the same Verdier cluster-comparison table.
`17_verdier_robust.do:218` (3-country) and `17b_cluster_summary.do:85-86` (5-row, with the hukou splits) both write `cluster_comparison_consumption_unb.tex` with the same label; `17b` is not in `0_master.do`, runs without the skip guard, re-optimizes and clobbers the shared sters and the table, and the compiled paper's prose then disagrees with the table it inputs.
Fix: make one canonical producer (the 5-row `17b`, with its skip guard set) and add it to `0_master.do`, or give the two distinct filenames.
The researcher flagged this as a priority.

C2, migration-patterns figure is balanced-only despite the full-sample framing.
`11_make_figures.do` filters the trajectory bar chart on the balanced-only `trajectory` variable even though it loads the `_unb` file, and the surrounding paper text cites a full-sample non-switcher share without qualifying the figure.
Open question for the researcher: is this figure meant to be balanced-only (then the fix is to label it as such in the caption) or full-sample (then rebuild it on the inclusive `trajectory_2waves`/`_3waves` encoding)?
This one is a judgment call about intended content, not a mechanical fix.

## Stale paper text or stale committed tables (code is correct)

C7, the OLS results prose narrates a 7-column progression, but the code produces 6 and its own table notes describe 6.
The prose splits a nonexistent "column 1 has no time FE" from "column 2 adds time FE"; time FE is in every column.
Fix: update the prose in `main-updated.tex:634-656` to 6 columns.

C8 and C14, the GRC results prose narrates a "column 5, linear time trend" that no version of the GRC code ever produced (trend lives only in the OLS path), and requotes old numbers.
Fix: rewrite `main-updated.tex:705-740` to the actual 4-column ladder (time FE, +female, +age squared, +all covariates including education) and requote from the refreshed tables.

C9, the prose Delta-never numbers match the archived pre-refactor 5-column tables, not the current 4-column ones.
Fix: same prose rewrite plus requote after regeneration.

C11, the rural-first hukou table appears to reject the J-test only because a stale deprecated no-covariate column is still in the committed table; the columns the current code produces do not reject.
Fix: regenerate the hukou tables (the re-run does this) and recopy to Overleaf.

C13, the default GRC table is 4 columns and the code is internally consistent, but the committed CHN table and the Overleaf copies were never regenerated after the intentional 2026-07-01 drop of the no-covariate column, so they are still 5 columns.
Fix: regenerate CHN (IDN and TZA already done), recopy to Overleaf, update the column-count prose and the `preamble.tex` note macros; optionally fix the stale docstring at `0_programs.do:3263-3264`.

## By design

C12, the drop of individuals missing education is the intended constant-sample-across-columns design, confirmed in the call graph: the sample is fixed once at the richest column's requirement and every narrower column reuses it.
Not a bug.
Caveat for the researcher: the verifier could not find an explicit "the sample is held constant at the smallest column" sentence in `main-updated.tex` or in the table-note macros in `preamble.tex:230-248`; confirm the disclosure exists, or add it, since you noted the paper does disclose this.

## How this feeds the plan

The 7 code bugs join Change A and Change B in the code, so the one definitive re-run regenerates every output correctly.
The 6 stale-paper items are two kinds: the ones that are purely stale committed tables (C11, C13, and the table half of C9/C14) are fixed automatically by the re-run plus the Overleaf recopy, and the ones that are prose errors (C7, C8, the narrative half of C9/C14) are manual edits on `main-updated.tex` with approval, best done after the re-run so the requoted numbers are final.
Two code fixes need a researcher decision before implementation: C2 (intended figure sample) and C10 (intended non-switcher denominator).
C12 needs a disclosure check, not a fix.

## Decided fix approaches (user, 2026-07-13)

Per-capita outcome (C1, C4, C6): fix at the source, as early in the pipeline as possible, to kill the whole drift class.
Build the outcome as per capita once inside `handle_depvar`, `gen lndepvar = log(depvar/hhsize_cube)`, so every downstream script inherits it and the scattered `replace lndepvar = log(consumption/hhsize_cube)` lines become redundant.
This divides by `hhsize_cube` uniformly for the consumption, income, and non-ag outcomes (matching what the scattered replaces already did), and removes the possibility of a future script forgetting the transform.

C2 trajectories figure: build two versions, one balanced-only and one full-sample, and compare them before deciding which the paper shows.

C10 non-switcher definition: redefine switcher status from the observed choice sequence, not the full balanced-only trajectory.
In the unbalanced sample (the summary-stats tables and the trajectory overview), a switcher is anyone observed in both states, that is with both a `choice==0` and a `choice==1` round, even if observed in only two rounds; someone all-`0` or all-`1` across their observed rounds is a non-switcher.
In the balanced sample, keep the trajectory-based classification and exclude the unbalanced individuals.
This yields the "how many people in the overall sample never move" count the researcher wants, using the less-strict observed-switching sense in the unbalanced world.

C12: add the constant-sample statement to the generated table notes, so the "sample held constant across columns at the most restrictive specification" disclosure is explicit in the paper.

Fix batch: queue C1, C3, C4, C5, C6, plus the C10 redefinition, the C2 two-version figure, and the C12 table-note addition, alongside Change A and Change B, all landing in the one definitive re-run.
The stale-paper prose edits (C7, C8, C9, C14) follow the re-run, once the requoted numbers are final.
