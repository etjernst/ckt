# Econometric proof style (Verdier 2020)

Style insights extracted from Verdier (2020), *Average Treatment Effects for Stayers with Correlated Random Coefficient Models of Panel Data*, main paper and online appendix. Useful reference for future methods writing.

## The twelve patterns

1. **Preview the proposition in plain prose before stating it.** Let the formal statement carry only the formal result. Example (main text, before Proposition 1): "Under these assumptions, Proposition 1 establishes the asymptotic properties of our first-step estimates." And a fuller version (before Proposition 2): "The following proposition shows that under the CRC model, the extrapolation identifying assumption, and the assumptions above, the second step estimators of $\alpha_0$, $\alpha_1$, and of ATE for stayers discussed above have a linear influence function representation and are asymptotically normal."

2. **Restate what the proposition showed immediately after it.** "Proposition 1 shows that the noise in the estimates of $a_i$ and $a + b_i$ obtained from the first step of our estimation procedure is approximated by a noise term of mean zero conditional on treatment status history..." The formal statement is dense; the follow-up translates it back into English so the reader knows what to take away.

3. **Keep the proposition statement itself almost trivially short.** Verdier's Proposition 1 is literally: "Under the CRC model (2.4) and Assumptions 1 and 2, as $n \to \infty$: [display formula]". No parameter definitions, no regularity preamble, no delta-method corollaries. Those go in the surrounding prose.

4. **Gloss each assumption sub-part individually after stating it.** For Assumption 2 with parts a/b/c: "Assumption 2.a is imposed in this form for simplicity and could easily be relaxed. Assumption 2.b is natural here since we are interested in cases where stayers are observed in the data. Assumption 2.c is a regularity condition that imposes that the error term in the CRC model (2.4) has variability, so that the model would not fit the data perfectly without this error term." Each part gets its own "why it's here" sentence. Never stack all four assumptions in a single list.

5. **Say why each assumption is cheap to impose.** "This is imposed for convenience only since convergence in probability of the two-stage least squares estimators of $\alpha_0$ and $\alpha_1$ can be derived from primitive conditions as in the proof of Proposition 5 below." He names the assumption, acknowledges it is not primitive, and points to where the primitive derivation lives. No defensiveness.

6. **Short modular hedges.** "For simplicity, we assume...", "In addition, we assume...", "As before, only observations on movers are used for this regression." Sentences rarely stack more than one idea. Each hedge is its own sentence.

7. **Connective "Note that" sentences tie results together.** "Note that Proposition 1 in the main text is obtained as a special case of Proposition 4." "Note that Assumption 8 is implied by Assumptions 1 and 2 in the main text for the special case where $T = 2$ and $z_{it} = \mathbf 1[t=2]$." Light touch; no fanfare.

8. **Friendly signposting.** "To shorten notation, define...", "Similarly as before, we can show that...", "In the rest of this section, we list conditions..." Reads like a tour, not a manifesto.

9. **Acknowledge scope in parentheticals, not defensive clauses.** "This assumption is relaxed to independence across cross-sectional observations in the appendix and can easily be relaxed to accommodate limited forms of cross-sectional dependence such as cluster dependence, as in Section 3.3 below." Matter-of-fact, no "we do not claim..." posturing.

10. **Open an unbalanced/special-case section by stating the motivation in one sentence, then defining scope in another.** Appendix Section G opens: "Many panel datasets available in empirical work are unbalanced, i.e. some cross-sectional observations are only observed for a subset of the time periods $t = 1, \ldots, T$. In this section we briefly discuss the consequences of missing data if one assumes that observations are missing at random." That is the entire setup. No three-paragraph throat-clear.

11. **Sub-part glossing for multi-part assumptions is patient and often gives a sufficient condition.** For Assumption 9 parts a--d, each gets 2--3 sentences, often with "For instance with two time periods, Assumption 9.a would be obtained by..." style concrete examples. The reader never has to guess what a part is for.

12. **Short-to-medium sentences, one idea each.** Em-dash stacks with four conditions glued together are rare. Conditions get separated into sentences. Lists get broken into lines or paragraphs, not inlined.

## Two side-by-sides

### Example 1: proposition statement

Ours (before this revision, 4 sentences, 180+ words):
> "Let $\kappa_T$ be defined in~(2) and let $\vartheta_T \equiv (\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}_{\underline d \in \mathcal D \setminus \{d_T\}}, \kappa_T)$ denote the trajectory-block parameters; let $\theta_0 \equiv (\vartheta_T, \mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}}, \gamma)$ denote the full parameter vector of~(1). Assume (A1)--(A5) of Section 2, Assumptions 1 and 2, the rank condition that $D_{it}$ takes both values within the unbalanced stratum, and the standard regularity conditions for non-linear GMM. Then the two-step GMM estimator of~(1) is $\sqrt n$-consistent and asymptotically normal for $\theta_0$. The trajectory-specific returns... [one more long sentence]. Because the balanced-only GMM system is a strict subset... [another long sentence]."

Verdier-style rewrite (single display result, follow-ups live outside):
> "Proposition (Pooling balanced and unbalanced individuals). Under (A1)--(A5), Assumptions 1 and 2, the rank condition that $D_{it}$ takes both values within the unbalanced stratum, and standard regularity conditions for non-linear GMM, as $n \to \infty$,
> $$\sqrt n\,(\hat\theta - \theta_0) \xrightarrow{d} \mathcal N(0, V),$$
> where $\theta_0 = (\vartheta_T, \mu_{\mathrm{unb}}, \Delta_{\mathrm{unb}}, \gamma)$ with $\vartheta_T = (\Delta_{\underline d_0}, \phi, \{\mu_{\underline d}\}_{\underline d \neq d_T}, \kappa_T)$, and $V$ is the efficient two-step GMM asymptotic variance."

The delta-method extensions, the inversion, and the efficiency comparison become their own short sentences after the proposition.

### Example 2: ingredient preview

Verdier (main, before Proposition 1):
> "Under these assumptions, Proposition 1 establishes the asymptotic properties of our first-step estimates."

Our current setup jumps directly from the `ass:common-gamma` discussion into the proposition without a preview sentence. A Verdier-style preview would be:
> "Taken together, (A1)--(A5), Assumptions 1 and 2, and a rank condition on $D_{it}$ within the unbalanced stratum suffice for $\sqrt n$-consistency and asymptotic normality of the pooled two-step GMM estimator. Proposition 1 states the result; the delta-method extensions and the efficiency comparison to the balanced-only estimator follow."

## When to deviate

These are Verdier's defaults, not universal laws. Deviate when:

- The formal statement genuinely has to carry the ingredient list (e.g., the reader would otherwise not know which object the proposition is about).
- The paper has no main/appendix split and proofs appear in-line; Verdier-style multi-sentence unpacking would bloat the body.
- The proposition is one of many closely related variants; a tight inline form is easier to compare.

Default to Verdier's patterns and break them only for cause.
