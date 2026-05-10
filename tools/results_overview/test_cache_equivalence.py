"""Step 2 gate: cache-vs-live equivalence on N=20 random stems.

Loads each stem twice --- once via the cache-aware `load_fit()` and once
via `_load_fit_live()` --- and asserts that all eight headline values
(`b_phi`, `se_phi`, `b_delta_never`, `se_delta_never`, `b_delta_always`,
`se_delta_always`, `b_delta_avg`, `se_delta_avg`) match within float
tolerance.

Catches the failure mode that bytes-identical HTML can mask: both paths
agree because both are reading the same wrong source. CSV round-trip
loses ~2 digits of precision at the float64 boundary, so we use rtol=1e-12.

Usage (from tools/results_overview/):
    python test_cache_equivalence.py
    python test_cache_equivalence.py --n 50 --seed 0
"""

from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

import compare


def _eight(fit: compare.Fit) -> dict[str, float | None]:
    """Pull the eight headline scalars off a Fit, treating missing as None."""

    def _get(rec, idx, key):
        if rec is None or key not in rec.b.index:
            return None
        v = float(getattr(rec, idx)[key])
        return None if math.isnan(v) else v

    return {
        "b_phi": _get(fit.main, "b", "phi:_cons"),
        "se_phi": _get(fit.main, "se", "phi:_cons"),
        "b_delta_never": _get(fit.n_rec, "b", "Delta_never"),
        "se_delta_never": _get(fit.n_rec, "se", "Delta_never"),
        "b_delta_always": _get(fit.a_rec, "b", "Delta_always"),
        "se_delta_always": _get(fit.a_rec, "se", "Delta_always"),
        "b_delta_avg": _get(fit.g_rec, "b", "Delta_avg"),
        "se_delta_avg": _get(fit.g_rec, "se", "Delta_avg"),
    }


def _close(a: float | None, b: float | None, rtol: float, atol: float) -> bool:
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    return abs(a - b) <= atol + rtol * max(abs(a), abs(b))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=20)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--rtol", type=float, default=1e-12)
    parser.add_argument("--atol", type=float, default=1e-15)
    parser.add_argument(
        "--output-dir", type=Path,
        default=Path(__file__).resolve().parents[2] / "RP7" / "output",
    )
    args = parser.parse_args(argv)

    cache_dir = args.output_dir / "headlines"
    csvs = sorted(cache_dir.glob("*.csv"))
    if len(csvs) == 0:
        print(f"FAIL: no cache CSVs in {cache_dir}", file=sys.stderr)
        return 1

    rng = random.Random(args.seed)
    sample = rng.sample(csvs, k=min(args.n, len(csvs)))
    stems = [p.stem for p in sample]

    failures: list[tuple[str, str, float | None, float | None]] = []
    for full_stem in stems:
        # Split off `_r` if present, since load_fit's signature is (stem, vsfx).
        vsfx = "_r" if full_stem.endswith("_r") else ""
        stem = full_stem[: -len(vsfx)] if vsfx else full_stem

        cached = compare.load_fit(stem, output_dir=args.output_dir, vsfx=vsfx)
        live = compare._load_fit_live(stem, output_dir=args.output_dir, vsfx=vsfx)
        h_cached = _eight(cached)
        h_live = _eight(live)
        for k in h_cached:
            if not _close(h_cached[k], h_live[k], args.rtol, args.atol):
                failures.append((full_stem, k, h_cached[k], h_live[k]))

    print(f"checked {len(stems)} stems x 8 values = {len(stems)*8} comparisons")
    print(f"  rtol={args.rtol}, atol={args.atol}")

    if failures:
        print(f"FAIL: {len(failures)} mismatches:", file=sys.stderr)
        for stem, k, c, l in failures[:20]:
            print(f"  {stem} {k}: cache={c!r}  live={l!r}", file=sys.stderr)
        if len(failures) > 20:
            print(f"  ... and {len(failures) - 20} more", file=sys.stderr)
        return 1

    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
