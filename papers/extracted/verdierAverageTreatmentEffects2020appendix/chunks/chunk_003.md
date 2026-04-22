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
