<!-- engine: datalab -->

<!-- page 0 -->

![Elsevier logo featuring a tree and the word ELSEVIER](935eed7aa61f7777f62cfc032e11bee9_img.jpg)

Elsevier logo featuring a tree and the word ELSEVIER

![Journal of Econometrics cover image](390120de4fe440c42fea8154fcaad334_img.jpg)

Journal of Econometrics cover image

# Inference on an extended Roy model, with an application to schooling decisions in France<sup>\*</sup>

Xavier D'Haultfœuille<sup>a</sup>, Arnaud Maurel<sup>b,c,\*</sup>

<sup>a</sup> CREST, France

<sup>b</sup> Duke University, United States

<sup>c</sup> IZA, Germany

## ARTICLE INFO

### Article history:

Received 11 May 2011

Received in revised form

2 April 2012

Accepted 29 January 2013

Available online 13 February 2013

### JEL classification:

C14

C25

J24

### Keywords:

Roy model

Nonparametric identification

Schooling choices

*ex ante* returns to schooling

## ABSTRACT

This paper considers the identification and estimation of an extension of Roy's model (1951) of sectoral choice, which includes a non-pecuniary component in the selection equation and allows for uncertainty on potential earnings. We focus on the identification of the non-pecuniary component, which is key to disentangling the relative importance of monetary incentives versus preferences in the context of sorting across sectors. By making the most of the structure of the selection equation, we show that this component is point identified from the knowledge of the covariate effects on earnings, as soon as one covariate is continuous. Notably, and in contrast to most results on the identification of Roy models, this implies that identification can be achieved without any exclusion restriction nor large support condition on the covariates. As a by-product, bounds are obtained on the distribution of the *ex ante* monetary returns. We propose a three-stage semiparametric estimation procedure for this model, which yields root- $n$  consistent and asymptotically normal estimators. Finally, we apply our results to the educational context, by providing new evidence from French data that non-pecuniary factors are a key determinant of higher education attendance decisions.

© 2013 Elsevier B.V. All rights reserved.

## 1. Introduction

Self-selection is probably one of the major issues economists have to deal with when trying to measure causal effects such as, among others, wage returns to education, migration and occupation wage premia. The seminal Roy's model (1951) of occupational choice can be seen as an extreme setting of self-selection, where agents choose between two sectors by maximizing their wage. The idea underlying this model has been very influential in the analysis of choices of participation to the labor market (Heckman, 1974), union versus nonunion status (Lee, 1978; Robinson

and Tomes, 1984), public versus private sector (Dustmann and van Soest, 1998), college attendance (Willis and Rosen, 1979), migration (Borjas, 1987), training program participation (Ashenfelter and Card, 1985; Ham and LaLonde, 1996) and occupation (Dolton et al., 1989).

The standard Roy model is, however, restrictive in at least two dimensions. First, non-pecuniary aspects matter much in general. For instance, in the context of educational choice, it is most often assumed that individuals consider not only the investment value of schooling, which is related to wage returns, but also the non-pecuniary consumption value of schooling, which relates to preferences and schooling ability. Recent empirical evidence suggests that these non-pecuniary factors are indeed a key determinant of schooling decisions (see, e.g., Carneiro et al., 2003; Arcidiacono, 2004; Beffy et al., 2012). Non-pecuniary aspects such as working conditions may also matter when choosing an occupation. Similarly, migration decisions are likely to be driven both by monetary returns and the psychic costs associated with the decision to migrate (see, e.g., Bayer et al., 2011). Second, as emphasized by a recent stream of the literature on schooling choices (see Cunha and Heckman, 2007, for a survey), agents most often do not anticipate perfectly their potential earnings in each sector at the moment of their decision. Because of this *ex ante* uncertainty, their decision

<sup>\*</sup> We are grateful to the editor, Han Hong, the associate editor and two anonymous referees for helpful comments. We also thank Victor Aguirregabiria, Christian Belzil, Gerard van den Berg, Federico Bugni, Stephen Cosslett, Philippe Février, Marc Gurgand, Marc Henry, Bo Honoré, Shakeeb Khan, Simon Lee, Thierry Magnac, Enzo Mammen, Salvador Navarro, David Neumark, Jean-Marc Robin, Christopher Taber and participants at numerous seminars and conferences for useful discussions and comments.

<sup>\*</sup> Correspondence to: Department of Economics, Duke University, 213 Social Sciences, Durham, NC 27708, United States. Tel.: +1 919 660 1851; fax: +1 919 681 7984.

E-mail addresses: [xavier.dhaultfoeuille@ensae.fr](mailto:xavier.dhaultfoeuille@ensae.fr) (X. D'Haultfœuille), [apm16@duke.edu](mailto:apm16@duke.edu) (A. Maurel).

<!-- page 1 -->

depends on expectations of these potential earnings rather than on their true values.

This paper focuses on the identification of the non-pecuniary factors in an extended Roy model including these two aspects.<sup>1</sup> The model we consider in the paper includes a non-pecuniary component which is allowed to vary across individuals according to observed covariates. Namely, denoting by  $Y_0$  the potential earnings in sector  $d \in \{0, 1\}$  (and by  $D$  the corresponding random variable),  $\mathcal{I}$  the information set of the agent at the time of the choice and  $G(X)$  the non-pecuniary component, we consider throughout the paper a selection equation of the form:

$$D = 1\{E(Y_1|\mathcal{I}) > E(Y_0|\mathcal{I}) + G(X)\}.$$

While much emphasis has been put in the literature on the identification of the distribution of the potential earnings ( $Y_0, Y_1$ ) in the presence of endogenous selection, still relatively little attention has been geared towards the selection process itself. However, as put forward by [Cunha and Heckman \(2007\)](#), providing evidence on the structural determinants of sectoral choice, which correspond to what agents act on, is of clear interest. In particular, identifying the non-pecuniary factors is key to disentangling the relative importance of monetary incentives versus preferences in the context of sorting across sectors.

By making the most of the structure of the selection process, we show that this non-pecuniary component is point identified from the knowledge of the covariate effects on earnings, as soon as one covariate is continuous. When all covariates are discrete, our strategy can be naturally adapted to yield informative bounds. We then propose two alternative strategies for identifying the covariate effects on sector-specific earnings. The first one is based on exclusion restrictions. It requires either a “standard” instrument, i.e. a variable affecting the selection probability but not the potential earnings, or sector-specific variables à la [Heckman and Sedlacek \(1985, 1990\)](#). The second strategy builds on an argument at infinity for the potential outcomes, relying on a result from a companion paper ([D'Haultfeuille and Maurel, 2013](#)). This latter approach does not require any exclusion restriction, nor any large support on the covariates. Taken together, these results imply that the non-pecuniary component can be identified without any exclusion restriction nor large support condition on the covariates. This conclusion contrasts sharply with the identification results for generalized Roy models, which allow for unobserved determinants of the non-pecuniary component. As stressed by [French and Taber \(2011\)](#), identification of this more general class of models hinges on the availability of exclusion restrictions and large support regressors. Overall, this is a key advantage of our model relative to the generalized Roy specification (see [Heckman and Vytlacil, 2007; French and Taber, 2011](#)). Importantly, we also provide some evidence suggesting that, in the case where the data is actually generated from a generalized Roy model, the misspecification bias on the non-pecuniary component is likely to be small relative to the finite sample estimation error.

As a by-product of this analysis, we obtain informative bounds on the distribution of the *ex ante* returns, which correspond to the monetary returns expected by the agent at the time of the choice and are also equal, in our setting, to marginal treatment effects evaluated at certain margins. We also provide support conditions under which these bounds shrink to a point. In particular, standard average treatment effect parameters are point identified if the probability of selection ranges from zero to one, a result in line with that of [Heckman and Vytlacil \(2005\)](#) in the case of local

instrumental variable strategies. Noteworthy, unlike [Carneiro et al. \(2003\)](#) and [Cunha and Heckman \(2007\)](#) who impose less structure on the selection equation, the *ex ante* returns are identified without any exclusion restriction. To the extent that convincing exclusion restrictions may in practice be hard to come by, we view this as a clear benefit from using our framework.

In a recent article investigating the identification of an extended Roy model with a focus on non-pecuniary factors, [Bayer et al. \(2011\)](#) also propose a strategy which does not require any exclusion restriction nor large support condition. However, they specify an extended Roy model which does not account for *ex ante* uncertainty on the outcomes and restricts the alternative-specific non-pecuniary factors to be constant across individuals. Their model also differs from ours in that they consider a setting with potentially more than two sectors, so that our framework does not nest their model. They show that the non-pecuniary factors as well as the unconditional wage distributions are identified provided that the distribution of monetary returns has a finite lower bound. Although appealing in that neither exclusion restrictions nor strong support conditions are required, the finite lower bound condition may be restrictive and the strategy hard to apply in practice, notably when using log wages which do not have a natural lower bound, such as for instance in [Willis and Rosen \(1979\)](#) and in our application.<sup>2</sup>

Apart from identification, we propose a three-stage semiparametric estimation procedure under an index restriction on the effects of covariates. The first two stages allow us to estimate the covariate effects on potential earnings and correspond to [Newey's method \(2009\)](#) for estimating semiparametric selection models. The originality of the proposed estimation procedure lies in its third stage, which is devoted to the non-pecuniary component. This stage simply amounts to estimating a linear instrumental model. The difference with a standard IV approach is that both the dependent variable and one of the regressors have to be estimated, this involving in particular a nonparametric regression on generated covariates. We show that the corresponding estimator is root- $n$  consistent and asymptotically normal.

Eventually, we apply our estimation procedure to the context of higher education attendance decisions in France over the 1990s. We estimate semiparametrically a model à la [Willis and Rosen \(1979\)](#), which is extended to account for non-pecuniary factors driving the attendance decision. We use respectively the local average incomes for high school and higher education graduates as sector-specific regressors, thus yielding identification of the covariate effects on earnings. As could be expected, we cannot reject (at the 10% level) the hypothesis that the local average income for high school graduates only affects the probability of attendance through the *ex ante* returns to higher education. This allows us to apply a constrained version of our estimator, leading to substantial gains of precision. Consistent with the recent evidence on this question, our results suggest that non-pecuniary factors are a key determinant of the decision to attend higher education. We find in particular that 10% of the individuals attending higher education choose to do so in spite of negative *ex ante* monetary returns to education. Besides, it follows from our estimates that the higher education attendance rate would fall from 83.1% to 72% if non-pecuniary factors did not exist. This decrease is eight times larger than the one associated with a 10% permanent decrease in labor market earnings of higher education attendees.

The remainder of the paper is organized as follows. Section 2 presents the extended Roy model which is considered throughout the paper, derives our key identification results for the non-pecuniary component and the distribution of the *ex ante* returns

<sup>1</sup> The seminal work by [Heckman and Honoré \(1990\)](#) examines the identification of the standard Roy model (see [Buera, 2006](#), for an extension to non-separable functional forms for the potential outcomes).

<sup>2</sup> [Bayer et al. \(2011\)](#) alternatively prove identification assuming independence between the potential wages. We do not make this assumption in the paper.

<!-- page 2 -->

before discussing the identification of the covariate effects on earnings. Section 3 develops a semiparametric estimation procedure for this model, and proves the root- $n$  consistency and asymptotic normality of the proposed estimators. Section 4 applies the preceding estimators to investigate the influence of non-pecuniary factors on higher education attendance decision in France. Finally, Section 5 concludes. The online Appendix collects Monte Carlo simulations, the proofs of our results and additional details on the application.

## 2. Identification

### 2.1. The setting

We consider an extension of the Roy model which is obtained by including *ex ante* uncertainty as well as non-pecuniary factors in the seminal Roy's model (1951) of occupational choice. Suppose that there are two sectors 0 and 1 in the economy, and let  $Y_k$ ,  $k \in \{0, 1\}$ , denote the individual's potential earnings in sector  $k$ . These earnings are not perfectly observed by the individual at the time of her decision. Instead, she can only compute the expectation  $E(Y_k|X, \eta_0, \eta_1)$ , where  $X \in \mathbb{R}^p$  are covariates observed by the econometrician and  $(\eta_0, \eta_1)$  are sector-specific productivity terms known by the agent at the time of the choice but unobserved by the econometrician. We maintain the following assumption throughout the paper.

**Assumption 2.1 (Additive Decomposition).** We have, for  $k \in \{0, 1\}$ ,  $E(Y_k|X, \eta_0, \eta_1) = E(Y_k|X, \eta_k) = \psi_k(X) + \eta_k$ . Moreover,  $X \perp\!\!\!\perp (\eta_0, \eta_1)$ .

The independence assumption ( $X \perp\!\!\!\perp (\eta_0, \eta_1)$ ) is commonly made when studying sample selection models (see, e.g., Powell, 1994) or Roy models (see, e.g., Heckman and Honoré, 1990, for the standard Roy model and French and Taber, 2011, for generalized Roy models). We shall discuss further in the paper how this assumption could be weakened.

We let hereafter  $v_k = Y_k - E(Y_k|X, \eta_0, \eta_1)$  denote the unexpected shock on  $Y_k$  and  $\varepsilon_k = \eta_k + v_k$  denote the sector-specific residual.<sup>3</sup> Noteworthy, apart from the independence assumption, we do not impose any restriction on  $(\eta_0, \eta_1, v_0, v_1)$ , thus departing from, e.g., Carneiro et al. (2003) who posit a factor structure on the unobservables. Such a restriction is useful to identify the joint distribution of  $(\eta_0, \eta_1, v_0, v_1)$ , and thus to test for comparative advantage or to assess the importance of unobserved heterogeneity (see Cunha and Heckman, 2007). We do not consider these issues here.

Unlike Roy's original model, we do not suppose that the sectoral choice is based only on income maximization. Instead, we suppose that each individual chooses to enter the sector which yields the highest expected utility, with the expected utility in sector  $k$  writing as  $U_k = E(Y_k|X, \eta_0, \eta_1) + G_k(X)$ .  $U_k$  is assumed to be given by the sum of sector-specific expected earnings  $E(Y_k|X, \eta_0, \eta_1)$  and the non-pecuniary component associated with sector  $k$ ,  $G_k(X)$ , which is supposed to depend on the covariates  $X$ . Assuming additive separability between the expected earnings and the non-pecuniary component of utility is standard for the generalizations of the Roy model considered in the literature.<sup>4</sup> This separability assumption, which is required to obtain an additive separable form between  $X$  and  $\eta_\Delta$  in the selection index, is key

for our identification strategy.<sup>5</sup> Along with the covariates  $X$ , the econometrician observes the chosen sector  $D$ , which satisfies

$$\begin{aligned} D &= 1\{U_1 > U_0\} \\ &= 1\{\eta_\Delta > \psi_0(X) - \psi_1(X) + G(X)\}, \end{aligned} \quad (2.1)$$

where  $G(X) = (G_0 - G_1)(X)$  and  $\eta_\Delta = \eta_1 - \eta_0$ . Finally, the econometrician also observes the earnings in the chosen sector, that is

$$Y = DY_1 + (1 - D)Y_0.$$

This model is known in the literature as the extended Roy model, whose identification is also considered, in a version without *ex ante* uncertainty, by Heckman and Vytlacil (2007). Bayer et al. (2011) examine the identification of an extended Roy model without *ex ante* uncertainty as well, which allows for more than two sectors and includes a non-pecuniary intercept for each sector. In a recent paper, Fox and Gandhi (2011) extend this model by allowing for random functions in the selection equation.<sup>6</sup> The model presented above can be applied to various economic settings, including sectoral choice in the labor market, immigration or higher education attendance decisions (see our application in Section 5). A central contribution of this paper is to show that, by making the most of the extended Roy structure, the identification of the covariate effects on earnings directly entails the identification of the non-pecuniary component. In particular, unlike in Heckman and Vytlacil (2007) and Fox and Gandhi (2011), no exclusion restriction between  $G$  and  $(\psi_0, \psi_1)$  is needed.

### 2.2. Identification of the non-pecuniary component

Since our main contribution relates to the identification of the non-pecuniary component, we first discuss this issue, and suppose for now that the covariate effects on earnings  $(\psi_0, \psi_1)$  are known. Discussion of the identification of  $(\psi_0, \psi_1)$  is deferred to Section 2.4.<sup>7</sup> Our identification strategy for the non-pecuniary component fully relies on the detailed structure of the model, and in particular on the link between the residuals in the outcome equations and the one in the selection equation. We first suppose that conditional on the other components of  $X$ , at least one component  $X_j$ , say  $X_1$ , is continuous, and we let  $X = (X_1, X_{-1})$  (and we let similarly  $x = (x_1, x_{-1})$ ). We also impose a mild regularity condition on  $T = \psi_0 - \psi_1$ ,  $G$  and the error terms of the outcome equation. Assumption 2.3 below is a technical condition which is usual in Roy or competing risks models (see, e.g., Heckman and Honoré, 1990, or Lee, 2006).

**Assumption 2.2.** For all  $x_{-1}$  in the support of  $X_{-1}$ , the distribution of  $X_1$  conditional on  $X_{-1} = x_{-1}$  is continuous and  $T(\cdot, x_{-1})$  and  $G(\cdot, x_{-1})$  are differentiable on the support of  $X_1$  conditional on  $X_{-1}$ .

**Assumption 2.3 (Restrictions on the Errors, 1).**  $E(|\varepsilon_k|) < \infty$  for  $k \in \{0, 1\}$ . The distribution of  $\eta_\Delta$  admits a continuous density  $f_{\eta_\Delta}$  with respect to the Lebesgue measure and for all  $u \in \mathbb{R}$ ,  $f_{\eta_\Delta}(u) > 0$ .

<sup>5</sup> This echoes the fact that additive separability in the selection index is crucial for the identification results obtained in the Marginal Treatment Effects literature (see, e.g., Heckman and Vytlacil, 2005).

<sup>6</sup> However, as is the case for the model we consider, Fox and Gandhi (2011) rule out the existence of additive errors for the non-pecuniary components entering the selection model.

<sup>7</sup> What we mean by identification throughout the paper is that these functions are uniquely defined almost everywhere by the model and the data generating process. "Almost everywhere" can be replaced by "everywhere" under for instance continuity conditions.

<sup>3</sup> Part of the residual  $v_k$  may correspond to a measurement error rather than an unexpected shock. We use the latter interpretation throughout the paper for convenience of exposition only.

<sup>4</sup> Note that  $-G_k(X)$  can be seen as a cost of entry into sector  $k$ . This interpretation is put forward in the treatment effect literature relying on generalized Roy models.

<!-- page 3 -->

We start from the following observations:

$$\begin{aligned} E[D\eta_\Delta|X] &= E[\mathbb{1}\{\eta_\Delta \geq T(X) + G(X)\}\eta_\Delta|X] \\ &= \int_{T(X)+G(X)}^{\infty} uf_{\eta_\Delta}(u)du, \end{aligned} \quad (2.2)$$

$$E[D|X] = \int_{T(X)+G(X)}^{\infty} f_{\eta_\Delta}(u)du. \quad (2.3)$$

By the fundamental theorem of calculus and Assumptions 2.2 and 2.3, the functions  $q_0(x) = E(D|X = x)$  and  $E[D\eta_\Delta|X = x]$  are continuously differentiable with respect to  $x_1$ , and

$$\frac{\partial E[D\eta_\Delta|X = x]}{\partial x_1} = (T(x) + G(x)) \frac{\partial q_0}{\partial x_1}(x). \quad (2.4)$$

for almost all  $x_{-1}$  and all  $x_1$  in the support of  $X_1$  conditional on  $X_{-1} = x_{-1}$ . Because  $T$  and  $q_0$  are identified, this equation shows that, provided that  $\partial q_0/\partial x_1(x) \neq 0$ , identification of  $G(x)$  amounts to recovering  $\partial E[D\eta_\Delta|X = x]/\partial x_1$ . The key idea, for that purpose, is to relate this term with the residual  $\varepsilon$  of the (realized) outcome equation. Observe that by definition of  $v_i$  and the law of iterated expectations,  $E(v_i|D = k, X) = 0$ . As a result, letting  $\varepsilon = D\varepsilon_1 + (1 - D)\varepsilon_0$ , we get

$$\begin{aligned} E(\varepsilon|X) &= E[D\varepsilon_1 + (1 - D)\varepsilon_0|X] \\ &= E[D\eta_1 + (1 - D)\eta_0|X] \\ &= E[D\eta_\Delta|X] + E[\eta_0]. \end{aligned} \quad (2.5)$$

Thus, letting  $g_0(x) = E(\varepsilon|X = x)$ , we obtain

$$\frac{\partial g_0}{\partial x_1}(x) = (T(x) + G(x)) \frac{\partial q_0}{\partial x_1}(x). \quad (2.6)$$

Since  $\varepsilon = Y - \psi_D(X)$  is identified (where we let  $\psi_D = D\psi_1 + (1 - D)\psi_0$ ),  $g_0$  and  $q_0$  are identified and we can use Eq. (2.6) to recover  $G$ . The only exception is actually when  $\frac{\partial q_0}{\partial x_1}$  is identically equal to zero, a case which is ruled out by Assumptions 2.3 and 2.4 below. Theorem 2.1 shows that, under these conditions,  $G$  is point identified.<sup>8</sup>

**Assumption 2.4.** For all  $x_{-1}$  in the support of  $X_{-1}$ , the set  $\{x_1 : \frac{\partial(T+G)}{\partial x_1}(x_1, x_{-1}) \neq 0\}$  is not empty.

**Theorem 2.1.** Suppose that  $T$  is identified and Assumptions 2.1–2.4 hold. Then  $G$  is identified.

The independence condition between  $X$  and  $(\eta_0, \eta_1)$  plays an important role in the derivation above. However, this assumption could be weakened to the conditional independence condition  $X_1 \perp\!\!\!\perp (\eta_0, \eta_1)|X_{-1}$ , without affecting the identification result. We maintain the stronger independence assumption here for the sake of notational simplicity.

Now consider the case where no component of  $X$  is continuous, so that  $X$  has a discrete distribution. Suppose that it takes  $M < \infty$  values  $x_1, \dots, x_M$ . Then one cannot take the derivative of  $g_0$  and  $q_0$  anymore. However, the strategy above can be adapted to yield bounds on  $G$ , replacing derivatives with finite differences. First, note that  $P(D = 0|X = x) = F_{\eta_\Delta}(T(x) + G(x))$ , with  $F_{\eta_\Delta}$  denoting the cumulative distribution function of  $\eta_\Delta$ . This equality implies that we can sort the  $x_i$ 's so that  $T(x_1) + G(x_1) < \dots$

$< T(x_M) + G(x_M)$ .<sup>9</sup> This provides a first set of inequalities on  $(G(x_1), \dots, G(x_M))$ . Besides, letting  $i < j$ , we have,

$$\begin{aligned} &\sum_{k=i}^{j-1} [T(x_{k+1}) + G(x_{k+1})][q_0(x_{k+1}) - q_0(x_k)] \\ &\leq g_0(x_j) - g_0(x_i) = - \int_{T(x_i)+G(x_i)}^{T(x_j)+G(x_j)} uf_{\eta_\Delta}(u)du \\ &\leq \sum_{k=i}^{j-1} [T(x_k) + G(x_k)][q_0(x_{k+1}) - q_0(x_k)]. \end{aligned}$$

These inequalities provide supplementary conditions for  $(G(x_1), \dots, G(x_M))$ . Note that we only get an upper bound for  $G(x_1)$  and a lower bound for  $G(x_M)$ , but both for  $G(x_2), \dots, G(x_{M-1})$ .

When deriving our estimation procedure in Section 3, consistent with the framework of our application, we will maintain the assumptions ensuring that the non-pecuniary component  $G$  is point identified. We leave in particular the analysis of set-estimation of  $G$  for further research.

### 2.3. Distribution of ex ante returns

We now turn to the identification of the distribution of the ex ante returns,  $\Delta = E(Y_1 - Y_0|X, \eta_0, \eta_1)$ . The ex ante return is meaningful since it corresponds to what agents act on (see Cunha and Heckman, 2007). Besides, it corresponds to the ex post return if (i) agents perfectly observe or anticipate their potential outcomes (in which case  $v_0 = v_1 = 0$ ) or if (ii) the idiosyncratic shocks are equal across sectors ( $v_0 = v_1$ ), as postulated in standard regression models. Although we have remained completely agnostic on the information set of the agents, it is possible to point or partially identify the distribution of  $\Delta$ . The intuition behind is similar to that underlying the identification of  $G$ .  $\Delta$  depends on  $\eta_\Delta$ , which is also the residual of the selection equation. Thus, the observed choice of sector directly provides information on these ex ante returns. To see this, first recall that

$$P(D = 0|X) = F_{\eta_\Delta}(T(X) + G(X)).$$

This shows that  $F_{\eta_\Delta}$  is identified over the support of  $T(X) + G(X)$ . Now, the cumulative distribution function of  $\Delta$  ( $F_\Delta$ ) satisfies

$$\begin{aligned} F_\Delta(u) &= E[P(\eta_\Delta \leq u + T(X)|X)] \\ &= E[F_{\eta_\Delta}(u + T(X))]. \end{aligned}$$

Hence, we can identify  $F_\Delta(u)$  for all  $u$  such that the support of  $X + T(X)$  is included in the support of  $T(X) + G(X)$ . In particular, the complete distribution of the ex ante returns  $\Delta$  is identified as soon as  $T(X) + G(X)$  has a large support. In that case, one can recover standard treatment effect parameters such as the average treatment effect or the average treatment on the treated (i.e. for the individuals such that  $D = 1$  here), by integrating the ex ante returns over the distribution of  $\eta_\Delta$ . Even if this large support condition fails, it is still possible to point identify a subset of the distribution of the ex ante returns, and bound  $F_\Delta(u)$  for the rest of the distribution.<sup>10</sup> Indeed, letting  $[M, \bar{M}]$  (resp.  $[P, \bar{P}]$ ) denote the support of  $T(X) + G(X)$  (resp. of  $P(D = 0|X)$ ), we have, by the

<sup>8</sup> If Assumption 2.4 fails to hold,  $\frac{\partial g_0}{\partial x_1}$  is still identified (but not  $G$ ), as it is equal to  $-\frac{\partial \varepsilon}{\partial x_1}$  in this case. Besides, since Assumption 2.4 implies that  $\frac{\partial q_0}{\partial x_1}$  is not identically equal to zero, this restriction can be tested in the data.

<sup>9</sup> This is without loss of generality. In case of ties between  $T(x_i) + G(x_i)$  and  $T(x_{i+1}) + G(x_{i+1})$ , one may remove  $x_{i+1}$  from the set of  $x$ 's. Then the bounds on  $G(x_{i+1})$  follow directly from those on  $G(x_i)$ .

<sup>10</sup> Heckman and Vytlacil (2007) also obtain bounds on the average returns without assuming large support on the selection probability, in the context of an extended Roy model. Their strategy hinges on an exclusion restriction between the selection equation and the potential outcomes.

<!-- page 4 -->

monotonicity of  $F_{\eta_\Delta}$ ,  $F_\Delta(u) \in [F_\Delta(u), \bar{F}_\Delta(u)]$ , where

$$\begin{aligned} F_\Delta(u) &= E(F_{\eta_\Delta}(u + T(X)) \mathbb{1}[u + T(X) \in [M, \bar{M}]]) \\ &\quad + \bar{P} \times P(u + T(X) > \bar{M}) \\ &\quad + 0 \times P(u + T(X) \leq M), \end{aligned} \tag{2.7}$$

$$\begin{aligned} \bar{F}_\Delta(u) &= E(F_{\eta_\Delta}(u + T(X)) \mathbb{1}[u + T(X) \in [M, \bar{M}]]) \\ &\quad + 1 \times P(u + T(X) > \bar{M}) \\ &\quad + \underline{P} \times P(u + T(X) \leq M). \end{aligned} \tag{2.8}$$

The distribution of the *ex ante* treatment effect on the treated can be identified in a similar way, with

$$\begin{aligned} F_{\Delta|D=1}(u) &= \frac{E((F_{\eta_\Delta}(u + T(X)) - P(D = 0|X)) \times \mathbb{1}\{G(X) \leq u\})}{P(D = 1)}. \end{aligned} \tag{2.9}$$

In our setting, the *ex ante* return  $\Delta$  is closely related to the marginal treatment effect  $\Delta^{MTE}$  (Heckman and Vytlacil, 2005). Indeed, denoting by  $S_{\eta_\Delta}$  the survival function of  $\eta_\Delta$ , we have, under Assumption 2.3,

$$\begin{aligned} \Delta^{MTE}(x, u) &= E(Y_1 - Y_0 | X = x, S_{\eta_\Delta}(\eta_\Delta) = u) \\ &= \psi_1(x) - \psi_0(x) + S_{\eta_\Delta}^{-1}(u). \end{aligned}$$

Thus,  $\Delta = (\psi_1 - \psi_0)(X) + \eta_\Delta$  coincides with  $\Delta^{MTE}(X, S_{\eta_\Delta}(\eta_\Delta))$ . Besides, one is able to identify  $\Delta^{MTE}(x, u)$  for all  $u$  in the support of  $P(D = 1|X)$ , since in that case there exists  $\bar{x}$  in the support of  $X$  such that  $S_{\eta_\Delta}^{-1}(u) = (\psi_0 - \psi_1 + G)(\bar{x})$ .

### **2.4. Identification of the covariate effects on earnings**

We now relax the assumption that the covariate effects on earnings are known, and discuss in this subsection two alternative strategies to identify  $(\psi_0, \psi_1)$ . In both strategies, we impose the following normalization, which is innocuous since adding a constant to  $\psi_k$  and subtracting it to  $\eta_k$  does not modify the model.

**Assumption 2.5 (Normalization).** There exists  $x^*$  in the support of  $X$  such that  $\psi_0(x^*) = \psi_1(x^*) = 0$ .

The first and standard approach we focus on is based on exclusion restrictions, in the same spirit as, e.g., Das et al. (2003). The second hinges on a nonstandard identification at infinity, with the advantage of not requiring any exclusion restriction. The first strategy relies on the following assumption.

**Assumption 2.6 (Exclusion Restrictions).**  $\psi_0$  (resp.  $\psi_1$ ) depends only on  $\bar{X}_0 \subset X$  (resp. on  $\bar{X}_1 \subset X$ ). Moreover,  $\bar{X}_0$  (resp.  $\bar{X}_1$ ) and  $P(D = 1|X)$  are measurably separated, that is, any function of  $\bar{X}_0$  (resp. of  $\bar{X}_1$ ) almost surely equal to a function of  $P(D = 1|X)$  is almost surely constant.

The first part of Assumption 2.6 covers two rather different situations. The first one is when  $X = (\bar{X}_0, Z)$  and  $\bar{X}_1 = \bar{X}_0$ . This corresponds to the standard instrumental setting in sample selection models, where the instrument  $Z$  affects the probability of selection but not the potential outcomes. In our framework,  $Z$  would be a determinant of the non-pecuniary component but not of the potential earnings. The second situation corresponds to the case where  $X = (\bar{X}_0, \bar{X}_1, X_c)$ .  $\bar{X}_0 = (\bar{X}_0, X_c)$  and  $\bar{X}_1 = (\bar{X}_1, X_c)$ . This occurs in the presence of sector-specific regressors. In this case, no exclusion restriction between the non-pecuniary factors and the potential earnings is required. This kind of exclusion restrictions was previously used in particular by Heckman and Sedlacek (1985, 1990) when estimating parametrically a multiple-sector Roy model of self-selection in the labor market. We also use sector-specific regressors in our application.

Intuitively, the measurable separation requirement<sup>11</sup> of Assumption 2.6 ensures that  $\psi_0(X)$  (or  $\psi_1(X)$ ) and  $P(D = 1|X)$  can vary in a sufficiently independent way. This assumption, also made by Das et al. (2003), is weak when, considering the two cases above,  $Z$  or  $(\bar{X}_0, X_1)$  is continuous (see Florens et al., 2008, for sufficient conditions in this case). However, it may not hold when  $Z$  (or  $(\bar{X}_0, X_1)$ ) is discrete. As an illustration, consider a standard instrumental setting where  $\bar{X}_0$  and  $Z$  are binary and let  $P_{ij} = P(D = 1|\bar{X}_0 = i, Z = j)$  for  $i, j \in \{0, 1\}$ . Then, provided that  $P_{10}$  and  $P_{11}$  do not belong to  $\{P_{00}, P_{01}\}$ , there exists a function  $h$  such that  $h(P_{00}) = h(P_{01})$  and  $h(P_{10}) = h(P_{11})$  but  $h(P_{00}) \neq h(P_{10})$ . In this case, the function  $g$  defined by  $g(0) = h(P_{00})$  and  $g(1) = h(P_{10})$  is not constant. As a result,  $\bar{X}_0$  and  $P(D = 1|X)$  are not measurably separated.

Given the preceding exclusion restrictions and the additive decomposition assumption, it is possible to identify  $\psi_0$  and  $\psi_1$  up to location parameters. Then full identification stems from the normalization of Assumption 2.5. Similarly to Das et al. (2003), Proposition 2.2 below does not provide any result on the location parameters. In general, such parameters are identified only at infinity under a large support condition, i.e. when  $P(D = 1|X)$  can be arbitrarily close to zero and one (see Heckman, 1990).

**Proposition 2.2.** Suppose that Assumptions 2.1, 2.3, 2.5 and 2.6 hold. Then  $\psi_0$  and  $\psi_1$  are identified.

Proposition 2.2 is similar to Theorem 2.1 of Das et al. (2003), but identification is shown here without assuming that the regressors are continuous nor that  $\psi_0$  and  $\psi_1$  are continuously differentiable. The idea behind the proof of Proposition 2.2 is that  $E(\varepsilon_k | D = k, X)$  only depends on  $P(D = 1|X)$ . We can then rely on the measurable separability condition of Assumption 2.6 to prove the result. Because identification is based on  $P(D = 1|X)$  only, the structure imposed on the selection equation is not needed at this stage, whereas, as stressed above, it is crucial to identify the non-pecuniary component and the distribution of the *ex ante* returns. Finally, following Das et al. (2003), one could actually relax the independence condition  $X \perp\!\!\!\perp (\eta_0, \eta_1)$  and allow for endogenous covariates  $X$  while still identifying  $\psi_0$  and  $\psi_1$  up to location. However, it is not clear in this case how to recover the non-pecuniary component  $G$ .

We now also show, using a result from a companion paper (D'Haultfœuille and Maurel, 2013), that  $\psi_0$  and  $\psi_1$  can be identified at the limit without any exclusion restriction, under the following restrictions on the error terms.

**Assumption 2.7 (Restrictions on the Errors, 2).** (i)  $X \perp\!\!\!\perp (\varepsilon_0, \varepsilon_1)$ , (ii) for  $k \in \{0, 1\}$ , the supremum of the support of  $\varepsilon_k$  is infinite and there exists  $b_k > 0$  such that  $E(\exp(b_k \varepsilon_k)) < \infty$ , and (iii) for all  $u \in \mathbb{R}$ ,

$$\lim_{v \rightarrow \infty} P(\eta_k - \eta_{1-k} > u | \eta_k + v_k = v) = 1, \quad k \in \{0, 1\}.$$

The first restriction reinforces the condition that  $X \perp\!\!\!\perp (\eta_0, \eta_1)$ , by ruling out in particular heteroskedasticity of the shocks  $(v_0, v_1)$ . The second restriction is a light tail condition, which is in practice fairly mild. If we consider the example of log-wages  $Y_k = \ln W_k$ , the assumption is satisfied provided that there exists  $b_k > 0$  such that  $E(W_k^{b_k}) < \infty$ . Hence, it holds even if wages have fat tails, Pareto-like for instance. The last restriction can be interpreted as a moderate dependence condition between  $\eta_0$  and  $\eta_1$ , which is not very restrictive either. When  $(\eta_0, \eta_1, v_0, v_1)$  is Gaussian for instance, one can show that it is equivalent to  $\text{cov}(\eta_0, \eta_1) < \min(V(\eta_0), V(\eta_1))$ . In particular, when  $V(\eta_0) = V(\eta_1)$ , this condition is automatically satisfied, except in the degenerate case where  $\eta_0 = \eta_1$ .

<sup>11</sup> We adopt here the terminology of Florens et al. (2008) (see their assumption A4).

<!-- page 5 -->

**Proposition 2.3.** Suppose that Assumptions 2.1, 2.5 and 2.7 hold. Then  $\psi_0$  and  $\psi_1$  are identified.

This result does not follow from the typical identification at infinity strategy for sample selection models, which relies on the fact that the selection probability tends to zero or one when one of the regressors takes arbitrarily large values. Rather, the intuition can be described as follows. First, the moderate dependence restriction on  $(\eta_0, \eta_1)$ , together with the extended Roy structure of the selection equation, ensures that

$$\lim_{y \rightarrow \infty} P(D = k | X = x, Y_k = y) = 1, \quad \text{for all } x \text{ and } k \in \{0, 1\}. \quad (2.10)$$

In other words, individuals whose potential outcome in one sector tends to infinity will choose this sector with a probability approaching one, whatever their observed characteristics  $X = x$ . This is because these individuals will have, with a large probability, a smaller potential outcome in the other sector, even though the latter may also be large on average.

In turn, (2.10) implies that the right tails of the observed and potential outcomes are similar. Formally, one can show that as  $y \rightarrow \infty$ ,

$$\lim_{y \rightarrow \infty} \frac{P(Y \geq y, D = k | X = x)}{S_{\psi_k}(y - \psi_k(x))} = 1.$$

As a result,

$$\lim_{y \rightarrow \infty} \frac{P(Y \geq y - \psi_k(x^*), D = k | X = x)}{P(Y \geq y - \psi_k(x), D = k | X = x^*)} = 1.$$

It follows from the location normalization imposed in Assumption 2.5 ( $\psi_k(x^*) = 0$ ) that

$$u = \psi_k(x) \Rightarrow \lim_{y \rightarrow \infty} \frac{P(Y \geq y, D = k | X = x)}{P(Y \geq y - u, D = k | X = x^*)} = 1. \quad (2.11)$$

Because the function  $y \mapsto P(Y \geq y, D = k | X = x)$  is identified for each  $x$ ,  $\psi_k(x)$  is identified provided that the converse of (2.11) also holds. The latter implication is ensured by Assumption 2.7(ii).

This type of identification at infinity is similar to the one used by Heckman and Honoré (1989) and Abbring and van den Berg (2003) in the related competing risks model. Nevertheless, their results cannot be used here because their strategies break down when turning to extended Roy models.<sup>12</sup> An appealing feature of Condition (2.10) is that it is testable (see D'Haultfœuille and Maurel, 2013). Besides, this identification strategy does not rely on any support condition on  $X$ . In particular, it may be applied even if  $X$  is discrete.<sup>13</sup> On the other hand, estimators corresponding to this setting have not been derived yet. We therefore restrict in the estimation part (Section 3) to the case where exclusion restrictions are available.

