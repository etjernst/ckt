* **********************************************************************
* Audit-2026-04-28 M4 test: does the doubled mu-loop in initial_values
* actually double the local-string length, or does Stata silently
* collapse duplicates? And does Stata's gmm from(...) parser care?
*
* Test 1: build a fake `initial' the same way initial_values does (one
*         mu loop) and measure its length.
* Test 2: build it with TWO mu loops and measure its length.
*         If the second is roughly 2x the first, the macro really doubles.
*         If they're equal, Stata collapsed duplicates.
* Test 3: feed both versions to gmm on a trivial dataset; verify the
*         final coefficient is the same (last-wins or first-wins, but
*         in our code mu_<s> is the same scalar both times so it doesn't
*         matter).
*
* Run via: stata-mp -b do tests/test_gmm_from_duplicate.do
* **********************************************************************

clear all
set more off
capture log close
log using "tests/test_gmm_from_duplicate.log", replace

* --- Test 1 + 2: macro length ---
local switchers "2 3 4 5 6"
local initial_one ""
foreach s of numlist `switchers' {
    local initial_one "`initial_one' mu:switcher_`s' mu_`s'"
}
local initial_one "`initial_one' kappa: kappa"

local initial_two ""
foreach s of numlist `switchers' {
    local initial_two "`initial_two' mu:switcher_`s' mu_`s'"
}
local initial_two "`initial_two' kappa: kappa"
foreach s of numlist `switchers' {
    local initial_two "`initial_two' mu:switcher_`s' mu_`s'"
}

local len_one  = length("`initial_one'")
local len_two  = length("`initial_two'")
local ratio    = `len_two' / `len_one'

di as text "Test 1: one mu-loop  string length = `len_one'"
di as text "Test 2: two mu-loops string length = `len_two'"
di as text "Ratio (two/one) = " %5.2f `ratio'
di as text ""
di as text "VERDICT: " cond(`ratio' > 1.5, "doubles (no collapse) --- audit M4 confirmed", ///
    cond(`ratio' < 1.1, "collapses --- audit M4 wrong", "ambiguous, inspect manually"))
di as text ""

* --- Test 3: gmm semantics with duplicate parameter entries ---
* Trivial dataset: y = a + b*x + e, a true = 1, b true = 2.
set seed 12345
set obs 200
gen x = rnormal()
gen y = 1 + 2*x + rnormal()*0.5

* Baseline: pass each parameter once with the "true" starting value.
gmm (y - {a} - {b}*x), instruments(x) from(a 1 b 2) onestep nolog
matrix b_one = e(b)

* Doubled: pass each parameter twice (same value); does Stata accept it?
* Result should equal baseline.
gmm (y - {a} - {b}*x), instruments(x) from(a 1 b 2 a 1 b 2) onestep nolog
matrix b_two = e(b)

* Compare coefficients
di as text "Baseline a, b: " _b[a:_cons] ", " _b[b:_cons]
matrix list b_one
matrix list b_two

* --- Test 4: gmm semantics with duplicate parameter entries having
*             DIFFERENT values. This is what would happen if the
*             initial_values code stored different mu_<s> scalars on
*             the two passes, which it doesn't currently. Test what
*             Stata does: first-wins, last-wins, or error?
gmm (y - {a} - {b}*x), instruments(x) from(a 1 b 2 a 50 b -50) onestep nolog
matrix b_diff = e(b)
di as text "Different-value duplicate run a, b: " _b[a:_cons] ", " _b[b:_cons]

* If gmm is happy and converges to the same solution regardless of
* starting value, the duplicate is harmless even with different values.
* If gmm errors or diverges, the bug would matter.

log close
exit, STATA clear
