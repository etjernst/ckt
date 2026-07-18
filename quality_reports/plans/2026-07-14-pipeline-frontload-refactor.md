# Plan: front-load the pipeline, staged with a tiered equivalence gate

Date: 2026-07-14 (revised after fresh-context plan critique; revised again the same evening after the stale-hub discovery, which restructured Stage 0 and re-based the gate baseline).
Spec: [2026-07-14-pipeline-frontload-refactor.md](file:///C:/git/ckt/quality_reports/specs/2026-07-14-pipeline-frontload-refactor.md).
Review: [2026-07-14_pipeline-consistency-audit.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-14_pipeline-consistency-audit.md).

## Principle

Every stage is one logical change, implemented, then verified non-destructively against a frozen baseline before it is committed.
The pipeline stays runnable per-country and per-cell throughout (no collapsing into loops, per the standing convention).
Consistency stages must leave the estimates equivalent to the baseline; correctness and estimand stages change only their named cells.
Citations below are by program name and anchor string, not line numbers, because Stages 1-2 edit `0_programs.do` and shift every downstream line.

## The equivalence gate (tiered, byte-first)

The April 2026 M4 verification already showed that refits reproduce the committed sters bit-for-bit on this machine, so byte-identity is attainable, not aspirational.
The gate is therefore tiered rather than a single pass/fail line.
The baseline the gate compares against is the gate-panel refit produced in Stage 0 on the rebuilt hub, not the current ster population: the current sters predate the 2026-07-13 front-end commits (per-capita outcome and Change A) and are stale relative to committed source.

Tier 1, provenance (exact, always required).
Per cell: `e(N)` and `count if e(sample)` match baseline exactly; the trajectory partition (count of always / never / each switcher trajectory) matches exactly; the `e(sample)` membership is identical.
A provenance mismatch is a real change and stops the stage regardless of coefficients.

Tier 2, byte-identity (the target for stages that do not reorder rows).
Full-precision `%24.16e` dump of `e(b)`/`e(V)` is identical to baseline.
Stages 1 and 2 remove value-identical no-ops without touching row order or executing sorts, so they must be byte-identical.
A Tier 2 red on these stages means stop and diagnose; one benign mechanism exists.
Stata's `sort` is not stable on ties and tie order depends on the sortseed state; batch runs reset that state identically at launch, which is why unchanged code reproduces bit-for-bit, but an edit that changes the number or order of sorts executed before a tied sort can flip tie order without changing any value.
If diagnosis traces a Tier 2 red to tie order alone (provenance exact, coefficients within the Tier 3 criterion), record it and adjudicate that stage at Tier 3; any other cause is a bug.

Tier 3, tolerance adjudication (only when a stage legitimately reorders rows).
Stages 3 and 4 move construction and reorder drops, so `vce(cluster pid)` summation order can flip low-order bits under float non-associativity.
When Tier 2 goes red but Tier 1 passes and every element of `e(b)` and `e(V)` satisfies |new - old| <= max(1e-12, 1e-10 x |old|), the red is a benign reorder: accept and record it in the stage's gate artifact.
The mixed criterion (absolute floor plus relative band) keeps near-zero coefficients from blowing up a relative-only check.
If Tier 1 fails or the criterion is exceeded, stop and surface it.
Every Tier 3 acceptance is re-adjudicated against the full population at the end sweep (see after all stages).

Every stage commits its gate artifact (the provenance table and the diff result) alongside the code, so "why did cell X move" is answerable from history.

## Coverage: the gate panel

Per-stage verification runs a fixed gate panel, not ad hoc cells, chosen to exercise every distinct code path: each estimator type (OLS/FE, main GRC, non-ag GRC, hukou GRC, one extras stem, inversion, Verdier) crossed with all three countries, both balanced and unbalanced, and at least one switcher-sparse cell (a CHN hukou split).
The panel prioritizes fast cells so a stage gate is minutes, not hours.
The full `.ster` population is swept once at the end, when the definitive re-run happens, and compared cell-by-cell against baseline; that end sweep is the exhaustive characterization check, so no stage needs a full refit.

## Stage 0: rebuild the stale hub, then freeze the baseline (no refactor change)

The 2026-07-14 Stage 0 diagnostics restructured this stage: the processed hub at `C:/git/ckt/RP7/data/processed/` was built 2026-06-24 and predates three committed front-end changes, so the hub and every current `.ster` are stale relative to source.
The three commits, each with a checkable on-disk signature:
`47b60e3` builds `lndepvar` per-capita at source, so every consumption and income cell's `lndepvar` moves by exactly `ln(hhsize_cube)`.
`a11e013` (Change A) reflags strict-spec-incomplete individuals as unbalanced: `_bal` cells lose those individuals (lower N), and `_unb` cells keep their rows with changed `unbalanced` and `unbalanced_choice` values.
`1e10113` (C10) reclassifies `non_switcher` by observed movement, which moves values only for unbalanced workers.
Because of Change A, the current GRC sters are correct on scale but fit on pre-Change-A samples, so the current ster population cannot serve as the gate baseline.

Stage 0 therefore runs in this order.

Before the rebuild, three fail-fast checks that need nothing but the current hub (folded in from the 2026-07-14 review adjudication).
Pin the environment in the gate artifact: `version`, Stata flavor and MP core count (mata reduction order depends on it), and the installed package set; confirm once that the mainline pipeline has no randomized step (no bootstrap, simulation, or sampling), so no seed control is needed beyond the sortseed mechanism documented in the gate section.
Run the determinism preflight: double-fit one fast GRC cell on the current hub and byte-compare the two sters; determinism is a property of machine plus code, not of which hub is loaded, so this proves the tiering premise before any rebuild work and refreshes the April M4 evidence.
Self-test the harness before it gates anything: a known-good pair (a ster against itself) must pass all tiers, and a deliberately perturbed pair (one coefficient nudged at the 12th decimal) must fail Tier 2 and trip the Tier 3 criterion when the nudge exceeds it.

First, rebuild the hub to a fresh location, never in place.
Create `RP7/data_rebuild/` with an empty `processed/` and a `countries` junction to the existing raw folder, then run `1_processData.do` unmodified via a small driver that repoints `$dirdata`.
The driver must not run `0_CHN_hukou_restrictions.do`, which writes into the raw `countries/` folder; the derived hukou files it once produced already exist there and are read, not rebuilt.

Second, characterize the old hub against the fresh hub cell by cell.
Every difference must be attributable to exactly one of the three commit signatures above; a difference that matches none stops the stage.
`IDN_unb.dta` doubles as a determinism probe: it was rebuilt through current code on 2026-07-14 at 19:45, so the fresh copy must match it byte for byte.

Third, re-run `3_OLS_uGRC` and `6_OLS_uGRC_hukou` against the fresh hub into a fresh output directory and table the combined per-cell movement (scale fix plus Change A) against the current tables.
This is the number that says how far the paper's OLS consumption tables move; the movement is reported combined, not decomposed, per the author's 2026-07-14 decision.

Fourth, author review of the characterization artifact (the attributed cell-by-cell hub diff and the OLS movement table), not a bare approval, then promote: swap the fresh hub in as canonical and keep the old hub as a backup until the definitive run.

Fifth, freeze the gate baseline on the new hub.
Refit the gate panel with unchanged code and store those sters as the baseline for Stages 1-8.
Double-fit at least two panel cells and byte-compare as the run-to-run determinism proof; if any cell does not reproduce, the pipeline is not deterministic and that must be resolved before trusting the gate.
The panel refit is the only GRC cost pulled forward; the full population re-run stays at the end, because GRC fits are expensive.

Carried Stage 0 deliverables, re-based on the new hub:
the golden-master harness (drafted as `gate_harness.do`, not yet run);
the no-op inventory for every `replace`/global the consistency stages will remove, which is meaningful only against the rebuilt hub (against the stale hub, the GRC load-time replaces were the sole source of the per-capita scale, not no-ops);
the per-cell N-reconciliation baseline recomputed on the new hub.
Environment pinning moved to the fail-fast preflight above (first values recorded 2026-07-14: StataNow 19.5 MP, 4 processors).
The 11b materiality probe already ran on 2026-07-14; its result is recorded under D-3 below.

Until the definitive run at the end, the paper's GRC tables remain pre-Change-A, so nothing ships to coauthors or Overleaf before that run completes.

## Stage 1: single source of truth for the covariate ladder (consistency, Tier 2)

Define `$covs_gmm*` in one place (a `set_covariate_globals` program, country-arg for hukou), and additionally stash the resolved list as a dataset characteristic at build time.
Delete the hand-redeclarations in `4_GrRC.do`/`5_GrRC_NonAg.do`/`7_GrRC_hukou.do` and the parallel locals in `run_grc_with_extra_regressor`, replacing each with the one reference.
No row-order change, so the gate panel must be byte-identical.
Commit with gate artifact.
Status 2026-07-17: implemented, critic-reviewed, and smoke-tested on branch `stage1-covariate-ladder` (commits `6a5bbf9` and `8cbf3d3`); the country-arg was dropped because the hukou drivers use the plain ladder, and the consumer-less hukou ladder globals were deleted outright with author approval.
The Stage 1 refit did not launch alone: per D-5 it gates jointly with Stage 2 in one panel refit.

## Stage 2: de-mutate and rename the outcome, remove income (consistency, Tier 2)

Build the per-capita outcome once in `handle_depvar`, parameterized by `` `depvar' ``, and rename `lndepvar` to `logpc_` followed by the outcome name, giving `logpc_consumption` for consumption cells and `logpc_income` for income cells.
Remove every redundant `replace ... = log(consumption/hhsize_cube)` site (enumerated by the Stage 0 inventory) and the central one in `run_grc_with_extra_regressor`, updating every consumer to the new name.
Per D-2, keep the `_income.dta` builds in `1_processData.do` but remove the income estimation blocks (in `3_OLS_uGRC`/`4_GrRC`/`7_GrRC_hukou` and the `iuu` extras), so income data stay buildable while no income results are produced.
No row-order change, so the gate panel (consumption cells) must be byte-identical; income cells leave the panel with the estimation blocks.
Commit with gate artifact.
Gates jointly with Stage 1 in a single panel refit, per D-5.
Status 2026-07-17: implemented and smoke-tested on branch `stage1-covariate-ladder`.
`handle_depvar` builds `logpc_consumption` / `logpc_income` at source; every consumer is renamed; the income estimation and table blocks are deleted from `3_OLS_uGRC`, `4_GrRC`, `7_GrRC_hukou`, `9_GRC_extras`, `10_make_tables`, and the extras dispatch programs, while the income data builds stay.
The rename also swept five covariate-ladder hand-redeclarations Stage 1's audit had not enumerated (`5b_inversion`, `5c_inversion_hukou`, `10_make_tables`, `17_verdier_robust`, `17b_cluster_summary`), each now a `set_covariate_globals` call.
Because the rename edits `17_verdier_robust.do`, the Verdier leg joins the bundled gate refit (the Stage 6 contract fix is untouched).
The hub was rebuilt with the new front end into `RP7/data_rebuild` and verified cell by cell as a pure rename against the canonical hub (34/34 PASS, artifact at quality_reports/staging/stage2/hub_rename_check.csv); the author promoted it to canonical on 2026-07-17.
Gate closed 2026-07-17: the bundled Stage 1+2 refit (main, nonag, hukou, extras, Verdier, and the ct supplement) ran on the promoted hub and all 250 ster pairs are bitwise identical to the frozen baseline (artifact at quality_reports/staging/stage1/gate_results.csv, commit 83bd3af).
Stages 1 and 2 are complete; the next stage is Stage 3.

## Stage 3: front-load the estimation scaffolding, document the trajectory contract (consistency, Tier 3 allowed)

Move the `always`/`never`/`switcher_*` construction and the `trajectory` sentinel into the front-end build so the processed `.dta` carries them, with a documented value label on the sentinel, and persist the data-driven `$switchers` list as a dataset characteristic the estimator reads back.
Reduce the analysis scripts to `use` + estimate; remove the now-redundant `drop if mi(logpc_consumption)|mi(choice)` re-filters in 5b/5c.
Critic finding MAJOR-4 (2026-07-14 review) lands here; the kickoff reminder was delivered 2026-07-17 and the author FLIPPED the decision to drop-at-source per cell.
Within each cell, rows no estimator can ever use---missing per-capita outcome (missing or non-positive `hhsize_cube`) or missing `choice`---are dropped at build time with counted diagnostics, so the saved dataset is the common estimable sample and summary-stat denominators describe what gets estimated; never any imputation.
The drop conditions ONLY on outcome and choice: approach-specific restrictions (the Verdier programs' `drop if missing(vfirst)`, a missing-in-all-waves cluster index, not a lag-structure loss) stay inside their estimators and remain visible through their own counted diagnostics.
The gate artifact enumerates the rows dropped at source per cell; since those rows were never in any `e(sample)`, Tier 1 provenance must still be exact.
The author's cross-approach variant (one canonical per-country dataset at the smallest sample across approaches) was considered and rejected 2026-07-17: it would collapse the designed balanced/unbalanced and hukou sample distinctions and restrict headline estimates to a robustness check's sample, an estimand change outside this refactor.
Build-time construction may reorder rows, so Tier 3 applies: Tier 1 provenance must be exact; a Tier 2 red is accepted only under the `1e-10` tolerance and recorded.
Stage 3 runs on branch `stage3-frontload-scaffolding`, cut from `main` after `stage1-covariate-ladder` merged (2026-07-17, merge commit 29abc8f).
Per D-5, Stages 3 and 4 bundle their gate into one panel refit (decided 2026-07-17); the bundled gate must show exactly the CRITICAL-1 enumerated diff (and the Stage 3 drop-at-source enumeration) and nothing else, so a red elsewhere bisects between the two stages via the per-cell b/V dumps.
Commit with gate artifact.
Status 2026-07-17: implemented and smoke-tested on branch `stage3-frontload-scaffolding`.
`handle_grc_scaffolding` builds the always/never/switcher_* dummies and their choice interactions at source and stashes the trajectory contract as dataset characteristics (`_dta[grc_switchers]`, `_dta[grc_always]`); `handle_estimable_sample` drops the missing-outcome person-waves as the LAST build step, so per-individual classifications keep the full observed choice history and every surviving value is unchanged; `setup_grc_estimation` becomes a reader that repopulates the globals from the characteristics and exits 459 on a contract-less dataset; the redundant re-filters in 5b/5c are removed.
Deviation from the plan text, chosen for equivalence: the 999 sentinel is NOT written into the saved data; `trajectory` stays missing in the file and the sentinel recode remains a documented load-time step in the reader, so estimation-time state is bitwise today's (the inversion's Python bridge sees the in-memory 999 either way).
Corrected rationale (2026-07-18, after a full call-chain audit): the only live `i.trajectory` consumer is `heterogeneity_plots` (11_make_figures), which runs after `setup_grc_estimation` and therefore sees 999 under either design; `3_OLS_uGRC`/`6_OLS_uGRC_hukou` call only `reghdfe_regressions`, which never touches `trajectory`, and `ugrc_regressions` (the reg7 `i.trajectory` + `i.unbalanced#i.choice` specification that would exclude unbalanced rows via the missing factor) has NO call site anywhere in RP7/scripts---it is dead code and a Stage 8 deletion candidate.
Keeping missing in the file is therefore an honest-encoding choice, not a live-output constraint: any consumer that loads the hub without the reader (scratch drivers, or ugrc_regressions if resurrected) keeps pre-scaffolding semantics.
Unbalanced individuals ARE in every live regression: the OLS/FE tables (no trajectory factor), the heterogeneity regressions (999 level plus the `i.unbalanced#i.choice` lump), and the restricted GRC (unbalanced/unbalanced_choice terms).
Enumerated drops on the current hub (artifact at quality_reports/staging/stage3/estimable_sample_drops.csv): 588 person-waves in IDN_unb and its 2waves/3waves variants, 238 in IDN_unb_nonag, 1015/182/129/119/52/48 across the income cells, zero everywhere else; all dropped rows sit on Change-A unbalanced individuals, so no balanced-trajectory count moves.
Knock-on requiring author sign-off at the end sweep: `gen_vfirst` computes the Verdier cluster index at estimation time, so the drop reassigns `vfirst` for 45 IDN pids (67 person-waves); TZA and CHN have zero dropped rows, the gated TZA Verdier leg is clean, but the IDN Verdier robustness columns will move at the definitive run.
Author decision 2026-07-18: accepted; `vfirst` stays computed at estimation time on the estimable sample (the alternative of freezing today's assignments by building `vfirst` before the drop was declined, since a wave without an estimable outcome should not seed the cluster index).
The 45-pid IDN reassignment is expected movement, to be enumerated at the end sweep.
Smoke artifact: RP7/tests/stage0/smoke_stage3.do, all-PASS (row-by-row dummy equality against the old load-time construction on IDN_unb, exact N transitions 93038-588, 29864-0, 58047-1015, reader and fail-fast verified).
The bundled Stage 3+4 gate runs after Stage 4 lands, on a rebuilt hub.

## Stage 4: split set_covariates, tidy non_switcher and the partition (consistency, Tier 3 allowed)

Separate covariate definition from the sample drops; replace the two hand-enumerated `non_switcher` string lists with a computed rule; collapse the three partition re-implementations to one shared indicator.
Five critic findings from the 2026-07-14 review land here.
CRITICAL-1: recompute `nr_periods_obs`, `obs_per_individual`, and `pid_first_obs` after the `set_covariates` drops (or move the drops ahead of the descriptor construction), then re-apply the singleton drop on the corrected count.
The predicted diff is enumerated in advance from [verify_c1.do](file:///C:/git/ckt/RP7/tests/stage0/verify_c1.do): stale descriptors on 9/4/2 person-waves (CHN/IDN/TZA unb), 2/0/2 rows of pids lacking a first-obs flag, and 0/1/2 surviving singleton rows whose removal will change N in those cells; the Stage 4 gate artifact must show exactly this diff and nothing else, with author sign-off since N moves.
MAJOR-1: add an `isid pid period` assert in `use_data` before any transformation.
MAJOR-2: replace the `r(N_drop)` display strings in `handle_choice`/`handle_depvar` (a return value `drop` never sets) with counted attrition messages.
MAJOR-3: give the three `set_covariates` drops real before/after counts.
MAJOR-7: delete the dead `depvar` argument and its stale comment in `set_covariates`.
Rebuild all processed files and diff variable-by-variable against the Stage 0 processed snapshot; the reordered drops make Tier 3 applicable to the sters.
Provenance (N, partition, `e(sample)`) must be exact except for the CRITICAL-1 singleton rows predicted above; coefficients within tolerance.
Commit with gate artifact.
Status 2026-07-18: implemented and smoke-tested on branch `stage3-frontload-scaffolding`, with one open author decision below.
`handle_sample_drops` (split out of `set_covariates`, which now defines covariates only and loses its dead `depvar` argument per MAJOR-7) applies counted covariate drops, refreshes the per-individual descriptors, and applies the singleton drop on the refreshed observed-wave count; the smoke emulation reproduces the enumerated CRITICAL-1 diff exactly (0/1/2 recomputed-singleton person-waves for CHN/IDN/TZA).
`refresh_descriptors` (factored per the 2026-07-18 critic review) recomputes wave counts and first-obs flags for the base and `_2waves`/`_3waves` descriptor families and runs again at the end of `handle_estimable_sample`; this closes the critic's MAJOR finding that individuals whose chronologically-first wave is dropped would silently vanish from the 2waves/3waves figure panels and summary-stat rows that keep on `pid_first_obs_Xwaves == 1`.
MAJOR-1 (`isid pid period` in `use_data`), MAJOR-2 (counted attrition messages in `handle_choice`/`handle_depvar`), and MAJOR-3 (all drops counted) are in; the two hand-enumerated `non_switcher_2waves`/`_3waves` string lists are replaced by a computed all-same-string rule, verified row-by-row equal to the lists.
No new sorts were introduced: every added bysort uses the unique pid-year key on data already ordered by `handle_trajectory_groups`.
The scaffolding dummies carry variable labels and the contract carries `_dta[grc_never]`, both author-approved 2026-07-18; `setup_grc_estimation` reads the never-code back.
critic-stata scored the diff 84/100 with no CRITICAL; its MAJOR is fixed as above, and its remaining MINORs are recorded (labels would leak into a future `esttab` that omits `coeflabels()`; smoke drivers hardcode the per-user path per project convention).
Smoke artifact: RP7/tests/stage0/smoke_stage4.do, all-PASS (IDN unb N 92,449 = 93,038 minus 1 recomputed singleton minus 588 missing-outcome waves with descriptors exactly true; TZA 2waves N 29,862 with the computed rule equal to the hand lists; IDN 2waves suffixed descriptors true after real drops; CHN raw passes `isid`).
Resolved 2026-07-18 (author): individuals with exactly one estimable wave but a longer observed history are KEPT for now (205 in IDN_unb, 89 in IDN_unb_nonag; CHN and TZA have none), matching today's estimation samples; whether to drop them is deferred to a later deliberate decision (Stage 9 territory).
Hub rebuilt and compared 2026-07-18: all 34 cells PASS the enumerated-delta check (compare_hub_stage34.do; artifact at quality_reports/staging/stage34/hub_stage34_check.csv)---the rebuild differs from the canonical hub by exactly the recomputed-singleton rows, the missing-outcome rows, the corrected descriptors, and the scaffolding variables, nothing else.
The bundled Stage 3+4 gate launched the same evening as two detached batches (gate_stage34.do and gate_stage34_ct.do) on the stage34_root shadow root (scripts junction to the working tree, data junction to RP7/data_rebuild).
Expected adjudication (gate_stage34_compare.do): every ster pair PASS_BITWISE except the cells fit on IDN_unb (grc_IDN_cuu*, e(N) down by exactly 1) and TZA_unb (grc_TZA_cuu* and vv_TZA_*, e(N) down by exactly 2), which the compare reclassifies EXPECTED_N_CHANGE and reports for author sign-off; any other verdict fails the gate.
Gate adjudicated 2026-07-19: all 250 pairs exactly as enumerated---140 PASS_BITWISE (every CHN cell including both hukou splits, IDN nonag, all balanced cells) and 110 EXPECTED_N_CHANGE with the predicted deltas and nothing else (artifact at quality_reports/staging/stage34/gate_results.csv; both batches rc=0, about 8.5 hours wall-clock).
Coefficient movement across the 110 moved pairs (quality_reports/staging/stage34/moved_movement.csv): max relative e(b) change ranges 1.9e-13 to 2.3e-2, mean 1.0e-3; the largest movers are a Verdier TZA twostep trend subgroup (2.3%) and the IDN extras c3 per-trajectory Deltas (2.0%), consistent with removing 1-2 person-waves from those fits.
AWAITING AUTHOR SIGN-OFF on the N-changing cells (plan requirement since N moves); after sign-off: promote RP7/data_rebuild to canonical (author runs or approves the renames, per the data-safety protocol), remove the data_rebuild junction with cmd rmdir only, and close Stages 3+4 in the plan and session log.

## Stage 5: inversion CIs key off e(sample) (correctness, contract not exercised today)

Change `attach_inversion_ci` (5b/5c) to compute on the fitted ster's `e(sample)` rather than a reconstruction.
This establishes a contract that is not currently exercised (zero missingness in the present covariates), so the CIs should match baseline today; a future data refresh with missingness would move them, which is the point.
Document the invariant.
Verify: refit the inversion panel cells; Tier 1 exact, Tier 2 expected; if any CI moves the reconstruction was already diverging, so stop and surface.
Byte-identity alone cannot distinguish the new code from the old here, so the stage also commits a synthetic contract test: a scratch dataset with injected missingness, where the reconstruction and `e(sample)` disagree by construction, asserting the CI computes on `e(sample)`.
Author sign-off, then commit.

## Stage 6: clean up run_grc_robust_vv (correctness, contract not exercised today)

Make the Verdier loop start each spec from the same baseline sample (preserve/restore or a scoped working copy), so the internal `drop if missing(vfirst)` no longer persists across specs.
Same contract framing as Stage 5: expected byte-identical today, corrected for the general case.
Verify: refit the Verdier panel cells for all three countries; if any move, the persistence was affecting results and that is a finding, not something to absorb.
Same contract-test obligation as Stage 5: a synthetic spec sequence on scratch data, where the old code's persisted `drop if missing(vfirst)` would shrink later specs, asserting each spec starts from the full baseline sample.
REQUIRED FIX, found 2026-07-16 during the baseline sweep: the tail of `17_verdier_robust.do` loads sters under the pre-rename suffixes (`_never`, `_avg`) while fits save `_n`/`_a`, so the load fails silently and `grc_tex_table_trend_robust` skip-and-warns, meaning NO run since the suffix rename can regenerate the paper's Verdier robustness tables (the production `verdier_robust_*.tex` are frozen 2026-05-06 artifacts, two months older than their sters).
Fix the two suffixes, regenerate the tables, and diff against the May versions; without this fix the definitive run silently ships stale VV tables.
Author sign-off, then commit.

## Stage 7: fix the 11b figure scale (correctness, figure changes)

Rebuild `11b_extrapolation_support_figure.do`'s mu quantities on the per-capita outcome, or read them from the ster (matching `_export_e1_inputs.do`).
The materiality was already probed at Stage 0; this stage ships the fix and the corrected figure.
Author sign-off (a numeric change is expected), then commit.

## Stage 8: config hygiene (no estimate change)

Move the derived `CHN_hukou_*.dta` out of `data/countries/` (raw) into `data/processed/` and repoint the readers (critic MAJOR-6, confirmed; the intermediates were verified cf-identical to a fresh regeneration on 2026-07-14, so the move is pure relocation).
Warning recorded from the critic adjudication: any driver that regenerates the hukou files must not do so through a `countries` junction into the raw folder.
The named master log (critic MAJOR-5) is now required, not optional, per the author's 2026-07-14 decision: a timestamped, named, text-format log covering the data-construction path, following the AEA pattern in the project conventions.
Script-folder taxonomy (user preference, 2026-07-14, to settle by discussion first): the leading underscore is currently overloaded, marking both throwaway dev scratch (`_smoke_*`, `_probe_*`, `_refit_*`, `test_*`) and load-bearing include-only helpers (`_export_e1_inputs.do`, `_export_e1_inputs_hukou.do`, included by `12_counterfactuals.do`).
Proposed convention: a `scripts/helpers/` subdirectory for include-only helpers and a `tests/` or `dev/` subdirectory for the scratch, so the pipeline folder shows only numbered pipeline scripts plus clearly-marked entry points.
Optionally add the hukou eststo-naming fix, the learning edge-case flag, and the 1b cross-check assertion.
Verify: full clean run of the cleaning path; confirm every processed file regenerates and the hukou readers resolve.
Commit.

## Stage 9: Change B, switcher-inclusion consistency (estimand change, human-approved)

Author the switcher keep-list once at the front end, persist it, and have every estimator read it.
This intentionally changes the estimand, per the switcher-inclusion spec [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) and its plan [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md).
Verify against that spec's acceptance criteria, not the equivalence gate.
Author approval, then commit.

## After all stages

Run the full pipeline once (serial or via the parallel launcher, the next project) on final code.
This single run is deliberately the latest possible point for the full GRC refit, per the author's 2026-07-14 decision, and it does three jobs at once: it is the definitive Change A plus per-capita update of the full `.ster` population, the source of the final paper tables, and the exhaustive end characterization sweep.
Compare the full population cell-by-cell against the pre-rebuild sters to characterize the movement (expected: scale plus Change A in OLS cells, Change A alone in GRC cells), and hold the gate-panel cells to the Stage 0 baseline within the tiers.
Re-adjudicate every Tier 3 acceptance recorded during the stages against the full population; any cell exceeding the mixed criterion reopens the stage that accepted it.
Promote the fresh output to canonical and copy `RP7/{scripts,output}/` to Dropbox as the replication handoff.

## Decisions

D-5 (resolved 2026-07-17).
Consistency stages bundle their gate refits to cut the number of panel runs, after the author flagged the per-stage refit cost.
Stages 1 and 2 share one panel refit (both are Tier 2 byte-identity stages touching largely the same files); Stages 3 and 4 likewise bundle (author decision 2026-07-17), with the CRITICAL-1 N-diff carved out as the only accepted provenance change.
Accepted cost: a red on a bundled gate bisects between two stages' changes, which the per-cell b/V dumps localize.
The full-population run stays a single definitive run at the end; the ct supplement (time-FE-only fits) runs in the bundled gate because Stage 2 changes the outcome path those fits consume, even though Stage 1 alone would not need it.

D-4 (OPEN, raised 2026-07-15). The manuscript promises the sectoral (nonag) analysis in prose ("we repeat our analysis for sectoral choice in Indonesia", main-updated.tex line ~574) but inputs no nonag table anywhere; an earlier "documented in the Appendix" sentence is commented out.
Either drop nonag from the paper (trim the promise, remove nonag from the gate panel and the definitive run) or restore a nonag appendix table at the definitive run; the author leans low-priority on nonag (2026-07-15) but has not decided.

## Decisions resolved 2026-07-14

D-1. C2, the IDN cnu x urbanbirth cell: align it to the nonag definition; this changes one extras number.
D-2. Income: keep building the income processed data but do not run income results, and cut income from the paper text (easy to restore if a referee asks); the outcome name is parameterized as `logpc_` plus the outcome so income cells stay honestly named.
D-3. 11b materiality: the Stage 0 probe shows TZA's never-migrant target moves from inside the switcher support on the raw scale to below it on the per-capita scale (a gap of about 0.055 log points), while IDN and CHN stay inside on both scales; the fix is claim-affecting for TZA and cosmetic for IDN and CHN.

## Review and human gates

Each consistency stage: fixer applies, the harness confirms the tier result, `critic-stata` on the touched programs, then commit with the gate artifact.
Correctness and estimand stages (5, 6, 7, 9) and decisions D-1/D-2/D-3 require author sign-off before commit, since they can change reported numbers or a treatment definition.
Maximum five review-fix rounds per stage; unresolved issues stop the stage and surface.

## Rollback

Each stage is a branch, per the standing git convention; a mid-stage hard-stop reverts the branch and the pipeline stays on the last gated commit.
Un-promoting the hub means repointing back to the retained backup, which is kept until the definitive run completes.

## Appendix: gate panel and operator pointers

The gate panel below is the concrete cell list; runtimes are measured at the determinism preflight, and a slow cell may be swapped for a faster cell on the same code path with author approval.
OLS/FE: `3_OLS_uGRC` consumption for CHN, IDN, TZA, unbalanced and balanced.
Main GRC: `4_GrRC` consumption unbalanced for CHN, IDN, TZA, plus one balanced cell (TZA_bal, the smallest).
Non-ag GRC: `5_GrRC_NonAg` IDN unbalanced (the only nonag family).
Hukou GRC: `7_GrRC_hukou` CHN rural-first unbalanced, plus CHN urban-first unbalanced as the designated switcher-sparse cell.
Extras: one `run_grc_with_extra_regressor` stem (experience) on its usual cell.
Inversion: `5b_inversion` on the main GRC panel cells.
Verdier: `17_verdier_robust` on TZA per gate run (the fastest country), all three countries at the end sweep.
Operator pointers: the `$dirdata`-repointing rebuild driver and `gate_harness.do` live in `RP7/tests/stage0/`; the Stage 1 and 2 edit-site anchors are enumerated in the Stage 0 no-op inventory ([noop_lndepvar.csv](file:///C:/git/ckt/quality_reports/staging/stage0/noop_lndepvar.csv) and successors), which this appendix references rather than duplicates.
