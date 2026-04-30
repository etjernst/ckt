# The $1+\phi$ singularity in always-mover returns

## Definitions (and a note on terminology)

A Möbius transformation, also called a linear fractional transformation, is a function of the form

$$f(x) = \frac{a\,x + b}{c\,x + d}, \qquad ad - bc \neq 0.$$

Examples: $f(x) = (2x + 1)/(x - 3)$, $f(x) = 1/x$, $f(x) = (x + 1)/(x - 1)$.
A linear function $f(x) = a x + b$ is the trivial special case with $c = 0$, $d = 1$.
Möbius transformations are the standard objects in elementary complex analysis; they are taught in undergraduate textbooks and date to August Möbius circa 1827.
The transformation has a single pole at $x = -d/c$, the value where the denominator vanishes and $f$ becomes undefined.

A function has a singularity at a point $x_0$ when $f$ is not analytic at $x_0$ in some neighborhood; a pole is one common type, where $|f(x)| \to \infty$ as $x \to x_0$.
For a Möbius transformation the only singularity is the pole at $x = -d/c$.
Outside that one point, $f$ is smooth and well-behaved.

So "Möbius transformation" and "singularity" are both standard mathematical vocabulary.
What is not standard is the phrase "Möbius singularity" applied to the LCA always-mover return at $\phi = -1$.
That label is our coinage: we are reusing standard math vocabulary to describe a feature of our model.
The phrase is descriptive (the singularity is at the pole of a Möbius transformation in $\phi$), but a referee or coauthor reading the paper will not have seen it elsewhere in the LCA / GRC literature.
We should introduce it the first time we use it: write something like "the LCA-implied $\Delta_{d_T}$ is a Möbius transformation of $\phi$ (a fractional linear function); it has a single pole at $\phi = -1$, which we refer to throughout as the Möbius singularity."

## What it is

Under LCA, the rural counterfactual mean for always-movers $\mu_{d_T}$ (named $\kappa$ in the GMM code, a misnomer we plan to fix; see TODO) is not directly observed.
What we observe is their urban mean $\alpha_{d_T}^{\text{obs}} = \mu_{d_T} + \Delta_{d_T}$.
The LCA restriction also pins $\Delta_{d_T} = \beta + \phi(\mu_{d_T} - \mu_{\text{base}})$ in terms of the unobserved $\mu_{d_T}$.
Solving the two equations simultaneously and eliminating $\mu_{d_T}$:

$$\Delta_{d_T} = \frac{\beta + \phi\,(\alpha_{d_T}^{\text{obs}} - \mu_{\text{base}})}{1 + \phi}.$$

The $1+\phi$ in the denominator vanishes at $\phi = -1$.

## Why this isn't a degenerate model, just an algebraic singularity

It is not pathology in the GRC, the data, or the estimator.
It comes from the algebraic move of eliminating the unobserved $\mu_{d_T}$.
The map from data-identifiable objects $(\beta, \phi, \alpha_{d_T}^{\text{obs}}, \mu_{\text{base}})$ to the trajectory-specific return $\Delta_{d_T}$ has the form $f(\phi) = (a + b\phi)/(c + d\phi)$, which is the standard linear fractional transformation (a.k.a.\ Möbius transformation) named for August Möbius circa 1830 and basic enough that it is taught in undergraduate complex analysis.
A Möbius transformation has a single pole where the denominator vanishes; in our case that pole is at $\phi = -1$.
The phrase "Möbius singularity" applied to this specific GRC parameter combination is descriptive vocabulary, not jargon from the LCA literature; if we use it in the paper, we should call out where the term comes from.

The intuition for why the pole sits at $\phi = -1$: $\phi$ measures how returns scale with comparative advantage.
At $\phi = -1$, the LCA restriction implies that comparative advantage and absolute advantage exactly offset for the recovery of $\mu_{d_T}$ from $\alpha_{d_T}^{\text{obs}}$, so the rural counterfactual is no longer pinned down by the observed urban mean.
The model is fine; we have just written one parameter as a fractional combination of others, and the fraction blows up at one point.

## What it means for the inversion CI

When the $\phi$-CI is comfortably bounded away from $-1$ (e.g., $[-0.7, -0.4]$ for TZA covs_trend), $\Delta_{d_T}$ inverts cleanly to a single bounded interval.

When the $\phi$-CI crosses $-1$ (e.g., $[-1.23, -0.01]$ for IDN covs_all), values of $\phi$ just below $-1$ map to large negative $\Delta_{d_T}$ and values just above $-1$ map to large positive $\Delta_{d_T}$.
Both halves of the $\phi$-CI map to $\Delta_{d_T}$ regions on opposite sides of the pole, so the data-consistent set in $\Delta_{d_T}$-space splits into two unbounded intervals separated by a finite rejection band.
For IDN covs_all this is $(-\infty, +0.04] \cup [+0.66, +\infty)$.

## How to read these multi-island CIs in tables and prose

The CI is what we cannot rule out at the 5\% level.
For IDN covs_all/$\Delta_{d_T}$ the rejected set is the band $(0.04, 0.66)$ and everything outside is data-consistent.

Reporting decisions for the paper:

1. Write the CI as the union of intervals in the table cell, with $\pm\infty$ endpoints when the half-line is unbounded.
2. Footnote the cell to explain that the CI is unbounded because the $\phi$-CI crosses the singularity at $\phi = -1$, not because the model is degenerate.
3. The bounded-CI specifications (covs_trend, covs_1, covs_2 for IDN; the matching specs for TZA) localize $\Delta_{d_T}$ tightly; lean on those for substantive interpretation and present covs_all as the spec where the data has nothing to say about $\Delta_{d_T}$.

A possible alternative we have explicitly chosen against for now is rendering the cell as an "uninformative" check mark and pushing the multi-island CI to a footnote or appendix.
The information lost is real (a reader cannot tell that $(0.04, 0.66)$ specifically is rejected), but a check mark is also less honest about why the CI is wide.
We can switch to that if a coauthor or reviewer prefers cleaner table aesthetics; for now we report the union of intervals.

## Affected cells in the current results

Two cells in the consumption / urban / unbalanced specifications have $\phi$-CIs crossing $-1$ and therefore multi-island $\Delta_{d_T}$ CIs:

- IDN/covs_all: $\phi \in [-1.23, -0.01]$, $\Delta_{d_T} \in (-\infty, +0.04] \cup [+0.66, +\infty)$
- TZA/covs_all: $\phi \in [-1.22, -0.45]$, $\Delta_{d_T} \in (-\infty, -0.14] \cup [+1.72, +\infty)$

The other thirteen cells either have empty CIs (CHN, all specs; covs_0 for IDN and TZA) or single-island bounded CIs.

Source: [`results/delta_inversion_three_countries.md`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/results/delta_inversion_three_countries.md), generated by [`run_all_countries_inversion.py`](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/run_all_countries_inversion.py).
