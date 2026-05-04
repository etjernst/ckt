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
log using probe_idn_setup_run.log, replace text

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

        di as txt _n "--- summclust syntax probe ---"
        timer clear 1
        timer on 1
        capture noisily summclust lndepvar `zvars' `periodFE',  ///
            cluster(pid)                                        ///
            absorb(trajectory)                                  ///
            jackknife
        local sc_rc = _rc
        timer off 1
        timer list 1
        di as txt _n "summclust rc = `sc_rc'"
        if `sc_rc' != 0 {
            di as err "summclust failed; inspect log for syntax issues"
            di as txt "Trying without absorb()..."
            timer clear 2
            timer on 2
            capture noisily summclust lndepvar `zvars' `periodFE' i.trajectory,   ///
                cluster(pid)                                                     ///
                jackknife
            local sc_rc2 = _rc
            timer off 2
            timer list 2
            di as txt "summclust (no-absorb) rc = `sc_rc2'"
        }
    restore

    di as txt _n "=== Probe complete ==="
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> probe_idn_setup.do FAILED with rc=`saved_rc'"
}
exit, STATA clear
