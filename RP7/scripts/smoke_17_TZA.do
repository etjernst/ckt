* ============================================================
* Smoke test: 17_verdier_robust on Tanzania only
* All 5 covariate specs, both onestep and twostep.
* Goal: surface syntax errors before the full 30-estimation run.
* Delete after smoke passes; the full driver is 17_verdier_robust.do.
* ============================================================

clear all

* Path setup (matches 0_master.do for c(username)=="maand")
if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
}
include "$dir/scripts/0_path_config.do"
include "$dir/scripts/0_setup.do"
include "$dir/scripts/0_programs.do"
global copyOverleaf 0

cd "$logs"
capture log close
log using 17_smoke_TZA.log, replace

* ============================================================
* Wrap the body in capture noisily so any error is caught and
* the script always reaches `exit, STATA clear`. Without this
* wrapper, Windows pops the modal "Stata finished" dialog on
* batch-mode errors, which is not sustainable.
* ============================================================
capture noisily {

* TZA only
local country TZA
local choice  urban
local depvar  consumption
local balance unb
local vidx    region

global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

global keepvars lndepvar trajectory choice pid year
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*
global keepvars $keepvars `vidx'

eststo clear

use "$dirdata/processed/`country'_`balance'.dta", clear
replace lndepvar = log(consumption/hhsize_cube)
setup_grc_estimation
keep $keepvars

tab period, gen(period_)
local periodFE "period_2 - period_`r(r)'"

initial_values lndepvar,        ///
    switchers($switchers)       ///
    balance(`balance')          ///
    estname(initial_`country')
local base `r(base)'
local initial "`r(initial)'"

local iterations 500

foreach step in onestep twostep {

    if "`step'" == "onestep" local stepshort os
    else                     local stepshort ts

    di as txt "================================================================"
    di as txt "TZA smoke: step=`step' (estname tag = `stepshort')"
    di as txt "================================================================"

    run_grc_robust_vv,                                                  ///
        estname(vv_`country'_`stepshort'_covs_0)                   ///
        switchers($switchers) base(`base') initial(`initial')           ///
        balance(`balance') vindex(`vidx')                               ///
        iterate(`iterations') `step'

    run_grc_robust_vv,                                                  ///
        estname(vv_`country'_`stepshort'_covs_trend)               ///
        switchers($switchers) base(`base') initial(`initial')           ///
        balance(`balance') vindex(`vidx')                               ///
        covars(`periodFE')                                              ///
        iterate(`iterations') `step'

    run_grc_robust_vv,                                                  ///
        estname(vv_`country'_`stepshort'_covs_1)                   ///
        switchers($switchers) base(`base') initial(`initial')           ///
        balance(`balance') vindex(`vidx')                               ///
        covars(`periodFE' $covs_gmm)                                    ///
        iterate(`iterations') `step'

    run_grc_robust_vv,                                                  ///
        estname(vv_`country'_`stepshort'_covs_2)                   ///
        switchers($switchers) base(`base') initial(`initial')           ///
        balance(`balance') vindex(`vidx')                               ///
        covars(`periodFE' $covs_gmm2)                                   ///
        iterate(`iterations') `step'

    run_grc_robust_vv,                                                  ///
        estname(vv_`country'_`stepshort'_covs_all)                 ///
        switchers($switchers) base(`base') initial(`initial')           ///
        balance(`balance') vindex(`vidx')                               ///
        covars(`periodFE' $covs_gmm_all)                                ///
        iterate(`iterations') `step'
}

* ============================================================
* Quick ester roundtrip + table generation smoke
* ============================================================
foreach step in onestep twostep {
    if "`step'" == "onestep" local stepshort os
    else                     local stepshort ts
    foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all {
        local stem vv_`country'_`stepshort'_`estname'
        estimates use "$dir/output/`stem'"
        estimates store `stem'
        estimates use "$dir/output/`stem'_never"
        estimates store `stem'_never
        estimates use "$dir/output/`stem'_avg"
        estimates store `stem'_avg
    }
}

local reportvars "phi:_cons"
local varlab "$\phi$"

foreach step in onestep twostep {
    if "`step'" == "onestep" local stepshort os
    else                     local stepshort ts
    local htb_str "htbp"
    local table_caption "`" \caption{TZA smoke: Cluster-Residualized GRC, log Consumption, `step' GMM} "'"
    local table_label "`" \label{tab:smoke_verdier_robust_`step'_TZA} "'"
    local table_notes "Smoke-test table. Cluster-residualized GRC with `step' GMM, TZA only. Standard errors clustered at vfirst."
    local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

    grc_tex_table_trend, columns(5)                                                  ///
        country(TZA_`stepshort')                                                     ///
        estprefix(vv_)                                                          ///
        filename(smoke_verdier_robust_`step'_TZA_`depvar'_`choice'_`balance')        ///
        keep(`reportvars')                                                           ///
        varlabel(`varlab')                                                           ///
        htb(`htb_str')                                                               ///
        prehead(`table_caption' `table_label')                                       ///
        postfoot(`postfoot_str')                                                     ///
        coeflabels(choice "Urban")                                                   ///
        textdepvar( log(`depvar') )
}

di as text ">>> SMOKE TEST PASSED (if no errors above)"

}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> SMOKE TEST FAILED with rc=`saved_rc'"
}
exit, STATA clear
