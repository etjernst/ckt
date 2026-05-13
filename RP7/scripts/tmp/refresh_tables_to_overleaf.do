* ============================================================
* Title:   Refresh tables to Overleaf (one-off)
* Purpose: Re-run 10_make_tables.do with copyOverleaf=1 so the
*          slim-tabular versions written since the Phase 1b
*          preamble-macro migration finally land in the Overleaf
*          tables/ folder. Reads existing .ster files; no re-estimation.
* Notes:   One-off driver, not part of the production master pipeline.
*          Delete after the refresh has been verified.
* ============================================================

clear all
version 17
set more off

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
    global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

if "$dir" == "" {
    di as error "refresh_tables_to_overleaf: \$dir not set for user `c(username)'"
    exit 198
}

include "$dir/scripts/0_path_config.do"
quietly include "$scripts/0_programs.do"

global copyOverleaf 1

include "$scripts/10_make_tables.do"
