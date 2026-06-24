/*******************************************************************************
Returns to Migration --- data-construction pipeline
0_databuild_master.do

Builds the three analysis input datasets (CHN, IDN, TZA) from the upstream
replication-package outputs, and writes them to output/.

This is the permanent data-construction pipeline. It is separate from the
analytical pipeline (RP7/scripts/0_master.do), which this file never calls.

Run from the databuild directory:
	cd RP7/databuild && stata-mp -b do 0_databuild_master.do

Chain, per country:
- IDN: HKLM Intergen_Analysis_IFLS (+ Total_panel_HKLM_hhsize + location_vars) -> IDN.dta
- CHN: LMMVW chn_panel + raw CFPS adult waves 1-4 (experience) -> CHN.dta
- TZA: LMMVW tza_panel + David's Panel_TZA (education, CPI) -> TZA.dta

The verification harness (_verify_equivalence.do) is temporary and is NOT run
here; run it separately once, then delete it.
*******************************************************************************/

clear all
set more off

do 0_databuild_paths.do

do 1_build_IDN.do
do 2_build_CHN.do
do 3_build_TZA.do

display "Data build complete. Outputs in $output."
