# Session log 2026-07-22: definitive run status and 5b deferral

## If you resume

- Read this file fully, then the plan [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/plans/2026-07-22-wcr11-inversion-port.md), the spec [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/specs/2026-07-22-wcr11-inversion-port.md), and the review [2026-07-22-wcr11-inversion-port-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-22-wcr11-inversion-port-review.md).
- Open thread: start Stage 0 of the WCR11 inversion port, author-approved, with the plan carrying eleven applied review revisions and five approval-checklist items, of which item 5, the covs_0 skip, is already ratified.
- Stage 0 concretely: cut branch wcr11-inversion-port and develop in a git worktree, never a main-tree checkout, since the live master still re-reads `10_make_tables`, figures, and Verdier scripts from disk.
  Before any worktree operation, check every junction target per the 2026-06-23 data-loss protocol.
  Retrieve `wcr_bootstrap.py` and `wcr_oracle.py` from worktree-extension-sims via git show into `explorations/python-grc/`, the algorithm note beside them, and the IDN-anchor rows of `wcr_size.csv` into `quality_reports/staging/wcr11/`.
  Read the note end to end before wiring anything.
- Definitive run state: launched 2026-07-21 22:33, still running at wrap-up (2026-07-22 19:35), about 21 hours in, and healthy.
  Error count sits at exactly 1, the known 5b fossil abort, fully diagnosed and remedied by fossil deletion; its re-run stays deferred until this WCR port lands.
  Check [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt) (present means Stata exited) and tail [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log) before doing anything that touches RP7.
- Standing constraints: no CI regeneration happens until the sentinel appears and the WCR port passes its parity gates and pilot pricing gate.
  At that point the author sees timing, seed sensitivity, and B=999 endpoint movement, then picks the production B.
  Main-line inversion CIs stay deliberately absent from all 12 mainline cells, and delta-inversion CIs get scrubbed by the port, an author-approved step still pending at its own stage.
  Nothing ships to Overleaf without author review.
  The hukou sters do carry chi-squared CIs from this run's 5c, and the port's scrub handles those too.
- Cached state: the working tree is clean at commit `776ea83` aside from the pre-existing untracked files already listed in git status.
  Backups `output_prestage9_2026-07-21` and `processed_prestage9_2026-07-21` still stand, and the c0 fossils remain deleted from `RP7/output`.

---

## Context

Continuation of the definitive run tracked in [2026-07-21_stage9-switcher-inclusion.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-21_stage9-switcher-inclusion.md).
That log covers the 22:11 launch, its crash on an all-thin keep-list income cell, the author's decision to drop income entirely, the keep-list hardening fix (commit `b08d369`), the 22:33 relaunch (PID 28684), the README draft (commit `fbc8e2b`), and the README verification fixes (commit `55f6fca`).
This log covers only what happened today, 2026-07-22, while that run kept going in the background.

## Morning status check

About 11 hours into the run, Stata was alive, scripts 1 through 8 had completed, and the batch was deep into `9_GRC_extras.do`, the long pole of the pipeline.
At that point there were 370 fresh `.ster` files and 84 extras-family `.ster` files, with the birth-cohort family not yet started.
By 13:12 the run was still inside the extras family, on the IDN cub-experience cell.

## The 5b_inversion.do overnight casualty

`5b_inversion.do` aborted on its first cell overnight and attached inversion confidence intervals to zero of the 12 main-line cells (IDN, CHN, TZA times ct, c1, c2, ca).
The mechanism, confirmed by a direct read of [5b_inversion.do](file:///C:/git/ckt/RP7/scripts/5b_inversion.do) lines 115-145 and the master log, is a chain of three individually reasonable design choices interacting badly.
First, the loop's spec list still includes `covs_0`, the no-covariate column decommissioned on 2026-07-01, and its skip logic is keyed on file existence: a `capture confirm file` that skips the cell only when no parent `.ster` is present.
Second, a stale `grc_IDN_cuu_c0.ster` fossil from a months-old run was still sitting in `RP7/output`, because the run writes in place rather than into a fresh directory.
Third, the fossil passed the existence check, carried no `_esample` marker (only fresh fits write one), and the reconstruction fallback found 92,449 rows against the fossil's `e(N)=92,450`.
That one-row gap is the Stage 4 recomputed-singleton drop, so the row-count check worked exactly as designed and correctly flagged a mismatch.
`attach_inversion_ci` hard-stopped with `r(460)`, and because that attach call is deliberately uncaptured, on the loud-failure convention used for real cells, the error escaped the loop and killed the rest of `5b`.
The master script's script-level capture logged the failure and moved on, so every stage after `5b` in the running batch is unaffected and healthy.
The GMM fits themselves are untouched by this: `5b` only attaches confidence intervals to already-fit results, so it is decoupled by design and re-runnable in minutes once its inputs are right.

`5c_inversion_hukou.do` was clean by contrast.
Its `covs_0` fossils do not exist, so the same existence-keyed SKIP branch fired correctly, and all rf/uf cells attached 4 of 4 sters.

## Decisions, with the why

Delete the `covs_0` fossil sters rather than guard `5b`'s loop: the fossils are relics nothing regenerates or reads, since `10_make_tables` uses only `ct`, `c1`, `c2`, `ca`, deletion restores the existing skip logic to correctness, and the backup `output_prestage9_2026-07-21` preserves the deleted files.
Done: ten `grc_*_c0*.ster` files removed from `RP7/output`; the `vv_` `covs_0` family was never present, and `17_verdier_robust` refits that family from scratch anyway, so there was nothing to clean there.
Defer the `5b` re-run rather than patch and re-run now: the simulation branch (`worktree-extension-sims`) has shown the inversion CI computation needs adjustment, so re-attaching current-method CIs now would be double work.
Accepted consequence: the tables `10_make_tables` builds in this run will lack main-line inversion CIs, and will need regenerating once the eventual `5b` re-run is done.
No pipeline-script edits while the run is live: the `0_master.do` "44 stems" comment and the `9_GRC_extras.do` header are known-stale but parked, because editing a file a running batch may still read risks corrupting the definitive run.
The one code edit made mid-run was `run_master_resume.do`'s active `$dir` line, repointed from the stale grc-pipeline-refactor worktree to `C:/git/ckt/RP7`: the running batch never reads that file, and a crash-resume is exactly the moment the stale path would bite.
Root-cause framing recorded for the `5b` failure, for the post-run cleanup pass: three individually sensible choices combined into a bad interaction (existence-keyed skip, a deliberately uncaptured attach call, and an in-place output directory that can carry fossils across runs).
Two hardening candidates are parked for after the run: trim `covs_0` from `5b`'s spec list, and start definitive runs against a clean output directory.

## Rejected approaches

Re-running `5b` concurrently with the still-live master, on the grounds that the two touch disjoint files: proposed as safe, but mooted once the author decided to defer the `5b` re-run entirely until the sims-branch CI adjustment lands.

## Open items

The definitive run is in flight; after `9_GRC_extras` finishes, the remaining stages are `10_make_tables`, `11_make_figures`, `17_verdier_robust`, `17b_cluster_summary`, and the `11b` support figure.
Monitor [0_master.log](file:///C:/git/ckt/RP7/scripts/0_master.log) and the sentinel [definitive_run_rc.txt](file:///C:/git/ckt/RP7/tests/definitive_run_rc.txt), written by `RP7/tests/run_definitive.cmd` when Stata exits; no completion notification fires on its own.
The `5b` re-run stays deferred until the simulation-branch inversion-CI adjustment is built; because the fossils are gone, `covs_0` will SKIP cleanly next time, and once the re-run happens, `10_make_tables` (and `11_make_figures` if it depends on CI values) need to regenerate so the tables carry confidence intervals.
The post-run sequence is otherwise unchanged from the prior plan: a master-log sanity sweep, the Python keep-list agreement smoke ([run_all_countries_inversion.py](file:///C:/git/ckt/explorations/python-grc/run_all_countries_inversion.py)), `12_counterfactuals` with baseline-drift adjudication, a movement summary for the author, and a purge of remaining stale artifacts in `RP7/output` (income-era sters and tables nothing regenerates), before the author-gated Overleaf and Dropbox shipping steps.
Post-run code cleanups parked in the README verify report ([2026-07-21_2310_readme.md](file:///C:/git/ckt/quality_reports/verify-snippet/2026-07-21_2310_readme.md)): the `0_master.do` line 131 comment (44 to 31 stems), the `9_GRC_extras.do` header (44 stems, 220 sters), per-script version-17 declarations pending an author decision, the per-user `$dir` block collapse before the ReplicationPackage7 handoff, `$runDashboard`'s external-path dependency, `lca_inversion_ci.ado` as a deletion candidate, and the `5b` `covs_0` spec-list trim.
README FILL-IN placeholders still await the author: data rights, storage and hardware, the table-to-manuscript mapping, and the shipped Python module location, plus an optional CFPS codebook confirmation that `hukou==1` means rural.
D-4 (the nonag manuscript promise) and the `main-updated.tex` "lack complete trajectories" footnote remain open, unchanged from the prior log.
The simulation rebuild and P2 parity certification remain a follow-on after this run completes.

## 2026-07-22 evening continuation: WCR11 port spec, plan, review, and revisions

### Goal

On worktree-extension-sims, a Monte Carlo study had shown that the chi-squared reference distribution used for the phi inversion over-rejects badly.
At the IDN anchor, J=26, size sits at 0.264 against a nominal 0.05; the wild-cluster-bootstrap correction (WCR11) restores size to 0.048.
This evening's work delivered a MUST/SHOULD/MAY spec to wire that WCR11 correction into the real-data pipeline, replacing the chi-squared reference wherever the phi inversion runs.
The session followed Mode 2 in full: spec saved and approved, plan written, plan stress-tested by review, revisions applied.
Implementation, Stage 0, was deliberately deferred to a fresh session at the author's request.

### Artifacts

All three documents are committed.

- Spec: [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/specs/2026-07-22-wcr11-inversion-port.md).
- Plan, revised same day: [2026-07-22-wcr11-inversion-port.md](file:///C:/git/ckt/quality_reports/plans/2026-07-22-wcr11-inversion-port.md).
- Plan review, a solo /review-plan run by an econometrics-methodology specialist in fresh context with repo read access: [2026-07-22-wcr11-inversion-port-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-22-wcr11-inversion-port-review.md).

Commit `776ea83` carries all three.

### Preconditions verified before planning

The four reference artifacts are retrievable from worktree-extension-sims via git show: the `wcr_bootstrap.py` kernel, `wcr_oracle.py`, the algorithm note, and `wcr_size.csv`.
The pipeline imports the production [lca_inversion.py](file:///C:/git/ckt/explorations/python-grc/lca_inversion.py) through a sys.path insert in [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do).
Main's `attach_inversion_for_stata` signature is current, so the worktree copy is the laggard and needs no reconciliation.
Development edits are safe while the definitive master run is live, since none of the touched files gets re-read by the running session.
Regeneration still waits for the rc sentinel regardless.

### Review outcome

The plan review returned REVISE, with one Red, seven Yellow, and five Green findings.
All eleven enumerated revisions were applied to the plan, which was then re-committed.

The Red: the plan's original mixed-table mechanism, "stop writing delta CI scalars," fails against the code twice.
Stale chi-squared delta CI macros survive the attach re-save on the hukou sters the definitive run already attached (5c, 4 of 4).
`grc_tex_table_trend`'s invci block also hardcodes the delta CI rows, in a file the plan had not touched.
So the spec's forbidden table, corrected phi beside uncorrected delta CIs, was the default outcome.

The fix now in the plan has four parts.
Attach actively scrubs the inv_dN/inv_davg/inv_dT scalar and macro families on every re-save.
A new Stage 3b edits the invci block to drop the delta rows and keep the phi row.
Stage 6 verifies that no delta macro survives on any reported ster and no delta row survives in any rebuilt table.
A new `e(inv_method)="wcr11"` tag rekeys the 5b/5c skip guards, since the old guard keyed on `e(inv_phi_ci95_lo)`, a field chi-squared-era sters also satisfy.

Other notable revisions:

- The chi-squared site inventory was corrected from three sites to five, rescoped by function name.
  `grid_lca_inversion` is the sole port target; `grid_md_inversion` stays chi-squared off the attach path.
  The original three-site claim traced to a truncated grep, now recorded as a correction in the plan.
- Strict p*>alpha now threads through `find_islands`, with a boundary-tie test added, because the >= convention differs from > exactly at the 20/400=0.05 lattice point.
- Stage 0 development moves to a git worktree, because a branch checkout would swap out scripts the live master still re-reads (10_make_tables, figures, Verdier).
- Gate B states its comparison rule explicitly: same-seed exact, else sqrt(2) times MCSE, about 0.014.
- The plan now names a contingency if the build_aux_design byte-identity assert fires.
- The Stage 5 pilot gains a second-seed rerun and a B=999 arm.
  Endpoint movement gets reported in grid steps, so the author picks production B on evidence, not a guess.
- A chi-squared fixture regression test was added.

### Author decisions this block

The author ratified the covs_0 skip: "yeah no c0 spec."
The spec's every-specification MUST is satisfied by the four estimated specifications, since c0 was decommissioned 2026-07-01.
This is recorded as approval checklist item 5 in the plan.

The author's puzzle about c0 columns still visible in the paper resolved by direct file comparison.
The Overleaf GRC tables are frozen at May 13, five columns, with c0 values Delta_never=0.304 and phi=-2.446, N=92,450, pre-refactor.
The locally regenerated July 10 table has four columns and no c0.
Nothing has shipped to Overleaf since May by design, and the definitive-run tables will supersede the freeze once the author approves the post-run copy.

The author approved the plan in substance, with all eleven revisions applied at "yes please," and directed that Stage 0 implementation start in a fresh session.

### Stata run status at wrap-up (19:35)

Still running, about 21 hours in.
Error count remains exactly 1, the known and fully diagnosed 5b fossil abort.
438 fresh extras-family sters have written so far, currently on the fourth of five extras families, IDN max-experience-share.
Remaining after extras: `10_make_tables`, `11_make_figures`, `17_verdier_robust` (30 GMM fits), `17b_cluster_summary`, and the `11b` support figure.
Completion is estimated overnight or tomorrow morning.
