* *******************************************************************
* Title:   Stage 6 gate: adjudicate leg A vs leg B identity, markers,
*          TZA continuity, and table regeneration
* Author:  Emilia Tjernstrom
* Date:    2026-07-20
* Purpose: Five checks. (1) Every leg B (fixed-code) ster is bitwise-
*          identical to its leg A (pre-fix code) counterpart, so the
*          sample-scoping fix is a no-op on today's data. (2) Every
*          parent ster in both legs carries an _esample.dta marker
*          with exactly e(N) rows. (3) Cross-leg marker equality via
*          cf (same pid-period fit sample either leg). (4) TZA
*          continuity: leg A vv_TZA_* sters bitwise-match the
*          retained stage5_root refits where present. (5) The fixed
*          tail produced all six verdier_robust tables plus three
*          GRC_*_cluster copies in leg B, while leg A (stale tail)
*          produced none. Run after both leg rc files exist.
* Input:   stage6_rootA/output, stage6_rootB/output,
*          stage5_root/output, gate_harness.do
* Output:  quality_reports/staging/stage6/{gate_results.csv,
*          marker_inventory.csv, tza_continuity.csv}
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* defines gate_compare and $stage0dir; manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/gate_stage6_compare_run.log", replace text

local legA     "C:/git/ckt/RP7/tests/stage0/stage6_rootA/output"
local legB     "C:/git/ckt/RP7/tests/stage0/stage6_rootB/output"
local stage5   "C:/git/ckt/RP7/tests/stage0/stage5_root/output"
local stagedir "C:/git/ckt/quality_reports/staging/stage6"
capture mkdir "`stagedir'"
global stage0dir "`stagedir'"

* ----------------------------------------------------------------
* 1. Leg B vs leg A: bitwise everywhere, no carve-outs
* ----------------------------------------------------------------
local results "`stagedir'/gate_results_raw.csv"
capture erase "`results'"

local sters : dir "`legB'" files "*.ster"
local n_sters : word count `sters'
if `n_sters' == 0 {
    di as error ">>> STAGE 6 GATE: no sters found in `legB'"
    exit 601
}
foreach f of local sters {
    local nm = subinstr("`f'", ".ster", "", .)
    gate_compare, estname(`nm') refit_ster("`legB'/`f'") ///
        basedir("`legA'") resultsfile("`results'")
}

import delimited using "`results'", clear varnames(1) stringcols(_all)
gen byte gate_fail = tier_verdict != "PASS_BITWISE"
export delimited using "`stagedir'/gate_results.csv", replace
quietly count if gate_fail
local n_fail_refit = r(N)
quietly count
local n_pairs = r(N)

* Missing-pair sweep: a leg A ster with no leg B counterpart
local stersA : dir "`legA'" files "*.ster"
local n_stersA : word count `stersA'
local n_missing_B = 0
foreach f of local stersA {
    capture confirm file "`legB'/`f'"
    if _rc != 0 {
        di as error "  leg A ster with no leg B counterpart: `f'"
        local ++n_missing_B
    }
}

* ----------------------------------------------------------------
* 2. Marker inventory, both legs: marker rows == parent e(N)
* ----------------------------------------------------------------
tempname MI
postfile `MI' str10 leg str60 estname long n_marker long n_fit ///
    str20 verdict using "`stagedir'/marker_inventory.dta", replace
local n_fail_marker = 0
local n_parents = 0
foreach leg in A B {
    local dir_ = cond("`leg'" == "A", "`legA'", "`legB'")
    local sters_ : dir "`dir_'" files "*.ster"
    foreach f of local sters_ {
        local nm = subinstr("`f'", ".ster", "", .)
        * suffix sters (_n/_a/_d/_g) rest on the parent fit, no marker
        if regexm(lower("`nm'"), "_(n|a|d|g)$") continue
        local ++n_parents
        quietly estimates use "`dir_'/`f'"
        local n_fit = e(N)
        capture confirm file "`dir_'/`nm'_esample.dta"
        if _rc != 0 {
            post `MI' ("`leg'") ("`nm'") (.) (`n_fit') ("MISSING_MARKER")
            local ++n_fail_marker
            continue
        }
        preserve
            quietly use "`dir_'/`nm'_esample.dta", clear
            local n_marker = _N
        restore
        if `n_marker' == `n_fit' {
            post `MI' ("`leg'") ("`nm'") (`n_marker') (`n_fit') ("PASS")
        }
        else {
            post `MI' ("`leg'") ("`nm'") (`n_marker') (`n_fit') ("COUNT_MISMATCH")
            local ++n_fail_marker
        }
    }
}
postclose `MI'
preserve
    use "`stagedir'/marker_inventory.dta", clear
    export delimited using "`stagedir'/marker_inventory.csv", replace
restore

* ----------------------------------------------------------------
* 3. Cross-leg marker equality: identical pid-period fit sample
*    (cf compares values, so the dta header timestamp is ignored)
* ----------------------------------------------------------------
local n_fail_mcf = 0
local n_mpairs = 0
local markersA : dir "`legA'" files "*_esample.dta"
foreach f of local markersA {
    capture confirm file "`legB'/`f'"
    if _rc != 0 {
        di as error "  marker missing in leg B: `f'"
        local ++n_fail_mcf
        continue
    }
    local ++n_mpairs
    preserve
        quietly use "`legA'/`f'", clear
        capture noisily cf _all using "`legB'/`f'"
        if _rc != 0 {
            di as error "  marker content differs across legs: `f'"
            local ++n_fail_mcf
        }
    restore
}

* ----------------------------------------------------------------
* 4. TZA continuity: leg A matches the retained stage5_root refits
* ----------------------------------------------------------------
local cont_results "`stagedir'/tza_continuity_raw.csv"
capture erase "`cont_results'"
local n_cont = 0
local n_fail_cont = 0
local stersT : dir "`stage5'" files "vv_TZA_*.ster"
foreach f of local stersT {
    local nm = subinstr("`f'", ".ster", "", .)
    capture confirm file "`legA'/`f'"
    if _rc != 0 continue
    local ++n_cont
    gate_compare, estname(`nm') refit_ster("`legA'/`f'") ///
        basedir("`stage5'") resultsfile("`cont_results'")
}
if `n_cont' > 0 {
    import delimited using "`cont_results'", clear varnames(1) stringcols(_all)
    quietly count if tier_verdict != "PASS_BITWISE"
    local n_fail_cont = r(N)
    export delimited using "`stagedir'/tza_continuity.csv", replace
}

* ----------------------------------------------------------------
* 5. Table regeneration: leg B has all nine .tex files; leg A none
* ----------------------------------------------------------------
local n_fail_tables = 0
foreach step in onestep twostep {
    foreach c in IDN TZA CHN {
        capture confirm file "`legB'/tables/verdier_robust_`step'_`c'_consumption_urban_unb.tex"
        if _rc != 0 {
            di as error "  leg B table missing: verdier_robust_`step'_`c'"
            local ++n_fail_tables
        }
    }
}
foreach c in IDN TZA CHN {
    capture confirm file "`legB'/tables/GRC_`c'_consumption_urban_unb_cluster.tex"
    if _rc != 0 {
        di as error "  leg B cluster copy missing: GRC_`c'"
        local ++n_fail_tables
    }
}
local texA : dir "`legA'/tables" files "*.tex"
local n_texA : word count `texA'
if `n_texA' != 0 {
    di as error "  leg A unexpectedly produced `n_texA' .tex files (stale tail should produce none)"
    local ++n_fail_tables
}

* ----------------------------------------------------------------
* Verdict
* ----------------------------------------------------------------
di as text _n "===== STAGE 6 GATE SUMMARY ====="
di as text "1. ster pairs compared:        `n_pairs' (missing in leg B: `n_missing_B'; non-bitwise: `n_fail_refit')"
di as text "2. parent markers checked:     `n_parents' (failures: `n_fail_marker')"
di as text "3. cross-leg marker cf pairs:  `n_mpairs' (failures: `n_fail_mcf')"
di as text "4. TZA continuity pairs:       `n_cont' (non-bitwise: `n_fail_cont')"
di as text "5. table check failures:       `n_fail_tables'"

if `n_fail_refit' + `n_missing_B' + `n_fail_marker' + `n_fail_mcf' ///
    + `n_fail_cont' + `n_fail_tables' == 0 {
    di as result ">>> STAGE 6 GATE: ALL PASS"
}
else {
    di as error ">>> STAGE 6 GATE: FAILURES PRESENT -- see counts above"
}

capture log close
