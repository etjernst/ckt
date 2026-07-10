* _smoke_5b_full.do --- post-merge inversion smoke for ALL 15 cells.
*
* Runs 5b_inversion.do against the renamed staging sters at
* RP7/output/smoke/. Verifies that the post-refactor naming +
* attach_inversion_ci quote-stripping fix carries across all
* 3 countries x 5 covs specs (15 attach calls, 60 ster updates).
*
* Intended as a smoke, not production: pre-existing parent sters
* must already exist at $inversion_sterdir.
version 19
clear all
set more off
set varabbrev off
set linesize 250
capture log close

global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
quietly include "$dir/scripts/0_path_config.do"
global logs "$dir/output"
global inversion_sterdir "$dir/output/smoke"

quietly include "$dir/scripts/0_programs.do"

* 5b_inversion.do does its own log and capture wrapping.
do "$dir/scripts/5b_inversion.do"
