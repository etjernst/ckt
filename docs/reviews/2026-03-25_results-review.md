# Results and empirical sections review

**Paper:** "Selection and Heterogeneity in the Returns to Migration" (Cenci, Kleemans, Tjernström)
**Reviewer focus:** Results (Section 5), Robustness (Section 6), Conclusion (Section 7), plus introduction numbers
**Date:** 2026-03-25
**Files examined:**
- `paper/main.tex` (lines 100--920)
- `output/tables/GRC_{IDN,CHN,TZA}_consumption_urban_unb.tex`
- `output/tables/GRC_{IDN,CHN,TZA}_consumption_urban_bal.tex`
- `output/tables/GRC_{IDN,CHN,TZA}_income_urban_unb.tex`
- `output/tables/GRC_IDN_consumption_nonag_unb.tex`
- `output/tables/OLS_consumption_urban_unb.tex`
- `output/tables/OLS_consumption_urban_bal.tex`
- `paper/tables/GRC_CHN_hukou_{rural_first,urban_first,rural_only,urban_only}_consumption_urban_unb.tex`
- `output/figures/hetplotDelta_consumption_urban_unb_Fcovars.png`

---

## Issue 1: GRC results text is systematically out of sync with current tables

**Severity:** CRITICAL | **Confidence:** HIGH

The GRC tables were replaced on March 10, 2026 (per comments at lines 707--712: "MK 260310: Correctly replaced"), but the text in Section 5.3 (lines 700--729) was not updated. Every numerical claim about GRC estimates in the results section is wrong relative to the current tables.

Specific mismatches, all in the GRC results discussion (lines 700--729):

| Claim in text | Location | Table value | Discrepancy |
|---|---|---|---|
| IDN col(4) $\Delta_{\text{never}}$ = "20.6 log points" | line 701 | col(4) = 0.091 = 9.1 lp | Factor of 2.3x off |
| IDN col(5) $\Delta_{\text{never}}$ = "12 log points" | line 702 | col(5) = 0.071 = 7.1 lp | Factor of 1.7x off |
| IDN "78 percent larger than the 6.7 log points" from FE | line 704 | OLS FE = 0.088 = 8.8 lp, not 6.7 | Wrong FE baseline |
| CHN col(5) $\Delta_{\text{never}}$ = "10.7 log points" | line 720 | col(5) = 0.098 = 9.8 lp | Off by ~1 lp |
| CHN "observational returns of 14.5 log points" | line 720 | OLS FE col(7) = 0.172 = 17.2 lp | Off by 2.7 lp |
| TZA col(1) $\Delta_{\text{never}}$ = "78 log points" | line 728 | col(1) = 0.539 = 53.9 lp | Off by 24 lp |
| TZA col(5) $\Delta_{\text{never}}$ = "37 log points" | line 729 | col(5) = 0.270 = 27.0 lp | Off by 10 lp |

The text also refers to "a linear time trend" in column (5) (lines 702, 729), but the table notes describe column (5) as adding education controls ("All"), with no mention of a time trend. The old tables apparently had a different column order.

---

## Issue 2: Introduction numbers do not match current OLS table

**Severity:** CRITICAL | **Confidence:** HIGH

The introduction (lines 104--107) summarizes OLS results with numbers that no longer match the current OLS table:

| Claim | Location | Actual (from table) |
|---|---|---|
| "ranging from 40 log points in Indonesia to 74 log points in Tanzania" | line 104 | IDN = 38.8 (rounds to 39), TZA = 66.0 (not 74) |
| "decrease to 21-57 log points when we include controls" | line 105 | Range is 19.0--47.5 (col 5) |
| "narrow to 7-15 log points with individual fixed effects" | line 105 | Range is 7.2--17.2; CHN = 17.2 exceeds stated upper bound |
| "3-12 log points with controls" for switchers only | line 107 | Range is 8.8--26.4 (col 6); no value falls below 8.8 |

The results section (lines 622--643) correctly describes the OLS numbers relative to the current table, so the introduction is lagging behind the results section. The CHN col(6) discrepancy deserves special mention: the results section says "2.6 log points" (line 637) but the table shows 0.264 = 26.4 log points. This appears to be a decimal point error (26.4 became 2.6).

---

## Issue 3: Non-agricultural GRC table is a duplicate of the urban GRC table

**Severity:** CRITICAL | **Confidence:** HIGH

The file `output/tables/GRC_IDN_consumption_nonag_unb.tex` has exactly the same coefficient estimates ($\Delta_{\text{never}}$ = 0.304, $\phi$ = -2.445 in col 1; 0.071 and -0.526 in col 5), the same observation counts (92,450), and the same J-statistics as `GRC_IDN_consumption_urban_unb.tex`. The OLS non-ag table correctly uses a different sample (69,683 observations) with different coefficients, so the GRC non-ag table was clearly generated with the wrong treatment variable or data. This table appears in Appendix B (line 885) and any conclusions drawn from it would be wrong.

---

## Issue 4: China $\phi$ is not statistically significant in preferred specification

**Severity:** MAJOR | **Confidence:** HIGH

The central claim of the paper is that $\phi < 0$ consistently across all three countries. For China, $\hat{\phi}$ = -0.205 (s.e. = 0.134) in the preferred specification (col 5). This is not statistically significant at conventional levels (p $\approx$ 0.13). In fact, $\phi$ is insignificant in columns (2) through (5) for China. The text (line 724) states "$\phi$, for China is consistently negative across all specifications," which is literally true about the point estimates but omits that the estimates are statistically indistinguishable from zero in every specification with time fixed effects.

The conclusion (line 836) claims "a distinct pattern... that is remarkably consistent across the three countries." This overstates the evidence from China.

---

## Issue 5: J-test rejection in pooled China warrants stronger caveats

**Severity:** MAJOR | **Confidence:** MEDIUM

Hansen J-test rejects in all China specifications with time FE (p-values 0.013--0.029). The paper addresses this by splitting by hukou status and showing non-rejection in subsamples. Concerns:

(a) The pooled China estimates are reported as primary results in Tables 4 and 6, but the J-test says the model is misspecified for this sample. The paper should either lead with the split estimates or explicitly caution against the pooled ones.

(b) For rural-hukou-first subsample, $\hat{\phi}$ = -0.039 (s.e. = 0.153) -- essentially zero. Non-rejection of J may reflect low power rather than the LCA restriction holding well.

(c) For urban-hukou-first subsample, $\hat{\phi}$ = -0.989 (s.e. = 0.147) -- large and significant. But $\Delta_{\text{never}}$ = -0.127 (s.e. = 0.125) -- negative and insignificant. Extrapolated returns to non-migrants are essentially zero or negative, contradicting the "pro-poor migration" narrative.

(d) The text (line 753) says "Neither subsample rejects the $J$-test at conventional significance levels" -- true at 5% but several cells are in the 0.12--0.21 range, not strongly supportive given few overidentifying restrictions.

---

## Issue 6: Income results contradict the pro-poor narrative

**Severity:** MAJOR | **Confidence:** MEDIUM

Income GRC tables in Appendix C tell a markedly different story but are not discussed in the main text:

- **IDN income:** $\hat{\phi}$ is positive (0.445, p < 0.05) in col(5), the opposite sign from consumption. $\Delta_{\text{never}}$ is negative and insignificant (-0.088). Migration is "pro-rich" when measured by income.
- **TZA income:** Results are unstable. $\Delta_{\text{never}}$ flips from -1.569 (col 1) to +1.405 (col 5). $\phi$ flips from +1.477 to -0.558.
- **CHN income:** Cols (2)--(3) fail to converge. $\phi$ is strongly negative, consistent with consumption.

Some of these problems may stem from the known `define_switcherpars` base(2) issue. But regardless, the income results are either buggy and should not be in the paper, or genuine and need discussion.

---

## Issue 7: Missing robustness checks

**Severity:** MAJOR | **Confidence:** MEDIUM

The robustness section (Section 6) covers only the balanced panel. Commented-out subsection headers (lines 810--822) suggest planned analyses that are not yet written. Key missing elements:

(a) No placebo tests (false-treatment-timing or false-treatment-group).
(b) No sensitivity to LCA linearity (quadratic or more flexible specification).
(c) No leave-one-out or influence analysis for small-count trajectories.
(d) No Oster bounds or sensitivity to selection on unobservables.
(e) Assumption A3 ($\beta$ constant over time) is untested. A simple test: interact urban indicator with period dummies.
(f) Assumption A4 ($\gamma^U = \gamma^R$) is untested. A Chow-type test splitting by location would assess this.

---

## Issue 8: TZA column (1) fails to converge

**Severity:** MAJOR | **Confidence:** HIGH

Table `GRC_TZA_consumption_urban_unb` col(1) reports "Converged: N." The text (line 728) reports the column (1) estimate as if it were a valid result. Non-converged results should not be reported as point estimates, or at minimum the non-convergence should be disclosed.

---

## Issue 9: Average $\Delta$ near zero raises interpretive concerns

**Severity:** MAJOR | **Confidence:** LOW

All GRC tables report "Average $\Delta$" in the preferred specifications: IDN = 0.003, CHN = 0.004, TZA = 0.012 (col 5). When the average return is essentially zero but $\Delta_{\text{never}}$ is 7--27 log points, the model asserts that never-migrants have large positive returns while other groups have large negative returns that nearly cancel out. This implies some switcher groups lose substantially from migrating. The paper does not discuss this implication or whether it is plausible.

---

## Issue 10: Clustering level and number of clusters

**Severity:** MINOR | **Confidence:** MEDIUM

Standard errors are clustered at the individual level. The model is identified from variation across trajectories, and there are relatively few trajectory types. If identification comes from trajectory-level variation, individual-level clustering may understate standard errors. The paper should discuss whether trajectory-level clustering or bootstrap inference would be more appropriate.

---

## Issue 11: Text error in robustness section

**Severity:** MINOR | **Confidence:** HIGH

Lines 806--807: "In the full sample, rural respondents are on average around one year younger than their urban counterparts. In contrast, this difference is reversed in the full sample, with urban respondents being nearly two years older." The second "full sample" should be "balanced sample."

---

## Issue 12: Robustness IDN balanced panel number is wrong

**Severity:** MINOR | **Confidence:** HIGH

Line 800: "the estimated returns to urban migration for non-migrants fall to 7 log points once we include all controls and a time trend." Table `GRC_IDN_consumption_urban_bal` col(5) shows $\Delta_{\text{never}}$ = 0.040 = 4.0 log points, not 7. Likely from older table version.

---

## Issue 13: CHN col(6) OLS decimal point error

**Severity:** MINOR | **Confidence:** HIGH

Line 637: "an estimated consumption gap of 2.6 log points." The OLS table shows CHN col(6) = 0.264 = 26.4 log points. Decimal error.

---

## Issue 14: Conclusion overstates consistency of evidence

**Severity:** MAJOR | **Confidence:** MEDIUM

The conclusion (lines 836--838) states results are "remarkably consistent across the three countries." Given that (a) China's $\phi$ is insignificant, (b) J-test rejects for pooled China, (c) hukou splits yield one subsample where $\phi \approx 0$ and another where $\Delta_{\text{never}} < 0$, and (d) income results show opposite signs for IDN, this overstates the evidence.

The policy claim that "promoting migration would reduce misallocation and, thereby, increase overall growth" (line 838) requires that $\Delta_{\text{never}} > 0$ reflects causal returns and that barriers are policy-amenable. The paper does not discuss whether the LCA extrapolation produces causal returns.

---

## Issue 15: SUTVA concerns with migration

**Severity:** MINOR | **Confidence:** LOW

The model treats each worker's return as independent of others' migration decisions. At scale, migration changes local labor supply and wages, violating SUTVA. The paper's policy conclusions about "promoting migration" rest on partial-equilibrium returns. Standard limitation but should be acknowledged.

---

## Overall assessment

**3 CRITICAL issues** (reporting errors -- text/table mismatch, duplicate non-ag table) block readiness. These are mechanical errors requiring text updates and table regeneration.

**7 MAJOR issues** covering identification concerns (insignificant China $\phi$, J-test rejection, income contradictions, overstated conclusions) and missing robustness checks. These require human judgment about how strongly to state the cross-country consistency.

**4 MINOR issues** (text errors, clustering discussion, SUTVA).
