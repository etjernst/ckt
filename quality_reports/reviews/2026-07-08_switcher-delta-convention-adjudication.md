# Adjudication: which switcher $\Delta_{\underline{d}}$ convention belongs in the misallocation counterfactual

Date: 2026-07-08.
Scope: the E1 aggregate misallocation gap, $W_{\text{opt}} - W_{\text{obs}} = \sum_{\underline{d}} \pi_{\underline{d}} [\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}} \bar D_{\underline{d}}]$, and its weak-identification-robust confidence interval built by propagating a joint $(\phi, \beta)$ test-inversion region through the aggregate.
The question is which values of $\Delta_{\underline{d}}$ for switcher trajectories should enter, at the point estimate and inside the confidence-region sweep.
Sources consulted: [results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) (equation 1 and the identification paragraph, lines 54-60), [counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py) (`run_cell`, `delta_at`, lines 536-564), and [0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) lines 2160-2202 (the nlcom blocks on the restricted fit).

## Verdict

Ranking on econometric correctness: (B) strictly first, (A) second, (C) last.

(B) Restricted, recomputed: $\Delta_{\underline{d}}(\phi, \beta) = \beta + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ evaluated at every candidate $(\phi, \beta)$ in the region, for switchers, $d_N$, and $d_T$ alike.
This is the model-consistent convention and the only one under which the reported interval is the image of a coherent estimand map.

(A) Unrestricted, held fixed: defensible as a minimum-model-dependence cross-check, but the resulting interval is conditional on the unrestricted switcher estimates and is not, strictly, a valid confidence statement for the population aggregate.

(C) The current implementation, LCA-fitted values frozen at $(\hat\phi, \hat\beta)$ while the sweep moves $(\phi, \beta)$ inside the $d_N$ and $d_T$ terms: dominated by both alternatives.
It has neither (A)'s robustness rationale nor (B)'s coherence, and each lattice point of the sweep evaluates the aggregate under two mutually contradictory parameter values at once.

Numerically the three are close here (switcher shares of 1-6%, passing $J$-test), so this adjudication changes the description of the estimator more than it changes the numbers.
That makes it cheap to get right and embarrassing to get wrong.

## Reasoning

### Internal coherence of the counterfactual experiment

A structural counterfactual is a statement of the form "under the model at parameter value $(\phi, \beta)$, the aggregate would be $g(\phi, \beta)$."
The dispersion-floor logic, the $d_N$ extrapolation, and the Mobius inversion for $d_T$ all commit the exercise to the LCA restriction as the maintained model; without it there is no counterfactual at all, because over 90% of the population is a non-switcher.
Once that commitment is made, the coherent evaluation computes every model-implied object at the same candidate parameter value.
Convention (B) does exactly this: at each $(\phi, \beta)$, all trajectory returns lie on the same LCA line, and $g(\phi, \beta)$ describes one internally consistent economy.

Convention (C) violates this within a single evaluation.
At a candidate point $(\phi, \beta) \neq (\hat\phi, \hat\beta)$, the never-migrant return says the LCA line has slope $\phi$, while the switcher returns say it has slope $\hat\phi$.
No data-generating process produces both simultaneously, so the swept functional is not $g(\phi, \beta)$ for any model; it is $g(\phi, \beta; \hat\phi, \hat\beta)$, a hybrid whose second argument is a random variable frozen at its realization.

Convention (A) is coherent in a different sense: it treats the switcher returns as directly identified data-side objects, like $\pi_{\underline{d}}$ and $\bar D_{\underline{d}}$, and uses the model only where extrapolation is unavoidable.
That is a legitimate estimand (a hybrid of nonparametric and model-implied pieces), but it is a different estimand from the model-implied aggregate, and its uncertainty statement inherits the problems in the next subsection.

### Is mixing nonparametric and model-implied objects acceptable?

Acceptable as a robustness display, undesirable as the headline.
The structural counterfactual convention is that objects the model restricts are recomputed from the model inside the counterfactual, even when the data identify them directly; the direct estimates serve as fitting targets and specification checks, not as spliced-in components of the counterfactual aggregate.
Suri (2011), the immediate precedent named in the draft (Section 5.2 counterfactuals), computes counterfactual yield gains for non-adopters from the fitted CRC line, and the same fitted line prices the adopters in her decomposition; Bryan and Morten (2019) likewise run their counterfactual entirely through the estimated model rather than substituting raw wage gaps where observed.
The deeper reason is that the difference between the unrestricted switcher returns and the LCA-fitted ones is exactly the overidentifying variation the $J$-test evaluates.
Splicing the unrestricted values into a model-based aggregate quietly re-litigates a specification question the paper has already answered in the model's favor: with a passing $J$-test, the restricted fitted values are the (asymptotically) efficient estimates of the switcher returns under the maintained model, and the unrestricted values are noisier estimates of the same quantities.
If the LCA restriction were false, the robustness of the unrestricted switcher terms would buy almost nothing, because the extrapolated $d_N$ and $d_T$ terms, which carry most of the population weight, would be wrong anyway.
So the efficiency-robustness tradeoff resolves for (B) on both ends: efficiency when the model is right, and no meaningful robustness gain from (A) when it is wrong.

### What each convention implies for the confidence interval

This is where the ranking becomes sharp rather than aesthetic.
The reported interval is the image of the joint $(\phi, \beta)$ acceptance region under the aggregate map, and projection of a valid joint confidence set through a known function yields a valid (conservative) confidence set for the function's value only when the function depends on the tested parameters and known constants alone.

Under (B), $g(\phi, \beta)$ depends on $(\phi, \beta)$ plus quantities treated as known ($\mu_{\underline{d}}$, $\pi_{\underline{d}}$, $\bar D_{\underline{d}}$, $\alpha_{d_T}^{\text{obs}}$).
Conditional on that known-constants treatment, which the draft already acknowledges for the shares in the E2 footnote, the projected interval is a valid weak-identification-robust confidence statement for the model-implied aggregate: coverage of $g(\phi_0, \beta_0)$ is at least the coverage of the joint region.
The interval also correctly widens when a switcher return crosses zero somewhere in the region, because the $\max(0, \cdot)$ kink is evaluated at the candidate parameters rather than at the point estimate.

Under (A), the switcher returns are estimated quantities held at their realizations, so the interval is conditional on them.
Two pieces of uncertainty are dropped: the sampling variance of the unrestricted returns themselves, and their covariance with the S-statistic moments, which is not zero because both come from the same auxiliary regression on the same sample.
The honest description is "a confidence interval for the aggregate, treating the unrestricted switcher returns as known," which undercovers by an amount that is small here but not signed or bounded in general.

Under (C), no clean coverage statement exists at all.
The frozen values $\beta_{\hat{}} + \hat\phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$ are functions of the estimator whose uncertainty the sweep is supposed to propagate, so the map being swept has a random argument frozen at its realization and a deterministic argument being varied, and the two arguments refer to the same underlying parameters.
The interval that comes out is neither a confidence set for the model-implied aggregate (that would require moving the switcher terms too) nor for the hybrid estimand of (A) (that would require the unrestricted values).
Describing it accurately in a published paper would require a sentence no referee should have to read.

### The mechanical direction of the (C) error

Freezing the switcher terms removes their contribution to the interval width, so (C) weakly understates the interval relative to (B) whenever $\phi$ or $\beta$ variation moves the switcher terms in the same direction as the $d_N$ term (which it does here, since all returns share the same line).
Small in this application, but the bias direction is toward overstated precision, which is the wrong direction to be sloppy in.

## Findings

1. Lens 3 (inference), CRITICAL, HIGH confidence.
The paper's identification paragraph (line 57 of [results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex)) describes convention (A): "The unrestricted GRC identifies the switcher returns $\Delta_{\underline{d}}$ for $\underline{d} \in \mathcal{D}_S$ non-parametrically," and the coincidence argument that follows justifies the realized-return interpretation via the unrestricted objects.
The implementation is convention (C): LCA-fitted values from the nlcom block on the restricted fit ([0_programs.do](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/scripts/0_programs.do) lines 2181-2202), frozen across the sweep in `delta_at` ([counterfactuals.py](file:///C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/counterfactuals.py) lines 560-564, base array at line 536).
Whichever convention the authors adopt, prose and code must describe the same estimator; as written the paper misdescribes the computation behind a headline table.
This blocks readiness regardless of the numeric closeness of the conventions.
Flagged for human decision; the adjudication above ranks the options but the choice alters reported results and requires user approval.

2. Lens 1 (identification design), MAJOR, HIGH confidence.
Convention (C) itself: each accepted lattice point evaluates the aggregate under two parameter values at once ($(\hat\phi, \hat\beta)$ for switchers, $(\phi, \beta)$ for $d_N$ and $d_T$), so the swept functional corresponds to no coherent model-implied estimand and the resulting interval has no clean coverage interpretation.
Numerically immaterial in this application; conceptually the weakest of the three conventions.

3. Lens 3 (inference), MAJOR, HIGH confidence.
The lumped unbalanced-switcher cell is the quantitatively serious instance of the same freeze.
`delta_at` assigns it `unb_choice_hat`, a scalar frozen at the GMM point estimate across the entire sweep (lines 540 and 562 of counterfactuals.py), and the draft itself reports that roughly nine in ten IDN individuals sit in that cell (line 75 of results_counterfactuals.tex).
For the enumerated switchers the freeze moves nothing because $\pi_{\underline{d}}$ is 1-6%; for the lumped cell it suppresses the uncertainty of the single largest contributor to the IDN "value of observed migration."
The narrow IDN interval of $[+5.7\%, +6.1\%]$ should be checked against this: if the lumped cell's return carries nontrivial sampling variance, the reported interval understates.
Whatever convention wins for enumerated switchers needs an explicit, stated treatment for the lumped cell (under (B), either an LCA-fitted value at that cell's $\mu$, if a mean rural consumption is computable for it, or explicit propagation of the coefficient's uncertainty; under (A), at minimum an acknowledgment that its sampling error is ignored).

4. Lens 4 (robustness) / code hygiene, MAJOR, MEDIUM confidence.
The exported column feeding `delta_arr_base` is named `delta_d_unrestricted` (counterfactuals.py line 536), yet the stated provenance is the nlcom block on the restricted fit, whose expressions $\Delta_s = \Delta_{\text{base}} + \phi(\mu_s - \mu_{\text{base}})$ are LCA-fitted values by construction.
Either the column name misdescribes restricted fitted values, or the export actually pulls unrestricted auxiliary coefficients and the implementation is (A) rather than (C); I could not verify `_export_e1_inputs.do` directly.
Confidence MEDIUM on which side is wrong, HIGH that the two cannot both be right.
Verify what the export writes and rename accordingly before any convention change, or the fix will be applied to the wrong object.

5. Lens 3 (inference), MINOR, HIGH confidence.
Under every convention, $\mu_{\underline{d}}$, $\mu_{\underline{d}_0}$, $\alpha_{d_T}^{\text{obs}}$, $\pi_{\underline{d}}$, and $\bar D_{\underline{d}}$ enter the propagation as known constants.
The E2 footnote justifies the fixed-shares treatment quantitatively (binomial SE near 0.003 against an inversion half-width near 0.02); no parallel justification exists for the $\mu$'s in E1.
A one-sentence version of the same order-of-magnitude argument would close this.

## Headline and cross-check

Report (B) as the headline and (A) as the cross-check, in that order, and retire (C).

The headline should read, in substance: all trajectory returns entering equation (1) are the LCA-implied values $\Delta_{\underline{d}}(\phi, \beta) = \beta + \phi(\mu_{\underline{d}} - \mu_{\underline{d}_0})$, recomputed at every $(\phi, \beta)$ in the joint inversion region, so switcher, never-migrant, and always-urban returns move coherently along the same line.
The cross-check then earns its place as an economically weighted companion to the $J$-test: replacing the fitted switcher returns with the unrestricted ones moves the gap by less than some stated number of percentage points, which tells the reader that the counterfactual does not lean on the restriction where the data can check it.
That is a strictly more informative use of the unrestricted returns than baking them into the headline, and it converts the passing $J$-test from a table statistic into a magnitude the counterfactual reader cares about.
The reverse ordering (headline (A), cross-check (B)) would pair a hybrid estimand with an undercovering interval as the paper's featured number, which is the worse of both worlds.

Implementation note for the point estimate: under (B) the point-estimate aggregate at $(\hat\phi, \hat\beta)$ uses the same nlcom fitted values the code already exports, so the headline point numbers likely do not move at all; only the sweep changes, and only through the small switcher terms.

## Conditions under which the ranking flips

First, a rejecting $J$-test.
If the overidentifying restrictions fail in a given cell, the LCA line is refuted precisely where the data can test it, and splicing fitted values over the unrestricted ones would launder a rejected restriction into the aggregate.
There (A) becomes the defensible convention for the switcher terms, the extrapolated terms carry explicit health warnings, and the draft's existing policy (line 32: report with caution, split by regime where the rejection is regime-driven) already points the right way.
Ranking becomes A > B, and (C) still never wins.

Second, large switcher weight.
If enumerated switchers carried, say, a quarter or more of the aggregate, the (A)-versus-(B) gap would become a substantive quantity rather than a footnote, and the paper would need to display both aggregates prominently whichever is the headline.
The ranking would not flip on validity grounds, but the cross-check would be promoted from footnote to table row.

Third, externally estimated switcher returns.
If the unrestricted returns came from a different sample or design than the GMM moments (they do not here; both come from the same auxiliary regression), the fixed-constants treatment under (A) would be more defensible, since the neglected covariance term would vanish.
This narrows the gap between (A) and (B) without reordering them.

Fourth, a purely descriptive target.
The first column of equation (1), the value of observed migration $\sum \pi_{\underline{d}} \Delta_{\underline{d}} \bar D_{\underline{d}}$, is dominated by switcher-identified terms ($\bar D_{d_N} = 0$, and $d_T$ is dropped under the P3 fallback).
If the paper wanted to present that column as a nonparametric descriptive fact rather than a model output, (A) is the natural convention for that column alone, with (B) reserved for the misallocation gap.
I would not recommend splitting conventions across columns of one table, but it is the one place (A) has an affirmative case rather than a robustness one.

## Overall assessment

The identification strategy of the counterfactual survives scrutiny conditional on resolving the convention question, and the question has a clear answer: the model-consistent convention (B) is the defensible headline, the unrestricted convention (A) is a valuable cross-check, and the current frozen-hybrid convention (C) should not appear in a published paper even though it is numerically indistinguishable here.
The two items that block readiness are the prose-code mismatch (finding 1) and, prior to any code change, the `delta_d_unrestricted` provenance check (finding 4); the lumped-cell freeze (finding 3) is the one place the convention choice could visibly move a reported interval.
This assessment is a prompt for the researcher's own judgment, not a substitute for it: the convention choice alters how a headline result is computed and described, and per project rules that decision belongs to a human.
