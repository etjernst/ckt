"""Test alternative weighting-matrix conventions against Stata's SE(phi).

Stata's target (from stata_out_idn_cons_urb_unb.csv): SE(phi) = 0.0705.

Python currently uses W = S^{-1}(theta_hat); this gives SE(phi) = 0.199.

Candidates to test:
    * W = I                             (one-step GMM with identity)
    * W = (Z'Z / n)^{-1}                (Stata's default first-step for twostep)
    * W = S^{-1}(theta_initial_OLS)     (step-2 weight from OLS initial values)
    * W = S^{-1}(theta_py)              (current Python weight; sanity)

For each, report V = (G'WG)^{-1} G'WSWG (G'WG)^{-1} / n (sandwich)
and V = (G'WG)^{-1} / n (efficient).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent


def _reconstruct_theta(data, coefs):
    S = len(data["switchers"])
    theta = np.zeros(1 + S + 3 + data["X_cov"].shape[1])
    theta[0] = coefs["mu:never"]
    for j, s in enumerate(data["switchers"]):
        theta[1 + j] = coefs[f"mu:switcher_{s}"]
    theta[1 + S] = coefs["kappa:_cons"]
    theta[2 + S] = coefs["Delta_base:_cons"]
    theta[3 + S] = coefs["phi:_cons"]
    for k, c in enumerate(data["cov_names"]):
        theta[4 + S + k] = coefs[f"xb:{c}"]
    return theta


def _var_under_W(est, data, theta, W, phi_idx):
    G = est._gradient_of_g(theta, data)
    Smat = est._cluster_S(theta, data)
    GtWG = G.T @ W @ G
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    n = data["n"]
    V_eff = GtWG_inv / n
    meat = G.T @ W @ Smat @ W @ G
    V_sw = GtWG_inv @ meat @ GtWG_inv / n
    return float(np.sqrt(max(V_eff[phi_idx, phi_idx], 0.0))), \
           float(np.sqrt(max(V_sw[phi_idx, phi_idx], 0.0)))


def main():
    df = load_consumption_unb("IDN")
    est = RestrictedGRC(
        outcome="lndepvar", choice="choice", trajectory="trajectory",
        individual_id="pid", covariates=[], unbalanced_col="unbalanced",
    )
    data = est._build_design(df)
    Z_raw = est._build_instruments(data)
    Z, kept = _drop_collinear(Z_raw)
    data["Z"] = Z
    data["n"] = len(data["y"])
    data["base"] = 2

    n = data["n"]
    m = Z.shape[1]
    S = len(data["switchers"])
    phi_idx = 3 + S

    # Theta candidates
    stata = pd.read_csv(HERE / "stata_out_idn_cons_urb_unb.csv")
    py = pd.read_csv(HERE / "python_out_idn_cons_urb_unb.csv")
    theta_stata = _reconstruct_theta(
        data, dict(zip(stata["name"], stata["coef"]))
    )
    theta_py = _reconstruct_theta(
        data, dict(zip(py["name"], py["coef_py"]))
    )

    # Initial-OLS theta: use the fit's _ols_initial_values to populate
    # mu_never, kappa, mu_switchers, gamma. Delta_base = 0, phi = -1 per run_grc.
    beta0 = est._ols_initial_values(data)
    theta_ols = np.zeros_like(theta_py)
    theta_ols[0] = beta0[0]  # mu_never
    for j in range(S):
        theta_ols[1 + j] = beta0[2 + j]  # mu_switcher_s
    theta_ols[1 + S] = beta0[1]  # kappa
    theta_ols[2 + S] = 0.0  # Delta_base
    theta_ols[3 + S] = -1.0  # phi default from run_grc
    K = data["X_cov"].shape[1]
    for k in range(K):
        theta_ols[4 + S + k] = beta0[2 + S + k]

    # Candidate W matrices
    W_identity = np.eye(m)
    ZtZ_over_n = Z.T @ Z / n
    W_ZtZ = np.linalg.pinv(ZtZ_over_n, rcond=1e-10)
    S_ols = est._cluster_S(theta_ols, data)
    W_ols = np.linalg.pinv(S_ols, rcond=1e-10)
    S_py = est._cluster_S(theta_py, data)
    W_py = np.linalg.pinv(S_py, rcond=1e-10)
    S_stata = est._cluster_S(theta_stata, data)
    W_stata = np.linalg.pinv(S_stata, rcond=1e-10)

    print(f"Stata target SE(phi) = 0.070457\n")
    print(f"Rows: W choice. Columns: evaluation theta.\n")

    cases = [
        ("W = I (1-step identity)", W_identity),
        ("W = (Z'Z/n)^{-1}", W_ZtZ),
        ("W = S^{-1}(theta_ols_init)", W_ols),
        ("W = S^{-1}(theta_py)", W_py),
        ("W = S^{-1}(theta_stata)", W_stata),
    ]
    thetas = [
        ("theta_py", theta_py),
        ("theta_stata", theta_stata),
    ]

    print(f"  {'W choice':<30s}  {'theta':<12s}  "
          f"{'SE_eff':>10s}  {'SE_sandwich':>12s}")
    for wname, W in cases:
        for tname, theta in thetas:
            se_eff, se_sw = _var_under_W(est, data, theta, W, phi_idx)
            print(f"  {wname:<30s}  {tname:<12s}  "
                  f"{se_eff:>10.6f}  {se_sw:>12.6f}")

    # Extra: at theta_stata, W = S^{-1}(theta_stata), compare to both
    # sandwich and efficient — should be identical there
    print()
    print("Sanity: at theta with W = S^{-1}(theta), eff should equal sandwich.")

    # Additional angle: compute the matrix W that REPRODUCES Stata's SE(phi).
    # Specifically, search for a scalar alpha such that
    #   V = (G'[alpha W_py]G)^{-1} / n matches.
    # This tells us nothing useful if it's a basis-change, but is cheap.
    G = est._gradient_of_g(theta_stata, data)
    GtWG_py = G.T @ W_py @ G
    GtWG_py_inv = np.linalg.pinv(GtWG_py, rcond=1e-10)
    V_py_scale = GtWG_py_inv / n
    print(
        f"\nV_py[phi,phi] at theta_stata = {V_py_scale[phi_idx, phi_idx]:.6e}"
    )
    print(
        f"Stata V[phi,phi] target       = {0.070457**2:.6e}"
    )
    print(
        f"Ratio (V_py / V_stata)        = "
        f"{V_py_scale[phi_idx, phi_idx] / 0.070457**2:.4f}"
    )


if __name__ == "__main__":
    main()
