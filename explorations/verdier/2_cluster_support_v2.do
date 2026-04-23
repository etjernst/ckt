* ============================================================
* Title:   Cluster support for v_i candidates (inline version)
* Author:  Claude
* Date:    2026-04-22
* Purpose: Per country and candidate v_i, report:
*          - number of unique clusters;
*          - switchers per cluster (distribution);
*          - always-rural support fraction.
* Input:   data/processed/{CHN,IDN,TZA}_unb.dta
* Output:  explorations/verdier/cluster_support_v2.{smcl,txt}
* Note:    Read-only. Inline (no helper program) so any error
*          surfaces rather than being silently captured.
* ============================================================

clear all
set more off
if "$dir" == "" global dir "c:/git/ckt"
capture log close
log using "$dir/explorations/verdier/cluster_support_v2.smcl", replace text

* ----------------------------------------------------------------
* Helper: gen_vfirst returns the value of `vname' at the EARLIEST
* observed year per pid (NOT the smallest numeric value across years,
* which is what the buggy min(cond(...)) version did).
* Validated by 3_test_gen_vfirst.do on 5 fabricated cases.
* ----------------------------------------------------------------
capture program drop gen_vfirst
program define gen_vfirst
    syntax , vname(varname) genname(name)
    capture drop `genname'
    tempvar seq mark tmp
    bysort pid (year): gen `seq' = sum(!missing(`vname'))
    by pid: gen `mark' = (!missing(`vname')) & (`seq' == 1)
    gen `tmp' = `vname' if `mark'
    by pid: egen `genname' = max(`tmp')
end

*
* Country: CHN
*
display _newline(2) "================ CHN ================"
use "$dir/data/processed/CHN_unb.dta", clear
display "N obs: " _N
quietly levelsof pid, local(pids)
display "N individuals: " `:word count `pids''

foreach v in prov provcd hukou birth_province birth_county {
    capture confirm variable `v'
    if _rc != 0 {
        display _newline "--- `v' : variable not present, skipping ---"
        continue
    }
    display _newline "--- CHN / `v' ---"

    * first-wave value of v per pid
    foreach tmp in vfirst_ nsw_ hasw_ first_obs_ {
        capture drop `tmp'
    }
    bysort pid (year): gen first_obs_ = _n == 1
    gen_vfirst, vname(`v') genname(vfirst_)

    preserve
        keep if first_obs_
        quietly count if !missing(vfirst_)
        local nind = r(N)
        quietly levelsof vfirst_, local(cells)
        display as result "  clusters (distinct v_i values): " `:word count `cells''
        display as result "  individuals with non-missing v_i: " `nind'

        * switcher var
        capture confirm variable switcher
        if _rc != 0 {
            display as error "  (no switcher variable; skipping)"
            restore
            continue
        }

        bysort vfirst_: egen nsw_ = total(switcher == 1)
        bysort vfirst_: gen firstincluster_ = (_n == 1)
        tabstat nsw_ if firstincluster_ == 1, stat(mean sd min p25 p50 p75 max n) col(stat) format(%9.1f)
        quietly count if nsw_ >= 5 & firstincluster_ == 1
        display as result "  clusters with >=5 switchers: " r(N)
        quietly count if nsw_ >= 10 & firstincluster_ == 1
        display as result "  clusters with >=10 switchers: " r(N)
        drop firstincluster_

        * always-rural support
        capture confirm variable never
        if _rc != 0 {
            gen never = (switcher == 0)
        }
        bysort vfirst_: egen hasw_ = max(switcher == 1)
        quietly count if never == 1 & !missing(vfirst_)
        local Nnever = r(N)
        quietly count if never == 1 & hasw_ == 1 & !missing(vfirst_)
        local Nsup   = r(N)
        if `Nnever' > 0 {
            local frac = 100 * `Nsup' / `Nnever'
            display as result "  always-rural support: " %6.2f `frac' ///
                "%  (" `Nsup' " / " `Nnever' ")"
        }
    restore
}

*
* Country: IDN
*
display _newline(2) "================ IDN ================"
use "$dir/data/processed/IDN_unb.dta", clear
display "N obs: " _N

foreach v in prov kabu keca location {
    capture confirm variable `v'
    if _rc != 0 {
        display _newline "--- `v' : variable not present, skipping ---"
        continue
    }
    display _newline "--- IDN / `v' ---"
    foreach tmp in vfirst_ nsw_ hasw_ first_obs_ {
        capture drop `tmp'
    }
    bysort pid (year): gen first_obs_ = _n == 1
    gen_vfirst, vname(`v') genname(vfirst_)

    preserve
        keep if first_obs_
        quietly count if !missing(vfirst_)
        local nind = r(N)
        quietly levelsof vfirst_, local(cells)
        display as result "  clusters: " `:word count `cells''
        display as result "  individuals: " `nind'

        capture confirm variable switcher
        if _rc != 0 {
            display as error "  (no switcher; skip)"
            restore
            continue
        }
        bysort vfirst_: egen nsw_ = total(switcher == 1)
        bysort vfirst_: gen firstincluster_ = (_n == 1)
        tabstat nsw_ if firstincluster_ == 1, stat(mean sd min p25 p50 p75 max n) col(stat) format(%9.1f)
        quietly count if nsw_ >= 5 & firstincluster_ == 1
        display as result "  clusters with >=5 switchers: " r(N)
        quietly count if nsw_ >= 10 & firstincluster_ == 1
        display as result "  clusters with >=10 switchers: " r(N)
        drop firstincluster_

        capture confirm variable never
        if _rc != 0 gen never = (switcher == 0)
        bysort vfirst_: egen hasw_ = max(switcher == 1)
        quietly count if never == 1 & !missing(vfirst_)
        local Nnever = r(N)
        quietly count if never == 1 & hasw_ == 1 & !missing(vfirst_)
        local Nsup   = r(N)
        if `Nnever' > 0 {
            local frac = 100 * `Nsup' / `Nnever'
            display as result "  always-rural support: " %6.2f `frac' ///
                "%  (" `Nsup' " / " `Nnever' ")"
        }
    restore
}

* IDN: migr / urbanbirth diagnostics
display _newline "--- IDN migr / urbanbirth ---"
capture confirm variable migr
if _rc == 0 tab migr, missing
capture confirm variable urbanbirth
if _rc == 0 tab urbanbirth, missing

*
* Country: TZA
*
display _newline(2) "================ TZA ================"
use "$dir/data/processed/TZA_unb.dta", clear
display "N obs: " _N

* Also build region x district as a finer cluster
capture confirm variable region
if _rc == 0 {
    capture confirm variable district
    if _rc == 0 {
        egen regdist = group(region district)
    }
}

foreach v in region district regdist location_detail {
    capture confirm variable `v'
    if _rc != 0 {
        display _newline "--- `v' : variable not present, skipping ---"
        continue
    }
    display _newline "--- TZA / `v' ---"
    foreach tmp in vfirst_ nsw_ hasw_ first_obs_ {
        capture drop `tmp'
    }
    bysort pid (year): gen first_obs_ = _n == 1
    gen_vfirst, vname(`v') genname(vfirst_)

    preserve
        keep if first_obs_
        quietly count if !missing(vfirst_)
        local nind = r(N)
        quietly levelsof vfirst_, local(cells)
        display as result "  clusters: " `:word count `cells''
        display as result "  individuals: " `nind'

        capture confirm variable switcher
        if _rc != 0 {
            display as error "  (no switcher; skip)"
            restore
            continue
        }
        bysort vfirst_: egen nsw_ = total(switcher == 1)
        bysort vfirst_: gen firstincluster_ = (_n == 1)
        tabstat nsw_ if firstincluster_ == 1, stat(mean sd min p25 p50 p75 max n) col(stat) format(%9.1f)
        quietly count if nsw_ >= 5 & firstincluster_ == 1
        display as result "  clusters with >=5 switchers: " r(N)
        quietly count if nsw_ >= 10 & firstincluster_ == 1
        display as result "  clusters with >=10 switchers: " r(N)
        drop firstincluster_

        capture confirm variable never
        if _rc != 0 gen never = (switcher == 0)
        bysort vfirst_: egen hasw_ = max(switcher == 1)
        quietly count if never == 1 & !missing(vfirst_)
        local Nnever = r(N)
        quietly count if never == 1 & hasw_ == 1 & !missing(vfirst_)
        local Nsup   = r(N)
        if `Nnever' > 0 {
            local frac = 100 * `Nsup' / `Nnever'
            display as result "  always-rural support: " %6.2f `frac' ///
                "%  (" `Nsup' " / " `Nnever' ")"
        }
    restore
}

log close

* Translate SMCL to plain text
capture translate "$dir/explorations/verdier/cluster_support_v2.smcl" ///
                 "$dir/explorations/verdier/cluster_support_v2.txt", replace

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
