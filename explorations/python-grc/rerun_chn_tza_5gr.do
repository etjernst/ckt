* ============================================================
* Rerun the CHN and TZA sections of 5_GrRC.do to regenerate
* fresh urban-choice ster files (the production ster files in
* Dropbox are contaminated by 6_GrRC_NonAg.do's overwrites).
* Writes to LOCAL rerun_workdir/output, NOT Dropbox.
* Then dumps phi, SE, J for all 5 specs across both countries.
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "rerun_chn_tza_5gr.smcl", replace

* Read data + programs from Dropbox; write estimates locally.
global dropbox "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"
global dirdata "$dropbox/data"
global scripts "$dropbox/scripts"

global dir     "."
global output  "./output"
global logs    "./logs"
capture mkdir "$logs"

do "$scripts/0_programs.do"

local choice  urban
local depvar  consumption
local balance unb

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

* Open the output CSV before any country loop
tempname fh
file open `fh' using "chn_tza_fresh_phi.csv", write replace
file write `fh' "country,spec,phi,phi_se,Delta_base,Delta_base_se,kappa,kappa_se,J,J_p,N,converged" _n
file close `fh'

foreach country in CHN TZA {
    di as text "{hline 72}"
    di as text "Running `country' urban consumption unbalanced, all 5 specs"
    di as text "{hline 72}"

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    initial_values lndepvar, switchers($switchers) balance(`balance') ///
        estname(initial_`country')
    local base `r(base)'
    local initial "`r(initial)'"
    local iterations 500

    run_grc, estname(grc_`country'_covs_0) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') iterate(`iterations')
    run_grc, estname(grc_`country'_covs_trend) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE') iterate(`iterations')
    run_grc, estname(grc_`country'_covs_1) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm) iterate(`iterations')
    run_grc, estname(grc_`country'_covs_2) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm2) iterate(`iterations')
    run_grc, estname(grc_`country'_covs_all) switchers($switchers) base(`base') ///
        initial(`initial') balance(`balance') covars(`periodFE' $covs_gmm_all) iterate(`iterations')

    * Append rows for this country to the shared CSV
    file open `fh' using "chn_tza_fresh_phi.csv", write append
    foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
        capture estimates use "$output/grc_`country'_`spec'"
        if _rc {
            file write `fh' "`country',`spec',NA,NA,NA,NA,NA,NA,NA,NA,NA,NA" _n
            continue
        }
        local phi    = _b[phi:_cons]
        local phi_se = _se[phi:_cons]
        local Db     = _b[Delta_base:_cons]
        local Db_se  = _se[Delta_base:_cons]
        local ka     = _b[kappa:_cons]
        local ka_se  = _se[kappa:_cons]
        local J      = e(J)
        local Jp     = e(J_p)
        local N      = e(N)
        local cv     = cond(e(converged) == 1, "Y", "N")
        file write `fh' "`country',`spec',`phi',`phi_se',`Db',`Db_se',`ka',`ka_se',`J',`Jp',`N',`cv'" _n
    }
    file close `fh'
}

log close
exit, STATA clear
