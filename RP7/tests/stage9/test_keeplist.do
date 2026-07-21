* *******************************************************************
* Title:   Stage 9 unit test: switcher-inclusion keep-list
* Author:  Emilia Tjernstrom
* Date:    2026-07-21
* Purpose: Tests compute_switcher_keeplist, stash_switcher_keeplist,
*          and the setup_grc_estimation lump on a constructed panel:
*          a trajectory with five both-state individuals is kept, one
*          with four is lumped, a one-sided cell (urban-only) is
*          lumped, lumping relabels rather than deletes, the balanced
*          sample drops loudly, nolump leaves everything alone, the
*          cluster-counted unit works at the Verdier threshold, and an
*          all-thin cell stashes an empty keep-list without error.
* Input:   none (synthetic data built in memory)
* Output:  tests/stage9/out/ scratch keep-list CSVs; PASS/FAIL log
* *******************************************************************
version 17
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

* *******************************************************************
* Test 7: full synthetic Verdier fit with a cluster-dropped trajectory
*   Exercises run_grc_robust_vv end to end via the driver pattern
*   (gen_vfirst + per-country keep-list + keeplist() option): the
*   dropped trajectory must be absent from the fitted parameters AND
*   from every post-estimation product (the joint tests and nlcoms
*   must loop the kept list, not the $switchers global).
* *******************************************************************
clear
set seed 12345
set obs 0
gen long pid = .
gen int year = .
gen byte choice = .
gen byte trajectory = .
gen byte unbalanced = .
gen int prov = .

local next 0
* never (code 1): 30 pids, all rural, clusters 1-3
forvalues i = 1/30 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = 0 in `=_N'
        replace trajectory = 1 in `=_N'
        replace unbalanced = 0 in `=_N'
        replace prov = 1 + mod(`i', 3) in `=_N'
    }
}
* switcher 2: 0-0-1, 30 pids, clusters 1-3
forvalues i = 1/30 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' == 3, 1, 0) in `=_N'
        replace trajectory = 2 in `=_N'
        replace unbalanced = 0 in `=_N'
        replace prov = 1 + mod(`i', 3) in `=_N'
    }
}
* switcher 3: 0-1-1, 30 pids, clusters 4-6
forvalues i = 1/30 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' >= 2, 1, 0) in `=_N'
        replace trajectory = 3 in `=_N'
        replace unbalanced = 0 in `=_N'
        replace prov = 4 + mod(`i', 3) in `=_N'
    }
}
* switcher 4: 0-1-1, 9 pids, ALL in cluster 7 -> one both-state cluster,
* below the two-cluster Verdier rule, so it must be lumped
forvalues i = 1/9 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' >= 2, 1, 0) in `=_N'
        replace trajectory = 4 in `=_N'
        replace unbalanced = 0 in `=_N'
        replace prov = 7 in `=_N'
    }
}
* always (code 5): 30 pids, all urban, clusters 4-6
forvalues i = 1/30 {
    local ++next
    forvalues t = 1/3 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = 1 in `=_N'
        replace trajectory = 5 in `=_N'
        replace unbalanced = 0 in `=_N'
        replace prov = 4 + mod(`i', 3) in `=_N'
    }
}
* unbalanced pids: 10 pids, 2 waves, cluster 8
forvalues i = 1/10 {
    local ++next
    forvalues t = 1/2 {
        set obs `=_N+1'
        replace pid = `next' in `=_N'
        replace year = 2000 + `t' in `=_N'
        replace choice = cond(`t' == 2, 1, 0) in `=_N'
        replace trajectory = . in `=_N'
        replace unbalanced = 1 in `=_N'
        replace prov = 8 in `=_N'
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

* Outcome: trajectory mean + common urban return + noise
gen double mu_true = 1.0
replace mu_true = 1.2 if trajectory == 2
replace mu_true = 1.4 if trajectory == 3
replace mu_true = 1.6 if trajectory == 4
replace mu_true = 2.0 if trajectory == 5
replace mu_true = 1.1 if missing(trajectory)
gen double logpc_consumption = mu_true + 0.3*choice + rnormal(0, 0.05)

char define _dta[grc_switchers] "2 3 4"
char define _dta[grc_always] "5"
char define _dta[grc_never] "1"

setup_grc_estimation, nolump
assert "$switchers" == "2 3 4"

* Driver pattern: vfirst + per-country keep-list, then the fit consumes it
gen_vfirst, vname(prov) genname(vfirst)
compute_switcher_keeplist if !missing(vfirst), candidates($switchers) ///
    threshold($grc_switcher_keep_min_vv) unitvar(vfirst)
local vv_kept `r(kept)'
assert "`vv_kept'" == "2 3"
assert "`r(dropped)'" == "4"

* Starting values from the kept set, exactly as the drivers do (a zero
* start leaves the phi derivative on a flat region and the gmm r(430)s)
xtset pid period
initial_values logpc_consumption, ///
    switchers(`vv_kept')        ///
    balance(unb)                ///
    estname(initial_t9)
* t9base, not base: `base' is this do-file's tempfile handle
local t9base `r(base)'
local initial "`r(initial)'"
assert strpos(" `vv_kept' ", " `t9base' ") > 0

* Redirect $dir so the fit's sters land in the test tree, not RP7/output
global dir "C:/git/ckt/RP7/tests/stage9"
capture mkdir "$dir/output"

local n_before = _N
run_grc_robust_vv,                                ///
    estname(vv_t9_os)                             ///
    switchers($switchers) keeplist(`vv_kept')     ///
    base(`t9base') balance(unb) vindex(prov)      ///
    initial(`initial')                            ///
    iterate(100) onestep

* caller's data untouched (program-level preserve)
assert _N == `n_before'

* fitted parameters: kept switchers present, dropped switcher absent
estimates use "$dir/output/vv_t9_os.ster"
local eqs   : coleq e(b)
local names : colnames e(b)
local has2 0
local has3 0
local has4 0
forvalues j = 1/`=colsof(e(b))' {
    local eq : word `j' of `eqs'
    local nm : word `j' of `names'
    if "`eq'" == "mu" & "`nm'" == "switcher_2" local has2 1
    if "`eq'" == "mu" & "`nm'" == "switcher_3" local has3 1
    if "`eq'" == "mu" & "`nm'" == "switcher_4" local has4 1
}
assert `has2' == 1 & `has3' == 1 & `has4' == 0
* the joint mu test ran on the kept list (would have errored on the
* full $switchers enumeration, which includes the dropped code 4)
assert e(joint_chi2) < .

* post-estimation products exist and carry only kept-switcher Deltas
confirm file "$dir/output/vv_t9_os_d.ster"
confirm file "$dir/output/vv_t9_os_g.ster"
estimates use "$dir/output/vv_t9_os_d.ster"
local dnames : colnames e(b)
assert strpos("`dnames'", "Delta_2") > 0
assert strpos("`dnames'", "Delta_3") > 0
assert strpos("`dnames'", "Delta_4") == 0
di as result "PASS 7: synthetic Verdier fit lumps the one-cluster trajectory and post-estimation loops the kept list"

* *******************************************************************
* Test 8: all-thin cell (every switcher trajectory below threshold)
*   drop one trajectory-2 pid so its both-state count falls to 4:
*   no trajectory survives, the stash must not error, and the reader
*   must lump everything rather than mistake the cell for pre-keep-list
* *******************************************************************
use `base', clear
drop if trajectory == 2 & pid == 7
stash_switcher_keeplist allthin
local kchar : char _dta[grc_kept_switchers]
assert "`kchar'" == ""
local tchar : char _dta[grc_keep_threshold]
assert "`tchar'" == "5"
confirm file "$output/keeplists/allthin_keeplist.csv"
local n_before = _N
setup_grc_estimation
assert "$switchers" == ""
assert _N == `n_before'
assert trajectory == 999 & unbalanced == 1 if inlist(trajectory_full, 2, 3, 4)
di as result "PASS 8: all-thin cell stashes an empty keep-list and lumps every switcher"

di as result "ALL STAGE 9 KEEP-LIST TESTS PASSED"
}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> TEST FAILED with rc=`saved_rc'"
}
exit, STATA clear
