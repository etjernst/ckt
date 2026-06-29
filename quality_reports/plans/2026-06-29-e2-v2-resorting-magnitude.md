# Plan --- E2 Version 2: hukou-removal resorting scenario (revision 2)

Date: 2026-06-29.
Spec: [2026-06-29-e2-v2-resorting-magnitude.md](../specs/2026-06-29-e2-v2-resorting-magnitude.md) (revision 2).
Branch: lca-inversion.
Status: revised draft, awaiting approval. Incorporates the /review-plan pass (three Reds, six Yellows, two Greens); changes marked [NEW]/[CHANGED] inline. Reading A adopted (the barrier sits in the baseline index, so $\sigma_\eta$ re-anchors jointly with $c$).

Tracks the revision-2 spec: a calibrated resorting scenario with a realized-shock rule, common-base normalization, payoff/cost separation, a within-trajectory $\theta$ distribution, two named scenarios, and the full diagnostic and reproducibility set.
All code is additive in `explorations/python-grc/counterfactuals.py` plus a thin Stata export; no edits to `run_cell`, `build_joint_ci_grid`, or any E1 path (spec M18/S4).

## Step 0 --- Confirmations and pre-registration (no code)

CC1 is resolved by the empirics (switchers force the realized-shock rule); no decision needed, only the two non-blocking paper edits flagged to coauthors ([PROPOSED-PAPER-EDITS](../reviews/2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md)).
CC2 is resolved (report both $\sigma_{\theta,d}$ calibrations).
Get user approval on the revised spec and this plan before coding.

[NEW] Pre-register, before seeing any output, the two gate tolerances so the headline decision carries no researcher degrees of freedom (review Y4):
- baseline-fit gate: a maximum absolute by-trajectory urban-choice-rate gap (modeled vs observed), conditioned on the empirical within-trajectory $T_i$ distribution;
- over-ID gate: a switcher-share band (model vs observed) at the anchored $\sigma_\eta$.
A run that breaches either gate may be reported but not headlined.

## Step 1 --- Inputs from the GRC sters (Stata side)

Confirm the rural-hukou and urban-hukou cells export, or can derive in Python, everything the scenario needs:
- $\beta^{rh}, \phi^{rh}$ and $\beta^{uh}, \phi^{uh}$ point estimates and their inversion-CI lattices (CHN_rf and CHN_uf joint-CI machinery already produces the accepted $(\phi,\beta)$ grids).
- Per-trajectory mean comparative advantage $\bar\theta_d$ (from $\mu_d - \mu_{\text{base}}$, in `CHN_rf_e1_mu_d.csv`) and shares $\pi_d$ (`CHN_rf_e1_traj.csv`).
- The common reference type $\mu_{\text{common}}$ for the $\tilde\beta$ transform. [CHANGED] Name three candidates explicitly --- the pooled never-migrant mean, the rh base, and the uh base --- and report the headline under each (review G1).
- Within-trajectory dispersion of individual rural log consumption for calibration 1, and the variance-decomposition pieces ($\theta$ vs $\tau$ vs $\varepsilon$) for calibration 2, both derivable in Python from the prepared sample / auxiliary OLS.
- Person-level never-migrant and switcher shares for the rural-hukou subsample (Python from `prepare_data`).
- [NEW] The empirical within-trajectory panel-length $T_i$ distribution; confirm it is recoverable from the `prepare_data` path as per-pid period counts (review G2), since the never-probability integral depends on it.

Extend `_export_e1_inputs_hukou.do` only for a scalar genuinely not already available ($\beta^{uh}, \phi^{uh}$, CI endpoints).
Prefer Python derivation to keep the Stata surface minimal.

## Step 1.5 --- Analytic prototype gate (Python, throwaway) [NEW]

Before building any envelope, persistence, prose, or figures, write a one-page prototype that evaluates the scenario at the point estimates only (review Y6):
- anchor $\sigma_\eta$ to the observed person-level never-share at the rh point estimate;
- run both scenarios (barrier-only, regime-convergence) at $c \in \{0, 0.5, 1\}$;
- compute the realized effect and the unrealized potential at each.
Gate the full build (Steps 4--10) on this prototype being coherent: finite, sign-sensible, and with the regime-convergence case not blowing up near the $\phi = -1$ pole (review Y1).
If it is incoherent, stop and rethink the estimand rather than building the machinery around a number nobody will trust.
This prototype is throwaway; it is not the deliverable.

## Step 2 --- Normalization and primitives (Python, additive)

- `common_base_intercepts(beta_g, phi_g, mu_base_g, mu_common)` -- the $\tilde\beta^g = \beta^g + \phi^g(\mu_{\text{common}} - \mu_{\text{base}^g})$ transform (M4); returns $\tilde\beta^{rh}, \tilde\beta^{uh}$ and the common-base wedge $\tilde\beta^{uh} - \tilde\beta^{rh}$.
- `theta_distribution(traj_df, sample, calibration, family)` -- returns, per trajectory, the mean $\bar\theta_d$ and the calibrated dispersion $\sigma_{\theta,d}$ under calibration 1 (consumption dispersion) or calibration 2 ($\tau$/$\varepsilon$-stripped) (M5), plus integration nodes/weights for the chosen $G_d$ family.
  [CHANGED] The $G_d$ family is an explicit maintained assumption, because the magnitude is driven by the tail of $G_d$, not by $\sigma_{\theta,d}$ alone (review Red 2): default to Gaussian (Gauss-Hermite nodes), justify it in the prose, and report headline sensitivity to at least one fatter-tailed alternative at matched variance (e.g. a scaled $t$ or a truncated form, integrated by its own quadrature).
  Gauss-Hermite is not a neutral numerical choice; it presupposes Gaussian tails, so the family must be named, not defaulted silently.
- `_choice_prob(F, payoff, kappa, sigma_eta)` -- standardized CDF of the choice index $(\text{payoff} - \kappa)/\sigma_\eta$; `F` injected (logit first, normal second) (M2).

## Step 3 --- The $\sigma_\eta$ back-out (Python, additive)

- `attainable_never_share(...)` -- the never-share limits as $\sigma_\eta \to 0$ and $\to \infty$ under the exact panel-length mixture (M7); defines the i.i.d. ceiling.
- `anchor_sigma_eta(target_never_share, c, ...)` -- bracketed root-find (Brent) on the person-level never-migrant share, integrating the per-type never probability over $G_d$ and the panel length $T_i$ (M6).
  [CHANGED] The baseline choice index carries the barrier $\kappa = c(\tilde\beta^{uh} - \tilde\beta^{rh})$ (Reading A: the observed world has the barrier), so $\sigma_\eta$ is re-anchored jointly with $c$ --- a different $\sigma_\eta$ root for each $c$ (review Red 1).
  $\sigma_\eta$ is therefore not separately identified from $\kappa$; the data fix the never-share, not the barrier-vs-shock split, and the reporting (Step 5) makes the $c$-dependence explicit rather than hiding it in a $c=1$ point.
  Guards: target strictly interior to the attainable range; scan the full range for sign changes and fail on multiple roots unless a pre-specified selection rule fires (M7).
- `overid_switcher_check(sigma_eta, ...)` -- model vs observed switcher share as a pass/fail with a pre-specified tolerance (M6).
- `baseline_fit(sigma_eta, ...)` -- observed vs modeled urban-choice rate by trajectory (M14).

## Step 4 --- Scenario evaluation (Python, additive)

- `resort_gain(scenario, c, sigma_eta, sigma_theta, F, ...)` -- for the chosen scenario (barrier-only $(\tilde\beta^{rh}, \phi^{rh})$ or regime-convergence $(\tilde\beta^{uh}, \phi^{uh})$, M10) and institutional fraction $c$ (so $\kappa = c(\tilde\beta^{uh} - \tilde\beta^{rh})$, M4/M11):
  - integrate baseline and counterfactual choice probabilities over $G_d$ with the chosen family's quadrature;
  - [CHANGED] the realized effect is the probability-weighted integral $\int \Delta(\theta)\,[P^{cf}(\theta) - P^{base}(\theta)]\,dG_d(\theta)$, not a simple average over a deterministic tail set (review Y3); with i.i.d. $\eta$ the flip is probabilistic and $\theta$-dependent, and this integral nets negative-return movers automatically, subsuming M9;
  - report the realized partial-equilibrium effect and the remaining unrealized potential as two separate objects, never summed (M8);
  - decompose into marginal-migrant and residual-never-migrant pieces.
  - [NEW] Regime-convergence runs near the $\phi = -1$ Mobius pole (the uf marginal $\phi$ sits below $-1$): evaluate this scenario at the uh point estimate first and confirm a finite, sign-coherent result; document the inverted (low-$\theta$) tail interpretation; exclude lattice points within a stated $\epsilon$ of $\phi = -1$ (review Y1).
- `HukouResortResult` dataclass -- the $\sigma_\eta$ anchor, the over-ID switcher gap, the baseline-fit table, the realized effect, the unrealized potential, the decomposition, the scenario, $c$, $\sigma_{\theta}$ calibration label, and shape.

## Step 5 --- Envelope and diagnostics (Python, additive)

- `run_hukou_resort(...)` -- the V2 analogue of `run_hukou_bound`.
  [CHANGED] The primary reported object is the resorting gain across the full $c \in [0,1]$ range, not a $c=1$ point (review Red 1): $c$ has no data discipline, so leading with a single $c$ contradicts the spec's own M11.
  Over the $c$ range and the other sensitivity axes ($\sigma_\eta$ log-spaced multiplicative grid, $\sigma_{\theta}$ both calibrations, $G_d$ family, logit and probit, both scenarios):
  - propagate the accepted $(\phi,\beta)$ inversion lattice through `resort_gain`, re-anchoring $\sigma_\eta$ jointly at each accepted point and each $c$ (M12, Reading A);
  - project the image to a conditional inversion envelope (reuse `project_image_intervals`), labeled as such, never "95% CI" (M12).
- [NEW] Local sensitivity panel (review Red 3, Andrews-Gentzkow-Shapiro): report a normalized elasticity $d(\text{headline})/d(\log \text{param})$ at the anchor for $\sigma_\eta$, $\sigma_{\theta}$, $c$, and $\mu_{\text{common}}$, as the cheap local complement to the global sweeps.
- [NEW] Calibrated-moment sampling uncertainty (review Y2): report the headline under a $\pm 1$ to $2$ SE perturbation of the never-share target and of $\sigma_{\theta}$ (the binomial SE on the share, the sampling SE on the dispersion), or document that it is dominated by the inversion width as E2-V1 did.
- Emit grid/root diagnostics: accepted-point count, points with valid/no/multiple roots, $\phi$/$\beta$ boundary touches, image islands, refinement sensitivity (M13).
- Add the $c$-monotonicity diagnostic (increasing $c$ weakly raises urban choice for the affected group, M11).

## Step 6 --- Persistence (Python, additive)

- `_hukou_resort_rows(hr)` -- long-format rows in the existing CSV schema: realized effect and unrealized potential (separately), decomposition, both scenarios, both $\sigma_\theta$ calibrations, both shapes, $\sigma_\eta$ anchor, over-ID gap, and the diagnostic counts.
- Wire into `results_dataframe` (append) and `run_all_cells` (new `hukou_resort` key).
- `write_hukou_resort_table(res, table_path)` -- self-contained LaTeX float; the notes disclose every calibrated knob (M17); every value formatted from the computed result, nothing hardcoded.
- Extend `run_counterfactuals_for_stata` with a `table_path_resort` param and a headline echo, as `table_path_hukou` was added.

## Step 7 --- Legacy-subset check, then regenerate the baseline (controlled)

- Before any baseline regeneration, run a legacy-subset equality check: filter fresh and committed baseline to the pre-existing E1/E2-V1 keys, assert near-exact equality on those rows, and assert the only new rows are V2 (M16).
- Only then run once with `regenerate_baseline=True` (temporary driver edit, reverted) and confirm the baseline git diff is purely additive.

## Step 8 --- Stata driver + run

- `12_counterfactuals.do`: pass `table_path_resort`, confirm the new table writes.
- Run via `stata-mp -e do 12_counterfactuals.do` from `RP7/scripts`.
- Confirm "self-check passed" and the legacy-subset check in pure Python (no Stata lock), per the V1 exit-hang gotcha.

## Step 9 --- Paper prose (local paper/, not Overleaf)

- Rewrite `paper/results_counterfactuals.tex` lines 139--157 from subjunctive into reported results: the realized effect, the unrealized potential (separately), the two named scenarios, the $\sigma_\eta$ grid dependence, the two $\sigma_\theta$ calibrations, the $c$ sensitivity, and the conditional-inversion-envelope language.
- Fold in the calibration caveats (S3) and the Edit 2 limitation text from [PROPOSED-PAPER-EDITS](../reviews/2026-06-29_e2-v2-PROPOSED-PAPER-EDITS.md); Edit 1 (model-section clarification) is applied by the user in Overleaf, not here.
- [NEW] Add a one-sentence flag that $\eta \perp \theta$ (the non-pecuniary shock is independent of comparative advantage) is a maintained calibration assumption; if urban taste correlates with $\theta$, the resorting selection is biased (review Y5).
- [NEW] Lead the prose and table with the $c$-range, and state that the data pin the baseline never-share but cannot separate barrier from shock, so $c$ indexes an assumption, not an estimate (review Red 1).
- `\input` the new table; one sentence per source line; LaTeX notation; American English.

## Step 10 --- Appendix figures (MAY1)

- $\sigma_\eta \times c$ and $\sigma_{\theta,d} \times c$ heatmaps, following figure-design rules (no in-figure title, caption in LaTeX, direct labels, muted palette).

## Step 11 --- Review and verify

- Logit back-out reproduces the person-level never-share at the point estimate (S2); root uniqueness confirmed (M7); baseline-fit acceptable by trajectory (M14).
- Both scenarios, both shapes, both $\sigma_\theta$ calibrations produced; sensitivity bands populated.
- Legacy-subset equality green; E1/E2-V1 byte-identical; baseline diff additive (M16).
- `12_counterfactuals.do` clean via `stata-mp -e`; pure-Python self-check green.
- Hand-check one grid point against a by-hand logit-probability and payoff-integral calculation.
- critic-python on the harness diff; critic-writing on the paper prose; verifier on the table compile.
- Quality gate: 80 to commit, 90 for the section to be PR-ready.

## Step 12 --- Session log

- Decisions with the why (the CC1 empirics resolution, CC2 two calibrations, the A2/A3/A4/A5 framing), files changed, open items, how to resume.

## Risk register

- [CHANGED] Re-anchoring $\sigma_\eta$ at every accepted lattice point AND every $c$ multiplies root-finds further (Reading A); cache the anchor as a function of $(\phi,\beta,c)$ on the accepted lattice if runtime balloons (M12).
- [NEW] The $G_d$ tail, not just $\sigma_{\theta}$, drives the magnitude; a silent Gaussian choice would understate a fat tail. The family is named and a fatter-tailed alternative is reported (Step 2).
- [NEW] $c$ has no data discipline and the gain scales with it; leading with the $c$-range rather than $c=1$ keeps the reporting honest (Step 5/9).
- [NEW] The analytic prototype (Step 1.5) gates the full build, so an incoherent estimand is caught before the machinery, prose, and figures are written.
- The logit/probit gap may exceed the inversion width in the targeted tail; both shapes are produced before promotion (S1), so it is visible.
- Calibration-1 over-states tail selection (the upper proxy); calibration 2 leans on the $\theta$/$\tau$ separation; reporting both brackets the truth (M5).
- Multiple $\sigma_\eta$ roots or boundary-touching accepted regions can create artificial endpoints; the root and grid diagnostics (M7/M13) surface this rather than hiding it in a convex hull.
- The common reference type $\mu_{\text{common}}$ is a stated choice; document it and check the wedge is not sensitive to a reasonable alternative.
