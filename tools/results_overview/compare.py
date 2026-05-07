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


COV_ORDER = ["c0", "ct", "c1", "c2", "c3", "ca"]
COV_LABELS = {
    "c0": "none",
    "ct": "trend",
    "c1": "+female",
    "c2": "+age<sup>2</sup>",
    "c3": "+age<sup>2</sup>",
    "ca": "+edu",
}

# Family-extras fits start the ladder at c1 = `<extra> + period FE` (no `c0` /
# `ct`). The covariate-set tokens carry different meanings, so the labels are
# overridden when a family is specified.
COV_LABELS_FAMILY = {
    "c1": "+extra",
    "c2": "+female",
    "c3": "+age<sup>2</sup>",
    "ca": "+edu",
}

CANONICAL_COV_ORDER = ["c0", "ct", "c1", "c2", "c3", "ca"]

OUTPUT_DIR = Path(__file__).resolve().parents[2] / "RP7" / "output"

import re as _re

_SPEC3_REV = {
    "consumption": "c", "income": "i",
    "urban":       "u", "nonag":  "n",
    "unbalanced":  "u", "balanced": "b",
}


def _spec3_from_fix(cfg: dict) -> str:
    """Build the 3-char spec3 token from semantic fix keys."""
    if "spec3" in cfg:
        return cfg["spec3"]
    return (_SPEC3_REV[cfg["depvar"]]
            + _SPEC3_REV[cfg["choice"]]
            + _SPEC3_REV[cfg["balance"]])


def _stem_for(cfg: dict) -> str:
    """Build the filename stem (without `_<cov>.ster`) from a config dict."""
    parts = ["grc", cfg["country"]]
    if cfg.get("hukou"):
        parts.append(cfg["hukou"])
    parts.append(_spec3_from_fix(cfg))
    if cfg.get("family"):
        parts.append(cfg["family"])
    return "_".join(parts)


def _discover_covs(stem: str, output_dir: Path) -> list[str]:
    """Glob for `{stem}_<cov>.ster` and return cov tokens in canonical order."""
    pattern = _re.compile(rf"^{_re.escape(stem)}_(c[0-9ta])\.ster$")
    found: set[str] = set()
    for p in output_dir.glob(f"{stem}_*.ster"):
        m = pattern.match(p.name)
        if m:
            found.add(m.group(1))
    return [c for c in CANONICAL_COV_ORDER if c in found]


def _normalize_versus(versus: dict) -> dict[str, dict]:
    """Convert legacy spec3-string values into override dicts.

    Accepts:
      `{"unbalanced": "cuu", "balanced": "cub"}`     (legacy: spec3 string)
      `{"main": {}, "experience": {"family":"exp"}}` (modern: override dict)
    """
    out: dict[str, dict] = {}
    for label, val in versus.items():
        if isinstance(val, dict):
            out[label] = dict(val)
        elif isinstance(val, str) and len(val) == 3 and val[0] in "ci":
            out[label] = {"spec3": val}
        else:
            raise ValueError(f"versus value {val!r} not recognized")
    return out


def _cov_labels_for(version_cfg: dict) -> dict[str, str]:
    """Return the cov-label map appropriate for a version (main vs family)."""
    return COV_LABELS_FAMILY if version_cfg.get("family") else COV_LABELS


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
    versus: dict[str, str | dict],
    output_dir: Path = OUTPUT_DIR,
) -> pd.DataFrame:
    """Return the formatted comparison table.

    `fix`     pins shared dimensions (country, depvar, choice, balance, plus
              optionally hukou or family). Country is required; the rest are
              required only if `versus` does not override them.
    `versus`  maps display label to either:
                - a 3-char spec3 token (legacy: `'cuu'`), or
                - an override dict (`{'family': 'exp'}`, `{'hukou': 'rf'}`,
                  `{'balance': 'balanced'}`, etc.).
              Each version's filename stem is built by merging `fix` with the
              version's overrides.

    Each version's covariate-set list is auto-discovered from disk, so a main
    fit (5 cov sets: c0/ct/c1/c2/ca) can sit next to a family-extras fit
    (4 cov sets: c1/c2/c3/ca) without forcing a common axis.
    """
    versus_norm = _normalize_versus(versus)

    # Per-version: merged config, stem, available cov tokens, fits.
    version_cfgs: dict[str, dict] = {}
    version_covs: dict[str, list[str]] = {}
    fits: dict[tuple[str, str], Fit] = {}
    for label, override in versus_norm.items():
        cfg = {**fix, **override}
        version_cfgs[label] = cfg
        stem = _stem_for(cfg)
        covs = _discover_covs(stem, output_dir)
        if not covs:
            raise FileNotFoundError(
                f"no '{stem}_<cov>.ster' files found in {output_dir}"
            )
        version_covs[label] = covs
        for cov in covs:
            fits[(label, cov)] = load_fit(f"{stem}_{cov}", output_dir)

    coef_rows = ["Delta_never", "phi", "Delta_avg"]
    coef_labels = {
        "Delta_never": "<i>&Delta;</i><sub>never</sub>",
        "phi":         "<i>&phi;</i>",
        "Delta_avg":   "<span style='text-decoration:overline;'><i>&Delta;</i></span>",
    }

    # Each coefficient occupies two display rows (estimate + SE).
    rows_idx: list[str] = []
    for c in coef_rows:
        rows_idx.append(coef_labels[c])
        rows_idx.append("")
    rows_idx.append("<i>J</i> p")
    rows_idx.append("<i>N</i>")
    rows_idx.append("runtime")

    # Build column tuples version-by-version (variable width per version).
    column_tuples: list[tuple[str, str]] = []
    for label in versus_norm:
        cov_lbl_map = _cov_labels_for(version_cfgs[label])
        for cov in version_covs[label]:
            column_tuples.append((label, cov_lbl_map[cov]))
    columns = pd.MultiIndex.from_tuples(column_tuples, names=["version", "covariates"])

    data: list[list[str]] = []
    for c in coef_rows:
        b_row, se_row = [], []
        for label in versus_norm:
            for cov in version_covs[label]:
                fit = fits[(label, cov)]
                b_se = fit.headline().get(c, (None, None))
                b_str, se_str = _fmt(*b_se)
                b_row.append(b_str)
                se_row.append(se_str)
        data.append(b_row)
        data.append(se_row)

    jp_row, n_row, rt_row = [], [], []
    for label in versus_norm:
        for cov in version_covs[label]:
            fit = fits[(label, cov)]
            jp_row.append(f"{fit.main.J_p:.3f}" if fit.main.J_p is not None else "")
            n_row.append(f"{fit.main.N:,}" if fit.main.N is not None else "")
            rt_row.append(f"{fit.main.runtime_s:.0f}s" if fit.main.runtime_s is not None else "")
    data.append(jp_row)
    data.append(n_row)
    data.append(rt_row)

    return pd.DataFrame(data, index=pd.Index(rows_idx, name=""), columns=columns)


_COEF_DISPLAY = {
    "Delta_never": r"$\Delta_{\mathrm{never}}$",
    "phi":         r"$\phi$",
    "Delta_avg":   r"$\bar\Delta$",
}


def coefplot(
    fix: dict[str, str],
    versus: dict[str, str | dict],
    output_dir: Path = OUTPUT_DIR,
    coefs: tuple[str, ...] = ("Delta_never", "phi", "Delta_avg"),
    figsize: tuple[float, float] | None = None,
) -> plt.Figure:
    """Side-by-side coefplot for the same comparison `comparison_table` builds.

    One subplot per coefficient. y-axis: union of covariate sets seen across
    versions, in canonical order. x-axis: point estimate with 95% CI. Versions
    are offset on the y-axis so their CIs are visible side-by-side. A version
    that lacks a particular cov set simply has no marker on that row.
    """
    versus_norm = _normalize_versus(versus)
    versions = list(versus_norm.keys())
    n_ver = len(versions)

    version_cfgs: dict[str, dict] = {}
    version_covs: dict[str, list[str]] = {}
    fits: dict[tuple[str, str], Fit] = {}
    for label, override in versus_norm.items():
        cfg = {**fix, **override}
        version_cfgs[label] = cfg
        stem = _stem_for(cfg)
        covs = _discover_covs(stem, output_dir)
        version_covs[label] = covs
        for cov in covs:
            fits[(label, cov)] = load_fit(f"{stem}_{cov}", output_dir)

    # y-axis: union of cov sets across versions, in canonical order.
    cov_union = [c for c in CANONICAL_COV_ORDER
                 if any(c in version_covs[v] for v in versions)]
    n_cov = len(cov_union)

    # Per-version cov labels can disagree (main vs family). For the shared
    # y-axis we display the *main* convention if any version is non-family,
    # otherwise the family convention.
    any_main = any(not version_cfgs[v].get("family") for v in versions)
    label_map = COV_LABELS if any_main else COV_LABELS_FAMILY
    cov_labels = [label_map.get(c, c).replace("<sup>2</sup>", "²")
                  for c in cov_union]

    figsize = figsize or (2.8 * len(coefs), 1.8 + 0.32 * n_cov)
    fig, axes = plt.subplots(1, len(coefs), figsize=figsize, sharey=True)
    if len(coefs) == 1:
        axes = [axes]

    colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    offsets = np.linspace(-0.18, 0.18, n_ver) if n_ver > 1 else [0.0]

    for ax, coef in zip(axes, coefs):
        for v_idx, v_label in enumerate(versions):
            ys, xs, errs = [], [], []
            for cov_idx, cov in enumerate(cov_union):
                if cov not in version_covs[v_label]:
                    continue
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
    # Preserve column order (a MultiIndex with non-unique level-0 values
    # like ['main','main','exp','exp'] needs ordered, not deduplicated, keys).
    seen: list[str] = []
    for v in table.columns.get_level_values(0):
        if v not in seen:
            seen.append(v)
    versions = seen

    # Width per version: how many cov columns sit under each spanner.
    width_per_version: dict[str, int] = {v: 0 for v in versions}
    for v in table.columns.get_level_values(0):
        width_per_version[v] += 1

    # Per-version background shade. The first version (canonically the
    # baseline / "main") gets a near-white tint; the second gets a soft
    # neutral grey. Mild contrast on purpose---enough to chunk visually,
    # gentle enough not to fight the data. Extra versions cycle through
    # the same two tints.
    panel_shades = ["#fafafa", "#eef1f4"]
    bg_for: dict[str, str] = {
        v: panel_shades[i % len(panel_shades)] for i, v in enumerate(versions)
    }
    # Map each ordered (version, cov) column tuple to its background.
    column_bgs: list[str] = [bg_for[v] for v in table.columns.get_level_values(0)]

    # The diagnostic-row index identifies where to drop a thicker rule.
    diagnostic_labels = {"<i>J</i> p", "<i>N</i>", "runtime"}
    first_diag_seen = False

    rows: list[str] = []
    rows.append("<table class='results-overview'>")
    rows.append("<thead>")
    # Span row: a thin midrule under each version label. The shaded panel
    # background does the contrast work; the rule keeps the version name
    # visually attached to its columns.
    span_cells = "<th></th>" + "".join(
        f"<th colspan='{width_per_version[v]}' style='text-align:center; background:{bg_for[v]};'>"
        f"<div style='border-bottom:1px solid #444; margin:0 18px; padding-bottom:2px;'>"
        f"{v}</div></th>"
        for v in versions
    )
    rows.append(f"<tr>{span_cells}</tr>")
    cov_cells = "<th></th>" + "".join(
        f"<th style='text-align:right; background:{column_bgs[i]};'>{c}</th>"
        for i, c in enumerate(table.columns.get_level_values(1))
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
            f"<td style='text-align:right; background:{column_bgs[i]};'>{v}</td>"
            for i, v in enumerate(row.values)
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
