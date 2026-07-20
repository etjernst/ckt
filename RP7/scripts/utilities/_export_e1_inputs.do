* ============================================================
* Title:   Export E1 inputs to CSV for the V2 back-of-envelope check
* Author:  Emilia Tjernström (with Claude)
* Date:    2026-05-18
* Purpose: E1 input exporter. For each country that has cuu_ca sters,
*          writes four CSVs:
*            <country>_e1_traj.csv    rows by trajectory: n_pids, pi_d,
*                                    dbar_d, dbar0_d (first-observed-wave
*                                    urban share)
*            <country>_e1_mu_d.csv    mu_d_ster (model, per-capita) and
*                                    mu_d_raw_hh (raw household cross-check)
*            <country>_e1_delta_d.csv delta_d_lcafit_point per switcher
*            <country>_e1_scalars.csv phi_hat, beta_hat, base, inversion
*                                    scalars, delta_never_point, filtered
*                                    row/pid counts
* Input:   $output/grc_<c>_cuu_ca{,_d}.ster, $dirdata/processed/<c>_unb.dta
* Output:  $output/counterfactual_inputs/<c>_e1_{traj,scalars}.csv
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

    * --- 2. Read _d ster (per-trajectory LCA-fitted Delta_d) and detect base ---
    local dster "$output/grc_`country'_cuu_ca_d.ster"
    capture confirm file "`dster'"
    if _rc {
        di as error "  _d ster missing -- skipping `country'"
        continue
    }
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    di as text "  _d ster parameters: `d_names'"

    * Base trajectory: the unique k with Delta_k equal to Delta_base:_cons.
    * The _d ster values are nlcom Delta_base + phi*(mu_k - mu_base), so the
    * base's own entry equals beta_hat to machine precision.
    local base_traj = .
    local n_base_matches = 0
    foreach name of local d_names {
        if strpos("`name'", "Delta_") == 1 {
            local k = substr("`name'", length("Delta_") + 1, .)
            if abs(bd[1, colnumb(bd, "`name'")] - beta_hat) < 1e-10 {
                local base_traj `k'
                local n_base_matches = `n_base_matches' + 1
            }
        }
    }
    if `n_base_matches' != 1 {
        di as error "  base detection failed for `country': `n_base_matches' Delta_k match beta_hat"
        exit 498
    }
    di as text "  base trajectory = `base_traj'"

    * --- 2b. Read _n ster: the Delta_never point for the self-check ---
    local nster "$output/grc_`country'_cuu_ca_n.ster"
    capture confirm file "`nster'"
    if _rc {
        di as error "  _n ster missing for `country' -- required for delta_never_point"
        exit 498
    }
    quietly estimates use "`nster'"
    matrix bn = e(b)
    scalar delta_never_point = bn[1, colnumb(bn, "Delta_never")]
    di as text "  delta_never_point = " delta_never_point

    * --- 3. From parent ster b matrix: extract mu:never and mu:switcher_k ---
    * NB: `: colnames` strips equation prefixes, so match on coleq+colnames
    * pairs (a bare strpos on "mu:switcher_" never matches).
    quietly estimates use "`pster'"
    matrix b = e(b)
    local b_names : colnames b
    local b_eqs   : coleq b
    local n_bcols = colsof(b)
    local sw_traj_codes ""
    forvalues j = 1/`n_bcols' {
        local eq : word `j' of `b_eqs'
        local nm : word `j' of `b_names'
        if "`eq'" == "mu" & strpos("`nm'", "switcher_") == 1 {
            local k = substr("`nm'", length("switcher_") + 1, .)
            local sw_traj_codes "`sw_traj_codes' `k'"
            local mu_ster_`k' = b[1, `j']
        }
    }
    if "`sw_traj_codes'" == "" {
        di as error "  no mu:switcher_* found on parent ster for `country'"
        exit 498
    }
    local mu_never = b[1, colnumb(b, "mu:never")]
    di as text "  switcher trajectory codes from parent ster: `sw_traj_codes'"
    di as text "  mu_never (ster) = `mu_never'"

    * --- 4. Load data: compute pi_d, dbar_d, dbar0_d, n_pids per trajectory ---
    * Filter matches the Python auxiliary fit exactly: positive consumption
    * and hhsize_cube (Stata ln() of nonpositive is missing but np.log(0) is
    * -inf and survives dropna, so positivity, not missingness, is the
    * aligned condition), plus non-missing choice, period, controls, and
    * unbalanced dummies.
    use "$dirdata/processed/`country'_unb.dta", clear
    quietly drop if missing(consumption) | consumption <= 0
    quietly drop if missing(hhsize_cube) | hhsize_cube <= 0
    quietly drop if missing(choice) | missing(period)
    foreach v in female age2 education_max education_max2 unbalanced unbalanced_choice {
        capture confirm variable `v'
        if !_rc quietly drop if missing(`v')
    }

    * Per-individual urban share, first-observed-wave choice, and trajectory
    bysort pid: gen pid_first = (_n == 1)
    bysort pid: egen dbar_indiv = mean(choice)
    bysort pid (period): gen d0_indiv = choice[1]

    quietly count
    local n_rows_filtered = r(N)
    quietly count if pid_first == 1
    local n_pids_filtered = r(N)

    * For unbalanced spec: trajectory is missing for unbalanced individuals.
    * We treat those as a single "lumped switcher" cell coded -1 so it stays
    * distinct from the integer trajectory codes.
    quietly gen traj_for_agg = trajectory
    quietly replace traj_for_agg = -1 if missing(trajectory) & unbalanced == 1
    quietly count if missing(traj_for_agg)
    if r(N) > 0 {
        di as error "  `r(N)' rows have neither a trajectory nor unbalanced==1"
        exit 498
    }

    preserve
        quietly keep if pid_first == 1
        bysort traj_for_agg: egen n_pids = count(pid)
        bysort traj_for_agg: egen double dbar_d  = mean(dbar_indiv)
        bysort traj_for_agg: egen double dbar0_d = mean(d0_indiv)
        bysort traj_for_agg: gen  traj_first = (_n == 1)
        quietly keep if traj_first == 1
        keep traj_for_agg n_pids dbar_d dbar0_d
        quietly count
        local n_traj = r(N)
        quietly sum n_pids
        local n_total_pids = r(sum)
        quietly gen double pi_d = n_pids / `n_total_pids'
        format pi_d dbar_d dbar0_d %6.4f
        sort traj_for_agg
        di as text "  trajectory accounting:"
        list, noobs sep(0)
        export delimited using "`outdir'/`country'_e1_traj.csv", replace
    restore

    * --- 5. mu_d CSV: ster (model, per-capita, covariate-consistent) plus the
    * raw household-level data mean, kept only as a labeled cross-check ---
    quietly gen log_c = ln(consumption)
    quietly gen log_c_rural = log_c if choice == 0
    bysort pid: egen ind_rural_mean = mean(log_c_rural)

    preserve
        quietly keep if pid_first == 1
        bysort traj_for_agg: egen double mu_d_raw_hh = mean(ind_rural_mean)
        bysort traj_for_agg: gen traj_first = (_n == 1)
        quietly keep if traj_first == 1
        keep traj_for_agg mu_d_raw_hh
        quietly gen double mu_d_ster = .
        quietly replace mu_d_ster = `mu_never' if traj_for_agg == 1
        foreach k of local sw_traj_codes {
            quietly replace mu_d_ster = `mu_ster_`k'' if traj_for_agg == `k'
        }
        format mu_d_raw_hh mu_d_ster %12.6f
        sort traj_for_agg
        di as text "  mu_d by trajectory (ster and raw-household cross-check):"
        list, noobs sep(0)
        export delimited using "`outdir'/`country'_e1_mu_d.csv", replace
    restore

    * --- 6. Extract switcher Delta_d from _d ster into a CSV ---
    * These are the restricted-fit LCA-fitted values (nlcom Delta_base +
    * phi*(mu_k - mu_base) at the GMM point estimate), named accordingly.
    * The _d ster has Delta_2, ..., Delta_K-1 columns; trajectory codes are
    * 1 (d_N), 2..K-1 (switchers), K (d_T).
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    tempname delta_d_handle
    file open `delta_d_handle' using "`outdir'/`country'_e1_delta_d.csv", write replace
    file write `delta_d_handle' "trajectory,delta_d_lcafit_point" _n
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
    file write `scalars_handle' "base,`base_traj'" _n
    file write `scalars_handle' "delta_never_point," (delta_never_point) _n
    file write `scalars_handle' "n_rows_filtered,`n_rows_filtered'" _n
    file write `scalars_handle' "n_pids_filtered,`n_pids_filtered'" _n
    file close `scalars_handle'

    di as text "  wrote `outdir'/`country'_e1_scalars.csv"
    di as text "  -> E1 inputs for `country' exported"
}

}

local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> SCRIPT FAILED with rc=`saved_rc'"
