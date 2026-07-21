# Review: Stage 9 switcher-inclusion, Stata leg

Reviewer: critic-stata (sonnet), 2026-07-21; CRITICAL finding verified by direct read in the main session.
Target: branch `stage9-switcher-inclusion`, commits `fc8169f` and `06b0212`, cross-referenced against [the Stage 9 plan](file:///C:/git/ckt/quality_reports/plans/2026-07-21-stage9-switcher-inclusion.md).

Severity counts: CRITICAL 1, MAJOR 1, MINOR 3.
Score: 68/100, NOT READY (the CRITICAL blocks regardless of score).

## CRITICAL

C1. `run_grc_robust_vv` post-estimation blocks reference the stale global `$switchers` instead of the VV-lumped local list.
Verified by direct read: [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) lines 3593, 3595, 3657, 3663, 3665, 3677 loop `$switchers` in the joint mu test, the per-switcher `Delta_d` `nlcom`/`test`, and the `Delta_avg` `nlcom`.
The program computes its cluster-counted keep-list into the local `switchers` (line 3458) and builds the moment system from that local, but the caller's `setup_grc_estimation, nolump` left the global at the full enumeration, and the global is never updated inside the program.
Whenever the cluster rule drops a trajectory, the post-estimation calls reference `[mu]switcher_<s>` for a parameter the fitted model does not contain and error; 17b_cluster_summary.do's call has no `capture`, so one dropped trajectory aborts its whole loop, and 17_verdier_robust.do's unwrapped `estimates use` tail then breaks table generation.
Likely to fire: the TZA single-person trajectory occupies at most one cluster, below the two-cluster threshold.
The unit test never exercises `run_grc_robust_vv`, so the gap was untested.
Fix: use the local (post-lump) list in all three post-estimation blocks, matching the moment build.

## MAJOR

M1. Base-trajectory selection for the Verdier path is computed on the full enumeration, not the VV kept set.
`initial_values` picks the base from `switchers($switchers)` (full enumeration under `nolump`) with no knowledge of the cluster rule; `run_grc_robust_vv` then hard-errors (`exit 498`) if that base is not kept.
The drivers compute the base once per country and reuse it across ten calls, so one unlucky base fails all ten; 17b has no `capture` around its single call.
Candidate fixes: hoist the cluster keep-list computation to once per country in the drivers, before `initial_values`, and pass the kept set through (also resolves MINOR 3); or fall back inside the program to the best kept trajectory instead of hard-exiting.

## MINOR

MI1. The E1 exporters lump into the -1 cell using the build-time keep-list while applying their own additional positivity filters (`consumption <= 0`, `hhsize_cube <= 0`) first; the plan's K-4 covers strict-regressor missingness but not positivity, so the keep-list basis and the exporter's filtered sample are not provably the same. Suggested: recompute the keep-list on the exporter's filtered sample and assert it matches the characteristic.

MI2. The two lumping call sites detect "no unbalanced cell to lump into" differently: data-driven (`count if unbalanced == 1`) in `setup_grc_estimation` versus argument-driven (`"balance" == "unb"`) in `run_grc_robust_vv`. Not a live bug under current conventions; prefer one shared data-driven check.

MI3. The VV keep-list is recomputed (and its audit CSV rewritten) ten times per country under near-identical filenames, though it depends only on `trajectory` and `vfirst`. Hoist per country.

## Verified correct

`compute_switcher_keeplist`'s counting and row-order restoration; `stash_switcher_keeplist` running after `handle_estimable_sample` (the right point, so attrition-stripped switchers count correctly); the main-path lump semantics including `trajectory_full`, dummy zeroing, and the balanced-sample drop; the program-level preserve scoping in `run_grc_robust_vv`; the exporters' deliberate bypass of `setup_grc_estimation` (avoiding the 999-versus-missing ambiguity); the single-definition thresholds in `0_path_config.do`; and the intended hard-stop on the missing characteristic until the hub rebuild.
