# Spec: two pre-submission production changes to the estimation sample and switcher set

Date: 2026-07-13.
Source: [2026-07-13_p7-split-fit-sim-review-p5b.md](file:///C:/git/ckt/quality_reports/session_logs/2026-07-13_p7-split-fit-sim-review-p5b.md) and the "Exclude individuals missing on the strict spec" and "Make the switcher-inclusion rule internally consistent" entries in [docs/TODO.md](file:///C:/git/ckt/docs/TODO.md).
Mode: Implementation (both alter the estimation sample and the headline estimates, so this needs an approved spec and plan before any code).

This spec covers two coupled production changes that land together at the one final pre-submission full-pipeline re-run.
Change A: exclude individuals missing on the strictest specification from the estimation sample at the individual level.
Change B: make the switcher-inclusion rule identical across the GMM, the auxiliary OLS, and the inversion.
They are combined here because they share the re-run and interact directly: A removes the only individuals for whom B's symmetric form differs from a plain cell-size count (see the coupling section), so A must apply before B computes the keep-set.

Scope: the estimation-sample construction and the switcher-trajectory keep/drop decision across the three estimators the paper reports side by side.
Stata in `RP7/scripts/0_programs.do` (`data_setup`, the `unbalanced` flag at [0_programs.do:321](file:///C:/git/ckt/RP7/scripts/0_programs.do), the `regression_sample = e(sample)` restriction at [0_programs.do:1287](file:///C:/git/ckt/RP7/scripts/0_programs.do), `setup_grc_estimation`, `run_grc`, `define_switcherpars`, and the Verdier-robust `run_grc_robust_vv`).
Python auxiliary OLS and inversion in `explorations/python-grc/lca_inversion.py` (`drop_sparse_switchers`, `fit_auxiliary_ols`, `grid_lca_inversion`) and their driver `run_all_countries_inversion.py` / helper `lca_inversion_ci_helper.py`.
The generated `.ster` files, the E1 exporter CSVs, the simulation design snapshot, and any paper number that moves.

Out of scope: the threshold-sweep and leave-one-trajectory-out robustness checks (separate TODO, built after the P5b freeze).
Any change to the estimator math itself; this changes only which individuals and which switcher trajectories enter.

## Change A: the current sample defect

IDN has 29 individuals (0.1% of 29,692) with `hhsize_cube` missing in exactly one wave; consumption itself is present, so only log per-capita consumption is undefined for that one person-wave.
Production drops that single row via the row-level `regression_sample = e(sample)` restriction taken from the strictest column ([0_programs.do:1287](file:///C:/git/ckt/RP7/scripts/0_programs.do)), but the `unbalanced` flag is fixed earlier ([0_programs.do:321](file:///C:/git/ckt/RP7/scripts/0_programs.do)) before that restriction, so these 29 individuals stay flagged balanced and enter their trajectory cells with four waves instead of five.
Verified against the exporter CSVs: every trajectory's `n_pids` includes them, so this is the sample the current `.ster` and E1 CSVs were built on.
The intended sample restricts to individuals non-missing on the strictest specification (the last GRC column): an individual missing household size in any wave should not be in the sample at all, not merely have one wave dropped.

## Change B: the current inconsistency

The GMM keeps every switcher trajectory that exists.
`setup_grc_estimation` builds `$switchers` from `tab trajectory` ([0_programs.do:1471](file:///C:/git/ckt/RP7/scripts/0_programs.do)) and generates a `switcher_s`/`switcher_s_choice` moment for each ([0_programs.do:1489](file:///C:/git/ckt/RP7/scripts/0_programs.do)) with no thin-cell drop, so TZA trajectory 3 (one person) enters the GMM.

The auxiliary OLS and the inversion drop switchers via `drop_sparse_switchers` ([lca_inversion.py:46](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)), which keeps a trajectory only if at least five unique individuals contribute a treated (`choice==1`, urban) observation.
That count is one-sided: it never checks the rural side, even though a switcher's return is identified off the within-person urban-versus-rural contrast.

The consequence is that the GMM average return over all switchers and the inversion average return over the kept switchers are different estimands over different switcher sets, which is a genuine internal inconsistency, not merely a simulation artifact.

## MUST (Change A: sample restriction)

A1. Remove individuals incomplete on the strictest specification from the balanced trajectory cells, at the individual level, by recomputing `unbalanced` so they land in the unbalanced cell rather than being deleted (decision DA3, revised after review finding M4).
   An individual missing `hhsize_cube` (or any strict-column regressor) in any wave is flagged `unbalanced == 1`, so their valid waves are retained in the unbalanced cell instead of being discarded; a full `drop` of the individual is rejected because it throws away roughly four valid person-waves each and contradicts the never-discard principle in D3.
   Acceptance: the 29 IDN individuals no longer appear in any balanced trajectory cell; every one of their valid person-waves is retained under `unbalanced == 1`; total person-wave counts are unchanged.

A2. Confirm the headline numbers barely move before trusting the re-run.
   The change is 29 of 29,692 IDN individuals, one wave each, so the expected shift is order 1e-4; report the IDN $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ before and after.
   TZA is unaffected (no balanced individual is missing household size); CHN is untouched by inspection but re-checked in the same pass.
   Acceptance: the old-versus-new table shows IDN moves at the expected small order and TZA and CHN are unchanged.

A3. Regenerate the affected `.ster` and the E1 exporter CSVs on the corrected sample, and rebuild the simulation design snapshot from the corrected exporter (the sim is calibrated to the current exporter, so it must be re-derived).

## MUST (Change B: switcher-inclusion consistency)

1. One switcher keep-set per (country, specification, sample) cell, computed once and shared, drives all three estimators.
   The Stata GMM performs the drop-and-lump; the Python auxiliary OLS and inversion consume the resulting trajectory labels rather than independently re-deriving a possibly different set.
   Acceptance: for every (country, spec) cell the switcher codes entering the GMM equal the switcher codes entering the inversion; verified by a printed comparison, not by inspection.

2. The keep rule is: retain a switcher trajectory if and only if it has at least five unique individuals each observed in both an urban period (`choice==1`) and a rural period (`choice==0`) within that trajectory.
   Never (first trajectory code, all rural) and always (last code, all urban) are not switchers and are excluded from candidacy, as today.
   Acceptance: a unit test on a constructed panel confirms a trajectory with five both-states individuals is kept, one with four is dropped, and one-sided cells (five urban-only, zero rural-only) are dropped.

3. The GMM adopts this rule.
   Where it currently keeps every switcher, it drops sub-threshold switcher trajectories before generating the moment dummies, moving from the effective `sparse_moment_threshold=0` to the shared rule.
   Acceptance: TZA trajectory 3 (one person) no longer appears as a `switcher_3_choice` moment in the TZA GMM fit; its person's rows are relabeled, not deleted.

4. Individuals in a dropped switcher trajectory are lumped into the unbalanced cell (Stata `trajectory==999`, Python trajectory `-1`), never deleted.
   The lumped individuals contribute through the same `unbalanced`/`U_i`-times-`choice` mechanism that already absorbs unbalanced individuals ([0_programs.do:1481](file:///C:/git/ckt/RP7/scripts/0_programs.do), [0_programs.do:1516](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
   Acceptance: total person and person-wave counts are unchanged before and after the drop; only the trajectory label changes for the affected individuals.

5. The keep-set is computed per specification on the actual estimation subsample that specification uses.
   covs_2 and covs_all subset the sample where `education_max` and its square are required, so a trajectory at five both-states individuals on the base sample may fall below five on the covariate-restricted subsample.
   The keep-set is recomputed on each spec's own sample, closing the deferred per-spec keep-list item (P-M2 in TODO).
   Acceptance: the printed keep-sets differ across covs specs wherever the covariate subsetting drops a near-threshold trajectory below five.

6. The Verdier-robust path counts by cluster (village), not by individual, and uses a lower threshold.
   On `run_grc_robust_vv` and the Python cluster path, the count unit is the village-equivalent cluster and the keep rule is: retain a switcher trajectory if at least two unique clusters each contribute both an urban and a rural observation.
   The relaxed threshold of two (versus five individuals on the main path) reflects that setting the VV cutoff equal to the main path would empty most switcher trajectories given the small number of clusters, especially TZA; two is the floor that preserves any cross-cluster contrast, and the threshold is swept in the separate robustness check.
   "Consistent" therefore means individual-count at five on the main path and cluster-count at two on the VV path, matching the separate VV cluster-count TODO.
   Acceptance: the VV keep-set is derived from cluster counts at the two-cluster threshold and is reported separately from the main-path keep-set.

7. Regenerate every affected `.ster`, the E1 exporter CSVs, and any downstream artifact, and re-quote every paper number that moves.
   The main-path headline parameters ($\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$) are reported old-versus-new per cell in the plan's status footer.
   Acceptance: the GMM average return and the inversion average return are the same estimand over the same switcher set in every cell, which is the point of the change.

8. Disclose the lumping in the paper prose.
   The text states the rule (five both-states individuals on the main path), that dropped-trajectory individuals join the unbalanced cell, and that the count of reported switcher trajectories falls (TZA loses its single-person trajectory, review finding m3).
   Because the paper never interprets $\Delta_{\text{unb}}$ as a return (user 2026-07-13, review finding m4), the disclosure states that `unbalanced_choice` is a nuisance control absorbing both survey attrition and the lumped thin switchers, and does not carry the two-population-mixture-return caveat.
   Acceptance: one to three sentences, one-sentence-per-line, in the section that first defines the switcher cells.

9a. Report the Hansen $J$, its degrees of freedom, and its $p$-value before and after the rule in the old-versus-new table (review finding M2), so the non-rejection is visibly not an artifact of the overidentifying restrictions that the lumping removes.

9. Re-certify P2 parity after the change.
   Changing the GMM switcher set breaks the current simulation parity by construction; after regenerating the `.ster` and exporter, the simulation design snapshot and truths are rebuilt from the corrected exporter and P2 parity is re-run and passes before any simulation hash freeze or P5b relaunch.
   Acceptance: P2 parity certification passes on the rebuilt sim; the hash freeze stays deferred until it does.

## SHOULD

10. Keep the Python `drop_sparse_switchers` as a redundant safety check that is a no-op once Stata has already lumped.
    After the Stata relabel, the data Python reads carries dropped switchers as unbalanced already, so a Python re-run of the rule keeps everything remaining; assert this rather than silently re-deriving.
    A mismatch between the Stata-exported keep-set and a Python recomputation is a hard error, not a warning.

11. Emit a per-cell keep-set diagnostic: the candidate switcher trajectories, their both-states counts, which were kept, and which were lumped, written next to the estimation output for audit.

12. Verify the both-states count equals the cell size on clean balanced data.
    Every balanced switcher-trajectory individual spans both states by the trajectory pattern (for example 01011 has at least one urban and one rural wave), so on the corrected sample the both-states count and the plain cell size coincide; the symmetric wording is self-documenting insurance rather than a live correction on clean data.

## MAY

13. Report the number of switcher trajectories and individuals lumped per country in an appendix line, so the reader can see how much mass the rule moves.

14. Fold the threshold into a single named constant (default five) surfaced in both the Stata code and the Python module, so the later robustness sweep can vary it without touching call sites.

## Decisions locked 2026-07-13 (user), with the why

DA1 combine the two changes into one spec and one re-run: the sample restriction and the switcher-inclusion rule ship together, because they share the final pre-submission pipeline re-run and interact (the sample fix must apply before the keep-set is computed).

DA2 sample restriction at the individual level: an individual missing on the strictest specification leaves the sample entirely, rather than losing one wave and staying in a balanced cell with a short panel.
This is the correct sample definition for the estimand; leaving it makes the balanced GRC quietly include incomplete-panel individuals, which is indefensible for an Econometrica submission even though the numeric effect is tiny.

DA3 lump the incomplete individuals, do not delete them (user 2026-07-13, after review finding M4): the 29 IDN individuals are moved to the unbalanced cell by recomputing `unbalanced`, retaining their four valid waves each, rather than being dropped.
A full drop was rejected because it discards roughly 116 valid person-waves and contradicts the never-discard principle in D3.

D1 keep rule: at least five unique individuals observed in both an urban and a rural period, applied identically in the GMM, the auxiliary OLS, and the inversion.
Five is the current production value in `drop_sparse_switchers`, which keeps continuity and is a standard minimum-cell heuristic; the honest defense is the robustness sweep, not the specific number.
The symmetric both-states form is preferred over the one-sided treated-only count because a switcher's return needs representation on both sides of the within-person contrast; on clean balanced data it equals the cell size, so it is insurance, and the live behavioral change is the GMM adopting the drop at all.

D2 GMM adopts the rule: confirmed no coauthor decision needed; it changes headline estimates and requires the re-run, which the user accepts.
The current split is defensible only as an accident of implementation, not a considered choice.

D3 lump, do not delete: dropped-trajectory individuals join the unbalanced cell, because we never discard data and the lumped cell already exists to absorb individuals who do not get their own trajectory parameter.
This needs disclosure because it shifts what $\Delta_{\text{unb}}$ estimates.

D4 count unit: individual on the main path, cluster (village) on the Verdier-robust path, matching how each path clusters its inference.

D5 sequencing: land both changes at the one final pre-submission full-pipeline re-run, sample fix first then keep-set, then rebuild the sim and re-certify P2 parity; hold P5b until then so it validates the shipping procedure.

D6 single source of truth: the shared keep-set is authored in Stata and exported to Python, rather than coded independently in both languages.
This removes any chance of a two-language drift, at the acceptable cost of Python depending on a Stata-produced trajectory label (user, 2026-07-13).

D7 VV threshold: less strict than the main path, set at two clusters in both states (versus five individuals), because five clusters would empty most switcher trajectories at the small cluster counts and the threshold is swept in the robustness check anyway (user, 2026-07-13; specific value proposed here for confirmation at plan review).

D8 VV switcher-set confound accepted, not resolved (user 2026-07-13, after review finding M6): the VV estimator runs only on its looser cluster-count-2 set and is not additionally re-run on the main-path set, because VV is already a robustness check and the extra fits are not worth it.
The disclosure notes that the VV switcher set differs from the main path, so a reader does not mistake the VV-versus-GMM movement for a pure estimator effect.

Review resolutions from the 2026-07-13 critic-econometrics pass are recorded in the plan's "Review resolutions" section; the report is [2026-07-13-switcher-inclusion-plan-review.md](file:///C:/git/ckt/quality_reports/reviews/2026-07-13-switcher-inclusion-plan-review.md).

## Coupling between the two changes

The both-states rule (Change B) reduces exactly to the plain cell size only after the sample restriction (Change A) removes the 29 incomplete IDN individuals, because those individuals are the only ones whose sole urban or sole rural wave can be dropped and thus the only ones for whom one-sided and both-states counts differ.
The two changes therefore land in the same re-run in a fixed order: Change A first, so incomplete individuals leave the balanced cells, then the keep-set is computed on the corrected sample.
