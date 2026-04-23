# Message to RA: OLS time fixed effects bug

Hi David,

I noticed an issue with `gen_time_fe` in `0_programs.do` (the program you added on 2025-11-24 to replace the linear time trend with period fixed effects in the OLS regressions).

## The problem

The current code is:

```stata
program define gen_time_fe
    tab period, gen(period_)
    gen periodFE = period_2 - period_`r(r)'
end
```

This creates a **single numeric variable** equal to the arithmetic difference of two period dummies. For Indonesia (5 waves), `periodFE = period_2 - period_5`, which takes values 1 (wave 2), -1 (wave 5), and 0 (all other waves). That's one regressor capturing a single contrast between two periods---not a full set of period fixed effects.

When `reghdfe_regressions` includes `periodFE` as a covariate, it enters as one variable, so the OLS table effectively has one period contrast rather than T-1 period dummies. For Indonesia, 3 period effects are uncontrolled; for China, 2 are uncontrolled. Only Tanzania (3 waves, so T-1 = 2 dummies, but the single variable still captures only one contrast) is close, but even there the sign convention is non-standard.

## Why it went unnoticed

The GRC scripts happen to do it correctly. They each construct `local periodFE "period_2 - period_`r(r)'"` as a **local macro**, which Stata interprets as a varlist range expanding to all period dummies (`period_2 period_3 period_4 period_5` for Indonesia). The crucial difference:

- `gen periodFE = period_2 - period_5` → arithmetic subtraction, one numeric variable
- `local periodFE "period_2 - period_5"` → a string that Stata expands to the varlist `period_2 period_3 period_4 period_5`

So the GRC results are fine. Only the OLS table (`OLS_consumption_urban_unb.tex`) is affected.

## How to fix it

Option A (minimal change): In `reghdfe_regressions`, replace `periodFE` with a local macro varlist, matching what the GRC scripts already do:

```stata
program define reghdfe_regressions
    args country choice depvar balance

    * Create period FE varlist (range of all period dummies)
    qui tab period
    local periodFE "period_2 - period_`r(r)'"

    * Run col 7 first for e(sample)
    eststo reg7_`country': reghdfe lndepvar choice ///
        $lnsize $covs_all `periodFE' ///
        , vce(cluster pid) absorb(pid)
    gen regression_sample = e(sample)

    * Cols 1-6 with period dummies as explicit regressors
    eststo reg1_`country': reghdfe lndepvar choice $lnsize ///
        if regression_sample, noabsorb vce(cluster pid)
    eststo reg2_`country': reghdfe lndepvar choice $lnsize `periodFE' ///
        if regression_sample, noabsorb vce(cluster pid)
    * ... etc for cols 3-6, adding `periodFE' to each
end
```

Option B (cleaner): Use `absorb(period)` for cols (2)--(6) and `absorb(pid period)` for col (7). This avoids generating dummy variables at all:

```stata
    eststo reg2_`country': reghdfe lndepvar choice $lnsize $covs_1 ///
        if regression_sample, absorb(period) vce(cluster pid)
    * ...
    eststo reg7_`country': reghdfe lndepvar choice ///
        $lnsize $covs_all ///
        , vce(cluster pid) absorb(pid period)
```

Either option works. Option A is closer to the current code structure; Option B is cleaner but changes the `noabsorb` pattern.

You can also delete the `gen_time_fe` program entirely once the fix is in place---the numeric `periodFE` variable it creates is not needed by either approach.

After fixing, please regenerate the OLS tables and check whether the numbers change (they almost certainly will, since 3 period effects were previously omitted for IDN and 2 for CHN).
