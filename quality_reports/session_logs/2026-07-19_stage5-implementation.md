# Session log 2026-07-19 to 2026-07-20: Stage 5 specced, approved, implemented; gate in flight

## If you resume

Stage 5 (inversion CIs key off e(sample)) is implemented and committed on branch `stage5-inversion-esample` (spec+plan `69af0de`, implementation `2ab4b21`); smoke and contract tests are ALL PASS; the gate is partially adjudicated with the attach batch still running.
Two things are pending and both need Emilia.
First, critic-fix approval: the adjudicated critic-stata review at [2026-07-19_stage5-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-19_stage5-critic-stata.md) proposes fixing the CRITICAL (`$vsfx`-blind attach paths in `attach_inversion_ci` plus the `5b`/`5c` parent guards, a pre-existing defect the new marker lookup inherited), the MAJOR (move the dead `estimates esample:` declaration to after the suffix loop so the program returns with the parent estimates active and their true sample declared), and two trivial MINORs, declining one MINOR; all proposed edits are nominal-track no-ops so gate results stay valid.
Second, gate sign-off and merge after the attach legs finish.
Gate state: COMPLETE and PASS on all three checks (2026-07-20, 01:55).
Refit identity 210/210 PASS_BITWISE against `stage34_root/output`; marker inventory 42/42 parents with exactly e(N) rows; attach legs 80/80 cell-suffix pairs identical between leg A (fallback, the old computation, 20 loud warnings as expected) and leg B (marker path, zero warnings)---all inv_* scalars, CI strings, and bitwise e(b).
Artifacts: [gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage5/gate_results.csv), [marker_inventory.csv](file:///C:/git/ckt/quality_reports/staging/stage5/marker_inventory.csv), [attach_compare.csv](file:///C:/git/ckt/quality_reports/staging/stage5/attach_compare.csv).
Cleanup queue for stage close: smoke/contract artifacts `smk5_*` and `smk5c_*` in `RP7/output`, and the `smk5c` marker was deliberately erased by the contract test.

## Goals

Resume at Stage 5 of the pipeline-frontload plan, treat it as Mode 2, and carry it through spec, plan, implementation, tests, and gate.

## Decisions, with the why

The core design fact, verified empirically before the spec: Stata does not persist `e(sample)` inside a saved ster (probe: `e(N)`=22 but marker count 0 after `estimates use`), and `estimates esample:` is a declaration, not a recovery, so keying the inversion off the fit sample requires a fit-time persisted marker.
Author decisions 2026-07-19: markers written for EVERY fit (not just inversion consumers), labeled; loud-warning fallback on legacy sters rather than a hard refit error, guarded by the e(N) assert in both paths; per-cell marker files (Claude's recommendation over the author's index-per-run suggestion, accepted pending plan approval which the author then gave with "ok go ahead") because cells are individually re-runnable, parallel detached batches would race on a shared index, and per-cell files follow their sters through copies.
Gate design deviation from the plan text, decided after discovering the stage34/baseline sters carry NO attached inversion scalars (the earlier gate panels never ran 5b): there is no frozen attached-CI baseline, so the gate generates the old computation fresh as leg A (fallback path on marker-less ster copies) and requires leg B (marker path) to match it exactly; same evidentiary content, no baseline needed.
The e(N) contract guard uses exit 460 (459 was taken by the contract-less-data reader error).

## What got built

`save_esample_marker` in `0_programs.do`: snapshots `pid period` keys of `e(sample)` rows to `<estname>${vsfx}_esample.dta` (dataset label naming source ster and fit date) under preserve/restore; called after the parent `estimates save` in all four fitters (`run_grc`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`; the extras program dispatches to `run_grc` so needs no site).
`attach_inversion_ci` rework: loads the parent, reads the marker, merges on `pid period` with a row-index dance that restores sort order (merge re-sorts by key, and row order feeds Python float summation), hard-errors on unmatched marker rows (459) or marker-count/e(N) mismatch (460), declares `estimates esample:`, passes the flag column to Python; marker-less sters get a loud multi-line warning and the reconstruction; both paths assert the Python-side realized count equals parent e(N).
`lca_inversion.py`: `compute_all_inversion_cis` gains an `esample` column argument (subset on flag; missing values inside the flagged subset raise instead of silently dropping) and returns top-level `n_obs`; `attach_inversion_for_stata` passes the flag through and sets the `inv_n_used` local.
Tests in `RP7/tests/stage0/`: `smoke_stage5.do` (marker write, marker-path attach, fallback equivalence on zero-missingness data---ALL PASS, TZA ct, marker rows 29,862 = e(N), identical CI scalars across paths) and `contract_stage5_esample.do` (inject missingness into `female`, fit, refill to simulate a refresh: marker path computes on the persisted 29,616-row fit sample, fallback trips exit 460---ALL PASS).
Gate infrastructure: `stage5_root` shadow root (scripts/data junctions, fresh output), refit drivers `gate_stage5_refit_main.do` and `gate_stage5_refit_hukou_vv.do` (verbatim reuse of the stage34 panel slices; the two batches cover all four fitter call sites), `gate_stage5_attach.do` (sequential legs because both would write `$logs/5b_inversion.log`; pins the lca_inversion sys.path because `0_programs.do` resolves it from `$dir`, which is the shadow root here), `gate_stage5_compare.do` (three checks: refit bitwise identity via gate_harness, marker inventory, leg A vs leg B equality on all inv_* scalars, CI strings, and bitwise e(b)).

## Verification

Smoke and contract tests ALL PASS (logs beside the drivers).
Refit batches rc=0 in about 4 hours; early compare: 210/210 PASS_BITWISE, 42/42 markers e(N)-exact.
critic-stata on the diff: 70/100, one CRITICAL (vsfx, pre-existing, fix proposed), one MAJOR (dead esample declaration, fix proposed), three MINORs (two accepted, one declined); adjudication in the review file.
Attach legs and final compare: pending at handoff.

## Gotchas recorded

`Start-Process -FilePath "stata-mp"` fails (not on the PowerShell PATH); use the full path `C:\Program Files\StataNow19\StataMP-64.exe`.
The bash tool's persistent cwd was left inside `stage5_root` by the junction setup, which made a later repo-root `git add` fail with a confusing pathspec error; run git from `C:/git/ckt` explicitly.
`0_programs.do` resolves the Python module path as `$dir/../explorations/python-grc`, which breaks under any shadow root; attach-side drivers must pin the real path.
The early compare run prints an overall gate verdict even when the attach legs are absent (part 3 skips per-cell and reports vacuous success); rerun after the legs exist.

## Open items

Critic fixes await author approval; then re-smoke and re-run critic per the review loop.
Attach batch finishing, then the full compare rerun, gate artifact assembly, author sign-off, merge.
The real-values (`values=real`) inversion coverage gap is recorded in the review file as out of Stage 5 scope; it belongs to the M4 track.
D-4 (nonag manuscript promise) and the Stage 6 Verdier suffix fix remain open from the parent plan.
