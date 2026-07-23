"""Keep-list agreement smoke for the post-run sanity sequence.

For each sample behind the twenty WCR11 cells, recompute the switcher
keep-list in Python (drop_sparse_switchers, threshold 5 both-state
individuals) and compare trajectory-by-trajectory against the
Stata-authored CSV the pipeline wrote to RP7/output/keeplists/.
Any disagreement in kept sets or both-state counts is a hard failure:
it means the data and the estimation contract drifted during the run.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from lca_inversion import drop_sparse_switchers  # noqa: E402

DATA = Path("C:/git/ckt/RP7/data/processed")
KEEP = Path("C:/git/ckt/RP7/output/keeplists")

SAMPLES = {
    "IDN_unb": "IDN_unb_keeplist.csv",
    "TZA_unb": "TZA_unb_keeplist.csv",
    "CHN_unb": "CHN_unb_keeplist.csv",
    "CHN_hukou_rural_first_unb": "CHN_hukou_rural_first_unb_keeplist.csv",
    "CHN_hukou_urban_first_unb": "CHN_hukou_urban_first_unb_keeplist.csv",
}


def main() -> int:
    failures = 0
    for stem, csv_name in SAMPLES.items():
        df = pd.read_stata(DATA / f"{stem}.dta", convert_categoricals=False,
                           columns=["pid", "trajectory", "choice"])
        df.loc[df["trajectory"] == 999, "trajectory"] = np.nan
        kept, counts = drop_sparse_switchers(
            df.dropna(subset=["pid", "choice"]), "trajectory", "choice", "pid"
        )

        ref = pd.read_csv(KEEP / csv_name)
        ref_kept = sorted(int(t) for t in ref.loc[ref["kept"] == 1, "trajectory"])
        ref_counts = {int(r.trajectory): int(r.n_both_states)
                      for r in ref.itertuples()}

        ok_kept = sorted(kept) == ref_kept
        ok_counts = all(counts.get(t) == c for t, c in ref_counts.items())
        status = "AGREE" if (ok_kept and ok_counts) else "DISAGREE"
        if status == "DISAGREE":
            failures += 1
        print(f"{stem}: {status}  "
              f"(python kept {sorted(kept)} vs stata kept {ref_kept})")
        if not ok_counts:
            diffs = {t: (counts.get(t), c) for t, c in ref_counts.items()
                     if counts.get(t) != c}
            print(f"  count differences (python, stata): {diffs}")
    print(f"\n{'PASS' if failures == 0 else 'FAIL'}: "
          f"{len(SAMPLES) - failures}/{len(SAMPLES)} samples agree")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
