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
