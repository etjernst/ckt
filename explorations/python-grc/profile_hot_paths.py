"""Profile the per-call cost of grc_gmm's inner functions.

The fit loop calls ``_objective``, ``_gradient_of_g`` (via the jac), and
``_cluster_S`` (for W updates) many times. If any one of these is slow,
that dominates wall time.

Also micro-benchmarks candidate replacements for ``_cluster_S``'s
np.add.at (which is a known performance cliff).
"""

from __future__ import annotations

import time
from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb
from grc_gmm import RestrictedGRC, _drop_collinear


HERE = Path(__file__).parent


def _time(fn, reps=5):
    # warmup
    fn()
    t0 = time.time()
    for _ in range(reps):
        fn()
    return (time.time() - t0) / reps


def main():
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

    py = pd.read_csv(HERE / "python_out_idn_cons_urb_unb.csv")
    coefs = dict(zip(py["name"], py["coef_py"]))
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

    # Fake W for timing.
    W = np.eye(Z.shape[1])

    t_resid = _time(lambda: est._residuals(theta, data))
    t_moments = _time(lambda: est._moments_individual(theta, data))
    t_obj = _time(lambda: est._objective(theta, data, W))
    t_grad = _time(lambda: est._gradient_of_g(theta, data))
    t_S = _time(lambda: est._cluster_S(theta, data))

    print(f"Per-call timings (mean over 5 reps, n={data['n']}, m={Z.shape[1]}):")
    print(f"  _residuals             {t_resid * 1000:8.1f} ms")
    print(f"  _moments_individual    {t_moments * 1000:8.1f} ms")
    print(f"  _objective             {t_obj * 1000:8.1f} ms")
    print(f"  _gradient_of_g         {t_grad * 1000:8.1f} ms")
    print(f"  _cluster_S             {t_S * 1000:8.1f} ms")

    # Micro-benchmark _cluster_S replacement: sort-then-cumsum.
    ids = data["ids"]
    _, inv = np.unique(ids, return_inverse=True)
    G_clust = int(inv.max() + 1)
    g = est._moments_individual(theta, data)
    m = g.shape[1]

    def cluster_S_addat():
        cluster_sum = np.zeros((G_clust, m))
        np.add.at(cluster_sum, inv, g)
        return cluster_sum.T @ cluster_sum / data["n"]

    def cluster_S_bincount():
        # Per-column 1-D bincount is much faster than np.add.at on a 2-D array.
        cluster_sum = np.zeros((G_clust, m))
        for k in range(m):
            cluster_sum[:, k] = np.bincount(inv, weights=g[:, k], minlength=G_clust)
        return cluster_sum.T @ cluster_sum / data["n"]

    def cluster_S_sorted():
        # Sort by cluster id, then cumulative-sum within group boundaries.
        order = np.argsort(inv, kind="stable")
        inv_sorted = inv[order]
        g_sorted = g[order]
        # Boundary indices where a new group starts.
        starts = np.concatenate(([0], np.flatnonzero(np.diff(inv_sorted)) + 1,
                                  [len(inv_sorted)]))
        cluster_sum = np.add.reduceat(g_sorted, starts[:-1])
        return cluster_sum.T @ cluster_sum / data["n"]

    S_addat = _time(cluster_S_addat, reps=3)
    S_bin = _time(cluster_S_bincount, reps=3)
    S_sort = _time(cluster_S_sorted, reps=3)
    print()
    print(f"Cluster-S alternatives:")
    print(f"  np.add.at                    {S_addat * 1000:8.1f} ms  (current)")
    print(f"  per-col np.bincount          {S_bin * 1000:8.1f} ms")
    print(f"  argsort + np.add.reduceat    {S_sort * 1000:8.1f} ms")

    # Verify equivalence.
    ref = cluster_S_addat()
    assert np.allclose(ref, cluster_S_bincount())
    assert np.allclose(ref, cluster_S_sorted())
    print("  (all three produce identical output)")

    # Rough extrapolation: how many _objective calls does fit() make?
    # L-BFGS-B with 1000 maxiter + Nelder-Mead with 2000 maxiter per outer step,
    # 5-8 outer steps. Each _objective call triggers _moments_individual.
    # With _gradient_of_g called at each L-BFGS-B step (maybe 50-100 per outer),
    # total objective+grad invocations ~ 3000-5000 per outer step.
    print()
    print("Approximate per-outer-iter cost (conservative):")
    print(f"  2000 _objective calls        {t_obj * 2000:6.1f} s  (Nelder-Mead)")
    print(f"  1000 _objective + 100 grad   "
          f"{(t_obj * 1000 + t_grad * 100):6.1f} s  (L-BFGS-B)")
    print(f"  1 _cluster_S update          {t_S:6.1f} s")


if __name__ == "__main__":
    main()
