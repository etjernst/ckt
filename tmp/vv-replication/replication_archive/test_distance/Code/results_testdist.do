use Results/bootstrap_1.dta, clear
forvalues batch = 2/20 {
capture append using Results/bootstrap_`batch'.dta
}

su alpha2
local se = r(sd)
su alpha2_estimate
local alpha2 = r(mean)

local pvalue = 2*normal(`alpha2'/`se')
di `pvalue'