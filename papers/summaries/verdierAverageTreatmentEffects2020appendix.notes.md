# Notes: Verdier (2020) online appendix

Citekey: verdierAverageTreatmentEffects2020appendix
Extraction caveat: formula VLM disabled; 0 formulas detected. Every blank-line gap between prose fragments likely hid an equation. Flagged below as `[EQUATION MISSING from extraction]` (EM for short).

## Chunk 1 (pp. 1-22): sections A-E intro

### Structure / TOC
- Appendix A: identification with general T
- Appendix B: map to Lemieux (1998) and Suri (2011) notation; show both methods implement the linear extrapolation from movers to stayers
- Appendix C: comparison of the extrapolation identifying assumption with generalized Roy models (Carneiro, Hansen, Heckman 2003)
- Appendix D: CRC model with time-varying treatment effects
- Appendix E: two-step estimation and inference under the simple extrapolation IA; E.1 high-dimensional step-1 regression; E.2 step-2 IV / extrapolation; E.3 testing validity (not testable with T=2; testable with T >= 3)
- Appendix F: estimation with generalized extrapolation IA
- Appendix G: unbalanced panels (MAR)
- Appendix H: proofs of Propositions 1-8
- Appendix I: learning about treatment effects upon treatment and its effect on validity of the CRC / extrapolation assumptions

### Section A: general T identification
- Stacks CRC model Y_i = W_i [a_i; b_i] + f + U_i where W_i = [j_T, X_i]. EM after "rewrite the CRC model (2.4) as:" (p. 5).
- Information equivalent to projecting with M_{W_i} = I_T - W_i (W_i' W_i)^- W_i'. EM again (p. 5).
- With normalization f_1 = 0, time effects f_t identified if rank(M_{W_i}) > T-1 for some X_i with positive probability. For stayers M_{W_i} is the projection off a constant over T observations so rank = T - 1, yielding identification of time effects from stayers.
- With T=2, M_{W_i} = 0 for movers; with T >= 3, rank(M_{W_i}) >= T - 2 > 0 and movers contribute to identifying time effects. With T >= 3 all f_t can potentially be identified from movers only.
- "conditional average treatment effect E(b_i | X_i) is only identified for cross-sectional observations such that W_i' W_i is non-singular. With x_it being binary, W_i' W_i is non-singular for movers and singular for stayers, so that average treatment effects are only identified for movers." (p. 6)

### Section B: relating to Lemieux (1998) and Suri (2011)
- Both are shown to implement the *linear extrapolation* depicted in Figure 1 of the main text (from mover ATEs to stayer ATEs) when treatment is the only covariate.
- Mapping Lemieux notation to main text notation: f_t = delta_t^N, a_i = theta_i^N, b_i = bar{delta} + theta_i^U - theta_i^N, u_it = epsilon'_it.
- Lemieux's extrapolation is a linear-projection assumption: theta_1^N and theta_1^U projected linearly on (theta_i^N - theta_i^U). Coefficients b^N and b^U map to main-text alpha_1 and alpha_1 + 1.
- Suri (2011) uses minimum distance; parameter phi (= psi - 1, i.e. phi = 1/alpha_1) and beta = E(b_i).
- Both yield the same pseudo-true parameters under the CRC model alone: alpha_1* = [E(a_i|0,1) - E(a_i|1,0)] / [E(b_i|0,1) - E(b_i|1,0)] and alpha_0* = E(a_i|1,0) - alpha_1* E(b_i|1,0). ATE for entire population then recovered by linear extrapolation (Figure 1 of main text).
- Suri's seven reduced-form moments (B.13)-(B.19) are at most exactly identifying for six structural parameters under the CRC model; when phi = -1 the extrapolation line and the a+b = const line have the same slope and beta, lambda_0, lambda_3 are not identified, so stayer-return estimators have no probability limit.
- Footnote 2: ATE* for untreated stayers = E(a_i|0,0) - alpha_0*/alpha_1*; ATE* for treated stayers = E(a_i + b_i|1,1) - alpha_0* / (1 + alpha_1*).

### Section C: comparison with generalized Roy
- Uses Carneiro, Hansen, Heckman (2003, p. 365-6) framework. Potential outcomes y(1), y(0) with common factor theta and shocks epsilon_0, epsilon_1, epsilon_s; selection x.
- Defines a = beta_{0,0} + beta_{1,0} theta + epsilon_0 and b = (beta_{0,1} - beta_{0,0}) + (beta_{1,1} - beta_{1,0}) theta. If beta_{1,1} - beta_{1,0} != 0, then a = linear function of b plus epsilon_0, giving condition (2.12) of main text.
- Condition (2.13) holds with c = epsilon_s under independence of epsilon_s and theta.
- Roy-model identification usually requires instruments / proxies / repeated measurements of theta; here the CRC restriction (2.4) alone yields identification.

### Section D: CRC with time-varying treatment effects
- Model: outcome equation with b_it allowed to vary over t. EM at (D.1).
- Identification of differences in time effects requires pairs of periods where the *same cross-section was untreated in both*; cannot use treated-in-both comparisons as in the main text.
- ATE for currently-treated movers identified by DID.
- Average baseline heterogeneity identified for movers and untreated stayers; total heterogeneity at each t identified for treated movers and treated stayers (but not ATE for currently-untreated movers or for stayers).
- Proposed extrapolation IA (D.4)-(D.6): single unobserved e_i determines both baseline a_i and treatment effect b_it (with time-varying loading beta_{1,t}); treatment status depends on e_i only, not directly on b_it. Intuition: the shocks nu_{t,i} to b_it must be unforecastable at the time of selection.
- Yields alpha_{0,t} = beta_{0,a} - beta_{0,t} beta_{1,t} and alpha_{1,t} = beta_{1,a}/beta_{1,t} (well defined if beta_{1,t} != 0).
- Step 2 becomes IV regression of hat{a}_i on hat{b}_it using treatment history as instruments, but restricted to movers treated at time t. Requires at least T = 3 so multiple such mover groups exist.
- ATE for untreated movers and stayers identified from EM (p. 19) if alpha_{1,t} not in {-1, 0}.
- Extension allowing dynamic effects: include x_{i,t-1} in the IA (D.9). Yields alpha_{1,t}(x_{i,t-1}) = beta_{1,a}/(beta_{1,t} + beta_3 x_{i,t-1}) etc.
- Caveat (p. 21): these extensions are noisier and demand much larger samples; author defers detailed treatment to future work.

### Section E intro (pp. 21-22)
- Considers models with general controls z_it (IV regression set-up). Special case z_it = [1[t = s]]_{s=2..T} gives the main-text CRC model with f_1 = 0 normalization. EM at (E.1)-(E.2) equations.
- Asymptotics: n large, T fixed. Cross-sectionally independent (extends to independent clusters as in the empirical application).

### Verbatim fragments worth preserving (chunk 1)
- "conditional average treatment effect E(b_i|X_i) is only identified for cross-sectional observations such that W_i'W_i is non-singular. With x_it being binary, W_i'W_i is non-singular for movers and singular for stayers, so that average treatment effects are only identified for movers." (p. 6)
- "When phi = -1, the system linking reduced form parameters to structural parameters does not identify lambda_3, so that beta, lambda_0, lambda_3 are not identified, so that the probability limits of the estimators for average returns for stayers do not exist." (p. 13)
- "In practice this will imply that estimation results will be significantly more noisy than using the methods developed in the main text, and will require researchers to have access to larger datasets than what is used in the empirical application of the main text." (p. 21, on time-varying b_it)

## Chunk 2 (pp. 22-45): Section E in detail + Section F + Section G

### Section E.1: Step 1 high-dimensional regression
- Step 1 regresses y_it on z_it, cross-sectional indicators, and cross-sectional indicators x x_it. By Frisch-Waugh, hat{gamma} uses M_{W_i} = I_T - W_i (W_i' W_i)^- W_i' with generalized inverse that drops the treatment interaction for stayers (no within variation).
- Yields: consistent gamma; noisy a_i and b_i for movers; noisy a_i for untreated stayers; noisy (a_i + b_i) for treated stayers.
- **Assumption 7:** cross-sectional independence (implied by main-text Assumption 1).
- **Assumption 8** (moment / regularity, p. 23):
  - (a) support of a_i, b_i, z_it, u_it is compact;
  - (b) non-vanishing share of stayers observed;
  - (c), (d) variation in z_it and u_it over time among stayers. Condition on stayers (not all i) is needed so that step-1 error is not approximately linearly dependent with the part of the step-2 influence function that is independent of step 1; this guarantees step 2 is at most sqrt(n)-consistent (not super-consistent).
- Assumption 8 is implied by main-text Assumptions 1-2 when T=2 and z_it = 1[t=2].

### **Proposition 4** (consistency / asymptotic noise of step 1, pp. 24-25)
- As n -> infty, T fixed:
  - sqrt(n)(hat{gamma} - gamma) is asymptotically normal with sandwich V_{n,gamma,0} / A_{n,gamma,0}, where A = E(Z_i' M_{W_i} Z_i) average and V = Var(Z_i' M_{W_i} U_i) average (p. 24).
  - For movers (exists t,s with x_it != x_is): hat{a}_i - a_i and hat{b}_i - b_i decompose into a term driven by zeta_{ab,n} = (1/sqrt{n}) sum Z_i' M_{W_i} U_i = O_p(1) plus e_{i,n} with max_i |e_{i,n}| = o_p(1/sqrt{n}). I.e. noise has a non-vanishing idiosyncratic part plus a sqrt(n)-vanishing estimation-of-gamma contribution.
  - For untreated stayers (x_it=0 all t) and treated stayers (x_it=1 all t), analogous expressions (EM blocks on pp. 24-25).
- "Proposition 4 shows that the estimator for gamma is sqrt(n)-consistent and asymptotically normal. It also shows that the estimation noise of the heterogeneity terms a_i and b_i is decomposed into idiosyncratic noise that would arise even if gamma were known and vanishing noise originating from the estimation of gamma which is dominated by a term of order 1/sqrt(n)." (p. 25)
- Proposition 1 of main text is a special case of Proposition 4.

### Section E.2: Step 2 IV regression and extrapolation (pp. 25-28)
- Step 2: GMM regression of hat{a}_i on hat{b}_i (instruments = treatment history tilde{X}_i, restricted to movers M_n).
- tilde{X}_i = [1, (x_it)_{t in S}] where S is a largest subset of periods with {x_it}_{t in S} linearly independent among movers. For T=2: |S|=1 (exactly identified). For T > 2 with both treatments represented every period, S = {1,...,T}.
- **GMM estimator**: (hat{alpha}_0, hat{alpha}_1)' solves a GMM criterion with weighting Sigma_n. EM block at (E.4)-ish.
- Footnote 3 (p. 26): "We consider GMM estimation for a potential efficiency gain because of the heteroscedasticity in hat{a}_i - alpha_0 - alpha_1 hat{b}_i conditional on X_i that is likely to exist because of measurement error. Indeed heteroscedasticity is likely to appear in the non-vanishing part of the estimation noise in the estimates hat{a}_i and hat{b}_i." Even under homoscedastic (epsilon_i, U_i), the projected residuals are heteroscedastic.
- **Relevant for CKT — optimal instruments flavor:** the paper's step-2 GMM with efficient weighting is exactly the class from which z_opt = Z W Z' X arises, but the explicit "z_opt = Z W Z' x" formula is **not** derived verbatim in this chunk (and no such statement appears). The paper just refers to Newey and Windmeijer (2009) to caution against many-moment GMM.
- Plug-in: hat{ATE}_{S,0}, hat{ATE}_{S,1} via main-text formulas using hat{alpha}_0, hat{alpha}_1.
- **Assumption 9** (identification + rank, p. 27):
  - (a) min eigenvalue of Sigma_{n,0} >= c for n >= C. Requires variation in X_i among movers. With T=2 this reduces to (i) Var(v_i | X_i) >= c (non-degenerate IA error and CRC u_it), plus (ii) 0 < c <= P(x_i1=0, x_i2=1) <= 1-c and similarly for (1,0). **This is the support condition requiring non-vanishing mass on both switcher directions.**
  - (b) variation in X_i among movers is predictive of b_i: |E[b_i | (0,1)] pooled minus E[b_i | (1,0)] pooled| >= c > 0 — **relevance condition for the treatment-history instruments**, analogous to a standard IV first-stage strength condition.
  - (c) 2SLS estimators tilde{alpha}_0, tilde{alpha}_1 converge in probability; imposed for convenience, derivable from primitives.
  - (d) regularity to keep step-2 at most sqrt(n)-consistent (no super-consistency); essentially requires no approximate exact dependence between a_i (and a_i + b_i) and u_it.
- Assumption 9.a, 9.b, 9.d implied by main-text Assumptions 1-3. 9.c moot when T=2 (exactly identified).

### **Proposition 5** (asymptotic distribution of step 2, pp. 29-31)
- Defines deterministic matrices driving the limiting distribution (EM blocks on pp. 29-30 for (hat{alpha}_0, hat{alpha}_1), hat{ATE}_{S,0}, hat{ATE}_{S,1}).
- Main statement (p. 31): under (E.1), (E.2), Assumptions 7-9, as n -> infty, T fixed, the sqrt(n)-scaled estimators are asymptotically normal. When alpha_1 is not in {0, -1}, the corresponding ATE_{S,0} and ATE_{S,1} estimators are sqrt(n)-consistent and asymptotically normal.
- Proposition 2 of main text is a special case.
- Linear influence-function representation means cluster bootstrap (clusters = cross-sectional units) is asymptotically valid.

### **Proposition 6** (variance estimation / standard errors, pp. 31-32)
- Defines C_n = (1/n) sum_{i in M_n} tilde{X}_i [1, -hat{alpha}_1] (W_i' W_i)^{-1} W_i' Z_i; hat{r}_i = hat{a}_i - hat{alpha}_0 - hat{alpha}_1 hat{b}_i; hat{U}_i = Y_i - Z_i hat{gamma}. Sigma_n = (1/n) sum_{i in M_n} hat{r}_i^2 tilde{X}_i tilde{X}_i' (meat matrix, sandwich-clustered). Sigma_{n,gamma} = (1/n) sum Z_i' M_{W_i} hat{U}_i hat{U}_i' M_{W_i} Z_i. Sigma_{n,alpha gamma} = cross covariance (EM for exact form).
- Result: under (E.1), (E.2), and Assumptions 7-9, the plug-in sandwich variance is consistent for the asymptotic variance of hat{alpha}, accounting for the first-step estimation of gamma (EM on p. 32 for exact formula).
- Analytical SEs clustered at cross-sectional unit are computable from quantities standard software already stores; alternatively use numerical differentiation of exactly identifying moments.

### Section E.3: Testing the extrapolation IA
- **E.3.1 T=2: no testable implications.** "Under the CRC model and with two time periods, the extrapolation identifying assumption is equivalent to introducing identities for four parameters that were left unrestricted by the CRC model, so that the extrapolation identifying assumption does not contain testable implications under the CRC model." (p. 33). Shows one can always construct (tilde{a}_i, tilde{b}_i, tilde{xi}_i) to satisfy both CRC and IA given any CRC data.
- **E.3.2 T >= 3: Sargan-Hansen-like test.**
  - Test LP(a_i - alpha_0 - alpha_1 b_i | X_i, i in M_n) = 0. Equivalently E(tilde{X}_i (a_i - alpha_0 - alpha_1 b_i)) = 0 for each t in S.
  - Add |S| + 1 exactly identified moment conditions with nuisance parameters eta_0, eta_t; Wald-test H_0: eta_0 = 0, eta_t = 0 for all t in S. chi-squared with |S| - 1 (|S|1 in text looks like a typo) df.
  - With T=2 the test collapses (|S|=1).
  - Author frames it as an over-identification test like Sargan-Hansen J but adjusted for first-step estimation of gamma.
  - Alternative direct test of E(a_i - alpha_0 - alpha_1 b_i | X_i) = 0 has more power in large samples but suffers small-cell / size distortion in moderate samples.

### Section F: generalized extrapolation IA (village / indexing fixed effects)
- Model (F.1)-(F.2): extrapolation IA is a_i - alpha_1 b_i = e_{v_i} + alpha_0 + error with v_i an indexing variable (village in the empirical application). Cost shifters shared within v-groups can be correlated with (a_i, b_i).
- Exogeneity in (F.1) is strengthened to strict across all i with same v_i because cross-sectional independence is relaxed (below) to independence across v.
- Step 1 identical to Section E. For step 2, demean (hat{a}_i, hat{b}_i) within v among movers, then GMM.
- tilde{X}_i = [x_it]_{t in S} without the constant; fixed-effects 2SLS using demeaned variables.
- hat{e}_v estimator back-computed from the within-group residuals.
- ATE for stayers then recovered with a plug-in formula analogous to Section E.
- Setting: few cross-sectional observations per v (many villages with few farmers each) — mimics the empirical application.
- **Assumption 10:** observations independent across v; max group size uniformly bounded (max_i N_{v_i} <= C). Implied by main-text Assumption 4.
- **Assumption 11** (rank conditions in FE case, p. 38-):
  - (a) lambda_min(ddot{Sigma}_{n,0}) >= c with within-group variation in X_i among movers. T=2 sufficient conditions: within-v variance of r_i bounded below plus zero within-v covariance of r_i, r_j (independence across i within v) plus non-degenerate x variation within v.
  - Others (b)-(d) bound moments analogously to Assumption 9 but in the clustered environment.

### **Proposition 7** (asymptotic dist. in FE case, pp. 42-43)
- Under (F.1), (F.2), Assumptions 8, 10, 11: as n -> infty, T fixed, sqrt(n)(hat{alpha}_1 - alpha_1) is asymptotically normal (EM for variance).
- For alpha_1 not in {0, -1}, hat{ATE}_{S,0} and hat{ATE}_{S,1} are sqrt(n)-consistent and asymptotically normal.
- Proposition 3 of main text is a special case.
- Inference: cluster bootstrap at v or analytical SE clustered at v.

### **Proposition 8** (analytical SE consistency for FE case, pp. 43-44)
- Consistency of the analytical cluster-robust (at v) SE for hat{alpha}_1 accounting for first-step estimation.
- Same form of Sargan-Hansen-style overid test for the IA: include exactly identifying moment conditions with eta_t for t in S, Wald test with chi-squared(|S| - 1). Clustering at v.

### Section G: unbalanced panels (MAR)
- o_it = 1[observed]. If observed-ness is independent of all model variables, redefine Y_i, W_i, Z_i, X_i to keep only observed periods; redefine M_n as those with a within-observed-periods switch.
- Under MAR, E(Z_i' M_{W_i} U_i) = 0, so step 1 remains a pooled linear regression of y_it on unit indicators, unit x treatment, and z_it.
- Step 2 GMM moments for alpha_0, alpha_1 remain valid when pooled across observations separately per t.
- Same testing and inference logic extends; generalized IA (Section F) likewise.

### Verbatim fragments worth preserving (chunk 2)
- "Under the CRC model ( ?? ) and with two time periods, the extrapolation identifying assumption ( ?? ) is equivalent to introducing identities for four parameters that were left unrestricted by the CRC model, so that the extrapolation identifying assumption does not contain testable implications under the CRC model." (p. 33)
- Footnote 3 on heteroscedasticity of hat{a} - alpha_0 - alpha_1 hat{b}: justifies GMM-efficient over plain 2SLS (p. 26).
- Assumption 9.a second condition: "0 < c <= P(x_i1 = 0, x_i2 = 1) <= 1 - c and 0 < c <= P(x_i1 = 1, x_i2 = 0) <= 1 - c" — explicit non-vanishing switcher mass requirement (p. 27).
- Assumption 9.b: non-vanishing difference in conditional E(b_i | switcher-type) — **instrument relevance** (p. 28).

### Weak identification / monte carlo
- No Monte Carlo in chunks 1-2. No explicit weak-identification asymptotic (Staiger-Stock / Andrews-Stock style) framework; paper treats identification as strong under Assumption 9 and flags the alpha_1 = -1 boundary case (p. 13) as the non-identification point.

## Chunk 3 (pp. 46-67): Section H proofs + Section I learning + References

### H.1 Proof of Proposition 1 (pp. 46-47)
- Proves sqrt(n)-consistency of hat{f}_2 (time effect) under f_1 = 0 normalization.
- Uses hat{f}_2 - f_2 driven by (1/n) sum 1[x_i1 = x_i2] Delta u_i2 divided by pi_S = P(x_i1 = x_i2) > 0.
- Key variance component sigma^2_{Delta u, S} = Var(Delta u_i2 | x_i1 = x_i2) > 0 under Assumptions 2.b, 2.c (law of total variance).
- Lindeberg-Levy CLT + Slutsky yield sqrt(n)(hat{f}_2 - f_2) => N(0, sigma^2_{Delta u, S}/pi_S).
- hat{a}_i, hat{a}_i + hat{b}_i decompose into (a_i, a_i + b_i) plus a zeta_{a,i,n} / zeta_{a+b,i,n} term with max_i | . | = O_p(1/sqrt(n)) — the "sqrt(n)-vanishing contamination" from estimating gamma.

### H.2 Proof of Proposition 2 (pp. 47-52)
- Establishes linear influence-function representation for (hat{alpha}_0, hat{alpha}_1) and asymptotic normality.
- Defines r_i = epsilon_i + sum_{t=1,2} u_it [(1 + alpha_1)(1 - x_it) - alpha_1 x_it] — the "effective" second-step residual.
- zeta_{i,n} = zeta_{a,i,n} - alpha_1 zeta_{b,i,n}; zeta_{b,i,n} = zeta_{a+b,i,n} - zeta_{a,i,n}.
- Expands (1/sqrt(n)) sum tilde{X}_i (hat{a}_i - alpha_0 - alpha_1 hat{b}_i) into (a) an influence-function contribution from r_i, plus (b) a contribution from zeta_{i,n} that collapses into a term involving (hat{f}_2 - f_2).
- Uses Assumption 3.a to bound |Corr(1[x_i1 = x_i2] r_i, 1[x_i1 = 0, x_i2 = 1] r_i)| < 1; with bounded support, positive variance, iid, Lindeberg-Levy applies.
- Defines w_i = vector stacking 1[x_i1 = x_i2] Delta u_i2 and mover indicators times r_i; variance positive definite. Asymptotic variance V_alpha = A_0^{-1} [I_2, c_0] Var(w_i) [I_2, c_0]' A_0^{-T}.
- Delta method for hat{ATE}_{S,0} using ATE_{S,0} = E(a_i | 0,0) - alpha_0/alpha_1. Assumption 3.c ensures Var(tilde{a}_i | Delta u_i2, x_i=(0,0)) > 0 so that w_{ATE,i} has positive-definite variance. Delta-method coefficient A_{ATE,0} = [1/alpha_1, -1/alpha_1, -ATE_{S,0}/alpha_1] B_{ATE,0} where B_{ATE,0} is a 3x3 block matrix with pi_{00}, pi_S, A_0^{-1}, c_0.
- **Explicit variance formula for hat{ATE}_{S,0}** (via delta method) — useful for CKT stayer-ATE variance questions.

### H.3 Definitions + Lemma 1 for Prop 3 (pp. 53-54)
- Lemma 1 (FE extension of Prop 1): under CRC and Assumptions 4, 5, as N (number of v-groups) -> infty:
  - sqrt(N)(hat{f}_2 - f_2) => N(0, sigma^2_{Delta u, S} / pi_S) with redefined pi_S = E(sum_{i : v_i = v} 1[x_i1 = x_i2]) and sigma^2_{Delta u, S} = Var(sum_{i : v_i = v, x_i1 = x_i2} Delta u_i2).
  - hat{a}_i, hat{a}_i + hat{b}_i have the same sqrt(N)-vanishing contamination as Prop 1 but with the cluster index.
- Also defines the step-2 FE IV estimator of alpha_1 explicitly using x_i2 as instrument with v-indexed fixed effects; hat{e}_v obtained by within-group residualization.

### H.4 Proof of Proposition 3 (pp. 54-58)
- Shows sqrt(N)-consistency and asymptotic normality of hat{alpha}_1 under CRC + generalized IA + Assumptions 4-6.
- Key object: n_{v,01} n_{v,10} / n_v <= C (Assumption 4, bounded group size).
- **Identification via switcher heterogeneity across villages:** Delta_b = E(n_{v,01} n_{v,10}/n_v (b_{01,v} - b_{10,v})). Proof argues Delta_b != 0 because the quotient is non-negative with positive prob (Assumptions 6.a + 4), has discrete support (Assumption 4), and b_{01,v} - b_{10,v} has uniform sign under Assumption 6.c. **This is the rank condition for the FE estimator.**
- Asymptotic variance: V_alpha = A_{alpha,0} Var(w_v) A_{alpha,0}' with A_{alpha,0} = (1/Delta_b) [1, c_0 / pi_S] and w_v a cluster-level stacked vector (sum over i in v of x_i2 dot{r}_i and sum over i in v with x_i1=x_i2 of Delta u_i2). Assumption 6.d imposes lambda_min(Var(w_v)) > 0 (the clustered analog of rank).
- Delta-method step for hat{ATE}_{S,0}: pi_{00} = E(sum_{i : v_i = v} 1[x_i1 = x_i2 = 0]) > 0 under Assumption 6.d.
- Defines tilde{u}_i = (1/2) sum_t u_it - (1/n_{v_i}) sum_{j in M_n, v_j = v_i} r_j — the "cluster-adjusted noise" relevant to the stayer-ATE variance formula.

### H.5 Proof of Proposition 4 (pp. 58-60)
- Shows step-1 high-dimensional regression estimator properties.
- Uses explicit representation of Z_i' M_{W_i} Z_i and Z_i' M_{W_i} U_i via within-treatment averages bar{z}^0_it = sum_t (1-x_it) z_it / sum_t (1-x_it) and bar{z}^1_it = sum_t x_it z_it / sum_t x_it. These and (W_i' W_i)^- W_i' Z_i, (W_i' W_i)^- W_i' U_i have bounded support under Assumption 8.a.
- Assumption 7 (cross-sectional indep.) ensures Z_i' M_{W_i} Z_i and Z_i' M_{W_i} U_i are iid; CLT + Slutsky give sqrt(n)-consistency, asymptotic normality.

### H.6 Proof of Proposition 5 (pp. 60-64)
- Builds on Prop 4. Uses bounded support of tilde{X}_i [1, b_i + [0,1] (W_i' W_i)^{-1} W_i' U_i] (Assumption 8.a) so MSE convergence applies.
- Under Assumptions 9.a, 9.b, continuous mapping theorem + Prop 4 give sqrt(n)(hat{alpha} - alpha) CLT.
- To apply CLT for independent obs (Theorem 5.11 in White 2001):
  - Shows B_n' Sigma_n^{-1} X tilde{}_i r_i has bounded support (Assumptions 8.a, 9.a, 9.b).
  - Shows lambda_min(Omega_{n,0}) >= c from Assumption 7 (indep) + 8.b (non-vanishing stayer share) + 8.d, 9.a.
  - Uses lambda_max(Sigma_{n,0}^{-1}) <= 1/lambda_min(Sigma_{n,0}) <= C by Assumption 9.a and lambda_max(B_n' B_n) <= C by 8.a.
- ATE_{S,0}, ATE_{S,1} proofs analogous. Assumptions 8.d, 9.a, 9.d give uniform positive-definite variance of the stacked score; Assumption 7 ensures the stayer-average of tilde{a}_i is independent of the mover moment (1/n) sum_{i in M_n} tilde{X}_i r_i; Assumption 9.d prevents approximate linear dependence of the stayer average and the gamma-estimation noise.

### H.7 Proof of Proposition 6 (p. 65)
- One-paragraph proof. MSE convergence + continuous mapping theorem give consistency of the sandwich estimator; Slutsky closes.

### H.8 Proof of Proposition 7 (p. 65)
- One-line: "follows the same steps as the proof of Proposition 5 albeit with different definitions and dependence being indexed by v_i rather than i."

### H.9 Proof of Proposition 8 (p. 65)
- "follows the same steps as the proof of Proposition 6 albeit with different definitions and dependence being indexed by v_i rather than i."

### Section I: Learning and the extrapolation IA (pp. 65-66)
- Motivating concern: if farmers learn about b_i through adoption, past shocks u_is (s < t) could influence x_it, invalidating the CRC model in step 1.
- Model of "immediate learning": pre-first-adoption rule x_it = 1[tilde{b}_i >= c_it] with tilde{b}_i = b_i + varsigma_i (measurement error); post-adoption rule x_it = 1[b_i >= c_it]. If varsigma_i, c_it are independent of (a_i, b_i), this satisfies condition (2.15) of the main text.
- General info-set model: x_it = 1[E(b_i | I_it) >= c_it] (following D'Haultfoeuille and Maurel 2013). If I_it and c_it are independent of a_i conditional on b_i, the extrapolation IA (2.11) holds (provided linearity (2.14) holds).
- Section 4.3 of main text allows village-shared information to be correlated with (a_i, b_i) — the motivation for the generalized IA in Section F.

### References list (p. 66-67)
- Abbring and Heckman (2007, Handbook of Econometrics Vol. 6)
- Carneiro, Hansen, Heckman (2003, IER 44)
- Chamberlain (1992, Econometrica 60)
- Cunha, Heckman, Navarro (2005, Oxford Econ Papers 57)
- D'Haultfoeuille and Maurel (2013, J. Econometrics 174)
- Hansen (1982, Econometrica 50)
- Lemieux (1998, JOLE 16)
- Mammen (1992, Springer Lecture Notes)
- Newey and Windmeijer (2009, Econometrica 77) — "Generalized Method of Moments With Many Weak Moment Conditions"
- Suri (2011, Econometrica 79)
- White (2001, Asymptotic theory for econometricians)

### Verbatim fragments worth preserving (chunk 3)
- Learning paragraph: "If farmers learn directly about their returns, without confounding their adoption of the new technology with past productivity shocks, learning may not invalidate the extrapolation assumption." (p. 65)
- General info-set condition: "if I_it and c_it are independent of a_i conditional on b_i, then the extrapolation identifying assumption (2.11) holds (if the assumption of linearity (2.14) also holds)." (p. 66)

### Monte Carlo evidence
- **None.** The online appendix contains no Monte Carlo simulations or finite-sample coverage exercises. All results are asymptotic.

### Optimal instruments z_opt = Z W Z' x
- **Not derived verbatim.** The appendix uses GMM with an efficient weighting matrix Sigma_n (justified by heteroscedasticity of the step-2 residual, footnote 3 on p. 26) but does not state the explicit z_opt = ZWZ'x expression. The relevant machinery (efficient weighting = inverse moment covariance) is standard GMM and is left implicit. Newey-Windmeijer (2009) is cited only as a caution against many-moment specifications.

