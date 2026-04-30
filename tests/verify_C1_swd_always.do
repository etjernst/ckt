* ============================================================
* Title:   Verify C1 from run_grc_robust_vv audit memo
* Author:  Emilia (with Claude)
* Date:    2026-04-30
* Purpose: Test the claim that swd_always_choice is identically zero
*          across the sample. If true, the moment
*          E[swd_always_choice * u] = 0 is trivially satisfied for
*          any parameter vector and provides no information about
*          kappa. See:
*          quality_reports/reviews/2026-04-29_run-grc-robust-vv-audit.md
*          (post-implementation section, finding C1)
* Inputs:  $dirdata/processed/{IDN,TZA,CHN}_unb.dta
* Outputs: $dir/output/verify_C1_swd_always.txt
*          $dir/output/verify_C1_kappa_with.ster   (CHN focal cell, with swd_always_choice)
*          $dir/output/verify_C1_kappa_without.ster (CHN focal cell, swd_always_choice dropped)
* ============================================================

* ============================================================
* Defensive prelude (same pattern as 17_verdier_robust.do)
* ============================================================
if "$dir" == "" {
    clear all
    if "`c(username)'" == "maand" {
        global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
    }
    quietly include "$dir/scripts/0_path_config.do"
    quietly include "$dir/scripts/0_setup.do"
    quietly include "$dir/scripts/0_programs.do"
}

cd "$logs"
capture log close
log using verify_C1_swd_always.log, replace

* Output text file: full-precision, grep-able audit trail.
tempname fh
file open `fh' using "$dir/output/verify_C1_swd_always.txt", write replace
file write `fh' "Verification: swd_always_choice nonzero counts" _n
file write `fh' "Generated: $S_DATE $S_TIME" _n
file write `fh' "Source: tests/verify_C1_swd_always.do" _n _n

capture noisily {

    * ============================================================
    * Per-country diagnostic block
    * ============================================================
    local choice  urban
    local depvar  consumption
    local balance unb

    foreach country in IDN TZA CHN {

        if "`country'" == "IDN" local vidx prov
        if "`country'" == "TZA" local vidx region
        if "`country'" == "CHN" local vidx provcd

        di as txt _n "================================================================"
        di as txt "verify_C1: country=`country' vindex=`vidx'"
        di as txt "================================================================"

        file write `fh' "================================================================" _n
        file write `fh' "Country: `country'  vindex=`vidx'" _n
        file write `fh' "================================================================" _n

        use "$dirdata/processed/`country'_`balance'.dta", clear
        replace lndepvar = log(consumption/hhsize_cube)
        setup_grc_estimation
        global keepvars lndepvar trajectory choice pid year
        global keepvars $keepvars period unbalanced* switcher non_switcher
        global keepvars $keepvars female age age2
        global keepvars $keepvars education_max education_max2 trend
        global keepvars $keepvars always always_choice never switcher_*
        global keepvars $keepvars `vidx'
        keep $keepvars

        * (1) Build vfirst, drop missing, reproduce demean exactly as in
        *     run_grc_robust_vv L2412-2455.
        gen_vfirst, vname(`vidx') genname(vfirst)
        qui count if missing(vfirst)
        local n_drop = r(N)
        qui drop if missing(vfirst)
        qui count
        local n_after = r(N)

        di as txt "  obs after vfirst drop = `n_after' (dropped `n_drop')"
        file write `fh' "  obs after vfirst drop: " %12.0fc (`n_after') ///
            "   (dropped: " %6.0fc (`n_drop') ")" _n

        * (2) Tabulate choice when always == 1 to verify the structural claim
        *     that always-urban have choice == 1 in every period.
        qui count if always == 1
        local n_always_obs = r(N)
        qui count if always == 1 & choice == 1
        local n_always_choice1 = r(N)
        qui count if always == 1 & choice == 0
        local n_always_choice0 = r(N)
        qui count if always == 1 & missing(choice)
        local n_always_chmiss = r(N)

        di as txt "  always==1 obs: `n_always_obs'"
        di as txt "    choice==1: `n_always_choice1'"
        di as txt "    choice==0: `n_always_choice0'"
        di as txt "    choice==.: `n_always_chmiss'"
        file write `fh' "  always==1 obs: " %12.0fc (`n_always_obs') _n
        file write `fh' "    choice==1: "    %12.0fc (`n_always_choice1') _n
        file write `fh' "    choice==0: "    %12.0fc (`n_always_choice0') _n
        file write `fh' "    choice==.: "    %12.0fc (`n_always_chmiss') _n

        * (3) Reproduce the demean: regress always_choice on i.vfirst among
        *     workers with always==1, take residuals, zero-fill elsewhere.
        capture drop swd_always_choice
        tempvar tmpy tmpresid
        qui gen `tmpy' = always_choice if always == 1
        qui reg `tmpy' i.vfirst if always == 1
        qui predict `tmpresid' if always == 1, resid
        qui gen swd_always_choice = `tmpresid'
        qui replace swd_always_choice = 0 if missing(swd_always_choice)

        * (4) The verification line: count nonzero swd_always_choice.
        qui count if swd_always_choice != 0
        local n_nonzero = r(N)
        qui count
        local n_total = r(N)
        qui sum swd_always_choice, detail
        local sd_swd = r(sd)
        local min_swd = r(min)
        local max_swd = r(max)

        di as txt _n "  swd_always_choice diagnostics:"
        di as txt "    nonzero obs: `n_nonzero' / `n_total'"
        di as txt "    sd: " %12.6e (`sd_swd')
        di as txt "    range: [" %12.6e (`min_swd') ", " %12.6e (`max_swd') "]"

        file write `fh' _n "  swd_always_choice nonzero obs: " ///
            %12.0fc (`n_nonzero') " / " %12.0fc (`n_total') _n
        file write `fh' "    sd:    " %16.6e (`sd_swd')  _n
        file write `fh' "    min:   " %16.6e (`min_swd') _n
        file write `fh' "    max:   " %16.6e (`max_swd') _n _n
    }

    * ============================================================
    * Focal-cell GMM: refit CHN covs_all onestep, once with the
    * existing instrument set (matches run_grc_robust_vv) and once
    * without swd_always_choice. Compare kappa to see whether the
    * point estimate moves when the dead-weight instrument is dropped.
    *
    * Hard-coded to CHN covs_all because that's the focal cell in the
    * paper's robustness table; the question is whether kappa estimates
    * in production are stable to the instrument set.
    * ============================================================
    di as txt _n "================================================================"
    di as txt "Focal-cell GMM comparison (CHN covs_all onestep)"
    di as txt "================================================================"
    file write `fh' "================================================================" _n
    file write `fh' "Focal-cell GMM comparison: CHN covs_all onestep" _n
    file write `fh' "================================================================" _n

    use "$dirdata/processed/CHN_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    local vidx provcd
    global keepvars lndepvar trajectory choice pid year
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*
    global keepvars $keepvars `vidx'
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * Initial values for kappa comparison
    initial_values lndepvar,        ///
        switchers($switchers)       ///
        balance(unb)                ///
        estname(verify_C1_init)
    local base `r(base)'
    local initial "`r(initial)'"

    * Reload + redo demean (initial_values may have left side effects)
    use "$dirdata/processed/CHN_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars
    tab period, gen(period_)
    gen_vfirst, vname(`vidx') genname(vfirst)
    qui drop if missing(vfirst)

    * Build swd_switcher_*_choice exactly as in the program
    local swd_list ""
    foreach s of numlist $switchers {
        capture drop swd_switcher_`s'_choice
        tempvar tmpy tmpresid
        qui gen `tmpy' = switcher_`s'_choice if switcher_`s' == 1
        qui reg `tmpy' i.vfirst if switcher_`s' == 1
        qui predict `tmpresid' if switcher_`s' == 1, resid
        qui gen swd_switcher_`s'_choice = `tmpresid'
        qui replace swd_switcher_`s'_choice = 0 if missing(swd_switcher_`s'_choice)
        local swd_list "`swd_list' swd_switcher_`s'_choice"
    }
    capture drop swd_always_choice
    tempvar tmpy2 tmpresid2
    qui gen `tmpy2' = always_choice if always == 1
    qui reg `tmpy2' i.vfirst if always == 1
    qui predict `tmpresid2' if always == 1, resid
    qui gen swd_always_choice = `tmpresid2'
    qui replace swd_always_choice = 0 if missing(swd_always_choice)

    local covarlist "`periodFE' female age2 education_max education_max2 unbalanced unbalanced_choice"
    local switcher_traj
    foreach s of numlist $switchers {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }
    define_switcherpars, switchers($switchers) base(`base')
    local switcherpars `r(switcherpars)'

    * (A) WITH swd_always_choice (matches run_grc_robust_vv)
    di as txt _n "  Fit (A): WITH swd_always_choice"
    eststo verify_with: gmm (lndepvar - {mu: never `switcher_traj'}              ///
                            - {Delta_base}*choice                                 ///
                            - {phi=-1}*(`switcherpars')                           ///
                            - ({kappa}+{phi}*({kappa}                             ///
                            - {mu: switcher_`base'}))*(always#1.choice)           ///
                            - {xb: `covarlist'})                                  ///
                           , instruments(                                         ///
                            `covarlist'                                           ///
                            never `switcher_traj' choice                          ///
                            swd_always_choice `swd_list', nocons                  ///
                           )                                                      ///
                             vce(cluster vfirst)                                  ///
                             winitial(unadjusted, independent)                    ///
                             onestep                                              ///
                             from(`initial')                                      ///
                             quickderivatives nolog                               ///
                             iterate(100)
    local kappa_with = _b[kappa:_cons]
    local kappa_with_se = _se[kappa:_cons]
    local phi_with = _b[phi:_cons]
    local phi_with_se = _se[phi:_cons]
    local conv_with = e(converged)
    estimates save "$dir/output/verify_C1_kappa_with", replace

    * (B) WITHOUT swd_always_choice (drops the dead-weight instrument)
    di as txt _n "  Fit (B): WITHOUT swd_always_choice"
    eststo verify_without: gmm (lndepvar - {mu: never `switcher_traj'}            ///
                            - {Delta_base}*choice                                 ///
                            - {phi=-1}*(`switcherpars')                           ///
                            - ({kappa}+{phi}*({kappa}                             ///
                            - {mu: switcher_`base'}))*(always#1.choice)           ///
                            - {xb: `covarlist'})                                  ///
                           , instruments(                                         ///
                            `covarlist'                                           ///
                            never `switcher_traj' choice                          ///
                            `swd_list', nocons                                    ///
                           )                                                      ///
                             vce(cluster vfirst)                                  ///
                             winitial(unadjusted, independent)                    ///
                             onestep                                              ///
                             from(`initial')                                      ///
                             quickderivatives nolog                               ///
                             iterate(100)
    local kappa_without = _b[kappa:_cons]
    local kappa_without_se = _se[kappa:_cons]
    local phi_without = _b[phi:_cons]
    local phi_without_se = _se[phi:_cons]
    local conv_without = e(converged)
    estimates save "$dir/output/verify_C1_kappa_without", replace

    di as txt _n "================================================================"
    di as txt "Comparison: CHN covs_all onestep, kappa estimate"
    di as txt "================================================================"
    di as txt "  WITH    swd_always_choice: kappa = " %10.6f (`kappa_with')    ///
        " (se " %10.6f (`kappa_with_se') ")  conv=`conv_with'"
    di as txt "  WITHOUT swd_always_choice: kappa = " %10.6f (`kappa_without') ///
        " (se " %10.6f (`kappa_without_se') ")  conv=`conv_without'"
    di as txt "  difference: " %10.6f (`kappa_with' - `kappa_without')
    di as txt "  phi WITH    = " %10.6f (`phi_with')    " (se " %10.6f (`phi_with_se')    ")"
    di as txt "  phi WITHOUT = " %10.6f (`phi_without') " (se " %10.6f (`phi_without_se') ")"

    file write `fh' "  WITH    swd_always_choice: kappa = " %12.6e (`kappa_with') ///
        "  se= " %12.6e (`kappa_with_se') "  conv=`conv_with'" _n
    file write `fh' "  WITHOUT swd_always_choice: kappa = " %12.6e (`kappa_without') ///
        "  se= " %12.6e (`kappa_without_se') "  conv=`conv_without'" _n
    file write `fh' "  diff(kappa): " %12.6e (`kappa_with' - `kappa_without') _n
    file write `fh' "  phi WITH    = " %12.6e (`phi_with')    "  se= " %12.6e (`phi_with_se')    _n
    file write `fh' "  phi WITHOUT = " %12.6e (`phi_without') "  se= " %12.6e (`phi_without_se') _n
    file write `fh' "  diff(phi): "    %12.6e (`phi_with' - `phi_without') _n
}

local saved_rc = _rc
file close `fh'
capture log close
if `saved_rc' != 0 {
    di as error ">>> verify_C1_swd_always.do FAILED with rc=`saved_rc'"
}

exit, STATA clear
