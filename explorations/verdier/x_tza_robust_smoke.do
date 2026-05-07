* ============================================================
* Title:   TZA robust-spec smoke test (P1)
* Author:  Emilia (with Claude)
* Date:    2026-04-23
* Purpose: P1 verification gate for Verdier robust extrapolation.
*          Three GMM fits per P1 design:
*          1. run_grc          : simple spec, Stata default two-step
*                                (as currently published in CKT).
*          2. run_grc_onestep  : simple spec, onestep + winitial
*                                unadjusted independent. Apples-to-
*                                apples comparator for the robust spec.
*          3. run_grc_robust   : VV within-v-demeaning robust spec,
*                                onestep GMM, vindex(region).
*          Plus a degenerate-v test (vindex=v_one) that must match
*          run_grc_onestep to 6 decimals per derivation memo section 8.
*          Cluster-support diagnostics compared against the feasibility
*          note (TZA region: 21 clusters >=10 sw).
* Input:   data/processed/TZA_unb.dta
*          scripts/0_programs.do
* Output:  x_tza_robust_smoke.smcl / .txt log
*          $output/grc_TZA_covs_all_smoke.ster (simple, twostep)
*          $output/grc1_TZA_covs_all_smoke.ster (simple, onestep)
*          $output/grcr_TZA_covs_all_vone.ster (degenerate robust)
*          $output/grcr_TZA_covs_all_region.ster (robust, region)
*          (Filenames are short enough to fit Stata's 32-char _est_
*           prefix limit; grc1_ = "grc one-step", grcr_ = "grc robust".
*           Update plan P2 to use these conventions.)
* x_     : temporary smoke-test prefix; replaced by additive edits
*          to 5_GrRC.do in P2.
* ============================================================

clear all
set more off
set varabbrev off
capture log close

* ----------------------------------------------------------------
* Path bootstrap (mirrors 0_master.do for the active user)
* ----------------------------------------------------------------
if "`c(username)'" == "maand" {
    global dir "C:/git/ckt"
}
if "$dir" == "" {
    di as error "Set \$dir for your username in the header of this script."
    exit 198
}
include "$dir/scripts/0_path_config.do"

cd "$dir/explorations/verdier"
log using "x_tza_robust_smoke.smcl", replace text
version 17

* Suppress Overleaf copying during smoke test
global copyOverleaf 0

* Load utility programs (includes the new gen_vfirst,
* initial_values_robust, run_grc_onestep, run_grc_robust).
include "$dir/scripts/0_programs.do"

* ============================================================
* TZA setup (minimal slice of 5_GrRC.do)
* ============================================================
local country TZA
local choice  urban
local depvar  consumption
local balance unb

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* keepvars augmented with year + region (needed by gen_vfirst / vindex)
global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*
global keepvars $keepvars year region

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
sum ln*

setup_grc_estimation
keep $keepvars

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

local iterations 500

* ============================================================
* STEP 1: simple spec, Stata default two-step (as published)
* ============================================================
di as result _newline(2) "=== STEP 1: simple spec (run_grc, default two-step) ==="

initial_values lndepvar,     ///
    switchers($switchers)    ///
    balance(`balance')       ///
    estname(initial_`country'_smoke)
local base_simple    `r(base)'
local initial_simple "`r(initial)'"

run_grc, estname(grc_`country'_covs_all_smoke)                      ///
    switchers($switchers) base(`base_simple')                        ///
    initial(`initial_simple')                                        ///
    balance(`balance')                                               ///
    covars(`periodFE' $covs_gmm_all)                                 ///
    iterate(`iterations')

estimates use "$output/grc_`country'_covs_all_smoke"
di as result "run_grc (two-step): phi = " %8.4f _b[phi:_cons] ///
    ", se = " %8.4f _se[phi:_cons] ", converged = " e(converged)

* ============================================================
* STEP 2: simple spec, onestep (apples-to-apples comparator)
* ============================================================
di as result _newline(2) "=== STEP 2: simple spec (run_grc_onestep) ==="

run_grc_onestep, estname(grc1_`country'_covs_all_smoke)             ///
    switchers($switchers) base(`base_simple')                        ///
    initial(`initial_simple')                                        ///
    balance(`balance')                                               ///
    covars(`periodFE' $covs_gmm_all)                                 ///
    iterate(`iterations')

estimates use "$output/grc1_`country'_covs_all_smoke"
matrix b_onestep = e(b)
di as result "run_grc_onestep: phi = " %8.4f _b[phi:_cons] ///
    ", se = " %8.4f _se[phi:_cons] ", converged = " e(converged)

* ============================================================
* STEP 3: degenerate-v test (must match run_grc_onestep exactly)
* ============================================================
di as result _newline(2) "=== STEP 3: degenerate-v test (vindex=v_one) ==="

gen v_one = 1
label var v_one "Single-cluster indicator for degenerate-v test"

initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(`balance')              ///
    vindex(v_one)                   ///
    estname(initial_`country'_vone_smoke)
local base_vone    `r(base)'
local initial_vone "`r(initial)'"

run_grc_robust,                                              ///
    estname(grcr_`country'_covs_all_vone)                    ///
    switchers($switchers) base(`base_vone')                  ///
    initial(`initial_vone')                                  ///
    balance(`balance') vindex(v_one)                         ///
    covars(`periodFE' $covs_gmm_all)                         ///
    iterate(`iterations')

estimates use "$output/grcr_`country'_covs_all_vone"
matrix b_vone = e(b)
di as result "degenerate robust: phi = " %8.4f _b[phi:_cons] ///
    ", se = " %8.4f _se[phi:_cons] ", converged = " e(converged)

* ------------------------------------------------------------
* Compare degenerate robust to run_grc_onestep (NOT run_grc).
* Both use onestep + winitial unadjusted independent.
* Tolerance: 1e-6 (memo section 8, 6 decimals).
* ------------------------------------------------------------
di as result _newline(2) "=== Degenerate-v comparison (vs run_grc_onestep) ==="
local maxabs_diff = 0
local n_compared  = 0
local n_mismatch  = 0

local colnames_vone : colnames b_vone
foreach nm of local colnames_vone {
    local cn_o = colnumb(b_onestep, "`nm'")
    if missing(`cn_o') continue
    local cn_v = colnumb(b_vone,    "`nm'")
    local o_val = b_onestep[1, `cn_o']
    local v_val = b_vone[1, `cn_v']
    local diff  = abs(`o_val' - `v_val')
    local ++n_compared
    if `diff' > `maxabs_diff' {
        local maxabs_diff = `diff'
    }
    if `diff' > 1e-6 {
        local ++n_mismatch
        di as error "  MISMATCH: `nm'  onestep=" %12.8f `o_val' ///
            "  robust=" %12.8f `v_val' "  diff=" %12.2e `diff'
    }
}

di as text _newline(1) ///
    "  n_compared = `n_compared', " ///
    "n_mismatch(>1e-6) = `n_mismatch', " ///
    "max |diff| = " %12.2e `maxabs_diff'

* Report but do NOT abort on failure -- keeping the do-file alive so
* it reaches exit, STATA clear (no Windows batch popup).
if `n_mismatch' > 0 {
    di as error _newline "DEGENERATE-V TEST FAILED"
}
else {
    di as result _newline "DEGENERATE-V TEST PASSED (`n_compared' common parameters within 1e-6)"
}

* ============================================================
* STEP 4: robust fit with vindex(region)
* ============================================================
di as result _newline(2) "=== STEP 4: robust fit with vindex(region) ==="

* Reload TZA data to reset vfirst/vchoice_* state.
use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)

setup_grc_estimation
keep $keepvars

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values_robust lndepvar,     ///
    switchers($switchers)           ///
    balance(`balance')              ///
    vindex(region)                  ///
    estname(initial_`country'_region_smoke)
local base_region    `r(base)'
local initial_region "`r(initial)'"

run_grc_robust,                                              ///
    estname(grcr_`country'_covs_all_region)                  ///
    switchers($switchers) base(`base_region')                ///
    initial(`initial_region')                                ///
    balance(`balance') vindex(region)                        ///
    covars(`periodFE' $covs_gmm_all)                         ///
    iterate(`iterations')

estimates use "$output/grcr_`country'_covs_all_region"
di as result _newline "Robust (region) summary:"
di as result "  |V| clusters                = " e(V_clusters)
di as result "  |V| with >=10 switchers     = " e(V_ge10sw)
di as result "  |V| with sw & never support = " e(V_supp)
di as result "  phi                         = " %8.4f _b[phi:_cons]
di as result "  phi se (cluster vfirst)     = " %8.4f _se[phi:_cons]
di as result "  Converged                   = " e(converged_str)

* ============================================================
* P1 smoke test complete
* ============================================================
di as result _newline(2) "=== P1 smoke test complete ==="
di as result ///
    "See log for cluster-support diagnostics and phi estimates across the three specs."
di as result ///
    "Feasibility-note target (corrected helper): TZA region"
di as result ///
    "  clusters with >=10 switchers = 21 (out of 26 regions)"

log close

* Translate SMCL to plain text for easier reading
capture translate "x_tza_robust_smoke.smcl" "x_tza_robust_smoke.txt", replace

* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
