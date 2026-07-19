# Plan review: inversion-inference validation and rerun

Date: 2026-07-10

Reviewing as: applied econometrics methodology specialist.

Plan source: `quality_reports/plans/2026-07-10-inversion-inference-part-b.md`.

Depth: standard.

## Best-practices context

1. Weak-identification-robust confidence sets must allow empty, disconnected, or unbounded sets when the inverted test warrants them; a finite search box cannot by itself establish boundedness or unboundedness. See [Dufour (1997)](https://jeanmariedufour.github.io/Dufour_1994_ImpossibilityTheorems_W.pdf) and [Stock and Wright (2000)](https://scholar.harvard.edu/files/stock/files/gmm_with_weak_identification.pdf).
2. A generalized Wald statistic with singular covariance requires a theoretically justified rank and reference distribution; generalized-inverse rank loss cannot be paired silently with nominal restriction-count degrees of freedom. See [Moore (1977)](https://www.tandfonline.com/doi/abs/10.1080/01621459.1977.10479921).
3. Simulation studies should pre-specify aims, DGPs, estimands, methods, and performance measures; report Monte Carlo uncertainty and all failures; and preserve reproducible raw results and seeds. See [Morris, White, and Crowther (2019)](https://doi.org/10.1002/sim.8086).

## Strengths

1. The immutable baseline and stop gates provide strong provenance.
2. The plan uses the production auxiliary-OLS covariance, preserves disconnected components, and retains replication-level failures and seeds.
3. The conditional GMM gate correctly avoids rerunning point estimation for an inference-only change when validated stored inputs suffice.

## Findings incorporated

- **Red:** Singular-covariance classification did not determine a valid rank/reference law. The revised plan now requires scale-normalized rank diagnostics, column-space compatibility, equivalence between a full-rank restriction basis and a Moore--Penrose/rank-df statistic, and separate treatment of candidate-dependent rank changes.
- **Red:** Finite grid expansion could not certify unboundedness or find every narrow component. The revised plan now distinguishes domain truncation from unboundedness, requires adaptive subdivision, and requires a tail or contour certificate.
- **Red:** The two-MCSE coverage trigger could approve meaningful undercoverage. The revised plan sets a 94% floor for nominal 95% inference, uses familywise-adjusted exact binomial bounds, and sizes confirmation by power.
- **Red:** Using the diagnosing runs to validate the chosen adjustment created selection optimism. Discovery and confirmatory seed banks are now disjoint.
- **Red:** Computational failures lacked a primary coverage score. The revised plan uses all attempted replications and worst/best-case failure bounds.
- **Yellow:** Python/Stata reconciliation omitted sample, covariance, restriction, and sentinel-candidate comparisons. These are now explicit.
- **Yellow:** Hash-valid `.ster` files alone did not establish reconstructible provenance. The GMM gate now includes sample, convergence, objective, ordering, and mapping metadata.

## Verdict

APPROVE after revisions.
