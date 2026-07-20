* Thin driver to run 5c_inversion_hukou.do against the hukou-split sters.
* Sets $dir / globals exactly like 0_master.do would.

version 17
clear all

if "`c(username)'" == "maand" {
    global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
global skip_if_exists = 0

quietly include "$dir/scripts/0_path_config.do"
quietly include "$dir/scripts/0_programs.do"

* Switchers needed for initial_values
global switchers ""

do "$dir/scripts/5c_inversion_hukou.do"
