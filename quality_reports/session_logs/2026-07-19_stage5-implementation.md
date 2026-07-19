# Session log 2026-07-19 to 2026-07-20: Stage 5 specced, approved, implemented; gate in flight

## If you resume

Stage 5 is CLOSED: signed off 2026-07-20, merged to main (merge commit `d8ec610`), and pushed to origin (main at `89d28fc`; branch `stage5-inversion-esample` also pushed).
Next work is Stage 6 of [quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), run as Mode 2: spec, then plan, then implement.
It has two parts.
First, make `run_grc_robust_vv` start each Verdier spec from the same baseline sample---the internal drop if missing(vfirst) currently persists across specs.
Second, and mandatory, fix the tail of `17_verdier_robust.do`, which loads sters under the pre-rename suffixes (`_never`/`_avg`) while the fits now save `_n`/`_a`; no run since the suffix rename can regenerate the paper's Verdier robustness tables, so the production `verdier_robust_*.tex` files are frozen 2026-05-06 artifacts.
Branch from main at `89d28fc`.
Cached state a resumer should know: gate evidence is retained until the definitive run (`stage5_root`, `stage5_legA_output`, `stage5_legB_output` in `RP7/tests/stage0`, alongside `stage34_root`, `baseline_root`, `baseline_root2`, `stage1_root`); e(sample) markers are now written by every fitter and gitignored in `RP7/output`; the real-values track is DROPPED (memory file `project_real_values_dropped.md`; `$values`/`$vsfx`/`data_real` removal is folded into Stage 8, including the save_esample_marker filename residual the fix-delta re-review flagged); D-4 (the nonag manuscript promise) is still open; rc receipt files (`gate_stage5_*_rc.txt`) stay untracked by convention; `papers/extracted/` holds three files awaiting optional promotion to the central paper store; the NCI request advice has been delivered (Macquarie University Gadi scheme; a compute-sizing benchmark is deferred until the Python simulation code is ready).

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

## 2026-07-20 close-out: sign-off, merge, push, and repository backfill

The author signed off on Stage 5 mid-morning and the branch merged to main with merge commit `d8ec610` (`--no-ff`, matching the Stage 3+4 close pattern), after `f743929` closed the stage in the parent plan and added a gitignore rule for `RP7/output/*_esample.dta`---the smoke run had exposed that markers were untracked, contrary to spec S5-2's marker-follows-ster lifecycle.
The smoke artifacts (`smk5_*` and `smk5c_*` sters and markers in `RP7/output`) were deleted with author approval.
Backfill commit `3db81bb` captured every previously-untracked file under [quality_reports/](file:///C:/git/ckt/quality_reports/) and [docs/session_logs/](file:///C:/git/ckt/docs/session_logs/) (1,105 files) after the author asked that reviews and session logs never sit uncommitted; this swept in the early-July reviews and plans and the Stage 3+4 gate evidence dumps.
Commit `9c80710` tracks [docs/TGMBLM-2026.tex](file:///C:/git/ckt/docs/TGMBLM-2026.tex) (the Econometrica paper that is the foundation for the GRC estimator, kept for future reference per the author).
Commit `89d28fc` tracks [citation_audits/](file:///C:/git/ckt/citation_audits/) (the 2026-07-10 Herrendorf-Schoellman citation-faithfulness audit evidence: claims, chain-of-verification runs, verdicts, final report, plus a staged variant).
`papers/summaries/` turned out to contain only two throwaway pipeline-test JSONs, deleted with author approval; real summaries already live in the central store at `~/Dropbox (Personal)/papers/`.
Main was pushed to origin (`78360cf..89d28fc`) with the Stage 5 branch, per author instruction.
Memory updates: [MEMORY.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/MEMORY.md) now records Stages 1-5 closed with Stage 6 next and the retained gate evidence, and a new memory file records the author's 2026-07-20 decision to drop the real-values track (removal planned into Stage 8; the Stage 5 review CRITICAL on vsfx-blind attach paths is superseded by that removal).
Non-repo work: advice for the NCI Australia server request---scheme choice Macquarie University (Gadi compute) over Macquarie Cloud because the workload is batch Monte Carlo, not persistent services; recommended ANZSRC 2020 FOR codes 380204 Panel data analysis 40%, 380202 Econometric and statistical methods 30%, 380111 Labour economics 30% (noting ANZSRC 2020 has no development-economics field; 380104 is economics of education, a trap); SEO codes 280108 Expanding knowledge in economics 50%, 150203 Economic growth 30%, 150507 Micro labour market issues 20%.
The allocation is for the Econometrica-targeted simulation study, which is all Python, so Stata licensing on Gadi is not a concern; a service-unit sizing benchmark is deferred until the simulation code can run one timed replication.
Decisions with the why, appended: the backfill covered all untracked quality_reports and session-log content rather than only Stage 5 files because the author's instruction targeted the category and the early-July files were the ones actually at risk; the marker gitignore rule landed in the Stage 5 close because spec S5-2 promised markers follow the ster lifecycle and production runs would otherwise generate a hundred untracked files.
