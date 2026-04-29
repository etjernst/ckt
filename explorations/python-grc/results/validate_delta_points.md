# Delta point-estimate validation (precondition gate)

Spec: `quality_reports/specs/2026-04-29-delta-inversion-extension.md`. Compares Python's auxiliary-OLS-derived $\Delta_X(\hat\phi, b)$ against Stata's published `nlcom` point estimate at the GMM's $\hat\phi$. Inversion CIs are not reported for any (country, spec, delta) with relative error above 1%.

## Per-(country, spec, delta) match

| Country | Spec | Delta | $\hat\phi$ | Stata point | Python point | Rel error | Flag |
|---|---|---|---:|---:|---:|---:|---|
| IDN | covs_0 | never | -2.4455 | +0.30440 | +0.60660 | +99.278% | FAIL |
| IDN | covs_0 | avg | -2.4455 | +0.38107 | +0.64420 | +69.053% | FAIL |
| IDN | covs_0 | always | -2.4455 | +0.45992 | +0.25085 | -45.458% | FAIL |
| IDN | covs_trend | never | -0.3095 | +0.08633 | +0.11789 | +36.555% | FAIL |
| IDN | covs_trend | avg | -0.3095 | +0.04052 | +0.07275 | +79.544% | FAIL |
| IDN | covs_trend | always | -0.3095 | -0.05264 | -0.00693 | +86.828% | FAIL |
| IDN | covs_1 | never | -0.3098 | +0.08647 | +0.11792 | +36.377% | FAIL |
| IDN | covs_1 | avg | -0.3098 | +0.04059 | +0.07272 | +79.178% | FAIL |
| IDN | covs_1 | always | -0.3098 | -0.05281 | -0.00723 | +86.315% | FAIL |
| IDN | covs_2 | never | -0.3208 | +0.09138 | +0.12605 | +37.947% | FAIL |
| IDN | covs_2 | avg | -0.3208 | +0.04462 | +0.08004 | +79.381% | FAIL |
| IDN | covs_2 | always | -0.3208 | -0.05263 | -0.00155 | +97.062% | FAIL |
| IDN | covs_all | never | -0.5256 | +0.07147 | +0.09968 | +39.471% | FAIL |
| IDN | covs_all | avg | -0.5256 | +0.03762 | +0.06743 | +79.252% | FAIL |
| IDN | covs_all | always | -0.5256 | -0.09640 | -0.03712 | +61.499% | FAIL |
| CHN | covs_0 | never | -0.8975 | +0.42397 | +0.54131 | +27.678% | FAIL |
| CHN | covs_0 | avg | -0.8975 | +0.00000 | +0.57768 | +57768289.113% | FAIL |
| CHN | covs_0 | always | -0.8975 | -0.10857 | +1.03569 | +1053.948% | FAIL |
| CHN | covs_trend | never | -0.0727 | +0.08982 | +0.07721 | -14.038% | FAIL |
| CHN | covs_trend | avg | -0.0727 | +0.00000 | +0.06769 | +6769475.579% | FAIL |
| CHN | covs_trend | always | -0.0727 | +0.05884 | +0.04523 | -23.121% | FAIL |
| CHN | covs_1 | never | -0.0728 | +0.08982 | +0.07720 | -14.046% | FAIL |
| CHN | covs_1 | avg | -0.0728 | +0.00000 | +0.06768 | +6768403.070% | FAIL |
| CHN | covs_1 | always | -0.0728 | +0.05883 | +0.04522 | -23.138% | FAIL |
| CHN | covs_2 | never | -0.1606 | +0.10406 | +0.09182 | -11.761% | FAIL |
| CHN | covs_2 | avg | -0.1606 | +0.00000 | +0.07809 | +7809137.264% | FAIL |
| CHN | covs_2 | always | -0.1606 | +0.03156 | +0.01696 | -46.253% | FAIL |
| CHN | covs_all | never | -0.2047 | +0.09793 | +0.08284 | -15.413% | FAIL |
| CHN | covs_all | avg | -0.2047 | +0.00000 | +0.07437 | +7436500.354% | FAIL |
| CHN | covs_all | always | -0.2047 | +0.03299 | +0.01398 | -57.609% | FAIL |
| TZA | covs_0 | never | -0.9985 | +0.53881 | +0.60809 | +12.859% | FAIL |
| TZA | covs_0 | avg | -0.9985 | +0.00000 | +0.15438 | +15437957.534% | FAIL |
| TZA | covs_0 | always | -0.9985 | -138.57856 | -147.51164 | -6.446% | FAIL |
| TZA | covs_trend | never | -0.5150 | +0.30084 | +0.27710 | -7.890% | FAIL |
| TZA | covs_trend | avg | -0.5150 | +0.00000 | +0.08022 | +8022436.164% | FAIL |
| TZA | covs_trend | always | -0.5150 | -0.26223 | -0.31094 | -18.575% | FAIL |
| TZA | covs_1 | never | -0.5227 | +0.30404 | +0.27997 | -7.917% | FAIL |
| TZA | covs_1 | avg | -0.5227 | +0.00000 | +0.08001 | +8000777.451% | FAIL |
| TZA | covs_1 | always | -0.5227 | -0.27346 | -0.32367 | -18.362% | FAIL |
| TZA | covs_2 | never | -0.5337 | +0.30134 | +0.27764 | -7.866% | FAIL |
| TZA | covs_2 | avg | -0.5337 | +0.00000 | +0.08032 | +8031742.355% | FAIL |
| TZA | covs_2 | always | -0.5337 | -0.28864 | -0.33920 | -17.518% | FAIL |
| TZA | covs_all | never | -0.7190 | +0.26989 | +0.29119 | +7.893% | FAIL |
| TZA | covs_all | avg | -0.7190 | +0.00000 | +0.12581 | +12580857.452% | FAIL |
| TZA | covs_all | always | -0.7190 | -0.66222 | -0.58564 | +11.564% | FAIL |

## Summary by (country, spec)

| Country | Spec | Max abs rel error | Worst delta | Verdict |
|---|---|---:|---|---|
| IDN | covs_0 | +99.278% | never | FAIL |
| IDN | covs_trend | +86.828% | always | FAIL |
| IDN | covs_1 | +86.315% | always | FAIL |
| IDN | covs_2 | +97.062% | always | FAIL |
| IDN | covs_all | +79.252% | avg | FAIL |
| CHN | covs_0 | +57768289.113% | avg | FAIL |
| CHN | covs_trend | +6769475.579% | avg | FAIL |
| CHN | covs_1 | +6768403.070% | avg | FAIL |
| CHN | covs_2 | +7809137.264% | avg | FAIL |
| CHN | covs_all | +7436500.354% | avg | FAIL |
| TZA | covs_0 | +15437957.534% | avg | FAIL |
| TZA | covs_trend | +8022436.164% | avg | FAIL |
| TZA | covs_1 | +8000777.451% | avg | FAIL |
| TZA | covs_2 | +8031742.355% | avg | FAIL |
| TZA | covs_all | +12580857.452% | avg | FAIL |
