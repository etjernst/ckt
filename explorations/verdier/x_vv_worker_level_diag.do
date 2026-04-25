* ============================================================
* Title:   VV worker-level diagnostic port
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Compare phi estimates across three approaches at the
*          headline covs_all, consumption/urban/unbalanced spec:
*          (1) run_grc         --- CKT simple twostep (published).
*          (2) run_grc_robust_vv --- CKT Verdier robust (current
*              "Verdier" spec in the paper).
*          (3) VV worker-level --- verbatim port of VV (2020)
*              Table1/Code/{firststage_projection.do, robust.do}.
*              Chamberlain within-household projection + village-
*              demeaned instruments + worker-level 2SLS.
*          The VV estimator is NOT proposed as the paper's primary.
*          It is a diagnostic to test whether trajectory pooling
*          introduces alpha-pooling bias in run_grc_robust_vv.
*          See docs/plans/2026-04-24-vv-worker-level-diagnostic.md.
* Input:   data/processed/{IDN,CHN,TZA}_unb.dta
*          $output/cmp_{country}_all.ster   (simple twostep main)
*          $output/cmpvv_{country}_all.ster (Verdier robust main)
* Output:  x_vv_worker_level_diag.smcl / .txt
*          x_vv_worker_level_diag_results.dta (one row per country
*          with simple/verdier/vv phi estimates and SEs)
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
include "$dir/scripts/0_path_config.do"

cd "$dir/explorations/verdier"
log using "x_vv_worker_level_diag.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/RP7/scripts/0_programs.do"

* Redirect $dir to RP7/ so all run_grc / run_grc_robust_vv saves
* (which hardcode `$dir/output/...`) land in our local, tracked
* RP7/output instead of the coauthor's read-only RP6 junction in
* Dropbox. $dirdata was set from the original $dir before this
* override, so data loading still works.
* This fixes the issue where .ster files saved to the junction
* disappear between sessions due to Dropbox/sync interactions.
capture mkdir "$dir/RP7/output"
global dir "$dir/RP7"
global output "$dir/output"
di as text "Output redirected to: $output (was $dir/.. before override)"
di as text "Data still loads from: $dirdata"

* Min per-switcher treated-pid count to keep a switcher as instrument
* (matches lca_inversion.py's drop_sparse_switchers threshold)
local switcher_min 5

global covs_gmm_all "female age2 education_max education_max2"

tempname results
postfile `results' str4 country double(phi_simple se_simple ///
    phi_verdier se_verdier phi_vv se_vv diff_vv_verdier tol within_tol ///
    n_obs n_pids n_switcher_pids n_kept_switchers) ///
    using "x_vv_worker_level_diag_results.dta", replace

foreach country in IDN CHN TZA {

    di as result _newline(2) "################################"
    di as result "# `country'"
    di as result "################################"

    * Country-specific cluster variable (matches main comparison)
    if "`country'" == "CHN" {
        local vidx provcd
    }
    else if "`country'" == "TZA" {
        local vidx region
    }
    else {
        local vidx prov
    }

    * Load and set up
    use "$dirdata/processed/`country'_unb.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)

    setup_grc_estimation
    * Keep everything we need through to the 2SLS
    keep lndepvar trajectory choice pid year period unbalanced* ///
        switcher switcher_* non_switcher ///
        female age age2 education_max education_max2 trend ///
        always always_choice never `vidx'

    * Verdier first-wave cluster index (used for instruments and clustering SE)
    gen_vfirst, vname(`vidx') genname(vfirst)
    qui drop if missing(vfirst)

    * Period dummies (for covs_all covariates)
    tab period, gen(period_)
    qui levelsof period, local(pers)
    local n_per : word count `pers'
    local periodFE "period_2 - period_`n_per'"

    qui levelsof vfirst, local(vvals)
    local V : word count `vvals'
    di as text "  |V| = `V' clusters (vindex = `vidx')"

    * ----------------------------------------------------------
    * Refit simple + Verdier covs_all baselines INLINE so we don't
    * depend on stale .ster files or x_main_comparison_results.dta.
    * Saves to RP7/output (durable, tracked) for downstream re-use.
    * ----------------------------------------------------------
    initial_values lndepvar,         ///
        switchers($switchers)        ///
        balance(unb)                 ///
        estname(init_vvdiag_`country')
    local base    `r(base)'
    local initial "`r(initial)'"

    di as result _newline "=== Refit: run_grc (simple twostep) ==="
    run_grc, estname(vvd_simple_`country')                         ///
        switchers($switchers) base(`base')                          ///
        initial(`initial')                                          ///
        balance(unb)                                                ///
        covars(`periodFE' $covs_gmm_all)                            ///
        iterate(500)
    estimates use "$output/vvd_simple_`country'"
    local phi_simple = _b[phi:_cons]
    local se_simple  = _se[phi:_cons]
    di as result "  simple: phi = " %9.4f `phi_simple' ", se = " %9.4f `se_simple'

    di as result _newline "=== Refit: run_grc_robust_vv (Verdier) ==="
    preserve
        run_grc_robust_vv, estname(vvd_verdier_`country')           ///
            switchers($switchers) base(`base')                       ///
            initial(`initial')                                       ///
            balance(unb) vindex(`vidx')                              ///
            covars(`periodFE' $covs_gmm_all)                         ///
            iterate(500)

        estimates use "$output/vvd_verdier_`country'"
        local phi_verdier = _b[phi:_cons]
        local se_verdier  = _se[phi:_cons]
        di as result "  verdier: phi = " %9.4f `phi_verdier' ", se = " %9.4f `se_verdier'
    restore

    * ----------------------------------------------------------
    * Stage 1: Chamberlain within-household projection
    * VV absorbs (hhid * 10 + hybrid); we absorb (pid * 10 + choice).
    * Covariates: periodFE + female + age2 + education_max + education_max2
    *             + unbalanced + unbalanced_choice  (matches covs_all)
    * ----------------------------------------------------------
    di as result _newline "=== Stage 1: Chamberlain projection (areg) ==="
    capture drop pid_choice
    gen long pid_choice = pid * 10 + choice

    local covars "period_2-period_`n_per' female age2 education_max education_max2 unbalanced unbalanced_choice"

    areg lndepvar `covars', absorb(pid_choice)
    * VV uses predict ..., d (the dummies / FE contribution), NOT resid.
    * That gives the (pid, choice) cell mean of y net of covariates.
    * residuals from areg average to zero within each absorbed cell by
    * construction, so taking cell-means of residuals would just be zero.
    predict d_hat if e(sample), d

    * ----------------------------------------------------------
    * Stage 1b: per-pid a_i (FE for choice=0) and apb_i (FE for choice=1)
    *           return_i = apb_i - a_i (defined for switchers only)
    * d_hat is constant within (pid, choice) cell, so taking the mean
    * over all obs in the cell just returns that constant value.
    * ----------------------------------------------------------
    capture drop a_pid apb_pid return_pid_v a apb
    bysort pid: egen a_pid   = mean(d_hat) if choice == 0
    bysort pid: egen apb_pid = mean(d_hat) if choice == 1
    * Spread a_pid and apb_pid across all obs of each pid
    bysort pid: egen a   = max(a_pid)
    bysort pid: egen apb = max(apb_pid)
    drop a_pid apb_pid
    gen return_pid_v = apb - a  // well-defined for switchers only

    * Check: for switchers both a and apb should be non-missing
    qui count if switcher == 1 & (missing(a) | missing(apb))
    local n_sw_missing = r(N)
    if `n_sw_missing' > 0 {
        di as text "  `country': `n_sw_missing' switcher obs with missing a or apb (dropped)"
    }

    * ----------------------------------------------------------
    * Stage 2: VV-style period-specific village-demeaned instruments
    * Match VV's Table1/Code/{firststage_projection.do, robust.do}:
    * hybrid_per = 1 if worker was urban in period per (propagated to
    * all obs of the worker via egen max), then reg hybrid_per on
    * i.vfirst among switchers; residual = village-demeaned instrument.
    * One instrument per period.
    * ----------------------------------------------------------
    di as result _newline "=== Stage 2: VV-style period-specific instruments ==="

    local instr_list ""
    forvalues per = 1/`n_per' {
        capture drop hybrid`per' hybrid`per'd _tmp_h
        * Per-period treatment indicator, propagated within pid
        gen _tmp_h = choice if period == `per'
        bysort pid: egen hybrid`per' = max(_tmp_h)
        drop _tmp_h

        * Village-demean among switchers
        qui reg hybrid`per' i.vfirst if switcher == 1
        qui predict hybrid`per'd if switcher == 1, resid
        qui replace hybrid`per'd = 0 if missing(hybrid`per'd)

        local instr_list "`instr_list' hybrid`per'd"
    }

    * Check how many instruments have actual variation among switchers
    local instr_kept ""
    foreach inst of local instr_list {
        qui sum `inst' if switcher == 1
        if r(sd) > 0 {
            local instr_kept "`instr_kept' `inst'"
        }
        else {
            di as text "  `inst' has zero variance among switchers; drop"
        }
    }
    local n_instr : word count `instr_kept'
    di as text "  `country': kept `n_instr' period-specific instruments: `instr_kept'"

    * ----------------------------------------------------------
    * Stage 3: collapse to one row per pid, worker-level 2SLS
    * Dep: a (rural residual mean per pid)
    * Endog: return (post-pre residual difference per pid)
    * Instruments: {hybrid_per_d}_{per}
    * Cluster SE at vfirst.
    * ----------------------------------------------------------
    di as result _newline "=== Stage 3: worker-level 2SLS ==="
    preserve
        collapse (mean) a return_pid_v `instr_list' ///
                 (first) vfirst switcher, by(pid)

        qui count
        local n_pids_total = r(N)
        qui count if switcher == 1
        local n_switcher_pids = r(N)
        di as text "  `country': `n_pids_total' pids total, `n_switcher_pids' switcher pids"

        * 2SLS: restrict to switchers (return defined only there) with
        * valid instruments. ivregress drops non-switchers automatically.
        ivregress 2sls a (return_pid_v = `instr_kept'), vce(cluster vfirst)

        local phi_vv = _b[return_pid_v]
        local se_vv  = _se[return_pid_v]
        local n_2sls = e(N)

        di as result "  `country' VV phi = " %9.4f `phi_vv' ", se = " %9.4f `se_vv'
    restore
    local n_kept = `n_instr'

    * ----------------------------------------------------------
    * Comparison summary
    * ----------------------------------------------------------
    local diff_vv_verdier = abs(`phi_vv' - `phi_verdier')
    local tol = max(0.05, `se_verdier')
    local within_tol = (`diff_vv_verdier' < `tol')

    qui count
    local n_obs = r(N)
    qui levelsof pid, local(pidsu)
    local n_pids : word count `pidsu'

    post `results' ("`country'") ///
        (`phi_simple') (`se_simple') ///
        (`phi_verdier') (`se_verdier') ///
        (`phi_vv') (`se_vv') ///
        (`diff_vv_verdier') (`tol') (`within_tol') ///
        (`n_obs') (`n_pids') (`n_switcher_pids') (`n_kept')

    di as result _newline "  |VV - Verdier| = " %6.4f `diff_vv_verdier' ///
        ", tolerance = " %6.4f `tol' ///
        ", within? = `within_tol'"
}

postclose `results'

* ============================================================
* Report
* ============================================================
di as result _newline(2) "============================================================"
di as result "# THREE-WAY COMPARISON: simple vs Verdier vs VV worker-level"
di as result "============================================================"

use "x_vv_worker_level_diag_results.dta", clear

format phi_simple se_simple phi_verdier se_verdier phi_vv se_vv diff_vv_verdier tol %8.4f
format n_obs n_pids n_switcher_pids n_kept_switchers %10.0fc

list country phi_simple se_simple phi_verdier se_verdier phi_vv se_vv, ///
    abbrev(12) noobs sep(0)

di as result _newline "Tolerance check: |phi_VV - phi_Verdier| vs max(0.05, se_Verdier)"
list country diff_vv_verdier tol within_tol, abbrev(12) noobs sep(0)

di as result _newline "Sample sizes:"
list country n_obs n_pids n_switcher_pids n_kept_switchers, abbrev(16) noobs sep(0)

log close
capture translate "x_vv_worker_level_diag.smcl" "x_vv_worker_level_diag.txt", replace
exit, STATA clear
