# Stage W external review round 1, approved fixes implemented; CHN upper rerun landed, tables rebuilt, transition run, movement memo written

## If you resume

Read the 2026-08-18 log first, then this file end to end.
Stage 6 thread: complete through the movement memo.
The eight CHN and CHN_rf cells were re-attached on [-5, 5] (six still open above at 95 percent, lean is to report as open and stop widening); all 28 GRC tables were rebuilt at 11:15; the counterfactual transition ran at 11:35 with `$cf_allow_drift = 1` (variant B reproduces the baseline points; drift is the new schema); the movement memo for Emilia is [2026-08-19-stage6-movement-memo.md](file:///C:/git/ckt/quality_reports/reviews/2026-08-19-stage6-movement-memo.md).
Four author gates remain: drift adjudication, E1 variant pick (lean B), presentation of the open regions and the IDN ca islands, Overleaf macro diffs and table copy.
Stage W thread (extension-sims worktree): the round-1 fix bundle is implemented, reviewed, fixed, and committed (drivers with shared signs, `--offsets`, exact-truth grids; summarizer with 48 tests; plan amended); the outer-grid power pilot is Gadi job 176640720 in `/scratch/dr48/et5292/ckt-sims-r1` (results to `sims/results/power_outer`), and its curves fix the production offset grid.
Compute is the open decision: the coarse set-metric pilot priced production at about 33,000 SU for the plan's spec against 7.39 KSU available in Q3 plus 10 KSU in Q4; options and a recommendation were put to Emilia at about 11:05 and no answer has arrived.

---

## 2026-08-19

Goal: keep the two overnight jobs moving and get the Stage W power experiment past an external critic before spending about 4,500 service units on production.

Overnight results: chnhi1 and chnhi2 attached both cells each with no failures; rfhi at three of four cells by 08:47.
Gadi power pilot: 5,250 tests, zero failures, all 399 draws valid, 1 h 45 min, 56 SU, 1.12 SU per replication; results fetched and tabulated to `sims/results/power_setmetric/pilot_power_wcr_by_offset.csv`.

Emilia asked what Stage W buys and then for a brief an external critic could review; the brief grew from a one-pager to a full linked document, [stage_w_power_external_brief.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/stage_w_power_external_brief.md), carrying code and result links, the Stage U size table, the pilot power table, two pilot observations (benchmark power at $q = 26$ only 0.32 at offset +0.50 in the anchor and 0.08 in the sparsest design; intermediate $q$ appearing more powerful than 26), and six critic questions.

The critic returned [2026-08-19_stage_w_power_external_brief_round1.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-08-19_stage_w_power_external_brief_round1.md): NOT READY, six CRITICAL items.
Three of its factual claims were verified directly: the full 401-point grid misses the exact truth ($-0.5247$ is off the 0.01 lattice on $[-3, 1]$); the plan text says redraw invalid draws while the code drops and flags them; CHN pooled and rural-first have $J_R = 9$, urban-first 5, TZA 4.
Triage at [2026-08-19_stage_w_round1_triage.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-08-19_stage_w_round1_triage.md).

Emilia's decisions (all 2026-08-19): approve the fix bundle (items 1 to 10); keep the code's drop-and-flag invalid-draw rule and amend the plan; run an outer-grid pilot before freezing the grid; adopt the shared sign matrix per replication; answer the pooling-weights concern analytically rather than adding a projection arm.

One reversal after the decisions: I had recommended truncating the offset grid at $\phi = -1$; the pole is a singularity of derived quantities, not of $\phi$ or the inversion test (the paper's real-data grid runs to $-5$, regions cross $-1$, all pilot tests at $-1.02$ valid), so the plan extends both sides and flags rows below $-1$; Emilia informed, no objection yet.
Second correction: the shared-signs code changes which draws each test receives, so the pilot's 25 replications are not a production prefix; production reruns them (about 56 SU).

Files changed and committed on `worktree-extension-sims`: the plan [2026-08-19-stage-w-round1-fixes.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/plans/2026-08-19-stage-w-round1-fixes.md); the Stage W amendment in [2026-07-22-unified-run-and-derived-quantity-coverage.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/plans/2026-07-22-unified-run-and-derived-quantity-coverage.md) revised in place (one-sided noninferiority power bar over one family with pair-completion floor 0.90; proper-set, empty-set, paired-length bars; sequential selection $q = 20$ down with deterministic coarse-to-fine fallback; exact truth and power offsets on every grid; failed grid points make a replication indeterminate; drop-and-flag invalid draws; shared sign matrix; country-scope map $q_{cell} = \min(q^*, J_{R,cell})$; wording fixes; a dated round-1 revision section); the bootstrap note gains the shared-matrix paragraph.

In flight (sonnet subagents): `run_power_eval.py` and `run_setmetric_eval.py` (shared signs, `--offsets`, exact-truth grids with `grid_role`, `phi0_below_minus1`); `summarize_power_setmetric.py` with oracle tests; `report_projection_signal.py` writing `sims/docs/projection_local_signal.md`.
Next after they land: review the diffs, critic-python on the drivers and summarizer, push to Gadi, run the outer-grid pilot (offsets $\{0, \pm 0.6, \pm 0.8, \pm 1.0, \pm 1.25, \pm 1.5, \pm 2.0\}$, $R = 25$, about 35 SU), freeze the production grid in the plan, then launch production power (four jobs, one per design, walltime 40 h, all replications from 0).

### Later on 2026-08-19 (11:00 to 11:45)

Subagent legs landed and were committed on `worktree-extension-sims`: drivers (shared sign matrix, `--offsets`, exact-truth grids with `grid_role`, `phi0_below_minus1`, PBS `OFFSETS`/`OUTDIR`/`BASE_DIR`), summarizer `summarize_power_setmetric.py` with oracle tests, projection signal report ([projection_local_signal.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/sims/docs/projection_local_signal.md): equal-weight tail cancels heavily at $q = 14$, ratio 11; $q = 2$ retains 3 to 10 percent; Wald-asymptotic power at $q = 26$, offset 0.5, anchor 0.87 against 0.32 bootstrap-corrected in the pilot).
Both drivers smoke-ran locally at B = 9.
critic-python review ([2026-08-19_stage_w_code_review.md](file:///C:/git/ckt/.claude/worktrees/extension-sims/quality_reports/reviews/2026-08-19_stage_w_code_review.md)): no CRITICAL; the MAJOR and MINOR items were applied by fixer-code and committed (c71f434); the default offset grid stays the old 21 points until the outer pilot freezes the production grid, and launch commands pass `--offsets` explicitly.
The revised tree was pushed to a separate Gadi directory (`ckt-sims-r1`, venv symlinked) so the running coarse pilot was not disturbed; the outer-grid power pilot was submitted from there.
The coarse set-metric pilot finished at 10:54 (12 h 57 min, 415 SU, 20,500 tests, zero failures): 3.2 h single-core and 8.3 SU per replication; production per the plan prices at about 33,000 SU (coarse) or 162,000 SU (full grid) against 7.39 KSU available; options were put to Emilia.
The summarizer ran end to end on the two pilots as a preview (winner 26 at R = 25, as expected at that noise).

Stage 6 thread: rfhi finished 10:59 (4/4); the endpoint check was given a per-country upper edge (+5 for CHN and CHN_rf) and rerun; addendum committed to the endpoint memo (dec2da1).
Tables rebuilt via [rebuild_tables.do](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/rebuild_tables.do) (main-tree `$dir`, port-branch `0_programs.do` for the renderer; a `/*` opener hidden in a comment path had to be removed first); backup of the previous tables at `RP7/output_tables_backup_2026-08-19/`.
Counterfactual transition ran with `0_programs.do` loaded (the first attempt failed with `compute_switcher_keeplist` unrecognized because `12_counterfactuals.do` assumes the master has loaded the programs); backup of the previous outputs at `RP7/output_cf_backup_2026-08-19/`.
Chi-squared-era CIs for the movement memo came from the 2026-07-21 ster vintage (`output_prestage9_2026-07-21`), since the pre-Stage-6 backup sters carried no inversion CI (5b was deferred in the definitive run).
Movement memo and regenerated outputs committed (15ba872).
