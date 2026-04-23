"""Speed-win candidate: drop the Nelder-Mead polish after outer iter 0
of iterated GMM. Re-runs the IDN consumption fit with this strategy and
compares final theta, J, SE(phi) to the cached baseline at
python_out_idn_cons_urb_unb.csv (phi = -2.4639, SE(phi) = 0.1991).

If theta, J, SE all match within tight tolerance, we save ~10 min per fit.
If they diverge, NM was load-bearing and we keep it.
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import optimize

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear, _robust_inv


HERE = Path(__file__).parent
BASELINE_CSV = HERE / "python_out_idn_cons_urb_unb.csv"


def main() -> None:
    df = load_consumption_unb("IDN")
    est = RestrictedGRC(
        outcome="lndepvar", choice="choice", trajectory="trajectory",
        individual_id="pid", covariates=[], unbalanced_col="unbalanced",
    )
    data = est._build_design(df)
    Z_raw = est._build_instruments(data)
    Z, _ = _drop_collinear(Z_raw)
    data["Z"] = Z
    data["n"] = len(data["y"])
    data["base"] = 2

    n = data["n"]
    m = Z.shape[1]
    S = len(data["switchers"])
    phi_idx = 3 + S

    beta0_ols = est._ols_initial_values(data)
    theta0 = np.zeros(1 + S + 3 + data["X_cov"].shape[1])
    theta0[0] = beta0_ols[0]
    for j in range(S):
        theta0[1 + j] = beta0_ols[2 + j]
    theta0[1 + S] = beta0_ols[1]
    theta0[2 + S] = 0.0
    theta0[3 + S] = -1.0
    for k in range(data["X_cov"].shape[1]):
        theta0[4 + S + k] = beta0_ols[2 + S + k]

    def grad(theta: np.ndarray, W: np.ndarray) -> np.ndarray:
        g = est._moments_individual(theta, data).sum(axis=0) / data["n"]
        G = est._gradient_of_g(theta, data)
        return 2.0 * data["n"] * (G.T @ W @ g)

    def optimize_step(theta_start: np.ndarray, W: np.ndarray,
                       use_nm: bool) -> tuple[np.ndarray, float, float]:
        """L-BFGS-B with optional Nelder-Mead polish. Returns (theta, fun, nm_time)."""
        r1 = optimize.minimize(
            est._objective, theta_start, args=(data, W),
            jac=lambda t, *a: grad(t, W),
            method="L-BFGS-B",
            options={"gtol": 1e-8, "maxiter": 1000, "disp": False},
        )
        if not use_nm:
            return r1.x, float(r1.fun), 0.0
        t_nm = time.time()
        r_nm = optimize.minimize(
            est._objective, r1.x, args=(data, W),
            method="Nelder-Mead",
            options={"xatol": 1e-7, "fatol": 1e-7,
                     "maxiter": 500, "adaptive": True, "disp": False},
        )
        nm_time = time.time() - t_nm
        if r_nm.fun < r1.fun:
            return r_nm.x, float(r_nm.fun), nm_time
        return r1.x, float(r1.fun), nm_time

    # Iterated GMM, NM only on outer iter 0
    W = np.eye(m)
    theta = theta0
    theta_prev = theta
    history = []
    converged = False
    t_total = time.time()
    for k in range(8):
        t_iter = time.time()
        use_nm = (k == 0)
        theta, fun, nm_time = optimize_step(theta, W, use_nm=use_nm)
        delta = float(np.linalg.norm(theta - theta_prev))
        rel = delta / max(float(np.linalg.norm(theta_prev)), 1.0)
        iter_time = time.time() - t_iter
        history.append({
            "iter": k, "use_nm": use_nm, "obj": fun,
            "delta": delta, "rel": rel,
            "iter_s": iter_time, "nm_s": nm_time,
        })
        print(f"  iter {k}: nm={use_nm}  obj={fun:.6e}  "
              f"delta={delta:.3e}  rel={rel:.3e}  "
              f"time={iter_time:.1f}s (nm={nm_time:.1f}s)")
        if k > 0 and rel < 1e-4:
            converged = True
            break
        S_mat = est._cluster_S(theta, data)
        W = _robust_inv(S_mat)
        theta_prev = theta.copy()

    total_s = time.time() - t_total
    print(f"\nTotal: {total_s:.1f}s   converged={converged}   iters={len(history)}")

    # Variance + J at final theta, W
    G = est._gradient_of_g(theta, data)
    S_at = est._cluster_S(theta, data)
    GtWG = G.T @ W @ G
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    meat = G.T @ W @ S_at @ W @ G
    V = GtWG_inv @ meat @ GtWG_inv / data["n"]
    g_bar = est._moments_individual(theta, data).sum(axis=0) / data["n"]
    J = float(data["n"] * g_bar @ W @ g_bar)
    se_phi = float(np.sqrt(max(V[phi_idx, phi_idx], 0.0)))

    print("\nNo-NM-after-iter0 results:")
    print(f"  phi          = {theta[phi_idx]:.6f}")
    print(f"  SE(phi)      = {se_phi:.6f}")
    print(f"  J            = {J:.4f}")
    print(f"  Delta_base   = {theta[2 + S]:.6f}")
    print(f"  kappa        = {theta[1 + S]:.6f}")

    # Compare to cached baseline
    base = pd.read_csv(BASELINE_CSV)
    base_phi = base.loc[base["name"] == "phi:_cons", "coef_py"].iloc[0]
    base_se = base.loc[base["name"] == "phi:_cons", "se_py"].iloc[0]
    base_dbase = base.loc[base["name"] == "Delta_base:_cons", "coef_py"].iloc[0]
    base_kappa = base.loc[base["name"] == "kappa:_cons", "coef_py"].iloc[0]

    print("\nBaseline (NM every iter):")
    print(f"  phi          = {base_phi:.6f}")
    print(f"  SE(phi)      = {base_se:.6f}")
    print(f"  Delta_base   = {base_dbase:.6f}")
    print(f"  kappa        = {base_kappa:.6f}")

    print("\nDiff (test - baseline):")
    print(f"  phi          : {theta[phi_idx] - base_phi:+.6e}")
    print(f"  SE(phi)      : {se_phi - base_se:+.6e}")
    print(f"  Delta_base   : {theta[2 + S] - base_dbase:+.6e}")
    print(f"  kappa        : {theta[1 + S] - base_kappa:+.6e}")

    # Per-coef summary across all params
    base_coef = dict(zip(base["name"], base["coef_py"]))
    py_names = ["mu:never"]
    py_names += [f"mu:switcher_{s}" for s in data["switchers"]]
    py_names += ["kappa:_cons", "Delta_base:_cons", "phi:_cons"]
    py_names += [f"xb:{c}" for c in data["cov_names"]]
    diffs = []
    for i, nm in enumerate(py_names):
        if nm in base_coef:
            diffs.append(abs(theta[i] - base_coef[nm]))
    diffs = np.array(diffs)
    print(f"\nMax |diff| across all coefs: {diffs.max():.3e}")
    print(f"Median |diff|: {np.median(diffs):.3e}")


if __name__ == "__main__":
    main()
