# 2026-06-24 --- Reproducible data-construction pipeline

## If you resume

A clean, reproducible data-construction pipeline now lives in `RP7/databuild/` on branch `worktree-data-construction`.
It rebuilds the three analysis inputs (`CHN.dta`, `IDN.dta`, `TZA.dta`) from the upstream replication-package outputs and was verified to reproduce the canonical files exactly.

Status: complete and verified.
The branch is not yet merged to main.

Next actions if continuing:
- Merge `worktree-data-construction` into main when ready.
- Optionally wire the real and spatial-deflator tracks (`260302`, `260508`) the same way; only nominal was built.
- The Todoist task to document the CHN/CFPS provenance in the paper data section is filed (id `6gwq3x2hQ2R3xmWr`).

## Mode

Implementation (spec to plan to build to verify), following the four-mode workflow.

## What was built

`RP7/databuild/` contains a self-contained pipeline:
- `0_databuild_paths.do` sets directory globals from the current directory.
- `0_databuild_master.do` runs the three country builds, wrapped in capture noisily.
- `1_build_IDN.do`, `2_build_CHN.do`, `3_build_TZA.do` build one country each.
- `inputs/` (gitignored) holds 2.08 GB of copied replication inputs, pinned by `manifest_inputs.csv` (SHA-256 + size).
- `output/` (gitignored) holds the regenerated datasets.
- `README.md` documents the chain; `verification_report.md` records the equivalence result.

The build starts from replication outputs, not original microdata (per the scope decision): IDN from the HKLM `Intergen_Analysis_IFLS`, CHN from the LMMVW `chn_panel` plus raw CFPS adult waves 1 to 4 for the experience variable, TZA from the LMMVW `tza_panel` plus David's `Panel_TZA` for education and CPI.
The do-files transcribe the team's `230328 Variable selection_DB_MK.do` and `250314 Data preparation_DB.do` verbatim, changing only paths, organization, and comments.

## Verification result

All three regenerated datasets are content-identical to the canonical `Data/countries/*.dta`: matching `datasignature`, identical variable list, and `cf _all` identical position by position.
Observation and unique-`pid` counts match (CHN 143,252 / 50,965; IDN 118,828 / 44,517; TZA 34,598 / 15,673).
The live `RP7/data/countries` hub is byte-identical (SHA-256) to the canonical files, so regenerated equals canonical equals the analysis input.

The nominal-vs-real probe resolved a standing question: real consumption differs from nominal for both CHN and IDN (CHN mean 55,338 nominal vs 47,572 real; IDN 231,496 vs 866,561).
The equal `.dta` file sizes across nominal and real were a red herring, since deflation changes values, not storage size.

## Decisions and reasoning

- Rebuild from replication outputs only, not original microdata, because the original LMMVW microdata and raw TZA waves are not on disk, and the build outputs are.
  The CHN experience variable is the one exception: it needs the raw CFPS adult waves, which are present, so they were copied in as a pinned input.
- Full-copy the 1.5 GB of raw CFPS rather than subsetting, per the user's call.
- Nominal track only; the live counterfactual code reads bare `{country}_unb.dta` (nominal), confirmed in `data_loader.py`.
- New, clearly named do-files rather than copies of the Dropbox files, whose dated names are hard to follow.
- Hard safety rule observed throughout: read Dropbox only, never write or delete there, no junctions, all outputs to the repo.

## The popup incident and the fix

Two Stata modal popups fired during this session, both my fault.
Root cause: I invoked Stata with `stata-mp -b`, which always shows the Windows completion dialog.
The fix, per the user-level rule `~/.claude/rules/stata-conventions.md` (verified 2026-05-04), is `stata-mp -e`, which exits with no dialog.
`exit, STATA clear` does not suppress it; the project memory note that claimed otherwise was stale and has been corrected.
A separate bug also surfaced: a `/*` inside a header comment (`countries/*.dta`) opened a nested block comment that swallowed all the `global` definitions, which is why the first build failed with empty paths.

## Files changed

- New: `RP7/databuild/` pipeline (do-files, README, manifest, verification report, .gitignore).
- Corrected memory: `feedback_stata_gotchas.md` section 3 now points to the `-e` fix.
- Spec and plan committed to main: `quality_reports/{specs,plans}/2026-06-24-data-construction-pipeline.md`.

## Open items

- Merge the branch to main.
- Real and spatial tracks not yet built.
- Document the CHN/CFPS provenance in the paper (Todoist task filed).
