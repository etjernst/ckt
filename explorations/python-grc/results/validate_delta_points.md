# Delta point-estimate validation (precondition gate)

Spec: `quality_reports/specs/2026-04-29-delta-inversion-extension.md`. Compares Python's auxiliary-OLS-derived $\Delta_X(\hat\phi, b)$ against Stata's published `nlcom` point estimate at the GMM's $\hat\phi$. Inversion CIs are not reported for any (country, spec, delta) with relative error above 1%.

## Per-(country, spec, delta) match

| Country | Spec | Delta | $\hat\phi$ | Stata point | Python point | Rel error | Flag |
|---|---|---|---:|---:|---:|---:|---|
| IDN | covs_0 | never | -2.4455 | +0.30440 | +0.60660 | +99.278% | FAIL |
| IDN | covs_0 | never_md | -2.4455 | +0.30440 | +0.55380 | +81.932% | FAIL |
| IDN | covs_0 | avg | -2.4455 | +0.38107 | +0.64420 | +69.053% | FAIL |
| IDN | covs_0 | avg_md | -2.4455 | +0.38107 | +0.59141 | +55.197% | FAIL |
| IDN | covs_0 | avg_overall | -2.4455 | +0.38107 | +0.04584 | -87.970% | FAIL |
| IDN | covs_0 | always | -2.4455 | +0.45992 | +0.25085 | -45.458% | FAIL |
| IDN | covs_0 | always_md | -2.4455 | +0.45992 | +0.28738 | -37.516% | FAIL |
| IDN | covs_trend | never | -0.3095 | +0.08633 | +0.11789 | +36.555% | FAIL |
| IDN | covs_trend | never_md | -0.3095 | +0.08633 | +0.08224 | -4.737% | FAIL |
| IDN | covs_trend | avg | -0.3095 | +0.04052 | +0.07275 | +79.544% | FAIL |
| IDN | covs_trend | avg_md | -0.3095 | +0.04052 | +0.03710 | -8.433% | FAIL |
| IDN | covs_trend | avg_overall | -0.3095 | +0.04052 | +0.00518 | -87.223% | FAIL |
| IDN | covs_trend | always | -0.3095 | -0.05264 | -0.00693 | +86.828% | FAIL |
| IDN | covs_trend | always_md | -0.3095 | -0.05264 | -0.05856 | -11.246% | FAIL |
| IDN | covs_1 | never | -0.3098 | +0.08647 | +0.11792 | +36.377% | FAIL |
| IDN | covs_1 | never_md | -0.3098 | +0.08647 | +0.08238 | -4.721% | FAIL |
| IDN | covs_1 | avg | -0.3098 | +0.04059 | +0.07272 | +79.178% | FAIL |
| IDN | covs_1 | avg_md | -0.3098 | +0.04059 | +0.03719 | -8.377% | FAIL |
| IDN | covs_1 | avg_overall | -0.3098 | +0.04059 | +0.00518 | -87.248% | FAIL |
| IDN | covs_1 | always | -0.3098 | -0.05281 | -0.00723 | +86.315% | FAIL |
| IDN | covs_1 | always_md | -0.3098 | -0.05281 | -0.05871 | -11.174% | FAIL |
| IDN | covs_2 | never | -0.3208 | +0.09138 | +0.12605 | +37.947% | FAIL |
| IDN | covs_2 | never_md | -0.3208 | +0.09138 | +0.08707 | -4.709% | FAIL |
| IDN | covs_2 | avg | -0.3208 | +0.04462 | +0.08004 | +79.381% | FAIL |
| IDN | covs_2 | avg_md | -0.3208 | +0.04462 | +0.04106 | -7.975% | FAIL |
| IDN | covs_2 | avg_overall | -0.3208 | +0.04462 | +0.00570 | -87.233% | FAIL |
| IDN | covs_2 | always | -0.3208 | -0.05263 | -0.00155 | +97.062% | FAIL |
| IDN | covs_2 | always_md | -0.3208 | -0.05263 | -0.05893 | -11.972% | FAIL |
| IDN | covs_all | never | -0.5256 | +0.07147 | +0.09968 | +39.471% | FAIL |
| IDN | covs_all | never_md | -0.5256 | +0.07147 | +0.06826 | -4.490% | FAIL |
| IDN | covs_all | avg | -0.5256 | +0.03762 | +0.06743 | +79.252% | FAIL |
| IDN | covs_all | avg_md | -0.5256 | +0.03762 | +0.03601 | -4.265% | FAIL |
| IDN | covs_all | avg_overall | -0.5256 | +0.03762 | +0.00480 | -87.242% | FAIL |
| IDN | covs_all | always | -0.5256 | -0.09640 | -0.03712 | +61.499% | FAIL |
| IDN | covs_all | always_md | -0.5256 | -0.09640 | -0.10334 | -7.203% | FAIL |
| CHN | covs_0 | never | -0.8975 | +0.42397 | +0.54131 | +27.678% | FAIL |
| CHN | covs_0 | never_md | -0.8975 | +0.42397 | +0.46203 | +8.979% | FAIL |
| CHN | covs_0 | avg | -0.8975 | +0.47174 | +0.57768 | +22.458% | FAIL |
| CHN | covs_0 | avg_md | -0.8975 | +0.47174 | +0.49841 | +5.653% | FAIL |
| CHN | covs_0 | avg_overall | -0.8975 | +0.47174 | +0.02456 | -94.795% | FAIL |
| CHN | covs_0 | always | -0.8975 | -0.10857 | +1.03569 | +1053.948% | FAIL |
| CHN | covs_0 | always_md | -0.8975 | -0.10857 | +0.26222 | +341.520% | FAIL |
| CHN | covs_trend | never | -0.0727 | +0.08982 | +0.07721 | -14.038% | FAIL |
| CHN | covs_trend | never_md | -0.0727 | +0.08982 | +0.08393 | -6.550% | FAIL |
| CHN | covs_trend | avg | -0.0727 | +0.08067 | +0.06769 | -16.081% | FAIL |
| CHN | covs_trend | avg_md | -0.0727 | +0.08067 | +0.07442 | -7.743% | FAIL |
| CHN | covs_trend | avg_overall | -0.0727 | +0.08067 | +0.00288 | -96.433% | FAIL |
| CHN | covs_trend | always | -0.0727 | +0.05884 | +0.04523 | -23.121% | FAIL |
| CHN | covs_trend | always_md | -0.0727 | +0.05884 | +0.05249 | -10.794% | FAIL |
| CHN | covs_1 | never | -0.0728 | +0.08982 | +0.07720 | -14.046% | FAIL |
| CHN | covs_1 | never_md | -0.0728 | +0.08982 | +0.08393 | -6.548% | FAIL |
| CHN | covs_1 | avg | -0.0728 | +0.08066 | +0.06768 | -16.090% | FAIL |
| CHN | covs_1 | avg_md | -0.0728 | +0.08066 | +0.07442 | -7.742% | FAIL |
| CHN | covs_1 | avg_overall | -0.0728 | +0.08066 | +0.00288 | -96.433% | FAIL |
| CHN | covs_1 | always | -0.0728 | +0.05883 | +0.04522 | -23.138% | FAIL |
| CHN | covs_1 | always_md | -0.0728 | +0.05883 | +0.05248 | -10.793% | FAIL |
| CHN | covs_2 | never | -0.1606 | +0.10406 | +0.09182 | -11.761% | FAIL |
| CHN | covs_2 | never_md | -0.1606 | +0.10406 | +0.09938 | -4.498% | FAIL |
| CHN | covs_2 | avg | -0.1606 | +0.09114 | +0.07809 | -14.319% | FAIL |
| CHN | covs_2 | avg_md | -0.1606 | +0.09114 | +0.08565 | -6.027% | FAIL |
| CHN | covs_2 | avg_overall | -0.1606 | +0.09114 | +0.00332 | -96.358% | FAIL |
| CHN | covs_2 | always | -0.1606 | +0.03156 | +0.01696 | -46.253% | FAIL |
| CHN | covs_2 | always_md | -0.1606 | +0.03156 | +0.02597 | -17.721% | FAIL |
| CHN | covs_all | never | -0.2047 | +0.09793 | +0.08284 | -15.413% | FAIL |
| CHN | covs_all | never_md | -0.2047 | +0.09793 | +0.09458 | -3.424% | FAIL |
| CHN | covs_all | avg | -0.2047 | +0.09004 | +0.07437 | -17.408% | FAIL |
| CHN | covs_all | avg_md | -0.2047 | +0.09004 | +0.08611 | -4.368% | FAIL |
| CHN | covs_all | avg_overall | -0.2047 | +0.09004 | +0.00316 | -96.489% | FAIL |
| CHN | covs_all | always | -0.2047 | +0.03299 | +0.01398 | -57.609% | FAIL |
| CHN | covs_all | always_md | -0.2047 | +0.03299 | +0.02875 | -12.856% | FAIL |
| TZA | covs_0 | never | -0.9985 | +0.53881 | +0.60809 | +12.859% | FAIL |
| TZA | covs_0 | never_md | -0.9985 | +0.53881 | +0.57202 | +6.164% | FAIL |
| TZA | covs_0 | avg | -0.9985 | +0.08537 | +0.15438 | +80.827% | FAIL |
| TZA | covs_0 | avg_md | -0.9985 | +0.08537 | +0.11831 | +38.573% | FAIL |
| TZA | covs_0 | avg_overall | -0.9985 | +0.08537 | +0.01763 | -79.346% | FAIL |
| TZA | covs_0 | always | -0.9985 | -138.57856 | -147.51164 | -6.446% | FAIL |
| TZA | covs_0 | always_md | -0.9985 | -138.57856 | -171.52547 | -23.775% | FAIL |
| TZA | covs_trend | never | -0.5150 | +0.30084 | +0.27710 | -7.890% | FAIL |
| TZA | covs_trend | never_md | -0.5150 | +0.30084 | +0.29636 | -1.489% | FAIL |
| TZA | covs_trend | avg | -0.5150 | +0.10221 | +0.08022 | -21.511% | FAIL |
| TZA | covs_trend | avg_md | -0.5150 | +0.10221 | +0.09948 | -2.671% | FAIL |
| TZA | covs_trend | avg_overall | -0.5150 | +0.10221 | +0.00916 | -91.035% | FAIL |
| TZA | covs_trend | always | -0.5150 | -0.26223 | -0.31094 | -18.575% | FAIL |
| TZA | covs_trend | always_md | -0.5150 | -0.26223 | -0.27123 | -3.434% | FAIL |
| TZA | covs_1 | never | -0.5227 | +0.30404 | +0.27997 | -7.917% | FAIL |
| TZA | covs_1 | never_md | -0.5227 | +0.30404 | +0.29947 | -1.505% | FAIL |
| TZA | covs_1 | avg | -0.5227 | +0.10235 | +0.08001 | -21.830% | FAIL |
| TZA | covs_1 | avg_md | -0.5227 | +0.10235 | +0.09950 | -2.782% | FAIL |
| TZA | covs_1 | avg_overall | -0.5227 | +0.10235 | +0.00914 | -91.072% | FAIL |
| TZA | covs_1 | always | -0.5227 | -0.27346 | -0.32367 | -18.362% | FAIL |
| TZA | covs_1 | always_md | -0.5227 | -0.27346 | -0.28282 | -3.424% | FAIL |
| TZA | covs_2 | never | -0.5337 | +0.30134 | +0.27764 | -7.866% | FAIL |
| TZA | covs_2 | never_md | -0.5337 | +0.30134 | +0.29668 | -1.547% | FAIL |
| TZA | covs_2 | avg | -0.5337 | +0.10251 | +0.08032 | -21.647% | FAIL |
| TZA | covs_2 | avg_md | -0.5337 | +0.10251 | +0.09936 | -3.072% | FAIL |
| TZA | covs_2 | avg_overall | -0.5337 | +0.10251 | +0.00917 | -91.051% | FAIL |
| TZA | covs_2 | always | -0.5337 | -0.28864 | -0.33920 | -17.518% | FAIL |
| TZA | covs_2 | always_md | -0.5337 | -0.28864 | -0.29837 | -3.369% | FAIL |
| TZA | covs_all | never | -0.7190 | +0.26989 | +0.29119 | +7.893% | FAIL |
| TZA | covs_all | never_md | -0.7190 | +0.26989 | +0.27650 | +2.452% | FAIL |
| TZA | covs_all | avg | -0.7190 | +0.10584 | +0.12581 | +18.868% | FAIL |
| TZA | covs_all | avg_md | -0.7190 | +0.10584 | +0.11112 | +4.993% | FAIL |
| TZA | covs_all | avg_overall | -0.7190 | +0.10584 | +0.01437 | -86.423% | FAIL |
| TZA | covs_all | always | -0.7190 | -0.66222 | -0.58564 | +11.564% | FAIL |
| TZA | covs_all | always_md | -0.7190 | -0.66222 | -0.63791 | +3.671% | FAIL |

## Summary by (country, spec)

| Country | Spec | Max abs rel error | Worst delta | Verdict |
|---|---|---:|---|---|
| IDN | covs_0 | +99.278% | never | FAIL |
| IDN | covs_trend | -87.223% | avg_overall | FAIL |
| IDN | covs_1 | -87.248% | avg_overall | FAIL |
| IDN | covs_2 | +97.062% | always | FAIL |
| IDN | covs_all | -87.242% | avg_overall | FAIL |
| CHN | covs_0 | +1053.948% | always | FAIL |
| CHN | covs_trend | -96.433% | avg_overall | FAIL |
| CHN | covs_1 | -96.433% | avg_overall | FAIL |
| CHN | covs_2 | -96.358% | avg_overall | FAIL |
| CHN | covs_all | -96.489% | avg_overall | FAIL |
| TZA | covs_0 | +80.827% | avg | FAIL |
| TZA | covs_trend | -91.035% | avg_overall | FAIL |
| TZA | covs_1 | -91.072% | avg_overall | FAIL |
| TZA | covs_2 | -91.051% | avg_overall | FAIL |
| TZA | covs_all | -86.423% | avg_overall | FAIL |
