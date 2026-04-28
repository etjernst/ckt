# Session log: 2026-04-24 --- GRC pipeline refactor (scoping)

Mode: Implementation (scoping phase; no code edits yet).
Branch: `worktree-grc-pipeline-refactor` (worktree at `.claude/worktrees/grc-pipeline-refactor/`).

## Motivation

The user stepped back from the LCA-inversion thread to address a larger structural problem: the Stata production pipeline has accumulated ~22 `.do` files in `RP7/scripts/`, many of which are near-duplicates.
The RA extended the pipeline by cloning do-files rather than adding options to the shared programs in `0_programs.do`.
A parallel Dropbox folder, `ReplicationPackage6 - real values/`, duplicates the entire pipeline a second time just to swap nominal for real values.
Goal: collapse both axes of duplication via options/switches on the shared programs, and add a lightweight "results overview" layer so the team can see how headline estimates move across spec tweaks without having to read the LaTeX tables.

## Setup this turn

- Memory updated: `RP7/` is now the active working copy on every branch, not just `lca-inversion`.
- Memory updated: `ReplicationPackage6 - real values/` recorded as a parallel nominal/real fork to be folded in.
- New worktree created: `.claude/worktrees/grc-pipeline-refactor/` on branch `worktree-grc-pipeline-refactor`.
- New directory: `quality_reports/reviews/` (was missing; first write attempt by a subagent was blocked because it did not exist).
- New session log: this file (topic suffix `grc-pipeline-refactor` per CLAUDE.md's mandatory-suffix convention; prior 2026-04-24 logs cover `verdier-p1`, `rcond-and-sparse-moment`, and `rp7-and-ster-rename` on the `lca-inversion` worktree).

## Plan for the scoping phase

Three parallel research agents produce feeder reviews:

1. **Do-file inventory** --- `quality_reports/reviews/2026-04-24_do-file-inventory.md`.
   One block per file with purpose, callers, covariate sets, outputs, near-duplicate sibling, and collapse observations.
2. **Nominal vs real-values diff** --- `quality_reports/reviews/2026-04-24_real-values-diff.md`.
   Where the fork actually differs; what a `values(nominal|real)` switch would need to control.
3. **`0_programs.do` audit** --- `quality_reports/reviews/2026-04-24_programs-do-audit.md`.
   Every program with signature, callers, hardcoded values, and proposed extension points.

Synthesis target: `quality_reports/specs/2026-04-24-grc-pipeline-refactor.md` (MUST/SHOULD/MAY spec).
Stop for user approval before any plan or code edits.

## State at end of turn

- Agent 1 (do-file inventory): **completed but write blocked**; directory did not exist at time of write.
  Headline findings returned inline: 22 files across 11 families; ~20--27 shared programs invoked; top collapse targets are the 4-file experience family (`10`/`11`/`12`/`13`), the main/non-ag/hukou GRC trio (`5`/`6`/`8`), and the IDN-only extras (`14`/`15`).
  Detailed per-file blocks are lost in the subagent's context; will relaunch to write the full document now that the directory exists.
- Agent 2 (real-values diff): still running.
- Agent 3 (`0_programs.do` audit): still running.

## Open next steps

1. Wait for agents 2 and 3 to return; confirm their writes land in `quality_reports/reviews/`.
2. Relaunch agent 1 to write the full per-file inventory.
3. Synthesize all three reviews into the MUST/SHOULD/MAY refactor spec.
4. Present spec; stop for user approval before writing a plan.
5. **Deferred (per user):** smoke-test `5_GrRC.do` on IDN in `RP7/output/` to confirm the ster-rename from the `lca-inversion` branch reproduces the published headline before any refactor starts.
   Not run this turn because the worktree may not have the ster-rename commits and because GRC estimation is expensive --- user should approve before launching.

## Decisions logged

1. **Scope widening of RP7.** User decided RP7 should be the working copy on every branch, not just `lca-inversion`. Memory updated accordingly. Rationale: fragmenting the pipeline across branches is worse than merging our RP7 edits forward.
2. **Dedicated worktree for the refactor.** Justified by the size of the task (22 do-files + parallel real-values fork + new overview layer). Keeps main tree and other worktrees (verdier, lca-inversion) undisturbed during a multi-session refactor.
3. **Scoping phase is read-only.** No code edits, no Stata runs this turn. Three feeder reviews + one spec, then stop.

## Continuation (later in the same day)

All three feeder reviews landed:

- [quality_reports/reviews/2026-04-24_do-file-inventory.md](../reviews/2026-04-24_do-file-inventory.md)
- [quality_reports/reviews/2026-04-24_programs-do-audit.md](../reviews/2026-04-24_programs-do-audit.md)
- [quality_reports/reviews/2026-04-24_real-values-diff.md](../reviews/2026-04-24_real-values-diff.md)

Plus a fourth review triggered by an unexpected finding:

- [quality_reports/reviews/2026-04-24_real-values-bug-evidence.md](../reviews/2026-04-24_real-values-bug-evidence.md)
- [quality_reports/reviews/2026-04-24_upstream-deflation-search.md](../reviews/2026-04-24_upstream-deflation-search.md)

### Key findings

1. **The "real values" fork is cosmetically parallel, not functionally.** Of 22 `.do` files, only 2 differ (paths in `0_master.do`, a stale snapshot of `0_programs.do` missing the Verdier-robust machinery). Of 53 columns in IDN, only `consumption` and `income` differ. The entire "real values" replication package is effectively: point `$dirdata` at a different pre-deflated data folder.
2. **Upstream deflators differ by country**, with all three applied outside this repo:
   - **IDN**: BPS spatial deflator (province × urban/rural × period) + national CPI to 2014 base, applied at lines 259/262 of `260302 Data preparation real values_DB.do`. Same deflator used for consumption and income.
   - **CHN**: Brandt-Holz spatial deflator (provcd × year × urban), imported from `Processed China CPI data.xls`, 1990 base. Same deflator for consumption and income, applied at lines 589/592.
   - **TZA**: two different deflators mixed inadvertently --- LSMS-ISA's spatial deflator for consumption (via `expmR` renamed at TZA_01A:36) and LMMVW's national-CPI 2013-base for earnings (created fresh at TZA_02:135). The two series use different methodologies; the paper text currently describes only the spatial deflator.
3. **TZA upstream bug**: `260301 Variable selection TZA real values_DB.do` line 66 picks up nominal `food` instead of `food_real`, then line 148 computes `consnonfood = consumption - consfood` mixing real and nominal. Not affecting paper results (food/non-food never used).
4. **CHN and IDN have the same class of cosmetic bug** --- `consfood` / `consnonfood` exist in the real `.dta` files but are passed through nominal. Not affecting paper results.
5. **Empirical diagnostic**: row-aligning nominal vs real country files and computing median ratio by year yields a clean diagnostic. IDN ratios 9.5 -> 1.6 (base ~2015); CHN ratios 0.97 -> 0.83 (base 2010); TZA income 1.50 -> 1.00 (base 2013), TZA consumption non-monotone around 1.0 (explained by the two-deflator mix).

### Side commits

- `ac8d474` cherry-picked from `lca-inversion` commit `ff9a665` --- brings the ster-rename into this worktree as a prerequisite for any collapse work. No conflicts. 10 files changed.

### Decisions on the email

- Drafted a coauthor email at `docs/communications/2026-04-24_real-values-data-prep-email.md`.
- User decided NOT to send it. Food / non-food mislabeling is cosmetic (paper never uses these variables), within-country base years are not actually mixed (verified: one deflator per country covers both consumption and income), and the `replace` anti-pattern can be raised separately.
- The TZA two-deflator mix is a real methodological question, not a bug --- documented in the reviews for when the refactor spec needs it.

### Lessons

- Trust-but-verify subagent summaries. The inventory agent's first run was blocked on writes; its returned summary paraphrased findings that I nearly shipped to the user without reading the underlying file. On a later point (within-country base years) I overclaimed based on empirical ratios before reading the deflation code. User caught it. Going forward: when the claim would change what the user does, read the exact lines myself before making it.
- Row-alignment matters. Direct column diffs on same-sized Stata datasets misled initially because the two forks' row order was different. `sort pid year` before comparing columns.

### Open next steps (from earlier today)

1. Synthesize the four reviews into the MUST/SHOULD/MAY refactor spec at `quality_reports/specs/2026-04-24-grc-pipeline-refactor.md`.
2. Still deferred: smoke-test `5_GrRC.do` on IDN in `RP7/output/` to confirm the cherry-picked ster-rename reproduces the published headline before expanding. User has not yet approved launching the Stata run.
3. Refactor spec should likely include an explicit `values(nominal|real)` switch at `0_path_config.do` routing `$dirdata` to the right pre-deflated folder --- per the real-values-diff review, this is the entire feature; no in-pipeline deflation code needed.

## Continuation 2026-04-25 --- spec finalization, coauthor drift, smoke test launch

### Spec draft landed and approved

Spec at [quality_reports/specs/2026-04-24_grc-pipeline-refactor.md](../specs/2026-04-24_grc-pipeline-refactor.md) covers: 9 MUST items (M1--M9), 5 SHOULD items (S1, S1b, S1c, S2, S3), 2 MAY items, a to-do list for deferred work, target program API, risks, phasing, open questions, success criteria.

Key shape changes during the review loop:

- **M5 (enumerated-block collapse) deferred** per user 2026-04-25.
  Loops make per-country debugging harder.
  Moved to to-do list; picked up only after the regression test is trusted.
- **M9 added**: `run_grc` stores `e(runtime)` via `timer on 99 / timer off 99`. Lands in Phase 0 before the reference freezes so the scraper's runtime column is populated from day one.
- **S1 switched to Python** (`scripts/python/scrape_grc_runs.py` using `pyreadstat`). Comparison tooling lives in Python; Stata `speccurve` is out of reach for the visualization.
- **S1b reframed** as a Python matplotlib specification-curve figure (4 panels: $\phi$, $\Delta_{\text{avg}}$, $\Delta_{\text{never}}$, $\Delta_{\text{always}}$) with 90% and 95% CIs plus a speccurve-style checkmark grid for the spec-axis annotation.
  Verified that all four quantities are computed and saved in separate ster files by `run_grc` (lines 1761--1813 of `0_programs.do`): `_never`, `_always`, `_delta`, `_avg`.
- **S1c added**: currently the LaTeX GRC tables show $\Delta_{\text{never}}$, Average $\Delta$, and $\phi$ (verified by reading `GRC_CHN_consumption_urban_unb.tex`).
  $\Delta_{\text{always}}$ is computed and saved but not displayed.
  One-line edit in `grc_tex_table_trend` to surface it.
- **Q7 resolved**: the memoized "`define_switcherpars` hardcoded to `base(2)`" claim was obsolete.
  Direct read confirmed `initial_values` L1508 sets `local base = 2` only as a starting value and L1511--1524 overwrite it by selecting the switcher with highest t-stat on `switcher_*_choice` subject to $N_{\underline{d}}/T > 5$.
  Obsolete notes removed from project `CLAUDE.md` and `MEMORY.md`.

### Coauthor drift vs 2026-04-24 baseline

Diffed baseline (from commit `ec5318e`) against live Dropbox RP6 today.
Actual drift is tiny and thematically coherent:

1. `local iterations 500` -> `local iterations 100` in all GRC do-files (69 occurrences across 10 files).
   Speed optimization.
2. GMM $\phi$ starting value `-1` -> `-0.1` in `run_grc` and `run_grc_hukou` of `0_programs.do`.
   Same intent: faster convergence.
3. Removed `quickderivatives nolog` from 6 `gmm` continuation lines.
4. Removed our Verdier additions (`phistart` option, `run_grc_robust`, `run_grc_robust_vv`, `run_grc_onestep`, `initial_values_robust`, `gen_vfirst`).
   These are on us to push back when we hand off RP7 as ReplicationPackage7.

### Changes applied to RP7 (uncommitted)

User approved matching the coauthor's initial-value and iteration changes in our tree:

- Bulk: `local iterations 500` -> `local iterations 100` across 10 GRC do-files (69 replacements).
- `0_programs.do`: `phistart(real -1)` -> `phistart(real -0.1)` at 4 syntax sites (`run_grc`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`).
  This preserves `phistart` as an option we added but matches the coauthor's default.
- `0_programs.do`: `{phi=-1}` -> `{phi=-0.1}` at the one hardcoded use inside `run_grc_hukou`.
- `0_programs.do`: removed `quickderivatives nolog` at 6 `gmm` continuation lines.
- `0_master.do`: `$dir` for user `maand` now points at this worktree (`C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7`), with the other two worktree paths (`lca-inversion`, main tree) commented out.

### Smoke test launched 2026-04-25 ~11:43 local

Driver: `RP7/scripts/_smoke_5_GrRC.do` (leading underscore --- not part of the master pipeline).
Skips `1_processData.do` so nothing writes back to the Dropbox junction.
Runs `0_path_config.do` + `0_setup.do` + `0_programs.do` + `5_GrRC.do`.
Background job ID: `blpde8kpf`.

First-launch attempt (`bcet5sdmi`) failed immediately because the shell's pwd had drifted into `RP7/scripts/` already, so `cd RP7/scripts` resolved to a non-existent path.
Relaunched with an absolute `cd` and it's running.

Early log confirms changes are live:

```
run_grc: base trajectory = 2
run_grc: phi initial value = -.1
iterate(100)
```

and the first IDN block is in GMM iteration. Expected runtime multiple hours.

### Also during this continuation

- TZA deflator investigation and email draft at [docs/communications/2026-04-24_tza-real-deflation-email.md](../../docs/communications/2026-04-24_tza-real-deflation-email.md). Ready to send; user is reviewing.
- Verified `expmR` is NPS's Fisher-deflated consumption (spatial + within-wave time), base = within-wave. Different from LMMVW's `logearnings_real` which uses national CPI with 2013 base. Hence the TZA "real" has consumption and income on different deflator methodologies.

### Open next steps

1. Wait for smoke test completion. On success, diff `RP7/output/tables/GRC_IDN_consumption_urban_unb.tex` against the Dropbox published version to confirm reproducibility.
2. Commit the drift-matching changes (iterations 100, phi=-0.1, removed options) once smoke test passes.
3. Start Phase 0 of the refactor proper: M8 (done once smoke passes), M7 (regression-test scaffold), M9 (`e(runtime)`), then M6 Phase 0 (freeze reference outputs).
4. Coauthor TZA email: user will finalize and send.

## Continuation 2026-04-26 --- second-half ster-rename, stored-name limit, smoke pain

### Smoke test #2 result: GMM works, table builders fail

The first re-run after the iterations/phi/quickderivatives drift-match wrote all 75 ster files cleanly but errored at the table-builder section of `5_GrRC.do` with `grc_IDN_covs_0.ster not found`.
Cause: the original ster-rename commit (`ff9a665`, cherry-picked here as `ac8d474`) was incomplete --- it renamed the `estimates save` writes but missed many of the `estimates use`/`estimates store` reads.

Stale references found across:

- 5_GrRC.do (36), 6_GrRC_NonAg.do (12), 10/11/12/13_GrRC_*.do (36 each), 14_GrRC_NonAg_experience.do (48), 15_GrRC_birth.do (48). 288 lines total.
- 0_programs.do --- `grc_tex_table` (no `_trend`) at L2615--2618 had the bug, but it's dead code per the audit.
  Other `grc_tex_table_trend*` programs already used `\`spec'\`` correctly.

Per-file fix: prepend the spec prefix the file's `run_grc` calls actually write (`urban`, `nonag`, `exp`, `maxexp`, `expsh`, `maxexpsh`, `nonag_exp`, `birth`).
Done in one Python pass.

### Smoke test #3 result: hit Stata's stored-estimate name limit

Re-running after the rename completion produced 75 sters again but errored with:

```
_est_grc_IDN_urban_covs_trend_never invalid name
r(7);
```

Stata's `estimates store name` creates an internal `_est_<name>` matrix that must fit in 32 characters --- so the user-visible limit on stored-estimate names is **27 characters**.
The ster-rename pushed names from 24 chars (`grc_IDN_covs_trend_never`) to 30 chars (`grc_IDN_urban_covs_trend_never`), past the limit.

Fix per user direction: **Option B**. File names on disk keep the verbose form to match the published convention; in-memory stored names use a short prefix (`urban` -> `u`, `nonag` -> `n`).
The exp/maxexp/expsh/maxexpsh/nonag_exp/birth families don't need shortening (their names already fit).

Implementation:

- 5_GrRC.do, 6_GrRC_NonAg.do: substitute `grc_\`country'_urban_` -> `grc_\`country'_u_` (and `nonag_` -> `n_`) **only on lines that DO NOT contain `"$dir/output/"` or `estname(`** --- the file-path lines and the `run_grc, estname(...)` lines must keep the verbose form.
  First pass had a too-broad filter (only excluded `$dir/output/`), which incorrectly shortened the `estname()` arguments and would have produced files named `grc_IDN_u_covs_0.ster`.
  Reverted and redid with the strict filter.
  Final counts: 33 substitutions in 5_GrRC.do, 11 in 6_GrRC_NonAg.do.
- 0_programs.do `grc_tex_table_trend`: added `local spec_short = cond(\`spec'==urban,"u",cond(\`spec'==nonag,"n","\`spec'"))` and rewrote the foreach loop body to use `\`spec_short'\`` so the constructed names match the stored ones.

### M10 resume-on-interrupt guard added

Three-line `${skip_if_exists}` check in `run_grc` body, gated by a global so default behavior is unchanged.
Checks for `<estname>_avg.ster` (the last subgroup ster written, at L1813).
Spec updated.

### Smoke iteration tools

- `_smoke_idn_only.do`: focused driver running only IDN/cons/urban/unb (~5 GMM fits + 1 LaTeX table). Skips `0_setup.do` (its `window stopbox` calls are real modal dialogs in batch mode, fire when packages are flagged missing). Inlines the `$keepvars` and `$covs_gmm*` globals from 5_GrRC.do lines 42-51 since the smoke skips that prelude.
- `_smoke_5_GrRC.do`: full-pipeline smoke. Both wrap their bodies in `capture noisily { }` so any error doesn't trigger the Windows "Stata finished" modal.
  After-capture `exit, STATA clear` always runs.

### Open puzzle: IDN-only smoke is slower than the full smoke

Launched the IDN-only smoke at 2026-04-26 11:40.
At 13:46 the StataMP-64 process is still alive but the log stopped writing at 13:30 (~16 min idle).
Last log entry was Step 2 / iteration 6 of GMM for `covs_2`, with Q(b) flat near 0.000360.

Earlier smoke test #2 (the FULL pipeline running CHN + IDN + TZA at all balance/depvar combinations) completed in ~30 minutes for 75 ster files.
The IDN-only smoke has been running 2+ hours and is on the 4th of 5 IDN specs.
Something is fundamentally different between the smoke driver and 5_GrRC.do as `include`d in the full smoke.

User decision (2026-04-26 13:50): wait a few more minutes before killing, then diagnose.

### Open next steps

1. Resolve the IDN smoke runtime puzzle. Likely candidates: `set varabbrev off` not run (effect: ?); some global not set that 5_GrRC.do sets later; the data in memory differs.
2. Once the IDN smoke completes (or is killed), compare the resulting IDN/cons/urban/unb table to the published version.
3. Commit the rename-completion + stored-name-shortening fixes after smoke passes.

## Continuation 2026-04-26 (afternoon) --- static verification + M9 timer

### Smoke runs in chronological order

| # | Driver | Started | Ended | Outcome |
|---|---|---|---|---|
| 6 | `_smoke_idn_only.do` (with `capture noisily` wrap) | ~11:40 | killed ~13:50 | hung in covs_2 GMM Step 2 |
| 7 | `_smoke_idn_only.do` (no wrap) | ~17:20 | killed ~18:36 | iter pattern looked similar; killed manually |
| 8 | `_smoke_5_GrRC.do` (no wrap, full pipeline) | 18:37 | killed 19:35 | one fit completed (5 sters for IDN cons/urban/covs_0) at 19:31; ~53 min for that one fit |

What we **know** about runtime: smoke #8 produced 5 ster files, all timestamped 19:30-19:31, log mtime 19:35.
We do not have explicit start/end timestamps from earlier smokes (#2 and #3) to compare against.
The "30 min for 45 fits" baseline was from memory, not a recorded measurement.
We do not know what caused the recent runs to take longer than expected.

### Static verification of the ster-rename, all paths

Rather than re-run the smoke for verification, traced every `<estname>` write/read pair through code review.

**5_GrRC.do (urban):** writes `grc_<c>_urban_covs_*` via `run_grc, estname(...)`; reads same paths via `estimates use`; stores in memory under Option-B short `grc_<c>_u_*`; `estimates table` and `grc_tex_table_trend` (with `spec_short=u`) reference the short stored names. All consistent.

**6_GrRC_NonAg.do (nonag):** same shape, with `n_` short form.

**10/11/12/13/14/15_GrRC_*.do (exp/maxexp/expsh/maxexpsh/nonag_exp/birth):** stored names are short enough as-is (longest is `grc_IDN_nonag_exp_ca_never` = 26 chars + `_est_` = 31, just under Stata's 32 limit). No Option-B shortening needed in these files. `grc_tex_table_trend_exp` and `_birth` use the long `\`spec'\`` form, which matches.

**8_GrRC_hukou.do:** `country_short` (e.g. `CHN_rural_first`) pre-encodes the subgroup; suffixes are short (`c0/ct/c1/c2/ca`); `_n` instead of `_never`. Worst case `grc_CHN_rural_first_ca_n` = 24 + `_est_` = 29. Fits.

**16_heterogeneity_tables.do:** had stale `urban_` form in `estimates store`/`estimates table` lines that exceeded the 32-char limit when combined with `_delta`. Fixed in this turn: applied Option B (`urban_` -> `u_`, 6 substitutions, file paths preserved).

**0_programs.do `het_table_delta` / `het_table_mu`:** referenced the long `grc_<c>_urban_covs_all{,_delta}` form in their `esttab` namelists. Fixed in this turn to use `grc_<c>_u_covs_all{,_delta}` to match the caller's stored names.

**0_programs.do `grc_tex_table_trend`:** added `spec_short = cond(spec=="urban","u",cond(spec=="nonag","n",spec))` and the foreach loop now builds `grc_<c>_<spec_short>_<estname>_<sub>`.

Static verification result: the rename is consistent end-to-end across all entry points.

### M9 added (`run_grc` writes a `runtime` scalar to its main ster)

Each call to `run_grc` (or `run_grc_onestep`) increments a global counter `${grc_timer_slot}` and uses the next sequential `timer` slot.
This means at the end of a session `timer list` shows every fit's elapsed seconds in slot order; nothing is cleared.
The same value also gets saved into the ster as a custom scalar via `estadd scalar runtime = r(t<slot>), replace : \`estname'`, plus `estadd scalar timer_slot = <slot>` so each result knows which slot it used.

Important detail: `e(runtime)` is **not a built-in Stata return** --- we are creating a custom scalar via `estadd` (estout package).
After `estimates restore`, the scalar is accessible via `e(runtime)` because we put it there.
The S1 scraper can read it.

### What we know is true, what we do not

True (verified by direct evidence):

- 69 occurrences of `local iterations 500` -> `100` across 10 files.
- 4 `phistart(real -1)` -> `phistart(real -0.1)` in `0_programs.do`.
- 1 hardcoded `{phi=-1}` -> `{phi=-0.1}` in `run_grc_hukou`.
- 6 `quickderivatives nolog` lines removed.
- 288 `grc_\`country'_\`estname'` references prefixed with the appropriate spec across 8 numbered files.
- Option B applied to `5_GrRC.do` (33), `6_GrRC_NonAg.do` (11), `16_heterogeneity_tables.do` (6).
- `spec_short` logic in `grc_tex_table_trend`; long form in `_exp` and `_birth`; bare `country` in `_hukou`.
- `het_table_delta`, `het_table_mu` updated to short stored names.
- M10 resume guard inserted in `run_grc` body.
- M9 timer + `estadd scalar runtime` in `run_grc` and `run_grc_onestep`.
- Smoke #8 (full pipeline, no wrap): 5 ster files written for IDN cons/urban/covs_0, file mtime 19:30-19:31, launched 18:37, log mtime 19:35.

Not established:

- Whether `capture noisily` materially affects GMM runtime.
- Whether smoke #2/#3 took ~30 min for 45 fits (claimed from memory; no timestamps recorded).
- Why smoke #8's first fit took ~53 min wall-clock.

### Open next steps (as of 2026-04-26)

1. Commit current changes (drift match + rename completion + Option B + M9 + M10 + smoke drivers + planning artifacts).
2. When ready to do another smoke run: it will write `runtime` into each ster, giving us per-fit timings for the first time.
3. Phase 0 of the spec (M7 regression scaffold + reference freeze).

## Continuation 2026-04-27 / 28 --- overnight smoke succeeded, tables verified

### Smoke #9 (full pipeline, no wrap, no resume guard)

Driver: `_smoke_5_GrRC.do`.
Launched 2026-04-26 21:31, log closed 2026-04-27 17:56 --- ~20.5 h wall clock.
Exit code 0, clean.

Produced all 9 expected LaTeX tables under `RP7/output/tables/`:
`GRC_<CHN|IDN|TZA>_<consumption|income>_urban_<unb|bal>.tex`.

### Bit-identical to RP6 2026-04-22 reference

Diffed all 9 tables against the coauthor's RP6 in Dropbox (latest run there is 2026-04-22).
All 9 are byte-for-byte identical.
This is strong evidence that:

- The drift-match settings (iterations 100, $\phi_{\text{start}} = -0.1$, no `quickderivatives nolog`) reproduce the same numerical results as the coauthor's published run.
- The completed ster-rename + Option B short stored names produce identical LaTeX output.
- GMM is robust to the change in starting value of $\phi$ (-1 to -0.1).

(Caveat: the comparison is to RP6's 2026-04-22 output, not to whatever tables are currently in the paper draft on Overleaf. User confirmed RP6 2026-04-22 is the right reference at this point.)

### M9 timing data captured

Section 3 (income/urban/unb) sters were inspected via `_peek_runtime.do` reading `e(runtime)` and `e(timer_slot)`.
Section 1 (cons/unb) and section 2 (cons/bal) timings live only in the smoke's in-session `timer list`, which evaporated at Stata exit; only section 3 sters survive on disk after the M11 overwrite.

Per-fit runtimes from section 3:

| Country | Spec | Runtime | Slot | Converged |
|---|---|---|---|---|
| IDN | covs_0 | 1667 s | 31 | Y |
| IDN | covs_all | 2183 s | 35 | Y |
| TZA | covs_0 | 6 s | 36 | Y |
| TZA | covs_all | 12 s | 40 | Y |
| CHN | covs_trend | 220 s | 42 | **N** |
| CHN | covs_1 | 241 s | 43 | **N** |
| CHN | covs_2 | 258 s | 44 | **N** |
| CHN | covs_all | 177 s | 45 | Y |

Worth noting: CHN income covs_trend / covs_1 / covs_2 reported `converged=N` at the iter=100 cap, yet the LaTeX tables match the published 2026-04-22 RP6 tables exactly --- which means the published tables were ALSO produced under the same iter cap and reached the same final values.
Not a problem for reproducing what's published, but worth knowing if anyone re-examines the iter cap.

IDN is the slow country (~28--36 min per income fit), TZA is fast (~5--12 sec), CHN is moderate (~3--5 min).

### Timer visibility added (after smoke #9 was already running)

Two changes for the next run:

- `run_grc` and `run_grc_onestep` now display `run_grc: <estname> fit in NNN.NN sec (timer slot K)` immediately after each fit's M9 timer stop.
- `_smoke_5_GrRC.do` now appends `timer list` at the end so the log shows the full slot table.
  `_smoke_full.do` already had `timer list` at the end.

These don't affect the just-completed run --- Stata held the old in-memory copies of those scripts.

### Other artifacts

- `_peek_runtime.do`: standalone inspection script that reads each ster's `e(runtime)` / `e(timer_slot)` / `e(Jpval)` / `e(converged_str)`.
- `_smoke_full.do`: overnight driver that runs 5_GrRC + 6 + 8 + 10--15 + 16 with `${skip_if_exists} 1` enabled.
  Created but not yet successfully run (M11 should land first so the bigger run gets unique sters).

### Phase 0 done (2026-04-28)

Three commits:
- `eec4141` --- Spec M11 (unique ster filenames per fit, locked-in shorthand).
- `fbef9bf` --- Per-fit timer display in `run_grc` + `timer list` summary at end of `_smoke_5_GrRC.do` + `_smoke_full.do` overnight driver + `_peek_runtime.do` helper + session log update.
- `b1ddf25` --- Smoke #9 output tables (9 of 9 bit-identical to RP6 2026-04-22).
- New: `tests/reference/output/tables/*.tex` (9 frozen tables) + `tests/regression_test.py` + `tests/README.md`.

Verification: `python tests/regression_test.py` passes (9 identical, 0 differs, 0 missing, 0 extra).

### Validation tier scheme adopted (avoid 30h re-run per step)

Spec extended with a "Validation tiers for incremental work" section (4b). Three tiers:

- **Tier 1 (seconds, every commit)**: static grep audit of rename/code-path changes; stored-name length check; lint syntax-check.
- **Tier 2 (minutes, per phase)**: replay smoke. For pure-rename changes, rename existing surviving sters on disk + run only the table-builder block; for sections without surviving sters, run a tiny TZA-only GMM subset (~1 min). Diff resulting tables against frozen reference.
- **Tier 3 (~30 hours, end of major milestone)**: full smoke. Refresh `tests/reference/` with any new artifacts.

Worked example for M11 in the spec: ~10 min total of Tier 1 + Tier 2 work, vs. the 20.5h Tier 3 cost.

### Phase 1 plan (next)

Phase 1 = M1 + M2 + M11 together. Sub-steps:
1. M11 in `0_programs.do` (run_grc, run_grc_onestep, run_grc_robust*, suffix strings).
2. M11 in 5/6/8/10--16: rename `estimates save / use / store / table` and call-site `estname` args.
3. M11 in `grc_tex_table_trend*`: rebuild loop bodies; drop `spec_short`.
4. M1 + M2: extend `run_grc` with `exp_variant` + `extra_regressor` options.
5. Update 5_GrRC.do to loop over those options; delete 10/11/12/13/14/15.
6. Tier 1 audit; Tier 2 replay smoke; commit.
7. Tier 3 full smoke at end of Phase 1; refresh `tests/reference/` to include experience/birth/nonag families.

### What we know is true (2026-04-28)

- Smoke #9 launched 2026-04-26 21:31, finished 2026-04-27 17:56, ~20.5 h.
- 75 ster files on disk after run; 9 LaTeX tables; all 9 bit-identical to RP6 2026-04-22.
- `e(runtime)` and `e(timer_slot)` survive in section-3 sters; sections 1 and 2 sters were overwritten (M11 pending).
- CHN income (slots 42--44) converged=N; the matching published tables presumably did too.
- Phase 0 committed and validated end-to-end via `tests/regression_test.py`.

## Continuation 2026-04-28 (afternoon) --- Phase 1a (M11 rename) done

### Plan finalized

[docs/plans/2026-04-28-phase1-m1-m2-m11.md](../../docs/plans/2026-04-28-phase1-m1-m2-m11.md) covers Phase 1 split into 1a (M11 only) and 1b (M1+M2 collapse) with a Tier 2 gate between.

User decisions logged on plan questions:
1. Hukou compression in Phase 1a (not deferred).
2. Skip hukou Tier 2 coverage; rely on Tier 3.
3. IDN nonag-exp absorbed into `6_GrRC_NonAg.do` (Phase 1b).
4. `extra_regressor(varname)` (general, not a dedicated `birth` flag).
5. Dropbox RP6 GRC_*_exp*.tex etc. trustworthy as Phase 1b reference.
6. Rename touches `.ster` filenames + stored estimate names ONLY; `.tex` output filenames unchanged.

### M11 implementation

**`0_programs.do`**:
- Header doc block at top documenting the spec3 / covs2 / sfx1 / hukou-subgroup scheme.
- Suffix swaps in 5 programs (run_grc, run_grc_onestep, run_grc_hukou, run_grc_robust, run_grc_robust_vv): `_never -> _n`, `_always -> _a`, `_delta -> _d`, `_avg -> _g`. Done via replace_all on `"$dir/output/`estname'_<sfx>"` literals (4 substitutions × 5 programs = 20 sites).
- M10 resume guard updated: `_avg.ster` -> `_g.ster`.
- `grc_tex_table_trend` foreach loop: rebuilt to use `c0/ct/c1/c2/ca`; dropped `spec_short` local; comment updated.
- `grc_tex_table_trend_hukou` foreach loop: rebuilt to use the new `_n/_g` suffixes (caller passes already-compressed `country_short`).
- `grc_tex_table_trend_exp`, `grc_tex_table_trend_birth` foreach loops: rebuilt; caller now passes `spec(<spec3>_<family>)` instead of `spec(<family>)`.
- `het_table_delta`, `het_table_mu`: ester refs updated to `grc_<c>_cuu_ca[_d]`.
- Dead `grc_tex_table` (no `_trend`): added deprecation comment; left foreach body as-is.

**Numbered files** via `tools/rename_m11_phase1a.py` (one-shot helper, committed):
- `5_GrRC.do`: 3 sections, 37 substitutions per section (urban -> cuu/cub/iuu).
- `6_GrRC_NonAg.do`: single section, 25 subs (nonag -> cnu).
- `8_GrRC_hukou.do`: 12 sub-sections (4 hukou subgroups × 3 spec3); per-section `local country_short CHN_<full>` -> `CHN_<hu>_<spec3>` (23 renames total, since urban_first §3 has only one country_short line); plus `_avg -> _g` swaps.
- `10/11/12/13`: 93 subs each, prefix `cuu` added to existing `<family>_<covs2>` shape.
- `14_GrRC_NonAg_experience.do`: 84 subs, prefix `cnu`. Preserves the prior 4-way collision (only §4's sters survive on disk; tex_table runs immediately after each section's fits, so produced .tex tables are bit-identical). Disambiguation lands in Phase 1b.
- `15_GrRC_birth.do`: 84 subs, prefix `cuu` (both sections; preserves prior collision).
- `16_heterogeneity_tables.do`: 10 subs, `urban_covs_all{,_delta}` -> `cuu_ca{,_d}`.

**Helper smoke drivers**:
- `_peek_runtime.do`: ster name list updated to `iuu` (smoke #9 income survivors); comment notes that section-1 (cuu) and section-2 (cub) sters were overwritten before M11 landed.
- `_smoke_idn_only.do`: estname args updated to `cuu_<covs2>`; foreach loop updated to read/store under unified shorthand; `spec(urban) -> spec(cuu)`.

**Tier 1 audit (grep)**:
- Old patterns (`urban_covs_`, `nonag_covs_`, `_u_covs_`, `_n_covs_`, `spec_short`, `\`estname'_never|always|delta|avg`) all removed except inside the dead `grc_tex_table` program (intentionally left with deprecation note).
- Hukou subgroup names (`grc_(IDN|CHN|TZA)_(rural|urban)_(first|only)`) all removed.
- Worst-case stored-estimate name length: `_est_grc_CHN_cuu_maxexpsh_ca_n` = 30 chars. Fits Stata's 32-char limit with 2 chars headroom.

**Tier 2 replay smoke**:
- Driver: `_tier2_tza.do` (TZA cons/urban/unb only, 5 GMM fits + 1 LaTeX table).
- Wall-clock: ~7 min from launch to table written (longer than the 1-min estimate from session log; possibly cold-start overhead or different from the smoke #9 run-time per fit).
- Result: `RP7/output/tables/GRC_TZA_consumption_urban_unb.tex` BIT-IDENTICAL to `tests/reference/output/tables/GRC_TZA_consumption_urban_unb.tex`.
- 25 sters written under M11 shorthand: `grc_TZA_cuu_<covs2>{,_n,_a,_d,_g}`. Confirms write path produces correct names; confirms read path picks them up; confirms the table builder produces the right bytes.
- `python tests/regression_test.py` still passes (9/9 identical) after Tier 2.

### Coauthor-facing README

[RP7/scripts/STER_NAMING.md](../../RP7/scripts/STER_NAMING.md) documents the new naming convention for coauthors who don't use git.
Covers: TL;DR, what changed/why, per-shape mapping tables (5_GrRC.do/6, 8_GrRC_hukou.do, 10--15), examples, where the locked-in convention lives in code, headroom for adding new specs, and a list of what the rename did NOT do (regressor lists, sample, .tex filenames).

### Open next steps (Phase 1b)

1. Pre-step: import 10--15 reference tables from Dropbox RP6 `output/tables/GRC_*_exp*.tex` etc. as `tests/reference/` baseline for Phase 1b.
2. Extend `run_grc` with `exp_variant(none|exp|maxexp|expsh|maxexpsh)` and `extra_regressor(varname)` options.
3. Expand `5_GrRC.do` loop over `exp_variant`; absorb 14 nonag-exp into `6_GrRC_NonAg.do`; absorb 15 birth via `extra_regressor(birth)`.
4. Delete 10/11/12/13/14/15.
5. Tier 1 audit + Tier 2 partial validation.
6. Tier 3 full smoke (~30 hours), refresh `tests/reference/`.

## Continuation 2026-04-28 (late) --- Phase 1b scope revised after user feedback

### What got revised, why

Walking into Phase 1b, I proposed extending `run_grc` with `exp_variant(...)` / `extra_regressor(...)` options and absorbing the experience family into a `foreach variant in exp maxexp ...` loop inside `5_GrRC.do`.
User vetoed loops outright (durable feedback now in [feedback_no_loops_for_regressions.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/feedback_no_loops_for_regressions.md)): "We should only save on code by writing programs, not by writing loops" --- the user must be able to comment out a single per-cell call to re-run only IDN cons/urban for an interactive sanity check.
With a `foreach country / foreach spec` loop that's a code-edit dance.

That reframed the whole approach. The right collapse is: extract the repeated body into a single program (`run_grc_with_extra_regressor`) in `0_programs.do`, and the numbered files become a sequence of EXPLICIT per-cell calls to that program.
Same code-savings goal, preserved interactive re-runnability.

### The captions/notes problem and the captions-out-of-do approach

Designing `run_grc_with_extra_regressor` ran into a dead end on captions/notes: each of the 36 cells in 10--13 has its own bespoke caption + notes, parameterizing them via program args meant the "saved" lines come right back as call-site arguments.

User proposed pulling captions + notes OUT of the .do pipeline and into the paper LaTeX, where they belong.
.do programs become a pure data pipe; paper handles all bespoke text. Confirmed.

### What moves vs stays (corrected)

I was sloppy initially and proposed dropping `prehead`/`postfoot` from `grc_tex_table_trend*` entirely. User correctly flagged that this would lose the `\label{}` (silently breaks `\ref{}` cross-references) AND the "Time FE Y Y Y" indicator rows in `postfoot` (these are DATA --- they tell readers which columns include FE/female/age2 --- not decoration).

Correct split, now in [feedback_table_split_in_do_vs_paper.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/feedback_table_split_in_do_vs_paper.md):

- **Stays in .do output (the `\input`-able file):** `\begin{tabular}{l ccccc}\toprule \textbf{Dep. var:} <depvar>` column header + estimate rows + `\cmidrule{2-N}` + indicator rows (`Time FE & Y & Y... \\\\`, `Covariates & ... \\\\`) + `\bottomrule\end{tabular}`.
- **Moves to paper LaTeX:** `\begin{table}[...]\centering\begin{threeparttable}` envelope, `\caption{}`, `\label{tab:...}`, `\begin{tablenotes}...\end{tablenotes}`, closing `\end{threeparttable}\end{table}`.

So `prehead`/`postfoot` arguments to .do programs become SHORTER, not gone.

### Paper file location

Pivoted from `paper/main.tex` (worktree, OUTDATED per user) to the live Overleaf-Dropbox folder:
`C:\Users\maand\Monash Uni Enterprise Dropbox\Emilia Tjernstrom\Apps\Overleaf\ReturnsToMigration-clean\`

Editable: `main-sections.tex` (note plural --- user verbally said "main-section"), files under `sections/`, `preamble.tex`.
Off-limits: `main.tex` in that folder. Never touch.
Tables under `tables/` are generated by the pipeline; do not hand-edit.

Saved in [reference_overleaf_paths.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_overleaf_paths.md).

### Paper-side macro design (sketch, awaiting refinement)

Define in `preamble.tex`:

- Helper macros for repeated phrases: `\sigstars`, `\seclusterind`, `\datasourceIDN`, `\datasourceCHN`, `\datasourceTZA`, `\countrynameIDN/CHN/TZA`, `\refnotesIDN`.
- `\GRCtable{country}{depvar}{choice}{balance}[optional extra notes prefix]` --- main 5_GrRC.do tables (5 cols: c0/ct/c1/c2/ca). Optional 5th arg defaults to empty; the IDN canonical table fills it with the long-form variable explanations; CHN/TZA omit it and just inherit the standard `\refnotesIDN`-style cross-ref notes.
- `\GRCexptable{country}{depvar}{choice}{balance}{variant}` --- 4-column experience and birth family tables. Notes pattern: "This table repeats the analysis of Table~\ref{tab:GRC_<c>_<dvc>_<chc>_<bal>} with <variant> included as an additional regressor."
- `\GRChukoutable{...}` --- per-subgroup hukou tables.

Each call site is 1--2 lines; bespoke prose lives inside the call args (for the canonical IDN table) or comes from the macros' defaults (for non-canonical tables).

### Order of operations + commit cadence

User: "let's commit now; let's commit often basically. We can always revert commits."

Phase 1b plan revised:
1. Extract every current caption/notes/postfoot indicator-row from 5/6/8/10--15 into a reference doc, clearly labeled by (country, depvar, choice, balance, variant). One commit.
2. Design draft macro set in `preamble.tex` (paper-side). Get user sign-off. One commit.
3. Modify `grc_tex_table_trend*` programs in `0_programs.do` to drop wrapper-and-notes pieces only (keep label-free tabular + indicator rows + bottomrule). Update all call sites in 5/6/8/10--15 to drop the now-stale args. One commit.
4. Update `main-sections.tex` (and `sections/*.tex`) to wrap each `\input{tables/GRC_X.tex}` with `\GRCtable{...}` etc. Add the missing 33 family-table inputs (paper currently only inputs 20 GRC tables). One commit.
5. Tier 2 verify: re-run TZA, paper compiles, slim .tex output works. Refresh `tests/reference/` for the touched tables. One commit.
6. Add `run_grc_with_extra_regressor` program to `0_programs.do`. Replace 10/11/12/13/14/15 with explicit per-cell calls. Per file commits acceptable.
7. Delete 10/11/12/13/14/15 once verified. One commit.
8. Tier 1 audit + Tier 2 partial smoke. One commit.
9. Tier 3 full smoke (~30h). Refresh `tests/reference/` to include all 53+ tables. Final Phase 1b commit.

### Other decisions

- Q3 from earlier plan ("delete vs comment-out 10--15"): delete after verification works.
- Q (combined program vs two): one combined `run_grc_with_extra_regressor` program; call sites pass the regressor variable name.
- Q (canonical-table notes asymmetry): the IDN cons/urban/unb table carries the long variable-explanation prose via the optional 5th macro arg; CHN/TZA tables (and bal/income variants) omit the optional arg and inherit a default short-notes block that cross-references back to the IDN table. Same template, asymmetric content.

### What's NOT decided yet (to confirm during execution)

- Macro shape details (argument order, optional vs required) --- sketched above, will refine in Phase 1b step 2.
- Whether 10--15 absorb into 5_GrRC.do/6_GrRC_NonAg.do as new sections, or stay as separate thin numbered files. Lean: stay as separate thin files, since the user emphasized per-file granularity for re-runs (`do 11_GrRC_max_experience.do` should still mean "re-run the maxexp family alone").
- Country and depvar specific information must be CLEARLY LABELED in extraction doc (per user direction). Country-specific = data source, country name; depvar-specific = "log consumption" vs "log income"; both should be separate macro components, not blended.

### Phase 1b.1 done (commit cceb9cb)

[quality_reports/reviews/2026-04-28_paper-table-text-extraction.md](../reviews/2026-04-28_paper-table-text-extraction.md) catalogs all caption / notes / postfoot blocks from 5/6/8/10--16 organized by pattern.
5 distinct notes templates identified (A: IDN canonical, B: standard cross-ref, C: income shared, D/E: heterogeneity).
3 postfoot patterns (P1: 5-col main, P2: 4-col experience/birth, P3: 1-col heterogeneity).
59 paper-side macro calls to write at Phase 1b.4.

### Phase 1b.2 done (commit 22bafce + 2ebe9f1)

Drafted macros at [quality_reports/reviews/2026-04-28_preamble-macros-draft.tex](../reviews/2026-04-28_preamble-macros-draft.tex), got user sign-off (with two revisions: keep income notes shared, normalize TZA on "Tanzanian National Panel Survey"), ported to Overleaf:

`C:\Users\maand\Monash Uni Enterprise Dropbox\Emilia Tjernstrom\Apps\Overleaf\ReturnsToMigration-clean\preamble.tex`

Added `\usepackage{etoolbox}`, atomic helper macros, country/treatment/depvar caption components, 3 notes assembly macros (Templates A, B, C), and 3 table macros (`\GRCtable`, `\GRCexptable`, `\GRChukoutable`).
Heterogeneity macros (D/E) deferred until 1b.3 reads the canonical IDN heterogeneity prose.

`xelatex main-sections.tex` succeeds: 59-page PDF, no new errors (only pre-existing overfull hboxes).

Note: Overleaf folder is outside this git repo. The staging draft in `quality_reports/reviews/` is the in-repo record of what was added.

### Phase 1b.3 starting

Modify `grc_tex_table_trend*` programs in `0_programs.do` to drop only the wrapper-and-notes pieces from `prehead`/`postfoot`. Keep label-free tabular + indicator rows + bottomrule. Update all call sites in 5/6/8/10--16 to drop the now-stale `htb`, full-prehead, full-postfoot args.

Sequencing risk: 1b.3 changes the bytes of every .tex file the pipeline produces. Tier 2 verify (1b.5) will compile the paper with new slim tables to confirm visual identity.

### Phase 1b.3 done (commit 87898b7)

`0_programs.do` 6 programs slimmed (`grc_tex_table_trend`, `_hukou`, `_exp`, `_birth`, `het_table_delta`, `het_table_mu`): drop `htb`, `PREhead` from syntax, build slim prehead (just `\begin{tabular}` + col header), append `\bottomrule\end{tabular}` to caller's `POSTfoot`.

Caller stripping via `tools/captions_to_paper_phase1b3.py`: 493 substitutions across 10 GRC files. Drops `local htb_str / table_caption / table_label / table_notes`, drops `htb()` / `prehead()` args, shortens `local postfoot_str` to indicator-rows-only.

Helper smoke drivers (`_tier2_tza.do`, `_smoke_idn_only.do`) updated manually (not in pipeline FILES list).

Deferred: 2_OLS_uGRC.do, 7_OLS_uGRC_hukou.do, 9_learning.do have the same caption/notes/postfoot pattern but produce non-GRC tables via direct esttab calls. Migration deferred --- needs separate paper-side macros for OLS reduced-form table shape.

### Phase 1b.4 done (paper-side macro call swap)

Swapped 11 `\input{tables/GRC_*}` → macro calls in Overleaf-Dropbox:

- `sections/sec_results.tex`: 5 (IDN/CHN/TZA cuu + 2 hukou first), with `[\GRCnotesIDNcanonical]` for IDN canonical
- `sections/sec_robustness.tex`: 3 (IDN/CHN/TZA cub)
- `sections/app_nonag.tex`: 1 (IDN cnu)
- `sections/app_hukou.tex`: 2 (CHN hukou rural_only + urban_only)

Commented-out `\input` lines (income tables in app_nonag, balanced cells in app_balanced, etc.) left as-is --- they were inactive before Phase 1b and remain inactive.

The 33 family tables (10--15 output: experience variants + birth) are NOT yet referenced in the paper. Per user "no paper-prose changes" lean, leaving as-is. They'll exist on disk as slim .tex after Tier 3 but won't be `\input`-ed until the paper grows to reference them.

Note: Overleaf folder is outside this git repo. Edits to `main-sections.tex`, `sections/*.tex`, and `preamble.tex` don't show in `git status` here. Session log + per-step commits in this repo are the only durable trace.

### Phase 1b.5 starting

Regenerate the IDN/CHN/TZA cuu cell `.tex` files via `_tier2_tza.do`. Compile `main-sections.tex` to confirm `\GRCtable` produces a visually-acceptable PDF for that cell. If TZA cuu compiles correctly, the same macro shape works for the other 10 active sites (CHN/IDN cuu, all 3 cub, IDN cnu, 4 hukou). Refresh `tests/reference/output/tables/GRC_TZA_consumption_urban_unb.tex` to the new slim format.

Important: paper compilation will FAIL for the other 10 sites until they too are regenerated to slim format. Tier 2 here is a single-cell smoke; full coverage waits for Tier 3 (1b.10).
