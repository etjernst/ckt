* ============================================================
* Title:   Export E1 inputs to CSV for the V2 back-of-envelope check
* Author:  Emilia Tjernström (with Claude)
* Date:    2026-05-18
* Purpose: Drives the V2 milestone of the counterfactual plan. For each
*          country that has cuu_ca sters, writes two CSVs:
*            <country>_e1_traj.csv    rows by trajectory: n_pids, pi_d,
*                                    dbar_d, mu_d, delta_d (unrestricted
*                                    from _d ster)
*            <country>_e1_scalars.csv country-level scalars: phi_hat,
*                                    beta_hat, delta_dN, delta_dT (from
*                                    inversion), mu_dN, n_total
* Input:   $output/grc_<c>_cuu_ca{,_d}.ster, $dirdata/processed/<c>_unb.dta
* Output:  $output/counterfactual_inputs/<c>_e1_{traj,scalars}.csv
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

cap mkdir "$output/counterfactual_inputs"
local outdir "$output/counterfactual_inputs"

log using "$logs/_export_e1_inputs.smcl", replace

capture noisily {

foreach country in IDN TZA {

    di as text _newline(2) "==== `country' ===="

    * --- 1. Read parent ster: phi_hat, mu_base, inversion scalars ---
    local pster "$output/grc_`country'_cuu_ca.ster"
    capture confirm file "`pster'"
    if _rc {
        di as error "  parent ster missing -- skipping `country'"
        continue
    }
    quietly estimates use "`pster'"
    matrix b = e(b)
    scalar phi_hat = b[1, colnumb(b, "phi:_cons")]
    scalar beta_hat = b[1, colnumb(b, "Delta_base:_cons")]
    scalar kappa_hat = b[1, colnumb(b, "kappa:_cons")]
    scalar unb_choice_hat = b[1, colnumb(b, "xb:unbalanced_choice")]
    local jstat = e(J)
    local jdf   = e(J_df)
    local jp    = chi2tail(`jdf', `jstat')
    scalar n_total = e(N)

    * Inversion CIs at point estimate (e(inv_*_at_waldmin))
    scalar inv_phi  = e(inv_phi_at_waldmin)
    scalar inv_dN   = e(inv_dN_at_waldmin)
    scalar inv_dT   = e(inv_dT_at_waldmin)
    scalar inv_davg = e(inv_davg_at_waldmin)

    di as text "  phi_hat   = " phi_hat
    di as text "  beta_hat  = " beta_hat
    di as text "  inv_dN    = " inv_dN
    di as text "  inv_dT    = " inv_dT
    di as text "  J = " %6.3f `jstat' "   df = `jdf'   p = " %5.3f `jp'

    * --- 2. Read _d ster for per-trajectory unrestricted Delta_d ---
    local dster "$output/grc_`country'_cuu_ca_d.ster"
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    di as text "  _d ster parameters: `d_names'"

    * --- 3. From parent ster b matrix: extract mu:never and mu:switcher_K ---
    quietly estimates use "`pster'"
    matrix b = e(b)
    local b_names : colnames b
    * Find all "mu:switcher_<k>" columns
    local sw_traj_codes ""
    local sw_mus ""
    foreach name of local b_names {
        if strpos("`name'", "mu:switcher_") == 1 {
            local k = substr("`name'", length("mu:switcher_") + 1, .)
            local sw_traj_codes "`sw_traj_codes' `k'"
            local mu_k = b[1, colnumb(b, "`name'")]
            local sw_mus "`sw_mus' `mu_k'"
        }
    }
    local mu_never = b[1, colnumb(b, "mu:never")]
    di as text "  switcher trajectory codes from parent ster: `sw_traj_codes'"
    di as text "  mu_never (raw) = `mu_never'"

    * --- 4. Load data: compute pi_d, dbar_d, n_pids per trajectory ---
    use "$dirdata/processed/`country'_unb.dta", clear
    quietly drop if missing(consumption) | missing(choice)

    * Per-individual urban share and trajectory
    bysort pid: gen pid_first = (_n == 1)
    bysort pid: egen dbar_indiv = mean(choice)

    * For unbalanced spec: trajectory is missing for unbalanced individuals.
    * We treat those as a single "lumped switcher" cell coded -1 so it stays
    * distinct from the integer trajectory codes.
    quietly replace pid_first = 0 if missing(trajectory) & missing(unbalanced)
    quietly gen traj_for_agg = trajectory
    quietly replace traj_for_agg = -1 if missing(trajectory) & unbalanced == 1

    preserve
        quietly keep if pid_first == 1
        bysort traj_for_agg: egen n_pids = count(pid)
        bysort traj_for_agg: egen pi_helper = total(1)
        bysort traj_for_agg: egen dbar_d   = mean(dbar_indiv)
        bysort traj_for_agg: gen  traj_first = (_n == 1)
        quietly keep if traj_first == 1
        keep traj_for_agg n_pids dbar_d
        quietly count
        local n_traj = r(N)
        quietly sum n_pids
        local n_total_pids = r(sum)
        quietly gen pi_d = n_pids / `n_total_pids'
        format pi_d dbar_d %6.4f
        sort traj_for_agg
        di as text "  trajectory accounting:"
        list, noobs sep(0)
        export delimited using "`outdir'/`country'_e1_traj.csv", replace
    restore

    * --- 5. Compute mu_d from data: mean of indiv rural-period log consumption ---
    quietly gen log_c = ln(consumption) if consumption > 0
    quietly gen log_c_rural = log_c if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_c_rural)

    preserve
        quietly keep if pid_first == 1
        bysort traj_for_agg: egen mu_d = mean(ind_rural_mean)
        bysort traj_for_agg: gen traj_first = (_n == 1)
        quietly keep if traj_first == 1
        keep traj_for_agg mu_d
        format mu_d %9.4f
        sort traj_for_agg
        di as text "  mu_d by trajectory:"
        list, noobs sep(0)
        * Append mu_d to the traj CSV via a separate file; the Python driver
        * will merge on traj_for_agg
        export delimited using "`outdir'/`country'_e1_mu_d.csv", replace
    restore

    * --- 6. Extract switcher Delta_d from _d ster (unrestricted) into a CSV ---
    * The _d ster has Delta_2, Delta_3, ..., Delta_K columns. The mapping
    * Delta_k -> trajectory_code is positional. Per handle_trajectory_groups,
    * trajectory codes are 1 (d_N), 2..K-1 (switchers), K (d_T).
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    tempname delta_d_handle
    file open `delta_d_handle' using "`outdir'/`country'_e1_delta_d.csv", write replace
    file write `delta_d_handle' "trajectory,delta_d_unrestricted" _n
    foreach name of local d_names {
        if strpos("`name'", "Delta_") == 1 {
            local k = substr("`name'", length("Delta_") + 1, .)
            local d_k = bd[1, colnumb(bd, "`name'")]
            file write `delta_d_handle' "`k',`d_k'" _n
        }
    }
    file close `delta_d_handle'
    di as text "  wrote `outdir'/`country'_e1_delta_d.csv"

    * --- 7. Write scalars CSV ---
    tempname scalars_handle
    file open `scalars_handle' using "`outdir'/`country'_e1_scalars.csv", write replace
    file write `scalars_handle' "name,value" _n
    file write `scalars_handle' "country,`country'" _n
    file write `scalars_handle' "phi_hat,"  (phi_hat) _n
    file write `scalars_handle' "beta_hat," (beta_hat) _n
    file write `scalars_handle' "kappa_hat," (kappa_hat) _n
    file write `scalars_handle' "unb_choice_hat," (unb_choice_hat) _n
    file write `scalars_handle' "inv_phi," (inv_phi) _n
    file write `scalars_handle' "inv_dN,"  (inv_dN) _n
    file write `scalars_handle' "inv_dT,"  (inv_dT) _n
    file write `scalars_handle' "inv_davg," (inv_davg) _n
    file write `scalars_handle' "n_obs," (n_total) _n
    file write `scalars_handle' "j_stat,`jstat'" _n
    file write `scalars_handle' "j_df,`jdf'" _n
    file write `scalars_handle' "j_pval,`jp'" _n
    file close `scalars_handle'

    di as text "  wrote `outdir'/`country'_e1_scalars.csv"
    di as text "  -> E1 inputs for `country' exported"
}

}

local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> SCRIPT FAILED with rc=`saved_rc'"
