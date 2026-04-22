<!-- chunk 1: pages 1-10 -->

## 
<!-- page 1 -->

Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data

## Online Appendix

Valentin Verdier ∗ May 26, 2020

∗ Department of Economics, University of North Carolina - Chapel Hill.

## 
<!-- page 2 -->

Contents

| A   | Identification with a General Number of Time Periods                    | 5                                                                       |
|-----|-------------------------------------------------------------------------|-------------------------------------------------------------------------|
| B   | Notation and Comparison with the Methods of Suri 2011 and Lemieux       | Notation and Comparison with the Methods of Suri 2011 and Lemieux       |
|     | 1998                                                                    | 6                                                                       |
|     | B.1 Lemieux 1998 . . . . . . . . . . . . . . . . . . . . . . . . . .    | 8                                                                       |
|     | B.2 Suri 2011 . . . . . . . . . . . . . . . . . . . . . . . . . . . .   | 10                                                                      |
| C   | Comparison of the Extrapolation Identifying Assumption with Generalized | Comparison of the Extrapolation Identifying Assumption with Generalized |
|     | Roy Models                                                              | 15                                                                      |
| D   | CRC Model with Time-Varying Treatment Effects                           | 16                                                                      |
| E   | Estimation and Inference with the Simple Extrapolation Identifying As-  | Estimation and Inference with the Simple Extrapolation Identifying As-  |
|     | sumption                                                                | 21                                                                      |
|     | E.1 Step 1: High-dimensional regression . . . . . . . . . . . . . .     | 23                                                                      |
|     | E.2 Step 2: Instrumental Variable Regression and Extrapolation          | 25                                                                      |
|     | E.3 Testing the Validity of the Extrapolation . . . . . . . . . . .     | 33                                                                      |
|     | E.3.1 Lack of testable implications with two time periods .             | 33                                                                      |
|     | E.3.2 Testing with three or more time periods . . . . . . .             | 33                                                                      |
| F   | Estimation and Inference with the Generalized Extrapolation Identifying | Estimation and Inference with the Generalized Extrapolation Identifying |
|     | Assumption                                                              | 35                                                                      |
| G   | Estimation and Inference with Unbalanced Panels                         | 44                                                                      |
| H   | Proofs                                                                  | 46                                                                      |
|     | H.1 Proof of Proposition 1 . . . . . . . . . . . . . . . . . . . . .    | 46                                                                      |
|     | H.2 Proof of Proposition 2 . . . . . . . . . . . . . . . . . . . . .    | 47                                                                      |
|     | H.3 Definitions and Lemma for the Proof of Proposition 3 . . . .        | 53                                                                      |

| H.4                        | Proof of Proposition 3 . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 54   |
|----------------------------|-----------------------------------------------------------------------------------------|
| H.5 Proof of Proposition 4 | . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 58                          |
| H.6 Proof of Proposition 5 | . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 60                          |
| H.7 Proof of Proposition 6 | . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 65                          |
| H.8 Proof of Proposition 7 | . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 65                          |
| H.9 Proof of Proposition 8 | . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 65                          |


<!-- page 4 -->

In this appendix we provide the technical details corresponding to our discussion in the main text. Section A briefly discusses identification of time effects and average treatment effects (ATE) with a correlated random coefficient (CRC) model and a general number of time periods, while the main text focused on the case where two time periods are observed for simplicity. Section B discusses the estimation methods of Lemieux (1998) and Suri (2011). Section C compares the sufficient set of conditions for the extrapolation identifying assumption to hold discussed in the main text with generalized Roy models. Section D discusses CRC models with time-varying treatment effects. Section E discusses the two-step estimation method defined in the main text and the test of validity of the extrapolation identifying assumption for the simple extrapolation. Section F discusses the extension of these methods to using the generalized extrapolation identifying assumption discussed in the main text. Section G discusses the implications of using unbalanced panels due to data missing at random. Section H contains proofs for the results of Sections E and F. Propositions 1-3 in the main text are obtained as special cases of the propositions stated in Sections E and F, but with more cumbersome notation. Therefore we also write in Section H proofs for Propositions 1-3 in the main text. In Section I we briefly discuss the consequences of learning about treatment effects (returns in our empirical application) upon being treated on the validity of the CRC model and extrapolation identification assumptions discussed in the main text.

Throughout the appendix, c will denote an arbitrary positive constant c &gt; 0 and C will denote an arbitrary constant C &lt; ∞ . We use |A| to denote the cardinality of any set A . We use the notation O p to denote that a sequence is bounded in probability and o p to denote that a sequence converges in probability. Throughout the appendix, referenced equations corresponding to numbered sections are found in the main text, while equations corresponding to sections indexed by letters are found in this appendix.

## 
<!-- page 5 -->

A Identification with a General Number of Time Periods

In this section we discuss the information contained in the CRC model (2.4) for a general number of time periods T , while the main text only considered T = 2 for simplicity.

Under cross-sectional independence, we can stack observations across time and rewrite the CRC model (2.4) as:


where Y i = [ y it ] t =1 ,...,T , W i = [ j T X i ] , j T = [1] t =1 ,...,T , X i = [ x it ] t =1 ,...,T , f = [ f t ] t =1 ,...,T , U i = [ u it ] t =1 ,...,T .

As in Chamberlain (1992), since the relationship between baseline heterogeneity ( a i ), treatment effect ( b i ), and treatment status history ( X i ) is left unrestricted, the information for estimating f contained in (A.1) is equivalent to the information contained in:


where M W i = I T -W i ( W ′ i W i ) -W ′ i and ( . ) -is a generalized inverse operator.

As in the main text, we will apply the normalization f 1 = 0, so that time effects f t are identified if M W i has rank greater than T -1 for some values of X i corresponding to a positive probability. For values of X i corresponding to stayers, M W i is the projection matrix of a regression on an constant using T observations, so that it has rank T -1, leading to identification of time effects from observations on stayers.

With two time periods, M W i = 0 for cross-sectional observations i that correspond to movers. However with three or more time periods, rank ( M W i ) ≥ T -2 &gt; 0, and observations on movers participate in the identification of time effects f t . Depending on the profiles of


<!-- page 6 -->

treatment status history observed in the data, it is possible for all time effects f t , t = 2 , ..., T to be identified by observations on movers only when T ≥ 3.

The CRC model (A.1) is equivalent to (A.2) and:


where B i = ( W ′ i W i ) -W ′ i and ζ i is an unknown, unrestricted term of heterogeneity.

This shows that conditional average treatment effect E ( b i | X i ) is only identified for crosssectional observations such that W ′ i W i is non-singular. With x it being binary, W ′ i W i is non-singular for movers and singular for stayers, so that average treatment effects are only identified for movers.

## B Notation and Comparison with the Methods of Suri 2011 and Lemieux 1998

In this section we describe the estimation procedures used by Lemieux (1998) and Suri (2011) and show that they can be represented by the linear extrapolation discussed in the main text when there are no additional covariates in the model, i.e. when treatment status x it is the only covariate.

First we map the notation used by Lemieux (1998) and Suri (2011) to the notation used in the main text. In the simple setting without additional covariates, our notation for the correlated random coefficient model with the extrapolation identifying assumption and two time periods is given by:




<!-- page 7 -->

In the simple setting without additional covariates, the notation used by Lemieux (1998) writes potential outcomes without (N) or with (U) treatment as:



where θ U i and θ N i have mean zero, so that the average treatment effect is given by ¯ δ and glyph[epsilon1] ′ it are unobserved wage shocks.

Therefore our notation writes f t = δ N t , a i = θ N i , b i = ¯ δ + θ U i -θ N i , u it = glyph[epsilon1] ′ it .

The notation for the extrapolation identifying assumption in Lemieux (1998) is given by the linear projections:


where b N = Cov ( θ N 1 ,θ N i -θ U i ) V ar ( θ N i -θ U i ) and b U = Cov ( θ U 1 ,θ N i -θ U i ) V ar ( θ N i -θ U i ) .

Lemieux (1998) then defines glyph[epsilon1] it = ξ i + glyph[epsilon1] ′ it and assumes:


In our notation we have α 1 = b N , glyph[epsilon1] i = ξ i , α 1 +1 = b U

Lemieux (1998) defines θ i = b N ( θ N i -θ U i ) and ψ = b U b N



In our notation we have α 1 +1 α 1 = ψ , α 1 b i = θ i .

. so that:


<!-- page 8 -->

The model for observed outcomes estimated by Lemieux (1998) is then given by:


In the next two subsections we show that under the CRC model assumption (B.1) only, estimation of all the parameters in the model (B.4) that combines the CRC model with the extrapolation identifying assumption (B.2) by generalized method of moments estimation (Lemieux (1998)) or minimum distance estimation (Suri (2011)) leads to the linear extrapolation from ATE among movers to ATE among stayers depicted in Figure 1 of the main text.

## B.1 Lemieux 1998

The estimation procedure proposed by Lemieux (1998) is GMM estimation from the moment conditions:



where the moment function e i ( . ) is defined to be:



<!-- page 9 -->

These moment conditions can be rewritten as:


Under the CRC model (B.1), with the normalization f 1 = 0, we can further re-write these moment conditions:






We see that the first two moment conditions (B.5) and (B.6) contain the same information under the CRC model (B.1), setting ∆ δ N 2 equal to ∆ f 2 . Therefore the remaining three moment conditions (B.7)-(B.9) are exactly identifying for ψ , δ N 1 , ¯ δ .

Equations (B.7) and (B.8) imply:


Defining α glyph[star] 1 = E ( a i | 0 , 1) -E ( a i | 1 , 0) E ( b i | 0 , 1) -E ( b i | 1 , 0) , we can therefore use ψ = α glyph[star] 1 +1 α glyph[star] 1 below to shorten notation. 1

1 Here we use α glyph[star] 1 to denote a pseudo-true value of a parameter since the extrapolation identifying assumption is not assumed to hold here, only the CRC model is assumed to hold throughout this section.


<!-- page 10 -->

We can re-write equation (B.8) as:


Therefore defining α glyph[star] 0 = E ( a i | 1 , 0) -α glyph[star] 1 E ( b i | 1 , 0) we can write that δ N 1 = α glyph[star] 0 + α glyph[star] 1 ¯ δ . Equation (B.9) can then be written:


where we define π x 1 x 2 = P ( x i 1 = x 1 , x i 2 = x 2 ) to shorten notation.

This yields:


so that the ATE for the entire population is indeed obtained by the linear extrapolation represented in Figure 1 of the main text. 2

## B.2 Suri 2011

The notation used in Suri (2011) is almost identical to the notation used in Lemieux (1998) but Suri (2011) uses minimum distance estimation instead of GMM estimation. The only differences between the notation in Suri (2011) and the notation in Lemieux (1998) are that the parameter φ is used, which is mapped to the notation of Lemieux (1998) by φ = ψ -1, so that this new parameter is mapped to our notation by φ = 1 α 1 . The expected value of returns is also defined to be β in Suri (2011) rather than ¯ δ in Lemieux (1998), so that this

2 Similarly ATE for untreated stayers would be taken to be ATE glyph[star] 00 = E ( a i | 0 , 0) -α glyph[star] 0 α glyph[star] 1 and ATE for treated stayers would be taken to be E ( a i + b i | 1 , 1) -α glyph[star] 0 1+ α glyph[star] 1 .

<!-- chunk 2: pages 11-20 -->


<!-- page 11 -->

new parameter is mapped to our notation by β = E ( b i ).

The reduced form parameters used in Suri (2011) are obtained from the conditional expectations:


which are obtained in this form without loss of generality since x it is a binary random variable.

In addition to the parameter φ and ATE β , the structural parameters to be identified in Suri (2011) also comprise the parameters in the conditional expected value of θ i conditional on treatment history:


The structural parameters to be identified in Suri (2011) are the parameters in the conditional expectation E ( θ i | x i 1 , x i 2 ), φ , and the ATE β (a total of six structural parameters). These structural parameters are estimated by minimum distance estimation from the link:









<!-- page 12 -->

where as before π x 1 x 2 = P ( x i 1 = x 1 , x i 2 = x 2 ) and where π 1 = P ( x i 1 = 1) and π 2 = P ( x i 2 = 1).

The first six equalities (B.13)-(B.18) follow from:


where the first equality follows from the model given by (B.4) with the notation used in Suri (2011).

The last equality (B.19) follows from E ( θ i ) = 0.

Under the CRC model we can rewrite the reduced form parameters as:


Therefore under the CRC model, equations (B.14), (B.15), (B.16), and (B.18) or equations (B.13), (B.14), (B.16), and (B.17) both lead to γ 6 -γ 3 γ 4 -γ 2 = γ 1 -γ 5 γ 4 -γ 2 -1 = E ( b i | 1 , 0) -E ( b i | 0 , 1) E ( a i | 1 , 0) -E ( a i | 0 , 1) . Therefore under the CRC model the system of seven equations (B.13)-(B.19) is at most exactly identifying for the six structural parameters.


<!-- page 13 -->

From (B.13), (B.14), (B.16), and (B.17) we find:




When φ = -1, the system linking reduced form parameters to structural parameters does not identify λ 3 , so that β , λ 0 , λ 3 are not identified, so that the probability limits of the estimators for average returns for stayers do not exist. In Figure 1 in the main text, this corresponds to the case where the line a + b = E ( b i | 1 , 1) + E ( a i | 1 , 1) and the extrapolation line going through ( E ( a i | 1 , 0) , E ( b i | 1 , 0)) and ( E ( a i | 0 , 1) , E ( b i | 0 , 1)) have the same slope, -1, so that they do not intersect at a unique point.

glyph[negationslash]

When φ = -1, then:

β is then given by:

We also have:

and:




<!-- page 14 -->

We can show from the above equalities that:


The above implies:


Using α glyph[star] 1 = E ( a i | 1 , 0) -E ( a i | 0 , 1) E ( b i | 1 , 0) -E ( b i | 0 , 1) and α glyph[star] 0 = E ( a i | 0 , 1) -α glyph[star] 1 E ( b i | 0 , 1) we can rewrite:


Similarly for expected returns for the population of stayers, which in Suri (2011) are given by:



<!-- page 15 -->

Under the CRC model, we have:


and:


Using α glyph[star] 1 = E ( a i | 1 , 0) -E ( a i | 0 , 1) E ( b i | 1 , 0) -E ( b i | 0 , 1) and α glyph[star] 0 = E ( a i | 0 , 1) -α 1 E ( b i | 0 , 1) we can rewrite:



Therefore we see that the method used in Suri (2011) corresponds to the extrapolation represented in Figure 1 of the main text.

## C Comparison of the Extrapolation Identifying Assumption with Generalized Roy Models

In this section we briefly compare generalized Roy models with the set of conditions (2.12) and (2.13) considered in the main text as sufficient for the extrapolation identifying assumption (2.11) to hold. We take as an example the model outlined in p. 365-366 of Carneiro et al. (2003), abstracting from observed covariates or instrumental variables, which can be


<!-- page 16 -->

written as:


where variables in bold denote random variables, y (1) and y (0) are potential outcomes with and without treatment, x is treatment status, θ is an unobserved common factor, and glyph[epsilon1] 0 , glyph[epsilon1] 1 , glyph[epsilon1] s are unobserved shocks to outcomes and selection into treatment.

glyph[negationslash]

We can define a = β 0 , 0 + β 1 , 0 θ + glyph[epsilon1] 0 , b = β 0 , 1 -β 0 , 0 +( β 1 , 1 -β 1 , 0 ) θ , so that if β 1 , 1 -β 1 , 0 = 0 we have a = β 0 , 0 -β 1 , 0 β 1 , 1 -β 1 , 0 ( β 0 , 1 -β 0 , 0 ) + β 1 , 0 β 1 , 1 -β 1 , 0 b + glyph[epsilon1] 0 and (2.12) holds. With these definitions, (2.13) also holds by defining c = glyph[epsilon1] s and from the assumption that glyph[epsilon1] s is independent of θ . With generalized Roy models, observing instrumental variables that satisfy exogeneity and relevance conditions, observing proxies for the unobserved common factor θ , or observing several independent measurements of θ , would yield identification of ATE (see also Cunha et al. (2005), Abbring and Heckman (2007)), while here the restrictions imposed by the CRC model (2.4) yield identification, as discussed in the main text.

## D CRC Model with Time-Varying Treatment Effects

In this section we discuss CRC models with time varying treatment effects. For simplicity we consider the case where there are no additional control covariates here, so that the model is given by:


Without additional restrictions on treatment effects, b it , identification of differences in time effects relies on average changes in outcomes for a cross-sectional observation across pairs of time periods when she was untreated only (whereas with the CRC model with time-


<!-- page 17 -->

constant treatment effects considered in the main text, pairs of time periods with the same treatment status - both treated and untreated - can be used to identify changes in time effects):


ATEfor movers who are currently treated can then be identified by difference-in-differences comparisons:


As in the main text, we can apply the normalization f 1 = 0 to shorten notation. Then average baseline heterogeneity is identified for movers and untreated stayers, and average total heterogeneity at each time period is identified for treated movers and stayers:


Under the CRC model with time varying random coefficients (D.1), ATE for movers who are currently untreated or for stayers are not identified. In order to extrapolate from the quantities identified by the CRC model (D.1) to ATE for stayers or for movers who are currently untreated, we can assume that a single term of unobserved heterogeneity determines baseline heterogeneity, treatment effects at each time period, and treatment status:





<!-- page 18 -->

Conditions (D.4) and (D.5) impose that a particular characteristic e i determines both baseline heterogeneity a i and treatment effects b it , but the effect of e i on treatment effect may vary over time. Condition (D.6) imposes that treatment effects b it themselves do not enter the determination of treatment status, rather that this determination is based on e i only. Intuitively this last restriction most likely implies that the shocks ν t,i to treatment effect b it are unknown and unpredictable at the time of determination of treatment status, so that the main advantage of this extrapolation with time-varying treatment effects compared to the extrapolation discussed in the main text with time-constant treatment effects is that the effect of the one-dimensional term of unobserved heterogeneity e i on treatment effect b it , β 1 ,t , is allowed to vary over time.

Under (D.4)-(D.6), we obtain:


glyph[negationslash]

where we define α 0 ,t = β 0 ,a -β 0 ,t β 1 ,t and α 1 ,t = β 1 ,a β 1 ,t , which are well-defined if β 1 ,t = 0.

Under the CRC model with time-varying random coefficients (D.1) and the new extrapolation identifying assumption (D.7), the second step of our estimation procedure can still take the form of an instrumental variable regression of ˆ a i on ˆ b it using treatment status history { x i 1 , ..., x iT } as instrumental variables, but the estimation sample is now restricted to include only movers who are treated at time t . Because of this restriction in the sample that can be used for the second-step estimation, one must observe at least three time periods to observe several groups of movers who are treated at time t and be able to implement this estimation procedure. For instance with T = 2, the only group of movers treated at time t = 1 has treatment status history profile x = (1 , 0). With T = 3, movers treated at time t = 1 correspond to treatment status history profiles x ∈ { (1 , 0 , 0) , (1 , 1 , 0) , (1 , 0 , 1) } .


<!-- page 19 -->

ATE for untreated movers and stayers can then be identified from:


if α 1 ,t / ∈ {-1 , 0 } .

In practice, since identification relies on smaller groups of movers, the implementation of this approach may lead to estimation results that are significantly more imprecise than the results obtained when treatment effects are assumed to be time constant. In addition, the conditions (D.4)-(D.6) that lead to the extrapolation identifying assumption (D.7) are restrictive, even though we can note that they encompass the case when treatment effects are constant over time since we could then define e i = b i and ν t,i = 0.

In some applications, accounting for dynamic treatment effects, i.e. allowing for past treatment status to affect current treatment effect, is an important feature of the models used. This could be accommodated here by explicitly using an extrapolation identifying assumption that allows, for instance, the most recent treatment status to affect current treatment effect:


so that the difference in treatment effect at the time of the first exposure to treatment and one time period later is given by β 2 + β 3 e i .

Under (D.4), (D.6), and (D.9) we obtain the extrapolation identifying assumption:


where α 1 ,t ( x it -1 ) = β 1 ,a β 1 ,t + β 3 x it -1 and α 2 ,t ( x it -1 ) = -β 1 ,a β 2 β 1 ,t + β 3 x it -1 .

The parameters in this extrapolation identifying assumption can be estimated by an instrumental variable regression by conditioning on both possible values of x it -1 ∈ { 0 , 1 } ,

<!-- chunk 3: pages 21-30 -->


<!-- page 21 -->

with the models discussed in this section than with the models discussed in the main text. Not only more time periods need to be observed for identification, but identification of time effects in the CRC model and of the parameters in the extrapolation identifying assumption is obtained from much narrower subgroups of cross-sectional observations than in the main text. In practice this will imply that estimation results will be significantly more noisy than using the methods developed in the main text, and will require researchers to have access to larger datasets than what is used in the empirical application of the main text. It would be interesting to consider the extensions sketched in this section in more details in future work in applications that are more amenable to these methods.

## E Estimation and Inference with the Simple Extrapolation Identifying Assumption

In this section we discuss the details of estimation for models of the form:




Setting z it to be a set of indicator variables for each time period other than the first time period, i.e. z it = [1[ t = s ]] s =2 ,...,T , yields the special case:


which is the CRC model considered in the main text, where only time effects are included as control covariates and where the normalization f 1 = 0 has been applied.


<!-- page 22 -->

In general z it is a vector of controls that can include random variables. For notational simplicity we consider the case where z it is a scalar variable below, as all results extend in a straightforward way to multiple control covariates.

Weobserve cross-sectional observations i = 1 , ..., n over time periods t = 1 , ..., T . Throughout this appendix, we use an asymptotic framework where n is large and T is small. We also assume that observations are cross-sectionally independent for simplicity, all results extend in a straightforward way to many independent clusters as in the empirical application.

## Assumption 7. Observations are cross-sectionally independent.

Note that Assumption 7 is implied by Assumption 1 in the main text.

Stacking observations over time, we obtain:



The estimation method we discuss in this section is decomposed into two steps. The first step yields consistent estimates of the homogenous coefficients γ and noisy estimates of treatment effect b i and baseline heterogeneity a i for cross-sectional units that are movers, noisy estimates of baseline heterogeneity a i for untreated stayers, noisy estimates of total heterogeneity a i + b i for treated stayers. The second step yields consistent estimates of α 0 , α 1 , and noisy estimates of the values of { a i , b i } i =1 ,...,n that were missing from the first step, i.e. corresponding to untreated and treated stayers. We show that averaging the resulting noisy estimates of treatment effect b i across the entire population or large groups of stayers or movers yields consistent estimators of ATE.

## 
<!-- page 23 -->

E.1 Step 1: High-dimensional regression

The first step of our estimation procedure regresses y it on z it , indicator variables for each cross-sectional observation, and indicator variables for each cross-sectional observation interacted with x it . By the Frisch-Waugh theorem, the resulting estimates are given by:



where M W i = I T -W i ( W ′ i W i ) -W ′ i and ( W ′ i W i ) -is the generalized inverse obtained by omitting the interaction of the indicator variable corresponding to a particular cross-sectional observation with treatment status x it when this cross-sectional observation is a stayer, i.e. when there is no variation in x it over time across observations corresponding to this crosssectional observation.

The next assumption imposes restrictions on moments of the data.

## Assumption 8.

- a) The support of a i , b i , z it , u it is compact.

For constants C and c &gt; 0 :




Assumption 8.a is standard and imposed in this form for simplicity. It could easily be relaxed to higher moments of the random variables a i , b i , z it , u it being uniformly bounded. Assumption 8.b imposes that we observe a non-vanishing share of stayers in the data. Assumptions 8.c and 8.d impose that there is variation in covariates z it and transitory shocks u it over time. For instance z it and u it may not be time constant.


<!-- page 24 -->

Assumption 8.d requires that there be variation in covariates z it and transitory shocks u it over time among observations that are stayers instead of among all cross-sectional observations. This additional regularity condition is imposed for simplicity as it guarantees that the first-step estimator discussed in this section is not approximately linearly dependent of the part of the influence function of the second-step estimator which does not depend on the firststep estimator, which guarantees that the second-step estimator is at most √ n -consistent, i.e. is not super consistent.

Note that Assumption 8 is implied by Assumptions 1 and 2 in the main text for the special case where T = 2 and z it = 1[ t = 2].

Under the CRC model and Assumptions 7 and 8, the first step of our estimation procedure yields consistent estimates of the homogenous coefficients γ and noisy estimates of the two terms of unobserved heterogeneity a i and b i with estimation noise that can be decomposed into a part which vanishes as sample size increases and a part which is unrelated to sample size.

Proposition 4. Under (E.1) and Assumptions 7 and 8, as n →∞ while T remains fixed:


where A n,γ, 0 = 1 n ∑ n i =1 E ( Z ′ i M W i Z i ) , V n,γ, 0 = 1 n ∑ n i =1 V ar ( Z ′ i M W i U i ) .

glyph[negationslash]

For i = 1 , ..., n such that ∃ t, s s.t. x it = x is , we have:


where ζ ab,n = 1 √ n ∑ n i =1 Z ′ i M W i U i = O p (1) and max i =1 ,...,n | e i,n | = o p ( 1 √ n ) .

For i = 1 , ..., n such that x it = 0 ∀ t , we have:



<!-- page 25 -->

For i = 1 , ..., n such that x it = 1 ∀ t , we have:


Proposition 4 shows that the estimator for γ is √ n -consistent and asymptotically normal. It also shows that the estimation noise of the heterogeneity terms a i and b i is decomposed into idiosyncratic noise that would arise even if γ were known and vanishing noise originating from the estimation of γ which is dominated by a term of order 1 √ n .

Note that Proposition 1 in the main text is obtained as a special case of Proposition 4.

## E.2 Step 2: Instrumental Variable Regression and Extrapolation

In a second step, we consider estimation of the parameters α 0 and α 1 in the linear extrapolation to ATE for stayers by generalized method of moments (GMM) estimation of the coefficients in an instrumental variable regression using noisy estimates of a i (ˆ a i ) as the dependent variable, noisy estimates of b i ( ˆ b i ) as the explanatory variable, and treatment history X i as instrumental variables.

Let M n be the subset of cross-sectional observations that are movers, i.e.

glyph[negationslash]


Define S ⊆ { 1 , ..., T } to be one of the largest subsets of time periods such that the variables { x it } t ∈S are linearly independent among observations corresponding to movers in the data. When only two time periods are observed, i.e. T = 2, we have S = { 1 } or S = { 2 } since x i 1 = 1 -x i 2 among movers. In general when T &gt; 2 and if there are treated and untreated observations in all time periods, the entire vector of treatment status history X i will be included in the list of instrumental variables, i.e. S = { 1 , ..., T } . Define


<!-- page 26 -->

˜ X i =    1 [ x it ] t ∈S    to be the elements of the vector of treatment status history that are linearly independent among movers augmented with a constant.

The estimator for α 0 and α 1 in the extrapolation identifying assumption (E.2) that we consider in this section is:


where ˜ glyph[epsilon1] i are first-stage residuals obtained by a two-stage least squares regression of ˆ a i on ˆ b i using ˜ X i as instrumental variables. 3

As in the main text, given estimates of the parameters α 0 and α 1 , we obtain estimates of ATE for stayers, ATE S, 0 = ∑ i =1 ,...,n E (1[ x it =0 ∀ t ] b i ) ∑ i =1 ,...,n P ( x it =0 ∀ t ) and ATE S, 1 = ∑ i =1 ,...,n E (1[ x it =1 ∀ t ] b i ) ∑ i =1 ,...,n P ( x it =1 ∀ t ) , by a

3 Note that in this section we could have considered a two-stage least squares regression only instead of GMM estimation, i.e. we could have chosen Σ n = 1 n ∑ n i =1 ˜ X i ˜ X ′ i . This would also lead to a consistent and asymptotically normal estimator. We consider GMM estimation for a potential efficiency gain because of the heteroscedasticity in ˆ a i -α 0 -α 1 ˆ b i conditional on X i that is likely to exist because of measurement error. Indeed heteroscedasticity is likely to appear in the non-vanishing part of the estimation noise in the estimates ˆ a i and ˆ b i : Even if V ar ( glyph[epsilon1] i | X i ) = σ 2 glyph[epsilon1] , V ar ( U i | X i ) = σ 2 u I T , and Cov ( glyph[epsilon1] i , U i | X i ) = 0, we have:

glyph[negationslash]


in general.

In addition GMM estimation extends easily to estimating and performing statistical inference on additional parameters such as ATE among different subpopulations, to accounting for cross-sectional dependence when computing the weighting matrix, and to accommodating unbalanced panel data originating from missing data. We encounter these three issues in our empirical application.

Note also that one could use interactions between elements of X i to obtain additional valid moment functions. We only consider moment functions obtained by using linear terms for simplicity here and to avoid the proliferation of moment conditions. See for instance Newey and Windmeijer (2009) for a discussion of issues that arise with GMM estimation and many moment conditions.


<!-- page 27 -->

simple plug-in using the derivations in the main text:


Define


Define ˜ α 0 and ˜ α 1 to be the two-stage least squares regression estimators of α 0 and α 1 obtained by regressing ˆ a i on a constant and ˆ b i using ˜ X i as instrumental variables.

Define λ min to be the minimum eigenvalue of a matrix.

## Assumption 9. For constants C and c &gt; 0 :

- a) λ min (Σ n, 0 ) ≥ c , ∀ n ≥ C .


- c) ˜ α 0 p → α 0 and ˜ α 1 p → α 1 as n →∞ while T remains fixed.


Assumption 9.a requires that there be variation in X i among observations that correspond to movers. For instance with two time periods, i.e. T = 2, Assumption 9.a would be obtained by imposing i) V ar ( v i | X i ) ≥ c &gt; 0 ∀ i = 1 , ..., n , ∀ n and ii) 0 &lt; c ≤ P ( x i 1 = 0 , x i 2 = 1) ≤ 1 -c and 0 &lt; c ≤ P ( x i 1 = 1 , x i 2 = 0) ≤ 1 -c ∀ i = 1 , ..., n , ∀ n . The first condition is standard and requires that the error terms of the CRC model u it and of the extrapolation identifying assumption have positive variance, so that the resulting model is not degenerate.


<!-- page 28 -->

The second condition guarantees that two different profiles of movers are represented by non-vanishing fractions of the data (in large samples), so that there is variation in x i 1 (or x i 2 ) among observations that are movers.

Assumption 9.b requires that the variation in X i among observations that correspond to movers be predictive of treatment effect b i . For instance with two time periods Assumption 9.b would be obtained by | ∑ i =1 ,...,n E (1[( x i 1 ,x i 2 )=(0 , 1)] b i ) ∑ i =1 ,...,n P (( x i 1 ,x i 2 )=(0 , 1)) -∑ i =1 ,...,n E (1[( x i 1 ,x i 2 )=(1 , 0)] b i ) ∑ i =1 ,...,n P (( x i 1 ,x i 2 )=(1 , 0)) | ≥ c &gt; 0 ∀ n ≥ C .

Assumption 9.c requires that the two-stage least squares estimators of α 0 and α 1 be consistent. This is imposed for convenience only since convergence in probability of the two-stage least squares estimators of α 0 and α 1 can be derived from primitive conditions as in the proof of Proposition 5 below.

Assumption 9.d is a regularity condition which guarantees that the estimator for ATE is at most √ n -consistent, i.e. is not super consistent. It requires that there be no approximately exact dependence between the terms of unobserved heterogeneity a i and a i + b i and the error term of the CRC model u it . This condition for the case x it = 0 ∀ t would be obtained if we assume that i) a i is independent of { u it } t =1 ,...,T conditional on Z i and W i and that ii) V ar ( 1 T ∑ T t =1 u it |{ u is -1 T ∑ T t =1 u it } s =1 ,...,T , Z i , x it = 0 ∀ t ) ≥ c . These are both natural conditions requiring that the idiosyncratic shocks to outcomes u it be independent of baseline heterogeneity a i and that the error term in the CRC model u it not be degenerate. Similarly this condition for the case x it = 1 ∀ t would be obtained if we assume that i) a i + b i is independent of { u it } t =1 ,...,T conditional on Z i and W i and that ii) V ar ( 1 T ∑ T t =1 u it |{ u is -1 T ∑ T t =1 u it } s =1 ,...,T , Z i , x it = 1 ∀ t ) ≥ c .

Note that Assumption 9.a, 9.b, and 9.d are implied by Assumptions 1-3 in the main text and Assumption 9.c is irrelevant with two time periods since the moment conditions E ( ˜ X i (ˆ a i -α 0 -α 1 ˆ b i )) glyph[similarequal] 0 are exactly identifying for the parameters α 0 and α 1 in this case.

To state Proposition , we define deterministic matrices which will determine the asymp-


<!-- page 29 -->

totic distribution of our second-step estimators    ˆ α 0 ˆ α 1    :


We define deterministic matrices which will determine the asymptotic distribution of our second-step estimators ˆ ATE S, 0 :


We define deterministic matrices which will determine the asymptotic distribution of our

<!-- chunk 4: pages 31-40 -->


<!-- page 31 -->

If in addition α 1 / ∈ { 0 , -1 } , then we have:


and:


Note that Proposition 2 in the main text is obtained as a special case of Proposition 5.

Proposition 5 shows that the estimators    ˆ α 0 ˆ α 1    , ˆ ATE S, 1 , and ˆ ATE S, 0 adopt a linear influence function asymptotic representation, so that inference by cluster bootstrap, with clusters given by cross-sectional units, would be asymptotically valid (see e.g. Mammen (1992)). Alternatively, one can use the analytical formula for asymptotic variance to obtain consistent estimated variance-covariance matrix using cluster robust standard errors for twostep estimation, with clusters given by cross-sectional units.

For simplicity the next proposition shows that these standard errors are consistent and lead to asymptotically valid inference for the estimator    ˆ α 0 ˆ α 1    only, since the same result can be obtained for the estimators ˆ ATE S, 1 and ˆ ATE S, 0 .

Proposition 6. Define C n = 1 n ∑ i ∈ M n ˜ X i [1 , -ˆ α 1 ]( W ′ i W i ) -1 W ′ i Z i , ˆ r i = ˆ a i -ˆ α 0 -ˆ α 1 ˆ b i , and ˆ U i = Y i -Z i ˆ γ . Define Σ n = 1 n ∑ i ∈ M n ˆ r 2 i ˜ X i ˜ X ′ i , Σ n,γ = 1 n ∑ i =1 ,...,n Z ′ i M W i ˆ U i ˆ U ′ i M W i Z i , Σ n,αγ =



<!-- page 32 -->

Under (E.1), (E.2), and Assumptions 7-9, as n →∞ while T remains fixed:


Since the matrices used in Proposition 6 are stored by standard statistical software, variance-covariance matrices using the formula given by Proposition 6 are straightforward to compute.

Additionally, note that all estimators above can be computed as the solution to exactly identifying moment conditions:


so that, instead of using the formulae from Proposition 6 to compute standard errors, analytical standard errors can also be obtained directly using any command capable of numerical differentiation in standard statistical software.

## 
<!-- page 33 -->

E.3 Testing the Validity of the Extrapolation

## E.3.1 Lack of testable implications with two time periods

As discussed in the main text, under the CRC model ( ?? ) and with two time periods, the extrapolation identifying assumption ( ?? ) is equivalent to introducing identities for four parameters that were left unrestricted by the CRC model, so that the extrapolation identifying assumption does not contain testable implications under the CRC model.

We can see this directly by considering the CRC model:


glyph[negationslash]

and defining α glyph[star] 1 = E ( a i | 0 , 1) -E ( a i | 1 , 0) E ( b i | 0 , 1) -E ( b i | 1 , 0) and α glyph[star] 0 = E ( a i | 0 , 1) -α glyph[star] 1 E ( b i | 0 , 1) if E ( b i | 0 , 1) = E ( b i | 1 , 0).

glyph[negationslash]

glyph[negationslash]

For i such that x i 1 = x i 2 , define ˜ a i = a i and ˜ b i = b i . For i such that x i 1 = 0 and x i 2 = 0, define ˜ b i = a i -α glyph[star] 0 α glyph[star] 1 if α glyph[star] 1 = 0. For i such that x i 1 = 1 and x i 2 = 1, define ˜ b i = a i + b i -α glyph[star] 0 1+ α glyph[star] 1 and ˜ a i = α glyph[star] 0 + α glyph[star] 1 ˜ b i if α glyph[star] 1 = -1.

Then we can write:


and


glyph[negationslash]

since ˜ ξ i = 0 when x i 1 = x i 2 and E ( ˜ ξ i | x i 1 , x i 2 ) = 0 when x i 1 = x i 2 .

## E.3.2 Testing with three or more time periods

The extrapolation identifying assumption (E.2) implies that


glyph[negationslash]


<!-- page 34 -->

Here we propose testing an implication of this assumption, namely LP ( a i -α 0 -α 1 b i | X i , i ∈ M n ) = 0, where LP is the linear projection operator, and recall that M n is the subset of cross-sectional observations that are movers. This condition is equivalently written:



where recall that S is one of the largest subsets of time periods such that the variables { x it } t ∈S are linearly independent among observations corresponding to movers in the data. When only two time periods are observed, i.e. T = 2, we have S = { 1 } or S = { 2 } , while in general S = { 1 , ..., T } when T ≥ 3.

With a very large number of cross-sectional observations, testing (E.10) directly would generally yield a test with larger power, similarly as in the previous section where using interactions of the elements of X i would lead to more moment conditions and to a more efficient estimator in general when a large number of cross-sectional observations is available. However with more modest sample sizes, it is possible that some values of X i correspond to relatively few cross-sectional observations, leading to a 'small cell' problem, i.e. it is possible that E ( a i -α 0 -α 1 b i | X i ) can only be estimated imprecisely for some values of X i . This could lead to size distortions in small samples. We propose a more parsimonious test based on (E.11) and (E.12) instead.

This test is straightforward given the discussion in the previous section as long as three or more time periods are observed. We simply add |S| +1 exactly identified moment conditions:


and test the null hypothesis H 0 : η 0 = 0 , η t = 0 ∀ t ∈ S using a Wald test with critical values from a chi-squared distribution with |S| 1 degrees of freedom. Note that when T = 2,


<!-- page 35 -->

|S| = 1 so that this test cannot be performed, as discussed in the main text and above.

Estimated variances for this Wald test can be obtained by cluster bootstrap, or using analytical formulae as in Proposition 6, or by solving for exactly identifying moment conditions using any command capable of numerical differentiation in standard statistical software.

This is an over-identification test similar to the Sargan-Hansen J-test discussed in Hansen (1982) except that it accounts for the first-step estimation of the coefficients γ .

## F Estimation and Inference with the Generalized Extrapolation Identifying Assumption

In this section we discuss how to extend the estimation and testing methods discussed in the previous section to the use of a generalized extrapolation where cost shifters shared by all observations with the same value of indexing variable v i can be correlated with productivity ( a i , b i ). The model considered in this section is given by:



where all variables are defined as in the previous section, and v i is a deterministic discrete indexing variable. 4 In our empirical example v i indexes farmer i 's village.

The same first-step estimator of γ is used as in the previous section. As before, it also leads to noisy estimates of baseline heterogeneity and treatment effects, ˆ a i and ˆ b i , for movers, noisy estimates of baseline heterogeneity for untreated stayers, and noisy estimates of total heterogeneity for treated stayers.

4 Note that here the exogeneity of covariates X i and Z i in the CRC model (F.1) has been strengthened to be strict across all observations with the same value of the indexing variable v i . This is because the assumption of independence is relaxed below so that observations are only assumed to be independent across different values of the indexing variable v i instead of being independent cross-sectionally. If the assumption of cross-sectional independence held, the assumptions of exogeneity in (F.1) could be relaxed to E ( u it | X i , Z i ) = 0 as before.


<!-- page 36 -->

The coefficient α 1 is then estimated by GMM estimation after demeaning the noisy estimates of a i and b i obtained for movers in the first stage within the groups defined by each value of the indexing variable v i :



where n v = |{ i ∈ M n : v i = v }| . In our empirical example, this amounts to demeaning among movers within each village.

As before, define S to be one of the largest sets of time periods such that [ x it ] t ∈S is a set of linearly independent variables in the data among observations that correspond to movers, in order to accommodate the case where T = 2. Redefine ˜ X i = [ x it ] t ∈S to be as in the previous section but without the constant. Then the estimator of α 1 in this section is given by:


and ˜ α 1 is the first-step estimator of α 1 obtained by a fixed effects two-stage least squares regression of ˆ a i on ˆ b i using ˜ X i as instrumental variable and with fixed effects indexed by v i .

Given this estimator of α 1 , we obtain a noisy estimator of the 'fixed effect' term e v in


<!-- page 37 -->

the generalized extrapolation assumption (F.2):


Estimators of ATE for stayers are then defined in this section by:


Here we consider the case where there are few cross-sectional observations per value of the indexing variable v i , so that the indexing variable v i takes many values. As discussed in the main text, this corresponds to the data structure of our application where few farmers live in each village. Considering the case where v i takes few values and where there are many crosssectional observations per value of v i is straightforward with cross-sectional independence or limited forms of cross-sectional dependence.

With v i taking many values, Assumption 1 of cross-sectional independence can be relaxed to independence across values of v i . Define N v = |{ i = 1 , ..., n : v i = v }| to be the number of cross-sectional observations with value v of the indexing variable v i .

Assumption 10. Observations are independent if they do not share the same value of the indexing variable v i and the number of observations per group is uniformly bounded, i.e. max i =1 ,...,n N v i ≤ C ∀ n for a constant C .

Note that Assumption 10 is implied by Assumption 4 in the main text.

Similarly as before, the new estimator of α 1 defined above and the estimators of ATE for stayers will be consistent and asymptotically normal if conditions hold on second moments


<!-- page 38 -->

of the data. Define:


Assumption 11. For constants C and c &gt; 0 :



Assumption 11.a requires that there be within-group variation in X i among movers since we can rewrite ¨ Σ n, 0 = 1 n ∑ i ∈ M n ,j ∈ M n : v j = v i E ( r i r j ˙ X i ˙ X ′ j ) where ˙ X i = ˜ X i -1 n v i ∑ j ∈ M n ,v j = v i ˜ X j . Define N to be the number of values taken by v i . Under Assumption 10, note that N is of the same order as n . With two time periods, Assumption 11.a is implied by i) V ar ( r i |{ X j } j : v j = v i ) ≥ c &gt; 0 ∀ i = 1 , ..., n , ∀ n , ii) Cov ( r i , r j |{ X i ′ } i ′ : v i ′ = v i ) = 0 ∀ i = 1 , ..., n ,

<!-- chunk 5: pages 41-50 -->


<!-- page 41 -->

second-step estimators ˆ ATE S, 0 :


Define the deterministic matrices which will determine the asymptotic distribution of our


<!-- page 42 -->

second-step estimators ˆ ATE S, 1 :


Proposition 7. Under (F.1), (F.2) and Assumptions 8, 10, and 11, as n → ∞ while T remains fixed:

and:




<!-- page 43 -->

If in addition α 1 / ∈ { 0 , -1 } , then we have:


and:


Note that Proposition 3 in the main text is obtained as a special case of Proposition 7.

Proposition 7 shows that the second stage estimators of α 1 and of ATE for stayers have a linear influence function asymptotic representation, so that as before consistent variance estimation could be obtained by bootstrap resampling, although here resampling should be clustered at the level of the indexing variable v i . Alternatively, one can also use analytical standard errors for inference, although these standard errors should now be clustered at the level of the indexing variable v i . As before, we only show consistency of the analytical standard errors for ˆ α 1 here, as the same result for ATE of stayers is obtained in a similar way.




<!-- page 44 -->

Under (F.1), (F.2) and Assumptions 8, 10, and 11, as n →∞ while T remains fixed:


As in the previous section, this proposition shows that asymptotically valid inference for α 1 can be based on Wald tests with analytical standard errors clustered at the level of the indexing variable v i which account for both steps of estimation.

As in the previous section, the estimators defined above and consistent standard errors can also be obtained by solving for exactly identifying moment conditions using any command capable of numerical differentiation in standard statistical software.

As in the previous section, we can test the extrapolation identifying assumption (F.2) by including additional exactly identifying moment conditions:


and testing the null hypothesis H 0 : η t = 0 ∀ t ∈ S using a Wald test with critical values from a chi-squared distribution with |S| 1 degrees of freedom.

## G Estimation and Inference with Unbalanced Panels

Many panel datasets available in empirical work are unbalanced, i.e. some cross-sectional observations are only observed for a subset of the time periods t = 1 , ..., T . In this section we briefly discuss the consequences of missing data if one assumes that observations are missing at random, i.e. that whether an observation ( i, t ) is observed are not is independent of all of the variables included in our model.


<!-- page 45 -->

glyph[negationslash]

Let o it = 1[ observation ( i, t ) is observed ]. Redefine Y i = [ y it ] t : o it =1 , W i = [1 , x it ] t : o it =1 , Z i = [ z it ] t : o it =1 , X i = [ x it ] t : o it =1 . Redefine M n to be the set of cross-sectional observations that have a change in treatment status across the time periods for which observations are observed, i.e. M n = { i = 1 , ..., n : ∃ t, s with x it = x is , o it = 1 , o is = 1 } . With data missing at random, under the model used in Section B given by (E.1) and (E.2), we have:


so that γ can be estimated by a linear regression of y it on indicator variables for each crosssectional observation, these indicator variables interacted with treatment status, and z it , pooling over all observations that are observed.

We also have:


so that the parameters α 1 and α 0 can be estimated by GMM as in Section B, pooling over observations that are observed for each moment condition separately for each time period t .

Similarly testing the validity of the extrapolation identifying assumption and performing asymptotically valid inference for objects of interest such as ATE for untreated stayers can be obtained by relying on GMM estimation and pooling across all observations that are observed separately for each moment condition.

The same results apply to the use of the generalized extrapolation identifying assumption discussed in Section C.

## 
<!-- page 46 -->

H Proofs

## H.1 Proof of Proposition 1

Recall the normalization ˆ f 1 = 0 and the definition in the main text:


where the second equality follows from the normalization f 1 = 0 and the CRC model ( ?? ).

By convergence in mean-square error and Assumption 1 we have:


where π S was defined in the main text to be π S = P ( x i 1 = x i 2 ).

Note that by the law of total variance and the CRC model ( ?? ) we have:


where the main text defined σ 2 ∆ u,S = V ar (∆ u i 2 | x i 1 = x i 2 ). Therefore we have V ar (1[ x i 1 = x i 2 ]∆ u i 2 ) &gt; 0 under Assumption 2.b and 2.c.

Assumption 2.a of bounded support implies that 1[ x i 1 = x i 2 ]∆ u i 2 has bounded support. Therefore by the Lindeberg-Levy central limit theorem for i.i.d. observations, we have:


Therefore by Slutsky's theorem, since π S &gt; 0 by Assumption 2.b, we have:


This establishes the first result of Proposition 1.


<!-- page 47 -->

By definition, we have:


where as discussed above these estimators are both well-defined only for cross-sectional observations that are movers.

For all cross-sectional observations such that ˆ a i is well-defined (movers and untreated stayers), we can write:


where the first equality follows from the normalizations f 1 = ˆ f 1 = 0 and the second equality follows from the CRC model ( ?? ).

The first result of this proposition shows that ˆ f 2 -f 2 = O p ( 1 √ n ), and we have (1 -x i 2 ) ∈ { 0 , 1 } and ∑ i =1 , 2 (1 -x it ) ∈ { 1 , 2 } for movers and untreated stayers.

Therefore defining ζ a,i,n = (1 -x i 2 ) ( ˆ f 2 -f 2 ) ∑ i =1 , 2 (1 -x it ) we obtain max i =1 ,...,n : x i 1 =0or x i 2 =0 | ζ a,i,n | = O p ( 1 √ n ).

Similarly we have for movers and treated stayers:


and defining ζ a + b,i,n = x i 2 ( ˆ f 2 -f 2 ) ∑ i =1 , 2 x it we obtain max i =1 ,...,n : x i 1 =1or x i 2 =1 | ζ a + b,i,n | = O p ( 1 √ n ), which completes the proof of this proposition.

## H.2 Proof of Proposition 2

Linear influence function representation for ˆ α 0 and ˆ α 1 .



<!-- page 48 -->

The extrapolation identifying assumption ( ?? ) and Proposition 1 imply:


where ζ i,n = ζ a,i,n -α 1 ζ b,i,n and ζ b,i,n = ζ a + b,i,n -ζ a,i,n and r i is defined in the main text as r i = glyph[epsilon1] i + ∑ t =1 , 2 u it ((1 + α 1 )(1 -x it ) -α 1 x it ).

Therefore we have:



From Proposition 1, for cross-sectional observations that are movers:


By convergence in mean-squared error:

<!-- chunk 6: pages 51-60 -->


<!-- page 51 -->

(Assumption 3.a).

Therefore | Corr (1[ x i 1 = x i 2 ] r i , 1[ x i 1 = 0 , x i 2 = 1] r i ) | &lt; 1, so that:


where λ min denotes the smallest eigenvalue of a matrix.

Therefore all conditions (bounded support, positive variance, i.i.d.) are met for the Lindeberg-Levy central limit theorem to apply:


so that we obtain by Slutsky's theorem:


where V α = A -1 0 [ I 2 , c 0 ] V ar ( w i )    I 2 c ′ 0    A -1 ′ 0 .

Linear influence function representation and asymptotic normality of ˆ ATE S, 0 and ˆ ATE S, 1

By definition:


glyph[negationslash]


<!-- page 52 -->

Define ˜ a i = a i + 1 2 ∑ t =1 , 2 u it and define:


glyph[negationslash]


glyph[negationslash]

where w i was defined above as w i

As before, the variance of w i is positive definite. In addition Assumption 1 implies that 1[ x i 1 = x i 2 = 0](˜ a i -E ( a i | 0 , 0)) is uncorrelated with 1[ x i 1 = x i 2 ] r i and 1[ x i 1 = 0 , x i 2 = 1] r i .

Assumption 3.c implies that V ar (˜ a i | ∆ u i 2 , 0 , 0) &gt; 0, so that | Corr (1[ x i 1 = x i 2 = 0](˜ a i -E ( a i | 0 , 0)) , 1[ x i 1 = x i 2 ]∆ u i 2 ) | &lt; 1.

Therefore λ min V ar ( w ATE,i ) &gt; 0. In addition Assumption 2.a guarantees that w ATE,i has bounded support.

Therefore by the Lindeberg-Levy central limit theorem we have:


Therefore since ATE S, 0 = E ( a i | 0 , 0) -α 0 α 1 , by the δ -method we obtain:


where A ATE, 0 = [ 1 α 1 , -1 α 1 , -ATE S, 0 α 1 ] B ATE, 0 and B ATE, 0 =    1 π 00 0 ′ 2 -1 π 00 1 2 1 π S 0 2 A -1 0 A -1 0 c 0    where 0 2 is a 2 × 1 vector of zeros and A 0 , c 0 are defined above.

The same steps can be used for ˆ ATE S, 1 , which completes the proof of Proposition 2.

## 
<!-- page 53 -->

H.3 Definitions and Lemma for the Proof of Proposition 3

The first step of our estimation procedure is unchanged when estimating ATE under the generalized extrapolation identifying assumption (3.7). We first establish the same result for these first step estimators as Proposition 1 but under Assumptions 4 and 5.

Recall the redefinition in the main text of σ 2 ∆ u,S to σ 2 ∆ u,S = V ar ( ∑ i : v i = v,x i 1 = x i 2 ∆ u i 2 ). Also redefine π S = E ( ∑ i : v i = v 1[ x i 1 = x i 2 ]).

Lemma 1. Under the CRC model ( ?? ) and Assumptions 4 and 5, as N →∞ :


and wherever ˆ a i and ˆ a i + ˆ b i are well-defined we can write:


where max i =1 ,...,n : x i 1 =0 or x i 2 =0 | ζ a,i,N | = O p ( 1 √ N ) and max i =1 ,...,n : x i 1 =1 or x i 2 =1 | ζ a + b,i,N | = O p ( 1 √ N ) .

Proof. As in the proof of Proposition 1, we have:


Under Assumption 4, convergence in mean-squared error implies:


and Assumption 2.b implies π S &gt; 0.

Assumption 4 and Assumption 2.a imply that ∑ i : v i = v,x i 1 = x i 2 ∆ u i 2 is i.i.d. across v with bounded support. Assumption 5 implies V ar ( ∑ i : v i = v,x i 1 = x i 2 ∆ u i 2 ) = σ 2 ∆ u,S &gt; 0. Therefore by the continuous mapping theorem, Slutsky's theorem, and the Lindeberg-Levy central limit


<!-- page 54 -->

theorem, we have:


Given this result, the rest of the proof of Lemma 1 is as in the proof of Proposition 1.

Here we also define explicitly the second-step estimator for α 1 used with the generalized extrapolation identifying assumption (3.7). A fixed effects instrumental variable regression of ˆ a i on ˆ b i using x i 2 as an instrumental variable, with fixed effects indexed by v i , yields the estimator:



The estimated fixed effects are given by:


## H.4 Proof of Proposition 3

From the CRC model ( ?? ), the generalized extrapolation identifying assumption (3.7), and Lemma 1:


where


<!-- page 55 -->

where as before r i = glyph[epsilon1] i + ∑ t =1 , 2 u it ((1 + α 1 )(1 -x it ) -α 1 x it ) and ζ i,n = (1+ α 1 )(1 -x i 2 )( ˆ f 2 -f 2 ) -α 1 x i 2 ( ˆ f 2 -f 2 ).

Therefore we have:


where ˙ r i = r i -1 n v i ∑ j ∈ M n : v j = v i r j and ˙ ζ i,n = ζ i,n -1 n v i ∑ j ∈ M n : v j = v i ζ j,n .

Considering the denominator, we have:


where n v,x 1 x 2 = |{ i = 1 , ..., n : v i = v, x i 1 = x 1 , x i 2 = x 2 }| .

Under Assumption 4 we have n v, 01 n v, 10 n v ≤ C . From Lemma 1 we therefore have:


and convergence in mean-squared error implies:


glyph[negationslash]

Define ∆ b = E ( n v, 01 n v, 10 n v ( b 01 ,v -b 10 ,v )). We have ∆ b = 0 since n v, 01 n v, 10 n v ≥ 0, n v, 01 n v, 10 n v ≥ c with positive probability under Assumptions 6.a and 4, n v, 01 n v, 10 n v has discrete support under Assumption 4, and b 01 ,v -b 10 ,v &gt; 0 whenever n v, 01 n v, 10 n v &gt; 0 or b 01 ,v -b 10 ,v &lt; 0 whenever

n v, 01 n v, 10 n v &gt; 0 under Assumption 6.c.

Convergence in mean-squared error and Lemma 1 imply:


where c 0 = E ( ∑ i ∈ M n : v i = v x i 2 ((1 + α 1 )(1 -˙ x i 2 ) -α 1 ˙ x i 2 )), ˙ x i 2 = x i 2 -1 n v i ∑ j ∈ M n : v j = v i x j 2 . Define w v =    ∑ i ∈ M n : v i = v x i 2 ˙ r i ∑ i : v i = v,x i 1 = x i 2 ∆ u i 2    . E ( w v ) = 0 under the CRC model and the generalized extrapolation identifying assumption. Assumption 6.d imposes that λ min ( V ar ( w v )) &gt; 0. w v has bounded support under Assumption 2.a.

Therefore under Assumption 4, the continuous mapping theorem, Slutsky's theorem, and the Lindeberg-Levy central limit theorem imply:


where V α = A α, 0 V ar ( w v ) A ′ α, 0 and A α, 0 = 1 ∆ b [1 , c 0 1 π S ].

By definition:


Redefine π 00 = E ( ∑ i : v i = v 1[ x i 1 = x i 2 = 0]), note that Assumption 6.d implies π 00 &gt; 0. By convergence in mean-squared error we obtain:



<!-- page 57 -->

By convergence in mean-squared error and the previous results, we can also write:


where


Therefore by the δ -method we have:





<!-- page 58 -->

where ˜ u i was defined in the main text to be ˜ u i = 1 2 ∑ T t =1 u it -1 n v i ∑ j ∈ M n : v j = v i r j and w v is defined above.

Bounded support, Assumption 6.d, and Assumption 4 lead to the applicability of the Lindeberg-Levy central limit theorem, so that:


where V ATE = A ATE, 0 V ar ( w ATE 0 ,v ) A ′ ATE, 0 .

This completes the proof of this proposition since the same steps can be used to derive the asymptotic normality of the estimator of ATE for treated stayers, ˆ ATE S, 1 .

## H.5 Proof of Proposition 4

The choice of generalized inverse used here (excluding the interaction between the crosssectional indicator variables and treatment status for stayers) implies:


where ¯ z 0 it = ∑ t (1 -x it ) z it ∑ t (1 -x it ) and ¯ z 1 it = ∑ t x it z it ∑ t x it , and ( W ′ i W i ) -W ′ i U i has a similar representation.

Therefore under Assumption 8.a: Z ′ i M W i Z i , Z ′ i M W i U i , ( W ′ i W i ) -W ′ i Z i and ( W ′ i W i ) -W ′ i U i have bounded support.

The definition of the estimator and (E.3) implies:


Under Assumption 7, Z ′ i M W i Z i and Z ′ i M W i U i are cross-sectionally independent.

<!-- chunk 7: pages 61-67 -->


<!-- page 61 -->

where the last equality follows from Proposition 4.

As in the proof of Proposition 4, ˜ X i [1 , b i + [0 , 1]( W ′ i W i ) -1 W ′ i U i ] has bounded support under Assumption 8.a, so that by convergence in mean-squared error:


By definition of Σ n :


From Assumption 9.c, Proposition 4, and Assumption 8.a:




Therefore:


<!-- page 62 -->

As previously, under Assumptions 7 and 8.a, convergence in mean squared error implies:


Therefore under Assumptions 9.a and 9.b, by the continuous mapping theorem and Proposition 4, we have:


which completes the proof of the first result of Proposition 5.

With the first result of Proposition 5 established, the second result can be obtained by using a central limit theorem for independent observations. To apply this central limit theorem, we show that higher moments of the linear influence function for    ˆ α 0 ˆ α 1    are bounded and that the variance of the linear influence function is uniformly positive-definite.

From Assumptions 8.a, 9.a, and 9.b, we have that the support of ( B ′ n, 0 Σ -1 n, 0 B n, 0 ) -1 B ′ n, 0 Σ -1 n, 0 ˜ X i r i is bounded.

From Assumptions 8.a, 9.a, 9.b, and 8.c, we have that the support of


is bounded.

Assumption 7 of cross-sectional independence, Assumption 8.b that a non-vanishing share of the population be stayers, and Assumptions 8.d and 9.a imply that λ min (Ω n, 0 ) ≥ c .


<!-- page 63 -->

Therefore λ min ( V n, 0 ) ≥ c as long as:


which follows from λ min ( B ′ n, 0 Σ -1 n, 0 B n, 0 ) -1 ≥ c , which itself follows from λ min ( B ′ n, 0 Σ -1 n, 0 B n, 0 ) -1 = 1 λ max ( B ′ n, 0 Σ -1 n, 0 B n, 0 ) , and λ max Σ -1 n, 0 = 1 λ min Σ n, 0 ≤ C by Assumption 9.a, and λ max ( B ′ n, 0 B n, 0 ) ≤ C by Assumption 8.a.

Therefore all conditions are met to use a central limit theorem for independent observations such as Theorem 5.11 in White (2001), and we have:


which completes the proof of the second result of Proposition 5.

We can show that the estimators of ATE for stayers, ˆ ATE S, 0 and ˆ ATE S, 1 , have a linear influence function representation using similar steps as above. Under the assumptions of this proposition we have:


For concision we concentrate on ˆ ATE S, 0 in the remainder of this proof since the asymptotic normality of ˆ ATE S, 1 is derived in the same way.


<!-- page 64 -->

As above, A n,ATE s, 0 , 0       ∑ i : x it =0 ∀ t ˜ a i ∑ i =1 ,...,n P ( x it =0 ∀ t ) 1 n ∑ n i =1 Z ′ i M W i U i 1 n ∑ i ∈ M n ˜ X i r i       has bounded support under the assumptions of this proposition, so that we can apply a central limit theorem for independent observations


Assumptions 8.d, 9.a, and 9.d impose that the variance of each term in √ n       ∑ i : x it =0 ∀ t ˜ a i ∑ i =1 ,...,n P ( x it =0 ∀ t ) 1 n ∑ n i =1 Z ′ i M W i U i 1 n ∑ i ∈ M n ˜ X i r i       is uniformly positive definite.

As above, Assumptions 7, 8.b, and 8.d guarantee that 1 n ∑ n i =1 Z ′ i M W i U i and 1 n ∑ i ∈ M n ˜ X i r i are not approximately linearly dependent.

Assumption 7 of cross-sectional independence guarantees that ∑ i : x it =0 ∀ t ˜ a i ∑ i =1 ,...,n P ( x it =0 ∀ t ) and 1 n ∑ i ∈ M n ˜ X i r i are independent.

Assumption 9.d guarantees that ∑ i : x it =0 ∀ t ˜ a i ∑ i =1 ,...,n P ( x it =0 ∀ t ) and 1 n ∑ n i =1 Z ′ i M W i U i are not approximately linearly dependent.

Therefore we have λ min V ar ( √ n       ∑ i : x it =0 ∀ t ˜ a i ∑ i =1 ,...,n P ( x it =0 ∀ t ) 1 n ∑ n i =1 Z ′ i M W i U i 1 n ∑ i ∈ M n ˜ X i r i       ) ≥ c &gt; 0 ∀ n ≥ C and applying a central limit theorem for independent observations such as Theorem 5.11 in White (2001) we obtain:


## 
<!-- page 65 -->

H.7 Proof of Proposition 6

As in the proofs of Propositions 4 and 5, convergence in mean-squared error and the continuous mapping theorem imply:


so that Slutsky's theorem implies:


## H.8 Proof of Proposition 7

The proof of this proposition follows the same steps as the proof of Proposition 5 albeit with different definitions and dependence being indexed by v i rather than i .

## H.9 Proof of Proposition 8

The proof of this proposition follows the same steps as the proof of Proposition 6 albeit with different definitions and dependence being indexed by v i rather than i .

## I Learning and the Extrapolation Identifying Assumption

In this section we briefly discuss the possibility that farmers in our empirical application do not know exactly what their returns are prior to adopting hybrid seeds for the first time, and learn about their returns as they use the technology. Learning could create a feedback from past shocks to productivity, u is ∀ s &lt; t , to current technology use, x it , if positive (negative)


<!-- page 66 -->

shocks to productivity while using hybrid seeds are misinterpreted as high (low) returns to using hybrid seeds, invalidating the CRC model (2.4) used in the first step of our estimation approach.

If farmers learn directly about their returns, without confounding their adoption of the new technology with past productivity shocks, learning may not invalidate the extrapolation assumption (2.11). Suppose for simplicity that immediate learning takes place, where before her first adoption, a farmer bases her decision on whether to use hybrid seeds on the rule x it = 1[ ˜ b i ≥ c it ] where ˜ b i = b i + ς i , where ς i is measurement error, and c it is the cost of using hybrid seeds, while after having used hybrid seeds at least once she bases her decision on the rule x it = 1[ b i ≥ c it ]. If ς i and c it are independent of a i and b i , this model of selection satisfies the condition (2.15) discussed in section 2.4 in the main text.

More generally, a farmer may base her selection decision on an information set, I it , and the selection rule x it = 1[ E ( b i |I it ) ≥ c it ], as in D'Haultfœuille and Maurel (2013) and references therein. If I it and c it are independent of a i conditional on b i , then the extrapolation identifying assumption (2.11) holds (if the assumption of linearity (2.14) also holds). In section 4.3 in the main text, we allow for part of a farmer's information set to be correlated with her baseline productivity a i or returns b i as long as it corresponds to information that is shared by all farmers in a village.

## References

- Abbring, J. H. and J. J. Heckman (2007): 'Chapter 72 Econometric Evaluation of Social Programs, Part III: Distributional Treatment Effects, Dynamic Treatment Effects, Dynamic Discrete Choice, and General Equilibrium Policy Evaluation,' in Handbook of Econometrics , ed. by J. J. Heckman and E. E. Leamer, Elsevier, vol. 6, 5145-5303.
- Carneiro, P., K. T. Hansen, and J. J. Heckman (2003): '2001 Lawrence R. Klein Lecture Estimating Distributions of Treatment Effects with an Application to the Re-


<!-- page 67 -->

turns to Schooling and Measurement of the Effects of Uncertainty on College Choice*,' International Economic Review , 44, 361-422.

- Chamberlain, G. (1992): 'Efficiency Bounds for Semiparametric Regression,' Econometrica , 60, 567-596.
- Cunha, F., J. Heckman, and S. Navarro (2005): 'The 2004 Hicks Lecture: Separating Uncertainty from Heterogeneity in Life Cycle Earnings,' Oxford Economic Papers , 57, 191-261.
- D'Haultfœuille, X. and A. Maurel (2013): 'Inference on an extended Roy model, with an application to schooling decisions in France,' Journal of Econometrics , 174, 95 106.
- Hansen, L. P. (1982): 'Large Sample Properties of Generalized Method of Moments Estimators,' Econometrica , 50, 1029-1054.
- Lemieux, T. (1998): 'Estimating the Effects of Unions on Wage Inequality in a Panel Data Model with Comparative Advantage and Nonrandom Selection,' Journal of Labor Economics , 16, 261-291.
- Mammen, E. (1992): When Does Bootstrap Work?: Asymptotic Results and Simulations , Lecture Notes in Statistics, New York: Springer-Verlag.
- Newey, W. K. and F. Windmeijer (2009): 'Generalized Method of Moments With Many Weak Moment Conditions,' Econometrica , 77, 687-719.
- Suri, T. (2011): 'Selection and Comparative Advantage in Technology Adoption,' Econometrica , 79, 159-209.
- White, H. (2001): Asymptotic theory for econometricians , San Diego: Academic Press.
