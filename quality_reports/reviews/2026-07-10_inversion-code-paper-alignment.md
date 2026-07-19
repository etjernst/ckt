# Inversion inference: code--paper alignment review

Date: 2026-07-10

Scope: `main-updated.tex`, the production inversion bridge in `RP7/scripts/0_programs.do`, the drivers `5b_inversion.do` and `5c_inversion_hukou.do`, and the Python implementations in `explorations/python-grc/lca_inversion.py` and `counterfactuals.py`.

This review compares the manuscript with the code as written.
It does not authorize estimation or code changes.

## Finding F1: the methods section omits the implemented inversion procedure

Severity: MAJOR.

Confidence: HIGH.

The manuscript claims weak-identification-robust inference in the introduction and invokes an inversion confidence region in the counterfactual section, but the methods section currently ends with two-step GMM, the Hansen $J$-statistic, and clustered standard errors.
The production code instead fits a saturated auxiliary OLS with trajectory intercepts, switcher-by-urban interactions, the unbalanced indicators, and the same controls; it then inverts joint Wald restrictions built from those reduced-form coefficients.

Recommended action: Add a short inference subsection after the GMM moments that defines the auxiliary estimates, restriction vector, Wald statistic, acceptance rule, clustering, sparse-cell threshold, and profiling used for derived returns.

## Finding F2: the counterfactual confidence region is labeled with the wrong intercept

Severity: MAJOR.

Confidence: HIGH.

The manuscript describes the joint region as a region for $(\phi,\beta,\Delta_{\mathrm{unb}})$ and writes $\Delta_{d_N}=\beta+\phi(\mu_{d_N}-\mu_{\underline d_0})$.
The code's `beta_grid` and exported `beta_hat` are the baseline-switcher return, `Delta_base:_cons`, not the structural intercept $\beta$ in $\Delta_i=\beta+\phi\theta_i$.
The implemented formula is

\[
\Delta_{\underline d}=\Delta_{\underline d_0}+\phi(\mu_{\underline d}-\mu_{\underline d_0}).
\]

Recommended action: Replace $\beta$ by $\Delta_{\underline d_0}$ wherever the manuscript describes the inversion region or the trajectory-relative extrapolation.
Keep $\beta$ for the structural LCA intercept in $\Delta_i=\beta+\phi\theta_i$.

## Finding F3: the lumped unbalanced return is a direct auxiliary-OLS coefficient

Severity: MAJOR.

Confidence: HIGH.

The manuscript calls $\Delta_{\mathrm{unb}}$ “the base-trajectory return plus the unbalanced-mover shift.”
In `fit_auxiliary_ols`, each retained switcher has its own urban interaction and the unbalanced observations have a separate `unbalanced_choice` regressor; there is no common urban-return regressor in that auxiliary regression.
The coefficient on `unbalanced_choice` is therefore the lumped cell's direct urban premium.

Recommended action: Describe $\Delta_{\mathrm{unb}}$ as the coefficient on the urban indicator for the lumped unbalanced cell in the saturated auxiliary regression.

## Finding F4: the scalar and joint inversions use related but distinct restriction vectors

Severity: MAJOR.

Confidence: HIGH.

For the scalar $\phi$ interval, `grid_lca_inversion` compares every retained non-base switcher with the baseline switcher and inverts a $K-1$ degree-of-freedom Wald statistic.
For the counterfactual region, `build_joint_ci_grid_3d` includes all $K$ switcher equations, including the base equation, plus the lumped-cell equation; it uses $K+1$ degrees of freedom for $(\phi,\Delta_{\underline d_0},\Delta_{\mathrm{unb}})$.
For $\Delta_{d_N}$, $\bar\Delta$, and $\Delta_{d_T}$, the code fixes a candidate derived return, profiles over $\phi$, and inverts the minimized $K-1$ degree-of-freedom statistic.

Recommended action: Describe the scalar/profile inversions and the three-dimensional counterfactual region separately.

## Finding F5: the Hansen specification test and the inversion test are not distinguished

Severity: MAJOR.

Confidence: HIGH.

The Hansen $J$-statistic comes from the restricted two-step GMM fit and is used as a specification diagnostic for the LCA model.
The weak-identification-robust confidence sets come from Wald tests of fixed candidate values using unrestricted auxiliary-regression coefficients.
These are not the same statistic, even though both test implications of the LCA restriction and both may produce empty sets under misspecification.

Recommended action: State the different roles explicitly and retain the Hansen $J$-test discussion as a model-diagnostic paragraph.

## Finding F6: the computational support and critical values are undocumented

Severity: MINOR.

Confidence: HIGH.

The table-side inversion uses a $0.01$ grid for $\phi$ on $[-3,1]$, a $0.01$ grid for $\Delta_{d_N}$ and $\bar\Delta$ on $[-1.5,1.5]$, and a $0.02$ grid for $\Delta_{d_T}$ on $[-5,5]$.
It retains switcher trajectories with at least five individuals observed urban within that trajectory, uses individual-clustered auxiliary-OLS covariance estimates, and compares the statistic with asymptotic chi-squared critical values.
The counterfactual code uses a $0.01$ $\phi$ grid, wider support for the hukou subsamples, and marks accepted rays as unbounded after explicit large-$|\phi|$ probes.

Recommended action: Put the threshold, grid spacing, asymptotic critical values, and unbounded-set convention in the inference subsection or a compact footnote.

## Finding F7: coverage language needs the asymptotic qualifier

Severity: MINOR.

Confidence: HIGH.

Projecting a joint $95\%$ confidence region through the counterfactual gives a confidence set with at least the joint region's coverage for the model-implied aggregate.
The implemented critical values are asymptotic chi-squared values, so the manuscript should say “asymptotic coverage of at least $95\%$.”
The existing China national footnote correctly states the weaker $90\%$ floor that follows from combining two subgroup hulls under arbitrary dependence.

Recommended action: Add “asymptotic” to the general coverage statement and preserve the China-specific qualification.

## Finding F8: the Overleaf GRC tables do not yet display the implemented intervals

Severity: MAJOR if the prose says that the tables report inversion intervals; otherwise an open production item.

Confidence: HIGH.

The current Overleaf GRC tables are the five-column versions without inversion rows.
The current RP7 output contains four-column tables with inversion rows for Indonesia and Tanzania, but the China and hukou tables remain stale because the required full-sweep, inversion-attached RP7 sters are not available.
The July 1 session log explicitly forbids a multi-day GMM rerun without separate approval.

Recommended action: Do not claim that all main GRC tables report inversion intervals in this editing round.
Do not copy a mixed set of old and new tables.
Treat coherent table regeneration as a separate estimation/output task.

## Readiness verdict

The manuscript can be updated now to describe the implemented inference and correct the parameter labels without rerunning estimates.
The table-side presentation remains blocked for China and the hukou subsamples, so this round should not alter or synchronize the GRC table files.
