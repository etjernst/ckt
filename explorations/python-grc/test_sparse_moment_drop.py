"""Quick diagnostic for option A: explicit sparse-moment drop in the
GMM fit. Runs IDN/cons/urban/unb covs_0 with the new
``_drop_sparse_moments`` step active, prints what got dropped, and
shows phi/SE compared to the cached Stata baseline.
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb, period_fe_columns
from grc_gmm import RestrictedGRC


HERE = Path(__file__).parent


def main():
    df = load_consumption_unb("IDN")
    print(f"Loaded {len(df):,} rows, {df['pid'].nunique():,} unique pids")

    # covs_all: period FE + female + age2 + education_max + education_max2
    # (matches 5_GrRC.do covs_all spec). Headline-relevant column.
    period_cols = period_fe_columns(df)
    controls = list(period_cols) + ["female", "age2",
                                     "education_max", "education_max2"]
    print(f"Controls (covs_all): {controls}")

    est = RestrictedGRC(
        outcome="lndepvar",
        choice="choice",
        trajectory="trajectory",
        individual_id="pid",
        covariates=controls,
        unbalanced_col="unbalanced",
        sparse_moment_threshold=2,
    )

    t0 = time.time()
    est.fit(df, verbose=True)
    runtime = time.time() - t0
    print(f"\nfit() runtime: {runtime / 60:.1f} min ({runtime:.0f} s)")
    print(f"Total dropped instruments: {est.dropped_moments_}")
    print(f"Sparse drops: {est.sparse_dropped_}")

    # Build name -> index for the kept theta vector
    S = len(est._data_["switchers"])
    names = ["mu:never"]
    names += [f"mu:switcher_{s}" for s in est._data_["switchers"]]
    names += ["kappa:_cons", "Delta_base:_cons", "phi:_cons"]
    names += [f"xb:{c}" for c in est._data_["cov_names"]]

    coefs = pd.DataFrame({
        "name": names,
        "coef_py": est.theta_,
        "se_py": np.sqrt(np.diag(est.vcov_)),
    })

    out_csv = HERE / "python_out_idn_cons_urb_unb_covs_all_sparsedrop.csv"
    coefs.to_csv(out_csv, index=False)
    print(f"\nSaved coefficients to {out_csv}")

    # Compare phi against the fresh Stata covs_all rerun
    stata_csv = HERE / "rerun_workdir" / "idn_fresh_phi.csv"
    if stata_csv.exists():
        s = pd.read_csv(stata_csv)
        row = s[s["spec"] == "covs_all"].iloc[0]
        s_phi = float(row["phi"])
        s_se = float(row["phi_se"])
        py_phi = coefs.loc[coefs["name"] == "phi:_cons", "coef_py"].iloc[0]
        py_se = coefs.loc[coefs["name"] == "phi:_cons", "se_py"].iloc[0]
        print("\n--- phi comparison (covs_all) ---")
        print(f"  Stata twostep:        phi = {s_phi:.6f}, SE = {s_se:.6f}")
        print(f"  Python iterated:      phi = {py_phi:.6f}, SE = {py_se:.6f}")
        print(f"  diff phi:  {py_phi - s_phi:+.4e}")
        print(f"  ratio SE:  {py_se / s_se:.3f}")

    # Diagnostic on the W matrix used at the final iteration
    from grc_gmm import _robust_inv
    S_mat = est._cluster_S(est.theta_, est._data_)
    W = _robust_inv(S_mat)
    W_diag = np.diag(W)
    print("\n--- final W diagnostic ---")
    print(f"  m = {S_mat.shape[0]} (post-drops)")
    print(f"  cond(S) (svd, top/bottom): "
          f"{np.linalg.cond(S_mat):.3e}")
    print(f"  cond(W): {np.linalg.cond(W):.3e}")
    print(f"  W diag: min={W_diag.min():.3e}, "
          f"max={W_diag.max():.3e}, "
          f"max/min ratio={W_diag.max() / max(W_diag.min(), 1e-300):.3e}")


if __name__ == "__main__":
    main()
