Subject: A few questions on the real-values data prep

Hi David,

I've been poking around the real-values construction and I think there are a few things worth sorting out.
None of this affects the headline numbers we use in the paper --- we never actually look at the food / non-food split --- but I'd like to clean the code up before we build anything else around it, and a couple of points are genuinely worth a fix.

## 1. TZA: `consfood` is nominal inside the "real values" file

In `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\Replication LMMVW\260301 Variable selection TZA real values_DB.do`:

- Line 66 keeps `consumption_real` (real) and `food` (nominal) side by side from the LMMVW upstream file.
- Line 136 renames `consumption_real` to `consumption` (labeled real on line 137).
- Line 145 renames `food` to `consfood`, and line 146 explicitly labels it `"nominal annual consumption of food items"`.
- Line 148 then computes `consnonfood = consumption - consfood`, i.e., real minus nominal --- so `consnonfood` is neither nominal nor real.

LMMVW's own `TZA_01A_consumption.do` at line 37 does `rename (foodbev foodbevR) (food food_real)`, so a real food series already exists in their intermediate file.
Should we just pick up `food_real` on line 66 of `260301` instead of `food`, rename it to `consfood`, and then compute `consnonfood = consumption - consfood`?

## 2. CHN: `consfood` and `consnonfood` are also nominal in `CHN_real.dta`

In `C:\Users\maand\Dropbox (Personal)\Returns to migration\Data\260302 Data preparation real values_DB.do`, lines 589--593 apply the Brandt-Holz spatial deflator to `consumption` and `income` but not to `consfood` or `consnonfood`.
LMMVW's `CHN_01A_consumption.do` doesn't publish a real food series for China, so we can't pick one up like we can for TZA.
But the Brandt-Holz deflator is a scalar price index --- it should apply to food the same way it applies to total consumption.
Can we add two more deflation steps after 593 for `consfood` and `consnonfood`?

## 3. IDN: same pattern --- consfood / consnonfood never deflated

Same file, lines 259 and 262 deflate only `consumption` and `income`.
Our BPS-based spatial deflator should apply to food too.
Two more lines after 262 for `consfood` and `consnonfood`?

## 4. Please don't `replace` variables in place

Lines 259, 262, 589, and 592 all do things like `replace consumption = consumption / deflator`.
I'd really prefer we not overwrite variables like this.
Two reasons: if someone re-runs the script inside a single Stata session the deflation gets applied twice, and once the `replace` has run, the nominal value is gone from the dataset so we can't audit or spot-check.

Could we switch to `gen consumption_real = consumption / deflator` (and use `consumption_real` downstream) instead?
I tell my students never to use `replace` for this reason, so I'd like us to hold ourselves to the same standard.

## 5. Base years --- intentional?

We end up with three different base years across the countries:

- IDN: 2014 (matches the paper --- `CPI_2014` in our deflator formula)
- CHN: 1990 (inherited from Brandt-Holz)
- TZA: LSMS per-wave deflators (so not a single base year at all)

This seems fine as long as each country uses its own literature standard, and we're not comparing levels across countries directly.
But can you confirm it's intentional, and that there's nothing in the code that implicitly assumes a common base?
The TZA per-wave deflator is what's making the TZA real/nominal ratio non-monotone across years, which caught my eye while I was checking all this.

Happy to chat through any of it whenever works.

Thanks,
Emilia
