"""National CHN E1: population-weighted aggregate of the RF and UF P3 cells.

Pooled CHN cuu_ca rejects the J-test, so CHN enters E1 through the
hukou-split sters. RF (rural-hukou-first) and UF (urban-hukou-first)
form a near-exhaustive partition of CHN at the pid level: 25,491 RF
plus 9,024 UF out of 34,746 pids in CHN_unb.dta (99.3% coverage; the
remaining 231 pids have undefined or missing hukou status). The
national CHN aggregate is the population-weighted sum of the RF and
UF aggregates, with weights from the share of each subsample in
the full CHN sample.

This driver:
  1. computes the RF and UF P3 aggregates by importing logic from
     2026-05-20_e1_v3_joint_ci_hukou.py;
  2. reads the pid-level partition shares from CHN_unb.dta;
  3. combines the two cells' P3 images via interval arithmetic on the
     convex hulls (conservative outer bound assuming the two cells'
     parameters are independent draws within their joint CIs);
  4. reports both pre-selection (population) and post-selection
     (analysis-sample) weighted aggregates.
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
    """Mirror 5b_inversion.do's sample: do not drop trajectory NaN rows."""
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


def cell_p3_image(country_file_stem: str, country_short: str) -> dict:
    """Return the P3 (no-d_T) image of the misallocation gap and the
    value of observed migration across the accepted joint-CI lattice
    for one hukou cell."""
    print(f"\n  ---- {country_short} ({country_file_stem}) ----")
    df, controls = prepare_data(country_file_stem)
    n_pids_analysis = df["pid"].nunique()
    print(f"  N obs after drops: {len(df)}, n_pids: {n_pids_analysis}")

    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    K = len(kept)
    base = BASE_TRAJECTORY if BASE_TRAJECTORY in kept else kept[0]
    print(f"  K = {K}, base = {base}")

    fit = fit_auxiliary_ols(
        df, outcome="lndepvar", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=kept, controls=controls,
    )

    ci = build_joint_ci_grid(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=PHI_GRID, beta_grid=BETA_GRID, type_one=TYPE_ONE,
    )
    n_accept = int(ci["accept"].sum())
    print(f"  joint CI: {n_accept} of {ci['accept'].size} lattice points accepted")

    v2 = load_v2_inputs(country_short)
    traj_df = v2["trajectory"]
    scalars = v2["scalars"]
    mu_dN = float(traj_df.loc[traj_df["traj_for_agg"] == 1, "mu_d"].iloc[0])
    mu_base = float(traj_df.loc[traj_df["traj_for_agg"] == base, "mu_d"].iloc[0])
    max_traj = int(traj_df["traj_for_agg"].max())
    alpha_dT_obs = compute_alpha_dT_obs(
        df, "trajectory", "choice", "consumption", max_traj
    )

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

    wms_p3: list[float] = []
    wmm_p3: list[float] = []
    for (i, j) in np.argwhere(ci["accept"]):
        phi = float(ci["phi_grid"][i])
        beta = float(ci["beta_grid"][j])
        try:
            delta_vec = delta_at(phi, beta)
            delta_vec_p3 = delta_vec.copy()
            delta_vec_p3[is_dT] = 0.0
            res_p3 = evaluate_aggregate(
                delta_d=delta_vec_p3, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None,
            )
            wms_p3.append(res_p3.w_obs_minus_zero)
            wmm_p3.append(res_p3.w_opt_minus_obs)
        except (ValueError, FloatingPointError):
            wms_p3.append(float("nan"))
            wmm_p3.append(float("nan"))

    # Point estimate at GMM phi_hat, beta_hat
    phi_hat = scalars["phi_hat"]
    beta_hat = scalars["beta_hat"]
    delta_vec_hat = delta_at(phi_hat, beta_hat).copy()
    delta_vec_hat[is_dT] = 0.0
    res_hat = evaluate_aggregate(
        delta_d=delta_vec_hat, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None,
    )

    return {
        "country_short": country_short,
        "wms_p3": np.array(wms_p3),
        "wmm_p3": np.array(wmm_p3),
        "n_pids_analysis": n_pids_analysis,
        "point_estimate_wms": res_hat.w_obs_minus_zero,
        "point_estimate_wmm": res_hat.w_opt_minus_obs,
    }


def hukou_population_weights() -> dict:
    """Read pid-level hukou-status counts from the full CHN sample."""
    chn = pd.read_stata(DATA_DIR / "CHN_unb.dta", convert_categoricals=False)
    chn_pids = set(chn["pid"].unique())
    rf_pids = set(
        pd.read_stata(DATA_DIR / "CHN_hukou_rural_first_unb.dta",
                      convert_categoricals=False)["pid"].unique()
    )
    uf_pids = set(
        pd.read_stata(DATA_DIR / "CHN_hukou_urban_first_unb.dta",
                      convert_categoricals=False)["pid"].unique()
    )
    n_chn = len(chn_pids)
    n_rf = len(rf_pids)
    n_uf = len(uf_pids)
    n_overlap = len(rf_pids & uf_pids)
    n_missing = len(chn_pids - (rf_pids | uf_pids))
    return {
        "n_chn": n_chn,
        "n_rf": n_rf,
        "n_uf": n_uf,
        "n_overlap": n_overlap,
        "n_missing": n_missing,
        "w_rf_full": n_rf / n_chn,
        "w_uf_full": n_uf / n_chn,
        "w_rf_cond": n_rf / (n_rf + n_uf),
        "w_uf_cond": n_uf / (n_rf + n_uf),
    }


def combine_intervals(
    rf_lo: float, rf_hi: float, uf_lo: float, uf_hi: float,
    w_rf: float, w_uf: float,
) -> tuple[float, float]:
    """Interval arithmetic on the linear combination w_rf * x_rf + w_uf * x_uf.
    With non-negative weights the bounds are monotone in the inputs."""
    lo = w_rf * rf_lo + w_uf * uf_lo
    hi = w_rf * rf_hi + w_uf * uf_hi
    return lo, hi


def main() -> None:
    print(f"{'=' * 64}")
    print(f"National CHN E1 (population-weighted RF + UF, P3)")
    print(f"{'=' * 64}")

    weights = hukou_population_weights()
    print(f"\nCHN sample partition (pid-level, full CHN_unb.dta):")
    print(f"  n_chn        = {weights['n_chn']}")
    print(f"  n_rf         = {weights['n_rf']}")
    print(f"  n_uf         = {weights['n_uf']}")
    print(f"  n_overlap    = {weights['n_overlap']}")
    print(f"  n_missing    = {weights['n_missing']}  (pids in CHN but not in RF or UF)")
    print(f"  w_rf (full)  = {weights['w_rf_full']:.4f}  (= n_rf / n_chn)")
    print(f"  w_uf (full)  = {weights['w_uf_full']:.4f}  (= n_uf / n_chn)")
    print(f"  w_rf (cond)  = {weights['w_rf_cond']:.4f}  (conditional on RF or UF)")
    print(f"  w_uf (cond)  = {weights['w_uf_cond']:.4f}")

    rf = cell_p3_image("CHN_hukou_rural_first", "CHN_rf")
    uf = cell_p3_image("CHN_hukou_urban_first", "CHN_uf")

    # Analysis-sample weights (post-selection)
    n_rf_a = rf["n_pids_analysis"]
    n_uf_a = uf["n_pids_analysis"]
    w_rf_an = n_rf_a / (n_rf_a + n_uf_a)
    w_uf_an = n_uf_a / (n_rf_a + n_uf_a)
    print(f"\nAnalysis-sample weights (post-selection, pid-level):")
    print(f"  n_rf_analysis = {n_rf_a},  n_uf_analysis = {n_uf_a}")
    print(f"  w_rf_an = {w_rf_an:.4f},  w_uf_an = {w_uf_an:.4f}")

    # P3 convex hulls per cell
    proj_rf_wmm = project_image_intervals(rf["wmm_p3"])
    proj_uf_wmm = project_image_intervals(uf["wmm_p3"])
    proj_rf_wms = project_image_intervals(rf["wms_p3"])
    proj_uf_wms = project_image_intervals(uf["wms_p3"])

    print(f"\nPer-cell P3 misallocation gap (recap):")
    rf_wmm_lo, rf_wmm_hi = proj_rf_wmm["convex_hull"]
    uf_wmm_lo, uf_wmm_hi = proj_uf_wmm["convex_hull"]
    print(f"  RF: [{rf_wmm_lo:+.4f}, {rf_wmm_hi:+.4f}] log pts  "
          f"({log_to_pct(rf_wmm_lo)*100:+.2f}% to {log_to_pct(rf_wmm_hi)*100:+.2f}%)  "
          f"point = {rf['point_estimate_wmm']:+.4f} ({log_to_pct(rf['point_estimate_wmm'])*100:+.2f}%)")
    print(f"  UF: [{uf_wmm_lo:+.4f}, {uf_wmm_hi:+.4f}] log pts  "
          f"({log_to_pct(uf_wmm_lo)*100:+.2f}% to {log_to_pct(uf_wmm_hi)*100:+.2f}%)  "
          f"point = {uf['point_estimate_wmm']:+.4f} ({log_to_pct(uf['point_estimate_wmm'])*100:+.2f}%)")

    print(f"\nPer-cell P3 value of observed migration (recap):")
    rf_wms_lo, rf_wms_hi = proj_rf_wms["convex_hull"]
    uf_wms_lo, uf_wms_hi = proj_uf_wms["convex_hull"]
    print(f"  RF: [{rf_wms_lo:+.4f}, {rf_wms_hi:+.4f}] log pts  "
          f"({log_to_pct(rf_wms_lo)*100:+.2f}% to {log_to_pct(rf_wms_hi)*100:+.2f}%)  "
          f"point = {rf['point_estimate_wms']:+.4f} ({log_to_pct(rf['point_estimate_wms'])*100:+.2f}%)")
    print(f"  UF: [{uf_wms_lo:+.4f}, {uf_wms_hi:+.4f}] log pts  "
          f"({log_to_pct(uf_wms_lo)*100:+.2f}% to {log_to_pct(uf_wms_hi)*100:+.2f}%)  "
          f"point = {uf['point_estimate_wms']:+.4f} ({log_to_pct(uf['point_estimate_wms'])*100:+.2f}%)")

    # Combine via interval arithmetic
    for label, w_rf, w_uf in [
        ("CHN national (population weights, conditional on RF or UF)",
         weights["w_rf_cond"], weights["w_uf_cond"]),
        ("CHN national (population weights, divided by full CHN N)",
         weights["w_rf_full"], weights["w_uf_full"]),
        ("CHN national (analysis-sample weights)",
         w_rf_an, w_uf_an),
    ]:
        print(f"\n{label}:")
        print(f"  w_rf = {w_rf:.4f},  w_uf = {w_uf:.4f}")
        wmm_lo, wmm_hi = combine_intervals(rf_wmm_lo, rf_wmm_hi,
                                           uf_wmm_lo, uf_wmm_hi, w_rf, w_uf)
        wms_lo, wms_hi = combine_intervals(rf_wms_lo, rf_wms_hi,
                                           uf_wms_lo, uf_wms_hi, w_rf, w_uf)
        pt_wmm = w_rf * rf["point_estimate_wmm"] + w_uf * uf["point_estimate_wmm"]
        pt_wms = w_rf * rf["point_estimate_wms"] + w_uf * uf["point_estimate_wms"]
        print(f"  W_obs - W_zero:  point = {pt_wms:+.4f} ({log_to_pct(pt_wms)*100:+.2f}%)")
        print(f"                   CI    = [{wms_lo:+.4f}, {wms_hi:+.4f}] "
              f"({log_to_pct(wms_lo)*100:+.2f}% to {log_to_pct(wms_hi)*100:+.2f}%)")
        print(f"  Misallocation:   point = {pt_wmm:+.4f} ({log_to_pct(pt_wmm)*100:+.2f}%)")
        print(f"                   CI    = [{wmm_lo:+.4f}, {wmm_hi:+.4f}] "
              f"({log_to_pct(wmm_lo)*100:+.2f}% to {log_to_pct(wmm_hi)*100:+.2f}%)")


if __name__ == "__main__":
    main()
