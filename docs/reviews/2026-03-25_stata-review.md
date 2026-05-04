# Stata Code Review: CKT Replication Package

**Paper:** "Selection and Heterogeneity in the Returns to Migration" (Cenci, Kleemans, Tjernström)
**Date:** 2026-03-25 (updated after checking ReplicationPackage5)
**Reviewer:** Stata-critic agent
**Scope:** All do-files in ReplicationPackage5 (`0_master.do`, `0_programs.do`, `0_path_config.do`, `0_setup.do`, `0_CHN_hukou_restrictions.do`, `1_processData.do`, `1_summaryStats.do`, `2_OLS_uGRC.do`, `3_heterogeneity_plots.do`, `4_trajectory_bar_graph.do`, `5_GrRC.do`, `6_GrRC_NonAg.do`, `8_GrRC_hukou.do`, `9_learning.do`, `10_GrRC_experience.do` through `16_heterogeneity_tables.do`)

---

## CRITICAL Issues

### C-1: `define_switcherpars` call sites ignore the data-adaptive base trajectory

- **File:** `0_programs.do` lines 1527--1546; `5_GrRC.do` lines 88, 164, 242, 520, 596, 674, 945, 1016, 1087
- **Lens:** Inference
- **Severity:** CRITICAL | **Confidence:** HIGH

The `define_switcherpars` program itself now correctly accepts and uses the `base()` argument. However, every call site in `5_GrRC.do` still hardcodes `base(2)`:

```stata
define_switcherpars, switchers($switchers) base(2)
```

Meanwhile `initial_values` returns a data-adaptive base in `r(base)`, and `run_grc` receives that value in its `base()` option. When the data-adaptive base differs from 2, the `switcherpars` string (normalized to trajectory 2) and the `nlcom` extrapolation (normalized to `` `base' ``) refer to different reference groups.

Note: under exact LCA, the choice of baseline is a reparameterization---$\hat\phi$ should be invariant. The inconsistency matters for $\Delta_{\text{base}}$ and extrapolated returns, and for income specs where the data-adaptive base is known to differ (IDN base=16, TZA base=5).

**Fix:** Pass `` `base' `` to `define_switcherpars` at each call site: `define_switcherpars, switchers($switchers) base(`base')`.

---

### C-2: Mu initial values entered twice in GMM starting-value string

- **File:** `0_programs.do` lines 1457--1474 (inside `initial_values`)
- **Lens:** Inference
- **Severity:** CRITICAL | **Confidence:** HIGH

The loop over `$switchers` that appends `mu:switcher_s mu_s` entries runs twice: once at lines 1457--1460 and again at lines 1471--1474. Every mu entry appears twice in the `from()` string. Stata's `gmm` does not error on duplicates---it uses the last value---so convergence is not prevented, but the initialization string is malformed.

**Fix:** Delete lines 1471--1474 (the duplicate mu loop).

---

## MAJOR Issues

### M-1: `run_grc` always appends `unbalanced` controls, even for balanced panels

- **File:** `0_programs.do` lines 1557--1559
- **Lens:** Inference
- **Severity:** MAJOR | **Confidence:** HIGH

```stata
local covarlist `covars'
local covarlist "`covars' unbalanced unbalanced_choice"
```

The first assignment is dead code; the second overwrites it unconditionally. For balanced-panel specifications, `unbalanced == 0` for all observations, so these regressors add collinear columns to the instrument matrix, inflating the degrees of freedom of Hansen's J-statistic.

A header comment in `0_programs.do` (lines 1--3) acknowledges this is intentional ("not a problem for balanced specifications since unbalanced var is empty?"), suggesting the authors are aware but have not resolved it cleanly.

**Fix:**

```stata
local covarlist "`covars'"
if "`balance'" == "unb" {
    local covarlist "`covarlist' unbalanced unbalanced_choice"
}
```

---

### M-2: OLS time fixed effects implemented as a single arithmetic variable, not period dummies

- **File:** `0_programs.do` lines 386--390 (`gen_time_fe`); `reghdfe_regressions` (lines 1027--1048)
- **Lens:** Inference / Reproducibility
- **Severity:** MAJOR | **Confidence:** HIGH

`gen_time_fe` (added by DB on 2025-11-24 to replace the linear time trend from the original RP) creates:

```stata
gen periodFE = period_2 - period_`r(r)'
```

This is a **single numeric variable** (arithmetic subtraction of two dummies), not a set of period dummies. For IDN (5 waves), it captures only a period-2 vs. last-period contrast, leaving 3 period effects uncontrolled. `reghdfe_regressions` includes this single variable as a regressor in OLS columns (2)--(7).

The GRC scripts do it correctly: `local periodFE "period_2 - period_`r(r)'"` is a varlist range that expands to all period dummies. Only the OLS table is affected.

The original RP (pre-RP4) used a linear time trend (`trend = year - min_year`), not period FE. The conversion was implemented incorrectly.

**Fix:** Replace the single `periodFE` variable with the local macro varlist approach already used in GRC scripts, or use `absorb(period)` in `reghdfe`. See `docs/reviews/2026-03-25_ra-message-time-fe.md` for detailed fix options.

---

### M-3: No `version` declaration in any do-file

- **File:** `0_master.do`
- **Lens:** Reproducibility
- **Severity:** MAJOR | **Confidence:** HIGH

Stata behavior changes across versions for `gmm`, `reghdfe`, factor-variable syntax. Without a `version` statement, results depend on the replicator's Stata version.

**Fix:** Add `version 17` (or whichever version was used) at the top of `0_master.do`.

---

### M-4: No master-level log file

- **File:** `0_master.do`
- **Lens:** Output
- **Severity:** MAJOR | **Confidence:** HIGH

Individual do-files each open and close their own logs, but no single log captures the complete pipeline run.

**Fix:** Add `capture log close _all` / `log using "$logs/0_master.log", replace text` at the top of `0_master.do`.

---

### M-5: Merge diagnostics suppressed throughout

- **File:** `0_programs.do` lines 235, 294, 352
- **Lens:** Data quality
- **Severity:** MAJOR | **Confidence:** HIGH

All three `handle_trajectory_groups` programs merge with `nogen`, suppressing `_merge`. Unmatched observations get missing trajectory values, which are silently replaced with 999.

**Fix:**

```stata
merge m:1 pid using `traj'
assert _merge != 2
drop _merge
```

---

### M-6: Hardcoded trajectory-string enumeration for non-switcher classification

- **File:** `0_programs.do` lines 301--306 and 358--363
- **Lens:** Data quality
- **Severity:** MAJOR | **Confidence:** MEDIUM

`non_switcher_2waves` and `non_switcher_3waves` are constructed by exhaustively listing every possible trajectory string. Any unlisted trajectory remains missing, and since `gen switcher_2waves = non_switcher_2waves == 0` treats missing as 0, unlisted individuals are silently misclassified as switchers.

**Fix:** Use regex: `gen non_switcher_2waves = (regexm(trajectory_2waves, "^0+$") | regexm(trajectory_2waves, "^1+$"))`.

---

### M-7: `hhsize_cube` used but never constructed in accessible scripts

- **File:** All GRC do-files (e.g., `5_GrRC.do`, `6_GrRC_NonAg.do`, `9_learning.do`)
- **Lens:** Data quality
- **Severity:** MAJOR | **Confidence:** MEDIUM

Every GRC do-file replaces `lndepvar` with `log(consumption/hhsize_cube)`. The variable `hhsize_cube` is never constructed in `0_programs.do` or any accessible do-file---it must exist in the raw `.dta` files. Its construction is invisible to a replicator. No `assert !mi(hhsize_cube)` guard exists.

**Fix:** Define `hhsize_cube` construction explicitly or add `assert !mi(hhsize_cube)` before the replacement.

---

### M-8: `$dir` undefined for unknown users; duplicate path assignment

- **File:** `0_master.do` lines 29--51
- **Lens:** Reproducibility
- **Severity:** MAJOR | **Confidence:** HIGH

RP5 added more usernames (David, maand, etje0002) but still has no guard for unknown users. A replicator whose username is not in the list gets undefined `$dir`. The `kleemans` block still sets `$dir` twice.

**Fix:** Add a guard: `if "$dir" == "" { di as error "ERROR: Set your project directory." \n exit 198 }`.

---

### M-9: `drop if obs_per_individual == 1` is silent and buried in `set_covariates`

- **File:** `0_programs.do` line 445
- **Lens:** Data quality
- **Severity:** MAJOR | **Confidence:** HIGH

`set_covariates` drops singleton observations without any display or count. This substantive sample restriction is invisible from any calling do-file.

**Fix:** Add `count if obs_per_individual == 1` and display before dropping.

---

## MINOR Issues

### m-1: Undefined `` `choice' `` macro in `copyOverleaf` call

- **File:** `9_learning.do` line 128
- **Severity:** MINOR | Latent bug (gated by `$copyOverleaf == 0`)

### m-2: `reg7_`country'` overwritten twice in `ugrc_regressions`

- **File:** `0_programs.do` lines 1396--1404
- **Severity:** MINOR | First `eststo` is dead code

### m-3: `r(N_drop)` does not exist after `drop if`; display shows stale value

- **File:** `0_programs.do` line 153
- **Severity:** MINOR | Misleading diagnostic message

### m-4: Magic number threshold `N_s / T > 5` in base-trajectory selection

- **File:** `0_programs.do` lines 1509--1516
- **Severity:** MINOR | Undocumented threshold with silent fallback

### m-5: Misleading indentation after `initial_values` calls

- **File:** All GRC do-files
- **Severity:** MINOR | Makes post-call locals look like continuation lines

---

## Additional Observations (Not Scored)

- **GMM identification and instruments:** The moment condition in `run_grc` is correctly specified. Clustering at `pid` is appropriate. `quickderivatives` and `iterate(500)` are standard.
- **Hansen's J-test:** `estat overid` is called and stored after each GMM estimation---good practice.
- **Sort stability:** Several programs use `bysort pid (year)`. If `pid-year` is not unique, first-observation indicators are non-deterministic. No `duplicates report pid year` check exists.
- **`initial_values` OLS:** The OLS seeding GMM starting values does not include `unbalanced unbalanced_choice` controls. Acceptable for initialization but worth noting.

---

## Aggregate Score

| Lens | Weight | Score | Weighted |
|------|--------|-------|---------|
| Reproducibility | 25% | 52/100 | 13.0 |
| Inference | 30% | 50/100 | 15.0 |
| Data Quality | 20% | 57/100 | 11.4 |
| Output | 10% | 65/100 | 6.5 |
| Code Quality | 15% | 62/100 | 9.3 |
| **Total** | | | **55/100** |

**Readiness verdict: NOT READY FOR SUBMISSION.** Two CRITICAL issues block readiness: call-site base mismatch (C-1) and duplicate mu initialization (C-2). Nine MAJOR issues must also be addressed.
