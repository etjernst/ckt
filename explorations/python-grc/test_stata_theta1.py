"""Smoking-gun test: use Stata's exact theta_1 to compute W_2, then do
Python's step 2 + VCE. If SE(phi) matches Stata's 0.0705, the remaining
gap is entirely about which theta_1 the step-1 optimizer stops at.

Also: compute W_2 at three interpolated theta_1's (Stata's, Python's, and
a midpoint) to show how sensitive the eventual SE(phi) is to the step-1
stopping point.
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import optimize

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent


def _reconstruct(data, coefs):
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


def _optimize(est, data, theta_start, W):
    def obj(theta):
        return est._objective(theta, data, W)

    def grad(theta):
        g = est._moments_individual(theta, data).sum(axis=0) / data["n"]
        G = est._gradient_of_g(theta, data)
        return 2.0 * data["n"] * (G.T @ W @ g)

    r1 = optimize.minimize(
        obj, theta_start, jac=grad, method="L-BFGS-B",
        options={"gtol": 1e-8, "maxiter": 2000, "disp": False},
    )
    r_nm = optimize.minimize(
        obj, r1.x, method="Nelder-Mead",
        options={"xatol": 1e-8, "fatol": 1e-8, "maxiter": 3000,
                 "adaptive": True, "disp": False},
    )
    return r_nm.x if r_nm.fun < r1.fun else r1.x


def _se_and_J(est, data, theta2, W2, phi_idx):
    G = est._gradient_of_g(theta2, data)
    S2 = est._cluster_S(theta2, data)
    GtWG = G.T @ W2 @ G
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    meat = G.T @ W2 @ S2 @ W2 @ G
    V_sw = GtWG_inv @ meat @ GtWG_inv / data["n"]
    g = est._moments_individual(theta2, data).sum(axis=0) / data["n"]
    J = float(data["n"] * g @ W2 @ g)
    se = float(np.sqrt(max(V_sw[phi_idx, phi_idx], 0.0)))
    return se, J


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

    # Load Stata's theta_1 (step-1 result, from gmm onestep)
    b1 = pd.read_csv(HERE / "stata_theta1.csv")
    coefs_st1 = dict(zip(b1["name"], b1["value"]))
    theta1_stata = _reconstruct(data, coefs_st1)

    # Python's step-1 theta from earlier 2-step run
    # (we could re-derive but cache it; phi_1 = -2.7253)
    # Easier: recompute via a fresh step-1 minimize.
    beta0_ols = est._ols_initial_values(data)
    theta0 = np.zeros(1 + S + 3 + data["X_cov"].shape[1])
    theta0[0] = beta0_ols[0]  # mu_never from OLS
    for j in range(S):
        theta0[1 + j] = beta0_ols[2 + j]
    theta0[1 + S] = beta0_ols[1]
    theta0[2 + S] = 0.0
    theta0[3 + S] = -1.0
    for k in range(data["X_cov"].shape[1]):
        theta0[4 + S + k] = beta0_ols[2 + S + k]
    W1 = np.linalg.pinv(Z.T @ Z / n, rcond=1e-10)

    print("Recovering Python's step-1 theta_1 (for side-by-side compare)...")
    t0 = time.time()
    theta1_py = _optimize(est, data, theta0, W1)
    print(f"  done ({time.time() - t0:.1f}s)")

    # Compute step-1 Q at both theta_1's
    obj_stata = est._objective(theta1_stata, data, W1) / n
    obj_py = est._objective(theta1_py, data, W1) / n

    print(f"\nStep-1 objective Q(b) = g'W_1 g:")
    print(f"  Stata theta_1:   Q = {obj_stata:.8f}  (report says 0.00195)")
    print(f"  Python theta_1:  Q = {obj_py:.8f}")
    print(f"  Python step-1 is LOWER minimum: {obj_py < obj_stata}")

    print(f"\nTheta_1 coefficients (first 6 + phi, Delta_base, kappa):")
    print(f"  {'param':<25s}  {'Stata theta_1':>15s}  "
          f"{'Python theta_1':>15s}  {'|diff|':>10s}")
    py_names = ["mu:never"]
    py_names += [f"mu:switcher_{s}" for s in data["switchers"]]
    py_names += ["kappa:_cons", "Delta_base:_cons", "phi:_cons"]
    py_names += [f"xb:{c}" for c in data["cov_names"]]
    for i, nm in enumerate(py_names):
        if nm in {"mu:never", "kappa:_cons", "Delta_base:_cons", "phi:_cons",
                  "mu:switcher_2", "mu:switcher_11", "mu:switcher_31",
                  "xb:unbalanced", "xb:unbalanced_choice"}:
            d = abs(theta1_stata[i] - theta1_py[i])
            print(f"  {nm:<25s}  {theta1_stata[i]:>15.6f}  "
                  f"{theta1_py[i]:>15.6f}  {d:>10.3e}")

    # Now: Use Stata's theta_1 to compute W_2, do Python step 2, get SE.
    print("\n[A] Path A: use Stata's theta_1 -> W_2 -> Python step 2 + VCE")
    S_at_stata1 = est._cluster_S(theta1_stata, data)
    W2_stata1 = np.linalg.pinv(S_at_stata1, rcond=1e-10)
    t0 = time.time()
    theta2_via_stata1 = _optimize(est, data, theta1_stata, W2_stata1)
    se_A, J_A = _se_and_J(est, data, theta2_via_stata1, W2_stata1, phi_idx)
    print(f"  theta_2[phi] = {theta2_via_stata1[phi_idx]:.6f}  "
          f"(Stata: -2.4455)")
    print(f"  SE(phi) sandwich = {se_A:.6f}  (Stata: 0.0705)")
    print(f"  J = {J_A:.4f}  (Stata: 86.52)")
    print(f"  Step 2 took {time.time() - t0:.1f}s")

    # Compare Python's W_2 (from Stata's theta_1) to Stata's e(W).
    stata_W_full = pd.read_csv(HERE / "stata_W.csv")
    p_m_full = int(stata_W_full[["row", "col"]].max().max())
    Wfull = np.zeros((p_m_full, p_m_full))
    for _, row in stata_W_full.iterrows():
        Wfull[int(row["row"]) - 1, int(row["col"]) - 1] = float(row["value"])
    keep_mask = np.ones(p_m_full, dtype=bool)
    keep_mask[64] = False  # drop o.switcher_31_choice
    W_stata = Wfull[np.ix_(keep_mask, keep_mask)]
    rel = np.linalg.norm(W2_stata1 - W_stata) / np.linalg.norm(W_stata)
    print(f"  ||W_2(Python from Stata theta_1) - W_stata|| / ||W_stata|| = "
          f"{rel:.3e}")

    # Path B: use Python's theta_1 -> W_2 -> Python step 2. For reference.
    print("\n[B] Path B (reference): use Python's theta_1 -> W_2 -> step 2 + VCE")
    S_at_py1 = est._cluster_S(theta1_py, data)
    W2_py1 = np.linalg.pinv(S_at_py1, rcond=1e-10)
    theta2_via_py1 = _optimize(est, data, theta1_py, W2_py1)
    se_B, J_B = _se_and_J(est, data, theta2_via_py1, W2_py1, phi_idx)
    print(f"  theta_2[phi] = {theta2_via_py1[phi_idx]:.6f}")
    print(f"  SE(phi) sandwich = {se_B:.6f}")
    print(f"  J = {J_B:.4f}")


if __name__ == "__main__":
    main()
