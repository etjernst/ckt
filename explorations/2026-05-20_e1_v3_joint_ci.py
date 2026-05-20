"""V3 joint CI on the E1 misallocation aggregate, with the auxiliary-OLS
spec matched to the GMM specification of column 5 (cuu_ca).

Supersedes 2026-05-18_e1_v3_joint_ci_smoke.py, which used log(consumption)
and no controls in fit_auxiliary_ols and therefore returned 0 of 6171
accepted lattice points for IDN. The Wald-at-GMM diagnostic
(2026-05-20_e1_v3_wald_at_gmm.py + memo) localized the bug to the
auxiliary-OLS spec; this driver fixes it by passing:

  - outcome:  log(consumption / hhsize_cube)
  - controls: period FE + female + age2 + education_max + education_max2
  - sample:   drop mi(education_max), mi(age), obs_per_individual == 1

Lattice refined to 0.01 spacing on both axes around the GMM point.

Reports per country:
  - joint CI: count of accepted lattice points and marginal phi/beta CIs
  - Wald-at-GMM cross-check (should be below the threshold)
  - projection of the aggregate through the joint CI (convex hull + islands)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import chi2

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

COUNTRIES = ["IDN", "TZA"]
# Refined lattice: 0.01 spacing
PHI_GRID = np.linspace(-2.0, 1.0, 301)
BETA_GRID = np.linspace(-0.5, 0.5, 101)
BASE_TRAJECTORY = 2
THRESHOLD = 5
TYPE_ONE = 0.05


def load_v2_inputs(country: str) -> dict:
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
    """Mean observed urban log per-capita consumption for trajectory == d_T."""
    mask = (data[traj_var] == dT_code) & (data[choice_var] == 1)
    return float(
        np.log(data.loc[mask, outcome_var] / data.loc[mask, "hhsize_cube"]).mean()
    )


def prepare_data(country: str) -> tuple[pd.DataFrame, list[str]]:
    """Load and prepare data with GMM-matched outcome, controls, sample."""
    df = pd.read_stata(DATA_DIR / f"{country}_unb.dta", convert_categoricals=False)
    df = df.dropna(subset=["consumption", "choice", "trajectory"]).copy()
    df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])
    df = df.dropna(subset=["lndepvar"])
    df = df.dropna(subset=["education_max", "age"])
    if "obs_per_individual" in df.columns:
        df = df.loc[df["obs_per_individual"] > 1].copy()
    periods = sorted(df["period"].dropna().unique().astype(int).tolist())
    period_cols = []
    for t in periods[1:]:
        col = f"period_{t}"
        df[col] = (df["period"] == t).astype(float)
        period_cols.append(col)
    controls = period_cols + ["female", "age2", "education_max", "education_max2"]
    for col in ["unbalanced", "unbalanced_choice"]:
        if col not in df.columns:
            df[col] = 0.0
    return df, controls


def run_country(country: str) -> None:
    print(f"\n{'=' * 64}")
    print(f"==== {country} V3 joint CI (matched spec)")
    print(f"{'=' * 64}")

    df, controls = prepare_data(country)
    print(f"  outcome:  log(consumption / hhsize_cube)")
    print(f"  controls: {controls}")
    print(f"  N obs after drops: {len(df)}")

    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    K = len(kept)
    base = BASE_TRAJECTORY if BASE_TRAJECTORY in kept else kept[0]
    print(f"  switchers kept (N >= {THRESHOLD}): K = {K}")
    print(f"  base trajectory: {base}")

    fit = fit_auxiliary_ols(
        df,
        outcome="lndepvar",
        trajectory="trajectory",
        choice="choice",
        hhid="pid",
        switchers_kept=kept,
        controls=controls,
    )
    print(f"  aux OLS: n_obs = {fit.n_obs}, n_clusters = {fit.n_clusters}, p = {len(fit.b)}")

    # Build joint CI grid
    print(f"\n  Building joint (phi, beta) CI on a {len(PHI_GRID)} x {len(BETA_GRID)} lattice ...")
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
    threshold = chi2.ppf(1.0 - TYPE_ONE, df=K)
    print(f"  joint CI: {n_accept} of {n_total} lattice points accepted "
          f"({100.0 * n_accept / n_total:.2f}%)")
    print(f"  threshold chi^2_{{{K}, 0.95}} = {threshold:.3f}")
    print(f"  n_islands: {len(ci['islands'])}")

    # Marginal CIs (projection of the joint accept mask)
    phi_marg = ci["accept"].any(axis=1)
    beta_marg = ci["accept"].any(axis=0)
    if phi_marg.any():
        phi_lo = float(PHI_GRID[phi_marg][0])
        phi_hi = float(PHI_GRID[phi_marg][-1])
        print(f"  marginal phi: [{phi_lo:+.3f}, {phi_hi:+.3f}]")
    else:
        print(f"  marginal phi: empty")
    if beta_marg.any():
        beta_lo = float(BETA_GRID[beta_marg][0])
        beta_hi = float(BETA_GRID[beta_marg][-1])
        print(f"  marginal beta: [{beta_lo:+.3f}, {beta_hi:+.3f}]")
    else:
        print(f"  marginal beta: empty")

    # Wald-at-GMM cross-check
    v2 = load_v2_inputs(country)
    scalars = v2["scalars"]
    phi_hat = scalars["phi_hat"]
    beta_hat = scalars["beta_hat"]
    j_stat = scalars["j_stat"]
    j_df = int(scalars["j_df"])
    point = build_joint_ci_grid(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=np.array([phi_hat]), beta_grid=np.array([beta_hat]),
        type_one=TYPE_ONE,
    )
    wald_gmm = float(point["wald"][0, 0])
    p_gmm = float(point["p_value"][0, 0])
    print(f"\n  Wald-at-GMM cross-check at ({phi_hat:+.4f}, {beta_hat:+.4f}):")
    print(f"    constrained Wald = {wald_gmm:.3f}")
    print(f"    p-value          = {p_gmm:.4f}")
    print(f"    GMM J from ster  = {j_stat:.3f} on {j_df} dof")
    print(f"    accepted: {p_gmm >= TYPE_ONE}")

    # Propagate the aggregate through the joint CI
    if n_accept == 0:
        print(f"\n  Joint CI is empty; cannot propagate aggregate.")
        return

    traj_df = v2["trajectory"]
    mu_dN = float(traj_df.loc[traj_df["traj_for_agg"] == 1, "mu_d"].iloc[0])
    mu_base = float(traj_df.loc[traj_df["traj_for_agg"] == base, "mu_d"].iloc[0])
    max_traj = int(traj_df["traj_for_agg"].max())
    alpha_dT_obs = compute_alpha_dT_obs(
        df, "trajectory", "choice", "consumption", max_traj
    )
    print(f"\n  Aggregate propagation:")
    print(f"    mu_dN  = {mu_dN:+.4f}")
    print(f"    mu_base = {mu_base:+.4f}  (traj {base})")
    print(f"    alpha_dT_obs (from data, traj={max_traj}) = {alpha_dT_obs:+.4f}")

    pi_arr = traj_df["pi_d"].to_numpy()
    dbar_arr = traj_df["dbar_d"].to_numpy()
    delta_arr_base = traj_df["delta_d_unrestricted"].to_numpy()
    is_dN = traj_df["traj_for_agg"].to_numpy() == 1
    is_dT = traj_df["traj_for_agg"].to_numpy() == max_traj
    is_lumped = traj_df["traj_for_agg"].to_numpy() == -1
    unb_choice_hat = scalars.get("unb_choice_hat", 0.0)

    def delta_at(phi: float, beta: float) -> np.ndarray:
        out = np.where(np.isnan(delta_arr_base), 0.0, delta_arr_base)
        out = np.where(is_lumped, unb_choice_hat, out)
        out = np.where(is_dN, lca_delta_dN(phi, beta, mu_dN, mu_base), out)
        out = np.where(is_dT, lca_delta_dT(phi, beta, alpha_dT_obs, mu_base), out)
        return out

    wms: list[float] = []
    wmm: list[float] = []
    crosses_pole = False
    for (i, j) in np.argwhere(ci["accept"]):
        phi = float(ci["phi_grid"][i])
        beta = float(ci["beta_grid"][j])
        if phi <= -1.0:
            crosses_pole = True
        try:
            delta_vec = delta_at(phi, beta)
            res = evaluate_aggregate(
                delta_d=delta_vec, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None,
            )
            wms.append(res.w_obs_minus_zero)
            wmm.append(res.w_opt_minus_obs)
        except (ValueError, FloatingPointError):
            wms.append(float("nan"))
            wmm.append(float("nan"))

    wms_arr = np.array(wms)
    wmm_arr = np.array(wmm)
    proj_oz = project_image_intervals(wms_arr)
    proj_oo = project_image_intervals(wmm_arr)

    if crosses_pole:
        print(f"    WARNING: accepted region crosses the Mobius pole (phi <= -1).")
        print(f"             aggregate is unbounded near phi = -1 from below.")
        print(f"             P3 fallback (drop d_T) recommended; not implemented here.")

    print(f"\n  W_obs - W_zero (value of observed migration):")
    print(f"    finite values: {proj_oz['n_finite']} / {len(wms_arr)}")
    if proj_oz["n_finite"] > 0:
        lo, hi = proj_oz["convex_hull"]
        print(f"    convex hull: [{lo:+.4f}, {hi:+.4f}] log pts  "
              f"({log_to_pct(lo) * 100:+.2f}% to {log_to_pct(hi) * 100:+.2f}%)")
        print(f"    n_islands: {proj_oz['n_islands']}")
        for k, (lo, hi) in enumerate(proj_oz["intervals"][:5]):
            print(f"    interval {k + 1}: [{lo:+.4f}, {hi:+.4f}]")

    print(f"\n  W_opt - W_obs (misallocation gap):")
    print(f"    finite values: {proj_oo['n_finite']} / {len(wmm_arr)}")
    if proj_oo["n_finite"] > 0:
        lo, hi = proj_oo["convex_hull"]
        print(f"    convex hull: [{lo:+.4f}, {hi:+.4f}] log pts  "
              f"({log_to_pct(lo) * 100:+.2f}% to {log_to_pct(hi) * 100:+.2f}%)")
        print(f"    n_islands: {proj_oo['n_islands']}")
        for k, (lo, hi) in enumerate(proj_oo["intervals"][:5]):
            print(f"    interval {k + 1}: [{lo:+.4f}, {hi:+.4f}]")


def main() -> None:
    for country in COUNTRIES:
        run_country(country)


if __name__ == "__main__":
    main()
