# Stage 0 hub characterization: old hub vs rebuilt hub

Date: 2026-07-14.
Comparison driver: [compare_hubs.do](file:///C:/git/ckt/RP7/tests/stage0/compare_hubs.do); rebuild driver: [rebuild_hub.do](file:///C:/git/ckt/RP7/tests/stage0/rebuild_hub.do).
Cell-level results: [hub_characterization.csv](file:///C:/git/ckt/quality_reports/staging/stage0/hub_characterization.csv); variable-level detail: [hub_var_diffs.csv](file:///C:/git/ckt/quality_reports/staging/stage0/hub_var_diffs.csv).

## What ran

`1_processData.do`, unmodified at commit state 2026-07-14, rebuilt all 34 processed cells into `RP7/data_rebuild/processed/` (raw read through a junction; the canonical hub at `RP7/data` untouched; `0_CHN_hukou_restrictions.do` not run).
Every cell was then compared against the old hub: 1:1 merge on `pid` and `period`, three commit-signature checks, and a generic mismatch count for every common variable.

## Verdict

Every difference between the hubs is attributed to exactly one of the three post-build commits.
No variable was added or removed in any cell.
No value moved outside the three signatures.
The determinism probe passed: the batch rebuild of `IDN_unb.dta` is value-identical (`cf _all`) to the copy the author built interactively at 19:45 through the same code; the only byte differences are the header timestamp and uninitialized padding in the label blocks, which Stata fills with session memory.

## Signature 1: per-capita outcome (commit `47b60e3`)

In 33 of 34 cells, max |lndepvar_new - (lndepvar_old - ln(hhsize_cube))| is between 9.4e-07 and 1.7e-06, float-storage noise around zero.
The apparent outlier, `idn_unb` at 0.9986, is the confirmation case: its old copy was already rebuilt through current code (2026-07-14, 19:45), so both sides are per-capita, `lndepvar` shows zero mismatches, and the signature statistic degenerates to max ln(hhsize_cube).
Income cells carry the same signature off log income, confirming the income files previously stored raw ln(income) despite the stale already-per-capita comment the old code trusted.

## Signature 2: Change A, strict-spec reflagging (commit `a11e013`)

Balanced cells: `idn_bal` (and its 2waves/3waves copies) lose 145 person-waves, and recomputing the strict-spec rule on the old file predicts exactly those 145 with zero mismatch.
TZA balanced cells lose none, and the rule predicts none.
CHN balanced cells lose 3 person-waves that the recompute could not predict; the trace resolved them completely (next section).
Unbalanced cells: reflag counts run from 3 (CHN consumption) through 8-135 (income cells) to 145 (IDN 2waves/3waves), with zero reverse flips (1 to 0) anywhere.
The `trajectory`, `switcher`, and `unbalanced_choice` mismatches in the variable sweep track the reflagged person-waves cell by cell; they are the Change A cascade (reflagged individuals move to the lumped unbalanced trajectory), not independent movement.

## The 3 CHN rows, traced to the raw data

The 3 unattributed person-waves are one individual, pid 620123103, observed in periods 1, 2, and 4 of the old `CHN_bal` file.
The raw file shows why the recompute was blind: the pid has all four waves in raw with consumption present, but wave 3 (2014) has missing `age` and missing `education`.
Old build: the pid survives the consumption drop with 4 waves, is classified balanced, and then the post-balance covariate drop removes wave 3, saving a de-facto-unbalanced 3-wave individual inside the balanced cell.
New build: Change A's rule fires on wave 3's missing `age` at balance time and reflags the pid unbalanced, so they leave the balanced cells and appear reflagged in the unbalanced cells (the `reflag_0to1 = 3` rows).
This pid is the exact inconsistency Change A was written to remove; the attribution is Change A, fully explained.

## Signature 3: C10, non_switcher reclassification (commit `1e10113`)

`non_switcher` differences appear only where the new `unbalanced` flag is 1, in every cell: zero balanced-worker differences across all 34 cells.
The large counts (for example 47,731 person-waves in `chn_unb`, 55,869 in `idn_unb_2waves`) are the fix operating as documented: unbalanced workers previously evaluated to non_switcher = 0 via a missing balanced-only trajectory, and are now classified by observed movement.

## Caveat for the promotion decision

The old hub's `idn_unb.dta` is not a stale-state witness (it was rebuilt through current code mid-session); its raw-scale baseline is recoverable from the stored `consumption` variable if ever needed.
All other 33 cells were compared against genuine stale copies.
