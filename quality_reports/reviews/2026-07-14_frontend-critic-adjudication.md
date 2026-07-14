# Adjudication of the critic-stata pre-promotion review

Review adjudicated: [2026-07-14_pipeline-frontend-critic-stata.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-frontend-critic-stata.md) (3 CRITICAL, 7 MAJOR, 5 MINOR, verdict "do not promote").
Adjudicator: session model, 2026-07-14 late evening, with both CRITICAL factual claims verified empirically before adjudicating.
Verification drivers: [verify_c1.do](file:///C:/git/ckt/RP7/tests/stage0/verify_c1.do), [regen_hukou.do](file:///C:/git/ckt/RP7/tests/stage0/regen_hukou.do).

## The frame the verdict misses

The critic reviewed the pipeline absolutely, and its findings about the pipeline are largely right.
But the promotion decision is not "is this pipeline clean"; it is "old hub vs new hub," and every verified defect below is present identically in both, because the two hubs differ only by the three characterized commits.
Refusing promotion keeps a hub with the same descriptor staleness plus a wrong outcome scale.
The new hub strictly dominates, so the findings gate the refactor stages, not the promotion.

## CRITICAL-1, stale sample descriptors: VERIFIED, real, tiny, shared by both hubs

Verified on the rebuilt hub: stale `obs_per_individual`/`nr_periods_obs` on 9 person-waves (CHN_unb), 4 (IDN_unb), 2 (TZA_unb); pids with no `pid_first_obs==1` row: 2 (CHN), 0 (IDN), 2 (TZA); surviving singleton rows the pre-drop count missed: 0 (CHN), 1 (IDN), 2 (TZA).
The traced pid 620123103 shows the signature exactly: descriptors say 4 waves, the file holds 3 rows.
Both failure modes the critic named are real; the magnitudes are single-digit person-waves against samples of 30,000 to 110,000, with no plausible effect on any reported estimate (reghdfe drops singletons itself; the first-obs flag feeds summary-stat denominators at most).
The old hub carries the identical staleness (the characterization showed these variables identical old-vs-new), so this cannot distinguish the hubs.
Disposition: accepted as a mandatory, named item in Stage 4 (which already restructures `set_covariates` to separate covariate definition from sample drops).
The fix will change these enumerated rows' saved descriptors, so Stage 4's gate artifact must predict exactly this diff in advance and get author sign-off; fixing it now, mid-Stage 0, would change data content outside any gate and invalidate the characterization just completed.

## CRITICAL-2, rebuild driver skips the hukou prerequisite: substance CLOSED empirically, process gap stands

The concern was that 12 of 34 cells were built from hukou intermediate files of uncontrolled vintage.
Resolved by regeneration: `0_CHN_hukou_restrictions.do` at current source, run into a scratch data root, reproduces all four `CHN_hukou_*.dta` files `cf _all`-identical to the canonical copies.
The intermediates are exactly what the current script produces, so the rebuilt hukou cells are genuinely from-source.
The process gap (undocumented ordering dependency, derived files living in the raw folder) is MAJOR-6's territory and is already Stage 8 in the plan.
One safety correction to the critic's proposed fix: adding the restriction script to `rebuild_hub.do` as suggested would have it write through the `data_rebuild/countries` junction INTO the real raw folder, a data-safety violation; the right sequencing is to fix it only after Stage 8 moves the hukou outputs to `processed/`.
Disposition: no promotion blocker; Stage 8 item confirmed, with the junction-write hazard documented.

## CRITICAL-3, hardcoded path in rebuild_hub.do: accepted, trivial, not promotion-relevant

True per the letter of the rubric.
The file is single-session Stage 0 tooling, but the fix (a `c(username)` guard mirroring `0_master.do`) is one edit and worth doing together with a junction-existence precondition check (the critic's last MINOR).
Disposition: fix in the driver on approval; no bearing on the data content.

## The seven MAJORs, mapped to the plan

MAJOR-1 (no `isid pid period`): accepted; add the assert in `use_data` at Stage 4.
MAJOR-2 (`r(N_drop)` never set by `drop`): accepted; the critic is right that the printed attrition counts are garbage; display-only, no data effect; fix at Stage 4 alongside MAJOR-3.
MAJOR-3 (silent `set_covariates` drops): accepted; Stage 4, same edit as CRITICAL-1.
MAJOR-4 (missing `lndepvar` can ride into saved rows): accepted and already quantified (the 793 IDN person-waves in the OLS movement memo); the drop-or-keep decision is an author call scheduled with Stage 3, where the redundant re-filters are already being consolidated.
MAJOR-5 (no named log in the data-construction path): accepted; the named master log is already a Stage 8 optional item, now promoted to required.
MAJOR-6 (derived hukou files in the raw folder): already Stage 8; confirmed.
MAJOR-7 (dead `depvar` arg and stale comment in `set_covariates`): accepted; Stage 4 tidy.

## Author decisions (2026-07-14, after this adjudication)

Promotion: approved and executed; the rebuilt hub is canonical, the stale hub retained at `RP7/data/processed_stale_2026-07-14/`.
CRITICAL-3 and the junction-precondition MINOR (the `rebuild_hub.do` hygiene fixes): declined; the author does not plan future hub rebuilds and wants any parallelization built more cleanly than this driver, so it stays as-is with the findings on record.
MAJOR-4: resolved; rows with missing household size keep a missing per-capita outcome (no drop, no imputation), folded into Stage 3 with a diagnostic.
MAJOR-5: the named master log is required, folded into Stage 8.
The remaining stage mapping (CRITICAL-1 and MAJOR-1/2/3/7 into Stage 4; MAJOR-6 into Stage 8) approved and written into the plan.

## Recommendation

Promote the rebuilt hub.
Every finding that survives verification is either shared identically by both hubs (CRITICAL-1, all MAJORs) or about tooling rather than data (CRITICAL-3), while the rebuilt hub corrects the outcome scale and carries the two committed sample fixes.
Alongside promotion: apply the two trivial driver-hygiene fixes (CRITICAL-3 plus the junction precondition), and freeze the critic's remaining findings into their named stages (CRITICAL-1, MAJOR-1/2/3/7 into Stage 4; MAJOR-4 into Stage 3; MAJOR-5/6 into Stage 8) so nothing is lost.
The author reviews this adjudication together with the characterization memo and the OLS movement memo as the promotion package.
