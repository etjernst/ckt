# Proposed paper edits for E2 Version 2

Date: 2026-06-29.
Two suggested edits, to be applied by the user in Overleaf (do not edit the paper here).
Both follow from the CC1 resolution: the existence of switchers forces the realized-shock reading of the decision rule (see [external-review-response](2026-06-29_e2-v2-external-review-response.md) and the session log).
Locate each by the quoted anchor; worktree line numbers are a secondary pointer and may differ from the Overleaf section files.

---

## Edit 1 --- model section: state the realized-shock per-period rule

Why.
The decision rule is written with an expectation operator, $E[\nu_{it}^U - \nu_{it}^R]$, which a reader can misread as integrating out the current shock.
Under that misreading the rule is deterministic in the time-invariant index $\beta + \phi\theta_i$, so no worker ever switches, contradicting the switchers on which identification rests.
One sentence makes explicit that the operative per-period choice evaluates the rule at the realized shock, which the paper's own static-equivalence argument already implies.
This clarifies rather than changes the model.

Where.
In the location-choice subsection, immediately after the decision-rule equation \eqref{eq:decision-rule}.
Anchor: the equation that reads $E[V_{it}^U] > E[V_{it}^R] \Longleftrightarrow \beta + \phi\theta_i + E[\nu_{it}^U - \nu_{it}^R] > 0$ (worktree `paper/main.tex` line 300, just before `\subsection{Empirical Model}`).

Insert this paragraph after the equation:

```latex
Because the idiosyncratic shocks are i.i.d.\ and productivity is time-invariant, the forward-looking comparison in \eqref{eq:decision-rule} reduces to a sequence of static, period-by-period choices evaluated at the realized shock.
Worker $i$ selects the urban location in period $t$ whenever $\beta + \phi\theta_i + (\nu_{it}^U - \nu_{it}^R) > 0$.
It is this realized variation in $\nu_{it}^U - \nu_{it}^R$, not its expectation, that generates the location switching from which the returns are identified.
```

---

## Edit 2 --- counterfactual section: the calibration limitation

Why.
Version 2 calibrates the shock scale $\sigma_\eta$ to the observed rate of (never-)migration, which attributes all period-to-period mobility to the i.i.d.\ taste shock.
If real switching also reflects forces the model abstracts from, the calibration over-states the dispersion of transitory tastes and the resorting mass.
Stating this directly keeps the magnitude honestly conditional on the model's shock structure.
This is the same concern the external reviewer raised.

Where.
In the resorting (Version 2) discussion of the counterfactual section, immediately after the sentence that introduces the $\sigma_\eta$ calibration.
Anchor: the passage describing the scale of the distribution of $\nu_{it}^U - \nu_{it}^R$ and the justified $\sigma_\eta$ grid (worktree `paper/results_counterfactuals.tex` around lines 155--157).
This text will land when the Version 2 prose is rewritten from subjunctive into reported results; include it as part of that rewrite.

Insert these sentences:

```latex
Calibrating $\sigma_\eta$ to the observed never-migration rate attributes all period-to-period mobility to the i.i.d.\ taste shock.
To the extent that observed switching also reflects forces the model abstracts from---learning about own comparative advantage, moving costs, or persistent location-specific factors---this calibration over-states the dispersion of transitory tastes and, with it, the mass of workers the counterfactual induces to resort.
The resulting magnitude is therefore conditional on the model's i.i.d.\ shock structure, and is best read as an upper estimate of the resorting response under that structure.
```

Note on the last clause.
"Upper estimate" here refers to the shock-dispersion channel.
It compounds with the separate upper-proxy caveat on the within-trajectory comparative-advantage dispersion $\sigma_{\theta,d}$ (CC2).
If both caveats appear in the same paragraph, state them together so the reader does not double-count the word "upper".
