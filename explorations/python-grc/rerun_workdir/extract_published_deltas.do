* ============================================================
* Title:   Extract Delta_never / Delta_avg / Delta_always point
*          estimates and SEs from existing .ster files.
* Author:  delta-inversion validation gate (2026-04-29 spec)
* Date:    2026-04-29
* Purpose: Provide the Stata-side ground truth for validation
*          step 1 of the delta-inversion extension. Reads each
*          grc_{country}_{spec}_{never|avg|always}.ster file in
*          rerun_workdir/output/, pulls _b[Delta_X:_cons] and
*          _se[Delta_X:_cons], writes a long-format CSV.
* Input:   rerun_workdir/output/grc_*_*.ster (45 files)
* Output:  rerun_workdir/published_deltas.csv
* ============================================================
version 19
clear all
set more off
set varabbrev off
capture log close
log using "extract_published_deltas.smcl", replace

capture noisily {
    tempname fh
    file open `fh' using "published_deltas.csv", write replace
    file write `fh' "country,spec,delta,point,se" _n

    * Also extract GMM-side phi, Delta_base, kappa, plus the per-switcher
    * mu's (mu:never, mu:switcher_`s', etc.) and the switcher
    * sample-share weights (over e(sample)) used by Stata's Delta_avg
    * nlcom. Save to a wide CSV keyed on (country, spec).
    tempname fh2
    file open `fh2' using "published_gmm_internals.csv", write replace
    file write `fh2' "country,spec,phi,Delta_base,kappa,mu_never," ///
        "switcher_codes,mu_switchers,share_switchers" _n

    foreach country in IDN CHN TZA {
        foreach spec in covs_0 covs_trend covs_1 covs_2 covs_all {
            * Pull GMM internals from the unsuffixed .ster.
            local pt ""
            local stem_main "output/grc_`country'_`spec'"
            capture estimates use "`stem_main'"
            if _rc == 0 {
                local phi    = _b[phi:_cons]
                local Db     = _b[Delta_base:_cons]
                local ka     = _b[kappa:_cons]
                * mu:never; some specs may not have it (e.g., if the
                * trajectory was dropped). Capture per-element.
                local mu_never ""
                capture local mu_never = _b[mu:never]
                * Switcher mu's and shares: walk e(b) column names.
                local cols : colnames e(b)
                local sw_codes ""
                local sw_mus ""
                foreach c of local cols {
                    if regexm("`c'", "^mu:switcher_([0-9]+)$") {
                        local code = regexs(1)
                        local sw_codes "`sw_codes' `code'"
                        local mu_s = _b[mu:switcher_`code']
                        local sw_mus "`sw_mus' `mu_s'"
                    }
                }
                local sw_codes = trim("`sw_codes'")
                local sw_mus = trim("`sw_mus'")
                * Shares from e(sample) require the data to be in memory,
                * not just the .ster. Defer to a follow-up runner that
                * re-estimates; skip here.
                file write `fh2' "`country',`spec',`phi',`Db',`ka'," ///
                    "`mu_never',`sw_codes'," ///
                    `"""' "`sw_mus'" `"""' ",NA" _n
            }
            else {
                file write `fh2' "`country',`spec',NA,NA,NA,NA,NA,NA,NA" _n
            }

            foreach delta in never avg always {
                * Reset locals each iteration; otherwise a failed
                * `capture local pt = ...' leaves pt holding the
                * previous iteration's value, which silently
                * propagates wrong numbers through the CSV.
                local pt ""
                local sd ""
                local stem "output/grc_`country'_`spec'_`delta'"
                capture estimates use "`stem'"
                if _rc != 0 {
                    di as error "MISSING: `stem'.ster (rc=`=_rc')"
                    file write `fh' "`country',`spec',`delta',.,." _n
                    continue
                }
                * After nlcom + estimates save, the saved e(b) is a
                * 1x1 matrix with the single column "Delta_<delta>"
                * (no equation, no _cons). Use the bare _b[<name>].
                local label "Delta_`delta'"
                local pt = _b[`label']
                local sd = _se[`label']
                file write `fh' "`country',`spec',`delta',`pt',`sd'" _n
                di as text "`country' `spec' `delta': pt=`pt' se=`sd'"
            }
        }
    }
    file close `fh'
    file close `fh2'
}
local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> extract_published_deltas FAILED with rc=`saved_rc'"
}
exit, STATA clear
