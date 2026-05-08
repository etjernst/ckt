"""Build estout-style comparison tables across two versions of GRC fits.

Each comparison fixes a slice (country, depvar, choice) and varies one axis
(typically `balance`, sometimes `values`, eventually `estimator`). The five
covariate sets fan across columns automatically.

Output is a pandas DataFrame with multi-index columns (version, covariate).
Display is a string-formatted DataFrame (point estimate with significance
stars, SE in parentheses on the next row).
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from functools import lru_cache
from pathlib import Path

import numpy as np
import pandas as pd
from scipy import stats

import matplotlib.pyplot as plt

from scrape import SterRecord, load_ster


@lru_cache(maxsize=None)
def _cached_load_ster(path_str: str, mtime_ns: int) -> SterRecord:
    """Cache `load_ster` keyed on (path, mtime_ns).

    The mtime in the key invalidates the cache automatically whenever Stata
    rewrites the `.ster` file, so re-renders after a fresh estimation run
    never serve stale values. Within one render this also dedupes the
    `comparison_table` -> `coefplot` double-load (~2x speedup).
    """
    return load_ster(Path(path_str))


COV_ORDER = ["c0", "ct", "c1", "c2", "c3", "ca"]
COV_LABELS = {
    "c0": "none",
    "ct": "trend",
    "c1": "+female",
    "c2": "+age<sup>2</sup>",
    "c3": "+age<sup>2</sup>",
    "ca": "+edu",
}

CANONICAL_COV_ORDER = ["c0", "ct", "c1", "c2", "c3", "ca"]

# Plain-text step labels for matplotlib axes. Order is the canonical
# progression that holds across both main (`c0` -> `ca`) and family-extras
# (`c1` -> `ca`) ladders. Any "+<extra>" label slots between "trend" and
# "+female" --- handled in `_step_order()`.
STANDARD_STEPS_TEXT = ["none", "trend", "+female", "+age²", "+edu"]

OUTPUT_DIR = Path(__file__).resolve().parents[2] / "RP7" / "output"

# Bank of headline values scraped from RP6-real Stata logs (see
# scrape_logs.py). Used as a synthetic-fit fallback when a `_r`-suffix
# `.ster` file is missing on disk, so the nominal-vs-real comparison
# view can render before we re-run the M4 real pipeline locally.
SCRAPED_BANK = Path(__file__).resolve().parent / "scraped_real.json"


@lru_cache(maxsize=1)
def _load_bank() -> dict[str, dict]:
    if not SCRAPED_BANK.exists():
        return {}
    return json.loads(SCRAPED_BANK.read_text(encoding="utf-8"))


# Sidecar CSV produced by `fix_delta_avg_scaling.do`. Each row carries
# the buggy Delta_avg (= switcher_frac * E[Delta | switcher]) saved in
# the corresponding `_g.ster` plus the rescaled headline value.
# `Fit.headline()` substitutes the rescaled value when the on-disk
# ster still matches `b_buggy` --- so re-fits done under the corrected
# `0_programs.do` (where `_g.ster` no longer carries the bug) bypass
# the override automatically. See [delta_avg_rescaled.csv] for the
# full row set.
DELTA_RESCALED_CSV = OUTPUT_DIR / "delta_avg_rescaled.csv"


@lru_cache(maxsize=None)
def _cached_rescaled(path_str: str, mtime_ns: int) -> dict[str, dict[str, float]]:
    df = pd.read_csv(path_str)
    return {
        row.estname: {
            "b_buggy": float(row.b_buggy),
            "se_buggy": float(row.se_buggy),
            "b_rescaled": float(row.b_rescaled),
            "se_rescaled": float(row.se_rescaled),
        }
        for row in df.itertuples(index=False)
    }


def _load_rescaled() -> dict[str, dict[str, float]]:
    if not DELTA_RESCALED_CSV.exists():
        return {}
    return _cached_rescaled(str(DELTA_RESCALED_CSV), DELTA_RESCALED_CSV.stat().st_mtime_ns)


def _vsfx(cfg: dict) -> str:
    """Return the values-axis suffix: empty for nominal, `_r` for real."""
    return "_r" if cfg.get("values") == "real" else ""


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


def _discover_covs(stem: str, output_dir: Path, vsfx: str = "") -> list[str]:
    """Glob for `{stem}_<cov>{vsfx}.ster` and return cov tokens in order.

    `vsfx` is the values-axis suffix (`""` for nominal, `"_r"` for real).
    For real fits that lack on-disk `.ster` files, the bank of scraped
    headline values (see `_load_bank`) supplies cov coverage instead.
    """
    pattern = _re.compile(
        rf"^{_re.escape(stem)}_(c[0-9ta]){_re.escape(vsfx)}\.ster$"
    )
    found: set[str] = set()
    for p in output_dir.glob(f"{stem}_*{vsfx}.ster"):
        m = pattern.match(p.name)
        if m:
            found.add(m.group(1))

    # If real and the disk has nothing, look in the scraped bank.
    if vsfx and not found:
        bank = _load_bank()
        prefix = f"{stem}_"
        for key in bank:
            if not key.startswith(prefix) or not key.endswith(vsfx):
                continue
            cov = key[len(prefix): -len(vsfx)]
            if cov in CANONICAL_COV_ORDER:
                found.add(cov)

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
    """Return the cov-label map for a version.

    Main fits use the canonical progression `none / trend / +female /
    +age² / +edu`. Family-extras fits replace the leftmost rung with the
    actual extra-regressor name (`+exp`, `+maxexp`, `+expsh`, etc.) so a
    glance at the column header tells you what is being added.
    """
    family = version_cfg.get("family")
    if not family:
        return COV_LABELS
    return {
        "c1": f"+{family}",
        "c2": "+female",
        "c3": "+age<sup>2</sup>",
        "ca": "+edu",
    }


def _step_order(seen: list[str]) -> list[str]:
    """Order step labels canonically: none, trend, [extras], +female, +age², +edu.

    `seen` is a list of step labels (with HTML stripped) collected across
    versions. Family-extra labels (`+exp`, `+maxexp`, etc.) are anything
    not in `STANDARD_STEPS_TEXT`; they slot in after "trend".
    """
    out: list[str] = []
    for s in STANDARD_STEPS_TEXT:
        if s in seen:
            out.append(s)
    extras = [s for s in seen if s not in STANDARD_STEPS_TEXT]
    # Insert extras after "trend" if present, else at the front.
    insert_at = (out.index("trend") + 1) if "trend" in out else 0
    return out[:insert_at] + sorted(extras) + out[insert_at:]


def _strip_html(label: str) -> str:
    """Drop HTML tags from a cov label so it can be used in matplotlib."""
    return label.replace("<sup>2</sup>", "²").replace("<sub>", "").replace("</sub>", "").replace("<i>", "").replace("</i>", "")


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
            b = float(self.g_rec.b["Delta_avg"])
            se = float(self.g_rec.se["Delta_avg"])
            rescaled = _load_rescaled().get(self.stem)
            if rescaled is not None and (
                abs(b - rescaled["b_buggy"]) < 1e-9
                and abs(se - rescaled["se_buggy"]) < 1e-9
            ):
                b, se = rescaled["b_rescaled"], rescaled["se_rescaled"]
            out["Delta_avg"] = (b, se)
        else:
            out["Delta_avg"] = (None, None)

        return out


def _synthetic_fit_from_bank(stem: str, vsfx: str, vals: dict) -> Fit:
    """Build a Fit out of scraped-bank headline values.

    Only the three headline reads in `Fit.headline()` (`phi:_cons` on
    main, `Delta_never` on n_rec, `Delta_avg` on g_rec) plus `J_p`/`N`
    on main need to work. The synthetic SterRecords carry just those
    indices; everything else is None.
    """
    fake_path = OUTPUT_DIR / f"{stem}{vsfx}.ster"

    def _rec(b_index: dict[str, float], se_index: dict[str, float]) -> SterRecord:
        return SterRecord(
            path=fake_path,
            country="", spec3="", depvar="", choice="", balance="",
            covs2="", covariates="",
            b=pd.Series(b_index, dtype=float),
            se=pd.Series(se_index, dtype=float),
            N=vals.get("N"),
            J=None, J_df=None, J_p=vals.get("J_p"),
            runtime_s=None,
        )

    main = _rec(
        {"phi:_cons": vals.get("phi_b")},
        {"phi:_cons": vals.get("phi_se")},
    )
    n_rec = _rec(
        {"Delta_never": vals.get("Dn_b")},
        {"Delta_never": vals.get("Dn_se")},
    )
    g_rec = _rec(
        {"Delta_avg": vals.get("Dg_b")},
        {"Delta_avg": vals.get("Dg_se")},
    )
    return Fit(main=main, n_rec=n_rec, a_rec=None, d_rec=None, g_rec=g_rec)


def load_fit(stem: str, output_dir: Path = OUTPUT_DIR, vsfx: str = "") -> Fit:
    """Load a main ster and its four subgroup sters by stem.

    Stem is the filename without `.ster` (e.g. `grc_IDN_cuu_ca`).
    `vsfx` is the values-axis suffix (`""` nominal, `"_r"` real).
    Missing subgroup files are tolerated; the corresponding fields are None.

    Disk lookups route through `_cached_load_ster` keyed on (path, mtime_ns).
    For `_r`-suffix stems whose `.ster` files are not on disk, the bank of
    scraped headline values supplies a synthetic Fit so the comparison
    table can still render before we re-run the M4 real pipeline locally.
    """
    def _load(p: Path) -> SterRecord:
        return _cached_load_ster(str(p), p.stat().st_mtime_ns)

    main_path = output_dir / f"{stem}{vsfx}.ster"
    if main_path.exists():
        main = _load(main_path)

        def _maybe(suffix: str) -> SterRecord | None:
            p = output_dir / f"{stem}_{suffix}{vsfx}.ster"
            return _load(p) if p.exists() else None

        return Fit(
            main=main,
            n_rec=_maybe("n"),
            a_rec=_maybe("a"),
            d_rec=_maybe("d"),
            g_rec=_maybe("g"),
        )

    if vsfx:
        bank = _load_bank()
        key = f"{stem}{vsfx}"
        if key in bank:
            return _synthetic_fit_from_bank(stem, vsfx, bank[key])

    raise FileNotFoundError(main_path)


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

    # Per-version: merged config, stem, values-suffix, available cov tokens, fits.
    version_cfgs: dict[str, dict] = {}
    version_covs: dict[str, list[str]] = {}
    fits: dict[tuple[str, str], Fit] = {}
    for label, override in versus_norm.items():
        cfg = {**fix, **override}
        version_cfgs[label] = cfg
        stem = _stem_for(cfg)
        vsfx = _vsfx(cfg)
        covs = _discover_covs(stem, output_dir, vsfx)
        if not covs:
            raise FileNotFoundError(
                f"no '{stem}_<cov>{vsfx}.ster' files (or bank entries) "
                f"found for version '{label}' in {output_dir}"
            )
        version_covs[label] = covs
        for cov in covs:
            fits[(label, cov)] = load_fit(f"{stem}_{cov}", output_dir, vsfx)

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
    rows_idx.append("converged")
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

    jp_row, conv_row, n_row, rt_row = [], [], [], []
    for label in versus_norm:
        for cov in version_covs[label]:
            fit = fits[(label, cov)]
            jp_row.append(f"{fit.main.J_p:.3f}" if fit.main.J_p is not None else "")
            if fit.main.converged is None:
                conv_row.append("")
            else:
                conv_row.append("Y" if fit.main.converged == 1 else "<b>N</b>")
            n_row.append(f"{fit.main.N:,}" if fit.main.N is not None else "")
            rt_row.append(f"{fit.main.runtime_s:.0f}s" if fit.main.runtime_s is not None else "")
    data.append(jp_row)
    data.append(conv_row)
    data.append(n_row)
    data.append(rt_row)

    return pd.DataFrame(data, index=pd.Index(rows_idx, name=""), columns=columns)


def comparison_dates(
    fix: dict[str, str],
    versus: dict[str, str | dict],
    output_dir: Path = OUTPUT_DIR,
) -> str:
    """Return a small HTML datestamp line summarising when each version was fit.

    For each version: takes the oldest `.ster` mtime across the (stem, cov)
    cells discovered the same way `comparison_table` discovers them. That gives
    a conservative "results from <date>" --- if any cell is older than that,
    the displayed table is at least that old.

    Versions backed by `scraped_real.json` (no on-disk `.ster` files) are
    flagged "(scraped from log)" rather than dated.
    """
    import datetime as _dt

    versus_norm = _normalize_versus(versus)
    parts: list[str] = []
    for label, override in versus_norm.items():
        cfg = {**fix, **override}
        stem = _stem_for(cfg)
        vsfx = _vsfx(cfg)
        covs = _discover_covs(stem, output_dir, vsfx)
        mtimes: list[float] = []
        for cov in covs:
            p = output_dir / f"{stem}_{cov}{vsfx}.ster"
            if p.exists():
                mtimes.append(p.stat().st_mtime)
        if mtimes:
            stamp = _dt.datetime.fromtimestamp(min(mtimes)).strftime("%Y-%m-%d %H:%M")
            parts.append(f"<i>{label}</i>: {stamp}")
        else:
            parts.append(f"<i>{label}</i>: scraped from log")
    return (
        "<div style='font-size:0.85em; color:#666; margin-top:-0.5em; "
        "margin-bottom:1em;'>Results from "
        + " &nbsp;|&nbsp; ".join(parts)
        + "</div>"
    )


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
        vsfx = _vsfx(cfg)
        covs = _discover_covs(stem, output_dir, vsfx)
        version_covs[label] = covs
        for cov in covs:
            fits[(label, cov)] = load_fit(f"{stem}_{cov}", output_dir, vsfx)

    # y-axis: union of *step labels* (e.g. "+female", "+exp") across
    # versions, ordered canonically. This is robust to family-extras
    # versions whose c1 token is "+exp" rather than "+female", so each
    # version's marker lands on the row matching what was added.
    per_version_steps: dict[str, list[str]] = {}
    for v in versions:
        cov_lbl = _cov_labels_for(version_cfgs[v])
        per_version_steps[v] = [_strip_html(cov_lbl[c]) for c in version_covs[v]]
    seen_steps: list[str] = []
    for v in versions:
        for s in per_version_steps[v]:
            if s not in seen_steps:
                seen_steps.append(s)
    step_axis = _step_order(seen_steps)
    n_steps = len(step_axis)
    step_pos = {s: i for i, s in enumerate(step_axis)}

    figsize = figsize or (2.8 * len(coefs), 1.8 + 0.32 * n_steps)
    fig, axes = plt.subplots(1, len(coefs), figsize=figsize, sharey=True)
    if len(coefs) == 1:
        axes = [axes]

    colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    offsets = np.linspace(-0.18, 0.18, n_ver) if n_ver > 1 else [0.0]

    for ax, coef in zip(axes, coefs):
        for v_idx, v_label in enumerate(versions):
            ys, xs, errs = [], [], []
            for cov, step in zip(version_covs[v_label], per_version_steps[v_label]):
                fit = fits[(v_label, cov)]
                b, se = fit.headline().get(coef, (None, None))
                if b is None or se is None:
                    continue
                ys.append(step_pos[step] + offsets[v_idx])
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
        ax.set_yticks(range(n_steps))
        ax.set_yticklabels(step_axis)
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

    # Per-version background shade. Tints derived from the matplotlib
    # default cycle (#1f77b4 steel-blue and #ff7f0e orange) so the table
    # panels echo the coefplot markers. Lightness is high enough to keep
    # text legible; saturation is low enough not to fight the data.
    panel_shades = ["#eaf2f9", "#fdefe1"]
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
