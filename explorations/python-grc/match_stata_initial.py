"""Test whether matching Stata's initial values + 2-step convention makes
Python's SE(phi) match Stata's.

Stata's ``initial_values`` program (``0_programs.do:1412``) does:
    reg y always* switcher_*, nocons vce(cluster pid)
    --> kappa = _b[always]
    --> mu_s  = _b[switcher_s] for each switcher
    --> mu_1 (i.e., mu_never) = 0 HARDCODED
    --> Delta_base = 0 (not in initial; Stata gmm defaults unspecified to 0)
    --> phi = -1 (embedded in the equation via {phi=-1})

Python's current ``_ols_initial_values`` regresses on [never, always, sw_d, X]
so mu_never gets the OLS coefficient ~11.35. That starting point for
mu_never is ~11 units away from Stata's 0, which may lead the step-1
optimizer down a different path.

If the step-1 theta_1 matches Stata's, then W_2 = S^{-1}(theta_1) will match,
and the full variance chain downstream will match to machine precision.
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


def _stata_initial_values(est: RestrictedGRC, data: dict) -> np.ndarray:
    """Replicate Stata's ``initial_values`` program exactly.

    OLS of y on [always, always_choice, switcher_2..switcher_31,
    switcher_2_choice..switcher_31_choice, X_cov] with no constant, then
    set mu_never = 0 and phi = -1, Delta_base = 0.
    """
    y = data["y"]
    D = data["D"]
    always_d = data["always_d"]
    sw_d = data["sw_d"]
    X_cov = data["X_cov"]

    # Stata's regression matrix: always, always_choice,
    # switcher_s (for each s), switcher_s_choice (for each s), X_cov.
    # This differs from Python's current initial values, which uses
    # [never, always, switcher_s, X_cov] (no choice interactions).
    cols = [always_d[:, None], (always_d * D)[:, None]]
    cols.append(sw_d)
    cols.append(sw_d * D[:, None])
    if X_cov.shape[1] > 0:
        cols.append(X_cov)
    X = np.column_stack(cols)
    beta, *_ = np.linalg.lstsq(X, y, rcond=None)
    # Layout: beta[0] = kappa (always), beta[1] = Delta_always
    # (always*D), beta[2:2+S] = mu_s, beta[2+S:2+2S] = Delta_s, rest =
    # gamma.
    S = sw_d.shape[1]
    kappa = beta[0]
    mu_s = beta[2:2 + S]
    gamma = beta[2 + 2 * S:]

    # Assemble theta in Python's parameter layout:
    # [mu_never, mu_s1..mu_sS, kappa, Delta_base, phi, gamma]
    theta = np.zeros(1 + S + 3 + X_cov.shape[1])
    theta[0] = 0.0  # mu_never hardcoded per Stata's initial_values
    for j in range(S):
        theta[1 + j] = mu_s[j]
    theta[1 + S] = kappa
    theta[2 + S] = 0.0  # Delta_base
    theta[3 + S] = -1.0  # phi
    for k in range(X_cov.shape[1]):
        theta[4 + S + k] = gamma[k]
    return theta


def _minimize(est, data, theta_start, W, label=""):
    def obj(theta):
        return est._objective(theta, data, W)

    def grad(theta):
        g = est._moments_individual(theta, data).sum(axis=0) / data["n"]
        G = est._gradient_of_g(theta, data)
        return 2.0 * data["n"] * (G.T @ W @ g)

    t0 = time.time()
    r1 = optimize.minimize(
        obj, theta_start, jac=grad, method="L-BFGS-B",
        options={"gtol": 1e-8, "maxiter": 2000, "disp": False},
    )
    r_nm = optimize.minimize(
        obj, r1.x, method="Nelder-Mead",
        options={"xatol": 1e-8, "fatol": 1e-8, "maxiter": 3000,
                 "adaptive": True, "disp": False},
    )
    theta_out = r_nm.x if r_nm.fun < r1.fun else r1.x
    print(f"  [{label}] L-BFGS-B obj = {r1.fun:.6f} ({r1.nit} iter, "
          f"{r1.message.decode() if isinstance(r1.message, bytes) else r1.message}); "
          f"NM obj = {r_nm.fun:.6f}; took {time.time() - t0:.1f}s")
    return theta_out, time.time() - t0


def main():
    t_all = time.time()
    print("Loading data...")
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

    # Stata-style initial values
    theta0 = _stata_initial_values(est, data)
    print(f"\nStata-style initial theta:")
    print(f"  mu_never    = {theta0[0]:.4f} (Stata hardcodes 0)")
    print(f"  mu_switcher_2 = {theta0[1]:.4f}")
    print(f"  kappa       = {theta0[1 + S]:.4f}")
    print(f"  phi         = {theta0[3 + S]:.4f} (Stata hardcodes -1)")
    print(f"  Delta_base  = {theta0[2 + S]:.4f}")

    # Step 1: W_1 = (Z'Z/n)^{-1}, Stata's winitial(unadjusted) default.
    print("\n[Step 1] W_1 = (Z'Z/n)^{-1}, initial from Stata convention")
    W1 = np.linalg.pinv(Z.T @ Z / n, rcond=1e-10)
    theta1, t_s1 = _minimize(est, data, theta0, W1, label="step 1")
    print(f"  theta_1[phi] = {theta1[phi_idx]:.6f}")
    print(f"  theta_1[mu_never] = {theta1[0]:.6f}")
    print(f"  theta_1[kappa] = {theta1[1 + S]:.6f}")
    print(f"  theta_1[Delta_base] = {theta1[2 + S]:.6f}")

    # Step 2: W_2 = S^{-1}(theta_1), held fixed.
    print("\n[Step 2] W_2 = S^{-1}(theta_1)")
    S1 = est._cluster_S(theta1, data)
    W2 = np.linalg.pinv(S1, rcond=1e-10)
    theta2, t_s2 = _minimize(est, data, theta1, W2, label="step 2")
    print(f"  theta_2[phi] = {theta2[phi_idx]:.6f}")

    # Sandwich variance
    G2 = est._gradient_of_g(theta2, data)
    S2 = est._cluster_S(theta2, data)
    GtWG = G2.T @ W2 @ G2
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    meat = G2.T @ W2 @ S2 @ W2 @ G2
    V_sw = GtWG_inv @ meat @ GtWG_inv / n
    se_phi_sw = float(np.sqrt(max(V_sw[phi_idx, phi_idx], 0.0)))

    # J
    g2 = est._moments_individual(theta2, data).sum(axis=0) / n
    J = float(n * g2 @ W2 @ g2)

    # Compare W_2 to Stata's e(W)
    stata_W_full = pd.read_csv(HERE / "stata_W.csv")
    stata_W_size = int(stata_W_full[["row", "col"]].max().max())
    Wfull = np.zeros((stata_W_size, stata_W_size))
    for _, row in stata_W_full.iterrows():
        Wfull[int(row["row"]) - 1, int(row["col"]) - 1] = float(row["value"])
    # Drop the zero column/row for switcher_31_choice (index 64 in Stata's 65-wide Z)
    # Stata order: [cov, never, sw_2..sw_31, choice, always_choice, sw_2_ch..sw_31_ch]
    # Python kept order matches Stata except drops switcher_31_choice.
    stata_drop_idx = 64  # 0-based; last column in Stata's Z
    keep_mask = np.ones(stata_W_size, dtype=bool)
    keep_mask[stata_drop_idx] = False
    W_stata = Wfull[np.ix_(keep_mask, keep_mask)]
    diff = np.linalg.norm(W2 - W_stata) / np.linalg.norm(W_stata)
    print(f"\nW_2 (Python, Stata-init) vs Stata's e(W):")
    print(f"  ||W_py - W_stata|| / ||W_stata|| = {diff:.3e}")
    print(f"  (was 2.833e-01 for Python's iterated-GMM W)")

    print("\n=== Summary ===")
    print(f"Stata target: phi = -2.4455, SE = 0.0705, J = 86.52")
    print(f"Python (Stata-init 2-step):")
    print(f"  phi = {theta2[phi_idx]:.6f}")
    print(f"  SE(phi) sandwich = {se_phi_sw:.6f}")
    print(f"  J = {J:.4f}")
    print(f"Total runtime: {time.time() - t_all:.1f}s ({t_s1 + t_s2:.1f}s optimizer)")


if __name__ == "__main__":
    main()
