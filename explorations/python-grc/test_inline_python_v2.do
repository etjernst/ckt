* test_inline_python_v2.do --- workaround for Stata 19's python:/end-inside-
* program-define parser issue. Pre-define the helper at file level (where
* end correctly terminates the python block); then inside the program use
* a single-line `python: helper_fn(...)` call that has no `end` keyword.
*
* Important: the python: block contents must start at column 0 because
* Python is whitespace-sensitive; do NOT indent the body even when the
* surrounding Stata code is indented.
version 19
clear all
set more off
capture log close
log using "test_inline_python_v2.smcl", replace

* --- file-level python: block (NOT wrapped in capture noisily so
* indentation stays at column 0). The `end` here ends the python block.
python:
from sfi import Macro, SFIToolkit

def _test_helper(msg):
    SFIToolkit.displayln("python helper says: " + msg)
    Macro.setLocal("py_result", "helper returned: " + msg.upper())
end

capture noisily {

    capture program drop _test_inline_v2
    program define _test_inline_v2, eclass
        syntax , msg(string)
        python: _test_helper(Macro.getLocal("msg"))
        di as text "After python call, py_result = " as result "`py_result'"
        ereturn local py_result = "`py_result'"
    end

    sysuse auto, clear
    eststo m1: regress price mpg
    _test_inline_v2, msg("hello from a do-file")
    di as text ""
    di as text "After call, e(py_result) = " as result `"`e(py_result)'"'
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> rc=`rc'"
exit, STATA clear
