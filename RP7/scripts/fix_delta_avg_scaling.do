* fix_delta_avg_scaling.do
* ---------------------------------------------------------------------
* Purpose: post-hoc rescaling of Delta_avg in already-saved _g.ster files
*          to correct the buggy formula that gave Delta_avg_buggy =
*          switcher_frac * E[Delta | switcher] instead of E[Delta | switcher].
*
* Architecture: writes a sidecar CSV at $output/delta_avg_rescaled.csv with
* one row per cell containing (estname, sw_frac, b_buggy, se_buggy,
* b_rescaled, se_rescaled). Dashboard / downstream tools read this CSV when
* they need a corrected Delta_avg without re-running nlcom.
*
* Background: 0_programs.do had four mirror copies of
*     sum 1.switcher_`s' if e(sample); local num_`s' = r(mean)
* which gave N_s/N_total (sums to switcher_frac, ~4-11%) rather than
* N_s/N_switchers (sums to 1). The nlcom expression is exactly linear in
* those weights, so:
*     b_correct  = b_buggy / switcher_frac
*     SE_correct = SE_buggy / switcher_frac
*     z_correct  = z_buggy   (invariant)
* See lca-inversion commit 5cfe158 for the upstream fix.
*
* Why CSV instead of in-place .ster mutation: ereturn post + estimates save
* did not round-trip through Stata's estimation context after `estimates
* use` of an nlcom-posted ster (rc=301 "last estimates not found" on save,
* rc=152 on `ereturn repost`). Sidecar CSV avoids touching the binary
* .ster files entirely and keeps the buggy values inspectable as a paper
* trail.
*
* This script overrides `run_grc` to skip fitting and instead append a row
* to the sidecar CSV per cell. It then includes 4_GrRC.do, 5_GrRC_NonAg.do,
* and 7_GrRC_hukou.do to walk the cell list using their own enumeration.
*
* Run AFTER applying the 4-line fix to 0_programs.do but BEFORE relaunching
* the master pipeline. The fix in 0_programs.do ensures any future re-fits
* compute Delta_avg correctly from the start; this CSV sidecar handles the
* legacy cells from this run that already have buggy _g.sters.
* ---------------------------------------------------------------------

clear all
version 17
set more off

global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
include "$dir/scripts/0_path_config.do"
quietly include "$scripts/0_setup.do"
quietly include "$scripts/0_programs.do"

* Disable Overleaf copies during this rescaling pass
global copyOverleaf 0

* Sidecar CSV: header on first run, append rows from each cell.
local sidecar "$output/delta_avg_rescaled.csv"
file open _sc using "`sidecar'", write replace
file write _sc "estname,sw_frac,scale,b_buggy,se_buggy,b_rescaled,se_rescaled" _n
file close _sc

* ---------------------------------------------------------------------
* Override: run_grc as a Delta_avg sidecar writer
* ---------------------------------------------------------------------
capture program drop run_grc
program define run_grc
    syntax , estname(string) switchers(numlist) base(numlist) balance(string) ///
             [covars(varlist) iterate(numlist) initial(string) phistart(real -0.1)]

    local g_path "$output/`estname'_g${vsfx}.ster"
    capture confirm file "`g_path'"
    if _rc != 0 {
        di as text "rescale: SKIP `estname' (no _g.ster on disk)"
        exit
    }

    * Surrogate regression to define a sample matching the GMM's:
    qui reg lndepvar never always switcher_* `covars' if !missing(choice)
    qui count if e(sample) & switcher == 1
    local n_sw = r(N)
    qui count if e(sample)
    local n_tot = r(N)
    if `n_tot' == 0 | `n_sw' == 0 {
        di as error "rescale: `estname' empty surrogate-regression sample --- skipping"
        exit
    }
    local sw_frac = `n_sw' / `n_tot'
    local scale = 1 / `sw_frac'

    * Read the buggy b and V from _g.ster.
    estimates use "`g_path'"
    matrix _b_buggy = e(b)
    matrix _V_buggy = e(V)
    local b_buggy  = _b_buggy[1, 1]
    local se_buggy = sqrt(_V_buggy[1, 1])
    local b_resc   = `b_buggy'  * `scale'
    local se_resc  = `se_buggy' * `scale'

    * Append to sidecar CSV.
    file open _sc using "$output/delta_avg_rescaled.csv", write append
    file write _sc "`estname',`sw_frac',`scale',`b_buggy',`se_buggy',`b_resc',`se_resc'" _n
    file close _sc

    di as text "rescale: `estname' " ///
                "sw_frac=" %6.4f `sw_frac' " scale=" %7.3f `scale' ///
                " | b: " %8.4f `b_buggy' " (" %7.4f `se_buggy' ")" ///
                " --> " %8.4f `b_resc' " (" %7.4f `se_resc' ")"
end

* ---------------------------------------------------------------------
* Walk the cell list by including the original drivers.
* ---------------------------------------------------------------------
include "$dir/scripts/4_GrRC.do"
include "$dir/scripts/5_GrRC_NonAg.do"
include "$dir/scripts/7_GrRC_hukou.do"

di as text "DONE: see $output/delta_avg_rescaled.csv"
