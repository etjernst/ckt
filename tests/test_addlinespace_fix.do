* ============================================================
* Title:   Test: blank-row + addlinespace fix in grc_tex_table_trend
* Author:  Emilia (with Claude)
* Date:    2026-05-01
* Purpose: Empirically test whether passing explicit varlabels()
*          to the first two esttab calls (Delta_never, Delta_avg)
*          suppresses the blank tabular row at end-of-block while
*          preserving the inter-block \addlinespace.
*
*          Sister to a planned change in grc_tex_table_trend
*          (RP7/scripts/0_programs.do lines 2989--3029).
*
* Method:  Run the current esttab pattern AND the proposed fix on
*          the SAME sters (grc_IDN_cuu_{c0,ct,c1,c2,ca}). Emit two
*          .tex files; diff them externally.
*
* Input:   RP7/output/grc_IDN_cuu_<covs2>{,_n,_g}.ster (existing)
* Output:  RP7/output/test_addlinespace_baseline.tex
*          RP7/output/test_addlinespace_fix.tex
* ============================================================

clear all
set more off
set varabbrev off

global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
global values "nominal"
quietly include "$dir/scripts/0_path_config.do"

capture log close
log using "$logs/test_addlinespace_fix.smcl", replace

capture noisily {

* ------------------------------------------------------------
* Load the five sters into memory under their stored names.
* ------------------------------------------------------------
local _stem grc_IDN_cuu
local covs2set c0 ct c1 c2 ca

foreach c in `covs2set' {
    quietly estimates use "$dir/output/`_stem'_`c'"
    quietly estimates store `_stem'_`c'
    quietly estimates use "$dir/output/`_stem'_`c'_n"
    quietly estimates store `_stem'_`c'_n
    quietly estimates use "$dir/output/`_stem'_`c'_g"
    quietly estimates store `_stem'_`c'_g
}

local ests_never ""
local ests_avg ""
local ests ""
foreach c in `covs2set' {
    local ests_never "`ests_never' `_stem'_`c'_n"
    local ests_avg   "`ests_avg' `_stem'_`c'_g"
    local ests       "`ests' `_stem'_`c'"
}

local prehead `"\begin{tabular}{l ccccc} \toprule  \textbf{Dep. var:}  log(consumption)"'
local postfoot `"\cmidrule{2-6} Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\ \bottomrule \end{tabular}"'

local keep phi
local varlabel "$\phi$"

* ============================================================
* CURRENT BEHAVIOR --- replicate the three esttab calls verbatim
* ============================================================
di as text _newline "===> Generating baseline (current pattern)"

capture noisily {

esttab `ests_never'                    ///
using "$output/test_addlinespace_baseline.tex", ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20) 	                       ///
nolines nomtitles                      ///
prehead(`prehead')                     ///
posthead("")                           ///
coeflabels(Delta_never "$\Delta_{\text{never}}$" Delta_always "$\Delta_{\text{always}}$") ///
replace substitute(\_ _)

esttab `ests_avg'   		           ///
using "$output/test_addlinespace_baseline.tex", ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20) 	                       ///
nolines nomtitles nonum 		       ///
coeflabels(Delta_avg "$\bar{\Delta}$") ///
append substitute(\_ _)

esttab `ests'	                       ///
using "$output/test_addlinespace_baseline.tex", ///
se b(%8.3f)                            ///
keep(`keep')                           ///
varlabels(`keep' "`varlabel'")         ///
eqlabels(none)				           ///
fragment booktabs                      ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
s(N_clust N Jstat Jpval converged_str, label( "Individuals" "Observations" "J-stat" "J-stat (p-value)" "Converged") ///
fmt(%9.0fc %9.0fc %8.1fc %8.3fc %8.0fc))      ///
varwidth(20)                           ///
nolines nomtitles nonum                ///
postfoot("`postfoot'")                 ///
append substitute(\_ _)

}
di as text "  baseline rc=`=_rc'"

capture noisily {

* ============================================================
* PROPOSED FIX --- pass explicit varlabels() to esttab #1 and #2
* (mirroring how esttab #3 already does it). Bypasses the
* auto-end("" midgap) injection at line 928 of esttab.ado.
* ============================================================
di as text _newline "===> Generating fix variant (explicit varlabels)"

esttab `ests_never'                    ///
using "$output/test_addlinespace_fix.tex", ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20) 	                       ///
nolines nomtitles                      ///
prehead(`prehead')                     ///
posthead("")                           ///
coeflabels(Delta_never "$\Delta_{\text{never}}$") ///
replace substitute(\_ _)

esttab `ests_avg'   		           ///
using "$output/test_addlinespace_fix.tex", ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20) 	                       ///
nolines nomtitles nonum 		       ///
varlabels(Delta_avg "$\bar{\Delta}$")  ///
append substitute(\_ _)

esttab `ests'	                       ///
using "$output/test_addlinespace_fix.tex", ///
se b(%8.3f)                            ///
keep(`keep')                           ///
varlabels(`keep' "`varlabel'")         ///
eqlabels(none)				           ///
fragment booktabs                      ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
s(N_clust N Jstat Jpval converged_str, label( "Individuals" "Observations" "J-stat" "J-stat (p-value)" "Converged") ///
fmt(%9.0fc %9.0fc %8.1fc %8.3fc %8.0fc))      ///
varwidth(20)                           ///
nolines nomtitles nonum                ///
postfoot("`postfoot'")                 ///
append substitute(\_ _)

}
di as text "  fix rc=`=_rc'"

di as text _newline "===> DONE. Diff the two outputs to compare:"
di "  $output/test_addlinespace_baseline.tex"
di "  $output/test_addlinespace_fix.tex"

}
local saved_rc = _rc
capture log close

exit, STATA clear
