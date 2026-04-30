# GRC pipeline refactor --- MUST / SHOULD / MAY spec

Status: draft, awaiting user approval.
Branch: `worktree-grc-pipeline-refactor`.
Authors: Emilia + Claude.
Feeder reviews:

- [do-file-inventory.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-24_do-file-inventory.md)
- [programs-do-audit.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-24_programs-do-audit.md)
- [real-values-diff.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-24_real-values-diff.md)
- [real-values-bug-evidence.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-24_real-values-bug-evidence.md)
- [upstream-deflation-search.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/reviews/2026-04-24_upstream-deflation-search.md)

## 1. Motivation

The Stata production pipeline has accumulated 22 `.do` files in `RP7/scripts/`.
Roughly half are near-duplicates produced when an RA extended robustness checks by cloning do-files rather than adding options to the shared programs in `0_programs.do`.
Separately, `Dropbox\Returns to migration\ReplicationPackage6 - real values\` maintains a second copy of the entire pipeline just to point at pre-deflated data files.

Empirically, the real-values script fork runs against different numbers (and therefore produces different estimates), but only 2 of 22 `.do` files actually differ in content, and those differences are one path string plus a stale snapshot of `0_programs.do`.
The functional weight of the fork lives entirely in swapping the data folder, which does not require maintaining a parallel script tree.

On top of the duplication, results currently pop out only as production-quality LaTeX tables, which makes it slow to compare headline numbers across spec tweaks.

Goals of this refactor:

1. **Collapse the 22 files to roughly 10--12** by extending `0_programs.do` with new options that absorb the parameterization axes the RA duplicated across files.
2. **Replace the real-values script fork** with a single `values(nominal|real)` switch at `0_path_config.do` that routes `$dirdata/countries/` to the appropriate pre-deflated data folder.
3. **Add a lightweight results-overview layer** that writes a compact per-run summary row every time the pipeline fits a GRC, separate from the production LaTeX tables, so the team can scan headline estimates across specs at a glance.
4. **Preserve all published numbers exactly**. Any refactor must bit-for-bit reproduce the current `output/tables/` and `output/figures/` that appear in the paper.

## 2. MUST

### M1. Extend `5_GrRC.do` to absorb the 10/11/12/13 experience family.
Currently `10_GrRC_experience.do`, `11_GrRC_max_experience.do`, `12_GrRC_experience_share.do`, `13_GrRC_max_experience_share.do` are near-identical (~3 600 duplicated lines total) and differ only in which regressor is used: `exp`, `exp_max`, `exp_share`, `exp_max_share`.
Extend `run_grc` with an `exp_variant(none | exp | maxexp | expsh | maxexpsh)` option that selects the regressor (or, when `none`, runs without any experience regressor and reproduces current `5_GrRC.do` behavior).
Default: `none`, so existing `5_GrRC.do` calls keep running unchanged.
Expand `5_GrRC.do` to loop over the five values of `exp_variant`.
Files 10/11/12/13 are then deleted outright.

### M2. Collapse the 14/15 extras into `5_GrRC.do` the same way.
`14_GrRC_NonAg_experience.do` is effectively IDN-only nonag plus an extra experience regressor; `15_GrRC_birth.do` is IDN-only plus a birth-place control.
Both drive the same GRC machinery as 10--13.
Add an `extra_regressor(varname)` option (or, if cleaner, a `birth` flag and let `exp_variant` handle the experience variants) so these become additional axes in `5_GrRC.do`'s loop.
Files 14/15 deleted after the collapse lands.

### M3. Unify the `grc_tex_table_trend*` family.
Currently `grc_tex_table_trend`, `grc_tex_table_trend_exp`, `grc_tex_table_trend_birth`, and `grc_tex_table_trend_hukou` are four near-identical programs.
The ster-rename commit (cherry-picked into this branch as `ac8d474`) already added a `spec()` option to three of them.
Finish the job: collapse into one `grc_tex_table_trend` with options `spec(string)`, `est_schedule(string)`, `est_prefix(string)`, plus any hukou-specific controls.
`grc_tex_table_trend_birth` is byte-identical to `grc_tex_table_trend_exp` per the programs audit --- delete it outright and redirect callers.

### M4. Replace the real-values script fork with a `values(nominal|real)` switch.
- Implement at `RP7/scripts/0_path_config.do`: `global values "nominal"` as default; `global dirdata` resolves to the nominal or real data folder accordingly.
- Append `_${values}` to the `.ster` prefix, CSV output, and LaTeX table filenames so nominal and real results coexist without clobbering.
- No in-pipeline deflation code is added --- the deflation machinery lives upstream of this replication package (documented in the real-values-diff and upstream-deflation-search reviews).
- Archival of the `ReplicationPackage6 - real values\scripts\` folder is deferred until we confirm the switch reproduces existing real-values results exactly. Decision not in this spec.

### M5. (deferred) Collapse the enumerated-block pattern in `1_processData.do`, `1_summaryStats.do`, `7_OLS_uGRC_hukou.do`.

**Deferred per user, 2026-04-25.**
The original target was nested loops, but those make per-country debugging harder --- you can no longer just comment out one block to skip a country.
Revisit only after the rest of the refactor is complete and we are confident in the regression test, so we can experiment without losing the ability to run a single country.

The original write-up follows for the eventual pickup.

Concrete example of what "enumerated blocks" means, from `1_processData.do`:

```stata
*******************************************************************************
* INDONESIA - unbalanced, non-ag
*******************************************************************************
* Choices
    local country               IDN
    local choice                nonag
    local depvar                consumption
    local balance               unb

* Prepare for summary stats
    data_setup `country' `choice' `depvar' `balance'

* Save dataset for later use
    save "$dirdata/processed/`country'_`balance'_`choice'.dta", replace

*******************************************************************************
* INDONESIA - unbalanced, income
*******************************************************************************
* Choices
    local country               IDN
    local choice                urban
    local depvar                income
    ...
```

This same six-line block repeats ~28 times in `1_processData.do`, varying only in `country`, `choice`, `depvar`, `balance`, and sometimes the program called (`data_setup` vs `data_setup_2waves` vs `data_setup_3waves`).
Similar enumeration lives in `1_summaryStats.do` (15 blocks) and `7_OLS_uGRC_hukou.do` (12 blocks).

Replace each with a nested loop over the parameterization axes.
For example `1_processData.do` could become roughly:

```stata
foreach country in IDN CHN TZA {
    foreach balance in unb bal {
        foreach choice in urban nonag {
            foreach depvar in consumption income {
                * Skip combinations that don't exist (e.g. nonag only applies to IDN)
                if "`country'" != "IDN" & "`choice'" == "nonag" continue
                ...
            }
        }
    }
    * 2-wave and 3-wave variants for trajectory subsets
    foreach waves in 2waves 3waves {
        data_setup_`waves' `country' urban consumption unb
        save "$dirdata/processed/`country'_unb_`waves'.dta", replace
    }
}
```

The skip conditions take care of the small country-specific asymmetries; new combinations can be added by extending the enum lists rather than pasting new blocks.

### M6. Preserve bit-for-bit reproducibility of published results.
Before and after each phase of the refactor, every file under `RP7/output/tables/` and `RP7/output/figures/` must match the pre-refactor version exactly.

Practical note: a full master pipeline run is expected to take on the order of 40+ hours.
So the verification strategy is:

1. **Phase 0**: run the current master pipeline end-to-end **once**, capture every file under `output/tables/` and `output/figures/` (and the `.ster` files) as a frozen reference in `tests/reference/`.
2. **During refactor**: each phase diffs against the saved reference, not against a re-run.
3. **Re-run the reference only when** there is a concrete reason to refresh it (e.g. after M8 and Phase 1 are known to be bit-identical, refresh to include the new naming).

### M7. Add an automated regression test.
A `tests/regression_test.do` (or Python wrapper) that:

- For each file under `output/tables/` and `output/figures/`, diff against `tests/reference/`.
- Fails the test if any file changes.
- Also checks the master pipeline log for `error` / `no observations` / convergence failures.

Tolerance: **bit-for-bit**. Whitespace or trailing-newline changes often hide real drift, and tolerating them defeats the purpose.

Each refactor phase must pass this test before merging. Phase 0 generates the reference against which Phase 1+ diff.

### M9. Store `e(runtime)` in `run_grc`.
Wrap the GMM fit inside `run_grc` with a `timer clear 99 / timer on 99 / ... / timer off 99 / qui timer list 99` pattern (or equivalent) and save the elapsed seconds as `e(runtime)` before the program returns.
This populates the overview layer's runtime column (S1) without requiring a separate profiling pass.
No impact on estimation numerics; regression test (M7) should still pass bit-for-bit.

### M11. Unique `.ster` filenames per fit, with locked-in shorthand.

Note: should have been in the original spec. Discovered post-hoc when running an overnight smoke and noticing slots 1--15 (cons/urban/unb section) get clobbered by slots 16--30 (cons/urban/bal) which are then clobbered by slots 31--45 (income/urban/unb).
Today every section in `5_GrRC.do` writes the same `grc_<c>_urban_covs_<k>` filenames, so only the LAST section's sters survive on disk.
Same overwrite issue applies in `8_GrRC_hukou.do` (3 sections per hukou subgroup, all writing the same hukou-prefixed names).

Cost of the current scheme:

- **Cannot reload prior-section results from disk** once the full pipeline has run.
- **Cannot inspect or reuse individual past fits** for ad-hoc analysis, sensitivity exercises, or reviewer requests.
- **M9 runtime values** for sections 1 and 2 are lost once section 3 overwrites the main sters.
- **S1 scraper** can only see the LAST fit per filename (15 of 45 fits in `5_GrRC.do` alone).
- **M10 resume guard** misfires if a partial run from section 1 leaves `_avg.ster` files on disk; section 2's first fit falsely skips.

#### Locked-in shorthand scheme (file names AND stored names)

Single shared format:

```
grc_<country>_<spec3>_<covs2>_<sfx1>
```

- `country`: 3 chars (`CHN` / `IDN` / `TZA`).
- `spec3`: 3-char positional triplet (`<depvar><choice><balance>`):
  - `cuu` = consumption / urban / unbalanced
  - `cub` = consumption / urban / balanced
  - `iuu` = income / urban / unbalanced
  - `cnu` = consumption / nonag / unbalanced (IDN-only path in `6_GrRC_NonAg.do`)
  - Add additional triplets if/when new specs land. Document the table mapping at the top of `0_programs.do`.
- `covs2`: 2--3 char covariate-set abbreviation. Apply the existing experience-family convention to the `5_GrRC.do` family too:
  - `c0` = no covariates
  - `ct` = trend (time FE only)
  - `c1` = trend + female
  - `c2` = trend + female + age$^2$
  - `ca` = trend + female + age$^2$ + education + education$^2$
  - The existing experience suffixes `c1/c2/c3/ca` keep their meaning inside `10/11/12/13/14/15_*.do`.
- `sfx1`: 0--1 char post-estimation marker:
  - `<empty>` = main GMM result
  - `n` = $\Delta_{\text{never}}$ (replaces `_never`)
  - `a` = $\Delta_{\text{always}}$ (replaces `_always`)
  - `d` = per-trajectory $\Delta_d$ + joint test (replaces `_delta`)
  - `g` = population-weighted average $\Delta$ (replaces `_avg`)

Example: `grc_IDN_cuu_ct_n.ster` is "Δ_never extrapolation for IDN consumption/urban/unbalanced, time-FE-only covariate spec".
Length 20 chars. Stored-estimate name (without `.ster`) same 20 chars. With Stata's `_est_` prefix: 25 chars --- well under the 32-char limit, no Option B abbreviation needed for these files.

#### Hukou variant (8_GrRC_hukou.do)

`country_short` already encodes the hukou subgroup, e.g. `CHN_rural_first`.
Naive concat `grc_CHN_rural_first_cuu_ct_n` = 28 chars + `_est_` = 33 --- one over.
Two options, decide at implementation:

- **Compress hukou subgroup**: `rural_first -> rf`, `urban_first -> uf`, `rural_only -> ro`, `urban_only -> uo`. Result: `grc_CHN_rf_cuu_ct_n` = 19 chars. Cleaner.
- **Drop the triplet for hukou**: hukou-specific tables already imply the spec context. Result: `grc_CHN_rural_first_ct_n` = 24 chars. Within limit. Loses cross-section disambiguation though, which is the very thing M11 is fixing.

Recommend the first.

#### Why this replaces Option B in these files

After M11, file names and stored names are short enough that we don't need a separate "long disk / short memory" Option B convention.
The `urban -> u` and `nonag -> n` translations in `grc_tex_table_trend` (the `spec_short` local) become unnecessary.
Remove that complication when M11 lands.
Net simplification: single naming scheme everywhere.

#### Concrete code-paths that change

For each numbered file:

| File | Current pattern | After M11 |
|---|---|---|
| 5_GrRC.do | `grc_<c>_urban_covs_<k>` (collides across 3 sections) | `grc_<c>_<spec3>_<covs2>` with `spec3` $\in \{cuu, cub, iuu\}$ per section |
| 6_GrRC_NonAg.do | `grc_<c>_nonag_covs_<k>` | `grc_<c>_cnu_<covs2>` |
| 8_GrRC_hukou.do | `grc_<country_short>_c<k>` (collides across 3 sections) | `grc_<country_short_compressed>_<spec3>_<covs2>` |
| 10_GrRC_experience.do | `grc_<c>_exp_c<k>` (no collision today; single-section) | `grc_<c>_cuu_exp_<covs2>` --- adds `cuu` for consistency, OR keep as-is since unique already |
| 11/12/13_GrRC_*.do | analogous | analogous |
| 14_GrRC_NonAg_experience.do | `grc_<c>_nonag_exp_c<k>` | `grc_<c>_cnu_exp_<covs2>` (or keep as-is) |
| 15_GrRC_birth.do | `grc_<c>_birth_c<k>` | `grc_<c>_cuu_birth_<covs2>` (or keep as-is) |
| 16_heterogeneity_tables.do | reads `grc_<c>_urban_covs_all{,_delta}` | reads `grc_<c>_cuu_ca{,_d}` |

For the experience/birth families (10--15), they don't have the collision problem because their estname pattern differs by file (`exp_`, `maxexp_`, `birth_`, etc.). M11 can either:

- Add the triplet for consistency: `grc_<c>_<spec3>_exp_<covs2>` → all sters have the same shape.
- Leave as-is: their existing scheme is unique enough.

Recommend **add the triplet for consistency**, even where not strictly needed --- the S1 scraper's parser is simpler with one scheme everywhere.

For each program in `0_programs.do`:

| Program | What changes |
|---|---|
| `run_grc` `estimates save` block (5 sites) | suffix `_never/_always/_delta/_avg` -> `_n/_a/_d/_g` |
| `run_grc_hukou` `estimates save` block | same |
| `run_grc_onestep` | same |
| `run_grc_robust` / `run_grc_robust_vv` | same |
| `grc_tex_table_trend` foreach loop | rebuild `<estname>` to use new shorthand; drop `spec_short` (no longer needed) |
| `grc_tex_table_trend_exp/_birth/_hukou` | same |
| `het_table_delta`, `het_table_mu` | reference `grc_<c>_cuu_ca_d` and `grc_<c>_cuu_ca` |

#### Phase placement

Phase 1, with M1/M2 (collapse the experience family + non-ag/birth into `5_GrRC.do`).
Doing M11 + collapse together avoids editing the same call sites twice.

#### Verification after M11

- A clean smoke run of the full pipeline should leave a number of unique sters per fit equal to (number of `run_grc` calls) × 5 (subgroups). For `5_GrRC.do` alone that's 45 × 5 = 225 sters.
- The S1 scraper enumerates every fit with its `e(runtime)` and `e(timer_slot)`.
- No stored-name length errors regardless of country / spec / covariate combination.

### M10. Resume-on-interrupt guard inside `run_grc`.

The Phase 0 reference run (M6) is expected to take ~40 hours and would otherwise have to restart from zero if interrupted.
Add a resume guard right after `run_grc`'s `syntax` line:

```stata
if "${skip_if_exists}" == "1" {
    capture confirm file "$output/`estname'_avg.ster"
    if _rc == 0 {
        di as text "run_grc: SKIP `estname' (`estname'_avg.ster present)"
        exit
    }
}
```

Check `_avg.ster` specifically because it's the last of the five subgroup sters `run_grc` writes (main, `_never`, `_always`, `_delta`, `_avg` at lines 1757--1813).
If `_avg` is present, all five are present; partial completions will re-run.

Design notes:

- **Opt-in** via the global `$skip_if_exists`.
  Default behavior (global unset or `"0"`) is to always re-run, preserving reproducibility guarantees.
  Master scripts or smoke-test drivers that want resume-on-interrupt set `global skip_if_exists 1`.
- **Zero changes to callers**.
  No search-and-replace across the numbered do-files.
- **To force a fresh run** when the global is set: delete the target `.ster` files (e.g. `rm -rf $output/*.ster` or filtered).
- Applies symmetrically to `run_grc_hukou` and the other `run_grc_*` variants --- same three-line pattern, same `_avg.ster` check.
  Extend when those programs are touched in Phase 1.

Lands immediately in Phase 0 so the reference run itself benefits.

### M8. Smoke-test the ster-rename on IDN before collapse work starts.
The ster-rename commit (`ac8d474`, cherry-picked from `lca-inversion`) changes the filenames of 8 source scripts' `.ster` outputs and 10 programs in `0_programs.do`.
Before anything collapses, run `5_GrRC.do` + `16_heterogeneity_tables.do` against IDN/cons/urban/unb in `RP7/output/` and confirm the urban covs_all table matches the published headline.
Prerequisite for any M1--M5 work.
This is a single-country smoke test (hours, not 40+) so can run before the full reference-build in M6's Phase 0.

## 3. SHOULD

### S1. Add a results-overview layer that scrapes `.ster` files.

Rather than threading a CSV-append step into `run_grc` (risky, touches the core estimation code), implement the overview as a **standalone scraper** that reads the `.ster` files in `RP7/output/` and produces a compact summary on demand.
Benefits: can regenerate at any time without re-running estimation; no modification to `run_grc` or `0_programs.do`; failure modes (missing ster, corrupt file) don't poison a Stata run.

Design:

- **Python implementation** (`scripts/python/scrape_grc_runs.py`).
  Stata's `estimates use` works but the comparison tooling already lives in Python, and pandas is a more natural home for the long-format output.
  Read each `.ster` via `pyreadstat` (or `pystata.config` + `Estimates`).
  Extract point estimates, standard errors, sample size, J-test p-value, and any `e()` scalars (including `runtime` once M9 lands).
  Write a single tidy `RP7/output/overview/grc_runs.csv` with one row per fit.
- Columns:

| Column | Content |
|---|---|
| `ster_filename` | e.g. `grc_IDN_urban_covs_all.ster` |
| `country` | parsed from filename |
| `depvar` | consumption / income |
| `choice` | urban / nonag / hukou |
| `balance` | bal / unb |
| `spec` | urban / nonag / exp / maxexp / expsh / maxexpsh / nonag_exp / birth |
| `covariates` | covs_0 / covs_trend / covs_1 / covs_2 / covs_all |
| `values` | nominal / real |
| `beta` | $\beta$ |
| `phi` | $\phi$ |
| `phi_se` | SE of $\phi$ |
| `delta_d0` | $\Delta_{\underline{d}_0}$ for baseline switcher |
| `N` | sample size |
| `J_pval` | Hansen J-test p-value |
| `runtime_s` | elapsed seconds for the fit (read from `e()` returns if stored, else blank) |
| `ster_mtime` | filesystem mtime of the `.ster` (proxy for when it was last re-run) |
| `commit` | git SHA of HEAD at scrape time |

Companion summary script: `summarize_overview.do` (or `.py`) that prints a pivot for a chosen axis, e.g. "$\phi$ by (country, covariates) for consumption/urban/unb," to answer "how did results shift when I tweaked X" in seconds.

Caveat on runtime: `runtime_s` only works if `run_grc` stores an `e(runtime)` scalar.
If that scalar is not present, leave the column blank or drop it.
Adding timing to `run_grc` can happen as a tiny extension under S1, or as its own MINOR item.

### S1b. Specification-curve-style overview figure, in Python.

One CSV gives you exact numbers; one figure gives you the at-a-glance pattern.
Implement as a Python script (the existing comparison tooling lives in Python; Stata's `speccurve` is out of reach), taking inspiration from the speccurve / Simonsohn-Simmons-Nelson specification-curve design.

**Script: `scripts/python/grc_overview_figure.py`.**

**Inputs.**
The scraper output (S1's `grc_runs.csv`) plus the corresponding subgroup `.ster` files read directly via `pyreadstat`:

- $\phi$: from the main `.ster` (`grc_<c>_<spec>_<covs>.ster`), parameter `phi:_cons`.
- $\Delta_{\text{never}}$: from `grc_<c>_<spec>_<covs>_never.ster`, parameter `Delta_never`.
- $\Delta_{\text{always}}$: from `grc_<c>_<spec>_<covs>_always.ster`, parameter `Delta_always`.
- $\Delta_{\text{avg}}$: from `grc_<c>_<spec>_<covs>_avg.ster`, parameter `Delta_avg`.

All four are already produced by `run_grc` (lines 1761--1813 of `0_programs.do`), so no estimation changes are needed --- just read the existing files.

**Layout (default 2x2):**

```
+-------------------+-------------------+
| phi               | Delta_avg         |
+-------------------+-------------------+
| Delta_never       | Delta_always      |
+-------------------+-------------------+
```

Top row is the headline pair (slope + population mean), bottom row is the extrapolated subgroup returns.
Each panel: estimates on x-axis (sorted by point estimate within panel, or in the same order as the user's chosen comparison axis), point estimate + 90% inner CI + 95% outer CI as nested error bars, vertical reference line at 0.
Beneath the four panels, a "checkmark grid" panel showing which level of each spec axis (country, depvar, choice, balance, covariates, exp_variant, values) is present for each estimate --- this is the speccurve-style annotation that lets you see which spec choices move which coefficient.

**Alternative layout:** 4 rows tall, with the spec grid running across the full bottom. Useful when you have many estimates (10+). Offer via a flag.

**Controls.**
CLI flags or a small config dict select which estimates to plot:

- `--country IDN` (or `all` to plot all three)
- `--depvar consumption`
- `--choice urban`
- `--balance unb`
- `--vary covariates` --- the comparison axis: every estimate on the figure differs only along this axis
- `--values nominal` (or `real` once M4's switch lands)

**Outputs.**
PDF + PNG under `RP7/output/overview/`, named by the comparison cut (e.g. `grc_overview_IDN_cons_urban_unb_byCovariates.pdf`).

**Cross-country variant.**
Drop the country fix and `--vary country`. Three estimates per panel, one per CHN/IDN/TZA. Answers "does the pattern replicate across countries?" in one figure.

**MVP scope.**
Static PDF/PNG; no interactivity, no HTML, no dashboard. The DIY matplotlib implementation is ~150--200 lines of pandas + matplotlib, which is small enough to maintain without taking on a third-party dependency. We can revisit a third-party Python `specurve` package only if the DIY route turns out to need more polish than expected.

### S1c. Add $\Delta_{\text{always}}$ to the main GRC LaTeX tables.

The current `grc_tex_table_trend` produces tables with three coefficient rows: $\Delta_{\text{never}}$, "Average $\Delta$" (= $\Delta_{\text{avg}}$), and $\phi$. Verified by reading `GRC_CHN_consumption_urban_unb.tex`.
$\Delta_{\text{always}}$ is computed and saved in `_always.ster` (line 1771 of `0_programs.do`) but is not displayed.
Add a fourth row "$\Delta_{\text{always}}$" so the paper tables and the visual overview surface the same set of estimates.
One-line edit in `grc_tex_table_trend`; gated by M7 to confirm no other table content shifts.

### S2. Dispatcher-based numbered files.

After M1--M5, rename the numbered files so their purpose is visible at a glance.
Proposed target list:

| File | Purpose |
|---|---|
| `0_master.do` | dispatcher, unchanged |
| `0_path_config.do` | paths + `values()` switch |
| `0_programs.do` | shared programs (extended) |
| `0_setup.do` | environment, unchanged |
| `1_processData.do` | country × balance × depvar loop (collapsed) |
| `1_summaryStats.do` | summary stats loop (collapsed) |
| `2_OLS.do` | OLS / FE reduced-form (merges current `2` and `7`) |
| `3_heterogeneity_plots.do` | unchanged |
| `4_trajectory_bar_graph.do` | unchanged |
| `5_GrRC.do` | main GRC driver; loops over spec / exp_variant / extra_regressor (absorbs 5, 6, 8, 10--15) |
| `6_learning.do` | renamed from `9_learning.do` |
| `7_heterogeneity_tables.do` | renamed from `16_heterogeneity_tables.do` |
| `0_CHN_hukou_restrictions.do` | unchanged, country-specific prep |

Target count: **13 files**, down from 22.

### S3. Map which programs in `0_programs.do` are used and which are dead.

The programs audit gave a first pass but some of its "dead code" calls require verification (e.g. some programs are only called from `explorations/`, which is out-of-tree but still in the repo).
Produce a definitive map: for each of the 45 programs in `0_programs.do`, list every caller inside `RP7/scripts/`, `explorations/`, and anywhere else in the repo.
No deletions in this step --- just the map, landed as a new review.
Deletion is decided case by case in a follow-up.

Note: the previously-memoized "`define_switcherpars` hardcoded to `base(2)`" claim appears to be obsolete.
Direct read of `0_programs.do` shows `initial_values` at L1508 sets `local base = 2` only as a starting value, then loops over switchers and selects the base by highest t-stat among those with $N_{\underline{d}} / T > 5$ (L1511--1524).
`define_switcherpars` itself requires `base()` as a mandatory argument.
So the base IS data-driven for normal specs.
Track as an open question for the user to confirm; if confirmed, the memoized "bug" note in `CLAUDE.md` should be removed.

## 4. MAY

### A1. (removed)
Tables stay separate --- they are inserted in different places in the paper, so a single combined artifact is not useful.

### A2. Replace `replace` with `gen new_var` in deflation and transform steps.
Postponed. Not in the refactor's scope.
Affects the four `replace ... / deflator` lines in `260302 Data preparation real values_DB.do` (upstream of this repo) and any analogous pattern inside `0_programs.do`.
On the to-do list for a future session.

## 4b. Validation tiers for incremental work

A full smoke run takes ~30 hours wall clock.
Re-running it at every step would block progress.
Use a tiered scheme: cheap checks at every commit, narrow runtime checks per phase, full smoke only at major milestones.

### Tier 1 --- static + symbolic (seconds, every commit)

For pure-rename and structural-collapse changes, validation is mostly grep-based:

- Rename audit: every `estimates save / use / store / table / esttab` reference uses the new shorthand consistently.
- Stored-name length: every constructed name fits 32 chars after `_est_` prefix; trivial to compute from the format spec.
- Code-path matrix: walk the spec's M11 / M1 / M2 call-site tables, confirm each was updated.
- Lint / syntax check: `stata-mp -e do <file>` sanity-load to catch syntax errors without running anything.

Exit criterion: zero unaccounted-for references to the OLD names; every change in the matrix is present.

### Tier 2 --- replay smoke (minutes, per phase or per substantive change)

For changes that don't alter GMM math (rename, collapse), use existing surviving sters to validate the read pipeline without re-running estimation:

- Rename existing sters on disk via a one-shot script to match the new convention.
- Run only the table-builder block of the relevant section in `5_GrRC.do` (skip the GMM `run_grc` calls; just `estimates use` / `estimates store` / `grc_tex_table_trend`).
- Diff the resulting LaTeX tables against the frozen reference (`tests/reference/output/tables/`).

For sections where we don't have surviving sters (cons/unb and cons/bal were overwritten in smoke #9; only income/unb sters survive on disk), use a tiny GMM subset:

- Run TZA only: TZA's covs_0 was 6 sec and covs_all 12 sec in the reference smoke; 5 specs total ~1 minute. Diff the TZA tables.
- This validates the write side (run_grc estname) end-to-end at minimal cost.

Exit criterion: tables diff identically against the reference for the sections covered by the replay.

### Tier 3 --- full smoke (~30 hours, end of major milestone)

Re-run the full pipeline once at the end of a phase. This:

- Validates every fit's GMM still converges with the new code paths.
- Refreshes `tests/reference/` to include any new tables that the milestone's changes produce (e.g. M11 doesn't add new tables, but Phase 1's collapse + M11 will surface the experience/birth families' tables once their sters are uniquely named).
- Captures M9 timings for sections 1 and 2 (which are currently lost to overwrite, fixed by M11).

Exit criterion: regression test passes against the prior reference; new artifacts (if any) reviewed manually before being committed as the new reference.

### Worked example: M11 (rename only)

| Sub-step | Validation | Time |
|---|---|---|
| Rename in `0_programs.do` (run_grc, run_grc_onestep, suffix strings) | Tier 1 grep | seconds |
| Rename `estimates save / use / store / table` in 5/6/8/10--16 | Tier 1 grep + length check | seconds |
| Rename in `grc_tex_table_trend*` foreach bodies | Tier 1 grep | seconds |
| Drop `spec_short` (no longer needed) | Tier 1 | seconds |
| Replay smoke: rename existing income sters; re-run table-builder for income/urban/unb | Tier 2 diff vs reference | ~5 min |
| Tiny TZA smoke: 5 GMM fits + 1 table for TZA cons/urban/unb | Tier 2 diff vs reference | ~5 min |
| Phase 1 wrap: full smoke; refresh reference if new tables produced | Tier 3 | ~30 hours, once |

This pattern applies to every later phase too: Tier 1 + 2 inside the phase, Tier 3 at phase boundary.

## 4a. To-do list (not in this refactor)

- A2: replace `replace` with `gen` in the deflation layer.
- Coauthor-side fixes from the TZA email draft.
- `consfood` / `consnonfood` nominal-in-real-file mislabeling in IDN, CHN, TZA files.
- M5 (collapse enumerated blocks): revisit after the refactor is settled and the regression test is trusted.

## 5. Target program API (concrete)

After the refactor, `run_grc` should support this call pattern:

```stata
run_grc, country(CHN) depvar(consumption) choice(urban) balance(unb) ///
         spec(urban) covariates(covs_all) ///
         values(nominal) ///
         estname_prefix(grc_${country}_${spec})
```

with optional axes:

```stata
         exp_variant(exp)          // exp | maxexp | expsh | maxexpsh
         extra_regressor(birth)    // birth | nonag_exp | none
         hukou_subset(rural_first) // rural_first | urban_first | none
         phi_fixed(real)           // optional: pin $\phi$
```

Internally `run_grc` picks up `${values}` from the global set at `0_path_config.do` as the default; the explicit `values()` option is an override for one-off runs.

`grc_tex_table_trend` takes the same axis options to generate the corresponding LaTeX table.

## 6. Risks and non-goals

### Non-goals for this refactor

- Fixing the upstream deflation methodology (TZA `expmR` vs CPI mismatch). That is a coauthor conversation, separate email draft at [docs/communications/2026-04-24_tza-real-deflation-email.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/communications/2026-04-24_tza-real-deflation-email.md).
- Fixing the `consfood` / `consnonfood` nominal-in-real-file bug in IDN, CHN, and TZA data files. Not used in any paper result; documented in reviews; punt to coauthor.
- Harmonizing base years across countries. Each country uses its own literature standard; cross-country level comparisons are not in the paper.
- Porting the Verdier-robust GRC (`run_grc_robust`, `run_grc_robust_vv`) into `0_master.do`. That work is on its own branch; this refactor should remain compatible but not merge it.
- Touching raw data or `0_programs.do`'s `data_setup` in ways that could alter sample construction.

### Risks

- **MAJOR**: Any bug in the new options code silently alters estimation results. Mitigated by M7 (automated regression test) and M6 (bit-for-bit reproducibility requirement).
- **MAJOR**: The `values()` switch changes filenames and CI / pipeline assumptions. Downstream consumers (the paper's LaTeX, any external scripts) must be updated in lockstep. Mitigated by a single-commit cutover with a checklist.
- **MINOR**: The experience family `exp_variant` absorption may interact with the known `define_switcherpars` base(2) bug differently once code paths merge. Mitigated by S3 (fix the base bug in the same refactor wave) and by limiting M1 scope to consumption specs until S3 lands.
- **MINOR**: The overview CSV (S1) doubles file-writes per GRC run. Negligible overhead in practice, but a corrupt CSV could fail a run. Mitigated by writing the CSV under `output/overview/` (not part of the replication package artifacts) and making the append step non-fatal.

## 7. Phasing and dependencies

Proposed phase order, each with its own PR-sized commit set:

1. **Phase 0**: M8 (smoke-test ster-rename on IDN) + M10 (resume-on-interrupt guard; one three-line insert in `run_grc`) + M7 (regression-test scaffolding) + M6 Phase 0 (run master pipeline once, freeze reference outputs under `tests/reference/`) + M9 (add `e(runtime)` to `run_grc`; no numeric impact, slot it in here before the reference is frozen so runtime columns are populated from the start). The master run is the ~40 h step --- everything else is fast; M10 makes the master run restartable. Unlocks everything.
   **Status as of 2026-04-28: Phase 0 is DONE.** Smoke #9 completed 2026-04-27 ~17:56 (~20.5 h, not 40), produced all 9 5_GrRC.do tables bit-identical to RP6 2026-04-22 reference; M9 timer captures per-fit runtime; M10 guard in place; tests/reference/ frozen with the 9 tables; tests/regression_test.py passes.
2. **Phase 1**: M1 + M2 (extend `run_grc` with `exp_variant` and `extra_regressor`; expand `5_GrRC.do`'s loop; delete 10--15). Diff against frozen reference.
   **Status as of 2026-04-30: PARTIAL.** M11 (unique ster filenames) landed via the disambiguated naming scheme; sters now follow `grc_<country>_<spec3>_<covs2>[_<sfx1>]` everywhere.
   Phase 1b.6 spec ([2026-04-28-phase1b6-extras-program.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-28-phase1b6-extras-program.md)) implemented `run_grc_with_extra_regressor` in `0_programs.do` and `GRC_extras.do` with 44 explicit per-cell calls; `_smoke_full.do` calls `GRC_extras.do` directly.
   Bonus refactor 2026-04-30: `run_grc_hukou` merged into `run_grc` (commit `5c3308b`); the duplicated 118-line program is gone, the joint mu test and per-trajectory Δ_d block are wrapped in `capture noisily` so small hukou subsamples can't crash run_grc, and hukou cells now also pick up the `$skip_if_exists` guard.
   Verified end-to-end via [_smoke_hukou_only.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/_smoke_hukou_only.do): 30 ro+uo cells refit cleanly, 150 new sters, zero capture-wrapper fires, 50 min wall.
   What remains for Phase 1 close-out: commit 6e from the Phase 1b.6 spec---delete `10/11/12/13/14/15_*.do` and collapse `0_master.do` includes from 6 lines to 1.
   This is gated on Tier 3 producing a complete ster set under M11 names; the 2026-04-30 Tier 3 run finished mid-crash at CHN cuu maxexp c3 (timer slot overflow at slot 101; root cause fixed in commit `5c21224`), 160 sters preserved, ~50 cells still missing.
3. **Phase 2**: M3 (unify `grc_tex_table_trend*`) + S3 step 1 (map program callers, no deletions yet).
   **Status as of 2026-04-29: NOT STARTED.**
4. ~~Phase 3 (M5 enumerated-block collapse): deferred per user 2026-04-25; not in this refactor.~~
5. **Phase 4**: M4 (values() switch at `0_path_config.do`). Diff nominal against reference; confirm real-values path reproduces existing real-folder results.
   **Status as of 2026-04-29: NOT STARTED.** Note: `0_path_config.do` is now also the canonical home for project-wide globals (`grc_max_iter`, `grc_min_switchers_per_wave`) per the 2026-04-29 fix; `values()` would slot in alongside.
6. **Phase 5**: S1 (standalone `.ster` scraper) + S1b (coefplot overview figure) + S2 (file rename pass).
   **Status as of 2026-04-29: NOT STARTED.**
7. **Phase 6**: decide on any deletions informed by Phase 2's program-caller map.
   **Status as of 2026-04-29: NOT STARTED.**

### S1c. Add $\Delta_{\text{always}}$ row to main GRC LaTeX tables (Section 3 SHOULD).
**Status as of 2026-04-29: NOT STARTED.** One-line edit in `grc_tex_table_trend`; gated by the regression test.

### Audit-driven side workstream (separate from this spec).
The 2026-04-28 best-practices audit ([docs/reviews/2026-04-28_pipeline-best-practices.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/reviews/2026-04-28_pipeline-best-practices.md)) and its action plan ([docs/plans/2026-04-29-audit-action-plan.md](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/plans/2026-04-29-audit-action-plan.md)) drove the cleanup work in the 2026-04-29 session.
Status: nearly closed.
Pending: `m8` (graph-save in cwd), `m13` (`data_path_override`---likely TRIVIA / SKIP), `m14` (schemepack install bug), `m16` (hardcoded panel headers).
Plus the data-creation findings (`DC-M1` through `DC-m7`) deferred by the user to a later session.
M4 mu-loop cleanup landed at commit `d2b0c73` but stays at "RESOLVED" not "CLOSED" until post-Tier-3 ster-comparison verification.

## 8. Open questions for user approval

1. **Scope of M1 absorption**: **Decided** --- collapse 10--15 by adding options to `5_GrRC.do`. Files 10--15 are deleted after Phase 1.
2. **Target file count**: **Decided** --- 13 files.
3. **Regression test tolerance**: **Decided** --- bit-for-bit.
4. **Overview columns**: **Decided** --- the overview is a standalone scraper of `.ster` files rather than a CSV-append hook inside `run_grc`. Runtime is included if `e(runtime)` is stored; otherwise left blank. Open sub-question: should `run_grc` start writing an `e(runtime)` scalar? Low cost, high value for the overview.
5. **Archival of `ReplicationPackage6 - real values\scripts\`**: **Deferred** --- decide after M4 is known to reproduce existing real-values results.
6. **Base-year harmonization**: **Decided** --- keep country-specific bases as-is (IDN 2014, CHN 1990, TZA-for-income 2013).
7. **Is the `initial_values` base selection actually a bug?** **Decided** --- no. L1508's `base=2` is only a starting-value fallback; L1511--1524 pick the base by highest t-stat among switchers meeting $N_{\underline{d}} / T > 5$. Memory note removed from `CLAUDE.md` and `MEMORY.md`.

## 9. Success criteria

A complete refactor satisfies all MUST items, the regression test passes, the file count under `RP7/scripts/` drops from 22 to approximately 13, the `values()` switch produces identical results to a fresh run of the current `ReplicationPackage6 - real values\` scripts, and the new overview CSV makes spec comparisons visibly easier in the day-to-day workflow.
