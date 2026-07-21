* *******************************************************************
* Title:   Stage 9 unit test: switcher-inclusion keep-list
* Author:  Emilia Tjernstrom
* Date:    2026-07-21
* Purpose: Tests compute_switcher_keeplist, stash_switcher_keeplist,
*          and the setup_grc_estimation lump on a constructed panel:
*          a trajectory with five both-state individuals is kept, one
*          with four is lumped, a one-sided cell (urban-only) is
*          lumped, lumping relabels rather than deletes, the balanced
*          sample drops loudly, nolump leaves everything alone, and
*          the cluster-counted unit works at the Verdier threshold.
* Input:   none (synthetic data built in memory)
* Output:  tests/stage9/out/ scratch keep-list CSVs; PASS/FAIL log
* *******************************************************************
clear all
set more off
set varabbrev off

global dir "C:/git/ckt/RP7"
do "$dir/scripts/0_path_config.do"
quietly do "$dir/scripts/0_programs.do"

* Redirect output so the test never writes into the real output tree
global output "$dir/tests/stage9/out"
capture mkdir "$output"
capture mkdir "$output/keeplists"

capture noisily {

* *******************************************************************
* Build the synthetic panel, T = 3 waves
*   trajectory 1 (never):    6 pids, all rural
*   trajectory 2 (switcher): 5 pids, pattern 0-0-1  -> kept at 5
*   trajectory 3 (switcher): 4 pids, pattern 0-1-1  -> lumped (4 < 5)
*   trajectory 4 (switcher): 5 pids, urban-only     -> lumped (one-sided)
*   trajectory 5 (always):   6 pids, all urban
*   plus 3 unbalanced pids (trajectory missing, unbalanced == 1)
* *******************************************************************
set obs 0
gen long pid = .
gen int year = .
gen byte choice = .
gen byte trajectory = .
gen byte unbalanced = .

local next 0
* never
forvalues i = 1/6 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = 0 in `=_N'
        replace trajectory = 1 in `=_N'
        replace unbalanced = 0 in `=_N'
    }
}
* switcher 2: 0-0-1
forvalues i = 1/5 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' == 3, 1, 0) in `=_N'
        replace trajectory = 2 in `=_N'
        replace unbalanced = 0 in `=_N'
    }
}
* switcher 3: 0-1-1, only 4 pids
forvalues i = 1/4 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' >= 2, 1, 0) in `=_N'
        replace trajectory = 3 in `=_N'
        replace unbalanced = 0 in `=_N'
    }
}
* switcher 4: urban in every wave (one-sided by construction)
forvalues i = 1/5 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = 1 in `=_N'
        replace trajectory = 4 in `=_N'
        replace unbalanced = 0 in `=_N'
    }
}
* always
forvalues i = 1/6 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = 1 in `=_N'
        replace trajectory = 5 in `=_N'
        replace unbalanced = 0 in `=_N'
    }
}
* unbalanced pids (missing trajectory)
forvalues i = 1/3 {
    local ++next
    forvalues t = 1/2 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' == 2, 1, 0) in `=_N'
        replace trajectory = . in `=_N'
        replace unbalanced = 1 in `=_N'
    }
}

gen byte period = year - 2000
gen unbalanced_choice = unbalanced*choice
gen byte always = (trajectory == 5)
gen always_choice = always*choice
gen byte never = (trajectory == 1)
gen byte switcher = inlist(trajectory, 2, 3, 4)
forvalues s = 2/4 {
    gen byte switcher_`s' = (trajectory == `s')
    gen switcher_`s'_choice = switcher_`s'*choice
}
bysort pid (year): gen byte pid_first_obs = (_n == 1)
sort pid year

* The trajectory contract, as handle_grc_scaffolding would stash it
char define _dta[grc_switchers] "2 3 4"
char define _dta[grc_always] "5"
char define _dta[grc_never] "1"

tempfile base
save `base'

* *******************************************************************
* Test 1: compute_switcher_keeplist counts and verdicts
* *******************************************************************
compute_switcher_keeplist, candidates(2 3 4) threshold(5) unitvar(pid)
assert "`r(kept)'" == "2"
assert "`r(dropped)'" == "3 4"
assert "`r(counts)'" == "2=5 3=4 4=0"
di as result "PASS 1: both-state counts (5 kept, 4 lumped, one-sided lumped)"

* *******************************************************************
* Test 2: stash writes the characteristics and the audit CSV
* *******************************************************************
stash_switcher_keeplist testcell
local kchar : char _dta[grc_kept_switchers]
assert "`kchar'" == "2"
local tchar : char _dta[grc_keep_threshold]
assert "`tchar'" == "5"
confirm file "$output/keeplists/testcell_keeplist.csv"
di as result "PASS 2: characteristics stashed, CSV written"

* *******************************************************************
* Test 3: setup_grc_estimation lumps (relabels, never deletes)
* *******************************************************************
local n_before = _N
setup_grc_estimation
assert "$switchers" == "2"
assert _N == `n_before'
* trajectory-3 and -4 pids: relabeled 999, flagged unbalanced
assert trajectory == 999 & unbalanced == 1 & switcher == 0 ///
    if inlist(trajectory_full, 3, 4)
assert unbalanced_choice == unbalanced*choice
assert switcher_3 == 0 & switcher_3_choice == 0
assert switcher_4 == 0 & switcher_4_choice == 0
* kept trajectory untouched
assert trajectory == 2 & switcher_2 == 1 if trajectory_full == 2
* originals preserved: every lumped person-wave still carries its code
count if trajectory_full == 3
assert r(N) == 12
count if trajectory_full == 4
assert r(N) == 15
di as result "PASS 3: lump relabels to 999/unbalanced, N unchanged, kept cell untouched"

* *******************************************************************
* Test 4: balanced sample (no unbalanced cell) drops loudly
* *******************************************************************
use `base', clear
drop if unbalanced == 1
char define _dta[grc_kept_switchers] "2"
char define _dta[grc_keep_threshold] "5"
local n_before = _N
* trajectories 3 (4 pids x 3 waves) and 4 (5 pids x 3 waves) = 27 waves
setup_grc_estimation
assert "$switchers" == "2"
assert _N == `n_before' - 27
assert !inlist(trajectory, 3, 4)
di as result "PASS 4: balanced sample drops the lumped trajectories (27 person-waves)"

* *******************************************************************
* Test 5: nolump leaves labels and $switchers alone
* *******************************************************************
use `base', clear
local n_before = _N
setup_grc_estimation, nolump
assert "$switchers" == "2 3 4"
assert _N == `n_before'
assert trajectory == trajectory_full if trajectory != 999
count if trajectory == 3
assert r(N) == 12
di as result "PASS 5: nolump keeps the full enumeration"

* *******************************************************************
* Test 6: cluster-counted unit at the Verdier threshold
*   2 clusters both-state in trajectory 2 -> kept at threshold 2
*   1 cluster both-state in trajectory 3  -> lumped
* *******************************************************************
use `base', clear
* clusters: split trajectory 2's five pids across 2 clusters, all of
* trajectory 3 in one cluster; others one cluster each
gen int vfirst = 10 if trajectory == 1
replace vfirst = cond(mod(pid, 2) == 0, 21, 22) if trajectory == 2
replace vfirst = 30 if trajectory == 3
replace vfirst = 40 if trajectory == 4
replace vfirst = 50 if trajectory == 5
replace vfirst = 60 if missing(trajectory)
compute_switcher_keeplist, candidates(2 3 4) threshold(2) unitvar(vfirst)
assert "`r(kept)'" == "2"
assert "`r(dropped)'" == "3 4"
assert "`r(counts)'" == "2=2 3=1 4=0"
di as result "PASS 6: cluster-counted rule at threshold 2"

di as result "ALL STAGE 9 KEEP-LIST TESTS PASSED"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> TEST FAILED with rc=`saved_rc'"
}
exit, STATA clear
