"""V2 milestone: Option 1 misallocation gap at the point estimate.

Reads the CSVs produced by RP7/scripts/_export_e1_inputs.do, assembles a
trajectory-level (Delta_d, pi_d, Dbar_d) vector per country, calls
counterfactuals.evaluate_aggregate, and reports the resulting aggregate.

The V2 gate in the plan calls this a code-consistency check (not a
magnitude validation): does the production code reproduce the back-of-
envelope arithmetic from the 2026-05-13 memo on the same inputs?
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

# Make the python-grc helper module importable.
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "python-grc"))

from counterfactuals import evaluate_aggregate, log_to_pct  # noqa: E402

INPUTS_DIR = Path(
    "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_inputs"
)

COUNTRIES = ["IDN", "TZA"]


def load_country(country: str) -> dict:
    """Load the four CSVs for a country and return a merged frame."""
    traj = pd.read_csv(INPUTS_DIR / f"{country}_e1_traj.csv")
    mu_d = pd.read_csv(INPUTS_DIR / f"{country}_e1_mu_d.csv")
    delta_d = pd.read_csv(INPUTS_DIR / f"{country}_e1_delta_d.csv")
    scalars = pd.read_csv(INPUTS_DIR / f"{country}_e1_scalars.csv")

    # Reshape scalars to a dict for easy access.
    scalar_dict: dict = {}
    for _, row in scalars.iterrows():
        name = row["name"]
        val = row["value"]
        try:
            scalar_dict[name] = float(val)
        except (TypeError, ValueError):
            scalar_dict[name] = val

    df = traj.merge(mu_d, on="traj_for_agg", how="left")
    df = df.merge(
        delta_d.rename(columns={"trajectory": "traj_for_agg"}),
        on="traj_for_agg",
        how="left",
    )

    # Assemble Delta_d per trajectory:
    #   traj 1 = d_N: use the inversion-derived Delta_dN
    #   traj == max(traj): d_T, use the inversion-derived Delta_dT
    #   traj == -1: lumped unbalanced switchers, use unb_choice_hat
    #   else: balanced switchers, use the unrestricted Delta from _d ster
    max_traj = int(df["traj_for_agg"].max())

    def assign_delta(row):
        t = int(row["traj_for_agg"])
        if t == 1:
            return scalar_dict["inv_dN"]
        if t == max_traj:
            return scalar_dict["inv_dT"]
        if t == -1:
            return scalar_dict["unb_choice_hat"]
        return row["delta_d_unrestricted"]

    df["delta_d_use"] = df.apply(assign_delta, axis=1)

    # Drop trajectories with NaN pi or Delta (shouldn't happen, but guard).
    df = df.dropna(subset=["pi_d", "dbar_d", "delta_d_use"]).reset_index(drop=True)

    return {"frame": df, "scalars": scalar_dict, "max_traj": max_traj}


def label_trajectory(t: int, max_traj: int) -> str:
    if t == -1:
        return "lumped switcher"
    if t == 1:
        return "d_N (never)"
    if t == max_traj:
        return "d_T (always)"
    return f"switcher {t}"


def report_country(country: str) -> None:
    print(f"\n{'=' * 64}")
    print(f"==== {country}")
    print(f"{'=' * 64}")

    payload = load_country(country)
    df = payload["frame"]
    scalars = payload["scalars"]
    max_traj = payload["max_traj"]

    df["label"] = df["traj_for_agg"].apply(
        lambda t: label_trajectory(int(t), max_traj)
    )

    print(f"\nKey scalars at point estimate:")
    print(f"  phi_hat  = {scalars['phi_hat']:+.4f}")
    print(f"  beta_hat = {scalars['beta_hat']:+.4f}")
    print(f"  inv_dN   = {scalars['inv_dN']:+.4f}")
    print(f"  inv_dT   = {scalars['inv_dT']:+.4f}")
    print(f"  J = {scalars['j_stat']:.3f}  df = {int(scalars['j_df'])}  p = {scalars['j_pval']:.3f}")

    print(f"\nTrajectory-level inputs:")
    cols = ["label", "traj_for_agg", "n_pids", "pi_d", "dbar_d", "delta_d_use"]
    print(df[cols].to_string(
        index=False,
        formatters={
            "pi_d": lambda x: f"{x:.4f}",
            "dbar_d": lambda x: f"{x:.4f}",
            "delta_d_use": lambda x: f"{x:+.4f}",
            "n_pids": lambda x: f"{int(x)}",
        },
    ))

    res = evaluate_aggregate(
        delta_d=df["delta_d_use"].to_numpy(),
        pi_d=df["pi_d"].to_numpy(),
        dbar_d=df["dbar_d"].to_numpy(),
        traj_labels=df["label"].tolist(),
    )

    print(f"\nE1 aggregate at the point estimate:")
    print(f"  W_obs - W_zero        = {res.w_obs_minus_zero:+.4f} log pts  ({log_to_pct(res.w_obs_minus_zero) * 100:+.2f}%)")
    print(f"  W_opt - W_obs (Opt 1) = {res.w_opt_minus_obs:+.4f} log pts  ({log_to_pct(res.w_opt_minus_obs) * 100:+.2f}%)")

    print(f"\nDecomposition (log pts contribution):")
    print(f"  {'trajectory':<18} {'value-of-mig':>15} {'misalloc-gap':>15}")
    for lbl, c_oz, c_op in zip(res.traj_labels, res.contrib_obs_zero, res.contrib_opt_obs):
        print(f"  {lbl:<18} {c_oz:>+15.4f} {c_op:>+15.4f}")
    print(f"  {'-' * 50}")
    print(f"  {'total':<18} {res.w_obs_minus_zero:>+15.4f} {res.w_opt_minus_obs:>+15.4f}")

    # Compare to back-of-envelope from the memo.
    boe_map = {
        "IDN": {"value_of_mig": -0.044, "misalloc_pct": 3.7},
        "TZA": {"value_of_mig": -0.09, "misalloc_pct": 22.0},
    }
    boe = boe_map[country]
    print(f"\nBack-of-envelope comparison (2026-05-13 memo):")
    print(f"  memo W_obs - W_zero  ~  {boe['value_of_mig']:+.3f} log pts")
    print(f"  prod W_obs - W_zero  =  {res.w_obs_minus_zero:+.4f} log pts")
    print(f"  memo W_opt - W_obs   ~  {boe['misalloc_pct']:+.1f}%")
    print(f"  prod W_opt - W_obs   =  {log_to_pct(res.w_opt_minus_obs) * 100:+.2f}%")


def main() -> None:
    for country in COUNTRIES:
        report_country(country)


if __name__ == "__main__":
    main()
