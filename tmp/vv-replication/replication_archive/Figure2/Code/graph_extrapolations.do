set scheme plotplainblind

*NON-ROBUST

*Average baseline for stayers
*	Run first step estimation to generate required variables
qui do Code/firststage_projection 1 4

*	Restrict sample to stayers who live in a village with at least one mover
capture drop has_switcher
egen has_switcher = sum(switcher), by(vil)
replace has_switcher = (has_switcher>0)

*	Calculate averages
duplicates drop hhid, force
forvalues per = 1/4 {
	su a if !switcher&hybrid`per'==0&has_switcher
	local stayera`per'=r(mean)
}

*Extrapolation line

*	First step
qui do Code/firststage_projection 1 4

*	Keep movers only
drop if !switcher
drop if a==.
drop if return==.
duplicates drop hhid, force

*	2SLS and GMM estimation

local epsilon (a-{alpha0}-{alpha1}*return)

forvalues per=1/4 {
	gen hybrid`per'_filled = hybrid`per'
	replace hybrid`per'_filled = 0 if hybrid`per'_filled ==.
}

local mc_step1 `epsilon'
forvalues per=1/4 {
	local mc_step1 `mc_step1' (hybrid`per'_filled*`epsilon')
}

capture drop ones
gen ones=1
putmata Z = (ones hybrid*_filled), replace
mata
Winit = invsym(Z'*Z)
st_matrix("Winit",Winit)
end

gmm `mc_step1', winitial(Winit)  vce(cluster vil) onestep
ivregress 2sls a (return=hybrid*_filled)
matrix bhat=e(b)
scalar alpha1_2sls=bhat[1,1]
scalar alpha0_2sls=bhat[1,2]
gmm `mc_step1', winitial(Winit)  vce(cluster vil) wmatrix(cluster vil)
matrix bhat=e(b)
scalar alpha1=bhat[1,2]
scalar alpha0=bhat[1,1]

*Average baseline and ATE for movers
forvalues per = 1/4 {
	forvalues h = 0/1 {
		foreach var in a return {
			su `var' if hybrid`per'==`h'
			local mean`var'_`per'_`h' = r(mean)	
			local N`var'_`per'_`h' = r(N)	
		}
	}
} 

*Non-Robust graph

clear
set obs 8
gen year=.
gen hybrid=.
gen a=.
gen return=.
gen N=.

local count=1
forvalues per = 1/4 {
	forvalues h = 0/1 {
		replace year=`per' in `count'
		replace hybrid=`h' in `count'
		foreach var in a return {
			replace `var' = `mean`var'_`per'_`h'' in `count'
			replace N = `N`var'_`per'_`h'' in `count'
		}
		local count=`count'+1
	}
} 
su
local Nold=r(N)
local Nnew = `Nold' + 101

set obs `Nnew'

replace a = 4.6+(_n-`Nold'-1)*.4/100 if a==.

gen extrapolation_line =   -alpha0/alpha1+a/alpha1
gen extrapolation_line_2sls =   -alpha0_2sls/alpha1_2sls+a/alpha1_2sls

twoway (scatter return a if year==1&hybrid==0, sort msymbol(circle)) (scatter return a if year==1&hybrid==1, sort msymbol(circle)) (scatter return a if year==2&hybrid==0, sort msymbol(circle)) (scatter return a if year==2&hybrid==1, sort msymbol(circle)) (scatter return a if year==3&hybrid==0, sort msymbol(circle)) (scatter return a if year==3&hybrid==1, sort msymbol(circle)) (scatter return a if year==4&hybrid==0, sort msymbol(circle)) (scatter return a if year==4&hybrid==1, sort msymbol(circle))  (line extrapolation_line a , sort lcolor(gray)) (line extrapolation_line_2sls a, sort ) (scatteri -.2 `stayera1' 1 `stayera1', recast(line)  lpattern(solid) lcolor(sky%50)) (scatteri -.2 `stayera2' 1 `stayera2', recast(line)  lpattern(solid) lcolor(turquoise%50)   ) (scatteri -.2 `stayera3' 1 `stayera3', recast(line)    lpattern(solid) lcolor(orangebrown%50) ) (scatteri -.2 `stayera4' 1 `stayera4', recast(line)   lpattern(solid) lcolor(reddish%50)  ), yscale(range(-0.2 1)) ylabel(-0.2(.2)1)  legend(size(small) order(1 "1997 non-hybrid" 2 "1997 hybrid" 3 "2004 non-hybrid" 4 "2004 hybrid" 5 "2007 non-hybrid" 6 "2007 hybrid" 7 "2010 non-hybrid" 8 "2010 hybrid" 9 "extrapolation line (GMM)" 10 "extrapolation line (2SLS)" 11 "1997 untreated stayers" 12 "2004 untreated stayers" 13 "2007 untreated stayers" 14 "2010 untreated stayers") nobox position(6) c(3) region(lstyle(none))) ytitle("return",size(small)) xtitle("baseline heterogeneity",size(small))
graph export nrobust.pdf, replace


*ROBUST

*Extrapolation line
*	first-step
qui do Code/firststage_projection 1 4

*	second-step
drop if !switcher
drop if a==.
drop if return==.
duplicates drop hhid, force

*		FE-IV, so partial out FE from IV, and fill missing values with zero for computation
forvalues per=1/4 {
	qui reg hybrid`per' i.vil 
	predict hybrid`per'_filled_resid if hybrid`per'!=., resid
	replace hybrid`per'_filled_resid=0 if hybrid`per'_filled_resid==.
}

*		2SLS and GMM
local epsilon (a-{alpha1}*return)
local mc_step1
forvalues per=1/4 {
	local mc_step1 `mc_step1' (hybrid`per'_filled_resid*`epsilon')
}

putmata Z = (hybrid*_filled_resid), replace
mata
Winit = invsym(Z'*Z)
st_matrix("Winit",Winit)
end

gmm `mc_step1', winitial(Winit)  vce(cluster vil) onestep
*ivregress 2sls a (return=hybrid*_filled) i.vil
matrix bhat=e(b)
scalar alpha1_2sls=bhat[1,1]
gmm `mc_step1', winitial(Winit)  vce(cluster vil) wmatrix(cluster vil)
matrix bhat=e(b)
scalar alpha1=bhat[1,1]

*	baseline heterogeneity deviated from village-level factors
capture drop temp
gen temp = (a-alpha1*return)
qui reg temp i.vil 
capture drop temp
predict temp, xb
gen aresid = a-temp

*	Average deviated baseline heterogeneity and ATE for movers
forvalues per = 1/4 {
	forvalues h = 0/1 {
		foreach var in aresid return {
			*qui reg `var' i.vil if hybrid`per'!=.
			*capture drop `var'resid
			*predict `var'resid if hybrid`per'!=., resid
			*su `var'resid if hybrid`per'==`h'
			su `var' if hybrid`per'==`h'
*&per==`per'
			local mean`var'_`per'_`h' = r(mean)	
			local N`var'_`per'_`h' = r(N)	
		}
	}
} 

*Average deviated baseline heterogeneity for stayers

qui do Code/firststage_projection 1 4
duplicates drop hhid, force
capture drop has_switcher
egen has_switcher = sum(switcher), by(vil)
replace has_switcher = (has_switcher>0)

capture drop temp
gen temp = (a-alpha1*return)
qui reg temp i.vil if switcher
capture drop temp
predict temp if  has_switcher, xb
gen aresid = a-temp if  has_switcher

keep if !switcher&hybrid==0&has_switcher
forvalues per = 1/4 {
		foreach var in aresid {
			su `var' if hybrid`per'==0
			local stayera`per' = r(mean)	
		}
} 

*Graph for robust extrapolation

clear
set obs 8
gen year=.
gen hybrid=.
gen aresid=.
gen return=.
gen N=.

local count=1
forvalues per = 1/4 {
	forvalues h = 0/1 {
		replace year=`per' in `count'
		replace hybrid=`h' in `count'
		foreach var in aresid return {
			replace `var' = `mean`var'_`per'_`h'' in `count'
			replace N = `N`var'_`per'_`h'' in `count'
		}
		local count=`count'+1
	}
} 
su
local Nold=r(N)
local Nnew = `Nold' + 101

set obs `Nnew'

replace aresid = -.45+(_n-`Nold'-1)*.4/100 if aresid==.

gen extrapolation_line =   aresid/alpha1
gen extrapolation_line_2sls =   aresid/alpha1_2sls

rename return returnresid

twoway (scatter returnresid aresid if year==1&hybrid==0, sort msymbol(circle)) (scatter returnresid aresid if year==1&hybrid==1, sort msymbol(circle)) (scatter returnresid aresid if year==2&hybrid==0, sort msymbol(circle)) (scatter returnresid aresid if year==2&hybrid==1, sort msymbol(circle)) (scatter returnresid aresid if year==3&hybrid==0, sort msymbol(circle)) (scatter returnresid aresid if year==3&hybrid==1, sort msymbol(circle)) (scatter returnresid aresid if year==4&hybrid==0, sort msymbol(circle)) (scatter returnresid aresid if year==4&hybrid==1, sort msymbol(circle))  (line extrapolation_line aresid , sort lcolor(gray)) (line extrapolation_line_2sls aresid, sort ) (scatteri -.2 `stayera1' 1 `stayera1', recast(line)  lpattern(solid) lcolor(sky%50)) (scatteri -.2 `stayera2' 1 `stayera2', recast(line)  lpattern(solid) lcolor(turquoise%50)   ) (scatteri -.2 `stayera3' 1 `stayera3', recast(line)    lpattern(solid) lcolor(orangebrown%50) ) (scatteri -.2 `stayera4' 1 `stayera4', recast(line)   lpattern(solid) lcolor(reddish%50)  ), yscale(range(-0.2 1)) ylabel(-0.2(.2)1) xlabel(-.45(.1)-.05)  legend(size(small) order(1 "1997 non-hybrid" 2 "1997 hybrid" 3 "2004 non-hybrid" 4 "2004 hybrid" 5 "2007 non-hybrid" 6 "2007 hybrid" 7 "2010 non-hybrid" 8 "2010 hybrid" 9 "extrapolation line (GMM)" 10 "extrapolation line (2SLS)" 11 "1997 untreated stayers" 12 "2004 untreated stayers" 13 "2007 untreated stayers" 14 "2010 untreated stayers") nobox position(6) c(3) region(lstyle(none))) ytitle("return",size(small)) xtitle("baseline heterogeneity deviated from village-level factors",size(small))
graph export robust.pdf, replace



