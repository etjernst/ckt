"""Bootstrap the headlines cache for the GRC dashboard.

Walks `RP7/output/*.ster`, extracts the headline values from each main fit
plus its `_n` / `_a` / `_g` subgroups, and writes one CSV per stem to
`RP7/output/headlines/<stem>.csv` via `os.replace` atomic rename.

The cache is a derived artifact: it can always be rebuilt from the on-disk
`.ster` files. The dashboard reader (`compare.py`) uses it to short-circuit
`load_fit()` and skip the pystata IPC round-trip that dominates render time.

Usage (from anywhere; `--output-dir` defaults to RP7/output relative to the
script):

    python tools/results_overview/scrape_headlines.py
    python tools/results_overview/scrape_headlines.py --incremental
    python tools/results_overview/scrape_headlines.py --jobs 4

`--incremental` skips stems whose cached CSV mtimes already match every
source ster mtime; useful as a tail-of-pipeline refresh.

`--jobs N` parallelizes across worker subprocesses (each spawning its own
pystata kernel). Default is 1 because a 30-minute one-time bootstrap is
cheap enough that the speedup is rarely worth the added complexity.
"""

from __future__ import annotations

import argparse
import multiprocessing
import os
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scrape import _FILENAME_RE, load_ster, parse_filename  # noqa: E402

SCHEMA_VERSION = 1

DEFAULT_OUTPUT_DIR = Path(__file__).resolve().parents[2] / "RP7" / "output"

# Fixed column order. The reader's `EXPECTED_SCHEMA_VERSION` and column
# expectations key off this list; a schema bump means changing both this
# list and the reader's `_fit_from_cache_row` together.
COLUMN_ORDER: list[str] = [
    "schema_version",
    "stem", "country", "spec3", "depvar", "choice", "balance",
    "covs2", "family", "hukou", "values",
    "estimator",
    "main_mtime", "n_mtime", "a_mtime", "g_mtime",
    "b_phi", "se_phi",
    "b_delta_never", "se_delta_never",
    "b_delta_always", "se_delta_always",
    "b_delta_avg", "se_delta_avg",
    "J_p", "N", "runtime_s", "converged",
]


def _is_main_ster(path: Path) -> bool:
    """A 'main' ster has the form `grc_*[_<family>]_<cov>[_r].ster` with no
    `_n` / `_a` / `_d` / `_g` subgroup suffix.
    """
    m = _FILENAME_RE.match(path.name)
    return m is not None and not m.group("suffix")


def _subgroup_path(main_path: Path, suffix: str) -> Path:
    """Build an `_n` / `_a` / `_g` path from a main ster path.

    The `_r` values marker (if present) sits at the very end of the stem,
    after the suffix, so we splice the new suffix in before it:
        grc_IDN_cuu_c0.ster      + 'n' -> grc_IDN_cuu_c0_n.ster
        grc_IDN_cuu_c0_r.ster    + 'n' -> grc_IDN_cuu_c0_n_r.ster
    """
    stem = main_path.stem
    if stem.endswith("_r"):
        return main_path.with_name(f"{stem[:-2]}_{suffix}_r.ster")
    return main_path.with_name(f"{stem}_{suffix}.ster")


def _mtime_iso(path: Path) -> str:
    """Return ISO-8601 mtime for `path`, or empty string if it doesn't exist."""
    if not path.exists():
        return ""
    return datetime.fromtimestamp(path.stat().st_mtime).isoformat(timespec="microseconds")


def _row_for_stem(main_path: Path) -> dict:
    """Build one cache row by loading main + _n + _a + _g.

    Subgroup files that do not exist contribute NaN to their headline
    columns and an empty string to their mtime column.
    """
    meta = parse_filename(main_path)

    n_path = _subgroup_path(main_path, "n")
    a_path = _subgroup_path(main_path, "a")
    g_path = _subgroup_path(main_path, "g")

    main_rec = load_ster(main_path)
    n_rec = load_ster(n_path) if n_path.exists() else None
    a_rec = load_ster(a_path) if a_path.exists() else None
    g_rec = load_ster(g_path) if g_path.exists() else None

    nan = float("nan")

    def _b(rec, key):
        if rec is None or key not in rec.b.index:
            return nan
        return float(rec.b[key])

    def _se(rec, key):
        if rec is None or key not in rec.se.index:
            return nan
        return float(rec.se[key])

    return {
        "schema_version": SCHEMA_VERSION,
        "stem": main_path.stem,
        "country": meta["country"],
        "spec3": meta["spec3"],
        "depvar": meta["depvar"],
        "choice": meta["choice"],
        "balance": meta["balance"],
        "covs2": meta["covs2"],
        "family": meta["family"],
        "hukou": meta["hukou"] or "",
        "values": meta["values"],
        "estimator": "run_grc",
        "main_mtime": _mtime_iso(main_path),
        "n_mtime": _mtime_iso(n_path),
        "a_mtime": _mtime_iso(a_path),
        "g_mtime": _mtime_iso(g_path),
        "b_phi": _b(main_rec, "phi:_cons"),
        "se_phi": _se(main_rec, "phi:_cons"),
        "b_delta_never": _b(n_rec, "Delta_never"),
        "se_delta_never": _se(n_rec, "Delta_never"),
        "b_delta_always": _b(a_rec, "Delta_always"),
        "se_delta_always": _se(a_rec, "Delta_always"),
        "b_delta_avg": _b(g_rec, "Delta_avg"),
        "se_delta_avg": _se(g_rec, "Delta_avg"),
        "J_p": main_rec.J_p if main_rec.J_p is not None else nan,
        "N": main_rec.N if main_rec.N is not None else nan,
        "runtime_s": main_rec.runtime_s if main_rec.runtime_s is not None else nan,
        "converged": main_rec.converged if main_rec.converged is not None else nan,
    }


def _write_row(row: dict, cache_dir: Path) -> Path:
    """Write a one-row CSV to `cache_dir/<stem>.csv` via atomic rename."""
    target = cache_dir / f"{row['stem']}.csv"
    tmp = target.with_suffix(".csv.tmp")
    df = pd.DataFrame([row], columns=COLUMN_ORDER)
    df.to_csv(tmp, index=False, lineterminator="\n")
    os.replace(tmp, target)
    return target


def _is_fresh(main_path: Path, csv_path: Path) -> bool:
    """True if `csv_path` exists and its recorded mtimes match the live
    source mtimes for main + _n + _a + _g exactly.
    """
    if not csv_path.exists():
        return False
    try:
        df = pd.read_csv(csv_path, dtype=str, keep_default_na=False)
    except (pd.errors.EmptyDataError, pd.errors.ParserError):
        return False
    if len(df) != 1:
        return False
    if df.loc[0, "schema_version"] != str(SCHEMA_VERSION):
        return False
    paths = {
        "main": main_path,
        "n": _subgroup_path(main_path, "n"),
        "a": _subgroup_path(main_path, "a"),
        "g": _subgroup_path(main_path, "g"),
    }
    for k, p in paths.items():
        if df.loc[0, f"{k}_mtime"] != _mtime_iso(p):
            return False
    return True


def _scrape_stem(main_path: Path, cache_dir: Path) -> tuple[bool, str | None]:
    """Scrape one stem; return (wrote_row, error_message).

    Errors are caught and returned, never raised, so a single malformed
    ster doesn't kill the whole bootstrap.
    """
    try:
        row = _row_for_stem(main_path)
        _write_row(row, cache_dir)
    except Exception as e:
        return False, f"{main_path.name}: {type(e).__name__}: {e}"
    return True, None


def _scrape_worker(arg: tuple[str, str]) -> tuple[bool, str | None]:
    """Pickleable worker for multiprocessing.Pool.

    Each worker process re-imports `scrape`, which initializes its own
    pystata kernel on first call. That is the entire point of fanning
    out across processes (pystata is single-kernel per process).
    """
    main_path_str, cache_dir_str = arg
    return _scrape_stem(Path(main_path_str), Path(cache_dir_str))


def _orphan_cleanup(output_dir: Path, cache_dir: Path) -> list[Path]:
    """Delete cached CSVs whose source main ster no longer exists.

    Returns the list of deleted paths (for logging).
    """
    deleted: list[Path] = []
    for csv in cache_dir.glob("*.csv"):
        stem = csv.stem
        if not (output_dir / f"{stem}.ster").exists():
            csv.unlink()
            deleted.append(csv)
    return deleted


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", maxsplit=1)[0])
    parser.add_argument(
        "--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR,
        help=f"directory containing *.ster files (default: {DEFAULT_OUTPUT_DIR})",
    )
    parser.add_argument(
        "--incremental", action="store_true",
        help="skip stems whose cached CSV already matches every source mtime",
    )
    parser.add_argument(
        "--jobs", type=int, default=1, metavar="N",
        help="parallelize across N worker subprocesses (default: 1)",
    )
    parser.add_argument(
        "--no-orphan-cleanup", action="store_true",
        help="skip deleting cache files whose source ster no longer exists",
    )
    parser.add_argument(
        "--verbose", action="store_true",
        help="log each stem as it is scraped",
    )
    args = parser.parse_args(argv)

    output_dir: Path = args.output_dir.resolve()
    cache_dir = output_dir / "headlines"
    cache_dir.mkdir(exist_ok=True)

    main_paths = sorted(p for p in output_dir.glob("*.ster") if _is_main_ster(p))
    n_total = len(main_paths)

    if args.incremental:
        main_paths = [p for p in main_paths if not _is_fresh(p, cache_dir / f"{p.stem}.csv")]

    n_to_scrape = len(main_paths)
    print(
        f"scrape_headlines: {n_total} main sters in {output_dir}; "
        f"{n_to_scrape} to scrape (jobs={args.jobs}, incremental={args.incremental})",
        flush=True,
    )

    errors: list[str] = []
    n_written = 0
    if args.jobs > 1 and n_to_scrape > 0:
        worker_args = [(str(p), str(cache_dir)) for p in main_paths]
        with multiprocessing.Pool(args.jobs) as pool:
            for wrote, err in pool.imap_unordered(_scrape_worker, worker_args):
                if wrote:
                    n_written += 1
                if err:
                    errors.append(err)
    else:
        for p in main_paths:
            wrote, err = _scrape_stem(p, cache_dir)
            if wrote:
                n_written += 1
                if args.verbose:
                    print(f"  wrote {p.stem}.csv", flush=True)
            if err:
                errors.append(err)

    print(f"  wrote {n_written} cache rows", flush=True)
    if errors:
        print(f"  {len(errors)} errors:", flush=True)
        for e in errors[:10]:
            print(f"    {e}", flush=True)
        if len(errors) > 10:
            print(f"    ... and {len(errors) - 10} more", flush=True)

    if not args.no_orphan_cleanup:
        deleted = _orphan_cleanup(output_dir, cache_dir)
        print(f"  cleaned up {len(deleted)} orphan cache files", flush=True)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
