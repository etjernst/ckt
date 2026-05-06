* ============================================================
* Title:   M4 verification --- duplicate mu-loop cleanup
* Author:  Emilia (with Claude)
* Date:    2026-04-30
* Purpose: Bit-compare a production GRC cell estimated under the OLD
*          (pre-M4) initial_values code against a refit under the
*          NEW (post-M4, commit d2b0c73) code.
* Input:   RP7/output/grc_CHN_cub_c0.ster   (pre-M4 reference)
*          RP7/data/processed/CHN_bal.dta
*          RP7/scripts/0_path_config.do
*          RP7/scripts/0_programs.do        (post-M4 cleanup)
* Output:  RP7/output/verify_M4_CHN_cub_c0*.ster (5 sters, refit)
*          RP7/output/verify_M4_b_compare.txt    (param-by-param dump)
*          Console: max abs diff and mreldif on b and V.
* ============================================================

clear all
set more off
set varabbrev off

* Reproduce the worktree path. Adjust if running from a different tree.
global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"

quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

* Reference: load pre-M4 ster, stash e(b) and e(V).
estimates use "$output/grc_CHN_cub_c0.ster"
matrix b_ref_M4 = e(b)
matrix V_ref_M4 = e(V)

* Mirror 5_GrRC.do cub section pre-amble (L284-299).
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

* Mirror 5_GrRC.do CHN block (L450-493).
local country CHN
quietly use "$dirdata/processed/`country'_`balance'.dta", clear
quietly replace lndepvar = log(consumption/hhsize_cube)

quietly setup_grc_estimation
keep $keepvars

quietly tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar,       ///
    switchers($switchers)      ///
    balance(`balance')         ///
    estname(initial_`country')

local base `r(base)'
scalar base_`country' = `base'
local initial "`r(initial)'"
local iterations $grc_max_iter

run_grc, estname(verify_M4_CHN_cub_c0)                             ///
    switchers($switchers) base(`base') initial(`initial')          ///
    balance(`balance')                                             ///
    iterate(`iterations')

* Compare new fit against the stashed reference.
matrix b_new = e(b)
matrix V_new = e(V)

matrix dB = b_new - b_ref_M4
matrix dV = V_new - V_ref_M4
mata: max_abs_b = max(abs(st_matrix("dB")))
mata: max_abs_V = max(abs(st_matrix("dV")))
mata: st_local("max_abs_b", strofreal(max_abs_b, "%24.18e"))
mata: st_local("max_abs_V", strofreal(max_abs_V, "%24.18e"))

di ""
di "=== M4 verification result ==="
di "max |b_new - b_ref| = `max_abs_b'"
di "max |V_new - V_ref| = `max_abs_V'"
di "mreldif(b_new, b_ref_M4) = " mreldif(b_new, b_ref_M4)
di "mreldif(V_new, V_ref_M4) = " mreldif(V_new, V_ref_M4)
di "ref N: 56855  new N: " e(N)

* Persist a parameter-by-parameter audit trail.
mata:
b_ref_export = st_matrix("b_ref_M4")
b_new_export = st_matrix("b_new")
names_export = st_matrixcolstripe("b_ref_M4")
fh = fopen(st_global("output") + "/verify_M4_b_compare.txt", "w")
fput(fh, "param_eq:param_name | b_ref (pre-M4)        | b_new (post-M4)       | diff")
fput(fh, "-----------------------------------------------------------------------------")
for (i=1; i<=cols(b_ref_export); i++) {
    label_export = names_export[i,1] + ":" + names_export[i,2]
    line_export = sprintf("%-22s | %22.16e | %22.16e | %12.2e",
                          label_export,
                          b_ref_export[1,i],
                          b_new_export[1,i],
                          b_new_export[1,i] - b_ref_export[1,i])
    fput(fh, line_export)
}
fclose(fh)
end

di ""
di "Audit trail at: $output/verify_M4_b_compare.txt"
