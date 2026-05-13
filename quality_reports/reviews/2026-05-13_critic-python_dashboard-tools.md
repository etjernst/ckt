# Python critic: dashboard tools

Date: 2026-05-13

Files reviewed:

- [tools/results_overview/scrape_headlines.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape_headlines.py)
- [tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py)

Scope note: these are opt-in dashboard tools, not analysis scripts producing paper artifacts.
No statistical estimation occurs.
`scrape.py`, `scrape_logs.py`, `profile_render.py`, and `test_cache_equivalence.py` are out of scope.

---

## Answers to the four specific questions

### 1. Schema version: does the reader reject mismatched rows or silently accept them?

`_read_headlines` in [compare.py L352-360](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py) filters out mismatched rows and does not raise.
After concatenating all CSVs it computes `wrong = df["schema_version"] != EXPECTED_SCHEMA_VERSION` and drops those rows with `df = df.loc[~wrong]`.
A `logging.warning` is emitted.
Stale rows never reach `_fit_from_cache_row`; they trigger a live fallback via `_load_fit_live`.

One fragility: `pd.read_csv` without `dtype=str` infers `schema_version` as int64 and the comparison `!= 1` works for the current integer schema.
The writer (`scrape_headlines.py`) and `_is_fresh` both use string comparisons (`str(SCHEMA_VERSION)`), while `_read_headlines` uses int comparison.
The two conventions agree at `SCHEMA_VERSION = 1` but would diverge for non-integer bumps.

### 2. Sibling import: cwd-dependent or cwd-independent?

`scrape_headlines.py` [L37-39](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape_headlines.py) inserts its own resolved directory into `sys.path` before `from scrape import ...`.
It is cwd-independent, runnable from any directory.

`compare.py` [L27](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py) does `from scrape import SterRecord, load_ster` with no preceding `sys.path` manipulation.
The import succeeds only because Quarto sets cwd to the script directory and [report.qmd L20-21](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.qmd) adds `Path.cwd()` to `sys.path`.
If `compare.py` is imported from outside `tools/results_overview/` without that injection (e.g., from a test runner at the repo root), the import raises `ModuleNotFoundError`.
The empty `__init__.py` does not resolve this.

### 3. `_load_bank()` error handling

`_load_bank()` [L72-75](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py) returns `{}` silently when `scraped_real.json` is absent.
No warning or log entry is emitted.
Downstream:

- `_discover_covs` [L129-138](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py): bank fallback yields `found = {}`; function returns `[]`.
- `comparison_table` [L552-555](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py): raises `FileNotFoundError` on empty `covs`. Quarto's `error: true` renders this as an error cell rather than crashing the document.
- `coefplot` [L693-696](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py): does not guard on empty `covs`; the fit loop no-ops silently; the figure renders with empty axes.
- `_load_fit_live` [L309-315](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py): when `vsfx` is non-empty, the `.ster` is missing, and the bank key is absent, raises `FileNotFoundError`. No diagnostic precedes this.

In the nominal-vs-real comparison view with `_r`-suffix sters missing and `scraped_real.json` absent, the failure mode is an uncaught exception with no prior user-facing warning.

### 4. `_is_fresh()` behavior on corrupt or truncated CSVs

`_is_fresh` [L164-187](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape_headlines.py) wraps `pd.read_csv` in `try/except (EmptyDataError, ParserError)`.
Both empty files and truncated/malformed CSVs return `False`, causing the stem to be re-scraped.
A CSV with the correct row count but corrupt numeric cells would pass the `len(df) != 1` and schema-version string-equality checks and land on the mtime comparison, where mismatched mtime strings return `False`.
In all plausible corrupt-file scenarios the function correctly returns `False`.
The `os.replace` atomic-rename write pattern [L160](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scrape_headlines.py) ensures a partial write never commits a corrupt file.
This path is correct.

---

## Findings by severity

### MAJOR

**M1 | No environment specification | both files | Lens 5 | confidence: high**

No `requirements.txt`, `pyproject.toml`, or `environment.yml` exists at the project root or in `tools/results_overview/`.
The only environment files in the repo are under `explorations/python-grc/`, a separate context.
`compare.py` imports `numpy`, `pandas`, `scipy`, and `matplotlib`; `scrape_headlines.py` imports `pandas`.
Without pinned versions the dashboard tools are not reproducible across machines.

Fix: add `tools/results_overview/requirements.txt` listing at minimum `numpy`, `pandas`, `scipy`, and `matplotlib` with version pins matching the Anaconda environment in use.

**M2 | Sibling import in compare.py is cwd-dependent | compare.py L27 | Lens 1 | confidence: high**

`from scrape import SterRecord, load_ster` works only when `tools/results_overview/` is on `sys.path`.
This holds during Quarto renders (the qmd setup cell injects it) but not when `compare.py` is imported from any other context.
`scrape_headlines.py` handles this correctly; `compare.py` does not.

Fix: add the same `sys.path` guard before line 27:

```python
import sys as _sys
_HERE = Path(__file__).resolve().parent
if str(_HERE) not in _sys.path:
    _sys.path.insert(0, str(_HERE))
```

**M3 | `_load_bank()` silent failure | compare.py L72-75 | Lens 4 | confidence: high**

When `scraped_real.json` is absent, `_load_bank` returns `{}` without logging.
The first symptom is a Quarto error cell or a silently empty coefplot.
For a workflow where the bank is a prerequisite for the real-values view, the failure should be surfaced earlier.

Fix: add a `logging.warning` inside `_load_bank` when the file is absent, and add a guard in `coefplot` matching the one already in `comparison_table`.

**M4 | Mid-file import | compare.py L83 | Lens 1 | confidence: high**

`import re as _re` appears at line 83, well below the top-level import block.
The `re` module is stdlib and has no conditional load rationale.

Fix: move `import re as _re` to the stdlib import block at the top of the file.

### MINOR

**m1 | `coefplot` does not guard on empty covs | compare.py L693-696 | Lens 4 | confidence: high**

`comparison_table` raises `FileNotFoundError` when `_discover_covs` returns an empty list.
`coefplot` has no equivalent guard: the fit loop no-ops and the figure renders with empty axes.

Fix: add a guard matching `comparison_table` and raise the same error.

**m2 | Redundant `pd.isna` guards in `_fit_from_cache_row` | compare.py L439-440 | Lens 2 | confidence: high**

`J_p` and `runtime_s` are guarded with an explicit `pd.isna` check before calling `_f()`, but `_f()` already handles NaN.
`N` and `converged` route through `_i()` without the extra guard.
The asymmetry is harmless but misleads a reader into thinking `_f()` is unsafe for NaN inputs.

Fix: unify the pattern (e.g., add a `_fn()` helper that returns `None` on NaN and use it consistently for nullable float fields).

**m3 | Schema version comparison type mismatch | compare.py L353, scrape_headlines.py L177 | Lens 2 | confidence: medium**

`_is_fresh` reads the CSV with `dtype=str` and compares against `str(SCHEMA_VERSION)`.
`_read_headlines` reads without `dtype=str` and compares against `EXPECTED_SCHEMA_VERSION` (int).
Both happen to work at `SCHEMA_VERSION = 1`.
Worth aligning to one convention at the next schema bump.

**m4 | Subgroup SterRecords lack diagnostic fields | compare.py L445-455 | Lens 2 | confidence: low**

The `_sub` helper returns a `SterRecord` without `N`, `J`, `J_df`, `J_p`, `runtime_s`, or `converged`.
These default to `None` per the dataclass definition, which is correct for subgroup records.
A future caller could silently get `None` values for fields it expects to carry the main record's values.

---

## Score

Estimation lens is N/A (no statistical estimation in scope); its 30% weight is treated as full credit.

| Lens | Weight | Score | Weighted |
|------|--------|-------|----------|
| Structure | 15% | 72 | 10.8 |
| Data Handling | 25% | 88 | 22.0 |
| Estimation | 30% | N/A (full credit) | 30.0 |
| Output | 15% | 82 | 12.3 |
| Reproducibility | 15% | 55 | 8.3 |
| **Total** | | | **83 / 100** |

No CRITICAL issues.
Above the commit threshold (80); below the PR threshold (90).
The missing environment specification (M1) and the cwd-dependent sibling import (M2) are the blockers for PR.
The `_load_bank` silent failure (M3) is a usability issue, not a correctness bug given the qmd has `error: true`.
The remaining minors are low-priority polish.
