* test_inline_python_v4.do --- import-from-module pattern: put the helper
* in a module on sys.path, import it inside the program.
version 19
clear all
set more off
capture log close
log using "test_inline_python_v4.smcl", replace

* sys.path setup at file level
python:
import sys, os
HERE = r"C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc"
if HERE not in sys.path:
    sys.path.insert(0, HERE)
end

capture program drop _t4
program define _t4, eclass
    syntax , msg(string)
    python: import lca_inversion as _li; from sfi import Macro, SFIToolkit; SFIToolkit.displayln("imported from program; lca_inversion has compute_all_inversion_cis: " + str(hasattr(_li, "compute_all_inversion_cis"))); Macro.setLocal("py_result", "ok msg=" + Macro.getLocal("msg"))
    di as text "py_result = " as result `"`py_result'"'
    ereturn local py_result = "`py_result'"
end

sysuse auto, clear
eststo m1: regress price mpg
_t4, msg("hello world")
di as text "After call: e(py_result) = " as result `"`e(py_result)'"'

capture log close
exit, STATA clear
