## 2.5 Extrapolation in the Presence of Correlated Cost Shifters

In this section, we consider the case where the factors of selection into treatment other than treatment effects may be correlated with baseline heterogeneity or treatment effects, but where this correlation is due to factors of selection that originate from observed sources. For concision, we refer to factors of selection into treatment other than treatment effects as the cost of treatment in this section. We assume that the cost of treatment cit can be written as:

<!-- formula-not-decoded -->

where wi is observed while n it is unobserved. 21

19 An alternative sufficient condition for the extrapolation identifying assumption (2.11) to hold is ai = a 0 + a 1 bi + e i , E ( e i | bi , ci 1 , ..., ciT ) = 0, with xit = g ( bi , cit ) ∀ t . Intuitively this captures the same two restrictions of linearity and zero partial correlation between ai and { ci 1 , ..., ciT } after conditioning on bi .

20 In section 3.4, we show that the extrapolation identifying assumption (2.11) can at least be tested if three or more time periods are observed.

21 Note that wi may be a vector. For instance, we may have wi =[ wi 1 , ..., wiT ] , so that time-variation in the index for confounding cost shifters is allowed. Note that n it may also be a vector. In particular, n it may include indicator variables for each time period, 1 [ t = s ] ∀ s = 1 , ..., T , so that the equation above does not impose homogeneity over time.

<!-- chunk 2: pages 11-20 -->


<!-- page 11 -->



leads to an estimator for m ( wi ) from m ( wi ) = E ( ai | wi , xi 1 = xi 2 ) -a 1 E ( bi | wi , xi 1 = xi 2 ) . ATE for stayers would then be identified by E ( bi | 0 , 0 ) = E ( ai -m ( wi ) | 0 , 0 ) a 1 and E ( bi | 1 , 1 ) = E ( ai + bi -m ( wi ) | 1 , 1 ) 1 + a 1 , which follows from (2.18). The properties of the resulting estimators could be established using standard results, but they are not discussed in this paper. 22 Instead, in section 3.3 below we discuss in detail the case where wi is discrete but takes a number of values that is proportional to sample size, which is the case encountered in our empirical application and leads to a fixed effects estimation approach.

## 2.6 Model with Additional Control Covariates

The CRC model can be generalized to accommodate additional control covariates:


where Z = { zit } i = 1 ,..., n , t = 1 ,..., T collects all values of a vector of control covariates zit that may be random. When zit only include a set of indicator variables for each time period, i.e., zit =[ 1 [ t = s ]] s = 1 ,..., T , the model given by (2.20) reduces to the CRC model without additional control covariates given by (2.4).

When (2.20) includes a general set of control covariates, the results above are extended in a straightforward way. Considering the case where two time periods are observed for simplicity ( T = 2), the CRC model with control covariates (2.20) implies:


from which we see that g 0 is identified as long as there is variation over time in the covariates zit . Given g 0, average baseline heterogeneity and average total heterogeneity are identified as before. For instance, for crosssectional observations that switch into treatment we have E ( ai | 0 , 1 ) = E ( yi 1 -zi 1 g 0 | 0 , 1 ) and E ( bi | 0 , 1 ) = E ( D yi 2 -D zi 2 g 0 | 0 , 1 ) . Therefore, the extrapolation based on the simple 
<!-- page 12 -->

extrapolation identifying assumption (2.11) can be defined as above. One can also condition on confounding cost shifters and base extrapolation on the generalized extrapolation identifying assumption (2.18).

On the other hand, Lemieux (1998) and Suri (2011) use a panel data model which can be written as: 23


We see that this model is obtained by the CRC model with additional control covariates (2.20) and the

22 If one imposes a linearity restriction on m ( wi ) , i.e., m ( wi ) = wi h 0 , then the parameter vector h 0 can be estimated by a simple linear instrumental variable regression, similar to the one discussed in section 3.2 below.

23 In a recent publication, Sakaguchi (2020) discusses this model as well, while being unaware of Lemieux (1998) and Suri (2011). As a result, he imposes restrictions that are stronger than in Lemieux (1998) and Suri (2011), requiring that an additional instrumental variable be available, which is not necessary for identification.

extrapolation identifying assumption


by defining ˜ uit = uit + e i . 24

The restriction imposed by (2.23) is stronger than the restriction imposed by the simple extrapolation identifying assumption (2.11) since, in addition to imposing that treatment status history xi 1 , ..., xiT has no partial predictive effect on baseline heterogeneity ai , it imposes that the control covariates zi 1 , ..., ziT also do not have a partial predictive effect. For instance, a set of conditions that is sufficient for (2.23) to hold is given by the conditions (2.14) and (2.15) listed above and the additional condition:


This additional restriction is not necessary for identifying ATE for stayers, as seen from the discussion above, and may be likely to be violated in many applications.

## 2.7 CRC Model with Time-Varying Treatment Effects

In this section, we sketch an extension of the results above to the case where treatment effects might vary over time. A growing econometric literature uses semi-parametric difference-in-differences models to analyze the properties of new and existing estimators. 25 The assumption of parallel trends is the main restriction imposed by semiparametric difference-in-differences models. It imposes that the change over time in potential untreated outcome is identical across all treatment history profiles:


where we assume cross-sectional independence and define xi =[ xi 1 , ..., xiT ] , zi =[ zi 1 , ..., ziT ] .

The parallel trend assumption (2.24) can be rewritten equivalently as a correlated random coefficient model with time-varying coefficients:


by defining ai = yi 1 ( 0 ) , f t ( zi ) = E ( yit ( 0 ) -yi 1 ( 0 ) | zi ) , bit = yit ( 1 ) -yit ( 0 ) .

If the time varying part of treatment effect is captured by observable variables - for instance, if we can

24 Additionally, Suri (2011) imposes, for estimation, additional restrictions on the form of E ( bi | xi 1 , ..., xiT , z i 1 , ..., ziT ) which are not required and are not imposed here or in Lemieux (1998).

25 See, e.g. Heckman et al. (1997), Heckman et al. (1998), Blundell et al. (2004), Abadie (2005), Conley and Taber (2010), Imai and Kim (2012), de Chaisemartin and D'Haultfoeuille (2018a), Abraham and Sun (2018), Callaway and Sant'Anna (2018), de Chaisemartin and D'Haultfoeuille (2018b), Athey and Imbens (2018), Goodman-Bacon (2018), Hull (2018), and references therein.

write:



<!-- page 13 -->

where qit is observed - then the results discussed above apply. 26

Otherwise, one can define Xit = xit [ 1 [ t = s ] , s = 1 , ..., T ] to be a 1 × T vector containing treatment status interacted with indicator variables for each time period, and Bi = [ bit , t = 1 , ..., T ] ′ to be a T × 1 vector containing the treatment effects of cross-sectional observation i at each time period, and write (2.25) as


from which we see that the parallel trend assumption (2.24) can be represented as a CRC model with a larger number of random coefficients than previously considered. We discuss this model in more details in the appendix. In general, estimation based on this model will require a larger number of time periods and crosssectional observations than estimation based on the CRC model with time-constant treatment effects (2.4). In the remainder of this paper, we focus on the CRC model with time-constant treatment effects, although comparing results across specifications in applications with large enough samples would be interesting for future work.

## 3 Estimation and Inference

In this section we define an estimation method composed of two simple steps for the quantities discussed in the previous section. The first step of estimation is an ordinary least-squares (OLS) regression. The second step is an instrumental variable regression.

## 3.1 First Step CRC Regression

The first step of our estimation procedure, similarly as in Chamberlain (1992), consists of an OLS regression of the outcome variable yit on indicator variables for each cross-sectional observation, d j it = 1 [ i = j ] ∀ j = 1 , ..., n ; the interaction of these indicator variables with treatment status, xitd j it ∀ j = 1 , ..., n ; and indicator variables for each time period, 1 [ t = s ] ∀ s = 2 , ..., T , if the CRC model (2.4) without additional covariates is estimated, or the control covariates zit if the CRC model (2.20) with control covariates is estimated.

For simplicity, we will consider the case where the CRC model (2.4) without additional covariates is

26 In the previous section, we considered the case where control covariates entered the CRC model linearly rather than in an additively separable term without parametric restrictions ( f t ( zi ) in equation (2.25) above). The results on estimation discussed in the appendix can be extended to accommodate for a non-parametric first step of estimation in a straightforward way because xit is binary here rather than continuous, the latter being the case considered in Laage (2019).


<!-- page 14 -->

estimated here, and the appendix shows results for the general case. This first estimation step then yields estimates of time effects f t , ˆ f t , for every time period t = 2 , ..., T . The procedure also yields noisy estimates of baseline heterogeneity ai and treatment effect bi , ˆ ai and ˆ bi , for each cross-sectional observation that is a mover. For untreated stayers, only estimates of baseline heterogeneity ai , ˆ ai , are obtained, while only estimates of total heterogeneity ai + bi , ˆ ai + ˆ bi , are obtained for treated stayers.

For the remainder of this section, we also consider for simplicity the special case where two time periods are observed, i.e., T = 2. The case with a general number of time periods is considered in the online appendix. With only two time periods, this first step estimation procedure takes a particularly simple form. The estimator of the time effect for the second time period, f 2, is given by :


where Mn is the set of all cross-sectional observations that are movers, i.e., Mn = { i = 1 , ..., n : xi 1 = xi 2 } and | . | denotes the cardinality of a set.

We also have:


where, as discussed above, all three of these quantities are well-defined for movers only. For untreated stayers, only ˆ ai is well-defined, while only ˆ ai + ˆ bi is well-defined for treated stayers.

The first result in this section shows conditions under which time effects are estimated precisely and that the noise in the estimates of heterogeneity can be decomposed into two parts, one of which vanishes asymptotically and the other of which does not depend on sample size. For simplicity, we assume that observations are identically and independently distributed (i.i.d.) at the level of cross-sectional units. This assumption is relaxed to independence across cross-sectional observations in the appendix and can easily be relaxed to accommodate limited forms of cross-sectional dependence such as cluster dependence, as in Section 3.3 below.

Assumption 1. Observations { xi 1 , yi 1 , xi 2 , yi 2 , ai , bi } i = 1 ,..., n are i.i.d. across i.

In addition, we assume that all variables in the model have finitely bounded higher moments, that there is a positive probability of being a stayer, and that the error term uit is not degenerate.

Assumption 2. Define p S = P ( xi 1 = xi 2 ) and s 2 D u , S = Var ( D ui 2 | xi 1 = xi 2 ) .

a) The support of ai, bi, uit is compact.


b) &gt; 0




<!-- page 15 -->

Assumption 2.a is imposed in this form for simplicity and could easily be relaxed to impose bounded higher moments only. Assumption 2.b is natural here since we are interested in cases where stayers are observed in the data. Assumption 2.c is a regularity condition that imposes that the error term in the CRC model (2.4) has variability, so that the model would not fit the data perfectly without this error term. Under these assumptions, Proposition 1 establishes the asymptotic properties of our first-step estimates.

Proposition 1. Under the CRC model (2.4) and Assumptions 1 and 2, as n → ¥ :


and wherever ˆ ai and ˆ ai + ˆ bi are well-defined, we can write:


where maxi = 1 ,..., n : xi 1 = 0 orxi 2 = 0 | z a , i , n | = Op ( 1 √ n ) and maxi = 1 ,..., n : xi 1 = 1 orxi 2 = 1 | z a + b , i , n | = Op ( 1 √ n ) .

Proposition 1 shows that the noise in the estimates of ai and a + bi obtained from the first step of our estimation procedure is approximated by a noise term of mean zero conditional on treatment status history, since under the CRC model (2.4) we have:


for any combination of values of xi 1 and xi 2 such that these quantities are well-defined.

Therefore, consistent estimators of ATE for movers, ATE 01 = E ( bi | 0 , 1 ) and ATE 10 = E ( bi | 1 , 0 ) , are obtained by simply averaging these noisy estimates across all observations corresponding to movers. To shorten notation, define nx 1 x 2 = |{ i = 1 , ..., n : xi 1 = x 1 , xi 2 = x 2 }| , then the estimators for ATE of movers are given by:


## 3.2 Non-Robust Extrapolation

The extrapolation identifying assumption (2.11), together with the result of Proposition 1, implies that for cross-sectional observations that are movers:



<!-- page 16 -->

where ri = e i + t = 1 , 2 uit (( 1 + a 1 )( 1 -xit ) -a 1 xit ) is a composite error term composed of the error term e i in the extrapolation identifying assumption (2.11) and the non-vanishing part of the estimation noise in the estimates of unobserved heterogeneity shown in Proposition 1, and z i , n is a vanishing error term composed of the vanishing part of the estimation noise in the estimates of unobserved heterogeneity shown in Proposition 1.

Up to a vanishing error term, a 0 and a 1 are therefore parameters in an instrumental variable regression model where the observed variable ˆ ai is the dependent variable, the observed variable ˆ bi is the endogenous covariate, and instrumental variables are given by treatment status history { xi 1 , xi 2 } .

The second step of our estimation procedure estimates a 0 and a 1 by an instrumental variable regression of ˆ ai on ˆ bi using { xi 1 , ..., xiT } as instrumental variables. Because the dependent variable ˆ ai and the endogenous covariate ˆ bi in this instrumental variable regression are only observed simultaneously for movers, this regression is performed using observations on movers only. 27

With only two time periods, this second step estimator takes the simple form of a Wald estimator:


Given estimates of baseline heterogeneity ai for untreated stayers, of total heterogeneity ai + bi for treated stayers, and of the parameters a 0 and a 1 in the extrapolation identifying assumption, estimates of ATE among untreated and treated stayers are obtained by a simple plug-in estimator using the results from the previous section:


In the rest of this section, we show regularity conditions under which this second step yields asymptotically normal estimators for a 0 and a 1 and for ATE among stayers. 28

27 As discussed in section 2.5 above, one may wish to control for correlated cost shifters when extrapolating to stayers. When these cost shifters are indexed by observed variables wi that are low-dimensional, under a linearity restriction discussed in footnote 22, we can write ai = wi h 0 + a 1 bi + e i , E ( e i | wi , xi 1 , ..., xiT ) . The parameter vector h 0 and coefficient a 1 can be estimated by simply regressing ˆ ai on ˆ bi and wi , using { wi , xi 1 , ..., xiT } as instrumental variables. Objects of interest such as ATE for untreated stayers can then be estimated by plug-in estimators. For the ATE of untreated stayers for instance, we would estimate E ( bi | 0 , 0 ) = E ( ai | 0 , 0 ) -E ( wi | 0 , 0 ) h 0 a 1 with ˆ ATE 00 = ¯ a 00 -¯ w 00 ˆ h ˆ a 1 , where ˆ h and ˆ a 1 are the estimates obtained from the instrumental variable regression discussed here and ¯ w 00 is the average value of wi among untreated stayers. All results presented in this section extend to this case in a straightforward way so that we do not provide details here for concision. We discuss in detail the case where wi is high-dimensional but discrete, leading to a fixed-effects instrumental variable regression, in section 3.3 below.

28 Only the first step of our estimation procedure is needed to compute estimates of ATE for movers, which are given by ˆ ATE 01


<!-- page 17 -->


c) Var ( ri | xi 1 , xi 2 ) &gt; 0 if xi 1 = xi 2 . Var ( ai + 1 2 t = 1 , 2 uit | D ui 2 , xi 1 = 0 , xi 2 = 0 ) ≥ c and Var ( ai + bi + 1 t = 1 , 2 uit | D ui 2 , xi 1 = 1 , xi 2 = 1 ) ≥ c a.s. for a constant c &gt; 0 .

Assumption 3. Define p 01 = P ( xi 1 = 0 , xi 2 = 1 ) and p 10 = P ( xi 1 = 1 , xi 2 = 0 ) . a) p 01 &gt; 0 and p 10 &gt; 0 . b) E ( bi | 0 , 1 ) = E ( bi | 1 , 0 ) . 2


Assumption 3.a requires that there be two types of movers with positive probability. Assumption 3.b is an assumption of relevance of the instrumental variables that requires that the two groups of movers have different ATE. Assumption 3.c is a regularity condition that guarantees that the second step estimators defined above have non-degenerate asymptotic distributions. It imposes that there be variability in the composite error term of the approximate instrumental variable regression model (3.4) and that there be variability in baseline heterogeneity ai and total heterogeneity ai + bi conditional on the error term uit of the CRC model, or that there be variability in the error term uit of the CRC model over time.

The following proposition shows that under the CRC model, the extrapolation identifying assumption, and the assumptions above, the second step estimators of a 0, a 1, and of ATE for stayers discussed above have a linear influence function representation and are asymptotically normal.

Proposition 2. Under the CRC model (2.4), the extrapolation identifying assumption (2.11), and Assumptions 1-3, as n → ¥ we have:


where xa , i is an i.i.d. sequence of random variables with E ( xa , i ) = 0 and V a = Var ( xa , i ) , and where za , n = op ( 1 ) .

If in addition a 1 / ∈ { 0 , -1 } , p 00 &gt; 0 , and p 11 &gt; 0 , then:


where x ATE , i is an i.i.d. sequence of random variables with E ( x ATE , i ) = 0 andVATE = Var ( x ATE , i ) , and where z ATE , n = op ( 1 ) .

and ˆ ATE 10 above. Although this is not shown here for concision, one can use the results of Proposition 1 to show that these estimators have linear influence function representations and are asymptotically normal, so that one can estimate unconditional ATE for the entire population by weighing each conditional ATE by the observed frequency of the corresponding subpopulation, and the resulting estimator will be asymptotically normal and have a linear influence function representation under the same assumptions as Proposition 2 below.


<!-- page 18 -->

Since these second-step estimators have a linear influence function representation, asymptotically valid inference can be based on Wald tests with variances estimated by bootstrap resampling, as shown in Mammen (1992), e.g. Note that this resampling should be clustered at the level of cross-sectional observations and that both steps of the estimation procedure outlined above need to be applied to each bootstrap sample for the estimated variance to be valid. The online appendix also provides analytical formulae for the asymptotic variance of the second step estimators, so that their variance can also be estimated as sample analogues of their asymptotic variance. The resulting variance estimator uses quantities that are computed by default in commonly used statistical software, so that implementation is straightforward.

## 3.3 Robust Extrapolation

In this section, we consider extrapolation with the generalized extrapolation assumption:


where vi ∈ { 1 , ..., N } is an observed deterministic indexing variable that indexes the factors of selection into treatment other than treatment effects that may be correlated with baseline heterogeneity ai or treatment effect bi .

Similarly as before, we can show that under the CRC model (2.4), the generalized extrapolation assumption (3.7), and new regularity conditions listed below, an approximate fixed-effects instrumental variable regression model links our noisy estimates ˆ ai and ˆ bi among cross-sectional observations that are movers:


where as before ri = e i + t = 1 , 2 uit (( 1 + a 1 )( 1 -xit ) -a 1 xit ) when T = 2, but with e i denoting the error term in the generalized extrapolation identifying assumption (3.7).

The second step of our estimation procedure under the generalized extrapolation identifying assumption is therefore given by a fixed-effects instrumental variable regression of ˆ ai on ˆ bi using { xi 1 , ..., xiT } as instrumental variables, with fixed effects indexed by the variable vi . As before, only observations on movers are used for this regression.

This new estimation procedure will yield an estimate of a 1, which we redefine to be ˆ a 1, and will also yield estimated fixed effects, which we denote by ˆ ev for value v of the indexing variable vi .

Given these estimates, estimated ATE for stayers are redefined to be:



<!-- page 19 -->

In the rest of this section, we list conditions that guarantee that these estimators are consistent and asymptotically normal. As before, we only consider the case where two time periods are observed here, while the appendix considers the case where a general number of time periods is observed.

For simplicity, we assume that observations are obtained by a random sample of clusters, with clusters indexed by the indexing variable vi . In the online appendix, we show that results can be obtained by imposing only independence across observations with different values of the indexing variable vi . In addition, we assume for simplicity that cross-sectional observations belonging to the same cluster are exchangeable. Finally, we assume that there are few cross-sectional observations per value of the indexing variable vi since this corresponds to our empirical application. 29

To state the next assumption, define nv = |{ i = 1 , ..., n : vi = v }| to be the number of cross-sectional observations with value v of the indexing variable vi , N = |{ v : ∃ i = 1 , ..., n s . t . vi = v }| to be the number of values of the indexing variable vi , and index cross-sectional observations with the same value v of vi by i v , so that { i v : i = 1 , ..., nv } = { i = 1 , ..., n : vi = v } .

Assumption 4. Observations {{ xiv 1 , yiv 1 , xiv 2 , yiv 2 , aiv , biv } i = 1 ,..., nv } v = 1 ,..., N are i.i.d. across v. The number of observations sharing the same value of the indexing variable vi is bounded, i.e., nv ≤ C almost surely for a constant C. Cross-sectional observations with the same value of vi are exchangeable.

With cluster dependence rather than cross-sectional independence as in section 3.2, the assumption that the error term uit in the CRC model (2.4) is not degenerate needs to be slightly reformulated compared to Assumption 2 above.


The generalized extrapolation (3.7) discussed in this section accounts for more flexible patterns of dependence between the factors that determine selection into treatment ( cit ) and the unobserved heterogeneity that determines outcome ( ai and bi ), but consistent estimation will require overlap conditions that were not needed with the simple extrapolation discussed in Section 3.2. The overlap conditions stated in the next assumption guarantee that instrumental variables in the second step of our procedure are relevant even after partialling out variation across observations sharing the same value of the indexing variable vi , and that stayers can be compared to movers with the same value of the indexing variable vi .

29 In our empirical application, cross-sectional observations are farmers and vi indexes villages. We observe an average of twelve farmers per village and a total of 1,130 farmers in our empirical application.

<!-- chunk 3: pages 21-30 -->

order.


<!-- page 21 -->

Proposition 3. Under the CRC model (2.4), the generalized extrapolation identifying assumption (3.7), and Assumptions 4-6, as N → ¥ , we have:

<!-- formula-not-decoded -->

where xa , v is an i.i.d. sequence of random variables with E ( xa , v ) = 0 and V a = Var ( xa , v ) , and where za , N = op ( 1 ) .

If in addition a 1 / ∈ { 0 , -1 } , then:

<!-- formula-not-decoded -->

where x ATE , v is an i.i.d. sequence of random variables with E ( x ATE , v ) = 0 and VATE = Var ( x ATE , v ) , and where z ATE , N = op ( 1 ) .

As before, Proposition 3 shows that asymptotically valid inference can be obtained by using Wald tests with variance estimated by cluster bootstrap, with clusters now being indexed by the indexing variable vi . The appendix also provides formulae for analytical standard errors that are sample analogues of the asymptotic variance of these new second step estimators. In addition, the generalized extrapolation assumption (3.7) can be tested when more than two time periods are observed by testing whether a linear relationship exists between the baseline heterogeneity and treatment effect of movers of different treatment status history profiles after partialling out variation at the level of the indexing variable vi . Details of the test are provided in the appendix.

