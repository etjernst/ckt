/*******************************************************************************
Project: Returns to Migration
Team:    E. Tjernström, M. Kleemans, E. Cenci
Version: May 2026
This code:
    Computes the rank-condition diagnostics that support the pooling step
    formalized in Proposition~\ref{prop:pooling} (Appendix~\ref{app:pooling}).
    For each country (CHN, IDN, TZA), among individuals observed in strictly
    fewer than the country's full panel length (U_i = 1, the unbalanced
    stratum), produces:

      (a) the urban rate Pr(D_it = 1 | U_i = 1), at the person-period
          level --- the marginal-variation diagnostic for the sub-block
          rank condition;
      (b) the (always-rural, always-urban, switcher) decomposition
          (|U_R|, |U_U|, |U_S|) at the individual level --- so the reader
          can see whether between-individual variation comes from a
          meaningful number of always-urban unbalanced individuals or from
          one or two outliers;
      (c) the share of within-stratum variation in D_it that is orthogonal
          to x_it, computed as 1 - R^2 from a regression of D_it on x_it
          within {U_i = 1}, with x_it matched to the main-estimation
          covariate vector (column 5 of the GMM specs: female age2
          education_max education_max2 i.period). This is the operational
          form of the full-system rank condition: high values mean lots of
          residualized variation in D_it, far from collinearity with x_it.

    Also retains the original within-switch share --- the share of
    unbalanced individuals observed with both D=0 and D=1 across their own
    waves --- as a credibility supplement (within-switcher transitions
    automatically partial out time-invariant covariates, so this share
    measures variation most insulated from misspecification of the
    orthogonality condition).

Terminology:
    D_it is the urban indicator throughout the paper. We avoid the
    "treatment" framing here because urban location is a choice, not
    a randomized intervention.

Why we care:
    The pooled-cell specification adds (mu_unb, Delta_unb) as free
    parameters indexing unbalanced individuals. The slope Delta_unb is
    identified from the (U_i * D_it) moment, which requires variation in D
    on the unbalanced stratum that survives partialling out x_it.
    Diagnostic (a) shows D varies on the unbalanced stratum (sub-block
    condition); diagnostic (c) shows that variation survives partialling
    on x_it (full-system condition); diagnostic (b) shows the structural
    composition of the unbalanced stratum by D-pattern; the within-switch
    share shows how much of (a)+(c) comes from within-individual variation.

    See [quality_reports/2026-05-02_rank-condition-diagnostic.md] for the
    derivation of the rank conditions and the case for reporting all four.

Input:
    $dirdata/processed/CHN_unb.dta
    $dirdata/processed/IDN_unb.dta
    $dirdata/processed/TZA_unb.dta
    Each file is created by 1_processData.do via the data_setup program,
    which generates the panel-balance flag `unbalanced`, the binary
    urban indicator `choice`, and the covariates female / age2 / education_max /
    education_max2 / period used in the partial-R^2 check.

Output:
    $logs/1b_unbalanced_rank_diagnostic.log
        Run log with the per-country counts, shares, and partial-R^2 values.
    $output/tables/unbalanced_rank_macros.tex
        LaTeX macros file with the following commands per country
        XXX in {CHN, IDN, TZA}:
            \unbCountXXX        unbalanced individuals (count, comma-formatted)
            \unbBothXXX         unbalanced switchers   (count, comma-formatted)
            \unbShareXXX        within-switch share    (percent, one decimal)
            \unbAlwaysRuralXXX  always-rural unbalanced individuals (count)
            \unbAlwaysUrbanXXX  always-urban unbalanced individuals (count)
            \unbUrbanRateXXX    Pr(D=1 | U=1)          (percent, one decimal)
            \unbResidShareXXX   100*(1 - R^2)          (percent, one decimal)
        Inputted by paper/unbalanced_proposition.tex and
        paper/unbalanced_proposition_short.tex so the appendix prose
        always reflects the current data.
*******************************************************************************/

* set log file
capture log close
log using "$logs/1b_unbalanced_rank_diagnostic.log", replace

* **********************************************************************
* Preliminaries
* **********************************************************************
* Make sure to run section 0 of 0_master.do before running this script

capture noisily {

    * Holders for per-country results, populated in the country loop and
    * read out into the macros .tex file at the end.
    foreach country in CHN IDN TZA {
        local n_unb_`country'         = .
        local n_both_`country'        = .
        local share_`country'         = .
        local n_alwaysrural_`country' = .
        local n_alwaysurban_`country' = .
        local urbanrate_`country'     = .
        local residshare_`country'    = .
    }

    foreach country in CHN IDN TZA {

        di as text _n "=== `country' ==="

        use "$dirdata/processed/`country'_unb.dta", clear

        * Sanity checks on the variables this diagnostic depends on
        confirm variable choice
        confirm variable unbalanced
        confirm variable pid
        confirm variable female
        confirm variable age2
        confirm variable education_max
        confirm variable education_max2
        confirm variable period

        * Restrict to person-period rows belonging to unbalanced individuals
        keep if unbalanced == 1

        * --------------------------------------------------------------
        * (a) Urban rate Pr(D=1 | U=1) at person-period
        *     level. Computed before any individual-level collapses.
        * --------------------------------------------------------------
        quietly summarize choice
        local urbanrate_`country' = r(mean)

        * --------------------------------------------------------------
        * (c) Partial-R^2 check: regress D on the main-spec covariate
        *     vector within the unbalanced stratum and grab R^2. The
        *     residual share 1 - R^2 is the share of within-stratum
        *     variation in D orthogonal to x.
        * --------------------------------------------------------------
        regress choice female age2 education_max education_max2 i.period
        di as text "  Observations used in R^2 regression: " e(N)
        local r2_`country' = e(r2)
        local residshare_`country' = 1 - `r2_`country''

        * --------------------------------------------------------------
        * (b) Always-rural / always-urban / switcher decomposition at
        *     the individual level.
        * --------------------------------------------------------------
        bysort pid: egen byte has_zero = max(choice == 0)
        bysort pid: egen byte has_one  = max(choice == 1)
        gen byte both_realized         = (has_zero == 1 & has_one == 1)
        gen byte always_rural          = (has_zero == 1 & has_one == 0)
        gen byte always_urban          = (has_zero == 0 & has_one == 1)
        label var both_realized        "Unbalanced individual with both D=0 and D=1 observed"
        label var always_rural         "Unbalanced individual always observed rural"
        label var always_urban         "Unbalanced individual always observed urban"

        * Sanity: the three flags should partition the unbalanced individuals
        gen byte _check_partition = both_realized + always_rural + always_urban
        quietly summarize _check_partition
        if r(min) != 1 | r(max) != 1 {
            di as error "Partition violation in `country': both/always_rural/always_urban do not sum to 1"
            error 9999
        }
        drop _check_partition

        * Collapse to one row per unbalanced individual
        * both_realized / always_rural / always_urban are constant within pid by construction, so keeping any one row is safe.
        bysort pid: keep if _n == 1

        count
        local n_unb_`country' = r(N)
        count if both_realized == 1
        local n_both_`country' = r(N)
        count if always_rural == 1
        local n_alwaysrural_`country' = r(N)
        count if always_urban == 1
        local n_alwaysurban_`country' = r(N)
        local share_`country' = `n_both_`country'' / `n_unb_`country''

        di as text "Unbalanced individuals (U_i = 1):           " %9.0fc `n_unb_`country''
        di as text "  ... always rural (D=0 in all waves):      " %9.0fc `n_alwaysrural_`country''
        di as text "  ... always urban (D=1 in all waves):      " %9.0fc `n_alwaysurban_`country''
        di as text "  ... switchers (both D=0 and D=1):         " %9.0fc `n_both_`country''
        di as text "Within-switch share:                        " %6.3f  `share_`country''
        di as text "Urban rate Pr(D=1|U=1):                     " %6.3f  `urbanrate_`country''
        di as text "R^2 of D on x within {U=1}:                 " %6.3f  `r2_`country''
        di as text "Residual share 1 - R^2 (orthogonal to x):   " %6.3f  `residshare_`country''
    }

    * **********************************************************************
    * Write LaTeX macros file
    * **********************************************************************
    * All percent-shares formatted to one decimal place (numeric only;
    * appendix prose attaches "\%" so the format stays decoupled from
    * this script). Counts use comma-thousands formatting.

    local outfile "$output/tables/unbalanced_rank_macros.tex"
    file open f using "`outfile'", write replace
    file write f "% Auto-generated by RP7/scripts/1b_unbalanced_rank_diagnostic.do" _n
    file write f "% Do not edit by hand; rerun the do-file to refresh." _n
    file write f "%" _n
    file write f "% Rank-condition diagnostics for the unbalanced pooling step" _n
    file write f "% (Proposition~\ref{prop:pooling}, Appendix~\ref{app:pooling})." _n
    file write f "% See quality_reports/2026-05-02_rank-condition-diagnostic.md." _n
    foreach country in CHN IDN TZA {
        * Counts (comma-formatted)
        local n_unb_str          : display %9.0fc `n_unb_`country''
        local n_unb_str          = strtrim("`n_unb_str'")
        local n_both_str         : display %9.0fc `n_both_`country''
        local n_both_str         = strtrim("`n_both_str'")
        local n_alwaysrural_str  : display %9.0fc `n_alwaysrural_`country''
        local n_alwaysrural_str  = strtrim("`n_alwaysrural_str'")
        local n_alwaysurban_str  : display %9.0fc `n_alwaysurban_`country''
        local n_alwaysurban_str  = strtrim("`n_alwaysurban_str'")
        * Percentages (one decimal)
        local share_str          : display %4.1f 100 * `share_`country''
        local share_str          = strtrim("`share_str'")
        local urbanrate_str      : display %4.1f 100 * `urbanrate_`country''
        local urbanrate_str      = strtrim("`urbanrate_str'")
        local residshare_str     : display %4.1f 100 * `residshare_`country''
        local residshare_str     = strtrim("`residshare_str'")

        file write f "\newcommand{\unbCount`country'}{`n_unb_str'}" _n
        file write f "\newcommand{\unbBoth`country'}{`n_both_str'}" _n
        file write f "\newcommand{\unbShare`country'}{`share_str'}" _n
        file write f "\newcommand{\unbAlwaysRural`country'}{`n_alwaysrural_str'}" _n
        file write f "\newcommand{\unbAlwaysUrban`country'}{`n_alwaysurban_str'}" _n
        file write f "\newcommand{\unbUrbanRate`country'}{`urbanrate_str'}" _n
        file write f "\newcommand{\unbResidShare`country'}{`residshare_str'}" _n
    }
    file close f

    di as text _n "LaTeX macros written to `outfile'"

    * Copy to Overleaf if requested
    if $copyOverleaf == 1 {
        capture noisily copyOverleaf "`outfile'", subdir(tables)
        if _rc != 0 di as error "copyOverleaf failed (rc=`=_rc'); macros file written but not copied"
    }
}

local saved_rc = _rc
capture log close
if `saved_rc' != 0 {
    di as error ">>> 1b_unbalanced_rank_diagnostic.do FAILED with rc=`saved_rc'"
}
* NOTE: exit, STATA clear intentionally omitted.
* This script is included from 0_master.do; an exit here would terminate the
* full pipeline. Batch-mode popup suppression is handled at the master level.
