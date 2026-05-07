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
* alternate entry points (e.g. _smoke_full.do) which bypass this file
* still see them.

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
	global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
	* global dir = "C:/git/ckt/RP7"
	* Overleaf-Dropbox lives in Monash Enterprise Dropbox (not Personal).
	global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

* 2. Set up sub-folders
	include "$dir/scripts/0_path_config.do"

* 3. Install dependencies
	include "$scripts/0_setup.do"

* 4. Run .do file containing utility programs
	include "$scripts/0_programs.do"

* 5. Copy to Overleaf or not? 1 = will copy to Overleaf
	global copyOverleaf 1

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
* Run GRC regressions (Non-Ag)
	include			"$dir/scripts/5_GrRC_NonAg.do"
* Run OLS & FE regressions (hukou)
	include			"$dir/scripts/6_OLS_uGRC_hukou.do"
* Run GRC regressions (hukou)
	include			"$dir/scripts/7_GrRC_hukou.do"
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
