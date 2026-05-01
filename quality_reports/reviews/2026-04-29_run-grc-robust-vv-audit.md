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

## Post-hoc findings (surfaced during smoke testing)

These three issues bit during smoke runs of the driver; not anticipated by the static audit pass.
All fixed; logged here for traceability.

**B1. Stata's 32-char eststo internal name limit.**
`eststo NAME` and `estimates store NAME` both prepend `_est_` to the name and cap the result at 32 characters.
Original estname `grc_robust_vv_TZA_onestep_covs_trend` (34 chars) overflowed.
After shortening to `grc_rvv_TZA_os_covs_trend` (25 chars), the downstream `estimates store NAME_never` (`grc_rvv_TZA_os_covs_trend_never` = 31 chars + `_est_` = 36) still overflowed.
Final fix: dropped to `vv_<country>_<os|ts>_<covs_X>` (worst case `vv_TZA_os_covs_trend_never` = 26 chars + `_est_` = 31, fits).
The full word `onestep`/`twostep` is still passed to `run_grc_robust_vv` as a syntax flag; only the estname tag is shortened.

**B2. `year` must be in `keepvars` for the robust estimator.**
`gen_vfirst` (called inside `run_grc_robust_vv`) uses `bysort pid (year)` to identify the first-wave value of the cluster index.
The main GRC pipeline's `keep $keepvars` does not include `year` (because `run_grc` uses `vce(cluster pid)` and never sorts within pid).
Fix: added `year` to `$keepvars_base` in [`17_verdier_robust.do`](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/17_verdier_robust.do) and the smoke driver.

**B3. Modal popup on batch-mode error.**
`exit, STATA clear` only suppresses the Windows "Stata finished" popup on the success path.
On any `r(N);` error, Stata aborts before reaching `exit, STATA clear`, the popup fires, and a stale Stata process holds the dialog.
Fix: wrapped the body of both drivers in `capture noisily { ... }`, so internal errors are caught locally, `_rc` is recorded, log is closed, and `exit, STATA clear` always runs.

**B4. Standalone-vs-include ambiguity.**
[`17_verdier_robust.do`](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/17_verdier_robust.do) was originally written assuming inclusion from `0_master.do` (which sets `$dir`, `$logs`, programs).
Running standalone via `stata-mp -b do 17_verdier_robust.do` left `$dir` unset, and the script aborted at `cd "$logs"` before the log even opened.
Fix: added a defensive prelude that bootstraps path globals + program includes only when `$dir` is empty.
Calling from master is unaffected (the prelude is skipped).

These post-hoc findings now live as memory for future Stata work in this project at [feedback_stata_gotchas.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/feedback_stata_gotchas.md), and the 32-char limit + capture-noisily wrapper are added to the global `stata-conventions.md` rule.

## Post-implementation audit (2026-04-30)

The pre-implementation findings above have been addressed.
A1 (onestep/twostep flag) is implemented at [L2374--2406](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do); A2 (estprefix) is implemented in `grc_tex_table_trend` at [L2701--2706](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do); A3 ($dir path) is set per-worktree in `0_master.do`.
The driver runs end-to-end and produces the six tables.

This section is a fresh static read of `run_grc_robust_vv` after implementation, looking for issues not visible before.
Severity follows the project convention.
Major affects reported numbers or makes the code fragile to re-run.
Minor is robustness or readability.

### MAJOR

**C1. `swd_always_choice` is mechanically zero everywhere; the always-urban moment is uninformative.**

[L2444--2455](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) demean `always_choice` on `i.vfirst` among workers with `always == 1`.
But `always_choice = always * choice` ([L1244](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)), and for always-urban workers `choice == 1` in every period by construction of the trajectory.
Hence among `always == 1`, `always_choice` is identically 1.
Regressing a constant on `i.vfirst` returns residuals of zero for every observation, so `swd_always_choice` is filled with zeros and then zero-filled again for non-always observations.
The moment $E[\text{swd\_always\_choice} \cdot u_{it}] = 0$ is satisfied trivially for every parameter vector---the instrument carries no information about $\kappa$.

In contrast, `run_grc` uses the raw `always_choice` indicator (= 1 for always-urban person-period observations, 0 otherwise) as the instrument ([L1728](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)).
That instrument has variation across observations and identifies $\kappa$ through the standard moment.

The moment equation still contains `({kappa} + {phi}*({kappa} - {mu:switcher_base}))*(always#1.choice)` ([L2506--2507](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)), so $\kappa$ appears in the residuals, but no instrument with cross-observation variation pairs with it.
GMM converges in practice and reports values for $\kappa$.
That is suspicious: either (a) cross-equation restrictions through other moments pin $\kappa$ down (in which case the instrument is dead weight but the estimate is meaningful), or (b) $\kappa$ is weakly identified and the estimate is sensitive to starting values.

I worry about (b) in particular because the convergence behavior of $\hat\kappa$ across our 30 spec cells has not been audited against starting values.

Suggested response: verify.
Add a one-line diagnostic right after the demean block:

```stata
qui count if swd_always_choice != 0
di as text "run_grc_robust_vv: swd_always_choice nonzero obs = " r(N)
```

If `r(N) == 0` across all three countries, decide whether to (i) drop `swd_always_choice` from the instrument list and rely on the rest of the moment system, (ii) replace it with the raw `always_choice` (matching `run_grc`), or (iii) keep it as a no-op and footnote the audit.
Option (ii) is closest to "minimum deviation from VV's prescription" given that always-urban have no within-cluster variation in the structural treatment to demean.

This is the only finding that could change reported numbers.
Even if (i) leaves $\hat\phi$ unchanged (likely, since $\phi$ is identified from the switcher moments), $\hat\kappa$ and the implied $\Delta_{\text{always}}$ could shift.

**C2. Sample mutation persists across calls and shrinks the dataset in memory.**

[L2417](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) `qui drop if missing(vfirst)` permanently removes observations from the loaded data.
[L2412--2455](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) generate persistent variables (`vfirst`, `swd_switcher_*_choice`, `swd_always_choice`).
The `capture drop` calls at the top of each variable-build block keep variable creation idempotent, but the row drop is not undone.

Pre-implementation A4 noted that the program drops these observations.
The post-implementation finding is that the side effect persists across calls within the same `use`.
In practice, `17_verdier_robust.do` reloads data via `data_setup` per country before the first call ([L94 area](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/17_verdier_robust.do)), so cross-country contamination is avoided.
Within a country, the program is called 10 times (5 covariate sets $\times$ 2 GMM steps) on the same loaded data, and each call after the first sees the smaller sample.
Because the missing-`vfirst` rows are already gone after call 1, runs 2--10 produce identical output to a full reload-per-call---but only because the drop is idempotent.

The fragility is for future callers.
Someone reusing the program after `5_GrRC.do` (which uses the full sample with `vce(cluster pid)`) without reloading would run subsequent main-pipeline estimation on a smaller sample.

Suggested response: document in a header comment (proposed in C5 below).
The cost of `preserve` / `restore` is high (the GMM needs the dropped rows gone) and the current driver pattern is safe.
A header note saying "WARNING: this program drops observations with missing `vfirst` from the loaded data; reload before unrelated estimation" suffices.

### MINOR

**C3. The `_delta` ster file is built but never read.**

`run_grc_robust_vv` saves `\`estname'_delta.ster` ([L2585](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)) containing per-switcher $\Delta_{\underline{d}}$ posts plus a joint test.
[`17_verdier_robust.do` L161--175](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/17_verdier_robust.do) restores only the base, `_never`, and `_avg` esters.
The `_delta` file is never opened.
This mirrors how the main GRC tables only show $\Delta_{\text{never}}$, average $\Delta$, and $\phi$---the `_delta` ster is for internal joint-test use, not the table.

Suggested response: accept.
File the observation in case future tables want per-switcher $\Delta$ rows or the joint test result.
The ster files are cheap; building them defensively is fine.

**C4. `from(\`initial')` is required-shaped but optional-declared.**

The syntax declaration makes `initial` optional ([L2374](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)), but the `gmm` call has `from(\`initial')` unconditionally ([L2517](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)).
If the caller omits `initial()`, the local is empty and `from()` receives nothing, which Stata interprets as "no starting values supplied" (and uses its built-in initialization).
This is the right behavior in practice but opaque from reading.

Suggested response: fix if touching this code anyway, otherwise accept.
The minimal-edit version is:

```stata
local fromopt
if "`initial'" != "" local fromopt "from(`initial')"
gmm ... `fromopt' ...
```

**C5. Program docstring is light.**

The program has no header block describing inputs, outputs, side effects (the sample drop in C2), or the relationship to `run_grc`.
A reader new to the file has to read both programs side-by-side to see what changed.

Suggested response: fix when next editing this program.
A 15-line header documenting purpose, key differences from `run_grc` (cluster-residualized switcher instruments, `vce(cluster vfirst)`, `winitial(unadjusted, independent)`, default onestep, sample mutation), and output files would save future readers a parse.

**C6. `estat overid` failure path swallows missing values silently.**

[L2536--2544](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) wrap `estat overid` in `capture`.
Under one-step GMM, Stata returns rc != 0 in some versions; in others it returns rc == 0 with `r(J)` set to missing.
The `if _rc == 0` branch then `estadd`s `r(J)`, which may be `.`---in which case `Jstat` is added but missing.
The .tex tables show this as a blank cell, which is the desired behavior under onestep.
But the path that triggered it depends on Stata version.
A future Stata version returning rc==0 with non-missing $J$ under onestep would silently start populating the row.

Suggested response: accept for now, document the assumption in a one-line comment.
Worst case is mildly surprising future behavior, easily caught at table-review time.

**C7. First-stage demean has no per-trajectory rank diagnostic.**

[L2436--2442](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) regress `switcher_s_choice` on `i.vfirst` among workers in trajectory $s$.
If a (cluster, trajectory $s$) cell has only one worker, `i.vfirst` perfectly fits that observation and the residual is zero.
Stata silently absorbs this without warning.
Across many sparse cells, the residual variance comes from a smaller effective sample than the count suggests.

Pre-implementation A7 flagged this, scoped to the always-urban level.
The post-implementation observation is that the cluster-support diagnostic ([L2459--2472](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do)) reports `nclust_ge10` across all switchers pooled, not per-trajectory.
A trajectory with thin per-cluster representation could be weakly identified even when the global cluster is well-populated.

Suggested response: verify if C1 needs revisiting.
After the demean loop, optionally add per-trajectory nonzero-residual counts:

```stata
foreach s of numlist `switchers' {
    qui count if switcher_`s' == 1 & swd_switcher_`s'_choice != 0
    di as text "  trajectory `s': nonzero residuals = " r(N)
}
```

### Out of scope

- Whether the GRC moment equation is the right one: methods question for `econometrics-critic` or the user, not a code review.
- The bootstrap overID test from VV's Footnote 31 (S1 in the spec).
We decided to footnote rather than implement (per 2026-04-30 chat).
- Renaming labels `ass:cluster-pooling` to `ass:location-pooling`: deferred per the 2026-04-30 session log.
- `define_switcherpars` base-selection logic: the data-driven choice happens in `initial_values`, and `17_verdier_robust.do` passes `base()` explicitly, so the fallback never fires.

### Recommended action priority

If we fix only one thing, fix C1 (the `swd_always_choice` zero-instrument issue).
It is the only finding that could change reported numbers.
First step is the verification one-liner; the choice between (i) drop, (ii) replace with raw `always_choice`, (iii) accept and footnote depends on whether $\hat\kappa$ moves with starting values.

C2 and C5 are documentation; do them when next editing the program.
C3, C4, C6, C7 are nits and can wait.

### C1 verification outcome (2026-04-30)

Smoke test [tests/verify_C1_swd_always.do](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/tests/verify_C1_swd_always.do) reproduced the demean across all three countries and ran a focal-cell GMM with and without the dead instrument.
Diagnostic at [RP7/output/verify_C1_swd_always.txt](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/output/verify_C1_swd_always.txt).

**Confirmed:** `swd_always_choice` is identically zero everywhere in all three countries.

| Country | nonzero / total |
|---|---|
| IDN | 0 / 92,738 |
| TZA | 0 / 29,864 |
| CHN | 0 / 109,535 |

Always-urban workers have `choice == 1` in every period in all three countries (no zeros, no missings), confirming the structural reason: the demean regresses a constant on cluster dummies, so residuals are zero by construction.

**Confirmed harmless:** dropping `swd_always_choice` from the instrument list in the focal cell (CHN, covs_all, onestep) yields point estimates and standard errors identical to machine precision.

| Quantity | WITH | WITHOUT | diff |
|---|---|---|---|
| $\hat\kappa$ | 9.49400 | 9.49400 | 0.0e+00 |
| se($\hat\kappa$) | 0.10514 | 0.10514 | 0.0e+00 |
| $\hat\phi$ | -0.15467 | -0.15467 | 0.0e+00 |
| se($\hat\phi$) | 0.23088 | 0.23088 | 0.0e+00 |

**Decision:** drop the instrument.
The change is mathematically equivalent (a zero-column instrument adds nothing to the moment system) but makes the program's intent more legible to future readers.
The audit trail is preserved in this memo and the smoke test for anyone who wants to verify equivalence again later.

**Side observation:** IDN drops 300 observations to missing `vfirst` (close to the 297-obs gap between main GRC and Verdier IDN tables; the 3-obs residual is probably observations that drop later for other reasons).
This motivates Task #2 (better drop-count logging in `run_grc_robust_vv`).

## Task #2 + C3--C7 resolution (2026-05-01, commit `b0a2edb`)

All remaining open items in this memo are now closed.
Math is unchanged for every edit; the driver does not need a regen unless `n_dropped_vfirst` is wanted on existing `.ster` files.
Parse-checked via the Stata MCP after edits.

| Finding | Resolution |
|---|---|
| Task #2 | Drop count and percentage now logged on every call (was conditional on `r(N) > 0`). `n_dropped_vfirst` posted via `estadd scalar` so it survives on the `.ster`. |
| C3 (`_delta` ster unread) | Accepted; no code change. Filed as documented behavior. |
| C4 (`from()` shape) | `from()` now conditional on `initial` being non-empty via a `local fromopt` block. Behavior unchanged in practice (the driver always supplies starting values). |
| C5 (light docstring) | ~25-line program header added covering purpose, key differences from `run_grc`, the C2 sample-mutation side effect, and output `.ster` files. |
| C6 (`estat overid` silent path) | One-line comment added flagging the Stata-version-dependent rc behavior under one-step GMM. |
| C7 (no per-trajectory rank diagnostic) | Per-trajectory nonzero-residual counts printed after the demean loop, so weak first stages are visible in the log. |

Edits live in [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/verdier-wrap-up/RP7/scripts/0_programs.do) at the `run_grc_robust_vv` block.
