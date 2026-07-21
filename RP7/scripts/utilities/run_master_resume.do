* ============================================================
* Title:   run_master_resume.do
* Author:  Emilia (with Claude)
* Date:    2026-04-24
* Purpose: Resume the full pipeline (0_master.do) with skip_if_exists=1,
*          so already-saved _g.ster cells are reused instead of re-fit.
*          Equivalent semantics to running 0_master.do, except slow GMM
*          cells are short-circuited. Inherits copyOverleaf from master.
* Input:   Existing _g.ster files in $output (used as cache hits).
*          $dir resolved via the user-block ladder below (mirrors 0_master.do).
* Output:  All artifacts produced by 0_master.do (tables, figures,
*          remaining .ster files, optional Python dashboard tail).
* Notes:   To force a re-fit of any cell, delete its sters before launching.
*          The skip-if-exists logic lives in run_grc inside 0_programs.do;
*          search there for `skip_if_exists` to inspect the gate.
* ============================================================

clear all
set more off
version 17

* $dir per user --- mirrors the layout in 0_master.do.

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
	global dir = "C:/git/ckt/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
	* global dir = "C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7"
	* Overleaf-Dropbox lives in Monash Enterprise Dropbox (not Personal).
	global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

if "$dir" == "" {
	di as error "run_master_resume: \$dir not set for user `c(username)'. Add a user block above."
	exit 198
}

global skip_if_exists 1
do "$dir/scripts/0_master.do"
