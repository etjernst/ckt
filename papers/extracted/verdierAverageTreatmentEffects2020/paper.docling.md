<!-- chunk 1: pages 1-10 -->

## 
<!-- page 1 -->

Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data

Valentin Verdier ∗

May 25, 2020

## Abstract

Correlated random coefficient (CRC) models provide a useful framework for estimating average treat- ment effects (ATE) with panel data by accommodating heterogeneous treatment effects and flexible pat-

terns of selection. In their simplest form, they lead to the well-known difference-in-differences estimator.

CRC models yield estimates of ATE for 'movers', i.e., cross-sectional units whose treatment status changed over time, while ATE for 'stayers', i.e., cross-sectional units who retained the same treatment

status over time, are not identified. We study additional restrictions on selection into treatment that lead to the identification of ATE for stayers by an extrapolation from quantities identified by the CRC model.

We discuss estimation and testing the extrapolation's validity, then use our results to estimate the returns to agricultural technology adoption among maize farmers in Kenya.

Keywords: Panel data, Correlated Random Coefficient Models, Difference-in-differences, Agricultural technology adoption. JEL codes: C23

Online appendix:

https://bit.ly/3fGURJe

Acknowledgments: I thank Jane Cooley Fruehwirth, David Guilkey, Matt Masten, Arnaud Maurel, and Robert Myers for many helpful comments and suggestions. Andrew Castro provided excellent research assistance to process the data. The data come from the Tegemeo Agricultural Monitoring and Policy Analysis (TAMPA) Project, which is between Tegemeo Institute at Egerton University, Kenya and Michigan State University, and is funded by USAID. Milu Muyanga and John Olwande provided very helpful information for processing the data.

∗ Department of Economics, University of North Carolina - Chapel Hill.

## 
<!-- page 2 -->

1 Introduction

When outcomes and treatment status are observed repeatedly over time, many empircal methods rely on comparisons both across time and across cross-sectional units to obtain estimates of treatment effects that are robust to patterns of selection into treatment that could lead to biases with more naive estimators. With selection on cross-sectional unobserved heterogeneity, fixed effects estimation yields valid estimates when this heterogeneity is constant over time and treatment effect is homogenous. If selection into treatment varies across time, for instance, with more treated observations in later time periods, estimated treatment effects could be biased by the presence of aggregate shocks to outcomes, but estimators that include time fixed effects are valid when these aggregate shocks are common to all cross-sectional units. 1

In many empirical applications, the treatment effect is likely to be heterogenous across cross-sectional units. 2 This heterogeneity leads to biases in the estimators discussed above if they are perceived as estimating average treatment effects (ATE). 3 In addition, estimating features of the heterogeneity in treatment effects might be of first-order interest in many empirical studies. Correlated random coefficient (CRC) models account for heterogeneous treatment effects and flexible patterns of selection on unobservables. These models lead to a separation of cross-sectional units into 'movers', cross-sectional units whose treatment status has changed over time, and 'stayers', cross-sectional units whose treatment status has remained constant over time. With CRC models, a difference-in-differences estimation approach can be used to estimate ATE for movers, while the ATE of stayers are not identified. 4

In some applications, information on the ATE of stayers may be important for policy design. Here, we study existing and new methods for extrapolation from quantities that can be estimated with CRC models to ATE for stayers. We begin by showing that methods introduced by Lemieux (1998) and Suri (2011) can be represented as a linear extrapolation from difference-in-differences estimates. This linear extrapolation

1 Estimators with both cross-sectional and time fixed effects are commonly referred to as two-way fixed effects estimators. Examples are found in Freeman (1984), Jakubson (1991), Card (1996), and Lemieux (1998) on the effect of union membership on wages, Ashenfelter and Card (1985) and Card and Sullivan (1988) on the effect of job training programs on earnings and employment probabilities, Arcidiacono et al. (2008) on returns to completing a MBA, Kowaleski-Jones and Duncan (2002), Behrman and Hoddinott (2005), and Alderman (2007) on the effect of different social aid programs on nutrition, Rouse (1998), Hanushek et al. (1998), and Clotfelter et al. (2010) on the effect of different programs on student achievement, Suri (2011) and Michler et al. (2019) on the effect of technology adoption on agricultural yields. In a recent survey, de Chaisemartin and D'Haultfoeuille (2018b) report that 20% of all studies published in the American Economic Review between 2010 and 2012 rely on the use of two-way fixed effects estimators.

2 See Browning and Carro (2007) for empirical evidence on panel data models with more than additive unobserved heterogeneity. 3 See Chamberlain (1982), Wooldridge (2005), Wooldridge (2010), and de Chaisemartin and D'Haultfoeuille (2018b).

4 See, for instance, de Chaisemartin and D'Haultfoeuille (2018a) for a review of difference-in-differences and Chamberlain (1982) and Chernozhukov et al. (2013) for the non-identification of ATE for stayers with CRC models.


<!-- page 3 -->

takes a simple form: (i) estimate the average baseline outcome and average treatment effect using differencein-differences for different groups of movers; 5 (ii) fit an extrapolation line through the points thus obtained; (iii) estimate average treatment effects for untreated stayers by interpolating their estimated average baseline outcome with this extrapolation line. 6 We show that the validity of this extrapolation relies on an assumption that is likely to be violated if factors of selection into treatment other than treatment effect are statistically correlated with baseline outcomes or treatment effect, which may be a likely scenario in many applications. We show that a more robust extrapolation can be used that accounts for correlated factors of selection into treatment that originate from observable sources. We also discuss extensions of these results to models where additional control covariates are included in the model and to CRC models with time-varying treatment effects. 7 Finally we apply our results to revisit the empirical study of Suri (2011) on estimating the returns to using an agricultural technology, hybrid seeds, among maize farmers in Kenya.

## 2 Correlated Random Coefficient Model and Extrapolation to Stayers

We consider a setting where an outcome yit and treatment status xit ∈ { 0 , 1 } are observed for crosssectional observations i = 1 , ..., n across time periods t = 1 , ..., T . 8 Using potential outcome notation (see e.g. Imbens and Rubin (2015)), we assume that the observed outcome yit is determined by:

<!-- formula-not-decoded -->

where yit ( 1 ) and yit ( 0 ) are the potential outcomes corresponding to treatment or baseline, but a researcher only observes the potential outcome corresponding to the current treatment status of an observation, xit .

We further assume models for potential outcomes that impose additive separability of unobservables and strict exogeneity of treatment status will hold:

<!-- formula-not-decoded -->

<!-- formula-not-decoded -->

5 Different groups of movers can be obtained, for instance, when some cross-sectional observations are observed switching from non-treatment to treatment (adopters) and from treatment to non-treatment (disadopters), or when cross-sectional observations that switch from non-treatment to treatment do so at different points in time, as is frequently the case in event studies.

6 For treated stayers, a -45 ◦ line determined by the sum of their average baseline outcome and average treatment effect is interpolated with the extrapolation line.

7 We show that CRC models with time-varying treatment effects are equivalent to the semi-parametric difference-in-differences models considered in Abadie (2005) and subsequent papers.

8 The covariate of interest, xit , is taken to be binary here, but all results extend directly to the case where xit is discrete. If xit were continuous without perfect persistence, stayers would form a subpopulation of mass zero, which is the case considered in Chamberlain (1992). For simplicity, we abstract from including control covariates at this point but address this point in section 2.6 below.


<!-- page 4 -->

where ai denotes unobserved time-constant heterogeneity that affects both baseline and treated outcomes, f t denotes unobserved aggregate shocks that affect both baseline and treated outcomes, bi denotes the timeconstant effect of treatment, u 0 , it and u 1 , it are additional unobserved shocks to baseline and treated outcomes, and X collects all observations on treatment status: X = { xit : i = 1 , ..., n , t = 1 , ..., T } .

Combining conditions (2.1)-(2.3), and defining uit = u 0 , it + xitu 1 , it , we obtain:

<!-- formula-not-decoded -->

which constitutes the CRC model that we study throughout this paper. 9

Conditions (2.2) and (2.3) do not impose restrictions on the relationship between treatment status, xit , and baseline heterogeneity, ai , treatment effect, bi , or aggregate shocks, f t . Therefore, the CRC model accounts for fairly flexible forms of selection on unobservables and for treatment roll-outs that might coincide with external aggregate shocks to outcomes.

On the other hand, conditions (2.2) and (2.3) impose three main restrictions. Firstly, the unobserved factors determining baseline outcome, yit ( 0 ) , that are potentially correlated with treatment status, xit , are assumed to be additively separable across cross-sectional observations ( ai ) and time periods ( f t ). 10 Secondly, the treatment effect is assumed to be constant over time (up to conditional mean zero shocks), which, for instance, rules out so-called dynamic treatment effects where an individual's treatment effect might vary with how long she has been treated. 11 Finally, conditions (2.2) and (2.3) impose an assumption of strict exogeneity, ruling out feedback mechanisms whereby past outcomes affect current treatment status.

In section 2.2 below, we review what quantities are identified under the CRC model (2.4). In particular we find that the CRC model identifies ATE for movers (cross-sectional observations i = 1 , ..., n such that min t = 1 ,..., T xit = 0 and max t = 1 ,..., T xit = 1) but does not impose any restriction on the ATE of stayers (untreated stayers are cross-sectional observations i = 1 , ..., n such that xit = 0 ∀ t , treated stayers are cross sectional observations such that xit = 1 ∀ t ). In the remainder of the paper, we study existing and new approaches to identifying average treatment effects for stayers with CRC models. Before doing so, we motivate the

9 CRC models were introduced by Chamberlain (1982) and Chamberlain (1992). With continuous covariates, Graham and Powell (2012) considered irregular identification of the model with one fewer time period than required in Chamberlain (1992). Arellano and Bonhomme (2012) considered imposing additional restrictions on the conditional distribution of the transitory shocks uit to recover more information on the distribution of unobserved heterogeneity. Fern´ andez-Val and Lee (2013) study CRC models in a long panel setting (i.e., with many time periods). In a recent contribution, Laage (2019) considers the estimation of CRC models where additional control covariates enter the model in an additively separable term that is not specified parametrically. We concentrate on the CRC model throughout this paper; reviews of alternative non-linear models of panel data can be found in Arellano and Bonhomme (2011) and Ghanem (2017).

10 This is referred to as a parallel trends assumption in the literature on difference-in-differences methods, see e.g. Abadie (2005). 11 We discuss time-varying treatment effect in section 2.7 below.


<!-- page 5 -->

importance of identifying the average treatment effects of stayers for policy design.

## 2.1 Average Treatment Effects of Stayers as Objects of Interest

In this section, we consider the effect on outcomes yit of policies that can affect the distribution of treatment status xit in the population. We will use potential outcome notation to represent the dependence of treatment status xit on the implementation of a policy, and write xit ( 1 ) as the treatment status of individual i at time t if the policy is implemented, and xit ( 0 ) to be this individual's treatment status if the policy is not implemented.

The average effect of a policy is then given by: 12

<!-- formula-not-decoded -->

One may also be interested in the effect of the policy on those affected by the policy:

glyph[negationslash]

<!-- formula-not-decoded -->

One particular policy we can consider is to make treatment mandatory for everyone, so that xit ( 1 ) = 1 for any individual i . Then we have:

<!-- formula-not-decoded -->

so that the average effect of the policy at time t is equal to the average treatment effect for untreated individuals. If untreated stayers represent a large share of all untreated individuals, being able to estimate average treatment effects for stayers would be crucial to predict the effect of the policy.

For other policies, a policy-maker may be able to assume that individuals with higher treatment effects are more likely to switch into treatment than individuals with lower treatment effects, leading to E ( yit ( 1 ) -yit ( 0 ) | xit ( 1 ) -xit ( 0 ) = 1 ) ≥ E ( yit ( 1 ) -yit ( 0 ) | xit ( 1 ) = xit ( 0 ) = 0 ) , and that the policy does not lead to switching out of treatment (i.e., P ( xit ( 1 ) -xit ( 0 ) = -1 ) = 0). 13 In this case, the average treatment effect for untreated individuals forms a lower bound for the effect of the policy on those affected by the

12 Note that the only effect of the policy on outcome yit is through the effect of the policy on treatment status xit .

13 Policies that reduce the cost of treatment to a fixed level for all individuals, such as policies that guarantee that treatment can be accessed at no cost, fall into this category of interventions if an individual's treatment status is determined by a comparison of treatment effect with treatment cost.

policy:

<!-- formula-not-decoded -->


<!-- page 6 -->

More generally, estimating high average treatment effects among untreated individuals in particular subpopulations is evidence that there are reassignments of untreated individuals from these subpopulations to treatment that would lead to large average effects on outcomes, even though it might not be possible to identify which particular interventions could achieve that result without additional information. 14

## 2.2 Identification with the Correlated Random Coefficient Model

In this section, we review what quantities are identified with the CRC model (2.4). For simplicity, we consider the case where only two time periods are observed, i.e., T = 2. The online appendix considers the case where a general number of time periods is observed. For concision, we will write E ( wi | x 1 , x 2 ) to stand for E ( wi | xi 1 = x 1 , xi 2 = x 2 ) for any random variable wi and any values x 1 , x 2 ∈ { 0 , 1 } .

The CRC model (2.4) yields identification of the difference in time effects f t over time from changes in the outcomes of stayers:

<!-- formula-not-decoded -->

where D is the first-differencing operator.

ATE for movers are then identified by a difference-in-differences comparison:

<!-- formula-not-decoded -->

For notational concision, we can apply the normalization f 1 = 0 on the time effects, or, in other words, we write f t instead of f t -f 1 and ai instead of ai + f 1. With this normalization, average baseline heterogeneity is identified by average outcomes for untreated stayers and movers, and average total heterogeneity is identified by average outcomes for treated stayers:

<!-- formula-not-decoded -->

<!-- formula-not-decoded -->

14 Being able to predict the effect of any policy on average outcomes would generally require stronger assumptions on selection into treatment than the restrictions imposed in this paper (see e.g. Heckman and Vytlacil (2007) for a review). Our results could also be combined with a partial identification approach as in Mogstad et al. (2018) to obtain tighter bounds on policy relevant treatment effects, but this is not pursued in this paper.


<!-- page 7 -->

When T = 2 and under cross-sectional independence, the CRC model (2.4) is equivalent to equations (2.7)-(2.10), from which we see that the CRC model imposes no restriction on ATE for stayers, i.e., ATE for stayers are not identified with the CRC model. 15 The online appendix discusses the general case where T ≥ 2. When T &gt; 2, time effects f t are identified by observations on both stayers and movers, but ATE remain non-identified for stayers.

## 2.3 Extrapolation to Stayers

Lemieux (1998) and Suri (2011) study a closely related model where, in the absence of additional control covariates in the CRC model (2.4), the additional assumption:

<!-- formula-not-decoded -->

is imposed, which we call an extrapolation identifying assumption.

With two time periods ( T = 2) and under cross-sectional independence, the extrapolation identifying assumption (2.11) can be rewritten as:

<!-- formula-not-decoded -->

<!-- formula-not-decoded -->

glyph[negationslash]

if all quantities above are well-defined, i.e., if E ( bi | 0 , 1 ) = E ( bi | 1 , 0 ) and a 1 / ∈ { 0 , -1 } .

glyph[negationslash]

As seen in the previous section, all of the right-hand side quantities in equations (2.12) and (2.13) are identified under the CRC model (2.4). Therefore assumption (2.11) yields identification of ATE for stayers by an extrapolation from ATE and average baseline heterogeneity for movers to ATE for stayers. This extrapolation takes a simple form: an extrapolation line is drawn through points ( E ( ai | 1 , 0 ) , E ( bi | 1 , 0 )) and ( E ( ai | 0 , 1 ) , E ( bi | 0 , 1 )) . Average treatment effects for untreated stayers are identified by interpolating the vertical line given by a = E ( ai | 0 , 0 ) and the extrapolation line. Average treatment effects for treated stayers are identified by interpolating the -45 ◦ line given by a + b = E ( ai | 1 , 1 )+ E ( bi | 1 , 1 ) and the extrapolation line. This is represented graphically in Figure 1. If the condition E ( bi | 1 , 0 ) = E ( bi | 0 , 1 ) fails, the extrapolation line is not identified. If the conditions a 1 = 0 and a 1 = -1 fail, ATE are not identified for untreated and treated stayers, respectively. 16

glyph[negationslash]

glyph[negationslash]

15 See also Chernozhukov et al. (2013), where partial identification with similar models when the outcome variable has bounded support is discussed.

16 In cross-sectional data settings, there are results on extrapolating from subpopulations for which ATE are robustly identified to wider subpopulations that have a similar flavor to the extrapolation discussed here. Angrist and Fern´ andez-Val (2013), Brinch et al. (2017), Kline and Walters (2018), Mogstad et al. (2018), and Mogstad and Torgovitsky (2018) discuss extrapolation from local


<!-- page 8 -->

The appendix shows that the methods implemented by Lemieux (1998) and Suri (2011) can indeed be represented as the linear extrapolation depicted by Figure 1. This result provides a simple mechanical representation of these methods in terms of quantities estimated by difference-in-differences that was, to our knowledge, previously unknown.

Both Lemieux (1998) and Suri (2011) highlight the restrictions imposed by the CRC model (2.4) when discussing their empirical model, without emphasizing the restrictions imposed by (2.11). 17 In the next section, we discuss the restrictions imposed by the extrapolation identifying assumption (2.11) in more detail.

## 2.4 Interpretation of the Extrapolation Identifying Assumption

In order to interpret the extrapolation identifying assumption (2.11), we consider a set of conditions that is sufficient for assumption (2.11) to hold. Using the law of iterated expectations, we can show that the extrapolation identifying assumption (2.11) holds if:

<!-- formula-not-decoded -->

<!-- formula-not-decoded -->

where g is a deterministic function and { cit }∀ t are random variables.

Condition (2.14) captures the statistical dependence between baseline heterogeneity ai and treatment effect bi , but imposes linearity in the conditional mean of baseline heterogeneity ai conditional on treatment effect bi . Condition (2.15) captures the possible dependence of treatment status xit on treatment effect bi (endogenous selection), but imposes that factors of selection into treatment other than treatment effect bi , denoted as cit , be independent of baseline heterogeneity and treatment effect. For illustration purposes, the function g can be taken to be a threshold crossing function, so that xit = 1 [ bi ≥ cit ] , where 1 [ . ] is the indicator function. In this case, observation i receives treatment in time period t if treatment effect bi exceeds the cost of treatment given by cit . With this representation, condition (2.15) assumes that the cost of treatment cit is independent of both baseline heterogeneity ai and treatment effect bi . 18

ATE obtained by instrumental variable regression. Angrist and Rokkanen (2015), Bertanha (2017), Bertanha and Imbens (2014), Cattaneo et al. (2016), Dong and Lewbel (2015), Rokkanen (2015) discuss extrapolation from local ATE obtained by regression discontinuity design. W¨ uthrich (2018) establishes a relationship between instrumental variable quantile regression estimation and local quantile treatment effect estimation.

17 For instance, Suri (2011) states that assumption (2.11) is not restrictive (p. 181).

18 Conditions (2.14) and (2.15) are similar to the conditions imposed in generalized Roy models with common factors, see e.g. Abbring and Heckman (2007) for a review. With these models, identification is obtained when valid and relevant instrumental variables are observed, or when proxies can be used, or when independent measurements are available, while here the restrictions imposed by the CRC model yields identification, as discussed above. We provide a more detailed comparison in the appendix.


<!-- page 9 -->

While conditions (2.14) and (2.15) only form a set of conditions that is sufficient for the extrapolation identifying assumption (2.11) to hold, they capture the two restrictions embedded in the extrapolation identifying assumption (2.11), namely: (i) linearity and (ii) no partial correlation between baseline heterogeneity and the factors of selection into treatment other than treatment effect. 19 In this paper, we do not consider methods that could relax the restriction of linearity embedded in the extrapolation identifying assumption (2.11). Recall from section 2.2 that the CRC model can be equivalently written as a set of restrictions on the conditional first moments of baseline heterogeneity and treatment effects. Therefore it is likely that one cannot learn about non-linearities in the relationship between baseline heterogeneity and treatment effects without imposing stronger restrictions than the assumption of mean independence of the CRC model (2.4). This was explored in Arellano and Bonhomme (2012) to learn about distributional features of unobserved heterogeneity for the subpopulation of movers, and it is possible that similar arguments can be extended to an extrapolation to stayers, but we leave this to future work and concentrate on identification with the CRC model (2.4) here. 20 However, the next section shows that an extrapolation to stayers can be conducted when there are factors of selection into treatment other than treatment effects that may be correlated with treatment effects or baseline heterogeneity, as long as these factors of selection into treatment originate from observed sources.

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

## 5 Conclusion

In this paper, we explored how to combine models of selection with correlated random coefficient models of panel data to identify ATE for stayers instead of restricting one's attention to movers. We propose simple estimation and testing procedures, and we find that when applied to estimating the returns to technology adoption, being able to test the extrapolation of ATE to non-hybrid stayers and being able to estimate a generalized extrapolation has first-order implications for empirical results. We hope that these results contribute to widening the applicability of correlated random coefficient models when estimating treatment or partial

38 Intuitively, identification for treated stayers fails when a 1 = -1 because this implies that average returns, bi , are not predictive for average total heterogeneity, ai + bi , which in turn implies that this relationship cannot be inverted to obtain the average returns of treated stayers from their average total heterogeneity. More precisely, consider, for example, the simple extrapolation assumption

(2.11) and T = 2; we have E ( ai + bi | 1 , 1 ) = a 0 +( 1 + a 1 ) E ( bi | 1 , 1 ) = a 0 if a 1 = -1.

39 For comparison, Carter et al. (2017) find an average increase in productivity of 41% from using hybrid seeds in a randomized control trial.

<!-- chunk 4: pages 31-35 -->

- 
<!-- page 31 -->

Brinch, C. N., Mogstad, M., and Wiswall, M. (2017). Beyond LATE with a Discrete Instrument. Journal of Political Economy , 125(4):985-1039.
- Browning, M. and Carro, J. (2007). Heterogeneity and Microeconometrics Modeling. Advances in Economics and Econometrics: Theory and Applications, Ninth World Congress .
- Callaway, B. and Sant'Anna, P. H. C. (2018). Difference-in-Differences with Multiple Time Periods and an Application on the Minimum Wage and Employment.
- Card, D. (1996). The Effect of Unions on the Structure of Wages: A Longitudinal Analysis. Econometrica , 64(4):957-979.
- Card, D. and Sullivan, D. (1988). Measuring the Effect of Subsidized Training Programs on Movements In and Out of Employment. Econometrica , 56(3):497-530.
- Carter, M., Mathenge, M., Bird, S., Lybbert, T., Njagi, T., and Tjernstr¨ om, E. (2017). Policy Brief: Local Seed Company Fills a Niche to Increase Maize Productivity in Kenya. Innovation Lab for Assets and Market Access Policy Brief , (2017-01).
- Cattaneo, M. D., Keele, L., Titiunik, R., and Vazquez-Bare, G. (2016). Interpreting Regression Discontinuity Designs with Multiple Cutoffs. The Journal of Politics , 78(4):1229-1248.
- Chamberlain, G. (1982). Multivariate Regression Models for Panel Data. Journal of Econometrics , 18(1):546.
- Chamberlain, G. (1992). Efficiency Bounds for Semiparametric Regression. Econometrica , 60(3):567-596.
- Chernozhukov, V., Fern´ andez-Val, I., Hahn, J., and Newey, W. (2013). Average and Quantile Effects in Nonseparable Panel Models. Econometrica , 81(2):535-580.
- Clotfelter, C. T., Ladd, H. F., and Vigdor, J. L. (2010). Teacher Credentials and Student Achievement in High School A Cross-Subject Analysis with Student Fixed Effects. Journal of Human Resources , 45(3):655681.
- Conley, T. G. and Taber, C. R. (2010). Inference with 'Difference in Differences' with a Small Number of Policy Changes. The Review of Economics and Statistics , 93(1):113-125.
- de Chaisemartin, C. and D'Haultfoeuille, X. (2018a). Fuzzy Differences-in-Differences. The Review of Economic Studies , 85(2):999-1028.
- de Chaisemartin, C. and D'Haultfoeuille, X. (2018b). Two-way fixed effects estimators with heterogeneous treatment effects. Working Paper .
- Dong, Y. and Lewbel, A. (2015). Identifying the Effect of Changing the Policy Threshold in Regression Discontinuity Models. The Review of Economics and Statistics , 97(5):1081-1092.
- Fern´ andez-Val, I. and Lee, J. (2013). Panel data models with nonadditive unobserved heterogeneity: Estimation and inference. Quantitative Economics , 4(3):453-481.
- Freeman, R. B. (1984). Longitudinal Analyses of the Effects of Trade Unions. Journal of Labor Economics , 2(1):1-26.
- Ghanem, D. (2017). Testing identifying assumptions in nonseparable panel data models. Journal of Econometrics , 197(2):202-217.

- 
<!-- page 32 -->

Goodman-Bacon, A. (2018). Difference-in-Differences with Variation in Treatment Timing. Working Paper 25018, National Bureau of Economic Research.
- Graham, B. S. and Powell, J. L. (2012). Identification and Estimation of Average Partial Effects in 'Irregular' Correlated Random Coefficient Panel Data Models. Econometrica , 80(5):2105-2152.
- Hall, A. R. and Inoue, A. (2003). The large sample behaviour of the generalized method of moments estimator in misspecified models. Journal of Econometrics , 114(2):361 - 394.
- Hanushek, E. A., Kain, J. F., and Rivkin, S. G. (1998). Does Special Education Raise Academic Achievement for Students with Disabilities? Working Paper 6690, National Bureau of Economic Research.
- Heckman, J., Ichimura, H., Smith, J., and Todd, P. (1998). Characterizing Selection Bias Using Experimental Data. Econometrica , 66(5):1017-1098.
- Heckman, J. J., Ichimura, H., and Todd, P. E. (1997). Matching as an Econometric Evaluation Estimator: Evidence from Evaluating a Job Training Programme. The Review of Economic Studies , 64(4):605-654.
- Heckman, J. J. and Vytlacil, E. J. (2007). Chapter 70 Econometric Evaluation of Social Programs, Part I: Causal Models, Structural Models and Econometric Policy Evaluation. In Heckman, J. J. and Leamer, E. E., editors, Handbook of Econometrics , volume 6, pages 4779-4874. Elsevier.
- Hull, P. (2018). Estimating Treatment Effects in Mover Designs.
- Imai, K. and Kim, I. S. (2012). On the Use of Linear Fixed Effects Regression Models for Causal Inference.
- Imbens, G. W. and Rubin, D. B. (2015). Causal Inference for Statistics, Social, and Biomedical Sciences: An Introduction . Cambridge University Press, New York, 1 edition edition.
- Jakubson, G. (1991). Estimation and Testing of the Union Wage Effect Using Panel Data. The Review of Economic Studies , 58(5):971-991.
- Kline, P. and Walters, C. R. (2018). On Heckits, LATE, and Numerical Equivalence | The Econometric Society. Econometrica , Forthcoming.
- Kowaleski-Jones, L. and Duncan, G. J. (2002). Effects of Participation in the WIC Program on Birthweight: Evidence From the National Longitudinal Survey of Youth. American Journal of Public Health , 92(5):799-804.
- Laage, L. (2019). A Correlated Random Coefficient Panel Model with Time-Varying Endogeneity. Working Paper .
- Lemieux, T. (1998). Estimating the Effects of Unions on Wage Inequality in a Panel Data Model with Comparative Advantage and Nonrandom Selection. Journal of Labor Economics , 16(2):261-291.
- Mammen, E. (1992). When Does Bootstrap Work?: Asymptotic Results and Simulations . Lecture Notes in Statistics. Springer-Verlag, New York.
- Michler, J. D., Tjernstr¨ om, E., Verkaart, S., and Mausch, K. (2019). Money Matters: The Role of Yields and Profits in Agricultural Technology Adoption. American Journal of Agricultural Economics , 101(3):710731.
- Mogstad, M., Santos, A., and Torgovitsky, A. (2018). Using Instrumental Variables for Inference About Policy Relevant Treatment Parameters. Econometrica , 86(5):1589-1619.

- 
<!-- page 33 -->

Mogstad, M. and Torgovitsky, A. (2018). Identification and Extrapolation of Causal Effects with Instrumental Variables. Annual Review of Economics , 10(1):577-613.
- Robinson, P. M. (1988). Root-N-Consistent Semiparametric Regression. Econometrica , 56(4):931-954.
- Rokkanen, M. A. T. (2015). Exam Schools, Ability, and the Effects of Affirmative Action: Latent Factor Extrapolation in the Regression Discontinuity Design.
- Rouse, C. E. (1998). Private School Vouchers and Student Achievement: An Evaluation of the Milwaukee Parental Choice Program. The Quarterly Journal of Economics , 113(2):553-602.
- Sakaguchi, S. (2020). Estimation of average treatment effects using panel data when treatment effect heterogeneity depends on unobserved fixed effects. Journal of Applied Econometrics , n/a(n/a).
- Suri, T. (2011). Selection and Comparative Advantage in Technology Adoption. Econometrica , 79(1):159209.
- Wooldridge, J. M. (2005). Fixed-Effects and Related Estimators for Correlated Random-Coefficient and Treatment-Effect Panel Data Models. The Review of Economics and Statistics , 87(2):385-390.
- Wooldridge, J. M. (2010). Econometric Analysis of Cross Section and Panel Data . The MIT Press, second edition.
- W¨ uthrich, K. (2018). A comparison of two quantile models with endogeneity. Journal of Business &amp; Economic Statistics , 0(ja):1-36.

Figure 1: Extrapolation from difference-in-differences estimates to stayers




<!-- page 34 -->

(b) Robust extrapolation.

Figure 2: Visualization of the extrapolation from movers to stayers for the non-robust and robust extrapolations.


<!-- page 35 -->

Table 1: Average baseline productivity and returns to using hybrid seeds for different subpopulations and estimation methods.

|         | Mover currently using hybrid     | Mover currently using hybrid     | Mover currently using hybrid     | Mover currently using hybrid     | Mover currently using hybrid     | Mover currently using hybrid     | Mover currently using hybrid     |
|---------|----------------------------------|----------------------------------|----------------------------------|----------------------------------|----------------------------------|----------------------------------|----------------------------------|
|         | observations                     | baseline                         | baseline                         | return                           | return                           |                                  |                                  |
| 1997    | 137                              | 4.896                            | (0.355)                          | 0.080                            | (0.088)                          |                                  |                                  |
| 2004    | 115                              | 4.937                            | (0.390)                          | 0.112                            | (0.066)                          |                                  |                                  |
| 2007    | 165                              | 4.928                            | (0.358)                          | 0.232                            | (0.077)                          |                                  |                                  |
| 2010    | 251                              | 4.882                            | (0.331)                          | 0.283                            | (0.069)                          |                                  |                                  |
|         | Mover currently not using hybrid | Mover currently not using hybrid | Mover currently not using hybrid | Mover currently not using hybrid | Mover currently not using hybrid | Mover currently not using hybrid | Mover currently not using hybrid |
|         | observations                     | baseline                         | baseline                         | return                           | return                           |                                  |                                  |
| 1997    | 173                              | 4.804                            | (0.338)                          | 0.373                            | (0.072)                          |                                  |                                  |
| 2004    | 198                              | 4.878                            | (0.322)                          | 0.230                            | (0.087)                          |                                  |                                  |
| 2007    | 125                              | 4.697                            | (0.323)                          | 0.295                            | (0.102)                          |                                  |                                  |
| 2010    | 38                               | 4.908                            | (0.330)                          | -0.001                           | (0.170)                          |                                  |                                  |
|         | non-hybrid stayer                | non-hybrid stayer                | non-hybrid stayer                | non-hybrid stayer                | non-hybrid stayer                | non-hybrid stayer                | non-hybrid stayer                |
|         | observations                     | baseline                         | baseline                         | return (NR)                      | return (NR)                      | return (R)                       | return (R)                       |
| 1997    | 95                               | 4.692                            | (0.351)                          | 0.717                            | (0.374)                          | 0.352                            | (0.121)                          |
| 2004    | 84                               | 4.748                            | (0.354)                          | 0.603                            | (0.320)                          | 0.326                            | (0.103)                          |
| 2007    | 71                               | 4.638                            | (0.344)                          | 0.826                            | (0.444)                          | 0.447                            | (0.112)                          |
| 2010    | 59                               | 4.738                            | (0.327)                          | 0.623                            | (0.299)                          | 0.370                            | (0.148)                          |
| a 0     |                                  |                                  |                                  | 5.044                            | (0.407)                          |                                  |                                  |
| a 1     |                                  |                                  |                                  | -0.491                           | (0.348)                          | -0.949                           | (0.329)                          |
| p-value |                                  |                                  |                                  | 0.004                            |                                  | 0.257                            |                                  |

Standard errors, which are between parenthesis, account for the estimation noise originating from both steps of estimation and are robust to cluster dependence at the village level. There are 95 clusters (villages) in the first step of our estimation procedure, and 78 clusters in the second step. For non-hybrid stayers, NR denotes that the non-robust extrapolation was used, while R denotes that the robust extrapolation was used. p-value refers to the p-value obtained from testing the validity of the non-robust and robust extrapolations.
