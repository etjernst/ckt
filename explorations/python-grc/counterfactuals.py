"""Counterfactual aggregates for E1 (misallocation) and E2 (hukou wedge).

Module-level functions implement the deterministic aggregate evaluator
and the (eventual) inversion-CI grid construction. The point-estimate
evaluator runs on raw trajectory-level objects exported from Stata;
the joint-CI version (planned) reuses the auxiliary-OLS machinery in
``lca_inversion.py``.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np


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
