# 2026-05-07---post-merge inversion smoke unblocked and going green

Mode: implementation.
Picked up from the morning's `2026-05-07_inversion-merge-and-rename.md` hand-off, which left the smoke blocked on a data junction problem.

## Goal

Get `_smoke_5b_one_cell.do` to attach inversion CIs to the four post-refactor IDN/cuu/ca staging sters, end-to-end, so the post-merge naming + plumbing is verified before extending to all 15 production cells.

## What changed

Three substantive changes this session.

### Repointed `RP7/data` junction from RP6 to RP5

The `RP7/data` junction targeted `Dropbox/.../ReplicationPackage6/data/`, but that folder is empty.
All `.dta` files (raw `countries/` and derived `processed/`) still live under `Dropbox/.../ReplicationPackage5/data/`.
The MEMORY.md note that RP4-to-RP6 happened on 2026-04-22 is correct only for `scripts/`; data was never moved.

Repointed via:

```pwsh
cmd /c rmdir "C:\git\ckt\.claude\worktrees\lca-inversion\RP7\data"
cmd /c 'mklink /J "C:\git\ckt\.claude\worktrees\lca-inversion\RP7\data" "C:\Users\maand\Dropbox (Personal)\Returns to migration\ReplicationPackage5\data"'
```

The user's preference (stated this session): pulling data from RP5 is fine; copying ~400 MB into the repo is not, because git bloats permanently and our data-safety rule keeps data in Dropbox.
Rejected option: copy `RP5/data/{countries,processed}` into `RP6/data/`.
Why dropped: duplicates ~400 MB on Dropbox for no benefit; the RP5 path resolves through the junction transparently.

This change is a Windows directory junction; it is NOT tracked in git.
Anyone setting up a fresh worktree must redo it.
The MEMORY.md "Workspace" entry will be updated to reflect "RP6 data is empty; data lives at RP5/data" in the next memory pass.

### Smoke driver wired through `0_path_config.do`

Commit [`2505f99`](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
[RP7/scripts/_smoke_5b_one_cell.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_one_cell.do) previously hardcoded `$dropbox = ".../ReplicationPackage6"` and `$dirdata = "$dropbox/data"`, both of which bypassed the junction and pointed at the empty RP6 folder.
It also did not source `0_path_config.do`, which left the project-wide constants `$grc_max_iter` and `$grc_min_switchers_per_wave` empty.

Replaced the hardcoded paths with `quietly include "$dir/scripts/0_path_config.do"` and an explicit `global logs "$dir/output"` override (so the smoke log lands beside `$output`, not in `$dir/scripts/logs` where path_config sends it).

The empty `$grc_min_switchers_per_wave` was producing the cryptic `T> invalid name` r(198) error.
`initial_values` line 1671 reads `if N_'s' / T > $grc_min_switchers_per_wave { ... }`.
With the global empty, that substituted to `if N_'s' / T >  {`, which Stata parsed as a comparison `T >` followed by `{` --- and complained that `T>` was not a valid name.
This was hard to read because the error tag printed as `T> invalid name` literally, with the `>` looking like a wrap continuation marker rather than part of the offending token.
A `set trace on` over the call surfaced the empty RHS immediately.

Also added `set linesize 250` so future error wraps don't masquerade as syntax artifacts.

### `attach_inversion_ci` quote-stripping fix

Commit [`6c85a3f`](file:///C:/git/ckt/.claude/worktrees/lca-inversion).
The program's `STERdir(string asis)` option preserves outer double quotes verbatim when callers pass `sterdir("${inversion_sterdir}")` --- which is the exact pattern used by both the smoke and the production [RP7/scripts/5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do) (line 141).
The local `sterdir` arrived inside the program with literal `"` characters, and the subsequent `local target "\`sterdir'/\`estbase'\`suffix'.ster"` concatenation produced a malformed path with embedded quotes.
`confirm file` then silently rejected all four suffixes in the smoke run.

The first attach run logged `0 of 4 sters updated`, but the read-back showed `_g` carrying inversion macros.
That was a red herring: those macros came from the 2026-04-30 attach-test run on `grc_IDN_urban_covs_all_avg.ster`, which was byte-copied to `grc_IDN_cuu_ca_g.ster` during the post-merge rename.
The macros traveled with the file.
Today's run had attached nothing.

Fix: strip outer quotes once at program entry.

```stata
local sterdir = subinstr(`"`sterdir'"', `"""', "", .)
```

Safe because file paths cannot contain `"` on either Windows or POSIX.

This fix unblocks production too: `5b_inversion.do` was silently doing nothing whenever it was called against a quoted `${inversion_sterdir}`, which is the only way it ever has been called.

## Smoke result (IDN/cuu/ca)

Re-copied the byte-identical staging sters into the smoke directory (so the read-back reflects today's attach, not the stale 2026-04-30 macros), restarted Stata, and ran the smoke.
Result: `4 of 4 sters updated`, all four suffixes round-trip through `estimates use`.

| Estimand | point | 95% CI | 90% CI |
|----------|------:|--------|--------|
| $\hat\phi$ | $-0.60$ | $[-1.23, -0.01]$ | $[-1.09, -0.14]$ |
| $\Delta_N$ | $0.07$ | $[0.01, 0.15]$ | $[0.02, 0.13]$ |
| $\Delta_{\text{avg}}$ | $0.04$ | $[-0.02, 0.09]$ | $[-0.01, 0.08]$ |
| $\Delta_T$ | $-0.14$ | $[-\infty, 0.04] \cup [0.66, +\infty]$ | $[-\infty, 0.02] \cup [1.46, +\infty]$ |

$J_R = 26$, switchers kept = 27.
$\hat\phi$ negative and bounded away from zero (the pro-poor LCA story).
$\Delta_T$ disconnected interval is the expected weak-ID footprint at the always-takers extrapolation; the LCA is asking the data to say something about a counterfactual far from where switchers are observed.

All CI endpoints are exact multiples of 0.01.
That is a grid-resolution artifact: `lca_inversion.attach_inversion_for_stata` evaluates the test statistic on a 0.01-spaced $\phi_0$ grid and reports the convex-hull endpoints as the smallest grid points whose $p$-value crosses 0.05/0.10.
Different specs land on the same grid points whenever the underlying weak-ID region is wider than the grid resolution.
This is documentation-worthy but not a bug; the grid spacing is documented in the python module.

## Approaches rejected and the reason

Approach: copy `RP5/data/{countries,processed}` into `RP6/data` so the junction stays pointing at RP6.
Why dropped: ~400 MB Dropbox duplication for no functional benefit; data is immutable so junctioning at RP5 is harmless.

Approach: copy data into the repo at `data/` and commit.
Why dropped: ~400 MB in git history is permanent bloat; data-safety rule says keep data in Dropbox.

Approach: source `0_path_config.do` AND let it set `$logs = $dir/scripts/logs`.
Why dropped: smokes should land their logs near `$output` so they don't pollute the production scripts/logs folder.
Re-overriding `$logs` after sourcing is the clean compromise.

Approach: change `STERdir(string asis)` to `STERdir(string)` in `attach_inversion_ci` so plain-string parsing strips quotes.
Why dropped: plain `string` rejects values containing spaces.
File paths on this project pass through Dropbox folder names with spaces, so `string asis` is required for any caller that doesn't pre-resolve the path.
Stripping quotes once inside the program is more robust.

## Files touched

- [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): added 8-line block at the top of `attach_inversion_ci` to strip outer quotes from `sterdir`.
- [RP7/scripts/_smoke_5b_one_cell.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_one_cell.do): replaced hardcoded `$dropbox`/`$dirdata` with `include "$dir/scripts/0_path_config.do"` plus a `$logs` override; added `set linesize 250`.

Files NOT edited but verified:

- [RP7/scripts/5b_inversion.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do): the production caller benefits from the `attach_inversion_ci` fix without further changes.

Junction repointed (not in git):

- `C:\git\ckt\.claude\worktrees\lca-inversion\RP7\data` --- now targets `Dropbox/.../ReplicationPackage5/data/`.

## Open items

- Run the smoke against the remaining 14 (country, covs2) cells to confirm the plumbing works on TZA and CHN, and on the four non-`ca` covs specs for IDN.
This is the natural next step.
The 75-ster staging inventory is intact; need to copy + rename into the smoke dir and call `5b_inversion.do` with `$inversion_sterdir` pointed there.
- Add `5b_inversion` to `0_master.do` once the broader smoke is green.
- Port the `grc_tex_table_trend` extension (commit `2b24344` on the pre-merge branch) onto main's Phase 2 program shape so the inversion CI rows actually appear in rendered tables.
- Delete `RP7/output/staging/` (user said earlier it can go).
- Update MEMORY.md "Workspace" entry to reflect RP5 vs RP6 data location reality.

## If you resume

The post-merge inversion plumbing is verified on one cell.
The two next high-value moves are (a) extend the smoke to all 15 cells and (b) wire 5b into master.
Both are short.
After those, the inversion thread closes for now and the next push is on the D-grid wall benchmark for path D weak-ID-robust inference (Path 2 from the earlier hand-off).

## Addendum: 15-cell smoke, master integration, table-builder port

Continued in the same session.
Three more chunks of work; the inversion thread is now closed end-to-end at the plumbing level.

### Full 15-cell smoke

Copied the 75 staging sters into the smoke directory under the post-refactor naming (`urban_covs_X` -> `cuu_cX`, `_never/_avg/_always/_delta` -> `_n/_g/_a/_d`).
Wrote [`RP7/scripts/_smoke_5b_full.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_full.do), which sources `0_path_config.do`, points `$inversion_sterdir` at `RP7/output/smoke/`, and `do`s `5b_inversion.do`.
Result: **15 of 15 cells, 60 of 60 sters updated, no failures**.
Walltime ~7 minutes total.

The cell-by-cell CI table is now in the chat transcript and the `5b_inversion.log` at [`RP7/output/5b_inversion.log`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/5b_inversion.log).
Two patterns worth flagging.
First, every `c0` (no-covariate) spec produces an empty CI across all three countries --- no $\phi_0$ in the grid is consistent with the LCA at 5%.
Without period FE the period effects load onto the trajectory dummies, the LCA fit is poor everywhere on the grid, and the test rejects.
Second, CHN's CI is empty in every covs spec including `ca`.
This is consistent with the known Hansen J rejection in pooled CHN; the LCA fails for the same reason.
Hukou-split CHN (rural-first / urban-first) should produce non-empty CIs, but those sters live in a separate naming branch and are not in `5b_inversion.do` --- intentional given the user's "main results first" guidance.

### Vestigial `exit, STATA clear` removal (commit `1c98c44`)

Found three production scripts ending with `exit, STATA clear` under the comment "Suppress the Windows batch-mode 'Stata finished' popup": [`5b_inversion.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do), [`9_GRC_extras.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/9_GRC_extras.do), [`17_verdier_robust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/17_verdier_robust.do).
Per Stata docs, `exit, STATA` exits Stata entirely from any do-file context, including from inside an `include`d file.
That means `0_master.do` had been silently chained-broken: 9 would exit Stata before 10_make_tables, 11_make_figures, or 17 ran.
The popup-suppression motivation is now obsolete --- the user-global Stata convention switched to `stata-mp -e` invocation, which already suppresses the dialog.
Dropped all three lines.

### `5b_inversion` wired into master (commit `2f5b0b3`)

Added a single `include` line to [`0_master.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_master.do) directly after `4_GrRC.do`, matching the comment in `5b_inversion.do`'s header ("Run after 4_GrRC.do, before tables get built by 10_make_tables.do").
`$inversion_sterdir` defaults to `$output`, so the production sters from `4_GrRC.do` get inversion macros attached in place.

### Table builder port (commits `5e24727`, `7983c8e`)

Three substantive changes to `grc_tex_table_trend` in [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do).

First, **load `_a` sters and add a Delta_always block**.
Per user instruction "I do want to add Delta_always to ALL tables below delta_average".
The pre-merge attempt put Delta_always in the Delta_never block's `coeflabels`, which was a silent no-op because `_n` sters do not carry a Delta_always coefficient (verified via MCP: `colnames e(b) = Delta_never` only).
The clean fix is a separate fourth esttab block that loads `_a` sters and emits the Delta_always row with its inv_dT CI rows attached via `stats()`.

Second, **attach inversion CI rows to all three Delta blocks plus the parent**.
`stats(inv_dN_ci90_str inv_dN_ci95_str, fmt(s s) labels(...))` for the Delta_never block.
`stats(inv_davg_ci90_str inv_davg_ci95_str, fmt(s s) labels(...))` for the Delta_avg block.
`stats(inv_dT_ci90_str inv_dT_ci95_str, fmt(s s) labels(...))` for the new Delta_always block.
`s(inv_phi_ci90_str inv_phi_ci95_str ...)` prepended to the existing parent-block s() clause.
The inv_phi rows ride on the parent ster, the others ride on their respective subgroup sters.
All three subgroup sters and the parent carry the same inversion macros (the python compute is per-cell, not per-suffix), so any of the four sters could in principle source any of the inv_* macros.

Third, **postfoot tablenote**.
Added a `\multicolumn{cmid}{p{\linewidth}}{...}` row before `\bottomrule` explaining that multi-island CIs (one endpoint at $\pm\infty$) reflect the singularity at $\phi=-1$ in the LCA mapping for $\Delta_{\text{always}}$.
Initially included the name "Mobius" with an umlaut escape (`M\""obius`); esttab's postfoot processing rendered the escape as a literal `\` followed by a newline, splitting the word across two lines in the .tex output.
Dropped the name reference rather than chase the escape; the singularity's mathematical content is what the note is for, the eponym is incidental.

### Verification

Wrote [`RP7/scripts/_smoke_table_render.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_table_render.do) to render one IDN/cuu paper table end-to-end against staged sters in `$dir/output/`.
Verified all four esttab blocks succeed, all CI rows render, the multi-island union renders correctly for IDN/ca's $\Delta_T$, and the postfoot note appears once per table.
The rendered fragment is a valid LaTeX `tabular` block of 38 lines.
Cleaned up the staged sters and the test .tex after verification.

### Decisions, with the why

Decision: drop the umlaut name reference in the postfoot tablenote.
Why: esttab's postfoot processing mishandles `\""` escape sequences (Stata's mechanism for embedding `"` in regular `"..."` strings); the result was a literal `\` + newline + `obius` in the rendered .tex.
The note's purpose is to explain what union-of-intervals means for a reader who has not seen the LCA derivation; naming the singularity is incidental.

Decision: NOT port `grc_tex_table_trend_robust` (the Verdier-Vella variant).
Why: VV-robust pipeline isn't on this branch's mainline (no `vv_*.ster` on disk).
Plus the robust variant has a separate disk-naming bug that needs fixing in the same pass: `17_verdier_robust.do` lines 167--172 load `_never`/`_avg` from disk, but `run_grc_robust_vv` saves to `_n`/`_g`.
Tracked as a TODO; out of scope for the inversion port.

Decision: drop "Delta_always" from the Delta_never block's coeflabels.
Why: the previous inclusion was a silent no-op (the `_n` ster doesn't have that coefficient).
Keeping it is misleading.
The Delta_always row now lives in its own block with the right ster.

### Approaches rejected

Approach: emit only inv_phi, inv_dN, and inv_davg CI rows --- skip inv_dT entirely.
Why dropped: user explicitly said add Delta_always to ALL tables.

Approach: park inv_dT CI rows in the parent block alongside inv_phi.
Why dropped: would orphan the rows below the unrelated phi coefficient row.
A dedicated Delta_always block reads better.

Approach: keep "Mobius" with the umlaut, fix the escape via compound double quotes (`` `"M\"obius"' ``).
Why dropped: would still pass through esttab's postfoot processing, which has its own quote-handling quirks.
The simpler fix is to drop the name; the umlaut isn't load-bearing.

### Files touched in this addendum

- [`RP7/scripts/_smoke_5b_full.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_5b_full.do) (new): full 15-cell smoke driver.
- [`RP7/scripts/_smoke_table_render.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_table_render.do) (new): one-cell table-render smoke.
- [`RP7/scripts/0_master.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_master.do): one-line `include` of 5b_inversion.
- [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do): `grc_tex_table_trend` extension (load `_a` sters, add Delta_always block, attach inversion CI rows to all four blocks, Mobius tablenote).
- [`RP7/scripts/5b_inversion.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/5b_inversion.do), [`RP7/scripts/9_GRC_extras.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/9_GRC_extras.do), [`RP7/scripts/17_verdier_robust.do`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/17_verdier_robust.do): drop vestigial `exit, STATA clear`.
- [`docs/TODO.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): added "Port to grc_tex_table_trend_robust" entry.

### Status

Post-merge inversion thread closed end-to-end at the plumbing level.
Master pipeline now runs 4_GrRC -> 5b_inversion -> 5_GrRC_NonAg -> ... -> 10_make_tables -> 11_make_figures -> 17_verdier_robust without exit-mid-pipeline.
Table builder emits paper-ready LaTeX with Delta_never, Delta_avg, Delta_always, and phi rows each carrying their LCA inversion CIs.

### Open items

- Refine grid spacing for paper-final CIs (TODO).
- Inversion CIs on robustness specs (TODO).
- Port `grc_tex_table_trend_robust` + fix `17_verdier_robust.do` disk-naming bug (TODO).
- Run master end-to-end on this branch to verify the full chain --- not done; would take hours; cleanest done as a separate session.
- Pre-existing `_est_<name>` 32-char overflow TODO in `5_GrRC.do`'s table-build block.
- Pre-existing TODO to regenerate auxiliary tables for the Delta_avg fix.
