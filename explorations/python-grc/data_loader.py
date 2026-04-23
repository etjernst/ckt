"""Load processed CKT panel data for the Python GRC port.

Mirrors the variable construction done in Stata's ``5_GrRC.do`` for the
consumption-urban specification:

    use IDN_unb.dta
    replace lndepvar = log(consumption/hhsize_cube)
    setup_grc_estimation   // recodes trajectory == . to 999 for unbalanced
    tab period, gen(period_)

Unbalanced observers have a missing trajectory label. We preserve that as
NaN so the moment code below can zero out their trajectory indicators.
Nothing is imputed.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd


# The repo convention is that data/ is a directory junction to the current
# ReplicationPackage{N}/data/ folder. Resolve relative to the project root.
HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent  # explorations/python-grc -> project root
DATA_ROOT = PROJECT_ROOT / "data" / "processed"

# Fallback: main working tree (this worktree may not have the data
# junction). The wrapper repo at C:/git/ckt always has the junction.
FALLBACK_DATA_ROOT = Path("C:/git/ckt/data/processed")


def _resolve_data_root() -> Path:
    if DATA_ROOT.exists():
        return DATA_ROOT
    if FALLBACK_DATA_ROOT.exists():
        return FALLBACK_DATA_ROOT
    raise FileNotFoundError(
        f"Could not find data/processed at either {DATA_ROOT} or "
        f"{FALLBACK_DATA_ROOT}. Ensure the junction is set up."
    )


def load_consumption_unb(country: str = "IDN") -> pd.DataFrame:
    """Load the unbalanced-panel consumption dataset for ``country``.

    Returns a DataFrame with columns for the estimator:
        lndepvar, choice, trajectory, pid, period, period_2 ... period_T,
        female, age, age2, education_max, education_max2,
        unbalanced, unbalanced_choice.

    ``trajectory`` is float with NaN for unbalanced observers.
    """
    data_root = _resolve_data_root()
    path = data_root / f"{country}_unb.dta"
    df = pd.read_stata(path, convert_categoricals=False)

    n0 = len(df)

    # Replace lndepvar with log consumption per capita (per 5_GrRC.do line 64).
    with np.errstate(invalid="ignore", divide="ignore"):
        df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])

    # Drop rows where the outcome or choice is missing. Stata's gmm silently
    # drops them. We do not impute missing values; trajectory may be NaN
    # (unbalanced observers) and is preserved as NaN.
    keep = df["lndepvar"].notna() & df["choice"].notna()
    df = df.loc[keep].copy()
    n1 = len(df)
    dropped = n0 - n1
    if dropped:
        print(
            f"[data_loader] Dropped {dropped} rows with missing outcome or choice.",
            file=sys.stderr,
        )

    # Build period dummies period_2 ... period_T, dropping period_1.
    periods = sorted(int(p) for p in df["period"].dropna().unique())
    for p in periods:
        df[f"period_{p}"] = (df["period"] == p).astype(float)
    # Drop the omitted baseline period dummy (Stata periodFE starts at period_2).
    df = df.drop(columns=[f"period_{periods[0]}"])

    # ``unbalanced`` and ``unbalanced_choice`` are in the .dta; recompute
    # the interaction for safety.
    df["unbalanced_choice"] = df["unbalanced"] * df["choice"]

    return df


def period_fe_columns(df: pd.DataFrame) -> list[str]:
    """Return period dummy column names in sorted order."""
    return sorted(
        [c for c in df.columns if c.startswith("period_")],
        key=lambda s: int(s.split("_")[1]),
    )


def _sanity_check(country: str = "IDN") -> None:
    df = load_consumption_unb(country)
    n_ind = df["pid"].nunique()
    n_obs = len(df)
    traj_counts = df.groupby("pid")["trajectory"].first().value_counts(dropna=False)
    n_traj = traj_counts.index.dropna().size
    print(f"Country: {country}")
    print(f"  n_individuals = {n_ind}")
    print(f"  n_observations = {n_obs}")
    print(f"  n_trajectories (non-missing) = {n_traj}")
    print(f"  n_unbalanced_individuals = "
          f"{int(traj_counts.get(np.nan, 0))}")
    print("  trajectory sizes (top 10):")
    print(traj_counts.head(10).to_string())


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Sanity-check the GRC data loader.")
    parser.add_argument("--country", default="IDN")
    args = parser.parse_args()
    _sanity_check(args.country)
