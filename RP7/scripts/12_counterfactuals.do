* ============================================================
* Title:   E1 counterfactual misallocation accounting
* Author:  Emilia Tjernström (with Claude)
* Date:    2026-06-24
* Purpose: Reproduce the E1 misallocation aggregates (IDN, TZA, the two
*          CHN hukou regimes, and the population-weighted CHN national
*          aggregate) from the GRC + inversion sters. Mirrors the
*          Stata-orchestrates-Python pattern of 5b_inversion.do: this
*          driver regenerates the ster-derived input CSVs, then calls
*          counterfactuals.run_counterfactuals_for_stata over the SFI
*          python: bridge to compute the aggregates, write the persisted
*          results CSV and the paper table, and self-check against the
*          committed baseline snapshot.
* Input:   $output/grc_{IDN,TZA,CHN_rf,CHN_uf}_cuu_ca{,_d}.ster
*          $output/counterfactual_inputs/ per-cell e1 CSVs (regenerated here)
*          $output/counterfactual_results_baseline.csv  (drift baseline)
*          $dirdata/processed/{IDN,TZA,CHN,CHN_hukou_*}_unb.dta
* Output:  $output/counterfactual_results.csv
*          $output/tables/counterfactual_misallocation.tex
* Note:    Prerequisites are the inversion sters (5b_inversion.do) and the
*          hukou sters (7_GrRC_hukou.do, with 5c inversion attach); it can
*          run any time after those sters exist on disk.
* ============================================================

version 17
set more off
set varabbrev off

if "$dir" == "" {
    if "`c(username)'" == "maand" global dir "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
}
if "$dir" == "" {
    di as error "12_counterfactuals: set global dir before running."
    exit 198
}
quietly include "$dir/scripts/0_path_config.do"

* --- Step A: regenerate the ster-derived input CSVs. The exporters are
* standard sub-do-files (no clear all; each opens and closes its own log),
* so include them in this driver's scope. They run before this driver
* opens its own log below, so there is no log-nesting conflict.
include "$dir/scripts/_export_e1_inputs.do"
include "$dir/scripts/_export_e1_inputs_hukou.do"

* --- Python sys.path setup (file-level, mirrors 0_programs.do). Idempotent.
python:
import sys, os
from sfi import Macro
_DIR = Macro.getGlobal("dir")
if _DIR:
    _EXPLOR = os.path.normpath(
        os.path.join(_DIR, "..", "explorations", "python-grc")
    )
    if _EXPLOR not in sys.path:
        sys.path.insert(0, _EXPLOR)
del _DIR
end

capture log close
log using "$logs/12_counterfactuals.log", replace

capture noisily {

    cap mkdir "$output/tables"

    * --- Step B: one python call computes all cells, writes the results
    * CSV and the paper table, and self-checks against the baseline.
    * Paths are read via sfi inside Python (robust to spaces) rather than
    * interpolated into the Stata string.
    * NOTE: this python: invocation MUST stay on a single physical line.
    python: import counterfactuals as _cf; from sfi import Macro as _M; _cf.run_counterfactuals_for_stata(inputs_dir=_M.getGlobal("output")+"/counterfactual_inputs", data_dir=_M.getGlobal("dirdata")+"/processed", out_dir=_M.getGlobal("output"), table_path=_M.getGlobal("output")+"/tables/counterfactual_misallocation.tex")

    confirm file "$output/counterfactual_results.csv"
    confirm file "$output/tables/counterfactual_misallocation.tex"

    di as text ""
    di as text "{hline 72}"
    di as text "12_counterfactuals: complete"
    di as text "{hline 72}"
}
local rc = _rc
capture log close
if `rc' != 0 di as error ">>> 12_counterfactuals FAILED rc=`rc'"
