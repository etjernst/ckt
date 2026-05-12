---
citekey: dhaultfoeuilleInferenceExtendedRoy2013
title: Inference on an extended Roy model, with an application to schooling decisions in France
authors:
  - D'Haultfoeuille
  - Maurel
year: 2013
doi: null
source_pdf: papers/extracted/dhaultfoeuilleInferenceExtendedRoy2013/dhaultfoeuilleInferenceExtendedRoy2013.pdf
---

# Inference on an extended Roy model, with an application to schooling decisions in France

## Bibliographic header

D'Haultfoeuille, Xavier and Maurel, Arnaud. "Inference on an extended Roy model, with an application to schooling decisions in France." Journal of Econometrics, 2013. DOI: not recorded.

## Research question

How can a Roy-type sectoral choice model be identified and estimated when agents act on expected potential earnings and selection is driven by both monetary and non-pecuniary factors, and how large are non-pecuniary determinants of the decision to attend higher education in France?

## Audience

Microeconometricians working on Roy and generalized Roy models, treatment-effect identification under selection, and applied researchers studying schooling choice and the returns to education.

## Method

The paper extends the Roy (1951) model by adding a non-pecuniary component $G(X)$ to the selection equation and replacing realized with expected potential earnings, so that $D = 1\{E(Y_1|\mathcal{I}) > E(Y_0|\mathcal{I}) + G(X)\}$. Under an additive decomposition $E(Y_k|X,\eta_k) = \psi_k(X) + \eta_k$ with $X \perp (\eta_0,\eta_1)$, the authors show that $G$ is point identified from the covariate effects on earnings as soon as one covariate is continuous, using a derivative argument that links $\partial g_0/\partial x_1$ to $(T(x)+G(x))\partial q_0/\partial x_1$. When all covariates are discrete the same logic yields bounds via finite differences. Identification of the outcome indices $\psi_0, \psi_1$ is obtained either through exclusion restrictions in a Das, Newey, and Vella style (Proposition 2.2), or through a non-standard identification-at-infinity argument on the right tail of potential outcomes (Proposition 2.3). The distribution of ex ante returns $\Delta$ is point identified under large support of $T(X)+G(X)$ and otherwise bounded by closed-form expressions, with an analogous formula for the return distribution among treated individuals. The framework connects to the marginal treatment effect of Heckman and Vytlacil (2005).

## Data

Pooled French Generation 1992 and Generation 1998 surveys, covering individuals who left the French educational system in 1992 or 1998. The sample is restricted to respondents who passed the national high school final examination (baccalaureat) and who are observed working in the labor market, dropping individuals who only held temporary jobs or were out of the labor force, leaving 24,225 individuals. The unit of observation is the individual. Key variables include the schooling choice (enter the labor market with a high school degree vs. attend higher education), log-earnings, individual covariates, and departement-level local averages of log-earnings for high-school and higher-education graduates that serve as sector-specific instruments. A productivity proxy based on the local share of high-school graduates with honors, computed from the Panel 1989 dataset of the French Ministry of Education, is used in robustness checks.

## Statistical methods

Three-stage semiparametric estimator under linear-index restrictions on $\psi_0, \psi_1, G$. Stage 1 estimates the selection-index coefficient $\zeta_0$ by a single-index estimator (Klein-Spady, Ichimura, or Coppejans's mixture-of-probit with $K_1 = 3$ components). Stage 2 estimates the outcome coefficients $(\beta_0, \beta_1)$ by a Newey (2009) series estimator with $K_2 = 9$ approximating terms. Stage 3 recovers the non-pecuniary intercept and slope $(\delta_0, \gamma_0)$ by IV-GMM, using functions of the estimated selection index $U$ as instruments for the endogenous regressors $D$ and an integral $V$ of the conditional choice probability obtained from kernel estimation of the propensity function, with trimming to handle boundary effects. Theorem 3.1 establishes root-$n$ consistency and asymptotic normality of the third-stage estimator. Bounds on the ex ante return distribution use a Gaussian-kernel estimator of $F_{\eta_\Delta}$ with bandwidth $\hat h_n = 1.6\sigma(\hat U) n^{-1/5}$. Standard errors are bootstrapped with 200 replications.

## Findings

1. About 10% of individuals who attend higher education do so despite negative ex ante monetary returns to education.
2. Removing non-pecuniary factors would lower the higher-education attendance rate from a predicted 83.1% to 72%, an 11.1-percentage-point drop, roughly eight times larger than the 1.4-point decrease associated with a 10% permanent fall in higher-education earnings.
3. For 84% of the sample the estimated non-pecuniary component is negative, consistent with a psychic gain from attending higher education.
4. The median non-pecuniary component is $-0.326$ in absolute terms, much larger than the median ex ante return of $0.133$; the interquartile range is $0.239$ for the non-pecuniary component and $0.336$ for ex ante returns.
5. Setting the non-pecuniary component to the first vs. last decile of its estimated distribution moves predicted attendance from 95.2% to 63.0%, a swing of more than 32 points.
6. The lower bound on the average return to higher education is $\underline E \approx 0.12$, close to one standard deviation of log-earnings.
7. The ex ante return distribution is right-shifted among attendees: roughly 10% face a negative ex ante return, against 28% in the whole sample.
8. Under a generalized-Roy misspecification with jointly normal unobservables, the analytical bias on $\delta_0$ averages 0.065, about 40% of its estimated standard error.

## Contribution

The paper delivers a new identification result for the non-pecuniary component of a generalized Roy selection equation that requires neither exclusion restrictions nor large-support conditions on the covariates, only a single continuous covariate. It complements this with closed-form bounds on the ex ante return distribution and a root-$n$ semiparametric three-stage estimator, then applies the framework to French data to quantify the dominance of non-pecuniary factors over expected monetary returns in higher-education decisions.

## Replication feasibility

The application uses the French Generation 1992 and Generation 1998 surveys plus the Panel 1989 dataset from the French Ministry of Education. These sources are administrative survey products and are not described as publicly downloadable. The appendix points to online supplementary material via a DOI link but no public replication archive is cited in the chunks. Replication would require access to the underlying surveys through CEREQ and the French Ministry of Education and implementation of the three-stage estimator from the paper's equations.

## Verbatim evidence

Every numerical, causal, definitional, or sample-scope claim the paper makes appears here as a verbatim quote with page number. This block is the substrate for citation audits; paraphrases do NOT belong here.

- **Quantitative (effect size):** "We find in particular that 10% of the individuals attending higher education choose to do so in spite of negative *ex ante* monetary returns to education." (p. 1)
- **Quantitative (effect size):** "Besides, it follows from our estimates that the higher education attendance rate would fall from 83.1% to 72% if non-pecuniary factors did not exist. This decrease is eight times larger than the one associated with a 10% permanent decrease in labor market earnings of higher education attendees." (p. 1)
- **Quantitative (effect size):** "tuition fees are very low in most of the French higher education institutions (on average around 200 euros per year over the period of interest)" (p. 8)
- **Quantitative (effect size):** "an estimation of the non-pecuniary component of each individual in the sample reveals that for 84% of them, this component is negative." (p. 9)
- **Quantitative (effect size):** "The upper bound of the distribution can be used to compute a lower bound  $\underline{E}$  on the average return to higher education  $E(Y_1 - Y_0)$. We obtain  $\underline{E} \approx 0.12$, which is quite large since it is close to one standard deviation of  $Y$." (pp. 8-9)
- **Quantitative (effect size):** "the distribution of the *ex ante* returns is shifted towards the right for the subsample of higher education attendees, with a close to 10% probability of having a negative *ex ante* return, versus 28% for the whole sample." (pp. 9-10)
- **Quantitative (effect size):** "about 10% of the individuals attending higher education choose to do so despite a negative *ex ante* return to higher education" (p. 10)
- **Quantitative (effect size):** "the probability of attending higher education would fall by 11.1 percentage points (from the predicted access rate, equal to 83.1%, to the probability of having a positive *ex ante* return, 72%) if non-pecuniary factors did not exist." (p. 10)
- **Quantitative (effect size):** "this decrease in higher education attendance rate is notably eight times larger than the 1.4 point decrease which is found to be associated with a 10% permanent decrease in labor market earnings of higher education attendees." (p. 10)
- **Quantitative (effect size):** "the median non-pecuniary component (−0.326) is, in absolute terms, quantitatively much larger than the median *ex ante* return to higher education (0.133). Aside from their large magnitude, non-pecuniary factors also have a fairly large dispersion, with an interquartile range equal to 0.239 which is nevertheless smaller than the interquartile range for *ex ante* returns (0.336)." (p. 10)
- **Quantitative (effect size):** "If the non-pecuniary factors of every individual were equal to the first (resp. last) decile of the sample distribution of these factors, the attendance rate in the population would reach 95.2% (resp. 63.0%). Hence, the predicted attendance rate would fall by more than 32 points if *G* varied from its first to its last decile." (p. 10)
- **Quantitative (effect size):** "Quartile (%) | *Ex ante* return | Non-pecuniary factors | 25 | −0.069 | −0.430 | 50 | 0.133 | −0.326 | 75 | 0.267 | −0.191" (p. 10)
- **Quantitative (effect size):** "This leads to an average bias equal to 0.065, corresponding to 40% of the estimated standard error of  $\delta_0$." (p. 10)
- **Causal (identification):** "Notably, and in contrast to most results on the identification of Roy models, this implies that identification can be achieved without any exclusion restriction nor large support condition on the covariates." (p. 0)
- **Causal (identification):** "By making the most of the structure of the selection process, we show that this non-pecuniary component is point identified from the knowledge of the covariate effects on earnings, as soon as one covariate is continuous. When all covariates are discrete, our strategy can be naturally adapted to yield informative bounds." (p. 1)
- **Causal (identification):** "Taken together, these results imply that the non-pecuniary component can be identified without any exclusion restriction nor large support condition on the covariates." (p. 1)
- **Causal (identification):** "In particular, standard average treatment effect parameters are point identified if the probability of selection ranges from zero to one, a result in line with that of [Heckman and Vytlacil (2005)] in the case of local instrumental variable strategies." (p. 1)
- **Causal (identification):** "**Theorem 2.1.** Suppose that  $T$  is identified and Assumptions 2.1-2.4 hold. Then  $G$  is identified." (p. 3)
- **Causal (identification):** "The independence condition between  $X$  and  $(\eta_0, \eta_1)$  plays an important role in the derivation above. However, this assumption could be weakened to the conditional independence condition  $X_1 \perp\!\!\!\perp (\eta_0, \eta_1)|X_{-1}$ , without affecting the identification result." (p. 3)
- **Causal (identification):** "Hence, we can identify  $F_\Delta(u)$  for all  $u$  such that the support of  $X + T(X)$  is included in the support of  $T(X) + G(X)$ . In particular, the complete distribution of the ex ante returns  $\Delta$  is identified as soon as  $T(X) + G(X)$  has a large support." (p. 3)
- **Causal (identification):** "**Proposition 2.2.** Suppose that Assumptions 2.1, 2.3, 2.5 and 2.6 hold. Then  $\psi_0$  and  $\psi_1$  are identified." (p. 4)
- **Causal (identification):** "**Proposition 2.3.** Suppose that Assumptions 2.1, 2.5 and 2.7 hold. Then  $\psi_0$  and  $\psi_1$  are identified." (p. 5)
- **Causal (identification):** "$$\lim_{y \rightarrow \infty} P(D = k | X = x, Y_k = y) = 1, \quad \text{for all } x \text{ and } k \in \{0, 1\}. \quad (2.10)$$" (p. 5)
- **Causal (identification):** "Although  $\delta_0$  and  $\gamma_0$  are identified without any exclusion restriction, imposing restrictions on  $\gamma_0$  may still be useful to improve the accuracy of the estimators." (p. 7)
- **Causal (identification):** "Consistent with the recent empirical evidence on this question, our main insight is that non-pecuniary factors are a key determinant of the attendance decision." (p. 10)
- **Causal (identification):** "From a policy point of view, our results suggest that a moderate increase in tuition fees, which is currently discussed to help finance the French higher education system, would only have a small detrimental effect on the higher education participation rate." (p. 10)
- **Sample scope:** "Eventually, we apply our estimation procedure to the context of higher education attendance decisions in France over the 1990s." (p. 1)
- **Sample scope:** "We use pooled data from the French Generation 1992 and Generation 1998 surveys in order to estimate our schooling choice model. These surveys collect information on individuals who left the French educational system in 1992 and 1998." (p. 8)
- **Sample scope:** "Our subsample of interest comprises respondents having at least passed the national high school final examination. Because the labor market participation rate for this subsample is above 90% over the period of interest for both genders, we keep both males and females in our final sample. We drop individuals who only worked as temporary workers or were out of the labor force during the observation length, as we do not observe any wage for them. This finally leaves us with a sample of 24,225 individuals." (p. 8)
- **Sample scope:** "we run our estimates without the 3092 dropouts. By doing so, we focus on higher education graduation rather than attendance" (p. 10)
- **Sample scope:** "We use our approach to quantify the relative importance of non-pecuniary factors and expected returns to schooling in the decision to attend higher education in France." (p. 10)
- **Definitional:** "$$D = 1\{E(Y_1|\mathcal{I}) > E(Y_0|\mathcal{I}) + G(X)\}.$$" (p. 1)
- **Definitional:** "**Assumption 2.1 (Additive Decomposition).** We have, for  $k \in \{0, 1\}$ ,  $E(Y_k|X, \eta_0, \eta_1) = E(Y_k|X, \eta_k) = \psi_k(X) + \eta_k$ . Moreover,  $X \perp\!\!\!\perp (\eta_0, \eta_1)$ ." (p. 2)
- **Definitional:** "$$\begin{aligned} D &= 1\{U_1 > U_0\} \\ &= 1\{\eta_\Delta > \psi_0(X) - \psi_1(X) + G(X)\}, \end{aligned} \quad (2.1)$$" (p. 2)
- **Definitional:** "$$Y = DY_1 + (1 - D)Y_0.$$" (p. 2)
- **Definitional:** "$$\frac{\partial E[D\eta_\Delta|X = x]}{\partial x_1} = (T(x) + G(x)) \frac{\partial q_0}{\partial x_1}(x). \quad (2.4)$$" (p. 3)
- **Definitional:** "$$\frac{\partial g_0}{\partial x_1}(x) = (T(x) + G(x)) \frac{\partial q_0}{\partial x_1}(x). \quad (2.6)$$" (p. 3)
- **Definitional:** "$$P(D = 0|X) = F_{\eta_\Delta}(T(X) + G(X)).$$" (p. 3)
- **Definitional:** "$$\begin{aligned} F_\Delta(u) &= E(F_{\eta_\Delta}(u + T(X)) \mathbb{1}[u + T(X) \in [M, \bar{M}]]) \\ &\quad + \bar{P} \times P(u + T(X) > \bar{M}) \\ &\quad + 0 \times P(u + T(X) \leq M), \end{aligned} \tag{2.7}$$" (p. 4)
- **Definitional:** "$$\begin{aligned} \bar{F}_\Delta(u) &= E(F_{\eta_\Delta}(u + T(X)) \mathbb{1}[u + T(X) \in [M, \bar{M}]]) \\ &\quad + 1 \times P(u + T(X) > \bar{M}) \\ &\quad + \underline{P} \times P(u + T(X) \leq M). \end{aligned} \tag{2.8}$$" (p. 4)
- **Definitional:** "$$\begin{aligned} F_{\Delta|D=1}(u) &= \frac{E((F_{\eta_\Delta}(u + T(X)) - P(D = 0|X)) \times \mathbb{1}\{G(X) \leq u\})}{P(D = 1)}. \end{aligned} \tag{2.9}$$" (p. 4)
- **Definitional:** "$$\begin{aligned} \Delta^{MTE}(x, u) &= E(Y_1 - Y_0 | X = x, S_{\eta_\Delta}(\eta_\Delta) = u) \\ &= \psi_1(x) - \psi_0(x) + S_{\eta_\Delta}^{-1}(u). \end{aligned}$$" (p. 4)
- **Definitional:** "After completing secondary education, individuals decide either to enter directly the labor market with a high school degree ( $k = 0$ ) or to attend higher education ( $k = 1$ )." (p. 8)
- **Definitional:** "$U_k = E(Y_k^*|X, \eta_0, \eta_1) + G_k(X) = \psi_k(X) + \eta_k + G_k(X)$, where  $Y_k^*$  and  $G_k(X)$  denote respectively the stream of log-earnings and the consumption value associated with the schooling alternative  $k$." (p. 8)
- **Methodological:** "This paper considers the identification and estimation of an extension of Roy's model (1951) of sectoral choice, which includes a non-pecuniary component in the selection equation and allows for uncertainty on potential earnings." (p. 0)
- **Methodological:** "By making the most of the structure of the selection equation, we show that this component is point identified from the knowledge of the covariate effects on earnings, as soon as one covariate is continuous." (p. 0)
- **Methodological:** "We propose a three-stage semiparametric estimation procedure for this model, which yields root- $n$  consistent and asymptotically normal estimators." (p. 0)
- **Methodological:** "The first one is based on exclusion restrictions. It requires either a “standard” instrument, i.e. a variable affecting the selection probability but not the potential earnings, or sector-specific variables à la [Heckman and Sedlacek (1985, 1990)]." (p. 1)
- **Methodological:** "The second strategy builds on an argument at infinity for the potential outcomes, relying on a result from a companion paper ([D'Haultfeuille and Maurel, 2013])." (p. 1)
- **Methodological:** "Apart from identification, we propose a three-stage semiparametric estimation procedure under an index restriction on the effects of covariates. The first two stages allow us to estimate the covariate effects on potential earnings and correspond to [Newey's method (2009)] for estimating semiparametric selection models." (p. 1)
- **Methodological:** "**Assumption 2.2.** For all  $x_{-1}$  in the support of  $X_{-1}$ , the distribution of  $X_1$  conditional on  $X_{-1} = x_{-1}$  is continuous and  $T(\cdot, x_{-1})$  and  $G(\cdot, x_{-1})$  are differentiable on the support of  $X_1$  conditional on  $X_{-1}$ ." (p. 2)
- **Methodological:** "**Assumption 2.3 (Restrictions on the Errors, 1).**  $E(|\varepsilon_k|) < \infty$  for  $k \in \{0, 1\}$ . The distribution of  $\eta_\Delta$  admits a continuous density  $f_{\eta_\Delta}$  with respect to the Lebesgue measure and for all  $u \in \mathbb{R}$ ,  $f_{\eta_\Delta}(u) > 0$ ." (p. 2)
- **Methodological:** "**Assumption 2.4.** For all  $x_{-1}$  in the support of  $X_{-1}$ , the set  $\{x_1 : \frac{\partial(T+G)}{\partial x_1}(x_1, x_{-1}) \neq 0\}$  is not empty." (p. 3)
- **Methodological:** "**Assumption 2.5 (Normalization).** There exists  $x^*$  in the support of  $X$  such that  $\psi_0(x^*) = \psi_1(x^*) = 0$ ." (p. 4)
- **Methodological:** "**Assumption 2.6 (Exclusion Restrictions).**  $\psi_0$  (resp.  $\psi_1$ ) depends only on  $\bar{X}_0 \subset X$  (resp. on  $\bar{X}_1 \subset X$ ). Moreover,  $\bar{X}_0$  (resp.  $\bar{X}_1$ ) and  $P(D = 1|X)$  are measurably separated, that is, any function of  $\bar{X}_0$  (resp. of  $\bar{X}_1$ ) almost surely equal to a function of  $P(D = 1|X)$  is almost surely constant." (p. 4)
- **Methodological:** "**Assumption 2.7 (Restrictions on the Errors, 2).** (i)  $X \perp\!\!\!\perp (\varepsilon_0, \varepsilon_1)$ , (ii) for  $k \in \{0, 1\}$ , the supremum of the support of  $\varepsilon_k$  is infinite and there exists  $b_k > 0$  such that  $E(\exp(b_k \varepsilon_k)) < \infty$ , and (iii) for all  $u \in \mathbb{R}$, $$\lim_{v \rightarrow \infty} P(\eta_k - \eta_{1-k} > u | \eta_k + v_k = v) = 1, \quad k \in \{0, 1\}.$$" (p. 4)
- **Methodological:** "We therefore restrict in the estimation part (Section 3) to the case where exclusion restrictions are available." (p. 5)
- **Methodological:** "we focus here on semiparametric estimation in order to provide root- $n$  consistent and asymptotically normal estimators of  $\psi_0$ ,  $\psi_1$  and  $G$ ." (p. 6)
- **Methodological:** "Assumption 3.1 (Exclusion Restrictions). There exists  $j_1$  and  $j_2$  such that  $\beta_{0j_1} = \beta_{1j_2} = 0$ ,  $\gamma_{0j_1} \neq \beta_{1j_1}$  and  $\gamma_{0j_2} \neq -\beta_{0j_2}$." (p. 6)
- **Methodological:** "Assumption 3.2 (Regularity of  $X$ ). The support of  $X$  is bounded and not contained in a proper subset of  $\mathbb{R}^p$ . For all  $x_{-1}$  in the support of  $X_{-1}$ , the distribution of  $X_1$  conditional on  $X_{-1} = x_{-1}$  admits a continuously differentiable and positive density on its support, which is a compact interval independent of  $x_{-1}$ . Besides,  $\beta_{11} - \beta_{01} - \gamma_{01} \neq 0$." (p. 6)
- **Methodological:** "Assumption 3.3 (i.i.d. Sample). We observe a sample  $(Y_i, X_i, D_i)_{1 \leq i \leq n}$  of i.i.d. copies of  $(Y, X, D)$." (p. 6)
- **Methodological:** "We propose a three-stage estimation procedure of the model, where we estimate first  $\zeta_0$ , then  $(\beta_0, \beta_1)$  and finally  $(\delta_0, \gamma_0)$." (p. 6)
- **Methodological:** "First, we estimate  $\zeta_0$  by a single index estimator  $\hat{\zeta}$ , for which we suppose Assumption 3.4 below to be satisfied. This is the case of many semiparametric estimators, such as the one of Klein and Spady (1993) or Ichimura (1993). Secondly, we estimate  $\beta_0$  and  $\beta_1$  by series estimator" (p. 6)
- **Methodological:** "The regressors  $D$  and  $V$  are endogenous since selection  $D$  depends both on  $U$  and  $\tilde{\eta}_\varepsilon$ . We therefore use an IV estimator of  $\theta_0$  with functions of the index  $U$  as instruments for  $D$  and  $V$." (p. 7)
- **Methodological:** "To avoid boundary effects, we include some trimming by considering feasible versions of the instruments  $Z = \mathbb{1}\{X \in \mathcal{X}\}h(U)$" (p. 7)
- **Methodological:** "Assumption 3.6 (Restrictions on The Kernel).  $K(\cdot)$  is nonnegative, zero outside a compact set, continuously twice differentiable on this compact set and satisfies  $\int K(v)dv = 1$  and  $\int vK(v)dv = 0$. Moreover,  $K(\cdot)$  and  $K'(\cdot)$  are zero on the boundary of this compact set." (p. 7)
- **Methodological:** "Theorem 3.1. Suppose that  $nh_n^6 \rightarrow \infty$ ,  $nh_n^8 \rightarrow 0$ and that Assumptions 2.1, 2.3, 2.4 and 3.1–3.7 hold. Then  $\sqrt{n}(\hat{\theta} - \theta_0) \rightarrow \mathcal{N}\left(0, E(ZW')^{-1}V(Z\xi + \Omega_{11} + \Omega_{21})E(WZ')^{-1}\right)$" (p. 7)
- **Methodological:** "Once  $\delta_0$  and  $\alpha_0$  have been estimated, we can also estimate bounds on the distribution of the *ex ante* returns  $\Delta$, namely  $F_\Delta(u) = E[F_{\eta_\Delta}(u + X'(\beta_0 - \beta_1))]$." (p. 7)
- **Methodological:** "We use for the first step a mixture of probit (see Coppejans, 2001) with  $K_1 = 3$  mixture components. The second step is performed with Newey (2009)'s series estimator, with  $K_2 = 9$  approximating terms." (p. 8)
- **Methodological:** "to estimate  $h$  bounds on the distribution of the *ex ante* returns, we consider a kernel estimator of  $F_{\eta_\Delta}$  with a Gaussian kernel, and a bandwidth  $\hat{h}_n = 1.6\sigma(\hat{U})n^{-1/5}$." (p. 8)
- **Methodological:** "Standard errors, presented in parentheses, were computed by bootstrap with 200 replications." (p. 9)
- **Methodological:** "we add in the regressors the local proportion of individuals who graduated from high school with honors. This variable, computed from the Panel 1989 dataset (French Ministry of Education), is used to control for differences across *départements* in productivity levels." (p. 10)
- **Methodological:** "We assume that  $\eta_\Delta$  and  $U$  are independent and normally distributed, respectively with mean  $m$  and 0." (p. 10)
- **Methodological:** "Our main theoretical contribution is to show that we can identify these non-pecuniary factors, and provide informative bounds on the distribution of the *ex ante* monetary returns, without any exclusion restriction nor large support condition on the covariates." (p. 10)
- **Methodological:** "We also develop a three-stage semiparametric estimation procedure leading to a root- $n$  consistent and asymptotically normal estimator of the non-pecuniary component." (p. 10)

## Gaps and limitations

The point-identification result for $G$ requires at least one continuous covariate; with fully discrete covariates only bounds are available. Point identification of the ex ante return distribution requires large support of $T(X)+G(X)$; otherwise only bounds are obtained. Although $\psi_0$ and $\psi_1$ can be identified without exclusion restrictions through identification at infinity, no estimator for that strategy has yet been developed and the estimation section restricts to the exclusion-restriction case. The empirical application drops dropouts and temporary workers, conflating attendance with later labor-market participation. The misspecification exercise considers only the Gaussian generalized-Roy alternative. The authors flag general vs. specific human capital and dependence between sector-specific unobserved productivities, connected to competing-risks methods, as future work rather than something delivered here.
