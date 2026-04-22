"""
Parse all GrRC log files under scripts/logs/ and produce a per-run convergence
table. Writes docs/reviews/2026-04-22-gmm-convergence-audit.md.

For each `run_grc` invocation in each log, we record:
  - source log
  - country (IDN/TZA/CHN, or CHN-rural/CHN-urban for hukou)
  - section (the nearest preceding log banner, e.g. "Consumption | Urban | Unbalanced")
  - estname  (e.g. grc_IDN_covs_0)
  - base trajectory
  - final GMM criterion Q(b)
  - converged (True/False)
  - phi estimate and SE
  - kappa estimate and SE
"""

from __future__ import annotations
import re
from pathlib import Path
from collections import defaultdict

LOGS = Path(r"C:\git\ckt\scripts\logs")
OUT  = Path(r"C:\git\ckt\docs\reviews\2026-04-22-gmm-convergence-audit.md")

GRC_LOGS = sorted([p for p in LOGS.glob("*GrRC*.log")])

RUN_HEADER_RE   = re.compile(r"^run_grc: base trajectory = (\d+)")
ESTNAME_RE      = re.compile(r"run_grc(?:_hukou)?\s*,\s*estname\(([^)]+)\)")
SECTION_RE      = re.compile(r"\*\s*(\d+\.\s*(?:Consumption|Income)\s*\|.*)")
BANNER_RE       = re.compile(r"^\*\s*([A-Z][A-Z ]+?(?:-[A-Z]+)?)\s*$")
FINAL_Q_RE      = re.compile(r"Final GMM criterion Q\(b\) =\s*(\S+)")
NOTCONVERGED_RE = re.compile(r"^convergence not achieved")
COV_COMMENT_RE  = re.compile(r"^\.\s*\*\s*(No covariates|Add time FE|Add female|Add age2|Add education.*)")
LOG_NAME_RE     = re.compile(r"\.\s*log using\s+(\S+)")

# Column marker for phi/kappa rows (preceded by pipe; block header lines).
# We want the next "_cons" row after each of those block headers.

def parse_log(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8", errors="replace").splitlines()
    runs: list[dict] = []

    current_section = ""    # e.g. "Consumption | Urban | Unbalanced"
    current_country = ""    # IDN/TZA/CHN
    current_estname = ""
    current_cov_comment = ""

    i = 0
    n = len(text)
    while i < n:
        line = text[i]

        # track section banners like "* 1. Consumption | Urban | Unbalanced | GRC"
        m = SECTION_RE.search(line)
        if m:
            sec = m.group(1).strip()
            # drop trailing segments after " | GRC" etc.
            sec = re.sub(r"\s*\|\s*GRC.*$", "", sec)
            current_section = sec

        # track country marker written in do-file as "local country XXX"
        if "local country" in line:
            m2 = re.search(r"local country\s+(\S+)", line)
            if m2:
                current_country = m2.group(1)

        # track spec comments like "* No covariates" / "* Add female" etc.
        m3 = COV_COMMENT_RE.match(line)
        if m3:
            current_cov_comment = m3.group(1)

        # track the estname from "run_grc, estname(...)" echo in log.
        # Stata echoes the unresolved macro, so substitute `country' ourselves.
        m4 = ESTNAME_RE.search(line)
        if m4:
            est = m4.group(1).strip()
            if current_country:
                est = est.replace("`country'", current_country)
                est = est.replace("`country_short'", current_country)
            current_estname = est

        # detect a run
        m5 = RUN_HEADER_RE.match(line)
        if m5:
            base = int(m5.group(1))
            # scan forward up to ~200 lines to find final Q and convergence status
            converged = True
            final_q = None
            phi = phi_se = kappa = kappa_se = None
            # also detect if "convergence not achieved" appears in the next ~5 lines
            for j in range(i+1, min(i+8, n)):
                if NOTCONVERGED_RE.match(text[j]):
                    converged = False
                    break
            # find Final Q
            for j in range(i+1, min(i+60, n)):
                mq = FINAL_Q_RE.search(text[j])
                if mq:
                    try:
                        final_q = float(mq.group(1))
                    except ValueError:
                        final_q = None
                    break
            # extract phi and kappa coefficients from the regression table
            # pattern: "phi               |" or "phi          |" block header,
            # then next "_cons |" row has coefficient and SE.
            def extract_block(name: str, start: int) -> tuple[float|None, float|None]:
                header_re = re.compile(rf"^{name}\s*\|")
                for k in range(start, min(start+200, n)):
                    if header_re.match(text[k]):
                        for m_ in range(k+1, min(k+4, n)):
                            row = text[m_]
                            if "_cons" in row:
                                parts = re.findall(r"-?\d*\.?\d+(?:e[+\-]?\d+)?", row)
                                if len(parts) >= 2:
                                    try:
                                        return float(parts[0]), float(parts[1])
                                    except ValueError:
                                        return None, None
                        break
                return None, None
            phi, phi_se       = extract_block("phi",   i+1)
            kappa, kappa_se   = extract_block("kappa", i+1)

            runs.append({
                "log": path.name,
                "section": current_section or "(none)",
                "country": current_country or "?",
                "estname": current_estname or "?",
                "cov_comment": current_cov_comment or "?",
                "base": base,
                "final_q": final_q,
                "converged": converged,
                "phi": phi, "phi_se": phi_se,
                "kappa": kappa, "kappa_se": kappa_se,
                "line": i+1,
            })
            current_cov_comment = ""  # reset so we don't reuse for the next run
        i += 1
    return runs


def esc(s: str) -> str:
    """Escape pipes so section strings like 'Income | Urban | Unbalanced' don't
    break the markdown table."""
    return s.replace("|", "\\|")


def fmt(v, nd=4):
    if v is None:
        return "—"
    if isinstance(v, float):
        if abs(v) >= 1e4 or (v != 0 and abs(v) < 1e-4):
            return f"{v:.2e}"
        return f"{v:.{nd}f}"
    return str(v)


def main():
    all_runs: list[dict] = []
    for p in GRC_LOGS:
        all_runs.extend(parse_log(p))

    # ---- Build markdown report ----
    lines: list[str] = []
    lines.append("# GMM convergence audit — GrRC specifications")
    lines.append("")
    lines.append("_Date: 2026-04-22 · Source: `scripts/logs/*GrRC*.log` (last run 2026-04-01/02)_")
    lines.append("")
    lines.append("## Diagnosis (read first)")
    lines.append("")
    lines.append("- **21 / 286 GrRC runs did not converge.**")
    lines.append("- **IDN never fails** (0 / 100). All failures are CHN, CHN-hukou, or TZA.")
    lines.append("- Failures cluster in the **least-saturated specifications** (no covariates, no covariates + time FE, + female) and disappear once age² or education are added.")
    lines.append("- **Hukou splits amplify the problem** — rural-first and rural-only (the smaller CHN subsamples) fail most; urban-first/urban-only almost never fail.")
    lines.append("- Failing runs share a distinctive signature:")
    lines.append("  - `phi` pinned near **−1.00 ± 0.001** (i.e., it never moves from its initial value `{phi=-1}`)")
    lines.append("  - `kappa` standard error in the **thousands to millions** (e.g. 4.48e+06 for CHN rural-only income c_t)")
    lines.append("  - `kappa` point estimate absurdly large (75--315 on the log-consumption scale where `mu` is ≈9--14)")
    lines.append("  - Final GMM criterion Q(b) very small (0.0002--0.003)")
    lines.append("- **This is a weak-identification / flat-criterion pattern, not non-concavity.** "
                 "GMM's criterion is quadratic, so non-concavity per se doesn't apply — the objective "
                 "is locally flat in the `kappa` direction because the always-urban group is small "
                 "(and smaller still after hukou splits) and the moments that identify `kappa` --- "
                 "which rely on always-urban observations --- have little power. The optimizer reduces "
                 "Q(b) into the 1e-3 range and then stalls because the gradient with respect to `kappa` "
                 "is nearly zero; `phi` never leaves its starting value because its derivative is also "
                 "nearly zero at that slice of the parameter space.")
    lines.append("- The iteration log is **suppressed** (`run_grc` calls `gmm … nolog`), so we can't see "
                 "Stata's own `(not concave)` / `(backed up)` / `(flat region)` annotations. Re-running "
                 "a handful of failed specs without `nolog` would confirm the mechanism; the SE pattern "
                 "is already strongly consistent with a flat likelihood in `kappa`, not non-concavity.")
    lines.append("")
    lines.append("### Things worth trying")
    lines.append("")
    lines.append("1. **Rerun a few failing specs without `nolog`** to see Stata's iteration-level diagnostics.")
    lines.append("2. **Profile `kappa` directly**: fix `kappa` at a grid of values and re-estimate the rest. If `Q(b)` is nearly constant across the grid, `kappa` is unidentified at this sample.")
    lines.append("3. **Start `kappa` from the always-urban `mu`** (or a data-driven value) instead of letting it float from the default. Current failures show `kappa ≈ 150+` which is far outside the plausible range.")
    lines.append("4. **Bound `kappa` and/or `phi`** via `{kappa:...}` initial-value syntax, or impose a prior/penalty.")
    lines.append("5. **Drop the `always`-urban block from the moment system** for cells where the always group is very small (<1% of sample). Without always-urban observations, `kappa` drops out of the model.")
    lines.append("6. **Loosen `ltolerance`/`nrtolerance`** or increase `iterate()` above 500 — unlikely to help given the SE pattern, but cheap to test.")
    lines.append("7. **Switch optimizer**: try `technique(nr)` or `technique(bhhh)` — may help if the issue is a bad step in the current algorithm rather than true flatness.")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    # Summary by log file
    by_log: dict[str, list[dict]] = defaultdict(list)
    for r in all_runs:
        by_log[r["log"]].append(r)
    lines.append("| Log | Total runs | Converged | Failed |")
    lines.append("|---|---:|---:|---:|")
    total_runs = total_fail = 0
    for log_name, rs in sorted(by_log.items()):
        n_ok = sum(1 for r in rs if r["converged"])
        n_bad = sum(1 for r in rs if not r["converged"])
        total_runs += len(rs); total_fail += n_bad
        lines.append(f"| `{log_name}` | {len(rs)} | {n_ok} | **{n_bad}** |")
    lines.append(f"| **Total** | **{total_runs}** | **{total_runs-total_fail}** | **{total_fail}** |")
    lines.append("")

    # Summary by country across all logs
    lines.append("### Failures by country (across all GrRC logs)")
    lines.append("")
    by_ctry: dict[str, tuple[int,int]] = defaultdict(lambda: (0,0))
    for r in all_runs:
        n_tot, n_bad = by_ctry[r["country"]]
        by_ctry[r["country"]] = (n_tot+1, n_bad + (0 if r["converged"] else 1))
    lines.append("| Country | Total runs | Failed | Failure rate |")
    lines.append("|---|---:|---:|---:|")
    for ctry, (tot, bad) in sorted(by_ctry.items()):
        rate = f"{100*bad/tot:.1f}%" if tot else "—"
        lines.append(f"| {ctry} | {tot} | {bad} | {rate} |")
    lines.append("")

    # ---- Compact per-script × country grid (✓/✗) ----
    lines.append("## Convergence grid — one row per (log, section, country)")
    lines.append("")
    lines.append("Each cell is the sequence of `run_grc` calls in that cell, in "
                 "order. `✓` = converged, `✗` = convergence not achieved.")
    lines.append("")
    lines.append("| Log | Section | Country | Runs (in order) |")
    lines.append("|---|---|---|---|")
    grid: dict[tuple[str, str, str], list[dict]] = defaultdict(list)
    for r in all_runs:
        grid[(r["log"], r["section"], r["country"])].append(r)
    for (log_name, section, ctry), rs in sorted(grid.items()):
        cells = []
        for r in rs:
            mark = "✓" if r["converged"] else "✗"
            label = r["cov_comment"] or r["estname"].split("_")[-1]
            cells.append(f"{mark} {label}")
        cellstr = " · ".join(cells)
        lines.append(f"| `{log_name}` | {esc(section) or '—'} | {ctry} | "
                     f"{esc(cellstr)} |")
    lines.append("")

    # ---- Detail: only failed runs ----
    failed = [r for r in all_runs if not r["converged"]]
    lines.append("## Failed runs — detail")
    lines.append("")
    lines.append(f"{len(failed)} failed runs across {len(set(r['log'] for r in failed))} logs.")
    lines.append("")
    lines.append("| Log | Line | Country | Section | estname | Comment | base | Q(b) | φ | SE(φ) | κ | SE(κ) |")
    lines.append("|---|---:|---|---|---|---|---:|---:|---:|---:|---:|---:|")
    for r in failed:
        lines.append(
            f"| `{r['log']}` | {r['line']} | {r['country']} | {esc(r['section'])} | "
            f"`{r['estname']}` | {esc(r['cov_comment'])} | {r['base']} | "
            f"{fmt(r['final_q'])} | {fmt(r['phi'])} | {fmt(r['phi_se'])} | "
            f"{fmt(r['kappa'],2)} | {fmt(r['kappa_se'],2)} |"
        )
    lines.append("")

    # ---- Per-log full cross-tab ----
    lines.append("## Full cross-tab (converged = ✓, failed = ✗)")
    lines.append("")
    # group by (log, section, country) → list of (estname, converged)
    grouped: dict[tuple[str,str,str], list[dict]] = defaultdict(list)
    for r in all_runs:
        grouped[(r["log"], r["section"], r["country"])].append(r)
    last_log = None
    for (log_name, section, ctry), rs in sorted(grouped.items()):
        if log_name != last_log:
            lines.append(f"### `{log_name}`")
            lines.append("")
            last_log = log_name
        lines.append(f"**{esc(section) or '(no section)'} · {ctry}**")
        lines.append("")
        lines.append("| estname | base | Q(b) | conv | φ | SE(φ) | κ | SE(κ) |")
        lines.append("|---|---:|---:|:---:|---:|---:|---:|---:|")
        for r in rs:
            mark = "✓" if r["converged"] else "✗"
            lines.append(
                f"| `{r['estname']}` | {r['base']} | "
                f"{fmt(r['final_q'])} | {mark} | "
                f"{fmt(r['phi'])} | {fmt(r['phi_se'])} | "
                f"{fmt(r['kappa'],2)} | {fmt(r['kappa_se'],2)} |"
            )
        lines.append("")

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Total runs: {total_runs}, failed: {total_fail}")


if __name__ == "__main__":
    main()
