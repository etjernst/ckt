* test_inline_python_v3.do --- check whether python set exec_mode shared
* lets a function defined at file level survive into an in-program call.
version 19
clear all
set more off
capture log close
log using "test_inline_python_v3.smcl", replace

* try to set shared mode (may not exist in 19 with this exact syntax)
capture python set exec_mode shared
di as text "python set exec_mode shared rc=" as result _rc

python query

* file-level def
python:
from sfi import Macro, SFIToolkit
def _test_helper(msg):
    SFIToolkit.displayln("python helper says: " + msg)
    Macro.setLocal("py_result", "helper returned: " + msg.upper())
SFIToolkit.displayln("module __name__ at def time: " + __name__)
SFIToolkit.displayln("_test_helper id at def time: " + str(id(_test_helper)))
end

* probe: can a second top-level block see the def?
python:
from sfi import SFIToolkit
SFIToolkit.displayln("second block: __name__ = " + __name__)
try:
    SFIToolkit.displayln("second block sees _test_helper id = " + str(id(_test_helper)))
except NameError as e:
    SFIToolkit.displayln("second block: NameError " + str(e))
end

capture program drop _t3
program define _t3, eclass
    syntax , msg(string)
    python: from sfi import SFIToolkit; SFIToolkit.displayln("inside program, __name__ = " + __name__)
    capture python: _test_helper(Macro.getLocal("msg"))
    di as text "rc after python call: " _rc
end

sysuse auto, clear
eststo m1: regress price mpg
_t3, msg("hello from program")

capture log close
exit, STATA clear
