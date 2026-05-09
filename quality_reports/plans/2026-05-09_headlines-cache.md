# Headlines cache: design (round 3, simplified)

## Goal

Cut dashboard render time from ~30+ min to seconds by caching the headline numbers per stem into a flat-file cache.
Replace per-render pystata round-trips with a single `pd.read_csv` directory walk.

The cache is a derived artifact, not a replacement for `.ster`.
Stata's table builders (`10_make_tables.do`, `11_make_figures.do`) still read full `e(b)`/`e(V)` from `.ster` to write the multi-row LaTeX tables.

## Note on the multi-ster structure

Each call to `run_grc` produces five ster files: one main GMM fit plus four `nlcom`-posted derived quantities (`Delta_never`, `Delta_always`, the trajectory Deltas, `Delta_avg`).
The four are separate sters because `nlcom, post` is destructive --- there is only one active `e()` slot in Stata, and saving each derived quantity preserves it for downstream commands like `test`, `lincom`, and `estimates table`.

The cache flattens this: one cache row per stem (full ster filename), with columns drawn from across the relevant sters.
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

One writer, one reader.
The Python bootstrap script is the only thing that ever writes the cache.
Run it after every fit batch (or wire it into `0_master.do`'s tail) to keep the cache fresh.

### Writer: `tools/results_overview/scrape_headlines.py`

Walks `RP7/output/*.ster`, calls `load_ster()` once per main + `_n` + `_a` + `_g` subgroup file, gathers the headline values, and writes one `headlines/<stem>.csv` per stem.

Implementation specifics:

- **Atomic writes** via `os.replace`: write to `<stem>.csv.tmp`, then `os.replace(tmp, dst)`.
  Atomic on Windows and POSIX, free in Python.
- **Per-file try/except.** A malformed ster (e.g. one written by a fit that failed after `e(b)` but before `e(V)`) is logged and skipped, not fatal.
- **Idempotency.** Re-running on top of an existing `headlines/` produces the same end state (modulo the `mtime` columns).
  Verification: run twice, confirm `git diff` is empty modulo mtimes.
- **Orphan cleanup.** Walks `RP7/output/headlines/*.csv` and deletes any cache file whose source `<stem>.ster` no longer exists (e.g. after a refactor renames a stem).
- **`--incremental` flag.** Skips stems whose `<stem>.csv` is newer than all four source ster mtimes.
  After a fit batch, `--incremental` only re-derives the changed cells; full bootstrap is still available without the flag.
- **`--jobs N` flag.** Default 1.
  Parallelize across worker subprocesses (each with its own pystata kernel) only if 30 min full bootstrap actually annoys someone.

`_r` stems with no on-disk ster are NOT scraped.
Those continue to use the existing `_load_fit_live` synthetic-bank fallback path that already works.
This drops a whole class of bank-vs-ster precedence concerns.

### Reader (the dashboard side)

`compare.py` adds:

```python
EXPECTED_SCHEMA_VERSION = 1


def _load_headlines() -> pd.DataFrame:
    cache_dir = OUTPUT_DIR / "headlines"
    if not cache_dir.exists():
        return pd.DataFrame()
    rows: list[pd.DataFrame] = []
    bad: list[str] = []
    for f in cache_dir.glob("*.csv"):
        try:
            rows.append(pd.read_csv(f))
        except (pd.errors.EmptyDataError, pd.errors.ParserError):
            bad.append(str(f))
    if bad:
        logging.warning("skipped %d malformed cache files: %s", len(bad), bad[:5])
    if not rows:
        return pd.DataFrame()
    df = pd.concat(rows, ignore_index=True)
    # Drop any rows with stale schema (warn user to re-run scrape_headlines.py)
    if "schema_version" in df.columns:
        wrong = df["schema_version"] != EXPECTED_SCHEMA_VERSION
        if wrong.any():
            logging.warning(
                "headlines cache: %d rows have wrong schema_version; "
                "run `python tools/results_overview/scrape_headlines.py` to regenerate.",
                int(wrong.sum()),
            )
            df = df.loc[~wrong]
    logging.info("headlines cache: %d files, %d rows", len(rows), len(df))
    return df
```

No `@lru_cache`: the function is cheap (~600 small CSV reads), and re-reading on every render keeps long-lived Jupyter kernels honest.

`load_fit()` becomes cache-aware (the existing function is renamed to `_load_fit_live`, preserving its synthetic-bank fallback for `_r` stems):

```python
def load_fit(stem, output_dir=OUTPUT_DIR, vsfx=""):
    df = _load_headlines()
    key = f"{stem}{vsfx}"
    if not df.empty and key in df["stem"].values:
        row = df.loc[df["stem"] == key].iloc[0]
        # Exact mtime comparison: each row records the source mtimes it was built from
        if all(
            _same_mtime(row.get(f"{suffix}_mtime"), output_dir / f"{stem}{('_' + suffix) if suffix != 'main' else ''}{vsfx}.ster")
            for suffix in ("main", "n", "a", "g")
        ):
            return _fit_from_cache_row(row)
    return _load_fit_live(stem, output_dir, vsfx)
```

`_same_mtime(cached_iso, ster_path)` returns True if either the ster doesn't exist (e.g. a fit type with no `_a.ster`) or its on-disk mtime equals the cached ISO timestamp.
Exact comparison; no tolerance constant.

`_fit_from_cache_row` returns a `Fit` whose `main.J_p`, `main.N`, `main.runtime_s`, `main.converged`, `b`, `se`, plus the four subgroup `n_rec.b`, `a_rec.b`, `g_rec.b` (each populated with just the relevant single-row Series) come from the cached row.
The other ster matrices stay None.
A one-line check on the codebase (`grep -n "fit\.main\.\|fit\.[nadg]_rec\." compare.py`) confirms no caller reads anything outside what the cache supplies.

`_load_fit_live` is the existing `load_fit` --- including its synthetic-bank fallback at compare.py L274--308 --- renamed verbatim.
On cache miss or staleness, the dashboard falls through with no behavioral change.

## Update semantics

If the user re-runs IDN consumption urban, the existing IDN-consumption-urban rows must be replaced; everything else stays put.

The per-stem-file design satisfies this by construction: writing `headlines/grc_IDN_cuu_c0.csv` overwrites only that file.
Files for CHN, TZA, other depvars, balanced sample, family extras, hukou splits are untouched.
After re-fitting, run `scrape_headlines.py --incremental` to refresh just the changed stems.
The dashboard's consolidation reads whatever is currently in the directory; the next render automatically reflects the new values without any merge logic.

## Why per-stem files (not a single CSV)

Considered: one canonical `headlines.csv` that the bootstrap reads, deletes the stem's row from, appends to, and writes back.

Rejected because:

1. A partial write (process killed mid-rewrite) corrupts the entire CSV, not just one row.
2. Diff readability: a single 600-row CSV that gets rewritten on every fit produces meaningless full-file diffs in git.
3. Per-stem files trivially handle re-runs --- writing one file overwrites only that file.

## Why CSV (not JSON)

CSV wins for this schema:

- Flat tabular data --- no nesting needed.
- `pd.read_csv` is faster than `pd.read_json` for large flat tables.
- Excel-openable for a coauthor without Python.
- Diffable per row in git.

## Stem key

The cache key is the full ster filename without `.ster`.
Examples:

| ster filename | cache key | what it is |
|---------------|-----------|------------|
| `grc_IDN_cuu_c0.ster` | `grc_IDN_cuu_c0` | main GRC, IDN consumption-urban-unbalanced, no covariates |
| `grc_CHN_rf_cuu_ca.ster` | `grc_CHN_rf_cuu_ca` | hukou split (rural-first), CHN consumption-urban-unbalanced, +edu covs |
| `grc_IDN_cuu_exp_c1.ster` | `grc_IDN_cuu_exp_c1` | family extras (experience), IDN consumption-urban-unbalanced, +female |
| `grc_IDN_cuu_c0_r.ster` | `grc_IDN_cuu_c0_r` | real-values version (NOT cached --- falls through to bank fallback) |

One row per (full filename) cell.
The composite identifier columns (`country`, `spec3`, `family`, `hukou`, `values`, `covs2`) are denormalized for filtering and human readability but are not the primary key.

## Schema (v1)

Columns in fixed order; `schema_version` first:

```
schema_version,
stem, country, spec3, depvar, choice, balance, covs2, family, hukou, values,
estimator,
main_mtime, n_mtime, a_mtime, g_mtime,
b_phi, se_phi,
b_delta_never, se_delta_never,
b_delta_always, se_delta_always,
b_delta_avg, se_delta_avg,
J_p, N, runtime_s, converged
```

- `schema_version`: integer; `EXPECTED_SCHEMA_VERSION` in `compare.py` and `scrape_headlines.py` must match.
  Mismatch → reader drops those rows and warns the user to re-bootstrap.
- `estimator`: `"run_grc"` for the canonical GRC; reserved for `"run_grc_onestep"`, `"run_grc_robust"`, `"run_grc_robust_vv"` if/when added.
- `main_mtime`, `n_mtime`, `a_mtime`, `g_mtime`: ISO 8601 timestamps of the source sters as observed at write time; empty if the corresponding ster doesn't exist.
  Exact-equality compared at read time to detect stale rows.
- Missing values (e.g. a fit with no `_a.ster`) are written as empty CSV cells; pandas reads them as NaN.

On a schema bump:

1. Edit `EXPECTED_SCHEMA_VERSION` and the column lists in `compare.py` and `scrape_headlines.py`.
2. Re-run `scrape_headlines.py` to regenerate the cache.
3. The dashboard now reads the new schema cleanly.

## Rescale-overlay precedence

The existing `_load_rescaled()` overlay (loading from `RP7/output/delta_avg_rescaled.csv`) sits one layer above the cache.
The cache stores raw `_g.ster` values for `b_delta_avg` / `se_delta_avg` --- whatever the binary file actually contains, including buggy values for the 110 pre-fix cells.
After `Fit.headline()` returns the cached `(b, se)`, the existing rescale logic (compare.py L258--267) checks whether the loaded values match `b_buggy`/`se_buggy` and substitutes `b_rescaled`/`se_rescaled` if so.
This logic runs identically on cache-hit and cache-miss paths; nothing in the rescale layer changes.
The rescale layer becomes obsolete on its own once all 110 pre-fix cells are re-fit; the match-on-buggy guard auto-bypasses, exactly as today.

## Race safety with multiple Stata instances

Not a concern for this design: the cache is written by Python only, and `os.replace` is atomic.
Multiple Stata instances writing sters concurrently is fine; the next bootstrap pass picks them all up.

## Migration plan

### Step 0 --- baseline + bottleneck profile

Render the dashboard once before any change.
Save `report.html` to `quality_reports/baselines/2026-05-09_pre-cache.html`.
Profile the render with `cProfile` to confirm `load_ster` (or `_cached_load_ster`) accounts for ≥80% of wall time.
If a different function dominates (e.g. `_synthetic_fit_from_bank` rebuilding repeatedly, or `_load_rescaled` reconstructing the dict), pause and re-plan: the cache may not buy what the design assumes.

### Step 1 --- bootstrap (Python, read-only against `.ster`)

Land `tools/results_overview/scrape_headlines.py` with `--incremental` and `--jobs N` flags.
Walk `RP7/output/*.ster`, call `load_ster()` once per main + `_n` + `_a` + `_g` subgroup file, write per-stem CSVs into `RP7/output/headlines/` via `os.replace` atomic rename.
Default `--jobs 1` (~30 min once); raise to `--jobs 4` only if it actually annoys someone.
Verify idempotency: re-run, confirm `git diff` is empty modulo `mtime` columns.

### Step 2 --- reader (dashboard side)

Rename existing `load_fit` to `_load_fit_live` (preserving its synthetic-bank fallback).
Add `_load_headlines()`, `_fit_from_cache_row()`, `_same_mtime()`, `EXPECTED_SCHEMA_VERSION` in `compare.py`.
Add the new cache-aware `load_fit()` that delegates to `_load_fit_live` on miss or staleness.
Re-render the dashboard.
Compare against the baseline from step 0 --- bytes-identical (modulo timestamps in the rendered footer) is the success criterion.

**Step 2 gate: cache-vs-live equivalence test.**
Add `tools/results_overview/test_cache_equivalence.py`: pick N=20 random stems, load each via the cache and via `_load_fit_live`, assert all eight headline values match within float tolerance (`rtol=1e-12`).
Run as a one-shot before declaring step 2 done.
Catches the "both paths agree for the wrong reason" failure that the bytes-identical-HTML test misses.

### Step 3 --- wire incremental refresh into the pipeline

Add a single line at the tail of `RP7/scripts/0_master.do` (and `run_master_resume.do`):

```stata
shell python "$dir/../tools/results_overview/scrape_headlines.py" --incremental
```

After every full or partial fit run, the cache stays fresh automatically.
No Stata-side schema mirror, no per-program capture windows, no `capture noisily` defenses.

For ad hoc re-fits (single cells via the MCP or interactively), the user runs `scrape_headlines.py --incremental` manually.

## What changes in the codebase

### New files

- `tools/results_overview/scrape_headlines.py` --- bootstrap script with `--incremental` and `--jobs N`.
- `tools/results_overview/test_cache_equivalence.py` --- step 2 gate.
- `RP7/output/headlines/<stem>.csv` --- one per fit, ~600 files.
- `quality_reports/baselines/2026-05-09_pre-cache.html` --- step 0 comparison artifact.

### Edited files

- `tools/results_overview/compare.py` --- renames existing `load_fit` to `_load_fit_live`; adds `_load_headlines`, `_fit_from_cache_row`, `_same_mtime`, `EXPECTED_SCHEMA_VERSION`; adds the new cache-aware `load_fit` wrapper.
- `RP7/scripts/0_master.do` and `RP7/scripts/run_master_resume.do` --- add the one-line `shell python ...` tail for incremental refresh.

### Untouched

- `tools/results_overview/scrape.py` --- still does the live `load_ster` work for cache misses, including the synthetic-bank fallback for `_r` fits.
- `RP7/scripts/0_programs.do` --- not touched.
  No in-Stata writer, no schema globals.
- All other `*GrRC*.do` scripts --- inherit nothing new.

### Gitignore

`RP7/output/headlines/` is gitignored, same as `*.ster`.
The cache is fully derivable from `.ster` files via `scrape_headlines.py`.
Tracking would create per-fit churn that pollutes diffs without adding signal.

## Open questions resolved during this design

- Atomic write strategy: Python `os.replace` only.
- Schema versioning: row-level `schema_version` column.
- Gitignore vs track: gitignored.
- `estimator` column: included now.
- `Delta_always` in cache: yes.
  Per-trajectory `Delta_d` remains out of scope.
- Bootstrap parallelization: `--jobs N` flag, default 1.
- `lru_cache` on `_load_headlines()`: dropped.
- Mtime invalidation: exact comparison via per-row source mtimes.
- Stata-side writer: dropped.
  Cache freshness via `--incremental` shell-out wired into master script tails.
- Cache-vs-live equivalence test: yes, as a step 2 gate.
- Manifest sidecar: dropped.
  `schema_version` lives in each row.
- `source` provenance column: dropped.
  `_r` stems use the existing bank fallback.
