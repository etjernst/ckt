
local batch = `1'
local seed = `2'

log using log_`batch'.log, replace

clear
set more off
set matsize 10000
set varabbrev off

* Create master data from which clusters are drawn from
use Data/SuriPanel_extended.dta
drop if vil==""
encode vil, gen(vil2)
drop vil
rename vil2 vil
save Data/SuriPanel_extended_forbs.dta, replace

*  Estimates
do Code/testdist_estimates.do
local alpha2_estimate=alpha2

set seed `seed'

tempname results
postfile `results' alpha2 alpha2_estimate using Results/bootstrap_`batch'.dta, replace

forvalues iter = 1/500 {
	
	clear
	set obs 95

	gen bvil = _n

	gen vil = ceil(runiform()*95)
	replace vil = 96 if vil==79

	merge m:m vil using Data/SuriPanel_extended_forbs.dta

	keep if _merge==3
	drop _merge
	
	drop vil
	rename bvil vil
	
	capture drop hhid2
	egen hhid2 = group(vil hhid)
	drop hhid
	rename hhid2 hhid

	do Code/testdist.do
	post `results' (alpha2) (`alpha2_estimate')
		
}	
postclose `results'
log close
