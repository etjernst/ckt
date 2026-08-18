# Upper-widened CHN rerun launched, Stage W pilot submitted, Verdier one-step signed off

## If you resume

Read the 2026-07-25 handoff and the 2026-07-26 endpoint memo first, then this file.
Three detached Stata workers are re-attaching WCR11 intervals at phi grid [-5, 5] to the eight CHN and CHN_rf cells; poll them by CPU delta and by `worker_done.txt` under [logs/](file:///C:/git/ckt/.claude/worktrees/wcr11-inversion-port/explorations/wcr11-stage6/logs/) (subdirectories `chnhi1`, `chnhi2`, `rfhi`), never by process existence.
Two Stage W pilot jobs are queued on Gadi (176589968 power, 176589969 coarse set-metric); fetch with `bash sims/hpc/fetch_results.sh power_setmetric` from the extension-sims worktree once `qstat -u et5292` shows them gone.
When the three workers are done, the remaining sequence is unchanged from the 2026-07-25 handoff: rerun the endpoint check on the eight cells, rebuild the affected tables, run the counterfactual transition (`12_counterfactuals.do` with `$cf_allow_drift = 1`), and write the movement memo.

---

## 2026-08-18

Emilia returned after three idle weeks and asked for the state of the project; the summary came from the 2026-07-25 handoff, the 2026-07-26 endpoint memo, and the sims worktree brief.

Decisions today, all Emilia's: launch the three upper-widened rerun workers; formal sign-off that one-step Verdier is the official robustness method (recorded in project memory as `project_verdier_onestep_official`); submit the Stage W pilot on Gadi in the meantime, with the note that compute is not a constraint.
The seed-contract question in the pilot brief (Stage W taking the 3000/4000 key blocks) was not raised separately, so the pilot runs with the blocks as committed; if Emilia wants them reserved after all, the pilot's replications would need a fresh key block and a resubmit.

Rerun launch at 21:58: the 40 sters for the eight cells were copied to [backup_preupperrerun_2026-08-18/](file:///C:/git/ckt/RP7/output/backup_preupperrerun_2026-08-18/) first, then `worker_chnhi1.do` (PID 18348), `worker_chnhi2.do` (PID 40024), and `worker_rfhi.do` (PID 39948) were started via `Start-Process` with the full StataMP-64 path, `-WindowStyle Minimized`, from the worktree's wcr11-stage6 directory.
A 45-second CPU-delta check showed all three at roughly 50 s of CPU per 45 s wall, and their `5b_inversion.log` / `5c_inversion_hukou.log` files exist.
Expected durations from the memo: about 12 h for each CHN worker, about 7 h for CHN_rf.
The one unrelated StataMP-64 process at launch (PID 10292) was the mcp-stata scout, not a worker.

Gadi: passwordless SSH as `et5292` works from this machine, so the push script and qsub ran directly.
`push_to_gadi.sh` refreshed `/scratch/dr48/et5292/ckt-sims`, then `qsub -v FACTORS="1.0 0.5",REPS=25 sims/hpc/power_eval.pbs` gave 176589968 and `qsub -v FACTORS="1.0 0.5",GRID=coarse,REPS=25 sims/hpc/setmetric_eval.pbs` gave 176589969; both queued in `normal` at 16 cores, 64 GB.
Once they finish, the plan's timing rule prices the production run and picks the grid tier, and the set-reconstruction summarizer is the next build.

Not touched: the uncommitted RP7/output artifacts (counterfactual CSVs dated 2026-07-26 13:32 with no logged provenance, regenerated tables and figures) stay uncommitted until the transition run regenerates them.
