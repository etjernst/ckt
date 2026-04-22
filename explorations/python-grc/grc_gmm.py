"""Python port of the Stata restricted-GRC two-step GMM estimator.

Mirrors the estimator used in CKT's ``scripts/0_programs.do`` (programs
``run_grc``, ``initial_values``, ``define_switcherpars``). Restricted
group-random-coefficient (GRC) model of Equation ``eq:restricted-GRC``
in ``paper/main.tex`` and Equation ``eq:restricted-grc-unbalanced`` in
``paper/unbalanced_proposition.tex``.

Scope:

* Consumption outcome, urban choice, pooled unbalanced panel.
* Two-step efficient GMM, cluster-robust at individual id.
* Cluster-robust analytic standard errors and Hansen's J-statistic.

Out of scope (on purpose): Monte Carlo, heterogeneity plots, hukou and
experience splits, income specification (which relies on a
``define_switcherpars`` base bug flagged in CLAUDE.md).

Parameter vector layout (as stored in ``self.theta_``)::

    theta = [mu_never,
             mu_{s1}, mu_{s2}, ..., mu_{sS},
             kappa,
             Delta_base,
             phi,
             gamma_1, ..., gamma_K]   # covariates + (pooled) U_i, U_i*D_it

Moment vector ``z_it`` (no constant, matches the instrument list in
``run_grc``)::

    z_it = [ x_it',                          # covariates
             U_i, U_i * D_it,                # if pooled unbalanced
             1{never},
             1{switcher_i = s} for each s,
             D_it,
             1{always} * D_it,
             1{switcher_i = s} * D_it for each s ]

Sample moment: ``g_i(theta) = sum_t z_it * eps_it(theta)`` where
``eps_it = y_it - fit_it(theta)`` and ``fit_it`` is the right-hand side of
the restricted-GRC equation.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Sequence

import numpy as np
import pandas as pd


def _as_ndarray(x) -> np.ndarray:
    return np.asarray(x, dtype=float)


@dataclass
class RestrictedGRC:
    """Two-step efficient GMM estimator for the restricted GRC model.

    Parameters
    ----------
    outcome : column name of the log outcome (e.g. log consumption pc).
    choice : column name of binary urban indicator D_it.
    trajectory : column name of integer trajectory label. Rows with
        missing trajectory (unbalanced observers) are allowed; their
        trajectory indicators are identically zero.
    individual_id : column name for clustering (and id in the moments).
    covariates : list of covariate column names (period dummies, female,
        etc.). Constant is excluded (Stata uses ``nocons``).
    unbalanced_col : column name of U_i. If set, ``U_i`` and ``U_i * D_it``
        are appended to the covariate block (matches ``run_grc`` under
        ``balance == "unb"``).
    base_trajectory : integer label of the baseline switcher d_0. If
        ``None``, chosen by the ``initial_values`` rule (largest |t| on
        the OLS switcher*choice coefficient among switchers with
        ``N_s / T > 5``).
    never_label : integer label for the never-urban trajectory d_N.
        Default 1 (Stata convention: lowest integer after ``encode``).
    always_label : integer label for always-urban d_T. If ``None``,
        inferred as the max non-missing trajectory in the data.
    tol : convergence tolerance for the optimizer.
    maxiter : maximum iterations per optimization step.
    """

    outcome: str
    choice: str
    trajectory: str
    individual_id: str
    covariates: Sequence[str] = field(default_factory=list)
    unbalanced_col: str | None = None
    base_trajectory: int | None = None
    never_label: int = 1
    always_label: int | None = None
    tol: float = 1e-10
    maxiter: int = 500

    # Populated by fit()
    coef_: dict[str, float] | None = None
    se_: dict[str, float] | None = None
    J_stat_: float | None = None
    J_df_: int | None = None
    J_pval_: float | None = None
    n_obs_: int | None = None
    n_clusters_: int | None = None
    switchers_: list[int] | None = None
    converged_: bool | None = None
    param_names_: list[str] | None = None
    vcov_: np.ndarray | None = None
    theta_: np.ndarray | None = None

    # ------------------------------------------------------------------
    # Design matrix builders (shared between M3 implementation and tests).
    # ------------------------------------------------------------------
    def _prepare_sample(self, df: pd.DataFrame) -> pd.DataFrame:
        """Drop rows with missing outcome/choice/covariates. Trajectory
        may be NaN (unbalanced observers) and is preserved as NaN.
        Missing values are never imputed.
        """
        required = [self.outcome, self.choice, self.individual_id]
        required += list(self.covariates)
        if self.unbalanced_col is not None:
            required.append(self.unbalanced_col)
        mask = df[required].notna().all(axis=1)
        return df.loc[mask].copy()

    def _build_design(self, df: pd.DataFrame) -> dict:
        """Assemble y, D, trajectory indicators, covariate block, etc."""
        df = self._prepare_sample(df)

        y = _as_ndarray(df[self.outcome])
        D = _as_ndarray(df[self.choice])
        ids = np.asarray(df[self.individual_id])
        traj = df[self.trajectory].to_numpy(dtype=float)  # NaN preserved

        if self.always_label is None:
            if np.all(np.isnan(traj)):
                raise ValueError("All trajectory values are missing.")
            always_label = int(np.nanmax(traj))
        else:
            always_label = int(self.always_label)
        never_label = int(self.never_label)

        observed = np.unique(traj[~np.isnan(traj)]).astype(int)
        switchers = sorted(
            int(s) for s in observed
            if s != never_label and s != always_label
        )

        def ind(val: int) -> np.ndarray:
            out = np.zeros(len(df), dtype=float)
            out[traj == val] = 1.0
            return out

        never_d = ind(never_label)
        always_d = ind(always_label)
        sw_d = np.column_stack([ind(s) for s in switchers])

        cov_names = list(self.covariates)
        X_cov_list = [_as_ndarray(df[c]) for c in cov_names]
        if self.unbalanced_col is not None:
            U = _as_ndarray(df[self.unbalanced_col])
            UD = U * D
            X_cov_list.extend([U, UD])
            cov_names = cov_names + [self.unbalanced_col,
                                     f"{self.unbalanced_col}_choice"]
        X_cov = (np.column_stack(X_cov_list) if X_cov_list
                 else np.zeros((len(df), 0)))

        return {
            "df": df,
            "y": y, "D": D, "ids": ids, "traj": traj,
            "never_d": never_d, "always_d": always_d,
            "sw_d": sw_d, "switchers": switchers,
            "always_label": always_label, "never_label": never_label,
            "X_cov": X_cov, "cov_names": cov_names,
        }

    def _build_instruments(self, data: dict) -> np.ndarray:
        """Assemble the moment-function instrument matrix Z.

        Matches the ``instruments()`` option in ``run_grc``::

            instruments(covarlist never switcher_traj choice
                        always_choice switcher_*_choice, nocons)

        Column order of the returned matrix (n x m)::

            [X_cov, never, switcher_s (S cols), D, always*D,
             switcher_s * D (S cols)]

        The moment ``g_it = z_it * eps_it`` is computed from this Z and
        the residual ``eps_it``.
        """
        D = data["D"]
        blocks = []
        if data["X_cov"].shape[1] > 0:
            blocks.append(data["X_cov"])
        blocks.append(data["never_d"][:, None])
        blocks.append(data["sw_d"])
        blocks.append(D[:, None])
        blocks.append((data["always_d"] * D)[:, None])
        blocks.append(data["sw_d"] * D[:, None])
        return np.column_stack(blocks)

    def _residuals(self, theta: np.ndarray, data: dict) -> np.ndarray:
        """Residual vector eps_it(theta) = y_it - fit_it(theta).

        fit_it encodes the right-hand side of Equation
        ``eq:restricted-grc-unbalanced``::

          fit_it = mu_never * 1{never}
                 + sum_s mu_s * 1{sw_i=s}
                 + Delta_base * D_it
                 + phi * sum_{s != base} (mu_s - mu_base) * 1{sw_i=s} * D_it
                 + (kappa + phi*(kappa - mu_base)) * 1{always} * D_it
                 + X_cov * gamma.
        """
        raise NotImplementedError("M3 will fill this in.")

    def _moments_individual(self, theta: np.ndarray, data: dict) -> np.ndarray:
        """Return n x m matrix of per-observation moments ``g_it``."""
        raise NotImplementedError("M3 will fill this in.")

    def _cluster_S(self, theta: np.ndarray, data: dict) -> np.ndarray:
        """Cluster-robust long-run variance of the stacked moment.

        Computes ``S = (1/n) * sum_i g_i g_i'`` with
        ``g_i = sum_{t in T_i} g_it``; this is the Stata convention under
        ``vce(cluster pid)``.
        """
        raise NotImplementedError("M3 will fill this in.")

    def _gradient_of_g(self, theta: np.ndarray, data: dict) -> np.ndarray:
        """Mean Jacobian ``G = d g_bar / d theta``, shape (m, p)."""
        raise NotImplementedError("M3 will fill this in.")

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def fit(self, df: pd.DataFrame, verbose: bool = False) -> "RestrictedGRC":
        """Two-step efficient GMM.

        Step 1: identity weighting, scipy optimizer from OLS initial values.
        Step 2: ``W = S_hat^{-1}`` using cluster-robust S at step-1 theta.

        After step 2, compute cluster-robust analytic variance and
        Hansen's J at the final theta.
        """
        raise NotImplementedError("M3 will fill this in.")

    def summary(self) -> str:
        """Return a textual summary of estimates (M3 fills in body)."""
        raise NotImplementedError("M3 will fill this in.")
