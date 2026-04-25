# Asymptotic equivalence: trajectory-pooled vs worker-level robust LCA estimators

**Date:** 2026-04-25
**Context:** [run_grc_robust_vv](file:///C:/git/ckt/RP7/scripts/0_programs.do) (CKT, trajectory-pooled, cluster-demeaned switcher$\times$choice instruments) and the worker-level estimator from Verdier (2020) Table 1 [robust.do](file:///C:/git/ckt/tmp/vv-replication/replication_archive/Table1/Code/robust.do) (Chamberlain projection + village-demeaned period-treatment instruments) are claimed to estimate the same scalar $\phi$. This memo states the assumptions, the population parameter, and proves consistency of both. A companion simulation tests the claim numerically.

## 1. Setup

Data: panel of workers $i = 1, \ldots, N$, time periods $t = 1, \ldots, T$, clusters $v_i \in \{1, \ldots, V\}$ (time-invariant: first-wave province), trajectories $d_i \in \mathcal{D}$ (time-invariant: full sequence of $D_{it}$).

Outcome model:
$$y_{it} = \alpha_i + \Delta_i\, D_{it} + x_{it}'\gamma + u_{it} \qquad (1)$$
$\alpha_i$ worker-level intercept (rural productivity), $\Delta_i$ worker-level treatment effect, $u_{it}$ idiosyncratic mean-zero given $(\alpha_i, \Delta_i, D_{it}, x_{it})$.

LCA at the worker level (Verdier 2020 robust extrapolation):
$$\Delta_i = \beta(v_i) + \phi\, \theta_i + \xi_i \qquad (2)$$
$\theta_i$ comparative advantage (rescaled), $\beta(v)$ cluster-specific intercept, $\xi_i$ deviation from LCA with $E[\xi_i \mid v_i, D_{i1}, \ldots, D_{iT}] = 0$ (Verdier's Assumption A2').

## 2. Assumptions

**A1 (LCA).** Equation (2) holds.

**A2' (within-cluster exogeneity).** $E[u_{it}, \xi_i \mid v_i, D_{i1}, \ldots, D_{iT}, x_{i1}, \ldots, x_{iT}] = 0$. Treatment can correlate with worker types ACROSS clusters but is exogenous within cluster.

**A3 (trajectory pooling).** Conditional on trajectory $d_i$, the distribution of $\theta_i$ is the same across clusters:
$$E[\theta_i \mid d_i = s, v_i = v] = E[\theta_i \mid d_i = s] \equiv m_s \qquad (3)$$
This is what CKT's pooling buys.

**A4 (regularity).** Standard moment-existence and identification conditions: $E[(D_{it} - E[D_{it} \mid v_i, d_i = s])^2 \mid d_i = s] > 0$ for some $s$, etc. Within-cluster variation in treatment is non-trivial.

## 3. The two estimators

### 3.1 Worker-level (Verdier)

Step 1, Chamberlain projection: fit $y_{it} = \mu_{i, D_{it}} + x_{it}'\gamma + e_{it}$ via OLS with $(\text{pid}_i, D_{it})$ fixed effects absorbed. Recover the FE estimate $\hat\mu_{i, d}$ for $d \in \{0, 1\}$, define $\hat a_i = \hat\mu_{i,0}$ and $\hat b_i = \hat\mu_{i,1} - \hat\mu_{i,0}$.

Step 2, instrument construction: for each period $t$, regress $D_{it}$ on $\mathbb{1}\{v_i\}$ among switchers; residual is $\tilde D_{it}^{\text{vv}}$.

Step 3, worker-level 2SLS:
$$\hat a_i = \alpha_0 + \alpha_1 \hat b_i + \varepsilon_i^{\text{vv}}, \qquad E[\tilde D_{it}^{\text{vv}} \cdot \varepsilon_i^{\text{vv}}] = 0 \qquad (4)$$
The estimator is $\hat\alpha_1^{\text{vv}}$, and we identify $\alpha_1 = 1/\phi$ at the population (VV's LCA convention reverses the regression direction relative to CKT; see §7.5).

### 3.2 Trajectory-pooled (run_grc_robust_vv)

Trajectory pooling collapses workers to per-trajectory means $\mu_d = E[\alpha_i \mid d_i = d]$. The GMM moment equation (under A1, A3) takes the population-level form
$$y_{it} = \sum_{d \in \mathcal{D}} \mu_d \mathbb{1}\{d_i = d\} + \Delta_{d_0} D_{it} + \phi \!\!\!\!\sum_{d \in \mathcal{D}_S \setminus d_0} \!\!\! (\mu_d - \mu_{d_0}) \mathbb{1}\{d_i = d\} D_{it} + \kappa\text{-term} + x_{it}'\gamma + \varepsilon^{\text{ckt}}_{it} \qquad (5)$$
with cluster-demeaned switcher$\times$choice instruments
$$\text{swd}_{s, it} = \mathbb{1}\{d_i = s\} (D_{it} - \bar D_{s, v_i}) \qquad (6)$$
where $\bar D_{s,v} = E[D_{it} \mid d_i = s, v_i = v]$. Moment conditions:
$$E[\text{swd}_{s, it} \cdot \varepsilon^{\text{ckt}}_{it}] = 0 \quad \forall s \in \mathcal{D}_S \setminus d_0 \qquad (7)$$
The estimator is $\hat\phi^{\text{robust\_vv}}$.

## 4. Population parameter

The two estimators target related but distinct scalars. The trajectory-pooled estimator targets:
$$\phi_0 \;=\; \text{the LCA slope in (2)} \qquad (8)$$
The worker-level VV estimator targets $1/\phi_0$, because VV's moment regresses $a$ on $b$ (opposite direction to CKT's LCA). Both scalars are one-to-one functions of the same underlying LCA slope; they are equivalent up to inversion. Different aggregations of the data, same population restriction (up to the directional convention).

## 5. Consistency of the worker-level estimator

**Lemma 1.** Under A1, A2', A4, $\hat\alpha_1^{\text{vv}} \xrightarrow{p} 1/\phi_0$ as $N \to \infty$.

**Proof sketch.** Plug the true model into the 2SLS moment. The Chamberlain projection asymptotically recovers worker-level objects:
$$\hat a_i \xrightarrow{p} \alpha_i, \qquad \hat b_i \xrightarrow{p} \Delta_i = \beta(v_i) + \phi_0 \theta_i + \xi_i$$
(noise vanishes as $T$ grows, or as the within-pid sample size grows; for finite $T$ the estimates are unbiased given enough switchers).

The 2SLS regression $a_i = \alpha_0 + \alpha_1 b_i + \varepsilon_i$ uses $\tilde D_{it}^{\text{vv}}$ as instrument. Under A2',
$$E[\tilde D_{it}^{\text{vv}} \cdot \xi_i] = E[E[\tilde D_{it}^{\text{vv}} \mid v_i] E[\xi_i \mid v_i]] = 0$$
since $\tilde D_{it}^{\text{vv}}$ is mean-zero within $v_i$ by construction and $\xi_i$ is also mean-zero within $v_i$ under A2'. Provided $\tilde D_{it}^{\text{vv}}$ has non-trivial variance among switchers (A4), the 2SLS/GMM identifies $\alpha_1 = 1/\phi_0$: because VV's LCA equation regresses $a$ on $b$ (the reverse of CKT's direction), the identified coefficient is the reciprocal of the CKT slope (see §A.1 of the Phase A derivations for the full algebra). $\blacksquare$

## 6. Consistency of the trajectory-pooled estimator

**Lemma 2.** Under A1--A4, $\hat\phi^{\text{robust\_vv}} \xrightarrow{p} \phi_0$ as $N \to \infty$ (with $V \to \infty$ if cluster-asymptotic regularity is invoked, or fixed $V$ with $N_v / V \to \infty$).

**Proof sketch.** Equation (5) is the population analog of CKT's moment equation under A1, A3. Specifically:

Plug worker-level (1), (2), and A3 into the trajectory-pooled residual:
$$\varepsilon^{\text{ckt}}_{it} = y_{it} - \mu_{d_i} - \Delta_{d_0} D_{it} - \phi (\mu_{d_i} - \mu_{d_0}) D_{it} \mathbb{1}\{d_i \in \mathcal{D}_S \setminus d_0\} - \cdots$$
For a switcher-$s$ worker:
$$\varepsilon^{\text{ckt}}_{it} = \alpha_i - \mu_s + (\Delta_i - \Delta_{d_0} - \phi(\mu_s - \mu_{d_0})) D_{it} - x_{it}'\gamma + u_{it}$$
Under A1 + A3:
$$\Delta_i - \Delta_{d_0} = \beta(v_i) + \phi \theta_i + \xi_i - \beta(v_{d_0}) - \phi \theta_{d_0} - \xi_{d_0}$$
The LCA slope component is $\phi (m_s - m_{d_0})$ when conditioned on trajectories (using A3's $E[\theta_i \mid d_i = s] = m_s$). Identifying $\mu_s - \mu_{d_0}$ with $m_s - m_{d_0}$ (rescaled appropriately) and $\Delta_{d_0} = \beta(v_{d_0}) + \phi \cdot m_{d_0}$ at the population, the residual reduces to:
$$\varepsilon^{\text{ckt}}_{it} = (\alpha_i - \mu_s) + (\beta(v_i) - \beta(v_{d_0}))D_{it} + \phi(\theta_i - m_s)D_{it} + \xi_i D_{it} + u_{it}$$

Now compute the moment $E[\text{swd}_{s, it} \cdot \varepsilon^{\text{ckt}}_{it}]$:

- $E[\text{swd}_{s, it} \cdot (\alpha_i - \mu_s)] = 0$ because $\text{swd}_{s, it}$ has mean zero given $(d_i = s, v_i)$ (by demeaning within cluster) and $E[\alpha_i - \mu_s \mid d_i = s, v_i = v] = 0$ under A3.
- $E[\text{swd}_{s, it} \cdot (\beta(v_i) - \beta(v_{d_0})) D_{it}]$: $\text{swd}_{s, it}$ is mean-zero within $(s, v)$, and $\beta(v_i)$ is constant within cluster, so this term equals zero by within-cluster demeaning.
- $E[\text{swd}_{s, it} \cdot \phi(\theta_i - m_s) D_{it}]$: under A3, $E[\theta_i - m_s \mid d_i = s, v_i = v] = 0$, so this term is zero.
- $E[\text{swd}_{s, it} \cdot \xi_i D_{it}] = 0$ under A2' (treatment exogenous to $\xi_i$ within cluster).
- $E[\text{swd}_{s, it} \cdot u_{it}] = 0$ under A2' applied to $u$.

Hence the moment condition (7) holds at $\phi = \phi_0$. Standard GMM consistency arguments (Hansen 1982, Theorem 2.1) give $\hat\phi^{\text{robust\_vv}} \xrightarrow{p} \phi_0$ provided rank conditions are satisfied (A4). $\blacksquare$

## 7. Asymptotic equivalence

**Theorem 1.** Under A1--A4, $\hat\alpha_1^{\text{vv}}$ is consistent for $1/\phi_0$ and $\hat\phi^{\text{robust\_vv}}$ is consistent for $\phi_0$. The two estimators report reciprocal scalars of the same population LCA slope; they are equivalent up to this one-to-one transformation.

**Proof.** Combine Lemmas 1 and 2. The population parameter solving the trajectory-pooled moment system (7) is $\phi_0$ (Lemma 2). The population parameter solving VV's worker-level moment (4) is $1/\phi_0$ (Lemma 1), because VV's LCA equation reverses the regression direction relative to CKT. Since $\phi_0 \mapsto 1/\phi_0$ is a bijection, both estimators are consistent for the same underlying LCA relationship. $\blacksquare$

**Equivalence in distribution.** The two estimators are consistent for reciprocal population scalars ($\phi_0$ and $1/\phi_0$ respectively) and their asymptotic VARIANCES differ in general. The worker-level estimator uses worker-level residuals from a Chamberlain projection; the trajectory-pooled estimator pools moments at the trajectory level. Under standard cluster asymptotics, both achieve $\sqrt{V}$-rate convergence (clustering at $v$ in both cases) but with cluster-specific variance functions that depend on the within-cluster cross-distribution of trajectories. In general:

$$\sqrt{V} \, (\hat\phi - \phi_0) \xrightarrow{d} N(0, \Omega^{(\cdot)})$$

with $\Omega^{\text{vv}} \neq \Omega^{\text{robust\_vv}}$ in general. The two estimators trade off efficiency differently when within-cluster trajectory composition is heterogeneous.

## 7.5 Convention note

VV's paper (footnote 19, line 234 of the published version) writes the LCA as $a_i = a_0 + a_1 b_i + e_i$, regressing rural productivity $a$ on the treatment effect $b$. CKT (following Suri 2011) writes the LCA in the reverse direction: $\Delta_i = \beta + \phi\theta_i + \xi_i$, regressing the treatment effect $\Delta$ on comparative advantage $\theta$. Under both conventions the economic content is identical---the LCA captures how returns vary with pre-treatment productivity---but the reported slope coefficient is reciprocal: $a_1^{\text{VV}} = 1/\phi^{\text{CKT}}$.

In empirical work, one must therefore either invert VV's $\hat\alpha_1$ before comparing it to CKT's $\hat\phi$ (report $1/\hat\alpha_1^{\text{vv}}$), or run VV with the reverse moment $E[z \cdot (b - \gamma_0 - \gamma_1 a)] = 0$, which targets $\phi$ directly (see Phase A derivations §A.1, equation 5).

## 8. Where the equivalence breaks: failure of A3

If trajectory pooling (A3) fails --- i.e., $E[\theta_i \mid d_i = s, v_i = v]$ depends on $v$ --- then the trajectory-pooled moment (7) does NOT hold at $\phi_0$. The bias is the alpha-pooling bias derived in [2026-04-24_alpha-pooling-derivation.md](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-derivation.md):

$$\hat\phi^{\text{robust\_vv}} - \phi_0 \;=\; -\frac{\mathrm{Cov}_s(\bar\beta(s),\, m_s - m_{d_0})}{\mathrm{Var}_s(m_s - m_{d_0})} + o_p(1)$$

where $\bar\beta(s) = \sum_v \tilde w(s, v) \beta(v)$ is the $s$-tilted cluster average. The worker-level VV estimator does NOT face this bias because it doesn't aggregate over workers within a trajectory; its only assumption is A2' + within-cluster identification.

So:
- Under A3: the two estimators are equivalent (consistent for $\phi_0$ and $1/\phi_0$ respectively; same underlying relationship up to inversion).
- Without A3: VV remains consistent for $1/\phi_0$; trajectory-pooled is biased for $\phi_0$. Under A3 failure, VV's $\hat\alpha_1$ also inherits a bias, which maps to a bias in the implied $\hat\phi^{\text{VV}} = 1/\hat\alpha_1^{\text{vv}}$---the inversion propagates the bias nonlinearly.

This is exactly what the [empirical TV diagnostic](file:///C:/git/ckt/docs/reviews/2026-04-24_alpha-pooling-diagnostic-results.md) tests (whether $\bar\beta(s)$ varies meaningfully across $s$).

## 9. Caveats and gaps in this proof

- The Chamberlain projection in step 5 assumes $T \to \infty$ for the worker-level objects to converge cleanly. For finite $T$ with limited switching, $\hat a_i$ and $\hat b_i$ are noisy estimates of population objects; consistency of the worker-level 2SLS still holds because the noise is mean-zero given the instruments, but with reduced efficiency.
- Cluster asymptotics: I asserted $V \to \infty$ for cluster-robust SE consistency. With fixed $V$, both estimators are still consistent if $N_v / V \to \infty$ (large clusters), but the asymptotic distribution requires care.
- Multi-switch trajectories: in CKT, a worker can have $D_{it}$ trajectories like RURU. The Chamberlain projection treats this as a "treated" indicator collapsed across periods, possibly losing efficiency. Doesn't affect consistency.
- Always-urban / never-urban subpopulations: identified by extrapolation in both approaches; not a consistency issue for $\phi$ itself.
- The proof shows consistency, NOT asymptotic equivalence in distribution. The two estimators have different asymptotic variances.

## 10. What the simulation tests

The simulation in [explorations/verdier/x_equivalence_simulation.do](file:///C:/git/ckt/explorations/verdier/x_equivalence_simulation.do) (companion file) generates synthetic panel data under A1, A2', A3, then computes both estimators. Across replications, we test:

1. **Both consistent for their respective population scalars ($\phi_0$ and $1/\phi_0$) when A3 holds.** Bias should be $o(1)$ at $N = 5000$ workers; the simulation should report both $\hat\alpha_1$ and $1/\hat\alpha_1$ for direct comparison with CKT's $\hat\phi$.
2. **Verdier consistent, trajectory-pooled biased when A3 fails.** Add a deterministic shift $E[\theta_i \mid s, v] = m_s + \delta_{s,v}$ with $\delta$ varying across $(s, v)$. Bias in trajectory-pooled phi should match the alpha-pooling formula.
3. **Asymptotic variance comparison.** Whose SE is smaller, and under what conditions?
4. **Behavior with sparse switcher cells**, multi-switch trajectories, small $V$.

Empirical pattern from the diagnostic --- TZA agrees, IDN diverges --- can be reproduced in simulation by tuning the cluster-distribution heterogeneity across switchers.
