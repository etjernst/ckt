* ============================================================
* Title:   Render main-comparison tables from saved results
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: The main comparison run (x_main_comparison.do) finished
*          all 30 GMM fits and saved results to
*          x_main_comparison_results.dta, but the markdown table
*          rendering errored on bad string() syntax in Stata locals.
*          This script reads the results dta and builds the tables
*          with correct string formatting (no re-estimation).
* Input:   x_main_comparison_results.dta
* Output:  x_main_comparison_tables.smcl / .txt
*          Markdown tables for IDN, CHN, TZA.
* ============================================================

clear all
set more off
set varabbrev off
capture log close

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
cd "$dir/explorations/verdier"
log using "x_main_comparison_tables.smcl", replace text
version 17

use "x_main_comparison_results.dta", clear
describe

* Helper to format a value-se cell
capture program drop fmt_cell
program define fmt_cell, rclass
    args val se digits
    if "`digits'" == "" local digits 3
    if missing(`val') {
        return local cell "-- "
    }
    else {
        local vstr = string(`val', "%6.`digits'f")
        if missing(`se') {
            return local cell "`vstr'"
        }
        else {
            local sstr = string(`se', "%5.`digits'f")
            return local cell "`vstr' (`sstr')"
        }
    }
end

foreach country in IDN CHN TZA {
    di as result _newline(2) "## `country' --- consumption | urban | unbalanced"
    di as result _newline ///
        "| Statistic | covs_0 | covs_trend | covs_1 | covs_2 | covs_all |"
    di as result ///
        "|-----------|--------|------------|--------|--------|----------|"

    * Helper loop over (stat, approach) pairs
    foreach stat in phi Dnever Dalways Davg {
        local statlabel "phi"
        if "`stat'" == "Dnever"  local statlabel "Delta_never"
        if "`stat'" == "Dalways" local statlabel "Delta_always"
        if "`stat'" == "Davg"    local statlabel "Delta_avg"

        local valvar "phi"
        local sevar  "se_phi"
        if "`stat'" == "Dnever"  local valvar "Delta_never"
        if "`stat'" == "Dnever"  local sevar  "se_never"
        if "`stat'" == "Dalways" local valvar "Delta_always"
        if "`stat'" == "Dalways" local sevar  "se_always"
        if "`stat'" == "Davg"    local valvar "Delta_avg"
        if "`stat'" == "Davg"    local sevar  "se_avg"

        foreach appr in simple verdier {
            local row "| `statlabel' (`appr') |"
            foreach cov in 0 trend 1 2 all {
                qui sum `valvar' if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                if r(N) == 0 {
                    local row "`row' -- |"
                    continue
                }
                local val = r(mean)
                qui sum `sevar' if country == "`country'" & spec == "`cov'" & approach == "`appr'"
                local se = r(mean)
                fmt_cell `val' `se' 3
                local row "`row' `r(cell)' |"
            }
            di as result "`row'"
        }
    }

    * Hansen J (simple only)
    local row "| Hansen J (simple) |"
    foreach cov in 0 trend 1 2 all {
        qui sum Jstat if country == "`country'" & spec == "`cov'" & approach == "simple"
        if r(N) == 0 | missing(r(mean)) {
            local row "`row' -- |"
        }
        else {
            local jstat = r(mean)
            qui sum Jpval if country == "`country'" & spec == "`cov'" & approach == "simple"
            local jpval = r(mean)
            local jstr = string(`jstat', "%5.2f")
            local pstr = string(`jpval', "%4.2f")
            local row "`row' `jstr' (p=`pstr') |"
        }
    }
    di as result "`row'"

    * GMM criterion Q (both)
    foreach appr in simple verdier {
        local row "| Q (`appr') |"
        foreach cov in 0 trend 1 2 all {
            qui sum Q if country == "`country'" & spec == "`cov'" & approach == "`appr'"
            if r(N) == 0 | missing(r(mean)) {
                local row "`row' -- |"
            }
            else {
                local q = r(mean)
                local qstr = string(`q', "%9.2e")
                local row "`row' `qstr' |"
            }
        }
        di as result "`row'"
    }

    * Converged flags
    foreach appr in simple verdier {
        local row "| Converged (`appr') |"
        foreach cov in 0 trend 1 2 all {
            qui sum converged if country == "`country'" & spec == "`cov'" & approach == "`appr'"
            if r(N) == 0 {
                local row "`row' -- |"
            }
            else {
                local cvg = r(mean)
                local cvgstr = cond(`cvg' == 1, "Y", "N")
                local row "`row' `cvgstr' |"
            }
        }
        di as result "`row'"
    }

    * N
    foreach appr in simple verdier {
        local row "| N (`appr') |"
        foreach cov in 0 trend 1 2 all {
            qui sum N if country == "`country'" & spec == "`cov'" & approach == "`appr'"
            if r(N) == 0 {
                local row "`row' -- |"
            }
            else {
                local nn = r(mean)
                local nstr = string(`nn', "%10.0fc")
                local row "`row' `nstr' |"
            }
        }
        di as result "`row'"
    }
}

log close
capture translate "x_main_comparison_tables.smcl" "x_main_comparison_tables.txt", replace
exit, STATA clear
