
local start=`1'
local end=`2'

*Obtain weighting matrix and create resulting optimal instruments.

local epsilon (a-{alpha0}-{alpha1}*return)

local mc_step1 `epsilon'
forvalues per=`start'/`end' {
	local mc_step1 `mc_step1' (hybrid`per'*`epsilon')
}

gmm `mc_step1', winitial(identity) nocommonesample wmatrix(cluster vil) igmm 

matrix W=e(W)

local listIV
forvalues per=`start'/`end' {
	capture drop hybrid`per'IV
	gen hybrid`per'IV=hybrid`per'
	replace hybrid`per'IV=0 if hybrid`per'IV==.
	local listIV `listIV' hybrid`per'IV
}

capture drop x_IV
gen x_IV=return
replace x_IV=0 if return==.
capture drop ones_IV
gen ones_IV=1
replace ones_IV=0 if return==.

putmata z=(ones_IV `listIV'), replace
putmata x=(ones_IV x_IV), replace

mata
W=st_matrix("W")
z_opt=z*W*z'*x
end

getmata (z_opt1 z_opt2)=z_opt, replace

*	verify that indeed same results
gmm (z_opt1*`epsilon') (z_opt2*`epsilon'), vce(cluster vil) winitial(identity)
gmm `epsilon', instruments(z_opt1 z_opt2) vce(cluster vil) winitial(identity)

*Now estimate first and second steps jointly to obtain valid standard errors (could also have bootstrapped -- re-running both the first and second steps for each bootstrap draw --, clustering at the village-level).

*	Create partialled out dependent variable
capture drop temp1
capture drop temp2
egen temp1=mean(lyield), by(hhid_hybrid)
gen temp2=temp1 if !hybrid
capture drop yp1
egen yp1=mean(temp2), by(hhid)

capture drop temp2
gen temp2=temp1 if hybrid
capture drop yp2
egen yp2=mean(temp2), by(hhid)
replace yp2=yp2-yp1

*	number of covariates in first step
local nw=nw
forvalues var=1/`nw' {
	capture drop temp1
	capture drop temp2
	egen temp1=mean(w`var'), by(hhid_hybrid)
	gen temp2=temp1 if !hybrid
	capture drop wp1`var'
	egen wp1`var'=mean(temp2), by(hhid)
	capture drop temp2
	gen temp2=temp1 if hybrid
	capture drop wp2`var'
	egen wp2`var'=mean(temp2), by(hhid)
	replace wp2`var'=wp2`var'-wp1`var'
}

forvalues per=`start'/`end' {
	foreach var in yp1 yp2 {
		capture drop `var'd`per'
		gen `var'd`per'=`var' if !missing(hybrid`per')&switcher
	}
	foreach var2 in wp1 wp2 {
		forvalues i=1/`nw' {
			local var `var2'`i'
			capture drop `var'd`per'
			gen `var'd`per'=`var' if !missing(hybrid`per')&switcher
		}
	}
}

capture drop temp
egen temp=sum(switcher), by(vil)
gen has_switcher=(temp>0)

gen yp2_zeros=yp2
replace yp2_zeros=0 if yp2_zeros==.&never

*	number of covariates in first step
local nw=nw
forvalues var=1/`nw' {
	gen wp2`var'_zeros=wp2`var'
	replace wp2`var'_zeros=0 if wp2`var'_zeros==.&never
}

*	Joint estimation

*		starting values for first step
reg yd wd1-wd`nw', nocons
matrix b=e(b)

forvalues per=`start'/`end' {
	local a`per' yp1d`per'
	forvalues i=1/`nw' {
		local a`per' `a`per'' -{gamma`i'}*wp1`i'd`per'
	}
	local return`per' yp2d`per'
	forvalues i=1/`nw' {
		local return`per' `return`per'' -{gamma`i'}*wp2`i'd`per'
	}
	local epsilon`per' (`a`per''-{alpha0} -{alpha1}*(`return`per''))
}

local a yp1
forvalues i=1/`nw' {
	local a `a' -{gamma`i'}*wp1`i'
}
local return yp2
forvalues i=1/`nw' {
	local return `return' -{gamma`i'}*wp2`i'
}
local epsilon (`a' -{alpha0}-{alpha1}*(`return'))

local return_new yp2_zeros
forvalues i=1/`nw' {
	local return_new `return_new' -{gamma`i'}*wp2`i'_zeros
} 
local return_new (`return_new')

local return_new switcher*`return_new'+never*has_switcher*(`a'-{alpha0})/{alpha1}

local average (switcher*(`return_new'-{ATEs}))
local average `average' (never*has_switcher*(`return_new'-{ATEn}))
capture drop perd1-perd4
tab per, gen(perd)
forvalues per=1/4 {
	local average `average' (hybrid*perd`per'*(`return_new'-{ATEh`per'}))
	local average `average' ((1-hybrid)*switcher*perd`per'*(`return_new'-{ATEnh`per'}))
	local average `average' (hybrid*perd`per'*(`a'-{ah`per'}))
	local average `average' ((1-hybrid)*switcher*perd`per'*(`a'-{anh`per'}))
	local average `average' (never*has_switcher*perd`per'*(`return_new'-{ATEnever`per'}))
	local average `average' (never*has_switcher*perd`per'*(`a'-{anever`per'}))
}

local mf1 yd
forvalues i=1/`nw' {
	local mf1 `mf1' - {gamma`i'}*wd`i'
}
local mf1 (`mf1')

local step1
forvalues i=1/`nw' {
	local step1 `step1' (wd`i'*`mf1')
}

local mc `epsilon'
forvalues per=`start'/`end' {
	local mc `mc' (hybrid`per'*`epsilon`per'')
}

local overid (`epsilon'-{eta0})
forvalues per=`start'/`end' {
	local overid `overid' (hybrid`per'IV*`epsilon`per''-{eta`per'})
}

matrix starting=b
matrix starting=starting,0,-.5,J(1,31,0)

gmm `mf1' `epsilon' `average' `overid', instruments(1:wd1-wd`nw', nocons) instruments(2:z_opt1 z_opt2, nocons) vce(cluster vil) nocommonesample winitial(unadjusted, independent) from(starting) quickd onestep

local test [eta0]_cons
forvalues per=`start'/`end' {
	local test `test' [eta`per']_cons
}

test `test'
scalar chi2=r(chi2)
local Tm1=`end'-`start'
scalar pvalue=chi2tail(`Tm1',chi2)
di pvalue

save Data/results_nrobust.dta, replace
*end
