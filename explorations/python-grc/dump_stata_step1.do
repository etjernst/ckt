* Run Stata's step 1 only (gmm onestep with winitial unadjusted) and
* dump theta_1 + W_1 for side-by-side comparison with Python's step 1.
version 19
clear all
set more off
set varabbrev off
capture log close
log using "dump_stata_step1.smcl", replace

global dir     "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dir/data"
global scripts "$dir/scripts"

do "$scripts/0_programs.do"

use "$dirdata/processed/IDN_unb.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
tab period, gen(period_)

drop if mi(lndepvar) | mi(choice)

initial_values lndepvar, switchers($switchers) balance(unb) estname(initial_idn)
local base `r(base)'
local initial "`r(initial)'"

* gmm ONESTEP with winitial(unadjusted) = the exact step-1 of twostep.
* Capture theta_1 and Q(b) at the step-1 optimum.
local switcher_traj
foreach s of numlist $switchers {
    local switcher_traj "`switcher_traj' switcher_`s'"
}
define_switcherpars, switchers($switchers) base(`base')
local switcherpars `r(switcherpars)'
di as text "step1 dump: base = `base'"

eststo step1: gmm (lndepvar - {mu: never `switcher_traj'} ///
    - {Delta_base}*choice ///
    - {phi=-1}*(`switcherpars') ///
    - ({kappa}+{phi}*({kappa} - {mu: switcher_`base'}))*(always#1.choice) ///
    - {xb: unbalanced unbalanced_choice}) ///
    , instruments( ///
        unbalanced unbalanced_choice ///
        never `switcher_traj' choice ///
        always_choice switcher_*_choice, nocons ///
    ) ///
    onestep ///
    winitial(unadjusted) ///
    from(`initial') ///
    quickderivatives nolog ///
    iterate(500)

di as result "step 1 Q(b) = " e(Q)

matrix b1 = e(b)
local names : colfullnames b1
local p = colsof(b1)

tempname fh
file open `fh' using "stata_theta1.csv", write replace
file write `fh' "idx,name,value" _n
forvalues i = 1/`p' {
    local nm : word `i' of `names'
    local v  = b1[1,`i']
    file write `fh' "`i',`nm',`v'" _n
}
file close `fh'

* Also save the Q(b) so we know where step 1 landed.
file open `fh' using "stata_step1_meta.csv", write replace
file write `fh' "stat,value" _n
file write `fh' "Q,`=e(Q)'" _n
file write `fh' "converged,`=e(converged)'" _n
file write `fh' "N,`=e(N)'" _n
file write `fh' "base,`base'" _n
file close `fh'

log close
exit, STATA clear
