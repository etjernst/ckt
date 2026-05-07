* ============================================================
* Title:   Phase C: equivalence MC for trajectory-pooled vs worker-level LCA
* Author:  Emilia (with Claude)
* Date:    2026-04-25
* Purpose: Monte Carlo for the equivalence claim in
*          docs/reviews/2026-04-25_robust-vv-equivalence-proof.md.
*          Three regimes:
*            R1  : A3 holds, uniform cluster assignment. Both estimators
*                  should be consistent for phi_true.
*            R2a : Mode B (differential cluster assignment, A3 holds).
*                  P(v|s) propto 1 + lambda*g(s)*h(v). Trajectory-pooled
*                  CKT picks up alpha-pooling bias ~ -0.18*lambda;
*                  VV worker-level stays consistent.
*            R2b : Mode A (theta-tilt, A3 fails).
*                  theta_i ~ N(m_s + lambda*g(s)*h(v_i), sigma_theta^2).
*                  Both estimators biased.
*          Per Phase A.1 the VV moment targets alpha_1 = 1/phi; we report
*          1/alpha_1 as the comparable estimate.
* Input:   None (in-memory). Requires RP7/scripts/0_programs.do.
* Output:  x_equivalence_simulation.smcl / .txt
*          x_equivalence_simulation_results.dta (one row per regime x rep)
* Plan:    docs/plans/valiant-sleeping-trinket.md Phase C.
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
include "$dir/scripts/0_path_config.do"

* Redirect $dir to RP7 so .ster files land in RP7/output
capture mkdir "$dir/RP7/output"
global dir "$dir/RP7"
global output "$dir/output"
cd "$dir/../explorations/verdier"

log using "x_equivalence_simulation.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

* ============================================================
* MC parameters
* ============================================================
capture noisily {

    local n_reps      100
    local N           4000
    local T           4
    local V           25
    local phi_true    -0.7
    local sigma_theta 0.5
    local sigma_xi    0.3
    local sigma_u     0.3
    local sigma_beta  0.4
    local c1          1.0
    local c2          0.5
    local m_slope     0.1
    local lambda_r2a  1.0
    local lambda_r2b  1.0
    local seed_base   20260425

    local results_dta "x_equivalence_simulation_results.dta"
    capture rm "`results_dta'"

    tempname pf
    postfile `pf' str4 regime int rep                         ///
        double phi_ckt se_ckt phi_vv_inv se_vv_inv            ///
        double tv_realized n_switchers ckt_ok vv_ok           ///
        using "`results_dta'", replace

    foreach regime in "R1" "R2a" "R2b" {

        di as result _newline(2) "######### regime = `regime' #########"

        * Per-regime seed offset so different regimes don't share rep seeds
        if "`regime'" == "R1"  local seed_offset 0
        if "`regime'" == "R2a" local seed_offset 100000
        if "`regime'" == "R2b" local seed_offset 200000

        forvalues r = 1/`n_reps' {

            local seed = `seed_base' + `seed_offset' + `r'
            di as result _newline "--- regime=`regime' rep=`r' seed=`seed' ---"

            local ckt_ok = 0
            local vv_ok  = 0
            local phi_ckt = .
            local se_ckt  = .
            local phi_vv_inv = .
            local se_vv_inv  = .
            local tv_realized = .
            local n_sw_rep = .

            capture noisily {

                clear
                set seed `seed'

                * --------------------------------------------------------
                * DGP: trajectory and (regime-dependent) cluster assignment
                * --------------------------------------------------------
                set obs `N'
                gen long pid = _n

                * Trajectory: uniform 1..16. Trajectory 1=never (RRRR),
                * 16=always (UUUU). Switchers are 2..15.
                gen int trajectory = 1 + floor(16 * runiform())

                * Cluster assignment
                if "`regime'" == "R2a" {
                    * Mode B: P(v|s) propto 1 + lambda*g(s)*h(v).
                    * Discrete inverse-CDF sampling per pid.
                    gen double g_s = (trajectory - 8.5) / 7.5
                    gen byte vfirst_true = .
                    forvalues v = 1/`V' {
                        local h_v = (`v' - (`V'+1)/2) / ((`V'-1)/2)
                        gen double w_v_`v' = (1 + `lambda_r2a' * g_s * `h_v') / `V'
                    }
                    * Cumulative sums and uniform draw
                    gen double w_cum_0 = 0
                    forvalues v = 1/`V' {
                        local vm1 = `v' - 1
                        gen double w_cum_`v' = w_cum_`vm1' + w_v_`v'
                    }
                    gen double u_v = runiform()
                    forvalues v = 1/`V' {
                        local vm1 = `v' - 1
                        replace vfirst_true = `v' if missing(vfirst_true) ///
                            & u_v > w_cum_`vm1' & u_v <= w_cum_`v'
                    }
                    * Edge case: u rounding may leave vfirst missing
                    replace vfirst_true = `V' if missing(vfirst_true)
                    drop g_s w_v_* w_cum_* u_v
                }
                else {
                    * R1, R2b: uniform cluster
                    gen byte vfirst_true = 1 + floor(`V' * runiform())
                }

                * h(v) and m(s)
                gen double h_v = (vfirst_true - (`V'+1)/2) / ((`V'-1)/2)
                gen double m_s = `m_slope' * (trajectory - 8.5)

                * theta_i: regime-dependent
                if "`regime'" == "R2b" {
                    * Mode A: theta tilted by lambda*g(s)*h(v)
                    gen double g_s = (trajectory - 8.5) / 7.5
                    gen double theta_i = m_s + `lambda_r2b' * g_s * h_v ///
                        + `sigma_theta' * rnormal()
                    drop g_s
                }
                else {
                    gen double theta_i = m_s + `sigma_theta' * rnormal()
                }

                * beta(v) = sigma_beta * h(v); alpha_i = c1*theta + c2*eta
                gen double beta_v  = `sigma_beta' * h_v
                gen double eta_i   = rnormal()
                gen double alpha_i = `c1' * theta_i + `c2' * eta_i
                gen double xi_i    = `sigma_xi' * rnormal()
                gen double Delta_i = beta_v + `phi_true' * theta_i + xi_i

                * Expand to panel
                expand `T'
                bysort pid: gen byte t = _n
                gen int period = t
                gen int year = 2000 + t

                * D_it = bit_(T-t+1) of (trajectory - 1), MSB to LSB
                gen byte D_it = mod(floor((trajectory - 1) / 2^(`T' - t)), 2)
                rename D_it choice

                * Outcome
                gen double u_it = `sigma_u' * rnormal()
                gen double lndepvar = alpha_i + Delta_i * choice + u_it

                * Setup placeholders for setup_grc_estimation
                gen byte female = 0
                gen byte age = 40
                gen double age2 = age^2
                gen byte education_max = 0
                gen double education_max2 = education_max^2
                gen byte unbalanced = 0
                gen byte unbalanced_choice = 0

                * vfirst lookup variable
                gen int prov = vfirst_true

                sort pid period
                xtset pid period

                * --------------------------------------------------------
                * CKT pipeline setup
                * --------------------------------------------------------
                setup_grc_estimation

                qui sum trajectory
                local maxtraj = r(max)
                capture drop switcher non_switcher pid_first_obs
                gen byte switcher     = (trajectory > 1 & trajectory < `maxtraj')
                gen byte non_switcher = (trajectory == 1 | trajectory == `maxtraj')
                bysort pid (year): gen byte pid_first_obs = (_n == 1)

                * vfirst (override gen_vfirst since we have prov already)
                capture drop vfirst
                gen int vfirst = prov

                * Switcher count this rep (worker-level)
                qui count if switcher == 1 & pid_first_obs == 1
                local n_sw_rep = r(N)

                * --------------------------------------------------------
                * Realized TV distance (R2a only -- diagnostic for cal)
                * Mean pairwise TV across switcher trajectories.
                * --------------------------------------------------------
                if "`regime'" == "R2a" {
                    preserve
                        keep if switcher == 1 & pid_first_obs == 1
                        qui tab trajectory
                        local n_sw_traj = r(r)
                        if `n_sw_traj' >= 2 {
                            * Build P(v|s) matrix
                            qui levelsof trajectory, local(slist)
                            tempname Pmat
                            mat `Pmat' = J(`n_sw_traj', `V', 0)
                            local i_s = 0
                            foreach s of local slist {
                                local i_s = `i_s' + 1
                                qui count if trajectory == `s'
                                local n_s = r(N)
                                forvalues v = 1/`V' {
                                    qui count if trajectory == `s' & vfirst == `v'
                                    mat `Pmat'[`i_s', `v'] = r(N) / `n_s'
                                }
                            }
                            * Mean pairwise TV
                            local tv_sum = 0
                            local n_pairs = 0
                            forvalues a = 1/`n_sw_traj' {
                                forvalues b = `=`a'+1'/`n_sw_traj' {
                                    local tv_ab = 0
                                    forvalues v = 1/`V' {
                                        local d_ab = `Pmat'[`a',`v'] - `Pmat'[`b',`v']
                                        if `d_ab' < 0 local d_ab = -`d_ab'
                                        local tv_ab = `tv_ab' + `d_ab'
                                    }
                                    local tv_sum = `tv_sum' + 0.5 * `tv_ab'
                                    local n_pairs = `n_pairs' + 1
                                }
                            }
                            if `n_pairs' > 0 local tv_realized = `tv_sum' / `n_pairs'
                        }
                    restore
                }
                else {
                    local tv_realized = 0
                }

                * --------------------------------------------------------
                * Estimator 1: CKT trajectory-pooled run_grc_robust_vv
                * --------------------------------------------------------
                qui tab period, gen(period_)
                qui levelsof period, local(pers)
                local n_per : word count `pers'
                local periodFE "period_2 - period_`n_per'"

                capture noisily {
                    qui initial_values lndepvar,         ///
                        switchers($switchers)            ///
                        balance(unb)                     ///
                        estname(mc_init)
                    local base    `r(base)'
                    local initial "`r(initial)'"

                    qui run_grc_robust_vv,               ///
                        estname(mc_robust_vv)            ///
                        switchers($switchers)            ///
                        base(`base')                     ///
                        initial(`initial')               ///
                        balance(unb) vindex(prov)        ///
                        covars(`periodFE')               ///
                        iterate(500)

                    qui estimates use "$output/mc_robust_vv"
                    local phi_ckt = _b[phi:_cons]
                    local se_ckt  = _se[phi:_cons]
                    local ckt_ok = 1
                }

                * --------------------------------------------------------
                * Estimator 2: VV worker-level Chamberlain + GMM
                * --------------------------------------------------------
                capture noisily {
                    capture drop pid_choice
                    gen long pid_choice = pid * 10 + choice

                    qui areg lndepvar period_2-period_`n_per', absorb(pid_choice)
                    capture drop d_hat
                    qui predict d_hat if e(sample), d

                    capture drop a_pid apb_pid a apb return_pid
                    bysort pid: egen a_pid   = mean(d_hat) if choice == 0
                    bysort pid: egen apb_pid = mean(d_hat) if choice == 1
                    bysort pid: egen a       = max(a_pid)
                    bysort pid: egen apb     = max(apb_pid)
                    drop a_pid apb_pid
                    gen return_pid = apb - a

                    * Village-demeaned period-treatment instruments
                    local instr_list ""
                    forvalues p = 1/`n_per' {
                        capture drop hybrid`p' hybrid`p'd _tmp_h
                        gen _tmp_h = choice if period == `p'
                        bysort pid: egen hybrid`p' = max(_tmp_h)
                        drop _tmp_h
                        qui reg hybrid`p' i.vfirst if switcher == 1
                        qui predict hybrid`p'd if switcher == 1, resid
                        qui replace hybrid`p'd = 0 if missing(hybrid`p'd)
                        local instr_list "`instr_list' hybrid`p'd"
                    }

                    preserve
                        qui collapse (mean) a return_pid `instr_list' ///
                            (first) vfirst switcher, by(pid)

                        local instr_kept ""
                        foreach inst of local instr_list {
                            qui sum `inst' if switcher == 1
                            if r(sd) > 1e-8 local instr_kept "`instr_kept' `inst'"
                        }

                        capture noisily {
                            qui gmm (a - {alpha0} - {alpha1}*return_pid),  ///
                                instruments(`instr_kept')                  ///
                                vce(cluster vfirst)                        ///
                                winitial(unadjusted, independent)          ///
                                onestep                                    ///
                                quickderivatives nolog                     ///
                                iterate(500)

                            local alpha1 = _b[alpha1:_cons]
                            local se_a1  = _se[alpha1:_cons]
                            if !missing(`alpha1') & abs(`alpha1') > 1e-6 {
                                local phi_vv_inv = 1 / `alpha1'
                                local se_vv_inv  = `se_a1' / (`alpha1')^2
                                local vv_ok = 1
                            }
                        }
                    restore
                }

                di as result "rep=`r' regime=`regime' " ///
                    "ckt_phi=" %7.4f `phi_ckt' " (ok=`ckt_ok') " ///
                    "vv_phi=" %7.4f `phi_vv_inv' " (ok=`vv_ok') " ///
                    "tv=" %6.4f `tv_realized'
            }

            post `pf' ("`regime'") (`r')                                    ///
                (cond(missing(`phi_ckt'), ., `phi_ckt'))                    ///
                (cond(missing(`se_ckt'), ., `se_ckt'))                      ///
                (cond(missing(`phi_vv_inv'), ., `phi_vv_inv'))              ///
                (cond(missing(`se_vv_inv'), ., `se_vv_inv'))                ///
                (cond(missing(`tv_realized'), ., `tv_realized'))            ///
                (cond(missing(`n_sw_rep'), ., `n_sw_rep'))                  ///
                (`ckt_ok') (`vv_ok')
        }
    }

    postclose `pf'

    * ============================================================
    * Summary
    * ============================================================
    use "`results_dta'", clear

    di as result _newline(2) "###### MC summary ######"
    di as result "phi_true = `phi_true'"

    bysort regime: gen reps_done = _n == _N
    bysort regime: egen ckt_pass_n = total(ckt_ok)
    bysort regime: egen vv_pass_n  = total(vv_ok)

    di as result _newline "Convergence rates by regime:"
    tabstat ckt_ok vv_ok, by(regime) stat(mean N)

    di as result _newline "CKT phi summary (ckt_ok==1):"
    tabstat phi_ckt if ckt_ok == 1, by(regime) stat(mean sd N)

    di as result _newline "VV 1/alpha1 summary (vv_ok==1):"
    tabstat phi_vv_inv if vv_ok == 1, by(regime) stat(mean sd N)

    di as result _newline "Realized TV (R2a only):"
    tabstat tv_realized if regime == "R2a", stat(mean sd N)

    save "`results_dta'", replace
}

log close
capture translate "x_equivalence_simulation.smcl" ///
    "x_equivalence_simulation.txt", replace
exit, STATA clear
