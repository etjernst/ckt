<!-- engine: datalab -->

## 3. Semiparametric estimation

Although our identification results hold in a nonparametric setting, we focus here on semiparametric estimation in order to provide root- $n$  consistent and asymptotically normal estimators of  $\psi_0$ ,  $\psi_1$  and  $G$ . More precisely, we consider a class of extended Roy models with a linear index structure of the form:

$$\begin{cases} Y_0 = X' \beta_0 + \varepsilon_0 \\ Y_1 = X' \beta_1 + \varepsilon_1 \\ D = \mathbb{1}\{-\delta_0 + X'(\beta_1 - \beta_0 - \gamma_0) + \eta_\Delta > 0\}. \end{cases} \quad (3.1)$$

Here, our normalization on  $\psi_0(\cdot)$  and  $\psi_1(\cdot)$  is that  $\psi_0(0) = \psi_1(0) = 0$ .<sup>14</sup> In our setting, the non-pecuniary component  $G(X)$  is of the form  $\delta_0 + X' \gamma_0$ . Let  $\gamma_{0j}$  (resp.  $\beta_{0j}$ ,  $\beta_{1j}$ ) denote the  $j$ -th component of  $\gamma_0$  (resp.  $\beta_0$ ,  $\beta_1$ ). We impose the following conditions.

**Assumption 3.1 (Exclusion Restrictions).** There exists  $j_1$  and  $j_2$  such that  $\beta_{0j_1} = \beta_{1j_2} = 0$ ,  $\gamma_{0j_1} \neq \beta_{1j_1}$  and  $\gamma_{0j_2} \neq -\beta_{0j_2}$ .

**Assumption 3.2 (Regularity of  $X$ ).** The support of  $X$  is bounded and not contained in a proper subset of  $\mathbb{R}^p$ . For all  $x_{-1}$  in the support of  $X_{-1}$ , the distribution of  $X_1$  conditional on  $X_{-1} = x_{-1}$  admits a continuously differentiable and positive density on its support, which is a compact interval independent of  $x_{-1}$ . Besides,  $\beta_{11} - \beta_{01} - \gamma_{01} \neq 0$ . Moreover, the support of  $X'(\beta_1 - \beta_0 - \gamma_0)$  is an interval. Finally, for all  $j$ ,  $t \mapsto E(X_j | X'(\beta_1 - \beta_0 - \gamma_0) = t)$  is continuously differentiable.

**Assumption 3.3 (i.i.d. Sample).** We observe a sample  $(Y_i, X_i, D_i)_{1 \leq i \leq n}$  of i.i.d. copies of  $(Y, X, D)$ .

Assumption 3.1 corresponds, in this semiparametric framework, to Assumption 2.6. The case where  $j_1 = j_2$  corresponds to the standard instrumental variable setting of sample selection models, while  $j_1 \neq j_2$  applies when some covariates are sector-specific. Assumption 3.2 corresponds to Assumptions 2.2 and 2.4. It ensures that at least one covariate is continuous and has a nonzero effect on  $D$  (because  $\beta_{11} - \beta_{01} - \gamma_{01} \neq 0$ ). As shown in Theorem 2.1, this condition is sufficient to provide point identification of  $G$ . We also require the support of  $X'(\beta_1 - \beta_0 - \gamma_0)$  to be an interval. This condition, together with the requirement that the  $X_j$  are not collinear, is sufficient to point identify the single index model on  $D$  (see, e.g., Horowitz, 1998) that corresponds to our first step estimator described below.

Let us assume, without loss of generality, that  $\beta_{11} - \beta_{01} - \gamma_{01}$  is strictly positive. We define  $\zeta_0 = (\beta_1 - \beta_0 - \gamma_0)/(\beta_{11} - \beta_{01} - \gamma_{01})$  (so that  $\zeta_{01} = 1$ ) and  $\tilde{\eta}_\Delta = (\eta_\Delta - \delta_0)/(\beta_{11} - \beta_{01} - \gamma_{01})$ . We propose a three-stage estimation procedure of the model, where we estimate first  $\zeta_0$ , then  $(\beta_0, \beta_1)$  and finally  $(\delta_0, \gamma_0)$ . The first and second stages of our procedure are not new, and rely on the fact that we can rewrite the model in the following reduced form:

$$D = \mathbb{1}\{X' \zeta_0 + \tilde{\eta}_\Delta > 0\} \quad (3.2)$$

$$Y_k = X' \beta_k + \varepsilon_k, \quad k \in \{0, 1\},$$

where  $Y_k$  is observed when  $D = k$ ,  $\tilde{\eta}_\Delta$  is independent of  $X$  and  $E(\varepsilon_k | D = k, X)$  only depends on  $X' \zeta_0$ .<sup>15</sup> Besides, by Assumption 3.1,  $X_{j_1}$  (resp.  $X_{j_2}$ ) affects selection since  $\zeta_{0j_1} \neq 0$  (resp.  $\zeta_{0j_2} \neq 0$ ) but not the potential earnings  $Y_0$  (resp.  $Y_1$ ). Hence, Eqs. (3.2) correspond to Newey (2009)'s selection model and we follow his approach here. First, we estimate  $\zeta_0$  by a single index estimator  $\hat{\zeta}$ , for which we suppose Assumption 3.4 below to be satisfied. This is the case of many semiparametric estimators, such as the one of Klein and Spady (1993) or Ichimura (1993). Secondly, we estimate  $\beta_0$  and  $\beta_1$  by series estimator, and we suppose that they satisfy Assumption 3.5. This condition can be obtained under more primitive assumptions (see Newey, 2009, p. S227).

**Assumption 3.4 (Regularity of The First Stage Estimator).** There exists  $(\chi_i)_{1 \leq i \leq n}$ , i.i.d. random variables such that  $E(\chi_i) = 0$ ,  $E(\chi_i \chi_j')$

<sup>12</sup> Lee (2006) and Lee and Lewbel (forthcoming) obtain identification of competing risks models without using arguments at the limit. Their strategy cannot be extended easily to extended Roy models either.

<sup>13</sup> If one of the covariates has large support, one can use alternatively the results of Lewbel (2007) which also yield identification of the covariate effects on earnings without any instrument for selection.

<sup>14</sup> Thus, it may differ from Assumption 2.5 if zero does not belong to the support of  $X$ . Yet, this is still without loss of generality since we do not constrain the expectations of  $\varepsilon_0$  and  $\varepsilon_1$  to be zero.

<sup>15</sup> Indeed,  $\varepsilon_k = \eta_k + v_k$  with  $E(v_k | D = k, X) = 0$  by definition and  $E(\eta_k | D = 1, X = x) = E(\eta_k | \tilde{\eta}_\Delta > -x' \zeta_0)$  (and similarly for  $k = 0$ ). Note that in general,  $\varepsilon_k$  is not independent of  $X$  because  $v_k$  is not.

<!-- page 6 -->

exists and is non-singular and

$$\hat{\zeta} - \zeta_0 = \frac{1}{n} \sum_{i=1}^n X_{i1} + o_p\left(\frac{1}{\sqrt{n}}\right).$$

**Assumption 3.5** (Regularity of The Second Stage Estimators). Let  $\varepsilon \in \{0, 1\}$ , there exists  $(\chi_{ki})_{1 \leq i \leq n}$ , i.i.d. random variables such that  $E(\chi_{ki}) = 0$ ,  $E(\chi_{ki}\chi_{ki}')$  exists and is non-singular and

$$\hat{\beta}_k - \beta_k = \frac{1}{n} \sum_{i=1}^n X_{ki} + o_p\left(\frac{1}{\sqrt{n}}\right).$$

The originality of the estimation procedure lies in its third stage, which is devoted to the estimation of  $(\delta_0, \gamma_0)$ . Actually, it suffices to estimate  $\delta_0$  and  $\alpha_0 \equiv \beta_{01} - \beta_{11} + \gamma_{01}$ , since  $\gamma_0 = \beta_1 - \beta_0 + \alpha_0\zeta_0$ . Eqs. (2.2), (2.3) and (2.5) applied to the current index model show that  $E(D|X)$  and  $E(\varepsilon|X)$  only depend on  $U \equiv X'\zeta_0$ . Letting, with a slight abuse of notation,  $q_0(u) = E(D|U = u)$  and  $g_0(u) = E(\varepsilon|U = u)$ , we have, similarly to Eq. (2.6),

$$g_0'(U) = q_0'(U)(\delta_0 + \alpha_0 U). \tag{3.3}$$

Integrating (3.3) between  $u_0$  in the support of  $U$  and  $U$ , we obtain:

$$g_0(U) = \tilde{\lambda}_0 + q_0(U)\delta_0 + \left[ \int_{u_0}^U u q_0'(u) du \right] \alpha_0,$$

where  $\tilde{\lambda}_0$  is the constant of integration. An integration by part yields

$$g_0(U) = \lambda_0 + q_0(U)\delta_0 + \left[ q_0(U)U - \int_{u_0}^U q_0(u) du \right] \alpha_0, \tag{3.4}$$

where  $\lambda_0 = \tilde{\lambda}_0 - u_0 q_0(u_0)\alpha_0$ . In other terms,

$$\begin{aligned} \varepsilon &= \lambda_0 + D\delta_0 + \left[ DU - \int_{u_0}^U q_0(u) du \right] \alpha_0 + \xi, \\ E(\xi|X) &= E(\xi|U) = 0. \end{aligned} \tag{3.5}$$

Let  $\theta_0 = (\lambda_0, \delta_0, \alpha_0)'$ ,  $V = DU - \int_{u_0}^U q_0(u) du$  and  $W = (1, D, V)'$ , so that  $\varepsilon = W'\theta_0 + \xi$ . The regressors  $D$  and  $V$  are endogenous since selection  $D$  depends both on  $U$  and  $\tilde{\eta}_\varepsilon$ . We therefore use an IV estimator of  $\theta_0$  with functions of the index  $U$  as instruments for  $D$  and  $V$ . To avoid boundary effects, we include some trimming by considering feasible versions of the instruments  $Z = \mathbb{1}\{X \in \mathcal{X}\}h(U)$ , where  $h(U) = (1, h_1(U), h_2(U))' \in \mathbb{R}^3$  and  $\mathcal{X}$  is a set included in the support of  $X$  and such that  $\{x'\zeta_0, x \in \mathcal{X}\}$  is a closed interval strictly included in the interior of the support of  $U$ .<sup>16</sup> Then  $\theta_0 = E(ZW')^{-1}E(Z\varepsilon)$ , and we estimate it by

$$\hat{\theta} = \left( \frac{1}{n} \sum_{i=1}^n \hat{Z}_i \hat{W}_i' \right)^{-1} \left( \frac{1}{n} \sum_{i=1}^n \hat{Z}_i \hat{\varepsilon}_i \right),$$

$$\text{where } \hat{\varepsilon}_i = Y_i - X_i' D_i \hat{\beta}_1 + (1 - D_i) \hat{\beta}_0, \hat{W}_i = (1, D_i, \hat{V}_i)' \text{ and}$$

$$\hat{V}_i = D_i \hat{U}_i - \int_{u_0}^{\hat{U}_i} \hat{q}(u, \hat{\zeta}) du,$$

$$\hat{Z}_i = \mathbb{1}\{X_i \in \mathcal{X}\}h(\hat{U}_i).$$

<sup>16</sup> This trimming procedure ensures uniform consistency of kernel estimators over  $\{x'\zeta_0, x \in \mathcal{X}\}$ .

Finally,  $\hat{U}_i = X_i'\hat{\zeta}$  and

$$\hat{q}(u, \zeta) = \frac{\sum_{i=1}^n D_i K\left(\frac{u - X_i'\zeta}{h_n}\right)}{\sum_{i=1}^n K\left(\frac{u - X_i'\zeta}{h_n}\right)}. \tag{3.6}$$

where  $K(\cdot)$  is a kernel function and  $h_n$  the bandwidth parameter. The result on the third step estimator  $\hat{\theta}$  relies on the following conditions on  $h(\cdot)$  and  $K(\cdot)$ .

**Assumption 3.6** (Restrictions on The Kernel).  $K(\cdot)$  is nonnegative, zero outside a compact set, continuously twice differentiable on this compact set and satisfies  $\int K(v)dv = 1$  and  $\int vK(v)dv = 0$ . Moreover,  $K(\cdot)$  and  $K'(\cdot)$  are zero on the boundary of this compact set.

**Assumption 3.7** (Regular Instruments).  $h_k(\cdot)$  is twice differentiable and  $|h_k'|$  is bounded for  $k \in \{1, 2\}$ .

Assumption 3.6 is satisfied for instance by the quartic kernel  $K(v) = (15/16)(1 - v^2)^2 \mathbb{1}_{[-1,1]}(v)$ . Assumption 3.7 is imposed to ensure that  $\hat{Z}_i - Z_i$  is small for large sample sizes, and behaves regularly.

**Theorem 3.1.** Suppose that  $nh_n^6 \rightarrow \infty$ ,  $nh_n^8 \rightarrow 0$  and that Assumptions 2.1, 2.3, 2.4 and 3.1–3.7 hold. Then

$$\begin{aligned} &\sqrt{n}(\hat{\theta} - \theta_0) \\ &\rightarrow \mathcal{N}\left(0, E(ZW')^{-1}V(Z\xi + \Omega_{11} + \Omega_{21})E(WZ')^{-1}\right), \end{aligned}$$

where  $\Omega_{21}$  is defined by Eq. (3.7) in the online Appendix and

$$\Omega_{21} = \alpha_0 z(1 - F_0(U))\mathbb{1}(U \geq u_0)(D - q_0(U))/f_0(U),$$

$F_0(\cdot)$  and  $f_0(\cdot)$  denoting respectively the cumulative distribution function and the density of  $U$ .

Theorem 3.1 establishes the root- $n$  consistency and asymptotic normality of  $\hat{\theta}$ . We prove the result by first remarking that  $\hat{\theta}$  is a two-step GMM estimator with a nonparametric first step estimator ( $\hat{q}$ ). We then follow Newey and McFadden (1994)'s outline for establishing asymptotic normality. Some differences arise however because  $\hat{q}$  also depends on the estimator  $\hat{\zeta}$ . Theorem 3.1 also shows that the asymptotic variance of  $\hat{\theta}$  depends on the three variables  $\Omega_{11}$ ,  $\Omega_{21}$  and  $Z\xi$ . The first one corresponds to the contribution of the estimators of the first and second steps. The second one arises because of the nonparametric estimation of  $q_0(\cdot)$  in  $\hat{V}_i$ . The third one corresponds to the moment estimation of the linear instrumental model (3.5) in the last step.

As the proof of the theorem shows,  $\hat{\theta}$  can be linearized. Thus, by Assumptions 3.4 and 3.5, the estimator of  $\gamma_0$ ,  $\hat{\gamma} = \hat{\beta}_1 - \hat{\beta}_0 + \hat{\alpha}\hat{\zeta}$ , is also root- $n$  consistent and asymptotically normal.

Although  $\delta_0$  and  $\gamma_0$  are identified without any exclusion restriction, imposing restrictions on  $\gamma_0$  may still be useful to improve the accuracy of the estimators. Suppose that, e.g.,  $X_1$  is excluded from the non-pecuniary component, so that  $\gamma_{01} = 0$ . In this case, we get from the second stage  $\alpha_0 = \beta_{01} - \beta_{11}$ . Hence,  $\gamma_0 = \beta_1 - \beta_0 + \alpha_0\zeta_0$  can be estimated using only the first two steps, resulting in general in accuracy gains (see our Monte Carlo simulations and application below for evidence on this point). The third stage then boils down to estimating  $\delta_0$  only, through the instrumental linear model

$$\varepsilon - \left[ DU - \int_{u_0}^U q_0(u) du \right] \alpha_0 = \lambda_0 + D\delta_0 + \xi,$$

$$E(\xi|X) = E(\xi|U) = 0, \tag{3.7}$$

<!-- page 7 -->

where  $\alpha_0$  in the left hand side can now be estimated by  $\hat{\beta}_{01} - \hat{\beta}_{11}$ . One can show that the corresponding estimator is also asymptotically normal.<sup>17</sup>

Once  $\delta_0$  and  $\alpha_0$  have been estimated, we can also estimate bounds on the distribution of the *ex ante* returns  $\Delta$ , namely  $F_\Delta(u) = E[F_{\eta_\Delta}(u + X'(\beta_0 - \beta_1))]$ . For that purpose, remark that, by (3.1),

$$P(D = 0|X) = F_{\eta_\Delta}(\delta_0 + X'\alpha_0\zeta_0).$$

Therefore, we can obtain an estimator  $\hat{F}_{\eta_\Delta}(\cdot)$  on  $[\hat{M}, \hat{M}]$ , the estimated support of  $\delta_0 + X'\alpha_0\zeta_0$ , by regressing nonparametrically  $1 - D$  on the index  $\hat{\delta} + X'\hat{\alpha}\zeta$ . On  $[\hat{M}, +\infty)$  (resp.  $(-\infty, \hat{M}]$ ), we simply set estimate  $F_{\eta_\Delta}(\cdot)$  by  $[\hat{P}, 1]$  (resp.  $[0, \hat{P}]$ ), where  $\hat{P}$  (resp.  $\hat{P}$ ) is the supremum (resp. infimum) of  $\hat{F}_{\eta_\Delta}(\cdot)$  on  $[\hat{M}, \hat{M}]$ . Finally, we can estimate  $F_\Delta(u)$  and  $F_\Delta(u)$  with the empirical analogs of (2.7) and (2.8). Bounds on the distribution of the *ex ante* returns for the treated can be estimated similarly, using (2.9).

## 4. Application to the decision to attend higher education

### 4.1. The model and data

In this section, we apply our method to estimate the relative importance of non-pecuniary factors and monetary returns to education in the decision to attend higher education in France. We consider here a generalization of the Willis and Rosen model (1979) which accounts for the non-pecuniary consumption value of schooling, in a semiparametric setting. After completing secondary education, individuals decide either to enter directly the labor market with a high school degree ( $k = 0$ ) or to attend higher education ( $k = 1$ ).<sup>18</sup> They are supposed to make their decision  $D \in \{0, 1\}$  by comparing the expected utility  $U_k$  of each schooling alternative  $k$ , given by

$$U_k = E(Y_k^*|X, \eta_0, \eta_1) + G_k(X) = \psi_k(X) + \eta_k + G_k(X),$$

where  $Y_k^*$  and  $G_k(X)$  denote respectively the stream of log-earnings and the consumption value associated with the schooling alternative  $k$ . As above,  $\eta_k$  is an individual productivity term known by the individual at the time of her decision but unobserved by the econometrician. Thus, the selection equation corresponds exactly to Eq. (2.1).

As opposed in particular to the U.S., tuition fees are very low in most of the French higher education institutions (on average around 200 euros per year over the period of interest). This suggests that  $G_0 - G_1$ , which would in principle also account for the direct costs of post-secondary schooling, can be interpreted in this context as a truly non-pecuniary component, including taste for schooling and preferences for future non-wage job attributes (as those may depend on higher education attendance).

We use pooled data from the French Generation 1992 and Generation 1998 surveys in order to estimate our schooling choice model. These surveys collect information on individuals who left the French educational system in 1992 and 1998. They both record educational and labor market histories over the first five years following the exit from the educational system. The surveys also provide a set of individual covariates used as controls in our

estimation procedure. Our subsample of interest comprises respondents having at least passed the national high school final examination. Because the labor market participation rate for this subsample is above 90% over the period of interest for both genders, we keep both males and females in our final sample. We drop individuals who only worked as temporary workers or were out of the labor force during the observation length, as we do not observe any wage for them. This finally leaves us with a sample of 24,225 individuals.<sup>19</sup> Working with many observations is especially important for the semiparametric estimation procedure to perform well.

Apart from a set of common regressors, including high school track, age in 6th grade, school leaving year, dummies for being born abroad (same for parents) and living in the Paris region, gender, and parental profession, we include sector-specific variables, by supposing that the average local log-earnings of high school (resp. higher education) graduates affects  $\psi_0(\cdot)$  (resp.  $\psi_1(\cdot)$ ) alone. These variables, computed from the French Labor Force Surveys (1990–2000), are used as proxies for local labor market conditions (at the level of the French *départements*, which roughly correspond to U.S. counties) for high school and higher education graduates. Migration costs imply that labor market conditions in the places where individuals live while studying are likely to be correlated with the earnings perceived when entering the labor market.

As already mentioned, we only observe incomes during the first five years in the labor market, so that we cannot compute the discounted streams of log-earnings  $Y^* = DY_1^* + (1 - D)Y_0^*$ . To cope with this issue, we estimate a dynamic wage model with sector-specific returns to experience. Even if we cannot recover  $Y^*$  with this model because of uncertainty on future wages, we show in the online Appendix that we can identify a proxy  $Y$  satisfying  $E(Y_k|X, \eta_0, \eta_1) = E(Y_k^*|X, \eta_0, \eta_1)$  (with  $Y = DY_1 + (1 - D)Y_0$ ). The model may then be written in terms of  $Y_k$  instead of  $Y_k^*$ , and our identification strategy applies with  $Y$  instead of  $Y^*$ .

We estimate the model relying on the three-stage semiparametric procedure detailed in Section 3. Identification is secured here through the use of the average local log-earnings of high school and higher education graduates as sector-specific regressors. We use for the first step a mixture of probit (see Coppejans, 2001) with  $K_1 = 3$  mixture components. The second step is performed with Newey (2009)'s series estimator, with  $K_2 = 9$  approximating terms. We use for the last step the same specifications as in the Monte Carlo simulations (see the online Appendix for details). Finally, to estimate  $h$  bounds on the distribution of the *ex ante* returns, we consider a kernel estimator of  $F_{\eta_\Delta}$  with a Gaussian kernel, and a bandwidth  $\hat{h}_n = 1.6\sigma(\hat{U})n^{-1/5}$ .

### 4.2. Results

We focus hereafter on the estimates of the non-pecuniary components and *ex ante* returns. The first step estimates of  $(\zeta, \beta_0, \beta_1)$  are discussed in the online Appendix. The first column of Table 1 below reports the parameter estimates relative to the non-pecuniary component  $G$  which are obtained with the unconstrained specification. The coefficients corresponding to the local average income of higher education and high school graduates are both not significant at the 10% level. This supports the idea that, as proxies for local labor market conditions, these variables have no clear reason to enter the non-pecuniary factors and should therefore only affect the probability of attendance through the *ex ante* returns. It also indicates that the data is consistent with a constrained specification where the coefficient related to the local

<sup>17</sup> The proof is very close to the one of Theorem 3.1 and is available from the authors upon request.

<sup>18</sup> The French higher education system includes universities, which do not impose any entry selection, as well as the *Grandes Écoles* and specialized technical colleges, which are selective.

<sup>19</sup> Descriptives are reported in the online Appendix.

<!-- page 8 -->

average income of high school graduates is set equal to zero.<sup>20</sup> As the estimators are more accurate when using an exclusion restriction on  $G$ , we focus on the constrained specification hereafter.

Several patterns emerge from the constrained estimates of  $G$  displayed in the second column of Table 1. The results suggest that individuals attending a general secondary schooling track (namely L for Humanities, ES for Economics and Social Sciences and S for Sciences), relative to a technical or vocational secondary schooling track, value positively higher education attendance, with the related coefficients being significant at the 1% level.<sup>21</sup> This pattern is consistent with the fact that the courses which are given in vocational secondary schooling tracks and, to a lesser extent, in technical tracks, are much more oriented towards the labor market than they are in general tracks. The positive effect of entering the labor market in 1998 probably reflects the enlargement of access to higher education which took place in France during the 1990s. Individuals living in the Paris region also have a higher probability to attend higher education through these non-pecuniary factors, reflecting the large supply of post-secondary institutions in this area. Parental profession, in particular that of the father, also has a significant influence on the non-pecuniary determinants of the decision to attend higher education. For instance, for a given *ex ante* return to higher education, individuals whose father is employed, relative to a white collar position, as an executive, a tradesman or in an intermediate occupation have a higher propensity to enroll in higher education. This pattern suggests that part of the intergenerational transmission of human capital acts through non-pecuniary factors affecting the higher education attendance decision. Interestingly also, for a given level of expected monetary returns, males have a significantly higher probability of attending higher education (with a parameter significant at the 1% level), possibly reflecting higher educational aspirations for males than for females. Age in 6th grade, which is used as a proxy for schooling ability, also affects the attendance decision through non-pecuniary factors. Individuals who were less than 10 when entering junior high school have for instance a significantly higher probability to get some post-secondary education. These results may stem from a positive correlation between schooling ability and taste (or motivation) for schooling.

Consistent with the results of the unconstrained specification, the coefficient related to the local average income of higher education graduates is small, and here only significant at the 10% level. Finally, an estimation of the non-pecuniary component of each individual in the sample reveals that for 84% of them, this component is negative. Hence, we find, in line with Carneiro et al. (2003), that there is for most of the individuals what could be referred to as a psychic gain of attending higher education.

The estimated distributions of the *ex ante* returns to higher education are displayed in Fig. 1, for the whole sample and for the subsample of higher education attendees. The streams of earnings were divided by 1000 for scaling reasons, so that these returns must be compared to values which range from 0.7 to 2. A first striking point is that both distributions are point identified for most values. Differences between the upper and lower bounds appear only for  $u \geq 0.36$ , and still for these values the identifying interval remains small until  $u \approx 0.65$ . The upper bound of the distribution can be used to compute a lower bound  $\underline{E}$  on the average return

**Table 1**  
Determinants of non-pecuniary factors: parameter estimates.

| Variable                                             | Unconstrained                 | Constrained                   |
|------------------------------------------------------|-------------------------------|-------------------------------|
| Constant ( $\delta_0$ )                              | −0.185 (0.174)                | −0.026 (0.155)                |
| Local average income                                 |                               |                               |
| Higher education graduates                           | −0.026 (0.017)                | −0.014 <sup>*</sup> (0.008)   |
| High school graduates                                | 0.01 (0.012)                  | 0                             |
| Secondary schooling track                            |                               |                               |
| L                                                    | −0.288 <sup>***</sup> (0.087) | −0.142 <sup>***</sup> (0.054) |
| ES                                                   | −0.336 <sup>***</sup> (0.097) | −0.172 <sup>***</sup> (0.058) |
| S                                                    | −0.349 <sup>***</sup> (0.097) | −0.175 <sup>***</sup> (0.061) |
| Vocational                                           | 0.62 <sup>*</sup> (0.248)     | 0.293 <sup>*</sup> (0.164)    |
| Technical                                            | Ref.                          | Ref.                          |
| Born abroad                                          | −0.084 <sup>*</sup> (0.033)   | −0.031 (0.021)                |
| Father born abroad                                   | −0.034 <sup>*</sup> (0.02)    | −0.005 (0.011)                |
| Mother born abroad                                   | 0.003 (0.014)                 | −0.009 (0.013)                |
| Entering the labor market in 1998 (relative to 1992) | −0.272 <sup>***</sup> (0.084) | −0.12 <sup>**</sup> (0.051)   |
| Male                                                 | −0.062 <sup>***</sup> (0.015) | −0.038 <sup>***</sup> (0.009) |
| Father's profession                                  |                               |                               |
| Farmer                                               | −0.029 (0.02)                 | −0.023 (0.017)                |
| Tradesman                                            | −0.053 <sup>**</sup> (0.02)   | −0.025 <sup>**</sup> (0.011)  |
| Executive                                            | −0.105 <sup>***</sup> (0.034) | −0.054 <sup>**</sup> (0.022)  |
| Intermediate occupation                              | −0.071 <sup>***</sup> (0.025) | −0.035 <sup>***</sup> (0.011) |
| Blue collar                                          | 0.000 (0.012)                 | −0.004 (0.008)                |
| Other                                                | −0.036 <sup>***</sup> (0.015) | −0.023 <sup>**</sup> (0.011)  |
| White collar                                         | Ref.                          | Ref.                          |
| Mother's profession                                  |                               |                               |
| Farmer                                               | 0.091 <sup>**</sup> (0.039)   | 0.057 (0.037)                 |
| Tradesman                                            | 0.021 (0.019)                 | −0.003 (0.011)                |
| Executive                                            | −0.056 <sup>**</sup> (0.02)   | −0.023 (0.014)                |
| Intermediate occupation                              | −0.118 (0.013)                | −0.019 (0.011)                |
| Blue collar                                          | 0.076 <sup>**</sup> (0.027)   | 0.019 (0.01)                  |
| Other                                                | 0.012 (0.014)                 | −0.01 (0.007)                 |
| White collar                                         | Ref.                          | Ref.                          |
| Age in 6th grade                                     |                               |                               |
| $\leq 10$                                            | −0.103 <sup>***</sup> (0.038) | −0.047 <sup>**</sup> (0.024)  |
| 11                                                   | Ref.                          | Ref.                          |
| $\geq 12$                                            | 0.108 <sup>***</sup> (0.041)  | 0.056 <sup>**</sup> (0.026)   |
| Paris region                                         | −0.082 <sup>***</sup> (0.025) | −0.03 <sup>**</sup> (0.012)   |
| Vocational $\times \dots$                            |                               |                               |
| Entering the labor market in 1998                    | 0.068 <sup>**</sup> (0.029)   | 0.034 (0.024)                 |
| Male                                                 | −0.02 (0.021)                 | 0.003 (0.014)                 |
| Paris region                                         | 0.126 <sup>***</sup> (0.048)  | 0.059 <sup>**</sup> (0.029)   |

Standard errors, presented in parentheses, were computed by bootstrap with 200 replications.

<sup>\*\*</sup> Significance level: (1%).

<sup>\*</sup> Significance level: (5%).

<sup>\*\*\*</sup> Significance level: (10%).

to higher education  $E(Y_1 - Y_0)$ .<sup>22</sup> We obtain  $\underline{E} \approx 0.12$ , which is quite large since it is close to one standard deviation of  $Y$ . We also observe a large heterogeneity on these returns, with a range on the *ex ante* returns  $E(Y_1 - Y_0 | X, \eta_0, \eta_1)$  which is similar to the one of  $Y$ . This substantial *ex ante* dispersion of the returns to higher education is in line with the conclusion of Cunha and Heckman (2007, p. 887) on U.S. data.

As expected, the distribution of the *ex ante* returns is shifted towards the right for the subsample of higher education attendees, with a close to 10% probability of having a negative *ex ante* return,

<sup>20</sup> We choose to impose the nullity of the coefficient associated with the local average income of high school graduates rather than the one of higher education graduates since (i) its point estimate in the unconstrained setting is much smaller and (ii) the latter coefficient is close to the 10% significance level.

<sup>21</sup> Recall that  $G = G_0 - G_1$ , so that a negative sign for a given coefficient of Gimplied a positive valuation of higher education compared to high school graduation.

<sup>22</sup> Indeed, an integration by parts shows that

$$E(Y_1 - Y_0) = \int_{-\infty}^{\infty} [1[u \geq 0] - F_A(u)] du.$$

This integral can be bounded below by the corresponding integrals on  $\bar{F}_A$ . Note that we cannot obtain a finite upper bound on  $E(Y_1 - Y_0)$  here because  $\lim_{u \rightarrow +\infty} \bar{F}_A(u) < 1$ .

<!-- page 9 -->

![Figure 1: Distribution of the ex ante returns to higher education. The figure consists of two side-by-side plots. The left plot is titled 'Whole population' and the right plot is titled 'Higher education attendees'. Both plots show cumulative distribution functions (CDFs) for 'ex ante returns'. The x-axis represents the return, ranging from -1 to 1 for the whole population and from -0.5 to 1 for higher education attendees. The y-axis represents the cumulative probability, ranging from 0 to 1. Each plot contains three lines: a solid black line for the 'Lower and upper bound' and two dotted black lines for the '95% CI'. In both plots, the CDF curves are S-shaped, starting near 0 at the left and approaching 1 at the right. The curves for higher education attendees are shifted to the right, indicating higher ex ante returns compared to the whole population.](7801d00a216dc4dc8a7d210dcb5fe3c5_img.jpg)

Figure 1: Distribution of the ex ante returns to higher education. The figure consists of two side-by-side plots. The left plot is titled 'Whole population' and the right plot is titled 'Higher education attendees'. Both plots show cumulative distribution functions (CDFs) for 'ex ante returns'. The x-axis represents the return, ranging from -1 to 1 for the whole population and from -0.5 to 1 for higher education attendees. The y-axis represents the cumulative probability, ranging from 0 to 1. Each plot contains three lines: a solid black line for the 'Lower and upper bound' and two dotted black lines for the '95% CI'. In both plots, the CDF curves are S-shaped, starting near 0 at the left and approaching 1 at the right. The curves for higher education attendees are shifted to the right, indicating higher ex ante returns compared to the whole population.

Fig. 1. Distribution of the *ex ante* returns to higher education.

**Table 2**  
Quartiles of *ex ante* returns and non-pecuniary factors.

| Quartile (%) | <i>Ex ante</i> return | Non-pecuniary factors |
|--------------|-----------------------|-----------------------|
| 25           | −0.069                | −0.430                |
| 50           | 0.133                 | −0.326                |
| 75           | 0.267                 | −0.191                |

versus 28% for the whole sample. Hence, about 10% of the individuals attending higher education choose to do so despite a negative *ex ante* return to higher education, stressing the important role played by non-pecuniary factors in this schooling decision. Along those lines, the probability of attending higher education would fall by 11.1 percentage points (from the predicted access rate, equal to 83.1%, to the probability of having a positive *ex ante* return, 72%) if non-pecuniary factors did not exist. For comparison purposes, this decrease in higher education attendance rate is notably eight times larger than the 1.4 point decrease which is found to be associated with a 10% permanent decrease in labor market earnings of higher education attendees.

Several other results highlight the influence of non-pecuniary factors, relative to *ex ante* monetary returns, in the decision to attend higher education. First, as shown in Table 2, the median non-pecuniary component (−0.326) is, in absolute terms, quantitatively much larger than the median *ex ante* return to higher education (0.133). Aside from their large magnitude, non-pecuniary factors also have a fairly large dispersion, with an interquartile range equal to 0.239 which is nevertheless smaller than the interquartile range for *ex ante* returns (0.336). We also compute the predicted probabilities of higher education attendance for fixed values of the non-pecuniary factors. If the non-pecuniary factors of every individual were equal to the first (resp. last) decile of the sample distribution of these factors, the attendance rate in the population would reach 95.2% (resp. 63.0%). Hence, the predicted attendance rate would fall by more than 32 points if *G* varied from its first to its last decile. Overall, in line with recent evidence by Carneiro et al. (2003) and Beffy et al. (2012), non-pecuniary factors appear to be a key determinant of the decision to attend higher education.

### 4.3. Robustness checks

#### 4.3.1. Validity of the identification strategy

The validity of the results discussed above hinges on the exclusion restrictions between sectors. A reason why this identification strategy may not hold is that some individuals who attended higher education might face labor market conditions similar to

the ones faced for those with a high school level. This might in particular be true for higher education dropouts. In order to cope with this potential concern, we run our estimates without the 3092 dropouts. By doing so, we focus on higher education graduation rather than attendance, in a similar spirit as in Carneiro et al. (2003). The resulting estimates of the non-pecuniary factors (see Panel 1, Table 4 in the online Appendix) are very similar to previously. Secondary schooling track, gender, father's profession and year of entry into the labor market remain the main determinants of this non-pecuniary component. The distribution of the *ex ante* returns to higher education is also very similar to previously (see Fig. 2 in the online Appendix) and remains within the confidence intervals of that of the baseline specification. Hence, the robustness of the results to the exclusion of higher education dropouts from the sample supports our exclusion restrictions.

One might also suspect that variations across *départements* in sector-specific average incomes could be correlated with geographical variations in sector-specific labor market productivity. In an attempt to solve this issue, we add in the regressors the local proportion of individuals who graduated from high school with honors. This variable, computed from the Panel 1989 dataset (French Ministry of Education), is used to control for differences across *départements* in productivity levels.<sup>23</sup> The estimates of the non-pecuniary factors as well as of the distribution of the *ex ante* returns to education (see Panel 2, Table 4 and Fig. 2 in the online Appendix) are robust to this alternative specification, suggesting that our estimates are likely not to be biased by this type of confounding effect.

#### 4.3.2. Misspecification bias

As already stressed, assuming that the non-pecuniary component of the selection equation varies across individuals according to observed covariates only allows us to identify the model without any exclusion restrictions nor large support condition on the covariates. However, this specification may seem too restrictive relative to a generalized Roy model where the non-pecuniary factors also vary with unobserved characteristics. We examine this issue by computing, under some distributional assumptions, the misspecification bias on the non-pecuniary component that would arise by using our estimation procedure when the true structure of the selection equation is that of a generalized Roy model, where the

<sup>23</sup> The Panel 1989 is a longitudinal dataset that follows 22,000 students entering 6th grade in 1989.

<!-- page 10 -->

non-pecuniary component writes  $G(X) + U$ , with  $U$  unobserved. We need to impose some further restrictions to compute the misspecification bias  $B(X)$  defined by the difference between the non-pecuniary component obtained with our method (denoted here by  $G(X)$ ) and the deterministic part of the true non-pecuniary component,  $G(X)$ . We assume that  $\eta_\Delta$  and  $U$  are independent and normally distributed, respectively with mean  $m$  and 0. Under these assumptions, it follows from some algebra that:

$$B(X) = -(\tilde{G}(X) - B(X) + T(X) - m) \times \exp \left[ \frac{(\tilde{G}(X) - B(X) + T(X) - m)^2}{2} \rho \left( 1 - \frac{1}{\sigma_{\eta_\Delta}^2} \right) \right] \rho,$$

where  $\rho = \sigma_U^2 / (\sigma_U^2 + \sigma_{\eta_\Delta}^2)$ ,  $\sigma_U^2$  and  $\sigma_{\eta_\Delta}^2$  denoting respectively the variance of  $U$  and  $\eta_\Delta$ .

We estimate the bias by solving numerically this equation on the support of  $X$ , after (i) replacing  $(\tilde{G}(X), T(X))$  by their estimators obtained with our semiparametric procedure, (ii) approximating  $m$  by  $E(T(X)) + \text{median}(\Delta)$  and (iii) calibrating  $(\sigma_U^2, \sigma_{\eta_\Delta}^2)$  from the estimates provided in Carneiro et al. (2003). (ii) and (iii) are needed since we do not identify these parameters in our setting. This leads to an average bias equal to 0.065, corresponding to 40% of the estimated standard error of  $\delta_0$ . Overall, this suggests that the misspecification bias is small relative to the finite sample estimation error on the non-pecuniary component. An important implication is that we will tend to underestimate the dispersion of the non-pecuniary component  $G(X) + U$  with our method. This actually strengthens our finding of a substantial dispersion in the non-pecuniary factors.

