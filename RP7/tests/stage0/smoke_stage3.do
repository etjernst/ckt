* *******************************************************************
* Title:   Stage 3 smoke test: build-time GRC scaffolding
* Author:  Emilia Tjernstrom
* Date:    2026-07-17
* Purpose: Verify the Stage 3 front-end changes on three cells built
*          in memory (IDN unb consumption, TZA unb consumption, IDN
*          unb income): scaffolding dummies and trajectory-contract
*          characteristics exist, the estimable-sample drop removes
*          exactly the missing-logpc person-waves, trajectory keeps
*          missing (not 999) in built data, dummies match the old
*          load-time construction on the canonical hub row by row,
*          and setup_grc_estimation reads the contract back.
* Input:   RP7/data/countries (raw), RP7/data/processed (canonical hub)
* Output:  none (assertions only; log is the artifact)
* *******************************************************************

clear all
version 17
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"

include "$dir/scripts/0_path_config.do"
include "$dir/scripts/0_programs.do"

capture noisily {

* ----------------------------------------------------------------
* Cell 1: IDN unb consumption (588 missing-logpc person-waves)
* ----------------------------------------------------------------
* Old-side reference: canonical hub cell + the pre-Stage-3 load-time
* scaffolding, then the same estimable-sample restriction.
use "$dirdata/processed/IDN_unb.dta", clear
assert _N == 93038
quietly tab trajectory
local always_o = r(r)
local last_o = `always_o'-1
numlist "2(1)`last_o'"
local switchers_o "`r(numlist)'"
gen always_o = (trajectory == `always_o')
gen always_choice_o = always_o*choice
gen never_o = (trajectory == 1)
foreach s of numlist `switchers_o' {
    gen switcher_`s'_o = (trajectory == `s')
    gen switcher_`s'_choice_o = switcher_`s'_o*choice
}
drop if mi(logpc_consumption)
assert _N == 92450
rename trajectory trajectory_o
rename logpc_consumption logpc_o
keep pid period trajectory_o logpc_o always_o always_choice_o never_o switcher_*_o switcher_*_choice_o
tempfile oldside
save `oldside'

* New-side: full front-end build in memory
data_setup IDN urban consumption unb
assert _N == 92450
assert !mi(logpc_consumption)
assert trajectory != 999
count if mi(trajectory)
assert r(N) > 0
local sw : char _dta[grc_switchers]
local aw : char _dta[grc_always]
assert "`sw'" == "`switchers_o'"
assert "`aw'" == "`always_o'"

* Row-by-row equality of outcome, trajectory, and every dummy
merge 1:1 pid period using `oldside', assert(3) nogen
assert logpc_consumption == logpc_o
assert trajectory == trajectory_o | (mi(trajectory) & mi(trajectory_o))
assert always == always_o
assert always_choice == always_choice_o
assert never == never_o
foreach s of numlist `sw' {
    assert switcher_`s' == switcher_`s'_o
    assert switcher_`s'_choice == switcher_`s'_choice_o
}
di as text ">>> IDN unb consumption: PASS (N=92450, contract `sw' | `aw')"

* Reader: globals repopulated from the contract, 999 recode applied
setup_grc_estimation
assert "$switchers" == "`switchers_o'"
assert "$always" == "`always_o'"
assert "$never" == "1"
count if trajectory == 999
assert r(N) > 0
count if mi(trajectory)
assert r(N) == 0
di as text ">>> setup_grc_estimation reader: PASS"

* ----------------------------------------------------------------
* Cell 2: TZA unb consumption (zero missing-logpc rows: pure no-op)
* ----------------------------------------------------------------
data_setup TZA urban consumption unb
assert _N == 29864
assert !mi(logpc_consumption)
assert "`: char _dta[grc_switchers]'" != ""
confirm variable always always_choice never
di as text ">>> TZA unb consumption: PASS (N=29864 unchanged)"

* ----------------------------------------------------------------
* Cell 3: IDN unb income (1015 missing-logpc person-waves)
* ----------------------------------------------------------------
data_setup IDN urban income unb
assert _N == 57032
assert !mi(logpc_income)
assert "`: char _dta[grc_switchers]'" != ""
di as text ">>> IDN unb income: PASS (N=57032 = 58047 - 1015)"

* ----------------------------------------------------------------
* Reader fail-fast on a pre-scaffolding dataset
* ----------------------------------------------------------------
use "$dirdata/processed/TZA_unb.dta", clear
capture noisily setup_grc_estimation
assert _rc == 459
di as text ">>> reader fail-fast on contract-less data: PASS (rc=459)"

di as text ">>> SMOKE_STAGE3: ALL PASS"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> SMOKE_STAGE3 FAILED with rc=`saved_rc'"
}
