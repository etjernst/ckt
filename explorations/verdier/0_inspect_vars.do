* ============================================================
* Title:   Inspect geographic variables in processed CKT data
* Author:  Claude (design memo phase; read-only)
* Date:    2026-04-22
* Purpose: List variables in CHN / IDN / TZA processed files to
*          identify candidate v_i indexing variables for the
*          Verdier robust extrapolation.
* Input:   data/processed/{CHN,IDN,TZA}_unb.dta
* Output:  explorations/verdier/var_lists.txt (log)
* ============================================================

clear all
set more off

* Resolve project root: assumes .do is run from c:/git/ckt
if "$dir" == "" global dir "c:/git/ckt"

capture log close
log using "$dir/explorations/verdier/var_lists.smcl", replace

foreach country in CHN IDN TZA {
    display _newline(2) "{hline 60}"
    display "Country: `country'"
    display "{hline 60}"

    use "$dir/data/processed/`country'_unb.dta", clear
    describe, simple

    display _newline "{hline 40}"
    display "Candidate geographic variables (name/label):"
    display "{hline 40}"
    foreach pat in province prov region district dist village vil ///
                   psu ea community kab kec desa rt rw hukou ///
                   birth origin baseline_prov baseline_region  {
        capture confirm variable `pat'
        if _rc == 0 {
            display as text "FOUND: `pat'"
            tabulate `pat', missing
        }
    }

    * Also show any variable with 'prov', 'reg', 'dist', 'vil' in the name
    display _newline "{hline 40}"
    display "All variable names (searching for geography hints):"
    display "{hline 40}"
    quietly ds
    local allvars = r(varlist)
    foreach v of local allvars {
        if (strpos("`v'", "prov") > 0 | strpos("`v'", "reg") > 0 | ///
            strpos("`v'", "dist") > 0 | strpos("`v'", "vil") > 0 | ///
            strpos("`v'", "kab") > 0 | strpos("`v'", "kec") > 0 | ///
            strpos("`v'", "psu") > 0 | strpos("`v'", "ea") > 0 | ///
            strpos("`v'", "community") > 0 | strpos("`v'", "hukou") > 0 | ///
            strpos("`v'", "birth") > 0 | strpos("`v'", "origin") > 0 | ///
            strpos("`v'", "location") > 0) {
            display as text "  potential: `v'"
            capture tab `v' if period == 1, missing
        }
    }
}

log close
translate "$dir/explorations/verdier/var_lists.smcl" ///
          "$dir/explorations/verdier/var_lists.txt", replace

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
