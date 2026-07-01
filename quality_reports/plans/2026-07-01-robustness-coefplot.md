# Plan: GRC robustness coefplot (phi, Delta_never, Delta_avg)

## Goal
Native Stata `coefplot` for the robustness section: one figure per country (IDN, TZA)
showing phi, Delta_never, and Delta_avg for the main `ca` specification plus each
extra-regressor robustness spec, with specs on the y-axis.

## Scope (decided with user)
- No adult equivalence (sters not estimated; would need a multi-day GMM re-fit).
- Countries: IDN (main + exp + maxexp + expsh + maxexpsh + birth) and TZA (same minus birth;
  birth cell not on disk for TZA). CHN excluded (no extra-regressor sters on disk).
- Native Stata `coefplot` to match the paper's other figures (not the Python overview).
- Plain GMM standard errors from `e(V)` (95% CI = b +/- 1.96 se).
- Estimands, in order: phi, Delta_never, Delta_avg. mu excluded (trajectory-specific;
  only mu:never is a single scalar and it is a level, not a robustness-relevant estimand).

## Data sources (existing sters, no re-fit)
- phi: `_b[phi:_cons]` / `_se[phi:_cons]` from `grc_<C>_cuu[_<fam>]_ca.ster`
- Delta_never: `_b[Delta_never]` from `..._ca_n.ster`
- Delta_avg: `_b[Delta_avg]` from `..._ca_g.ster`
- fam token: (none)=main, exp, maxexp, expsh, maxexpsh, birth

## Implementation
1. New program `grc_robustness_coefplot <country>` in `0_programs.do` (after `heterogeneity_plots`):
   - Build one 1xk row vector (+ se vector) per estimand, columns = spec tokens.
   - Three `coefplot matrix(), se()` panels titled phi / Delta_never / Delta_avg,
     specs relabeled via `coeflabels()`, `xline(0)`, `legend(off)`, saved as .gph.
   - `graph combine` the three, row(1), country title; export PDF+PNG to `$output/figures/`;
     `copyOverleaf` gated.
2. Call it for IDN and TZA from a new section in `11_make_figures.do`.

## Verify
- Regenerate via a lean local driver (copyOverleaf 0), render PNG, eyeball.
- No GMM re-fit; reads sters only.

## Output files
`output/figures/robustness_coefplot_IDN.{pdf,png}`, `..._TZA.{pdf,png}`.
