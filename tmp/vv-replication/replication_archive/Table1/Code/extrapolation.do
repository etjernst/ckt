
*Longleaf
*sbatch -p general -N 1 -t 6:00:00 --mem=6g -n 1 --wrap="stata-se -b do Code/extrapolation.do"

*Not robust
capture log close
log using Results/log.smcl, replace
clear all
set more off
local per_start=1
local per_end=4
qui do Code/firststage_projection `per_start' `per_end'
do Code/nrobust.do `per_start' `per_end'
log close
translate Results/log.smcl Results/log_nrobust.pdf, replace

*Robust
capture log close
log using Results/log.smcl, replace 
clear all
set more off
local start=1
local end=4
qui do Code/firststage_projection `start' `end'
do Code/robust.do `per_start' `per_end'
log close
translate Results/log.smcl Results/log_robust.pdf, replace
