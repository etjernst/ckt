# Headlines cache: design (revised after critic round 2)

## Goal

Cut dashboard render time from ~30+ min to seconds by caching the headline numbers per stem into a flat-file cache.
Replace per-render pystata round-trips with a single `pd.read_csv` per render.

The cache is a derived artifact, not a replacement for `.ster`.
Stata's table builders (`10_make_tables.do`, `11_make_figures.do`) still read full `e(b)`/`e(V)` from `.ster` to write the multi-row LaTeX tables.

## Note on the multi-ster structure

Each call to `run_grc` produces five ster files: one main GMM fit plus four `nlcom`-posted derived quantities (`Delta_never`, `Delta_always`, the trajectory Deltas, `Delta_avg`).
The four are separate sters because `nlcom, post` is destructive --- there is only one active `e()` slot in Stata, and saving each derived quantity preserves it for downstream commands like `test`, `lincom`, and `estimates table`.

The cache flattens this: one cache row per `(country, spec3, depvar, choice, balance, covs, family, hukou, values)` cell, with columns drawn from across the five sters.
Per-trajectory Delta_d is out of scope: the number of trajectories varies by sample, which doesn't fit a flat schema.
Any dashboard chunk that wants per-trajectory Deltas falls through to live load.

## What the cache must carry

Per stem, the dashboard reads:

| field | source ster | parameter / scalar | consumed in |
|-------|-------------|--------------------|-------------|
| `b_phi`, `se_phi` | main | `phi:_cons` | `Fit.headline()` |
| `b_delta_never`, `se_delta_never` | `_n` | `Delta_never` | `Fit.headline()` |
| `b_delta_always`, `se_delta_always` | `_a` | `Delta_always` | `Fit.headline()` |
| `b_delta_avg`, `se_delta_avg` | `_g` | `Delta_avg` | `Fit.headline()` |
| `J_p` | main | `e(Jpval)` | `comparison_table` row build |
| `N` | main | `e(N)` | `comparison_table` row build |
| `runtime_s` | main | `e(runtime)` | `comparison_table` row build |
| `converged` | main | `e(converged)` | `comparison_table` row build |

The diagnostic columns (`J_p`, `N`, `runtime_s`, `converged`) are pulled directly off `fit.main.*` in `comparison_table`, not through `Fit.headline()`.
A cache that only feeds `Fit.headline()` would still trigger a full `load_fit()` per cell to populate those four scalars and would barely move the render time.
The cache must short-circuit `load_fit()` itself --- not just `headline()`.

## Architecture

Two write paths, one read path, no separate consolidator.

### Read path (the dashboard side)

`compare.py` adds:

```python
def _load_headlines() -> pd.DataFrame:
    cache_dir = OUTPUT_DIR / "headlines"
    if not cache_dir.exists():
        return pd.DataFrame()
    manifest_path = cache_dir / "_manifest.json"
    if manifest_path.exists():
        with open(manifest_path) as f:
            mf = json.load(f)
        if mf.get("schema_version") != EXPECTED_SCHEMA_VERSION:
            logging.warning(
                "headlines cache schema mismatch: cache=%s, expected=%d. "
                "Run `python tools/results_overview/scrape_headlines.py` to regenerate.",
                mf.get("schema_version"), EXPECTED_SCHEMA_VERSION,
            )
            return pd.DataFrame()
    rows: list[pd.DataFrame] = []
    bad: list[str] = []
    for f in cache_dir.glob("*.csv"):
        try:
            rows.append(pd.read_csv(f))
        except (pd.errors.EmptyDataError, pd.errors.ParserError) as e:
            bad.append(str(f))
    if bad:
        logging.warning("skipped %d malformed cache files: %s", len(bad), bad[:5])
    if not rows:
        return pd.DataFrame()
    df = pd.concat(rows, ignore_index=True)
    logging.info("headlines cache: %d files, %d rows", len(rows), len(df))
    return df
```

No `@lru_cache`: the function is cheap (~600 small CSV reads) and re-reading on every render keeps long-lived Jupyter kernels from serving stale data.

`load_fit()` becomes cache-aware (the existing function is renamed to `_load_fit_live`, preserving its synthetic-bank fallback for `_r` stems):

```python
def load_fit(stem, output_dir=OUTPUT_DIR, vsfx=""):
    df = _load_headlines()
    key = f"{stem}{vsfx}"
    if not df.empty and key in df["stem"].values:
        row = df.loc[df["stem"] == key].iloc[0]
        if _cache_row_is_fresh(row, stem, output_dir, vsfx):
            return _fit_from_cache_row(row)
    return _load_fit_live(stem, output_dir, vsfx)
```

`_load_fit_live` is the existing `load_fit` --- including its synthetic-bank fallback at compare.py L274--308 --- renamed verbatim.
On cache miss or staleness, the dashboard falls through to live load with no behavioral change.

`_fit_from_cache_row` returns a `Fit` whose `main.J_p`, `main.N`, `main.runtime_s`, `main.converged` and the four `(b, se)` headline pairs come straight from the cached row.
The other ster matrices stay None --- the dashboard never reads them.

`_cache_row_is_fresh(row, stem, output_dir, vsfx)` compares the row's `mtime` against the on-disk mtimes of the main ster and the three subgroup sters (`_n`, `_a`, `_g` --- whichever exist).
Tolerance: row passes if `row_mtime + TOLERANCE_SECONDS >= max(source_mtime)` with `TOLERANCE_SECONDS = 5`.
This handles bootstrap-written rows born within a few seconds of the source sters (where strict equality would always fail) without missing genuinely stale rows from re-fits separated by minutes.

### Write path A: at fit time, inside Stata

Inside `run_grc` (in `0_programs.do`, lines 1837--2030), capture each headline value into a local at the moment it is produced.

The capture windows are tight because `nlcom, post` overwrites `e()`:

| capture window in 0_programs.do | what to capture | why this window |
|---------------------------------|-----------------|-----------------|
| **between L1942 (`estadd scalar Jpval`) and L1958 (first `nlcom, post`)** --- L1954 is the natural anchor | `local _b_phi = _b[phi:_cons]`, `local _se_phi = _se[phi:_cons]`, `local _Jp = e(Jpval)`, `local _N = e(N)`, `local _runtime = e(runtime)`, `local _converged = e(converged)` | After L1958 `e()` is replaced with the Delta_never `nlcom` post and these are gone |
| **between L1958 (`nlcom Delta_never, post`) and L1961 (`_n.ster` save)** | `local _b_Dn = _b[Delta_never]`, `local _se_Dn = _se[Delta_never]` | Delta_never is in `e()` only between these two lines |
| **between L1965 (`nlcom Delta_always, post`) and L1968 (`_a.ster` save)** | `local _b_Da = _b[Delta_always]`, `local _se_Da = _se[Delta_always]` | Same logic |
| **between L2028 (`nlcom Delta_avg, post`) and L2030 (`_g.ster` save)** | `local _b_Davg = _b[Delta_avg]`, `local _se_Davg = _se[Delta_avg]` | Same |
| **after L2030** | `capture noisily write_headlines_row, stem(...) <all locals>` | All values in scope; wrapped in capture-noisily so a buggy helper warns but does not kill `run_grc` |

The new helper `write_headlines_row` (added to `0_programs.do`) takes the locals + the cell's identifier columns + a `schema_version` macro and writes a single per-stem CSV.
Best-effort write: `file open ... file write ... file close` directly to the destination filename.
If a process is killed mid-write, the reader's try/except catches the malformed file and falls through to live load until the next clean write.

Schema column order is hardcoded as a Stata global in `0_programs.do`:

```stata
global HEADLINES_SCHEMA_VERSION 1
global HEADLINES_COLS = "stem country spec3 depvar choice balance covs2 family hukou values estimator source mtime b_phi se_phi b_delta_never se_delta_never b_delta_always se_delta_always b_delta_avg se_delta_avg J_p N runtime_s converged"
```

The bootstrap script (Python) asserts at startup that this global matches its own column list and that both match `_manifest.json`.
Any mismatch is a build error, not a silent data drift.

### Write path A applies to four estimator programs

The same capture pattern applies to:

- `run_grc` --- lines 1837--2030 in `0_programs.do` (canonical, detailed above).
- `run_grc_with_extra_regressor` --- starts at L2081.
- `run_grc_onestep` --- starts at L2215.
- `run_grc_robust` and `run_grc_robust_vv` --- elsewhere in the same file.

Each of these has the same internal structure (main fit, then four `nlcom, post` blocks for Delta_never / Delta_always / Delta_d / Delta_avg, then `_g.ster` save).
The capture targets are at the analogous lines: between the `estadd Jpval` and the first `nlcom`, then between each `nlcom` and the corresponding `_<n,a,g>.ster` save.
A grep for `nlcom (Delta_` and `estimates save .*_[nag]\${vsfx}` finds them.
The `estimator` schema column distinguishes the four (default `"run_grc"` for the canonical estimator).

### Write path B: from existing `.ster` files (one-time bootstrap)

A Python script `tools/results_overview/scrape_headlines.py` walks `RP7/output/*.ster`, calls `load_ster()` once per main and once per `_n`, `_a`, `_g` subgroup file, gathers the headline values, and writes one `headlines/<stem>.csv` per stem.

Implementation specifics:

- **Parallelization.** `--jobs N` flag (default 1, recommended 4) using `concurrent.futures.ProcessPoolExecutor` with subprocess workers, each spawning its own pystata kernel.
  ~600 main + ~1800 subgroup sters serially is ~30 min once; 4-way parallel cuts to ~8 min.
  Workers communicate per-stem rows back to the parent for unified writeout, avoiding race conditions on the manifest.
- **Atomic writes.** The Python writer uses `os.replace`: write to `<stem>.csv.tmp`, then `os.replace(tmp, dst)`.
  This is atomic on Windows and POSIX and costs nothing in Python.
  (The Stata writer remains best-effort because adding subprocess shell-out per fit costs more than the race window.)
- **Per-file try/except.** A malformed ster (e.g. one written by a fit that failed after `e(b)` but before `e(V)`) is logged and skipped, not fatal.
- **Idempotency.** Re-running `scrape_headlines.py` on top of an existing `headlines/` produces the same end state (modulo timestamps in the `mtime` column).
  Verification: run twice, confirm `git diff` is empty modulo `mtime` columns and the manifest's `written_at`.
- **Orphan cleanup.** The script also walks `RP7/output/headlines/*.csv` and deletes any cache file whose source `<stem>.ster` no longer exists (e.g. after a refactor renames a stem).
  Without this, orphaned rows linger forever, no source ster to invalidate against.
- **Synthetic-bank rows.** For `_r` stems with no on-disk ster, the script optionally synthesizes from `scraped_real.json` and writes the row with `source = "bank"`.
  When the local re-fit eventually produces a real `.ster`, the in-Stata writer overwrites the bank row with `source = "ster"`.

### No separate consolidator

The dashboard's `_load_headlines()` reads the directory at every call (no caching layer) and concatenates in memory.
The "consolidated CSV" is purely a transient in-memory view, never written back to disk.
This keeps per-stem files as the single source of truth.

## Update semantics

If the user re-runs IDN consumption urban, the existing IDN-consumption-urban rows must be replaced; everything else stays put.

The per-stem-file design satisfies this by construction:
writing `headlines/grc_IDN_cuu_c0.csv` overwrites only that file.
Files for CHN, TZA, other depvars, balanced sample, family extras, hukou splits are untouched.
The dashboard's consolidation reads whatever is currently in the directory; the next render automatically reflects the new IDN-cuu values without any merge logic anywhere.

The blast radius of a re-run equals the set of stems it actually re-fits.

## Atomicity

Two writers, two policies:

- **Python bootstrap** (`scrape_headlines.py`) uses `os.replace` for true atomic rename.
  Free in Python; correct on Windows and POSIX.
- **Stata in-fit writer** (`write_headlines_row`) uses best-effort `file open ... file close`.
  Adding `os.replace`-equivalent atomicity per fit means shelling out to Python on every fit (~150ms cold start, dominating the helper's cost) for a race window of microseconds.
  Not worth it given the reader's tolerant fallback.

The reader's `try/except` around `pd.read_csv` catches malformed files (the only Stata-side failure mode) and skips them; the dashboard falls through to live load for those stems on that render and picks up the correct cache row on the next render.

## Schema versioning (manifest sidecar)

A single file at `RP7/output/headlines/_manifest.json`:

```json
{
  "schema_version": 1,
  "columns": ["stem", "country", "spec3", "depvar", "choice", "balance",
              "covs2", "family", "hukou", "values", "estimator", "source",
              "mtime",
              "b_phi", "se_phi",
              "b_delta_never", "se_delta_never",
              "b_delta_always", "se_delta_always",
              "b_delta_avg", "se_delta_avg",
              "J_p", "N", "runtime_s", "converged"],
  "written_at": "2026-05-09T12:00:00",
  "writer": "scrape_headlines.py | run_grc"
}
```

`_load_headlines()` reads the manifest first.
On `schema_version` mismatch with `EXPECTED_SCHEMA_VERSION`, the cache is treated as empty, the dashboard falls through to live loads for everything, and a stderr warning instructs the user to re-run `scrape_headlines.py`.

The manifest column order is the source of truth for the schema.
The bootstrap script writes the manifest and asserts the Stata global `$HEADLINES_COLS` matches.
The Stata writer reads `$HEADLINES_COLS` directly (set in `0_programs.do`) --- no JSON parsing in Stata.
On a schema bump:

1. Edit `EXPECTED_SCHEMA_VERSION` and the column lists in `compare.py`, `0_programs.do`, and `scrape_headlines.py`.
2. Re-run `scrape_headlines.py` to regenerate the cache and rewrite the manifest.
3. The dashboard now reads the new schema cleanly.

## Source provenance (`source` column)

`source = "ster"` indicates the row was derived from an on-disk ster (via Stata writer or Python bootstrap).
`source = "bank"` indicates synthesis from `scraped_real.json` for `_r` stems with no local fit.

The column is informational provenance.
Per-stem files are single-source: one file per stem at any time, and a write replaces whatever was there.
There is no "two files for the same stem" precedence rule because there is no two-files-for-one-stem case.

## Race safety with multiple Stata instances

Each instance writes to its own per-stem files.
Two instances writing to the same `<stem>.csv` is impossible if the partition is disjoint (the requirement for the parallelization plan separately).
Two instances writing to different `<stem>.csv` files have zero shared state.

## Why not a single CSV with upsert semantics

Considered: one canonical `headlines.csv` that `run_grc` reads, deletes the stem's row from, appends to, and writes back.

Rejected because:

1. Stata can't easily upsert a row into a CSV without trampling the in-memory dataset (would need `preserve`/`restore` or a `frame`).
2. Concurrent writers fight over the file; needs a lock.
3. A partial write (process killed mid-rewrite) corrupts the entire CSV, not just one row.
4. Diff readability: a single 600-row CSV that gets rewritten on every fit produces meaningless full-file diffs in git.

Per-stem files dodge all four.

## Why not JSON

CSV wins for this schema because:

- Flat tabular data --- no nesting needed.
- `pd.read_csv` is faster than `pd.read_json` for large flat tables.
- Excel-openable for a coauthor without Python.
- Diffable per row in git.

Reserve JSON for the manifest sidecar (where small structured metadata is the natural fit).

## Stem key

The cache key is the full ster filename without `.ster`.
Examples:

| ster filename | cache key | what it is |
|---------------|-----------|------------|
| `grc_IDN_cuu_c0.ster` | `grc_IDN_cuu_c0` | main GRC, IDN consumption-urban-unbalanced, no covariates |
| `grc_CHN_rf_cuu_ca.ster` | `grc_CHN_rf_cuu_ca` | hukou split (rural-first), CHN consumption-urban-unbalanced, +edu covs |
| `grc_IDN_cuu_exp_c1.ster` | `grc_IDN_cuu_exp_c1` | family extras (experience), IDN consumption-urban-unbalanced, +female |
| `grc_IDN_cuu_c0_r.ster` | `grc_IDN_cuu_c0_r` | real-values version of the first row |

One row per (full filename) cell.
The composite identifier columns (`country`, `spec3`, `family`, `hukou`, `values`, `covs2`) are denormalized for filtering and human readability but are not the primary key.

## Schema details

Columns in fixed order (matching `_manifest.json` and `$HEADLINES_COLS`):

```
stem, country, spec3, depvar, choice, balance, covs2, family, hukou, values,
estimator, source, mtime,
b_phi, se_phi,
b_delta_never, se_delta_never,
b_delta_always, se_delta_always,
b_delta_avg, se_delta_avg,
J_p, N, runtime_s, converged
```

- `estimator`: `"run_grc"` for the canonical GRC; reserved for `"run_grc_onestep"`, `"run_grc_robust"`, `"run_grc_robust_vv"` in future expansions.
- `source`: `"ster"` (live or bootstrap) or `"bank"` (synthesized from `scraped_real.json`).
- `mtime`: ISO 8601 timestamp when the row was generated; used by the reader's freshness gate.
- Missing values (e.g. a fit type that has no `_a.ster` because of a small subsample) are written as empty CSV cells; pandas reads them as NaN.

## Rescale-overlay precedence

The existing `_load_rescaled()` overlay (loading from `RP7/output/delta_avg_rescaled.csv`) sits one layer above the cache.
The cache stores raw `_g.ster` values for `b_delta_avg` / `se_delta_avg` --- whatever the binary file actually contains, including buggy values for the 110 pre-fix cells.
After `Fit.headline()` returns the cached `(b, se)`, the existing rescale logic (compare.py L258--267) checks whether the loaded values match `b_buggy`/`se_buggy` in the rescale CSV and substitutes `b_rescaled`/`se_rescaled` if so.
This logic runs identically on cache-hit and cache-miss paths; nothing in the rescale layer changes.
The rescale layer becomes obsolete on its own once all 110 pre-fix cells are re-fit under the corrected `0_programs.do`; the match-on-buggy guard auto-bypasses, exactly as today.

## Migration plan (revised order: bootstrap first, writer last)

The original migration plan had the Stata writer landing first.
The revised order de-risks: if the writer turns out to be buggy, the bootstrap script is the ground truth and we never have to re-fit anything to recover.

### Step 0 --- baseline + bottleneck profile

Render the dashboard once before any change.
Save `report.html` to `quality_reports/baselines/2026-05-09_pre-cache.html`.
Profile the same render with `cProfile` to confirm `load_ster` (or `_cached_load_ster`) accounts for ≥80% of wall time.
If a different function dominates (e.g. `_synthetic_fit_from_bank` or `_load_rescaled` repeatedly rebuilding), the design assumptions need rechecking before sinking effort into the cache.

### Step 1 --- bootstrap (Python, read-only against `.ster`)

Land `tools/results_overview/scrape_headlines.py` with `--jobs N` flag.
Walk `RP7/output/*.ster`, call `load_ster()` once per main + `_n` + `_a` + `_g` subgroup file, write per-stem CSVs into `RP7/output/headlines/` via `os.replace` atomic rename.
Write `headlines/_manifest.json` with `schema_version: 1` and the column list.
For `_r` stems missing on disk, synthesize from `scraped_real.json` with `source: "bank"` and `mtime` set to the current time.
Run with `--jobs 4` for ~8 min wall time.
Verify idempotency: re-run, confirm `git diff` is empty modulo `mtime` columns and manifest's `written_at`.

### Step 2 --- reader (dashboard side)

Rename existing `load_fit` to `_load_fit_live` (preserving its synthetic-bank fallback).
Add `_load_headlines()`, `_cache_row_is_fresh()`, `_fit_from_cache_row()`, `EXPECTED_SCHEMA_VERSION` in `compare.py`.
Add the new cache-aware `load_fit()` that delegates to `_load_fit_live` on miss or staleness.
Re-render the dashboard.
Compare against the baseline from step 0 --- bytes-identical (modulo timestamps in the rendered footer) is the success criterion.

### Step 3 --- in-Stata writer (substantive)

Land `write_headlines_row` and `$HEADLINES_COLS` in `0_programs.do`, plus the capture-and-call edits at the four windows in `run_grc` (and analogous windows in `run_grc_with_extra_regressor`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`).
Each call site is wrapped in `capture noisily { write_headlines_row ... }` so a bad helper warns but does not kill the fit.
On the next fit run, new sters get cache rows automatically.
Existing rows from the bootstrap are preserved; new fits overwrite them.

Each step is independently committable and reversible.
After step 2, the dashboard is fast even without step 3.
Step 3 is purely an optimization to avoid having to re-run `scrape_headlines.py` after every fit batch.

## What changes in the codebase

### New files

- `tools/results_overview/scrape_headlines.py` --- bootstrap script with `--jobs N`.
- `RP7/output/headlines/_manifest.json` --- schema manifest (created by bootstrap, updated on schema bumps).
- `RP7/output/headlines/<stem>.csv` --- one per fit, ~600 files.
- `quality_reports/baselines/2026-05-09_pre-cache.html` --- step 0 comparison artifact.

### Edited files

- `RP7/scripts/0_programs.do` --- adds `write_headlines_row` helper, `$HEADLINES_SCHEMA_VERSION` and `$HEADLINES_COLS` globals, plus capture-and-call edits at four windows in `run_grc` and analogous windows in `run_grc_with_extra_regressor`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`.
- `tools/results_overview/compare.py` --- renames existing `load_fit` to `_load_fit_live`; adds `_load_headlines`, `_cache_row_is_fresh`, `_fit_from_cache_row`, `EXPECTED_SCHEMA_VERSION`; adds the new cache-aware `load_fit` wrapper.

### Untouched

- `tools/results_overview/scrape.py` --- still does the live `load_ster` work for cache misses, including the synthetic-bank fallback for `_r` fits where appropriate.
- `RP7/scripts/4_GrRC.do`, `5_GrRC_NonAg.do`, `7_GrRC_hukou.do`, `9_GRC_extras.do`, `8_learning.do` --- inherit the new helper transparently through `run_grc`.

### Gitignore

`RP7/output/headlines/` is gitignored, same as `*.ster`.
The cache is fully derivable from `.ster` files via `scrape_headlines.py`.
Tracking would create per-fit churn that pollutes diffs without adding signal.

## Open questions resolved during this design

- Atomic write strategy: best-effort writer (Stata) + atomic-rename writer (Python) + tolerant reader.
- Schema versioning: `_manifest.json` sidecar with hardcoded `$HEADLINES_COLS` global as the Stata-side mirror.
- Gitignore vs track: gitignored.
- `estimator` column: included now.
- `Delta_always` in cache: yes (added per round-2 user request); per-trajectory `Delta_d` remains out of scope.
- Bootstrap parallelization: `--jobs N` flag, default 1, recommended 4.
- `lru_cache` on `_load_headlines()`: dropped (avoids stale reads in long-lived Jupyter kernels).
- Mtime tolerance: 5-second slack for bootstrap-written rows.
- Manifest read in Stata: replaced with hardcoded `$HEADLINES_COLS` global, asserted at bootstrap time.
- `capture noisily` wrapper on each Stata call site: yes (defensive, lets a bad helper warn without killing fits).
- Orphan cache row cleanup: handled in `scrape_headlines.py` (delete any `headlines/<stem>.csv` whose source `<stem>.ster` no longer exists).
