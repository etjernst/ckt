"""Compute per-rep monitor summary statistics.

Joins the dual-J stability rep CSV with the system monitor CSV via
start_clock/end_clock windows. Outputs per_rep_monitor_summary.csv with one
row per replicate.
"""
from pathlib import Path

import numpy as np
import pandas as pd

OUT = Path("C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output")
MON = OUT / "monitor_20260505_215248.csv"
REP = OUT / "stability_dual_2026May5_215257.csv"
DST = OUT / "per_rep_monitor_summary.csv"

mon = pd.read_csv(MON, comment="#", skiprows=[1, 2, 3])
mon["timestamp"] = pd.to_datetime(mon["timestamp"])

reps = pd.read_csv(REP)
reps["start_clock"] = pd.to_datetime(reps["start_clock"].str.strip(), format="%d %b %Y %H:%M:%S")
reps["end_clock"] = pd.to_datetime(reps["end_clock"].str.strip(), format="%d %b %Y %H:%M:%S")

rows = []
for _, r in reps.iterrows():
    mask = (mon["timestamp"] >= r["start_clock"]) & (mon["timestamp"] <= r["end_clock"])
    sub = mon.loc[mask].copy()
    if len(sub) < 2:
        rows.append({"J": r["J_target"], "rep": r["rep"], "monitor_samples": len(sub)})
        continue

    sub_st = sub.dropna(subset=["stata_cpu_sec"])
    if len(sub_st) >= 2:
        dt = (sub_st["timestamp"].iloc[-1] - sub_st["timestamp"].iloc[0]).total_seconds()
        dcpu = sub_st["stata_cpu_sec"].iloc[-1] - sub_st["stata_cpu_sec"].iloc[0]
        cpu_rate = dcpu / dt if dt > 0 else np.nan
    else:
        cpu_rate = np.nan

    rows.append(
        {
            "J": r["J_target"],
            "rep": r["rep"],
            "wall_seconds": r["wall_seconds"],
            "monitor_samples": len(sub),
            "cpu_pct_mean": round(sub["cpu_pct"].mean(), 1),
            "cpu_pct_med": round(sub["cpu_pct"].median(), 1),
            "cpu_pct_max": round(sub["cpu_pct"].max(), 1),
            "cpu_perf_pct_mean": round(sub["cpu_perf_pct"].mean(), 1),
            "cpu_perf_pct_med": round(sub["cpu_perf_pct"].median(), 1),
            "cpu_perf_pct_min": round(sub["cpu_perf_pct"].min(), 1),
            "cpu_perf_pct_max": round(sub["cpu_perf_pct"].max(), 1),
            "mem_used_gb_mean": round(sub["mem_used_gb"].mean(), 2),
            "mem_used_gb_max": round(sub["mem_used_gb"].max(), 2),
            "mem_commit_gb_mean": round(sub["mem_commit_gb"].mean(), 2),
            "pagefile_pct_mean": round(sub["pagefile_pct"].mean(), 2),
            "pagefile_pct_max": round(sub["pagefile_pct"].max(), 2),
            "stata_ws_gb_mean": round(sub["stata_ws_gb"].mean(), 3),
            "stata_ws_gb_max": round(sub["stata_ws_gb"].max(), 3),
            "stata_cpu_sec_per_wall_sec": round(cpu_rate, 3) if not np.isnan(cpu_rate) else None,
            "stata_threads_med": int(sub["stata_threads"].median()) if not sub["stata_threads"].isna().all() else None,
        }
    )

out = pd.DataFrame(rows)
out.to_csv(DST, index=False)
print(out.to_string(index=False))
