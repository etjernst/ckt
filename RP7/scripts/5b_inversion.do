/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: Apr 2026
This code:
    - attaches weak-ID-robust LCA inversion CIs (90% and 95%) for phi
      and the three trajectory-specific deltas to the .ster files
      produced by 5_GrRC.do for the urban / consumption / unbalanced
      mainline.
    - decoupled from 5_GrRC.do so re-running the inversion does not
      re-run the (slow) GMM. Run after 5_GrRC.do, before tables get
      built by grc_tex_table_trend.

Output:
    Updates the four .sters per (country, spec):
        grc_<country>_urban_<spec>.ster        (parent: phi inversion)
        grc_<country>_urban_<spec>_never.ster  (Delta_never inversion)
        grc_<country>_urban_<spec>_avg.ster    (Delta_avg inversion)
        grc_<country>_urban_<spec>_always.ster (Delta_always inversion)
    by re-saving with the inversion CI scalars and macros attached.

Set ${inversion_sterdir} ahead of running this file to redirect to a
non-default location (e.g., explorations/python-grc/rerun_workdir/output
for testing). Defaults to $output.
*******************************************************************************/

* set log file
cd "$logs"
capture log close
log using 5b_inversion.log, replace

capture noisily {

    * **********************************************************************
    * Choices for the analysis (mirror 5_GrRC.do mainline)
    *     Countries:          IDN / TZA / CHN
    *     Choice variable:    urban
    *     Dependent variable: consumption
    *     Panel structure:    unbalanced
    * **********************************************************************
    local choice  urban
    local depvar  consumption
    local balance unb

    * Resolve where the .ster files live. Defaults to $output (the standard
    * 5_GrRC.do destination); override with `global inversion_sterdir ...`
    * before invoking this script for a test run against existing sters.
    if "${inversion_sterdir}" == "" {
        global inversion_sterdir "$output"
    }
    di as text "Inversion writes to: " as result "${inversion_sterdir}"

    * GMM covariates (mirror 5_GrRC.do)
    global covs_gmm     "female"
    global covs_gmm2    "$covs_gmm age2"
    global covs_gmm_all "$covs_gmm2 education_max education_max2"

    global keepvars lndepvar trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    foreach country in IDN TZA CHN {

        di as text ""
        di as text "{hline 72}"
        di as text "Country: `country'"
        di as text "{hline 72}"

        * --- load data and prep (mirror 5_GrRC.do)
        use "$dirdata/processed/`country'_`balance'.dta", clear
        replace lndepvar = log(consumption/hhsize_cube)
        setup_grc_estimation
        keep $keepvars
        tab period, gen(period_)
        local periodFE "period_2 - period_`r(r)'"
        drop if mi(lndepvar) | mi(choice)

        * --- recover the base trajectory using the same routine 5_GrRC.do
        * uses, so the inversion's auxiliary OLS pivots on the same
        * switcher reference as the GMM.
        initial_values lndepvar,        ///
            switchers($switchers)       ///
            balance(`balance')          ///
            estname(initial_`country')
        local base `r(base)'
        di as text "  base trajectory = `base'"

        * --- attach inversion CIs to each (spec, suffix) cell
        foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {

            * Map spec names to controls (mirror 5_GrRC.do)
            if "`spec'" == "covs_0" {
                local controls ""
            }
            else if "`spec'" == "covs_trend" {
                local controls `periodFE'
            }
            else if "`spec'" == "covs_1" {
                local controls `periodFE' $covs_gmm
            }
            else if "`spec'" == "covs_2" {
                local controls `periodFE' $covs_gmm2
            }
            else if "`spec'" == "covs_all" {
                local controls `periodFE' $covs_gmm_all
            }

            local estbase grc_`country'_`choice'_`spec'

            * --- skip-if-exists guard at cell level. If the parent ster
            * already carries e(inv_phi_ci95_lo) and ${skip_if_exists}=1,
            * the whole cell is considered done; unset $skip_if_exists or
            * delete the ster to force a re-run.
            local parent "${inversion_sterdir}/`estbase'.ster"
            capture confirm file "`parent'"
            if _rc != 0 {
                di as text "  SKIP `estbase' (no parent ster)"
                continue
            }
            if "${skip_if_exists}" == "1" {
                capture estimates use "`parent'"
                if _rc == 0 & e(inv_phi_ci95_lo) < . {
                    di as text "  SKIP `estbase' (inversion already attached)"
                    continue
                }
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

    di as text ""
    di as text "{hline 72}"
    di as text "5b_inversion: complete"
    di as text "{hline 72}"
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> 5b_inversion FAILED rc=`rc'"
exit, STATA clear
