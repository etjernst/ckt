# Plan: Stage 6, clean up run_grc_robust_vv and repair the Verdier table tail

Date: 2026-07-20.
Spec: [2026-07-20-stage6-verdier-cleanup.md](file:///C:/git/ckt/quality_reports/specs/2026-07-20-stage6-verdier-cleanup.md) (approved 2026-07-20).
Parent plan: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), Stage 6.
Branch: `stage6-verdier-cleanup`, cut from main at `218ac9c`.

## Implementation

Sample-persistence fix (M1, M2): add `preserve` in `run_grc_robust_vv` after the skip-if-exists check and step resolution, immediately before `gen_vfirst`.
Stata auto-restores preserved data when the program exits, on success and on error alike, so the `vfirst` build, the missing-`vfirst` drop, and the `swd_switcher_*_choice` columns stay scoped to the call.
Every `e(sample)`-dependent computation (the `n_indiv` scalar, `save_esample_marker`, the `Delta_avg` trajectory shares) already runs before program exit, against the fitted data state, so nothing downstream changes meaning.
`save_esample_marker`'s internal preserve nests across the program boundary, which Stata permits (one preserve per program level).

Suffix fix (M3): in the tail of `17_verdier_robust.do`, load `<stem>_n` into stored name `<stem>_never` and `<stem>_g` into stored name `<stem>_avg`; stored names are unchanged, so `grc_tex_table_trend_robust` and the 32-character `_est_` budget are untouched.

Comment corrections (S1): the fitter's header output list (`_never`/`_always`/`_delta`/`_avg` to `_n`/`_a`/`_d`/`_g`), the now-false "SIDE EFFECT" block, and the driver's resume comment (`_avg` to `_g`).

## Contract test (M4)

`RP7/tests/stage0/contract_stage6_vv_sample.do`, on TZA (the smallest country), `covs_0` onestep, following the Stage 5 test conventions.
Construct `vindexA` as a copy of `region` set to missing in ALL waves for an injected subset of pids, so `vfirst` is missing for exactly those pids; keep `region` itself intact as the second index.
Call the fitter twice: first with `vindex(vindexA)` (fits on the reduced sample), then with `vindex(region)` (must fit on the full baseline).
Assert after each call that the caller's row count and content are unchanged (`cf _all` against a pre-call snapshot), and that the second call's marker row count equals the full-baseline non-missing-`vfirst` count computed independently, including the injected pids the old code would have lost.

## Gate (M5, M6): two fresh legs, nothing overwritten

No frozen baseline exists for the IDN and CHN Verdier cells (the stage34/stage5 gate panels ran TZA only), so the gate generates the old computation fresh as leg A and requires leg B to match it, mirroring the Stage 5 gate design.

Leg A (old code): `RP7/tests/stage0/stage6_rootA/` with a real COPY of `RP7/scripts` taken from main before any edit, a `data` junction to the canonical hub, and a fresh `output/`.
A thin driver sets `$dir` to the root and runs the copied `17_verdier_robust.do` verbatim: all three countries, both GMM steps, five specs, 30 parent fits plus subgroup sters and markers.
The stale tail is expected to error (r(601) on the `_never` load) inside the script's own capture wrapper after all sters are saved; that error is itself gate evidence of the defect.

Leg B (fixed code): `stage6_rootB/`, same layout, with a real COPY of the post-edit scripts (a copy, not a junction, so the script's own log lands in the shadow root rather than `RP7/scripts/logs`).
Same driver shape; the fixed tail must complete and write the six `verdier_robust_*.tex` tables plus the three `GRC_*_cluster.tex` copies into the shadow `output/tables/`.

Writes are confined to `stage6_rootA/output`, `stage6_rootB/output`, the shadow logs, and rc receipt files; the data junction is read-only by convention and `$runDashboard` stays unset so the Python comparison step (which writes into `quality_reports/reviews/`) is skipped.
Both legs launch detached via PowerShell `Start-Process` on the full StataMP path with rc receipt files, per the detached-batch convention; leg A launches before the code edits begin so the running batch never reads an edited file.

Adjudication, after both legs:
Tier 2, every paired ster bitwise-identical between legs (leg A executes the same per-call sort sequence as leg B, and the one entry-order difference is erased by the deterministic unique-key `bysort pid (year)` inside `gen_vfirst`, so byte-identity is the expectation; any red is diagnosed, with the plan's tie-order mechanism the only benign escape).
Tier 1, every marker row count equals its parent `e(N)`.
Continuity, the leg A TZA sters byte-match the retained `stage5_root` Verdier refits where present.
Tables, leg B's six tables diffed against the frozen 2026-05-06 `RP7/output/tables/verdier_robust_*.tex`: numeric movement expected (per-capita outcome plus Change A), structural or formatting differences beyond the numbers are findings.
Gate artifact under `quality_reports/staging/stage6/`.

## Review and close

critic-stata on the diff, fix round if needed, then author sign-off on the gate artifact and the table diff summary; commit with the gate artifact and merge per the stage pattern.
Production `RP7/output/tables/` and Overleaf are untouched; regenerated tables remain gate evidence until the definitive run (M7).
