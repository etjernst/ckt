# Pipeline consistency audit: data cleaning, variable construction, and shared programs

Date: 2026-07-14.
Reviewers: five independent readers (two-look coverage of every analysis script, plus one global cross-check) and the orchestrator's direct reads of the front end.
Scope: `RP7/scripts/` cleaning and assembly pipeline plus `0_programs.do`, ahead of the definitive re-run.
Goal of the review: find every site where an analysis script re-derives, transforms, or overwrites a variable the front end already built, or re-imposes a sample filter, since that is the class of bug that produced last session's GRC-vs-OLS per-capita inconsistency.

## The one architectural fact that drives everything

The front-end constructor is the program `data_setup` (and its `_2waves`/`_3waves` variants) in `0_programs.do`, not a standalone cleaning script.
`1_processData.do` is the sole caller: it runs `data_setup` once per $(\text{country} \times \text{choice} \times \text{depvar} \times \text{balance})$ cell and saves each fully-built dataset to `$dirdata/processed/`.
So the "build once, load downstream" design already exists on disk for 34 cells.

The seam is that analysis scripts do not trust the saved files.
Some `use` the processed `.dta` and then re-mutate on top of it; the OLS scripts even mix two provenance paths, calling `data_setup` live in some sections and loading the cached file in others.
Every consistency bug below is a symptom of that one seam: construction is duplicated between the front end and the consumers, so the two can silently disagree.

## Severity tiers

I separate genuine value or sample divergences (a number could be wrong) from latent redundancy (a no-op today that is one copy-paste away from being wrong).
Corroboration column records how many of the six readers independently flagged the site; single-reader claims I verified by direct read are marked (verified).

### Critical: a reported quantity is on the wrong scale

C1. `11b_extrapolation_support_figure.do:48-62` builds the never-migrant extrapolation-target line $\mu_{\underline{d}_N}$ from raw `ln(consumption)`, not the per-capita `log(consumption/hhsize_cube)` the GRC actually estimates.
The comment at lines 46-47 asserts the paper's $\mu_{\underline{d}}$ is mean log consumption; the estimator's $\mu_{\underline{d}}$ is per capita, so the figure contextualizes the estimate on a different footing than the estimate itself.
It never reconciles against the ster's `mu_never`, unlike the sibling `_export_e1_inputs.do`, which computes the same raw quantity but names it `mu_d_raw_hh` and cross-checks it against the ster.
Corroborated by two readers; verified by direct read.
Materiality (whether the corrected scale moves the in-support conclusion) needs a numeric check, not just the code fix.

### Critical-adjacent, needs a human econometrics decision

C2. The IDN $\text{cnu} \times \text{urbanbirth}$ cell (`9_GRC_extras.do:120-121`, `run_extras_birth.do:58-59`) overrides the nonag dataset with `IDN_unb.dta`, which was built with `choice = urban`.
So a cell labeled `cnu` and saved as `grc_IDN_cnu_birth_*` estimates the urban treatment, not the non-agricultural one its label implies.
The override is explicit and commented as faithful replication of historical file-15 behavior, so it is a known choice, not a silent bug.
This is a judgment call for the authors: keep it (and footnote it in the replication notes) or align it to the `cnu` definition.
Verified by direct read.

### Major: latent divergence, no-op today but fragile

M1. Triplicated covariate ladder.
`$covs_gmm`/`$covs_gmm2`/`$covs_gmm_all` are defined in `set_covariates` (`0_programs.do:608-612`), hand-redeclared in `4_GrRC.do`, `5_GrRC_NonAg.do`, and `7_GrRC_hukou.do` at 15-plus sites, and hardcoded a third time as bare locals in `run_grc_with_extra_regressor` (`0_programs.do:2413-2416`).
Three independent sources of truth; a change to the front-end covariate set would silently fail to reach the other two.
Corroborated by two readers; verified by direct read.

M2. The redundant per-capita `replace`, hardcoding the literal outcome.
`replace lndepvar = log(consumption/hhsize_cube)` appears 25 times across `4_GrRC.do` (6), `7_GrRC_hukou.do` (8), `8_learning.do` (2), `10_make_tables.do` (3), `5_GrRC_NonAg.do`, `5b_inversion.do`, `5c_inversion_hukou.do`, `17_verdier_robust.do`, `17b_cluster_summary.do`.
Every instance recomputes the exact formula `handle_depvar` already applied, so all are no-ops today.
The trap is that they hardcode the string `consumption` rather than the block's own `` `depvar' `` local, so a copy-paste into an income or nonag block would silently swap the outcome with no error.
The safe pattern already exists at `0_programs.do:2384` (`log(`depvar'/hhsize_cube)`).
Corroborated by all five readers.

M3. The inversion CIs run on a reconstructed sample, not `e(sample)`.
`attach_inversion_ci` (5b/5c, via `lca_inversion.py`) rebuilds the estimation sample from `keep $keepvars` + `drop if mi(lndepvar)|mi(choice)` + a Python per-spec `dropna`, rather than reading the fitted ster's `e(sample)`.
It agrees with the GMM fit today only because `female`, `age2`, and `education_max2` have zero missingness; any covariate with missingness would compute the CI on a different $N$ than the fit it attaches to.
Single reader; the mechanism is concrete and the user has confirmed this should be fixed to key off `e(sample)`.

M4. `run_grc_robust_vv`'s persisting sample drop.
The program's internal `drop if missing(vfirst)` (`0_programs.do:3018-3028`) shrinks the sample below the canonical GRC unbalanced baseline and, per its own comment, persists across the five-spec covariate loop within one `use`.
So each successive spec in the Verdier loop starts from an already-trimmed dataset, and the Verdier tables are not sample-comparable to the mainline `grc_*` tables.
The user has flagged this for cleanup.
Single reader; verified against the program comment.

M5. The `trajectory = 999` sentinel recode is an undocumented on-disk contract.
`setup_grc_estimation` (`0_programs.do:1519`) does `replace trajectory = 999 if trajectory == .` in memory after each `use`, then builds `always`/`never`/`switcher_*` off the recoded variable.
Nothing in the saved `.dta` records that 999 means "unbalanced, no balanced-panel trajectory," so a script that reads `trajectory` straight off disk (`11_make_figures.do`, `1b_unbalanced_rank_diagnostic.do`) sees `.` where the GMM path sees 999.
Applied uniformly, so not a divergence today, but two branches of the audit trail can legitimately disagree about what a trajectory code means.
Corroborated by four readers.

M6. OLS scripts mix live and cached provenance.
`3_OLS_uGRC.do` calls `data_setup` live in its balanced and nonag sections but `use`s cached files in its unbalanced and income sections; `6_OLS_uGRC_hukou.do` is entirely cached with no live fallback.
Any `set_covariates`/`data_setup` edit reaches the live sections immediately and the cached sections only after `1_processData.do` is re-run.
This is the exact silent-divergence failure mode, mediated through a stale cache rather than an in-script `replace`.
Single reader (OLS pair); verified by the absence of any `data_setup` call in `6_OLS_uGRC_hukou.do`.

### Minor: structural, presentation, or hygiene

m1. `5b_inversion.do:80` / `5c_inversion_hukou.do:83` carry an explicit `drop if mi(lndepvar)|mi(choice)` that the parallel `4_GrRC.do`/`7_GrRC_hukou.do` blocks do not, so the sample-trimming step is inconsistently explicit across otherwise-parallel scripts (folds into M3's fix).

m2. `1b_unbalanced_rank_diagnostic.do:145-149` recomputes the switcher/non-switcher partition from scratch instead of cross-checking the shipped `switcher`/`non_switcher`, so if the C10 definition is revisited the diagnostic silently stops matching the variable the pipeline uses.

m3. `11_make_figures.do`'s "Unbalanced" trajectory-composition chart plots the balanced-only subsample, because `handle_trajectory_groups` does `keep if !unbalanced` before building `trajectory`; the authors already flagged this and added a `_fullsample` companion, but the mislabeled chart is still produced.

m4. The never/switcher/always partition ("first trajectory code = never, last = always, else switcher") is hand-coded in three places (`setup_grc_estimation`, `11_make_figures.do`'s `mega_trajectories` bins, `11b`), so adding a wave or changing balance rules requires editing three `inlist()` lists to stay correct.

m5. `8_learning.do:46-77`: for a pid with no `period == 1` row, `first_period_urban` is missing and the `_Xperiod` comparisons silently evaluate to false rather than missing, treating those individuals as neither urban- nor rural-history without a flag.

m6. `6_OLS_uGRC_hukou.do` passes the literal `CHN` (not the hukou-subgroup local) into `reghdfe_regressions`, so all four subgroups share `eststo` names and correctness rests entirely on `eststo clear` placement.

### Front-end design smells (orchestrator's direct read of `0_programs.do` and config)

F1. `handle_depvar` builds `lndepvar` per capita but `ln_income = ln(income)` and `ln_consumption = ln(consumption)` right beside it as raw logs, a live foot-gun for any consumer that reaches for `ln_consumption` expecting the estimand's scale.

F2. `set_covariates` both defines the covariate globals and silently drops the estimation sample (`drop if mi(education_max)`, `mi(age)`, `obs_per_individual == 1`), tangling construction with sample definition inside one program called from inside `data_setup`.

F3. The 2-wave and 3-wave `non_switcher` are hand-enumerated ~60-way string-equality lists (`0_programs.do:464-465`, `522-523`) rather than computed from the trajectory string, fragile against any change in wave count.

F4. `0_CHN_hukou_restrictions.do` writes derived `CHN_hukou_*.dta` into `data/countries/`, mixing derived datasets into the raw-inputs folder.

F5. Logging is per-script (each opens its own log) rather than one named master log per the AEA data-editor pattern; minor, and orthogonal to correctness.

Dropped from an earlier draft: "no project-wide `set seed`" is not a finding, since the estimation path is deterministic (no bootstrap or simulation in the main pipeline).

## What is clean

`2_summaryStats.do`, `3_OLS_uGRC.do` (content), `12_counterfactuals.do` (ster/CSV-driven), `run_extras_cnu.do`, and `run_extras_maxexpsh.do` carry no re-derivation of a front-end variable.
No script outside `0_programs.do` re-derives `age2`, `education_max2`, `rural`, or `choice`, or re-imposes the `mi(education_max)`/`mi(age)`/`obs_per_individual` drops.
The extra regressors (`exp`, `exp_max`, `exp_share`, `exp_max_share`, `urbanbirth`) are genuinely front-end, built in `RP7/databuild/{1_build_IDN,2_build_CHN,3_build_TZA}.do`, and ride through the save-reload cycle untouched.

## Bottom line

There is no realized numerical bug in the mainline GRC or OLS estimates: every redundant `replace` is a no-op today.
The one realized correctness problem is C1 (the 11b figure on the wrong scale), plus C2 as a labeling decision for the authors.
Everything else is latent, and the fix is architectural rather than site-by-site: make the front end the sole construction site, persist every consumer-facing variable to disk with a documented contract, and reduce each analysis script to load-and-estimate.
That single change closes the seam that produced last session's inconsistency and prevents its siblings.
