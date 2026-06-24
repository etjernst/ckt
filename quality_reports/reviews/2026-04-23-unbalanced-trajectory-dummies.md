# Adding trajectory dummies for unbalanced observers: econometric analysis

**Date:** 2026-04-23
**Status:** Working memo. Decision deferred; current pooled-cell specification stays in the draft for now.
**Relates to:** `docs/reviews/2026-04-23-unbalanced-panel-proof-review.md`, `docs/reviews/2026-04-23-todo-verdier-section-G.md`.

## The question

Can we just add more trajectory dummies for unbalanced observers (classified by their observed-wave sequences) instead of pooling them into one cell via $U_i$ and $\pi$? And if we do:

1. How many new parameters would this add, especially in IDN (5 waves)?
2. Does it introduce interpretational problems in the non-parametric trajectory-cell framework?
3. Does it weaken our ability to extrapolate to never-migrants and always-migrants?

This memo walks through the econometrics carefully and gives a verdict.

---

## Part 1: What does "trajectory for an unbalanced observer" even mean?

In the current specification, a trajectory label $\underline d_i \in \mathcal D$ is defined as the full sequence $(D_{i1}, D_{i2}, \ldots, D_{iT_c})$ for a balanced observer. Unbalanced observers have no defined $\underline d_i$ because some $D_{it}$ is missing.

For an unbalanced observer we can instead index by one of three schemes:

**Scheme A: (pattern, observed sequence).** Define the trajectory as the pair $(\mathcal T_i, \underline d_i^{\mathrm{obs}})$, where $\mathcal T_i \subseteq \{1, \ldots, T_c\}$ is the set of observed waves and $\underline d_i^{\mathrm{obs}} = (D_{it})_{t \in \mathcal T_i}$ is the observed sequence. Each unique $(\mathcal T, \underline d)$ gets its own cell. Most granular.

**Scheme B: observed sequence only.** Define the trajectory as $\underline d_i^{\mathrm{obs}}$, ignoring which specific waves were observed. An "observed 0-then-1" individual is in the same cell whether observed in waves $(1,2)$ or $(3,5)$.

**Scheme C: coarse observed type.** Collapse to a handful of types: observed-always-rural, observed-always-urban, observed-switcher-first-up, observed-switcher-first-down, observed-multiple-switches. Very parsimonious.

Each scheme defines cells that are **MAR-weighted mixtures** of full-sequence cells. For an unbalanced observer observed as "0-then-1" in waves $(1,3)$, the true full-sequence trajectory could be $(0,0,1,0,0)$, $(0,1,1,1,1)$, or any other sequence consistent with $D_1=0, D_3=1$. Under MAR, the conditional distribution over these full sequences, given the observed $(0,1)$, is well-defined. The cell's parameters are population averages over this mixture.

**Implication:** the $\mu$ of an observed-sequence cell is *not* the same as any single balanced-cell $\mu$. It's a mixture. This is not a bug; it's a well-defined population parameter. But interpretation must be careful.

---

## Part 2: Does LCA still hold on these mixture cells?

Yes, and this is the key econometric point.

LCA is an individual-level restriction: $\Delta_i = \beta + \phi \theta_i$ for every individual $i$. Take conditional expectations within any cell $c$ (whether a balanced-sequence cell or a mixture cell from unbalanced observers):

$$E[\Delta_i \mid c] = \beta + \phi \cdot E[\theta_i \mid c].$$

Since $\mu_c \equiv E[\alpha_i^R \mid c]$ is a linear function of $E[\theta_i \mid c]$ through the structural model, the cross-cell relationship
$$\Delta_c = \beta + \phi \cdot (\text{linear in } \mu_c)$$
holds identically for any well-defined cell, mixture or not. **The same $\phi$ governs every cell.** So the LCA overidentifying structure is preserved when we add mixture cells.

This has a concrete practical consequence: adding observed-sequence cells from unbalanced observers gives us **more overidentifying restrictions for $\phi$**, which in principle sharpens the estimate. The cost is that thin cells add noise. Whether the noise-sharpness tradeoff favours adding cells is an empirical question.

---

## Part 3: Does extrapolation to never-migrants weaken?

**No.** Extrapolation to always-rural non-migrants uses
$$\hat\Delta_{d_N} = \hat\beta + \hat\phi \cdot \hat\mu_{d_N},$$
where $\hat\mu_{d_N}$ is the balanced-sample average for the $d_N = (0,0,\ldots,0)$ cell. That balanced cell still exists in any specification; adding unbalanced-observer cells doesn't change it or its estimate. Only $\hat\phi$ is affected, and only potentially sharpened.

There is one honest caveat: if one of the added unbalanced cells is "observed-always-rural," it's tempting to *merge* that cell with the balanced $d_N$ cell. **Don't do that without checking.** An observed-always-rural unbalanced observer could have migrated and returned in missing waves; their expected $\alpha_i^R$ is not identical to a true always-rural observer's, even under MAR. Keep them as a separate cell. Their $\mu$ informs $\phi$; it does not replace $\mu_{d_N}$.

---

## Part 4: How many new parameters?

Quick combinatorial count. Let $T_c$ be the number of waves. The number of potential cells under each scheme, before dropping thin/empty cells:

| Country | $T_c$ | Balanced cells ($2^{T_c}$) | Scheme A (pattern × seq, 3+ waves) | Scheme B (obs seq only, 3+ waves) | Scheme C (coarse type) |
|---------|-------|--------------------------|-----------------------------------|-----------------------------------|------------------------|
| TZA     | 3     | 8                        | 8 (same as balanced)             | 8                                 | ~5                     |
| CHN     | 4     | 16                       | 16 + 5·8 = 56                    | 16 + 8 = 24                       | ~5                     |
| IDN     | 5     | 32                       | 32 + 5·16 + 10·8 = 192            | 32 + 16 + 8 = 56                  | ~5                     |

In practice most cells are empty or thin (the balanced IDN already has far fewer than 32 populated cells because the switcher types are rare). The real counts depend on the data. But the theoretical upper bounds show what we're flirting with:

- **Scheme A** (maximally non-parametric): up to 192 potential cells in IDN. Unusable without heavy shrinkage or cell-merging.
- **Scheme B** (observed sequence only): up to 56 cells in IDN. Potentially manageable if thin cells are merged.
- **Scheme C** (coarse): ~5 new cells. Manageable.

**Each cell adds two parameters**: a $\mu_c$ intercept and (under LCA) an implied $\Delta_c = \beta + \phi \mu_c$ return. If LCA is imposed, only $\mu_c$ is a free parameter. If LCA is left free on a cell (as is done for the current $U_i$ pooled cell, where $\pi$ is unconstrained), both are free.

For Scheme C with LCA imposed: ~5 new free $\mu$ parameters total. Roughly comparable to the current pooled-cell approach, which has 2 parameters ($\alpha, \pi$) for the unbalanced stratum.

For Scheme B with LCA imposed: dozens of new $\mu$ parameters. $\phi$ becomes sharpened but thin cells introduce noise.

---

## Part 5: A subtle point about the current specification

The existing $U_i$ pooled-cell specification has $(\alpha, \pi)$ as **both free parameters**. In effect, it treats the unbalanced stratum as one giant cell with a free intercept and a free urban return, *unconstrained by LCA*.

If LCA holds on the unbalanced stratum (which it must, if A5 applies to every individual), then
$$\pi = \phi(\alpha - \mu_{\underline d_0})$$
is a testable restriction on the current specification. Imposing it drops $\pi$ as a free parameter and adds one overidentifying restriction to the $\phi$ estimate.

**So one of the cheapest and most principled changes you could make is: impose LCA on the unbalanced pooled cell.** No new dummies, one fewer free parameter, one extra moment condition for $\phi$ identification. It treats the unbalanced observers as if they form a single LCA-consistent cell. This is strictly more structural than the current approach.

The practical question is: does $\hat\pi$ currently satisfy $\hat\pi \approx \hat\phi(\hat\alpha - \hat\mu_{\underline d_0})$ to within sampling error? If yes, imposing LCA costs nothing. If no, the unbalanced stratum's average return is not on the LCA line, which is itself interesting evidence (either against MAR, against common-$\gamma$, or against LCA).

---

## Part 6: Verdict

Three concrete options, ordered from cheapest to most ambitious:

### Option 1: Keep the current specification, acknowledge the simplification.

No code changes. The proposition and main text already treat this specification carefully. This is what's in the draft now.

**Pro:** no work, no risk of destabilizing results.
**Con:** leaves efficiency on the table; a referee familiar with Verdier may ask why we didn't do more.

### Option 2: Impose LCA on the unbalanced pooled cell.

Replace the free $(\alpha, \pi)$ pair with a single free $\alpha = \mu_{\mathrm{unb}}$ and the LCA-implied $\pi = \phi(\mu_{\mathrm{unb}} - \mu_{\underline d_0})$.

**Pro:** one fewer parameter, more moment conditions for $\phi$, respects the model's structure.
**Con:** commits to LCA on the unbalanced stratum, which is an additional substantive restriction.
**Effort:** half-day of code changes to `run_grc`, re-estimation, a footnote in the proposition.

### Option 3: Scheme C --- coarse observed-type cells with LCA.

Add ~5 observed-type cells (observed-always-rural, observed-always-urban, observed-first-switch-up, observed-first-switch-down, observed-multiple-switches) with LCA imposed on each.

**Pro:** closest to Verdier's spirit while respecting the trajectory-cell framework; unbalanced observers contribute to $\phi$ identification through multiple cells; extrapolation to balanced never-migrants is unchanged.
**Con:** requires rewriting `handle_trajectory_groups` and `define_switcherpars`; interpretation of observed-type cells as MAR mixtures needs formalization.
**Effort:** one week, including proposition rewrite.

### Avoid: Scheme A or B.

Too many thin cells, especially for IDN. Would require shrinkage, regularization, or ad hoc cell merging --- all of which are harder to defend than Option 3.

---

## Part 7: Recommendation

**For the current submission cycle: Option 1.** The proof is now clean (post v2 review fixes). The common-$\gamma$ assumption is testable and we can report that test as a robustness check. Ship this.

**For a future revision: Option 2 is low-cost and interesting.** If the LCA restriction $\pi = \phi(\alpha - \mu_{\underline d_0})$ is satisfied in the data, imposing it gives us a cleaner specification essentially for free. If it's rejected, that's a finding worth reporting --- it suggests something structural is off for unbalanced observers (MAR violation, common-$\gamma$ violation, or genuine LCA heterogeneity).

**Option 3 is a paper-level investment.** Only worth doing if the balanced/pooled gap in trajectory estimates is meaningful (it currently appears small, per the main text) or if a referee explicitly asks for more nuanced handling of unbalanced observers along Verdier's lines.

---

## Appendix: why we were confused about common-$\gamma$

The assumption "$\gamma$ is the same across strata" (our Assumption~\ref{ass:common-gamma} in the proposition) and "$\gamma$ is the same across trajectories" are closely related. Both are downstream consequences of assumption A4 in the main model ($\gamma^U = \gamma^R$). A4 says covariate effects are location-symmetric, and because a trajectory is just a sequence of locations, A4 implies common covariate effects within and across trajectories. Under MAR, unbalanced observers inherit the same structural model, so A4 + MAR implies common-$\gamma$ across strata too.

So the proposition's Assumption~\ref{ass:common-gamma} is arguably redundant given A1--A5 + MAR. We state it separately because:

1. It makes the test for cross-stratum covariate homogeneity explicit and easy to run (just add $U_i \cdot x_{it}'\delta$ interactions, joint-test $\delta = 0$).
2. It gives us something concrete to probe when we compare pooled and balanced-only trajectory estimates.

The test for cross-trajectory covariate homogeneity (the analogous $\mathbb{1}\{\underline d_i = \underline d\} \cdot x_{it}'\delta_d$ interaction test) is a test of A4 itself. Not standard in this literature, but worth noting as a potential robustness check.
