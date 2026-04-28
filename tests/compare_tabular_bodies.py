"""Compare tabular bodies of live RP7 tables against RP6 references.

The references in tests/reference/output/tables/ are OLD-format
(table+threeparttable envelope + caption + label + tablenotes).
The live RP7 tables are SLIM (post-Phase 1b.3 trim --- tabular only).

Bit-identical diff is therefore not meaningful. This script extracts
the tabular body --- the substring between '\\begin{tabular}' and
'\\end{tabular}' inclusive --- from both files and compares those.

Usage:
    python tests/compare_tabular_bodies.py
    python tests/compare_tabular_bodies.py --dir output/tables  # restrict scope

Exit 0 if all live tables match references (or are missing in live);
exit 1 if any live table differs in tabular body from its reference.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = REPO_ROOT / "tests" / "reference" / "output" / "tables"
LIVE_DIR = REPO_ROOT / "RP7" / "output" / "tables"

TABULAR_RE = re.compile(
    r"\\begin\{tabular\}.*?\\end\{tabular\}",
    flags=re.DOTALL,
)


def extract_body(path: Path) -> str | None:
    """Return the tabular body of `path`, or None if no tabular is found."""
    text = path.read_text(encoding="utf-8")
    m = TABULAR_RE.search(text)
    if m is None:
        return None
    return m.group(0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter; only compare files whose names contain this string.",
    )
    args = parser.parse_args()

    if not REFERENCE_DIR.exists():
        print(f"reference dir missing: {REFERENCE_DIR}")
        return 1
    if not LIVE_DIR.exists():
        print(f"live dir missing: {LIVE_DIR}")
        return 1

    matched: list[str] = []
    differed: list[tuple[str, str, str]] = []
    missing_live: list[str] = []
    no_body_ref: list[str] = []
    no_body_live: list[str] = []

    for ref_path in sorted(REFERENCE_DIR.glob("*.tex")):
        if args.filter and args.filter not in ref_path.name:
            continue
        live_path = LIVE_DIR / ref_path.name
        if not live_path.exists():
            missing_live.append(ref_path.name)
            continue

        ref_body = extract_body(ref_path)
        live_body = extract_body(live_path)
        if ref_body is None:
            no_body_ref.append(ref_path.name)
            continue
        if live_body is None:
            no_body_live.append(ref_path.name)
            continue

        if ref_body == live_body:
            matched.append(ref_path.name)
        else:
            # Compute a brief preview of the first diff line.
            ref_lines = ref_body.splitlines()
            live_lines = live_body.splitlines()
            preview_ref = ""
            preview_live = ""
            for i, (rline, lline) in enumerate(zip(ref_lines, live_lines)):
                if rline != lline:
                    preview_ref = f"L{i+1} ref:  {rline[:120]}"
                    preview_live = f"L{i+1} live: {lline[:120]}"
                    break
            else:
                # One is shorter than the other.
                if len(ref_lines) > len(live_lines):
                    preview_ref = f"L{len(live_lines)+1} ref:  {ref_lines[len(live_lines)][:120]}"
                    preview_live = "L? live: <missing line>"
                else:
                    preview_ref = "L? ref:  <missing line>"
                    preview_live = f"L{len(ref_lines)+1} live: {live_lines[len(ref_lines)][:120]}"
            differed.append((ref_path.name, preview_ref, preview_live))

    print("=" * 60)
    print(f"Reference dir: {REFERENCE_DIR}")
    print(f"Live dir:      {LIVE_DIR}")
    if args.filter:
        print(f"Filter:        '{args.filter}'")
    print("-" * 60)
    print(f"  matched         : {len(matched)}")
    print(f"  differed        : {len(differed)}")
    print(f"  missing in live : {len(missing_live)}")
    print(f"  ref no body     : {len(no_body_ref)}")
    print(f"  live no body    : {len(no_body_live)}")
    print()

    if matched:
        print("MATCHED (tabular body identical):")
        for name in matched:
            print(f"  {name}")
        print()
    if differed:
        print("DIFFERED (tabular body differs):")
        for name, p_ref, p_live in differed:
            print(f"  {name}")
            print(f"    {p_ref}")
            print(f"    {p_live}")
        print()
    if missing_live:
        print("MISSING IN LIVE (no .tex produced; ster missing or table skipped):")
        for name in missing_live:
            print(f"  {name}")
        print()
    if no_body_ref or no_body_live:
        print("NO TABULAR BODY (file lacks \\begin{tabular}):")
        for name in no_body_ref:
            print(f"  ref:  {name}")
        for name in no_body_live:
            print(f"  live: {name}")
        print()

    return 1 if differed else 0


if __name__ == "__main__":
    sys.exit(main())
