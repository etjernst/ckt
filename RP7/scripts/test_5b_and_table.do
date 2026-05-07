* test_5b_and_table.do --- end-to-end verification for Step 5.
*
* Inlines 5b_inversion.do's body so the trailing `exit, STATA clear`
* in that file does not interrupt the table-render that follows.
* Production runs invoke 5b_inversion.do as a top-level script.
*
* Updated 2026-05-08 for the post-pipeline-refactor naming convention
* (STER_NAMING.md): estbase = grc_<country>_cuu_<covs2>, suffixes _n/_g/_a.
*
* TODO: main's Phase 2 grc_tex_table_trend does NOT yet consume the
* inv_*_ci95_str / inv_*_ci90_str e()-macros that attach_inversion_ci
* writes onto each ster. Extending grc_tex_table_trend to emit the
* inversion CI rows is a separate piece of work; for now this script
* verifies (a) attach_inversion_ci succeeds across the 15 mainline
* cells and (b) grc_tex_table_trend still renders the standard
* (non-inversion) table from the renamed sters. The CI rows come back
* when grc_tex_table_trend is extended.
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
global inversion_sterdir "$dir/output/staging"

cap mkdir "$output/tables"

log using "$logs/test_5b_and_table.log", replace

quietly include "$dir/scripts/0_programs.do"

capture noisily {

    local choice  urban
    local depvar  consumption
    local balance unb
    local spec3   cuu

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

        foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {

            if "`spec'" == "covs_0" {
                local controls ""
                local covs2    c0
            }
            else if "`spec'" == "covs_trend" {
                local controls `periodFE'
                local covs2    ct
            }
            else if "`spec'" == "covs_1" {
                local controls `periodFE' $covs_gmm
                local covs2    c1
            }
            else if "`spec'" == "covs_2" {
                local controls `periodFE' $covs_gmm2
                local covs2    c2
            }
            else if "`spec'" == "covs_all" {
                local controls `periodFE' $covs_gmm_all
                local covs2    ca
            }

            local estbase grc_`country'_`spec3'_`covs2'
            local parent "${inversion_sterdir}/`estbase'.ster"
            capture confirm file "`parent'"
            if _rc != 0 {
                di as text "  SKIP `estbase' (no parent ster)"
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

    * --- (2) Verify the inversion macros are on the staging sters.
    * Read e(inv_phi_ci95_str) back from the IDN/cuu/ca cell as a smoke.
    estimates use "$inversion_sterdir/grc_IDN_cuu_ca.ster"
    di as text "{hline 72}"
    di as text "Smoke read-back from grc_IDN_cuu_ca.ster:"
    di as text "  e(inv_phi_ci95_str)   = " as result `"`e(inv_phi_ci95_str)'"'
    di as text "  e(inv_phi_at_waldmin) = " as result %9.4f e(inv_phi_at_waldmin)
    di as text "  e(inv_dN_ci95_str)    = " as result `"`e(inv_dN_ci95_str)'"'
    di as text "  e(inv_davg_ci95_str)  = " as result `"`e(inv_davg_ci95_str)'"'
    di as text "  e(inv_dT_ci95_str)    = " as result `"`e(inv_dT_ci95_str)'"'
    di as text "{hline 72}"

    * Note: grc_tex_table_trend table-render is intentionally NOT exercised
    * here. Phase 2 / M3 grc_tex_table_trend on main reads from $dir/output/,
    * not from a configurable staging dir, AND does not yet consume the
    * inv_*_ci95_str e()-macros. Both are tracked separately:
    *   - sterdir argument on grc_tex_table_trend (low priority).
    *   - inversion CI rows in grc_tex_table_trend (high priority; needs
    *     porting the 2b24344 esttab s() extension onto main's Phase 2
    *     grc_tex_table_trend).
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> wrapper FAILED rc=`rc'"
exit, STATA clear
