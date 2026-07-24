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
from pathlib import Path
from typing import Sequence

import numpy as np
import pandas as pd
from scipy.stats import chi2

# Re-export the auxiliary-OLS infrastructure from lca_inversion so the
# joint CI consumer can ``from counterfactuals import fit_auxiliary_ols``.
from lca_inversion import (  # noqa: F401
    SWITCHER_KEEP_MIN,
    AuxiliaryFit,
    drop_sparse_switchers,
    fit_auxiliary_ols,
)


@dataclass
class AggregateResult:
    """Output of ``evaluate_aggregate``.

    All quantities are in log per-capita consumption units (so percent
    quantities are change in geometric-mean consumption: exp(x) - 1).
    The zero-migration baseline holds each worker at their first-observed-wave
    location, so the value term multiplies Delta_d by (Dbar_d - Dbar0_d);
    always-urban workers drop out of the value term by construction.
    The gap term is baseline-free.
    """
    w_obs_minus_zero: float       # value of observed migration
    w_opt_minus_obs: float        # misallocation gap (trajectory-mean floor)
    contrib_obs_zero: np.ndarray  # per-trajectory: pi_d * Delta_d * (Dbar_d - Dbar0_d)
    contrib_opt_obs: np.ndarray   # per-trajectory: pi_d * [max(0, Delta_d) - Delta_d * Dbar_d]
    delta_d: np.ndarray           # the Delta_d used per trajectory (echo)
    pi_d: np.ndarray
    dbar_d: np.ndarray
    dbar0_d: np.ndarray
    traj_labels: list[str]        # row labels for the decomposition


def evaluate_aggregate(
    delta_d: np.ndarray,
    pi_d: np.ndarray,
    dbar_d: np.ndarray,
    dbar0_d: np.ndarray,
    traj_labels: list[str] | None = None,
) -> AggregateResult:
    """E1 aggregate at trajectory-level Deltas.

    Computes the decomposition in equation (1) of the paper:

        W_obs - W_zero = sum_d pi_d * Delta_d * (Dbar_d - Dbar0_d)
        W_opt - W_obs  = sum_d pi_d * [max(0, Delta_d) - Delta_d * Dbar_d]

    where Dbar0_d is the trajectory's first-observed-wave urban share (the
    stay-at-first-observation baseline). Treats ``delta_d`` as fixed at
    whatever values the caller passes; no LCA constraint is imposed here.
    """
    delta_d = np.asarray(delta_d, dtype=float)
    pi_d = np.asarray(pi_d, dtype=float)
    dbar_d = np.asarray(dbar_d, dtype=float)
    dbar0_d = np.asarray(dbar0_d, dtype=float)
    if not (len(delta_d) == len(pi_d) == len(dbar_d) == len(dbar0_d)):
        raise ValueError(
            f"length mismatch: delta_d={len(delta_d)} pi_d={len(pi_d)} "
            f"dbar_d={len(dbar_d)} dbar0_d={len(dbar0_d)}"
        )
    if traj_labels is None:
        traj_labels = [str(i) for i in range(len(delta_d))]

    # pi normalization sanity check
    pi_sum = float(np.nansum(pi_d))
    if not (0.99 <= pi_sum <= 1.01):
        raise ValueError(f"pi_d does not sum to ~1: sum = {pi_sum:.4f}")

    contrib_obs_zero = pi_d * delta_d * (dbar_d - dbar0_d)
    contrib_opt_obs = pi_d * (np.maximum(0.0, delta_d) - delta_d * dbar_d)

    return AggregateResult(
        w_obs_minus_zero=float(np.nansum(contrib_obs_zero)),
        w_opt_minus_obs=float(np.nansum(contrib_opt_obs)),
        contrib_obs_zero=contrib_obs_zero,
        contrib_opt_obs=contrib_opt_obs,
        delta_d=delta_d,
        pi_d=pi_d,
        dbar_d=dbar_d,
        dbar0_d=dbar0_d,
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


# ===========================================================================
# Orchestration: the single reproducible E1 path.
#
# Graduates the two dated drivers (2026-05-20_e1_v3_joint_ci.py and
# 2026-05-20_e1_chn_national.py) into one code path. Mirrors
# lca_inversion.attach_inversion_for_stata: 12_counterfactuals.do calls
# run_counterfactuals_for_stata over the SFI python: bridge, and every E1
# misallocation aggregate is computed here.
# ===========================================================================

THRESHOLD = SWITCHER_KEEP_MIN
TYPE_ONE = 0.05
# Cells exempt from the hard 0.01 OLS-vs-ster Delta_dN agreement bound (weak
# identification near phi = -1 separates the two estimators; see run_cell).
WEAK_ID_EXEMPT = {"CHN_uf"}

# Per-cell configuration. The CHN hukou cells use wider phi AND beta grids:
# the UF region sits below the phi = -1 boundary and, being weakly
# identified, extends far along a (phi, beta) ray, so both grids must reach
# far enough to bracket it (run_cell hard-errors if the accepted region
# touches any lattice edge).
CELLS = {
    "IDN":    {"file_stem": "IDN",                   "phi": (-2.0, 1.0, 301)},
    "TZA":    {"file_stem": "TZA",                   "phi": (-2.0, 1.0, 301)},
    "CHN_rf": {"file_stem": "CHN_hukou_rural_first", "phi": (-6.0, 1.0, 701),
               "beta": (-2.0, 2.0, 401)},
    "CHN_uf": {"file_stem": "CHN_hukou_urban_first", "phi": (-6.0, 1.0, 701),
               "beta": (-2.0, 2.0, 401)},
}
BETA_GRID_SPEC = (-0.5, 0.5, 101)


@dataclass
class CellResult:
    """Per-cell E1 outputs, in log per-capita consumption units.

    Convex hulls are (lo, hi) tuples; percent quantities are exp(x) - 1
    (change in geometric-mean consumption). P3 is the no-d_T variant that
    zeroes the always-urban gap contribution (a lower bound; the region can
    cross the phi = -1 pole); full keeps it. Coverage variant v1 projects the
    joint 3D (phi, beta, Delta_unb) region (nominal >= 95%); v2 folds the
    Delta_unb 95% CI into the 2D (phi, beta) region by interval arithmetic.
    The hull fields are DIAGNOSTICS ONLY (persisted in the diagnostics CSV,
    never reported): the joint region's measured coverage is 0.820, and E1
    interval reporting waits on the WCR11 joint-region extension. The
    reported quantities are the point_* fields.
    """
    short: str
    n_obs: int
    n_pids: int
    K: int
    base: int
    n_accept_2d: int
    n_accept_3d: int
    crosses_boundary: bool
    phi_open_below: bool                # weak-ID: region accepts phi -> -inf
    phi_open_above: bool                # weak-ID: region accepts phi -> +inf
    marginal_phi: tuple[float, float] | None
    marginal_beta: tuple[float, float] | None
    marginal_unb: tuple[float, float] | None
    hull_wmm_p3_v1: tuple[float, float]
    hull_wms_p3_v1: tuple[float, float]
    hull_wmm_full_v1: tuple[float, float]
    hull_wms_full_v1: tuple[float, float]
    hull_wmm_p3_v2: tuple[float, float]
    hull_wms_p3_v2: tuple[float, float]
    hull_wmm_full_v2: tuple[float, float]
    hull_wms_full_v2: tuple[float, float]
    point_gap_varA: float               # gap at the GMM point, d_T from the _a ster
    point_gap_varB: float               # gap at the GMM point, d_T zeroed
    point_value_d0: float               # value vs first-observed location (variant-invariant)
    point_value_allrural_varA: float    # value vs everyone rural, d_T from the _a ster
    point_value_allrural_varB: float    # value vs everyone rural, d_T zeroed
    unb_ols: float                      # lumped-cell return, auxiliary OLS
    unb_se_ols: float
    unb_gmm: float                      # ster xb:unbalanced_choice (diagnostic)
    xcheck_gap_unrestricted: float      # point gap under unrestricted switcher returns
    xcheck_gap_diff: float              # unrestricted minus LCA-line point gap
    decomposition: pd.DataFrame         # per-trajectory contributions at the point


@dataclass
class HukouBoundResult:
    """E2 hukou-wedge lower bound, in log per-capita consumption units.

    The economy-wide consumption gain (lower bound) from relocating the
    rural-hukou never-migrants is ``const * delta_dN_rh_point`` with
    ``const = pi_rh * pi_dN_rh`` (both fixed population shares). Reported next
    to the per-never-migrant return ``delta_dN_rh_point`` itself, so the
    within-group magnitude sits beside the population-averaged floor.
    ``hull_bound`` and ``delta_dN_rh_ci`` are (lo, hi) tuples; percent
    quantities downstream are exp(x) - 1 (geometric-mean change).
    ``ci_source`` names the ster behind the CI (GMM delta-method interval
    from the CHN_rf ``_n`` ster; recorded in the results CSV).
    """
    pi_rh: float
    pi_dN_rh: float
    const: float
    delta_dN_rh_point: float
    delta_dN_rh_ci: tuple[float, float]   # 95% GMM CI on Delta_dN_rh
    ci_source: str
    point_bound: float                    # const * delta_dN_rh_point
    hull_bound: tuple[float, float]       # const * delta_dN_rh_ci
    floor_positive: bool                  # delta_dN_rh_ci lower endpoint > 0


def prepare_data(file_stem: str, data_dir) -> tuple[pd.DataFrame, list[str]]:
    """Load and prep a cell's sample, mirroring 5b_inversion.do.

    Critical: do NOT drop trajectory-NaN rows. Unbalanced workers carry a
    missing trajectory; 5b routes them through the `unbalanced` /
    `unbalanced_choice` dummies in the auxiliary OLS rather than dropping
    them. Dropping them here would shrink the sample by ~60-89% and inflate
    the joint CI (the 2026-05-20 sample-fix bug).
    """
    df = pd.read_stata(Path(data_dir) / f"{file_stem}_unb.dta",
                       convert_categoricals=False)
    # Filter mirrors _export_e1_inputs*.do exactly: POSITIVITY on consumption
    # and hhsize_cube (np.log(0) is -inf and would survive a NaN filter),
    # plus non-missing choice, period, controls, and unbalanced dummies.
    # The exporter asserts this reproduces the GMM e(N); run_cell asserts the
    # row/pid counts against the exporter's scalars.
    df = df[(df["consumption"] > 0) & (df["hhsize_cube"] > 0)].copy()
    df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])
    df = df.dropna(subset=["lndepvar", "choice", "period"]).copy()
    needed = ["female", "age2", "education_max", "education_max2",
              "unbalanced", "unbalanced_choice"]
    df = df.dropna(subset=[c for c in needed if c in df.columns])
    periods = sorted(df["period"].dropna().unique().astype(int).tolist())
    period_cols = []
    for t in periods[1:]:
        col = f"period_{t}"
        df[col] = (df["period"] == t).astype(float)
        period_cols.append(col)
    controls = period_cols + ["female", "age2", "education_max", "education_max2"]
    for col in ["unbalanced", "unbalanced_choice"]:
        if col not in df.columns:
            df[col] = 0.0
    return df, controls


# Interface schema for the exporter CSVs. load_cell_inputs errors on any
# missing column or scalar key so a silent rename upstream cannot ship.
_TRAJ_COLS = {"traj_for_agg", "n_pids", "dbar_d", "dbar0_d", "pi_d"}
_MU_COLS = {"traj_for_agg", "mu_d_ster", "mu_d_raw_hh"}
_DELTA_COLS = {"trajectory", "delta_d_lcafit_point"}
_SCALAR_KEYS = {"phi_hat", "beta_hat", "unb_choice_hat", "base",
                "delta_never_point", "delta_always_point",
                "n_rows_filtered", "n_pids_filtered"}


def load_cell_inputs(short: str, inputs_dir) -> dict:
    """Read the four ster-derived input CSVs for one cell and merge them.

    The CSVs (`{short}_e1_{traj,mu_d,delta_d,scalars}.csv`) are written by
    _export_e1_inputs.do / _export_e1_inputs_hukou.do from the GRC sters.
    Every required column and scalar key is asserted present.
    """
    inputs_dir = Path(inputs_dir)
    traj = pd.read_csv(inputs_dir / f"{short}_e1_traj.csv")
    mu_d = pd.read_csv(inputs_dir / f"{short}_e1_mu_d.csv")
    delta_d = pd.read_csv(inputs_dir / f"{short}_e1_delta_d.csv")
    scalars_df = pd.read_csv(inputs_dir / f"{short}_e1_scalars.csv")
    scalars: dict = {}
    for _, row in scalars_df.iterrows():
        try:
            scalars[row["name"]] = float(row["value"])
        except (TypeError, ValueError):
            scalars[row["name"]] = row["value"]

    for label, have, want in [
        ("traj", set(traj.columns), _TRAJ_COLS),
        ("mu_d", set(mu_d.columns), _MU_COLS),
        ("delta_d", set(delta_d.columns), _DELTA_COLS),
        ("scalars", set(scalars.keys()), _SCALAR_KEYS),
    ]:
        missing = want - have
        if missing:
            raise ValueError(
                f"{short}: {label} CSV is missing {sorted(missing)}; "
                f"re-run the E1 exporters before the counterfactuals."
            )

    df = traj.merge(mu_d, on="traj_for_agg", how="left").merge(
        delta_d.rename(columns={"trajectory": "traj_for_agg"}),
        on="traj_for_agg", how="left",
    )
    return {"trajectory": df, "scalars": scalars}


def build_joint_ci_grid_3d(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    phi_grid: np.ndarray,
    beta_grid: np.ndarray,
    unb_grid: np.ndarray,
    type_one: float = 0.05,
    unb_col: str = "unbalanced_choice",
) -> dict:
    """Joint $(\\phi, \\beta, \\Delta_{unb})$ region via constrained-J inversion.

    Extends ``build_joint_ci_grid`` with one extra moment
    ``unbalanced_choice_OLS - delta_unb`` so the lumped-cell return is tested
    inside the same S-statistic (dof K+1) rather than bolted on afterwards.
    The moment vector is linear in $(\\beta, \\delta_{unb})$ at fixed $\\phi$,
    so the Wald surface is evaluated by quadratic-form expansion --- O(1) per
    lattice point after one weight-matrix inversion per $\\phi$.
    """
    sw = list(switchers_kept)
    K = len(sw)
    if base not in sw:
        raise ValueError(f"base trajectory {base} not in switchers_kept {sw}")

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])
    unb_idx = fit.idx(unb_col)

    u = fit.b[s_beta]
    d = fit.b[s_alpha] - fit.b[base_alpha]
    unb_hat = float(fit.b[unb_idx])
    unb_se = float(np.sqrt(fit.V[unb_idx, unb_idx]))

    n_phi, n_beta, n_unb = len(phi_grid), len(beta_grid), len(unb_grid)
    wald = np.empty((n_phi, n_beta, n_unb))
    avec = np.zeros(K + 1)
    avec[:K] = 1.0            # -d m / d beta
    bvec = np.zeros(K + 1)
    bvec[K] = 1.0             # -d m / d delta_unb

    for i, phi in enumerate(phi_grid):
        J = np.zeros((K + 1, p))
        for k in range(K):
            J[k, s_beta[k]] = 1.0
            if not is_base[k]:
                J[k, s_alpha[k]] = -phi
                J[k, base_alpha] = +phi
        J[K, unb_idx] = 1.0
        V_m = J @ fit.V @ J.T
        W = np.linalg.pinv(V_m, rcond=1e-10)

        c = np.concatenate([u - phi * d, [unb_hat]])
        Wc = W @ c
        Wa = W @ avec
        Wb = W @ bvec
        cWc = float(c @ Wc)
        aWc = float(avec @ Wc)
        bWc = float(bvec @ Wc)
        aWa = float(avec @ Wa)
        bWb = float(bvec @ Wb)
        aWb = float(avec @ Wb)
        B = beta_grid[:, None]
        U = unb_grid[None, :]
        wald[i] = (cWc - 2.0 * B * aWc - 2.0 * U * bWc
                   + B ** 2 * aWa + U ** 2 * bWb + 2.0 * B * U * aWb)

    p_value = 1.0 - chi2.cdf(wald, df=K + 1)
    accept = p_value >= type_one
    return {
        "phi_grid": np.asarray(phi_grid),
        "beta_grid": np.asarray(beta_grid),
        "unb_grid": np.asarray(unb_grid),
        "wald": wald,
        "accept": accept,
        "K": K + 1,
        "unb_hat": unb_hat,
        "unb_se": unb_se,
    }


def _assert_region_interior(accept: np.ndarray, axis_names: list[str],
                            short: str,
                            open_edges: set[tuple[str, str]] | None = None) -> None:
    """Error if the accepted region touches any lattice edge.

    A truncated region silently narrows the projected interval, so this is a
    hard stop; widen the offending grid and rerun. ``open_edges`` is a set of
    (axis_name, "lo"/"hi") pairs declared genuinely unbounded (verified by
    ``_phi_open_below``); those edges are exempt.
    """
    open_edges = open_edges or set()
    for ax, name in enumerate(axis_names):
        first = np.take(accept, 0, axis=ax)
        last = np.take(accept, -1, axis=ax)
        if bool(first.any()) and (name, "lo") not in open_edges:
            raise ValueError(
                f"{short}: accepted region touches the lower {name}-grid edge; "
                f"widen the {name} grid and rerun."
            )
        if bool(last.any()) and (name, "hi") not in open_edges:
            raise ValueError(
                f"{short}: accepted region touches the upper {name}-grid edge; "
                f"widen the {name} grid and rerun."
            )


def _min_wald_at_phi(fit: AuxiliaryFit, switchers_kept: Sequence[int],
                     base: int, phi: float) -> float:
    """Min-over-beta 2D S-statistic at one phi (beta concentrated in closed form)."""
    sw = list(switchers_kept)
    K = len(sw)
    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])
    J = np.zeros((K, p))
    for k in range(K):
        J[k, s_beta[k]] = 1.0
        if not is_base[k]:
            J[k, s_alpha[k]] = -phi
            J[k, base_alpha] = +phi
    W = np.linalg.pinv(J @ fit.V @ J.T, rcond=1e-10)
    c = fit.b[s_beta] - phi * (fit.b[s_alpha] - fit.b[base_alpha])
    ones = np.ones(K)
    beta_star = float(ones @ W @ c) / float(ones @ W @ ones)
    m = c - beta_star
    return float(m @ W @ m)


def _beta_star_at_phi(fit: AuxiliaryFit, switchers_kept: Sequence[int],
                      base: int, phi: float) -> float:
    """The concentrated (min-Wald) beta at one phi."""
    sw = list(switchers_kept)
    K = len(sw)
    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])
    J = np.zeros((K, p))
    for k in range(K):
        J[k, s_beta[k]] = 1.0
        if not is_base[k]:
            J[k, s_alpha[k]] = -phi
            J[k, base_alpha] = +phi
    W = np.linalg.pinv(J @ fit.V @ J.T, rcond=1e-10)
    c = fit.b[s_beta] - phi * (fit.b[s_alpha] - fit.b[base_alpha])
    ones = np.ones(K)
    return float(ones @ W @ c) / float(ones @ W @ ones)


def _phi_open_sides(fit: AuxiliaryFit, switchers_kept: Sequence[int],
                    base: int, type_one: float = 0.05,
                    dof_offset: int = 0) -> tuple[bool, bool]:
    """(open_below, open_above): does the S-statistic accept phi -> -/+inf?

    As |phi| -> inf both the moment and its variance scale with phi, so the
    standardized statistic converges (to the same limit on both sides up to
    grid effects); if the limit sits below the chi^2 critical value the
    confidence region is unbounded on that side (a Dufour-type unbounded
    weak-identification confidence set). ``dof_offset`` lets the caller test
    against the 3D region's K+1 critical value, which is the binding one for
    the edge guard. Probed at two extreme phi values per side for stability.
    """
    crit = chi2.ppf(1.0 - type_one, len(list(switchers_kept)) + dof_offset)
    open_below = all(_min_wald_at_phi(fit, switchers_kept, base, phi) < crit
                     for phi in (-1e4, -1e5))
    open_above = all(_min_wald_at_phi(fit, switchers_kept, base, phi) < crit
                     for phi in (1e4, 1e5))
    return open_below, open_above


def _hulls_from_sweep(dv_iter, pi_arr, dbar_arr, dbar0_arr, is_dT) -> dict:
    """Evaluate the aggregate over an iterable of delta vectors; return hulls.

    Each element of ``dv_iter`` is a per-trajectory delta vector. P3 zeroes
    the d_T row in the gap (its value contribution is already zero because
    dbar - dbar0 = 0 for always-urban workers); full keeps it.
    """
    wms_full: list[float] = []
    wmm_full: list[float] = []
    wms_p3: list[float] = []
    wmm_p3: list[float] = []
    with np.errstate(invalid="ignore", over="ignore"):
        for dv in dv_iter:
            try:
                dv_p3 = dv.copy()
                dv_p3[is_dT] = 0.0
                r_full = evaluate_aggregate(dv, pi_arr, dbar_arr, dbar0_arr)
                r_p3 = evaluate_aggregate(dv_p3, pi_arr, dbar_arr, dbar0_arr)
                wms_full.append(r_full.w_obs_minus_zero)
                wmm_full.append(r_full.w_opt_minus_obs)
                wms_p3.append(r_p3.w_obs_minus_zero)
                wmm_p3.append(r_p3.w_opt_minus_obs)
            except (ValueError, FloatingPointError):
                wms_full.append(float("nan"))
                wmm_full.append(float("nan"))
                wms_p3.append(float("nan"))
                wmm_p3.append(float("nan"))
    return {
        "wmm_p3": project_image_intervals(np.array(wmm_p3))["convex_hull"],
        "wms_p3": project_image_intervals(np.array(wms_p3))["convex_hull"],
        "wmm_full": project_image_intervals(np.array(wmm_full))["convex_hull"],
        "wms_full": project_image_intervals(np.array(wms_full))["convex_hull"],
    }


def run_cell(short: str, inputs_dir, data_dir) -> CellResult:
    """Compute the E1 aggregate and both coverage-variant intervals for one cell.

    Every LCA object comes from one per-capita, covariate-adjusted source:
    the auxiliary-OLS fit (alpha differences) for the never cell, kept
    switchers, and the d_T Mobius input; the ster's mu:switcher_k for sparse
    non-kept switchers. Switcher returns are recomputed on the LCA line at
    every lattice point (D1); the lumped cell's return is the tested
    delta_unb coordinate under variant 1 and the auxiliary-OLS coefficient
    otherwise.
    """
    cfg = CELLS[short]
    phi_grid = np.linspace(*cfg["phi"])
    beta_grid = np.linspace(*cfg.get("beta", BETA_GRID_SPEC))

    inp = load_cell_inputs(short, inputs_dir)
    traj_df = inp["trajectory"].sort_values("traj_for_agg").reset_index(drop=True)
    scalars = inp["scalars"]

    df, controls = prepare_data(cfg["file_stem"], data_dir)
    n_obs = len(df)
    n_pids = int(df["pid"].nunique())
    if (n_obs != int(scalars["n_rows_filtered"])
            or n_pids != int(scalars["n_pids_filtered"])):
        raise ValueError(
            f"{short}: sample mismatch vs exporter: rows {n_obs} vs "
            f"{int(scalars['n_rows_filtered'])}, pids {n_pids} vs "
            f"{int(scalars['n_pids_filtered'])}; the exporter and "
            f"prepare_data filters have diverged."
        )

    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    K = len(kept)
    base = int(scalars["base"])
    if base not in kept:
        raise ValueError(f"{short}: ster base {base} not in switchers_kept {kept}")

    fit = fit_auxiliary_ols(
        df, outcome="lndepvar", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=kept, controls=controls,
    )

    trajectories = sorted(int(t) for t in df["trajectory"].dropna().unique())
    never_traj, always_traj = trajectories[0], trajectories[-1]
    max_traj = int(traj_df["traj_for_agg"].max())
    if never_traj != 1 or always_traj != max_traj:
        raise ValueError(
            f"{short}: trajectory coding mismatch: data range "
            f"[{never_traj}, {always_traj}] vs traj CSV max {max_traj}"
        )

    alpha_base = float(fit.b[fit.idx(f"alpha[{base}]")])
    alpha_never = float(fit.b[fit.idx(f"alpha[{never_traj}]")])
    alpha_dT = float(fit.b[fit.idx(f"alpha[{always_traj}]")])
    unb_idx = fit.idx("unbalanced_choice")
    unb_ols = float(fit.b[unb_idx])
    unb_se = float(np.sqrt(fit.V[unb_idx, unb_idx]))
    unb_gmm = float(scalars["unb_choice_hat"])

    traj_codes = traj_df["traj_for_agg"].to_numpy(dtype=int)
    pi_arr = traj_df["pi_d"].to_numpy(dtype=float)
    dbar_arr = traj_df["dbar_d"].to_numpy(dtype=float)
    dbar0_arr = traj_df["dbar0_d"].to_numpy(dtype=float)
    mu_ster = traj_df["mu_d_ster"].to_numpy(dtype=float)
    is_dN = traj_codes == never_traj
    is_dT = traj_codes == always_traj
    is_lumped = traj_codes == -1
    is_switcher = ~(is_dN | is_dT | is_lumped)

    # LCA slope input per row: OLS alpha differences for the never cell and
    # kept switchers; ster mu differences for sparse non-kept switchers,
    # whose OLS alpha pools rural and urban observations. d_T and the lumped
    # cell are overwritten inside delta_at.
    mu_ster_base = float(
        traj_df.loc[traj_df["traj_for_agg"] == base, "mu_d_ster"].iloc[0]
    )
    if not np.isfinite(mu_ster_base):
        raise ValueError(f"{short}: mu_d_ster missing for base trajectory {base}")
    diff_arr = np.zeros(len(traj_codes))
    for i, t in enumerate(traj_codes):
        if is_dN[i]:
            diff_arr[i] = alpha_never - alpha_base
        elif is_switcher[i]:
            if t in kept:
                diff_arr[i] = float(fit.b[fit.idx(f"alpha[{t}]")]) - alpha_base
            else:
                if not np.isfinite(mu_ster[i]):
                    raise ValueError(
                        f"{short}: sparse switcher {t} has no mu_d_ster"
                    )
                diff_arr[i] = mu_ster[i] - mu_ster_base

    def delta_at(phi: float, beta: float, delta_unb: float) -> np.ndarray:
        out = beta + phi * diff_arr
        out = np.where(is_lumped, delta_unb, out)
        out = np.where(is_dT, lca_delta_dT(phi, beta, alpha_dT, alpha_base), out)
        return out

    # Self-check: the OLS-alpha LCA extrapolation at the GMM point should
    # reproduce the ster's Delta_never (two estimators of one object; 0.01
    # is the inversion grid resolution). CHN_uf is exempt from the hard 0.01
    # bound with a loose 0.15 sanity cap: near the phi = -1 boundary the
    # restricted GMM's mu and the unrestricted OLS alpha genuinely diverge,
    # which is why the point estimate below comes from the ster objects and
    # the interval from the weak-ID-robust region (the same pairing the GRC
    # tables use). On any other failure investigate; never loosen.
    phi_hat = float(scalars["phi_hat"])
    beta_hat = float(scalars["beta_hat"])
    delta_never_point = float(scalars["delta_never_point"])
    delta_always_point = float(scalars["delta_always_point"])
    if not np.isfinite(delta_always_point):
        raise ValueError(
            f"{short}: delta_always_point is not finite; check the _a ster export"
        )
    d_dN_ols = beta_hat + phi_hat * (alpha_never - alpha_base)
    dN_gap = d_dN_ols - delta_never_point
    tol = 0.15 if short in WEAK_ID_EXEMPT else 0.01
    if abs(dN_gap) > tol:
        raise ValueError(
            f"{short}: OLS-alpha Delta_dN at the point ({d_dN_ols:+.4f}) "
            f"differs from ster delta_never_point ({delta_never_point:+.4f}) "
            f"by {dN_gap:+.4f} > {tol}."
        )
    print(f"  {short}: Delta_dN ster point {delta_never_point:+.4f}, "
          f"OLS-alpha plug-in {d_dN_ols:+.4f} (gap {dN_gap:+.4f}), "
          f"base = {base}")

    # Unbounded-region probe: under weak identification the S-statistic can
    # accept arbitrarily large |phi| (CHN_uf does, on both sides); those phi
    # edges are declared open instead of erroring, and diverging hull
    # endpoints are marked infinite below. The probe uses the 3D (K+1)
    # critical value, the binding one for the wider region.
    open_lo, open_hi = _phi_open_sides(fit, kept, base, TYPE_ONE, dof_offset=1)
    phi_open = open_lo or open_hi
    open_edges = set()
    if open_lo:
        open_edges.add(("phi", "lo"))
    if open_hi:
        open_edges.add(("phi", "hi"))
    if phi_open:
        sides = " and ".join(s for s, f in [("below", open_lo), ("above", open_hi)] if f)
        print(f"  {short}: phi confidence region is UNBOUNDED {sides} "
              f"(S-statistic accepts phi -> +/-inf)")

    # Variant 2 region: 2D (phi, beta), dof K.
    ci2 = build_joint_ci_grid(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=phi_grid, beta_grid=beta_grid, type_one=TYPE_ONE,
    )
    accept2 = ci2["accept"]
    _assert_region_interior(accept2, ["phi", "beta"], short, open_edges)

    # Variant 1 region: 3D (phi, beta, delta_unb), dof K+1. Grid halfwidth
    # sqrt(chi2_{K+1,0.95}) + 1 SEs so the accepted range cannot clip.
    halfw = (np.sqrt(chi2.ppf(1.0 - TYPE_ONE, K + 1)) + 1.0) * unb_se
    n_unb = int(2 * np.ceil(halfw / (unb_se / 5.0))) + 1
    unb_grid = np.linspace(unb_ols - halfw, unb_ols + halfw, n_unb)
    ci3 = build_joint_ci_grid_3d(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=phi_grid, beta_grid=beta_grid, unb_grid=unb_grid,
        type_one=TYPE_ONE,
    )
    accept3 = ci3["accept"]
    _assert_region_interior(accept3, ["phi", "beta", "delta_unb"], short,
                            open_edges)

    phi_m = accept3.any(axis=(1, 2))
    beta_m = accept3.any(axis=(0, 2))
    unb_m = accept3.any(axis=(0, 1))
    marginal_phi = ((float(phi_grid[phi_m][0]), float(phi_grid[phi_m][-1]))
                    if phi_m.any() else None)
    marginal_beta = ((float(beta_grid[beta_m][0]), float(beta_grid[beta_m][-1]))
                     if beta_m.any() else None)
    marginal_unb = ((float(unb_grid[unb_m][0]), float(unb_grid[unb_m][-1]))
                    if unb_m.any() else None)
    crosses_boundary = bool(phi_m.any() and phi_grid[phi_m][0] <= -1.0)

    # Sweep variant 1: the aggregate at every accepted 3D point.
    def _iter_v1():
        for (i, j, m) in np.argwhere(accept3):
            yield delta_at(float(phi_grid[i]), float(beta_grid[j]),
                           float(unb_grid[m]))

    hulls_v1 = _hulls_from_sweep(_iter_v1(), pi_arr, dbar_arr, dbar0_arr, is_dT)

    # Sweep variant 2: the 2D region with the Delta_unb 95% CI folded in by
    # interval arithmetic. The aggregate is piecewise-linear monotone in
    # delta_unb with a kink at 0, so evaluating the endpoints (plus 0 when
    # straddled) is exact.
    unb_lo = unb_ols - 1.96 * unb_se
    unb_hi = unb_ols + 1.96 * unb_se
    unb_candidates = [unb_lo, unb_hi] + ([0.0] if unb_lo < 0.0 < unb_hi else [])

    def _iter_v2():
        for (i, j) in np.argwhere(accept2):
            for du in unb_candidates:
                yield delta_at(float(phi_grid[i]), float(beta_grid[j]), du)

    hulls_v2 = _hulls_from_sweep(_iter_v2(), pi_arr, dbar_arr, dbar0_arr, is_dT)

    # When phi is unbounded on either side, hulls computed on the finite grid
    # are truncation artifacts wherever the aggregate diverges along an
    # accepted ray. Probe each open ray at two extreme phi (beta concentrated,
    # delta_unb at its center) and mark diverging endpoints infinite in BOTH
    # variants.
    open_rays = ([(-1e3, -2e3)] if open_lo else []) + \
                ([(1e3, 2e3)] if open_hi else [])
    for ray in open_rays:
        probes = []
        with np.errstate(invalid="ignore", over="ignore"):
            for phi_p in ray:
                b_p = _beta_star_at_phi(fit, kept, base, phi_p)
                dv = delta_at(phi_p, b_p, unb_ols)
                dv_p3 = dv.copy()
                dv_p3[is_dT] = 0.0
                r_p3 = evaluate_aggregate(dv_p3, pi_arr, dbar_arr, dbar0_arr)
                r_fl = evaluate_aggregate(dv, pi_arr, dbar_arr, dbar0_arr)
                probes.append({
                    "wmm_p3": r_p3.w_opt_minus_obs, "wms_p3": r_p3.w_obs_minus_zero,
                    "wmm_full": r_fl.w_opt_minus_obs, "wms_full": r_fl.w_obs_minus_zero,
                })
        for key in ("wmm_p3", "wms_p3", "wmm_full", "wms_full"):
            growth = probes[1][key] - probes[0][key]
            if not np.isfinite(growth):
                growth = probes[1][key]
            for hulls in (hulls_v1, hulls_v2):
                lo, hi = hulls[key]
                if growth > 0.005:
                    hulls[key] = (lo, float("inf"))
                elif growth < -0.005:
                    hulls[key] = (float("-inf"), hi)

    # Point estimates from the STER objects (GMM nlcom values: LCA-fitted
    # switcher returns, Delta_never, and Delta_always), matching the paper's
    # GRC tables; the lumped cell takes the auxiliary-OLS coefficient (the
    # interval center). The two reported variants differ only in the
    # always-urban row: variant A sources it from the _a ster, variant B
    # zeroes it in both the gap and the all-rural value term.
    lcafit = traj_df["delta_d_lcafit_point"].to_numpy(dtype=float)
    if np.isnan(lcafit[is_switcher]).any():
        bad = traj_df.loc[is_switcher & np.isnan(lcafit), "traj_for_agg"].tolist()
        raise ValueError(f"{short}: switcher rows {bad} missing delta_d_lcafit_point")
    dv_hat = np.where(is_switcher, lcafit, 0.0)
    dv_hat[is_dN] = delta_never_point
    dv_hat[is_lumped] = unb_ols
    dv_hat_A = dv_hat.copy()
    dv_hat_A[is_dT] = delta_always_point
    dv_hat_B = dv_hat.copy()
    dv_hat_B[is_dT] = 0.0
    r_hat_A = evaluate_aggregate(dv_hat_A, pi_arr, dbar_arr, dbar0_arr)
    r_hat_B = evaluate_aggregate(dv_hat_B, pi_arr, dbar_arr, dbar0_arr)
    # Value vs the everyone-rural baseline: all urban person-time is valued,
    # so the always-urban row enters (with Dbar = 1) and the variant matters.
    value_allrural_A = float(np.nansum(pi_arr * dv_hat_A * dbar_arr))
    value_allrural_B = float(np.nansum(pi_arr * dv_hat_B * dbar_arr))

    # D1 cross-check: the point gap with genuinely unrestricted switcher
    # returns (beta[s] from a fit that interacts EVERY switcher trajectory
    # with choice) in place of the LCA-line values.
    all_switchers = [t for t in trajectories
                     if t not in (never_traj, always_traj)]
    fit_all = fit_auxiliary_ols(
        df, outcome="lndepvar", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=all_switchers, controls=controls,
    )
    dv_x = dv_hat_B.copy()
    for i, t in enumerate(traj_codes):
        if is_switcher[i]:
            dv_x[i] = float(fit_all.b[fit_all.idx(f"beta[{t}]")])
    r_x = evaluate_aggregate(dv_x, pi_arr, dbar_arr, dbar0_arr)

    decomposition = pd.DataFrame({
        "cell": short,
        "traj_for_agg": traj_codes,
        "pi_d": pi_arr,
        "dbar_d": dbar_arr,
        "dbar0_d": dbar0_arr,
        "delta_point_varA": dv_hat_A,
        "delta_point_varB": dv_hat_B,
        "contrib_gap_varA": r_hat_A.contrib_opt_obs,
        "contrib_gap_varB": r_hat_B.contrib_opt_obs,
        "contrib_value_d0": r_hat_B.contrib_obs_zero,
        "contrib_value_allrural_varA": pi_arr * dv_hat_A * dbar_arr,
        "contrib_value_allrural_varB": pi_arr * dv_hat_B * dbar_arr,
    })

    if marginal_phi is not None:
        if open_lo:
            marginal_phi = (float("-inf"), marginal_phi[1])
        if open_hi:
            marginal_phi = (marginal_phi[0], float("inf"))

    return CellResult(
        short=short, n_obs=n_obs, n_pids=n_pids, K=K, base=base,
        n_accept_2d=int(accept2.sum()), n_accept_3d=int(accept3.sum()),
        crosses_boundary=crosses_boundary, phi_open_below=open_lo,
        phi_open_above=open_hi,
        marginal_phi=marginal_phi, marginal_beta=marginal_beta,
        marginal_unb=marginal_unb,
        hull_wmm_p3_v1=hulls_v1["wmm_p3"], hull_wms_p3_v1=hulls_v1["wms_p3"],
        hull_wmm_full_v1=hulls_v1["wmm_full"], hull_wms_full_v1=hulls_v1["wms_full"],
        hull_wmm_p3_v2=hulls_v2["wmm_p3"], hull_wms_p3_v2=hulls_v2["wms_p3"],
        hull_wmm_full_v2=hulls_v2["wmm_full"], hull_wms_full_v2=hulls_v2["wms_full"],
        point_gap_varA=r_hat_A.w_opt_minus_obs,
        point_gap_varB=r_hat_B.w_opt_minus_obs,
        point_value_d0=r_hat_B.w_obs_minus_zero,
        point_value_allrural_varA=value_allrural_A,
        point_value_allrural_varB=value_allrural_B,
        unb_ols=unb_ols, unb_se_ols=unb_se, unb_gmm=unb_gmm,
        xcheck_gap_unrestricted=r_x.w_opt_minus_obs,
        xcheck_gap_diff=r_x.w_opt_minus_obs - r_hat_B.w_opt_minus_obs,
        decomposition=decomposition,
    )


def hukou_population_weights(data_dir) -> dict:
    """Pid-level RF / UF partition shares of the full CHN sample."""
    data_dir = Path(data_dir)
    chn = set(pd.read_stata(data_dir / "CHN_unb.dta",
                            convert_categoricals=False)["pid"].unique())
    rf = set(pd.read_stata(data_dir / "CHN_hukou_rural_first_unb.dta",
                           convert_categoricals=False)["pid"].unique())
    uf = set(pd.read_stata(data_dir / "CHN_hukou_urban_first_unb.dta",
                           convert_categoricals=False)["pid"].unique())
    n_chn, n_rf, n_uf = len(chn), len(rf), len(uf)
    return {
        "n_chn": n_chn, "n_rf": n_rf, "n_uf": n_uf,
        "w_rf_cond": n_rf / (n_rf + n_uf), "w_uf_cond": n_uf / (n_rf + n_uf),
        "w_rf_full": n_rf / n_chn, "w_uf_full": n_uf / n_chn,
    }


def combine_national(rf: CellResult, uf: CellResult,
                     w_rf: float, w_uf: float) -> dict:
    """Population-weighted national CHN point aggregates.

    Weighted sums of the two hukou regimes' point estimates. No intervals
    are combined: E1 interval reporting is pending the WCR11 joint-region
    extension, and the per-cell hulls live in the diagnostics CSV only.
    """
    def comb(a: float, b: float) -> float:
        return w_rf * a + w_uf * b

    return {
        "short": "CHN_national",
        "point_gap_varA": comb(rf.point_gap_varA, uf.point_gap_varA),
        "point_gap_varB": comb(rf.point_gap_varB, uf.point_gap_varB),
        "point_value_d0": comb(rf.point_value_d0, uf.point_value_d0),
        "point_value_allrural_varA": comb(rf.point_value_allrural_varA,
                                          uf.point_value_allrural_varA),
        "point_value_allrural_varB": comb(rf.point_value_allrural_varB,
                                          uf.point_value_allrural_varB),
        "w_rf": w_rf, "w_uf": w_uf,
    }


def hukou_bound_point(pi_rh: float, pi_dN_rh: float, delta_dN_rh: float) -> float:
    """E2 lower bound: pi_rh * pi_dN_rh * Delta_dN_rh (log per-capita consumption)."""
    return float(pi_rh * pi_dN_rh * delta_dN_rh)


def run_hukou_bound(inputs_dir, data_dir, weights: dict) -> HukouBoundResult:
    """E2 hukou-wedge lower bound for the rural-hukou regime.

    Scales the rural-hukou never-migrant return Delta_dN_rh (the GMM nlcom
    point on the CHN_rf ``_n`` ster, with its delta-method 95% CI exported in
    the scalars CSV as gmm_dN_ci95_{lo,hi}) by the fixed constant
    pi_rh * pi_dN_rh. pi_rh is the conditional rural-hukou share of the
    defined-hukou CHN sample (the same base the E1 national figure uses);
    pi_dN_rh is the never-migrant share within the rural-hukou subsample.
    The GMM CI replaced the test-inversion CI when the WCR11 attach began
    scrubbing the delta-inversion families; simulated coverage for the GMM
    Delta_dN interval is 0.915-0.940, inside the pre-registered band.

    Endpoint-scaling is the exact test-inversion CI for const * Delta_dN_rh
    because const > 0 is a known constant: the shares' sampling variance is an
    order of magnitude smaller than the inversion width (binomial SE on pi_dN
    ~ 0.003 vs a CI halfwidth ~ 0.02 on Delta_dN_rh), so it is treated as fixed.
    """
    inp = load_cell_inputs("CHN_rf", inputs_dir)
    traj_df = inp["trajectory"]
    scalars = inp["scalars"]

    never_rows = traj_df.loc[traj_df["traj_for_agg"] == 1, "pi_d"]
    if len(never_rows) != 1:
        raise ValueError(
            f"CHN_rf: expected exactly one never (traj_for_agg==1) row for "
            f"pi_dN_rh, found {len(never_rows)}"
        )
    pi_dN_rh = float(never_rows.iloc[0])
    pi_rh = float(weights["w_rf_cond"])

    # M1: both shares must be strictly inside (0, 1)
    for _share, _name, _src in [
        (pi_dN_rh, "pi_dN_rh", "CHN_rf_e1_traj.csv pi_d column"),
        (pi_rh, "pi_rh", "hukou_population_weights / w_rf_cond"),
    ]:
        if not (np.isfinite(_share) and 0.0 < _share < 1.0):
            raise ValueError(
                f"CHN_rf: {_name}={_share} is not finite and strictly inside (0, 1); "
                f"check source: {_src}"
            )

    # delta_never_point is the _n-ster nlcom point (matching the RF GRC
    # table); gmm_dN_ci95_{lo,hi} are its delta-method 95% CI endpoints from
    # the same ster's e(V). _export_e1_inputs_hukou.do writes all three under
    # these key names only, so inversion-era values cannot silently mix in.
    for _key in ("delta_never_point", "gmm_dN_ci95_lo", "gmm_dN_ci95_hi"):
        if _key not in scalars:
            raise KeyError(
                f"CHN_rf: required scalar '{_key}' not found in CHN_rf_e1_scalars.csv"
            )
    delta_point = float(scalars["delta_never_point"])
    delta_lo = float(scalars["gmm_dN_ci95_lo"])
    delta_hi = float(scalars["gmm_dN_ci95_hi"])
    if not all(np.isfinite([delta_point, delta_lo, delta_hi])):
        raise ValueError(
            f"CHN_rf: non-finite gmm_dN scalars (point={delta_point}, "
            f"lo={delta_lo}, hi={delta_hi}); check the CHN_rf_e1_scalars.csv export."
        )
    if delta_lo > delta_hi:
        raise ValueError(
            f"CHN_rf: gmm_dN CI endpoints out of order: lo={delta_lo} > hi={delta_hi}"
        )
    ci_source = str(scalars.get("gmm_dN_ci95_source", "")).strip()
    if not ci_source:
        raise ValueError(
            "CHN_rf: gmm_dN_ci95_source provenance row missing from "
            "CHN_rf_e1_scalars.csv; re-run the hukou exporter."
        )

    const = pi_rh * pi_dN_rh
    return HukouBoundResult(
        pi_rh=pi_rh,
        pi_dN_rh=pi_dN_rh,
        const=const,
        delta_dN_rh_point=delta_point,
        delta_dN_rh_ci=(delta_lo, delta_hi),
        ci_source=ci_source,
        point_bound=hukou_bound_point(pi_rh, pi_dN_rh, delta_point),
        hull_bound=(const * delta_lo, const * delta_hi),
        floor_positive=bool(delta_lo > 0.0),
    )


def run_all_cells(inputs_dir, data_dir) -> dict:
    """Run all four base cells, the national CHN combination, and the E2 bound."""
    cells = {short: run_cell(short, inputs_dir, data_dir) for short in CELLS}
    weights = hukou_population_weights(data_dir)
    # National CHN uses conditional hukou weights (rf or uf, normalized to
    # sum to one). The ~0.7% of CHN pids with undefined hukou status are
    # excluded; the conditional, full-N, and analysis-sample weighting
    # schemes agree within 0.1pp, so the choice does not move the headline.
    national = combine_national(
        cells["CHN_rf"], cells["CHN_uf"],
        weights["w_rf_cond"], weights["w_uf_cond"],
    )
    hukou_bound = run_hukou_bound(inputs_dir, data_dir, weights)
    return {"cells": cells, "national": national, "weights": weights,
            "hukou_bound": hukou_bound}


# ---------------------------------------------------------------------------
# Persistence: results CSV, paper table, golden-snapshot self-check.
# ---------------------------------------------------------------------------

# Display labels and row order for the paper table.
_LABELS = {
    "IDN": "Indonesia",
    "TZA": "Tanzania",
    "CHN_national": "China (national)",
    "CHN_rf": r"\quad rural-hukou first",
    "CHN_uf": r"\quad urban-hukou first",
}
_TABLE_ORDER = ["IDN", "TZA", "CHN_national", "CHN_rf", "CHN_uf"]


def _rows_for_cell(short: str, gap_A: float, gap_B: float, val_d0: float,
                   val_ar_A: float, val_ar_B: float) -> list[dict]:
    """Emit the reported point rows for one cell.

    Interval rows are absent by design: the E1 joint-region hull's measured
    coverage is 0.820, so no E1 interval is reported pending the WCR11
    joint-region extension. The computed hulls live in the diagnostics CSV.
    """
    nan = float("nan")
    return [
        _result_row(short, "misallocation", "point_varA", nan, nan, gap_A),
        _result_row(short, "misallocation", "point_varB", nan, nan, gap_B),
        _result_row(short, "value_migration_d0", "point", nan, nan, val_d0),
        _result_row(short, "value_migration_allrural", "point_varA",
                    nan, nan, val_ar_A),
        _result_row(short, "value_migration_allrural", "point_varB",
                    nan, nan, val_ar_B),
    ]


def _result_row(cell, quantity, version, lo, hi, point, ci_source="") -> dict:
    """One long-format result row in the persisted schema (log + percent)."""
    return {
        "cell": cell, "quantity": quantity, "version": version,
        "ci_lo_log": lo, "ci_hi_log": hi, "point_log": point,
        "ci_lo_pct": log_to_pct(lo) * 100.0,
        "ci_hi_pct": log_to_pct(hi) * 100.0,
        "point_pct": log_to_pct(point) * 100.0 if np.isfinite(point) else float("nan"),
        "ci_source": ci_source,
    }


def _hukou_bound_rows(hb: HukouBoundResult) -> list[dict]:
    """E2 rows: the economy-wide bound and the per-never-migrant return.

    Version ``gmm_ci`` names the CI construction (delta-method GMM interval,
    scaled by the fixed shares); ``ci_source`` names the ster behind it.
    """
    return [
        _result_row("CHN_hukou_bound", "hukou_consumption_gain", "gmm_ci",
                    hb.hull_bound[0], hb.hull_bound[1], hb.point_bound,
                    ci_source=hb.ci_source),
        _result_row("CHN_hukou_bound", "delta_dN_rural_hukou", "gmm_ci",
                    hb.delta_dN_rh_ci[0], hb.delta_dN_rh_ci[1],
                    hb.delta_dN_rh_point, ci_source=hb.ci_source),
    ]


def results_dataframe(res: dict) -> pd.DataFrame:
    """Flatten run_all_cells output into the persisted long-format table."""
    rows: list[dict] = []
    for short, c in res["cells"].items():
        rows.extend(_rows_for_cell(
            short, c.point_gap_varA, c.point_gap_varB, c.point_value_d0,
            c.point_value_allrural_varA, c.point_value_allrural_varB,
        ))
    nat = res["national"]
    rows.extend(_rows_for_cell(
        "CHN_national", nat["point_gap_varA"], nat["point_gap_varB"],
        nat["point_value_d0"], nat["point_value_allrural_varA"],
        nat["point_value_allrural_varB"],
    ))
    if "hukou_bound" in res:
        rows.extend(_hukou_bound_rows(res["hukou_bound"]))
    return pd.DataFrame(rows).sort_values(["cell", "quantity", "version"]).reset_index(drop=True)


def diagnostics_dataframes(res: dict) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Cell-level diagnostics and the per-trajectory point decomposition."""
    cell_rows = []
    decomp_frames = []
    hull_fields = ("hull_wmm_p3_v1", "hull_wms_p3_v1",
                   "hull_wmm_full_v1", "hull_wms_full_v1",
                   "hull_wmm_p3_v2", "hull_wms_p3_v2",
                   "hull_wmm_full_v2", "hull_wms_full_v2")
    for short, c in res["cells"].items():
        row = {
            "cell": short, "n_obs": c.n_obs, "n_pids": c.n_pids,
            "K": c.K, "base": c.base,
            "n_accept_2d": c.n_accept_2d, "n_accept_3d": c.n_accept_3d,
            "crosses_boundary": c.crosses_boundary,
            "phi_open_below": c.phi_open_below,
            "phi_open_above": c.phi_open_above,
            "marginal_phi_lo": c.marginal_phi[0] if c.marginal_phi else float("nan"),
            "marginal_phi_hi": c.marginal_phi[1] if c.marginal_phi else float("nan"),
            "marginal_beta_lo": c.marginal_beta[0] if c.marginal_beta else float("nan"),
            "marginal_beta_hi": c.marginal_beta[1] if c.marginal_beta else float("nan"),
            "marginal_unb_lo": c.marginal_unb[0] if c.marginal_unb else float("nan"),
            "marginal_unb_hi": c.marginal_unb[1] if c.marginal_unb else float("nan"),
            "unb_ols": c.unb_ols, "unb_se_ols": c.unb_se_ols,
            "unb_gmm": c.unb_gmm, "unb_ols_minus_gmm": c.unb_ols - c.unb_gmm,
            "point_gap_varA": c.point_gap_varA,
            "point_gap_varB": c.point_gap_varB,
            "xcheck_gap_unrestricted": c.xcheck_gap_unrestricted,
            "xcheck_gap_diff": c.xcheck_gap_diff,
        }
        # Unreported joint-region hulls (measured coverage 0.820) are kept
        # here as diagnostics, not in the results CSV.
        for h in hull_fields:
            lo, hi = getattr(c, h)
            row[f"{h}_lo"] = lo
            row[f"{h}_hi"] = hi
        cell_rows.append(row)
        decomp_frames.append(c.decomposition)
    return pd.DataFrame(cell_rows), pd.concat(decomp_frames, ignore_index=True)


def _fmt_interval(lo_pct: float, hi_pct: float) -> str:
    return f"$[{lo_pct:+.1f}\\%, {hi_pct:+.1f}\\%]$"


def write_e1_variant_table(res: dict, table_path, variant: str,
                           label: str | None = None) -> None:
    """Write one E1 points table for the always-urban treatment ``variant``.

    Variant A sources the always-urban return from the ``_a``-ster GMM point;
    variant B zeroes the always-urban row. Three point columns: misallocation
    gap, value of migration vs. the first-observed location, and value of
    migration vs. the everyone-rural baseline. No interval column: the
    joint-region hull's measured coverage is 0.820, so E1 intervals are
    unavailable pending the WCR11 joint-region extension.
    """
    if variant not in ("A", "B"):
        raise ValueError(f"write_e1_variant_table: variant must be A or B, got {variant!r}")
    sfx = f"var{variant}"

    def cell_points(short):
        if short == "CHN_national":
            nat = res["national"]
            return (nat[f"point_gap_{sfx}"], nat["point_value_d0"],
                    nat[f"point_value_allrural_{sfx}"])
        c = res["cells"][short]
        return (getattr(c, f"point_gap_{sfx}"), c.point_value_d0,
                getattr(c, f"point_value_allrural_{sfx}"))

    lines = [
        r"\begin{table}[htbp]",
        r"\centering",
        r"\caption{Counterfactual misallocation accounting, by country.}",
        rf"\label{{{label or f'tab:counterfactual_misallocation_{sfx}'}}}",
        r"\begin{tabular}{lccc}",
        r"\toprule",
        r" & Misallocation & Value of migration & Value of migration \\",
        r" & gap & (vs. first location) & (vs. all rural) \\",
        r"\midrule",
    ]
    for short in _TABLE_ORDER:
        pts = cell_points(short)
        for v in pts:
            if not np.isfinite(v):
                raise ValueError(
                    f"write_e1_variant_table: non-finite value for {short}: {pts}"
                )
        cells = " & ".join(f"${log_to_pct(v) * 100.0:+.1f}\\%$" for v in pts)
        lines.append(f"{_LABELS[short]} & {cells} \\\\")
    note = (
        "Always-urban workers enter the gap and all-rural value columns at "
        "their GMM point estimate."
        if variant == "A" else
        "Always-urban workers are excluded (their row is set to zero) in the "
        "gap and all-rural value columns."
    )
    lines += [r"\bottomrule", r"\end{tabular}",
              rf"\par\smallskip {{\footnotesize {note}}}",
              r"\end{table}", ""]

    table_path = Path(table_path)
    table_path.parent.mkdir(parents=True, exist_ok=True)
    table_path.write_text("\n".join(lines), encoding="utf-8")


def write_hukou_bound_table(res: dict, table_path) -> None:
    """Write the paper-facing E2 hukou-bound table (rural-hukou regime).

    Self-contained float, parallel to write_e1_variant_table: caption, label, and
    tabular only; the population identity, fixed-share assumption, and
    partial-equilibrium-floor framing live in the paper prose, not embedded
    here. Reports the per-never-migrant return Delta_dN_rh (with its 95%
    inversion CI) and the economy-wide consumption gain (lower bound, with its
    95% CI). Every value is formatted from the computed result; nothing
    hardcoded.
    """
    hb = res["hukou_bound"]
    d_pt = log_to_pct(hb.delta_dN_rh_point) * 100.0
    d_lo = log_to_pct(hb.delta_dN_rh_ci[0]) * 100.0
    d_hi = log_to_pct(hb.delta_dN_rh_ci[1]) * 100.0
    b_pt = log_to_pct(hb.point_bound) * 100.0
    b_lo = log_to_pct(hb.hull_bound[0]) * 100.0
    b_hi = log_to_pct(hb.hull_bound[1]) * 100.0
    for v in (d_pt, d_lo, d_hi, b_pt, b_lo, b_hi):
        if not np.isfinite(v):
            raise ValueError(f"write_hukou_bound_table: non-finite value {v}")

    lines = [
        r"\begin{table}[htbp]",
        r"\centering",
        r"\caption{Removing the rural-hukou barrier: lower bound on the consumption gain.}",
        r"\label{tab:hukou_bound}",
        r"\begin{tabular}{lcc}",
        r"\toprule",
        r" & Point & 95\% CI \\",
        r"\midrule",
        f"Return per never-migrant $\\Delta_{{d_N}}^{{rh}}$ & "
        f"${d_pt:+.1f}\\%$ & {_fmt_interval(d_lo, d_hi)} \\\\",
        f"Economy-wide gain (lower bound) & "
        f"${b_pt:+.1f}\\%$ & {_fmt_interval(b_lo, b_hi)} \\\\",
        r"\bottomrule",
        r"\end{tabular}",
        r"\end{table}",
        "",
    ]

    table_path = Path(table_path)
    table_path.parent.mkdir(parents=True, exist_ok=True)
    table_path.write_text("\n".join(lines), encoding="utf-8")


def _self_check(fresh: pd.DataFrame, baseline_path, atol_log: float = 1e-3) -> None:
    """Compare the fresh run against the committed baseline snapshot.

    Joins on (cell, quantity, version) and asserts every log-point value is
    within ``atol_log`` of the baseline. Raises with a per-row message on
    drift so a changed number fails loudly rather than silently shipping.
    NaN point estimates (with-d_T) are exempt from the point comparison.
    """
    baseline_path = Path(baseline_path)
    if not baseline_path.exists():
        raise FileNotFoundError(
            f"baseline snapshot missing: {baseline_path}. "
            f"Run with regenerate_baseline=True to create it after verifying "
            f"the numbers by hand."
        )
    base = pd.read_csv(baseline_path)
    key = ["cell", "quantity", "version"]
    merged = fresh.merge(base, on=key, suffixes=("_new", "_base"), how="outer",
                         indicator=True)
    missing = merged[merged["_merge"] != "both"]
    if len(missing):
        raise ValueError(
            f"self-check: {len(missing)} rows present in only one of "
            f"fresh/baseline:\n{missing[key + ['_merge']].to_string(index=False)}"
        )

    problems = []
    for col in ["ci_lo_log", "ci_hi_log", "point_log"]:
        a = merged[f"{col}_new"].to_numpy(dtype=float)
        b = merged[f"{col}_base"].to_numpy(dtype=float)
        both_nan = np.isnan(a) & np.isnan(b)
        both_inf_same = np.isinf(a) & np.isinf(b) & (np.sign(a) == np.sign(b))
        diff = np.abs(a - b)
        bad = (~both_nan) & (~both_inf_same) & ~(diff <= atol_log)
        for idx in np.argwhere(bad).ravel():
            r = merged.iloc[idx]
            problems.append(
                f"  {r['cell']}/{r['quantity']}/{r['version']} {col}: "
                f"new={a[idx]:+.6f} base={b[idx]:+.6f} |diff|={diff[idx]:.6f}"
            )
    if "ci_source_new" in merged.columns and "ci_source_base" in merged.columns:
        sa = merged["ci_source_new"].fillna("").astype(str)
        sb = merged["ci_source_base"].fillna("").astype(str)
        for idx in np.flatnonzero((sa != sb).to_numpy()):
            r = merged.iloc[idx]
            problems.append(
                f"  {r['cell']}/{r['quantity']}/{r['version']} ci_source: "
                f"new={sa.iloc[idx]!r} base={sb.iloc[idx]!r}"
            )

    if problems:
        raise ValueError(
            "self-check FAILED: reproduced numbers drifted from baseline "
            f"(atol={atol_log} log pts):\n" + "\n".join(problems)
        )


def run_counterfactuals_for_stata(
    inputs_dir: str,
    data_dir: str,
    out_dir: str,
    tables_dir: str,
    allow_drift: bool = False,
    regenerate_baseline: bool = False,
    e1_variant: str = "",
    baseline_path: str | None = None,
    atol_log: float = 1e-3,
) -> None:
    """Stata-facing entry point (called from 12_counterfactuals.do).

    Runs all E1 cells plus the E2 hukou bound, writes the persisted results
    CSV, the diagnostics CSVs, and the paper tables, and self-checks against
    the committed baseline snapshot. Both E1 variant tables
    (``counterfactual_misallocation_var{A,B}.tex``) are always written for
    author comparison; the canonical ``counterfactual_misallocation.tex`` the
    paper inputs is written only when ``e1_variant`` is ``"A"`` or ``"B"``
    (the author's pick). ``allow_drift=True`` prints the drift report loudly
    but does not raise --- for transition runs whose numbers await approval
    before the baseline is regenerated.
    """
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    tables_dir = Path(tables_dir)
    tables_dir.mkdir(parents=True, exist_ok=True)
    results_csv = out_dir / "counterfactual_results.csv"
    if baseline_path is None:
        baseline_path = out_dir / "counterfactual_results_baseline.csv"
    if e1_variant and e1_variant not in ("A", "B"):
        raise ValueError(
            f"e1_variant must be '', 'A', or 'B'; got {e1_variant!r}"
        )

    res = run_all_cells(inputs_dir, data_dir)
    df = results_dataframe(res)
    df.to_csv(results_csv, index=False)
    print(f"  wrote results: {results_csv}")

    diag_df, decomp_df = diagnostics_dataframes(res)
    diag_df.to_csv(out_dir / "counterfactual_diagnostics.csv", index=False)
    decomp_df.to_csv(out_dir / "counterfactual_decomposition.csv", index=False)
    print(f"  wrote diagnostics: {out_dir / 'counterfactual_diagnostics.csv'}")

    if regenerate_baseline:
        df.to_csv(baseline_path, index=False)
        print(f"  wrote baseline snapshot: {baseline_path}")
    else:
        try:
            _self_check(df, baseline_path, atol_log=atol_log)
            print(f"  self-check passed against {baseline_path}")
        except (ValueError, FileNotFoundError) as exc:
            if not allow_drift:
                raise
            print(f"  self-check DRIFT (allowed for this transition run):\n{exc}")

    for v in ("A", "B"):
        p = tables_dir / f"counterfactual_misallocation_var{v}.tex"
        write_e1_variant_table(res, p, v)
        print(f"  wrote table (variant {v}): {p}")
    if e1_variant:
        p = tables_dir / "counterfactual_misallocation.tex"
        write_e1_variant_table(res, p, e1_variant,
                               label="tab:counterfactual_misallocation")
        print(f"  wrote canonical table (variant {e1_variant}): {p}")

    write_hukou_bound_table(res, tables_dir / "hukou_bound.tex")
    print(f"  wrote table: {tables_dir / 'hukou_bound.tex'}")

    # Headline echo for the Stata log: both variants' points side by side.
    for short in _TABLE_ORDER:
        if short == "CHN_national":
            nat = res["national"]
            ga, gb = nat["point_gap_varA"], nat["point_gap_varB"]
            v0 = nat["point_value_d0"]
            va, vb = (nat["point_value_allrural_varA"],
                      nat["point_value_allrural_varB"])
        else:
            c = res["cells"][short]
            ga, gb, v0 = c.point_gap_varA, c.point_gap_varB, c.point_value_d0
            va, vb = c.point_value_allrural_varA, c.point_value_allrural_varB
        print(f"  {short:14s} gap A {log_to_pct(ga) * 100:+.2f}%"
              f"  B {log_to_pct(gb) * 100:+.2f}%"
              f"   value d0 {log_to_pct(v0) * 100:+.2f}%"
              f"   allrural A {log_to_pct(va) * 100:+.2f}%"
              f"  B {log_to_pct(vb) * 100:+.2f}%")

    hb = res["hukou_bound"]
    print(f"  E2 hukou bound: pi_rh={hb.pi_rh:.4f} pi_dN_rh={hb.pi_dN_rh:.4f} "
          f"const={hb.const:.4f}  ci_source={hb.ci_source}")
    print(f"  E2 Delta_dN_rh          "
          f"[{log_to_pct(hb.delta_dN_rh_ci[0]) * 100:+.2f}%, "
          f"{log_to_pct(hb.delta_dN_rh_ci[1]) * 100:+.2f}%]"
          f"   point {log_to_pct(hb.delta_dN_rh_point) * 100:+.2f}%")
    print(f"  E2 economy-wide gain    "
          f"[{log_to_pct(hb.hull_bound[0]) * 100:+.2f}%, "
          f"{log_to_pct(hb.hull_bound[1]) * 100:+.2f}%]"
          f"   point {log_to_pct(hb.point_bound) * 100:+.2f}%"
          f"   (floor_positive={hb.floor_positive})")
