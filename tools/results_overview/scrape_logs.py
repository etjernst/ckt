"""Scrape headline values from RP6-real Stata logs into a JSON bank.

The RP6-real do-files reuse estnames across cells (e.g. `grc_IDN_covs_0`
gets overwritten as the script progresses through cuu --> cub --> iuu),
so the surviving `.ster` files on disk only reflect the last cell. The
text logs are preserved per-script though, and contain the printed
results of every cell. This script parses those logs and produces a
JSON bank keyed by the new-convention stem with `_r` suffix, so the
comparison framework can pull "real-values" numbers via a synthetic
fallback path.

Coverage:
  * 5_GrRC.log              : main covs (c0/ct/c1/c2/ca) x cuu/cub/iuu x 3 countries
  * 6_GrRC_NonAg.log        : main covs x cnu x IDN only
  * 8_GrRC_hukou.log        : main covs x cuu/cub/iuu x 4 hukou variants x CHN only
  * 10_GrRC_experience.log  : family=exp x cuu/cub/iuu x 3 countries x c1/c2/c3/ca
  * 11_..._max_experience   : family=maxexp
  * 12_..._experience_share : family=expsh
  * 13_..._max_experience_share : family=maxexpsh
  * 15_GrRC_birth.log       : family=birth x IDN only

Skipped (combination of treatments + family extras; needed only after
both axes are wired into the comparison render):
  * 14_GrRC_NonAg_experience.log

Output: tools/results_overview/scraped_real.json
        Keys are `grc_<COUNTRY>_<spec3>[_<family>]_<cov>_r`.
        Values: {"phi_b", "phi_se", "Dn_b", "Dn_se", "Dg_b", "Dg_se",
                 "J_p", "N"}.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

# RP6-real logs live under Dropbox.
DROPBOX_REAL = Path(
    r"C:/Users/maand/Dropbox (Personal)/Returns to migration/"
    r"ReplicationPackage6 - real values"
)
LOG_DIR = DROPBOX_REAL / "scripts" / "logs"

OUT_PATH = Path(__file__).resolve().parent / "scraped_real.json"

# Old-name --> new-name conventions.
COVSET_MAP = {
    "covs_0":     "c0",
    "covs_trend": "ct",
    "covs_1":     "c1",
    "covs_2":     "c2",
    "covs_all":   "ca",
    # 10/11/12/13/15 (family extras) already use c1/c2/c3/ca directly.
    "c1": "c1", "c2": "c2", "c3": "c3", "ca": "ca",
}

# Section header --> spec3. 5_GrRC.log layout:
#     . * 1. Consumption | Urban | Unbalanced | GRC
#     . * 2. Consumption | Urban | Balanced   | GRC
#     . * 3. Income      | Urban | Unbalanced | GRC
SPEC3_FROM_HEADER = {
    ("Consumption", "Urban", "Unbalanced"): "cuu",
    ("Consumption", "Urban", "Balanced"):   "cub",
    ("Income",      "Urban", "Unbalanced"): "iuu",
    ("Income",      "Urban", "Balanced"):   "iub",
    ("Consumption", "Nonag", "Unbalanced"): "cnu",
    ("Consumption", "Nonag", "Balanced"):   "cnb",
}

# 8_hukou.log section markers carry a fifth "| <hukou-tag>" field that
# names the sample restriction in long form. Map to the short tokens
# the comparison framework uses (matching `_stem_for`'s `hukou:` key).
HUKOU_TAG_TO_TOKEN = {
    "rural hukou first": "rf",
    "urban hukou first": "uf",
    "only rural hukou":  "ro",
    "only urban hukou":  "uo",
}

# Family-extras log files --> family token.
FAMILY_LOGS = {
    "10_GrRC_experience.log":           "exp",
    "11_GrRC_max_experience.log":       "maxexp",
    "12_GrRC_experience_share.log":     "expsh",
    "13_GrRC_max_experience_share.log": "maxexpsh",
    "15_GrRC_birth.log":                "birth",
}

# --- Regex patterns --------------------------------------------------------

RE_SECTION = re.compile(
    r"^\.\s+\*\s+\d+\.\s+"
    r"(?P<dep>Consumption|Income)\s*\|\s*"
    r"(?P<choice>Urban|Nonag)\s*\|\s*"
    r"(?P<bal>Unbalanced|Balanced)\s*\|\s*GRC\b"
    r"(?:\s*\|\s*(?P<tag>[^|\n]+?))?\s*$"
)

# Save line for the main fit: "...output/grc_X_Y.ster saved" (NOT a sub).
RE_SAVE_MAIN = re.compile(
    r"output/(grc_(?P<country>IDN|CHN|TZA)_(?P<covset>[a-z0-9_]+))\.ster saved$"
)
RE_SAVE_SUB = re.compile(
    r"output/grc_(?P<country>IDN|CHN|TZA)_(?P<covset>[a-z0-9_]+)"
    r"_(?P<sub>never|always|delta|avg)\.ster saved$"
)

# Number of obs in main GMM table.
RE_N_OBS = re.compile(r"Number of obs\s*=\s*([\d,]+)")

# Hansen's J p-value.
RE_HANSEN = re.compile(
    r"Hansen's J chi2\(\d+\)\s*=\s*[\d.]+\s*\(p\s*=\s*([\d.]+)\)"
)

# Coefficient row: leading label, pipe, then number columns.
# Float pattern accepts optional leading "-" and "." formats.
_FLOAT = r"-?\d*\.?\d+(?:[eE][+\-]?\d+)?"
RE_PHI_CONS = re.compile(
    rf"^\s*_cons\s*\|\s*({_FLOAT})\s+({_FLOAT})\s+"
)
RE_DELTA_NEVER = re.compile(
    rf"^\s*Delta_never\s*\|\s*({_FLOAT})\s+({_FLOAT})\s+"
)
RE_DELTA_AVG = re.compile(
    rf"^\s*Delta_avg\s*\|\s*({_FLOAT})\s+({_FLOAT})\s+"
)
# The phi block is anchored by a header line "phi               |" before
# the _cons line. Several other parameter blocks (Delta_base, kappa,
# unbalanced, ...) also have _cons lines, so we need the block context.
RE_BLOCK_HEADER = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*\|\s*$")


def _safe_float(s: str) -> float | None:
    """Parse a Stata scalar; bare `.` is Stata's missing-value sentinel."""
    s = s.strip()
    if s in {"", ".", ".a", ".b", ".c"}:
        return None
    try:
        return float(s)
    except ValueError:
        return None


# --- Per-script log scraper -----------------------------------------------

def parse_5_grrc(log_path: Path) -> dict[str, dict]:
    """Parse 5_GrRC.log: 3 cells (cuu/cub/iuu) x 3 countries x 5 covs.

    Returns map from new-naming stem (with `_r`) to headline-values dict.
    """
    out: dict[str, dict] = {}
    spec3: str | None = None      # current cell's spec3
    main_n: int | None = None     # last seen N
    main_phi_b: float | None = None
    main_phi_se: float | None = None
    main_J_p: float | None = None
    in_phi_block = False          # are we inside the `phi |` block?
    pending_main_stem: str | None = None  # stem awaiting Delta_never/Delta_avg

    fit: dict[str, dict] = {}     # accumulator keyed by old-naming stem

    for raw in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        # Strip leading "." that Stata prepends to echoed commands.
        line = raw

        m = RE_SECTION.match(line)
        if m:
            key = (m.group("dep"), m.group("choice"), m.group("bal"))
            spec3 = SPEC3_FROM_HEADER.get(key)
            continue

        # Block context for the phi/_cons capture.
        m = RE_BLOCK_HEADER.match(line)
        if m:
            in_phi_block = (m.group(1) == "phi")
            continue

        m = RE_N_OBS.search(line)
        if m:
            main_n = int(m.group(1).replace(",", ""))
            continue

        m = RE_HANSEN.search(line)
        if m:
            main_J_p = _safe_float(m.group(1))
            continue

        if in_phi_block:
            m = RE_PHI_CONS.match(line)
            if m:
                main_phi_b = _safe_float(m.group(1))
                main_phi_se = _safe_float(m.group(2))
                in_phi_block = False
                continue

        m = RE_SAVE_MAIN.search(line)
        if m and spec3:
            country = m.group("country")
            covset_old = m.group("covset")
            covset_new = COVSET_MAP.get(covset_old)
            if covset_new is None:
                continue
            stem = f"grc_{country}_{spec3}_{covset_new}"
            fit[stem] = {
                "phi_b": main_phi_b,
                "phi_se": main_phi_se,
                "J_p": main_J_p,
                "N": main_n,
                "Dn_b": None, "Dn_se": None,
                "Dg_b": None, "Dg_se": None,
            }
            pending_main_stem = stem
            # Reset trackers (next fit starts fresh).
            main_phi_b = main_phi_se = None
            main_J_p = None
            main_n = None
            continue

        # Sub-fit: Delta_never table appears before its _never.ster save line.
        m = RE_DELTA_NEVER.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dn_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dn_se"] = _safe_float(m.group(2))
            continue

        m = RE_DELTA_AVG.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dg_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dg_se"] = _safe_float(m.group(2))
            continue

    # Tag with `_r` suffix on output keys.
    for stem, vals in fit.items():
        out[f"{stem}_r"] = vals
    return out


def parse_family_log(log_path: Path, family: str) -> dict[str, dict]:
    """Parse family-extras logs (10/11/12/13/15.log).

    Same structure as 5_GrRC but with family token; estnames in these
    logs are bare `grc_<COUNTRY>_c<X>` so we tag them with the family
    token on output: `grc_<COUNTRY>_<spec3>_<family>_c<X>_r`.

    spec3 still cycles (cuu --> cub --> iuu) within each script via
    section headers. Birth (15) is IDN-only.
    """
    out: dict[str, dict] = {}
    spec3: str | None = None
    main_n = main_phi_b = main_phi_se = main_J_p = None
    in_phi_block = False
    pending_main_stem: str | None = None
    fit: dict[str, dict] = {}

    for raw in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw

        m = RE_SECTION.match(line)
        if m:
            key = (m.group("dep"), m.group("choice"), m.group("bal"))
            spec3 = SPEC3_FROM_HEADER.get(key)
            continue

        m = RE_BLOCK_HEADER.match(line)
        if m:
            in_phi_block = (m.group(1) == "phi")
            continue

        m = RE_N_OBS.search(line)
        if m:
            main_n = int(m.group(1).replace(",", ""))
            continue

        m = RE_HANSEN.search(line)
        if m:
            main_J_p = _safe_float(m.group(1))
            continue

        if in_phi_block:
            m = RE_PHI_CONS.match(line)
            if m:
                main_phi_b = _safe_float(m.group(1))
                main_phi_se = _safe_float(m.group(2))
                in_phi_block = False
                continue

        m = RE_SAVE_MAIN.search(line)
        if m and spec3:
            country = m.group("country")
            covset_old = m.group("covset")
            covset_new = COVSET_MAP.get(covset_old)
            if covset_new is None:
                continue
            stem = f"grc_{country}_{spec3}_{family}_{covset_new}"
            fit[stem] = {
                "phi_b": main_phi_b,
                "phi_se": main_phi_se,
                "J_p": main_J_p,
                "N": main_n,
                "Dn_b": None, "Dn_se": None,
                "Dg_b": None, "Dg_se": None,
            }
            pending_main_stem = stem
            main_phi_b = main_phi_se = None
            main_J_p = None
            main_n = None
            continue

        m = RE_DELTA_NEVER.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dn_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dn_se"] = _safe_float(m.group(2))
            continue

        m = RE_DELTA_AVG.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dg_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dg_se"] = _safe_float(m.group(2))
            continue

    for stem, vals in fit.items():
        out[f"{stem}_r"] = vals
    return out


def parse_6_nonag(log_path: Path) -> dict[str, dict]:
    """Parse 6_GrRC_NonAg.log: a single cell (cnu) for IDN.

    Same record structure as 5_GrRC.log but only one section header.
    Output keys: `grc_IDN_cnu_<cov>_r`.
    """
    out: dict[str, dict] = {}
    spec3: str | None = None
    main_n = main_phi_b = main_phi_se = main_J_p = None
    in_phi_block = False
    pending_main_stem: str | None = None
    fit: dict[str, dict] = {}

    for raw in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw

        m = RE_SECTION.match(line)
        if m:
            spec3 = SPEC3_FROM_HEADER.get(
                (m.group("dep"), m.group("choice"), m.group("bal"))
            )
            continue

        m = RE_BLOCK_HEADER.match(line)
        if m:
            in_phi_block = (m.group(1) == "phi")
            continue

        m = RE_N_OBS.search(line)
        if m:
            main_n = int(m.group(1).replace(",", ""))
            continue

        m = RE_HANSEN.search(line)
        if m:
            main_J_p = _safe_float(m.group(1))
            continue

        if in_phi_block:
            m = RE_PHI_CONS.match(line)
            if m:
                main_phi_b = _safe_float(m.group(1))
                main_phi_se = _safe_float(m.group(2))
                in_phi_block = False
                continue

        m = RE_SAVE_MAIN.search(line)
        if m and spec3:
            country = m.group("country")
            covset_old = m.group("covset")
            covset_new = COVSET_MAP.get(covset_old)
            if covset_new is None:
                continue
            stem = f"grc_{country}_{spec3}_{covset_new}"
            fit[stem] = {
                "phi_b": main_phi_b, "phi_se": main_phi_se,
                "J_p": main_J_p, "N": main_n,
                "Dn_b": None, "Dn_se": None,
                "Dg_b": None, "Dg_se": None,
            }
            pending_main_stem = stem
            main_phi_b = main_phi_se = None
            main_J_p = None
            main_n = None
            continue

        m = RE_DELTA_NEVER.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dn_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dn_se"] = _safe_float(m.group(2))
            continue

        m = RE_DELTA_AVG.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dg_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dg_se"] = _safe_float(m.group(2))
            continue

    for stem, vals in fit.items():
        out[f"{stem}_r"] = vals
    return out


# Estname parsing for 8_hukou: filenames embed the long hukou name
# (e.g. `grc_CHN_rural_first_c1`) rather than spec3. Section header gives
# the spec3; we recombine into the new-naming stem `grc_CHN_<token>_<spec3>_<cov>`.
RE_SAVE_HUKOU_MAIN = re.compile(
    r"output/grc_(?P<country>CHN)_"
    r"(?P<long>(?:rural|urban)_(?:first|only))"
    r"_(?P<cov>c[0-9at]+)\.ster saved$"
)
LONG_HUKOU_TO_TOKEN = {
    "rural_first": "rf",
    "urban_first": "uf",
    "rural_only":  "ro",
    "urban_only":  "uo",
}


def parse_8_hukou(log_path: Path) -> dict[str, dict]:
    """Parse 8_GrRC_hukou.log: 4 hukou variants x 3 spec3 cells x CHN.

    Section header carries the hukou tag as its 5th field (e.g.
    `| rural hukou first`). Estnames in the log embed the long hukou
    name (`grc_CHN_rural_first_c1`); on output we translate to the
    short token (`rf`) so keys match what `_stem_for(cfg)` builds for
    `cfg["hukou"] = "rf"`: `grc_CHN_rf_<spec3>_<cov>_r`.

    Cov tokens here are already in new-naming (c0/ct/c1/c2/ca), so no
    COVSET_MAP step is needed.
    """
    out: dict[str, dict] = {}
    spec3: str | None = None
    hukou_token: str | None = None
    main_n = main_phi_b = main_phi_se = main_J_p = None
    in_phi_block = False
    pending_main_stem: str | None = None
    fit: dict[str, dict] = {}

    for raw in log_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw

        m = RE_SECTION.match(line)
        if m:
            spec3 = SPEC3_FROM_HEADER.get(
                (m.group("dep"), m.group("choice"), m.group("bal"))
            )
            tag = (m.group("tag") or "").strip().lower()
            hukou_token = HUKOU_TAG_TO_TOKEN.get(tag)
            continue

        m = RE_BLOCK_HEADER.match(line)
        if m:
            in_phi_block = (m.group(1) == "phi")
            continue

        m = RE_N_OBS.search(line)
        if m:
            main_n = int(m.group(1).replace(",", ""))
            continue

        m = RE_HANSEN.search(line)
        if m:
            main_J_p = _safe_float(m.group(1))
            continue

        if in_phi_block:
            m = RE_PHI_CONS.match(line)
            if m:
                main_phi_b = _safe_float(m.group(1))
                main_phi_se = _safe_float(m.group(2))
                in_phi_block = False
                continue

        m = RE_SAVE_HUKOU_MAIN.search(line)
        if m and spec3 and hukou_token:
            country = m.group("country")
            long_huk = m.group("long")
            token = LONG_HUKOU_TO_TOKEN.get(long_huk)
            cov = m.group("cov")
            if token is None or cov not in {"c0", "ct", "c1", "c2", "c3", "ca"}:
                continue
            # Sanity: section-header hukou should match estname hukou.
            if token != hukou_token:
                continue
            stem = f"grc_{country}_{token}_{spec3}_{cov}"
            fit[stem] = {
                "phi_b": main_phi_b, "phi_se": main_phi_se,
                "J_p": main_J_p, "N": main_n,
                "Dn_b": None, "Dn_se": None,
                "Dg_b": None, "Dg_se": None,
            }
            pending_main_stem = stem
            main_phi_b = main_phi_se = None
            main_J_p = None
            main_n = None
            continue

        m = RE_DELTA_NEVER.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dn_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dn_se"] = _safe_float(m.group(2))
            continue

        m = RE_DELTA_AVG.match(line)
        if m and pending_main_stem and pending_main_stem in fit:
            fit[pending_main_stem]["Dg_b"] = _safe_float(m.group(1))
            fit[pending_main_stem]["Dg_se"] = _safe_float(m.group(2))
            continue

    for stem, vals in fit.items():
        out[f"{stem}_r"] = vals
    return out


def main() -> None:
    bank: dict[str, dict] = {}

    five = LOG_DIR / "5_GrRC.log"
    if five.exists():
        new = parse_5_grrc(five)
        bank.update(new)
        print(f"5_GrRC.log: {len(new)} fits scraped")
    else:
        print(f"WARN: missing {five}")

    six = LOG_DIR / "6_GrRC_NonAg.log"
    if six.exists():
        new = parse_6_nonag(six)
        bank.update(new)
        print(f"6_GrRC_NonAg.log: {len(new)} fits scraped")
    else:
        print(f"WARN: missing {six}")

    eight = LOG_DIR / "8_GrRC_hukou.log"
    if eight.exists():
        new = parse_8_hukou(eight)
        bank.update(new)
        print(f"8_GrRC_hukou.log: {len(new)} fits scraped")
    else:
        print(f"WARN: missing {eight}")

    for fname, family in FAMILY_LOGS.items():
        path = LOG_DIR / fname
        if not path.exists():
            print(f"WARN: missing {path}")
            continue
        new = parse_family_log(path, family)
        bank.update(new)
        print(f"{fname}: {len(new)} fits scraped (family={family})")

    OUT_PATH.write_text(json.dumps(bank, indent=2, sort_keys=True))
    print(f"\nWrote {len(bank)} entries to {OUT_PATH}")

    # Sanity report: how many fits have all four headline numbers vs. partial.
    complete = sum(
        1 for v in bank.values()
        if all(v.get(k) is not None for k in ("phi_b", "Dn_b", "Dg_b", "J_p", "N"))
    )
    print(f"  complete: {complete}/{len(bank)} fits")


if __name__ == "__main__":
    main()
