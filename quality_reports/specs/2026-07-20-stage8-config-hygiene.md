# Spec: Stage 8, config hygiene (no estimate change)

Date: 2026-07-20.
Mode: Implementation (Mode 2), but every change is structural or cosmetic; none alters a sample, specification, variable definition, or estimate.
Parent plan: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), Stage 8.
Predecessor: Stage 7 closed and merged 2026-07-20 (merge `096765c`).

## Purpose

Strip dead track-switching machinery, fix a raw-vs-derived data placement, add the required master log, and reorganize the script folder so the shipped `RP7/scripts/` shows only pipeline scripts, clearly-marked entry points, and their supporting utilities.
The equivalence obligation is trivial here: no MUST below touches an estimated quantity, so the acceptance test is "the pipeline still runs and every processed file and reader resolves," not a ster gate.
The one exception that could move a filename or a physical file (the `CHN_hukou` relocation) is guarded so it stays a pure relocation.

## Taxonomy decision (settled by discussion 2026-07-20, author)

Two buckets, confirmed against the actual call graph:

`scripts/utilities/` holds supporting scripts that are not numbered pipeline steps but do ship: the two include-only helpers (`_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`, both `include`d by `12_counterfactuals.do`) and the four standalone drivers (`run_extras_birth.do`, `run_extras_cnu.do`, `run_extras_maxexpsh.do`, `run_master_resume.do`).
The `run_` prefix keeps the launchable drivers visually distinct from the `_export_` includes inside the folder.

A non-shipped scratch folder at `RP7/dev/` (sibling of `scripts/`, so the `RP7/scripts/` -> Dropbox handoff excludes it automatically) holds every ad-hoc driver referenced by nothing in the pipeline: `_smoke_5b_full.do`, `_smoke_5b_one_cell.do`, `_smoke_counterfactual_inputs.do`, `_smoke_packages.do`, `_smoke_table_overleaf.do`, `_smoke_table_render.do`, `_probe_d_ster.do`, `_refit_chn_sweep.do`, `_run_5b_for_attach.do`, `_run_5c_for_attach.do`, `test_5b_and_table.do`.

## MUST

M1. Create `scripts/utilities/` and move the six utility scripts into it.
Repoint the two `include` lines in `12_counterfactuals.do` (currently `include "$dir/scripts/_export_e1_inputs.do"` and the `_hukou` sibling at lines 43--44) to `$dir/scripts/utilities/`.
The four `run_` drivers reference siblings only by absolute `$dir/scripts/...` paths (`0_slice_bootstrap.do`, `0_master.do`), which continue to resolve after the drivers move, so no in-driver path edit is required beyond any USAGE-block doc text that names the driver's own path.

M2. Create `RP7/dev/` and move the eleven scratch scripts listed above into it.
Sweep the output residue out of `scripts/`: `11b_extrapolation_support_figure.log`, `check_waves.log`, and the `tmp/` and `logs/` directories (regenerable; not source).
`RP7/dev/` is kept on file but untracked (author 2026-07-20): the scratch stays available and re-runnable, excluded via `.git/info/exclude` (not `.gitignore`, so the exclusion is not published), matching the untracked `RP7/tests/stage0/` pattern.
Nothing in `RP7/dev/` is deleted.

M3. Remove the `$values`/`$vsfx`/`data_real` machinery entirely (real-values track dropped, author 2026-07-20).
Delete the values-switch block in `0_path_config.do` (lines ~10--31: the `$values` default, the nominal/real branch, the `$vsfx` and `data_real` `$dirdata` assignments, the header comment).
Remove every `${vsfx}` / `$vsfx` occurrence from filename construction: 60 sites in `0_programs.do`, plus `run_extras_maxexpsh.do` (3), `run_extras_cnu.do` (2), `run_extras_birth.do` (2), `0_slice_bootstrap.do` (3).
Because `$vsfx` is the empty string in nominal mode, deleting it is filename-neutral: every produced ster/CSV/tex name is byte-identical before and after.
Remove `data_real` junction references; the `RP7/data_real` junction itself is removed as an operator step (confirm nothing else points into it first).
This supersedes the Stage 5 review CRITICAL on vsfx-blind attach paths: resolution is removal, not threading.

M4. Relocate the four derived `CHN_hukou_*.dta` from `data/countries/` (raw) to `data/processed/` and repoint their readers (critic MAJOR-6).
DATA-SAFETY GATE, verified 2026-07-20: `fsutil reparsepoint query` confirms `RP7/data`, `RP7/data/countries`, and `RP7/data/processed` are all real local directories (error 4390, not reparse points), so this relocation is local-to-local and writes nothing into Dropbox.
Only the top-level `C:/git/ckt/{data,output,scripts}` are junctions into `ReplicationPackage6/`; Stage 8 never touches those.
Re-run the reparse-point check immediately before the move in case the hub is repointed between now and execution; if either dir has become a junction, STOP and surface.
Execute as copy -> verify byte-identity of the copies -> repoint readers -> delete originals, never a bare move, so a mid-step failure leaves the originals intact.
The derived files were verified cf-identical to a fresh regeneration on 2026-07-14, so this is pure relocation; enumerate the reader sites (`0_programs.do` hukou data-load paths, `7_GrRC_hukou.do`, `6_OLS_uGRC_hukou.do`, `5c_inversion_hukou.do`) before editing.
Warning carried from the critic adjudication: any driver that regenerates the hukou files (`0_CHN_hukou_restrictions.do`) must not do so through a `countries` junction into the raw folder.

M5. Add the named master log for the data-construction path (critic MAJOR-5, now required per author 2026-07-14).
A timestamped, named, text-format (`.log`, not `.smcl`) log opened at the top of the cleaning path, following the AEA replication pattern in the project conventions.
Scope to the data-construction path (`1_processData.do` and its callees), not the estimation path.

## SHOULD

S1. Update the docs that name moved paths or the dropped suffix, sequenced LAST (after M1--M4 land and the folder layout stabilizes):
`scripts/README_counterfactuals.md` (references the `_export_e1_inputs*` helper paths), `scripts/STER_NAMING.md` (if it documents the `$vsfx` suffix).
A full replication-package README refresh (`create-readme`) is out of scope for this stage; flag it as a follow-up.

S2. Optional cleanups the plan lists (author to include or defer): the hukou `eststo` naming fix, the learning edge-case flag (`8_learning.do`), and the `1b` cross-check assertion.
Treat each as an independent commit; none blocks the stage.

## MAY

MAY1. Delete the dead `ugrc_regressions` program (identified in the Stage 3 call-chain audit as having no call site in `RP7/scripts/`), if the author confirms it is not a resurrection candidate.
Deferred by default; a deletion, not hygiene, so it needs its own confirmation.

## Out of scope

Change B / switcher-inclusion (Stage 9), the definitive full-population run (after all stages), the D-4 nonag manuscript decision, and any estimate-affecting edit.
If any M-item is found to move a ster or a reported number, STOP and re-classify it as Implementation requiring author sign-off, per the parent plan's human-gate rule.

## Ordering and commits

One logical change per commit, in this order so each is independently revertable:
(1) M1+M2 folder reorg (moves plus the `12_counterfactuals.do` include repoint);
(2) M3 vsfx/values/data_real removal;
(3) M4 CHN_hukou relocation;
(4) M5 master log;
(5) S1 doc updates.
Stage 8 runs on a branch `stage8-config-hygiene` cut from `main`, per the standing branch-per-stage convention.

## Verification

No ster gate (nothing estimate-affecting).
Acceptance: a full clean run of the data-construction path completes; every processed file regenerates; the hukou readers resolve to the new `data/processed/` location; `12_counterfactuals.do` resolves its two includes from `utilities/`; a spot ster refit on one hukou cell and one extras cell produces byte-identical filenames and contents to a pre-Stage-8 refit (proving the vsfx removal is filename-neutral).
`critic-stata` on the touched programs before commit; the folder-move commit needs no critic beyond a path-resolution check.
`git mv` (not delete+add) for tracked scripts so history follows the file.

## Hazards

The `CHN_hukou` relocation is the only data-touching item; its safety gate (M4) is mandatory.
The `$vsfx` removal in `0_programs.do` spans 60 sites; delegate to a `model: "sonnet"` fixer with the precise brief "delete `${vsfx}`/`$vsfx` token from filename strings, leave all other logic untouched," then review the full diff and confirm filename-neutrality on a refit, rather than hand-editing 60 sites.
