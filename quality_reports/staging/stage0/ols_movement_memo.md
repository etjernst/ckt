# Stage 0 OLS movement: current tables vs rebuilt-hub re-run

Date: 2026-07-14.
Re-run driver: [ols_rerun_new.do](file:///C:/git/ckt/RP7/tests/stage0/ols_rerun_new.do); full cell-by-cell comparison: [ols_movement.csv](file:///C:/git/ckt/quality_reports/staging/stage0/ols_movement.csv) (396 rows, all 16 OLS tables).
New tables live in `RP7/tests/stage0/ols_new/tables/`; the canonical `RP7/output/tables/` is untouched.

## What this measures

`3_OLS_uGRC.do` and `6_OLS_uGRC_hukou.do` ran unmodified against the rebuilt hub, and every generated table was compared against its current counterpart.
The movement is the combined effect of the raw-to-per-capita outcome correction, Change A, and C10, reported combined per the author's 2026-07-14 decision.
Both table generations use the same table code (the current tables date from 2026-07-10), with one legacy exception: the old hukou tables carry the pre-C3 panel labels (every panel said Indonesia), so their rows were matched by coefficient label.

## Headline movement: urban coefficient on log consumption per capita

Full-covariates column (4), unbalanced: IDN 0.338 to 0.323 (-0.015), CHN 0.422 to 0.474 (+0.052), TZA 0.669 to 0.710 (+0.041).
Individual-FE column (6), unbalanced: IDN 0.072 to 0.084 (+0.012), CHN 0.105 to 0.142 (+0.037), TZA 0.094 to 0.110 (+0.016).
Balanced cells move the same way (column 4: IDN -0.018, CHN +0.039, TZA +0.042).
The IDN non-agricultural table barely moves (column 4: 0.240 to 0.237).
CHN hukou splits all shift up by 0.020 to 0.041 in column 4 and 0.005 to 0.038 in column 6.
No significance verdict flips in the consumption columns: every starred coefficient keeps its stars, and the two near-zero migrants-only CHN estimates stay insignificant.

## Direction, mechanically

The per-capita correction subtracts ln(hhsize_cube) from the outcome, so the pooled no-covariate coefficient moves by exactly minus the urban-rural gap in mean ln(hhsize_cube).
Verified on the rebuilt unbalanced cells: that gap is -0.0515 (CHN), +0.0087 (IDN), and -0.0405 (TZA), matching the observed column-1 movements of +0.052, -0.015, and +0.041 (IDN's extra -0.006 comes from the 793 newly-excluded person-waves).
Rural households are larger on average in CHN and TZA, so scaling by household size widens their measured urban premium; IDN's urban households are very slightly larger, shrinking its premium.
The FE estimates rise in all three countries, most in CHN.

## Sample-size movement

N changes come from two sources, both expected.
Change A: the CHN balanced cells lose 3 person-waves (the traced pid) and `idn_bal` loses 145.
Newly-missing outcome: `log(consumption/hhsize_cube)` is missing where `hhsize_cube` is missing or zero, rows the raw-scale OLS previously kept, so `idn_unb` loses 793 person-waves and the nonag cell 327; the GRC estimation already excluded these rows via its load-time per-capita replace, so OLS is aligning to the sample the GRC results always used.
Income cells lose more (up to 1,339 in `idn_unb_income`) for the same two reasons; income is cut from the paper per D-2, so these move nothing user-facing.
TZA loses no observations anywhere.

## What this means for the paper

The paper's OLS consumption tables currently overstate IDN and understate CHN and TZA relative to the correctly-scaled estimates, by roughly 0.01 to 0.05 log points depending on the column.
The qualitative claims survive: ordering across countries (TZA > CHN > IDN in pooled OLS), the large pooled-vs-FE gap, and all significance patterns are unchanged.
The corrected tables ship with the definitive run, not before, so the paper stays internally consistent until then.
