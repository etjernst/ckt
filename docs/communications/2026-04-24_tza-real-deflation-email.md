Subject: TZA consumption --- two issues with how we deflate

Hi David,

I've been tracing through the TZA consumption pipeline and found two separate issues we should fix.
First, the variable we use in the main analysis is not actually spatially adjusted, even though our paper text says we use NPS's spatial deflator.
Second, what we call "real" for TZA in the robustness is methodologically different from what we call "real" for IDN and CHN --- TZA is space-adjusted but not inflation-adjusted across waves.
I'm going to fix the first one by revising the main text (see below), but the second one needs a code change.

## Terminology

Throughout this email I'll use "nominal" and "real" in the usual economics sense --- "real" means adjusted for inflation over time.
I'll say "spatially adjusted" separately to mean adjusted for price-level differences across regions or urban/rural.
A variable can be spatially adjusted without being real, and vice versa.
This matters because NPS's `expmR` is both spatially adjusted AND deflated for inflation within a single wave (via the Fisher index), but **not** deflated across waves --- each wave's `expmR` lives in that wave's own prices.

## Issue 1: main-analysis TZA consumption is not spatially adjusted

### What the paper says

The TZA data section currently says:

> "NPS already uses a spatial price deflator in their data to account for different price levels between rural and urban areas. As we did for the Chinese data, we directly use the NPS replication data provided by Lagakos 2020."

Reading that, you'd expect our main-analysis TZA consumption to be NPS's spatially adjusted aggregate.

### What the code actually does

The main-analysis `TZA.dta` in `ReplicationPackage6\data\countries\` picks up NPS's nominal total expenditure (`expm`), not its spatially adjusted aggregate (`expmR`).
Here's the chain:

1. LMMVW's build script `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\Replication LMMVW\JME-Migration-Costs-2020-main\Code\Build\Scripts\TZA_01A_consumption.do`, line 36:
   ```stata
   rename (expm expmR) (consumption consumption_real)
   ```
   So both `consumption` (= NPS nominal `expm`) and `consumption_real` (= NPS spatially adjusted `expmR`) are available in `tza_panel.dta`.
2. Your `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\Replication LMMVW\230328 Variable selection_DB_MK.do`, TZA block starting line 295.
   Line 321 picks up the nominal one:
   ```stata
   keep pid wave isic_primary urban any_ag switcher age female educ district ward region year hhsize nadult consumption earnings hours food earn_primary earn_self
   ```
   And line 391 labels it:
   ```stata
   lab var consumption "nominal annual consumption"
   ```
3. The file saves as `Panel_LMMVW_TZA.dta` (line 413), and `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\250314 Data preparation_DB.do` passes `consumption` through unchanged into the final `TZA.dta` used for the main analysis.

So the main-analysis `consumption` for TZA is NPS's nominal `expm`.
No spatial adjustment, no temporal adjustment.

### How I verified

I row-aligned the nominal `TZA.dta` against the real `TZA.dta` by `(pid, year)` and computed the ratio `consumption_real / consumption_nominal`.
If the nominal file were already using the spatial deflator, those ratios would reflect only whatever additional temporal layer the real file adds.
The ratios are 1.04 (2009), 1.01 (2011), 1.06 (2013) --- which is consistent with the real file adding NPS's spatial+within-wave Fisher adjustment on top of something that's pure nominal.

### How to fix, and what I'm planning to do

Two options:

**Option A (revise paper text, no code change).**
I'll revise the main text to clarify that the main analysis uses nominal values and that NPS's spatial deflator is applied only in the real-values robustness check.
This matches what the code already does.
This is my plan.

**Option B (update code to match the current paper text).**
If we'd rather the main analysis use the spatially adjusted aggregate, the change is small:

- `230328 Variable selection_DB_MK.do` line 321: swap `consumption` for `consumption_real` in the `keep` list.
- Immediately after the existing renames in the TZA block (around line 391), add:
  ```stata
  rename consumption_real consumption
  lab var consumption "spatially adjusted annual consumption (NPS Fisher, within-wave base)"
  ```
- Replace the existing label on line 391 accordingly.

Flagging Option B just so you're aware it's easy if we decide to go that route.
If you'd rather we do B, let me know and I'll hold off on the text revision.

## Issue 2: our TZA "real" is not the same as our IDN and CHN "real"

### What each country's "real" actually captures

For **IDN** (`C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\260302 Data preparation real values_DB.do` lines 246--265):

- Import a spatial deflator that varies by `prov × period × urban`.
- Merge m:1 on those three keys, so the deflator column already captures variation across both space and time.
- Apply `consumption / deflator` and `income / deflator`.
- Result: both consumption and income are deflated for space and for inflation across waves, same base.

For **CHN** (same file, lines 576--600): same structure --- Brandt-Holz spatial deflator with `provcd × year × urban` variation, space + cross-wave inflation applied consistently to both consumption and income.

For **TZA** (`C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\Replication LMMVW\260301 Variable selection TZA real values_DB.do` line 66):

```stata
keep pid wave isic_primary urban any_ag switcher age female educ district ward region year hhsize nadult consumption_real logearnings_real hours food earn_primary earn_self
```

- `consumption_real` is NPS's `expmR` passed through.
  This uses NPS's Fisher deflator (`fisherb4c4`), which adjusts for spatial price differences across areas (Dar es Salaam / Other Urban / Rural / Zanzibar) and for temporal price differences across the quarters of the survey fieldwork window.
  Per the NPS documentation, the Fisher base is the same wave as the consumption file --- Wave 5's `expmR` is in 2020/21 prices, Wave 4's in 2014/15 prices, and so on.
  **So `expmR` does not adjust for inflation across waves.**
- `logearnings_real` is LMMVW's own construction at `TZA_02_panel.do` lines 132--138, using the national Tanzania CPI with 2013 base:
  ```stata
  sum CPI_tanzania if year == 2013
  local base = r(mean)
  gen logearnings_real = ln(earnings * `base' / CPI_tanzania)
  ```
  This is purely temporal, no spatial adjustment.

So inside the same TZA real file, consumption has spatial + within-wave time adjustment (but no cross-wave inflation adjustment), and income has cross-wave inflation adjustment (but no spatial adjustment).
Different dimensions adjusted for each variable, neither matching IDN or CHN.

### Empirical signature

This is visible in the real/nominal ratios by year:

- `income`: 1.50 (2009), 1.25 (2011), 1.00 (2013).
  Monotone, hits 1.0 at 2013 --- the classic CPI-to-2013-base pattern.
- `consumption`: 1.04 (2009), 1.01 (2011), 1.06 (2013).
  Close to 1 and non-monotone, because the Fisher deflator puts each wave's consumption in that wave's own prices with no bridge between waves.

### How to fix

Layer LMMVW's national-CPI-to-2013 adjustment on top of NPS's `expmR`.
`CPI_tanzania` is already in `tza_panel.dta` (LMMVW merges it at `TZA_02_panel.do` line 113), so nothing new needs to be merged.

Step-by-step in `260301 Variable selection TZA real values_DB.do`:

1. **Line 66**: add `CPI_tanzania` to the `keep` list.
2. **Line 136**: replace `rename consumption_real consumption` with:
   ```stata
   * expmR (renamed to consumption_real upstream) is spatially adjusted and
   * Fisher-deflated within wave, but each wave is in that wave's own prices.
   * Layer LMMVW's national CPI to a 2013 base so that cross-wave comparisons
   * are in common prices and the variable matches what we do for IDN and CHN.
   sum CPI_tanzania if year == 2013
   local base = r(mean)
   gen consumption = consumption_real * `base' / CPI_tanzania
   lab var consumption "real annual consumption (NPS spatial + Fisher within-wave + CPI to 2013 base)"
   drop consumption_real
   ```
3. Add a sanity-check line right after:
   ```stata
   tabstat consumption, by(year) statistics(mean p50 count)
   ```
   After the fix, real/nominal consumption ratios by year should be monotone and hit 1.0 at 2013, matching what income already does.

Nothing else in `260301` or `260302` needs to change for this fix.

### One thing to confirm before applying

The NPS documentation I'm working from is for Wave 5 specifically.
It says the Fisher base is Wave 5 (2020/21 prices), so `expmR` is within-wave.
I'm assuming the same structure holds for Waves 1--3 that we use --- Wave 1's `expmR` in 2009 prices, Wave 2 in 2011 prices, Wave 3 in 2013 prices.
If NPS used a common Fisher base across Waves 1--3 (say all three in 2013 prices), then `expmR` would already be cross-wave comparable and the CPI layer would double-count.
Can you confirm the Fisher base structure for Waves 1--3 before applying the fix?

## One related cleanup --- food / non-food in the real file

`consfood` and `consnonfood` in the real TZA file are still nominal.
`260301` line 66 picks up nominal `food` rather than `food_real` (LMMVW renames `foodbevR` to `food_real` at `TZA_01A_consumption.do` line 37, so it's available in the same panel).
We don't decompose consumption into food vs non-food anywhere in the paper, so this doesn't affect any result, but it makes the file labels misleading.

If we're touching the TZA real pipeline anyway, while you're in there:

- Line 66: swap `food` for `food_real` in the `keep`.
- Line 145: rename `food_real` to `consfood` instead of `food`.
- Line 146: update the label to say `spatially adjusted within-wave` rather than `nominal` (and apply the CPI layer from Issue 2 if we want fully real food too).
- Line 148: `consnonfood = consumption - consfood` stays, but now both sides are on the same deflation basis.

Happy to chat through any of this on a call.

Thanks,
Emilia
