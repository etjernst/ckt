# Session log 2026-07-21: Stage 9 plan, approval, and implementation

## If you resume

Stage 9 (Change B, one switcher-inclusion rule across the GMM, auxiliary OLS, and inversion) is implemented, reviewed, and fix-applied on branch `stage9-switcher-inclusion` (commits `d2cd6da` plan, `fc8169f` Stata, `06b0212` Python, `048a9b6` review fixes; the author approved the plan and then "fix everything" on the review findings the same day).
The first review round found and fixed a real CRITICAL (post-estimation blocks looping the `$switchers` global instead of the fitted switcher list; details in the plan's review-round section and the two review reports).
The fresh-context re-review pair came back with no CRITICAL: critic-python 92/100 (three low-risk MINORs, none blocking) and critic-stata 83/100 with two new MAJORs, both fixed in `a8c56fe` (the inversion-attach threshold now defaults from `$grc_switcher_keep_min` so a sweep changes one number; the dead-code `initial_values_robust` fallback aligned; `define_switcherpars` gained a base-in-list guard; `version 17` and the plan's scenario count corrected).
One review MINOR was declined with reason (per-user `$dir` literals are the documented project convention), and one item is an author decision left open: whether to delete the superseded dead programs `run_grc_robust` and `initial_values_robust` outright.
All seven unit-test scenarios pass on the final state; the branch awaits author sign-off and merge to main.
The disclosure prose and the Verdier footnote are IN `main-updated.tex` (author-approved, compiled clean, aux swept); the existing footnote there saying unbalanced individuals "lack complete trajectories" is now slightly imprecise and was flagged to the author, who has not yet acted on it.
The keep-list characteristics do not exist in the current processed hub, so `setup_grc_estimation` now hard-stops on every current dataset BY DESIGN until the hub is rebuilt; the rebuild, all `.ster` and E1 regeneration, the old-versus-new table, the B-8 thin-cells exhibit, the sim rebuild, and P2 parity all fold into the definitive end-of-stages run per [the plan](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md).
Drafted disclosure prose and the Verdier footnote sit at the bottom of the plan for the author to place in the manuscript.

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
