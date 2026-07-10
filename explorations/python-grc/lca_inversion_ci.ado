* lca_inversion_ci.ado -- attach LCA test-inversion CIs for phi to an
* already-saved GRC estimation result via embedded Python.
*
* Usage (after run_grc has saved `grc_IDN_covs_all.ster`):
*
*   lca_inversion_ci, estname(grc_IDN_covs_all) ///
*       outcome(lndepvar) traj(trajectory) choice(choice) hhid(pid) ///
*       base(`base') [controls(period_2-period_5 female)]
*
* What it does:
*   1. restores the saved estimate so ereturn-scalars attach to e()
*   2. runs the auxiliary OLS via Python (statsmodels) on the current
*      in-memory dataset, cluster-robust at `hhid`
*   3. grid-inverts the LCA Wald at 5% and 10% type-1 error
*   4. stores results as e() scalars:
*        e(inv_phi_at_waldmin), e(inv_wald_min)
*        e(inv_ci90_lo), e(inv_ci90_hi)
*        e(inv_ci95_lo), e(inv_ci95_hi)
*      plus r() returns of the same
*   5. re-saves the .ster so the scalars persist
*
* Requires Python bindings to lca_inversion.py on the path (see local
* python_src near the top of the python: block).

capture program drop lca_inversion_ci
program define lca_inversion_ci, eclass
    syntax , ESTname(string)                                     ///
             OUTcome(string) TRAJ(string) CHOICE(string)         ///
             HHID(string) BASE(integer)                          ///
             [CONTrols(varlist fv)]                              ///
             [MIN_phi(real -3)] [MAX_phi(real 1)]                ///
             [INCrement(real 0.01)]                              ///
             [THReshold(integer 5)]                              ///
             [STERdir(string)]

    * ---- restore estimate so the re-save includes our scalars
    if "`sterdir'" != "" {
        estimates use "`sterdir'/`estname'"
    }
    else {
        estimates restore `estname'
    }

    * ---- fv-expand controls into plain var names for statsmodels
    local fvops = "`s(fvops)'" == "true" | _caller() >= 11 & "`controls'" != ""
    if `fvops' & "`controls'" != "" {
        fvexpand `controls'
        local ctrl_list = r(varlist)
    }
    else {
        local ctrl_list `controls'
    }

    * ---- push args to python (via locals)
    local outcome   `outcome'
    local traj      `traj'
    local choice    `choice'
    local hhid      `hhid'
    local base      `base'
    local ctrl_list `ctrl_list'
    local min_phi   `min_phi'
    local max_phi   `max_phi'
    local increment `increment'
    local threshold `threshold'

    * inline python: blocks confuse Stata's program-define parser, so we
    * execute the helper as an external script.
    quietly findfile lca_inversion_ci_helper.py
    local helper "`r(fn)'"
    * The helper needs to know its own directory; Stata's `python script`
    * does not set __file__ in the child interpreter.
    local helper_dir : subinstr local helper "/lca_inversion_ci_helper.py" "", all
    local helper_dir : subinstr local helper_dir "\lca_inversion_ci_helper.py" "", all
    python script "`helper'"

    * ---- pull python macros into ereturn (program is eclass; appends to
    *      the restored estimate so estimates save persists them)
    foreach s in inv_phi_at_waldmin inv_wald_min inv_J_R inv_n_kept   ///
                 inv_ci90_lo inv_ci90_hi inv_ci95_lo inv_ci95_hi {
        ereturn scalar `s' = ``s''
    }

    * ---- re-save so the scalars persist in the .ster
    if "`sterdir'" != "" {
        estimates save "`sterdir'/`estname'", replace
    }
    else {
        estimates store `estname'
    }

    * ---- pretty print
    di as text "{hline 72}"
    di as text "LCA inversion CI for phi (estimate: `estname')"
    di as text "{hline 72}"
    di as text "  switchers kept (>= `threshold' treated pids):  " as result "`inv_n_kept'"
    di as text "  J_R (restrictions):                            " as result "`inv_J_R'"
    di as text "  Wald minimum:                                  " as result %9.4f `inv_wald_min'
    di as text "  phi at Wald minimum:                           " as result %9.4f `inv_phi_at_waldmin'
    di as text "  95% CI:  [" as result %7.4f `inv_ci95_lo' as text ", " ///
        as result %7.4f `inv_ci95_hi' as text "]"
    di as text "  90% CI:  [" as result %7.4f `inv_ci90_lo' as text ", " ///
        as result %7.4f `inv_ci90_hi' as text "]"
end
