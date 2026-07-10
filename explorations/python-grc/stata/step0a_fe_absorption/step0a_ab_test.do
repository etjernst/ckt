* ============================================================
* Title:   Step 0a -- FE-absorption A/B test for reg_sandwich
* Author:  Emilia Tjernstrom (with Claude)
* Date:    2026-05-01
* Purpose: Run the LCA auxiliary OLS twice on TZA covs_trend:
*          (A) unabsorbed -- alpha_d_* dummies as raw regressors
*          (B) absorbed   -- absorb(trajectory_id)
*          Capture AHZ statistic / df / p-value, CR2 SE on the
*          beta parameters, and wall time per call.  Joint test
*          is on the non-base beta_s_* dummies (q = J_R = 4).
*          Locks decision 8 of plan 2026-05-01-f-adjustment-inversion.
* Input:   tza_covs_trend_design.dta
* Output:  step0a_ab_test.smcl
*          step0a_ab_test_out.txt   (parsable scalars, both specs)
* ============================================================

clear all
set more off
set varabbrev off
capture log close
log using "step0a_ab_test.smcl", replace

capture noisily {
    * Load the pre-built design matrix.
    use "tza_covs_trend_design.dta", clear
    di as text "rows: " _N
    quietly levelsof pid, local(pids)
    local nclust : word count `pids'
    di as text "clusters: `nclust'"

    * Variables in the design.  Hard-coded to match the JSON sidecar
    * to avoid any in-band name parsing.
    local alphas "alpha_d_1 alpha_d_2 alpha_d_3 alpha_d_4 alpha_d_5 alpha_d_6 alpha_d_7 alpha_d_8"
    local betas  "beta_s_2 beta_s_4 beta_s_5 beta_s_6 beta_s_7"
    local nonbase_betas "beta_s_4 beta_s_5 beta_s_6 beta_s_7"
    local controls "period_2 period_3"
    local extras   "unbalanced unbalanced_choice"

    di as text ">>> Spec A: unabsorbed (alpha_d_* as raw regressors)"
    timer clear 1
    timer on 1
    reg_sandwich lndepvar `alphas' `betas' `extras' `controls', cluster(pid)
    timer off 1
    matrix b_A    = e(b)
    matrix V_A    = e(V)
    scalar N_A    = e(N)
    scalar Nclu_A = e(N_clusters)

    test_sandwich `nonbase_betas'
    scalar F_stat_A   = e(F_stat)
    scalar F_df1_A    = e(F_df1)
    scalar F_df2_A    = e(F_df2)
    scalar F_pvalue_A = e(F_pvalue)
    scalar F_eta_A    = e(F_eta)

    timer list 1
    scalar t_A = r(t1)

    * CR2 SEs on the non-base beta dummies.  Pull diagonal of V_A for
    * those parameters.
    foreach v of local nonbase_betas {
        matrix V_A_diag = V_A
        local pos = colnumb(V_A, "`v'")
        scalar se_A_`v' = sqrt(V_A[`pos', `pos'])
        di as text "  SE_A[`v'] = " %24.16e se_A_`v'
    }

    di as text ">>> Spec B: absorbed (absorb(trajectory_id))"
    timer clear 2
    timer on 2
    reg_sandwich lndepvar `betas' `extras' `controls', cluster(pid) absorb(trajectory_id)
    timer off 2
    matrix b_B    = e(b)
    matrix V_B    = e(V)
    scalar N_B    = e(N)
    scalar Nclu_B = e(N_clusters)

    test_sandwich `nonbase_betas'
    scalar F_stat_B   = e(F_stat)
    scalar F_df1_B    = e(F_df1)
    scalar F_df2_B    = e(F_df2)
    scalar F_pvalue_B = e(F_pvalue)
    scalar F_eta_B    = e(F_eta)

    timer list 2
    scalar t_B = r(t2)

    foreach v of local nonbase_betas {
        local pos = colnumb(V_B, "`v'")
        scalar se_B_`v' = sqrt(V_B[`pos', `pos'])
        di as text "  SE_B[`v'] = " %24.16e se_B_`v'
    }

    di as text "----- A/B summary -----"
    di as text "Spec A wall (s) = " %12.4f t_A
    di as text "Spec B wall (s) = " %12.4f t_B
    di as text "F_stat   A=" %20.10e F_stat_A "   B=" %20.10e F_stat_B
    di as text "F_df1    A=" %20.10e F_df1_A  "   B=" %20.10e F_df1_B
    di as text "F_df2    A=" %20.10e F_df2_A  "   B=" %20.10e F_df2_B
    di as text "F_pvalue A=" %20.10e F_pvalue_A "   B=" %20.10e F_pvalue_B

    * Persist all scalars at full precision via mata.
    mata: f = fopen("step0a_ab_test_out.txt", "w")
    mata: fput(f, "engine=stata_reg_sandwich")
    mata: fput(f, "country=TZA")
    mata: fput(f, "spec=covs_trend")
    mata: fput(f, sprintf("N_obs=%24.16e",   st_numscalar("N_A")))
    mata: fput(f, sprintf("N_clust=%24.16e", st_numscalar("Nclu_A")))
    mata: fput(f, sprintf("J_R=%24.16e",     st_numscalar("F_df1_A")))
    mata: fput(f, sprintf("A_F_stat=%24.16e",   st_numscalar("F_stat_A")))
    mata: fput(f, sprintf("A_F_df1=%24.16e",    st_numscalar("F_df1_A")))
    mata: fput(f, sprintf("A_F_df2=%24.16e",    st_numscalar("F_df2_A")))
    mata: fput(f, sprintf("A_F_pvalue=%24.16e", st_numscalar("F_pvalue_A")))
    mata: fput(f, sprintf("A_F_eta=%24.16e",    st_numscalar("F_eta_A")))
    mata: fput(f, sprintf("A_wall_sec=%24.16e", st_numscalar("t_A")))
    mata: fput(f, sprintf("A_se_beta_4=%24.16e", st_numscalar("se_A_beta_s_4")))
    mata: fput(f, sprintf("A_se_beta_5=%24.16e", st_numscalar("se_A_beta_s_5")))
    mata: fput(f, sprintf("A_se_beta_6=%24.16e", st_numscalar("se_A_beta_s_6")))
    mata: fput(f, sprintf("A_se_beta_7=%24.16e", st_numscalar("se_A_beta_s_7")))
    mata: fput(f, sprintf("B_F_stat=%24.16e",   st_numscalar("F_stat_B")))
    mata: fput(f, sprintf("B_F_df1=%24.16e",    st_numscalar("F_df1_B")))
    mata: fput(f, sprintf("B_F_df2=%24.16e",    st_numscalar("F_df2_B")))
    mata: fput(f, sprintf("B_F_pvalue=%24.16e", st_numscalar("F_pvalue_B")))
    mata: fput(f, sprintf("B_F_eta=%24.16e",    st_numscalar("F_eta_B")))
    mata: fput(f, sprintf("B_wall_sec=%24.16e", st_numscalar("t_B")))
    mata: fput(f, sprintf("B_se_beta_4=%24.16e", st_numscalar("se_B_beta_s_4")))
    mata: fput(f, sprintf("B_se_beta_5=%24.16e", st_numscalar("se_B_beta_s_5")))
    mata: fput(f, sprintf("B_se_beta_6=%24.16e", st_numscalar("se_B_beta_s_6")))
    mata: fput(f, sprintf("B_se_beta_7=%24.16e", st_numscalar("se_B_beta_s_7")))
    mata: fclose(f)
    di as text "wrote step0a_ab_test_out.txt"
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> step0a_ab_test.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
