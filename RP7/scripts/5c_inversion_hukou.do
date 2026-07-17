/*******************************************************************************
Project: Returns to Migration
Team: E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
    - attaches weak-ID-robust LCA inversion CIs (90% and 95%) for phi and
      the three trajectory-specific deltas to the .ster files produced by
      7_GrRC_hukou.do for the urban / consumption / unbalanced mainline
      (spec3 = cuu) on the CHN hukou subsamples.
    - parallel to 5b_inversion.do, which handles the pooled IDN / TZA /
      CHN cells. Split into a separate script so the pooled and
      hukou-split inversion passes can be run independently.

Hukou subsamples handled (per the country -> country_short mapping in
7_GrRC_hukou.do):

    CHN_hukou_rural_first  -> CHN_rf  (rural-hukou-first: ever had rural hukou,
                                       headline E2 contrast vs urban-first)
    CHN_hukou_urban_first  -> CHN_uf  (urban-hukou-first: ever had urban hukou)

The rural-only (CHN_ro) and urban-only (CHN_uo) subsamples are not run
in this pass; extend the foreach loop on line ~50 when they are needed.

Output:
    Updates the four .sters per (subsample, covs2):
        grc_<country_short>_cuu_<covs2>.ster    (parent: phi inversion)
        grc_<country_short>_cuu_<covs2>_n.ster  (Delta_never inversion)
        grc_<country_short>_cuu_<covs2>_g.ster  (Delta_avg inversion)
        grc_<country_short>_cuu_<covs2>_a.ster  (Delta_always inversion)

Set ${inversion_sterdir} ahead of running this file to redirect to a
non-default location. Defaults to $output.
*******************************************************************************/

cd "$logs"
capture log close
log using 5c_inversion_hukou.log, replace

capture noisily {

    local choice  urban
    local depvar  consumption
    local balance unb
    local spec3   cuu

    if "${inversion_sterdir}" == "" {
        global inversion_sterdir "$output"
    }
    di as text "Inversion writes to: " as result "${inversion_sterdir}"

    * GMM covariates (single source; mirror 4_GrRC.do)
    set_covariate_globals

    global keepvars logpc_consumption trajectory choice pid
    global keepvars $keepvars period unbalanced* switcher non_switcher
    global keepvars $keepvars female age age2
    global keepvars $keepvars education_max education_max2 trend
    global keepvars $keepvars always always_choice never switcher_*

    * Hukou subsamples to process. RO and UO can be appended here once
    * RF/UF are validated; the rest of the loop body is subsample-agnostic.
    foreach country in CHN_hukou_rural_first CHN_hukou_urban_first {

        * country -> country_short mapping (mirror 7_GrRC_hukou.do)
        if "`country'" == "CHN_hukou_rural_first" local country_short CHN_rf
        else if "`country'" == "CHN_hukou_urban_first" local country_short CHN_uf
        else if "`country'" == "CHN_hukou_rural_only"  local country_short CHN_ro
        else if "`country'" == "CHN_hukou_urban_only"  local country_short CHN_uo

        di as text ""
        di as text "{hline 72}"
        di as text "Hukou subsample: `country' (`country_short')"
        di as text "{hline 72}"

        * --- load data and prep (mirror 5b_inversion.do)
        use "$dirdata/processed/`country'_`balance'.dta", clear
        setup_grc_estimation
        keep $keepvars
        tab period, gen(period_)
        local periodFE "period_2 - period_`r(r)'"
        drop if mi(logpc_consumption) | mi(choice)

        * --- recover base trajectory via the routine 7_GrRC_hukou.do uses
        initial_values logpc_consumption, ///
            switchers($switchers)       ///
            balance(`balance')          ///
            estname(initial_`country_short')
        local base `r(base)'
        di as text "  base trajectory = `base'"

        * --- attach inversion CIs to each (covs2, suffix) cell
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

            local estbase grc_`country_short'_`spec3'_`covs2'

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
                outcome(logpc_consumption)      ///
                traj(trajectory)                ///
                choice(choice)                  ///
                hhid(pid)                       ///
                base(`base')                    ///
                controls(`controls')
        }
    }

    di as text ""
    di as text "{hline 72}"
    di as text "5c_inversion_hukou: complete"
    di as text "{hline 72}"
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> 5c_inversion_hukou FAILED rc=`rc'"
