# Spec: within-never-migrant dispersion envelope for the misallocation gap

Date: 2026-07-08.
Status: DRAFT for a go/no-go decision; supersedes item 13 of [2026-07-08-counterfactual-fixes.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/specs/2026-07-08-counterfactual-fixes.md) and ignores the envelope description currently in the paper (lines 825--832 of `main-updated.tex`), which this spec would replace.

## What it computes and why

The misallocation gap gives every never-migrant the group-mean return $\Delta_{d_N}$, so their contribution is $\pi_{d_N} \max(0, \Delta_{d_N})$.
If returns vary within the group, a planner moves only the workers with $\Delta_i > 0$, so the true contribution is $\pi_{d_N} E[\max(0, \Delta_i) \mid d_N]$, which weakly exceeds the mean-based floor (Jensen).
The envelope quantifies how much larger the gap could be as a function of how much within-group heterogeneity one is willing to assume.

The calculation: returns within never-migrants are $\Delta_i = \beta + \phi \theta_i$; assume $\Delta_i \mid d_N \sim N(\Delta_{d_N}, s^2)$, where $s = |\phi| \sigma_{\theta \mid d_N}$ is the within-group standard deviation of returns.
The censored-normal identity gives $E[\max(0, \Delta_i)] = \Delta_{d_N} \Phi(\Delta_{d_N}/s) + s\,\varphi(\Delta_{d_N}/s)$, a closed form, so no simulation is needed.
The exhibit is the curve $G(s)$: the misallocation gap with the never-migrant term replaced by this expectation, plotted for $s$ from 0 (the current floor) up to a reference maximum, per country and CHN regime.

## The assumptions, in decreasing order of comfort

A1 (mean pinned to the LCA line).
$E[\Delta_i \mid d_N] = \Delta_{d_N} = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$.
This is the same object the rest of the counterfactual already uses; nothing new is assumed.

A2 (evaluated at the point estimate).
The curve is a sensitivity exhibit at $(\hat\phi, \hat\beta)$, not an inference object; no confidence band on it.
Cheap to relax later (evaluate the curve at region endpoints), but the paper paragraph does not promise that.

A3 (normality).
The shape of $\Delta_i \mid d_N$ is not identified; the Gaussian is pure convenience to make the integral closed-form.
The functional $\max(0, \cdot)$ is not very shape-sensitive near the mean but is tail-sensitive when $\Delta_{d_N}$ is far from zero relative to $s$; for our cells $\Delta_{d_N} > 0$, so heavier left tails than Gaussian would LOWER the envelope toward the floor and heavier right tails raise it.
The paper must present the curve as "under a Gaussian benchmark", not as a bound.

A4 (the scale $s$ is not identified --- this is the load-bearing assumption).
Nothing in the GRC pins down the within-group dispersion of comparative advantage; any number we plug in is a calibration.
Important: the justification currently in the paper is wrong and must go regardless of the go/no-go here.
The text claims the cross-trajectory dispersion of $\mu_{\underline{d}}$ is "an upper bound on $\sigma_\theta$ by the law of total variance"; the law of total variance runs the other way ($\mathrm{Var}_d(E[\theta \mid d]) \le \mathrm{Var}(\theta)$, a lower bound on the total), and neither quantity orders the within-group $\sigma_{\theta \mid d_N}$ in general.
What we can honestly offer is a sensitivity axis with labeled reference points rather than a bounded interval:

- Reference L (between-group scale): $s_L = $ the standard deviation of the LCA-fitted returns across trajectories, $|\hat\phi| \cdot \mathrm{SD}_{\underline{d}}(\hat\mu_{\underline{d}})$ ($\pi$-weighted).
  Interpretation: "within-group heterogeneity as large as the between-group heterogeneity the model already estimates."
  A focal calibration, not a bound.
- Reference U (heuristic ceiling): $s_U = |\hat\phi| \cdot \mathrm{SD}$ of individual mean rural log per-capita consumption within $d_N$ (residualized on the model's covariates).
  Interpretation: returns cannot plausibly be more dispersed than the total permanent consumption heterogeneity within the group.
  Honest caveat: this is heuristic, not a theorem --- in the model, rural consumption loads on absolute advantage and rural skill, not on comparative advantage directly, so $s_U$ could in principle understate or (far more likely) overstate the true dispersion; it inflates with measurement error and household-composition variation.

The exhibit therefore reports $G(s)$ on $s \in [0, s_U]$ with ticks at 0, $s_L$, and $s_U$, and the prose describes L and U as calibration references.
If that framing feels too loose to publish, the honest alternative is to cut the envelope and keep only the one-sentence Jensen remark that the trajectory-mean gap is a floor.

A5 (never-migrants only).
The lumped unbalanced cell has the same mean-versus-max issue and larger $\pi$, but extending the envelope there needs a stand on the return distribution of a mixed bag of unbalanced stayers and movers, compounding A3--A4.
Scope: compute for $d_N$ only; one prose sentence notes the same logic applies to the lumped cell, making the reported floor conservative there too.

## Implementation sketch

One function in `counterfactuals.py` (`envelope_curve(cell, s_grid)`) using the closed form; $s_L$, $s_U$ computed from objects already in the auxiliary fit and the panel; driver writes `counterfactual_envelope.csv` (cell, s, gap_log, gap_pct) and one small multi-panel figure `counterfactual_envelope.pdf/png` (gap vs $s$, four cells, reference ticks, house figure style).
Paper: rewrite lines 825--832 to match (Gaussian benchmark framing, references L/U, delete the law-of-total-variance sentence), point to the figure.
Roughly a half-day including the figure and prose; no re-estimation.

## Decision

Go: implement as specced (sensitivity curve with calibration references, no bound language).
No-go: cut the envelope paragraph from the paper, keep the Jensen floor sentence, and delete item 13 from the fixes spec.
Either way the incorrect law-of-total-variance sentence leaves the paper.
