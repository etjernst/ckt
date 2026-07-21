* ============================================================
* Title:   Cluster-residualized GRC summary (phi + Delta_never)
* Author:  Emilia (with Claude)
* Date:    2026-07-01
* Purpose: Run the cluster-residualized GRC (run_grc_robust_vv) at the
*          onestep / full-controls specification for the five rows of the
*          "Robustness to cluster pooling" summary table:
*              IDN, CHN (all), CHN rural-first, CHN urban-first, TZA.
*          Then build the summary table via cluster_comparison_table,
*          which reads phi (grc_/vv_ *_cuu_ca / *_os_covs_all) and
*          Delta_never (the _n sters) for baseline and cluster columns.
* Input:   $dirdata/processed/{IDN,CHN,TZA}_unb.dta,
*          $dirdata/processed/CHN_hukou_{rural,urban}_first_unb.dta,
*          baseline grc_*_cuu_ca(+_n) sters in $output (copied in).
* Output:  $output/vv_{IDN,CHN,CHN_rf,CHN_uf,TZA}_os_covs_all(+_n/_a/_d/_g).ster
*          $output/tables/cluster_comparison_consumption_unb.tex
* Note:    Onestep / full controls only. The twostep columns and the full
*          per-country appendix tables are the deferred "full run" (see
*          docs/TODO.md).
* ============================================================

* Resume-on-interrupt: skip cells whose final .ster (_g) already exists.
* Set to 0 to force every cell to re-estimate.
global skip_if_exists 1

cd "$logs"
capture log close
log using 17b_cluster_summary.log, replace

capture noisily {

* GMM covariate sets (single source; mirror 17_verdier_robust.do)
set_covariate_globals

* Keep only relevant vars; `year` is required by gen_vfirst (bysort pid (year)),
* and the cluster index (vindex) must survive the keep.
global keepvars_base logpc_consumption trajectory choice pid year
global keepvars_base $keepvars_base period unbalanced* switcher non_switcher
global keepvars_base $keepvars_base female age age2
global keepvars_base $keepvars_base education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_*

local iterations 100

* One onestep / full-controls cluster fit per summary row.
* Parallel lists: row code, processed dataset stem, cluster index (vfirst seed).
local codes "IDN CHN CHN_rf CHN_uf TZA"
local dsets "IDN_unb CHN_unb CHN_hukou_rural_first_unb CHN_hukou_urban_first_unb TZA_unb"
local vidxs "prov provcd provcd provcd region"

local nrows : word count `codes'
forval k = 1/`nrows' {
    local code : word `k' of `codes'
    local dset : word `k' of `dsets'
    local vidx : word `k' of `vidxs'

    di as txt "================================================================"
    di as txt "cluster fit: code=`code' data=`dset' vindex=`vidx'"
    di as txt "================================================================"

    use "$dirdata/processed/`dset'.dta", clear
    * nolump: cluster diagnostics describe the Verdier path, which
    * applies its own cluster-counted switcher keep rule
    setup_grc_estimation, nolump
    global keepvars $keepvars_base `vidx'
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    initial_values logpc_consumption, ///
        switchers($switchers)       ///
        balance(unb)                ///
        estname(initial_`code')
    local base `r(base)'
    local initial "`r(initial)'"

    * Onestep, full controls (period FE + female + age^2 + education + education^2)
    run_grc_robust_vv,                                    ///
        estname(vv_`code'_os_covs_all)                    ///
        switchers($switchers) base(`base') initial(`initial') ///
        balance(unb) vindex(`vidx')                       ///
        covars(`periodFE' $covs_gmm_all)                  ///
        iterate(`iterations') onestep
}

* Build the summary table from the baseline (grc_) and cluster (vv_) sters.
cluster_comparison_table, filename(cluster_comparison_consumption_unb) ///
    countries("IDN CHN CHN_rf CHN_uf TZA")

}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> 17b_cluster_summary FAILED with rc=`saved_rc'"
}
