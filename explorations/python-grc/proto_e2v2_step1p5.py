"""Step 1.5 analytic prototype for E2 Version 2 (THROWAWAY).

Gate question (spec 2026-06-29-e2-v2-resorting-magnitude.md, plan Step 1.5):
at the CHN rural-hukou point estimates, anchor sigma_eta to the observed
person-level never-migrant share under Reading A (kappa in the baseline
choice index), then evaluate both scenarios (barrier-only and
regime-convergence) at c in {0, 0.5, 1}, computing the realized-effect
integral and the unrealized potential. Report whether the estimand is
coherent: finite, sign-sensible, and stable for regime-convergence away
from the phi = -1 pole.

This is a one-page coherence probe, not the deliverable. It reads only the
already-exported per-cell input CSVs (counterfactual_inputs/), never the
panel data junction. Two primitives that the full build draws from the
panel are unavailable here and are treated as swept inputs, flagged in the
memo as blockers for the real harness:
  - the within-trajectory comparative-advantage dispersion sigma_theta
    (calibration 1/2 both need individual rural log consumption);
  - the unbalanced-inclusive person-level never share (the -1 lump is not
    split by realized never/switch status in the export). We anchor to the
    BALANCED rural-hukou never share, which the CSV does give cleanly.

Model (Reading A, logit shape):
  payoff      Delta_g(mu) = beta_g + phi_g * (mu - mu_base_g)
  common base beta_tilde_g = beta_g + phi_g * (mu_common - mu_base_g)
  barrier     kappa = c * (beta_tilde_uh - beta_tilde_rh),  c in [0,1]
  choice idx  urban iff Delta_payoff(mu) - kappa + eta > 0,  eta ~ Logistic(0, s)
              with s the logistic scale; sigma_eta = s * pi / sqrt(3).
  P_urban(mu) = Lambda((Delta_payoff(mu) - kappa) / s)
  never(mu)   = (1 - P_urban(mu))^T          (T i.i.d. periods)

Scenarios (rural-hukou workers, removing the barrier kappa -> 0):
  barrier-only       : payoff & index keep the rh schedule (beta_rh, phi_rh)
  regime-convergence : payoff & index swap to the uh schedule (beta_uh, phi_uh)
  baseline (both)    : observed world = rh schedule WITH barrier kappa
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from numpy.polynomial.hermite_e import hermegauss
from scipy.optimize import brentq
from scipy.special import expit  # logistic CDF

HERE = Path(__file__).resolve().parent
INPUTS = HERE.parent.parent / "RP7" / "output" / "counterfactual_inputs"

T_PANEL = 4          # balanced CHN panel length (4 waves)
GH_NODES = 40        # Gauss-Hermite nodes for the within-trajectory integral
C_GRID = [0.0, 0.5, 1.0]
SIGMA_THETA_SWEEP = [0.0, 0.2, 0.4, 0.6]   # blocker: exact value needs the panel
NEVER_TARGET_SWEEP = [0.55, 0.6543, 0.75]  # headline = balanced rh never share


# --------------------------------------------------------------------------
# Inputs
# --------------------------------------------------------------------------
def load_cell(short: str) -> dict:
    """Read the four exported CSVs for one cell and assemble point inputs."""
    traj = pd.read_csv(INPUTS / f"{short}_e1_traj.csv")
    mu_d = pd.read_csv(INPUTS / f"{short}_e1_mu_d.csv")
    delta = pd.read_csv(INPUTS / f"{short}_e1_delta_d.csv").rename(
        columns={"trajectory": "traj_for_agg"}
    )
    sc = pd.read_csv(INPUTS / f"{short}_e1_scalars.csv")
    scalars = {}
    for _, r in sc.iterrows():
        try:
            scalars[r["name"]] = float(r["value"])
        except (TypeError, ValueError):
            scalars[r["name"]] = r["value"]

    df = traj.merge(mu_d, on="traj_for_agg", how="left").merge(
        delta, on="traj_for_agg", how="left"
    )
    beta = scalars["beta_hat"]
    phi = scalars["phi_hat"]

    # Base trajectory: the one whose unrestricted Delta equals beta_hat
    # (the LCA line passes through beta at theta = 0, i.e. mu = mu_base).
    cand = df.dropna(subset=["delta_d_unrestricted"]).copy()
    cand["gap"] = (cand["delta_d_unrestricted"] - beta).abs()
    base_row = cand.loc[cand["gap"].idxmin()]
    base_traj = int(base_row["traj_for_agg"])
    mu_base = float(df.loc[df["traj_for_agg"] == base_traj, "mu_d"].iloc[0])

    return {
        "short": short, "df": df, "beta": beta, "phi": phi,
        "base_traj": base_traj, "mu_base": mu_base, "scalars": scalars,
    }


def balanced_trajectories(cell: dict) -> pd.DataFrame:
    """Balanced enumerated trajectories only (drop the -1 unbalanced lump).

    Renormalize pi over the balanced set. d_T (dbar==1) carries a missing
    mu_d (never observed rural) and is kept only as a known-urban mass:
    it contributes pi to the denominator, 0 to never, 0 to resorting.
    """
    df = cell["df"]
    bal = df[df["traj_for_agg"] >= 0].copy()
    n_total = bal["n_pids"].sum()
    bal["pi_bal"] = bal["n_pids"] / n_total
    bal["is_dT"] = (bal["dbar_d"] >= 0.999)
    bal["is_never"] = (bal["dbar_d"] <= 1e-9)
    return bal


# --------------------------------------------------------------------------
# Primitives
# --------------------------------------------------------------------------
def beta_tilde(beta: float, phi: float, mu_base: float, mu_common: float) -> float:
    return beta + phi * (mu_common - mu_base)


def gh_grid(mu_center: float, sigma_theta: float):
    """Probabilist Gauss-Hermite nodes/weights for N(mu_center, sigma_theta^2).

    Returns (mu_nodes, probability_weights) with weights summing to 1.
    sigma_theta == 0 degenerates to a single point mass at the center.
    """
    if sigma_theta <= 0:
        return np.array([mu_center]), np.array([1.0])
    x, w = hermegauss(GH_NODES)
    mu_nodes = mu_center + sigma_theta * x
    pw = w / np.sqrt(2.0 * np.pi)
    pw = pw / pw.sum()
    return mu_nodes, pw


def payoff(mu, beta, phi, mu_base):
    return beta + phi * (mu - mu_base)


def p_urban(delta_payoff, kappa, s):
    """Logistic choice probability; s is the logistic scale of eta."""
    return expit((delta_payoff - kappa) / s)


def sigma_eta_from_scale(s: float) -> float:
    """SD of a Logistic(0, s) shock."""
    return s * np.pi / np.sqrt(3.0)


# --------------------------------------------------------------------------
# Modeled never share (the anchoring moment) under Reading A
# --------------------------------------------------------------------------
def modeled_never_share(s, cell, bal, kappa, sigma_theta, beta, phi, mu_base, T):
    """Person-level never share = sum_d pi_d E_Gd[(1 - P_base)^T], with the
    baseline barrier kappa in the index. d_T contributes 0 (always urban)."""
    total = 0.0
    for _, row in bal.iterrows():
        pi = row["pi_bal"]
        if row["is_dT"] or not np.isfinite(row["mu_d"]):
            continue  # always-urban mass: never contribution = 0
        mu_nodes, pw = gh_grid(row["mu_d"], sigma_theta)
        dp = payoff(mu_nodes, beta, phi, mu_base)
        pu = p_urban(dp, kappa, s)
        never_prob = (1.0 - pu) ** T
        total += pi * float(np.dot(pw, never_prob))
    return total


def attainable_never_range(cell, bal, kappa, sigma_theta, beta, phi, mu_base, T):
    """Never-share limits as s -> 0+ and s -> inf (the i.i.d. ceiling)."""
    lo = modeled_never_share(1e-6, cell, bal, kappa, sigma_theta,
                             beta, phi, mu_base, T)
    hi = modeled_never_share(1e6, cell, bal, kappa, sigma_theta,
                             beta, phi, mu_base, T)
    return lo, hi


def anchor_scale(target, cell, bal, kappa, sigma_theta, beta, phi, mu_base, T):
    """Brent root-find on the logistic scale s so modeled never == target.

    Returns (s, sigma_eta, status). status flags whether target is interior
    to the attainable range and whether the root is unique on a coarse scan.
    """
    def f(s):
        return modeled_never_share(s, cell, bal, kappa, sigma_theta,
                                   beta, phi, mu_base, T) - target

    s_lo, s_hi = 1e-4, 1e4
    n_lo = f(s_lo) + target
    n_hi = f(s_hi) + target
    interior = min(n_lo, n_hi) <= target <= max(n_lo, n_hi)
    if not interior:
        return None, None, f"INFEASIBLE: target {target:.4f} outside " \
                            f"attainable [{min(n_lo, n_hi):.4f}, " \
                            f"{max(n_lo, n_hi):.4f}]"
    # coarse scan for sign changes (root uniqueness)
    grid = np.geomspace(s_lo, s_hi, 60)
    vals = np.array([f(s) for s in grid])
    sign_changes = int(np.sum(np.diff(np.sign(vals)) != 0))
    s_star = brentq(f, s_lo, s_hi, xtol=1e-8, rtol=1e-10)
    status = "ok" if sign_changes == 1 else f"WARN: {sign_changes} sign changes"
    return s_star, sigma_eta_from_scale(s_star), status


# --------------------------------------------------------------------------
# Scenario evaluation: realized effect and unrealized potential
# --------------------------------------------------------------------------
def evaluate_scenario(scenario, c, cell_rh, cell_uh, bal, mu_common,
                      sigma_theta, target, T):
    """One (scenario, c) cell. Anchors s jointly with c on the BASELINE
    (rh schedule + barrier), then evaluates the counterfactual.

    Returns a dict of computed quantities (all finite-checked)."""
    beta_rh, phi_rh, mu_base_rh = cell_rh["beta"], cell_rh["phi"], cell_rh["mu_base"]
    beta_uh, phi_uh, mu_base_uh = cell_uh["beta"], cell_uh["phi"], cell_uh["mu_base"]

    bt_rh = beta_tilde(beta_rh, phi_rh, mu_base_rh, mu_common)
    bt_uh = beta_tilde(beta_uh, phi_uh, mu_base_uh, mu_common)
    wedge = bt_uh - bt_rh
    kappa = c * wedge

    # Anchor sigma_eta on the observed (baseline) world: rh schedule + barrier.
    s_star, sigma_eta, status = anchor_scale(
        target, cell_rh, bal, kappa, sigma_theta,
        beta_rh, phi_rh, mu_base_rh, T
    )
    out = {
        "scenario": scenario, "c": c, "mu_common_tag": None,
        "wedge": wedge, "kappa": kappa, "sigma_eta": sigma_eta,
        "anchor_status": status,
    }
    if s_star is None:
        out.update(realized=np.nan, unrealized=np.nan,
                   modeled_never=np.nan, switcher_share=np.nan)
        return out

    # Counterfactual schedule depends on scenario.
    if scenario == "barrier-only":
        beta_cf, phi_cf, mu_base_cf = beta_rh, phi_rh, mu_base_rh
    else:  # regime-convergence: rh workers adopt the uh schedule
        beta_cf, phi_cf, mu_base_cf = beta_uh, phi_uh, mu_base_uh

    realized = 0.0
    unrealized = 0.0
    modeled_never = 0.0
    switcher_mass = 0.0
    for _, row in bal.iterrows():
        pi = row["pi_bal"]
        if row["is_dT"] or not np.isfinite(row["mu_d"]):
            continue
        mu_nodes, pw = gh_grid(row["mu_d"], sigma_theta)

        # Baseline = observed world: rh schedule, barrier present.
        dp_base = payoff(mu_nodes, beta_rh, phi_rh, mu_base_rh)
        p_base = p_urban(dp_base, kappa, s_star)

        # Counterfactual: barrier removed, scenario schedule.
        dp_cf = payoff(mu_nodes, beta_cf, phi_cf, mu_base_cf)
        p_cf = p_urban(dp_cf, 0.0, s_star)

        # Realized effect: probability-weighted signed payoff change (M8/M9).
        realized += pi * float(np.dot(pw, dp_cf * (p_cf - p_base)))
        # Unrealized potential: positive payoff still not taken up (M8).
        unrealized += pi * float(np.dot(pw, (1.0 - p_cf) * np.maximum(dp_cf, 0.0)))

        modeled_never += pi * float(np.dot(pw, (1.0 - p_base) ** T))
        # one-period switcher proxy: P(at least one urban) - P(all urban)
        switcher_mass += pi * float(
            np.dot(pw, (1.0 - (1.0 - p_base) ** T) - p_base ** T)
        )

    out.update(realized=realized, unrealized=unrealized,
               modeled_never=modeled_never, switcher_share=switcher_mass)
    return out


# --------------------------------------------------------------------------
# Driver
# --------------------------------------------------------------------------
def main():
    cell_rh = load_cell("CHN_rf")
    cell_uh = load_cell("CHN_uf")
    bal = balanced_trajectories(cell_rh)

    n_total = bal["n_pids"].sum()
    never_share_obs = bal.loc[bal["is_never"], "n_pids"].sum() / n_total
    dT_share = bal.loc[bal["is_dT"], "n_pids"].sum() / n_total
    switch_share_obs = 1.0 - never_share_obs - dT_share

    print("=" * 74)
    print("E2 V2 Step 1.5 prototype --- CHN rural-hukou point estimates")
    print("=" * 74)
    print(f"rh: beta={cell_rh['beta']:.5f} phi={cell_rh['phi']:.5f} "
          f"base_traj={cell_rh['base_traj']} mu_base={cell_rh['mu_base']:.5f}")
    print(f"uh: beta={cell_uh['beta']:.5f} phi={cell_uh['phi']:.5f} "
          f"base_traj={cell_uh['base_traj']} mu_base={cell_uh['mu_base']:.5f}")
    print(f"balanced rh persons={int(n_total)}  "
          f"never={never_share_obs:.4f}  switch={switch_share_obs:.4f}  "
          f"always-urban={dT_share:.4f}")

    # mu_common candidates (plan Step 1, review G1).
    never_rh = float(cell_rh["df"].query("traj_for_agg == 1")["mu_d"].iloc[0])
    never_uh = float(cell_uh["df"].query("traj_for_agg == 1")["mu_d"].iloc[0])
    n_rh = float(cell_rh["df"].query("traj_for_agg == 1")["n_pids"].iloc[0])
    n_uh = float(cell_uh["df"].query("traj_for_agg == 1")["n_pids"].iloc[0])
    pooled_never = (n_rh * never_rh + n_uh * never_uh) / (n_rh + n_uh)
    mu_common_opts = {
        "pooled_never": pooled_never,
        "rh_base": cell_rh["mu_base"],
        "uh_base": cell_uh["mu_base"],
    }
    print("\nmu_common candidates and the resulting common-base wedge "
          "(beta_tilde_uh - beta_tilde_rh):")
    for tag, mc in mu_common_opts.items():
        bt_rh = beta_tilde(cell_rh["beta"], cell_rh["phi"], cell_rh["mu_base"], mc)
        bt_uh = beta_tilde(cell_uh["beta"], cell_uh["phi"], cell_uh["mu_base"], mc)
        print(f"  {tag:13s} mu_common={mc:.5f}  bt_rh={bt_rh:.5f}  "
              f"bt_uh={bt_uh:.5f}  wedge={bt_uh - bt_rh:+.5f}")

    rows = []
    headline_target = 0.6543
    headline_sigma_theta = 0.4
    for mc_tag, mc in mu_common_opts.items():
        for scen in ("barrier-only", "regime-convergence"):
            for c in C_GRID:
                r = evaluate_scenario(scen, c, cell_rh, cell_uh, bal, mc,
                                      headline_sigma_theta, headline_target,
                                      T_PANEL)
                r["mu_common_tag"] = mc_tag
                r["sigma_theta"] = headline_sigma_theta
                r["never_target"] = headline_target
                rows.append(r)

    res = pd.DataFrame(rows)

    print("\n" + "=" * 74)
    print(f"HEADLINE: sigma_theta={headline_sigma_theta}, "
          f"never_target={headline_target}, logit, T={T_PANEL}")
    print("=" * 74)
    show = res[["mu_common_tag", "scenario", "c", "wedge", "kappa",
                "sigma_eta", "realized", "unrealized", "modeled_never",
                "anchor_status"]]
    with pd.option_context("display.width", 200,
                           "display.max_columns", None,
                           "display.float_format", lambda v: f"{v:.4f}"):
        print(show.to_string(index=False))

    # Sensitivity of feasibility + headline to sigma_theta and never target,
    # under the mu_common that makes the anchor feasible at c<=1.
    print("\n" + "=" * 74)
    print("FEASIBILITY SWEEP (mu_common = rh_base; barrier-only; c=1)")
    print("=" * 74)
    mc = mu_common_opts["rh_base"]
    for tgt in NEVER_TARGET_SWEEP:
        for st in SIGMA_THETA_SWEEP:
            r = evaluate_scenario("barrier-only", 1.0, cell_rh, cell_uh, bal,
                                  mc, st, tgt, T_PANEL)
            print(f"  target={tgt:.4f} sigma_theta={st:.1f}  "
                  f"sigma_eta={_fmt(r['sigma_eta'])}  "
                  f"realized={_fmt(r['realized'])}  "
                  f"unrealized={_fmt(r['unrealized'])}  "
                  f"[{r['anchor_status']}]")

    # Regime-convergence pole check: it adopts phi_uh = -0.973 (near -1).
    print("\n" + "=" * 74)
    print("POLE CHECK: regime-convergence at the uh point estimate "
          f"(phi_uh={cell_uh['phi']:.4f})")
    print("=" * 74)
    mc = mu_common_opts["rh_base"]
    for c in C_GRID:
        r = evaluate_scenario("regime-convergence", c, cell_rh, cell_uh, bal,
                              mc, headline_sigma_theta, headline_target, T_PANEL)
        finite = np.isfinite([r["realized"], r["unrealized"]]).all()
        print(f"  c={c:.1f}  realized={_fmt(r['realized'])}  "
              f"unrealized={_fmt(r['unrealized'])}  "
              f"finite={finite}  [{r['anchor_status']}]")

    out_csv = HERE / "proto_e2v2_step1p5_results.csv"
    res.to_csv(out_csv, index=False)
    print(f"\nWrote {out_csv}")


def _fmt(x):
    return "  nan " if x is None or (isinstance(x, float) and np.isnan(x)) \
        else f"{x:+.4f}"


if __name__ == "__main__":
    main()
