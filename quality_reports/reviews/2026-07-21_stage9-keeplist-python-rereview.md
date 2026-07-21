# Re-review: Stage 9 switcher-inclusion, Python leg (post-fix)

Reviewer: critic-python (sonnet, fresh context), 2026-07-21.
Target: branch `stage9-switcher-inclusion` after fix commit `048a9b6`.
Files: [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py), [lca_inversion_ci_helper.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion_ci_helper.py), [run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py), [counterfactuals.py](file:///C:/git/ckt/explorations/python-grc/counterfactuals.py) (import block and THRESHOLD).

Severity counts: CRITICAL 0, MAJOR 0, MINOR 3.
Score: 92/100; clears the PR gate (90).
Recommendation: nothing blocks merge.

## Fixes confirmed

All prior findings verified fixed in current source: the whitespace-safe strip on both handoffs; `_int_codes` checked rounding at every trajectory-enumeration site; the missing-id guard in `drop_sparse_switchers` (load-bearing at the two call sites that do not pre-filter ids, redundant-but-harmless at the two that do); the corrected module docstring; and `counterfactuals.py` importing `SWITCHER_KEEP_MIN`.
The standalone runner's keep-list filename convention was cross-checked against `stash_switcher_keeplist`'s write path and matches exactly.

## MINOR (none blocking)

MI-A (carryover): the CSV-verification branch in the standalone runner is still unexercised end to end until the hub rebuild populates `output/keeplists/`; already on the definitive-run checklist.

MI-B: the handoff string-to-int parsing uses plain `int()` rather than the `_int_codes` checked-round pattern; the Stata side always emits integer literals, and a decimal token would fail loud (`ValueError`), so this is a defense-in-depth inconsistency, not a live bug.

MI-C: the standalone runner's base pick (`kept[0]`) raises a bare `IndexError` on an empty keep-list instead of the clear `ValueError` `compute_all_inversion_cis` raises for the same edge; error-message quality only, exploration-tier code.

## Re-confirmed correct

Both-state counting still matches `compute_switcher_keeplist` exactly; the recompute-plus-hard-error passthrough semantics are consistent on both handoffs; no consumer of the `kept` list or `counts` dict assumes the old one-sided semantics; no hardcoded paths, syntax errors, or seed-requiring operations.
