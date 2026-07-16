* ============================================================
* _refit_chn_sweep.do --- targeted re-fit of the CHN covariate sweep
* Fits the nine GRC cells missing under RP7 naming (CHN main cuu,
* hukou rural-first cuu, hukou urban-first cuu; covs2 = ct/c1/c2),
* attaches LCA inversion CIs to those cells plus the existing ca
* cells, and regenerates the three main-results tables.
* Run: cd RP7/scripts && stata-mp -e do _refit_chn_sweep.do
* Resumable: $skip_if_exists = 1 skips cells whose sters exist.
* ============================================================

version 17
clear all
set more off

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
global copyOverleaf 0
global overleaf ""
global values "nominal"
global skip_if_exists = 1

quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

capture log close
log using "$logs/_refit_chn_sweep.smcl", replace

capture noisily {

* GMM covariates (mirror 4_GrRC.do / 7_GrRC_hukou.do)
set_covariate_globals

global keepvars lndepvar trajectory choice pid
global keepvars $keepvars period unbalanced* switcher non_switcher
global keepvars $keepvars female age age2
global keepvars $keepvars education_max education_max2 trend
global keepvars $keepvars always always_choice never switcher_*

local balance unb
local iterations $grc_max_iter

* **********************************************************************
* Phase A1: CHN main cuu --- fit ct/c1/c2 (mirror 4_GrRC.do CHN section)
* **********************************************************************
di as text ">>> Phase A1: CHN main cuu (ct/c1/c2)"
eststo clear
local country CHN

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

run_grc, estname(grc_`country'_cuu_ct)                 ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                 ///
    covars(`periodFE')                                 ///
    iterate(`iterations')

run_grc, estname(grc_`country'_cuu_c1)                 ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                 ///
    covars(`periodFE' $covs_gmm)                       ///
    iterate(`iterations')

run_grc, estname(grc_`country'_cuu_c2)                 ///
    switchers($switchers) base(`base') initial(`initial') ///
    balance(`balance')                                 ///
    covars(`periodFE' $covs_gmm2)                      ///
    iterate(`iterations')

* **********************************************************************
* Phase A2/A3: hukou rf_cuu and uf_cuu --- fit ct/c1/c2
* (mirror 7_GrRC_hukou.do sections 1 and 4)
* **********************************************************************
foreach grp in rural_first urban_first {

    local country       CHN_hukou_`grp'
    if "`grp'" == "rural_first" local country_short CHN_rf_cuu
    else                        local country_short CHN_uf_cuu

    di as text ">>> Phase A: `country' (`country_short') ct/c1/c2"
    eststo clear

    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    initial_values lndepvar,       ///
        switchers($switchers)      ///
        balance(`balance')         ///
        estname(initial_`country_short')
        local base `r(base)'
        local initial "`r(initial)'"

    run_grc, estname(grc_`country_short'_ct)               ///
        switchers($switchers) base(`base') initial(`initial') ///
        balance(`balance')                                 ///
        covars(`periodFE')                                 ///
        iterate(`iterations')

    run_grc, estname(grc_`country_short'_c1)               ///
        switchers($switchers) base(`base') initial(`initial') ///
        balance(`balance')                                 ///
        covars(`periodFE' $covs_gmm)                       ///
        iterate(`iterations')

    run_grc, estname(grc_`country_short'_c2)               ///
        switchers($switchers) base(`base') initial(`initial') ///
        balance(`balance')                                 ///
        covars(`periodFE' $covs_gmm2)                      ///
        iterate(`iterations')
}

* **********************************************************************
* Phase B: attach LCA inversion CIs (mirror 5b_inversion.do /
* 5c_inversion_hukou.do, restricted to the CHN cells; covers ca too).
* Cells already attached (e(inv_phi_ci95_lo) non-missing) are skipped,
* so the phase is idempotent. Not routed through 5b/5c because those
* would also attach the unattached IDN/TZA c0 parents (a column
* dropped from the tables).
* **********************************************************************
global inversion_sterdir "$output"

foreach cell in main rf uf {

    if "`cell'" == "main" {
        local dtafile  CHN
        local stem     grc_CHN_cuu
        local initname initial_CHN
    }
    else if "`cell'" == "rf" {
        local dtafile  CHN_hukou_rural_first
        local stem     grc_CHN_rf_cuu
        local initname initial_CHN_rf_cuu
    }
    else {
        local dtafile  CHN_hukou_urban_first
        local stem     grc_CHN_uf_cuu
        local initname initial_CHN_uf_cuu
    }

    di as text ">>> Phase B: inversion attach for `stem'"

    use "$dirdata/processed/`dtafile'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    keep $keepvars
    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"
    drop if mi(lndepvar) | mi(choice)

    initial_values lndepvar,        ///
        switchers($switchers)       ///
        balance(`balance')          ///
        estname(`initname')
    local base `r(base)'
    di as text "  base trajectory = `base'"

    foreach covs2 in ct c1 c2 ca {

        if "`covs2'" == "ct"      local controls `periodFE'
        else if "`covs2'" == "c1" local controls `periodFE' $covs_gmm
        else if "`covs2'" == "c2" local controls `periodFE' $covs_gmm2
        else                      local controls `periodFE' $covs_gmm_all

        local estbase `stem'_`covs2'

        local parent "${inversion_sterdir}/`estbase'.ster"
        capture confirm file "`parent'"
        if _rc != 0 {
            di as error "  SKIP `estbase' (no parent ster)"
            continue
        }
        capture estimates use "`parent'"
        if _rc == 0 & e(inv_phi_ci95_lo) < . {
            di as text "  SKIP `estbase' (inversion already attached)"
            continue
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
    }
}

* **********************************************************************
* Phase C: regenerate the three main-results tables (mirror
* 10_make_tables.do call shapes; invci on). copyOverleaf stays 0;
* copy to Overleaf manually after inspection.
* **********************************************************************
di as text ">>> Phase C: tables"

local reportvars "phi:_cons"
local varlab "$\phi$"
local postfoot_str Time FE & Y & Y & Y & Y \\ Covariates & & Female & \& Age$^2$ & All \\
local choice  urban
local depvar  consumption

* CHN main
local country CHN
grc_tex_table_trend, columns(4)                         ///
    spec(cuu)                                           ///
    invci                                               ///
    country(`country')                                  ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )

* Hukou rural-first
local country       CHN_hukou_rural_first
local country_short CHN_rf_cuu
grc_tex_table_trend, columns(4)                         ///
    invci                                               ///
    country(`country_short')                            ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )

* Hukou urban-first
local country       CHN_hukou_urban_first
local country_short CHN_uf_cuu
grc_tex_table_trend, columns(4)                         ///
    invci                                               ///
    country(`country_short')                            ///
    filename(GRC_`country'_`depvar'_`choice'_`balance') ///
    keep(`reportvars')                                  ///
    varlabel(`varlab')                                  ///
    postfoot(`postfoot_str')                            ///
    coeflabels(choice "Urban")                          ///
    textdepvar( log(`depvar') )

di as text ">>> _refit_chn_sweep: complete"
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> _refit_chn_sweep FAILED with rc=`saved_rc'"
}
