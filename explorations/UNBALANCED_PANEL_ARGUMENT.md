# Unbalanced panel inclusion: proof or simulation?

**Date:** 2026-04-22
**Status:** Exploratory memo. Superseded in part; see correction below.

## Correction (2026-04-22)

This memo originally assumed trajectories are defined over each individual's observed waves (so every observer gets a trajectory based on their own $\mathcal{T}_i$). That is **not** how CKT's code works. In `scripts/0_programs.do`, `handle_trajectory_groups` executes `keep if !unbalanced` (line 199), so only fully balanced observers are assigned a trajectory. Unbalanced observers are pooled into a single cell (`trajectory = 999`, line 1217) with an unbalanced indicator $U_i$ and a $U_i \times D_{it}$ interaction.

This makes the proof *simpler*, not different. With a single pooled unbalanced cell, trajectory indicators are identically zero for unbalanced observers by construction, and Frisch--Waugh--Lovell orthogonality goes through directly. The authoritative proof is now in `explorations/unbalanced_proposition.tex`. The sketch below is retained for the conceptual framing but its cell-structure claims (in particular "more trajectory cells" in §What changes) should be read as superseded.

## Verdict

**Proof for the main claim, simulation only for the MNAR robustness arm.**

Under the CKT assumptions A1--A5 plus MAR attrition, the GMM moment conditions evaluated on the unbalanced sample have the same probability limit as on a balanced sample. This is a short, clean econometric argument --- no Monte Carlo needed to establish consistency. A simulation earns its keep only as a robustness check against MNAR attrition (observation probability depending on $\theta_i$ after conditioning on observables), which a proof cannot cover.

## Why this is a proof, not a simulation

The GRC estimator is a GMM on trajectory-indexed moment conditions. The parameters $\phi$ and $\{\mu_{\underline d}, \Delta_{\underline d}\}$ are identified from population expectations conditional on trajectory membership. Adding partially observed individuals to the sample is an operation on the *sampling weights* over trajectory cells, not on the population moments themselves. If MAR holds and trajectories are defined over observed waves only, the estimator is consistent by a single substitution argument.

Contrast this with the coverage question for $\Delta_{d_N}$: that one requires a Monte Carlo because finite-sample CI coverage is not something a consistency proof delivers. The unbalanced-sample question is about consistency, not finite-sample inference, and is therefore the right job for a proof.

## Sketch of the proof

### Setup

Let $R_i = (R_{i1},\ldots,R_{iT})$ be the vector of wave-level observation indicators for individual $i$. Let $\mathcal{T}_i \equiv \{t : R_{it}=1\}$ be the set of waves where $i$ is observed, and let $\underline d_i \equiv (D_{it})_{t \in \mathcal{T}_i}$ be the *observed* trajectory over $\mathcal{T}_i$. Two individuals with the same $\mathcal{T}_i$ and the same observed $D$ sequence share a trajectory cell.

Each trajectory cell $(\mathcal{T}, \underline d)$ contributes a moment:
$$
g_{(\mathcal{T},\underline d)}(\beta, \phi, \gamma) \;=\; E\!\left[\,\frac{1}{|\mathcal{T}|}\sum_{t\in\mathcal{T}}\bigl(y_{it} - \mu_{(\mathcal{T},\underline d)} - (\beta + \phi\theta_{(\mathcal{T},\underline d)})\, D_{it} - x_{it}'\gamma\bigr)\,\Bigm|\, \mathcal{T}_i=\mathcal{T},\,\underline d_i=\underline d\right] = 0.
$$

The restricted GRC imposes LCA at the individual level ($\Delta_i = \beta + \phi\theta_i$) and pools $\phi$ across all cells.

### Assumptions

- **A1--A5** as stated in CKT_2026.tex (time-invariant $\theta_i^l$, i.i.d. $\nu_{it}^l$, constant $\beta$, $\gamma^U=\gamma^R$, LCA).
- **MAR attrition:** $R_i \perp (\theta_i, \tau_i, \{\nu_{it}^l\}) \mid \{x_{it}\}_{t=1}^T$.

### Claim

The empirical moments $\hat g_{(\mathcal{T},\underline d)}$ computed on the unbalanced sample converge in probability to the same $g_{(\mathcal{T},\underline d)}$ as in the full-observation thought experiment, and therefore the two-step GMM estimator is consistent and asymptotically normal with the usual sandwich variance.

### Argument

For any individual $i$ with observation pattern $R_i$, the conditional distribution of $(y_{it}, D_{it}, x_{it})$ given $\underline d_i = \underline d$ and $\mathcal{T}_i = \mathcal{T}$ is, under MAR,
$$
f(y, D, x \mid \underline d_i=\underline d,\, \mathcal{T}_i=\mathcal{T}) = f(y, D, x \mid \underline d_i=\underline d,\, t \in \mathcal{T})
$$
because $R_i$ is independent of $(\theta_i, \tau_i, \nu)$ given $x$, and $(y, D)$ are functions of $(\theta, \tau, \nu, x)$. The conditioning on $\mathcal{T}$ carries no further information about the latent primitives beyond what $x$ already provides.

So the population moment evaluated in cell $(\mathcal{T}, \underline d)$ on the unbalanced sample equals the population moment that would obtain if we had observed the full $T$ waves and kept the same $(\mathcal{T}, \underline d)$ labels. LCA is an individual-level restriction; it is preserved under any waves-observed subset. The same $\phi$ appears in every cell's moment, so stacking cells identifies it, and each cell identifies its own $(\mu, \Delta)$.

Consistency and asymptotic normality then follow from standard GMM theory (Hansen 1982) once the moment is correctly specified and the weight matrix is estimated from the same unbalanced sample.

### What changes vs. the balanced case

1. **More trajectory cells.** A balanced sample with $T$ waves has up to $2^T$ switcher cells. An unbalanced sample has cells indexed by $(\mathcal{T}, \underline d)$ for every subset $\mathcal{T}$. Some cells are thin; that hurts efficiency, not consistency.
2. **Weighting.** Individuals with longer observation windows contribute more within-cell moment information. The two-step GMM weight matrix absorbs this.
3. **Hansen $J$.** Over-identification is now evaluated across a larger cell system. Size and power are calibration-dependent --- this is the Monte Carlo question, and it is Exercise 2 in the main simulation memo, independent of the unbalanced-panel argument.

## What the proof does *not* cover

- **MNAR attrition.** If $R_i \not\perp \theta_i \mid x$ --- for example, if high-$\theta$ individuals selectively migrate out of the study --- the observed-trajectory moment no longer equals the population moment. The proof breaks.
- **Finite-sample coverage in thin cells.** A cell $(\mathcal{T}, \underline d)$ observed in only a handful of individuals can have severely under-covered SEs even under MAR. This is an efficiency question that a proof cannot settle.

Both are natural Monte Carlo tasks. They slot into Exercise 6 (attrition) of SIMULATION_PLAN.md:1 without any new design machinery.

## Recommended place in the paper

Short proposition in the model section or in the online appendix:

> **Proposition (unbalanced panel).** *Under A1--A5 and MAR attrition, the restricted GRC estimator on the unbalanced sample is consistent and asymptotically normal with the same probability limit as on the balanced sample.*

Proof: half a page. Assumption MAR: one sentence in the identification section. Robustness to MNAR: one paragraph pointing to the Monte Carlo appendix.

This is cheap, referee-proof against the "why include the unbalanced sample" question, and formally closes an argument the paper currently makes only by citing the balanced-panel robustness table.

## Caveats

1. **Defining trajectories over observed waves.** The proof depends on defining $\underline d_i$ over $\mathcal{T}_i$, not over the full $T$ waves. If the CKT code defines $\underline d$ over the full wave support and treats missing waves as a third symbol (e.g., `.` or $-1$), re-check that the moment condition uses only the observed-wave contributions. A quick check of `run_grc` in `0_programs.do` will tell us which convention the code follows.
2. **MAR is an assumption, not a fact.** If there is reason to believe attrition loads on $\theta_i$ (e.g., migration itself causes dropout from the home-country survey), the proof does not save us --- the simulation has to. This is common in migration panels; acknowledge it.
3. **Covariate conditioning.** If the MAR condition holds only after conditioning on time-varying $x$, the moments must enter with $x_{it}$ included. CKT already conditions on age, education, household size, period, so this is likely fine, but worth stating explicitly.

## Next step

Low cost, high value: draft the proposition and proof for the appendix as a standalone half-page. Verify the trajectory-definition convention in `run_grc` first (five-minute code check). Then decide whether to fold it into the model section proper or keep it in the online appendix.
