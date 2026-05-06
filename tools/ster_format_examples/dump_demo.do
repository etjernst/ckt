* ============================================================
* dump_demo.do --- one-off ster-scraper format demo
*
* Reads 6 representative .ster files and writes a long-format
* CSV with one row per (ster, coefficient).  Python step in
* sibling script pivots to wide format for side-by-side compare.
*
* Stand-in for the eventual S1 ster scraper.  Throwaway script;
* paths are absolute on purpose so it runs from anywhere.
* ============================================================

clear all
set more off
version 17

local outdir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/ster_format_examples"
local sterdir "C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output"

local sters ///
    grc_IDN_cuu_c0  ///
    grc_IDN_cuu_ca  ///
    grc_IDN_cuu_ca_n  ///
    grc_CHN_cuu_ca  ///
    grc_TZA_cuu_ca  ///
    grc_IDN_iuu_ca

* Open the long-format CSV and write the header row.
file open fh using "`outdir'/demo_long.csv", write replace
file write fh "ster,country,spec3,covs2,suffix,N,coef_name,coef_value,coef_se" _n

foreach s of local sters {
    estimates use "`sterdir'/`s'.ster"

    * Parse filename tokens.  ster name is grc_<country>_<spec3>_<covs2>[_<suffix>].
    local stem = subinstr("`s'", "grc_", "", 1)
    tokenize "`stem'", parse("_")
    local country `1'
    local spec3 `3'
    local covs2 `5'
    local suffix ""
    if "`7'" != "" local suffix `7'

    local nobs = e(N)

    * Walk e(b) and pair with diagonal of e(V) for SEs.
    matrix b = e(b)
    matrix V = e(V)
    local k = colsof(b)
    local cn : colnames b
    forvalues i = 1/`k' {
        local name : word `i' of `cn'
        local val = b[1, `i']
        local var = V[`i', `i']
        if `var' >= 0 {
            local se = sqrt(`var')
        }
        else {
            local se = .
        }
        file write fh "`s',`country',`spec3',`covs2',`suffix',`nobs',`name',`val',`se'" _n
    }
}

file close fh
display as text "Wrote demo_long.csv"

exit, STATA clear
