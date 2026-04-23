"""Collinearity diagnostics on Z for the IDN/cons/urban/unb spec.

What we're testing: the sequential Gram-Schmidt in ``_drop_collinear``
drops exactly 1 column of Z (``switcher_31 * choice``) at tol=1e-7.
Stata's ``gmm`` may drop a different number or different columns. If Z's
effective rank is lower than 64 (the m after our 1 drop), then the
phi-identifying direction may sit on a nearly-collinear subspace that
Stata excises but we don't, inflating Var(phi).

Outputs:
    * Effective rank of Z at tolerances 1e-5 through 1e-10.
    * Candidate columns to drop under each tolerance.
    * SE(phi) under each alternative Z (dropping 0, 1, 2, 3, 4 columns).
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent
STATA_CSV = HERE / "stata_out_idn_cons_urb_unb.csv"
PY_CSV = HERE / "python_out_idn_cons_urb_unb.csv"


def _build_state(theta_src_csv: Path, theta_col: str):
    df = load_consumption_unb("IDN")
    est = RestrictedGRC(
        outcome="lndepvar", choice="choice", trajectory="trajectory",
        individual_id="pid", covariates=[], unbalanced_col="unbalanced",
    )
    data = est._build_design(df)
    Z_raw = est._build_instruments(data)
    data["n"] = len(data["y"])
    data["base"] = 2

    # Reconstruct theta from CSV
    d = pd.read_csv(theta_src_csv)
    theta = np.zeros(1 + len(data["switchers"]) + 3 + data["X_cov"].shape[1])
    S = len(data["switchers"])
    coefs = dict(zip(d["name"], d[theta_col]))
    theta[0] = coefs["mu:never"]
    for j, s in enumerate(data["switchers"]):
        theta[1 + j] = coefs[f"mu:switcher_{s}"]
    theta[1 + S] = coefs["kappa:_cons"]
    theta[2 + S] = coefs["Delta_base:_cons"]
    theta[3 + S] = coefs["phi:_cons"]
    for k, c in enumerate(data["cov_names"]):
        theta[4 + S + k] = coefs[f"xb:{c}"]
    return est, data, Z_raw, theta, 3 + S


def _z_col_names(est, data):
    names = []
    for c in data["cov_names"]:
        names.append(c)
    names.append("never")
    for s in data["switchers"]:
        names.append(f"switcher_{s}")
    names.append("choice")
    names.append("always_choice")
    for s in data["switchers"]:
        names.append(f"switcher_{s}_choice")
    return names


def _rank_at_tol(Z: np.ndarray, tol: float) -> int:
    """Effective rank via SVD with relative tolerance ``tol``."""
    s = np.linalg.svd(Z, compute_uv=False)
    return int(np.sum(s > tol * s[0]))


def _drop_k(Z: np.ndarray, tol: float) -> tuple[np.ndarray, np.ndarray]:
    kept_mask = np.ones(Z.shape[1], dtype=bool)
    kept_idx = []
    Q_cols = []
    for j in range(Z.shape[1]):
        col = Z[:, j].astype(float)
        cn = float(np.linalg.norm(col))
        if cn == 0.0:
            kept_mask[j] = False
            continue
        if Q_cols:
            Q = np.column_stack(Q_cols)
            r = col - Q @ (Q.T @ col)
            r = r - Q @ (Q.T @ r)
        else:
            r = col
        rn = float(np.linalg.norm(r))
        if rn / cn < tol:
            kept_mask[j] = False
            continue
        Q_cols.append(r / rn)
        kept_idx.append(j)
    return Z[:, kept_mask], np.array(kept_idx, dtype=int)


def _se_phi_under_drop(est, data, Z_sub, theta, phi_idx):
    data_copy = dict(data)
    data_copy["Z"] = Z_sub
    G = est._gradient_of_g(theta, data_copy)
    Smat = est._cluster_S(theta, data_copy)
    W = np.linalg.pinv(Smat, rcond=1e-10)
    GtWG = G.T @ W @ G
    V = np.linalg.pinv(GtWG, rcond=1e-10) / data_copy["n"]
    return float(np.sqrt(max(V[phi_idx, phi_idx], 0.0))), V


def main():
    est, data, Z, theta, phi_idx = _build_state(PY_CSV, "coef_py")
    names = _z_col_names(est, data)
    print(f"Z shape: {Z.shape}  (names: {len(names)})")

    print("\n[A] SVD spectrum of Z (first 8 + last 8 singular values):")
    s = np.linalg.svd(Z, compute_uv=False)
    with np.printoptions(precision=3, suppress=False):
        print("  leading: ", s[:8])
        print("  tailing: ", s[-8:])
    print(f"  s[0] = {s[0]:.3e}, s[-1] = {s[-1]:.3e}")

    print("\n[B] Effective rank at tolerances 1e-4 ... 1e-10:")
    for tol in (1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10):
        print(f"  tol = {tol:.0e}  rank = {_rank_at_tol(Z, tol)}")

    print("\n[C] Sequential Gram-Schmidt drop at different tolerances:")
    for tol in (1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9):
        Z_sub, kept = _drop_k(Z, tol)
        dropped = [i for i in range(Z.shape[1]) if i not in kept.tolist()]
        print(f"  tol = {tol:.0e}  kept = {len(kept):2d}  "
              f"dropped columns = {dropped} "
              f"names = {[names[i] for i in dropped]}")

    print("\n[D] SE(phi) under different Z subsets (W = S^{-1} at theta_py):")
    Z_sub, kept = _drop_k(Z, 1e-7)
    base_se, _ = _se_phi_under_drop(est, data, Z_sub, theta, phi_idx)
    print(f"  baseline (1 drop, tol 1e-7): SE(phi) = {base_se:.6f}")

    # Try aggressively dropping more columns one at a time from the sw*choice block.
    # Stata's log (previous runs) said ``switcher_31_choice`` omitted; the
    # next candidates are other switcher*choice columns with low marginal
    # residual. Rank down to 60 / 59 / 58 columns:
    for target in (62, 60, 58, 56):
        # Start with the 1e-7 kept set and greedily drop the smallest-residual
        # remaining column until we hit `target`.
        kept_list = list(kept)
        Q_cols = []
        Z_work = np.zeros((Z.shape[0], 0))
        residuals = []
        for j in kept_list:
            col = Z[:, j].astype(float)
            cn = float(np.linalg.norm(col))
            if Q_cols:
                Q = np.column_stack(Q_cols)
                r = col - Q @ (Q.T @ col)
                r = r - Q @ (Q.T @ r)
            else:
                r = col
            rn = float(np.linalg.norm(r))
            residuals.append(rn / cn)
            Q_cols.append(r / max(rn, 1e-30))
        # Drop the smallest-residual entries until len = target
        order = np.argsort(residuals)
        drop_set = set(kept_list[i] for i in order[: max(0, Z.shape[1] - target - 1)])
        keep_mask = np.array(
            [(j in kept) and (j not in drop_set) for j in range(Z.shape[1])]
        )
        Z_t = Z[:, keep_mask]
        if Z_t.shape[1] == 0:
            continue
        se_t, _ = _se_phi_under_drop(est, data, Z_t, theta, phi_idx)
        dropped_names = [names[i] for i in range(Z.shape[1]) if not keep_mask[i]]
        print(f"  m = {Z_t.shape[1]:2d}  SE(phi) = {se_t:.6f}  "
              f"dropped = {dropped_names}")


if __name__ == "__main__":
    main()
