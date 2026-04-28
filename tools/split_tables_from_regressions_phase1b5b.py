"""tools/split_tables_from_regressions_phase1b5b.py

Phase 1b.5b: strip the duplicated table-creation sections from
5/6/8_GrRC*.do (now lives in their _tables.do siblings).

Strips, for each file:
  - Every "* Add statistics and table markers" block (estimates use/store
    loops + estimates table display)
  - Every "* Make bootiful latex table" block (per-country grc_tex_table_trend
    calls + copyOverleaf)

These blocks are now in:
  5_GrRC_tables.do, 6_GrRC_NonAg_tables.do, 8_GrRC_hukou_tables.do

Idempotent: re-running on already-stripped files is a no-op.
"""
import re
from pathlib import Path

ROOT = Path(__file__).parent.parent.resolve()
SCRIPTS = ROOT / "RP7" / "scripts"

REPLACEMENT = """* **********************************************************************
* Tables for this section are produced by the sibling _tables.do file
* (reads existing .ster files via grc_tex_table_trend's internal load).
* Run that separately to refresh tables without re-running GMM.
* **********************************************************************
"""


def strip_table_blocks(text):
    """Strip every "* Add statistics and table markers" through the trailing
    "* Make bootiful latex table" block (ending at the last copyOverleaf
    closing `}` before the next major section marker or log close).

    Strategy: find each "* Add statistics and table markers" header and
    delete from there to (but not including) the next line beginning with
    either "* **********" + "* N. " section marker, OR "log close" line.
    """
    # Pattern: starts at the section banner, ends just before the next
    # section banner (or log close at EOF).
    pattern = re.compile(
        r'\* \*{20,}\s*\n\* Add statistics and table markers\s*\n\* \*{20,}\s*\n'  # banner
        r'.*?'  # everything in between (DOTALL)
        r'(?=\* \*{20,}\s*\n\* (\d+\. |log close)|^log close)',
        re.DOTALL | re.MULTILINE,
    )
    new_text, n = pattern.subn(REPLACEMENT + "\n", text)
    return new_text, n


def main():
    for fname in ["5_GrRC.do", "6_GrRC_NonAg.do", "8_GrRC_hukou.do"]:
        path = SCRIPTS / fname
        text = path.read_bytes().decode("utf-8")
        new_text, n = strip_table_blocks(text)
        if n > 0:
            path.write_bytes(new_text.encode("utf-8"))
            print(f"{fname}: stripped {n} table block(s)")
        else:
            print(f"{fname}: no changes (already stripped or pattern not found)")


if __name__ == "__main__":
    main()
