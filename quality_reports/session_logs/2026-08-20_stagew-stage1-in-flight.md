# Stage W Stage one in flight on Gadi; Stage 6 closed except author gates

## If you resume

Read [2026-08-19_stage-w-round1-review-and-fixes.md](file:///C:/git/ckt/quality_reports/session_logs/2026-08-19_stage-w-round1-review-and-fixes.md) end to end first (it carries the two external review rounds, the fixes, and all of yesterday's author decisions), then this file.

The open thread is the Stage W Stage one production run: eight PBS jobs on Gadi (176677711 to 176677719, names `sm_f{factor}_r{0|250}`), set metrics for $q \in \{20, 26\}$, coarse lattice, $B = 999$, the frozen 33-offset grid, replications 0 to 499, output `/scratch/dr48/et5292/ckt-sims-r1/sims/results/stagew_prod_setmetric`.
At 10:15 on 2026-08-20 seven were running at 18 h elapsed of 30 h walltime and one (`sm_f4.0_r250`) was still queued; the running seven should finish around midday 2026-08-20 and the queued one about 20 h after it starts.

Next concrete action: `ssh et5292@gadi.nci.org.au 'qstat -u et5292'`; when all eight are gone, check each `sm_f*.o*` file under `/scratch/dr48/et5292/ckt-sims-r1` reads Exit Status 0, then fetch `sims/results/stagew_prod_setmetric/` (raw_setmetric plus every `manifest_setmetric_*.json`) into the extension-sims worktree, run `python sims/src/summarize_power_setmetric.py --power-dir sims/results/power_setmetric/raw_power --set-dir sims/results/stagew_prod_setmetric/raw_setmetric --set-manifest <the manifests> --out-dir <fresh dir> --n-boot 1000`, verify `decision.json` says `power_source: set_metric_b999`, and write the interim results memo (coverage, set quality, and power bars for $q = 20$ against $26$ at $R = 500$; the adoption rule and thresholds are in the plan's round-1 and round-2 revision sections).
The pilot batches live in separate directories (`power_setmetric/`, `power_outer/`) and must not be mixed into the production summarize call except as the descriptive `--power-dir` source.

Cached state.
Sims worktree (`C:/git/ckt/.claude/worktrees/extension-sims`, branch `worktree-extension-sims`, HEAD 0c73466): drivers with shared sign matrix and config-hashed manifests, summarizer with lattice-only topology and the $B = 999$ adoption power source, 75 tests passing; the governing plan is [2026-07-22-unified-run-and-derived-quantity-coverage.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/plans/2026-07-22-unified-run-and-derived-quantity-coverage.md) with two dated revision sections at the end and the frozen offset grid.
Stage two (Q4, October allocation): if $q = 20$ passes, paired full-grid confirmation of 20 against 26 (about 6,500 SU); if it fails, stay at 26 or run $q = 14$ (about 3,300 SU), the choice recorded before results are opened; descriptive $B = 399$ power curves for all five $q$ when the balance allows.
Q3 balance after Stage one: roughly 500 SU.

Stage 6 is closed except author items: the movement memo is [2026-08-19-stage6-movement-memo.md](file:///C:/git/ckt/quality_reports/reviews/2026-08-19-stage6-movement-memo.md); decided already are the 90 percent CI row (memory `project_phi_ci_90pct`), variant B (memory `project_e1_variant_b`), and the Overleaf note edits (applied directly to `preamble.tex` and `main-updated.tex`, compiled clean, five tables plus `counterfactual_misallocation.tex` and `hukou_bound.tex` copied over).
Still open for Emilia: presentation of the six CHN and CHN_rf cells open above the widened grid (lean: report as open, stop widening) and of the IDN ca five-island 95 percent set (moot in the tables now that only the 90 percent row prints, but live for any appendix that shows 95 percent); the always-urban caveat paragraph rewrite is Todoist task 6hHwvX2w5JM2C58J (due 2026-09-05).
The uncommitted working-tree noise in the main repo is mostly regenerated `RP7/output` figures and stage-test scaffolding predating this session; the counterfactual CSVs and the GRC/counterfactual tables are committed.

---

## 2026-08-20

Morning status check only: seven of the eight Stage one jobs running at 18 h elapsed, one queued, no output batches yet (each job writes its parquet only at factor completion).
No decisions, no file changes beyond this log.
Explained to Emilia that completion is discovered by polling `qstat` at next session start, that a local restart cannot touch the Gadi jobs, and that `/scratch` purges untouched files after 100 days, so results should be fetched within days.
