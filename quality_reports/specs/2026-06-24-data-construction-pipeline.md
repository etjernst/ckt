# Spec: reproducible data-construction pipeline (replication outputs to analysis datasets)

Date: 2026-06-24
Mode: Implementation
Status: draft, awaiting approval

## Problem

The analysis pipeline consumes `CHN.dta`, `IDN.dta`, `TZA.dta` from `RP7/data/countries/`.
Until now those files were produced by a chain of badly-named do-files in the Dropbox `Returns to migration/Data/` tree and hand-copied into the repo by an RA.
The chain is undocumented, depends on per-user hardcoded paths, and was nearly lost in the 2026-06-23 junction incident.
We want a clear, self-contained build that regenerates the three analysis datasets inside the repo and proves the output matches the files we have been using.

## Scope

Build a bridge from the upstream replication-package outputs to our three analysis input datasets.
We start from the replication build outputs, not the original survey microdata.
Improving on that boundary (rebuilding the upstream packages from raw) is explicitly out of scope for now.

Country starting points:
- IDN starts from the HKLM build output `Intergen_Analysis_IFLS.dta` (plus `Total_panel_HKLM_hhsize.dta` and `IFLS/location_vars.dta`).
- CHN starts from the LMMVW build output `chn_panel.dta`, plus raw CFPS adult waves 1 to 4 for the experience variable.
- TZA starts from the LMMVW build output `tza_panel.dta`, plus David's `Panel_TZA.dta` for the education and CPI variables.

Only the nominal track is in scope.
`250314 Data preparation_DB.do` is the nominal bridge whose `save CHN/IDN/TZA` statements name our analysis files.
The current counterfactual code reads bare `{country}_unb.dta`, confirming the live analysis is nominal.
The real and spatial-deflator variants are deferred to a later pass.

## Hard safety constraints

These are non-negotiable and override convenience.

- MUST NOT write to or delete anything under any Dropbox path. Dropbox is read-only for this work.
- MUST NOT create or rely on directory junctions into Dropbox. Inputs are copied as real files into the repo.
- MUST NOT run the analytical pipeline (`0_master.do` and the estimation scripts). The data-construction build is separate and far shorter.
- MUST NOT overwrite the canonical `countries/` files during verification. The build writes to a scratch output directory.

## Requirements

MUST:
- Copy every needed input as a real file into a gitignored data directory inside the worktree. No junctions.
- Record a manifest of every input: relative path, byte size, OS SHA-256, and Stata `datasignature`. Commit the manifest.
- Write new, clearly named do-files that perform the build, rather than copying or editing the Dropbox do-files. One do-file per country, plus a path-config file, a master, and a verification file. Follow the numbered, descriptive naming pattern used by the analysis scripts.
- Produce `CHN.dta`, `IDN.dta`, `TZA.dta` in a scratch output directory.
- Verify content equivalence between the regenerated files and the canonical `Data/countries/*.dta` (and the `RP7/data/countries` copies) using Stata `cf _all` or `datasignature confirm`, which compare data content independent of file-header timestamps.
- Assert per-country invariants: observation count, unique `pid` count, variable names, and variable labels.
- Write a verification report recording every check and its result. A mismatch is a finding to investigate, not a thing to silence.

SHOULD:
- Keep the build master runnable cell by cell, consistent with the project rule against collapsing re-runnable steps into opaque loops.
- Record the raw OS SHA-256 of the regenerated files as supplementary evidence, while treating `cf`/`datasignature` as authoritative.
- Probe whether CHN and IDN `consumption` actually differs across the nominal, real, and real_spatial canonical files, since the three are byte-identical in size and the deflation may not have been applied.

MAY:
- Add a short README in the build directory describing the chain and how to rerun it.
- Stage the real and spatial tracks as a follow-up once the nominal build verifies clean.

## Reproducibility boundary and one nuance to confirm

The CHN experience variable is built from raw CFPS adult waves, which are original microdata.
The raw CFPS waves are present on disk, so the build can reproduce the experience variable and match the canonical file.
This is a small departure from "no original microdata," and it is necessary for exact equivalence.
Recommendation: include the raw CFPS waves as a pinned input for CHN, since they are available and the canonical `CHN.dta` already embeds the experience variable.

## Success criteria

- The build runs end to end from copied inputs with no Dropbox writes and no junctions.
- `cf _all` reports zero differences for all three countries against the canonical files, or every difference is identified and explained.
- The input manifest and verification report are committed, so the next person can rerun the build and confirm the same result.

## Out of scope

- Rebuilding HKLM or LMMVW from their original survey microdata.
- The real and spatial-deflator tracks.
- Any change to the analysis pipeline or its outputs.
