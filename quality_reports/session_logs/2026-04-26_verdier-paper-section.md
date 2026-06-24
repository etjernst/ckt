# Session log: 2026-04-26 --- Verdier paper section

**Mode:** Implementation (paper drafting) + Review (writing-critic, humanizer pass)
**Files touched:**
- [`paper/verdier_robust.tex`](file:///C:/git/ckt/paper/verdier_robust.tex) (new) --- robustness subsection body
- [`paper/robust_equivalence_proof.tex`](file:///C:/git/ckt/paper/robust_equivalence_proof.tex) (new) --- appendix proof

## What we built

A standalone robustness subsection for `\section{Robustness}` in [`paper/main.tex`](file:///C:/git/ckt/paper/main.tex), with a companion appendix proof.

Body argues: we adopt the cluster-residualized trajectory-pooled estimator $\hat\phi^{\mathrm{rob}}$ as a robustness check against the cluster-pooling concern raised by \citet{verdierAverageTreatmentEffects2020a}, and report it alongside the baseline $\hat\phi$ for the three baseline consumption specifications (IDN, CHN, TZA, unbalanced panel, urban indicator, full controls + period FE).

Appendix proves Proposition~\ref{prop:robust-equivalence}: under (A1)--(A5) + Assumption~\ref{ass:cluster-pooling}, $\hat\phi^{\mathrm{rob}}$ and Verdier's worker-level GMM estimator $1/\hat\alpha_1$ have the same probability limit, equal to the LCA slope $\phi$. Four-step proof modeled on the structure of [`unbalanced_proposition.tex`](file:///C:/git/ckt/paper/unbalanced_proposition.tex).

## Key design decisions

### D1. Subsection title: "Robustness to cluster pooling"

**Reason:** The earlier draft was titled "Worker-level robustness", which invites the referee reaction "if worker-level is the right thing, why aren't you running it as your main?" Naming the section after the assumption being tested keeps the focus on what the check probes rather than on an alternative estimator we don't run.

### D2. Use $\hat\phi^{\mathrm{rob}}$ as the robustness estimator, not Verdier's full worker-level GMM

Two substantive reasons in the body:
1. **Parameterization.** Verdier's worker-level estimator parameterizes the LCA in the reverse direction ($\alpha_1 = 1/\phi$), so its point estimates and standard errors are not on the same scale as $\hat\phi$. Direct comparison requires inverting and propagating SEs by the delta method.
2. **Sample restriction.** Worker-level identification requires each worker to be observed in both rural and urban states, which discards the unbalanced observers that Proposition~\ref{prop:pooling} (in unbalanced_proposition.tex) validates including.

**Reason explicitly dropped (per user feedback, 2026-04-26):** "inference machinery (cluster-robust SEs, Hansen's $J$-test, delta-method trajectory deltas) carries over from `run_grc`." Reads as a "we don't want to write new code" justification, which sounds lazy and doesn't have a substantive analog in Verdier's setup --- both estimators support cluster-robust SEs natively. Hansen's $J$ does require overidentification choices in the worker-level case, but this is a finite-sample inference concern rather than a fundamental obstacle.

### D3. Appendix proves $\hat\phi^{\mathrm{rob}} \equiv$ Verdier's worker-level

**Reason:** The body's substantive claim is that $\hat\phi^{\mathrm{rob}}$ is a faithful stand-in for Verdier's worker-level robustness check, so the appendix has to prove that equivalence. Proving "$\hat\phi^{\mathrm{rob}} \equiv \hat\phi$" instead would be circular for the robustness purpose --- the whole point of running $\hat\phi^{\mathrm{rob}}$ is that it could differ from $\hat\phi$ when cluster-pooling fails.

The appendix may not make the final paper but stays available for referees who ask "why is your cluster-residualized version a valid stand-in for Verdier's method?"

### D4. Body proposition stated for the worker-level equivalence; baseline-vs-robust comparison stays empirical

The body's Proposition~\ref{prop:robust-equivalence} formally claims $\hat\phi^{\mathrm{rob}}$ and Verdier's worker-level have the same probability limit. The comparison of $\hat\phi^{\mathrm{rob}}$ to the baseline $\hat\phi$ is presented as an empirical exercise (Table~\ref{tab:verdier-robust}, results paragraph) without a separate formal claim. The two-sentence appendix remark notes that the proof also covers the generalization with cluster-level intercept $c(v_i)$, under which $\hat\phi^{\mathrm{rob}}$ stays consistent.

### D5. No TV diagnostic in the body

**Reason:** Mean total-variation distance between switcher cluster profiles was a useful diagnostic during the development phase (see [`quality_reports/reviews/2026-04-25_simulation-results.md`](file:///C:/git/ckt/quality_reports/reviews/2026-04-25_simulation-results.md)) and is implemented in `explorations/verdier/`. The body now reports just the point-estimate comparison; if a referee asks "how do we know cluster-pooling is approximately satisfied?" we have the diagnostic ready to deploy. Putting it in the body up front signals the assumption is fragile and invites attack.

### D6. No comparison of $\hat\phi^{\mathrm{rob}}$ to $1/\hat\alpha_1$ in the body

**Reason:** We are not running Verdier's worker-level estimator on the real data, so there is no $\hat\alpha_1$ to compare to. Earlier drafts that talked about a "gap between $\hat\phi^{\mathrm{rob}}$ and $1/\hat\alpha_1$" as a diagnostic were rooted in the simulation work (where we did run both), not in what the paper will actually report.

### D7. Section flow: motivation $\to$ what we do $\to$ results $\to$ equivalence $\to$ caveats

**Reason (per user, 2026-04-26):** Lead with why the reader should care (cluster-pooling concern from Verdier), then say what we did (cluster-residualized instruments), then show results, then justify the equivalence to Verdier's method. Earlier drafts opened with the worker-level setup or the implementation details, which buries the motivation.

## Reviews applied

- **writing-critic** review on the earlier draft (75/100, below 80 commit gate). Major fixes applied: notation $b_i \to \Delta_i^w$ (avoid collision with main.tex's $b_U, b_R$ projection coefficients); explicit derivation of (eq:worker-lca); explicit formula for the cluster-residualized instrument $\tilde D_{it}^{\,\underline d}$; bias formula relabeled "cluster-pooling bias" with $c(v_i)$ replacing $\beta(v_i)$ to avoid collision with $\beta$ as the constant rural-urban gap (eq:beta) and with $\alpha$ in eq:restricted-grc-unbalanced; removed `\href{run:quality_reports/reviews/...md}` link to working-tree memo; tightened proof sketch; collapsed subsubsections into prose with topic sentences.
- **humanizer** pass (manual, against [`~/.claude/skills/humanizer/SKILL.md`](file:///C:/Users/maand/.claude/skills/humanizer/SKILL.md) pattern list): no AI-vocab, no superficial -ing endings, no copula avoidance, no negative parallelisms, no em-dash overuse, no bold labels in prose. One mild literary phrase ("probes a margin our baseline estimates rest on") retained as defensible academic prose.

After the user's 2026-04-26 restructure (D2--D7), the writing-critic review was not re-run; the changes simplified rather than complicated the prose, so likely cleared remaining hedges.

## Outstanding

1. **Wire `\input` lines into [`paper/main.tex`](file:///C:/git/ckt/paper/main.tex):** body section into `\section{Robustness}` (after line ~809), appendix into the appendix block (after line 923).
2. **Compile.** Verify amsthm `\newtheorem{proposition}` and `\newtheorem{assumption}` are in [`paper/preamble.tex`](file:///C:/git/ckt/paper/preamble.tex); verify that the existing `prop:pooling` and `ass:mar`, `ass:common-gamma` from unbalanced_proposition.tex use the same theorem environments (so the new ones inherit the same numbering scheme).
3. **Generate the results table.** [`explorations/verdier/x_main_comparison_results.dta`](file:///C:/git/ckt/explorations/verdier/x_main_comparison_results.dta) has $\hat\phi$ and $\hat\phi^{\mathrm{rob}}$ point estimates and SEs across the 3 countries × 5 covariate variants. Need a do-file that filters to the 3 baseline consumption-unbalanced cells and writes `tables/verdier_robust_consumption_unb.tex`.
4. **Fill the results paragraph.** Once the table is in place, replace the placeholder bracketed text with the actual point estimates and the comparison interpretation. Country-by-country: small/large gap, within/outside one SE.
5. **Decide on appendix placement.** Currently `\input{robust_equivalence_proof}` would go alongside `\input{unbalanced_proposition}` in the appendix block. Order matters for label numbering.

## Files referenced

- [`paper/verdier_robust.tex`](file:///C:/git/ckt/paper/verdier_robust.tex) --- new body subsection
- [`paper/robust_equivalence_proof.tex`](file:///C:/git/ckt/paper/robust_equivalence_proof.tex) --- new appendix proof
- [`paper/main.tex`](file:///C:/git/ckt/paper/main.tex) --- target manuscript
- [`paper/unbalanced_proposition.tex`](file:///C:/git/ckt/paper/unbalanced_proposition.tex) --- structural template
- [`quality_reports/reviews/2026-04-25_robust-vv-equivalence-proof.md`](file:///C:/git/ckt/quality_reports/reviews/2026-04-25_robust-vv-equivalence-proof.md) --- proof source memo
- [`quality_reports/reviews/2026-04-25_simulation-results.md`](file:///C:/git/ckt/quality_reports/reviews/2026-04-25_simulation-results.md) --- empirical evidence
- [`.claude/worktrees/unbalanced-panel-proof-review/docs/Econometric Proof Style.md`](file:///C:/git/ckt/.claude/worktrees/unbalanced-panel-proof-review/docs/Econometric%20Proof%20Style.md) --- style guide for proof structure
