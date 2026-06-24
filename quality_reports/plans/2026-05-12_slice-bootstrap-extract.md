# Plan: extract `0_slice_bootstrap.do` from the three slice drivers

Date: 2026-05-12
Branch: `worktree-grc-pipeline-refactor`
Status: approved (verbal, "let's implement Change 2" from [docs/parallelization-overview.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/docs/parallelization-overview.html))

## Goal

Collapse the ~70 lines of duplicated post-`$dir` boilerplate in
[run_extras_maxexpsh.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_maxexpsh.do),
[run_extras_birth.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_birth.do),
[run_extras_cnu.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_extras_cnu.do)
into a single shared include.

Not in scope (per 2026-05-12 conversation): `$dir` username block extraction.
Stata cannot resolve sibling-file lookups from an arbitrary launch cwd, and
`cd`-to-scripts is rejected as an anti-pattern per DIME conventions. Env-var
seeding deferred until coauthor buy-in is plausible.

## What goes in `0_slice_bootstrap.do`

Lines 62-80 of each slice driver are identical and run AFTER `$dir` is set:

1. `include "$dir/scripts/0_path_config.do"` --- subdirectory globals,
   `$vsfx`, `$grc_max_iter`, etc.
2. `quietly include "$scripts/0_programs.do"` --- shared programs (~155 KB,
   needs `quietly` to avoid saturating batch output).
3. `global skip_if_exists 1` --- enables the resume guard in `run_grc`.
4. `global copyOverleaf 0` --- slice drivers don't build tables.

These four lines (plus the comment headers describing them) move to
`0_slice_bootstrap.do`. Each slice driver replaces them with a single include.

## What stays in each slice driver

- `clear all`, `version 17`
- `global values "nominal"` (with the comment block explaining the M4 switch ---
  this is the user-facing knob, leave it visible at the top of each driver)
- The 14-line username-to-`$dir` block + the "`$dir` empty" error guard
  (chicken-and-egg, can't be factored without env vars or cd convention)
- The `capture log close` / `log using` / `capture noisily { body }` /
  `local saved_rc` / `log close` / error message / `exit, STATA clear`
  envelope (log filename differs per driver; not worth a wrapper program)
- The body of cell calls (the actual content that differs)

## Files

New: `RP7/scripts/0_slice_bootstrap.do`
Edited: `RP7/scripts/run_extras_maxexpsh.do`, `run_extras_birth.do`, `run_extras_cnu.do`
Untouched: `0_master.do` (has its own setup pattern; not a slice driver),
`0_path_config.do`, `0_programs.do`, `run_master_resume.do`

## Verification

Run one slice driver in batch mode after the refactor:

```
cd RP7/scripts && stata-mp -e do run_extras_birth.do
```

Expected: with `skip_if_exists=1` and all 4 IDN birth cells already fit,
the driver should `SKIP` every cell and exit clean in <30 seconds. Log
file `$logs/run_extras_birth.log` should show four `run_grc: SKIP ...`
lines and `rc=0`.

If any cell re-fits unexpectedly, abort and investigate before committing
the other two drivers.

## Commit sequence

1. Add `0_slice_bootstrap.do` (new file, no callers yet).
2. Refactor all three slice drivers together (parallel change).

## Risks

- `0_slice_bootstrap.do` is not on Stata's adopath; `include "$dir/scripts/0_slice_bootstrap.do"` works because `$dir` is set by the caller. If a future entry point forgets to set `$dir` first, the include will fail with a path-not-found error, which is loud and easy to diagnose.
- No behavior change is expected. Sters on disk should not be touched (skip_if_exists guard).
