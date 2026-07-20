* *******************************************************************
* Title:   Stage 7 probe: switcher trajectory cell sizes and edge tests
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: For each country, list every switcher trajectory's pid
*          count and mean rural log per-capita consumption, and test
*          mu_dN against each switcher trajectory mean (pid-level,
*          robust) so the support-test design can key off adequately
*          sized cells. Diagnostic only.
* Input:   stage7_root/data/processed/<country>_bal.dta
* Output:  log only
* *******************************************************************

version 17
clear all
set more off
set varabbrev off
capture log close

global dir "C:/git/ckt/RP7/tests/stage0/stage7_root"

log using "$dir/output/logs/stage7_probe_edge_cells.smcl", replace

capture noisily {
foreach country in IDN CHN TZA {
    di as text _newline(2) "==== `country' ===="
    use "$dir/data/processed/`country'_bal.dta", clear
    quietly drop if missing(logpc_consumption) | missing(trajectory) | missing(choice)

    quietly sum trajectory
    local max_traj = r(max)
    gen log_cons_rural = logpc_consumption if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_cons_rural)
    bysort pid: gen pid_first = (_n == 1)
    quietly keep if pid_first == 1

    gen byte is_dN = (trajectory == 1)
    quietly sum ind_rural_mean if is_dN
    local mu_dN = r(mean)
    local n_dN = r(N)
    di as text "  mu_dN = " %9.4f `mu_dN' "  (N = `n_dN')"
    di as text "  traj      N     mu_d      gap       se        t         p"

    levelsof trajectory if trajectory > 1 & trajectory < `max_traj', local(sw_trajs)
    foreach k of local sw_trajs {
        quietly count if trajectory == `k'
        local n_k = r(N)
        quietly sum ind_rural_mean if trajectory == `k'
        local mu_k = r(mean)
        if `n_k' >= 2 {
            gen byte grp = (trajectory == `k') if is_dN | trajectory == `k'
            quietly regress ind_rural_mean grp if !missing(grp), vce(robust)
            local gap  = _b[grp]
            local se   = _se[grp]
            local t    = `gap' / `se'
            local p    = 2 * ttail(e(df_r), abs(`t'))
            drop grp
            di as text "  " %4.0f `k' %7.0f `n_k' %10.4f `mu_k' %9.4f `gap' %9.4f `se' %9.3f `t' %10.4f `p'
        }
        else {
            di as text "  " %4.0f `k' %7.0f `n_k' %10.4f `mu_k' "   (singleton: no test)"
        }
    }
}
}
local rc = _rc
log close
if `rc' di as error "RUN FAILED with rc = `rc'"
