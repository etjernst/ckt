"""Smoke test: MD inversion CIs for Delta_never, Delta_avg,
Delta_always on IDN, all 5 specs.

Compares against (a) Stata's published nlcom CI (point +/- 1.96*SE)
and (b) the convex hull of the just-identified Delta_never values
implied by the MD phi-CI grid evaluated at MD's beta_md(phi).

Sanity check: the inversion CI should bracket Stata's published
nlcom CI roughly, with width similar or wider in the weakly-identified
specs.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import (
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_delta_never_md_inversion,
    grid_delta_avg_md_inversion,
    grid_delta_always_md_inversion,
    grid_md_inversion,
)
from run_all_countries_inversion import _spec_controls

HERE = Path(__file__).resolve().parent
RERUN = HERE / "rerun_workdir"
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


def main():
    country = "IDN"
    pub = pd.read_csv(RERUN / "published_deltas.csv")
    df = load_consumption_unb(country)
    period_cols = period_fe_columns(df)
    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=5
    )
    base = 2 if 2 in kept else kept[0]
    trajectories = sorted(int(t) for t in df["trajectory"].dropna().unique())
    never_traj, always_traj = trajectories[0], trajectories[-1]

    phi_grid = np.arange(-3.0, 1.0001, 0.01)
    delta_grid = np.arange(-1.5, 1.5001, 0.01)
    rows = []

    for spec in ["covs_0", "covs_trend", "covs_1", "covs_2", "covs_all"]:
        controls = _spec_controls(spec, period_cols)
        cols_needed = [
            "lndepvar", "choice", "trajectory", "pid",
            "unbalanced", "unbalanced_choice",
        ] + controls
        sub = df.dropna(subset=[c for c in cols_needed if c != "trajectory"]).copy()
        fit = fit_auxiliary_ols(
            sub, outcome="lndepvar", trajectory="trajectory",
            choice="choice", hhid="pid",
            switchers_kept=kept, controls=controls,
        )
        n_sw = int(sub["trajectory"].isin(kept).sum())
        pi_within = {
            s: float((sub["trajectory"] == s).sum()) / n_sw for s in kept
        }

        # Three inversions
        n_curve, n_lo, n_hi = grid_delta_never_md_inversion(
            fit, switchers_kept=kept, base=base, never_traj=never_traj,
            delta_grid=delta_grid, phi_search_grid=phi_grid,
        )
        a_curve, a_lo, a_hi = grid_delta_avg_md_inversion(
            fit, switchers_kept=kept, base=base, pi_within=pi_within,
            delta_grid=delta_grid, phi_search_grid=phi_grid,
        )
        t_curve, t_lo, t_hi = grid_delta_always_md_inversion(
            fit, switchers_kept=kept, base=base, always_traj=always_traj,
            delta_grid=delta_grid, phi_search_grid=phi_grid,
        )
        n_d = float(n_curve["delta"].iloc[int(n_curve["wald"].idxmin())])
        a_d = float(a_curve["delta"].iloc[int(a_curve["wald"].idxmin())])
        t_d = float(t_curve["delta"].iloc[int(t_curve["wald"].idxmin())])

        for label, py_d, py_ci, sd_key in [
            ("never",  n_d, (n_lo, n_hi), "never"),
            ("avg",    a_d, (a_lo, a_hi), "avg"),
            ("always", t_d, (t_lo, t_hi), "always"),
        ]:
            srow = pub[
                (pub["country"] == country)
                & (pub["spec"] == spec) & (pub["delta"] == sd_key)
            ]
            st_pt = float(srow["point"].iloc[0])
            st_se = float(srow["se"].iloc[0])
            print(
                f"{spec} {label:7s}: Stata {st_pt:+.4f} +/- {st_se:.4f}  "
                f"95%=({st_pt-1.96*st_se:+.4f},{st_pt+1.96*st_se:+.4f})  "
                f"MD inv: d_min={py_d:+.3f} CI=[{py_ci[0]:+.3f},{py_ci[1]:+.3f}]"
            )
            rows.append({
                "spec": spec, "delta": label,
                "stata_pt": st_pt, "stata_se": st_se,
                "md_inv_d_min": py_d,
                "md_inv_ci95_lo": py_ci[0], "md_inv_ci95_hi": py_ci[1],
            })

    out = pd.DataFrame(rows)
    out.to_csv(OUTDIR / "smoke_delta_md_inversion.csv", index=False)
    print(f"\nWrote {OUTDIR / 'smoke_delta_md_inversion.csv'}")


if __name__ == "__main__":
    main()
