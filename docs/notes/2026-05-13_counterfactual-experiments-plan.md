# Counterfactual experiments: plan and design notes

**Added:** 2026-05-13.
**Branch:** lca-inversion.
**Status:** design memo. Canonical reference; HTML at [2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html) is a readable mirror.
#1 has three nested reporting options (conservative floor / heterogeneity-corrected / bounded envelope) to address within-trajectory heterogeneity in returns; all three to be delivered.
#2 has a lower bound version (immediate, falls out of #1's machinery) and a resorting version (uses the model's existing decision rule in eq.~(6); requires a shock-distribution choice and a parameterization of the institutional barrier).
#3 (from consumption to welfare) has two parallel routes: Suri-style observables (primary, generalizes the hukou comparison across all three countries) and a parametric Heckman-style assumption on $\nu$ (single welfare number under a stated distribution).
A Borjas-style benchmark with panel extensions (Carneiro-Hansen-Heckman / Cunha-Heckman factor structure; Kennan-Walker dynamic Roy) sits in the back of our mind as a later robustness exercise.

## Why these counterfactuals

The paper delivers identification and estimates but not magnitudes.
The pro-poor finding ($\phi < 0$) is a coefficient.
The non-migrant extrapolation is reported through the slope and intercept of $\Delta_i = \beta + \phi\theta_i$ rather than as "the average never-migrant in country $c$ would gain $X$ log points."
The counterfactuals below convert the identified objects into readable magnitudes that align with the paper's stated contribution.

## Notation

$y_{it}^l$ is systematic log consumption in location $l \in \{R, U\}$.
$\theta_i^R, \theta_i^U$ are location-specific time-invariant productivities.
$\theta_i \equiv b_R(\theta_i^U - \theta_i^R)$ is rescaled comparative advantage.
$\phi \equiv (b_U - b_R)/b_R$ is the LCA slope.
$\Delta_i = \beta + \phi\theta_i$ is the worker-specific return to urban location.
$\mu_{\underline{d}}$ is the average rural mean for trajectory $\underline{d}$.
$\Delta_{\underline{d}}$ is the average return for trajectory $\underline{d}$.
$\mathcal{D}_S$ is the set of switcher trajectories; $d_N$ is always-rural; $d_T$ is always-urban.
$\pi_{\underline{d}}$ is the population share of trajectory $\underline{d}$.
$\bar{D}_{\underline{d}}$ is the share of periods spent urban within trajectory $\underline{d}$.
$\underline{d}_0$ denotes the base switcher trajectory in the restricted GRC.

---

## 1. Aggregate misallocation accounting

**Question.** What is aggregate log consumption under optimal sorting versus observed sorting, expressed as a percentage of observed consumption?

**Identified objects (all in hand).**
- $\pi_{\underline{d}}$ from the data.
- $\mu_{\underline{d}}$ for every trajectory from the GRC.
- $\Delta_{\underline{d}}$ for $\underline{d} \in \mathcal{D}_S$ from the unrestricted GRC (non-parametric).
- $\Delta_{d_T}$ from the LCA inversion (the inversion CI bounds it).
- $\Delta_{d_N}$ from the LCA extrapolation: $\Delta_{d_N} = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$.

**Computation.**
Per trajectory, the per-worker gain from moving from observed to optimal sorting is $\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}} \bar{D}_{\underline{d}}$.
The aggregate gap is
$$\text{Misallocation gap} = \sum_{\underline{d}} \pi_{\underline{d}} \left[\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}} \bar{D}_{\underline{d}}\right].$$
The $d_N$ piece contributes most of the mass because $\bar{D}_{d_N} = 0$ and $\pi_{d_N}$ is large in every country (back-of-envelope: $\approx 0.75$ TZA, $\approx 0.65$ CHN, $\approx 0.50$ IDN; shares to verify against descriptives).

**Headline output.**
Per country: misallocation gap as a percentage of observed aggregate consumption.
Decomposition: share of the gap attributable to non-migrants ($d_N$), to switchers, and to always-urban workers ($d_T$).

**Inference.**
The largest sources of uncertainty are $\Delta_{d_T}$ (Möbius pole as $\phi$ approaches $-1$, [docs/notes/2026-04-30_mobius-singularity.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-04-30_mobius-singularity.md)) and $\Delta_{d_N}$ (proportional to $\phi$).
The natural inference object is the inversion confidence region: for each $(\phi, \beta)$ in the joint inversion CI, compute the misallocation gap; report the convex hull.
This propagates the existing inversion CI machinery directly.

**Open questions.**
How to handle countries or specs where the inversion CI brushes $\phi = -1$: report the gap conditional on a non-empty CI, or report the gap restricted to the $d_N$ and switcher pieces, since those do not depend on $\Delta_{d_T}$.
Whether to express the aggregate in log points (cleanest given the consumption equation) or in level percentage (cleaner for the abstract; requires a Jensen-style adjustment).

### Both extremes: zero migration as the lower bound

The misallocation gap measures observed sorting versus optimal sorting.
Pairing it with the converse---observed sorting versus zero migration---brackets where observed migration sits in the range of possibilities.
Let $W_{\text{obs}}, W_{\text{zero}}, W_{\text{opt}}$ denote aggregate log consumption under the three scenarios.
Then:
$$\underbrace{W_{\text{obs}} - W_{\text{zero}}}_{\text{current welfare gains from migration}} = \sum_{\underline{d}} \pi_{\underline{d}} \cdot \Delta_{\underline{d}} \cdot \bar{D}_{\underline{d}}; \qquad \underbrace{W_{\text{opt}} - W_{\text{obs}}}_{\text{misallocation gap}} = \sum_{\underline{d}} \pi_{\underline{d}} \left[\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}} \bar{D}_{\underline{d}}\right].$$

The zero-migration calculation is cleaner than the optimal-sort one.
The $d_N$ piece drops out because $\bar{D}_{d_N} = 0$.
Within-trajectory heterogeneity in $\Delta_i$ does not enter because everyone in a trajectory shares the same $\bar{D}$.
Only conditional means are needed, all identified by the GRC: the switcher piece uses the non-parametric $\Delta_{\underline{d}}$ from the unrestricted GRC; the $d_T$ piece uses $\Delta_{d_T}$ from the LCA inversion.

**Back-of-envelope using col-5 estimates and the rough trajectory shares.**
- TZA: $\pi_{d_T} \cdot \Delta_{d_T} \approx 0.14 \cdot (-0.66) \approx -9$ log pts; switcher piece $\lesssim 0.1$ log pts. Net $\approx -9$ log pts.
Observed migration delivers *negative* net welfare under the LCA point estimates.
- IDN: $\pi_{d_T} \cdot \Delta_{d_T} \approx 0.46 \cdot (-0.10) \approx -4.4$ log pts; switcher piece small. Net $\approx -4$ log pts.
Same direction as TZA, smaller magnitude.
- CHN: pooled spec does not report $\Delta_{d_T}$ (the $J$-test rejects, so the inversion machinery returns empty CIs and the $\Delta_{\text{always}}$ row is omitted).
Compute regime by regime once the hukou-split tables are extended to include $\Delta_{d_T}$ rows.

**Implication.**
Combining the two extremes: observed migration delivers no detectable net welfare gain in TZA or IDN under the LCA point estimates, while optimal migration would deliver $\approx 22\%$ (TZA) or $\approx 3.7\%$ (IDN).
The misallocation gap is essentially the entire potential value of migration.
The lower bound is fragile---driven by point-estimate $\Delta_{d_T}$ in the wide multi-island inversion CI---so report it with the same CI propagation as $\Delta_{d_T}$ itself.
The upper bound is more robust because the $d_N$ piece dominates and does not depend on $\Delta_{d_T}$.

### Within-trajectory heterogeneity in returns: three reporting options

The trajectory-mean formula above treats every never-migrant as if they share the same return.
Under LCA, $\Delta_i = \beta + \phi\theta_i$ varies within trajectory whenever $\theta_i$ does, so the formula is implicitly a no-within-heterogeneity assumption.
The GRC identifies the conditional mean $\Delta_{d_N}$ but not the conditional dispersion.
The same caveat applies inside $d_T$ and inside switcher trajectories; $d_N$ is where it bites hardest because of population share and because LCA extrapolation does most of the work.

**Direction of error.**
Optimal sort assigns to urban the workers with $\Delta_i > 0$, so the aggregate gain from $d_N$ is $\pi_{d_N} \cdot E[\max(0, \Delta_i) \mid d_N]$, not $\pi_{d_N} \cdot \max(0, E[\Delta_i \mid d_N])$.
With $\Delta_{d_N} > 0$, the conditional expectation of the positive part weakly exceeds the positive part of the conditional mean (Jensen, convexity of $\max(0, \cdot)$).
The trajectory-mean number is a lower bound on the true gap.
Under $\phi < 0$, the lowest-$\theta$ never-migrants carry the highest unrealized returns, so optimal sort moves precisely those workers---a feature, not a wrinkle, of the pro-poor finding.

**Option 1: conservative floor.**
Trajectory-mean formula as written.
Defensible as a lower bound under LCA; no extra structure beyond what the GRC already delivers.
This is the back-of-envelope $\approx 22\%$ / $6.5\%$ / $3.7\%$ for TZA / CHN / IDN.
Reporting sentence: "at least $X\%$ of consumption is unrealized."

**Option 2: heterogeneity-corrected.**
The paper's model section already specifies a location-choice rule (eq.~(6) at [sec_model.tex:119--123](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/sections/sec_model.tex)): a worker chooses urban iff $\beta + \phi\theta_i + (\nu_{it}^U - \nu_{it}^R) > 0$, with $\nu^l$ iid across individuals, time, and locations.
We do not need to invent a sorting rule; under this rule, $d_N$ membership requires the shock to go against urban in every period, so $f_{\theta \mid d_N}(\theta) \propto f_\theta(\theta) \cdot F_\eta(-\beta - \phi\theta)^T$, where $f_\theta$ is the population density of $\theta_i$ and $F_\eta$ is the CDF of $\nu^U - \nu^R$.
Parametric choices: $\theta_i \sim N(0, \sigma_\theta^2)$ with $\sigma_\theta$ pinned by cross-trajectory dispersion of $\mu_{\underline{d}}$; $\nu^l$ normal or type-I extreme value (the model leaves this open beyond iid).
Integrate $\max(0, \beta + \phi\theta)$ over $\theta_i \mid d_N$ numerically (recall $\bar{D}_{d_N} = 0$).
Delivers a magnitude, not a floor; adds two parametric assumptions (one for $\theta_i$, one for $\nu$), both made explicit.

**Option 3: bounded envelope.**
Parameterize the within-$d_N$ dispersion as $\sigma_{\theta \mid d_N} = c \cdot \sigma_\theta$ for $c \in [0, 1]$.
At $c = 0$, recovers Option 1 as a point; at $c = 1$, the within-trajectory share equals the pooled population variance (a plausible upper limit).
Compute Option 2's integral on a grid of $c$ and plot the gap as a function of $c$; the audience reads the envelope rather than committing to a single value.
Cleanest in that the only choice on the reader's table is "how dispersed should you think within-$d_N$ comparative advantage is?".

**Tension with the decision rule.**
Under $\phi < 0$ and rational sorting via eq.~(6), never-migrants should have $\Delta_{d_N} < 0$ on average (workers with negative returns self-select rural).
The empirical $\Delta_{d_N} > 0$ under LCA therefore signals either an institutional barrier that suppresses rational sorting (the hukou story in #2) or LCA misspecification off-support.
Either way, the misallocation calculation is interpretable: it quantifies how much consumption is left on the table by the friction (institutional or specification) that prevents observed sorting from matching the model's predicted sorting.

**Deeper concern: LCA out of the switcher support.**
$(\beta, \phi)$ are identified from switcher trajectories; all three options extrapolate to $d_N$.
If LCA is a local approximation around the switcher region, the slope identified from switchers may not carry over to never-migrants, and the $d_N$ piece of every option becomes shaky.
The paper already addresses this through the $J$-test and the inversion CI as the primary inference object.
The misallocation reporting inherits the same identification machinery and the same caveats; the options above sit on top of LCA, not next to it.

**Cost.**
Both extremes (no migration vs current, and current vs optimal) share a common pipeline: extract trajectory-level $\mu_{\underline{d}}, \Delta_{\underline{d}}, \bar{D}_{\underline{d}}, \pi_{\underline{d}}$ from `.ster` files and panel data; aggregate; propagate inference through the inversion CI.
Pipeline build is roughly two to three days.
Once built, the zero-migration aggregate (current welfare gains) and the optimal-sort Option 1 (conservative floor on misallocation) drop out in parallel.
Options 2--3 of the misallocation calc share their own additional machinery (parametric within-trajectory $\theta_i$ distribution; numerical integration over the model's choice rule from eq.~(6); grid sweep on $c$); together they add two to three more days.
Compute cost is small throughout.

---

## 2. The hukou puzzle and what removing it would unlock (China only)

**Question.**
The CHN hukou-split estimates show inverted patterns across regimes.
Rural-hukou never-migrants carry a large unrealized return under a flat LCA slope; urban-hukou never-migrants carry essentially zero return under a steep LCA slope.
What does the contrast reveal, and what does a counterfactual that "removes hukou" deliver on top of the existing estimates?

**The numbers (CHN, col 5, urban_unb, consumption).**

| | Rural-hukou | Urban-hukou |
|---|---|---|
| $\Delta_{d_N}$ | $0.106$ (large, positive) | $0.006$ (essentially zero) |
| $\phi$ | $-0.04$ (flat slope) | $-0.97$ (steep slope) |
| $J$-stat ($p$) | $12.6$ ($0.13$) | $7.1$ ($0.22$) |
| Subsample share of CHN | $\approx 74\%$ | $\approx 26\%$ |

**Mechanical decomposition.**
Recall $\Delta_{d_N} = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$.
Two ways for $\Delta_{d_N}$ to come out where it does:
- Rural-hukou: $\phi \approx 0$ flattens the LCA line, so $\Delta_{d_N} \approx \beta \approx 0.106$.
The 10 log point return looks uniform across the comparative-advantage distribution.
- Urban-hukou: $\phi \approx -1$ tilts the line steeply, and $\beta$ approximately cancels the never-migrant offset $\phi(\mu_{d_N}^{uh} - \mu_{\underline{d}_0}^{uh})$.
Never-migrants sit at the point where the line crosses zero.

**Economic reading.**
The two regimes appear to trace out two different worlds side by side.

*Rural-hukou: sorting suppressed.*
The institutional barrier prevents workers from sorting on comparative advantage.
The estimated LCA slope is flat not because skills are homogeneous, but because the heterogeneity is not being revealed through migration choices---high-comparative-advantage workers are stuck rural.
The 10-log-point $\Delta_{d_N}^{rh}$ is the unrealized return that sorting would deliver.
It looks uniform precisely because the workers who would sort have not been allowed to, so the observed slope cannot distinguish them.

*Urban-hukou: sorting works.*
Workers choose where to locate.
Comparative advantage drives the choice.
The steep negative $\phi^{uh}$ reflects revealed heterogeneity in returns.
Never-migrants here are not blocked, they are sorted: they chose rural because their personal return to urban location is approximately zero (consistent with the model's decision rule in eq.~(6) under $\phi < 0$).
$\Delta_{d_N}^{uh} \approx 0$ describes optimally placed workers, not victims of an institutional wedge.

**Implication.**
The hukou system suppresses the comparative-advantage sorting that operates freely for urban-hukou holders.
The fact that $\phi$ varies across subsamples is itself the evidence that institutions, not just preferences, are doing real work.

**Is this regime-driven or LCA misspecification?**
A competing reading is that $\Delta_i = \beta + \phi\theta_i$ holds within each regime but with different $(\beta, \phi)$ because the LCA linearity is a local approximation that bends differently when fit to different selected populations.
Under that reading, $\phi^{rh} \neq \phi^{uh}$ is a specification fact, not an institutional fact.
The way to discriminate is the hukou-split overid tests: in col 5, $p^{rh} = 0.13$ and $p^{uh} = 0.22$.
Both fail to reject the LCA restriction within their own regime, so the institutional reading is the parsimonious one.

### What removing hukou would unlock

The right counterfactual is "what if rural-hukou holders could sort freely?".
Under the reading above, the high-return workers would migrate, and the residual never-migrants would have expected return close to zero, matching the urban-hukou pattern.
The welfare gain is the integral of positive returns over the rural-hukou never-migrant distribution.

**Lower bound from existing estimates.**
The bound uses identified objects only.
Assume the flat $\phi^{rh}$ reflects genuine uniformity of returns within rural-hukou, so every rural-hukou never-migrant gets the same 10 log points.
Then:
$$\text{Welfare gain (lower bound)} \;\approx\; \pi^{rh} \cdot \pi_{d_N}^{rh} \cdot \Delta_{d_N}^{rh} \;\approx\; 0.74 \cdot 0.65 \cdot 0.106 \;\approx\; 5 \text{ log points}$$
The bound is conservative: if the flat slope is instead a censoring artifact of suppressed sorting, the welfare gain rises above the bound because optimal sort selects the high-return tail.

**Resorting version (primary policy answer).**
Use the model's existing decision rule from eq.~(6).
Apply it to rural-hukou workers under the "no hukou" assumption that the rule operates without the institutional barrier.
The barrier itself can be parameterized as an additive cost $c$ that shifts $\beta^{rh}$ down to $\beta^{uh}$ (i.e., the wedge is $\beta^{rh} - \beta^{uh}$, and removing hukou sets the wedge to zero).
Simulate which rural-hukou workers select urban under the no-barrier rule and compute the aggregate consumption gain.
This delivers a magnitude rather than a bound and a confidence interval that propagates through the choice model.

**What the simulation adds.**
- Distributional bounds: the lower bound assumes uniform returns; the resorting simulation delivers the magnitude.
- A confidence interval that propagates the inversion CI on $\phi^{rh}$ and $\phi^{uh}$ through the simulation.
- A decomposition of the gain into (a) returns realized by the marginal migrant, (b) the unrealized return left in the residual never-migrant pool.

**Headline output.**
Percentage gain in CHN aggregate consumption from removing the hukou wedge, decomposed into marginal-migrant and residual pieces.

**Open questions.**
The two regimes do not share a common base trajectory, so the choice of $\mu_{\underline{d}_0}$ matters numerically for the bound.
Two reasonable conventions: (a) anchor on the urban-hukou base used in the original 8_GrRC_hukou tables; (b) re-estimate both regimes with a common base for the counterfactual.
We should run both and report the range.

**Cost.**
Lower bound is half a day, falls out of #1's machinery.
Resorting version requires (i) a choice for the shock distribution $F_\eta$ (the paper leaves it iid but unspecified), (ii) a parameterization of the institutional barrier, (iii) simulation of the rural-hukou subpopulation's choice probabilities under no barrier.
Figure two to three days for a working version once the sorting specification is locked in.

---

## 3. From consumption to welfare: valuing the non-pecuniary side

**Question.**
The counterfactuals in #1 and #2 report consumption-side statistics.
Converting them to welfare requires putting a value on the non-pecuniary component of $\nu^U_i - \nu^R_i$, which the LCA framework deliberately does not identify on its own.
Two routes are available, both with precedent in the literature: observable proxies in the Suri (2011) style and a parametric assumption on $\nu$ in the Heckman style.
We plan to do both.

### Route A: Suri-style observables

Suri (2011, Section 7) resolves her high-counterfactual-returns puzzle by relating predicted $\hat\theta_i$ to observable cost proxies (distance to fertilizer sellers, distance to roads, infrastructure) rather than imputing the cost component from choice probabilities under a distributional assumption.
The analogous move for us: model the persistent component of $\nu^U_i - \nu^R_i$ as $X_i'\gamma$ for some observable vector $X_i$ that affects non-pecuniary value of location but not the consumption return $\Delta_i$.
The decision rule from eq.~(6) becomes "choose urban iff $\beta + \phi\theta_i + X_i'\gamma + (\text{iid component}) > 0$."
The GRC already identifies $\Delta_i$; a probit or logit using $X_i$ alongside trajectory predictions of $\Delta_i$ pins down $\gamma$.
Welfare counterfactuals then include $X_i'\gamma$ as the non-pecuniary value the model puts on observed location.

The benefit of doing this cross-country: it generalizes the hukou comparison we already have, which only speaks for China.
The same exercise can run in Indonesia and Tanzania with appropriate observables.

**Cross-country observable candidates.**
- Distance from birthplace or origin village (direct Suri analog).
- Family network at origin (relatives in rural areas).
- Ethnic or community ties concentrated by location.
- Marital status and household composition.
- Age and life-cycle position.

**Country-specific augmentations.**
- CHN: hukou (already have), native-province status, family in rural counties.
- IDN: Javanese-or-not, transmigration history, family in origin village.
- TZA: ethnic group, linguistic region, family ties at origin.

**Exclusion restriction concerns.**
$X_i$ must affect non-pecuniary value of location but not the consumption return $\Delta_i$.
Variables already in the consumption equation (education, age, female) cannot also serve as exclusion restrictions because they enter $\Delta_i$ via $\gamma$.
Distance to birthplace and family-network variables are the most defensible candidates.

**Headline output.**
Country-level decomposition: how much of the gap between observed sorting and rational-sorting predictions is attributable to identifiable non-pecuniary observables versus residual unexplained variation.
The residual is what the parametric route would then have to value.

### Route B: parametric (in parallel)

Maintain the paper's existing A2 (iid $\nu$) and add a parametric form for $\eta_{it} = \nu^U_{it} - \nu^R_{it}$.
Two natural choices: type-I extreme value (logit-style choice probabilities, closed-form expected utility, $\sigma_\eta^2 = \pi^2 \sigma^2 / 6$) or normal (probit-style, slightly more numerical work but familiar in empirical micro).
Identification: under iid $\eta$,
$$\pi_{d_T} = E_\theta\!\left[(1 - F_\eta(-\Delta(\theta)))^T\right]$$
pins down $\sigma_\eta$ from the observed trajectory share $\pi_{d_T}$, the GMM-identified distribution of $\Delta_i$, and the panel length $T$.
Multiple trajectory shares give over-identification.
Once $\sigma_\eta$ is pinned, the non-pecuniary value to a $d_T$ worker is the truncated mean $E[\eta \mid d_T]$, a standard Heckman-style inverse-Mills-ratio calculation.
This is the same machinery Suri uses for her ATE/TT/MTE benchmarks in Section 5.2.

**Why both routes.**
Route A makes the empirical case: "here is what we can attribute to identifiable amenity proxies."
Route B delivers a single welfare number under a stated distributional assumption: "under iid type-I EV, the welfare gap is $X\%$."
The two are complements, not substitutes.
Reporting both gives a defensible range and lets the audience choose the reading they trust most.

### Borjas-style benchmark (later TODO)

Borjas (1987) assumes joint log-normality of $(\theta^U, \theta^R)$ in source and destination, then identifies skill prices and selection patterns from cross-sectional wage moments.
Our LCA approach deliberately avoids this distributional assumption.
Worth running as a benchmark robustness exercise: estimate $b_U$ and $b_R$ separately under joint log-normality, characterize selection patterns, compare to what LCA delivers.

Panel extensions of Borjas to cite or adapt:
- Heckman \& Honor\'e (1990, ECMA): formal identification result for the Roy model under different data structures including panels.
- Lemieux (1998, JOLE): panel-based CRC, the direct ancestor of Suri and CKT.
- Carneiro, Hansen, \& Heckman (2003, IER); Cunha, Heckman, \& Navarro (2005, 2006); Cunha \& Heckman (2007): factor structure approach. Recover the joint distribution of $(\theta^U, \theta^R)$ from panel plus auxiliary measurements without imposing joint normality.
The cleanest panel extension of Borjas in spirit.
- Heckman \& Vytlacil (2005, ECMA): MTE framework with panel data; identifies the full distribution of treatment effects.
- Dahl (2002, ECMA); Kennan \& Walker (2011, ECMA): migration-specific.
Dahl is multi-destination Roy with selection correction; Kennan-Walker is dynamic Roy of migration with panel, the modern structural template.
- Lagakos, Mobarak, \& Waugh (2023): recent migration-specific structural Roy with cross-country data, closest in spirit to our setting.

The natural Borjas-with-panel adaptation for us would be Carneiro-Hansen-Heckman or Cunha-Heckman: factor structure recovery of the joint skill distribution, then Borjas-style selection characterization.
Less ambitious than Kennan-Walker; more honest about its parametric structure than vanilla Borjas.

**Cost.**
Route A: identify defensible observable proxies, verify availability across CFPS, IFLS, TZNPS; estimate a probit/logit per country plus integration of $X_i'\gamma$ into the counterfactual aggregates.
Approximately 3--4 days.
Route B: reuse the trajectory-level estimates, add the $\sigma_\eta$ identification step plus truncated-mean integration.
2--3 days.
Borjas benchmark: separate exercise, lower priority.

**Status.**
Design open.
Pre-requisite: catalog of available observables across the three panels.

---

## Sequencing

Natural order: #1 first, #2 in parallel (bound version), #2 resorting next, then #3.
#1 reuses the inversion CI machinery and delivers the headline consumption-side number.
#2 bound reuses existing hukou-split estimates; #2 resorting uses the model's existing decision rule in eq.~(6).
#3 has two parallel routes (Suri-style observables and parametric Heckman-style); both can run once the trajectory-level extraction pipeline from #1 exists.

#1 and #2 (bound) are paper-ready consumption-side additions in their current scope.
#2 (resorting) and #3 are the moves that take us from consumption to welfare; both are model extensions that need design work first.
A Borjas-style benchmark with panel extensions (Heckman-Honor\'e identification, Carneiro-Hansen-Heckman / Cunha-Heckman factor structure, Kennan-Walker dynamic Roy, Lagakos-Mobarak-Waugh structural migration) sits in the back of our mind as a later robustness exercise.
