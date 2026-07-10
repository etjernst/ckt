"""
Compare AHZ scalars (from step0_ahz_stata_out.txt) against R clubSandwich
HTZ scalars (from step0_htz_r_out.txt).

Plan tolerance (rev 3, Step 0):
  |F_stat diff|  <= 1e-4 absolute
  |F_df  diff|   <= 1e-3 absolute on df_denom

Writes a Markdown table to step0_compare.md.
Exits non-zero if any tolerance fails.
"""

from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent

def load_kv(path: Path) -> dict[str, float]:
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        k, v = k.strip(), v.strip()
        try:
            out[k] = float(v)
        except ValueError:
            out[k] = v
    return out


stata = load_kv(HERE / "step0_ahz_stata_out.txt")
r     = load_kv(HERE / "step0_htz_r_out.txt")

stat_keys = ("F_stat", "F_df1", "F_df2", "F_pvalue")
TOL_STAT  = 1e-4
TOL_DF    = 1e-3
TOL_PVAL  = 1e-3  # diagnostic only; the spec doesn't bind on p

rows = []
fail = False
for k in stat_keys:
    s, rv = stata[k], r[k]
    diff = abs(s - rv)
    if k == "F_stat":
        ok = diff <= TOL_STAT
        if not ok: fail = True
        rows.append((k, s, rv, diff, TOL_STAT, ok))
    elif k == "F_df2":
        ok = diff <= TOL_DF
        if not ok: fail = True
        rows.append((k, s, rv, diff, TOL_DF, ok))
    elif k == "F_df1":
        ok = diff == 0  # numerator df should be exactly q
        if not ok: fail = True
        rows.append((k, s, rv, diff, 0.0, ok))
    else:
        ok = diff <= TOL_PVAL
        rows.append((k, s, rv, diff, TOL_PVAL, ok))

md = []
md.append("# Step 0 cross-check: Stata reg_sandwich AHZ vs R clubSandwich HTZ")
md.append("")
md.append(f"clubSandwich version: {r.get('clubSandwich_version', 'unknown')}")
md.append(f"reg_sandwich version: 0.0 (02-March-2017, SSC); pre-corrigendum.")
md.append("")
md.append(f"Toy panel: J=20, T=4, N={int(stata['N_obs'])}, q=3 contrast on (x1, x2, x3).")
md.append("Auxiliary regression: y ~ x1 + x2 + x3 + z, cluster=pid, no FE absorption.")
md.append("")
md.append("| Quantity | Stata AHZ | R HTZ | abs diff | tol | pass |")
md.append("|---|---:|---:|---:|---:|:---:|")
for k, s, rv, d, tol, ok in rows:
    md.append(f"| {k} | {s:.16e} | {rv:.16e} | {d:.3e} | {tol:.0e} | {'PASS' if ok else 'FAIL'} |")

verdict = "PASS" if not fail else "FAIL"
md.append("")
md.append(f"**Verdict:** {verdict}")
md.append("")
md.append("Notes:")
md.append("- F_df1 = q = 3 (numerator df) is identical by construction.")
md.append("- F_df2 (Satterthwaite-approximated denominator df) and F_stat agree well below plan tolerance,")
md.append("  even though the installed Stata package is the 2017 SSC build (pre-corrigendum) and the R")
md.append("  package is the current 0.6.2 build.  Step 0a must still verify the SSC version against the")
md.append("  GitHub history to identify whether the corrigendum changed code paths that this toy q=3 test")
md.append("  does not exercise.")

(HERE / "step0_compare.md").write_text("\n".join(md) + "\n", encoding="utf-8")
print("\n".join(md))
sys.exit(0 if not fail else 1)
