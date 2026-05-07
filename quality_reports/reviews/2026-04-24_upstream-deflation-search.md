# Upstream construction of nominal and real consumption/income

The CKT replication package's Stata scripts do no deflation; they just `use` the country-level `.dta` files in `data/countries/`.
The files are built by two do-files that both live in `Dropbox (Personal)/Returns to migration/Data/` (outside the replication package).
This report maps the provenance of `consumption`, `income`, `consfood`, and `consnonfood` for each country under both the nominal and the real-values pipelines, and documents a bug in the real-values TZA construction.

## Do-files found (by country)

### Indonesia (IDN) --- nominal

Script: [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>), block "Indonesia (IDN)", ending at `save IDN, replace` (line 246).
Starts from `Intergen_Analysis_IFLS.dta` (the HKLM replication product) and keeps the nominal series `cons_tot`, `cons_food`, `cons_nfood`, `inc`, `inc_h` etc. after outlier trimming.
No CPI deflation or spatial deflator is merged in; the file is renamed `cons_tot -> consumption`, `cons_food -> consfood`, `cons_nfood -> consnonfood`, `inc -> income`, and saved as `countries/IDN.dta`.

### Indonesia (IDN) --- real

Script: [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>), block "Indonesia (IDN)", ending at `save IDN_real.dta, replace` (line 270).
Same upstream data as the nominal pipeline, but the log-transform block explicitly drops the nominal `lncons_*` and renames the `_real` versions into their places (lines 141--144: "all consumption variables are now replaced with the real equivalents"), so `consumption`, `consfood`, `consnonfood` in the saved dataset are already real when the rename to CKT naming happens.
On top of that, a spatial deflator is merged from `Spatial deflator/Indonesia/Processed Indonesia CPI data.xlsx` (sheet "Final deflators") on `prov period urban`, and applied as `consumption = consumption / deflator`, `income = income / deflator` (lines 247--265).
Base year is not stated in the do-file; the deflator table is a separate Excel file.

### China (CHN) --- nominal

Script: [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>), block "China (CHN)", ending at `save CHN, replace` (line 552).
Starts from `Panel_LMMVW_CHN.dta` (prepared by [`Data/Replication LMMVW/230328 Variable selection_DB_MK.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/Replication LMMVW/230328 Variable selection_DB_MK.do>), which keeps `consumption`, `earnings`, `food` from `chn_panel`).
No CPI merge, no deflator; just renames `earnings -> income`, creates `consnonfood = consumption - consfood`.

### China (CHN) --- real

Script: [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>), block "China (CHN)", ending at `save CHN_real.dta, replace` (line 600).
Loads the same `Panel_LMMVW_CHN.dta` the nominal pipeline uses, then merges a spatial deflator from `Spatial deflator/China/Processed China CPI data.xls` (sheet "Spatial deflators") on `provcd year urban`, and applies `consumption = consumption / deflator`, `income = income / deflator` (lines 576--595).
`consfood` and `consnonfood` are carried over unchanged from the nominal panel --- they are never deflated.
Base year is not in the do-file (stored in the CPI workbook); the observed 0.97 --> 0.83 ratio from 2010 to 2016 is consistent with a 2010-RMB base.

### Tanzania (TZA) --- nominal

Panel build script: [`Data/Replication LMMVW/230328 Variable selection_DB_MK.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/Replication LMMVW/230328 Variable selection_DB_MK.do>), block "Tanzania" (lines 295--413), which keeps the nominal `consumption`, `earnings`, `food` from `tza_panel.dta` and saves `Panel_LMMVW_TZA.dta`.
Country-file script: [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>), block "Tanzania (TZA)" (lines 580--673), ending at `save TZA.dta, replace`.
No CPI merge, no deflation; `income` is nominal from `earn_primary`, `consnonfood = consumption - consfood` is computed directly.

### Tanzania (TZA) --- real

Panel build script: [`Data/Replication LMMVW/260301 Variable selection TZA real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/Replication LMMVW/260301 Variable selection TZA real values_DB.do>) (written March 2026, author David Buller).
Saves `Panel_LMMVW_TZA_real.dta`, which is then consumed by [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>), block "Tanzania (TZA)" (lines 602--721), ending at `save TZA_real.dta, replace`.
The real panel script reads LMMVW's pre-deflated series `consumption_real` and `logearnings_real` from `tza_panel.dta`, so `consumption` and `income` come out real (base year 2013 per the observed 1.50-->1.25-->1.00 ratio on income).
No CPI file is merged inside these CKT scripts --- the deflation was done upstream by LMMVW.

## The TZA consfood/consnonfood inconsistency

The real-values TZA panel build is internally inconsistent, and this is the source of the anomaly in the user's comparison.

In [`260301 Variable selection TZA real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/Replication LMMVW/260301 Variable selection TZA real values_DB.do>):

- Line 66: `keep pid wave ... consumption_real logearnings_real hours food earn_primary earn_self`
  Note: `consumption_real` is pulled in, but the food series kept is `food` (nominal), not a `food_real`.
- Line 136: `rename consumption_real consumption` (real series now named `consumption`).
- Line 137: `lab var consumption "real annual consumption"`.
- Line 145: `rename food consfood`.
- Line 146: `lab var consfood "nominal annual consumption of food items"` (label explicitly says "nominal").
- Line 148: `g consnonfood = consumption - consfood` --- this subtracts a nominal food value from a real total.
- Line 149: `lab var consnonfood "nominal annual consumption of non-food items"` (label says "nominal" but the value is real total minus nominal food --- it is neither real nonfood nor nominal nonfood).

Consequences, which match the observed byte-level diff pattern exactly:

- `consumption` differs between the nominal and real TZA files --- yes, because one uses `consumption` and the other `consumption_real`.
- `consnonfood` differs --- yes, because it is recomputed from the new `consumption` minus the same `consfood`.
- `consfood` is byte-identical across the two files --- yes, because both pipelines rename the same nominal `food` variable without touching it.
- `consumption/consnonfood` ratio is not monotone and hovers near 1 --- yes, because `consumption_real` in LMMVW's TZA panel is already close to the nominal `consumption` in levels (the scale of the LMMVW deflator for TZA consumption is near 1), so the ratio reflects noise, not a CPI trend.

Recommended fix for the authors (for reference; no code changes made here per read-only instruction):
LMMVW's `tza_panel.dta` does not ship a `food_real` (only `food`), so a clean fix requires either applying the LMMVW TZA consumption deflator to `food` directly, or dropping `consfood`/`consnonfood` from the real-values dataset and reporting only total consumption.

## Files that produce the final `.dta` files in the replication package

Provenance map (every `save` statement reaching `data/countries/`):

| Output file | Producing script | Save line |
|---|---|---|
| `countries/IDN.dta` | [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>) | line 246 (`save IDN, replace`) |
| `countries/CHN.dta` | [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>) | line 552 (`save CHN, replace`) |
| `countries/TZA.dta` | [`Data/250314 Data preparation_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/250314 Data preparation_DB.do>) | line 673 (`save TZA.dta, replace`) |
| `countries/IDN_real.dta` | [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>) | line 270 |
| `countries/CHN_real.dta` | [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>) | line 600 |
| `countries/TZA_real.dta` | [`Data/260302 Data preparation real values_DB.do`](<C:/Users/maand/Dropbox (Personal)/Returns to migration/Data/260302 Data preparation real values_DB.do>) | line 721 |

Intermediate producers: `Panel_LMMVW_CHN.dta` and `Panel_LMMVW_TZA.dta` are built by `Data/Replication LMMVW/230328 Variable selection_DB_MK.do`; `Panel_LMMVW_TZA_real.dta` is built by `Data/Replication LMMVW/260301 Variable selection TZA real values_DB.do`.
There is no `Panel_LMMVW_CHN_real.dta` --- the CHN real values are produced by applying a CPI-workbook merge inside `260302 Data preparation real values_DB.do` itself.

## Unknowns / gaps

- The CPI base years are not written in any do-file; they live inside `Spatial deflator/Indonesia/Processed Indonesia CPI data.xlsx` and `Spatial deflator/China/Processed China CPI data.xls`.
  For IDN the base is consistent with a modern year (2014 or 2015); for CHN it is consistent with 2010.
- TZA deflation is done entirely upstream inside the LMMVW replication package (the `consumption_real`, `logearnings_real` variables in `tza_panel.dta`); the CKT scripts never see the deflator.
  The LMMVW build folder contains only `tza_panel.dta`, `tza_wave{1,2,3}.dta`, and an `intermediate/` subfolder --- the deflator construction would be in the LMMVW build scripts proper, which are not in scope here.
- No `_real` variant was found for CHN `consfood`/`consnonfood` or for TZA `consfood` --- the pipelines never deflate food-level components for any country.
  For IDN this is fine because the HKLM file ships `cons_food_real` and `cons_nfood_real` that get renamed into place; for CHN and TZA it silently propagates the nominal food series into the "real" country file.
- No Python pipeline was found outside the replication package; all data construction is Stata.
