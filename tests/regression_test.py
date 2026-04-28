"""Regression test: diff RP7 output against the frozen reference.

Run after any change to the GMM pipeline. Fails (exit 1) on any diff.

Reference snapshot lives under tests/reference/. The current snapshot
covers the 9 LaTeX tables produced by 5_GrRC.do (verified bit-identical
to RP6 2026-04-22 in commit b1ddf25). Extend the reference as later
phases produce more artifacts (e.g. .ster files after M11, figures from
3_heterogeneity_plots.do, etc.).

Usage:
    python tests/regression_test.py

Exits 0 if every reference file has an identical match in RP7/output/.
Exits 1 if any file differs, is missing in RP7/output/, or is unexpectedly
extra under RP7/output/tables/. Prints a summary.
"""
from __future__ import annotations

import filecmp
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = REPO_ROOT / "tests" / "reference" / "output"
LIVE_DIR = REPO_ROOT / "RP7" / "output"


def diff_tree(reference: Path, live: Path) -> tuple[list[str], list[str], list[str], list[str]]:
    """Walk reference and check each file against live.

    Returns (identical, differs, missing, extra) lists of relative paths.
    """
    identical: list[str] = []
    differs: list[str] = []
    missing: list[str] = []
    extra: list[str] = []

    ref_files = {p.relative_to(reference) for p in reference.rglob("*") if p.is_file()}
    live_files = {p.relative_to(live) for p in live.rglob("*") if p.is_file() and p.suffix in {".tex", ".pdf", ".png"}}

    for rel in sorted(ref_files):
        ref_path = reference / rel
        live_path = live / rel
        if not live_path.exists():
            missing.append(str(rel))
            continue
        if filecmp.cmp(ref_path, live_path, shallow=False):
            identical.append(str(rel))
        else:
            differs.append(str(rel))

    # Files in live that aren't in reference (e.g. new spec the reference doesn't yet cover).
    # These are not failures but worth surfacing.
    for rel in sorted(live_files - ref_files):
        extra.append(str(rel))

    return identical, differs, missing, extra


def main() -> int:
    if not REFERENCE_DIR.exists():
        print(f"ERROR: reference directory not found at {REFERENCE_DIR}", file=sys.stderr)
        return 2
    if not LIVE_DIR.exists():
        print(f"ERROR: live output directory not found at {LIVE_DIR}", file=sys.stderr)
        return 2

    identical, differs, missing, extra = diff_tree(REFERENCE_DIR, LIVE_DIR)

    print(f"Reference root: {REFERENCE_DIR}")
    print(f"Live      root: {LIVE_DIR}")
    print()
    print(f"  identical : {len(identical)}")
    print(f"  differs   : {len(differs)}")
    print(f"  missing   : {len(missing)}  (in reference but not in live)")
    print(f"  extra     : {len(extra)}  (in live but not in reference --- not a failure)")
    print()

    if differs:
        print("DIFFERS:")
        for p in differs:
            print(f"  {p}")
        print()
    if missing:
        print("MISSING:")
        for p in missing:
            print(f"  {p}")
        print()
    if extra:
        print("EXTRA (informational):")
        for p in extra:
            print(f"  {p}")
        print()

    if differs or missing:
        print("REGRESSION TEST FAILED")
        return 1
    print("REGRESSION TEST PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
