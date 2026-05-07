"""tools/captions_to_paper_phase1b3.py

Phase 1b.3: strip caption / label / notes / htb / prehead boilerplate
from GRC do-files and shorten postfoot_str to indicator-rows-only.

The wrapper-and-notes pieces (caption, label, table envelope, tablenotes)
now live in paper-side macros (\\GRCtable / \\GRCexptable / \\GRChukoutable
in ReturnsToMigration-clean/preamble.tex). The .do output is now slim
tabular-only:
    \\begin{tabular}{l ccccc}\\toprule \\textbf{Dep. var:} ...
    <body rows>
    \\cmidrule{2-N}
    Time FE & ... \\\\
    Covariates & ... \\\\
    \\bottomrule\\end{tabular}

Touches:
    5_GrRC.do, 6_GrRC_NonAg.do, 8_GrRC_hukou.do,
    10/11/12/13/14/15_GrRC_*.do, 16_heterogeneity_tables.do.

Run from worktree root:
    python tools/captions_to_paper_phase1b3.py

Idempotent: re-running on already-stripped files leaves them unchanged
(the patterns to delete are no longer present, regex .subn returns 0).
"""
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent.resolve()
SCRIPTS = ROOT / "RP7" / "scripts"

FILES = [
    "5_GrRC.do",
    "6_GrRC_NonAg.do",
    "8_GrRC_hukou.do",
    "10_GrRC_experience.do",
    "11_GrRC_max_experience.do",
    "12_GrRC_experience_share.do",
    "13_GrRC_max_experience_share.do",
    "14_GrRC_NonAg_experience.do",
    "15_GrRC_birth.do",
    "16_heterogeneity_tables.do",
]


def transform(text):
    """Apply Phase 1b.3 transformations. Returns (new_text, count_dict)."""
    counts = {}

    # 1. Delete `local htb_str "..."` lines.
    text, counts["htb_str"] = re.subn(
        r'^local htb_str\s+"[^"]*"\s*\n', '', text, flags=re.MULTILINE
    )

    # 2. Delete `* Table caption` comment + `local table_caption "..."`.
    text, n1 = re.subn(
        r'^\*\s*Table caption\s*\n^local table_caption\s.*\n',
        '', text, flags=re.MULTILINE,
    )
    text, n2 = re.subn(
        r'^local table_caption\s.*\n', '', text, flags=re.MULTILINE
    )
    counts["table_caption"] = n1 + n2

    # 3. Delete `* Table label` comment + `local table_label "..."`.
    text, n1 = re.subn(
        r'^\*\s*Table label\s*\n^local table_label\s.*\n',
        '', text, flags=re.MULTILINE,
    )
    text, n2 = re.subn(
        r'^local table_label\s.*\n', '', text, flags=re.MULTILINE
    )
    counts["table_label"] = n1 + n2

    # 4. Delete `* Define prehead and postfoot strings` orphan comment +
    #    `* Table notes` + `local table_notes "..."`.
    text, n1 = re.subn(
        r'^\*\s*Define prehead and postfoot strings\s*\n\s*\n',
        '', text, flags=re.MULTILINE,
    )
    text, n2 = re.subn(
        r'^\*\s*Table notes\s*\n^local table_notes\s.*\n',
        '', text, flags=re.MULTILINE,
    )
    text, n3 = re.subn(
        r'^local table_notes\s.*\n', '', text, flags=re.MULTILINE
    )
    counts["table_notes"] = n1 + n2 + n3

    # 5. Shorten postfoot_str: chop tail starting from ` \bottomrule`.
    # Greedy `.*\\\\` captures through the LAST `\\` (LaTeX line break)
    # before `\bottomrule`, preserving the indicator rows including
    # their trailing `\\`.
    text, counts["postfoot_str"] = re.subn(
        r'(^local postfoot_str\s.*\\\\)\s*\\bottomrule.*$',
        r'\1', text, flags=re.MULTILINE,
    )

    # 6. Remove `* Table footer` orphan comment (was sibling to postfoot_str).
    text, counts["table_footer_comment"] = re.subn(
        r'^\*\s*Table footer\s*\n', '', text, flags=re.MULTILINE
    )

    # 7. Remove `htb(`htb_str') ///` argument lines from caller calls.
    text, counts["htb_arg"] = re.subn(
        r'^\s*htb\(`htb_str\'\)[^\n]*\n',
        '', text, flags=re.MULTILINE,
    )

    # 8. Remove `prehead(`table_caption' `table_label') ///` argument lines.
    text, counts["prehead_arg"] = re.subn(
        r"^\s*prehead\(`table_caption' `table_label'\)[^\n]*\n",
        '', text, flags=re.MULTILINE,
    )

    return text, counts


def main():
    grand_total = 0
    for fname in FILES:
        path = SCRIPTS / fname
        text = path.read_bytes().decode("utf-8")
        new_text, counts = transform(text)
        n = sum(counts.values())
        grand_total += n
        if n > 0:
            path.write_bytes(new_text.encode("utf-8"))
            details = ", ".join(f"{k}={v}" for k, v in counts.items() if v > 0)
            print(f"{fname}: {n} substitutions ({details})")
        else:
            print(f"{fname}: no changes")
    print(f"\nGrand total: {grand_total} substitutions across {len(FILES)} files.")
    print("Run a Tier 1 grep audit next, then Tier 2 verify.")


if __name__ == "__main__":
    main()
