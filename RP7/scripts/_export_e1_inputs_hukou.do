* ============================================================
* Title:   Export E1 inputs to CSV for CHN hukou subsamples
* Author:  Emilia Tjernström (with Claude)
* Date:    2026-05-20
* Purpose: Hukou-subsample parallel of _export_e1_inputs.do. For each
*          hukou subsample, writes the same four CSVs the IDN/TZA
*          exporter produces, using the country-short prefix as the
*          CSV filename so the Python driver can loop generically.
* Input:   $output/grc_<country_short>_cuu_ca{,_d}.ster,
*          $dirdata/processed/<country>_unb.dta
* Output:  $output/counterfactual_inputs/<country_short>_e1_{traj,mu_d,
*          delta_d,scalars}.csv
* ============================================================

version 17
set more off
set varabbrev off
capture log close

if "$dir" == "" {
    if "`c(username)'" == "maand" global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
quietly include "$dir/scripts/0_path_config.do"

cap mkdir "$output/counterfactual_inputs"
local outdir "$output/counterfactual_inputs"

log using "$logs/_export_e1_inputs_hukou.smcl", replace

capture noisily {

* Hukou subsamples to process. RF and UF are the priority; RO and UO
* can be appended once their inversion scalars are attached.
foreach country in CHN_hukou_rural_first CHN_hukou_urban_first {

    if "`country'" == "CHN_hukou_rural_first" local country_short CHN_rf
    else if "`country'" == "CHN_hukou_urban_first" local country_short CHN_uf
    else if "`country'" == "CHN_hukou_rural_only"  local country_short CHN_ro
    else if "`country'" == "CHN_hukou_urban_only"  local country_short CHN_uo

    di as text _newline(2) "==== `country' (`country_short') ===="

    * --- 1. Read parent ster: phi_hat, beta_hat, inversion scalars ---
    local pster "$output/grc_`country_short'_cuu_ca.ster"
    capture confirm file "`pster'"
    if _rc {
        di as error "  parent ster missing -- skipping `country_short'"
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
    local dster "$output/grc_`country_short'_cuu_ca_d.ster"
    capture confirm file "`dster'"
    if _rc {
        di as error "  _d ster missing -- skipping `country_short'"
        continue
    }
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    di as text "  _d ster parameters: `d_names'"

    * --- 3. Reload parent ster for switcher trajectory codes / mu's ---
    quietly estimates use "`pster'"
    matrix b = e(b)
    local b_names : colnames b
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

    bysort pid: gen pid_first = (_n == 1)
    bysort pid: egen dbar_indiv = mean(choice)
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
        export delimited using "`outdir'/`country_short'_e1_traj.csv", replace
    restore

    * --- 5. Compute mu_d from data ---
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
        export delimited using "`outdir'/`country_short'_e1_mu_d.csv", replace
    restore

    * --- 6. Extract switcher Delta_d from _d ster ---
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    tempname delta_d_handle
    file open `delta_d_handle' using "`outdir'/`country_short'_e1_delta_d.csv", write replace
    file write `delta_d_handle' "trajectory,delta_d_unrestricted" _n
    foreach name of local d_names {
        if strpos("`name'", "Delta_") == 1 {
            local k = substr("`name'", length("Delta_") + 1, .)
            local d_k = bd[1, colnumb(bd, "`name'")]
            file write `delta_d_handle' "`k',`d_k'" _n
        }
    }
    file close `delta_d_handle'
    di as text "  wrote `outdir'/`country_short'_e1_delta_d.csv"

    * --- 7. Write scalars CSV ---
    tempname scalars_handle
    file open `scalars_handle' using "`outdir'/`country_short'_e1_scalars.csv", write replace
    file write `scalars_handle' "name,value" _n
    file write `scalars_handle' "country,`country_short'" _n
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

    di as text "  wrote `outdir'/`country_short'_e1_scalars.csv"
    di as text "  -> E1 inputs for `country_short' exported"
}

}

local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> SCRIPT FAILED with rc=`saved_rc'"
