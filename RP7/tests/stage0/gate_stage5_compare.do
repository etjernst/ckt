* *******************************************************************
* Title:   Stage 5 gate: adjudicate refit identity, marker inventory,
*          and cross-leg attach equality
* Author:  Emilia Tjernstrom
* Date:    2026-07-19
* Purpose: Three checks, all of which must pass with no exceptions.
*          (1) Every Stage 5 refit ster is bitwise-identical to its
*          stage34_root/output counterpart (the marker write cannot
*          touch the fit). (2) Every parent ster carries an
*          _esample.dta marker whose row count equals its e(N).
*          (3) For every inversion cell, the leg A (fallback,
*          old computation) and leg B (marker path, new mainline)
*          attached results are identical: all inv_* scalars, both CI
*          strings, and bitwise e(b), on the parent and each attached
*          suffix. Run after gate_stage5_attach.do reports rc=0.
* Input:   stage5_root/output, stage34_root/output, stage5_legA_output,
*          stage5_legB_output, gate_harness.do
* Output:  quality_reports/staging/stage5/{gate_results.csv,
*          marker_inventory.csv, attach_compare.csv}
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

* defines gate_compare and $stage0dir; manages its own log
do "C:/git/ckt/RP7/tests/stage0/gate_harness.do"

capture log close
log using "C:/git/ckt/RP7/tests/stage0/gate_stage5_compare_run.log", replace text

local base     "C:/git/ckt/RP7/tests/stage0/stage34_root/output"
local refit    "C:/git/ckt/RP7/tests/stage0/stage5_root/output"
local legA     "C:/git/ckt/RP7/tests/stage0/stage5_legA_output"
local legB     "C:/git/ckt/RP7/tests/stage0/stage5_legB_output"
local stagedir "C:/git/ckt/quality_reports/staging/stage5"
capture mkdir "`stagedir'"
global stage0dir "`stagedir'"

* ----------------------------------------------------------------
* 1. Refit vs stage34 baseline: bitwise everywhere, no carve-outs
* ----------------------------------------------------------------
local results "`stagedir'/gate_results_raw.csv"
capture erase "`results'"

local sters : dir "`refit'" files "*.ster"
local n_sters : word count `sters'
if `n_sters' == 0 {
    di as error ">>> STAGE 5 GATE: no sters found in `refit'"
    exit 601
}
foreach f of local sters {
    local nm = subinstr("`f'", ".ster", "", .)
    gate_compare, estname(`nm') refit_ster("`refit'/`f'") ///
        basedir("`base'") resultsfile("`results'")
}

import delimited using "`results'", clear varnames(1) stringcols(_all)
gen byte gate_fail = tier_verdict != "PASS_BITWISE"
export delimited using "`stagedir'/gate_results.csv", replace
quietly count if gate_fail
local n_fail_refit = r(N)
quietly count
local n_pairs = r(N)

* ----------------------------------------------------------------
* 2. Marker inventory: every parent ster has a marker with e(N) rows
* ----------------------------------------------------------------
tempname MI
postfile `MI' str60 estname long n_marker long n_fit str20 verdict ///
    using "`stagedir'/marker_inventory.dta", replace
local n_fail_marker = 0
local n_parents = 0
foreach f of local sters {
    local nm = subinstr("`f'", ".ster", "", .)
    * suffix sters (_n/_a/_d/_g) rest on the parent fit and get no marker
    if regexm(lower("`nm'"), "_(n|a|d|g)$") continue
    local ++n_parents
    quietly estimates use "`refit'/`f'"
    local n_fit = e(N)
    capture confirm file "`refit'/`nm'_esample.dta"
    if _rc != 0 {
        post `MI' ("`nm'") (.) (`n_fit') ("MISSING_MARKER")
        local ++n_fail_marker
        continue
    }
    preserve
        quietly use "`refit'/`nm'_esample.dta", clear
        local n_marker = _N
    restore
    if `n_marker' == `n_fit' post `MI' ("`nm'") (`n_marker') (`n_fit') ("PASS")
    else {
        post `MI' ("`nm'") (`n_marker') (`n_fit') ("COUNT_MISMATCH")
        local ++n_fail_marker
    }
}
postclose `MI'
preserve
    use "`stagedir'/marker_inventory.dta", clear
    export delimited using "`stagedir'/marker_inventory.csv", replace
restore

* ----------------------------------------------------------------
* 3. Leg A vs leg B: identical attached results per inversion cell
* ----------------------------------------------------------------
local cells ""
foreach c in IDN TZA CHN CHN_rf CHN_uf {
    foreach covs2 in ct c1 c2 ca {
        local cells "`cells' grc_`c'_cuu_`covs2'"
    }
}

local scalars ""
foreach p in inv_phi inv_dN inv_davg inv_dT {
    foreach s in at_waldmin wald_min J_R n_kept ci90_lo ci90_hi ///
                 ci95_lo ci95_hi island_count95 island_count90 {
        local scalars "`scalars' `p'_`s'"
    }
}

tempname AC
postfile `AC' str60 estname str8 suffix long n_scalar_diff ///
    long n_string_diff double max_b_absdiff str20 verdict ///
    using "`stagedir'/attach_compare.dta", replace
local n_fail_attach = 0
foreach cell of local cells {
    foreach sfx in "" "_n" "_g" "_a" {
        capture confirm file "`legA'/`cell'`sfx'.ster"
        if _rc != 0 {
            * cells 5b/5c skipped (no parent ster) simply do not appear
            continue
        }
        quietly estimates use "`legA'/`cell'`sfx'.ster"
        foreach s of local scalars {
            scalar __A_`s' = e(`s')
        }
        local A_str90 `"`e(inv_phi_ci90_str)'"'
        local A_str95 `"`e(inv_phi_ci95_str)'"'
        matrix __bA = e(b)

        quietly estimates use "`legB'/`cell'`sfx'.ster"
        local ndiff = 0
        foreach s of local scalars {
            local eq = (scalar(__A_`s') == e(`s')) | ///
                (missing(scalar(__A_`s')) & missing(e(`s')))
            if !`eq' local ++ndiff
        }
        local sdiff = 0
        if `"`A_str90'"' != `"`e(inv_phi_ci90_str)'"' local ++sdiff
        if `"`A_str95'"' != `"`e(inv_phi_ci95_str)'"' local ++sdiff
        matrix __bB = e(b)
        mata: st_numscalar("__bd", max(abs(st_matrix("__bA") - st_matrix("__bB"))))
        local verdict = cond(`ndiff'==0 & `sdiff'==0 & scalar(__bd)==0, ///
            "PASS", "LEG_DIVERGENCE")
        if "`verdict'" != "PASS" local ++n_fail_attach
        post `AC' ("`cell'") ("`sfx'") (`ndiff') (`sdiff') ///
            (scalar(__bd)) ("`verdict'")
    }
}
postclose `AC'
preserve
    use "`stagedir'/attach_compare.dta", clear
    export delimited using "`stagedir'/attach_compare.csv", replace
    quietly count
    local n_attach_pairs = r(N)
    quietly count if verdict == "PASS"
    di as text "attach cells compared (cell x suffix): `n_attach_pairs', PASS: " r(N)
restore

* ----------------------------------------------------------------
* Verdict
* ----------------------------------------------------------------
di as text _newline "{hline 72}"
if `n_fail_refit' == 0 di as result ">>> refit identity: all `n_pairs' ster pairs PASS_BITWISE"
else                   di as error  ">>> refit identity: `n_fail_refit' of `n_pairs' pairs FAIL"
if `n_fail_marker' == 0 di as result ">>> marker inventory: all `n_parents' parent fits carry e(N)-row markers"
else                    di as error  ">>> marker inventory: `n_fail_marker' of `n_parents' parents FAIL"
if `n_fail_attach' == 0 di as result ">>> attach legs: identical results on every compared cell"
else                    di as error  ">>> attach legs: `n_fail_attach' cell-suffix pairs DIVERGE"
if `n_fail_refit' + `n_fail_marker' + `n_fail_attach' == 0 {
    di as result ">>> STAGE 5 GATE: PASS"
}
else {
    di as error ">>> STAGE 5 GATE: FAIL"
}
di as text "{hline 72}"

log close
