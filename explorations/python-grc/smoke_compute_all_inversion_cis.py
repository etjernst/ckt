"""Smoke test for ``compute_all_inversion_cis``.

Calls the new single-call entry point on IDN/covs_all using the same
data_loader path as ``run_all_countries_inversion.py``. Prints the
four CIs at 90% and 95% so they can be compared against the
published markdown table at
``results/delta_inversion_three_countries.md``.

Diagnoses whether discrepancies seen via the Stata bridge originate
in the helper itself or in the Stata-side data preparation.
"""
from __future__ import annotations

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import compute_all_inversion_cis


def _spec_controls(spec, period_cols):
    if spec == "covs_0":
        return []
    if spec == "covs_trend":
        return list(period_cols)
    if spec == "covs_1":
        return list(period_cols) + ["female"]
    if spec == "covs_2":
        return list(period_cols) + ["female", "age2"]
    if spec == "covs_all":
        return (list(period_cols)
                + ["female", "age2", "education_max", "education_max2"])
    raise ValueError(spec)


def main() -> None:
    df = load_consumption_unb("IDN")
    period_cols = period_fe_columns(df)
    spec = "covs_all"
    controls = _spec_controls(spec, period_cols)

    print(f"loaded IDN: rows={len(df):,}, "
          f"pids={df['pid'].nunique():,}, periods={period_cols}")
    print(f"spec={spec}, controls={controls}")

    out = compute_all_inversion_cis(
        df=df,
        outcome="lndepvar",
        trajectory="trajectory",
        choice="choice",
        hhid="pid",
        base=2,
        controls=controls,
        threshold=5,
    )
    for k in ["phi", "delta_never", "delta_avg", "delta_always"]:
        d = out[k]
        print(f"\n{k}:")
        print(f"  J_R={d['J_R']}  n_kept={d['n_kept']}")
        print(f"  point at wald-min: {d['point']:+.4f}  "
              f"wald_min={d['wald_min']:.3f}")
        print(f"  ci90: {d['ci90']}  islands90: {d['islands90']}")
        print(f"  ci95: {d['ci95']}  islands95: {d['islands95']}")
        print(f"  ci90_str: {d['ci90_str']}")
        print(f"  ci95_str: {d['ci95_str']}")


if __name__ == "__main__":
    main()
