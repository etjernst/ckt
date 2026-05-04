* **********************************************************************
* Tier 2 replay smoke (Phase 1a M11 verification): TZA cons/urban/unb only.
*
* Runs ~5 GMM fits + 1 LaTeX table for TZA. TZA is the fastest country
* in the smoke #9 reference (covs_0 = 6 sec, covs_all = 12 sec); whole
* file should take ~1 minute.
*
* On success, diff RP7/output/tables/GRC_TZA_consumption_urban_unb.tex
* against tests/reference/output/tables/GRC_TZA_consumption_urban_unb.tex.
* Bit-identical = M11 rename validated for the write+read path.
*
* Mirrors the structure of _smoke_idn_only.do (and inherits its no-wrap
* convention --- see that file's header for why).
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_programs.do"

global copyOverleaf 0

* --------------------------------------------------------------
* Spec: TZA consumption urban unbalanced
* --------------------------------------------------------------
    local choice  urban
    local depvar  consumption
    local balance unb

    * Globals normally set at the top of 4_GrRC.do (lines 42-51).
    global covs_gmm     "female"
    global covs_gmm2    "$covs_gmm age2"
    global covs_gmm_all "$covs_gmm2 education_max education_max2"

    global keepvars lndepvar trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    eststo clear
    local country TZA

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)

    setup_grc_estimation
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * --------------------------------------------------------------
    * GMM fits: 5 covariate specs (M11 estname shorthand: cuu_<covs2>)
    * --------------------------------------------------------------
    initial_values lndepvar,        ///
        switchers($switchers)       ///
        balance(`balance')          ///
        estname(initial_`country')
    local base `r(base)'
    scalar base_`country' = `base'
    local initial "`r(initial)'"

    local iterations 100

    run_grc, estname(grc_`country'_cuu_c0)                          ///
        switchers($switchers) base(`base') initial(`initial')       ///
        balance(`balance')                                          ///
        iterate(`iterations')

    run_grc, estname(grc_`country'_cuu_ct)                          ///
        switchers($switchers) base(`base') initial(`initial')       ///
        balance(`balance')                                          ///
        covars(`periodFE')                                          ///
        iterate(`iterations')

    run_grc, estname(grc_`country'_cuu_c1)                          ///
        switchers($switchers) base(`base') initial(`initial')       ///
        balance(`balance')                                          ///
        covars(`periodFE' $covs_gmm)                                ///
        iterate(`iterations')

    run_grc, estname(grc_`country'_cuu_c2)                          ///
        switchers($switchers) base(`base') initial(`initial')       ///
        balance(`balance')                                          ///
        covars(`periodFE' $covs_gmm2)                               ///
        iterate(`iterations')

    run_grc, estname(grc_`country'_cuu_ca)                          ///
        switchers($switchers) base(`base') initial(`initial')       ///
        balance(`balance')                                          ///
        covars(`periodFE' $covs_gmm_all)                            ///
        iterate(`iterations')

    * --------------------------------------------------------------
    * Load saved sters (M11 unified shorthand: disk == memory)
    * --------------------------------------------------------------
    foreach estname in c0 ct c1 c2 ca {
        estimates use "$dir/output/grc_`country'_cuu_`estname'"
        estimates store grc_`country'_cuu_`estname'
        estimates use "$dir/output/grc_`country'_cuu_`estname'_n"
        estimates store grc_`country'_cuu_`estname'_n
        estimates use "$dir/output/grc_`country'_cuu_`estname'_g"
        estimates store grc_`country'_cuu_`estname'_g
    }

    * --------------------------------------------------------------
    * LaTeX table: same call shape as 4_GrRC.do for TZA, must produce
    * the GRC_TZA_consumption_urban_unb.tex that tests/reference/ has.
    * --------------------------------------------------------------
    local reportvars "phi:_cons"
    local varlab "$\phi$"
    local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

    grc_tex_table_trend, columns(5)                         ///
        spec(cuu)                                           ///
        country(`country')                                  ///
        filename(GRC_`country'_`depvar'_`choice'_`balance') ///
        keep(`reportvars')                                  ///
        varlabel(`varlab')                                  ///
        postfoot(`postfoot_str')                            ///
        coeflabels(choice "Urban")                          ///
        textdepvar( log(`depvar') )

    timer list

display as text "============ Tier 2 TZA smoke complete ============"
exit, STATA clear
