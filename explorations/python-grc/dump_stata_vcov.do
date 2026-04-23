* Dump Stata's saved e(V), e(W), and theta from grc_verify.ster for
* inspection in Python. Writes three CSVs: the full VCE, the weighting
* matrix, and the parameter vector with full precision.
version 19
clear all
set more off
capture log close
log using "dump_stata_vcov.smcl", replace

global dir     "C:/Users/maand/Dropbox (Personal)/Returns to migration/ReplicationPackage6"

estimates use "$dir/output/grc_verify.ster"
matrix b = e(b)
matrix V = e(V)
matrix W = e(W)

local p = colsof(b)
local m = rowsof(W)
di as text "p = `p', m = `m'"

local names : colfullnames b

tempname fh
file open `fh' using "stata_vcov.csv", write replace
file write `fh' "row,col,value" _n
forvalues i = 1/`p' {
    forvalues j = 1/`p' {
        local v = V[`i',`j']
        file write `fh' "`i',`j',`v'" _n
    }
}
file close `fh'

tempname fhw
file open `fhw' using "stata_W.csv", write replace
file write `fhw' "row,col,value" _n
forvalues i = 1/`m' {
    forvalues j = 1/`m' {
        local v = W[`i',`j']
        file write `fhw' "`i',`j',`v'" _n
    }
}
file close `fhw'

tempname fhb
file open `fhb' using "stata_theta_full.csv", write replace
file write `fhb' "idx,name,value" _n
forvalues i = 1/`p' {
    local nm : word `i' of `names'
    local v  = b[1,`i']
    file write `fhb' "`i',`nm',`v'" _n
}
file close `fhb'

* Also print row/col label info so we can align Python and Stata orderings.
local rnames_W : rownames e(W)
local cnames_W : colnames e(W)
di as text "e(W) rows: `rnames_W'"
di as text "e(W) cols: `cnames_W'"

log close
exit, STATA clear
