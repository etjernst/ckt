# Plan: S1 ster scraper---results-overview layer

Status: draft, awaiting user approval.
Branch: `worktree-grc-pipeline-refactor`.
Umbrella spec: [section S1](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/specs/2026-04-24_grc-pipeline-refactor.md#s1-add-a-results-overview-layer-that-scrapes-ster-files), 2026-04-24.

## 1. Motivation

Today, GRC results pop out only as production LaTeX tables.
That makes it slow to compare headline numbers across spec tweaks---the user has to open the `.tex` file, find the relevant cell, and eyeball it.
Worse, the `_n` / `_a` / `_d` / `_g` subgroup sters (Δ_never, Δ_always, per-trajectory Δ_d, Δ_avg) only surface in the tables that aggregate them, never as a flat queryable layer.

Goal: a tidy CSV with one row per fit, queryable in pandas, that answers questions like "show me $\phi$ across covariate sets for IDN consumption/urban/unb" in seconds.
This is the pre-requisite for S1b (specification-curve figure) and a quality-of-life win for the team's own ad-hoc analysis.

## 2. What's already in place

`run_grc` already stores everything we need:

- `e(b)`, `e(V)`: full coefficient vector and covariance, including `phi:_cons`, `Delta_base:_cons`, and the trajectory-specific `Delta_*` rows.
- `e(N)`: sample size.
- `e(J)`: Hansen J statistic.
  Storage of the J p-value depends on whether it is `estadd`-ed; will confirm during Phase A.
- `e(runtime)` (via `estadd scalar runtime = r(t<slot>)` at `0_programs.do:1947`, M9 commit `1cce1e9`): GMM-fit wall-clock seconds.

The five sters per fit (main + `_n` + `_a` + `_d` + `_g`) are already written by `run_grc`'s `estimates save` block and have been since M11 (commit `ddb3886`).
1365+ such sters currently sit on disk in `RP7/output/`.

So the scraper requires zero changes to estimation code.
It is purely a read-and-report layer.

## 3. Design choices

### 3a. Reading .ster files: Stata, not Python

The spec said "read each `.ster` via `pyreadstat`."
`pyreadstat` reads `.dta` files only---it does not understand `.ster` (Stata's saved-estimates binary format).
The two real options are:

- **`pystata` (bundled module from the Stata install)**.
  Lets Python issue Stata commands (`estimates use ...`) and inspect `e()` returns.
  Works in-process; no subprocess overhead.
  The CKT memory bank explicitly says do not `pip install pystata`---use the bundled module from the Stata install (`<STATA_INSTALL>/utilities/pystata/`).
- **Stata-side dumper plus Python post-processor**.
  A `.do` file walks the sters, loads each via `estimates use`, dumps the relevant `e()` scalars and `_b[...]` values to a flat tidy CSV.
  Python then enriches the CSV with filename parsing, mtime, and git commit metadata.

**Decision: option 2 (Stata-side dumper plus Python post-processor).**

Why: the Stata side is shorter, more obviously correct, and avoids the `pystata` initialization cost on every scraper run.
The Python side can be re-run independently when only the filename parsing or git commit needs refreshing (no Stata kernel needed).
Splits cleanly along the read-vs-enrich boundary.

### 3b. One row per fit, not per ster

Each GRC fit produces five sters (main, `_n`, `_a`, `_d`, `_g`).
The CSV has one row per fit, joining the five.

The Stata dumper is a thin loop over the main sters (suffix-less `grc_<c>_<spec3>_<covs2>.ster`); for each main ster it also `estimates use` the four subgroup sters and pulls the relevant scalar (`Delta_never`, `Delta_always`, `Delta_avg`, plus per-trajectory `Delta_*` from the `_d` ster).
Output is a long-format CSV with one row per (main_stem, subgroup) plus a key column for the join, OR a wide-format CSV with one row per main_stem and columns for the subgroup point estimates.

**Decision: long format on the Stata side, wide format after the Python pivot.**

Long format keeps the Stata loop simple---one row appended per `e()` extraction.
The Python post-processor pivots on `(main_stem, subgroup)` to produce the user-facing wide table.
If long-format turns out to be more useful for downstream analysis (S1b, ad-hoc plotting), the pivot is optional.

### 3c. Old-naming filtering

75 pre-M11 orphan sters live in `RP7/output/` (see Tier 1 lint Check 6).
They use the old `urban_covs_*` / `nonag_covs_*` naming and the `_avg` / `_never` / `_always` / `_delta` suffixes.

**Decision: filter them out by glob.**

The Stata dumper iterates only over filenames matching the M11 shorthand pattern: `grc_<3>_<3>_<2or3>.ster` for the post-M11 mains.
A simple regex on the filename excludes the orphans cleanly.
Adds a 1-line filter on the Stata side; no per-file inspection needed.

### 3d. Where the artifacts live

| File | Path | Role |
|---|---|---|
| Stata dumper | `tools/scrape_grc_runs.do` | One-shot, invoked by Python wrapper. Reads sters, writes long-format CSV. |
| Python wrapper | `scripts/python/scrape_grc_runs.py` | Calls the dumper via `stata-mp -b do`, then enriches the CSV. |
| Long CSV (intermediate) | `RP7/output/overview/grc_runs_long.csv` | One row per (main_stem, subgroup). |
| Wide CSV (final) | `RP7/output/overview/grc_runs.csv` | One row per fit. |
| Companion summary tool | `scripts/python/summarize_overview.py` | Pivots the wide CSV by chosen axis. **Deferred** to a follow-up; not in scope for this plan. |

`tools/` already holds the one-shot refactor scripts (`captions_to_paper_phase1b3.py`, etc.); the Stata dumper fits there.
`scripts/python/` is the standard CKT location for analysis-side Python.

### 3e. Schema (final wide CSV)

| Column | Source | Type | Notes |
|---|---|---|---|
| `main_stem` | filename | str | e.g. `grc_IDN_cuu_ca` |
| `country` | filename parse | str | CHN / IDN / TZA |
| `spec3` | filename parse | str | cuu / cub / iuu / cnu |
| `covs2` | filename parse | str | c0 / ct / c1 / c2 / ca |
| `family` | filename parse | str | "" / exp / maxexp / expsh / maxexpsh / birth |
| `values` | filename parse | str | nominal / real (parsed from `_r` suffix on M4 outputs) |
| `depvar` | spec3 decode | str | consumption / income |
| `choice` | spec3 decode | str | urban / nonag |
| `balance` | spec3 decode | str | bal / unb |
| `covariates` | covs2 decode | str | covs_0 / covs_trend / covs_1 / covs_2 / covs_all |
| `beta` | main ster, `_b[Delta_base:_cons]` | float | |
| `phi` | main ster, `_b[phi:_cons]` | float | |
| `phi_se` | main ster, `_se[phi:_cons]` | float | |
| `delta_never` | `_n` ster, `_b[Delta_never]` | float | |
| `delta_always` | `_a` ster, `_b[Delta_always]` | float | |
| `delta_avg` | `_g` ster, `_b[Delta_avg]` | float | |
| `delta_d0` | `_d` ster, baseline switcher's `_b[Delta_d0]` (or whichever name) | float | exact param name TBD in Phase A |
| `N` | main ster, `e(N)` | int | |
| `J_stat` | main ster, `e(J)` | float | Hansen J. |
| `J_pval` | main ster, derived from `e(J)` and `e(rank_S)` if not directly stored | float | Confirm storage; may need `chi2tail` post-hoc. |
| `runtime_s` | main ster, `e(runtime)` | float | M9 timer; blank if pre-M9. |
| `ster_mtime` | filesystem | datetime | mtime of the main ster. |
| `commit` | `git rev-parse HEAD` | str | At scrape time. |

20 columns.
Adding columns later is free; the CSV is regenerated on every scrape.

## 4. Implementation phases

### Phase A: Stata dumper

1. Write `tools/scrape_grc_runs.do`:
   - Walks `$dir/output/` for filenames matching `grc_*_*_*.ster` (post-M11 mains).
   - Excludes anything ending in `_n.ster`, `_a.ster`, `_d.ster`, `_g.ster` (those are the subgroup sters; we read them as a group with their main).
   - Excludes anything matching `*_always.ster` etc. (pre-M11 orphans).
   - For each main ster, opens it via `estimates use`, extracts `e(b)`, `e(V)`, `e(N)`, `e(J)`, `e(runtime)`.
   - Then opens the four subgroup sters, extracts the relevant `_b[...]` value.
   - Writes one row per (main_stem, subgroup) to `RP7/output/overview/grc_runs_long.csv`.
2. Verify against 3 known sters by hand (e.g. `grc_IDN_cuu_ca`).
3. Confirm the `delta_d0` parameter name (`_d` ster has per-trajectory deltas; need to know which one is the baseline switcher).

### Phase B: Python wrapper

1. Write `scripts/python/scrape_grc_runs.py`:
   - Subprocess `stata-mp -b do tools/scrape_grc_runs.do`.
   - Read `RP7/output/overview/grc_runs_long.csv` into pandas.
   - Pivot to wide format (one row per main_stem).
   - Parse filename into country / spec3 / covs2 / family / values columns.
   - Decode spec3 / covs2 into the human-readable depvar / choice / balance / covariates columns.
   - Add `ster_mtime` (from `Path.stat().st_mtime`) and `commit` (from `git rev-parse HEAD`).
   - Write the wide CSV to `RP7/output/overview/grc_runs.csv`.
2. Verify column counts and dtypes; spot-check a handful of rows against the underlying sters.

### Phase C: Documentation

1. Add a brief usage note to `tests/README.md` or a new `RP7/output/overview/README.md`.
2. If the team uses it, add an entry to CLAUDE.md's "commands" section.

## 5. Verification

Tier 1: filename parser unit tests for all 4 spec3 codes plus the family extension.
Tier 2: spot-check 5--10 rows against `estimates use ...; di e(N)` in an interactive Stata session.
Tier 3: run on the post-Tier-3 #6 ster set, count rows; should match `45 + 12 + 44 = 101` cells per the spec's expected stem count, give or take any scripts that did not converge.

## 6. Effort estimate

- Phase A: half a day (Stata loop + verification).
- Phase B: half a day (Python pivot + filename parsing).
- Phase C: an hour.
- Total: roughly 1 working day.

## 7. Out of scope

- S1b specification-curve figure.
- S1c adding $\Delta_{\text{always}}$ to the main GRC LaTeX tables.
- Live updates---the scraper runs on demand, not as part of `_smoke_full.do`.
- pre-M11 orphan sters (filtered out; user has separately decided to address those via `RP7/output/` cleanup before merge).

## 8. Open questions for the user

- **Wide vs long-format final output.**
  The plan says "wide CSV is the user-facing format, long CSV is intermediate."
  The user might prefer the long format end-to-end (one row per ster, easier for S1b downstream).
  Decide before Phase B.
- **Where does the wrapper live?**
  Spec says `scripts/python/scrape_grc_runs.py`.
  CKT also has `tools/` and `explorations/`.
  Confirm `scripts/python/` is correct.
- **Subprocess vs pystata.**
  The plan uses `stata-mp -b` subprocess for portability.
  If the user prefers in-process pystata for speed, switch to that.
  Functional equivalent; only difference is the Python wrapper's invocation pattern.
- **Should the scraper also catch the deferred S1c addition (Δ_always row in tables)?**
  Currently scope is read-only.
  If S1c lands in this same PR cycle, the scraper schema is unchanged but the table-builder output will include a new row, which Tier 2 byte-identity flags as `UNEXPECTED`.
  Either gate S1c behind a separate PR or refresh the Tier 0 reference after S1c lands.

with Claude
