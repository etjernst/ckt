# Stage W relaunch: supplement approved, 16 chunked jobs running, throughput shortfall accepted

## If you resume

Read [2026-08-20_stagew-stage1-in-flight.md](file:///C:/git/ckt/quality_reports/session_logs/2026-08-20_stagew-stage1-in-flight.md) end to end first (walltime incident, probe design, chunking implementation), then this file; this file's hand-off supersedes the resume block there.

The open thread: 16 production set-metric jobs (176966569 to 176966584, names `sm_f{0.5|1.0|2.0|4.0}_r{0|125|250|375}`) are running on Gadi since 2026-08-21 20:56 AEST, 125 replications each, 16 cores, 20 h walltime, `CHUNK=25`.
They will be killed at walltime around 17:00 AEST on 2026-08-22 with roughly half the 2,000 replications checkpointed; completed chunks survive as `sims/results/stagew_prod_setmetric/raw_setmetric/setmetric_IDN_f{X}_coarse_B999_69f0c386_rep{a}-{b}.parquet`.

Next concrete action, tonight after the kills: ssh `et5292@gadi.nci.org.au`, inventory surviving chunks per factor, measure per-factor chunk wall times from file mtimes (`stat -c '%y %n'`), write the stocktake, and draft the October resubmission plan with per-factor walltimes sized from those measurements, not from the probe.
Resubmission reuses the exact qsub loop below; the drivers skip completed chunks automatically.

```bash
cd /scratch/dr48/et5292/ckt-sims-r1
OFF="-2.0 -1.75 -1.5 -1.25 -1.0 -0.75 -0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.75 1.0 1.25 1.5 1.75 2.0"
for f in 0.5 1.0 2.0 4.0; do for s in 0 125 250 375; do
  qsub -N sm_f${f}_r${s} -l walltime=<PER-FACTOR> \
    -v "FACTORS=$f,JLIST=20 26,GRID=coarse,BVAL=999,REPS=125,REP_START=$s,CHUNK=25,OFFSETS=$OFF,OUTDIR=sims/results/stagew_prod_setmetric,BASE_DIR=/scratch/dr48/et5292/ckt-sims-r1" \
    sims/hpc/setmetric_eval.pbs
done; done
```

State to know:

- Budget: the OneHelp supplement was approved 2026-08-21 (20 KSU total across Q3 and Q4); Q3 now reads Grant 20 KSU with 10.62 KSU available at submission, and the running pass reserves 10.24 KSU, leaving about 0.4 KSU in Q3 afterward.
- Emilia CANNOT ask for another top-up (her words, 2026-08-22); the remainder of the study runs on the standing Q4 grant of 10 KSU from October 1.
- Emilia decided to let all 16 jobs run to walltime with no chunk-boundary kills and to build an interpretable half-sample read from this pass.
- Walltime-killed jobs never write manifests, and the summarizer reads manifest-listed files; the partial read needs either a hand-built manifest over the surviving chunks or one short completing job per factor.
- Partial samples are statistically clean: replications are independently seeded by index (SeedSequence spawn keys), so a chunk-truncated set is a random subsample; at 250 replications per factor, coverage near 90 percent is estimated to within about 1.9 percentage points.
- Measured costs so far: probe gave 4.3 SU per replication at factor 0.5 and 3.9 at factor 1.0 at 2-fit concurrency, but production at 16-fit concurrency runs 2 to 3 times slower, and factors 2 and 4 are substantially dearer than 0.5 and 1.0; per-factor production numbers come from tonight's chunk mtimes.
- After ANY scp push to Gadi, strip CRLF on the Gadi side (`sed -i 's/\r$//'`) and verify `head -1 | cat -A` shows `$` not `^M$`; memory `reference-gadi-crlf-push`.
- Chunked drivers and PBS scripts on Gadi match worktree commit c4dfeed (md5-verified, then LF-fixed in place); the worktree is `C:/git/ckt/.claude/worktrees/extension-sims`, branch `worktree-extension-sims`.
- Framing note: do not describe this pass as a pilot to Emilia; the mispricing is a sore point, and the pass is half the study, not a measurement exercise.
- The OneHelp ticket text lives at [quality_reports/2026-08-21_dr48_supplement_ticket.md](file:///C:/git/ckt/quality_reports/2026-08-21_dr48_supplement_ticket.md); the two staged Outlook drafts it superseded can be deleted.

---

## 2026-08-21 and 2026-08-22 morning

### Goals

Started as follow-through on the walltime incident: confirm the allocation-request draft, answer whether dr48 fits Macquarie's Tier 1 band, then submit the supplementary request and relaunch Stage one.
Mid-session corrections: the request went through a OneHelp ticket rather than email; first person singular throughout; totals read as whole-project (20 KSU over 2 quarters), not the delta.

### What happened

The timing probe (176849518) finished cleanly: 15.96 SU, four replications, per-replication cost 4.3 SU (factor 0.5) and 3.9 SU (factor 1.0), read from the `wall_fit_s`/`wall_boot_s` columns via the project venv.
Stage one was repriced at about 9 KSU for set metrics and the supplement ask confirmed at 10 KSU on top of standing grants.
The chunked drivers and both PBS scripts were pushed to Gadi and md5-verified against worktree commit c4dfeed.
The OneHelp ticket (submitted with 20 KSU total over 2 quarters, reason field at 49 words) was approved the same day and the top-up landed by evening.
Held job 176677719 was qdel'd with approval before the funds arrived so nothing could auto-start on stale sizing.
Stage one relaunched as 16 jobs of 125 replications at 20 h walltime; the first submission (176961546 to 176961561) died instantly on CRLF shebangs from the Windows scp, was fixed with `sed -i 's/\r$//'` on Gadi (~0.2 SU lost), and the clean resubmission (176966569 to 176966584) started within minutes.
By morning, 13 chunks (325 replications) were checkpointed but throughput was 2 to 3 times below the probe-based estimate.

### Decisions, with the why

- Ticket numbers went in as 20 KSU over 2 quarters rather than the 10 KSU delta.
Why: Emilia read the form's "total for all quarters (max 60)" as whole-project, and the max mirrors the Tier 1 per-project cap; text and numbers were aligned to that reading.
- Relaunched as 16 jobs of 125 replications at 20 h rather than 8 jobs of 250 at more walltime.
Why: measured probe cost put 250 replications of factor 0.5 at about 34 h on 16 cores, over the old 30 h cap that killed the first batch; shorter jobs schedule faster and a kill costs at most one 25-replication chunk.
- Let all 16 jobs run to walltime instead of qdel-ing each at its last completable chunk boundary.
Why: the boundary-kill economy saves roughly 1 to 2 KSU but requires an afternoon of polling; Emilia chose simplicity, accepts a half-study read from this pass, and finishes the remainder on the Q4 grant.
- No further top-up will be requested.
Why: Emilia stated she cannot ask again; the Q4 standing grant covers the remainder.
- Wrote the pilot-pricing lesson as a feedback memory at Emilia's request.
Why: two mispricings in one week (wrong $J$ spec, then flat extrapolation across sparse-dial factors at wrong concurrency); the rule is to measure every factor level at production concurrency and price each level from its own measurement.

### Approaches rejected

- Begin/end email notifications on the 16 jobs (`qalter -m be`): 32 emails of noise; qstat on demand plus chunk-file counts is better.
- Extending walltime of running jobs via qalter: users cannot raise walltime on running Gadi jobs.
- Describing the running pass as a de facto pilot: Emilia rejected the framing as spin; the honest accounting is ~1,000 banked replications against 2-3 KSU of avoidable waste this pass plus 6.7 KSU lost in the first batch.

### Files changed

- [quality_reports/2026-08-21_dr48_supplement_ticket.md](file:///C:/git/ckt/quality_reports/2026-08-21_dr48_supplement_ticket.md): OneHelp ticket text (title, body, 49-word reason field), first person singular, 20 KSU over two quarters.
- [quality_reports/session_logs/2026-08-20_stagew-stage1-in-flight.md](file:///C:/git/ckt/quality_reports/session_logs/2026-08-20_stagew-stage1-in-flight.md): running updates through the relaunch (five commits).
- Memory files [reference_gadi_crlf_push.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_gadi_crlf_push.md) and [feedback_pilot_pricing_nonlinear.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/feedback_pilot_pricing_nonlinear.md), plus MEMORY.md pointers.
- On Gadi: `sims/src/run_setmetric_eval.py`, `sims/src/run_power_eval.py`, `sims/hpc/setmetric_eval.pbs`, `sims/hpc/power_eval.pbs` pushed and LF-normalized in `/scratch/dr48/et5292/ckt-sims-r1`.

### Open items

- Tonight: chunk inventory, per-factor cost measurement, stocktake, October resubmission plan (the "If you resume" block above).
- Partial-read manifest pathway needs building before the half-sample summarize can run.
- Power evaluation remains unscheduled and unpriced at production conditions; price it from tonight's measurements before submitting anything.
- Emilia still needs to delete the two superseded Outlook drafts.
