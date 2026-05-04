* ============================================================
* Title:   Step 0.5 probe: IDN unb consumption setup + phi_hat extraction.
* Author:  Emilia (with Claude)
* Date:    2026-05-04
* Purpose: Before the full summclust scaling sweep, verify:
*          (a) IDN_unb.dta loads and setup_grc_estimation runs;
*          (b) the saved grc_IDN_urban_covs_trend.ster is readable
*              and exposes a $\phi$ parameter we can extract;
*          (c) summclust accepts the recoded-design syntax we plan
*              on a tiny J subsample (J=500) before scaling up.
* Output:  probe_idn_setup_run.log
* Note:    Variable names corrected from rev 5 plan
*          (rev 5 says beta_s_/alpha_d_; actual code uses
*           switcher_s_choice/switcher_s).
* ============================================================

clear all
set more off
set varabbrev off
* Suppress graphics --- summclust draws an internal leverage plot
* (summclust_temp_pb.gph) which on Windows batch mode triggers a
* "Stata finished"-style popup that exit, STATA clear does not suppress.
set graphics off

* Path setup mirroring 0_master.do for user maand
if "`c(username)'" == "maand" {
    global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
include "$dir/scripts/0_path_config.do"

quietly {
    include "$dir/scripts/0_programs.do"
}

cd "$logs"
capture log close

* Timestamped log name so successive probe runs do not overwrite each other.
* c(current_date) is "DD MMM YYYY"; reformat to YYYYMMDD; c(current_time) is "HH:MM:SS".
local _d  "`c(current_date)'"
local _dd : word 1 of `_d'
local _mm : word 2 of `_d'
local _yy : word 3 of `_d'
local _t  "`c(current_time)'"
local _ts = subinstr("`_t'", ":", "", .)
local _stamp = "`_yy'`_mm'`_dd'_`_ts'"
log using "probe_idn_setup_run_`_stamp'.log", replace text

capture noisily {
    di as txt _n "=== Step 0.5 probe: IDN consumption recoded-design setup ==="

    local choice  urban
    local depvar  consumption
    local balance unb

    use "$dirdata/processed/IDN_`balance'.dta", clear
    di as txt "IDN_`balance'.dta loaded: N=" _N

    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    di as txt "switchers global = $switchers"
    di as txt "always trajectory = $always"

    di as txt _n "--- pid cluster moments (full sample) ---"
    quietly bys pid: gen _n_pid = _N
    sum _n_pid, detail
    quietly bys pid: gen _first_pid = (_n == 1)
    quietly count if _first_pid
    di as txt "Total unique pids (full IDN unb): " r(N)
    drop _n_pid _first_pid

    di as txt _n "--- Extract phi_hat from grc_IDN_urban_covs_trend.ster ---"
    capture estimates use "$output/staging/grc_IDN_urban_covs_trend.ster"
    if _rc {
        di as err "ster file not found at $output/staging/grc_IDN_urban_covs_trend.ster"
        exit 198
    }
    di as txt "Loaded ster. Parameter names in e(b):"
    matrix list e(b), noheader
    estimates dir
    di as txt _n "Coefficient names from colnames(e(b)):"
    local cnames : colnames e(b)
    di as txt "`cnames'"

    * Try common phi parameter names
    capture scalar phi_hat = _b[phi:_cons]
    if _rc {
        capture scalar phi_hat = _b[/phi]
        if _rc {
            capture scalar phi_hat = _b[phi]
            if _rc {
                di as err "Could not locate phi parameter under common names"
                di as txt "Inspect colnames above and update the probe"
                exit 198
            }
        }
    }
    di as txt _n "phi_hat = " %12.8f scalar(phi_hat)

    * Reload working data
    use "$dirdata/processed/IDN_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation

    * Re-run initial_values to get the data-driven base trajectory
    quietly initial_values lndepvar,                         ///
        switchers($switchers) balance(`balance')             ///
        estname(initial_IDN_probe)
    local base = `r(base)'
    di as txt _n "Data-driven base trajectory for IDN consumption: `base'"
    di as txt "(rev 5 plan claimed base=2 a priori; verify against this value)"

    * Construct period FE
    quietly tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * Construct recoded z's at phi_0 = phi_hat for s in switchers \ {base}
    local zvars
    foreach s of numlist $switchers {
        if `s' != `base' {
            quietly gen z_`s' = switcher_`s'_choice - scalar(phi_hat) * switcher_`s'
            local zvars `zvars' z_`s'
        }
    }
    local n_z : word count `zvars'
    di as txt _n "Built `n_z' recoded z's: `zvars'"

    * Drop singletons
    quietly bys pid: gen _n_pid = _N
    quietly count if _n_pid == 1
    di as txt "Singleton observations (n_pid == 1): " r(N)
    drop if _n_pid == 1
    drop _n_pid

    * Subsample J = 500 unique pids for the syntax probe
    preserve
        quietly bys pid: gen _f = (_n == 1)
        quietly egen _pid_id = group(pid) if _f
        sort _pid_id
        quietly count if _f
        local J_total = r(N)
        di as txt "Unique pids after singleton drop: `J_total'"
        local J_target 500
        set seed 20260504
        quietly gen _u = runiform() if _f
        quietly egen _r = rank(_u) if _f
        quietly bys pid (_f): replace _r = _r[_N]
        quietly keep if _r <= `J_target'
        quietly count
        di as txt "Probe subsample: N=" r(N)
        quietly bys pid: gen _g = _n == 1
        quietly count if _g
        di as txt "Probe subsample unique pids: " r(N)

        * Diagnose which switcher trajectories actually appear in this subsample
        * and drop z_s columns whose underlying switcher_s_choice is uniformly zero
        * --- those columns trip "subscript invalid" deep inside summclust.
        di as txt _n "--- subsample trajectory composition ---"
        quietly levelsof trajectory, local(traj_in_sample)
        di as txt "Trajectories present in J=500 subsample: `traj_in_sample'"
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
        di as txt "Active z's (positive variance in subsample): `n_active' of `n_z'"
        di as txt "`zvars_active'"

        di as txt _n "--- summclust syntax probe: fevar(trajectory) ---"
        di as txt "(absorb(trajectory) errored rc=198 in the prior run because"
        di as txt " pid varies within trajectory; fevar() handles arbitrary FE.)"
        timer clear 1
        timer on 1
        capture noisily summclust lndepvar `zvars_active' `periodFE',  ///
            cluster(pid)                                                ///
            fevar(trajectory)                                           ///
            jackknife                                                   ///
            nograph
        local sc_rc_fevar = _rc
        timer off 1
        timer list 1
        di as txt _n "summclust fevar(trajectory) rc = `sc_rc_fevar'"

        di as txt _n "--- summclust syntax probe: manual trajectory dummies ---"
        quietly tab trajectory, gen(trajdum_)
        * Drop the base dummy to avoid the dummy trap; base is `base'.
        capture drop trajdum_`base'
        unab trajdums : trajdum_*
        di as txt "Manual trajectory dummies (base trajdum_`base' dropped): `trajdums'"
        timer clear 2
        timer on 2
        capture noisily summclust lndepvar `zvars_active' `trajdums' `periodFE',   ///
            cluster(pid)                                                            ///
            jackknife                                                               ///
            nograph
        local sc_rc_manual = _rc
        timer off 2
        timer list 2
        di as txt _n "summclust manual-dummies rc = `sc_rc_manual'"

        di as txt _n "--- syntax probe summary ---"
        di as txt "fevar(trajectory): rc=`sc_rc_fevar'"
        di as txt "manual trajdum_*:  rc=`sc_rc_manual'"
        di as txt "(both rc=0 means either syntax works; pick whichever is faster"
        di as txt " or scales cleaner in the J in {5000,10000,20000} sweep.)"
    restore

    di as txt _n "=== Probe complete ==="
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> probe_idn_setup.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
