# Plan: counterfactual experiments

**Date:** 2026-05-18.
**Branch:** lca-inversion.
**Mode:** Implementation (per workflow.md, Mode 2).
**Inputs:** design memo at [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md); paper-side draft at [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex); existing inversion machinery at [explorations/python-grc/lca_inversion.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/lca_inversion.py) and `attach_inversion_ci` in [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do).

This plan converts the design memo into concrete deliverables: scripts, programs, output tables and figures, an inference protocol that propagates the inversion CI, and validation checks at every milestone.
It is the implementation companion to the memo; the memo is the design rationale.

## Decisions resolved (2026-05-18)

The 2026-05-18 methods review surfaced seven open decisions; all are now resolved.
The detailed walkthrough lives in the HTML overview at [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html) and the consolidated punch list at [docs/reviews/2026-05-18_counterfactual-plan-consolidated.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/reviews/2026-05-18_counterfactual-plan-consolidated.md).
Summary of dispositions:

- **A1** (Option 2 disposition): collapse Option 2 into the $c = 1$ point of Option 3 envelope.
  No standalone Option 2 magnitude.
  Option 3 reformulated as a direct Gaussian sweep on within-trajectory dispersion of $\theta_i \mid d_N$ (no decision-rule construction, no $F_\eta$ dependence).
- **A2** ($\sigma_\eta$ identification): defer entirely.
  E1 Option 3 does not need $\sigma_\eta$ after the A1 reformulation.
  E2 resort needs $\sigma_\eta$ and reports the magnitude as a curve over a justified $\sigma_\eta$ grid rather than a single number.
- **A3** (logistic vs normal): report both as parallel headlines.
  At each $\sigma_\eta$ on the E2-resort grid, simulate under both type-I EV and normal shocks.
- **A4** (hukou wedge reading): Reading A as headline (full intercept gap is institutional).
  Reading B (continuum) kept as a sensitivity figure.
  Revisit if the four-source decomposition of $\beta^{rh} - \beta^{uh}$ turns out to drive the magnitude.
- **A5** (empty joint CI cells): report only the parts of the aggregate that do not depend on the rejected LCA piece.
  $W_{\text{obs}} - W_{\text{zero}}$ stays; $W_{\text{opt}} - W_{\text{obs}}$ drops when the joint CI is empty.
- **A6** (out-of-support diagnostic): yes, add D4.
  First-pass visual diagnostic produced 2026-05-18; results in [docs/notes/2026-05-18_extrapolation_support_diagnostic.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-18_extrapolation_support_diagnostic.md).
  All three countries have $\hat\mu_{d_N}$ interior to the switcher hull; TZA is the boundary case at 8% in.
- **A7** (Experiment 3 status): defer entirely.
  Paper draft updated to subjunctive on the Suri-Route-A welfare extension.

The §"Estimands", §"Inference protocol", §"Risk register", §"Diagnostics", and §"Open issues" sections below have been revised to reflect these dispositions.

## Scope and non-goals

In scope:

- Experiment 1 (E1): aggregate misallocation accounting (three reporting options) plus the zero-migration lower extreme.
- Experiment 2 (E2): hukou wedge for CHN, both the lower bound from identified objects and the resorting version under a parametric shock distribution.
- Inference: convex hull of the misallocation gap over the joint $(\phi, \beta)$ inversion CI, separately per country and per spec.
- Output: country-level table of $(W_{\text{obs}} - W_{\text{zero}}, W_{\text{opt}} - W_{\text{obs}})$ with CI, decomposed by $\{d_N, \mathcal{D}_S, d_T\}$, with all three reporting options for the optimal-sort piece; CHN hukou counterfactual table with bound and resorting versions, type-I EV and normal shock distributions.
- Two new top-level scripts (`12_counterfactuals_misallocation.do`, `13_counterfactuals_hukou.do`), one new Python helper (`explorations/python-grc/counterfactuals.py`), and shared programs added to `0_programs.do`.
- Integration into `0_master.do` behind a switch so the counterfactuals run only when explicitly requested (compute cost is small, but the resorting version is several seconds per country).

Out of scope for this plan (will be planned separately):

- Experiment 3 Route A (Suri-style observable proxies for non-pecuniary value). Requires a catalog of observables in CFPS / IFLS / TZNPS that is not yet built. See open issue O5.
- Experiment 3 Route B (parametric Heckman-style $\sigma_\eta$ identification from trajectory shares). Touches the same machinery as E2 resorting and may end up sharing code, but the identification step (matching observed $\pi_{d_T}$ to a model-implied probability) is its own piece; defer to a follow-up plan.
- Borjas factor-structure benchmark.
- Updating the paper draft beyond the existing [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) (Overleaf section file is untouched per the STOP-READ-FIRST rule).

## Identified objects (audit before any code)

Every quantity below must trace to a `.ster` file or a panel descriptive.
Audit script `_smoke_counterfactual_inputs.do` will print each object per country / spec and halt if any is missing or NaN.

Per country $c \in \{\text{CHN}, \text{IDN}, \text{TZA}\}$ and primary spec (col 5, `consumption`, `urban`, `unb`):

| Symbol | Source | Status |
|---|---|---|
| $\pi_{\underline{d}}$, trajectory share | descriptive on the estimation sample | derive in script |
| $\bar{D}_{\underline{d}}$, urban time share within trajectory | deterministic from trajectory definition | derive in script |
| $\mu_{\underline{d}}$, trajectory rural mean | unrestricted GRC (`uGRC*.ster`) | in hand |
| $\Delta_{\underline{d}}$, switcher trajectory return | unrestricted GRC | in hand |
| $(\phi, \beta)$ point estimates and inversion CI grid | restricted GRC plus inversion (`*_g.ster` plus inversion-side cache) | in hand |
| $\Delta_{d_T}$ inversion CI | `grid_delta_always_md_inversion` output | in hand |
| $\Delta_{d_N}$ point and CI | LCA extrapolation evaluated on the inversion CI grid | derive in script |
| $\sigma_\theta^2$ (cross-trajectory variance of $\mu_{\underline{d}}$, weighted by $\pi_{\underline{d}}$) | descriptive | derive in script |

CHN pooled spec returns no $\Delta_{d_T}$ inversion CI (the $J$-test rejects, the inversion is empty).
The audit script reports this case as "no pooled output, will skip and report regime-by-regime."
The hukou-split sters (`grc_chn_hukou_*`) carry their own inversion CIs and feed E2 directly.

## Estimands

Indexing convention.
$\underline{d}$ ranges over the trajectory set $\mathcal{D}$ defined in the model section: $d_N$ (never-urban), $d_T$ (always-urban), and the switcher trajectories $\mathcal{D}_S = \mathcal{D} \setminus \{d_N, d_T\}$.
$\pi_{\underline{d}}$ are normalized to sum to one over $\mathcal{D}$.
For unbalanced specs we follow [reference_unbalanced_lumps_trajectories.md](file:///C:/Users/maand/.claude/projects/C--git-ckt/memory/reference_unbalanced_lumps_trajectories.md): the switcher subset is lumped into a single trajectory, so $|\mathcal{D}_S| = 1$ in the headline spec.
Balanced specs enumerate switchers per trajectory and will be reported as a robustness check (E1.4).

E1 primary estimands per country $c$:

1. $W_{\text{obs}} - W_{\text{zero}} = \sum_{\underline{d}} \pi_{\underline{d}} \, \Delta_{\underline{d}} \, \bar{D}_{\underline{d}}$.
   The $d_N$ term contributes zero because $\bar{D}_{d_N} = 0$.
   The $d_T$ term contributes $\pi_{d_T} \cdot \Delta_{d_T} \cdot 1$.
   The switcher term contributes $\pi_{\mathcal{D}_S} \cdot \Delta_{\mathcal{D}_S} \cdot \bar{D}_{\mathcal{D}_S}$ in the lumped unbalanced case, summed across switchers in the balanced case.

2. $W_{\text{opt}} - W_{\text{obs}} = \sum_{\underline{d}} \pi_{\underline{d}} \left[\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}} \bar{D}_{\underline{d}}\right]$ (Option 1, conservative floor).
   By construction, Option 1 is a lower bound on the gap whenever within-trajectory dispersion in $\Delta_i$ is nonzero, by Jensen on the convexity of $\max(0, \cdot)$.

3. Option 3 (bounded envelope, A1 decision): parameterize $\theta_i \mid d_N \sim N(\hat\mu_{\theta \mid d_N}, (c \cdot \sigma_\theta)^2)$ directly, integrate $\max(0, \beta + \phi\theta)$ against that density, and report the gap as a function of $c \in \{0, 0.25, 0.5, 0.75, 1.0\}$.
   $\hat\mu_{\theta \mid d_N}$ is the value at which the LCA line passes through $\hat\Delta_{d_N}$ (i.e., $(\hat\Delta_{d_N} - \beta)/\phi$).
   $\sigma_\theta$ is the weighted cross-trajectory variance of $\mu_{\underline{d}}$, which is an upper bound on the population variance by the law of total variance (between-group variance bounds total).
   At $c = 0$, recovers Option 1; at $c = 1$, recovers the integration that the original Option 2 attempted, without the decision-rule construction that A1 discarded.
   No standalone Option 2 magnitude is reported.
   The $\theta_i$ Gaussian assumption is auxiliary, not implied by the GRC; report sensitivities with $t_5$ and shifted log-normal alternatives.
   No $F_\eta$ enters this envelope (A2 deferral consequence).

E2 primary estimands (CHN only):

5. Lower bound: $\pi^{rh} \cdot \pi_{d_N}^{rh} \cdot \Delta_{d_N}^{rh}$, where $\pi^{rh}$ is the rural-hukou share of the CHN sample, $\pi_{d_N}^{rh}$ is the never-migrant share within the rural-hukou regime, and $\Delta_{d_N}^{rh}$ is from the regime-specific extrapolation $\beta^{rh} + \phi^{rh}(\mu_{d_N}^{rh} - \mu_{\underline{d}_0}^{rh})$.
   Reported with the regime-specific base $\underline{d}_0^{rh}$ used in the existing hukou tables, and as a sensitivity with a common base re-estimated for the counterfactual.

6. Resorting version: simulate the choice rule from `eq:decision-rule` on the rural-hukou subpopulation under the parameter pair $(\phi^{rh}, \beta^{uh})$ (Reading A: full intercept gap is institutional, per A4 headline).
   Compute the share who select urban under the no-barrier rule, the consumption gain to each marginal mover, and the aggregate.
   Decompose into marginal-migrant piece and residual-stayer piece.
   Under A2 (defer $\sigma_\eta$), the simulation reports the aggregate as a *curve* in $\sigma_\eta$ on a justified grid rather than a single number.
   At each $\sigma_\eta$ on the grid, run the simulation under both logistic (type-I EV difference) and normal shocks (A3: parallel headline reports), so the figure carries two curves per country and the reader sees both scale and shape dependence.

7. Optional E2 sensitivity: parameterize the barrier as a continuum $\beta(c) = (1 - c) \beta^{rh} + c \beta^{uh}$ for $c \in [0, 1]$ and plot the aggregate gain as a function of $c$.
   Reports the half-removed and fully-removed wedge magnitudes; the audience can read off intermediate policy scenarios.

## Auxiliary assumptions and their testability

The counterfactuals add several auxiliary assumptions on top of CKT's A1-A5 from `sec_model.tex`.
Each is listed here with its scope, the testable implication if any, and how the production pipeline handles it.

**AA1.** *Time-invariant $\theta_i$ + LCA cross-piece consistency*: the LCA-identified $(\phi, \beta)$ holds simultaneously for $\Delta_{d_N}$ (extrapolation), $\Delta_{d_T}$ (inversion), and every switcher trajectory.
**Testable** via Hansen's $J$ on the restricted GRC; the existing pipeline already runs this and reports per-(country, spec) $p$-values.
Production handling: report the $J$-stat row in T1; per A5, drop the LCA-dependent piece of the aggregate when the joint CI is empty (model rejected at $\alpha$).

**AA2.** *LCA holds off the switcher support of $\mu_{\underline{d}}$*: the LCA line $\Delta_i = \beta + \phi\theta_i$ fit from switcher trajectory means extrapolates correctly to $\mu_{d_N}$ (and $\mu_{d_T}$).
**Untestable** with the data in hand---this is the deeper R6 concern.
Production handling: D4 reports where $\mu_{d_N}$ sits relative to the switcher hull; T1 footnote flags out-of-hull or near-boundary cases (TZA is the live boundary case per A6 first-pass result).

**AA3.** *Trajectory-conditional ATE = trajectory-conditional realized-return mean*: $\Delta_{\underline{d}}$ as identified by the unrestricted GRC equals the population mean realized urban return for trajectory $\underline{d}$.
**Implied by AA1 plus the model's A1-A5 (time-invariant $\theta_i$ and trajectory pinning the full $D_{it}$ sequence)**, so not a new assumption beyond what the model already maintains.
Production handling: stated explicitly in the paper-side text and §"Estimands" of this plan.

**AA4.** *$\theta_i$ marginally Gaussian for the Option 3 envelope*: $\theta_i \mid d_N \sim N(\hat\mu_{\theta \mid d_N}, (c\sigma_\theta)^2)$ for the within-trajectory integration.
**Auxiliary, not implied by the GRC.**
**Partially testable** through the moments of the unrestricted-GRC $\mu_{\underline{d}}$ ranks; full distributional testability requires the within-trajectory dispersion which is itself unidentified.
Production handling: D6 reports sensitivities under $t_5$ and shifted log-normal alternatives (Py-mod 3 hooks); paper-side text flags this as an auxiliary parametric assumption that the Option 1 floor does not require.

**AA5.** *$\sigma_\theta$ pinning from cross-trajectory variance of $\mu_{\underline{d}}$*: the cross-trajectory variance is used as the upper-bound scale parameter in the Option 3 envelope.
**Implied by the law of total variance** as a between-group variance, which is a lower bound on $\text{Var}(\theta_i)$.
Production handling: $c$ in Option 3 sweeps the dispersion ratio; D6 reports both the unbalanced 3-cell variance and the balanced-sample enumerated-trajectory variance side by side.

**AA6.** *Removing hukou maps $\beta^{rh} \to \beta^{uh}$*: the full intercept gap is attributed to the institutional barrier (A4 Reading A).
**Untestable** with the data in hand because the four-source decomposition (pecuniary premium net of cost-of-living; cost-of-living difference; compensating differentials; residual selection) is not separately identified.
Production handling: Reading A as headline; appendix figure (Reading B continuum) sweeps the institutional fraction over $c \in [0, 1]$.
Decision A4 carries an explicit revisit clause if the four-source decomposition turns out to drive the magnitude.

**AA7.** *Comparable $F_\eta$ distributions across hukou regimes*: the $\nu^U - \nu^R$ distribution is the same for rural-hukou and urban-hukou holders, conditional on covariates.
Needed for the resort version of E2.
**Untestable** at the per-regime moment level given the small switcher pools.
Production handling: stated explicitly in the paper-side text; the E2-resort curve is reported as a function of $\sigma_\eta$ which absorbs scale uncertainty if not identification uncertainty.

## Inference protocol

The natural inference object is the convex hull of the counterfactual evaluated over the joint $(\phi, \beta)$ inversion CI region, not asymptotic standard errors.
This protocol is shared across E1 and E2 because the same Möbius pole at $\phi = -1$ that motivates inversion CIs for $\Delta_{d_T}$ and $\Delta_{d_N}$ also breaks delta-method inference for the aggregates.

Step P1.
Construct the joint inversion grid.
The existing inversion machinery returns a marginal CI for $\phi$ via `grid_lca_inversion` and a marginal CI for $\Delta_{d_T}$ via `grid_delta_always_md_inversion`.
The joint $(\phi, \beta)$ confidence region is the set of $(\phi, \beta)$ pairs at which the constrained $J$ statistic (the GMM objective minimized over nuisance parameters at fixed $(\phi, \beta)$, or the MD analog already implemented in `_md_constrained_wald`) is below the chi-squared $1 - \alpha$ quantile with $\text{dof} = |\mathcal{D}_S| - 1$ matching `grid_lca_inversion`.
Constrained $J$ rather than Wald: Wald-type CIs are not weak-ID-robust (Stock-Wright 2000, Andrews-Mikusheva 2016), and the entire motivation for grid inversion is weak identification near the Möbius pole at $\phi = -1$.
We will construct this region in `explorations/python-grc/counterfactuals.py::build_joint_ci_grid`, reusing the auxiliary GMM machinery already used by `_md_constrained_wald`.
Grid resolution: $\phi$ on the existing inversion grid (typically 401 points spanning $[-2, 1]$), $\beta$ on a *fixed wide* grid centered at $\hat\beta$ with bounds derived by sweeping outward at $\phi = \hat\phi$ until the constrained $J$ rejects, then padding 50%.
The fixed-grid choice replaces the original adaptive-from-marginal-SE specification because the marginal SE on $\hat\beta$ diverges near the pole and is uninformative exactly where the joint CI matters most.
Report grid-saturation diagnostics: if the accepted region touches a $\beta$ grid endpoint, flag the CI as "extends beyond grid" in D2.

Step P2.
At each accepted $(\phi, \beta)$ in the joint CI grid, compute the full counterfactual: $\Delta_{d_N}(\phi, \beta), \Delta_{d_T}(\phi, \beta)$ via LCA, then the aggregate $W_{\text{opt}} - W_{\text{obs}}$ from estimand (2) and the value-of-observed-migration $W_{\text{obs}} - W_{\text{zero}}$ from estimand (1).
$\Delta_{\underline{d}}$ for $\underline{d} \in \mathcal{D}_S$ is held at its non-parametric point estimate (it is not constrained by LCA; we sweep only the LCA-restricted parameters).
$\pi_{\underline{d}}$ and $\bar{D}_{\underline{d}}$ are descriptives and do not move with $(\phi, \beta)$.

Step P3.
Report the inversion CI for the aggregate as the image $g(\mathcal{C}_{1-\alpha})$ of the joint CI under the aggregate functional $g$.
This is projection inference in the Kaido-Molinari-Stoye (2019) sense: $\{(\phi_0, \beta_0) \in \mathcal{C}\} \subseteq \{g(\phi_0, \beta_0) \in g(\mathcal{C})\}$, so $g(\mathcal{C})$ has coverage at least $1 - \alpha$ for $g(\phi_0, \beta_0)$.
Validity requires (a) continuity of $g$ on the joint CI region and (b) connectedness of $\mathcal{C}$, or, when (b) fails, careful handling of the image.
Near the Möbius pole at $\phi = -1$, $g$ is unbounded along any path crossing the pole; the edge-case handling below restricts the aggregate to $d_N + \mathcal{D}_S$ when the CI brushes $-1$ so $g$ stays continuous on the reported region.
When the image $g(\mathcal{C})$ is disconnected (a finite union of intervals), report the union via `find_islands` applied to a fine grid of $g$-values, matching the convention `format_islands_tex` uses for $\Delta_{d_T}$.
The convex hull of the union is a defensible conservative fallback only when the user prefers a single interval; flag both representations in the output table.

Step P4.
Code-consistency sanity check on the propagation pipeline.
At every $(\phi, \beta)$ accepted in the joint CI grid, the implied $\Delta_{d_N}(\phi, \beta) = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$ must lie inside the cached marginal *profile* CI for $\Delta_{d_N}$ stored in the `*_n.ster` (produced by `grid_delta_never_md_inversion`).
Reason: the cached marginal CI profiles out the nuisance parameter via $\min$ over `phi_search_grid`, and the joint-accepted set is a subset of the profile-accepted set, so set inclusion is the right invariant.
This is *not* a coverage check; it is a check that the code projects the joint CI correctly through the LCA formula.
Halting condition: any joint-accepted $(\phi, \beta)$ that maps to a $\Delta_{d_N}$ outside the cached profile CI indicates a bug in the grid construction or the chi-squared dof, and halts the script with a diagnostic in `output/counterfactual_diagnostics/marginal_ci_check_*.csv`.
Drop the original 10% half-width tolerance: it conflated propagation arithmetic with coverage and admitted bugs under 10% and rejected legitimate projection-vs-profile differences over 10%.

Step P5.
Aggregate the gap into both log-point and percent units.
Log points are immediate.
Percent: $\exp(W_{\text{opt}} - W_{\text{obs}}) - 1$, labeled as "change in geometric-mean consumption" (not "change in arithmetic-mean consumption").
The aggregate $W$ is mean log per-capita consumption, so $\exp(\Delta W)$ is the geometric-mean ratio.
Arithmetic-mean consumption gains differ by a Jensen-style correction whose sign depends on whether the reallocation compresses or expands the within-country consumption distribution; the geometric-mean reading is the cleanest given the linear-in-logs model.
Report both for the primary table; the percent column carries the "geometric-mean change" label and the gap between geometric and arithmetic means goes in a methods footnote.

Edge case.
If the inversion CI for $\phi$ brushes $-1$ (the Möbius pole), $\Delta_{d_T}$ is unbounded and the aggregate inherits the singularity.
The protocol in that case: report the aggregate restricted to the $d_N + \mathcal{D}_S$ contributions, flag that the $d_T$ piece is non-finite in the CI, and (only for that country / spec) report the point-estimate $d_T$ piece in a footnote rather than in the main table.
The TZA col 5 case in the back-of-envelope ($\Delta_{d_T} \approx -0.66$ with a wide CI) is the live example of this edge.

Step P6.
$\sigma_\eta$ propagation under A2 (defer).
E1 Option 3 has no $\sigma_\eta$ dependence after the A1 reformulation, so $\sigma_\eta$ does not propagate into the E1 aggregate.
For E2 resort, $\sigma_\eta$ is unidentified in this round; the deliverable is a curve over a $\sigma_\eta$ grid rather than a single magnitude.
At each grid point of $\sigma_\eta$, the resort simulation produces an aggregate.
The grid spans $\sigma_\eta \in \{0.1, 0.25, 0.5, 1.0, 2.0\}$ in log-consumption units, justified by the cross-country range of $\hat\Delta_{\underline{d}}$.
The figure F2 carries two curves per country (logistic and normal shocks per A3) and reports the inversion-CI band of the aggregate at each $\sigma_\eta$ point (propagation per P7 below).

Step P7.
E2 resort CI propagation through Py-mod 4.
At each $\sigma_\eta$ on the grid, propagate the joint $(\phi^{rh}, \beta^{rh})$ CI through the resort simulation under the parameter pair $(\phi^{rh}, \beta^{uh})$ where $\beta^{uh}$ is at its point estimate (A4 Reading A: full intercept gap is institutional).
$\beta^{uh}$ uncertainty enters only through Reading B continuum sensitivity, which is a separate figure.
Procedure: for each $(\phi^{rh}, \beta^{rh})$ in the joint CI grid (constructed exactly as in P1 but using the rural-hukou subsample's restricted GRC), and at each $\sigma_\eta$ on the grid, run the simulation under common random numbers (a fixed $N \times S$ shock matrix seeded once at the start of the country's run, reused at every grid point).
CRN reduces the Monte Carlo variance of the propagated CI by 1--2 orders of magnitude compared to fresh draws per grid point.
Aggregate the result via the image of the joint 2D CI under the simulated $g$, reported as in P3.
Monte Carlo SE target: at the point estimate, the aggregate should move by less than 10% of the inversion-CI half-width when $S$ doubles from 10{,}000 to 20{,}000; if not, increase $S$.

## Cross-cutting infrastructure

New programs added to [RP7/scripts/0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do).

P-prog 1.
`extract_trajectory_aggregates`: takes a country and spec, reads the estimation sample, computes $\pi_{\underline{d}}$, $\bar{D}_{\underline{d}}$, the sample size per trajectory, and the trajectory codebook (mapping integer codes to the urban-time pattern).
Writes a tempfile that the Python helper consumes.

P-prog 2.
`extract_lca_params`: takes a ster file path, returns $(\hat\phi, \hat\beta, \mu_{\underline{d}_0})$ and the inversion-side grid stored on the ster (or recomputed if absent).

P-prog 3.
`call_counterfactual_py`: thin wrapper around the Python helper that handles the temp-file plumbing and reads back the result table.
Mirrors the structure of `attach_inversion_ci` (existing similar wrapper, see [0_programs.do:3597](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do)).

P-prog 4.
`render_counterfactual_table`: assembles the LaTeX table from the Python output.
Pattern matches `grc_tex_table_trend` so the output style is consistent with the rest of the paper.

New Python module at [explorations/python-grc/counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py).

Py-mod 1.
`build_joint_ci_grid(phi_grid, beta_grid, gmm_inputs, alpha=0.05) -> np.ndarray`.
Returns a boolean mask over the $(\phi, \beta)$ lattice marking the joint CI region.
Inverts the constrained-$J$ statistic (per P1), with chi-squared $1-\alpha$ cutoff at $\text{dof} = |\mathcal{D}_S| - 1$ matching `grid_lca_inversion`.
Reuses the `_md_constrained_wald` helper from `lca_inversion.py` (the function's name is historical; it implements the MD constrained-$J$ analog that grid-inversion uses throughout).
Also returns an island-decomposition of the accepted set (a list of connected components on the lattice via flood-fill) for use in P3's image reporting.

Py-mod 2.
`evaluate_aggregate(phi, beta, mu_d, delta_d, pi_d, dbar_d, mu_d0) -> dict`.
Returns the per-$(\phi, \beta)$ scalars: $W_{\text{obs}} - W_{\text{zero}}$, $W_{\text{opt}} - W_{\text{obs}}$ (Option 1), per-trajectory decompositions ($d_N$, switchers, $d_T$ pieces), and the implied $\Delta_{d_N}(\phi, \beta)$ and $\Delta_{d_T}(\phi, \beta)$ values for the P4 code-consistency check.
Treats $\Delta_{\underline{d}}$ for $\underline{d} \in \mathcal{D}_S$ as fixed at its non-parametric point estimate (it is not constrained by LCA).

Py-mod 3.
`integrate_envelope(phi, beta, mu_d_N_hat, sigma_theta, c, distribution="gaussian") -> dict`.
Returns $E[\max(0, \beta + \phi\theta) \mid d_N]$ where $\theta \mid d_N \sim N(\hat\mu_{\theta \mid d_N}, (c \cdot \sigma_\theta)^2)$ and $\hat\mu_{\theta \mid d_N} = (\hat\Delta_{d_N} - \beta)/\phi$.
No $F_\eta$ enters this integration (A2 deferral consequence).
Quadrature: `scipy.integrate.quad` with domain split at $\theta^* = -\beta/\phi$ (the kink of $\max(0, \cdot)$) to keep the integrand smooth on each subinterval; `points=[theta_star]` is passed as a fallback.
Same integration applied to switcher trajectories when reporting the per-trajectory decomposition of the envelope.
Sensitivity hooks: also accepts `distribution="t5"` (heavier-tailed) and `distribution="lognormal"` (skewed) for the auxiliary-assumption sensitivity in D6.

Py-mod 4.
`simulate_hukou_resort(phi_rh, beta_uh, sample_rh, sigma_eta, shock_family, seed=42, n_draws=10000) -> dict`.
Simulates the choice rule for the rural-hukou subsample under the no-barrier mapping (A4 Reading A: $\beta^{rh} \to \beta^{uh}$).
At each worker $i$ in `sample_rh`, draws $S = n\_draws$ values of $\nu^U_{it} - \nu^R_{it}$ from `shock_family` ($\in \{$logistic, normal$\}$, per A3) with scale $\sigma_\eta$ (A2 grid; the caller iterates over the $\sigma_\eta$ grid).
Uses *common random numbers* across calls within a country: the $N \times S$ shock matrix is generated once at the country level (seeded with `seed=42`) and reused across all $(\phi^{rh}, \beta^{rh})$ grid points and across $\sigma_\eta$ grid points within the same family.
Returns mean choice probability, marginal-migrant piece (workers who switch under no-barrier but did not under hukou), residual-stayer piece, and aggregate consumption gain.
The caller wraps this in a propagation loop over the joint $(\phi^{rh}, \beta^{rh})$ CI grid and the $\sigma_\eta$ grid (per P7).

Py-mod 5 (new, per A6).
`check_extrapolation_support(mu_d_N, switcher_mu_d_array, mu_d_T_hat=None) -> dict`.
Returns the hull check (is `mu_d_N` between min and max of `switcher_mu_d_array`?), the extrapolation distance in switcher-range units (min of `|mu_d_N - sw_min|` and `|mu_d_N - sw_max|`, divided by `sw_max - sw_min`), the position-in-hull fraction if interior, and the same diagnostic for `mu_d_T_hat` if provided.
Mirror of the visual diagnostic in [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do), promoted into the production pipeline.
Surfaces a T1 footnote-trigger flag when `mu_d_N` is out-of-hull or within 10% of either edge (per O7).

New scripts at the RP7 top level.

S-do 1.
[RP7/scripts/12_counterfactuals_misallocation.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/12_counterfactuals_misallocation.do).
Driver for E1.
Loops over countries and specs, calls `extract_trajectory_aggregates`, `extract_lca_params`, `call_counterfactual_py` (with mode = misallocation), and `render_counterfactual_table`.
Output: `output/tables/counterfactual_misallocation_{country}_{spec}.tex` plus a combined `counterfactual_misallocation_all.tex` for the paper.

S-do 2.
[RP7/scripts/13_counterfactuals_hukou.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/13_counterfactuals_hukou.do).
Driver for E2.
Calls the hukou-split sters, runs the bound calculation, runs the resort simulation under both shock distributions, renders the table.
Output: `output/tables/counterfactual_hukou_chn.tex`, plus a sensitivity figure `output/figures/counterfactual_hukou_continuum.pdf` for E2 estimand (7).

S-do 3.
[RP7/scripts/_smoke_counterfactual_inputs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/_smoke_counterfactual_inputs.do).
Audit script.
Loads each country / spec, reports every required object with its source, halts on missing or NaN.
Run this first, before any production run.

Master integration in [RP7/scripts/0_master.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_master.do).
Add a switch `local run_counterfactuals = 0` near the top of the master, in the same block as the existing `values()` / outcome / treatment switches.
Document the switch with a header comment block explaining:
(a) what it gates (12_ and 13_ scripts plus their Py-mod dependencies);
(b) why it defaults off (compute is small but E2-resort iterates over a $\sigma_\eta$ grid which adds a few minutes per country);
(c) which output artifacts it produces (T1, T2, T3, F1, F2, D1-D9);
(d) prerequisites (the audit script and all existing GRC + inversion sters must be on disk).
When the switch is set to 1, include `12_counterfactuals_misallocation.do` and `13_counterfactuals_hukou.do` after the existing pipeline steps (after `5b_inversion.do` so the inversion sters exist) and before figure assembly (`11_make_figures.do` consumes the resulting CSVs for F1/F2).
The team-facing README in `ReplicationPackage7/scripts/` should mention the switch on the second page, with a one-paragraph description of what it does and an explicit "default off" callout so coauthors are not surprised by silent extra runtime.

## Output artifacts

Tables (LaTeX, in `output/tables/`):

T1.
`counterfactual_misallocation_all.tex`.
Country-by-country rows.
Columns: $W_{\text{obs}} - W_{\text{zero}}$ (point and CI), $W_{\text{opt}} - W_{\text{obs}}$ Option 1 (point and CI), Option 2 (point and CI), $d_N$ share of the gap, switcher share, $d_T$ share.
Two units rows per country: log points; percent of aggregate.

T2.
`counterfactual_misallocation_envelope_{country}.tex`.
Per country.
Option 3 envelope table: rows are values of $c \in \{0, 0.25, 0.5, 0.75, 1.0\}$; columns are gap point estimate and CI half-width.

T3.
`counterfactual_hukou_chn.tex`.
Bound version, resorting version under logistic shocks, resorting version under normal shocks.
Each row: aggregate gain, marginal-migrant piece, residual-stayer piece, all in log points and percent.
CI from inversion-CI propagation.

Figures (PDF, in `output/figures/`):

F1.
`counterfactual_envelope_{country}.pdf`.
$x$-axis: $c$.
$y$-axis: $W_{\text{opt}} - W_{\text{obs}}$ in percent.
Three panels: TZA, IDN, CHN (the latter only if pooled inversion has a non-empty CI; otherwise skip CHN here and rely on hukou panel below).
Inversion-CI shaded band per panel.

F2.
`counterfactual_hukou_continuum.pdf`.
$x$-axis: $c$, the fraction of the hukou wedge removed.
$y$-axis: aggregate consumption gain in percent.
Two curves: logistic shocks vs normal shocks.

Diagnostics (CSV, in `output/counterfactual_diagnostics/`, not for paper):

D1.
`marginal_ci_check_{country}_{spec}.csv`.
Marginal CIs for $\Delta_{d_N}, \Delta_{d_T}$ obtained by projecting the joint CI versus the existing marginal CIs.
Pass/fail flag per row.

D2.
`joint_ci_acceptance_{country}_{spec}.csv`.
Fraction of the (phi, beta) lattice that the joint CI accepts, the boundary contour, and the minimum chi-squared value over the lattice.
Used to detect cases where the joint CI is empty (which should not happen for accepted specs).

D3.
`heterogeneity_integration_check_{country}.csv`.
At the point estimate $(\hat\phi, \hat\beta)$, the Option 1 trajectory-mean gap and the Option 3 envelope at $c = 1$ should satisfy Option 3($c=1$) $\geq$ Option 1 whenever $\Delta_{d_N} > 0$.
Sign-flip flag if not.
This is the Jensen monotonicity check; failure indicates either an integration bug or a sign of within-trajectory dispersion that pulls the other way (rare but possible if much of the $d_N$ mass sits at very negative $\Delta_i$).

D4.
`extrapolation_support_{country}.csv` plus per-country figure.
For each (country, spec): hull check on $\mu_{d_N}$ against switcher $\mu_{\underline{d}}$'s; extrapolation distance in switcher-range units; same diagnostic for $\mu_{d_T}$.
First-pass implementation already shipped at [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do).
Surface as a T1 footnote when $\mu_{d_N}$ is out-of-hull or within 10% of either edge.

D5.
`sigma_eta_grid_E2resort_{country}.csv` plus per-country figure.
For E2 resort: aggregate gain at each $\sigma_\eta$ on the justified grid, under both logistic and normal shocks.
Outputs the curve in $\sigma_\eta$ that is the primary E2-resort deliverable under A2.

D6.
`sigma_theta_pinning_check_{country}.csv`.
Reports $\sigma_\theta$ pinned from the unbalanced lumped-switcher cross-trajectory variance (3-point), the balanced-sample enumerated-trajectory cross-trajectory variance, and the implied envelope at each $c \in \{0, 0.25, 0.5, 0.75, 1.0\}$ under each pinning.
Quantifies how much the envelope depends on the pinning choice; both numbers are between-group lower bounds on the true within-trajectory dispersion (R3).

D7.
`ci_width_decomposition_{country}.csv`.
For each (country, spec), decompose the inversion CI width on the aggregate into the contribution from $\phi$ uncertainty alone (holding $\beta$ at $\hat\beta$), $\beta$ uncertainty alone (holding $\phi$ at $\hat\phi$), and the joint.
Tells the reader which parameter is doing the work; the Möbius pole at $\phi = -1$ should dominate when $\phi$ uncertainty alone is the input.

D8.
`leave_one_traj_out_{country}.csv` (balanced specs only, where $|\mathcal{D}_S| > 1$).
Recompute the aggregate dropping each switcher trajectory in turn.
Cheap robustness check; surfaces whether any single trajectory drives the magnitude.

D9.
`sign_flip_placebo_{country}.csv`.
At $\hat\phi$ flipped to $-\hat\phi$ (the LCA slope sign-flipped), recompute the aggregate.
The point estimate should change substantially; if it does not, the result is not being driven by the slope but by mechanical population weights.
Sanity check on whether the headline depends on $\phi < 0$ vs the trajectory-share weighting.

## Validation milestones

Milestone V1 (after P-prog 1 plus S-do 3 are in place).
Audit script runs cleanly on all six (country, spec) combinations under the headline specification.
All inputs present, no NaN.
Halt criterion: any missing object.

Milestone V2 (after Py-mod 1 plus Py-mod 2 plus P-prog 3 in place).
*Code-consistency check, not magnitude validation.*
Option 1 misallocation gap for TZA col 5 matches the back-of-envelope number ($\approx 22\%$) within $\pm 0.5$ percentage points; same for IDN ($\approx 3.7\%$).
The back-of-envelope numbers are themselves CKT-estimate-derived arithmetic, so this confirms the production code reproduces hand-arithmetic on its own inputs (catches transcription and indexing bugs).
It does not validate the magnitude against any external benchmark; see V2b.

Milestone V2b (new, after V2).
*External triangulation.*
Cross-check the headline magnitudes against (i) the urban-rural consumption gap in the country descriptives (`2_summaryStats.do` outputs); (ii) where available, comparable structural-migration aggregate magnitudes in the cited literature ($\cite{bryanAggregateProductivityEffects2019}$ for Indonesia; $\cite{lagakosMigrationCostsObservational2020}$).
Discrepancies of >50% with cross-paper benchmarks are explained in the paper-side text, not silently absorbed.
This is a write-up gate, not a halt gate.

Milestone V3 (after inference protocol P1-P3 in place).
Code-consistency check on the marginal projection: at every joint-accepted $(\phi, \beta)$, the implied $\Delta_{d_N}(\phi, \beta)$ must lie inside the cached profile CI for $\Delta_{d_N}$ from `*_n.ster`.
Halt on any violation (no half-width tolerance; see P4).

Milestone V4 (after Py-mod 3 in place).
Jensen monotonicity check D3 passes at every point estimate.
Option 3 at $c = 1$ $\geq$ Option 1 (which is Option 3 at $c = 0$) whenever $\Delta_{d_N} > 0$.
Failure indicates an integration bug.

Milestone V5 (after E2 in place).
Hukou lower bound from the rural-hukou regime matches the back-of-envelope from the memo ($\approx 5$ log points $\approx 5.1\%$) under the regime-specific base.
Same number under the common-base sensitivity, with a magnitude within 30% of the regime-specific base (precise range to be reported, not fixed in this plan).
For E2 resort: $\sigma_\eta = 1.0$ row in D5 produces a sensible aggregate (positive, less than the optimal-sort upper bound from E1, more than the bound from E2.1).

Milestone V7 (new, per A6).
D4 out-of-support diagnostic produces the expected output structure (hull check, distance metric, position-in-hull) for all (country, spec) pairs.
TZA flagged in T1 footnote (8% in hull, under the 10% threshold from O7).
CHN and IDN clean.

Milestone V6 (final).
End-to-end run of `12_counterfactuals_misallocation.do` and `13_counterfactuals_hukou.do` from a clean state produces all tables T1-T3, all figures F1-F2, all diagnostics D1-D9.
LaTeX compile of `paper/results_counterfactuals.tex` after wiring the new tables and figures succeeds without missing references or undefined commands.
*Cross-check the resolved paper-side caveats against this review's findings:* each CRITICAL and MAJOR item in [docs/reviews/2026-05-18_counterfactual-plan-methods-review-v2.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/reviews/2026-05-18_counterfactual-plan-methods-review-v2.md) appears either as resolved code behavior or as an explicit paper-side caveat.

## Sequencing and timeline

Sequence S1 (~1 day).
Build the audit script (S-do 3) and P-prog 1, P-prog 2.
Run V1.
Gate: V1 passes before proceeding.

Sequence S2 (~1.5 days).
Build Py-mod 1, Py-mod 2.
Compute Option 1 by hand at the point estimate for all (country, spec).
Run V2.
Gate: V2 passes (back-of-envelope match) before proceeding.

Sequence S3 (~1 day).
Build the inversion CI propagation (Step P1-P3) inside Py-mod 1 and Py-mod 2.
Run V3.
Gate: V3 passes.

Sequence S4 (~1 day).
Build Py-mod 3 (heterogeneity integration).
Wire into 12_counterfactuals_misallocation.do.
Run V4.

Sequence S5 (~1 day).
Build P-prog 4 (table rendering).
Wire end to end; produce T1, T2, F1.
Validate T1 row magnitudes against V2.

Sequence S6 (~1.5 days).
Build Py-mod 4 (hukou resort simulation).
Build 13_counterfactuals_hukou.do.
Produce T3, F2.
Run V5.

Sequence S7 (~0.5 days).
Wire everything into 0_master.do behind the switch.
Run V6.
Update the paper draft at [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) with realized numbers, replacing placeholder "approximately X%" prose with actual estimates and CIs.

Total: approximately 7.5 working days, single-track, before any paper-text revision beyond updating numbers.

## Risk register

R1.
Joint inversion CI is empty for some (country, spec).
Per A5: do **not** report the gap at the point estimate under a rejected model.
Instead, report only the components of the aggregate that do not depend on the rejected LCA piece.
$W_{\text{obs}} - W_{\text{zero}}$ uses non-parametric switcher $\Delta_{\underline{d}}$ and inversion $\Delta_{d_T}$ (no LCA cross-piece restriction) and stays reportable.
$W_{\text{opt}} - W_{\text{obs}}$ uses the LCA-extrapolated $\Delta_{d_N}$ and is suppressed when the joint CI is empty (table cell displays "model rejected at $\alpha = 0.05$").
CHN pooled is the leading candidate and is already addressed by hukou-split estimation per R5; the rule extends the convention to other (country, spec) cells.
Impact: medium.

R2.
Heterogeneity integration is numerically unstable when $\phi$ is close to $-1$.
The conditional density of $\theta_i | d_N$ involves $F_\eta(-\beta - \phi\theta)^T$; for very negative $\phi$ this becomes either very flat or very peaked, and the quadrature may fail.
Mitigation: switch to adaptive Gauss-Hermite quadrature; if the integral still does not converge, drop Option 2 for that (country, spec) and report Option 1 plus Option 3 envelope only.
Impact: medium.

R3.
Within-trajectory dispersion $\sigma_\theta$ pinned from cross-trajectory variance of $\mu_{\underline{d}}$ may not be the right object.
Cross-trajectory variance is a function of how trajectories are coarsened; under unbalanced specs the switcher trajectory is lumped, so the cross-trajectory variance is computed across only $\{d_N, \mathcal{D}_S, d_T\}$, a three-point distribution.
Mitigation: compute $\sigma_\theta$ both from the three-trajectory variance and from the full balanced-sample trajectory variance where available; report Option 2 / Option 3 with both choices in the diagnostics, headline with the unbalanced-consistent choice.
Impact: low for headline numbers (Option 1 and Option 3 at $c = 0$ are unchanged); medium for Option 2.

R4.
The hukou resort simulation requires a parameterization of the institutional wedge.
The plan parameterizes it as the intercept gap $\beta^{rh} - \beta^{uh}$, but this conflates two things: a true institutional barrier and a Frisch-style price-level difference between the two regimes.
Mitigation: report E2 under both readings.
Reading A: the entire intercept gap is the wedge.
Reading B: only a fraction of the intercept gap is the wedge, the rest is non-removable price-level heterogeneity; parameterized by the continuum $c$ in estimand (7).
Reading B is the sensitivity figure F2.
Impact: medium; this is a substantive economic question and we should flag it in the paper draft.

R5.
The $J$-test rejects under the pooled CHN spec but the hukou-split sters carry their own inversion CIs.
The misallocation accounting for CHN therefore has to be reported either regime-by-regime (with the rural-hukou and urban-hukou aggregates summed in proportion to subsample share) or simply omitted at the country level for CHN.
Plan: report both, headline with the regime-summed version.
Subsample shares ($\pi^{rh}, \pi^{uh}$) come from the CHN descriptives.
Impact: medium; affects the cross-country comparability of T1.

R6.
LCA out-of-support extrapolation to $d_N$ is the deeper identification concern.
If the slope $\phi$ identified from switchers does not carry over to never-migrants, then $\Delta_{d_N}$ is misstated, and the headline E1 magnitude (dominated by the $d_N$ piece) is also misstated.
Per A6: this is **high-impact at implementation**, not low.
The diagnostic is cheap (one line of code on objects in hand) and reported alongside every (country, spec) table cell.
First-pass implementation already shipped at [explorations/2026-05-18_extrapolation_support_diagnostic.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/2026-05-18_extrapolation_support_diagnostic.do); per-country density figures and memo at [docs/notes/2026-05-18_extrapolation_support_diagnostic.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-18_extrapolation_support_diagnostic.md).
Headline result: all three countries have $\hat\mu_{d_N}$ interior to the switcher hull (CHN at 26%, IDN at 24%, TZA at 8% from the lower edge).
Production version: surface D4 (see §"Diagnostics") in T1 footnotes when $\mu_{d_N}$ sits outside the switcher hull or within 10% of either edge.
TZA in the current data is a boundary case and warrants a paper-side flag.
Impact: high.

## Open issues: closed 2026-05-18

O1.
$\alpha = 0.05$ throughout, consistent with existing 95% inversion CIs.
**Closed: confirmed.**

O2.
Shock distribution for E2 resort.
**Closed (A3):** logistic and normal as parallel headlines, with the curve in $\sigma_\eta$ (A2 deferral) carrying both shapes at each grid point.

O3.
Heterogeneity grid for Option 3.
**Closed:** $c \in \{0, 0.25, 0.5, 0.75, 1.0\}$ confirmed; Option 3 reformulated per A1 as a direct Gaussian sweep on within-trajectory $\theta_i$ dispersion.

O4.
Hukou wedge parameterization in E2.
**Closed (A4):** Reading A (full intercept gap is institutional) as headline; Reading B continuum kept as appendix sensitivity figure.
Revisit if the four-source decomposition of $\beta^{rh} - \beta^{uh}$ drives the magnitude.

O5.
Experiment 3 deferral.
**Closed (A7):** both routes deferred; paper draft softened to subjunctive on the welfare-bridge extension.

O6.
Insertion of new tables and figures.
**Closed:** keep `paper/results_counterfactuals.tex` as a local working draft; once numbers are produced and the section is stable, user manually pastes into `sec_results.tex` on Overleaf per the STOP-READ-FIRST rule.

O7 (new).
Threshold for surfacing the out-of-support diagnostic in T1 footnotes.
**Closed:** flag when $\mu_{d_N}$ is out of the switcher hull *or* within 10% of either edge.
TZA (at 8%) crosses the threshold and warrants the flag.

## What this plan does not yet specify

- Exact column order in the headline table T1 (depends on what reads best once we have the numbers).
- Whether to display Option 2 in T1 alongside Option 1 (headline candidate) or only in the envelope figure F1 (alternative).
- Bootstrap-resample size for Py-mod 4 (default 10,000; may need to be larger for tight CIs).
- Whether to log-aggregate ($W$ is mean log consumption) or level-aggregate ($\exp(W)$ then mean) when reporting "percent of aggregate consumption."
  The two differ by Jensen.
  Default: log-aggregate plus an `\exp() - 1` for the headline percent, with a footnote.

These will be resolved during implementation as the numbers come in.

---

End of plan.
