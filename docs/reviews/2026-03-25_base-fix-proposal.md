# Proposed fix: `define_switcherpars` base mismatch

**Date:** 2026-03-25
**Scope:** All GRC do-files across RP5

## The bug

`define_switcherpars` is called with `base(2)` (or `base(3)`/`base(4)` for robustness alternatives), while `run_grc` receives the data-adaptive `base` from `initial_values`. This creates an internal inconsistency in the GMM moment condition: the switcherpars sum is normalized to one trajectory while the always-urban term and `nlcom` extrapolation use a different trajectory.

## The fix

**One change per call site.** Replace every hardcoded `base(N)` with `base(`base')`, where `` `base' `` is the local already captured from `initial_values`.

### Pattern (before)

```stata
initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
scalar base_`country' = `base'
local initial "`r(initial)'"

define_switcherpars, switchers($switchers) base(2)        // <-- hardcoded
local switcherpars `r(switcherpars)'
```

### Pattern (after)

```stata
initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
scalar base_`country' = `base'
local initial "`r(initial)'"

define_switcherpars, switchers($switchers) base(`base')   // <-- uses data-adaptive base
local switcherpars `r(switcherpars)'
```

### Robustness alternatives with `switcherpars_alt`

Some do-files build a second `switcherpars_alt` with a different hardcoded base (e.g., `base(3)`) for robustness. These also have the same mismatch since `run_grc` still receives `base(`base')`. The fix depends on the intent:

**If the robustness check is "use a different base to verify invariance":**
```stata
* Primary estimation with data-adaptive base
define_switcherpars, switchers($switchers) base(`base')
local switcherpars `r(switcherpars)'

* Robustness: re-estimate with a different base to confirm invariance
local alt_base = 3    // or whatever alternative you want to test
define_switcherpars, switchers($switchers) base(`alt_base')
local switcherpars_alt `r(switcherpars)'

* CRITICAL: run_grc must use the SAME base as switcherpars
run_grc, switcherpars("`switcherpars_alt'") base(`alt_base') ...
```

**If the robustness check is no longer needed** (since under exact LCA, all bases yield the same result once the bug is fixed), delete the `switcherpars_alt` lines and the corresponding `run_grc` calls.

## Affected files (RP5)

| File | `base(2)` sites | `base(3)` sites | `base(4)` sites |
|------|-----------------|-----------------|-----------------|
| `5_GrRC.do` | 9 | 2 | 1 |
| `6_GrRC_NonAg.do` | 1 | 0 | 0 |
| `8_GrRC_hukou.do` | 12 | 8 | 1 |
| `10_GrRC_experience.do` | 9 | 0 | 1 |
| `11_GrRC_max_experience.do` | 9 | 0 | 1 |
| `12_GrRC_experience_share.do` | 9 | 0 | 1 |
| `13_GrRC_max_experience_share.do` | 9 | 0 | 1 |
| `14_GrRC_NonAg_experience.do` | 4 | 0 | 0 |
| `15_GrRC_birth.do` | 4 | 0 | 0 |
| `16_heterogeneity_tables.do` | 3 | 0 | 0 |
| **Total** | **69** | **10** | **5** |

## Verification after fix

1. Re-run `5_GrRC.do` for all three countries, both depvars, both balance specs.
2. Compare consumption-urban results to current tables. If `initial_values` was already picking base=2 for those, results should be identical---confirming the fix is correct and the bug was dormant.
3. Compare income results. These should change (especially IDN and TZA where base ≠ 2). The new results are the correct ones.
4. Check that J-test p-values, convergence status, and standard errors are reasonable in the re-estimated tables.
5. As a further sanity check, after fixing, manually re-run one spec with `base(2)` forced everywhere (switcherpars AND run_grc) and confirm it produces identical results to the data-adaptive base. This verifies LCA invariance.

## What NOT to change

- `initial_values` itself is fine. Its data-adaptive base selection logic is correct.
- `define_switcherpars` program body is fine (in RP5 it already correctly uses the `base()` argument).
- `run_grc` program body is fine. It correctly uses `base` in both the always-urban term and `nlcom`.
- The `0_programs.do` file needs no changes.
