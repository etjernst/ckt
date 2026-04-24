"""LCA inversion CI for phi across all three countries (IDN, CHN, TZA),
all five 5_GrRC.do covariate specs (consumption / urban / unbalanced).

Builds the side-by-side table the paper would carry:
    Country x Spec  --  Stata phi (SE) -- 90% sandwich -- 95% sandwich
                       -- 90% inversion -- 95% inversion

Stata phi / SE values come from the published .tex tables
(GRC_{country}_consumption_urban_unb.tex). Inversion CIs computed
fresh by this script.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import scipy.stats as st

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import (
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_lca_inversion,
)


HERE = Path(__file__).resolve().parent
OUTDIR = HERE / "results"
OUTDIR.mkdir(exist_ok=True)


# Load fresh GMM phi/SE from local Stata reruns (rerun_workdir/).
# IDN from rerun_idn_5gr.do (2026-04-23 evening); CHN+TZA from
# rerun_chn_tza_5gr.do (2026-04-24 afternoon). Both wrote to a LOCAL
# workdir (not Dropbox) to avoid overwriting shared coauthor output.
# All three reruns confirmed to match the published .tex tables to
# 3-4 decimals.

def _load_fresh_gmm() -> dict:
    """Load and normalize the fresh GMM values into the same dict shape
    the rest of this module expects."""
    import math

    def _to_float(x):
        try:
            return float(x)
        except (ValueError, TypeError):
            return float("nan")

    out: dict = {}
    idn_csv = HERE / "rerun_workdir" / "idn_fresh_phi.csv"
    chn_tza_csv = HERE / "rerun_workdir" / "chn_tza_fresh_phi.csv"
    for path, country_col, default_country in [
        (idn_csv,    None,        "IDN"),
        (chn_tza_csv, "country",  None),
    ]:
        if not path.exists():
            print(f"[WARN] missing fresh GMM file: {path}")
            continue
        df = pd.read_csv(path)
        for _, row in df.iterrows():
            country = (row[country_col]
                       if country_col else default_country)
            spec = row["spec"]
            phi = _to_float(row["phi"])
            se = _to_float(row["phi_se"])
            J_p_raw = row.get("J_p", float("nan"))
            J_p = (_to_float(J_p_raw)
                   if not (isinstance(J_p_raw, float) and math.isnan(J_p_raw))
                   else float("nan"))
            J_stat = _to_float(row.get("J", float("nan")))
            conv = (str(row.get("converged", "Y")).strip() == "Y")
            # If J_p is missing, compute from J and (m - k) -- but we don't
            # know m, k here. Fall back to the published table p-values
            # for display when J_p is NaN.
            out.setdefault(country, {})[spec] = {
                "phi": phi, "se": se, "J": J_stat,
                "J_p": J_p, "conv": conv,
            }
    return out


PUBLISHED_GMM = _load_fresh_gmm()

# J_p is missing from the rerun CSVs (Stata's e(J_p) returned ".").
# Backfill from the published .tex tables for display.
_J_P_PUBLISHED = {
    ("IDN", "covs_0"):     0.000,
    ("IDN", "covs_trend"): 0.214,
    ("IDN", "covs_1"):     0.216,
    ("IDN", "covs_2"):     0.187,
    ("IDN", "covs_all"):   0.403,
    ("CHN", "covs_0"):     0.000,
    ("CHN", "covs_trend"): 0.029,
    ("CHN", "covs_1"):     0.029,
    ("CHN", "covs_2"):     0.019,
    ("CHN", "covs_all"):   0.025,
    ("TZA", "covs_0"):     0.000,
    ("TZA", "covs_trend"): 0.084,
    ("TZA", "covs_1"):     0.089,
    ("TZA", "covs_2"):     0.084,
    ("TZA", "covs_all"):   0.280,
}
for (cc, ss), pv in _J_P_PUBLISHED.items():
    if cc in PUBLISHED_GMM and ss in PUBLISHED_GMM[cc]:
        if np.isnan(PUBLISHED_GMM[cc][ss].get("J_p", np.nan)):
            PUBLISHED_GMM[cc][ss]["J_p"] = pv


def _spec_controls(spec: str, period_cols: list[str]) -> list[str]:
    """Map 5_GrRC.do spec names to the controls list."""
    if spec == "covs_0":
        return []
    if spec == "covs_trend":
        return list(period_cols)
    if spec == "covs_1":
        return list(period_cols) + ["female"]
    if spec == "covs_2":
        return list(period_cols) + ["female", "age2"]
    if spec == "covs_all":
        return list(period_cols) + ["female", "age2",
                                     "education_max", "education_max2"]
    raise ValueError(f"unknown spec {spec}")


def _run_one_country(country: str) -> list[dict]:
    print(f"\n{'='*72}\n{country}\n{'='*72}")
    df = load_consumption_unb(country)
    period_cols = period_fe_columns(df)
    print(f"  rows={len(df):,}  pids={df['pid'].nunique():,}  "
          f"period FEs available: {period_cols}")

    kept, counts = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=5
    )
    if 2 not in kept:
        # Pick first available switcher as base if 2 was dropped
        base = kept[0]
        print(f"  base 2 dropped; using base = {base}")
    else:
        base = 2
    print(f"  switchers kept ({len(kept)}): {kept}, base={base}")
    print(f"  J_R (restrictions) = {len(kept) - 1}")

    phi_grid = np.arange(-3.0, 1.0001, 0.01)
    rows: list[dict] = []

    for spec in ["covs_0", "covs_trend", "covs_1", "covs_2", "covs_all"]:
        controls = _spec_controls(spec, period_cols)
        cols_needed = ["lndepvar", "choice", "trajectory", "pid",
                       "unbalanced", "unbalanced_choice"] + controls
        sub = df.dropna(subset=[c for c in cols_needed
                                 if c != "trajectory"]).copy()
        try:
            fit = fit_auxiliary_ols(
                sub, outcome="lndepvar", trajectory="trajectory",
                choice="choice", hhid="pid",
                switchers_kept=kept, controls=controls,
            )
        except Exception as e:
            print(f"  [{spec}] OLS failed: {e}")
            continue

        curve, ci95_lo, ci95_hi = grid_lca_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.05,
        )
        _, ci90_lo, ci90_hi = grid_lca_inversion(
            fit, switchers_kept=kept, base=base,
            phi_grid=phi_grid, type_one=0.10,
        )
        wald_min = float(curve["wald"].min())
        phi_at_min = float(curve.loc[curve["wald"].idxmin(), "phi"])
        gmm = PUBLISHED_GMM[country][spec]

        rows.append({
            "country": country,
            "spec": spec,
            "n_obs": fit.n_obs,
            "n_clusters": fit.n_clusters,
            "J_R": len(kept) - 1,
            "gmm_phi": gmm["phi"],
            "gmm_se": gmm["se"],
            "gmm_J_p": gmm["J_p"],
            "gmm_converged": gmm["conv"],
            "gmm_ci90_lo": gmm["phi"] - 1.645 * gmm["se"],
            "gmm_ci90_hi": gmm["phi"] + 1.645 * gmm["se"],
            "gmm_ci95_lo": gmm["phi"] - 1.96 * gmm["se"],
            "gmm_ci95_hi": gmm["phi"] + 1.96 * gmm["se"],
            "inv_wald_min": wald_min,
            "inv_phi_at_waldmin": phi_at_min,
            "inv_ci90_lo": ci90_lo,
            "inv_ci90_hi": ci90_hi,
            "inv_ci95_lo": ci95_lo,
            "inv_ci95_hi": ci95_hi,
        })

        gmm_phi, gmm_se = gmm["phi"], gmm["se"]
        ci95_inv = (
            f"[{ci95_lo:7.3f}, {ci95_hi:7.3f}]"
            if not np.isnan(ci95_lo) else "          empty         "
        )
        print(f"  {spec:11s}: GMM phi={gmm_phi:+.3f} (SE {gmm_se:.3f})  "
              f"inv 95% {ci95_inv}  Wald_min={wald_min:.1f}")

        curve.to_parquet(
            OUTDIR / f"lca_inversion_{country.lower()}_{spec}.parquet"
        )

    return rows


def _format_md_table(rows: list[dict], ci_level: int = 95) -> str:
    pre = "ci95_" if ci_level == 95 else "ci90_"
    z = 1.96 if ci_level == 95 else 1.645
    out = []
    out.append(f"## {ci_level}% confidence intervals\n")
    out.append("| Country | Spec | GMM $\\hat\\phi$ (SE) | "
               f"GMM {ci_level}% CI (sandwich) | "
               f"Inversion {ci_level}% CI (LCA) | "
               "Width ratio (inv/sand) |")
    out.append("|---|---|---:|---|---|---:|")
    for r in rows:
        sand_w = r[f"gmm_{pre}hi"] - r[f"gmm_{pre}lo"]
        if not np.isnan(r[f"inv_{pre}lo"]):
            inv_w = r[f"inv_{pre}hi"] - r[f"inv_{pre}lo"]
            ratio = f"{inv_w / sand_w:.2f}"
            inv_str = f"[{r[f'inv_{pre}lo']:.3f}, {r[f'inv_{pre}hi']:.3f}]"
        else:
            ratio = "---"
            inv_str = "empty"
        flag = " (J rejects)" if r["gmm_J_p"] < 0.05 else ""
        out.append(
            f"| {r['country']} | {r['spec']} | "
            f"{r['gmm_phi']:+.3f} ({r['gmm_se']:.3f}){flag} | "
            f"[{r[f'gmm_{pre}lo']:.3f}, {r[f'gmm_{pre}hi']:.3f}] | "
            f"{inv_str} | {ratio} |"
        )
    return "\n".join(out)


def main():
    all_rows: list[dict] = []
    for country in ["IDN", "CHN", "TZA"]:
        all_rows.extend(_run_one_country(country))

    summary = pd.DataFrame(all_rows)
    summary.to_csv(OUTDIR / "lca_inversion_three_countries_summary.csv",
                   index=False)
    print(f"\nSummary saved to "
          f"{OUTDIR / 'lca_inversion_three_countries_summary.csv'}")

    md = "# LCA inversion CI vs GMM sandwich CI\n"
    md += "\n**Spec:** consumption / urban / unbalanced\n\n"
    md += "**GMM source:** fresh local Stata reruns of 5_GrRC.do "
    md += "(`rerun_workdir/idn_fresh_phi.csv` for IDN, "
    md += "`rerun_workdir/chn_tza_fresh_phi.csv` for CHN/TZA). "
    md += "Cross-checked against the published "
    md += "`output/tables/GRC_{country}_consumption_urban_unb.tex` --- match to 3-4 decimals.\n\n"
    md += "**Inversion source:** `lca_inversion.py` on the same data, "
    md += "Python statsmodels OLS with cluster-robust SE at pid, "
    md += "grid `[-3, 1]` step 0.01, `drop_sparse_switchers` threshold 5.\n\n"
    md += "**(J rejects)** flag indicates Stata GMM Hansen J p-value < 0.05 "
    md += "(model rejected by overid; e.g., CHN pooled sample needs hukou splits).\n\n"
    md += _format_md_table(all_rows, ci_level=95) + "\n\n"
    md += _format_md_table(all_rows, ci_level=90) + "\n"

    md_path = OUTDIR / "lca_inversion_three_countries.md"
    md_path.write_text(md)
    print(f"Markdown comparison saved to {md_path}")


if __name__ == "__main__":
    main()
