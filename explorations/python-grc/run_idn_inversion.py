"""Run the LCA inversion on IDN/cons/urban/unb across covariate specs and
build the side-by-side comparison against the GMM sandwich CIs.

Covariate specs match 5_GrRC.do:42-44, 94-125:
* covs_0     : no covariates beyond unbalanced shifters
* covs_trend : + period FE
* covs_1     : + period FE + female
* covs_2     : + period FE + female + age2
* covs_all   : + period FE + female + age2 + education_max + education_max2

Reports both 90% and 95% CIs from (a) the LCA inversion and (b) the GMM
sandwich. GMM phi/SE values are loaded from idn_fresh_phi.csv if it exists
(produced by rerun_idn_5gr.do); otherwise falls back to hand-extracted
values from output/tables/GRC_IDN_consumption_urban_unb.tex.
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
)


HERE = Path(__file__).resolve().parent
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


def main():
    df = load_consumption_unb("IDN")
    period_cols = period_fe_columns(df)
    print(f"Loaded {len(df):,} rows, {df['pid'].nunique():,} unique pids")
    print(f"Period dummies available: {period_cols}")

    kept, counts = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=5
    )
    dropped = sorted(s for s, n in counts.items() if n < 5)
    print(f"Switcher candidates: {len(counts)}, kept: {len(kept)}, dropped: {dropped}")
    print(f"  J_R (number of restrictions) = {len(kept) - 1}")

    if 2 not in kept:
        raise RuntimeError(f"base = 2 not among kept switchers: {kept}")
    base = 2

    # Spec names match 5_GrRC.do:42-44, 94-125
    specs = {
        "covs_0":     [],
        "covs_trend": list(period_cols),
        "covs_1":     list(period_cols) + ["female"],
        "covs_2":     list(period_cols) + ["female", "age2"],
        "covs_all":   list(period_cols) + ["female", "age2",
                                            "education_max", "education_max2"],
    }

    # Fine grid covering all observed CI ranges across specs.
    phi_grid = np.arange(-3.0, 1.0001, 0.01)

    # Hand-extracted GMM values from output/tables/GRC_IDN_consumption_urban_unb.tex.
    # Used as a fallback if the fresh rerun output isn't available.
    table_gmm = {
        "covs_0":     {"phi": -2.445, "se": 0.070},
        "covs_trend": {"phi": -0.309, "se": 0.087},
        "covs_1":     {"phi": -0.310, "se": 0.087},
        "covs_2":     {"phi": -0.321, "se": 0.086},
        "covs_all":   {"phi": -0.526, "se": 0.102},
    }
    fresh_gmm_path = (HERE / "rerun_workdir" / "idn_fresh_phi.csv")
    if fresh_gmm_path.exists():
        fresh = pd.read_csv(fresh_gmm_path)
        gmm_lookup = {row["spec"]: {"phi": row["phi"], "se": row["phi_se"]}
                      for _, row in fresh.iterrows()
                      if pd.notna(row.get("phi"))}
        gmm_source = "rerun_workdir/idn_fresh_phi.csv (fresh)"
    else:
        gmm_lookup = table_gmm
        gmm_source = "output/tables/GRC_IDN_consumption_urban_unb.tex (hand-extracted)"
    print(f"\nGMM source: {gmm_source}")

    rows = []
    for spec_name, controls in specs.items():
        # Skip rows with NaN in any control before fitting.
        cols_needed = ["lndepvar", "choice", "trajectory", "pid",
                       "unbalanced", "unbalanced_choice"] + controls
        sub = df.dropna(subset=[c for c in cols_needed
                                 if c != "trajectory"]).copy()
        n_drop = len(df) - len(sub)
        print(f"\n[{spec_name}] controls = {controls}")
        print(f"  dropped {n_drop} rows with missing controls; n = {len(sub)}")

        try:
            fit = fit_auxiliary_ols(
                sub,
                outcome="lndepvar",
                trajectory="trajectory",
                choice="choice",
                hhid="pid",
                switchers_kept=kept,
                controls=controls,
            )
        except Exception as e:
            print(f"  OLS failed: {e}")
            continue

        print(f"  aux OLS: p={len(fit.b)} params, n={fit.n_obs:,}, "
              f"G={fit.n_clusters:,}")

        curve, ci95_lo, ci95_hi = grid_lca_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.05,
        )
        _, ci90_lo, ci90_hi = grid_lca_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.10,
        )

        wald_min = curve["wald"].min()
        phi_at_min = curve.loc[curve["wald"].idxmin(), "phi"]
        p_at_min = curve.loc[curve["wald"].idxmin(), "p_value"]
        print(f"  Wald min = {wald_min:.2f} at phi = {phi_at_min:.3f} "
              f"(p = {p_at_min:.4f})")
        for level, lo, hi in [("90", ci90_lo, ci90_hi), ("95", ci95_lo, ci95_hi)]:
            print(f"  {level}% CI inv: "
                  f"[{lo if not np.isnan(lo) else 'empty':>8}, "
                  f"{hi if not np.isnan(hi) else 'empty':>8}]")

        gmm = gmm_lookup.get(spec_name, {"phi": np.nan, "se": np.nan})
        gmm_phi, gmm_se = gmm["phi"], gmm["se"]
        gmm_ci95 = (gmm_phi - 1.96 * gmm_se, gmm_phi + 1.96 * gmm_se)
        gmm_ci90 = (gmm_phi - 1.645 * gmm_se, gmm_phi + 1.645 * gmm_se)
        print(f"  GMM phi = {gmm_phi:.3f} (SE {gmm_se:.3f})")
        print(f"  90% CI sandwich: [{gmm_ci90[0]:.3f}, {gmm_ci90[1]:.3f}]")
        print(f"  95% CI sandwich: [{gmm_ci95[0]:.3f}, {gmm_ci95[1]:.3f}]")

        curve.to_parquet(OUTDIR / f"lca_inversion_idn_{spec_name}.parquet")

        rows.append({
            "spec": spec_name,
            "n_obs": fit.n_obs,
            "n_clusters": fit.n_clusters,
            "n_params": len(fit.b),
            "J_R": len(kept) - 1,
            "wald_min": wald_min,
            "phi_at_wald_min": phi_at_min,
            "p_at_wald_min": p_at_min,
            "inv_ci90_lo": ci90_lo,
            "inv_ci90_hi": ci90_hi,
            "inv_ci95_lo": ci95_lo,
            "inv_ci95_hi": ci95_hi,
            "gmm_phi": gmm_phi,
            "gmm_se": gmm_se,
            "gmm_ci90_lo": gmm_ci90[0],
            "gmm_ci90_hi": gmm_ci90[1],
            "gmm_ci95_lo": gmm_ci95[0],
            "gmm_ci95_hi": gmm_ci95[1],
        })

    summary = pd.DataFrame(rows)
    summary.to_csv(OUTDIR / "lca_inversion_idn_summary.csv", index=False)
    print(f"\nSummary saved to {OUTDIR / 'lca_inversion_idn_summary.csv'}")
    print(summary.to_string(index=False, float_format="%.3f"))

    # Markdown comparison table for the writeup.
    md_path = OUTDIR / "lca_inversion_idn_comparison.md"
    with open(md_path, "w") as f:
        f.write(f"# IDN/cons/urban/unb: GMM vs LCA inversion\n\n")
        f.write(f"GMM source: `{gmm_source}`\n\n")
        f.write("## 95% confidence intervals\n\n")
        f.write("| Spec | GMM $\\hat\\phi$ (SE) | GMM 95% CI (sandwich) | "
                "Inversion 95% CI (LCA) | Width ratio (inv/sand) |\n")
        f.write("|---|---:|---|---|---:|\n")
        for r in rows:
            sand_w = r["gmm_ci95_hi"] - r["gmm_ci95_lo"]
            inv_w = (r["inv_ci95_hi"] - r["inv_ci95_lo"]
                     if not np.isnan(r["inv_ci95_lo"]) else np.nan)
            ratio = (inv_w / sand_w) if not np.isnan(inv_w) else np.nan
            inv_str = (f"[{r['inv_ci95_lo']:.3f}, {r['inv_ci95_hi']:.3f}]"
                       if not np.isnan(r["inv_ci95_lo"]) else "empty")
            f.write(f"| {r['spec']} | "
                    f"{r['gmm_phi']:.3f} ({r['gmm_se']:.3f}) | "
                    f"[{r['gmm_ci95_lo']:.3f}, {r['gmm_ci95_hi']:.3f}] | "
                    f"{inv_str} | "
                    f"{ratio:.2f} |\n" if not np.isnan(ratio)
                    else f"| {r['spec']} | "
                         f"{r['gmm_phi']:.3f} ({r['gmm_se']:.3f}) | "
                         f"[{r['gmm_ci95_lo']:.3f}, {r['gmm_ci95_hi']:.3f}] | "
                         f"{inv_str} | --- |\n")
        f.write("\n## 90% confidence intervals\n\n")
        f.write("| Spec | GMM $\\hat\\phi$ (SE) | GMM 90% CI (sandwich) | "
                "Inversion 90% CI (LCA) | Width ratio (inv/sand) |\n")
        f.write("|---|---:|---|---|---:|\n")
        for r in rows:
            sand_w = r["gmm_ci90_hi"] - r["gmm_ci90_lo"]
            inv_w = (r["inv_ci90_hi"] - r["inv_ci90_lo"]
                     if not np.isnan(r["inv_ci90_lo"]) else np.nan)
            ratio = (inv_w / sand_w) if not np.isnan(inv_w) else np.nan
            inv_str = (f"[{r['inv_ci90_lo']:.3f}, {r['inv_ci90_hi']:.3f}]"
                       if not np.isnan(r["inv_ci90_lo"]) else "empty")
            f.write(f"| {r['spec']} | "
                    f"{r['gmm_phi']:.3f} ({r['gmm_se']:.3f}) | "
                    f"[{r['gmm_ci90_lo']:.3f}, {r['gmm_ci90_hi']:.3f}] | "
                    f"{inv_str} | "
                    f"{ratio:.2f} |\n" if not np.isnan(ratio)
                    else f"| {r['spec']} | "
                         f"{r['gmm_phi']:.3f} ({r['gmm_se']:.3f}) | "
                         f"[{r['gmm_ci90_lo']:.3f}, {r['gmm_ci90_hi']:.3f}] | "
                         f"{inv_str} | --- |\n")
    print(f"\nComparison markdown saved to {md_path}")


if __name__ == "__main__":
    main()
