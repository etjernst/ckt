# Plan: Stage 9, switcher-inclusion consistency (Change B) on the post-Stage-8 codebase

Date: 2026-07-21.
Spec: [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) (decisions D1-D8 and DA1-DA3 locked by the author 2026-07-13).
Predecessor plan: [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md), reviewed by critic-econometrics with resolutions folded in.
Parent: Stage 9 of [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/plans/2026-07-14-pipeline-frontload-refactor.md).
Mode: Implementation.
Status: APPROVED 2026-07-21 (author), with the amendments recorded under "Approval decisions" below.

## Approval decisions (author, 2026-07-21)

The threshold must be easy to vary for robustness: one named constant per path (five individuals on the main path, two clusters on the Verdier path), defined once and referenced everywhere, so a sweep changes one number and no call sites.
This promotes the spec's MAY 14 to a requirement.
R-1 resolved as option (a): the rule is computed during data construction and stored in the saved dataset; the author accepts the rebuild cost ("data construction is not a big cost in this project").
The keep-list text file is written for Python and for audit, as planned.
R-2 resolved: in the balanced-sample runs, dropped-trajectory individuals are removed outright, announced loudly in the log.
R-3 resolved: keep the original labels in a `trajectory_full` copy; additionally, the paper's Verdier robustness section must carry a footnote stating that the Verdier path's rule is two villages rather than five individuals.
R-4 confirmed: the hukou dataset rebuild goes on the definitive-run checklist.

## Why a new plan

The predecessor plan covered Change A and Change B against the pre-refactor code.
Change A already shipped: commit `a11e013` reflags strict-spec-incomplete individuals as unbalanced inside `handle_balance` (now [0_programs.do:368](file:///C:/git/ckt/RP7/scripts/0_programs.do)), and the Stage 3+4 gate adjudicated its enumerated N-changes with author sign-off.
Stage 9 is therefore Change B alone, and Stages 1-8 restructured every location the predecessor plan pointed at, so the implementation steps need re-anchoring while the spec's decisions carry over unchanged.

## What Stages 1-8 changed under this plan's feet

The trajectory scaffolding is front-loaded: `handle_grc_scaffolding` ([0_programs.do:582](file:///C:/git/ckt/RP7/scripts/0_programs.do)) builds the always/never/switcher dummies at build time and stashes the enumeration as dataset characteristics (`_dta[grc_switchers]`, `_dta[grc_always]`, `_dta[grc_never]`); `setup_grc_estimation` ([0_programs.do:1660](file:///C:/git/ckt/RP7/scripts/0_programs.do)) is now a contract reader that repopulates the globals and recodes missing `trajectory` to 999 at load, and it exits 459 on contract-less data.
`trajectory` stays missing in the saved file for out-of-enumeration individuals; the honest-encoding decision from Stage 3 governs any new stored label.
`handle_estimable_sample` ([0_programs.do:660](file:///C:/git/ckt/RP7/scripts/0_programs.do)) drops missing-outcome person-waves as the last build step, so the saved hub is the estimable sample.
The outcome is `logpc_consumption` (the predecessor plan's `lndepvar` references are stale), the E1 exporters live at [utilities/_export_e1_inputs.do](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do) (`traj_for_agg` at line 169), and `run_grc_robust_vv` now runs under a program-level preserve with `vfirst` computed at estimation time on the estimable sample.
The lca-inversion worktree merged; the Python side lives at [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py) with the `lca_inversion_ci.ado` handoff and production `hhid(pid)` confirmed at [5b_inversion.do:141](file:///C:/git/ckt/RP7/scripts/5b_inversion.do).

## Architecture: the keep-list joins the trajectory contract

The parent plan directs: author the switcher keep-list once at the front end, persist it, and have every estimator read it.
The predecessor plan's Design 2 (an explicit keep-list artifact, original `trajectory` intact, VV computing its own looser list) survives, but its home moves from estimation setup into the build, riding the same characteristic mechanism Stage 3 created.

K-1. `compute_switcher_keeplist, count_unit(pid|cluster) cluster_var(name) threshold(#)` enters `0_programs.do` exactly as the predecessor's B-1 specified: for each candidate switcher, count distinct units observed with `choice==1` and with `choice==0` within the trajectory, keep the candidates at or above the threshold, and return the kept list plus the per-candidate counts.
Default `threshold(5)`, `count_unit(pid)`.

K-2. `data_setup` (and its 2waves/3waves siblings) calls the counter after `handle_estimable_sample`, so the counts describe the saved estimable sample, and stashes the result as `_dta[grc_kept_switchers]` plus a per-candidate count characteristic.
It also writes the per-cell keep-set diagnostic (candidates, both-states counts, kept, lumped) to `$output/keeplists/` for audit and for the standalone Python path (spec SHOULD 11).

K-3. `setup_grc_estimation` reads the keep-list back and applies the lump at load: preserve the original codes in a `trajectory_full` copy, then for individuals in a dropped switcher trajectory set `trajectory = 999`, `unbalanced = 1`, and refresh `unbalanced_choice`; build `$switchers` from the kept set only.
The saved file keeps original labels (honest encoding, per Stage 3); the lump is load-time state, exactly like the existing 999 recode.
`trajectory_full` exists so the VV path can compute its cluster-count-2 list from unlumped labels without reloading.

K-4. Because Change A already removed every individual missing a strict regressor, one keep-set per cell equals the keep-set on every covariate spec's subsample by construction (the predecessor plan's simplification, unchanged); the hukou and income paths get the per-spec check the review resolution m2 asked for.

This layout is the main point to confirm at review, alongside R-1 through R-3 below.

## Implementation steps

B-3 (main GMM adopts the rule) happens inside K-3; acceptance unchanged: TZA trajectory 3 no longer appears as a `switcher_3_choice` moment, person and person-wave totals unchanged, the person's rows carry `unbalanced==1` in memory.

B-4 (auxiliary OLS and inversion consume the list): extend the `lca_inversion_ci.ado` handoff with the kept-switcher list, have `lca_inversion_ci_helper.py`, `compute_all_inversion_cis`, and `attach_inversion_for_stata` accept `switchers_kept` and skip `drop_sparse_switchers` when supplied; keep `drop_sparse_switchers` callable but assert agreement and hard-error on mismatch (spec SHOULD 10).
`run_all_countries_inversion.py` defaults to reading the persisted keep-list file.

B-5 (E1 exporter): after `traj_for_agg` is built ([utilities/_export_e1_inputs.do:169](file:///C:/git/ckt/RP7/scripts/utilities/_export_e1_inputs.do)), read the keep-list characteristic and set `traj_for_agg = -1` for dropped-switcher individuals; same for the hukou exporter.
Verify the exporter's assumption about load state (it currently keys `-1` off `missing(trajectory)`, which the load-time 999 recode changes if the exporter runs downstream of `setup_grc_estimation`).

B-6 (Verdier-robust path): inside `run_grc_robust_vv` (and the onestep variant), call `compute_switcher_keeplist, count_unit(cluster) cluster_var(vfirst) threshold(2)` on `trajectory_full`, persist `{country}_vv_switchers.txt`, and lump on the VV path only, all inside the existing program-level preserve so nothing leaks to the caller.
The cluster-granularity caveat (CHN `cid`, IDN `keca`, TZA `ward`) carries over from D7/M7.

B-7 (disclosure prose): draft the two-to-three sentences in the local paper source for the author to place in Overleaf; content per spec MUST 8 (rule, lumping destination, trajectory count falls, `unbalanced_choice` as nuisance control).

B-8 (thin-cells-retained inversion exhibit): unchanged from the predecessor plan; appendix comparison of filtered versus thin-retained inversion CIs for the IDN and TZA cells with thin trajectories.

Unit test (spec MUST 2 acceptance): a constructed panel where five both-states individuals keep a trajectory, four drop it, and a one-sided cell drops; runs as a scratch driver under `RP7/tests/`.

## Sequencing and verification

The keep-list authoring and the lump land in code now; the regeneration of every affected `.ster`, the E1 CSVs, the old-versus-new table, the sim rebuild, and P2 parity re-certification all belong to the definitive end-of-stages run, per the parent plan.
Stage 9 verifies against the spec's acceptance criteria, not the equivalence gate: the estimand change is the point.
Pre-run verification that needs no GRC refit: the unit test above, a printed keep-set comparison across GMM, auxiliary OLS, and inversion for every main-path cell (spec MUST 1), the E1 exporter row check, and a smoke fit of one fast cell (TZA) confirming the moment list shrinks as enumerated.
The old-versus-new table at the definitive run reports $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$, and Hansen $J$/$J_{df}$/$p$ per cell with the base trajectory pinned across runs, and asserts the weight vector and base match across estimators (review resolutions M1/M2).

## Open points for review

R-1. Confirm the contract-characteristic home for the keep-list (K-2/K-3) over the predecessor's estimation-setup authoring; the front-end home follows the parent plan's directive and the Stage 3 mechanism, at the cost of a hub rebuild being required before the new characteristics exist.

R-2. The `bal` sample has no unbalanced cell to lump into; the predecessor plan proposed removal there with a run-log note.
Confirm, or specify an alternative.

R-3. `trajectory_full` adds a column to load-time state visible to every downstream consumer; confirm the name, or prefer stashing the original codes some other way.

R-4. The hukou cells must carry the new characteristic too, which means `0_CHN_hukou_restrictions.do` reruns after the keep-list lands; it now writes to `processed/` (Stage 8), so this is a plain rerun, but it needs to be on the definitive-run checklist.

## Implementation status (2026-07-21)

Both legs are implemented and unit-tested on branch `stage9-switcher-inclusion` (commits `fc8169f` Stata, `06b0212` Python).
The thresholds live in [0_path_config.do](file:///C:/git/ckt/RP7/scripts/0_path_config.do) as `$grc_switcher_keep_min` (5, individuals, main path) and `$grc_switcher_keep_min_vv` (2, clusters, Verdier path); the Python mirror is `SWITCHER_KEEP_MIN` in [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py).
`compute_switcher_keeplist` counts both-state units; `stash_switcher_keeplist` runs at the end of every `data_setup` variant and stores the keep-list in the dataset characteristics plus an audit CSV under `$output/keeplists/`; `setup_grc_estimation` lumps at load (relabel to 999/unbalanced, loud drop in balanced samples) and gains `nolump` for the Verdier drivers; `run_grc_robust_vv` applies the cluster rule inside its preserve and errors if the base trajectory is not kept; the E1 exporters lump non-kept trajectories into the -1 cell; the inversion receives `$switchers` through the attach handoff with a hard-error agreement check against the Python recomputation.
The unit test ([test_keeplist.do](file:///C:/git/ckt/RP7/tests/stage9/test_keeplist.do)) passes all six scenarios: five both-state individuals kept, four lumped, one-sided lumped, lumping relabels without deleting, balanced sample drops loudly, nolump inert, cluster-counted rule at threshold two.
Still owed at the definitive run: hub rebuild (the keep-list characteristics do not exist until then, and `setup_grc_estimation` hard-stops without them), the hukou rebuild (R-4), all `.ster` and E1 regeneration, the old-versus-new table with Hansen $J$, the B-8 thin-cells-retained inversion exhibit (run via the threshold knobs), a fixture smoke of the standalone runner's keep-list CSV check once `output/keeplists/` is populated, the sim rebuild, and P2 parity.
The disclosure prose below went into `main-updated.tex` with author approval on 2026-07-21 (estimation section, plus the two-clusters-not-five-individuals footnote in the cluster-pooling robustness subsection).

Review round (2026-07-21, author approved "fix everything"): critic-stata found one CRITICAL (the GMM programs' post-estimation blocks looped the `$switchers` global while the Verdier fit was built from a trimmed local, so a cluster-dropped trajectory would crash the joint tests and nlcoms), one MAJOR (the Verdier base was picked from the full enumeration, risking a hard stop when it fell outside the cluster keep-list), and three MINOR; critic-python found one latent MAJOR (whitespace-only handoff strings misread as an empty keep-list) and six MINOR.
All were fixed in commit `048a9b6`: every post-estimation block loops its program's `switchers()` argument; the drivers compute the cluster keep-list once per country (via `compute_switcher_keeplist`'s new `if` qualifier and `run_grc_robust_vv`'s new `keeplist()` option) and pick base and initial values inside it; the exporters recompute the rule on their own filtered sample and hard-error on disagreement; the Python side gains whitespace-stripping, checked integer coercion, a missing-id guard, the shared constant in `counterfactuals.py`, and corrected rule descriptions.
The unit test gained scenario 7, a full synthetic Verdier fit with a cluster-dropped trajectory; all seven scenarios pass.
Reports: [Stata](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-stata-review.md), [Python](file:///C:/git/ckt/quality_reports/reviews/2026-07-21_stage9-keeplist-python-review.md); a fresh-context re-review of the fixed branch is the remaining gate before author sign-off and merge.

## Drafted disclosure prose (for the author to place)

For the section that first defines the switcher cells (spec MUST 8):

> We retain a switcher trajectory only if at least five individuals in it are observed in both an urban and a rural period; individuals in thinner trajectories join the unbalanced cell, whose coefficient serves as a nuisance control absorbing both survey attrition and these lumped thin trajectories.
> This rule applies identically to the GMM, the auxiliary OLS behind the inversion, and the inversion itself, so all three estimators average over the same switcher set.
> The number of reported switcher trajectories falls accordingly; in Tanzania, a single-person trajectory is absorbed this way. % TODO verify at the definitive run that TZA trajectory 3 is the only lumped cell

Footnote for the Verdier robustness section (author decision 2026-07-21):

> \footnote{On the Verdier-robust path the inclusion rule counts clusters rather than individuals: a switcher trajectory is retained if at least two clusters contribute both an urban and a rural observation to it. The looser threshold reflects the small number of clusters, and the Verdier switcher set can therefore differ from the main path's, so differences between the two estimators are not a pure estimator effect.}
