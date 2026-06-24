# Plan: reproducible data-construction pipeline

Date: 2026-06-24
Spec: [2026-06-24-data-construction-pipeline.md](../specs/2026-06-24-data-construction-pipeline.md)
Status: draft, awaiting approval

## Where the work lives

A dedicated worktree, `data-construction`, branched from main.
The build lives under `RP7/databuild/`, so it can ship to coauthors as part of the eventual `ReplicationPackage7/` handoff.

```
RP7/databuild/
  0_databuild_master.do      tracked   orchestrates the build and the verification
  0_databuild_paths.do       tracked   path config: a maand branch pointing at this worktree
  1_build_IDN.do             tracked   HKLM output -> IDN.dta
  2_build_CHN.do             tracked   LMMVW chn_panel + raw CFPS experience -> CHN.dta
  3_build_TZA.do             tracked   LMMVW tza_panel + Panel_TZA education/CPI -> TZA.dta
  _verify_equivalence.do     temp      cf _all vs canonical, invariants, write report; deleted after verification passes
  manifest_inputs.csv        tracked   SHA-256 + datasignature of every input
  verification_report.md     tracked   results of every check
  README.md                  tracked   the chain and how to rerun it
  inputs/                    gitignored copied real files (read from Dropbox once)
  output/                    gitignored regenerated CHN/IDN/TZA.dta
```

A `.gitignore` in `databuild/` excludes `inputs/` and `output/`.

## Step 1: copy inputs into the repo

Read from Dropbox, write only into `RP7/databuild/inputs/`.
No junctions, no writes back to Dropbox.

Inputs to copy:
- IDN: `Replication HKLM/Intergen_Analysis_IFLS.dta`, `Replication HKLM/Total_panel_HKLM_hhsize.dta`, `IFLS/location_vars.dta`.
- CHN: `Replication LMMVW/JME-Migration-Costs-2020-main/Data/Build/China/chn_panel.dta`, and the four raw CFPS adult files (`ecfps2010adult_202008`, `ecfps2012adult_201906`, `ecfps2014adult_201906`, `ecfps2016adult_201906`).
- TZA: `Replication LMMVW/JME-Migration-Costs-2020-main/Data/Build/Tanzania/tza_panel.dta`, `David/Panel_TZA.dta`.
- Comparison targets: `Data/countries/CHN.dta`, `IDN.dta`, `TZA.dta`, copied into `inputs/canonical/` so verification is self-contained.

I will report the total copy size before copying the large raw CFPS files.
If a raw CFPS adult file is very large, I will confirm before copying rather than bloating the working tree silently.

After copying, write `manifest_inputs.csv` with relative path, byte size, SHA-256, and Stata `datasignature` for every input.

## Step 2: write the build do-files

Fresh files, faithful to the logic in `230328 Variable selection_DB_MK.do` and `250314 Data preparation_DB.do`, with clear names and per-step comments.
No loops that hide re-runnable steps.

- `0_databuild_paths.do` sets one global for the worktree root and derives `inputs/` and `output/`. It defines a maand branch only; the Dropbox per-user branches are not carried over.
- `1_build_IDN.do` reads `Intergen_Analysis_IFLS`, applies the experience, outlier, adult-equivalent, location-merge, rename, and `education_max` steps, and saves `output/IDN.dta`.
- `2_build_CHN.do` builds the experience variables from the four raw CFPS waves, reads `chn_panel`, runs the variable selection and rename, merges experience, builds adult-equivalent and `education_max`, and saves `output/CHN.dta`.
- `3_build_TZA.do` reads `tza_panel`, runs the variable selection and rename, merges education and CPI from `Panel_TZA`, builds experience and adult-equivalent, and saves `output/TZA.dta`.
- `0_databuild_master.do` runs the three builds only. The permanent pipeline is the master plus the three country builds plus the path config.

The verification harness is separate and temporary.
`_verify_equivalence.do` is a one-time scaffold to confirm the build reproduces the canonical files.
It is not wired into the master and not part of the data pipeline.
Once the build verifies clean, the temp do-file is deleted; only its written report is kept.

These files write only to `output/`.
They never touch the canonical `countries/` files.

## Step 3: build and verify

Run `cd RP7/databuild && stata-mp -b do 0_databuild_master.do`.
This is the data-construction build only.
The analytical pipeline (`0_master.do` and the estimation scripts) is never run.

The temporary `_verify_equivalence.do` does, per country:
- `cf _all` (or `datasignature confirm`) of `output/COUNTRY.dta` against `inputs/canonical/COUNTRY.dta`.
- A second `cf _all` against the live `RP7/data/countries/COUNTRY.dta` hub.
- Asserts on observation count, unique `pid` count, variable names, and variable labels.
- A probe of whether CHN and IDN `consumption` differs across the nominal, real, and real_spatial canonical files.

It writes `verification_report.md` with every check and its result, plus the raw SHA-256 of the regenerated files as supplementary evidence.

I will report the build runtime. Expectation is minutes to under an hour, not the multi-hour analytical run.

## Step 4: commit and report

Commit the do-files, manifest, verification report, README, and `.gitignore`.
Data directories stay gitignored.
Report the verification outcome.
If `cf _all` shows differences, I stop and investigate the drift rather than adjusting anything to force a match.

## What needs your approval inside this plan

- The worktree location and the `RP7/databuild/` layout.
- Copying the large raw CFPS adult files into the gitignored `inputs/` (I will confirm sizes first).
- The decision to read the canonical `countries/` files read-only from Dropbox once, to copy into `inputs/canonical/`.

## Risks and how the plan handles them

- Dropbox data loss: the build only reads Dropbox and only writes into the repo. No junctions. This is the direct lesson from 2026-06-23.
- Silent mismatch: the equivalence check is the success criterion, and a mismatch halts the work as a finding.
- Path drift: a single maand path branch and copied inputs make the build independent of the Dropbox per-user paths.
