# Stage 6 completion and post-run handoff

## If you resume

Read the 2026-07-24 log end to end first, then this file end to end; the narrative below the divider carries the load-bearing detail.
The open thread is finishing Stage 6's post-run sequence, tracked as task #6 in the task list and enumerated as seven ordered actions in the narrative.
The first concrete action is checking whether `grc_IDN_cuu_ca` finished (worker idn2, the only cell of 20 still running at 11:49 Saturday; look for [logs/idn2/worker_done.txt](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/idn2/worker_done.txt)).
The one analytical trap waiting: several attached 95% CIs print a $+\infty$ upper endpoint, which may be truncation at the never-widened +1 upper grid edge rather than a genuine weak-identification unbounded region; the endpoint check must test both edges, and an upper-side rerun needs a not-yet-existing `phihi` override mirroring the `philo` pattern.
Cached state in one glance: E1/E2 rework implemented, reviewed, and verified on main (ce16dc2 + 8eaea3d) with the transition run NOT yet executed (run `12_counterfactuals.do` with `$cf_allow_drift = 1` only after all workers are done); port worktree at b13309e with the run logs and two chn relaunch launchers untracked; ster backup at `RP7/output/backup_prestage6_2026-07-24/`; Emilia still owes the one-step Verdier formal sign-off and the E1 variant A/B pick (the latter after the movement memo).

---

## 2026-07-25

This is a Saturday-morning continuation of the 2026-07-24 session.
That session's log, [2026-07-24_postrun-sweep-e1e2-spec-decisions.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-24_postrun-sweep-e1e2-spec-decisions.md), carries the full E1/E2 and launch narrative across three addenda, and a resuming session needs to read it in full rather than skim it.

Today's goal was narrow: verify the overnight WCR11 Stage 6 run completed and hand off the post-run sequence to a fresh-context session, at Emilia's request.

### Verified state at 11:49

19 of the 20 WCR11 cells are attached, with zero FAILED lines across any worker log.
TZA is done at 4/4, and the hukou worker finished both CHN_rf and CHN_uf at 4/4 each.
IDN's ct and c1 cells are done under worker idn1, with its done-file present, and IDN's c2 cell is done under worker idn2.
CHN's ct and c1 cells are done under worker chn1, and CHN's c2 and ca cells are done under worker chn2.
The one remaining cell is `grc_IDN_cuu_ca`, worker idn2's second cell, still running as the single live Stata process; the IDN cells each ran roughly 10 hours, about 1.6 times the pilot-scaled estimate.

A quick scan of the attached endpoints turned up several cells printing a $+\infty$ upper 95% endpoint.
The phi grid was widened only on the lower side, to -5, while the upper bound stayed at +1.
The B=9 smoke run showed that the attach step renders an accept region touching a grid edge as an infinite endpoint, so these $+\infty$ entries may just mean truncation at the +1 edge rather than a genuinely unbounded region.
The next session's endpoint check has to examine both edges and distinguish declared-open weak-identification regions from grid truncation.
An upper-side rerun would need a `phihi` override that does not exist yet: only `${inversion_philo}` was threaded through, and the same pattern would need to reach `compute_all_inversion_cis` and `attach_inversion_for_stata` in [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/python-grc/lca_inversion.py), the `philo()` option on `attach_inversion_ci`, and the 5b/5c call sites.

Worker logs live under [logs/](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/), with subdirectories for idn1, idn2, tza, chn1, chn2, hukou, and smoke.
Each finished worker wrote a `worker_done.txt`, and per-cell completions grep as "Inversion CIs attached."
The pre-launch backup of the .ster files sits at [backup_prestage6_2026-07-24/](file:///C:/git/ckt/RP7/output/backup_prestage6_2026-07-24/), 100 files.

One incident is worth a one-line recap here, though it is already logged in full in the 2026-07-24 file: the original single CHN worker stalled for 5 hours behind an invisible Stata Break dialog, was relaunched at roughly 19:58 as two split workers, and those relaunched workers completed cleanly.

### Next concrete actions (task #6)

First, wait for `grc_IDN_cuu_ca` to finish; check [logs/idn2/worker_done.txt](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/idn2/worker_done.txt).

Second, run the per-cell endpoint check on all 20 cells at both grid edges, -5 and +1.
Distinguish genuine weak-identification open regions, expected for CHN_uf per the port plan's Stage 7 (report as-is, author words the presentation), from grid truncation.
If the upper-side truncation turns out to be real, thread a `phihi` override mirroring the `philo` pattern and rerun only the affected cells.

Third, verify `e(inv_method)=wcr11` and the delta-family scrub on all reported .ster files.

Fourth, rebuild the affected tables per the port plan's Stage 6.
`10_make_tables` reads .ster files and does not re-run GMM, so this uses the worktree code against the main-tree .ster files the same way the workers did: `$dir` set to the worktree, `RP7`, with `$dirdata` and `sterdir` pointed at [RP7](file:///C:/git/ckt/RP7).

Fifth, run the counterfactual transition: [12_counterfactuals.do](file:///C:/git/ckt/RP7/scripts/12_counterfactuals.do) in the main repo, with the global `cf_allow_drift = 1`.
The exporters are now safe to run this way because the workers are done.
The code for this is already implemented, critic-reviewed, fixed, and verified, across commits ce16dc2 and 8eaea3d.

Sixth, write a movement memo to `quality_reports/reviews/` for author adjudication, covering WCR11 phi confidence intervals against the chi-squared-era ones, counterfactual drift against the baseline, and the variant A and variant B tables side by side.

Seventh, after the memo, four author gates follow: the drift adjudication itself; the E1 variant pick, which sets `$cf_e1_variant` and creates the canonical `counterfactual_misallocation.tex`; the preamble table-macro diffs, proposed as a diff for Emilia to place into Overleaf herself; and the additive copy of the tables into the Overleaf `tables/` folder.

### Cached state for the resuming session

Main repo commits: 82b006e (the E1/E2 plan), 6c26ec4 (a spec and plan amendment valuing both baselines), ce16dc2 (the E1/E2 implementation), 8eaea3d (approved critic fixes), and a731195 plus fd9d97d (session log addenda).

The port worktree, branch `wcr11-inversion-port`, is at commit b13309e, which carries the launch plumbing: `phi_lo` threading, the country and spec worker splits, and the launchers.
Untracked in that worktree: `worker_chn1.do`, `worker_chn2.do`, the smoke artifacts, and all run logs under [explorations/wcr11-stage6/](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/); these are commit candidates.

`12_counterfactuals.do` carries three knobs: `$cf_allow_drift` for loud drift, `$cf_regen_baseline` as a one-shot self-clearing flag, and `$cf_e1_variant`, which takes A or B and writes the canonical table.

The detached-batch gotchas that caused the CHN stall are recorded in project memory: the full executable path is `C:\Program Files\StataNow19\StataMP-64.exe`, the launch window style must be Minimized and never Hidden, and a zero-CPU process combined with a window-class `#32770` enumeration is how a hidden dialog stall gets diagnosed.

Two confirmations from Emilia are still pending: formal sign-off that one-step Verdier is the official method, which is already the de facto shipped state, and the E1 variant pick, which comes after the movement memo.

For timing reference, at the widened 601-point grid with B = 999, IDN cells ran about 10 hours each and CHN cells about 3.5 hours each.
