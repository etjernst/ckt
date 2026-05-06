"""Build estout-style comparison tables across two versions of GRC fits.

Each comparison fixes a slice (country, depvar, choice) and varies one axis
(typically `balance`, sometimes `values`, eventually `estimator`). The five
covariate sets fan across columns automatically.

Output is a pandas DataFrame with multi-index columns (version, covariate).
Display is a string-formatted DataFrame (point estimate with significance
stars, SE in parentheses on the next row).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats

import matplotlib.pyplot as plt

from scrape import SterRecord, load_ster


COV_ORDER = ["c0", "ct", "c1", "c2", "ca"]
COV_LABELS = {
    "c0": "none",
    "ct": "trend",
    "c1": "+female",
    "c2": "+age<sup>2</sup>",
    "ca": "+edu",
}

OUTPUT_DIR = Path(__file__).resolve().parents[2] / "RP7" / "output"


@dataclass
class Fit:
    """A complete fit: the main ster plus its four subgroup sters."""

    main: SterRecord
    n_rec: SterRecord | None = None
    a_rec: SterRecord | None = None
    d_rec: SterRecord | None = None
    g_rec: SterRecord | None = None

    @property
    def stem(self) -> str:
        return self.main.path.stem

    def headline(self) -> dict[str, tuple[float | None, float | None]]:
        """Return the headline (b, se) pairs in the canonical row order."""
        out: dict[str, tuple[float | None, float | None]] = {}

        if self.n_rec is not None and "Delta_never" in self.n_rec.b.index:
            out["Delta_never"] = (
                self.n_rec.b["Delta_never"], self.n_rec.se["Delta_never"]
            )
        else:
            out["Delta_never"] = (None, None)

        if "phi:_cons" in self.main.b.index:
            out["phi"] = (self.main.b["phi:_cons"], self.main.se["phi:_cons"])
        else:
            out["phi"] = (None, None)

        if self.g_rec is not None and "Delta_avg" in self.g_rec.b.index:
            out["Delta_avg"] = (
                self.g_rec.b["Delta_avg"], self.g_rec.se["Delta_avg"]
            )
        else:
            out["Delta_avg"] = (None, None)

        return out


def load_fit(stem: str, output_dir: Path = OUTPUT_DIR) -> Fit:
    """Load a main ster and its four subgroup sters by stem.

    Stem is the filename without `.ster` (e.g. `grc_IDN_cuu_ca`).
    Missing subgroup files are tolerated; the corresponding fields are None.
    """
    main_path = output_dir / f"{stem}.ster"
    main = load_ster(main_path)

    def _maybe(suffix: str) -> SterRecord | None:
        p = output_dir / f"{stem}_{suffix}.ster"
        return load_ster(p) if p.exists() else None

    return Fit(
        main=main,
        n_rec=_maybe("n"),
        a_rec=_maybe("a"),
        d_rec=_maybe("d"),
        g_rec=_maybe("g"),
    )


def _stars(b: float, se: float) -> str:
    if b is None or se is None or se == 0 or np.isnan(b) or np.isnan(se):
        return ""
    z = abs(b / se)
    p = 2 * (1 - stats.norm.cdf(z))
    if p < 0.01:
        return "<sup>***</sup>"
    if p < 0.05:
        return "<sup>**</sup>"
    if p < 0.10:
        return "<sup>*</sup>"
    return ""


def _fmt(b: float | None, se: float | None, decimals: int = 3) -> tuple[str, str]:
    if b is None or (isinstance(b, float) and np.isnan(b)):
        return ("", "")
    star = _stars(b, se) if se is not None else ""
    b_str = f"{b:.{decimals}f}{star}"
    se_str = f"({se:.{decimals}f})" if se is not None else ""
    return (b_str, se_str)


def comparison_table(
    fix: dict[str, str],
    versus: dict[str, str],
    output_dir: Path = OUTPUT_DIR,
) -> pd.DataFrame:
    """Return the formatted comparison table.

    `fix`     pins country / depvar / choice (e.g. {'country':'IDN', 'depvar':'consumption', 'choice':'urban'}).
    `versus`  maps display label -> spec3 token (e.g. {'unbalanced':'cuu', 'balanced':'cub'}).

    The five covariate sets (`c0`, `ct`, `c1`, `c2`, `ca`) fan across the columns automatically.
    """
    country = fix["country"]

    # Assemble fits: versions × covariates.
    fits: dict[tuple[str, str], Fit] = {}
    for version_label, spec3 in versus.items():
        for cov in COV_ORDER:
            stem = f"grc_{country}_{spec3}_{cov}"
            fits[(version_label, cov)] = load_fit(stem, output_dir)

    # Headline coefficient rows. Labels use Unicode + HTML so the table
    # does not depend on a math renderer (MathJax is not invoked inside
    # Quarto raw-HTML blocks).
    coef_rows = ["Delta_never", "phi", "Delta_avg"]
    coef_labels = {
        "Delta_never": "<i>&Delta;</i><sub>never</sub>",
        "phi":         "<i>&phi;</i>",
        "Delta_avg":   "<span style='text-decoration:overline;'><i>&Delta;</i></span>",
    }

    # Each coefficient occupies two display rows (estimate + SE).
    rows: list[tuple[str, str]] = []
    for c in coef_rows:
        rows.append((coef_labels[c], "b"))
        rows.append(("", f"se_{c}"))
    rows.append(("<i>J</i> p", "scalar"))
    rows.append(("<i>N</i>", "scalar"))
    rows.append(("runtime", "scalar"))

    columns = pd.MultiIndex.from_product(
        [list(versus.keys()), [COV_LABELS[c] for c in COV_ORDER]],
        names=["version", "covariates"],
    )

    data = []
    # Coefficient rows.
    for c in coef_rows:
        b_row, se_row = [], []
        for version_label in versus.keys():
            for cov in COV_ORDER:
                fit = fits[(version_label, cov)]
                b_se = fit.headline().get(c, (None, None))
                b_str, se_str = _fmt(*b_se)
                b_row.append(b_str)
                se_row.append(se_str)
        data.append(b_row)
        data.append(se_row)

    # J p, N, runtime.
    jp_row, n_row, rt_row = [], [], []
    for version_label in versus.keys():
        for cov in COV_ORDER:
            fit = fits[(version_label, cov)]
            jp_row.append(f"{fit.main.J_p:.3f}" if fit.main.J_p is not None else "")
            n_row.append(f"{fit.main.N:,}" if fit.main.N is not None else "")
            rt_row.append(f"{fit.main.runtime_s:.0f}s" if fit.main.runtime_s is not None else "")
    data.append(jp_row)
    data.append(n_row)
    data.append(rt_row)

    row_index = pd.Index(
        [r[0] for r in rows],
        name="",
    )
    return pd.DataFrame(data, index=row_index, columns=columns)


_COEF_DISPLAY = {
    "Delta_never": r"$\Delta_{\mathrm{never}}$",
    "phi":         r"$\phi$",
    "Delta_avg":   r"$\bar\Delta$",
}


def coefplot(
    fix: dict[str, str],
    versus: dict[str, str],
    output_dir: Path = OUTPUT_DIR,
    coefs: tuple[str, ...] = ("Delta_never", "phi", "Delta_avg"),
    figsize: tuple[float, float] | None = None,
) -> plt.Figure:
    """Side-by-side coefplot for the same comparison `comparison_table` builds.

    One subplot per coefficient. y-axis: covariate sets (5 ticks). x-axis:
    point estimate with 95% CI as horizontal whiskers. Versions are
    offset on the y-axis so their CIs are visible side-by-side.
    """
    country = fix["country"]
    n_cov = len(COV_ORDER)
    versions = list(versus.keys())
    n_ver = len(versions)
    cov_labels = [COV_LABELS[c] for c in COV_ORDER]
    # CSS-style label substitution for matplotlib (no HTML in mpl).
    cov_labels = [c.replace("<sup>2</sup>", "²") for c in cov_labels]

    fits: dict[tuple[str, str], Fit] = {}
    for v_label, spec3 in versus.items():
        for cov in COV_ORDER:
            stem = f"grc_{country}_{spec3}_{cov}"
            fits[(v_label, cov)] = load_fit(stem, output_dir)

    figsize = figsize or (2.8 * len(coefs), 1.8 + 0.32 * n_cov)
    fig, axes = plt.subplots(1, len(coefs), figsize=figsize, sharey=True)
    if len(coefs) == 1:
        axes = [axes]

    colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    offsets = np.linspace(-0.18, 0.18, n_ver) if n_ver > 1 else [0.0]

    for ax, coef in zip(axes, coefs):
        for v_idx, v_label in enumerate(versions):
            ys, xs, errs = [], [], []
            for cov_idx, cov in enumerate(COV_ORDER):
                fit = fits[(v_label, cov)]
                b, se = fit.headline().get(coef, (None, None))
                if b is None or se is None:
                    continue
                ys.append(cov_idx + offsets[v_idx])
                xs.append(b)
                errs.append(1.96 * se)
            ax.errorbar(
                xs, ys, xerr=errs, fmt="o",
                color=colors[v_idx % len(colors)],
                ecolor=colors[v_idx % len(colors)],
                capsize=2.5, markersize=4.5, linewidth=1.0,
                label=v_label,
            )
        ax.axvline(0, color="grey", linewidth=0.6, linestyle=":")
        ax.set_yticks(range(n_cov))
        ax.set_yticklabels(cov_labels)
        ax.set_title(_COEF_DISPLAY.get(coef, coef))
        ax.invert_yaxis()
        ax.grid(True, axis="x", alpha=0.25, linewidth=0.5)
        ax.spines["top"].set_visible(False)
        ax.spines["right"].set_visible(False)

    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(
        handles, labels,
        loc="lower center",
        ncol=len(labels),
        frameon=False,
        fontsize="small",
        bbox_to_anchor=(0.5, -0.02),
    )
    fig.tight_layout(rect=(0, 0.06, 1, 1))
    return fig


def render_table(table: pd.DataFrame) -> str:
    """Render the comparison table as raw HTML.

    Hand-built HTML lets us use colspan for the version spanners, escapes
    nothing, and passes through both Quarto HTML (rendered natively) and
    GFM (GitHub renders inline HTML tables) targets. The wrapping
    ``{=html}`` raw block in the qmd ensures pandoc does not touch it.
    """
    versions = list(table.columns.get_level_values(0).unique())
    n_per_version = len(table.columns) // len(versions)
    cov_labels = list(table.columns.get_level_values(1))[:n_per_version]

    # The diagnostic-row index identifies where to drop a thicker rule.
    diagnostic_labels = {"<i>J</i> p", "<i>N</i>", "runtime"}
    first_diag_seen = False

    rows: list[str] = []
    rows.append("<table class='results-overview'>")
    rows.append("<thead>")
    # Span row: a thin midrule under each version label, broken in the
    # gap between the two contrasts. The rule sits on an inner <div>
    # with horizontal margin so adjacent cells' rules do not touch.
    span_cells = "<th></th>" + "".join(
        f"<th colspan='{n_per_version}' style='text-align:center;'>"
        f"<div style='border-bottom:1px solid #444; margin:0 18px; padding-bottom:2px;'>"
        f"{v}</div></th>"
        for v in versions
    )
    rows.append(f"<tr>{span_cells}</tr>")
    cov_cells = "<th></th>" + "".join(
        f"<th style='text-align:right;'>{c}</th>" for c in cov_labels * len(versions)
    )
    rows.append(f"<tr>{cov_cells}</tr>")
    rows.append("</thead><tbody>")
    for idx, row in table.iterrows():
        # Thick rule above the first diagnostic row to separate
        # coefficients from sample-info rows.
        if str(idx) in diagnostic_labels and not first_diag_seen:
            tr_style = " style='border-top:2px solid #444;'"
            first_diag_seen = True
        else:
            tr_style = ""
        body = "".join(
            f"<td style='text-align:right;'>{v}</td>" for v in row.values
        )
        rows.append(f"<tr{tr_style}><td>{idx}</td>{body}</tr>")
    rows.append("</tbody></table>")
    return "\n".join(rows)


if __name__ == "__main__":
    pd.set_option("display.max_columns", None)
    pd.set_option("display.width", 200)
    table = comparison_table(
        fix={"country": "IDN", "depvar": "consumption", "choice": "urban"},
        versus={"unbalanced": "cuu", "balanced": "cub"},
    )
    print(table)
