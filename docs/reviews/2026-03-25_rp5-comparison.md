# ReplicationPackage5 Issue Status Check

**Date:** 2026-03-25
**Comparison:** RP4 (current symlink at `c:\git\ckt\scripts\`) vs RP5 (`ReplicationPackage5/scripts/` in Dropbox)

## Summary table

| Review | Issue | Severity | Status in RP5 | Notes |
|--------|-------|----------|---------------|-------|
| Stata C-1 | Missing files break pipeline | CRITICAL | **FIXED** | `0_path_config.do`, `0_setup.do`, `5_GrRC.do`, `1_summaryStats.do`, `2_OLS_uGRC.do`, `3_heterogeneity_plots.do`, `4_trajectory_bar_graph.do` all present |
| Stata C-2 | `define_switcherpars` hardcoded `base(2)` | CRITICAL | **PARTIALLY FIXED** | Program now accepts `base()` argument and uses it correctly. But all call sites in `5_GrRC.do` still hardcode `base(2)`, ignoring `initial_values` output |
| Stata C-3 | Duplicate mu loop in `initial_values` | CRITICAL | **STILL PRESENT** | Lines 1457--1460 and 1471--1474 both append `mu:switcher_s mu_s` entries |
| Stata M-1 | `run_grc` always appends unbalanced controls | MAJOR | **STILL PRESENT** | Lines 1558--1559: dead first assignment, unconditional append of `unbalanced unbalanced_choice` |
| Stata M-2 | `gen_time_fe` creates single numeric `periodFE` | MAJOR | **STILL PRESENT** | Line 389: `gen periodFE = period_2 - period_\`r(r)'` unchanged |
| Stata M-3 | No `version` declaration | MAJOR | **STILL PRESENT** | No `version` statement in `0_master.do` |
| Stata M-4 | No master-level log file | MAJOR | **STILL PRESENT** | No `log using` in `0_master.do` |
| Stata M-5 | Merge with `nogen` in `handle_trajectory_groups` | MAJOR | **STILL PRESENT** | Lines 235, 294, 352 all use `nogen` |
| Stata M-6 | Hardcoded trajectory-string enumeration | MAJOR | **STILL PRESENT** | `non_switcher_2waves` (line 301) and `non_switcher_3waves` (line 358) still use exhaustive string listing |
| Stata M-7 | `hhsize_cube` used but never constructed | MAJOR | **STILL PRESENT** | Used in all GRC do-files (e.g., `5_GrRC.do`, `11_GrRC_max_experience.do`); not defined in `0_programs.do` |
| Stata M-8 | `$dir` undefined for unknown users | MAJOR | **PARTIALLY FIXED** | More users listed (David, maand, etje0002); still no guard for unknown usernames |
| Stata M-9 | Silent singleton drop in `set_covariates` | MAJOR | **STILL PRESENT** | Line 445: `drop if obs_per_individual == 1` with no count or display |
| Stata m-1 | Undefined `choice` in `copyOverleaf` call | MINOR | NOT CHECKED | Gated by `$copyOverleaf == 0` |
| Stata m-2 | `reg7_` overwritten twice in `ugrc_regressions` | MINOR | **STILL PRESENT** | Lines 1396--1401: first `eststo reg7_` is dead code, overwritten immediately |
| Stata m-3 | `r(N_drop)` stale after `drop if` | MINOR | **STILL PRESENT** | Lines 153, 166: display references `r(N_drop)` which does not exist after `drop if` |
| Stata m-4 | Magic number `N_s / T > 5` undocumented | MINOR | NOT CHECKED | |
| Alignment 1 | OLS time FE as single variable, not dummies | CRITICAL | **STILL PRESENT** | `gen_time_fe` (line 389) creates one numeric variable; `reghdfe_regressions` uses it as a single regressor |
| Alignment 2 | `define_switcherpars` hardcoded `base(2)` | MAJOR | **PARTIALLY FIXED** | Same as Stata C-2; program fixed but call sites not |
| Alignment 3 | `5_GrRC.do` missing | MAJOR | **FIXED** | File now present with full GRC estimation code |
| Alignment 4 | Duplicate mu in `initial_values` | MINOR | **STILL PRESENT** | Same as Stata C-3 |
| Alignment 5 | `always` omitted from instrument list | MINOR | NOT CHECKED | Econometrically innocuous per original review |
| Alignment 6 | OLS restricts all cols to FE sample | MINOR | **STILL PRESENT** | `reghdfe_regressions` still runs col 7 first and restricts cols 1--6 to `regression_sample` |
| Alignment 7 | Age variable undocumented | MINOR | NOT CHECKED | |

## Detailed findings

### Stata C-2 / Alignment 2: `define_switcherpars` --- PARTIALLY FIXED

The `define_switcherpars` program itself is now correct. It accepts `base()` and uses it properly in the loop:

```stata
program define define_switcherpars, rclass
    syntax , switchers(numlist) base(numlist)
    local switcherpars "0"
    foreach s of numlist `switchers' {
        if `s' != `base' {
            local switcherpars ///
              "`switcherpars' + ({mu:switcher_`s'} - {mu:switcher_`base'})*(switcher_`s'#1.choice)"
        }
    }
    return local switcherpars "`switcherpars'"
end
```

However, every call site in `5_GrRC.do` still hardcodes `base(2)`:

```stata
define_switcherpars, switchers($switchers) base(2)     // lines 88, 164, 242, 520, 596, 674, 945, 1016, 1087
```

Some specifications also call with `base(3)` or `base(4)` for an alternative switcherpars string, suggesting awareness of the issue, but the primary estimation always uses `base(2)`. The `initial_values` program still selects a data-adaptive base via `r(base)`, and `run_grc` still receives that data-adaptive `base` value. The mismatch between `switcherpars` (built relative to trajectory 2) and the `base` argument to `run_grc` (data-adaptive) persists whenever the data-adaptive base differs from 2.

### Stata C-3 / Alignment 4: Duplicate mu loop in `initial_values` --- STILL PRESENT

Lines 1457--1460 and 1471--1474 in `0_programs.do`:

```stata
    * Accumulate mu-coeffs for initial values          (first occurrence)
    foreach s of numlist $switchers {
        local initial "`initial' mu:switcher_`s' mu_`s'"
    }

    * Accumulate Delta-coeffs for initial values
    [... Delta block ...]

    * Accumulate mu-coeffs for initial values          (second occurrence)
    foreach s of numlist $switchers {
        local initial "`initial' mu:switcher_`s' mu_`s'"
    }
```

### Stata M-1: `run_grc` unconditional unbalanced controls --- STILL PRESENT

Lines 1557--1559 in `0_programs.do`:

```stata
local covarlist `covars'
local covarlist "`covars' unbalanced unbalanced_choice"
```

First line is dead code. Second unconditionally appends `unbalanced unbalanced_choice` even for balanced panels.

Note: The header comment at the top of `0_programs.do` (lines 1--3) acknowledges this is intentional:

> "adjustment: set covarlist in the run_grc command as always as: covarlist "unbalanced unbalanced_choice" ... (otherwise the xb vector is empty in specs wo/ log HH size) (not a problem for balanced specifications since unbalanced var is empty?)"

This suggests the authors know about it but have not resolved it cleanly. For balanced panels, the `unbalanced` variable should be all zeros, making it collinear rather than harmful, but it still inflates the Hansen J-test degrees of freedom.

### Alignment 1 / Stata M-2: OLS time FE as single variable --- STILL PRESENT

`gen_time_fe` at line 387--390:

```stata
program define gen_time_fe
    tab period, gen(period_)
    gen periodFE = period_2 - period_`r(r)'
end
```

`reghdfe_regressions` (lines 1027--1048) uses `periodFE` as a single regressor in all OLS columns (2)--(7). For IDN with 5 waves, this captures only a period 2 vs. last-period contrast, leaving 3 period effects uncontrolled. The GRC scripts correctly expand the local `periodFE` as a varlist of all period dummies.

### Stata M-5: Merge with `nogen` --- STILL PRESENT

All three `handle_trajectory_groups` variants:

```stata
merge m:1 pid using `traj', nogen      // lines 235, 294, 352
```

### Stata M-6: Hardcoded non-switcher enumeration --- STILL PRESENT

Line 301--302:

```stata
gen non_switcher_2waves = .
replace non_switcher_2waves = 1 if trajectory_2waves == "00" | trajectory_2waves == "000" | ...
```

Same pattern at lines 358--359 for 3-wave version.

### Stata M-8: `$dir` guard --- PARTIALLY FIXED

More usernames are now handled (added `David`, `maand`, `etje0002`), and the duplicate `kleemans` assignment is still present (lines 31--33). But there is still no guard for unknown usernames---`$dir` remains undefined silently. A commented-out placeholder is provided for new users:

```stata
/* global dir "C:/Users/YourUsername/YourProjectFolder" */
```

### Stata M-9: Silent singleton drop --- STILL PRESENT

Line 445:

```stata
drop if obs_per_individual == 1
```

No `count` or `display` before the drop.

### Stata m-2: `reg7_` overwritten --- STILL PRESENT

Lines 1395--1401 in `ugrc_regressions`:

```stata
eststo reg7_`country': reghdfe lndepvar choice ...     // first (dead code)
    ...
eststo reg7_`country': reghdfe lndepvar i.trajectory ...  // overwrites
```

### Stata m-3: Stale `r(N_drop)` --- STILL PRESENT

Lines 153 and 166:

```stata
drop if mi(choice)
display as text "Note: Dropped `r(N_drop)' observations ..."
```

`drop if` does not set `r(N_drop)`. The display shows whatever was in `r(N_drop)` from a prior command.

## Items not checked (paper/text issues)

The following issues from the results review are about paper text, not code. They were not checked against RP5 because they depend on `paper/main.tex`, not on the replication scripts:

- Results 1--3: Text/table mismatches, duplicate non-ag table (require new table output from RP5)
- Results 4--6, 8--9, 14: Interpretive and statistical significance concerns
- Results 7: Missing robustness checks
- Results 10--13, 15: Minor text and methodology issues

## Summary

Of the issues checkable in code:

- **FIXED:** 2 (missing files C-1, missing `5_GrRC.do`)
- **PARTIALLY FIXED:** 2 (`define_switcherpars` program body, `$dir` user list)
- **STILL PRESENT:** 14 (all other code issues)
- **NOT CHECKED:** 4 (minor or requiring runtime verification)

The two most consequential code issues remain unresolved:

1. The OLS time fixed effects bug (Alignment 1 / Stata M-2) means OLS tables do not include proper period fixed effects. This affects the OLS results reported in the paper.

2. The `define_switcherpars` call-site mismatch (Stata C-2) means the GMM moment condition may be internally inconsistent for specifications where the data-adaptive base differs from trajectory 2. Consumption-urban results are likely unaffected (base is likely 2), but income specs for IDN and TZA are at risk.
