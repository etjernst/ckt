* *******************************************************************
* Title:   Stage 0 --- cheap non-destructive verification checks
* Author:  CKT pipeline refactor
* Date:    2026-07-14
* Purpose: Safety foundation for the pipeline refactor. Four read-only
*          checks that require no GMM refit:
*            A. environment capture (Stata/MP configuration)
*            B. data hub confirmation ($dirdata/processed inventory)
*            C. no-op proof for the redundant lndepvar rebuild the
*               refactor will delete
*            D. N-reconciliation baseline from existing group-average
*               GRC sters (grc_*_g.ster)
* Input:   processed .dta files under $dirdata  (READ-ONLY)
*          group-average GRC sters in $dir/output (READ-ONLY)
*          $dir/scripts/0_path_config.do
* Output:  quality_reports/staging/stage0/environment.txt
*          quality_reports/staging/stage0/noop_lndepvar.csv
*          quality_reports/staging/stage0/baseline_N.csv
*          $dir/tests/stage0/stage0_checks.log
* Note:    Strictly read-only against $dirdata and existing .ster files.
*          Writes only to quality_reports/staging/stage0/ and its own log.
* Historical artifact: check C's lndepvar no-op proof targets the
*          pre-rename variable name and must run against the pre-rename
*          hub. After the Stage 2 rename (lndepvar -> logpc_consumption /
*          logpc_income), check C silently no-ops against the live hub.
*          Do not re-run this file for live signal.
* *******************************************************************

version 17
clear all
set more off
set varabbrev off
set linesize 250

* --- Bootstrap: minimal globals, no 0_setup.do (would prompt to install
* packages) and no 0_programs.do (this file never estimates anything) ---
global dir "C:/git/ckt/RP7"
include "$dir/scripts/0_path_config.do"

* --- Create the two report directories this stage owns. Never write
* anywhere under $dirdata or the existing sters in $dir/output. ---
capture mkdir "$dir/tests"
capture mkdir "$dir/tests/stage0"
capture mkdir "C:/git/ckt/quality_reports/staging"
capture mkdir "C:/git/ckt/quality_reports/staging/stage0"

global stage0dir "C:/git/ckt/quality_reports/staging/stage0"

* Output captured by the stata-mp -e auto-log (<basename>.log in the run cwd).

local overall_fail = 0

capture noisily {

    di as text "{hline 72}"
    di as text "STAGE 0 CHECKS --- non-destructive, no-GMM-refit verification"
    di as text "{hline 72}"

    * ===================================================================
    * Section A --- environment capture
    * ===================================================================
    di as text ""
    di as text "--- Section A: environment capture ---"

    di as text "c(stata_version)  = " as result "`c(stata_version)'"
    di as text "c(version)        = " as result "`c(version)'"
    di as text "c(MP)             = " as result `c(MP)'
    di as text "c(SE)             = " as result `c(SE)'
    di as text "c(processors)     = " as result `c(processors)'
    di as text "c(processors_max) = " as result `c(processors_max)'
    di as text "c(maxvar)         = " as result `c(maxvar)'
    di as text "c(os)             = " as result "`c(os)'"
    di as text "c(machine_type)   = " as result "`c(machine_type)'"
    di as text "\$values           = " as result "$values"
    di as text "\$vsfx             = " as result "$vsfx"
    di as text "\$dirdata          = " as result "$dirdata"

    tempname envf
    file open `envf' using "$stage0dir/environment.txt", write replace
    file write `envf' "stage0_checks environment capture" _n
    file write `envf' "c(stata_version)  = `c(stata_version)'" _n
    file write `envf' "c(version)        = `c(version)'" _n
    file write `envf' "c(MP)             = `c(MP)'" _n
    file write `envf' "c(SE)             = `c(SE)'" _n
    file write `envf' "c(processors)     = `c(processors)'" _n
    file write `envf' "c(processors_max) = `c(processors_max)'" _n
    file write `envf' "c(maxvar)         = `c(maxvar)'" _n
    file write `envf' "c(os)             = `c(os)'" _n
    file write `envf' "c(machine_type)   = `c(machine_type)'" _n
    file write `envf' "values            = $values" _n
    file write `envf' "vsfx              = $vsfx" _n
    file write `envf' "dirdata           = $dirdata" _n
    file close `envf'

    di as text "Section A wrote $stage0dir/environment.txt"

    * ===================================================================
    * Section B --- hub confirmation (read-only; no writes under $dirdata)
    * ===================================================================
    di as text ""
    di as text "--- Section B: hub confirmation ---"

    capture local dta_files : dir "$dirdata/processed" files "*.dta"
    local secB_rc = _rc

    if `secB_rc' != 0 {
        di as error "FAIL: $dirdata/processed does not exist or is unreadable (rc=`secB_rc')"
        local overall_fail = 1
    }
    else {
        local n_dta : word count `dta_files'
        di as text "Found `n_dta' .dta files under $dirdata/processed (expected 34):"
        foreach f of local dta_files {
            di as text "  `f'"
        }
        if `n_dta' != 34 {
            di as error "WARN: expected 34 processed files, found `n_dta'. Continuing; not treated as fatal."
        }
        else {
            di as text "PASS: 34 processed files found, as expected."
        }
    }

    * ===================================================================
    * Section C --- no-op inventory for the per-capita outcome
    * ===================================================================
    di as text ""
    di as text "--- Section C: no-op proof for lndepvar rebuild ---"

    if `secB_rc' != 0 {
        di as error "SKIP Section C: hub confirmation failed in Section B."
        local overall_fail = 1
    }
    else {
        * split the inventory into consumption-based vs income-based cells
        * by filename; income files carry "income" in the name (see
        * 1_processData.do save lines).
        local cons_files ""
        local inc_files  ""
        foreach f of local dta_files {
            if strpos("`f'", "income") > 0 {
                local inc_files "`inc_files' `f'"
            }
            else {
                local cons_files "`cons_files' `f'"
            }
        }
        local n_cons : word count `cons_files'
        local n_inc  : word count `inc_files'
        di as text "Consumption-based cells: `n_cons'.  Income-based cells: `n_inc'."

        tempname csvC
        file open `csvC' using "$stage0dir/noop_lndepvar.csv", write replace
        file write `csvC' "cell,N,max_absdiff,max_absdiff_dividetwice" _n

        local n_cons_checked = 0
        local n_cons_fail    = 0

        foreach f of local cons_files {
            local cell = subinstr("`f'", ".dta", "", .)

            capture noisily {
                use "$dirdata/processed/`f'", clear

                capture confirm variable lndepvar
                local has_lndepvar = (_rc == 0)
                capture confirm variable consumption
                local has_consumption = (_rc == 0)
                capture confirm variable hhsize_cube
                local has_hhsize = (_rc == 0)

                if `has_lndepvar' == 0 | `has_consumption' == 0 | `has_hhsize' == 0 {
                    di as error "  SKIP `cell': missing lndepvar/consumption/hhsize_cube (lndepvar=`has_lndepvar' consumption=`has_consumption' hhsize_cube=`has_hhsize')"
                    file write `csvC' "`cell',NA,NA,NA" _n
                }
                else {
                    quietly gen double _chk     = log(consumption/hhsize_cube)
                    quietly gen double _absdiff = abs(lndepvar - _chk)
                    * divide-twice probe: should NOT be a no-op, confirms
                    * the check above actually discriminates
                    quietly gen double _wrong    = log(consumption/hhsize_cube/hhsize_cube)
                    quietly gen double _absdiff2 = abs(lndepvar - _wrong)

                    quietly count
                    local N = r(N)
                    quietly sum _absdiff
                    local maxdiff = r(max)
                    quietly sum _absdiff2
                    local maxdiff2 = r(max)

                    local maxdiff_str  = strofreal(`maxdiff',  "%12.6e")
                    local maxdiff2_str = strofreal(`maxdiff2', "%12.6e")

                    file write `csvC' "`cell',`N',`maxdiff_str',`maxdiff2_str'" _n

                    local n_cons_checked = `n_cons_checked' + 1
                    if (`maxdiff' >= 1e-5) | (`maxdiff2' <= 0.1) {
                        local n_cons_fail = `n_cons_fail' + 1
                        di as error "  FAIL `cell': N=`N' max_absdiff=`maxdiff_str' max_absdiff_dividetwice=`maxdiff2_str'"
                    }
                    else {
                        di as text "  PASS `cell': N=`N' max_absdiff=`maxdiff_str' max_absdiff_dividetwice=`maxdiff2_str'"
                    }
                }
            }
            if _rc != 0 {
                di as error "  ERROR `cell': rc=`_rc' while running no-op check"
                local n_cons_fail = `n_cons_fail' + 1
                file write `csvC' "`cell',NA,NA,NA" _n
            }
        }

        di as text ""
        di as text "Consumption cells checked: `n_cons_checked'.  Failures: `n_cons_fail'."
        if `n_cons_fail' > 0 {
            local overall_fail = 1
        }

        * income cells: confirm lndepvar already carries the per-capita
        * INCOME outcome (log(income/hhsize_cube)), not a formal PASS/FAIL
        * gate --- diagnostic only, recorded in the same CSV for reference.
        di as text ""
        di as text "Income cells (diagnostic; lndepvar should equal log(income/hhsize_cube)):"
        foreach f of local inc_files {
            local cell = subinstr("`f'", ".dta", "", .)

            capture noisily {
                use "$dirdata/processed/`f'", clear

                capture confirm variable lndepvar
                local has_lndepvar = (_rc == 0)
                capture confirm variable income
                local has_income = (_rc == 0)
                capture confirm variable hhsize_cube
                local has_hhsize = (_rc == 0)

                if `has_lndepvar' == 0 | `has_income' == 0 | `has_hhsize' == 0 {
                    di as error "  SKIP `cell': missing lndepvar/income/hhsize_cube (lndepvar=`has_lndepvar' income=`has_income' hhsize_cube=`has_hhsize')"
                    file write `csvC' "`cell',NA,NA,NA" _n
                }
                else {
                    quietly gen double _chk_inc     = log(income/hhsize_cube)
                    quietly gen double _absdiff_inc = abs(lndepvar - _chk_inc)

                    quietly count
                    local N = r(N)
                    quietly sum _absdiff_inc
                    local maxdiff = r(max)
                    local maxdiff_str = strofreal(`maxdiff', "%12.6e")

                    file write `csvC' "`cell',`N',`maxdiff_str',NA" _n
                    di as text "  `cell': N=`N' max|lndepvar - log(income/hhsize_cube)|=`maxdiff_str'"
                }
            }
            if _rc != 0 {
                di as error "  ERROR `cell': rc=`_rc' while checking income lndepvar"
                file write `csvC' "`cell',NA,NA,NA" _n
            }
        }

        file close `csvC'
        di as text "Section C wrote $stage0dir/noop_lndepvar.csv"
    }

    * ===================================================================
    * Section D --- N-reconciliation baseline (reads sters, no refit)
    * ===================================================================
    di as text ""
    di as text "--- Section D: N-reconciliation baseline from grc_*_g.ster ---"

    local gsters : dir "$dir/output" files "grc_*_g.ster"
    local n_gsters : word count `gsters'
    di as text "Found `n_gsters' sters matching grc_*_g.ster in $dir/output."

    tempname csvD
    file open `csvD' using "$stage0dir/baseline_N.csv", write replace
    file write `csvD' "ster,N,N_clust" _n

    local n_d_ok   = 0
    local n_d_fail = 0

    foreach s of local gsters {
        local stem = subinstr("`s'", ".ster", "", .)
        local N ""
        local Nclust_str "NA"

        * whole per-ster body captured, not just estimates use --- a
        * malformed ster or an unexpected missing e(N) must not abort
        * the loop for the remaining sters.
        capture noisily {
            estimates use "$dir/output/`s'"
            local N = e(N)
            capture local Nclust = e(N_clust)
            if _rc == 0 & "`Nclust'" != "" {
                local Nclust_str "`Nclust'"
            }
        }
        local est_rc = _rc

        if `est_rc' != 0 | "`N'" == "" {
            di as error "  FAIL `stem': rc=`est_rc' (estimates use or e(N) read failed)"
            file write `csvD' "`stem',NA,NA" _n
            local n_d_fail = `n_d_fail' + 1
            continue
        }

        file write `csvD' "`stem',`N',`Nclust_str'" _n
        local n_d_ok = `n_d_ok' + 1
    }

    file close `csvD'

    di as text ""
    di as text "Section D: `n_d_ok' sters read OK, `n_d_fail' malformed/unreadable."
    if `n_d_fail' > 0 {
        local overall_fail = 1
    }
    di as text "Section D wrote $stage0dir/baseline_N.csv"

}
local saved_rc = _rc
if `saved_rc' != 0 {
    di as error ">>> stage0_checks encountered an uncaught error, rc=`saved_rc'"
    local overall_fail = 1
}

di as text ""
di as text "{hline 72}"
if `overall_fail' == 0 & `saved_rc' == 0 {
    di as result "STAGE0_CHECKS: PASS"
}
else {
    di as error "STAGE0_CHECKS: FAIL"
}
di as text "{hline 72}"

capture log close
