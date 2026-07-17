* *******************************************************************
* Title:   Gate-panel slice of 17_verdier_robust.do (Stage 0 baseline)
* Author:  Emilia Tjernstrom
* Date:    2026-07-15
* Purpose: Verdier robustness grid on TZA only (plan appendix); full
*          onestep/twostep x 5-spec grid kept, it is the VV deliverable.
*          Blocks below are verbatim copies of the source script;
*          re-slice from source if it changes.
* *******************************************************************

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

if "$dir" == "" {
    di as error "17_verdier_robust: \$dir not set."
    exit 198
}

* Resume-on-interrupt: skip cells whose final .ster (_avg) already exists.
* Set to 0 to force every cell to re-estimate.
global skip_if_exists 1

* Set log file
cd "$logs"
capture log close
log using gate_panel_verdier.log, replace

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

* GMM covariate sets (single source; mirror 4_GrRC.do)
set_covariate_globals

* Keep only relevant variables (speeds up estimation); add vidx per country below.
* `year` is required because gen_vfirst (called inside run_grc_robust_vv) uses
* `bysort pid (year)` to identify the first-wave value of the cluster index.
global keepvars_base logpc_consumption trajectory choice pid year
global keepvars_base $keepvars_base period unbalanced* switcher non_switcher
global keepvars_base $keepvars_base female age age2
global keepvars_base $keepvars_base education_max education_max2 trend
global keepvars_base $keepvars_base always always_choice never switcher_*

* **********************************************************************
* Country loop: estimate onestep + twostep × 5 covariate specs each
* **********************************************************************
local iterations 100

foreach country in TZA {

    * Country-specific cluster index (vfirst seed)
    if "`country'" == "IDN" local vidx prov
    if "`country'" == "TZA" local vidx region
    if "`country'" == "CHN" local vidx provcd

    eststo clear

    * Open and prep data
    use "$dirdata/processed/`country'_`balance'.dta", clear
    setup_grc_estimation
    global keepvars $keepvars_base `vidx'
    keep $keepvars

    tab period, gen(period_)
    local periodFE "period_2 - period_`r(r)'"

    * Initial values (data-driven base + starting parameter vector)
    initial_values logpc_consumption,        ///
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
        capture noisily run_grc_robust_vv,                              ///
            estname(vv_`country'_`stepshort'_covs_0)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            iterate(`iterations') `step'

        * Add time FE
        capture noisily run_grc_robust_vv,                              ///
            estname(vv_`country'_`stepshort'_covs_trend)           ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE')                                          ///
            iterate(`iterations') `step'

        * Add female
        capture noisily run_grc_robust_vv,                              ///
            estname(vv_`country'_`stepshort'_covs_1)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE' $covs_gmm)                                ///
            iterate(`iterations') `step'

        * Add age^2
        capture noisily run_grc_robust_vv,                              ///
            estname(vv_`country'_`stepshort'_covs_2)               ///
            switchers($switchers) base(`base') initial(`initial')       ///
            balance(`balance') vindex(`vidx')                           ///
            covars(`periodFE' $covs_gmm2)                               ///
            iterate(`iterations') `step'

        * Add education + education^2
        capture noisily run_grc_robust_vv,                              ///
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
foreach country in TZA {
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
    foreach country in TZA {

        local htb_str "htbp"

        if "`country'" == "IDN" local countryname Indonesia
        if "`country'" == "CHN" local countryname China
        if "`country'" == "TZA" local countryname Tanzania

        local table_caption "`" \caption{Restricted GRC estimates of the returns to urban location with location-specific trajectory intercepts (`countryname')} "'"
        local table_label "`" \label{tab:verdier_robust_`step'_`country'_`depvar'_`choice'_`balance'} "'"

        local table_notes "Cluster-residualized GRC estimates with `step' GMM. Standard errors clustered at the location level (first-wave province in Indonesia and China, region in Tanzania) in parentheses. Columns (2)-(5) include time fixed effects; column (3) adds a female indicator, column (4) adds age squared, and column (5) adds education (years of schooling, maximum across periods) and its square. Stars: $^{*} p<0.10$; $^{**} p<0.05$; $^{***} p<0.01$."
        local postfoot_str Time FE & & Y & Y & Y & Y \\ Covariates & & & Female & \& Age$^2$ & All \\ \bottomrule \end{tabular} \begin{tablenotes}[flushleft] \footnotesize \item{`table_notes'} \end{tablenotes} \end{threeparttable} \end{table}

        grc_tex_table_trend_robust, columns(5)                                             ///
            country(`country'_`stepshort')                                                 ///
            estprefix(vv_)                                                                 ///
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
* Paper-facing output for the "Robustness to cluster pooling" subsection:
* the onestep per-country tables under the GRC_{country}_..._cluster
* name that the paper \input{}s.
*
* The baseline-vs-cluster summary table (cluster_comparison_`depvar'_`balance'.tex)
* is NOT built here. It is produced solely by 17b_cluster_summary.do, which
* covers all five rows (IDN, CHN, CHN rural-first, CHN urban-first, TZA)
* including the hukou splits; building it here too would clobber that
* 5-row table with a 3-country version.
* **********************************************************************
foreach country in TZA {
    copy "$output/tables/verdier_robust_onestep_`country'_`depvar'_`choice'_`balance'.tex" ///
         "$output/tables/GRC_`country'_`depvar'_`choice'_`balance'_cluster.tex", replace
}

* **********************************************************************
* Generate the onestep-vs-twostep comparison markdown.
* Delegated to gen_verdier_comparison.py: it parses the 6 .tex tables
* just produced above and writes both a markdown summary and a tidy CSV
* to quality_reports/reviews/. Python avoids the file-write fragilities
* (file flush throwing r(198), and estimates restore vs estimates use
* mismatches) that broke the in-Stata version. Numbers in the comparison
* are taken verbatim from the .tex tables, so what you read there is
* exactly what the paper reports.
*
* Gated behind $runDashboard so coauthors without Python don't hit errors.
* The .tex tables above are still produced regardless --- this only skips
* the internal markdown/CSV review summary.
* **********************************************************************
if "${runDashboard}" == "1" {
    shell python "$dir/scripts/gen_verdier_comparison.py"
}

}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> 17_verdier_robust FAILED with rc=`saved_rc'"
}
