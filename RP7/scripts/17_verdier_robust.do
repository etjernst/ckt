* ============================================================
* Title:   Verdier-style robust GRC estimator (cluster-residualized instruments)
* Author:  Emilia (with Claude)
* Date:    2026-04-29
* Purpose: Estimate the Verdier-style robust extrapolation (run_grc_robust_vv)
*          for the paper's "Allowing cluster-specific trajectory intercepts"
*          subsection. Runs both onestep (matches VV's setting) and twostep
*          (Hansen J available) so we can compare and pick.
*          Uses urban as treatment, log per-capita consumption as outcome,
*          unbalanced panel, for IDN/TZA/CHN.
* Input:   $dirdata/processed/{IDN,TZA,CHN}_unb.dta
* Output:  $output/vv_{country}_{os|ts}_covs_*.ster (5 covariate specs x 2 step variants x 3 countries)
*          $output/tables/verdier_robust_{onestep|twostep}_{country}_consumption_urban_unb.tex (6 paper tables)
*          quality_reports/reviews/2026-04-29_verdier-v2-onestep-vs-twostep.md (decision-aid markdown)
* ============================================================

* ============================================================
* Defensive prelude: when this file is run standalone via
* `stata-mp -b do 17_verdier_robust.do`, $dir is not set, and
* path globals + programs need bootstrapping. When invoked via
* `include` from 0_master.do, $dir is already set and we skip.
* ============================================================
if "$dir" == "" {
    clear all
    if "`c(username)'" == "maand" {
        global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
    }
    include "$dir/scripts/0_path_config.do"
    include "$dir/scripts/0_setup.do"
    include "$dir/scripts/0_programs.do"
    global copyOverleaf 0
}

* Resume-on-interrupt: skip cells whose final .ster (_avg) already exists.
* Set to 0 to force every cell to re-estimate.
global skip_if_exists 1

* Set log file
cd "$logs"
capture log close
log using 17_verdier_robust.log, replace

* ============================================================
* Wrap the body in capture noisily so any error is caught and
* the script always reaches `exit, STATA clear`. Without this
* wrapper, Windows pops the modal "Stata finished" dialog on
* batch-mode errors.
* ============================================================
capture noisily {

* **********************************************************************
* Choices for the analysis
* **********************************************************************
local choice  urban
local depvar  consumption
local balance unb

* GMM covariate sets (mirror 5_GrRC.do)
global covs_gmm     "female"
global covs_gmm2    "$covs_gmm age2"
global covs_gmm_all "$covs_gmm2 education_max education_max2"

* Keep only relevant variables (speeds up estimation); add vidx per country below.
* `year` is required because gen_vfirst (called inside run_grc_robust_vv) uses
* `bysort pid (year)` to identify the first-wave value of the cluster index.
global keepvars_base lndepvar trajectory choice pid year
global keepvars_base $keepvars_base period unbalanced* switcher non_switcher
global keepvars_base $keepvars_base female age age2
global keepvars_base $keepvars_base education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_*

* **********************************************************************
* Country loop: estimate onestep + twostep × 5 covariate specs each
* **********************************************************************
local iterations 100

foreach country in IDN TZA CHN {

    * Country-specific cluster index (vfirst seed)
    if "`country'" == "IDN" local vidx prov
    if "`country'" == "TZA" local vidx region
    if "`country'" == "CHN" local vidx provcd

    eststo clear

    * Open and prep data
    use "$dirdata/processed/`country'_`balance'.dta", clear
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation
    global keepvars $keepvars_base `vidx'
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * Initial values (data-driven base + starting parameter vector)
    initial_values lndepvar,        ///
        switchers($switchers)       ///
        balance(`balance')          ///
        estname(initial_`country')
    local base `r(base)'
    local initial "`r(initial)'"

    * Loop over GMM step option (onestep | twostep).
    * Use a short estname tag (os/ts) so the eststo internal name `_est_<...>`
    * stays under Stata's 32-char limit. The full word (onestep/twostep) is
    * still passed as a syntax flag to run_grc_robust_vv.
    foreach step in onestep twostep {

        if "`step'" == "onestep" local stepshort os
        else                     local stepshort ts

        di as txt "================================================================"
        di as txt "run_grc_robust_vv: country=`country' step=`step' (tag=`stepshort')"
        di as txt "================================================================"

        * No covariates
        run_grc_robust_vv,                                              ///
            estname(vv_`country'_`stepshort'_covs_0)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            iterate(`iterations') `step'

        * Add time FE
        run_grc_robust_vv,                                              ///
            estname(vv_`country'_`stepshort'_covs_trend)           ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE')                                          ///
            iterate(`iterations') `step'

        * Add female
        run_grc_robust_vv,                                              ///
            estname(vv_`country'_`stepshort'_covs_1)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE' $covs_gmm)                                ///
            iterate(`iterations') `step'

        * Add age^2
        run_grc_robust_vv,                                              ///
            estname(vv_`country'_`stepshort'_covs_2)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE' $covs_gmm2)                               ///
            iterate(`iterations') `step'

        * Add education + education^2
        run_grc_robust_vv,                                              ///
            estname(vv_`country'_`stepshort'_covs_all)             ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE' $covs_gmm_all)                            ///
            iterate(`iterations') `step'
    }
}

* **********************************************************************
* Restore all 6 sets of estimates into memory for table generation
* **********************************************************************
foreach country in IDN TZA CHN {
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
}

* **********************************************************************
* Generate paper tables (one per country × step), main-results format
* **********************************************************************
local reportvars "phi:_cons"
local varlab "$\phi$"

foreach step in onestep twostep {

    if "`step'" == "onestep" local stepshort os
    else                     local stepshort ts

    * Inject the short step tag into the country slot so grc_tex_table_trend
    * reads vv_{country}_{stepshort}_covs_X via estprefix(vv_).
    foreach country in IDN TZA CHN {

        local htb_str "htbp"

        if "`country'" == "IDN" local countryname Indonesia
        if "`country'" == "CHN" local countryname China
        if "`country'" == "TZA" local countryname Tanzania

        local table_caption "`" \caption{Cluster-Residualized GRC Estimates of the Returns to Urban Location on log Consumption in `countryname' (`step' GMM)} "'"
        local table_label "`" \label{tab:verdier_robust_`step'_`country'_`depvar'_`choice'_`balance'} "'"

        local table_notes "Cluster-residualized GRC (Verdier-style) estimates with `step' GMM. Standard errors clustered at the village (vfirst) level in parentheses. Columns (2)-(5) include time fixed effects; column (3) adds a female indicator, column (4) adds age squared, and column (5) adds education (years of schooling, maximum across periods) and its square. Stars: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."
        local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

        grc_tex_table_trend, columns(5)                                                    ///
            country(`country'_`stepshort')                                                 ///
            estprefix(vv_)                                                            ///
            filename(verdier_robust_`step'_`country'_`depvar'_`choice'_`balance')          ///
            keep(`reportvars')                                                             ///
            varlabel(`varlab')                                                             ///
            htb(`htb_str')                                                                 ///
            prehead(`table_caption' `table_label')                                         ///
            postfoot(`postfoot_str')                                                       ///
            coeflabels(choice "Urban")                                                     ///
            textdepvar( log(`depvar') )
    }
}

* **********************************************************************
* Generate the onestep-vs-twostep comparison markdown
* (one focal column = covs_all per spec M4 wording, full grid for transparency)
* **********************************************************************
local mdpath "$dir/../quality_reports/reviews/2026-04-29_verdier-v2-onestep-vs-twostep.md"
capture file close mdh
file open mdh using "`mdpath'", write replace

file write mdh "# Verdier robust estimator: onestep vs twostep comparison" _n
file write mdh "" _n
file write mdh "**Generated by:** ``17_verdier_robust.do``" _n
file write mdh "**Spec:** Consumption per capita, urban as treatment, unbalanced panel." _n
file write mdh "**Versions:** onestep (VV's setting) and twostep (Hansen J via estat overid)." _n
file write mdh "" _n
file write mdh "Each per-country block reports phi-rob, Delta-never-rob, Delta-always-rob, Delta-avg-rob, and convergence indicator." _n
file write mdh "Rows iterate 5 covariate specs x 2 GMM step variants." _n
file write mdh "Standard errors in parentheses." _n
file write mdh "" _n

foreach country in IDN TZA CHN {

    if "`country'" == "IDN" local countryname "Indonesia"
    if "`country'" == "CHN" local countryname "China"
    if "`country'" == "TZA" local countryname "Tanzania"

    file write mdh "## `countryname' (`country')" _n
    file write mdh "" _n
    file write mdh "| Spec | Step | phi | SE(phi) | Delta_never | SE | Delta_always | SE | Delta_avg | SE | Converged |" _n
    file write mdh "|------|------|-----|---------|-------------|-----|--------------|-----|-----------|-----|-----------|" _n

    foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all {
        foreach step in onestep twostep {
            if "`step'" == "onestep" local stepshort os
            else                     local stepshort ts
            local stem vv_`country'_`stepshort'_`estname'

            * phi from main ster
            capture estimates restore `stem'
            if _rc == 0 {
                local phi_b  = string(_b[phi:_cons],  "%9.4f")
                local phi_se = string(_se[phi:_cons], "%9.4f")
                local conv = e(converged_str)
                if "`conv'" == "" local conv "?"
            }
            else {
                local phi_b "FAIL"
                local phi_se "."
                local conv "FAIL"
            }

            * Delta_never
            capture estimates restore `stem'_never
            if _rc == 0 {
                local dn_b  = string(_b[Delta_never:_cons],  "%9.4f")
                local dn_se = string(_se[Delta_never:_cons], "%9.4f")
            }
            else {
                local dn_b "FAIL"
                local dn_se "."
            }

            * Delta_always: ster filename ends in _always
            capture estimates use "$dir/output/`stem'_always"
            if _rc == 0 {
                local da_b  = string(_b[Delta_always:_cons],  "%9.4f")
                local da_se = string(_se[Delta_always:_cons], "%9.4f")
            }
            else {
                local da_b "FAIL"
                local da_se "."
            }

            * Delta_avg
            capture estimates restore `stem'_avg
            if _rc == 0 {
                local davg_b  = string(_b[Delta_avg:_cons],  "%9.4f")
                local davg_se = string(_se[Delta_avg:_cons], "%9.4f")
            }
            else {
                local davg_b "FAIL"
                local davg_se "."
            }

            file write mdh "| `estname' | `step' | `phi_b' | (`phi_se') | `dn_b' | (`dn_se') | `da_b' | (`da_se') | `davg_b' | (`davg_se') | `conv' |" _n
        }
    }

    file write mdh "" _n
}

file write mdh "## Notes" _n
file write mdh "" _n
file write mdh "- Sample for the robust estimator drops observations with missing ``vfirst`` (first-wave province/region per pid). N may differ from the main GRC sample." _n
file write mdh "- Under onestep, ``estat overid`` is unavailable; Jstat is missing in those columns." _n
file write mdh "- Convergence column reports ``e(converged)`` (Y/N) for the main GMM call." _n
file write mdh "- Pick the version per country (or across the board) and replace the placeholder Overleaf table accordingly." _n

file close mdh
di as text "Comparison markdown written to: `mdpath'"

}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> 17_verdier_robust FAILED with rc=`saved_rc'"
}
* Suppress the Windows batch-mode "Stata finished" popup.
exit, STATA clear
