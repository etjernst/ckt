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

