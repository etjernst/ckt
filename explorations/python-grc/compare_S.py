"""Element-by-element diagnosis: at Stata's saved theta_1 (the same point
where Stata builds W_2 in twostep GMM), does Python's _cluster_S(theta)
match the S implied by Stata's saved e(W)?

Stata's e(W) in stata_W.csv comes from the twostep estimator, which sets
W_2 = S^{-1}(theta_1). So inv(W_stata) is Stata's S(theta_1_stata).

If the two S matrices differ block-wise, the row/column labels point to
which moment / instrument has a formula difference between the two
implementations.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

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

    # Load Stata's theta_1 and compute Python's S there.
    b1 = pd.read_csv(HERE / "stata_theta1.csv")
    coefs_st1 = dict(zip(b1["name"], b1["value"]))
    theta1 = _reconstruct(data, coefs_st1)
    S_py = est._cluster_S(theta1, data)

    # Load Stata's e(W) and invert to recover Stata's S(theta_1).
    Wdf = pd.read_csv(HERE / "stata_W.csv")
    p_full = int(Wdf[["row", "col"]].max().max())
    W_full = np.zeros((p_full, p_full))
    for _, row in Wdf.iterrows():
        W_full[int(row["row"]) - 1, int(row["col"]) - 1] = float(row["value"])
    keep_mask = np.ones(p_full, dtype=bool)
    keep_mask[64] = False  # drop o.switcher_31_choice
    W_st = W_full[np.ix_(keep_mask, keep_mask)]

    # Stata-style W invert. Use straight inv first; if singular, fall back to pinv.
    try:
        S_st = np.linalg.inv(W_st)
    except np.linalg.LinAlgError:
        S_st = np.linalg.pinv(W_st, rcond=1e-10)

    # Quick sanity: W_st @ S_st should be I to ~1e-8.
    err_id = np.linalg.norm(W_st @ S_st - np.eye(m))
    print(f"||W_st @ inv(W_st) - I|| = {err_id:.3e}")

    # Frobenius
    rel_frob = np.linalg.norm(S_py - S_st) / np.linalg.norm(S_st)
    print(f"||S_py - S_st|| / ||S_st|| (Frobenius) = {rel_frob:.4e}")

    # Element-by-element ratio
    abs_diff = np.abs(S_py - S_st)
    rel_diff = abs_diff / (np.abs(S_st) + 1e-12)

    # Top 20 entries by absolute diff, with row/col labels
    inst_names = list(np.array([
        "unbalanced", "unbalanced_choice",
        "never",
    ] + [f"switcher_{s}" for s in data["switchers"]] + [
        "choice", "always_choice",
    ] + [f"switcher_{s}_choice" for s in data["switchers"]])[kept])

    flat_idx = np.argsort(abs_diff.ravel())[::-1][:25]
    rows, cols = np.unravel_index(flat_idx, abs_diff.shape)
    print("\nTop 25 element diffs (S_py - S_st):")
    print(f"{'i':>3} {'j':>3} {'inst_i':<22} {'inst_j':<22} "
          f"{'S_py':>14} {'S_st':>14} {'|diff|':>11} {'rel':>8}")
    for r, c in zip(rows, cols):
        ri = inst_names[r] if r < len(inst_names) else f"<{r}>"
        ci = inst_names[c] if c < len(inst_names) else f"<{c}>"
        print(f"{r:>3} {c:>3} {ri:<22} {ci:<22} "
              f"{S_py[r,c]:>14.6e} {S_st[r,c]:>14.6e} "
              f"{abs_diff[r,c]:>11.3e} {rel_diff[r,c]:>8.3f}")

    # Diagonal block-wise: ratio diag(S_py)/diag(S_st)
    print("\nDiagonal ratios (S_py / S_st), per moment:")
    for i, name in enumerate(inst_names):
        ratio = S_py[i, i] / S_st[i, i] if S_st[i, i] != 0 else np.nan
        print(f"  {i:>3}  {name:<22}  {S_py[i,i]:>13.4e}  "
              f"{S_st[i,i]:>13.4e}  ratio={ratio:>8.5f}")

    # Try common candidate scaling explanations: dof corrections.
    G_clust = data["ids"]
    n_clusters = len(np.unique(G_clust))
    p_params = 1 + len(data["switchers"]) + 3 + data["X_cov"].shape[1]
    c_dof = ((n - 1) / (n - p_params)) * (n_clusters / (n_clusters - 1))
    print(f"\nCandidate scaling factors:")
    print(f"  n = {n}, n_clusters = {n_clusters}, p = {p_params}")
    print(f"  (n-1)/(n-p) * G/(G-1) = {c_dof:.6f}")
    print(f"  n / G                  = {n / n_clusters:.6f}")
    print(f"  G / n                  = {n_clusters / n:.6f}")
    # Test: does S_st = c_dof * S_py?
    for label, c in [("dof=c_dof", c_dof),
                     ("n/G", n / n_clusters),
                     ("(n-1)/n", (n-1)/n),
                     ("G/(G-1)", n_clusters / (n_clusters - 1))]:
        S_py_scaled = S_py * c
        rel = np.linalg.norm(S_py_scaled - S_st) / np.linalg.norm(S_st)
        print(f"  ||c*S_py - S_st||/||S_st|| with c={label:>10s} ({c:.6f}): {rel:.4e}")


if __name__ == "__main__":
    main()
