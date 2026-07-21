# Session log 2026-07-21: Stage 9 plan, approval, and implementation

## If you resume

Stage 9 (Change B, one switcher-inclusion rule across the GMM, the auxiliary OLS, and the inversion) is CLOSED and merged to main.
Merge commit `2201692` (`--no-ff`) carries it in.
Stage 9 is marked CLOSED in the parent plan, [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) (close-out commit `ccc9631`).
The stage plan itself is [2026-07-21-stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md).
Nothing has recomputed yet: the estimation code deliberately hard-stops on the current processed hub, because the keep-list dataset characteristics do not exist until the hub is rebuilt.
The next work is the definitive end-of-stages run, which is now the entire remaining job on the pipeline-frontload refactor.
It rebuilds the processed data (which is also what makes the new keep-list take effect), refits the whole `.ster` population, produces the old-versus-new comparison table with Hansen's $J$, runs the B-8 thin-cells-retained inversion exhibit via the threshold knobs, rebuilds the simulation, and re-certifies P2 parity.
Also on that run's checklist: the hukou dataset rebuild, and a fixture smoke of the standalone Python runner's keep-list CSV check once `output/keeplists/` is populated.
This is a long compute-heavy run, not an editing task.
Cached state worth knowing: the two threshold knobs are `$grc_switcher_keep_min` (5, individuals) and `$grc_switcher_keep_min_vv` (2, clusters) in [0_path_config.do](file:///C:/git/ckt/RP7/scripts/0_path_config.do), plus `SWITCHER_KEEP_MIN` in [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py); a robustness sweep changes those.
One item is open and author-deferred: the existing footnote in `main-updated.tex` saying unbalanced individuals "lack complete trajectories" is now slightly imprecise, since lumped thin-switcher individuals also join the unbalanced group; flagged to the author, not yet acted on.
D-4 (the nonag manuscript promise) also remains open at the parent plan.
The working tree is clean on main; all Stage 9 work is committed.

## Goals

Pick up after Stage 8 close-out: plan Stage 9 against the post-refactor codebase, get approval, implement.

## Decisions, with the why

A fresh plan rather than the 2026-07-13 one: Change A already shipped (`a11e013`) and Stages 1-8 moved every location that plan pointed at; the spec's locked decisions (D1-D8, DA1-DA3) carry over unchanged.
Author approvals (2026-07-21): the threshold is one named constant per path so robustness sweeps change one number (promotes spec MAY 14 to a requirement); the rule is computed at data construction and stored in the saved dataset (option a; "data construction is not a big cost in this project"); balanced-sample runs drop dropped-trajectory individuals outright, loudly in the log, since they have no unbalanced cell; original labels survive in a `trajectory_full` copy; the paper's Verdier robustness section gets a footnote stating the two-clusters-not-five-individuals rule; the hukou rebuild goes on the definitive-run checklist.
Dataset characteristics over tempfiles or a bare text file as the source of truth: the keep decision must travel with the saved data across sessions and languages, and a characteristic cannot be paired with the wrong data version; the CSV under `$output/keeplists/` is audit trail and Python-facing, not authoritative.
`setup_grc_estimation` lumps by default with a `nolump` opt-out for the Verdier drivers, rather than a separate lump program every call site must remember: the safe default is the new consistent behavior, and the Verdier path (which applies its own looser cluster rule inside `run_grc_robust_vv`, where `vfirst` exists) is the only opt-out.
The author's prose direction ("computing the rule inside the Stata estimation setup") conflicted with their numbered pick of option (a); implemented (a) and flagged the discrepancy in chat for correction.

## What got built

See the implementation status section of [the plan](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md) for the component-by-component list.
Files changed: [0_path_config.do](file:///C:/git/ckt/RP7/scripts/0_path_config.do) (two threshold globals, keeplists dir), [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) (`compute_switcher_keeplist`, `write_keeplist_csv`, `stash_switcher_keeplist`, the `data_setup` variants, the `setup_grc_estimation` lump, the `run_grc_robust_vv` cluster rule, the `attach_inversion_ci` passthrough), [17_verdier_robust.do](file:///C:/git/ckt/RP7/scripts/17_verdier_robust.do) and [17b_cluster_summary.do](file:///C:/git/ckt/RP7/scripts/17b_cluster_summary.do) (`nolump`), [utilities/_export_e1_inputs.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do) and [the hukou twin](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs_hukou.do) (-1 lump), [5b_inversion.do](file:///C:/git/ckt/RP7/scripts/5b_inversion.do) and [5c_inversion_hukou.do](file:///C:/git/ckt/RP7/scripts/5c_inversion_hukou.do) (pass `$switchers`), and on the Python side [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py) (both-states `drop_sparse_switchers`, `SWITCHER_KEEP_MIN`, `switchers_kept` passthrough with hard-error agreement check), [lca_inversion_ci.ado](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci.ado), [lca_inversion_ci_helper.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci_helper.py), [run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py) (CSV verification).

## Verification

[test_keeplist.do](file:///C:/git/ckt/RP7/tests/stage9/test_keeplist.do) via `stata-mp -e`, ALL PASS on six scenarios: five both-state individuals kept, four lumped, one-sided (urban-only) lumped, lumping relabels to 999/unbalanced with N unchanged and originals preserved in `trajectory_full`, balanced sample drops exactly the 27 affected person-waves loudly, `nolump` inert, cluster-counted rule keeps 2-cluster and lumps 1-cluster trajectories at threshold two.
The test also parse-checks the edited `0_programs.do` end to end (rerun after the last edit).
A direct pandas smoke confirmed the Python both-states counter (5 both-state pids kept, urban-only trajectory counted 0).
No refits and no hub rebuild: the current hub lacks the new characteristics, so nothing downstream of `data_setup` runs until the definitive-run rebuild, per the plan.

## Open items

Adjudicate the two critic reviews (launched end of session; reports expected at quality_reports/reviews/2026-07-21_stage9-keeplist-{stata,python}-review.md), fix what the author approves, then author sign-off on the branch.
Author to place the drafted disclosure prose and Verdier footnote (bottom of the plan) in the manuscript; the TZA single-person-trajectory claim carries a verify-at-definitive-run TODO.
Definitive-run checklist additions from this stage: hub rebuild (keep-list characteristics), hukou rebuild, keep-set comparison print across the three estimators per cell (spec MUST 1), old-versus-new table with Hansen $J$ and pinned base, B-8 thin-cells-retained inversion exhibit via the threshold knobs, sim rebuild, P2 parity.
D-4 (nonag manuscript promise) remains open at the parent plan, unchanged.

## 2026-07-21 evening continuation: review rounds, dead-code deletion, merge

### Goals

Adjudicate the two critic reviews launched at the end of the prior block (critic-stata, critic-python) and apply whatever fixes the author approved.
The author said "fix everything" on the first review round, then "yes merge" and "delete them please" on the dead-code question once the branch was clean.

### Manuscript disclosure, earlier in this continuation

Before the review rounds, the disclosure prose and the two-clusters-not-five-individuals footnote went into `main-updated.tex` in the Overleaf-Dropbox folder, at the author's request ("please add them").
The paragraph compiled clean with xelatex.
Aux residue was swept and two stray tmp files removed.
The disclosure paragraph sits in the estimation section right after the unbalanced-dummy paragraph.
A `% TODO verify` comment on the Tanzania single-person-trajectory sentence flags a check for the definitive run.

### First review round

Reports: [2026-07-21_stage9-keeplist-stata-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-stata-review.md) and [2026-07-21_stage9-keeplist-python-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-python-review.md).
critic-stata scored 68/100 with one CRITICAL, one MAJOR, and three MINOR.
critic-python scored 82/100 with no CRITICAL, one MAJOR, and six MINOR.
The CRITICAL, verified by direct read before trusting the reviewer: `run_grc_robust_vv`'s three post-estimation blocks (the joint mu test, the per-switcher Delta nlcom/test, Delta_avg) looped the `$switchers` global, which the caller's `setup_grc_estimation nolump` left at the full enumeration, while the GMM itself was built from a trimmed local switcher list.
Whenever the Verdier cluster rule drops a trajectory, those blocks reference an unfitted `mu:switcher_<s>` parameter and error.
`17b_cluster_summary.do` has no capture around the call, so one dropped trajectory aborts the whole run.
This was near-certain to fire in practice, since the TZA single-person trajectory occupies at most one cluster, below the two-cluster threshold.
The Stata MAJOR: the Verdier base trajectory was picked from the full enumeration, ignorant of the cluster rule, so `run_grc_robust_vv` hard-errored whenever the base fell outside the kept set.
The Python MAJOR was latent rather than live: the handoff check misread a whitespace-only string as a supplied-but-empty keep-list, raising a false mismatch.

### First fix round, commit 048a9b6

Every GMM program's post-estimation blocks (`run_grc`, `run_grc_onestep`, `run_grc_robust` at the time, `run_grc_robust_vv`) now loop the `switchers()` argument the system was actually built from, never the `$switchers` global.
The Verdier drivers ([17_verdier_robust.do](file:///C:/git/ckt/RP7/scripts/17_verdier_robust.do), [17b_cluster_summary.do](file:///C:/git/ckt/RP7/scripts/17b_cluster_summary.do)) now compute the cluster keep-list once per country via `gen_vfirst` plus `compute_switcher_keeplist` (which gained an `if` qualifier via `marksample`), write one audit CSV, pick the base and initial values inside the kept set, and pass the list to `run_grc_robust_vv` through a new `keeplist()` option that skips the per-cell recomputation.
`initial_values`'s fallback base is now the first passed switcher rather than a hardcoded 2.
`initial_values` and `initial_values_robust` build the `from()` vector from their own `switchers()` argument.
`run_grc_robust_vv` now detects a missing unbalanced cell data-driven, matching `setup_grc_estimation`'s existing convention.
The E1 exporters recompute the keep rule on their own filtered sample and hard-error on disagreement with the build-time characteristic.
On the Python side: `.strip()` now runs before the empty-check on both handoffs; `_int_codes` does checked-round coercion (was a truncating `int()`) at every trajectory-enumeration site; `drop_sparse_switchers` rejects missing unit ids; [counterfactuals.py](file:///C:/git/ckt/explorations/python-grc/counterfactuals.py) imports `SWITCHER_KEEP_MIN` instead of carrying a local 5; two stale one-sided-rule descriptions were corrected (the module docstring, the ado console message).
The unit test gained a seventh scenario: a full synthetic Verdier GMM fit where the cluster rule drops a one-cluster trajectory, verifying the dropped code is absent from `e(b)` and the `_d` ster and that the joint tests run on the kept list only.
That scenario initially exposed a real subtlety: a zero start leaves the phi derivative on a flat region and the gmm call throws r(430).
The test now follows the driver pattern (an `initial_values`-derived starting vector) rather than starting from zero.
All seven scenarios pass.

### Fresh-context re-review pair

Reports: [2026-07-21_stage9-keeplist-stata-rereview.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-stata-rereview.md) and [2026-07-21_stage9-keeplist-python-rereview.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-python-rereview.md).
critic-python came back at 92/100 with no CRITICAL or MAJOR and three low-risk MINOR: an unexercised CSV branch until the hub rebuild, a plain `int()` on the handoff parse that fails loud, and an unhelpful IndexError on an empty keep-list in the exploration runner.
None of the three are blocking.
critic-stata came back at 83/100 with no CRITICAL but two new MAJOR and four MINOR.
The first new MAJOR: `attach_inversion_ci`'s `threshold()` defaulted to a hardcoded 5 rather than `$grc_switcher_keep_min`, and `5b`/`5c` did not pass it through.
Under a threshold sweep the build-time keep-list would move while the Python redundant recomputation stayed at 5, firing the agreement hard-error as a spurious mismatch and defeating the one-number-sweep requirement.
The second: `initial_values_robust`'s base fallback was still a hardcoded 2, stale relative to the `initial_values` fix, and neither it nor `run_grc_robust` had received any keep-list treatment.
Both turned out to be dead code with no callers.

### Second fix round, commit a8c56fe

`attach_inversion_ci`'s threshold now defaults from `$grc_switcher_keep_min` inside the program itself, with the option changed to an optional numlist, so no second literal remains on the production path.
`initial_values_robust`'s base fallback was aligned to the first passed switcher.
`define_switcherpars` gained a guard: it exits 498 if the base is not in the `switchers()` list, so any caller that slips a base outside its list fails loud instead of silently misbuilding the restricted moment equation.
`version 17` was added to the stage 9 test driver, and the plan text was corrected from six scenarios to seven.
One re-review MINOR was declined with reason: the per-user `$dir` literals are the documented project convention.
All seven unit-test scenarios pass after these changes.

### Dead-code deletion, commit 07deae5

The author approved deletion outright ("delete them please").
`run_grc_robust` and `initial_values_robust` came out of [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do): an early Verdier Section F single-step cluster-dummy estimator plus its OLS starting-value helper, both with known convergence problems, both superseded by `run_grc_robust_vv`, and neither with any caller left anywhere in the codebase.
Each was replaced with a brief tombstone comment matching the file's existing convention, modeled on the `run_grc_hukou` tombstone near line 2970.
Three other comments that named the deleted programs were fixed: `gen_vfirst`'s header now names `run_grc_robust_vv` and the Verdier drivers as its users, `run_grc_onestep`'s header reframes its comparator note, and `run_grc_robust_vv`'s header reframes the old "key difference vs run_grc_robust" line as a plain design-choice explanation.
The deletion itself used a small Python script that found block boundaries by content (the header box's top border through the terminating end) rather than by sed line ranges, with a dry run first to confirm the boundaries (`initial_values_robust` was 124 lines, `run_grc_robust` 306 lines).
`run_grc_robust_vv` was verified intact afterward.
All seven unit-test scenarios still pass after the deletion.

### Merge and close-out

`stage9-switcher-inclusion` merged to main with `--no-ff` (merge commit `2201692`), keeping the branch history legible.
Nine stage 9 commits plus the deletion commit landed on main.
Stage 9 was marked CLOSED in the parent plan, [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md) (commit `ccc9631`), with a full status paragraph.

### Decisions, with the why

Verified the reviewer's CRITICAL by direct grep and read before trusting it, rather than fixing on the reviewer's word alone.
The aversion-to-sloppiness rule and the general principle that a code change should be evidence-backed both call for this; the grep confirmed six stale `$switchers` references across the VV post-estimation blocks.
Restructured the Verdier drivers to compute the cluster keep-list once per country up front, rather than patch the base-selection bug locally.
This resolves the base-selection MAJOR at its source, since base and initial values are now picked inside the kept set, and it removes ten redundant keep-list recomputations and audit files per country.
Threaded the threshold from a single global rather than leaving a second literal in `attach_inversion_ci`.
The author's approval condition was an easy one-number robustness sweep, and a second hardcoded 5 would have silently desynced under a sweep and surfaced as a spurious hard-error.
Added the `define_switcherpars` base-in-list guard as defense in depth.
The invariant was previously held only by caller discipline, and the re-review noted the guard would have caught the dead-code fallback bug immediately had it existed earlier.
Kept the project's tombstone-comment convention for the deleted programs.
It matches the surrounding file idiom and helps a future reader who greps the old names; the deletion narrative itself lives in the commit message, not the tombstone, per the project's code-comment convention.

### Approaches rejected

Fixing the CRITICAL only in `run_grc_robust_vv`.
Rejected because the same `$switchers`-global pattern lived in `run_grc` and `run_grc_onestep` too, where the local and global happen to agree today; fixed all three so the invariant holds by construction rather than by coincidence.
Starting the synthetic Verdier test's GMM from a zero vector.
Rejected after it hit gmm r(430), a flat and discontinuous derivative region; production always passes `initial_values`-derived starting values, so the test now matches that.
sed line-range deletion for the dead code.
Rejected in favor of a content-boundary Python script with a dry run first, because line numbers shift easily and the file is central to the whole pipeline.

### Files changed this continuation

All committed, all on main after the merge.
[0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do): post-estimation loops, `keeplist()` option, base guard, threshold default, dead-code deletion, comment fixes.
[17_verdier_robust.do](file:///C:/git/ckt/RP7/scripts/17_verdier_robust.do) and [17b_cluster_summary.do](file:///C:/git/ckt/RP7/scripts/17b_cluster_summary.do): per-country cluster keep-list, `keeplist()` pass-through.
[utilities/_export_e1_inputs.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do) and [utilities/_export_e1_inputs_hukou.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs_hukou.do): recompute-and-assert.
[lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py), [lca_inversion_ci_helper.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci_helper.py), [lca_inversion_ci.ado](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci.ado), [run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py), [counterfactuals.py](file:///C:/git/ckt/explorations/python-grc/counterfactuals.py).
[test_keeplist.do](file:///C:/git/ckt/RP7/tests/stage9/test_keeplist.do): scenario 7, `version 17`.
Overleaf `main-updated.tex`: disclosure paragraph, Verdier footnote.
[2026-07-21-stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md) and the parent plan [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).
Five review reports dated 2026-07-21 under [quality_reports/reviews/](file:///C:/git/ckt/quality_reports/reviews/).

### Open items and blockers

The definitive end-of-stages run is now the whole remaining job: hub rebuild, full refits, the old-versus-new table with Hansen's $J$, the B-8 thin-cells exhibit, the hukou rebuild, the sim rebuild, P2 parity, and a fixture smoke of the Python CSV check.
The `main-updated.tex` "lack complete trajectories" footnote is now slightly imprecise; flagged to the author, not yet acted on.
D-4 (the nonag manuscript promise) remains open at the parent plan.

## 2026-07-21 night continuation: definitive run launched, income dropped, all-thin keep-list fix

### Scope decisions (author)

The definitive run is one serial `0_master.do` batch from raw data through final tables; no parallel launcher, no fleet of drivers.
The old-versus-new Hansen-$J$ comparison table and the B-8 thin-cells exhibit are dropped from the checklist (a threshold-robustness appendix stays a possible later idea); the sim rebuild and P2 parity are out of scope as a dependent follow-on.
`copyOverleaf 0`: the Overleaf copy happens only after the author reviews the movement.
Income is dropped from the project ENTIRELY, superseding D-2: no income data builds, no income runs ("useless to be honest as we've decided not to use them").
Run plan: [2026-07-21-definitive-run.md](file:///C:/git/ckt/quality_reports/plans/2026-07-21-definitive-run.md).

### Pre-flight, first launch, crash

`0_master.do` gained the two orphaned includes (`5c_inversion_hukou.do` after 7; `11b_extrapolation_support_figure.do` at the tail because its standalone init does `clear all`) and `copyOverleaf 0` (commit `677e2a5`).
Backups: `RP7/output_prestage9_2026-07-21` and `RP7/data/processed_prestage9_2026-07-21`.
Launcher: [run_definitive.cmd](file:///C:/git/ckt/RP7/tests/run_definitive.cmd) via PowerShell `Start-Process` (detached, `-e`, rc sentinel at `RP7/tests/definitive_run_rc.txt`); bare `stata-mp` is not resolvable from cmd.exe, so the wrapper calls `StataMP-64.exe` in `C:/Program Files/StataNow19` directly.
First launch (22:11) crashed two minutes in at `CHN_hukou_urban_only_unb_income`: every switcher trajectory in that cell is thin, the keep-list came out empty, and `write_keeplist_csv` declared `kept()` required, r(198).
The cell is build-only (income estimation left at Stage 2; hukou urban-only is not estimated), and the 26 cells stashed before the crash all keep multiple trajectories, so no estimated cell is near the all-thin state.

### Fixes (commit b08d369)

Income surgery: the seven income build blocks left `1_processData.do` and the FOUR hukou income OLS blocks left `6_OLS_uGRC_hukou.do`; Stage 2 had missed those four (rural-first, urban-first, rural-only, urban-only), so income OLS hukou tables were still being produced until tonight.
Deletion by content-boundary Python script with dry run; the last block deletion swallowed the file's closing `log close`, restored by hand.
`ln_income` as a descriptive variable in summary stats is not an income run and stays.
Keep-list hardening: `kept()` is now optional in `write_keeplist_csv`, and `setup_grc_estimation` detects keep-list presence via `_dta[grc_keep_threshold]` (always non-empty when stashed) because `char define` deletes a characteristic set to empty, so an all-thin cell would otherwise masquerade as a pre-keep-list dataset.
The lump machinery already handles an empty kept list (everything lumps; `$switchers` ends empty; estimation of such a cell would fail loudly at `define_switcherpars`).
Test scenario 8 (all-thin cell) added to [test_keeplist.do](file:///C:/git/ckt/RP7/tests/stage9/test_keeplist.do); it exposed a latent collision in scenario 7, whose `local base` (Verdier base trajectory) clobbered the do-file's `base` tempfile handle; renamed `t9base`.
All 8 scenarios pass.

### Relaunch

Stale income `.dta`, stale keep-list CSVs, and the rc sentinel were removed (all backed up), and the run relaunched at 22:33 (PID 28684).
By 22:37 the build had passed the old crash point (27 keep-lists stashed, no errors) and estimation iterations were running.
Monitoring: poll `RP7/scripts/0_master.log` and the rc sentinel; expected wall-clock about two days, the extras block the long pole.

### Project-notes corrections (author)

CHN/TZA data source is Lagakos, Marshall, Mobarak, Vernot, and Waugh (LMMVW, 2020, JME), not "Lagakos et al. (2023)"; local package at `Dropbox (Personal)/Returns to migration/Data/Replication LMMVW`.
CLAUDE.md corrected (outcomes line and data-sources line); memory files `project_income_dropped.md` and `reference_lmmvw_2020_data.md` added.

### README work

No replication README existed anywhere (RP6 root has none either), so a fresh AEA-style [RP7/README.md](file:///C:/git/ckt/RP7/README.md) was drafted by a subagent, coauthor-facing, with author FILL INs (data rights, storage/hardware, table-to-manuscript mapping, Python module location).
Per the author, one subagent per master-listed .do file now writes a detailed per-script description to scratch (`readme_desc/`), to be merged into the README's program section by an integrator; in flight at the time of this entry.
The README's provenance citations came from the outdated local `paper/main.tex`; the LMMVW 2020 identification was author-confirmed afterward.

### Open items

Definitive run in flight; on completion: log sanity, Python keep-list agreement smoke, `12_counterfactuals` with drift adjudication, movement summary, then the author-gated Overleaf/Dropbox shipping steps.
README program-section merge pending the description agents; README review by the author pending.
The uncommitted new files (README.md, run plan edits if any) commit once the README merge lands.
