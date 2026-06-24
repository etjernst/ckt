# Rescaler cleanup: ready-to-apply checklist

Date: 2026-05-12
Branch: `worktree-grc-pipeline-refactor`
Status: drafted, NOT YET APPLIED.
Apply only after the Delta_avg refit completes and all 110 `_g.ster`
files have been verified to match `delta_avg_rescaled.csv`'s
`b_rescaled` column.

This file is the unambiguous record of what to delete so the cleanup
can be applied in one shot when verification passes.

---

## Precondition: verify the refit

Before running any of the steps below, confirm:

1. The background refit (PID 10420, launched 13:10 on 2026-05-12)
   has exited cleanly.
   Check `RP7/scripts/run_master_resume.log` for `end of do-file`
   and rc=0.
2. All 110 `_g.ster` files for the rescale CSV estnames are
   present on disk:

```bash
# Count expected vs actual
wc -l RP7/output/delta_avg_rescaled.csv  # 111 lines = 110 rows + header
ls RP7/output/_pre_fix_backup_82766d2/*_g.ster | wc -l  # 110
ls RP7/output/grc_*_g.ster | wc -l  # >= 110 (some new fits too)
```

3. Spot-check that on-disk `Delta_avg` for at least three sample cells
   matches the CSV's `b_rescaled` to machine epsilon.
   Already verified for `grc_IDN_cuu_c0` (`0.3810670249710334` vs
   `0.3810670249710419`).
   Pick one CHN cell and one TZA cell for the additional check.

If any cell fails the spot-check, STOP and investigate before deleting
the sidecar.

---

## Step 1: delete the rescaler files

```bash
git rm RP7/scripts/fix_delta_avg_scaling.do
git rm RP7/output/delta_avg_rescaled.csv
```

Sizes for reference:

- `RP7/scripts/fix_delta_avg_scaling.do`: 113 lines, 4.9 KB.
  The analytical rescaler that read `_g.ster` values, divided by
  `switcher_frac`, and wrote the sidecar CSV.
- `RP7/output/delta_avg_rescaled.csv`: 111 lines (110 rows + header),
  13.9 KB.
  Carries `(estname, b_buggy, se_buggy, b_rescaled, se_rescaled)`
  pairs.

---

## Step 2: strip the overlay from `compare.py`

Exact line ranges in
[tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py)
verified against the current file on 2026-05-12.

### 2a. Delete lines 78--106 (constant + cache + loader + comment block)

Block to remove (the four blank lines on either side stay):

```python
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
```

### 2b. Strip the substitution block in `Fit.headline()` (lines 265--270)

Current block (lines 262--273):

```python
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
```

Target block (six lines deleted):

```python
if self.g_rec is not None and "Delta_avg" in self.g_rec.b.index:
    b = float(self.g_rec.b["Delta_avg"])
    se = float(self.g_rec.se["Delta_avg"])
    out["Delta_avg"] = (b, se)
else:
    out["Delta_avg"] = (None, None)
```

### 2c. Imports

`lru_cache` and `pandas` stay --- both used elsewhere in `compare.py`
(scraped-bank cache, dataframe construction).

---

## Step 3: revert the temporary verdier early-exit

Commit `28a74f2` added a six-line early-exit at the top of
[RP7/scripts/17_verdier_robust.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/17_verdier_robust.do)
to skip the verdier-robust check during this refit.
After the refit completes, revert.

```bash
git revert --no-commit 28a74f2
# Inspect diff, then commit
git commit -m "Re-enable 17_verdier_robust after the 2026-05-12 refit

The verdier early-exit was a temporary measure so the refit could
complete without spending compute on the verdier-robust check.
Refit is done; verdier is back in the master pipeline path.

with Claude"
```

Verify the block at lines 22--28 of `17_verdier_robust.do` is gone after
the revert.

---

## Step 4: refresh headlines cache + re-render dashboard

```bash
python tools/results_overview/scrape_headlines.py --incremental
```

This restates the 110 affected stems with the corrected `Delta_avg`
values.

Then re-render the dashboard:

```bash
cd tools/results_overview && quarto render report.qmd
```

Sanity check: open `tools/results_overview/report.html`, locate one
main-GRC row (e.g. `grc_IDN_cuu_c0`), confirm the Delta_avg value
matches the `b_rescaled` column from the pre-deletion CSV
(0.3810670249710419 for that cell).

---

## Step 5: delete the backup once verified

```bash
rm -r RP7/output/_pre_fix_backup_82766d2/
```

This directory holds the 550 pre-fix `.ster` files (110 cells × 5
sters each).
Only delete after Step 4 confirms the dashboard reads correct values
from the new `_g.ster` files.

---

## Step 6: commit

Suggested commit message:

```
Remove Delta_avg sidecar rescaler now that re-fit uses corrected formula

The Delta_avg formula fix in 0_programs.do (commit 82766d2) is now
reflected on disk: all 110 affected cells have been re-fit under the
corrected formula. The analytical rescaler (fix_delta_avg_scaling.do
+ delta_avg_rescaled.csv) was a temporary workaround for the period
when on-disk values still carried the bug; it is no longer needed.

The compare.py overlay (`_load_rescaled` + Fit.headline substitution)
becomes dead code post-refit and is removed.

with Claude
```

---

## Post-cleanup state

After Steps 1--6:

- `RP7/scripts/fix_delta_avg_scaling.do`: deleted.
- `RP7/output/delta_avg_rescaled.csv`: deleted.
- `RP7/output/_pre_fix_backup_82766d2/`: deleted.
- `tools/results_overview/compare.py`: net −37 lines (29 from the
  module-level block, 6 from `Fit.headline()`, 2 blank lines).
- `RP7/scripts/17_verdier_robust.do`: early-exit removed.
- Branch is ready for PR-1.
