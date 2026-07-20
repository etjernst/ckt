# Plan: Stage 8, config hygiene

Date: 2026-07-20.
Spec: [2026-07-20-stage8-config-hygiene.md](file:///C:/git/ckt/quality_reports/specs/2026-07-20-stage8-config-hygiene.md) (approved 2026-07-20).
Mode: Implementation. Branch `stage8-config-hygiene`, cut from `main`.
No estimate-affecting change; acceptance is a clean data-construction run plus one fast-cell filename-neutrality refit, not a ster gate.

## Anchors confirmed by read (2026-07-20)

The generic loader `use_data` (0_programs.do:300-305) reads every country, hukou families included, from `$dirdata/countries/\`country'`.
The only literal `CHN_hukou_*.dta` paths are the four `save` lines in `0_CHN_hukou_restrictions.do` (L31/45/61/77); every read routes through `use_data`, so M4 is four saves plus one loader branch plus the physical move.
`0_path_config.do` sets both `$vsfx` and `$dirdata` inside the values-switch block (L17-32), so M3 must replace that block with an unconditional `global dirdata "$dir/data"`, not just delete it. `$logs`/`$output`/constants below it are independent.
`0_path_config.do:59` already `mkdir`s `$dirdata/processed`, so the hukou destination exists before the L99 hukou-restrictions include runs.
Master include order: `0_path_config` L72, `0_programs` L78, `0_CHN_hukou_restrictions` L99, `1_processData` L101, estimation/tables/figures L103-141.

## Model routing

The three mechanical legs (the `$vsfx` token strip across 60+ sites, the folder moves, the doc-path updates) go to `model: "sonnet"` fixer subagents with precise briefs; I review each returned diff.
The judgment legs (the `use_data` hukou branch, the master-log placement, the vsfx-block replacement in `0_path_config.do`, and every verification adjudication) stay in the main thread.

## Commit sequence

One logical change per commit, each independently revertable.

### Commit 1: folder reorg (M1 + M2)

Tracking status confirmed 2026-07-20: all 45 files under `RP7/scripts/` are tracked. Author decision 2026-07-20: tracking is fine either way, so everything that moves stays tracked via `git mv` (history follows); no untracking dance.

Utilities: `git mv` the six into a new `RP7/scripts/utilities/` --- `_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`, `run_extras_birth.do`, `run_extras_cnu.do`, `run_extras_maxexpsh.do`, `run_master_resume.do`.
Repoint the two includes in `12_counterfactuals.do` (L43-44) from `$dir/scripts/_export_e1_inputs*.do` to `$dir/scripts/utilities/_export_e1_inputs*.do`.

Scratch: `git mv` the eleven into a new `RP7/dev/` (sibling of `scripts/`, so excluded from the `RP7/scripts/` -> Dropbox handoff regardless of git-tracking) --- `_smoke_*` x6, `_probe_d_ster.do`, `_refit_chn_sweep.do`, `_run_5b_for_attach.do`, `_run_5c_for_attach.do`, `test_5b_and_table.do`. Nothing deleted; they stay tracked at the new path.

Delete the stale one-off: `git rm RP7/scripts/tmp/refresh_tables_to_overleaf.do` --- confirmed 2026-07-20 unreferenced by any file, last touched 2026-05-13, its `$dir` points at a removed worktree, and its own header declares it a one-off to delete after use.

Sweep the untracked residue out of `scripts/`: `rm` the stray `11b_extrapolation_support_figure.log`, `check_waves.log`, the untracked `logs/` contents, and the now-empty `tmp/` dir. `$logs` is recreated by `0_path_config.do:55`.

Verify: the four `run_*` drivers' internal `$dir/scripts/0_*.do` references still resolve (absolute, unaffected by the move); `grep -rn "_export_e1_inputs" RP7/scripts/` shows only the repointed `utilities/` paths; no numbered pipeline script references a moved scratch file or the deleted one-off.

### Commit 2: remove the values/vsfx/data_real machinery (M3)

`0_path_config.do`: delete the values-switch header comment (L10-16) and the `if/else` block (L17-32); replace with a single `global dirdata "$dir/data"`.
Strip every `${vsfx}`/`$vsfx` token wherever it appears in string construction (sonnet fixer brief: "delete the `${vsfx}`/`$vsfx` token from every string it is concatenated into --- filenames and any estname/eststo tag alike; it is the empty string in nominal mode so removal is neutral; change no other logic, no row order, no path beyond dropping the token"): 60 sites in `0_programs.do` (a grep confirms these are filename strings plus one explanatory comment at L820, but the brief covers estnames as belt-and-suspenders), plus `run_extras_maxexpsh.do` (3), `run_extras_cnu.do` (2), `run_extras_birth.do` (2), `0_slice_bootstrap.do` (3) --- the driver files at their new `utilities/` locations after Commit 1.
Remove `data_real` references (the L27 assignment is already gone with the block; the three `run_extras_*` headers each carry a multi-line "For real-values mode (deflated CPI, $dir/data_real), edit the ..." comment block --- remove the whole block, not just the token; then grep the tree for any residual `data_real` string).
Operator step, not committed code: remove the `RP7/data_real` local directory (author approved removal 2026-07-20; fsutil confirmed it is a real dir, not a junction); confirm nothing else points into it (`grep -rn data_real scripts/`) before `rm -rf`.
Because `$vsfx` is empty in nominal mode and an undefined global expands to empty, the strip is filename-neutral and safe even if a straggler remains.

### Commit 3: relocate CHN_hukou to processed (M4)

DATA-SAFETY GATE (re-run immediately before touching files): `fsutil reparsepoint query` on `RP7/data`, `RP7/data/countries`, `RP7/data/processed`; all three must return error 4390 (local). If any is a junction, STOP.
Physical move, copy-verify-delete: copy the four `CHN_hukou_*.dta` from `data/countries/` to `data/processed/`, byte-compare each copy to its original (`cmp` or Stata `cf`), then delete the originals only after all four verify.
`0_CHN_hukou_restrictions.do`: repoint the four `save "$dirdata/countries/CHN_hukou_*.dta"` (L31/45/61/77) to `$dirdata/processed/`.
`0_programs.do` `use_data` (L303): branch the load directory by country name, so hukou families resolve to `processed/` and raw countries stay in `countries/`:
```
local sub = cond(regexm("`country'", "^CHN_hukou_"), "processed", "countries")
use "$dirdata/`sub'/`country'", clear
```
Confirm no reader bypasses `use_data`: re-grep `CHN_hukou.*\.dta` across `scripts/` (expect only the four repointed saves); explicitly check `1_processData.do`'s `CHN_hukou` references are country-list locals or comments, not direct `use` of the `.dta`.
Note: `0_CHN_hukou_restrictions.do` reads raw `CHN` from `countries/` (true raw, stays) and now writes derived files to `processed/`, which structurally retires the old "never regenerate through the countries junction" hazard.

### Commit 4: named master log (M5)

Master-level named log confirmed by author 2026-07-20 (AEA pattern, covering the whole run, not `1_processData`-only).
`0_master.do`: after the `0_path_config.do` include (L72, so `$logs` exists) and before `0_setup.do` (L75), open the AEA-pattern log; close it after the final include block.
```
local stamp : di %tdCCYY-NN-DD date("`c(current_date)'", "DMY")
local stamp "`stamp'_`=subinstr("`c(current_time)'", ":", "-", .)'"
log using "$logs/0_master_`stamp'_`c(username)'.log", name(master) replace text
```
Named `master` so it never collides with the per-script `.smcl` logs (e.g. `0_CHN_hukou_restrictions.do:12`); text format for grep-ability; timestamped with username so runs never overwrite; `$logs` is gitignored.
`run_master_resume.do` inherits it via `do 0_master.do`; the standalone `run_extras_*` drivers keep their own logging and are out of scope.

### Commit 5: doc updates (S1)

Sequenced last, after the layout is final.
`scripts/README_counterfactuals.md`: repoint any `_export_e1_inputs*` reference to `utilities/`.
`scripts/STER_NAMING.md`: remove any `$vsfx`/`_r` suffix documentation.
Grep both docs for stale `countries/CHN_hukou`, `data_real`, and top-level path claims; fix what the moves invalidated.
A full replication-package README refresh (`create-readme`) is a follow-up, not this stage.

## Optional (S2 / MAY1), each its own commit if the author opts in

Hukou `eststo` naming fix, `8_learning.do` edge-case flag, `1b` cross-check assertion (S2); delete dead `ugrc_regressions` (MAY1). None blocks the stage; skipped unless the author asks.

## Verification (end of stage)

1. `critic-stata` on the touched programs (`0_programs.do`, `0_path_config.do`, `0_master.do`, `0_CHN_hukou_restrictions.do`, `12_counterfactuals.do`) before the final commit.
2. Data-construction run: `stata-mp -e do 0_CHN_hukou_restrictions.do` then `1_processData.do` (via a small driver that sets `$dir` and includes config/programs), confirm every processed `.dta` regenerates, the four hukou files land in `processed/`, and the master log opens as one timestamped text file.
3. Filename-neutrality proof for M3: refit one fast cell (TZA_bal main GRC, the smallest gate-panel cell) and one hukou cell, confirm the produced ster/CSV/tex filenames carry no suffix and match the pre-Stage-8 names byte-for-byte; the fit contents are unchanged because no sample or spec moved.
4. Reader resolution: run one hukou reader cell (`6_OLS_uGRC_hukou` on CHN rural-first) and confirm it loads from `processed/` (log shows the `processed/` path) and produces the same estimates.
5. Include resolution: confirm `12_counterfactuals.do` resolves both `utilities/` includes.

If any M-item is found to move a ster or a reported number, STOP and re-classify as estimand-affecting per the parent plan's human gate.

## Flagged for author decision

M5 scope. The approved spec says "scope to the data-construction path, not the estimation path," but the parent plan calls it "the named master log ... following the AEA pattern," and the AEA/project convention is a single master-level log covering the whole run.
Recommendation: master-level placement in `0_master.do` (Commit 4 above) --- it is strictly broader, matches the cited AEA pattern and the critic's "master log" language, and still covers the data-construction path.
If the author prefers the narrow reading, the log opens at the top of `1_processData.do` and closes at its end instead, and `0_CHN_hukou_restrictions.do` (which runs before `1_processData` at L99) stays on its own per-script log.

## Rollback

Each commit is revertable on the branch; a mid-stage stop reverts the branch and `main` stays on the last gated commit (the Stage 7 merge).
The CHN_hukou move is copy-verify-delete, so a failure before the delete leaves the originals in `countries/` intact.
`RP7/data_real` removal is the only irreversible operator step; it waits for explicit author go-ahead.
