# Base fix: step-by-step instructions

## Step 1: `0_programs.do` — modify `run_grc`

### 1a. Replace the syntax line (line 1555)

**Find:**
```stata
    syntax , estname(string) switcherpars(string) base(numlist)  balance(string) [covars(varlist) iterate(numlist) initial(string)]
```

**Replace with:**
```stata
    syntax , estname(string) base(numlist) switchers(numlist) balance(string) [covars(varlist) iterate(numlist) initial(string)]
```

### 1b. Replace the covarlist block (lines 1557--1559)

**Find:**
```stata
    * Construct the covariates string for the regression and instruments
		local covarlist `covars'
		local covarlist "`covars' unbalanced unbalanced_choice"
```

**Replace with:**
```stata
    * Construct the covariates string for the regression and instruments
    if "`balance'" == "unb" {
        local covarlist "`covars' unbalanced unbalanced_choice"
    }
    else {
        local covarlist "`covars'"
    }
```

### 1c. Replace the switcher_traj loop (lines 1564--1567)

**Find:**
```stata
		* Loop through switchers and add them to local
		foreach s of numlist $switchers {
			local switcher_traj	"`switcher_traj' switcher_`s'"
		}
```

**Replace with:**
```stata
    * Loop through switchers and add them to local
    foreach s of numlist `switchers' {
        local switcher_traj "`switcher_traj' switcher_`s'"
    }

    * Build switcherpars internally — guarantees same base everywhere
    define_switcherpars, switchers(`switchers') base(`base')
    local switcherpars `r(switcherpars)'
    di as text "run_grc: base trajectory = `base'"
```

### 1d. Replace `$switchers` with `` `switchers' `` in four more places

**Line 1588:** `local s0 : word 1 of $switchers` → `local s0 : word 1 of `switchers'`

**Line 1590:** `foreach s of numlist $switchers {` → `foreach s of numlist `switchers' {`

**Line 1627:** `foreach s of numlist $switchers {` → `foreach s of numlist `switchers' {`

**Line 1633:** `local s0 : word 1 of $switchers` → `local s0 : word 1 of `switchers'`

**Line 1649:** `foreach s of numlist $switchers {` → `foreach s of numlist `switchers' {`

---

## Step 2: All GRC do-files — update call sites

The same two edits at every call site in every file listed below.

### 2a. Delete the `define_switcherpars` block

Wherever you see this pattern (2 or 4 lines), delete all of it:

```stata
define_switcherpars, switchers($switchers) base(2)
local switcherpars `r(switcherpars)'
```

If there's also an alt-base version, delete that too:

```stata
define_switcherpars, switchers($switchers) base(3)
local switcherpars_alt `r(switcherpars)'
```

### 2b. In every `run_grc` call, replace `switcherpars(...)` with `switchers($switchers)`

**Find (standard calls):**
```stata
    switcherpars("`switcherpars'") base(`base') initial(`initial') ///
```

**Replace with:**
```stata
    switchers($switchers) base(`base') initial(`initial') ///
```

**Find (alt-base robustness calls that used `switcherpars_alt`):**
```stata
    switcherpars("`switcherpars_alt'") base(`base') initial(`initial') ///
```

**Replace with (note: base changes to match the alt):**
```stata
    switchers($switchers) base(3) initial(`initial') ///
```

(Use `base(4)` if the original `switcherpars_alt` was built with `base(4)`.)

---

## Files and locations

| File | Lines to edit |
|------|--------------|
| `0_programs.do` | 1555, 1557--1559, 1564--1567, 1588, 1590, 1627, 1633, 1649 |
| `5_GrRC.do` | 88--89, 97, 103, 110, 117, 124, 164--167, 175, 181, etc. |
| `6_GrRC_NonAg.do` | 87--88, all `run_grc` calls |
| `8_GrRC_hukou.do` | All `define_switcherpars` + `run_grc` calls |
| `10_GrRC_experience.do` | All `define_switcherpars` + `run_grc` calls |
| `11_GrRC_max_experience.do` | Same pattern |
| `12_GrRC_experience_share.do` | Same pattern |
| `13_GrRC_max_experience_share.do` | Same pattern |
| `14_GrRC_NonAg_experience.do` | Same pattern |
| `15_GrRC_birth.do` | Same pattern |
| `16_heterogeneity_tables.do` | Same pattern |

### Quick way to find all locations

Search for `switcherpars` across all do-files. Every hit is a line that needs editing:
- `define_switcherpars` lines → delete
- `local switcherpars` lines → delete
- `switcherpars("` in `run_grc` calls → replace with `switchers($switchers)`
