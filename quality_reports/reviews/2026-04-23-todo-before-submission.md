# TODO before submission: unbalanced-panel proposition

**Date:** 2026-04-23
**Status:** Open. Items below are blocking final submission of the unbalanced-panel proposition.

These are promises the text currently makes that the code has not delivered on. Ship items 1--3 before the paper goes out. Item 4 is optional but high-value.

## 1. Fill the `[X\%]` / `[Y\%]` placeholders

**Where:** `paper/unbalanced_proposition.tex`, first paragraph.

**What:** The proposition opens with "between `[X\%]` and `[Y\%]` of individuals are observed in strictly fewer than $T_c$ waves." Replace with actual per-country shares from the estimation samples.

**How:** For each country, `tab unbalanced if e(sample)` (or equivalent on the full sample used for estimation), pull the share with at least one missing wave. Report the range across the three countries as the `[X\%]`--`[Y\%]` bracket.

**Estimated effort:** 10 minutes.

## 2. Run the common-$\gamma$ test

**Where:** `paper/unbalanced_proposition.tex`, paragraph after Assumption~\ref{ass:common-gamma}.

**What:** The proposition promises: "The assumption is directly testable: replace $x_{it}'\gamma$ with $x_{it}'\gamma + U_i\,x_{it}'\delta$ and test $\delta=0$." A referee reading this will want the p-value. We have not actually run the test.

**How:** Add $U_i \times x_{it}$ interactions to `run_grc` for the unbalanced spec, estimate, and test the joint null $\delta = 0$ via a Wald test after the GMM. Add one sentence to the paper (probably in Section~\ref{sec:robustness} or a footnote in the proposition) reporting the test result.

**Estimated effort:** 30 minutes.

## 3. Verify the wave-of-first-observation robustness footnote

**Where:** `paper/unbalanced_proposition.tex`, footnote to the MAR discussion --- currently wrapped in red text to flag that it is unverified.

**What:** The footnote claims: "If panel entry cohorts matter for selection beyond what age, education, and household composition capture, wave-of-first-observation indicators can be added to $x_{it}$ without changing any of the arguments that follow. The version of the estimator reported in the main tables does not include such indicators; results are essentially unchanged when they are added (available on request)." We have not run the regression with wave-of-first-observation dummies, so the "essentially unchanged" claim is unverified.

**How:** Add wave-of-first-observation dummies to the covariate vector in `run_grc` (the existing code already has `pid_first_obs` --- generate wave-specific versions and include them as additional covariates). Re-estimate all three country specifications. Compare to the baseline.

**Three possible outcomes:**
- **Essentially unchanged** (what we claim): remove the red markup, keep the footnote as is.
- **Noticeable differences**: rewrite the footnote honestly and report both specifications in an online appendix.
- **Large differences**: this is a real finding. MAR as currently stated does not hold; selection is driven by entry cohort. Rework the robustness discussion.

**Estimated effort:** 30 minutes (plus writing time).

**Note:** The footnote text is currently rendered in `\textcolor{red}{...}` in `paper/unbalanced_proposition.tex` so it stands out visually as unverified. Remove the color command once the claim is confirmed.

## 4. (Optional, high-value) Option 2: impose LCA on the pooled unbalanced cell

**Where:** `scripts/0_programs.do`, `run_grc` program.

**What:** Currently the coefficient on `unbalanced_choice` (equivalently, $\Delta_{\mathrm{unb}} - \Delta_{\underline d_0}$) is estimated freely. A5 (LCA) says it should satisfy $\Delta_{\mathrm{unb}} - \Delta_{\underline d_0} = \phi(\mu_{\mathrm{unb}} - \mu_{\underline d_0})$. Imposing this is one GMM constraint away.

**How:** In the GMM residual within `run_grc`, replace the free coefficient on `unbalanced_choice` with `{phi}*({unbalanced_mu} - {mu: switcher_`base'})`, where `{unbalanced_mu}` is a named parameter for $\mu_{\mathrm{unb}}$. Re-estimate on three countries.

**Decision path after running:**
- Estimates agree: impose the constraint, report a tighter specification, update Remark~2 in the proposition to say we imposed LCA on the unbalanced cell.
- Slight disagreement: report both specifications, note the trade-off.
- Large disagreement: this is a real finding about attrition selecting on comparative advantage. Update the remark and report.

**Estimated effort:** half a day (code + re-estimation + write-up).

## Not on this list but adjacent

- Independent second-pass review of the proof. I found the issues and I also wrote the fixes, which is a conflict of interest. Before final submission, run `unbalanced_proposition.tex` through the `econometrics-critic` agent (or a coauthor's eyes) as an independent cross-check.
- The Verdier-robust extrapolation work on the other branch (`explorations/verdier/`) is a separate stream. Confirm the two pieces fit together before submission.

## Sequence

Recommended order:

1. Item 1 (10 min) --- must do before anything else.
2. Item 3 (30 min) --- verify the red-flagged footnote; the result dictates whether the footnote stays.
3. Item 2 (30 min) --- add the common-$\gamma$ test result to the paper.
4. Independent review (econometrics-critic agent).
5. Optionally Item 4 (half day) --- if we want one more econometric swing before submission.

Total for items 1--3 + review: one afternoon.
