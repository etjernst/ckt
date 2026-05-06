"""Read .ster estimation files into structured records via in-process pystata."""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import pandas as pd

PYSTATA_DIR = r"C:/Program Files/StataNow19/utilities"
if PYSTATA_DIR not in sys.path:
    sys.path.append(PYSTATA_DIR)

import pystata  # noqa: E402


def _silent_init() -> None:
    """Initialize pystata without dumping the Stata banner to stdout."""
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
        pystata.config.init("mp")


_silent_init()

from pystata import stata  # noqa: E402
from sfi import Macro, Matrix, Scalar  # noqa: E402


_SPEC3_DEPVAR = {"c": "consumption", "i": "income"}
_SPEC3_CHOICE = {"u": "urban", "n": "nonag"}
_SPEC3_BALANCE = {"u": "unbalanced", "b": "balanced"}

_COVS2 = {
    "c0": "no covariates",
    "ct": "trend",
    "c1": "trend + female",
    "c2": "trend + female + age^2",
    "ca": "trend + female + age^2 + edu + edu^2",
}

_SUFFIX = {"": "main", "n": "Delta_never", "a": "Delta_always",
           "d": "Delta_d", "g": "Delta_avg"}

_FILENAME_RE = re.compile(
    r"^grc_(?P<country>CHN|IDN|TZA)"
    r"(?:_(?P<hukou>ro|uo|rf|uf))?"
    r"_(?P<spec3>[ci][un][ub])"
    r"(?:_(?P<family>birth|exp|maxexp|expsh|maxexpsh))?"
    r"_(?P<covs2>c0|ct|c1|c2|c3|ca)"
    r"(?:_(?P<suffix>[nadg]))?"
    r"(?P<values>_r)?"
    r"\.ster$"
)


@dataclass
class SterRecord:
    """One fit's worth of estimation output, parsed from a main ster.

    `b` and `se` are pandas Series indexed by Stata coefficient names
    (e.g. 'phi:_cons', 'Delta_base:_cons').
    """

    path: Path
    country: str
    spec3: str
    depvar: str
    choice: str
    balance: str
    covs2: str
    covariates: str
    family: str = ""
    hukou: str | None = None
    values: str = "nominal"
    b: pd.Series = field(default_factory=pd.Series)
    se: pd.Series = field(default_factory=pd.Series)
    N: int | None = None
    J: float | None = None
    J_df: int | None = None
    J_p: float | None = None
    runtime_s: float | None = None


def parse_filename(path: Path) -> dict:
    m = _FILENAME_RE.match(path.name)
    if not m:
        raise ValueError(f"unrecognized ster filename: {path.name}")
    parts = m.groupdict()
    spec3 = parts["spec3"]
    parts["depvar"] = _SPEC3_DEPVAR[spec3[0]]
    parts["choice"] = _SPEC3_CHOICE[spec3[1]]
    parts["balance"] = _SPEC3_BALANCE[spec3[2]]
    parts["covariates"] = _COVS2.get(parts["covs2"], parts["covs2"])
    parts["family"] = parts["family"] or ""
    parts["values"] = "real" if parts["values"] == "_r" else "nominal"
    parts["suffix"] = parts["suffix"] or ""
    return parts


def _qualified_colnames(matname: str) -> list[str]:
    """Return 'eqname:colname' for each column of `e(<matname>)`.

    `Matrix.getColNames` drops the equation prefix, which collides on
    multi-equation models (e.g. three `_cons` in GRC). `colfullnames`
    keeps the prefix.
    """
    stata.run(f"local __cfn : colfullnames {matname}", quietly=True)
    raw = Macro.getLocal("__cfn") or ""
    return raw.split()


def load_ster(path: str | Path) -> SterRecord:
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(path)

    meta = parse_filename(path)

    stata_path = str(path.resolve()).replace("\\", "/")
    stata.run(f'estimates use "{stata_path}"', quietly=True)

    b_mat = np.asarray(Matrix.get("e(b)"), dtype=float)
    V_mat = np.asarray(Matrix.get("e(V)"), dtype=float)
    names = _qualified_colnames("e(b)")

    if b_mat.ndim == 2:
        b_mat = b_mat[0]

    b = pd.Series(b_mat, index=names, dtype=float)
    se = pd.Series(np.sqrt(np.diag(V_mat)), index=names, dtype=float)

    def _scalar(name: str) -> float | None:
        v = Scalar.getValue(f"e({name})")
        return None if v is None or np.isnan(v) else float(v)

    N = _scalar("N")
    J = _scalar("J")
    J_df = _scalar("Jdf")
    J_p = _scalar("Jpval")
    runtime_s = _scalar("runtime")

    return SterRecord(
        path=path,
        country=meta["country"],
        spec3=meta["spec3"],
        depvar=meta["depvar"],
        choice=meta["choice"],
        balance=meta["balance"],
        covs2=meta["covs2"],
        covariates=meta["covariates"],
        family=meta["family"],
        hukou=meta["hukou"],
        values=meta["values"],
        b=b,
        se=se,
        N=int(N) if N is not None else None,
        J=J,
        J_df=int(J_df) if J_df is not None else None,
        J_p=J_p,
        runtime_s=runtime_s,
    )


if __name__ == "__main__":
    import argparse

    p = argparse.ArgumentParser()
    p.add_argument("ster", help="path to a .ster file")
    args = p.parse_args()

    rec = load_ster(args.ster)
    print(f"file:       {rec.path.name}")
    print(f"country:    {rec.country}")
    print(f"spec3:      {rec.spec3} ({rec.depvar} / {rec.choice} / {rec.balance})")
    print(f"covs:       {rec.covs2} ({rec.covariates})")
    print(f"N:          {rec.N}")
    print(f"J:          {rec.J}")
    print(f"runtime:    {rec.runtime_s}")
    print("\ncoefficients (first 10):")
    print(pd.DataFrame({"b": rec.b, "se": rec.se}).head(10))
