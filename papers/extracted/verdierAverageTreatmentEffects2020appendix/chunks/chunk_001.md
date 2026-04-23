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

