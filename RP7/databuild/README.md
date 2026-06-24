# Data-construction pipeline

This folder rebuilds the three analysis input datasets (`CHN.dta`, `IDN.dta`, `TZA.dta`) that the CKT analysis pipeline consumes, starting from the upstream replication-package outputs.
It exists so the analysis inputs are reproducible from documented code rather than a hand-copied file of unknown provenance.

## What it does

The build is a bridge from the replication outputs to our analysis datasets.
It does not rebuild the upstream packages (HKLM, LMMVW) from their original survey microdata; it starts from their build outputs.

- IDN is built from the HKLM output `Intergen_Analysis_IFLS.dta`, plus `Total_panel_HKLM_hhsize.dta` and `location_vars.dta`.
- CHN is built from the LMMVW output `chn_panel.dta`, plus the raw CFPS adult waves 1 to 4 (used only to construct the experience variable).
- TZA is built from the LMMVW output `tza_panel.dta`, plus David's `Panel_TZA.dta` (used only for education and CPI).

All consumption and income variables are nominal.

## How to run

```
cd RP7/databuild
stata-mp -e do 0_databuild_master.do
```

Use the `-e` flag, not `-b`: on Windows `-b` always shows a modal completion popup, while `-e` exits cleanly.

Outputs land in `output/`.
The build never touches the canonical files and never runs the analytical pipeline.

## Files

- `0_databuild_paths.do` sets the directory globals from the current directory.
- `0_databuild_master.do` runs the three country builds.
- `1_build_IDN.do`, `2_build_CHN.do`, `3_build_TZA.do` build one country each.
- `inputs/` holds the copied replication inputs (gitignored).
- `output/` holds the regenerated datasets (gitignored).
- `manifest_inputs.csv` records the SHA-256 and size of every input.

## Verification

`_verify_equivalence.do` is a temporary harness that confirms the regenerated files match the canonical ones (via Stata `datasignature` and `cf _all`).
It is not part of the pipeline and is deleted once the build verifies clean.
Its result is recorded in `verification_report.md`.

## Provenance note

The build is faithful to the team's original "Variable selection" and "Data preparation" do-files; only paths, file organization, and comments were changed.
The original files live in the Dropbox `Returns to migration/Data/` tree and are not used at build time.
