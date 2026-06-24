"""cProfile harness for the dashboard render.

Mirrors the workload in `report.qmd` --- one `comparison_table` + `comparison_dates`
+ `coefplot` per section --- without the Quarto/Jupyter overhead so the profile
reflects the pure Python+pystata work the qmd kernel does.

Usage (from this directory):
    python -m cProfile -o profile_render.prof profile_render.py

Then inspect with:
    python -c "import pstats; p = pstats.Stats('profile_render.prof'); \
        p.strip_dirs().sort_stats('cumulative').print_stats(40)"
"""

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).parent
sys.path.insert(0, str(ROOT))

from compare import comparison_table, coefplot, render_table, comparison_dates  # noqa: E402

CASES: list[tuple[str, dict, dict]] = [
    ("idn-bal-vs-unb",
        {"country": "IDN", "depvar": "consumption", "choice": "urban"},
        {"unbalanced": "cuu", "balanced": "cub"}),
    ("chn-bal-vs-unb",
        {"country": "CHN", "depvar": "consumption", "choice": "urban"},
        {"unbalanced": "cuu", "balanced": "cub"}),
    ("tza-bal-vs-unb",
        {"country": "TZA", "depvar": "consumption", "choice": "urban"},
        {"unbalanced": "cuu", "balanced": "cub"}),
    ("idn-main-vs-exp",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "experience": {"family": "exp"}}),
    ("idn-main-vs-maxexp",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "max experience": {"family": "maxexp"}}),
    ("idn-main-vs-expsh",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "experience share": {"family": "expsh"}}),
    ("idn-main-vs-maxexpsh",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "max experience share": {"family": "maxexpsh"}}),
    ("idn-main-vs-birth",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "urban birth": {"family": "birth"}}),
    ("chn-main-vs-rf",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "rural-first": {"hukou": "rf"}}),
    ("chn-main-vs-ro",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "rural-only": {"hukou": "ro"}}),
    ("chn-main-vs-uo",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "urban-only": {"hukou": "uo"}}),
    ("chn-main-vs-uf",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"main": {}, "urban-first": {"hukou": "uf"}}),
    ("idn-main-vs-nonag",
        {"country": "IDN", "depvar": "consumption", "balance": "unbalanced"},
        {"main": {"choice": "urban"}, "non-ag": {"choice": "nonag"}}),
    ("idn-main-vs-income",
        {"country": "IDN", "choice": "urban", "balance": "unbalanced"},
        {"consumption": {"depvar": "consumption"}, "income": {"depvar": "income"}}),
    ("idn-nom-vs-real-cuu",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("chn-nom-vs-real-cuu",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("tza-nom-vs-real-cuu",
        {"country": "TZA", "depvar": "consumption", "choice": "urban", "balance": "unbalanced"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("idn-nom-vs-real-cuu-exp",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "family": "exp"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("idn-nom-vs-real-cuu-birth",
        {"country": "IDN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "family": "birth"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("idn-nom-vs-real-cnu",
        {"country": "IDN", "depvar": "consumption", "choice": "nonag", "balance": "unbalanced"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("chn-nom-vs-real-rf-cuu",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "hukou": "rf"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("chn-nom-vs-real-ro-cuu",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "hukou": "ro"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("chn-nom-vs-real-uf-cuu",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "hukou": "uf"},
        {"nominal": {}, "real": {"values": "real"}}),
    ("chn-nom-vs-real-uo-cuu",
        {"country": "CHN", "depvar": "consumption", "choice": "urban", "balance": "unbalanced", "hukou": "uo"},
        {"nominal": {}, "real": {"values": "real"}}),
]


def main() -> None:
    for label, fix, versus in CASES:
        print(f"--- {label} ---", flush=True)
        try:
            table = comparison_table(fix=fix, versus=versus)
            _ = render_table(table)
            _ = comparison_dates(fix=fix, versus=versus)
            coefplot(fix=fix, versus=versus)
        except Exception as e:  # match qmd's `error: true`
            print(f"    ERROR ({type(e).__name__}): {e}", flush=True)
        finally:
            plt.close("all")


if __name__ == "__main__":
    main()
