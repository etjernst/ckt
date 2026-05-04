"""Reproduce Stata's exact two-step GMM convention in Python.

Stata's ``gmm ..., vce(cluster pid)`` does:
    1. Step 1: W_1 = (Z'Z/n)^{-1}; minimize n * g'W_1 g over theta, get theta_1.
    2. Step 2: W_2 = S_cluster^{-1}(theta_1), held fixed during this step;
       minimize n * g'W_2 g over theta, get theta_2. Report theta_2.
    3. VCE (sandwich form):
       V = (G_2' W_2 G_2)^{-1} G_2' W_2 S(theta_2) W_2 G_2
           (G_2' W_2 G_2)^{-1} / n,
       where G_2 = d g_bar / d theta at theta_2.

Python's ``RestrictedGRC.fit()`` instead iterates: W_{k+1} = S^{-1}(theta_k)
to a fixed point. At convergence, W = S^{-1}(theta_hat), so the efficient
formula (G'WG)^{-1}/n coincides with the sandwich. The two estimators are
asymptotically equivalent but differ in finite samples.

This script implements the exact Stata 2-step protocol and reports SE(phi)
for direct comparison with the Stata reference CSV.
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


def _minimize(est, data, theta_start, W, verbose=False, label=""):
    """Minimize n * g'Wg via L-BFGS-B + Nelder-Mead polish. Same recipe as
    grc_gmm.fit() -- re-used so numerical behavior matches."""
    def obj(theta):
        return est._objective(theta, data, W)

    def grad(theta):
        g = est._moments_individual(theta, data).sum(axis=0) / data["n"]
        G = est._gradient_of_g(theta, data)
        return 2.0 * data["n"] * (G.T @ W @ g)

    t0 = time.time()
    r1 = optimize.minimize(
        obj, theta_start, jac=grad, method="L-BFGS-B",
        options={"gtol": 1e-8, "maxiter": 1000, "disp": False},
    )
    r_nm = optimize.minimize(
        obj, r1.x, method="Nelder-Mead",
        options={"xatol": 1e-7, "fatol": 1e-7, "maxiter": 2000,
                 "adaptive": True, "disp": False},
    )
    theta_out = r_nm.x if r_nm.fun < r1.fun else r1.x
    if verbose:
        print(f"  [{label}] L-BFGS-B obj = {r1.fun:.4f}, "
              f"NM obj = {r_nm.fun:.4f}, took {time.time() - t0:.1f}s")
    return theta_out, time.time() - t0


def main():
    t_total = time.time()
    print("Loading data...")
    t0 = time.time()
    df = load_consumption_unb("IDN")
    print(f"  done ({time.time() - t0:.1f}s, {len(df)} rows)")

    est = RestrictedGRC(
        outcome="lndepvar", choice="choice", trajectory="trajectory",
        individual_id="pid", covariates=[], unbalanced_col="unbalanced",
    )
    t0 = time.time()
    data = est._build_design(df)
    Z_raw = est._build_instruments(data)
    Z, kept = _drop_collinear(Z_raw)
    data["Z"] = Z
    data["n"] = len(data["y"])
    data["base"] = 2
    print(f"  built design+Z in {time.time() - t0:.1f}s "
          f"(n={data['n']}, m={Z.shape[1]}, kept {len(kept)}/{Z_raw.shape[1]} cols)")

    n = data["n"]
    m = Z.shape[1]
    S = len(data["switchers"])
    phi_idx = 3 + S

    # Initial values from OLS (Stata's initial_values program).
    beta0 = est._ols_initial_values(data)
    theta0 = np.zeros(1 + S + 3 + data["X_cov"].shape[1])
    theta0[0] = beta0[0]
    for j in range(S):
        theta0[1 + j] = beta0[2 + j]
    theta0[1 + S] = beta0[1]
    theta0[2 + S] = 0.0
    theta0[3 + S] = -1.0
    for k in range(data["X_cov"].shape[1]):
        theta0[4 + S + k] = beta0[2 + S + k]

    # Step 1: W_1 = (Z'Z/n)^{-1}. Stata's winitial(unadjusted) default.
    print("\n[Step 1] W_1 = (Z'Z/n)^{-1}")
    W1 = np.linalg.pinv(Z.T @ Z / n, rcond=1e-10)
    theta1, t_s1 = _minimize(est, data, theta0, W1, verbose=True,
                              label="step 1")
    phi_1 = theta1[phi_idx]
    print(f"  phi_1 = {phi_1:.6f}, step 1 took {t_s1:.1f}s")

    # Step 2: W_2 = S^{-1}(theta_1), HELD FIXED.
    print("\n[Step 2] W_2 = S^{-1}(theta_1)")
    S1 = est._cluster_S(theta1, data)
    W2 = np.linalg.pinv(S1, rcond=1e-10)
    theta2, t_s2 = _minimize(est, data, theta1, W2, verbose=True,
                              label="step 2")
    phi_2 = theta2[phi_idx]
    print(f"  phi_2 = {phi_2:.6f}, step 2 took {t_s2:.1f}s")

    # VCE: Stata's cluster sandwich with W_2.
    G2 = est._gradient_of_g(theta2, data)
    S2 = est._cluster_S(theta2, data)
    GtWG = G2.T @ W2 @ G2
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    meat = G2.T @ W2 @ S2 @ W2 @ G2
    V_sandwich = GtWG_inv @ meat @ GtWG_inv / n
    V_efficient = GtWG_inv / n
    se_sw = float(np.sqrt(max(V_sandwich[phi_idx, phi_idx], 0.0)))
    se_eff = float(np.sqrt(max(V_efficient[phi_idx, phi_idx], 0.0)))

    # J statistic at theta_2 with W_2.
    g2 = est._moments_individual(theta2, data).sum(axis=0) / n
    J = float(n * g2 @ W2 @ g2)

    print()
    print("Stata target SE(phi) = 0.070457, phi = -2.4455, J = 86.52 (df 27)")
    print(f"Python 2-step phi   = {phi_2:.6f}")
    print(f"Python 2-step J     = {J:.4f}  (df = {m - theta2.size})")
    print(f"Python 2-step SE(phi) efficient = {se_eff:.6f}")
    print(f"Python 2-step SE(phi) sandwich  = {se_sw:.6f}")
    print(f"Total runtime: {time.time() - t_total:.1f}s "
          f"({t_s1 + t_s2:.1f}s in optimizer)")

    # Save for downstream comparison.
    out = []
    names = ["mu:never"]
    names += [f"mu:switcher_{s}" for s in data["switchers"]]
    names += ["kappa:_cons", "Delta_base:_cons", "phi:_cons"]
    names += [f"xb:{c}" for c in data["cov_names"]]
    # Sandwich SEs for all params
    se_vec = np.sqrt(np.maximum(np.diag(V_sandwich), 0.0))
    for nm, coef, se in zip(names, theta2, se_vec):
        out.append({"name": nm, "coef_py2step": coef, "se_py2step": se})
    pd.DataFrame(out).to_csv(
        HERE / "python_out_idn_cons_urb_unb_2step.csv", index=False
    )
    print(f"\nWrote python_out_idn_cons_urb_unb_2step.csv")


if __name__ == "__main__":
    main()
