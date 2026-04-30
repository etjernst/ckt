* ============================================================
* Title:   M4 verification (extended) --- 4 cells, 3 caveats
* Author:  Emilia (with Claude)
* Date:    2026-04-30
* Purpose: Strengthen the original M4 verification by spot-checking
*          three caveats from quality_reports/reviews/2026-04-30_M4-verification.md:
*            2a covariate spec  --- CHN cub ca (full controls)
*            2b _robust path    --- skipped; closed by code-symmetry argument
*                                    (initial_values_robust was written by
*                                    copying initial_values WITH the duplicate
*                                    already in it, so M4's symmetric edit
*                                    has identical effect on both)
*            2c sample variation --- IDN cub c0, TZA cub c0
*          Plus the original baseline cell (CHN cub c0) re-tested as a
*          smoke check that the driver is correct.
* Input:   RP7/output/grc_{CHN,IDN,TZA}_cub_{c0,ca}.ster (pre-M4 references)
*          RP7/data/processed/{CHN,IDN,TZA}_bal.dta
*          RP7/scripts/0_path_config.do
*          RP7/scripts/0_programs.do        (post-M4 cleanup)
* Output:  RP7/output/verify_M4_{CHN,IDN,TZA}_cub_{c0,ca}*.ster (refit sters)
*          RP7/output/verify_M4_extended_summary.txt (max abs diff per cell)
* ============================================================

clear all
set more off
set varabbrev off

global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"

quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

* Route all subsequent output to a log file on disk so the MCP response cap
* never trips. After `log using`, even un-quietly run_grc traces land in the
* .smcl, not in stdout.
capture log close
log using "$logs/verify_M4_extended.smcl", replace

* ============================================================
* Stash all four references first so they survive `use ..., clear`
* ============================================================
foreach pair in CHN_cub_c0 CHN_cub_ca IDN_cub_c0 TZA_cub_c0 {
    estimates use "$output/grc_`pair'.ster"
    matrix b_ref_`pair' = e(b)
    matrix V_ref_`pair' = e(V)
}

* ============================================================
* Cub-section globals (mirror 5_GrRC.do L284-299)
* ============================================================
local choice  urban
local depvar  consumption
local balance bal

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* ============================================================
* CHINA block --- refit cub c0 AND cub ca
* (same data prep + initial_values; two run_grc calls)
* ============================================================
di as text "===> CHN block start: " c(current_time)

local country CHN
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)
quietly setup_grc_estimation
keep $keepvars
quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
local initial "`r(initial)'"
local iterations $grc_max_iter

* run_grc writes derived sters (_a, _g, _n, _d) after the main fit, so
* e(b) after run_grc reflects the LAST one, not the main fit. Don't try
* to stash matrices here --- read each main ster back from disk in the
* comparison loop below.

di as text "  CHN cub c0 fit: " c(current_time)
run_grc, estname(verify_M4_CHN_cub_c0)                            ///
    switchers($switchers) base(`base') initial(`initial')         ///
    balance(`balance') iterate(`iterations')

di as text "  CHN cub ca fit: " c(current_time)
run_grc, estname(verify_M4_CHN_cub_ca)                            ///
    switchers($switchers) base(`base') initial(`initial')         ///
    balance(`balance') covars(`periodFE' $covs_gmm_all)           ///
    iterate(`iterations')

* ============================================================
* INDONESIA block --- refit cub c0
* ============================================================
di as text "===> IDN block start: " c(current_time)

local country IDN
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)
quietly setup_grc_estimation
keep $keepvars
quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
local initial "`r(initial)'"

di as text "  IDN cub c0 fit: " c(current_time)
run_grc, estname(verify_M4_IDN_cub_c0)                            ///
    switchers($switchers) base(`base') initial(`initial')         ///
    balance(`balance') iterate(`iterations')

* ============================================================
* TANZANIA block --- refit cub c0
* ============================================================
di as text "===> TZA block start: " c(current_time)

local country TZA
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)
quietly setup_grc_estimation
keep $keepvars
quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_`country')
local base `r(base)'
local initial "`r(initial)'"

di as text "  TZA cub c0 fit: " c(current_time)
run_grc, estname(verify_M4_TZA_cub_c0)                            ///
    switchers($switchers) base(`base') initial(`initial')         ///
    balance(`balance') iterate(`iterations')

di as text "===> All fits done: " c(current_time)

* ============================================================
* Compare each cell. Persist a one-line summary per cell.
* ============================================================
mata:
fh = fopen(st_global("output") + "/verify_M4_extended_summary.txt", "w")
fput(fh, "M4 extended verification summary --- 2026-04-30")
fput(fh, sprintf("%-18s | %-7s | %-22s | %-22s | %-12s | %-12s",
                 "cell", "k", "max |b_new - b_ref|", "max |V_new - V_ref|",
                 "mreldif(b)", "mreldif(V)"))
fput(fh, "----------------------------------------------------------------------------------------------------")
fclose(fh)
end

foreach pair in CHN_cub_c0 CHN_cub_ca IDN_cub_c0 TZA_cub_c0 {
    quietly estimates use "$output/verify_M4_`pair'.ster"
    matrix b_new = e(b)
    matrix V_new = e(V)

    matrix dB = b_new - b_ref_`pair'
    matrix dV = V_new - V_ref_`pair'
    mata: max_abs_b = max(abs(st_matrix("dB")))
    mata: max_abs_V = max(abs(st_matrix("dV")))
    local mrel_b = mreldif(b_new, b_ref_`pair')
    local mrel_V = mreldif(V_new, V_ref_`pair')
    local k = colsof(b_new)
    local n = e(N)

    mata: st_local("max_abs_b", strofreal(max_abs_b, "%22.16e"))
    mata: st_local("max_abs_V", strofreal(max_abs_V, "%22.16e"))

    di ""
    di as text "=== `pair' ==="
    di "  k          = `k'"
    di "  N          = `n'"
    di "  max |dB|   = `max_abs_b'"
    di "  max |dV|   = `max_abs_V'"
    di "  mreldif b  = `mrel_b'"
    di "  mreldif V  = `mrel_V'"

    mata: fh2 = fopen(st_global("output") + "/verify_M4_extended_summary.txt", "a")
    mata: fput(fh2, sprintf("%-18s | %-7s | %-22s | %-22s | %-12s | %-12s",
                            st_local("pair"),
                            st_local("k"),
                            st_local("max_abs_b"),
                            st_local("max_abs_V"),
                            st_local("mrel_b"),
                            st_local("mrel_V")))
    mata: fclose(fh2)
}

di ""
di as text "Summary at: $output/verify_M4_extended_summary.txt"
type "$output/verify_M4_extended_summary.txt"

log close
