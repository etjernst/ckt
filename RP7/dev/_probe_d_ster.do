version 17
clear all
if "$dir" == "" global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
quietly include "$dir/scripts/0_path_config.do"

foreach country in IDN TZA {
    di as text _newline(2) "==== `country' _d ster ===="
    quietly estimates use "$output/grc_`country'_cuu_ca_d"
    di as text "  e(cmd) = " e(cmd)
    di as text "  e(N)   = " e(N)
    di as text "  matrix list e(b):"
    matrix list e(b), noheader
}
