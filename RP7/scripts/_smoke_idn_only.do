* **********************************************************************
* Fast smoke driver: IDN consumption / urban / unbalanced ONLY.
* ~5 GMM fits + 1 LaTeX table. Targets ~5 minutes wall-clock.
*
* No `capture noisily` wrap --- it appeared to interact badly with the
* multi-line `gmm` calls in `run_grc` (110 min stall in one trial vs.
* 30 min for the FULL pipeline without the wrap).
*
* Use during bug-fix iteration. The full smoke (_smoke_5_GrRC.do) is the
* end-to-end check; this is the inner-loop test.
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
}

include "$dir/scripts/0_path_config.do"
* Skip 0_setup.do --- it has `window stopbox` calls that show real modal
* dialogs in batch mode if any SSC package is flagged as missing (even
* under `capture`). For a smoke test we assume packages are already
* installed; failures will surface as command-not-found errors instead.
include "$scripts/0_programs.do"

global copyOverleaf 0

* NOTE 2026-04-26: dropped the `capture noisily { }` wrap. Previous run
* with the wrap stalled in Step 2 of GMM iteration --- 110 minutes into
* a job that should take 5-10 minutes. Same code without the wrap ran
* the FULL pipeline in 30 minutes. Suspected slow-path interaction
* between `capture noisily` and multi-line `gmm`.
* Trade-off: if the script errors, Stata's popup appears in batch mode.
* Click through it; we'll add a cleaner error-handling shim later if
* this becomes annoying.

* --------------------------------------------------------------
* Spec: IDN consumption urban unbalanced
* --------------------------------------------------------------
    local choice  urban
    local depvar  consumption
    local balance unb

    * Globals normally set at the top of 5_GrRC.do (lines 42-51).
    * Inlining here because the smoke skips that prelude.
    global covs_gmm     "female"
    global covs_gmm2    "$covs_gmm age2"
    global covs_gmm_all "$covs_gmm2 education_max education_max2"

    global keepvars lndepvar trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    eststo clear
    local country IDN

    use "$dirdata/processed/`country'_`balance'.dta", clear

    * IDN-specific: log per-capita consumption normalized by household-size cube
    replace lndepvar = log(consumption/hhsize_cube)

    setup_grc_estimation
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * --------------------------------------------------------------
    * GMM fits: 5 covariate specs
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
    * Load the saved sters. After M11, ster filenames and stored
    * estimate names use the same `grc_<country>_<spec3>_<covs2>`
    * shorthand (no Option B bridge needed).
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
    * LaTeX table: same call shape as 5_GrRC.do for IDN
    * --------------------------------------------------------------
    local reportvars "phi:_cons"
    local varlab "$\phi$"
    local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age\$^2$ & All \\

grc_tex_table_trend, columns(5)                         ///
    spec(cuu)                                           ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )

display as text "============ IDN smoke complete ============"
exit, STATA clear
