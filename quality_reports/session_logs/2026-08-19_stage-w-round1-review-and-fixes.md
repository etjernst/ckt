# Stage W external review round 1, approved fixes in progress; CHN upper rerun landing

## If you resume

Read the 2026-08-18 log first (it carries the launch state), then this file.
Two live threads: (1) the local upper-widened WCR11 rerun (chnhi1 and chnhi2 finished 08:17, rfhi still on its fourth CHN_rf cell; sentinels under [logs/](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/)), after which the endpoint recheck, table rebuild, counterfactual transition, and movement memo follow as in the 2026-07-25 handoff; (2) the Stage W simulation on branch `worktree-extension-sims`, where an external review held the production launch and Emilia approved a fix bundle now being implemented.
Three sonnet subagents were dispatched at about 10:45 for the mechanical legs (driver changes, summarizer plus oracle tests, analytical signal report); if their results are not in this log's later sections, check the working tree of the extension-sims worktree for uncommitted files in `sims/src/` and `sims/tests/`.
The Gadi coarse set-metric pilot (job 176589969) is still running; the power pilot (176589968) finished and its raw rows are fetched locally under `sims/results/power_setmetric/`.

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
