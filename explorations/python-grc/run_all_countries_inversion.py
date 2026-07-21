"""LCA inversion CIs across all three countries (IDN, CHN, TZA), all
five 5_GrRC.do covariate specs (consumption / urban / unbalanced).

Reports four inversion CIs per (country, spec):

* phi (LCA slope) via the just-identified inversion ``grid_lca_inversion``.
* Delta_never via constrained MD ``grid_delta_never_md_inversion``.
* Delta_avg via constrained MD ``grid_delta_avg_md_inversion``.
* Delta_always via constrained MD ``grid_delta_always_md_inversion``,
  with multi-island handling near the Mobius singularity at phi = -1.

Stata GMM phi / SE come from the local reruns of 5_GrRC.do
(`rerun_workdir/{idn,chn_tza}_fresh_phi.csv`). Stata GMM Delta_X
point/SE come from `rerun_workdir/published_deltas.csv`, regenerated
with the corrected within-switcher Delta_avg formula.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
import scipy.stats as st

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import (
    SWITCHER_KEEP_MIN,
    drop_sparse_switchers,
    find_islands,
    fit_auxiliary_ols,
    format_islands,
    grid_delta_always_md_inversion,
    grid_delta_avg_md_inversion,
    grid_delta_never_md_inversion,
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


def _load_published_deltas() -> dict:
    """Load Stata's published Delta_X point/SE per (country, spec, delta).

    Reads `rerun_workdir/published_deltas.csv`, which was regenerated
    on 2026-04-30 after the within-switcher Delta_avg fix landed and
    all three countries' `_avg.ster` files were rerun.
    """
    out: dict = {}
    path = HERE / "rerun_workdir" / "published_deltas.csv"
    if not path.exists():
        print(f"[WARN] missing published deltas file: {path}")
        return out
    df = pd.read_csv(path)
    for _, row in df.iterrows():
        try:
            pt = float(row["point"])
            se = float(row["se"])
        except (ValueError, TypeError):
            pt, se = float("nan"), float("nan")
        key = (row["country"], row["spec"], row["delta"])
        out[key] = {"point": pt, "se": se}
    return out


PUBLISHED_DELTAS = _load_published_deltas()

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


def _run_one_country(country: str) -> tuple[list[dict], list[dict]]:
    """Run phi and three delta inversions for ``country``.

    Returns (phi_rows, delta_rows). The phi rows mirror the prior
    schema (one row per spec); delta rows carry one row per
    (spec, delta in {never, avg, always}).
    """
    print(f"\n{'='*72}\n{country}\n{'='*72}")
    df = load_consumption_unb(country)
    period_cols = period_fe_columns(df)
    print(f"  rows={len(df):,}  pids={df['pid'].nunique():,}  "
          f"period FEs available: {period_cols}")

    kept, counts = drop_sparse_switchers(
        df, "trajectory", "choice", "pid", threshold=SWITCHER_KEEP_MIN
    )
    # Production authors the keep-list in Stata at build time
    # (stash_switcher_keeplist) and persists it under output/keeplists/.
    # When that file exists, it is the source of truth: disagreement with
    # the local recomputation is a hard error, never a silent override.
    keeplist_csv = (HERE.parent.parent / "RP7" / "output" / "keeplists"
                    / f"{country}_unb_keeplist.csv")
    if keeplist_csv.exists():
        kl = pd.read_csv(keeplist_csv)
        stata_kept = sorted(int(s) for s in kl.loc[kl["kept"] == 1, "trajectory"])
        if stata_kept != sorted(kept):
            raise ValueError(
                f"Stata keep-list {stata_kept} ({keeplist_csv}) disagrees "
                f"with the recomputed keep-list {sorted(kept)}; counts={counts}"
            )
        kept = stata_kept
        print(f"  keep-list verified against {keeplist_csv.name}")
    else:
        print(f"  no persisted keep-list at {keeplist_csv}; using recomputation")
    if 2 not in kept:
        # Pick first available switcher as base if 2 was dropped
        base = kept[0]
        print(f"  base 2 dropped; using base = {base}")
    else:
        base = 2
    print(f"  switchers kept ({len(kept)}): {kept}, base={base}")
    print(f"  J_R (restrictions) = {len(kept) - 1}")

    trajectories = sorted(int(t) for t in df["trajectory"].dropna().unique())
    never_traj, always_traj = trajectories[0], trajectories[-1]

    phi_grid = np.arange(-3.0, 1.0001, 0.01)
    # Delta_never / Delta_avg are well-bounded around the published GMM
    # values (|Delta| < 0.5 across all three countries), so [-1.5, 1.5]
    # comfortably covers the 95% CI in those cells. Delta_always crosses
    # the Mobius singularity at phi = -1, so the CI may be unbounded;
    # use a wider grid plus find_islands to honor the multi-interval CI.
    delta_grid_nv = np.arange(-1.5, 1.5001, 0.01)
    delta_grid_al = np.arange(-5.0, 5.0001, 0.02)
    phi_rows: list[dict] = []
    delta_rows: list[dict] = []

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

        # phi inversion (just-identified, primary in lca_inversion_three_countries.md)
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

        phi_rows.append({
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

        # Three delta inversions via constrained minimum distance
        n_sw = int(sub["trajectory"].isin(kept).sum())
        pi_within = {
            s: float((sub["trajectory"] == s).sum()) / n_sw for s in kept
        }

        n_curve, n_lo, n_hi = grid_delta_never_md_inversion(
            fit, switchers_kept=kept, base=base, never_traj=never_traj,
            delta_grid=delta_grid_nv, phi_search_grid=phi_grid,
            type_one=0.05,
        )
        a_curve, a_lo, a_hi = grid_delta_avg_md_inversion(
            fit, switchers_kept=kept, base=base, pi_within=pi_within,
            delta_grid=delta_grid_nv, phi_search_grid=phi_grid,
            type_one=0.05,
        )
        t_curve, _t_lo, _t_hi = grid_delta_always_md_inversion(
            fit, switchers_kept=kept, base=base,
            always_traj=always_traj,
            delta_grid=delta_grid_al, phi_search_grid=phi_grid,
            type_one=0.05,
        )

        n_curve.to_parquet(
            OUTDIR / f"delta_never_inversion_{country.lower()}_{spec}.parquet"
        )
        a_curve.to_parquet(
            OUTDIR / f"delta_avg_inversion_{country.lower()}_{spec}.parquet"
        )
        t_curve.to_parquet(
            OUTDIR / f"delta_always_inversion_{country.lower()}_{spec}.parquet"
        )

        # Multi-island detection on the always curve (Mobius case).
        # never / avg are linear in phi at fixed delta and historically
        # produce single islands, but we run find_islands on all three
        # so unexpected multimodality surfaces in the table.
        n_islands = find_islands(n_curve, type_one=0.05, x="delta")
        a_islands = find_islands(a_curve, type_one=0.05, x="delta")
        t_islands = find_islands(t_curve, type_one=0.05, x="delta")
        nv_bounds = (float(delta_grid_nv[0]), float(delta_grid_nv[-1]))
        al_bounds = (float(delta_grid_al[0]), float(delta_grid_al[-1]))

        delta_specs = [
            ("never",  n_curve, n_lo, n_hi, n_islands, nv_bounds),
            ("avg",    a_curve, a_lo, a_hi, a_islands, nv_bounds),
            ("always", t_curve, _t_lo, _t_hi, t_islands, al_bounds),
        ]
        for label, curve_df, hull_lo, hull_hi, islands, gbounds in delta_specs:
            d_min = float(
                curve_df["delta"].iloc[int(curve_df["wald"].idxmin())]
            )
            wmin = float(curve_df["wald"].min())
            stata = PUBLISHED_DELTAS.get((country, spec, label),
                                          {"point": float("nan"),
                                           "se": float("nan")})
            delta_rows.append({
                "country": country,
                "spec": spec,
                "delta": label,
                "stata_pt": stata["point"],
                "stata_se": stata["se"],
                "stata_ci95_lo": stata["point"] - 1.96 * stata["se"],
                "stata_ci95_hi": stata["point"] + 1.96 * stata["se"],
                "md_d_at_min": d_min,
                "md_wald_min": wmin,
                "md_hull_ci95_lo": hull_lo,
                "md_hull_ci95_hi": hull_hi,
                "md_islands": format_islands(islands, grid_bounds=gbounds),
                "md_n_islands": len(islands),
                "md_grid_lo": gbounds[0],
                "md_grid_hi": gbounds[1],
            })
            inv_str = format_islands(islands, grid_bounds=gbounds)
            print(f"    {label:7s}: Stata {stata['point']:+.3f} +/- "
                  f"{stata['se']:.3f}  inv {inv_str}")

    return phi_rows, delta_rows


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


def _format_delta_md_table(rows: list[dict], delta_label: str) -> str:
    """Markdown table for one delta (never / avg / always) across all
    countries x specs. Reports Stata 95% CI vs the inversion CI as a
    union of intervals."""
    out = []
    title = {
        "never":  "Delta_never (return for never-movers)",
        "avg":    "Delta_avg (within-switcher average return)",
        "always": "Delta_always (return for always-movers)",
    }[delta_label]
    out.append(f"## {title}\n")
    out.append(
        "| Country | Spec | Stata point (SE) | Stata 95% CI | "
        "MD inversion 95% CI | Islands | Grid |"
    )
    out.append("|---|---|---:|---|---|---:|---|")
    for r in rows:
        if r["delta"] != delta_label:
            continue
        if np.isnan(r["stata_pt"]):
            stata_pt_str = "---"
            stata_ci_str = "---"
        else:
            stata_pt_str = f"{r['stata_pt']:+.3f} ({r['stata_se']:.3f})"
            stata_ci_str = (
                f"[{r['stata_ci95_lo']:+.3f}, "
                f"{r['stata_ci95_hi']:+.3f}]"
            )
        grid_str = f"[{r['md_grid_lo']:+.1f}, {r['md_grid_hi']:+.1f}]"
        out.append(
            f"| {r['country']} | {r['spec']} | "
            f"{stata_pt_str} | {stata_ci_str} | "
            f"{r['md_islands']} | {r['md_n_islands']} | {grid_str} |"
        )
    return "\n".join(out)


def main():
    phi_all: list[dict] = []
    delta_all: list[dict] = []
    for country in ["IDN", "CHN", "TZA"]:
        phi_rows, delta_rows = _run_one_country(country)
        phi_all.extend(phi_rows)
        delta_all.extend(delta_rows)

    phi_summary = pd.DataFrame(phi_all)
    phi_summary.to_csv(
        OUTDIR / "lca_inversion_three_countries_summary.csv", index=False
    )
    delta_summary = pd.DataFrame(delta_all)
    delta_summary.to_csv(
        OUTDIR / "delta_inversion_three_countries_summary.csv", index=False
    )
    print(f"\nphi summary    -> {OUTDIR / 'lca_inversion_three_countries_summary.csv'}")
    print(f"delta summary  -> {OUTDIR / 'delta_inversion_three_countries_summary.csv'}")

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
    md += _format_md_table(phi_all, ci_level=95) + "\n\n"
    md += _format_md_table(phi_all, ci_level=90) + "\n"

    md_path = OUTDIR / "lca_inversion_three_countries.md"
    md_path.write_text(md)
    print(f"phi markdown   -> {md_path}")

    delta_md = "# Trajectory-specific Delta inversion CIs\n"
    delta_md += "\n**Spec:** consumption / urban / unbalanced.\n"
    delta_md += "**Inversion source:** `lca_inversion.py` MD inversions "
    delta_md += "(`grid_delta_never_md_inversion`, "
    delta_md += "`grid_delta_avg_md_inversion`, "
    delta_md += "`grid_delta_always_md_inversion`) profiling phi over "
    delta_md += "`[-3, 1]` step 0.01.\n\n"
    delta_md += "**Stata source:** `rerun_workdir/published_deltas.csv`, "
    delta_md += "regenerated 2026-04-30 with the corrected within-switcher "
    delta_md += "Delta_avg formula.\n\n"
    delta_md += "**Grid:** Delta_never / Delta_avg use a `[-1.5, +1.5]` "
    delta_md += "step 0.01 grid; Delta_always uses `[-5, +5]` step 0.02 "
    delta_md += "to absorb the Mobius singularity at phi = -1. CI endpoints "
    delta_md += "annotated as `-inf` / `+inf` indicate the inversion CI "
    delta_md += "extends beyond the grid (CI is unbounded; widen the grid "
    delta_md += "or treat as not-rejected over the half-line).\n\n"
    delta_md += "**Islands:** number of disjoint intervals in the inversion "
    delta_md += "CI, from `find_islands`. >= 2 indicates the curve crosses "
    delta_md += "rejection on both sides of a non-monotone region (typically "
    delta_md += "the Mobius singularity for Delta_always).\n\n"
    delta_md += _format_delta_md_table(delta_all, "never") + "\n\n"
    delta_md += _format_delta_md_table(delta_all, "avg") + "\n\n"
    delta_md += _format_delta_md_table(delta_all, "always") + "\n"

    delta_md_path = OUTDIR / "delta_inversion_three_countries.md"
    delta_md_path.write_text(delta_md)
    print(f"delta markdown -> {delta_md_path}")


if __name__ == "__main__":
    main()
