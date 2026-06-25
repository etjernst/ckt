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


# ===========================================================================
# Orchestration: the single reproducible E1 path.
#
# Graduates the two dated drivers (2026-05-20_e1_v3_joint_ci.py and
# 2026-05-20_e1_chn_national.py) into one code path. Mirrors
# lca_inversion.attach_inversion_for_stata: 12_counterfactuals.do calls
# run_counterfactuals_for_stata over the SFI python: bridge, and every E1
# misallocation aggregate is computed here.
# ===========================================================================

THRESHOLD = 5
TYPE_ONE = 0.05
BASE_TRAJECTORY = 2

# Per-cell configuration. The CHN hukou cells use a wider, finer phi grid:
# the UF marginal phi sits entirely below -1 (the identification boundary),
# so the grid must reach far enough negative to bracket the accepted region.
CELLS = {
    "IDN":    {"file_stem": "IDN",                   "phi": (-2.0, 1.0, 301)},
    "TZA":    {"file_stem": "TZA",                   "phi": (-2.0, 1.0, 301)},
    "CHN_rf": {"file_stem": "CHN_hukou_rural_first", "phi": (-3.5, 1.0, 451)},
    "CHN_uf": {"file_stem": "CHN_hukou_urban_first", "phi": (-3.5, 1.0, 451)},
}
BETA_GRID_SPEC = (-0.5, 0.5, 101)


@dataclass
class CellResult:
    """Per-cell E1 outputs, in log per-capita consumption units.

    Convex hulls are (lo, hi) tuples; percent quantities are exp(x) - 1
    (change in geometric-mean consumption). P3 is the no-d_T variant that
    drops the always-urban contribution when the joint CI crosses the
    phi = -1 identification boundary; full keeps it.
    """
    short: str
    n_obs: int
    n_pids: int
    K: int
    base: int
    n_accept: int
    n_total: int
    crosses_boundary: bool
    marginal_phi: tuple[float, float] | None
    marginal_beta: tuple[float, float] | None
    hull_wmm_p3: tuple[float, float]    # misallocation gap, P3
    hull_wms_p3: tuple[float, float]    # value of observed migration, P3
    hull_wmm_full: tuple[float, float]  # misallocation gap, with d_T
    hull_wms_full: tuple[float, float]  # value of observed migration, with d_T
    point_wmm_p3: float                 # at (phi_hat, beta_hat), P3
    point_wms_p3: float


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
    """
    pi_rh: float
    pi_dN_rh: float
    const: float
    delta_dN_rh_point: float
    delta_dN_rh_ci: tuple[float, float]   # 95% inversion CI on Delta_dN_rh
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
    df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])
    # 5b drops only mi(lndepvar) | mi(choice); compute_all_inversion_cis
    # additionally needs the controls + unbalanced dummies non-NaN.
    df = df.dropna(subset=["lndepvar", "choice"]).copy()
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


def load_cell_inputs(short: str, inputs_dir) -> dict:
    """Read the four ster-derived input CSVs for one cell and merge them.

    The CSVs (`{short}_e1_{traj,mu_d,delta_d,scalars}.csv`) are written by
    _export_e1_inputs.do / _export_e1_inputs_hukou.do from the GRC sters.
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
    df = traj.merge(mu_d, on="traj_for_agg", how="left").merge(
        delta_d.rename(columns={"trajectory": "traj_for_agg"}),
        on="traj_for_agg", how="left",
    )
    return {"trajectory": df, "scalars": scalars}


def compute_alpha_dT_obs(data: pd.DataFrame, traj_var: str, choice_var: str,
                         dT_code: int) -> float:
    """Mean observed urban log per-capita consumption for trajectory == d_T.

    Uses the already-constructed lndepvar column (= log(consumption /
    hhsize_cube)) rather than recomputing from raw, which avoids any NaN
    from an unfiltered hhsize_cube."""
    mask = (data[traj_var] == dT_code) & (data[choice_var] == 1)
    return float(data.loc[mask, "lndepvar"].mean())


def run_cell(short: str, inputs_dir, data_dir) -> CellResult:
    """Compute the E1 aggregate and its joint-CI image for one cell."""
    cfg = CELLS[short]
    phi_grid = np.linspace(*cfg["phi"])
    beta_grid = np.linspace(*BETA_GRID_SPEC)

    df, controls = prepare_data(cfg["file_stem"], data_dir)
    n_obs = len(df)
    n_pids = int(df["pid"].nunique())

    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    K = len(kept)
    base = BASE_TRAJECTORY if BASE_TRAJECTORY in kept else kept[0]

    fit = fit_auxiliary_ols(
        df, outcome="lndepvar", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=kept, controls=controls,
    )

    ci = build_joint_ci_grid(
        fit=fit, switchers_kept=kept, base=base,
        phi_grid=phi_grid, beta_grid=beta_grid, type_one=TYPE_ONE,
    )
    accept = ci["accept"]
    n_accept = int(accept.sum())

    phi_marg = accept.any(axis=1)
    beta_marg = accept.any(axis=0)
    marginal_phi = (
        (float(phi_grid[phi_marg][0]), float(phi_grid[phi_marg][-1]))
        if phi_marg.any() else None
    )
    marginal_beta = (
        (float(beta_grid[beta_marg][0]), float(beta_grid[beta_marg][-1]))
        if beta_marg.any() else None
    )

    inp = load_cell_inputs(short, inputs_dir)
    traj_df = inp["trajectory"]
    scalars = inp["scalars"]
    mu_dN = float(traj_df.loc[traj_df["traj_for_agg"] == 1, "mu_d"].iloc[0])
    mu_base = float(traj_df.loc[traj_df["traj_for_agg"] == base, "mu_d"].iloc[0])
    max_traj = int(traj_df["traj_for_agg"].max())
    alpha_dT_obs = compute_alpha_dT_obs(
        df, "trajectory", "choice", max_traj
    )

    pi_arr = traj_df["pi_d"].to_numpy()
    dbar_arr = traj_df["dbar_d"].to_numpy()
    delta_arr_base = traj_df["delta_d_unrestricted"].to_numpy()
    is_dN = traj_df["traj_for_agg"].to_numpy() == 1
    is_dT = traj_df["traj_for_agg"].to_numpy() == max_traj
    is_lumped = traj_df["traj_for_agg"].to_numpy() == -1
    unb_choice_hat = scalars.get("unb_choice_hat", 0.0)

    # Guard: every trajectory is either overwritten below (dN/dT via LCA,
    # lumped via unb_choice_hat) or must already carry a finite non-parametric
    # delta. delta_at starts from a plain copy, so a NaN delta on a
    # non-overwritten row would be carried into the aggregate (nansum treats it
    # as zero), silently corrupting the gap. Fail loudly here instead.
    covered = is_dN | is_dT | is_lumped | ~np.isnan(delta_arr_base)
    if not covered.all():
        bad = traj_df.loc[~covered, "traj_for_agg"].tolist()
        raise ValueError(
            f"{short}: trajectories {bad} have a NaN delta and are not covered "
            f"by the dN/dT/lumped overwrites; refusing to treat them as zero."
        )
    if not (np.isfinite(mu_dN) and np.isfinite(mu_base)):
        raise ValueError(
            f"{short}: non-finite mu_dN={mu_dN} or mu_base={mu_base}; "
            f"check the {short}_e1_mu_d.csv merge."
        )

    def delta_at(phi: float, beta: float) -> np.ndarray:
        out = delta_arr_base.astype(float).copy()
        out = np.where(is_lumped, unb_choice_hat, out)
        out = np.where(is_dN, lca_delta_dN(phi, beta, mu_dN, mu_base), out)
        out = np.where(is_dT, lca_delta_dT(phi, beta, alpha_dT_obs, mu_base), out)
        return out

    wms_full: list[float] = []
    wmm_full: list[float] = []
    wms_p3: list[float] = []
    wmm_p3: list[float] = []
    crosses_boundary = False
    # The with-d_T aggregate hits inf-inf near the phi = -1 pole (lca_delta_dT
    # diverges); those points become NaN and are dropped by the finite mask in
    # project_image_intervals. Silence the expected non-finite arithmetic.
    with np.errstate(invalid="ignore", over="ignore"):
        for (i, j) in np.argwhere(accept):
            phi = float(ci["phi_grid"][i])
            beta = float(ci["beta_grid"][j])
            if phi <= -1.0:
                crosses_boundary = True
            try:
                dv = delta_at(phi, beta)
                dv_p3 = dv.copy()
                dv_p3[is_dT] = 0.0
                r_full = evaluate_aggregate(
                    delta_d=dv, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None
                )
                r_p3 = evaluate_aggregate(
                    delta_d=dv_p3, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None
                )
                wms_full.append(r_full.w_obs_minus_zero)
                wmm_full.append(r_full.w_opt_minus_obs)
                wms_p3.append(r_p3.w_obs_minus_zero)
                wmm_p3.append(r_p3.w_opt_minus_obs)
            except (ValueError, FloatingPointError):
                wms_full.append(float("nan"))
                wmm_full.append(float("nan"))
                wms_p3.append(float("nan"))
                wmm_p3.append(float("nan"))

    proj_wmm_full = project_image_intervals(np.array(wmm_full))
    proj_wms_full = project_image_intervals(np.array(wms_full))
    proj_wmm_p3 = project_image_intervals(np.array(wmm_p3))
    proj_wms_p3 = project_image_intervals(np.array(wms_p3))

    phi_hat = scalars["phi_hat"]
    beta_hat = scalars["beta_hat"]
    dv_hat = delta_at(phi_hat, beta_hat).copy()
    dv_hat[is_dT] = 0.0
    r_hat = evaluate_aggregate(
        delta_d=dv_hat, pi_d=pi_arr, dbar_d=dbar_arr, traj_labels=None
    )

    return CellResult(
        short=short, n_obs=n_obs, n_pids=n_pids, K=K, base=base,
        n_accept=n_accept, n_total=int(accept.size),
        crosses_boundary=crosses_boundary,
        marginal_phi=marginal_phi, marginal_beta=marginal_beta,
        hull_wmm_p3=proj_wmm_p3["convex_hull"],
        hull_wms_p3=proj_wms_p3["convex_hull"],
        hull_wmm_full=proj_wmm_full["convex_hull"],
        hull_wms_full=proj_wms_full["convex_hull"],
        point_wmm_p3=r_hat.w_opt_minus_obs,
        point_wms_p3=r_hat.w_obs_minus_zero,
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
    """Population-weighted national CHN aggregate via interval arithmetic.

    With non-negative weights the bounds are monotone in the inputs, so
    the combined hull is the weighted sum of the per-cell hulls.
    """
    def comb(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
        return (w_rf * a[0] + w_uf * b[0], w_rf * a[1] + w_uf * b[1])

    return {
        "short": "CHN_national",
        "hull_wmm_p3": comb(rf.hull_wmm_p3, uf.hull_wmm_p3),
        "hull_wms_p3": comb(rf.hull_wms_p3, uf.hull_wms_p3),
        "point_wmm_p3": w_rf * rf.point_wmm_p3 + w_uf * uf.point_wmm_p3,
        "point_wms_p3": w_rf * rf.point_wms_p3 + w_uf * uf.point_wms_p3,
        "w_rf": w_rf, "w_uf": w_uf,
    }


def hukou_bound_point(pi_rh: float, pi_dN_rh: float, delta_dN_rh: float) -> float:
    """E2 lower bound: pi_rh * pi_dN_rh * Delta_dN_rh (log per-capita consumption)."""
    return float(pi_rh * pi_dN_rh * delta_dN_rh)


def run_hukou_bound(inputs_dir, data_dir, weights: dict) -> HukouBoundResult:
    """E2 hukou-wedge lower bound for the rural-hukou regime.

    Scales the rural-hukou never-migrant return Delta_dN_rh (already estimated
    by the weak-ID-robust inversion and stored on the CHN_rf ster, exported in
    the scalars CSV as inv_dN and inv_dN_ci95_{lo,hi}) by the fixed constant
    pi_rh * pi_dN_rh. pi_rh is the conditional rural-hukou share of the
    defined-hukou CHN sample (the same base the E1 national figure uses);
    pi_dN_rh is the never-migrant share within the rural-hukou subsample.

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

    # inv_dN and inv_dN_ci95_{{lo,hi}} must be the CHN_rf-cell-specific
    # never-migrant inversion CI (not pooled CHN); _export_e1_inputs_hukou.do writes them.
    for _key in ("inv_dN", "inv_dN_ci95_lo", "inv_dN_ci95_hi"):
        if _key not in scalars:
            raise KeyError(
                f"CHN_rf: required scalar '{_key}' not found in CHN_rf_e1_scalars.csv"
            )
    delta_point = float(scalars["inv_dN"])
    delta_lo = float(scalars["inv_dN_ci95_lo"])
    delta_hi = float(scalars["inv_dN_ci95_hi"])
    if not all(np.isfinite([delta_point, delta_lo, delta_hi])):
        raise ValueError(
            f"CHN_rf: non-finite inv_dN scalars (point={delta_point}, "
            f"lo={delta_lo}, hi={delta_hi}); check the CHN_rf_e1_scalars.csv export."
        )
    if delta_lo > delta_hi:
        raise ValueError(
            f"CHN_rf: inv_dN CI endpoints out of order: lo={delta_lo} > hi={delta_hi}"
        )

    const = pi_rh * pi_dN_rh
    return HukouBoundResult(
        pi_rh=pi_rh,
        pi_dN_rh=pi_dN_rh,
        const=const,
        delta_dN_rh_point=delta_point,
        delta_dN_rh_ci=(delta_lo, delta_hi),
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


def _rows_for_cell(short: str, hull_wmm_p3, hull_wms_p3, point_wmm_p3,
                   point_wms_p3, hull_wmm_full=None, hull_wms_full=None) -> list[dict]:
    """Emit one row per (quantity, version) for the results CSV.

    Values are stored at full precision in log points and as percent
    (geometric-mean change, exp(x) - 1). point is the GMM-point estimate;
    NaN where a point is not defined (the with-d_T near-pole case).
    """
    def row(quantity, version, lo, hi, point):
        return {
            "cell": short, "quantity": quantity, "version": version,
            "ci_lo_log": lo, "ci_hi_log": hi, "point_log": point,
            "ci_lo_pct": log_to_pct(lo) * 100.0,
            "ci_hi_pct": log_to_pct(hi) * 100.0,
            "point_pct": log_to_pct(point) * 100.0 if np.isfinite(point) else float("nan"),
        }

    rows = [
        row("misallocation", "p3", hull_wmm_p3[0], hull_wmm_p3[1], point_wmm_p3),
        row("value_migration", "p3", hull_wms_p3[0], hull_wms_p3[1], point_wms_p3),
    ]
    if hull_wmm_full is not None:
        rows.append(row("misallocation", "with_dT",
                        hull_wmm_full[0], hull_wmm_full[1], float("nan")))
        rows.append(row("value_migration", "with_dT",
                        hull_wms_full[0], hull_wms_full[1], float("nan")))
    return rows


def _result_row(cell, quantity, version, lo, hi, point) -> dict:
    """One long-format result row in the persisted schema (log + percent)."""
    return {
        "cell": cell, "quantity": quantity, "version": version,
        "ci_lo_log": lo, "ci_hi_log": hi, "point_log": point,
        "ci_lo_pct": log_to_pct(lo) * 100.0,
        "ci_hi_pct": log_to_pct(hi) * 100.0,
        "point_pct": log_to_pct(point) * 100.0 if np.isfinite(point) else float("nan"),
    }


def _hukou_bound_rows(hb: HukouBoundResult) -> list[dict]:
    """E2 rows: the economy-wide bound and the per-never-migrant return."""
    return [
        _result_row("CHN_hukou_bound", "hukou_consumption_gain", "bound",
                    hb.hull_bound[0], hb.hull_bound[1], hb.point_bound),
        _result_row("CHN_hukou_bound", "delta_dN_rural_hukou", "inversion",
                    hb.delta_dN_rh_ci[0], hb.delta_dN_rh_ci[1], hb.delta_dN_rh_point),
    ]


def results_dataframe(res: dict) -> pd.DataFrame:
    """Flatten run_all_cells output into the persisted long-format table."""
    rows: list[dict] = []
    for short, c in res["cells"].items():
        rows.extend(_rows_for_cell(
            short, c.hull_wmm_p3, c.hull_wms_p3, c.point_wmm_p3, c.point_wms_p3,
            c.hull_wmm_full, c.hull_wms_full,
        ))
    nat = res["national"]
    rows.extend(_rows_for_cell(
        "CHN_national", nat["hull_wmm_p3"], nat["hull_wms_p3"],
        nat["point_wmm_p3"], nat["point_wms_p3"],
    ))
    if "hukou_bound" in res:
        rows.extend(_hukou_bound_rows(res["hukou_bound"]))
    return pd.DataFrame(rows).sort_values(["cell", "quantity", "version"]).reset_index(drop=True)


def _fmt_interval(lo_pct: float, hi_pct: float) -> str:
    return f"$[{lo_pct:+.1f}\\%, {hi_pct:+.1f}\\%]$"


def write_latex_table(res: dict, table_path) -> None:
    """Write the paper-facing E1 table (P3 convex-hull intervals).

    Self-contained float so the paper can \\input it directly. The headline
    is the P3 misallocation gap interval and the (point) value of observed
    migration per cell.
    """
    def cell_pcts(short):
        if short == "CHN_national":
            nat = res["national"]
            return (nat["hull_wmm_p3"], nat["point_wms_p3"])
        c = res["cells"][short]
        return (c.hull_wmm_p3, c.point_wms_p3)

    lines = [
        r"\begin{table}[htbp]",
        r"\centering",
        r"\caption{Counterfactual misallocation accounting, by country.}",
        r"\label{tab:counterfactual_misallocation}",
        r"\begin{tabular}{lcc}",
        r"\toprule",
        r" & Misallocation gap & Value of observed \\",
        r" & (95\% CI) & migration \\",
        r"\midrule",
    ]
    for short in _TABLE_ORDER:
        hull_wmm, pt_wms = cell_pcts(short)
        if not (np.isfinite(hull_wmm[0]) and np.isfinite(hull_wmm[1])
                and np.isfinite(pt_wms)):
            raise ValueError(
                f"write_latex_table: non-finite values for {short}: "
                f"hull={hull_wmm}, value={pt_wms}"
            )
        interval = _fmt_interval(log_to_pct(hull_wmm[0]) * 100.0,
                                 log_to_pct(hull_wmm[1]) * 100.0)
        value = f"${log_to_pct(pt_wms) * 100.0:+.1f}\\%$"
        lines.append(f"{_LABELS[short]} & {interval} & {value} \\\\")
    lines += [r"\bottomrule", r"\end{tabular}", r"\end{table}", ""]

    table_path = Path(table_path)
    table_path.parent.mkdir(parents=True, exist_ok=True)
    table_path.write_text("\n".join(lines), encoding="utf-8")


def write_hukou_bound_table(res: dict, table_path) -> None:
    """Write the paper-facing E2 hukou-bound table (rural-hukou regime).

    Self-contained float, parallel to write_latex_table: caption, label, and
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
        diff = np.abs(a - b)
        bad = (~both_nan) & ~(diff <= atol_log)
        for idx in np.argwhere(bad).ravel():
            r = merged.iloc[idx]
            problems.append(
                f"  {r['cell']}/{r['quantity']}/{r['version']} {col}: "
                f"new={a[idx]:+.6f} base={b[idx]:+.6f} |diff|={diff[idx]:.6f}"
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
    table_path: str,
    table_path_hukou: str | None = None,
    baseline_path: str | None = None,
    regenerate_baseline: bool = False,
    atol_log: float = 1e-3,
) -> None:
    """Stata-facing entry point (called from 12_counterfactuals.do).

    Runs all E1 cells plus the E2 hukou bound, writes the persisted results
    CSV and the paper tables (E1 misallocation and, if ``table_path_hukou`` is
    given, the E2 hukou bound), and self-checks against the committed baseline
    snapshot. Mirrors the role of lca_inversion.attach_inversion_for_stata for
    the inversion step.
    """
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    results_csv = out_dir / "counterfactual_results.csv"
    if baseline_path is None:
        baseline_path = out_dir / "counterfactual_results_baseline.csv"

    res = run_all_cells(inputs_dir, data_dir)
    df = results_dataframe(res)
    df.to_csv(results_csv, index=False)
    print(f"  wrote results: {results_csv}")

    if regenerate_baseline:
        df.to_csv(baseline_path, index=False)
        print(f"  wrote baseline snapshot: {baseline_path}")
    else:
        _self_check(df, baseline_path, atol_log=atol_log)
        print(f"  self-check passed against {baseline_path}")

    write_latex_table(res, table_path)
    print(f"  wrote table: {table_path}")

    if table_path_hukou is not None:
        write_hukou_bound_table(res, table_path_hukou)
        print(f"  wrote table: {table_path_hukou}")

    # Headline echo for the Stata log.
    for short in _TABLE_ORDER:
        if short == "CHN_national":
            hull, pt = res["national"]["hull_wmm_p3"], res["national"]["point_wms_p3"]
        else:
            c = res["cells"][short]
            hull, pt = c.hull_wmm_p3, c.point_wms_p3
        print(f"  {short:14s} misallocation P3 "
              f"[{log_to_pct(hull[0]) * 100:+.2f}%, {log_to_pct(hull[1]) * 100:+.2f}%]"
              f"   value {log_to_pct(pt) * 100:+.2f}%")

    hb = res["hukou_bound"]
    print(f"  E2 hukou bound: pi_rh={hb.pi_rh:.4f} pi_dN_rh={hb.pi_dN_rh:.4f} "
          f"const={hb.const:.4f}")
    print(f"  E2 Delta_dN_rh          "
          f"[{log_to_pct(hb.delta_dN_rh_ci[0]) * 100:+.2f}%, "
          f"{log_to_pct(hb.delta_dN_rh_ci[1]) * 100:+.2f}%]"
          f"   point {log_to_pct(hb.delta_dN_rh_point) * 100:+.2f}%")
    print(f"  E2 economy-wide gain    "
          f"[{log_to_pct(hb.hull_bound[0]) * 100:+.2f}%, "
          f"{log_to_pct(hb.hull_bound[1]) * 100:+.2f}%]"
          f"   point {log_to_pct(hb.point_bound) * 100:+.2f}%"
          f"   (floor_positive={hb.floor_positive})")
