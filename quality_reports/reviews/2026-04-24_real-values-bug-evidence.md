# Real-values bug evidence: food variables and base years

Evidence gathered 2026-04-24 in read-only mode from the Dropbox replication folders.
All paths below are under `C:/Users/maand/Dropbox (Personal)/Returns to migration/`.
Line numbers refer to the current state of each script.

## Task 1: Does `food_real` exist in LMMVW upstream?

**Short answer:** Yes for TZA; no for CHN; not applicable for IDN (which is HKLM not LMMVW, and already has `cons_food_real`).

### TZA (LMMVW): `food_real` exists upstream

The LMMVW build script that produces `tza_panel.dta` creates `food_real` explicitly.

`Data/Replication LMMVW/JME-Migration-Costs-2020-main/Code/Build/Scripts/TZA_01A_consumption.do`, lines 33-48 (inside program `consumpagg`):

```stata
program define consumpagg

    rename (expm expmR) (consumption consumption_real)
    rename (foodbev foodbevR) (food food_real)

    keep *hhid* mainland food health educa consumption *_real hhsize adulteq region urban

    gen food_share = food / consumption
    label variable food_share "Proportion of total consumption spent on food and non-alc beverages, annual"

    foreach var in food food_real consumption consumption_real {
        gen `var'_ae = `var' / adulteq
        gen log`var' = ln(`var')
        gen log`var'_ae = ln(`var'_ae)
    }
```

The program is called on waves 1-3 (lines 78-102) and saves `wave{1,2,3}_consumption.dta`. `TZA_02_panel.do` lines 62, 76, 90 merge each wave's consumption file into the panel via `merge m:1 hhid using "${TZAbuild}/intermediate/wave{1,2,3}_consumption.dta", nogen`, so `food_real` survives into `tza_panel.dta` (the file DB uses at line 43 of `260301 Variable selection TZA real values_DB.do`).

The source variables `expm/expmR` and `foodbev/foodbevR` are LSMS-ISA-provided nominal/real aggregates from the Tanzania NPS waves — LSMS's own spatial+temporal deflator is already baked into the `R`-suffixed versions.

### CHN (LMMVW): `food_real` does NOT exist upstream

`Data/Replication LMMVW/JME-Migration-Costs-2020-main/Code/Build/Scripts/CHN_01A_consumption.do` keeps only nominal `food` from `CFPS_familyecon_{2010,2012,2014,2016}.dta`. All four waves are symmetric:

```stata
use "${CHNraw}/2010/CFPS_familyecon_2010.dta", clear
keep fid expense food familysize
rename expense consumption
...
```

Nowhere in `CHN_01A_consumption.do` or `CHN_02_panel.do` does a `food_real`, `foodR`, `food_deflated`, or equivalent get constructed. A grep across all LMMVW build scripts confirms `food_real`/`foodbev` only appear in the TZA build. The closest thing CHN has is the raw nominal `food`.

### IDN (HKLM, not LMMVW): `cons_food_real` exists upstream

IDN runs through the HKLM pipeline, not LMMVW. `Data/Replication HKLM/Do-files/2. Creation of IFLS replication data.do` lines 147-149 already labels `cons_tot_real`, `cons_food_real`, `cons_nfood_real` as real. These are produced upstream by HKLM using the Indonesia spatial deflator (see Task 2), and land in `Intergen_Analysis_IFLS.dta`.

## Task 2: The spatial deflator --- can it be applied to `food`?

**Short answer:** Yes, trivially, for IDN and CHN (single multiplicative divisor, already merged onto the panel). For TZA there is no explicit spatial deflator in Emilia's code path --- `food_real` is already provided by LSMS and just needs to be kept instead of being replaced.

### IDN (260302, lines 246-265)

```stata
* import spatial deflators
import excel "$dirdata/Spatial deflator/Indonesia/Processed Indonesia CPI data.xlsx", sheet("Final deflators") firstrow clear

tempfile IDN_deflators
save `IDN_deflators', replace

* merge in spatial deflators
use `IDN_temp', replace

merge m:1 prov period urban using `IDN_deflators', keepusing(prov period urban deflator)
drop if _merge == 2
drop _merge

replace consumption = consumption / deflator
lab var consumption "Real consumption"

replace income = income / deflator
lab var income "Real income"

drop deflator
```

The deflator is a single scalar column `deflator` merged m:1 on `(prov, period, urban)`. It is applied multiplicatively (`var = var / deflator`). Extending to `consfood` and `consnonfood` would be two extra `replace ... / deflator` lines **before** the `drop deflator` at line 265. **Trivial single-line change per variable.**

That said --- upstream HKLM already produces `cons_food_real` and `cons_nfood_real` in `Intergen_Analysis_IFLS.dta`. Emilia's script at lines 235-236 renames the NOMINAL `cons_food` and `cons_nfood` to `consfood`/`consnonfood`, throwing away the already-real `_real` versions for the levels. (The log variants `lncons_food`/`lncons_nfood` are correctly pointed at the real versions via the `drop`/`rename` block at lines 141-144.) So for IDN there are two equally-clean fixes:

1. Use HKLM's `cons_food_real` and `cons_nfood_real` at lines 235-236 (mirror the consumption rename pattern); or
2. Apply the deflator to nominal `consfood`/`consnonfood` in the same block that deflates `consumption` and `income` (lines 259-263).

### CHN (260302, lines 576-595)

```stata
* import spatial deflators
import excel "$dirdata/Spatial deflator/China/Processed China CPI data.xls", sheet("Spatial deflators") firstrow clear

tempfile CHN_deflators
save `CHN_deflators', replace

* merge in spatial deflators
use `CHN_temp', replace

merge m:1 provcd year urban using `CHN_deflators', keepusing(provcd year urban deflator)
drop if _merge == 2
drop _merge

replace consumption = consumption / deflator
lab var consumption "real total family consumption"

replace income = income / deflator
lab var income "real annual personal income"

drop deflator
```

Same structure as IDN: scalar `deflator` merged m:1 on `(provcd, year, urban)`, applied multiplicatively. Applying it to `consfood` and `consnonfood` is a **single-line change per variable**, slotted before `drop deflator` at line 595. This is the **only available fix for CHN**, since upstream has no `food_real`.

### TZA (260302, lines 629-640; 260301)

There is no spatial-deflator merge in either the TZA block of `260302 Data preparation real values_DB.do` or in `260301 Variable selection TZA real values_DB.do`. `TZA_real.dta` inherits its real values from LSMS's own provided spatial deflator (baked into `consumption_real`, `food_real`, and LMMVW's `logearnings_real`). For TZA the fix is to pick up `food_real` rather than `food` at the keep step --- no new deflator merge is needed.

## Task 3: The CHN analogue

**Bug is present in CHN, with the same structure as TZA, in `230328 Variable selection_DB_MK.do`.**

### Evidence in `Data/Replication LMMVW/230328 Variable selection_DB_MK.do` (CHN block, lines 181-292)

Line 210 (keep): pulls nominal `consumption` (= CFPS `expense`) and nominal `food` only --- no `food_real` is available upstream.

```stata
keep pid wave hukou urban switcher age female educ cid provcd countyid year marriage hhsize nadult birth_province birth_county consumption earnings food
```

Lines 278-288:

```stata
lab var consumption "total family consumption"

rename earnings income
lab var income "annual personal income (from 2010)"

rename food consfood
lab var consfood "consumption of food items"

g consnonfood = consumption - consfood
lab var consnonfood "consumption of non-food items"
sum consnonfood
```

Both `consumption` and `consfood` are nominal at this stage. `consnonfood` is a clean nominal - nominal subtraction at the `Panel_LMMVW_CHN.dta` level, so it is at least internally consistent as nominal.

The bug is introduced later in `260302 Data preparation real values_DB.do`, CHN block. Line 466 loads `Panel_LMMVW_CHN.dta` (where everything is nominal). Line 589 deflates only `consumption`:

```stata
use Panel_LMMVW_CHN, clear
...
replace consumption = consumption / deflator
lab var consumption "real total family consumption"

replace income = income / deflator
lab var income "real annual personal income"

drop deflator
```

`consfood` and `consnonfood` are never touched. After the save at line 600, `CHN_real.dta` has `consumption` in real terms but `consfood` and `consnonfood` in nominal terms --- the same garbage-column condition as TZA (`consnonfood = real - nominal` would be `consumption - consfood` if you recomputed it; as stored, `consnonfood` is just the stale nominal residual from line 286).

Mirror symmetry with the TZA bug: in TZA the nominal mix happens in `260301 Variable selection TZA real values_DB.do` lines 66, 145-150; in CHN it happens across `230328 Variable selection_DB_MK.do` lines 210, 283-288 (nominal construction) and `260302 Data preparation real values_DB.do` lines 589-595 (deflator applied only to `consumption` / `income`, bypassing food components).

**CHN bug class:** same as TZA. Needs `replace consfood = consfood / deflator` and `replace consnonfood = consnonfood / deflator` inserted between lines 593 and 595 of `260302 Data preparation real values_DB.do`.

## Task 4: Base years in the construction code

**Short answer:** The different base years emerge **implicitly** from upstream data products. Emilia's code does not choose them; it inherits whatever the LSMS/HKLM/BPS/Brandt-Holz source decided. No explicit base-year logic exists in `260302 Data preparation real values_DB.do` or `260301 Variable selection TZA real values_DB.do`.

### Indonesia: base ~2015, inherited from CPI normalization

The Indonesia deflator Excel file `Data/Spatial deflator/Indonesia/Processed Indonesia CPI data.xlsx` contains four sheets. The `IFLS years CPI` sheet shows IDNCPIALLAINMEI normalized to 100 in 2015:

```
observation_date  IDNCPIALLAINMEI  IFLS
1993-01-01          12.33988          1
1997-01-01          16.80794          2
2000-01-01          33.26962          3
2008-01-01          68.87299          4
2015-01-01         100.00000          5
```

The `Final deflators` sheet holds the merged province-period-urban values. Emilia's code at `260302 Data preparation real values_DB.do` lines 247-265 simply imports this pre-built column and divides --- no normalization, no base-year choice. The 2015 base is a property of the Excel construction, not the Stata code. This matches the empirical ratio pattern (9.5 in 1993, ~1.6 in 2015).

The instructions markdown at `Data/Spatial deflator/Indonesia/Archive/indonesia_spatial_deflator_instructions.md` documents the intended base as "Urban Jakarta" (line 56) but the actual Excel file appears to have been constructed with 2015 as the temporal anchor; the two do not contradict each other --- spatial base is Urban Jakarta and temporal base is 2015.

### China: base ~2010, inherited from the Brandt-Holz or equivalent index

The China deflator Excel file `Data/Spatial deflator/China/Processed China CPI data.xls` (.xls format, could not be opened directly for inspection under current tool permissions) is imported from `sheet("Spatial deflators")` at line 577 of `260302 Data preparation real values_DB.do`. Sheet `01-import_CPI_GDPPC.do` (LMMVW) shows FRED's `CHNCPIALLAINMEI` is CPI base 2010 per the FRED convention.

The empirical ratios (0.97 in 2010 falling to 0.83 in 2016) are consistent with 2010 being the reference year used to normalize the deflator column. Emilia's code does not rescale it.

### Tanzania: no single base year; deflator is LSMS-provided

`TZA_real.dta` draws `consumption_real` and `food_real` from LMMVW's `tza_panel.dta`, which inherits them from LSMS-ISA's own `expmR` and `foodbevR` variables. LSMS-ISA applies spatial+temporal adjustments at the household level using its own deflator logic (2009 Dar-es-Salaam September prices in recent waves, but the convention has shifted across waves and between consumption and income files). The LSMS construction mixes a spatial Laspeyres index on food items with a temporal CPI, so the implicit temporal base depends on which wave you look at and which aggregate. This upstream heterogeneity is the most natural explanation for why TZA consumption ratios are not monotone (1.04, 1.01, 1.06): the deflator is a wave-specific construction, not a clean rebasing of a single price series.

`LMMVW TZA_02_panel.do` line 133 does use `sum CPI_tanzania if year == 2013 / local base = r(mean)` to define `logearnings_real`, but that quantity is separate from `consumption_real` / `food_real`, which come through `wave{1,2,3}_consumption.dta` without passing through the FRED CPI. So the 2013 base shows up only in the income/earnings real values, not in the consumption reals that Emilia uses.

### Summary: intentional vs. implicit

- No block of `260302 Data preparation real values_DB.do` picks a base year.
- No block of `260301 Variable selection TZA real values_DB.do` picks a base year.
- All base-year behavior is inherited from upstream Excel/deflator construction (IDN), upstream deflator Excel (CHN), or upstream LSMS-provided real aggregates (TZA).
- Cross-country base years are therefore not **coordinated** --- if the paper wants to report real values on a common base, Emilia would need to add a temporal-rebasing step downstream (or confirm that the reported quantities only ever appear in log-differences and ratios where base year cancels).

## Summary for the coauthor email

- **TZA fix:** in `Data/Replication LMMVW/260301 Variable selection TZA real values_DB.do`, replace `food` with `food_real` in the keep list at line 66, rename `food_real` (not `food`) to `consfood` at line 145, and update the labels at lines 146 and 149 to say "real" instead of "nominal." `food_real` is already produced by LMMVW at `TZA_01A_consumption.do:37` (`rename (foodbev foodbevR) (food food_real)`) and survives into `tza_panel.dta`. No new deflator logic is required for TZA.
- **CHN fix:** LMMVW upstream does not produce a `food_real` for China; `CHN_01A_consumption.do` keeps only nominal `food`. The spatial deflator exists in `260302 Data preparation real values_DB.do` lines 577-595 and is already merged onto the panel. The fix is to add `replace consfood = consfood / deflator` and `replace consnonfood = consnonfood / deflator` between lines 593 and 595, and update the labels. Same two-line-per-variable pattern as the existing `consumption` / `income` deflation.
- **IDN (bonus):** the same bug class exists at the level (though not the log). `260302` lines 235-236 rename the **nominal** `cons_food` / `cons_nfood` from HKLM as `consfood` / `consnonfood`, even though HKLM's `Intergen_Analysis_IFLS.dta` already carries `cons_food_real` / `cons_nfood_real`. Either rename the `_real` variants directly (mirroring the `rename cons_tot consumption` / lines 141-144 `lncons` pattern) or apply the IDN deflator to food the same way CHN will. Levels `consfood`/`consnonfood` for IDN are currently nominal; the log versions `lncons_food`/`lncons_nfood` are real.
- **Base years:** not controlled in Emilia's code. IDN inherits ~2015 from `Processed Indonesia CPI data.xlsx`. CHN inherits ~2010 from `Processed China CPI data.xls`. TZA inherits LSMS-ISA's per-wave deflator without a single base year, which is why TZA consumption ratios are not monotone. If cross-country levels matter downstream, base-year harmonization has to be added; if only logs and within-country differences matter, the existing bases cancel.
- **Questions to ask David:**
  1. For TZA, is there a reason the original `Variable selection TZA real values_DB.do` dropped `food_real` in favor of nominal `food`, or is this simply an oversight? (The label "nominal annual consumption of food items" suggests he knew it was nominal but perhaps was unaware that `food_real` was available.)
  2. For CHN, did he consider running the `Processed China CPI data.xls` deflator on `consfood` / `consnonfood`, or was the thinking that food deflation required a separate food-specific price index? (If the latter, document the decision and expose `consfood_real` only once that index is available.)
  3. For IDN, would he object to pulling `cons_food_real` / `cons_nfood_real` from HKLM rather than re-deflating nominal food using the IFLS spatial deflator? (These two routes are not numerically identical --- HKLM's real variants use the HKLM temporal deflator, while the IFLS spatial deflator we merge in covers spatial variation only.)
  4. Which base year does he want documented for each country, and does he want a downstream rebasing step so CHN, IDN, and TZA real values share a common reference year?
