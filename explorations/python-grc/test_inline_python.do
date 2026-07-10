* test_inline_python.do --- check whether Stata 19 still has the
* "program-define parser confused by python: block" issue noted in
* the 2026-04 comment in lca_inversion_ci.ado.
version 19
clear all
set more off
capture log close
log using "test_inline_python.smcl", replace

capture noisily {

    capture program drop _test_inline
    program define _test_inline, eclass
        syntax , msg(string)
        python:
        from sfi import Macro, SFIToolkit
        msg = Macro.getLocal("msg")
        SFIToolkit.displayln("python says: " + msg)
        Macro.setLocal("py_result", "python set this from inline block")
        end
        di as text "Stata sees py_result = " as result "`py_result'"
        ereturn local py_result = "`py_result'"
    end

    sysuse auto, clear
    eststo m1: regress price mpg
    _test_inline, msg("hello from a do-file")
    di as text "After call, e(py_result) = " as result `"`e(py_result)'"'
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> rc=`rc'"
exit, STATA clear
