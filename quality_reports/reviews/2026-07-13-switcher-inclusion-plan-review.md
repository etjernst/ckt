# Methods review: switcher-inclusion consistency and strict-spec sample restriction

Date: 2026-07-13.
Reviewer role: identification/estimand referee (Econometrica target).
Scope reviewed: [spec](file:///C:/git/ckt/quality_reports/specs/2026-07-13-switcher-inclusion-consistency.md) and [plan](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md), read against the moment structure in [0_programs.do](file:///C:/git/ckt/RP7/scripts/0_programs.do) (`run_grc` at 2103--2116, `setup_grc_estimation` at 1468--1494, `Delta_avg` construction at 2843--2868) and the Python inversion in [lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py).

This is a methods/estimand review, not a code lint. The two changes are sound in intent and the plan is unusually careful about mechanics. The findings below concern what the plan treats as settled at the level of the estimand and the identifying restriction. CRITICAL flags are prompts for the researcher's own judgment, not verdicts.

## What the moment algebra actually says (grounding the findings)

The GMM residual (unbalanced path) is
$$
\text{lndepvar} - \{\mu:\, \text{never},\ \text{switcher\_traj}\} - \Delta_{\text{base}}\cdot\text{choice} - \phi\cdot(\text{switcherpars}) - (\kappa + \phi(\kappa - \mu_{\text{base}}))\cdot(\text{always}\times\text{choice}) - \{xb:\, \text{covars},\ \text{unbalanced},\ \text{unbalanced\_choice}\},
$$
with `unbalanced` and `unbalanced_choice` appearing as their own instruments ([0_programs.do:2109](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
So the unbalanced cell is a saturated, just-identified free absorber: `unbalanced_choice` is an unrestricted coefficient, orthogonal to the LCA line.
The reported `Delta_avg` is a trajectory-share-weighted average of the LCA-restricted fitted returns $\Delta_{\text{base}} + \phi(\mu_s - \mu_{\text{base}})$ over kept switchers ([0_programs.do:2843](file:///C:/git/ckt/RP7/scripts/0_programs.do)).
The inversion is built on the unrestricted saturated auxiliary OLS (each $\beta_s$ free) and inverts the LCA restriction for $\phi$ ([lca_inversion.py:138](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)).
These four facts drive most of what follows.

---

## CRITICAL

### C1. "Same estimand" presupposes the LCA restriction the inversion exists to interrogate (confidence: MEDIUM)
Lens: identification design.
Spec acceptance 81 and plan S-3 state that after the change "the GMM average return and the inversion average return are the same estimand over the same switcher set."
The GMM `Delta_avg` evaluates each switcher's return *on the LCA line* ($\Delta_{\text{base}} + \phi(\mu_s - \mu_{\text{base}})$), share-weighted.
The inversion is anchored on the *unrestricted* auxiliary OLS, where each switcher's $\beta_s$ is free, and it treats the LCA cross-equation restriction as a hypothesis to be inverted.
An unrestricted average of switcher returns and an LCA-line average coincide only when the LCA restriction holds exactly.
That restriction is precisely what the Hansen $J$ and the weak-ID-robust inversion are there to test.
So describing the two averages as "the same estimand" builds the restriction into the claim that is supposed to be able to fail.
Under LCA misspecification (the paper already documents a CHN $J$ rejection) the two averages are different estimands by construction, and making the switcher *set* identical does not close that gap.
I mark this CRITICAL and MEDIUM because I could not fully trace how the driver defines the "inversion average return" (whether it maps $\phi$ back through the same LCA weighting or averages the unrestricted $\beta_s$); if it maps through the identical LCA formula with identical weights, the estimand claim is defensible and this drops to MAJOR wording. Human judgment required on which object the inversion reports.

---

## MAJOR

### M1. Matching the switcher set is necessary but not sufficient for a common estimand (confidence: HIGH)
Lens: identification design.
The spec's acceptance criteria verify that the *codes* entering each estimator agree (spec MUST 1, plan B-4 "printed not eyeballed").
`Delta_avg` depends on three further choices beyond the set: the weights (`num_s` trajectory shares, [0_programs.do:2223](file:///C:/git/ckt/RP7/scripts/0_programs.do)), the base trajectory, and whether returns are evaluated restricted (on the line) or unrestricted.
The plan verifies none of these across the three estimators.
Two averages over the identical switcher set still differ if the GMM share-weights while the inversion equal-weights the joint Wald, or if the base differs.
The comment trail at [0_programs.do:2217](file:///C:/git/ckt/RP7/scripts/0_programs.do) records a prior `Delta_avg` weighting bug (a switcher-fraction that swept in non-switchers), so weighting is a live, previously-wrong axis here.
The acceptance checklist should assert equality of the weight vector and the base, not only the code set.

### M2. Lumping removes overidentifying restrictions from the very $J$-test that validates LCA (confidence: HIGH)
Lens: threats to validity / robustness.
Each kept switcher contributes an overidentifying moment that binds against the LCA line; the Hansen $J$ counts those restrictions.
Relabeling a thin switcher to the unbalanced cell moves it into the saturated, just-identified `unbalanced_choice` absorber, which contributes no overidentifying restriction.
So the change mechanically *reduces* the number of binding LCA restrictions and makes $J$ weakly easier to pass.
Given the documented CHN $J$ rejection and the hukou-split workaround, a referee will read "drop the thinnest, most awkward switcher trajectories, then report a non-rejecting $J$" as specification search unless the paper reports $J$, its degrees of freedom, and $p$ both before and after the rule and shows the non-rejection is not an artifact of shed restrictions.
The plan's old-versus-new table (S-3) reports $\phi$, $\Delta_{d_N}$, $\Delta_{\text{avg}}$, $\Delta_{d_T}$ but not $J$, $J_{df}$, $J_p$. That omission should be closed.

### M3. The inversion's raison d'etre is weak identification, and the rule discards the weakly identified trajectories (confidence: MEDIUM)
Lens: identification design.
The inversion exists to deliver CIs that stay valid when switcher returns are weakly identified.
Thin switcher trajectories are exactly the weakly-identified moments.
Applying a five-both-states pre-filter removes the trajectories most responsible for weak identification before running the weak-ID-robust procedure.
The result is a robust CI computed over a set pre-selected to be well-identified, which weakens the procedure's stated purpose and invites the question of why the robust machinery is needed once the thin cells are gone.
This is a conceptual tension the plan does not surface; at minimum the paper should report what the robust CI looks like *with* the thin trajectories retained, so the reader sees the pre-filter is not doing the identification work.

### M4. Change A deletes valid person-waves, contradicting the "never discard data" principle it sits beside (confidence: HIGH)
Lens: threats to validity (selection) / internal consistency.
The 29 IDN individuals have consumption present in every wave and `hhsize_cube` missing in exactly one, so log per-capita consumption is defined in four of five waves.
Spec A1 says drop the person "or, equivalently, by recomputing `unbalanced`" so they leave the balanced cells.
These are not equivalent: full drop discards four valid person-waves per individual; recomputing `unbalanced` retains those four waves in the unbalanced cell.
The plan's code ([plan A-2](file:///C:/git/ckt/quality_reports/plans/2026-07-13-switcher-inclusion-consistency.md)) executes `drop if pid_miss_strict`, the full-drop, which throws away roughly 116 valid person-waves.
This directly contradicts D3 for Change B ("we never discard data; lump into the unbalanced cell"), which keeps thin switchers precisely because their outcomes are valid.
Two individuals with valid outcomes in a wave are treated oppositely depending on which change touches them.
The defensible, internally consistent choice is to move the 29 to the unbalanced cell (retain their four valid waves), not delete them; if deletion is chosen, the asymmetry with D3 needs an explicit reason (undefined outcome in one wave versus a valid outcome in a thin cell) stated in the disclosure.

### M5. The GMM and the auxiliary OLS cluster on different units (confidence: HIGH)
Lens: inference.
`run_grc` uses `vce(cluster pid)` ([0_programs.do:2114](file:///C:/git/ckt/RP7/scripts/0_programs.do)); `fit_auxiliary_ols` clusters on `hhid` (`groups=hhid`, [lca_inversion.py:120](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py)) and `drop_sparse_switchers` counts unique `hhid`.
The whole point of Change B is to make the three side-by-side estimators comparable, yet two of them cluster inference at different levels (person versus household).
Households with multiple migrants make these genuinely different, and the standard errors the reader compares across the three columns are then not on a common footing.
The spec's "count by individual" for the main path would also flip the Python count unit from `hhid` to `pid`, which is a substantive change to the keep-set the plan does not call out.
Decide the inference unit once and apply it to both the clustering and the count.

### M6. The VV path runs on a different switcher set, confounding the estimator comparison (confidence: MEDIUM)
Lens: robustness.
The main path keeps switchers at five individuals in both states; the VV path keeps at two clusters in both states (D7, plan B-6).
The plan accepts that VV "generally keeps at least as many switcher trajectories."
The VV estimator is presented as a robustness check on the same parameter, but if it runs over a *larger* switcher set, any movement between the main GMM and the VV estimate confounds two changes: the estimator (GMM versus Verdier-robust) and the switcher set (more versus fewer trajectories).
To isolate the estimator effect, the VV estimator should also be reported on the main-path keep-set, so "VV versus GMM" is not entangled with "more switchers versus fewer." The plan proposes only the looser VV-specific set.

### M7. Threshold of two clusters sits on the degenerate boundary for cluster-robust inference (confidence: MEDIUM)
Lens: inference (few clusters).
Two clusters is the floor at which any between-cluster contrast exists, but a switcher trajectory supported by exactly two clusters contributes a cluster-robust moment with an essentially non-normal, severely downward-biased variance (the few-clusters problem in its most acute form).
Admitting such trajectories into a cluster-robust Wald is defensible only under the weak-ID-robust logic, and even then the trajectory's contribution to the covariance is near-degenerate.
Deferring the choice to the separate sweep is reasonable, but the plan should state that two-cluster trajectories yield near-degenerate cluster-robust moments and that the VV granularity variable (`cid`/`keca`/`ward`) is itself not yet finalized (plan R-5, B-6), which means the keep-set will move again when that TODO lands. Freezing headline results on a provisional cluster definition risks a re-run.

---

## MINOR

### m1. The "both-states" refinement is vacuous on the corrected sample, so the live change is narrower than framed (confidence: HIGH)
Lens: robustness.
For a balanced switcher trajectory the pattern itself guarantees both states, so the both-states count equals the plain cell size (spec SHOULD 12, plan B-1 both concede this).
After Change A removes the 29 incomplete IDN individuals, the both-states count, the one-sided treated count, and the cell size all coincide, and the per-spec recomputation (MUST 5) is a no-op by the plan's own argument (plan lines 35--39).
The only behavioral change is the GMM adopting a drop at all.
This is fine, but the elaborate symmetric-counter machinery should be presented as insurance, and the paper should not claim the both-states form corrects a live bias in the reported estimates.

### m2. The no-op claim for per-spec subsetting does not extend to the income outcome (confidence: MEDIUM)
Lens: robustness.
The plan's no-op argument (protecting $\{$`hhsize_cube`, `female`, `age`, `education_max`$\}$ makes covariate subsetting drop nobody) is built on the consumption strict spec.
CLAUDE.md lists log income as a secondary reported outcome.
If income is missing where consumption is not, income-spec keep-sets can differ, and the single-keep-set-per-country simplification (plan lines 35--39) does not cover income specs or the hukou path (which adds `hukou`, plan R-5).
Confirm the outcome and covariate coverage the keep-set claim spans, or scope the claim explicitly to consumption main-path specs.

### m3. Dropping a single-person trajectory from the GMM is stabilizing but changes the reported set of switcher returns (confidence: HIGH)
Lens: robustness.
TZA trajectory 3 (one person) currently enters as its own `switcher_3_choice` moment identified off one person's within-variation, a near-singular contribution to the weighting matrix.
Removing it improves numerical stability, which is a point in favor.
But its per-trajectory return was previously part of the reported switcher-return set and the $J$-test; the disclosure should note that the count of reported switcher trajectories falls, not only that an average shifts.

### m4. Disclosure requirement understates what the unbalanced coefficient becomes (confidence: MEDIUM)
Lens: threats to validity.
Because `unbalanced_choice` is a free, just-identified absorber, lumping does not bias $\phi$, $\Delta_{d_N}$, $\Delta_{d_T}$, or $\Delta_{\text{avg}}$ through the moment algebra (the reassuring counterpart to worry D3): the lumped mass leaves the LCA-identifying moments entirely and is soaked up by its own instrument.
What it does do is turn `unbalanced_choice` into a mixture return over two populations with different information content, survey-attrition individuals and dropped thin switchers with genuine both-states contrasts.
The spec's disclosure requirement ("changes the unbalanced-cell interpretation," D3) is directionally right but vague; if $\Delta_{\text{unb}}$ is read anywhere as a return estimand, the prose should state that it is a sample-weighted mixture over those two distinct groups, not merely that the interpretation "changes." If $\Delta_{\text{unb}}$ is only a nuisance control never interpreted as a return, say that explicitly and the disclosure burden lightens.

---

## Answers to the five posed questions

1. Is the both-states rule sound, and does identical-across-estimators make the GMM and inversion averages the same estimand?
The both-states minimum-cell criterion is sound and, on the corrected sample, equal to a plain cell-size count (m1). Making the switcher *set* identical is necessary but not sufficient: the averages also depend on weights, base, and restricted-versus-unrestricted evaluation (M1), and the deeper equivalence presupposes LCA holds (C1). Hidden ways they still differ: weight vector (`num_s` versus equal), base trajectory, clustering unit (M5), and the restricted-line versus unrestricted-$\beta_s$ construction of the average.

2. Consequences of lumping into the unbalanced cell.
The unbalanced-cell coefficient becomes a mixture return over attrition individuals plus dropped thin switchers (m4). Lumping does *not* bias $\phi$, the never-migrant return, the average switcher return, or the always-migrant return through the moment algebra, because the unbalanced pair is a free just-identified absorber (m4). It does remove overidentifying restrictions from the Hansen $J$ (M2). Disclosure is directionally adequate but should name the mixture explicitly and report $J$ before and after.

3. Change A's individual-level restriction.
Dropping the whole individual (rather than the incomplete wave) discards four valid person-waves each and contradicts the "never discard" principle used for Change B (M4); this is the main concern, more than selection, since 0.1 percent is unlikely to move estimates. The no-op claim for per-spec subsetting is correct for the consumption main path given the protected-regressor union, but not automatically for income or hukou specs (m2).

4. Main-path (individual, 5) versus VV (cluster, 2) asymmetry.
"Consistent" is fair for the three headline estimators (GMM, OLS, inversion all use individual-5); it is a stretch as a global claim once the VV path uses a different unit and threshold. Threshold 2 is the degenerate floor for cluster-robust inference and rests on a not-yet-finalized cluster variable (M7), and it puts the VV estimator on a different switcher set than the main path (M6).

5. Settled things a referee would challenge / missed issues.
The estimand-equivalence claim (C1), the $J$-test weakening (M2), the self-defeating pre-filter for a weak-ID-robust procedure (M3), the cross-estimator clustering mismatch (M5), the VV set confound (M6), and the base-trajectory stability of the old-versus-new table (M1) are the main ones. The plan should also pin the base trajectory across the before/after runs so S-3 is apples-to-apples, since base selection is data-driven and the candidate pool changes with the keep-set.

---

## Overall assessment

The two changes are the right moves in intent: an internally inconsistent switcher set across three co-reported estimators is indefensible for Econometrica, and a balanced cell holding short-panel individuals is a genuine defect. The plan's mechanics (single Stata-authored keep-list, Design 2, lump-not-delete for thin switchers) are sound and carefully traced.

The identification strategy does not obviously break under these changes, and the reassuring result is concrete: because the unbalanced cell is a free just-identified absorber, lumping cannot bias $\phi$ or the extrapolated returns through the moment algebra. The exposure is at the level of what the paper *claims* the change achieves and what it does to the validation apparatus. Two claims a referee will press: that the GMM and inversion averages become "the same estimand" (true only under LCA, which the inversion is built to interrogate) and that the reconciliation is clean while the Hansen $J$ quietly sheds restrictions and Change A deletes valid data that Change B's own principle says to keep. Resolve C1, M2, and M4 before the freeze; M5 and M6 are the difference between a robustness comparison a referee trusts and one they read as confounded.

This assessment is a prompt for the researcher's judgment, not a substitute for it. In particular, C1 hinges on how the driver defines the inversion's reported average return, which I could not fully verify from the files read.
