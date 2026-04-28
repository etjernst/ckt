* **********************************************************************
* Smoke driver: run the 3 new tables-only files end to end (Phase 1b.5b).
* Does NOT run any GMM. Reads existing .ster files from $output/ and
* emits .tex via grc_tex_table_trend / _hukou. With $copyOverleaf=1,
* auto-copies the .tex files to the Overleaf-Dropbox tables/ folder.
*
* Targets ~minutes wall-clock for all 22 active GRC cells (9 main + 1
* nonag + 12 hukou). 11 of those 22 are currently in main-sections.tex
* (3 main cuu, 3 main cub, 3 main iuu, 1 nonag, 4 hukou); the others
* land in tables/ but aren't \input'd by the paper.
* **********************************************************************

clear all

if "`c(username)'" == "maand" {
    global dir = "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7"
    global overleaf = "C:/Users/maand/Monash Uni Enterprise Dropbox/Emilia Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean"
}

include "$dir/scripts/0_path_config.do"
include "$scripts/0_programs.do"

global copyOverleaf 1

include "$scripts/make_tables.do"

display as text "============ tables-only smoke complete ============"
exit, STATA clear
