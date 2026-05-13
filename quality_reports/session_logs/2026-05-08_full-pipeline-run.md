# 2026-05-08: full-pipeline run (continuation from 2026-05-07 evening)

## Goal

Run the full RP7 pipeline (`0_master.do`) end-to-end in nominal mode.
This is the first full-pipeline run since the GRC refactor on the `worktree-grc-pipeline-refactor` branch.

## Context inherited from 2026-05-07

The pipeline was launched yesterday at 21:35 (2026-05-07) after fixing a bug introduced in [`ac8f3f6`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor) (audit batch 4: m6 retrofit).
Bug: `assert_merge_clean` declared its `label` option as `(string asis)`, so quoted call-sites like `label("handle_trajectory_groups")` injected literal double quotes into the macro, breaking the diagnostic `di` line with `r(133)` "unknown function".
Fix: changed line 117 of [`RP7/scripts/0_programs.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do) from `label(string asis)` to `label(string)`.

Bug stayed latent for ~9 days because all subsequent runs went through [`_smoke_full.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/_smoke_full.do), which deliberately excludes `1_processData.do` and `0_CHN_hukou_restrictions.do` (the only two scripts that actually invoke the helper).
Yesterday's launch was the first time `assert_merge_clean` ran end-to-end.
Full diagnosis is in [`2026-05-07_s1-prototype-coefplot-polish.md`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/quality_reports/session_logs/2026-05-07_s1-prototype-coefplot-polish.md) segment 4.

## Process management

Stata was launched via PowerShell `Start-Process` with `-WindowStyle Hidden` so it would survive the Bash-tool's 10-min child-process timeout cap.
Currently running as **PID 38876**, started 2026-05-07 21:35:30, fully detached from the harness.
Not to be confused with PID 48912 which is a separate `stata-mp -e do smoke_18_CHN.do` from the `worktree-vanilla-vv` branch and unrelated to this run.

## Cell timings (run_grc fits, `4_GrRC.do`, consumption-urban-unbalanced)

| Country | Cell | Wall time |
|---------|------|-----------|
| IDN | `cuu_c0` | 3287 sec (~55 min) |
| IDN | `cuu_ct` | 3001 sec (~50 min) |
| IDN | `cuu_c1` | 2844 sec (~47 min) |
| IDN | `cuu_c2` | 2920 sec (~49 min) |
| IDN | `cuu_ca` | 3152 sec (~53 min) |
| TZA | `cuu_c0` | 23 sec |
| TZA | `cuu_ct` | 28 sec |
| TZA | `cuu_c1` | 30 sec |
| TZA | `cuu_c2` | 34 sec |
| TZA | `cuu_ca` | 44 sec |
| CHN | `cuu_c0` | 345 sec (~5.7 min) |

IDN-unbalanced runtime is dominated by the **delta-method standard error block** at the end of each fit: `nlcom Delta_avg = <30-term weighted sum of switcher contributions>`.
That single `nlcom` call computes a symbolic Hessian roughly `O(K² × n)` and runs single-threaded (Stata MP can't parallelize it), eating ~45 min per IDN-unbalanced cell.
TZA only has ~5 trajectories so the `nlcom` is trivial; CHN sits in between.

## False alarm earlier in the run

Around 22:17 on 2026-05-07 the master log appeared "frozen" at 21:45 with the process at 21% CPU and Stata's window title stuck on "82% complete".
Almost killed the process before realizing this was just `nlcom` buffering 48 minutes of output until the command completed.
Once the buffer flushed, normal progress resumed and the first cell's ster was saved.
Lesson: long `nlcom` calls look hung but aren't.
For future smoke tests on IDN-unbalanced, consider opening a per-fit log inside `run_grc` so the buffer flushes more often, or wrapping `nlcom` with a heartbeat marker.

## Pipeline status

Currently in `4_GrRC.do`, partway through CHN consumption-urban-unbalanced.
Sequence so far: IDN cuu (5 cells, ~4 hours) -> TZA cuu (5 cells, ~3 min) -> CHN cuu (in progress, started ~01:55).

After CHN cuu finishes, `4_GrRC.do` should still need to do balanced samples (cub_*) for all three countries.
Then the master proceeds to `5_GrRC_NonAg.do`, `6_OLS_uGRC_hukou.do`, `7_GrRC_hukou.do`, `8_learning.do`, `9_GRC_extras.do`, then table builders (`10_make_tables.do`, `11_make_figures.do`), then `17_verdier_robust.do`.

The non-IDN cells are fast, so total remaining wall time is dominated by however many more IDN-unbalanced cells are scheduled across the various scripts.
Conservative: another 4-6 hours.

## Open

- Pipeline still running detached as PID 38876.
- Decision deferred: whether to commit the one-line `asis` fix on its own once the run completes, or bundle with whatever else lands.

with Claude

---

## Update at 03:00

Through `4_GrRC.do` cells (consumption-urban):

| Country | Sample | c0 | ct | c1 | c2 | ca | total |
|---------|--------|-----|-----|-----|-----|-----|-------|
| IDN | unbal (cuu) | 3287 | 3001 | 2844 | 2920 | 3152 | ~250 min |
| TZA | unbal (cuu) | 23 | 28 | 30 | 34 | 44 | ~3 min |
| CHN | unbal (cuu) | 345 | 362 | 398 | 441 | 504 | ~34 min |
| IDN | bal (cub)   | (slot 16, missed log) | 493 | 492 | 510 | 550 | ~42 min |
| TZA | bal (cub)   | 16 | 21 | (in progress) | | | |

(All times in seconds; pulled from `run_grc:.*fit in` lines in master log.)

Pattern: balanced samples are 5-6× faster than unbalanced for IDN (lower trajectory count after dropping partial-panel individuals); CHN is ~6 min/cell unbalanced and likely sub-min balanced; TZA is always sub-minute.

After CHN cub finishes, `4_GrRC.do` should be done.
Next is `5_GrRC_NonAg.do` (IDN-only, non-ag treatment instead of urban) and downstream scripts.

with Claude

---

## Update at 04:30: 4_GrRC.do crossed into income outcome

Completed full consumption-urban set (slots 1--30):
all three countries × balanced/unbalanced × 5 covariate columns.

Now in income-urban (`iuu`/`iub`) half of `4_GrRC.do`.

| Slot | Cell | Wall sec |
|------|------|---------:|
| 31 | `grc_IDN_iuu_c0` | 1514 |
| 32 | `grc_IDN_iuu_ct` | 1755 |

IDN income cells are ~25--30 min vs ~50 min for the consumption analogs.
Income sample is smaller (income data missing more often than consumption), fewer switcher trajectories, smaller `nlcom` Hessian.

Remaining in `4_GrRC.do`: 28 more income cells (3 IDN-iuu remaining + 5 TZA-iuu + 5 CHN-iuu + 5 IDN-iub + 5 TZA-iub + 5 CHN-iub).
Conservative IDN-iuu remainder: 3 × 30 min = 90 min.
Then balanced (faster) plus the small countries.
Estimated `4_GrRC.do` completion: ~2 more hours.

After that: `5_GrRC_NonAg.do` (IDN-only, non-ag treatment), `6_OLS_uGRC_hukou.do` (CHN-only, OLS), `7_GrRC_hukou.do` (CHN-only, GRC by hukou regime), `8_learning.do`, `9_GRC_extras.do`, then table/figure builders, then `17_verdier_robust.do`.

with Claude

---

## Update at 06:15: IDN-iuu done, TZA + CHN income halves moving fast

| Slot | Cell | Wall sec |
|------|------|---------:|
| 33 | `grc_IDN_iuu_c1` | 1857 |
| 34 | `grc_IDN_iuu_c2` | 1906 |
| 35 | `grc_IDN_iuu_ca` | 2019 |
| 36 | `grc_TZA_iuu_c0` | 5.6 |
| 37 | `grc_TZA_iuu_ct` | 7.2 |
| 38 | `grc_TZA_iuu_c1` | 8.3 |
| 39 | `grc_TZA_iuu_c2` | 9.4 |
| 40 | `grc_TZA_iuu_ca` | 10.9 |
| 41 | `grc_CHN_iuu_c0` | 59.7 |

Note IDN-iuu cells averaged ~30 min, escalating with each covariate added (1514 → 2019 sec).
TZA iuu cells are even faster than the cuu equivalents (5--11 sec vs 23--44 sec) since the income sample is smaller.
CHN iuu is also faster than cuu (1 min vs 5 min for c0).

Slots 1--40 done so far.
Remaining in `4_GrRC.do`: 4 more CHN iuu cells, then iub (income-balanced) for all three countries (15 cells).
Estimated `4_GrRC.do` completion: another ~1 hour.

with Claude

---

## Update at 08:40

`4_GrRC.do` finished at slot 45.
Spec was 45 cells: cuu (consumption-urban-unbalanced) + cub (balanced) for all three countries × 5 cov columns = 30 cells, plus iuu (income-urban-unbalanced) for all three countries × 5 cov columns = 15 cells.
Income-balanced (iub) is NOT part of the spec.

Now in `5_GrRC_NonAg.do` (IDN-only, non-ag treatment). Cells so far:

| Slot | Cell | Wall sec |
|------|------|---------:|
| 46 | `grc_IDN_cnu_c0` | 1866 |
| 47 | `grc_IDN_cnu_ct` | 2127 |
| 48 | `grc_IDN_cnu_c1` | 2228 |

(Slot 49 currently in nlcom block, log frozen at 08:09 for ~30 min.)

`5_GrRC_NonAg.do` cells follow the same naming as `4_GrRC.do` but with `n` (non-ag) instead of `u` (urban) treatment.
Expecting: cnu × 5, cnb × 5, inu × 5, possibly inb × 5 (need to verify by reading the script, but pattern from 4_GrRC suggests cnu+cnb+inu = 15 cells, no inb).

240 sters on disk since launch.
Run elapsed ~11 hours (since 2026-05-07 21:35).

Estimated remaining: another 4-6 hours through 5_GrRC_NonAg, 6_OLS_uGRC_hukou, 7_GrRC_hukou, 8_learning, 9_GRC_extras, 10/11/17.

with Claude

---

## Update at 10:15: dashboard refresh + datestamps + pipeline halfway

User asked for a dashboard refresh with a "Results from DATE" line under each table.

### compare.py: new helper

Added `comparison_dates(fix, versus, output_dir)` to [compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py).
For each version: discovers the same `(stem, cov)` cells `comparison_table` does, takes the OLDEST mtime across the on-disk `.ster` files (conservative: "results are at least this old"), formats as `YYYY-MM-DD HH:MM`.
Versions backed by [scraped_real.json](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/scraped_real.json) (no on-disk sters) get "(scraped from log)" instead.
Returns a small grey HTML line.

### report.qmd: 24 chunks updated

Imported the helper, then replaced every `print(render_table(table))\nprint("\`\`\`")` with the same plus `print(comparison_dates(fix=fix, versus=versus))`.
Single `replace_all=true` Edit got all 24 occurrences.

### Render kicked off

`cd tools/results_overview && quarto render report.qmd --to html` running in background.
First attempt's monitor triggered prematurely on a `pgrep -f "quarto render"` that matched nothing; second attempt running synchronously now.

### Pipeline progress while we worked

Pipeline kept moving through CHN hukou-split fits:

| Slot | Cell | sec |
|------|------|----:|
| 56 | `grc_CHN_rf_cub_c0` | 132 |
| 57 | `grc_CHN_rf_cub_ct` | 153 |
| 58 | `grc_CHN_rf_cub_c1` | 199 |
| 59 | `grc_CHN_rf_cub_c2` | 220 |
| 60 | `grc_CHN_rf_cub_ca` | 262 |
| 61 | `grc_CHN_rf_iuu_c0` | 28 |
| 62 | `grc_CHN_rf_iuu_ct` | 40 |

So `7_GrRC_hukou.do` is doing rf-cuu/cub then rf-iuu/iub for CHN, and presumably uf-* for the urban-first half next.
60 slots done; estimated remaining: 30-50 more across hukou-uf and the downstream scripts.

with Claude

---

## Update at 10:55: hukou-uf set partway, dashboard render still in flight

CHN urban-first cells progressing fast (~25--150 sec each). Slots 71--73 done.
Pipeline cumulative count: 73 fits since launch.

### Dashboard render

`quarto render report.qmd --to html` is still running (quarto.exe + deno.exe + node.exe processes alive).
Initial bg launch's task output file got cleaned up by the harness, so the bash bg "ended" but the actual quarto/deno child kept going.
Re-armed a watcher polling `report.html` mtime; will fire when the file is rewritten.

### Monitor cleanup

Two pipeline monitors were firing duplicate events for every fit (an old one from before the dashboard work plus a fresh one re-armed afterwards).
Stopped the older one to halve the noise.

with Claude

---

## Update at 11:30: dashboard rendered + hukou cells progressing

### Dashboard

`report.html` rewritten at 10:37 (2.64 MB).
All 24 `Results from <YYYY-MM-DD HH:MM>` lines render correctly under their tables.
`comparison_dates()` works as designed: per-version oldest-mtime across the displayed cells, with "(scraped from log)" fallback for real-values versions backed by `scraped_real.json`.

The original "first" render (which I thought failed earlier because the bash bg output file looked empty) actually finished too --- the harness just reported it asynchronously much later.
Both renders produced equivalent html; the second one's mtime is the one on disk.

### Pipeline at slot 82

Through the four hukou splits in `7_GrRC_hukou.do`:

| Variant | Cells | Pattern |
|---------|-------|---------|
| `rf` (rural-first) | 51--65 (15 cells) | cuu/cub/iuu × 5 covs |
| `uf` (urban-first) | 66--80 (15 cells) | cuu/cub/iuu × 5 covs |
| `ro` (rural-only?) | 81-- (in progress) | cuu/cub/iuu × 5 covs expected |
| `uo` (urban-only?) | pending | |

Currently slot 82 (`grc_CHN_ro_cuu_ct`, 268 sec) --- ro cells running ~4--5 min each, slower than uf (~30--80 sec) probably because the rural-only sub-sample retains more switcher trajectories than the urban-only one.

with Claude

---

## Update at 11:55: ro variant nearly done

Slots 81--93 covered CHN `ro` variant cuu/cub (10 cells, ~25 min total) and started ro_iuu (3 cells, ~90 sec total).
Two more ro_iuu cells expected, then `uo` variant (15 cells), then `7_GrRC_hukou.do` is done.

`ro` cuu cells ran ~4--6 min each, slower than `uf` (30--80 sec).
`ro` cub cells ~2--3 min, `ro` iuu sub-min.
The pattern: rural-only sub-sample retains more switcher trajectories than urban-only.

Cumulative through slot 93: 93 fits since launch.
Run elapsed: 14h 20m (since 2026-05-07 21:35).

with Claude

---

## Update at 12:25: 100 fits crossed, uo variant moving fast

Timer slot wrapped at 100 (per commit `5c21224`'s wrap-at-100 logic). Fit #101 onwards reuses slot numbers.

Hukou variants completed/in-progress:

| Variant | Fits | Cuu range | Comment |
|---------|------|-----------|---------|
| `rf` (rural-first) | 51--65 | 5--7 min/cell | mid-runtime |
| `uf` (urban-first) | 66--80 | 30--80 sec/cell | small sample |
| `ro` (rural-only?) | 81--95 | 4--6 min cuu, 2--3 min cub | bigger sample |
| `uo` (urban-only?) | 96-- | 30--60 sec | smallest sample so far |

uo cuu set complete (96--100). Now in uo cub (101--104). 1 more cub cell + 5 iuu cells expected.

Cumulative through fit #104: 104 fits since launch, 14h 50m elapsed.

After hukou is done, `7_GrRC_hukou.do` is complete. Next: `8_learning.do`, `9_GRC_extras.do` (44 stems per memory), then table/figure builders, then `17_verdier_robust.do`.

with Claude

---

## Update at 11:50: pipeline halt + resume

### Halt at slot 110 (`8_learning.do`)

After completing all 60 hukou cells (slots 51--110, four variants rf/uf/ro/uo × cuu/cub/iuu × 5 covs), the pipeline entered `8_learning.do` and halted with `r(601)` "file not found".

Bug at [`RP7/scripts/8_learning.do:127`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/8_learning.do) and L218: the `create_panel_tex_table_learn_<C>` call writes `OLS_<C>_<depvar>_learning_<balance>.tex` but the very next `copyOverleaf` line referenced `OLS_<C>_<depvar>_<choice>_<balance>.tex` (= `OLS_<C>_<depvar>_urban_<balance>.tex`).
Different filename, doesn't exist, r(601), Stata exits.

Fixed both lines to use `_learning_` pattern. User-approved.

### Resume strategy

User wanted to keep all sters from this run but force any stale older sters to re-fit.
The codebase has a built-in resume mechanism in `run_grc`: if `${skip_if_exists} == "1"` and the cell's `_g.ster` exists, the fit is skipped (see [`0_programs.do:1842`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do)).
This is the canonical resume path, not a hack.

Steps taken:
1. Deleted 955 ster files with mtime before 2026-05-07 21:35:30 (this run's launch time).
   Kept 550 sters from this run.
2. Wrote [`RP7/scripts/run_master_resume.do`](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do): two-line wrapper that sets `global skip_if_exists 1` then `do "0_master.do"`.
3. Launched detached as PID 17140 at 11:42 via PowerShell `Start-Process`.
4. Auto-log writes to `RP7/scripts/run_master_resume.log` (not `0_master.log` --- new entry point, new auto-log).

### Resume run blowing through skips

All 110 prior fits skipping in seconds:
- cuu × 3 countries (15)
- cub × 3 countries (15)
- iuu × 3 countries (15)
- cnu × IDN (5)
- rf / uf / ro / uo × CHN × 3 spec3 × 5 covs (60)

After the skips, the pipeline will run for the first time:
- rest of `8_learning.do` (now bug-free)
- `9_GRC_extras.do` (44 stems --- many fresh fits, the family-extras and IDN-birth dispatcher)
- `10_make_tables.do`, `11_make_figures.do`
- `17_verdier_robust.do`

with Claude

---

## To-do (after main run finishes)

### Delta_avg rescaling

Bug: `0_programs.do` lines 2009 / 2318 / 2632 / 2986 use `sum 1.switcher_\`s' if e(sample)` to set `num_\`s'`, which gives `N_s/N_total` (sums to switcher_frac, ~4--11%) rather than `N_s/N_switchers` (sums to 1).
The `lca-inversion` branch fixed this in commit `5cfe158` (Apr 30) but the fix was never merged into `worktree-grc-pipeline-refactor`.

So every `_g.ster` saved on this branch carries `Delta_avg_buggy = switcher_frac * E[Delta | switcher]` instead of `E[Delta | switcher]`.
This affects the 110 sters from this run AND any new `_g.ster` produced by `9_GRC_extras.do` in the in-flight resume (the resume loaded the buggy `0_programs.do` before any fix could be applied).

Plan once main run finishes:

1. Apply the 4-line fix to `0_programs.do` (each: `if e(sample)` --> `if e(sample) & switcher == 1`).
2. Write `RP7/scripts/fix_delta_avg_scaling.do` that walks all `RP7/output/grc_*_g.ster`, computes `switcher_frac` per cell from data + main ster's `e(sample)`, multiplies the `_g.ster`'s `b` by `1/switcher_frac` and `V` by `(1/switcher_frac)^2`, and saves back.
   Math: nlcom expression is exactly linear in the trajectory weights, so `Delta_avg_correct = Delta_avg_buggy / switcher_frac` and `SE_correct = SE_buggy / switcher_frac`.
   Z-stats / p-values / stars unchanged.
3. Mark rescaled sters via a flag file or a stored scalar so re-running the script is idempotent.
4. Re-render the dashboard.

Note: this would be one of two fixes accumulated on this branch that need merging back to `lca-inversion` (or vice versa) at some point.

with Claude

---

## Wrap-up at 12:35 (pre-/clear)

This section captures the full-day arc with rationales, in case the next session has to pick up cold.

### Goals through the session

Initial ask: run the full RP7 pipeline (`0_master.do`) end-to-end in nominal mode.
This was the first end-to-end run since the GRC refactor on `worktree-grc-pipeline-refactor`.
Mid-session asks, in order:

1. Refresh [tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html) and add a per-table "Results from DATE" line so the dashboard shows at a glance which cells are stale.
2. Investigate whether Delta_avg is being computed in the "updated way" --- visual inspection suggested it was not.
3. Once the bug was confirmed, stop the in-flight run, fix the formula, post-hoc rescale the existing 110 `_g.ster` outputs, and resume so downstream cells get the corrected version from birth.
4. /wrap-up before /clear.

### What got built or changed

[RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/0_programs.do).
Two fixes:

- L117: `label(string asis)` to `label(string)` in `assert_merge_clean`.
   The `asis` modifier was preserving literal double quotes from `label("handle_trajectory_groups")` callsites, breaking the diagnostic `di` line with `r(133)` "unknown function".
   Latent for nine days because all subsequent runs went through `_smoke_full.do`, which excludes `1_processData.do` --- the only caller of the helper.
- L2009 / 2318 / 2632 / 2986: `if e(sample)` to `if e(sample) & switcher == 1` in the four `Delta_avg_nlcom` blocks of `run_grc`, `run_grc_onestep`, `run_grc_robust`, and `run_grc_robust_vv`.
   Bug gave `num_s = N_s/N_total` (sums to switcher_frac, ~4 to 11%) instead of `N_s/N_switchers` (sums to 1), so published `Delta_avg = switcher_frac * E[Delta | switcher]`.
   The fix is a cherry-pick of `lca-inversion` commit `5cfe158` (Apr 30) that never made it into this branch.

[RP7/scripts/8_learning.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/8_learning.do).
L127 and L218: changed the `copyOverleaf` filename pattern from `OLS_<C>_<depvar>_<choice>_<balance>.tex` to `OLS_<C>_<depvar>_learning_<balance>.tex` for IDN and CHN.
The just-created file uses `_learning_` between depvar and balance; the copy line was using `_<choice>_` (= `_urban_`).
That filename does not exist, `r(601)` halts pipeline.

[tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py).
Added `comparison_dates(fix, versus, output_dir)` around line 430.
For each version it discovers the same `(stem, cov)` cells `comparison_table` does, takes the oldest mtime across the on-disk `.ster` files, formats as `YYYY-MM-DD HH:MM`, returns a small grey HTML line.
Versions backed by `scraped_real.json` (no on-disk sters) get "(scraped from log)" instead.

[tools/results_overview/report.qmd](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.qmd).
Imported the helper, added a `print(comparison_dates(fix=fix, versus=versus))` call after each `print(render_table(table))` block --- 24 chunks total.

[tools/results_overview/report.html](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/report.html).
Re-rendered at 10:37; 2.64 MB; all 24 datestamp lines present.

[RP7/scripts/run_master_resume.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do) (new).
Two-line wrapper that sets `global skip_if_exists 1` then `do "0_master.do"`.
This is the canonical resume entry point documented at `0_programs.do:1842`.

[RP7/scripts/fix_delta_avg_scaling.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/fix_delta_avg_scaling.do) (new).
Sidecar-CSV rescaler.
Overrides `run_grc` to bypass the GMM and instead compute `switcher_frac` from a fast surrogate OLS, read the buggy `Delta_avg` and SE from the saved `_g.ster` via `estimates use`, and append a row `(estname, sw_frac, scale, b_buggy, se_buggy, b_rescaled, se_rescaled)` to `RP7/output/delta_avg_rescaled.csv`.
Walks the 110 cells by `include`-ing `4_GrRC.do`, `5_GrRC_NonAg.do`, and `7_GrRC_hukou.do`.

[RP7/output/delta_avg_rescaled.csv](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/delta_avg_rescaled.csv) (new).
110 data rows + header.
Per-cell rescaling factors range from 2.5 (IDN cub, sw_frac = 0.40) to 404 (CHN uo iuu, sw_frac = 0.0025).

### Decisions, with the why

Detached Stata via PowerShell `Start-Process -WindowStyle Hidden`.
Why: the Bash tool's hidden 10-min timeout cap killed an earlier launch mid-fit at 21:25; detaching the Stata process from the harness lets it run for as long as needed.

Did not kill the process during the 45-min "frozen log" episode.
Why: PID 38876 was burning CPU steadily (4500+ CPU-seconds across its lifetime, ~21% of one core) and its working set was changing.
Eventually the log flushed 48 minutes of buffered `nlcom` output at once and a ster appeared.
The 45-min freeze is `nlcom`'s symbolic Hessian on the 30-trajectory IDN-unbalanced sum, single-threaded by design --- not a hang.

Wrapper [run_master_resume.do](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.do) over editing `0_master.do` to set `skip_if_exists`.
Why: the codebase explicitly documents this resume pattern at `0_programs.do:1842-1853`.
The wrapper is the canonical entry point; editing `0_master.do` to set the global permanently would change semantics for everyone.

Sidecar CSV instead of in-place mutation of `_g.ster` files.
Why: `ereturn post b_new V_new` after `estimates use` of an `nlcom`-posted ster posts cleanly (rc=0) but `estimates save` then errors with `r(301)` "last estimates not found"; `ereturn repost b=b V=V` errors with `r(152)` "matrices not conformable".
Stata's e() context after `estimates use` of an `nlcom`-posted ster does not round-trip through post/save.
The CSV sidecar avoids mutating the binary `.ster`, keeps the buggy values inspectable as a paper trail, and decouples the correction from Stata's estimation context.

Surrogate OLS regression for `switcher_frac` rather than reading `e(sample)` from disk-loaded sters.
Why: Stata documents that `estimates use` does not restore `e(sample)` from a `.ster` file --- it only survives across `estimates store/restore` in-session.
The surrogate `reg lndepvar never always switcher_* <covars> if !missing(choice)` imposes the same non-missing requirements as the GMM (modulo choice-interaction restrictions, which contribute negligible additional dropouts in practice).

Deleted 955 old sters before resume.
Why: the user explicitly asked for this --- they wanted to overwrite stale May-1-to-3 sters but keep this run's 550 fresh ones.
After deletion, `skip_if_exists` reuses only this run's outputs and re-fits anything older.

Killed the in-flight resume to apply the Delta_avg fix cleanly.
Why: zero new fits had completed under the resume yet (only skips of the 110 prior fits), so the wall-time cost was about 25 minutes of one partial fit.
Cleaner provenance: the new `9_GRC_extras` outputs will be born correct under the fixed `0_programs.do`, no follow-up rescaling needed for them.

### Approaches rejected and the reason

Rerun nlcom only (option 2 originally proposed for the rescaling).
Reason dropped: `nlcom` IS the bottleneck (about 45 minutes per IDN-unbalanced cell because of the 30-trajectory symbolic Hessian), so re-running it for 110 cells costs roughly the same as a full re-run.

In-place ster mutation via `ereturn post` + `estimates save`.
Reason dropped: rc=301 on save after post; rc=152 on `ereturn repost`.
Stata's e() context after `estimates use` of an `nlcom`-posted ster does not accept post/save round-trip cleanly.

Cherry-picking `5cfe158` from `lca-inversion`.
Reason dropped (implicit): the manual 4-line edit on this branch + sidecar CSV is more contained.
The other parts of `5cfe158` (validation memo, Python validator, IDN regenerated sters) are unrelated to this run.

Using `e(sample)` from `estimates use`-loaded ster.
Reason dropped: empirical `count if e(sample) & switcher == 1` returned 0 for every cell.
Stata's docs confirm `estimates use` does not restore `e(sample)`.
Switched to a surrogate regression to reconstruct the sample.

### Open items and blockers

Resume run is in flight as PID 4864 (started 12:28, detached via PowerShell).
Auto-log at [RP7/scripts/run_master_resume.log](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.log).
All 110 prior fits are skipping cleanly per the latest monitor events.
Next: `9_GRC_extras.do` (44 stems planned, mostly IDN-unbalanced cells at 30 to 50 minutes each --- estimated 24 to 30 hours), then table builders, then `17_verdier_robust.do`.

Dashboard does NOT yet read the sidecar.
[tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py) `Fit.headline()` still reads Delta_avg directly from `_g.ster`, so the rendered HTML still shows buggy (small) Delta_avg values.
Next session needs to:

1. Modify `Fit.headline()` (or a wrapper layer) to load `RP7/output/delta_avg_rescaled.csv` once at module load and prefer the rescaled `(b, se)` when present.
2. Re-render the dashboard.

Two fixes accumulated on this branch are not yet on `lca-inversion`:

- `assert_merge_clean` `asis` fix.
- `8_learning.do` copyOverleaf filename fix.

Conversely, the `lca-inversion` branch has rerun-after-fix infrastructure (`explorations/python-grc/rerun_<C>_5gr_fixed.do`, `validate_delta_points.py`, the validation memo at `quality_reports/reviews/2026-04-29_delta-inversion-validation-gate.md`) that has not been pulled into this branch.
A merge or cherry-pick at some point is needed.

Uncommitted changes (per `git status`):

- M `RP7/scripts/0_programs.do` (assert_merge_clean + Delta_avg fixes)
- M `RP7/scripts/8_learning.do` (copyOverleaf filename fix)
- M `tools/results_overview/compare.py` (`comparison_dates` helper)
- M `tools/results_overview/report.qmd` (24 chunk additions)
- M `tools/results_overview/report.html` (re-rendered)
- M `quality_reports/session_logs/2026-05-07_s1-prototype-coefplot-polish.md` (carried over from yesterday)
- M `.claude/settings.local.json` (harmless local-permission state)
- ?? `RP7/output/delta_avg_rescaled.csv` (sidecar)
- ?? `RP7/scripts/run_master_resume.do` (resume entry point)
- ?? `RP7/scripts/fix_delta_avg_scaling.do` (rescaler)
- ?? Many `RP7/output/tables/OLS_*.tex` and `summary_stats_*.tex` (regenerated by this run; not previously tracked)
- ?? `.claude/scheduled_tasks.lock` (transient)

### Picking back up

If you resume in a fresh session, read this file first.

Open thread: pipeline still running detached as PID 4864 (`run_master_resume.do`).
Confirm it is alive with `Get-Process -Name "StataMP-64"` (will show one or two processes; 4864 is ours, any other is unrelated cross-worktree work).
Tail [RP7/scripts/run_master_resume.log](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/scripts/run_master_resume.log) for progress.

Next concrete actions, in priority order:

1. Once the run finishes (estimated late tonight or early tomorrow given the IDN-cell slowness), update [tools/results_overview/compare.py](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/tools/results_overview/compare.py) to read [delta_avg_rescaled.csv](file:///C:/git/ckt/.claude/worktrees/grc-pipeline-refactor/RP7/output/delta_avg_rescaled.csv) and override the buggy Delta_avg from `_g.ster` files.
   Then re-render the dashboard.
2. Decide what to commit and when.
   The `0_programs.do` fix is a real bug fix; the `8_learning.do` fix is a real bug fix; the dashboard changes are a self-contained improvement.
   These could each be separate commits.
3. Plan the eventual merge or cherry-pick between this branch and `lca-inversion` so neither branch loses its fixes.

State to know:

- `0_programs.do` was loaded by Stata at 12:28 with the Delta_avg fix; the in-flight run will produce correct Delta_avg for `9_GRC_extras` cells.
- The 110 existing `_g.ster` files still carry buggy Delta_avg values; the sidecar CSV is the source of truth for their rescaled versions.
- `report.html` was rendered against the buggy values; do not trust the displayed Delta_avg until `compare.py` is updated to use the sidecar.
- The dashboard "Results from DATE" lines stay accurate (they use `.ster` mtimes, which are correct).

with Claude
