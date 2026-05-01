# Step 0 cross-check: Stata `reg_sandwich` AHZ vs R `clubSandwich` HTZ

Date: 2026-05-01.
Plan: [`quality_reports/plans/2026-05-01-f-adjustment-inversion.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/plans/2026-05-01-f-adjustment-inversion.md), Step 0.
Working dir: [`explorations/python-grc/stata/step0_reg_sandwich/`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_reg_sandwich/).

## Verdict

PASS at $q = 3$.
Stata `test_sandwich` (AHZ) and R `clubSandwich::Wald_test(test = "HTZ")` agree to $1.8 \cdot 10^{-8}$ on the F statistic and $1.6 \cdot 10^{-7}$ on the Satterthwaite-approximated denominator df, both well under the plan-rev-3 tolerances ($10^{-4}$ on the statistic, $10^{-3}$ on the df).

## Setup

The toy panel comes from [`make_toy_panel.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_reg_sandwich/make_toy_panel.py): $J = 20$ clusters, $T = 4$, $N = 80$, three regressors of interest plus a fourth regressor $z$ kept in the model but excluded from the joint test.
A cluster-level random effect $\alpha_i$ is included so the CR2 adjustment matrix has nontrivial work to do.
The DGP is seeded with `np.random.default_rng(20260501)` so both engines see byte-identical rows.

The auxiliary regression is `y x1 x2 x3 z`, cluster `pid`, no FE absorption.
This matches the unabsorbed `i.trajectory` branch we will use in production unless Step 0a's A/B test flags a divergence.
The joint contrast is $H_0: \beta_{x1} = \beta_{x2} = \beta_{x3} = 0$, so $q = 3$.

Stata uses `reg_sandwich` SSC version `0.0 updated 02-March-2017` followed by `test_sandwich x1 x2 x3`.
R uses `clubSandwich` 0.6.2 (current CRAN), `vcovCR(..., type = "CR2")` then `Wald_test(test = "HTZ")` with `constrain_zero(c("x1","x2","x3"), coef(m))`.

## Numbers

| Quantity | Stata AHZ | R HTZ | abs diff | tol | pass |
|---|---:|---:|---:|---:|:---:|
| F_stat | 1.2988455646814021e+00 | 1.2988455822142317e+00 | 1.753e-08 | 1e-04 | PASS |
| F_df1 (q) | 3 | 3 | 0 | 0 | PASS |
| F_df2 (denom) | 1.2608472841205529e+01 | 1.2608473002507665e+01 | 1.613e-07 | 1e-03 | PASS |
| F_pvalue | 3.1782233927176401e-01 | 3.1782233339685045e-01 | 5.875e-09 | 1e-03 | PASS |

The full machine table sits at [`step0_compare.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_reg_sandwich/step0_compare.md).
Persisted scalars are at [`step0_ahz_stata_out.txt`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_reg_sandwich/step0_ahz_stata_out.txt) and [`step0_htz_r_out.txt`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_reg_sandwich/step0_htz_r_out.txt).

## Reproducibility

```
cd explorations/python-grc/stata/step0_reg_sandwich
python make_toy_panel.py                                       # writes toy_panel.csv
stata-mp -b do install_reg_sandwich.do                         # one-time
stata-mp -b do step0_ahz_stata.do                              # writes step0_ahz_stata_out.txt
"/c/Program Files/R/R-4.5.3/bin/Rscript.exe" step0_htz_r.R     # writes step0_htz_r_out.txt
python compare_ahz_htz.py                                      # writes step0_compare.md
```

## What this proves

The AHZ machinery in Stata `reg_sandwich`/`test_sandwich` and R `clubSandwich::Wald_test(test = "HTZ")` agree on a multi-parameter ($q = 3$) Wald test with no FE absorption, on the same data, to the eighth decimal of the test statistic and the seventh decimal of the Satterthwaite df.
That is enough agreement to use Stata as the production engine for the F-adjusted inversion CIs in [`lca_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).

## What this does not prove

First, the 2017 SSC version of `reg_sandwich` does not necessarily implement the 2023 PT corrigendum to Theorem 2.
The corrigendum touches multi-parameter Wald-Satterthwaite, which is exactly the regime we use, but if it edits a code path that this $q = 3$ toy test does not exercise, the agreement would not catch it.
Step 0a verifies the GitHub history at https://github.com/jepusto/clubSandwich-Stata, identifies the corrigendum-addressing commit, compares against SSC `.pkg` metadata, and falls back to a `net install` from a pinned commit SHA if SSC lags.
The production version is then locked.

Second, the unabsorbed `i.trajectory` branch is not yet validated at our scale ($K = 27$, $J_R = 26$).
This toy panel uses three regressors of interest plus one nuisance; the LCA design has $K + J_R = 53$ regressors with small per-cluster $N$.
Step 0a runs the FE-absorption A/B test on a representative country dataset to lock the production specification.

Third, coverage at LCA scale is a Step 3 result, not a Step 0 result.

## Hand-off

Step 0 cleared.
Step 0a is next: pull the GitHub history, identify the corrigendum commit, decide between the SSC build and a pinned GitHub install, and run the FE-absorption A/B test on a representative country dataset.
Locked decisions 2 (corrigendum-compliant version) and 8 (FE-absorption choice) close out at the end of Step 0a.
