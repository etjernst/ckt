# Targeted citation audit: Zhipeng Liao and Todd Schoellman

Date: 2026-07-10

Query: Determine whether the current draft of “Selection and Heterogeneity in the Returns to Migration” should cite work by Zhipeng Liao or Todd Schoellman, and identify accurate placement and wording.

The manuscript and bibliography in the Overleaf-Dropbox folder were read only.
No manuscript or bibliography files were changed.

## Recommendation

The paper already cites two Schoellman papers, and both belong in the paper.
The Donovan and Schoellman (2023) review is an especially close fit for the paper's framing of sectoral gaps as a tension between selection and mobility frictions.
Herrendorf and Schoellman (2018) is also relevant, but the current sentence describes its treatment margin too narrowly.
The paper combines cross-country census evidence on sectoral wages and human capital with panel evidence on workers leaving agriculture in the United States, Brazil, and Indonesia.
It therefore belongs with the microdata studies, but as evidence on agriculture-to-nonagriculture wage gains rather than rural-urban consumption returns.

One Liao paper is sufficiently close to merit a conditional citation: Lee and Liao (2018) on GMM inference under local identification failure of known forms.
The citation should describe the broader inferential problem, not imply that the paper implements Lee and Liao's proposed estimator or test.
The author decided to postpone this citation until the manuscript explains how its weak-identification-robust inversion relates to its conventional Hansen $J$-test.

I would not add any other paper by either editor merely for editorial fit.

## Draft-level citation map

| Paper | Current use | Fit | Recommended action |
|---|---|---|---|
| Donovan and Schoellman (2023), “The Role of Labor Market Frictions in Structural Transformation” | Cited in the footnote at draft line 129 | Very high | Keep it and consider moving the citation into the main sentence at line 130, where the paper frames the selection-versus-frictions debate. |
| Herrendorf and Schoellman (2018), “Wages, Human Capital, and Barriers to Structural Transformation” | Cited at lines 66 and 133 | High, but the treatment margin needs qualification | Keep it in the microdata discussion but describe its panel evidence as wage gains from leaving agriculture, alongside its cross-country wage and human-capital accounting. |
| Herrendorf and Schoellman (2015), “Why Is Measured Productivity So Low in Agriculture?” | Present in the bibliography but not cited | Moderate | Optional footnote only if the authors want to distinguish measured average-product gaps from marginal-product gaps and flag agricultural value-added mismeasurement. |
| Lee and Liao (2018), “On Standard Inference for GMM with Local Identification Failure of Known Forms” | Not in the bibliography | Moderate to high methodological fit | Add as related weak-GMM theory in the inference discussion, paired with the actual source for the manuscript's test-inversion procedure. |
| Donovan, Lu, and Schoellman (2023), “Labor Market Dynamics and Development” | Not cited | Low for the present draft | Do not add unless the paper develops a separate argument about frequent job or occupational transitions into marginal work. |

## Suggested citation language

These are recommendations only and have not been applied to the manuscript.

### Schoellman: correct the current characterization

The sentence at line 133 should not describe Herrendorf and Schoellman (2018) as a study of rural-urban migration returns.
The paper does use panel evidence, but its treatment is leaving agriculture for nonagricultural work and its outcome is wages.
A cleaner two-sentence split would be:

```latex
Several recent studies using longitudinal microdata find that average gains from rural--urban migration or movement out of agriculture are relatively small \citep{alvarezAgriculturalWageGap2020,hamoryReevaluatingAgriculturalProductivity2021}.
Complementary work combines cross-country census evidence on sectoral wages and human capital with panel estimates for workers leaving agriculture in the United States, Brazil, and Indonesia; these switcher wage gains are positive but small relative to the sectoral wage gaps, supporting a selection-based interpretation of the gaps \citep{herrendorfWagesHumanCapital2018}.
```

The second sentence tracks the full paper closely.
Herrendorf and Schoellman document sectoral wage, education, and Mincer-return differences across 13 countries, compare their model's barrier implications with panel evidence for the United States, Brazil, and Indonesia, and conclude that the switcher gains are close to their selection view and imply limited labor-mobility barriers.
Their [AEA article page](https://www.aeaweb.org/articles?id=10.1257%2Fmac.20160236&page=475) supports the cross-country characterization, and the [author-posted paper](https://toddschoellman.com/papers/AgWagesPaperResubmission.pdf) documents the panel comparison in Sections 1 and 5.2.

The citation at line 66 is weaker because Herrendorf and Schoellman (2018) studies wages across agriculture and other sectors, not rural-urban consumption gaps after cost-of-living adjustment.
Either remove it from that sentence or rewrite the sentence so that its outcome and margin match the paper.

### Schoellman: strengthen the closest existing review citation

The line 130 claim is almost exactly the organizing question in Donovan and Schoellman (2023), which uses a Roy model to distinguish gaps caused by heterogeneous-worker selection from gains blocked by labor-market frictions.
The citation would carry more weight in the main text:

```latex
A central debate in this literature is whether earnings or consumption gaps imply that productivity and welfare would increase if workers could reallocate to more productive sectors, or whether they reflect the self-selection of heterogeneous workers across sectors \citep{donovanRoleLaborMarket2023}.
```

The [published article](https://www.tandfonline.com/doi/abs/10.1080/13600818.2023.2276702) explicitly reviews sectoral wage gaps, worker flows, specific frictions, and policies that may improve mobility.

### Liao: add only in an explicit inference paragraph

Equation `\eqref{eq:phi-proposition1}` in the draft shows that $\phi$ becomes weakly identified when switcher trajectories have similar average rural consumption.
The resulting moment Jacobian is then close to rank deficient in the direction that identifies $\phi$.
A paragraph after the GMM moments at lines 456--463 could say:

```latex
When switcher trajectories have similar values of $\mu_{\underline d}$, the moment Jacobian becomes nearly rank deficient in the direction that identifies $\phi$.
Local identification failures of this kind can produce nonstandard GMM estimator and overidentification-test asymptotics \citep{leeLiaoStandardInference2018}.
We therefore construct confidence sets for the LCA parameters by inverting [name the statistic and cite the paper that establishes the validity of this exact inversion procedure].
```

Lee and Liao (2018) studies GMM models in which the Jacobian is rank deficient in a known form and shows that the local identification failure produces slow convergence and nonstandard overidentification-test asymptotics.
The authors then exploit the known form of the deficiency to recover standard properties.
The manuscript's inversion procedure is related in motivation but is not the Lee-Liao procedure, so the text should not say “following Lee and Liao.”
The [publisher page](https://www.cambridge.org/core/journals/econometric-theory/article/abs/on-standard-inference-for-gmm-with-local-identification-failure-of-known-forms/5DCB091CA8A31182B7EBF7929BA045E5) supports this limited characterization.

The current draft calls its inference weak-identification robust at line 98 and discusses inversion at lines 793 and 825--827, but the methods section at lines 456--463 currently describes only two-step efficient GMM, a Hansen $J$-test, and clustered standard errors.
The inference paragraph should identify the inverted statistic, its degrees of freedom, its critical values, and the source that proves weak-identification validity.
Lee and Liao is a related-literature citation, not a substitute for that source.

### Schoellman: optional measurement caveat

Herrendorf and Schoellman (2015) is relevant if the authors want to sharpen the distinction between large measured productivity gaps and gains from labor reallocation.
The paper shows that sectoral productivity gaps need not equal gaps in marginal value products and documents agricultural value-added mismeasurement in US data.
A restrained footnote near lines 129--133 could say:

```latex
Measured labor-productivity gaps need not map directly into marginal-product gaps; \citet{herrendorfWhyMeasuredProductivity2015} show that agricultural value-added mismeasurement materially contributes to the discrepancy in US data.
```

This citation is optional because the current Donovan and Schoellman review already covers the broader debate, and the US measurement exercise is not central to the paper's developing-country panel estimand.
The [published abstract](https://www.sciencedirect.com/science/article/abs/pii/S1094202514000647) supports the narrower wording above.

## Thematic assessment

### Theoretical contributions

Herrendorf and Schoellman (2018) provides a multi-sector model with heterogeneous workers and sector-specific human-capital intensities.
Its main relevance is to the paper's selection-versus-barriers framing, not to the GRC identification argument.

Donovan and Schoellman (2023) uses a simple Roy model to organize evidence on whether sectoral outcome gaps reflect opportunities for workers or selection of heterogeneous workers.
This is the closest conceptual bridge to the paper.

### Empirical findings

Herrendorf and Schoellman (2018) documents lower agricultural wages, education, and Mincer returns across 13 countries and compares its model-implied barriers with panel evidence on workers leaving agriculture in the United States, Brazil, and Indonesia.
Herrendorf and Schoellman (2015) provides a measurement warning about sectoral productivity gaps.
Donovan, Lu, and Schoellman (2023) documents high job and occupational turnover in developing economies, driven largely by transitions into and out of marginal work, but it does not estimate returns to rural-urban migration.

### Methodological innovations

Lee and Liao (2018) is the only Liao paper with a close connection to the draft's central econometric issue.
It establishes that a known-form rank deficiency in a GMM moment Jacobian can produce nonstandard estimator and overidentification-test asymptotics and proposes a way to exploit that known form.

Hahn and Liao (2021) on bootstrap standard-error estimates is not a good citation for the current procedure.
It concerns inference based on bootstrap variance estimates, whereas this manuscript inverts a test statistic and propagates an accepted confidence region through counterfactuals.

### Open debates and gaps

First, the manuscript should state each treatment margin explicitly.
Herrendorf and Schoellman (2018) studies agriculture-to-nonagriculture wage gains, whereas the paper's main estimand is the consumption return to rural-urban location.

Second, the paper should distinguish the conventional Hansen $J$-test used as a specification diagnostic from the statistic inverted for weak-identification-robust confidence sets.
This distinction becomes more important, not less, if Lee and Liao (2018) is cited.

Third, the manuscript should cite the canonical source for its exact weak-identification-robust inversion procedure in addition to the related Lee-Liao paper.

## Bibliography housekeeping

The bibliography contains duplicate entries for Herrendorf and Schoellman (2018): `herrendorfWagesHumanCapital2018a` and `herrendorfWagesHumanCapital2018`.
Only the latter is cited in the current draft.
Consolidating them before submission will avoid duplicate-reference or metadata inconsistencies.

The bibliography already contains the optional Herrendorf and Schoellman (2015) entry and the two Schoellman papers currently cited.
Only Lee and Liao (2018) would require a new entry.

## BibTeX entries

```bibtex
@article{leeLiaoStandardInference2018,
  author  = {Lee, Ji Hyung and Liao, Zhipeng},
  title   = {On Standard Inference for {GMM} with Local Identification Failure of Known Forms},
  journal = {Econometric Theory},
  year    = {2018},
  volume  = {34},
  number  = {4},
  pages   = {790--814},
  doi     = {10.1017/S026646661700024X}
}

@article{donovanRoleLaborMarket2023,
  author  = {Donovan, Kevin and Schoellman, Todd},
  title   = {The Role of Labor Market Frictions in Structural Transformation},
  journal = {Oxford Development Studies},
  year    = {2023},
  volume  = {51},
  number  = {4},
  pages   = {362--374},
  doi     = {10.1080/13600818.2023.2276702}
}

@article{herrendorfWagesHumanCapital2018,
  author  = {Herrendorf, Berthold and Schoellman, Todd},
  title   = {Wages, Human Capital, and Barriers to Structural Transformation},
  journal = {American Economic Journal: Macroeconomics},
  year    = {2018},
  volume  = {10},
  number  = {2},
  pages   = {1--23},
  doi     = {10.1257/mac.20160236}
}

@article{herrendorfWhyMeasuredProductivity2015,
  author  = {Herrendorf, Berthold and Schoellman, Todd},
  title   = {Why Is Measured Productivity So Low in Agriculture?},
  journal = {Review of Economic Dynamics},
  year    = {2015},
  volume  = {18},
  number  = {4},
  pages   = {1003--1022},
  doi     = {10.1016/j.red.2014.10.006}
}

@article{donovanLaborMarketDynamics2023,
  author  = {Donovan, Kevin and Lu, Will Jianyu and Schoellman, Todd},
  title   = {Labor Market Dynamics and Development},
  journal = {Quarterly Journal of Economics},
  year    = {2023},
  volume  = {138},
  number  = {4},
  pages   = {2287--2325},
  doi     = {10.1093/qje/qjad019}
}
```

## Suggested next steps

1. Recast the Herrendorf and Schoellman (2018) citation as a separate cross-country wage-and-human-capital result.
2. Keep Donovan and Schoellman (2023), preferably in the main text at the selection-versus-frictions claim.
3. Add Lee and Liao (2018) only when the methods section explicitly distinguishes the standard $J$-test from the weak-identification-robust inversion procedure and cites the procedure's own methodological source.
4. Skip the other candidate papers unless the substantive argument expands.
