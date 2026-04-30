* ============================================================
* Title:   M4 (Phase 4) values(nominal|real) switch verification
* Author:  Emilia (with Claude)
* Date:    2026-05-01
* Purpose: Validate the M4 values switch end-to-end on a single
*          cell (grc_IDN_cub_c0). Four tests:
*            T1 (config):    $values=real -> $dirdata=$dir/data_real,
*                                            $vsfx="_r" (and the
*                                            nominal-mode reset works).
*            T2 (real fit):  fit grc_IDN_cub_c0 with $values=real;
*                            verify _r-suffixed sters land on disk;
*                            stash e(b), e(V), e(N).
*            T3 (nominal):   refit grc_IDN_cub_c0 with $values=nominal
*                            and bit-compare e(b)/e(V) against the
*                            pre-M4 ster on disk. Bit-identical proves
*                            M4's path-string edits don't perturb
*                            nominal numerics.
*            T4 (real != nominal): max abs diff between T2 and T3
*                            estimates --- should be large (>1e-3 in
*                            beta) since deflation rescales consumption.
*                            Validates that real mode actually reads
*                            different data, not just a path swap that
*                            happens to produce identical numbers.
*
* Input:   RP7/output/grc_IDN_cub_c0{,_n,_a,_d,_g}.ster (pre-M4 reference)
*          RP7/data/processed/IDN_bal.dta (nominal)
*          RP7/data_real/processed/IDN_bal.dta (deflated)
*          RP7/scripts/0_path_config.do (post-M4)
*          RP7/scripts/0_programs.do    (post-M4)
* Output:  RP7/output/verify_M4_values_summary.txt
*          RP7/output/verify_M4_values_*.ster (T2 real, T3 nominal refits)
*          RP7/scripts/logs/verify_M4_values.smcl
*
* Run via: cd RP7/scripts && stata-mp -b do ../../tests/verify_M4_values_switch.do
* Or via MCP `default` session: do "tests/verify_M4_values_switch.do"
* ============================================================

clear all
set more off
set varabbrev off

global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"

* Start in nominal mode for the baseline stash.
global values "nominal"
quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

capture log close
log using "$logs/verify_M4_values.smcl", replace

* ============================================================
* Stash pre-M4 nominal reference. Load main + _g sters; capture e(b),
* e(V), e(N), and the Delta_avg point estimate.
* ============================================================
estimates use "$output/grc_IDN_cub_c0.ster"
matrix b_pre_main = e(b)
matrix V_pre_main = e(V)
scalar N_pre = e(N)

estimates use "$output/grc_IDN_cub_c0_g.ster"
scalar Delta_avg_pre = _b[Delta_avg:_cons]

di as text "Pre-M4 reference stashed:"
di "  N_pre              = " N_pre
di "  Delta_avg_pre      = " %20.16e Delta_avg_pre

* ============================================================
* T1 --- config resolution. Toggle $values, re-include 0_path_config,
* check that $dirdata and $vsfx wire up correctly in both directions.
* ============================================================
di as text _newline "===> T1: config resolution"

global values "real"
quietly include "$dir/scripts/0_path_config.do"
local t1a_dirdata "$dirdata"
local t1a_vsfx "$vsfx"

global values "nominal"
quietly include "$dir/scripts/0_path_config.do"
local t1b_dirdata "$dirdata"
local t1b_vsfx "$vsfx"

di "  real-mode  : dirdata = `t1a_dirdata' ; vsfx = '`t1a_vsfx''"
di "  nominal    : dirdata = `t1b_dirdata' ; vsfx = '`t1b_vsfx''"

local t1_pass = ("`t1a_dirdata'" == "$dir/data_real") & ("`t1a_vsfx'" == "_r") ///
              & ("`t1b_dirdata'" == "$dir/data") & ("`t1b_vsfx'" == "")
di "  T1 result  : " cond(`t1_pass', "PASS", "FAIL")

* ============================================================
* Cub-section globals (mirror 5_GrRC.do L284-299). Used by both T2
* and T3 fits so the only difference is the data folder $values
* points at.
* ============================================================
local choice  urban
local depvar  consumption
local balance bal

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* ============================================================
* T2 --- real-mode fit of grc_IDN_cub_c0.
* ============================================================
di as text _newline "===> T2: real-mode fit start: " c(current_time)

global values "real"
quietly include "$dir/scripts/0_path_config.do"
di "  fit reads from: $dirdata"

local country IDN
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)
quietly setup_grc_estimation
keep $keepvars
quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_real_`country')
local base `r(base)'
local initial "`r(initial)'"
local iterations $grc_max_iter

run_grc, estname(verify_M4_values_real_`country'_cub_c0)              ///
    switchers($switchers) base(`base') initial(`initial')             ///
    balance(`balance') iterate(`iterations')

* The _r suffix is appended INSIDE run_grc via ${vsfx}, so the disk
* file is verify_M4_values_real_IDN_cub_c0_r.ster.
quietly estimates use "$output/verify_M4_values_real_IDN_cub_c0_r.ster"
matrix b_real_main = e(b)
matrix V_real_main = e(V)
scalar N_real = e(N)
quietly estimates use "$output/verify_M4_values_real_IDN_cub_c0_g_r.ster"
scalar Delta_avg_real = _b[Delta_avg:_cons]

di "  N_real             = " N_real
di "  Delta_avg_real     = " %20.16e Delta_avg_real

* T2 success conditions: ster files exist on disk with _r suffix; e(N)>0.
capture confirm file "$output/verify_M4_values_real_IDN_cub_c0_r.ster"
local t2_main_exists = (_rc == 0)
capture confirm file "$output/verify_M4_values_real_IDN_cub_c0_g_r.ster"
local t2_g_exists = (_rc == 0)
local t2_pass = `t2_main_exists' & `t2_g_exists' & (N_real > 0)
di "  T2 result          : " cond(`t2_pass', "PASS", "FAIL")

* ============================================================
* T3 --- nominal-mode refit of grc_IDN_cub_c0; bit-compare against
* pre-M4 stashed reference.
* ============================================================
di as text _newline "===> T3: nominal-mode refit start: " c(current_time)

global values "nominal"
quietly include "$dir/scripts/0_path_config.do"
di "  fit reads from: $dirdata"

local country IDN
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)
quietly setup_grc_estimation
keep $keepvars
quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar, switchers($switchers) balance(`balance') estname(initial_nominal_`country')
local base `r(base)'
local initial "`r(initial)'"

run_grc, estname(verify_M4_values_nominal_`country'_cub_c0)            ///
    switchers($switchers) base(`base') initial(`initial')              ///
    balance(`balance') iterate(`iterations')

quietly estimates use "$output/verify_M4_values_nominal_IDN_cub_c0.ster"
matrix b_nom_main = e(b)
matrix V_nom_main = e(V)
scalar N_nom = e(N)
quietly estimates use "$output/verify_M4_values_nominal_IDN_cub_c0_g.ster"
scalar Delta_avg_nom = _b[Delta_avg:_cons]

di "  N_nom              = " N_nom
di "  Delta_avg_nom      = " %20.16e Delta_avg_nom

* T3 bit-compare against the pre-M4 reference.
matrix dB_nom = b_nom_main - b_pre_main
matrix dV_nom = V_nom_main - V_pre_main
mata: max_abs_b_nom = max(abs(st_matrix("dB_nom")))
mata: max_abs_V_nom = max(abs(st_matrix("dV_nom")))
local mrel_b_nom = mreldif(b_nom_main, b_pre_main)
local mrel_V_nom = mreldif(V_nom_main, V_pre_main)

mata: st_local("max_abs_b_nom", strofreal(max_abs_b_nom, "%22.16e"))
mata: st_local("max_abs_V_nom", strofreal(max_abs_V_nom, "%22.16e"))

di "  max |dB_nom|       = `max_abs_b_nom'"
di "  max |dV_nom|       = `max_abs_V_nom'"
di "  mreldif(b_nom)     = `mrel_b_nom'"
di "  mreldif(V_nom)     = `mrel_V_nom'"

local t3_pass = (`mrel_b_nom' == 0) & (`mrel_V_nom' == 0)
di "  T3 result          : " cond(`t3_pass', "PASS (bit-identical)", "FAIL")

* ============================================================
* T4 --- real != nominal. Compare T2 and T3 estimates; expect
* meaningful differences because deflation rescales consumption.
* Expectation: max abs diff in beta > 1e-3 and Delta_avg differs.
* ============================================================
di as text _newline "===> T4: real != nominal check"

matrix dB_rn = b_real_main - b_nom_main
mata: max_abs_b_rn = max(abs(st_matrix("dB_rn")))
local mrel_b_rn = mreldif(b_real_main, b_nom_main)
mata: st_local("max_abs_b_rn", strofreal(max_abs_b_rn, "%22.16e"))

scalar Delta_avg_diff = Delta_avg_real - Delta_avg_nom

di "  max |b_real - b_nom|     = `max_abs_b_rn'"
di "  mreldif(b_real, b_nom)   = `mrel_b_rn'"
di "  Delta_avg(real - nom)    = " %20.16e Delta_avg_diff
di "  N_real vs N_nom          = " N_real " vs " N_nom

* T4 passes if estimates differ. Threshold deliberately loose: a
* meaningful real-mode change should produce mreldif > 1e-6.
local t4_pass = (`mrel_b_rn' > 1e-6)
di "  T4 result          : " cond(`t4_pass', "PASS (estimates differ)", "FAIL (estimates identical --- bug)")

* ============================================================
* Persist a summary file
* ============================================================
mata:
fh = fopen(st_global("output") + "/verify_M4_values_summary.txt", "w")
fput(fh, "M4 (Phase 4) values(nominal|real) switch verification")
fput(fh, sprintf("Run: %s", c("current_time")))
fput(fh, "")
fput(fh, sprintf("T1 config:       %s", strofreal(st_local("t1_pass"))))
fput(fh, sprintf("T2 real fit:     %s   (N=%s, Delta_avg=%s)",
                 strofreal(st_local("t2_pass")),
                 strofreal(st_numscalar("N_real")),
                 strofreal(st_numscalar("Delta_avg_real"), "%22.16e")))
fput(fh, sprintf("T3 nominal:      %s   (N=%s, Delta_avg=%s, mreldif b=%s)",
                 strofreal(st_local("t3_pass")),
                 strofreal(st_numscalar("N_nom")),
                 strofreal(st_numscalar("Delta_avg_nom"), "%22.16e"),
                 st_local("mrel_b_nom")))
fput(fh, sprintf("T4 real != nom:  %s   (mreldif=%s, max|dB|=%s)",
                 strofreal(st_local("t4_pass")),
                 st_local("mrel_b_rn"),
                 st_local("max_abs_b_rn")))
fput(fh, "")
fput(fh, sprintf("Pre-M4 reference: N=%s, Delta_avg=%s",
                 strofreal(st_numscalar("N_pre")),
                 strofreal(st_numscalar("Delta_avg_pre"), "%22.16e")))
fclose(fh)
end

di ""
type "$output/verify_M4_values_summary.txt"

log close
