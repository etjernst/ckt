"""Weak-ID-robust CI for the LCA slope (phi) via grid test inversion.

Three components:

* ``drop_sparse_switchers``: pre-filter switcher trajectories with too few
  treated clusters. Mirrors the rank-deficient-moment pre-drop planned
  for the GMM estimator's pseudo-inverse step.
* ``fit_auxiliary_ols``: saturated OLS in trajectory dummies and (kept
  switcher) x choice interactions with cluster-robust SE. Returns
  coefficients, VCV, and a name -> index map for the inversion.
* ``grid_lca_inversion``: at each phi on the grid, build the joint
  Wald statistic for the LCA restriction
      (beta_s - beta_base) - phi * (alpha_s - alpha_base) = 0
  for every kept non-base switcher s. The restriction is linear in
  the OLS coefficients for fixed phi, so the Jacobian is a constant
  selector matrix and the Wald is a one-line numpy expression.

Plan reference: ``docs/plans/2026-04-23-lca-inversion-ci-ckt.md``.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy.stats import chi2


@dataclass
class AuxiliaryFit:
    """Result of the auxiliary OLS regression."""
    b: np.ndarray
    V: np.ndarray
    names: list[str]
    name_to_idx: dict[str, int]
    n_obs: int
    n_clusters: int

    def idx(self, name: str) -> int:
        return self.name_to_idx[name]


def drop_sparse_switchers(
    df: pd.DataFrame,
    trajectory: str,
    choice: str,
    hhid: str,
    threshold: int = 5,
) -> tuple[list[int], dict[int, int]]:
    """Identify switcher trajectories with at least ``threshold`` unique
    individuals contributing a treated observation (trajectory == s and
    choice == 1).

    Returns ``(kept, counts)`` where ``kept`` is the sorted list of switcher
    codes retained and ``counts`` maps every candidate switcher to its
    treated-pid count (including those dropped). The smallest and largest
    trajectory codes are treated as ``never`` and ``always`` and excluded
    from candidacy.
    """
    trajectories = sorted(int(t) for t in df[trajectory].dropna().unique())
    if len(trajectories) < 3:
        raise ValueError(
            f"Need at least 3 trajectories (never, switcher(s), always); "
            f"got {trajectories}"
        )
    never, always = trajectories[0], trajectories[-1]
    candidates = [t for t in trajectories if t not in (never, always)]

    kept: list[int] = []
    counts: dict[int, int] = {}
    for s in candidates:
        mask = (df[trajectory] == s) & (df[choice] == 1)
        n_pids = int(df.loc[mask, hhid].nunique())
        counts[s] = n_pids
        if n_pids >= threshold:
            kept.append(s)
    return kept, counts


def fit_auxiliary_ols(
    df: pd.DataFrame,
    outcome: str,
    trajectory: str,
    choice: str,
    hhid: str,
    switchers_kept: Sequence[int],
    controls: Sequence[str] | None = None,
    unbalanced_col: str = "unbalanced",
    unbalanced_choice_col: str = "unbalanced_choice",
) -> AuxiliaryFit:
    """Fit the saturated trajectory + (switcher x choice) OLS used as the
    inversion's just-identified vehicle. Cluster-robust SE at ``hhid``.

    Each observed trajectory (excluding NaN unbalanced observers) gets its
    own ``alpha[d]`` dummy. Each switcher in ``switchers_kept`` gets a
    ``beta[s]`` interaction with ``choice``. Unbalanced observers enter
    via ``unbalanced`` and ``unbalanced_choice`` indicators (matching CKT's
    GMM specification). Additional ``controls`` are included as level shifters.
    """
    trajectories = sorted(int(t) for t in df[trajectory].dropna().unique())

    cols: dict[str, np.ndarray] = {}
    for d in trajectories:
        cols[f"alpha[{d}]"] = (df[trajectory] == d).astype(float).values
    for s in switchers_kept:
        cols[f"beta[{s}]"] = (
            ((df[trajectory] == s) & (df[choice] == 1)).astype(float).values
        )
    cols[unbalanced_col] = df[unbalanced_col].astype(float).values
    cols[unbalanced_choice_col] = df[unbalanced_choice_col].astype(float).values
    if controls:
        for c in controls:
            cols[c] = df[c].astype(float).values

    X = pd.DataFrame(cols)
    y = df[outcome].astype(float).values
    groups = df[hhid].values

    model = sm.OLS(y, X.values)
    results = model.fit(
        cov_type="cluster",
        cov_kwds={"groups": groups, "use_correction": True},
    )

    return AuxiliaryFit(
        b=np.asarray(results.params),
        V=np.asarray(results.cov_params()),
        names=list(X.columns),
        name_to_idx={name: i for i, name in enumerate(X.columns)},
        n_obs=len(y),
        n_clusters=int(pd.Series(groups).nunique()),
    )


def grid_lca_inversion(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    phi_grid: np.ndarray,
    type_one: float = 0.05,
) -> tuple[pd.DataFrame, float, float]:
    """Sweep ``phi_grid`` and return ``(curve_df, ci_low, ci_high)``.

    At each phi, the joint Wald statistic for the linear restriction
        r_s(b, phi) = (beta_s - beta_base) - phi * (alpha_s - alpha_base)
    is evaluated across every kept switcher s != base. Under the null,
    Wald ~ chi^2_(J_R) with ``J_R = len(switchers_kept) - 1``.

    The CI is the convex hull of grid points where p_value >= ``type_one``.
    Multimodal (island) detection is deferred (see ``docs/TODO.md``).
    """
    if base not in switchers_kept:
        raise ValueError(
            f"base trajectory {base} not in switchers_kept {list(switchers_kept)}"
        )
    other = [s for s in switchers_kept if s != base]
    J_R = len(other)
    if J_R == 0:
        raise ValueError(
            "Need at least one non-base switcher for the LCA inversion"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    base_beta = fit.idx(f"beta[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in other])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in other])

    rows = []
    for phi in phi_grid:
        G = np.zeros((J_R, p))
        for k in range(J_R):
            G[k, s_beta[k]] = 1.0
            G[k, base_beta] = -1.0
            G[k, s_alpha[k]] = -phi
            G[k, base_alpha] = phi
        r = G @ fit.b
        V_R = G @ fit.V @ G.T
        # pinv guards against near-singular V_R when sparse switchers slip
        # past the pre-drop. rcond mirrors statsmodels' default tolerance.
        V_R_inv = np.linalg.pinv(V_R, rcond=1e-10)
        wald = float(r @ V_R_inv @ r)
        p_value = float(1.0 - chi2.cdf(wald, df=J_R))
        rows.append((float(phi), wald, p_value))

    curve = pd.DataFrame(rows, columns=["phi", "wald", "p_value"])
    accepted = curve.loc[curve["p_value"] >= type_one, "phi"]
    if len(accepted) == 0:
        return curve, float("nan"), float("nan")
    return curve, float(accepted.min()), float(accepted.max())
