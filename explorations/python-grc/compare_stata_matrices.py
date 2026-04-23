"""Compare Stata's saved e(V), e(W), e(b) against Python's computations.

Answers definitively: which weighting matrix does Stata end up using, and
what variance formula produces Stata's SE(phi) = 0.0705? Relies on CSVs
produced by ``dump_stata_vcov.do``.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent


def _load_stata_matrix(path: Path, size: int) -> np.ndarray:
    d = pd.read_csv(path)
    M = np.zeros((size, size))
    for _, row in d.iterrows():
        M[int(row["row"]) - 1, int(row["col"]) - 1] = float(row["value"])
    return M


def _z_col_names_python(data):
    names = list(data["cov_names"])  # [unbalanced, unbalanced_choice]
    names.append("never")
    for s in data["switchers"]:
        names.append(f"switcher_{s}")
    names.append("choice")
    names.append("always_choice")
    for s in data["switchers"]:
        names.append(f"switcher_{s}_choice")
    return names


def _stata_W_colnames():
    # As echoed by dump_stata_vcov.log. 65 entries, including the dropped
    # o.switcher_31_choice column (which has zeros in Stata's e(W)).
    base = [
        "unbalanced", "unbalanced_choice", "never",
    ]
    base += [f"switcher_{s}" for s in range(2, 32)]
    base += ["choice", "always_choice"]
    base += [f"switcher_{s}_choice" for s in range(2, 31)]
    base += ["o.switcher_31_choice"]
    return base


def main():
    # Build Python state
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
    S_sw = len(data["switchers"])
    phi_idx = 3 + S_sw

    # Load Stata's b, V, W
    b = pd.read_csv(HERE / "stata_theta_full.csv")
    p_stata = len(b)
    V_stata = _load_stata_matrix(HERE / "stata_vcov.csv", p_stata)
    # e(W) is stored on the FULL 65-column Z (including the dropped
    # switcher_31_choice as a zero row/col).
    W_stata_full = _load_stata_matrix(HERE / "stata_W.csv", Z_raw.shape[1])

    print(f"Stata p = {p_stata}, m (full) = {W_stata_full.shape[0]}")
    print(f"Python p = {1 + S_sw + 3 + data['X_cov'].shape[1]}, "
          f"m (kept) = {m}")

    # Names. Python's Z was trimmed by _drop_collinear (switcher_31_choice
    # dropped); Python's Z has 64 cols corresponding to 64 of these 65 names.
    python_Z_all = _z_col_names_python(data)   # 65 names
    python_Z_kept = [python_Z_all[i] for i in kept]  # 64 names, matching Python Z
    stata_W_names = _stata_W_colnames()  # 65 names incl. o.switcher_31_choice
    assert len(python_Z_all) == len(stata_W_names), (
        f"{len(python_Z_all)} vs {len(stata_W_names)}"
    )
    # Verify Stata's W has zeros in the dropped column
    drop_idx = stata_W_names.index("o.switcher_31_choice")
    drop_col_norm = float(np.linalg.norm(W_stata_full[:, drop_idx]))
    print(f"Stata e(W) column norm for dropped switcher_31_choice: "
          f"{drop_col_norm:.3e}")

    # Reduce Stata's W to the kept columns (match Python's Z order).
    stata_keep_idx = [stata_W_names.index(nm) for nm in python_Z_kept]
    W_stata = W_stata_full[np.ix_(stata_keep_idx, stata_keep_idx)]
    python_Z_names = python_Z_kept  # for downstream printing
    print(f"Stata W (reduced) shape: {W_stata.shape}")

    # --------------------------------------------------------------
    # Reconstruct theta in Python ordering (same as build_instruments
    # implies; here we match by NAME, not by index).
    # --------------------------------------------------------------
    py_coef_names = ["mu:never"]
    py_coef_names += [f"mu:switcher_{s}" for s in data["switchers"]]
    py_coef_names += ["kappa:_cons", "Delta_base:_cons", "phi:_cons"]
    py_coef_names += [f"xb:{c}" for c in data["cov_names"]]
    theta_stata = np.zeros(len(py_coef_names))
    name_to_val = dict(zip(b["name"], b["value"]))
    # Stata names use colon and look like "mu:never" or "Delta_base:_cons"
    for i, nm in enumerate(py_coef_names):
        if nm in name_to_val:
            theta_stata[i] = name_to_val[nm]
        else:
            # scalar params may show up as ":_cons" only, or xb label different
            # Try trimming / alternatives
            alt = nm.replace(":_cons", "")
            if alt in name_to_val:
                theta_stata[i] = name_to_val[alt]
            else:
                raise KeyError(
                    f"Cannot find {nm} in Stata theta. "
                    f"Available: {list(name_to_val.keys())[:5]}"
                )
    print(f"theta_stata reconstructed; phi = {theta_stata[phi_idx]:.6f}")

    # --------------------------------------------------------------
    # Compare Stata's W with Python's candidates.
    # --------------------------------------------------------------
    print("\n[A] Compare Stata's e(W) with Python-computed candidates:")
    S_at_stata = est._cluster_S(theta_stata, data)
    W_py_S_stata = np.linalg.pinv(S_at_stata, rcond=1e-10)

    def _relerr(A, B):
        return float(np.linalg.norm(A - B) / max(np.linalg.norm(B), 1e-30))

    # Stata's GMM weight matrix should be S^{-1}(theta_1) for twostep.
    # Compare against S^{-1} at theta_stata (which should be close if theta_1 ~ theta_2).
    print(f"  ||W_stata - S^(-1)(theta_stata)|| / ||S^(-1)(theta_stata)|| "
          f"= {_relerr(W_stata, W_py_S_stata):.3e}")

    # Absolute magnitude
    print(f"  Frobenius ||W_stata||          = {np.linalg.norm(W_stata):.3e}")
    print(f"  Frobenius ||S^(-1)(theta_st)|| = "
          f"{np.linalg.norm(W_py_S_stata):.3e}")

    # Check a few diagonal entries
    print("\n  Select diagonals (Stata W vs Python S^{-1}(theta_stata)):")
    for i, nm in enumerate(python_Z_names[:5] + python_Z_names[-5:]):
        j = python_Z_names.index(nm)
        print(f"    {nm:25s}  Stata {W_stata[j, j]:+12.4e}  "
              f"Python {W_py_S_stata[j, j]:+12.4e}")

    # --------------------------------------------------------------
    # Use Stata's exact W in Python's sandwich formula and see if SE(phi) matches.
    # --------------------------------------------------------------
    print("\n[B] Python sandwich at theta_stata with Stata's e(W):")
    G = est._gradient_of_g(theta_stata, data)
    GtWG = G.T @ W_stata @ G
    GtWG_inv = np.linalg.pinv(GtWG, rcond=1e-10)
    V_eff = GtWG_inv / n
    meat = G.T @ W_stata @ S_at_stata @ W_stata @ G
    V_sw = GtWG_inv @ meat @ GtWG_inv / n
    se_eff = float(np.sqrt(max(V_eff[phi_idx, phi_idx], 0.0)))
    se_sw = float(np.sqrt(max(V_sw[phi_idx, phi_idx], 0.0)))
    print(f"  SE(phi) efficient       = {se_eff:.6f}")
    print(f"  SE(phi) sandwich        = {se_sw:.6f}")
    print(f"  Stata reported SE(phi)  = {np.sqrt(V_stata[phi_idx, phi_idx]):.6f}")

    # Check whole diagonal of V_sandwich vs V_stata (to confirm formula)
    print("\n[C] Diagonal of Python V_sandwich vs Stata V:")
    se_stata = np.sqrt(np.maximum(np.diag(V_stata), 0.0))
    se_py_sw = np.sqrt(np.maximum(np.diag(V_sw), 0.0))
    se_py_eff = np.sqrt(np.maximum(np.diag(V_eff), 0.0))
    print(f"  {'param':<30s}  {'SE(stata)':>10s}  {'SE(py,eff)':>12s}  "
          f"{'SE(py,sw)':>12s}  {'ratio sw/stata':>15s}")
    for i, nm in enumerate(py_coef_names):
        r = se_py_sw[i] / se_stata[i] if se_stata[i] > 0 else float("nan")
        print(f"  {nm:<30s}  {se_stata[i]:>10.4f}  {se_py_eff[i]:>12.4f}  "
              f"{se_py_sw[i]:>12.4f}  {r:>15.4f}")


if __name__ == "__main__":
    main()
