# 2026-05-07---merge main into lca-inversion, rename inversion-side files

Mode: implementation.
Picked up the hand-off from the morning summclust-noise / inversion-status session.

## Goals

The morning session closed with two paths queued.
This session covered Path A end to end (merge main into lca-inversion, then rebase the inversion-side files onto the new naming) and started Path C (single-cell D-grid wall benchmark).

User's explicit ordering at start of session: "Yes let's rebase, then move ahead with C before moving ahead with the full production, good plan."

Mid-session course correction: when I flagged the merge-vs-rebase tradeoff (48 commits replayed against renumbered scripts vs one shot), user picked "Merge main".

End-of-session correction: user asked to wrap up here, before the D-grid benchmark, and continue in a fresh session.

## What got built or changed

Four new commits on lca-inversion (in order).

- [280bdc3 Merge branch 'main' into lca-inversion](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
Brings post-pipeline-refactor structure (renumbered scripts, STER_NAMING.md, run_grc_with_extra_regressor) and the M4 values switch (nominal/real, $vsfx) onto lca-inversion.
- [c72e3d0 Drop 16 pre-refactor RP7 scripts superseded by main's pipeline refactor](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
Removes 1_summaryStats, 2_OLS_uGRC, 3_heterogeneity_plots, 4_trajectory_bar_graph, 5_GrRC, 6_GrRC_NonAg, 7_OLS_uGRC_hukou, 8_GrRC_hukou, 9_learning, 10/11/12/13/14/15_GrRC_*, 16_heterogeneity_tables.
- [eed4bc8 Update inversion-side files to post-refactor ster naming](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
Aligns 5b_inversion.do, attach_inversion_ci, and test_5b_and_table.do with STER_NAMING.md (estbase = grc_<country>_cuu_<covs2>; suffixes _n / _g / _a).
- [5025184 Add _smoke_5b_one_cell.do for post-merge inversion smoke](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
One-cell smoke driver targeting IDN/cuu/ca; sterdir defaults to RP7/output/smoke.

Files touched in the merge resolution (with the why for each):

- [.gitignore](file:///C:/git/ckt/.claude/worktrees/lca-inversion/.gitignore) and [CLAUDE.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/CLAUDE.md): kept main's content (M4 data_real junction text, post-refactor 4_GrRC.do reference) and folded in lca-inversion's rerun_workdir ignore rules.
- [docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): three layered conflict regions (Active, Active low priority, Completed).
Kept lca-inversion's content (more current, more detailed, supersedes main's earlier "Wire LCA inversion CI" item) and added two genuinely-new low-priority items from main (Verdier-robust inversion CI extension; multistart GMM-basin diagnostic simulation).
- [quality_reports/session_logs/2026-04-23_afternoon-rank-deficient-S.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-04-23_afternoon-rank-deficient-S.md): took main's version.
Strictly more comprehensive (adds stream-reorganization framing).
- Setup scripts that lca-inversion only touched in the initial RP7-creation copy: take main's version.
Affects 0_CHN_hukou_restrictions.do, 0_master.do, 0_path_config.do, 1_processData.do.
- [RP7/scripts/0_setup.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_setup.do): take main's, then re-apply b5d0106's boottest/summclust additions to ssc_install.
- [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): take main's, then port lca-inversion's two substantive contributions.
The Delta_avg within-switcher fix from 5cfe158 was applied to all four sites that compute Delta_avg under the new program structure (run_grc, run_grc_onestep, run_grc_robust, run_grc_robust_vv).
The attach_inversion_ci program from 2b24344 was appended at the end with section header, with internal suffix iteration updated from "_never / _avg / _always" to "_n / _g / _a".
- [RP7/scripts/5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do): added a `local spec3 cuu`; per-spec branch now also assigns the 2-char `covs2` token; estbase becomes `grc_<country>_<spec3>_<covs2>`.
- [RP7/scripts/test_5b_and_table.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/test_5b_and_table.do): same spec3 / covs2 plumbing as 5b.
The grc_tex_table_trend table-render block was dropped because main's program reads from `$dir/output/` (not a configurable sterdir) and does not yet consume the inv_*_ci95_str macros.
Replaced with a simple read-back of the inversion macros from a single staging ster.
- [RP7/scripts/_smoke_5b_one_cell.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_one_cell.do): new file; one-cell smoke driver.

Files NOT touched (but discussed):

- explorations/python-grc/demo_lca_inversion_ci.do: legacy proof-of-concept against rerun_workdir/output/ with its own pre-rename names.
Standalone exploration code, not on the production path.

## Decisions, with the why

Decision: merge main into lca-inversion rather than rebase.
Why: 48 commits replayed against renumbered, renamed, and consolidated scripts means many rounds of "translate this edit to live in 4_GrRC.do instead of 5_GrRC.do."
Merge is one shot; team workflow already uses merge commits (PRs #3, #4); merge is consistent with team practice.

Decision: take main's version for the four setup scripts that lca-inversion only touched in the initial RP7-creation copy (0_CHN_hukou_restrictions, 0_master, 0_path_config, 1_processData).
Why: lca-inversion has no substantive edits on these; main has the refactor work.
Re-applying nothing to main's version is the right call.

Decision: take main's 0_setup.do and re-apply only the boottest/summclust addition.
Why: that addition (b5d0106) is the only substantive lca-inversion edit on 0_setup.do; everything else in lca-inversion's version is the unedited initial copy.

Decision: take main's 0_programs.do and port lca-inversion's substantive contributions on top.
Why: main's version has the Phase 2 / M3 grc_tex_table_trend unification, the deletion of run_grc_hukou as a near-duplicate of run_grc, and the new run_grc_with_extra_regressor program.
Reapplying the Delta_avg within-switcher fix (4 sites under main's program structure) preserves lca-inversion's substantive bug fix.
Appending attach_inversion_ci preserves the inversion CI wiring.

Decision: drop the lca-inversion run_grc_hukou Delta_avg fix.
Why: main's pipeline refactor deleted run_grc_hukou as a near-duplicate of run_grc on 2026-04-30 (`run_grc_hukou (DELETED 2026-04-30)` comment is in the file).
Nowhere for the fix to land.
Hukou estimation now goes through run_grc with the hukou-disambiguator in the estbase string.

Decision: defer porting the lca-inversion 2b24344 grc_tex_table_trend extension (the esttab s() clause that emits inversion CI rows from inv_*_ci95_str e()-macros).
Why: main's Phase 2 / M3 unification reshaped grc_tex_table_trend; the extension needs careful re-porting onto the new program shape.
Out of step 2's scope; tracked as TODO in test_5b_and_table.do.

Decision: take main's version of the 2026-04-23_afternoon-rank-deficient-S session log on the AA conflict.
Why: main's version is strictly more comprehensive.
Adds the stream-reorganization (A/B/C) section, the naming-convention update note, and reorganizes the next-steps by stream.
lca-inversion's content is a strict subset.

Decision: remove all 16 pre-refactor numbered scripts (`1_summaryStats`, `2_OLS_uGRC`, `3_heterogeneity_plots`, `4_trajectory_bar_graph`, `5_GrRC`, `6_GrRC_NonAg`, `7_OLS_uGRC_hukou`, `8_GrRC_hukou`, `9_learning`, `10/11/12/13/14/15_GrRC_*`, `16_heterogeneity_tables`).
Why: per-file `git log lca-inversion ^merge-base` showed only ff9a665 (ster filename collision fix) ever touched these on lca-inversion beyond the initial copy.
That fix's estbase rename to `grc_<c>_urban_covs_*` is now subsumed by main's pipeline-refactor naming (`grc_<c>_<spec3>_<covs2>`).
Old files contain zero unique content.
User asked me to make very sure they were identical; I confirmed each diff is purely the refactor work.

Decision: drop the grc_tex_table_trend table-render block from test_5b_and_table.do.
Why: main's grc_tex_table_trend reads from `$dir/output/` (not a configurable sterdir).
Pointing it at staging would need either modifying the program to take a sterdir argument, copying staging sters into `$dir/output/`, or hardcoding paths.
All three are out of step 2's scope.
Replaced with a direct read-back of the inversion macros via `estimates use` plus `di e(inv_*_ci95_str)`.

Decision: smoke option A (rename old-naming staging sters to new names) rather than option B (run 4_GrRC.do for one cell).
Why: attach_inversion_ci does not read GMM coefficients from the ster; the Python compute reads from the dataset on disk and writes new e()-macros to whatever ster file path it is told.
The smoke's only job is to exercise the rename plumbing.
Renaming files is ~5 minutes; running 4_GrRC.do for one cell is ~30.

Decision: leave demo_lca_inversion_ci.do alone.
Why: standalone exploration code using the legacy lca_inversion_ci.ado against rerun_workdir/output/ with its own pre-rename names.
Not on the production path.
Updating it now would be churn for no benefit.

## Approaches rejected and the reason

Approach: rebase lca-inversion onto main.
Why dropped: heavy structural divergence (renumbering + renaming + consolidation on main) means many of the 48 commits would conflict at the file-existence level.
Merge is one round of conflicts; rebase is potentially 48.
The wrap-up plan said "rebase" but I flagged the cost; user agreed to merge.

Approach: cherry-pick only the inversion-relevant commits from lca-inversion onto post-refactor main.
Why dropped: 48 commits is too many to triage individually; the merge captures everything in one shot and we can prune in a follow-up commit.

Approach: run 4_GrRC.do for one cell to seed the smoke with real new-naming sters (~30 min).
Why dropped: not needed.
attach_inversion_ci does not depend on in-ster GMM contents.
Renaming the existing staging sters is faster and tests the same plumbing.

Approach: run 4_GrRC.do mainline in full (hours).
Why dropped: way too expensive for a smoke.

Approach: rely on lca-inversion's 2b24344 grc_tex_table_trend extension as-is.
Why dropped: main's Phase 2 / M3 unification rewrote grc_tex_table_trend (collapsed three variants into one parameterized program with `spec(...)` and `covs2set(...)` arguments).
Pasting the lca-inversion extension on top would conflict with the new program shape.
Re-porting needs a careful merge of the two ideas; deferred.

Approach: keep main's tracked .claude/settings.local.json on the merge.
Why partially dropped: the working tree was reset to the local short version (`Bash(git cherry-pick *)`) so the local content is preserved as an uncommitted modification.
Decided not to commit it; user can stage the local additions separately if desired.

## Open items and blockers

The smoke is BLOCKED on a data junction problem.

`RP7/data` is a Windows directory junction targeting `C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6/data/`.
That target directory exists but is EMPTY (verified by `ls` and `find`).
The `.dta` files still live under `ReplicationPackage5/data/` (verified: RP5/data/countries/CHN.dta etc.).
Per MEMORY.md the RP4-to-RP6 bump on 2026-04-22 was supposed to bring data over, but apparently only scripts moved; data was left in RP5.

Resolution options for the next session:

1. Repoint the `RP7/data` junction at `Dropbox/.../ReplicationPackage5/data/`.
Easiest, but lies about which RP version is "current."
2. Repoint at `Dropbox/.../ReplicationPackage5/data/` as a temporary measure and ask the user whether RP6 should be promoted to canonical (which would mean copying data from RP5 to RP6 and re-junctioning).
Cleanest.
3. Ask the user where the data canonically should live before making any changes.

I would not unilaterally re-junction; the user should decide which RP folder is canonical for data.

Other open items.

- Extend main's grc_tex_table_trend to consume the inv_*_ci95_str / inv_*_ci90_str e()-macros (the 2b24344 esttab `s(...)` extension, ported onto main's Phase 2 program shape).
Tracked as a TODO in test_5b_and_table.do.
- Optionally add a `sterdir()` argument to grc_tex_table_trend so smokes can render against a non-default ster directory.
Lower priority.
- D-grid wall benchmark (Path C).
Not started.
The plan was: time one cell of D-grid at IDN $J = 29{,}715$, $B = 9999$, then decide on full 60-cell production.
- Cleanup of `.claude/settings.local.json`.
Working-tree shows it as Modified (local content `Bash(git cherry-pick *)` differs from the tracked version inherited from main).
User can decide: commit the merge of both allowlists, keep local-only as an uncommitted overlay, or move the file to gitignore.
- Old staging dir at `RP7/output/staging/`.
User said it can be deleted.
Not removed yet.
- Safety branch `lca-inversion-pre-merge-2026-05-07` retains the pre-merge tip.
Can be deleted after the next session confirms the merge is healthy.

## If you resume

Read [quality_reports/session_logs/2026-05-07_inversion-merge-and-rename.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-07_inversion-merge-and-rename.md).

Open thread: the post-merge inversion smoke is blocked on the empty RP6/data folder.

Next concrete action: ask the user where the data canonically should live (RP5 or RP6), then either re-junction `RP7/data` or copy the `processed/*.dta` files from RP5 to RP6.
Once data resolves, run [RP7/scripts/_smoke_5b_one_cell.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_one_cell.do) and confirm the four inversion macros land on the four suffixed sters at `RP7/output/smoke/`.

State to know:

- Recent commits on lca-inversion (4 new this session, none pushed): 280bdc3 (merge), c72e3d0 (drop pre-refactor scripts), eed4bc8 (rename inversion-side), 5025184 (smoke driver).
- Safety branch: `lca-inversion-pre-merge-2026-05-07`.
- The renamed staging sters live at `RP7/output/smoke/grc_IDN_cuu_ca{,_n,_g,_a,_d}.ster` (gitignored).
They are byte-identical copies of `RP7/output/staging/grc_IDN_urban_covs_all{,_never,_avg,_always,_delta}.ster` from the pre-merge attach test on 2026-04-30.
- Working tree has uncommitted modifications on `.claude/settings.local.json` (local cherry-pick allow vs main's tracked allowlist).
- Voice profile and manuscript-writing rules were Read this session (prose-rules-enforcer pre-edit flag set; will reset on next session).
- `RP7/scripts/STER_NAMING.md` is the canonical reference for the new naming convention.
Worth a quick re-read at session start.

After the smoke goes green, two natural next steps.

Path 1 (continue inversion polish): port the 2b24344 grc_tex_table_trend extension onto main's Phase 2 program shape so the inversion CI rows actually appear in the rendered table.
Then 5b_inversion can be added to 0_master.do.

Path 2 (D-grid benchmark, deferred from this session): time one cell of D-grid at IDN $J = 29{,}715$, $B = 9999$.
The boottest invocation pattern that worked in the morning's Step 0.6 smoke is `boottest (z_3 z_4 ... z_J), weighttype(rademacher) reps(\`Bdev') nograph`.
At each $\phi_0$ on the grid, rebuild the recoded design, refit the auxiliary OLS, and let boottest return the joint p-value.
CI is the convex hull of $\phi_0$ values where bootstrap $p \geq 0.05$.
Cached parameters: TZA $\hat\phi = -0.5150$, IDN $\hat\phi = -0.30948$, base trajectory 2 for both consumption specs.
