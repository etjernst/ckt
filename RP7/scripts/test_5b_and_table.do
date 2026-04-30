* test_5b_and_table.do --- end-to-end verification for Step 5.
*
* Inlines 5b_inversion.do's body so the trailing `exit, STATA clear`
* in that file does not interrupt the table-render that follows.
* Production runs invoke 5b_inversion.do as a top-level script.
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

    * --- (2) Render the IDN consumption table via grc_tex_table_trend.
    * The program reads `grc_<country>_urban_covs_<k>{,_never,_avg}.ster`
    * names; we point $output at the staging dir so its tables/ output
    * also lands there.
    global output "$dir/output/staging"
    cap mkdir "$output/tables"

    * Restore stored estimates from the staging sters so esttab finds them
    * by stored-estimate name (separate from file-on-disk).
    foreach country in IDN TZA CHN {
        foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
            foreach suffix in "" "_never" "_avg" "_always" {
                local estname grc_`country'_urban_`spec'`suffix'
                capture estimates use "$inversion_sterdir/`estname'.ster"
                if _rc == 0 estimates store `estname'
            }
        }
    }

    grc_tex_table_trend,                                  ///
        columns(5)                                        ///
        filename("test_inversion_IDN_consumption")        ///
        country(IDN)                                      ///
        spec(urban)                                       ///
        keep("Delta_base:_cons phi:_cons")                ///
        varlabel("$\beta$")                               ///
        htb("htbp")                                       ///
        prehead("\caption{IDN GRC with LCA inversion CIs}")  ///
        postfoot("\bottomrule \end{tabular} \end{threeparttable} \end{table}") ///
        coeflabels("Delta_base:_cons \beta phi:_cons \phi") ///
        textdepvar("log consumption")
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> wrapper FAILED rc=`rc'"
exit, STATA clear
