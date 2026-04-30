"""Synthesize an over-identified GRC panel with realistic CKT-scale
parameters, and check empirical coverage of the four MD inversion CIs.

Differences from ``synth_t2_validation.py``:

* T = 3 instead of T = 2, so up to 8 trajectories ($2^T$) exist and
  $K = 6$ switcher trajectories pass the threshold-5 sparse drop with
  modest sample sizes. $J_R = K - 1 = 5$ over-identifying restrictions
  on $\\phi$, so the LCA-restriction joint test is non-trivial.
* Trajectory means spaced 0.2 log units apart (realistic for log
  per-capita consumption in CKT) instead of 1.0 log units. Within-
  trajectory dispersion sigma_alpha = 0.6, transitory sigma_eps = 0.3,
  also matching realistic log-consumption scales. The model is
  substantially more fragile here than in the T=2 synth: cross-traj
  signal is ~0.2 vs noise ~0.6, so OLS alphas have meaningful
  uncertainty.
* phi_true = -0.5 (realistic CKT scale), beta_base = 0.05.

Usage::

    python synth_overid.py            # smoke (R=3)
    python synth_overid.py 100        # full coverage R=100
"""

from __future__ import annotations

from itertools import product
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


HERE = Path(__file__).resolve().parent
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


# --- DGP --------------------------------------------------------------

T = 3
N_INDIVIDUALS = 10_000

# Treatment patterns ordered as integer codes 0..2^T-1 with code = sum
# t bit_t * 2^t. Code 0 is the all-zero pattern (never); code 2^T-1
# is the all-one pattern (always); the rest are switchers.
ALL_PATTERNS: list[tuple[int, ...]] = list(product([0, 1], repeat=T))


def _code(pattern: tuple[int, ...]) -> int:
    """Map a binary tuple to an integer code 0..2^T-1."""
    return sum(b * (1 << t) for t, b in enumerate(pattern))


TREATMENT_PATTERN: dict[int, tuple[int, ...]] = {
    _code(p): p for p in ALL_PATTERNS
}
NEVER = _code(tuple(0 for _ in range(T)))
ALWAYS = _code(tuple(1 for _ in range(T)))
SWITCHERS = sorted(c for c in TREATMENT_PATTERN if c not in (NEVER, ALWAYS))

# Realistic trajectory shares for log per-capita consumption settings
# in CKT. Never and always dominate; switcher mass spreads across
# 6 patterns. Sums to 1.
TRAJECTORY_PROBS: dict[int, float] = {
    NEVER:   0.30,
    ALWAYS:  0.42,
}
_sw_probs = [0.05, 0.04, 0.05, 0.04, 0.05, 0.05]
for s, p in zip(SWITCHERS, _sw_probs):
    TRAJECTORY_PROBS[s] = p
assert abs(sum(TRAJECTORY_PROBS.values()) - 1.0) < 1e-9

# Trajectory means spaced 0.1 log units apart on the integer codes.
# This is the realistic CKT scale for log per-capita consumption.
MU_TRAJ: dict[int, float] = {c: 0.1 * c for c in TREATMENT_PATTERN}

# Realistic CKT scales for log consumption
SIGMA_ALPHA = 0.6
SIGMA_EPS = 0.3

# True parameters under the LCA model
PHI_TRUE = -0.5
DELTA_BASE = 0.05  # baseline switcher's return

# Use the smallest switcher code as base (mirrors data_loader / Stata
# convention of base = trajectory 2)
BASE = SWITCHERS[0]
MU_BASE = MU_TRAJ[BASE]


def true_delta(traj_code: int) -> float:
    """LCA-implied return for trajectory ``traj_code`` under the DGP."""
    return DELTA_BASE + PHI_TRUE * (MU_TRAJ[traj_code] - MU_BASE)


def synthesize(seed: int = 42) -> pd.DataFrame:
    """Generate a balanced T-period panel under the LCA model."""
    rng = np.random.default_rng(seed)

    codes = list(TRAJECTORY_PROBS.keys())
    probs = [TRAJECTORY_PROBS[c] for c in codes]
    traj = rng.choice(codes, size=N_INDIVIDUALS, p=probs)

    alpha_i = np.zeros(N_INDIVIDUALS)
    for code in codes:
        mask = traj == code
        alpha_i[mask] = (
            MU_TRAJ[code] + SIGMA_ALPHA * rng.standard_normal(mask.sum())
        )

    delta_traj = {c: true_delta(c) for c in codes}

    rows = []
    for i in range(N_INDIVIDUALS):
        pid = i + 1
        pattern = TREATMENT_PATTERN[int(traj[i])]
        delta = delta_traj[int(traj[i])]
        eps = SIGMA_EPS * rng.standard_normal(T)
        for t, d in enumerate(pattern, start=1):
            y = alpha_i[i] + delta * d + eps[t - 1]
            rows.append((pid, t, int(traj[i]), int(d), float(y)))

    df = pd.DataFrame(
        rows, columns=["pid", "period", "trajectory", "choice", "y"]
    )
    df["unbalanced"] = 0
    df["unbalanced_choice"] = 0
    return df


# --- Truth pinned by the DGP -----------------------------------------

TRUE_PHI = PHI_TRUE
TRUE_DELTA_BASE = DELTA_BASE
TRUE_DELTA_NEVER = true_delta(NEVER)
TRUE_DELTA_ALWAYS = true_delta(ALWAYS)
# Within-switcher share is conditional on switcher status, so
# normalize by the total switcher mass.
_pi_sw_total = sum(TRAJECTORY_PROBS[s] for s in SWITCHERS)
TRUE_PI_WITHIN = {s: TRAJECTORY_PROBS[s] / _pi_sw_total for s in SWITCHERS}
TRUE_DELTA_AVG = sum(
    TRUE_PI_WITHIN[s] * true_delta(s) for s in SWITCHERS
)


def _in_islands(value: float, islands: list[tuple[float, float]]) -> bool:
    return any(lo <= value <= hi for lo, hi in islands)


def _run_one_replication(seed: int, threshold: int = 5) -> dict:
    df = synthesize(seed=seed)
    kept, _ = drop_sparse_switchers(
        df, trajectory="trajectory", choice="choice", hhid="pid",
        threshold=threshold,
    )
    base = BASE if BASE in kept else kept[0]
    fit = fit_auxiliary_ols(
        df, outcome="y", trajectory="trajectory", choice="choice",
        hhid="pid", switchers_kept=kept,
    )
    phi_grid = np.arange(-3.0, 1.0001, 0.02)
    delta_grid_nv = np.arange(-1.0, 1.0001, 0.005)
    delta_grid_al = np.arange(-3.0, 3.0001, 0.01)

    # phi inversion (over-identified: K - 1 = J_R restrictions)
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

    # Delta_avg with TRUE within-switcher shares (matches what we did
    # for T=2; renormalize over kept set if drop_sparse_switchers
    # culled any switchers in this replication)
    pi_within = {s: TRUE_PI_WITHIN[s] for s in kept if s in SWITCHERS}
    if abs(sum(pi_within.values()) - 1.0) > 1e-9:
        z = sum(pi_within.values())
        pi_within = {k: v / z for k, v in pi_within.items()}
    a_curve, a_lo, a_hi = grid_delta_avg_md_inversion(
        fit, switchers_kept=kept, base=base, pi_within=pi_within,
        delta_grid=delta_grid_nv, phi_search_grid=phi_grid,
        type_one=0.05,
    )
    a_islands = find_islands(a_curve, type_one=0.05, x="delta")
    # Recompute Delta_avg-truth conditional on the rep's kept set so we
    # measure coverage of the population object the test is targeting.
    if abs(sum(TRUE_PI_WITHIN[s] for s in kept if s in SWITCHERS) - 1.0) > 1e-9:
        target_avg = sum(
            pi_within[s] * true_delta(s) for s in kept if s in SWITCHERS
        )
    else:
        target_avg = TRUE_DELTA_AVG
    a_cov = (
        _in_islands(target_avg, a_islands) if a_islands else False
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
        "K": len(kept),
        "phi_lo": phi_lo, "phi_hi": phi_hi, "phi_cov": phi_cov,
        "phi_n_islands": len(phi_islands),
        "n_lo": n_lo, "n_hi": n_hi, "n_cov": n_cov,
        "n_n_islands": len(n_islands),
        "a_lo": a_lo, "a_hi": a_hi, "a_cov": a_cov,
        "a_n_islands": len(a_islands), "a_target": target_avg,
        "t_lo": t_lo, "t_hi": t_hi, "t_cov": t_cov,
        "t_n_islands": len(t_islands),
    }


def _cov_se(p: float, R: int) -> float:
    return float(np.sqrt(p * (1.0 - p) / R))


def main(R: int = 100):
    print(f"Setup: T={T}, N={N_INDIVIDUALS}")
    print(f"Trajectories: NEVER={NEVER}, ALWAYS={ALWAYS}, "
          f"switchers={SWITCHERS}, base={BASE}")
    print(f"Trajectory shares: {TRAJECTORY_PROBS}")
    print(f"Trajectory means : {MU_TRAJ}")
    print(f"sigma_alpha={SIGMA_ALPHA}, sigma_eps={SIGMA_EPS}")
    print(f"True params: phi={TRUE_PHI:+.3f}, beta_base={TRUE_DELTA_BASE:+.3f}")
    print(f"  Delta_never  = {TRUE_DELTA_NEVER:+.3f}")
    print(f"  Delta_avg    = {TRUE_DELTA_AVG:+.3f}")
    print(f"  Delta_always = {TRUE_DELTA_ALWAYS:+.3f}")
    print()
    print(f"Running R={R} Monte Carlo replications...")

    rows = []
    for r in range(R):
        seed = 2000 + r
        try:
            row = _run_one_replication(seed)
        except Exception as e:
            print(f"  rep {r} (seed {seed}): FAILED -- {e}")
            continue
        rows.append(row)
        if (r + 1) % 10 == 0:
            print(f"  done {r + 1}/{R}")

    out = pd.DataFrame(rows)
    out.to_csv(OUTDIR / "synth_overid_coverage_per_rep.csv", index=False)

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
            "mean_K": float(out["K"].mean()),
        })

    sdf = pd.DataFrame(summary)
    sdf.to_csv(OUTDIR / "synth_overid_coverage_summary.csv", index=False)
    print()
    print(sdf.to_string(index=False))
    print()
    print(f"Per-rep CSV  -> {OUTDIR / 'synth_overid_coverage_per_rep.csv'}")
    print(f"Summary CSV  -> {OUTDIR / 'synth_overid_coverage_summary.csv'}")


if __name__ == "__main__":
    import sys
    R = int(sys.argv[1]) if len(sys.argv) > 1 else 3
    main(R=R)
