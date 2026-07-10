"""Validation gate for the delta-inversion extension (spec 2026-04-29).

For each (country, spec), check whether the auxiliary-OLS-derived

    Delta_never(phi_hat, b)   = beta_base + phi_hat * (alpha_never - alpha_base)
    Delta_avg(phi_hat, b)     = beta_base + phi_hat * sum_s pi_s (alpha_s - alpha_base)
    Delta_always(phi_hat, b)  = (beta_base + phi_hat * (alpha_always - alpha_base))
                                / (1 + phi_hat)

reproduces Stata's published nlcom point estimate (loaded from
``rerun_workdir/published_deltas.csv``) at the GMM's phi_hat (loaded from
``rerun_workdir/{idn,chn_tza}_fresh_phi.csv``).

This is the precondition gate from the spec: if any (country, spec, delta)
fails to match within sub-percent, the auxiliary-OLS-vs-GMM controls
partialling differs and the inversion procedure needs to revisit how
shares / mu's are constructed before any inversion CI is reported.

Output: ``results/validate_delta_points.md`` with a per-(country, spec)
summary, and ``results/validate_delta_points.csv`` with the long-format
match table.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import (
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_md_inversion,
)
from run_all_countries_inversion import _spec_controls

HERE = Path(__file__).resolve().parent
RERUN = HERE / "rerun_workdir"
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


def _load_phi_hat() -> dict[tuple[str, str], float]:
    """Load phi_hat per (country, spec) from the two rerun CSVs."""
    out: dict[tuple[str, str], float] = {}
    idn = pd.read_csv(RERUN / "idn_fresh_phi.csv")
    for _, r in idn.iterrows():
        out[("IDN", r["spec"])] = float(r["phi"])
    other = pd.read_csv(RERUN / "chn_tza_fresh_phi.csv")
    for _, r in other.iterrows():
        out[(r["country"], r["spec"])] = float(r["phi"])
    return out


def _load_gmm_internals() -> dict[tuple[str, str], dict]:
    out: dict[tuple[str, str], dict] = {}
    p = RERUN / "published_gmm_internals.csv"
    if not p.exists():
        return out
    df = pd.read_csv(p)
    for _, r in df.iterrows():
        out[(r["country"], r["spec"])] = {
            "phi": float(r["phi"]) if pd.notna(r["phi"]) else None,
            "Delta_base": float(r["Delta_base"]) if pd.notna(r["Delta_base"]) else None,
            "kappa": float(r["kappa"]) if pd.notna(r["kappa"]) else None,
            "mu_never": float(r["mu_never"]) if pd.notna(r["mu_never"]) else None,
        }
    return out


def _python_deltas(
    country: str, spec: str, phi_hat: float
) -> dict[str, float | None]:
    """Compute (Delta_never, Delta_avg, Delta_always) at phi_hat from the
    auxiliary OLS, plus the implied trajectory codes used.

    Returns NaNs and a diagnostic message if base 2 was dropped or the
    spec is otherwise degenerate.
    """
    df = load_consumption_unb(country)
    period_cols = period_fe_columns(df)
    controls = _spec_controls(spec, period_cols)

    cols_needed = [
        "lndepvar", "choice", "trajectory", "pid",
        "unbalanced", "unbalanced_choice",
    ] + controls
    sub = df.dropna(subset=[c for c in cols_needed if c != "trajectory"]).copy()

    kept, _ = drop_sparse_switchers(
        sub, "trajectory", "choice", "pid", threshold=5
    )
    if 2 not in kept:
        # Stata uses base 2; if it's been dropped, the comparison is
        # not apples-to-apples. Flag and skip.
        return {
            "delta_never": float("nan"),
            "delta_avg": float("nan"),
            "delta_always": float("nan"),
            "n_obs": int(len(sub)),
            "note": f"base 2 dropped; kept={kept}",
        }
    base = 2

    fit = fit_auxiliary_ols(
        sub, outcome="lndepvar", trajectory="trajectory",
        choice="choice", hhid="pid",
        switchers_kept=kept, controls=controls,
    )

    trajectories = sorted(int(t) for t in sub["trajectory"].dropna().unique())
    never_traj, always_traj = trajectories[0], trajectories[-1]

    a_base = fit.b[fit.idx(f"alpha[{base}]")]
    b_base = fit.b[fit.idx(f"beta[{base}]")]
    a_never = fit.b[fit.idx(f"alpha[{never_traj}]")]
    a_always = fit.b[fit.idx(f"alpha[{always_traj}]")]

    n_total = int(len(sub))
    sw_mask = sub["trajectory"].isin(kept)
    n_sw = int(sw_mask.sum())
    sw_frac = n_sw / n_total

    # Two share conventions, matching the spec's eq (3') vs Stata's
    # actual nlcom in 0_programs.do:1797--1812. Stata's `num_s` comes
    # from `sum 1.switcher_s if e(sample); local num_s = r(mean)`,
    # which is N_s / N_total -- an over-all-sample share that sums
    # to sw_frac, not 1.
    pi_within = {
        s: float((sub["trajectory"] == s).sum()) / n_sw for s in kept
    }
    pi_overall = {
        s: float((sub["trajectory"] == s).sum()) / n_total for s in kept
    }
    weighted_dev_within = sum(
        pi_within[s] * (fit.b[fit.idx(f"alpha[{s}]")] - a_base)
        for s in kept
    )
    weighted_dev_overall = sum(
        pi_overall[s] * (fit.b[fit.idx(f"alpha[{s}]")] - a_base)
        for s in kept
    )

    # Compute MD's beta_md at phi_hat. This pools beta across all
    # switchers via GLS rather than pinning it to beta_base_OLS, so
    # the resulting Delta_X values should match Stata's GMM nlcom to
    # fractions of a percent (vs the 1-7 pp OLS-vs-GMM gap when using
    # b_base directly).
    md_curve, _, _ = grid_md_inversion(
        fit, switchers_kept=kept, base=base,
        phi_grid=np.array([phi_hat]),
    )
    b_md = float(md_curve["beta_md"].iloc[0])

    delta_never = b_base + phi_hat * (a_never - a_base)
    delta_never_md = b_md + phi_hat * (a_never - a_base)
    # Spec's eq (3'): within-switcher shares.
    delta_avg_within = b_base + phi_hat * weighted_dev_within
    delta_avg_within_md = b_md + phi_hat * weighted_dev_within
    # Stata's actual formula: over-all shares times the whole bracket,
    # i.e. sw_frac * Delta_base + phi * sum_s pi_overall_s * (a_s - a_base).
    delta_avg_overall = (
        sw_frac * b_base + phi_hat * weighted_dev_overall
    )
    one_plus_phi = 1.0 + phi_hat
    if abs(one_plus_phi) < 1e-8:
        delta_always = float("nan")
        delta_always_md = float("nan")
        note = f"phi_hat ~ -1 (1+phi={one_plus_phi:.2e}); always undefined"
    else:
        delta_always = (b_base + phi_hat * (a_always - a_base)) / one_plus_phi
        delta_always_md = (b_md + phi_hat * (a_always - a_base)) / one_plus_phi
        note = ""

    return {
        "delta_never": float(delta_never),
        "delta_never_md": float(delta_never_md),
        "delta_avg": float(delta_avg_within),
        "delta_avg_md": float(delta_avg_within_md),
        "delta_avg_overall": float(delta_avg_overall),
        "delta_always": float(delta_always),
        "delta_always_md": float(delta_always_md),
        "alpha_base": float(a_base),
        "alpha_never": float(a_never),
        "alpha_always": float(a_always),
        "beta_base_ols": float(b_base),
        "beta_md": float(b_md),
        "n_obs": int(fit.n_obs),
        "n_switchers": n_sw,
        "switcher_frac": float(sw_frac),
        "note": note,
        "never_traj": never_traj,
        "always_traj": always_traj,
        "switchers_kept": kept,
    }


def main():
    phi_hat = _load_phi_hat()
    pub = pd.read_csv(RERUN / "published_deltas.csv")
    gmm = _load_gmm_internals()

    rows: list[dict] = []
    decompose: list[dict] = []
    for country in ["IDN", "CHN", "TZA"]:
        for spec in ["covs_0", "covs_trend", "covs_1", "covs_2", "covs_all"]:
            ph = phi_hat.get((country, spec))
            if ph is None:
                continue
            print(f"\n{country}/{spec}: phi_hat={ph:+.4f}")
            res = _python_deltas(country, spec, ph)
            if res.get("note"):
                print(f"  note: {res['note']}")
            print(
                f"  switcher_frac={res['switcher_frac']:.4f}  "
                f"beta_base_OLS={res['beta_base_ols']:+.5f}  "
                f"alpha_base={res['alpha_base']:+.4f}  "
                f"alpha_never={res['alpha_never']:+.4f}"
            )
            internals = gmm.get((country, spec))
            if internals:
                gmm_beta = internals.get("Delta_base")
                gmm_mu_never = internals.get("mu_never")
                ols_beta = res["beta_base_ols"]
                if gmm_beta is not None:
                    print(
                        f"  beta_base GMM={gmm_beta:+.5f}  "
                        f"OLS-GMM diff={ols_beta - gmm_beta:+.5f}"
                    )
                decompose.append({
                    "country": country, "spec": spec,
                    "phi_hat": ph,
                    "switcher_frac": res["switcher_frac"],
                    "beta_OLS": ols_beta,
                    "beta_GMM": gmm_beta,
                    "alpha_base_OLS": res["alpha_base"],
                    "alpha_never_OLS": res["alpha_never"],
                    "alpha_always_OLS": res["alpha_always"],
                    "mu_never_GMM": gmm_mu_never,
                    "kappa_GMM": internals.get("kappa"),
                })

            for delta_name, py_key in [
                ("never", "delta_never"),
                ("never_md", "delta_never_md"),
                ("avg", "delta_avg"),
                ("avg_md", "delta_avg_md"),
                ("avg_overall", "delta_avg_overall"),
                ("always", "delta_always"),
                ("always_md", "delta_always_md"),
            ]:
                # Map MD/overall variants back to the published delta key.
                pub_delta_key = (
                    delta_name.split("_")[0]
                    if delta_name in {
                        "never_md", "avg_md", "always_md",
                        "avg_overall",
                    }
                    else delta_name
                )
                stata_row = pub[
                    (pub["country"] == country)
                    & (pub["spec"] == spec)
                    & (pub["delta"] == pub_delta_key)
                ]
                if stata_row.empty:
                    continue
                stata_pt = float(stata_row["point"].iloc[0])
                py_pt = res[py_key]
                if np.isnan(py_pt) or np.isnan(stata_pt):
                    abs_err = float("nan")
                    rel_err = float("nan")
                else:
                    abs_err = float(py_pt - stata_pt)
                    denom = max(abs(stata_pt), 1e-6)
                    rel_err = float(abs_err / denom)
                rows.append({
                    "country": country,
                    "spec": spec,
                    "delta": delta_name,
                    "phi_hat": ph,
                    "stata_point": stata_pt,
                    "python_point": py_pt,
                    "abs_err": abs_err,
                    "rel_err": rel_err,
                    "note": res.get("note", ""),
                })
                flag = ""
                if not np.isnan(rel_err):
                    if abs(rel_err) > 0.01:
                        flag = "  *** > 1% ***"
                    elif abs(rel_err) > 0.001:
                        flag = "  ** > 0.1% **"
                print(
                    f"  {delta_name:7s}  Stata {stata_pt:+.5f}  "
                    f"Py {py_pt:+.5f}  rel {rel_err:+.4%}{flag}"
                )

    out = pd.DataFrame(rows)
    csv_path = OUTDIR / "validate_delta_points.csv"
    out.to_csv(csv_path, index=False)
    print(f"\nWrote {csv_path}")

    if decompose:
        dec_df = pd.DataFrame(decompose)
        dec_path = OUTDIR / "validate_delta_decomposition.csv"
        dec_df.to_csv(dec_path, index=False)
        print(f"Wrote {dec_path}")

    md = ["# Delta point-estimate validation (precondition gate)\n"]
    md.append(
        "Spec: `quality_reports/specs/2026-04-29-delta-inversion-extension.md`. "
        "Compares Python's auxiliary-OLS-derived "
        "$\\Delta_X(\\hat\\phi, b)$ against Stata's published `nlcom` point "
        "estimate at the GMM's $\\hat\\phi$. Inversion CIs are not reported "
        "for any (country, spec, delta) with relative error above 1%.\n"
    )
    md.append("## Per-(country, spec, delta) match\n")
    md.append("| Country | Spec | Delta | $\\hat\\phi$ | "
              "Stata point | Python point | Rel error | Flag |")
    md.append("|---|---|---|---:|---:|---:|---:|---|")
    for r in rows:
        if np.isnan(r["rel_err"]):
            rel_str = "nan"
            flag = "skip"
        else:
            rel_str = f"{r['rel_err']:+.3%}"
            if abs(r["rel_err"]) > 0.01:
                flag = "FAIL"
            elif abs(r["rel_err"]) > 0.001:
                flag = "warn"
            else:
                flag = "ok"
        md.append(
            f"| {r['country']} | {r['spec']} | {r['delta']} | "
            f"{r['phi_hat']:+.4f} | {r['stata_point']:+.5f} | "
            f"{r['python_point']:+.5f} | {rel_str} | {flag} |"
        )

    md.append("\n## Summary by (country, spec)\n")
    md.append("| Country | Spec | Max abs rel error | Worst delta | Verdict |")
    md.append("|---|---|---:|---|---|")
    for (c, s), grp in out.groupby(["country", "spec"], sort=False):
        valid = grp.dropna(subset=["rel_err"])
        if valid.empty:
            md.append(f"| {c} | {s} | --- | --- | skip (no valid match) |")
            continue
        i_max = valid["rel_err"].abs().idxmax()
        worst = valid.loc[i_max]
        verdict = (
            "FAIL" if abs(worst["rel_err"]) > 0.01
            else ("warn" if abs(worst["rel_err"]) > 0.001 else "PASS")
        )
        md.append(
            f"| {c} | {s} | {worst['rel_err']:+.3%} | "
            f"{worst['delta']} | {verdict} |"
        )

    md_path = OUTDIR / "validate_delta_points.md"
    md_path.write_text("\n".join(md) + "\n")
    print(f"Wrote {md_path}")


if __name__ == "__main__":
    main()
