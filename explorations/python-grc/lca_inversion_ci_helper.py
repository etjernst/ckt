"""Stata-callable helper for the LCA inversion CI procedure.

Invoked from `lca_inversion_ci.ado` via `python script "..."`. Reads
arguments from Stata locals (via `sfi.Macro.getLocal`), runs the
inversion on the current dataset, and writes results back to Stata
locals for the .ado to ereturn-scalar.

Expected Stata locals before invocation:
    outcome, traj, choice, hhid, base, ctrl_list, min_phi, max_phi,
    increment, threshold, and optionally switchers_kept (the
    Stata-authored keep-list; disagreement with the local recomputation
    is a hard error)

Writes back:
    inv_phi_at_waldmin, inv_wald_min, inv_J_R, inv_n_kept,
    inv_ci90_lo, inv_ci90_hi, inv_ci95_lo, inv_ci95_hi
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sfi import Data, Macro

HERE = Path(Macro.getLocal("helper_dir")).resolve()
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from lca_inversion import (  # noqa: E402
    drop_sparse_switchers,
    fit_auxiliary_ols,
    grid_lca_inversion,
)


def _put(name, val):
    if val is None or (isinstance(val, float) and np.isnan(val)):
        Macro.setLocal(name, ".")
    else:
        Macro.setLocal(name, f"{float(val):.10g}")


def main():
    outcome = Macro.getLocal("outcome")
    traj = Macro.getLocal("traj")
    choice = Macro.getLocal("choice")
    hhid = Macro.getLocal("hhid")
    base = int(Macro.getLocal("base"))
    ctrl = Macro.getLocal("ctrl_list").split()
    min_phi = float(Macro.getLocal("min_phi"))
    max_phi = float(Macro.getLocal("max_phi"))
    incr = float(Macro.getLocal("increment"))
    thr = int(Macro.getLocal("threshold"))

    needed = [outcome, traj, choice, hhid, "unbalanced", "unbalanced_choice"] + ctrl
    df = pd.DataFrame({c: Data.get(c) for c in needed})
    # sfi.Data.get returns Stata's missing-value sentinel (8.988e+307 for `.`,
    # slightly larger for .a-.z) instead of NaN. Convert to NaN for pandas.
    df = df.where(df.abs() < 1e300, np.nan)
    n0 = len(df)

    # setup_grc_estimation recodes trajectory to 999 for unbalanced observers.
    # data_loader.py uses NaN for the same observers. Reconcile here so
    # drop_sparse_switchers does not misidentify 999 as the "always" group.
    # Rows themselves stay; identification comes via unbalanced + unbalanced_choice.
    df.loc[df["unbalanced"] == 1, traj] = np.nan

    # Drop rows with missing values in outcome, choice, hhid, or any control.
    # statsmodels' OLS otherwise propagates NaN through the design and the
    # cluster-robust VCV overflows. NaN in trajectory is preserved
    # (unbalanced observers stay in the regression via unbalanced indicators).
    nan_subset = [outcome, choice, hhid, "unbalanced", "unbalanced_choice"] + ctrl
    df = df.dropna(subset=nan_subset).copy()
    print(f"[lca_inversion_ci] after dropna(outcome+choice+ctrls): n = {len(df)} "
          f"(dropped {n0 - len(df)})")
    # Diagnostic on the remaining columns: surface any column with extreme
    # values that would indicate a missed missing-value sentinel.
    for c in [outcome] + ctrl:
        col = df[c].values
        if col.size:
            mn, mx = float(np.nanmin(col)), float(np.nanmax(col))
            if abs(mn) > 1e10 or abs(mx) > 1e10:
                print(f"[lca_inversion_ci] WARNING: column {c} has extreme "
                      f"values: min={mn:g}, max={mx:g}")

    kept, counts = drop_sparse_switchers(df, traj, choice, hhid, threshold=thr)
    supplied_raw = Macro.getLocal("switchers_kept")
    if supplied_raw:
        # The Stata-authored keep-list is the source of truth; the local
        # recomputation is a redundant safety check, and disagreement is
        # a hard error, never a silent re-derivation.
        supplied = sorted(int(s) for s in supplied_raw.split())
        if supplied != sorted(kept):
            raise ValueError(
                f"supplied switchers_kept {supplied} disagrees with the "
                f"recomputed keep-list {sorted(kept)}; counts={counts}"
            )
        kept = supplied
    print(f"[lca_inversion_ci] switchers kept: {kept}")
    if base not in kept:
        raise ValueError(
            f"base trajectory {base} not in kept switchers {kept}; counts={counts}"
        )

    fit = fit_auxiliary_ols(
        df,
        outcome=outcome,
        trajectory=traj,
        choice=choice,
        hhid=hhid,
        switchers_kept=kept,
        controls=ctrl,
    )

    phi_grid = np.arange(min_phi, max_phi + 1e-9, incr)
    curve, ci95_lo, ci95_hi = grid_lca_inversion(
        fit, switchers_kept=kept, base=base, phi_grid=phi_grid, type_one=0.05
    )
    _, ci90_lo, ci90_hi = grid_lca_inversion(
        fit, switchers_kept=kept, base=base, phi_grid=phi_grid, type_one=0.10
    )

    wald_min = float(curve["wald"].min())
    phi_at_min = float(curve.loc[curve["wald"].idxmin(), "phi"])

    _put("inv_phi_at_waldmin", phi_at_min)
    _put("inv_wald_min", wald_min)
    _put("inv_J_R", len(kept) - 1)
    _put("inv_n_kept", len(kept))
    _put("inv_ci90_lo", ci90_lo)
    _put("inv_ci90_hi", ci90_hi)
    _put("inv_ci95_lo", ci95_lo)
    _put("inv_ci95_hi", ci95_hi)


main()
