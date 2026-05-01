* Minimal repro for addlinespace fix --- single esttab call.
clear all
set more off
set varabbrev off

global dir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
global values "nominal"
quietly include "$dir/scripts/0_path_config.do"

capture log close
log using "$logs/test_addlinespace_minimal.smcl", replace

capture noisily {

local _stem grc_IDN_cuu
local covs2set c0 ct c1 c2 ca

foreach c in `covs2set' {
    quietly estimates use "$dir/output/`_stem'_`c'_n"
    quietly estimates store `_stem'_`c'_n
}

local ests_never ""
foreach c in `covs2set' {
    local ests_never "`ests_never' `_stem'_`c'_n"
}

di as text _newline "Sters loaded: `ests_never'"

* Inspect the e(b) matrix for one of them.
estimates restore grc_IDN_cuu_c0_n
matrix b = e(b)
matrix list b
di "b colnames: `: colnames b'"

* Variant A: existing pattern (coeflabels, no varlabels) --- should work.
di as text _newline "===> Variant A: coeflabels only"
esttab `ests_never'                    ///
using "$output/test_min_A.tex",        ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20)                           ///
nolines nomtitles                      ///
coeflabels(Delta_never "DN" Delta_always "DA") ///
replace substitute(\_ _)

* Variant B: explicit varlabels with both entries.
di as text _newline "===> Variant B: varlabels (Delta_never & Delta_always)"
esttab `ests_never'                    ///
using "$output/test_min_B.tex",        ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20)                           ///
nolines nomtitles                      ///
varlabels(Delta_never "DN" Delta_always "DA") ///
replace substitute(\_ _)

* Variant C: explicit varlabels with only Delta_never.
di as text _newline "===> Variant C: varlabels (Delta_never only)"
esttab `ests_never'                    ///
using "$output/test_min_C.tex",        ///
se b(%8.3f)                            ///
fragment booktabs noobs                ///
collabels("")                          ///
starlevels(* 0.10 ** 0.05 *** 0.01)    ///
varwidth(20)                           ///
nolines nomtitles                      ///
varlabels(Delta_never "DN")            ///
replace substitute(\_ _)

di as text _newline "===> Files written:"
ls "$output/test_min_*.tex"

}
local saved_rc = _rc
capture log close
exit, STATA clear
