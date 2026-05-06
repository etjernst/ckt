"""Pivot demo_long.csv to demo_wide.csv for format comparison.

Long: one row per (ster, coefficient).  Easy for stacking many runs,
filtering by coefficient, or feeding to long-format plotting.

Wide: one row per ster, one column per coefficient (b_<name> and
se_<name>).  Easy for spreadsheet inspection and side-by-side
comparison of two runs.
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

HERE = Path(__file__).parent
LONG = HERE / "demo_long.csv"
WIDE = HERE / "demo_wide.csv"


def main() -> None:
    df = pd.read_csv(LONG)

    # Empty suffix -> NaN -> pivot_table silently drops the row.  Treat
    # missing suffix as the literal string "" so all sters survive.
    df["suffix"] = df["suffix"].fillna("")

    id_cols = ["ster", "country", "spec3", "covs2", "suffix", "N"]

    b = (
        df.pivot_table(index=id_cols, columns="coef_name", values="coef_value", aggfunc="first")
        .add_prefix("b_")
    )
    se = (
        df.pivot_table(index=id_cols, columns="coef_name", values="coef_se", aggfunc="first")
        .add_prefix("se_")
    )

    wide = pd.concat([b, se], axis=1).reset_index()

    # Keep b_<name> and se_<name> adjacent: interleave columns by base name.
    coef_names = sorted({c[2:] for c in wide.columns if c.startswith("b_")})
    interleaved: list[str] = []
    for name in coef_names:
        interleaved.append(f"b_{name}")
        interleaved.append(f"se_{name}")
    wide = wide[id_cols + interleaved]

    wide.to_csv(WIDE, index=False, na_rep="")
    print(f"Wrote {WIDE.name}: {len(wide)} rows x {len(wide.columns)} cols.")


if __name__ == "__main__":
    main()
