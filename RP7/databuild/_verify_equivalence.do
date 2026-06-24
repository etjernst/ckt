/*******************************************************************************
Returns to Migration --- data-construction pipeline
_verify_equivalence.do   (TEMPORARY --- delete after verification passes)

Confirms that the regenerated output/{CHN,IDN,TZA}.dta reproduce the canonical
analysis inputs. NOT part of the permanent pipeline and NOT called by the master.

Run after the build (use -e, not -b, to avoid the Windows popup):
	cd RP7/databuild && stata-mp -e do _verify_equivalence.do

Writes verification_report.md. The primary verdict is the Stata datasignature,
which compares data content independent of file-header timestamps and of
observation/variable order. cf _all is a secondary positional check.
*******************************************************************************/

clear all
set more off
do 0_databuild_paths.do

tempname fh
file open `fh' using "$databuild/verification_report.md", write replace
file write `fh' "# Verification report: regenerated vs canonical analysis datasets" _n _n
file write `fh' "Primary verdict is the Stata datasignature (content equality, order-independent)." _n
file write `fh' "cf _all is a secondary positional check (rc 0 means identical position by position)." _n _n

foreach c in CHN IDN TZA {

	* guard: skip cleanly (no modal) if either file is missing
	capture confirm file "$output/`c'.dta"
	local rc_out = _rc
	capture confirm file "$canonical/`c'.dta"
	local rc_can = _rc
	if `rc_out' | `rc_can' {
		file write `fh' "## `c'" _n
		file write `fh' "- SKIPPED: missing file (output rc `rc_out', canonical rc `rc_can')" _n _n
		continue
	}

	* regenerated
	use "$output/`c'", clear
	qui count
	local n_new = r(N)
	qui datasignature
	local sig_new "`r(datasignature)'"
	unab vars_new : _all
	qui bysort pid: gen byte _first = _n == 1
	qui count if _first
	local upid_new = r(N)
	drop _first

	* canonical
	use "$canonical/`c'", clear
	qui count
	local n_can = r(N)
	qui datasignature
	local sig_can "`r(datasignature)'"
	unab vars_can : _all
	qui bysort pid: gen byte _first = _n == 1
	qui count if _first
	local upid_can = r(N)
	drop _first

	* positional check: regenerated in memory, canonical as using
	use "$output/`c'", clear
	cap cf _all using "$canonical/`c'"
	local cf_rc = _rc

	file write `fh' "## `c'" _n
	file write `fh' "- obs (regenerated / canonical): `n_new' / `n_can'" _n
	file write `fh' "- unique pid (regenerated / canonical): `upid_new' / `upid_can'" _n
	file write `fh' "- datasignature regenerated: `sig_new'" _n
	file write `fh' "- datasignature canonical:   `sig_can'" _n
	if "`sig_new'" == "`sig_can'" {
		file write `fh' "- VERDICT: datasignature MATCH --- data content identical" _n
	}
	else {
		file write `fh' "- VERDICT: datasignature MISMATCH --- investigate" _n
	}
	if "`vars_new'" == "`vars_can'" {
		file write `fh' "- variable list: identical" _n
	}
	else {
		file write `fh' "- variable list: DIFFERS" _n
		file write `fh' "  - regenerated: `vars_new'" _n
		file write `fh' "  - canonical:   `vars_can'" _n
	}
	if `cf_rc' == 0 {
		file write `fh' "- cf _all: identical position by position (rc 0)" _n _n
	}
	else {
		file write `fh' "- cf _all: differences or different N (rc `cf_rc'); see log" _n _n
	}
}

* nominal-vs-real probe (read-only from Dropbox; skipped if not reachable)
local dbx "C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/countries"
file write `fh' "## Nominal vs real probe (read-only)" _n
foreach c in CHN IDN {
	capture confirm file "`dbx'/`c'.dta"
	local rc_nom = _rc
	capture confirm file "`dbx'/`c'_real.dta"
	local rc_real = _rc
	capture confirm file "`dbx'/`c'_real_spatial.dta"
	local rc_sp = _rc
	if `rc_nom' == 0 & `rc_real' == 0 {
		cap use consumption using "`dbx'/`c'.dta", clear
		qui summarize consumption
		local m_nom = r(mean)
		cap use consumption using "`dbx'/`c'_real.dta", clear
		qui summarize consumption
		local m_real = r(mean)
		local m_sp = .
		if `rc_sp' == 0 {
			cap use consumption using "`dbx'/`c'_real_spatial.dta", clear
			qui summarize consumption
			local m_sp = r(mean)
		}
		file write `fh' "- `c' mean consumption --- nominal `m_nom', real `m_real', real_spatial `m_sp'" _n
		if abs(`m_nom' - `m_real') < 1e-6 {
			file write `fh' "  - nominal and real are equal: deflation not applied to consumption for `c'" _n
		}
	}
	else {
		file write `fh' "- `c': real files not reachable, probe skipped" _n
	}
}
file write `fh' "" _n

file close `fh'
display "Verification report written to $databuild/verification_report.md"
