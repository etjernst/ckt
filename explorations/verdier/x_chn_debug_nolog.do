* ============================================================
* Title:   CHN robust diagnostic: iteration trace
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Debug why CHN's first robust fit (phistart=-1) hung
*          for 70+ min. The P1 run_grc_robust uses `nolog` which
*          suppresses iteration output. This script reruns the
*          exact same gmm call inline (so we can see the criterion
*          and per-iteration wall time) with `nolog` removed.
*          One fit only (phistart=-1). Cap at iterate(50) so we
*          bound the run time.
* Output:  x_chn_debug_nolog.smcl / .txt
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
log using "x_chn_debug_nolog.smcl", replace text
version 17

global copyOverleaf 0
include "$dir/scripts/0_programs.do"

local country CHN
local balance unb

global covs_gmm_all "female age2 education_max education_max2"
global keepvars_base lndepvar trajectory choice pid period unbalanced* switcher non_switcher
global keepvars_base $keepvars_base female age age2 education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_* year

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars_base provcd

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(unb)                    ///
    vindex(provcd)                  ///
    estname(initial_`country'_debug)
local base_chn    `r(base)'
local initial_chn "`r(initial)'"

* Replicate run_grc_robust's inline prep (so we can bare-bones the gmm call)
gen_vfirst, vname(provcd) genname(vfirst)
qui drop if missing(vfirst)
qui levelsof vfirst, local(vvals)
local V : word count `vvals'
local v_base : word 1 of `vvals'
local vchoice_list ""
foreach v of local vvals {
    if `v' != `v_base' {
        capture drop vchoice_`v'
        qui gen vchoice_`v' = (vfirst == `v') * choice
        local vchoice_list "`vchoice_list' vchoice_`v'"
    }
}

local covarlist "`periodFE' $covs_gmm_all unbalanced unbalanced_choice"

local switcher_traj
foreach s of numlist $switchers {
    local switcher_traj "`switcher_traj' switcher_`s'"
}

define_switcherpars, switchers($switchers) base(`base_chn')
local switcherpars `r(switcherpars)'

di as result _newline(2) "=== CHN debug GMM: iteration trace ON, iterate(50) cap ==="
di as result "   |V| = `V' clusters, v_base = `v_base'"
di as result "   phi start = -1, onestep, winitial unadjusted independent"
timer clear 1
timer on 1

gmm (lndepvar - {mu: never `switcher_traj'}                      ///
      - {Delta_base}*choice                                      ///
      - {beta_dev: `vchoice_list'}                               ///
      - {phi=-1}*(`switcherpars')                                ///
      - ({kappa}+{phi}*({kappa}                                  ///
      - {mu: switcher_`base_chn'}))*(always#1.choice)            ///
      - {xb: `covarlist'})                                       ///
     , instruments(                                              ///
      `covarlist'                                                ///
      never `switcher_traj' choice `vchoice_list'                ///
      always_choice switcher_*_choice, nocons                    ///
     )                                                           ///
       vce(cluster vfirst)                                       ///
       winitial(unadjusted, independent)                         ///
       onestep                                                   ///
       from(`initial_chn')                                       ///
       quickderivatives                                          ///
       iterate(50)

timer off 1
di as result _newline(2) "=== Timer (seconds) ==="
timer list

log close
capture translate "x_chn_debug_nolog.smcl" "x_chn_debug_nolog.txt", replace
exit, STATA clear
