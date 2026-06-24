/*******************************************************************************
Returns to Migration --- data-construction pipeline
1_build_IDN.do

Builds IDN.dta (Indonesia analysis input) from the HKLM replication output.

Input:  inputs/Intergen_Analysis_IFLS.dta   (HKLM build output)
        inputs/Total_panel_HKLM_hhsize.dta  (HKLM household size)
        inputs/location_vars.dta            (province/kabupaten/kecamatan, from IFLS)
Output: output/IDN.dta

Logic is transcribed verbatim from the team's "Data preparation" do-file
(nominal track); only paths and file organization are changed. The consumption
and income variables saved here are nominal.
*******************************************************************************/

clear all
set more off
do 0_databuild_paths.do

* load replication data and keep only wave years
use "$inputs/Intergen_Analysis_IFLS", clear									//  This data files comes the replication data from HKLM that can be downloaded on Harvard's dataverse. After download the whole replication package, run the master's do-file and one of the dta files created is Intergen_Analysis_IFLS.dta. We use that file directly.

* create time-invariant variable for age in the year of the first survey wave (1993)
g year_temp = year
replace year_temp = . if age == .
egen first_year = min(year_temp), by(pidlink)
egen age1993 = total((age - (first_year - 1993)) * (year == first_year)), by(pidlink)
lab var age1993 "age in 1993"
drop year_temp first_year

* create yearly dummy for employment
foreach i of numlist 1988/2015 {
	g empl_`i'_temp = .
	replace empl_`i'_temp = empl if year == `i'
}
sort pidlink year
foreach i of numlist 1988/2015 {
	by pidlink: egen empl_`i' = min(empl_`i'_temp)
}

* make values of empl_`year' 0 if respondent was 16+ but we don't know they worked, and make them missing if respondent wasn't yet 16
foreach i of numlist 1988/2015 {
	replace empl_`i' = 0 if 1993 - age1993 + 16 <= `i' & empl_`i' == .
	replace empl_`i' = . if 1993 - age1993 + 16 > `i'
}

* create experience variables
g exp = .
g elig_years = .
foreach i in 1993 1997 1998 2000 2007 2008 2014 2015 {
	egen exp_`i' = rowtotal(empl_1988-empl_`i')
	egen elig_years_`i' = anycount(empl_1988-empl_`i'), values(0 1)
	replace exp = exp_`i' if year == `i'
	replace elig_years = elig_years_`i' if year == `i'
}
lab var exp "years of experience from 1988 or age 16 until year of observation"

sort pidlink year
by pidlink: egen exp_max = max(exp)
lab var exp_max "time-invariant highest years of experience from 1988 or age 16"

g exp_share = exp / elig_years													// Experience divided by number of years since 1988 or age 16 (whichever comes later) and year of observation
label var exp_share "share of years worked from 1988 or age 16 until year of observation"

sort pidlink year
by pidlink: egen max_elig_years = max(elig_years)
g exp_max_share = exp_max / max_elig_years
label var exp_max_share "time-invariant share of years worked from 1988 or age 16 until final year of observation"

drop empl_* elig_years* exp_19* exp_20* max_elig_years

* the following 63 lines of code are from the HKLM replication do-files to create Consumption_Analysis_IFLS.dta from Intergen_Analysis_IFLS.dta. Here we just omit the lines from the replication code that drop observations where nonag, urban, age, or educyr are missing
local outlier "1"
local top = 100 - `outlier'
foreach var in inc inc_h forinc forinc_h inforinc inforinc_h ///
inc_real inc_h_real forinc_real forinc_h_real inforinc_real inforinc_h_real {
gen `var'_raw = `var'
replace `var' = . if `var' <= 0		// Remove zero and negative monetary values because when taking logs these are not included either (never happens)
forvalues year =  1988 / 2015 {													// Min and max value of year variable
	display `year'
	_pctile `var' if year == `year', p(`outlier' `top')
	replace `var' = . if (`var' < r(r1) | `var' > r(r2)) & year == `year'
}
gen ln`var' = ln(`var')
drop `var'_raw
}
sum inc inc_h forinc forinc_h inforinc inforinc_h inc_real inc_h_real forinc_real forinc_h_real inforinc_real inforinc_h_real
*
sum cons_tot cons_food cons_nfood cons_tot_real cons_food_real cons_nfood_real 	// A handful of times 0 so delete these
sum cons_tot cons_food cons_nfood cons_tot_real cons_food_real cons_nfood_real pidlink year if wave == . // Sometimes happens, fine, leave as it (so don't delete outliers for those)
foreach var in cons_tot cons_food cons_nfood cons_tot_real cons_food_real cons_nfood_real {
gen `var'_raw = `var'
replace `var' = . if `var' <= 0		// Remove zero monetary values because when taking logs these are not included either (happens a few times)
	forvalues wave = 1/5 {		/* Delete outliers per wave (instead of per year as we do with income data). Note it happens occasionally that wave
	is missing while consumption data is available, fine leave those consumption values unchanged */
	display `wave'
	_pctile `var' if wave == `wave', p(`outlier' `top')
	replace `var' = . if (`var' < r(r1) | `var' > r(r2)) & wave == `wave'
}
gen ln`var' = ln(`var')
drop `var'_raw
}

drop lncons_tot lncons_food lncons_nfood			// This means that all consumption variables are now replaced with the real equivalents!
rename lncons_tot_real lncons_tot
rename lncons_food_real lncons_food
rename lncons_nfood_real lncons_nfood

* label variables
lab var lninc "Log income"
lab var lninc_h "Log hourly income"
lab var lnforinc "Log formal income"
lab var lnforinc_h "Log hourly formla income"
lab var lninforinc "Log informal income"
lab var lninforinc_h "Log hourly informal income"
lab var lninc_real "Log real earnings"
lab var lninc_h_real "Log real wage"
lab var lnforinc_real "Log real earnings"
lab var lnforinc_h_real "Log real wage"
lab var lninforinc_real "Log real earnings"
lab var lninforinc_h_real "Log real wage"
lab var lncons_tot "Log total consumption"
lab var lncons_food "Log food consumption"
lab var lncons_nfood "Log non-food consumption"

* merge in hhsize and hhadults (originally nadult) from Total_panel_HKLM data
merge 1:1 pidlink year using "$inputs/Total_panel_HKLM_hhsize"
drop if _merge == 2
replace hhsize = hhsize_hklm

* create several adult equivalent variables
g hhchildren = hhsize - hhadults
replace hhchildren = . if hhsize == . | hhadults == .

g hhsize_oxford = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.7) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.5)
lab var hhsize_oxford "Oxford adult equivalent scale (1 for adult #1 + 0.7 per other adults + 0.5 per child)"

g hhsize_oecd = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.5) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.3)
lab var hhsize_oecd "OECD adult equivalent scale (1 for adult #1 + 0.5 per other adults + 0.3 per child)"

g hhsize_root = sqrt(hhsize)
lab var hhsize_root "Square root of hhsize"

g hhsize_comp = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.72) + ((hhchildren >= 1 & hhchildren != .) * hhchildren * 0.34)
lab var hhsize_comp "Companion adult equivalent scale (1 for adult #1 + 0.72 per other adults + 0.34 per child)"

g hhsize_pse = (hhadults >= 1 & hhadults != .) + ((hhadults - 1 >= 1 & hhadults != .) * (hhadults - 1) * 0.64) + ((hhchildren >= 1 & hhchildren != .) * 0.5) + ((hhchildren - 1 >= 1 & hhchildren != .) * (hhchildren - 1) * 0.43)
lab var hhsize_pse "PSE adult equivalent scale (1 for adult #1 + 0.64 per other adults + + 0.5 for child #1 + 0.43 per child)"

g hhsize_cube = hhsize ^ (1/3)
lab var hhsize_cube "Cube root of hhsize"

drop _merge hhsize_hklm hhchildren

* order variables
order pidlink year wave hhsize hhadults hhsize_oxford hhsize_oecd hhsize_root ///
hhsize_comp hhsize_pse hhsize_cube age age_norm age_sq male female ///
urban_birth migr educlv educyr educyr_sq ravens ravens_norm ravens_norm_sq ///
nonag urban nonagonly nonagany inc inc_h forinc forinc_h inforinc inforinc_h ///
inc_real inc_h_real forinc_real forinc_h_real inforinc_real inforinc_h_real ///
lninc lninc_h lnforinc lnforinc_h lninforinc lninforinc_h lninc_real ///
lninc_h_real lnforinc_real lnforinc_h_real lninforinc_real lninforinc_h_real ///
empl hour forhour inforhour lnhour lnhour_sq lnhour_exp3 lnhour_exp4 ///
lnhour_exp5 lnforhour lnforhour_sq lninforhour lninforhour_sq cons_tot ///
cons_food cons_nfood cons_tot_real cons_food_real cons_nfood_real lncons_tot ///
lncons_food lncons_nfood fath_pidlink moth_pidlink jakarta surabaya

drop if wave == .

* merge location variables (extracted from IFLS data)
merge 1:1 pidlink year using "$inputs/location_vars"
	drop if _merge == 2
	drop _merge
encode provname, generate(prov)
encode kabuname, generate(kabu)
encode kecaname, generate(keca)
	drop provname kabuname kecaname

* drop year and province dummies; drop log, squared, and normalized variables
drop year1* year2*
drop jakarta - bekasi
drop *_norm*
drop ln*
drop *_sq

* drop secondary pidlinks and form/inform income and hours variables
drop *_pidlink *forinc* *forhour*

* rename variables to ensure consistency across all country data
rename pidlink pid
rename wave period
rename urban_birth urbanbirth
rename educyr education
rename inc income
rename cons_tot consumption
rename hour hours
rename cons_food consfood
rename cons_nfood  consnonfood

* create maximum education level within all periods
sort pid period
by pid: egen education_max = max(education)										// We create this varialbe for all countries to make sure we have a time-invariant education variable for all countries
label var education_max "time-invariant highest years of education for individual"

* compress and save
compress
save "$output/IDN", replace														// This is the file that we use directly for all our analyses for Indonesia.
