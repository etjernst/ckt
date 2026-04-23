"""SE(phi) diagnostics on the IDN/consumption/urban/unb fit.

Reuses cached theta from the python and Stata output CSVs, reconstructs
the design and moment matrix, and tests the four hypotheses flagged in
``quality_reports/session_logs/2026-04-22_gmm-convergence-audit.md:637``:

    1. Analytic vs. finite-difference Jacobian on the phi column.
    2. Efficient (G'WG)^{-1} vs. sandwich (G'WG)^{-1} G'WSWG (G'WG)^{-1} /n.
    3. (Covered by re-running fit with max_outer=15 -- separate script.)
    4. Effective Stata VCE formula.

Plus: variance evaluated at the Stata theta vs. Python theta, to separate
"variance formula is wrong" from "we converged to a different point".

Usage::

    python check_variance.py          # reuses cached CSVs
    TIME_FD=1 python check_variance.py  # also times the finite-difference
"""

from __future__ import annotations

import os
import time
from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent
STATA_CSV = HERE / "stata_out_idn_cons_urb_unb.csv"
PY_CSV = HERE / "python_out_idn_cons_urb_unb.csv"


def _reconstruct_theta(
    est: RestrictedGRC, data: dict, coefs: dict[str, float]
) -> np.ndarray:
    """Map param_names (from fit()) back into a theta vector.

    Same ordering as ``RestrictedGRC.fit()``: [mu_never, mu_s1..mu_sS,
    kappa, Delta_base, phi, gamma_1..gamma_K].
    """
    switchers = data["switchers"]
    S = len(switchers)
    K = data["X_cov"].shape[1]
    theta = np.zeros(1 + S + 1 + 1 + 1 + K)
    theta[0] = coefs["mu:never"]
    for j, s in enumerate(switchers):
        theta[1 + j] = coefs[f"mu:switcher_{s}"]
    theta[1 + S] = coefs["kappa:_cons"]
    theta[2 + S] = coefs["Delta_base:_cons"]
    theta[3 + S] = coefs["phi:_cons"]
    for k, c in enumerate(data["cov_names"]):
        theta[4 + S + k] = coefs[f"xb:{c}"]
    return theta


def _load_theta(csv: Path, value_col: str) -> dict[str, float]:
    d = pd.read_csv(csv)
    name_col = "name"
    return dict(zip(d[name_col], d[value_col]))


def _finite_diff_jacobian(est: RestrictedGRC, theta: np.ndarray,
                          data: dict, h: float = 1e-5) -> np.ndarray:
    """Central-difference ``d g_bar / d theta``, shape (m, p).

    Computed moment-by-moment so it is cheap in RAM, and only on the full
    parameter vector so we can compare every column against the analytic
    Jacobian (not just phi's).
    """
    p = theta.size
    m = data["Z"].shape[1]
    G = np.zeros((m, p))
    n = data["n"]
    for k in range(p):
        tk = theta.copy()
        step = h * max(abs(theta[k]), 1.0)
        tk[k] = theta[k] + step
        g_plus = est._moments_individual(tk, data).sum(axis=0) / n
        tk[k] = theta[k] - step
        g_minus = est._moments_individual(tk, data).sum(axis=0) / n
        G[:, k] = (g_plus - g_minus) / (2.0 * step)
    return G


def _variance_formulas(est: RestrictedGRC, theta: np.ndarray,
                       data: dict) -> dict[str, np.ndarray]:
    """Return V_efficient and V_sandwich at ``theta`` with W = S^{-1}."""
    G = est._gradient_of_g(theta, data)
    S = est._cluster_S(theta, data)
    W = np.linalg.pinv(S, rcond=1e-10)
    GtWG = G.T @ W @ G
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    n = data["n"]

    V_eff = GtWG_inv / n
    meat = G.T @ W @ S @ W @ G
    V_sw = GtWG_inv @ meat @ GtWG_inv / n
    return {"V_efficient": V_eff, "V_sandwich": V_sw, "G": G, "S": S, "W": W}


def _se_of_phi(V: np.ndarray, phi_idx: int) -> float:
    v = V[phi_idx, phi_idx]
    return float(np.sqrt(max(v, 0.0)))


def main() -> None:
    print("Loading data...")
    t0 = time.time()
    df = load_consumption_unb("IDN")
    print(f"  loaded in {time.time() - t0:.1f}s ({len(df)} rows)")

    est = RestrictedGRC(
        outcome="lndepvar",
        choice="choice",
        trajectory="trajectory",
        individual_id="pid",
        covariates=[],
        unbalanced_col="unbalanced",
    )
    t0 = time.time()
    data = est._build_design(df)
    Z_raw = est._build_instruments(data)
    Z_kept, kept_idx = _drop_collinear(Z_raw)
    data["Z"] = Z_kept
    data["Z_kept_idx"] = kept_idx
    data["n"] = len(data["y"])
    data["base"] = 2  # Stata and Python both settle on base = 2
    print(f"  built design + instruments in {time.time() - t0:.1f}s "
          f"(n={data['n']}, m={Z_kept.shape[1]}, dropped="
          f"{Z_raw.shape[1] - Z_kept.shape[1]})")

    py_coefs = _load_theta(PY_CSV, "coef_py")
    st_coefs = _load_theta(STATA_CSV, "coef")
    theta_py = _reconstruct_theta(est, data, py_coefs)
    theta_st = _reconstruct_theta(est, data, st_coefs)

    S = len(data["switchers"])
    phi_idx = 3 + S
    p = theta_py.size
    m = data["Z"].shape[1]
    print(f"  p = {p}, m = {m}, phi_idx = {phi_idx}, "
          f"base switcher = {data['base']}")
    print(f"  switcher index list: {data['switchers']}")

    # ------------------------------------------------------------------
    # Diagnostic 1: analytic vs. finite-difference Jacobian at theta_py.
    # ------------------------------------------------------------------
    print("\n[1] Analytic vs. finite-difference Jacobian (at theta_py)...")
    t0 = time.time()
    G_an = est._gradient_of_g(theta_py, data)
    t_an = time.time() - t0
    t0 = time.time()
    G_fd = _finite_diff_jacobian(est, theta_py, data, h=1e-5)
    t_fd = time.time() - t0
    print(f"  timing: analytic {t_an:.2f}s, finite-diff {t_fd:.2f}s")

    col_diff = np.max(np.abs(G_an - G_fd), axis=0)
    phi_col_an = G_an[:, phi_idx]
    phi_col_fd = G_fd[:, phi_idx]
    phi_maxdiff = float(np.max(np.abs(phi_col_an - phi_col_fd)))
    phi_reldiff = phi_maxdiff / max(float(np.max(np.abs(phi_col_an))), 1e-30)
    print(f"  max |G_analytic - G_fd| per column (abs): "
          f"min={col_diff.min():.2e}, max={col_diff.max():.2e}")
    print(f"  phi column: max |diff| = {phi_maxdiff:.2e}, "
          f"relative to ||phi col||_inf = {phi_reldiff:.2e}")

    # Identify which columns have large discrepancy
    worst = np.argsort(-col_diff)[:5]
    print("  five worst columns (analytic-vs-FD max diff):")
    for i in worst:
        nm = "mu:never"
        if 1 <= i < 1 + S:
            nm = f"mu:switcher_{data['switchers'][i - 1]}"
        elif i == 1 + S:
            nm = "kappa"
        elif i == 2 + S:
            nm = "Delta_base"
        elif i == 3 + S:
            nm = "phi"
        else:
            k = i - (4 + S)
            nm = f"xb:{data['cov_names'][k]}"
        print(f"    col {i:2d} ({nm}): {col_diff[i]:.2e}")

    # ------------------------------------------------------------------
    # Diagnostic 2: efficient vs. sandwich variance at theta_py.
    # ------------------------------------------------------------------
    print("\n[2] Efficient vs. sandwich variance (at theta_py)...")
    res_py = _variance_formulas(est, theta_py, data)
    se_eff_py = _se_of_phi(res_py["V_efficient"], phi_idx)
    se_sw_py = _se_of_phi(res_py["V_sandwich"], phi_idx)
    print(f"  SE(phi) efficient  = {se_eff_py:.6f}")
    print(f"  SE(phi) sandwich   = {se_sw_py:.6f}")
    print(f"  Stata SE(phi)      = 0.070457")

    # Effective weight matrix quality: ||W @ S - I||
    WS = res_py["W"] @ res_py["S"]
    eye_gap = np.linalg.norm(WS - np.eye(m)) / np.sqrt(m)
    print(f"  ||W@S - I||/sqrt(m) = {eye_gap:.2e} (0 = efficient W)")

    # ------------------------------------------------------------------
    # Diagnostic 2b: same formulas at the Stata theta.
    # ------------------------------------------------------------------
    print("\n[2b] Same formulas at Stata's theta...")
    res_st = _variance_formulas(est, theta_st, data)
    se_eff_st = _se_of_phi(res_st["V_efficient"], phi_idx)
    se_sw_st = _se_of_phi(res_st["V_sandwich"], phi_idx)
    print(f"  SE(phi) efficient at theta_stata = {se_eff_st:.6f}")
    print(f"  SE(phi) sandwich  at theta_stata = {se_sw_st:.6f}")

    # ------------------------------------------------------------------
    # Diagnostic 3: structure of G'WG near phi
    # ------------------------------------------------------------------
    print("\n[3] Condition number and collinearity of G'WG...")
    G = res_py["G"]
    W = res_py["W"]
    GtWG = G.T @ W @ G
    eigvals = np.linalg.eigvalsh((GtWG + GtWG.T) / 2.0)
    print(f"  eigvals(G'WG): min={eigvals.min():.2e}, max={eigvals.max():.2e}")
    print(f"  condition number = {eigvals.max() / max(eigvals.min(), 1e-30):.2e}")

    # How much of SE(phi) comes from each eigendirection?
    # V = U diag(1/eig) U^T (approximately). phi variance = sum_k u_{phi,k}^2 / eig_k.
    evals, evecs = np.linalg.eigh((GtWG + GtWG.T) / 2.0)
    order = np.argsort(evals)  # ascending
    evals, evecs = evals[order], evecs[:, order]
    contribs = evecs[phi_idx, :] ** 2 / np.maximum(evals, 1e-30)
    n = data["n"]
    contribs /= n
    print("  top 5 eigendirections contributing to Var(phi):")
    for rank in range(5):
        idx = rank  # smallest eigenvalue first
        print(
            f"    rank {rank}: eigval = {evals[idx]:.2e}, "
            f"u_phi^2 = {evecs[phi_idx, idx] ** 2:.2e}, "
            f"contrib to Var(phi) = {contribs[idx]:.4e}"
        )
    print(f"  sum contribs (should equal V_eff[phi,phi]): "
          f"{contribs.sum():.4e} vs {res_py['V_efficient'][phi_idx, phi_idx]:.4e}")


if __name__ == "__main__":
    main()
