* *******************************************************************
* Title:   Stage 0 --- 11b figure materiality probe
* Author:  CKT pipeline refactor
* Date:    2026-07-14
* Purpose: Does rebuilding the extrapolation-support figure's mu_d on the
*          per-capita outcome (log(consumption/hhsize_cube)) instead of raw
*          ln(consumption) change the in-support conclusion? Replicates the
*          per-trajectory rural-mean logic of 11b_extrapolation_support_figure.do
*          under both scales and compares mu_dN against the switcher support.
* Input:   $dirdata/processed/{IDN,CHN,TZA}_bal.dta  (READ-ONLY)
* Output:  quality_reports/staging/stage0/probe_11b.csv
* Note:    Non-destructive. Reads processed data read-only; writes only the CSV.
* *******************************************************************

version 17
clear all
set more off

global dir "C:/git/ckt/RP7"
include "$dir/scripts/0_path_config.do"

capture mkdir "C:/git/ckt/quality_reports/staging"
capture mkdir "C:/git/ckt/quality_reports/staging/stage0"

local outcsv "C:/git/ckt/quality_reports/staging/stage0/probe_11b.csv"

* header row (output captured by the stata-mp -e auto-log)
file open pf using "`outcsv'", write replace
file write pf "country,scale,mu_dN,sw_min,sw_max,dN_vs_support" _n
file close pf

capture noisily {
  foreach country in IDN CHN TZA {
    di as text _newline "==== `country' ===="

    * scale loop: raw = ln(consumption); pc = log(consumption/hhsize_cube)
    foreach scale in raw pc {
      use "$dirdata/processed/`country'_bal.dta", clear
      quietly drop if missing(consumption) | missing(trajectory) | missing(choice)

      quietly sum trajectory
      local max_traj = r(max)

      * per-individual rural mean of the chosen log-consumption scale
      if "`scale'" == "raw" {
        gen double _lc = ln(consumption) if consumption > 0 & !missing(consumption)
      }
      else {
        gen double _lc = log(consumption/hhsize_cube) if consumption > 0 & !missing(consumption) & hhsize_cube > 0 & !missing(hhsize_cube)
      }
      gen double _lc_rural = _lc if choice == 0
      bysort pid: egen double _ind_rural_mean = mean(_lc_rural)

      * collapse to one row per pid, then per-trajectory mean
      bysort pid: gen byte _pid_first = (_n == 1)
      quietly keep if _pid_first == 1
      bysort trajectory: egen double _mu_d_traj = mean(_ind_rural_mean)

      quietly sum _mu_d_traj if trajectory == 1, meanonly
      local mu_dN = r(mean)

      quietly sum _mu_d_traj if trajectory > 1 & trajectory < `max_traj'
      local sw_min = r(min)
      local sw_max = r(max)

      * where does the never-migrant target sit relative to switcher support?
      local pos "inside"
      if `mu_dN' < `sw_min' local pos "below"
      if `mu_dN' > `sw_max' local pos "above"

      di as text "  scale=`scale'  mu_dN=" %9.4f `mu_dN' "  support=[" %9.4f `sw_min' ", " %9.4f `sw_max' "]  -> `pos'"

      file open pf using "`outcsv'", write append
      file write pf "`country',`scale',`mu_dN',`sw_min',`sw_max',`pos'" _n
      file close pf
    }
  }
}
local saved_rc = _rc
if `saved_rc' != 0 {
  di as error ">>> stage0_11b_probe FAILED with rc=`saved_rc'"
}
else {
  di as text ">>> stage0_11b_probe complete. See `outcsv'"
}
