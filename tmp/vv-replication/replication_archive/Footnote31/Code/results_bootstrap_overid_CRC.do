use Results/bootstrap_1.dta, clear
forvalues batch = 2/20 {
capture append using Results/bootstrap_`batch'.dta
}

*Obtain F-stat from actual data (stored in scalar F)
do overid_CRC_estimates.do
scalar F_estimate = F

su F
local N = r(N)

su F if F>F_estimate
local n = r(N)

local pvalue = `n'/`N'
di `pvalue'
