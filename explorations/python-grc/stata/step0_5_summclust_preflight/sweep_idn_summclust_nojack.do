* ============================================================
* Title:   Step 0.5 sweep (no-jackknife): summclust IDN unb at J in {5000, 10000}.
* Author:  Emilia (with Claude)
* Date:    2026-05-05
* Purpose: Re-run the J=5000 and J=10000 cells WITHOUT the jackknife option
*          to isolate how much of the wall time is the CV3J jackknife step.
*          Pair with sweep_idn_summclust.do (with-jackknife) for a head-to-head
*          jackknife-cost comparison; informs whether to (a) keep both CV3 and
*          CV3J for production at server scale or (b) ship CV3 on full IDN
*          and validate CV3J on a subsample only.
* Input:   IDN_unb.dta, grc_IDN_urban_covs_trend.ster (for phi_hat)
* Output:  output/summclust_IDN_J{J}_nojack_<stamp>.ster
*          output/summclust_scaling_sweep_nojack_<stamp>.csv
*          output/summclust_scaling_sweep_nojack_<stamp>.log
* Notes:   Run via: stata-mp -e do sweep_idn_summclust_nojack.do
*          Identical setup to sweep_idn_summclust.do EXCEPT the summclust
*          call drops the `jackknife` option.
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

* Timestamped run id
local _d  "`c(current_date)'"
local _dd : word 1 of `_d'
local _mm : word 2 of `_d'
local _yy : word 3 of `_d'
local _t  "`c(current_time)'"
local _ts = subinstr("`_t'", ":", "", .)
local stamp = "`_yy'`_mm'`_dd'_`_ts'"

log using "summclust_scaling_sweep_nojack_`stamp'.log", replace text

local csvfile "summclust_scaling_sweep_nojack_`stamp'.csv"
file open csvfh using "`csvfile'", write replace
file write csvfh "J_target,J_actual,N_obs,n_active_z,wall_seconds,mem_used_mb_after,rc" _n
file close csvfh

capture noisily {
    local choice  urban
    local depvar  consumption
    local balance unb

    di as txt _n "============================================================"
    di as txt "No-jackknife sweep setup: IDN `balance' `depvar' `choice'"
    di as txt "============================================================"

    use "$dirdata/processed/IDN_`balance'.dta", clear
    di as txt "Loaded IDN_`balance'.dta: N=" _N
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
        estname(initial_IDN_sweep_nj)
    local base = `r(base)'
    di as txt "Base trajectory: `base'"

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
    quietly count if _n_pid == 1
    di as txt "Singleton observations dropped: " r(N)
    drop if _n_pid == 1
    drop _n_pid

    tempfile prepped
    save `prepped'

    foreach J of numlist 5000 10000 {
        di as txt _n "============================================================"
        di as txt "No-jackknife cell: J_target = `J'"
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
        di as txt "J_actual = `J_actual', N_obs = `N_obs'"

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

        di as txt _n "--- memory before summclust (no jackknife) ---"
        memory

        timer clear 1
        timer on 1
        capture noisily summclust lndepvar `zvars_active' `periodFE',  ///
            cluster(pid)                                                ///
            fevar(trajectory)                                           ///
            nograph
        local sc_rc = _rc
        timer off 1
        quietly timer list 1
        local t_wall = r(t1)
        di as txt _n "summclust no-jackknife J=`J_actual' rc=`sc_rc'  wall=`t_wall'"

        di as txt _n "--- memory after summclust (no jackknife) ---"
        memory
        local mem_mb = .

        if `sc_rc' == 0 {
            capture estimates save "summclust_IDN_J`J'_nojack_`stamp'.ster", replace
            di as txt "Saved: summclust_IDN_J`J'_nojack_`stamp'.ster"
        }

        file open csvfh using "`csvfile'", write append
        file write csvfh "`J',`J_actual',`N_obs',`n_active',`t_wall',`mem_mb',`sc_rc'" _n
        file close csvfh
    }

    di as txt _n "============================================================"
    di as txt "No-jackknife sweep complete. Artifacts in: $sweep_out"
    di as txt "  CSV: `csvfile'"
    di as txt "============================================================"
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> sweep_idn_summclust_nojack.do FAILED with rc=`saved_rc'"
}
