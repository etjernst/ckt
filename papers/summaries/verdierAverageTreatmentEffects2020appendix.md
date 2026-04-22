---
citekey: verdierAverageTreatmentEffects2020appendix
title: "Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data --- Online Appendix"
authors: Verdier, Valentin
year: 2020
doi: 10.1002/jae.2750
source_pdf: papers/extracted/verdierAverageTreatmentEffects2020appendix/verdierAverageTreatmentEffects2020appendix.pdf
---

# Verdier (2020) Online Appendix

## Bibliographic header
Valentin Verdier, "Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data," Journal of Applied Econometrics, 2020. This document is the 67-page online appendix dated May 26, 2020.

## Extraction caveat
The PDF was processed with Docling's formula VLM disabled (it segfaults on Windows). The extraction report shows 0 formula tags. For a 67-page technical appendix this means nearly every inline or display equation was silently dropped from the markdown. Throughout the notes, places where an equation was clearly present in the source but missing from the extraction are flagged as `[EQUATION MISSING from extraction]`. Readers should consult the PDF directly (pp. 29-32, 38-43, and most of Section H) for exact formulas; the prose around the equations has been preserved and is reliable.

## Research question
What are the formal identification conditions, estimators, standard errors, and test statistics that implement the stayer-ATE extrapolation developed in the main text, and what classes of selection models (Roy, time-varying effects, learning) are compatible with the extrapolation identifying assumption?

## Audience
Econometric theorists working on panel data with random coefficients; applied microeconomists using Suri (2011) / Lemieux (1998) style comparative-advantage estimators and needing formal asymptotics, cluster-robust standard errors, or overidentification tests; anyone extending these methods to village-level fixed effects or unbalanced panels.

## Method
Pure derivation. The appendix (i) restates identification under general T, (ii) shows the Lemieux (1998) GMM and Suri (2011) minimum-distance estimators both implement the main text's linear extrapolation under the CRC model alone, (iii) proves asymptotic normality of a two-step estimator (cross-section-dummy regression in step 1; GMM on movers with treatment-history instruments in step 2), (iv) develops cluster-robust analogs for a village-indexed generalized extrapolation identifying assumption, (v) extends to unbalanced panels under MAR, (vi) proves Propositions 1-8 of the main text and their appendix generalizations, and (vii) discusses how learning about b_i affects the validity of the identifying assumption.

## Data
None. The appendix contains no data and no simulations. All results are asymptotic (n -> infty with T fixed).

## Statistical methods
- Two-step estimation. Step 1: pool observations, regress y_it on z_it plus cross-sectional dummies plus cross-sectional dummies interacted with x_it. By Frisch-Waugh this gives sqrt(n)-consistent gamma and noisy (a_i, b_i) for movers; noisy a_i for untreated stayers; noisy a_i + b_i for treated stayers.
- Step 2: GMM regression of hat{a}_i on hat{b}_i among movers with treatment-history tilde{X}_i = [1, (x_it)_{t in S}] as instruments. With T = 2 the system is exactly identified; with T >= 3 over-identification is available.
- Variance estimation: analytical cluster-robust sandwich (Prop 6; Prop 8 in the FE case) accounting for first-step estimation of gamma, or cluster bootstrap with clusters at the cross-sectional unit (or village v in the FE case).
- Over-identification test (E.3.2 / end of F): Wald test of |S| extra exactly identifying moments; chi-squared with |S| - 1 df. Cannot be run with T = 2.
- FE extension (Section F): demean (hat{a}_i, hat{b}_i) within values of indexing variable v_i, run 2SLS with fixed effects, cluster all standard errors at v.
- Unbalanced panels (Section G): under MAR, redefine Y_i, X_i, W_i, Z_i, M_n to use only observed periods; step 1 becomes a pooled regression and step 2 GMM pools moments separately per t.

## Theoretical results

Each proposition / lemma from the appendix, with a one-sentence statement and its location. The online appendix propositions generalize Propositions 1-3 of the main text; the main-text results are obtained as special cases.

1. **Proposition 4 (Step 1 asymptotics, pp. 24-25).** Under Assumptions 7-8, sqrt(n)(hat{gamma} - gamma) is asymptotically normal with sandwich variance V_{n,gamma,0} / A_{n,gamma,0}; for each i, hat{a}_i - a_i and hat{a}_i + hat{b}_i - (a_i + b_i) decompose into an O_p(1) idiosyncratic term plus a sqrt(n)-vanishing contamination from estimating gamma. Main-text Prop 1 is a special case.
2. **Proposition 5 (Step 2 asymptotics, pp. 29-31).** Under Assumptions 7-9, sqrt(n) ((hat{alpha}_0, hat{alpha}_1) - (alpha_0, alpha_1)) is asymptotically normal; when alpha_1 is not in {0, -1}, sqrt(n)(hat{ATE}_{S,0} - ATE_{S,0}) and sqrt(n)(hat{ATE}_{S,1} - ATE_{S,1}) are asymptotically normal. Main-text Prop 2 is a special case.
3. **Proposition 6 (analytical cluster-robust SE, pp. 31-32).** Under Assumptions 7-9, the explicit sandwich variance formula for hat{alpha} that uses hat{r}_i^2 tilde{X}_i tilde{X}_i', the step-1 residual moments, and the cross-step covariance is consistent for the asymptotic variance; the same machinery applies to hat{ATE}_{S,0} and hat{ATE}_{S,1}.
4. **Proposition 7 (FE / generalized extrapolation asymptotics, pp. 42-43).** Under (F.1), (F.2), and Assumptions 8, 10, 11, sqrt(n)(hat{alpha}_1 - alpha_1) is asymptotically normal; when alpha_1 is not in {0, -1}, sqrt(n)(hat{ATE}_{S,0} - ATE_{S,0}) and sqrt(n)(hat{ATE}_{S,1} - ATE_{S,1}) are asymptotically normal with cluster-at-v structure. Main-text Prop 3 is a special case.
5. **Proposition 8 (analytical cluster-at-v SE for FE case, pp. 43-44).** Under the same conditions, the analog of the Prop 6 sandwich, clustered at the indexing variable v_i, is consistent for the asymptotic variance of hat{alpha}_1.
6. **Lemma 1 (step-1 cluster analog, pp. 53-54).** Under the CRC model and Assumptions 4-5, sqrt(N)(hat{f}_2 - f_2) is asymptotically normal with variance sigma^2_{Delta u, S} / pi_S (cluster-redefined); hat{a}_i, hat{a}_i + hat{b}_i have the same decomposition as in Proposition 1 with the cluster-level sqrt(N)-vanishing contamination.
7. **Lack-of-testable-implications result (E.3.1, p. 33).** Verbatim: "Under the CRC model and with two time periods, the extrapolation identifying assumption is equivalent to introducing identities for four parameters that were left unrestricted by the CRC model, so that the extrapolation identifying assumption does not contain testable implications under the CRC model." Proof: explicit construction of (tilde{a}_i, tilde{b}_i, tilde{xi}_i) satisfying both CRC and the IA for any CRC data.
8. **Over-identification test (E.3.2 / Section F).** For T >= 3, the IA is testable by adding |S| + 1 exactly identifying moments with nuisance parameters (eta_0, (eta_t)_{t in S}) and Wald-testing H_0: all eta = 0. Critical values from chi-squared(|S| - 1). Analog of Sargan-Hansen J but adjusted for the first-step estimation of gamma.
9. **Breakdown at alpha_1 = -1 (Section B.2, p. 13).** When phi = -1 (equivalently alpha_1 = -1), the reduced-form-to-structural map is singular; beta, lambda_0, lambda_3 are not identified, so the probability limits of the stayer-return estimators do not exist. Geometrically, the extrapolation line becomes parallel to the a + b = const line.
10. **Time-varying treatment effects extension (Section D, pp. 16-21).** Under Assumptions (D.4)-(D.6) (a single unobserved e_i drives both baseline and time-varying returns, and treatment is chosen on e_i alone without direct dependence on the shocks nu_{t,i}), the step-2 IV regression still works but must be run separately on movers treated at each t, requiring T >= 3. Noisier and more data-hungry than the time-constant case.
11. **Roy-model embedding (Section C).** A Carneiro-Hansen-Heckman (2003) generalized Roy model with factor theta and selection shock epsilon_s satisfies the main-text sufficient conditions (2.12)-(2.13) whenever the factor loadings on (y(0), y(1)) differ, i.e. beta_{1,1} - beta_{1,0} != 0. The CRC restrictions replace the standard Roy-model identification devices (instruments, proxies, repeated measurements of theta).

## Contribution
The appendix gives the technical substrate missing from the main text: formal identification conditions under general T, explicit sandwich and cluster-robust variance formulas, a Sargan-Hansen-style overid test, a clean proof that Lemieux (1998) GMM and Suri (2011) minimum distance both reduce to the same linear-extrapolation pseudo-parameter under the CRC model, a generalized-Roy embedding, a time-varying-effects extension, a generalized extrapolation IA with within-village fixed effects, and an MAR-based unbalanced-panel extension. It also proves Propositions 1-8 that underpin the estimators actually used in the empirical application of the main text.

## Replication feasibility
No data or code in the appendix itself. The main text's replication package (Journal of Applied Econometrics archive) contains the empirical code. The theoretical content of this appendix is self-contained given access to the PDF formulas.

## Relevance to CKT (design memo consumer)

Points the downstream memo cares about, with status:

- **(i) Variance of the stayer-ATE estimator.** *Covered.* Proposition 5 gives the asymptotic distribution, Proposition 6 the analytical cluster-robust sandwich. Section H.2 supplies the delta-method derivation with explicit matrices A_{ATE,0} = [1/alpha_1, -1/alpha_1, -ATE_{S,0}/alpha_1] B_{ATE,0}. The FE version (Propositions 7-8) gives the cluster-at-v analog. All formulas require alpha_1 not in {0, -1}; near those boundary values the delta-method variance explodes.
- **(ii) Identification conditions beyond main text.** *Covered.*
  - Support: Assumption 9.a requires 0 < c <= P((x_i1, x_i2) = (0,1)) <= 1 - c and likewise for (1,0), i.e. non-vanishing mass on both switcher directions. With the FE extension (Section F), the analog is Assumption 11.a (within-v switcher variation).
  - Instrument relevance: Assumption 9.b requires |E(b_i | (0,1)) - E(b_i | (1,0))| >= c > 0 at the population level --- an IV first-stage-strength condition on treatment-history as an instrument for b_i.
  - Rank: Assumption 9.d prevents approximate linear dependence between stayer-level (a_i, a_i + b_i) and u_it, preventing super-consistency and ensuring sqrt(n) rates.
  - Boundary: alpha_1 in {0, -1} are non-identification points; the main-text condition alpha_1 != 0 corresponds to extrapolation-line slope in a + b = const coordinates, and alpha_1 = -1 to the extrapolation line being parallel to the always-treated line.
- **(iii) Monte Carlo / finite-sample bias and coverage.** *Not covered.* The online appendix contains no Monte Carlo. Any simulation evidence would be in the main text or the empirical section, not here.
- **(iv) Optimal instruments z_opt = Z W Z' x.** *Not stated verbatim.* The appendix argues for GMM with the efficient weighting matrix because the step-2 residual is heteroscedastic under measurement error (footnote 3, p. 26) and cites Newey and Windmeijer (2009) against many-moment expansions, but it never writes the z_opt = Z W Z' x formula explicitly. Readers wanting that expression must derive it from the standard efficient-GMM template; the ingredients (influence functions, moment Jacobians, residual covariance) are all in Propositions 5-6.
- **(v) Weak identification / small switcher variation.** *Partially covered.* The alpha_1 = -1 singularity (Section B.2, p. 13) is the only explicit non-identification point. The appendix does not develop a Staiger-Stock-style weak-IV asymptotic framework; strong identification is imposed via Assumption 9.a-b (bounded-away support and relevance). Near-weak-identification bias is acknowledged only indirectly through Assumption 9.d (no super-consistency) and the caveat in Section D (p. 21) that time-varying-effects extensions "will be significantly more noisy . . . and will require researchers to have access to larger datasets."

## Verbatim evidence

- **Identification (general T):** "conditional average treatment effect E(b_i | X_i) is only identified for cross-sectional observations such that W_i' W_i is non-singular. With x_it being binary, W_i' W_i is non-singular for movers and singular for stayers, so that average treatment effects are only identified for movers." (p. 6)
- **Non-identification at alpha_1 = -1:** "When phi = -1, the system linking reduced form parameters to structural parameters does not identify lambda_3, so that beta, lambda_0, lambda_3 are not identified, so that the probability limits of the estimators for average returns for stayers do not exist." (p. 13)
- **Noisier time-varying-effects extension:** "In practice this will imply that estimation results will be significantly more noisy than using the methods developed in the main text, and will require researchers to have access to larger datasets than what is used in the empirical application of the main text." (p. 21)
- **Step 1 result (verbal):** "Proposition 4 shows that the estimator for gamma is sqrt(n)-consistent and asymptotically normal. It also shows that the estimation noise of the heterogeneity terms a_i and b_i is decomposed into idiosyncratic noise that would arise even if gamma were known and vanishing noise originating from the estimation of gamma which is dominated by a term of order 1/sqrt(n)." (p. 25)
- **Why GMM not 2SLS (heteroscedasticity motivation):** "We consider GMM estimation for a potential efficiency gain because of the heteroscedasticity in hat{a}_i - alpha_0 - alpha_1 hat{b}_i conditional on X_i that is likely to exist because of measurement error. Indeed heteroscedasticity is likely to appear in the non-vanishing part of the estimation noise in the estimates hat{a}_i and hat{b}_i." (p. 26, footnote 3)
- **Support / rank / non-vanishing switcher-mass (Assumption 9.a):** "0 < c <= P(x_i1 = 0, x_i2 = 1) <= 1 - c and 0 < c <= P(x_i1 = 1, x_i2 = 0) <= 1 - c ... for all i = 1, ..., n, for all n." (p. 27)
- **Not testable under T = 2:** "Under the CRC model and with two time periods, the extrapolation identifying assumption is equivalent to introducing identities for four parameters that were left unrestricted by the CRC model, so that the extrapolation identifying assumption does not contain testable implications under the CRC model." (p. 33)
- **Cluster-level rank (FE):** Under the FE extension, "Proposition 7 shows that the second stage estimators of alpha_1 and of ATE for stayers have a linear influence function asymptotic representation, so that as before consistent variance estimation could be obtained by bootstrap resampling, although here resampling should be clustered at the level of the indexing variable v_i." (p. 43)
- **Learning and the IA:** "If farmers learn directly about their returns, without confounding their adoption of the new technology with past productivity shocks, learning may not invalidate the extrapolation assumption." (p. 65)
- **Info-set form of the IA:** "if I_it and c_it are independent of a_i conditional on b_i, then the extrapolation identifying assumption (2.11) holds (if the assumption of linearity (2.14) also holds)." (p. 66)

## Gaps and limitations
- The appendix contains no Monte Carlo evidence; finite-sample bias and coverage are not studied.
- No formal weak-instrument or weak-identification asymptotic framework. Identification is imposed by Assumption 9 / 11 strong-form rank conditions; the only explicit non-identification point is alpha_1 = -1.
- The optimal-instruments expression z_opt = Z W Z' x is not derived verbatim; only its generic GMM-efficient-weighting motivation appears.
- The time-varying-effects extension (Section D) is flagged by the author as noisier and requiring larger datasets; detailed development is deferred to future work.
- Extraction of equations is incomplete (Docling formula enrichment disabled). Any work requiring exact algebraic formulas --- particularly influence functions in Section H and variance-matrix definitions in Section E.2 --- must consult the PDF directly.
