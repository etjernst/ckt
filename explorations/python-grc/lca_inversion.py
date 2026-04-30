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


def grid_md_inversion(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    phi_grid: np.ndarray,
    type_one: float = 0.05,
) -> tuple[pd.DataFrame, float, float]:
    """Minimum-distance LCA inversion with beta concentrated out.

    At each phi, build the moment vector
        m_s(phi; beta) = beta_s - beta - phi * (alpha_s - alpha_base)
    for every kept switcher s in S (including the base, where the
    alpha_s - alpha_base term is identically zero). Concentrate out
    beta via GLS on V_m, then invert the |S|-1 chi^2 Wald.

    Differs from ``grid_lca_inversion`` in two ways. First, the LCA
    intercept beta is a free parameter, estimated efficiently across
    all switchers, instead of being pinned to ``beta_base`` (which
    just-identifies on the single base switcher). Second, the moment
    vector includes the base equation ``m_base = beta_base - beta``,
    which carries information about beta's level. Concentrating out
    beta leaves the same |S|-1 = J_R degrees of freedom, but the test
    is at least as efficient under LCA (Chamberlain 1982; Newey and
    McFadden 1994, Handbook ch. 36).

    Returns
    -------
    curve : DataFrame with columns ``phi``, ``beta_md`` (the
        concentrated-out estimate at this phi), ``wald``, ``p_value``.
    ci_low, ci_high : convex hull of grid points where p_value >=
        ``type_one``. Multimodal CI handling via ``find_islands``.

    The chi^2 dof matches ``grid_lca_inversion`` (J_R = len(switchers_kept) - 1).
    """
    if base not in switchers_kept:
        raise ValueError(
            f"base trajectory {base} not in switchers_kept {list(switchers_kept)}"
        )
    sw = list(switchers_kept)
    K = len(sw)
    J_R = K - 1
    if J_R == 0:
        raise ValueError(
            "Need at least one non-base switcher for the MD inversion"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])

    # u_s = beta_s_OLS, d_s = alpha_s_OLS - alpha_base_OLS
    # (d is 0 at the base row by construction)
    u = fit.b[s_beta]
    d = fit.b[s_alpha] - fit.b[base_alpha]

    rows = []
    ones = np.ones(K)
    for phi in phi_grid:
        # Jacobian of m wrt theta_OLS, K x p, depends on phi.
        # m_s = beta_s_OLS - beta - phi*(alpha_s_OLS - alpha_base_OLS)
        # so dm_s/dbeta_t_OLS = 1 if t==s else 0
        #    dm_s/dalpha_t_OLS = -phi if t==s and s!=base
        #                     = +phi if t==base and s!=base
        #                     = 0    if s==base or t not in {s, base}
        J = np.zeros((K, p))
        for k in range(K):
            J[k, s_beta[k]] = 1.0
            if not is_base[k]:
                J[k, s_alpha[k]] = -phi
                J[k, base_alpha] = +phi
        V_m = J @ fit.V @ J.T
        # Same pinv tolerance as grid_lca_inversion for consistency.
        W = np.linalg.pinv(V_m, rcond=1e-10)
        c = u - phi * d
        # Concentrated GLS: beta_md(phi) = (1' W c) / (1' W 1).
        denom = float(ones @ W @ ones)
        beta_md = float((ones @ W @ c) / denom)
        m = c - beta_md * ones
        wald = float(m @ W @ m)
        p_value = float(1.0 - chi2.cdf(wald, df=J_R))
        rows.append((float(phi), beta_md, wald, p_value))

    curve = pd.DataFrame(rows, columns=["phi", "beta_md", "wald", "p_value"])
    accepted = curve.loc[curve["p_value"] >= type_one, "phi"]
    if len(accepted) == 0:
        return curve, float("nan"), float("nan")
    return curve, float(accepted.min()), float(accepted.max())


def _md_constrained_wald(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    phi: float,
    delta_target: float,
    c1: float,
) -> float:
    """Minimum-distance Wald at fixed phi under a linear constraint
    delta_target = beta + phi * c1, i.e., beta = delta_target - phi * c1.

    Used internally by ``grid_delta_never_md_inversion`` and
    ``grid_delta_avg_md_inversion``. ``c1`` is the trajectory-mean
    deviation appropriate to the parameter being inverted:
        Delta_never:  c1 = alpha_never - alpha_base
        Delta_avg:    c1 = sum_s pi_s (alpha_s - alpha_base) (within-switcher)
    """
    sw = list(switchers_kept)
    K = len(sw)
    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])

    # m_s(delta, phi) = beta_s_OLS - delta + phi*(c1 - (alpha_s - alpha_base))
    #                 = beta_s_OLS - delta + phi*c1 - phi*d_s   (s != base)
    # for s = base: alpha_s - alpha_base = 0, so
    #     m_base = beta_base_OLS - delta + phi*c1
    # The c1 enters via the substitution beta = delta - phi*c1.
    # Jacobian wrt theta_OLS depends on whether c1 is a function of
    # the OLS coefficients (yes for never; yes via pi_s for avg).
    # For both never (c1 = a_never - a_base) and avg (c1 = sum_s pi_s
    # (a_s - a_base)), c1 is linear in alpha-coefficients, so the
    # Jacobian for that term must be added.

    # Build dc1/dtheta as a length-p vector. Caller sets it via the
    # closure below; here we just take c1 numerically and incorporate
    # its dependence through the closure-supplied jac_c1 if needed.
    raise NotImplementedError("Use the dedicated functions instead.")


def grid_delta_never_md_inversion(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    never_traj: int,
    delta_grid: np.ndarray,
    phi_search_grid: np.ndarray,
    type_one: float = 0.05,
) -> tuple[pd.DataFrame, float, float]:
    """Inversion CI for Delta_never via constrained minimum distance.

    At each candidate delta*, the LCA constraint
        delta* = beta + phi * (alpha_never - alpha_base)
    pins beta in terms of phi. Substitute into the moment vector
        m_s = beta_s - beta - phi*(alpha_s - alpha_base)
    and minimize the MD Wald over phi (search grid). Profiled Wald
    has chi^2_{|S|-1} asymptotic distribution under H0.

    Returns
    -------
    curve : DataFrame with columns ``delta``, ``phi_at_min`` (the
        nuisance phi minimizer at this delta), ``wald``, ``p_value``.
    ci_low, ci_high : convex hull of grid points where p_value >=
        ``type_one``.
    """
    sw = list(switchers_kept)
    K = len(sw)
    J_R = K - 1
    if J_R == 0:
        raise ValueError(
            "Need at least one non-base switcher for the MD inversion"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    never_alpha = fit.idx(f"alpha[{never_traj}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])

    rows = []
    for delta_star in delta_grid:
        wald_at_phi = np.empty(len(phi_search_grid))
        for j, phi in enumerate(phi_search_grid):
            # Jacobian of m wrt theta_OLS at this phi, with the
            # constraint beta = delta_star - phi*(alpha_never - alpha_base)
            # substituted in. m_s = beta_s_OLS - delta_star
            #     + phi*(alpha_never_OLS - alpha_base_OLS)
            #     - phi*(alpha_s_OLS - alpha_base_OLS)
            # For s != base:
            #   dm_s/dbeta_s = 1
            #   dm_s/dalpha_never = +phi
            #   dm_s/dalpha_s = -phi
            #   dm_s/dalpha_base = 0  (cancels)
            # For s == base:
            #   dm_base/dbeta_base = 1
            #   dm_base/dalpha_never = +phi
            #   dm_base/dalpha_base = -phi
            J = np.zeros((K, p))
            for k in range(K):
                J[k, s_beta[k]] = 1.0
                J[k, never_alpha] = +phi
                if not is_base[k]:
                    J[k, s_alpha[k]] = -phi
                else:
                    J[k, base_alpha] = -phi
            V_m = J @ fit.V @ J.T
            W = np.linalg.pinv(V_m, rcond=1e-10)

            # m at this (delta_star, phi)
            beta_s = fit.b[s_beta]
            d_s = fit.b[s_alpha] - fit.b[base_alpha]
            c1_val = fit.b[never_alpha] - fit.b[base_alpha]
            m = beta_s - delta_star + phi * c1_val - phi * d_s
            wald_at_phi[j] = float(m @ W @ m)
        j_star = int(np.argmin(wald_at_phi))
        wald_min = float(wald_at_phi[j_star])
        phi_min = float(phi_search_grid[j_star])
        p_value = float(1.0 - chi2.cdf(wald_min, df=J_R))
        rows.append((float(delta_star), phi_min, wald_min, p_value))

    curve = pd.DataFrame(
        rows, columns=["delta", "phi_at_min", "wald", "p_value"]
    )
    accepted = curve.loc[curve["p_value"] >= type_one, "delta"]
    if len(accepted) == 0:
        return curve, float("nan"), float("nan")
    return curve, float(accepted.min()), float(accepted.max())


def grid_delta_avg_md_inversion(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    pi_within: dict[int, float],
    delta_grid: np.ndarray,
    phi_search_grid: np.ndarray,
    type_one: float = 0.05,
) -> tuple[pd.DataFrame, float, float]:
    """Inversion CI for Delta_avg via constrained MD.

    Same structure as ``grid_delta_never_md_inversion`` but with
        c1 = sum_s pi_within[s] * (alpha_s - alpha_base)
    where ``pi_within`` are within-switcher trajectory shares
    (sum to 1 across ``switchers_kept``).

    The Jacobian of c1 wrt theta_OLS has dc1/dalpha_s = pi_s (for
    each switcher s), which propagates into the moment Jacobian
    through the +phi*c1 term. After algebra, alpha_base cancels in
    m_s for s != base via Sum pi_s = 1.
    """
    sw = list(switchers_kept)
    K = len(sw)
    J_R = K - 1
    if J_R == 0:
        raise ValueError(
            "Need at least one non-base switcher for the MD inversion"
        )
    if not np.isclose(sum(pi_within[s] for s in sw), 1.0, atol=1e-9):
        raise ValueError(
            f"pi_within must sum to 1 across switchers_kept; "
            f"got sum={sum(pi_within[s] for s in sw)}"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha_idx = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta_idx = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])
    pi_arr = np.array([pi_within[s] for s in sw])

    # c1_val at OLS estimates (constant across delta and phi):
    a_s = fit.b[s_alpha_idx]
    a_base_val = fit.b[base_alpha]
    d_s = a_s - a_base_val
    c1_val = float(np.sum(pi_arr * d_s))
    beta_s_OLS = fit.b[s_beta_idx]

    rows = []
    for delta_star in delta_grid:
        wald_at_phi = np.empty(len(phi_search_grid))
        for j, phi in enumerate(phi_search_grid):
            # m_s = beta_s_OLS - delta* + phi*c1 - phi*(alpha_s - alpha_base)
            #     = beta_s_OLS - delta* + phi*sum_t pi_t (alpha_t - alpha_base)
            #       - phi*(alpha_s - alpha_base)
            # After expansion (using sum pi_t = 1), alpha_base cancels for
            # s != base; only alpha_t (t in switchers) and alpha_s remain.
            #
            # Jacobian for s != base:
            #   dm_s/dbeta_s = 1
            #   dm_s/dalpha_t (t in sw, t != s) = phi*pi_t
            #   dm_s/dalpha_s = phi*pi_s - phi = -phi*(1 - pi_s)
            #   dm_s/dalpha_base = 0
            # Jacobian for s == base:
            #   dm_base/dbeta_base = 1
            #   dm_base/dalpha_t (t in sw, t != base) = phi*pi_t
            #   dm_base/dalpha_base = phi*pi_base - phi = -phi*(1 - pi_base)
            J = np.zeros((K, p))
            for k in range(K):
                J[k, s_beta_idx[k]] = 1.0
                # cross-switcher pi_t entries
                for t_idx, idx in enumerate(s_alpha_idx):
                    J[k, idx] += phi * pi_arr[t_idx]
                # subtract phi from this row's own alpha
                J[k, s_alpha_idx[k]] -= phi
            V_m = J @ fit.V @ J.T
            W = np.linalg.pinv(V_m, rcond=1e-10)

            m = beta_s_OLS - delta_star + phi * c1_val - phi * d_s
            wald_at_phi[j] = float(m @ W @ m)
        j_star = int(np.argmin(wald_at_phi))
        wald_min = float(wald_at_phi[j_star])
        phi_min = float(phi_search_grid[j_star])
        p_value = float(1.0 - chi2.cdf(wald_min, df=J_R))
        rows.append((float(delta_star), phi_min, wald_min, p_value))

    curve = pd.DataFrame(
        rows, columns=["delta", "phi_at_min", "wald", "p_value"]
    )
    accepted = curve.loc[curve["p_value"] >= type_one, "delta"]
    if len(accepted) == 0:
        return curve, float("nan"), float("nan")
    return curve, float(accepted.min()), float(accepted.max())


def grid_delta_always_md_inversion(
    fit: AuxiliaryFit,
    switchers_kept: Sequence[int],
    base: int,
    always_traj: int,
    delta_grid: np.ndarray,
    phi_search_grid: np.ndarray,
    type_one: float = 0.05,
) -> tuple[pd.DataFrame, float, float]:
    """Inversion CI for Delta_always via constrained MD (Mobius case).

    The LCA constraint for always-movers is
        delta* = (beta + phi*(alpha_always - alpha_base)) / (1 + phi)
    which gives beta = delta*(1+phi) - phi*c1 where
    c1 = alpha_always - alpha_base. Substituting into the moment vector:

        m_s = beta_s - delta*(1+phi) + phi*alpha_always - phi*alpha_s
              (s != base)
        m_base = beta_base - delta*(1+phi) + phi*alpha_always - phi*alpha_base

    The Jacobian wrt theta_OLS has the same shape as the Delta_never
    case (substitute always_traj for never_traj). The chi^2_{|S|-1}
    Wald is profiled over phi at each delta*, then inverted.

    Reports the multi-island CI honestly when the phi-CI crosses
    -1 (the Mobius singularity); ``find_islands`` on the curve
    handles separating the union.
    """
    sw = list(switchers_kept)
    K = len(sw)
    J_R = K - 1
    if J_R == 0:
        raise ValueError(
            "Need at least one non-base switcher for the MD inversion"
        )

    p = len(fit.b)
    base_alpha = fit.idx(f"alpha[{base}]")
    always_alpha = fit.idx(f"alpha[{always_traj}]")
    s_alpha_idx = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta_idx = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])

    a_base_val = fit.b[base_alpha]
    a_always_val = fit.b[always_alpha]
    c1_val = float(a_always_val - a_base_val)
    beta_s_OLS = fit.b[s_beta_idx]
    d_s = fit.b[s_alpha_idx] - a_base_val

    rows = []
    for delta_star in delta_grid:
        wald_at_phi = np.empty(len(phi_search_grid))
        for j, phi in enumerate(phi_search_grid):
            # For s != base: m_s = beta_s - delta*(1+phi) + phi*alpha_always
            #                       - phi*alpha_s
            #   dm_s/dbeta_s = 1
            #   dm_s/dalpha_always = +phi
            #   dm_s/dalpha_s = -phi
            # For s == base: m_base = beta_base - delta*(1+phi) +
            #                          phi*alpha_always - phi*alpha_base
            #   dm_base/dbeta_base = 1
            #   dm_base/dalpha_always = +phi
            #   dm_base/dalpha_base = -phi
            J = np.zeros((K, p))
            for k in range(K):
                J[k, s_beta_idx[k]] = 1.0
                J[k, always_alpha] = +phi
                if not is_base[k]:
                    J[k, s_alpha_idx[k]] = -phi
                else:
                    J[k, base_alpha] = -phi
            V_m = J @ fit.V @ J.T
            W = np.linalg.pinv(V_m, rcond=1e-10)

            m = (beta_s_OLS - delta_star * (1.0 + phi)
                 + phi * c1_val - phi * d_s)
            # For s != base, the c1 - d_s simplification holds; for
            # s == base, d_base = 0, so m_base = beta_base
            #   - delta*(1+phi) + phi*c1.
            wald_at_phi[j] = float(m @ W @ m)
        j_star = int(np.argmin(wald_at_phi))
        wald_min = float(wald_at_phi[j_star])
        phi_min = float(phi_search_grid[j_star])
        p_value = float(1.0 - chi2.cdf(wald_min, df=J_R))
        rows.append((float(delta_star), phi_min, wald_min, p_value))

    curve = pd.DataFrame(
        rows, columns=["delta", "phi_at_min", "wald", "p_value"]
    )
    accepted = curve.loc[curve["p_value"] >= type_one, "delta"]
    if len(accepted) == 0:
        return curve, float("nan"), float("nan")
    # Convex hull. Use ``find_islands`` separately for multi-island CI.
    return curve, float(accepted.min()), float(accepted.max())


def find_islands(
    curve: pd.DataFrame,
    type_one: float = 0.05,
    x: str = "phi",
) -> list[tuple[float, float]]:
    """Walk the (``x``, p_value) grid and return non-rejected regions
    as a list of ``(x_lo, x_hi)`` intervals.

    With one island the result matches the convex-hull CI returned by
    ``grid_lca_inversion`` / ``grid_md_inversion`` /
    ``grid_delta_*_md_inversion``. With multiple islands the convex
    hull would overstate coverage, so the paper should report each
    island separately. The ``x`` column defaults to ``phi`` for the
    LCA inversions; pass ``x="delta"`` for the trajectory-specific
    delta inversion curves.

    Returns an empty list if no grid point is accepted at level
    ``type_one``.
    """
    df = curve.sort_values(x).reset_index(drop=True)
    accept = (df["p_value"].values >= type_one).astype(int)
    if not accept.any():
        return []
    # Pad with zeros at both ends so np.diff catches edge runs.
    diffs = np.diff(np.concatenate([[0], accept, [0]]))
    starts = np.where(diffs == 1)[0]
    ends = np.where(diffs == -1)[0] - 1
    return [(float(df[x].iloc[s]), float(df[x].iloc[e]))
            for s, e in zip(starts, ends)]


def format_islands(
    islands: list[tuple[float, float]],
    grid_bounds: tuple[float, float] | None = None,
    fmt: str = "+.3f",
) -> str:
    r"""Pretty-print a list of islands as a union of intervals.

    If ``grid_bounds`` is supplied and an island touches the lower
    (resp.\ upper) bound, the endpoint is annotated as ``-inf``
    (resp.\ ``+inf``) to flag that the CI extends beyond the grid.
    Use this for the Mobius-singularity case in
    ``grid_delta_always_md_inversion``, where the true CI may be
    unbounded.
    """
    if not islands:
        return "empty"
    parts = []
    lo_bound = hi_bound = None
    if grid_bounds is not None:
        lo_bound, hi_bound = grid_bounds
    for lo, hi in islands:
        lo_str = f"{lo:{fmt}}"
        hi_str = f"{hi:{fmt}}"
        if lo_bound is not None and np.isclose(lo, lo_bound):
            lo_str = "-inf"
        if hi_bound is not None and np.isclose(hi, hi_bound):
            hi_str = "+inf"
        parts.append(f"[{lo_str}, {hi_str}]")
    return " U ".join(parts)


def format_islands_tex(
    islands: list[tuple[float, float]],
    grid_bounds: tuple[float, float] | None = None,
    fmt: str = "+.3f",
) -> str:
    """LaTeX-friendly variant of ``format_islands``.

    Renders endpoints touching the grid as ``$-\\infty$``/``$+\\infty$``
    and joins multi-island unions with ``$\\cup$``. Returned strings are
    safe to embed inside an ``esttab`` ``stats()`` macro that lands in a
    ``.tex`` table cell. Empty CIs render as ``empty``.
    """
    if not islands:
        return "empty"
    parts = []
    lo_bound = hi_bound = None
    if grid_bounds is not None:
        lo_bound, hi_bound = grid_bounds
    for lo, hi in islands:
        lo_str = f"{lo:{fmt}}"
        hi_str = f"{hi:{fmt}}"
        if lo_bound is not None and np.isclose(lo, lo_bound):
            lo_str = r"$-\infty$"
        if hi_bound is not None and np.isclose(hi, hi_bound):
            hi_str = r"$+\infty$"
        parts.append(f"[{lo_str}, {hi_str}]")
    return r" $\cup$ ".join(parts)


def _hull(islands: list[tuple[float, float]]) -> tuple[float, float]:
    """Convex hull of a list of (lo, hi) island tuples.

    Returns ``(nan, nan)`` if the list is empty.
    """
    if not islands:
        return float("nan"), float("nan")
    los = [lo for lo, _ in islands]
    his = [hi for _, hi in islands]
    return float(min(los)), float(max(his))


def compute_all_inversion_cis(
    df: pd.DataFrame,
    outcome: str = "lndepvar",
    trajectory: str = "trajectory",
    choice: str = "choice",
    hhid: str = "pid",
    base: int | None = None,
    controls: Sequence[str] | None = None,
    threshold: int = 5,
    phi_grid: np.ndarray | None = None,
    delta_grid_nv: np.ndarray | None = None,
    delta_grid_al: np.ndarray | None = None,
    unbalanced_col: str = "unbalanced",
    unbalanced_choice_col: str = "unbalanced_choice",
) -> dict:
    """Compute phi and three delta inversion CIs at 90% and 95% in one call.

    Wraps ``drop_sparse_switchers``, ``fit_auxiliary_ols``,
    ``grid_lca_inversion``, ``grid_delta_never_md_inversion``,
    ``grid_delta_avg_md_inversion``, and ``grid_delta_always_md_inversion``
    so the Stata-side ``attach_inversion_ci`` wrapper makes a single
    Python call per (country, spec) cell rather than four.

    Parameters mirror the existing helpers. ``base=None`` auto-selects
    base = 2 if it survives the sparse-switcher pre-drop, else the
    smallest kept switcher (matches ``run_all_countries_inversion.py``).
    Default grids match that runner: phi in ``[-3, 1]`` step 0.01;
    Delta_never / Delta_avg in ``[-1.5, 1.5]`` step 0.01; Delta_always
    in ``[-5, 5]`` step 0.02 (wider for the Mobius case).

    Returns a nested dict keyed by ``phi``, ``delta_never``, ``delta_avg``,
    ``delta_always``. Each leaf carries:

    - ``point``: phi or delta at the Wald minimum.
    - ``ci90``, ``ci95``: convex-hull CI as ``(lo, hi)`` tuple
      (``(nan, nan)`` if empty).
    - ``islands90``, ``islands95``: list of ``(lo, hi)`` accept-region
      intervals at the 10% and 5% type-I error levels.
    - ``ci90_str``, ``ci95_str``: LaTeX-formatted bracketed strings,
      ready for ``esttab`` ``stats()`` consumption.
    - ``grid_bounds``: ``(lo, hi)`` of the grid for that parameter.
    - ``J_R``: degrees of freedom of the joint chi-squared test.
    - ``n_kept``: number of switchers kept after threshold filtering.
    """
    if phi_grid is None:
        phi_grid = np.arange(-3.0, 1.0001, 0.01)
    if delta_grid_nv is None:
        delta_grid_nv = np.arange(-1.5, 1.5001, 0.01)
    if delta_grid_al is None:
        delta_grid_al = np.arange(-5.0, 5.0001, 0.02)

    cols_needed = [outcome, choice, trajectory, hhid,
                   unbalanced_col, unbalanced_choice_col]
    if controls:
        cols_needed = cols_needed + list(controls)
    sub = df.dropna(subset=[c for c in cols_needed if c != trajectory]).copy()

    kept, _counts = drop_sparse_switchers(
        sub, trajectory, choice, hhid, threshold=threshold
    )
    if base is None:
        base = 2 if 2 in kept else (kept[0] if kept else None)
    if base is None or base not in kept:
        raise ValueError(
            f"base {base} not in switchers_kept {kept} after threshold {threshold}"
        )

    trajectories = sorted(int(t) for t in sub[trajectory].dropna().unique())
    never_traj, always_traj = trajectories[0], trajectories[-1]

    fit = fit_auxiliary_ols(
        sub, outcome=outcome, trajectory=trajectory,
        choice=choice, hhid=hhid,
        switchers_kept=kept, controls=controls,
        unbalanced_col=unbalanced_col,
        unbalanced_choice_col=unbalanced_choice_col,
    )

    J_R = len(kept) - 1
    n_kept = len(kept)
    phi_bounds = (float(phi_grid[0]), float(phi_grid[-1]))
    nv_bounds = (float(delta_grid_nv[0]), float(delta_grid_nv[-1]))
    al_bounds = (float(delta_grid_al[0]), float(delta_grid_al[-1]))

    # Run each curve once at type_one=0.05; derive 90% via find_islands at 0.10.
    curve_phi, _ph95_lo, _ph95_hi = grid_lca_inversion(
        fit, kept, base, phi_grid, type_one=0.05
    )
    n_curve, _n95_lo, _n95_hi = grid_delta_never_md_inversion(
        fit, kept, base, never_traj, delta_grid_nv, phi_grid, type_one=0.05
    )

    n_sw = int(sub[trajectory].isin(kept).sum())
    pi_within = {s: float((sub[trajectory] == s).sum()) / n_sw for s in kept}
    a_curve, _a95_lo, _a95_hi = grid_delta_avg_md_inversion(
        fit, kept, base, pi_within, delta_grid_nv, phi_grid, type_one=0.05
    )
    t_curve, _t95_lo, _t95_hi = grid_delta_always_md_inversion(
        fit, kept, base, always_traj, delta_grid_al, phi_grid, type_one=0.05
    )

    def _summarize(curve, x, bounds):
        islands95 = find_islands(curve, type_one=0.05, x=x)
        islands90 = find_islands(curve, type_one=0.10, x=x)
        ci95 = _hull(islands95)
        ci90 = _hull(islands90)
        i_min = int(curve["wald"].idxmin())
        point = float(curve[x].iloc[i_min])
        wald_min = float(curve["wald"].iloc[i_min])
        return {
            "point": point,
            "wald_min": wald_min,
            "ci90": ci90,
            "ci95": ci95,
            "islands90": islands90,
            "islands95": islands95,
            "grid_bounds": bounds,
            "ci90_str": format_islands_tex(islands90, grid_bounds=bounds),
            "ci95_str": format_islands_tex(islands95, grid_bounds=bounds),
            "J_R": J_R,
            "n_kept": n_kept,
        }

    return {
        "phi":          _summarize(curve_phi, "phi",   phi_bounds),
        "delta_never":  _summarize(n_curve,   "delta", nv_bounds),
        "delta_avg":    _summarize(a_curve,   "delta", nv_bounds),
        "delta_always": _summarize(t_curve,   "delta", al_bounds),
    }


def attach_inversion_for_stata(
    outcome: str,
    trajectory: str,
    choice: str,
    hhid: str,
    base: int,
    controls: Sequence[str],
    threshold: int = 5,
    unbalanced_col: str = "unbalanced",
    unbalanced_choice_col: str = "unbalanced_choice",
) -> None:
    """Bridge between Stata's in-program ``python:`` call and
    ``compute_all_inversion_cis``.

    Pulls the in-memory Stata dataset via ``sfi.Data.getAsDict`` (limited
    to columns the inversion needs), runs the four inversions, and
    writes results back as Stata locals via ``sfi.Macro.setLocal``.

    The calling Stata program (``attach_inversion_ci`` in
    ``0_programs.do``) reads those locals and turns them into ``e()``
    scalars and macros via ``ereturn scalar`` / ``ereturn local``.

    This wrapper exists because Stata's in-program ``python:`` runs in
    the ``builtins`` namespace, isolated from file-level ``__main__``,
    so functions defined at the top of the do-file are not visible
    inside a program. Importing ``lca_inversion`` as a module circumvents
    that isolation.
    """
    from sfi import Data, Macro, SFIToolkit

    cols = [outcome, trajectory, choice, hhid,
            unbalanced_col, unbalanced_choice_col]
    cols = cols + [c for c in controls if c not in cols]
    seen: set[str] = set()
    cols = [c for c in cols if not (c in seen or seen.add(c))]

    raw = Data.getAsDict(cols, missingval=float("nan"))
    df = pd.DataFrame(raw)

    # setup_grc_estimation in 0_programs.do recodes trajectory==. to 999
    # for unbalanced observers (so the GMM's switcher_d dummies sum cleanly
    # over balanced rows only). Reverse that so the helper enumerates only
    # real trajectories and matches the Python data_loader path.
    df.loc[df[trajectory] == 999, trajectory] = float("nan")

    out = compute_all_inversion_cis(
        df=df,
        outcome=outcome, trajectory=trajectory,
        choice=choice, hhid=hhid,
        base=base, controls=list(controls),
        threshold=threshold,
        unbalanced_col=unbalanced_col,
        unbalanced_choice_col=unbalanced_choice_col,
    )

    SFIToolkit.displayln(
        f"  attach_inversion_for_stata: J_R={out['phi']['J_R']}, "
        f"n_kept={out['phi']['n_kept']}"
    )

    import math

    def _stata_float(x: float) -> str:
        # Stata's missing-value literal is . (period), not "nan"; otherwise
        # `ereturn scalar foo = nan` errors with r(111) because the parser
        # treats "nan" as a variable name.
        return "." if math.isnan(float(x)) else repr(float(x))

    for key, prefix in [("phi", "inv_phi"),
                         ("delta_never", "inv_dN"),
                         ("delta_avg", "inv_davg"),
                         ("delta_always", "inv_dT")]:
        d = out[key]
        Macro.setLocal(f"{prefix}_at_waldmin", _stata_float(d["point"]))
        Macro.setLocal(f"{prefix}_wald_min",   _stata_float(d["wald_min"]))
        Macro.setLocal(f"{prefix}_J_R",        str(int(d["J_R"])))
        Macro.setLocal(f"{prefix}_n_kept",     str(int(d["n_kept"])))
        for level in (90, 95):
            lo, hi = d[f"ci{level}"]
            Macro.setLocal(f"{prefix}_ci{level}_lo", _stata_float(lo))
            Macro.setLocal(f"{prefix}_ci{level}_hi", _stata_float(hi))
            Macro.setLocal(f"{prefix}_ci{level}_str", d[f"ci{level}_str"])
        Macro.setLocal(f"{prefix}_island_count95",
                       str(int(len(d["islands95"]))))
        Macro.setLocal(f"{prefix}_island_count90",
                       str(int(len(d["islands90"]))))


def summary_curve_stats(curve: pd.DataFrame) -> dict:
    """Diagnostics for an (phi, wald, p_value) curve. Useful when the CI is
    empty: max_p tells how close to non-rejection the data come, and
    phi_at_max_p locates the best-fitting LCA slope under the joint test.
    """
    df = curve.sort_values("phi").reset_index(drop=True)
    i_max = int(df["p_value"].idxmax())
    i_wald_min = int(df["wald"].idxmin())
    return {
        "max_p": float(df["p_value"].iloc[i_max]),
        "phi_at_max_p": float(df["phi"].iloc[i_max]),
        "min_wald": float(df["wald"].iloc[i_wald_min]),
        "phi_at_min_wald": float(df["phi"].iloc[i_wald_min]),
        "n_grid": int(len(df)),
    }
