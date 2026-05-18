"""Counterfactual aggregates for E1 (misallocation) and E2 (hukou wedge).

Module-level functions implement the deterministic aggregate evaluator,
the joint $(\\phi, \\beta)$ inversion-CI grid construction, and the
propagation of the aggregate functional through the joint CI image.

The auxiliary-OLS fit (``lca_inversion.fit_auxiliary_ols``) feeds both
the existing marginal grid inversion and this joint two-dimensional
extension; ``build_joint_ci_grid`` reuses the same Wald-on-moments
construction as ``grid_md_inversion`` but fixes both $\\phi$ and
$\\beta$ rather than concentrating $\\beta$ out.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

import numpy as np
from scipy.stats import chi2

# Re-export the auxiliary-OLS infrastructure from lca_inversion so the
# joint CI consumer can ``from counterfactuals import fit_auxiliary_ols``.
from lca_inversion import (  # noqa: F401
    AuxiliaryFit,
    drop_sparse_switchers,
    fit_auxiliary_ols,
)


@dataclass
class AggregateResult:
    """Output of ``evaluate_aggregate``.

    All quantities are in log per-capita consumption units (so percent
    quantities are change in geometric-mean consumption: exp(x) - 1).
    """
    w_obs_minus_zero: float       # value of observed migration
    w_opt_minus_obs: float        # misallocation gap (Option 1 floor)
    contrib_obs_zero: np.ndarray  # per-trajectory: pi_d * Delta_d * Dbar_d
    contrib_opt_obs: np.ndarray   # per-trajectory: pi_d * [max(0, Delta_d) - Delta_d * Dbar_d]
    delta_d: np.ndarray           # the Delta_d used per trajectory (echo)
    pi_d: np.ndarray
    dbar_d: np.ndarray
    traj_labels: list[str]        # row labels for the decomposition


def evaluate_aggregate(
    delta_d: np.ndarray,
    pi_d: np.ndarray,
    dbar_d: np.ndarray,
    traj_labels: list[str] | None = None,
) -> AggregateResult:
    """E1 aggregate at trajectory-level Deltas.

    Computes the decomposition in equation (1) of the paper:

        W_obs - W_zero = sum_d pi_d * Delta_d * Dbar_d
        W_opt - W_obs  = sum_d pi_d * [max(0, Delta_d) - Delta_d * Dbar_d]

    Treats ``delta_d`` as fixed at whatever values the caller passes;
    no LCA constraint is imposed here. For the inversion-CI propagation
    version, the caller will feed in the LCA-implied Delta_d at each
    grid point.
    """
    delta_d = np.asarray(delta_d, dtype=float)
    pi_d = np.asarray(pi_d, dtype=float)
    dbar_d = np.asarray(dbar_d, dtype=float)
    if not (len(delta_d) == len(pi_d) == len(dbar_d)):
        raise ValueError(
            f"length mismatch: delta_d={len(delta_d)} pi_d={len(pi_d)} "
            f"dbar_d={len(dbar_d)}"
        )
    if traj_labels is None:
        traj_labels = [str(i) for i in range(len(delta_d))]

    # pi normalization sanity check
    pi_sum = float(np.nansum(pi_d))
    if not (0.99 <= pi_sum <= 1.01):
        raise ValueError(f"pi_d does not sum to ~1: sum = {pi_sum:.4f}")

    contrib_obs_zero = pi_d * delta_d * dbar_d
    contrib_opt_obs = pi_d * (np.maximum(0.0, delta_d) - delta_d * dbar_d)

    return AggregateResult(
        w_obs_minus_zero=float(np.nansum(contrib_obs_zero)),
        w_opt_minus_obs=float(np.nansum(contrib_opt_obs)),
        contrib_obs_zero=contrib_obs_zero,
        contrib_opt_obs=contrib_opt_obs,
        delta_d=delta_d,
        pi_d=pi_d,
        dbar_d=dbar_d,
        traj_labels=traj_labels,
    )


def log_to_pct(x: float) -> float:
    """exp(x) - 1, the geometric-mean percent change from a log-points value."""
    return float(np.expm1(x))


def build_joint_ci_grid(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    phi_grid: np.ndarray,
    beta_grid: np.ndarray,
    type_one: float = 0.05,
) -> dict:
    """Joint $(\\phi, \\beta)$ confidence region via constrained-J inversion.

    At each $(\\phi, \\beta)$ on the 2D lattice, evaluate the moment vector

        m_s = beta_s_OLS - beta - phi * (alpha_s_OLS - alpha_base_OLS)

    for every switcher $s$ in ``switchers_kept`` (including the base, where
    alpha_s - alpha_base = 0 trivially). The Jacobian of $m$ wrt the OLS
    theta is constant once $\\phi$ is fixed, so the Wald statistic
    $m' V_m^{-1} m$ has chi^2_K asymptotic distribution under H0, where
    K = len(switchers_kept). dof matches the GMM Wald-on-moments
    convention; we test the joint hypothesis $H_0: (\\phi_0, \\beta_0)
    = (\\phi, \\beta)$ at fixed lattice points.

    Differs from the existing ``grid_md_inversion`` only in that beta is
    NOT concentrated out: it ranges over ``beta_grid``. Differs from
    ``grid_lca_inversion`` in that the base moment (s == base) is
    included, restoring one degree of freedom that the just-identified
    base-pinning approach drops.

    Weak-ID-robust: the Wald-on-moments at fixed $(\\phi, \\beta)$ is an
    S-type / J-type statistic (Stock-Wright 2000; Andrews-Mikusheva
    2016), not a delta-method Wald on $(\\phi, \\beta)$, so coverage is
    valid under weak identification.

    Parameters
    ----------
    fit : AuxiliaryFit
        Result of ``lca_inversion.fit_auxiliary_ols``.
    switchers_kept : sequence of int
        Switcher trajectory codes that pass the sparseness filter.
    base : int
        The base switcher trajectory.
    phi_grid : 1D array
        Values of $\\phi$ to test.
    beta_grid : 1D array
        Values of $\\beta$ to test.
    type_one : float, default 0.05
        Test size $\\alpha$.

    Returns
    -------
    dict with keys
        ``phi_grid``, ``beta_grid``     -- the 1D grids
        ``wald`` : 2D array (n_phi, n_beta)
        ``p_value`` : 2D array (n_phi, n_beta)
        ``accept`` : 2D bool array (p_value >= type_one)
        ``islands`` : list of connected components of ``accept``,
            each a list of (i, j) lattice indices
        ``K`` : the chi^2 dof (= len(switchers_kept))
    """
    sw = list(switchers_kept)
    K = len(sw)
    if K == 0:
        raise ValueError("Need at least one switcher for the joint CI")
    if base not in sw:
        raise ValueError(
            f"base trajectory {base} not in switchers_kept {sw}"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])

    # u_s = beta_s_OLS, d_s = alpha_s_OLS - alpha_base_OLS
    u = fit.b[s_beta]
    d = fit.b[s_alpha] - fit.b[base_alpha]

    n_phi = len(phi_grid)
    n_beta = len(beta_grid)
    wald = np.empty((n_phi, n_beta))

    for i, phi in enumerate(phi_grid):
        # Build Jacobian J at this phi (constant in beta).
        J = np.zeros((K, p))
        for k in range(K):
            J[k, s_beta[k]] = 1.0
            if not is_base[k]:
                J[k, s_alpha[k]] = -phi
                J[k, base_alpha] = +phi
        V_m = J @ fit.V @ J.T
        V_m_inv = np.linalg.pinv(V_m, rcond=1e-10)

        for j, beta in enumerate(beta_grid):
            m = u - beta - phi * d
            wald[i, j] = float(m @ V_m_inv @ m)

    p_value = 1.0 - chi2.cdf(wald, df=K)
    accept = p_value >= type_one
    islands = _flood_fill_2d(accept)

    return {
        "phi_grid": np.asarray(phi_grid),
        "beta_grid": np.asarray(beta_grid),
        "wald": wald,
        "p_value": p_value,
        "accept": accept,
        "islands": islands,
        "K": K,
    }


def _flood_fill_2d(mask: np.ndarray) -> list[list[tuple[int, int]]]:
    """4-connected flood-fill on a 2D bool mask.

    Returns a list of connected components; each component is a list of
    (i, j) lattice indices. Used by ``build_joint_ci_grid`` to detect
    disjoint pieces of the acceptance region (e.g., near the Mobius pole
    where the constraint surface can split).
    """
    visited = np.zeros_like(mask, dtype=bool)
    components: list[list[tuple[int, int]]] = []
    n_i, n_j = mask.shape

    for i0 in range(n_i):
        for j0 in range(n_j):
            if not mask[i0, j0] or visited[i0, j0]:
                continue
            comp: list[tuple[int, int]] = []
            stack = [(i0, j0)]
            while stack:
                i, j = stack.pop()
                if not (0 <= i < n_i and 0 <= j < n_j):
                    continue
                if visited[i, j] or not mask[i, j]:
                    continue
                visited[i, j] = True
                comp.append((i, j))
                stack.extend([(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)])
            components.append(comp)

    return components


def project_image_intervals(
    accepted_values: np.ndarray,
    n_bins: int = 401,
) -> dict:
    """Detect disjoint intervals in a 1D image $g(\\mathcal{C})$.

    Given the set of aggregate values at accepted joint-CI grid points,
    bin onto a fine 1D lattice and run ``_flood_fill_1d`` to identify
    connected intervals. This mirrors ``find_islands`` from
    ``lca_inversion`` and is what P3 of the inference protocol calls
    for when the image of the joint CI is non-convex (e.g., when the
    accepted region brushes the Mobius pole).

    Parameters
    ----------
    accepted_values : 1D array
        Aggregate values $g(\\phi, \\beta)$ at all accepted lattice
        points. NaN and +/- inf are dropped (these arise near the pole
        when the aggregate is unbounded; the caller should handle the
        infinite tail separately, per the plan's edge-case handling).
    n_bins : int, default 401
        Resolution of the 1D image grid.

    Returns
    -------
    dict with keys
        ``intervals`` : list of (lo, hi) tuples, one per connected piece
        ``n_islands`` : int
        ``convex_hull`` : (lo, hi) of the full image, the conservative
            fallback when the user prefers a single interval
        ``n_finite``, ``n_nonfinite`` : counts for diagnostic reporting
    """
    arr = np.asarray(accepted_values, dtype=float)
    finite = np.isfinite(arr)
    n_finite = int(finite.sum())
    n_nonfinite = int((~finite).sum())
    arr_f = arr[finite]
    if n_finite == 0:
        return {
            "intervals": [],
            "n_islands": 0,
            "convex_hull": (float("nan"), float("nan")),
            "n_finite": 0,
            "n_nonfinite": n_nonfinite,
        }

    lo, hi = float(arr_f.min()), float(arr_f.max())
    bins = np.linspace(lo, hi, n_bins + 1)
    counts, _ = np.histogram(arr_f, bins=bins)
    occupied = counts > 0

    # 1D flood-fill
    intervals: list[tuple[float, float]] = []
    j = 0
    while j < len(occupied):
        if not occupied[j]:
            j += 1
            continue
        start = j
        while j < len(occupied) and occupied[j]:
            j += 1
        end = j - 1
        intervals.append((float(bins[start]), float(bins[end + 1])))

    return {
        "intervals": intervals,
        "n_islands": len(intervals),
        "convex_hull": (lo, hi),
        "n_finite": n_finite,
        "n_nonfinite": n_nonfinite,
    }


def lca_delta_dN(phi: float, beta: float, mu_dN: float, mu_base: float) -> float:
    """LCA extrapolation: $\\Delta_{d_N} = \\beta + \\phi(\\mu_{d_N} - \\mu_{\\text{base}})$."""
    return float(beta + phi * (mu_dN - mu_base))


def lca_delta_dT(
    phi: float, beta: float, alpha_dT_obs: float, mu_base: float
) -> float:
    """LCA inversion via the Mobius transformation:

        $\\Delta_{d_T} = (\\beta + \\phi(\\alpha_{d_T}^{\\text{obs}} - \\mu_{\\text{base}})) / (1 + \\phi)$

    Unbounded at $\\phi = -1$. Returns +/- inf when $\\phi$ is within
    1e-10 of $-1$; the caller must handle these via the image-projection
    interval logic.
    """
    denom = 1.0 + phi
    if abs(denom) < 1e-10:
        num = beta + phi * (alpha_dT_obs - mu_base)
        return float("inf") if num > 0 else float("-inf")
    return float((beta + phi * (alpha_dT_obs - mu_base)) / denom)
