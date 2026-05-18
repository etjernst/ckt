"""V3 milestone (smoke): construct the joint (phi, beta) inversion CI
and propagate the E1 misallocation aggregate through it.

Pipeline:
  1. Load country data (.dta)
  2. Run fit_auxiliary_ols on the saturated trajectory + switcher x choice OLS
  3. Build a 2D (phi, beta) grid; invert the constrained-J at each point
  4. At each accepted (phi, beta), compute the LCA-implied Delta_dN and
     Delta_dT and evaluate the E1 aggregate
  5. Project the image: convex hull plus connected-component intervals
  6. Report

Smoke version: IDN and TZA only (CHN pooled rejects, will be handled
separately via hukou-split sters).
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "python-grc"))

from counterfactuals import (  # noqa: E402
    build_joint_ci_grid,
    drop_sparse_switchers,
    evaluate_aggregate,
    fit_auxiliary_ols,
    lca_delta_dN,
    lca_delta_dT,
    log_to_pct,
    project_image_intervals,
)

INPUTS_DIR = Path(
    "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_inputs"
)
DATA_DIR = Path(
    "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/data/processed"
)

# Configuration
COUNTRIES = ["IDN", "TZA"]
PHI_GRID = np.linspace(-2.0, 1.0, 121)   # coarse for smoke
BETA_GRID = np.linspace(-0.5, 0.5, 51)   # coarse for smoke
BASE_TRAJECTORY = 2  # from 5b_inversion.log: same for IDN/TZA/CHN
THRESHOLD = 5
TYPE_ONE = 0.05


def load_v2_inputs(country: str) -> dict:
    """Load the V2 CSVs (trajectory shares, switcher Deltas, scalars)."""
    traj = pd.read_csv(INPUTS_DIR / f"{country}_e1_traj.csv")
    mu_d = pd.read_csv(INPUTS_DIR / f"{country}_e1_mu_d.csv")
    delta_d = pd.read_csv(INPUTS_DIR / f"{country}_e1_delta_d.csv")
    scalars_df = pd.read_csv(INPUTS_DIR / f"{country}_e1_scalars.csv")
    scalars: dict = {}
    for _, row in scalars_df.iterrows():
        try:
            scalars[row["name"]] = float(row["value"])
        except (TypeError, ValueError):
            scalars[row["name"]] = row["value"]

    df = traj.merge(mu_d, on="traj_for_agg", how="left").merge(
        delta_d.rename(columns={"trajectory": "traj_for_agg"}),
        on="traj_for_agg",
        how="left",
    )
    return {"trajectory": df, "scalars": scalars}


def compute_alpha_dT_obs(data: pd.DataFrame, traj_var: str, choice_var: str,
                        outcome_var: str, dT_code: int) -> float:
    """Mean observed urban log consumption for trajectory == d_T."""
    mask = (data[traj_var] == dT_code) & (data[choice_var] == 1)
    return float(np.log(data.loc[mask, outcome_var]).mean())


def run_country(country: str) -> None:
    print(f"\n{'=' * 64}")
    print(f"==== {country} V3 joint CI smoke")
    print(f"{'=' * 64}")

    # Load data; convert_categoricals=False keeps trajectory and choice as
    # integer codes (1..K for trajectory, 0/1 for choice), matching what
    # drop_sparse_switchers expects.
    df = pd.read_stata(DATA_DIR / f"{country}_unb.dta", convert_categoricals=False)
    df = df.dropna(subset=["consumption", "choice", "trajectory"]).copy()
    df["log_c"] = np.log(df["consumption"])
    df = df.dropna(subset=["log_c"])

    # Determine kept switchers
    kept, sw_counts = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    print(f"  switchers kept (N >= {THRESHOLD} unique treated pids): {kept}")
    print(f"  base trajectory: {BASE_TRAJECTORY}")
    if BASE_TRAJECTORY not in kept:
        print(f"  WARNING: base {BASE_TRAJECTORY} not in kept switchers; using {kept[0]}")
        base = kept[0]
    else:
        base = BASE_TRAJECTORY

    # Fit auxiliary OLS
    print("  fitting auxiliary OLS...")
    # Use 'log_c' as outcome; auxiliary needs unbalanced* columns to exist
    for col in ["unbalanced", "unbalanced_choice"]:
        if col not in df.columns:
            df[col] = 0.0
    fit = fit_auxiliary_ols(
        df,
        outcome="log_c",
        trajectory="trajectory",
        choice="choice",
        hhid="pid",
        switchers_kept=kept,
    )
    print(f"  aux OLS: n_obs = {fit.n_obs}, n_clusters = {fit.n_clusters}, p = {len(fit.b)}")

    # Build joint CI grid
    print(f"  building joint (phi, beta) CI grid ({len(PHI_GRID)} x {len(BETA_GRID)}) ...")
    ci = build_joint_ci_grid(
        fit=fit,
        switchers_kept=kept,
        base=base,
        phi_grid=PHI_GRID,
        beta_grid=BETA_GRID,
        type_one=TYPE_ONE,
    )
    n_accept = int(ci["accept"].sum())
    n_total = ci["accept"].size
    print(f"  joint CI: {n_accept} of {n_total} lattice points accepted "
          f"({100.0 * n_accept / n_total:.1f}%)")
    print(f"  n_islands (connected components on the 2D mask): {len(ci['islands'])}")
    print(f"  K (chi^2 dof) = {ci['K']}")

    # Project marginal CIs (sanity check)
    phi_marginal = ci["accept"].any(axis=1)
    if phi_marginal.any():
        phi_lo = float(PHI_GRID[phi_marginal][0])
        phi_hi = float(PHI_GRID[phi_marginal][-1])
        print(f"  phi marginal (projected): [{phi_lo:+.3f}, {phi_hi:+.3f}]")

    beta_marginal = ci["accept"].any(axis=0)
    if beta_marginal.any():
        beta_lo = float(BETA_GRID[beta_marginal][0])
        beta_hi = float(BETA_GRID[beta_marginal][-1])
        print(f"  beta marginal (projected): [{beta_lo:+.3f}, {beta_hi:+.3f}]")

    # Propagate the aggregate through the joint CI
    v2 = load_v2_inputs(country)
    scalars = v2["scalars"]
    traj_df = v2["trajectory"]

    # Get mu_dN and mu_base (from V2 mu_d.csv) and alpha_dT_obs (compute from data)
    mu_dN = float(traj_df.loc[traj_df["traj_for_agg"] == 1, "mu_d"].iloc[0])
    mu_base = float(traj_df.loc[traj_df["traj_for_agg"] == base, "mu_d"].iloc[0])
    max_traj = int(traj_df["traj_for_agg"].max())
    alpha_dT_obs = compute_alpha_dT_obs(
        df, "trajectory", "choice", "consumption", max_traj
    )
    print(f"  mu_dN = {mu_dN:.4f}   mu_base(traj={base}) = {mu_base:.4f}")
    print(f"  alpha_dT_obs (from data, traj={max_traj}) = {alpha_dT_obs:.4f}")

    # Build the fixed pieces of the aggregate (everything that does not depend on phi, beta)
    # For each (phi, beta): replace traj_for_agg == 1 (d_N) and traj_for_agg == max_traj (d_T)
    # Delta with LCA-implied values; keep switcher Delta_d's and lumped from V2.
    # Compute over all accepted lattice points.
    pi_arr = traj_df["pi_d"].to_numpy()
    dbar_arr = traj_df["dbar_d"].to_numpy()
    delta_arr_base = traj_df["delta_d_unrestricted"].to_numpy()  # for balanced switchers
    is_dN = traj_df["traj_for_agg"].to_numpy() == 1
    is_dT = traj_df["traj_for_agg"].to_numpy() == max_traj
    is_lumped = traj_df["traj_for_agg"].to_numpy() == -1
    unb_choice_hat = scalars.get("unb_choice_hat", 0.0)

    # Delta vector at (phi, beta)
    def delta_at(phi: float, beta: float) -> np.ndarray:
        out = np.where(np.isnan(delta_arr_base), 0.0, delta_arr_base)
        out = np.where(is_lumped, unb_choice_hat, out)
        out = np.where(is_dN, lca_delta_dN(phi, beta, mu_dN, mu_base), out)
        out = np.where(is_dT, lca_delta_dT(phi, beta, alpha_dT_obs, mu_base), out)
        return out

    # Sweep
    wms = []  # W_obs - W_zero
    wmm = []  # W_opt - W_obs
    for (i, j) in np.argwhere(ci["accept"]):
        phi = float(ci["phi_grid"][i])
        beta = float(ci["beta_grid"][j])
        delta_vec = delta_at(phi, beta)
        try:
            res = evaluate_aggregate(
                delta_d=delta_vec,
                pi_d=pi_arr,
                dbar_d=dbar_arr,
                traj_labels=None,
            )
            wms.append(res.w_obs_minus_zero)
            wmm.append(res.w_opt_minus_obs)
        except ValueError:
            wms.append(float("nan"))
            wmm.append(float("nan"))

    wms = np.array(wms)
    wmm = np.array(wmm)

    proj_obs_zero = project_image_intervals(wms)
    proj_opt_obs = project_image_intervals(wmm)

    print(f"\n  E1 aggregate propagated through joint CI:")
    print(f"  W_obs - W_zero:")
    print(f"    finite values: {proj_obs_zero['n_finite']} / {len(wms)}")
    print(f"    n_islands: {proj_obs_zero['n_islands']}")
    print(f"    convex hull: [{proj_obs_zero['convex_hull'][0]:+.4f}, "
          f"{proj_obs_zero['convex_hull'][1]:+.4f}] log pts  "
          f"(={log_to_pct(proj_obs_zero['convex_hull'][0]) * 100:+.2f}% to "
          f"{log_to_pct(proj_obs_zero['convex_hull'][1]) * 100:+.2f}%)")
    for k, (lo, hi) in enumerate(proj_obs_zero["intervals"]):
        print(f"    interval {k + 1}: [{lo:+.4f}, {hi:+.4f}]")

    print(f"  W_opt - W_obs (Option 1 floor):")
    print(f"    finite values: {proj_opt_obs['n_finite']} / {len(wmm)}")
    print(f"    n_islands: {proj_opt_obs['n_islands']}")
    print(f"    convex hull: [{proj_opt_obs['convex_hull'][0]:+.4f}, "
          f"{proj_opt_obs['convex_hull'][1]:+.4f}] log pts  "
          f"(={log_to_pct(proj_opt_obs['convex_hull'][0]) * 100:+.2f}% to "
          f"{log_to_pct(proj_opt_obs['convex_hull'][1]) * 100:+.2f}%)")
    for k, (lo, hi) in enumerate(proj_opt_obs["intervals"]):
        print(f"    interval {k + 1}: [{lo:+.4f}, {hi:+.4f}]")


def main() -> None:
    for country in COUNTRIES:
        run_country(country)


if __name__ == "__main__":
    main()
