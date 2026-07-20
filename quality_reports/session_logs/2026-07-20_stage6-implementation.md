# Session log 2026-07-20: Stage 6 specced, approved, implemented, gated, merged

## If you resume

Stage 6 is CLOSED: signed off 2026-07-20, merged to main with merge commit `a42219e` (--no-ff, matching the Stage 3-5 close pattern), and pushed to origin (main at `96747dd`; branch `stage6-verdier-cleanup` also pushed).
Next work is Stage 7 of [quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md): rebuild `11b_extrapolation_support_figure.do`'s mu quantities on the per-capita outcome (or read them from the ster, matching `_export_e1_inputs.do`); the materiality was probed at Stage 0 (D-3: claim-affecting for TZA, cosmetic for IDN and CHN); author sign-off required since a numeric change is expected.
Cached state a resumer should know: gate evidence retained until the definitive run now includes `stage6_rootA`, `stage6_rootB`, `stage6_ctroot` in `RP7/tests/stage0` (shadow roots with data junctions to `RP7/data`; the rootA/rootB scripts folders are real copies, pre-fix and post-fix respectively); rc receipt files (`gate_stage6_*_rc.txt`, `contract_stage6_rc.txt`) stay untracked by convention; D-4 (the nonag manuscript promise) remains open; the real-values removal stays folded into Stage 8.

## Goals

Resume at Stage 6 of the pipeline-frontload plan (the `run_grc_robust_vv` sample-persistence fix plus the mandatory `17_verdier_robust.do` table-tail suffix fix), run as Mode 2 through spec, plan, implementation, contract test, gate, review, sign-off, merge.

## Decisions, with the why

The author approved the spec with one standing constraint: nothing gets overwritten.
Everything therefore ran in shadow roots (`stage6_rootA/B/ctroot`); leg B and the contract root use real script copies rather than junctions so even run logs land in the shadow root, not `RP7/scripts/logs`; `$runDashboard` stayed unset so the Python comparison step could not write into `quality_reports/reviews/`.
Correction to the parent plan discovered by reading the fitter before speccing: the stale `_avg` load maps to `_g` (Delta_avg, the table's Average Delta row), not `_a` (Delta_always, which no table consumes); the plan text said `_n`/`_a`.
Gate design: because the stage34/stage5 gate panels ran the Verdier leg on TZA only, no frozen IDN/CHN baseline exists, so the gate generated the old computation fresh as leg A (pre-fix scripts snapshot) and required leg B (fixed code) to match bitwise, mirroring the Stage 5 two-leg pattern; leg A launched before any edit so a running batch never read an edited file.
The fix itself: a program-level `preserve` (auto-restore on exit, success or error) rather than driver-level reloads, because the defect is the program's, not the driver's; the internal cluster-support diagnostics then had to switch from preserve/restore to a tempfile save/use round-trip because Stata allows one preserve per program invocation level (r(621) otherwise, found by the contract test's first run), and the tempfile variant keeps the `duplicates drop` sort so the executed sort sequence is unchanged.
The author declined critic MINORs F4 (defensive stem-length assert; worst case is 31 of 32 chars) and F5 (contract-test `skip_if_exists` hermeticity) as not important; both are recorded as watch-items in the review file.
The TZA `covs_0` convergence flip (frozen tables show Converged = N, refreshed data give Y in both GMM steps) was adjudicated not paper-affecting: the no-covariate columns are no longer included in the paper's reported results; both legs agree bitwise on every TZA ster, so it is a data-refresh effect, not a code effect.

## What got built

`run_grc_robust_vv` in [RP7/scripts/0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do): program-level `preserve` scoping the vfirst build, the missing-vfirst drop, and the `swd_*` instrument columns to the call; cluster diagnostics on a tempfile round-trip; header comment corrected (`_n`/`_a`/`_d`/`_g` suffixes, stale SIDE EFFECT paragraph replaced).
Tail fix in [RP7/scripts/17_verdier_robust.do](file:///C:/git/ckt/RP7/scripts/17_verdier_robust.do) and [RP7/tests/stage0/gate_panel_verdier.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_verdier.do): load `_n` into stored name `_never` and `_g` into `_avg` (stored names unchanged, matching `grc_tex_table_trend_robust`).
Contract test [RP7/tests/stage0/contract_stage6_vv_sample.do](file:///C:/git/ckt/RP7/tests/stage0/contract_stage6_vv_sample.do): injected all-wave missingness into a copy of the TZA cluster index; call 1 fit on 29,260 rows, call 2 on the intact index recovered the full 29,862-row baseline; caller data `cf`-identical after each call; ALL PASS.
Gate infrastructure: `stage6_rootA/B` shadow roots, thin leg drivers, and [gate_stage6_compare.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage6_compare.do) (five checks: cross-leg bitwise sters, marker inventory vs e(N), cross-leg marker `cf`, TZA continuity vs `stage5_root`, table presence).

## Verification

Contract test ALL PASS (rc=0).
Gate ALL PASS: 150/150 ster pairs bitwise, 60/60 markers exactly e(N), 30/30 marker contents identical, 50/50 TZA continuity pairs bitwise, leg A reproduced the stale-tail r(601) with zero tables while leg B regenerated all nine.
Table diff vs the frozen 2026-05-06 production versions: all nine structurally identical once numerals and stars are masked; numeric movement 14-39 of ~76-86 cells per table (per-capita plus Change A); artifacts under [quality_reports/staging/stage6/](file:///C:/git/ckt/quality_reports/staging/stage6/).
critic-stata on the diff: 93/100, no CRITICAL, no MAJOR; adjudication in [the review file](file:///C:/git/ckt/quality_reports/reviews/2026-07-20_stage6-verdier-cleanup-review.md).

## Gotchas recorded

One preserve per program invocation level: a program-level `preserve` makes any later `preserve` in the same program fail with r(621); nested programs may each preserve.
In a Stata log, `di` lines inside an aborted `capture noisily` block still appear as command echoes, so grepping for PASS strings can show echoes of assertions that never executed; check the rc receipt and look for output lines without the leading `. ` prompt.
The morning background watcher was reaped by the session-idle cleanup (about 30 minutes, per the standing memory); the persistent Monitor tool survived and delivered the completion event.
Two parallel StataMP batches on 4 cores drift apart in pace without either being stuck; the legs finished within minutes of each other anyway (about 3.8 and 3.7 hours).

## Open items

Stage 7 (11b figure scale) is next; then Stage 8 (config hygiene sweep including the real-values removal), Stage 9 (Change B), and the definitive run.
D-4 (nonag manuscript promise) remains open at the parent plan.

## 2026-07-20 close-out addendum

Main (`89d28fc..96747dd`) and the branch `stage6-verdier-cleanup` were pushed to origin at the author's request at the end of the session.
The author's three adjudications, all mid-afternoon 2026-07-20: sign off and merge; leave critic MINORs F4/F5 unfixed; the TZA covs_0 convergence flip is not paper-affecting because the no-covariate columns are no longer in the reported results.
