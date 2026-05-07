# TODO: Explore Verdier (2020) Section G unbalanced-panel approach

**Date:** 2026-04-23
**Status:** Parking note --- not for current revision

## What Verdier does

Verdier (2020), online appendix Section G (one page, pp. 44--45), handles unbalanced panels in the CRC/GRC framework by:

1. Assuming unconditional MAR: $o_{it} \perp$ (all model variables), where $o_{it} = \mathbb{1}\{(i,t) \text{ observed}\}$.
2. Redefining stacked vectors to include only observed $(i,t)$ pairs: $Y_i = [y_{it}]_{t: o_{it}=1}$, and similarly $W_i, Z_i, X_i$.
3. Redefining "movers" as individuals with treatment variation **across observed periods** ($\exists t,s$ with $o_{it}=o_{is}=1$ and $x_{it} \neq x_{is}$).
4. Estimating $\gamma$ via a pooled linear regression of $y_{it}$ on cross-section dummies, cross-section dummies interacted with treatment, and $z_{it}$, using all observed $(i,t)$ pairs.
5. Running step-2 GMM on mover moments, pooling separately per time period $t$.

No $U_i$ indicator. No $\pi$ coefficient. No "unbalanced stratum" as a separate group.

## Why we're not adopting it now

CKT's pooled-cell approach (current Proposition~\ref{prop:pooling}) is defensible, internally consistent, and already written up. Switching to Verdier's approach would require:

- Re-defining trajectory cells in `0_programs.do::handle_trajectory_groups` from full-sequence trajectories to observed-sequence trajectories.
- Re-implementing the GMM instrument system to match Verdier's step-1/step-2 decomposition.
- Updating Propositions~1 and the restricted-GRC section to use within-individual demeaning or cross-section dummies.
- Re-running all estimates on CFPS, IFLS, TZNPS.

This is a multi-week implementation effort with uncertain payoff.

## What might be worth exploring

- **Efficiency comparison.** Does Verdier's observed-periods approach deliver tighter standard errors for $\Delta_{\underline d}$ than the pooled-cell approach? For CKT's data, where unbalanced observers are 88--96% non-switchers, the answer is probably no --- most unbalanced observers wouldn't count as "movers" under Verdier's definition either. But a simulation would settle it.

- **Weaker MAR requirement?** Verdier's MAR is strictly stronger (unconditional vs. conditional on $x$). CKT's conditional MAR is more realistic for migration panels. If the main concern about our approach is the common-$\gamma$ assumption rather than MAR, Verdier's approach does not buy us anything.

- **Trajectory cell enrichment.** Under Verdier's scheme, an individual observed in only 2 of 4 waves with a single migration switch still contributes to trajectory identification. This could bring more observers into the switcher pool. For IDN (5 waves), this matters; for TZA (3 waves), much less.

- **Referee preference.** Some referees familiar with Verdier (2020) may find his approach more natural. Citing him and explaining our choice (as we now do in the proposition text) should preempt this. But if a referee explicitly asks for Verdier's approach, having a simulation comparison ready would be valuable.

## Next steps (if we pick this up)

1. Draft a skeleton revision of `0_programs.do::handle_trajectory_groups` that defines trajectories over observed periods.
2. Write a small-scale Monte Carlo comparing pooled-cell vs. Verdier's approach under MAR and under mild MNAR.
3. Compare on a single country (probably IDN given the wave coverage).
4. Decide whether to switch on empirical grounds or leave the current approach with a clear Verdier citation.

## Existing infrastructure we can reuse

`0_programs.do` already contains `handle_trajectory_groups_2waves` (lines 257--310) and `handle_trajectory_groups_3waves` (lines 315--367) that build trajectory labels from each individual's **observed** wave sequence, skipping missing periods. Each program classifies the resulting observed-sequence as switcher or non-switcher via the long `replace` statements at lines 299--300 and 356--357.

These labels currently feed only into `data_setup_2waves` / `data_setup_3waves` (lines 73--122) and from there into `4_trajectory_bar_graph.do` --- i.e., they are used for the migration-patterns figure, not for the GMM. The GMM estimator in `run_grc` (line 1538) uses the plain `trajectory` variable, which `handle_trajectory_groups` builds only from balanced observers (line 199: `keep if !unbalanced`).

A Verdier-spirit (not Verdier-exact) extension within CKT's framework would:

1. Replace the `keep if !unbalanced` in `handle_trajectory_groups` with `keep if pid_obs >= 3` (or 2), borrowing the structure of `handle_trajectory_groups_3waves`.
2. Let observed-always-rural and observed-always-urban unbalanced observers attach to the never-migrant and always-migrant cells.
3. Let observed switchers attach to switcher cells indexed by their observed sequence.
4. Keep the $U_i$ pooled-cell treatment only for observers with 1--2 observed waves.

This leaves the trajectory-cell GMM structure intact and mostly eliminates the "unbalanced stratum" as a separate object. The common-$\gamma$-across-strata assumption becomes vacuous (no strata); common-$\gamma$-across-trajectories remains (but that's already A4).

**Caveat.** Under MAR, observed-sequence trajectory means are MAR-weighted averages over full-sequence trajectory means. An observed "0-then-1" cell in a 3-of-5 waves pattern is a mixture of full-sequence cells "$01XYZ$", "$X01YZ$", etc. The $\mu$ identified from observed-sequence cells is the population mean over this mixture, not the full-sequence-specific mean. Interpretation of $\mu_{\underline d}$ becomes stratum-aware in a different sense. This is what Verdier's footnote 32 glosses with "treat data as missing at random" --- a clean way to handle it formally would require reworking the identification section.

**Cost estimate.**

- `handle_trajectory_groups` rewrite: 1--2 hours.
- `define_switcherpars` / `initial_values` / `run_grc` adjustments for extended trajectory set: 1 day.
- Re-estimation and robustness on CHN/IDN/TZA: 1 day.
- Proposition and identification-section rewrite: 1--2 days.
- Total: ~1 week of focused work, not the multi-week rewrite I originally estimated.

## Verbatim source

Verdier (2020), online appendix, Section G, pp. 44--45. PDF at `papers/extracted/verdierAverageTreatmentEffects2020appendix/verdierAverageTreatmentEffects2020appendix.pdf`. Paper-pipeline summary at `papers/summaries/verdierAverageTreatmentEffects2020appendix.md`.

Main-text footnote 32 (p. 24 of Verdier 2020):
> "Here we observe four time periods but an unbalanced panel. We treat data as missing at random. Every cross-sectional observation with three or more observed time periods participates in the estimation of the coefficients $g_t$, regardless of whether they are stayers or movers. Among cross-sectional observations with only two observed time periods, only stayers participate in the estimation of the coefficients $g_t$."

This sliding-window rule (3+ waves contribute to $g_t$; 2-wave observers contribute only as stayers) is a further refinement of the Section G framework that we should look at if we explore this.
