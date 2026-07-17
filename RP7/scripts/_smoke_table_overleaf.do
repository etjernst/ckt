* _smoke_table_overleaf.do --- preview render for Overleaf temp-tables.
*
* Stages today's canonical IDN+TZA cuu sters from the
* grc-pipeline-refactor worktree (which has freshly-fit GMM output as
* of 2026-05-08), runs attach_inversion_ci on those 10 cells to
* compute LCA inversion CIs, then renders the IDN and TZA paper
* tables via grc_tex_table_trend so we can preview the new layout
* (95% inv CI rows attached to each Delta block + the phi block,
* Delta_always block, no-+-prefix on positive values, addlinespace
* between SE row and CI row stripped).
version 19
clear all
set more off
set varabbrev off
set linesize 250
capture log close

global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
quietly include "$dir/scripts/0_path_config.do"
global logs "$dir/output"
global inversion_sterdir "$dir/output"

quietly include "$dir/scripts/0_programs.do"

log using "$logs/_smoke_table_overleaf.log", replace

capture noisily {

    local canonical_src "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output"

    * --- stage canonical sters (IDN+TZA cuu, all 5 covs cols, all 4 suffixes).
    * Skipping the stage step is critical when re-running just to refresh
    * inversion macros on already-staged sters --- otherwise the copy
    * silently clobbers any inversion macros attached on a prior pass.
    if "${skip_stage}" == "1" di as text "skip_stage=1: bypassing canonical ster stage"
    if "${skip_stage}" != "1" {
    foreach country in IDN TZA {
        foreach col in c0 c1 c2 ca ct {
            foreach suf in "" _n _g _a _d {
                local src "`canonical_src'/grc_`country'_cuu_`col'`suf'.ster"
                local dst "$dir/output/grc_`country'_cuu_`col'`suf'.ster"
                capture confirm file "`src'"
                if _rc == 0 {
                    copy "`src'" "`dst'", replace
                }
                else {
                    di as error "missing canonical ster: `src'"
                }
            }
        }
    }
    }

    * --- run attach_inversion_ci for the 10 cells (mirror 5b_inversion.do).
    * Skip the python compute when re-running just to refresh table
    * formatting --- macros are already on the sters. Set
    * global skip_attach 1 before `do`-ing this script to skip the loop.
    if "${skip_attach}" == "1" {
        di as text "skip_attach=1: bypassing inversion CI compute"
    }
    local balance unb
    local spec3   cuu

    set_covariate_globals

    global keepvars logpc_consumption trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    if "${skip_attach}" != "1" {
    foreach country in IDN TZA {
        di as text ""
        di as text "{hline 72}"
        di as text "Country: `country' --- inversion CI compute"
        di as text "{hline 72}"

        use "$dirdata/processed/`country'_`balance'.dta", clear
        setup_grc_estimation
        keep $keepvars
        tab period, gen(period_)
        local periodFE "period_2 - period_`r(r)'"
        drop if mi(logpc_consumption) | mi(choice)

        initial_values logpc_consumption,        ///
            switchers($switchers)       ///
            balance(`balance')          ///
            estname(initial_`country')
        local base `r(base)'
        di as text "  base trajectory = `base'"

        foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
            if "`spec'" == "covs_0"     local covs2 c0
            if "`spec'" == "covs_trend" local covs2 ct
            if "`spec'" == "covs_1"     local covs2 c1
            if "`spec'" == "covs_2"     local covs2 c2
            if "`spec'" == "covs_all"   local covs2 ca

            if "`spec'" == "covs_0"     local controls ""
            if "`spec'" == "covs_trend" local controls `periodFE'
            if "`spec'" == "covs_1"     local controls `periodFE' $covs_gmm
            if "`spec'" == "covs_2"     local controls `periodFE' $covs_gmm2
            if "`spec'" == "covs_all"   local controls `periodFE' $covs_gmm_all

            local estbase grc_`country'_`spec3'_`covs2'

            attach_inversion_ci,                ///
                estbase(`estbase')              ///
                sterdir("${inversion_sterdir}") ///
                outcome(logpc_consumption)               ///
                traj(trajectory)                ///
                choice(choice)                  ///
                hhid(pid)                       ///
                base(`base')                    ///
                controls(`controls')
        }
    }
    }

    * --- render the two preview tables
    local reportvars "phi:_cons"
    local varlab "$\phi$"
    local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\

    foreach country in IDN TZA {
        di as text ""
        di as text "{hline 72}"
        di as text "Rendering paper table for `country'/cuu/consumption/unb"
        di as text "{hline 72}"

        grc_tex_table_trend, columns(5)                              ///
            spec(cuu)                                                ///
            country(`country')                                       ///
            filename(GRC_`country'_consumption_urban_unb)            ///
            keep(`reportvars')                                       ///
            varlabel(`varlab')                                       ///
            postfoot(`postfoot_str')                                 ///
            coeflabels(choice "Urban")                               ///
            textdepvar( log(consumption) )
    }

    di as text ""
    di as text "{hline 72}"
    di as text "Rendered tables in $output/tables/:"
    di as text "  GRC_IDN_consumption_urban_unb.tex"
    di as text "  GRC_TZA_consumption_urban_unb.tex"
    di as text "{hline 72}"
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> _smoke_table_overleaf FAILED rc=`rc'"
