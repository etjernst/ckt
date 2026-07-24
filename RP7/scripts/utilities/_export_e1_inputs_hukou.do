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

    di as text "  phi_hat   = " phi_hat
    di as text "  beta_hat  = " beta_hat
    di as text "  J = " %6.3f `jstat' "   df = `jdf'   p = " %5.3f `jp'

    * --- 2. Read _d ster (per-trajectory LCA-fitted Delta_d) and detect base ---
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
        di as error "  base detection failed for `country_short': `n_base_matches' Delta_k match beta_hat"
        exit 498
    }
    di as text "  base trajectory = `base_traj'"

    * --- 2b. Read _n ster: the Delta_never point (E2 table point + self-check) ---
    local nster "$output/grc_`country_short'_cuu_ca_n.ster"
    capture confirm file "`nster'"
    if _rc {
        di as error "  _n ster missing for `country_short' -- required for delta_never_point"
        exit 498
    }
    quietly estimates use "`nster'"
    matrix bn = e(b)
    local n_col = colnumb(bn, "Delta_never")
    if missing(`n_col') {
        di as error "  Delta_never not found on `nster'"
        exit 498
    }
    scalar delta_never_point = bn[1, `n_col']
    di as text "  delta_never_point = " delta_never_point

    * GMM 95% CI on Delta_never (delta-method, from the _n ster's e(V)):
    * E2 scales these endpoints by the fixed shares to form the hukou-bound
    * CI (consumption gain lower bound).
    matrix Vn = e(V)
    scalar dN_se = sqrt(Vn[`n_col', `n_col'])
    if missing(dN_se) | dN_se <= 0 {
        di as error "  Delta_never SE missing or nonpositive on the _n ster for `country_short'"
        exit 498
    }
    scalar gmm_dN_ci95_lo = delta_never_point - invnormal(0.975) * dN_se
    scalar gmm_dN_ci95_hi = delta_never_point + invnormal(0.975) * dN_se
    di as text "  gmm_dN_ci95 = [" gmm_dN_ci95_lo ", " gmm_dN_ci95_hi "]"

    * --- 2c. Read _a ster: the Delta_always point (variant A of the E1 value
    * and gap terms sources the always-urban return from this GMM estimate) ---
    local aster "$output/grc_`country_short'_cuu_ca_a.ster"
    capture confirm file "`aster'"
    if _rc {
        di as error "  _a ster missing for `country_short' -- required for delta_always_point"
        exit 498
    }
    quietly estimates use "`aster'"
    matrix ba = e(b)
    local a_col = colnumb(ba, "Delta_always")
    if missing(`a_col') {
        di as error "  Delta_always not found on `aster'"
        exit 498
    }
    scalar delta_always_point = ba[1, `a_col']
    di as text "  delta_always_point = " delta_always_point

    * --- 3. Reload parent ster for switcher trajectory codes / mu's ---
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
        di as error "  no mu:switcher_* found on parent ster for `country_short'"
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

    quietly gen traj_for_agg = trajectory
    quietly replace traj_for_agg = -1 if missing(trajectory) & unbalanced == 1
    quietly count if missing(traj_for_agg)
    if r(N) > 0 {
        di as error "  `r(N)' rows have neither a trajectory nor unbalanced==1"
        exit 498
    }

    * Switcher-inclusion rule: lump non-kept switcher trajectories into the
    * -1 cell so the exported per-trajectory rows match the lumped GMM
    local e1_switchers : char _dta[grc_switchers]
    local e1_kept      : char _dta[grc_kept_switchers]
    if "`e1_kept'" == "" {
        di as error "  no grc_kept_switchers characteristic on the loaded data -- rebuild the processed hub with 1_processData.do"
        exit 459
    }
    * Redundant safety check: recompute the keep rule on this exhibit's
    * filtered sample and hard-error on disagreement with the build-time
    * characteristic (the positivity filters above could in principle
    * thin a trajectory below the rule)
    local e1_thresh : char _dta[grc_keep_threshold]
    compute_switcher_keeplist, candidates(`e1_switchers') ///
        threshold(`e1_thresh') unitvar(pid)
    if "`r(kept)'" != "`e1_kept'" {
        di as error "  keep-list mismatch: build-time kept [`e1_kept'] vs this filtered sample [`r(kept)'] (counts `r(counts)')"
        exit 459
    }
    local e1_dropped : list e1_switchers - e1_kept
    foreach s of local e1_dropped {
        quietly replace traj_for_agg = -1 if traj_for_agg == `s'
    }
    if "`e1_dropped'" != "" {
        di as text "  switcher trajectories `e1_dropped' lumped into the -1 cell (keep-list)"
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
        export delimited using "`outdir'/`country_short'_e1_traj.csv", replace
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
        export delimited using "`outdir'/`country_short'_e1_mu_d.csv", replace
    restore

    * --- 6. Extract switcher Delta_d from _d ster into a CSV ---
    * These are the restricted-fit LCA-fitted values (nlcom Delta_base +
    * phi*(mu_k - mu_base) at the GMM point estimate), named accordingly.
    quietly estimates use "`dster'"
    matrix bd = e(b)
    local d_names : colnames bd
    tempname delta_d_handle
    file open `delta_d_handle' using "`outdir'/`country_short'_e1_delta_d.csv", write replace
    file write `delta_d_handle' "trajectory,delta_d_lcafit_point" _n
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
    file write `scalars_handle' "n_obs," (n_total) _n
    file write `scalars_handle' "j_stat,`jstat'" _n
    file write `scalars_handle' "j_df,`jdf'" _n
    file write `scalars_handle' "j_pval,`jp'" _n
    file write `scalars_handle' "base,`base_traj'" _n
    file write `scalars_handle' "delta_never_point," (delta_never_point) _n
    file write `scalars_handle' "delta_always_point," (delta_always_point) _n
    file write `scalars_handle' "gmm_dN_ci95_lo," (gmm_dN_ci95_lo) _n
    file write `scalars_handle' "gmm_dN_ci95_hi," (gmm_dN_ci95_hi) _n
    file write `scalars_handle' "delta_never_source,grc_`country_short'_cuu_ca_n.ster" _n
    file write `scalars_handle' "delta_always_source,grc_`country_short'_cuu_ca_a.ster" _n
    file write `scalars_handle' "gmm_dN_ci95_source,grc_`country_short'_cuu_ca_n.ster" _n
    file write `scalars_handle' "n_rows_filtered,`n_rows_filtered'" _n
    file write `scalars_handle' "n_pids_filtered,`n_pids_filtered'" _n
    file close `scalars_handle'

    di as text "  wrote `outdir'/`country_short'_e1_scalars.csv"
    di as text "  -> E1 inputs for `country_short' exported"
}

}

local saved_rc = _rc
log close
if `saved_rc' != 0 di as error ">>> SCRIPT FAILED with rc=`saved_rc'"
