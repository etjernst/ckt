# Session log 2026-07-17: Stage 1 implementation and gate bundling

## If you resume

Stage 1 (covariate-ladder single source) is implemented, critic-reviewed, smoke-tested, and committed on branch stage1-covariate-ladder, but its equivalence gate has deliberately not run.
Per decision D-5, it gates jointly with Stage 2, so the next work is implementing Stage 2 in this fresh context, then launching the bundled gate refit.

Read first: this log end to end, then the plan's Stage 2 section and D-5 in [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md), then the no-op inventory [noop_lndepvar.csv](file:///C:/git/ckt/quality_reports/staging/stage0/noop_lndepvar.csv).

Next concrete action: implement Stage 2 (Mode 2; the plan section is the approved plan), re-slice the gate panels, rebuild the processed panel cells with the new front-end code, launch gate_stage1.do plus gate_stage1_ct.do detached, compare with gate_stage1_compare.do, expect PASS_BITWISE, commit code plus gate artifact.

Cached state: branch stage1-covariate-ladder with commits 6a5bbf9, 5b66789, 8cbf3d3, b78e4be.
Frozen baseline at [baseline_root/output](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/output) (250 sters).
Shadow root [stage1_root](file:///C:/git/ckt/RP7/tests/stage0/stage1_root) is ready and git-excluded; its output/ is empty.
Stage 0 slice logs are renamed to `*_baseline.log`.
The smoke test in the session scratchpad passed.

Standing reminders: nothing ships to coauthors or Overleaf until the definitive run.
Detached-batch launch discipline follows the reference file on detached Stata batches (see Open items below for the path).
Gloss project-internal codes at first use when talking to Emilia: ct/c1/c2/ca name the covariate-spec table columns---time FE only, plus female, plus age squared, plus education.

---

## Goals

Resume after Stage 0 close and implement Stage 1 of the pipeline-frontload refactor plan: a single source of truth for the GMM covariate ladder, per the approved plan at [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).

Three mid-session course corrections from Emilia shaped the work.
First, she challenged the per-stage refit cost, asking whether the plan meant to re-run only once at the end; this produced decision D-5, bundling the Stage 1 and Stage 2 gates into one panel refit.
Second, she rejected commenting the dead hukou covariate globals and asked for deletion instead.
Third, she flagged too much unexplained shorthand in chat, specifically the ct/c1/c2/ca spec suffixes, which is now recorded in the memory file feedback_define_terms.md.

## What got built or changed

All paths below are absolute.

[0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) gained a new program, `set_covariate_globals`, placed immediately before `set_covariates`.
It is the single source for `$covs_gmm` ("female"), `$covs_gmm2` ("$covs_gmm age2"), and `$covs_gmm_all` ("$covs_gmm2 education_max education_max2").
`set_covariates` now calls it and stashes the resolved ladder via `char define _dta[covs_gmm_all]`, which takes effect at the next hub rebuild.
`run_grc_with_extra_regressor` now calls `set_covariate_globals` and builds its per-fit locals from the shared globals instead of hardcoded strings.
The dead hukou ladders were deleted entirely: four gmm variants (`covs_gmm*_hukou`) and four factor-variable variants (`covs_*_hukou`), eight globals with zero consumers repo-wide.
The deletion was applied via fixer-code after author approval.

Sixteen call sites across three files had their 3-line `covs_gmm` declaration blocks replaced by a single `set_covariate_globals` call: three sites in [4_GrRC.do](file:///C:/git/ckt/RP7/scripts/4_GrRC.do), one site in [5_GrRC_NonAg.do](file:///C:/git/ckt/RP7/scripts/5_GrRC_NonAg.do), and twelve sites in [7_GrRC_hukou.do](file:///C:/git/ckt/RP7/scripts/7_GrRC_hukou.do).
This is the 48 lines the 2026-07-14 audit counted.

[_refit_chn_sweep.do](file:///C:/git/ckt/RP7/scripts/_refit_chn_sweep.do) got the same swap, flagged as a critic-stata MAJOR finding because the script produces real sters.
Its `$dir` still points at the old lca-inversion worktree path, so it is stale scratch and a Stage 8 taxonomy candidate.

The gate-panel slices were re-sliced to match the edited sources: [gate_panel_main.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_main.do), [gate_panel_nonag.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_nonag.do), [gate_panel_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_hukou.do), [gate_panel_ct_main.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_main.do), [gate_panel_ct_nonag.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_nonag.do), and [gate_panel_ct_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_ct_hukou.do).
[gate_panel_verdier.do](file:///C:/git/ckt/RP7/tests/stage0/gate_panel_verdier.do) keeps its prior declaration because its source, `17_verdier_robust.do`, is untouched until Stage 6.

Two new refit drivers were added.
[gate_stage1.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1.do) runs the main, nonag, hukou, and extras legs into the `stage1_root` shadow root, carries the `skip_if_exists` resume guard, and writes its rc file to `gate_stage1_rc.txt`.
[gate_stage1_ct.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1_ct.do) runs the time-FE-only ct supplement as a parallel batch, writing `gate_stage1_ct_rc.txt`, mirroring the Stage 0 two-batch split.

A new compare driver, [gate_stage1_compare.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1_compare.do), enumerates every ster in `stage1_root/output`, runs `gate_compare` against each corresponding ster in the frozen baseline at [baseline_root/output](file:///C:/git/ckt/RP7/tests/stage0/baseline_root/output), and writes the verdict CSV to [quality_reports/staging/stage1/gate_results.csv](file:///C:/git/ckt/quality_reports/staging/stage1/gate_results.csv).
It repoints `$stage0dir` to the Stage 1 staging folder, because `gate_cmp_mata` writes its full-precision b/V dumps to `$stage0dir` unconditionally and would otherwise clobber the Stage 0 dumps.

A new shadow root, [stage1_root](file:///C:/git/ckt/RP7/tests/stage0/stage1_root), was created with `scripts/` and `data/` junctions into the live tree, a real `output/` directory, and a README warning that junction removal must use `cmd /c rmdir`.
It was added to `.git/info/exclude`.

The Stage 0 slice logs in [RP7/scripts/logs](file:///C:/git/ckt/RP7/scripts/logs) were renamed to `gate_panel_*_baseline.log` (and the determinism hukou log to `gate_panel_hukou_determinism.log`), so the Stage 1 refit cannot overwrite them through the shared scripts junction.

The plan file [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) was updated with a new decision D-5, a Stage 1 status paragraph, and a Stage 2 gating note.

The memory file feedback_define_terms.md was extended: project-internal codes need a one-clause gloss at first use in chat.

A smoke test at [smoke_covglobals.do](file:///C:/Users/maand/AppData/Local/Temp/claude/C--git-ckt/2f01539b-a322-46b8-a07a-82f5cac36797/scratchpad/smoke_covglobals.do) asserts that `set_covariate_globals` resolves to the exact pre-refactor strings and is idempotent, and that the deleted hukou globals are empty.
It passed both before and after the deletion.

Four commits landed on branch stage1-covariate-ladder: 6a5bbf9 (Stage 1 implementation plus re-sliced panels and gate drivers), 5b66789 (ct supplement split into a parallel batch), 8cbf3d3 (dead hukou ladders deleted), and b78e4be (plan update recording D-5 and Stage 1 status).

## Decisions, with the why

D-5 (author, 2026-07-17): Stages 1 and 2 gate together with a single panel refit, and the same bundling is available to Stages 3 and 4.
The author challenged the per-stage refit cost; both stages are Tier 2 byte-identity no-op stages touching largely the same files.
The accepted cost is that a red on the bundled gate bisects between two stages, which the per-cell b/V dumps localize.
The full-population run stays a single definitive run at the end.
The Stage 1 gate refit was therefore deliberately not launched this session, even though drivers and the shadow root are ready.

The ct supplement stays in the bundled gate.
Stage 1 alone would not need it, because the ct fits never read the covariate ladder and macro assignments cannot touch data, sort, or RNG state.
Stage 2 changes the outcome-variable path the ct fits consume, so the supplement belongs in the bundle.

Dead hukou ladders were deleted rather than commented, on the author's explicit instruction: do-nothing code should not be kept.

The plan's country-arg for `set_covariate_globals` was dropped, because the hukou drivers use the plain ladder, so an argument with no consumer would be dead surface.

Implementation was committed before the gate ran, even though a stage normally commits together with its gate artifact.
The branch isolates the work, and the standing lesson is to commit frequently because edits have been lost to session resets; the gate artifact commit follows the refit.

Stage 0 slice logs were renamed before any refit, because the refit writes same-named logs through the shared scripts junction, the same mechanism that already forced the hukou baseline log rename during the Stage 0 determinism run.

`_refit_chn_sweep.do` got the ladder swap despite being scratch, because it produces real sters and the fix removes a silent-drift risk at the cost of one line.

## Approaches rejected and the reason

Commenting the unused hukou globals, a critic MINOR suggestion, was rejected by the author; deletion was applied instead.

Trimming the main gate leg to the plan's four-cell panel, dropping the IDN and CHN balanced cells, was rejected: the savings would be small because the slow fits are the unbalanced ones, and re-slicing the slice files to a different cell set invites slicing errors.
Full six-cell coverage matching the frozen baseline was kept.

Launching the Stage 1 gate alone was the plan going into the session, but it was superseded by D-5 the following morning.

## Open items

Stage 2 is not implemented.
The next session implements it per the plan's Stage 2 section: build the per-capita outcome once in `handle_depvar`, parameterized by depvar; rename `lndepvar` to `logpc_<outcome>`; remove every redundant replace-lndepvar site, enumerated in [noop_lndepvar.csv](file:///C:/git/ckt/quality_reports/staging/stage0/noop_lndepvar.csv); and remove the income estimation blocks per D-2 while keeping the income data builds.
Because `handle_depvar` runs at build time, Stage 2 requires the processed data to carry the new outcome, so the hub, or at least the panel cells, must be rebuilt with the new code before the gate refit; decide fresh-location versus in-place at implementation time.

After Stage 2, re-slice the gate panels again from the edited sources, then launch the bundled gate: [gate_stage1.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1.do) and [gate_stage1_ct.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1_ct.do) as two detached Stata batches (`stata-mp -e` via PowerShell Start-Process, never tracked background Bash, which gets reaped about 30 minutes after session idle), then poll the two rc files or watch them with a Monitor.
Then run [gate_stage1_compare.do](file:///C:/git/ckt/RP7/tests/stage0/gate_stage1_compare.do); expect PASS_BITWISE on every pair; commit the gate artifact.

The gate drivers carry `skip_if_exists = 1` and `stage1_root/output` is currently empty, so a relaunch resumes rather than refits.

D-4, whether the manuscript keeps its nonag promise, remains open with the author.

The `stage1_root`, `baseline_root`, and `baseline_root2` junctions must only ever be removed with `cmd /c rmdir`, never a recursive delete.

Pre-existing uncommitted working-tree changes from before this session (modified slide PDFs, deleted papers/inbox PDFs, many untracked files) are not from this session and were left alone.
