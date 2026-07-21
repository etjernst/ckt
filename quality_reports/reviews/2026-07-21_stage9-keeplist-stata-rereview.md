# Re-review: Stage 9 switcher-inclusion, Stata leg (post-fix)

Reviewer: critic-stata (sonnet, fresh context), 2026-07-21.
Target: branch `stage9-switcher-inclusion` after fix commit `048a9b6`; current file state read in full across the keep-list chain, all four GMM programs, the drivers, the exporters, and the unit test.

Severity counts: CRITICAL 0, MAJOR 2, MINOR 4.
Score: 83/100 (above the commit gate, below the PR gate before the two MAJORs are fixed).

## Confirmed correct after the fix round

Every post-estimation block in `run_grc`, `run_grc_onestep`, `run_grc_robust`, and `run_grc_robust_vv` loops the `switchers()` argument, never the `$switchers` global.
The main-path chain is wired identically across all three `data_setup` variants and every driver; `setup_grc_estimation`'s lump semantics and `trajectory_full` match the design; `run_grc_robust_vv` validates `keeplist() ⊆ switchers()` and asserts the base survives the cluster rule; the exporters source the threshold from the build-time characteristic and hard-error on disagreement; `compute_switcher_keeplist`'s `if`-qualifier handling is correct (the condition folds into the tag and both-state computations); the unit test genuinely exercises the scenarios including the synthetic Verdier fit; `$output/keeplists/` creation is handled in `0_path_config.do`.

## MAJOR (both fixed in the follow-up commit)

M1. `attach_inversion_ci`'s `threshold()` defaulted to a hardcoded 5 rather than `$grc_switcher_keep_min`, and neither 5b nor 5c passes the option; under a threshold sweep the Python-side redundant recomputation would use the stale literal while the build-time keep-list moved, firing the agreement hard-error as a spurious mismatch and defeating the one-number-sweep requirement.
Fixed: the option defaults from `$grc_switcher_keep_min` inside the program; no second literal remains on the production path.

M2. `initial_values_robust`'s base fallback was still a hardcoded `local base = 2` (its comment claims identity with `initial_values`, whose fallback was corrected to the first passed switcher), and neither it nor `run_grc_robust` received any keep-list treatment; both are currently dead code (no callers anywhere in RP7/scripts or RP7/tests), so this is a landmine only if revived.
Fixed: the fallback now matches `initial_values`; the `define_switcherpars` guard (MI1 below) makes any revived path fail loud rather than silently misbuild the moment equation.
Whether to delete `run_grc_robust`/`initial_values_robust` outright is an author decision, recorded as an open cleanup candidate.

## MINOR

MI1. `define_switcherpars` had no assertion that `base` is in `switchers()`; callers guaranteed it only by discipline. Fixed: it now exits 498 on a base outside the list.

MI2. The plan's implementation-status paragraph said "six scenarios" while the test has seven PASS blocks. Fixed in the plan text.

MI3. The new test driver lacked a `version` declaration. Fixed (`version 17`).

MI4. Hardcoded per-user `$dir` in the exporters and the test driver. Declined: this is the project's documented per-user `$dir` convention (CLAUDE.md, and the recorded stance that smoke drivers hardcode the per-user path); a project-wide marker-file root finder is out of scope for this stage.
