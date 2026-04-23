* ============================================================
* Title:   Cluster support for v_i candidates
* Author:  Claude (design memo phase; read-only)
* Date:    2026-04-22
* Purpose: For each country and candidate v_i, tabulate:
*          (1) number of unique v_i clusters;
*          (2) number of switchers per cluster;
*          (3) fraction of always-rural workers in clusters
*              containing at least one switcher (support fraction).
* Input:   data/processed/{CHN,IDN,TZA}_unb.dta
* Output:  explorations/verdier/cluster_support.{smcl,txt}
* Note:    Read-only. No data modification. Uses only first-wave
*          values of v_i candidates. Relies on the `always` /
*          `never` / `switcher` indicators built elsewhere in the
*          pipeline where available; otherwise reconstructs them.
* ============================================================

clear all
set more off
if "$dir" == "" global dir "c:/git/ckt"

capture log close
log using "$dir/explorations/verdier/cluster_support.smcl", replace

* ----------------------------------------------------------------
* Programs
* ----------------------------------------------------------------

capture program drop report_cluster
program define report_cluster
    syntax , vname(string) label(string)
    display _newline "{hline 60}"
    display as text "Candidate v_i: {bf:`label'} (`vname')"
    display "{hline 60}"

    capture confirm variable `vname'
    if _rc != 0 {
        display as error "  variable not found; skipping"
        exit
    }

    * Use the first non-missing observation per pid as v_i.
    tempvar vfirst first_obs
    bysort pid (year): gen `first_obs' = _n == 1
    bysort pid: egen `vfirst' = min(cond(!missing(`vname'), `vname', .))

    * Unique-values tabulation restricted to individuals.
    preserve
        keep if `first_obs'
        display as text "Number of distinct values: "
        quietly levelsof `vfirst', local(vals)
        display as text "  `:word count `vals''"
        display as text "Number of individuals with non-missing v_i: "
        count if !missing(`vfirst')
        local nindiv = r(N)
        display as text "  `nindiv'"

        * Switcher indicator: we want per-individual.
        * Assume `switcher' is a 0/1 pid-constant variable already in the data;
        * if not, reconstruct from the choice variable.
        capture confirm variable switcher
        if _rc != 0 {
            display as error "  (no switcher variable -- skipping support calc)"
            restore
            exit
        }

        capture confirm variable never
        if _rc != 0 {
            display as error "  (no never variable -- reconstructing as 1-switcher-always)"
            gen never = (switcher == 0)
        }

        * Switcher counts per cluster
        display _newline as text "Switchers per cluster (distribution):"
        tempvar nsw
        bysort `vfirst': egen `nsw' = total(switcher == 1)
        preserve
            bysort `vfirst' : keep if _n == 1
            tabstat `nsw', stat(mean sd min p25 p50 p75 max n) col(stat)
            count if `nsw' >= 5
            display as text "  clusters with >=5 switchers: `r(N)'"
            count if `nsw' >= 10
            display as text "  clusters with >=10 switchers: `r(N)'"
        restore

        * Always-rural support: fraction of never-movers in clusters with >=1 switcher
        tempvar hasw
        bysort `vfirst': egen `hasw' = max(switcher == 1)
        display _newline as text "Always-rural support (fraction of 'never' in clusters with >=1 switcher):"
        quietly count if never == 1 & !missing(`vfirst')
        local Nnever = r(N)
        quietly count if never == 1 & `hasw' == 1 & !missing(`vfirst')
        local Nneversup = r(N)
        if `Nnever' > 0 {
            local frac = 100 * `Nneversup' / `Nnever'
            display as text "  " %6.2f `frac' "%  (" `Nneversup' " / " `Nnever' ")"
        }
        else {
            display as text "  (no 'never' observations)"
        }
    restore
end

* ----------------------------------------------------------------
* CHN
* ----------------------------------------------------------------
display _newline(2) "{hline 60}"
display "Country: CHN"
display "{hline 60}"
use "$dir/data/processed/CHN_unb.dta", clear
capture describe switcher never always prov hukou birth_province birth_county provcd, fullnames

foreach v in prov provcd hukou birth_province birth_county {
    capture report_cluster, vname(`v') label(`v')
}

* ----------------------------------------------------------------
* IDN
* ----------------------------------------------------------------
display _newline(2) "{hline 60}"
display "Country: IDN"
display "{hline 60}"
use "$dir/data/processed/IDN_unb.dta", clear
capture describe switcher never always prov kabu keca migr urbanbirth, fullnames

foreach v in prov kabu keca {
    capture report_cluster, vname(`v') label(`v')
}

* Subsample restriction: migr == 0 means still at birth location, so
* first-wave location is a genuine "origin" index. Report share.
display _newline "{hline 40}"
display as text "IDN subsample diagnostics (for robustness sample)"
display "{hline 40}"
capture confirm variable migr
if _rc == 0 {
    tab migr, missing
}
capture confirm variable urbanbirth
if _rc == 0 {
    tab urbanbirth, missing
}

* ----------------------------------------------------------------
* TZA
* ----------------------------------------------------------------
display _newline(2) "{hline 60}"
display "Country: TZA"
display "{hline 60}"
use "$dir/data/processed/TZA_unb.dta", clear
capture describe switcher never always region district, fullnames

foreach v in region district {
    capture report_cluster, vname(`v') label(`v')
}

log close
translate "$dir/explorations/verdier/cluster_support.smcl" ///
          "$dir/explorations/verdier/cluster_support.txt", replace
