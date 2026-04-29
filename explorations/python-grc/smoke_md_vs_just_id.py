"""Smoke test: compare grid_md_inversion against grid_lca_inversion
(just-identified) on IDN, all 5 specs.

The two test the same null at the same dof, but MD is at least as
efficient: its concentrated-out beta_md(phi) pools across all
switchers via GLS, while the just-identified version pins beta to
beta_base_OLS. Expect:

* MD CI is at least as tight as just-identified.
* MD beta_md(phi_hat) is closer to GMM's beta than beta_base_OLS is.

Output: smoke_md_vs_just_id.md in results/.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import (
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_lca_inversion,
    grid_md_inversion,
)
from run_all_countries_inversion import _spec_controls

HERE = Path(__file__).resolve().parent
RERUN = HERE / "rerun_workdir"
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


def _gmm_beta_for(country: str, spec: str) -> float | None:
    """Pull GMM's Delta_base for (country, spec) from the local CSV."""
    p = RERUN / "published_gmm_internals.csv"
    if not p.exists():
        return None
    df = pd.read_csv(p)
    row = df[(df["country"] == country) & (df["spec"] == spec)]
    if row.empty:
        return None
    val = row["Delta_base"].iloc[0]
    return float(val) if pd.notna(val) else None


def main():
    country = "IDN"
    df = load_consumption_unb(country)
    period_cols = period_fe_columns(df)
    kept, _ = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=5
    )
    base = 2 if 2 in kept else kept[0]

    phi_grid = np.arange(-3.0, 1.0001, 0.01)
    rows: list[dict] = []

    for spec in ["covs_0", "covs_trend", "covs_1", "covs_2", "covs_all"]:
        controls = _spec_controls(spec, period_cols)
        cols_needed = [
            "lndepvar", "choice", "trajectory", "pid",
            "unbalanced", "unbalanced_choice",
        ] + controls
        sub = df.dropna(subset=[c for c in cols_needed if c != "trajectory"]).copy()
        fit = fit_auxiliary_ols(
            sub, outcome="lndepvar", trajectory="trajectory",
            choice="choice", hhid="pid",
            switchers_kept=kept, controls=controls,
        )

        # Just-identified
        ji_curve, ji_lo, ji_hi = grid_lca_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.05,
        )
        i_min = int(ji_curve["wald"].idxmin())
        ji_phi_min = float(ji_curve["phi"].iloc[i_min])
        beta_base_ols = float(fit.b[fit.idx(f"beta[{base}]")])

        # Minimum-distance
        md_curve, md_lo, md_hi = grid_md_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.05,
        )
        j_min = int(md_curve["wald"].idxmin())
        md_phi_min = float(md_curve["phi"].iloc[j_min])
        md_beta_min = float(md_curve["beta_md"].iloc[j_min])

        gmm_beta = _gmm_beta_for(country, spec)

        rows.append({
            "spec": spec,
            "ji_phi_min": ji_phi_min,
            "ji_ci95": (ji_lo, ji_hi),
            "ji_ci95_w": (ji_hi - ji_lo) if not np.isnan(ji_lo) else float("nan"),
            "md_phi_min": md_phi_min,
            "md_beta_min": md_beta_min,
            "md_ci95": (md_lo, md_hi),
            "md_ci95_w": (md_hi - md_lo) if not np.isnan(md_lo) else float("nan"),
            "beta_base_ols": beta_base_ols,
            "gmm_beta": gmm_beta,
            "ji_beta_minus_gmm": (
                beta_base_ols - gmm_beta
                if gmm_beta is not None else float("nan")
            ),
            "md_beta_minus_gmm": (
                md_beta_min - gmm_beta
                if gmm_beta is not None else float("nan")
            ),
        })

    out = pd.DataFrame(rows)
    out.to_csv(OUTDIR / "smoke_md_vs_just_id.csv", index=False)

    md_lines = [
        "# MD vs just-identified phi inversion: IDN smoke\n",
        "Both procedures test the same LCA null at chi^2_{|S|-1} dof.",
        "MD differs by concentrating out a free LCA intercept beta",
        "across all switchers via GLS, instead of pinning beta to the",
        "base switcher's OLS coefficient.\n",
        "## Per-spec comparison",
        "",
        "| Spec | JI phi_min | JI 95% CI | width | MD phi_min | MD 95% CI | width | beta_OLS | beta_MD | beta_GMM | beta_OLS-GMM | beta_MD-GMM |",
        "|---|---:|---|---:|---:|---|---:|---:|---:|---:|---:|---:|",
    ]
    for r in rows:
        ji = (
            f"[{r['ji_ci95'][0]:.3f}, {r['ji_ci95'][1]:.3f}]"
            if not np.isnan(r["ji_ci95"][0]) else "empty"
        )
        md = (
            f"[{r['md_ci95'][0]:.3f}, {r['md_ci95'][1]:.3f}]"
            if not np.isnan(r["md_ci95"][0]) else "empty"
        )
        gmm_b = (
            f"{r['gmm_beta']:+.4f}"
            if r["gmm_beta"] is not None else "n/a"
        )
        md_lines.append(
            f"| {r['spec']} | {r['ji_phi_min']:+.3f} | {ji} | "
            f"{r['ji_ci95_w']:.3f} | {r['md_phi_min']:+.3f} | "
            f"{md} | {r['md_ci95_w']:.3f} | "
            f"{r['beta_base_ols']:+.4f} | {r['md_beta_min']:+.4f} | "
            f"{gmm_b} | {r['ji_beta_minus_gmm']:+.4f} | "
            f"{r['md_beta_minus_gmm']:+.4f} |"
        )

    md_path = OUTDIR / "smoke_md_vs_just_id.md"
    md_path.write_text("\n".join(md_lines) + "\n")
    print(f"Wrote {md_path}")
    print(out.to_string(index=False))


if __name__ == "__main__":
    main()
