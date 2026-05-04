# Base mismatch fix: exact code changes

**Date:** 2026-03-25
**Target:** `0_programs.do` + all GRC do-files in ReplicationPackage5

---

## What this fixes

`define_switcherpars` was called with a hardcoded `base(2)` at every call site, while `run_grc` received a data-adaptive base from `initial_values`. This created an internal inconsistency in the GMM moment condition: the switcherpars sum was normalized to trajectory 2, but the always-urban term and all `nlcom` extrapolations used a different trajectory. After this fix, `run_grc` calls `define_switcherpars` internally, making it impossible to mismatch.

---

## Part 1: `0_programs.do` — rewrite `run_grc`

### Replace the entire `run_grc` program (lines 1551--1666) with:

```stata
* **********************************************************************
* GMM regression
* **********************************************************************
capture program drop run_grc
program define run_grc

    * Syntax: switchers() replaces switcherpars() — base mismatch is now impossible
    syntax , estname(string) base(numlist) switchers(numlist) balance(string) ///
             [covars(varlist) iterate(numlist) initial(string)]

    * Construct the covariates string for the regression and instruments
    if "`balance'" == "unb" {
        local covarlist "`covars' unbalanced unbalanced_choice"
    }
    else {
        local covarlist "`covars'"
    }

    * Build switcher trajectory variable list
    local switcher_traj
    foreach s of numlist `switchers' {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }

    * Build switcherpars internally — guarantees same base everywhere
    define_switcherpars, switchers(`switchers') base(`base')
    local switcherpars `r(switcherpars)'

    di as text "run_grc: base trajectory = `base'"

    * Run the GMM estimation
    eststo `estname': gmm (lndepvar - {mu: never `switcher_traj'}          ///
                    - {Delta_base}*choice                                   ///
                    - {phi=-1}*(`switcherpars')                              ///
                    - ({kappa}+{phi}*({kappa}                               ///
                    - {mu: switcher_`base'}))*(always#1.choice)              ///
                    - {xb: `covarlist'})                                    ///
                    , instruments(                                           ///
                    `covarlist'                                              ///
                    never `switcher_traj' choice                             ///
                    always_choice switcher_*_choice, nocons                  ///
                    )                                                        ///
                    vce(cluster pid)                                         ///
                    from(`initial')                                          ///
                    quickderivatives nolog                                   ///
                    iterate(`iterate')

    * Joint test for mus
    local mu_test ""
    local s0 : word 1 of `switchers'
    local mu_test "[mu]switcher_`s0'"
    foreach s of numlist `switchers' {
        if `s' != `s0' {
            local mu_test "`mu_test' = [mu]switcher_`s'"
        }
    }
    test `mu_test'
    estadd scalar joint_chi2 = r(chi2), replace   : `estname'
    estadd scalar joint_p    = r(p),    replace   : `estname'

    * Add J-stat estimates from Hansen's J-test
    estat overid
    estadd sca Jstat    = r(J)      , replace   : `estname'
    estadd sca Jdf      = r(J_df)   , replace   : `estname'
    estadd sca Jpval    = r(J_p)    , replace   : `estname'
    local converged_str = cond(e(converged)==1, "Y", "N")
    estadd local converged_str "`converged_str'", replace : `estname'

    * Save results
    estimates save "$dir/output/`estname'", replace

    * Compute Delta_never
    estimates restore `estname'
    nlcom (Delta_never: _b[Delta_base:_cons] + (_b[phi:_cons] * ///
          (_b[mu:never] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_never", replace

    * Compute Delta_always (average Delta for always-urban)
    estimates restore `estname'
    nlcom (Delta_always: _b[Delta_base:_cons] + (_b[phi:_cons] *  ///
          (_b[kappa:_cons] - _b[mu:switcher_`base']))), post
    estimates save "$dir/output/`estname'_always", replace

    * Compute all switcher Deltas
    estimates restore `estname'
    local nlcom_expr ""
    foreach s of numlist `switchers' {
        local nlcom_expr "`nlcom_expr' (Delta_`s': _b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base'])))"
    }
    nlcom `nlcom_expr', post
    * Joint test for Deltas
    local d_test ""
    local s0 : word 1 of `switchers'
    local d_test "Delta_`s0'"
    foreach s of numlist `switchers' {
        if `s' != `s0' {
            local d_test "`d_test' = Delta_`s'"
        }
    }
    test `d_test'
    estadd scalar joint_chi2 = r(chi2), replace
    estadd scalar joint_p    = r(p),    replace
    estimates save "$dir/output/`estname'_delta", replace

    * Compute Delta_avg (average Delta for all switchers)
    local first_loop = 1
    local Delta_avg_nlcom ""
    foreach s of numlist `switchers' {
        estimates restore `estname'
        sum 1.switcher_`s' if e(sample)
        local num_`s' = r(mean)
        if `first_loop' == 0 {
            local Delta_avg_nlcom "`Delta_avg_nlcom' + (`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
        }
        else if `first_loop' == 1 {
            local Delta_avg_nlcom "(`num_`s'' * (_b[Delta_base:_cons] + (_b[phi:_cons] * (_b[mu:switcher_`s'] - _b[mu:switcher_`base']))))"
            local first_loop = 0
        }
    }
    estimates restore `estname'
    nlcom (Delta_avg: `Delta_avg_nlcom'), post
    estimates save "$dir/output/`estname'_avg", replace

end
```

### Summary of changes to `run_grc`:

| Change | Why |
|--------|-----|
| `switcherpars(string)` removed from `syntax` | No longer passed by caller |
| `switchers(numlist)` added to `syntax` | Needed to build switcherpars internally |
| `define_switcherpars` called inside program | Guarantees same `base` everywhere |
| `$switchers` → `` `switchers' `` throughout | Use argument, not global |
| `di` line added | Logs which base was selected |
| `covarlist` conditional on `balance` | Fixes separate minor issue (M-1 in Stata review) |

---

## Part 2: All GRC do-files — simplify call sites

### Standard block (appears ~69 times across all do-files)

**Before:**
```stata
* ************
* Specify general command for GMM
* ************
define_switcherpars, switchers($switchers) base(2)
local switcherpars `r(switcherpars)'
local iterations 500

* ************
* Estimate restricted GMM model
* ************
* No covariates
run_grc, estname(grc_`country'_covs_0)                             ///
    switcherpars("`switcherpars'") base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations')

* Add time FE
run_grc, estname(grc_`country'_covs_trend)                         ///
    switcherpars("`switcherpars'") base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations')

* Add female
run_grc, estname(grc_`country'_covs_1)                             ///
    switcherpars("`switcherpars'") base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations')
```

**After:**
```stata
local iterations 500

* ************
* Estimate restricted GMM model
* ************
* No covariates
run_grc, estname(grc_`country'_covs_0)                             ///
    switchers($switchers) base(`base') initial(`initial')          ///
    balance(`balance')                                             ///
    iterate(`iterations')

* Add time FE
run_grc, estname(grc_`country'_covs_trend)                         ///
    switchers($switchers) base(`base') initial(`initial')          ///
    balance(`balance')                                             ///
    covars(`periodFE')                                             ///
    iterate(`iterations')

* Add female
run_grc, estname(grc_`country'_covs_1)                             ///
    switchers($switchers) base(`base') initial(`initial')          ///
    balance(`balance')                                             ///
    covars(`periodFE' $covs_gmm)                                   ///
    iterate(`iterations')
```

**What changed:**
1. Delete the two `define_switcherpars` / `local switcherpars` lines
2. In every `run_grc` call: replace `switcherpars("`switcherpars'")` with `switchers($switchers)`

### Alternative-base robustness blocks (appears ~15 times)

These blocks build a `switcherpars_alt` with `base(3)` or `base(4)` and pass it to one `run_grc` call while still using `base(`base')`.

**Before (e.g., `5_GrRC.do` lines 164--177):**
```stata
define_switcherpars, switchers($switchers) base(2)
local switcherpars `r(switcherpars)'
define_switcherpars, switchers($switchers) base(3)
local switcherpars_alt `r(switcherpars)'
local iterations 500

* No covariates
run_grc, estname(grc_`country'_covs_0)                             ///
    switcherpars("`switcherpars_alt'") base(`base') initial(`initial') ///
    balance(`balance')                                             ///
    iterate(`iterations')
```

**After:**
```stata
local iterations 500

* No covariates (using alternative base for robustness)
run_grc, estname(grc_`country'_covs_0)                             ///
    switchers($switchers) base(3) initial(`initial')               ///
    balance(`balance')                                             ///
    iterate(`iterations')
```

**What changed:**
1. Delete all `define_switcherpars` and `local switcherpars*` lines
2. Replace `switcherpars("`switcherpars_alt'")` with `switchers($switchers)`
3. Replace `base(`base')` with `base(3)` (or `base(4)`)---the alternative base is now explicit and consistent

---

## Part 3: Files affected

| File | Call sites to update |
|------|---------------------|
| `0_programs.do` | Replace `run_grc` program (lines 1551--1666) |
| `5_GrRC.do` | 9 standard + 3 alt-base blocks |
| `6_GrRC_NonAg.do` | 1 standard |
| `8_GrRC_hukou.do` | 12 standard + 8 alt-base blocks |
| `10_GrRC_experience.do` | 9 standard + 1 alt-base |
| `11_GrRC_max_experience.do` | 9 standard + 1 alt-base |
| `12_GrRC_experience_share.do` | 9 standard + 1 alt-base |
| `13_GrRC_max_experience_share.do` | 9 standard + 1 alt-base |
| `14_GrRC_NonAg_experience.do` | 4 standard |
| `15_GrRC_birth.do` | 4 standard |
| `16_heterogeneity_tables.do` | 3 standard |

---

## Part 4: Verification

1. Re-run `5_GrRC.do` for all three countries, both depvars, both balance specs.
2. **Consumption-urban:** results should be identical to current tables if `initial_values` was already picking base=2. This confirms the fix is correct and the bug was dormant.
3. **Income:** results will change (especially IDN and TZA). The new results are the correct ones.
4. Check the log for `run_grc: base trajectory = N` lines to confirm which base was selected for each spec.
5. **LCA invariance check:** for one well-identified spec (e.g., IDN consumption), re-run with `base(2)` forced and compare to the data-adaptive base. Results should be very similar under exact LCA.
