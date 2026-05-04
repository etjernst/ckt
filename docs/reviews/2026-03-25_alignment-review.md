# Code-Paper Alignment Review

**Paper:** "Selection and Heterogeneity in the Returns to Migration" (CKT)
**Date:** 2026-03-25 (updated after checking ReplicationPackage5)
**Reviewer:** Alignment-critic agent
**Files examined:**
- `paper/main.tex`
- ReplicationPackage5: `0_programs.do`, `0_master.do`, `1_processData.do`, `2_OLS_uGRC.do`, `5_GrRC.do`, `6_GrRC_NonAg.do`
- `scripts/logs/5_GrRC.log`, `scripts/logs/2_OLS_uGRC.log`
- `output/tables/GRC_IDN_consumption_urban_unb.tex`, `output/tables/OLS_consumption_urban_unb.tex`

---

## Issue 1: OLS time fixed effects implemented as a single arithmetic variable, not period dummies

**Severity:** CRITICAL | **Confidence:** HIGH

**What the paper says:** The OLS table (`OLS_consumption_urban_unb.tex`, caption: "OLS Estimates of the Returns to Urban Location on log Consumption") states "Columns (2) to (7) include time (survey wave) fixed effects." The text at line 625 reads: "In column (2), we add time fixed effects."

**What the code does:** `gen_time_fe` in `0_programs.do` (lines 386--390) creates a **single numeric variable**: `gen periodFE = period_2 - period_`r(r)'`. For Indonesia (5 waves), this is one regressor capturing a period-2 vs. last-period contrast, leaving 3 period effects uncontrolled.

**Why this matters:** The OLS table claims period fixed effects but includes only a single contrast. The GRC scripts correctly expand `local periodFE "period_2 - period_`r(r)'"` as a varlist range of all period dummies. Only OLS results are affected.

**Origin:** The original RP used a linear time trend (`trend = year - min_year`). DB added `gen_time_fe` on 2025-11-24 to switch from trends to period FE, but the Stata syntax creates an arithmetic difference (one variable) instead of a varlist range (all dummies).

**Affected outputs:** `OLS_consumption_urban_unb.tex` columns (2)--(7) for all three countries; heterogeneity plots.

---

## Issue 2: `define_switcherpars` call sites hardcode `base(2)`, ignoring `initial_values` output

**Severity:** MAJOR | **Confidence:** HIGH

The `define_switcherpars` program itself now correctly accepts and uses the `base()` argument (fixed between RP4 and RP5). However, every call site in `5_GrRC.do` still hardcodes `base(2)`, while `run_grc` receives the data-adaptive base from `initial_values`. When the data-adaptive base differs from 2, the `switcherpars` string and the `nlcom` extrapolation use different reference groups.

Under exact LCA, $\hat\phi$ is invariant to the choice of baseline---this is a reparameterization. The inconsistency affects the reported $\Delta_{\text{base}}$ and extrapolated $\Delta_{\text{never}}$, and matters most for income specs where the data-adaptive base is known to differ (IDN base=16, TZA base=5).

---

## Issue 3: `initial_values` accumulates $\mu$ starting values twice

**Severity:** MINOR | **Confidence:** HIGH

The `initial` string in `initial_values` (lines 1457--1474) accumulates the $\mu$ block twice. Stata's `gmm, from()` uses the last value for duplicate parameters, so the net effect is correct, but the code is confusing and the duplicate loop is dead code. Additionally, the $\Delta_{\text{base}}$ initial value is never set, so GMM starts with $\Delta_{\text{base}} = 0$.

---

## Issue 4: `always` indicator omitted from instrument list

**Severity:** MINOR | **Confidence:** HIGH

The paper states the instrument vector includes "trajectory indicators $\mathbbm{1}\{\underline{d}_i = \underline{d}\}$" for all trajectories. The code includes `never` and `switcher_s` indicators but not `always`---only `always_choice` enters. This is econometrically innocuous: for always-urban workers $D_{it} = 1$ always, making `always` and `always_choice` perfectly collinear. But the paper's description is slightly imprecise.

---

## Issue 5: OLS restricts all columns to FE-determined sample without disclosure

**Severity:** MINOR | **Confidence:** MEDIUM

`reghdfe_regressions` runs col (7) first (individual FE with all covariates), saves `e(sample)`, then restricts cols (1)--(6) to this sample. This is standard practice for comparability but the paper does not disclose it.

---

## Issue 6: Age variable (current vs. baseline) undocumented

**Severity:** MINOR | **Confidence:** MEDIUM

Both OLS and GRC consistently use current (time-varying) age squared. The paper refers to "age squared" without specifying. `baseline_age` and `baseline_age2` are generated in `set_covariates` but commented out. No inconsistency between code sections, but the paper should clarify.

---

## Confirmed correct implementations

| Component | Status |
|---|---|
| GMM residual matches eq. (12) in paper | Correct |
| $\Delta_{\text{never}}$ and $\Delta_{\text{always}}$ extrapolation via `nlcom` | Correct |
| OLS and GRC covariate sequences match paper descriptions | Correct |
| Always-urban $\kappa$ parameterization | Correct |
| Always-rural group handling | Correct |
| Clustering at `pid` | Correct |

---

## Summary

| # | Issue | Severity | Confidence |
|---|-------|----------|------------|
| 1 | OLS time FE implemented as single arithmetic variable, not period dummies | CRITICAL | HIGH |
| 2 | `define_switcherpars` call sites hardcode `base(2)` | MAJOR | HIGH |
| 3 | `initial_values` accumulates $\mu$ starting values twice | MINOR | HIGH |
| 4 | `always` indicator omitted from instrument list (innocuous) | MINOR | HIGH |
| 5 | OLS restricts all columns to FE sample without disclosure | MINOR | MEDIUM |
| 6 | Age variable undocumented | MINOR | MEDIUM |
