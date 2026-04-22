

*argument 1 is start year and argument 2 is end year
local start_year=`1'
local end_year=`2'

local year1 1997
local year2 2004
local year3 2007
local year4 2010

local listyear

forvalues i=`start_year'/`end_year' {
	local listyear `listyear' `year`i''
}

*Keep years corresponding to desired period of observation
capture drop todrop
gen todrop=1
foreach year in `listyear' {
	replace todrop=0 if year==`year'
}
drop if todrop

*Drop high HIV districts
drop if dist=="siaya"|dist=="kisumu"

*Create dependent variable
gen lyield=log(kg_harv/acres)
drop if lyield==.

*Create explanatory variable (strictly positive quantity purchased of hybrid seed as in Suri)
drop if hybrid_purch==.
drop hybrid
gen hybrid=(hybrid_purch>0)

*Recode geographical indicators
drop if prov==""
encode prov, gen(prov2)
drop prov
rename prov2 prov

drop if dist==""
encode dist, gen(dist2)
drop dist
rename dist2 dist

*No duplicates
duplicates report hhid year

*Keep cross-sectional observations if at least two time periods observed 
gen ones=1
egen count=sum(ones), by(hhid)
keep if count>=2

*Define switchers
capture drop temp1
capture drop temp2
egen temp1=max(hybrid), by(hhid)
egen temp2=min(hybrid), by(hhid)
gen switcher=(temp1!=temp2)

gen always=(temp1==temp2&temp2==1)
gen never=(temp1==temp2&temp2==0)

unique hhid
unique hhid if switcher

sort hhid year

*Create time period variable (instead of year, so that increments are one)
local per=1
gen per=.
foreach year in `listyear' {
	replace per=`per' if year==`year'
	local per=`per'+1
}
local nper=`per'-1

xtset hhid per

*create list of covariates
tab prov, gen(provd)
local count=1
capture drop ones
gen ones=1
foreach var in acres seedkg lpcost totfertexp hiredlabor_S familylabor_S main hhsize boys girls oldermen women {
	forvalues per=1/`nper' {
		capture drop w`count'
		gen w`count'=`var'*(per==`per')
		local count=`count'+1
	}
}

foreach var in provd1 provd2 provd3 provd4 provd5 provd6 {
	capture confirm variable `var'
	local temp = _rc
	if `temp'==0 {
		local nperm1=`nper'-1
		forvalues per=1/`nperm1' {
			capture drop w`count'
			gen w`count'=`var'*(per==`per')
			local count=`count'+1
		}
	}
}


local count=`count'-1
di `count'
scalar nw=`count'

*Chamberlain 1992 regression (with homoscedastic weights instead of semiparametric efficient estimator)

*Make sure two methods are identical (the second one is more convenient for inference)
capture drop hhid_hybrid
gen hhid_hybrid=hhid*10+hybrid
areg lyield w1-w`count', absorb(hhid_hybrid)

capture drop yresid
predict yresid if hhid_hybrid!=., dresiduals

capture drop temp
predict temp, d

capture drop temp1
capture drop temp2
gen temp1=temp if hybrid
egen temp2=mean(temp1), by(hhid)
gen apb=temp2

capture drop temp1
capture drop temp2
gen temp1=temp if !hybrid
egen temp2=mean(temp1), by(hhid)
gen a=temp2

gen return1=apb-a if switcher
gen a1=a if never|switcher
gen apb1=apb if always|switcher

capture drop return
capture drop a
capture drop apb
rename return1 return
rename a1 a
rename apb1 apb

forvalues per=1/`nper' {
	gen hybrid`per'=hybrid if per==`per'
	capture drop temp
	egen temp=max(hybrid`per'), by(hhid)
	replace hybrid`per'=temp
}

