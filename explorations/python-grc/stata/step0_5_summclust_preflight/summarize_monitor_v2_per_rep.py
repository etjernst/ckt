"""Compute per-rep monitor summary statistics from v2 monitor.

v2 monitor has per-core perf and util as pipe-separated strings, plus
stata_count to handle multiple StataMP processes.

Joins the dual-J reverse stability rep CSV with the v2 monitor CSV via
start_clock/end_clock windows.
"""
from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path("C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output")
MON = OUT / "monitor_v2_20260506_070205.csv"
REP = OUT / "stability_dual_reverse_2026May6_070216.csv"
DST = OUT / "per_rep_monitor_summary_v2.csv"

mon = pd.read_csv(MON, comment="#", skiprows=[1, 2, 3])
mon["timestamp"] = pd.to_datetime(mon["timestamp"])

reps = pd.read_csv(REP)
reps["start_clock"] = pd.to_datetime(reps["start_clock"].str.strip(), format="%d %b %Y %H:%M:%S")
reps["end_clock"] = pd.to_datetime(reps["end_clock"].str.strip(), format="%d %b %Y %H:%M:%S")


def parse_pipe_cols(s):
    """Parse a pipe-separated string of floats into a list. NaN if missing."""
    if pd.isna(s) or s == "":
        return None
    try:
        return [float(x) for x in str(s).split("|")]
    except ValueError:
        return None


# Expand per-core columns into arrays we can summarize over time within a rep window.
mon["perf_cores"] = mon["perf_per_core"].apply(parse_pipe_cols)
mon["util_cores"] = mon["util_per_core"].apply(parse_pipe_cols)

rows = []
for _, r in reps.iterrows():
    mask = (mon["timestamp"] >= r["start_clock"]) & (mon["timestamp"] <= r["end_clock"])
    sub = mon.loc[mask].copy()
    if len(sub) < 2:
        rows.append({"J": r["J_target"], "rep": r["rep"], "monitor_samples": len(sub)})
        continue

    sub_st = sub.dropna(subset=["stata_cpu_sec_total"])
    if len(sub_st) >= 2:
        dt = (sub_st["timestamp"].iloc[-1] - sub_st["timestamp"].iloc[0]).total_seconds()
        dcpu = sub_st["stata_cpu_sec_total"].iloc[-1] - sub_st["stata_cpu_sec_total"].iloc[0]
        cpu_rate = dcpu / dt if dt > 0 else np.nan
    else:
        cpu_rate = np.nan

    # Per-core stats: stack into arrays
    perf_arrays = [a for a in sub["perf_cores"] if a is not None]
    util_arrays = [a for a in sub["util_cores"] if a is not None]
    if perf_arrays:
        perf_mat = np.array(perf_arrays)  # rows: time, cols: cores
        util_mat = np.array(util_arrays)
        # For each core, mean perf and util across the rep window
        core_perf_mean = perf_mat.mean(axis=0)
        core_util_mean = util_mat.mean(axis=0)
        # Identify "Stata-active" cores: cores where util > 50% on average
        active_mask = core_util_mean > 50
        active_cores = np.where(active_mask)[0].tolist()
        # Mean perf on active cores
        if active_mask.any():
            mean_perf_active = core_perf_mean[active_mask].mean()
            min_perf_active = core_perf_mean[active_mask].min()
        else:
            # No core consistently active; report top-utilization core
            top_idx = int(np.argmax(core_util_mean))
            active_cores = [top_idx]
            mean_perf_active = core_perf_mean[top_idx]
            min_perf_active = core_perf_mean[top_idx]
    else:
        active_cores = []
        mean_perf_active = np.nan
        min_perf_active = np.nan

    rows.append(
        {
            "J": r["J_target"],
            "rep": r["rep"],
            "wall_seconds": r["wall_seconds"],
            "monitor_samples": len(sub),
            "cpu_pct_mean": round(sub["cpu_pct"].mean(), 1),
            "cpu_perf_pct_mean": round(sub["cpu_perf_pct"].mean(), 1),
            "cpu_perf_pct_min": round(sub["cpu_perf_pct"].min(), 1),
            "cpu_perf_pct_max": round(sub["cpu_perf_pct"].max(), 1),
            "mem_used_gb_mean": round(sub["mem_used_gb"].mean(), 2),
            "mem_used_gb_max": round(sub["mem_used_gb"].max(), 2),
            "mem_commit_gb_mean": round(sub["mem_commit_gb"].mean(), 2),
            "mem_commit_gb_max": round(sub["mem_commit_gb"].max(), 2),
            "pagefile_pct_mean": round(sub["pagefile_pct"].mean(), 2),
            "pagefile_pct_max": round(sub["pagefile_pct"].max(), 2),
            "stata_count_mode": int(sub["stata_count"].mode().iloc[0]) if not sub["stata_count"].isna().all() else None,
            "stata_count_max": int(sub["stata_count"].max()) if not sub["stata_count"].isna().all() else None,
            "stata_ws_gb_mean": round(sub["stata_ws_gb_total"].mean(), 3),
            "stata_ws_gb_max": round(sub["stata_ws_gb_total"].max(), 3),
            "stata_threads_med": int(sub["stata_threads_total"].median()) if not sub["stata_threads_total"].isna().all() else None,
            "stata_cpu_sec_per_wall_sec": round(cpu_rate, 3) if not np.isnan(cpu_rate) else None,
            "stata_active_cores": ",".join(map(str, active_cores)),
            "n_stata_active_cores": len(active_cores),
            "mean_perf_pct_active_cores": round(mean_perf_active, 1) if not np.isnan(mean_perf_active) else None,
            "min_perf_pct_active_cores": round(min_perf_active, 1) if not np.isnan(min_perf_active) else None,
        }
    )

out = pd.DataFrame(rows)
out.to_csv(DST, index=False)
print(out.to_string(index=False))
