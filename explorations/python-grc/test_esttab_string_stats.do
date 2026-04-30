* test_esttab_string_stats.do --- verify that esttab's stats() clause
* accepts e()-stored MACROS (not just scalars) and passes LaTeX escape
* sequences ($\cup$, $\pm\infty$) through to the .tex fragment verbatim.
*
* The pipeline-integration plan stores pre-formatted bracketed CI strings
* in e()-macros (e.g. e(inv_phi_ci95_str) = "[-0.547, -0.302]") and asks
* esttab to render them via stats(...). This test confirms the approach
* before we wire it into 0_programs.do.
version 19
clear all
set more off
set varabbrev off
capture log close
log using "test_esttab_string_stats.smcl", replace

* tiny eclass wrapper so ereturn local/scalar are legal calls
capture program drop _attach_test_strings
program define _attach_test_strings, eclass
    syntax , phi95(string) phi90(string) dT95(string) dT90(string) ///
             phi95lo(real) phi95hi(real)
    ereturn local inv_phi_ci95_str = "`phi95'"
    ereturn local inv_phi_ci90_str = "`phi90'"
    ereturn local inv_dT_ci95_str  = "`dT95'"
    ereturn local inv_dT_ci90_str  = "`dT90'"
    ereturn scalar inv_phi_ci95_lo = `phi95lo'
    ereturn scalar inv_phi_ci95_hi = `phi95hi'
end

capture noisily {

    * --- fake estimation result so eststo has something to attach to
    sysuse auto, clear
    eststo m1: regress price mpg
    eststo m2: regress price mpg weight

    * --- attach pre-formatted CI strings as e()-macros, scalars, and a
    * mixed combination, so we can see what esttab will actually render.
    estimates restore m1
    _attach_test_strings,                                                       ///
        phi95("[-0.547, -0.302]")                                                ///
        phi90("[-0.512, -0.337]")                                                ///
        dT95("[\$-\infty\$, +0.040] \$\cup\$ [+0.660, \$+\infty\$]")             ///
        dT90("[\$-\infty\$, +0.180] \$\cup\$ [+0.520, \$+\infty\$]")             ///
        phi95lo(-0.547) phi95hi(-0.302)
    estimates store m1

    estimates restore m2
    _attach_test_strings,                                                       ///
        phi95("[-0.621, -0.255]")                                                ///
        phi90("[-0.589, -0.288]")                                                ///
        dT95("[-1.234, +1.234]")                                                 ///
        dT90("[-1.100, +1.100]")                                                 ///
        phi95lo(-0.621) phi95hi(-0.255)
    estimates store m2

    * --- show that the macros made it into e()
    estimates restore m1
    di as text "m1 e(inv_phi_ci95_str) = " as result `"`e(inv_phi_ci95_str)'"'
    di as text "m1 e(inv_dT_ci95_str)  = " as result `"`e(inv_dT_ci95_str)'"'
    di as text "m1 e(inv_phi_ci95_lo)  = " as result %9.3f e(inv_phi_ci95_lo)

    * --- Test 1: stats() with macro names. This is the main question.
    di as text "{hline 72}"
    di as text "Test 1: stats() with e()-macros only"
    di as text "{hline 72}"
    esttab m1 m2 using "test_esttab_macros.tex",                 ///
        replace booktabs fragment                                 ///
        b(%9.3f) se nostar                                        ///
        stats(inv_phi_ci90_str inv_phi_ci95_str                   ///
              inv_dT_ci90_str  inv_dT_ci95_str,                   ///
              labels("90\% LCA inv. CI ($\phi$)"                  ///
                     "95\% LCA inv. CI ($\phi$)"                  ///
                     "90\% LCA inv. CI ($\Delta_{always}$)"       ///
                     "95\% LCA inv. CI ($\Delta_{always}$)"))     ///
        nomtitles

    * --- Test 2: mix scalars and macros in stats()
    di as text "{hline 72}"
    di as text "Test 2: stats() mixes scalars and macros"
    di as text "{hline 72}"
    esttab m1 m2 using "test_esttab_mixed.tex",                  ///
        replace booktabs fragment                                 ///
        b(%9.3f) se nostar                                        ///
        stats(inv_phi_ci95_lo inv_phi_ci95_hi inv_phi_ci95_str    ///
              inv_dT_ci95_str,                                    ///
              fmt(%9.3f %9.3f s s)                                ///
              labels("95\% lo" "95\% hi"                          ///
                     "95\% LCA inv. CI ($\phi$)"                  ///
                     "95\% LCA inv. CI ($\Delta_{always}$)"))     ///
        nomtitles

    * --- Test 3: minimal (no fmt() override) to check default behavior
    di as text "{hline 72}"
    di as text "Test 3: minimal stats() with macros, no fmt override"
    di as text "{hline 72}"
    esttab m1 m2 using "test_esttab_minimal.tex",                ///
        replace booktabs fragment                                 ///
        b(%9.3f) se nostar                                        ///
        stats(inv_phi_ci95_str inv_dT_ci95_str)                   ///
        nomtitles

    * --- echo each generated .tex to the log so we can eyeball it
    foreach f in test_esttab_macros.tex test_esttab_mixed.tex test_esttab_minimal.tex {
        di as text ""
        di as text "{hline 72}"
        di as text "==> `f' contents:"
        di as text "{hline 72}"
        type "`f'"
    }
}
local rc = _rc
capture log close
if `rc' != 0 {
    di as error ">>> SCRIPT FAILED with rc=`rc'"
}
exit, STATA clear
