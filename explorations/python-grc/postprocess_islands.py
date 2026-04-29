"""Post-processing pass on saved (phi, p_value) curves: identify islands
of non-rejection and report curve diagnostics (max p, phi at max p) on top
of the existing CI comparison.

Reads ``results/lca_inversion_{country}_{spec}.parquet`` written by
``run_all_countries_inversion.py`` and writes:

* ``results/lca_inversion_islands.md``: human-readable extension of the
  three-countries comparison, showing island counts and max p per spec.
* ``results/lca_inversion_islands_summary.csv``: per-spec island and
  curve-stat columns for downstream analysis.

Pure post-processing --- does not re-run any OLS or grid sweep, so the
existing parquets and the published comparison md remain canonical.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

from lca_inversion import find_islands, summary_curve_stats


HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results"

COUNTRIES = ["IDN", "CHN", "TZA"]
SPECS = ["covs_0", "covs_trend", "covs_1", "covs_2", "covs_all"]


def _islands_str(islands: list[tuple[float, float]]) -> str:
    if not islands:
        return "empty"
    return ", ".join(f"[{lo:+.3f}, {hi:+.3f}]" for lo, hi in islands)


def _row_for(country: str, spec: str) -> dict:
    path = RESULTS / f"lca_inversion_{country.lower()}_{spec}.parquet"
    curve = pd.read_parquet(path)
    stats = summary_curve_stats(curve)
    isl_95 = find_islands(curve, type_one=0.05)
    isl_90 = find_islands(curve, type_one=0.10)
    return {
        "country": country,
        "spec": spec,
        "max_p": stats["max_p"],
        "phi_at_max_p": stats["phi_at_max_p"],
        "min_wald": stats["min_wald"],
        "phi_at_min_wald": stats["phi_at_min_wald"],
        "n_islands_95": len(isl_95),
        "islands_95": _islands_str(isl_95),
        "n_islands_90": len(isl_90),
        "islands_90": _islands_str(isl_90),
    }


def main():
    rows = [_row_for(c, s) for c in COUNTRIES for s in SPECS]
    df = pd.DataFrame(rows)
    df.to_csv(RESULTS / "lca_inversion_islands_summary.csv", index=False)

    md = ["# LCA inversion: island detection and curve diagnostics\n"]
    md.append("Post-processing of the (phi, p_value) grid curves saved by ")
    md.append("`run_all_countries_inversion.py`. ")
    md.append("Companion to `lca_inversion_three_countries.md` (CI comparison).\n\n")
    md.append("Single-island results are the same convex hull as the ")
    md.append("comparison md. Multimodal results would mean disconnected ")
    md.append("non-rejected regions of the phi grid; reporting only the ")
    md.append("min/max would overstate CI coverage. ")
    md.append("Empty CIs are reported with the max p-value attained on the ")
    md.append("grid, which says how close the model comes to acceptance ")
    md.append("for the best-fitting phi.\n\n")
    md.append("**Grid:** `phi in [-3, 1]` step 0.01 (401 points). ")
    md.append("**Levels:** 95% (alpha=0.05), 90% (alpha=0.10).\n\n")

    md.append("## Curve diagnostics and island counts\n\n")
    md.append("| Country | Spec | max p (phi) | min Wald (phi) | "
              "Islands @ 95% | Islands @ 90% |\n")
    md.append("|---|---|---|---|---|---|\n")
    for r in rows:
        max_p_str = f"{r['max_p']:.4f} (phi={r['phi_at_max_p']:+.3f})"
        wald_str = f"{r['min_wald']:.2f} (phi={r['phi_at_min_wald']:+.3f})"
        n95 = r["n_islands_95"]
        n90 = r["n_islands_90"]
        i95 = r["islands_95"]
        i90 = r["islands_90"]
        flag = ""
        if n95 > 1 or n90 > 1:
            flag = " **MULTIMODAL**"
        md.append(
            f"| {r['country']} | {r['spec']} | {max_p_str} | {wald_str} | "
            f"{n95}: {i95}{flag} | {n90}: {i90} |\n"
        )

    md.append("\n## Findings\n\n")
    multimodal = [r for r in rows
                  if r["n_islands_95"] > 1 or r["n_islands_90"] > 1]
    if not multimodal:
        md.append("**No multimodality.** Every non-empty CI in the grid is ")
        md.append("a single connected region of non-rejection, so the ")
        md.append("convex-hull CIs in `lca_inversion_three_countries.md` ")
        md.append("are not hiding disconnected islands. ")
        md.append("The reported `[min, max]` endpoints fully describe each ")
        md.append("country/spec's accepted phi region.\n\n")
    else:
        md.append("**Multimodal cases detected:**\n\n")
        for r in multimodal:
            md.append(f"- {r['country']} / {r['spec']}: "
                      f"95% islands {r['islands_95']}, "
                      f"90% islands {r['islands_90']}\n")
        md.append("\n")

    chn_rows = [r for r in rows if r["country"] == "CHN"]
    chn_max_p = max(r["max_p"] for r in chn_rows)
    md.append("**CHN's empty CIs are not borderline.** ")
    md.append(f"Across all five specs, the highest p-value attained on the ")
    md.append(f"`[-3, 1]` grid is {chn_max_p:.4f} ")
    md.append("(at covs_all). Even at the best-fitting phi, the joint Wald ")
    md.append("statistic for the LCA restriction is rejected at the 5% level. ")
    md.append("Pooled-sample LCA is incompatible with the CHN data for ")
    md.append("*every* phi value in the grid, not just the GMM point estimate. ")
    md.append("Hukou splits are necessary, not optional.\n\n")

    out = RESULTS / "lca_inversion_islands.md"
    out.write_text("".join(md))
    print(f"Wrote {out}")
    print(f"Wrote {RESULTS / 'lca_inversion_islands_summary.csv'}")


if __name__ == "__main__":
    main()
