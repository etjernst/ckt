"""V3 IDN empty-CI diagnostic: Wald at the GMM point estimate.

The V3 smoke (2026-05-18) returned zero accepted lattice points for IDN
at alpha = 0.05, but the marginal phi CI from 5b_inversion.do is
[-1.23, -0.01]. Diagnose by evaluating the constrained-J inside
build_joint_ci_grid at (phi_hat, beta_hat) and comparing to
chi^2_{K, 0.95}.

Three readings of the Wald-at-GMM value:
  - Wald < chi^2_K threshold: construction is right; empty grid CI is a
    coarseness or honest-tight-region artifact. Refine the lattice.
  - Wald >> threshold: bug in moment formula, Jacobian, or weighting
    matrix; GMM point is not being recognized as a solution.
  - Borderline: numerical / convergence issue in the inner OLS fit.

Also reports two cross-checks:
  - The unconstrained GMM J from the parent ster (28.172 on 27 dof for
    IDN col 5).
  - The marginal phi CI from grid_lca_inversion (K - 1 dof), which
    should reproduce 5b's [-1.23, -0.01].
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.stats import chi2

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "python-grc"))

from counterfactuals import (  # noqa: E402
    build_joint_ci_grid,
    drop_sparse_switchers,
    fit_auxiliary_ols,
)
from lca_inversion import grid_lca_inversion  # noqa: E402

INPUTS_DIR = Path(
    "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/counterfactual_inputs"
)
DATA_DIR = Path(
    "C:/git/ckt/.claude/worktrees/lca-inversion/RP7/data/processed"
)

COUNTRY = "IDN"
BASE_TRAJECTORY = 2
THRESHOLD = 5
TYPE_ONE = 0.05


def load_scalars(country: str) -> dict:
    df = pd.read_csv(INPUTS_DIR / f"{country}_e1_scalars.csv")
    out: dict = {}
    for _, row in df.iterrows():
        try:
            out[row["name"]] = float(row["value"])
        except (TypeError, ValueError):
            out[row["name"]] = row["value"]
    return out


def main() -> None:
    print(f"{'=' * 64}")
    print(f"V3 Wald-at-GMM diagnostic: {COUNTRY} col 5 (cuu_ca)")
    print(f"{'=' * 64}")

    scalars = load_scalars(COUNTRY)
    phi_hat = scalars["phi_hat"]
    beta_hat = scalars["beta_hat"]
    j_stat = scalars["j_stat"]
    j_df = int(scalars["j_df"])
    j_pval = scalars["j_pval"]

    print(f"\nFrom parent ster (GMM point estimate):")
    print(f"  phi_hat   = {phi_hat:+.4f}")
    print(f"  beta_hat  = {beta_hat:+.4f}")
    print(f"  GMM J     = {j_stat:.3f}   df = {j_df}   p = {j_pval:.3f}")
    print(f"  chi^2_{{{j_df}, 0.95}} = {chi2.ppf(0.95, df=j_df):.3f}")

    # Load data and reproduce the GMM sample selection from 0_programs.do's
    # set_covariates and 4_GrRC.do's lndepvar definition.
    df = pd.read_stata(DATA_DIR / f"{COUNTRY}_unb.dta", convert_categoricals=False)
    df = df.dropna(subset=["consumption", "choice", "trajectory"]).copy()
    # 4_GrRC.do line 136: replace lndepvar = log(consumption/hhsize_cube)
    df["lndepvar"] = np.log(df["consumption"] / df["hhsize_cube"])
    df = df.dropna(subset=["lndepvar"])
    # set_covariates drops if mi(education_max) | mi(age) | obs_per_individual == 1
    df = df.dropna(subset=["education_max", "age"])
    if "obs_per_individual" in df.columns:
        df = df.loc[df["obs_per_individual"] > 1].copy()
    # Generate period dummies (period_1 omitted as base)
    periods = sorted(df["period"].dropna().unique().astype(int).tolist())
    period_cols = []
    for t in periods[1:]:
        col = f"period_{t}"
        df[col] = (df["period"] == t).astype(float)
        period_cols.append(col)
    # covs_gmm_all controls (already in data: female, age2, education_max, education_max2)
    controls = period_cols + ["female", "age2", "education_max", "education_max2"]
    for col in ["unbalanced", "unbalanced_choice"]:
        if col not in df.columns:
            df[col] = 0.0

    kept, sw_counts = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=THRESHOLD
    )
    K = len(kept)
    print(f"\nAuxiliary OLS setup (matched to GMM cuu_ca):")
    print(f"  outcome: log(consumption / hhsize_cube)")
    print(f"  controls: {controls}")
    print(f"  switchers kept (N >= {THRESHOLD}): {kept}")
    print(f"  K (= number of moments in build_joint_ci_grid) = {K}")
    print(f"  chi^2_{{K, 0.95}} = chi^2_{{{K}, 0.95}} = {chi2.ppf(0.95, df=K):.3f}")

    base = BASE_TRAJECTORY if BASE_TRAJECTORY in kept else kept[0]
    print(f"  base trajectory = {base}")

    fit = fit_auxiliary_ols(
        df,
        outcome="lndepvar",
        trajectory="trajectory",
        choice="choice",
        hhid="pid",
        switchers_kept=kept,
        controls=controls,
    )
    print(f"  aux OLS: n_obs = {fit.n_obs}, n_clusters = {fit.n_clusters}, p = {len(fit.b)}")

    # ----- Wald at the GMM point -----
    print(f"\n{'-' * 64}")
    print(f"Wald-at-GMM diagnostic")
    print(f"{'-' * 64}")
    ci_point = build_joint_ci_grid(
        fit=fit,
        switchers_kept=kept,
        base=base,
        phi_grid=np.array([phi_hat]),
        beta_grid=np.array([beta_hat]),
        type_one=TYPE_ONE,
    )
    wald_gmm = float(ci_point["wald"][0, 0])
    p_gmm = float(ci_point["p_value"][0, 0])
    threshold = chi2.ppf(1.0 - TYPE_ONE, df=K)
    print(f"  Wald at (phi_hat, beta_hat) = ({phi_hat:+.4f}, {beta_hat:+.4f})")
    print(f"  Constrained Wald = {wald_gmm:.3f}")
    print(f"  p-value          = {p_gmm:.4f}")
    print(f"  chi^2_{{K={K}, 0.95}} threshold = {threshold:.3f}")
    print(f"  Accepted at alpha = {TYPE_ONE}: {p_gmm >= TYPE_ONE}")

    # Per-switcher decomposition of the Wald
    print(f"\n  Per-switcher moment decomposition at the GMM point:")
    sw = list(kept)
    base_alpha = fit.idx(f"alpha[{base}]")
    s_alpha = np.array([fit.idx(f"alpha[{s}]") for s in sw])
    s_beta = np.array([fit.idx(f"beta[{s}]") for s in sw])
    is_base = np.array([s == base for s in sw])
    u = fit.b[s_beta]
    d = fit.b[s_alpha] - fit.b[base_alpha]
    m = u - beta_hat - phi_hat * d
    print(f"    {'s':>4} {'beta_s_OLS':>12} {'d_s = a_s - a_base':>22} {'m_s':>12}")
    for k, s in enumerate(sw):
        tag = "*" if is_base[k] else " "
        print(f"    {s:>4}{tag} {u[k]:>+12.4f} {d[k]:>+22.4f} {m[k]:>+12.4f}")
    # Recompute V_m and contributions
    p = len(fit.b)
    J = np.zeros((K, p))
    for k in range(K):
        J[k, s_beta[k]] = 1.0
        if not is_base[k]:
            J[k, s_alpha[k]] = -phi_hat
            J[k, base_alpha] = +phi_hat
    V_m = J @ fit.V @ J.T
    V_m_inv = np.linalg.pinv(V_m, rcond=1e-10)
    print(f"\n  V_m diagonal (sqrt -> moment SE):")
    print(f"    {'s':>4} {'se(m_s)':>10}")
    for k, s in enumerate(sw):
        print(f"    {s:>4} {np.sqrt(V_m[k, k]):>10.4f}")
    # Eigenvalues of V_m to see if it's near-singular
    eigvals = np.linalg.eigvalsh(V_m)
    print(f"\n  V_m eigenvalues (smallest to largest):")
    print(f"    min = {eigvals[0]:.3e}")
    print(f"    max = {eigvals[-1]:.3e}")
    print(f"    condition number = {eigvals[-1] / eigvals[0]:.3e}")

    # Sanity check: re-run the marginal CI (grid_lca_inversion, K-1 dof)
    print(f"\n{'-' * 64}")
    print(f"Cross-check: marginal phi CI from grid_lca_inversion (K-1 dof)")
    print(f"  (Should reproduce 5b_inversion.do's [-1.23, -0.01].)")
    print(f"{'-' * 64}")
    phi_grid_marginal = np.linspace(-2.0, 1.0, 401)
    curve, ci_lo, ci_hi = grid_lca_inversion(
        fit=fit,
        switchers_kept=kept,
        base=base,
        phi_grid=phi_grid_marginal,
        type_one=TYPE_ONE,
    )
    if not np.isnan(ci_lo):
        print(f"  marginal phi CI: [{ci_lo:+.3f}, {ci_hi:+.3f}]")
    else:
        print(f"  marginal phi CI: empty")
    i_phihat = int(np.argmin(np.abs(curve["phi"].to_numpy() - phi_hat)))
    print(f"  Marginal Wald at phi_hat = {phi_hat:+.4f}: "
          f"{curve['wald'].iloc[i_phihat]:.3f} "
          f"(K-1 threshold = chi^2_{{{K - 1}, 0.95}} "
          f"= {chi2.ppf(0.95, df=K - 1):.3f})")

    # ----- Verdict -----
    print(f"\n{'=' * 64}")
    print(f"Verdict")
    print(f"{'=' * 64}")
    if wald_gmm < threshold:
        print(f"  Construction is RIGHT: Wald ({wald_gmm:.3f}) < threshold ({threshold:.3f})")
        print(f"  The empty grid CI in the smoke is a lattice/coverage artifact.")
        print(f"  Next step: refine the lattice around (phi_hat, beta_hat).")
    elif wald_gmm > 2 * threshold:
        print(f"  Construction is WRONG: Wald ({wald_gmm:.3f}) >> threshold ({threshold:.3f})")
        print(f"  Likely a bug in moment formula, Jacobian, or V_m.")
        print(f"  Inspect the per-switcher decomposition above.")
    else:
        print(f"  BORDERLINE: Wald ({wald_gmm:.3f}) close to threshold ({threshold:.3f})")
        print(f"  Probably a numerical / convergence issue.")


if __name__ == "__main__":
    main()
