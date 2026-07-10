"""Build the TZA covs_trend auxiliary OLS design matrix as a Stata .dta.

Mirrors fit_auxiliary_ols(...) in lca_inversion.py: alpha[d] for every
observed trajectory, beta[s] for every kept switcher, unbalanced,
unbalanced_choice, plus controls (period FE for covs_trend).  Saves a
.dta with explicit columns plus the trajectory id and pid for cluster
keys, so reg_sandwich can be run two ways:

  Spec A (unabsorbed): include alpha_d_* as raw regressors.
  Spec B (absorbed)  : drop alpha_d_*, use absorb(trajectory).

The kept switchers, base, and beta-name list go into a sidecar JSON for
the Stata script.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PYGRC = HERE.parent.parent
sys.path.insert(0, str(PYGRC))

import numpy as np
import pandas as pd

from data_loader import load_consumption_unb, period_fe_columns
from lca_inversion import drop_sparse_switchers


COUNTRY = "TZA"
SPEC = "covs_trend"

print(f"loading {COUNTRY} unbalanced consumption...")
df = load_consumption_unb(COUNTRY)
period_cols = period_fe_columns(df)
print(f"  rows={len(df):,}  pids={df['pid'].nunique():,}  period FE: {period_cols}")

kept, counts = drop_sparse_switchers(df, "trajectory", "choice", "pid", threshold=5)
base = 2 if 2 in kept else kept[0]
print(f"  switchers kept ({len(kept)}): {kept}, base={base}")
print(f"  J_R = {len(kept) - 1}")

controls = list(period_cols)
cols_needed = ["lndepvar", "choice", "trajectory", "pid",
               "unbalanced", "unbalanced_choice"] + controls
sub = df.dropna(subset=[c for c in cols_needed if c != "trajectory"]).copy()
print(f"  after spec dropna: rows={len(sub):,}, pids={sub['pid'].nunique():,}")

# Build alpha[d] dummies for every observed trajectory (NaN trajectory
# becomes 0 for every alpha; those rows are unbalanced and the
# `unbalanced` column carries them).
trajectories = sorted(int(t) for t in sub["trajectory"].dropna().unique())
print(f"  trajectories observed: {len(trajectories)}: {trajectories}")

design = pd.DataFrame(index=sub.index)
design["lndepvar"] = sub["lndepvar"].astype(float).values
design["pid"]      = sub["pid"].astype(int).values
# trajectory needs a non-missing fill value for absorb() to handle the
# unbalanced row group cleanly; use -1 as the sentinel.  Spec A reads
# alpha_d_* and ignores the trajectory column; Spec B reads trajectory.
design["trajectory_id"] = sub["trajectory"].fillna(-1).astype(int).values

alpha_names = []
for d in trajectories:
    name = f"alpha_d_{d}"
    design[name] = (sub["trajectory"] == d).astype(float).values
    alpha_names.append(name)

beta_names = []
for s in kept:
    name = f"beta_s_{s}"
    design[name] = ((sub["trajectory"] == s) & (sub["choice"] == 1)).astype(float).values
    beta_names.append(name)

design["unbalanced"]        = sub["unbalanced"].astype(float).values
design["unbalanced_choice"] = sub["unbalanced_choice"].astype(float).values

control_names = []
for c in controls:
    design[c] = sub[c].astype(float).values
    control_names.append(c)

# Rank check.
X_cols = alpha_names + beta_names + ["unbalanced", "unbalanced_choice"] + control_names
X = design[X_cols].values
print(f"  K = {X.shape[1]} regressors (without intercept; reg_sandwich adds one)")
rank = np.linalg.matrix_rank(np.column_stack([np.ones(len(X)), X]))
print(f"  rank(X with intercept) = {rank} (max possible = {X.shape[1] + 1})")

dta_out = HERE / f"tza_{SPEC}_design.dta"
design.to_stata(dta_out, write_index=False, version=118)
print(f"  wrote {dta_out}  ({len(design):,} rows, {design.shape[1]} cols)")

sidecar = {
    "country": COUNTRY,
    "spec": SPEC,
    "n_obs": int(len(design)),
    "n_clust": int(design["pid"].nunique()),
    "trajectories": trajectories,
    "kept_switchers": [int(s) for s in kept],
    "base_switcher": int(base),
    "J_R": int(len(kept) - 1),
    "alpha_names": alpha_names,
    "beta_names": beta_names,
    "non_base_beta_names": [b for b, s in zip(beta_names, kept) if s != base],
    "control_names": control_names,
    "K_regressors_no_intercept": int(X.shape[1]),
    "rank_with_intercept": int(rank),
}
side_out = HERE / f"tza_{SPEC}_design.json"
side_out.write_text(json.dumps(sidecar, indent=2), encoding="utf-8")
print(f"  wrote {side_out}")

print("\nsummary:")
for k, v in sidecar.items():
    if isinstance(v, list) and len(v) > 8:
        print(f"  {k}: list of {len(v)}")
    else:
        print(f"  {k}: {v}")
