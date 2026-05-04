"""Tier 2 byte-identity check for M3 + M4 + Phase 1b table refactor.

Runs after Tier 3 closes and `_smoke_tables_only.do` has regenerated all
tables under `RP7/output/tables/`. For every reference table in
`tests/reference/output/tables/`, extracts the tabular body and computes
a unified diff against the live table. Each diff hunk is classified:

    LABEL_FLIP       --- a `-Average $\\Delta$` cell paired with a
                         `+$\\bar{\\Delta}$` cell on the same row.
                         Expected from the Delta_avg rename (commit 5e2277c).

    BLANK_ROW        --- a removed line whose tabular cells are empty
                         (e.g. `&            &            \\\\`).
                         Expected from Phase 1b.6 (commit f68892e).

    ADDLINESPACE     --- a removed `\\addlinespace` line.
                         Expected from Phase 1b.6's esttab cleanup.

    UNEXPECTED       --- anything else.  These are regressions and
                         must be inspected.

Per-file unified diffs are written to
`RP7/output/tier2_diffs/<filename>.diff` for inspection.
The script's exit code is the count of files with at least one
UNEXPECTED hunk (0 = clean Tier 2 pass).

Usage:
    python tests/tier2_table_diff.py
    python tests/tier2_table_diff.py --filter CHN

The companion tool `tests/compare_tabular_bodies.py` does the simpler
exact-match check; this script supersedes it for the post-refactor
validation by adding diff classification.
"""
from __future__ import annotations

import argparse
import difflib
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REFERENCE_DIR = REPO_ROOT / "tests" / "reference" / "output" / "tables"
LIVE_DIR = REPO_ROOT / "RP7" / "output" / "tables"
DIFFS_DIR = REPO_ROOT / "RP7" / "output" / "tier2_diffs"

TABULAR_RE = re.compile(
    r"\\begin\{tabular\}.*?\\end\{tabular\}",
    flags=re.DOTALL,
)

LABEL_OLD = r"Average $\Delta$"
LABEL_NEW = r"$\bar{\Delta}$"

ADDLINESPACE_RE = re.compile(r"^\s*\\addlinespace\s*$")
BLANK_ROW_RE = re.compile(
    r"^\s*(?:&\s*)*\\\\\s*(?:\[[^\]]*\])?\s*$"
)
# Phase 1b.6 leaves an empty line where each `& & ... \\` row used to be
# (esttab does not delete the row; it blanks it). The diff hunk is (-1, +1):
# the removed line matches BLANK_ROW_RE and the added empty line is matched
# here so both sides of the hunk classify as BLANK_ROW.
EMPTY_LINE_RE = re.compile(r"^\s*$")


def extract_body(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8")
    m = TABULAR_RE.search(text)
    return m.group(0) if m else None


def classify_line(line: str) -> str:
    """Return a tag for a removed-or-added diff line.

    Pairing for LABEL_FLIP happens at the hunk level; this function
    only inspects a single line out of context.
    """
    bare = line[1:] if line and line[0] in "+-" else line
    if ADDLINESPACE_RE.match(bare):
        return "ADDLINESPACE"
    if BLANK_ROW_RE.match(bare) or EMPTY_LINE_RE.match(bare):
        return "BLANK_ROW"
    if LABEL_OLD in bare or LABEL_NEW in bare:
        return "LABEL_CANDIDATE"
    return "OTHER"


def classify_hunk(removed: list[str], added: list[str]) -> dict[str, int]:
    """Classify the lines in one diff hunk.

    Pairs `Average $\\Delta$` removals with `$\\bar{\\Delta}$` additions
    when they appear on rows that are otherwise byte-identical.
    """
    counts = {"LABEL_FLIP": 0, "BLANK_ROW": 0, "ADDLINESPACE": 0, "UNEXPECTED": 0}

    label_flip_pairs = []
    remaining_removed = []
    remaining_added = list(added)

    # LABEL_FLIP pairing: split each row at the first `&` (label cell
    # vs data cells). The data cells must match byte-equal across the
    # removed/added pair; the label cells must match modulo trailing
    # whitespace after substituting LABEL_OLD -> LABEL_NEW. esttab right-pads
    # the label cell to a fixed column width, so when the label contracts
    # (Average $\Delta$ -> $\bar{\Delta}$) the live line gets extra trailing
    # spaces in the label cell. A naive byte-equal compare on the full line
    # therefore misses the flip; the partition + rstrip handles that.
    for r in removed:
        bare_r = r[1:]
        if LABEL_OLD in bare_r and "&" in bare_r:
            r_label, sep, r_rest = bare_r.partition("&")
            if LABEL_OLD in r_label:
                target_label = r_label.replace(LABEL_OLD, LABEL_NEW).rstrip()
                matched_idx = None
                for j, a in enumerate(remaining_added):
                    bare_a = a[1:]
                    if "&" not in bare_a:
                        continue
                    a_label, _, a_rest = bare_a.partition("&")
                    if a_label.rstrip() == target_label and a_rest == r_rest:
                        matched_idx = j
                        break
                if matched_idx is not None:
                    label_flip_pairs.append((r, remaining_added.pop(matched_idx)))
                    continue
        remaining_removed.append(r)

    counts["LABEL_FLIP"] = len(label_flip_pairs)

    for r in remaining_removed:
        tag = classify_line(r)
        if tag in ("BLANK_ROW", "ADDLINESPACE"):
            counts[tag] += 1
        else:
            counts["UNEXPECTED"] += 1

    for a in remaining_added:
        tag = classify_line(a)
        if tag in ("BLANK_ROW", "ADDLINESPACE"):
            counts[tag] += 1
        else:
            counts["UNEXPECTED"] += 1

    return counts


def split_into_hunks(diff_lines: list[str]) -> list[tuple[list[str], list[str]]]:
    """Split a unified diff into (removed_lines, added_lines) pairs per hunk."""
    hunks: list[tuple[list[str], list[str]]] = []
    cur_removed: list[str] = []
    cur_added: list[str] = []
    in_hunk = False

    for line in diff_lines:
        if line.startswith("@@"):
            if in_hunk and (cur_removed or cur_added):
                hunks.append((cur_removed, cur_added))
            cur_removed, cur_added = [], []
            in_hunk = True
            continue
        if not in_hunk:
            continue
        if line.startswith("---") or line.startswith("+++"):
            continue
        if line.startswith("-"):
            cur_removed.append(line)
        elif line.startswith("+"):
            cur_added.append(line)

    if in_hunk and (cur_removed or cur_added):
        hunks.append((cur_removed, cur_added))
    return hunks


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--filter",
        default="",
        help="Substring filter; only compare files whose names contain this string.",
    )
    args = parser.parse_args()

    if not REFERENCE_DIR.exists():
        print(f"reference dir missing: {REFERENCE_DIR}", file=sys.stderr)
        return 2
    if not LIVE_DIR.exists():
        print(f"live dir missing: {LIVE_DIR}", file=sys.stderr)
        return 2
    DIFFS_DIR.mkdir(parents=True, exist_ok=True)

    totals = {"LABEL_FLIP": 0, "BLANK_ROW": 0, "ADDLINESPACE": 0, "UNEXPECTED": 0}
    files_clean: list[str] = []
    files_expected_only: list[tuple[str, dict[str, int]]] = []
    files_unexpected: list[tuple[str, dict[str, int]]] = []
    files_missing_live: list[str] = []

    for ref_path in sorted(REFERENCE_DIR.glob("*.tex")):
        if args.filter and args.filter not in ref_path.name:
            continue

        live_path = LIVE_DIR / ref_path.name
        if not live_path.exists():
            files_missing_live.append(ref_path.name)
            continue

        ref_body = extract_body(ref_path)
        live_body = extract_body(live_path)
        if ref_body is None or live_body is None:
            files_unexpected.append(
                (ref_path.name, {"LABEL_FLIP": 0, "BLANK_ROW": 0, "ADDLINESPACE": 0, "UNEXPECTED": -1})
            )
            continue

        ref_lines = ref_body.splitlines(keepends=False)
        live_lines = live_body.splitlines(keepends=False)
        if ref_lines == live_lines:
            files_clean.append(ref_path.name)
            continue

        diff = list(
            difflib.unified_diff(
                ref_lines,
                live_lines,
                fromfile=f"reference/{ref_path.name}",
                tofile=f"live/{ref_path.name}",
                lineterm="",
            )
        )
        diff_path = DIFFS_DIR / f"{ref_path.name}.diff"
        diff_path.write_text("\n".join(diff) + "\n", encoding="utf-8")

        file_counts = {"LABEL_FLIP": 0, "BLANK_ROW": 0, "ADDLINESPACE": 0, "UNEXPECTED": 0}
        for removed, added in split_into_hunks(diff):
            hunk_counts = classify_hunk(removed, added)
            for k, v in hunk_counts.items():
                file_counts[k] += v
                totals[k] += v

        if file_counts["UNEXPECTED"] > 0:
            files_unexpected.append((ref_path.name, file_counts))
        else:
            files_expected_only.append((ref_path.name, file_counts))

    print("=" * 64)
    print(f"Reference dir: {REFERENCE_DIR}")
    print(f"Live dir:      {LIVE_DIR}")
    print(f"Diffs dir:     {DIFFS_DIR}")
    if args.filter:
        print(f"Filter:        '{args.filter}'")
    print("-" * 64)
    print(f"  clean (byte-identical) : {len(files_clean)}")
    print(f"  expected diffs only    : {len(files_expected_only)}")
    print(f"  UNEXPECTED diffs       : {len(files_unexpected)}")
    print(f"  missing live           : {len(files_missing_live)}")
    print()
    print(f"  total LABEL_FLIP   : {totals['LABEL_FLIP']}")
    print(f"  total BLANK_ROW    : {totals['BLANK_ROW']}")
    print(f"  total ADDLINESPACE : {totals['ADDLINESPACE']}")
    print(f"  total UNEXPECTED   : {totals['UNEXPECTED']}")
    print()

    if files_clean:
        print("CLEAN:")
        for name in files_clean:
            print(f"  {name}")
        print()
    if files_expected_only:
        print("EXPECTED DIFFS ONLY (label flip / blank rows / addlinespace):")
        for name, counts in files_expected_only:
            print(f"  {name}  flip={counts['LABEL_FLIP']} blank={counts['BLANK_ROW']} als={counts['ADDLINESPACE']}")
        print()
    if files_unexpected:
        print("UNEXPECTED DIFFS (regressions; inspect diff files):")
        for name, counts in files_unexpected:
            unexpected = counts["UNEXPECTED"]
            print(f"  {name}  unexpected={unexpected}  flip={counts['LABEL_FLIP']} blank={counts['BLANK_ROW']} als={counts['ADDLINESPACE']}")
        print()
    if files_missing_live:
        print("MISSING IN LIVE (no .tex produced; ster missing or table skipped):")
        for name in files_missing_live:
            print(f"  {name}")
        print()

    return len(files_unexpected)


if __name__ == "__main__":
    sys.exit(main())
