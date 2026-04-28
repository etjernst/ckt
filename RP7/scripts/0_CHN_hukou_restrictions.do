/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Jan 2026
This code:
	- create CHN datasets with hukou restrictions
*******************************************************************************/

* set log file
capture log close
log using "$logs/0_CHN_hukou_restrictions.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

* **********************************************************************
* 1. Only rural hukou
* **********************************************************************
* Open dataset
  use 						"$dirdata/countries/CHN.dta", clear

bys pid: egen min_hukou = min(hukou)

g rural_hukou = min_hukou == 1

keep if rural_hukou == 1

save "$dirdata/countries/CHN_hukou_rural_only.dta", replace

* **********************************************************************
* 2. Only urban hukou
* **********************************************************************
* Open dataset
  use 						"$dirdata/countries/CHN.dta", clear

bys pid: egen max_hukou = max(hukou)

g urban_hukou = max_hukou == 0

keep if urban_hukou == 1

save "$dirdata/countries/CHN_hukou_urban_only.dta", replace

* **********************************************************************
* 3. Rural hukou first
* **********************************************************************
* Open dataset
  use 						"$dirdata/countries/CHN.dta", clear

bys pid (period): g obs = _n
g first_hukou_temp = .
replace first_hukou_temp = hukou if obs == 1
bys pid: egen first_hukou = min(first_hukou_temp)
drop first_hukou_temp

keep if first_hukou == 1

save "$dirdata/countries/CHN_hukou_rural_first.dta", replace
				  
* **********************************************************************
* 4. Urban hukou first
* **********************************************************************
* Open dataset
  use 						"$dirdata/countries/CHN.dta", clear

bys pid (period): g obs = _n
g first_hukou_temp = .
replace first_hukou_temp = hukou if obs == 1
bys pid: egen first_hukou = min(first_hukou_temp)
drop first_hukou_temp

keep if first_hukou == 0

save "$dirdata/countries/CHN_hukou_urban_first.dta", replace

* **********************************************************************
log close
