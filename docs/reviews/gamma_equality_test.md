# Testing the symmetric covariates restriction ($\gamma^U = \gamma^R$)

**Date:** 2026-03-23
**Status:** Ready to implement if requested by referee
**Source:** Review issue M8 in [2026-03-12_theory-section-review.md](2026-03-12_theory-section-review.md)

---

## Background

The restricted GRC model assumes $\gamma^U = \gamma^R$, i.e., observable characteristics affect consumption symmetrically across locations. This drops the interaction $D_{it} x_{it}'(\gamma^U - \gamma^R)$ from the estimating equation. If the restriction fails---for example, because education earns higher returns in urban labor markets---part of the heterogeneity attributed to $\theta_i$ may instead reflect differential covariate effects across locations.

The restriction is testable. The procedure below adds covariate-urban interactions to the GMM residual and instrument list, then tests whether the interaction coefficients are jointly zero.

## Current covariate list

From `0_programs.do` (line 432--436):

```stata
global covs_gmm       "female"
global covs_gmm2      "$covs_gmm age2"
global covs_gmm_all   "$covs_gmm2 education_max education_max2"
```

The full-controls specification uses `$covs_gmm_all` = `female age2 education_max education_max2`. Period fixed effects (`periodFE`) are also included but do not need interaction terms (they are common across locations by construction since $\beta \equiv \beta_t^U - \beta_t^R$ is assumed constant).

## Implementation

### Option A: Quick one-off test (no program changes)

Run after a standard `run_grc` call. Requires the same locals and globals to be set (`switcherpars`, `switcher_traj`, `base`, `covarlist`, `initial`).

```stata
* ============================================================
* Test H0: gamma^U = gamma^R (symmetric covariate restriction)
* ============================================================

* Generate covariate-urban interactions
foreach v of varlist female age2 education_max education_max2 {
    cap drop `v'_X_choice
    gen `v'_X_choice = `v' * choice
}

local interactions "female_X_choice age2_X_choice education_max_X_choice education_max2_X_choice"

* Run unrestricted GMM with covariate interactions
gmm (lndepvar - {mu: never `switcher_traj'}                     ///
    - {Delta_base}*choice                                        ///
    - {phi}*(`switcherpars')                                     ///
    - ({kappa}+{phi}*({kappa}                                    ///
    - {mu: switcher_`base'}))*(always#1.choice)                  ///
    - {xb: `covarlist' `interactions'})                          ///
    , instruments(                                               ///
    `covarlist'                                                  ///
    `interactions'                                               ///
    never `switcher_traj' choice                                 ///
    always_choice switcher_*_choice, nocons)                     ///
    vce(cluster pid) from(`initial')                             ///
    quickderivatives iterate(500)

* Store unrestricted estimates
estimates store grc_unrestricted

* Joint Wald test: H0: all interaction coefficients = 0
test [xb]female_X_choice       ///
     [xb]age2_X_choice         ///
     [xb]education_max_X_choice ///
     [xb]education_max2_X_choice

* Compare phi across restricted and unrestricted
estimates table grc_`country'_ca grc_unrestricted, keep(phi:_cons)
```

### Option B: Add `asymcovars()` option to `run_grc`

Modify the program signature in `0_programs.do` (line 1555) to accept an optional `asymcovars(varlist)`:

```stata
syntax , estname(string) switcherpars(string) base(numlist) ///
    balance(string) [covars(varlist) asymcovars(varlist)    ///
    iterate(numlist) initial(string)]
```

Then after the covarlist construction (line 1559), add:

```stata
* Generate asymmetric covariate interactions if requested
local interactions ""
if "`asymcovars'" != "" {
    foreach v of varlist `asymcovars' {
        cap drop `v'_X_choice
        gen `v'_X_choice = `v' * choice
        local interactions "`interactions' `v'_X_choice"
    }
    local covarlist "`covarlist' `interactions'"
}
```

The interactions are automatically added to both `{xb: covarlist}` in the residual and the instrument list since both use the same `covarlist` local. No other changes needed to `run_grc`.

Call as:

```stata
run_grc, estname(grc_`country'_asym)                        ///
    switcherpars("`switcherpars'") base(`base')              ///
    initial(`initial') balance(`balance')                    ///
    covars(`periodFE' $covs_gmm_all)                        ///
    asymcovars(female age2 education_max education_max2)     ///
    iterate(500)
```

## Interpreting results

1. If the joint Wald test **fails to reject** (p > 0.05): the restriction is empirically supported. Report p-value and move on.

2. If the test **rejects**: compare $\hat{\phi}$ and $\hat{\Delta}_{d_N}$ between the restricted and unrestricted specifications.
   - If $\hat{\phi}$ is similar: the restriction is innocuous for the headline result even though it is statistically rejected. Report both estimates.
   - If $\hat{\phi}$ changes substantially: the restriction matters and the paper should discuss implications.

3. **Economic prior:** The most likely violation is differential returns to education ($\gamma^U_{\text{educ}} > \gamma^R_{\text{educ}}$). If this holds, imposing $\gamma^U = \gamma^R$ forces the education premium difference into $\theta_i$, potentially inflating the estimated role of comparative advantage.

## Files affected

- `scripts/0_programs.do` (if using Option B): modify `run_grc` program
- New do-file or addition to existing GRC script (if using Option A): standalone test code
- No changes to `paper/main.tex` unless referee requests it
