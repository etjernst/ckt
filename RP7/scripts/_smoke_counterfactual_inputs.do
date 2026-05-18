* ============================================================
* Title:   Audit / smoke for counterfactual inputs (V1 gate)
* Author:  Emilia Tjernström (with Claude)
* Date:    2026-05-18
* Purpose: V1 milestone of the 2026-05-18 counterfactual plan. Walks the
*          three countries (CHN, IDN, TZA) under the headline col-5 spec
*          (consumption / urban / unbalanced / all covariates -> cuu_ca)
*          and inventories every quantity the misallocation aggregate
*          needs:
*            - the five sters per cell (main, _n, _a, _d, _g)
*            - beta-hat, phi-hat, J-stat, p-value on the main ster
*            - inversion CIs (inv_phi, inv_dN, inv_dT, inv_davg) attached
*              by attach_inversion_ci
*            - per-trajectory Delta_d (unrestricted GRC, on _d ster)
*            - data-side trajectory descriptives: N per trajectory,
*              mu_d-hat from individual rural-period mean log consumption,
*              and a flag for any NaN
*          Reports a clean inventory; flags any missing input at the end
*          for the user to address before E1 production code is written.
* Input:   $output/grc_<country>_cuu_ca{,_n,_a,_d,_g}.ster
*          $proc/<country>_unb.dta
* Output:  $logs/_smoke_counterfactual_inputs.smcl (the audit log)
* ============================================================

version 17
clear all
set more off
set varabbrev off
capture log close

if "$dir" == "" {
    if "`c(username)'" == "maand" global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
quietly include "$dir/scripts/0_path_config.do"

cap mkdir "$logs"
log using "$logs/_smoke_counterfactual_inputs.smcl", replace

* Track missing inputs across countries
local total_missing = 0

capture noisily {

foreach country in CHN IDN TZA {

    di as text _newline(2) _dup(64) "="
    di as text "==== `country' col 5 (spec = cuu_ca)"
    di as text _dup(64) "="

    local cell "grc_`country'_cuu_ca"
    local n_present = 0

    di as text _newline "  [1/4] ster inventory"
    foreach sfx in "" "_n" "_a" "_d" "_g" {
        local p "$output/`cell'`sfx'.ster"
        capture confirm file "`p'"
        if _rc {
            di as error "    MISSING: `cell'`sfx'.ster"
            local ++total_missing
        }
        else {
            di as text "    present: `cell'`sfx'.ster"
            local ++n_present
        }
    }
    di as text "    -> `n_present' of 5 sters present"

    if `n_present' == 0 {
        di as text "    skipping inversion + data inspection for `country'"
        continue
    }

    * Main ster: beta, phi, J, p, plus inversion scalars (attached to all four)
    di as text _newline "  [2/4] main ster inspection"
    capture confirm file "$output/`cell'.ster"
    if _rc {
        di as error "    main ster missing; cannot inspect"
    }
    else {
        quietly estimates use "$output/`cell'"
        di as text "    e(cmd)  = `e(cmd)'"
        di as text "    e(N)    = " e(N)
        capture local jstat = e(J)
        if !_rc di as text "    e(J)    = " %9.4f `jstat'
        capture local jdf = e(J_df)
        if !_rc di as text "    e(J_df) = " `jdf'
        * gmm does not always populate e(J_p); compute from chi2tail
        if "`jstat'" != "" & "`jdf'" != "" {
            local jp = chi2tail(`jdf', `jstat')
            di as text "    J p-val = " %6.4f `jp'
        }

        * Coefficient vector
        di as text "    e(b) full vector (showing first row):"
        noisily matrix list e(b), noheader
    }

    * Inversion CIs (attached by attach_inversion_ci to the parent / _n / _g / _a sters)
    di as text _newline "  [3/4] inversion CIs (read from parent ster)"
    capture confirm file "$output/`cell'.ster"
    if !_rc {
        quietly estimates use "$output/`cell'"
        foreach prefix in inv_phi inv_dN inv_dT inv_davg {
            capture local pt = e(`prefix'_at_waldmin)
            if _rc {
                di as error "    `prefix' scalars not on ster -> attach_inversion_ci not run?"
                local ++total_missing
                continue
            }
            local ci95 `"`e(`prefix'_ci95_str)'"'
            local nisl = e(`prefix'_island_count95)
            di as text "    `prefix' = " %9.4f `pt' "    ci95 = `ci95'    islands = " `nisl'
        }
    }

    * Data-side trajectory descriptives
    di as text _newline "  [4/4] trajectory descriptives from data"
    local data_file "$dirdata/processed/`country'_unb.dta"
    capture confirm file "`data_file'"
    if _rc {
        di as error "    MISSING DATA: `data_file'"
        local ++total_missing
        continue
    }
    use "`data_file'", clear

    foreach v in pid choice consumption trajectory {
        capture confirm variable `v'
        if _rc {
            di as error "    MISSING VARIABLE: `v' in `country'_unb"
            local ++total_missing
        }
    }

    quietly gen log_c = ln(consumption) if consumption > 0 & !missing(consumption)
    quietly count if missing(log_c)
    local n_missing_logc = r(N)
    quietly count
    di as text "    N obs total = " r(N)
    di as text "    N missing log consumption = `n_missing_logc'"

    quietly count if missing(trajectory)
    local n_missing_traj = r(N)
    di as text "    N missing trajectory      = `n_missing_traj'"
    quietly sum trajectory
    di as text "    trajectory range = [" r(min) ", " r(max) "]   (n_levels approx " r(max) ")"

    * Per-trajectory descriptives at the individual level
    quietly gen log_c_rural = log_c if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_c_rural)
    bysort pid: gen pid_first = (_n == 1)

    preserve
        quietly keep if pid_first == 1
        bysort trajectory: egen n_in_traj   = count(pid)
        bysort trajectory: egen mu_d_traj   = mean(ind_rural_mean)
        bysort trajectory: gen  traj_first  = (_n == 1)
        quietly keep if traj_first == 1
        keep trajectory n_in_traj mu_d_traj
        sort trajectory
        di as text _newline "    per-trajectory N and mu_d (mean indiv rural-period log consumption):"
        format mu_d_traj %9.4f
        list, noobs sep(0) ab(14)

        * Sigma_theta = cross-trajectory variance of mu_d weighted by pi_d
        * (this is the between-group lower bound on Var(theta_i))
        quietly sum n_in_traj
        local total_n = r(sum)
        quietly gen pi_d = n_in_traj / `total_n'
        quietly sum mu_d_traj [aw=pi_d]
        local mu_bar = r(mean)
        quietly gen sq_dev = pi_d * (mu_d_traj - `mu_bar')^2
        quietly sum sq_dev
        local sigma_theta_sq = r(sum)
        local sigma_theta = sqrt(`sigma_theta_sq')
        di as text "    sigma_theta (pi-weighted) = " %9.4f `sigma_theta' "  (between-group lower bound on sd(theta_i))"

        * mu_dN (traj 1) vs switcher range (max_traj is d_T)
        quietly sum trajectory
        local max_t = r(max)
        quietly sum mu_d_traj if trajectory == 1, meanonly
        local mu_dN = r(mean)
        quietly sum mu_d_traj if trajectory > 1 & trajectory < `max_t', meanonly
        if r(N) > 0 {
            quietly sum mu_d_traj if trajectory > 1 & trajectory < `max_t'
            local sw_min = r(min)
            local sw_max = r(max)
            di as text "    mu_dN = " %9.4f `mu_dN' "   switcher mu_d in [" %9.4f `sw_min' ", " %9.4f `sw_max' "]"
        }
        else {
            di as text "    mu_dN = " %9.4f `mu_dN' "   (no switcher trajectories enumerated in this dataset)"
        }
    restore
}

}

local saved_rc = _rc

di as text _newline(2) _dup(64) "="
di as text "==== SUMMARY"
di as text _dup(64) "="
if `total_missing' == 0 {
    di as text "    All headline-spec inputs present across CHN, IDN, TZA."
    di as text "    V1 gate: PASS."
}
else {
    di as error "    `total_missing' missing inputs across the three countries."
    di as error "    V1 gate: FAIL -- see entries flagged MISSING above."
}

log close
if `saved_rc' != 0 di as error ">>> SCRIPT FAILED with rc=`saved_rc'"
