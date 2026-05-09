# Headlines cache: design (revised after critic review)

## Goal

Cut dashboard render time from ~30+ min to seconds by caching the headline numbers per stem into a flat-file cache.
Replace per-render pystata round-trips with a single `pd.read_csv` per render.

The cache is a derived artifact, not a replacement for `.ster`.
Stata's table builders (`10_make_tables.do`, `11_make_figures.do`) still read full `e(b)`/`e(V)` from `.ster` to write the multi-row LaTeX tables.

## Note on the multi-ster structure

Each call to `run_grc` produces five ster files: one main GMM fit plus four `nlcom`-posted derived quantities (`Delta_never`, `Delta_always`, the trajectory Deltas, `Delta_avg`).
The four are separate sters because `nlcom, post` is destructive --- there is only one active `e()` slot in Stata, and saving each derived quantity preserves it for downstream commands like `test`, `lincom`, and `estimates table`.

The cache flattens this: one cache row per `(country, spec3, depvar, choice, balance, covs, family, hukou, values)` cell, with columns drawn from across the five sters.
Whether the future pipeline ever consolidates to fewer sters per model (via `, append` or `estadd matrix`) is independent of this design --- the cache key is the model, not the ster file.

## What the cache must carry

Per stem, the dashboard reads:

| field | source ster | parameter / scalar | consumed in |
|-------|-------------|--------------------|-------------|
| `b_phi`, `se_phi` | main | `phi:_cons` | `Fit.headline()` |
| `b_delta_never`, `se_delta_never` | `_n` | `Delta_never` | `Fit.headline()` |
| `b_delta_avg`, `se_delta_avg` | `_g` | `Delta_avg` | `Fit.headline()` |
| `J_p` | main | `e(Jpval)` | `comparison_table` row build |
| `N` | main | `e(N)` | `comparison_table` row build |
| `runtime_s` | main | `e(runtime)` | `comparison_table` row build |
| `converged` | main | `e(converged)` | `comparison_table` row build |

The diagnostic columns (`J_p`, `N`, `runtime_s`, `converged`) are pulled directly off `fit.main.*` in `comparison_table`, not through `Fit.headline()`.
A cache that only feeds `Fit.headline()` would still trigger a full `load_fit()` per cell to populate those four scalars and would barely move the render time.
The cache must short-circuit `load_fit()` itself --- not just `headline()`.

## Architecture

Two write paths, one read path, one consolidator.

### Read path (the dashboard side)

`compare.py` adds:

```python
@lru_cache(maxsize=1)
def _load_headlines() -> pd.DataFrame:
    cache_dir = OUTPUT_DIR / "headlines"
    if not cache_dir.exists():
        return pd.DataFrame()
    rows: list[pd.DataFrame] = []
    for f in cache_dir.glob("*.csv"):
        try:
            rows.append(pd.read_csv(f))
        except (pd.errors.EmptyDataError, pd.errors.ParserError) as e:
            logging.warning("skipping malformed cache file %s: %s", f, e)
    if not rows:
        return pd.DataFrame()
    df = pd.concat(rows, ignore_index=True)
    logging.info("headlines cache: %d files, %d rows", len(rows), len(df))
    return df
```

`load_fit()` becomes cache-aware:

```python
def load_fit(stem, output_dir=OUTPUT_DIR, vsfx=""):
    df = _load_headlines()
    key = f"{stem}{vsfx}"
    if not df.empty and key in df["stem"].values:
        row = df.loc[df["stem"] == key].iloc[0]
        if _cache_row_is_fresh(row, stem, output_dir, vsfx):
            return _fit_from_cache_row(row)
    # cache miss or stale -> live load
    return _load_fit_live(stem, output_dir, vsfx)
```

`_fit_from_cache_row` returns a `Fit` whose `main.J_p`, `main.N`, `main.runtime_s`, `main.converged` and the three `(b, se)` headline pairs come straight from the cached row.
The other ster matrices stay None --- the dashboard never reads them.
`_cache_row_is_fresh` compares the row's `mtime` against the on-disk mtimes of the main ster and the four subgroup sters (whichever exist); if any source ster is newer, the cache row is stale, drop and re-derive live.
This gates "trust the writer" with mtime invalidation, the cheapest robustness win available.

### Write path A: at fit time, inside Stata

Inside `run_grc` (in `0_programs.do`, lines 1837--2030), capture each headline value into a local at the moment it is produced:

| line in 0_programs.do | what to capture |
|-----------------------|-----------------|
| ~1954 (after main `estimates save`) | `local _b_phi = _b[phi:_cons]`, `local _se_phi = _se[phi:_cons]`, plus `local _Jp = e(Jpval)`, `local _N = e(N)`, `local _runtime = e(runtime)`, `local _converged = e(converged)` |
| ~1958 (after Delta_never `nlcom, post`) | `local _b_Dn = _b[Delta_never]`, `local _se_Dn = _se[Delta_never]` |
| ~2028 (after Delta_avg `nlcom, post`) | `local _b_Davg = _b[Delta_avg]`, `local _se_Davg = _se[Delta_avg]` |
| ~2030 (after `_g.ster` save) | call `write_headlines_row` with all the captured locals |

The new helper `write_headlines_row` (added to `0_programs.do`) takes the locals + the cell's identifier columns + a `schema_version` macro and writes a single per-stem CSV.
The same pattern applies inside `run_grc_with_extra_regressor`, `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv` --- one helper, four call sites.

### Write path B: from existing `.ster` files (one-time bootstrap)

A Python script `tools/results_overview/scrape_headlines.py` walks `RP7/output/*.ster`, calls `load_ster()` once per main and once per `_n` and `_g` subgroup file, and writes one `headlines/<stem>.csv` per stem.
Slow once (paying one full pystata pass), fast forever after.
This is the same pystata cost the dashboard currently pays per render, paid one time only.

### Consolidator (no separate step)

There is no consolidator script.
The dashboard's `_load_headlines()` reads the directory at module-import time (cached via `lru_cache`) and concatenates in memory.
The "consolidated CSV" is purely a transient in-memory view, never written back to disk.
This avoids any third file format and keeps the per-stem files as the single source of truth.

## Update semantics

If the user re-runs IDN consumption urban, the existing IDN-consumption-urban rows must be replaced; everything else stays put.

The per-stem-file design satisfies this by construction:
writing `headlines/grc_IDN_cuu_c0.csv` overwrites only that file.
Files for CHN, TZA, other depvars, balanced sample, family extras, hukou splits are untouched.
The dashboard's consolidation reads whatever is currently in the directory; the next render automatically reflects the new IDN-cuu values without any merge logic anywhere.

The blast radius of a re-run equals the set of stems it actually re-fits.

## Atomicity (best-effort writer + tolerant reader)

Stata writes the per-stem CSV as a single `file write ... file close` block.
On Windows this is not a guaranteed atomic operation; a process killed mid-write can leave a partially written file on disk.

Mitigations on the writer side:

- The per-stem file is two lines (header + one data row).
  The window between "file open" and "file close" is sub-millisecond per write.
- A killed Stata mid-write affects at most the one cell currently being written.

Mitigations on the reader side:

- `_load_headlines()` wraps each `pd.read_csv` in `try/except`, catching `EmptyDataError` and `ParserError`.
  A bad file logs a warning and is skipped; the corresponding stem falls through to live `load_fit_live()`.
- The next time that stem is re-fit (or the bootstrap script is re-run), the file is rewritten cleanly and the warning goes away.

True atomic rename via `os.replace` was considered (have Stata write a tmp file then shell out to a tiny Python helper for the rename).
Rejected for now: the helper would add ~150 ms per fit (~1.5 min over a 600-fit pipeline), the race window in the best-effort design is microseconds, and the failure mode is self-healing.
Easy to swap in later if the race ever bites in practice.

## Schema versioning (manifest sidecar)

A single file at `RP7/output/headlines/_manifest.json`:

```json
{
  "schema_version": 1,
  "columns": ["stem", "country", "spec3", "depvar", "choice", "balance",
              "covs2", "family", "hukou", "values", "estimator", "source",
              "mtime",
              "b_phi", "se_phi", "b_delta_never", "se_delta_never",
              "b_delta_avg", "se_delta_avg",
              "J_p", "N", "runtime_s", "converged"],
  "written_at": "2026-05-09T12:00:00",
  "writer": "scrape_headlines.py | run_grc"
}
```

`_load_headlines()` reads the manifest first.
If `schema_version` does not match the dashboard's `EXPECTED_SCHEMA_VERSION`, the cache is treated as empty and the dashboard falls through to live loads for everything (with a loud warning suggesting a re-bootstrap).
This avoids silent NaN-coercion when columns are added/removed.

The Stata writer reads the manifest at fit time and uses its column order to format the row, so the writer and reader agree on layout.
On schema bump: bump `EXPECTED_SCHEMA_VERSION` in `compare.py`, edit the writer to emit the new columns, re-run `scrape_headlines.py` to regenerate the cache; the manifest updates as a side effect.

## Source provenance (`source` column)

For `_r` real-values fits without on-disk sters, the bootstrap script can synthesize cache rows from `scraped_real.json` (currently the source of truth for real-values headlines).

To distinguish:

- `source = "ster"` --- row was derived from an on-disk ster (live or bootstrap).
- `source = "bank"` --- row was synthesized from `scraped_real.json`.

If both exist for the same stem (e.g. a real-values fit was run locally after bootstrap synthesized from JSON), the reader prefers `source = "ster"`.
Per-stem files are still the carrier; the bootstrap script writes the file with `source = "bank"`, and the in-Stata writer overwrites it with `source = "ster"` on the next local re-fit.

## Race safety with multiple Stata instances

Each instance writes to its own per-stem files.
Two instances writing to the same `<stem>.csv` is impossible if the partition is disjoint (which is the requirement for the parallelization plan separately).
Two instances writing to different `<stem>.csv` files have zero shared state.

The dashboard reads whatever is on disk at consolidation time.
A reader hitting a file mid-write degrades gracefully via the tolerant-reader pattern.

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
- Excel-openable for a coauthor without Python (they can drag the whole `headlines/` directory into a sheet via a small concat).
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

Columns in fixed order (also recorded in `_manifest.json`):

```
stem, country, spec3, depvar, choice, balance, covs2, family, hukou, values,
estimator, source, mtime,
b_phi, se_phi, b_delta_never, se_delta_never, b_delta_avg, se_delta_avg,
J_p, N, runtime_s, converged
```

- `estimator`: `"run_grc"` for the standard GRC estimator; reserved for `"run_grc_onestep"`, `"run_grc_robust"`, `"run_grc_robust_vv"` in future expansions.
- `source`: `"ster"` or `"bank"` per the precedence rule above.
- `mtime`: ISO 8601 timestamp when the row was generated.
  Used by the reader's mtime invalidation gate.
- Missing values (e.g. a fit type that has no `_g.ster`) are written as empty CSV cells; pandas reads them as NaN.

## Rescale-overlay precedence

The existing `tools/results_overview/compare.py:_load_rescaled()` overlay (loading from `RP7/output/delta_avg_rescaled.csv`) sits one layer above the cache.

The cache stores raw `_g.ster` values for `b_delta_avg` / `se_delta_avg` --- whatever the binary file actually contains, including buggy values for the 110 pre-fix cells.
After `Fit.headline()` returns the cached `(b, se)`, the existing rescale logic (compare.py L258--267) checks whether the loaded values match `b_buggy/se_buggy` in the rescale CSV and substitutes `b_rescaled/se_rescaled` if so.
This logic runs identically on cache-hit and cache-miss paths --- nothing in the rescale layer changes.

The rescale layer becomes obsolete on its own once all 110 pre-fix cells are re-fit under the corrected `0_programs.do`; the match-on-buggy guard auto-bypasses, exactly as today.

## Migration plan (revised order: bootstrap first, writer last)

The original migration plan had the Stata writer landing first.
The revised order de-risks: if the writer turns out to be buggy, the bootstrap script is the ground truth and we never have to re-fit anything to recover.

### Step 0 --- baseline

Render the dashboard once before any change.
Save `report.html` to `quality_reports/baselines/2026-05-09_pre-cache.html`.
This is the comparison artifact for verifying the cached render returns identical numbers.

### Step 1 --- bootstrap (Python, read-only against `.ster`)

Land `tools/results_overview/scrape_headlines.py`.
Walk `RP7/output/*.ster`, call `load_ster()` once per main and once per `_n`/`_g` subgroup file, write per-stem CSVs into `RP7/output/headlines/`.
Write `headlines/_manifest.json` with `schema_version: 1` and the column list.
For `_r` stems missing on disk, optionally synthesize from `scraped_real.json` with `source: "bank"`.

### Step 2 --- reader (dashboard side)

Land `_load_headlines()`, `_cache_row_is_fresh()`, `_fit_from_cache_row()`, `EXPECTED_SCHEMA_VERSION` in `compare.py`.
Modify `load_fit()` to consult the cache before calling `_load_fit_live`.
Re-render the dashboard.
Compare against the baseline from step 0 --- bytes-identical (modulo the timestamp in the rendered footer) is the success criterion.

### Step 3 --- in-Stata writer (substantive)

Land `write_headlines_row` in `0_programs.do` and the call-site captures at the four targets (~1954, ~1958, ~2028, ~2030 inside `run_grc` and analogous spots in `run_grc_onestep`, `run_grc_robust`, `run_grc_robust_vv`).
On the next fit run, new sters get cache rows automatically.
Existing rows from the bootstrap are preserved; new fits overwrite them.

Each step is independently committable and reversible.
After step 2, the dashboard is fast even without step 3.
Step 3 is purely an optimization to avoid having to re-run `scrape_headlines.py` after every fit batch.

## What changes in the codebase

### New files

- `tools/results_overview/scrape_headlines.py` --- bootstrap script.
- `RP7/output/headlines/_manifest.json` --- schema manifest (created by bootstrap, updated on schema bumps).
- `RP7/output/headlines/<stem>.csv` --- one per fit, ~600 files.
- `quality_reports/baselines/2026-05-09_pre-cache.html` --- step 0 comparison artifact.

### Edited files

- `RP7/scripts/0_programs.do` --- adds `write_headlines_row` helper, plus capture-and-call edits at four call sites inside `run_grc` and analogous edits in the other three estimator programs.
- `tools/results_overview/compare.py` --- adds `_load_headlines`, `_cache_row_is_fresh`, `_fit_from_cache_row`, `EXPECTED_SCHEMA_VERSION`; modifies `load_fit` to be cache-aware.

### Untouched

- `tools/results_overview/scrape.py` --- still does the live `load_ster` work for cache misses, including the synthetic-bank fallback for `_r` fits where appropriate.
- `RP7/scripts/4_GrRC.do`, `5_GrRC_NonAg.do`, `7_GrRC_hukou.do`, `9_GRC_extras.do`, `8_learning.do` --- inherit the new helper transparently through `run_grc`.

### Gitignore

`RP7/output/headlines/` is gitignored (added to `.gitignore`), same as `*.ster`.
The cache is fully derivable from `.ster` files via `scrape_headlines.py`.
Tracking would create per-fit churn that pollutes diffs without adding signal.

## Open questions resolved during this design

- Atomic write strategy: best-effort writer + tolerant reader.
- Schema versioning: `_manifest.json` sidecar.
- Gitignore vs track: gitignored.
- `estimator` column: included now.
