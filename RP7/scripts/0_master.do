* **********************************************************************
* Project: Returns to Migration
* Team: E. Cenci, M. Kleemans, E. Tjernström 
* Version: May 2026
* This code:
* 	Runs all of the do-files
* 	Set copyOverleaf to 1 to copy tables and figures to Overleaf 
*   (overwriting what is already there)
* **********************************************************************

clear all
version 17

* Project-wide constants ($grc_max_iter, $grc_min_switchers_per_wave) and
* `set more off` are configured in 0_path_config.do (included below) so
* alternate entry points (e.g. the run_extras_*.do slice drivers) which
* bypass this file still see them.

* **********************************************************************
* Preliminaries
* **********************************************************************
* 0 - Set up environment

* 1. Comment out filepaths that are not yours
*	You can set the "root" folder for the project below
*	i.e., modify this path as needed for your setup: 
	/* global dir "C:/Users/YourUsername/YourProjectFolder" */
					
* We can delete all the below when sharing the code

* To copy files automatically over to Overleaf, add a 
* filepath global overleaf that points to where your local 
* Overleaf repo lives
					
*** Marieke Kleemans's directories
if "`c(username)'"=="kleemans" {
	global dir = "C:\Users\kleemans\Dropbox\Returns to migration\ReplicationPackage6"
	global dir = "D:\Dropbox\Returns to migration\ReplicationPackage6"
	* Set $overleaf to your local Overleaf-Dropbox path to enable copyOverleaf.
	* global overleaf = "..."
}

*** David Buller's directories
if "`c(username)'"=="David" {
	global dir = "C:\Users\David\OneDrive - University of Illinois - Urbana\UIUC\Research\ReplicationPackage6"
	* global overleaf = "..."
}

*** Eduardo Cenci's directories
if inlist("`c(username)'", "ecenci", "educenci", "eduardocenci") {
	global dir =  "~/Dropbox/__Research/Returns to migration/ReplicationPackage6"
	* global overleaf = "..."
}

*** Emilia's git directory ***
if "`c(username)'"=="etje0002" {
	global dir = "C:/Users/etje0002/Desktop/git/ReturnsToMigration"
	* global overleaf = "..."
}
if "`c(username)'"=="maand" {
	* Path varies by worktree. Pick ONE --- uncomment the active line.
	* global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
	global dir = "C:/git/ckt/RP7"
	* Overleaf-Dropbox lives in Monash Enterprise Dropbox (not Personal).
	global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

* 2. Set up sub-folders
	include "$dir/scripts/0_path_config.do"

* 2b. Open the named master log (AEA pattern): one timestamped, text-format
* log covering the whole run, including the data-construction path. Named
* so it never collides with the per-script logs. $logs is set just above.
	local stamp : di %tdCCYY-NN-DD date("`c(current_date)'", "DMY")
	local stamp "`stamp'_`=subinstr("`c(current_time)'", ":", "-", .)'"
	capture log close master
	log using "$logs/0_master_`stamp'_`c(username)'.log", name(master) replace text

* 3. Install dependencies
	include "$scripts/0_setup.do"

* 4. Run .do file containing utility programs
	include "$scripts/0_programs.do"

* 5. Copy to Overleaf or not? 1 = will copy to Overleaf
	global copyOverleaf 0

* 6. Refresh dashboard cache + Verdier comparison memo? 1 = will run Python.
*    Default 0, this requires Python to run
	global runDashboard 0

* 7. Run the E1 counterfactual misallocation accounting? 1 = will run.
*    Default 0: like the dashboard it needs Python, plus the inversion
*    sters (5b_inversion.do) and the hukou sters (7_GrRC_hukou.do) on disk.
*    Produces output/counterfactual_results.csv and the paper table
*    output/tables/counterfactual_misallocation.tex, and self-checks the
*    numbers against the committed baseline snapshot.
	global run_counterfactuals 0

* **********************************************************************
* Run do-files
* **********************************************************************
* Run CHN hukou restrictions
	include			"$dir/scripts/0_CHN_hukou_restrictions.do"
* Set up data
	include			"$dir/scripts/1_processData.do"
* Compute & save summary statistics
	include			"$dir/scripts/2_summaryStats.do"
* Compute rank-condition diagnostic for unbalanced pooling (Appendix on pooling)
	include			"$dir/scripts/1b_unbalanced_rank_diagnostic.do"
* Run OLS & FE regressions
	include			"$dir/scripts/3_OLS_uGRC.do"
* Run GRC regressions (Urban)
	include			"$dir/scripts/4_GrRC.do"
* Attach LCA inversion CIs to the urban-mainline sters (decoupled from 4_GrRC.do
* so re-running the inversion does not re-run the GMM)
	include			"$dir/scripts/5b_inversion.do"
* Run GRC regressions (Non-Ag)
	include			"$dir/scripts/5_GrRC_NonAg.do"
* Run OLS & FE regressions (hukou)
	include			"$dir/scripts/6_OLS_uGRC_hukou.do"
* Run GRC regressions (hukou)
	include			"$dir/scripts/7_GrRC_hukou.do"
* Attach LCA inversion CIs to the hukou sters (parallel to 5b_inversion.do)
	include			"$dir/scripts/5c_inversion_hukou.do"
* Run learning regressions
	include			"$dir/scripts/8_learning.do"
* Run GRC regressions (extras: experience-family + IDN birth; 44 stems)
	include			"$dir/scripts/9_GRC_extras.do"
* Build all GRC LaTeX tables (main + non-ag + hukou + heterogeneity) from saved .ster files
	include			"$dir/scripts/10_make_tables.do"
* Make all GRC figures (heterogeneity plots + trajectory bar graphs)
	include			"$dir/scripts/11_make_figures.do"
* Run Verdier-style robust GRC (cluster-residualized instruments)
	include			"$dir/scripts/17_verdier_robust.do"
* Sole producer of cluster_comparison_consumption_unb.tex (5 rows incl. hukou splits)
	include			"$dir/scripts/17b_cluster_summary.do"
* Refresh the headlines cache (one CSV per fit) the dashboard reads instead
* of pystata round-trips. Reads only stems whose ster mtimes have changed.
* Gated behind $runDashboard so coauthors without Python don't hit errors.
	if "${runDashboard}" == "1" {
		shell python "$dir/../tools/results_overview/scrape_headlines.py" --incremental
	}
* Run the E1 counterfactual misallocation accounting (Stata orchestrates,
* Python computes). Placed after 5b and 7 because it needs the inversion
* sters (5b_inversion.do) and the hukou sters (7_GrRC_hukou.do) on disk.
	if "${run_counterfactuals}" == "1" {
		include		"$dir/scripts/12_counterfactuals.do"
	}
* Make the extrapolation-support figure and support test.
* Runs LAST: its standalone init does `clear all`, which drops the shared
* programs, so nothing that needs 0_programs.do may run after it.
	include			"$dir/scripts/11b_extrapolation_support_figure.do"

* Close the named master log.
	capture log close master
