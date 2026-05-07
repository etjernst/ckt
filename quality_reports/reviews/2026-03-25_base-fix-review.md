# Review: proposed fix for `define_switcherpars` base mismatch

**Date:** 2026-03-25
**Reviewer:** Stata-critic agent
**Proposal:** `docs/reviews/2026-03-25_base-fix-proposal.md`

---

## Summary verdict

The mechanical substitution `base(2)` → `base(`base')` is correct for the 69 plain-`switcherpars` sites. However, the fix is incomplete for 15 `switcherpars_alt` sites where a hardcoded alternative base (3 or 4) is passed to `run_grc` while `run_grc` still receives `base(`base')`. Those blocks remain internally inconsistent after the proposed fix and require an author decision on intent.

---

## Is the fix correct?

For the 69 plain sites: **yes**. `` `base' `` is already set from `r(base)` immediately after `initial_values`. Substituting `base(`base')` aligns the moment condition's normalization with the always-urban term and `nlcom`.

For the 15 `switcherpars_alt` sites: **incomplete**. Three blocks in `5_GrRC.do` build `switcherpars_alt` with a hardcoded base and pass it to `run_grc` which still uses `base(`base')`:

| Lines | Country/spec | `switcherpars_alt` base | Still inconsistent? |
|---|---|---|---|
| 164--177 | TZA consumption | 3 | Yes |
| 596--609 | IDN income | 3 | Yes |
| 1087--1113 | CHN income | 4 | Yes |

The correct pattern (already in the proposal but not applied) is:

```stata
local alt_base = 3
define_switcherpars, switchers($switchers) base(`alt_base')
local switcherpars_alt `r(switcherpars)'
run_grc, switcherpars("`switcherpars_alt'") base(`alt_base') ...
```

Or delete the `switcherpars_alt` blocks entirely if the robustness check is no longer needed (exact LCA implies base invariance once the bug is fixed).

Similar patterns exist in `8_GrRC_hukou.do`, `10_GrRC_experience.do`, `11-13_GrRC_*.do`.

---

## Edge cases and risks

### Risk 1 (MAJOR): fallback default in `initial_values` is 2

If no switcher passes the `N_s / T > 5` threshold, `initial_values` returns base=2 regardless. If trajectory 2 is not in `$switchers` for that sample, `define_switcherpars` will reference a nonexistent parameter. Add a guard:

```stata
initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
assert `: list base in local switchers'
```

### Risk 2 (MINOR): `16_heterogeneity_tables.do` may reconstruct from saved `.ster` files

If those 3 call sites derive `base` from `initial_values` on fresh data, the fix is correct. If they reload saved `.ster` estimates, the base must match the one used in the original estimation, not a freshly computed one. Authors should confirm.

---

## Verification plan additions

1. **Log the base:** Add `di "Base for `country' (`depvar'): `base'"` after each `local base` capture. Makes the selection visible in logs.

2. **Track `switcherpars_alt` blocks separately.** Results from those three blocks will change regardless of whether `initial_values` picks base=2, since they were always inconsistent.

3. **Step 5 correction:** Forcing `base(2)` everywhere and comparing to data-adaptive base tests LCA invariance, but under approximate LCA or J-test rejection (pooled CHN), results will be similar, not identical. Frame accordingly.

---

## Could the fix introduce new issues?

**Imprecise base $\mu$:** `initial_values` maximizes the t-stat for $\Delta_s$, not $\mu_s$. A trajectory with strong $\Delta$ but imprecise $\mu$ would propagate noise into all `nlcom` extrapolations via `_b[mu:switcher_`base']`. Unlikely to cause failures but standard errors on extrapolated $\Delta$ may shift.

**Base not in `$switchers`:** Covered by Risk 1 above. The assertion guard prevents this.

---

## Overall assessment

The primary substitution is correct and sufficient for 69 of 84 sites. The 15 `switcherpars_alt` sites require an author decision (keep as invariance check with matched base, or delete). That decision is blocking for a complete fix.
