"""Synthesize a T=2 GRC dataset matching the original ado's design,
run our Python LCA inversion on it, and (separately, via Stata batch)
run the original ado. Compare CI endpoints.

Generates ``synth_t2.dta`` with 4 trajectories at Suri-2011 shares,
true phi = -1.5, mu's spaced so that integer-trajectory and
mu-difference encodings test the same restriction. The companion
``synth_t2_validation.do`` runs the original ``grc_weak_id_inference``
on the same data and writes ``synth_t2_stata_ci.csv``.

If both CIs agree to ~2-3 decimal places, our Python implementation
faithfully reproduces the original ado's procedure on data the original
was designed for. Any larger gap signals an implementation bug.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from lca_inversion import (
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_lca_inversion,
)


HERE = Path(__file__).resolve().parent

# DGP parameters (matching the GRC paper's MC where possible).
N_INDIVIDUALS = 5000
TRAJECTORY_PROBS = {
    1: 0.26,  # never (00)
    2: 0.08,  # switcher (01) -- rural then urban
    3: 0.13,  # switcher (10) -- urban then rural
    4: 0.53,  # always (11)
}
TREATMENT_PATTERN = {
    1: (0, 0),  # never
    2: (0, 1),  # 01
    3: (1, 0),  # 10
    4: (1, 1),  # always
}
# mu_traj chosen so that mu_3 - mu_2 = 1.0 ==> integer-trajectory encoding
# and mu-difference encoding test identical restrictions, so both
# implementations are testing the same null on these data.
MU_TRAJ = {1: 1.0, 2: 2.0, 3: 3.0, 4: 4.0}
SIGMA_ALPHA = 0.84
SIGMA_EPS = 0.38

PHI_TRUE = -1.5
DELTA_BASE = 0.5  # treatment effect for base switcher (trajectory 2)


def synthesize(seed: int = 42) -> pd.DataFrame:
    """Generate a balanced T=2 panel under the LCA model with phi = PHI_TRUE."""
    rng = np.random.default_rng(seed)

    codes = list(TRAJECTORY_PROBS.keys())
    probs = list(TRAJECTORY_PROBS.values())
    traj = rng.choice(codes, size=N_INDIVIDUALS, p=probs)

    alpha_i = np.zeros(N_INDIVIDUALS)
    for code, mu in MU_TRAJ.items():
        mask = traj == code
        alpha_i[mask] = mu + SIGMA_ALPHA * rng.standard_normal(mask.sum())

    delta_traj = {
        1: 0.0,                          # never -- treatment never observed
        2: DELTA_BASE,                   # base switcher
        3: DELTA_BASE + PHI_TRUE,        # LCA with adjacent integer diff = 1
        4: DELTA_BASE + PHI_TRUE * 2.0,  # extrapolation to always
    }

    rows = []
    for i in range(N_INDIVIDUALS):
        pid = i + 1
        d1, d2 = TREATMENT_PATTERN[traj[i]]
        delta = delta_traj[traj[i]]
        eps = SIGMA_EPS * rng.standard_normal(2)
        y1 = alpha_i[i] + delta * d1 + eps[0]
        y2 = alpha_i[i] + delta * d2 + eps[1]
        rows.append((pid, 1, int(traj[i]), int(d1), float(y1)))
        rows.append((pid, 2, int(traj[i]), int(d2), float(y2)))

    df = pd.DataFrame(rows, columns=["pid", "period", "trajectory", "choice", "y"])
    # The CKT spec uses 'unbalanced' / 'unbalanced_choice' shifters; keep them
    # zero for this purely-balanced synthetic so they collapse out of the OLS.
    df["unbalanced"] = 0
    df["unbalanced_choice"] = 0
    return df


def run_python_inversion(df: pd.DataFrame) -> tuple[pd.DataFrame, float, float]:
    kept, counts = drop_sparse_switchers(
        df, trajectory="trajectory", choice="choice", hhid="pid", threshold=5
    )
    print(f"  switcher candidates: {sorted(counts.keys())}, kept: {kept}")

    fit = fit_auxiliary_ols(
        df,
        outcome="y",
        trajectory="trajectory",
        choice="choice",
        hhid="pid",
        switchers_kept=kept,
    )
    print(f"  aux OLS: p={len(fit.b)} params, n={fit.n_obs}, G={fit.n_clusters}")
    print(f"  alpha[2] = {fit.b[fit.idx('alpha[2]')]:.4f}  (true mu_2 = 2.0)")
    print(f"  alpha[3] = {fit.b[fit.idx('alpha[3]')]:.4f}  (true mu_3 = 3.0)")
    print(f"  beta[2]  = {fit.b[fit.idx('beta[2]')]:.4f}  (true Delta_2 = {DELTA_BASE})")
    print(f"  beta[3]  = {fit.b[fit.idx('beta[3]')]:.4f}  "
          f"(true Delta_3 = {DELTA_BASE + PHI_TRUE})")

    phi_grid = np.arange(-3.0, 1.0001, 0.02)
    curve, ci_lo, ci_hi = grid_lca_inversion(
        fit, switchers_kept=kept, base=2, phi_grid=phi_grid, type_one=0.05
    )
    return curve, ci_lo, ci_hi


def main():
    out_dta = HERE / "synth_t2.dta"
    out_curve = HERE / "synth_t2_python_curve.csv"
    out_ci = HERE / "synth_t2_python_ci.csv"

    print(f"True phi = {PHI_TRUE}")
    print("Generating synthetic T=2 dataset...")
    df = synthesize(seed=42)
    print(f"  N_individuals = {N_INDIVIDUALS}, N_obs = {len(df)}")
    print(f"  trajectory shares (observed):")
    counts = df.groupby("trajectory")["pid"].nunique() / N_INDIVIDUALS
    for code, share in counts.items():
        print(f"    traj {code}: {share:.3f}  (target {TRAJECTORY_PROBS[code]:.2f})")

    df.to_stata(out_dta, write_index=False, version=117)
    print(f"  saved {out_dta}")

    print("\nRunning Python LCA inversion...")
    curve, ci_lo, ci_hi = run_python_inversion(df)
    print(f"\nPython CI (alpha=0.05): [{ci_lo:.4f}, {ci_hi:.4f}]")
    print(f"  width = {ci_hi - ci_lo:.4f}")
    print(f"  contains true phi = {PHI_TRUE}: "
          f"{ci_lo <= PHI_TRUE <= ci_hi if not np.isnan(ci_lo) else 'CI empty'}")

    curve.to_csv(out_curve, index=False)
    pd.DataFrame({"min_phi": [ci_lo], "max_phi": [ci_hi]}).to_csv(out_ci, index=False)
    print(f"\nSaved Python curve to {out_curve}")
    print(f"Saved Python CI to {out_ci}")
    print("\nNext: run Stata side via")
    print(f"  cd {HERE} && stata-mp -b do synth_t2_validation.do")


if __name__ == "__main__":
    main()
