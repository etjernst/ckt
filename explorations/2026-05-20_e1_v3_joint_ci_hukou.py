"""V3 joint CI on the E1 misallocation aggregate for CHN hukou subsamples.

Parallel to 2026-05-20_e1_v3_joint_ci.py (which handles IDN and TZA),
but loops over CHN_hukou_rural_first and CHN_hukou_urban_first. Reads
trajectory inputs from the hukou CSVs produced by
_export_e1_inputs_hukou.do.

Auxiliary OLS spec is matched to the GMM (lndepvar = log per-capita
with cube-root scale, period FE + female + age2 + education_max +
education_max2 controls, drop mi(education_max), mi(age), and
obs_per_individual == 1).

CHN_uf (urban-hukou-first) is right at the identification boundary at
phi = -1: the GMM point estimate is phi_hat = -0.973 and 5b's attached
marginal CI is [-inf, -0.77]. The Delta_dT extrapolation blows up
across the boundary, so the aggregate convex hull for UF is dominated
by pole inflation rather than honest uncertainty. P3 fallback (drop
the Delta_dT piece, report aggregate as d_N plus switchers only) is
the next module to add.
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

# country -> (data_file_stem, country_short)
HUKOU_CELLS = [
    ("CHN_hukou_rural_first", "CHN_rf"),
    ("CHN_hukou_urban_first", "CHN_uf"),
]

# Lattice extended below phi = -3 to cover UF's GMM point estimate region.
PHI_GRID = np.linspace(-3.5, 1.0, 451)
BETA_GRID = np.linspace(-0.5, 0.5, 101)
BASE_TRAJECTORY = 2
THRESHOLD = 5
TYPE_ONE = 0.05


def load_v2_inputs(country_short: str) -> dict:
    traj = pd.read_csv(INPUTS_DIR / f"{country_short}_e1_traj.csv")
    mu_d = pd.read_csv(INPUTS_DIR / f"{country_short}_e1_mu_d.csv")
    delta_d = pd.read_csv(INPUTS_DIR / f"{country_short}_e1_delta_d.csv")
    scalars_df = pd.read_csv(INPUTS_DIR / f"{country_short}_e1_scalars.csv")
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
    mask = (data[traj_var] == dT_code) & (data[choice_var] == 1)
    return float(
        np.log(data.loc[mask, outcome_var] / data.loc[mask, "hhsize_cube"]).mean()
    )


def prepare_data(country_file_stem: str) -> tuple[pd.DataFrame, list[str]]:
    """Mirror 5b_inversion.do's sample: do not drop trajectory NaN rows.
    See the IDN/TZA driver for the full rationale."""
    df = pd.read_stata(
        DATA_DIR / f"{country_file_stem}_unb.dta", convert_categoricals=False
    )
    df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])
    df = df.dropna(subset=["lndepvar", "choice"]).copy()
    needed = ["female", "age2", "education_max", "education_max2",
              "unbalanced", "unbalanced_choice"]
    df = df.dropna(subset=[c for c in needed if c in df.columns])
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


def run_cell(country_file_stem: str, country_short: str) -> None:
    print(f"\n{'=' * 64}")
    print(f"==== {country_short} ({country_file_stem})")
    print(f"{'=' * 64}")

    df, controls = prepare_data(country_file_stem)
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

    print(f"\n  Building joint (phi, beta) CI on a {len(PHI_GRID)} x {len(BETA_GRID)} lattice ...")
    ci = build_joint_ci_grid(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=PHI_GRID, beta_grid=BETA_GRID, type_one=TYPE_ONE,
    )
    n_accept = int(ci["accept"].sum())
    n_total = ci["accept"].size
    threshold = chi2.ppf(1.0 - TYPE_ONE, df=K)
    print(f"  joint CI: {n_accept} of {n_total} lattice points accepted "
          f"({100.0 * n_accept / n_total:.2f}%)")
    print(f"  threshold chi^2_{{{K}, 0.95}} = {threshold:.3f}")
    print(f"  n_islands: {len(ci['islands'])}")

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

    v2 = load_v2_inputs(country_short)
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

    wms_full: list[float] = []
    wmm_full: list[float] = []
    wms_p3: list[float] = []
    wmm_p3: list[float] = []
    crosses_boundary = False
    for (i, j) in np.argwhere(ci["accept"]):
        phi = float(ci["phi_grid"][i])
        beta = float(ci["beta_grid"][j])
        if phi <= -1.0:
            crosses_boundary = True
        try:
            delta_vec = delta_at(phi, beta)
            delta_vec_p3 = delta_vec.copy()
            delta_vec_p3[is_dT] = 0.0
            res_full = evaluate_aggregate(
                delta_d=delta_vec, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None,
            )
            res_p3 = evaluate_aggregate(
                delta_d=delta_vec_p3, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None,
            )
            wms_full.append(res_full.w_obs_minus_zero)
            wmm_full.append(res_full.w_opt_minus_obs)
            wms_p3.append(res_p3.w_obs_minus_zero)
            wmm_p3.append(res_p3.w_opt_minus_obs)
        except (ValueError, FloatingPointError):
            wms_full.append(float("nan"))
            wmm_full.append(float("nan"))
            wms_p3.append(float("nan"))
            wmm_p3.append(float("nan"))

    wms_arr = np.array(wms_full)
    wmm_arr = np.array(wmm_full)
    wms_p3_arr = np.array(wms_p3)
    wmm_p3_arr = np.array(wmm_p3)
    proj_oz = project_image_intervals(wms_arr)
    proj_oo = project_image_intervals(wmm_arr)
    proj_oz_p3 = project_image_intervals(wms_p3_arr)
    proj_oo_p3 = project_image_intervals(wmm_p3_arr)

    if crosses_boundary:
        print(f"    NOTE: accepted region crosses the phi = -1 identification boundary.")
        print(f"          with-d_T aggregate inflates from the (1+phi) singularity;")
        print(f"          rely on the P3 (no-d_T) summary below as the defensible reading.")

    def _print_block(label: str, proj_with: dict, proj_p3: dict,
                     n_with: int, n_p3: int) -> None:
        print(f"\n  {label}:")
        if proj_with["n_finite"] > 0:
            lo, hi = proj_with["convex_hull"]
            print(f"    with d_T   ({proj_with['n_finite']}/{n_with} finite): "
                  f"[{lo:+.4f}, {hi:+.4f}] log pts  "
                  f"({log_to_pct(lo) * 100:+.2f}% to {log_to_pct(hi) * 100:+.2f}%)")
        else:
            print(f"    with d_T   ({proj_with['n_finite']}/{n_with} finite): empty")
        if proj_p3["n_finite"] > 0:
            lo, hi = proj_p3["convex_hull"]
            print(f"    P3 (no dT) ({proj_p3['n_finite']}/{n_p3} finite): "
                  f"[{lo:+.4f}, {hi:+.4f}] log pts  "
                  f"({log_to_pct(lo) * 100:+.2f}% to {log_to_pct(hi) * 100:+.2f}%)")
        else:
            print(f"    P3 (no dT) ({proj_p3['n_finite']}/{n_p3} finite): empty")

    _print_block("W_obs - W_zero (value of observed migration)",
                 proj_oz, proj_oz_p3, len(wms_arr), len(wms_p3_arr))
    _print_block("W_opt - W_obs (misallocation gap)",
                 proj_oo, proj_oo_p3, len(wmm_arr), len(wmm_p3_arr))


def main() -> None:
    for country_file_stem, country_short in HUKOU_CELLS:
        run_cell(country_file_stem, country_short)


if __name__ == "__main__":
    main()
