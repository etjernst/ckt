## 3.4 Testing the Validity of the Extrapolation to Stayers

In this section, we discuss how to test the validity of the extrapolations discussed in sections 3.2 and 3.3 above. When only two time periods are observed ( T = 2), equations (2.12) and (2.13) above show that the extrapolation identifying assumption (2.11) is equivalent to an identity that defines four previously unrestricted parameters in terms of quantities identified by the CRC model (2.4), so that the extrapolation identifying assumption does not contain any testable implications under the CRC model. The online appendix articulates this result in a more direct way.

When three or more time periods are available, the extrapolation identifying assumption (2.11) can be tested because there are more than two groups of movers for which average baseline heterogeneity and


<!-- page 22 -->

ATE are identified by the CRC model. One can test the extrapolation identifying assumption (2.11) by testing whether a linear relationship exists between the points ( E ( ai | x 1 , ..., xT ) , E ( bi | x 1 , ..., xT )) identified by the CRC model for all combinations of values { x 1 , ..., xT } corresponding to movers. In practice, one can implement such a test as a simple overidentification test following the instrumental variable regression of ˆ ai on ˆ bi using xi 1 , ..., xiT as instrumental variables. The appendix provides the details of the test.

Similarly, the generalized extrapolation identifying assumption (2.18) can be tested when more than two time periods are observed by testing whether a linear relationship exists between the baseline heterogeneity and treatment effect of movers of different treatment status history profiles after partialling out variation at the level of the indexing variable vi . The test takes the form of an overidentification test as well, but following a fixed effects instrumental variable regression. Details of the test are provided in the appendix.

## 4 Empirical Application: Returns to Hybrid Seeds

In this section, we apply the results discussed above to a longitudinal dataset of Kenyan maize farmers. The dataset was collected as part of the Tegemeo Agricultural Monitoring and Policy Analysis Project by the Tegemeo Institute at Egerton University and Michigan State University. This same dataset was also used in Suri (2011), and hence we refer the reader to Suri (2011) for a detailed discussion of the data and of the related empirical literature. The only notable difference here is that we use data on years 1997, 2004, 2007, and 2010 while Suri (2011) only used waves 1997 and 2004 for her study as these were the only two waves available at the time.

We observe a total of 1,130 farmers in our estimation sample but in an unbalanced panel with a total of 3,770 observations, so that farmers are observed for around 3.5 time periods on average. The sample is decomposed into 354 farmers observed both using and not using hybrid seeds over time (movers), 123 farmers never observed using hybrid seeds (untreated stayers), and 653 farmers always observed using hybrid seeds (treated stayers).

The adoption rate of hybrid seeds increased between the years 1997 and 2010: 72% of farmers in our sample used hybrid seeds in 1997, 71% in 2004, 77% in 2007, and 88% in 2010. This reflects an increase in the ease of access to hybrid seeds, which is also evidenced by the decrease in average distance to the nearest seed seller over time, from 6.1 kilometers on average in 1997, to 2.6km in 2004, 2.9km in 2007, and 3.3km in 2010. On the other hand, a significant number of farmers in our sample are still never observed using hybrid seeds. The methods developed above can be used to estimate whether these farmers would experience high


<!-- page 23 -->

returns from adopting hybrid seeds.

Reflecting the discussion above, our empirical approach starts with estimating the ATE for movers and follows with an extrapolation to obtain the ATE of stayers. We consider two extrapolations. In section 4.2, we discuss the extrapolation based on the extrapolation identifying assumption (2.11), which we call non-robust, and discuss evidence against the validity of this extrapolation. In section 4.3 we implement an extrapolation based on the generalized extrapolation identifying assumption (3.7) that accounts for village-level correlated cost shifters, which we call robust.

## 4.1 Effect of Using Hybrid Seeds for Movers

In this section, we estimate the average effect of using hybrid seeds on yields for farmers who are observed in our data both using and not using hybrid seeds (movers). To do so, we use the CRC model for farmer i in year t :

<!-- formula-not-decoded -->

where yit is maize yields (logarithm of kilograms harvested per acre), xit hybrid seed use, X =[ xi 1 , ..., xiT ] i = 1 ,..., n , Z =[ zi 1 , ..., ziT ] i = 1 ,..., n , and zit is the same vector of control covariates as in Suri (2011), namely: main season rainfall, variables measuring other inputs to production than hybrid seed use, acres planted, and demographics of the household such as size, gender distribution, and age. We also include province-by-year fixed effects in the controls to account for regional time varying shocks that might have occurred during the fairly long period of observation. The unobserved term ai captures a farmer's baseline productivity, while bi captures a farmer's returns to using hybrid seeds.

## 4.1.1 Discussion of the CRC Assumptions

In the context of hybrid seed adoption, the CRC model given by (4.1) presents the advantage of allowing for fairly flexible patterns of selection into technology use. For instance, both a farmer's baseline productivity, ai , and her return to using hybrid seeds, bi , may be correlated with her decision to use hybrid seeds.

On the other hand, as discussed in section 2 above, the CRC model (4.1) imposes three restrictions: (i) strict exogeneity of the covariates xit and zit with respect with transitory shocks uit , (ii) the parallel trends assumption, and (iii) time-constant (in conditional mean) treatment effects. The first restriction rules out feedback mechanisms from past shocks to productivity to current technology use. The second and third re-


<!-- page 24 -->

strictions may be particularly appropriate in this context if we think of baseline productivity, ai , and treatment effect, bi , as being determined by intrinsic qualities of a farmer's land that do not evolve over time. 31

## 4.1.2 Estimation Results

As discussed above, estimates of the coefficients g t and noisy estimates of baseline heterogeneity ai , treatment effect bi , and total heterogeneity ai + bi (depending on a cross-sectional observation's treatment status history) are obtained by an OLS regression of yit on indicator variables for each cross-sectional observation, the interaction of these indicator variables with hybrid seed use, and the covariates zit interacted with indicator variables for each time period. 32

Given these estimates, estimates of average returns (ATE in the general discussion of Section 2) are obtained for different groups of movers, which we present in Table 1. Returns for movers are estimated to be 23% on average, but with substantial variation across subgroups of movers. Movers who used hybrid seeds early in the period of observation, i.e. those who abandoned the use of hybrid seeds in later years, are estimated to have relatively low average returns (movers who used hybrid seeds in 1997 and 2004 are estimated to have average returns to using hybrid seeds of 8% and 11%, respectively). Movers who used hybrid seeds later, i.e., those who adopted the use of hybrid seeds in later years, are estimated to have higher average returns (movers who used hybrid seeds in 2007 and 2010 are estimated to have average returns to using hybrid seeds of 23% and 28% respectively). Similarly, movers who were not using hybrid seeds in early years are estimated to have higher average returns than movers who were not using hybrid seeds in later years (for instance, average returns are estimated to be 37% for movers not using hybrid seeds in 1997 and around 0% for movers not using hybrid seeds in 2010).

Low average returns among early adopters who disadopted in later time periods are consistent with these farmers being marginal hybrid seed users. High average returns among late adopters are consistent with a technology diffusion process such that some farmers who would have benefited from high returns to adoption glyph[negationslash]

31 We can also test these restrictions with an overidentification test. Defining the partial residual eit = yit -zit g t , we can test whether E ( D eit | xi 1 , ..., xiT ) = 0 across all time periods t = 2 , ..., T and treatment status history profiles such that xit = xit -1 ∈{ 0 , 1 } . In this application, in order to guarantee that groups of relatively large sizes are used, we test whether E ( D eit | xit = xit -1 = x , mi = m ) = 0 for all time periods t = 2 , ..., T , x ∈ { 0 , 1 } , m ∈ { 0 , 1 } , where mi = 1 [ min t = 1 ,..., T x it = max t = 1 ,..., T x it ] indexes whether a cross-sectional observation is a mover. The p-value corresponding to this over-identification test is 32%, so that the test does not yield strong evidence against the CRC model. This test is similar to a parallel trends test in event study analysis except that here we also test the restriction that treatment effects are constant over time.

32 Here we observe four time periods but an unbalanced panel. We treat data as missing at random. Every cross-sectional observation with three or more observed time periods participates in the estimation of the coefficients g t , regardless of whether they are stayers or movers. Among cross-sectional observations with only two observed time periods, only stayers participate in the estimation of the coefficients g t .


<!-- page 25 -->

did not use hybrid seeds in early years - perhaps because of high costs of adoption - but did gain access to hybrid seeds in later years, providing further evidence that access to hybrid seeds has improved over time.

On the other hand, a significant number of farmers in our sample are still never observed using hybrid seeds. The methods discussed in the previous sections can be used to estimate whether these farmers would experience high returns from adopting hybrid seeds.

## 4.2 Simple Extrapolation to Stayers

The first extrapolation that we consider relies on the extrapolation identifying assumption (2.11). Before presenting our results, we discuss this assumption in the context of our empirical application.

## 4.2.1 Discussion of the Simple Extrapolation Identifying Assumption

Assumption (2.11) requires that the history of a farmer's use of hybrid seed have no partial predictive effect on baseline heterogeneity. As discussed in section 2.4, this assumption can be interpreted as imposing two restrictions. The first restriction is a functional form restriction of linearity. The second restriction is that factors other than a farmer's return to using hybrid seed that determine her use of hybrid seeds be statistically uncorrelated with a farmer's baseline heterogeneity and returns to using hybrid seeds. In section 4.2.3 below, we discuss this second restriction in more detail and discuss evidence that the cost of using hybrid seeds may be statistically correlated with baseline heterogeneity and treatment effects, leading to a likely violation of the simple extrapolation used in this section. 33

In addition, for identification, it is required that variation in average returns be observed across different groups of movers. As discussed above, this is the case here since we estimate that there exists substantial variation in returns when comparing movers who were or were not using hybrid seeds in earlier or later years. This is also seen in figure 2, which plots the estimated average returns for the different groups of movers discussed above, as well as their estimated average baseline heterogeneity.

## 4.2.2 Estimation Results

We can estimate the parameters a 0 and a 1 of the extrapolation identifying assumption given by (2.11) by an instrumental variable regression among movers of estimated baseline productivity on estimated returns to using hybrid seeds, with instrumental variables taken to be hybrid seed use in all observed time periods. The

33 An additional potential concern is that farmers may not know what their returns to using hybrid seeds are prior to adopting the technology for the first time, and may learn about their returns as they use the technology. Depending on the specific form of learning, this might not invalidate the extrapolation identifying assumption. This is discussed briefly in the appendix.


<!-- page 26 -->

appendix details our estimation procedure, which is an extension of the procedure defined above to the case where an unbalanced panel with more than two time periods is observed. Table 1 reports these estimates, with a 1 in particular estimated to be -0 . 49, so that a negative statistical relationship is estimated to exist between baseline productivity and returns (i.e., on average low productivity farmers are estimated to benefit from higher returns from using hybrid seeds than high productivity farmers). This sign is expected since hybrid seeds are designed to compensate for the deficiencies of particular growing conditions, so that one would expect higher returns from using hybrid seeds on low-productivity plots. 34 Given estimated values for a 0 and a 1, and estimates of average baseline heterogeneity for untreated stayers obtained from the first step of our estimation procedure, we can estimate the average returns from using hybrid seeds for untreated stayers with a simple plug-in estimator, similar to what was discussed in section 3.2. The non-robust extrapolation estimates the average returns for non-hybrid stayers to be 66%, i.e., much larger than the average returns for movers. 35 Figure 2 represents this extrapolation graphically. 36

## 4.2.3 Evidence against the Validity of the Simple Extrapolation

Suri (2011) also finds that non-hybrid stayers are farmers with low average baseline productivity that would benefit from high average returns from using hybrid seeds. Her estimates for a 1 (although based on a dataset with only two time periods and under the additional assumption that control covariates are exogenous in the extrapolation identifying assumption, as discussed in section 2.6) are similar to our estimate in this section (her main specifications find a 1 to be in a range of approximately -0 . 5 to -0 . 66). She finds that untreated stayers would benefit from an even larger average returns from using hybrid seeds than the results reported above (she estimates average returns of 100% among untreated stayers in her main specification).

34 In addition to a 1 , it could be interesting to learn about the correlation between baseline heterogeneity, ai , and treatment effect, bi . Given knowledge of a 1 = Corr ( ai , bi ) Var ( bi ) , only Var ( bi ) would need to be estimated. However, as discussed above and in Arellano and Bonhomme (2012), identification of Var ( bi ) would generally require stronger assumptions than those imposed by the CRC model (2.4). Section 4.2.3 below discusses evidence against the validity of the extrapolation identifying assumption (2.11). Note that if | Corr ( ai , bi ) | = 1, this assumption would necessarily hold with ai = a 0 + a 1 bi . Therefore we can at least note that the results discussed in the next section point to the absolute value of the correlation between baseline heterogeneity, ai , and treatment effect, bi , being strictly less than one.

35 We report results for non-hybrid stayers only. In the next subsection we implement a robust extrapolation that yields an estimate of a 1 that is close to -1, so that average returns for hybrid stayers may not be identified with the robust extrapolation. In addition, as discussed in the next subsection, our robust extrapolation can only be applied to stayers who live in a village with a least one mover (which represents 91% of non-hybrid stayers), so that for consistency we report results for this subsample of non-hybrid stayers only in this section as well.

36 The extrapolation line can be estimated by two-stage least squares (2SLS) or optimally weighted generalized method of moments (GMM). Throughout this section, we report results using GMM as we can expect an efficiency gain over 2SLS, which is discussed in more details in the appendix. Figure 2 plots both estimated extrapolation lines. We see that neither extrapolation line seems to provide a good fit for the sample moments obtained from the data. There is also a significant difference between these two extrapolation lines, which corresponds to the known first-order impact of the choice of weight matrix when estimating models that are misspecified, see Hall and Inoue (2003).


<!-- page 27 -->

Suri (2011) reconciles high estimated average returns among farmers who are not observed using hybrid seeds with a selection model in which farmers use hybrid seeds if their returns exceed their cost by showing evidence that non-hybrid stayers are also exposed to higher costs of adopting hybrid seeds. Since the price of hybrid seeds was regulated during her period of observation, the main determinant of the cost of using hybrid seeds was a farmer's distance to the nearest seed seller. Suri (2011) shows that farmers with a low baseline productivity, ai , who also tend to have higher returns to using hybrid seeds, bi , tend to live further away from seed sellers, which explains their non-adoption of the technology.

glyph[negationslash]

However, as discussed in section 2.4, this statistical correlation between the cost of adoption of hybrid seeds and baseline returns would generally lead to the simple extrapolation identifying assumption (2.11) being invalid. Intuitively, this is because the extrapolation identifying assumption (2.11) requires that a farmer's history of hybrid seed use be predictive for this farmer's baseline heterogeneity only because it is predictive of her returns to hybrid seeds. If this condition holds, and if returns are correlated with baseline heterogeneity ( a 1 = 0), one can learn about untreated stayers' average returns from their average baseline heterogeneity. If one of the main determinants of the cost of using hybrid seeds (distance to the nearest seed seller) has a partial predictive effect on baseline heterogeneity, then a farmer's history of hybrid seed use will be predictive of her baseline heterogeneity both by being predictive for her returns from using hybrid seeds and by being predictive for her cost of using hybrid seeds. The predictive effect through the cost of using hybrid seeds will confound the relationship between baseline heterogeneity and returns and will invalidate the extrapolation to stayers used in Suri (2011) or in this section.

We can provide two forms of empirical evidence of the invalidity of the non-robust linear extrapolation. Firstly, we can estimate the linear extrapolation with distance to the nearest seed seller as an additional exogenous covariate:

<!-- formula-not-decoded -->

where ¯ di is the average distance, in kilometers, of a farmer to the nearest seed seller during the years in which this farmer is observed in our data. For the 354 movers in our data, the average of ¯ di is 4 . 08 km, with a standard deviation of 3 . 67 km. The null hypothesis that the factors of selection into treatment other than treatment effect have no partial predictive effect on baseline heterogeneity is simply expressed as a 2 = 0. We can estimate this model by an instrumental variable regression of our estimates of baseline heterogeneity, ˆ ai , on our estimates of returns, ˆ bi , using treatment status history, xi 1 , ..., xiT , as instrumental variables and average


<!-- page 28 -->

distance to the nearest seed seller, ¯ di , as an exogenous covariate, using observations on movers only. With this specification, we estimate a 1 to be -. 34 and a 2 to be -. 04, and testing the statistical significance of a 2 leads to a p-value of 2.8%, which supports the concern with the validity of the extrapolation.

In addition, we can test the simple extrapolation discussed in this section directly by using an overidentification test as discussed in section 3.4. Testing the null hypothesis that the non-robust extrapolation is valid in this way also leads to a p-value lower than 1% (reported in Table 1). We also see from figure 2 that the sample moments obtained from the data do not seem to be well approximated by a single extrapolation line.

## 4.3 Robust Extrapolation to Stayers

To address the concerns with the validity of the simple extrapolation discussed above, we can use a robust extrapolation based on the generalized extrapolation identifying assumption (3.7), where we take the indexing variable vi to be a farmer's village.

## 4.3.1 Discussion of the Robust Extrapolation Identifying Assumption

The robust extrapolation discussed in this section allows for dependence between the cost of using hybrid seeds and productivity, provided that this dependence originates from village specific cost shifters only. This accounts, for instance, for a farmer's distance to the nearest seed seller being correlated with a farmer's productivity since there is little variation in distance to the nearest seed seller across farmers who live in the same village, so that this cost shifter can be taken as common to all farmers who live in the same village. It will also account for the dependence between productivity and any other village-level cost shifter such as transportation amenities, information on hybrid seeds shared across farmers within villages, or the price of hybrid seeds if it varies geographically. On the other hand, any correlated cost shifter that is not common across all farmers in a village could lead to a violation of the generalized extrapolation assumption (3.7). 37

## 4.3.2 Estimation Results

As discussed in section 3.3, we can estimate the slope coefficient a 1 of the generalized extrapolation identifying assumption (3.7) by a fixed-effects instrumental variable regression among movers of the estimated baseline productivity on the estimated returns to using hybrid seeds, where fixed effects are indexed

37 While there is little variation in distance to the nearest seed seller across farmers who live in the same village, there is sufficient variation that one can in principle include distance to the nearest seed seller in addition to village-level fixed effects as controls for correlated cost shifters in the extrapolation to stayers. Results with that extrapolation are almost identical to the results discussed below and are not reported here for concision. We see that since the results discussed here are different than the results obtained including distance to the nearest seed seller as the only control for correlated cost shifters, reported in section 4.2.3, there must be other village-level correlated cost shifters than distance to the nearest seed seller that confound a simple extrapolation to stayers.


<!-- page 29 -->

by a farmer's village and instrumental variables are taken to be hybrid seed use in all observed time periods. The appendix details our estimation procedure. With this generalized extrapolation, we estimate a 1 to be -0 . 95, so that the predictive effect of returns on baseline productivity is still estimated to be negative when accounting for the predictive effect of village-level cost shifters, but the magnitude of this predictive effect is estimated to be larger after controlling for village-level cost shifters. Note that since this last estimate of a 1 is close to -1, we concentrate on non-hybrid (untreated) stayers throughout this section and do not obtain results for hybrid (treated) stayers. 38 As discussed in section 3.3, the generalized extrapolation requires that a stayer live in a village with at least one observed mover. In our data, 91% of farmers who never used hybrid seeds live in a village with at least one mover, so the results below are reported for these farmers only.

With this robust extrapolation, we estimate average returns for non-hybrid stayers to be 37%, i.e., larger than returns for movers but only marginally so. 39 We can test the validity of the generalized extrapolation identifying assumption (3.7) by using an overidentification test as in the previous section, the details of which are outlined in the appendix. We find significantly weaker evidence against the robust extrapolation, with a pvalue of 0.26. Figure 2 also represents the robust extrapolation graphically, by plotting the estimated average returns for different groups of movers against their estimated average baseline heterogeneity deviated from village-level factors, ai -evi . These averages can be consistently estimated by simply averaging the noisy estimates ˆ ai -ˆ evi across large groups of movers or untreated stayers. We find that, visually, the robust extrapolation assumption (3.7) seems to fit the data quite well, with these pairs of averages approximately lying on a single extrapolation line.

