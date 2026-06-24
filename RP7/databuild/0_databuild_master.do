/*******************************************************************************
Returns to Migration --- data-construction pipeline
0_databuild_master.do

Builds the three analysis input datasets (CHN, IDN, TZA) from the upstream
replication-package outputs, and writes them to output/.

This is the permanent data-construction pipeline. It is separate from the
analytical pipeline (RP7/scripts/0_master.do), which this file never calls.

Run from the databuild directory (use -e, not -b, to avoid the Windows popup):
	cd RP7/databuild && stata-mp -e do 0_databuild_master.do

Chain, per country:
- IDN: HKLM Intergen_Analysis_IFLS (+ Total_panel_HKLM_hhsize + location_vars) -> IDN.dta
- CHN: LMMVW chn_panel + raw CFPS adult waves 1-4 (experience) -> CHN.dta
- TZA: LMMVW tza_panel + David's Panel_TZA (education, CPI) -> TZA.dta

The verification harness (_verify_equivalence.do) is temporary and is NOT run
here; run it separately once, then delete it.
*******************************************************************************/

clear all
set more off

* Run this file with `stata-mp -e do 0_databuild_master.do` (NOT -b): the -e
* flag is what suppresses the Windows "Stata finished" completion popup. The
* capture noisily wrapper below is for error hygiene (so _rc can be inspected),
* not for popup suppression.
local failed = 0
capture noisily {

	do 0_databuild_paths.do

	foreach f in 1_build_IDN 2_build_CHN 3_build_TZA {
		display _n "=================== running `f' ==================="
		capture noisily do `f'.do
		if _rc {
			display as error ">>> `f' FAILED with rc=`=_rc'"
			local failed = 1
		}
		else {
			display ">>> `f' completed"
		}
	}
}
if _rc local failed = 1

if `failed' {
	display as error "One or more builds failed; see the log above. Outputs may be incomplete."
}
else {
	display "Data build complete. Outputs in $output."
}

capture log close
exit, STATA clear
