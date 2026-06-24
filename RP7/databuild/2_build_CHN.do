/*******************************************************************************
Returns to Migration --- data-construction pipeline
2_build_CHN.do

Builds CHN.dta (China analysis input) from the LMMVW replication output and the
raw CFPS adult waves.

Input:  inputs/chn_panel.dta              (LMMVW build output)
        inputs/ecfps2010adult_202008.dta  (raw CFPS wave 1, for experience)
        inputs/ecfps2012adult_201906.dta  (raw CFPS wave 2)
        inputs/ecfps2014adult_201906.dta  (raw CFPS wave 3)
        inputs/ecfps2016adult_201906.dta  (raw CFPS wave 4)
Output: output/CHN.dta
        output/_intermediate/Panel_LMMVW_CHN.dta  (stage A intermediate)

Stage A transcribes the LMMVW China variable selection; stage B transcribes the
experience construction and assembly. Both verbatim from the team's do-files;
only paths and organization changed. Consumption and income are nominal.
*******************************************************************************/

clear all
set more off
do 0_databuild_paths.do

********************************************************************************
*** Stage A: select and rename variables from the LMMVW China panel
********************************************************************************
*** Open main panel provided by LMMVW in replication package
use "$inputs/chn_panel", clear

drop if pid == .

cap unique pid

tab year, m

*** Select which variables to keep
keep pid wave hukou urban switcher age female educ cid provcd countyid year marriage hhsize nadult birth_province birth_county consumption earnings food

*** Rename variables

lab var pid "unique identifier for each person in the survey"

rename wave period
lab var period "period of reference for the data (number of each survey round/wave)"

lab var urban "dummy = 1 if current location is urban"

rename switcher switcherru
lab var switcherru "dummy = 1 if ever switched between rural and urban"

lab var age "age in years"

lab var female "dummy = 1 if female"

rename educ education
lab var education "formal education attained (years of schooling)"

g location = provcd
lab var location "current location (province)"

g strlocation = "."
tostring cid, format(%06.0f) gen(strcommunity)
tostring provcd, gen(strprovince)
tostring countyid, format(%04.0f) gen(strcounty)
replace strlocation = strprovince + "0" + strcounty + "0" + strcommunity if cid != . & cid != -9 & provcd != . & provcd != -9 & countyid != . & countyid != -9												// a value of -9 means the cid, provcd, or countyid is missing
destring strlocation, gen(location_detail)
drop strlocation strcommunity strprovince strcounty
lab var location_detail "current location (province-county-community)"
cap unique location
cap unique location_detail

xtset pid period
g migrant = .
replace migrant = location_detail != l.location_detail if location_detail != . & l.location_detail != .
lab var migrant "dummy = 1 if migrant (location in t != location in t-1)"

lab var year "calendar year"

g married = .
replace married = 1 if marriage == 2
replace married = 0 if marriage == 1 | marriage == 3 | marriage == 4 | marriage == 5		// married = 0 if marriage is "never married", "cohabitation", "divorced", or "widowed"
lab var married "dummy = 1 if married"
lab def married_lab 0 "Not Married" 1 "Married"
lab val married married_lab
drop marriage

lab var hhsize "number of HH members (total size)"

rename nadult hhadults
lab var hhadults "number of HH members age >= 16"

g hhchildren = hhsize - hhadults
lab var hhchildren "number of HH members age < 16"
sum hhchildren
list if hhchildren == -1														// 2 observations with hhchildren == -1

g strlocationbirth = "."
tostring birth_province, gen(strbirth_province)
tostring birth_county, format(%04.0f) gen(strbirth_county)
replace strlocationbirth = strbirth_province + "0" + strbirth_county if birth_province >= 0 & birth_province != . & birth_county != .		// values below 0 for birth_province mean that it's not applicable
destring strlocationbirth, gen(locationbirth)
drop strlocationbirth strbirth_province strbirth_county
lab var locationbirth "birth location (province-county)"

lab var consumption "total family consumption"

rename earnings income
lab var income "annual personal income (from 2010)"

rename food consfood
lab var consfood "consumption of food items"

g consnonfood = consumption - consfood
lab var consnonfood "consumption of non-food items"
sum consnonfood

order pid period hukou urban switcherru age female education location location_detail provcd countyid cid migrant year married hhsize hhadults hhchildren locationbirth birth_province birth_county consumption income consfood consnonfood

save "$output/_intermediate/Panel_LMMVW_CHN", replace

********************************************************************************
*** Stage B: build experience from raw CFPS and assemble CHN.dta
********************************************************************************

* load in raw data from wave 1 to create experience variable
use "$inputs/ecfps2010adult_202008", replace
keep pid cyear qa1y qg101_a_2 qg102_a_2 qg101_a_3 qg102_a_3 qg101_a_4 qg102_a_4 qg311 qh409a qg101_a_56 qg102_a_56
g start_productionjob = .														// All start and end years in raw data for the types of work below are 1900 or higher
replace start_productionjob = qg101_a_2 if qg101_a_2 >= 1900 & qg101_a_2 != .
g end_productionjob = .
replace end_productionjob = qg102_a_2 if start_productionjob != . & qg102_a_2 >= 1900 & qg102_a_2 != .
replace start_productionjob = . if end_productionjob == .						// Only keep starting year if we know end year (if job is currently held we still know "end" year)
g start_laborcamp = .
replace start_laborcamp = qg101_a_3 if qg101_a_3 >= 1900 & qg101_a_3 != .
g end_laborcamp = .
replace end_laborcamp = qg102_a_3 if start_laborcamp != . & qg102_a_3 >= 1900 & qg102_a_3 != .
replace start_laborcamp = . if end_laborcamp == .
g start_army = .
replace start_army = qg101_a_4 if qg101_a_4 >= 1900 & qg101_a_4 != .
g end_army = .
replace end_army = qg102_a_4 if start_army != . & qg102_a_4 >= 1900 & qg102_a_4 != .
replace start_army = . if end_army == .
g start_currentjob = .
replace start_currentjob = qg311 if qg311 >= 1900 & qg311 != .
g end_currentjob = .
replace end_currentjob = 2010 if start_currentjob != .
g start_nonagjob = .
replace start_nonagjob = qh409a if qh409a >= 1900 & qh409a != .
g end_nonagjob = .
replace end_nonagjob = 2010 if start_nonagjob != .
g start_otherjob = .
replace start_otherjob = qg101_a_56 if qg101_a_56 >= 1900 & qg101_a_56 != .
g end_otherjob = .
replace end_otherjob = qg102_a_56 if start_otherjob != . & qg102_a_56 >= 1900 & qg102_a_56 != .
replace start_otherjob = . if end_otherjob == .
foreach i of numlist 1900/2010 {												// Construct indicator vars for 1900 to 2010 telling whether respondent was at least 16 and worked in that year. Value is missing if respondent wasn't 16 yet
	g worked_`i' = .
	replace worked_`i' = 0 if `i' >= qa1y + 16
	foreach job in productionjob laborcamp army currentjob nonagjob otherjob {
		replace worked_`i' = 1 if start_`job' != . & end_`job' != . & start_`job' <= `i' & end_`job' >= `i' & `i' >= qa1y + 16
	}
}
egen exp_2010_w1 = rowtotal(worked_1900-worked_2010)							// Number of years we know respondent worked since turning 16 until 2010
egen elig_years_2010_w1 = anycount(worked_1900-worked_2010), values(0 1)		// Number of years since respondent turned 16 until 2010
rename worked_2010 worked_2010_w1
keep pid worked_2010_w1 exp_2010_w1 elig_years_2010_w1
tempfile CHN_exp_w1
save `CHN_exp_w1'

* load in raw data from wave 2 to create experience variable
use "$inputs/ecfps2012adult_201906", replace
keep pid cyear cfps2012_birthy_best cfps2012_age qg4121y_a_1 qg4122y_a_1 qg4121y_a_2 qg4122y_a_2 qg4121y_a_3 qg4122y_a_3 qg4121y_a_4 qg4122y_a_4 qg4121y_a_5 qg4122y_a_5 qg4121y_a_6 qg4122y_a_6 qg4121y_a_7 qg4122y_a_7 qg4121y_a_8 qg4122y_a_8 qg4121y_a_9 qg4122y_a_9 qg4121y_a_10 qg4122y_a_10 qg5101y_a_1 qg5102y_a_1 qg5101y_a_2 qg5102y_a_2 qg5101y_a_3 qg5102y_a_3 qg5101y_a_4 qg5102y_a_4 qa901 qa902 qg6101y_a_1 qg6102y_a_1 qg6101y_a_2 qg6102y_a_2 qg6101y_a_3 qg6102y_a_3 qg6101y_a_4 qg6102y_a_4 qg6101y_a_5 qg6102y_a_5 qg6101y_a_6 qg6102y_a_6 qg6101y_a_7 qg6102y_a_7 qg6101y_a_8 qg6102y_a_8
replace cfps2012_birthy_best = cyear - cfps2012_age if cfps2012_birthy_best < 0		// Fix the one missing birth year
foreach i of numlist 1/10 {
	g start_job`i' = .
	replace start_job`i' = qg4121y_a_`i' if qg4121y_a_`i' >= 1900 & qg4121y_a_`i' != .	// Wave 2 asks about start and end years for up to 10 wage jobs. All actual years in the responses are >= 1900
	g end_job`i' = .
	replace end_job`i' = qg4122y_a_`i' if qg4122y_a_`i' >= 1900 & qg4122y_a_`i' != .
	replace start_job`i' = . if end_job`i' == .									// Only keep starting year if we know end year (if job is currently held we still know "end" year)
}
foreach i of numlist 1/4 {
	g start_business`i' = .														// Wave 2 asks about start and end years for up to 4 own businesses
	replace start_business`i' = qg5101y_a_`i' if qg5101y_a_`i' >= 1900 & qg5101y_a_`i' != .
	g end_business`i' = .
	replace end_business`i' = qg5102y_a_`i' if qg5102y_a_`i' >= 1900 & qg5102y_a_`i' != .
	replace start_business`i' = . if end_business`i' == .
}
g start_military = .
replace start_military = qa901 if qa901 >= 1900 & qa901 != .
g end_military = .
replace end_military = qa902 if qa902 >= 1900 & qa902 != .
replace start_military = . if end_military == .
foreach i of numlist 1/8 {
	g start_fambusiness`i' = .													// Wave 2 asks about start and end years for unpaid help of up to 8 family businesses
	replace start_fambusiness`i' = qg6101y_a_`i' if qg6101y_a_`i' >= 1900 & qg6101y_a_`i' != .
	g end_fambusiness`i' = .
	replace end_fambusiness`i' = qg6102y_a_`i' if qg6102y_a_`i' >= 1900 & qg6102y_a_`i' != .
	replace start_fambusiness`i' = . if end_fambusiness`i' == .
}
g start_mainjob2012 = .															// Construct start and end year of "main job" in 2012 since this will be needed for wave 3 experience variable
g end_mainjob2012 = .
foreach job in job1 job2 job3 job4 job5 job6 job7 job8 job9 job10 business1 business2 business3 business4 military fambusiness1 fambusiness2 fambusiness3 fambusiness4 fambusiness5 fambusiness6 fambusiness7 fambusiness8 {
	replace end_mainjob2012 = end_`job' if end_`job' != . & (end_mainjob2012 == . | end_`job' >= end_mainjob2012)	// Main job in CFPS is defined as job that was most recently held (this will be used for wave 3 experience variable)
}
foreach job in job1 job2 job3 job4 job5 job6 job7 job8 job9 job10 business1 business2 business3 business4 military fambusiness1 fambusiness2 fambusiness3 fambusiness4 fambusiness5 fambusiness6 fambusiness7 fambusiness8 {
	replace start_mainjob2012 = start_`job' if end_mainjob2012 != . & end_`job' == end_mainjob2012 & (start_mainjob2012 == . | start_`job' <= start_mainjob2012)	// If multiple jobs share most recent end year, use the one that had the earliest start year
}
foreach i of numlist 1900/2012 {												// Construct indicator vars for 1900 to 2012 telling whether respondent was at least 16 and worked in that year. Value is missing if respondent wasn't 16 yet
	g worked_`i' = .
	replace worked_`i' = 0 if `i' >= cfps2012_birthy_best + 16 & cfps2012_birthy_best >= 1900
	foreach job in job1 job2 job3 job4 job5 job6 job7 job8 job9 job10 business1 business2 business3 business4 military fambusiness1 fambusiness2 fambusiness3 fambusiness4 fambusiness5 fambusiness6 fambusiness7 fambusiness8 {
	replace worked_`i' = 1 if start_`job' != . & end_`job' != . & start_`job' <= `i' & end_`job' >= `i' & `i' >= cfps2012_birthy_best + 16 & cfps2012_birthy_best >= 1900
	}
}
egen exp_2010_w2 = rowtotal(worked_1900-worked_2010)							// Number of years we know respondent worked since turning 16 until 2010
egen elig_years_2010_w2 = anycount(worked_1900-worked_2010), values(0 1)		// Number of years since respondent turned 16 until 2010
egen exp_2012_w2 = rowtotal(worked_1900-worked_2012)							// Number of years we know respondent worked since turning 16 until 2012
egen elig_years_2012_w2 = anycount(worked_1900-worked_2012), values(0 1)		// Number of years since respondent turned 16 until 2012
rename (worked_2010 worked_2012) (worked_2010_w2 worked_2012_w2)
keep pid worked_2010_w2 worked_2012_w2 exp_2010_w2 elig_years_2010_w2 exp_2012_w2 elig_years_2012_w2 start_mainjob2012 end_mainjob2012
tempfile CHN_exp_w2
save `CHN_exp_w2'

* load in raw data from wave 3 to create experience variable
use "$inputs/ecfps2014adult_201906", replace
keep pid cyear cfps_birthy egc2012y_a_1 egc2013y_a_1 egc2013c_a_1 egc2012y_a_2 egc2013y_a_2 egc2013c_a_2 egc2012y_a_3 egc2013y_a_3 egc2013c_a_3 egc2012y_a_4 egc2013y_a_4 egc2013c_a_4 egc2012y_a_5 egc2013y_a_5 egc2013c_a_5 egc104y egc104c egc103 egc1052y egc1053y egc1053c
merge 1:1 pid using `CHN_exp_w2'												// Merge in start and end years of 2012 main job
drop if _merge == 2
replace end_mainjob2012 = 2014 if egc104c == 1									// Update end year of main job from wave 2 to be 2014 if they still hold that job
replace end_mainjob2012 = egc104y if egc104y >= end_mainjob2012 & egc104y != .	// Update end year of main job from wave 2 to be end year reported in wave 3 for that job
g start_primaryjob = .
replace start_primaryjob = egc1052y if egc1052y >= 1900 & egc1052y != .
g end_primaryjob = .
replace end_primaryjob = 2014 if egc1053c == 1									// Set end year of primary job to 2014 if they still hold the job, otherwise set end year as reported end year below
replace end_primaryjob = egc1053y if egc1053y >= 1900 & egc1053y != . & egc1053y >= end_primaryjob
replace start_primaryjob = . if end_primaryjob == .
foreach i of numlist 1/5 {														// Start and end years of 5 other jobs are reported
	g start_otherjob`i' = .
	replace start_otherjob`i' = egc2012y_a_`i' if egc2012y_a_`i' >= 1900 & egc2012y_a_`i' != .
	g end_otherjob`i' = .
	replace end_otherjob`i' = 2014 if egc2013c_a_`i' == 1
	replace end_otherjob`i' = egc2013y_a_`i' if egc2013y_a_`i' >= 1900 & egc2013y_a_`i' != . & egc2013y_a_`i' >= end_otherjob`i'
	replace start_otherjob`i' = . if end_otherjob`i' == .
}
g start_mainjob2014 = .															// Construct start and end year of "main job" in 2014 since this will be needed for wave 4 experience variable
g end_mainjob2014 = .
foreach job in mainjob2012 primaryjob otherjob1 otherjob2 otherjob3 otherjob4 otherjob5 {
	replace end_mainjob2014 = end_`job' if end_`job' != . & (end_mainjob2014 == . | end_`job' >= end_mainjob2014)	// Main job in CFPS is defined as job that was most recently held (this will be used for wave 4 experience variable)
}
foreach job in mainjob2012 primaryjob otherjob1 otherjob2 otherjob3 otherjob4 otherjob5 {
	replace start_mainjob2014 = start_`job' if end_mainjob2014 != . & end_`job' == end_mainjob2014 & (start_mainjob2014 == . | start_`job' <= start_mainjob2014)	// If multiple jobs share most recent end year, use the one that had the earliest start year
}
foreach i of numlist 1900/2014 {												// Construct indicator vars for 1900 to 2014 telling whether respondent was at least 16 and worked in that year. Value is missing if respondent wasn't 16 yet
	g worked_`i' = .
	replace worked_`i' = 0 if `i' >= cfps_birthy + 16 & cfps_birthy != .
	foreach job in mainjob2012 primaryjob otherjob1 otherjob2 otherjob3 otherjob4 otherjob5 {
		replace worked_`i' = 1 if start_`job' != . & end_`job' != . & start_`job' <= `i' & end_`job' >= `i' & `i' >= cfps_birthy + 16 & cfps_birthy != .
	}
}
egen exp_2010_w3 = rowtotal(worked_1900-worked_2010)							// Number of years we know respondent worked since turning 16 until 2010
egen elig_years_2010_w3 = anycount(worked_1900-worked_2010), values(0 1)			// Number of years since respondent turned 16 until 2010
egen exp_2012_w3 = rowtotal(worked_1900-worked_2012)							// Number of years we know respondent worked since turning 16 until 2012
egen elig_years_2012_w3 = anycount(worked_1900-worked_2012), values(0 1)		// Number of years since respondent turned 16 until 2012
egen exp_2014_w3 = rowtotal(worked_1900-worked_2014)							// Number of years we know respondent worked since turning 16 until 2014
egen elig_years_2014_w3 = anycount(worked_1900-worked_2014), values(0 1)		// Number of years since respondent turned 16 until 2014
rename (worked_2010 worked_2012 worked_2014) (worked_2010_w3 worked_2012_w3 worked_2014_w3)
keep pid worked_2010_w3 worked_2012_w3 worked_2014_w3 exp_2010_w3 elig_years_2010_w3 exp_2012_w3 elig_years_2012_w3 exp_2014_w3 elig_years_2014_w3 start_mainjob2014 end_mainjob2014
tempfile CHN_exp_w3
save `CHN_exp_w3'

* load in raw data from wave 4 to create experience variable
use "$inputs/ecfps2016adult_201906", replace
keep pid cyear cfps_birthy cfps_age egc101 egc104y egc104c egc103 egc1052y egc1053y egc1053c egc2012y_a_1 egc2012y_a_2 egc2012y_a_3 egc2012y_a_4 egc2012y_a_5 egc2012y_a_6 egc2012y_a_7 egc2012y_a_8 egc2012y_a_9 egc2012y_a_10 egc2013y_a_1 egc2013y_a_2 egc2013y_a_3 egc2013y_a_4 egc2013y_a_5 egc2013y_a_6 egc2013y_a_7 egc2013y_a_8 egc2013y_a_9 egc2013y_a_10 egc2013c_a_1 egc2013c_a_2 egc2013c_a_3 egc2013c_a_4 egc2013c_a_5 egc2013c_a_6 egc2013c_a_7 egc2013c_a_8 egc2013c_a_9 egc2013c_a_10
replace cfps_birthy = cyear - cfps_age if cfps_birthy < 0						// Fix missing birth years where possible using age
merge 1:1 pid using `CHN_exp_w3'												// Merge in start and end years of 2014 main job
drop if _merge == 2
replace end_mainjob2014 = 2016 if egc104c == 1									// Update end year of main job from wave 3 to be 2016 if they still hold that job
replace end_mainjob2014 = egc104y if egc104y >= end_mainjob2014 & egc104y != .	// Update end year of main job from wave 3 to be end year reported in wave 4 for that job
g start_primaryjob = .
replace start_primaryjob = egc1052y if egc1052y >= 1900 & egc1052y != .
g end_primaryjob = .
replace end_primaryjob = 2016 if egc1053c == 1									// Set end year of primary job to 2016 if they still hold the job, otherwise set end year as reported end year below
replace end_primaryjob = egc1053y if egc1053y >= 1900 & egc1053y != . & egc1053y >= end_primaryjob
replace start_primaryjob = . if end_primaryjob == .
foreach i of numlist 1/10 {														// Start and end years of 10 other jobs are reported
	g start_otherjob`i' = .
	replace start_otherjob`i' = egc2012y_a_`i' if egc2012y_a_`i' >= 1900 & egc2012y_a_`i' != .
	g end_otherjob`i' = .
	replace end_otherjob`i' = 2016 if egc2013c_a_`i' == 1
	replace end_otherjob`i' = egc2013y_a_`i' if egc2013y_a_`i' >= 1900 & egc2013y_a_`i' != . & egc2013y_a_`i' >= end_otherjob`i'
	replace start_otherjob`i' = . if end_otherjob`i' == .
}
foreach i of numlist 1900/2016 {												// Construct indicator vars for 1900 to 2016 telling whether respondent was at least 16 and worked in that year. Value is missing if respondent wasn't 16 yet
	g worked_`i' = .
	replace worked_`i' = 0 if `i' >= cfps_birthy + 16 & cfps_birthy >= 1900
	foreach job in mainjob2014 primaryjob otherjob1 otherjob2 otherjob3 otherjob4 otherjob5 otherjob6 otherjob7 otherjob8 otherjob9 otherjob10 {
		replace worked_`i' = 1 if start_`job' != . & end_`job' != . & start_`job' <= `i' & end_`job' >= `i' & `i' >= cfps_birthy + 16 & cfps_birthy >= 1900
	}
}
egen exp_2010_w4 = rowtotal(worked_1900-worked_2010)							// Number of years we know respondent worked since turning 16 until 2010
egen elig_years_2010_w4 = anycount(worked_1900-worked_2010), values(0 1)		// Number of years since respondent turned 16 until 2010
egen exp_2012_w4 = rowtotal(worked_1900-worked_2012)							// Number of years we know respondent worked since turning 16 until 2012
egen elig_years_2012_w4 = anycount(worked_1900-worked_2012), values(0 1)		// Number of years since respondent turned 16 until 2012
egen exp_2014_w4 = rowtotal(worked_1900-worked_2014)							// Number of years we know respondent worked since turning 16 until 2014
egen elig_years_2014_w4 = anycount(worked_1900-worked_2014), values(0 1)		// Number of years since respondent turned 16 until 2014
egen exp_2016_w4 = rowtotal(worked_1900-worked_2016)							// Number of years we know respondent worked since turning 16 until 2016
egen elig_years_2016_w4 = anycount(worked_1900-worked_2016), values(0 1)		// Number of years since respondent turned 16 until 2016
rename (worked_2010 worked_2012 worked_2014) (worked_2010_w4 worked_2012_w4 worked_2014_w4)
keep pid worked_2010_w4 worked_2012_w4 worked_2014_w4 worked_2016 exp_2010_w4 elig_years_2010_w4 exp_2012_w4 elig_years_2012_w4 exp_2014_w4 elig_years_2014_w4 exp_2016_w4 elig_years_2016_w4
tempfile CHN_exp_w4
save `CHN_exp_w4'

* load replication data (prepared by David) and save as it is
use "$output/_intermediate/Panel_LMMVW_CHN", clear

* create maximum education level within all periods
sort pid period
by pid: egen education_max = max(education)
label var education_max "time-invariant highest years of education for individual"

* create time-invariant variable for age in the year of the first survey wave (2010)
g year_temp = year
replace year_temp = . if age == .
egen first_year = min(year_temp), by(pid)
egen age2010 = total((age - (first_year - 2010)) * (year == first_year)), by(pid)
lab var age2010 "age in 2010"
	drop year_temp first_year

* merge in experience variables
merge m:1 pid using `CHN_exp_w1'
drop if _merge == 2
drop _merge
merge m:1 pid using `CHN_exp_w2'
drop if _merge == 2
drop _merge
merge m:1 pid using `CHN_exp_w3'
drop if _merge == 2
drop _merge
merge m:1 pid using `CHN_exp_w4'
drop if _merge == 2

sort pid period
egen worked_2010 = rowmax(worked_2010_w1 worked_2010_w2 worked_2010_w3 worked_2010_w4)
egen worked_2012 = rowmax(worked_2012_w2 worked_2012_w3 worked_2012_w4)
egen worked_2014 = rowmax(worked_2014_w3 worked_2014_w4)

* create employment indicator
g empl = .
replace empl = worked_2010 if year == 2010
replace empl = worked_2012 if year == 2012
replace empl = worked_2014 if year == 2014
replace empl = worked_2016 if year == 2016
lab var empl "empoyment indicator for year of observation"

g exp = .																		// This will be time-varying years of experience since age 16 until year of observation. The wave that gives us the highest number of years of experience up to the year of observation will be used'
g exp_share = .																	// This will be the share of years worked since age 16 until year of observation. The wave that gives us the highest number of years of experience up to the year of observation will be used for the share of years worked as well

replace exp = exp_2010_w1 if exp_2010_w1 != .
replace exp_share = exp_2010_w1 / (elig_years_2010_w1 + (year - 2010)) if exp_2010_w1 != .
replace exp = exp_2010_w2 if exp_2010_w2 != . & (exp_2010_w2 >= exp | exp == .)
replace exp_share = exp_2010_w2 / (elig_years_2010_w2 + (year - 2010)) if exp_2010_w2 != . & (exp_2010_w2 >= exp | exp == .)
replace exp = exp_2010_w3 if exp_2010_w3 != . & (exp_2010_w3 >= exp | exp == .)
replace exp_share = exp_2010_w3 / (elig_years_2010_w3 + (year - 2010)) if exp_2010_w3 != . & (exp_2010_w3 >= exp | exp == .)
replace exp = exp_2010_w4 if exp_2010_w4 != . & (exp_2010_w4 >= exp | exp == .)
replace exp_share = exp_2010_w4 / (elig_years_2010_w4 + (year - 2010)) if exp_2010_w4 != . & (exp_2010_w4 >= exp | exp == .)

replace exp = exp_2012_w2 if year >= 2012 & exp_2012_w2 != . & (exp_2012_w2 >= exp | exp == .)
replace exp_share = exp_2012_w2 / (elig_years_2012_w2 + (year - 2012)) if year >= 2012 & exp_2012_w2 != . & (exp_2012_w2 >= exp | exp == .)
replace exp = exp_2012_w3 if year >= 2012 & exp_2012_w3 != . & (exp_2012_w3 >= exp | exp == .)
replace exp_share = exp_2012_w3 / (elig_years_2012_w3 + (year - 2012)) if year >= 2012 & exp_2012_w3 != . & (exp_2012_w3 >= exp | exp == .)
replace exp = exp_2012_w4 if year >= 2012 & exp_2012_w4 != . & (exp_2012_w4 >= exp | exp == .)
replace exp_share = exp_2012_w4 / (elig_years_2012_w4 + (year - 2012)) if year >= 2012 & exp_2012_w4 != . & (exp_2012_w4 >= exp | exp == .)

replace exp = exp_2014_w3 if year >= 2014 & exp_2014_w3 != . & (exp_2014_w3 >= exp | exp == .)
replace exp_share = exp_2014_w3 / (elig_years_2014_w3 + (year - 2014)) if year >= 2014 & exp_2014_w3 != . & (exp_2014_w3 >= exp | exp == .)
replace exp = exp_2014_w4 if year >= 2014 & exp_2014_w4 != . & (exp_2014_w4 >= exp | exp == .)
replace exp_share = exp_2014_w4 / (elig_years_2014_w4 + (year - 2014)) if year >= 2014 & exp_2014_w4 != . & (exp_2014_w4 >= exp | exp == .)

replace exp = exp_2016_w4 if year >= 2016 & exp_2016_w4 != . & (exp_2016_w4 >= exp | exp == .)
replace exp_share = exp_2016_w4 / (elig_years_2016_w4 + (year - 2016)) if year >= 2016 & exp_2016_w4 != . & (exp_2016_w4 >= exp | exp == .)

label var exp "years of experience from age 16 until year of observation"
label var exp_share "share of years worked from age 16 until year of observation"

* create time-invariant variable for years of experience in final year of observation
sort pid period
by pid: egen exp_max = max(exp)
label var exp_max "time-invariant highest years of experience from age 16"

* create time-invariant variable for share of years worked from age 16 until final year of observation
by pid: egen max_year = max(year)
g max_share_temp = .
replace max_share_temp = exp_share if year == max_year
by pid: egen exp_max_share = min(max_share_temp)
label var exp_max_share "time-invariant share of years worked from age 16 until final year of observation"

* create several adult equivalent variables
replace hhadults = . if hhadults > hhsize										// only 2 observations
replace hhchildren = . if hhchildren < 0										// only 2 observations

g hhsize_oxford = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.7) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.5)
lab var hhsize_oxford "Oxford adult equivalent scale (1 for adult #1 + 0.7 per other adults + 0.5 per child)"

g hhsize_oecd = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.5) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.3)
lab var hhsize_oecd "OECD adult equivalent scale (1 for adult #1 + 0.5 per other adults + 0.3 per child)"

g hhsize_root = sqrt(hhsize)
lab var hhsize_root "square root of hhsize"

g hhsize_comp = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.72) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.34)
lab var hhsize_comp "companion adult equivalent scale (1 for adult #1 + 0.72 per other adults + 0.34 per child)"

g hhsize_pse = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.64) + ((hhchildren >= 1 & hhchildren != .) * 0.5) + ((hhchildren - 1 >= 1 & hhchildren != .) * (hhchildren - 1) * 0.43)
lab var hhsize_pse "PSE adult equivalent scale (1 for adult #1 + 0.64 per other adults + + 0.5 for child #1 + 0.43 per child)"

g hhsize_cube = hhsize ^ (1/3)
lab var hhsize_cube "cube root of hhsize"

drop _merge worked_* exp_20* elig_* start_* end_* max_*

* compress and save
compress
save "$output/CHN", replace
