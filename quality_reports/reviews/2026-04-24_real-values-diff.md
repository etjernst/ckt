# Nominal vs real-values fork: what actually differs

Feeder review for the GRC pipeline refactor spec.
Compares `ReplicationPackage6/scripts/` (nominal, authoritative, 2026-04-24 mtime) against `ReplicationPackage6 - real values/scripts/` (real, 2026-04-01 mtime), and the corresponding `data/countries/*.dta` files.

## Headline

Of the 22 `.do` files in each fork, **only two differ**: `0_master.do` (path strings) and `0_programs.do` (stale snapshot).
The "real values" fork is not a parallel pipeline --- it is effectively the same scripts pointing at a different data folder.

On the data side, **only two columns differ row-for-row** in each country file: `consumption` and `income` (plus `consnonfood` in TZA, which looks like an oversight rather than intent).
Every other numeric variable --- including `cons_tot_real`, `cons_food_real`, `cons_nfood_real`, `inc_real`, and `inc_h_real` --- is byte-identical across forks.
The real-values data was regenerated upstream with a different deflator applied to `consumption` and `income`; the rest of the schema was copied as-is.

This means a `values(nominal|real)` switch does not need any in-pipeline deflation logic --- it just needs to point `$dirdata` at a different folder.

## Files present in only one fork

None.
Both `scripts/` folders contain the same 22 `.do` files.

## File-by-file semantic diffs

### `0_master.do` --- bookkeeping only

Four lines differ (31, 32, 37, 42), all path strings appending `" - real values"` to the `$dir` folder for Marieke, David, and Eduardo.
Emilia's blocks are identical.
The `do` include list is line-for-line the same across forks.

Classification: **Path / filename.**

### `0_programs.do` --- pure drift, no nominal-vs-real logic

Nominal: 2884 lines, 133 648 bytes.
Real: 2154 lines, 95 299 bytes.
The real-values copy is a strictly older snapshot (2026-04-01 vs 2026-04-24).

Every program shared by both is line-for-line identical.
Verified identical: `use_data`, `handle_choice`, `handle_depvar`, `set_covariates`, `fix_varlabels`, `define_switcherpars`, `initial_values`.

The ~730 extra lines in nominal are five programs absent from the real-values fork:

- `gen_vfirst` (vfirst cluster index for robust spec)
- `initial_values_robust`
- `run_grc_onestep`
- `run_grc_robust` (Verdier 2020 Section F)
- `run_grc_robust_vv`

Plus one in-place edit: `run_grc` in nominal gained a `phistart(real -1)` option (line 1692) and replaced hardcoded `{phi=-1}` with `{phi=`phistart'}` (line 1721).
The real-values fork still has hardcoded $\phi_{\text{start}} = -1$.

Classification: **Bugs / inconsistencies (one-way drift).**
None of the drift touches nominal-vs-real semantics --- the real fork simply missed the robust-spec additions.

## The deflation step

There is none in the scripts.

- `use_data` is identical in both forks: `use "$dirdata/countries/`country'", clear`.
- `handle_depvar` takes `consumption` / `income` as-is and does `gen lndepvar = ln(depvar)`.
- `1_processData.do` has zero hits on `real`, `deflat`, `cpi`, `price`.
- Real-values `0_programs.do` has zero hits on `real`, `deflat`, `cpi`, `lcu`, `price index`.

The deflator is applied upstream of this replication package, before the `.dta` files are built.

## Empirical comparison of the data files

Verified 2026-04-24 by row-aligning each country's nominal vs real `.dta` on `(pid, year)` and diffing column-by-column.

### IDN

Shape identical: 118 828 rows, 53 columns.

Only two numeric columns differ: `consumption` and `income`.
The 51 other numeric columns (including `cons_tot_real`, `cons_food_real`, `cons_nfood_real`, `inc_real`, `inc_h_real`, `consfood`, `consnonfood`, all household-size transforms, `exp*`, geography, education) are byte-identical.

Real/nominal consumption ratio by year (median):

| Year | 1993 | 1997 | 1998 | 2000 | 2007 | 2008 | 2014 | 2015 |
|------|------|------|------|------|------|------|------|------|
| ratio| 9.53 | 9.28 | 9.28 | 4.71 | 2.33 | 2.26 | 1.56 | 1.56 |

The monotone pattern is consistent with a CPI-style deflation to a modern base year; earlier years' "real" values are larger because Indonesian rupiah lost purchasing power over 1993--2015.
Note that `cons_tot_real` in both forks has mean $\approx$ 219 863 and median 153 743, while the real fork's overwritten `consumption` has mean 866 561 and median 566 060.
So the real fork's `consumption` is a **different** real series than the already-present `cons_tot_real` --- different base year or different index.

### CHN

Shape identical: 143 252 rows, 39 columns.

Only `consumption` and `income` differ.

Real/nominal ratio by year (median):

| Year | 2010 | 2012 | 2014 | 2016 |
|------|------|------|------|------|
| cons | 0.97 | 0.91 | 0.86 | 0.83 |
| inc  | 0.97 | 0.89 | 0.85 | 0.82 |

Ratio $\approx$ 1 in 2010 and falls monotonically; this matches deflation to a 2010-RMB base year.

### TZA

Shape identical: 34 598 rows, 42 columns.

**Three** columns differ: `consumption`, `income`, and `consnonfood`.
`consfood` and `cons_tot_real` are identical, which is inconsistent --- if the real fork recomputed `consumption` from scratch it should have touched food as well.
Best explanation: the upstream data-build for TZA "real" regenerated `consnonfood` but then `consumption = consfood + consnonfood` was recomputed while `consfood` was left nominal.
Severity: **MINOR** if the paper only uses `consumption` or `cons_tot_real`; worth a one-line check with the coauthor.

Real/nominal ratio by year (median):

| Year | 2009 | 2011 | 2013 |
|------|------|------|------|
| cons | 1.04 | 1.01 | 1.06 |
| inc  | 1.50 | 1.25 | 1.00 |

Consumption base year for TZA is 2011; income base year is 2013.
The two base years differ within the same file, which is an odd choice worth verifying with coauthors.

## Data dependencies unique to real-values

None at the filename level.
Both `data/countries/` folders contain the same seven files: `CHN.dta`, `CHN_hukou_{rural_first,rural_only,urban_first,urban_only}.dta`, `IDN.dta`, `TZA.dta`.
No CPI, deflator, or price-index file is referenced in either tree.
The deflation machinery lives in whatever upstream pipeline produces the country-level `.dta` files --- it is outside this replication package and not currently surfaced in the repo.

## Upstream bug: TZA `consumption`, `consfood`, `consnonfood`

Confirmed by direct inspection of the upstream producer script on 2026-04-24.

**File:** `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\Replication LMMVW\260301 Variable selection TZA real values_DB.do` (authored by David Buller).

The script keeps both a real total and a nominal food series from the same upstream `.dta`, then renames them such that `consumption` is real while `consfood` is nominal, and computes `consnonfood` as their difference:

| Line | Code | Problem |
|---|---|---|
| 66 | `keep pid wave ... consumption_real ... food ...` | Keeps real total and nominal food side-by-side. |
| 136 | `rename consumption_real consumption` | Real total becomes `consumption`. |
| 137 | `lab var consumption "real annual consumption"` | Correctly labeled. |
| 145 | `rename food consfood` | Nominal food becomes `consfood`. |
| 146 | `lab var consfood "nominal annual consumption of food items"` | Label explicitly says nominal inside a real-values file. |
| 148 | `g consnonfood = consumption - consfood` | Mixes real total with nominal food --- uninterpretable. |
| 149 | `lab var consnonfood "nominal annual consumption of non-food items"` | Label is also wrong --- the quantity is neither purely nominal nor purely real. |

Severity: **MAJOR.**
`consumption` is usable; `consfood` and `consnonfood` are not interpretable as real-values quantities.
Any paper exhibit that decomposes real consumption into food and non-food for TZA is affected.

This exactly reproduces the observed diff pattern (`consumption` and `consnonfood` differ row-for-row, `consfood` byte-identical to nominal, TZA consumption ratios non-monotone).

The suspected CHN analogue in `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\260302 Data preparation real values_DB.do` is under separate investigation.

## Implications for the refactor

- A `values(nominal|real)` switch controls **zero estimation code**.
  It just routes `$dirdata/countries/` to the right folder.
  Everything downstream is agnostic.
- Cleanest location for the switch: `0_path_config.do`.
  Define `global values "nominal"`, let `$dirdata` resolve to a nominal or real data folder accordingly.
  No changes to `0_programs.do`, `1_processData.do`, or any numbered script.
- Append `_${values}` to `.ster`, CSV, and table output prefixes so nominal and real results coexist without clobbering.
- **Delete the real-values `0_programs.do` outright.**
  It is strictly an older copy, and keeping it means the real spec physically cannot run `run_grc_robust`, `run_grc_robust_vv`, `run_grc_onestep`, or `initial_values_robust`, and cannot parameterize $\phi_{\text{start}}$.
  Anyone who has been running robustness specs on real values has been using a fork that physically cannot do it --- this is a latent bug worth flagging to coauthors.
- Upstream deflation (where `consumption` and `income` become real LCU) lives **outside** this replication package.
  Surface and commit the upstream deflation script with the refactor, or at minimum document it.
  Otherwise the real-values column of the paper is not reproducible from this repo.
  Severity: **MAJOR** --- affects reproducibility of a published result.
- Keep the switch as a two-value enum.
  There is no CPI join, no base year, no country-specific deflator in-code: one global picking between two prebuilt data folders is the whole feature.
