# 2026-05-13---counterfactual experiments brainstorm, design memo, and HTML overview

Mode: design / documentation.
No code or estimation touched this session.
Picked up from [2026-05-11's inversion-table-format session](file:///C:/git/ckt/.claude/worktrees/lca-inversion/quality_reports/session_logs/2026-05-11_inversion-table-format-and-period-fe-paragraph.md), which had closed the inversion table rendering end-to-end.

## Goals

The user wanted to revisit the "counterfactual experiments leveraging CKT's two-skill structure" TODO from 2026-05-08 (sitting on the main tree at [docs/TODO.md:77](file:///C:/git/ckt/docs/TODO.md)) and start fleshing out concrete designs.
The 2026-05-08 entry framed the exercise as differentiation from Verdier; the user redirected mid-session to "what would really boost the paper," moving the framing from methodological one-upmanship to magnitudes-the-audience-presses-on.

## What got produced

### Design memo

[docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md)
Lead motivation: the paper currently reports identification and estimates but not magnitudes.
$\phi < 0$ is a coefficient.
The non-migrant return is reported through $(\beta, \phi)$ rather than as "the average never-migrant in country $c$ would gain $X$ log points."
Four experiments selected from a broader brainstorm:

1. Aggregate misallocation accounting (optimal vs observed sorting, % of consumption).
2. Hukou wedge in welfare units (CHN-only; original framing was "apply urban-hukou returns schedule to rural-hukou trajectories", revised mid-session---see below).
3. Decomposing the pro-poor result ($\phi < 0$) into skill-price wedge vs joint skill-distribution channel.
4. Asymmetric human-capital policy: how the distribution of $\Delta_i$ shifts under expanded rural schooling, given $\epsilon_U \neq \epsilon_R$.

Status: #1 and #2-bound use identified objects directly and can be implemented now.
#2-resorting, #3, and #4 require model extensions or external calibration before any code.

### HTML overview

[docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html)
Single-page, self-contained, MathJax for equations.
Visual language cribbed from the `create-overview` skill: cream background, Source Serif Pro body + Inter sans labels, rust accent for ready-to-implement sections (#1, #2), amber for design-open (#3, #4), tile grids for the four-part structure of each experiment, expert-mode collapsibles for caveats.
Notation reminder in a sidebar-style aside up top so a cold reader has every symbol defined before the experiments start.

### TODO entry

[docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md) top of Active.
Entry "Counterfactual experiments: misallocation, hukou wedge, pro-poor decomposition, schooling".
Points to the memo and HTML.
Sequencing: #1 first, #2-bound in parallel with #1, #2-resorting next (model extension), #3 and #4 after their design memos.

## Mid-session decisions

### Refocus away from Verdier-differentiation

Original 2026-05-08 brainstorm framed counterfactuals as "what makes us look better than Verdier."
The user explicitly redirected: "let's focus less on differentiating from Verdier and on what would really boost the paper."
The right filter became "convert identified parameters into magnitudes the audience presses on."
This eliminated several previously proposed exercises (cross-country price-vs-quantity decomposition, sector-vs-location, decomposing observed migration gains) as "second paper material."

### Selected #6, #7, #9, #10 from a larger menu

User picked these four from a list of 10 brainstormed counterfactuals.
Renumbered #1--#4 in the memo.
The original #6 (aggregate misallocation) became the headline; the original #7 (hukou wedge) became "what unlocks the policy question"; #9 (pro-poor decomposition) and #10 (asymmetric schooling) ended up design-open.

### Back-of-envelope before implementation

User asked whether back-of-envelope outcomes were possible before running anything.
Pulled actual estimates from [RP7/output/tables/](file:///C:/git/ckt/.claude/worktrees/lca-inversion/RP7/output/tables/) col 5 (covs_all, urban_unb, consumption):

- TZA: $\Delta_{d_N} = 0.270$, $\phi = -0.719$ (95% inv. CI $[-1.22, -0.45]$), $\bar{\Delta} = 0.012$.
- CHN (pooled): $\Delta_{d_N} = 0.098$, $\phi = -0.205$, $\bar{\Delta} = 0.004$.
J-test rejects at 5% pooled (hence the hukou split).
- IDN: $\Delta_{d_N} = 0.071$, $\phi = -0.525$ (95% inv. CI $[-1.23, -0.01]$), $\bar{\Delta} = 0.003$.

CHN hukou-split col 5:

- Rural-hukou: $\Delta_{d_N}^{rh} = 0.106$, $\phi^{rh} = -0.04$ (essentially flat), $J = 12.6$ ($p = 0.13$).
- Urban-hukou: $\Delta_{d_N}^{uh} = 0.006$, $\phi^{uh} = -0.97$ (steep), $J = 7.1$ ($p = 0.22$).

Using rough trajectory shares ($\pi_{d_N}$ approximately $0.75$ TZA, $0.65$ CHN, $0.50$ IDN; these are guesses, NOT verified against descriptive tables and should be confirmed before any paper-grade number), the back-of-envelope misallocation gap is:

- TZA: $\approx 22\%$ of aggregate consumption (driven almost entirely by $\pi_{d_N} \cdot \Delta_{d_N}$; switcher contribution under $0.1\%$).
- CHN: $\approx 6.5\%$.
- IDN: $\approx 3.7\%$.

These are publication-worthy magnitudes.
They are consistent with Lagakos et al.\ (2023) and Bryan-Chowdhury-Mobarak (2014).
And they're driven by the LCA extrapolation to $d_N$, which is exactly the paper's headline contribution.

### Reframing of #2 mid-session

The user noticed and flagged the structural pattern in the CHN hukou tables:
rural-hukou has large $\Delta_{d_N}$ + flat $\phi$;
urban-hukou has zero $\Delta_{d_N}$ + steep $\phi$.
Worked out the mechanical decomposition ($\Delta_{d_N} = \beta + \phi(\mu_{d_N} - \mu_{\underline{d}_0})$) and the economic reading:

- Rural-hukou: sorting suppressed. Returns look uniform at 10 log points because the heterogeneity is not being revealed.
- Urban-hukou: sorting works. Steep $\phi$ reflects revealed heterogeneity. Never-migrants are sorted, not blocked.

Both J-tests fail to reject in col 5, so the institutional reading is parsimonious over the "LCA misspecification across populations" alternative.

This changed the framing of #2 in the HTML.
The old framing ("apply urban-hukou returns schedule to rural-hukou") was conceptually wrong---it doesn't answer the policy question because the urban-hukou returns schedule describes a sorting equilibrium and applying it to an unsorted population is not "what removing hukou would do."
The right counterfactual is "what if rural-hukou could sort freely."
Removed the easy-version-as-primary framing; replaced with:

- Lower bound from existing estimates: $\pi^{rh} \cdot \pi_{d_N}^{rh} \cdot \Delta_{d_N}^{rh} \approx 0.74 \cdot 0.65 \cdot 0.106 \approx 5$ log points.
- Resorting version (primary): requires a location-choice equation as a function of $(\theta_i^R, \theta_i^U)$.
- What simulation adds: distributional bounds + inference.

The bound and the resorting version are now both visible in the HTML overview.

## Open items

- Verify trajectory shares $\pi_{d_N}, \pi_{d_T}, \pi_{S}$ against actual descriptive tables before producing paper-grade misallocation numbers.
The back-of-envelope used rough guesses (TZA $\approx 0.75$, CHN $\approx 0.65$, IDN $\approx 0.50$).
- Implementation of #1 (aggregate misallocation): 1--2 days, reuses inversion CI machinery.
- Implementation of #2 bound: half a day, falls out of #1.
- Design decision for #2 resorting version: how to model location choice as a function of $(\theta_i^R, \theta_i^U)$.
- Design memo for #3: write out what $\phi$ identifies under LCA in terms of skill prices and the joint skill distribution; pick among (a) external calibration, (b) higher moments, (c) structural choice equation.
- Calibration source for #4: $\epsilon_U / \epsilon_R$ from Young (2013), Lagakos-Mobarak-Waugh (2023), or Hamory et al.\ (2021).

## How to pick back up

The canonical reference is the memo: [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).
For a readable view of the same content with the hukou puzzle interpretation up front, open the HTML in a browser: [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html).
The TODO entry at the top of Active in [docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md) points to both.

Next concrete step is implementing #1.
That session should start by verifying actual $\pi_{d_N}$ values from the descriptive tables before plugging into the misallocation formula.
The formula is in the memo: $\text{gap} = \sum_{\underline{d}} \pi_{\underline{d}} \left[\max(0, \Delta_{\underline{d}}) - \Delta_{\underline{d}}\bar{D}_{\underline{d}}\right]$.
Inference propagates by recomputing the gap at each $(\phi, \beta)$ in the inversion CI joint region and reporting the convex hull.

---

## Continued: afternoon refinements

### Within-trajectory heterogeneity in returns added to #1

The user pointed out that the trajectory-mean misallocation formula treats every never-migrant as if they share the same return, which under LCA assumes no within-trajectory $\theta$ heterogeneity.
The user wanted to attempt all three reporting options as deliverables, not pick one.
Added a new H3 subsection under #1 in both files with three options:

1. *Conservative floor*: trajectory-mean formula. Lower bound under LCA.
2. *Heterogeneity-corrected*: uses the paper's existing decision rule (eq.~(6)) plus parametric assumptions on $f_\theta$ and $F_\eta$ to integrate $\max(0, \beta + \phi\theta)$ over $\theta \mid d_N$.
3. *Bounded envelope*: parameterize $\sigma_{\theta \mid d_N} = c \cdot \sigma_\theta$ for $c \in [0, 1]$ and report the gap as a function of $c$.

Also added a "direction of error" callout: under $\Delta_{d_N} > 0$ and any within-trajectory variance, $E[\max(0, \Delta_i) \mid d_N] \geq \max(0, \Delta_{d_N})$ by Jensen, so the trajectory-mean number is a lower bound on the true gap.
Fixed a stale "$\pi_{d_N} > 0.9$" claim that conflated $d_N$ with all non-switchers; replaced with the rough country-specific guesses ($\approx 0.75$ TZA, $\approx 0.65$ CHN, $\approx 0.50$ IDN; flagged as needing verification).

### Sorting rule already in the paper

User: "check our model section, don't we already have a sorting rule there?"
Read `sec_model.tex` and confirmed eq.~(6): a worker chooses urban iff $\beta + \phi\theta_i + (\nu^U - \nu^R) > 0$ with $\nu^l$ iid.
Under iid shocks, $f_{\theta \mid d_N}(\theta) \propto f_\theta(\theta) \cdot F_\eta(-\beta - \phi\theta)^T$.
This means Option 2 of #1 and the resorting version of #2 do not need a NEW sorting equation---both can reuse the paper's existing decision rule.
Updated language in both files (Option 2 tile, resorting tile in #2, related cost lines) to reference eq.~(6).

Also added a substantive observation as a "Tension with the decision rule" callout: under $\phi < 0$ and rational sorting, never-migrants should have $\Delta_{d_N} < 0$ on average, but empirically $\Delta_{d_N} > 0$ under LCA.
This tension IS the misallocation story---it points either to an institutional barrier (the hukou story) or to LCA misspecification off-support.

### Memo's #2 brought into sync with HTML's #2

The earlier session had updated the HTML's #2 (puzzle-first framing: sorting suppressed vs sorting works; bound + resorting versions) but left the memo's #2 in the old "easy version applies urban-hukou returns to rural-hukou trajectories" framing.
User: "let's update the memo, I agree to keep it as the canonical source."
Rewrote the memo's #2 in full to mirror the HTML structure:
header status block updated, contrast table for the numbers in markdown, mechanical decomposition, "sorting suppressed" vs "sorting works" subsections, institutional-vs-LCA-misspecification discussion using the actual $J$-test $p$-values, lower-bound calculation, resorting-version description that references eq.~(6) and parameterizes the institutional barrier as an additive cost.

### Zero-migration as second extreme added to #1

User: "could we also do a 'zero migration' bound to have both extremes?"
Then: "that would give us sort of an estimate of the 'current welfare gains from migration.'"
Added a new H3 subsection inside #1 (HTML and memo) showing:
$$\underbrace{W_{\text{obs}} - W_{\text{zero}}}_{\text{current welfare gains from migration}} = \sum_{\underline d} \pi_{\underline d} \Delta_{\underline d} \bar D_{\underline d}$$
alongside the existing misallocation formula.
Noted that the zero-migration calc is cleaner than optimal-sort: within-trajectory heterogeneity doesn't enter because everyone in a trajectory shares the same $\bar D$.

Back-of-envelope: TZA $d_T$ piece $\approx 0.14 \cdot (-0.66) \approx -9$ log pts; IDN $\approx 0.46 \cdot (-0.10) \approx -4$ log pts; switcher piece negligible in both.
CHN pooled spec does not report $\Delta_{d_T}$ (the $J$-test rejects, so the inversion machinery returns empty CIs and the $\Delta_{\text{always}}$ row is omitted from the table).
The striking finding under LCA point estimates: observed migration delivers near-zero or negative net welfare; optimal migration would deliver $\approx 22\%$ (TZA), $\approx 3.7\%$ (IDN).
The misallocation gap is essentially the entire potential value of migration.

User pushed back on the back-of-envelope: "let's not get too hung up... the full counterfactual thing needs a bit more than point estimates and population shares, isn't it?"
Acknowledged: yes, proper implementation needs trajectory-level $\mu_{\underline{d}}, \Delta_{\underline{d}}, \bar D_{\underline{d}}, \pi_{\underline{d}}$ extracted from `.ster` files and the panel data, plus inference machinery (bootstrap or inversion-CI propagation through the aggregate).
Updated both files' cost lines: pipeline build 2--3 days, both extremes drop out together once pipeline exists, Options 2--3 of misallocation add 2--3 more days for parametric integration.

### Three explanations for negative $\Delta_{d_T}$

User worried about the negative-realized-returns reading: "what could explain it? And does it align with our model?"

Three explanations identified:

1. *Contradicts model's rational-sorting prediction*: under $\phi < 0$ and the decision rule in eq.~(6), $d_T$ pool should be dominated by high-$\Delta_i$ workers. LCA inversion says the opposite. Symmetric to the $\Delta_{d_N} > 0$ contradiction already in the memo.
2. *Model itself flags the candidate explanation*: `sec_model.tex:108` concedes that persistent non-pecuniary factors would weaken the trajectory-as-$\theta$ interpretation. Negative $\Delta_{d_T}$ is exactly the kind of evidence that the i.i.d. assumption on $\nu$ is too strong.
3. *LCA-extrapolation artifact*: the M\"obius denominator $1+\phi = 0.28$ for TZA col 5 amplifies estimation noise by $\sim 3.6\times$; the multi-island inversion CI signals fragility; cross-spec instability ($\Delta_{d_T}$ ranges from $+1.43$ in TZA col 1 to $-0.66$ in col 5) suggests the LCA line is being fit off-support.

### Paper-bound interpretation addendum drafted

User: "write this up as a few paragraphs I can include in the end of my main results section. Make them a separate .tex file and do make sure you take a look at the results section before drafting."

Read `sec_results.tex` to match voice (declarative "we"-statements, ties to tables, sentence-case headings, $\Delta_{d_N}, \Delta_{d_T}, \phi, \nu_{it}^l$ notation, J-test references already in section).
Wrote [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex): five paragraphs, standalone, no preamble, ready to paste at the end of the GRC subsection.

Structure of the five paragraphs:
1. Identification rests on A1--A5; A5 is the testable piece via $J$; trajectory-conditional averages are well-defined population objects.
2. Estimates suggest tension with the decision rule: negative $\Delta_{d_T}$ in TZA/IDN, positive $\Delta_{d_N}$ everywhere.
3. Not evidence against identification; evidence that A2 is strained.
Section~\ref{sec:model_identification} already concedes this; our estimates put magnitudes on it.
4. Hukou comparison sharpens the reading: where the institutional barrier is absent, LCA aligns with rational sorting; where it binds, it doesn't.
5. Consumption-vs-welfare caveat for counterfactuals: our estimates identify the consumption side of $\Delta_i$; reallocations would raise consumption but forgo non-pecuniary value.

### HTML informal version added

User: "also add the more informal version above to the html file (can be a new section that's fine it doesn't have to fit perfectly)."

Added a new section between #4 and the Sequencing footer, with olive accent (`s-olive`) to distinguish it from the counterfactual experiments.
Structure: lead with the "isn't the model wrong?" reaction → "what the moments need" with the displayed $E[\varepsilon_{it} z_{it}] = 0$ equation → "the $J$-test is the formal check" with a 5-row table of $J$-stats and $p$-values → "what the negative $\Delta_{d_T}$ means" → "consumption vs welfare qualification" → "framing for a referee" with a 4-tile defense → closing punchline callout.

### Caught an inconsistency

User caught a real loose end: "hang on, the moment conditions hold under A1--A5 and one of them is that $\nu$ is iid..."

I had been claiming "iid $\nu$ doesn't matter for identification" while A2 (iid $\nu$) is in the paper's identification list.
This was overclaiming.
Refined the framing in three places in the HTML and two paragraphs in the paper-bound .tex:

- A1--A5 *jointly* imply the moments hold. The paper says this; we should too.
- A5 (LCA) is formally testable through $J$.
- A1--A4 are maintained, including A2.
- The negative $\Delta_{d_T}$ is evidence that A2 is *strained* (persistent $\nu$ would generate it), but the testable consequence---a violation of A5---does not occur in our reported specs.
- So the estimates remain consistent estimates of trajectory-conditional averages; what loosens is the structural reading that those averages represent what rational sorters in $\underline{d}$ would have realized.

The cleaner position the user articulated---"A2 is in identification; the testable consequence is A5 via $J$; our specs pass even when the estimates indicate A2 is strained"---is the one both files now defend.

## Files changed in the afternoon

- [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html): added heterogeneity subsection within #1, zero-migration subsection within #1, new "How to read the results" section between #4 and Sequencing; multiple framing refinements; added the missing `.contrast-card`/`.contrast-cell` CSS rules that had been cribbed without their stylesheet (fix for a rendering bug the user spotted).
- [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md): all the same content additions; #2 fully rewritten to match HTML's puzzle-first framing; cost lines updated.
- [docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): the Counterfactuals entry's cost line revised to reflect three-options-for-#1 and bound-vs-resorting-for-#2.
- [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex): new standalone .tex file with five paragraphs to paste at the end of `sec_results.tex`.

## Updated open items

- Verify trajectory shares $\pi_{\underline{d}}$ for every trajectory against descriptive tables before any number lands in a draft.
- Implement #1's pipeline (2--3 days): extract trajectory-level estimates from `.ster` files, compute $W_{\text{obs}}, W_{\text{zero}}, W_{\text{opt}}$, propagate inversion CI through.
- For #1 Options 2--3: pick parametric forms for $f_\theta$ and $F_\eta$ (truncated normal? type-I extreme value?); implement integration over the model's choice rule.
- For #2 resorting: parameterize the hukou barrier as an additive cost; calibrate the wedge from $\beta^{rh} - \beta^{uh}$ or similar; simulate.
- For #3 and #4: design memos still outstanding.

## Updated how to pick back up

The canonical reference is still [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).
The HTML mirror [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html) is now richer than the morning version: contains the heterogeneity options for #1, the zero-migration extreme, and the "How to read the results" defense section with the four-pillar framing and the $J$-test table.
The paper-bound interpretation paragraphs at [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex) are ready to copy into `sec_results.tex` after the hukou subsubsection.

The defensible model framing crystalized in the afternoon: A1--A5 jointly identify; A5 is the testable piece; the negative $\Delta_{d_T}$ is evidence that A2 (i.i.d.\ $\nu$) is strained but not enough to violate A5; the estimates are conditional averages and well-defined; what we should hedge is the structural reading of "what rational sorters in $\underline{d}$ would have done," not the parameter estimates themselves.

---

## Continued: evening session

Three substantive threads in the evening.
First, the user asked three meta-questions: whether our counterfactuals fit the standard definition of "structural model," whether defensible assumptions on $\nu$ would let us reach welfare, and what someone meant by "the standard Roy model thing."
Confirmed CKT is structural in the textbook sense (estimating parameters of an explicit Roy model and using them to simulate counterfactuals), but light on the spectrum: we get $\phi$ rather than separately identifying $b_U, b_R$, and we don't model migration costs.
The "standard Roy thing" turned out to mean Borjas-style.

Second, the user asked to verify what Suri (2011) does with her error term.
Extracted the Suri PDF (papers/extracted/suri2011.pdf via pypdf) and read the relevant sections.
Three findings worth recording:

1. Suri's main CRC estimation uses Chamberlain (1982, 1984) panel projection.
No distributional assumption is needed.
This is exactly what CKT does too (the GMM with trajectory indicators is the saturated Chamberlain projection).
2. Suri's decision rule (her eq.~25) has $\vartheta_{it}$ as period-to-period cost fluctuations.
She does not parametrize this for her main estimates.
3. For her ATE / TT / MTE treatment-effect benchmarks (Section 5.2, Table IV), Suri uses joint normality.
This is the standard Heckman two-step.
She uses it as a benchmark, not as her preferred specification.

The substantive insight from Suri: she resolves the "high counterfactual returns for non-adopters" puzzle (her Section 7) by relating predicted $\hat\theta_i$ to observable cost proxies (distance to fertilizer sellers, distance to roads, infrastructure), not by imputing the persistent cost component from choice probabilities under a distributional assumption.
The observables route is the cleaner empirical case.

Third, the user pruned the counterfactual experiment list from four to three.
The user dropped the pro-poor decomposition and the asymmetric-schooling exercise as "I don't think we'll go there."
Renumbered the consumption-to-welfare experiment from #5 to #3.

### Decisions, with the why

- *Dropped #3 (pro-poor decomposition) and #4 (asymmetric schooling).*
The pro-poor decomposition (skill prices versus joint skill distribution) would have required additional structure---external calibration, higher moments, or a structural choice equation---that the user did not want to commit to.
Asymmetric schooling needed external calibration of $\epsilon_U / \epsilon_R$ that we cannot defend cleanly.
Both were "design open" with substantial pre-coding work; dropping them tightens the paper's scope.
- *Added a new #3, "From consumption to welfare: valuing the non-pecuniary side."*
The consumption-vs-welfare distinction had been a caveat under #1 and a piece of the model-defense section.
Promoting it to its own experiment makes the welfare extension a deliberate piece of work rather than a footnote.
The user wants this for the paper, not just as a robustness check.
- *Two parallel routes for #3: Suri-style observables and parametric Heckman-style.*
The Suri-style observables route is the primary empirical case, because it generalizes the hukou comparison across all three countries.
The user explicitly did not want to limit the welfare exercise to hukou (one country).
The parametric route delivers a single welfare number under a stated distribution and acts as a complement.
Reporting both gives a defensible range.
- *Cross-country observables candidates for Route A: distance from birthplace, family network at origin, ethnic or community ties, marital status, age, plus country-specific augmentations.*
The exclusion-restriction logic requires $X_i$ to affect non-pecuniary value of location but not the consumption return $\Delta_i$.
Variables already in the consumption equation (education, age, female) cannot also serve as exclusion restrictions because they enter $\Delta_i$ via $\gamma$.
Distance-to-birthplace and family-network variables are the most defensible.
- *Borjas-style benchmark stays in the back of our mind, sketched in an expert pocket under #3.*
The user said "later TODO."
The panel extensions named in the sketch (Heckman-Honor\'e 1990, Lemieux 1998, Carneiro-Hansen-Heckman 2003, Cunha-Heckman 2007, Heckman-Vytlacil 2005, Dahl 2002, Kennan-Walker 2011, Lagakos-Mobarak-Waugh 2023) are the references we should cite or adapt if we go that route.
The most natural adaptation is Carneiro-Hansen-Heckman / Cunha-Heckman factor structure, which recovers the joint distribution of $(\theta^U, \theta^R)$ from panel + auxiliary measurements without imposing joint normality.

### Approaches considered and rejected

- *Limiting the welfare route to hukou.*
Considered because we already have the comparison.
Rejected because hukou is China-only and the user wants a cross-country framing.
- *Doing only the parametric route.*
Considered because it delivers a clean single number.
Rejected because Suri's precedent makes the observables route the cleaner empirical case, and the user wants both.
- *Making Borjas-style its own experiment #4.*
Considered because it is a serious alternative.
Rejected because the user said "later" and the paper structure is tighter with three core experiments.
- *Going full Lagakos-Mobarak-Waugh structural migration model.*
Considered as the maximalist alternative.
Rejected as too ambitious for the immediate paper scope; flagged in the Borjas sketch as the "modern structural template" if we ever want it.

### Files changed in the evening

- [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html): added new section "5. From consumption to welfare" between #4 and "How to read"; then deleted old #3 and #4; renumbered #5 to #3; sequencing footer rewritten.
The Borjas sketch lives in an expert pocket inside the new #3.
- [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md): the same content moves; intro status block rewritten to describe the three experiments plus the Borjas back-pocket note; sequencing footer rewritten.
- [docs/TODO.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/TODO.md): counterfactuals entry retitled to "misallocation, hukou wedge, consumption-to-welfare"; cost lines updated to reflect Routes A and B of #3; Borjas-benchmark sub-entry added with the panel-extension citations spelled out.

### Updated open items

- Verify trajectory shares $\pi_{\underline{d}}$ for every trajectory against descriptive tables before any back-of-envelope number lands in a draft.
This is the cheapest concrete next step ($\sim 30$ minutes).
- Implement #1's pipeline (2--3 days): extract trajectory-level estimates from `.ster` files, compute $W_{\text{obs}}, W_{\text{zero}}, W_{\text{opt}}$, propagate inversion CI.
- For #1 Options 2--3: pick parametric forms for $f_\theta$ and $F_\eta$.
- For #2 resorting: parameterize the hukou barrier as an additive cost; simulate.
- For #3 Route A: catalog available observable proxies across CFPS, IFLS, TZNPS.
This is the prerequisite for any code.
- For #3 Route B: identify $\sigma_\eta$ from trajectory shares plus the GMM-estimated distribution of $\Delta_i$; compute truncated-mean $E[\eta \mid d_T]$.
- Borjas-style benchmark: only after the paper is closer to submission; treat as robustness.

### How to pick back up

The canonical reference is still [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md).
The HTML mirror at [docs/notes/2026-05-13_counterfactual-experiments-plan.html](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.html) is the readable view and now shows three experiments (rust / rust / amber) plus the olive "How to read the results" interpretive section.
The paper-bound .tex addendum at [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex) is ready to paste into `sec_results.tex` after the hukou subsubsection.

The natural next concrete action is verification of trajectory shares before any pipeline build.
That is a 30-minute warm-up that improves the credibility of the headline back-of-envelope numbers ($\approx 22\%$ TZA, $\approx 6.5\%$ CHN, $\approx 3.7\%$ IDN), which currently rest on rough guesses.
After that, the trajectory-extraction pipeline is the 2--3 day commitment that unlocks #1, #2 bound, and Route B of #3 in parallel.

There are uncommitted changes across the four files modified this session.
A clean commit before /clear would make the state recoverable and let the next session start from `git log`.

---

## Continued: paper-bound draft of the counterfactual experiments section

Mode: drafting.
Picked up after /clear from a clean working tree; the morning/afternoon/evening commits were already in (`bd9f0b7`).

### Goals

The user asked for a draft section of the paper describing the planned counterfactual experiments, to be added at the end of the current results section, written in the way the migration-counterfactual literature typically describes such exercises (Mobarak et al.\ in particular).
Framed explicitly as "two counterfactual experiments," which constrained the scope to #1 (aggregate misallocation) and #2 (hukou wedge) from the canonical memo; experiment #3 (consumption-to-welfare) demoted from a standalone experiment to a closing bridge paragraph that flags it as ongoing work.

### What got built

[paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex), 87 lines, standalone .tex with header comment listing every cross-ref and citekey used.
Four subsections: `\subsection{Counterfactual experiments}` (intro), `\subsubsection{Aggregate consumption gap from misallocated migration}`, `\subsubsection{Removing the hukou wedge in China}`, `\subsubsection{From consumption to welfare}`.
One numbered equation per experiment plus the misallocation decomposition equation that brackets observed migration against zero-migration and optimal-sort.

### Decisions, with the why

- "Two experiments" interpreted as #1 + #2; #3 demoted to a closing paragraph.
Why: user wrote "the two counterfactual experiments" explicitly; #3 in the memo is still "design open" with neither route specified, while #1 and #2 are paper-ready in their current scope.
The bridge paragraph preserves the welfare extension as ongoing work without overcommitting to a route the user has not approved.
- Did NOT bake the back-of-envelope numbers ($\approx 22\%$ TZA, $\approx 6.5\%$ CHN, $\approx 3.7\%$ IDN) into the prose.
Why: those rest on unverified trajectory-share guesses ($\pi_{d_N} \approx 0.75$ TZA, $0.65$ CHN, $0.50$ IDN), and the user explicitly flagged in the afternoon session that "the full counterfactual thing needs a bit more than point estimates and population shares."
The draft describes what we will deliver and the design that produces it, not numbers that would commit the paper to magnitudes we have not verified.
- Cited \cite{bryanAggregateProductivityEffects2019}, \cite{lagakosMigrationCostsObservational2020}, \cite{lagakosUrbanRuralGapsDeveloping2020a} as the literature placing the exercise.
Why: the user asked for "Mobarak et al" style framing, and these three are the standard structural-migration-counterfactual references already in CKT.bib.
Bryan-Morten is the canonical "what does removing rural-urban frictions deliver" paper; Lagakos-Mobarak-et-al 2020 is closest in spirit to our identification (migration costs from observed wage gaps in panel data); Lagakos 2020 frames the urban-rural productivity gap.
- Three within-trajectory heterogeneity reporting options (floor / heterogeneity-corrected / bounded envelope) preserved from the memo.
Why: LCA identifies $\Delta_{\underline{d}}$ but not its within-trajectory dispersion, and the trajectory-mean formula is a Jensen lower bound on the true gap.
Bracketing the magnitude across the three options is the honest way to report this, and the memo committed to all three as deliverables.
- Inversion CI propagation method described in prose, not derived.
Why: the appendix [app:inversion-preview](file:///C:/Users/maand/Monash%20Uni%20Enterprise%20Dropbox/Emilia%20Tjernstrom/Apps/Overleaf/ReturnsToMigration-clean/sections/app_inversion_preview.tex) already does this work; the counterfactual section inherits the machinery and points the reader there.
- Hukou wedge parameterized as an additive intercept shift $\beta^{rh} \rightarrow \beta^{uh}$.
Why: the memo's "resorting version" specified this, and it is the cleanest way to use the model's existing decision rule from equation~\eqref{eq:decision-rule} without introducing new structure.
The alternative (estimating a separate barrier parameter) would expand the model beyond what the paper currently identifies.
- Sentence-case headings even though `sec_results.tex` currently uses Title Case for its existing subsections.
Why: the user's `rules/manuscript-writing.md` mandates sentence case as a hard rule, and the prior addendum [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex) already chose sentence case.
Consistency with the addendum wins over consistency with the legacy-cased sec_results headings; the user will presumably normalize the existing headings later.

### Approaches rejected and the reason

- Including #3 as a third counterfactual experiment.
User said "two," and the memo flags #3 as design-open with the Suri-style observables route requiring a per-country amenity-proxy catalog that does not yet exist.
- Putting specific back-of-envelope percentages in the section text.
The shares feeding them ($\pi_{\underline{d}}$) are unverified guesses; baking the percentages into the paper would commit us to numbers that will move when actual trajectory shares are extracted.
- Drafting in a "we find" / "we estimate" register as if the experiments had been run.
The section is paper-bound but describes planned exercises; pretending results exist would be sloppy.
Chose "we use these objects to address...", "We report two versions...", "We will report..."---future-facing where results are not yet realized, present-tense where we describe what is identified.
- A full \subsection-level structural defense of LCA as the right identification for these counterfactuals.
That work is in the interpretation addendum from earlier today; duplicating it here would bloat the section.
The counterfactual section references `\ref{sec:interpretation}` instead.

### Open items

- Compile verification only possible inside the full Overleaf build; the standalone .tex references macros and labels defined elsewhere (`\GRChukoutable`, `eq:decision-rule`, `eq:restricted-GRC`, `app:inversion-preview`, `sec:interpretation`).
Verify on the next user-side compile when pasted in.
- The interpretation addendum [paper/results_interpretation_addendum.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_interpretation_addendum.tex) is not yet pasted into Overleaf either; the counterfactuals section's `\ref{sec:interpretation}` resolves only after both are pasted, in order.
- New file [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) is untracked; commit pending.
- The trajectory-share verification flagged at the top of this session log as "the natural next concrete action" remains undone.
That 30-minute warm-up is still the cheapest next step before any pipeline build.

### Picking back up

If you resume:
Read this session log; the canonical memo at [docs/notes/2026-05-13_counterfactual-experiments-plan.md](file:///C:/git/ckt/.claude/worktrees/lca-inversion/docs/notes/2026-05-13_counterfactual-experiments-plan.md) remains the design reference.
Open thread: paper has two ready-to-paste standalone .tex files in [paper/](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/) (interpretation addendum and counterfactual experiments section); both await the user's manual paste into the Overleaf-Dropbox `sec_results.tex`.
Next concrete action options, in increasing commitment: (1) commit [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex); (2) verify trajectory shares $\pi_{\underline{d}}$ from descriptive tables to firm up the back-of-envelope numbers; (3) start the 2--3 day trajectory-extraction pipeline for experiment #1.
State to know: [paper/results_counterfactuals.tex](file:///C:/git/ckt/.claude/worktrees/lca-inversion/paper/results_counterfactuals.tex) is the only uncommitted change in the worktree.
The prose-rules-enforcer hook was satisfied this session ([references/voice.md](file:///C:/Users/maand/.claude/references/voice.md) and [rules/manuscript-writing.md](file:///C:/Users/maand/.claude/rules/manuscript-writing.md) both Read).
