# Audit: `run_grc_robust_vv` in `0_programs.do` (L2370--2572)

**Date:** 2026-04-29
**Branch:** `worktree-verdier-wrap-up`
**Scope:** Promote `run_grc_robust_vv` from exploration to production for the paper's "Allowing cluster-specific trajectory intercepts" subsection.
This audit lists rough edges in the program and adjacent infrastructure that the driver `17_verdier_robust.do` will hit.
The user decides which to fix before implementation.

## TL;DR

The program itself is structurally clean and parameter-consistent with `run_grc`.
Three real issues to resolve before writing the driver:

1. `run_grc_robust_vv` hardcodes `onestep`---no twostep toggle. M4 requires running both, so the program needs an `[onestep twostep]` syntax option (or a second sibling program).
2. The existing tex-table program `grc_tex_table_trend` is hardcoded to read `grc_{country}_covs_*` ster files. M3 wants three per-country tables in that format. Either pass an estprefix, generalize the program, or save the robust ster files under a `grc_{country}_*` prefix that fits.
3. `0_master.do` line 51 still points `$dir` at the `lca-inversion` worktree. Running the pipeline from `verdier-wrap-up` needs the path updated locally.

The placeholder table on Overleaf was built around the old M3 (one combined 3-row table with $\hat\phi$ vs $\hat\phi^{\mathrm{rob}}$ side by side and a Mean TV column).
The revised M3 replaces it with three per-country tables.
The prose in `sections/sec_robustness.tex` line 82 also needs rewording to match---flagged for the Overleaf-edit pass, out of scope for this branch.

## Findings, by severity

### MAJOR

**A1. No onestep/twostep toggle.**
Line 2483 hardcodes `onestep` inside the GMM call.
M4 requires running both versions for each country to compare $\hat\phi^{\mathrm{rob}}$, $\Delta_{\text{never}}^{\mathrm{rob}}$, $\Delta_{\text{always}}^{\mathrm{rob}}$, average $\Delta^{\mathrm{rob}}$, and `e(converged)`.
Two ways to fix:
(a) Add `[onestep twostep]` to the syntax line and pass through to the `gmm` call.
(b) Create a sibling program `run_grc_robust_vv_twostep`.
Option (a) is cleaner; one program with a flag mirrors how `gmm` itself works.

**A2. Tex-table program is hardcoded to `grc_` prefix.**
[`grc_tex_table_trend`](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) at L2693--2697 builds the ester list as:

```
foreach estname in covs_0 covs_trend covs_1 covs_2 covs_all {
    local ests_never = "`ests_never' grc_`country'_`estname'_never"
    ...
}
```

This reads `grc_{country}_{covs_*}_never.ster` etc.
Two reconciliation paths:
(a) Save robust ester files under `grc_{country}_robust_covs_*` and pass `country=robust_{country}` (hacky, abuses the country slot).
(b) Add an `estprefix(string)` option to `grc_tex_table_trend` that defaults to `grc_` and let the driver pass `estprefix(grc_robust_vv_)`.
Option (b) is the clean one; small, additive change to the existing program.
Spec S3 ("`grc_robust_vv_{country}_*` naming") fits option (b).

**A3. `0_master.do` `$dir` is wrong for this worktree.**
Line 51:

```stata
global dir = "C:/git/ckt/.claude/worktrees/lca-inversion/RP7"
```

For `verdier-wrap-up`, this needs to be `C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7`.
Per memory the path varies by worktree---update locally for runs from this tree.
Don't commit the change unless we agree on a uniform pattern.

### MINOR

**A4. Sample differs from `run_grc`.**
The program drops obs with missing `vfirst` (L2384) before the GMM call.
`run_grc` keeps them.
For the per-country tables (M3), this only affects the comparison narrative---each robust table is internally consistent.
For the M4 comparison summary, report `e(N)` and `e(N_clust)` for each version so the user sees the sample shift.

**A5. `estat overid` failure path is correct but silent.**
After `onestep`, `estat overid` returns rc!=0; the program catches it and prints a `di` (L2510).
Good.
But the `_never` / `_always` / `_delta` / `_avg` ster files inherit no Jstat scalar.
The tex-table program references `Jstat`/`Jpval` in the postfoot stats list (L2735).
Result: under onestep, the table will show blank Jstat cells.
Acceptable per M4 (footnote stands), but worth knowing in advance.

**A6. `define_switcherpars` and `initial_values` need to be called per country before `run_grc_robust_vv`.**
The program accepts `base()` and `initial()` as args but doesn't derive them itself.
Same calling pattern as `run_grc`---driver must call `initial_values` first.
Not a program defect; a driver-implementation note.

**A7. Trajectory residualization can be ill-conditioned in sparse clusters.**
Lines 2399--2410 regress `switcher_s_choice` on `i.vfirst` within trajectory `s`.
If trajectory `s` has very few observations in some clusters, those cluster fixed effects absorb almost everything and residuals are near zero.
The `nclust_ge10` diagnostic (L2436) helps, but only at the always-urban level.
Add a per-trajectory `nclust_ge10` print if R3 from the spec materializes.
Otherwise leave it.

**A8. `eststo NAME` with no `clear` rebuilds in place.**
Fine; just noting that running the driver twice without `eststo clear` between calls is harmless because `eststo NAME` overwrites.

### Cosmetic

**A9. Doc comment in `gen_vfirst` calls itself "buggy" while describing the *prior* (replaced) implementation.**
[L386--389](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) reads slightly oddly on a cold read.
Rewrite for clarity if touching that block.

**A10. Mixed local-vs-global use in joint-`mu` test.**
L2492 uses `$switchers` (global), but L2458 passes `switchers(`switchers')` (local) to `define_switcherpars`.
`run_grc` has the same inconsistency at L1737/1713.
Match the existing convention---don't refactor.

## Action items for the driver `17_verdier_robust.do`

Assuming the user approves fixing A1 and A2:

1. Top of file: `local choice urban`, `local depvar consumption`, `local balance unb`.
2. For each `country in IDN TZA CHN`:
    - `use "$dirdata/processed/`country'_`balance'.dta", clear`.
    - `replace lndepvar = log(consumption/hhsize_cube)`.
    - `setup_grc_estimation` then `keep $keepvars`.
    - Build `periodFE`.
    - Call `initial_values` to derive `base` and `initial`.
    - Five `run_grc_robust_vv` calls with `estname(grc_robust_vv_{country}_covs_{0,trend,1,2,all})`, increasing covariate sets, twostep version (default for the paper table).
    - Repeat the five calls with onestep variant for the M4 comparison; ester names like `grc_robust_vv_{country}_covs_{...}_onestep`.
3. Write the M4 comparison markdown by reading from both sets of ster files for one focal column (say `covs_all`) and tabling $\hat\phi$, $\Delta_{\text{never}}$, $\Delta_{\text{always}}$, $\Delta_{\text{avg}}$, `e(converged)` side by side.
4. Call `grc_tex_table_trend, ..., estprefix(grc_robust_vv_)` (after A2 fix) to write the three paper tables.

## Out-of-scope but flagged

- Overleaf prose at [`sections/sec_robustness.tex`](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/sections/sec_robustness.tex) line 82 currently says the table "reports $\hat\phi$ and $\hat\phi^{\mathrm{rob}}$ side by side along with the realized mean TV per country."
After the M3 revision (three per-country tables, robust only), this prose needs rewording.
That's an Overleaf edit and belongs to a separate session per spec.
- The placeholder Overleaf table at [`tables/verdier_robust_consumption_unb.tex`](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/tables/verdier_robust_consumption_unb.tex) will be replaced by the three new per-country files; the single combined file is no longer the right shape.
- `app_robust_equivalence.tex` proof is unaffected; it's about the worker-level estimator equivalence, not the cluster-pooling table format.

## Decisions needed

1. Approve A1 fix (add `[onestep twostep]` syntax option to `run_grc_robust_vv`)?
2. Approve A2 fix (add `estprefix(string)` option to `grc_tex_table_trend`)?
3. Comfortable with A3 ($dir update for `verdier-wrap-up` worktree, local edit, do not commit)?
4. M4 comparison-summary scope: just one focal column (`covs_all`), or the full 5-column grid for both versions?
The latter is more thorough but also more numbers to scan.
