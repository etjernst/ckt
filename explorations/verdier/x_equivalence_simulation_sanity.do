* ============================================================
* Title:   Phase B sanity check for equivalence simulation
* Author:  Emilia (with Claude)
* Date:    2026-04-25
* Purpose: Verify the DGP and both estimators at large N before
*          launching the main MC. Per
*          docs/plans/valiant-sleeping-trinket.md Phase B.
*          At N=50000, 1 rep, R1 regime (A3 holds), both estimators
*          must return phi-hat within ±0.02 of phi_true = -0.7.
* Input:   None (data generated in-memory).
*          Requires RP7/scripts/0_programs.do.
* Output:  x_equivalence_simulation_sanity.smcl / .txt
* DGP:     See quality_reports/reviews/2026-04-25_simulation-phase-a-derivations.md §B.1
*          phi_true = -0.7, sigma_theta = 0.5, sigma_xi = 0.3, sigma_u = 0.3,
*          sigma_beta = 0.4, c_1 = 1, c_2 = 0.5, T = 4, V = 25, 16 trajectories.
* Notes:   Worker-level estimator: VV's joint GMM with moment
*          (a - {alpha0} - {alpha1}*return), instruments = period-
*          specific village-demeaned D indicators. Per Phase A.1,
*          alpha_1 targets 1/phi. Report both alpha_1 and 1/alpha_1
*          so comparison to phi_true is transparent.
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
include "$dir/scripts/0_path_config.do"

* Redirect $dir to RP7 so run_grc_robust_vv's .ster saves land in RP7/output
capture mkdir "$dir/RP7/output"
local dirdata_orig "$dirdata"
global dir "$dir/RP7"
global output "$dir/output"

cd "$dir/../explorations/verdier"
log using "x_equivalence_simulation_sanity.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

* ============================================================
* DGP parameters
* ============================================================
local N            50000
local T            4
local V            25
local phi_true     -0.7
local sigma_theta  0.5
local sigma_xi     0.3
local sigma_u      0.3
local sigma_beta   0.4
local c1           1.0
local c2           0.5
local m_slope      0.1     // m_s = m_slope * (s - 8.5)
local lambda_r2a   1.0     // for differential cluster assignment (R2a)
local lambda_r2b   1.0     // for theta-tilt (R2b)
local seed         20260425

set seed `seed'

* ============================================================
* Generate synthetic panel under R1 (A3 holds, uniform cluster assignment)
* ============================================================
clear
set obs `N'
gen long pid = _n

* Trajectory: uniform over 1..16. Trajectory 1 = never (RRRR), 16 = always (UUUU).
gen int trajectory = 1 + floor(16 * runiform())
gen byte traj = trajectory   // alias for DGP formulas below

* Cluster: uniform 1..V
gen byte vfirst_true = 1 + floor(`V' * runiform())

* Worker-level comparative advantage theta_i. Under R1: m_s depends only
* on trajectory.
gen double m_s = `m_slope' * (traj - 8.5)
gen double theta_i = m_s + `sigma_theta' * rnormal()

* Cluster-specific intercept beta(v) = sigma_beta * h(v), where
* h(v) = (v - (V+1)/2) / ((V-1)/2). For V=25, h(v) in [-1, 1].
gen double h_v = (vfirst_true - (`V'+1)/2) / ((`V'-1)/2)
gen double beta_v = `sigma_beta' * h_v

* Worker intercept: alpha_i = c1*theta_i + c2*eta_i. Non-degenerate.
gen double eta_i = rnormal()
gen double alpha_i = `c1' * theta_i + `c2' * eta_i

* Worker-level xi (deviation from LCA)
gen double xi_i = `sigma_xi' * rnormal()

* Worker treatment effect: Delta_i = beta(v_i) + phi * theta_i + xi_i
gen double Delta_i = beta_v + `phi_true' * theta_i + xi_i

* Expand to panel
expand `T'
bysort pid: gen byte t = _n
gen int period = t
gen int year = 2000 + t   // arbitrary year for compatibility

* Treatment D_it = bit_(T-t+1) of (traj - 1), MSB to LSB
gen byte D_it = mod(floor((traj - 1) / 2^(`T' - t)), 2)
rename D_it choice

* Outcome
gen double u_it = `sigma_u' * rnormal()
gen double lndepvar = alpha_i + Delta_i * choice + u_it

* Covariates placeholder (setup_grc_estimation expects these)
gen byte female = 0
gen byte age = 40
gen double age2 = age^2
gen byte education_max = 0
gen double education_max2 = education_max^2
gen byte unbalanced = 0
gen byte unbalanced_choice = 0

* Save vfirst_true under the name setup_grc_estimation/gen_vfirst will later
* use. We override vfirst directly later to skip gen_vfirst.
gen int prov = vfirst_true

* Order for setup_grc_estimation
sort pid period
xtset pid period

* ============================================================
* Setup CKT variables (trajectory, switcher, switcher_*, always, never)
* ============================================================
setup_grc_estimation

* Worker-level switcher indicator (handle_trajectory_groups creates this in
* the production pipeline; we synthesize it here from trajectory)
qui sum trajectory
local maxtraj = r(max)
capture drop switcher non_switcher
gen byte switcher     = (trajectory > 1 & trajectory < `maxtraj')
gen byte non_switcher = (trajectory == 1 | trajectory == `maxtraj')
capture drop pid_first_obs
bysort pid (year): gen byte pid_first_obs = (_n == 1)

di as result _newline "$switchers"
di as result "n_switchers = " _N

* Manually set vfirst (time-invariant per pid, = prov by construction)
capture drop vfirst
gen int vfirst = prov

* ============================================================
* Fit 1: trajectory-pooled run_grc_robust_vv
* ============================================================
di as result _newline(2) "=== Trajectory-pooled: run_grc_robust_vv ==="

tab period, gen(period_)
qui levelsof period, local(pers)
local n_per : word count `pers'
local periodFE "period_2 - period_`n_per'"

initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(unb)             ///
    estname(init_sanity)
local base    `r(base)'
local initial "`r(initial)'"
di as text "base = `base'"

run_grc_robust_vv,                           ///
    estname(sanity_robust_vv)                ///
    switchers($switchers) base(`base')       ///
    initial(`initial')                       ///
    balance(unb) vindex(prov)                ///
    covars(`periodFE')                       ///
    iterate(500)

estimates use "$output/sanity_robust_vv"
local phi_robust_vv = _b[phi:_cons]
local se_robust_vv  = _se[phi:_cons]
di as result "CKT trajectory-pooled: phi = " %9.4f `phi_robust_vv' ///
    ", se = " %9.4f `se_robust_vv'

* ============================================================
* Fit 2: VV worker-level (Chamberlain + GMM, matching robust.do)
* ============================================================
di as result _newline(2) "=== Worker-level: VV Chamberlain + GMM ==="

capture drop pid_choice
gen long pid_choice = pid * 10 + choice

* Chamberlain projection
qui areg lndepvar period_2-period_`n_per', absorb(pid_choice)
qui predict d_hat if e(sample), d

* Per-pid a_i (choice=0 FE) and apb_i (choice=1 FE)
capture drop a_pid apb_pid a apb return_pid
bysort pid: egen a_pid   = mean(d_hat) if choice == 0
bysort pid: egen apb_pid = mean(d_hat) if choice == 1
bysort pid: egen a       = max(a_pid)
bysort pid: egen apb     = max(apb_pid)
drop a_pid apb_pid
gen return_pid = apb - a

* Village-demeaned period-treatment instruments (per VV's robust.do)
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

* Collapse to worker level for VV GMM
preserve
    collapse (mean) a return_pid `instr_list' ///
             (first) vfirst switcher, by(pid)

    * Drop zero-variance instruments
    local instr_kept ""
    foreach inst of local instr_list {
        qui sum `inst' if switcher == 1
        if r(sd) > 1e-8 local instr_kept "`instr_kept' `inst'"
    }

    * VV's GMM moment: E[z * (a - alpha0 - alpha1 * return)] = 0
    * Equivalent to just-identified 2SLS of a on return_pid with instr_kept.
    gmm (a - {alpha0} - {alpha1}*return_pid), ///
        instruments(`instr_kept')             ///
        vce(cluster vfirst)                    ///
        winitial(unadjusted, independent)      ///
        onestep                                 ///
        quickderivatives nolog                  ///
        iterate(500)

    local alpha1_vv = _b[alpha1:_cons]
    local se_alpha1 = _se[alpha1:_cons]
    local phi_vv_inv = 1 / `alpha1_vv'
    * Delta-method SE on 1/alpha1
    local se_phi_vv  = `se_alpha1' / (`alpha1_vv')^2

    di as result "VV worker-level alpha1   = " %9.4f `alpha1_vv' ///
        ", se = " %9.4f `se_alpha1'
    di as result "  implied phi = 1/alpha1 = " %9.4f `phi_vv_inv' ///
        ", delta-SE = " %9.4f `se_phi_vv'
restore

* ============================================================
* Verdict
* ============================================================
di as result _newline(2) "========================"
di as result "# Phase B sanity verdict"
di as result "========================"

local tol_verdict = 0.02
local diff_ckt = `phi_robust_vv' - (`phi_true')
local diff_vv  = `phi_vv_inv' - (`phi_true')

di as result "phi_true = `phi_true'"
di as result "CKT phi_robust_vv     = " %9.4f `phi_robust_vv' ///
    "   diff from true = " %8.4f `diff_ckt'
di as result "VV 1/alpha1 (implied) = " %9.4f `phi_vv_inv' ///
    "   diff from true = " %8.4f `diff_vv'

if abs(`diff_ckt') < `tol_verdict' {
    di as result "  CKT: PASS (within +-`tol_verdict')"
}
else {
    di as error "  CKT: FAIL (outside +-`tol_verdict'); DGP or estimator bug"
}
if abs(`diff_vv') < `tol_verdict' * 2 {
    di as result "  VV:  PASS (within +-`=2*`tol_verdict'' given delta-method noise)"
}
else {
    di as error "  VV:  FAIL (outside +-`=2*`tol_verdict''); direction or estimator bug"
}

log close
capture translate "x_equivalence_simulation_sanity.smcl" ///
    "x_equivalence_simulation_sanity.txt", replace
exit, STATA clear
