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

