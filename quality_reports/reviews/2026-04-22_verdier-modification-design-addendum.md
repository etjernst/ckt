# Addendum to Verdier modification design memo: what $v_i$ can actually be in CKT

**Date:** 2026-04-22
**Relates to:** [2026-04-22_verdier-modification-design.md](file:///C:/git/ckt/.claude/worktrees/verdier/docs/reviews/2026-04-22_verdier-modification-design.md)
**Issue raised:** The primary recommendation (variant A) proposed using village fixed effects as the indexing variable $v_i$. This does not transfer directly from VV's setting to CKT because in CKT migration itself changes a person's location, so "village" is not a time-invariant cluster. The memo also did not properly articulate VV's exclusion restriction and what the CKT analogue has to buy.

This addendum (i) states VV's theoretical argument for $v_i$ in full, (ii) explains why direct translation to "village" fails in CKT, (iii) proposes $v_i$ candidates that respect CKT's structure, and (iv) connects the needed exclusion restriction to CKT's existing Assumption A2.

---

## 1. What VV's $v_i$ is doing, theoretically

### 1.1 The generalized identifying assumption

VV's robust extrapolation replaces the simple LCA (2.11) with assumption (2.18) (and its equivalent version 3.7):
$$E\!\left(a_i\mid b_i, x_{i1},\ldots,x_{iT}, v_i\right)=m(v_i)+\alpha_1 b_i.$$

Two things to notice:

1. Baseline heterogeneity $a_i$ can depend on $(x_{i1},\ldots,x_{iT})$ ONLY through $v_i$ and through the LCA term $\alpha_1 b_i$. Conditional on $(b_i, v_i)$, treatment history is irrelevant for predicting baseline productivity.
2. $v_i$ is treated as observable and *conditioned on*, not instrumented.

The mechanical implementation is a within-$v$ (cluster-demeaned) IV regression of $\hat a_i$ on $\hat b_i$, with treatment history as instruments for $\hat b_i$, on movers only. The stayer-ATE plug-in becomes
$$\widehat{ATE}_{d_N,v}=\frac{\bar a_{d_N,v}-\hat m(v)}{\hat\alpha_1},$$
averaged across $v$-clusters that contain at least one mover.

### 1.2 The primitive structure that justifies (2.18)

The derivation of (2.18) comes from decomposing the cost-of-treatment process. VV writes
$$x_{it}=g(b_i, c_{it}),\qquad c_{it}=f(w_i,n_{it}),$$
with $c_{it}$ the cost of treatment in period $t$, $w_i$ an observed index of cost shifters, and $n_{it}$ residual cost-shifter variation. The threshold-crossing illustration is $x_{it}=\mathbb{1}\{b_i\ge c_{it}\}$: a farmer adopts when return exceeds cost.

The exclusion restriction behind (2.18) (VV's (2.15) generalized to (2.17)/(2.18)) is:
$$n_{it}\perp (a_i,b_i)\mid v_i.$$

In words: conditional on the observed cost index $v_i$, the *residual* variation in cost — the part of $c_{it}$ not absorbed by $v_i$ — must be independent of both baseline productivity and returns. The rest of selection-into-treatment can flow through $v_i$ and through $b_i$ via $g$.

### 1.3 Why village works in Kenya

VV's argument (main paper, pp. 10, 28):
- Farmer productivity $(a_i,b_i)$ depends on agronomic conditions (rainfall, soil, altitude).
- Adoption cost $c_{it}$ depends on distance to the nearest seed seller and similar market-access frictions.
- Both agronomic conditions and market access are local: farmers in the same village share them.
- Within a village, residual adoption-cost variation $n_{it}$ is idiosyncratic (neighbor happened to adopt first, a random agent visited, etc.) and plausibly independent of individual productivity.

So village captures essentially all of the confounding $(a_i,b_i)\leftrightarrow c_{it}$ correlation. That's a *substantive* argument about the Kenyan maize-farmer setting, not a generic property of fixed effects. VV validates it with the overid test and with the distance-to-seed-seller covariate diagnostic.

---

## 2. Why "village" does not transfer to CKT

### 2.1 Time variation

In VV's dataset every farmer lives in one village for the full panel. Village is time-invariant. So $v_i$ is a well-defined individual-level variable and the within-$v$ transformation makes sense.

In CKT the outcome of interest is location itself. A rural-to-urban switcher lives in a different village (and often a different region) in each period. "Current village" is $v_{it}$, not $v_i$, and $v_{it}$ is a deterministic function of the treatment history $(D_{i1},\ldots,D_{iT})$. Using current village as $v_i$ would partial out exactly the variation we want to study.

### 2.2 Rural vs urban

In VV everyone is a farmer, so "village" is defined for all units with the same semantic content. In CKT "village of residence" in a rural period and "village of residence" in an urban period are not comparable objects — an urban neighborhood is not the rural analogue of an agricultural village. The within-$v$ transformation would combine rural and urban locations in the same cluster and cancel out the treatment itself.

### 2.3 Support

VV's robust extrapolation requires every always-rural $v$-cluster to contain at least one mover. In VV's Kenya data this held for 91% of untreated stayers. In CKT, for a village-level $v_i$ the picture is likely much worse: large numbers of always-rural individuals live in villages where *no one ever migrates out* (by definition if we're thinking of long-term non-migrants in remote areas). Village-level support is almost certainly thin in TZA and non-trivial-to-establish in IDN/CHN.

---

## 3. What $v_i$ should be in CKT

What we need from $v_i$ is: (a) observable at baseline, (b) time-invariant (or at least pre-treatment), (c) a good proxy for correlated cost shifters of migration, and (d) present in both the switcher and non-migrant subpopulations with overlap.

### 3.1 Candidates that respect the structure

**Origin region (village, district, or province of first observation).** For every individual (migrant or not) this is time-invariant and observed in the first wave. Migrants who left rural region $A$ for urban destination $X$ are still indexed by their origin $A$. Stayers in $A$ are also indexed by $A$. The cluster captures local labor-market conditions, distance to cities, sector composition, climate — the plausibly exogenous *push* factors. Residual cost-shifter variation $n_{it}$ within an origin region captures individual-level shocks like a relative's job offer, a family illness, a specific firm's hiring.

**Hukou status (CHN only).** Rural vs urban hukou is assigned at birth and is extraordinarily persistent (changing hukou is rare and bureaucratically expensive). It indexes the entire institutional migration cost structure for Chinese workers. This is the cleanest direct analogue to VV's village FE, because it's time-invariant, observable, and exactly the kind of cost shifter (2.18) targets. CKT already splits by hukou in CHN; the robust-extrapolation framing recasts this from an ad-hoc fix for the $J$-rejection into a principled implementation of VV's generalized IA.

**Birth region or ethnicity (where available).** If we observe place of birth or ethnic/caste identity, these are time-invariant and capture historical and social determinants of migration cost. Less universally available than hukou but worth checking.

**Pre-treatment baseline controls interacted with a coarser geography.** If we want more flexibility without blowing up the FE count, we can use (origin province) $\times$ (baseline characteristics) as the cluster structure. This approximates VV's linear-in-$w_i$ extension (his footnote 22 / 27).

### 3.2 Candidates that do NOT work (for the reasons above)

- Current village or current district.
- Current sector of employment.
- Any variable that changes with treatment status.
- Any destination-side variable (receiving region, urban district).

### 3.3 Revised variant A, per country

- **CHN:** $v_i=$ hukou status (rural/urban at baseline). Optionally also $v_i=$ province of origin. CKT already splits on hukou; this reframes that split.
- **IDN:** $v_i=$ province of origin (or kabupaten of origin if cell counts allow). IFLS records baseline household location.
- **TZA:** $v_i=$ region of origin (district may be too fine given 3-wave panel). TZNPS records baseline region.

Support for each candidate must be tabulated before committing.

---

## 4. What exclusion restriction is CKT signing up for, and does our existing model support it?

The exclusion restriction behind VV (2.18), translated to the CKT setting, reads:

> Conditional on $v_i$ and $b_i=\Delta_i$, the residual variation $n_{it}$ in migration cost $c_{it}$ is independent of $(a_i,b_i)$.

In CKT's decision rule (equation 10), migration is driven by the latent index
$$\beta+\phi\theta_i+E[\nu_{it}^U-\nu_{it}^R].$$
The role of the non-pecuniary shock $\nu_{it}^l$ in CKT is exactly the role of the residual cost shifter $n_{it}$ in VV's (2.17)--(2.18). And CKT's Assumption A2 already states that $\nu_{it}^l$ is i.i.d.\ across individuals, time, and locations.

So: if A2 holds exactly as currently stated, then $n_{it}=\nu_{it}^U-\nu_{it}^R$ is orthogonal to $(a_i,b_i)\equiv(\theta_i+\tau_i, \phi\theta_i)$ by construction, and VV's exclusion restriction is satisfied with $v_i$ equal to any observed time-invariant individual index.

**This is the key theoretical point.** CKT's current Assumption A2 is *stronger* than VV's exclusion restriction: it requires i.i.d.\ shocks across all units and periods, not just conditional independence given $v_i$. In the CKT framework as written, we already assume the residual cost shifter is independent of baseline and return heterogeneity. VV's (2.18) is simply a conditional version of the same assumption.

What then does adding $v_i$ actually buy us? It relaxes A2 in a specific direction: instead of requiring $\nu_{it}^l$ to be pure white noise, we now allow $\nu_{it}^l$ to have a cluster-level component $m(v_i)$ that is correlated with $(a_i,b_i)$. Only the residual $\nu_{it}^l - m(v_i)$ has to be uncorrelated. That is a weaker and more defensible assumption, especially across heterogeneous regions.

**So the case for variant A can be made from inside CKT's existing framework**, as follows:

1. Assumption A2 as currently stated requires $\nu_{it}^l$ to be i.i.d.\ across all workers, which is implausible across regions with very different migration infrastructure (e.g., coastal vs interior China).
2. The robust version of the LCA (VV's 2.18) weakens A2 to allow a region-specific shift $m(v_i)$ in the migration-cost distribution.
3. Under this weakened A2, the LCA holds conditional on $v_i$; pooling across $v$ without the cluster adjustment produces a biased estimate of $\phi$ (and, more importantly, biased plug-in stayer ATEs).

This is a defensible argument that maps onto the migration literature: migration costs are known to vary across regions (Bryan & Morten 2019; Lagakos et al. 2020); absorbing that variation at the region level is a small, targeted relaxation.

---

## 5. What the estimator actually looks like after this revision

The restricted GRC equation (eq. 12 in the manuscript) under $v_i$-indexed LCA becomes:
$$y_{it}=\sum_{\underline d,v}\mu_{\underline d,v}\mathbb{1}\{\underline d_i=\underline d, v_i=v\}+\Delta_{\underline d_0}D_{it}+\sum_{\underline d\in\mathcal D_S\setminus\{\underline d_0\}}\phi(\mu_{\underline d,v_i}-\mu_{\underline d_0,v_i})D_{it}\mathbb{1}\{\underline d_i=\underline d\}+\cdots+\varepsilon_{it},$$
i.e., the trajectory-specific rural-consumption means are replaced by trajectory-by-$v$ means, and the LCA extrapolation happens within $v$. The slope $\phi$ is still common across $v$; what varies by $v$ is the baseline $\mu_{\underline d,v}$.

The implementation in `run_grc` is:
1. Add $v_i$ interactions to the `mu` parameter set: `{mu: i.v never#i.v switcher_*#i.v}`.
2. The `nlcom` plug-in for $\Delta_{d_N}$ must be computed per $v$, then averaged over $v$-clusters with switcher support.
3. Standard errors cluster at $v_i$ (or two-way pid × $v_i$).

For CHN this is tractable: hukou has 2 values, so we add one interaction. For IDN/TZA with province-of-origin, the $v$ set is larger (10--30 values) and moment counts grow; the `gmm` solver should still handle it but convergence will need more careful initial values.

---

## 6. Revised open questions

Superseding the earlier list:

1. Confirm $v_i$ candidates: hukou for CHN; province-of-origin for IDN; region-of-origin for TZA.
2. Tabulate always-rural support: fraction of never-migrants in $v$-clusters that contain at least one switcher.
3. Does the manuscript want to state this as "relaxed Assumption A2 allows $v$-clustered migration-cost shifters" or as "robust extrapolation following Verdier (2020)"? The substantive theory is the same; the framing is a writing choice.
4. Do we want a specification chart showing results under (simple LCA) vs (robust LCA with $v$=hukou, $v$=province-of-origin) to let the reader see how much the stayer-ATE plug-in depends on $v$?
5. For CHN specifically: is the robust extrapolation with $v_i=$ hukou a different object from the current hukou-split GRC? It should be — the former pools the slope $\phi$ across hukou types with hukou-specific intercepts, while the latter estimates separate $\phi$ per hukou group. The distinction matters substantively.

---

## 7. What does not change

- The memo's variants B (VV's LCA overid test), C (cost-shifter diagnostic), and D (individual-level rewrite) are unaffected by this addendum.
- The ranking still puts variant A first, but with the revised $v_i$ candidates above.
- Variant B is still an independent diagnostic worth doing regardless.
- The `define_switcherpars` base-hardcoding issue is orthogonal.

---

## 8. Do we need an observed exogenous cost shifter for variant A?

This is an important theoretical distinction that the original memo blurred.

**Short answer: no for variant A, yes for variant C.** VV uses two different devices, and they serve different purposes.

### 8.1 $v_i$ vs $\bar d_i$: two different objects in VV

In VV's paper:

- $v_i$ is an observed **indexing variable** for the cluster structure of cost shifters. It does not have to be an exogenous continuous variable. In the Kenya application $v_i$ is just village membership --- a categorical label for which village a farmer is in. It enters the estimator through fixed effects.
- $\bar d_i$ is an observed **exogenous covariate**: average distance to the nearest seed seller in kilometres. It is a continuous variable with a specific, measurable interpretation. It enters the estimator as an additional exogenous regressor in the LCA equation.

### 8.2 What variant A needs

Variant A uses $v_i$. The only requirements are:

1. $v_i$ is observable at baseline.
2. $v_i$ is time-invariant (or at least pre-treatment).
3. The cluster structure $v_i$ plausibly captures the relevant cost-shifter variation --- formally, the residual cost shifter $n_{it}$ satisfies $n_{it}\perp (a_i,b_i)\mid v_i$.

No requirement to measure or even name the underlying cost shifters. Village in VV is a *proxy* for the bundle of distance-to-seller, road quality, agronomic conditions, cooperative presence, etc. The robust extrapolation absorbs all of them at once via fixed effects.

The claim "all correlation between migration cost and $(a_i,b_i)$ flows through $v_i$" is untestable in general but it can be partially checked:

- the VV overid test ($\chi^2(|S|-1)$) rejects if the within-$v$ LCA line does not fit;
- adding any candidate cost shifter $w_i$ as an extra regressor and testing $\alpha_{w}=0$ --- variant C --- is a second check.

Neither check requires us to hand over a named exogenous instrument.

### 8.3 What variant C needs

Variant C is the diagnostic that *does* need an observed exogenous cost shifter. The specification is
$$a_i=\alpha_0+\alpha_1 b_i+\alpha_2 w_i+e_i,\qquad w_i\perp (a_i,b_i)\ \text{except through the LCA},$$
and the hypothesis is $H_0:\alpha_2=0$. This is variant C exactly because $w_i$ has a measurable meaning and a testable coefficient.

Variant C is a *falsification test* of the simple extrapolation --- it does not fix anything, it only reveals whether the simple version is wrong. Variant A is the fix that does not require $w_i$ at all.

### 8.4 Summary table

| Device | Object | Role | Required to implement |
|---|---|---|---|
| $v_i$ | Categorical cluster label | Relaxes (2.11) to (2.18) via FE | Observable time-invariant index (variant A) |
| $w_i$ | Continuous exogenous cost shifter | Falsification test of (2.11) | Measured exogenous variable (variant C) |

Variant A can be done with $v_i$ alone. Variant C is the natural companion diagnostic but is not needed to produce estimates.

---

## 9. How many $v$-clusters do we need, and how do we justify the choice?

Two pieces: (i) a mechanical lower bound, (ii) a substantive justification.

### 9.1 Mechanical lower bound

The VV overid test has $|S|-1$ df where $|S|$ is the number of distinct switcher-trajectory profiles observed (not the number of $v$-clusters). So the $v$-count does not drive the df directly. What the $v$-count does drive is:

- **Degrees of freedom in the FE step.** Each $v$-cluster absorbs one parameter. With $n$ switchers and $|v|$ clusters, the second-stage IV regression has $n-|v|-1$ residual df. Need enough switchers per cluster to identify the common slope.
- **Asymptotic approximation.** VV's Proposition 7 treats $|v|\to\infty$ with $n_v\to\infty$ and asks $n_v/n\to$ constant (each cluster has non-vanishing share). This is the within-cluster asymptotic regime. In practice it wants "many clusters, each with several switchers."
- **Support of the stayer-ATE estimand.** Need always-rural individuals in $v$-clusters that contain at least one switcher.

There is no universal minimum, but rough rules of thumb from the cluster-robust-inference literature (Cameron--Miller 2015; MacKinnon--Webb 2017; Conley--Taber style with cluster-level variation):

- Fewer than about 20 clusters: cluster-robust SEs can be severely under-sized. Wild cluster bootstrap becomes essential rather than optional.
- Cells smaller than $\sim 10$ switchers per cluster: the FE absorbs most within-cluster variation and the slope is identified off a thin margin.
- Below $\sim 5$ switchers per cluster the cluster contributes essentially no information to $\hat\phi$.

This means the $v_i$ choice is constrained from both directions:

- Coarse $v_i$ (few clusters, many switchers per cluster): good within-cluster identification of $\phi$, but the cluster FE absorbs less cost-shifter variation --- weaker robustness.
- Fine $v_i$ (many clusters, few switchers per cluster): strong robustness claim but weak identification, and cluster-robust inference becomes dodgy.

For CKT concretely:

- **CHN:** hukou has $|v|=2$. This is *too few* for cluster-robust asymptotics. Implementable, but SEs should be bootstrap-based. Province of origin has $|v|\approx 30$; prefecture of origin has $|v|\approx 300$ --- either is better from a cluster-count standpoint but prefecture may be thin on switchers.
- **IDN:** province of origin has $|v|\approx 27$; kabupaten of origin has $|v|\approx 500$ --- probably too thin.
- **TZA:** region of origin has $|v|\approx 26$; district has $|v|\approx 120$ --- possibly OK given 3 waves but tight.

My revised suggestion: aim for $|v|$ in the 15--50 range per country, with $\ge 10$ switchers per cluster.

### 9.2 Substantive justification

The memo earlier appealed to CKT's existing Assumption A2 ($\nu_{it}^l$ i.i.d.) as the hook. That stands, but the justification for a specific $v_i$ needs to go further:

**What we have to argue.** The residual non-pecuniary migration cost $\tilde\nu_{it}^l=\nu_{it}^l-m(v_i)$ is uncorrelated with $(\theta_i,\tau_i)$. Equivalently, conditional on origin region, individual migration decisions are driven by idiosyncratic shocks rather than by local variables correlated with skill.

**What the migration literature says.** Bryan \& Morten (2019), Lagakos et al.\ (2020), Pulido \& Swiecki (2021) all document large region-level variation in migration costs driven by distance, infrastructure, language, and institutional barriers. Hukou (CHN specifically) is the institutional version. That region-level variation has to be absorbed somehow; A2 as currently written in CKT does not absorb it. Variant A does.

**What we cannot argue from data alone.** That $v_i$ at the chosen granularity is sufficient. We can only test for specific violations via the overid test or via variant C. The reader has to find the substantive argument for $v_i$ plausible.

**How to write this up.** A defensible justification has three parts:
1. A paragraph in the model section explicitly weakening A2 to A2$'$: $\nu_{it}^l=m_l(v_i)+\tilde\nu_{it}^l$ with $\tilde\nu_{it}^l$ i.i.d.
2. A paragraph per country describing *what* $v_i$ is taken to absorb (institutional migration barriers for CHN hukou; distance to labor-market centers for IDN provinces; agroclimatic zone for TZA regions).
3. A robustness table showing results under different $v_i$ choices --- if they are stable, the specific choice matters less; if they move around, we report the range.

This is the most vulnerable part of the paper to referee pushback and needs to be written carefully.

---

## 10. Why does partialing out location change anything? Intuition

This is the right question to have. Let me build it up from VV's Kenya example because the mechanics are clearer there.

### 10.1 The selection problem in the simple LCA

The LCA says: individual returns $b_i$ linearly predict individual baselines $a_i$, that is, $a_i=\alpha_0+\alpha_1 b_i+e_i$ with $e_i$ independent of everything else relevant. The identifying assumption behind the simple extrapolation (2.11) is that once we condition on $b_i$, treatment history $(x_{i1},\ldots,x_{iT})$ has no additional predictive content for $a_i$.

Why might this fail? Consider a farmer who lives 50 km from the nearest seed seller. Two things are true for her:
1. She has lower $a_i$ than the average farmer because her soil is poor, her road access is limited, her cooperative is weak.
2. She has lower probability of switching into hybrid seed use because adoption cost is high.

Now compare the two subpopulations of switchers:
- Switchers who adopted early ($x_{i1}=1$). These are farmers who adopted even when the seller was far. They tend to live near sellers or have high returns $b_i$ that overcome the cost.
- Switchers who adopted late ($x_{i1}=0, x_{iT}=1$). These include farmers in remote villages who only adopted once the cost came down.

The late adopters have systematically lower $a_i$ (remote villages) and they got into the mover sample precisely because the cost came down. Their $(a_i, b_i)$ pair does not lie on the population LCA line --- it is displaced by the cost-shifter structure.

If you run the simple IV regression of $\hat a$ on $\hat b$ using treatment-history indicators as instruments, the regression line is pulled away from the true LCA line by this selection. The extrapolation to stayers then uses this biased line, producing biased stayer ATEs. This is what happens in Suri's Kenya: $\hat\alpha_1=-0.49$ from the simple extrapolation, pulled far from the true relationship.

### 10.2 What village FE does mechanically

Village FE demeans $\hat a_i$ and $\hat b_i$ within village before the IV regression. That is, it replaces
$$\hat a_i,\ \hat b_i \ \text{with}\ \hat a_i-\bar a_v,\ \hat b_i-\bar b_v,$$
where $\bar a_v,\bar b_v$ are village-level means over movers. The resulting regression identifies $\alpha_1$ from *within-village* variation in switcher profiles --- e.g., from comparing a Karin who adopted in 1997 to a Jane who adopted in 2007, both living in village $V$.

Within a village, distance to the seller is constant. Road quality is constant. Agronomic conditions are roughly constant. So the within-village $(a,b)$ variation is purged of those cost shifters --- what varies within a village is idiosyncratic farmer-level stuff (a neighbor's recommendation, a family event, an individual risk preference). If that residual variation is orthogonal to $(a_i,b_i)$ --- VV's (2.18) --- then the within-village slope is an unbiased estimate of the true LCA.

In the Kenya result: the within-village estimate is $\hat\alpha_1=-0.95$ instead of $-0.49$. Interpretation: without partialing out village, the estimate was severely attenuated by the distance-induced selection. Partialling out village gives the "clean" slope, and plugging it back in gives $\widehat{ATE}_{d_N}=37\%$ instead of $66\%$.

### 10.3 Translation to CKT

Two regions of rural Indonesia --- call them $A$ and $B$. In region $A$, urban centers are 2 hours away and infrastructure is good. In $B$, urban centers are 2 days away and roads are seasonal.

- Average baseline productivity $a_i$ is lower in $B$ because of poor infrastructure, smaller markets, less-productive agriculture.
- Probability of migration (switcher status) is lower in $B$ because migration cost is high.
- The subset of people from $B$ who do migrate is selected: they are unusually high-$b_i$ (high return), unusually connected, etc.

Switchers from $A$ are a wide mix of types. Switchers from $B$ are a narrow, unusual subset. The population LCA slope $\phi$ should be estimated from comparable variation; if we pool switchers from $A$ and $B$ without adjustment, we are mixing apples and oranges.

Partialling out region-of-origin ($v_i=A$ or $v_i=B$) restricts identification to within-region variation. Within $A$, switcher selection is less skewed (migration is easy, many types go). Within $B$, switcher selection is more skewed but we are no longer mixing with $A$. The common slope $\phi$ is identified from the within-region variation in both.

The extrapolation to always-rural workers happens per region: within $A$ the LCA line extends to $A$'s stayers; within $B$ it extends to $B$'s stayers. The reported $\widehat\Delta_{d_N}$ averages over $v$-clusters with switcher support.

### 10.4 When does this change results?

- If $v_i$ is uncorrelated with $(a_i,b_i)$ in the first place, adding FE changes little; $\hat\alpha_1$ is similar to the simple spec.
- If $v_i$ captures large migration-cost heterogeneity that also correlates with productivity, $\hat\alpha_1$ can move a lot (Kenya: $-0.49\to-0.95$, stayer ATE $66\%\to 37\%$).

The pro-poor finding in CKT ($\phi<0$ across all three countries) could move in either direction under variant A. If the pattern is robust, so much the better. If it flips or strengthens substantially in specific countries, that is itself an important finding about how our simple-extrapolation estimates have been measuring sorting plus region-level selection together.

---

## 11. Revisiting variant D: what is actually hard about it?

My earlier "3--4 weeks, too ambitious for a first pass" framing was miscalibrated. Let me rebalance.

### 11.1 What is genuinely easy about variant D

Rewriting the Stata GMM call is not that hard. VV's `robust.do` is $\sim 200$ lines and does the whole joint two-step GMM with optimal instruments and the $\eta$ overid moments. Translating it to our data and variable names is mechanical; probably a week of work including debugging.

The identifying assumption, moments, and estimand are all well-specified in VV's paper and replication. We do not need to re-derive anything.

### 11.2 What is actually hard about variant D

The difficulty is not in the GMM rewrite. It is in the downstream consequences for the rest of the paper:

1. **The CKT manuscript's identification argument is built around trajectory aggregation.** The model section, the GRC representation, the interpretation of $\Delta_{\underline d}$ as trajectory-specific returns --- all of this is written around aggregating switchers into histories and reasoning about trajectory means. Variant D operates at the individual level. Adopting it means rewriting the model section to match.
2. **All results tables are trajectory-structured.** Tables 3--5 and appendix tables report $\mu_{\underline d}$, $\Delta_{\underline d}$, and the $\phi$ extrapolation per trajectory. Variant D does not produce trajectory-specific estimates in the same way; it produces a single $\alpha_1$, the mover subgroup averages that fed it, and the stayer ATEs.
3. **Heterogeneity figures (Section 4.2) are trajectory-based.** The "returns by trajectory type" plots that are core to the paper's argument do not come out of variant D naturally. You can recover them, but via different machinery.
4. **Existing co-author understanding and writing is aligned with the current estimator.** Shifting everyone's mental model of what the paper is doing is real work.

So my honest calibration of variant D:

- Technical code effort: 1--2 weeks (reasonable).
- Manuscript rewrite + figure/table redo: 4--8 weeks depending on how much we want to keep in parallel as robustness.
- Co-author alignment: nontrivial and depends on whether the team sees this as a strict improvement or a competing framing.

### 11.3 Variant D vs variant A: what you give up

Variant A keeps the trajectory-aggregated GRC machinery and adds $v_i$ FE on top. Variant D replaces the trajectory aggregation entirely.

You could argue either direction:

- **Keep trajectory aggregation (variant A).** The CKT paper has a specific contribution: the trajectory-level heterogeneity pattern, the $\mu_{\underline d}$-$\Delta_{\underline d}$ relationship, and the interpretation of migration histories. That structure is lost under variant D. Variant A preserves the structure and adds robustness.
- **Adopt VV's structure wholesale (variant D).** More defensibly estimated, cleanly comparable to VV's replication, cleaner joint standard errors. But different paper in the end.

My current read: variant A is the right call for *this* paper. Variant D would be the right call for a methods-focused companion paper ("we re-estimate the Suri (2011) / Tjernström (2023) framework using Verdier's machinery"). The two are complementary rather than competing.

### 11.4 Hybrid: variant A with variant D's inference

There is a middle path: keep the trajectory-aggregated moment structure of the current `run_grc`, but borrow VV's inference tooling --- joint two-step GMM with `nocommonesample`, cluster bootstrap on both steps, analytical sandwich from Propositions 6/8. This gives us the correct joint standard errors without restructuring the paper's identification story. It is maybe a week of engineering and no manuscript rewrite.

I should have flagged this in the original memo. It is probably the minimum-risk change that still materially improves the paper.

---

## 12. Summary of revisions to the original ranking

| Variant | Original | Revised |
|---|---|---|
| A (robust extrapolation with $v_i$) | Primary recommendation, $v_i$ = village | Primary recommendation, $v_i$ = origin region / hukou (time-invariant) |
| A$'$ (inference tooling only) | Not identified | New: adopt VV's joint-two-step-GMM inference without changing identification |
| B (LCA overid test) | Complementary diagnostic | Unchanged |
| C (cost-shifter diagnostic) | Complementary robustness | Unchanged; now clarified as the *only* variant requiring an observed exogenous shifter |
| D (individual-level rewrite) | "Too ambitious, 3--4 weeks" | Code is 1--2 weeks; the real cost is manuscript rewrite. Probably for a methods companion, not this paper. |

The honest version is: **A + A$'$ + B is the right package**, probably 3--4 weeks total. C is a nice-to-have if we can identify cost shifters per country. D is future work.

---

## 13. Can we default $v_i$ to first-wave location?

Question raised: we may not have explicit "province of origin" or "region of origin" variables in the CFPS, IFLS, and TZNPS data. Can we default $v_i$ to the location where we first observe each individual?

**Short answer: yes, with two caveats.** First-wave location is the conventional pragmatic choice in the panel-migration literature. But it is not "origin" in the strict sense VV's exclusion restriction asks for, and the granularity matters.

### 13.1 Why first-wave location is not strictly "origin"

VV's (2.18) asks $v_i$ to be pre-treatment. If we interpret treatment as "location choice in period $t$," then $v_i$ pre-treatment means $v_i$ fixed before any location decision we observe.

First-wave location is pinned down by location decisions made *before* wave 1. For someone whose migration history predates our panel, the first-wave location is itself a consequence of earlier treatment choices:

- A Sichuan-born worker who migrated to Shanghai in 2005 and is first observed in CFPS 2010 in Shanghai has $v_i=$ Shanghai under this definition. Their structurally relevant "origin" (rural Sichuan) is invisible to us.
- A rural-born Indonesian who migrated to Jakarta before IFLS 1993 similarly gets $v_i=$ Jakarta.

In both cases, using first-wave location as $v_i$ misassigns cluster membership relative to VV's ideal --- we would be clustering on post-migration location for pre-panel migrants.

### 13.2 Why this is usually tolerable

Three reasons this is the defensible pragmatic choice:

1. **Baseline sample restriction.** If we restrict attention to individuals first observed as children or young adults --- before their first migration decision --- then wave-1 location *is* pre-treatment for them. CFPS oversamples young household members; IFLS has a large youth panel. For the subset of individuals who had not yet migrated by wave 1, first-wave location coincides with origin. We can report the results restricted to this subsample as a robustness.
2. **Non-migrants dominate.** In all three CKT countries, $>90\%$ of individuals never migrate during the panel. For non-migrants, first-wave location equals every-wave location equals (plausibly) origin. The problem is concentrated among the $\le 10\%$ who migrate.
3. **It is what the literature does.** Kleemans (2018), Hamory et al.\ (2021), Bryan \& Morten (2019), Lagakos et al.\ (2020), and Pulido \& Swiecki (2021) all use first-observed location (or similar) to index origin in panel migration analyses. This is a defensible convention.

### 13.3 Granularity matters more than the exact "origin" label

The coarsest possible first-wave location is the binary rural/urban indicator. If we use *that* as $v_i$, we collapse to only two clusters --- and those two clusters are essentially collinear with the non-switcher structure. Always-rural stayers all have $v_i=$ rural; always-urban stayers all have $v_i=$ urban. The within-$v$ switcher variation used to identify $\phi$ is then whatever switchers started where they started. This is almost certainly too coarse.

For the FE to do meaningful work, $v_i$ needs sub-national geography: province, prefecture, district, village, or community. All three datasets record PSU-level geography (sampling clusters) and typically a broader region code too:

- **CFPS (CHN)** records province and county codes for every individual at every wave. Hukou registration province is typically recorded separately and is closer to "origin" in the strict sense for Chinese workers than is current province.
- **IFLS (IDN)** is explicitly community-based --- every individual has province (propinsi), kabupaten, kecamatan, and village (desa) codes. Community-tracking is a design feature.
- **TZNPS (TZA)** records region, district, and EA-level codes for every wave.

So candidate $v_i$ variables at different granularities likely exist for all three countries. The question is which ones are in the *cleaned* CKT-ready dataset, as opposed to what exists in the raw survey files.

### 13.4 What we should check before committing

Before writing any spec, we need to know for each country:

1. What geographic variables are in `data/processed/` (i.e., survive the cleaning pipeline in `1_processData.do`)?
2. At what granularity are they recorded?
3. How many values does each take, and how many switchers per cluster do we get at each granularity?
4. For CHN: is hukou registration province (or hukou status) preserved? The CKT manuscript already discusses hukou, so it should be somewhere in the pipeline.

These are read-only questions. I can inspect `1_processData.do` and the processed `.dta` files to produce a table of candidate $v_i$ variables per country, their granularity, and per-cluster switcher counts --- all without any data modification. That feasibility survey is the natural next step before the spec.

### 13.5 How this changes the recommendation

Replace the earlier per-country defaults with:

- **CHN:** first-wave province if present (otherwise first-wave prefecture). Compare against hukou registration province as a secondary specification. If hukou status is recorded, report hukou-pooled and hukou-split versions both.
- **IDN:** first-wave propinsi. If kabupaten/kecamatan-level cell counts are adequate, report at that finer level as well.
- **TZA:** first-wave region. District level as secondary if cell counts allow.

All three are "first-wave" definitions in practice. The manuscript framing should state this explicitly: "We index $v_i$ by an individual's location in the first panel wave, which we treat as pre-treatment. For individuals whose migration history predates the panel, this is a proxy rather than a true origin." A robustness check restricted to individuals young enough at wave 1 to plausibly not have migrated yet would strengthen the claim.

### 13.6 What I propose as the next concrete step

A short data-feasibility note (not a spec, not code changes) that answers:

1. What geographic variables are in `data/processed/` per country?
2. At each granularity, how many unique values are observed?
3. How many switchers per cluster, per country, per granularity?
4. What fraction of always-rural individuals live in clusters with at least one switcher?

This is a couple hours of read-only `tab`s and `by` statements in a fresh `.do` file under `explorations/`. It would let us pick the right $v_i$ per country on the basis of cell counts rather than guessing. I can draft this if you approve.
