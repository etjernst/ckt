"""Empirical coverage of the four MD inversion CIs on T=2 synthetic data.

For each replication r = 1, ..., R, generate a synthetic T=2 GRC panel
under the same DGP as ``synth_t2_validation.py`` (true phi = PHI_TRUE,
Delta_base = DELTA_BASE), then run the four inversions and check
whether each true parameter falls inside its 95% CI.

The DGP's LCA structure pins the truth for every parameter:

    true Delta_d = DELTA_BASE + PHI_TRUE * (MU_TRAJ[d] - MU_TRAJ[base])

with base = 2. Within-switcher pi_s comes from TRAJECTORY_PROBS
restricted to {2, 3} and renormalized.

Reports empirical coverage = (1/R) * sum_r 1{covered_r} per
parameter, alongside Monte Carlo standard errors.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from lca_inversion import (
    drop_sparse_switchers,
    find_islands,
    fit_auxiliary_ols,
    grid_delta_always_md_inversion,
    grid_delta_avg_md_inversion,
    grid_delta_never_md_inversion,
    grid_lca_inversion,
)
from synth_t2_validation import (
    DELTA_BASE,
    MU_TRAJ,
    PHI_TRUE,
    TRAJECTORY_PROBS,
    synthesize,
)


HERE = Path(__file__).resolve().parent
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


BASE = 2
NEVER = 1
ALWAYS = 4
SWITCHERS = (2, 3)

TRUE_PHI = PHI_TRUE
TRUE_DELTA_BASE = DELTA_BASE
TRUE_DELTA_NEVER = (
    TRUE_DELTA_BASE + TRUE_PHI * (MU_TRAJ[NEVER] - MU_TRAJ[BASE])
)
TRUE_DELTA_ALWAYS = (
    TRUE_DELTA_BASE + TRUE_PHI * (MU_TRAJ[ALWAYS] - MU_TRAJ[BASE])
)
_pi_sw_total = sum(TRAJECTORY_PROBS[s] for s in SWITCHERS)
TRUE_PI_WITHIN = {s: TRAJECTORY_PROBS[s] / _pi_sw_total for s in SWITCHERS}
TRUE_DELTA_AVG = sum(
    TRUE_PI_WITHIN[s]
    * (TRUE_DELTA_BASE + TRUE_PHI * (MU_TRAJ[s] - MU_TRAJ[BASE]))
    for s in SWITCHERS
)


def _in_islands(value: float, islands: list[tuple[float, float]]) -> bool:
    return any(lo <= value <= hi for lo, hi in islands)


def _run_one_replication(seed: int) -> dict:
    """One Monte Carlo replication. Returns a flat dict of CI endpoints
    and coverage indicators per parameter."""
    df = synthesize(seed=seed)
    kept, _ = drop_sparse_switchers(
        df, trajectory="trajectory", choice="choice", hhid="pid",
        threshold=5,
    )
    base = BASE if BASE in kept else kept[0]
    fit = fit_auxiliary_ols(
        df, outcome="y", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=kept,
    )
    phi_grid = np.arange(-3.0, 1.0001, 0.02)
    delta_grid_nv = np.arange(-2.0, 4.0001, 0.02)
    delta_grid_al = np.arange(-6.0, 6.0001, 0.04)

    # phi inversion (just-identified)
    phi_curve, phi_lo, phi_hi = grid_lca_inversion(
        fit, switchers_kept=kept, base=base,
        phi_grid=phi_grid, type_one=0.05,
    )
    phi_islands = find_islands(phi_curve, type_one=0.05, x="phi")
    phi_cov = (
        _in_islands(TRUE_PHI, phi_islands) if phi_islands else False
    )

    # Delta_never
    n_curve, n_lo, n_hi = grid_delta_never_md_inversion(
        fit, switchers_kept=kept, base=base, never_traj=NEVER,
        delta_grid=delta_grid_nv, phi_search_grid=phi_grid,
        type_one=0.05,
    )
    n_islands = find_islands(n_curve, type_one=0.05, x="delta")
    n_cov = (
        _in_islands(TRUE_DELTA_NEVER, n_islands) if n_islands else False
    )

    # Delta_avg (use TRUE pi shares, since the DGP knows them; the
    # empirical pi from this replication's data would also work but
    # adds another source of MC noise unrelated to the inversion)
    pi_within = {s: TRUE_PI_WITHIN[s] for s in kept if s in SWITCHERS}
    # Renormalize across kept switchers in case any got dropped (rare)
    if abs(sum(pi_within.values()) - 1.0) > 1e-9:
        z = sum(pi_within.values())
        pi_within = {k: v / z for k, v in pi_within.items()}
    a_curve, a_lo, a_hi = grid_delta_avg_md_inversion(
        fit, switchers_kept=kept, base=base, pi_within=pi_within,
        delta_grid=delta_grid_nv, phi_search_grid=phi_grid,
        type_one=0.05,
    )
    a_islands = find_islands(a_curve, type_one=0.05, x="delta")
    a_cov = (
        _in_islands(TRUE_DELTA_AVG, a_islands) if a_islands else False
    )

    # Delta_always
    t_curve, t_lo, t_hi = grid_delta_always_md_inversion(
        fit, switchers_kept=kept, base=base, always_traj=ALWAYS,
        delta_grid=delta_grid_al, phi_search_grid=phi_grid,
        type_one=0.05,
    )
    t_islands = find_islands(t_curve, type_one=0.05, x="delta")
    t_cov = (
        _in_islands(TRUE_DELTA_ALWAYS, t_islands) if t_islands else False
    )

    return {
        "seed": seed,
        "phi_lo": phi_lo, "phi_hi": phi_hi, "phi_cov": phi_cov,
        "phi_n_islands": len(phi_islands),
        "n_lo": n_lo, "n_hi": n_hi, "n_cov": n_cov,
        "n_n_islands": len(n_islands),
        "a_lo": a_lo, "a_hi": a_hi, "a_cov": a_cov,
        "a_n_islands": len(a_islands),
        "t_lo": t_lo, "t_hi": t_hi, "t_cov": t_cov,
        "t_n_islands": len(t_islands),
    }


def _cov_se(p: float, R: int) -> float:
    """MC standard error for a binomial proportion at level p."""
    return float(np.sqrt(p * (1.0 - p) / R))


def main(R: int = 100):
    print(f"True parameters under the DGP:")
    print(f"  phi          = {TRUE_PHI:+.3f}")
    print(f"  Delta_never  = {TRUE_DELTA_NEVER:+.3f}")
    print(f"  Delta_avg    = {TRUE_DELTA_AVG:+.3f}")
    print(f"  Delta_always = {TRUE_DELTA_ALWAYS:+.3f}")
    print(f"  pi_within    = {TRUE_PI_WITHIN}")
    print()
    print(f"Running R={R} Monte Carlo replications...")

    rows = []
    for r in range(R):
        seed = 1000 + r
        try:
            row = _run_one_replication(seed)
        except Exception as e:
            print(f"  rep {r} (seed {seed}): FAILED -- {e}")
            continue
        rows.append(row)
        if (r + 1) % 10 == 0:
            print(f"  done {r + 1}/{R}")

    out = pd.DataFrame(rows)
    out.to_csv(OUTDIR / "synth_t2_coverage_per_rep.csv", index=False)

    summary = []
    for label, true_val, key in [
        ("phi",          TRUE_PHI,          "phi"),
        ("Delta_never",  TRUE_DELTA_NEVER,  "n"),
        ("Delta_avg",    TRUE_DELTA_AVG,    "a"),
        ("Delta_always", TRUE_DELTA_ALWAYS, "t"),
    ]:
        cov = float(out[f"{key}_cov"].mean())
        se = _cov_se(cov, len(out))
        empty = int(out[f"{key}_lo"].isna().sum())
        multi = int((out[f"{key}_n_islands"] > 1).sum())
        summary.append({
            "parameter": label,
            "true_value": true_val,
            "n_reps": len(out),
            "coverage": cov,
            "mc_se": se,
            "n_empty": empty,
            "n_multi_island": multi,
        })

    sdf = pd.DataFrame(summary)
    sdf.to_csv(OUTDIR / "synth_t2_coverage_summary.csv", index=False)
    print()
    print(sdf.to_string(index=False))
    print()
    print(f"Per-rep CSV  -> {OUTDIR / 'synth_t2_coverage_per_rep.csv'}")
    print(f"Summary CSV  -> {OUTDIR / 'synth_t2_coverage_summary.csv'}")


if __name__ == "__main__":
    import sys
    R = int(sys.argv[1]) if len(sys.argv) > 1 else 100
    main(R=R)
