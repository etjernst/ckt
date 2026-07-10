* ============================================================
* Title:   Benchmark reg_sandwich runtime as a function of J
* Author:  Emilia Tjernstrom (with Claude)
* Date:    2026-05-01
* Purpose: After 17 min on a single TZA covs_trend reg_sandwich
*          fit at J = 11012 with no completion, characterize the
*          scaling curve.  Sample J in {100, 500, 1000, 2000} and
*          time each fit.  Decision: does reg_sandwich scale to
*          our cluster counts at all?
* Input:   tza_covs_trend_design.dta
* Output:  benchmark_reg_sandwich.smcl
*          benchmark_reg_sandwich_out.txt
* ============================================================

clear all
set more off
set varabbrev off
capture log close
log using "benchmark_reg_sandwich.smcl", replace

set seed 20260501

capture noisily {
    use "tza_covs_trend_design.dta", clear

    local alphas "alpha_d_1 alpha_d_2 alpha_d_3 alpha_d_4 alpha_d_5 alpha_d_6 alpha_d_7 alpha_d_8"
    local betas  "beta_s_2 beta_s_4 beta_s_5 beta_s_6 beta_s_7"
    local nonbase_betas "beta_s_4 beta_s_5 beta_s_6 beta_s_7"
    local controls "period_2 period_3"
    local extras   "unbalanced unbalanced_choice"
    local indep "`alphas' `betas' `extras' `controls'"

    * Persist the full design as a tempfile so we can subsample without
    * losing the original.
    tempfile full
    save "`full'"

    * Open output file.
    file open OUT using "benchmark_reg_sandwich_out.txt", write replace
    file write OUT "J,N,wall_sec,F_stat,F_df1,F_df2,F_pvalue" _newline

    foreach J of numlist 100 500 1000 2000 {
        di as text ">>> J = `J'"
        use "`full'", clear

        * Sample J distinct pids.
        preserve
        keep pid
        duplicates drop pid, force
        sample `J', count
        tempfile keep_pids
        save "`keep_pids'"
        restore

        merge m:1 pid using "`keep_pids'", keep(match) nogenerate
        local N_sub = _N
        quietly levelsof pid, local(pp)
        local J_sub : word count `pp'
        di as text "    sampled: J=`J_sub' (target `J'), N=`N_sub'"

        timer clear 1
        timer on 1
        capture noisily reg_sandwich lndepvar `indep', cluster(pid)
        local rc_fit = _rc
        if `rc_fit' != 0 {
            di as error "    reg_sandwich rc=`rc_fit'"
            timer off 1
            file write OUT "`J_sub',`N_sub',NA,NA,NA,NA,NA" _newline
            continue
        }
        capture noisily test_sandwich `nonbase_betas'
        local rc_test = _rc
        timer off 1
        timer list 1
        local twall : di %12.4f r(t1)
        if `rc_test' != 0 {
            di as error "    test_sandwich rc=`rc_test'"
            file write OUT "`J_sub',`N_sub',`twall',NA,NA,NA,NA" _newline
            continue
        }

        local fs : di %20.10e e(F_stat)
        local d1 : di %20.10e e(F_df1)
        local d2 : di %20.10e e(F_df2)
        local pv : di %20.10e e(F_pvalue)

        di as text "    wall=`twall' s   F=`fs'   df2=`d2'   p=`pv'"
        file write OUT "`J_sub',`N_sub',`twall',`fs',`d1',`d2',`pv'" _newline
    }
    file close OUT
    di as text "wrote benchmark_reg_sandwich_out.txt"
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> benchmark_reg_sandwich.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
