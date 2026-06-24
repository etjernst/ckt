/*******************************************************************************
Returns to Migration --- data-construction pipeline
3_build_TZA.do

Builds TZA.dta (Tanzania analysis input) from the LMMVW replication output and
David's coded education/CPI variables.

Input:  inputs/tza_panel.dta   (LMMVW build output)
        inputs/Panel_TZA.dta   (David's coding of raw TZA, used here only for
                                 education and CPI)
Output: output/TZA.dta
        output/_intermediate/Panel_LMMVW_TZA.dta  (stage A intermediate)

Stage A transcribes the LMMVW Tanzania variable selection; stage B transcribes
the merge of David's education/CPI, the experience construction, and assembly.
Both verbatim from the team's do-files; only paths and organization changed.
Consumption and income are nominal.
*******************************************************************************/

clear all
set more off
do 0_databuild_paths.do

********************************************************************************
*** Stage A: select and rename variables from the LMMVW Tanzania panel
********************************************************************************
*** Open main panel provided by LMMVW in replication package
use "$inputs/tza_panel", clear

cap unique pid

tab year, m

*** Select which variables to keep
keep pid wave isic_primary urban any_ag switcher age female educ district ward region year hhsize nadult consumption earnings hours food earn_primary earn_self

*** Rename variables

lab var pid "unique identifier for each person in the survey"

rename wave period
lab var period "period of reference for the data (number of each survey round/wave)"

rename isic_primary	employmain													// DB TO MK: I BELIEVE isic_primary TELLS WHAT KIND OF BUSINESS EACH PERSON'S PRIMARY EMPLOYMENT IS SO MAYBE THAT COULD BE USED FOR THIS VARIABLE, BUT THE VAST MAJORITY OF OBSERVATIONS ARE MISSING VALUES FOR isic_primary
lab var employmain "main sector of employment or occupation"

lab var urban "dummy = 1 if current location is urban"

g nonag = .
replace nonag = 1 if any_ag == 0
replace nonag = 0 if any_ag == 1
lab var nonag "dummy = 1 if current employment is not in agriculture"

rename switcher switcherru
lab var switcherru "dummy = 1 if ever switched between rural and urban"

sort pid year
by pid: egen max_ag = max(any_ag)
by pid: egen min_ag = min(any_ag)
g switcheran = max_ag - min_ag								// DB TO MK: any_ag IS A DUMMY FOR "Does anyone in the hh cultivate any plot" SO IT DOESN'T SEEM LIKE THIS IS EXACTLY WHAT WE WANT
lab var switcheran "dummy = 1 if ever switched between ag and non-ag"
drop any_ag max_ag min_ag

g nonagonly = nonag
lab var nonagonly "dummy = 1 if all employments are not in agriculture"

lab var age "age in years"

lab var female "dummy = 1 if female"

rename educ education
lab var education "formal education attained (years of schooling)"

g location = region
lab var location "current location (region)"

g strlocation = "."
tostring region, gen(strregion)
tostring district, gen(strdistrict)
tostring ward, format(%03.0f) gen(strward)
replace strlocation = strregion + "0" + strdistrict + "0" + strward if region != . & district != . & ward != .
destring strlocation, gen(location_detail)
drop strlocation strregion strdistrict strward
lab var location_detail "current location (region-district-ward)"
cap unique location
cap unique location_detail

xtset pid period
g migrant = .
replace migrant = location_detail != l.location_detail if location_detail != . & l.location_detail != .
lab var migrant "dummy = 1 if migrant (location in t != location in t-1)"

lab var year "calendar year"

lab var hhsize "number of HH members (total size)"

rename nadult hhadults
lab var hhadults "number of HH members age >= 16"								// DB TO MK: I USED THE WORDING FROM THE VARIABLE SELECTION EXCEL FILE FOR THE LABEL BUT I'M NOT SURE WHAT AGE IS CONSIDERED AN ADULT IN THIS DATA

sum hhsize
sum hhadults																	// DB TO MK: SOMETHING SEEMS WRONG WITH hhadults - A BUNCH OF OBSERVATIONS HAVE VALUES IN THE THOUSANDS, MAKING hhchildren NEGATIVE FOR MANY OBSERVATIONS
*g hhchildren = hhsize - hhadults
*lab var hhchildren "number of HH members age < 16"

lab var consumption "nominal annual consumption"

rename earnings income															// DB TO MK: THIS IS ANNUAL INCOME BUT JUST FROM THE PRIMARY JOB. THERE ARE A LOT OF ZEROS FOR SOME REASON EVEN THOUGH THESE PEOPLE HAVE MANY HOURS WORKED
lab var income "annual income from primary job"

lab var hours "number of annual hours worked"

rename food consfood
lab var consfood "nominal annual consumption of food items"

g consnonfood = consumption - consfood
lab var consnonfood "nominal annual consumption of non-food items"
sum consnonfood

rename earn_primary incformal													// This "earnings from wage labor"
lab var incformal "total income from formal employment (wage labor)"

rename earn_self incinfself														// This is "own business earnings past year"
lab var incinfself "total income from informal or self-employment (own business earnings past year)"

order pid period employmain urban nonag switcherru switcheran nonagonly age female education location location_detail region district ward migrant year hhsize hhadults consumption income hours consfood consnonfood incformal incinfself

save "$output/_intermediate/Panel_LMMVW_TZA", replace

********************************************************************************
*** Stage B: merge David's education/CPI, build experience, assemble TZA.dta
********************************************************************************

* load data prepared by David in Feb 2024, keep education variable for merge
* must use decode to replace pid variable with its label value
use "$inputs/Panel_TZA", clear
decode pid, gen(pid_str)
/*
g pid_length = length(pid_str)
g hhid_missing = hhid == ""
tab pid_length hhid_missing, m													// some pids have extra characters that need to be deleted or have fewer characters than most other pids, and these ones all have missing hhids
replace hhid = substr(pid_str, 1, 8) if pid_length == 10 | pid_length == 11		// after looking through the pids, hhids should be first 8 characters for pids that have 10 or 11 characters
replace hhid = substr(pid_str, 1, 14) if pid_length == 18 | pid_length == 19	// after looking through the pids, hhids should be first 14 characters for pids that have 18 or 19 characters
drop hhsize
bysort hhid period: egen hhsize = count(pid)										// creating fixed hhsize variable
lab var hhsize "number of HH members (total size)"
drop if age < 16
bysort hhid period: egen hhadults = count(pid)										// creating fixed hhadults variable
lab var hhadults "number of HH members age >= 16"
keep pid_str hhid period education* cpi hhsize hhadults
*/
keep pid_str period education* cpi
tempfile educvars
save `educvars'

* load replication data (prepared by David)
use "$output/_intermediate/Panel_LMMVW_TZA", clear
*drop hhsize hhadults															// drop faulty hhsize and hhadults variables
* merge education and cpi variables coded by David
rename education education_LMMVW
decode pid, gen(pid_str)
merge 1:1 pid_str period using `educvars'
	keep if _merge == 3
	drop _merge

* create time-invariant variable for age in the year of the first survey wave (2008)
g year_temp = year
replace year_temp = . if age == .
egen first_year = min(year_temp), by(pid)
egen age2008 = total((age - (first_year - 2008)) * (year == first_year)), by(pid)
lab var age2008 "age in 2008"
	drop year_temp first_year

* create employment indicator
g empl = .
replace empl = 1 if hours > 0 & hours != .
replace empl = 0 if hours == 0
lab var empl "empoyment indicator for year of observation"

* create experience variable
sort pid period
g temp_worked_2009 = .
replace temp_worked_2009 = empl if year == 2009
by pid: egen worked_2009 = max(temp_worked_2009)
g temp_worked_2011 = .
replace temp_worked_2011 = empl if year == 2011
by pid: egen worked_2011 = max(temp_worked_2011)
egen exp_2011 = rowtotal(worked_2009 worked_2011)
g temp_worked_2013 = .
replace temp_worked_2013 = empl if year == 2013
by pid: egen worked_2013 = max(temp_worked_2013)
egen exp_2013 = rowtotal(worked_2009 worked_2011 worked_2013)
g exp = worked_2009
replace exp = exp_2011 if year == 2011
replace exp = exp_2013 if year == 2013
label var exp "number of waves employed through wave of observation"

* create variable for share of waves worked
g exp_share = exp
replace exp_share = exp / 2 if year == 2011
replace exp_share = exp / 3 if year == 2013
label var exp_share "share of waves worked through wave of observation"

* create time-invariant variable for waves of experience in final wave
sort pid period
by pid: egen exp_max = max(exp)
label var exp_max "time-invariant most waves of experience from age 16"

* create time-invariant variable for share of waves worked from age 16 until final wave
by pid: egen max_year = max(year)
g max_share_temp = .
replace max_share_temp = exp_share if year == max_year
by pid: egen exp_max_share = min(max_share_temp)
label var exp_max_share "time-invariant share of waves worked from age 16 until final wave"

* get rid of huge values of hhadults that arise from missing HHIDs
replace hhadults = . if hhadults >= 2000

* create several adult equivalent variables
g hhchildren = hhsize - hhadults
replace hhchildren = . if hhadults == .

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

drop temp_* worked_* exp_20* max_* hhchildren

* drop pid variable created for merging and save
drop pid_str
compress
save "$output/TZA", replace
