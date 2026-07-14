* *******************************************************************
* Title:   Stage 0 --- golden-master refit gate harness
* Author:  CKT pipeline refactor
* Date:    2026-07-14
* Purpose: Defines gate_compare, the three-tier comparison machinery
*          the refactor will use to certify that a refit GRC cell
*          matches its frozen baseline: (1) provenance (N match),
*          (2) bit-identity of b/V, (3) tolerance on relative
*          difference. This file only DEFINES the program; it does
*          NOT refit any cell and does NOT call gate_compare. A
*          separate driver (written later) will refit gate-panel
*          cells into $refitdir and call gate_compare per cell.
* Input:   $dir/output/<estname>.ster        (baseline, READ-ONLY)
*          <refit_ster> path                 (READ-ONLY, supplied by caller)
*          $dir/scripts/0_path_config.do
*          $dir/scripts/0_programs.do        (needed for shared globals/
*                                              conventions; gate_compare
*                                              itself does not call any
*                                              estimation program)
* Output:  quality_reports/staging/stage0/gate_results.csv        (one row/cell)
*          quality_reports/staging/stage0/gate_<estname>_b_compare.txt
*          quality_reports/staging/stage0/gate_<estname>_V_compare.txt
*          $dir/tests/stage0/gate_harness.log
* Note:    Read-only against $dirdata and existing baseline .ster files.
*          Any refit sters this stage produces belong ONLY in
*          $dir/output/stage0_refit/, never in $dir/output/ directly.
* *******************************************************************

version 17
clear all
set more off
set varabbrev off
set linesize 250
capture log close

* --- Bootstrap: minimal globals ---
global dir "C:/git/ckt/RP7"
include "$dir/scripts/0_path_config.do"

* 0_programs.do is ~92KB; wrap in quietly so the log stays readable.
* Needed here only so this file's conventions (globals, naming) line up
* with the rest of the pipeline; gate_compare itself never calls an
* estimation program.
quietly include "$dir/scripts/0_programs.do"

* --- Create the two directories this stage owns. Never write into
* $dirdata or overwrite an existing baseline .ster. ---
capture mkdir "$dir/tests"
capture mkdir "$dir/tests/stage0"
capture mkdir "C:/git/ckt/quality_reports/staging"
capture mkdir "C:/git/ckt/quality_reports/staging/stage0"
capture mkdir "$dir/output/stage0_refit"

global stage0dir "C:/git/ckt/quality_reports/staging/stage0"
global refitdir  "$dir/output/stage0_refit"

log using "$dir/tests/stage0/gate_harness.log", replace text

* *******************************************************************
* Program: gate_compare
*
* Three-tier comparison of a freshly refit ster against the frozen
* baseline ster for the same GRC cell. Never writes to $dirdata or to
* the baseline .ster; only reads both and writes to $stage0dir.
*
* Syntax:
*   gate_compare, estname(string) refit_ster(string) [ resultsfile(string) ]
*
*   estname(string)      baseline ster stem under $dir/output, e.g.
*                         grc_IDN_cuu_ca (no .ster extension)
*   refit_ster(string)   full path to the freshly refit ster for the
*                         same cell, expected under $refitdir
*   resultsfile(string)  optional override for the results CSV;
*                         defaults to $stage0dir/gate_results.csv
*
* Tier 1 (provenance): e(N) must match exactly between baseline and
*   refit, and the two coefficient vectors must be conformable
*   (same number of parameters). Either failing is FAIL_PROVENANCE
*   and skips tiers 2--3.
* Tier 2 (bit-identity): every element of b and V dumped at full
*   precision (%24.16e) via a mata loop and compared for exact
*   equality. All-equal is PASS_BITWISE.
* Tier 3 (tolerance): if not bit-identical, every element of b and V
*   must satisfy |new - base| <= max(1e-12, 1e-10 * |base|), the mixed
*   criterion from the 2026-07-14 plan revision (absolute floor keeps
*   near-zero elements from blowing up a relative-only check). The CSV
*   reports max_crit_ratio = max over elements of |new - base| divided
*   by that element's threshold; <= 1 is PASS_TOLERANCE, otherwise
*   FAIL_TOLERANCE.
* basedir(string) overrides where the baseline ster is read from
*   (default $dir/output), so frozen baselines can live in a dedicated
*   directory such as tests/stage0/baseline_root/output.
* *******************************************************************
capture program drop gate_compare
program define gate_compare
    syntax , estname(string) refit_ster(string) [ resultsfile(string) basedir(string) ]

    if "`resultsfile'" == "" {
        local resultsfile "$stage0dir/gate_results.csv"
    }
    if "`basedir'" == "" {
        local basedir "$dir/output"
    }

    * --- 1. Load baseline, stash b/V/N ---
    capture confirm file "`basedir'/`estname'.ster"
    if _rc != 0 {
        di as error "gate_compare: baseline ster not found: `basedir'/`estname'.ster"
        exit 601
    }
    estimates use "`basedir'/`estname'.ster"
    matrix b_base = e(b)
    matrix V_base = e(V)
    scalar N_base = e(N)

    * --- 2. Load refit, stash b/V/N ---
    capture confirm file "`refit_ster'"
    if _rc != 0 {
        di as error "gate_compare: refit ster not found: `refit_ster'"
        exit 601
    }
    estimates use "`refit_ster'"
    matrix b_new = e(b)
    matrix V_new = e(V)
    scalar N_new = e(N)

    * --- Tier 1: provenance --- exact N match plus conformable b ---
    local k_base = colsof(b_base)
    local k_new  = colsof(b_new)
    local dims_ok = (`k_base' == `k_new')
    local provenance_ok = (N_base == N_new) & `dims_ok'

    local bit_identical = 0
    local max_reldiff   = .
    local verdict        ""

    if `provenance_ok' == 0 {
        local verdict "FAIL_PROVENANCE"
        if `dims_ok' == 0 {
            di as error "gate_compare `estname': parameter count mismatch (base=`k_base' new=`k_new'); dims not comparable"
        }
    }
    else {

        * --- Tiers 2 and 3 run in gate_cmp_mata (defined at file level;
        * a multi-line mata block cannot live inside program define
        * because its bare `end` terminates the program definition).
        * Single-line invocation; sets locals bit_identical and
        * max_reldiff in this program's space. ---
        mata: gate_cmp_mata("`estname'")

        local tol_ok = (`max_reldiff' <= 1)

        if `bit_identical' == 1 {
            local verdict "PASS_BITWISE"
        }
        else if `tol_ok' {
            local verdict "PASS_TOLERANCE"
        }
        else {
            local verdict "FAIL_TOLERANCE"
        }
    }

    * --- Write one-line verdict, creating the CSV with a header if absent ---
    capture confirm file "`resultsfile'"
    if _rc != 0 {
        tempname rf
        file open `rf' using "`resultsfile'", write replace
        file write `rf' "estname,N_base,N_new,provenance_ok,bit_identical,max_crit_ratio,tier_verdict" _n
    }
    else {
        tempname rf
        file open `rf' using "`resultsfile'", write append
    }
    file write `rf' "`estname',`=N_base',`=N_new',`provenance_ok',`bit_identical',`max_reldiff',`verdict'" _n
    file close `rf'

    di as text "gate_compare `estname': `verdict' (N_base=`=N_base' N_new=`=N_new' max_crit_ratio=`max_reldiff')"

end

* *******************************************************************
* Mata worker for gate_compare: tier 2 (bit-identity, full-precision
* text dumps) and tier 3 (mixed criterion |new - base| <=
* max(1e-12, 1e-10 * |base|), reported as max ratio to threshold).
* Reads Stata matrices b_base/b_new/V_base/V_new stashed by
* gate_compare; sets locals bit_identical and max_reldiff in the
* calling program's space via st_local.
* *******************************************************************
mata:
void gate_cmp_mata(string scalar estname)
{
    real matrix b_base_m, b_new_m, V_base_m, V_new_m, T_b, T_V, ratio_b, ratio_V
    real scalar bit_identical_b, bit_identical_V, eq_b, eq_V, i, j, fh_b, fh_V, max_ratio_val

    b_base_m = st_matrix("b_base")
    b_new_m  = st_matrix("b_new")
    V_base_m = st_matrix("V_base")
    V_new_m  = st_matrix("V_new")

    bit_identical_b = 1
    _unlink(st_global("stage0dir") + "/gate_" + estname + "_b_compare.txt")
    fh_b = fopen(st_global("stage0dir") + "/gate_" + estname + "_b_compare.txt", "w")
    fput(fh_b, "index | b_base                   | b_new                    | equal")
    for (i=1; i<=cols(b_base_m); i++) {
        eq_b = (b_base_m[1,i] == b_new_m[1,i])
        if (!eq_b) bit_identical_b = 0
        fput(fh_b, sprintf("%5.0f | %24.16e | %24.16e | %g", i, b_base_m[1,i], b_new_m[1,i], eq_b))
    }
    fclose(fh_b)

    bit_identical_V = 1
    _unlink(st_global("stage0dir") + "/gate_" + estname + "_V_compare.txt")
    fh_V = fopen(st_global("stage0dir") + "/gate_" + estname + "_V_compare.txt", "w")
    fput(fh_V, "row,col | V_base                   | V_new                    | equal")
    for (i=1; i<=rows(V_base_m); i++) {
        for (j=1; j<=cols(V_base_m); j++) {
            eq_V = (V_base_m[i,j] == V_new_m[i,j])
            if (!eq_V) bit_identical_V = 0
            fput(fh_V, sprintf("%3.0f,%3.0f | %24.16e | %24.16e | %g", i, j, V_base_m[i,j], V_new_m[i,j], eq_V))
        }
    }
    fclose(fh_V)

    st_local("bit_identical", strofreal(bit_identical_b * bit_identical_V))

    T_b = 1e-10 :* abs(b_base_m)
    T_b = T_b :* (T_b :>= 1e-12) :+ 1e-12 :* (T_b :< 1e-12)
    T_V = 1e-10 :* abs(V_base_m)
    T_V = T_V :* (T_V :>= 1e-12) :+ 1e-12 :* (T_V :< 1e-12)
    ratio_b = abs(b_new_m - b_base_m) :/ T_b
    ratio_V = abs(V_new_m - V_base_m) :/ T_V
    max_ratio_val = max((max(ratio_b), max(ratio_V)))
    st_local("max_reldiff", strofreal(max_ratio_val, "%24.16e"))
}
end

capture noisily {
    di as text "gate_harness: gate_compare defined; program not invoked by this file."
}
local saved_rc = _rc

di as text "{hline 72}"
if `saved_rc' == 0 {
    di as result "GATE_HARNESS LOAD: PASS"
}
else {
    di as error "GATE_HARNESS LOAD: FAIL (rc=`saved_rc')"
}
di as text "{hline 72}"

capture log close

* *******************************************************************
* Example usage (commented out --- do NOT run from this file). A
* future driver refits one cell into $refitdir under a distinct
* estname, then calls gate_compare against the frozen baseline:
*
* local estname     grc_IDN_cuu_ca
* local refit_name  `estname'_refit
* local refit_ster  "$refitdir/`refit_name'_g.ster"
*
* * ... driver re-runs the run_grc call for this cell here, e.g. by
* * mirroring the relevant block of 4_GrRC.do with
* * estname(`refit_name') so run_grc's own $dir/output/`refit_name'_g
* * save path is overridden to land under $refitdir instead of
* * $dir/output ...
*
* gate_compare, estname(`estname') refit_ster(`refit_ster')
* *******************************************************************
