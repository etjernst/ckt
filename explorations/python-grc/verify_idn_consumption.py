"""End-to-end verification: Stata restricted-GRC vs. Python port.

Runs the IDN / consumption / urban / unbalanced / no-covariate
specification in both Stata and Python, then compares coefficients,
standard errors, and the Hansen J-statistic.

The Stata side is the standalone file ``verify_stata.do``, which uses
``run_grc`` from ``scripts/0_programs.do``. The Python side calls
``RestrictedGRC`` from ``grc_gmm.py``.

Usage::

    python verify_idn_consumption.py               # run both sides, compare
    STATA_TIMEOUT=3600 python verify_idn_consumption.py   # let Stata run longer
    SKIP_STATA=1 python verify_idn_consumption.py  # use cached Stata CSVs

Manual Stata (when the wrapper's timeout is inconvenient)::

    cd explorations/python-grc && stata-mp -b do verify_stata.do
    SKIP_STATA=1 python verify_idn_consumption.py

Target precision (per the task brief): coefficients to 4 decimals,
standard errors to 3 decimals, J-stat to 2 decimals.
"""

from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))

from data_loader import load_consumption_unb  # noqa: E402
from grc_gmm import RestrictedGRC  # noqa: E402


HERE = Path(__file__).parent
STATA_DO = HERE / "verify_stata.do"
STATA_OUT = HERE / "stata_out_idn_cons_urb_unb.csv"
STATA_J_OUT = HERE / "stata_out_idn_cons_urb_unb_jstat.csv"
STATA_SAMPLE_OUT = HERE / "stata_sample_idn_cons_urb_unb.csv"
STATA_TRAJ_OUT = HERE / "stata_sample_idn_cons_urb_unb_traj.csv"
PYTHON_OUT = HERE / "python_out_idn_cons_urb_unb.csv"
PYTHON_SAMPLE_OUT = HERE / "python_sample_idn_cons_urb_unb.csv"
PYTHON_TRAJ_OUT = HERE / "python_sample_idn_cons_urb_unb_traj.csv"
COMPARISON = HERE / "verification_idn_consumption.csv"


def _stata_exe() -> str:
    """Resolve the Stata executable path.

    The user's bash alias points to ``C:\\Program Files\\StataNow19\\StataMP-64.exe``.
    Allow override via the ``STATA_EXE`` environment variable.
    """
    explicit = os.environ.get("STATA_EXE")
    if explicit:
        return explicit
    candidates = [
        r"C:/Program Files/StataNow19/StataMP-64.exe",
        r"C:/Program Files/Stata19/StataMP-64.exe",
        r"C:/Program Files/Stata18/StataMP-64.exe",
        r"C:/Program Files/Stata17/StataMP-64.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    raise FileNotFoundError(
        "Could not find StataMP-64.exe. Set STATA_EXE environment variable."
    )


def run_stata() -> None:
    """Invoke ``verify_stata.do`` via ``stata-mp -b``.

    The .do file is standalone; callers can also run it manually outside
    Python (useful when Stata's wall time exceeds this wrapper's budget).
    """
    print(f"Running Stata from {STATA_DO.name}...", flush=True)
    stata = _stata_exe()
    timeout = int(os.environ.get("STATA_TIMEOUT", "1800"))  # default 30 min
    subprocess.run(
        [stata, "-b", "do", STATA_DO.name],
        cwd=str(HERE), check=True, timeout=timeout,
    )
    print("  stata_out:", STATA_OUT)
    print("  stata_j_out:", STATA_J_OUT)


def dump_python_sample(df: pd.DataFrame) -> None:
    """Write per-variable summary and per-trajectory counts for the
    Python side, mirroring the Stata sample dump in ``verify_stata.do``.
    Enables a direct observational-alignment check against Stata
    before interpreting any coef/SE differences as estimator issues."""
    keep_vars = [c for c in ["lndepvar", "choice", "unbalanced", "period",
                              "consumption", "hhsize_cube"] if c in df.columns]
    summary = df[keep_vars].describe().T.reset_index()
    summary = summary.rename(columns={"index": "variable", "count": "n",
                                       "std": "sd"})
    summary[["variable", "n", "mean", "sd", "min", "max"]].to_csv(
        PYTHON_SAMPLE_OUT, index=False
    )
    traj = (df.groupby(df["trajectory"].fillna(-1), dropna=False)
              .size().rename("n").reset_index())
    traj["trajectory"] = traj["trajectory"].apply(
        lambda v: "NA" if v == -1 else f"{int(v)}"
    )
    traj.to_csv(PYTHON_TRAJ_OUT, index=False)


def compare_samples() -> bool:
    """Compare Stata and Python sample dumps. Returns True if aligned."""
    if not (STATA_SAMPLE_OUT.exists() and PYTHON_SAMPLE_OUT.exists()):
        print("  (sample dumps missing on one side; skipping sample diff)")
        return True
    s = pd.read_csv(STATA_SAMPLE_OUT)
    p = pd.read_csv(PYTHON_SAMPLE_OUT)
    m = s.merge(p, on="variable", how="outer", suffixes=("_stata", "_py"))
    m["delta_n"] = m["n_stata"] - m["n_py"]
    m["delta_mean"] = m["mean_stata"] - m["mean_py"]
    print("\nSample diff (per-variable):")
    cols = ["variable", "n_stata", "n_py", "delta_n",
            "mean_stata", "mean_py", "delta_mean"]
    print(m[cols].to_string(index=False))
    ok = bool((m["delta_n"].abs().fillna(0) == 0).all() and
              (m["delta_mean"].abs().fillna(0) < 1e-6).all())
    if STATA_TRAJ_OUT.exists() and PYTHON_TRAJ_OUT.exists():
        st = pd.read_csv(STATA_TRAJ_OUT, dtype={"trajectory": str})
        pt = pd.read_csv(PYTHON_TRAJ_OUT, dtype={"trajectory": str})
        tm = st.merge(pt, on="trajectory", how="outer",
                      suffixes=("_stata", "_py"))
        tm["delta"] = tm["n_stata"].fillna(0) - tm["n_py"].fillna(0)
        mismatch = tm[tm["delta"].abs() > 0]
        if len(mismatch) > 0:
            print("\nTrajectory-count mismatches:")
            print(mismatch.to_string(index=False))
            ok = False
        else:
            print("\nTrajectory counts: aligned across all labels.")
    return ok


def run_python() -> dict:
    df = load_consumption_unb("IDN")
    dump_python_sample(df)
    t0 = time.time()
    fit = RestrictedGRC(
        outcome="lndepvar",
        choice="choice",
        trajectory="trajectory",
        individual_id="pid",
        covariates=[],
        unbalanced_col="unbalanced",
    ).fit(df)
    fit_seconds = time.time() - t0
    rows = []
    for name in fit.param_names_:
        rows.append({
            "name": name,
            "coef_py": fit.coef_[name],
            "se_py": fit.se_[name],
        })
    pd.DataFrame(rows).to_csv(PYTHON_OUT, index=False)
    return {
        "fit": fit,
        "J": fit.J_stat_,
        "J_df": fit.J_df_,
        "J_pval": fit.J_pval_,
        "N": fit.n_obs_,
        "N_clust": fit.n_clusters_,
        "base": fit._data_["base"],
        "fit_seconds": fit_seconds,
    }


def compare(python_summary: dict) -> None:
    stata_df = pd.read_csv(STATA_OUT)
    py_df = pd.read_csv(PYTHON_OUT)

    # Normalize names for join (Stata uses `eq:_cons` for scalars).
    stata_df["name_norm"] = stata_df["name"].str.replace(":_cons$", "", regex=True)
    py_df["name_norm"] = py_df["name"].str.replace(":_cons$", "", regex=True)
    merged = stata_df.merge(py_df, on="name_norm", how="outer",
                            suffixes=("_stata", "_py"))
    merged["delta_coef"] = merged["coef"] - merged["coef_py"]
    merged["delta_se"] = merged["se"] - merged["se_py"]
    merged.to_csv(COMPARISON, index=False)
    print()
    cols = ["name_norm", "coef", "coef_py", "delta_coef",
            "se", "se_py", "delta_se"]
    print(merged[cols].to_string(index=False))

    stata_j = pd.read_csv(STATA_J_OUT).set_index("stat")["value"].to_dict()

    def _safe_float(v, default=float("nan")):
        """Stata writes `.` for missing scalars (e.g. a p-value too small
        to represent). Fall back to NaN for display."""
        try:
            s = str(v).strip()
            if s == "" or s == ".":
                return default
            return float(s)
        except (TypeError, ValueError):
            return default

    stata_J = _safe_float(stata_j["J"])
    stata_Jdf = int(_safe_float(stata_j["J_df"], 0))
    stata_Jp = _safe_float(stata_j["J_p"])
    stata_N = int(_safe_float(stata_j["N"], 0))
    stata_Nclust = int(_safe_float(stata_j["N_clust"], 0))
    stata_base = int(_safe_float(stata_j["base"], 0))
    print()
    print(
        f"Stata J = {stata_J:.4f}, df = {stata_Jdf}, p = {stata_Jp:.4f}, "
        f"N = {stata_N}, N_clust = {stata_Nclust}, base = {stata_base}"
    )
    print(
        f"Python J = {python_summary['J']:.4f}, df = {python_summary['J_df']}, "
        f"p = {python_summary['J_pval']:.4f}, N = {python_summary['N']}, "
        f"N_clust = {python_summary['N_clust']}, base = {python_summary['base']}"
    )

    stata_seconds = _safe_float(stata_j.get("gmm_seconds", "."))
    py_seconds = python_summary.get("fit_seconds", float("nan"))
    print()
    print(
        f"Stata run_grc wall time : {stata_seconds:>8.1f} s"
        if not np.isnan(stata_seconds)
        else "Stata run_grc wall time : (not recorded -- rerun verify_stata.do)"
    )
    print(f"Python .fit() wall time : {py_seconds:>8.1f} s")

    max_coef_diff = merged["delta_coef"].abs().max()
    max_se_diff = merged["delta_se"].abs().max()
    J_diff = abs(stata_J - python_summary["J"])
    print()
    print(f"max |coef diff| = {max_coef_diff:.6e}  (target 1e-4)")
    print(f"max |se diff|   = {max_se_diff:.6e}  (target 1e-3)")
    print(f"|J diff|        = {J_diff:.6e}  (target 1e-2)")
    passed = (max_coef_diff < 1e-4) and (max_se_diff < 1e-3) and (J_diff < 1e-2)
    print("VERIFICATION:", "PASS" if passed else "FAIL")


def main() -> None:
    if not os.environ.get("SKIP_STATA"):
        run_stata()
    python_summary = run_python()
    sample_ok = compare_samples()
    if not sample_ok:
        print(
            "\n*** Sample diff: Stata and Python are NOT using the same "
            "observations. Interpret coef/SE comparison with caution. ***"
        )
    compare(python_summary)
    print()
    print(python_summary["fit"].summary())


if __name__ == "__main__":
    main()
