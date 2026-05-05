* ============================================================
* Title:   Step 0.5 sweep: summclust IDN unb scaling at J in {5000, 10000, 20000}.
* Author:  Emilia (with Claude)
* Date:    2026-05-04
* Purpose: Time and memory-profile summclust at three IDN-scale subsamples
*          so we can extrapolate to J = 29,715 (post-singleton-drop) before
*          committing to the full IDN run. Per rev 5 Step 0.5 decision rule:
*          if extrapolation predicts > 30 min wall or > 8 GB peak at full J,
*          kick off the from-scratch CR3 prototype in parallel.
* Input:   IDN_unb.dta, grc_IDN_urban_covs_trend.ster (for phi_hat)
* Output:  output/summclust_IDN_J{J}_<stamp>.ster        (per-cell estimates)
*          output/summclust_scaling_sweep_<stamp>.csv    (timing + memory)
*          output/summclust_scaling_sweep_<stamp>.log    (full log)
* Notes:   Run via:  stata-mp -e do sweep_idn_summclust.do
*          NOT  stata-mp -b  --- the -b flag fires the Windows completion
*          popup that -e suppresses (see ~/.claude/rules/stata-conventions.md).
*          summclust uses fevar(trajectory) and the active-z filter validated
*          in probe_idn_setup.do at J=500.
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

* Timestamped run id (YYYYMMMDD_HHMMSS so files sort uniquely per run)
local _d  "`c(current_date)'"
local _dd : word 1 of `_d'
local _mm : word 2 of `_d'
local _yy : word 3 of `_d'
local _t  "`c(current_time)'"
local _ts = subinstr("`_t'", ":", "", .)
local stamp = "`_yy'`_mm'`_dd'_`_ts'"

log using "summclust_scaling_sweep_`stamp'.log", replace text

* CSV header for the timing artifact
local csvfile "summclust_scaling_sweep_`stamp'.csv"
file open csvfh using "`csvfile'", write replace
file write csvfh "J_target,J_actual,N_obs,n_active_z,wall_seconds,mem_used_mb_after,rc" _n
file close csvfh

capture noisily {
    local choice  urban
    local depvar  consumption
    local balance unb

    di as txt _n "============================================================"
    di as txt "Sweep setup: IDN `balance' `depvar' `choice'"
    di as txt "============================================================"

    use "$dirdata/processed/IDN_`balance'.dta", clear
    di as txt "Loaded IDN_`balance'.dta: N=" _N
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    * Extract phi_hat from the saved point-estimate ster
    capture estimates use "$output/staging/grc_IDN_urban_covs_trend.ster"
    if _rc {
        di as err "ster not found at $output/staging/grc_IDN_urban_covs_trend.ster"
        exit 198
    }
    scalar phi_hat = _b[/phi]
    di as txt "phi_hat = " %12.8f scalar(phi_hat)

    * Reload working data and rebuild the design
    use "$dirdata/processed/IDN_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    * Data-driven base trajectory
    quietly initial_values lndepvar,                         ///
        switchers($switchers) balance(`balance')             ///
        estname(initial_IDN_sweep)
    local base = `r(base)'
    di as txt "Base trajectory: `base'"

    * Period FE
    quietly tab period, gen(period_)
    local n_periods = r(r)
    local periodFE
    forvalues p = 2/`n_periods' {
        local periodFE `periodFE' period_`p'
    }
    di as txt "Period FE columns: `periodFE'"

    * Build full set of recoded z's at phi_0 = phi_hat
    foreach s of numlist $switchers {
        if `s' != `base' {
            quietly gen z_`s' = switcher_`s'_choice - scalar(phi_hat) * switcher_`s'
        }
    }

    * Drop singletons
    quietly bys pid: gen _n_pid = _N
    quietly count if _n_pid == 1
    di as txt "Singleton observations dropped: " r(N)
    drop if _n_pid == 1
    drop _n_pid

    quietly bys pid: gen _f = (_n == 1)
    quietly count if _f
    local J_total = r(N)
    di as txt "Unique pids after singleton drop (J_total): `J_total'"
    drop _f

    * Save the prepared dataset to a tempfile so each sweep cell starts fresh
    tempfile prepped
    save `prepped'

    foreach J of numlist 5000 10000 20000 {
        di as txt _n "============================================================"
        di as txt "Sweep cell: J_target = `J'"
        di as txt "============================================================"

        use `prepped', clear

        * Sample J unique pids
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
        di as txt "J_actual = `J_actual', N_obs = `N_obs'"

        * Active-z filter (rare trajectories may still be missing at J=5000)
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
        di as txt "Active z's at J=`J_actual': `n_active'"

        * Memory snapshot before
        di as txt _n "--- memory before summclust ---"
        memory

        * Time the fit
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
        di as txt _n "summclust J=`J_actual' rc=`sc_rc'  wall=`t_wall'"

        * Memory snapshot after
        di as txt _n "--- memory after summclust ---"
        memory
        * Approximate "memory used" via Stata's data_u allocation.
        * c(memory) is the data-only allocation in MB; sum_g and others are
        * in c(); the closest single-number summary is data_u + sysmiss_u, but
        * in batch mode `memory` displays the full table, which the log captures.
        * For peak RSS, capture via Task Manager / Get-Process externally.
        local mem_mb = .

        * Save .ster per cell (only if the fit succeeded)
        if `sc_rc' == 0 {
            capture estimates save "summclust_IDN_J`J'_`stamp'.ster", replace
            di as txt "Saved: summclust_IDN_J`J'_`stamp'.ster"
        }

        * Append CSV row
        file open csvfh using "`csvfile'", write append
        file write csvfh "`J',`J_actual',`N_obs',`n_active',`t_wall',`mem_mb',`sc_rc'" _n
        file close csvfh
    }

    di as txt _n "============================================================"
    di as txt "Sweep complete. Artifacts in: $sweep_out"
    di as txt "  CSV: `csvfile'"
    di as txt "  Per-cell sters: summclust_IDN_J{5000,10000,20000}_`stamp'.ster"
    di as txt "============================================================"
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> sweep_idn_summclust.do FAILED with rc=`saved_rc'"
}
