# Plan: two pre-submission production changes to the estimation sample and switcher set

Date: 2026-07-13.
Spec: [2026-07-13-switcher-inclusion-consistency.md](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md).
Mode: Implementation.
Status: draft for review; no code is touched until this plan is approved.

This plan implements Change A (individual-level strict-spec sample restriction) and Change B (one switcher-inclusion rule across the GMM, the auxiliary OLS, and the inversion), sequenced A-then-B at the one final pre-submission full-pipeline re-run, followed by a simulation rebuild and P2 parity re-certification.

## What the code tracing established

The tracing behind this plan (two Explore passes plus direct reads, 2026-07-13) fixed the following load-bearing facts, each of which shapes a step.

The processed datasets are built by `data_setup` in `1_processData.do` (script 1) and saved to `$dirdata/processed/{country}_{bal,unb}.dta`; every downstream estimator reloads them.
Inside `data_setup` the call order is `use_data` -> `handle_choice` -> `handle_depvar` -> `handle_balance` -> `handle_trajectory_groups` -> `set_covariates` -> ... ([0_programs.do:184](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
`handle_depvar` sets `depvar = consumption` (raw) and drops only missing/non-positive raw consumption ([0_programs.do:298](file:///C:/git/ckt/RP7/scripts/0_programs.do)); the per-capita outcome `log(consumption/hhsize_cube)` is created later, in the GRC drivers ([4_GrRC.do:62](file:///C:/git/ckt/RP7/scripts/4_GrRC.do)), long after the sample is frozen.
`handle_balance` sets `unbalanced = (nr_periods_obs != max_period)` from a raw row count ([0_programs.do:321](file:///C:/git/ckt/RP7/scripts/0_programs.do)), before `hhsize_cube` is ever referenced.
So an individual present in all waves of raw consumption but missing `hhsize_cube` in one wave is flagged balanced and enters a trajectory cell with a short panel; the short wave is later dropped only by the GMM's internal listwise deletion.

Correction to the spec/TODO narrative: [0_programs.do:1287](file:///C:/git/ckt/RP7/scripts/0_programs.do) (`regression_sample = e(sample)`) lives in the OLS `reghdfe_regressions` path ([0_programs.do:1279](file:///C:/git/ckt/RP7/scripts/0_programs.do)) run by `3_OLS_uGRC.do` on raw `log(consumption)` with no `hhsize_cube`, so it is not the mechanism that currently drops the 29 individuals' wave in the GRC estimation.
The fix location is unaffected, but the plan states the true mechanism.

The strictest GRC column uses `covs_gmm_all = female age2 education_max education_max2` plus period FE ([0_programs.do:587](file:///C:/git/ckt/RP7/scripts/0_programs.do), applied at [4_GrRC.do:122](file:///C:/git/ckt/RP7/scripts/4_GrRC.do)); the OLS strictest column uses `covs_all = female c.age#c.age c.education_max##c.education_max` ([0_programs.do:570](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
So the union of strict regressors to protect is `{hhsize_cube, female, age, education_max}`.

The GMM keeps every switcher: `setup_grc_estimation` builds `$switchers` from `tab trajectory` and generates a moment per switcher with no drop ([0_programs.do:1468](file:///C:/git/ckt/RP7/scripts/0_programs.do)); `run_grc` loops `$switchers` into `switcher_traj` and `switcherpars` ([0_programs.do:2069](file:///C:/git/ckt/RP7/scripts/0_programs.do)).

The Python inversion reads the same processed `.dta` the GMM runs on, either from disk (`data_loader.py`, standalone path) or straight from the in-memory Stata dataset via `sfi.Data` (production `attach_inversion_for_stata`, [lca_inversion.py:872](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)).
`switchers_kept` is a clean pass-through argument into `fit_auxiliary_ols` and every `grid_*_inversion` ([lca_inversion.py:83](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py), [lca_inversion.py:138](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)); it is produced by `drop_sparse_switchers` at three call sites and never recomputed inside the fitters.
The Stata-to-Python handoff already passes scalars as locals through `lca_inversion_ci.ado` ([lca_inversion_ci.ado:54](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion_ci.ado)); a keep-list can ride the same channel.

The E1 exporter builds its own aggregation key `traj_for_agg = trajectory`, with `-1` for unbalanced/missing-trajectory individuals, and writes one row per switcher trajectory with no threshold filter ([_export_e1_inputs.do:169](file:///C:/git/ckt/RP7/scripts/_export_e1_inputs.do)).
So it too needs the shared keep-set to stay consistent with a lumped GMM.

## The consequence that simplifies the design

After Change A removes every individual missing any of `{hhsize_cube, female, age, education_max}` in any wave, the per-spec covariate subsetting that `covs_2`/`covs_all` perform drops nobody further, because the only regressors those specs add are exactly the protected ones.
Therefore one switcher keep-set computed on the corrected base sample is automatically identical to the keep-set on every covariate spec's subsample, and MUST 5 (per-spec consistency) is satisfied by construction rather than by recomputing per spec.
This is why a single Stata-authored keep-set per (country, estimation path) is sufficient.

## Architecture decision to confirm at review: where the keep-set lives

Two designs were considered.

Design 1, bake the lumping into the processed `.dta` at build time.
Relabel sub-threshold switchers to `999`/unbalanced inside `handle_trajectory_groups`, so the GMM, the Python inversion, and the E1 exporter all inherit the lumped labels for free by reading the same file.
Rejected as the sole mechanism because the Verdier-robust path needs the unlumped trajectories to apply its looser cluster-count-2 rule (D7), and a `.dta` already lumped at individual-count-5 has discarded exactly the thin trajectories VV wants to keep.

Design 2 (recommended), author the keep-set once in Stata as an explicit artifact, consumed everywhere.
Keep the original `trajectory` column intact in the `.dta`.
Compute the both-states keep-set once per (country, path) in Stata and write it to a small artifact (a per-country text/CSV keep-list under `$output/keeplists/`, plus in-memory globals for the same-session consumers).
The main GMM (`setup_grc_estimation`) lumps non-kept switchers to `999` at estimation setup; the E1 exporter reads the same keep-list and lumps its `traj_for_agg` identically; the Python inversion receives the keep-list through the `lca_inversion_ci.ado` handoff and uses it as `switchers_kept`, skipping `drop_sparse_switchers`.
The VV path computes its own cluster-count-2 keep-list from the same original `trajectory` and lumps on its path only.
This is the true single source of truth per D6: one Stata-authored keep-list per (country, path), no `.dta` fork, VV cleanly separated.

The rest of the plan assumes Design 2.
This is the main point to confirm at review.

## Change A: individual-level strict-spec sample restriction

A-1. Confirm the build path.
Read `1_processData.do` to confirm `data_setup` is the sole builder of `{country}_{bal,unb}.dta` and that no later script re-derives `unbalanced`/`trajectory`.
Confirm `hhsize_cube`, `female`, `age`, `education_max` all exist in the panel at `use_data` time (the databuild scripts build `hhsize_cube` at [1_build_IDN.do:151](file:///C:/git/ckt/RP7/databuild/1_build_IDN.do) and siblings).

A-2. Mark strict-spec-incomplete individuals as unbalanced in `handle_balance`, right after `unbalanced` is generated (line 321), and in the `_2waves`/`_3waves` siblings at the matching point.
Flag any individual missing a strict regressor in any wave as unbalanced, retaining their valid waves rather than deleting them (revised from a full `drop` after review finding M4):
```stata
bysort pid: egen byte pid_miss_strict = max( ///
    missing(hhsize_cube) | hhsize_cube <= 0 | ///
    missing(female) | missing(age) | missing(education_max) )
quietly count if pid_miss_strict & !unbalanced
di as text "handle_balance: reflagging `r(N)' person-waves as unbalanced (strict-spec-incomplete individuals)"
replace unbalanced = 1 if pid_miss_strict
replace unbalanced_choice = unbalanced*choice
drop pid_miss_strict
```
Placing it right after line 321 (before `handle_trajectory_groups` runs `keep if !unbalanced` at line 337) makes the incomplete individuals leave the balanced cells and land in the unbalanced cell, keeping their valid waves.
Hardcode the raw variable names, because `set_covariates` (which defines `$covs_gmm_all`) runs later at line 206.
Guard the predicate so it matches exactly the strict-column regressors; if a country's strict spec differs (hukou adds `hukou`), extend the predicate for that path or gate it by country.
For the `bal` sample (`keep if unbalanced == 0`), these individuals are then dropped by the balance restriction, which is correct: the balanced sample by definition excludes them.

A-3. Verify the effect is the 29 IDN individuals and nothing unexpected.
Before dropping, tabulate by country how many individuals the predicate removes and how many waves each loses; expect 29 in IDN (one wave each), zero in TZA, and re-check CHN.
If any country loses materially more than expected, stop and report before proceeding, because that means a strict regressor has broader missingness than the household-size denominator.

A-4. Regenerate the affected `.ster` and the E1 exporter CSVs on the corrected sample (this happens jointly with Change B's re-run, not separately).
Report IDN `phi`, `Delta_dN`, `Delta_avg`, `Delta_always` old versus new; expect movement of order 1e-4.

## Change B: one switcher-inclusion rule across the three estimators

B-1. Write the both-states counter as a shared Stata program in `0_programs.do`.
`compute_switcher_keeplist, count_unit(pid|cluster) cluster_var(name) threshold(#)` returns, in `r()`, the sorted list of kept switcher codes and a matrix of per-candidate both-states counts, computed on the data in memory:
for each candidate switcher `s` (all trajectories strictly between the min and max codes), count the distinct `count_unit` values that appear both with `choice==1` and with `choice==0` within trajectory `s`, and keep `s` iff that count is at least `threshold`.
On clean balanced data the both-states count equals the plain cell size (every balanced individual spans both states by the trajectory pattern), so this is self-documenting insurance; the counter must still compute it the both-states way so it is correct on any residual incomplete data.
Default `threshold=5`, `count_unit(pid)` for the main path.

B-2. Author the keep-list once per (country, path) and persist it.
In `setup_grc_estimation` (or a thin wrapper called right after data load in `4_GrRC.do`), call `compute_switcher_keeplist` on the loaded estimation sample, write the kept codes to `$output/keeplists/{country}_{path}_switchers.txt`, and stash them in a global for same-session consumers.
This is the single source of truth per D6.

B-3. Main GMM adopts the rule.
In `setup_grc_estimation`, after `tab trajectory` and before building `$switchers` and the switcher dummies ([0_programs.do:1471](file:///C:/git/ckt/RP7/scripts/0_programs.do)), lump non-kept switcher individuals: set `trajectory = 999` and `unbalanced = 1` (and `unbalanced_choice = unbalanced*choice`) for individuals whose trajectory is a dropped switcher, then build `$switchers` from the kept set only.
The lumped individuals now enter through the existing `unbalanced`/`unbalanced_choice` regressors that `run_grc` already adds for the `unb` balance ([0_programs.do:2061](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
Acceptance: TZA trajectory 3 (one person) no longer appears as `switcher_3_choice`; total person and person-wave counts are unchanged; the person's rows carry `unbalanced==1`.
Edge case: in the balanced sample there is no unbalanced cell, so dropped switchers cannot be lumped; for the `bal` robustness runs, dropped switchers are removed and this is noted in the run log and the disclosure prose. Flag for review whether the `bal` sample should instead keep them via a different convention.

B-4. Auxiliary OLS and inversion consume the same keep-list.
Extend `lca_inversion_ci.ado` to pass the kept-switcher list as a local (alongside `outcome/traj/choice/hhid/base`), and change `lca_inversion_ci_helper.py`, `compute_all_inversion_cis`, and `attach_inversion_for_stata` to accept an optional `switchers_kept` and, when supplied, skip `drop_sparse_switchers` and use the supplied list directly.
Keep `drop_sparse_switchers` callable, but when both a supplied list and a recomputation are available, assert they agree and hard-error on mismatch (SHOULD 10).
The standalone `run_all_countries_inversion.py` path gains the same optional argument, defaulting to reading the persisted keep-list file so a manual run matches production.

B-5. E1 exporter consumes the same keep-list.
In `_export_e1_inputs.do` and `_export_e1_inputs_hukou.do`, after building `traj_for_agg` ([_export_e1_inputs.do:169](file:///C:/git/ckt/RP7/scripts/_export_e1_inputs.do)), read the persisted keep-list and set `traj_for_agg = -1` for individuals in a dropped switcher trajectory, so the exported per-trajectory rows match the lumped GMM.
Acceptance: no `{country}_e1_traj.csv` row exists for a dropped switcher trajectory; the `-1` row's `n_pids` grows by exactly the lumped individuals.

B-6. Verdier-robust path, looser and cluster-counted.
In `run_grc_robust_vv` (and its onestep variant), call `compute_switcher_keeplist, count_unit(cluster) cluster_var(<village-equivalent>) threshold(2)` on the original trajectory labels, persist it as the `{country}_vv_switchers.txt` keep-list, and lump non-kept switchers to `999`/unbalanced on the VV path only.
The village-equivalent cluster follows the separate VV granularity TODO (CHN `cid`, IDN `keca`, TZA `ward`); until that TODO lands, use the current VV cluster variable and note the granularity caveat.
Acceptance: the VV keep-list is reported separately and generally keeps at least as many switcher trajectories as the main path.

B-7. Disclosure prose.
Add two-to-three sentences (one per line) to the section that first defines the switcher cells or reports `Delta_unb`, stating the rule (five individuals in both states on the main path, two clusters on the VV path), that dropped-trajectory individuals join the unbalanced cell, and that this changes the unbalanced-cell interpretation.
Draft in the worktree paper source; the Overleaf edit is the user's to make.

B-8. Thin-cells-retained inversion exhibit (review finding M3, user-approved).
Because the inversion is a weak-ID-robust procedure and the five-both-states rule pre-filters exactly the weakly-identified thin trajectories, add an appendix exhibit that runs the inversion CI with the thin switcher trajectories retained (threshold lowered to include them), for the IDN and TZA cells where thin trajectories exist.
The exhibit shows the pre-filter is not doing the identification work; the main-text CI stays the filtered version.
Acceptance: one appendix table or figure comparing the filtered and thin-retained inversion CIs for the affected cells.

## Sequencing, regeneration, and re-certification

S-1. Order within the re-run: Change A first (rebuild processed `.dta` via `1_processData.do` so incomplete individuals leave the balanced cells), then Change B (keep-list authored on the corrected sample, GMM/OLS/inversion/exporter all consuming it).

S-2. Regenerate: the main-path `.ster` (`4_GrRC.do`, and hukou `7_GrRC_hukou.do`), the inversion attach (`5b_inversion.do`), the VV path (`17_verdier_robust.do`), and the E1 exporter CSVs.
This is a full-pipeline re-run; estimate cost and confirm the run window with the user before launching (the master pipeline is long).

S-3. Old-versus-new table: per (country, spec) report `phi`, `Delta_dN`, `Delta_avg`, `Delta_always`, and the Hansen `J`, `J_df`, `J_p` before and after (the `J` columns per review finding M2, so a non-rejection is visibly not an artifact of the lumped-away overidentifying restrictions).
Pin the base trajectory across the before and after runs (review process note): base selection is data-driven and the candidate pool moves with the keep-set, so hold the base fixed to keep the comparison apples-to-apples.
Confirm the headline reading (pro-poor `phi<0`, non-migrant magnitude) is unchanged in sign and roughly in size, and confirm the GMM average return and the inversion average return now share the same switcher set cell by cell (the point of Change B).
Assert the average-return weight vector (`num_s` for the GMM, `pi_within` for the inversion) and the base trajectory match across the two estimators, not only the switcher code set (review finding M1).

S-4. Simulation rebuild and parity: rebuild the extension-simulation design snapshot and truths from the corrected E1 exporter, then re-run P2 parity certification.
The hash freeze and the P5b relaunch stay deferred until P2 parity passes on the rebuilt sim (spec MUST 9).

S-5. Update the two TODO entries (Change A and Change B) to reflect completion, and write the session log.

## Verification checklist

Sample restriction removes exactly the expected individuals per country (A-3).
Person and person-wave totals unchanged by the lumping, only labels change (B-3).
Kept switcher codes identical across GMM, auxiliary OLS, inversion for every main-path cell (B-4), printed not eyeballed.
E1 exporter rows match the lumped GMM (B-5).
VV keep-list computed at cluster-count-2 and reported separately (B-6).
Headline numbers move only at the disclosed small order for Change A and by the disclosed amounts for Change B (S-3).
P2 parity re-certifies on the rebuilt sim (S-4).

## Risks and open points for review

R-1. Design 2 (keep-list artifact) versus Design 1 (`.dta` bake): confirm Design 2, given the VV-path conflict is the deciding factor.

R-2. The `bal` sample has no unbalanced cell to lump into (B-3 edge case): confirm dropped switchers are simply removed there, or specify an alternative.

R-3. Lumping sparse switchers into the unbalanced cell conflates them with survey-attrition unbalanced individuals, which carry different information; this is the user's decision (D3) and is disclosed, but the plan records the econometric caveat the tracing surfaced.

R-4. The VV threshold of two clusters is a proposed value (D7); confirm at review, and note it is swept in the separate robustness check.

R-5. The strict-regressor predicate (A-2) assumes `{hhsize_cube, female, age, education_max}` is the full strict-column set for the main path; the hukou path adds `hukou`. Confirm the predicate per path so Change A does not silently under- or over-restrict a hukou sample.

## Review resolutions (critic-econometrics, 2026-07-13)

Report: [2026-07-13-switcher-inclusion-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-switcher-inclusion-plan-review.md).
Verified counterpoint carried through: because `unbalanced_choice` is a free just-identified absorber with its own instrument ([0_programs.do:2109](file:///C:/git/ckt/RP7/scripts/0_programs.do)), the lumping cannot bias $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, or $\Delta_{d_T}$ through the moment algebra; the exposure is in the claims and the validation apparatus, not the headline parameters.

C1 (estimand equivalence): downgraded to wording after verification.
`grid_delta_avg_md_inversion` ([lca_inversion.py:419](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)) targets `c1 = sum_s pi_within[s]*(alpha_s - alpha_base)`, the same LCA-line share-weighted form the GMM `Delta_avg` uses, not an unrestricted-$\beta_s$ average, so the two procedures target the same object once the switcher set matches.
Framing fix: state that both target the LCA-line share-weighted average over the same switchers, and that under LCA rejection the inversion can return an empty CI while the GMM still forces a number, so they share the target object but the inversion may decline to report it.

M1: acceptance now asserts the weight vector and base trajectory match across estimators (folded into S-3), not only the code set.

M2: `J`, `J_df`, `J_p` added to the S-3 before/after table so the non-rejection is visibly not an artifact of shed overidentifying restrictions.

M3: appendix exhibit added (B-8), inversion CI with thin trajectories retained.

M4: resolved by lumping, not deleting (A-1/A-2 revised to recompute `unbalanced`); DA3 records the decision.

M5: dissolved. Production passes `hhid(pid)` at [5b_inversion.do:145](file:///C:/git/ckt/RP7/scripts/5b_inversion.do), so the auxiliary OLS and `drop_sparse_switchers` cluster and count on `pid`, matching the GMM's `vce(cluster pid)`; no person-versus-household split on the reported path.
Add a verification assert that no other reported inversion path clusters on a household id.

M6: not resolved, accepted (user 2026-07-13, decision D8).
The VV path keeps its looser cluster-count-2 set and is not re-run on the main-path set, because VV is already a robustness check and the extra fits are not worth it; the disclosure prose notes the VV switcher set differs from the main path so the estimator comparison is not read as clean.

M7: disclosed. The prose and the table note that two-cluster VV trajectories yield near-degenerate cluster-robust moments and that the VV cluster variable (`cid`/`keca`/`ward`) is provisional (R-5), so freezing VV headline results before that granularity TODO lands risks a re-run.

m1: the both-states form is framed as insurance, not a live-bias correction; the paper does not claim it corrects a bias in the reported estimates.
m2: the per-spec no-op claim is scoped to the consumption main-path specs; the income outcome and the hukou path (which adds `hukou`) get their own per-spec keep-set check.
m3: the disclosure states that the count of reported switcher trajectories falls (TZA loses its single-person trajectory), not only that an average shifts.
m4: since the paper never interprets $\Delta_{\text{unb}}$ as a return (user 2026-07-13), the disclosure states plainly that `unbalanced_choice` is a nuisance control absorbing attrition and lumped thin switchers, and does not need the two-population-mixture return caveat.
