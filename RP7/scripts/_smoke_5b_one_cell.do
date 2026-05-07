* _smoke_5b_one_cell.do --- minimal post-merge smoke for 5b_inversion.
*
* Confirms attach_inversion_ci consumes the post-pipeline-refactor
* naming convention end-to-end on a single cell (IDN / cuu / ca):
*   - finds grc_IDN_cuu_ca.ster, grc_IDN_cuu_ca_n.ster, _g.ster, _a.ster
*     in $inversion_sterdir
*   - runs the Python inversion compute against the IDN unb data
*   - re-saves each ster with the inv_*_ci95_str / inv_*_ci90_str e()-macros
*   - verifies the macros are readable via estimates use
*
* Sterdir defaults to RP7/output/smoke; override with `global
* inversion_sterdir <path>` before running.
version 19
clear all
set more off
set varabbrev off
capture log close

global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global scripts "$dir/scripts"
global logs    "$dir/output"
global output  "$dir/output"

if "${inversion_sterdir}" == "" {
    global inversion_sterdir "$dir/output/smoke"
}

log using "$logs/_smoke_5b_one_cell.log", replace

quietly include "$dir/scripts/0_programs.do"

capture noisily {

    local country IDN
    local choice  urban
    local depvar  consumption
    local balance unb
    local spec3   cuu
    local covs2   ca

    global covs_gmm     "female"
    global covs_gmm2    "$covs_gmm age2"
    global covs_gmm_all "$covs_gmm2 education_max education_max2"

    global keepvars lndepvar trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    di as text "{hline 72}"
    di as text "Smoke target: `country' / `spec3' / `covs2'"
    di as text "Sterdir: ${inversion_sterdir}"
    di as text "{hline 72}"

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"
    drop if mi(lndepvar) | mi(choice)

    initial_values lndepvar,        ///
        switchers($switchers)       ///
        balance(`balance')          ///
        estname(initial_`country')
    local base `r(base)'
    di as text "  base trajectory = `base'"

    local controls `periodFE' $covs_gmm_all
    local estbase grc_`country'_`spec3'_`covs2'

    capture confirm file "${inversion_sterdir}/`estbase'.ster"
    if _rc != 0 {
        di as error ">>> SKIP `estbase' (no parent ster at ${inversion_sterdir})"
        exit 1
    }

    attach_inversion_ci,                ///
        estbase(`estbase')              ///
        sterdir("${inversion_sterdir}") ///
        outcome(lndepvar)               ///
        traj(trajectory)                ///
        choice(choice)                  ///
        hhid(pid)                       ///
        base(`base')                    ///
        controls(`controls')

    * --- read back the macros from each ster suffix
    di as text ""
    di as text "{hline 72}"
    di as text "Read-back of inversion macros from each ster suffix:"
    di as text "{hline 72}"
    foreach suffix in "" "_n" "_g" "_a" {
        capture confirm file "${inversion_sterdir}/`estbase'`suffix'.ster"
        if _rc != 0 continue
        estimates use "${inversion_sterdir}/`estbase'`suffix'.ster"
        di as text "  `estbase'`suffix':"
        di as text "    inv_phi_ci95_str  = " as result `"`e(inv_phi_ci95_str)'"'
        di as text "    inv_phi_ci90_str  = " as result `"`e(inv_phi_ci90_str)'"'
        di as text "    inv_dN_ci95_str   = " as result `"`e(inv_dN_ci95_str)'"'
        di as text "    inv_davg_ci95_str = " as result `"`e(inv_davg_ci95_str)'"'
        di as text "    inv_dT_ci95_str   = " as result `"`e(inv_dT_ci95_str)'"'
    }
    di as text "{hline 72}"

}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> _smoke_5b_one_cell FAILED rc=`rc'"
