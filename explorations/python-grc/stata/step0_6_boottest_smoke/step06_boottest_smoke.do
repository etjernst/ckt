* ============================================================
* Title:   Step 0.6 smoke test: boottest one-pass inversion feasibility
* Author:  Emilia (with Claude)
* Date:    2026-05-07
* Purpose: Verify whether boottest can invert the joint q-dim LCA null
*          over scalar phi in a single bootstrap pass at TZA J=1500.
*          Per rev 5 of the backend-choice plan, this decides whether
*          path D resolves to D-onepass (cheap) or D-grid (~30x cost).
*
* Spec from rev 5 plan:
*   - TZA covs_trend recoded design at J=1500
*   - phi_0 = phi_hat from the GRC fit (TZA covs_trend staging ster)
*   - Recoded z_s = switcher_s_choice - phi_0 * switcher_s for s != base
*   - Drop singleton clusters
*   - Absorb trajectory FE; cluster on pid
*   - boottest weighttype(rademacher) reps(B) for WCU31
*   - B=999 for the smoke; B=9999 reserved for production
*
* Smoke goals:
*   1. Time the auxiliary OLS fit (areg).
*   2. Time the analytic joint Wald (built-in test).
*   3. Time boottest joint p-value at phi_hat (single-pass cost).
*   4. Attempt boottest with gridpoints(0) for one-pass CI inversion;
*      record whether it errors out or returns a CI.
*   5. Extrapolate D-grid wall at production B (9999) and 30 grid points.
*
* Input:   TZA_unb.dta, grc_TZA_urban_covs_trend.ster (staging)
* Output:  output/step06_boottest_smoke_<stamp>.log
* Notes:   Run via: stata-mp -e do step06_boottest_smoke.do
* ============================================================

clear all
set more off
set varabbrev off

if "`c(username)'" == "maand" {
    global dir        "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
    global step06_out "C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_6_boottest_smoke/output"
}

include "$dir/scripts/0_path_config.do"
quietly {
    include "$dir/scripts/0_programs.do"
}

cd "$step06_out"
capture log close

local _d  "`c(current_date)'"
local _dd : word 1 of `_d'
local _mm : word 2 of `_d'
local _yy : word 3 of `_d'
local _t  "`c(current_time)'"
local _ts = subinstr("`_t'", ":", "", .)
local stamp = "`_yy'`_mm'`_dd'_`_ts'"

log using "step06_boottest_smoke_`stamp'.log", replace text

local J     1500
local Bdev  999

capture noisily {

    * --- 1. Recover phi_hat from the TZA covs_trend GRC fit
    use "$dirdata/processed/TZA_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    capture estimates use "$output/staging/grc_TZA_urban_covs_trend.ster"
    if _rc {
        di as err "TZA covs_trend ster not found at $output/staging/"
        di as err "Cannot recover phi_hat without it. Aborting."
        exit 198
    }
    scalar phi_hat = _b[/phi]
    di as txt _n "phi_hat (TZA covs_trend) = " %12.8f scalar(phi_hat)

    * --- 2. Reload data, build recoded design at phi_0 = phi_hat
    use "$dirdata/processed/TZA_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    quietly initial_values lndepvar, switchers($switchers) balance(unb) ///
        estname(initial_TZA_step06)
    local base = `r(base)'
    di as txt "base trajectory = `base'"

    quietly tab period, gen(period_)
    local n_periods = r(r)
    local periodFE
    forvalues p = 2/`n_periods' {
        local periodFE `periodFE' period_`p'
    }

    local z_list
    foreach s of numlist $switchers {
        if `s' != `base' {
            quietly gen z_`s' = switcher_`s'_choice - scalar(phi_hat) * switcher_`s'
            local z_list `z_list' z_`s'
        }
    }

    * --- 3. Drop singleton clusters
    quietly bys pid: gen _n_pid = _N
    quietly count if _n_pid == 1
    local n_singletons = r(N)
    quietly count
    local n_pre = r(N)
    drop if _n_pid == 1
    drop _n_pid
    di as txt "Dropped singletons: `n_singletons' obs of `n_pre'"

    * --- 4. Subsample to J=`J' unique pids
    preserve
        keep pid
        duplicates drop
        quietly count
        local J_avail = r(N)
    restore
    di as txt "J available pre-subsample: `J_avail'"

    if `J_avail' > `J' {
        preserve
            keep pid
            duplicates drop
            set seed 20260507
            quietly gen _u = runiform()
            sort _u
            quietly keep if _n <= `J'
            tempfile keep_pids
            save `keep_pids'
        restore
        quietly merge m:1 pid using `keep_pids', keep(match) nogen
    }

    quietly count
    local N_obs = r(N)
    preserve
        keep pid
        duplicates drop
        quietly count
        local J_actual = r(N)
    restore
    di as txt "Post-subsample: J_actual=`J_actual', N=`N_obs'"

    * --- 5. Active z's (drop any with zero variance after subsampling)
    local active_z
    foreach z of varlist z_* {
        quietly summ `z'
        if r(sd) > 0 {
            local active_z `active_z' `z'
        }
    }
    local q_active : word count `active_z'
    di as txt "active z's (q): `q_active'"

    * --- 6. Fit auxiliary OLS at phi_hat with absorbed trajectory FE
    di as txt _n "{hline 72}"
    di as txt "Fitting auxiliary OLS (areg, absorb trajectory, cluster pid)"
    di as txt "{hline 72}"
    timer clear 1
    timer on 1
    areg lndepvar `active_z' `periodFE', absorb(trajectory) vce(cluster pid)
    timer off 1
    quietly timer list 1
    local t_areg = r(t1)
    di as txt _n "areg wall: " %7.3f `t_areg' " s"

    * --- 7. Analytic joint Wald (built-in test) at phi_hat
    di as txt _n "{hline 72}"
    di as txt "Analytic joint Wald (built-in test)"
    di as txt "{hline 72}"
    timer clear 2
    timer on 2
    test `active_z'
    timer off 2
    quietly timer list 2
    local t_jointwald = r(t1)
    scalar wald_F = r(F)
    scalar wald_p = r(p)
    di as txt _n "Joint Wald F = " %12.6f scalar(wald_F) ///
                ", p = " %12.8f scalar(wald_p)
    di as txt "Joint Wald wall: " %7.4f `t_jointwald' " s"

    * --- 8. boottest joint p-value at phi_hat (single-pass cost)
    di as txt _n "{hline 72}"
    di as txt "boottest joint p-value at phi_hat (B=`Bdev', WCU31 / rademacher)"
    di as txt "{hline 72}"
    timer clear 3
    timer on 3
    capture noisily boottest (`active_z'),               ///
        weighttype(rademacher) reps(`Bdev') nograph
    local rc_btp = _rc
    timer off 3
    quietly timer list 3
    local t_bt_p = r(t1)
    if `rc_btp' == 0 {
        di as txt _n "boottest joint p wall: " %7.3f `t_bt_p' " s   (rc=0)"
    }
    else {
        di as err _n "boottest joint p FAILED with rc=`rc_btp' (wall " %7.3f `t_bt_p' " s)"
    }

    * --- 9. Try one-pass CI inversion via gridpoints(0)
    *     Per rev 5: boottest's CI inversion is documented as scalar-only.
    *     Expectation is this errors. If it returns a CI, manually inspect
    *     whether the CI is for the joint null (good) or per-coefficient
    *     scalar inversion masquerading as joint (silent failure mode).
    di as txt _n "{hline 72}"
    di as txt "One-pass inversion attempt: boottest joint null with gridpoints(0)"
    di as txt "{hline 72}"
    timer clear 4
    timer on 4
    capture noisily boottest (`active_z'),               ///
        weighttype(rademacher) reps(`Bdev') nograph     ///
        gridpoints(0)
    local rc_onepass = _rc
    timer off 4
    quietly timer list 4
    local t_bt_onepass = r(t1)
    if `rc_onepass' == 0 {
        di as txt _n "ONE-PASS RETURNED: rc=0 in " %7.3f `t_bt_onepass' " s"
        di as txt "  --> Manually inspect log to check whether the CI inverts"
        di as txt "      the joint q-dim null vs treats as per-coef scalar inversion."
    }
    else {
        di as err _n "One-pass inversion FAILED: rc=`rc_onepass'"
        di as err "  --> Path D resolves to D-grid per rev 5 fallback."
    }

    * --- 10. Extrapolate D-grid wall at production B (9999) and grid=30
    di as txt _n _n "{hline 72}"
    di as txt "Step 0.6 smoke summary"
    di as txt "{hline 72}"
    di as txt "TZA covs_trend recoded design"
    di as txt "  J_actual:           `J_actual'"
    di as txt "  N_obs:              `N_obs'"
    di as txt "  q (active z's):     `q_active'"
    di as txt "  base trajectory:    `base'"
    di as txt "  phi_hat:            " %12.8f scalar(phi_hat)
    di as txt ""
    di as txt "Wall times:"
    di as txt "  areg fit:                    " %7.3f `t_areg'      " s"
    di as txt "  analytic joint Wald:         " %7.4f `t_jointwald' " s"
    di as txt "  boottest joint p (B=`Bdev'): " %7.3f `t_bt_p'      " s   rc=`rc_btp'"
    di as txt "  boottest one-pass(B=`Bdev'): " %7.3f `t_bt_onepass'" s   rc=`rc_onepass'"

    di as txt ""
    di as txt "D-grid extrapolation (single-fit cost x 30 grid x B_prod/B_dev):"
    local Bprod = 9999
    local grid_pts = 30
    if `rc_btp' == 0 {
        local single_pass = `t_areg' + `t_bt_p'
        local dgrid_wall_tza = `single_pass' * `grid_pts' * (`Bprod' / `Bdev')
        di as txt "  per-grid (areg + boottest): " %7.3f `single_pass' " s"
        di as txt "  D-grid TZA J=`J' total:     " %9.1f `dgrid_wall_tza' " s"
        di as txt "                           = " %7.2f (`dgrid_wall_tza'/3600) " h"
        di as txt "  D-grid TZA scaled to IDN unb (J=29715, naive J^2): "
        local idn_factor = (29715/1500)^2
        local dgrid_wall_idn = `dgrid_wall_tza' * `idn_factor'
        di as txt "      ~" %9.1f `dgrid_wall_idn' " s = " %7.2f (`dgrid_wall_idn'/3600) " h"
        di as txt "  (J^2 is conservative; actual scaling may be J*log(J) for"
        di as txt "   areg + linear in J for the bootstrap matrix multiply.)"
    }

    di as txt ""
    di as txt "Decision input:"
    if `rc_onepass' == 0 {
        di as txt "  one-pass DID return; inspect CI manually before promoting D-onepass."
    }
    else {
        di as txt "  one-pass DID NOT return; D resolves to D-grid (per rev 5)."
        di as txt "  D-grid wall above estimates production cost."
    }
    di as txt "{hline 72}"
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> Step 0.6 smoke FAILED with rc=`saved_rc'"
}
exit, STATA clear
