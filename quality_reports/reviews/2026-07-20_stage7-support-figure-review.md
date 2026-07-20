# Review record: Stage 7, support figure on per-capita scale

Date: 2026-07-20.
Target: [RP7/scripts/11b_extrapolation_support_figure.do](file:///C:/git/ckt/RP7/scripts/11b_extrapolation_support_figure.do) as of commit `b1301ef` on branch `stage7-11b-figure-scale`.
Critic: critic-stata, 83/100, no CRITICAL.

## Findings and adjudications

MAJOR-1: the support-test block has no guard for a country where no switcher trajectory has at least two individuals; `edge_traj` would resolve empty and the run would abort with a syntax error, leaving the postfile handle open and dropping the remaining countries' figures.
Cannot trigger on current data (every country has several switcher cells with hundreds of individuals) and the failure mode is loud (RUN FAILED in the log), not silent.
Author signed off 2026-07-20 without requesting the guard; recorded as a watch-item consistent with the Stage 6 F4 adjudication on defensive asserts.

MINOR-2: tie-break when two switcher trajectories share the same float mean is first-by-trajectory-number and undocumented. Watch-item.
MINOR-3: intermediate `.gph` files use bare relative paths instead of `$xsup_fig` or tempfiles. Pre-existing pattern; watch-item.
MINOR-4: diagnostic intermediates (`ind_rural_mean`, `edge_grp`, and kin) carry no variable labels. The figure uses direct text annotations; watch-item.
MINOR-5: intermediates are named variables rather than tempvars. Pre-existing pattern; each call starts from `use, clear`, so no leakage.
MINOR-6: `is_dT` is defined and unused. Watch-item for the Stage 8 hygiene sweep.
MINOR-7: the three per-country support tests carry no multiple-testing correction. The tests are country-specific support diagnostics, not a joint family feeding a pooled claim; no change.

## Verified correct by the critic

Postfile column order matches the post statement 13-for-13; the singleton-count logic tags exactly the sub-edge singleton cells; `gap` equals `mu_edge - mu_dN` by construction; robust variance is appropriate at one row per individual; the added `bysort` does not disturb the grid, kdensity, or twoway logic downstream; no state leaks across the three country calls.
