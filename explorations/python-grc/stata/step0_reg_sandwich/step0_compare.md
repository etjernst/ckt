# Step 0 cross-check: Stata reg_sandwich AHZ vs R clubSandwich HTZ

clubSandwich version: 0.6.2
reg_sandwich version: 0.0 (02-March-2017, SSC); pre-corrigendum.

Toy panel: J=20, T=4, N=80, q=3 contrast on (x1, x2, x3).
Auxiliary regression: y ~ x1 + x2 + x3 + z, cluster=pid, no FE absorption.

| Quantity | Stata AHZ | R HTZ | abs diff | tol | pass |
|---|---:|---:|---:|---:|:---:|
| F_stat | 1.2988455646814021e+00 | 1.2988455822142317e+00 | 1.753e-08 | 1e-04 | PASS |
| F_df1 | 3.0000000000000000e+00 | 3.0000000000000000e+00 | 0.000e+00 | 0e+00 | PASS |
| F_df2 | 1.2608472841205529e+01 | 1.2608473002507665e+01 | 1.613e-07 | 1e-03 | PASS |
| F_pvalue | 3.1782233927176401e-01 | 3.1782233339685045e-01 | 5.875e-09 | 1e-03 | PASS |

**Verdict:** PASS

Notes:
- F_df1 = q = 3 (numerator df) is identical by construction.
- F_df2 (Satterthwaite-approximated denominator df) and F_stat agree well below plan tolerance,
  even though the installed Stata package is the 2017 SSC build (pre-corrigendum) and the R
  package is the current 0.6.2 build.  Step 0a must still verify the SSC version against the
  GitHub history to identify whether the corrigendum changed code paths that this toy q=3 test
  does not exercise.
