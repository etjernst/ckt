* ============================================================
* Title:   Step 0.5 stability test: 5x summclust at J=5000 IDN unb (with-jackknife).
* Author:  Emilia (with Claude)
* Date:    2026-05-05
* Purpose: Quantify wall-time noise at the J=5000 baseline. Five identical
*          summclust runs at J=5000 with the production spec (jackknife
*          included), all with the same seed and same active-z filter.
*          A coefficient of variation > 10% across runs means the
*          J=5000 vs J=10000 wall comparisons are noise-dominated and we
*          need a clean-room re-run.
* Input:   IDN_unb.dta, grc_IDN_urban_covs_trend.ster (for phi_hat)
* Output:  output/stability_J5000_<stamp>.csv  (one row per replicate)
*          output/stability_J5000_<stamp>.log
* Notes:   Run via:  stata-mp -e do stability_test_J5000.do
*          Identical setup to sweep_idn_summclust.do, just looped 5x at
*          J=5000 instead of stepping J. Same seed each replicate so the
*          subsample and active-z set are identical run-to-run; the only
*          variation is wall-time noise from system load, OS scheduler,
*          and Stata's internal nondeterminism (none expected).
* ============================================================

clear all
set more off
set varabbrev off

if "`c(username)'" == "maand" {
    global dir       "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
    global sweep_out "C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output"
}

include "$dir/scripts/0_path_config.do"
quietly {
    include "$dir/scripts/0_programs.do"
}

cd "$sweep_out"
capture log close

local _d  "`c(current_date)'"
local _dd : word 1 of `_d'
local _mm : word 2 of `_d'
local _yy : word 3 of `_d'
local _t  "`c(current_time)'"
local _ts = subinstr("`_t'", ":", "", .)
local stamp = "`_yy'`_mm'`_dd'_`_ts'"

log using "stability_J5000_`stamp'.log", replace text

local csvfile "stability_J5000_`stamp'.csv"
file open csvfh using "`csvfile'", write replace
file write csvfh "rep,J_target,J_actual,N_obs,n_active_z,wall_seconds,rc" _n
file close csvfh

capture noisily {
    local choice  urban
    local depvar  consumption
    local balance unb
    local J 5000

    di as txt _n "============================================================"
    di as txt "Stability test setup: 5x J=`J' IDN `balance' with jackknife"
    di as txt "============================================================"

    use "$dirdata/processed/IDN_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    capture estimates use "$output/staging/grc_IDN_urban_covs_trend.ster"
    if _rc {
        di as err "ster not found at $output/staging/grc_IDN_urban_covs_trend.ster"
        exit 198
    }
    scalar phi_hat = _b[/phi]
    di as txt "phi_hat = " %12.8f scalar(phi_hat)

    use "$dirdata/processed/IDN_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    quietly initial_values lndepvar,                         ///
        switchers($switchers) balance(`balance')             ///
        estname(initial_IDN_stab)
    local base = `r(base)'

    quietly tab period, gen(period_)
    local n_periods = r(r)
    local periodFE
    forvalues p = 2/`n_periods' {
        local periodFE `periodFE' period_`p'
    }

    foreach s of numlist $switchers {
        if `s' != `base' {
            quietly gen z_`s' = switcher_`s'_choice - scalar(phi_hat) * switcher_`s'
        }
    }

    quietly bys pid: gen _n_pid = _N
    drop if _n_pid == 1
    drop _n_pid

    tempfile prepped
    save `prepped'

    forvalues rep = 1/5 {
        di as txt _n "============================================================"
        di as txt "Replicate `rep' of 5"
        di as txt "============================================================"

        use `prepped', clear

        preserve
            keep pid
            duplicates drop
            set seed 20260504
            quietly gen _u = runiform()
            sort _u
            quietly keep if _n <= `J'
            tempfile keep_pids
            save `keep_pids'
        restore
        quietly merge m:1 pid using `keep_pids', keep(match) nogen
        quietly bys pid: gen _f = (_n == 1)
        quietly count if _f
        local J_actual = r(N)
        drop _f
        quietly count
        local N_obs = r(N)

        local zvars_active
        foreach s of numlist $switchers {
            if `s' != `base' {
                quietly sum switcher_`s'_choice
                if r(sd) > 0 & r(sd) < . {
                    local zvars_active `zvars_active' z_`s'
                }
            }
        }
        local n_active : word count `zvars_active'
        di as txt "Replicate `rep': J_actual=`J_actual', N_obs=`N_obs', active z=`n_active'"

        timer clear 1
        timer on 1
        capture noisily summclust lndepvar `zvars_active' `periodFE',  ///
            cluster(pid)                                                ///
            fevar(trajectory)                                           ///
            jackknife                                                   ///
            nograph
        local sc_rc = _rc
        timer off 1
        quietly timer list 1
        local t_wall = r(t1)
        di as txt _n "Replicate `rep' rc=`sc_rc'  wall=`t_wall'"

        file open csvfh using "`csvfile'", write append
        file write csvfh "`rep',`J',`J_actual',`N_obs',`n_active',`t_wall',`sc_rc'" _n
        file close csvfh
    }

    di as txt _n "============================================================"
    di as txt "Stability test complete. CSV: `csvfile'"
    di as txt "============================================================"
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> stability_test_J5000.do FAILED with rc=`saved_rc'"
}
